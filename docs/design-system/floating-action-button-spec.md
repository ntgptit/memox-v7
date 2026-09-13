# FloatingActionButton — đối chiếu component spec với `MxFab`

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract "FloatingActionButton" (MemoX HTML design kit, mục B · Buttons & actions) với `MxFab` + `buildFloatingActionButtonTheme` đã triển khai: xác nhận hình học/placement khớp, ghi lại xung đột thật ở màu fill (đã được adjudicate từ trước) |
| **Scope** | Đối chiếu dimension table, icon, state matrix của FAB (kit) với `mx_fab.dart` / `app_fab_theme.dart` / `mx_content_shell.dart`. Ngoài phạm vi: FilledButton, TonalButton (spec riêng), giá trị token gốc, thay đổi hợp đồng đóng băng |
| **Source of truth for** | Kết quả đối chiếu spec FAB (kit) ↔ `MxFab`; điểm nào khớp, điểm nào là xung đột đã biết và vì sao tài liệu này không tự sửa nó |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/v1-freeze.md` · `design-system/tokyo-component-mapping.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-13 |

---

## 0. Tài liệu này là gì, và không phải là gì

Nguồn: MemoX HTML design kit, mục *B · Buttons & actions*. HTML design kit đã
bị xoá ở M100.83 — spec gốc (§1) là bản ghi duy nhất còn lại của mục này.

**Đây không phải một implementation task.** `MxFab` đã tồn tại và chạy
production (`lib/shared/widgets/mx_fab.dart`), với doc comment của chính nó
nói rõ lý do tồn tại: *"Exists so no feature builds a `FloatingActionButton`
again"* — guard `no_raw_widget` cấm widget thô trong `lib/features/`.

File đã đọc: `mx_fab.dart`, `app_fab_theme.dart`, `mx_content_shell.dart`,
`app_elevation.dart`, `app_interaction_states.dart`, `v1-freeze.md`,
`tokyo-component-mapping.md`.

## 1. Hợp đồng component (nguyên văn từ prompt gốc — binding)

Mục đích: Extended FAB — 52dp tall, radius-lg 16, pinned bottom-right above
the safe area (or above the bottom nav via `.fab-above-nav`). Kit không có
biến thể tròn. Nature: production component. Closest Flutter/Material
equivalent theo prompt gốc: `FloatingActionButton[.extended]`.

**Dimension table gốc:**

| Dimension | Class |
|---|---|
| height | 52 · `--fab-h` — FIXED |
| radius | 16 · `radius-lg` — FIXED |
| placement | bottom-right / above nav — RESPONSIVE |

**Icon** (Lucide): `plus`.

**State matrix gốc:**

| Trạng thái | Vẽ |
|---|---|
| `default` | primary fill, onPrimary label + glyph, shadow-fab |
| `pressed` | shadow tightens, 8% onPrimary overlay [INFERRED] |

## 2. Đối chiếu — dimension table

| Dimension | Class (kit) | Hành vi đã triển khai | Verdict | Bằng chứng |
|---|---|---|---|---|
| height | FIXED, 52 | `MxFab` bọc `FloatingActionButton` (không `.extended`) — kích thước mặc định M3 là 56 tròn, **không phải** 52 | **Xung đột hình học nhẹ, xem dưới** | [mx_fab.dart:42-47](../../lib/shared/widgets/mx_fab.dart:42) |
| radius | FIXED, 16 (`radius-lg`) | `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))` — `AppRadius.lg` = 16 | **Khớp** | [app_fab_theme.dart:29-31](../../lib/core/theme/components/actions/app_fab_theme.dart:29) |
| placement | RESPONSIVE, bottom-right / above nav | `Scaffold.floatingActionButton: widget.floatingActionButton` bên trong `MxContentShell` — Scaffold M3 tự đặt FAB `endFloat` (bottom-right) và tự nới trên `bottomNavigationBar` khi có; không có code nào tự tính toạ độ | **Khớp — system/framework-owned** | [mx_content_shell.dart:211-217](../../lib/shared/widgets/mx_content_shell.dart:211) |

**Về height 52 vs 56.** Kit mô tả một FAB *extended* (có nhãn cạnh glyph) cao
52dp — kit tự ghi "The kit has no circular variant." `MxFab` hiện chỉ bọc
`FloatingActionButton` tròn tiêu chuẩn (glyph-only, không nhãn, cao mặc định
56 theo `_FABDefaultsM3`), không có API cho biến thể extended. Đây không phải
một lệch giá trị (52 so với 56) mà là **kit đặc tả một shape** (extended,
bo góc `radius-lg`, có nhãn) mà API hiện tại của `MxFab` không có tham số để
dựng — component contract của `MxFab` (đã đóng ở `v1-freeze.md` §2 dòng 6)
chỉ nhận `icon` + `label` (label dùng làm tooltip/semantic, không vẽ ra
màn hình). Ghi làm mục mở ở §6, không tự thêm biến thể vì đó là mở rộng public
API của một shared primitive.

## 3. Icon

Kit: `plus`. Thật: gọi qua `IconData icon` bắt buộc, do caller truyền
(`Icons.add` ở các call site hiện có). Không mâu thuẫn — glyph là tham số của
component, không phải một phần vẽ cứng.

## 4. Ma trận trạng thái

| Trạng thái | Kit | Thật | Verdict | Bằng chứng |
|---|---|---|---|---|
| `default` | **primary** fill, onPrimary label + glyph, shadow-fab | `primaryContainer` fill, `onPrimaryContainer` foreground | **Xung đột thật — xem §5** | [app_fab_theme.dart:20-24](../../lib/core/theme/components/actions/app_fab_theme.dart:20) |
| `pressed` | shadow tightens, 8% onPrimary overlay [INFERRED] | `splashColor: onPrimaryContainer @ AppStateOpacity.pressed = 0.12`; elevation **phẳng** ở cả bốn state (`AppElevation.overlay` cho enabled/focus/hover/highlight — không "tighten") | **Lệch số + lệch cơ chế shadow, có chủ đích** | [app_fab_theme.dart:46-68](../../lib/core/theme/components/actions/app_fab_theme.dart:46), [app_elevation.dart:29](../../lib/core/theme/foundations/app_elevation.dart:29) |

**Vì sao elevation không "tighten" khi press.** Doc comment của
`buildFloatingActionButtonTheme` ghi rõ (M100.35): elevation M3 canonical là
6/6/8/6 (resting/focus/hover/press — hover là 8, thứ Android không có con trỏ
để tạo ra), và app cố ý phẳng cả bốn ở `AppElevation.overlay` vì "release
target cannot reach" trạng thái hover. Kit hình dung một hiệu ứng bóng thay
đổi theo áp lực — desktop/web reasoning không áp dụng cho Android.

## 5. Mục còn mở — fill `primary` vs `primaryContainer` (KHÔNG giải quyết ở đây)

**Xung đột, và đã được adjudicate từ trước bởi chính đội ngũ này.** Kit đặc tả
FAB fill là `primary`/`onPrimary` — cùng màu FilledButton. Code thật dùng
`primaryContainer`/`onPrimaryContainer`, và doc comment của
`buildFloatingActionButtonTheme` ghi lại nguyên nhân: *"It was `primary`/
`onPrimary` from an owner mockup (2026-08-20)... The argument was sound and
the fix was in the wrong layer: it swapped one accent pair for another on the
component, which is exactly the substitution #426/#427 removed from five
other components."* Nói cách khác: **đúng yêu cầu kit** (`primary`/`onPrimary`)
đã từng được thử, và bị revert vì nó là một lần đổi role ngữ nghĩa
(`v1-freeze.md` §2 dòng 1/2) — `tokyo-component-mapping.md` §4 "Bốn binding"
liệt kê chính xác trường hợp này: "FAB bg/fg | `primaryContainer`/
`onPrimaryContainer` | Trước: `primary`/`onPrimary` | Sau: **canonical**".

**Tài liệu này MUST NOT đề xuất đổi FAB về `primary`/`onPrimary` theo kit, và
MUST NOT đề xuất bỏ yêu cầu đó khỏi hợp đồng kit.** Đường duy nhất để mở lại:
`v1-freeze.md` §3 điều kiện 6, với một tham chiếu thị giác cụ thể từ chủ dự
án — đúng điều kiện lần trước đã dùng để thử `primary`/`onPrimary`, và đã bị
đảo ngược sau khi đo. Nếu chủ dự án muốn thử lại, doc comment ở
`app_fab_theme.dart` đã nói sẵn hướng đi: "the answers are the
`primaryContainer` family's tone, or depth, geometry and placement — not this
slot."

**Mục mở thứ hai — biến thể extended.** Kit đặc tả một FAB có nhãn (extended,
cao 52); `MxFab` hiện chỉ có biến thể tròn glyph-only. Đây không phải một
defect — chưa có call site nào cần nhãn trên FAB — nhưng nếu một feature
tương lai cần, đó là một tham số mới trên một shared primitive đã đóng, nên
theo `v1-freeze.md` §3 điều kiện 3 (thêm họ/biến thể mới) chứ không phải việc
của một feature task tự thêm.

## 6. SYSTEM-OWNED / không copy nguyên văn

Placement "bottom-right / above nav" của kit là RESPONSIVE — thật ra hoàn
toàn system/framework-owned qua `Scaffold` (§2), nên không có kỹ thuật CSS nào
(`::after`, absolute positioning, `backdrop-filter`) có thể áp dụng hay bị vi
phạm ở đây. Không mục "DO NOT COPY LITERALLY" nào khác của kit liên quan.

## 7. Hợp đồng đóng băng đang che component này

`v1-freeze.md` §2: vai trò (#1, #2 — `primaryContainer`/`onPrimaryContainer`
canonical, giữ bởi `m3_role_binding_guard_test.dart` theo
`tokyo-component-mapping.md` §4), mapping ThemeData (#3), public contract của
shared primitive (#6 — `MxFab` chỉ nhận `icon`/`label`/`onPressed`), floor
48dp (#7 — FAB tự động thoả vì kích thước M3 vượt 48), ripple/state (#8), raw
Material (#13 — `no_raw_widget` cấm feature tự dựng `FloatingActionButton`).

## 8. Kết luận

`FloatingActionButton` đã triển khai đầy đủ phần hình học và placement của
kit (radius, vị trí). Một xung đột thật ở màu fill — kit muốn `primary`, app
dùng `primaryContainer` canonical — nhưng đây **không phải một gap chưa xử
lý**: nó đã được thử theo đúng hướng kit muốn, đo, và revert một cách có chủ
đích, ghi lại ngay trong doc comment của theme. Component cũng thiếu một biến
thể extended-with-label mà kit đặc tả nhưng chưa có call site nào cần. Cả hai
mục mở đều chờ đúng điều kiện của `v1-freeze.md` §3 (điều kiện 6 cho màu,
điều kiện 3 cho biến thể mới) nếu chủ dự án từng muốn.
