# Recursive UI/UX review — Deck ancestry cycle safety

| | |
|---|---|
| **Status** | active |
| **Purpose** | Xác nhận breadcrumb hợp lệ không đổi và không có visual delta ngoài việc app không còn treo trên dữ liệu lỗi |
| **Scope** | Deck breadcrumb observable behavior, loading/error termination và no-visual-delta evidence |
| **Source of truth for** | Hướng dẫn recursive UI impact review của data fix |
| **Depends on** | `docs/prompt/deck-ancestry-cycle-safety/implementation.md`, Deck wireframe/spec, latest worktree |
| **Updated by task** | Terra bounded-data campaign |
| **Last updated** | 2026-08-28 |

---

Pass đầu audit-only. Không redesign Deck. Dùng production tree/harness xác nhận legal
breadcrumb ở các depth đại diện giữ cùng label/order/tap destination/back behavior và
không thêm spinner vô hạn. Với corrupted cycle, observable surface phải settle theo
failure policy hiện có thay vì treo; không invent copy mới nếu contract chưa có.

Pin `getRect` cho breadcrumb band, title và content leading edge ở fixture sạch
trước/sau; các rect phải giữ nguyên. Bảng **approved divergence** phải rỗng vì
task không được đổi layout; mọi **unapproved divergence** hoặc golden delta phải
bị revert, không được nhận bằng cách update baseline.

So diff để chứng minh không token/layout/golden đổi. Nếu pixel đổi, đó là finding cần
revert hoặc owner approval. Coordinator auto-fix regression trong scope và reviewer
lặp. Clean stop khi legal UI parity giữ nguyên, cycle không tạo permanent loading,
no-visual-delta được chứng minh và gate xanh.
