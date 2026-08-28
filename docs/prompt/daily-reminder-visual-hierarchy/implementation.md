# Upgrade Daily Reminder — Card Detail Visual Language

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc nâng cấp Daily Reminder thành màn cài đặt compact, rõ trạng thái và nhất quán với Card Detail |
| **Scope** | Reminder Settings route, toggle/time/error/supporting surfaces, time picker visual integration, tests/goldens/gallery; không đổi scheduling/platform logic |
| **Source of truth for** | Hướng dẫn thực thi Daily Reminder visual hierarchy; nghiệp vụ vẫn thuộc BR-218…BR-229, UC-17 và M6 Daily Reminders |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-218…BR-229, UC-17, `docs/wireframes/m6-daily-reminders.md`, production Card Detail và MemoX design tokens |
| **Updated by task** | Daily Reminder visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Restyle production **Daily Reminder** route. Không đổi opt-in/default time,
permission/capability/schedule/cancel/retry semantics, due-only workload,
notification privacy/copy, platform adapters, bootstrap hoặc deep link.

## Pre-flight và 5Why

Đọc repo contract, BR-218…BR-229, UC-17, M6, screen/widgets/tests/goldens hiện
tại, Card Detail và shared setting/switch/list/dialog components. Lập reduced UI
Contract/widget tree; kiểm branch/base/dirty state. Không commit/push/PR trong
implementation phase.

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Màn hiện là một card lớn và hai đoạn chữ trôi, nên trạng thái và giải thích tách rời. | Tạo compact schedule panel + supporting info band cùng một reading column. |
| 2 | Toggle và time row thiếu hierarchy nhưng là hai phần của một quyết định. | Giữ cùng surface, divider subtle; toggle primary, time subordinate. |
| 3 | Error banner xuất hiện làm màn có thêm một loại card cạnh tranh. | Dùng in-flow semantic status band, cùng edges và tone tập trung. |
| 4 | Disabled/time/busy dễ chỉ phân biệt bằng màu. | Dùng text, icon, semantics và stable geometry; màu chỉ cue. |
| 5 | Restyle dễ phá retry đúng command hoặc permission timing. | Không đổi controllers/platform; review đầy đủ S1…S11 và command ownership. |

## Visual thesis và widget tree

```text
MxContentShell (back preserved)
└─ centered max-width column
   ├─ section label / optional concise intro
   ├─ Schedule MxCard
   │  ├─ reminder toggle row
   │  ├─ subtle divider
   │  └─ reminder time row
   ├─ conditional in-flow status band
   └─ quiet privacy/due-only information panel
```

- Flat/subtle surfaces như Card Detail; không giant title/body, no shadow stack.
- Compact typography; icon wells cho bell/time/info/error dùng semantic roles.
- Một schedule surface duy nhất. Không tách toggle/time thành hai cards.
- Supporting copy có thể nằm trong one muted info panel để đọc như một contract,
  không hai paragraph trôi; giữ nguyên nghĩa/copy M6.

## Schedule panel

- Toggle row label trái, switch phải, stable center alignment và ≥48dp.
- Time row xếp dọc label + localized time theo M6; luôn hiện, disabled khi off/
  unsupported/busy, không ẩn gây layout shift.
- Row time mở approved shared picker; dialog giữ safe area/theme/locale. Không
  tạo raw picker wrapper chỉ để đổi style.
- S2→S3→S4 không đổi card height; switch không optimistic-toggle trước success.

## Status/error và supporting info

- Giữ typed faces permission denied, unavailable, schedule/settings/cancel error,
  retry đúng command, read-error full body.
- In-flow band chung edges với schedule/info, icon + text + action trái theo M6;
  no snackbar, no saturated full-width danger card.
- Unsupported không có CTA giả. Banner liveRegion, retry target ≥48dp.
- Due-only và lock-screen disclosure luôn hiện, không chứa card content/tag/history.

## Files dự kiến

- `lib/features/reminder/presentation/screens/reminder_settings_screen.dart`
- `presentation/widgets/sections/reminder_settings_section_widget.dart`,
  `reminder_banner_section_widget.dart`
- `presentation/widgets/items/reminder_toggle_row_widget.dart`,
  `reminder_time_row_widget.dart`
- time picker overlay chỉ khi style integration thật sự cần
- append visual revision vào M6, cập nhật `docs/wbs.md`
- tests/goldens/Widgetbook/visual audit; ARB chỉ khi thiếu semantic key.

## Không được thay đổi

- BR-218…BR-229, UC-17, off/20:00, permission only after explicit enable.
- Due-only fire-time recheck, notification privacy/copy/order/id/deep link.
- Three command controllers, retry dispatch, rollback, scheduling/platform/
  manifest/bootstrap/data/domain/schema.
- Settings-to-Reminder seam, route/back/bottom-nav.

## Tests bắt buộc

- Regression S1…S11: loading/off/enabling/on/picker/permission/unavailable/
  schedule/settings/cancel/read errors and each retry command.
- `getRect`: schedule/status/info shared edges; toggle center; time label/value
  shared left; rows ≥48; card height stable S2→S4; banner pushes info, no overlay;
  bottom clearance at 320×568.
- 320dp @2.0, 393dp, 412dp; EN/VI; light/dark; 12/24-hour locales; long error;
  keyboard not relevant, picker safe-area relevant.
- Semantics switch has label+value on same node, disabled time leaves focus order,
  localized time read once, banner liveRegion, no color-only status.
- Render/inspect all principal faces and time picker.

## Verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Không chạy emulator notification/IT cho restyle; báo `not run — presentation-
only restyle`. Clean stop khi host gate/state/geometry/a11y pass, platform/domain/
data untouched và worktree sẵn sàng reviews. Coordinator xử lý gallery/PR.
