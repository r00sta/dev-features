#!/bin/sh
set -e
. /usr/local/share/devcontainers/util.sh

ZEPHYR_VER=${VERSION:-4.4.1}
SDK_VER=${SDKVERSION:-1.0.1}
TARGET=${TARGET:-arm}
ZEPHYRWORKSPACE="/opt/zephyrproject"
SDK_DIR="/opt/zephyr-sdk-${SDK_VER}"
SDK_BASE_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VER}"

map_target_to_toolchain() {
	_log_target="$1"
	case "$_log_target" in
		arm) echo "arm-zephyr-eabi" ;;
		aarch64) echo "aarch64-zephyr-elf" ;;
		riscv64) echo "riscv64-zephyr-elf" ;;
		riscv32) echo "riscv32-zephyr-elf" ;;
		x86_64) echo "x86_64-zephyr-elf" ;;
		x86) echo "x86-zephyr-elf" ;;
		arc) echo "arc-zephyr-elf" ;;
		arc64) echo "arc64-zephyr-elf" ;;
		*) echo "" ;;
	esac
}

resolve_toolchain_args() {
	_input="$1"

	if [ "$_input" = "all" ]; then
		echo "-t all"
		return
	fi

	_args=""
	_remaining="$_input"
	while [ -n "$_remaining" ]; do
		_item="${_remaining%%,*}"
		_tc=$(map_target_to_toolchain "$_item")
		if [ -z "$_tc" ]; then
			log_error "Unknown target architecture: '$_item'"
			log_error "Supported targets: arm, aarch64, riscv64, riscv32, x86_64, x86, arc, arc64, all"
			return 1
		fi
		if [ -n "$_args" ]; then
			_args="$_args -t $_tc"
		else
			_args="-t $_tc"
		fi
		case "$_remaining" in
			*,*)
				_remaining="${_remaining#*,}"
				;;
			*)
				_remaining=""
				;;
		esac
	done
	echo "$_args"
}

install_zephyr_deps_rhel() {
	log_debug "install_zephyr_deps_rhel: starting"

	log_debug "Installing Zephyr build dependencies via dnf"
	dnf -y install ninja-build gperf ccache dtc wget 2>/dev/null || true
	log_debug "Zephyr build dependencies installed"

	log_debug "install_zephyr_deps_rhel: complete"
}

install_zephyr_deps_debian() {
	log_debug "install_zephyr_deps_debian: starting"

	export DEBIAN_FRONTEND=noninteractive
	log_debug "Updating apt cache"
	apt-get update -qq

	log_debug "Installing Zephyr build dependencies via apt"
	apt-get -y install ninja-build gperf ccache device-tree-compiler wget 2>/dev/null || true
	log_debug "Zephyr build dependencies installed"

	log_debug "install_zephyr_deps_debian: complete"
}

install_west() {
	log_debug "install_west: starting"

	if remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && command -v west" >/dev/null 2>&1; then
		version=$(remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && west --version 2>&1 | head -n1')
		log_info "west is already installed: ${version}"
		return 0
	fi

	log_debug "west not found for user"

	if ! remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && command -v uv" >/dev/null 2>&1; then
		log_error "uv is required for west installation. Install python feature first."
		return 1
	fi

	log_info "Installing west via uv"
	remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && uv tool install west'

	if remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && command -v west" >/dev/null 2>&1; then
		version=$(remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && west --version 2>&1 | head -n1')
		log_debug "west ${version} installed successfully"
	else
		log_error "west installation verification failed"
	fi

	log_debug "install_west: complete"
}

init_zephyr_workspace() {
	log_debug "init_zephyr_workspace: starting"

	if [ -d "$ZEPHYRWORKSPACE/zephyr/west.yml" ]; then
		log_info "Zephyr workspace already exists at ${ZEPHYRWORKSPACE}"
		return 0
	fi

	log_debug "Zephyr workspace not found, initializing"
	log_info "Initializing Zephyr workspace (version ${ZEPHYR_VER})"
	echo ""

	if ! has_command git; then
		log_error "This feature requires git to be installed."
		return 1
	fi

	mkdir -p "$ZEPHYRWORKSPACE"
	remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && west init $ZEPHYRWORKSPACE -m https://github.com/zephyrproject-rtos/zephyr --mr v${ZEPHYR_VER}"

	log_debug "Running west update (this may take a while)"
	remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && cd $ZEPHYRWORKSPACE && west update"

	chown -R root:root "$ZEPHYRWORKSPACE"

	log_debug "init_zephyr_workspace: complete"
}

install_zephyr_python_deps() {
	log_debug "install_zephyr_python_deps: starting"

	VENV_DIR="$ZEPHYRWORKSPACE/.venv"

	if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python" ]; then
		log_info "Python venv already exists at ${VENV_DIR}"
		return 0
	fi

	log_debug "Creating Python venv for Zephyr"
	remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && uv venv $VENV_DIR"

	log_debug "Installing Zephyr Python requirements"
	remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && cd $ZEPHYRWORKSPACE && uv pip install --python $VENV_DIR/bin/python -r zephyr/scripts/requirements.txt"

	chown -R root:root "$VENV_DIR"

	log_debug "install_zephyr_python_deps: complete"
}

install_sdk_minimal() {
	log_debug "install_sdk_minimal: starting"

	if [ -d "$SDK_DIR" ] && [ -f "$SDK_DIR/setup.sh" ]; then
		log_info "Zephyr SDK already exists at ${SDK_DIR}"
		return 0
	fi

	log_debug "SDK not found, downloading minimal bundle"
	log_info "Downloading Zephyr SDK ${SDK_VER} (minimal bundle)"
	echo ""

	if ! has_command wget; then
		log_error "This feature requires wget to be installed."
		return 1
	fi

	wget -q --show-progress -O "/tmp/zephyr-sdk-${SDK_VER}_minimal.tar.xz" \
		"${SDK_BASE_URL}/zephyr-sdk-${SDK_VER}_linux-x86_64_minimal.tar.xz"

	log_debug "Extracting SDK to ${SDK_DIR}"
	mkdir -p /opt
	tar xf "/tmp/zephyr-sdk-${SDK_VER}_minimal.tar.xz" -C /opt

	log_debug "Cleaning up minimal archive"
	rm -f "/tmp/zephyr-sdk-${SDK_VER}_minimal.tar.xz"

	log_debug "install_sdk_minimal: complete"
}

install_sdk_gnu_bundle() {
	log_debug "install_sdk_gnu_bundle: starting"

	if [ -d "$SDK_DIR" ] && [ -f "$SDK_DIR/setup.sh" ]; then
		log_info "Zephyr SDK already exists at ${SDK_DIR}"
		return 0
	fi

	log_debug "SDK not found, downloading GNU bundle (all toolchains)"
	log_info "Downloading Zephyr SDK ${SDK_VER} (GNU bundle)"
	echo ""

	if ! has_command wget; then
		log_error "This feature requires wget to be installed."
		return 1
	fi

	wget -q --show-progress -O "/tmp/zephyr-sdk-${SDK_VER}_gnu.tar.xz" \
		"${SDK_BASE_URL}/zephyr-sdk-${SDK_VER}_linux-x86_64_gnu.tar.xz"

	log_debug "Extracting SDK to ${SDK_DIR}"
	mkdir -p /opt
	tar xf "/tmp/zephyr-sdk-${SDK_VER}_gnu.tar.xz" -C /opt

	log_debug "Cleaning up GNU archive"
	rm -f "/tmp/zephyr-sdk-${SDK_VER}_gnu.tar.xz"

	log_debug "install_sdk_gnu_bundle: complete"
}

install_sdk_toolchain() {
	_tc_args="$1"
	log_debug "install_sdk_toolchain: starting (${_tc_args})"

	cd "$SDK_DIR"

	log_debug "Registering SDK CMake package and installing host tools"
	./setup.sh -c -h

	log_debug "Installing SDK toolchains: ${_tc_args}"
	# shellcheck disable=SC2086
	./setup.sh $_tc_args

	log_debug "install_sdk_toolchain: complete"
}

set_zephyr_env() {
	log_debug "set_zephyr_env: starting"

	log_debug "Setting Zephyr environment variables in ~/.zshrc"

	remote_user_run "echo 'export ZEPHYR_BASE=$ZEPHYRWORKSPACE/zephyr' >> ~/.zshrc"
	remote_user_run "echo 'export ZEPHYR_SDK_INSTALL_DIR=$SDK_DIR' >> ~/.zshrc"
	remote_user_run "echo 'source $ZEPHYRWORKSPACE/.venv/bin/activate' >> ~/.zshrc"

	log_debug "set_zephyr_env: complete"
}

install_udev_rules() {
	log_debug "install_udev_rules: starting"

	UDEV_SRC="$SDK_DIR/hosttools/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules"
	UDEV_DST="/etc/udev/rules.d/60-openocd.rules"

	if [ -f "$UDEV_SRC" ]; then
		cp "$UDEV_SRC" "$UDEV_DST" 2>/dev/null || true
		udevadm control --reload-rules 2>/dev/null || true
		udevadm trigger 2>/dev/null || true
		log_debug "udev rules installed"
	else
		log_debug "udev rules not found at ${UDEV_SRC}, skipping"
	fi

	log_debug "install_udev_rules: complete"
}

verify_installation() {
	log_debug "verify_installation: starting"

	if remote_user_run "export PATH=\"\$HOME/.local/bin:\$PATH\" && command -v west" >/dev/null 2>&1; then
		version=$(remote_user_run 'export PATH="$HOME/.local/bin:$PATH" && west --version 2>&1 | head -n1')
		log_debug "west ${version} installed successfully"
	else
		log_error "west installation verification failed"
	fi

	if [ -d "$ZEPHYRWORKSPACE/zephyr" ]; then
		log_debug "Zephyr source found at ${ZEPHYRWORKSPACE}/zephyr"
	else
		log_error "Zephyr source verification failed"
	fi

	if [ -d "$SDK_DIR" ] && [ -f "$SDK_DIR/setup.sh" ]; then
		log_debug "Zephyr SDK found at ${SDK_DIR}"
	else
		log_error "Zephyr SDK verification failed"
	fi

	if [ -d "$ZEPHYRWORKSPACE/.venv" ] && [ -f "$ZEPHYRWORKSPACE/.venv/bin/python" ]; then
		log_debug "Python venv found at ${ZEPHYRWORKSPACE}/.venv"
	else
		log_error "Python venv verification failed"
	fi

	log_debug "verify_installation: complete"
}

log_debug "Activating feature 'zephyr'"

OS=$(detect_os)
log_debug "Detected OS: $OS"

case "$OS" in
rhel)
	log_info "Installing for rhel"
	install_zephyr_deps_rhel
	;;
debian)
	log_info "Installing for debian"
	install_zephyr_deps_debian
	;;
*)
	log_error "Unknown OS"
	;;
esac

install_west
init_zephyr_workspace
install_zephyr_python_deps

log_info "Resolving target architectures: ${TARGET}"
TOOLCHAIN_ARGS=$(resolve_toolchain_args "$TARGET") || {
	log_error "Failed to resolve target architectures"
	exit 1
}

if [ "$TARGET" = "all" ]; then
	install_sdk_gnu_bundle
else
	install_sdk_minimal
fi

install_sdk_toolchain "$TOOLCHAIN_ARGS"
install_udev_rules
set_zephyr_env
verify_installation

log_debug "Done"
