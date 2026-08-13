# Recursive UI/UX Review — Reverse Self-assess v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa direction chooser, prompt/reveal parity, geometry và accessibility của Reverse Self-assess |
| **Scope** | Eligible chooser và SM-2 self-assess running/resume states; eight-box regression |
| **Source of truth for** | Quy trình recursive UI/UX review Reverse Self-assess v1 |
| **Depends on** | `docs/prompt/reverse-self-assess-v1/implementation.md`, Study wireframe và approved Browse/Self-assess layout |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production entry/session. `AUDIT_ONLY` không edit; `APPLY_FIXES`/
standalone sửa/rerender đệ quy. Không commit/push/PR/merge.

Inspect chooser three options, loading/failure, Korean→Meaning prompt/reveal,
Meaning→Korean prompt/reveal, Mixed both directions, resume, long Korean/meaning,
eight-box unchanged; EN/VI, light/dark, 320dp@2.0, 390/412dp. Pin `getRect` cho
content gutter, option shared widths/edges, option gaps, prompt/reveal card edges,
labels/text baselines, action row, progress and bottom safe area.

Verify selected state and reveal are not color-only; copy makes direction
understandable without exposing implementation words; Korean typography and long
Vietnamese wrapping remain readable; actions keep 48dp targets/TalkBack order;
no layout jump when reveal/resume. Regression goldens require concept/wireframe
comparison. Clean stop when no unapproved divergence/P0/P1/P2 and all state
geometry/semantics tests pass.
