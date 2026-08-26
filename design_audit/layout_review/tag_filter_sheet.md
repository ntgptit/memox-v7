# Tag filter

Tag · `lib/features/tag/presentation/widgets/overlays/` · golden
`test/demo/goldens/tag_filter_sheet_light.png` · commit `ea80d3f7`

Lọc OR nhiều nhãn (BR-231). Số typography là của **hai** màn cộng lại — sheet đè
lên [card_list](card_list.md); 17/31 target bị barrier chặn.

## Số đo

| | |
|---|---|
| Typography rungs | **11 tổng** — **~5 là của sheet**, còn lại là card list phía sau |
| Rung của sheet | 16/600 (`Filter by tags`) · 16/400 (tên nhãn) · 14/400 (số thẻ + mô tả) · 14/600 (nhãn nút) · 12/… |
| Spacer | 4×4, 8×4, 12×6 — **toàn bộ trên scale** |
| Inset | 4×15, 8×28, 12×5, 16×23, 24×4 + 1×20 viền + 48×1 vùng sheet |
| Trục text trái | **72 ×48** (tên nhãn + số thẻ) · 54 ×24 (nền) · 16 ×9 |
| Tap target | 14 chạm được, 17 bị che, **6 "dưới 48"** — **cả 6 đều được hàng 361×72 phủ** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ nhãn dài nhất (`TOPIK II · vocabulary · chapter 3`) vừa một dòng |
| Không overlap | ✅ hàng cuối cách thanh nút, không bị cắt |
| Safe area | ✅ |
| Touch target | ✅ **14/14 hiệu dụng** — checkbox 40px nhưng cả hàng 361×72 là target |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ **`Show 19 cards` = 12 + 7**, đúng phép OR |
| Responsive | ⚠️ nhãn dài nhất sát mép — cùng rủi ro F2 của [tag_catalog](tag_catalog.md) |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ tiêu đề → giải thích luật → danh sách → hai hành động |
| Grouping đúng | ✅ checkbox + tên + số thẻ đọc thành một hàng |
| Alignment tốt | ✅ trục 72 dùng **48 lần**, checkbox ở trục riêng 16 |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ hàng 72px; sáu nhãn chiếm gần trọn sheet |
| Visual weight cân | ✅ |
| CTA prominence | ✅ **CTA mang con số sống** |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ checkbox căn giữa theo cả hai dòng của hàng |
| Typography tinh tế | ✅ sheet dùng ~5 rung |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ primary chỉ ở checkbox đã tick và nút — hai chỗ, cả hai mang nghĩa |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu. **Và nó nói luật ngay dòng thứ hai**:
`Shows cards with any of the selected tags.` — BR-231 được phát biểu cho người
dùng thay vì để họ đoán từ kết quả.

**2. Visual hierarchy** ✅ Bốn cấp.

**3. Grouping** ✅ Không divider giữa các hàng, chỉ khoảng cách — như
[tag_catalog](tag_catalog.md).

**4. Alignment** ✅ Trục 72 ×48. Cột checkbox riêng ở 16.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ✅ Sheet dùng ~5 rung. Số 11 là do nền.

**7. Component sizing** ✅ Sáu hàng cùng chiều cao, hai nút cùng kích thước.

**8. Density** ⚠️ Hàng 72px. Với thư viện nhiều nhãn, sheet sẽ phải cuộn nhiều.

**9. Balance** ✅

**10. Color hierarchy** ✅ Hai chỗ dùng primary, cả hai mang nghĩa (đã chọn / hành
động). Nhãn không được tô màu — đúng, chúng không có ngữ nghĩa màu.

**11. App bar** ➖

**12. List / card** ✅ **Cả hàng là target, không chỉ checkbox** — §12 và §20.
Đây là điều mà phép đo "target nhỏ" suýt báo sai: xem F2.

**13. Filter / sort / chips** ✅ Selected state (checkbox tick primary) dễ nhận.
Filter có hierarchy thấp hơn nội dung — nó nằm trong sheet chứ không chiếm đầu
màn.

**14. CTA** ✅ **`Show 19 cards` là nhãn CTA tốt nhất trong 29 màn**: nó nói kết
quả của lựa chọn hiện tại, cập nhật theo tick, và cho người dùng kiểm tra phép OR
trước khi áp dụng. `Clear` outlined, không tranh.

**15. Scroll** ✅ Sheet cuộn được, hàng cuối không bị thanh nút che.

**16. Responsive** ⚠️ Cùng rủi ro biên với tag_catalog.

**17. Safe area** ✅

**18. Empty / loading / error** ➖ chưa có golden cho thư viện không nhãn nào.

**19. Content stress** ✅ Tiếng Việt có dấu, nhãn ba đoạn, nhãn 0 thẻ, cặp
`Noun`/`nouns`.

**20. Interaction** ✅ ⚠️ Một điểm: `unused / No cards` **tick được**, và tick nó
sẽ cho kết quả 0 thẻ. Xem F1.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | bốn cấp, luật được phát biểu |
| Grouping | 2 | không divider thừa |
| Alignment | 2 | trục 72 ×48 |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 1 | hàng 72px, sheet dài nhanh |
| Typography | 2 | ~5 rung cho sheet |
| CTA | 2 | nhãn mang số sống, kiểm chứng được phép OR |
| Responsive | 1 | biên nhãn dài chưa đo |
| **Tổng** | **14 / 16** | **Pass** |

## Findings

**F1 — Nhãn 0 thẻ vẫn tick được.** ⚠️
`unused · No cards` có checkbox hoạt động. Tick nó một mình sẽ cho
`Show 0 cards` — một ngõ cụt mà bố cục mời người dùng đi vào.
Hai lối: vô hiệu hoá hàng có 0 thẻ, hoặc ẩn chúng khỏi sheet lọc (chúng vẫn hiện
ở [tag_catalog](tag_catalog.md), nơi việc thấy nhãn mồ côi là **mục đích**).
Lối thứ hai hợp hơn: hai màn có hai công việc khác nhau với cùng dữ liệu.

**F2 — Sáu checkbox 40×40, và tại sao chúng **không** phải lỗi.** ✅ ghi lại.
Probe báo sáu target dưới sàn 48. Kiểm tra bao phủ cho thấy cả sáu nằm trong
`InkWell 361×72` — tức chạm bất kỳ đâu trên hàng đều tick được.
Đây là cụm dương tính giả lớn nhất trong 29 màn, và nó là lý do phép đo target
**bắt buộc** phải kèm kiểm tra bao phủ. Không có bước đó, file này sẽ mở đầu bằng
sáu lỗi Level 1 không tồn tại.

**F3 — Sheet nói luật trước khi bắt người dùng đoán.** ✅ ghi lại làm mốc.
`Shows cards with any of the selected tags.` biến BR-231 thành một câu người dùng
đọc được, đặt **trước** danh sách. Cộng với nhãn CTA mang số sống, người dùng có
thể xác nhận luật bằng số học ngay trên màn (12 + 7 = 19).
Đây là hình mẫu cho [card_move_picker](card_move_picker.md) F1, nơi phạm vi hành
động hoàn toàn không được nhắc.
