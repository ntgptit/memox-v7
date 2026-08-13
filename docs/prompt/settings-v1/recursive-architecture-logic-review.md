# Recursive Architecture and Logic Review — Settings v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa persistence, override precedence, session immutability và app wiring của Settings |
| **Scope** | Docs/schema/migration/domain/data/DI/bootstrap/controller/router/tests của Settings v1 |
| **Source of truth for** | Quy trình recursive architecture/logic review Settings v1 |
| **Depends on** | `docs/prompt/settings-v1/implementation.md`, canonical settings docs và production Study options flow |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Review latest production diff. `AUDIT_ONLY` không edit; `APPLY_FIXES`/standalone
reproduce bằng failing test, sửa và lặp. Không commit/push/PR/merge.

Chứng minh singleton typed persistence; migration/rollback/schema snapshot đầy
đủ; global→root override precedence đúng; clear override không reset learning;
running sessions bất biến; future sessions nhận new defaults; System theme/locale
resolution và restart persistence đúng; no provider-memory second truth; no
repository/Drift trong UI; bootstrap không dependency cycle; stream updates không
write loop; typed failure/double-submit/draft retention; routes/docs/ARB parity.

Dùng real SQLite cho migration/transaction/override/session tests và app/widget
fakes đúng domain boundary. Kiểm no generated edits và no unrelated reminder
scope. Chạy targeted + full host gate ở repair pass; emulator deferred. Clean
stop khi không P0/P1/P2, mọi invariant có negative test và report commands thật.
