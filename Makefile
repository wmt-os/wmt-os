# WMT OS Build System
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

SHELL := /bin/bash
PROFILE ?= standard

.DEFAULT_GOAL := help
.NOTPARALLEL:
.PHONY: help all deps repo sync reset rebase config kernel modules debs rootfs standard desktop image clean mrproper distclean

help:  ## Show this help text
	@awk -F':.*## ' '/^[a-z][a-z-]*:.*##/ {printf "  \033[36m%-9s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: standard desktop  ## Build both disk images (standard + desktop)

# ---- Host dependencies ----

deps:  ## Install host build dependencies
	@sudo NICE=$(NICE) scripts/install-deps.sh

# ---- Kernel repository ----

repo: linux-wmt/.git  ## Clone the kernel repo
linux-wmt/.git:
	@scripts/clone-repo.sh

sync: repo  ## Sync the kernel repo to origin (keeps build artifacts)
	@scripts/sync-kernel.sh

reset: sync  ## Reset the kernel repo to origin (discards local changes)
	@scripts/reset-kernel.sh

rebase: sync  ## Rebase onto the latest upstream kernel (keeps build artifacts)
	@scripts/rebase-kernel.sh

# ---- Kernel ----

config:  ## Generate the kernel config from the seed
	@scripts/mk-config.sh
linux-wmt/.config: kernel-seed.config | linux-wmt/.git
	@scripts/mk-config.sh

# Source lib.sh so the kernel build inherits ARCH/CROSS_COMPILE/KCFLAGS and runs reniced;
# kernel-id.sh aligns LOCALVERSION and the baked timestamp with mk-debs's builds
KMAKE := . ./scripts/lib.sh && $(MAKE) -C linux-wmt -j$$(nproc) \
	LOCALVERSION=-$$(scripts/kernel-id.sh) KBUILD_BUILD_TIMESTAMP="$$(scripts/kernel-id.sh stamp)"

linux-wmt/arch/arm/boot/zImage: linux-wmt/.config FORCE
	$(KMAKE) zImage dtbs
kernel: linux-wmt/arch/arm/boot/zImage  ## Build the kernel image

linux-wmt/modules.order: linux-wmt/.config FORCE
	$(KMAKE) modules
modules: linux-wmt/modules.order  ## Build the kernel modules

FORCE:

# ---- Debian packages ----

debs: build/debs/Packages.gz  ## Build the kernel deb packages
build/debs/Packages.gz: linux-wmt/arch/arm/boot/zImage linux-wmt/modules.order $(shell find packages -type f)
	@scripts/mk-debs.sh

# ---- Image ----

rootfs: build/rootfs-$(PROFILE)  ## Bootstrap the root filesystem
build/rootfs-$(PROFILE): build/debs/Packages.gz config.sh $(shell find overlays/rootfs* bootstrap -type f)
	@sudo PROFILE=$(PROFILE) NICE=$(NICE) scripts/mk-rootfs.sh

# Newest image decides freshness
IMG := $(or $(shell ls -t build/*-$(PROFILE)-*.img* 2>/dev/null | grep -v '\.sha256$$' | head -n1),NOIMAGE)

image: $(IMG)  ## Build the disk image
$(IMG): build/rootfs-$(PROFILE)
	@sudo PROFILE=$(PROFILE) NICE=$(NICE) XZ_LEVEL=$(XZ_LEVEL) IMG_SIZE=$(IMG_SIZE) scripts/mk-image.sh

standard:  ## Build the standard (default) disk image
	@$(MAKE) image PROFILE=standard

desktop:  ## Build the desktop disk image
	@$(MAKE) image PROFILE=desktop

# ---- Cleanup ----

clean:  ## Remove build artifacts and the kernel config
	@sudo rm -rf build/ linux-wmt/.config*

mrproper: clean  ## Remove build artifacts and reset kernel repo
	@scripts/reset-kernel.sh

distclean: clean  ## Remove build artifacts and the kernel repo
	@rm -rf linux-wmt/
