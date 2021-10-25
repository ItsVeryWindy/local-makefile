GIT_REPO := ItsVeryWindy/remote-makefile.git
CACHE_DIR := $(shell echo $${TMPDIR-/tmp}/dds)
GIT_DIR := $(CACHE_DIR)/repo
GIT_BRANCH := master
CURRENT_DIR := $(shell pwd)
GIT_HASH_FILE := GIT_HASH
GIT_HASH := $(shell cat $(GIT_HASH_FILE) 2>/dev/null)
CHECKOUT_DIR := $(CACHE_DIR)/checkouts/$(GIT_HASH)
GIT_MAKEFILE := $(CHECKOUT_DIR)/Makefile

all: $(GIT_MAKEFILE)
	@:

$(CACHE_DIR):
	@mkdir $(CACHE_DIR)

$(GIT_DIR): | $(CACHE_DIR)
	@\
	set -e; \
	HTTPS_CLONE_URL="https://github.com/$(GIT_REPO)"; \
	SSH_CLONE_URL="git@github.com:$(GIT_REPO)"; \
	USE_HTTPS=$$(git ls-remote "$$HTTPS_CLONE_URL" > /dev/null 2>&1 && echo "1" || echo "0"); \
	USE_SSH=$$([ "$$USE_HTTPS" != "1" ] && git ls-remote "$$SSH_CLONE_URL" > /dev/null 2>&1 && echo "1" || echo "0"); \
	if [ "$$USE_HTTPS" != "1" ] && [ "$$USE_SSH" != "1" ]; then \
		echo "Neither https or ssl can be used to clone the repo"; \
		exit 1; \
	fi; \
	echo "Creating directory $(GIT_DIR)..."; \
	mkdir "$(GIT_DIR)"; \
	GIT_CLONE_URL=$$([ "$$USE_HTTPS" = "1" ] && echo "$$HTTPS_CLONE_URL" || echo "$$SSH_CLONE_URL"); \
	echo "Cloning repository $$HTTPS_CLONE_URL..."; \
	git clone "$$GIT_CLONE_URL" --no-checkout "$(GIT_DIR)"

$(GIT_HASH_FILE): | $(GIT_DIR)
	@cd $(GIT_DIR) && git rev-parse HEAD > $(CURRENT_DIR)/$(GIT_HASH_FILE)
	@$(MAKE) --no-print-directory

$(CHECKOUT_DIR): $(GIT_HASH_FILE)
	@rm -rf $(CHECKOUT_DIR)
	@mkdir -p $(CHECKOUT_DIR)
	@cd $(GIT_DIR) && git fetch origin $(GIT_BRANCH)
	@cd $(GIT_DIR) && git reset --hard origin/$(GIT_BRANCH)
	@cd $(GIT_DIR) && git archive $$(cat $(CURRENT_DIR)/$(GIT_HASH_FILE)) | tar -x -C $(CHECKOUT_DIR)/

$(GIT_MAKEFILE): $(CHECKOUT_DIR)
	@touch $(GIT_MAKEFILE)
	@$(MAKE) --no-print-directory

clean-cache: ## remove remote makefile cache
	@rm -rf $(CACHE_DIR)
	@$(MAKE) --no-print-directory

update-hash: | $(GIT_DIR) ## update remote makefile to latest version
	@cd $(GIT_DIR) && git fetch origin $(GIT_BRANCH)
	@cd $(GIT_DIR) && git reset --hard origin/$(GIT_BRANCH)
	@rm -f $(GIT_HASH_FILE)
	@$(MAKE) --no-print-directory

-include $(GIT_MAKEFILE)

hello: hello2 ## eh?
	@echo "hello world"
	@echo a $(GIT_DIR) $(GIT_CLONE_URL) $(MAKEFILE_LIST)