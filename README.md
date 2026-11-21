# Pomodoro TT

Pomodoro timer for Garmin Forerunner 955 that logs work phases straight into TimeTagger — no middle layer, no phone app beyond Garmin Connect.

Work phases become TimeTagger records (`{"key", "t1", "t2", "ds": "#<project> focus"}`); breaks are never logged; pausing splits the entry. Offline time is queued on the watch and flushed later — client-generated keys make retries idempotent.

## Prerequisites

- Docker + VS Code Dev Containers (the `.devcontainer/` image ships OpenJDK and Connect IQ SDK 7+)
- For `make sim` inside the container, allow local X once on the host: `xhost +local:`
- A developer key: `make key` (once, generates `~/.connectiq/developer_key.der`)
- A TimeTagger instance (self-hosted with a valid TLS cert, or `https://timetagger.app`) and its API token (Settings → API in the TimeTagger web UI)
- Personal container config (git identity, tools, mounts): copy `.devcontainer/docker-compose.override.yml.example` → `docker-compose.override.yml` and/or add `.devcontainer/local/*.sh` hooks — both gitignored

## Commands

| Command | Description |
|---------|-------------|
| `make key` | Generate a developer signing key |
| `make build` | Compile `bin/fr955.prg` |
| `make sim` | Build and run in the Connect IQ simulator |
| `make clean` | Remove build output |

`DEVICE=...` and `KEY=...` can be overridden in `properties.local.mk`.

## Testing

`make selftest` builds `bin/selftest.prg` and runs the 65-assert suite in the simulator. It needs the Connect IQ 8.4.1 simulator at `~/ciq841` (one-time setup: download [connectiq-sdk-lin-8.4.1.zip](https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-8.4.1.zip) and unzip it so `~/ciq841/bin/connectiq` exists). Success prints `TT: RESULTS passed=65 failed=0` and `TT: SELFTEST OK`.

- The suite is offline/hermetic: every client detaches via `SyncClient.setEndpoint("", "")`, no network is touched.
- The selftest app also contains an E2E driver (duplicate-PUT gate: PUT a record, re-PUT the same key, queue reaching 0 proves TimeTagger idempotency). It runs only when the `ttToken` setting is non-empty — i.e. on a real watch.

Simulator constraints:

- 9.x simulators reject developer-signed PRGs ("signature check failed") — use the 8.x simulator above.
- Simulator networking routes through adb + Garmin Connect mobile, so network E2E only works on a real watch. If a `ttToken` is set in simulator settings, the E2E driver crashes with `Symbol Not Found` after the RESULTS lines — known 8.4.1 sim `makeWebRequest` bug; the suite verdict printed above the crash stands.

## Real-watch E2E

1. `make build`, then copy `bin/fr955.prg` to the watch's `GARMIN/APPS/` over USB.
2. In the Garmin Connect app, set `ttUrl` + `ttToken` (TimeTagger API token).
3. Run one pomodoro and verify the record in TimeTagger.
4. Airplane mode: start a pomodoro in airplane mode, end it, reconnect — confirm the queued record syncs.

## Install on the watch

Copy `bin/fr955.prg` to `<watch>/GARMIN/APPS/` over USB.

## Usage

1. Edit the app settings in Garmin Connect (phone): work/break minutes, project tags (newline- or `;`-separated, `[a-z0-9-]` only), TimeTagger URL, API token.
2. Launch the app → pick a project → work phase runs → entries land in TimeTagger as `#<project> focus`.
3. Tap the screen (or Start) for pause / skip / end session. BACK leaves the app; the session keeps running and is retro-closed at the scheduled end if you stayed away.

## Limits

- Foreground only: no vibration if you exit the app mid-phase (data stays correct via resume arithmetic).
- Queue capped at 500 records, drop-oldest.
- Invalid project tags are skipped (shown at the bottom of the picker menu).
- TimeTagger must present a valid TLS certificate (Connect IQ rejects self-signed).

## Architecture

- [docs/architecture.md](docs/architecture.md)
- [docs/adr/](docs/adr/) — decisions in MADR format
