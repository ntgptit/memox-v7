# Recursive UI/UX review — local prompt handoff tooling

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit developer UX của trigger/output/error và xác nhận task không gây visual delta cho app |
| **Scope** | CLI text, copy-paste trigger ergonomics, diagnostics và no-visual-delta evidence |
| **Source of truth for** | Hướng dẫn recursive usability review của tooling; không phải UI contract sản phẩm |
| **Depends on** | `docs/prompt/local-prompt-handoff-tooling/implementation.md`, `AGENTS.md`, latest worktree |
| **Updated by task** | Terra tooling campaign |
| **Last updated** | 2026-08-28 |

---

Pass đầu **audit-only**. Scope không có production UI, nhưng claim no-visual-delta
vẫn phải có bằng chứng: render production tree của một screen đại diện ở loaded
state bằng golden harness hiện có và so trước/sau. Pin `getRect` cho screen gutter,
primary surface và bottom navigation; geometry phải tuyệt đối không đổi. Danh sách
**approved divergence** là rỗng; mọi **unapproved divergence** về pixel, rect,
semantics hoặc production state là scope violation, không được update golden để
nhận baseline mới.

Kiểm bằng invocation thật rằng trigger copy-paste được trong PowerShell, paths được
quote đúng, success output phân định ba phase rõ, error nói input nào sai và cách lấy
handoff mới nhưng không rò prompt body. Kiểm message không phụ thuộc màu, không yêu cầu
người dùng đoán source/target và `-VerifyOnly` được mô tả đúng.

Diff audit phải chứng minh không file dưới `lib/`, `widgetbook/`, ARB hay golden đổi;
nếu có thì là scope violation. Gallery không regenerate; PR phải link gallery hiện hữu
và ghi explicit no-visual-delta.

Sau report, coordinator auto-fix text/ergonomics trong scope, chạy tests và reviewer
lặp lại. Clean stop khi một trigger mới có thể chạy không giải thích miệng thêm, mọi
failure actionable, không visual delta và final gate xanh.
