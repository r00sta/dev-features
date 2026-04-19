#!/bin/sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
echored() {
  echo -e "${RED}$@${NC}"
}
echogrn() {
  echo -e "${GREEN}$@${NC}"
}
echoyel() {
  echo -e "${YELLOW}$@${NC}"
}

# Logging functions
log_debug() {
  echoyel "[DEBUG] $@"
}
log_info() {
  echogrn "[INFO] $@"
}
log_error() {
  echored "[ERROR] $@"
}

# check if a command exists
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# check if user is root user
is_root_user() {
  [ "$(id -u)" -eq 0 ]
}

# parse major verion from a semantic version string
semver_major() {
  echo "${1#v}" | cut -d'.' -f1
}

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  fi

  if [ -n "$ID" ]; then
    case "$ID" in
      fedora | rhel | rocky | almalinux | centos)
        echo "rhel"
        return
        ;;
      debian | ubuntu | pop)
        echo "debian"
        return
        ;;
    esac
  fi

  if [ -f /etc/redhat-release ]; then
    echo "rhel"
    return
  fi

  if [ -f /etc/debian_version ]; then
    echo "debian"
    return
  fi

  echo "unknown"
}

# If we're using Alpine, install bash before executing
ensure_bash_on_alpine() {
  . /etc/os-release
  if [ "${ID}" = "alpine" ]; then
    apk add --no-cache bash
  fi
}

# Run a command as the remote user for the devcontainer.
remote_user_run() {
  # Use _REMOTE_USER if available, otherwise use the devcontainer.json option USER_NAME
  command_to_run="$1"
  USER_OPTION="${REMOTE_USER_NAME:-automatic}"
  _REMOTE_USER="${_REMOTE_USER:-${USER_OPTION}}"
  if [ "${_REMOTE_USER}" = "auto" ] || [ "${_REMOTE_USER}" = "automatic" ]; then
    _REMOTE_USER="$(id -un 1000 2>/dev/null || echo "vscode")" # vscode fallback
  fi
  log_debug "Running as: ${_REMOTE_USER}, command: $command_to_run" >&2
  su - "${_REMOTE_USER}" -c "sh -lc '$command_to_run'"
}

# check if a command exists for remote user
remote_user_has_command() {
  remote_user_run "command -v \"$1\" > /dev/null 2>&1"
}
