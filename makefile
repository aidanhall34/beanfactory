SHELL=/usr/bin/env bash
VENV=dev/.venv
VENV_BIN = $(VENV)/bin

export
.PHONY: setup test lint run

# Runs all initialization recipes
setup: git.setup.hooks uv.init.dev

# Runs all unit tests
test: openapi-validate

# Runs all linters
lint:

# Starts the BEANfactory and all dependencies - defaults to docker runners
run:

#########
# SETUP #
#########
# Commands to prepare the local developer environment

uv.init.dev:
	@cd dev/ && uv sync ;

########
# TEST #
########
openapi-validate:
	for i in $$( find \
		./components/ \
		-maxdepth 2 \
		-type f \
		-name openapi.yaml \
	) ;\
	do \
		echo Validating "$$i" ; \
		$(VENV_BIN)/openapi-spec-validator "$$i" ; \
	done ;

########
# LINT #
########

#######
# RUN #
#######
# Scripts to start the BEANfactory

#######
# GIT #
#######
# git helpers

git.commit.msg:
	$(VENV_BIN)/cz check --allow-abort --commit-msg-file $(MSG) ;

git.setup.hooks:
	@echo Configuring Git hooks
	@cp dev/githooks/* ./.git/hooks/
	@find ./.git/hooks \
		-type f \
		-not -name "*.sample" \
		| xargs chmod +x
