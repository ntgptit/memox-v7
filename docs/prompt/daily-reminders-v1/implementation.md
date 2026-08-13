# Implement Daily Reminders v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc triển khai nhắc học hằng ngày Android từ due workload thật |
| **Scope** | Một notification summary tùy chọn, default off/20:00 local, tap mở Study Home; không gồm account, sync hoặc new-card reminder |
| **Source of truth for** | Hướng dẫn thực thi Daily Reminders v1; nghiệp vụ chính thức thuộc BR/UC/AD/data model/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, Settings/Study workload contracts, Android notification lifecycle và privacy contract |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Daily Reminders v1** trong worktree riêng. Android là release target;
Web phải build và degrade an toàn. Không dùng exact-alarm permission nếu chưa có
product requirement bắt buộc.

## Pre-flight và 5Why

Đọc repo/docs, privacy rules, app lifecycle/bootstrap, Study due queries,
Settings persistence, router/deep-link tests, Android manifests/flavors và
dependency constraints. Kiểm branch/status/base. Viết 5Why về opt-in, due-only,
one summary, inexact scheduling và notification privacy. Implementation không
commit/push/PR/merge trước reviews.

## Docs và nghiệp vụ

Append BR/UC/WBS, architecture/device-service decision nếu thật sự mới, data
model/migration docs và reminder wireframe. Canonicalize:

1. Reminder default **off**; default suggested time 20:00 local. Không xin
   permission trước khi user bật.
2. Notification chỉ tồn tại khi tổng overdue+due-today > 0. New cards không làm
   phát notification.
3. Một notification summary mỗi ngày. Copy được phép hiện most-urgent deck name,
   total due count và số deck còn lại trên lock screen theo quyết định privacy
   đã chốt; không hiện card content/tags/history.
4. Most urgent sort: overdue count giảm dần, then max overdue age giảm dần, due
   today giảm dần, stable deck name/ID. Tổng count không double-count card qua
   ancestor/descendant; notification dùng studyable root aggregation đã chốt.
5. Tap notification mở `/study`/Study Home bằng route/deep-link contract, không
   auto-start session.
6. Scheduling theo local wall time hiện tại, reschedule khi enable/time đổi,
   timezone/offset đổi, reboot/app update nếu platform cần, và cancel khi disable.
   Dùng inexact OS scheduling phù hợp; không request exact alarm.
7. Android 13+ permission denial là typed, recoverable state; settings vẫn off
   nếu enable không hoàn tất. Không spam prompt hoặc lặp schedule.
8. Khi fire-time đến mà không còn due, worker/service bỏ notification. Dismiss
   không mutation study state.
9. Web/iOS unsupported adapter trả capability rõ, không crash/import `dart:io`
   vào presentation/domain.

## Architecture và UI

- Domain: reminder settings/schedule/summary models, repository/platform
  contracts và focused use cases. Không plugin types/Flutter platform checks.
- Data/device: typed settings trong DB, workload reader qua domain seam, Android
  notification adapter và scheduler. Chọn plugin version tương thích repo sau
  kiểm chứng official docs; không tự viết channel khi plugin đáp ứng.
- DI/bootstrap sở hữu initialization/reschedule, idempotent và testable bằng
  injected clock/offset. Không query DB hoặc schedule trong widget.
- Settings UI thêm Reminder section: toggle, time picker, permission/capability
  state, supporting copy due-only và lock-screen disclosure. Không trộn vào
  Settings implementation nếu branch đó chưa merge: giữ seam/rebase notes rõ.
- All user copy EN/VI, Mx/tokens. States off, enabling, on, time change,
  permission denied, platform unavailable, schedule failure và retry.

Wireframe pin section/card edges, toggle/time baselines, error placement, dialog
safe area và bottom navigation. Kiểm themes/locales/320@2x/390/412.

## Tests và clean stop

Domain tests summary/count/sort/privacy copy inputs, due boundaries and no-new.
Real SQLite tests workload aggregation and no mutation. Adapter/service tests
enable/disable/reschedule/timezone/reboot hooks, permission branches, stale due
at fire, idempotency, typed failures and Web safe fallback. Widget/router tests
permission flow/time picker/tap deep link/semantics/viewports; Android manifest
and flavor configuration tests where repo pattern supports them.

Use fake platform adapter for host tests; never send real notification in unit
suite. Run targeted host gate; emulator/device notification smoke deferred to
integration worktree and reported not run. Stop when docs/privacy/code/tests
agree, no exact-alarm permission, no content logging, no P0/P1/P2/TODO and
handoff records native/schema/bootstrap/shared conflicts.
