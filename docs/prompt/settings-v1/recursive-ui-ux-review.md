# Recursive UI/UX Review — Settings v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa hierarchy, control states, geometry và accessibility của Settings v1 |
| **Scope** | Study defaults, Appearance, Language, saving/error states và root use-defaults affordance |
| **Source of truth for** | Quy trình recursive UI/UX review Settings v1 |
| **Depends on** | `docs/prompt/settings-v1/implementation.md`, Settings wireframe và MemoX theme/components |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production Settings và root-options surfaces. `AUDIT_ONLY` chỉ inspect;
`APPLY_FIXES`/standalone sửa/rerender đệ quy. Không commit/push/PR/merge.

Ma trận: defaults, explicit values, root override, saving, validation error,
persistence error/retry, System theme/locale resolution; EN/VI; light/dark;
320dp@2.0, 390/412dp. Pin `getRect` cho screen gutter, section shared edges,
row/control widths, title/support baselines, radio/segmented alignment, vertical
rhythm, error placement và bottom-nav clearance.

Kiểm selected/disabled/loading states không chỉ bằng màu, 48dp targets, TalkBack
role/value/hint, focus order, immediate theme/language feedback không flash,
supporting copy không lặp và reset action không bị hiểu là reset progress. Không
hardcode visual values. Mỗi fix có geometry/semantics regression assertion và
golden comparison với wireframe. Clean stop khi mọi state đã inspect, không
unapproved divergence/P0/P1/P2 và targeted visual tests xanh.
