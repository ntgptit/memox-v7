# V. Surfaces & Content Containers

## 29. `CardThemeData`

### Theme checklist

- [ ] Surface role.
- [ ] Border.
- [ ] Radius.
- [ ] Elevation.
- [ ] Shadow.
- [ ] Surface tint.
- [ ] Margin = zero nếu spacing phải do layout quyết.
- [ ] Clip behavior.
- [ ] Light/dark depth mechanism rõ.

### Shared widget: `MxCard`

Recipe theo meaning (AD-23, M99.83): `flat` · `raised` · `focal` · `recessed`
· `feedback` · `muted` · `tonal` · `accent` · `tile` · `option` — mỗi recipe
là một named constructor map 1-1 vào private spec. Không đặt tên theo
feature (`study`, `deck`).

- [x] Internal padding là enum đóng `MxCardPadding { none, compact, standard }`;
      `none` = child tự sở hữu content area.
- [x] Interactive card có hover/press/focus riêng; focus ring chỉ vẽ ở
      `FocusHighlightMode.traditional` (cùng gate với autofocus của button).
- [x] Non-interactive card không giả button state; `onLongPress` không cần
      `onTap` vẫn phải reach được.
- [x] Không expose `color/radius/shadow/elevation/EdgeInsets` — enforced bằng
      `test/app/shared_api_closure_test.dart` (allowlist AST) và
      `test/app/card_activation_wrapper_test.dart`.
- [x] Selection: tri-state `isSelected` thuộc card (M99.70); selected fill là
      `MxCardSelectionTreatment { edge, tint }`, không phải `Color`.
- [x] Interactive card giữ sàn 48×48 structural, không nhờ padding.

## 30. `ListTileThemeData`

### Theme checklist

- [ ] Horizontal padding.
- [ ] Vertical padding/min height.
- [ ] Shape.
- [ ] Title ink.
- [ ] Subtitle ink.
- [ ] Leading/trailing icon ink.
- [ ] Selected background.
- [ ] Selected ink.
- [ ] Disabled ink.
- [ ] Typography.
- [ ] Density.
- [ ] Selected contrast được đo.

### Shared widget: `MxListTile`

- [ ] Own hover/focus/press vì ThemeData không đủ toàn bộ.
- [ ] Focus ring.
- [ ] Title/subtitle max lines.
- [ ] Trailing constraints.
- [ ] Leading geometry.
- [ ] Whole-row semantics.
- [ ] Interactive vs informational row explicit.
- [ ] Selected state không do feature tự màu.
- [ ] Không truyền `contentPadding`, `tileColor`, `selectedColor`.

## 31. `ExpansionTileThemeData`

### Theme checklist

- [ ] Collapsed/expanded icon.
- [ ] Collapsed/expanded text.
- [ ] Background.
- [ ] Shape collapsed/expanded.
- [ ] Padding.
- [ ] Children padding.
- [ ] Divider policy.

### Shared widget: `MxExpansionTile`

- [ ] Header uses Mx row geometry.
- [ ] Animation duration/curve locked.
- [ ] Trailing indicator locked.
- [ ] Content spacing locked.
- [ ] No arbitrary colors.

## 32. `DividerThemeData`

### Theme checklist

- [ ] Color.
- [ ] Thickness.
- [ ] Space.
- [ ] Indent policy.
- [ ] Same line language as card/list separators.

### Shared widget

Optional `MxDivider`. Nếu raw `Divider` đã hoàn toàn deterministic từ theme thì
có thể allow raw `Divider`. Không cần wrapper chỉ để đổi tên.

## 33. `BadgeThemeData`

### Theme checklist

- [ ] Background.
- [ ] Foreground.
- [ ] Typography.
- [ ] Small/large size.
- [ ] Padding.
- [ ] Alignment.
- [ ] Radius/shape.
- [ ] Semantic colors không lạm dụng danger cho neutral count.

### Shared widget: `MxBadge`

Variants: neutral count, info, due/warning, danger nếu thực sự mang danger
meaning.

- [ ] Max display policy như `99+`.
- [ ] Semantics phát âm đúng.
- [ ] Không expose color.

Lưu ý repo: `badgeTheme` từng bị **từ chối** khỏi `app_planned_themes.dart` vì
due-vs-overdue là một quyết định cần màn hình (BR-161) — mục này chỉ mở khi
quyết định đó có screen để check.

## 34. `CarouselViewThemeData`

Chỉ build nếu app thực sự dùng carousel.

### Theme checklist

- [ ] Shape.
- [ ] Background/surface.
- [ ] Padding.
- [ ] Elevation nếu relevant.
- [ ] Item treatment.

### Shared widget: `MxCarousel`

- [ ] Item extent behavior.
- [ ] Focus/accessibility.
- [ ] Page indicator nếu product cần.
- [ ] Semantic navigation.
