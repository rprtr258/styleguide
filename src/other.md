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