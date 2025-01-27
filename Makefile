SEVERITIES = HIGH,CRITICAL

ifeq ($(ARCH),)
ARCH=$(shell go env GOARCH)
endif

BUILD_META=-build$(shell date +%Y%m%d)
ORG ?= rancher
PKG ?= github.com/kubernetes-sigs/cri-tools
SRC ?= github.com/kubernetes-sigs/cri-tools
TAG ?= v1.21.0$(BUILD_META)

ifneq ($(DRONE_TAG),)
TAG := $(DRONE_TAG)
endif

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG needs to end with build metadata: $(BUILD_META))
endif

GOLANG_VERSION := $(shell if echo $(TAG) | grep -qE '^v1\.(18|19|20)\.'; then echo v1.15.15b5; else echo v1.16.7b7; fi)

.PHONY: image-build
image-build:
	docker build \
		--pull \
		--build-arg PKG=$(PKG) \
		--build-arg SRC=$(SRC) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--build-arg GO_IMAGE=rancher/hardened-build-base:$(GOLANG_VERSION) \
		--tag $(ORG)/hardened-crictl:$(TAG) \
		--tag $(ORG)/hardened-crictl:$(TAG)-$(ARCH) \
	.

.PHONY: image-push
image-push:
	docker push $(ORG)/hardened-crictl:$(TAG)-$(ARCH)

.PHONY: image-manifest
image-manifest:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-crictl:$(TAG) \
		$(ORG)/hardened-crictl:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-crictl:$(TAG)

.PHONY: image-scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-crictl:$(TAG)
