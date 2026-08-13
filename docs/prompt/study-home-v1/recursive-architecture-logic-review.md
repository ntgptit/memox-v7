# Recursive Architecture and Logic Review — Study Home v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa session lifecycle, workload semantics và boundaries của Study Home |
| **Scope** | Docs, Study Home domain/data/DI/controller/router và regression tests |
| **Source of truth for** | Quy trình recursive architecture/logic review Study Home v1 |
| **Depends on** | `docs/prompt/study-home-v1/implementation.md`, canonical Study docs và production session code |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Đọc toàn diff và nguồn truth mới nhất. `AUDIT_ONLY` không edit; trả reproduction,
severity, file:line, violated contract và bounded fix. `APPLY_FIXES`/standalone
thêm failing test, sửa, rerun và lặp; không commit/push/PR/merge.

Chứng minh không còn production fixture; Resume không tạo/duplicate session;
stale/deleted/generation-invalid session bị loại đúng; workload aggregate root
subtree bằng scheduler eligibility thật; ordering overdue→due→new + stable ties;
không DB write trước explicit tap; double tap chỉ tạo một session; live streams
refresh sau session/answer/deck mutation; empty CTA route thật; dependency flow
không cross-feature data/presentation import; route constants và docs đồng bộ.

Reproduce trên real SQLite các root/depth/mixed workload/session cases; controller
tests dùng fake domain contract. Kiểm query count, transactions và no mutation.
Run targeted tests + full host gate ở repair pass; emulator deferred. Clean stop
khi không còn P0/P1/P2, invariants có negative tests và report không gọi gate
chưa chạy là pass.
