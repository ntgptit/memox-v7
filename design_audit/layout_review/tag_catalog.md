# Tag catalog

Tag · `lib/features/tag/presentation/` · golden
`test/demo/goldens/tag_catalog_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **3** — ngang [card_import_result_complete](card_import_result_complete.md), sạch nhất |
| Rung | 22/600 (title) · 16/400 (tên nhãn) · 14/400 (số thẻ) |
| Font weight | **400, 600 — chỉ hai** |
| Spacer | **không có `SizedBox` spacer nào** — toàn bộ nhịp do inset |
| Inset | 4×13, 8×26, 12×1, 16×14 — **toàn bộ trên scale, không có 1px viền** |
| Trục text trái | **32 ×48** · 52 ×2 · 16 ×2 |
| Tap target | 12 chạm được (6 hàng + 6 nút ⋮), **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ `TOPIK II · vocabulary · chapter 3` vừa đủ một dòng ở 393px |
| Không overlap | ✅ |
| Safe area | ➖ |
| Touch target | ✅ 12/12 |
| Text đọc được | ✅ tiếng Việt có dấu (`động từ`) render đúng |
| Component đúng chức năng | ✅ **số nhiều đúng**: `1 card` / `42 cards` / `No cards` |
| Responsive | ⚠️ nhãn dài nhất đã sát mép ở 393px — xem F2 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ tên nhãn 16/400 trên số thẻ 14/400 — hai cấp, đủ cho một danh mục |
| Grouping đúng | ✅ **không divider, không card** — chỉ khoảng trắng, và nó đủ |
| Alignment tốt | ✅ trục 32 dùng **48 lần**; cột ⋮ thẳng hàng tuyệt đối |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ⚠️ hàng ~88px cho hai dòng chữ; 6 nhãn chiếm 65% màn |
| Visual weight cân | ⚠️ 35% dưới trống |
| CTA prominence | ➖ không có CTA — xem F1 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ ⋮ căn giữa theo cả hai dòng của hàng |
| Typography tinh tế | ✅ **3 rung, 2 weight** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ **hoàn toàn đơn sắc** — không một pixel primary nào |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu: xem và sửa nhãn toàn thư viện. Hiểu ngay.

**2. Visual hierarchy** ✅ Hai cấp trong hàng, không thừa.

**3. Grouping** ✅ **Ví dụ mẫu cho §3**: "Không dùng divider nếu spacing đã đủ để
thể hiện grouping". Màn này không có một divider, không một card, và sáu hàng vẫn
đọc ra rành mạch. So với [card_list](card_list.md), nơi mỗi hàng được bọc trong
một surface có viền.

**4. Alignment** ✅ Trục 32 dùng 48 lần — cao nhất trong 29 màn. Cột ⋮ ở trục
riêng bên phải, không phá alignment (§12).

**5. Spacing & rhythm** ✅ **Không giá trị nào ngoài scale, và không dùng spacer
`SizedBox` nào** — toàn bộ nhịp đến từ inset. Đây là cách làm sạch nhất trong 29
màn: không có số nào rải rác giữa các widget.

**6. Typography** ✅ **3 rung, 2 weight — đạt mốc 3–5.**

**7. Component sizing** ✅ Sáu hàng cùng chiều cao, sáu nút ⋮ cùng kích thước.

**8. Density** ⚠️ Hàng 88px cho `food / 12 cards` là rộng rãi. Một danh mục nhãn
thường được duyệt bằng mắt chứ không đọc kỹ, nên đây là chỗ có thể compact hơn —
§8 nói list nhiều dữ liệu ưu tiên compact hơn dashboard.

**9. Balance** ⚠️ 35% dưới trống với 6 nhãn. Sẽ hết khi có nhiều nhãn hơn.

**10. Color hierarchy** ✅ Đơn sắc hoàn toàn. Với một màn quản lý siêu dữ liệu,
đây là quyết định đúng — không nhãn nào quan trọng hơn nhãn nào.

**11. App bar** ✅ Title `Tags` rõ. **Không action nào** — và ô tìm được đặt trong
nội dung chứ không nhét vào app bar, đúng §11 ("không nhét search vào app bar nếu
làm mất hierarchy").

**12. List / card** ✅ Cả hàng bấm được **và** ⋮ là target riêng — hai vùng chạm
nhưng chúng cách nhau gần hết chiều ngang màn, nên không nhầm được (§12).

**13. Filter / sort / chips** ➖ không có. ⚠️ Cũng không có sắp xếp — danh sách
đang theo thứ tự nào thì màn không nói. Xem F3.

**14. CTA** ➖ F1.

**15. Scroll** ✅

**16. Responsive** ⚠️ F2.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ `tag_catalog_empty` có golden riêng, ngoài 29
màn.

**19. Content stress** ✅ **Fixture tốt**: có tiếng Việt có dấu, có nhãn dài ba
đoạn, có `Noun` và `nouns` (ca gộp), có nhãn 0 thẻ. Bốn ca khó trong sáu hàng.

**20. Interaction** ✅ Không có gì giả dạng nút.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | hai cấp, không thừa |
| Grouping | 2 | không divider, không card, vẫn đọc rành mạch |
| Alignment | 2 | trục 32 dùng 48 lần |
| Spacing | 2 | 0 ngoài scale, không spacer rời |
| Density | 1 | hàng 88px cho hai dòng ngắn |
| Typography | 2 | 3 rung, 2 weight |
| CTA | 1 | không có lối tạo nhãn, và không nói vì sao |
| Responsive | 1 | nhãn dài nhất đã sát mép ở 393 |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — Không có lối tạo nhãn, và màn không nói vì sao.** ⚠️
Không FAB, không nút thêm. Nhãn được tạo khi gõ vào ô `Add tag` của
[card_editor_edit](card_editor_edit.md) — đó là một quyết định hợp lý (nhãn không
có thẻ thì vô nghĩa; `unused` ở đây là tàn dư sau khi gỡ khỏi thẻ cuối).
Nhưng người dùng đứng ở màn `Tags` không có cách nào biết điều đó. Một dòng chữ
ở cuối danh sách — "Tags are created when you add them to a card" — sẽ giải quyết,
và cũng lấp phần trống ở F "Balance".

**F2 — Nhãn dài nhất đã chạm mép ở 393px.** ⚠️
`TOPIK II · vocabulary · chapter 3` kết thúc ở khoảng x = 685/923 hiển thị, còn
cột ⋮ bắt đầu ở ~790. Biên còn ~100px hiển thị ≈ 42 logic. Ở 360px hoặc với nhãn
dài hơn một chút, tên sẽ đụng cột ⋮.
Chưa đo — nhưng khác với các mục ➖ khác, ở đây **đã nhìn thấy được biên còn lại
bao nhiêu**, nên nó là rủi ro có số chứ không phải phỏng đoán.

**F3 — Danh sách không nói nó đang sắp theo gì.** ⚠️
Thứ tự hiện tại (`động từ`, `food`, `Noun`, `nouns`, `TOPIK II…`, `unused`) là
alphabet không phân biệt hoa thường. Hợp lý, nhưng khi có nhiều nhãn, người dùng
sẽ muốn sắp theo số thẻ. [card_list](card_list.md) và deck list đều có control
sắp xếp; màn này không.
Không phải lỗi — ghi lại như một khác biệt có ý thức cần xác nhận.
