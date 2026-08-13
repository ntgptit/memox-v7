# Recursive UI/UX Review — Global Library Search v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa search focus, grouped hierarchy, density, geometry và accessibility |
| **Scope** | Library search field, Deck/Card groups, initial/loading/empty/error/pagination states và result navigation |
| **Source of truth for** | Quy trình recursive UI/UX review Global Library Search v1 |
| **Depends on** | `docs/prompt/global-library-search-v1/implementation.md`, Global Search wireframe và MemoX tokens |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production Library search. `AUDIT_ONLY` inspect-only;
`APPLY_FIXES`/standalone repair/rerender recursively. No commit/push/PR/merge.

Inspect initial focus/no DB, typing/debounce/loading, mixed, decks-only,
cards-only, no results, top/page error, loading-more, long paths/Front/Back/tag
match, keyboard open/back/clear; EN/VI, light/dark, 320dp@2.0, 390/412dp. Pin
`getRect` for screen gutter, search/group/list shared edges, field/action
alignment, group headers, row widths, path/summary baselines, vertical rhythm,
page indicator and keyboard/bottom-nav/safe-area clearance.

Ensure Deck/Card groups scan distinctly without excess chrome; one-line Back is
a summary with accessible full context where appropriate; match highlight has
contrast and is not only signal; clear/back/focus predictable; loading does not
erase previous results unnecessarily; 48dp targets and TalkBack announces group,
type, path and action. Add geometry/semantics regression for every fix and
compare goldens to wireframe. Clean stop when all states inspected and no
unapproved divergence/P0/P1/P2.
