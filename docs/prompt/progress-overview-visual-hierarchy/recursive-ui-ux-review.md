# Recursive UI/UX Review — Progress Overview Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit trực quan và auto-fix Progress Overview theo style Card Detail và M99.23 |
| **Scope** | Hierarchy, geometry, responsive, accessibility và render states của ba overview sections |
| **Source of truth for** | Quy trình recursive UI/UX review của Progress Overview visual hierarchy |
| **Depends on** | `implementation.md`, M99.23, M99 Progress by Deck, production Card Detail, tokens và goldens |
| **Updated by task** | Progress Overview visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Re-read sau architecture fixes. Card Detail là style reference; M99.23 sở hữu
anatomy. Approved divergences: overview có một compact numeric hero và chart;
không copy card content/timeline. Chart bar tùy biến hiện hành được giữ vì
`MxProgressBar` mang success-at-100 semantics sai cho relative weekly maximum.

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: **render
production states**, so wireframe/golden và lập inventory; chưa sửa. Không revert
ngoài scope, không commit/push/PR/merge. Sau đó mới auto-fix mọi unapproved
divergence, chạy verification/tests và recursive review lại.

Render light/dark, 320dp @2.0, 393dp, 412dp, EN/VI cho active/held/zero streak,
mixed/zero Today, mixed/all-zero week, lifetime empty, error và refresh.

Đo bằng `tester.getRect` trên production tree: shared edges/width, section gaps, hero height, Today hierarchy/grid, bảy bar
baselines/right edges/pitch/value column, overview-to-range transition và bottom
clearance. Kiểm giant-type dominance, card soup, double border/shadow, saturated
fills, clipped 3–4 digit counts và range band trông như điều khiển overview.

Ghi từng finding kèm state/viewport/screenshot/rect; auto-fix rồi render lại.
**Clean stop** khi không P0/P1/P2, tất cả states/locales/themes readable, semantics
đúng, no overflow/clip và hierarchy cho phép thấy Streak + Today trong first
viewport hợp lý. Không đổi metric/logic, không publish gallery/PR.
