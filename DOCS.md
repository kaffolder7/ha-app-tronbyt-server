# Tronbyt Server

Run [Tronbyt Server](https://github.com/tronbyt/server) inside Home Assistant so your Tronbyt (flashed Tidbyt) devices can be managed locally on your network.

## What This App Provides

- A Home Assistant-packaged Tronbyt Server instance
- Web UI exposed on port `8000`
- Persistent storage for server data across restarts and upgrades
- Optional support for private/custom app repositories

## After Installation

1. Open **Settings -> Apps -> Tronbyt Server**.
2. Click **Start**.
3. Wait for the log line `Listening on TCP addr=:8000`.
4. Open **Web UI** from the app page, or browse to:
   - `http://<home-assistant-ip>:8000`
5. Point your Tronbyt/Tidbyt firmware at that server URL.

If port `8000` is already in use:
1. Open **Configuration -> Network**.
2. Set `8000/tcp` to another available host port.
3. Click **Save** and **Restart** the app.
4. Use `http://<home-assistant-ip>:<configured-host-port>`.

Example: `http://192.168.1.100:8000` (if host port is set to `8000`)

## Configuration Options

| Option | Default | Description |
|---|---|---|
| `production` | `true` | Runs Tronbyt in production mode (recommended). |
| `enable_user_registration` | `false` | Allows open account registration in the Tronbyt UI. |
| `single_user_auto_login` | `false` | Automatically signs in a single-user setup. |
| `github_token` | `""` | GitHub token used when accessing private app repositories. |
| `system_apps_repo` | `""` | Optional Git URL for a custom system apps repository. |
| `custom_server_repo` | `""` | Optional Git URL for a custom Tronbyt Server fork. When set, the binary is built from source on startup instead of using the bundled upstream build. |
| `custom_server_ref` | `""` | Branch, tag, or commit SHA to check out from `custom_server_repo`. Defaults to the repository's default branch when empty. |

Notes:
- Keep `enable_user_registration` disabled unless you specifically need it.
- `github_token` is optional and only needed for private repositories.
- `custom_server_repo` is intended for forks of [`tronbyt/server`](https://github.com/tronbyt/server). The fork must keep the same project layout (Go module with a `./cmd/server` entrypoint and CGo + libwebp dependencies).
- The first build with a new repo or ref can take several minutes — the addon installs build dependencies and compiles Go from source. Builds are cached under `/data/tronbyt-build/cache/<commit>/`; restarts on the same commit reuse the cached binary. The three most recent builds are retained.
- Clear `custom_server_repo` to revert to the bundled upstream binary on the next restart.

## Network

- Internal app port: `8000/tcp`
- Default host port mapping: `8000/tcp -> 8000`
- Host port mapping is configurable in the add-on Network settings.
- Home Assistant Web UI link is configured automatically.
- Devices on your LAN must be able to reach Home Assistant on the configured host port (default `8000`).

## Data & Persistence

This app persists Tronbyt data under:

- `/data/tronbyt`

The startup script maps Tronbyt's internal data path (`/app/data`) to this persistent location, so state is retained across container restarts and updates.

## Health & Logs

- Health endpoint (if exposed by current Tronbyt release): `http://<home-assistant-ip>:<configured-host-port>/health`
- Runtime logs: **Settings -> Apps -> Tronbyt Server -> Logs**

## Troubleshooting

- Web UI unavailable:
  - Confirm the app is running.
  - If logs show a port-bind error (for example, address already in use), set `8000/tcp` to another host port in **Configuration -> Network**, then restart the app.
  - Check Home Assistant host IP and configured host port reachability.
  - Review app logs for startup errors.
- Device connection issues:
  - Verify device firmware points to `http://<home-assistant-ip>:<configured-host-port>`.
  - Ensure device and Home Assistant are on routable networks.
- Repository/app fetch failures:
  - If using private repos, validate `github_token`.
  - If using `system_apps_repo`, verify the Git URL is reachable and valid.
