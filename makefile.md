# Project scripts/Makefile guidelines

Boilerplate to copy and use:
```go
#!/usr/bin/awk BEGIN{for (i=2; i<ARGC; i++) { subslice = subslice ARGV[i] " " }; system("risor "ARGV[1]" -- "subslice)}

from cli import command, flag

PWD := os.getwd()
BINDIR := filepath.join(PWD, "bin")

APP_NAME := "myapp"

RED    := exec("tput", ["-Txterm", "setaf", "1"])
GREEN  := exec("tput", ["-Txterm", "setaf", "2"])
YELLOW := exec("tput", ["-Txterm", "setaf", "3"])
BLUE   := exec("tput", ["-Txterm", "setaf", "4"])
VIOLET := exec("tput", ["-Txterm", "setaf", "5"])
CYAN   := exec("tput", ["-Txterm", "setaf", "6"])
WHITE  := exec("tput", ["-Txterm", "setaf", "7"])
RESET  := exec("tput", ["-Txterm", "sgr0"])

GOVULNCHECK_VERSION        := "latest"
GOLANGCILINT_VERSION       := "v1.50"
PROTOLINT_VERSION          := "v0.40.0"
MOCKGEN_VERSION            := "v1.6.0"
PROTOC_GEN_GO_VERSION      := "v1.28"
PROTOC_GEN_GO_GRPC_VERSION := "v1.2"
PROTOC_VERSION             := "3.19.0"
NANCY_VERSION              := "latest"
GOMODOUTDATED_VERSION      := "latest"
GOLANGCILINTVER            := "1.53.2"

func bindir() {
  os.mkdir(BINDIR, 0755)
}

func myexec(cmd, args) { // TODO: variadic
  c := exec.command(cmd, args)
  exit_code := try(c.run, 1) // can't actually get exit code
  if exit_code != 0 {
    print("COMMAND FAILED:", cmd, args)
    print("STDOUT:", c.stdout)
    print("STDERR:", c.stderr)
  }
}

func lint_go() {
  // install golangci-lint
  GOLANGCILINTBIN := filepath.join(BINDIR, 'golangci-lint_{GOLANGCILINTVER}')

  bindir()
  file_exists := try(func() {
    os.stat(GOLANGCILINTBIN)
    return true
  }, false)
  if !file_exists {
    exec("wget", ['https://github.com/golangci/golangci-lint/releases/download/v{GOLANGCILINTVER}/golangci-lint-{GOLANGCILINTVER}-linux-amd64.tar.gz', "-O", '{GOLANGCILINTBIN}.tar.gz'])
    exec("tar", ["xvf", '{GOLANGCILINTBIN}.tar.gz', "-C", BINDIR])
    os.rename(filepath.join(BINDIR, 'golangci-lint-{GOLANGCILINTVER}-linux-amd64/golangci-lint'), GOLANGCILINTBIN)
    os.remove(filepath.join(BINDIR, '{GOLANGCILINTBIN}.tar.gz'))
    os.remove_all(filepath.join(BINDIR, 'golangci-lint-{GOLANGCILINTVER}-linux-amd64'))
  }
  // TODO: pin go-critic, deadcode
  exec(GOLANGCILINTBIN, ["run", "./..."])
  exec("gocritic", ["check", "-enableAll", "-disable='rangeValCopy,hugeParam,unnamedResult'", "./..."])
  exec("deadcode", ["."])
}

func lint_links() {
  exec("docker", ["run", "--init", "-it", "--rm", "-w", "/input", "-v", '{PWD}:/input', "lycheeverse/lychee", ".", "./..."])
}

func gorun(tool, version, args=[]) {
    exec("go", ["run", '{tool}@{version}'] + args)
}

func lint_proto() {
  gorun("github.com/yoheimuta/protolint/cmd/protolint", PROTOLINT_VERSION, ["lint", "-reporter", "unix", GRPC_API_PROTO_PATH])
}

func lint() {
  lint_go()
  lint_proto()
  lint_links()
}

func test() {
  exec("go", ["test", "./..."])
}

func audit() {
  exec("go", ["list", "-json", "-m", "all"]) | exec("docker", ["run", "--rm", "-i", 'sonatypecommunity/nancy:{NANCY_VERSION}', "sleuth"])
  gorun("golang.org/x/vuln/cmd/govulncheck", GOVULNCHECK_VERSION, ["./..."])
}

func format() {
  exec("go", ["fmt", "./..."])
  gorun("mvdan.cc/gofumpt", "latest", ["-l", "-w", "."])
  module := os.read_file("go.mod") | string | strings.split("\n") | func(xs) {return xs[0]} | func(v) {return v.split(" ")[1]}
  gorun("golang.org/x/tools/cmd/goimports", "latest", ["-l", "-w", "-local", module, "."])
  exec("go", ["mod", "tidy"])
}

func gen_mock() {
  mockgen := func(args) {
    gorun("github.com/golang/mock/mockgen", MOCKGEN_VERSION, args)
  }
  mockgen([
    "-source", './internal/{APP_NAME}/logic/data_provider.go',
    "-destination", './internal/{APP_NAME}/logic/mock_logic/data_provider_mocks.go',
  ])
  mockgen([
    "-source", './internal/{APP_NAME}/logic/logic.go',
    "-destination", './internal/{APP_NAME}/logic/mock_logic/logic_mocks.go',
  ])
}

func gen_grpc() {
  GRPC_INSTALL_SOURCE := "https://github.com/protocolbuffers/protobuf/releases/download/v3.19.0/protoc-3.19.0-linux-x86_64.zip"
  GRPC_INSTALL_FILENAME := "third_party/protoc.zip"

  // install grpc
  exec("wget", ["-qO", GRPC_INSTALL_FILENAME, GRPC_INSTALL_SOURCE])
  exec("unzip", ["-qod", "third_party/protoc", GRPC_INSTALL_FILENAME])
  exec("rm", ["-f", GRPC_INSTALL_FILENAME])
  exec("go", ["install", "google.golang.org/protobuf/cmd/protoc-gen-go@v1.28"])
  exec("go", ["install", "google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2"])

  GRPC_PKG_DIR := "./pkg/api/grpc"
  GRPC_API_PROTO_PATH := "./api/grpc"

  os.mkdir(GRPC_PKG_DIR)
  exec("./third_party/protoc/bin/protoc", [
    "-I", "./third_party/protoc/include/google/protobuf",
    "-I", "./third_party/protoc/include/google/protobuf/compiler",
    "-I", GRPC_API_PROTO_PATH,
    '--go_out={GRPC_PKG_DIR}',
    "--go_opt=paths=source_relative",
    '--go-grpc_out={GRPC_PKG_DIR}',
    "--go-grpc_opt=paths=source_relative",
    '{GRPC_API_PROTO_PATH}/*.proto'
  ])
}

cli.app({
  name: "myapp",
  description: "My app description",
  commands: [
    // Generic
    command({
      name: "install",
      description: "install into GOPATH",
      category: "Generic",
      action: func(ctx) {
        exec("go", ["install", "./cmd/app/"])
      },
    }),
    // Development
    command({
      name: "bump",
      description: "bump dependencies",
      category: "Development",
      action: func(ctx) {
        exec("go", ["get", "-u", "./..."])
        exec("go", ["mod", "tidy"])
      },
    }),
    // TODO: pin everything
    command({
      name: "fmt",
      description: "run formatters",
      category: "Development",
      action: func(ctx) {
        format()
      },
    }),
    command({
      name: "deps-bump",
      description: "update dependencies",
      category: "Development",
      action: func(ctx) {
        exec("go", ["get", "-u", "./..."])
      },
    }),
    command({
      name: "seed",
      description: "seed database",
      category: "Development",
      action: func(ctx) {},
    }),
    command({
      name: "mongo-sh",
      description: "open mongosh",
      category: "Development",
      action: func(ctx) {},
    }),
    command({
      name: "mongo-express",
      description: "open mongo-express",
      category: "Development",
      action: func(ctx) {},
    }),
    command({
      name: "minio-web",
      description: "open minio frontend",
      category: "Development",
      action: func(ctx) {},
    }),
    command({
      name: "redis-cli",
      description: "open redis cli",
      category: "Development",
      action: func(ctx) {},
    }),
    command({
      name: "dump-table",
      description: "dump table into terminal",
      category: "Development",
      action: func(ctx) {},
    }),
    // Generate
    command({
      name: "gen-mock",
      description: "generate mocks go sources",
      category: "Generate",
      action: func(ctx) {
        gen_mock()
      },
    }),
    command({
      name: "gen-grpc",
      description: "generate grpc go sources",
      category: "Generate",
      action: func(ctx) {
        gen_grpc()
      },
    }),
    command({
      name: "gen",
      description: "run all source generators",
      category: "Generate",
      action: func(ctx) {
        gen_mock()
        gen_grpc()
      },
    }),
    // Run
    command({
      name: "run",
      description: "run app",
      category: "Run",
      action: func(ctx) {
        exec("go", ["run", "cmd/app/app.go"])
      },
    }),
    command({
      name: "psql",
      description: "run postgres cli",
      category: "Run",
      action: func(ctx) {
        exec("docker", ["exec", "-ti", "postgres", "psql"])
      },
    }),
    command({
      name: "docker-server",
      description: "run dockerized server on specified port",
      category: "Run",
      flags: [
        flag({
          name: "port",
          aliases: ["p"],
          value: 8080,
        }),
      ],
      action: func(ctx) {
        exec("docker", ["compose", "up", "--build", "--rm", "-it", "-p", '{ctx.int("port")}:80'])
      },
    }),
    command({
      name: "service",
      description: "start service in docker",
      category: "Run",
      action: func(ctx) {
        exec("docker", ["compose", "up", "--build", "--rm", "-it", "service"])
      },
    }),
    command({
      name: "service-stop",
      description: "stop service in docker",
      category: "Run",
      action: func(ctx) {
        exec("docker", ["compose", "stop", "service"])
      },
    }),
    command({
      name: "service-build",
      description: "build service docker image",
      category: "Run",
      action: func(ctx) {
        exec("docker", ["compose", "build", "service"])
      },
    }),
    // Migrate
    command({
      name: "migrate-create",
      description: "create migration",
      category: "Migrate",
      action: func(ctx) {
        exec("go", ["install", "github.com/charmbracelet/gum@latest"])
        name := exec("gum", ["input", "--placeholder", "migration name"]).stdout
        print(name)
      },
    }),
    command({
      name: "migrate-up",
      description: "run all or several migrations up",
      // TODO: flag n with default value of 1
      category: "Migrate",
      action: func(ctx) {},
    }),
    command({
      name: "migrate-down",
      description: "run one or several migrations down",
      // TODO: flag n with default value of 1
      category: "Migrate",
      action: func(ctx) {},
    }),
    command({
      name: "migrate-ls",
      description: "list applied migrations",
      category: "Migrate",
      action: func(ctx) {},
    }),
    command({
      name: "migrate-reset",
      description: "reset all applied migrations",
      category: "Migrate",
      action: func(ctx) {},
    }),
    // Test
    command({
      name: "test",
      description: "run unit tests",
      category: "Test",
      action: func(ctx) {
        test()
      },
    }),
    command({
      name: "coverage",
      description: "run tests and open coverage in browser",
      category: "Test",
      action: func(ctx) {
        exec("go", ["test", "-v", "-coverprofile=cover.out", "-covermode=atomic", "."])
        exec("go", ["tool", "cover", "-html=cover.out"])
      },
    }),
    // Lint
    command({
      name: "lint",
      description: "run all linters",
      category: "Lint",
      action: func(ctx) {
        lint()
      },
    }),
    command({
      name: "lint-go",
      description: "run go linter",
      category: "Lint",
      action: func(ctx) {
        lint_go()
      },
    }),
    command({
      name: "lint-links",
      description: "find dead links",
      category: "Lint",
      action: func(ctx) {
        lint_links()
      },
    }),
    command({
      name: "lint-proto",
      description: "run proto linters",
      category: "Lint",
      action: func(ctx) {
        lint_proto()
      },
    }),
    command({
      name: "audit",
      description: "audit dependencies",
      category: "Lint",
      action: func(ctx) {
        audit()
      },
    }),
    command({
      name: "todo",
      description: "show list of all todos left in code",
      category: "Lint",
      action: func(ctx) {
        exec("grep", ["TODO", "--glob", "**/*"]) || print("All done!")
      },
    }),
    command({
      name: "outdated",
      description: "list outdated dependencies",
      category: "Lint",
      action: func(ctx) {
        exec("go", ["install", "github.com/psampaz/go-mod-outdated@latest"])
        exec("go", ["list", "-u", "-m", "-json", "all"]) | exec("docker", ["run", "--rm", "-i", 'psampaz/go-mod-outdated:{GOMODOUTDATED_VERSION}', "-update", "-direct"])
      },
    }),
    // CI
    command({
      name: "install-hook",
      description: "install git precommit hook",
      category: "CI",
      action: func(ctx) {
        os.write_file(".git/hooks/pre-commit", "#!/bin/sh\n./mk precommit")
      },
    }),
    command({
      name: "precommit",
      description: "run precommit checks",
      category: "CI",
      action: func(ctx) {
        format()
        lint()
        test()
        audit()
      },
    }),
  ],
}).run(["vahui"] + os.args())
```

- every command should have at least `name`, `description` and `category`
```go
command({
  name: "test",
  description: "run unit tests",
  category: "Test",
  action: func(ctx) {...},
}),
```

- reserved command names:
  - `run` run main executable with default parameters: envs, local database params and etc.
  - `lint` run linters
  - `test` run all tests that do not need any additional actions, e.g. unit tests
  - `precommit` usually just runs `lint`, then `test`
  - `todo` show list of `// TODO: something` comments
  - `build` build executable
  - `install` compile and install/update executable locally

- use dotenv files like so:
```go
func use_dotenv(filename) {
  for kv := range string(os.read_file(filename)).trim_space().split("\n") {
    k, v := kv.split("=")
    os.setenv(k, v)
  }
}

...
use_dotenv(".env")
```
never read `.env` file inside program itself

- particular cases (e.g. `run`ning different `target`s) of commands should go to subcommand like `$COMMAND $CASE`, e.g.
```go
cli.command({
  name: "run",
  description: "run targets",
  action: func(ctx) {...},
  subcommands: [ // TODO: not supported for now, use run-target flat commands list instead for now
    cli.command({
      name: "taret",
      description: "run target",
      action: func(ctx) {...},
    }),
    cli.command({
      name: "reposts",
      description: "run reposts script",
      action: func(ctx) {
        // go run main.go get-reposts
      },
    }),
    cli.command({
      name: "dumpwall",
      description: "run dumpwall script",
      action: func(ctx) {
        // go run main.go dumpwall
      },
    }),
    cli.command({
      name: "count",
      description: "run count script",
      action: func(ctx) {
        // go run main.go count --friends 168715495
      },
    }),
  ],
})
```

- if commands are used more than once, wrap them in a function
```go
func docker_compose(service="app") {
  exec("docker", ["compose", "-f", ".deploy/docker-compose.yml", service])
}

func run(args=[]) {
  use_dotenv(".env")
  exec("go", ["run", "main.go"] + args)
}
```

- you can import env vars from `.env` file at the beginning once, to reuse them for running app, scripts, db clients, etc.
```go
use_dotenv(".env")
```

- frequently used params should be saved in variables
```go
PROTOC_PATH := "./very/long/path"

exec("protoc", [
  filepath.join(PROTOC_PATH, "/api.proto"),
  "--src", filepath.join(PROTOC_PATH, "/packages/package.proto"),
  "--dst", filepath.join(PROTOC_PATH, "/pkg/"),
])
```
or
```go
func PROTOC_PATH(path) {
  return filepath.join("./very/long/path", path)
}

exec("protoc", [
  PROTOC_PATH("/api.proto"),
  "--src", PROTOC_PATH("/packages/package.proto"),
  "--dst", PROTOC_PATH("/pkg/"),
])
```

- third party tools should be installed first or run in docker
```go
func gen-mock() { // generate mocks go sources
  exec("go", ["install", "github.com/golang/mock/mockgen@v1.6.0"])
  exec("mockgen", [
    "-source", "./internal/$(APP_NAME)/logic/data_provider.go",
    "-destination", "./internal/$(APP_NAME)/logic/mock_logic/data_provider_mocks.go",
  ])
}
```
or
```go
func gen-mock() { // generate mocks go sources
  gorun("github.com/golang/mock/mockgen", "v1.6.0", [
    "-source", "./internal/$(APP_NAME)/logic/data_provider.go",
    "-destination", "./internal/$(APP_NAME)/logic/mock_logic/data_provider_mocks.go",
  ])
}
```
or
```go
GRPC_INSTALL_SOURCE := "https://github.com/protocolbuffers/protobuf/releases/.../protoc.zip"
GRPC_INSTALL_FILENAME := "third_party/protoc.zip"

// install grpc
print("downloading zip file...")
print("unpacking...")
print("removing zip file...")
print("moving executable into ./third_party/protoc/bin/...")

// generate grpc go sources
exec("./third_party/protoc/bin/protoc", ["..."])
```

- [swagger generates examples](https://github.com/moby/moby/blob/master/hack/generate-swagger-api.sh)
- [templating readme example](https://github.com/rprtr258/fimgs)
