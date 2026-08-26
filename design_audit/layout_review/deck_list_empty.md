# Deck list — rỗng

Library & Deck · `lib/features/deck/presentation/screens/deck_list_screen.dart`
· golden `test/demo/goldens/deck_list_empty_light.png` · commit `ea80d3f7`

Đây là màn đã thúc đẩy [#337](https://github.com/ntgptit/memox-v7/pull/337): hai
nút trước kia rộng theo label của chính chúng, `Browse starter library` dài hơn
hẳn `New deck`. Golden này là bản **sau** khi `MxButtonPair` cân lại — và nó chỉ
đúng từ [PR #340](https://github.com/ntgptit/memox-v7/pull/340), vì #337 không vẽ
lại ảnh nào.

## Số đo

| | |
|---|---|
| Typography rungs | **7** — 3 là bottom nav, **4** của nội dung |
| Rung nội dung | 22/600 (title) · 16/600 (nút) · 14/600 (heading rỗng) · 14/400 (mô tả) |
| Font weight | 400, 500, 600 — **không có 700** |
| Spacer | 8×3, 16×1, 24×1 — **toàn bộ trên scale** |
| Inset | 4×4, 8×8, 12×4, 24×8 — **toàn bộ trên scale** |
| Trục text trái | 16 ×4 · 27 ×4 · 129 ×4 · 218 ×4 · 318 ×4 |
| Tap target | 9 chạm được, **0 dưới 48** |

Hai nút bằng nhau đúng theo đo: cả hai `MxButtonPair` con đều rộng bằng cột nội
dung, cao bằng nhau qua `IntrinsicHeight`.

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ FAB nằm trên vùng trống, không đè gì |
| Safe area | ➖ |
| Touch target | ✅ 9/9 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ➖ — nhưng `MxButtonPair` có nhánh xếp chồng khi hẹp; xem §16 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ một điểm nhấn: `Browse starter library` tô đặc, `New deck` outlined |
| Grouping đúng | ✅ icon → title → mô tả → hai nút đọc thành một khối |
| Alignment tốt | ✅ hai nút cùng trục, cùng bề rộng |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ⚠️ **~40% chiều cao màn là khoảng trống phía trên** — xem F2 |
| Visual weight cân | ⚠️ khối nội dung nằm hơi thấp so với tâm quang học |
| CTA prominence | ❌ **FAB lặp lại đúng hành động của nút `New deck`** — xem F1 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ nhiều, nhưng phân bố lệch: dồn hết lên trên |
| Optical alignment | ✅ |
| Typography tinh tế | ✅ 4 rung, 3 weight — **màn sạch nhất nhóm này** |
| Icon/text proportion | ✅ icon 40px trên title 22 |
| Surface/color hierarchy | ⚠️ hai khối primary (nút chính + FAB) cho một màn không có nội dung |
| Mắt đi đúng flow | ⚠️ mắt xuống tới hai nút rồi bị FAB kéo ngược sang phải |

## Checklist 20 mục

**1. Screen structure** ✅ App Bar → empty state → Bottom nav. Cấu trúc màn được
**giữ nguyên** khi không có dữ liệu, đúng §18.

**2. Visual hierarchy** ✅ Đúng một điểm nhấn cấp 1. `Browse starter library` tô
đặc, `New deck` outlined — CTA phụ không tranh với CTA chính.

**3. Grouping** ✅ Năm phần tử, một nhóm, spacing trong nhóm 8–24 nhỏ hơn khoảng
trống bao quanh. Không dùng divider.

**4. Alignment** ✅ Hai nút chung trục và **chung bề rộng** — đây chính là thứ
#337 sửa. Text căn giữa, nhưng là hai dòng ngắn nên không vi phạm §4.

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale.

**6. Typography** ✅ **4 rung nội dung, 3 weight.** Đạt mốc 3–5 của checklist —
màn duy nhất trong nhóm Deck đạt.

**7. Component sizing** ✅ Hai nút cùng chiều cao qua `IntrinsicHeight`.

**8. Density** ⚠️ Xem F2.

**9. Balance** ⚠️ Khối nội dung nằm ở khoảng 55% chiều cao. Với empty state,
tâm quang học thường ở 40–45%; ở đây phần trống phía trên nặng hơn phía dưới.

**10. Color hierarchy** ⚠️ Primary dùng 3 chỗ: icon rỗng, nút chính, FAB. Icon
primary trên một màn rỗng là hợp lý (nó là thứ duy nhất có màu); FAB là F1.

**11. App bar** ✅ `0 decks · 0 cards` — dòng phụ vẫn nói sự thật khi rỗng, không
bị ẩn đi. Tốt: người dùng biết mình đang nhìn một thư viện trống chứ không phải
một màn đang tải.

**12. List / card** ➖ không có list.

**13. Filter / sort / chips** ✅ Không hiện toolbar sort khi không có gì để sắp —
đúng.

**14. CTA** ❌ F1.

**15. Scroll** ✅ Không cần cuộn, không có nested scroll.

**16. Responsive** ⚠️ `MxButtonPair` **có** nhánh xếp chồng khi màn quá hẹp cho
hai label, và `mx_button_pair_test.dart` đo hình chữ nhật sau layout. Đó là bằng
chứng thật cho một phần của §16 — nhiều hơn hầu hết màn khác có. Nhưng vẫn chưa
có render ở 360/412 hay font scale lớn cho **màn này**.

**17. Safe area** ➖

**18. Empty / loading / error** ✅ Chính nó là empty state, và nó **giữ cấu
trúc**: app bar còn, bottom nav còn, dòng thống kê còn. Có hành động tiếp theo
rõ ràng, hai lối. Không để màn trắng.

**19. Content stress** ✅ với 0 item — đây là trường hợp 0 item. ➖ cho các
trường hợp còn lại.

**20. Interaction** ❌ F1: hai thứ trông khác nhau nhưng làm cùng một việc.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | một điểm nhấn, CTA phụ nhường đúng cách |
| Grouping | 2 | một khối, đọc liền mạch |
| Alignment | 2 | hai nút cùng trục cùng bề rộng |
| Spacing | 2 | 0 ngoài scale |
| Density | 1 | khoảng trống dồn lên trên |
| Typography | 2 | 4 rung, 3 weight |
| CTA | 1 | FAB lặp lại nút `New deck` |
| Responsive | 1 | có `mx_button_pair_test` nhưng chưa có render đa kích thước |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — FAB và nút `New deck` là cùng một hành động.** ❌
Màn rỗng đưa ra hai lối vào có chủ đích (starter catalog / deck mới) — đó là
thiết kế đúng. Nhưng FAB `+` ở góc phải dưới **cũng** tạo deck mới, nên trên màn
có ba nút cho hai việc. §14 nói một primary CTA cho một context; §20 nói action
quan trọng phải rõ ràng. Ở trạng thái rỗng, FAB không thêm gì mà chỉ làm loãng
cặp nút vừa được cân bằng cẩn thận ở #337.
Hướng: ẩn FAB khi list rỗng. Nó có lý do tồn tại khi có list để cuộn — không có
lý do khi thứ duy nhất trên màn đã là hai nút.

**F2 — Gần 40% chiều cao màn là khoảng trống trên đầu.** ⚠️
Khối nội dung bắt đầu ở khoảng 55% chiều cao. §8 nói màn không nên quá trống, và
§9 nói top area không nên nặng/nhẹ bất thường so với body. Ở đây body bị đẩy
xuống dưới tâm.
Đây là hệ quả của việc căn giữa theo **toàn bộ** vùng cuộn thay vì theo vùng
quang học. Kéo khối lên khoảng 42–45% sẽ cân hơn mà không đổi gì khác.

**F3 — Màn sạch nhất về typography trong nhóm.** ✅ ghi lại làm mốc.
4 rung, 3 weight, không có 700. Ba màn deck còn lại đều 7 rung / 4 weight. Khác
biệt không phải do màn này đơn giản hơn — mà do nó **không có hero numeral**,
thứ một mình kéo theo cả rung 32 lẫn weight 700.
