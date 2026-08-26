# Deck list — trong deck

Library & Deck · `lib/features/deck/presentation/screens/deck_list_screen.dart`
· golden `test/demo/goldens/deck_list_level_light.png` · commit `ea80d3f7`

Cùng screen với [deck_list_root](deck_list_root.md), khác ba thứ: breadcrumb thay
dòng thống kê, heading là `SUB-DECKS · 3`, và scheduler giải qua root.

## Số đo

| | |
|---|---|
| Typography rungs | **12** — **2 của bottom nav**, **10 của nội dung** |
| Font weight | 400, 500, 600, **700** |
| Spacer | 4×6, 8×1, 12×1, 16×2 — **toàn bộ trên scale** |
| Inset | 4×17, 8×38, 12×6, 16×27, 24×6, 32×1 — **toàn bộ trên scale** |
| Trục text trái | 16 ×5 · 92 ×12 · 100 ×6 · 303 ×4 · 306 ×5 |
| Tap target | 21 chạm được, **1 dưới 48** |
| Target nhỏ | breadcrumb `InkWell` 265×32, hit-test đúng 265×32 — không nới |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ❌ **FAB đè lên nút Study của card 3** — xem F1, nặng hơn ở root |
| Safe area | ➖ |
| Touch target | ⚠️ 20/21 đạt; breadcrumb 32px cao — ngoại lệ có ghi lý do, xem F2 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ➖ chỉ đo ở 393 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ⚠️ ba primary tô đặc, y như root |
| Grouping đúng | ✅ cùng nhịp 16/16/8/0 |
| Alignment tốt | ✅ ba trục 16 / 92 / 100 |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ✅ ba sub-deck trọn vẹn |
| Visual weight cân | ⚠️ đáy phải nặng, F1 làm nặng thêm |
| CTA prominence | ❌ F1 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ |
| Typography tinh tế | ⚠️ 4 weight |
| Icon/text proportion | ✅ home icon + `/` + tên deck trên breadcrumb đọc thành một cụm |
| Surface/color hierarchy | ❌ **hai khối primary chồng nhau** — xem F1 |
| Mắt đi đúng flow | ⚠️ |

## Checklist 20 mục

**1. Screen structure** ✅ App Bar (title + breadcrumb) → Hero → Heading → List
→ Bottom nav. Breadcrumb trả lời "tôi đang ở đâu" ngay dòng thứ hai.

**2. Visual hierarchy** ⚠️ Title `Sublist 1` 22/600 là cấp 1 của chrome, numeral
`12` 32/700 là cấp 1 của nội dung. Hai cái không tranh nhau vì khác vùng. Vấn đề
vẫn là ba nút Study.

**3. Grouping** ✅ Heading `SUB-DECKS · 3` nghiêng về list, cùng số đo với root.
Breadcrumb dính vào title (cùng khối app bar), đúng — nó mô tả title.

**4. Alignment** ✅ Breadcrumb bắt đầu ở 16 cùng trục với heading và mép card.

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale.

**6. Typography** ❌ **10 rung nội dung**, 4 weight. Xem F3.

**7. Component sizing** ⚠️ Deck tile ở đây cao **không** đều nhau — Nouns 160
(có chip + nút Study), Verbs thấp hơn (không có nút), Adjectives lại 160. Đây là
đúng: chiều cao theo nội dung thật chứ không độn cho bằng. §7 nói "không tăng
chiều cao chỉ để lấp khoảng trắng" — màn này tuân thủ.

**8. Density** ✅ Ba sub-deck trọn trong viewport đầu.

**9. Balance** ❌ Góc phải dưới có FAB **chồng lên** một nút cùng màu.

**10. Color hierarchy** ❌ F1: hai surface primary chồng nhau tạo một mảng đặc
không có ý nghĩa ngữ nghĩa nào.

**11. App bar** ✅ Cao 84, title + breadcrumb hai dòng, hai action phải.

**12. List / card** ⚠️ Hierarchy mỗi item rõ; metadata (`60 cards`) không tranh
với title. Nhưng F1 làm hỏng trailing action của card cuối.

**13. Filter / sort / chips** ✅ Chip cùng chiều cao, `All caught up` là chip
trạng thái chứ không phải filter — phân biệt được bằng màu trung tính.

**14. CTA** ❌ F1.

**15. Scroll** ✅ Không nested scroll.

**16. Responsive** ➖ Breadcrumb `All decks / Academic Word List` đã dài; ở 360px
hoặc tiếng Việt nó là thứ tràn trước tiên. Chưa có bằng chứng — cần render bổ
sung.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ Sub-deck rỗng chưa có golden riêng.

**19. Content stress** ➖ Chưa có tên deck 2–3 dòng, chưa có breadcrumb sâu 10
cấp (BR-55 cho phép tới đó).

**20. Interaction** ⚠️ Breadcrumb trông bấm được và bấm được. Nhưng nút Study
của card 3 **trông** bấm được trong khi một phần của nó nằm dưới FAB.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 1 | ba primary tranh nhau |
| Grouping | 2 | đo được, đúng phía |
| Alignment | 2 | ba trục sạch |
| Spacing | 2 | 0 ngoài scale |
| Density | 2 | ba sub-deck trọn |
| Typography | 0 | 10 rung nội dung, 4 weight |
| CTA | 0 | **FAB đè lên một CTA khác cùng màu** |
| Responsive | 1 | breadcrumb là rủi ro chưa đo |
| **Tổng** | **10 / 16** | **Major layout revision** — và F1 là Level 1 |

## Findings

**F1 — FAB chồng lên nút Study của card cuối.** ❌ Level 1, **nặng hơn ở root**.
Ở root FAB che một dòng chữ; ở đây nó đè lên một **nút bấm được, cùng màu
primary**. Hai khối cùng màu chồng nhau không đọc ra được đâu là đâu, và người
dùng không biết chạm vào chỗ giao thì mở form tạo deck hay bắt đầu học.
Đây là cùng một nguyên nhân với F1 của root, nhưng hậu quả khác hạng: che chữ là
mất thông tin, đè lên nút là **mơ hồ về hành vi**.

**Chủ dự án cố ý để mở (2026-08-26)**, đang tìm phương án — xem
[deck_list_root](deck_list_root.md) F1 cho ba hướng và cho lý do **không** lấy
`DeckLevelScreen.jsx` làm căn cứ.

**F2 — Breadcrumb cao 32px, dưới ngưỡng 48.** ⚠️ ngoại lệ có ghi lý do.
Hit-test thật xác nhận 265×32 — không có `_InputPadding` nới ra. Nhưng
`MxBreadcrumb.compactLineHeight` có doc giải thích: ở chiều cao này dải là **một**
target rộng gần hết bar (265×32 = 8 480px², so với sàn 48×48 = 2 304px²), thay vì
bốn target nhỏ như bản 20px trước đó. Diện tích gấp 3,7 lần sàn. Chấp nhận được,
và điều làm nó chấp nhận được là lý do đã được viết ra chứ không phải con số.

**F3 — Bốn font weight.** ⚠️ giống root, cùng nguyên nhân (numeral 700).

**F4 — Breadcrumb là chỗ tràn đầu tiên chưa ai đo.** ➖ → rủi ro.
`All decks / Academic Word List` đã chiếm gần trọn chiều ngang ở 393px tiếng
Anh. BR-55 cho phép 10 cấp. Chưa có golden nào ở 360px hay tiếng Việt cho màn
này. Đây là mục ➖ đáng chuyển thành test hơn là đáng đoán.
