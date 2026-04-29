#!/bin/sh
set -e
. /usr/local/share/devcontainers/util.sh

ARM_TOOLCHAIN_VER=${VERSION:-13.3.rel1}
TOOLCHAIN_DIR="/opt/gcc-arm-none-eabi"
TOOLCHAIN_URL="https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_TOOLCHAIN_VER}/binrel/arm-gnu-toolchain-${ARM_TOOLCHAIN_VER}-x86_64-arm-none-eabi.tar.xz"

install_arm_gnu_rhel() {
	log_debug "install_arm_gnu_rhel: starting"

	log_debug "Installing ncurses-compat-libs via dnf"
	dnf -y install ncurses-compat-libs 2>/dev/null || true
	log_debug "ncurses-compat-libs installed"

	log_debug "install_arm_gnu_rhel: complete"
}

install_arm_gnu_debian() {
	log_debug "install_arm_gnu_debian: starting"

	export DEBIAN_FRONTEND=noninteractive
	log_debug "Updating apt cache"
	apt-get update -qq

	log_debug "Installing libncurses5 via apt"
	apt-get -y install libncurses5 2>/dev/null || true
	log_debug "libncurses5 installed"

	log_debug "install_arm_gnu_debian: complete"
}

download_and_install_toolchain() {
	log_debug "download_and_install_toolchain: starting"

	if [ -d "$TOOLCHAIN_DIR" ] && [ -x "$TOOLCHAIN_DIR/bin/arm-none-eabi-gcc" ]; then
		version=$("$TOOLCHAIN_DIR/bin/arm-none-eabi-gcc" --version 2>&1 | head -n1)
		log_info "ARM GNU toolchain is already installed: ${version}"
		return 0
	fi

	log_debug "Toolchain not found, downloading"
	log_info "Downloading ARM GNU toolchain ${ARM_TOOLCHAIN_VER}"
	echo ""

	if ! has_command curl; then
		log_error "This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
		return 1
	fi

	log_debug "Downloading from ${TOOLCHAIN_URL}"
	curl -Lo gcc-arm-none-eabi.tar.xz "$TOOLCHAIN_URL"

	log_debug "Creating toolchain directory"
	mkdir -p "$TOOLCHAIN_DIR"

	log_debug "Extracting toolchain"
	tar xf gcc-arm-none-eabi.tar.xz --strip-components=1 -C "$TOOLCHAIN_DIR"

	log_debug "Cleaning up"
	rm gcc-arm-none-eabi.tar.xz

	log_debug "Creating symlinks in /usr/bin"
	ln -sf "$TOOLCHAIN_DIR"/bin/* /usr/bin/

	log_debug "download_and_install_toolchain: complete"
}

verify_installation() {
	log_debug "verify_installation: starting"

	if command -v arm-none-eabi-gcc >/dev/null 2>&1; then
		version=$(arm-none-eabi-gcc --version 2>&1 | head -n1)
		log_debug "ARM GNU toolchain ${version} installed successfully"
	else
		log_error "ARM GNU toolchain installation verification failed"
	fi

	log_debug "verify_installation: complete"
}

log_debug "Activating feature 'arm-gnu'"

OS=$(detect_os)
log_debug "Detected OS: $OS"

case "$OS" in
rhel)
	log_info "Installing for rhel"
	install_arm_gnu_rhel
	;;
debian)
	log_info "Installing for debian"
	install_arm_gnu_debian
	;;
*)
	log_error "Unknown OS"
	;;
esac

download_and_install_toolchain
verify_installation

log_debug "Done"
