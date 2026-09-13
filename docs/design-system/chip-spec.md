# Chip — đối chiếu component spec với `MxPillButton` / `ChoiceChip` đã triển khai

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract của Chip trong MemoX HTML design kit (mục D · Inputs & forms) với implementation đã triển khai (`MxPillButton`, `buildChipTheme`), ghi lại điểm khớp, điểm lệch, và quyết định của chủ dự án cho điểm lệch mà kit mâu thuẫn M3 canonical |
| **Scope** | Dimension, icon, ma trận trạng thái của kit gốc đối chiếu với `lib/shared/widgets/mx_pill_button.dart` và `lib/core/theme/components/selection/app_chip_theme.dart`. Ngoài phạm vi: `SegmentedButton`/`NavigationBar` (đọc cùng cặp role cũ, không đổi trong task này), giá trị token nền (AD-14), vai trò M3 nào ánh xạ role nào ngoài Chip (đã có ở `tokyo-component-mapping.md`) |
| **Source of truth for** | Kết quả đối chiếu spec Chip (kit) ↔ implementation; quyết định kit-vs-canonical cho selected fill/label |
| **Depends on** | `document-conventions.md` · `design-system/v1-freeze.md` §3c (quyền hạn task này chạy dưới) · `design-system/tokyo-component-mapping.md` |
| **Updated by task** | M100.86 |
| **Last updated** | 2026-09-13 |

---

## 0. Tài liệu này là gì, và không phải là gì

Bản dịch component contract (nguồn: MemoX HTML design kit, mục *D · Inputs &
forms*) của Chip sang trạng thái đã triển khai. **Khác với `text-button-spec.md`:
Chip có một khoảng lệch thật, và task này đã đóng nó** — đây không phải một
tài liệu đối chiếu thuần tuý kết luận "không cần sửa". `MxPillButton` /
`buildChipTheme` đã có từ M100.36; phần lệch mà đối chiếu tìm ra (selected fill/
label) được sửa ngay trong task này, dưới quyền hạn chung của `v1-freeze.md`
§3c (M100.85 — V1 mở lại cho redesign theo handoff Tokyo, điều kiện 2).

HTML design kit đã bị xoá ở M100.83. Giá trị "kit nói gì" dưới đây đọc từ bản
đặc tả Chip mà chủ dự án đưa trực tiếp cho task này (dimension table + state
matrix, dẫn từ handoff); giá trị "implementation nói gì" đọc thẳng từ
`lib/core/theme/components/selection/app_chip_theme.dart` và
`lib/shared/widgets/mx_pill_button.dart`.

## 1. Hợp đồng component, từ prompt gốc (binding)

**Mục đích.** Selectable tag/filter, full radius.

**Dimension:**

| Dimension | Class | Giá trị |
|---|---|---|
| `selected` | CONTENT-DRIVEN | — (không cố định bề rộng theo trạng thái chọn) |
| `unselected` | CONTENT-DRIVEN | — |
| `size` | FIXED | 32 (chiều cao) / 24 (bước icon) |

**Icon.** `check` (tên Lucide trong kit — glyph khi selected; map theo ý nghĩa
sang Material Symbol tương đương, không phải tên `Icons.*` cố định).

**Ma trận trạng thái, từ prompt gốc:**

| Trạng thái | Vẽ |
|---|---|
| `unselected` | fill `surface-container`, viền `outlineVariant`, nhãn `onSurfaceVariant` |
| `selected` | fill `primaryContainer`, nhãn `onPrimaryContainer`, không viền |
| `pressed` | overlay 8% [INFERRED] |

## 2. Đối chiếu

### 2.1 `selected` / `unselected` — bề rộng content-driven

Khớp, và đã khớp từ M100.36 (4M): leading slot luôn được layout (tick khi
chọn, `icon` của caller khi không), nên bề rộng pill **không đổi** khi chuyển
trạng thái — chính là điều dimension class `CONTENT-DRIVEN` này đòi.
`mx_pill_button_test.dart`'s "toggling ... does not change its width" ghim
bằng đo thật, cả hai chiều (có icon, không icon).

### 2.2 `size` — 32 chiều cao, 24 bước icon

| Nửa của giá trị | Kit | Thật trước task này | Thật sau task này |
|---|---|---|---|
| chiều cao pill | 32 | 32 (`AppSizing.controlDense`) | **không đổi** — đã khớp |
| bước icon | 24 | 16 (`AppIconSize.sm`) | **24** (`AppIconSize.md`) |

Chiều cao đã đúng từ trước; đổi duy nhất là bước icon. Không token mới — cả
`.sm` và `.md` đã tồn tại trong `AppIconSize`.

**Phạm vi rộng hơn `MxPillButton`.** `ChipThemeData.iconTheme` là fall-through
chung cho cả họ Chip Flutter (`Chip`, `ChoiceChip`, `ActionChip`, `FilterChip`,
`InputChip`), không riêng `MxPillButton` composes trong leading slot của nó.
Đổi bước icon kéo theo hai call site khác trong app, cả hai đọc
`iconTheme` qua fall-through chứ không tự set size:
[`card_tag_section_widget.dart:290`](../../lib/features/card/presentation/widgets/sections/card_tag_section_widget.dart:290)
(`Chip(onDeleted:)` — tag đọc được, xoá được) và
[`:299`](../../lib/features/card/presentation/widgets/sections/card_tag_section_widget.dart:299)
(`ActionChip` — "+ Add tag"). Kiểm bằng golden `card_editor_edit`, không vỡ
layout ở kích thước mới.

### 2.3 Icon — `check`

Kit: glyph `check` khi selected. Thật: `MxPillButton._Content` đã vẽ
`Icons.check` trong leading slot khi `isSelected`, từ M100.36 — không phải
việc của task này, chỉ xác nhận khớp ý nghĩa (một dấu tick, meaning ổn định
qua mọi màn dùng pill).

### 2.4 Ma trận trạng thái

| Trạng thái | Kit | Thật trước task này | Thật sau task này | Khớp? |
|---|---|---|---|---|
| `unselected` fill | `surface-container` | `surfaceContainerLow` | không đổi | Khớp — "surface-container" đọc như mô tả họ bề mặt chung, không phải role Flutter cụ thể; `surfaceContainerLow` là câu trả lời đã có sẵn và đúng (paper trên page) |
| `unselected` viền | `outlineVariant` | `outlineVariant` | không đổi | Khớp, `=` |
| `unselected` nhãn | `onSurfaceVariant` | `onSurfaceVariant` | không đổi | Khớp, `=` |
| `selected` fill | `primaryContainer` | `secondaryContainer` | **`primaryContainer`** | **Lệch đã đóng — xem §2.5** |
| `selected` nhãn | `onPrimaryContainer` | `onSecondaryContainer` | **`onPrimaryContainer`** | **Lệch đã đóng — xem §2.5** |
| `selected` viền | không viền | trong suốt khi selected | không đổi | Khớp — side đã transparent khi selected từ M100.36 |
| `pressed` | overlay 8% [INFERRED] | ripple SDK, không fill riêng | **không đổi — xem §2.6** | Không triển khai theo nghĩa đen; lý do là một ruling, không phải bỏ sót |

### 2.5 `selected` fill/label — kit mâu thuẫn M3 canonical, hỏi chủ dự án

`secondaryContainer`/`onSecondaryContainer` không phải một lựa chọn tuỳ ý của
MemoX — đó là default canonical của chính `_ChoiceChipDefaultsM3` trong
Flutter, và `m3_role_bindings.dart` từng ghim nó với `refuses: primaryContainer`
tường minh. Cùng cặp role còn giữ "đang active" của Chip đồng nhất với
`NavigationBar`'s indicator và `SegmentedButton`'s selected segment.

`v1-freeze.md` §3c nói rõ: chỗ kit mâu thuẫn role canonical của M3 SHOULD được
hỏi chủ dự án theo từng ca, không tự chọn một phía. Ba hướng được đặt ra:

1. Giữ `secondaryContainer` — coi chữ "primaryContainer" trong spec là mô tả
   hình ảnh (nền tông brand), không phải tên role Flutter bắt buộc.
2. Đổi `primaryContainer`, chỉ cho Chip.
3. Đổi `primaryContainer` cho cả ba component (Chip + SegmentedButton +
   NavigationBar indicator), giữ "đang active" đồng nhất toàn app.

**Chủ dự án chọn (2) — chỉ Chip.** Hệ quả được chấp nhận tường minh: từ
task này, Chip đọc `primaryContainer` trong khi tab đang chọn và segment đang
chọn vẫn đọc `secondaryContainer` — ba component "đang active" không còn cùng
ngôn ngữ màu. `SegmentedButton` và `NavigationBar` không đổi; nếu cần đồng bộ
lại, đó là quyết định riêng cho lần sau, không phải phần mở rộng ngầm của
task này.

`m3_role_bindings.dart` đảo `requires`/`refuses` cho hai binding `ChoiceChip`
(`_restingFill`, `_labelColorFor`); `m3_role_contract_test.dart` và
`m3_combined_state_test.dart` ghim giá trị mới; `tokyo-component-mapping.md`
selection/ cập nhật hai dòng.

### 2.6 `pressed` — 8% overlay [INFERRED], không triển khai

Spec gốc tự đánh dấu dòng này `[INFERRED]` — "not drawn in the mock" — và yêu
cầu xác nhận thay vì chép thẳng. Kiến trúc hiện tại của `_fillFor` đã theo
đúng nguyên tắc "một cơ chế mỗi state": hover = fill tint (vì `RawChip` tắt
`hoverColor` khi theme có `color`), press = ripple SDK, focus = `MxFocusRing`.
Thêm một fill tint 8% riêng cho pressed sẽ tái tạo đúng bug class đã sửa ở
M100.36 (#434 P2-6) — press từng chạy ở ~24% hiệu quả vì cả fill tint lẫn
ripple SDK cùng cộng dồn trên cùng một fill. Cơ chế fill hiện tại không phụ
thuộc màu resting/selected là gì, nên đổi màu selected không đòi thay đổi gì
ở đây. Ruling: giữ nguyên, không thêm cơ chế mới.

## 3. Token mapping — đọc từ `lib/core/theme/`

**Hình học.** Chiều cao content box 32 (`AppSizing.controlDense`), painted 34
(hai hairline ngoài content box), target chạm 48
(`AppSizing.touchTarget`, `MxPillButton` tự nới ngoài ring). Padding ngang 12
(`AppSpacing.md`), `labelPadding` zero. Bán kính `AppRadius.pill`. Icon bước
24 (`AppIconSize.md`, M100.86 — trước đó `.sm` = 16).

**Chữ.** `labelLarge` re-metric xuống rung `label-md` (kích thước, leading,
tracking; màu vẫn theo `WidgetStateColor` của theme) — vì pill sống cạnh nút
Study `label-md` trên cùng hàng deck.

**Viền.** `AppStroke.hairline` khi unselected/disabled, trong suốt khi
selected.

**Elevation.** 0 khi rest, 0 khi pressed — cả hai slot đều bị ghim (AD-14 một
cơ chế độ sâu).

## 4. Vượt ra ngoài hợp đồng gốc

Không có API mới thêm trong task này. `MxPillButton`'s API
(`label`/`isSelected`/`onPressed`/`icon`/`semanticLabel`) không đổi — đây là
retune bên trong theme, không phải một tham số mới.

## 5. SYSTEM-OWNED / không copy nguyên văn — không áp dụng

Từ prompt gốc: status bar, cutout, gesture/nav inset, keyboard inset, nút Back
hệ thống, khung thiết bị, absolute positioning, `::after` hit expander,
`backdrop-filter`, `color-mix`, hover kiểu web, fake system chrome, hộp pixel
cố định quanh chữ — không mục nào liên quan Chip; ghi lại để người đọc sau
không tự hỏi lại.

## 6. Hợp đồng đóng băng liên quan, và quyền hạn đã dùng

Chip nằm dưới nhiều dòng của `v1-freeze.md` §2: vai trò (#1, #2 — selected
fill/label đã đổi trong task này), mapping ThemeData (#3), public contract của
shared primitive (#6 — không đổi), foundation sizing (#5 — bước icon đổi,
không token mới), floor 48dp (#7 — không đổi), ripple/state (#8 — không đổi).

**Task này sửa dòng #1/#2 hợp pháp dưới `v1-freeze.md` §3c** (M100.85 — V1 mở
lại cho redesign theo handoff Tokyo, điều kiện 2): một task thực hiện handoff
MAY sửa hợp đồng dòng 1-13 mà không cần dừng lại xin một reopen riêng cho từng
component. Điều §3c vẫn đòi: PR đổi hợp đồng MUST dời test/guard đang canh
sang giá trị mới ngay trong PR đó (đã làm — §2.5), và dòng 14 (golden chỉ
author trên Linux) không mở — goldens của task này được author trên WSL Linux,
không trên Windows.

## 7. Kết luận

Chip đã khớp phần lớn hợp đồng kit từ M100.36 (bề rộng content-driven, glyph
`check`, unselected fill/viền/nhãn). Hai điểm lệch tìm được: bước icon (16→24,
áp dụng thẳng, không cần quyết định chủ dự án) và selected fill/label
(`secondaryContainer`→`primaryContainer`, kit mâu thuẫn M3 canonical, hỏi
chủ dự án và triển khai theo câu trả lời). `pressed` overlay giữ nguyên bằng
một ruling có lý do ghi lại, không phải một khoảng trống bỏ sót.
