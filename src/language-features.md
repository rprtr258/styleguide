- use `type Optional[T any] struct { Value T; Valid bool }` (unless Go authors add sum types) for optional values, don't use pointers for that. if you use pointers for optional values, they are mixed up with pointers that has no meaning of optional value, which is confusing
- never use `new`, it's just useless
- the only uses for keyword `var` are:
  - global vars declarations, for some reason `var` is required
  - if var has no initial value, that is, instead of `var a = value` or `var a type = value` you can just `a := value`. Use `var a Type` e.g. if you declare var and `json.Unmarshal` into it immediately
- prefer to explicitly fill all structure fields, use [`exhaustruct`](https://github.com/GaijinEntertainment/go-exhaustruct/) linter to check that
- the only case to use named returns is to append error using `defer func() { if recover() != {} }` construct, use it in top-level methods and only if needed