# Recursive UI/UX Review — Settings Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit trực quan và auto-fix Settings theo Card Detail style và M99 Settings |
| **Scope** | Hierarchy, form interaction, layout, responsive, accessibility và rendered states của Settings |
| **Source of truth for** | Quy trình recursive UI/UX review của Settings visual hierarchy |
| **Depends on** | `implementation.md`, M99 Settings, production Card Detail, MemoX tokens và current goldens |
| **Updated by task** | Settings visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Review sau architecture fixes. Card Detail cung cấp flat surface/compact type;
M99 Settings giữ group anatomy, radio controls và reset behavior. Approved
divergence: Settings là form dài, không copy summary/timeline/metric grid.

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: **render
production states**, so wireframe/golden và lập inventory trước khi sửa. Không
revert ngoài scope, không commit/push/PR/merge. Sau đó mới auto-fix mọi unapproved
divergence, chạy verification/tests và recursive review lại.

Render light/dark, 320dp @2.0, 393dp, 412dp, EN/VI: default, custom, pristine,
dirty, validation error, each group saving/failure, read error, reset dialog và
keyboard-open. Inspect both top and scrolled-to-bottom states.

Pin bằng `tester.getRect` trên production tree: content/card/shared edges, section rhythm, study field/radio alignment,
choice row full-width ink and 48dp target, Save rect/stability, error band,
reminder row, reset region and bottom-nav clearance. Kiểm card soup, oversized
radio rows/text fields, Save always-primary while pristine, nested padding,
danger card, clipping/ellipsis and layout shift while saving.

Mỗi finding phải có state/viewport/screenshot/rect. Auto-fix, render lại và lặp
tới **clean stop** khi không P0/P1/P2, all themes/locales/scales pass, focus/semantics rõ và screen
scan được theo group. Không đổi persistence/behavior, không publish gallery/PR.
