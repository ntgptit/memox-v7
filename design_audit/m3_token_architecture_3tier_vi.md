# Kiến trúc token M3 ba tầng — hiện trạng trong codebase

Tài liệu mô tả **cái đang chạy** trong `lib/core/theme/**` (22 file), lập ngày
2026-08-21. Chỉ báo cáo, không đề xuất. Mỗi token ghi kèm `file:dòng` nơi định
nghĩa. Giá trị hex là giá trị thực trong code, không suy diễn.

---

## Tầng 1 — Reference (ref palette)

**Không có tonal palette.** Dự án **không** dùng bảng tone 0–100 cho bất kỳ
palette nào (primary/secondary/tertiary/neutral/neutral-variant/error). Nguồn
màu là **bảng hex viết tay**, mỗi màu hai giá trị (light/dark), tinh chỉnh bằng
tay theo OKLCH (L\*, hue ~285, chroma 0.06–0.074 cho thang surface dark — ghi
trong doc comment `app_colors.dart:30-41`).

- **Seed**: `AppColors.seed = primaryLight = #4646B4`
  (`lib/core/theme/app_colors.dart:53`).
- `ColorScheme.fromSeed(seedColor: AppColors.seed)` **có** được gọi
  (`app_theme.dart:34`, `app_theme.dart:100-103`) nhưng chỉ để thỏa constructor
  — **toàn bộ ~40 role bị override** ngay bằng `copyWith`. Không truyền
  `dynamicSchemeVariant` (dùng mặc định của SDK); kết quả sinh từ seed không
  bao giờ được render.
- Lớp hằng gốc gồm hai file:
  - `AppColors` (`app_colors.dart`) — màu mang nghĩa riêng của memox.
  - `AppMaterialRoles` (`app_material_roles.dart`) — các slot M3 khai báo chỉ
    để `fromSeed` không tự sinh (comment dòng 13-19 ghi lý do: fromSeed từng
    sinh tertiary hồng, thang container xám, đỏ thứ hai).
- Phía CSS kit (`design_system/tokens/colors.css:12-33`) có lớp literal
  `--mx-*` (page/card/inset/raised/ink/line/indigo/success/…) — cũng là hai
  giá trị light/dark mỗi màu, không phải tonal palette.

---

## Tầng 2 — System (semantic roles)

### 2.1 Role chuẩn M3 — ánh xạ role → giá trị

Nguồn ánh xạ: `buildLightTheme()` (`app_theme.dart:33-97`) và
`buildDarkTheme()` (`app_theme.dart:99-167`). Cột "Định nghĩa" là nơi hằng hex
nằm; `AC` = `app_colors.dart`, `MR` = `app_material_roles.dart`.

| Role M3 | Light | Dark | Định nghĩa (light / dark) |
|---|---|---|---|
| primary | `#4646B4` | `#5656C9` | AC:201 / AC:202 |
| onPrimary | `#FFFFFF` | `#FFFFFF` | AC:203 / AC:204 |
| primaryContainer | `#DCDCF2` | `#2B2B6E` | MR:45 / MR:46 |
| onPrimaryContainer | `#1B1B5C` | `#D7D5FF` | MR:47 / MR:51 |
| primaryFixed | `#DCDCF2` | `#DCDCF2` | = primaryContainerLight (app_theme.dart:77/143) |
| primaryFixedDim | `#DCDCF2` | `#DCDCF2` | = primaryContainerLight (app_theme.dart:78/144) |
| onPrimaryFixed | `#1B1B5C` | `#1B1B5C` | = onPrimaryContainerLight (app_theme.dart:79/145) |
| onPrimaryFixedVariant | `#4646B4` | `#4646B4` | = primaryLight (app_theme.dart:80/146) |
| secondary | `#4E5468` | `#B8B7D0` | MR:53 / MR:60 |
| onSecondary | `#FFFFFF` | `#1E2033` | MR:61 / MR:62 |
| secondaryContainer | `#E4E6EC` | `#332F58` | MR:63 / MR:64 |
| onSecondaryContainer | `#2C3141` | `#D9DCE7` | MR:65 / MR:66 |
| secondaryFixed / FixedDim | `#E4E6EC` | `#E4E6EC` | = secondaryContainerLight (app_theme.dart:81-82/147-148) |
| onSecondaryFixed | `#2C3141` | `#2C3141` | app_theme.dart:83/149 |
| onSecondaryFixedVariant | `#4E5468` | `#4E5468` | app_theme.dart:84/150 |
| tertiary | `#45647F` | `#8DB4D8` | MR:68 / MR:73 |
| onTertiary | `#FFFFFF` | `#17232E` | MR:74 / MR:75 |
| tertiaryContainer | `#E1E9F0` | `#33465A` | MR:76 / MR:77 |
| onTertiaryContainer | `#22394B` | `#D5E0EA` | MR:78 / MR:79 |
| tertiaryFixed / FixedDim | `#E1E9F0` | `#E1E9F0` | app_theme.dart:85-86/151-152 |
| onTertiaryFixed / FixedVariant | `#22394B` / `#45647F` | như light | app_theme.dart:87-88/153-154 |
| error | `#C02B3A` | `#F2808F` | AC:262 / AC:263 (`= danger`, app_theme.dart:52/116) |
| onError | `#FFFFFF` | `#2C1319` | MR:81 / MR:82 |
| errorContainer | `#F8DDE1` | `#5E2831` | MR:83 / MR:84 |
| onErrorContainer | `#641421` | `#F5D3D8` | MR:85 / MR:86 |
| surface | `#FBFBFE` | `#1A1838` | AC:85 / AC:86 |
| onSurface | `#16182B` | `#EDEDF6` | AC:107 / AC:108 (`textPrimary`) |
| onSurfaceVariant | `#565C72` | `#A8A7C4` | AC:109 / AC:110 (`textSecondary`) |
| surfaceDim | `#DEE0E7` | `#0B0327` | MR:105 / MR:106 |
| surfaceBright | `#FCFCFE` | `#37345F` | MR:107 / MR:108 |
| surfaceContainerLowest | `#FCFCFE` | `#0A0326` | MR:88 / MR:96 |
| surfaceContainerLow | `#FAFAFC` | `#151134` | MR:97 / MR:98 |
| surfaceContainer | `#F1F2F6` | `#221E44` | MR:99 / MR:100 |
| surfaceContainerHigh | `#EAECF1` | `#28254B` | MR:101 / MR:102 |
| surfaceContainerHighest | `#E3E5EC` | `#332F58` | MR:103 / MR:104 |
| outline | `#D2D2DD` | `#4C487A` | AC:152 / AC:158 (`borderSubtle`, app_theme.dart:66/130) |
| outlineVariant | `#D2D2DD` | `#4C487A` | **cùng giá trị `borderSubtle`** (app_theme.dart:67/131) |
| inverseSurface | `#2A2C3E` | `#E7E8F0` | MR:110 / MR:111 |
| onInverseSurface | `#F1F2F6` | `#23253A` | MR:112 / MR:113 |
| inversePrimary | `#A9A9E0` | `#3A3A9B` | MR:114 / MR:115 |
| shadow | `#0B0C18` | `#04040B` | AC:350 / AC:351 |
| scrim | `#0B0C18` | `#04040B` | AC:352 / AC:353 (= shadow) |
| surfaceTint | `#4646B4` (= primary) | `#37345F` (= surfaceElevatedDark) | app_theme.dart:71 / app_theme.dart:137 |
| ~~background / onBackground / surfaceVariant~~ (deprecated) | không set | không set | không đọc ở đâu trong `lib/` |

Ghi chú đọc kèm code:

- Nền trang (scaffold) **không phải** `scheme.surface`: `scaffoldBackgroundColor
  = AppColors.backgroundLight/Dark` (`#F4F5F8` / `#0A082D`, AC:69-70), truyền
  qua tham số `background` của `_buildTheme` (`app_theme.dart:93/159, 200`).
  Màu trang nằm **ngoài** `ColorScheme`.
- Họ `*Fixed` cả hai theme đều nhận giá trị container **light** (comment
  app_theme.dart:72-76: "brightness-independent by definition"); `*FixedDim`
  trùng hệt `*Fixed`.

### 2.2 Role không dùng tới (không có consumer ngoài khối build theme)

Kiểm bằng grep toàn `lib/` (loại trừ `lib/core/theme/`):

- **Không widget/theme nào đọc**: `surfaceDim`, `surfaceBright`,
  `surfaceContainer` (bậc giữa), `inversePrimary`, và **toàn bộ 12 role họ
  `*Fixed`**.
- **Chỉ dùng qua component theme, không widget nào đọc trực tiếp**:
  `inverseSurface`/`onInverseSurface` (SnackBar `app_theme.dart:381-390`,
  Tooltip `app_overlay_themes.dart:89-101`), `surfaceContainerHighest`
  (linear track, `app_overlay_themes.dart:62`), `shadow` (`shadowsFor`,
  `app_elevation.dart:53`), `scrim` (`modalBarrierColor`,
  `app_overlay_themes.dart:36-38`), `surfaceTint` (bị vô hiệu — mọi component
  set `surfaceTintColor: transparent`).
- Các role còn lại đều có widget đọc trực tiếp qua `context.colors.*`
  (primary/secondary/tertiary + container, error*, surface, onSurface,
  onSurfaceVariant, surfaceContainerLowest/Low/High, outline qua theme).

### 2.3 Role tự thêm ngoài chuẩn M3

**Cơ chế mở rộng: cả hai.**

1. Lớp hằng tĩnh: `AppColors`, `AppMaterialRoles` (compile-time const).
2. `ThemeExtension<AppSemanticColors>` — class `AppSemanticColors`
   (`app_semantic_colors.dart:11`), đăng ký tại `app_theme.dart:202`
   (`extensions: [semantic]`), hai constructor `.light()` (:33) / `.dark()`
   (:53), có `copyWith` (:138) và `lerp` đầy đủ (:187).
   **Truy cập ở widget**: `context.semanticColors`
   (`theme_context_extension.dart:21-30`) — **throw** nếu extension chưa đăng
   ký, không fallback. Kèm `context.colors` (ColorScheme, :11) và
   `context.texts` (:13).

18 role trong extension (giá trị gốc ở `app_colors.dart`, lý do lấy từ doc
comment trong code):

| Token | Light | Dark | Định nghĩa | Lý do tồn tại (theo comment) |
|---|---|---|---|---|
| primaryAccent | `#4646B4` | `#8A8AE0` | AC:214/215 | Brand làm **chữ/link**: `primary` dark chỉ đạt 3.33:1 làm text trần, fail AA — token này là biến thể đọc được (AC:206-213) |
| streakContainer | `#FBEBD7` | `#342C4B` | AC:310/311 | Nền due chip trên deck card; dark rời họ màu ấm vì olive trên nền tím "đọc như vết bẩn" (AC:285-298) |
| onStreakContainer | `#7A4A10` | `#E0B064` | AC:312/317 | Label của due chip; giá trị light **tự dẫn xuất** vì `--color-streak` của design chỉ đạt 3.12:1 trên container (AC:300-308) |
| progressTrack | `#DFE0E9` | `#2E3247` | AC:278/279 | Phần chưa lấp của progress bar (AC:265-275: họ riêng, không dùng accent để bar không lẫn với nút) |
| progressFill | `#6E6ECE` | `#8A8AE0` | AC:282/283 | Phần đã lấp, dưới 100%; 100% chuyển sang `success` (comment `app_semantic_colors.dart:78-79`) |
| success | `#10795C` | `#4FC79B` | AC:254/255 | "Answer remembered, session completed, saved" |
| warning | `#9A6A11` | `#E0B064` | AC:258/259 | "Card due soon, streak at risk — informative, not alarming" |
| danger | `#C02B3A` | `#F2808F` | AC:262/263 | "Answer forgotten, destructive action, reset"; cũng chính là `scheme.error` |
| info | `#3F6E97` | `#8DB4D8` | AC:321/322 | "Status genuinely carrying information: streak, counters, 3 of 20" |
| surfaceMuted | `#EAECF1` | `#28254B` | AC:89/90 | "Inset tile, chip, icon container" — một bậc trên card |
| surfaceElevated | `#FCFCFE` | `#37345F` | AC:97/98 | Đỉnh thang surface: bề mặt nâng/được chọn |
| borderAccent | `#B6B6E2` | `#31306F` | AC:150/156 | Hairline cho panel là "câu trả lời" của màn hình (Today card ở Library); brand blend 38% trên surface, resolve sẵn thay vì translucent (AC:140-149, rule R7) |
| borderSubtle | `#D2D2DD` | `#4C487A` | AC:152/158 | Hairline giữa row, quanh card, input lúc nghỉ |
| borderControl | `#8D8D95` | `#66628D` | AC:163/164 | Viền control đạt 3:1 theo WCAG 1.4.11 — khi viền là thứ duy nhất nói "chỗ này bấm/gõ được" (`app_semantic_colors.dart:107-120`) |
| focusRing | `#4141C0` | `#8A8AE0` | AC:168/169 | Focus đổi **hue**, không đổi độ dày stroke (AC:166-167) |
| secondaryAction | `#454B5E` | `#C3C6D2` | AC:225/226 | Label nút outlined; trung tính có chủ đích để không cạnh tranh với cặp verdict học (AC:217-224) |
| disabledSurface | `#E0E0E5` | `#33324F` | AC:181/182 | Fill + viền control disabled, solid theo rule R7 (không composite lúc paint) (AC:171-180) |
| onDisabled | `#16182B @38%` | `#EDEDF6 @38%` | AC:188/189 | Label/glyph disabled; translucent vì có 3 nền khả dĩ (AC:186-187) |

Ngoài extension còn 2 hằng tĩnh không vào theme: `webLetterbox = #6E7288`
(AC:336, viền web build) và `AppColors.seed` (AC:53).

**Token trạng thái học tập (overdue / due / new / mastery / caught-up):
KHÔNG CÓ token màu riêng.** Cụ thể:

- 4 trạng thái hiển thị của card map vào token sẵn có qua
  `cardStateColor` (`lib/features/card/presentation/widgets/support/card_state_widget.dart:22-30`):
  `isNew → info`, `beginning → warning`, `reviewing → primaryAccent`,
  `mastered → success`. Comment dòng 16-19 ghi rõ: "Existing semantic tokens,
  not four new ones".
- "Due" (chip số thẻ chờ trên deck) dùng cặp `streakContainer` /
  `onStreakContainer`.
- Không tồn tại token nào tên `overdue` hay `caughtUp` trong `lib/`
  (grep xác nhận; các hit "overdue" nằm ở domain model của feature reminder,
  không phải màu).

---

## Tầng 3 — Component

Tất cả khai báo trong `_buildTheme` (`app_theme.dart:169-392`) và các file
`app_*_theme(s).dart`. Quy ước dưới đây: `scheme.*` = ColorScheme,
`semantic.*` = AppSemanticColors.

### Nhóm ưu tiên (màn Library)

**FilledButtonTheme** (`app_theme.dart:283-288` → `app_button_themes.dart:63-77, 106-141`)

| Slot | Giá trị |
|---|---|
| fill (rest) | `actionFill` = `scheme.primary` (truyền từ app_theme.dart:94/164) |
| label (rest) | `actionLabel` = `scheme.onPrimary` |
| fill hovered/pressed | `Color.lerp(fill → scheme.onSurface)` 6% / 12% — **blend, không overlay** (`AppStateOpacity.filledHover/PressedBlend`, app_button_themes.dart:114-134) |
| disabled | fill `semantic.disabledSurface`, label `semantic.onDisabled` (:113, :137) |
| geometry | minSize 64×`AppSpacing.minimumTouchTarget`, padding `AppSpacing.xl/md`, radius `AppRadius.md`, overlay `AppInteractionStates.controlOverlay` (:41-60) |
| biến thể tonal | `buildFilledTonalStyle` (:87-95): fill `scheme.secondaryContainer`, label `scheme.onSecondaryContainer` — áp tại widget, không chiếm slot theme |

**OutlinedButtonTheme** (`app_theme.dart:290-294` → `app_button_themes.dart:230-256`)

| Slot | Giá trị |
|---|---|
| label | `outlineLabel` = `semantic.secondaryAction` (app_theme.dart:96/166) |
| side rest | `semantic.borderSubtle` (:253) |
| side focused | `AppInteractionStates.focusRing` = `semantic.focusRing` @ `AppStroke.focus` (:249-251) |
| disabled | label `semantic.onDisabled`, side `semantic.disabledSurface` (:237, :242-244) |

**TextButtonTheme** (`app_theme.dart:296` → `app_button_themes.dart:203-227`)

| Slot | Giá trị |
|---|---|
| foreground/icon | `textLinkForeground(accent: semantic.primaryAccent)` — rest = accent, hover/pressed = lerp về `scheme.onSurface` 15%/28%, disabled = `semantic.onDisabled` (:152-174) |
| padding | `EdgeInsets.zero`; minSize `0×48`; overlay `Colors.transparent`; `NoSplash` (:215-222) |

**CardTheme** (`app_theme.dart:263-271`)

| Slot | Giá trị |
|---|---|
| color | `scheme.surface` |
| elevation | `0` |
| shape | radius `AppRadius.lg`, side `semantic.borderSubtle` |
| ghi chú | đây là lưới an toàn cho `Card` trần; card thật của app là `MxCard` tự vẽ (focus-ring swap + `shadowsFor` không có slot trong `CardThemeData`) — comment :258-262 |

**AppBarTheme** (`app_theme.dart:228-236`)

| Slot | Giá trị |
|---|---|
| backgroundColor | `background` (= màu trang, không phải `scheme.surface`) |
| foregroundColor | `scheme.onSurface` |
| scrolledUnderElevation / elevation | `0` / `0`; `centerTitle: false` |

**NavigationBarTheme** (`app_theme.dart:256` → `app_navigation_bar_theme.dart:11-50`)

| Slot | Giá trị |
|---|---|
| backgroundColor | `background` (màu trang — bar cùng khung với app bar) |
| indicatorColor | `scheme.primaryContainer` (:21) |
| icon/label selected | `brandInk(scheme)` = light: `scheme.primary`, dark: `scheme.onPrimaryContainer` (`app_material_roles.dart:40-42`); label thêm w600 |
| icon/label unselected | `scheme.onSurfaceVariant` |
| surfaceTintColor / elevation | `transparent` / `0`; label luôn hiện (:43-50) |

**FloatingActionButtonTheme** (`app_theme.dart:248-255`)

| Slot | Giá trị |
|---|---|
| background / foreground | `scheme.primary` / `scheme.onPrimary` |
| elevation (mọi trạng thái) | `AppElevation.overlay` (= 8) |

**ChipTheme** (`app_theme.dart:281` → `app_chip_theme.dart:142-216`)

| Slot | Giá trị |
|---|---|
| fill rest | selected: `scheme.primaryContainer`, unselected: `scheme.surface` (:46-47) |
| fill hover/focus/press | `Color.alphaBlend(scheme.primary @ 6%/10%/12%, fill nghỉ)` — solid hoá theo R7 (:55-78) |
| fill disabled | `disabledSurfaceTint(scheme, over: resting)` = blend `onSurface` 12% (:61-63; hàm ở app_button_themes.dart:31-35) |
| label | `WidgetStateColor`: disabled `semantic.onDisabled`, selected `brandInk`, else `scheme.onSurfaceVariant`; weight **w500** ghi đè label-lg w600 (:87-140) |
| side | disabled `disabledSurfaceTint`, focused `focusRing`, selected `scheme.primary`, else `semantic.borderSubtle` (:152-173) |
| shape / padding | `StadiumBorder` (giữ pill, không dùng `AppRadius.sm` — :174-179); `labelPadding: zero`, padding ngang `AppSpacing.md`, dọc `(32−20)/2 = 6` (:195-215, hằng cục bộ :222-227) |

**ProgressIndicatorTheme** (`app_theme.dart:330` → `app_overlay_themes.dart:53-63`)

| Slot | Giá trị |
|---|---|
| color | `semantic.focusRing` — **không phải** `primary` (đo: primary dark 2.81:1 dưới sàn 3:1, comment :42-52) |
| circularTrackColor | `Colors.transparent` |
| linearTrackColor | `scheme.surfaceContainerHighest` |

### Các theme còn lại (tóm tắt)

- **InputDecorationTheme** (`app_input_theme.dart:20-58`): outlined không fill;
  border rest/enabled `semantic.borderControl`, focused `semantic.focusRing`,
  error `semantic.danger`, disabled = blend `borderControl @50%` trên surface;
  stroke `AppStroke.input` (1.5) mọi trạng thái; hint `scheme.onSurfaceVariant`.
- **IconButtonTheme** (`app_theme.dart:303-328`): fg `scheme.onSurfaceVariant`,
  disabled `semantic.onDisabled`, overlay `AppInteractionStates.iconOverlay`,
  focus vẽ ring `semantic.focusRing`, minSize 48².
- **ListTileTheme** (`app_theme.dart:337-350`): icon `onSurfaceVariant`, text
  `onSurface`, selected `primary`, selectedTile `semantic.surfaceMuted`.
- **DialogTheme / BottomSheetTheme** (`app_theme.dart:352-379`): nền
  `scheme.surface`, barrier `modalBarrierColor` (= `scrim` @ 0.72 dark / 0.48
  light, `app_overlay_themes.dart:36-38`), `surfaceTintColor: transparent`,
  elevation 0, viền/drag-handle `semantic.borderSubtle`.
- **SnackBarTheme** (`app_theme.dart:381-390`): `inverseSurface` /
  `onInverseSurface`, floating, radius `AppRadius.md`.
- **Tooltip / TextSelection / Divider / Scrollbar / Radio**
  (`app_overlay_themes.dart:89-142`, `app_radio_theme.dart`): tooltip
  `inverseSurface` + `labelMedium`; caret & handle `semantic.focusRing`,
  selection `primary @ 0.24`; divider `borderSubtle` @ `AppStroke.hairline`;
  scrollbar `onSurfaceVariant @ 0.4`, dày 4.
- **Fallback framework** (`app_theme.dart:212-226`): `hoverColor`
  (`onSurfaceVariant @ hoverRow`), `focusColor`/`highlightColor`/`splashColor`
  (`primary` @ focus/pressed), `iconTheme` (`onSurfaceVariant`, `AppIconSize.md`)
  — để widget không được theme hoá vẫn rơi về token của app.

### Hardcode tại widget (phần được soi kỹ nhất)

Kết quả quét toàn `lib/` ngoài `lib/core/theme/`:

- **Màu:** **0** literal `Color(0x…)` / `Color.fromARGB` / `Color.fromRGBO`;
  Material `Colors.*` duy nhất là `Colors.transparent`. Một chỗ duy nhất sửa
  alpha token tại widget:
  `lib/features/study/presentation/widgets/items/match_tile_widget.dart:255`
  (`semantic.borderControl.withValues(...)` — overlay, thuộc diện miễn trừ R7).
- **Ngoại lệ có chủ đích:** `lib/app/error_screen_widget.dart` đọc thẳng hằng
  `AppColors` (không qua `Theme.of`) vì render được cả khi cây widget phía trên
  `MaterialApp` đã chết (comment :~125-133); đồng thời file này **hardcode**
  `fontSize: 20` (:85), `fontSize: 14` (:94), `EdgeInsets.all(24)` (:78),
  `SizedBox(height: 12)` (:89) — các số ngoài thang token, chỉ ở màn hình này.
- **Padding/radius/fontSize ở features + shared:** không tìm thấy literal nào
  ngoài hệ — mọi `EdgeInsets` đi qua `AppSpacing` hoặc
  `mxScreenGutter(context)` (`lib/shared/widgets/mx_content_shell.dart:308-311`
  — compact: `AppSpacing.md`, còn lại `AppSpacing.lg`); không có
  `BorderRadius.circular(<số>)`, không có `fontSize: <số>`.
- **Literal nằm trong theme layer** (được phép ở đó, liệt kê để đầy đủ):
  alpha 0.24 (selection, `app_overlay_themes.dart:113`), 0.4 + thickness 4
  (scrollbar :138-141), 0.5 (disabled input border, `app_input_theme.dart:47`),
  0.72/0.48 (barrier :37), chip `_containerHeight 32` / `_labelLineHeight 20`
  (`app_chip_theme.dart:222-227`), shadow alpha `0.06 + 0.01·level`
  (`app_elevation.dart:64`).

---

## Ngoài màu

### Typography (`app_typography.dart`)

- **Scale M3 chuẩn về danh pháp** (display→label, đủ 15 rung,
  `buildTextTheme` :157-266), **giá trị tự khai báo tường minh** — size/height/
  tracking được ghi cứng thay vì thừa hưởng default của SDK (lý do: comment
  :113-120, chống trôi khi bump SDK).
- **Font family**: display = `PlusJakartaSans` (:26), body/UI = `Inter` (:27),
  fallback CJK `NotoSansKR → NotoSansJP → NotoSansSC` (:64-73) trên mọi style.
  Variable font — weight set qua `fontVariations` song song `fontWeight`
  (:91-93, :108-109).

| Style | Face | Size | Weight | Height | Tracking |
|---|---|---|---|---|---|
| displayLarge | Jakarta | 57 | w700 | 64/57 | 0 |
| displayMedium | Jakarta | 45 | w700 | 52/45 | 0 |
| displaySmall | Jakarta | 36 | w600 | 44/36 | 0 |
| headlineLarge | Jakarta | 32 | w600 | 40/32 | 0 |
| headlineMedium (card prompt) | Jakarta | 30 (`cardPromptSize` :77) | w600 | 1.22 | −0.5 |
| headlineSmall | Jakarta | 24 | w600 | 32/24 | 0 |
| titleLarge | Jakarta | 22 | w600 | 28/22 | 0 |
| titleMedium | Inter | 16 | w600 | 24/16 | 0.15 |
| titleSmall | Inter | 14 | w600 | 20/14 | 0.1 |
| bodyLarge | Inter | 16 | w400 | 24/16 | 0.5 |
| bodyMedium | Inter | 14 | w400 | 1.45 | 0.25 |
| bodySmall | Inter | 12 | w400 | 16/12 | 0.4 |
| labelLarge | Inter | 14 | **w600** (M3: w500) | 20/14 | 0.1 |
| labelMedium | Inter | 12 | w500 | 16/12 | 0.5 |
| labelSmall | Inter | 11 | w500 | 16/11 | 0.5 |

Lệch so với M3 mặc định: `labelLarge` w600 (chủ đích, cho label trên fill;
chip hạ về w500 riêng — `app_chip_theme.dart:102-122`), `headlineMedium`
30/1.22/−0.5 (card prompt), `bodyMedium` height 1.45. Token phụ:
`compactCardPromptSize = 26` (:82), `sectionLabelTracking = 1.1` (:88).

### Shape (`app_radius.dart`)

Không dùng danh pháp M3 (extraSmall→extraLarge); thang riêng 5 bậc:

| Token | Giá trị | Dùng cho | Dòng |
|---|---|---|---|
| sm | 8 | chip/badge nhỏ, tooltip, scrollbar | :7 |
| md | 12 | button, input, ListTile, SnackBar | :10 |
| lg | 16 | card, sheet, dialog | :13 |
| xl | 20 | riêng study card | :21 |
| pill | 999 | control dạng pill | :24 |

Ngoài hệ: `StadiumBorder` cho chip (tương đương pill, `app_chip_theme.dart:179`).
Không tìm thấy radius hardcode trong widget.

### Spacing (`app_spacing.dart`)

Có thang tập trung, 6 bậc + 1 sàn; comment :50-52 ghi `scale` tồn tại để test
khẳng định thang không tự mọc thêm bậc:

| Token | Giá trị | Dòng |
|---|---|---|
| xs / sm / md / lg / xl / xxl | 4 / 8 / 12 / 16 / 24 / 32 | :33-48 |
| minimumTouchTarget (sàn, không thuộc scale) | 48 | :59 |

Gutter màn hình: `mxScreenGutter` = `md` khi bề rộng < 360
(`AppBreakpoints.compact`, `app_breakpoints.dart:22`), ngược lại `lg`.

### Elevation (`app_elevation.dart`)

| Token | dp | Dòng | Ghi chú |
|---|---|---|---|
| none | 0 | :17 | mặc định |
| card | 1 | :20 | card trong list |
| raised | 3 | :25 | **chưa có caller** (comment ghi rõ) |
| overlay | 8 | :28 | sheet/dialog/FAB |

Paint qua `shadowsFor(level, scheme)` (:53-68): **dark không vẽ shadow**
(đo ΔL\* 0.26 — không nhìn thấy), light một `BoxShadow` duy nhất, alpha
`0.06 + 0.01·level`, blur `3·level`, offset `(0, level)`. Các component theme
đều set `elevation: 0` và tự vẽ qua `shadowsFor` (trừ FAB dùng dp 8 của
Material).

Phụ: motion `AppDurations` (fast 120 / normal 200 / slow 320 ms, curve
`Cubic(0.2,0,0,1)` và `Cubic(0,0,0,1)` — `app_durations.dart:9-30`); icon
`AppIconSize` 16/24/20/40 (:9-18); stroke `AppStroke` hairline 1 / input 1.5 /
focus 2 (:18-28).

---

## Lệch chuẩn

### 1. Token bị bỏ qua / hardcode trực tiếp trong widget

- `lib/app/error_screen_widget.dart` — hardcode `fontSize: 20`, `fontSize: 14`,
  `EdgeInsets.all(24)`, `SizedBox(height: 12)`; màu đọc thẳng `AppColors`
  không qua theme. Có chủ đích (render khi theme chết), nhưng là điểm duy nhất
  chữ và khoảng cách nằm ngoài token.
- `match_tile_widget.dart:255` — widget tự sửa alpha của `borderControl`
  (`withValues`) thay vì dùng token resolve sẵn.
- Không còn trường hợp nào khác: 0 màu literal, 0 padding/radius/fontSize
  literal trong `lib/features/` + `lib/shared/`.

### 2. Role M3 gán lệch ngữ nghĩa

- **`outline` == `outlineVariant` == `borderSubtle`** (`app_theme.dart:66-67/
  130-131`): cặp hai bậc của M3 bị gộp về một giá trị, và là bậc *yếu*
  (1.45:1 light / 2.04:1 dark trên surface). Stroke 3:1 mà M3 kỳ vọng ở
  `outline` tồn tại trong kit dưới tên `borderControl` nhưng nằm **ngoài**
  `ColorScheme` — component bên thứ ba đọc `scheme.outline` sẽ nhận hairline
  trang trí.
- **`surfaceTint` dark = `surfaceElevatedDark`** thay vì `primary`
  (`app_theme.dart:135-137`, có comment lý do); vô hại vì mọi component set
  `surfaceTintColor: transparent`, nhưng là ánh xạ phi chuẩn.
- **`*FixedDim` trùng hệt `*Fixed`** (cả 3 họ) — theo M3, Dim phải là tone tối
  hơn phân biệt được.
- **Màu trang không có slot trong scheme**: scaffold/AppBar/NavigationBar dùng
  `AppColors.background*` truyền tham số riêng; `scheme.surfaceDim` dark
  (`#0B0327`) gần trùng trang (`#0A082D`) nhưng không phải là nó.

### 3. Giá trị trùng lặp định nghĩa ở nhiều nơi (Dart)

| Hex | Các tên đang giữ cùng giá trị |
|---|---|
| `#4646B4` | `seed` (AC:53), `primaryLight` (AC:201), `primaryAccentLight` (AC:214), `surfaceTint` light, `onPrimaryFixedVariant` |
| `#8A8AE0` | `focusRingDark` (AC:169), `primaryAccentDark` (AC:215), `progressFillDark` (AC:283) |
| `#FCFCFE` | `surfaceElevatedLight` (AC:97), `surfaceContainerLowestLight` (MR:88), `surfaceBrightLight` (MR:107) |
| `#EAECF1` | `surfaceMutedLight` (AC:89), `surfaceContainerHighLight` (MR:101) |
| `#28254B` | `surfaceMutedDark` (AC:90), `surfaceContainerHighDark` (MR:102) |
| `#37345F` | `surfaceElevatedDark` (AC:98), `surfaceBrightDark` (MR:108), `surfaceTint` dark |
| `#332F58` | `secondaryContainerDark` (MR:64), `surfaceContainerHighestDark` (MR:104) |
| `#8DB4D8` | `tertiaryDark` (MR:73), `infoDark` (AC:322) — comment MR:70-73 ghi là chủ đích |
| `#C02B3A`/`#F2808F` | `danger` (AC:262-263) = `scheme.error` |
| `#0B0C18`/`#04040B` | `shadow` = `scrim` từng mode (AC:350-353) |
| `#E0B064` | `warningDark` (AC:259) = `onStreakContainerDark` (AC:317) |

Một số trùng lặp được comment ghi là cùng-thang-cố-ý (MR:90-95: dark ladder
dùng chung giá trị với `surfaceMuted`/`surfaceElevated`/`secondaryContainer`);
số còn lại chỉ trùng số, không có ràng buộc nào giữ chúng đồng bộ.

### 4. Trùng lặp chéo Dart ↔ CSS kit

`design_system/tokens/colors.css` chép lại toàn bộ giá trị Dart (tự nhận ở
header :1-4). Hai chỗ đã lệch nhau:

- `--color-disabled-surface` = `#E3E3E6`/`#312E4E` vs Dart `#E0E0E5`/`#33324F`
  (AC:178-180 gọi đây là "stale transcription", ghi trong `docs/wbs.md`
  M4.10an).
- `--color-streak` (`#C2731B`) làm label trên `--color-streak-container` light
  chỉ đạt 3.12:1; phía Dart đã thay bằng `onStreakContainerLight #7A4A10`
  (AC:300-312) — CSS chưa có token on-streak tương ứng.
