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
