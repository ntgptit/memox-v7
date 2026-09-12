# IconButton — đối chiếu component spec với `MxIconButton` đã triển khai

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract "IconButton" (MemoX HTML design kit, mục B · Buttons & actions) với `MxIconButton` đã triển khai: xác nhận phần đã thoả, ghi lại phần còn lệch (kích thước glyph mặc định) và vì sao tài liệu này không tự sửa nó |
| **Scope** | Đối chiếu dimension table + state matrix + danh sách icon của prompt gốc với `mx_icon_button.dart` / `app_icon_button_theme.dart` / `tokyo-component-mapping.md`. Ngoài phạm vi: giá trị token gốc (AD-14), thay đổi bất kỳ hợp đồng đóng băng nào (việc của một task design-system riêng, xem §3) |
| **Source of truth for** | Kết quả đối chiếu spec IconButton (kit) ↔ implementation; điểm nào của spec gốc đã khớp, điểm nào còn mở |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/v1-freeze.md` · `design-system/tokyo-component-mapping.md` · `.claude/skills/flutter-theme-design/references/buttons-actions.md` §19 |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-12 |

---

## 0. Tài liệu này là gì, và không phải là gì

Nguồn: MemoX HTML design kit, mục *B · Buttons & actions*. Kit đã bị xoá ở
M100.83 (#541) — spec gốc (nguyên văn ở §1) là bản ghi duy nhất còn lại của
mục này.

**Đây không phải một implementation task.** `MxIconButton` đã tồn tại từ M4.8
và đã qua ít nhất một lần mở lại có chủ đích (M100.73 — thêm trục
`MxIconButtonShape.outlined` theo owner review kèm ảnh chụp bản dựng, xem
`v1-freeze.md` §3a). Phần lớn hợp đồng của nó đã **đóng băng**: sàn 48dp
(`v1-freeze.md` §2 dòng 7), mapping ThemeData (dòng 3), và public contract
của shared primitive (dòng 6). Tài liệu này đối chiếu spec với code thật,
không tự ý đổi bất kỳ dòng nào trong số đó.

File đã đọc để đối chiếu: `mx_icon_button.dart`, `app_icon_button_theme.dart`,
`app_interaction_states.dart`, `app_icon_size.dart`, cộng ba tài liệu
design-system liệt ở header và checklist §19 của `flutter-theme-design`.

## 1. Hợp đồng component (nguyên văn từ prompt gốc — binding)

| Dimension | Class | Giá trị gốc |
|---|---|---|
| hover | FIXED | 8% layer |
| ink box | FIXED | 36 |
| hit target | MINIMUM | 48 |
| glyph | FIXED | 20 · icon-sm |

Icon (Lucide, dịch theo nghĩa sang Material Symbols): `search` ·
`more-vertical` · `bookmark`.

State matrix gốc: default = không fill, glyph `onSurfaceVariant`; hover/pressed
= vòng tint primary 8% sau glyph (14% ở dark); disabled = glyph 38%
**[INFERRED — prompt tự ghi: mock không vẽ trạng thái này]**.

Prompt gốc tự nêu rõ hai điều trước khi vào chi tiết: tên icon "là cái kit
minh hoạ, không phải phần cố định của hợp đồng" (chỉ bước kích thước là cố
định), và danh sách kỹ thuật HTML/CSS không được copy nguyên văn — trong đó
có `::after` hit-expander và "hover states" nói chung.

## 2. Đối chiếu — từng dimension

| Yêu cầu | Trong `MxIconButton` hôm nay | Bằng chứng |
|---|---|---|
| hit target 48 MINIMUM | `minimumSize: Size.square(AppSizing.touchTarget)` (48), không tham số nào hạ được nó | [app_icon_button_theme.dart:20](../../lib/core/theme/components/actions/app_icon_button_theme.dart:20) |
| default: không fill, glyph `onSurfaceVariant` | `foregroundColor: scheme.onSurfaceVariant`; shape `plain` không vẽ gì ở trạng thái nghỉ | [app_icon_button_theme.dart:21](../../lib/core/theme/components/actions/app_icon_button_theme.dart:21), [mx_icon_button.dart:127-133](../../lib/shared/widgets/mx_icon_button.dart:127) |
| disabled 38% glyph [INFERRED] | `disabledForegroundColor: semantic.onDisabled`, dẫn từ `AppStateOpacity.disabledContent = 0.38` | [app_icon_button_theme.dart:23](../../lib/core/theme/components/actions/app_icon_button_theme.dart:23), [app_interaction_states.dart:90](../../lib/core/theme/states/app_interaction_states.dart:90) |
| icon `search` | `Icons.search`, trên chính bar mà spec này mô tả — xem §3 | [deck_list_screen.dart:88](../../lib/features/deck/presentation/screens/deck_list_screen.dart:88) |
| icon `more-vertical` | `Icons.more_vert`, cùng bar (§3) cộng icon mặc định của `MxMenuButton` (biến thể overflow-menu) và ba call site khác | [deck_list_screen.dart:103](../../lib/features/deck/presentation/screens/deck_list_screen.dart:103), [mx_menu_button.dart:78](../../lib/shared/widgets/mx_menu_button.dart:78), [deck_tile_widget.dart:153](../../lib/features/deck/presentation/widgets/items/deck_tile_widget.dart:153) |
| icon `bookmark` | không có caller nào trong app | — |
| ink box 36 FIXED + hover 8% layer (qua `::after` mở rộng hit target) | không có vòng "ink" 36 riêng biệt với hit target — nguyên tắc đã chốt trước đó cho đúng mẫu này (`MuiIconButton` pad 8 → 40 vẽ) là **sàn 48 thắng pad**, không giữ box vẽ nhỏ hơn target | [tokyo-component-mapping.md:140](tokyo-component-mapping.md:140) |
| hover/pressed 8% primary tint (14% dark) | hover = `onSurfaceVariant` @ 8% (trung tính, không phải primary); pressed = `primary` @ 12%; focus = `primary` @ 10% — không có nhánh riêng cho dark | [app_interaction_states.dart:126-131](../../lib/core/theme/states/app_interaction_states.dart:126), [app_interaction_states.dart:211-228](../../lib/core/theme/states/app_interaction_states.dart:211) |
| glyph 20 · icon-sm FIXED | mặc định vẽ `AppIconSize.md` = 24; token 20 tồn tại (`AppIconSize.mdCompact`) nhưng chỉ dùng khi `isCompact: true` | [app_icon_size.dart:9-18](../../lib/core/theme/foundations/app_icon_size.dart:9), [mx_icon_button.dart:153](../../lib/shared/widgets/mx_icon_button.dart:153) — xem §3 |

Ba dòng "ink box", "hover/pressed tint" và icon `bookmark` không phải gap:
dòng đầu và dòng hai là đúng loại giá trị mà chính prompt liệt vào danh sách
"không copy literal" (kỹ thuật mở-rộng-hit-target kiểu web, và phần trăm
hover/pressed đo trên một kit đã xoá) — MemoX đã có quyết định riêng, có lý
do ghi lại, cho đúng mẫu này từ trước khi prompt này tồn tại. `bookmark`
không có gì để nối vì chính prompt nói tên icon "không phải phần cố định của
hợp đồng".

## 3. Kích thước glyph — đã có quyết định, hai ngày trước, đúng trên hai nút này

Prompt gốc đánh dấu **FIXED** cho bước kích thước (không phải cho tên icon):
"the size step in the dimension table IS fixed". Nếu không có gì khác, đây sẽ
là một gap thật — nhưng có: `deck_list_screen.dart:78-86` (chính hai nút
`search`/`more_vert` mà spec này mô tả) ghi lại rằng **cấu hình y hệt spec đã
được dựng, rồi bị rút lại**, gần nhất trước ngày viết tài liệu này hai hôm.

| Task | Ngày | Việc |
|---|---|---|
| M100.73 | — | Thêm trục `MxIconButtonShape.outlined` (vòng tròn viền) — owner review kèm ảnh chụp |
| M100.75 | — | Bar Library dùng vòng tròn theo mockup 2026-09-10, cộng `isCompact` (glyph 20 qua `AppIconSize.mdCompact`) vì glyph 24 trong vòng 40 để lại viền 8px mỗi bên |
| M100.77 | — | Vòng tròn hạ xuống 40 vẽ / 48 chạm |
| **M100.81** | **2026-09-10** | **Chủ dự án xem golden xong, yêu cầu bỏ viền.** `isCompact` đi theo *vì lý do của nó không còn* — không phải bị quên. Kết quả: hai nút trở lại `MxIconButton` mặc định — chạm 48, **glyph 24**, không viền |

Bằng chứng: [deck_list_screen.dart:78-86](../../lib/features/deck/presentation/screens/deck_list_screen.dart:78),
[wbs-archive/m100.md:182-204](../wbs-archive/m100.md:182) (M100.81, đủ
Scope/Output/Acceptance criteria).

**M100.81 chủ động giữ lại hạ tầng, chỉ đổi caller.** `MxIconButtonShape` và
`buildOutlinedIconButtonStyle` (M100.73) không bị gỡ — "chúng vẫn ở đó cho lần
sau có bar khác cần vòng tròn". Và `deck_header_chrome_test.dart` được **đảo
chiều** (không xoá): trước khẳng định "có ≥2 nút outlined", nay khẳng định
"không nút nào outlined" — viết rõ ràng để một PR sau **không vô tình dựng lại
vòng tròn mà không ai để ý**. Áp lại spec kit ở đúng hai nút này là đi thẳng
vào test đó.

**Vì sao đây không phải "spec đúng, code sai".** Prompt này và mockup
2026-09-10 mà M100.75 dựng theo gần như chắc chắn là cùng một nguồn — cùng
ngày, cùng hai nút, cùng cặp thuộc tính (viền + glyph nhỏ). Khác biệt duy
nhất là **M100.81 có thêm một dữ kiện mà bản kit tĩnh không có: phản hồi của
chủ dự án sau khi nhìn nó chạy trên thiết bị thật**, không phải trên một bản
render tĩnh. Một task đối chiếu spec không có thẩm quyền ghi đè một quyết
định on-device gần hơn, cụ thể hơn — đó là đúng loại việc `v1-freeze.md` §3
dành riêng cho **điều kiện mở lại #6** (chủ dự án chỉ định, kèm tham chiếu thị
giác cụ thể): nếu chủ dự án muốn xem lại, đó là quyết định của họ để đảo lại
lần nữa, không phải suy luận từ một prompt tĩnh hơn cả bản mockup đã bị vượt
qua.

**Phần còn lại của app không có bằng chứng cùng mức.** M100.81 chỉ chạm hai
nút trên bar Library; những caller khác của `MxIconButton` (card, trash,
study…) chưa từng được đối chiếu on-device với glyph 20, nên với chúng đây
đúng là một khoảng trống chưa đo — nhưng cùng logic áp dụng: đổi mặc định của
`AppIconSize.md` là chạm một quyết định nền tảng có tên
("Default for actions and list affordances"), ảnh hưởng mọi caller cùng lúc,
và nằm trong đúng ba dòng đã đóng băng của `v1-freeze.md` §2 (3, 6, 7) — cũng
cần điều kiện #6, không phải suy luận riêng của tài liệu này.

## 4. Kết luận

Năm trong sáu mục của contract (hit target, default state, disabled state,
icon `search`/`more-vertical`, và cặp "ink box"/"hover tint" đọc đúng theo
quy tắc không-copy-literal) đã được thoả bởi hành vi hiện có, giữ bởi guard
role-binding và bộ golden/accessibility sweep đã có
(`mx_tonal_and_outlined_test.dart` ghim biến thể outlined; bốn
`*_accessibility_sweep_test` giữ sàn 48dp). Mục thứ sáu — glyph 20 thay vì 24
— **không phải một khoảng trống chưa ai xét**: đúng cấu hình này đã được dựng
(M100.73/75/77) rồi bị chủ dự án rút lại sau khi xem trên thiết bị thật
(M100.81, 2026-09-10), với một test đảo chiều để giữ quyết định đó. Không có
task implement nào phát sinh từ tài liệu này, và áp lại spec kit ở hai nút
`search`/`more_vert` sẽ là đảo ngược M100.81 — việc chỉ chủ dự án được quyết,
qua điều kiện mở lại #6 của `v1-freeze.md` §3, không phải một suy luận từ
prompt kit tĩnh hơn chính bản mockup nó mô tả.
