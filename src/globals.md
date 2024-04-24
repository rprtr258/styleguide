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
- precompile constant templates, regexes, etc as global variables using method above
- name globals using underscore at the beginning: `var _cache map[int]int`, not `var cache map[int]int` to differentiate from locals and privates. This is important as access to global variables must be considered: it's scattered around and might blow up with concurrency if there are writes to it.
- prefer using global variables as immutable one-time initialized values
- if write access is required, it must be scoped and protected with mutex if there is any chance to use it from multiple goroutines
- if global var is constant and primitive make it `const` (non-primitives can't be `const` sadly)
