# Recursive UI/UX Review — Strict Widget Boundary

| | |
|---|---|
| **Status** | active |
| **Purpose** | Xác nhận strict enforcement bảo vệ design system mà không buộc wrapper noise hoặc tạo visual regression trong cleanup |
| **Scope** | Final classification/admission semantics, no-visual-delta proof, shared catalog consistency và gallery decision |
| **Source of truth for** | Hướng dẫn recursive UI/UX audit strict boundary; visuals thuộc tokens, wireframes, concepts và approved gallery |
| **Depends on** | `docs/prompt/design-system-widget-boundary-enforcement/implementation.md`, latest architecture fixes, design parity checklist và gallery |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Review sau architecture pass và re-read latest tree.

## Audit-only first pass

Vòng đầu là **audit-only**: không sửa code/golden/registry. Ghi approved
divergence và unapproved divergence cho mọi production render file trong diff,
rồi mới bắt đầu auto-fix.

## Audit loop

1. Kiểm diff có production render change không.
2. Nếu không, chứng minh no visual delta bằng unchanged feature/shared/theme files
   và no golden drift; không regenerate gallery giả.
3. Nếu có, render affected production states light/dark/320/2.0x, so approved
   gallery và auto-fix hoặc chuyển lại migration scope.
4. Review registry để chắc component policy mang UX value observable, không phải
   wrapper count.
5. Chạy gate và lặp tới sạch.

## UX criteria

- Layout primitives vẫn raw và không có Mx wrapper vô nghĩa.
- Theme-owned raw control chỉ còn khi ThemeData thực sự sở hữu states và không
  local override.
- Shared component có states/semantics/responsive/variant/behavior evidence đúng
  với policy khai báo.
- Không raw Cupertino lẫn design language vào Android UI.
- Strict cleanup không đổi content gutter, hierarchy, control density, focus,
  touch target, overlay behavior hoặc typography.
- Không update golden chỉ vì strict refactor; mọi pixel delta cần approved reason.

Nếu có production delta, thêm `tester.getRect(...)` assertions cho content
gutters, shared edges, widths, gaps và baselines có nguy cơ; nếu no delta, xác
nhận các `getRect` contracts hiện hữu vẫn chạy và không bị xoá để làm gate xanh.

Full gate phải xanh. Nếu no visual delta, PR ghi gallery intentionally not
regenerated và link existing Artifact. Nếu có valid user-visible delta, phải
regenerate `TZ=UTC`, inspect, build và republish existing gallery trước clean stop.

## Clean stop

Clean stop chỉ đạt khi recursive rerun không còn unapproved divergence, geometry
và accessibility evidence xanh, không wrapper noise, gallery decision đúng với
visual diff và full gate pass.
