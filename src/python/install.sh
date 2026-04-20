#!/bin/sh
set -e
. /usr/local/share/devcontainers/util.sh

install_python_rhel() {
	log_debug "install_python_rhel: starting"

	log_debug "Installing Python dependencies via dnf"
	dnf -y install python3-pip libatomic 2>/dev/null || true
	log_debug "Python dependencies installed"

	log_debug "install_python_rhel: complete"
}

install_python_debian() {
	log_debug "install_python_debian: starting"

	export DEBIAN_FRONTEND=noninteractive
	log_debug "Updating apt cache"
	apt-get update -qq

	log_debug "Installing Python dependencies via apt"
	apt-get -y install python3-pip libatomic 2>/dev/null || true
	log_debug "Python dependencies installed"

	log_debug "install_python_debian: complete"
}

install_uv() {
	log_debug "install_uv: starting"

	if remote_user_run "command -v uv" >/dev/null 2>&1; then
		version=$(remote_user_run 'uv --version 2>&1 | head -n1')
		log_info "uv ${version} is already installed"
		return 0
	fi

	log_debug "uv not found for user"

	if ! has_command curl; then
		log_error "This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
		return 1
	fi

	log_debug "curl found, proceeding with installation"
	log_info "Installing uv via https://astral.sh/uv/install.sh"
	echo ""

	remote_user_run 'curl -LsSf https://astral.sh/uv/install.sh | sh'

	remote_user_run "echo \"export PATH=\"\$HOME/.local/bin:\$PATH\"\" >> ~/.zshrc"

	if remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && command -v uv" >/dev/null 2>&1; then
		version=$(remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && uv --version 2>&1 | head -n1')
		log_debug "uv ${version} installed successfully"
	else
		log_error "uv installation verification failed"
	fi

	log_debug "install_uv: complete"
}

install_python_tools() {
	log_debug "install_python_tools: starting"

	if ! remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && command -v uv" >/dev/null 2>&1; then
		log_error "uv is required for Python tools. Install python feature first."
		return 1
	fi

	log_info "Installing Python tools via uv"

	log_debug "Installing ruff"
	remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && uv tool install ruff' 2>/dev/null || true

	log_debug "Installing ruff-lsp"
	remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && uv tool install ruff-lsp' 2>/dev/null || true

	log_debug "Installing pyright"
	remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && uv tool install pyright' 2>/dev/null || true

	log_debug "Installing python-lsp-server"
	remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && uv tool install python-lsp-server' 2>/dev/null || true

	log_debug "Python tools installation complete"

	if remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && command -v ruff" >/dev/null 2>&1; then
		version=$(remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && ruff --version 2>&1 | head -n1')
		log_debug "ruff ${version} installed successfully"
	else
		log_error "ruff installation verification failed"
	fi

	log_debug "install_python_tools: complete"
}

log_debug "Activating feature 'python'"

OS=$(detect_os)
log_debug "Detected OS: $OS"

case "$OS" in
rhel)
	log_info "Installing for rhel"
	install_python_rhel
	;;
debian)
	log_info "Installing for debian"
	install_python_debian
	;;
*)
	log_error "Unknown OS"
	;;
esac

install_uv
install_python_tools

log_debug "Done"
