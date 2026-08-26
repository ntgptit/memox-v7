# Progress — theo deck

Progress · `lib/features/progress/presentation/` · golden
`test/demo/goldens/progress_deck_light.png` · commit `ea80d3f7` · UC-13

**Một trong 5 golden có bottom navigation** — và `progress_overview` thì không,
dù là cùng feature. Xem [README](README.md).

## Số đo

| | |
|---|---|
| Typography rungs | **10** — **2 của bottom nav**, **8 của nội dung** |
| Rung nội dung | 57/700 (streak) · 24/600 · 22/600 · 16/600 · 14/600 · 14/400 ×60 · 12/400 · 12/600 |
| Font weight | 400, 500, 600, **700** |
| Spacer | 4×2, 8×7, 12×3, 24×2 — **toàn bộ trên scale** |
| Inset | 4×37, 8×33, 12×2, 16×26, 24×2 + **1×8 = viền của 3 thẻ** |
| Trục text trái | **32 ×40** · 352 ×14 · 60 ×12 · 232 ×12 |
| Tap target | 6 chạm được, **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ hàng chip cách thanh nav ~28px, không bị che |
| Safe area | ✅ **kiểm được ở màn này**, vì golden có thanh nav |
| Touch target | ✅ 6/6 |
| Text đọc được | ✅ |
| Component đúng chức năng | ❌ **màn không nói nó đang xem deck nào** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ⚠️ `1 day` ở 57/700 áp đảo — cùng F1 của [progress_overview](progress_overview.md) |
| Grouping đúng | ❌ chip lọc vẫn mồ côi giữa thẻ và thanh nav — nặng hơn ở đây |
| Alignment tốt | ✅ trục 32 ×40 |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ✅ ba thẻ trọn vẹn + hàng chip trong một viewport |
| Visual weight cân | ⚠️ thẻ streak nặng nhất |
| CTA prominence | ➖ màn đọc |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ |
| Typography tinh tế | ⚠️ 8 rung nội dung, 4 weight |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ |
| Mắt đi đúng flow | ⚠️ |

## Checklist 20 mục

**1. Screen structure** ❌ F1: không có gì trên màn nói đây là tiến độ của deck
nào.

**2. Visual hierarchy** ⚠️ Cùng F1 của [progress_overview](progress_overview.md).

**3. Grouping** ❌ Hàng chip `7 days / 30 days` nằm **giữa thẻ cuối và thanh
nav** — nó không thuộc thẻ nào, và ở đây còn tệ hơn màn tổng quan vì phía dưới nó
là chrome chứ không phải một thẻ khác.

**4. Alignment** ✅ Trục 32 dùng 40 lần; giá trị căn phải ở 352.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale.

**6. Typography** ⚠️ 8 rung nội dung, 4 weight — giống hệt màn tổng quan.

**7. Component sizing** ✅ Ba thẻ cùng padding, cùng viền.

**8. Density** ✅ Ba thẻ trọn vẹn.

**9. Balance** ⚠️

**10. Color hierarchy** ✅ Primary ở thanh biểu đồ, chip đang chọn, và tab đang
chọn — ba chỗ, cả ba mang nghĩa "cái này đang hoạt động".

**11. App bar** ❌ Title là `Progress` — **giống hệt màn tổng quan**. F1.

**12. List / card** ⚠️ Thẻ không bấm được nhưng trông như thẻ bấm được — cùng ghi
chú với màn tổng quan.

**13. Filter / sort / chips** ⚠️ Hai chip cùng chiều cao, selected state rõ, nhưng
vị trí mồ côi (§3).

**14. CTA** ➖

**15. Scroll** ✅ **Thanh nav không che hàng chip** — kiểm được ở màn này vì
golden có thanh nav, và kết quả là đạt.

**16. Responsive** ➖

**17. Safe area** ✅ Đây là **một trong ba màn duy nhất** trong 29 màn mà mục này
kết luận được, vì golden dựng qua shell.

**18. Empty / loading / error** ➖

**19. Content stress** ✅ **Biểu đồ ở đây đọc được**: 1, 0, 2, 0, 3, 0, 4 — bảy
thanh phân biệt rõ. Xem F2.

**20. Interaction** ⚠️ Cùng ghi chú §12.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 1 | streak áp đảo, và title không phân biệt được với màn tổng quan |
| Grouping | 0 | chip lọc mồ côi giữa thẻ cuối và thanh nav |
| Alignment | 2 | trục 32 ×40 |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 2 | ba thẻ trọn vẹn |
| Typography | 1 | 8 rung nội dung, 4 weight |
| CTA | 2 | không CTA là đúng |
| Responsive | 1 | chưa đo đa kích thước, nhưng safe area kiểm được |
| **Tổng** | **11 / 16** | **Minor fix** — nhưng F1 là lỗi định danh màn |

## Findings

**F1 — Màn tiến độ theo deck không nói nó là deck nào.** ❌
Title là `Progress`. Không có breadcrumb, không có chip ngữ cảnh, không có tên
deck ở bất cứ đâu trong viewport. Đặt cạnh
[progress_overview](progress_overview.md), hai màn **giống hệt nhau về cấu trúc**
và chỉ khác con số.
So sánh trong cùng app: [card_import_source](card_import_source.md) có chip
`Korean · TOPIK I · 142 cards`; [deck_list_level](deck_list_level.md) có
breadcrumb; [card_export_sheet](card_export_sheet.md) mở đầu bằng phạm vi. Ba màn
đó đều nhắc ngữ cảnh; màn này không.
Hướng rẻ nhất và đã có tiền lệ: một chip ngữ cảnh dưới title, đúng như wizard
import.

**F2 — Biểu đồ ở đây đọc được, và đó là bằng chứng cho F2 của màn tổng quan.** ✅
1, 0, 2, 0, 3, 0, 4 — bảy thanh, mỗi bậc phân biệt rõ bằng mắt.
Cùng một component, cùng thang tuyến tính, dữ liệu không có ngoại lai → hoạt động
tốt. Nên khiếm khuyết ở màn tổng quan (`Sun 143` nuốt sáu thanh còn lại) là vấn
đề **thang đo trước dữ liệu thật**, không phải lỗi vẽ.
Hai golden của cùng một component ở hai bộ dữ liệu là đúng loại bằng chứng §19
tồn tại để tạo ra.

**F3 — Hàng chip bị kẹp giữa thẻ cuối và thanh nav.** ❌
Ở [progress_overview](progress_overview.md) chip nằm giữa hai thẻ và mơ hồ; ở đây
nó nằm giữa một thẻ và chrome, nên nó vừa mơ hồ vừa trông như bị bỏ rơi cuối
trang. Cùng một nguyên nhân, và nó rõ hơn ở màn này.

**F4 — Hai golden của cùng một feature dựng bằng hai cách.** ⚠️ khiếm khuyết
gallery.
Màn này qua shell (có thanh nav), màn tổng quan thì không. Nên không thể đặt hai
ảnh cạnh nhau để so mật độ hay khoảng đáy — đúng việc mà gallery tồn tại để làm.
