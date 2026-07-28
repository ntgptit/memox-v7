# Documentation

## What exists

| Document | Purpose | Status |
|---|---|---|
| [`checklist.md`](checklist.md) | The canonical 22-phase development plan | complete, stable |
| [`wbs.md`](wbs.md) | Live progress ledger — the source of truth for what is done | active |
| [`product.md`](product.md) | Problem, users, platform/data/auth decisions, **and MVP scope** | draft |
| [`architecture.md`](architecture.md) | Architecture decisions AD-01…07 with reasoning | active |
| [`use-cases.md`](use-cases.md) | UC-01…06 cho must-have MVP | draft |
| [`business-rules.md`](business-rules.md) | BR-01…23, thuật toán 8-box, validation, edge cases | draft |

MVP scope lives inside `product.md` rather than a separate `mvp.md` — it is
short, and splitting it would mean two files that must agree about the same
feature list.

## Not written yet

These are deliberately absent rather than forgotten. Each is created by the
phase that owns it — an empty placeholder would read as "considered, nothing
needed", which is worse than an obvious gap.

| Document | Created during | Owning skill |
|---|---|---|
| `data-model.md` | Phase 11.1 | `flutter-data-layer` |
| `api-spec.md` | Phase 10.2 — **not until the Spring Boot backend exists** (AD-05) | `flutter-data-layer` |
| `design-system.md` | Phase 7 | `flutter-design-system` |
| `testing-strategy.md` | Phase 15 | `flutter-testing` |
| `release-checklist.md` | Phase 20–21 | `flutter-ship` |

Templates for the Phase 0–1 documents are in
`.claude/skills/flutter-product-spec/assets/`.

## The rule that keeps this useful

Documentation and source code are updated in the same commit. A document that
lags the code is actively harmful — the next session reads it, believes it, and
builds on something that is no longer true. If a change makes a document wrong,
either fix the document or note the discrepancy in `wbs.md` before merging.
