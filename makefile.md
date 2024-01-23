Boilerplate to copy and use:
```makefile
CURDIR=$(shell pwd)
BINDIR=${CURDIR}/bin

bindir:
	mkdir -p ${BINDIR}

RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
VIOLET := $(shell tput -Txterm setaf 5)
CYAN   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

## Generic
.PHONY: help
help: # show help
	@awk 'BEGIN {FS = ":.*?# "} { \
	if (/^[/%.a-zA-Z_-]+:.*?#.*$$/) \
		{ printf "  ${YELLOW}%-30s${RESET}${WHTIE}%s${RESET}\n", $$1, $$2} \
	else if (/^## .*$$/) \
		{ printf "${CYAN}%s:${RESET}\n", substr($$1,4)} \
	}' $(MAKEFILE_LIST)



## Generic
.PHONY: install
install: # install into GOPATH
	go install ./cmd/app/



## Development
bump: # bump dependencies
	go get -u ./...
	go mod tidy

# TODO: pin everything
fmt: # run formatters
	go fmt ./...
	go run mvdan.cc/gofumpt@latest -l -w .
	go run golang.org/x/tools/cmd/goimports@latest -l -w -local $(shell head -n1 go.mod | cut -d' ' -f2) .
	go mod tidy



## Run
.PHONY: run
run: # run app
	go run cmd/app/app.go

.PHONY: psql
psql: # run postgres cli
	docker exec -ti postgres psql

.PHONY: docker-server
docker-server port: # run dockerized server on specified port
	docker compose up --build --rm -it -p {{port}}:$(PORT)



## Test
.PHONY: test
test: # run unit tests
	go test ./...

.PHONY: coverage
coverage: # run tests and open coverage in browser
	go test -v -coverprofile=cover.out -covermode=atomic .
	go tool cover -html=cover.out



## Lint
.PHONY: lint
lint: lint-go lint-links # run all linters

GOLANGCILINTVER=1.53.2
GOLANGCILINTBIN=${BINDIR}/golangci-lint_${GOLANGCILINTVER}

install-golangcilint: bindir
	@test -f ${GOLANGCILINTBIN} || \
		(wget https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCILINTVER}/golangci-lint-${GOLANGCILINTVER}-linux-amd64.tar.gz -O ${GOLANGCILINTBIN}.tar.gz && \
		tar xvf ${GOLANGCILINTBIN}.tar.gz -C ${BINDIR} && \
		mv ${BINDIR}/golangci-lint-${GOLANGCILINTVER}-linux-amd64/golangci-lint ${GOLANGCILINTBIN} && \
		rm -rf ${BINDRI}/${GOLANGCILINTBIN}.tar.gz ${BINDIR}/golangci-lint-${GOLANGCILINTVER}-linux-amd64)

# TODO: pin go-critic, deadcode
.PHONY: lint-go
lint-go: install-golangcilint # run go linter
	@${GOLANGCILINTBIN} run ./...
	gocritic check -enableAll -disable='rangeValCopy,hugeParam,unnamedResult' ./...
	deadcode .

.PHONY: lint-links
lint-links:
	docker run --init -it --rm -w /input -v $(pwd):/input lycheeverse/lychee .

.PHONY: audit
audit: tools # audit dependencies
	go install github.com/sonatype-nexus-community/nancy@latest
	go list -json -m all | nancy sleuth

.PHONY: todo
todo: # show list of all todos left in code
	grep 'TODO' --glob '**/*' || echo 'All done!'

.PHONY: outdated
outdated: # list outdated dependencies
	go install github.com/psampaz/go-mod-outdated@latest
	go list -u -m -json all | go-mod-outdated -update -direct



## CI
.PHONY: precommit
precommit: lint test audit # run precommit checks
```

- every command should have docstring like so:
```makefile
rule: # this rule does something
```

- reserved rule names:
  - `help` rule must be first, in order to show it on `make` command, shows list of command with description
  - `run` run main executable with default parameters: envs, local database params and etc.
  - `lint` run linters
  - `test` run all tests that do not need any additional actions, e.g. unit tests
  - `precommit` usually just runs `lint`, then `test`
  - `todo` show list of `// TODO: something` comments
  - `build` build executable
  - `install` compile and install/update executable locally

- use dotenv files like so:
```makefile
run:
	rwenv -ie .env go run cmd/app/app.go
```

- particular cases (e.g. `run`ning different `target`s) of commands are named like `$(COMMAND)-$(CASE)`, e.g.
```makefile
run-target:
run-reposts:
	go run main.go get-reposts
run-dumpwall:
	go run main.go dumpwall
run-count:
	go run main.go count --friends 168715495
```

- echo calls must be prefixed with `@` in order to not output `echo` command itself, e.g.
```makefile
@echo 'something important is happening now...'
```

- frequently used commands should be aliased, e.g.
```makefile
DOCKER_COMPOSE:=docker compose -f .deploy/docker-compose.yml
VKUTILS:=rwenv -ie .env go run main.go
APP:=go run cmd/main.go
```

- use following snippet at the beginning of `Makefile` to export env vars from `.env` file
```makefile
ifneq (,$(wildcard ./.env))
	include .env
	export
endif
```

- [swagger generates examples](https://github.com/moby/moby/blob/master/hack/generate-swagger-api.sh)
- [templating readme example](https://github.com/rprtr258/fimgs)
