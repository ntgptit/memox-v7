# Trash

Trash · `lib/features/trash/presentation/` · golden
`test/demo/goldens/trash_light.png` · commit `ea80d3f7` · UC-21

Soft delete, 30 ngày, restore/purge.

## Số đo

| | |
|---|---|
| Typography rungs | **4**, tất cả là nội dung |
| Rung | 22/600 (title) · 16/600 (tên mục) · 12/500 · 12/400 |
| Font weight | 400, 500, 600 |
| Spacer | 4×5 — **toàn bộ trên scale** |
| Inset | 4×1, 8×27, 12×5, 16×8 + **1×12 = viền của 3 chip** |
| Trục text trái | **48 ×14** · 32 ×4 · 85 ×4 · 155 ×4 · 16 ×4 |
| Tap target | 10 chạm được, **1 dưới 48** |
| Target nhỏ | chip `All` **42×34 → hit 42×48**, không được phủ — **hụt 6px chiều ngang** |
| Khoảng trống | ~**62%** dưới |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ⚠️ **`Phrasal v...` bị cắt** — xem F2 |
| Không overlap | ✅ |
| Safe area | ➖ |
| Touch target | ❌ **chip `All` rộng 42** — xem F1 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ⚠️ đã cắt chữ ở 393px |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ tên 16/600 → thời hạn 12/500 → nguồn 12/400 |
| Grouping đúng | ✅ **không dùng card, không divider** — chỉ khoảng trắng |
| Alignment tốt | ✅ trục 48 dùng 14 lần; hai cột hành động ở biên phải |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ hai mục trong 38% trên |
| Visual weight cân | ⚠️ |
| CTA prominence | ⚠️ **restore và ⋮ cạnh nhau, một trong hai chứa hành động phá huỷ** — xem F3 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ |
| Optical alignment | ✅ icon loại căn theo dòng tên; hai icon hành động căn giữa theo hàng |
| Typography tinh tế | ✅ **4 rung** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ **`28 days left` dùng màu riêng** — đúng, nó là thứ duy nhất trên hàng có hạn |
| Mắt đi đúng flow | ✅ tên → còn bao lâu → từ đâu tới |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu. Dòng
`Items here are deleted forever after 30 days.` nói luật ngay trước danh sách —
cùng cách với [tag_filter_sheet](tag_filter_sheet.md) F3, và cũng đúng.

**2. Visual hierarchy** ✅ Ba cấp trong hàng. Thời hạn được tô màu riêng nên nó
nổi lên khỏi hai dòng metadata cùng cỡ.

**3. Grouping** ✅ Không card, không divider — như [tag_catalog](tag_catalog.md).
Hai mục cách nhau đủ để đọc thành hai khối.

**4. Alignment** ✅ Trục 48 dùng 14 lần; icon loại ở 16; hai icon hành động ở hai
trục biên phải cố định. Hàng 3 dòng và hàng 4 dòng vẫn giữ nguyên các trục.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ✅ **4 rung** — trong nhóm sạch nhất của 29 màn.

**7. Component sizing** ⚠️ Ba chip lọc cùng chiều cao (34) ✅, nhưng bề rộng theo
nhãn nên `All` chỉ 42 — F1. §13 nói chip cùng nhóm cùng chiều cao; nó không nói
gì về bề rộng, nhưng §7 nói touch target tối thiểu 48.

**8. Density** ⚠️ Hai mục cho 38% trên. Danh sách thật sẽ đầy hơn.

**9. Balance** ⚠️

**10. Color hierarchy** ✅ Đúng **một** màu ngữ nghĩa trên toàn màn, dành cho thời
hạn còn lại. Không dùng đỏ cho Trash — hợp lý, vì các mục ở đây **chưa** bị xoá
vĩnh viễn.

**11. App bar** ✅ Title + một action (chọn nhiều). Gọn.

**12. List / card** ⚠️ Mỗi hàng có hierarchy rõ, metadata không tranh tên. Nhưng
xem F3 về hai vùng chạm cạnh nhau.

**13. Filter / sort / chips** ⚠️ Ba chip `All` / `Cards` / `Decks` cùng chiều cao,
spacing đều, selected state rõ. F1 về bề rộng.

**14. CTA** ⚠️ F3.

**15. Scroll** ✅

**16. Responsive** ⚠️ F2 — đã cắt ở kích thước mặc định.

**17. Safe area** ➖

**18. Empty / loading / error** ➖ Trash rỗng chưa có golden trong 29 màn — và đó
là trạng thái **thường gặp nhất** của màn này.

**19. Content stress** ✅ Có một thẻ và một deck (hai loại), có deck kèm số lượng
con (`3 decks, 37 cards`), có hai mốc thời gian khác nhau. Và nó lộ F2.

**20. Interaction** ⚠️ F3.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | ba cấp, thời hạn được tô đúng chỗ |
| Grouping | 2 | không card, không divider, vẫn đọc rành mạch |
| Alignment | 2 | trục 48 ×14 giữ nguyên qua hàng 3 và 4 dòng |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 1 | hai mục cho 38% trên |
| Typography | 2 | 4 rung |
| CTA | 1 | restore và ⋮ cạnh nhau, ⋮ chứa hành động phá huỷ |
| Responsive | 0 | **đã cắt chữ ở 393px** |
| **Tổng** | **12 / 16** | **Minor fix** |

## Findings

**F1 — Chip `All` rộng 42px.** ❌ Level 1.
Hit-test thật: hộp 42×34, target hiệu dụng 42×48 — Material nới chiều dọc nhưng
**không** nới chiều ngang, và chip không nằm trong target nào lớn hơn. Hụt 6px so
với sàn 48.
Đây là chip **đầu tiên** trong hàng, tức chip mà ngón cái chạm nhiều nhất, và nó
là chip hẹp nhất vì nhãn ngắn nhất.
Sửa: `minWidth: AppSpacing.minimumTouchTarget` cho chip lọc. Nó cũng làm ba chip
đều hơn về thị giác.

**F2 — `From English › Grammar › Phrasal v...` bị cắt.** ⚠️
Đường dẫn nguồn của mục bị xoá là thông tin **cần** để quyết định có khôi phục
hay không — nó nói mục này sẽ quay về đâu. Cắt ở giữa tên deck cuối là cắt đúng
phần mang thông tin.
§16 nói không truncate dữ liệu quan trọng. Ở 393px tiếng Anh đã cắt.
Hướng: cắt từ **giữa** đường dẫn (`English › … › Phrasal verbs`) thay vì cắt
đuôi, như breadcrumb của [card_list](card_list.md) vẫn làm với `…`.

**F3 — Restore và ⋮ nằm cạnh nhau, và ⋮ chứa hành động phá huỷ.** ⚠️
Hai icon cách nhau ~47px tâm-tới-tâm ở biên phải mỗi hàng. Một cái khôi phục, cái
kia mở menu gần như chắc chắn chứa "Delete forever".
§20 nói các action quan trọng không được nằm quá sát nhau — và ở đây một trong
hai là **không hoàn tác được**, trên một màn mà toàn bộ mục đích là hoàn tác.
So sánh: [card_bulk_delete_dialog](card_bulk_delete_dialog.md) đặt hành động phá
huỷ sau một dialog xác nhận và không tô màu error vì nó hoàn tác được. Ở đây
hành động **thật sự** không hoàn tác lại nằm sau một icon 48px cạnh nút khôi
phục.
Ít nhất: tăng khoảng cách giữa hai icon, và giữ xác nhận cho purge.

**F4 — Trash rỗng chưa có ảnh.** ➖ → thiếu sót đáng chú ý.
Trạng thái phổ biến nhất của màn này là **rỗng**. `deck_list_empty`,
`tag_catalog_empty` và `card_move_picker_empty` đều có golden; Trash thì không.
