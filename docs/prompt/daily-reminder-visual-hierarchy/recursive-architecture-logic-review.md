# Recursive Architecture and Logic Review — Daily Reminder Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập và auto-fix regression nghiệp vụ/kiến trúc sau restyle Daily Reminder |
| **Scope** | Reminder Settings presentation/action wiring/tests; không đổi platform scheduling implementation |
| **Source of truth for** | Quy trình recursive architecture/logic review của Daily Reminder visual hierarchy |
| **Depends on** | `implementation.md`, BR-218…BR-229, UC-17, M6 và production tests |
| **Updated by task** | Daily Reminder visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Audit độc lập worktree mới nhất:

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: tái hiện và lập
inventory trước khi sửa. Không revert ngoài scope, không commit/push/PR/merge.
Sau inventory mới auto-fix, chạy verification/tests sau mỗi batch và recursive
audit lại từ đầu.

1. Diff không được chạm domain/data/platform/manifest/bootstrap/schema/router.
2. Reproduce S1…S11 và chứng minh each retry chạy đúng failed command.
3. Enabling chỉ xin quyền sau tap; failure giữ off/no schedule; switch không
   optimistic; time failure rollback nhưng giữ draft cho retry.
4. Disable/cancel error copy/state đúng; unavailable toggle disabled/no fake CTA.
5. Mở/scroll/picker cancel không mutation study; notification privacy/deep-link
   behavior và command controller ownership không đổi.
6. Audit l10n, typed failures, no private logs, no platform type in presentation/
   domain, no raw policy widget/hardcoded token.
7. Thêm regression test trước fix; chạy targeted + changed gate.

Findings P0/P1/P2 phải có scenario/expected/actual/file/BR. Auto-fix tuần tự,
re-read/lặp đến clean; không đổi BR để hợp thức hoá code. Không update golden/
gallery/PR. Clean stop khi all faces pass, diff presentation-only, changed gate
xanh, emulator `not run — presentation-only`.
