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