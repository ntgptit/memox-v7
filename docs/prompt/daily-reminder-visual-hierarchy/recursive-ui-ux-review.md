# Recursive UI/UX Review — Daily Reminder Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit trực quan và auto-fix Daily Reminder theo Card Detail style và M6 |
| **Scope** | Layout, states, responsiveness, interaction, accessibility và render evidence của Reminder Settings |
| **Source of truth for** | Quy trình recursive UI/UX review của Daily Reminder visual hierarchy |
| **Depends on** | `implementation.md`, M6 Daily Reminders, production Card Detail, tokens và current goldens |
| **Updated by task** | Daily Reminder visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Review sau architecture fixes. Card Detail định flat surface/compact type/icon
wells; M6 định toggle/time/status/supporting anatomy. Không copy Card Detail
metric grid/timeline và không thêm notification preview giả.

## Phase order và worktree safety

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: **render
production states**, so wireframe/golden và lập inventory trước khi sửa. Không
revert ngoài scope, không commit/push/PR/merge. Sau đó mới auto-fix mọi
unapproved divergence, chạy verification/tests và recursive review lại.

Render light/dark, 320×568 @2.0, 393dp, 412dp, EN/VI cho off, enabling, on,
picker, permission denied, unavailable, schedule/settings/cancel errors và read
error. Inspect 12/24-hour copy và scroll-to-bottom.

Pin bằng `tester.getRect` trên production tree: schedule/status/info shared edges, toggle alignment, time label/value left
edge, row/card stable height, banner flow placement, retry target, info wrapping,
appbar/back and bottom-nav clearance. Kiểm giant title/copy, floating paragraphs,
double card/border/shadow, saturated error surface, switch-only-color, clipped
labels và state layout jump.

Ghi finding với state/viewport/screenshot/rect; auto-fix và render lại tới
**clean stop** khi không P0/P1/P2, no overflow/ellipsis, semantics/targets pass và all state hierarchy rõ
trong light/dark. Không đổi scheduling/logic, không publish gallery/PR.
