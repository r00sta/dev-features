# AGENTS.md

## What this repo is

A collection of custom **devcontainer features** (not an app). Each feature lives in `src/<feature-id>/` and contains exactly:

- `devcontainer-feature.json` — metadata; `"id"` must match the directory name; options are passed to `install.sh` as env vars with the camelCase option name uppercased + `_` (e.g. `helixVersion` → `$HELIXVERSION`)
- `install.sh` — POSIX shell (`#!/bin/sh set -e`), the feature's implementation
- `README.md` — auto-generated in `src/*/README.md` by the release workflow (regenerate via `devcontainers action` from `devcontainer-feature.json`)

## Shared `base` conventions (critical)

- `src/base/` ships `util.sh`, installed to `/usr/local/share/devcontainers/util.sh`. Non-base features source it with `. /usr/local/share/devcontainers/util.sh` (base itself sources `./util.sh` because of this copy step).
- Provided helpers: `detect_os` (RHEL/dnf vs Debian/apt), `has_command`, `remote_user_run` (user-space installs — use for anything landing in the remote user's home/PATH), `log_debug/log_info/log_error`.
- Every feature must support both dnf (RHEL/Fedora/Rocky) and apt (Debian/Ubuntu) via `detect_os` branching.
- Installs must be **idempotent**: check `command -v`/existing install first and short-circuit — features re-run on container rebuild.
- Heavyweight runners assume `common-utils` already provided `curl`/`wget`; other features must not rely on base being installed unless declared in `installsAfter`.

## Testing

Requires the devcontainer CLI (not installed locally by default):

```sh
npm install -g @devcontainers/cli
devcontainer features test -f <feature-id> -i fedora:latest --skip-scenarios .
```

- CI (`.github/workflows/test.yaml`) tests only `base`, `rust`, `typst` across `fedora:latest`, `debian:latest`, `ubuntu:latest`, `mcr.microsoft.com/devcontainers/base:ubuntu` — all `continue-on-error`, so failures don't block CI.
- `test/hello/` and `test/color/` are stale template leftovers; those features don't exist under `src/`. Don't pattern new tests on them blindly.
- PRs run a JSON validation workflow (`validate-only`) over `src/`, so malformed `devcontainer-feature.json` fails CI.

## Release

- Release is **manual**: `.github/workflows/release.yaml` is `workflow_dispatch` only, on `main`. It publishes each feature to GHCR and opens an automated PR regenerating `src/*/README.md`.
- Bump `version` (semver) in `devcontainer-feature.json` before a release — consumers pin exact versions (see `.devcontainer/devcontainer.json`, which dogfoods these features from `ghcr.io/r00sta/dev-features/...`).
