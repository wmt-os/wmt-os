# SPDX-License-Identifier: MIT
#
# WMT OS Build System

SHELL := /bin/bash
NPROC := $(shell nproc)
PROFILE ?= standard

# Source ./config so the kernel build inherits ARCH, CROSS_COMPILE, and KCFLAGS
KMAKE := source ./config && $(MAKE) -C linux-wmt -j$(NPROC)

# Rebuild the rootfs when the settings, overlay, sources, or hooks change
ROOTFS_DEPS := config bootstrap/hooks.sh $(shell find overlays/rootfs bootstrap/sources -type f)
# Rebuild the image when the boot overlay changes (it bypasses the rootfs)
BOOT_DEPS := $(shell find overlays/boot -type f)

.DEFAULT_GOAL := help
.NOTPARALLEL:
.PHONY: help all deps repo sync reset rebase kconfig kernel modules deb rootfs standard desktop image clean distclean

help:  ## Show this help text
	@awk -F':.*## ' '/^[a-z][a-z-]*:.*##/ {printf "  \033[36m%-9s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: standard desktop  ## Build both disk images (standard + desktop)

# ---- Host dependencies ----

deps:  ## Install host build dependencies
	@sudo scripts/install-deps.sh

# ---- Kernel repository ----

repo: linux-wmt/.git  ## Clone the kernel repo
linux-wmt/.git:
	@scripts/clone-repo.sh

sync: repo  ## Sync the kernel repo to origin (keeps build artifacts)
	@scripts/sync-kernel.sh

reset: sync  ## Reset the kernel repo to origin (discards local changes)
	@scripts/reset-kernel.sh

rebase: reset  ## Rebase onto the latest upstream kernel (discards local changes)
	@scripts/rebase-kernel.sh

# ---- Kernel ----

kconfig: linux-wmt/.config  ## Generate the kernel config from the seed
linux-wmt/.config: kernel-seed.config | linux-wmt/.git
	@scripts/mk-kconfig.sh

linux-wmt/arch/arm/boot/zImage: linux-wmt/.config FORCE
	$(KMAKE) zImage dtbs
kernel: linux-wmt/arch/arm/boot/zImage  ## Build the kernel image and device tree

linux-wmt/modules.order: linux-wmt/.config FORCE
	$(KMAKE) modules
modules: linux-wmt/modules.order  ## Build the kernel modules

FORCE:

# ---- Debian package ----

deb: build/debs/Packages.gz  ## Build the kernel + metapackage + boot glue and local APT index
build/debs/Packages.gz: linux-wmt/arch/arm/boot/zImage linux-wmt/modules.order $(wildcard packages/wmt-boot/*)
	@scripts/mk-deb.sh

# ---- Image ----

rootfs: build/.rootfs-$(PROFILE)-stamp  ## Bootstrap the root filesystem
build/.rootfs-$(PROFILE)-stamp: build/debs/Packages.gz $(ROOTFS_DEPS)
	@sudo PROFILE=$(PROFILE) scripts/mk-rootfs.sh
	@touch build/.rootfs-$(PROFILE)-stamp

image: build/disk-$(PROFILE).img.gz  ## Build the disk image
build/disk-$(PROFILE).img.gz: build/.rootfs-$(PROFILE)-stamp $(BOOT_DEPS)
	@sudo PROFILE=$(PROFILE) scripts/mk-image.sh

standard:  ## Build the standard (default) disk image
	@$(MAKE) image PROFILE=standard

desktop:  ## Build the desktop disk image
	@$(MAKE) image PROFILE=desktop

# ---- Cleanup ----

clean:  ## Remove build artifacts
	@sudo rm -rf build/

distclean: clean  ## Remove build artifacts and the kernel repo
	@rm -rf linux-wmt/
