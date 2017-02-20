MAKEFLAGS += --warn-undefined-variables
SHELL := sh
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := test
.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY: test

SOURCE ?= source
DIFF ?= diff

test:
	# Load test environment and generate task definitions
	@$(SOURCE) ./load-env.sh && \
		DEPLOY_DATE=1466876553 $(MAKE) -C .. task-definitions
	# Check the generated tast definitions
	@$(DIFF) -Naur ../config/task-definitions.json ./expected-task-definitions.json
	# Looks good!
