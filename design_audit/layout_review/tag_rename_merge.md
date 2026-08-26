# Tag rename / gộp

Tag · `lib/features/tag/presentation/widgets/overlays/` · golden
`test/demo/goldens/tag_rename_merge_light.png` · commit `ea80d3f7`

Đổi tên thành một nhãn đã tồn tại = gộp, và màn **nói trước khi làm**. Số
typography là của hai màn cộng lại — sheet đè lên
[tag_catalog](tag_catalog.md); 13/15 target bị barrier chặn.

## Số đo

| | |
|---|---|
| Typography rungs | **7 tổng** — **~4 là của sheet** |
| Rung của sheet | 16/600 (`Rename tag`) · 16/400 (nội dung field) · 14/400 (cảnh báo) · 14/600 (nhãn nút) |
| Font weight | **400, 600 — chỉ hai** |
| Spacer | **không có spacer rời nào** |
| Inset | 4×13, 8×26, 12×5, 16×18, 24×4 + **13×4 = tay cầm chọn text của framework** + 48×1 vùng sheet |
| Trục text trái | 32 ×48 (nền) · 329 ×5 · 16 ×4 · 36 ×4 |
| Tap target | 2 chạm được (Cancel, Merge tags), 13 bị che, **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ cảnh báo hai dòng, không cắt |
| Không overlap | ✅ |
| Safe area | ✅ |
| Touch target | ✅ 2/2 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ **nhãn nút đổi theo nội dung đang gõ** |
| Responsive | ⚠️ nhãn `Merge tags` vừa khít ở 393px — xem F2 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ tiêu đề → field → hậu quả → hành động |
| Grouping đúng | ✅ cảnh báo đặt **giữa** field và nút — đúng thứ tự nhân quả |
| Alignment tốt | ✅ cảnh báo thụt bằng nội dung field |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ✅ sheet chỉ cao bằng thứ nó cần |
| Visual weight cân | ✅ |
| CTA prominence | ✅ |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ icon gộp căn theo dòng đầu của cảnh báo |
| Typography tinh tế | ✅ ~4 rung, **2 weight** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ⚠️ **cảnh báo không có màu cảnh báo** — xem F1 |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu, ba phần, đọc từ trên xuống là một câu
hoàn chỉnh.

**2. Visual hierarchy** ✅ Field đang focus có viền và nhãn màu primary — trạng
thái focus rõ (§20).

**3. Grouping** ✅ Cảnh báo nằm giữa nguyên nhân (field) và hậu quả (nút) — vị trí
đúng nhất có thể.

**4. Alignment** ✅ Cảnh báo thụt bằng chữ trong field; icon ở trục riêng.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale. 13px là tay cầm chọn text
của Flutter, đã truy nguồn.

**6. Typography** ✅ ~4 rung, **2 weight** — cùng mức sạch với
[tag_catalog](tag_catalog.md).

**7. Component sizing** ✅ Hai nút cùng kích thước.

**8. Density** ✅ Sheet cao đúng bằng nội dung.

**9. Balance** ✅

**10. Color hierarchy** ⚠️ F1.

**11. App bar** ➖

**12. List / card** ➖

**13. Filter / sort / chips** ➖

**14. CTA** ✅ **Nhãn nút là `Merge tags`, không phải `Rename`** — nó đổi theo
điều sắp thực sự xảy ra. Đây là mức nhãn CTA cao nhất: không chỉ mô tả hành động
mà mô tả **hành động đã được diễn giải theo dữ liệu hiện tại**. Ngang với
`Show 19 cards` của [tag_filter_sheet](tag_filter_sheet.md).

**15. Scroll** ➖

**16. Responsive** ⚠️ F2.

**17. Safe area** ✅

**18. Empty / loading / error** ➖

**19. Content stress** ✅ Đây **là** ca stress của tag: tên trùng khác hoa thường.
Và màn xử lý đúng — cảnh báo, đổi nhãn nút, nói rõ nhãn nào sống sót.

**20. Interaction** ✅ Field focus rõ. Con trỏ nhìn thấy được. `Cancel` outlined.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | bốn phần đọc thành một câu |
| Grouping | 2 | cảnh báo đặt giữa nguyên nhân và hậu quả |
| Alignment | 2 | cảnh báo thụt bằng nội dung field |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 2 | sheet cao đúng bằng nội dung |
| Typography | 2 | ~4 rung, 2 weight |
| CTA | 2 | nhãn đổi theo dữ liệu, nói đúng hậu quả |
| Responsive | 1 | `Merge tags` vừa khít, tiếng Việt sẽ dài hơn |
| **Tổng** | **15 / 16** | **Pass** — ngang [card_detail_page_error](card_detail_page_error.md) và [card_export_sheet](card_export_sheet.md) |

## Findings

**F1 — Cảnh báo không mang màu cảnh báo.** ⚠️ Level 3.
Câu `"Noun" already exists. Its cards and this tag's cards will all use "Noun",
and this tag will be gone.` báo một hành động **không hoàn tác trực tiếp được**
(nhãn này biến mất), nhưng nó là chữ 14/400 màu thứ cấp, cùng cấp với mọi dòng
phụ khác trong app.
Đây là mặt thứ hai của bất đối xứng đã ghi ở
[card_import_result_complete](card_import_result_complete.md) F3: app tô màu cho
**lỗi**, nhưng không tô cho **thành công** và cũng không tô cho **cảnh báo**.
Không nhất thiết phải đỏ — nhưng một câu quyết định hậu quả không nên trông giống
một dòng chú thích.

Ghi chú công bằng: nút vẫn là `Merge tags` chứ không phải `Rename`, nên tín hiệu
**có** tồn tại, chỉ là nó nằm ở nhãn nút chứ không ở câu giải thích.

**F2 — `Merge tags` vừa khít trong nửa sheet ở 393px.** ⚠️
Khác với [card_bulk_delete_dialog](card_bulk_delete_dialog.md) F1, sheet này rộng
gần trọn màn nên `MxButtonPair` có đủ chỗ và không xuống dòng. Nhưng nhãn tiếng
Việt (`Gộp nhãn`) ngắn hơn nên an toàn, còn ở text scale lớn thì chưa đo.
Đáng chú ý: doc của `MxButtonPair.minButtonWidth` **nhắc đích danh** `Merge tags`
là một trong các nhãn được đo khi chọn ngưỡng 136 — nên ca này đã được nghĩ tới.

**F3 — Đây là hình mẫu cho việc "nói trước khi làm".** ✅ ghi lại.
Ba thứ cùng lúc: cảnh báo xuất hiện **khi đang gõ** chứ không sau khi bấm, nó nêu
đích danh nhãn nào sống sót, và nhãn nút đổi để khớp. So với
[card_move_picker](card_move_picker.md), nơi chạm một hàng là thực hiện ngay mà
không nhắc lại phạm vi.
