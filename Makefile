.PHONY: run
run:
	API_KEY=test REPO_DIR=data LOG_LEVEL=DEBUG v watch run vieter

.PHONY: fmt
fmt:
	v fmt -w vieter
