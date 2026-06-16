.PHONY: all build-env compile package clean help

APP_VERSION ?= 3.16.2
SOURCE_DIR ?= /home/reallab_zwx/Desktop/cc-switch-source
OUTPUT_DIR ?= $(PWD)/output
FLATPAK_BUILD_DIR ?= /home/reallab_zwx/Desktop/cc-switch-flatpak-build
RUST_TOOLCHAIN ?= 1.95.0
RUST_MIRROR ?= https://rsproxy.cn

help:
	@echo "CC Switch Flatpak Build (Ubuntu 20.04 Compatible)"
	@echo ""
	@echo "Targets:"
	@echo "  make build-env  - Set up Rust toolchain and verify SDK"
	@echo "  make compile    - Build frontend and backend"
	@echo "  make package    - Create .flatpak bundle"
	@echo "  make all        - Build everything (build-env + compile + package)"
	@echo "  make install    - Install the flatpak"
	@echo "  make run        - Run CC Switch"
	@echo "  make clean      - Remove build artifacts"
	@echo ""
	@echo "Prerequisites:"
	@echo "  flatpak, flatpak-builder, org.gnome.Sdk//46, org.gnome.Platform//46"
	@echo ""

build-env:
	@echo "=== Setting up Rust $(RUST_TOOLCHAIN) ==="
	export RUSTUP_DIST_SERVER=$(RUST_MIRROR) && \
	export RUSTUP_UPDATE_ROOT=$(RUST_MIRROR)/rustup && \
	rustup toolchain install $(RUST_TOOLCHAIN) --profile minimal 2>/dev/null || true
	rustup default $(RUST_TOOLCHAIN)
	@echo "=== Verifying SDK ==="
	flatpak info org.gnome.Sdk//46 >/dev/null 2>&1 || \
		flatpak install --user flathub org.gnome.Sdk//46 org.gnome.Platform//46
	@echo "=== Build environment ready ==="

compile:
	@echo "=== Building frontend ==="
	cd $(SOURCE_DIR) && pnpm install --frozen-lockfile && pnpm run build:renderer
	@echo "=== Building backend inside GNOME 46 SDK ==="
	flatpak build --share=network --filesystem=home \
		/home/reallab_zwx/Desktop/cc-switch-flatpak-build \
		bash -c "export PATH=$(HOME)/.rustup/toolchains/$(RUST_TOOLCHAIN)-x86_64-unknown-linux-gnu/bin:\$$PATH; \
		export RUSTUP_HOME=$(HOME)/.rustup; export CARGO_HOME=$(HOME)/.cargo; \
		cd $(SOURCE_DIR)/src-tauri && cargo build --release"
	@echo "=== Binary ==="
	@ls -lh $(SOURCE_DIR)/src-tauri/target/release/cc-switch

package:
	@echo "=== Preparing files ==="
	rm -rf $(FLATPAK_BUILD_DIR)/files
	mkdir -p $(FLATPAK_BUILD_DIR)/files/lib
	cp $(SOURCE_DIR)/src-tauri/target/release/cc-switch $(FLATPAK_BUILD_DIR)/files/
	cp $(SOURCE_DIR)/src-tauri/icons/128x128.png $(FLATPAK_BUILD_DIR)/files/
	cp -a $(FLATPAK_BUILD_DIR)/files/lib/*.so* $(FLATPAK_BUILD_DIR)/files/lib/ 2>/dev/null || true
	cd $(FLATPAK_BUILD_DIR) && flatpak-builder --force-clean --user \
		--repo=flatpak-repo flatpak-build-dir com.ccswitch.desktop.yml
	mkdir -p $(OUTPUT_DIR)
	flatpak build-bundle $(FLATPAK_BUILD_DIR)/flatpak-repo \
		$(OUTPUT_DIR)/CC-Switch.flatpak com.ccswitch.desktop
	@echo "=== Flatpak created ==="
	@ls -lh $(OUTPUT_DIR)/CC-Switch.flatpak

all: build-env compile package
	@echo "=== All done! ==="

install:
	flatpak install --user $(OUTPUT_DIR)/CC-Switch.flatpak

run:
	flatpak run com.ccswitch.desktop

clean:
	cargo clean --manifest-path $(SOURCE_DIR)/src-tauri/Cargo.toml 2>/dev/null || true
	rm -rf $(FLATPAK_BUILD_DIR)/flatpak-build-dir $(FLATPAK_BUILD_DIR)/.flatpak-builder
	rm -rf $(OUTPUT_DIR)/*
	@echo "Cleaned"
