# Deck chỉ có thẻ mới

Library & Deck · `lib/features/deck/presentation/screens/deck_list_screen.dart`
· golden `test/demo/goldens/deck_list_new_only_light.png` · commit `ea80d3f7`

Trạng thái BR-150: không có thẻ nào đến hạn, chỉ có thẻ mới, và Study **vẫn** mở.

## Số đo

| | |
|---|---|
| Typography rungs | **10** — **2 của bottom nav**, **8 của nội dung** |
| Rung nội dung | 32/700 (numeral) · 22/600 (title) · 16/600 · 12/600/ls.72 (heading) · 12/400 |
| Font weight | 400, 500, 600, **700** |
| Spacer | 4×2, 8×1 — **toàn bộ trên scale** |
| Inset | 4×7, 8×20, 12×2, 16×13, 32×1 — **toàn bộ trên scale** |
| Trục text trái | 16 ×7 · 92 ×4 · 306 ×5 |
| Tap target | 13 chạm được, **0 dưới 48** |
| Hero | cao ~130px cho một numeral và một chevron, **không có CTA** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ FAB nằm trên vùng trống |
| Safe area | ➖ |
| Touch target | ✅ 13/13 |
| Text đọc được | ✅ |
| Component đúng chức năng | ❌ **`1 decks`** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ❌ **numeral lớn nhất màn thuộc về panel không làm gì** — xem F2 |
| Grouping đúng | ✅ cùng nhịp với root |
| Alignment tốt | ✅ |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ⚠️ **một card, ~55% màn trống** — xem F3 |
| Visual weight cân | ⚠️ toàn bộ trọng lượng dồn lên 1/3 trên |
| CTA prominence | ⚠️ CTA duy nhất nằm trên card, không nằm ở panel dẫn dắt |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ |
| Optical alignment | ✅ numeral `20` cắt leading như root |
| Typography tinh tế | ❌ 8 rung nội dung cho **một** deck, và weight 700 tồn tại cho một numeral không dẫn tới hành động nào |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ chỉ 2 chỗ dùng primary (Study, FAB) — sạch hơn root |
| Mắt đi đúng flow | ❌ mắt vào numeral `20` trước, rồi phải đi ngược xuống card mới tìm được việc để làm |

## Checklist 20 mục

**1. Screen structure** ✅ Phân vùng rõ. Nhưng xem F2 về việc vùng hero có xứng
đáng tồn tại ở trạng thái này không.

**2. Visual hierarchy** ❌ F2.

**3. Grouping** ✅ Heading nghiêng về list, cùng số đo với root.

**4. Alignment** ✅ Ba trục 16 / 92 / 306.

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale.

**6. Typography** ❌ **8 rung nội dung** — trên mốc 3–5, dù màn chỉ có một deck.
4 weight, và 700 dành cho numeral mô tả ở F2.

**7. Component sizing** ✅

**8. Density** ⚠️ F3.

**9. Balance** ⚠️ Mọi thứ nằm trong 45% trên, phần dưới trống hoàn toàn trừ FAB.

**10. Color hierarchy** ✅ Primary chỉ ở nút Study và FAB. Chip `20 new` dùng màu
trung tính — đúng, thẻ mới không phải cảnh báo.

**11. App bar** ⚠️ F1 nằm ở dòng phụ của app bar.

**12. List / card** ✅ Một item, hierarchy rõ, metadata không tranh title.

**13. Filter / sort / chips** ✅ Control sort vẫn hiện với một deck. Hợp lý —
ẩn/hiện theo số lượng sẽ làm vị trí điều khiển nhảy.

**14. CTA** ⚠️ Chỉ một CTA thật trên màn (`Study` trên card) và nó **không** nằm
ở chỗ mắt tới trước. FAB là hành động phụ nhưng nổi bật ngang.

**15. Scroll** ✅ Không cần cuộn.

**16. Responsive** ➖

**17. Safe area** ➖

**18. Empty / loading / error** ➖ Đây không phải empty state — nó là trạng thái
"có dữ liệu nhưng không có việc đến hạn", khác hẳn `deck_list_empty`.

**19. Content stress** ⚠️ Đây **là** trường hợp 1 item, và nó lộ ra F1 và F3 —
hai thứ mà bộ 4 deck của màn root che mất. Ghi lại như bằng chứng cho việc §19
đáng làm thật.

**20. Interaction** ✅ Chevron của hero mở/đóng chi tiết, trông đúng chức năng.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 0 | phần tử lớn nhất màn không dẫn tới hành động nào |
| Grouping | 2 | cùng nhịp đã đo với root |
| Alignment | 2 | ba trục sạch |
| Spacing | 2 | 0 ngoài scale |
| Density | 1 | một card, hơn nửa màn trống |
| Typography | 0 | 8 rung nội dung, 4 weight, 700 phục vụ F2 |
| CTA | 1 | CTA duy nhất không ở vị trí dẫn dắt |
| Responsive | 1 | không có bằng chứng |
| **Tổng** | **9 / 16** | **Major layout revision** |

## Findings

**F1 — `1 decks`.** ❌ Level 1, lỗi thật, nhìn thấy trên render.
`lib/l10n/app_en.arb:4107` là `"{deckCount} decks · {cardCount} cards"` — nội suy
thẳng, không có ICU plural. Ở một deck nó in `1 decks`.
Điều làm nó đáng sửa hơn một lỗi chính tả: **deck tile ngay bên dưới lại làm
đúng** — màn root in `1 sub-deck` số ít. Nên trên cùng một màn có hai quy tắc số
nhiều khác nhau, và cái sai là cái nằm ở dòng đầu tiên người dùng đọc.
Sửa: chuyển sang `{deckCount, plural, ...}` cho cả hai placeholder.

**F2 — Numeral lớn nhất màn thuộc về một panel không có hành động.** ❌
Hero ở đây là `20 New` + chevron, cao ~130px, **không có nút Study** (đúng — BR-150
nói Study mở, nhưng CTA thật nằm trên deck card). Kết quả:
- phần tử đậm nhất, lớn nhất (32/700) là con số `20`;
- chạm vào nó không dẫn đến đâu;
- việc duy nhất làm được nằm thấp hơn, nhỏ hơn, ở nửa phải màn.

§2 nói thứ tự thị giác phải khớp thứ tự người dùng cần thao tác. Ở đây nó ngược.
Và `20 New` đã được nói **ba lần** trên cùng một viewport: dòng phụ app bar
(`20 cards`), numeral hero, chip trên card (`20 new`).
Hướng: ở trạng thái không-có-gì-đến-hạn, hero nên rút thành một dòng, hoặc mang
luôn CTA `Study 20 new cards` để numeral dẫn tới hành động mà nó hứa hẹn.

**F3 — Một card, hơn nửa màn trống, và một hero chiếm 130px để nói lại thứ đã
nói.** ⚠️
Không phải lỗi riêng — nó là F2 nhìn từ phía mật độ. Sửa F2 thì F3 tự nhẹ đi.

**F4 — Màn này là bằng chứng cho §19.** ✅ ghi lại.
Cả F1 lẫn F2 chỉ lộ ra ở **1 item** và **0 thẻ đến hạn**. Bộ 4 deck của màn root
che cả hai. Đây đúng là điều checklist §19 (content stress) tồn tại để bắt.
