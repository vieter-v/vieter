# =====CONFIG=====
SRC_DIR := src
SOURCES != find '$(SRC_DIR)' -iname '*.v'

LARCHIVE_VER := 3.5.2
LARCHIVE_DIR := libarchive-$(LARCHIVE_VER)
LARCHIVE_LIB := $(LARCHIVE_DIR)/libarchive/libarchive.so

# Custom V command for linking libarchive
# V := LDFLAGS=$(PWD)/$(LARCHIVE_LIB) v -cflags '-I$(PWD)/$(LARCHIVE_DIR) -I $(PWD)/$(LARCHIVE_DIR)'
V := v -showcc

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

.PHONY: c
c:
	$(V) -o vieter.c $(SRC_DIR)


# =====EXECUTION=====
# Run the server in the default 'data' directory
.PHONY: run
run: vieter
	 API_KEY=test DOWNLOAD_DIR=data/downloads REPO_DIR=data/repo PKG_DIR=data/pkgs LOG_LEVEL=DEBUG ./vieter

.PHONY: run-prod
run-prod: prod
	 API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG ./pvieter

# Same as run, but restart when the source code changes
.PHONY: watch
watch:
	API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG $(V) watch run vieter


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

# Pulls & builds my personal build of the v compiler, required for this project to function
.PHONY: customv
customv:
	rm -rf v-jjr
	git clone \
		-b vweb-streaming \
		--single-branch \
		https://github.com/ChewingBever/v jjr-v
	'$(MAKE)' -C jjr-v


# =====LIBARCHIVE=====
.PHONY: libarchive
libarchive: $(LARCHIVE_LIB)
$(LARCHIVE_LIB):
	curl -o - "https://libarchive.org/downloads/libarchive-${LARCHIVE_VER}.tar.gz" | tar xzf -
	cd "libarchive-${LARCHIVE_VER}" && cmake .
	'$(MAKE)' -C "libarchive-${LARCHIVE_VER}"

clean:
	rm -rf '$(LARCHIVE_DIR)' 'data' 'vieter' 'dvieter' 'pvieter' 'vieter.c'
