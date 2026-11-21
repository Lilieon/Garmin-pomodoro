# 0003. Dev container personalization — Compose base + gitignored override

- Status: proposed
- Date: 2026-11-15

## Context and Problem Statement

The dev container is defined by a single committed `devcontainer.json` + `Dockerfile`. It currently mixes configuration every contributor needs (JDK, Connect IQ SDK, X11, gh CLI) with machine- or user-specific settings (DNS workaround, personal tool mounts, git identity baked into the image). The dev container spec has no native local-override file (`devcontainer.override.json` proposal, spec issue #305, still open), so personalization either pollutes the shared config or forces manual edits after every rebuild.

## Decision Drivers

- New contributors must get a working environment from `git clone` → "Reopen in Container" with zero manual steps
- Personal settings (identity, tools, mounts, machine quirks) must never be committed nor baked into the image
- Overrides must cover container-level config: mounts, environment, `runArgs`-equivalents — not just post-create commands
- Only mechanisms natively supported by VS Code Dev Containers (no third-party extension dependency)

## Considered Options

- **Keep Dockerfile-based devcontainer + conditional local hooks** (`post-create.sh` sourcing gitignored `local/*.sh`): simple, but mounts/runArgs/env cannot be personalized locally — they are fixed at container creation by the committed `devcontainer.json`
- **Docker Compose with file list** (`dockerComposeFile: [docker-compose.yml, docker-compose.override.yml]`, override gitignored): Compose natively merges the files; the gitignored override can add volumes, environment, DNS per machine. Requires the override to exist (`docker compose` fails on a missing `-f`) — solvable by seeding it in `initializeCommand`
- **devcontainer CLI `--override-config`**: deep-merges any config, but CLI-only (not the VS Code GUI)
- **`git update-index --skip-worktree` / third-party merge extension**: workarounds with poor ergonomics or a new dependency

## Decision Outcome

Chosen option: **Docker Compose base + gitignored override**, combined with the local-hooks pattern for post-create commands.

- `.devcontainer/docker-compose.yml` — committed base: build, `sleep infinity`, workspace bind, X11, ssh-agent, optional `gh.env` secrets
- `.devcontainer/docker-compose.override.yml` — gitignored personal override, seeded from a committed `.example` by `initializeCommand` (`scripts/init-host.sh`)
- `.devcontainer/scripts/post-create.sh` — committed shared setup, then runs every `.devcontainer/local/*.sh` (gitignored personal hooks: git identity, personal CLIs)
- `Dockerfile` slims down to the shared base: personal git identity and personal CLIs move out of the image

Confidence: high.

Revisit when: the dev container spec ships a native override file (spec issue #305), which would remove the need for the Compose indirection.

### Consequences

- Positive: "clone and reopen" works for anyone; personal config survives rebuilds and stays out of git; image carries no user data
- Positive: the same mechanism extends the container locally (extra mounts, env, DNS, sidecar services)
- Negative: Compose mode has its own gotchas (container needs `command: sleep infinity`; a listed compose file must exist; no automatic UID/GID sync — the chown stays in post-create)
- Neutral: personal VS Code extensions (e.g. Kilo) belong in the user setting `dev.containers.defaultExtensions`, not in the committed `customizations`
