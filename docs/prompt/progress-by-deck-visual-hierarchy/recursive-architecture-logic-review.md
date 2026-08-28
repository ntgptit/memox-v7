# Recursive Architecture and Logic Review — Progress by Deck Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập và auto-fix regression kiến trúc/nghiệp vụ sau restyle Progress by Deck |
| **Scope** | Progress level presentation/composition/navigation/tests; không mở rộng analytics |
| **Source of truth for** | Quy trình recursive architecture/logic review của Progress by Deck visual hierarchy |
| **Depends on** | `implementation.md`, BR-182…BR-189, UC-13, M99 Progress by Deck và production tests |
| **Updated by task** | Progress by Deck visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Audit diff từ đầu sau implementation:

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: tái hiện và lập
inventory trước khi sửa. Không revert ngoài scope, không commit/push/PR/merge.
Sau inventory mới auto-fix, chạy verification/tests sau mỗi batch và recursive
audit lại từ đầu.

1. Không domain/data/SQL/repository/clock/route mutation trong restyle.
2. Reproduce 7/30 snapshot, four metrics, Learning priority, subtree/current-
   location attribution, zero rows/sort, trash/delete/move live effects.
3. Range switch không query/loading; open/scroll/back không write.
4. Drill-down dùng push stack, deep-link/deck-missing/back recovery giữ nguyên.
5. Top-level Overview composition không duplicate provider/query/scroll.
6. State/controller ownership, typed failures, l10n, shared components, no raw
   policy widget/hardcoded token/private log.
7. Thêm regression test trước auto-fix; chạy targeted + changed gate.

Findings phải có severity/scenario/expected/actual/file/BR. Auto-fix P0→P2,
re-read diff và lặp tới **clean stop** khi không finding, all states xanh, metrics/navigation/read-
only unchanged và changed gate pass. Không update golden/gallery/PR; emulator
`not run — presentation-only`.
