# I. Global ThemeData Foundation

## 1. `ColorScheme`

### Theme checklist

- [ ] Khai báo explicit toàn bộ role mà Flutter có thể đọc.
- [ ] `primary/onPrimary` chỉ dành cho strong brand/action pair.
- [ ] `primaryContainer/onPrimaryContainer` dành cho brand-tinted
      container/selection.
- [ ] `secondary` không cạnh tranh với primary.
- [ ] `secondaryContainer` có semantic purpose rõ.
- [ ] `tertiary` chỉ tồn tại nếu có distinct semantic purpose.
- [ ] `error` dùng cùng danger family của app, không tạo hệ đỏ thứ hai.
- [ ] `surface` là canonical component surface.
- [ ] `surfaceContainerLowest → Highest` tạo ladder hợp lý.
- [ ] `outline` dành cho control boundary.
- [ ] `outlineVariant` dành cho decorative/subtle boundary.
- [ ] `surfaceTint` không vô tình đổi các surface đã hand-tune.
- [ ] `inverseSurface/onInverseSurface` được kiểm tra cho SnackBar/Tooltip.
- [ ] `shadow` và `scrim` cùng palette family.
- [ ] `*Fixed` roles tuân thủ invariant light/dark nếu app support.
- [ ] Kiểm tra contrast của mọi `onX` trên `X`.
- [ ] Kiểm tra selected ink trên selected container riêng cho light/dark.

### Shared API rule

Feature không được đọc trực tiếp arbitrary ColorScheme role để styling một
component.

Cho phép:

```dart
context.colors
context.semanticColors
```

chỉ trong shared/design-system layer.

Feature nên yêu cầu:

```dart
MxStatus.success
MxActionVariant.primary
MxSurfaceVariant.raised
```

## 2. `TextTheme`

### Theme checklist

- [ ] Có full type scale.
- [ ] Mỗi rung có size.
- [ ] Mỗi rung có line-height.
- [ ] Mỗi rung có weight.
- [ ] Mỗi rung có letter spacing nếu cần.
- [ ] Heading/body/label hierarchy không dựa chỉ vào màu.
- [ ] Không quá nhiều font weights trên một screen.
- [ ] Button typography được định nghĩa.
- [ ] Chip typography được định nghĩa riêng nếu khác button.
- [ ] Metadata/helper typography được định nghĩa.
- [ ] Text scale 2.0 không phá line box.

### Shared widgets

Nên có semantic accessors:

- `MxText.pageTitle`
- `MxText.sectionTitle`
- `MxText.body`
- `MxText.metadata`
- `MxText.label`
- `MxText.caption`

Hoặc `AppTextStyles`, nhưng feature không `.copyWith(fontSize: ...)`.

**Bẫy variable font (đã trả giá ba lần trong repo này):** cả hai face đều là
variable font có trục `wght`; một `copyWith(fontWeight:)` trần báo weight mới
cho test và vẽ weight cũ trên máy. Mọi re-weight đi qua
`AppTypography.withWeight`, và test pin `fontVariations`, không chỉ
`fontWeight`.

## 3. `IconTheme`

### Theme checklist

- [ ] Default icon color = secondary/quiet ink.
- [ ] Default icon size cố định.
- [ ] Selected icon không dùng default.
- [ ] Disabled icon có contract.
- [ ] Semantic icon color không lấy trực tiếp raw colors.

### Shared widget: `MxIcon`

Xây nếu muốn guard `Icon`.

- [ ] Nhận `IconData`.
- [ ] Có semantic sizes: `sm/md/lg`.
- [ ] Có tones: `default/accent/success/warning/danger`.
- [ ] Không nhận arbitrary `size`.
- [ ] Không nhận arbitrary `color`.
- [ ] Decorative icon được exclude semantics đúng cách.

## 4. Global interaction fallback

Bao gồm: `hoverColor`, `focusColor`, `highlightColor`, `splashColor`,
`splashFactory`, `disabledColor`, `canvasColor`.

### Checklist

- [ ] Bare `InkWell` không rơi về foreign black/white washes.
- [ ] Hover scale phù hợp diện tích component.
- [ ] Focus không chỉ dựa vào wash nếu contrast không đủ.
- [ ] Press mạnh hơn hover.
- [ ] Disabled fallback thuộc palette của app.
- [ ] Canvas của legacy popup/dropdown không ra màu lạ.
- [ ] Ripple không phá visual language.

## 5. `visualDensity`

- [ ] Pin density theo target product.
- [ ] Web E2E không render khác Android production.
- [ ] Không dùng compact để chữa layout quá lớn.

## 6. `materialTapTargetSize`

- [ ] Interactive target không nhỏ hơn 48×48.
- [ ] Visual box có thể nhỏ hơn target.
- [ ] Golden test phân biệt painted size và hit size — đo `Material` bên trong
      cho painted, đo hộp widget ngoài cho hit; đo nhầm hộp ngoài là assert
      chống lại chính cơ chế `padded` đang test.

## 7. `ScrollbarThemeData`

### Theme checklist

- [ ] Thumb color.
- [ ] Hover/dragged state nếu relevant.
- [ ] Thickness.
- [ ] Radius.
- [ ] Track chỉ bật nếu product cần.
- [ ] Dark/light đều đủ nhìn nhưng không tranh content.

### Shared widget

Không nhất thiết cần `MxScrollbar`. Cho phép raw `Scrollbar` nếu ThemeData
hoàn toàn đủ.
