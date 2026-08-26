# Daily reminder

Settings & Reminder · `lib/features/settings/presentation/` · golden
`test/demo/goldens/reminder_settings_light.png` · commit `ea80d3f7` · UC-17

Opt-in, giờ địa phương.

## Số đo

| | |
|---|---|
| Typography rungs | **3** — **ngang [tag_catalog](tag_catalog.md) và [card_import_result_complete](card_import_result_complete.md), sạch nhất** |
| Rung | 22/600 (title) · 16/400 (nhãn hàng) · 14/400 (giá trị + trợ giúp) |
| Font weight | **400, 600 — chỉ hai** |
| Spacer | 8×1, 16×1 — **toàn bộ trên scale** |
| Inset | 4×4, 8×2, 16×8 — **toàn bộ trên scale, không có 1px viền** |
| Trục text trái | 32 ×10 (trong thẻ) · 16 ×6 (ngoài thẻ) |
| Tap target | **2 chạm được**, **0 dưới 48** |
| Khoảng trống | ~**72% chiều cao màn** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ➖ |
| Touch target | ✅ 2/2 |
| Text đọc được | ✅ |
| Component đúng chức năng | ⚠️ **hàng `Reminder time` bấm được nhưng không trông bấm được** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ hai hàng, hai vai trò rõ |
| Grouping đúng | ✅ hai hàng trong một thẻ; trợ giúp đặt **ngoài** thẻ ở trục 16 — phân biệt đúng |
| Alignment tốt | ✅ hai trục, 32 trong thẻ và 16 ngoài thẻ |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ❌ **72% màn trống** — xem F3 |
| Visual weight cân | ❌ toàn bộ nội dung nằm trong 28% trên |
| CTA prominence | ➖ không có CTA; toggle là hành động |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ❌ F3 |
| Optical alignment | ✅ toggle căn theo dòng nhãn |
| Typography tinh tế | ✅ **3 rung, 2 weight** |
| Icon/text proportion | ➖ không có icon — và đó là một phần của F1 |
| Surface/color hierarchy | ✅ primary đúng một chỗ (toggle bật) |
| Mắt đi đúng flow | ✅ bật → đặt giờ → đọc điều kiện |

## Checklist 20 mục

**1. Screen structure** ⚠️ Một mục tiêu rõ. Nhưng title app bar và nhãn hàng đầu
tiên **là cùng một chữ** — `Daily reminder` xuất hiện hai lần trong 250px đầu.
Xem F2.

**2. Visual hierarchy** ✅ Hai hàng phân biệt bằng cấu trúc (một có toggle, một có
giá trị dưới nhãn).

**3. Grouping** ✅ **Trợ giúp đặt ngoài thẻ** ở trục 16 trong khi nội dung thẻ ở
32 — phân biệt "đây là cài đặt" với "đây là giải thích" bằng cả container lẫn
trục. Làm đúng.

**4. Alignment** ✅ Hai trục, mỗi trục một vai trò.

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale, không viền sinh padding.

**6. Typography** ✅ **3 rung, 2 weight** — mức sạch nhất trong 29 màn.

**7. Component sizing** ✅

**8. Density** ❌ F3.

**9. Balance** ❌

**10. Color hierarchy** ✅ Primary đúng một chỗ, và nó mang nghĩa "đang bật".

**11. App bar** ⚠️ F2.

**12. List / card** ⚠️ Hai hàng trong thẻ, nhưng chỉ hàng thứ hai bấm được và
không có gì nói điều đó — F1.

**13. Filter / sort / chips** ➖

**14. CTA** ➖ Không có, đúng cho một màn cài đặt hai dòng.

**15. Scroll** ✅ Không cần cuộn.

**16. Responsive** ➖ Câu trợ giúp thứ hai đã hai dòng ở 393px; ở tiếng Việt sẽ
là ba. Còn nhiều chỗ nên không vỡ.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ Trạng thái tắt (toggle off, hàng giờ ẩn hoặc
mờ) chưa có golden.

**19. Content stress** ➖

**20. Interaction** ⚠️ F1. Toggle thì rõ ràng ✅.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | hai hàng, hai vai trò rõ |
| Grouping | 2 | trợ giúp ngoài thẻ, trục riêng |
| Alignment | 2 | hai trục, mỗi trục một vai trò |
| Spacing | 2 | 0 ngoài scale |
| Density | 0 | 72% màn trống |
| Typography | 2 | 3 rung, 2 weight |
| CTA | 1 | hàng đặt giờ không có affordance |
| Responsive | 1 | chưa đo |
| **Tổng** | **12 / 16** | **Minor fix** |

## Findings

**F1 — `Reminder time · 8:00 PM` bấm được nhưng không trông bấm được.** ⚠️
Đo được 2 target: toggle và **hàng giờ**. Nên hàng đó mở bộ chọn giờ. Nhưng nó
không có chevron, không có gạch chân, không có icon đồng hồ, không có nền khác —
nó trông giống hệt một dòng hiển thị giá trị.
So sánh trong cùng app: [settings](settings.md) dùng radio để nói "chọn được";
[card_import_preview](card_import_preview.md) dùng mũi tên dropdown; deck tile
dùng ⋮. Ở đây không có tín hiệu nào.
§20 nói thành phần trông clickable phải clickable — mặt còn lại cũng đúng, và
đây là mặt bị bỏ sót thường xuyên hơn. Thêm một chevron là đủ.

**F2 — `Daily reminder` xuất hiện hai lần trong 250px.** ⚠️
Title app bar và nhãn hàng toggle trùng nhau. Với một màn chỉ có hai hàng, sự
lặp này chiếm tỉ lệ lớn trong toàn bộ chữ trên màn.
Đổi nhãn hàng thành `Enabled` hoặc `Remind me daily` sẽ gỡ trùng và làm hàng nói
đúng điều nó điều khiển.

**F3 — 72% chiều cao màn là khoảng trống.** ❌
Đây là **tỉ lệ trống cao nhất trong 29 màn**. Toàn bộ nội dung nằm trong 28%
trên, phần còn lại không có gì.
Không phải lỗi nghiêm trọng — màn này thật sự chỉ có hai cài đặt — nhưng §8 hỏi
"không quá trống", và ở đây câu trả lời là có. Hai lối:
- gộp màn này vào [settings](settings.md) thành một section thứ tư, bỏ hẳn một
  màn khỏi app;
- hoặc dùng chỗ trống cho một bản xem trước thông báo, thứ mà câu trợ giúp thứ
  hai đang phải mô tả bằng chữ (`can show a deck name and how many cards are
  due, including on your lock screen`).

Lối thứ nhất đáng cân nhắc hơn: màn này có đúng hai dòng, và
[settings](settings.md) đã có ba nhóm cùng dạng.
