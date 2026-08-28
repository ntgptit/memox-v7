# Recursive architecture and logic review — Card List management

| | |
|---|---|
| **Status** | active |
| **Purpose** | Bảo đảm restyle Card List không làm lệch CRUD, query, bulk selection hoặc navigation |
| **Scope** | Card List presentation delta và mọi callback/use-case/repository consumer bị ảnh hưởng |
| **Source of truth for** | Hướng dẫn recursive logic review; BR/UC/data model vẫn canonical |
| **Depends on** | `docs/prompt/card-list-management-visual-hierarchy/implementation.md`, UC-04, M4.11 và latest worktree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

First pass **audit-only**. Trace từ tap/long-press/search/filter/select-all/menu tới
controller, use case và repository. Tái hiện row mở Detail, edit, move, flag/tag,
single/bulk delete, export selected, study CTA, pagination và back-state preservation.

Tìm business logic bị đưa vào widget, `ref.watch` trong callback, selection id bị mất/
nhân đôi, filtered view làm đổi export-all semantics, tombstone leakage, double submit,
failure bị nuốt và raw navigation. Presentation restyle MUST NOT tạo database mutation mới.

Mỗi finding có reproduction/file/line/contract/test. Coordinator auto-fix architecture
trước, chạy changed gate, reviewer re-read latest tree và lặp. Không sửa docs để hợp thức
hóa regression, không thay expected test vô căn cứ. Clean stop khi behavior parity,
typed failures và dependency boundary đều sạch, full gate xanh. Reviewer không commit/
push/PR/merge shared worktree.
