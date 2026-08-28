# Recursive architecture and logic review — Study Entry and Session Result

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh restyle không đổi Study lifecycle, scheduler action hoặc persistence |
| **Scope** | Entry/result presentation delta, controllers, callbacks và affected Study consumers |
| **Source of truth for** | Hướng dẫn recursive logic audit; Study BR/UC/scheduler docs vẫn canonical |
| **Depends on** | `docs/prompt/study-entry-session-result-visual-hierarchy/implementation.md`, `docs/wbs-study.md`, latest worktree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

First pass **audit-only**. Trace Start, Resume, option change, back, finish, retry và next
action tới use case/repository/DAO. Tái hiện eight-box và SM-2; new/due mix; stale
generation; write failure; double tap; leave race; completed/abandoned result.

Tìm UI tự suy luận review kind/end reason, hardcode action set, tạo session hai lần,
commit answer sau feedback sai thứ tự, mất persisted direction hoặc map failure thành copy
sai. Restyle MUST NOT mutation database/query/scheduler.

Report severity/reproduction/file/contract/fix/test trước khi sửa. Coordinator auto-fix
logic tuần tự, chạy changed gate, reviewer re-read latest tree và lặp. Clean stop khi
state transition, idempotency, failure/rollback và dependency boundary có evidence;
full gate xanh. Reviewer không commit/push/merge.
