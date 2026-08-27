# III. Buttons & Actions

**Nguyên tắc chương này, trả giá mới có (M99.61):** đổi resting fill/foreground
của một component khỏi cặp canonical của Material thì **mọi state default
component đó sở hữu là của mình phải khai lại** — M3 hardcode default theo cặp
*cũ* (FAB: `onPrimaryContainer` 8/10/10%), không suy từ override.

## 15. `FilledButtonThemeData`

Raw: `FilledButton`, `FilledButton.tonal`.

### Theme checklist

- [ ] Minimum size.
- [ ] Internal padding.
- [ ] Shape.
- [ ] Typography.
- [ ] Primary fill/label.
- [ ] Hover.
- [ ] Press.
- [ ] Focus.
- [ ] Disabled fill/label.
- [ ] Icon size.
- [ ] Icon-label gap.
- [ ] Loading behavior không thay đổi geometry.

### Shared widget: `MxActionButton`

Required variants: `primary`, `tonal`, `destructive`.

- [ ] Variant là semantic, không phải color.
- [ ] Optional leading icon.
- [ ] Loading.
- [ ] Disabled.
- [ ] Full-width chỉ là layout option có chủ ý (wrapper `SizedBox` bên ngoài,
      không phải `Size.fromHeight` trong style).
- [ ] Caller không truyền style.
- [ ] Destructive dùng cùng geometry/state machine với primary.
- [ ] Tonal không được clone toàn bộ visual implementation riêng.
- [ ] Geometry axis (nếu có, như `size: compact`) là enum — cái ngày caller
      truyền được `Size`/`EdgeInsets` là ngày guard cấm nút thô chỉ dời sự tuỳ
      tiện sang file bên cạnh.

## 16. `OutlinedButtonThemeData`

### Theme checklist

- [ ] Resting border dùng interactive-control border token.
- [ ] Label đủ contrast.
- [ ] Border disabled.
- [ ] Focus ring.
- [ ] Hover/press.
- [ ] Shape/height/padding giống action family.
- [ ] Không dùng decorative hairline nếu border là dấu hiệu chính nhận diện
      control.

### Shared widget

`MxActionButton.secondary`

- [ ] Cùng geometry với primary.
- [ ] Khác emphasis, không khác component language.
- [ ] Không expose borderColor.

## 17. `TextButtonThemeData`

### Theme checklist

- [ ] Accent label dùng text-safe color.
- [ ] Disabled text.
- [ ] Hover.
- [ ] Press.
- [ ] Focus-visible.
- [ ] Padding contract.
- [ ] Minimum hit target.
- [ ] Typography.
- [ ] Nếu không có surface, state phải hiện trên text/underline/ring hợp lý.

### Shared widget: `MxTextButton`

Variants: default, destructive.

- [ ] Có optional icon.
- [ ] Không nhận arbitrary padding.
- [ ] Không biến thành outlined button không viền.

Quyết định đã chốt trong repo này: `TextButton` == link toàn app (builder tuyên
bố), và guard cấm raw `TextButton` trong features là phần enforcement của
quyết định đó — không mở lại.

## 18. `ElevatedButtonThemeData`

Policy:

- [ ] Không dùng mới.
- [ ] `FilledButton` là strong action.
- [ ] Elevation được thể hiện qua surface system, không tạo thêm action family.
- [ ] Guard raw `ElevatedButton`.

Không cần `MxElevatedButton`.

## 19. `IconButtonThemeData`

Raw: `IconButton`, filled, filled tonal, outlined.

### Theme checklist

- [ ] 48×48 minimum target.
- [ ] Icon size.
- [ ] Resting ink.
- [ ] Hover.
- [ ] Press.
- [ ] Focus ring.
- [ ] Disabled ink.
- [ ] Radius/shape.
- [ ] Selected/toggled state nếu dùng.
- [ ] Filled variants không tự phát sinh style ngoài system.

Bẫy SDK đã gặp: `IconButton.styleFrom(foregroundColor:)` tự tổng hợp
`overlayColor` từ foreground và **đè overlay của theme** — muốn chỉ đổi ink thì
dựng `ButtonStyle` tay chỉ khai `foregroundColor`.

### Shared widget: `MxIconButton`

Variants semantic: standard, accent, destructive.

- [ ] `tooltip`/accessible label required khi icon không có adjacent text.
- [ ] Không nhận arbitrary icon size.
- [ ] Không nhận arbitrary foreground/background.
- [ ] Loading nếu use case có async icon action.
- [ ] Selected chỉ expose nếu component thực sự toggle.

## 20. `FloatingActionButtonThemeData`

### Theme checklist

- [ ] Fill.
- [ ] Foreground.
- [ ] Shape.
- [ ] Elevation theo light/dark.
- [ ] Focus/hover/highlight elevation.
- [ ] **Hover/focus/splash color** — M3 default là `onPrimaryContainer`
      hardcode; đổi resting pair mà bỏ ba slot này là mực hệ khác trên fill hệ
      này (bug thật, M99.61).
- [ ] Size.
- [ ] Extended typography.
- [ ] Splash.
- [ ] Không cạnh tranh visual với primary CTA khác trên cùng screen.

### Shared widget: `MxFab`

- [ ] Chỉ dùng cho screen-level primary creation/action.
- [ ] Không cho feature đổi màu.
- [ ] Semantic label required.
- [ ] Standard/extended variants nếu cần.
