# ListTile · deck row — đặc tả từ MemoX HTML kit

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Dịch component "ListTile · deck row" (MemoX HTML design kit · C · Surfaces, cards & list items) sang hợp đồng Flutter/memox — token, icon, state — và đối chiếu với kiến trúc hàng đã có trong repo trước khi ai đó implement |
| **Scope** | Hình học, icon, state matrix của riêng component này, và điểm nó xung đột với code/kiến trúc hiện tại. Ngoài phạm vi: giá trị token nền tảng (đã đóng băng, xem AD-14 và `v1-freeze.md`), quyết định có build lại màn Library hay không — đó là quyết định của chủ dự án, nêu ở §5 chứ không tự chốt ở đây |
| **Source of truth for** | Bảng đối chiếu dimension/icon/state của "ListTile · deck row" so với `MxListTile` + `DeckIconArea` hiện có |
| **Depends on** | `document-conventions.md` · `tokyo-component-mapping.md` §7 · `v1-freeze.md` §2/§3/§3a · `architecture.md` (AD-14, AD-15) |
| **Updated by task** | chưa có task ID trong `wbs.md` — sinh từ prompt "ListTile · deck row" trên nhánh `claude/listtile-deck-row-spec-a9a136`, chưa gán WBS |
| **Last updated** | 2026-09-12 |

---

## 1. Nguồn và điều kiện tiên quyết chưa có

Prompt gốc yêu cầu chạy "MemoX Foundations spec" một lần trước đặc tả này, để
tài liệu đó cấp palette (hai theme), type scale, thang spacing/radius/icon/
elevation. Tại thời điểm viết tài liệu này, worktree song song
`memox-design-foundations-a8d2f8` **sạch** — chưa có commit, chưa có tài liệu
Foundations nào tồn tại trong repo.

Vì vậy tài liệu này **không** chờ một tài liệu Foundations trung gian; nó đọc
thẳng token đã đóng băng hiện có trong repo (AD-14, `theme-architecture.md`,
các file `lib/core/theme/foundations/*.dart`) làm nền — nguồn cấp giá trị cho
mọi ô ở §2 là code, không phải suy đoán từ kit.

Repo chạy song song hơn chục worktree "*-design-spec-*" khác (avatar,
breadcrumb, card, divider, fab, filledbutton, iconbutton, icontile, listrow,
navigationbar, outlined-button, sectionheader, settingstile, studytopbar,
textbutton, tonalbutton — cùng một mẫu prompt, khác component). Tại thời điểm
rebase tài liệu này lên `origin/main`, năm cái đã merge và xác nhận đúng một
khuôn: `docs/design-system/<component>-spec.md`, đối chiếu dimension/state
kit với widget đã ship, không kèm task implement — `card-spec.md` (#544, "đã
compliant"), IconButton (#545, "một caller-level revert cần tôn trọng" — nêu
đúng tình huống của tài liệu này: áp spec kit sẽ đảo một quyết định on-device
gần hơn kit tĩnh, và đó là việc của điều kiện mở lại #6, không phải của task
đặc tả), OutlinedButton (#546), TextButton (#547), Avatar (#543 — trường hợp
duy nhất "forward-looking", vì component đó chưa có implementation để đối
chiếu). Tài liệu này theo đúng khuôn đó: **sản phẩm là tài liệu đặc tả, không
phải code.**

---

## 2. Hình học — đối chiếu dimension

| Dimension (kit) | Lớp (kit) | Ánh xạ Flutter | Token thật |
|---|---|---|---|
| leading | icon-tile, CONTENT-DRIVEN | `DeckIconArea` (đã có, `lib/features/deck/presentation/widgets/items/deck_icon_area_widget.dart`) | Ô vuông `AppSizing.touchTarget` (48), bo góc `AppRadius.md` (12), nền `context.semanticColors.surfaceMuted`, glyph `AppInk.accent` qua `MxIcon` |
| title + meta subtitle | — | `MxListTile.title` / `.subtitle` (`lib/shared/widgets/mx_list_tile.dart`) | `ListTileThemeData` cấp content padding, `minVerticalPadding`; subtitle dùng `context.texts.bodyMedium!.inked(context, AppInk.quiet)` khi enabled |
| chiều cao hàng | — | `ListTileThemeData.minTileHeight` | `AppSizing.rowMinHeight` (56) — đã nêu tường minh ở `tokyo-component-mapping.md` §2 dòng `ListTile \| minTileHeight`, không phải 48 (48 là sàn chạm, 56 là hàng đọc) |
| shape | — | `ListTileThemeData.shape` | `Border()` — hình chữ nhật, **không** bo góc riêng (M100.37): hàng luôn nằm trong một card/sheet đã có góc của chính nó |
| trailing | ring / chevron / kebab, CONTENT-DRIVEN | `MxListTile.trailing` | Xem §2.1 — ba biến thể không tương đương nhau về hợp đồng |

**MUST** dùng token thật ở cột phải cho mọi implementation về sau — không ai
được viết lại `48`, `12`, `56` bằng số trần khi có thể viết `AppSizing.
touchTarget`, `AppRadius.md`, `AppSizing.rowMinHeight` (guard
`no_raw_spacing_literal` / `no_raw_border_radius` sẽ bắt số trần dù sao).

### 2.1. `trailing` — ba biến thể, một xung đột

Kit gộp ring/chevron/kebab vào một dimension "CONTENT-DRIVEN", nhưng
`tokyo-component-mapping.md` §7 nói **trailing của `MxListTile` chỉ trình
bày** (chevron, số đếm, glyph) — một control tự hành động không thuộc về nó.

| Biến thể kit | Có sẵn trong repo? | Ghi chú |
|---|---|---|
| chevron | Có — mẫu hình, chưa có caller deck cụ thể | Trình bày thuần, đúng hợp đồng `MxListTile.trailing` |
| kebab (nút overflow) | Có, nhưng **không** nằm trong một `MxListTile` — `DeckTileWidget` đặt `MxIconButton(icon: Icons.more_vert)` làm anh em của khối `Column`, không phải `trailing` của một `ListTile` | Một kebab thật (nút bấm được) đặt vào `trailing` sẽ tạo lồng gesture-arena hai lớp — đúng thứ `tokyo-component-mapping.md` §7 cấm ("Trailing chỉ trình bày... control tự hành động là `MxSwitchRow`/`MxCheckboxRow`/`MxRadioRows`", không phải một biến thể khác của `MxListTile.trailing`) |
| **mastery ring** | **Không tồn tại** — `grep -ri mastery lib/` không ra kết quả nào trong domain hay presentation của deck | Xem §5b — đây là khái niệm mới, chưa có định nghĩa số liệu |

**SHOULD** tách kebab ra khỏi định nghĩa "trailing CONTENT-DRIVEN" khi viết
task implementation: nó không cùng hợp đồng với chevron/ring, và gộp ba thứ
vào một prop `trailing: Widget?` (như `MxListTile` đã làm) là đúng cho
chevron/ring nhưng cần một quyết định riêng nếu kebab thật sự cần đứng trong
hàng này.

---

## 3. Icon — "layers" không nên trở thành một glyph deck thứ ba

Kit dùng tên Lucide `layers`. Prompt yêu cầu ánh xạ theo **ý nghĩa**, giữ một
glyph cho một khái niệm xuyên suốt app — và app này **đã có** khái niệm đó,
đóng ở một cặp glyph nhị phân. Đếm thật trong `lib/` (không tính test):
`Icons.style_outlined` xuất hiện ở 11 file, `Icons.folder_outlined` ở 11 file
khác, hợp thành 17 file duy nhất (một số file — như
`deck_status_icon_widget.dart`, `deck_create_child_widget.dart`,
`study_home_body_section_widget.dart`, `deck_result_tile_widget.dart`,
`trash_row_widget.dart` — dùng cả hai, chọn theo `contentType` tại chỗ):

| content_type | Glyph hiện dùng | Ví dụ (không đủ, xem grep để có danh sách đầy đủ) |
|---|---|---|
| deck chứa card (`DeckContentType.card`) | `Icons.style_outlined` — "a stack of cards" (nguyên văn doc comment) | `deck_status_icon_widget.dart:50-52`, `card_list_screen.dart`, `deck_card_handoff_widget.dart` |
| deck chứa sub-deck / `unset` (BR-63) | `Icons.folder_outlined` | `deck_status_icon_widget.dart:52`, `app_navigation_shell.dart` (icon tab), `deck_ancestors_widget.dart`, `card_bulk_overlays_widget.dart` (`_TargetList`, xem §5c) |

`Icons.layers_outlined` **có** xuất hiện trong repo, đúng một lần
(`card_editor_context_widget.dart:161`, size `MxIconSize.sm`) — một glyph nhỏ
trong ngữ cảnh breadcrumb của trình soạn thẻ, không phải glyph định danh deck.

**MUST NOT** thêm `Icons.layers_outlined` làm glyph deck thứ ba — đúng theo
câu prompt tự đặt ra ("keep the meaning stable across every screen that uses
it"). "Layers" và "a stack of cards" là cùng một ý; `style_outlined` /
`folder_outlined` theo `contentType`, giống hệt `DeckStatusIconWidget`, đã là
glyph mang đúng ý đó. Việc kit chọn tên Lucide khác không đổi ý nghĩa nó vẽ.

---

## 4. State matrix — hai trong ba entry `[INFERRED]` sai so với hợp đồng đã có

| State (kit) | `[INFERRED]`? | Đối chiếu `MxListTile` hiện tại |
|---|---|---|
| default | không | Khớp — `MxListTile` không tự vẽ fill khi không chọn, "trong suốt trên bề mặt card" đúng như hành vi hiện tại |
| pressed | có — "8% primary tint" | **Không tự đưa số 8% vào bất kỳ implementation nào.** Giá trị thật đã có chủ — `AppInteractionStates.rowOverlay(context.colors)` — và đây là **định nghĩa duy nhất mọi hàng trong app dùng chung** (`mx_list_tile.dart` dòng 116, 156-158). Nếu con số của resolver đó khác 8%, hàng deck **MUST** vẫn đọc từ resolver, không hard-code theo kit — trùng giá trị hôm nay không có nghĩa nó được phép trở thành hai định nghĩa |
| selected | có — "primaryContainer row" | **Sai, đã có câu trả lời khác và đã kiểm chứng.** `MxListTile.isSelected` tô `semantic.surfaceSelected` cho fill và `primary` cho title (doc comment dòng 99-103 của `mx_list_tile.dart`) — "bề mặt đã-chọn duy nhất do app sở hữu, dùng chung với tint của `MxCard`" (M100.36 §4I). `primaryContainer` không phải role được dùng ở đây trong toàn app |

Không có ô nào trong bảng này cần "confirm" theo nghĩa thử nghiệm — hai trong
ba đã có câu trả lời xác định trong code, và bảng trên là bằng chứng, không
phải đề xuất.

---

## 5. Xung đột cần chủ dự án quyết định, không tự chốt ở đây

### 5a. "The backbone of Library" đối đầu trực tiếp với quyết định M4.12

Contract gọi component này là **"the backbone of Library"** — tức hàng chính
của danh sách deck. Nhưng hàng đó, `DeckTileWidget`
(`lib/features/deck/presentation/widgets/items/deck_tile_widget.dart`), có
một dòng ghi rất tường minh trong chính doc comment của nó:

> "**It stopped being an `MxListTile` at M4.12.** A `ListTile` puts everything
> on one baseline at a fixed height, which reads as a row in a table — every
> deck the same weight, nothing to scan for."

`tokyo-component-mapping.md` §7 xác nhận lại quyết định đó ở tầng tài liệu
kiến trúc: bảng ranh giới hàng liệt kê **"deck tile"** làm ví dụ của `MxCard`
("một thực thể... mà nhóm và độ sâu của chính nó mang nghĩa"), không phải của
`MxListTile`.

`v1-freeze.md` §2 đóng dòng thứ 71 rằng **composition của màn hình nghiệp vụ
không đóng băng** — nên về mặt kỹ thuật, đổi `DeckTileWidget` từ `MxCard` sang
`MxListTile` không phạm một trong 14 hợp đồng đóng băng. Nhưng §3a (reopen
record M100.73) mô tả đúng loại thay đổi này — "chủ dự án chủ động đổi hình
thức của component đã có" — và đòi **điều kiện số 6**: "kèm tham chiếu thị
giác cụ thể (mockup, ảnh chụp, bản dựng)". Bảng dimension trích từ kit ở đặc
tả này không phải là tham chiếu thị giác đó.

**Nếu đảo quyết định M4.12 thật sự là ý định**, ba khối chức năng
`DeckTileWidget` đang mang sẽ mất chỗ đứng nếu ép vào ba slot của
`MxListTile` (leading / title+subtitle / trailing):

- workload line (`7 Due · 14 New`, `DeckWorkloadLineWidget`),
- progress gauge + phần trăm học (`_DeckGauge`, gắn với BR-88 — success chỉ ở
  100%),
- nút Study (`DeckStudyButtonWidget` — "the control that opens a session",
  M100.71).

"Mastery ring" ở trailing có thể là câu trả lời thay cho progress gauge, nhưng
đó là suy đoán của tài liệu này, không phải sự thật đã kiểm — xem §5b.

**Đề xuất:** task này dừng lại ở đặc tả. Việc build lại `DeckTileWidget` theo
form ListTile — có hay không, và nếu có thì workload/progress/Study đi đâu —
cần một quyết định tường minh riêng của chủ dự án, đi kèm tham chiếu thị giác
theo đúng điều kiện 6 đã ghi ở `v1-freeze.md`.

### 5b. "Mastery ring" là khái niệm chưa tồn tại

`grep -ri mastery lib/` không trả về kết quả nào trong domain hay presentation
của deck. `DeckSummary` hiện phơi `learnedFraction`, `dueCardCount`,
`overdueDayCount`, `totalCardCount`, `subDeckCount` — không có trường
"mastery". Trước khi bất kỳ ai vẽ một ring, cần chủ dự án trả lời: mastery có
phải `learnedFraction` đổi hình dạng biểu diễn (thanh → vòng tròn), hay là một
chỉ số khác (ví dụ theo scheduler — `eight_box` box hiện tại của thẻ, hay
điểm ease của `sm2`)? Hai khả năng cho hai use case rất khác nhau và
`AppInk.success` chỉ được dùng ở đúng một mốc (BR-88, 100% learned) — một ring
mastery cần cùng một quy tắc màu, không phải quy tắc mới.

### 5c. Hàng `MxListTile` cho deck **đã tồn tại**, ở hai chỗ — nhưng vẫn không khớp contract này

Hai nơi trong repo hôm nay dùng `MxListTile` cho một deck, không phải một:

- `move_deck_sheet_widget.dart` (`_TargetRow`) — leading là **radio** (ngữ
  nghĩa chọn-một, `isSelected`/`inMutuallyExclusiveGroup`), subtitle là lý do
  từ chối (`rejection`, có điều kiện) chứ không phải meta line, không có
  trailing.
- `card_bulk_overlays_widget.dart` (`_TargetList`, sheet "move cards to
  deck") — leading là một `Icon(Icons.folder_outlined)` trần (không qua
  `DeckIconArea`, không có well/tint), subtitle **là** một meta line thật
  (`target.parentName` — tên deck cha), không có trailing, và tap xác nhận
  ngay chứ không qua bước chọn-rồi-xác nhận.

Cái thứ hai gần hình dạng contract hơn (leading là glyph định danh chứ không
phải radio, subtitle là meta thật) nhưng vẫn thiếu icon-tile well và mọi
trailing. Áp trực tiếp contract "icon-tile + meta + ring/chevron" vào một
trong hai picker này vẫn là một thay đổi, không phải một khớp có sẵn.

Nói cách khác: **không có bề mặt nào trong app hôm nay khớp contract này
nguyên trạng.** Đây có thể là một hàng cho một màn chưa tồn tại (duyệt/tìm
deck dạng phẳng) hơn là một chỉnh sửa của các bề mặt đã có.

---

## 6. P0 changes — đã đóng, không cần làm lại

Prompt liệt "palette + both themes, type scale, 16 gutter and spacing rhythm"
là P0. Cả bốn đã có trong repo: palette Tokyo thay toàn bộ 45 role ở M100.83
(#541), type scale và gutter 16 (`AppSpacing.lg`) đã là nền hiện hành. Component
này compose hoàn toàn từ token đã đóng băng, không tự định nghĩa token mới —
không có việc P0 nào phải làm riêng cho "ListTile · deck row".

---

## 7. Việc KHÔNG làm trong task này, và vì sao

Task này **không** sửa `deck_tile_widget.dart`, không sửa
`move_deck_sheet_widget.dart`, không thêm widget `Mx*` mới, không đăng ký
Widgetbook. Lý do: §5a-c cho thấy còn ba quyết định của chủ dự án chưa có câu
trả lời, và implement trước khi có câu trả lời là chính xác thứ
`v1-freeze.md` §3 cấm ("merge một phần thay đổi để mở đường"). Tài liệu này
cũng không sửa `docs/wbs.md`: 17 worktree "*-design-spec-*" đang chạy song
song từ cùng một `main` (§1), nên gán một task ID ở đây trước khi biết
worktree nào trong số đó thực sự merge trước sẽ tạo xung đột số ngay từ vòng
đầu — task ID nên được gán một lần, sau khi biết task nào còn sống.
