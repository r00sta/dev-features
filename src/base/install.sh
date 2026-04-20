#!/bin/sh
set -e
. ./util.sh

HX_VER=${HELIXVERSION:-25.07.1}
OPENCODE_VER=${OPENCODEVERSION:-latest}

install_opencode() {
  log_debug "install_opencode: starting"

  # Check if already installed
  if remote_user_run "command -v opencode" >/dev/null 2>&1; then
    version=$(remote_user_run 'opencode -v')
    log_info "Open Code ${version} is already installed"
    return 0
  fi

  log_debug "opencode not found for user"

  # dependencies
  if ! has_command curl; then
    log_error "This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
    return 1
  fi

  log_debug "curl found, proceeding with installation"
  log_info "Installing Open Code via https://opencode.ai/install"
  echo ""

  # Run the install as the remote user, as script installs locally
  if [ "${OPENCODE_VER-latest}" = "latest" ]; then
    remote_user_run 'curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path'
  else
    remote_user_run "curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path --version $OPENCODE_VER"
  fi

  # Add opencode to PATH in user's shell config
  remote_user_run "echo \"export PATH=\"\$HOME/.opencode/bin:\$PATH\"\" >> ~/.zshrc"

  # Verify installation
  if remote_user_run 'export PATH="$HOME/.opencode/bin:$PATH" && command -v opencode' >/dev/null 2>&1; then
    version=$(remote_user_run 'export PATH="$HOME/.opencode/bin:$PATH" && opencode -v')
    log_debug "Open Code ${version} installed successfully"
  else
    log_error "Open Code installation verification failed"
  fi
}

install_helix() {
  log_debug "install_helix: starting"

  # Check if already installed
  if command -v hx >/dev/null 2>&1; then
    version=$(hx --version 2>&1 | head -n1)
    log_debug "Helix ${version} is already installed"
    return 0
  fi

  log_debug "hx not found in PATH"

  # Dependencies
  if ! has_command wget; then
    log_error "This feature requires wget to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
    return 1
  fi

  log_debug "wget found, proceeding with download"
  log_info "Installing helix $HX_VER via https://github.com/helix-editor/helix/releases..."
  echo ""

  log_debug "Downloading helix-$HX_VER-x86_64-linux.tar.xz"
  wget -v https://github.com/helix-editor/helix/releases/download/"$HX_VER"/helix-"$HX_VER"-x86_64-linux.tar.xz

  log_debug "Extracting archive"
  tar -xf helix-"$HX_VER"-x86_64-linux.tar.xz

  log_debug "Copying hx to /usr/bin/"
  cp helix-"$HX_VER"-x86_64-linux/hx /usr/bin/.
  chown root:root /usr/bin/hx
  chmod 755 /usr/bin/hx

  log_debug "Setting up runtime in /home/${_REMOTE_USER}/.config/helix"
  mkdir -p /home/"$_REMOTE_USER"/.config/helix
  cp -r helix-"$HX_VER"-x86_64-linux/runtime /home/"$_REMOTE_USER"/.config/helix/.
  chown -R "$_REMOTE_USER":"$_REMOTE_USER" /home/"$_REMOTE_USER"/.config/helix

  log_debug "Cleaning up"
  rm -rf helix-"$HX_VER"-x86_64-linux helix-"$HX_VER"-x86_64-linux.tar.xz

  log_info "Installing linters and formatters"
  log_debug "Installing prettier, prettier-plugin-toml"
  npm install -g prettier prettier-plugin-toml yaml-language-server vscode-langservers-extracted 2>/dev/null || true

  # Verify installation
  if command -v hx >/dev/null 2>&1; then
    version=$(hx --version 2>&1 | head -n1)
    log_debug "Helix ${version} installed successfully"
  else
    log_error "Helix installation verification failed - hx not in PATH"
  fi
}

install_starship() {
  log_debug "install_starship: starting"

  # Check if already installed
  if command -v starship >/dev/null 2>&1; then
    version=$(starship --version 2>&1 | head -n1)
    log_debug "${version} is already installed"
    return 0
  fi

  log_debug "starship not found in PATH"

  # Dependencies
  if ! has_command curl; then
    log_error "This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
    return 1
  fi

  log_debug "curl found, proceeding with installation"
  log_info "Installing starship latest via https://starship.rs/"
  echo ""

  remote_user_run 'curl -sS https://starship.rs/install.sh | sh -s -- -y'

  remote_user_run 'echo "eval "$(starship init zsh)"" >> ~/.zshrc'

  # Verify installation
  if command -v starship >/dev/null 2>&1; then
    version=$(starship --version 2>&1 | head -n1)
    log_debug "Starship ${version} installed successfully"
  else
    log_error "Starship installation verification failed"
  fi
}

install_gitnr() {
  log_debug "install_gitnr: starting"

  # Check if already installed
  if command -v gitnr >/dev/null 2>&1; then
    version=$(gitnr --version 2>&1 | head -n1)
    log_debug "${version} is already installed"
    return 0
  fi

  log_debug "gitnr not found in PATH"

  # Dependencies
  if ! has_command curl; then
    log_error "This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
    return 1
  fi

  log_debug "curl found, proceeding with installation"
  log_info "Installing gitnr latest via raw.githubusercontent.com/reemus-dev/gitnr/main/scripts/install.sh"
  echo ""

  remote_user_run "mkdir -p ~/.local/bin"
  remote_user_run 'curl -s https://raw.githubusercontent.com/reemus-dev/gitnr/main/scripts/install.sh | bash -s -- -u'
}

install_rhel() {
  log_debug "install_rhel: starting"

  dnf -y install langpacks-en udev curl wget usbutils 2>/dev/null || true
  dnf -y install git-delta direnv mosh picocom 2>/dev/null || true
  dnf -y install zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
  dnf -y install bash-language-server shfmt 2>/dev/null || true
  dnf -y install npm 2>/dev/null || true

  log_debug "install_rhel: complete"
}

install_debian() {
  log_debug "install_debian: starting"

  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get -y install langpacks-en udev curl wget usbutils 2>/dev/null || true
  apt-get -y install zsh git git-delta direnv mosh picocom 2>/dev/null || true
  apt-get -y install zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
  apt-get -y install bash-language-server shfmt 2>/dev/null || true
  apt-get -y install npm 2>/dev/null || true

  log_debug "install_debian: complete"
}

log_debug "Activating feature 'base'"

OS=$(detect_os)
log_debug "Detected OS: $OS"
case "$OS" in
  rhel)
    log_info "Installing for rhel"
    install_rhel
    ;;
  debian)
    log_info "Installing for debian"
    install_debian
    ;;
  *)
    log_error "Unknown OS"
    ;;
esac

# Run OS agnostic installs

log_info "Running OS agnostice installs"

install_opencode
install_helix
install_starship
install_gitnr

log_info "Copying util.sh for other features to use"
# Copy util.sh to shared location for other features
mkdir -p /usr/local/share/devcontainers
cp "$(dirname "$0")/util.sh" /usr/local/share/devcontainers/util.sh

log_debug "Done"
