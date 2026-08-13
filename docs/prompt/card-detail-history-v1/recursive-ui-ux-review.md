# Recursive UI/UX Review — Card Detail and History v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa readability, timeline hierarchy, geometry, interaction và accessibility của Card Detail |
| **Scope** | Detail header/content/state/history, pagination/error/empty states và editor affordance |
| **Source of truth for** | Quy trình recursive UI/UX review Card Detail and History v1 |
| **Depends on** | `docs/prompt/card-detail-history-v1/implementation.md`, Card Detail wireframe và MemoX tokens |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render via production card-row route. `AUDIT_ONLY` inspect-only;
`APPLY_FIXES`/standalone repair recursively. No commit/push/PR/merge.

Inspect loading, new card/no history, both schedulers, multiple generations,
50+ rows/loading-more/page error, not-found, very long Korean/meaning/optional
fields/tags; EN/VI, light/dark, 320dp@2.0, 390/412dp. Pin `getRect` for screen
gutter, content/state/history shared edges, header/title/action alignment,
label/value baselines, generation header/row gaps, timeline marker baseline,
load-more/error placement and safe area.

Ensure full content is readable rather than arbitrarily clipped; Edit is visible
but does not look like primary study action; history scans newest-first; scheduler
generation and before→after changes are understandable without color; timestamps
localized; TalkBack groups event meaning and action targets are 48dp. Preserve
scroll/list context on Back. Every fix adds geometry/semantics regression and
goldens are compared to wireframe. Clean stop when all states inspected and no
unapproved divergence/P0/P1/P2.
