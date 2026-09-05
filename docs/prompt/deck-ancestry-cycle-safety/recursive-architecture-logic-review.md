# Recursive architecture and logic review — Deck ancestry cycle safety

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập kiểm termination, domain-bound ownership và read-model parity của Deck ancestry fix |
| **Scope** | Delta ancestry branch, reverse consumers của `childDeckLevel` và SQLite tests |
| **Source of truth for** | Hướng dẫn recursive data/logic review; không thay BR/AD canonical |
| **Depends on** | `docs/prompt/deck-ancestry-cycle-safety/implementation.md`, canonical Deck docs, latest worktree |
| **Updated by task** | Terra bounded-data campaign |
| **Last updated** | 2026-08-28 |

---

Pass đầu audit-only. Trace parameter từ domain constant tới DAO/generated query và SQL.
Chứng minh legal depth không off-by-one; cycle/over-depth bounded; `branch` walk vẫn
cycle-safe; mapper không nhận duplicate/invented ancestor; one-statement snapshot của
AD-13 không bị tách thành query thứ hai.

Reproduce trên SQLite thật, đo query sau cycle vẫn chạy, fault-inject bỏ bound và đổi
`<`/`<=`. Audit schema version/migration không đổi, generated code không bị commit và
không business logic lọt presentation.

Finding phải có severity, reproduction, file/line, violated contract, fix và test.
Coordinator auto-fix rồi chạy changed gate; reviewer re-read và lặp. Clean stop khi
không P0/P1/P2, termination và legal parity đều có evidence, full gate xanh.
