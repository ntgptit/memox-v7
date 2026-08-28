# Upgrade Tag Catalog — Card Detail Visual Language

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc nâng cấp bố cục và phân tầng thị giác của Tag Catalog theo ngôn ngữ Card Detail mà không đổi nghiệp vụ tag |
| **Scope** | Presentation Tag Catalog, overlay rename/delete liên quan, tests hình học/a11y, golden và gallery; không đổi tag filtering trong Card List trừ shared visual regression bắt buộc |
| **Source of truth for** | Hướng dẫn thực thi Tag Catalog visual hierarchy; nghiệp vụ chính thức vẫn thuộc BR-230…BR-238, UC-18 và wireframe M4.14 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-230…BR-238, UC-18, `docs/wireframes/m4-14-tag-management.md`, production Card Detail và MemoX design tokens |
| **Updated by task** | Tag Catalog visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Triển khai **Tag Catalog — Card Detail Visual Language** từ `origin/main` mới
nhất. Đây là restyle presentation-only của catalog production đã tồn tại. Không
đổi normalization, search, sort, count, rename/merge, delete, filter semantics,
repository, DAO, route hoặc dữ liệu.

## Pre-flight

1. Đọc đầy đủ contract repo, BR-230…BR-238, UC-18, M4.14, code/test/golden Tag
   Catalog hiện tại và production Card Detail hiện tại.
2. Inspect `MxContentShell`, `MxCard`, `MxSearchField`, `MxListTile`,
   `MxIconButton`, menu/dialog/form-sheet và token typography/surface/spacing.
3. Kiểm tra branch, base và dirty state; không revert thay đổi ngoài scope.
4. Viết reduced UI Contract và widget tree production trước khi sửa code.
5. Không commit/push/PR trong implementation phase; coordinator giao hàng sau
   hai recursive review và final gate.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Catalog hiện là các dòng chữ và menu trôi trực tiếp trên nền trang. | Tạo một working surface rõ cho danh sách, nhưng không biến mỗi tag thành một card riêng. |
| 2 | Tên, count và menu có hierarchy yếu nên khó scan catalog dài. | Dùng compact typography, một leading semantic well và count phụ có tabular figures. |
| 3 | Search đang nổi bật hơn chính dữ liệu quản lý. | Giữ search ở subheader nhưng giảm visual weight, cùng content width với catalog. |
| 4 | Rename/delete đã có hành vi đúng và nhiều edge case nguyên tử. | Restyle không được chạm controller/domain/data hoặc đổi copy/hành vi overlay. |
| 5 | Golden mới có thể khoá một danh sách lệch gutter. | Pin shared edges, row geometry và overlay actions bằng `getRect` trên production tree. |

## Visual thesis

Card Detail là visual parent về **surface ladder, density và typography**, không
phải product-layout template:

- nền trang yên, một cột đọc giữa màn hình, giới hạn ở
  `AppBreakpoints.medium`;
- `MxCard` flat/subtle cho nhóm dữ liệu; không shadow stack và không card-per-row;
- section label compact, title `titleSmall/titleMedium`, metadata `bodySmall`;
- icon nằm trong semantic well nhẹ; màu chỉ là cue phụ;
- mọi content surface dùng cùng `mxScreenGutter(context)` và shared edges.

## UI Contract

```text
MxContentShell
├─ title: Tags
├─ subheader: full-width MxSearchField
└─ body
   └─ centered constrained column
      ├─ populated: one catalog MxCard
      │  └─ TagCatalogRow × N + subtle separators
      ├─ empty
      ├─ search-empty
      └─ error
```

### Populated catalog

- Search và catalog surface MUST có cùng left/right edges.
- Danh sách MUST là một surface liên tục; mỗi row không có shadow/radius/card
  riêng. Dùng separator subtle hoặc spacing nội bộ, không dùng cả hai quá nặng.
- Mỗi row giữ canonical name tối đa hai dòng, active-card count và overflow
  menu đúng M4.14. Không thêm preview, màu tag, selection hoặc CTA tạo tag.
- Có thể thêm leading icon well `sell_outlined` nếu nó cải thiện scan, nhưng
  mọi row phải dùng cùng glyph/tone trung tính; nó không được ngụ ý hierarchy
  hoặc loại tag khác nhau.
- Tên dùng `titleSmall`/`bodyLarge` phù hợp density Card Detail; count dùng
  `bodySmall`, `onSurfaceVariant`, tabular figures. Menu dùng `MxIconButton` và
  vùng chạm tối thiểu 48dp.
- Tag 0 card vẫn hiện và giữ cùng anatomy. Không dùng danger/warning cho số 0.

### Empty, search-empty và error

- Giữ đúng state matrix W3. Search-empty vẫn giữ search; empty thật không CTA;
  error ẩn search và có Retry.
- Các state dùng shared `MxEmptyState`/`MxErrorState`, nằm trong cùng constrained
  column và không tự thêm một gutter thứ hai.

### Rename và delete

- Giữ đúng merge disclosure, validation, retry, focus return và destructive
  copy hiện có.
- Restyle overlay theo cùng compact typography/surface roles của Card Detail,
  nhưng vẫn dùng shared `MxFormSheet`/`MxConfirmDialog`.
- Action row phải dùng `MxButtonPair` khi có hai action; keyboard/safe-area do
  shared overlay sở hữu. Không tạo raw Dialog/Button/Card.

## Files dự kiến

- `lib/features/card/presentation/screens/tag_catalog_screen.dart`
- `lib/features/card/presentation/widgets/items/tag_catalog_row_widget.dart`
- các overlay tag trong `presentation/widgets/overlays/` chỉ khi visual parity
  thật sự yêu cầu; không đổi command flow
- ARB chỉ khi thiếu semantic/tooltip key, không đổi product copy đã chốt
- `docs/wireframes/m4-14-tag-management.md`: append visual revision, không sửa
  các quyết định cũ
- `docs/wbs.md`: ghi đúng scope presentation-only và evidence
- tests/goldens/Widgetbook/visual audit tương ứng.

## Không được thay đổi

- BR-230…BR-238, UC-18, OR filter semantics, folded search/sort, active count.
- Rename giữ ID; collision merge nguyên tử; delete chỉ gỡ tag.
- Route/entry point, pagination contract, card-list filter behavior.
- Domain/data/repository/DAO/schema hoặc user-visible fields/actions.
- Global typography/tokens chỉ để làm riêng catalog đẹp hơn.

## Tests bắt buộc

- Regression mọi face và overlay hiện có; rename/merge/delete callback không đổi.
- `getRect`: search, catalog, empty/error cùng content edges; row edges thống
  nhất; title/count cùng baseline trái; menu trong gutter và ≥48dp.
- 320dp @ textScale 2.0, 393dp, 412dp; EN/VI; light/dark; tên tag dài, count lớn,
  0 card, keyboard mở ở rename.
- Semantics: menu có nhãn theo tag; count không bị đọc lặp; focus trở về đúng row;
  dialog/sheet action order đúng.
- Render và inspect populated, empty, search-empty, read-error, rename normal,
  merge disclosure, validation error, delete 0-card và delete many-card.

## Verification và clean stop

Chạy:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Không chạy emulator integration suite vì chỉ restyle route hiện hữu; báo
`not run — presentation-only restyle`. Clean stop khi changed gate xanh, không
logic/navigation/data drift, geometry contract pass và worktree sẵn sàng cho hai
recursive review độc lập. Golden/gallery/PR thuộc coordinator delivery phase.
