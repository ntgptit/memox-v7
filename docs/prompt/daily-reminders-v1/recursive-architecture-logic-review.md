# Recursive Architecture and Logic Review — Daily Reminders v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa scheduling, permission, privacy, due aggregation và platform boundaries của Daily Reminders |
| **Scope** | Docs/settings/domain/data/device/DI/bootstrap/deep-link/tests của reminder v1 |
| **Source of truth for** | Quy trình recursive architecture/logic review Daily Reminders v1 |
| **Depends on** | `docs/prompt/daily-reminders-v1/implementation.md`, canonical privacy/Study/Settings contracts |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

`AUDIT_ONLY` không edit; reproduce findings với severity/file:line/scenario.
`APPLY_FIXES`/standalone thêm regression test, sửa và lặp. Không commit/PR/merge.

Chứng minh default off/20:00; permission chỉ sau opt-in; denial không để enabled
ảo; due+overdue only, no new, no double-count; deterministic urgency; one
notification/day; fire-time stale recheck; enable/time/timezone/reboot/app-update
reschedule idempotent; disable cancels; tap opens Study Home không auto-session;
no exact-alarm permission; Web safe adapter; plugin types không lọt domain/UI;
notification/log không chứa card content; platform failures typed/retryable.

Test clock/offset/platform injectably, workload trên SQLite thật và bootstrap
idempotency. Inspect Android manifests cả flavors. Run targeted/full host gate in
repair; device smoke deferred. Clean stop khi không P0/P1/P2 và evidence phân
biệt host verified với device deferred.
