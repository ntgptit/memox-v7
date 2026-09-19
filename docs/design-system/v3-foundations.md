# Design system — MemoX v3 foundations

| | |
|---|---|
| **Status** | active |
| **Purpose** | Bản đồ giá trị handoff MemoX v3 → symbol Dart: mọi hex/size/alpha của GC-1…GC-7, bảng alias CSS → Dart, bảng đổi tên radius/icon (R8), và các ruling đã chốt trước khi triển khai (R1–R13) |
| **Scope** | Nền tảng thị giác toàn cục — palette hai theme, ink chữ, type scale, ladder spacing/radius/icon/state-layer, bóng đổ, composition (16 gutter, 48 scroll tail). Ngoài phạm vi: biến thể/hình học từng component (spec component riêng sẽ đọc file này — ruling R1), lý luận kiến trúc màu nói chung (`ad-14-color-and-depth.md`), layering của `lib/core/theme/` (`theme-architecture.md`) |
| **Source of truth for** | Giá trị token v3 dưới dạng spec value → Dart symbol; bảng alias CSS → Dart; tên gọi radius/icon CSS ↔ Dart; các ruling R1–R13 đưa ra khi triển khai foundations |
| **Depends on** | `document-conventions.md` · `docs/superpowers/specs/2026-09-17-memox-v3-foundations.md` (handoff nguyên văn) · `docs/superpowers/plans/2026-09-17-memox-v3-foundations.md` (kế hoạch và rulings gốc) |
| **Updated by task** | M100.116 |
| **Last updated** | 2026-09-19 |

---

Tài liệu này là **bản đồ giá trị**, không phải lý luận thiết kế: nó nói "spec viết
X, Dart đọc Y ở đâu", và không lặp lại *vì sao* — AD-14 giữ lý luận màu,
`theme-architecture.md` giữ layering. Mọi hex, size và alpha dưới đây được chép
nguyên văn từ `docs/superpowers/specs/2026-09-17-memox-v3-foundations.md` (handoff
của chủ dự án) hoặc từ các Global Constraint (GC-1…GC-8) mà kế hoạch triển khai
suy ra từ handoff đó — không có số nào được gõ lại từ trí nhớ.

Bốn mục dưới đây, theo đúng thứ tự một người cần tra: (1) bản đồ token theo GC,
(2) bảng alias của spec resolve về Dart, (3) đổi tên radius/icon giữa CSS và
Dart, (4) các ruling đã chốt khi spec im lặng.

---

## 1. Token map — spec value → Dart symbol (GC-1…GC-7)

### 1.1 GC-1 · 45 role của `ColorScheme` (light / dark)

| Role | Light | Dark | Dart constant(s) |
|---|---|---|---|
| primary | `#5265F5` | `#8B9AFF` | `AppColors.primaryLight/Dark` |
| onPrimary | `#FFFFFF` | `#11173A` | `AppColors.onPrimaryLight/Dark` |
| primaryContainer | `#E0E5FE` | `#2D346A` | `AppMaterialRoles.primaryContainerLight/Dark` |
| onPrimaryContainer | `#1A2580` | `#D9DFFF` | `AppMaterialRoles.onPrimaryContainerLight/Dark` |
| secondary | `#6E7CD9` | `#9DA8E8` | `AppMaterialRoles.secondaryLight/Dark` |
| onSecondary | `#FFFFFF` | `#1A2150` | `AppMaterialRoles.onSecondaryLight/Dark` |
| secondaryContainer | `#E3E6F7` | `#343C78` | `AppMaterialRoles.secondaryContainerLight/Dark` |
| onSecondaryContainer | `#262E6E` | `#DDE2FB` | `AppMaterialRoles.onSecondaryContainerLight/Dark` |
| tertiary | `#8B6FF5` | `#B5A0FF` | `AppMaterialRoles.tertiaryLight/Dark` |
| onTertiary | `#FFFFFF` | `#240B63` | `AppMaterialRoles.onTertiaryLight/Dark` |
| tertiaryContainer | `#EBE3FE` | `#443078` | `AppMaterialRoles.tertiaryContainerLight/Dark` |
| onTertiaryContainer | `#33177E` | `#E6DCFF` | `AppMaterialRoles.onTertiaryContainerLight/Dark` |
| error | `#DC2D4E` | `#FF8FA3` | `AppColors.dangerLight/Dark` |
| onError | `#FFFFFF` | `#52061B` | `AppMaterialRoles.onErrorLight/Dark` |
| errorContainer | `#FBDDE3` | `#7A2036` | `AppMaterialRoles.errorContainerLight/Dark` |
| onErrorContainer | `#7A0A23` | `#FFD9DF` | `AppMaterialRoles.onErrorContainerLight/Dark` |
| surface | `#F7F9FE` | `#0A0E27` | `AppSurfaceColors.pageLight/Dark` |
| onSurface | `#0F1638` | `#E4E8FA` | `AppColors.textPrimaryLight/Dark` |
| onSurfaceVariant | `#4A5278` | `#A4ACD0` | `AppColors.textSecondaryLight/Dark` |
| surfaceDim | `#DAE0EF` | `#060925` | `AppMaterialRoles.surfaceDimLight/Dark` |
| surfaceBright | `#FFFFFF` | `#232B5A` | `AppMaterialRoles.surfaceBrightLight/Dark` |
| surfaceContainerLowest | `#FFFFFF` | `#131A3A` | `AppMaterialRoles.surfaceContainerLowestLight/Dark` |
| surfaceContainerLow | `#F1F4FB` | `#1B2249` | `AppMaterialRoles.surfaceContainerLowLight/Dark` |
| surfaceContainer | `#E9EDF7` | `#232B5A` | `AppMaterialRoles.surfaceContainerLight/Dark` |
| surfaceContainerHigh | `#E2E7F3` | `#2C356E` | `AppMaterialRoles.surfaceContainerHighLight/Dark` |
| surfaceContainerHighest | `#DAE0EF` | `#353D7E` | `AppMaterialRoles.surfaceContainerHighestLight/Dark` |
| outline | `#7C85AB` | `#5A6BAE` | `AppBorderColors.borderControlLight/Dark` |
| outlineVariant | `#C5CBE3` | `#2A3267` | `AppBorderColors.borderSubtleLight/Dark` |
| inverseSurface | `#34395D` | `#34395D` | `AppMaterialRoles.inverseSurfaceLight/Dark` |
| onInverseSurface | `#E8EAFC` | `#E8EAFC` | `AppMaterialRoles.onInverseSurfaceLight/Dark` |
| inversePrimary | `#8B9AFF` | `#5265F5` | `AppMaterialRoles.inversePrimaryLight/Dark` |
| shadow | `#0F1638` | `#000000` | `AppColors.shadowLight/Dark` |
| scrim | `#0A0E27` | `#000000` | `AppColors.scrimLight/Dark` |

Chỉ `inverseSurface`/`onInverseSurface` là bất biến theo chủ đích giữa hai mode
(handoff nói rõ: "both themes" ở chỗ khác chỉ là trùng hợp, không phải bất biến).

Mười hai role `*Fixed` bất biến theo theme, lấy đúng literal `colors_and_type.css`
khai báo — **không** sinh từ tone (ruling R2):

| Role | Value | Role | Value |
|---|---|---|---|
| primaryFixed | `#E0E5FE` | secondaryFixedDim | `#C8CEF0` |
| primaryFixedDim | `#C2CBFD` | onSecondaryFixed | `#131A4E` |
| onPrimaryFixed | `#0B1252` | onSecondaryFixedVariant | `#4453A8` |
| onPrimaryFixedVariant | `#2B3AB8` | tertiaryFixed | `#EBE3FE` |
| secondaryFixed | `#E3E6F7` | tertiaryFixedDim | `#D7C8FD` |
| onTertiaryFixed | `#1D0A57` | onTertiaryFixedVariant | `#6A4AD4` |

### 1.2 GC-2 · Token semantic hiện có, trên palette v3

`AppSemanticColors` giữ nguyên mọi field, chỉ giá trị đổi. Toàn bộ 45 role ở 1.1
là literal; một token cũ **dẫn xuất từ** một role, không bao giờ ngược lại, và
không import cycle nào được mở ra.

| Token (light / dark) | Value | Dẫn xuất |
|---|---|---|
| `AppColors.disabledSurface` | `#DBDEE6` / `#242840` | `onSurface` tại 12% phẳng trên `surface` |
| `AppColors.onDisabled` | `0x610F1638` / `0x61E4E8FA` | `onSurface` tại 38% (v3 disabled 0.38) |
| `AppColors.success` | `#2BA88B` / `#6FE0BD` | v3 `success` |
| `AppColors.warning` | `#F59E0B` / `#FFC658` | v3 `warning` |
| `AppColors.danger` | `#DC2D4E` / `#FF8FA3` | v3 `error` (nạp vào `ColorScheme.error`) |
| `AppColors.info`, `infoContainer`, `onInfoContainer` | **không đổi** | owner answer A2 |
| `AppColors.successContainer` | `#EAF6F3` / `#243E52` | v3 `success-soft` (10% / 18%) phẳng trên `surfaceContainerLowest` |
| `AppColors.onSuccessContainer` | `#1E7460` / `#6FE0BD` | = `successInk` (1.3) |
| `AppColors.warningContainer` | `#FEF3E2` / `#3D393F` | v3 `warning-soft` (12% / 18%) phẳng trên `surfaceContainerLowest` |
| `AppColors.onWarningContainer` | `#3A2A00` / `#FFC658` | = `warningInk` (1.3) |
| `AppColors.streakContainer` / `onStreakContainer` | = `warningContainer` / `onWarningContainer` | due chip thuộc họ time-pressure; v3 vẽ số quá hạn bằng `warning ink` |
| `AppColors.progressTrack` | `#E2E7F3` / `#2C356E` | v3 `progress-track` = `surfaceContainerHigh` |
| `AppColors.progressFill` | `#5265F5` / `#8B9AFF` | = `primary` |
| `AppColors.webLetterbox` | **không đổi** | ngoài app surface |
| `AppSurfaceColors.paper` | `#F1F4FB` / `#1B2249` | = `surfaceContainerLow` (role mà card theme đang bind) |
| `AppSurfaceColors.surfaceEmphasis` | `#F6F7FE` / `#191F41` | v3 `surface-hero`: `primary` 5% trên `#FFFFFF` / 12% trên `#0A0E27` |
| `AppSurfaceColors.surfaceSelected` | `#E0E5FE` / `#2D346A` | = `primaryContainer` ("selected chip, soft emphasis") |
| `AppSurfaceColors.surfaceMuted` | `#E9EDF7` / `#232B5A` | = `surfaceContainer` |
| `AppSurfaceColors.surfaceElevated` | `#FFFFFF` / `#232B5A` | = `surfaceBright` |
| `AppBorderColors.borderSubtle` | `#C5CBE3` / `#2A3267` | = `outlineVariant` |
| `AppBorderColors.borderControl` | `#7C85AB` / `#5A6BAE` | = `outline` |
| `AppBorderColors.borderSelected` | `#5265F5` / `#8B9AFF` | = `primary` |
| `AppBorderColors.borderOption` | `#7C85AB` / `#5A6BAE` | = `outline` |
| `AppBorderColors.borderAccent` | `#D5DAFD` / `#394379` | v3 `primary-border` (24% / 32%) phẳng trên `surfaceContainerLowest` |

### 1.3 GC-3 · Ink chữ (owner answer A1)

Giữ hue/saturation của fill, dời lightness tới giá trị đầu tiên đạt **≥ 4.5:1
trên cả năm nền chữ** của mode đó — light `#F7F9FE #FFFFFF #F1F4FB #E9EDF7
#E2E7F3`, dark `#0A0E27 #131A3A #1B2249 #232B5A #2C356E`. Số trong ngoặc là mức
đo nhỏ nhất.

| Ink trên `AppSemanticColors` | Light | Dark |
|---|---|---|
| `accentInk` (từ `primary`) | `#3E53F4` (4.52) | `#8D9CFF` (4.52) |
| `dangerInk` (từ `error`) | `#C82141` (4.52) | `#FF8FA3` = fill (5.27) |
| `successInk` (từ `success`) | `#1E7460` (4.56) | `#6FE0BD` = fill (7.10) |
| `warningInk` | `#3A2A00` = v3 `on-warning` (11.22) | `#FFC658` = fill (7.32) |
| `secondaryInk` (từ `secondary`) | `#4B5CD0` (4.53) | `#9DA8E8` = fill (5.00) |
| `tertiaryInk` (từ `tertiary`) | `#6945F2` (4.54) | `#B5A0FF` = fill (5.12) |
| `inversePrimaryInk` (bất biến, trên `#34395D`) | `#919FFF` (4.56) | `#919FFF` (4.56) |

`AppInk.resolve`: `accent → accentInk`, `success → successInk`, `warning →
warningInk`, `danger`/`error`/`overdue → dangerInk`, `secondary → secondaryInk`,
`tertiary → tertiaryInk`. `stated`, `quiet`, `info`, `disabled` và mọi member
`on*` không đổi. Không có `masteryInk` (mastery đọc `successInk`), không có
`infoInk` (A2 giữ `info` nguyên) — ruling R4.

### 1.4 GC-4 · Chữ

Một họ duy nhất: `PlusJakartaSans` (bundled, variable). `Inter` rời bundle,
`pubspec.yaml`, trang licence, test font loader và Widgetbook. `NotoSansKR` vẫn
là fallback CJK trên mọi style. Weight luôn set qua cả `fontWeight` **và** trục
`wght` (`AppTypography.withWeight`).

| Vai trò v3 | Size | Weight | Height | Tracking |
|---|---:|---:|---:|---:|
| caption | 12 | 600 | 1.4 | 1.2 |
| body | 14 | 400 | 1.5 | 0 |
| body large | 16 | 500 | 1.5 | 0 |
| title | 20 | 700 | 1.2 | −0.64 |
| headline | 24 | 700 | 1.2 | −0.64 |
| display | 32 | 800 | 1.1 | −0.64 |
| stat | 40 | 600 | 1.0 | −0.64 |

Mười lăm slot `TextTheme` (ruling R5 — bảng D1 2026-09-13):

| Slot | Vào vai trò |
|---|---|
| `displayLarge`, `displayMedium` | stat — 40 / 600 / 1.0 / −0.64 |
| `displaySmall`, `headlineLarge` | display — 32 / 800 / 1.1 / −0.64 |
| `headlineMedium`, `headlineSmall` | headline — 24 / 700 / 1.2 / −0.64 |
| `titleLarge` | title — 20 / 700 / 1.2 / −0.64 |
| `titleMedium`, `bodyLarge` | body large — 16 / 500 / 1.5 / 0 |
| `titleSmall`, `labelLarge` | 14 / 600 / 1.5 / 0 (size body, weight semibold — dẫn xuất) |
| `bodyMedium` | body — 14 / 400 / 1.5 / 0 |
| `bodySmall` | 12 / 400 / 1.4 / 0 (size caption, weight body — dẫn xuất) |
| `labelMedium` | 12 / 600 / 1.4 / 0.72 (caption tại tracking CSS `--memox-ls-label` — dẫn xuất) |
| `labelSmall` | caption — 12 / 600 / 1.4 / 1.2 |

Style có tên: `sectionLabelTracking` = **1.2** (CSS `--memox-ls-section`);
`stateChipTracking` 0.6 và `listHeadingTracking` 0.72 không đổi; `heroNumeral` =
bậc stat (`displayLarge`) + tabular figures + `heroNumeralCapTrim` (0.481, không
đổi), và `heroNumeralWeight` bị xoá (ruling R6); `cardPrompt` giữ 30 / 1.22 /
−0.5 / w600 và bản compact 26 (ruling R6, component style — chưa vào foundations).
Tập weight theme đọc được: đúng `{400, 500, 600, 700, 800}`.

**Nợ đã ghi khi áp dụng, chưa trả ở task này** (owned bởi task typography sau):
`AppTextStyles.sectionLabel` và `.sectionLabelSmall` nay byte-identical (cả hai
12/600/1.4/1.2) vì sàn caption 12px của v3 xoá mất bậc 11px cũ mà `sectionLabelSmall`
từng giữ; `MxSectionLabelRung.small` không còn hiệu ứng nhìn thấy được.

### 1.5 GC-5 · Ladder và state layer

| Token | Giá trị |
|---|---|
| `AppSpacing` | `xs 4 · sm 8 · md 12 · lg 16 · card 20 · xl 24 · xxl 32 · xxxl 48`; `scale` liệt kê đủ tám, đúng thứ tự |
| `AppRadius` | `xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · pill 999` (không có 28 — v3 không có call site) |
| `AppIconSize` | `sm 16 · mdCompact 20 · md 24 · lg 32 · xl 40` — `lg` cũ (40) đổi tên thành `xl`; `lg` mới là 32. `MxIconSize` theo cùng |
| `AppSizing.touchTarget` | 48, không đổi |
| `AppStateOpacity` hover | `hoverRow`, `hoverIcon`, `hoverControl`, `hoverCard`, `stateLayerHover` = **0.08** |
| `AppStateOpacity` pressed | `pressed`, `pressedCard`, `stateLayerPressed` = **0.12** |
| `AppStateOpacity` focus | `focus`, `stateLayerFocus` không đổi, 0.10 (spec im lặng — ruling R10) |

**Nợ đã ghi khi áp dụng, chưa trả ở task này:** hàng due-chip của deck row cao
24.8dp — text-driven (`bodySmall` 12/1.4 trong 4+4) — không rơi đúng lưới 4dp mà
v3 tự vẽ; bảng component của v3 tự chốt bằng chip cỡ cố định 28, cái này thuộc
spec Chip sau.

### 1.6 GC-6 · Bóng đổ (owner decision 6, 2026-09-13, trên giá trị v3)

`AppElevation` giữ bốn bậc (`none 0 · card 1 · raised 3 · overlay 8`) và
`materialShadowColor` không đổi (ruling R11 — Material component dark vẫn không
đổ bóng). `shadowsFor(level, scheme)`:

| Bậc | Light (màu = `scheme.shadow` `#0F1638`) | Dark (màu = `scheme.shadow` `#000000`) |
|---|---|---|
| `card` | `0 1 2` tại 4% (v3 `shadow-soft`) | chỉ rim: `BoxShadow(color: outlineVariant, spreadRadius: AppStroke.hairline)` |
| `raised` | `0 12 32` tại 10% (v3 `shadow-card`) | rim + `0 16 40` tại 42% |
| `overlay` | `0 8 24` tại 12% (v3 `shadow-fab`) | rim + `0 10 28` tại 50% |

Viết dạng `offsetY blurRadius` tại alpha; không spread cho drop; một lớp light
mỗi bậc. Bóng `Chrome` của v3 không được khai báo (ruling R9 — chưa có caller;
spec bottom-nav sở hữu).

### 1.7 GC-7 · Composition

- `mxScreenGutter(context)` trả `AppSpacing.lg` (16) ở mọi bề rộng.
- `mxScrollEndInsetOf(context)` trả `AppSpacing.xxxl` (48) khi không có floating
  action, và `AppSpacing.fabScrollClearance + MediaQuery.viewPaddingOf(context).bottom`
  khi có, với `fabScrollClearance = AppSizing.floatingAction + AppSpacing.lg +
  AppSpacing.xxxl`.
- `applyCompactScale` không còn ghi đè `listTileTheme.contentPadding` hay
  `titleLarge`; vẫn giữ compact card prompt và compact button padding.

---

## 2. Alias layer — resolve theo spec, không phát minh token mới

Spec gọi các role M3 ở trên bằng tên riêng ở một số chỗ (`colors_and_type.css`).
Yêu cầu của spec là **resolve về role đã có trong repo**, không tạo hằng số mới
cho một cái tên chỉ là bí danh.

| Alias | Light / Dark (spec) | Resolve về |
|---|---|---|
| `bg` | `#F7F9FE` / `#0A0E27` | = `surface` → `scheme.surface` |
| `surface-raised` | `#FFFFFF` / `#131A3A` | fill `.card` → `scheme.surfaceContainerLowest` |
| `surface-muted` | `#F1F4FB` / `#1B2249` | TextField nghỉ, fill Note → `scheme.surfaceContainerLow` (= `AppSurfaceColors.paper`) |
| `surface-hero` | primary 5%/12% trộn nền | Hero card tint → `AppSurfaceColors.surfaceEmphasisLight/Dark` (`#F6F7FE` / `#191F41`) |
| `primary-border` | primary 24%/32% | Viền primary alpha thấp → `AppBorderColors.borderAccentLight/Dark` (`#D5DAFD` / `#394379`) |
| `danger` | `#DC2D4E` / `#FF8FA3` | = `error` → `scheme.error` (= `AppColors.dangerLight/Dark`) |
| `on-danger` | `#FFFFFF` / `#2A0A12` | = `onError` → `scheme.onError`. **Lưu ý:** literal dark của alias (`#2A0A12`) khác `onError` dark đã khai báo (`#52061B`, mục 1.1) — resolve về role có sẵn theo đúng yêu cầu của spec, không tạo hằng số `onDanger` riêng cho chênh lệch này |
| `success-soft` | success 10%/18% | Success tint → `AppColors.successContainerLight/Dark` (`#EAF6F3` / `#243E52`) |
| `warning-soft` | warning 12%/18% | Warning tint → `AppColors.warningContainerLight/Dark` (`#FEF3E2` / `#3D393F`) |
| `on-warning` | `#3A2A00` / `#2A1E00` | Ink trên fill warning → `AppColors.onWarningContainer` = `warningInk`. Light khớp literal (`#3A2A00`); **dark cố ý lệch** — `warningInk` dark dùng fill `#FFC658` chứ không phải literal alias `#2A1E00` (owner answer A1) |
| `progress-track` | `#E2E7F3` / `#2C356E` | = `surfaceContainerHigh` → `AppColors.progressTrackLight/Dark` |
| `badge-bg` | `#E9EDF7` / `#232B5A` | = `surfaceContainer`, "declared, no v3 call site" — dùng thẳng `scheme.surfaceContainer`, không cần hằng số riêng tên `badge` |
| `border-strong` | viền 1px `outlineVariant` | → `AppBorderColors.borderSubtleLight/Dark` (= `scheme.outlineVariant`) |
| `shadow-soft` | `0 1px 2px rgba(15,22,56,.04)` / none | Bóng "whisper" của card → `AppElevation.card` qua `shadowsFor()` (mục 1.6) |
| `shadow-none` | none cả hai theme | → `AppElevation.none` |
| `radius-button` | 12px cả hai | → `AppRadius.md` |
| `radius-input` | 12px cả hai | → `AppRadius.md` |
| `radius-chip` | 999px cả hai | → `AppRadius.pill` |
| `radius-fab` | 16px cả hai | → `AppRadius.lg` |

### R7 — màu v3 mới, chưa có hằng số Dart (ghi lại, không khai báo)

Ruling R7: repo từ chối khai báo một màu không ai render ("a colour with no
caller is a colour nobody is checking"), và spec cũng chỉ yêu cầu resolve alias
đã có caller. Các alias/role dưới đây **không có consumer hôm nay**, nên chỉ ghi
hex ở đây; mỗi cái sẽ vào Dart cùng lúc với spec component cần nó ("declared with
its first caller"):

| Tên (spec) | Light / Dark | Ghi chú |
|---|---|---|
| `chrome-glass` | `rgba(247,249,254,.84)` / `rgba(10,14,39,.84)` | Bottom-nav glass; spec bottom-nav sẽ khai báo |
| `primary-soft` | primary 10%/20% trộn trong suốt | Tonal tint cho action/tile; chưa có caller |
| `danger-soft` | error 8%/16% trộn trong suốt | ErrorState tile tint; chưa có caller |
| `danger-border` | error 22%/32% trộn trong suốt | Viền destructive; chưa có caller |
| ~~`border-ghost`~~ | `rgba(82,101,245,.14)` / `rgba(139,154,255,.16)` | **Đã khai báo ở M100.116** — `AppBorderColors.borderGhost*` / `AppSemanticColors.borderGhost`, caller đầu tiên là `MxFilterChip` (viền chưa chọn). Dòng này giữ lại làm hồ sơ của hex gốc; hàng Guess của Match vẫn chưa có caller |
| `error-fill` | `#DC2D4E` / `#B0485C` | Fill **đặc** cho nút destructive — khác `error` ở dark; spec Button đã khai báo (M100.112) |
| `on-error-fill` | `#FFFFFF` cả hai | Nhãn trên `error-fill`; đi cùng ở trên |
| `mastery` | `#1F8A5B` / `#6FE0BD` | Không có `masteryInk` riêng — khái niệm mastery dùng `success`/`successInk` (ruling R4); hex này chỉ để tra cứu |
| `mastery-fixed` | `#C7F2D8` / `#1F4A37` | Tint mastery bất biến theo theme; chưa có caller |
| `streak` / `on-streak` | `#F97316` / `#FFAE6E` (streak), `#FFFFFF` cả hai (on-streak) | Hex "cam" gốc **không** được dùng trực tiếp — `AppColors.streakContainer`/`onStreakContainer` hiện có đã trỏ sang `warningContainer`/`onWarningContainer` thay vì hai giá trị này (mục 1.2) |
| `status new/learning/reviewing/mastered` | `#8C95B8`/`#6B75A3` · `#F59E0B`/`#FFC658` · `#5265F5`/`#8B9AFF` · `#1F8A5B`/`#6FE0BD` | Trùng giá trị với các role/alias đã có (`warning`, `primary`, `mastery`) nhưng chưa có hằng số `status*` riêng; spec badge trạng thái sẽ quyết định dùng thẳng role hay đặt tên mới |
| `text muted` (ink) | fill `#7C85AB` / `#5A6BAE` — trùng hex với `outline` | Fill đã có vai (`outline`); **ink** riêng cho chữ "text-muted" chưa được tính trong GC-3 (bảy ink ở mục 1.3 không có mục này) — component cần chữ mực thứ ba sẽ là caller đầu tiên |

---

## 3. Đổi tên radius và icon — CSS ↔ Dart (R8)

Ruling R8: hai ladder spacing và radius lớn thêm **không đổi tên**; ladder icon
đổi đúng một tên (`lg → xl`) để có chỗ cho 32. Đây là bảng map, vì tên CSS và tên
Dart không khớp theo cùng một quy luật ở mọi bậc.

**Radius** — cột "role của spec" là mục dùng trong handoff (mục 219–234 của spec,
không phải tên biến CSS); cột Dart là `AppRadius` sau task này:

| Giá trị | Vai trò trong spec | Symbol Dart |
|---:|---|---|
| 4 | Checkbox 20px | `AppRadius.xs` |
| 8 | Icon tile 28, nút compact | `AppRadius.sm` |
| 12 | Button, input, note, snackbar, icon tile 36–44 (`radius-button`, `radius-input`) | `AppRadius.md` |
| 16 | FAB, bottom-nav bar (`radius-fab`) | `AppRadius.lg` |
| 20 | Card, **DIALOG**, **BOTTOM-SHEET**, empty-state tile 64 | `AppRadius.xl` |
| 24 | "No call site in v3" — nhưng CSS vẫn khai báo biến `--radius-xl` tại giá trị này (ruling R8) | `AppRadius.xxl` |
| 28 | "No call site in v3" | không có symbol — `AppRadius` không có bậc 28 |
| 999 | Pill — chip, badge, toggle track, grabber, progress track (`radius-chip`) | `AppRadius.pill` |

**Vì sao 20 và 24 đổi chỗ giữa hai tên:** CSS đặt tên `--radius-xl` cho bậc **24**
(bậc không có call site nào trong v3); Dart đặt tên `AppRadius.xl` cho bậc **20**
— bậc mà Card/Dialog/BottomSheet thực sự dùng. Cùng một từ `xl`, khác bậc, vì
ladder Dart đặt tên theo bậc nào có call site thật, không theo vị trí trong thang
CSS. Đọc "`xl`" ở CSS và ở Dart mà không tra bảng này sẽ lấy nhầm 24 thành 20 hoặc
ngược lại.

**Icon** — trước task này `AppIconSize` không có bậc 32; `lg` là 40. Task này
thêm 32 và đổi tên bậc 40 để nhường chỗ:

| Giá trị | Vai trò trong spec | Symbol Dart (sau task) | Trước task |
|---:|---|---|---|
| 16 | Inline | `AppIconSize.sm` | không đổi |
| 20 | Compact control | `AppIconSize.mdCompact` | không đổi |
| 24 | Standard action | `AppIconSize.md` | không đổi |
| 32 | Large emphasis | `AppIconSize.lg` | **chưa tồn tại** |
| 40 | Illustrative | `AppIconSize.xl` | tên cũ là `lg` — đổi tên ở 5 call site |

`MxIconSize` đổi theo `AppIconSize` cùng lượt.

---

## 4. Rulings chốt trước khi triển khai (R1–R13)

Spec im lặng hoặc mơ hồ ở từng điểm dưới đây. Copy nguyên văn từ
`docs/superpowers/plans/2026-09-17-memox-v3-foundations.md`, mục "Rulings made
before execution" — mỗi dòng ghi kèm cái giá phải trả nếu ruling sai.

| ID | Ruling | Vì sao | Giá nếu sai |
|---|---|---|---|
| R1 | Binding surface, fill, radius, height của component không đổi (card vẫn `surfaceContainerLow`, FAB vẫn `primaryContainer`, indicator nav vẫn `secondaryContainer`, chip vẫn `surfaceContainerLow`/`secondaryContainer`, track switch vẫn `surfaceContainerHighest`). | Spec nói foundations không sở hữu biến thể component, và P1 để "surface treatment, radius, geometry class" cho từng spec component. | Tới khi spec Card ra đời, card light là `#F1F4FB` trên nền `#F7F9FE` — một panel viền hairline **thấp hơn** page một bậc. |
| R2 | Mười hai role `*Fixed` lấy đúng literal của CSS. | CSS khai báo sẵn; sinh tone sẽ tạo ra giá trị bịa. | Mười hai literal phải trỏ lại. |
| R3 | Binding slot chữ **có** dời sang ink (Task 3). | A1 là luật về chữ, không phải về một component. | Phải revert các dòng slot của Task 3. |
| R4 | Không có `masteryInk` (mastery đọc `successInk`), không có `infoInk` (A2 giữ `info`; đo 5.17 trên page). Một ink đỏ duy nhất cho `danger`, `error`, `overdue`. | Mastery và success dùng chung một họ xanh lá; `info` giữ nguyên như đã ship. | Một ink phải thêm sau. |
| R5 | Bảng slot `TextTheme` ở mục 1.4 (bảng D1 2026-09-13). | CSS map bảy size vào mười một slot; bốn slot còn lại lấy role gần nhất theo size, và hai cặp dẫn xuất giữ weight M3 cho slot đó. | Các dòng slot phải trỏ lại, golden vẽ lại. |
| R6 | `heroNumeral` thành role stat (spec gọi stat là "Large metric, tabular numerals"); `cardPrompt` giữ số đo riêng tới khi có spec flashcard. | Hero numeral **chính là** con số lớn; card prompt là style của component. | Hero thư viện 32 → 40 hiện rõ ở một màn. |
| R7 | Màu v3 mới chưa có caller (`mastery`, `status*`, `streak`, `on-streak`, `on-warning` dạng fill ink, `error-fill`, `on-error-fill`, `mastery-fixed`, các alpha `*-soft`/`*-border`, `chrome-glass`, ink text-muted) **được ghi lại, không khai báo Dart** (bảng mục 2). | Repo từ chối khai báo màu không ai render, và spec cũng chỉ yêu cầu resolve alias đã có, không tạo token mới. | Mỗi spec component thêm một, hai hằng số. |
| R8 | Ladder radius và spacing lớn thêm không đổi tên; ladder icon chỉ đổi tên `lg → xl` (5 call site) để có chỗ cho 32. | Diff nhỏ nhất mà vẫn giữ đủ mọi giá trị v3, đúng thứ tự. | Tên lệch với CSS (`radius-xl` là 24 ở CSS, 20 ở đây); mục 3 ghi lại map. |
| R9 | Không có bậc bóng `chrome`, không có hằng số glass. | Chưa có caller; spec bottom-nav sẽ sở hữu. | Thêm một bậc cùng spec nav. |
| R10 | Alpha state-layer của focus giữ 0.10. | Spec chỉ liệt kê hover, pressed, disabled và glass. | Hai hằng số. |
| R11 | Material component ở dark vẫn không đổ bóng (`materialShadowColor` không đổi). | Ở mức component; decision 6 chi phối `shadowsFor`, thứ mà surface của app dùng. | Một spec dialog/FAB sẽ đổi lại. |
| R12 | Contrast gate quay lại ở Task 8–9: chữ phải đạt 4.5:1 qua ink của nó; một cạnh/dot/fill/track không phải chữ mà hex v3 đưa xuống dưới 3:1 thì ghim đúng số đo (owner decision 5). | M100.84 đã tắt các gate này chính vì lượt đổi palette này. | Sàn ghim lại khi một spec component re-bind. |
| R13 | ID của WBS entry chọn ngay trước khi push (`git log --all` census); placeholder `M100.97`. | PR chạy song song giành số. | Một commit đổi số. |

---

## 5. Xem thêm

- Handoff nguyên văn: `docs/superpowers/specs/2026-09-17-memox-v3-foundations.md`
- Kế hoạch triển khai và log quyết định: `docs/superpowers/plans/2026-09-17-memox-v3-foundations.md`
- Lý luận kiến trúc màu (AD-14): [`ad-14-color-and-depth.md`](ad-14-color-and-depth.md)
- Layering `lib/core/theme/`: [`theme-architecture.md`](theme-architecture.md)
- Tiến độ và acceptance criteria: `../wbs.md` (M100.97)
