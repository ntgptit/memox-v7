# IV. Input & Selection

## 21. `InputDecorationThemeData`

Raw: `TextField`, `TextFormField`, `InputDecorator`.

### Theme checklist

- [ ] Filled vs outlined policy.
- [ ] Resting border.
- [ ] Focus border.
- [ ] Error border.
- [ ] Disabled border.
- [ ] Border width không gây layout shift.
- [ ] Radius.
- [ ] Internal padding.
- [ ] Label style.
- [ ] Hint style.
- [ ] Helper style.
- [ ] Error style.
- [ ] Prefix/suffix icon constraints.
- [ ] Icon size/color.
- [ ] Counter style.
- [ ] Floating label behavior nếu dùng.
- [ ] Text cursor/selection phối đúng.

### Shared widget: `MxTextField`

Variants: standard; search-specific wrapper riêng nếu geometry khác.

API: label, hint, controller/value, validation/error, prefix semantic icon,
suffix action, obscureText, keyboard/input behavior.

Không expose: border, fillColor, contentPadding, radius, textStyle, icon size.

## 22. `TextSelectionThemeData`

### Theme checklist

- [ ] Cursor.
- [ ] Selection background.
- [ ] Selection handles.
- [ ] Selection vẫn nhận biết trên page/card/input backgrounds.
- [ ] Selection không làm text mất contrast.

Không cần shared widget.

## 23. `CheckboxThemeData`

### Theme checklist

- [ ] Selected fill.
- [ ] Unselected border.
- [ ] Checkmark.
- [ ] Disabled selected.
- [ ] Disabled unselected.
- [ ] Error state.
- [ ] Hover.
- [ ] Press.
- [ ] Focus ring.
- [ ] Shape.
- [ ] Hit target.

### Shared widget: `MxCheckbox`

- [ ] Optional label nên dùng composition có semantics merge.
- [ ] Có indeterminate nếu product cần.
- [ ] Không cho feature truyền activeColor.
- [ ] `CheckboxListTile` raw bị guard; dùng `MxCheckboxTile`.

## 24. `RadioThemeData`

### Theme checklist

Tương tự checkbox:

- [ ] Selected.
- [ ] Unselected.
- [ ] Disabled.
- [ ] Hover.
- [ ] Press.
- [ ] Focus.
- [ ] Error nếu relevant.
- [ ] Hit target.

### Shared widget: `MxRadio`

- [ ] Group semantics rõ.
- [ ] Label wrapper `MxRadioTile` nếu dùng trong list.
- [ ] Không expose raw color.

## 25. `SwitchThemeData`

### Theme checklist

- [ ] Track on/off.
- [ ] Thumb on/off.
- [ ] Disabled combinations.
- [ ] Hover.
- [ ] Focus.
- [ ] Press.
- [ ] Border/outline nếu design cần.
- [ ] Icon inside thumb nếu dùng.
- [ ] Track outline.
- [ ] Hit target.

### Shared widget: `MxSwitch`

- [ ] `MxSwitchTile` cho setting rows.
- [ ] Entire row tap semantics thống nhất.
- [ ] Không có feature-specific color.

## 26. `ChipThemeData`

Raw: `ChoiceChip`, `FilterChip`, `ActionChip`, `InputChip`.

### Theme checklist

- [ ] Resting fill.
- [ ] Selected fill.
- [ ] Resting border.
- [ ] Selected border.
- [ ] Resting label.
- [ ] Selected label.
- [ ] Disabled selected/unselected.
- [ ] Hover.
- [ ] Press.
- [ ] Focus.
- [ ] Checkmark policy.
- [ ] Shape.
- [ ] Label typography.
- [ ] Internal horizontal padding.
- [ ] Label padding.
- [ ] Icon size.
- [ ] Icon-label gap.
- [ ] Painted height.
- [ ] 48 target vẫn đảm bảo.
- [ ] Text scale không bị fixed-height clipping.

### Shared widgets

Không nên ép bốn raw chip vào một API nếu semantics khác. Nên có:

- `MxPillButton` — filter/sort/select.
- `MxActionChip` — compact command nếu product cần.
- `MxInputChip` — removable entity/tag nếu product cần.

Mỗi wrapper:

- [ ] Semantic variant rõ.
- [ ] Icon/label/delete states đồng màu.
- [ ] Không expose `shape`, `padding`, `side`, `selectedColor`.

## 27. `SegmentedButtonThemeData`

### Theme checklist

- [ ] Selected fill.
- [ ] Selected ink.
- [ ] Unselected fill.
- [ ] Divider/border.
- [ ] Shape của first/middle/last.
- [ ] Disabled.
- [ ] Hover/press/focus.
- [ ] Typography.
- [ ] Icon.
- [ ] Multi vs single selection visual.

### Shared widget: `MxSegmentedControl`

- [ ] Typed semantic options.
- [ ] Single/multi selection là explicit API.
- [ ] Không nhận arbitrary `ButtonSegment` styling.
- [ ] Responsive overflow strategy.

## 28. `SliderThemeData`

Raw: `Slider`, `RangeSlider`.

### Theme checklist

- [ ] Active track.
- [ ] Inactive track.
- [ ] Disabled track.
- [ ] Thumb.
- [ ] Overlay.
- [ ] Tick marks.
- [ ] Value indicator.
- [ ] Track height.
- [ ] Shapes.
- [ ] Label typography.
- [ ] Focus/hover.
- [ ] Contrast trên backgrounds thực tế.

### Shared widgets

`MxSlider`, `MxRangeSlider`.

- [ ] Range/value semantics.
- [ ] Labels/formatters semantic.
- [ ] Không expose raw colors/shapes.
