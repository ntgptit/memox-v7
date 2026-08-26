# Recall

Study · `lib/features/study/presentation/` · golden
`test/demo/goldens/study_recall_light.png` · commit `ea80d3f7`

Đếm ngược + tự chấm. Đáp án bị làm mờ cho tới khi bấm `Show answer`.

## Số đo

| | |
|---|---|
| Typography rungs | **6**, tất cả là nội dung |
| Rung | 30/600/ls−0.5 (từ) · 14/600 (nhãn nút) · 12/600/ls1.1 · 12/600/ls.5 · 12/400 · 11/500/ls1.1 |
| Font weight | 400, 500, 600 |
| Spacer | 8×1, 12×1, 16×3 — **toàn bộ trên scale** |
| Inset | 4×2, 8×2, 12×2, 16×16, 24×2 + 2×1 và 40×1 từ `MxSessionTopBar` |
| Trục text trái | 306 ×5 · 16 ×3 · 150 ×3 · 114 ×3 |
| Tap target | **2 chạm được** (`✕`, `Show answer`), **0 dưới 48** |
| Hai thẻ | mỗi thẻ ≈ **730px hiển thị**; thẻ trên chứa 1 từ, thẻ dưới chứa **một vệt mờ** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ⚠️ dòng hướng dẫn sát mép dưới |
| Touch target | ✅ 2/2 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ vệt mờ nói rõ "có gì đó ở đây, chưa cho xem" |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ từ 30/600 là cấp 1, `Show answer` là CTA duy nhất |
| Grouping đúng | ✅ hai thẻ tách rõ; nút thuộc về khối dưới |
| Alignment tốt | ✅ |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ❌ **~73% màn là hai thẻ gần như rỗng** — xem F1 |
| Visual weight cân | ⚠️ hai khối lớn bằng nhau nhưng một cái không chứa gì |
| CTA prominence | ✅ một nút đặc, đúng chỗ |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ❌ F1 |
| Optical alignment | ✅ từ căn giữa thẻ; vệt mờ căn giữa thẻ dưới |
| Typography tinh tế | ✅ 6 rung |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ primary hai chỗ (chip chế độ, nút) |
| Mắt đi đúng flow | ⚠️ mắt đi qua một vùng trống rất dài giữa từ và nút |

## Checklist 20 mục

**1. Screen structure** ✅ Câu hỏi → chỗ giấu đáp án → nút mở. Ba phần, đọc được
ngay.

**2. Visual hierarchy** ✅ Một điểm nhấn cấp 1.

**3. Grouping** ✅ Hai thẻ riêng biệt nói rõ "đây là hai mặt".

**4. Alignment** ✅

**5. Spacing & rhythm** ✅ Giá trị app đều trên scale.

**6. Typography** ✅ 6 rung; dùng lại rung 30/600 của
[study_guess](study_guess.md) cho từ hỏi — **nhất quán xuyên chế độ**.

**7. Component sizing** ✅ Hai thẻ bằng nhau — đúng, chúng là hai mặt ngang hàng.

**8. Density** ❌ F1.

**9. Balance** ⚠️

**10. Color hierarchy** ✅

**11. App bar** ⚠️ **Ô bên phải đổi nghĩa theo chế độ** — xem F2.

**12. List / card** ➖

**13. Filter / sort / chips** ➖

**14. CTA** ✅ Một nút đặc, nhãn nói đúng hành động. Không full-width — hợp lý cho
một nút đơn lẻ ở giữa.

**15. Scroll** ✅ Vừa một màn.

**16. Responsive** ➖ Với đáp án dài (như ca đã lộ ở [study_guess](study_guess.md)
F1), thẻ dưới sẽ đầy — nhưng golden này không cho thấy trạng thái đã mở.

**17. Safe area** ⚠️

**18. Empty / loading / error** ➖ `recall_counting_down`, `recall_self_assess` và
`recall_timed_out` có golden riêng ngoài 29 màn — **ba trạng thái, coverage tốt**.

**19. Content stress** ➖ Chỉ có từ ngắn.

**20. Interaction** ✅ Vệt mờ **trông không bấm được và không bấm được** — nút
riêng làm việc đó. Đúng §20.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | một cấp 1, một CTA |
| Grouping | 2 | hai mặt tách rõ |
| Alignment | 2 | |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 0 | **73% màn là hai thẻ gần như rỗng** |
| Typography | 2 | 6 rung, dùng lại rung của Guess |
| CTA | 2 | một nút, nhãn đúng hành động |
| Responsive | 1 | chưa đo trạng thái đã mở đáp án |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — Hai thẻ chiếm 73% màn cho một từ và một vệt mờ.** ❌ **Mật độ tệ nhất
trong 29 màn.**
Thẻ trên ~730px hiển thị chứa đúng một từ 30px. Thẻ dưới ~730px chứa một vệt mờ
cao ~30px. Tổng cộng ~1 460/2 000 pixel màn hình để truyền tải "từ này là gì" và
"đáp án đang bị giấu".
§8 nói màn không nên quá trống. §9 nói thành phần lớn phải được bù bởi whitespace
**hợp lý** — ở đây whitespace *là* thành phần.

Đây là biến thể nặng nhất của cùng một khiếm khuyết ở
[study_browse](study_browse.md) F2 và [study_guess](study_guess.md) F2: khung thẻ
cố định chiếm nửa màn bất kể nội dung. Ba chế độ, một gốc.
Hướng: thẻ co theo nội dung, giữ chiều cao tối thiểu; phần dư trả cho khoảng
trống giữa hai thẻ thay vì nằm bên trong chúng.

**F2 — `19s left` chiếm chỗ của bộ đếm thẻ.** ⚠️
Ở [study_browse](study_browse.md), [study_match](study_match.md) và
[study_guess](study_guess.md), ô bên phải thanh phiên là `2 / 5` — đang ở thẻ
mấy trên mấy. Ở Recall nó là `19s left`.
Nên trong chế độ Recall người dùng **mất** thông tin tiến độ phiên, và đổi lại
nhận một thông tin khác ở đúng chỗ mắt đã học là "tiến độ". Hai ý nghĩa dùng
chung một vị trí là chỗ dễ đọc nhầm nhất.
Thanh tiến độ bên trái vẫn chạy, nhưng nó không mang số.
Hướng: giữ `2 / 5` ở vị trí cũ và đưa đếm ngược vào chính thanh tiến độ (đổi màu
hoặc chạy ngược), hoặc cho nó một ô riêng.

**F3 — Vệt mờ là một affordance tốt.** ✅ ghi lại.
Nó nói được ba điều cùng lúc mà không cần chữ: có nội dung ở đây, nội dung đó là
một dòng ngắn, và bạn chưa được xem. Nó cũng **không** giả dạng nút — việc mở
thuộc về `Show answer`, đúng §20.
