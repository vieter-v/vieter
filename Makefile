.PHONY: run
run:
	API_KEY=test REPO_DIR=data v watch run vieter

.PHONY: fmt
fmt:
	v fmt -w vieter
