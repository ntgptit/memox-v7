# II. App Chrome & Navigation

## 8. `AppBarThemeData`

Raw: `AppBar`, `SliverAppBar`.

### Theme checklist

- [ ] Background.
- [ ] Foreground.
- [ ] Title typography.
- [ ] Icon theme.
- [ ] Action icon theme.
- [ ] Elevation.
- [ ] Scrolled-under elevation.
- [ ] Surface tint.
- [ ] Center title policy.
- [ ] System overlay style.
- [ ] Toolbar height nếu design cố định.

### Shared widget: `MxAppBar`

- [ ] `title`.
- [ ] Optional back affordance.
- [ ] Semantic action slots.
- [ ] Consistent max action count.
- [ ] Icon buttons luôn `MxIconButton`.
- [ ] Internal horizontal padding locked.
- [ ] Title overflow locked.
- [ ] Không nhận background/radius/elevation.
- [ ] Support standard / contextual mode nếu thực sự cần.

## 9. `ActionIconThemeData`

### Theme checklist

- [ ] AppBar action icons có cùng visual treatment.
- [ ] Back/close/menu semantics rõ.
- [ ] Không lệch `IconButtonTheme`.

### Shared widget

Không cần wrapper riêng nếu `MxAppBar` + `MxIconButton` đã own contract.

## 10. `NavigationBarThemeData`

Raw: `NavigationBar`.

### Theme checklist

- [ ] Background.
- [ ] Elevation.
- [ ] Surface tint.
- [ ] Indicator fill.
- [ ] Selected icon.
- [ ] Unselected icon.
- [ ] Selected label.
- [ ] Unselected label.
- [ ] Selected weight — qua `withWeight`, vì `copyWith(fontWeight:)` trần trên
      variable font vẽ weight cũ (bug thật, M99.61).
- [ ] Label visibility.
- [ ] Height.
- [ ] Selected state không chỉ khác bằng hue khó nhận biết.

### Shared widget: `MxNavigationBar`

- [ ] Nhận semantic destinations.
- [ ] Nhận selected index.
- [ ] Không nhận indicator color.
- [ ] Không nhận icon color.
- [ ] Không nhận height.
- [ ] Badge nếu có phải dùng `MxBadge`.
- [ ] Feature không dựng `NavigationDestination` tùy ý nếu điều đó phá
      geometry.

## 11. `NavigationDrawerThemeData`

Raw: `NavigationDrawer`.

### Theme checklist

- [ ] Background.
- [ ] Surface tint.
- [ ] Indicator color.
- [ ] Indicator shape.
- [ ] Label typography.
- [ ] Selected/unselected ink.
- [ ] Elevation.
- [ ] Width policy.

### Shared widget: `MxNavigationDrawer`

- [ ] Semantic destination model.
- [ ] Fixed internal padding.
- [ ] `MxNavigationDrawerHeader` nếu header có design riêng.
- [ ] Selected state giống navigation language chung.

## 12. `NavigationRailThemeData`

Raw: `NavigationRail`.

### Theme checklist

- [ ] Background.
- [ ] Indicator.
- [ ] Selected/unselected icon.
- [ ] Selected/unselected label.
- [ ] Label behavior.
- [ ] Width/minWidth.
- [ ] Group alignment.
- [ ] Elevation.

### Shared widget: `MxNavigationRail`

Chỉ build nếu tablet/desktop layout support rail. (Lưu ý: AD-04 hiện không ship
large-screen layout — mục này chờ quyết định đó đổi.)

- [ ] Destination API giống `MxNavigationBar`.
- [ ] Không tạo vocabulary selected mới.
- [ ] Có parity tests giữa rail và bar.

## 13. `BottomAppBarThemeData`

### Theme checklist

- [ ] Background.
- [ ] Elevation.
- [ ] Surface tint.
- [ ] Shape/notch nếu app dùng FAB.
- [ ] Padding.
- [ ] Shadow.

### Shared widget: `MxBottomAppBar`

Chỉ cần nếu app có bottom action chrome ngoài `NavigationBar`.

## 14. `BottomNavigationBarThemeData`

### Legacy policy

- [ ] Không dùng mới.
- [ ] Guard feature imports/usages.
- [ ] Dùng `NavigationBar` thay thế.
- [ ] Nếu dependency bắt buộc render nó, map tối thiểu về palette của app.

Không tạo `MxBottomNavigationBar`.
