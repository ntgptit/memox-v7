# Card detail

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_detail_light.png` · commit `ea80d3f7`

Trang đọc, có lịch sử phân trang keyset (M99.31). Không có bottom nav, nên cả 8
rung đều là nội dung.

## Số đo

| | |
|---|---|
| Typography rungs | **8**, tất cả là nội dung |
| Rung | 24/600 (từ) · 22/600 (title) · 16/600 (nghĩa) · 14/600 · 14/400 · 12/400 · **11/500** · **11/600** |
| Font weight | 400, 500, 600 |
| Spacer | 4×8, 8×2, 12×4, **32×2** — toàn bộ trên scale; 32 là vạch ngăn section |
| Inset | 4×7, 8×15, 12×1, 16×9, 24×1 — **toàn bộ trên scale, không có 1px viền nào** |
| Trục text trái | **16 ×40** · 40 ×20 · **144 ×18** · 24 ×2 · 76 ×2 |
| Tap target | **1** chạm được (nút sửa), 0 dưới 48 |

Trục 16 và 144 là hai cột của bảng nhãn/giá trị — 18 giá trị thẳng hàng tuyệt
đối.

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ➖ |
| Touch target | ✅ 1/1 |
| Text đọc được | ⚠️ hai rung 11px |
| Component đúng chức năng | ⚠️ **mâu thuẫn nội dung** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ từ 24/600 → nghĩa 16/600 → nhãn 12/400 → giá trị 14/400, bốn cấp tách bạch |
| Grouping đúng | ✅ ba section cách nhau 32, trong section cách nhau 4–12 |
| Alignment tốt | ✅ **bảng hai cột thẳng tuyệt đối** (16 / 144) |
| Spacing có rhythm | ✅ **0 giá trị ngoài scale, kể cả 1px** — màn sạch nhất về spacing |
| Density hợp lý | ⚠️ thưa; 6 dòng bảng chiếm ~14% màn |
| Visual weight cân | ✅ |
| CTA prominence | ➖ trang đọc, không có CTA — đúng |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ |
| Typography tinh tế | ⚠️ 8 rung cho một trang không có chrome nào để đổ lỗi |
| Icon/text proportion | ✅ cờ 16px trước `Flagged`, chấm 12px trước `New` |
| Surface/color hierarchy | ✅ **không dùng card nào** — phân nhóm hoàn toàn bằng khoảng trắng |
| Mắt đi đúng flow | ✅ từ → nghĩa → chi tiết → trạng thái → lịch sử |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu: xem mọi thứ về một thẻ. Ba vùng rõ.

**2. Visual hierarchy** ✅ Bốn cấp phân biệt được bằng cỡ **và** weight.

**3. Grouping** ✅ Khoảng cách trong nhóm (4–12) nhỏ hơn giữa nhóm (32). **Và
không dùng divider ở đâu spacing đã đủ** — §3 nói đúng điều này, màn này làm
đúng.

**4. Alignment** ✅ Hai cột nhãn/giá trị ở 16 và 144, 18 giá trị thẳng hàng.

**5. Spacing & rhythm** ✅ Không một giá trị nào ngoài scale — kể cả không có
inset 1px, vì màn không dùng viền.

**6. Typography** ⚠️ 8 rung, hai trong đó dưới 12px.

**7. Component sizing** ✅

**8. Density** ⚠️ Thưa. Chấp nhận được cho trang đọc, nhưng 6 dòng bảng với giá
trị ngắn (`0`, `0`, `1`) chiếm nhiều chiều dọc so với lượng thông tin.

**9. Balance** ✅

**10. Color hierarchy** ✅ Gần như đơn sắc, chỉ có chấm trạng thái mang màu. Đây
là cách dùng màu semantic đúng nhất trong 29 màn: **một** chỗ, và nó mang nghĩa.

**11. App bar** ⚠️ Title là `Card` — chung chung. Từ đang xem (`사과`) đã ở ngay
dưới, nên app bar không nói thêm gì. §11 "Title rõ ràng" — đây là nhãn loại, không
phải tên.

**12. List / card** ⚠️ Lịch sử là list. Mỗi mục có timeline dot + thời gian +
hành động + chuyển box, hierarchy rõ. Không mục nào bấm được — đúng, chúng là
bản ghi.

**13. Filter / sort / chips** ✅ Chip tag trung tính, không tranh với nội dung.

**14. CTA** ➖ Không có, và đúng là không nên có. Sửa nằm ở app bar.

**15. Scroll** ✅ Cuộn tự nhiên; lịch sử phân trang keyset nên không có nested
scroll.

**16. Responsive** ➖ Cột giá trị cố định ở 144 — với nhãn dài hơn (tiếng Việt:
`Lần trả lời gần nhất`) cột này là chỗ vỡ trước tiên. Chưa đo.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ `card_detail_page_error` là file riêng.

**19. Content stress** ⚠️ Có chữ Hàn + Việt. Chưa có từ dài, chưa có thẻ không
có Example/Hint/Pronunciation (rất phổ biến).

**20. Interaction** ✅ **Không có gì trông bấm được mà không bấm được.** Chip tag
để phẳng, không viền, không nền màu — đọc đúng là nhãn chứ không phải nút. §20
nói thành phần không clickable không được trông giống button; màn này là ví dụ
đúng.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | bốn cấp tách bạch bằng cỡ và weight |
| Grouping | 2 | 32 giữa section, 4–12 trong section, không divider thừa |
| Alignment | 2 | bảng hai cột thẳng tuyệt đối |
| Spacing | 2 | 0 giá trị ngoài scale |
| Density | 1 | thưa ở phần bảng |
| Typography | 1 | 8 rung, hai cỡ dưới 12 |
| CTA | 2 | không có CTA là quyết định đúng ở đây |
| Responsive | 1 | cột 144 chưa đo với nhãn dài |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — `Never answered` nằm ngay trên hai bản ghi trả lời.** ⚠️ cần câu trả lời
nghiệp vụ, không tự kết luận là bug.
Bảng trạng thái nói `Due: Not scheduled yet`, `Last answered: Never answered`,
`Reviews: 0`, trong khi ngay dưới, dưới nhãn **`Current learning cycle`**, có hai
mục `Self-assess · Scheduled · Remembered / Box 1 → 2` và `… Forgot`.
Theo CLAUDE.md, `review_history` là append-only và **được giữ qua mọi lần reset**,
còn `card_review_states` thì bị reset — nên "đã học rồi mà `Reviews: 0`" là hành
vi **đúng** sau một lần Reset learning progress.
Vấn đề là màn hình không nói thế. Nhãn `Current learning cycle` khẳng định hai
bản ghi đó thuộc chu kỳ **hiện tại**, mâu thuẫn trực tiếp với `Reviews: 0` cách
đó 200px.
Cần xác định: fixture demo dựng sai, hay nhãn `Current learning cycle` không lọc
theo `scheduler_generation`. Cái thứ hai là bug thật.

**F2 — Title app bar là `Card`.** ⚠️
Nhãn loại chứ không phải tên. Từ đang xem nằm ngay dưới ở 24/600, nên app bar
không thêm thông tin. Có thể để chính từ đó làm title khi cuộn (collapse), hoặc
đặt tên deck.

**F3 — Hai rung 11px.** ⚠️
Giống card list. Mọi màn khác dừng ở 12.

**F4 — Màn này là mốc tham chiếu cho §3 và §20.** ✅ ghi lại.
Nó **không dùng một card nào** — phân nhóm hoàn toàn bằng 32/12/4 — và không có
phần tử nào giả dạng nút. Card list, ngược lại, bọc mọi thứ trong surface. Khi
sửa card list theo F3 của file đó, đây là hình mẫu cho câu hỏi "chỗ này có thật
sự cần một container không".
