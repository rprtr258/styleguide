- camelCase, I hope this one is obvious
- variables with similar namings (e.g. enum values) should use common prefix, e.g. `EnvDev`, `EnvStg`, `EnvProd`, not `DevEnv`, `StgEnv`, `ProdEnv`
- use consistent naming, e.g. if you name user `User`, name it `User` everywhere: database tables, scan structs, handler structs, protobufs, not `Account` or `Profile` in some random cases instead
- receiver names are 1-2 characters long, and are first letter of receiver type, e.g. `(c client)`
- receiver names must be the same across all methods of the same type
- `id` or `ID`, same with other abbreviations like `URL`, `HTTP`, etc
- package exported things are used as `package.Thing`, so `Client`, not `RedisClient` in `redis` package
- noun for one thing, plural for collection/set of many things
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