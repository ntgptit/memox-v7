# Import — preview (bước 2)

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_import_preview_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **6**, tất cả là nội dung |
| Rung | 22/600 · 16/600 · 14/600 · 14/400 · 12/500 · 12/400 |
| Font weight | 400, 500, 600 |
| Spacer | 4×1, 8×4, 12×1, 16×1 — **toàn bộ trên scale** |
| Inset | 4×28, 8×23, 12×12, 16×6, 24×5 + **1×6 = bề rộng viền** |
| Trục text trái | **200 ×62** · 16 ×22 · 52 ×20 · 28 ×10 · 68 ×9 |
| Tap target | 11 chạm được, **2 dưới 48** |
| Target nhỏ | hai `Switch` 60×40 — **cả hai được hàng `InkWell` 361×56 phủ** |

Trục 200 dùng 62 lần: cột giá trị của bảng ánh xạ cột và cột nghĩa của bảng
preview dùng chung một đường.

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ❌ **thanh nút đáy cắt ngang hàng preview thứ 4** — xem F1 |
| Safe area | ⚠️ dòng trợ giúp lại nằm dưới nút, sát mép — như bước 1 |
| Touch target | ✅ 11/11 hiệu dụng — hai Switch 40px đều nằm trong hàng 56px |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ `Continue` là khối đặc duy nhất; `Back` outlined, không tranh |
| Grouping đúng | ✅ nguồn → tuỳ chọn đọc → ánh xạ cột → preview, bốn nhóm |
| Alignment tốt | ✅ trục 200 dùng chung cho hai bảng khác nhau |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ❌ **preview chiếm ~16% màn trên một bước tên là Preview** — xem F2 |
| Visual weight cân | ⚠️ phần thiết lập nặng hơn phần kết quả |
| CTA prominence | ✅ |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ |
| Typography tinh tế | ✅ 6 rung, 3 weight |
| Icon/text proportion | ✅ icon 16 trong chip trạng thái |
| Surface/color hierarchy | ✅ ba chip trạng thái dùng ba màu ngữ nghĩa đúng nghĩa |
| Mắt đi đúng flow | ⚠️ flow đúng, nhưng đích đến bị cắt cụt |

## Checklist 20 mục

**1. Screen structure** ⚠️ Mục tiêu là "xem trước từng hàng trước khi import".
Cấu trúc phục vụ nó, nhưng phần xem trước lại là phần nhỏ nhất — xem F2.

**2. Visual hierarchy** ✅ Stepper cho biết đã xong 2 bước. `2 of 5 ready` là con
số quan trọng nhất của bước và nó được đặt phải, ngang tiêu đề section — đọc
được ngay.

**3. Grouping** ✅ Bốn nhóm rõ. Toggle `Include duplicates` đặt **ngay trên** bảng
preview mà nó ảnh hưởng — đúng chỗ.

**4. Alignment** ✅ Trục 200 ×62 dùng chung cho cột giá trị của cả hai bảng.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ✅ 6 rung, 3 weight. Không có cỡ dưới 12.

**7. Component sizing** ✅ Hai toggle cùng kích thước, ba chip trạng thái cùng
chiều cao, `Back`/`Continue` cùng chiều cao qua `MxButtonPair`.

**8. Density** ❌ F2.

**9. Balance** ⚠️ Trọng lượng dồn vào phần thiết lập (toggle + 3 dòng ánh xạ),
phần kết quả bị ép xuống dưới.

**10. Color hierarchy** ✅ Xám cho Ready, đỏ cho Invalid, xanh cho Duplicate —
ba màu, ba nghĩa, không màu nào trang trí. Dấu `✓` / `✕` trong bảng lặp lại đúng
hệ màu đó.

**11. App bar** ✅

**12. List / card** ⚠️ Mỗi hàng preview có số thứ tự, front, back, và một icon
trạng thái bên phải — hierarchy rõ. Hàng lỗi có dòng lý do bên dưới. ❌ vì F1.

**13. Filter / sort / chips** ✅ Ba chip cùng chiều cao, spacing đều, và chúng là
**tóm tắt** chứ không phải filter — không giả dạng thứ bấm được.

**14. CTA** ✅ Một primary (`Continue`), một secondary outlined (`Back`), cùng
kích thước nhờ `MxButtonPair` (#337). Dòng `No cards are added until you tap
Import.` là lời trấn an đúng lúc.

**15. Scroll** ❌ F1: thanh đáy che mất hàng cuối, không có bottom padding.

**16. Responsive** ➖

**17. Safe area** ⚠️ Cùng F2 của [card_import_source](card_import_source.md).

**18. Empty / loading / error** ✅ Hàng lỗi được khoanh và có lý do — trạng thái
lỗi ở mức từng hàng, đúng chỗ.

**19. Content stress** ✅ Có `(empty)` cho ô rỗng, có hàng trùng, có hàng lỗi —
ba biến thể nội dung khó cùng lúc. Tốt.

**20. Interaction** ✅ Hai toggle có on/off phân biệt rõ. Dropdown ánh xạ cột có
mũi tên — trông chọn được và chọn được.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | `2 of 5 ready` đặt đúng chỗ, stepper rõ |
| Grouping | 2 | toggle đặt cạnh thứ nó ảnh hưởng |
| Alignment | 2 | trục 200 dùng chung hai bảng |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 0 | preview chiếm 16% của bước tên là Preview |
| Typography | 2 | 6 rung, không cỡ dưới 12 |
| CTA | 2 | pair cân, có dòng trấn an |
| Responsive | 1 | chưa đo |
| **Tổng** | **13 / 16** | **Minor fix** — nhưng F1 là Level 1 |

## Findings

**F1 — Thanh nút đáy cắt ngang hàng preview thứ 4.** ❌ Level 1.
Hàng `4 · 감사합니다 · (empty)` có một dòng lý do màu đỏ bên dưới, và dòng đó bị
thanh `Back`/`Continue` cắt ngang giữa chừng — nhìn thấy được nửa trên của chữ.
§15 nói rõ: bottom CTA không được che item cuối, và phải có bottom padding phù
hợp. Ở đây bảng preview không chừa chỗ cho thanh sticky.
Nặng hơn bình thường vì thứ bị che là **lý do một hàng bị từ chối** — đúng thông
tin mà bước này tồn tại để đưa ra.
Sửa: thêm bottom padding bằng chiều cao thanh đáy vào vùng cuộn.

**F2 — Bước tên là Preview nhưng preview chỉ chiếm ~16% màn.** ❌
Trên 852px, trước bảng preview đã tiêu: app bar, breadcrumb, stepper, chip deck,
thẻ nguồn, toggle headers, tiêu đề `Match columns`, ba dòng ánh xạ, tiêu đề
`2 · Preview`, ba chip, toggle duplicates. Bảng preview còn lại ~140px, tức 3
hàng, và hàng thứ 3 bị cắt.
Đây là **cùng một khiếm khuyết** với [card_list](card_list.md) F3 và với hero của
deck list trước bốn vòng sửa: phần thiết lập nuốt mất phần nội dung.
Hướng: gập nhóm `Match columns` lại sau khi đã tự nhận đúng (ba dòng hiện tại đều
khớp tên), để mặc định nó là một dòng tóm tắt `front → Front · back → Back · tags
→ Tags` bấm được để mở.

**F3 — Hai Switch 60×40 nhưng đều được hàng 56px phủ.** ✅ không phải lỗi, ghi lại.
Probe ban đầu báo chúng là target nhỏ; kiểm tra bao phủ cho thấy cả hai nằm trong
`InkWell` 361×56, tức chạm bất kỳ đâu trên hàng đều bật/tắt được. Đây là cách làm
đúng và là lý do phép đo "target nhỏ" phải kèm kiểm tra bao phủ.
