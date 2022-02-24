# =====CONFIG=====
SRC_DIR := src
SOURCES != find '$(SRC_DIR)' -iname '*.v'

V_PATH ?= v/v
V := $(V_PATH) -showcc -gc boehm

all: vieter

# =====COMPILATION=====
# Regular binary
vieter: $(SOURCES)
	$(V) -g -o vieter $(SRC_DIR)

# Debug build using gcc
# The debug build can't use the boehm garbage collector, as that is
# multi-threaded and causes issues when running vieter inside gdb.
.PHONY: debug
debug: dvieter
dvieter: $(SOURCES)
	$(V_PATH) -showcc -keepc -cg -o dvieter $(SRC_DIR)

# Run the debug build inside gdb
.PHONY: gdb
gdb: dvieter
	 VIETER_API_KEY=test \
		VIETER_DOWNLOAD_DIR=data/downloads \
		VIETER_REPO_DIR=data/repo \
		VIETER_PKG_DIR=data/pkgs \
		VIETER_LOG_LEVEL=DEBUG \
		VIETER_REPOS_FILE=data/repos.json \
		gdb --args ./dvieter

# Optimised production build
.PHONY: prod
prod: pvieter
pvieter: $(SOURCES)
	$(V) -o pvieter -prod $(SRC_DIR)

# Only generate C code
.PHONY: c
c:
	$(V) -o vieter.c $(SRC_DIR)

# Build the CLI tool
.PHONY: cli
cli: dvieterctl
dvieterctl: cli.v
	$(V_PATH) -showcc -g -o dvieterctl cli.v

.PHONY: cli-prod
cli-prod: vieterctl
vieterctl: cli.v
cli-prod:
	$(V_PATH) -showcc -o vieterctl -prod cli.v

# =====EXECUTION=====
# Run the server in the default 'data' directory
.PHONY: run
run: vieter
	 VIETER_API_KEY=test \
		VIETER_DOWNLOAD_DIR=data/downloads \
		VIETER_REPO_DIR=data/repo \
		VIETER_PKG_DIR=data/pkgs \
		VIETER_LOG_LEVEL=DEBUG \
		VIETER_REPOS_FILE=data/repos.json \
		./vieter server

.PHONY: run-prod
run-prod: prod
	VIETER_API_KEY=test \
		VIETER_DOWNLOAD_DIR=data/downloads \
		VIETER_REPO_DIR=data/repo \
		VIETER_PKG_DIR=data/pkgs \
		VIETER_LOG_LEVEL=DEBUG \
	./pvieter server

# =====OTHER=====
.PHONY: lint
lint:
	$(V) fmt -verify $(SRC_DIR)

# Format the V codebase
.PHONY: fmt
fmt:
	$(V) fmt -w $(SRC_DIR)

.PHONY: vet
vet:
	$(V) vet -W $(SRC_DIR)

# Build & patch the V compiler
.PHONY: v
v: v/v
v/v:
	git clone --single-branch --branch patches https://git.rustybever.be/Chewing_Bever/vieter-v v
	make -C v

clean:
	rm -rf 'data' 'vieter' 'dvieter' 'pvieter' 'vieter.c' 'dvieterctl' 'vieterctl' 'pkg' 'src/vieter'
