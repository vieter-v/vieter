# =====CONFIG=====
SRC_DIR := src
SOURCES != find '$(SRC_DIR)' -iname '*.v'

LARCHIVE_VER := 3.5.2
LARCHIVE_DIR := libarchive-$(LARCHIVE_VER)
LARCHIVE_LIB := $(LARCHIVE_DIR)/libarchive/libarchive.so

# Custom V command for linking libarchive
# V := LDFLAGS=$(PWD)/$(LARCHIVE_LIB) v -cflags '-I$(PWD)/$(LARCHIVE_DIR) -I $(PWD)/$(LARCHIVE_DIR)'
V := v


# =====COMPILATION=====
.PHONY: debug
debug: vieter
vieter: $(SOURCES)
	$(V) -cg -o vieter $(SRC_DIR)

.PHONY: prod
prod: vieter-prod
vieter-prod: $(SOURCES)
	$(V) -o vieter-prod -prod $(SRC_DIR)


# =====EXECUTION=====
# Run the server in the default 'data' directory
.PHONY: run
run: vieter
	 API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG ./vieter

# Same as run, but restart when the source code changes
.PHONY: watch
watch:
	API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG $(V) watch run vieter


# =====OTHER=====
# Format the V codebase
.PHONY: fmt
fmt:
	v fmt -w $(SRC_DIR)

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
	rm -rf '$(LARCHIVE_DIR)' 'data' 'vieter' 'vieter-prod'
