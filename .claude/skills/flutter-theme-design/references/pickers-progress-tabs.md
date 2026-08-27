# VII. Pickers & Search · VIII. Progress & Feedback · IX. Tabs & Data

## 46. `DatePickerThemeData`

### Theme checklist

- [ ] Dialog background.
- [ ] Header background/foreground.
- [ ] Day typography.
- [ ] Weekday typography.
- [ ] Today indication.
- [ ] Selected day fill/ink.
- [ ] Range colors nếu range picker.
- [ ] Disabled dates.
- [ ] Year view.
- [ ] Shape.
- [ ] Elevation.
- [ ] Input mode.
- [ ] Buttons.
- [ ] Divider.
- [ ] Locale/RTL.

### Shared API: `MxDatePicker`

Không nhất thiết wrap visual widget; có thể wrap `showDatePicker`.

- [ ] Initial date rules.
- [ ] Allowed range.
- [ ] Locale.
- [ ] Date format.
- [ ] Semantic result.
- [ ] Caller không truyền visual builder.

## 47. `TimePickerThemeData`

### Theme checklist

- [ ] Dialog surface.
- [ ] Shape.
- [ ] Elevation.
- [ ] Dial surface.
- [ ] Dial hand.
- [ ] Selected dial text.
- [ ] Hour/minute selected/unselected.
- [ ] AM/PM selected/unselected.
- [ ] Border.
- [ ] Entry mode icon.
- [ ] Typography.
- [ ] 12/24-hour layout verified.

### Shared API: `MxTimePicker`

- [ ] Wraps `showTimePicker`.
- [ ] Locale/hour-format policy.
- [ ] Feature không theme inline.

## 48. `SearchBarThemeData`

### Theme checklist

- [ ] Background.
- [ ] Foreground.
- [ ] Hint.
- [ ] Shape.
- [ ] Elevation.
- [ ] Surface tint.
- [ ] Padding.
- [ ] Leading/trailing icons.
- [ ] Hover/focus.
- [ ] Constraints/height.

### Shared widget: `MxSearchField` / `MxSearchBar`

- [ ] Clear action.
- [ ] Search icon.
- [ ] Debounce không thuộc visual widget nếu business-specific.
- [ ] Search geometry locked.
- [ ] No raw colors/padding/radius.

## 49. `SearchViewThemeData`

Raw: `SearchAnchor` search view.

### Theme checklist

- [ ] Full search surface.
- [ ] Header.
- [ ] Divider.
- [ ] Constraints.
- [ ] Elevation.
- [ ] Shape.
- [ ] Result list typography.
- [ ] Background.

### Shared widget: `MxSearchAnchor`

Chỉ build nếu app sử dụng expandable/fullscreen M3 search experience.

## 50. `ProgressIndicatorThemeData`

Raw: `CircularProgressIndicator`, `LinearProgressIndicator`.

### Theme checklist

- [ ] Indicator color.
- [ ] Track color.
- [ ] Stroke width.
- [ ] Stroke cap.
- [ ] Linear track shape.
- [ ] Circular track visibility.
- [ ] Graphic contrast ≥ 3:1 nơi indicator cần được nhận biết.

### Shared widgets

`MxLoadingIndicator`, `MxProgressBar` — tách semantics:

- `MxLoadingIndicator` — indeterminate loading.
- `MxProgressBar` — study/progress data.

- [ ] Progress 100% semantic variant nếu design định nghĩa.
- [ ] Track/fill lấy semantic tokens. (Lưu ý dark của repo này:
      `progressFill` và `primaryAccent` cùng một màu — bước hiện tại phải khác
      bằng hình, không chỉ bằng hue.)
- [ ] Label placement locked.
- [ ] Accessibility value `%`.

## 51. `TabBarThemeData`

Raw: `TabBar`, `TabBar.secondary`.

### Theme checklist

- [ ] Selected label.
- [ ] Unselected label.
- [ ] Selected typography.
- [ ] Indicator.
- [ ] Indicator size.
- [ ] Divider.
- [ ] Overlay.
- [ ] Splash.
- [ ] Label padding.
- [ ] Alignment.
- [ ] Primary vs secondary tab distinction.

### Shared widget: `MxTabs`

- [ ] Semantic tab definitions.
- [ ] Fixed vs scrollable contract.
- [ ] No arbitrary indicator.
- [ ] Badge uses `MxBadge`.
- [ ] Overflow behavior.

## 52. `DataTableThemeData`

### Theme checklist

- [ ] Heading background/ink.
- [ ] Data row ink.
- [ ] Selected rows.
- [ ] Hover.
- [ ] Divider.
- [ ] Checkbox integration.
- [ ] Heading/data typography.
- [ ] Horizontal/column spacing.
- [ ] Row height/min/max.
- [ ] Sort indicator.
- [ ] Border.

### Shared widget: `MxDataTable`

Chỉ build nếu product dùng table.

- [ ] Typed columns.
- [ ] Empty/loading/error states.
- [ ] Responsive strategy.
- [ ] Sorting semantics.
- [ ] Pagination strategy nếu needed.
- [ ] No cell-level visual ad hoc.
