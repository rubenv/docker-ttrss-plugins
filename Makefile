# IMAGE is supplied by direnv (.envrc) or explicitly on the command line.
TAG ?= latest
PODMAN ?= podman
BUILD_ARGS ?=

.DEFAULT_GOAL := build
.PHONY: build push

build:
	@test -n "$(IMAGE)" || { echo "IMAGE is required; run direnv allow or set IMAGE explicitly." >&2; exit 1; }
	$(PODMAN) build --pull=always $(BUILD_ARGS) -t $(IMAGE):$(TAG) .

push: build
	$(PODMAN) push $(IMAGE):$(TAG)
