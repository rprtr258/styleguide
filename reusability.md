This is list of tactics to build more reusable code. They might not be usable in general case, always justify your decisions.


## split sequential calls, extract/inline one-time used functions
if `g` only usage is in `f` and first/last call in `f` is `g()` or `return g()`, call to `g` can be extracted or inlined

<table><thead><tr><th>before</th><th>extract</th><th>inline</th></tr></thead><tbody><tr><td>

```python
def g():
    # g ...

def f():
    # f ...
    g()

f()
```
</td><td>

```python
def g():
    # g ...

def f():
    # f ...

f()
# here f() can be observed, modified, etc.
g()
```
</td><td>

```python
# now no code separation just to separate code
def f():
    # f ...
    # g ...

f()
```
</td></tr></tbody></table>

In `inline` variant we cannot reuse parts of `f` since they are still hidden, but now they are not broken into some functions with no purpose. `f` and `g` were just separations of single function, serving no other purpose besides separation. there is nothing inherently bad in having long functions as long as you can follow what they do step by step. small functions also tend to mutate shared state which is not reusable at all. E.g. see `SetupTeardownIncluder.java` example from [Clean Code book](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882), there are many little(1-4 lines) functions which mutate shared class fields and exist just to be small, if you try to reuse those methods, you are very likely to break something or forget to call methods in right order, or forget to call required method at all hence leading to bugs.


## move side effects outward, split concerns
if function does side effects: 
- reads/writes file
- performs http/grpc/etc. requests
- reads current time
- generates random numbers
- ...many other examples

Try to move out side effects for reading function inputs and return data used to do outputting side effect. In such way, function becomes pure and more reusable: input can be read from file, database, come from test input; so as output can be written to file, checked in test, observed to audit or logs or written to database:


<table><thead><tr><th>before</th><th>extract processing</th><th>extract file reading</th></tr></thead><tbody><tr><td>

```python
# reads file content
# parses each item
# processes each item
def load_entities():
    content = # read file
    for item in content.lines:
        result = parse(item)
        # process result, e.g. store in global map

load_entities()
```
</td><td>

```python
# first, collect items to be processed into inmemory data structure
# thus processing can be moved outward, and then function is more reusable

# reads content
# parses each item
def load_entities():
    content = # read file
    
    res = []
    for item in content.lines:
        res.append(parse(item))
        # special techniques such as iterators/generators/callbacks may be used
        # to consume less memory
        # yield parse(item)
    return res

for result in load_entities():
    # any type of processing can be done now with results
    # work can also be parallelised now, which was imposible when processing was locked inside function
    # process result
```
</td><td>

```python
# next, we can move input side effect out, reading file outside of function

# parses list of items
def load_entities(content):
    for item in content.lines:
        yield parse(item)

content = # read file
# Again, to consume less memory on content data, io.Reader/iterator-like readers can be used.
# Now we can use and test parsing independently of input source:
# - parse arbitary strings
# - read any file, not only hardcoded in function
# - get input from some request
# - etc.
for result in f(content):
    # process result
```
</td></tr></tbody></table>

Now we simplified function enough to be just `map(parse, content.lines)`. Higher order functions, especially `map` and `reduce` over lists and iterators are powerful tools and they force you to use pure functions, consider using them when possible:
```python
content = # read file/make request/etc
for result in map(parse, content.lines):
    # process result
```


## pass dependencies explicitly
`DI` (Dependency Injection) libraries and frameworks do not simplify anything, but hides how things are wired and reduces code length with cost of not knowing how things are initialized in case of errors. Also it does nothing that can't be done by simply passing arguments to functions, though wasting lots of library code on doing that.

Creating dependencies inside function which uses them is also not reusable. So, prefer create dependencies explicitly and pass them to dumb constructors (if constructor is needed at all):

<table><thead><tr><th>before</th><th>extract dependency</th></tr></thead><tbody><tr><td>

```python
def new_db_wrapper(dsn): # usually some constructor of SomeThingRepository
    db = driver.connect(dsn)
    return Repo(db=db)
```
</td><td>

```python
# instead, make explicit that something will use resource

# dumb constructor now
def new_db_wrapper(db):
    return Repo(db=db)
```
</td></tr></tbody></table>

Now constructor does not now how connector was created, does not do any side effects such as creating connection, pinging database, initializing pool of connections, etc. These now belongs to client code which in full control of creating `db`.


## don't inverse control flow when possible
instead of requiring callback in any form to just transform some data

<table><thead><tr><th>before</th><th>direct control flow</th></tr></thead><tbody><tr><td>

```python
def process(callback):
    resource = acquireResource()
    resource.init()
    callback(resource)

# callback MUST be closure in order to mutate something local here
process(myProcessing)
```
</td><td>

```python
# just allow to acquire resources directly

resource = acquire_resource() // acquires and initializes resource

# and do whatever I want with it, use, save, reuse, call special methods
myProcessing(resource)
```
</td></tr></tbody></table>

In case resource management is required, there are multiple viable options:
- simplified callback wrapper which just acquires and cleans up resource
```python
def with_resource(callback):
    resource = acquire_raw_resource()
    # nothing is done with resource here, it is passed as is
    callback(resource)
    resource.cleanup()

with_resource(my_processing)
```

- programming language supported context-manager-like thing
```python
with with_resource() as resource:
    my_processing(resource)
```

- same as callback but without callback
```python
def with_resource():
    resource = acquire_raw_resource()
    yield resource
    resource.cleanup()

for resource in with_resource():
    my_processing(resource)
```

- another language facilities to cleanup resources, like destructors or `defer` statements
```go
resource := acquire_raw_resource()
defer resource.cleanup()

callback(resource)
```

All these variants are better than callback variant (since callback are simple and does nothing but init and deinit resource) and allow e.g. to use multiple resources with little or no problem.

These variants of api are also an option when you want to give client no chance to misuse resources, as he might forget:
- close db connection
- close opened file
- release mutex
- misuse functions which MUST be called in specific order
- commit/rollback transaction
- etc

As example of using callbacks based approach see my [library](https://github.com/rprtr258/scuf/blob/master/buffer.go) for coloring terminal output:
- side effectful resource is handled in constructor `New(io.Writer) Buffer`
- all functions are just wrappers on writes to internal `io.Writer` and can be chained like `b.String("hello world").NL().TAB()`
- callback methods are used to force writing before and after users writes to buffer, e.g. `b.Styled(func(Buffer), ...Style)` will
    - begin styling buffer writes
    - execute what user wants to write to buffer
    - ends styling buffer
thus obviating need to call styling methods like `BeginStyle` and `EndStyle` in specific order
