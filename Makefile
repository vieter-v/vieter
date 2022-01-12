# =====CONFIG=====
LARCHIVE_VER := 3.5.2
LARCHIVE_DIR := libarchive-$(LARCHIVE_VER)
LARCHIVE_LIB := $(LARCHIVE_DIR)/.libs/libarchive.a

# Custom V command for linking libarchive
V := LDFLAGS=$(PWD)/$(LARCHIVE_LIB) v -cflags -I$(PWD)/$(LARCHIVE_DIR)


# =====COMPILATION=====
.PHONY: vieter
vieter:
	$(V) -cg -o vieter.exe vieter

.PHONY: prod
prod:
	$(V) -o vieter-prod.exe -prod vieter


# =====EXECUTION=====
# Run the server in the default 'data' directory
.PHONY: run
run: libarchive
	 API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG $(V) run vieter

# Same as run, but restart when the source code changes
.PHONY: watch
watch: libarchive
	API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG $(V) watch run vieter


# =====OTHER=====
# Format the V codebase
.PHONY: fmt
fmt:
	v fmt -w vieter

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
	cd "libarchive-${LARCHIVE_VER}" && ./configure --disable-bsdtar --disable-bsdcpio
	'$(MAKE)' -C "libarchive-${LARCHIVE_VER}"

clean:
	rm -rf '$(LARCHIVE_DIR)' 'data'
