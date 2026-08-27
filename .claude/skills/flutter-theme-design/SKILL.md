---
name: flutter-theme-design
description: The component-level design-language contract for this app — the per-component checklist that decides when a Material widget counts as supported by the design system, at both layers at once (ThemeData slot AND Mx shared widget). Use this skill when adding or reviewing a component theme in lib/core/theme/, when building or extending an Mx* shared widget, when a feature wants a Material widget the system does not support yet (admission rule), when deciding what an Mx API may and may not expose, or when auditing that a shared widget and its theme slot agree. flutter-design-system owns the principles (tokens, l10n, a11y); this skill owns the per-component contract those principles compile down to.
---

# ThemeData & Shared Widget Design Language

`flutter-design-system` nói *nguyên tắc* — token semantic, hai theme, a11y.
Skill này nói *hợp đồng từng component*: một Material component chỉ được coi là
**supported** khi hoàn thành **cả hai tầng** dưới đây, và mỗi tầng có checklist
riêng trong `references/`.

**Trạng thái vs. đích.** Checklist này là *đích*, không phải mô tả hiện trạng.
Guard `memox_v7.design_system.no_raw_button` hôm nay mới phủ bốn nút; danh sách
cấm đầy đủ ở `references/legacy-and-guards.md` §XI là nơi guard sẽ lớn tới.
Khi checklist và code lệch nhau: một mục chưa làm là việc chưa làm, không phải
lý do sửa checklist — sửa checklist cần quyết định của chủ dự án.

## 0. Definition of Done toàn hệ thống

### ThemeData contract

- [ ] Raw widget không truyền style vẫn render đúng app.
- [ ] Light / Dark / High Contrast đều có kết quả xác định.
- [ ] Không có màu quan trọng rơi về Flutter default ngoài chủ ý.
- [ ] Không có radius quan trọng rơi về Flutter default ngoài chủ ý.
- [ ] Không có elevation/shadow quan trọng rơi về Flutter default ngoài chủ ý.
- [ ] Typography lấy từ `TextTheme`/semantic text tokens.
- [ ] Resting / hovered / focused / pressed / selected / disabled / error được
      quyết định nếu widget có state đó.
- [ ] Interactive visual boundary cần thiết đạt ≥ 3:1.
- [ ] Normal text đạt ≥ 4.5:1.
- [ ] Không dùng một color role cho hai meaning khác nhau chỉ vì hex hiện
      giống nhau.
- [ ] Không dùng alpha paint-time nếu ground đã biết và có thể pre-compose
      thành solid token.
- [ ] Không để `surfaceTint` hoặc Material elevation overlay tự thay đổi màu
      ngoài design language.
- [ ] Internal icon mặc định có size/color đúng hệ thống.
- [ ] Motion/ripple/splash không rơi về một interaction language khác.

### Shared widget contract

- [ ] Feature không truyền `Color`.
- [ ] Feature không truyền `TextStyle`.
- [ ] Feature không truyền `BorderRadius`.
- [ ] Feature không truyền `BorderSide`.
- [ ] Feature không truyền `BoxShadow`.
- [ ] Feature không truyền raw `ButtonStyle`.
- [ ] Feature không truyền internal padding.
- [ ] Feature không truyền icon size.
- [ ] Feature không xử lý hover/focus/press/disabled visual.
- [ ] Feature chỉ chọn semantic variant.
- [ ] Widget tự đảm bảo ≥ 48×48 interactive target.
- [ ] Widget hỗ trợ RTL.
- [ ] Widget không clip ở text scale 2.0.
- [ ] Widget có semantics/accessibility name phù hợp.
- [ ] Không expose parameter chỉ vì raw Flutter widget có parameter đó.
- [ ] Escape hatch visual chỉ tồn tại nếu có use case được design system công
      nhận.

## Boundary

> Inside component = design system.
> Between components = feature layout.

Feature **được phép** quyết định: `Row`, `Column`, `Stack`, `Flex`, `Expanded`,
`Flexible`, `Padding`, `SizedBox`, screen padding, gap giữa các component,
responsive arrangement, width/flex/alignment theo layout.

Feature **không được** quyết định visual grammar của component.

## Luồng đúng, và luồng bị cấm

Luồng đúng:

> Design decision → token → ThemeData → shared widget → tests → feature.

Không được:

> feature dùng raw trước → thấy xấu → override cục bộ → vài tháng sau mới nghĩ
> đến shared widget.

Chi tiết admission rule cho một Material widget mới:
`references/legacy-and-guards.md` §XV.

## Bản đồ references

| File | Phủ | Sections |
|---|---|---|
| `references/foundation.md` | ColorScheme, TextTheme, IconTheme, interaction fallback, density, tap target, scrollbar | I (1–7) |
| `references/chrome-navigation.md` | AppBar, ActionIcon, NavigationBar/Drawer/Rail, BottomAppBar, legacy BottomNavigationBar | II (8–14) |
| `references/buttons-actions.md` | Filled/Outlined/Text/Elevated/Icon button, FAB | III (15–20) |
| `references/input-selection.md` | Input, TextSelection, Checkbox, Radio, Switch, Chip, SegmentedButton, Slider | IV (21–28) |
| `references/surfaces-containers.md` | Card, ListTile, ExpansionTile, Divider, Badge, Carousel | V (29–34) |
| `references/overlays-menus.md` | Dialog, BottomSheet, PopupMenu, Menu*, Dropdown, Tooltip, SnackBar, Banner | VI (35–45) |
| `references/pickers-progress-tabs.md` | Date/Time picker, SearchBar/View, ProgressIndicator, TabBar, DataTable | VII–IX (46–52) |
| `references/legacy-and-guards.md` | ToggleButtons/ButtonTheme policy, danh sách widget bị cấm ở feature, static guard, admission rule | X, XI, XIV, XV (53–54) |
| `references/construction-template.md` | Template dựng một `Mx*` mới (A–K), parity test theme ↔ widget | XII, XIII |

## Quy tắc cuối cùng

Một screen hoàn thiện tốt phải đọc gần như thế này:

```dart
MxContentShell(
  child: Column(
    children: [
      MxSearchField(...),
      const SizedBox(height: AppSpacing.lg),
      MxCard(
        child: MxListTile(...),
      ),
      const SizedBox(height: AppSpacing.xl),
      MxActionButton.primary(...),
    ],
  ),
)
```

Trong feature file lý tưởng không xuất hiện: `Color`, `Colors`, `TextStyle`,
`ButtonStyle`, `BorderRadius`, `BorderSide`, `BoxShadow`,
`MaterialStateProperty` / `WidgetStateProperty`.

Nếu feature developer cần nghĩ:

> "Button này màu gì, bo bao nhiêu, focus thế nào, icon bao nhiêu px?"

thì design system chưa hoàn thành. Nếu họ chỉ cần nghĩ:

> "Đây là primary, secondary, destructive, selected hay disabled; và nó nằm ở
> đâu?"

thì design language đã đạt mục tiêu.
