# Fill

Study · `lib/features/study/presentation/` · golden
`test/demo/goldens/study_fill_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **7**, tất cả là nội dung |
| Rung | **16/400/ls.5 (từ được hỏi)** · 14/600 (nhãn nút) · 14/400 · 12/600/ls1.1 · 12/600/ls.5 · 12/400 · 11/500/ls1.1 |
| Font weight | 400, 500, 600 |
| Spacer | 8×1, 12×1, 16×3 — **toàn bộ trên scale** |
| Inset | 4×2, 8×2, 12×4, 16×16, 24×4 + 2×1 và 40×1 từ `MxSessionTopBar` |
| Trục text trái | 324 ×3 · 16 ×3 · 76 ×3 · 261 ×3 · 122 ×3 |
| Tap target | 4 chạm được, **0 dưới 48** |
| Hai thẻ | mỗi thẻ ≈ **730px hiển thị**, viền và nền **giống hệt nhau** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ⚠️ dòng hướng dẫn sát mép dưới |
| Touch target | ✅ 4/4 |
| Text đọc được | ✅ |
| Component đúng chức năng | ❌ **ô nhập không trông giống ô nhập** — xem F1 |
| Responsive | ➖ **và bàn phím chưa được xét** — xem F4 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ❌ **từ được hỏi là 16/400**, nhỏ hơn nhãn nút — xem F2 |
| Grouping đúng | ✅ hai thẻ tách rõ, cặp nút thuộc khối dưới |
| Alignment tốt | ✅ |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ❌ ~73% màn là hai thẻ gần rỗng, như [study_recall](study_recall.md) F1 |
| Visual weight cân | ❌ không phần tử nào đủ nặng để làm điểm nhấn |
| CTA prominence | ✅ `Check` disabled rõ ràng, `Show hint` outlined |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ❌ |
| Optical alignment | ✅ |
| Typography tinh tế | ❌ 7 rung và **không rung nào đóng vai điểm nhấn** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ⚠️ hai surface giống hệt nhau cho hai vai trò khác nhau — F1 |
| Mắt đi đúng flow | ❌ mắt không có chỗ để bám vào |

## Checklist 20 mục

**1. Screen structure** ⚠️ Ba phần rõ về vị trí, nhưng không rõ về vai trò: hai
thẻ trông y hệt nhau nên phải đọc chữ mới biết cái nào hỏi, cái nào trả lời.

**2. Visual hierarchy** ❌ F2.

**3. Grouping** ✅

**4. Alignment** ✅

**5. Spacing & rhythm** ✅ Giá trị app đều trên scale.

**6. Typography** ❌ 7 rung, cỡ lớn nhất là 16 — **không màn nào khác trong nhóm
Study có cấp 1 nhỏ đến thế**.

**7. Component sizing** ✅ Hai nút cùng kích thước qua `MxButtonPair`.

**8. Density** ❌ Cùng F1 của [study_recall](study_recall.md).

**9. Balance** ❌

**10. Color hierarchy** ⚠️ Primary chỉ ở chip chế độ và thanh tiến độ — nút
`Check` đang disabled nên màn **không có** phần tử primary nào ở vùng nội dung.
Đúng về trạng thái, nhưng cộng với F2 thì màn thành ra phẳng lì.

**11. App bar** ✅ `2 / 5` trở lại đúng vị trí — khác [study_recall](study_recall.md)
F2.

**12. List / card** ➖

**13. Filter / sort / chips** ➖

**14. CTA** ✅ **Disabled state rõ ràng** (§14): `Check` xám hẳn khi chưa gõ gì,
và có `Show hint` làm lối thoát. Cặp nút cân kích thước.

**15. Scroll** ✅ ⚠️ Nhưng xem F4 về bàn phím.

**16. Responsive** ➖

**17. Safe area** ⚠️

**18. Empty / loading / error** ➖ Sáu biến thể (`_typing`, `_correct`,
`_incorrect`, `_hint`, `_keyboard`, `_long_meaning`) có golden riêng ngoài 29 màn
— **coverage tốt nhất trong toàn bộ app**.

**19. Content stress** ➖ ở golden này; `study_fill_long_meaning` phủ ca dài.

**20. Interaction** ❌ F1.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 0 | cấp 1 là 16/400, nhỏ hơn nhãn nút |
| Grouping | 2 | ba khối tách rõ về vị trí |
| Alignment | 2 | |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 0 | 73% màn là hai thẻ gần rỗng |
| Typography | 0 | 7 rung, không rung nào làm điểm nhấn |
| CTA | 2 | disabled rõ, cặp nút cân, có lối thoát |
| Responsive | 1 | chưa đo, và bàn phím chưa được xét |
| **Tổng** | **9 / 16** | **Major layout revision** |

## Findings

**F1 — Ô nhập trông giống hệt thẻ hỏi.** ❌
Thẻ dưới là một `TextField`, nhưng nó có **cùng viền, cùng nền, cùng bo góc, cùng
chiều cao** với thẻ hỏi phía trên. Không gạch chân, không con trỏ nhìn thấy, không
icon bàn phím. Thứ duy nhất phân biệt là chữ mờ `Type the answer` nằm giữa một
khối 730px.
§20 nói thành phần không clickable không được trông giống nút — mặt còn lại cũng
đúng: một ô nhập phải **trông** như ô nhập. Ở [card_editor_edit](card_editor_edit.md),
field có viền notch và nhãn nổi; ở [tag_rename_merge](tag_rename_merge.md), field
focus có viền primary và con trỏ. Ở đây thì không có gì.

**F2 — Từ được hỏi là 16/400, nhỏ hơn nhãn nút (14/600 nhưng đậm hơn).** ❌
[study_guess](study_guess.md) và [study_recall](study_recall.md) dùng
**30/600/ls−0.5** cho đúng vai trò này — thứ người dùng phải nhìn để trả lời.
Fill dùng 16/400, tức rung dành cho **nội dung phụ**.
Kết quả: màn không có điểm nhấn cấp 1 nào. Ba chế độ cùng một feature, cùng một
vai trò ngữ nghĩa, hai rung khác nhau — và cái sai là cái duy nhất khác biệt.
Sửa: dùng lại rung 30/600 của Guess/Recall.

**F3 — Hai thẻ 730px cho một từ và một placeholder.** ❌
Giống hệt [study_recall](study_recall.md) F1. Bốn chế độ (Browse, Guess, Recall,
Fill) đều dùng khung thẻ cố định nửa màn bất kể nội dung. Đây là **một** quyết
định thiết kế cần xem lại, không phải bốn lỗi riêng.

**F4 — Bàn phím chưa được xét trong ảnh này.** ➖ → rủi ro.
Khi bàn phím mở, ~40% chiều cao màn biến mất. Cặp nút `Show hint`/`Check` và dòng
hướng dẫn nằm ở đáy — chúng sẽ bị đẩy lên hoặc bị che.
`study_fill_keyboard` có golden riêng và **đó là điều đúng cần làm**; nó chỉ
không nằm trong 29 màn của gallery nên không được chấm ở đây. Ghi lại để người
đọc biết câu hỏi này **đã** có câu trả lời ở chỗ khác.
