LATEST_COMPOSER = 1.10.7
COMPOSER_BRANCHES = 1.9.3 1.10.7 2.0.0-alpha1
PHP_VERSIONS = 7.2 7.3 7.4
REPO_NAME = "pimlab/composer"

COMPOSER_INSTALLER_URL ?= https://raw.githubusercontent.com/composer/getcomposer.org/cb19f2aa3aeaa2006c0cd69a7ef011eb31463067/web/installer
COMPOSER_INSTALLER_HASH ?= 48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5

.PHONY = all build test template

all: template build test tag

build:
	@for branch in $(COMPOSER_BRANCHES); do \
	    for php in $(PHP_VERSIONS); do \
	        dir=$$branch/php$$php; \
	        if [ $$branch = $(LATEST_COMPOSER) ]; then \
	            docker build --tag composer:$$branch-php$$php --tag composer:latest-php$$php $$dir; \
	        else \
	            docker build --tag composer:$$branch-php$$php $$dir; \
	        fi \
	    done \
	done \

test:
	@for branch in $(COMPOSER_BRANCHES); do \
	    for php in $(PHP_VERSIONS); do \
	        if [ $$branch = $(LATEST_COMPOSER) ]; then \
	            echo "Test latest Composer $$branch for PHP $$php"; \
	            docker run --rm --tty composer:latest-php$$php --no-ansi | grep "Composer version $$branch"; \
	        else \
	            echo "Test Composer $$branch for PHP $$php"; \
	            docker run --rm --tty composer:$$branch-php$$php --no-ansi | grep "Composer version $$branch"; \
	        fi \
	    done \
	done \

tag:
	@for branch in $(COMPOSER_BRANCHES); do \
	    for php in $(PHP_VERSIONS); do \
	        dir=$$branch/php$$php; \
	        if [ $$branch = $(LATEST_COMPOSER) ]; then \
	            docker tag composer:$$branch-php$$php $(REPO_NAME):$$branch-php$$php; \
	            docker push $(REPO_NAME):$$branch-php$$php; \
	            docker tag composer:latest-php$$php $(REPO_NAME):latest-php$$php; \
	            docker push $(REPO_NAME):latest-php$$php; \
	        else \
	            docker tag composer:$$branch-php$$php $(REPO_NAME):$$branch-php$$php; \
	            docker push $(REPO_NAME):$$branch-php$$php; \
	        fi \
	    done \
	done \

template:
	@for branch in $(COMPOSER_BRANCHES); do \
	    rm -R ./$$branch; \
	    for php in $(PHP_VERSIONS); do \
	        echo "Create Dockerfile for Composer $$branch with PHP $$php"; \
	        dir=$$branch/php$$php; \
	        mkdir -p $$dir; \
	        cp docker-entrypoint.sh $$dir; \
	        cp Dockerfile.template $$dir/Dockerfile; \
	        sed -i --expression 's@%PHP_VERSION%@'$$php'@' \
	           --expression 's@%COMPOSER_VERSION%@'$$branch'@' \
               --expression 's@%COMPOSER_INSTALLER_URL%@$(COMPOSER_INSTALLER_URL)@' \
               --expression 's@%COMPOSER_INSTALLER_HASH%@$(COMPOSER_INSTALLER_HASH)@' \
               $$dir/Dockerfile; \
	    done \
	done \

clear:
	@for branch in $(COMPOSER_BRANCHES); do \
	    rm -R ./$$branch; \
	done \