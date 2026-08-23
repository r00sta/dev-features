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
Installs core packages, Helix editor, OpenCode, Starship, Gitnr, Rust/Cargo (via rustup), and copies shared `util.sh` to the system.

**Version:** 1.0.8

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `helixVersion` | string | `25.07.1` | Helix editor version. Proposals: `25.07.1`, `25.07`, `25.01.1`, `25.01`, `24.07`, `24.03` |
| `opencodeVersion` | string | `latest` | OpenCode version (e.g., `1.1.13`) |
| `rustVersion` | string | `stable` | Rust toolchain version to install via rustup (e.g., `stable`, `nightly`, `1.81.0`) |

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/base:1.0.8": {
            "helixVersion": "25.07.1",
            "opencodeVersion": "latest",
            "rustVersion": "stable"
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

### 6. Rust Development Environment (`rust`)
Installs the Rust language server (`rust-analyzer`), formatter (`rustfmt`), linter (`clippy`), and cargo dev tools: `cargo-watch`, `cargo-edit`, `cargo-nextest`, `cargo-audit`, `cargo-expand`. Works with the Helix editor via its built-in Rust LSP/formatter defaults.

**Version:** 1.0.0

**Options:** None

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/rust:1.0.0": {}
    }
}
```

**Dependencies:** Installs after `base` automatically (requires the Rust toolchain provided by `base`).

---

### 7. Zephyr RTOS Development Environment (`zephyr`)
Installs Zephyr RTOS, west meta-tool, Python dependencies via uv, and Zephyr SDK toolchains (configurable by architecture).

**Version:** 1.0.0

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `4.4.1` | Zephyr RTOS version. Proposals: `4.4.1`, `4.4.0`, `4.3.1`, `4.3.0`, `3.7.0` |
| `sdkVersion` | string | `1.0.1` | Zephyr SDK version. Proposals: `1.0.1`, `1.0.0` |
| `target` | string | `arm` | Target architecture(s) for SDK toolchains. Comma-separated (e.g. `arm,riscv64`) or `all` |

**Usage Template:**
```jsonc
{
    "features": {
        "ghcr.io/r00sta/dev-features/zephyr:1.0.0": {
            "version": "4.4.1",
            "sdkVersion": "1.0.1",
            "target": "arm"
        }
    }
}
```

**Dependencies:** Installs after `python` and `cpp` automatically.

---

## Cross-Platform Support
All features automatically detect the OS and use the appropriate package manager:
- **dnf**: RHEL, Fedora, Rocky Linux
- **apt**: Debian, Ubuntu

## Installation Order
Features install in this order due to `installsAfter` dependencies:
1. `common-utils` (external)
2. `base`
3. `rust` (after base)
4. `cpp`
5. `python` (after base)
6. `arm-gnu` (after cpp)
7. `pico-sdk` (after cpp)
8. `zephyr` (after python, cpp)

## Distributing Features
Features are versioned via `version` in `devcontainer-feature.json` (semver). To publish:
1. Push to GitHub; the included `.github/workflows/release.yaml` publishes to GHCR.
2. Mark packages as `public` in GHCR settings to avoid private registry limits.
3. Replace `<your-org>/dev-features` with your GitHub owner and repo name in feature references.
