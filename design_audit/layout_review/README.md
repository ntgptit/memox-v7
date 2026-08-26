# Layout review — 29 màn hình, cộng 17 bề mặt overlay của deck

**[→ SUMMARY.md](SUMMARY.md)** — bảng điểm, điểm theo tiêu chí, 10 phát hiện
xuyên màn và thứ tự đề xuất sửa. Đọc file đó trước.

Một file cho mỗi màn hình trong screen gallery, chấm theo checklist bố cục
mobile 20 mục + ba tầng Correct / Balanced / Beautiful + bảng 8 tiêu chí.

[**deck_overlays.md**](deck_overlays.md) chấm 11 overlay và màn starter của deck
— các bề mặt không nằm trong 29 màn vì chúng không có golden nào. Chúng gộp vào
**một** file, không phải mười lăm: chúng dùng chung `MxActionSheet`,
`MxFormSheet`, `MxConfirmDialog` và `MxButtonPair`, nên ba trong bốn lỗi tìm được
là lỗi của component dùng chung — điều mà chấm riêng lẻ sẽ giấu đi.

Chấm trên commit `ea80d3f7` (sau khi 26 golden cũ được vẽ lại — xem bên dưới).

**Cột Responsive của bốn màn deck đã được chấm lại trên `cd4f3eb2`** bằng
[ma trận responsive](deck_responsive_matrix.md) — xem "Đo ngoài một frame" bên
dưới.

## Số đo đến từ đâu

Không mục nào trong các file này được đoán từ ảnh. `test/support/layout_probe.dart`
đi qua **đúng cây render mà gallery chụp** — nó móc vào `matchesReviewGolden`,
nên số đo và bức ảnh luôn ra từ cùng một lần pump, không thể lệch nhau.

```bash
MEMOX_LAYOUT_PROBE=1 flutter test test/demo/ --tags golden
```

Ghi ra `build/layout_probe/<golden>.json`. Nó chỉ **ghi**, không assert: rule nào
làm đỏ build thì thuộc `test/visual_audit/`, trộn hai thứ sẽ khiến một ý kiến về
spacing có quyền phá CI.

Probe đo bốn thứ, và cả bốn đều đã phải sửa vì bản đầu đo sai:

| Đo | Bản đầu sai thế nào |
|---|---|
| **Tap target** — hit-test thật, không đọc kích thước hộp | Đọc hộp `InkWell` bỏ sót `_InputPadding` mà Material dùng để nới target ra ngoài phần vẽ. Chiều ngược lại còn tệ hơn và dự án này đã trả giá: hộp 48 tràn khỏi row 32 thì `meetsGuideline` xanh (nó đọc semantics rect) trong khi mọi tap 4px ra ngoài bị tổ tiên loại vì hit test bắt đầu bằng `size.contains`. |
| **Target bị che** — target sau modal barrier trả `-1`, loại khỏi kết quả | Không loại thì cả hàng filter của card list bị báo là lỗi trên cả 4 màn mở sheet đè lên nó. |
| **Spacing** — đọc `SizedBox` rỗng và `Padding`, tức con số người ta gõ | Đo khoảng cách giữa các con của `Column` ra gần như toàn số 0, vì spacer **là** một đứa con nên hai đứa cạnh nó chạm nhau. |
| **Typography** — loại font MaterialIcons | `Icon` vẽ qua `RenderParagraph`, nên 16 icon trên deck list bị đếm thành một rung 24px/400, đẩy màn đó vượt 2 rung so với thứ mắt đọc được là chữ. |

Ba lỗi đầu đều **im lặng**: chúng cho ra số trông hợp lý.

## Đo ngoài một frame gallery chụp

`layout_probe.dart` đo **frame mà gallery chụp**, và đó vừa là điểm mạnh (số và
ảnh không thể lệch nhau) vừa là trần của nó: gallery chụp một bề rộng, một text
scale, một ngôn ngữ, một theme. Mọi mục §16 và §19 vì thế phải để `➖`.

`test/design_audit/deck_stress_probe.dart` dựng **frame mới** thay vì đo lại
frame cũ — 25 frame cho bốn màn deck, ở ba bề rộng × ba text scale × en/vi ×
light/dark, cộng list 0/1/50 item và tên deck dài.

```bash
MEMOX_LAYOUT_PROBE=1 flutter test test/design_audit/deck_stress_probe.dart   --tags golden --update-goldens
```

Nó hỏi mỗi `RenderParagraph` hai câu — có phải cắt chữ không, và cần thêm bao
nhiêu pixel để khỏi cắt. Cách này cần thiết vì **không một frame nào overflow**:
những gì hỏng đều hỏng êm sau `TextOverflow.ellipsis`, nên không có sọc vàng đen
nào để nhìn thấy, và một dấu `…` trông như một lựa chọn chứ không như sự cố.

Nó cũng **không** phải `_test.dart`, nên `flutter test` không thu nó vào suite
nào: nó ghi, không assert — cùng lý do với `layout_probe`.

Kết quả: [deck_responsive_matrix.md](deck_responsive_matrix.md).

## Đọc con số typography thế nào

`rungs` đếm tổ hợp phân biệt của (size / weight / height / letter-spacing) thực
sự được vẽ. Hai điều chỉnh khi so với mốc "3–5 cấp" của checklist:

- **Bottom navigation góp đúng 2 rung**, và chỉ ở 5/29 golden — xem mục dưới.
  Đó là chrome dùng chung, không phải typography của màn.
- **Màn có sheet/dialog vẫn vẽ màn phía sau.** `card_export_sheet`,
  `card_bulk_delete_dialog`, `card_move_picker`, `tag_filter_sheet` mang theo
  rung của card list bên dưới. Số của chúng là của **hai** màn cộng lại.

Mỗi file nói rõ phần nào là của nội dung màn đó.

## Giá trị ngoài scale — đã truy nguồn, không phải lỗi spacing

Probe thấy 6 giá trị nằm ngoài `AppSpacing.scale`. Nếu chỉ báo con số thì 8 màn
sẽ bị chấm trượt §5 oan, nên probe ghi luôn 6 tổ tiên gần nhất của mỗi cái. Kết
quả:

| Giá trị | Nguồn | Kết luận |
|---|---|---|
| **1,0 / 1,5** | `DecoratedBox < ConstrainedBox < Container` | **Bề rộng viền.** `Container` có `border` sinh ra một `Padding` bằng đúng bề rộng viền. Không phải spacing. |
| **13,0** | `Listener < _GestureSemantics < RawGestureDetector < Align` | Tay cầm chọn text của Flutter. Framework, không phải app. |
| **40,0** | `AnimatedPadding < Dialog < AlertDialog < MxConfirmDialog` | `insetPadding` mặc định của Material `AlertDialog`. Xem ghi chú dưới. |
| **48,0** | `Stack < NotificationListener<DraggableScrollableNotification>` | Vùng của bottom sheet; 48 là giá trị touch target chứ không phải bậc spacing. |
| **2,0 / 40,0** | `MxSessionTopBar < Column < Padding` | **Hai giá trị của app**, trong thanh trên của phiên học. |

Nên §5 (spacing scale) là ✅ ở gần như mọi màn, và điều đó **đo được** chứ không
phải giả định. Hai chỗ đáng nói:

- `AlertDialog` mang inset 40 của Material vào một hệ thống mà bậc lớn nhất là
  32. Không sai, nhưng nó là mặc định của framework nằm giữa các token của app.
- `MxSessionTopBar` dùng 2 và 40 trực tiếp.

Bản đầu của phần này cũng sai và im lặng: cap độ dài danh sách tổ tiên làm nó
đóng băng ở 25 phần tử đầu — toàn scaffolding gần root — nên mọi giá trị lệch
đều bị đổ cho `RootRestorationScope`. Phải đổi sang cửa sổ trượt giữ **6 tổ tiên
gần nhất** mới ra được bảng trên.

## Golden phải đúng trước khi chấm

Lúc bắt đầu, `origin/main` có **26 golden cũ**: #337 đổi cách render của sáu
component qua `MxButtonPair` và commit 0 file PNG. Gallery khi đó đang xuất bản
bản app trước #337. Đã vẽ lại trên Windows (máy sở hữu pixel comparison) và mở
[PR #340](https://github.com/ntgptit/memox-v7/pull/340) trước khi chấm bất cứ
màn nào — chấm ảnh cũ là chấm một bản fork của app.

CI không gác golden: rollup của PR không có job Windows nào, nên chuyện này lọt
mà không ai thấy.

## Chỉ 5/29 golden có bottom navigation

Probe đánh dấu từng rung typography là nằm trong hay ngoài `MxNavigationBar`.
Kết quả không mong đợi: **chỉ 5 golden có thanh tab** — bốn màn deck và
`progress_deck`.

`study_home`, `progress_overview` và `settings` **là tab của thanh đó** trong app
thật, nhưng ảnh của chúng không có nó. Bốn màn deck được dựng qua router thật
(`deckShellWith`), các màn còn lại dựng thẳng từ widget của màn.

Hai hệ quả cho bản review này:

- Mọi kết luận về **mật độ** và **safe area** trên ba màn đó thiếu 80px chrome
  mà thiết bị thật sẽ vẽ. Chúng được đánh ⚠️ hoặc ➖ chứ không ✅.
- `progress_overview` và `progress_deck` — **hai golden của cùng một feature** —
  dựng bằng hai cách khác nhau, nên không so sánh trực tiếp được với nhau.

Đây là khiếm khuyết của gallery, không phải của UI, nhưng nó đúng loại "ảnh nói
sai về thứ đã ship" mà CLAUDE.md cảnh báo — và nó im lặng: ảnh trông hoàn chỉnh.

Chú thích này cũng sửa một sai sót của chính tôi: năm file đầu tiên ghi "3 rung
là bottom nav" theo phỏng đoán. Đo ra là **2**, và `card_list` thì không có thanh
nav nào cả. Các file đó đã được sửa.

## Ký hiệu

| | |
|---|---|
| ✅ | đạt, có bằng chứng đo được hoặc thấy rõ trên render |
| ⚠️ | lệch nhưng dùng được, hoặc đúng nhưng mong manh |
| ❌ | sai, phải sửa |
| ➖ | **không kết luận được từ bằng chứng đang có** — không phải là đạt |

➖ dùng thật, không phải để lấp chỗ. Gallery chụp một size máy, một text scale,
một bộ dữ liệu; mọi mục về 360/412px, font scale 120–150%, 0/1/50+ item hay
trạng thái pressed/focused đều **không** trả lời được từ nó. Đánh ✅ cho chúng là
bịa, nên chúng ➖ kèm câu nói cần gì mới trả lời được.
