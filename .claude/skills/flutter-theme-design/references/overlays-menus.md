# VI. Dialogs, Sheets, Menus & Overlays

**Nguyên tắc chương này:** Material không được âm thầm quyết định độ sâu. Mọi
overlay khai elevation explicit — SnackBar từng là cái cuối cùng để SDK tự
quyết (6.0, kể cả ở dark nơi app đã tắt bóng), và đó là một bug thật (M99.61).

## 35. `DialogThemeData`

Raw: `Dialog`, `AlertDialog`.

### Theme checklist

- [ ] Background.
- [ ] Barrier.
- [ ] Surface tint.
- [ ] Elevation.
- [ ] Shadow.
- [ ] Radius.
- [ ] Border.
- [ ] Inset padding.
- [ ] Max width/constraints.
- [ ] Title typography.
- [ ] Content typography.
- [ ] Icon color.
- [ ] Actions spacing.
- [ ] Clip behavior.

### Shared widgets

`MxAlertDialog`, `MxConfirmDialog`, `MxAsyncConfirmDialog`.

- [ ] Width metrics centralized.
- [ ] Header/body/footer spacing centralized.
- [ ] Button arrangement centralized.
- [ ] Destructive confirmation semantic variant.
- [ ] Async submit preserves dimensions.
- [ ] Long text and textScaler 2.0 tested.
- [ ] Feature supplies content/intent, không supplies visual metrics.

## 36. `BottomSheetThemeData`

### Theme checklist

- [ ] Background.
- [ ] Modal barrier.
- [ ] Elevation.
- [ ] Surface tint.
- [ ] Shape.
- [ ] Drag handle.
- [ ] Drag handle size/color.
- [ ] Clip.
- [ ] Constraints nếu tablet/web.

### Shared widget: `MxActionSheet` / `MxBottomSheet`

- [ ] Standard content padding.
- [ ] Safe-area policy.
- [ ] Keyboard inset behavior.
- [ ] Draggable behavior explicit.
- [ ] Max height policy.
- [ ] Action rows use shared components.
- [ ] No raw visual overrides at call site.

## 37. `PopupMenuThemeData`

### Theme checklist

- [ ] Background surface.
- [ ] Surface tint.
- [ ] Border.
- [ ] Radius.
- [ ] Elevation/shadow.
- [ ] Label typography.
- [ ] Disabled item.
- [ ] Padding.
- [ ] Popup layer visibly tách khỏi ground không có scrim.
- [ ] Selected/check state nếu applicable.

### Shared widget: `MxPopupMenu`

- [ ] Typed options.
- [ ] Icons use system size.
- [ ] Destructive item variant nếu cần.
- [ ] Divider policy.
- [ ] Item height/padding locked.
- [ ] No arbitrary menu styling.

## 38. `MenuThemeData`

Raw M3: `MenuAnchor`, menu surfaces.

### Theme checklist

- [ ] Surface.
- [ ] Shape.
- [ ] Elevation.
- [ ] Shadow.
- [ ] Padding.
- [ ] Alignment/constraints where theme permits.

### Shared widget: `MxMenu`

Chỉ build khi MenuAnchor workflow xuất hiện.

## 39. `MenuButtonThemeData`

### Theme checklist

- [ ] Menu item text.
- [ ] Icon.
- [ ] Hover.
- [ ] Focus.
- [ ] Pressed.
- [ ] Disabled.
- [ ] Padding.
- [ ] Minimum size.
- [ ] Submenu indicator.

### Shared widget: `MxMenuItem`

- [ ] Semantic item model.
- [ ] Shortcut text nếu desktop.
- [ ] Destructive semantic option.
- [ ] No visual parameters.

## 40. `MenuBarThemeData`

Desktop/tablet only.

### Theme checklist

- [ ] Background.
- [ ] Surface tint.
- [ ] Elevation.
- [ ] Shape.
- [ ] Padding.
- [ ] Menu item alignment.

### Shared widget: `MxMenuBar`

Chỉ build nếu desktop UX thực sự dùng menubar.

## 41. `DropdownMenuThemeData`

Raw: `DropdownMenu`.

### Theme checklist

- [ ] Input decoration phối với MxTextField.
- [ ] Menu surface phối với Popup/Menu.
- [ ] Text style.
- [ ] Menu item style.
- [ ] Width behavior.
- [ ] Trailing icon.
- [ ] Enabled/disabled/error.
- [ ] Selected value appearance.

### Shared widget: `MxDropdown`

- [ ] Typed items.
- [ ] Label/hint.
- [ ] Validation.
- [ ] Searchable option nếu required.
- [ ] No raw `InputDecoration`.
- [ ] No raw menu style.

## 42. Legacy `DropdownButton`

`ThemeData` không có component slot hiện đại tương đương đầy đủ.

Policy:

- [ ] Không dùng mới.
- [ ] Migrate sang `DropdownMenu`.
- [ ] Nếu còn legacy usage, `canvasColor` + typography + disabled fallback
      phải không phá palette.
- [ ] Guard new usage.

## 43. `TooltipThemeData`

### Theme checklist

- [ ] Background = inverse/tooltip surface.
- [ ] Foreground.
- [ ] Typography.
- [ ] Radius.
- [ ] Padding.
- [ ] Wait duration.
- [ ] Prefer below/position policy nếu cần.
- [ ] Text scaling.

### Shared widget

Không cần `MxTooltip` nếu raw tooltip fully themed. `MxIconButton` phải tự yêu
cầu tooltip/accessibility label khi necessary.

## 44. `SnackBarThemeData`

### Theme checklist

- [ ] Background.
- [ ] Content text.
- [ ] Action text.
- [ ] Shape.
- [ ] Floating/fixed behavior.
- [ ] Width/margin.
- [ ] Elevation — explicit, theo depth policy của app (repo này: theo
      brightness, chung một `_overlayElevation` với FAB).
- [ ] Dismiss icon.
- [ ] Error/success không tạo tùy ý một snack family khác nếu design chưa
      định nghĩa.

### Shared API: `MxSnackBar` hoặc `MxMessenger`

Nên ưu tiên service/helper API:

```dart
MxMessenger.success(...)
MxMessenger.error(...)
MxMessenger.info(...)
```

- [ ] Duration policy.
- [ ] Semantic announcements.
- [ ] Action contract.
- [ ] Icon contract.
- [ ] No screen-level raw `SnackBar(...)`.

## 45. `MaterialBannerThemeData`

### Theme checklist

- [ ] Background.
- [ ] Content text.
- [ ] Padding.
- [ ] Leading icon.
- [ ] Action styling.
- [ ] Divider.
- [ ] Elevation.

### Shared widget: `MxBanner`

Chỉ build khi product cần persistent inline/global announcement.
