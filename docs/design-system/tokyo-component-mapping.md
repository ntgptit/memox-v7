# Component themes — M3 contract, Tokyo intent, MemoX geometry

| | |
|---|---|
| **Status** | active |
| **Purpose** | Bảng đối chiếu từng Material component: role canonical của M3, cái memox override, ý đồ Tokyo, và token hình học — để không ai phải nhớ hoặc đoán |
| **Scope** | `lib/core/theme/components/**`. Ngoài phạm vi: giá trị token (AD-14), layering của `lib/core/theme/` (`theme-architecture.md`), API của `Mx*` widget |
| **Source of truth for** | Ma trận component → canonical M3 role · ma trận dịch ý đồ Tokyo → MemoX · danh sách sai lệch role đã biết và lý do |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/theme-architecture.md` |
| **Updated by task** | M100.31 |
| **Last updated** | 2026-09-03 |

---

## 1. Nguồn của cột "M3 canonical"

Mọi role trong tài liệu này **đọc từ SDK ghim** (`.fvmrc` → Flutter 3.44.8),
không phải từ trí nhớ hay từ spec trên web:

```
D:/Setup/flutter/packages/flutter/lib/src/material/**  →  class _XxxDefaultsM3
```

Trích bằng script, không chép tay. Khi nâng SDK, chạy lại phần trích và đối
chiếu — một role đổi trong SDK mà bảng này không đổi là một sai lệch âm thầm.

Thứ tự ưu tiên khi xung đột, theo brief và AD-14:

```
canonical M3 role  >  accessibility  >  MemoX structural system  >  Tokyo exact hex
```

---

## 2. Ma trận role — component × slot

`=` nghĩa là memox bind đúng role canonical. Cột cuối chỉ có nội dung khi khác.

### actions/

| Component | Slot | M3 canonical (SDK 3.44.8) | MemoX | Ghi chú |
|---|---|---|---|---|
| FilledButton | background | `primary` (disabled: `onSurface`) | = | disabled dùng `semantic.disabledSurface` — solid, R7 |
| FilledButton | foreground | `onPrimary` (disabled: `onSurface`) | = | disabled dùng `semantic.onDisabled` |
| FilledButton | overlay | `onPrimary` | blend về `onSurface` | 6% accent trên accent là vô hình — xem file |
| FilledTonalButton | background | `secondaryContainer` | = | qua `MxFilledPair.tonal` |
| FilledTonalButton | foreground | `onSecondaryContainer` | = | |
| OutlinedButton | foreground | `primary` | = | guard AST |
| OutlinedButton | side | `outline`, focus → `primary` | = | guard AST |
| TextButton | foreground | `primary` | = | guard AST |
| IconButton | foreground | `onSurfaceVariant` | = | |
| **FAB** | **background** | **`primaryContainer`** | **`primary`** | **SAI LỆCH — xem §4** |
| **FAB** | **foreground** | **`onPrimaryContainer`** | **`onPrimary`** | **SAI LỆCH — xem §4** |

### inputs/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| InputDecorator | outlineBorder | `outline`; focus `primary`; error `error` | = | |
| InputDecorator | fillColor | `surfaceContainerHighest` | `filled: false` | Cố ý: field là *khoảng mở*, không phải khối |
| InputDecorator | hintStyle | `onSurfaceVariant` | = | |

### selection/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| ChoiceChip | selected fill | `secondaryContainer` | = | guard AST |
| **ChoiceChip** | **unselected fill** | **`surfaceContainerLow`** | **`surface`** | **SAI LỆCH — xem §4** |
| ChoiceChip | side | `outlineVariant`, selected trong suốt | = | guard AST |
| Checkbox | fill | `primary` / trong suốt theo `selected` | = | guard AST |
| Switch | thumb | `outline` off / `onPrimary` on | = | guard AST |
| Switch | track | `surfaceContainerHighest` off / `primary` on | = | guard AST |
| Switch | trackOutline | `outline` off / trong suốt on | = | guard AST |
| Radio | fill | `onSurfaceVariant` / `primary` | = | |
| Slider | activeTrack | `primary` | = | |
| Slider | inactiveTrack | `secondaryContainer` | = | |
| SegmentedButton | selected bg | `secondaryContainer` | = | guard AST |
| SegmentedButton | side | `outline` | = | guard AST |

### navigation/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| NavigationBar | background | `surfaceContainer` | = | guard AST |
| NavigationBar | indicator | `secondaryContainer` | = | guard AST |
| NavigationBar | iconTheme | `onSecondaryContainer` / `onSurfaceVariant` | = | guard AST |
| NavigationBar | labelTextStyle | `onSurface` / `onSurfaceVariant` | = | guard AST |
| TabBar | labelColor | `primary` | = | guard AST |
| TabBar | indicatorColor | `primary` | = | guard AST |
| **AppBar** | **background** | **`surface`** | **nền trang** | **SAI LỆCH — xem §4** |
| AppBar | foreground | `onSurface` | = | |

### surfaces/ · content/ · feedback/ · overlays/ · pickers/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| **Card** | **color** | **`surfaceContainerLow`** | **`surface`** | **SAI LỆCH — xem §4** |
| Dialog | background | `surfaceContainerHigh` | = | |
| BottomSheet | background | `surfaceContainerLow` | = | |
| BottomSheet | dragHandle | `onSurfaceVariant` | = | + state layer, không đổi role |
| ListTile | selectedColor | `primary` | = | |
| ListTile | icon / title / subtitle | `onSurfaceVariant` / `onSurface` / `onSurfaceVariant` | = | |
| Divider | — | `outlineVariant` (M3 dùng ThemeData) | = | |
| ProgressIndicator | color | `primary` | = | |
| ProgressIndicator | linearTrack | `secondaryContainer` | = | |
| SnackBar | background | `inverseSurface` | = | |
| SnackBar | action | `inversePrimary` | = | |
| SnackBar | content | `onInverseSurface` | = | |
| Tooltip | — | `inverseSurface` / `onInverseSurface` | = | |
| PopupMenu | color | `surfaceContainer` | = | |
| DatePicker | day selected | `primary` / `onPrimary` | = | |
| DatePicker | range selection | `secondaryContainer` | = | |
| TimePicker | dial background | `surfaceContainerHighest` | = | |
| TimePicker | dial hand | `primary` | = | |

---

## 3. Dịch ý đồ Tokyo — không dịch giá trị

| Tokyo | Ý đồ | MemoX target | Bất biến M3 | Dịch hình học |
|---|---|---|---|---|
| `MuiButton.root` bold | action đọc ra là action | `buttonLabelWeight` w700 | pair `primary`/`onPrimary` không đổi | weight, không phải size |
| `sizeMedium` `8px 20px` | nút chắc, không rỗng | `AppSpacing.xl` / `md` | — | 20 không có trên thang; giữ 24 |
| `MuiButtonBase` radius 6 | góc control chặt | `AppRadius.md` (12) | — | tier, không phải px |
| `general.borderRadius` 10 | góc mặt phẳng | `AppRadius.lg` (16) | — | tier |
| `shadows.cardSm` / `card` | card ngồi / panel nổi | `shadowsFor(card)` / `(raised)` | — | hai lớp, màu qua `scheme.shadow` |
| `shadows.card` (dark) | rim thay shade | rim `#6A7199` | — | edge không sâu thêm theo level |
| `MuiPaper` paper | mặt giấy nổi | `ColorScheme.surface` | surface semantics | — |
| `divider` `#272C48` | vạch rất khẽ | `scheme.outlineVariant` | `outlineVariant` | `AppStroke.hairline` |
| Backdrop tối + blur | tách modal khỏi trang | `modalBarrierColor` (`scheme.scrim`) | scrim | alpha token; **blur chưa nhận** |
| `MuiIconButton` radius 8 / pad 8 | chrome gọn | `AppRadius.md` + `AppSizing.touchTarget` | `onSurfaceVariant` | sàn 48 thắng pad 8 |
| `MuiTab` height 38 | nhịp điều hướng chặt | chưa áp dụng | `primary` | 38 dưới sàn; hoãn |

**Blur của Backdrop chưa được nhận** (brief §32): nó cần một overlay recipe dùng
chung, một phép đo hiệu năng, và một quyết định — không phải từng modal tự gọi
`BackdropFilter`. Ghi ở đây để lần sau không tự ý thêm.

---

## 4. Bốn sai lệch role đã biết

MUST: không sửa bốn mục này như một "dọn dẹp". Mỗi mục là một quyết định đã ghi,
và ba trong bốn đụng vào toàn bộ hệ bề mặt của app.

| # | Component | M3 | MemoX | Lý do đã ghi | Trạng thái |
|---|---|---|---|---|---|
| 1 | FAB background/foreground | `primaryContainer`/`onPrimaryContainer` | `primary`/`onPrimary` | Mockup chủ dự án 2026-08-20: action tạo duy nhất của màn mặc màu thương hiệu, không mặc cùng bộ đồ với tab đang chọn của NavigationBar | **Cần chủ dự án quyết** — đây là *đổi canonical role*, thứ §4 của brief cấm. Hoặc đảo về `primaryContainer`, hoặc ghi thành ngoại lệ có tên trong AD-14 |
| 2 | Card `color` | `surfaceContainerLow` | `surface` | Thang bề mặt của app định nghĩa `surface` **là** mặt card, `background` là trang | Giữ. Đổi sẽ dịch mọi card trong app |
| 3 | ChoiceChip unselected fill | `surfaceContainerLow` | `surface` | Cùng lý do #2: pill chưa chọn là "một card nhỏ nằm trên trang" | Giữ |
| 4 | AppBar background | `surface` | nền trang | Header phải đứng yên trong phiên học: một dịch chuyển màu sau tấm thẻ đọc ra như chính tấm thẻ đổi | Giữ |

#2–#4 là **cùng một quyết định** nhìn từ ba chỗ: memox đọc `surface` là mặt
giấy và có một token trang riêng, còn M3 đọc `surface` là nền và leo thang
`surfaceContainer*` cho mọi thứ đặt lên. Đó là một sai lệch có hệ thống, đã đo,
và đảo nó là một task palette riêng chứ không phải một lượt dọn.

**#1 thì khác** và không nên gộp vào: nó không dính đến thang bề mặt, nó là một
cặp accent bị thay bằng một cặp accent khác — đúng dạng thay role mà #426/#427
đã dọn ở năm component khác.

---

## 5. Ranh giới hình học

Component theme sở hữu hình học **toàn cục**; shared widget chỉ thêm composition:

| Theme | Sở hữu |
|---|---|
| `buildSharedButtonStyle` | chiều cao tối thiểu (`AppSizing.touchTarget`), bề rộng tối thiểu, padding, shape, weight nhãn |
| `buildInputDecorationTheme` | content padding, radius, stroke, hint style |
| `buildChipTheme` | chiều cao pill, padding, radius, weight nhãn |
| `buildListTileTheme` | content padding, minVerticalPadding, shape |
| `buildDialogTheme` | shape |
| `buildCardTheme` | shape, hairline |

MUST NOT: một `Mx*` widget hoặc một feature nêu lại các giá trị này.
