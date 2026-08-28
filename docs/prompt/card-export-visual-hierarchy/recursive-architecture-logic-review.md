# Recursive architecture and logic review — Card Export visual hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh restyle export không đổi scope, dữ liệu, privacy hoặc persistence |
| **Scope** | Export presentation delta và callbacks tới controller/use case/repository/destination |
| **Source of truth for** | Hướng dẫn recursive logic audit; AD-20, BR-174…181 và UC-11 vẫn canonical |
| **Depends on** | `docs/prompt/card-export-visual-hierarchy/implementation.md`, export canonical docs, latest worktree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only first pass. Trace all/selected tới snapshot, encoder strategy và destination.
Fault-inject empty/stale/moved card, duplicate ids, encoder failure, share cancel, destination
failure, double submit và list mutation trong lúc sheet mở.

Chứng minh đúng sáu canonical fields, no localized headers, common tag codec, read-only
database, selection retained, no content/file name logging và temporary artifact policy.
Tìm business logic trong UI, duplicate codec/factory, repository bypass hoặc failure collapse.

Report reproduction/file/line/BR/fix/test trước sửa. Coordinator auto-fix logic, run changed
gate, reviewer re-read latest tree và lặp. Clean stop khi round-trip/no-mutation/failure
tests xanh, boundary đúng, full gate xanh. Reviewer không commit/push/merge.
