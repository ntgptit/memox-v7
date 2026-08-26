# Card detail — lỗi trang sau

Card · `lib/features/card/presentation/` · golden
`test/demo/goldens/card_detail_page_error_light.png` · commit `ea80d3f7`

Band D24: khi trang lịch sử kế tiếp lỗi, **giữ lại những gì đã đọc**. Xem F1 —
render không cho thấy điều đó.

## Số đo

| | |
|---|---|
| Typography rungs | **7**, tất cả là nội dung |
| Font weight | 400, 500, 600 |
| Spacer | 4×6, 8×2, 12×4, 32×2 — **toàn bộ trên scale** |
| Inset | 4×4, 8×15, 12×4, 16×6, 24×1 — **toàn bộ trên scale** |
| Trục text trái | 16 ×36 · 144 ×18 · 62 ×5 · 56 ×4 |
| Tap target | 3 chạm được, **0 dưới 48** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ➖ |
| Touch target | ✅ 3/3, gồm `Retry` |
| Text đọc được | ✅ |
| Component đúng chức năng | ⚠️ **thông báo nói "trang sau" nhưng không có trang trước nào hiện** — F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ khối lỗi là surface duy nhất trên màn, không thể bỏ sót |
| Grouping đúng | ✅ icon + tiêu đề + mô tả + hành động nằm gọn trong một container |
| Alignment tốt | ✅ trục 16 ×36, cột giá trị 144 ×18 giữ nguyên như bản không lỗi |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ✅ |
| Visual weight cân | ✅ khối lỗi nặng vừa đủ, không nuốt phần trên |
| CTA prominence | ✅ `Retry` là hành động duy nhất trong ngữ cảnh lỗi |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ⚠️ `Retry` thụt vào 56 trong khi tiêu đề lỗi ở 62 và icon ở 40 — ba trục trong một khối nhỏ |
| Typography tinh tế | ✅ |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ **màu error chỉ dùng ở đúng chỗ có lỗi** |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ✅ Giữ nguyên cấu trúc của bản không lỗi. Lỗi được đặt
**tại chỗ nó xảy ra** (cuối section lịch sử) chứ không ném lên đầu màn hay thành
snackbar. Đây là cách xử lý lỗi cục bộ đúng.

**2. Visual hierarchy** ✅ Khối lỗi là thứ duy nhất có nền màu → không thể bỏ qua,
mà cũng không lấn phần nội dung đã đọc được.

**3. Grouping** ✅ Bốn phần tử của khối lỗi đọc thành một nhóm.

**4. Alignment** ✅ Phần trên giữ nguyên hai trục 16/144.

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale.

**6. Typography** ✅ 7 rung — ít hơn bản không lỗi một rung, vì list lịch sử
không render.

**7. Component sizing** ✅

**8. Density** ✅

**9. Balance** ✅

**10. Color hierarchy** ✅ Đây là **cách dùng màu semantic đúng nhất trong 29
màn**: một khối, một màu, và nó nói đúng điều đang xảy ra. Đối lập với card
editor, nơi màu error tô một nút mà người dùng chưa bấm.

**11. App bar** ⚠️ Title `Card` — cùng ghi chú với [card_detail](card_detail.md).

**12. List / card** ➖ list không render — chính là F1.

**13. Filter / sort / chips** ✅

**14. CTA** ✅ `Retry` rõ ràng, là bước tiếp theo duy nhất. §18 "Error state có
hành động tiếp theo rõ ràng" — đạt.

**15. Scroll** ✅

**16. Responsive** ➖

**17. Safe area** ➖

**18. Empty / loading / error** ✅ với error. **Đây là error state tốt**: giữ cấu
trúc màn, không màn trắng, có hành động tiếp theo, đặt lỗi đúng chỗ nó xảy ra.
Trừ F1.

**19. Content stress** ➖

**20. Interaction** ✅ `Retry` trông bấm được và đủ lớn.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | khối lỗi nổi đúng mức, không lấn |
| Grouping | 2 | một nhóm gọn |
| Alignment | 2 | giữ nguyên hai trục của bản không lỗi |
| Spacing | 2 | 0 ngoài scale |
| Density | 2 | |
| Typography | 2 | 7 rung, không tăng so với bản thường |
| CTA | 2 | một hành động, đúng ngữ cảnh |
| Responsive | 1 | chưa đo |
| **Tổng** | **15 / 16** | **Pass** — điểm cao nhất trong 29 màn |

## Findings

**F1 — Không có mục lịch sử nào phía trên khối lỗi.** ⚠️ cần xác định.
Thông báo là `The next page could not be loaded` — nói rõ đây là lỗi của trang
**kế tiếp**, và band D24 tồn tại để **giữ những gì đã đọc**. Nhưng dưới tiêu đề
`Study history` không có một mục nào; khối lỗi bắt đầu ngay.
Nên bức ảnh minh hoạ cho D24 lại không cho thấy D24 đang hoạt động. Hai khả năng:
- fixture demo dựng trạng thái "trang 1 rỗng, trang 2 lỗi", tức golden chọn sai
  kịch bản để minh hoạ hành vi mà nó mang tên;
- hoặc trang đã đọc **thật sự bị bỏ** khi trang sau lỗi, tức D24 không được giữ.

Cái thứ hai là bug thật và không gate nào hiện có bắt được — golden chỉ so với
bản chụp hôm qua của chính nó, nên một trạng thái sai từ lần render đầu tiên sẽ
xanh mãi mãi. Cần một test đọc số mục lịch sử trước và sau khi trang sau lỗi.

**F2 — Ba trục trong khối lỗi.** ⚠️ Level 3.
Icon ở 40, tiêu đề `Couldn't load more` ở 62, mô tả ở 56, `Retry` ở 56. Tiêu đề
lệch 6px so với hai dòng dưới nó. §4 nói không có khoảng lệch 2–5px vô chủ đích —
đây là 6px, và nó đến từ việc tiêu đề nằm cạnh icon còn hai dòng kia thì không.
Cho mô tả và `Retry` thụt bằng tiêu đề (62) sẽ khiến khối đọc thành một cột.
