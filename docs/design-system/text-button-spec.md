# TextButton — đối chiếu component spec với `MxTextButton` đã triển khai

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract của TextButton trong MemoX HTML design kit (mục B · Buttons & actions) với implementation đã triển khai (`MxTextButton`, `buildTextButtonTheme`), ghi lại điểm khớp và điểm lệch có chủ đích |
| **Scope** | Dimension (tone), icon, ma trận trạng thái của kit gốc đối chiếu với `lib/shared/widgets/mx_text_button.dart` và `lib/core/theme/components/actions/app_button_themes.dart`. Ngoài phạm vi: thay đổi implementation (không cần thiết — xem §7), giá trị token nền (AD-14), vai trò M3 nào ánh xạ role nào (đã có ở `tokyo-component-mapping.md`) |
| **Source of truth for** | Kết quả đối chiếu spec TextButton (kit) ↔ implementation; điểm [INFERRED] nào của spec gốc khớp hoặc lệch với giá trị thật đang chạy — không phải nguồn gốc của role mapping hay giá trị token |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/v1-freeze.md` · `design-system/tokyo-component-mapping.md` · `design-system/ad-14-color-and-depth.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-12 |

---

## 0. Tài liệu này là gì, và không phải là gì

Bản dịch component contract (nguồn: MemoX HTML design kit, mục *B · Buttons &
actions*) của TextButton sang trạng thái đã triển khai. **Khác với
`avatar-spec.md`: TextButton không chờ triển khai** — nó đã có `MxTextButton`,
`buildTextButtonTheme`, và nhiều call site production từ trước khi prompt này
được viết. Tài liệu này vì vậy không phải một đặc tả chờ sẵn, mà là một bản
đối chiếu: kit yêu cầu gì, code đã làm gì, hai bên khớp ở đâu và lệch ở đâu —
và với chỗ lệch, vì sao lệch là quyết định đúng chứ không phải nợ.

HTML design kit đã bị xoá ở M100.83 (#541, "the CSS kit goes"). Giá trị trong
tài liệu này đọc thẳng từ `lib/core/theme/` và `lib/shared/widgets/`, không
chép lại từ kit. File đã đọc: `mx_text_button.dart`, `app_button_themes.dart`,
`app_interaction_states.dart`, `app_semantic_colors.dart`, `app_colors.dart`,
`app_ink.dart`.

**"MemoX Foundations spec" mà prompt gốc yêu cầu chạy trước không tồn tại ở
dạng đã commit** — cùng phát hiện `avatar-spec.md` đã ghi cùng ngày: không có
file, không có PR, không có branch nào mang nội dung đó. Tài liệu này tự đọc
thẳng từ nguồn thay vì chờ một phiên khác.

## 1. Hợp đồng component, từ prompt gốc (binding)

**Mục đích.** Inline link-style action.

**Dimension:**

| Dimension | Class | Giá trị |
|---|---|---|
| `tone` | CONTENT-DRIVEN | `primary` \| `error` |

**Icon.** "none — component này không tự vẽ glyph nào."

**Ma trận trạng thái, từ prompt gốc:**

| Trạng thái | Vẽ |
|---|---|
| `default` | không fill, nhãn màu primary |
| `pressed` | tint 8% của primary phía sau nhãn [INFERRED] |
| `disabled` | nhãn 38% [INFERRED] |

## 2. Đối chiếu

### 2.1 `tone` → `isDestructive`

Kit đặt tone là một content class hai giá trị. Implementation không có enum
`Tone` riêng (khác `MxDialogTone` mà `MxAlertDialog`/`MxConfirmDialog`/
`MxFormDialog` dùng) — `MxTextButton` nhận `isDestructive`, `bool`, mặc định
`false`
([mx_text_button.dart:38](../../lib/shared/widgets/mx_text_button.dart:38)):

| Giá trị kit | API thật | Resolve tới |
|---|---|---|
| `primary` | `isDestructive: false` (mặc định), không set `accent` | `_accentStyle` trả `null` → không style riêng → theme mặc định (`buildTextButtonTheme`) tô `colors.primary` — cùng giá trị `AppInk.accent` sẽ cho nếu caller tự set nó vào `accent` |
| `error` | `isDestructive: true` | ép `AppInk.danger` → `semantic.danger`, bất kể `accent` là gì |

`danger` và `error` không phải hai màu đỏ khác nhau — doc comment của
`MxFilledPair.destructive` ghi rõ: *"`error` is `danger` in this palette, so
this is not a second red."* Hai tên khác nhau vì hai đường đọc khác nhau (ink
cho chữ, role cho fill), cùng một hue.

`isDestructive` là boolean, không phải enum — khác khuyến nghị mà chính
`mx_action_button.dart` viết cho biến thể của nó ("carried by the enum and not
by an `isDestructive` flag plus a colour"). Đây là API đã ship, có caller
production; đổi thành enum là việc của một task design-system riêng theo
`v1-freeze.md` §3 điều kiện #6, không phải việc của một tài liệu đối chiếu.

### 2.2 Icon

Kit: không glyph nào là một phần cố định của component. Thật: `MxTextButton`
nhận `icon`/`trailingIcon: IconData?` tuỳ chọn cho caller cần một glyph biên
(vd. `Icons.expand_more` trên link "mở rộng"). Không mâu thuẫn — glyph do
caller truyền vào, không phải glyph component tự vẽ.

### 2.3 Ma trận trạng thái

| Trạng thái | Kit [INFERRED] | Thật | Khớp? |
|---|---|---|---|
| `default` | không fill, nhãn primary | `overlayColor: transparent`, `foregroundColor` = `colors.primary` qua `textLinkForeground` | Khớp |
| `pressed` | tint 8% primary phía sau nhãn | **Không có tint/fill nào** (`overlayColor: transparent`, `splashFactory: NoSplash`) — nhãn tự đổi màu: lerp 28% về `onSurface` ([`AppStateOpacity.textPressedBlend = 0.28`](../../lib/core/theme/states/app_interaction_states.dart:85)) | Lệch có chủ đích — xem dưới |
| `disabled` | nhãn 38% | `semantic.onDisabled` = [`Color(0x61313133)` light / `Color(0x61E3E3E6)` dark](../../lib/core/theme/foundations/app_colors.dart:86) — alpha `0x61` = 97/255 ≈ **38.04%** | Khớp gần như chính xác |

**Vì sao pressed lệch, và vì sao lệch là đúng.** Doc comment của
`buildTextButtonTheme` nói thẳng lý do: *".mx-textbtn is the one control in
the kit with no surface to wash", "so its states are carried by the text
itself."* Một text button không có nền để tint; tô 8% primary phía sau một
nhãn không khung/không nền sẽ vẽ một vệt màu không cạnh rõ ràng — đúng loại
"fake surface" mà hợp đồng #13 của `v1-freeze.md` §2 (`no_raw_button`) đang
chặn cho cả họ nút. Cơ chế thật (blend màu chữ) đã qua guard và test
(`component_depth_and_state_test`); tint nền chưa từng tồn tại trong code.

**Hai trạng thái kit không liệt kê, code có:**

| Trạng thái | Thật |
|---|---|
| `hovered` | nhãn lerp 15% về `onSurface` ([`AppStateOpacity.textHoverBlend = 0.15`](../../lib/core/theme/states/app_interaction_states.dart:82)) |
| `focused` | gạch chân dưới nhãn, độ dày `AppStroke.focus`, màu = màu nhãn đã blend — vì không có viền để vẽ ring |

## 3. Token mapping — đọc từ `lib/core/theme/`

**Hình học.** Padding zero, floor cao 48
([`AppSizing.touchTarget`](../../lib/core/theme/foundations/app_sizing.dart)),
floor rộng 0 (không phải 64 của Material — một link tự pad ra sẽ lệch cạnh
trailing so với nội dung khác trong cột), căn `centerStart`.

**Chữ.** `labelLarge`, re-weight qua `AppTypography.withWeight` lên
`buttonLabelWeight = FontWeight.w700` — cùng trọng số ba họ nút chia sẻ, không
phải một giá trị riêng cho text button.

**Overlay/ripple.** `Colors.transparent` + `NoSplash.splashFactory` — khác
`MxActionButton`'s outlined/filled, vốn dùng
`AppInteractionStates.controlOverlay` làm state layer thật. Đây là hệ quả
trực tiếp của việc "no surface to wash" ở §2.3, không phải một thiếu sót.

## 4. Vượt ra ngoài hợp đồng gốc

API thật rộng hơn contract của kit — không trái hợp đồng, vì kit không cấm mở
rộng, chỉ không yêu cầu:

- `isCompact` — hạ nhãn xuống rung `labelMedium`, cho một link chia hàng với
  heading 12sp.
- `accent: AppInk?` — đổi ink không-destructive khi caller có lý do thật
  (M100.5: trước đó bốn feature tự truyền `context.colors.onErrorContainer`
  bằng tay); mặc định `null` giữ `AppInk.accent`.
- `semanticLabel` — tên accessible khác nhãn hiển thị, cho link mà nhãn là
  một giá trị chứ không phải một hành động (WCAG 2.5.3).

## 5. SYSTEM-OWNED / không copy nguyên văn — không áp dụng

Từ prompt gốc: status bar, cutout, gesture/nav inset, keyboard inset, nút Back
hệ thống, khung thiết bị, absolute positioning, `::after` hit expander,
`backdrop-filter`, `color-mix`, hover kiểu web, fake system chrome, hộp pixel
cố định quanh chữ — không mục nào liên quan `TextButton`; ghi lại để người đọc
sau không tự hỏi lại.

## 6. Hợp đồng đóng băng đang che component này

Component này nằm dưới nhiều dòng của `v1-freeze.md` §2 cùng lúc: vai trò
(#1, #2 — `TextButton` foreground = `primary`, giữ bởi
`m3_role_binding_guard_test.dart`), mapping ThemeData (#3), public contract
của shared primitive (#6 — `shared_api_closure_test`), floor 48dp (#7), hành
vi ripple/state (#8), chính sách restyle chữ (#12 — `no_text_restyle`), sở
hữu raw Material (#13 — `no_raw_button`).

Tài liệu này **không đề xuất sửa gì** trong số đó. Bất kỳ thay đổi nào lên
tone/state mechanism mô tả ở §2 đều phải qua điều kiện mở lại của
`v1-freeze.md` §3, không phải qua việc sửa tài liệu đối chiếu này.

## 7. Kết luận

TextButton đã triển khai đầy đủ hợp đồng của kit. Một trong hai giá trị
[INFERRED] đúng gần như chính xác (disabled, 38.04% ≈ 38%); giá trị còn lại
(pressed) bị thay bởi một cơ chế khác — không phải vì kit sai, mà vì kit suy
luận từ ngôn ngữ thiết kế chung trong khi code giải quyết đúng ràng buộc của
riêng control này (không có nền để tint). Không tìm thấy khoảng trống hay
defect nào cần một task follow-up.
