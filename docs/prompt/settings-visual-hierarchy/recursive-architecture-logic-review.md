# Recursive Architecture and Logic Review — Settings Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập và auto-fix regression nghiệp vụ/kiến trúc sau restyle Settings |
| **Scope** | Settings presentation/form state/action wiring/tests; không mở rộng settings data model |
| **Source of truth for** | Quy trình recursive architecture/logic review của Settings visual hierarchy |
| **Depends on** | `implementation.md`, BR-210…BR-217, UC-16, M99 Settings và production tests |
| **Updated by task** | Settings visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Audit worktree độc lập:

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: tái hiện và lập
inventory trước khi sửa. Không revert ngoài scope, không commit/push/PR/merge.
Sau inventory mới auto-fix; chạy verification/tests sau mỗi batch và recursive
audit lại từ đầu.

1. Diff không đổi domain/data/repository/schema/router/bindings.
2. Reproduce one-snapshot load/read error; study draft pristine/dirty/invalid/
   saving/failure; theme/language success/failure; reset cancel/success/failure.
3. Chứng minh Save enablement chỉ presentation-derived, không auto-save hoặc
   write khi mở; failed write giữ persisted truth và draft đúng BR-216.
4. Theme/language apply ngay không rebuild router/lose scroll; only failed group
   locks; reset không đụng deck/study state.
5. Reminder entry không import/watch Reminder presentation/data.
6. Audit state/controller ownership, l10n, typed failures, raw Material policy
   widgets, trivial wrapper, hardcoded token và swallowed errors.
7. Thêm regression test trước fix; chạy targeted + changed gate.

Ghi P0/P1/P2 với scenario/expected/actual/file/BR; auto-fix, re-read và lặp đến
clean. Không nới rule, không update golden/gallery/PR. Clean stop khi không
finding, all state tests + changed gate xanh, emulator `not run — presentation-only`.
