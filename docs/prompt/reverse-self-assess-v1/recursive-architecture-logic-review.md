# Recursive Architecture and Logic Review — Reverse Self-assess v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa eligibility, persisted direction, scheduler isolation và migrations của Reverse Self-assess |
| **Scope** | Study docs/domain/data/migration/factory/controller/history và tests liên quan direction |
| **Source of truth for** | Quy trình recursive architecture/logic review Reverse Self-assess v1 |
| **Depends on** | `docs/prompt/reverse-self-assess-v1/implementation.md`, canonical Study rules và production schedulers |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

`AUDIT_ONLY` chỉ reproduce/report; `APPLY_FIXES`/standalone thêm regression test,
sửa và lặp trên latest diff. Không commit/push/PR/merge.

Chứng minh feature không reachable với eight-box/learning/non-self-assess;
Front/Back không mutation; session choice khóa đúng lúc; Mixed actual direction
materialize một lần bằng injected randomness và bền qua retry/comeback/resume/
restart; session/queue/history direction explicit; migration old rows an toàn;
SM-2 action/due/ease/interval byte-equivalent với baseline; stale generation và
rollback không để partial direction; factory dispatch exhaustive, không business
logic trong UI/controller; no private content logging.

Dùng real SQLite/migration snapshots và deterministic fake randomness. Test cả
negative reachability của eight-box. Run targeted + full host gate ở repair;
emulator deferred. Clean stop khi không P0/P1/P2, invariants có tests và report
commands thật.
