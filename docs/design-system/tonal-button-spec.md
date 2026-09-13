# TonalButton — đối chiếu component spec với `MxActionButton.tonal`

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract "TonalButton" (MemoX HTML design kit, mục B · Buttons & actions) với `MxActionButton(variant: MxActionButtonVariant.tonal)` + `buildFilledStyle(pair: MxFilledPair.tonal)` đã triển khai; ghi lại vì sao một tài liệu mapping khác (`tokyo-component-mapping.md`) từng nói variant này "không dựng" và vì sao điều đó nay sai |
| **Scope** | Đối chiếu dimension table, icon, state matrix của TonalButton (kit) với `mx_action_button.dart` / `app_button_themes.dart`. Ngoài phạm vi: FilledButton, FloatingActionButton (spec riêng), giá trị token gốc, thay đổi hợp đồng đóng băng |
| **Source of truth for** | Kết quả đối chiếu spec TonalButton (kit) ↔ `MxActionButton.tonal`; lịch sử gỡ (M100.36) và re-admit (M100.73/M100.74) của `MxFilledPair.tonal` |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/v1-freeze.md` §3a · `design-system/tokyo-component-mapping.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-13 |

---

## 0. Tài liệu này là gì, và không phải là gì

Nguồn: MemoX HTML design kit, mục *B · Buttons & actions*. HTML design kit đã
bị xoá ở M100.83 — spec gốc (§1) là bản ghi duy nhất còn lại của mục này.

**Đây không phải một implementation task, và đã có một reopen record cho nó.**
`v1-freeze.md` §3a/§3b (M100.73, M100.76) ghi lại chính xác lần chủ dự án yêu
cầu kit mang một mockup Library kèm ảnh chụp, và trong bốn chỗ lệch nêu ra,
một chỗ là "nút Study trên hàng deck là pill tông nhạt, trong khi
`MxActionButtonVariant` có đúng ba giá trị và không giá trị nào là tonal" —
đây chính là gap mà TonalButton (component này) mô tả. `v1-freeze.md` §3a nói
rõ điều kiện mở lại nào áp dụng (điều kiện 6 — "chủ dự án chỉ định một thay đổi
hình thức cho component đã có, kèm tham chiếu thị giác cụ thể") và ghi rằng
"M100.73 chỉ thêm variant vào primitive và MUST NOT dùng chúng ở đâu cả; task
feature đi sau (M100.74) là nơi chúng có caller đầu tiên."

**Phát hiện của tài liệu này: hai tài liệu khác trong repo còn nói variant này
chưa tồn tại, và cả hai đều sai kể từ M100.73/74.**

1. `tokyo-component-mapping.md` §2 (bảng `actions/`) ghi dòng
   `FilledTonalButton | ... | không dựng | gỡ ở M100.36...` — tài liệu đó
   "Last updated: 2026-09-03", tức **trước** M100.73 (2026-09-10). Đã sửa lại
   trong cùng đợt với tài liệu này (xem diff của `tokyo-component-mapping.md`).
2. `app_button_themes.dart`, doc comment ngay phía trên khai báo
   `enum MxFilledPair`, còn viết "**`tonal` left at M100.36.** It had no
   production caller..." — mô tả một enum **hai** thành viên (`brand`,
   `destructive`), trong khi enum thật có **ba**, và chính thành viên `tonal`
   (dòng bên dưới) có doc comment riêng giải thích chi tiết vì sao nó *được*
   admit. Đã sửa lại comment đó trong cùng đợt.

File đã đọc: `mx_action_button.dart`, `app_button_themes.dart`,
`app_interaction_states.dart`, `v1-freeze.md`, `tokyo-component-mapping.md`.

## 1. Hợp đồng component (nguyên văn từ prompt gốc — binding)

Mục đích: Secondary — sits on surface. Nature: production component. Closest
Flutter/Material equivalent theo prompt gốc: `FilledButton.tonal`.

**Dimension table gốc:**

| Dimension | Class |
|---|---|
| container | surfaceContainer — CONTENT-DRIVEN |

**Icon:** none — component này không tự vẽ glyph nào.

**State matrix gốc:**

| Trạng thái | Vẽ |
|---|---|
| `default` | secondaryContainer fill, onSecondaryContainer label |
| `pressed` | 8% onSecondaryContainer overlay [INFERRED] |
| `disabled` | 38% opacity [INFERRED] |

## 2. Đối chiếu — dimension table

| Dimension | Class (kit) | Hành vi đã triển khai | Verdict |
|---|---|---|---|
| container | CONTENT-DRIVEN, `surfaceContainer` | `MxFilledPair.tonal.fillOf` = `scheme.secondaryContainer` — **không** `surfaceContainer` | **Lệch tên role, đúng M3** |

**Vì sao "surfaceContainer" của kit sai và `secondaryContainer` đúng.** Kit gọi
tên nền của tonal button là `surfaceContainer` — một role trung tính
(container/chip/inactive track theo `Foundations` của chính kit). M3 thật
không có "tonal button trên surfaceContainer": `_FilledButtonDefaultsM3` cho
`FilledButton.tonal` là cặp `secondaryContainer`/`onSecondaryContainer`, một
role **có ý nghĩa nhấn mạnh** (container của brand thứ cấp), không phải một bề
mặt trung tính. `MxFilledPair.tonal` bám đúng cặp M3 chuẩn, giữ bởi
`v1-freeze.md` §2 dòng 1/2 (danh tính 45 role + không đổi role ngữ nghĩa bằng
role khác) — [app_button_themes.dart:128-138](../../lib/core/theme/components/actions/app_button_themes.dart:128).

## 3. Icon

Kit: không glyph nào là một phần cố định. Thật: `MxActionButton` nhận
`icon`/`iconSide` tuỳ chọn cho mọi variant kể cả `tonal`, do caller truyền.
Không mâu thuẫn.

## 4. Ma trận trạng thái

| Trạng thái | Kit | Thật | Verdict | Bằng chứng |
|---|---|---|---|---|
| `default` | secondaryContainer fill, onSecondaryContainer label | Khớp nguyên văn | **Khớp** | [app_button_themes.dart:131,138](../../lib/core/theme/components/actions/app_button_themes.dart:131) |
| `pressed` | 8% onSecondaryContainer overlay [INFERRED] | State layer `onSecondaryContainer` @ `stateLayerPressed` = 0.10 (cùng cơ chế FilledButton — xem [`filled-button-spec.md`](filled-button-spec.md) §4 cho lý do 8% của kit là hover, không phải press) | **Lệch số, cơ chế khớp** | [app_button_themes.dart:151-159](../../lib/core/theme/components/actions/app_button_themes.dart:151), [app_interaction_states.dart:72-74](../../lib/core/theme/states/app_interaction_states.dart:72) |
| `disabled` | 38% opacity [INFERRED] | Role đổi hẳn — fill → `semantic.disabledSurface`, label → `semantic.onDisabled` (~38.04%) — cùng cơ chế disabled dùng chung cho cả ba `MxFilledPair` | **Lệch cơ chế, có chủ đích, giống FilledButton** | [app_button_themes.dart:214-224](../../lib/core/theme/components/actions/app_button_themes.dart:214) |

`buildFilledStyle` là **một** resolver cho cả ba pair (`brand`, `tonal`,
`destructive`) — không có nhánh trạng thái nào riêng cho tonal mà hai anh em
kia không có, nên toàn bộ phân tích "vì sao lệch mà đúng" ở
[`filled-button-spec.md`](filled-button-spec.md) §4 áp dụng nguyên vẹn ở đây.

## 5. Ranh giới hình học — trục kích thước, không phải màu

`v1-freeze.md` §2 dòng 6 (public contract của shared primitive) giới hạn kết
luận ở đây: `tonal` là **một thành viên thêm vào một enum đã đóng**
(`MxActionButtonVariant`), không phải một widget hay một API mới —
`shared_api_closure_test` không phải nới lỏng vì allowlist của nó vốn nhận
enum do chính component khai báo (`v1-freeze.md` §3a). Doc comment của chính
`tonal` trong `mx_action_button.dart:25-37` nói rõ: *"A weight, not a colour"*
— nó tồn tại cho một hàng mà mọi dòng mang cùng một động từ (Study), nơi filled
lặp lại tới mức hết còn là nhấn mạnh và outlined đọc như một lựa chọn thay thế
không có gì để thay thế cho.

## 6. Hợp đồng đóng băng đang che component này

`v1-freeze.md` §2: vai trò (#1, #2 — `secondaryContainer`/`onSecondaryContainer`
đúng cặp M3, không phải một role tự chế), mapping ThemeData (#3), public
contract của shared primitive (#6 — enum thêm thành viên, không nới API),
floor 48dp (#7), ripple/state (#8 — cùng resolver với FilledButton), raw
Material (#13). Component này **là** một ví dụ reopen thành công theo điều
kiện 6 của §3 (xem §0) — tài liệu này không đề xuất reopen gì thêm.

## 7. Kết luận

`TonalButton` đã triển khai đầy đủ hợp đồng của kit, qua đúng con đường
`v1-freeze.md` §3 điều kiện 6 quy định (M100.73 thêm primitive, M100.74 cho nó
caller đầu). Một điểm kit gọi sai tên role (`surfaceContainer` thay vì
`secondaryContainer`) — code đúng M3, kit sai; hai trạng thái tương tác lệch
số/lệch cơ chế theo đúng cách FilledButton đã lệch, vì cùng một resolver. Phát
hiện thật của đợt đối chiếu này không nằm ở component mà ở hai tài liệu khác
đã lạc hậu so với M100.73 — cả hai đã được sửa cùng đợt (xem §0).
