# Recursive UI/UX Review — Progress by Deck v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa hierarchy, density, geometry, interaction và accessibility của Progress by Deck |
| **Scope** | Range selector, summary, deck rows, detail states và mọi responsive/theme/locale state |
| **Source of truth for** | Quy trình recursive UI/UX review Progress by Deck v1 |
| **Depends on** | `docs/prompt/progress-by-deck-v1/implementation.md`, wireframe trên branch và MemoX design tokens |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production route/tree, không review widget giả. `AUDIT_ONLY` chỉ đo,
inspect và báo finding; `APPLY_FIXES`/standalone tự sửa rồi rerender đệ quy.
Không commit/push/PR/merge.

Kiểm loading, mixed activity, all-zero, no decks, error/retry, long nested path,
large counts, move-live-refresh; EN/VI; light/dark; 320dp@2.0, 390, 412dp.
Pin `getRect` cho screen gutter, selector/summary/list shared edges, row widths,
internal padding, metric baselines, row gaps, path wrap, trailing affordance và
bottom-nav clearance. Bảo đảm 7/30 selected state rõ không chỉ bằng màu, hierarchy
scan được, zero không mang sắc thái lỗi, rows có 48dp target và TalkBack đọc
deck/path/range/metrics theo thứ tự hợp lý.

Mỗi fix layout phải có production geometry regression test; golden chỉ được
accept sau state-by-state comparison với wireframe và danh sách approved
divergences. Clean stop khi mọi state đã render/inspect, không unapproved visual
difference hoặc P0/P1/P2 và targeted visual/semantics tests xanh.
