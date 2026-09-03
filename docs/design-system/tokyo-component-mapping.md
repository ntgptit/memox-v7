# Component themes — M3 contract, Tokyo intent, MemoX geometry

| | |
|---|---|
| **Status** | active |
| **Purpose** | Bảng đối chiếu từng Material component: role canonical của M3, cái memox override, ý đồ Tokyo, và token hình học — để không ai phải nhớ hoặc đoán |
| **Scope** | `lib/core/theme/components/**`. Ngoài phạm vi: giá trị token (AD-14), layering của `lib/core/theme/` (`theme-architecture.md`), API của `Mx*` widget |
| **Source of truth for** | Ma trận component → canonical M3 role · ma trận dịch ý đồ Tokyo → MemoX · hồ sơ các sai lệch role đã sửa và mô hình bề mặt |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/theme-architecture.md` |
| **Updated by task** | M100.36 |
| **Last updated** | 2026-09-03 |

---

## 1. Nguồn của cột "M3 canonical"

Mọi role trong tài liệu này **đọc từ SDK ghim** (`.fvmrc` → Flutter 3.44.8),
không phải từ trí nhớ hay từ spec trên web:

```
D:/Setup/flutter/packages/flutter/lib/src/material/**  →  class _XxxDefaultsM3
```

Trích bằng script, không chép tay. Khi nâng SDK, chạy lại phần trích và đối
chiếu — một role đổi trong SDK mà bảng này không đổi là một sai lệch âm thầm.

Thứ tự ưu tiên khi xung đột, theo brief và AD-14:

```
canonical M3 role  >  accessibility  >  MemoX structural system  >  Tokyo exact hex
```

---

## 2. Ma trận role — component × slot

`=` nghĩa là memox bind đúng role canonical. Cột cuối chỉ có nội dung khi khác.

### actions/

| Component | Slot | M3 canonical (SDK 3.44.8) | MemoX | Ghi chú |
|---|---|---|---|---|
| FilledButton | background | `primary` (disabled: `onSurface`) | = | disabled dùng `semantic.disabledSurface` — solid, R7 |
| FilledButton | foreground | `onPrimary` (disabled: `onSurface`) | = | disabled dùng `semantic.onDisabled` |
| FilledButton | overlay | `onPrimary` @ .08/.10/.10 | = | qua `MxFilledPair.stateLayerOf`; guard AST (M100.36). Trước đó là blend về `onSurface` **cộng** overlay `primary` — xem §6 |
| FilledButton (destructive) | background / foreground / overlay | `error` / `onError` / `onError` | = | `MxFilledPair.destructive`; guard AST cả ba slot |
| FilledTonalButton | — | `secondaryContainer` / `onSecondaryContainer` | **không dựng** | `MxActionButtonVariant.tonal` gỡ ở M100.36: 0 caller từ #384, và hệ thứ bậc chấm điểm (§4B) chốt bằng `secondary` |
| OutlinedButton | foreground | `primary` | = | guard AST |
| OutlinedButton | side | `outline`, focus → `primary` | = | guard AST |
| TextButton | foreground | `primary` | = | guard AST |
| IconButton | foreground | `onSurfaceVariant` | = | |
| FAB | background | `primaryContainer` | = | sửa ở M100.32; guard AST |
| FAB | foreground | `onPrimaryContainer` | = | sửa ở M100.32; guard AST |

### inputs/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| InputDecorator | outlineBorder | `outline`; focus `primary`; error `error`; focus+error `error` **stroke 2** | = | guard AST bốn slot (M100.36). Stroke chỉ đổi ở focus+error — hue đã bận, stroke là kênh còn lại (§4C); focus thường vẫn chỉ đổi hue |
| InputDecorator | fillColor | `surfaceContainerHighest` | `filled: false` | Cố ý: field là *khoảng mở*, không phải khối |
| InputDecorator | hintStyle | `bodyLarge` / `onSurfaceVariant`, disabled 38% | = | M100.36: từng là `body-md` — một rung dưới value (#433 F6) |
| InputDecorator | suffixIconColor | `onSurfaceVariant`; error `error`; disabled 38% | = | M100.36: theme `IconButton` từng chặn nhánh error của SDK (#433 F4) |
| MxSearchField (custom) | fill / edge | — (không phải InputDecorator) | `surfaceMuted` → `surface`; edge `outline` → `primary` @ `AppStroke.input` | Control tuỳ biến, ranh giới dùng hệ chung (§4E). Trước M100.36 edge = màu fill, 1.09:1 |

### selection/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| ChoiceChip | selected fill | `secondaryContainer` | = | guard AST |
| ChoiceChip (flat) | unselected fill | `null` | `surfaceContainerLow` — **theme khai, không phải variant** | `ChipThemeData.color` chặn `chipDefaults.color` trước khi variant được hỏi (`chip.dart:1529`); M100.36 sửa lại lời giải thích ở §4 |
| ChoiceChip | side | `outlineVariant`, selected trong suốt | = | guard AST; width = `AppStroke.hairline` (test ghim); 1.24:1 trên giấy — **chấp nhận**, pill định danh bằng hình, nhãn, nhóm và tick (#434 P2-4) |
| ChoiceChip | disabled fill | `onSurface @ 12%` — selected hay không | = (`disabledSurfaceTint`) | M100.36: trước đó selected+disabled blend thêm container, dark sáng *hơn* pill sống (#434 P2-3) |
| ChoiceChip | elevation / pressElevation | 1 / 1 (M3) | **0 / 0** | AD-14 một cơ chế độ sâu; `pressElevation` từng để SDK → mỗi lần nhấn có bóng thật (#434 P1-2) |
| ChoiceChip | hover / press / focus | state layer `onSurfaceVariant` | hover: fill tint (`RawChip` tắt `hoverColor` khi theme có `color`) · press: ripple SDK · focus: `MxFocusRing` | **một cơ chế mỗi state** (§4O). Fill *không* đổi khi press/focus |
| MxPillButton (custom) | leading slot | — | 16dp luôn được layout: tick khi selected, `icon` của caller khi không | chọn có *hình*, không reflow (§4M); target 48 do widget tự nới **ngoài** ring |
| Checkbox | fill | `primary` / trong suốt theo `selected` | = | guard AST |
| Switch | thumb | `outline` off / `onPrimary` on | = | guard AST |
| Switch | track | `surfaceContainerHighest` off / `primary` on | = | guard AST |
| Switch | trackOutline | `outline` off / trong suốt on | = | guard AST |
| Radio | fill | `onSurfaceVariant` / `primary` | = | |
| Slider | activeTrack | `primary` | = | |
| Slider | inactiveTrack | `secondaryContainer` | = | |
| SegmentedButton | selected bg | `secondaryContainer` | = | guard AST |
| SegmentedButton | side | `outline` | = | guard AST |

### navigation/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| NavigationBar | background | `surfaceContainer` | = | guard AST |
| NavigationBar | indicator | `secondaryContainer` | = | guard AST |
| NavigationBar | iconTheme | `onSecondaryContainer` / `onSurfaceVariant` | = | guard AST |
| NavigationBar | labelTextStyle | `onSurface` / `onSurfaceVariant` | = | guard AST |
| TabBar | labelColor | `primary` | = | guard AST |
| TabBar | indicatorColor | `primary` | = | guard AST |
| AppBar | background | `surface` | = | `surface` *là* nền trang từ M100.32; guard AST |
| AppBar | foreground | `onSurface` | = | |

### surfaces/ · content/ · feedback/ · overlays/ · pickers/

| Component | Slot | M3 canonical | MemoX | Ghi chú |
|---|---|---|---|---|
| Card | color | `surfaceContainerLow` | = | sửa ở M100.32; guard AST |
| Dialog | background | `surfaceContainerHigh` | = | |
| BottomSheet | background | `surfaceContainerLow` | = | nay là mặt giấy, theo rung |
| BottomSheet | dragHandle | `onSurfaceVariant` | = | + state layer, không đổi role |
| ListTile | selectedColor | `primary` | = | guard AST |
| ListTile | icon / title / subtitle / trailing text | `onSurfaceVariant` / `onSurface` / `onSurfaceVariant` / `onSurfaceVariant` | = | guard AST (M100.36). Trước đó theme đặt `textColor: onSurface`, thứ `ListTile` chép lên **cả** subtitle (`list_tile.dart:934`) — subtitle mọi hàng từng mang mực title (#431 P1-1) |
| ListTile | selectedTileColor | *(null — M3 không có)* | `semantic.surfaceSelected` | Bề mặt "đã chọn" app-owned duy nhất, dùng chung với tint của `MxCard` (§4I, M100.36) |
| ListTile | shape | `null` → `Border()` (hình chữ nhật) | = | M100.37: từng là `AppRadius.md`; hàng luôn nằm trong card/sheet đã sở hữu góc, 12-trong-16 chỉ hiện ra như lệch (#431 P2-11) |
| ListTile | minTileHeight | 56 (`_defaultTileHeight`) | = `AppSizing.rowMinHeight` | Nêu tường minh ở M100.36 — 48 là sàn chạm, 56 là hàng đọc (§4J) |
| Divider | — | `outlineVariant` (M3 dùng ThemeData) | = | |
| ProgressIndicator | color | `primary` | = | |
| ProgressIndicator | linearTrack | `secondaryContainer` | = | |
| SnackBar | background | `inverseSurface` | = | |
| SnackBar | action | `inversePrimary` | = | |
| SnackBar | content | `onInverseSurface` | = | |
| Tooltip | — | `inverseSurface` / `onInverseSurface` | = | |
| PopupMenu | color | `surfaceContainer` | = | |
| DatePicker | day selected | `primary` / `onPrimary` | = | |
| DatePicker | range selection | `secondaryContainer` | = | |
| TimePicker | dial background | `surfaceContainerHighest` | = | |
| TimePicker | dial hand | `primary` | = | |

---

## 3. Dịch ý đồ Tokyo — không dịch giá trị

| Tokyo | Ý đồ | MemoX target | Bất biến M3 | Dịch hình học |
|---|---|---|---|---|
| `MuiButton.root` bold | action đọc ra là action | `buttonLabelWeight` w700 | pair `primary`/`onPrimary` không đổi | weight, không phải size |
| `sizeMedium` `8px 20px` | nút chắc, không rỗng | `AppSpacing.xl` / `md` | — | 20 không có trên thang; giữ 24 |
| `MuiButtonBase` radius 6 | góc control chặt | `AppRadius.md` (12) | — | tier, không phải px |
| `general.borderRadius` 10 | góc mặt phẳng | `AppRadius.lg` (16) | — | tier |
| `shadows.cardSm` / `card` | card ngồi / panel nổi | `shadowsFor(card)` / `(raised)` | — | hai lớp, màu qua `scheme.shadow` |
| `shadows.card` (dark) | rim thay shade | rim `#6A7199` | — | edge không sâu thêm theo level |
| `MuiPaper` paper | mặt giấy nổi | `ColorScheme.surfaceContainerLow` | `surface` là nền, giấy là container | — |
| `divider` `#272C48` | vạch rất khẽ | `scheme.outlineVariant` | `outlineVariant` | `AppStroke.hairline` |
| Backdrop tối + blur | tách modal khỏi trang | `modalBarrierColor` (`scheme.scrim`) | scrim | alpha token; **blur chưa nhận** |
| `MuiIconButton` radius 8 / pad 8 | chrome gọn | `AppRadius.md` + `AppSizing.touchTarget` | `onSurfaceVariant` | sàn 48 thắng pad 8 |
| `MuiTab` height 38 | nhịp điều hướng chặt | chưa áp dụng | `primary` | 38 dưới sàn; hoãn |

**Blur của Backdrop chưa được nhận** (brief §32): nó cần một overlay recipe dùng
chung, một phép đo hiệu năng, và một quyết định — không phải từng modal tự gọi
`BackdropFilter`. Ghi ở đây để lần sau không tự ý thêm.

---

## 4. Bốn sai lệch role — đã sửa ở M100.32

Mục này từng liệt kê bốn sai lệch "đã biết" kèm lý do giữ. Ba trong bốn là hệ
quả của **một** lỗi nền tảng, cái thứ tư là một thay role thuần tuý. Cả bốn đã
được sửa; bảng giữ lại làm hồ sơ, không phải làm ngoại lệ.

### Gốc: `ColorScheme.surface` bị đọc là mặt giấy

M3 định nghĩa `surface` là **nền cơ sở**; mọi thứ đặt lên nó là container
(`surfaceContainer*`). memox làm ngược: gọi card là `surface` và để trang trong
một token **ngoài** `ColorScheme` — nên bất kỳ component nào cần màu trang cũng
phải được *đưa* một màu vào, vòng qua hệ role.

Sửa bằng cách dời **hex qua thang**, không đổi mapping component:

| Role | Trước | Sau | Nghĩa |
|---|---|---|---|
| `surface` | `#FFFFFF` / `#111633` | `#F2F5F9` / `#070C27` | trang |
| `surfaceContainerLowest` | `#FFFFFF` / `#010624` | `#F9FAFB` / `#0D1335` | một bậc dưới giấy — chỗ `MxCard.recessed` vẽ |
| `surfaceContainerLow` | `#F9FAFB` / `#0D1335` | `#FFFFFF` / `#111633` | **mặt giấy**: card, sheet, menu, pill |

Thang sau khi sửa, đo bằng L\*:

| | Highest | High | Container | **surface** | Lowest | **Low** |
|---|---|---|---|---|---|---|
| light | 90.87 | 92.98 | 95.45 | **96.42** | 98.22 | **100.00** |
| dark | 21.62 | 16.97 | 13.72 | **4.11** | 7.30 | **8.41** |

Dark đơn điệu tăng từ trang lên. Light chạm trần trắng ở mặt giấy, nên
`Container`/`High`/`Highest` nằm **dưới** trang — chúng là *inset*, và đó là thứ
app vẫn vẽ từ trước.

### Bốn binding

| # | Component | M3 canonical | Trước | Sau |
|---|---|---|---|---|
| 1 | FAB bg/fg | `primaryContainer`/`onPrimaryContainer` | `primary`/`onPrimary` | **canonical** |
| 2 | Card `color` | `surfaceContainerLow` | `surface` | **canonical** |
| 3 | AppBar bg/fg | `surface`/`onSurface` | màu trang truyền vào | **canonical** |
| 4 | ChoiceChip fill chưa chọn | flat `null` · elevated `surfaceContainerLow` | flat + `surface` | **flat + `surfaceContainerLow` do theme khai** (M100.36 sửa lại M100.32) |

#4 đáng nói riêng, vì lời giải thích ở M100.32 sai và phải ghi lại: nó cho
rằng dựng `ChoiceChip.elevated` là "nhận fill từ role". Không phải —
`ChipThemeData.color` chặn `chipDefaults.color` *trước* khi variant được hỏi
(`chip.dart:1529-1531`), nên `buildChipTheme` đã và đang là thứ tô fill; cái
variant đổi được chỉ là `shadowColor`, và với `pressElevation` để nguyên 1.0
của M3 thì mỗi lần nhấn pill chưa chọn có một bóng thật (#434 P1-2). M100.36
dựng chip **flat**, khai fill giấy trên slot canonical, và ghim cả `elevation`
lẫn `pressElevation` bằng 0. `mx_pill_button_construction_test.dart` ghim
constructor ở mức source.

Năm slot (FAB ×2, Card, AppBar ×2) được ghim ở `m3_role_binding_guard_test.dart`
ở mức **source**, nên đổi `surfaceContainerLow` thành `surface` là đỏ kể cả khi
hai hex bằng nhau.

### Một palette retune đi kèm

`AppInk.warning` đo 4.33:1 trên nền trang, dưới sàn 4.5 của text. Con số đó đã
nằm trong `app_colors.dart` từ M4.10p kèm ghi chú "nếu nó từng được dùng làm
body text thì đây là số phải kiểm lại" — `AppInk.warning` *là* text ink, nên nó
luôn vi phạm; remap chỉ làm test đo đúng nền. Theo AD-14 thì **palette dịch**:
`warningLight` `#A46500` → `#A06200`, lệch hue 0.2°, saturation không đổi, đo
4.53 trên trang và 4.95 trên giấy.

---

## 5. Ranh giới hình học

Component theme sở hữu hình học **toàn cục**; shared widget chỉ thêm composition:

| Theme | Sở hữu |
|---|---|
| `buildSharedButtonStyle` | chiều cao tối thiểu (`AppSizing.touchTarget`), bề rộng tối thiểu, padding, shape, weight nhãn. `MxActionButtonSize.compact` là **trục kích thước** của shared widget (40 vẽ / 48 chạm, `label-md`), không phải một feature nêu lại — ranh giới dưới áp cho feature |
| `buildInputDecorationTheme` | content padding, radius, stroke (input; focus ở focused-error), hint style, suffix colour. `MxSearchField` là composition riêng: sở hữu rung `body-md` của nó (widget đóng, §4P) |
| `buildChipTheme` | chiều cao pill, padding, radius, weight nhãn, side hairline, hai elevation = 0. `MxPillButton` sở hữu slot dẫn 16dp, tick khi chọn, ring quanh hình vẽ và target 48 nới ngoài ring (§4P: rung `label-md`) |
| `buildListTileTheme` | content padding, minVerticalPadding, `minTileHeight` (`AppSizing.rowMinHeight`), shape, ba rung chữ |
| `buildDialogTheme` | shape |
| `buildCardTheme` | shape, hairline |

MUST NOT: một **feature** nêu lại các giá trị này. Một shared widget đóng
(`Mx*`) MAY chuyên biệt hoá một trục kích thước hoặc rung nhãn cho composition
của chính nó **khi trục đó là một enum đóng và có caller production** —
`MxActionButtonSize.compact`, `MxTextButton.isCompact`, `MxPillButton` với
`label-md` (M100.36 §4P). Cái bị cấm là một *feature* làm việc đó.

**Pill là một-trong-N, và chỉ thế** (M100.36 §4N). Một lệnh đứng cạnh nhóm pill
— nút mở sheet lọc tag của danh sách thẻ — là `MxActionButton` compact
secondary, không phải pill mang `isSelected` nó không có: năm node semantics
giống hệt nhau trong một hàng, bốn cái loại trừ nhau và một cái toggle độc lập,
không nói cho screen reader biết cái nào là cái nào (#434 P1-1). Nhóm pill tự
giới thiệu (`Semantics(container, label)`) trước các lựa chọn của nó (§11F).

**Badge không phải chip.** `MxBadge` là `Container` — không focus, không press,
không selected, không target — cho một từ trên nền `surfaceMuted`; ba feature
từng tự viết đúng recipe này (due label của card row, tag chỉ đọc). Badge mang
*trạng thái* (overdue, recommended, imported) giữ container riêng cạnh hàng của
nó và không gộp vào (#434 §17).

---

## 6. FilledButton state — đã đóng ở M100.36

**Trạng thái: ĐÓNG.** Button theme nay canonical với `_FilledButtonDefaultsM3`
ở cả ba slot (background, foreground, overlay), guard AST ghim từng nhánh của
`MxFilledPair`.

Hồ sơ, vì đây là về **bảng dịch này**: dòng §2 từng ghi sai lệch FilledButton
overlay là một **thay thế** (`onPrimary` → blend về `onSurface`), trong khi code
thực hiện một **phép cộng** — `buildSharedButtonStyle` đặt `overlayColor:
controlOverlay` (`primary` @ 6/10/12%) và `buildFilledStyle` chỉ `copyWith`
`backgroundColor` (lerp về `onSurface`), nên hover/press vẽ *cả hai*. Trên
`primary` overlay là no-op và còn triệt tiêu một phần blend (press ΔE 2.08 so
với M3 5.74); trên `error` nó phủ indigo lên đỏ và xoay hue 345.7° → 338.5°.
Chi tiết đo ở [`docs/reviews/mx-action-button-deep-audit.md`](../reviews/mx-action-button-deep-audit.md)
(#432).

Cách đóng: **một cơ chế, và là của Material** — fill giữ nguyên role ở mọi state
enabled; hover/focus/press là state layer màu `on` của chính cặp
(`MxFilledPair.stateLayerOf`) ở alpha SDK (`AppStateOpacity.stateLayer*` =
0.08/0.10/0.10). Hai token blend (`filledHoverBlend`, `filledPressedBlend`) gỡ,
không có consumer. Ring focus của filled button giữ lại vì
`_FilledButtonDefaultsM3` không khai `side` (slot trống) và wash 10% đo 1.29:1
trên fill — dưới sàn 3:1 của 1.4.11; `focus_ring_contrast_test.dart` ghim cả hai
nửa. Composite dưới ngón tay được đo ở
`mx_action_button_composite_state_test.dart`: ΔL\* 2.5–12, hue không xoay quá 4°.

---

## 7. Ranh giới hàng — `MxListTile` / `MxCard` / hàng thuộc feature

Không có một đáp án chung "mọi thứ là Card" hay "mọi thứ là ListTile"
(M100.36 §4H). Ranh giới là **ngữ nghĩa**, không phải mật độ:

| Dựng bằng | Khi | Ví dụ production |
|---|---|---|
| `MxListTile` | hàng điều hướng / thiết lập / điều khiển / lựa chọn thông thường — một tiêu đề, một dòng phụ, glyph hai bên, một cú chạm | mục Reminders trong Settings, giờ nhắc, đích di chuyển / khôi phục, chọn chế độ / hướng học |
| `MxCard` | một **thực thể** hoặc **mặt nội dung** mà nhóm và độ sâu của chính nó mang nghĩa | deck tile, card tile, mặt học, panel tóm tắt |
| hàng thuộc feature | **chỉ khi** composition thật sự vượt quá ngữ nghĩa ListTile — vùng thứ ba trở lên, lưới số liệu, thân là widget, control lồng bên trong | `deck_tile_widget` (bốn vùng + nút Study), `progress_deck_row_widget` (tên + đường dẫn **+ lưới bốn số liệu**), `search_result_shell_widget` (thân là widget của từng loại kết quả) |

Hai ứng viên #431 nêu để "đơn giản hoá" đã được xét theo quy tắc này và **ở
lại Card**: hàng Progress mang một lưới số liệu dưới tiêu đề, và vỏ kết quả
tìm kiếm nhận một `child` widget — cả hai vượt quá `String title / subtitle`.
Không có caller nào đang vi phạm ranh giới; không di trú hàng loạt.

Kèm theo, cho hàng:

- **Trailing của `MxListTile` chỉ trình bày** (§4K): chevron, số đếm, glyph.
  Control tự hành động — switch, checkbox, radio — là `MxSwitchRow`,
  `MxCheckboxRow`, `MxRadioRows`.
- **Chọn không đổi typography** (§4L): fill `surfaceSelected` + title
  `primary` + glyph; subtitle giữ mực phụ. Semibold-khi-chọn của kit
  (`mx.css:205`) bị từ chối vì nó reflow.
- **Một ngữ pháp semantics cho mỗi loại chọn** (§10E): chọn-một →
  `selected` + `inMutuallyExclusiveGroup` (`MxListTile.isSelected` non-null,
  `MxRadioRows`); chọn-nhiều → `checked` (`MxCheckboxRow`, hàng trash);
  điều hướng → `button`, không có selection. Card thực thể chọn-nhiều giữ
  `MxCard` tint + mark (card tile), hàng chọn-nhiều giữ `MxPressable` + glyph
  (trash) — hai ngữ pháp cho hai loại bề mặt, mỗi ngữ pháp một recipe.
- **Một ngôn ngữ phân cách** (§10H): `Divider` của theme — `outlineVariant`,
  một hairline, không chừa khoảng. Khoảng cách thuộc layout (`SizedBox` /
  `Padding`), độ dày thuộc stroke. `borderDivider` gỡ ở M100.36 (không
  consumer; ở light nó *là* màu trang). Khoảng cách giữa các card trong một
  danh sách là quyết định của feature trên thang `AppSpacing` (sm / md / lg
  tuỳ mật độ màn), không phải của theme.
- **Một danh sách quyết định leading một lần**: trộn hàng có glyph dẫn và hàng
  không có trong cùng một danh sách làm cột chữ nhảy 40dp. Không có danh sách
  production nào trộn; ghi làm quy tắc.

---

## 8. Focus — một câu trả lời mỗi họ (M100.36 §12)

Kiểm kê chéo sau khi bốn họ đóng. Mỗi control có **đúng một** chỉ báo bàn phím,
và chỉ báo đó là `AppInteractionStates.focusIndicator` (`primary`, `AppStroke.focus`)
hoặc — với nút filled — `focusIndicatorOf(label)` vì `primary` trên `primary`
là vô hình. Không control nào có hai vòng, và không control nào chỉ có wash.

| Họ | Cơ chế | Lớp | Gate `traditional` | Đo |
|---|---|---|---|---|
| FilledButton (`MxActionButton` primary/destructive) | `ButtonStyle.side` = `focusIndicatorOf(label)` | ngoài fill, không đổi kích thước | SDK (`ButtonStyleButton` chỉ nhận `focused` từ bàn phím) | `focus_ring_contrast_test` ≥ 3:1 trên fill |
| OutlinedButton / TextButton (`MxActionButton` secondary, `MxTextButton`) | `ButtonStyle.side` = `focusIndicator(scheme)` | thay hairline khi focus | SDK | cùng test |
| IconButton (`MxIconButton`, `MxMenuButton`) | `iconButtonTheme.side` khi focused | ngoài | SDK | cùng test |
| FAB | `focusColor` (wash `onPrimaryContainer`) + shape | SDK | SDK | chấp nhận: FAB là control duy nhất trên màn của nó |
| ChoiceChip (`MxPillButton`) | `MxFocusRing` quanh **hình vẽ**; SDK `focusColor` wash bên trong | ngoài, target 48 nới ngoài ring | `MxFocusRing` (`addHighlightModeListener`) | `mx_pill_button_focus_test`: rect ring == rect Material |
| `MxListTile` (interactive) | `MxFocusRing`; SDK wash `rowOverlay(focused)` | ngoài | `MxFocusRing` | `mx_list_tile_test` |
| `MxPressable` | `MxFocusRing` theo shape | ngoài | `MxFocusRing` | `mx_pressable_test` |
| `MxCard` (actionable) | ring riêng của card (#435, **bảo vệ**) — cùng `focusIndicator` | additive | gate riêng, cùng cơ chế | `mx_card_*` |
| TextField / `MxTextField` | `focusedBorder` `primary` @ `AppStroke.focus` (focused-error: `error` cùng width) | chính viền | SDK | `m3_combined_state_test` |
| `MxSearchField` | viền `outline` → `primary` @ `AppStroke.input` | chính viền | SDK | `mx_search_field_test` |
| Switch / Checkbox / Radio (`MxSwitchRow`, `MxCheckboxRow`, `MxRadioRows`) | overlay của control (`app_toggle_themes.dart`) — SDK vẽ vòng 40dp quanh thumb/box | trên control, không trên hàng | SDK | `app_toggle_themes_test` |

**Hàng không interactive không có ring** — `MxListTile` không `onTap` là
`ExcludeFocus`. **Không caller nào tự vẽ** `Border` cho focus ngoài các file ở
bảng; `grep -rn "WidgetState.focused" lib/features` phải rỗng.
