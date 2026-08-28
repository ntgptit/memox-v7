# Recursive architecture and logic review — post-merge integration

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập tái kiểm nghiệp vụ, persistence và dependency sau post-merge audit |
| **Scope** | Delta audit branch với `origin/main` và mọi consumer của mười feature hợp thành |
| **Source of truth for** | Hướng dẫn recursive architecture/logic review; không thay thế BR/AD/UC canonical |
| **Depends on** | `docs/prompt/post-merge-integration-audit/implementation.md`, canonical docs và latest worktree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Bạn là reviewer độc lập. First pass **audit-only**; không edit. Re-read latest
worktree, baseline, toàn diff và reverse consumers trước mỗi vòng.

## Bắt buộc kiểm

- Trace từng cross-feature scenario của implementation prompt từ BR/UC tới use case,
  repository, DAO/query, provider/controller và observable UI outcome.
- Chứng minh transaction, idempotency, rollback, stream invalidation, local clock,
  scheduler generation và persisted review/session labels.
- Tìm stale tombstone leakage, double-count, double-startup mutation, missing binding,
  raw route, feature-to-feature internal import, UI business logic và swallowed failure.
- Verify migration/snapshot/backfill/invariant từ mọi supported version; fresh schema
  và upgraded schema phải tương đương.
- Fault-inject stale entity, deleted target, repository failure, canceled navigation,
  resume sau reset và duplicate startup callback.

Mỗi finding phải có severity, reproduction, exact file/line, contract, fix và test.
Sau audit, coordinator auto-fix tuần tự trên latest tree, chạy changed gate, rồi reviewer
audit lại từ đầu. Không nới guard, đổi docs cho khớp bug hoặc xóa assertion.

Clean stop khi không còn P0/P1/P2, mọi failure path có typed handling, persistence
invariant xanh và full gate xanh. Worktree chỉ được commit/push/PR bởi coordinator;
reviewer không merge hay force-push.
