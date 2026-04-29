#!/bin/sh
set -e
. /usr/local/share/devcontainers/util.sh

PICO_SDK_VER=${VERSION:-2.2.0}
SDK_DIR="/opt/pico-sdk"
PICOTOOL_DIR="/opt/picotool"

install_pico_rhel() {
	log_debug "install_pico_rhel: starting"

	log_debug "Installing libusb via dnf"
	dnf -y install libusb1-devel 2>/dev/null || true
	log_debug "libusb installed"

	log_debug "install_pico_rhel: complete"
}

install_pico_debian() {
	log_debug "install_pico_debian: starting"

	export DEBIAN_FRONTEND=noninteractive
	log_debug "Updating apt cache"
	apt-get update -qq

	log_debug "Installing libusb via apt"
	apt-get -y install libusb-1.0-0-dev 2>/dev/null || true
	log_debug "libusb installed"

	log_debug "install_pico_debian: complete"
}

install_pico_sdk() {
	log_debug "install_pico_sdk: starting"

	if [ -d "$SDK_DIR" ] && [ -f "$SDK_DIR/pico_sdk_init.cmake" ]; then
		version=$(grep -oP 'set\(SDK_VERSION_MAJOR \K\d+' "$SDK_DIR/CMakeLists.txt" 2>/dev/null | head -1)
		log_info "Pico SDK is already installed at ${SDK_DIR}"
		return 0
	fi

	log_debug "SDK not found, cloning"
	log_info "Cloning Pico SDK version ${PICO_SDK_VER}"
	echo ""

	if ! has_command git; then
		log_error "This feature requires git to be installed."
		return 1
	fi

	log_debug "Cloning SDK directly to ${SDK_DIR}"
	git clone --branch "${PICO_SDK_VER}" --depth 1 https://github.com/raspberrypi/pico-sdk.git "$SDK_DIR"

	log_debug "Initializing submodules"
	cd "$SDK_DIR" && git submodule update --init

	log_debug "Setting permissions"
	chown -R root:root "$SDK_DIR"

	log_debug "install_pico_sdk: complete"
}

install_picotool() {
	log_debug "install_picotool: starting"

	if command -v picotool >/dev/null 2>&1; then
		version=$(picotool version 2>&1 | head -n1)
		log_info "picotool is already installed: ${version}"
		return 0
	fi

	log_debug "picotool not found, building from source"
	log_info "Building and installing picotool"
	echo ""

	if ! has_command cmake; then
		log_error "This feature requires cmake to build picotool."
		return 1
	fi

	log_debug "Cloning picotool"
	git clone https://github.com/raspberrypi/picotool.git "$PICOTOOL_DIR"

	log_debug "Building picotool"
	cd "$PICOTOOL_DIR"
	export PICO_SDK_PATH="$SDK_DIR"
	cmake -S . -B build
	cmake --build build

	log_debug "Installing picotool"
	cmake --install build

	log_debug "Installing udev rules for picotool"
	if [ -f "$PICOTOOL_DIR/udev/99-picotool.rules" ]; then
		cp "$PICOTOOL_DIR/udev/99-picotool.rules" /etc/udev/rules.d/ 2>/dev/null || true
		udevadm control --reload-rules && udevadm trigger 2>/dev/null || true
	fi

	log_debug "install_picotool: complete"
}

set_pico_env() {
	log_debug "set_pico_env: starting"

	log_debug "Setting PICO_SDK_PATH environment variable"

	remote_user_run "echo \"export PICO_SDK_PATH=$SDK_DIR\" >> ~/.zshrc"

	if [ -d "$SDK_DIR" ]; then
		remote_user_run "echo \"export PICO_SDK_PATH=$SDK_DIR\" >> ~/.zshrc"
	fi

	log_debug "set_pico_env: complete"
}

verify_installation() {
	log_debug "verify_installation: starting"

	if [ -d "$SDK_DIR" ] && [ -f "$SDK_DIR/pico_sdk_init.cmake" ]; then
		log_debug "Pico SDK found at ${SDK_DIR}"
	else
		log_error "Pico SDK installation verification failed"
	fi

	if command -v picotool >/dev/null 2>&1; then
		version=$(picotool version 2>&1 | head -n1)
		log_debug "picotool ${version} installed successfully"
	else
		log_error "picotool installation verification failed"
	fi

	log_debug "verify_installation: complete"
}

log_debug "Activating feature 'pico-sdk'"

OS=$(detect_os)
log_debug "Detected OS: $OS"

case "$OS" in
rhel)
	log_info "Installing for rhel"
	install_pico_rhel
	;;
debian)
	log_info "Installing for debian"
	install_pico_debian
	;;
*)
	log_error "Unknown OS"
	;;
esac

install_pico_sdk
install_picotool
set_pico_env
verify_installation

log_debug "Done"
