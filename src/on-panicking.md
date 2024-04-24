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