# Layout review — 29 màn hình

Một file cho mỗi màn hình trong screen gallery, chấm theo checklist bố cục
mobile 20 mục + ba tầng Correct / Balanced / Beautiful + bảng 8 tiêu chí.

Chấm trên commit `ea80d3f7` (sau khi 26 golden cũ được vẽ lại — xem bên dưới).

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

## Đọc con số typography thế nào

`rungs` đếm tổ hợp phân biệt của (size / weight / height / letter-spacing) thực
sự được vẽ. Hai điều chỉnh khi so với mốc "3–5 cấp" của checklist:

- **Bottom navigation góp 2–3 rung cho mọi màn có nó.** Đó là chrome dùng chung,
  không phải typography của màn.
- **Màn có sheet/dialog vẫn vẽ màn phía sau.** `card_export_sheet`,
  `card_bulk_delete_dialog`, `card_move_picker`, `tag_filter_sheet` mang theo
  rung của card list bên dưới. Số của chúng là của **hai** màn cộng lại.

Mỗi file nói rõ phần nào là của nội dung màn đó.

## Golden phải đúng trước khi chấm

Lúc bắt đầu, `origin/main` có **26 golden cũ**: #337 đổi cách render của sáu
component qua `MxButtonPair` và commit 0 file PNG. Gallery khi đó đang xuất bản
bản app trước #337. Đã vẽ lại trên Windows (máy sở hữu pixel comparison) và mở
[PR #340](https://github.com/ntgptit/memox-v7/pull/340) trước khi chấm bất cứ
màn nào — chấm ảnh cũ là chấm một bản fork của app.

CI không gác golden: rollup của PR không có job Windows nào, nên chuyện này lọt
mà không ai thấy.

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
