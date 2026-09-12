# Switch — đối chiếu component spec với `MxSwitchRow` đã triển khai

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract "Switch" (MemoX HTML design kit, mục D · Inputs & forms) với `MxSwitchRow` đã triển khai, và ghi lại rằng không có implementation gap — mọi giá trị trong dimension table/state matrix hoặc đã được thoả bởi hành vi hiện có, hoặc không đạt được qua bề mặt theme mà Flutter cho phép, và giá trị đang chạy là canonical M3 có đo lường |
| **Scope** | Đối chiếu dimension table + icon list + state matrix của prompt gốc với `mx_switch_row.dart` / `app_toggle_themes.dart` / `tokyo-component-mapping.md` / SDK Flutter đã ghim. Ngoài phạm vi: giá trị token gốc (AD-14), thay đổi bất kỳ hợp đồng đóng băng nào (việc của một task design-system riêng, xem §5) |
| **Source of truth for** | Kết quả đối chiếu spec Switch (kit) ↔ implementation; điểm nào của spec gốc — kể cả không đánh dấu [INFERRED] — khớp, không đạt được, hoặc lệch với giá trị thật đang chạy, và vì sao |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/v1-freeze.md` · `design-system/tokyo-component-mapping.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-12 |

---

## 0. Tài liệu này là gì, và không phải là gì

Nguồn: MemoX HTML design kit, mục *D · Inputs & forms*. Kit đã bị xoá ở
M100.83 (#541) — spec gốc (nguyên văn ở §1) là bản ghi duy nhất còn lại của
mục này, cùng tình trạng với Card (`card-spec.md` §0).

**Đây không phải một implementation task.** `MxSwitchRow` đã qua ba milestone
chỉnh riêng cho màu (M100.18, M100.22, M100.23) cộng một milestone chỉnh
semantics (A20.1 P2-13, gỡ variant thứ hai từng gây double-announce ở A19-19)
— tất cả **trước khi** spec này được viết. Mỗi slot của `buildSwitchTheme` đã
được guard ở mức AST (`m3_role_bindings.dart`), không chỉ giữ bằng test hành
vi. Tài liệu này đối chiếu spec với code thật, không đề xuất thay đổi nào.

File đã đọc để đối chiếu: `mx_switch_row.dart`, `mx_switch_row_test.dart`,
`app_toggle_themes.dart`, `app_toggle_themes_test.dart`, `m3_role_bindings.dart`,
`form_components.dart` (Widgetbook), cộng `switch.dart` / `switch_theme.dart`
của Flutter SDK đã ghim (3.44.8) — theo đúng phương pháp "trích từ SDK, không
chép tay" của `tokyo-component-mapping.md` §1.

## 1. Hợp đồng component (nguyên văn từ prompt gốc — binding)

| Dimension | Class | Giá trị gốc |
|---|---|---|
| track | FIXED | 44×26 |
| thumb | FIXED | 20 |
| on / off / disabled | CONTENT-DRIVEN | — (không mang giá trị; xem dòng cuối §2) |

Icons: none. State matrix gốc: off = fill `surfaceContainerHighest`, thumb
`surfaceBright` tại inset trái 3, shadow-soft trên thumb; on = fill `primary`,
**cùng** thumb `surfaceBright` trượt sang trái 21, chuyển động 160ms
ease-standard trên cả màu track lẫn vị trí thumb; disabled = 0.38
(`--memox-op-disabled`) trên toàn control, tắt pointer events **[INFERRED —
mock không có switch disabled trên màn hình thật]**.

## 2. Đối chiếu — từng dimension

| Yêu cầu | Trong `MxSwitchRow` hôm nay | Bằng chứng |
|---|---|---|
| track 44×26 FIXED | không đạt được qua `SwitchThemeData` — lớp này có đúng 10 field (`thumbColor`, `trackColor`, `trackOutlineColor`, `trackOutlineWidth`, `materialTapTargetSize`, `mouseCursor`, `overlayColor`, `splashRadius`, `thumbIcon`, `padding`), không field nào là kích thước track. SDK ghim vẽ track M3 canonical **52×32** bất kể theme | `switch_theme.dart` (danh sách field đầy đủ); `switch.dart:2375,2378` — `_SwitchConfigM3.trackHeight => 32.0`, `.trackWidth => 52.0` |
| thumb 20 FIXED | cùng lý do — không field kích thước thumb; M3 canonical còn đổi size thumb theo state (selected/pressed) thay vì một hằng số | `switch.dart:1569-1640` — `thumbSizeAnimation`, `thumbSize` tính theo `WidgetState` |
| off: track `surfaceContainerHighest` | khớp — `trackColor` trả `scheme.surfaceContainerHighest` khi không `selected`/`disabled` | [app_toggle_themes.dart:94](../../lib/core/theme/components/selection/app_toggle_themes.dart:94) |
| on: track `primary` | khớp — `trackColor` trả `scheme.primary` khi `selected` | [app_toggle_themes.dart:92](../../lib/core/theme/components/selection/app_toggle_themes.dart:92) |
| thumb `surfaceBright` cố định cả hai state | **không khớp, giữ nguyên giá trị hiện tại** — xem §3 |
| motion 160ms ease-standard | không đạt được qua theme — không field duration/curve trong `SwitchThemeData`. SDK ghim chạy `_SwitchConfigM3.toggleDuration = 300` (ms), cố định trong widget | `switch.dart:954` (`positionController.duration = Duration(milliseconds: switchConfig.toggleDuration)`); `switch.dart:2386` |
| track outline | spec không nhắc; M3 canonical vẽ `outline` (off) / trong suốt (on) — slot mà mock đơn giản của kit không có nhưng SDK luôn vẽ | [app_toggle_themes.dart:107-112](../../lib/core/theme/components/selection/app_toggle_themes.dart:107); guard [m3_role_bindings.dart:301-312](../../test/core/theme/contracts/m3_role_bindings.dart:301) |
| icons: none | khớp — `buildSwitchTheme` không set `thumbIcon`; `MxSwitchRow` không tự vẽ glyph nào | [app_toggle_themes.dart:70-121](../../lib/core/theme/components/selection/app_toggle_themes.dart:70) (không dòng `thumbIcon:`) |
| hit target | `SwitchListTile` dựng trên `ListTile` nên kế thừa `minTileHeight` = `AppSizing.rowMinHeight` (56dp) cho cả hàng — target là cả hàng, không riêng glyph switch — vượt sàn 48dp của hợp đồng đóng băng #7 | `tokyo-component-mapping.md:111`; bốn `*_accessibility_sweep_test` (`v1-freeze.md` §2 dòng 7) |
| dòng on/off/disabled CONTENT-DRIVEN, giá trị "—" | không mang giá trị để đối chiếu — đọc như boilerplate của template chung cho cả lô prompt (component không có nội dung text/icon để lớp CONTENT-DRIVEN áp lên), cùng loại nhận xét ở `card-spec.md` §2 dòng cuối |

## 3. Màu thumb — vì sao giữ nguyên, không theo spec

Đây không phải một điểm suy luận của spec — spec ghi thẳng `surfaceBright`,
không đánh dấu [INFERRED]. Nhưng giá trị đang chạy khác, có chủ đích, và được
canh ở ba lớp:

| | |
|---|---|
| Spec (kit) | `surfaceBright`, **hằng số** cho cả off và on |
| Code thật | `outline` khi off, `onPrimary` khi selected — đổi theo state | [app_toggle_themes.dart:71-89](../../lib/core/theme/components/selection/app_toggle_themes.dart:71) |
| Canonical M3 | `_SwitchDefaultsM3.thumbColor` — đúng cặp `outline`/`onPrimary` app đang dùng, theo comment tại chính file theme | [app_toggle_themes.dart:37](../../lib/core/theme/components/selection/app_toggle_themes.dart:37) |
| Guard | `m3_role_bindings.dart` yêu cầu đúng `['outline', 'onPrimary']`, **từ chối** `onSurfaceVariant` | [m3_role_bindings.dart:278-289](../../test/core/theme/contracts/m3_role_bindings.dart:278) |

Giá trị hằng số của kit sẽ xoá mất kênh trạng thái duy nhất của một switch —
trên chính switch, **thumb chính là trạng thái** ([app_toggle_themes.dart:47-52](../../lib/core/theme/components/selection/app_toggle_themes.dart:47)).
Giá trị đang chạy còn mang lịch sử đo tương phản thật: `outline` trên
`surfaceContainerHighest` từng đo 2.79:1 (light) / 2.54:1 (dark), dưới sàn 3:1
của WCAG 1.4.11 — M100.22 sửa bằng cách dời **role màu**
(`AppBorderColors.borderControlLight/Dark`) chứ không đổi ánh xạ component.
M100.83 (Tokyo palette) đổi lại hex của cả hai token này; tính lại bằng đúng
công thức WCAG trên cặp hex hiện tại (`borderControlLight` `#787C87` /
`surfaceContainerHighestLight` `#DCDDE6`; `borderControlDark` `#ACADBA` /
`surfaceContainerHighestDark` = `surfaceEmphasisDark` `#585A66`) ra
**3.09:1 (light) / 3.08:1 (dark)** — vẫn trên sàn 3:1, nhưng biên độ mỏng hơn
con số M100.22, nhất là ở light. **Con số này hiện không được gate giữ**: bài
test đúng cặp này (`app_toggle_themes_test.dart:66-97`, nhãn `TOKYO-2`) bị
comment nguyên khối ở M100.84 kèm `// TODO(M100.84): colour gate off for the
Tokyo palette swap — re-enable`, cùng đợt palette đổi — nên 3.09:1/3.08:1 ở
đây là số tính tay cho tài liệu này, không phải một khẳng định đang được CI
xác nhận. Việc re-enable gate đó đã tự ghi số hiệu (`TOKYO-2`) trong chính
test file; không phải việc audit Switch này mở thêm.

Theo đúng thứ tự ưu tiên của `tokyo-component-mapping.md` §1 — *canonical M3
role > accessibility > MemoX structural system > Tokyo exact hex* — giá trị
kit đứng cuối bảng và thua ở cả ba bậc trên. Đổi thumb thành hằng số sẽ là
"thay role ngữ nghĩa bằng role khác", đúng thứ hợp đồng đóng băng #2 của
`v1-freeze.md` cấm (guard `color_scheme_arguments_are_m3_roles`,
`color_scheme_reads_are_m3_roles`, `no_raw_color`) — việc này **MUST** đi qua
một task design-system riêng theo §3 điều kiện 6 (chủ dự án chỉ định kèm tham
chiếu thị giác cụ thể), không phải một suy luận từ prompt kit đã xoá.

## 4. Điểm [INFERRED] — disabled state, và vì sao không sửa theo

Giá trị thật đang chạy: mỗi slot có giá trị disabled riêng, đo tương phản
thật, không phải một alpha 0.38 phủ lên toàn control.

| | |
|---|---|
| Spec [INFERRED] | 0.38 (`--memox-op-disabled`) trên toàn control, tắt pointer events |
| Code thật | `thumbColor` disabled → `semantic.onDisabled`; `trackColor` disabled → `semantic.disabledSurface`; `trackOutlineColor` disabled → `semantic.onDisabled`; đo lại ở M100.36: **2.05:1 (light) / 2.51:1 (dark)** trên track đã tắt | [app_toggle_themes.dart:85,91,109](../../lib/core/theme/components/selection/app_toggle_themes.dart:85) |
| Pointer events | `onChanged` kiểu `ValueChanged<bool>?` — `null` khoá control qua chính API Dart, không cần cờ riêng | [mx_switch_row.dart:29-30](../../lib/shared/widgets/mx_switch_row.dart:29) |

WCAG 1.4.11 miễn control bất hoạt khỏi sàn 3:1 — yêu cầu thật là *nhìn thấy
được*, không phải *3:1* — và một alpha 0.38 phẳng trên hai nền khác nhau
(`surfaceContainerHighest` sáng, `primary` đậm) không đảm bảo điều đó bằng một
giá trị đã đo riêng cho từng nền. Đây cũng là bài học app từng trả giá: thumb
disabled từng dùng `disabledSurface` — trùng giá trị track — làm cả control
thành một khối, xoá mất trạng thái on/off đúng lúc người dùng không đổi được
nó.

`mx_switch_row_test.dart` đã pin `isEnabled == false` khi `onChanged: null`
("a null handler disables the row and says so"). Không test hay guard nào
giữ riêng con số 0.38 vì code thật không dùng một alpha phẳng — cùng dạng
với `card-spec.md` §3.

Use case `MxSwitchRow` trong Widgetbook (`form_components.dart:639-649`)
khoá cứng `onChanged`, không có knob bật/tắt disabled. Trạng thái disabled
của cùng theme này vẫn xem được — qua use case liền kề `Switch and Checkbox`
(`form_components.dart:705-758`, raw `Switch`/`Checkbox` xếp ma trận
on/off × enabled/disabled, đúng nơi comment đầu file giải thích quyết định
thumb/track outline) — chỉ là không đi qua chính composition `MxSwitchRow`.

## 5. Kết luận

Không có task implement.

Track/thumb geometry và thời lượng chuyển động không đạt được qua
`SwitchThemeData` — lớp theme của Flutter cho control này không có field kích
thước hay duration/curve nào, nên đây không phải một gap có thể sửa bằng
theme. Đạt đúng 44×26/20/160ms sẽ cần từ bỏ `Switch`/`SwitchListTile` canonical
của SDK để dựng một control tự vẽ — một quyết định thêm một họ primitive mới
(điều kiện mở lại #3 của `v1-freeze.md` §3), không phải việc một task đối
chiếu component tự quyết.

Màu track khớp kit 100%. Màu thumb và track outline giữ nguyên giá trị M3
canonical đang chạy, guard-pinned, có lịch sử đo tương phản ba milestone
(M100.18, M100.22, M100.23) — kit thua ở mọi bậc trong thứ tự ưu tiên của
`tokyo-component-mapping.md` §1. Disabled state đã có giá trị đo riêng cho
từng slot, chính xác hơn suy luận 0.38 phẳng của spec. Danh sách "không copy
literal" của prompt gốc (absolute positioning, `::after`, `backdrop-filter`,
color-mix, hover-only, fake chrome, hộp pixel cố định) không xuất hiện ở
`mx_switch_row.dart` / `app_toggle_themes.dart` — API đóng, `MxSwitchRow` chỉ
nhận `label`, `isOn`, `onChanged`, không tham số màu/kích thước nào lộ ra
feature.

Nếu sau này chủ dự án muốn đổi thật giá trị nào ở §3 hoặc §4 (ví dụ một thumb
đơn sắc theo hình ảnh cụ thể), đó là điều kiện mở lại #6 của `v1-freeze.md`
§3 — không phải việc một task component tự suy ra từ prompt kit đã xoá.
