# FilledButton — đối chiếu component spec với `MxActionButton.primary`

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract "FilledButton" (MemoX HTML design kit, mục B · Buttons & actions) với `MxActionButton(variant: MxActionButtonVariant.primary)` + `buildFilledStyle(pair: MxFilledPair.brand)` đã triển khai: xác nhận dimension table, icon, ma trận trạng thái và ba mục P0 |
| **Scope** | Đối chiếu dimension table, icon, state matrix và implementation handoff của FilledButton (kit) với `mx_action_button.dart` / `app_button_themes.dart` / `app_interaction_states.dart`. Ngoài phạm vi: TonalButton và FloatingActionButton (spec riêng — `tonal-button-spec.md`, `floating-action-button-spec.md`), giá trị token gốc (AD-14), thay đổi bất kỳ hợp đồng đóng băng nào |
| **Source of truth for** | Kết quả đối chiếu spec FilledButton (kit) ↔ `MxActionButton.primary` |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/v1-freeze.md` · `design-system/tokyo-component-mapping.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-13 |

---

## 0. Tài liệu này là gì, và không phải là gì

Nguồn: MemoX HTML design kit, mục *B · Buttons & actions*. HTML design kit đã
bị xoá ở M100.83 (#541, "the CSS kit goes") — spec gốc (nguyên văn ở §1) là bản
ghi duy nhất còn lại của mục này trong repo.

**Đây không phải một implementation task.** `MxActionButton` với
`variant: MxActionButtonVariant.primary` đã tồn tại và chạy production từ
trước khi prompt gốc được viết; role của nó (`primary`/`onPrimary`) đã được
`tokyo-component-mapping.md` §2 ghi là canonical và giữ bởi
`m3_role_binding_guard_test.dart` (dòng "FilledButton | background | `primary`
... | = | ... guard AST (M100.36)"). Tài liệu này đối chiếu spec với code
thật, không tự ý đổi bất kỳ dòng nào trong hợp đồng đã đóng băng.

File đã đọc: `mx_action_button.dart`, `app_button_themes.dart`,
`app_interaction_states.dart` (`AppStateOpacity`), `app_icon_size.dart`,
`v1-freeze.md`, `tokyo-component-mapping.md`.

## 1. Hợp đồng component (nguyên văn từ prompt gốc — binding)

Mục đích: Primary CTA — one per view. Nature: production component.

**Dimension table gốc:**

| Dimension | Class |
|---|---|
| state | enabled/pressed/disabled — CONTENT-DRIVEN |
| icon | leading — CONTENT-DRIVEN |

**Icon** (Lucide, ánh xạ theo nghĩa): `play`.

**State matrix gốc:**

| Trạng thái | Vẽ |
|---|---|
| `default` | primary fill, onPrimary label |
| `pressed` | 8% onPrimary overlay [INFERRED] |
| `disabled` | 38% opacity trên fill và label [INFERRED] |
| `loading` | label swaps to a 16px onPrimary spinner, width held |

## 2. Đối chiếu — dimension table

| Dimension | Class (kit) | Hành vi đã triển khai | Verdict |
|---|---|---|---|
| state | CONTENT-DRIVEN | `buildFilledStyle` resolves `backgroundColor`/`foregroundColor`/`overlayColor` qua `WidgetStateProperty.resolveWith` theo đúng ba trạng thái (`disabled` → role riêng; `pressed`/`focused`/`hovered` → state layer) — [mx_action_button.dart:270-275](../../lib/shared/widgets/mx_action_button.dart:270), [app_button_themes.dart:211-264](../../lib/core/theme/components/actions/app_button_themes.dart:211) | **Khớp** |
| icon | CONTENT-DRIVEN, leading | `icon: IconData?` tuỳ chọn, `iconSide` mặc định `leading`, vẽ ở `AppIconSize.sm` (16) — kit không liệt icon size là dimension FIXED cho riêng FilledButton (khác IconButton), nên không có gì để lệch | **Khớp** |

## 3. Icon

Kit: `play` — một glyph ví dụ (khớp nghĩa "Start/Study", không phải một phần
cố định của component: FilledButton không tự vẽ glyph, `icon` do caller
truyền). Không mâu thuẫn.

## 4. Ma trận trạng thái

| Trạng thái | Kit | Thật | Verdict | Bằng chứng |
|---|---|---|---|---|
| `default` | primary fill, onPrimary label | `MxFilledPair.brand.fillOf` = `scheme.primary`, `.labelOf` = `scheme.onPrimary` | **Khớp** | [app_button_themes.dart:128-138](../../lib/core/theme/components/actions/app_button_themes.dart:128) |
| `pressed` | 8% onPrimary overlay [INFERRED] | State layer `onPrimary` @ `stateLayerPressed` = **0.10**, không phải 0.08 — 0.08 là *hover*, không phải press | **Lệch số, cơ chế khớp** | [app_button_themes.dart:229-241](../../lib/core/theme/components/actions/app_button_themes.dart:229), [app_interaction_states.dart:72-74](../../lib/core/theme/states/app_interaction_states.dart:72) |
| `disabled` | 38% opacity trên **fill và label** [INFERRED] | Không phải một alpha-blend của cùng màu: **role đổi hẳn** — fill → `semantic.disabledSurface` (một mặt màu trung tính, giải solid), label → `semantic.onDisabled` (`onSurface` @ ~38.04%, đo từ `0x61/255`) | **Lệch cơ chế, có chủ đích** | [app_button_themes.dart:214-224](../../lib/core/theme/components/actions/app_button_themes.dart:214); alpha: [text-button-spec.md §2.3](text-button-spec.md) đã đo `0x61 ≈ 38.04%` cho cùng token |
| `loading` | label swaps to 16px onPrimary spinner, width held | `_ForegroundSpinner`, `AppIconSize.sm` = **16** — khớp đúng số; width held bằng `Stack` + `Opacity(0, alwaysIncludeSemantics: true)` giữ layout cũ | **Khớp** | [mx_action_button.dart:458-463](../../lib/shared/widgets/mx_action_button.dart:458), [app_icon_size.dart:9](../../lib/core/theme/foundations/app_icon_size.dart:9) |

**Vì sao pressed lệch số mà không phải một defect.** Kit ước lượng một số
[INFERRED] duy nhất cho "pressed"; SDK thật (`_FilledButtonDefaultsM3`, đã
transcribe ở `v1-freeze.md` §6) phân biệt ba trạng thái — hover 0.08, focus
0.10, pressed 0.10 — nên "8%" của kit đúng cho hover, không đúng cho press.
Đây là giới hạn của việc suy luận từ một bản mock tĩnh không có hover/focus,
không phải một chỗ code sai.

**Vì sao disabled lệch cơ chế mà vẫn đúng.** Kit hình dung disabled là "cùng
fill, mờ đi 38%" — hợp lý cho một mock không chạy runtime. Thật ra một fill
`primary` mờ 38% và một fill `primary` mờ 38% đặt trên hai nền khác nhau (card
sáng, card tối) sẽ ra hai màu khác nhau; `disabledSurface` là một mặt màu độc
lập với accent, đã giải solid — đúng nguyên tắc "một cơ chế disabled cho mọi
button" mà `buildFilledStyle` áp dụng cho cả ba pair (`brand`, `tonal`,
`destructive`), không phải một xử lý riêng của FilledButton.

**Hai trạng thái kit không liệt kê, code có:** `hovered` (0.08) và `focused`
(0.10, cộng thêm ring viền `onPrimary` vì `_FilledButtonDefaultsM3` không khai
`side` — [app_button_themes.dart:253-263](../../lib/core/theme/components/actions/app_button_themes.dart:253)).

## 5. SYSTEM-OWNED / không copy nguyên văn — không áp dụng

Không mục nào trong bảy mục kit liệt (status bar, cutout, gesture/nav inset,
keyboard inset, system Back, device bezel, absolute positioning, `::after`,
`backdrop-filter`, `color-mix`, hover kiểu web, fake system chrome, hộp pixel
cố định quanh chữ) liên quan `FilledButton`; ghi lại để người đọc sau không tự
hỏi lại.

## 6. Hợp đồng đóng băng đang che component này

`v1-freeze.md` §2: vai trò (#1, #2 — `primary`/`onPrimary`, giữ bởi
`m3_role_binding_guard_test.dart`), mapping ThemeData (#3), public contract
của shared primitive (#6), floor 48dp (#7), ripple/state (#8), chính sách
raw Material (#13 — `no_raw_button`). Tài liệu này không đề xuất sửa gì trong
số đó.

## 7. Kết luận

`FilledButton` đã triển khai đầy đủ hợp đồng của kit. Dimension table, icon và
hai trong bốn trạng thái khớp gần như chính xác (`default`, `loading`); hai
trạng thái còn lại (`pressed`, `disabled`) lệch so với phỏng đoán `[INFERRED]`
của kit nhưng đúng với cơ chế canonical M3 đã ghi ở `v1-freeze.md` §6 — không
phải defect, không cần task follow-up.
