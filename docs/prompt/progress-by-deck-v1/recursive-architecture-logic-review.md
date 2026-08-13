# Recursive Architecture and Logic Review — Progress by Deck v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa attribution, hierarchy query, architecture và lifecycle của Progress by Deck |
| **Scope** | Canonical docs, domain/data/DI/controller/router và tests của drill-down theo deck |
| **Source of truth for** | Quy trình recursive architecture/logic review Progress by Deck v1 |
| **Depends on** | `docs/prompt/progress-by-deck-v1/implementation.md`, canonical branch docs và production Deck/Study code |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Đọc lại repo contract, canonical docs và toàn diff. Với `AUDIT_ONLY`, không edit
mà trả findings có reproduction, severity, file:line và fix boundary. Với
`APPLY_FIXES` hoặc standalone, thêm regression test, sửa trong scope, chạy checks
và lặp; không commit/push/PR/merge hoặc revert diff người khác.

Phải chứng minh: distinct card-day và exclusive partition đúng; root/deck dùng
hierarchy thật; move card/subtree reattributes toàn history theo current location;
Trash exclusion/restore/purge đúng; reset giữ activity; 7/30 boundaries dùng
injected clock/offset; query aggregate/bounded/no N+1; stable sort; live stream
invalidates bởi answers/cards/decks; read path không mutation; dependency flow
không cross-feature internals; route constants/docs đồng bộ.

Dùng real SQLite cho hierarchy/move/delete/restore/query-plan tests và fake
domain contract cho controller/widget. Không thêm deck snapshot lịch sử hay bảng
analytics để làm test dễ hơn. Chạy targeted tests và full host gate ở repair
pass; emulator deferred. Clean stop khi không còn P0/P1/P2, mọi invariant có
positive/negative test, docs/code thống nhất và báo cáo command results thật.
