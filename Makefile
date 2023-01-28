# =====CONFIG=====
SRC_DIR := src
SRCS != find '$(SRC_DIR)' -iname '*.v'

V_PATH ?= v
V := $(V_PATH) -showcc -gc boehm -W -d use_openssl -skip-unused

all: vieter


# =====COMPILATION=====
.PHONY: libvieter
libvieter:
	make -C '$(SRC_DIR)/libvieter' CFLAGS='-O3' 

# Regular binary
vieter: $(SOURCES) libvieter
	$(V) -g -o vieter $(SRC_DIR)

# Debug build using gcc
# The debug build can't use the boehm garbage collector, as that is
# multi-threaded and causes issues when running vieter inside gdb.
.PHONY: debug
debug: dvieter
dvieter: $(SOURCES) libvieter
	$(V_PATH) -showcc -keepc -cg -o dvieter $(SRC_DIR)

# Run the debug build inside gdb
.PHONY: gdb
gdb: dvieter
		gdb --args ./dvieter -f vieter.toml server

# Optimised production build
.PHONY: prod
prod: pvieter
pvieter: $(SOURCES) libvieter
	$(V) -o pvieter -prod $(SRC_DIR)

# Only generate C code
.PHONY: c
c: $(SOURCES) libvieter
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

.PHONY: man
man: vieter
	rm -rf man
	./vieter man man


# =====OTHER=====
# Linting
.PHONY: lint
lint:
	$(V) fmt -verify $(SRC_DIR)
	$(V) vet -W $(SRC_DIR)
	$(V_PATH) missdoc -p $(SRC_DIR)
	@ [ $$($(V_PATH) missdoc -p $(SRC_DIR) | wc -l) = 0 ]


# Formatting
.PHONY: fmt
fmt:
	$(V) fmt -w $(SRC_DIR)


# Testing
.PHONY: test
test: libvieter
	$(V) -g test $(SRC_DIR)


# Cleaning
.PHONY: clean
clean:
	rm -rf 'data' 'vieter' 'dvieter' 'pvieter' 'vieter.c' 'pkg' 'src/vieter' *.pkg.tar.zst 'suvieter' 'afvieter' '$(SRC_DIR)/_docs' 'docs/public'
	make -C '$(SRC_DIR)/libvieter' clean


# =====EXPERIMENTAL=====
.PHONY: autofree
autofree: afvieter
afvieter: $(SOURCES)
	$(V) -showcc -autofree -o afvieter $(SRC_DIR)

.PHONY: skip-unused
skip-unused: suvieter
suvieter: $(SOURCES)
	$(V) -skip-unused -o suvieter $(SRC_DIR)
