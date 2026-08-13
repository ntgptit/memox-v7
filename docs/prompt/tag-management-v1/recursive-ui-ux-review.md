# Recursive UI/UX Review — Tag Management v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa tag catalog/filter density, geometry, destructive copy và accessibility |
| **Scope** | Catalog, multi-tag filter, rename/merge/delete overlays và Card List filtered states |
| **Source of truth for** | Quy trình recursive UI/UX review Tag Management v1 |
| **Depends on** | `docs/prompt/tag-management-v1/implementation.md`, tag wireframes và MemoX tokens |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production entry points. `AUDIT_ONLY` inspect/measure only;
`APPLY_FIXES`/standalone repair recursively. No commit/push/PR/merge.

Inspect populated/empty/search-empty catalog, many long tags/counts, multi-tag
filter none/one/many, filtered no-results, rename, merge disclosure, delete
confirm, submitting/errors; EN/VI, light/dark, 320dp@2.0, 390/412dp. Pin
`getRect` for gutters, catalog/filter shared edges, row widths, name/count/menu
baselines, chips/gaps/wrap, overlay action alignment, keyboard insets and safe
area.

Ensure entry affordance visible, selected tags not color-only, Clear/Apply state
obvious, chips remain readable, destructive copy says unlink not card deletion,
merge explains target, 48dp targets/TalkBack multi-select semantics and focus
return. Add geometry/semantics regression per fix; compare goldens to wireframe.
Clean stop when all states inspected and no unapproved divergence/P0/P1/P2.
