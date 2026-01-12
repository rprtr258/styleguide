- [Principles](#principles)
- [Practices](#practices)
  * [Just some Go proverbs I agree with, with no details](#just-some-go-proverbs-i-agree-with-with-no-details)
  * [Globals](#globals)
  * [Use pointers only if they are really needed](#use-pointers-only-if-they-are-really-needed)
  * [Naming](#naming)
  * [Group related things together](#group-related-things-together)
  * [Reduce variables scopes as much as you can](#reduce-variables-scopes-as-much-as-you-can)
  * [Reduce nesting](#reduce-nesting)
  * [On panicking](#on-panicking)
  * [Language features](#language-features)
  * [Standart library](#standart-library)
    + [`context.Context` usage](#contextcontext-usage)
    + [Time routines](#time-routines)
  * [Libraries/frameworks API design, including `internal`](#librariesframeworks-api-design-including-internal)
  * [Libraries and tools](#libraries-and-tools)
  * [Project organization](#project-organization)
  * [Error handling](#error-handling)
  * [Comments](#comments)
  * [Other](#other)

## Principles
- simplicity: make thing as simple as it can be
- minimalicity: don't introduce additional concepts, unless you really need them

## Practices
### Just some Go proverbs I agree with, with no details
- `interface{}` says nothing.
- A little copying is better than a little dependency.
- Clear is better than clever.
- Reflection is never clear.
- Errors are values.
- Don't just check errors, handle them gracefully.
- Don't panic.
- Pass interfaces, return implementations.

### Globals
- don't ever use `init` if you don't have to (some libs might force you to register your drivers or similar, then do minimal `init` for that), instead:
  - initialize things explicitly in `main` function: loggers, connections, tracing, etc.
  - initialize global variables using function call:
```go
var _moscowLoc = mustLoadLoc("Europe/Moscow")
func mustLoadLoc(name string) *time.Location {
    loc, err := time.LoadLocation(name)
    if err != nil {
        panic(fmt.Sprintf("load location name=%q: %s", name, err.Error()))
    }
    return loc
}
```
  - the only valid use for `init` is to check some conditions on global variables that theoretically might be done in compile time, e.g. check two maps have equal length
- precompile constant templates, regexes, etc as global variables using method above
- name globals using underscore at the beginning: `var _cache map[int]int`, not `var cache map[int]int` to differentiate from locals and privates. This is important as access to global variables must be considered: it's scattered around and might blow up with concurrency if there are writes to it.
- prefer using global variables as immutable one-time initialized values
- if write access is required, it must be scoped and protected with mutex if there is any chance to use it from multiple goroutines
- if global var is constant and primitive make it `const` (non-primitives can't be `const` sadly)


### Use pointers only if they are really needed
- to reuse same piece of memory in different places
- to pass around mutexes and other synchronization primitives
- to use pointers returned from external libraries

### Naming
- camelCase, I hope this one is obvious
- similar namings should go from more abstract words, followed with more specific
  - e.g. enum values should go like: `EnvDev`, `EnvStg`, `EnvProd`, not `DevEnv`, `StgEnv`, `ProdEnv`. As `Env` is more abstract. Such namings are easier to find and they align nicely.
  - "value modifiers" are reflected as concrete parts:
    - `idStr` (meaning marshalled `id`) and `id`
    - `password`, `passwordBase64` (which is `base64(password)`), `passwordBase64Hash` (which is `hash(base64(password))`), etc.
- names should be either descriptive or consistent, both is even better
  - descriptive name includes `what variable value is`, so not `tmp`, but `tmpFile` or `tmpBuffer`
  - use consistent naming, e.g. if you name user `User`, name it `User` everywhere: database tables, scan structs, handler structs, protobufs, not `Account` or `Profile` in some random cases instead
  - try to avoid putting types in names, though that might be useful sometimes, e.g. `idStr` means `id` in form of `string` which is yet not parsed
  - unsized types should include units, e.g. `sizeBytes int64` instead of `size int64`, `delay_secs int` instead of `delay int`, etc.
- receiver names are 1-2 characters long, and are first letter of receiver type, e.g. `(c client)`
- receiver names must be the same across all methods of the same type
- `id` or `ID`, never `Id`, same with other abbreviations like `URL`, `HTTP`, etc
- package exported things are used as `package.Thing`, so use `Client` instead of `RedisClient` in `redis` package
- noun for one thing, plural for collection/set of many things
- boolean vars and predicate functions (functions returning `bool`) should be prefixed with `is/has/can/should`
- avoid negating in names, as it leads to double-negations and hard to understand, e.g. `isAuthorized` instead of `isNotAuthorized` or `notAuthorized`, or `isUnauthorized`
- sometimes you can introduce `explanatory` variables, whose purpose is assign name to complex expression:
```go
isImportant := event.Importance == ImportanceHigh
isWhitelisted := whitelist.Contains(event.Type)
if isWhitelisted && !isImportant {
  // skip
  return
}
// instead of
if whitelist.Contains(event.Type) && event.Importance != ImportanceHigh {
  // skip
  return
}
```
- common abbreviations:

|||||
|-|-|-|-|
|`r`|reader, rune|`w`|writer|
|`b`|buffer|`sb`|strings builder, select builder|
|`s`|string|`q`|query|
|`wg`|waitgroup|`mu`|mutex|
|`k`|key|`v`|value|
|`T,R`|generic types|`K,V`|generic key,value types|
|`i,j,k`|indices|`d`|duration|
|`f`|function|||

### Group related things together
- db result models (ones with `db:"..."` tags) with sql queries with explicit columns listing
- error handling with place where error is produced
- group related `var`s and `const`s under one declaration
- group related symbols in one package (that what package are made for)
- group related symbols inside package into file
- group lines with receiving variable, checking error, validating it and deferring, so no newline breaks before `file` using code in following snippet:
```go
file, err := openFile()
if err != nil {
    return fmt.Errorf("open file: %w", err)
}
defer file.Close()
if file.Size() == 0 {
    return fmt.Errorf("file is empty")
}

// use file here
```

### Reduce variables scopes as much as you can
By scope I mean number of lines from which variable can be accessed

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
var a, b int
c := getC()
b = evalB(c)
a = evalA(b, c)
```
</td><td>

```go
c := getC()
b := evalB(c)
a := evalA(b, c)
```
</td></tr></tbody></table>

- prefer single assignment over multiple assignments:

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
a := new(MyStruct)
a.Field = 1
a.Aboba = "lol"
```
</td><td>

```go
a := &MyStruct{
    Field: 1,
    Aboba: "lol",
}
```
</td></tr></tbody></table>


to achieve that [samber/lo](https://github.com/samber/lo) or [rprtr258/fun](https://github.com/rprtr258/fun) or similar libs/hand-written funcs are of use

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
pbBooks := make([]*pb.Book, len(books))
for i, book := range books {
  pbBooks[i] = &pb.Book{
    Name: book.Name,
    Authors: make([]string, len(book.Authors)),
  }
  for j, author := range book.Authors {
    pbBooks[i].Authors[j] = &pb.Author{
      Name: author,
    }
  }
}
return &pb.Library{
    Books: pbBooks,
}
```
</td><td>

```go
return &pb.Library{
  Books: fun.Map[*pb.Book](
    books,
    func(book Book) *pb.Book {
      return &pb.Book{
        Name: book.Name,
        Authors: fun.Map[*pb.Author](
          book.Authors,
          func(author string) *pb.Author {
            return &pb.Author{
              Name: author,
            }
          }),
      }
    }),
}
```
</td></tr></tbody></table>

- reduce variable mutability scope (code that mutates variable)

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
a := new(MyStruct)
a.Field = evalField(b, c)
// write directly to a
// might depend only on c,d as arguments
// and b,c as they are used to fill a.Field
// instead, depend on b,c,d directly
appendSomeThings(a, c, d)
var err error
a.Location, err = getLocation()
// handle err
```
</td><td>

```go
aLocation, err := getLocation()
// handle err
a := &MyStruct{
    Field: evalField(b, c),
    Aboba: evalSomeThings(b, c, d),
    Location: aLocation,
}
```
</td></tr></tbody></table>

- treat function arguments as const/immutable most of the time


### Reduce nesting
- simplify `if`-s using conditions

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
if a {
    if b {
        ...
    }
}
```
</td><td>

```go
if a && b {
    ...
}
```
</td></tr></tbody></table>

- simplify `if`-s using `switch` `case`

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
if a == 1 {
    ...
} else if a == 2 {
    ...
} else {
    ...
}
```
</td><td>

```go
switch a {
case 1:
  ...
case 2:
  ...
default:
  ...
}
```
</td></tr></tbody></table>

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
if a == 1 {
    ...
} else if b == 1 {
    ...
} else {
    ...
}
```
</td><td>

```go
switch {
case a == 1:
  ...
case b == 2:
  ...
default:
  ...
}
```
</td></tr></tbody></table>

- simplify `if`-s/`switch`-`case` using single assignment

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
var col Color
if input == "Green" {
    col = ColorGreen
} else if input == "Red" {
    col = ColorRed
} else {
    col = ColorBlack
}
```
</td><td>

```go
col := fun.
  Switch(input, ColorBlack).
  Case("Green", ColorGreen).
  Case("Red", ColorRed).
  End()
```
</td></tr></tbody></table>

- simplify `if`-`return` by reducing nesting

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
if a {
    ...
    return 1
} else {
    ...
    return 2
}
```
</td><td>

```go
if a {
  ...
  return 1
}

...
return 2
```
</td></tr></tbody></table>

when doing so, put unhappy/fast (meaning you can give answer immediately, e.g. from cache) path into `if`, so mainline code expresses happy path with occasional exits in unhappy events

<table><thead><tr><th>bad</th><th>better</th></tr></thead><tbody><tr><td>

```go
if hasPermission {
    // happy path
    return nil
}

return ErrNoPermission
```
</td><td>

```go
if !hasPermission {
  return ErrNoPermission
}

// happy path
return nil
```
</td></tr></tbody></table>


### On panicking
- don't `panic` in general
- you are allowed to `panic` if caller disobeyed contract your code declared and you can't react to it (return error):
```go
// ToChunks splits xs into n chunks, n must be positive
func ToChunks(xs []int, n int) []int {
    if n <= 0 {
        panic(fmt.Sprintf("invalid chunks count: %d", n))
    }

    ...
}
```
- don't use `panic`s as exceptions alternative or control flow
    - if you really really really really REALLY want to use it that way and have reasons to, limit panic scope as much as possible, e.g. see `encoding/json` parser, though I didn't met such cases in my workings

### Language features
- use `type Optional[T any] struct { Value T; Valid bool }` (unless Go authors add sum types) for optional values, don't use pointers for that. if you use pointers for optional values, they are mixed up with pointers that has no meaning of optional value, which is confusing
- never use `new`, it's just useless
- the only uses for keyword `var` are:
  - global vars declarations, for some reason `var` is required
  - if var has no initial value, that is, instead of `var a = value` or `var a type = value` you can just `a := value`. Use `var a Type` e.g. if you declare var and `json.Unmarshal` into it immediately
- prefer to explicitly fill all structure fields, use [`exhaustruct`](https://github.com/GaijinEntertainment/go-exhaustruct/) linter to check that
- the only case to use named returns is to append error using `defer func() { if recover() != {} }` construct, use it in top-level methods and only if needed

### Standart library
- use `slices.SortFunc` over `sort.Slice`
- use `os` and `io` over `ioutil`
- use `map[K]struct{}` over `map[K]bool` for sets
- use `any` over `interface{}` as it is more specific
- use `x == ""` over `len(x) == 0`
- `strings` are
    - indexed by bytes aka `s[i]` gives `i`-th byte
    - `len(s)` gives number of bytes, for rune count use `utf8.RuneCountInString`
    - iterated by runes and byte index, that is `for i, r := range s` `i` will be index of first rune byte, `r` will be the rune
- for strange strings in errors/logs use `%q` formatting directive to not miss empty strings or strings with spaces in the end

#### `context.Context` usage
- use `context.Background` only in `main` and tests, though there can be cases when test hang up, in that case use `context.WithTimeout(context.Background(), 5*time.Second)` in test
- always pass context to long lived goroutines
- never pass data using `Context`. `trace_id` like things are not considered as data as they are not used in application

#### Time routines
- use `time` package, no custom structures or seconds with `const Day = 24 * 60 * 60`
- though, there is an issue with expressing date ranges using `time` package, for that use `struct DateRange {days, months, years int}` with `date.AddDate(r.years, r.months, r.days)`
- never use `time.Sleep`, except maybe in tests or one time scripts/benchmarks
- never call `time.Now()` several times in a func if they would return near times. if you need current timestamp, store it in variable and then use: `now := time.Now()`
- remember about timezones when using `time.Time` related things, store timestamps in UTC timezone, if you need to store timezone which is needed only for displaying, store it separately or in dedicated database type

### Libraries/frameworks API design, including `internal`
- if slice returned always contains exactly `n` elements, use array `[n]T` instead (`regexp` functions don't do it, though they return `[][]int` which are really `[][2]int`)
- treat most functions as ways to transform one data to another, don't make every function change something: write to Writer, change some external memory, etc
- focus on frequent path, they must be easy to use, rare path must be also usable if needed
- code must be reusable, every system might be reused in other systems, workers, crons, onetime scripts, tests etc, not being bound to some cringy DI framework and other things the system does not depend on
- don't create interfaces for single implementation
- if there are two ways to implement thing, e.g. A and B and A allows client code to do C, D, E while B allows client code only to do C, prefer A, For example, there might be two ways to write sort function
  1. one allocates copy and sorts it without modifying original slice
  1. another sorts original slice in-place

  Second way allows user to choose whether they want to allocate new array copy before sorting or not, while first way doesn't. So second way is preferable. (that is some sort of Single Responsibility criteria: do only one thing, let the client do everything around)
- use separate config for every subsystem, don't use global application configuration in subsystems
- watch [this lecture](https://www.youtube.com/watch?v=ZQ5_u8Lgvyk) and see [some formal techniques](./reusability.md) to build reusable components
- [Avoid package names like base, util, or common](https://dave.cheney.net/2019/01/08/avoid-package-names-like-base-util-or-common)
- prefer to name package same as directory name, e.g. `module/abc/def/pkg` must have `package pkg`
    - given that, it is prohibited to use hyphen in package (actually directory) names
- prefer to avoid allocations, using parallelism in library code, or try to give user control over them
- avoid boolean args, `getData(id, true)` is unclear about what does `true` mean

### Libraries and tools
- use [jessevdk/go-flags](https://github.com/jessevdk/go-flags) for cli apps
  - `urfave/cli/v2` was great until I found out there is no completion features, so if you don't need them, you can use it
  - `spf13/cobra` has many features presumably, but terrible api
  - `flag`, `spf13/pflag` or any other lib with crappy api - they have crappy api
  - `spf13/viper` or other complex lib for reading config - don't, read config directly, if you really need it and environment variables are not enough
- use `slog`/`zerolog`/`zap`/etc over `log`, as structured logs are easier to parse programmaticaly, can be pleasantly displayed and bit safer to write
- for configuration use [jsonnet](https://jsonnet.org/) over combinations of `yaml`, `json`, `hcl`, etc... files with includes, extends, cross references, loops encoded inside according syntax, etc... (until I find format with same features along with typing (Go has too weak typing system, unsure on CUE))
- use [`gofumpt -l -w .`](https://github.com/mvdan/gofumpt) as more strict formatting
- use [`goimports-reviser`](https://github.com/incu6us/goimports-reviser) for consistent imports ordering: std, libraries, local
- use sorted map for sorted map (maps which can be iterated over keys in order), e.g. [this implementation](https://github.com/rprtr258/fun/blob/master/orderedmap/orderedmap.go#L29)
- find and eliminate deadcode using following commands:
```bash
golangci-lint run --disable-all --enable unused ./...
go run golang.org/x/tools/cmd/deadcode@latest ./...
```

### Project organization
- don't `os.Exit` (or `log.Fatal`, etc.) anywhere but `main`
- write `main` as following:
```go
func run() error {
    ...
    return nil
}

func main() {
    if err := run(); err != nil {
        log.Fatalf("app crashed: %s", err.Error())
    }
}
```
you may add `context.Context` initialization, signal handling, parse arguments, etc and just do the work in `run` function
- group imports in following groups: std, foreign, locals
- order functions such that first comes functions that use only std/externals, then those using std/externals/first functions, then those using std/externals/first/second functions etc. In other words, topologically sort functions by usage, such that function can only use functions defined before it. Exceptions are mutually recursive functions, of course, though these are very rare.
- preferrable project structure (same as directory structure) is by separate layers:
    - for web-like service they might be:
        - `transport`/`handlers` layer with `grpc`/`http`/etc handlers which just handles, validate, parse the data and passes to usecases
        - `usecases`/`logic` layer with business logic aka what application actually does
        - `repositories`/`data-access` layer for external stores, databases, clients to grpc/rest/etc services
    - simpler architecture might go like so:
        - `ports` layer with both transport and repositories layers from above
        - `core` layer with logic
    - models for logic code are put into `internal/models` or `internal/logic/models` and can be reused throughout all logic instances, if `core` is used, put models in `core` package
    - subpackages are allowed if they are only used in their parent package, e.g. `markdown` subpackage of `messenger` package
    - don't put things in separate package just because they look reusable, if thing is used in only single package, put it there and make it private
- if some method is in separate file, put everything in package used only in this method in that file also

### Error handling
- `failed to ...` in logs, `action: %w` in `fmt.Errorf` wrappings, I don't want to see messages like `failed to authenticate: failed to check user identity: failed to select user: failed to select: database is unreachable`
- if some package returns errors, that package should declare which errors it might return(unless Golang authors add sum types, functions should use sum of possible errors instead). package should not reuse errors from used libraries, e.g. data access layer should not return `sql.ErrNoRows` if no rows is returned, it should instead declare their own errors like `ErrPersonNotFound`
- declare most useful errors as exported var/types
- given two previous points, while calling external code (libraries or local package) you will only need to handle errors declared by that package and maybe one really weird "unknown" error. That can be done using equality for error vars and type assertion for error types, not `are.Is`/`errors.As` are needed.
- after handling always wrap error to package-specific error or just `fmt.Errorf`

### Comments
- no commented code and no code `not used for now, will be needed in future` or `though it is unused now, maybe it will be need in future`
- comments are for things which can't be expressed as code, e.g. links to issues, standards, docs, implementation explanation details, formulas, etc.
- strive to reduce `TODO` comments, instead open issues to fix the problem
- comment complex logic, unsafe code, hacks. In most other cases clear naming is enough.
- do not use comments to just rephrase what is being done in code, as I can read the code itself

### Other
- don't ever mix sideeffects code with expressions, so no `messenger.SendUserCreatedNotification(createUser().ID)` like things
- if several functions do same thing, use most specific one, as they are there for your convenience/performance/expressiveness:
  - `fmt.Sprint(x)` and `strconv.Itoa(x)` both converts int to string: `strconv.Itoa` is winner
  - `if strings.HasPrefix(s, prefix) { s = strings.Replace(s, prefix, "", 1) }` and `strings.CutPrefix(s, prefix)` both cuts `prefix` from `s`: `strings.CutPrefix` is more specific
- preallocate slices and maps if you know exact or close top estimate of map/slice size
- write table tests:
```go
for name, test := range map[string]struct{
    // testcase parameters...
}{
    "happy path": {
        // ...
    },
    "fail case": {
        // ...
    },
} {
    t.Run(name, func(t *testing.T) {
        // testcase
    })
}
```
- avoid stupiditly slow and memory greedy algorithms, prefer `O(N)` over `O(N^2)` and `O(1)` or `O(log N)` over `O(N)` if it doesn't overcomplexify code
- don't put author, license, changes list and etc in source files, neither in headers, nor in footer, nor anywhere. Put license in separate file, change list in separate file or release notes in vcs.
- store applied values in minimal units: memory and file sizes in bytes(bits, if you need to count them), money in cents/satoshi/pennies
- never `SELECT * FROM ...`, list specific fields to select
- inline `if err := do(); err != nil`, just a personal preference, also it is harder to shadow another `err` in such way
- lines are less than 80 chars, max 120, because two panes of 80-width code fits screen nicely
- no dead, unused code if possible, use [unused](https://github.com/dominikh/go-tools/tree/master/unused) to find unused private symbols and [punused](https://github.com/bep/punused/) for public symbols. Though I recommend using `punused` only manually as it gives many false positives, e.g. for mock methods, grpc mehods, interface implementations methods.
- if a function is called from a single place, consider inlining it
- if one piece of code with changed parameters is used several times in one place (same "code context"), consider moving it to function
- if one piece of code with changed parameters is used several times in different places (different "code context"s), consider carefully if it is worth it to move it to function
- if function is close to purely functional, with few references to global state, try to make it completely functional
- learn logic/boolean-algebra to analyze and transform/simplify conditionals, e.g.
```go
if a { ... }
// instead of
if a || a && b { ... }
```
in general, try to transform conditions to Disjunctive normal form (that is `a && b && c || d && e`) as it is flat and simple enough

