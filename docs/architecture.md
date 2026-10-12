# Architecture

One codebase (this repo, MIT), three devices — two of them already built:

- **Watch** (Forerunner 955): Connect IQ app — pomodoro state machine, entry lifecycle, offline queue.
- **Backend**: TimeTagger (existing, open source) — its web UI doubles as the review UI on desktop/phone.
- **Phone**: Garmin Connect — BLE HTTP bridge + app-settings editor (projects, durations, URL, token).

Data flow: work phase ends → entry `{key, t1, t2, ds: "#<project> focus", mt, st}` (Unix seconds) → queue in Application Storage → `PUT /api/v2/records` with static `authtoken` header → TT `{accepted, failed}` response prunes the queue. Client keys make retries idempotent; pause = entry split; exit mid-phase = retro-close at scheduled end.

## Decisions

- [ADR-0001 — Choice of stack: fresh minimal CIQ app](adr/0001-choice-of-stack.md) — revisit when a maintained MIT pomodoro+logging app appears.
- [ADR-0002 — Sync architecture: watch → TimeTagger direct](adr/0002-sync-architecture.md) — revisit triggers: OpenProject↔TimeTagger bridge (project list may then be fetched from TT settings API), non-TT trackers (n8n routing), glance/background alerts.
