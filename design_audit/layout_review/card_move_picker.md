# Move picker

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_move_picker_light.png` · commit `ea80d3f7`

Sheet chọn deck đích; chỉ deck hợp lệ được chào (BR-55 về độ sâu, và deck
`content_type` phù hợp). Số typography là của **hai** màn cộng lại —
[card_list](card_list.md) ở dưới; 18/21 target bị barrier chặn.

## Số đo

| | |
|---|---|
| Typography rungs | **12 tổng** — **cao nhất trong 29 màn**, nhưng chỉ **~4 là của sheet** |
| Rung của sheet | 16/600 (`Move to deck`) · 16/400 (tên deck) · 14/400 (deck cha) · 12/… |
| Spacer | 4×7, 8×5, 12×8 — **toàn bộ trên scale** |
| Inset | 4×17, 8×31, 12×3, 16×36, 24×3 + 1×20 viền + 48×1 vùng sheet |
| Trục text trái | 54 ×30 (nền) · **72 ×24 (tên deck trong sheet)** · 16 ×7 |
| Tap target | **3 chạm được** (ba hàng deck), **18 bị che**, **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ➖ sheet chưa cuộn tới đáy trong render này |
| Touch target | ✅ 3/3 — **cả hàng là target**, không chỉ tên |
| Text đọc được | ✅ |
| Component đúng chức năng | ⚠️ **sheet không nhắc lại đang chuyển bao nhiêu thẻ** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ tên deck 16/400 trên deck cha 14/400 — hai cấp, đủ |
| Grouping đúng | ✅ icon + tên + cha đọc thành một hàng |
| Alignment tốt | ✅ trục 72 dùng 24 lần cho cả tên lẫn deck cha |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ ba hàng trong ~45% màn; hàng cao ~90px cho hai dòng chữ |
| Visual weight cân | ⚠️ **~68px trống giữa handle và tiêu đề** — xem F2 |
| CTA prominence | ➖ không có CTA; chạm hàng là hành động — xem F1 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ F2 |
| Optical alignment | ✅ icon thư mục căn giữa theo cả hai dòng chữ |
| Typography tinh tế | ✅ sheet chỉ dùng ~4 rung |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ **không dùng primary ở đâu trong sheet** — danh sách trung tính, đúng |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ⚠️ Mục tiêu rõ (chọn deck đích) nhưng thiếu một nửa ngữ
cảnh — xem F1.

**2. Visual hierarchy** ✅ Tiêu đề sheet → danh sách. Trong mỗi hàng, tên deck
đậm hơn tên deck cha.

**3. Grouping** ✅ Mỗi hàng là một nhóm. **Không dùng card cho từng hàng** —
phân tách bằng khoảng cách, đúng §3, và khác với card list vốn bọc mọi hàng.

**4. Alignment** ✅ Trục 72 cho cả tên và cha. Icon ở trục riêng bên trái.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ✅ Sheet dùng ~4 rung. Con số 12 là do nền — xem F3.

**7. Component sizing** ✅ Ba hàng cùng chiều cao.

**8. Density** ⚠️ Hàng cao ~90px cho hai dòng chữ ngắn. Với một picker mà người
dùng có thể có hàng chục deck, mật độ này khiến phải cuộn nhiều.

**9. Balance** ⚠️ F2.

**10. Color hierarchy** ✅ Sheet **hoàn toàn trung tính** — không có primary nào.
Đúng: đây là một danh sách để chọn, không phần tử nào đáng được nhấn hơn phần tử
khác. Đối lập có chủ đích với [card_export_sheet](card_export_sheet.md), nơi một
lựa chọn được đánh dấu sẵn nên có primary.

**11. App bar** ➖

**12. List / card** ✅ **Toàn bộ hàng bấm được** (§12), metadata (deck cha) không
tranh với tên. Không có trailing action nào phá alignment.

**13. Filter / sort / chips** ➖ ⚠️ Và đó có thể là thiếu sót: picker không có ô
tìm kiếm. Với thư viện 10 cấp (BR-55) danh sách deck hợp lệ có thể rất dài.

**14. CTA** ⚠️ F1.

**15. Scroll** ✅ Sheet cuộn được.

**16. Responsive** ➖ Tên deck dài (`TOPIK I · Unit 2` đã khá dài) chưa được thử ở
360px.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ `card_move_picker_empty` có golden riêng, ngoài
29 màn — nhưng sự tồn tại của nó là dấu hiệu tốt.

**19. Content stress** ➖

**20. Interaction** ✅ Hàng trông chạm được và chạm được. Không có gì giả dạng.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | hai cấp trong hàng, đủ và không thừa |
| Grouping | 2 | không bọc card thừa |
| Alignment | 2 | trục 72 dùng 24 lần |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 1 | hàng 90px, picker có thể rất dài |
| Typography | 2 | ~4 rung cho sheet |
| CTA | 1 | không nhắc phạm vi, không có đường lùi rõ ràng |
| Responsive | 1 | chưa đo |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — Sheet không nói đang chuyển bao nhiêu thẻ.** ⚠️
Tiêu đề là `Move to deck`, hết. Con số `2 selected` nằm ở thanh phía sau, đã bị
scrim làm mờ. Chạm một hàng là **thực hiện luôn** — không có bước xác nhận, không
có nút Cancel hiện diện.
So sánh trong cùng feature: [card_export_sheet](card_export_sheet.md) mở đầu bằng
`All 128 cards in this deck` và kết bằng `Export 128 cards`; nó nhắc phạm vi
**hai lần**. [card_bulk_delete_dialog](card_bulk_delete_dialog.md) hỏi
`Delete 2 cards?`. Move picker là hành động duy nhất trong ba cái **không** nhắc
phạm vi, và nó cũng là cái duy nhất thực hiện ngay khi chạm.
Sửa rẻ: tiêu đề thành `Move 2 cards to…`.

**F2 — ~68px trống giữa handle và tiêu đề.** ⚠️ Level 3.
Ở [card_export_sheet](card_export_sheet.md) khoảng đó là ~40px. Hai bottom sheet
của cùng một app, cùng một component nền, có hai khoảng đầu khác nhau — §4 nói
component cùng loại dùng cùng padding.
Đây là loại lệch mà chỉ thấy được khi đặt hai golden cạnh nhau, và gallery chính
là chỗ để thấy.

**F3 — 12 rung: cao nhất trong 29 màn, và gần như toàn bộ là của màn nền.** ➖
Sheet tự nó dùng ~4. Con số 12 gồm cả 11 rung của [card_list](card_list.md), vốn
đã bị ghi nhận ở file đó.
Ghi lại vì nếu đọc bảng tổng hợp mà không đọc chú thích này thì móc picker sẽ bị
đổ oan cho khiếm khuyết của màn khác — đúng loại sai lầm mà probe đã phải sửa bốn
lần để tránh.

**F4 — Không có ô tìm kiếm trong picker.** ⚠️
Cây deck cho phép 10 cấp (BR-55). Với một thư viện thật, danh sách deck hợp lệ có
thể dài hàng chục hàng ở mật độ 90px/hàng. Đây không phải lỗi bố cục của render
hiện tại (3 deck) mà là rủi ro §19 chưa được thử.
