#!/bin/sh
set -e
. /usr/local/share/devcontainers/util.sh

install_cpp_rhel() {
	log_debug "install_cpp_rhel: starting"

	log_debug "Installing C/C++ build tools via dnf"
	dnf -y install gcc gcc-c++ make cmake clang clang-tools-extra lldb openocd 2>/dev/null || true
	log_debug "C/C++ build tools installed"

	log_debug "Installing development tools group"
	dnf -y group install "development-tools" 2>/dev/null || true
	log_debug "Development tools group installed"

	if command -v gcc >/dev/null 2>&1; then
		version=$(gcc --version 2>&1 | head -n1)
		log_debug "gcc ${version} installed successfully"
	else
		log_error "gcc installation verification failed"
	fi

	if command -v g++ >/dev/null 2>&1; then
		version=$(g++ --version 2>&1 | head -n1)
		log_debug "g++ ${version} installed successfully"
	else
		log_error "g++ installation verification failed"
	fi

	if command -v cmake >/dev/null 2>&1; then
		version=$(cmake --version 2>&1 | head -n1)
		log_debug "cmake ${version} installed successfully"
	else
		log_error "cmake installation verification failed"
	fi

	if command -v clang >/dev/null 2>&1; then
		version=$(clang --version 2>&1 | head -n1)
		log_debug "clang ${version} installed successfully"
	else
		log_error "clang installation verification failed"
	fi

	log_debug "install_cpp_rhel: complete"
}

install_cpp_debian() {
	log_debug "install_cpp_debian: starting"

	export DEBIAN_FRONTEND=noninteractive
	log_debug "Updating apt cache"
	apt-get update -qq

	log_debug "Installing C/C++ build tools via apt"
	apt-get -y install gcc g++ make cmake clang clang-tools-extra lldb openocd 2>/dev/null || true
	log_debug "C/C++ build tools installed"

	if command -v gcc >/dev/null 2>&1; then
		version=$(gcc --version 2>&1 | head -n1)
		log_debug "gcc ${version} installed successfully"
	else
		log_error "gcc installation verification failed"
	fi

	if command -v g++ >/dev/null 2>&1; then
		version=$(g++ --version 2>&1 | head -n1)
		log_debug "g++ ${version} installed successfully"
	else
		log_error "g++ installation verification failed"
	fi

	if command -v cmake >/dev/null 2>&1; then
		version=$(cmake --version 2>&1 | head -n1)
		log_debug "cmake ${version} installed successfully"
	else
		log_error "cmake installation verification failed"
	fi

	if command -v clang >/dev/null 2>&1; then
		version=$(clang --version 2>&1 | head -n1)
		log_debug "clang ${version} installed successfully"
	else
		log_error "clang installation verification failed"
	fi

	log_debug "install_cpp_debian: complete"
}

log_debug "Activating feature 'cpp'"

OS=$(detect_os)
log_debug "Detected OS: $OS"

case "$OS" in
rhel)
	log_info "Installing for rhel"
	install_cpp_rhel
	;;
debian)
	log_info "Installing for debian"
	install_cpp_debian
	;;
*)
	log_error "Unknown OS"
	;;
esac

log_debug "Done"
