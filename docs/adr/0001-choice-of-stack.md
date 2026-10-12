# 0001. Choice of stack — fresh minimal Connect IQ app

- Status: proposed
- Date: 2026-10-12

## Context and Problem Statement

We need a pomodoro timer on a Garmin Forerunner 955 that logs work phases to a self-hosted time tracker. Which codebase do we start from?

## Decision Drivers

- Must combine pomodoro cycles **and** time-entry logging — no existing app does both
- License: no GPL code may ship in this project
- Watch codebase must stay tiny (watch = hostile dev environment, no on-watch JSON/crypto libs)
- Backend is TimeTagger (chosen separately, see ADR-0002)

## Considered Options

- **Fork garmodoro** (GPL-3): solid pomodoro state machine, ~4 files — but GPL contamination; would force this project GPL and it has no logging at all anyway
- **Fork garmin-toggl** (MIT): proven watch→tracker sync, correct HTTPS mechanics — but no pomodoro cycles, hard-wired to Toggl's API shape
- **Fresh minimal CIQ app** borrowing patterns from both (UX from garmodoro as reference-only, sync mechanics from garmin-toggl): one small codebase owning exactly the two features we need

## Decision Outcome

Chosen option: **fresh minimal Connect IQ app** (MIT), because it is the only path that gets pomodoro + logging + TimeTagger without GPL contamination or Toggl API lock-in, and both references are small enough that reimplementing their core is cheaper than adapting them.

Confidence: high

Revisit when: a maintained MIT app with pomodoro + open-backend logging appears, or CIQ platform changes make a fork cheaper.

### Consequences

- Positive: full ownership, no license debt, no dead code from either reference
- Negative: we re-write the pomodoro state machine and JSON serialization ourselves
- Neutral: garmodoro stays a read-only UX reference; garmin-toggl a code reference
