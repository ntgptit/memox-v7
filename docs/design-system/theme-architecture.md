# Theme architecture — `lib/core/theme/`

| | |
|---|---|
| **Status** | active |
| **Purpose** | Nói rõ mỗi loại quyết định thị giác sống ở tầng nào trong `lib/core/theme/`, và chiều phụ thuộc giữa các tầng |
| **Scope** | Cấu trúc thư mục, trách nhiệm từng tầng, public API của theme. Ngoài phạm vi: *giá trị* của token (AD-14), hợp đồng component-level (`.claude/skills/flutter-theme-design/`) |
| **Source of truth for** | Layering của `lib/core/theme/` · chiều import giữa các tầng · ranh giới public/internal của theme · bảng "cần gì thì đọc ở đâu" · ma trận dịch Tokyo → MemoX |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14, AD-23) |
| **Updated by task** | M100.30 |
| **Last updated** | 2026-09-03 |

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

**Ranh giới `components/` ↔ `app_theme.dart`.** Một file trong `components/`
chịu trách nhiệm cho **một** họ component, và "họ" được tính theo thứ mà một
quyết định chạm tới cùng lúc: `app_button_themes.dart` giữ bốn button vì chúng
dùng chung `buildSharedButtonStyle`, `app_modal_themes.dart` giữ dialog + bottom
sheet + snack bar vì cả ba phải trả lời "mode này có vẽ shadow không" và hai
trong ba dùng chung `modalBarrierColor`. `app_theme.dart` giữ đúng bốn thứ:
`ThemeData` base, các fall-through cấp framework (`hoverColor`, `canvasColor`,
`disabledColor`, `iconTheme`), extension, và danh sách slot → builder.

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
| `shadows.card` (dark) | rim thay shade | `AppColors.cardRimDark` |
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
