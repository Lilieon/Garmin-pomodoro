# 0002. Sync architecture — watch talks to TimeTagger directly

- Status: proposed
- Date: 2026-10-12

## Context and Problem Statement

The watch must create time entries in TimeTagger (self-hosted or timetagger.app). Connect IQ has no crypto module, no JSON writer, no UUID primitive, and HTTP goes through the phone via BLE. Where does the sync logic live, and what is the wire contract?

## Decision Drivers

- No middle layer to host/maintain unless it earns its keep
- No crypto on watch → auth must be a static header
- Flaky link (phone absent, server down) → no lost or duplicated entries
- Unix timestamps avoid all timezone math on the watch (the trap that killed Kimai 2)
- Projects must stay editable from the phone without rebuilding the app

## Considered Options

- **Direct watch → TimeTagger REST** (`PUT /api/v2/records`, static `authtoken` header, batch JSON list)
- n8n routing workflow as a proxy
- Custom micro-backend translating to another tracker

## Decision Outcome

Chosen option: **direct watch → TimeTagger**. The API needs only what CIQ offers: static-header auth, hand-rolled JSON (`{"key","t1","t2","ds","mt","st"}`, integer Unix seconds, `st=0`), and client-generated keys (`<epochSec>-<counter>-<rand>`) giving idempotent retries for free. Records land as `ds = "#<project> focus"`. Offline entries queue in Application Storage (cap 500, drop-oldest) and flush on app open and after each enqueue. Projects are CIQ app settings (newline/`;`-separated tags) edited in Garmin Connect — no fetch code on watch.

Confidence: high

Revisit when:
- The OpenProject ↔ TimeTagger bridge lands (watch may then read the curated project list via TimeTagger `GET settings` — same auth and base URL, zero protocol change)
- Entries should route to trackers other than TimeTagger (add n8n between watch and backend)
- Glance view or background temporal alerts are wanted

### Consequences

- Positive: zero infrastructure; idempotency by design; timezone-free timestamps; projects editable without rebuild
- Negative: foreground-only timer (no vibration when app closed mid-phase — resume arithmetic keeps data correct); queue loss possible past 500 records (shortcut: flash-based file if ever hit); self-hosted TimeTagger needs a valid TLS cert (CIQ rejects self-signed)
- Neutral: TT `failed` keys are dropped from the queue (permanently invalid — retrying is poison); network-level failures stay queued
