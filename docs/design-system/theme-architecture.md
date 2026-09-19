# Theme architecture — `lib/core/theme/`

| | |
|---|---|
| **Status** | active |
| **Purpose** | Nói rõ mỗi loại quyết định thị giác sống ở tầng nào trong `lib/core/theme/`, và chiều phụ thuộc giữa các tầng |
| **Scope** | Cấu trúc thư mục, trách nhiệm từng tầng, public API của theme. Ngoài phạm vi: *giá trị* của token (AD-14), hợp đồng component-level (`.claude/skills/flutter-theme-design/`) |
| **Source of truth for** | Layering của `lib/core/theme/` · chiều import giữa các tầng · ranh giới public/internal của theme · bảng "cần gì thì đọc ở đâu" · ma trận dịch Tokyo → MemoX |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14, AD-23) |
| **Updated by task** | M100.116 |
| **Last updated** | 2026-09-19 |

---

## 1. Ba nguồn, ba vai trò khác nhau

Hệ thị giác của memox có ba nguồn, và lẫn chúng vào nhau là cách sinh ra một
token thừa hoặc một role bị thay thế:

| Nguồn | Trả lời câu gì | Không trả lời câu gì |
|---|---|---|
| **Tokyo** (`ntgptit/tokyo-react-admin-dashboard`) | Personality — hue nào, page/card trông thế nào, dark dùng rim hay shade | Component nào bind vào role nào |
| **Material 3** | Semantic contract — 45 role, và mỗi component đọc role nào | Hex của role đó |
| **MemoX tokens** | Implementation discipline — token nào tồn tại, ai được đọc nó, cưỡng chế ở đâu | Thẩm mỹ |

Thứ tự ưu tiên đã chốt ở AD-14 và M100.28, và tài liệu này **không** phát biểu
lại nó: một component bind vào canonical M3 role; khi role trượt một tỉ lệ
contrast thì **palette dịch**, không phải role bị thay bằng token khác. Tokyo là
tham chiếu thị giác xếp *dưới* hợp đồng đó.

---

## 2. Chiều phụ thuộc

```
                 foundations/
          (colour · spacing · sizing · radius · stroke ·
           elevation · icon size · breakpoints · durations)
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
    typography/     states/      extensions/      ← read side
   (type scale)  (hover/press/    (context.colors,
                  focus/disabled)   AppInk)
          │             │
          └──────┬──────┘
                 ▼
        components/   schemes/
     (ThemeData slot  (ColorScheme,
      builders)        high contrast, compact)
                 │
                 ▼
           app_theme.dart          ← composition root
                 │
                 ▼
          lib/shared/widgets/
                 │
                 ▼
            lib/features/
```

MUST: mỗi tầng chỉ import tầng dưới nó và chính nó. Cụ thể:

| Tầng | Được import |
|---|---|
| `foundations/` | *(không gì trong theme ngoài `foundations/`)* |
| `typography/` | `foundations/` |
| `states/` | `foundations/` |
| `components/` | `foundations/`, `typography/`, `states/` |
| `schemes/` | `foundations/`, `typography/`, `states/` |
| `extensions/` | `foundations/`, `typography/` |
| `app_theme.dart` | tất cả |

MUST NOT: bất cứ file nào trong `lib/core/theme/` import `lib/features/`,
`lib/app/` hoặc `lib/shared/`. Theme được dựng trước khi ba thứ đó tồn tại; một
import ngược lại làm design system phụ thuộc vào chính app nó đang mặc — cùng
kiểu hỏng mà AD-13 cấm với `features/` → `app/`.

MUST: `app_theme.dart` **gọi** component theme, không **dựng** nó. Mọi
`XxxThemeData(` — và `XxxTheme(`, vì `AppBarTheme` cùng `InputDecorationTheme`
không có hậu tố `Data` — phải nằm trong `components/`. Hai ngoại lệ: `ThemeData`
là chính đối tượng đang được dựng, và `IconThemeData` không phải component theme
— `ThemeData.iconTheme` là fall-through cho một `Icon` trần nằm ngoài mọi
component, cùng họ với `hoverColor` và `disabledColor`.

Cưỡng chế: `test/core/theme/contracts/theme_layering_test.dart`. Cả năm rule
trong đó đều đã được kiểm ngược (chèn vi phạm → test đỏ) khi viết, vì một guard
không khớp gì thì xanh vĩnh viễn — và rule thứ năm bắt đúng lỗi đó ngay lần đầu:
một ký tự escape hỏng khiến regex không khớp gì và test xanh giả.

**`extensions/` nằm cạnh chứ không nằm dưới.** Nó là *read side* — thứ một
widget gọi trên một `ThemeData` đã dựng xong (`context.colors`,
`context.semanticColors`, `AppInk`). Nó không được biết app theme những component
nào, vì `context.colors` phải chạy đúng cả với component chưa ai theme.

---

## 3. Mô hình bề mặt

M3 định nghĩa `surface` là **nền cơ sở**, và mọi thứ đặt lên nó là container.
memox từng làm ngược — gọi card là `surface`, để trang ngoài `ColorScheme` — nên
component nào cần màu trang cũng phải được đưa một màu vào, vòng qua hệ role.
Sửa ở M100.32 bằng cách dời hex qua thang, không đổi mapping component:

| Vai trò thị giác | Role | light | dark |
|---|---|---|---|
| trang | `surface` | `#F7F9FE` | `#0A0E27` |
| một bậc dưới giấy (recess) | `surfaceContainerLowest` | `#FFFFFF` | `#131A3A` |
| **mặt giấy** — card, sheet, menu, pill | `surfaceContainerLow` | `#F1F4FB` | `#1B2249` |
| inset / nhấn | `surfaceContainer` → `High` → `Highest` | `#E9EDF7` → `#E2E7F3` → `#DAE0EF` | `#232B5A` → `#2C356E` → `#353D7E` |

Giá trị hiện hành của toàn bộ 45 role (v3 foundations, M100.97):
[`v3-foundations.md`](v3-foundations.md) §1.1.

MUST NOT: dựng một hệ "màu trang" song song nằm ngoài `ColorScheme`. Không
component theme nào được nhận màu trang như một tham số — `scheme.surface` là
nguồn duy nhất.

**Trạng thái tương tác — một cơ chế mỗi state, và fill không di chuyển**
(M100.36). Hover, focus, press của một control là **state layer** M3: mực `on-*`
của chính control đó ở `AppInteractionStates.stateLayerHover/Focus/Pressed`
(8 / 10 / 10%) trên fill role không đổi. Không blend fill về `primary`, không
tint chồng lên ripple của SDK, không token alias riêng cho từng control. Focus
có đúng một chỉ báo mỗi họ — bảng ở
[`tokyo-component-mapping.md`](tokyo-component-mapping.md) §8. Disabled là
`disabledSurfaceTint` (`onSurface @ 12%`) cho *mọi* control, chọn hay không.

Ma trận role từng component ở
[`tokyo-component-mapping.md`](tokyo-component-mapping.md) §2, và §4 ở đó ghi
bốn binding đã được trả về canonical cùng phép đo thang.

---

## 3. Cần gì thì đọc ở đâu

| Cần | Source of truth | Tầng |
|---|---|---|
| M3 role (`primary`, `surface`, `outline`…) | `ColorScheme` qua `context.colors` | `schemes/app_color_scheme.dart` dựng |
| Business semantic (`success`, `overdue`, `streak`…) | `AppSemanticColors` qua `context.semanticColors` | `foundations/` |
| Màu của một đoạn text | `AppInk` + `TextStyle.inked()` | `extensions/` |
| Gap, pad, inset | `AppSpacing` | `foundations/` |
| Chiều cao/rộng của một control | `AppSizing` | `foundations/` |
| Bo góc | `AppRadius` | `foundations/` |
| Độ dày nét | `AppStroke` | `foundations/` |
| Chiều sâu | `AppElevation` + `shadowsFor()` | `foundations/` |
| Cỡ icon | `AppIconSize` | `foundations/` |
| Bậc chữ | `TextTheme` qua `context.texts` | `typography/` dựng |
| Bậc chữ app-only (`cardPrompt`, `sectionLabel`) | `AppTextStyles` qua `context.textStyles` | `typography/` |
| Hover / pressed / focus / disabled | `AppStateOpacity`, `AppInteractionStates` | `states/` |
| Thời lượng animation | `AppDurations` + `AppMotionPolicy.durationOf` | `foundations/` |
| Breakpoint | `AppBreakpoints` | `foundations/` |

---

## 4. Public API của theme

`lib/features/` MUST chỉ đọc theme qua: `Theme.of(context)` / `context.colors` /
`context.texts` / `context.semanticColors` / `context.textStyles` / `AppInk`, và
các thang cấu trúc ở `foundations/` + `typography/`.

MUST NOT — với `lib/features/`:

| Không được import | Vì sao |
|---|---|
| `foundations/app_colors.dart`, `app_material_roles.dart`, `app_surface_colors.dart`, `app_border_colors.dart` | Đây là thứ `ColorScheme` **được dựng từ**. Đọc thẳng chúng là đóng băng một giá trị vào một brightness — đúng lỗi mà M100.18–23 mất sáu PR để gỡ khỏi component builder |
| `components/`, `schemes/`, `states/` | Component theme là một nửa hợp đồng mà nửa kia là một widget `Mx*`; feature dựng lại nó nghĩa là dựng lại component mà `shared/` đã sở hữu |

`lib/shared/widgets/` được thêm quyền đọc `components/` và `states/` — đó chính
là nửa widget của hợp đồng (`MxActionButton` gọi `buildFilledTonalStyle` để
widget và theme slot không thể lệch nhau). Vẫn MUST NOT đọc bốn file palette.

`lib/app/` không bị chặn gì: nó là composition root — chọn scheme, áp
`applyCompactScale`, và vẽ hai bề mặt nằm **ngoài** `MaterialApp` (bootstrap
error screen, letterbox của bản web) nơi không `Theme.of(context)` nào với tới.

**`components/` chia theo họ component (M100.31).** Chín thư mục, mỗi file một
họ:

```
actions/     button · icon button · fab
inputs/      input decoration · text selection
selection/   chip · toggle · radio · slider · segmented button
navigation/  navigation bar · tab bar · app bar
surfaces/    card · dialog · bottom sheet
content/     list tile · divider · scrollbar
feedback/    progress · snackbar · tooltip
overlays/    popup menu · backdrop recipe
pickers/     date picker · time picker
```

Trước đó có ba file gom: `app_overlay_themes.dart` giữ tám thứ không liên quan
(progress, tooltip, text selection, divider, scrollbar, time picker, popup menu,
scrim), `app_modal_themes.dart` giữ ba, và `app_planned_themes.dart` là nơi
chứa mọi component chưa biết đặt ở đâu. Cái cuối là vấn đề riêng: "planned"
không phải một họ, và bốn component trong đó đã có consumer thật.

`app_theme.dart` giữ đúng bốn thứ: `ThemeData` base, các fall-through cấp
framework (`hoverColor`, `canvasColor`, `disabledColor`, `iconTheme`),
extension, và danh sách slot → builder.

**Component theme chỉ chạm palette qua `ColorScheme`.** `components/` được
import `foundations/`, nhưng **không** bốn file palette (`app_colors`,
`app_material_roles`, `app_surface_colors`, `app_border_colors`): đó là thứ
`ColorScheme` được *dựng từ*, và đọc thẳng chúng là đóng băng một giá trị vào
một brightness. Token cấu trúc thì khác và vẫn được — một radius không phải
role, và không có scheme nào để đọc nó qua.

**Builder nhận hệ semantic, không nhận màu rời.** `ColorScheme`, `TextTheme`,
`AppSemanticColors`, hoặc một enum đóng của những cặp design system chấp nhận
(`MxFilledPair`). Hai ngoại lệ có tên — `background` của app bar và `accent` của
`textLinkForeground` — được ghi lý do ngay trong guard; cái thứ ba phải tranh
luận ở đó chứ không xuất hiện lặng lẽ.

**`AppSemanticColors` đủ cặp, kể cả khi một nửa chưa có caller** (M100.36 §4Q).
Một màu business (`success`, `warning`, `overdue`, `streak`…) là một **cặp**
`x` / `xContainer` với mực `onX` / `onXContainer`; đơn vị của hệ là cặp, không
phải từng màu. `warningContainer` / `onWarningContainer` được **giữ** với 0
caller vì bỏ nó là bỏ một nửa của `warning`, và feature đầu tiên cần một band
cảnh báo sẽ tự chế một `Container` màu — đúng cái guard tồn tại để chặn. MUST:
một màu semantic mới đến cùng container và hai mực của nó, hoặc không đến.
MUST NOT: xoá một nửa cặp vì "chưa ai dùng".

Ma trận role canonical từng component, và bốn sai lệch đã biết, nằm ở
[`tokyo-component-mapping.md`](tokyo-component-mapping.md).

**Không có barrel `theme.dart`.** Một barrel gom cả 31 file sẽ biến mọi internal
token thành public API, và guard ở §2 sẽ mất khả năng phân biệt — mọi import đều
là cùng một dòng. Import trực tiếp file cần dùng là thứ làm cho rule "feature
không đọc `app_material_roles`" kiểm tra được.

---

## 5. Dịch Tokyo sang MemoX

Bảng này mô tả **ý đồ thị giác → token semantic**, không phải quy đổi giá trị.
Một giá trị Tokyo không nằm trên thang MemoX thì *snap về tier gần nhất theo ý
đồ*, không kéo thang ra để chứa nó.

| Tokyo | Ý đồ | MemoX |
|---|---|---|
| `primary.main` / `primary.dark` | họ accent | `ColorScheme.primary` — hex chọn theo tone qua được mọi consumer canonical (M100.28) |
| `background.default` | nền trang | `AppSurfaceColors.background*` (không có M3 role) |
| `paper` | mặt card | `ColorScheme.surface` |
| `text.primary` / `text.secondary` | mực chính / mực phụ | `onSurface` / `onSurfaceVariant` |
| `divider` | hairline | `outlineVariant` |
| `shadows.cardSm` | card ngồi trên trang | `shadowsFor(AppElevation.card)` — float + contact |
| `shadows.card` | panel nổi hẳn lên | `shadowsFor(AppElevation.raised)` |
| `shadows.card` (dark) | **không còn dùng** | Rim Tokyo `#6A7199` bị gỡ ở M100.35 — nó đo 3.74:1 trên chính mặt card, tức độ tương phản của một viền *điều khiển*, và blur biến nó thành quầng trên góc 16 px. Dark vẽ `ColorScheme.outlineVariant` sắc nét (1.30:1) + drop thật ở mức trên `card`. |
| `MuiButton.root.fontWeight: bold` | action đọc ra là action | `buttonLabelWeight` = w700 |
| `general.borderRadius` 10px | góc mặt phẳng | `AppRadius.lg` (16) — **giữ nguyên thang MemoX** |
| `MuiButtonBase.borderRadius` 6px | góc control | `AppRadius.md` (12) — như trên |
| `sizeMedium` padding `8px 20px` | nút chắc, không rỗng | `AppSpacing.xl` / `md` — 20 không có trên thang |
| chiều cao nút ~38 | dày vừa phải | `AppSizing.touchTarget` 48 — sàn a11y thắng |

### Đã cân nhắc và **không** làm

Ghi lại để lần sau không đề xuất lại:

| Nét Tokyo | Vì sao không |
|---|---|
| Hạ tier radius (card 16→12, control 12→8) | Chủ dự án chọn phạm vi "shadow + density" cho lượt này; radius đụng mọi bề mặt và mọi golden. Để lượt sau |
| `disableRipple: true` trên button | Tokyo thay ripple bằng transition màu. Android là release target và ripple là quy ước nền tảng ở đó, không phải tranh chấp Tokyo↔M3 |
| Padding ngang 20 cho nút | 20 không có trên `AppSpacing`. Thêm bậc thứ bảy để nút chặt hơn 4dp là đúng thứ drift mà header của `AppSpacing` từ chối |
| `MuiPaper.outlined` cũng có shadow | `MxCard.flat` cố ý không có bóng: nó dùng cho card nằm *trong* sheet, nơi bóng chồng bóng đọc thành lỗi render |
| Chiều cao nút 33/38/44 | Dưới sàn touch target 48. Tokyo là personality, a11y là hợp đồng — hợp đồng thắng (§19 của brief) |

---

## 6. Ranh giới với các tài liệu khác

- **Giá trị** của token — hex, tỉ lệ contrast, độ sâu tính bằng L\* — thuộc
  AD-14, không thuộc file này.
- **Hợp đồng component-level** — khi nào một Material widget được coi là
  "supported", API của một `Mx*` widget được phép lộ gì — thuộc
  `.claude/skills/flutter-theme-design/`.
- **API của shared surface/action** thuộc AD-23.
- Cấu trúc `presentation/widgets/` của một feature thuộc AD-15. File này chỉ nói
  về `lib/core/theme/`.

---

## 7. Định tuyến registry v3 theo kind

M100.97 (#569) đưa 45 role `ColorScheme`, mười hai `*Fixed`, bảy ink chữ và
toàn bộ ladder vào repo — **tầng này không viết lại giá trị nào của #569**.
Phần còn lại của registry v3
(`docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md`) là những
mục Foundation *chưa* có nơi chứa: mỗi mục mang một `KIND`, và KIND quyết
định nó chảy vào cơ chế nào — không phải agent tự chọn theo cảm tính.
**#569 sở hữu giá trị Foundation; tầng này sở hữu định tuyến và quyền sống
của runtime.**

| Kind | Cơ chế | File |
|---|---|---|
| `MEMOX_SEMANTIC_COLOR` (BIND_NOW) | Field trên `AppSemanticColors`, giá trị đọc từ hằng số riêng | `foundations/app_semantic_colors.dart` + `foundations/app_product_colors.dart` |
| `M3_ALIAS` | Đọc thẳng role `ColorScheme` tương ứng — không field riêng | `schemes/app_color_scheme.dart` |
| `DERIVED_COLOR` | Một hàm dẫn xuất trung tâm, nhận `ColorScheme` | `foundations/app_derived_colors.dart` |
| `DECORATION` | Một hàm treatment có tên, trả `List<BoxShadow>` hoặc `BorderSide` | `foundations/app_decorations.dart` |
| `STATE_TOKEN` | Hằng số trên chính sách interaction-state | `states/app_interaction_states.dart` (`AppStateOpacity`) |
| `EFFECT_TOKEN` | Hằng số đứng ngoài tầng state | `foundations/app_effects.dart` |
| `COMPONENT_INPUT` / `NONE` | Không field nào — tham số component tự truyền, hoặc hằng số sẵn có của Flutter (`Colors.transparent`) | — |

MUST: một mục `PRESERVE_ONLY` không được thêm field, hằng số hay hàm nào —
giữ nguyên định nghĩa cũ nếu có, không tạo bản sao không ai gọi. MUST: một
`M3_ALIAS` (và mọi `COMPONENT_INPUT`/`NONE`) không bao giờ có field runtime
của riêng nó — nó luôn đọc thẳng `ColorScheme`, hoặc không có giá trị theme
nào cả.

`test/core/theme/contracts/v3_theme_binding_test.dart` cưỡng chế hai MUST này
bằng **hai cơ chế khác nhau, không phải một**. PRESERVE_ONLY được quét trên
toàn bộ `lib/core/theme` — quét khai báo Dart theo hình dạng (field/const/hàm),
không quét chữ mù, để một danh tính không liên quan (`AppWellFill.streak`,
`AppColors.seed`) không thành báo sai. `M3_ALIAS` và `COMPONENT_INPUT`/`NONE`
thì hẹp hơn: chỉ kiểm danh sách field của riêng `AppSemanticColors` — nơi duy
nhất một field như vậy có thể đáp xuống nếu nó thật sự đáp xuống đâu đó — chứ
không quét cả cây. Lý do đo được, không phải phỏng đoán: mở rộng chính cái
scan theo hình dạng ấy ra cả cây sẽ báo sai `AppColors.seed`, một hằng số
palette hợp lệ có từ trước v3. (`accent` thì không — nó chỉ tồn tại ở đây như
tham số của một builder và như một giá trị enum `AppInk`, hai hình dạng mà
scan này không bắt; nó chỉ là rủi ro với một phép quét chữ mù.)

**Hai chỗ tên trùng nhau, ghi rõ để không ai đọc nhầm cái này thành cái kia:**

- `AppSemanticColors.surfaceMuted` là tên cũ, có từ trước #569, đọc
  `ColorScheme.surfaceContainer`. `surface-muted` của v3 là một role khác —
  `surfaceContainerLow`. Hai giá trị khác nhau, hai ý nghĩa khác nhau; field
  cũ **không đổi**, và **không** phải alias của role v3 cùng tên (owner
  ruling 2026-09-18).
- `AppSemanticColors.progressTrack` là một compatibility alias, không phải
  nguồn thứ hai: nó đọc đúng `ColorScheme.surfaceContainerHigh` — route
  canonical mà `progress-track` cũng trỏ vào. Không call site nào đọc field
  này hôm nay; nó nằm trong danh sách nợ cần rút, chờ dịp component nào đó
  đọc thẳng `context.colors.surfaceContainerHigh` thay vì field này.

### COMPONENT_MIGRATION_PENDING

Slot mà v3 đã đặt tên vai trò nhưng component hôm nay còn đọc vai khác — biết
trước, hoãn lại, không sửa "tiện tay" trong task ghi nhận này (owner rule 8;
delta matrix D3/D5 của kế hoạch này). Task implement component nào đọc bảng
này trước khi tự đoán role.

| Component | Slot | Target semantic role |
|---|---|---|
| `NavigationBar` | nền | `chrome-glass` — **chặn, xem bên dưới** |
| `MxFilterChip` | nền + label đã chọn | `primary` / `onPrimary` — **đã thi hành ở M100.116, ngoài `ChipThemeData`** |
| `MxFilterChip` | label chưa chọn | `onSurface` — **đã thi hành ở M100.116, ngoài `ChipThemeData`** |
| `MxFilterChip` | viền | `border-ghost` — **đã thi hành ở M100.116, ngoài `ChipThemeData`** |

**Đợt Controls đã trả xong ở M100.101** và sáu dòng nữa rời bảng: thumb của
`Switch`, side của `OutlinedButton`, glyph của `IconButton`, và cả ba dòng của
`TextField` (hai fill cộng viền).

**`IconButton` lợi lớn:** glyph rời `onSurfaceVariant` sang `onSurface` —
**7.20 → 16.72** trong light, **8.50 → 15.59** trong dark.

**Ba cạnh control cùng đi xuống dưới sàn 3:1**, và đây là số đo ở nền *yếu nhất*
chứ không phải ở trang:

| Cạnh | Trước | Sau | Nền yếu nhất |
|---|---|---|---|
| `OutlinedButton` side | 3.44 / 3.75 | **1.30 / 1.05** | `surfaceContainerHigh` (dialog) |
| `TextField` viền | 2.92–3.44 / 2.25–3.75 | **1.17 / 1.27** | mọi nền, gần như phẳng |
| `Switch` thumb (trên track) | 2.74 / 1.96 | **1.32 / 1.36** | track |

**Ô nhập là chỗ nặng nhất, vì fill cũng không gánh nổi ranh giới.** v3 cho field
một fill cùng lúc với việc làm mờ viền, nhưng fill lúc nghỉ chỉ cách trang
**1.05:1** (ΔL\* 1.76) trong light — nên một ô nhập sáng trên trang **không còn
ranh giới nào vượt bất kỳ ngưỡng nào**. Nó đọc được là nhờ *chữ* trong nó
(16.00:1), không nhờ cạnh. Dark khá hơn: fill cách trang ΔL\* 9.98.

**Một nghịch đảo phải nói rõ:** switch **disabled giờ đậm hơn switch đang tắt** ở
cả hai theme — 2.30 so với 1.32 (light), 3.00 so với 1.36 (dark). Dark đã nghịch
đảo từ khi v3 dời `outline`; light theo sau ở M100.101. Một control người dùng
không chạm được lại dễ thấy hơn control họ chạm được, tức là ngược hẳn nghĩa của
trạng thái. `app_toggle_themes_test.dart` ghi lại nguyên văn nghịch đảo đó và sẽ
**đỏ có chủ ý** vào ngày spec Switch đổi binding.

**Một gate xanh giả đã bị bắt trong lúc làm.** `control_border_grounds_test.dart`
đo *token* `borderControl`, không đo thứ button và field thật sự vẽ — nên khi v3
dời cả hai component khỏi token đó, gate vẫn xanh và không còn đo gì cả, dù câu
`reason` của nó vẫn nói "the outlined button and the text field both draw
borderControl". Đã thêm một group đo đúng cạnh thật, ghim theo nền yếu nhất.

**Ba dòng `FilterChip` giờ có caller, và caller không đi qua `ChipThemeData`:**
`MxFilterChip` (M100.116, `lib/shared/widgets/mx_filter_chip.dart`) là control
một-trong-N cao 28dp cố định của v3, và nó đọc trực tiếp `primary` / `onPrimary`
(nền + label đã chọn), `onSurface` (label chưa chọn) và `border-ghost` (viền chưa
chọn, `AppSemanticColors.borderGhost`) từ theme của ngữ cảnh. Nó **không** dựng
trên `ChoiceChip`/`RawChip` — chúng kẹp chiều cao vẽ ra ở mức sàn ~34dp, cao hơn
28dp của v3 — và không ghi vào `ChipThemeData`, vốn dùng chung cho mọi biến thể
chip. Nên `ChoiceChip` và `MxPillButton` **không đổi một pixel**: đó chính là lý
do ba dòng này bị giữ lại ở M100.101 (thi hành chúng trên `ChipThemeData` sẽ âm
thầm đổi `ChoiceChip`) và là lý do chúng đáp xuống một caller mới thay vì sửa
theme dùng chung. Đúng luật R7 của v3 — màu chưa có caller thì ghi lại, không
khai báo; `border-ghost` được khai báo cùng lúc với caller đầu tiên của nó
(`AppBorderColors.borderGhost*`, xem `v3-foundations.md` mục R7). Kế hoạch:
`docs/superpowers/plans/2026-09-18-memox-filter-chip.md`. Các dòng vẫn nằm trong
bảng vì slot `ChipThemeData` của chúng **vẫn chưa** đọc các vai đó — chỉ
`MxFilterChip` đọc.

**Đợt Chrome đã trả xong ở M100.100** và năm dòng nữa rời bảng: track của
`ProgressIndicatorThemeData`, indicator + icon/label đã chọn của `NavigationBar`,
cặp màu của `FloatingActionButton`, và viền trên của `MxNavigationBar`.

**FAB là chỗ được lợi nhiều nhất.** `primaryContainer` đọc **1.19:1** so với
trang trong light và **1.64:1** trong dark — hành động tạo duy nhất của app là
một hình chỉ tìm thấy nếu đã biết nó ở đâu. `primary` đọc **4.39:1 / 7.39:1**.
Glyph trả lại một phần (10.37 → 4.63 light, 8.81 → 6.76 dark) nhưng vẫn trên sàn
4.5.

**Nhãn nav đã chọn là cái giá thật của đợt này:** 15.03:1 → **3.95:1** trong
light, dưới sàn 4.5 của chữ nhỏ, trên đúng chữ báo người dùng đang ở tab nào.
`component_depth_and_state_test.dart` ghim nó (floor 3.94 theo R12) như bản ghi
trạng thái trung gian. Thứ còn gánh lựa chọn khi màu không gánh nổi: cặp icon
outlined/filled — không dùng màu chút nào — cùng weight w600 và
`Semantics(selected:)`.

**Hai va chạm phải báo chứ không tự quyết:**

- **`NavigationBar` nền → `chrome-glass`: chặn, không phải hoãn cho vui.**
  `chrome-glass` là `surface @ 0.84`, mà `surface` trong palette này **chính là
  màu trang**. Shell không đặt `extendBody`, nên phía sau thanh nav không có gì
  ngoài nền Scaffold: đặt màu đó vào là thanh nav composite ra đúng màu trang và
  biến mất — đúng thứ M100.22 đã sửa. Làm glass thật cần `extendBody: true` cộng
  `BackdropFilter` ở `AppEffects.glassBlurSigma` (18), tức là đảo quyết định bố
  cục mà `app_navigation_shell.dart` ghi rõ ("the last row of a list ends above
  the bar rather than under it") và buộc mọi màn tự khai bottom padding. Đó là
  quyết định **bố cục**, không phải sàn contrast, nên nó cần chủ dự án chốt
  riêng.
- **`SegmentedButton` rời khỏi "house pair".** `app_unrendered_component_themes_test.dart`
  ghim rằng segment đang chọn bằng `navigationBarTheme.indicatorColor`. v3 dời
  indicator nhưng **không nhắc `SegmentedButton`** trong registry, nên hai bên
  giờ lệch nhau. Không tự bịa binding: test đã đổi sang ghim `secondaryContainer`
  trực tiếp và nêu rằng hợp nhất lại cần registry gọi tên component này, hoặc
  chủ dự án chốt rằng segment đi theo thanh nav.

**Đợt Surfaces đã trả xong ở M100.99** và mười một dòng của nó rời bảng: hai fill
của `MxCard` (đổi chỗ, `.surface` → `surfaceContainerLowest`, `.recessed` →
`surfaceContainerLow`), viền dark của `MxCard` và rim của `_darkDepth` →
`border-ghost`, `CardTheme.color`, `ChoiceChip` lúc nghỉ, `canvasColor`, nền +
grabber của `BottomSheetThemeData`, nền hàng guess-option, nền match tile, và
nền của hai phép blend disabled (`disabledSurfaceTint`, hairline disabled của
`InputDecorationTheme`).

**Một sàn accessibility đã bị nới, có chủ ý và có hồ sơ.** Grabber của bottom
sheet đọc **1.30:1 sáng / 1.05:1 tối** trên nền `surfaceContainerHigh` mới, so
với 6.12 / 5.10 khi nó còn là `onSurfaceVariant` — dưới sàn 3:1 mà WCAG 1.4.11
đòi ở một control. Chủ dự án chọn v3 với đúng hai con số này trước mặt.
`component_depth_and_state_test.dart` ghim lại chúng như một **bản ghi trạng thái
trung gian**, không phải một chuẩn: nó chặn mọi lần tụt thêm và nêu tên thứ sẽ
khôi phục sàn. Trả lại hình 3:1 là việc của task component cho sheet.

Ba dòng còn trong bảng cũng sẽ đi xuống dưới sàn khi tới lượt, và số đo có sẵn
để khỏi phải đo lại: `OutlinedButton` side `outlineVariant` **1.53 / 1.58**;
`TextField` và `FilterChip` viền `border-ghost` **1.19 / 1.28** (số ước lượng lúc
ghi; `FilterChip` đã đo lại ở M100.116 trên `surface`: **1.14 / 1.47**, ghim bởi
`high_contrast_figures_test.dart` — đó là số có thẩm quyền, còn `TextField` đã
đo thật ở M100.101 là 1.17 / 1.27); `Switch` thumb
`surfaceBright` **1.05 / 1.42** (trong light là `#FFFFFF` trên nền trang
`#F7F9FE`). Hai dòng của `NavigationBar` thì đảo ngược quyết định có phép đo của
M100.22 — indicator rời `secondaryContainer`, label đã chọn rời `onSurface`
(15.03 / 11.01) về `primary` (**3.95** trong light, dưới sàn 4.5:1 của chữ nhỏ).

Hai điều liên quan nhưng không phải một binding component · slot, nên đứng
ngoài bảng thay vì kéo dãn cột "Target semantic role": `AppDecorations
.chromeShadow` (`shadow-chrome`) đã có hàm nhưng chưa consumer nào gọi; và
ánh xạ level → treatment của `shadowsFor` (thang elevation) là quyết định của
hợp đồng từng component, chưa chốt ở đây.
