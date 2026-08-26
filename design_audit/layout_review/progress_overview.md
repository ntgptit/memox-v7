# Progress — tổng quan

Progress · `lib/features/progress/presentation/` · golden
`test/demo/goldens/progress_overview_light.png` · commit `ea80d3f7` · UC-12

**Golden này không có bottom navigation** dù Progress là một tab — xem
[README](README.md). Và nó được dựng khác cách với `progress_deck`, nên hai
golden của cùng feature không so trực tiếp được.

## Số đo

| | |
|---|---|
| Typography rungs | **8**, tất cả là nội dung |
| Rung | **57/700** (streak) · 24/600 · 22/600 · 16/600 · 14/600 · 14/400 ×60 · 12/400 · 12/500 |
| Font weight | 400, 500, 600, **700** |
| Spacer | 4×2, 8×7, 12×3, 24×2 — **toàn bộ trên scale** |
| Inset | 4×33, 8×33, 12×2, 16×26, 24×2 + **1×8 = viền của 4 thẻ** |
| Trục text trái | **32 ×40** · 337 ×14 · 60 ×12 · 232 ×12 |
| Tap target | **2 chạm được** (hai chip khoảng thời gian), **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ➖ không kiểm được — golden thiếu thanh nav |
| Touch target | ✅ 2/2 |
| Text đọc được | ✅ |
| Component đúng chức năng | ⚠️ **biểu đồ bị một giá trị ngoại lai làm vô dụng** — xem F2 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ⚠️ `5 days` ở 57/700 áp đảo mọi thứ khác — xem F1 |
| Grouping đúng | ❌ **chip lọc nằm giữa hai thẻ, không rõ nó điều khiển cái nào** — xem F3 |
| Alignment tốt | ✅ trục 32 ×40 cho nhãn, hai trục phải cho giá trị |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ ba thẻ + một hàng chip trong một viewport, thẻ thứ tư mới lộ mép |
| Visual weight cân | ❌ thẻ streak nặng gấp nhiều lần mọi thẻ khác |
| CTA prominence | ➖ màn đọc, không có CTA — hợp lý |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ số căn phải trên cùng hai trục |
| Typography tinh tế | ⚠️ 8 rung, **4 weight**, và một rung 57px chỉ dùng một lần |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ primary chỉ ở thanh biểu đồ và chip đang chọn |
| Mắt đi đúng flow | ⚠️ mắt bị `5 days` giữ lại quá lâu trước khi xuống nội dung thật |

## Checklist 20 mục

**1. Screen structure** ⚠️ Mục tiêu rõ. Nhưng **số 8 được nói ba lần trong một
viewport** — xem F4.

**2. Visual hierarchy** ⚠️ Đúng một điểm nhấn cấp 1 (`5 days`), nhưng nó lớn tới
mức thẻ thứ hai và thứ ba đọc như chú thích. F1.

**3. Grouping** ❌ F3.

**4. Alignment** ✅ Trục 32 dùng 40 lần; giá trị căn phải ở 337 (biểu đồ) và 232
(bảng Learning/Reviewing). Hai trục phải khác nhau cho hai bảng khác nhau — hợp
lý, chúng ở hai thẻ.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ⚠️ 8 rung, 4 weight. Rung 57/700 dùng đúng **một** lần.

**7. Component sizing** ✅ Bốn thẻ cùng padding, cùng bo góc, cùng viền.

**8. Density** ⚠️ Ba thẻ rưỡi trong viewport đầu. Với một màn thống kê thì chấp
nhận được, nhưng thẻ streak chiếm ~17% chỉ để nói một con số.

**9. Balance** ❌ F1.

**10. Color hierarchy** ✅ Primary hai chỗ, cả hai mang nghĩa. **Không dùng màu
ngữ nghĩa (đỏ/vàng/xanh) ở đâu** — đúng, đây là số liệu chứ không phải trạng thái.

**11. App bar** ✅ Title đơn giản, không action. Đúng cho màn đọc.

**12. List / card** ⚠️ Bốn thẻ, **không thẻ nào bấm được** (2 target đo được đều
là chip). Thẻ có viền và bo góc — hình thức giống thẻ deck vốn bấm được. Ranh
giới giữa "thẻ container" và "thẻ bấm được" đang mờ giữa các feature.

**13. Filter / sort / chips** ❌ F3. Ngoài ra hai chip cùng chiều cao ✅, selected
state (nền nhạt + ✓ + viền primary) rõ ✅.

**14. CTA** ➖

**15. Scroll** ✅

**16. Responsive** ➖ Nhãn `Learning`/`Reviewing` ngắn; ở tiếng Việt
(`Đang học` / `Đang ôn`) vẫn ngắn. Rủi ro thấp.

**17. Safe area** ➖ Không kiểm được.

**18. Empty / loading / error** ➖ `progress_error_face` có test riêng nhưng không
có golden trong 29 màn. Trạng thái "chưa học ngày nào" chưa có ảnh.

**19. Content stress** ⚠️ Fixture **có** ca ngoại lai (`Sun 143`) — và nó lộ F2.

**20. Interaction** ⚠️ Xem §12: thẻ trông như thẻ bấm được nhưng không bấm được.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 1 | một cấp 1 nhưng nó áp đảo phần còn lại |
| Grouping | 0 | **chip lọc không rõ điều khiển thẻ nào** |
| Alignment | 2 | trục 32 ×40, hai trục phải hợp lý |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 1 | thẻ streak 17% cho một con số |
| Typography | 1 | 8 rung, 4 weight, rung 57px dùng một lần |
| CTA | 2 | không có CTA là đúng cho màn đọc |
| Responsive | 1 | chưa đo, thiếu thanh nav trong ảnh |
| **Tổng** | **10 / 16** | **Major layout revision** |

## Findings

**F1 — `5 days` ở 57/700 áp đảo màn.** ⚠️
Đây là cỡ chữ **lớn nhất trong toàn bộ 29 màn** — gần gấp đôi numeral hero của
deck list (32/700). Nó chiếm ~180px chiều cao cho một con số, và làm hai thẻ dưới
đọc như chú thích.
Câu hỏi thiết kế: streak có phải thứ quan trọng nhất trên màn Progress không?
Nếu có thì cỡ này hợp lý. Nếu thứ người dùng vào đây để xem là **xu hướng học**,
thì phần tử lớn nhất đang là phần tử ít thông tin nhất.

**F2 — Một giá trị ngoại lai làm biểu đồ vô dụng.** ⚠️
`Sun 143` so với 12, 0, 6, 3, 9, 8. Trên thang tuyến tính, thanh của Sun chiếm
trọn chiều rộng còn sáu thanh kia gần như không phân biệt được với nhau — `Mon 3`
là một vệt 6px, `Sat 6` và `Today 8` trông như nhau.
Biểu đồ tồn tại để so sánh, và ở đây nó không so sánh được gì ngoài "có một ngày
rất nhiều". Con số bên phải đang gánh toàn bộ thông tin.
Hướng: cắt trục ở phân vị 90, hoặc dùng thang căn bậc hai, hoặc đơn giản là bỏ
thanh và giữ bảng số — bảng số vẫn đọc được.

**F3 — Chip `7 days / 30 days` nằm giữa hai thẻ.** ❌
Phía trên chúng là thẻ `Daily activity` (đang hiển thị 7 ngày). Phía dưới là thẻ
`Last 7 days`. Chip nằm chính giữa, không dính vào thẻ nào.
§3 nói khoảng cách trong nhóm phải nhỏ hơn khoảng cách giữa các nhóm — ở đây nó
bằng nhau, nên chip mồ côi. §13 nói filter phải có hierarchy thấp hơn nội dung và
không gây hỗn loạn.
Người dùng không có cách nào biết đổi sang `30 days` sẽ đổi thẻ nào — và cả hai
thẻ đều đang nói "7 ngày".
Hướng: đưa chip vào **trong** thẻ mà nó điều khiển, trên cùng hàng với tiêu đề
thẻ đó.

**F4 — Số `8` được nói ba lần trong một viewport.** ⚠️
`8 cards today` (thẻ streak) · `Today · 8 cards` + `Reviewing 8` (thẻ hôm nay) ·
`Today 8` (biểu đồ). Bốn lần nếu tính cả `Reviewing`.
Không sai — mỗi lần ở một ngữ cảnh khác — nhưng ba thẻ liên tiếp mở đầu bằng cùng
một con số làm màn đọc như đang lặp. Thẻ streak có thể bỏ dòng `8 cards today`,
vì thẻ ngay dưới nó nói kỹ hơn.
