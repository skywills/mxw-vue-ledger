MAKEFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_PATH := $(shell pwd)
SERVICE_NAME := mxw-ledger-portal
REGISTRY_URL := registry-intl.cn-hongkong.aliyuncs.com/oepay/

.PHONY: version name image
all: test

version-major: version-sync
	@npm -s version major --no-git-tag-version

version-minor: version-sync
	@npm -s version minor --no-git-tag-version

version-patch: version-sync
	@npm -s version patch --no-git-tag-version

version-prerelease: version-sync
	@npm -s version prerelease --preid=rc --no-git-tag-version

version-latest:
	@(git tag --sort=-creatordate || echo) | awk 'NR==1 { \
		split($$0, n, "-"); \
		if (n[1] != "") { \
			split(n[1], v, "."); \
			if (v[1] ~ /^[0-9]+$$/ && v[2] ~ /^[0-9]+$$/ && v[3] ~ /^[0-9]+$$/) { \
				print $$0; \
				exit 0; \
			} \
		} \
		print "1.0.0-rc.0"; \
	 } \
	 END { \
		 if (NR == 0) { \
			 print "1.0.0-rc.0"; \
		 } \
	 }'

version-sync:
	@git checkout $(CI_COMMIT_BRANCH)
	@git pull --tags 2&>/dev/null || true
	@git tag --sort=-creatordate | head -10
	@cat package.json | jq -r --arg PKG_VERSION `make --no-print-directory -f$(MAKEFILE) version-latest` '.version=$$PKG_VERSION' > package.json;
	@echo -n "Current Git tag: "; cat package.json | jq -r '.version'

version:
	@echo $(shell node -p "require('$(ROOT_PATH)/package.json').version")

name:
	@echo $(SERVICE_NAME)

image:
	@echo $(SERVICE_NAME):$(shell node -p "require('$(ROOT_PATH)/package.json').version")

test:
	@echo SKIPPED

build-docker:
	docker build -t $(SERVICE_NAME):$(shell node -p "require('$(ROOT_PATH)/package.json').version") .

release:
	@docker tag $(SERVICE_NAME):$(shell node -p "require('$(ROOT_PATH)/package.json').version") \
		$(REGISTRY_URL)$(SERVICE_NAME):$(shell node -p "require('$(ROOT_PATH)/package.json').version")
	@docker push $(REGISTRY_URL)$(SERVICE_NAME):$(shell node -p "require('$(ROOT_PATH)/package.json').version")