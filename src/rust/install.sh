#!/bin/sh
set -e
. /usr/local/share/devcontainers/util.sh

install_rust_builddeps_rhel() {
  log_debug "install_rust_builddeps_rhel: starting"

  log_debug "Installing build dependencies via dnf"
  dnf -y install gcc pkgconf-pkg-config openssl-devel 2>/dev/null || true
  log_debug "Build dependencies installed"

  log_debug "install_rust_builddeps_rhel: complete"
}

install_rust_builddeps_debian() {
  log_debug "install_rust_builddeps_debian: starting"

  export DEBIAN_FRONTEND=noninteractive
  log_debug "Updating apt cache"
  apt-get update -qq

  log_debug "Installing build dependencies via apt"
  apt-get -y install gcc pkg-config libssl-dev 2>/dev/null || true
  log_debug "Build dependencies installed"

  log_debug "install_rust_builddeps_debian: complete"
}

install_rust_tools() {
  log_debug "install_rust_tools: starting"

  # Ensure the rust toolchain (provided by the base feature) is present
  if ! remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v cargo >/dev/null 2>&1'; then
    log_error "cargo/rustup not found. Install the base feature first to provide the Rust toolchain."
    return 1
  fi

  # Add rustup components: formatter, linter, and language server
  log_info "Adding rustup components: rustfmt, clippy, rust-analyzer"
  remote_user_run 'source "$HOME/.cargo/env" && rustup component add rustfmt clippy rust-analyzer'

  # Install cargo dev tools (compiled from source; --locked for reproducible builds)
  log_info "Installing cargo dev tools: cargo-watch, cargo-edit, cargo-nextest, cargo-audit, cargo-expand"
  remote_user_run 'source "$HOME/.cargo/env" && cargo install --locked cargo-watch' || log_error "cargo-watch installation failed"
  remote_user_run 'source "$HOME/.cargo/env" && cargo install --locked cargo-edit' || log_error "cargo-edit installation failed"
  remote_user_run 'source "$HOME/.cargo/env" && cargo install --locked cargo-nextest' || log_error "cargo-nextest installation failed"
  remote_user_run 'source "$HOME/.cargo/env" && cargo install --locked cargo-audit' || log_error "cargo-audit installation failed"
  remote_user_run 'source "$HOME/.cargo/env" && cargo install --locked cargo-expand' || log_error "cargo-expand installation failed"

  # Verify installation
  if remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v rust-analyzer >/dev/null 2>&1'; then
    version=$(remote_user_run 'source "$HOME/.cargo/env" && rust-analyzer --version 2>&1 | head -n1')
    log_debug "rust-analyzer ${version} installed successfully"
  else
    log_error "rust-analyzer installation verification failed"
  fi

  if remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v rustfmt >/dev/null 2>&1'; then
    version=$(remote_user_run 'source "$HOME/.cargo/env" && rustfmt --version 2>&1 | head -n1')
    log_debug "rustfmt ${version} installed successfully"
  else
    log_error "rustfmt installation verification failed"
  fi

  if remote_user_run 'source "$HOME/.cargo/env" 2>/dev/null; command -v cargo-clippy >/dev/null 2>&1'; then
    version=$(remote_user_run 'source "$HOME/.cargo/env" && cargo clippy --version 2>&1 | head -n1')
    log_debug "clippy ${version} installed successfully"
  else
    log_error "clippy installation verification failed"
  fi

  for tool in cargo-watch cargo-edit cargo-nextest cargo-audit cargo-expand; do
    if remote_user_run "source \"\$HOME/.cargo/env\" 2>/dev/null; command -v ${tool} >/dev/null 2>&1"; then
      log_debug "${tool} installed successfully"
    else
      log_error "${tool} installation verification failed"
    fi
  done

  log_debug "install_rust_tools: complete"
}

log_debug "Activating feature 'rust'"

OS=$(detect_os)
log_debug "Detected OS: $OS"
case "$OS" in
  rhel)
    log_info "Installing for rhel"
    install_rust_builddeps_rhel
    ;;
  debian)
    log_info "Installing for debian"
    install_rust_builddeps_debian
    ;;
  *)
    log_error "Unknown OS"
    ;;
esac

install_rust_tools

log_debug "Done"
