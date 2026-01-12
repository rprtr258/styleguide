- use [jessevdk/go-flags](https://github.com/jessevdk/go-flags) for cli apps
  - `urfave/cli/v2` was great until I found out there is no completion features, so if you don't need them, you can use it
  - `spf13/cobra` has many features presumably, but terrible api
  - `flag`, `spf13/pflag` or any other lib with crappy api - they have crappy api
  - `spf13/viper` or other complex lib for reading config - don't, read config directly, if you really need it and environment variables are not enough
- use `slog`/`zerolog`/`zap`/etc over `log`, as structured logs are easier to parse programmaticaly, can be pleasantly displayed and bit safer to write
- for configuration use [jsonnet](https://jsonnet.org/) over combinations of `yaml`, `json`, `hcl`, etc... files with includes, extends, cross references, loops encoded inside according syntax, etc... (until I find format with same features along with typing (Go has too weak typing system, unsure on CUE))
- use [`gofumpt -l -w .`](https://github.com/mvdan/gofumpt) as more strict formatting
- use [`goimports-reviser`](https://github.com/incu6us/goimports-reviser) for consistent imports ordering: std, libraries, local
- use sorted map for sorted map (maps which can be iterated over keys in order), e.g. [this implementation](https://github.com/rprtr258/fun/blob/master/orderedmap/orderedmap.go#L29)
- find and eliminate deadcode using following commands:
```bash
golangci-lint run --disable-all --enable unused ./...
go run golang.org/x/tools/cmd/deadcode@latest ./...
```