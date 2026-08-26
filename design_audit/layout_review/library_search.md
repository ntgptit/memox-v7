# Global search

Search · `lib/features/search/presentation/` · golden
`test/demo/goldens/library_search_light.png` · commit `ea80d3f7` · UC-20

Tìm trên deck, thẻ và nhãn, phân trang keyset.

## Số đo

| | |
|---|---|
| Typography rungs | **6**, tất cả là nội dung |
| Rung | 22/600 (title) · 16/400 (kết quả) · 14/400 (nhãn section + đường dẫn) · **11/600/ls1.1** · **11/600/ls.5** · **11/500/ls.5** |
| Font weight | 400, 500, 600 |
| Spacer | 8×1 — **toàn bộ trên scale** |
| Inset | 4×2, 8×6, 12×7, 16×8 + **13×4 = tay cầm chọn text của framework** |
| Trục text trái | **60 ×18** · 16 ×6 · 52 ×2 · 309 ×2 |
| Tap target | 5 chạm được, **1 "dưới 48"** = tay cầm chọn text của Flutter, không phải control |
| Khoảng trống | ~**55%** dưới |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ đường dẫn `Korean › Grammar › Nouns` vừa một dòng |
| Không overlap | ✅ |
| Safe area | ➖ |
| Touch target | ✅ 5/5 control thật đều đạt |
| Text đọc được | ⚠️ ba rung **11px** |
| Component đúng chức năng | ⚠️ **số `3` trong ô tìm không có nhãn** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ đường dẫn 14/400 → tiêu đề kết quả 16/400 → nghĩa 14/400 |
| Grouping đúng | ✅ hai section `Decks` / `Cards`, mỗi kết quả một thẻ |
| Alignment tốt | ✅ **trục 60 dùng 18 lần** cho toàn bộ nội dung kết quả |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ ba kết quả trong 45% trên, 55% dưới trống |
| Visual weight cân | ⚠️ |
| CTA prominence | ➖ mỗi kết quả là một lối đi; không có CTA riêng — đúng |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ |
| Optical alignment | ✅ icon loại và ↗ nằm trên hai trục biên của thẻ |
| Typography tinh tế | ⚠️ 6 rung, **ba trong đó dưới 12px** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ **đơn sắc hoàn toàn** — không kết quả nào được tô ưu tiên |
| Mắt đi đúng flow | ✅ gõ → nhóm → kết quả |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu. Ô tìm ở vị trí cao nhất, đang focus, có
sẵn nội dung — người dùng biết ngay phải làm gì.

**2. Visual hierarchy** ✅ Trong mỗi thẻ: đường dẫn nhạt → nội dung khớp đậm →
nghĩa nhạt. Đường dẫn đặt **trên** tiêu đề chứ không dưới — đúng, nó là ngữ cảnh
cần đọc trước.

**3. Grouping** ⚠️ Hai section rõ. Nhưng nhãn section ở đây là `Decks` / `Cards`
kiểu câu, 14/400 — trong khi cả app dùng **12/500 chữ hoa có tracking** cho nhãn
section (`YOUR DECKS`, `STUDY DEFAULTS`, `APPEARANCE`, `LANGUAGE`). Xem F2.

**4. Alignment** ✅ Trục 60 dùng 18 lần — mọi dòng chữ trong mọi thẻ kết quả cùng
một đường, kể cả thẻ có 2 dòng và thẻ có 3 dòng.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ⚠️ 6 rung, **ba dưới 12px**. Xem F3.

**7. Component sizing** ✅ Ba thẻ cùng padding; chiều cao theo nội dung (2 hoặc 3
dòng) chứ không độn — đúng §7.

**8. Density** ⚠️ Ba kết quả cho 45% màn. Sẽ đầy khi có nhiều kết quả hơn.

**9. Balance** ⚠️

**10. Color hierarchy** ✅ **Hoàn toàn đơn sắc, kể cả từ khớp không được tô
highlight.** Điều đó nhất quán với [tag_catalog](tag_catalog.md) và
[card_move_picker](card_move_picker.md) — ba màn danh sách trung tính. Đáng cân
nhắc: highlight từ khớp là quy ước phổ biến của search và ở đây không có.

**11. App bar** ✅ Title `Search`. Ô tìm **không** nhét vào app bar mà nằm trong
nội dung — đúng §11, và nhất quán với [tag_catalog](tag_catalog.md).

**12. List / card** ✅ Mỗi kết quả có ↗ ở góc phải nói rõ "mở ở nơi khác".
Metadata (đường dẫn) không tranh với tiêu đề.

**13. Filter / sort / chips** ➖ Không có lọc theo loại. Với 3 kết quả thì không
cần; với 200 thì sẽ cần.

**14. CTA** ➖

**15. Scroll** ✅ Keyset paging.

**16. Responsive** ➖ Đường dẫn ba cấp đã dùng nửa chiều ngang. Với deck sâu hơn
(BR-55 cho tới 10 cấp) đây là chỗ vỡ trước — cùng rủi ro với
[deck_list_level](deck_list_level.md) F4.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ Trạng thái không kết quả và đang tải chưa có
golden trong 29 màn.

**19. Content stress** ✅ Có kết quả khớp theo **nhãn** (`Tag: noun`) chứ không
chỉ theo nội dung — ba loại khớp trong ba thẻ. Fixture tốt.

**20. Interaction** ✅ ✕ xoá ô tìm, ↗ nói kết quả mở đi đâu.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | đường dẫn trên tiêu đề, ba cấp trong thẻ |
| Grouping | 1 | nhãn section lệch chuẩn của app |
| Alignment | 2 | trục 60 dùng 18 lần |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 1 | 55% dưới trống |
| Typography | 1 | 6 rung, ba dưới 12px |
| CTA | 2 | mỗi kết quả là một lối đi, có ↗ |
| Responsive | 1 | đường dẫn sâu chưa đo |
| **Tổng** | **12 / 16** | **Minor fix** |

## Findings

**F1 — Số `3` trong ô tìm không có nhãn.** ⚠️
Bên phải ô tìm có `3` rồi `✕`. `3` là số kết quả, nhưng không có gì nói thế — nó
có thể đọc là số ký tự, số bộ lọc, hay một huy hiệu.
[card_list](card_list.md) dùng `Showing 7 of 142`; [tag_filter_sheet](tag_filter_sheet.md)
dùng `Show 19 cards`. Cả hai đều đặt con số cạnh một từ. Ở đây con số đứng một
mình cạnh nút xoá, tức cạnh thứ dễ bị hiểu là nó liên quan tới.
Sửa: `3 results`, hoặc đưa nó ra ngoài ô tìm thành một dòng như card list.

**F2 — Nhãn section lệch khỏi chuẩn của app.** ⚠️
`Decks` / `Cards` ở 14/400 kiểu câu. Bốn màn khác dùng 12/500 chữ hoa có
tracking cho đúng vai trò này: `YOUR DECKS` (deck list), `STUDY NEXT` (study
home), `STUDY DEFAULTS` / `APPEARANCE` / `LANGUAGE` (settings).
Nên màn này là ngoại lệ duy nhất, và nó làm nhãn section trông ngang hàng với
đường dẫn trong thẻ (cũng 14/400).

**F3 — Ba rung dưới 12px.** ⚠️
`11/600/ls1.1`, `11/600/ls.5`, `11/500/ls.5`. Cùng vấn đề với
[card_list](card_list.md) F4, [card_detail](card_detail.md) F3 và
[study_browse](study_browse.md) F3.
**Bốn màn, bốn feature khác nhau, cùng tụt xuống 11px.** Đây không phải bốn quyết
định riêng lẻ — nó là dấu hiệu thang typography thiếu một bậc dưới 12, nên mỗi
feature tự chế một bậc. Xem tổng kết ở [README](README.md).

**F4 — Không highlight từ khớp.** ⚠️ cần xác nhận là chủ đích.
Từ `noun` xuất hiện trong tiêu đề của cả ba kết quả nhưng không được tô đậm hay
tô nền. Với danh sách 3 kết quả thì không sao; với 50 kết quả trên nhiều trường
(tiêu đề, nghĩa, nhãn) thì người dùng sẽ phải tự dò xem **vì sao** một kết quả
lọt vào.
Thẻ thứ ba có `Tag: noun` — đó là một cách trả lời "vì sao", và nó tốt. Nhưng hai
thẻ đầu không có dòng tương đương.
