# Export sheet

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_export_sheet_light.png` · commit `ea80d3f7`

**Số của màn này là của hai màn cộng lại.** Sheet mở đè lên
[card_list](card_list.md), và màn phía sau vẫn được vẽ — nên bộ đếm typography
mang theo cả rung của card list. Phần tap target thì không: probe loại 17 target
bị modal barrier chặn.

## Số đo

| | |
|---|---|
| Typography rungs | **10 tổng** — trong đó **~5 là của sheet**, phần còn lại là card list phía sau (gồm cả hai rung 11px của nó) |
| Rung của sheet | 22/600 (`Export cards`) · 16/600 (tên format) · 14/600 · 14/400 (mô tả) · 12/600 (`Format`) |
| Font weight | 400, 500, 600 |
| Spacer | 4×7, 8×8, 12×7, 16×1, 24×2 — **toàn bộ trên scale** |
| Inset | 4×9, 8×22, 12×17, 16×22, 24×4 + 1×20 viền + **48×1 = vùng bottom sheet** |
| Trục text trái | 54 ×24 · 16 ×11 · 56 ×9 · 28 ×6 · 150 ×5 |
| Tap target | **5 chạm được** (3 thẻ format + 2 nút), **17 bị che**, **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ trong sheet |
| Không overlap | ✅ |
| Safe area | ✅ hai nút cách mép dưới, không có chữ nào dưới chúng |
| Touch target | ✅ 5/5 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ một CTA đặc, một outlined, một lựa chọn được đánh dấu sẵn |
| Grouping đúng | ✅ tiêu đề → phạm vi → format → điều gì có/không có trong file → hành động |
| Alignment tốt | ✅ ba thẻ format cùng trục, cùng bề rộng |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ✅ sheet chiếm ~60% màn cho 3 lựa chọn + 2 dòng ghi chú |
| Visual weight cân | ✅ |
| CTA prominence | ✅ `Export 128 cards` nói **đúng** số sẽ xuất |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ radio căn theo dòng tên format, mô tả thụt bằng tên |
| Typography tinh tế | ✅ ~5 rung cho sheet |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ primary chỉ ở radio đã chọn và nút xuất |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu. Handle kéo ở đỉnh nói rõ đây là sheet.

**2. Visual hierarchy** ✅ `Export cards` là cấp 1 của sheet; ba tên format cùng
cấp; mô tả thấp hơn. Chip `Recommended` không tranh với tên nó bổ nghĩa.

**3. Grouping** ✅ Năm nhóm rõ. Mỗi thẻ format bọc radio + tên + chip + mô tả
thành một khối — **và cả thẻ bấm được** (§12), không chỉ radio.

**4. Alignment** ✅ Ba thẻ cùng bề rộng, mô tả trong thẻ thụt bằng tên format.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale. 48 là vùng bottom sheet,
1px là viền thẻ — cả hai đã truy nguồn.

**6. Typography** ✅ Sheet dùng ~5 rung. Chỉ số 10 là do nền.

**7. Component sizing** ⚠️ Thẻ CSV cao hơn hai thẻ kia ~20px vì có chip
`Recommended`. Đây là chiều cao theo nội dung, không phải độn — chấp nhận được,
nhưng ba thẻ cùng loại trong một nhóm có chiều cao khác nhau vẫn đọc ra được.

**8. Density** ✅

**9. Balance** ✅

**10. Color hierarchy** ✅ Primary hai chỗ, cả hai đều mang nghĩa. Chip
`Recommended` trung tính — đúng, nó là gợi ý chứ không phải cảnh báo.

**11. App bar** ➖ sheet không có app bar; app bar nhìn thấy là của màn nền.

**12. List / card** ✅ **Toàn bộ thẻ format bấm được**, không chỉ nút radio bên
trong. §12 nói đúng điều này, và [tag_filter_sheet](tag_filter_sheet.md) cũng làm
đúng như vậy.

**13. Filter / sort / chips** ✅ Chip `Recommended` không giả dạng thứ bấm được.

**14. CTA** ✅ Nhãn CTA mang **con số thật** (`Export 128 cards`), khớp với dòng
phạm vi ở đầu sheet. Một primary, một outlined.

**15. Scroll** ✅ Sheet không cần cuộn ở nội dung này.

**16. Responsive** ➖ Ba mô tả format đều một dòng ở 393px tiếng Anh; ở tiếng Việt
chúng sẽ thành hai dòng và sheet cao thêm ~60px. Chưa đo.

**17. Safe area** ✅

**18. Empty / loading / error** ➖ `card_export_generating` và `card_export_error`
có golden riêng, ngoài 29 màn.

**19. Content stress** ➖

**20. Interaction** ✅ Selected state (radio đặc + viền thẻ đậm) dễ nhận. Không có
gì giả dạng nút.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | ba cấp trong sheet, chip không tranh với tên |
| Grouping | 2 | năm nhóm, cả thẻ là một target |
| Alignment | 2 | ba thẻ cùng bề rộng, mô tả thụt bằng tên |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 2 | |
| Typography | 2 | ~5 rung cho sheet |
| CTA | 2 | nhãn mang số thật, khớp phạm vi |
| Responsive | 1 | mô tả format sẽ xuống dòng ở tiếng Việt, chưa đo |
| **Tổng** | **15 / 16** | **Pass** — ngang [card_detail_page_error](card_detail_page_error.md) |

## Findings

**F1 — Hai dòng ghi chú, hai cách trình bày.** ⚠️ Level 3.
`Includes front, back, example, hint, pronunciation and tags.` để trần;
`Study progress and review history aren't in the file.` có icon ⓘ. Hai câu cùng
vai trò (nói cái gì có, cái gì không) nhưng một câu được đánh dấu là "thông tin",
câu kia thì không.
§6 nói text cùng chức năng dùng cùng style. Cho cả hai cùng một cách — hoặc cùng
có ⓘ, hoặc cùng không.

**F2 — Thẻ CSV cao hơn hai thẻ kia.** ⚠️ Level 3, có thể bỏ qua.
Chip `Recommended` đẩy dòng tên cao thêm. Ba thẻ cùng loại trong một nhóm. Không
đáng sửa bằng cách độn chiều cao hai thẻ kia — §7 cấm đúng việc đó. Nếu muốn
đều, đưa chip vào cùng dòng với tên mà không tăng chiều cao dòng.

**F3 — Màn nền vẫn mang theo hai rung 11px.** ➖ không phải lỗi của sheet.
Ghi lại để đọc số cho đúng: 10 rung của golden này gồm cả typography của
[card_list](card_list.md) phía sau, nơi F4 của file đó đã ghi nhận hai cỡ dưới
12px. Sheet tự nó sạch.
