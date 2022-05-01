# =====CONFIG=====
SRC_DIR := src
SOURCES != find '$(SRC_DIR)' -iname '*.v'

V_PATH ?= v
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
		gdb --args ./dvieter -f vieter.toml server

# Optimised production build
.PHONY: prod
prod: pvieter
pvieter: $(SOURCES)
	$(V) -o pvieter -prod $(SRC_DIR)

# Only generate C code
.PHONY: c
c: $(SOURCES)
	$(V) -o vieter.c $(SRC_DIR)


# =====EXECUTION=====
# Run the server in the default 'data' directory
.PHONY: run
run: vieter
	./vieter -f vieter.toml server

.PHONY: run-prod
run-prod: prod
	./pvieter -f vieter.toml server


# =====DOCS=====
.PHONY: docs
docs:
	rm -rf 'docs/public'
	cd docs && hugo

.PHONY: api-docs
api-docs:
	rm -rf '$(SRC_DIR)/_docs'
	cd '$(SRC_DIR)' && v doc -all -f html -m -readme .


# =====OTHER=====
.PHONY: lint
lint:
	$(V) fmt -verify $(SRC_DIR)
	$(V) vet -W $(SRC_DIR)
	$(V_PATH) missdoc -p $(SRC_DIR)
	@ [ $$($(V_PATH) missdoc -p $(SRC_DIR) | wc -l) = 0 ]

# Format the V codebase
.PHONY: fmt
fmt:
	$(V) fmt -w $(SRC_DIR)

.PHONY: test
test:
	$(V) test $(SRC_DIR)

# Build & patch the V compiler
.PHONY: v
v: v/v
v/v:
	git clone --single-branch https://git.rustybever.be/Chewing_Bever/v v
	make -C v

.PHONY: clean
clean:
	rm -rf 'data' 'vieter' 'dvieter' 'pvieter' 'vieter.c' 'dvieterctl' 'vieterctl' 'pkg' 'src/vieter' *.pkg.tar.zst 'suvieter' 'afvieter' '$(SRC_DIR)/_docs' 'docs/public'


# =====EXPERIMENTAL=====
.PHONY: autofree
autofree: afvieter
afvieter: $(SOURCES)
	$(V_PATH) -showcc -autofree -o afvieter $(SRC_DIR)

.PHONY: skip-unused
skip-unused: suvieter
suvieter: $(SOURCES)
	$(V_PATH) -showcc -skip-unused -o suvieter $(SRC_DIR)
