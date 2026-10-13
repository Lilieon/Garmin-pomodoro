# Pomodoro TT

Pomodoro timer for Garmin Forerunner 955 logging work phases directly to TimeTagger.

## Prerequisites

- OpenJDK (JRE enough) and Connect IQ SDK at `$CIQ_SDK` (preinstalled in the devcontainer at `/opt/connectiq`)
- Developer key via `make key` (gitignored)

## Commands

| Command | Description |
|---------|-------------|
| `make build` | Compile `bin/fr955.prg` (monkeyc via monkeybrains.jar) |
| `make sim` | Build + launch simulator with the app |
| `make selftest` | Build + run the 65-assert hermetic suite in the simulator |
| `make clean` | Remove `bin/` |
| `make key` | Generate developer signing key |

## Project layout

```
.devcontainer/     dev container (JDK + Connect IQ SDK)
watch/
  manifest.xml     app id, fr955 product, Communications permission
  monkey.jungle    compiler config (source + resources paths)
  resources/       properties.xml, settings.xml (Garmin Connect settings UI), strings.xml
  source/          Monkey C: PomodoroApp, ProjectPicker, TimerView, TimerDelegate, EntryLog, SyncClient
docs/adr/          architecture decisions (MADR)
```

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `docs:`, …).
- No GPL code (garmodoro is reference-only). garmin-toggl (MIT) is the sync-mechanics reference.
- Persisted Storage dictionaries use String keys/values only.
- Never log or echo the API token.
- `make selftest` needs the 8.4.1 simulator at `~/ciq841` (9.x sims reject developer-signed PRGs).
- ADRs stay `proposed` until reviewed by the user.

## Architecture

- Architecture documentation: [docs/architecture.md](docs/architecture.md)
- Decision records: [docs/adr/](docs/adr/) — one decision per file, MADR format, accepted ADRs are immutable (supersede via a new ADR)
