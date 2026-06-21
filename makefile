SHELL=/usr/bin/env bash
VENV=dev/.venv
VENV_BIN=$(VENV)/bin
BUILD_DIR=$(CURDIR)/build
MAKEFLAGS+=--warn-undefined-variables --silent

export
.PHONY: init test lint build clean run

# Runs all initialization recipes
init: git.setup.hooks uv.init

# Runs all unit tests
test: validate.openapi

# Runs all linters
lint:

# Builds all artifacts
build: build.docs

# Deletes built artifacts, call with CLEAN_ALL="true" to delete development dependencies
CLEAN_ALL="false"
clean:
	echo "Cleaning build artifacts" ;
	rm -rf "./build" ;
	if [ "$(CLEAN_ALL)" == "true" ] ; \
	then \
		echo "Cleaning development dependencies" ; \
		rm -rf "./dev/.venv/" ; \
	fi; \

# Starts the BEANfactory and all dependencies - defaults to docker runners
run:

###############
# Sub recipes #
###############

#########
# SETUP #
#########
# Commands to prepare the local developer environment

uv.init:
	cd dev/ && uv sync ;

########
# TEST #
########

validate.openapi:
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

#########
# BUILD #
#########

build.docs: generate.openapi.docs mkdocs.generate

#######
# RUN #
#######
# Scripts to start the BEANfactory and supporting servers

########
# DOCS #
########

generate.openapi.docs:
	for i in $$( find \
		./components/ \
		-maxdepth 2 \
		-type f \
		-name openapi.yaml \
	) ;\
	do \
		export APP="$$(echo $$i | rev | cut -d '/' -f 2 | rev )"; \
		export OUT_DIR="$(BUILD_DIR)/$$APP" ; \
		mkdir -p  $$OUT_DIR ; \
		echo Generating openAPI docs for $$APP at $$OUT_DIR ; \
		docker run \
 			--rm \
 			-v "$$i:/spec/openapi.yaml" \
 			-v "$$OUT_DIR:/out/" \
 			redocly/cli \
			build-docs \
 			openapi.yaml --output "/out/$$APP-redoc.html" ; \
	done ;

mkdocs.generate:
	mkdir -p "./build"
	$(VENV_BIN)/mkdocs build -s -d "./build/docs"


MKDOCS_ADDR="127.0.0.1:9999"
mkdocs.serve:
	echo "Serving docs at $(MKDOCS_ADDR)" ;
	$(VENV_BIN)/mkdocs serve \
		--dev-addr $(MKDOCS_ADDR) ;


#######
# GIT #
#######
# git helpers

git.commit.msg:
	$(VENV_BIN)/cz check --allow-abort --commit-msg-file "$(MSG)" ;

git.setup.hooks:
	echo Configuring Git hooks
	cp dev/githooks/* ./.git/hooks/
	find ./.git/hooks \
		-type f \
		-not -name "*.sample" \
		| xargs chmod +x

git.pre-commit: lint test
