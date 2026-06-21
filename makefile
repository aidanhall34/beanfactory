# Make options
SHELL=/usr/bin/env bash
MAKEFLAGS+=--warn-undefined-variables --silent

# Paths
BUILD_DIR=$(CURDIR)/build
DEV_DIR=$(CURDIR)/dev
CONFIG_DIR=$(DEV_DIR)/configs/
VENV_BIN=$(DEV_DIR)/.venv/bin
NPM_BIN=$(DEV_DIR)/node_modules/.bin

export
.PHONY: init test lint build clean run

# Runs all initialization recipes
init: git.setup.hooks uv.init npm.init

# Runs all unit tests
test: validate.openapi

# Runs all linters
lint:

# Builds all artifacts
build: build.docs

# Deletes built artifacts
# call with CLEAN_ALL="true" to delete development dependencies
CLEAN_ALL="false"
clean:
	echo "Cleaning build artifacts" ;
	rm -rf "$(BUILD_DIR)" ;
	if [[ "$(CLEAN_ALL)" == "true" ]] ; \
	then \
		echo "Cleaning development dependencies" ; \
		rm -rf "$(DEV_DIR)/.venv/" ; \
		rm -rf "$(DEV_DIR)/node_modules/" ; \
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
	uv sync --directory $(DEV_DIR) ;

npm.init:
	npm ci --prefix $(DEV_DIR)


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

# Pinned to trusted builds
# https://hub.docker.com/layers/trufflesecurity/trufflehog/3.95.6/images/sha256-8fcc7f10e11856f98d92fd86b66f7d63a32591cf934ff9f6438f4092b183510b
trufflehog.scan:
	docker run \
		-v "$$(PWD):/pwd" \
		"ghcr.io/trufflesecurity/trufflehog@sha256:96f8429082cb2d4ae73b1096dcdb2f5aa139881d97042b0c5e5fa226a392e056" \
		git \
		file:///pwd


lint.markdown:
	$(NPM_BIN)/markdownlint-cli2 "**.md" "!./**/.venv" "!./**/node_modules"

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
	mkdir -p "$(BUILD_DIR)" ;
	$(VENV_BIN)/mkdocs build -s --config-file "$(CONFIG_DIR)/mkdocs.yml" ;


MKDOCS_ADDR="127.0.0.1:9999"
mkdocs.serve:
	echo "Serving docs at $(MKDOCS_ADDR)" ;
	$(VENV_BIN)/mkdocs serve \
		--config-file "$(CONFIG_DIR)/mkdocs.yml" \
		--dev-addr $(MKDOCS_ADDR) ;

#######
# GIT #
#######
# git helpers

git.setup.hooks:
	echo Configuring Git hooks
	cp $(DEV_DIR)/githooks/* $(CURDIR)/.git/hooks/
	find $(CURDIR)/.git/hooks \
		-type f \
		-not -name "*.sample" \
		| xargs chmod +x ;

git.commit-msg:
	$(VENV_BIN)/cz check --allow-abort --commit-msg-file "$(MSG)" ;

git.pre-commit: lint test

git.pre-push: trufflehog.scan
