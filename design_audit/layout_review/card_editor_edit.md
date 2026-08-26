# Card editor

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_editor_edit.png` · commit `ea80d3f7`

Màn toàn trang, **không có bottom nav**, nên cả 7 rung typography đều là của nội
dung — không có phần chrome để trừ đi như các màn khác.

## Số đo

| | |
|---|---|
| Typography rungs | **7**, tất cả là nội dung |
| Rung | 22/600 (title) · 16/400/ls.5 (nội dung field) · 14/600 · 14/500 · 14/400 · 12/400 · 12/500 |
| Font weight | 400, 500, 600 |
| Spacer | 8×2, 12×3, 16×1, 24×2, 32×1 — **toàn bộ trên scale** |
| Inset | 8×10, 12×4, 16×4, 24×4 + **1×8 = bề rộng viền** |
| Trục text trái | 36 ×18 · 16 ×6 · 313 ×5 · 329 ×5 |
| Tap target | 11 chạm được, **3 dưới 48** |
| Target nhỏ | `Add details` 361×36 **không được phủ**; hai ✕ trên chip 16×16 → hit 44×48, **được chip 102×48 / 84×48 phủ** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ Back field cao ba dòng, chữ Việt có dấu hiển thị đủ |
| Không overlap | ✅ |
| Safe area | ➖ |
| Touch target | ❌ `Add details` cao 36 — xem F3 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ⚠️ Back field đã tự cao ba dòng ở 393px — hành vi đúng, xem §19 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ❌ **hai nút full-width tô đặc tranh nhau** — xem F1 |
| Grouping đúng | ⚠️ `Save changes` nằm **giữa** form — xem F2 |
| Alignment tốt | ✅ trục 36 (chữ trong field) ×18, trục 16 (padding màn) ×6 |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ✅ |
| Visual weight cân | ❌ hai khối đặc màu, một tím một đỏ, cùng bề rộng |
| CTA prominence | ❌ F1 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ nhãn notch `Front`/`Back` nằm đúng trên đường viền |
| Typography tinh tế | ⚠️ 7 rung, không có màn nào để chia bớt |
| Icon/text proportion | ✅ `+` 16px dẫn `Add details` |
| Surface/color hierarchy | ❌ **ba màu accent**: primary (Save), error (Danger), amber (cờ ở app bar) |
| Mắt đi đúng flow | ❌ mắt dừng ở khối đỏ, là thứ cuối cùng nó nên dừng |

## Checklist 20 mục

**1. Screen structure** ⚠️ Một mục tiêu rõ (sửa thẻ). Nhưng cấu trúc là
`nội dung → lưu → tags → xoá`, tức hành động kết thúc nằm ở giữa. Xem F2.

**2. Visual hierarchy** ❌ F1.

**3. Grouping** ⚠️ Front/Back là một nhóm ✅. Tags là một nhóm ✅. Danger zone
tách rõ ✅. Nhưng `Save changes` không thuộc nhóm nào — nó lơ lửng giữa nhóm nội
dung và nhóm tag.

**4. Alignment** ✅ Trục 36 dùng 18 lần. Field, nút, chip đều bắt đầu ở 16.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale; 8 inset 1px là viền field.

**6. Typography** ⚠️ 7 rung, tất cả là nội dung. Trên mốc 3–5.

**7. Component sizing** ⚠️ `Save changes` và `Delete card` cùng chiều cao ✅.
Nhưng `Add details` cao 36 trong khi mọi hành động khác cao 48+.

**8. Density** ✅ Thoáng, đúng cho một form.

**9. Balance** ❌ Hai khối đặc cùng bề rộng, cách nhau ~350px.

**10. Color hierarchy** ❌ F4.

**11. App bar** ✅ `✕` trái, title, một action phải. Đúng vị trí cho một màn form
toàn trang (đóng chứ không back).

**12. List / card** ➖ không có list.

**13. Filter / sort / chips** ✅ Hai chip tag cùng chiều cao 48, ✕ có target 44×48
nằm trong chip. Ô `Add tag` phân biệt rõ với chip đã có.

**14. CTA** ❌ F1 + F2.

**15. Scroll** ✅ Cuộn tự nhiên, có khoảng đệm đáy sau `Delete card`.

**16. Responsive** ➖ chính thức; ⚠️ trên thực tế field Back đã cần 3 dòng cho
tiếng Việt ở 393px, nên ở 360px nó sẽ là 4.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ chưa có golden cho trạng thái lưu / lỗi lưu.

**19. Content stress** ✅ **Đây là màn xử lý stress tốt nhất trong 29 màn**: nó
render chữ Hàn ở Front, một câu tiếng Việt có dấu dài 3 dòng ở Back, và hai chip
tag — cùng lúc. Field tự cao theo nội dung thay vì cắt.

**20. Interaction** ⚠️ `Add details` trông bấm được và bấm được, nhưng dưới sàn.
✕ trên chip nằm sát nhãn chip — hai vùng chạm cạnh nhau trong 102px.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 0 | hai nút full-width tô đặc |
| Grouping | 1 | Save không thuộc nhóm nào |
| Alignment | 2 | trục 36 ×18, rất sạch |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 2 | thoáng, đúng cho form |
| Typography | 1 | 7 rung |
| CTA | 0 | primary và destructive cùng độ nặng, Save đặt sai chỗ |
| Responsive | 1 | field co giãn đúng, nhưng chưa đo đa kích thước |
| **Tổng** | **9 / 16** | **Major layout revision** |

## Findings

**F1 — `Delete card` nặng ngang `Save changes`.** ❌
Cả hai đều full-width, cùng chiều cao, cùng tô đặc — khác mỗi màu. §14 nói
secondary action không được cạnh tranh với primary, và một hành động **phá huỷ**
còn phải nhẹ hơn thế nữa. Nhãn `Danger zone` phía trên có làm nhiệm vụ cảnh báo,
nhưng nó là chữ 14px trước một khối đỏ 48px — trọng lượng thị giác đi ngược lại
lời cảnh báo.
Hướng: `Delete card` thành outlined/text với màu error. Khối đặc dành cho hành
động người dùng muốn làm, không dành cho hành động họ cần cân nhắc.

**F2 — `Save changes` nằm giữa form.** ❌
Dưới nó còn hai vùng sửa được: Tags và Danger zone. Người dùng bấm Save rồi thêm
tag thì tag có được lưu không? Bố cục không trả lời. §14 nói CTA phải xuất hiện
đúng lúc người dùng cần.
Hai cách sạch: đưa Save xuống dưới cùng (sau tags, trước danger zone), hoặc cho
nó thành sticky bottom action.

**F3 — `Add details` là target 361×36.** ❌ Level 1.
Hit-test thật: 361×36, không nới, không nằm trong target nào lớn hơn. Rộng thì
thừa, cao thì thiếu 12px.
Sửa rẻ: cho nó chiều cao `AppSpacing.minimumTouchTarget`.

**F4 — Ba màu accent trên một màn.** ❌
Primary (Save), error (Danger zone + Delete), và amber cho cờ ở app bar. §10 nói
màu semantic không dùng để trang trí — cả ba đều **có** nghĩa ở đây, nên không
phải vi phạm nghĩa, mà là vi phạm số lượng: ba hệ màu cùng lúc trên một form
ngắn khiến không cái nào còn là tín hiệu.
Sửa F1 sẽ tự hạ khối đỏ xuống một bậc và giải quyết phần lớn.

**F5 — Hai ✕ trên chip rộng 44, dưới 48.** ⚠️ chấp nhận được.
Chúng **được** chip (102×48 và 84×48) phủ, nên chạm hụt vẫn rơi vào chip. Nhưng
chạm vào chip làm gì thì bố cục không nói — nếu chip cũng xoá tag thì ổn, nếu
không thì trượt tay sẽ không có phản hồi.
