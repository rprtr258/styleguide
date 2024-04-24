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
