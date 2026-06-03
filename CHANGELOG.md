# Changelog

## 0.1.19
- Bumped upstream `tronbyt/server` from `2.3.0` to `2.3.1`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.18
- Bumped upstream `tronbyt/server` from `2.2.9` to `2.3.0`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.17
- Bumped upstream `tronbyt/server` from `2.2.8` to `2.2.9`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.16
- Bumped upstream `tronbyt/server` from `2.2.7` to `2.2.8`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.15
- Bumped upstream `tronbyt/server` from `2.2.6` to `2.2.7`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.14
- Bumped upstream `tronbyt/server` from `2.2.5` to `2.2.6`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.13
- Bumped upstream `tronbyt/server` from `2.2.4` to `2.2.5`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.12
- Bumped upstream `tronbyt/server` from `2.2.2` to `2.2.4`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.11
- Changed default host mapping for `8000/tcp` back to `8000` so **Open Web UI** works out of the box for most users.
- Updated docs and translation strings to reflect the default port behavior and provide clear fallback steps when `8000` is already in use.

## 0.1.10
- Bumped upstream `tronbyt/server` from `2.2.1` to `2.2.2`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.9
- Bumped upstream `tronbyt/server` from `2.2.0` to `2.2.1`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.8
- Bumped upstream `tronbyt/server` from `2.1.3` to `2.2.0`.
- Rebuilt and published updated app images for `amd64` and `aarch64`.
- No app configuration changes required.

## 0.1.7
- upstream bump `tronbyt/server` `2.1.2` -> `2.1.3`
- rebuilt/published architectures
- no config changes required

## 0.1.6
- Hardened startup data migration to prevent silent copy failures from deleting existing `/app/data` contents.
- Redacted credentials from `system_apps_repo` in startup logs to reduce accidental secret exposure.
- Switched AppArmor profile from `complain` mode to enforced mode.
- Removed static watchdog metadata to avoid restart loops when `/health` behavior differs across Tronbyt versions.
- Updated docs to describe `/health` as an optional endpoint depending on the installed Tronbyt release.
- Changed `8000/tcp` host mapping from fixed `8000` to configurable (`null`) to reduce port-collision startup failures.

## 0.1.5
- Added localization for application configuration settings with German, English, and Spanish translations to improve accessibility.
- Cleaned up `README.md` by updating installation instructions and adding a link to the upstream project.
- Organized `config.yaml` to match [HA documentation](https://developers.home-assistant.io/docs/apps/configuration/) and improve readability and maintainability.

## 0.1.4
- Update `config.yaml` to remove risky mounts + improve secrets handling
- Add a custom `apparmor.txt` (security score + defense-in-depth)
- Supply-chain: pin `tronbyt/server` upstream image version to `2.1.2`.

## 0.1.3
- Fix container publishing to [GitHub Container Registry](https://github.com/features/packages) so images are published under the correct repository path (no duplicated `ghcr.io/kaffolder7/` prefix).

## 0.1.2
- Standardize published container image naming to the Home Assistant convention: `ghcr.io/kaffolder7/{arch}-app-tronbyt-server:<version>`.
- Add-on now pulls pre-built images from GHCR (no local build required on install/update).
- Update CI builder arguments formatting so architecture flags are correctly passed during workflow runs.

## 0.1.1
- Add `webui` metadata so Home Assistant shows an "Open Web UI" button for quick access to the Tronbyt UI (`http://[HOST]:[PORT:8000]`).

## 0.1.0
- Initial release of the Tronbyt Server Home Assistant app.
- Runs Tronbyt Server (based on `ghcr.io/tronbyt/server:2`) on Home Assistant.
- Exposes the Tronbyt web UI on port 8000.
- Persists Tronbyt data under `/data/tronbyt` across restarts/updates.
- Adds configuration options:
  - production mode
  - enable user registration
  - single-user auto login
  - GitHub token (optional)
  - system apps repo override (optional)
- Includes install + usage documentation.
