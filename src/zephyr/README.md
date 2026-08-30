
# Zephyr RTOS Development Environment (zephyr)

Installs Zephyr RTOS, west meta-tool, and Zephyr SDK toolchains

## Example Usage

```json
"features": {
    "ghcr.io/r00sta/dev-features/zephyr:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Zephyr RTOS version | string | 4.4.1 |
| sdkVersion | Zephyr SDK version | string | 1.0.1 |
| target | Target architecture(s) for SDK toolchains. Comma-separated (e.g. 'arm,riscv64') or 'all'. | string | arm |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/r00sta/dev-features/blob/main/src/zephyr/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
