# Recursive architecture and logic review — Deck write and move

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit invariant cây, scheduler và transaction sau UX hardening deck |
| **Scope** | Deck form/move callbacks, use cases, repositories, DAOs và affected aggregate streams |
| **Source of truth for** | Hướng dẫn recursive logic review; canonical deck BR/AD/UC vẫn quyết định hành vi |
| **Depends on** | `docs/prompt/deck-write-move-ux-hardening/implementation.md`, `lib/features/deck/README.md`, latest worktree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only trước. Fault-inject depth 10, self/descendant target, stale target, incompatible
content type, different scheduler/generation, last child moved, DB failure giữa transaction,
double submit và stream refresh. Chứng minh root resolution dùng `root_deck_id`, parent
content type reset/set atomically và no partial mutation.

Tìm validation duplicate ở UI, controller gọi repository trực tiếp, check ngoài transaction,
raw clock/route, swallowed typed failure và aggregate stale. Mỗi finding phải có reproduction,
file/line, BR/AD, fix và test.

Coordinator auto-fix architecture trước, chạy changed gate, reviewer re-read latest tree
và lặp. Không nới rule/migration hay đổi docs để xanh. Clean stop khi invariant và rollback
có database-backed evidence, dependency đúng, full gate xanh. Reviewer không commit/push/merge.
