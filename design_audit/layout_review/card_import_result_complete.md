# Import — kết quả (bước 3)

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_import_result_complete_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **3** — **ít nhất trong 29 màn** |
| Rung | 22/600 (title + tiêu đề kết quả) · 14/600 (nhãn dòng) · 14/400 (mô tả) |
| Font weight | 400, 600 — **chỉ hai** |
| Spacer | 4×1, 12×4 — **toàn bộ trên scale** |
| Inset | 4×2, 8×9, 12×6, 16×8, 24×5 — **toàn bộ trên scale, không có 1px viền** |
| Trục text trái | 56 ×3 · 41 ×3 · 251 ×3 · 106 ×2 · 32 ×2 |
| Tap target | 3 chạm được, **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ✅ hai nút cách mép dưới một khoảng, **không** có dòng chữ nào dưới nút — khác hai bước trước |
| Touch target | ✅ 3/3 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ một điểm nhấn (`Import complete`), một CTA đặc (`View cards`) |
| Grouping đúng | ✅ khối kết quả và bảng đếm tách nhau bằng 12, tách khỏi nút bằng khoảng lớn |
| Alignment tốt | ✅ |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ⚠️ **~55% màn trống ở giữa** — xem F2 |
| Visual weight cân | ⚠️ hai cụm ở hai đầu, giữa rỗng |
| CTA prominence | ✅ `View cards` đặc, `Import another file` outlined |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ nhiều và dồn vào một dải |
| Optical alignment | ✅ |
| Typography tinh tế | ✅ **3 rung, 2 weight — sạch nhất trong 29 màn** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ⚠️ **thành công không có màu, trong khi thất bại thì có** — xem F3 |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu: nói kết quả và đưa ra bước tiếp. Nhìn 2
giây là hiểu.

**2. Visual hierarchy** ✅ Đúng một điểm nhấn cấp 1.

**3. Grouping** ⚠️ Bảng đếm chỉ có **một dòng** (`Added · 4`) nhưng vẫn được bọc
trong một container riêng. §3 nói card chỉ dùng khi thật sự cần một group riêng.
Ở biến thể có bỏ qua (`card_import_result_skips`) bảng này nhiều dòng nên
container có lý — nhưng ở đây nó bọc một dòng.

**4. Alignment** ✅

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale, và không có inset 1px —
màn không dùng viền, giống [card_detail](card_detail.md).

**6. Typography** ✅ **3 rung, 2 weight.** Đạt mốc checklist với biên rộng nhất
trong toàn bộ 29 màn.

**7. Component sizing** ✅ Hai nút cùng kích thước qua `MxButtonPair`.

**8. Density** ⚠️ F2.

**9. Balance** ⚠️ Trọng lượng ở hai đầu, giữa trống. Với màn kết thúc thì chấp
nhận được, nhưng dải trống ~55% là nhiều.

**10. Color hierarchy** ⚠️ F3.

**11. App bar** ✅ `✕` + title. ❌ **stepper biến mất** — xem F1.

**12. List / card** ✅

**13. Filter / sort / chips** ➖

**14. CTA** ✅ Một primary, một secondary, cân kích thước. Cả hai đều là bước tiếp
hợp lý (xem thẻ vừa nhập / nhập tiếp).

**15. Scroll** ✅ Không cần cuộn.

**16. Responsive** ➖

**17. Safe area** ✅ **Bước duy nhất trong ba bước không đặt chữ dưới nút đáy.**

**18. Empty / loading / error** ✅ Đây là success state và nó giữ cấu trúc, có
hành động tiếp theo rõ.

**19. Content stress** ➖ Biến thể `_skips` và `_zero` có golden riêng nhưng không
nằm trong 29 màn của gallery.

**20. Interaction** ✅ Không có gì giả dạng nút.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | một điểm nhấn duy nhất |
| Grouping | 1 | container bọc một dòng |
| Alignment | 2 | |
| Spacing | 2 | 0 ngoài scale, không viền |
| Density | 1 | 55% màn trống |
| Typography | 2 | 3 rung, 2 weight |
| CTA | 2 | pair cân, cả hai đều là bước tiếp hợp lý |
| Responsive | 1 | chưa đo |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — Stepper biến mất ở bước 3.** ⚠️
Bước 1 và bước 2 đều có thanh `1 Source — 2 Preview — 3 Import` và breadcrumb.
Bước 3 không có cả hai. Người dùng mất mốc "tôi đang ở đâu" đúng vào lúc luồng
kết thúc — và cũng mất luôn khả năng nhìn thấy rằng cả ba bước đã xong.
Về mặt bố cục, ba màn của cùng một wizard đang có hai cấu trúc app bar khác nhau.
§1 nói các vùng chính phải phân chia rõ và nhất quán.
Giữ stepper với cả ba dấu ✓ sẽ vừa nhất quán vừa cho một cảm giác hoàn tất.

**F2 — ~55% màn là khoảng trống giữa.** ⚠️
Khối kết quả cao ~200px ở trên, hai nút ở đáy, giữa không có gì. Với một màn kết
thúc thì đây không phải lỗi, nhưng nó là chỗ mà một tóm tắt hữu ích có thể nằm —
ví dụ vài thẻ vừa được thêm.

**F3 — Thành công không được cấp màu, thất bại thì có.** ⚠️
Icon ✓ và chữ `Import complete` đều dùng màu trung tính. So với
[card_detail_page_error](card_detail_page_error.md), nơi khối lỗi có nền và chữ
màu error rõ ràng, và với [card_import_preview](card_import_preview.md), nơi chip
`Ready` có ✓ nhưng vẫn xám trong khi `Invalid` thì đỏ.
Nên hệ màu ngữ nghĩa của app hiện đang **bất đối xứng**: lỗi được tô, thành công
thì không. Đó có thể là chủ đích (không ăn mừng những việc tầm thường), nhưng nếu
vậy nó đáng được ghi lại làm quy tắc — vì hiện tại nó đọc như một chỗ bị bỏ quên.
