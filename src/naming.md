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