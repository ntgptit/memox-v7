# Import — nguồn (bước 1)

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_import_source_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **5**, tất cả là nội dung — **đạt mốc 3–5 của checklist** |
| Rung | 22/600 (title) · 14/600 · 14/400 · 12/500 · 12/400 |
| Font weight | 400, 500, 600 |
| Spacer | 4×3, 8×5, 12×1, 16×2 — **toàn bộ trên scale** |
| Inset | 4×7, 8×14, 12×18, 16×10, 24×5 + **1×2 = bề rộng viền** |
| Trục text trái | 28 ×10 · 48 ×6 · 212 ×4 · 170 ×3 · 145 ×3 |
| Tap target | 6 chạm được, **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ breadcrumb đã rút gọn bằng `…`, không cắt giữa chữ |
| Không overlap | ✅ |
| Safe area | ⚠️ **dòng trợ giúp nằm dưới nút sticky, sát mép dưới** — xem F2 |
| Touch target | ✅ 6/6 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ⚠️ CTA đậm nhất (`Choose file`) **không** phải CTA đi tiếp — xem F1 |
| Grouping đúng | ✅ stepper → chip deck → chọn nguồn → vùng thả file → giải thích |
| Alignment tốt | ✅ hai thẻ nguồn cùng bề rộng, cùng trục |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ ~25% màn trống giữa panel giải thích và nút đáy |
| Visual weight cân | ✅ |
| CTA prominence | ✅ nút đi tiếp disabled rõ ràng, không tranh với `Choose file` |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ khoảng trống dồn vào một chỗ |
| Optical alignment | ✅ icon check trên thẻ đã chọn nằm cạnh icon loại, đọc thành một cụm |
| Typography tinh tế | ✅ **5 rung, 3 weight** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ primary chỉ ở 3 chỗ và cả 3 đều mang nghĩa: số bước hiện tại, viền thẻ đã chọn, nút hành động |
| Mắt đi đúng flow | ✅ 1 → chọn nguồn → chọn file → đọc luật → đi tiếp |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu, và stepper nói ngay đang ở đâu trong ba
bước. Nhìn 2–3 giây là hiểu.

**2. Visual hierarchy** ⚠️ Bốn cấp rõ. Xem F1 về việc cấp 1 đặt ở đâu.

**3. Grouping** ✅ Năm nhóm, mỗi nhóm có ranh giới bằng khoảng trắng hoặc
container. Container chỉ dùng ở hai chỗ **thật sự** là vùng riêng (vùng thả file,
panel giải thích) — đúng §3.

**4. Alignment** ✅ Hai thẻ nguồn cùng bề rộng (≈410 mỗi thẻ ở 393px) — cùng loại
vấn đề mà `MxButtonPair` sửa cho nút, ở đây đã đúng sẵn.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ✅ **5 rung, 3 weight — đạt mốc checklist.** Một trong bốn màn
đạt được điều này.

**7. Component sizing** ✅ Hai thẻ nguồn cùng chiều cao dù nội dung khác độ dài.

**8. Density** ⚠️ Xem F3.

**9. Balance** ✅ Nội dung dồn lên trên, CTA neo dưới — đúng mô hình wizard.

**10. Color hierarchy** ✅ Primary chỉ ba chỗ, cả ba mang nghĩa.

**11. App bar** ✅ `✕` đóng (không phải back — đúng cho một luồng có thể bỏ dở),
title rõ, không action thừa.

**12. List / card** ➖

**13. Filter / sort / chips** ✅ Chip `Korean · TOPIK I · 142 cards` là ngữ cảnh,
không phải filter — và nó không trông bấm được. Đúng §20.

**14. CTA** ✅ **Disabled CTA thể hiện trạng thái rõ ràng** (§14) — `Preview
import` xám hẳn, và có dòng giải thích ngay dưới nói bước sau là gì.

**15. Scroll** ✅ Không nested scroll. Nút đáy sticky.

**16. Responsive** ➖ Breadcrumb đã dùng `…` ở 393px, nên nó là chỗ chật trước
tiên — giống [deck_list_level](deck_list_level.md) F4.

**17. Safe area** ⚠️ F2.

**18. Empty / loading / error** ✅ Đây là trạng thái "chưa chọn gì" và nó **không**
trống rỗng: vùng thả file có icon + lời mời + nút.

**19. Content stress** ➖

**20. Interaction** ✅ Thẻ đã chọn có viền + check — selected state dễ nhận. Chip
ngữ cảnh không giả dạng nút.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 1 | CTA đậm nhất không phải CTA đi tiếp |
| Grouping | 2 | năm nhóm, container chỉ ở chỗ cần |
| Alignment | 2 | hai thẻ cùng bề rộng và chiều cao |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 1 | 25% màn trống dồn một chỗ |
| Typography | 2 | 5 rung, 3 weight |
| CTA | 2 | disabled state rõ, có dòng dẫn bước sau |
| Responsive | 1 | breadcrumb đã phải rút gọn ở 393 |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — Nút đậm nhất màn không phải nút đi tiếp.** ⚠️
`Choose file` tô đặc primary ở giữa màn; `Preview import` — nút thực sự đưa người
dùng sang bước 2 — nằm dưới cùng và đang disabled.
Về logic thì đúng: chưa có file thì không preview được. Nhưng về thị giác, phần
tử mạnh nhất là một hành động **phụ trợ**, còn hành động của bước thì mờ. §2 nói
thứ tự thị giác phải khớp thứ tự thao tác — ở đây khớp về thời gian (chọn file
trước) nên đây là ⚠️ chứ không phải ❌.
Nếu muốn chặt hơn: `Choose file` có thể là outlined, để duy nhất một khối đặc
trên màn là nút bước.

**F2 — Dòng trợ giúp nằm **dưới** nút sticky, sát mép dưới.** ⚠️
`Next you'll preview every row before anything is imported.` nằm bên dưới
`Preview import`, tức là phần tử thấp nhất màn. Trên máy có thanh điều hướng cử
chỉ, đây là dải dễ bị che hoặc dễ bị vuốt nhầm.
§17 nói bottom action không được chạm gesture navigation — nút thì có vẻ ổn,
nhưng dòng chữ dưới nó thì không còn chỗ. Đưa dòng đó lên **trên** nút sẽ vừa an
toàn vừa đúng thứ tự đọc (giải thích trước, hành động sau).

**F3 — ~25% màn trống giữa panel giải thích và nút đáy.** ⚠️
Với mô hình sticky footer thì khoảng trống này là bình thường. Ghi lại vì §8 hỏi
"không quá trống", và nếu bước này về sau có thêm tuỳ chọn thì đây là chỗ để.
