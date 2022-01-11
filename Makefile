.PHONY: run
run:
	API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG v -cg run vieter

.PHONY: run-prod
run-prod:
	API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG v -prod run vieter

.PHONY: watch
watch:
	API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG v watch run vieter

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
