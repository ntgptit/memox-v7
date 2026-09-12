# Card — đối chiếu component spec với `MxCard` đã triển khai

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract "Card" (MemoX HTML design kit, mục C) với `MxCard` đã triển khai, và ghi lại rằng không có implementation gap — mọi dimension trong spec gốc đã được thoả bởi hành vi hiện có, đã đóng băng, đã test |
| **Scope** | Đối chiếu dimension table + state matrix của prompt gốc với `mx_card.dart` / `card-recipes.md` / `v1-freeze.md`. Ngoài phạm vi: giá trị token gốc (AD-14), thay đổi bất kỳ hợp đồng đóng băng nào (việc của một task design-system riêng, xem §4) |
| **Source of truth for** | Kết quả đối chiếu spec Card (kit) ↔ implementation; điểm [INFERRED] nào của spec gốc khớp hoặc lệch với giá trị thật đang chạy |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14, AD-15) · `design-system/v1-freeze.md` · `design-system/card-recipes.md` · `design-system/tokyo-component-mapping.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-12 |

---

## 0. Tài liệu này là gì, và không phải là gì

Nguồn: MemoX HTML design kit, mục *C · Surfaces, cards & list items*. Kit đã bị
xoá ở M100.83 (#541) — spec gốc (nguyên văn ở §1) là bản ghi duy nhất còn lại
của mục này.

**Đây không phải một implementation task.** `MxCard` đã tồn tại từ M99.70, đã
qua tám milestone chỉnh (M99.94, M99.95, M99.98, M100.32, M100.33, M100.35,
M100.36…) và một phần hợp đồng của nó đã **đóng băng** ở `v1-freeze.md` §2
dòng 8 (ripple/state) và dòng 10 (#435, depth) từ trước khi spec này được
viết. Tài liệu này đối chiếu spec với code thật, không đề xuất thay đổi nào.

File đã đọc để đối chiếu: `mx_card.dart`, `app_interaction_states.dart`,
`app_elevation.dart`, `app_radius.dart`, cộng ba tài liệu design-system liệt ở
header.

## 1. Hợp đồng component (nguyên văn từ prompt gốc — binding)

| Dimension | Class | Giá trị gốc |
|---|---|---|
| border | CONTENT-DRIVEN | ghost 15% |
| radius | FIXED | lg / md |

State matrix gốc: light = fill trắng (`#FFFFFF`), border NONE, radius 20,
padding 20, shadow `0 1px 2px rgba(15,22,56,.04)`; dark = cùng fill/radius,
shadow bỏ, thay bằng viền ghost 1px; pressed = primary 8% tint **[INFERRED —
prompt tự ghi: mock không vẽ trạng thái này, 8% là suy từ giá trị hover của
icon-button]**.

## 2. Đối chiếu — từng dimension

| Yêu cầu | Trong `MxCard` hôm nay | Bằng chứng |
|---|---|---|
| radius `lg` / `md` FIXED | `AppRadius.lg = 16`, `AppRadius.md = 12` — đúng hai giá trị, dùng bởi `.raised` (lg) và `.tile` (md) | [app_radius.dart:10,13](../../lib/core/theme/foundations/app_radius.dart:10) |
| light: fill trắng, border NONE | fill = `surfaceContainerLow`, role M3 đã guard, resolve `#FFFFFF` trong light; resting edge `subtle` → `null` | [mx_card.dart:591-602](../../lib/shared/widgets/mx_card.dart:591), [mx_card.dart:653-657](../../lib/shared/widgets/mx_card.dart:653), [tokyo-component-mapping.md:103](tokyo-component-mapping.md:103) |
| light: shadow nhẹ | shadow hai lớp phái sinh trực tiếp từ Tokyo `shadows.cardSm` (float + seat), không phải một shadow đơn như spec mô tả — trung thực với kit gốc hơn bản tóm gọn trong prompt | [app_elevation.dart:166-190](../../lib/core/theme/foundations/app_elevation.dart:166) |
| dark: bỏ shadow, thay viền ghost 1px | ở elevation `card`, dark chỉ vẽ `outlineVariant` hairline, không shadow — khớp mô tả | [app_elevation.dart:116-121](../../lib/core/theme/foundations/app_elevation.dart:116) |
| icon: none | `MxCard` không tự vẽ glyph nào | [mx_card.dart:157-478](../../lib/shared/widgets/mx_card.dart:157) |
| "Base container: `surfaceContainerLowest`" (đầu prompt) | không khớp fill của recipe nền (`surfaceContainerLow`) — dòng này trùng mô tả của `.recessed`, đọc như boilerplate của template chung cho nhiều component trong lô prompt này, không phải một yêu cầu riêng cho Card | [card-recipes.md:29-40](card-recipes.md:29) |

Giá trị thô "radius 20 / padding 20 / #FFFFFF" trong state matrix gốc là số đo
trực tiếp từ CSS đã bị xoá của kit; đã dịch đúng sang token (`lg`/`md`,
`surfaceContainerLow`) theo đúng chỉ dẫn "không copy literal" của chính
prompt — không phải một gap.

## 3. Điểm [INFERRED] — pressed state, và vì sao không sửa theo

Giá trị thật đang chạy: `primary @ 10%` (`AppStateOpacity.pressedCard = 0.10`),
chép trực tiếp từ `.mx-card__action:active` của kit — **chính xác hơn** con số
8% mà spec tự suy luận từ nút icon.

| | |
|---|---|
| Spec [INFERRED] | primary 8%, tự ghi "cần xác nhận" |
| Code thật | `primary` @ 10%, nguồn `mx.css` gốc | [app_interaction_states.dart:47,134-140](../../lib/core/theme/states/app_interaction_states.dart:47) |

Dòng này thuộc hợp đồng đã đóng băng — `v1-freeze.md` §2 dòng 8 (ripple/state,
giữ bởi `component_depth_and_state_test`). Một task component **MUST NOT**
đổi nó theo suy luận của spec, kể cả khi spec tự nhận là suy luận — giá trị
đang chạy đã có bằng chứng mạnh hơn (chính là dòng CSS spec đang đoán).

## 4. Kết luận

Không có task implement. Mọi FIXED value trong dimension table đã là hằng số
đang dùng thật (`AppRadius.lg/md`); mọi state trong state matrix đã có test
giữ (`mx_card_test.dart`, `mx_card_mobile_test.dart`, `mx_card_recipes_test.dart`,
`mx_card_interaction_test.dart`, `component_depth_and_state_test.dart`); danh
sách "không copy literal" của prompt gốc (absolute positioning, `::after`,
`backdrop-filter`, `color-mix`, hover-only, fake chrome, hộp pixel cố định)
không xuất hiện ở `mx_card.dart` — API đóng, không tham số màu/viền/radius nào
lộ ra ngoài (§ đầu `mx_card.dart`).

Nếu sau này cần đổi thật giá trị nào ở §3 (ví dụ chủ dự án muốn pressed tint
nhạt hơn), đó là điều kiện mở lại #6 của `v1-freeze.md` §3 — chủ dự án chỉ
định kèm tham chiếu thị giác cụ thể — không phải việc một task component tự
suy ra từ một dòng [INFERRED] trong spec kit đã xoá.
