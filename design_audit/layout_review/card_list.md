# Card list

Card · `lib/features/card/presentation/screens/` · golden
`test/demo/goldens/card_list_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **11 — không có bottom nav trong golden này**, cả 11 là nội dung |
| Rung nội dung | 22/600 · 16/600 · 14/400 · 14/600 · 12/600 · 12/400 · **11/600/ls.6** · **11/500/ls1.1** |
| Font weight | 400, 500, 600 |
| Spacer | 4×7, 8×5, 12×7 — **toàn bộ trên scale** |
| Inset | 4×14, 8×29, 12×3, 16×26, 24×3 + **1×20 = bề rộng viền** (xem README) |
| Trục text trái | 54 ×30 · 16 ×5 · 44 ×4 · 112 ×6 · 329 ×6 |
| Tap target | 15 chạm được, **1 dưới 48** |
| Target nhỏ | `InkWell` 59×24 @(318,496) — control sort `Newest ⌄`, không được phủ |

Chiều dọc trước card đầu tiên: app bar + breadcrumb + ô tìm + hàng chip + panel
tiến độ + dòng `Showing 7 of 142` ≈ **62% viewport**.

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ❌ **chip `Flagged` bị cắt giữa chữ thành `Fla`** — xem F1 |
| Không overlap | ⚠️ chip `Tags` nằm đè lên mép chip bị cắt, không có fade hay vạch |
| Safe area | ➖ |
| Touch target | ❌ control sort 59×24 — xem F2 |
| Text đọc được | ⚠️ nhãn trạng thái ở **11px** — xem F4 |
| Component đúng chức năng | ✅ |
| Responsive | ➖ — nhưng F1 đã là dấu hiệu ở 393px, chưa cần tới 360 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ⚠️ `Start study · 61 cards` là CTA cấp 1 rõ, nhưng nó nằm sau 5 dải chrome |
| Grouping đúng | ✅ mỗi card gom dot + từ + nghĩa + trạng thái thành một khối đọc được |
| Alignment tốt | ✅ trục 54 dùng 30 lần — cột chữ của card rất nhất quán |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ❌ **chỉ 2 card trong viewport đầu trên một màn có 142 card** — xem F3 |
| Visual weight cân | ❌ đầu màn nặng gấp nhiều lần phần list |
| CTA prominence | ✅ một CTA tô đặc duy nhất |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ |
| Optical alignment | ⚠️ dot trạng thái căn theo dòng đầu, lệch quang học nhẹ so với chữ Hàn cao hơn |
| Typography tinh tế | ❌ 11 rung nội dung, có **hai** cỡ dưới 12 |
| Icon/text proportion | ✅ icon 16 trong chip 34 |
| Surface/color hierarchy | ⚠️ **năm** màu ngữ nghĩa cùng lúc trong legend (New/Beginning/Reviewing/Mastered + primary) |
| Mắt đi đúng flow | ❌ mắt phải vượt 62% màn mới tới nội dung màn này mang tên |

## Checklist 20 mục

**1. Screen structure** ⚠️ Mục tiêu chính không rõ trong 2–3 giây: màn tên là
"card list" nhưng thứ chiếm chỗ nhất là một panel tiến độ. Có **hai** mục tiêu
ngang hàng — xem/lọc thẻ, và bắt đầu học.

**2. Visual hierarchy** ⚠️ `44 of 142 mastered` (16/600) và `Start study · 61
cards` cùng tranh vai trò cấp 1 với title deck.

**3. Grouping** ✅ Bốn nhóm rõ: tìm kiếm, lọc, tiến độ, danh sách.

**4. Alignment** ✅ Trục 54 ×30 — cột chữ trong card cực kỳ nhất quán. Trục 16 là
padding màn.

**5. Spacing & rhythm** ✅ Mọi giá trị của app đều trên scale; 20 inset 1px là bề
rộng viền, đã truy nguồn.

**6. Typography** ❌ **11 rung nội dung**, vượt xa mốc 3–5. Hai rung **dưới 12px**
(`11/600/ls.6` cho `NEW`/`MASTERED`, `11/500/ls1.1` cho pill `now`).

**7. Component sizing** ⚠️ Chip lọc cao 34, control sort cao 24, pill `now` cao
24 — ba chiều cao cho ba thứ cùng hạng "điều khiển nhỏ".

**8. Density** ❌ F3.

**9. Balance** ❌ Xem F3.

**10. Color hierarchy** ⚠️ Bốn màu trạng thái (xanh dương / vàng / tím / xanh lá)
+ primary. Chúng là **ngữ nghĩa thật** nên không vi phạm "không dùng semantic để
trang trí", nhưng năm màu cùng lúc là nhiều.

**11. App bar** ⚠️ Ba action bên phải (chọn nhiều, thêm, menu) — đúng mốc "không
quá nhiều", nhưng breadcrumb `All decks / … / Korean / Korean · TOPIK I` đã phải
rút gọn bằng `…` ngay ở 393px.

**12. List / card** ✅ Mỗi card có hierarchy rõ, metadata (`now`) không tranh với
từ. ⚠️ Trạng thái được nói **ba lần** trên một card: chấm màu, nhãn chữ
(`MASTERED`), và ở một số card là pill thời gian.

**13. Filter / sort / chips** ❌ F1. Ngoài ra chip lọc và control sort có hierarchy
khác nhau (chip có viền, sort là text) — đúng, sort thấp hơn.

**14. CTA** ✅ Một primary CTA duy nhất, rõ ràng.

**15. Scroll** ⚠️ Có nested scroll (hàng chip ngang trong trang dọc) — chuẩn mực
và chấp nhận được. Nhưng F1 khiến nó **không** trông như thứ cuộn được.

**16. Responsive** ➖ chính thức. Thực tế F1 cho thấy 393px đã chật.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ chưa có golden cho card list rỗng.

**19. Content stress** ⚠️ Có chữ Hàn + Việt có dấu, tốt. Chưa có từ dài, chưa có
0/1 item.

**20. Interaction** ⚠️ F2: control sort trông bấm được và bấm được, nhưng nhỏ hơn
sàn. Chip bị cắt trông **hỏng** chứ không trông như cuộn được.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 1 | hai mục tiêu ngang hàng tranh chỗ |
| Grouping | 2 | bốn nhóm rõ ràng |
| Alignment | 2 | trục 54 dùng 30 lần |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 0 | 2 card hiện trên 142 |
| Typography | 0 | 11 rung nội dung, hai cỡ dưới 12px |
| CTA | 2 | đúng một primary |
| Responsive | 0 | **đã tràn ở kích thước đang đo** |
| **Tổng** | **9 / 16** | **Major layout revision** |

## Findings

**F1 — Chip `Flagged` bị cắt thành `Fla`.** ❌ Level 1.
Ở 393px hàng chip lọc không đủ chỗ, và chip thứ tư bị cắt **giữa chữ**, ngay sát
chip `Tags` mà không có fade, vạch, hay bất cứ dấu hiệu nào nói "cuộn tiếp". Kết
quả là nó đọc thành một lỗi render chứ không phải một dải cuộn được.
§13 nói horizontal scroll không được gây layout hỗn loạn; §16 nói không truncate
dữ liệu quan trọng. Đây là cả hai, và nó xảy ra ở **kích thước mặc định**, chưa
cần tới 360px hay text scale lớn.
Hướng: fade mép phải, hoặc `Wrap` hai hàng, hoặc rút nhãn chip.

**F2 — Control sort `Newest ⌄` là 59×24.** ❌ Level 1.
Hit-test thật xác nhận 59×24, không nới, và **không nằm trong một target lớn
hơn**. Dưới sàn 48 ở cả hai chiều.
Đây đúng là vấn đề mà deck list đã giải: ở đó control sort được cho hẳn 48 chiều
cao và có ghi lý do vì sao row phải cao bằng nó. Card list chưa nhận thay đổi
đó. Sửa được bằng cách dùng lại `MxTextButton` như `DeckListToolbarWidget`.

**F3 — 62% viewport đầu tiên là chrome, còn lại 2 card trên 142.** ❌
Trước card đầu có: app bar, breadcrumb, ô tìm, hàng chip, panel tiến độ (donut +
4 dòng legend + CTA), dòng `Showing 7 of 142`. Panel tiến độ một mình cao ~26%
màn.
Đây **cùng một khiếm khuyết** mà deck list vừa trải qua bốn vòng để sửa: một
panel tóm tắt nuốt mất danh sách mà màn hình mang tên. Ở deck list, hero cuối
cùng còn 14% và ba card hiện trọn.
Hướng rẻ nhất, đúng bài đã dùng: cho legend 4 dòng vào sau một chevron như hero
của deck list, giữ donut + `44 of 142 mastered` + CTA.

**F4 — Hai cỡ chữ dưới 12px.** ⚠️
`11/600/ls.6` cho `NEW`/`MASTERED`/`BEGINNING`, `11/500/ls1.1` cho pill `now`.
Mọi màn khác trong app dừng ở 12. §6 nói không dùng font size để chữa layout —
11px ở đây trông đúng là để nhét vừa.

**F5 — Trạng thái thẻ được nói ba lần.** ⚠️
Chấm màu + nhãn chữ hoa + (đôi khi) pill thời gian, trên cùng một card. Bỏ nhãn
chữ sẽ vừa gỡ một rung typography (F4) vừa trả lại chiều cao cho list (F3).
