# Study Home

Study · `lib/features/study/presentation/` · golden
`test/demo/goldens/study_home_light.png` · commit `ea80d3f7` · UC-14

**Golden này không có bottom navigation** dù Study là một tab của thanh đó — xem
[README](README.md). Mọi kết luận về mật độ dưới đây thiếu 80px chrome.

## Số đo

| | |
|---|---|
| Typography rungs | **7**, tất cả là nội dung (không có nav trong golden) |
| Rung | 22/600 (title) · 16/600 (tên deck) · 14/600 · 14/400 · 12/600 · 12/400 · 12/500/ls1.1 |
| Font weight | 400, 500, 600 — **không có 700** |
| Spacer | 4×4, 8×2, 12×5, 16×1, 24×1 — **toàn bộ trên scale** |
| Inset | 4×24, 12×6, 16×12, 24×6 — **toàn bộ trên scale, không có 1px viền** |
| Trục text trái | 32 ×14 · 80 ×9 · 16 ×6 · 60 ×6 · 160 ×3 |
| Tap target | 3 chạm được (Resume + 2 nút Study), **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ➖ **và không kiểm được** — golden thiếu thanh nav |
| Touch target | ✅ 3/3 |
| Text đọc được | ✅ |
| Component đúng chức năng | ⚠️ **hai từ vựng khác nhau cho scheduler** — xem F2 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ **`Resume` tô đặc, hai nút `Study` outlined** — phân cấp CTA đúng |
| Grouping đúng | ✅ Carry-on tách khỏi `STUDY NEXT` bằng 24; trong thẻ dùng 4–12 |
| Alignment tốt | ✅ trục 32 ×14 (chữ trong thẻ), 16 (padding màn) |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ⚠️ ~25% dưới trống, và sẽ còn 17% khi có thanh nav |
| Visual weight cân | ✅ |
| CTA prominence | ✅ **một** khối đặc trên màn |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ icon ▶ dẫn nhãn nút, chip số liệu căn theo dòng |
| Typography tinh tế | ⚠️ 7 rung |
| Icon/text proportion | ✅ icon tròn 24 với số 14 bên cạnh |
| Surface/color hierarchy | ✅ **primary chỉ một chỗ**; carry-on dùng surface xám, không dùng màu |
| Mắt đi đúng flow | ✅ tiêu đề → tiếp tục dở dang → chọn deck khác |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu, và dòng phụ nói thẳng nó:
`Pick a deck, or carry on where you stopped.` Hai lối vào được phát biểu **trước**
khi hiện ra.

**2. Visual hierarchy** ✅ **Đây là màn phân cấp CTA đúng nhất trong 29 màn.**
`Resume` tô đặc; hai nút `Study` outlined. So với
[deck_list_root](deck_list_root.md) F2, nơi ba nút Study đều tô đặc và hero mất
vai trò cấp 1 — cùng một bài toán, hai lời giải, và lời giải ở đây đúng.

**3. Grouping** ✅ Thẻ carry-on dùng surface xám khác với thẻ deck (trắng, viền) —
hai loại khác nhau được vẽ khác nhau.

**4. Alignment** ✅ Trục 32 cho chữ trong thẻ, 16 cho padding màn, 80 cho nhãn số
liệu sau icon tròn.

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale, **không có inset 1px** —
thẻ deck có viền nhưng nó không sinh `Padding` (dùng `Border` trong `ShapeDecoration`).

**6. Typography** ⚠️ 7 rung. Trên mốc 3–5 nhưng thấp hơn hầu hết màn danh sách.

**7. Component sizing** ✅ Hai thẻ deck cùng cấu trúc; hai nút `Study` cùng kích
thước.

**8. Density** ⚠️ Hai deck trong ~60% màn. Sẽ chặt hơn khi thanh nav xuất hiện.

**9. Balance** ✅

**10. Color hierarchy** ✅ Primary đúng **một** chỗ (`Resume`). Ba màu ngữ nghĩa
cho overdue/due/new, và chúng **giữ nguyên hệ màu** của
[deck_list_root](deck_list_root.md) — cùng đỏ, cùng vàng, cùng xanh. Nhất quán
xuyên feature.

**11. App bar** ✅ Title + một dòng dẫn. Không action — đúng, màn này không có gì
để tác động ngoài việc chọn.

**12. List / card** ⚠️ Mỗi thẻ có nút `Study` riêng, nhưng **thân thẻ không phải
target** (3 target đo được = 3 nút). Người dùng chạm vào tên deck sẽ không có gì
xảy ra. §12 nói toàn bộ item nên clickable nếu hành vi là mở detail — ở đây hành
vi là *học*, nên chỉ nút mới đúng. Chấp nhận được, nhưng thẻ trông như một thẻ
bấm được.

**13. Filter / sort / chips** ✅ Ba chip số liệu cùng chiều cao, spacing đều, và
chúng **không** giả dạng nút.

**14. CTA** ✅ Một primary cho toàn màn; CTA phụ ở mỗi thẻ được hạ xuống outlined.

**15. Scroll** ✅

**16. Responsive** ➖ Ba chip số liệu trên một dòng đã dùng gần trọn chiều ngang
(`2 overdue · 5 due today · 12 new` kết thúc ở ~737/923). Ở 360px hoặc tiếng Việt
chúng sẽ phải xuống dòng.

**17. Safe area** ➖ Không kiểm được — golden thiếu thanh nav.

**18. Empty / loading / error** ➖ chưa có golden cho "không có gì để học".

**19. Content stress** ⚠️ Có deck 0 việc (`Kanji basics`: 0/0/3) — tốt, nó cho
thấy các số 0 vẫn hiện với màu nhạt thay vì biến mất. Chưa có tên deck dài.

**20. Interaction** ⚠️ Xem §12: thẻ trông bấm được nhưng chỉ nút bấm được.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | **phân cấp CTA đúng nhất trong 29 màn** |
| Grouping | 2 | hai loại thẻ vẽ khác nhau, nhịp rõ |
| Alignment | 2 | ba trục sạch |
| Spacing | 2 | 0 ngoài scale, không viền sinh padding |
| Density | 1 | thiếu 80px nav trong ảnh; thực tế sẽ chặt hơn |
| Typography | 1 | 7 rung |
| CTA | 2 | một primary, phụ hạ xuống outlined |
| Responsive | 1 | ba chip số liệu đã sát mép |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — `Everyday Korean` xuất hiện hai lần trong một viewport.** ⚠️
Thẻ `Carry on` là `Everyday Korean`, và item đầu tiên của `STUDY NEXT` cũng là
`Everyday Korean`. Người dùng thấy cùng một deck hai lần với hai nút khác nhau
(`Resume` và `Study`) và phải tự suy ra chúng khác gì.
Chúng **thật sự** khác — một cái tiếp tục phiên dở, một cái mở phiên mới — nhưng
màn không nói điều đó. Hai lối: loại deck đang dở khỏi `STUDY NEXT`, hoặc cho
item đó một nhãn nói rõ (`New session`).

**F2 — Hai từ vựng cho cùng một khái niệm.** ⚠️
`Everyday Korean` có dòng phụ `8 boxes`; `Kanji basics` có `SM-2`. Cả hai đều mô
tả scheduler, nhưng một cái nói **cách hoạt động** còn cái kia nói **tên thuật
toán**. Người dùng không có cách nào biết `8 boxes` và `SM-2` là hai câu trả lời
cho cùng một câu hỏi.
Chọn một hệ: hoặc cả hai là tên (`Eight-box` / `SM-2`), hoặc cả hai là mô tả
(`8 boxes` / `Spaced repetition`).

**F3 — Golden thiếu bottom navigation.** ⚠️ khiếm khuyết của gallery.
Study là một tab. Ảnh không có thanh tab, nên nó hiển thị 80px nội dung mà thiết
bị thật không có. Mọi phán xét về mật độ và về việc thẻ cuối có bị che hay không
đều không kết luận được từ ảnh này.
Sửa: dựng golden này qua shell như bốn màn deck.

**F4 — Màn này là hình mẫu cho F2 của [deck_list_root](deck_list_root.md).** ✅
Cùng bài toán — một hành động tổng và nhiều hành động con — và ở đây được giải
đúng: khối đặc dành cho hành động tổng, hành động con hạ xuống outlined. Deck
list tô đặc cả ba và mất cấp 1.
