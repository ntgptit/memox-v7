# Recursive UI/UX Review — Progress by Deck Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit trực quan và auto-fix Progress by Deck theo Card Detail style và canonical wireframe |
| **Scope** | Layout, density, hierarchy, interaction, responsive, semantics và rendered states |
| **Source of truth for** | Quy trình recursive UI/UX review của Progress by Deck visual hierarchy |
| **Depends on** | `implementation.md`, M99 Progress by Deck, M99.23, production Card Detail, tokens và goldens |
| **Updated by task** | Progress by Deck visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Review sau architecture fixes. Card Detail định style flat/compact; wireframe
định metric, range và drill-down. Không copy content hero/timeline, không thêm
Study CTA, accuracy/streak/filter.

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: **render
production states**, so wireframe/golden và lập inventory trước khi sửa. Không
revert ngoài scope, không commit/push/PR/merge. Sau đó mới auto-fix unapproved
divergence, chạy verification/tests và recursive review lại.

Render top-level và deck-level ở light/dark, 320dp @2.0, 393dp, 412dp, EN/VI:
mixed, all-zero, long path/counts, no decks, no subdecks, error, missing và deep
tree. Inspect pinned range trong lúc scroll, không chỉ idle screenshot.

Pin bằng `tester.getRect` trên production tree: range/summary/row shared edges, appbar/context visibility, summary grid
folding, row grid baseline, title/path wrap, chevron/tap rect, section/row gaps,
last-row clearance và no layout shift giữa states. Kiểm giant metrics, card soup,
double padding/shadow, saturated zero states và title mất khỏi first viewport.

Mỗi finding có state/viewport/screenshot/rect; auto-fix, render lại, lặp tới
**clean stop** khi không P0/P1/P2, no overflow/clip, semantics/targets pass và hierarchy top/deep
đều rõ trong light/dark. Không đổi logic, không publish gallery/PR.
