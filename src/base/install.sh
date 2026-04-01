#!/bin/sh
set -e
. ./util.sh

HX_VER=${HELIXVERSION:-25.07.1}
OPENCODE_VER=${OPENCODEVERSION:-latest}

install_opencode() {
    # Check if already installed
    if remote_user_run "command -v opencode" >/dev/null 2>&1; then
        version=$(remote_user_run 'opencode -v')
        echo "Open Code ${version} is already installed"
        return 0
    fi

    # dependencies
    has_command curl || {
        echored "ERROR: This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
        return 1
    }

    # install Open Code
    echo "Installing Open Code via https://opencode.ai/install"
    echo ""
    # Run the install as the remote user, as script installs locally
    if [ "${OPENCODE_VERSION-latest}" = "latest" ] ; then
        remote_user_run 'curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path'
    else
        remote_user_run "curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path --version $OPENCODE_VERSION"
    fi

    remote_user_run 'export PATH="/home/${_REMOTE_USER}/.opencode/bin:$PATH"'

    # Verify installation
    if remote_user_run "command -v opencode" >/dev/null 2>&1; then
        version=$(remote_user_run 'opencode -v')
        echo "Open Code ${version} installed successfully"
    fi
}

install_helix() {
    echo "[DEBUG] install_helix: starting"
    
    # Check if already installed
    if command -v hx >/dev/null 2>&1; then
        version=$(hx --version 2>&1 | head -n1)
        echo "Helix ${version} is already installed"
        return 0
    fi

    echo "[DEBUG] hx not found in PATH"
    
    # Dependencies
    if ! has_command wget; then
        echored "ERROR: This feature requires wget to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
        return 1
    fi

    echo "[DEBUG] wget found, proceeding with download"
    echo "Installing helix $HX_VER via https://github.com/helix-editor/helix/releases..."
    echo ""
    
    echo "[DEBUG] Downloading helix-$HX_VER-x86_64-linux.tar.xz"
    wget -v https://github.com/helix-editor/helix/releases/download/$HX_VER/helix-$HX_VER-x86_64-linux.tar.xz
    
    echo "[DEBUG] Extracting archive"
    tar -xf helix-$HX_VER-x86_64-linux.tar.xz
    
    echo "[DEBUG] Copying hx to /usr/bin/"
    cp helix-$HX_VER-x86_64-linux/hx /usr/bin/.
    chown root:root /usr/bin/hx
    chmod 755 /usr/bin/hx
    
    echo "[DEBUG] Setting up runtime in /home/${_REMOTE_USER}/.config/helix"
    mkdir -p /home/$_REMOTE_USER/.config/helix
    cp -r helix-$HX_VER-x86_64-linux/runtime /home/$_REMOTE_USER/.config/helix/.
    chown -R $_REMOTE_USER:$_REMOTE_USER /home/$_REMOTE_USER/.config/helix
    
    echo "[DEBUG] Cleaning up"
    rm -rf helix-$HX_VER-x86_64-linux helix-$HX_VER-x86_64-linux.tar.xz

    # Verify installation
    if command -v hx >/dev/null 2>&1; then
        version=$(hx --version 2>&1 | head -n1)
        echo "Helix ${version} installed successfully"
    else
        echo "[ERROR] Helix installation verification failed - hx not in PATH"
    fi
}

install_starship(){
    # Check if already installed
    if command -v starship >/dev/null 2>&1; then
        version=$(starship --version 2>&1 | head -n1)
        echo "${version} is already installed"
        return 0
    fi
    
    # Dependencies
    has_command curl || {
        echored "ERROR: This feature requires curl to be installed. Install with devcontainer feature ghcr.io/devcontainers/features/common-utils"
        return 1
    }

    echo "Installing starship latest via https://starship.rs/"
    echo ""
    
    remote_user_run 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
}

install_rhel() {
    dnf -y install langpacks-en udev curl wget usbutils 2>/dev/null || true
    dnf -y install git-delta direnv mosh picocom 2>/dev/null || true
    dnf -y install zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
    
    install_opencode
    install_helix
    install_starship
}

install_debian() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get -y install langpacks-en udev curl wget usbutils 2>/dev/null || true
    apt-get -y install zsh git git-delta direnv mosh picocom 2>/dev/null || true
    apt-get -y install zsh-autosuggestions zsh-syntax-highlighting starship 2>/dev/null || true
    
    install_opencode
    install_helix
}

echo "Activating feature 'base'"

OS=$(detect_os)
echo "Detected OS: $OS"
case "$OS" in
    rhel)
        echo "Installing for rhel"
        install_rhel
        ;;
    debian)
        echo "Installing for debian"
        install_debian
        ;;
    *)
        echo "Unknown OS"
        # install_rhel || install_debian
        ;;
esac
