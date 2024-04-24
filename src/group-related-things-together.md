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