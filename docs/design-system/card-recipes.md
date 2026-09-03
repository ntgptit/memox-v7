# Card recipes — `MxCard`

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi lại mười recipe của `MxCard`: mỗi cái nghĩa là gì, ai gọi, vẽ ra sao, và vì sao nó tồn tại riêng |
| **Scope** | Taxonomy và hợp đồng công khai của `MxCard`. Ngoài phạm vi: *giá trị* token (AD-14), layering của `lib/core/theme/` (`theme-architecture.md`), binding component→role M3 (`tokyo-component-mapping.md`) |
| **Source of truth for** | Ma trận recipe `MxCard` · hợp đồng `MxCard.option` · quyết định tên `tonal` |
| **Depends on** | `document-conventions.md` · `theme-architecture.md` · `architecture.md` (AD-14, AD-15) |
| **Updated by task** | M100.35 |
| **Last updated** | 2026-09-03 |

---

## 1. Vì sao có tài liệu này

`MxCard` không nhận `color`, `borderColor`, `radius`, `elevation` hay
`EdgeInsets`. Người gọi chọn **card này *là* cái gì**, còn phần vẽ là spec riêng
của từng recipe. Điều đó chỉ đứng vững khi mỗi recipe có một lý do tồn tại
riêng — nếu không, mười constructor chỉ là mười cách viết `color:` vòng vèo.

M100.35 kiểm lại cả mười. **Không recipe nào chết** và không recipe nào bị gỡ;
một câu mô tả sai đã được sửa, và một hợp đồng đã được đóng lại.

## 2. Ma trận

Số caller đếm trong `lib/` (không tính test, Widgetbook, tài liệu).

| Recipe | Nghĩa | Caller | Fill | Viền nghỉ | Elevation | Radius | Padding |
|---|---|---:|---|---|---|---|---|
| `flat` | Bề mặt nằm *trong* một bề mặt khác — cha đã tách nền rồi | 16 | `surfaceContainerLow` | không | `none` | `lg` 16 | `standard` 16 |
| `raised` | Card thường trên trang | 22 | `surfaceContainerLow` | không | `card` 1 | `lg` 16 | `standard` 16 |
| `focal` | Một bề mặt đứng riêng, mỗi màn một cái | 5 | `surfaceContainerLow` | không | `raised` 3 | `xl` 20 | `standard` 16 |
| `recessed` | Hõm xuống — ô nhập, ô đáp án | 5 | `surfaceContainerLowest` | theo state | `none` | `xl` 20 | `standard` 16 |
| `feedback` | Băng lỗi/cảnh báo | 4 | `errorContainer` | không | `none` | `lg` 16 | `compact` 12 |
| `muted` | Chú thích đặt cạnh nội dung | 5 | `surfaceContainerHigh` | không | `none` | `lg` 16 | `compact` 12 |
| `tonal` | Callout nhấn — xem §4 | 2 | `semantic.surfaceEmphasis` | không | `none` | `lg` 16 | `standard` 16 |
| `accent` | Card được đánh dấu bằng viền thương hiệu | 4 | `surfaceContainerLow` | `borderAccent` | `raised` 3 | `lg` 16 | `standard` 16 |
| `tile` | Hàng trong dòng thời gian | 2 | `surfaceContainerLow` | không | `card` 1 | `md` 12 | `compact` 12 |
| `option` | Một lựa chọn bấm được — xem §3 | 4 | `surfaceContainerLow` | `borderOption` | `none` | `lg` 16 | `compact` 12 |

Bốn recipe dùng chung `surfaceContainerLow` và **đó là chủ ý**: `flat`,
`raised`, `focal`, `accent`, `tile` đều là *cùng một mặt giấy*. Cái phân biệt
chúng là độ sâu (`none` / `card` / `raised`), góc (`md` / `lg` / `xl`) và viền —
tức **paint và composition**, không phải role. Đổi role theo recipe sẽ khiến
"card" mang năm danh tính ngữ nghĩa cho một thứ vốn là một.

Ba recipe rời khỏi mặt giấy vì chúng *không* phải mặt giấy: `recessed` hõm
xuống (`Lowest`), `muted` là phần đệm (`High`), `feedback` mang màu lỗi.

## 3. `MxCard.option` — `onTap` bắt buộc, vẫn nullable (M100.35)

Trước M100.35 `onTap` là tuỳ chọn. Với mọi recipe khác điều đó đúng: bỏ trống
nghĩa là "đây chỉ là bề mặt". Với `option` thì không — recipe này *là* một điều
khiển có trạng thái chọn, nên không có handler không thể mang nghĩa "không phải
điều khiển".

Kết quả là một trạng thái không ai chọn: **trông như bấm được + có ngữ nghĩa
đã-chọn + bấm không ăn**. Nó xảy ra thật, ở `CardExportPhase.invalidScope`,
nơi sheet xuất giữ các định dạng đọc được như *bản ghi điều đã yêu cầu* nhưng
không cho đổi nữa.

Nay `onTap` **bắt buộc và vẫn nullable**: người gọi phải nói ra, và `null` nghĩa
là **disabled**, được vẽ và được đọc lên đúng như thế.

| | Trước | Sau |
|---|---|---|
| Fill khi `onTap == null` | `surfaceContainerLow` (như bình thường) | `semantic.disabledSurface` |
| Viền | `borderOption` đủ mạnh | `semantic.onDisabled` |
| Semantics | `selected` — không có `button` | `button: true, enabled: false, selected: …` |

Cặp token là cặp các nút đã dùng, nên option bị vô hiệu đọc ra là *disabled của
app* chứ không phải một biến thể card. Không thêm API `isEnabled`: nguồn duy
nhất của trạng thái này đã sẵn tính ra một callback nullable.

## 4. `tonal` — tên đúng, câu mô tả sai

Tài liệu và doc comment nói recipe này vẽ trên `secondaryContainer`. Nó **không**
— và đã không kể từ M99.98, milestone đổi fill sang `semantic.surfaceEmphasis`
vì container của M3 đo được chroma 0.0084 ở light (gần như trung tính) và nằm
5.24 L\* dưới trang: callout chính của màn hình lại là thứ xám nhất trên đó.
`surfaceEmphasis` nằm 1.11 dưới trang với 3.6× chroma.

**Sai ở câu chữ, không ở tên.** "Tonal" trong M3 nghĩa là *một bề mặt mang sắc*,
và `surfaceEmphasis` đúng là như vậy; cái tên vẫn mô tả đúng thứ recipe vẽ. Nên
M100.35 sửa câu mô tả và **không** đổi tên: một lần đổi tên công khai để khớp
một token mà tên hiện tại vốn đã mô tả đúng là chi phí không mua được gì.

Nếu sau này `surfaceEmphasis` bị gỡ và recipe quay lại một container của M3 thì
tên vẫn đúng. Đó là dấu hiệu tên nằm đúng tầng trừu tượng.

## 5. Điều không đổi

Những thứ M100.33 đã sửa và M100.35 **không** đụng tới, ghi lại để lần sau
không ai vô tình lùi:

- một `ColorScheme` role cho cả light lẫn dark, mỗi recipe;
- viền state và focus ring là hai lớp **foreground** vẽ chồng lên con, cộng
  thêm chứ không thay nhau;
- không có `Border.all(color: fill)` giả;
- focus không làm layout xê dịch;
- sàn 48dp cho vùng chạm;
- thang radius `md` 12 / `lg` 16 / `xl` 20 và thang padding 0 / 12 / 16.
