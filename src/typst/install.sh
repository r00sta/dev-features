#!/bin/sh
set -e
. /usr/local/share/devcontainers/util.sh

TYPST_VER=${TYPSTVERSION:-latest}

install_typst_builddeps_rhel() {
  log_debug "install_typst_builddeps_rhel: starting"

  log_debug "Installing build dependencies via dnf"
  dnf -y install gcc pkgconf-pkg-config openssl-devel fontconfig-devel harfbuzz-devel 2>/dev/null || true
  log_debug "Build dependencies installed"

  log_debug "install_typst_builddeps_rhel: complete"
}

install_typst_builddeps_debian() {
  log_debug "install_typst_builddeps_debian: starting"

  export DEBIAN_FRONTEND=noninteractive
  log_debug "Updating apt cache"
  apt-get update -qq

  log_debug "Installing build dependencies via apt"
  apt-get -y install gcc pkg-config libssl-dev libfontconfig1-dev libharfbuzz-dev 2>/dev/null || true
  log_debug "Build dependencies installed"

  log_debug "install_typst_builddeps_debian: complete"
}

install_typst_tools() {
  log_debug "install_typst_tools: starting"

  # Ensure the rust toolchain (provided by the base feature) is present
  if ! remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v cargo >/dev/null 2>&1'; then
    log_error "cargo/rustup not found. Install the base feature first to provide the Rust toolchain."
    return 1
  fi

  # Install the typst CLI at the requested version (default: latest)
  log_info "Installing typst-cli (${TYPST_VER}) via cargo"
  if [ "${TYPST_VER}" = "latest" ]; then
    remote_user_run 'source "$HOME/.cargo/env" && cargo install --locked typst-cli' || log_error "typst-cli installation failed"
  else
    remote_user_run "source \"\$HOME/.cargo/env\" && cargo install --locked typst-cli --version ${TYPST_VER}" || log_error "typst-cli installation failed"
  fi

  # Install the language server and formatter for Helix (hx)
  log_info "Installing tinymist (LSP) and typstyle (formatter) via cargo"
  remote_user_run 'source "$HOME/.cargo/env" && cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli' || log_error "tinymist installation failed"
  remote_user_run 'source "$HOME/.cargo/env" && cargo install --locked typstyle' || log_error "typstyle installation failed"

  # Verify installation
  if remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v typst >/dev/null 2>&1'; then
    version=$(remote_user_run 'source "$HOME/.cargo/env" && typst --version 2>&1 | head -n1')
    log_debug "typst ${version} installed successfully"
  else
    log_error "typst installation verification failed"
  fi

  if remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v tinymist >/dev/null 2>&1'; then
    version=$(remote_user_run 'source "$HOME/.cargo/env" && tinymist --version 2>&1 | head -n1')
    log_debug "tinymist ${version} installed successfully"
  else
    log_error "tinymist installation verification failed"
  fi

  if remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v typstyle >/dev/null 2>&1'; then
    version=$(remote_user_run 'source "$HOME/.cargo/env" && typstyle --version 2>&1 | head -n1')
    log_debug "typstyle ${version} installed successfully"
  else
    log_error "typstyle installation verification failed"
  fi

  log_debug "install_typst_tools: complete"
}

log_debug "Activating feature 'typst'"

OS=$(detect_os)
log_debug "Detected OS: $OS"
case "$OS" in
  rhel)
    log_info "Installing for rhel"
    install_typst_builddeps_rhel
    ;;
  debian)
    log_info "Installing for debian"
    install_typst_builddeps_debian
    ;;
  *)
    log_error "Unknown OS"
    ;;
esac

install_typst_tools

log_debug "Done"
