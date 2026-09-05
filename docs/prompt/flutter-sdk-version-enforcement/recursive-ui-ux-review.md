# Recursive UI/UX review — Flutter SDK version enforcement

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit developer-facing diagnostics và chứng minh enforcement không tạo app visual delta |
| **Scope** | CLI failure/success output, latency perception và no-visual-delta evidence |
| **Source of truth for** | Hướng dẫn recursive developer-UX review của SDK gate |
| **Depends on** | `docs/prompt/flutter-sdk-version-enforcement/implementation.md`, latest worktree |
| **Updated by task** | Terra verification campaign |
| **Last updated** | 2026-08-28 |

---

Pass đầu audit-only. Chạy mismatch fixture và đánh giá message trả lời đủ: SDK nào đang
dùng, expected gì, executable ở đâu, sửa bằng cách nào, bước nào chưa chạy. Không dùng
màu làm tín hiệu duy nhất, không in noise/stack trace cho lỗi cấu hình bình thường.

Render production tree loaded state của một screen đại diện qua golden harness để
pin claim no-visual-delta. So `getRect` screen gutter, primary card và bottom
navigation; danh sách **approved divergence** phải rỗng, mọi **unapproved
divergence** hay golden delta là scope violation và không được nhận bằng update
baseline.

Đo docs-only path để bảo đảm không có spinner/chờ Flutter vô ích. Diff phải có 0 file
production UI/golden/ARB. Coordinator auto-fix diagnostics trong scope và reviewer lặp.
Clean stop khi error actionable một lần đọc, docs-only nhanh như baseline, no visual
delta và gate xanh.
