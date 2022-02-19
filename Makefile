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
.PHONY: debug
debug: dvieter
dvieter: $(SOURCES)
	$(V) -keepc -cg -cc gcc -o dvieter $(SRC_DIR)

# Optimised production build
.PHONY: prod
prod: pvieter
pvieter: $(SOURCES)
	$(V) -o pvieter -prod $(SRC_DIR)

# Only generate C code
.PHONY: c
c:
	$(V) -o vieter.c $(SRC_DIR)


# =====EXECUTION=====
# Run the server in the default 'data' directory
.PHONY: run
run: vieter
	 API_KEY=test DOWNLOAD_DIR=data/downloads REPO_DIR=data/repo PKG_DIR=data/pkgs LOG_LEVEL=DEBUG ./vieter server

.PHONY: run-prod
run-prod: prod
	API_KEY=test DOWNLOAD_DIR=data/downloads REPO_DIR=data/repo PKG_DIR=data/pkgs LOG_LEVEL=DEBUG ./pvieter

# Same as run, but restart when the source code changes
.PHONY: watch
watch:
	API_KEY=test DOWNLOAD_DIR=data/downloads REPO_DIR=data/repo PKG_DIR=data/pkgs LOG_LEVEL=DEBUG $(V) watch run vieter

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
	rm -rf 'data' 'vieter' 'dvieter' 'pvieter' 'vieter.c'
