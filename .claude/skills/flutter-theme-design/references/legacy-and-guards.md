# X. Legacy · XI. Banned raw widgets · XIV. Static guard · XV. Admission rule

## 53. `ToggleButtonsThemeData`

Policy:

- [ ] Không dùng mới.
- [ ] Dùng `SegmentedButton`.
- [ ] Guard raw `ToggleButtons`.
- [ ] Không tạo Mx wrapper.

## 54. `ButtonThemeData`

Legacy theme used by old Material widgets.

Policy:

- [ ] Không dùng để style modern buttons.
- [ ] Không coi nó là action design system.
- [ ] Chỉ set fallback nếu legacy Flutter widget còn đọc nó.
- [ ] Không tạo shared wrapper dựa trên `ButtonThemeData`.

## XI. Raw widgets không nên có visual freedom ở feature layer

Guard trực tiếp trong `lib/features/**`. **Trạng thái hiện tại:**
`memox_v7.design_system.no_raw_button` phủ bốn nút đầu; các mục còn lại là
đích mở rộng của guard, mỗi mục thêm phải kèm lượt chạy chứng minh rule bắn
đúng site hiện có (hoặc 0) trước khi ship — như bốn nút đã làm ở M99.61.

- [x] `FilledButton`
- [x] `OutlinedButton`
- [x] `TextButton`
- [x] `ElevatedButton`
- [ ] `IconButton`
- [ ] `FloatingActionButton`
- [ ] `Card`
- [ ] `ListTile`
- [ ] `Checkbox`
- [ ] `CheckboxListTile`
- [ ] `Radio`
- [ ] `RadioListTile`
- [ ] `Switch`
- [ ] `SwitchListTile`
- [ ] `ChoiceChip`
- [ ] `FilterChip`
- [ ] `ActionChip`
- [ ] `InputChip`
- [ ] `SegmentedButton`
- [ ] `TextField`
- [ ] `TextFormField`
- [ ] `NavigationBar`
- [ ] `NavigationDrawer`
- [ ] `NavigationRail`
- [ ] `BottomNavigationBar`
- [ ] `BottomAppBar`
- [ ] `Dialog`
- [ ] `AlertDialog`
- [ ] Direct `showDialog` nếu wrapper API đã tồn tại
- [ ] Direct `showModalBottomSheet`
- [ ] `PopupMenuButton`
- [ ] `DropdownMenu`
- [ ] `DropdownButton`
- [ ] `SnackBar`
- [ ] `MaterialBanner`
- [ ] `SearchBar`
- [ ] `SearchAnchor`
- [ ] `Slider`
- [ ] `RangeSlider`
- [ ] `TabBar`
- [ ] `ExpansionTile`
- [ ] `Badge`
- [ ] Direct interactive `InkWell`
- [ ] Direct interactive `InkResponse`

Cho phép raw layout primitives: `Row`, `Column`, `Stack`, `Wrap`, `Flex`,
`Expanded`, `Flexible`, `Align`, `Center`, `Positioned`, `Padding`, `SizedBox`,
`Spacer`, `LayoutBuilder`, scrolling/layout primitives khi không tự mang
visual language.

## XIV. Feature layer static guard

Trong `lib/features/**`, fail CI nếu xuất hiện visual escapes như:

- [ ] `Color(`
- [ ] `Colors.`
- [ ] `TextStyle(`
- [ ] `BorderRadius.circular(`
- [ ] `BorderSide(`
- [ ] `BoxShadow(`
- [ ] `ButtonStyle(`
- [ ] `.styleFrom(`
- [ ] `ShapeDecoration(`
- [ ] `RoundedRectangleBorder(`
- [ ] Arbitrary `Icon(size:)`
- [ ] Raw interactive Material widgets nằm trong banned list

Allowlist chỉ dành cho:

```
lib/core/theme/**
lib/shared/widgets/**
```

và exception phải có comment/rule ID.

**Chỗ đặt rule trong repo này:**
`code-verification-guard-v2/registries/projects/memox-v7/rules/memox-design-system-rules.yaml`,
scope `presentation_files` (không phải `ui_surfaces` — `lib/shared/` là nơi
primitives dựng raw widget hợp lệ). Ruleset `memox` cũ có rule tương tự nhưng
scope layer-first: load lại sẽ **xanh mà không match gì** — viết rule mới, đừng
trỏ manifest sang file cũ.

## XV. Admission rule cho raw Material widget mới

Trước khi feature được dùng một Material widget chưa support:

- [ ] Tìm ThemeData slot tương ứng.
- [ ] Xác định raw widget đọc những default nào — **đọc SDK thật**, đừng đoán:
      default có thể hardcode theo cặp màu cũ (`_FABDefaultsM3`) hoặc tự tổng
      hợp overlay (`IconButton.styleFrom`).
- [ ] Liệt kê các default không thể theme.
- [ ] Map color roles.
- [ ] Map typography.
- [ ] Map radius/shape.
- [ ] Map elevation.
- [ ] Map internal geometry.
- [ ] Map states.
- [ ] Map accessibility.
- [ ] Build shared wrapper nếu ThemeData không đủ.
- [ ] Add golden/state tests.
- [ ] Add raw-widget guard.
- [ ] Sau đó feature mới được sử dụng Mx component.

Không được:

> feature dùng raw trước → thấy xấu → override cục bộ → vài tháng sau mới nghĩ
> đến shared widget.

Luồng đúng:

> Design decision → token → ThemeData → shared widget → tests → feature.

**Ngoại lệ có kiểm soát — planned themes:** một theme cho component chưa render
được phép vào `ThemeData` khi và chỉ khi qua admission test ba điều kiện của
`app_planned_themes.dart` (chỉ restate token đã quyết và đã đo; component có
tên trong roadmap thật; M3 default sai theo cách đã xác lập), và
`theme_coverage_test` giữ hai chiều: rendered ⇒ themed, themed-chưa-rendered ⇒
nằm trong allowlist có lý do, allowlist-mà-đã-rendered ⇒ test fail.
