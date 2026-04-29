# Dev Container Features

Custom devcontainer features for development environments, supporting both dnf-based (RHEL/Fedora/Rocky) and apt-based (Debian/Ubuntu) images. All features use shared utility functions from the `base` feature and follow idempotent installation patterns.

## Shared Utilities

The `base` feature installs `util.sh` to `/usr/local/share/devcontainers/` for use by all other features. Available functions:
- `detect_os` - Detects RHEL (dnf) or Debian (apt) systems
- `has_command <cmd>` - Checks if a command exists
- `remote_user_run <cmd>` - Runs commands as the devcontainer remote user (for user-space installs)
- `log_debug/log_info/log_error <msg>` - Standardized logging with `[DEBUG]`, `[INFO]`, `[ERROR]` prefixes

## Features

### 1. Base Development Environment (`base`)
Installs core packages, Helix editor, OpenCode, Starship, Gitnr, and copies shared `util.sh` to the system.

**Version:** 1.0.5

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `helixVersion` | string | `25.07.1` | Helix editor version. Proposals: `25.07.1`, `25.07`, `25.01.1`, `25.01`, `24.07`, `24.03` |
| `opencodeVersion` | string | `latest` | OpenCode version (e.g., `1.1.13`) |

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/base:1.0.5": {
            "helixVersion": "25.07.1",
            "opencodeVersion": "latest"
        }
    }
}
```

---

### 2. Python Development Environment (`python`)
Installs `uv` (Python package manager) and user-space Python tools: ruff, ruff-lsp, pyright, python-lsp-server.

**Version:** 1.0.0

**Options:** None

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/python:1.0.0": {}
    }
}
```

**Dependencies:** Installs after `base` automatically.

---

### 3. C/C++ Development Environment (`cpp`)
Installs GCC, G++, Make, CMake, Clang, Clang tools, LLDB, and OpenOCD.

**Version:** 1.0.0

**Options:** None

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/cpp:1.0.0": {}
    }
}
```

**Dependencies:** Installs after `base` automatically.

---

### 4. ARM GNU Toolchain (`arm-gnu`)
Installs ARM GNU Embedded Toolchain for bare-metal ARM development.

**Version:** 1.0.0

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `13.3.rel1` | ARM toolchain version. Proposals: `13.3.rel1` |

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/arm-gnu:1.0.0": {
            "version": "13.3.rel1"
        }
    }
}
```

**Dependencies:** Installs after `cpp` automatically.

---

### 5. Raspberry Pi Pico SDK (`pico-sdk`)
Installs Pico SDK (default 2.2.0), builds/installs picotool, sets `PICO_SDK_PATH`, and copies udev rules for Pico device access.

**Version:** 1.0.0

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `2.2.0` | Pico SDK version. Proposals: `2.2.0` |

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/pico-sdk:1.0.0": {
            "version": "2.2.0"
        }
    }
}
```

**Dependencies:** Installs after `cpp` automatically.

---

## Cross-Platform Support
All features automatically detect the OS and use the appropriate package manager:
- **dnf**: RHEL, Fedora, Rocky Linux
- **apt**: Debian, Ubuntu

## Installation Order
Features install in this order due to `installsAfter` dependencies:
1. `common-utils` (external)
2. `base`
3. `cpp`
4. `python` (after base)
5. `arm-gnu` (after cpp)
6. `pico-sdk` (after cpp)

## Distributing Features
Features are versioned via `version` in `devcontainer-feature.json` (semver). To publish:
1. Push to GitHub; the included `.github/workflows/release.yaml` publishes to GHCR.
2. Mark packages as `public` in GHCR settings to avoid private registry limits.
3. Replace `<your-org>/dev-features` with your GitHub owner and repo name in feature references.
