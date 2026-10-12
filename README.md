# Pomodoro TT

Pomodoro timer for Garmin Forerunner 955 that logs work phases straight into TimeTagger — no middle layer, no phone app beyond Garmin Connect.

Work phases become TimeTagger records (`{"key", "t1", "t2", "ds": "#<project> focus"}`); breaks are never logged; pausing splits the entry. Offline time is queued on the watch and flushed later — client-generated keys make retries idempotent.

## Prerequisites

- Docker + VS Code Dev Containers (the `.devcontainer/` image ships OpenJDK and Connect IQ SDK 7+)
- For `make sim` inside the container, allow local X once on the host: `xhost +local:`
- A developer key: `make key` (once, generates `~/.connectiq/developer_key.der`)
- A TimeTagger instance (self-hosted with a valid TLS cert, or `https://timetagger.app`) and its API token (Settings → API in the TimeTagger web UI)

## Commands

| Command | Description |
|---------|-------------|
| `make key` | Generate a developer signing key |
| `make build` | Compile `bin/fr955.prg` |
| `make sim` | Build and run in the Connect IQ simulator |
| `make clean` | Remove build output |

`DEVICE=...` and `KEY=...` can be overridden in `properties.local.mk`.

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
