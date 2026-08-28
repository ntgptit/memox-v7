# Recursive UI/UX review — Card Export visual hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | So production export states với M4.13 và Card Detail visual language bằng geometry thật |
| **Scope** | Sheet hierarchy, options, feedback states, action bar, responsiveness và accessibility |
| **Source of truth for** | Hướng dẫn recursive visual audit; M4.13/tokens/canonical copy intent vẫn là contract |
| **Depends on** | `docs/prompt/card-export-visual-hierarchy/implementation.md`, `docs/wireframes/m4-13-card-export.md`, production goldens |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

First pass audit-only. Render production all/selected, scope-changed, generating, error,
VI, compact@2.0 và light/dark states. Golden mới không chứng minh parity.

Dùng `getRect` pin sheet/content gutter, shared edges của summary/options/explanation/action,
equal option widths, stable progress/button bounds và safe area. Selected/error/success không
chỉ dựa màu; copy, count, icon và semantics không lặp; long name không overflow.

Lập bảng concept intent/evidence/approved divergence/result trước fix. Approved differences
chỉ là production copy/fields bắt buộc bởi UC-11 và MemoX token/theme; không tự thêm.
Coordinator auto-fix trên **latest worktree**, add geometry/semantics tests, run gate,
render lại tới clean stop:
không P0/P1/P2, every state inspected, goldens `TZ=UTC` và gallery cũ republish.
Reviewer không commit/push/merge.
