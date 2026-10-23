
# Base Development Environment (base)

Installs core packages, utilities, helix/mitos editors, opencode, and rust/cargo

## Example Usage

```json
"features": {
    "ghcr.io/r00sta/dev-features/base:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| helixVersion | Helix editor version | string | 25.07.1 |
| mitosVersion | Mitos editor version | string | latest |
| opencodeVersion | Specific version number to install, eg: 1.1.13 | string | latest |
| rustVersion | Rust toolchain version to install via rustup, eg: stable, nightly, 1.81.0 | string | stable |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/r00sta/dev-features/blob/main/src/base/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
