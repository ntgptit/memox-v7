# Bulk delete — confirm

Card · `lib/shared/widgets/mx_confirm_dialog.dart` · golden
`test/demo/goldens/card_bulk_delete_dialog_light.png` · commit `ea80d3f7`

Biến thể *cautious*: xoá là **có thể hoàn tác** (Trash giữ 30 ngày), và nút xác
nhận nói đúng điều đó — `Move to Trash`, không phải `Delete`.

Số typography là của **hai** màn cộng lại; sheet đè lên [card_list](card_list.md).
17/18 target bị modal barrier chặn và đã bị probe loại.

## Số đo

| | |
|---|---|
| Typography rungs | **11 tổng** — **3 là của dialog**, còn lại là card list phía sau |
| Rung của dialog | 16/600 (tiêu đề + nhãn nút) · 14/400 (nội dung) · 12/… |
| Spacer | 4×7, 8×5, 12×7 — **toàn bộ trên scale** |
| Inset | 4×11, 8×31, 12×7, 16×27, 24×18 + 1×20 viền + **40×2 = `insetPadding` mặc định của Material `AlertDialog`** |
| Tap target | **2 chạm được** (Cancel, Move to Trash), **18 bị che**, **0 dưới 48** |
| Bề rộng dialog | 393 − 2×40 = **313**, nên mỗi nút được ~130 |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ⚠️ **nhãn nút xuống hai dòng** — xem F1 |
| Không overlap | ✅ |
| Safe area | ✅ dialog căn giữa |
| Touch target | ✅ 2/2 |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ❌ **hỏng ở kích thước đang đo** — F1 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ tiêu đề → hậu quả → hai hành động |
| Grouping đúng | ✅ |
| Alignment tốt | ⚠️ hai nút bằng nhau về hộp nhưng **nhãn không cùng số dòng**, nên chữ không cùng đường baseline |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ✅ |
| Visual weight cân | ✅ |
| CTA prominence | ✅ |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ❌ F1: nhãn hai dòng phá đường ngang của cặp nút |
| Typography tinh tế | ✅ 3 rung cho dialog |
| Icon/text proportion | ➖ không có icon |
| Surface/color hierarchy | ✅ **không dùng màu error** — đúng, vì hành động này hoàn tác được |
| Mắt đi đúng flow | ✅ |

## Checklist 20 mục

**1. Screen structure** ✅ Dialog có đúng ba phần: hỏi gì, hậu quả là gì, làm gì.

**2. Visual hierarchy** ✅ Tiêu đề 16/600 là cấp 1; nội dung 14/400 thấp hơn; nút
đặc là hành động chính.

**3. Grouping** ✅

**4. Alignment** ⚠️ F1.

**5. Spacing & rhythm** ✅ Mọi giá trị app trên scale. Inset 40 là mặc định của
Material `AlertDialog`, đã truy nguồn — xem F2.

**6. Typography** ✅ Dialog chỉ dùng 3 rung.

**7. Component sizing** ✅ Hai nút cùng hộp nhờ `MxButtonPair` (#337) — đó chính
là thứ PR đó sửa, và nó **đang hoạt động**. Vấn đề F1 nằm ở nhãn chứ không ở hộp.

**8. Density** ✅

**9. Balance** ✅

**10. Color hierarchy** ✅ **Đây là quyết định màu đúng nhất trong nhóm Card**:
hành động phá huỷ nhưng hoàn tác được thì dùng primary, không dùng error. So với
[card_editor_edit](card_editor_edit.md) F1, nơi `Delete card` là khối đỏ đặc —
hai màn đối xử khác nhau với hai mức độ nguy hiểm khác nhau, và cả hai đều nhất
quán với chính mức độ đó.

**11. App bar** ➖

**12. List / card** ➖

**13. Filter / sort / chips** ➖

**14. CTA** ✅ Một primary, một outlined. Nhãn nút **nói hành động thật**
(`Move to Trash`), không phải `OK`. Nội dung nói rõ 30 ngày.

**15. Scroll** ➖

**16. Responsive** ❌ F1.

**17. Safe area** ✅

**18. Empty / loading / error** ➖

**19. Content stress** ⚠️ Đây **là** một ca stress: nhãn nút dài trong hộp hẹp.
Và nó lộ ra F1.

**20. Interaction** ✅ `Cancel` có viền primary, `Move to Trash` đặc — phân biệt
được đâu là hành động mặc định an toàn.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | ba phần rõ, nhãn nút nói hành động thật |
| Grouping | 2 | |
| Alignment | 1 | nhãn hai dòng phá đường ngang của cặp nút |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 2 | |
| Typography | 2 | 3 rung |
| CTA | 2 | primary/outlined rõ, không lạm dụng màu error |
| Responsive | 0 | **hỏng ở 393px, chưa cần tới 360** |
| **Tổng** | **13 / 16** | **Minor fix** |

## Findings

**F1 — `Move to Trash` xuống hai dòng, `Cancel` một dòng.** ❌
Đo được: hai nút là **128,5 × 64** tại x = 64 và 200,5. Cao 64 thay vì 48 chính
là dấu hiệu của hai dòng nhãn. Vùng nội dung dialog rộng **265** (từ 64 đến 329).

`MxButtonPair` có nhánh xếp chồng đúng cho ca này, và nó **không** kích hoạt vì
được đưa sai bề rộng:

```dart
final line = MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;   // 393-32 = 361
return line < minButtonWidth * scale * 2 + AppSpacing.sm;            // 361 < 136*2+8 = 280  -> false
```

Đưa bề rộng **thật** vào cùng công thức đó thì `265 < 280` → **true**, tức pair
đã tự xếp chồng. Nói cách khác quy tắc là đúng, chỉ có đầu vào là sai: nó đo màn
hình trong khi nút sống trong một hộp hẹp hơn 96px.

Đáng chú ý hơn: doc của `minButtonWidth` ghi 136 là "bề rộng `Export 128 cards`
cần ở 1.0×". Mỗi nút ở đây chỉ có **128,5** — tức đã nằm dưới chính ngưỡng mà
component tự đặt cho mình.

Đây không phải lỗi của #337 mà là một hệ quả nó chưa phủ: PR đó **cố ý** đọc
`MediaQuery` thay vì `LayoutBuilder`, vì `AlertDialog` bọc actions trong
`IntrinsicWidth` và `LayoutBuilder` ném lỗi khi bị hỏi kích thước intrinsic —
điều này có ghi trong mô tả PR.
Nên hướng sửa **không** phải đổi sang `LayoutBuilder`. Hai lối khả dĩ:
- cho `MxButtonPair` nhận một tham số bề rộng khả dụng, và `MxConfirmDialog`
  truyền vào `width − insetPadding − padding`;
- hoặc dialog dùng nhánh xếp chồng mặc định, vì 313px không bao giờ đủ cho hai
  nhãn động.

Ở tiếng Việt (`Chuyển vào thùng rác`) nhãn còn dài hơn, nên đây sẽ tệ hơn chứ
không nhẹ đi.

**F2 — `insetPadding` 40 là mặc định của Material, không phải token của app.** ⚠️
Bậc lớn nhất của `AppSpacing.scale` là 32. Dialog đang lấy 40 từ Material, và
chính 40 đó là thứ khiến F1 xảy ra — hạ xuống 24 sẽ cho mỗi nút thêm 16px và
nhãn hết xuống dòng, đồng thời đưa giá trị này về trong hệ.
Đây là hai lỗi chung một nguyên nhân, và cách sửa rẻ nhất giải cả hai.

**F3 — Hai màn xoá dùng hai hệ màu, và cả hai đều đúng.** ✅ ghi lại làm quy tắc.
Ở đây: hoàn tác được → primary. Ở [card_editor_edit](card_editor_edit.md): nút
`Delete card` → error. Sự khác biệt **có nghĩa**, nên đáng được viết thành quy
tắc rõ ràng thay vì để nó tồn tại như một trùng hợp — nếu không, lần tới ai đó sẽ
đồng bộ hai màn về một màu và làm mất tín hiệu.
