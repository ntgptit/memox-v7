# Recursive UI/UX Review — Tag Catalog Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit trực quan độc lập và auto-fix Tag Catalog tới khi đạt Card Detail visual language và M4.14 |
| **Scope** | Layout, hierarchy, interaction, responsiveness, accessibility và visual evidence của Tag Catalog/overlays |
| **Source of truth for** | Quy trình recursive UI/UX review của Tag Catalog visual hierarchy |
| **Depends on** | `implementation.md`, M4.14, production Card Detail, MemoX tokens, current production states/goldens |
| **Updated by task** | Tag Catalog visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Review độc lập sau khi architecture fixes đã được áp dụng. Re-read worktree mới
nhất. Card Detail là style reference cho surface ladder, compact type, density và
shared edges; M4.14 vẫn là contract anatomy/behavior.

## Phase order và worktree safety

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: render
production states, so wireframe/golden và lập inventory trước khi sửa. Không
revert diff ngoài scope, không commit/push/PR/merge. Sau đó mới auto-fix theo
inventory, chạy verification/tests sau mỗi batch và recursive review lại từ đầu.

## Visual contract và approved divergences

- Catalog là operational list, nên dùng **một** grouped surface thay vì summary,
  progress và timeline của Card Detail.
- Không copy scheduler chips, metric grid hoặc history event cards.
- Search được pin theo M4.14; Card Detail không có search nên không phải reference
  cho vị trí này.
- Không thêm icon màu riêng cho từng tag, create CTA hoặc preview card.

## Render/audit matrix

Render production tree ở light/dark, 320dp @2.0, 393dp, 412dp, EN/VI:
populated, long names/counts, zero-card, empty, search-empty, error, rename,
merge disclosure, validation/write error, delete 0/many-card và keyboard-open.

Đối chiếu trực tiếp từng ảnh với Card Detail grammar và M4.14. Golden mới chỉ là
baseline sau khi comparison pass; không bulk-accept.

## Geometry assertions

- Dùng `tester.getRect` trên production tree, không đo widget giả.
- Search, catalog surface và state faces chung left/right edge.
- Mọi row chung edges; name/count chung baseline trái; separator không vượt
  content column.
- Menu target ≥48dp và nằm trong gutter; row cao thay đổi chỉ vì wrap có chủ ý.
- Overlay content/action chung cột; action nằm trên keyboard và safe area.
- Không nested padding, không card-per-row, không double shadow/border.

## Recursive auto-fix

Ghi finding với screenshot/state/viewport, expected/actual và rect khi có. Auto-
fix mọi **unapproved divergence**; regenerate state; inspect lại; lặp tới **clean
stop** khi
không còn P0/P1/P2, không overflow/clip/ellipsis ngoài M4.14, semantics/tap target
pass và light/dark đều có surface hierarchy rõ. Reviewer không publish gallery,
không tạo PR và không thay nghiệp vụ.
