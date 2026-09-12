# StudyTopBar — đối chiếu component spec với `MxSessionTopBar` đã triển khai

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu component contract "StudyTopBar" (MemoX HTML design kit, mục A · Chrome & navigation) với `MxSessionTopBar` + `StudySessionFrameSectionWidget` đã triển khai: xác nhận phần đã thoả (dimension `progress`, icon, state matrix, cả ba mục P0), ghi lại phần còn lệch (accent cố định thay vì theo từng mode) và vì sao tài liệu này không tự sửa nó |
| **Scope** | Đối chiếu dimension table, icon mapping, state matrix, implementation handoff và ba mục P0 của prompt gốc với `mx_session_top_bar.dart` / `study_session_frame_section_widget.dart` / `v1-freeze.md`. Ngoài phạm vi: giá trị token gốc (AD-14), thay đổi bất kỳ hợp đồng đóng băng nào (việc của một task design-system riêng, xem §7) |
| **Source of truth for** | Kết quả đối chiếu spec StudyTopBar (kit) ↔ `MxSessionTopBar`; điểm nào của spec gốc đã khớp, điểm nào còn mở (accent theo mode) |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14) · `design-system/v1-freeze.md` · `design-system/tokyo-component-mapping.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-12 |

---

## 0. Tài liệu này là gì, và không phải là gì

Nguồn: MemoX HTML design kit, mục *A · Chrome & navigation*. HTML design kit
đã bị xoá ở M100.83 (#541, "the CSS kit goes") — spec gốc (nguyên văn ở §1)
là bản ghi duy nhất còn lại của mục này trong repo. Prompt gốc còn giả định
một tài liệu "MemoX Foundations spec" đọc trước; tài liệu đó cũng **không tồn
tại** trong repo này hay lịch sử git của nó (đã tìm trước khi viết) — tài
liệu này tự đọc thẳng `lib/core/theme/` thay cho nó, không chờ một phiên
khác dựng ra bản đó trước.

**Đây không phải một implementation task.** Component đã tồn tại và đã chạy
production:

- `MxSessionTopBar` — [lib/shared/widgets/mx_session_top_bar.dart](../../lib/shared/widgets/mx_session_top_bar.dart)
  — chrome của bar: nút đóng, chip mode, track tiến độ, figure cuối hàng.
- `StudySessionFrameSectionWidget` — [lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart](../../lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart)
  — compose bar vào khung phiên học đầy đủ (context line, hint line), dùng
  chung cho cả năm mode học.

Một phần hợp đồng của nó đã **đóng băng** ở `v1-freeze.md` §2, và bốn dòng
đó giới hạn những gì tài liệu này có quyền kết luận: danh tính 45 role của
`ColorScheme` (dòng 1) và nguyên tắc chỉ retune trong role, không đổi role
ngữ nghĩa (dòng 2) — cả hai ràng buộc kết luận ở §2/§7 rằng ink `AppInk.accent`
của chip không thể tự đổi thành một role khác theo mode; public contract của
shared primitive (dòng 6) — ràng buộc kết luận ở §4 rằng trạng thái của nút
đóng thuộc về `MxIconButton`, không phải thứ `StudyTopBar` tự định nghĩa
riêng; và chrome contract của `MxContentShell` (dòng 11, giữ một phần bởi
`study_session_chrome_test.dart`) — ràng buộc kết luận ở §5 về "system Back".
Tài liệu này đối chiếu spec với code thật, không tự ý đổi bất kỳ dòng nào
trong số đó.

File đã đọc để đối chiếu: `mx_session_top_bar.dart`,
`study_session_frame_section_widget.dart`, `mx_icon_button.dart`,
`mx_progress_bar.dart`, `mx_content_shell.dart`, `app_spacing.dart`,
`app_sizing.dart`, `app_icon_size.dart`, `app_breakpoints.dart`,
`app_ink.dart`, `v1-freeze.md`, `study_session_chrome_test.dart`,
`pubspec.yaml`.

## 1. Hợp đồng component (nguyên văn từ prompt gốc — binding)

Nature: production component. Closest Flutter/Material equivalent theo prompt
gốc: custom — AppBar + LinearProgress.

**Chú giải của chính prompt:** FIXED = tái tạo đúng giá trị; MINIMUM = không
được nhỏ hơn, lớn tự do; CONTENT-DRIVEN = nội dung quyết định, không đóng
khung cố định; RESPONSIVE = đổi theo bề rộng hoặc text scale; SYSTEM-OWNED =
platform cấp.

**Dimension table gốc:**

| Dimension | Class |
|---|---|
| accent | per study mode — CONTENT-DRIVEN |
| progress | current/total — CONTENT-DRIVEN |

**Icon** (tên Lucide, vì bản HTML preview không có Material Symbols): `x`. Ánh
xạ theo nghĩa, không theo tên; kích thước là phần cố định của hợp đồng, tên
glyph Lucide thì không.

**State matrix gốc:** non-interactive — không pressed, focused, selected hay
disabled.

**Implementation handoff gốc:**

- SYSTEM-OWNED, không tự vẽ: status bar (44 trong bản mock), cutout,
  gesture/nav inset, keyboard inset, system Back, device bezel.
- Không copy nguyên văn từ HTML/JSX: absolute positioning, `::after` hit
  expander, `backdrop-filter`, `color-mix` overlay, hover state, fake system
  chrome, hộp pixel cố định quanh chữ.
- P0: palette + cả hai theme, type scale, gutter 16 và spacing rhythm.

## 2. Đối chiếu — dimension table

| Dimension | Class (kit) | Hành vi đã triển khai | Verdict | Bằng chứng |
|---|---|---|---|---|
| accent | CONTENT-DRIVEN, per study mode | Một accent **cố định** cho mọi mode — chip inked bằng `AppInk.accent`, resolve về role `primary` — thay vì đổi theo mode; các mode phân biệt bằng chữ trên chip, không bằng màu | **Xung đột — ghi làm mục mở, xem §7** | Chip: [mx_session_top_bar.dart:249-254](../../lib/shared/widgets/mx_session_top_bar.dart:249); role: [app_ink.dart:92](../../lib/core/theme/extensions/app_ink.dart:92) (`AppInk.accent => colors.primary`); lý do thiết kế: [study_session_frame_section_widget.dart:28-34](../../lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart:28) |
| progress | CONTENT-DRIVEN, current/total | `MxProgressBar(value: progress, size: MxProgressBarSize.sm)`; `progress` là `progress.fraction` (0…1) do caller tính; track cao 4dp — rung mỏng nhất trong hai rung có sẵn (sm=4, md=8); tự vẽ "own colour family, never the accent" nên không dính xung đột accent ở trên | **Khớp** | Call site: [mx_session_top_bar.dart:208-209](../../lib/shared/widgets/mx_session_top_bar.dart:208); fraction: [study_session_frame_section_widget.dart:114](../../lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart:114); track height: [mx_progress_bar.dart:17-23](../../lib/shared/widgets/mx_progress_bar.dart:17); "never the accent": [mx_progress_bar.dart:32](../../lib/shared/widgets/mx_progress_bar.dart:32) |

## 3. Ánh xạ icon

| Lucide (kit) | Material dùng thật | Bằng chứng |
|---|---|---|
| `x` | `Icons.close`, vẽ ở `AppIconSize.mdCompact` (20) trong hộp `AppSizing.touchTarget` (48×48) | Call site: [mx_session_top_bar.dart:165-170](../../lib/shared/widgets/mx_session_top_bar.dart:165); glyph/box: [mx_icon_button.dart:144-155](../../lib/shared/widgets/mx_icon_button.dart:144); hằng số: [app_icon_size.dart:15](../../lib/core/theme/foundations/app_icon_size.dart:15), [app_sizing.dart:33](../../lib/core/theme/foundations/app_sizing.dart:33) |

**Đính chính khẳng định "the app ships Material Symbols" của prompt gốc —
khẳng định đó SAI cho repo này.** `pubspec.yaml` không khai bất kỳ package
Material Symbols nào: chỉ có comment về Cupertino Icons
([pubspec.yaml:34-35](../../pubspec.yaml:34)) và cờ `uses-material-design:
true` cấp font Material Icons cổ điển
([pubspec.yaml:161-164](../../pubspec.yaml:161)). Grep `material_symbols` /
`MaterialSymbols` trên `pubspec.yaml`, `pubspec.lock` và toàn bộ `lib/` không
khớp dòng nào. App dùng hằng số `Icons.*` (Material Icons cổ điển) như
`Icons.close` ở trên — đây là bản dịch đã đúng từ trước, không phải một gap
cần sửa.

## 4. Ma trận trạng thái

Kit: non-interactive — không pressed, focused, selected hay disabled. Đối
chiếu từng phần tử của bar, không phần nào cần đánh dấu `[INFERRED]` vì cả
bốn đều xác nhận được trực tiếp từ code:

- **Chip (mode label): xác nhận non-interactive.** Doc comment của chính
  `_Chip` nói rõ đây **không** phải `MxPillButton` với callback null — một
  callback null sẽ render như *disabled* (38% alpha, rời khỏi palette); đây
  là một cái tên, không phải một control bị tắt
  ([mx_session_top_bar.dart:223-227](../../lib/shared/widgets/mx_session_top_bar.dart:223)).
- **Track và trailing figure: xác nhận non-interactive.** Cả hai chỉ là
  `Expanded(MxProgressBar(...))` và widget `trailing` do caller truyền vào,
  không có `GestureDetector`/`onTap` nào bọc quanh
  ([mx_session_top_bar.dart:208-215](../../lib/shared/widgets/mx_session_top_bar.dart:208)).
- **Nút đóng (✕): đây là phần tử kit không tách riêng nhưng thực tế MANG hợp
  đồng trạng thái đầy đủ, kế thừa từ `MxIconButton`.** `MxIconButton` bọc một
  `IconButton` Material thật
  ([mx_icon_button.dart:122](../../lib/shared/widgets/mx_icon_button.dart:122)),
  nên nó mang đủ pressed/hover/focus/disabled qua `IconButtonThemeData` —
  đúng như doc comment của chính widget: "Size comes from `AppIconSize` and
  the 48×48 minimum from `IconButtonThemeData`"
  ([mx_icon_button.dart:61-65](../../lib/shared/widgets/mx_icon_button.dart:61)).
  Đây là hợp đồng public của một shared primitive đã đóng băng
  (`v1-freeze.md` §2 dòng 6: [v1-freeze.md:48](../../docs/design-system/v1-freeze.md:48)),
  không phải thứ `StudyTopBar` tự định nghĩa lại.

Kết luận: kit's "non-interactive" đúng cho ba trong bốn phần tử của bar
(chip, track, trailing figure); nút đóng là ngoại lệ tất yếu — nó là lối ra
duy nhất của phiên học (BR-82) nên buộc phải là một control thật, và bar
không tự vẽ thêm state nào ngoài cái `MxIconButton` đã cấp sẵn.

## 5. Implementation handoff — SYSTEM-OWNED / DO NOT COPY LITERALLY

**SYSTEM-OWNED — đã đúng, có bằng chứng cho phần chạm tới `StudyTopBar`.**
Trong sáu mục kit liệt (status bar, cutout, gesture/nav inset, keyboard
inset, system Back, device bezel), năm mục đầu là chrome cấp platform mà cả
hai file này không đụng tới ở bất kỳ dòng nào (đọc toàn bộ, không có
`SafeArea` hay MediaQuery inset nào bị vẽ đè trong chúng). Mục thứ sáu —
**system Back — đáng nói riêng vì nó là mục duy nhất có nguy cơ bị vi phạm
ngầm (một `AppBar` suy luận từ route sẽ tự thêm nút Back), và app đã làm
đúng, có test ghim:** `study_session_chrome_test.dart` push
`StudySessionScreen` qua một `Navigator` thật rồi khẳng định `MxSessionTopBar`
có mặt, còn `AppBar` và `BackButton` thì không
([study_session_chrome_test.dart:117-120](../../test/features/study/presentation/study_session_chrome_test.dart:117)).
Đây đúng là hệ quả của BR-82 (rời phiên chỉ qua ✕) mà
`study_session_frame_section_widget.dart` ghi lại tại chỗ
([study_session_frame_section_widget.dart:23-26](../../lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart:23)),
và là một phần của hợp đồng chrome đã đóng băng của `MxContentShell`
(`v1-freeze.md` §2 dòng 11: [v1-freeze.md:53](../../docs/design-system/v1-freeze.md:53)).

**DO NOT COPY LITERALLY — không áp dụng được nên không có gì để vi phạm.**
Bảy mục kit liệt (absolute positioning, `::after` hit expander,
`backdrop-filter`, `color-mix` overlay, hover state, fake system chrome, hộp
pixel cố định quanh chữ) đều là khái niệm CSS/JSX không có phép chiếu Flutter
1-1. Đọc toàn bộ `mx_session_top_bar.dart`: layout dùng `Padding` / `Row` /
`LayoutBuilder` / `ConstrainedBox` thường — không `Positioned`, không hiệu
ứng blur, không hộp kích thước cố định quanh `Text` (chip và figure đều
`maxLines: 1` + `TextOverflow.ellipsis`, co theo nội dung, không phải hộp
pixel cứng).

## 6. Tình trạng ba mục P0

| Mục P0 | Đã thoả? | Bằng chứng |
|---|---|---|
| Palette + cả hai theme | **Có.** Không màu nào trong bar là hex cứng: chip fill đọc `context.semanticColors.surfaceMuted`, chip ink đọc `AppInk.accent` → `colors.primary`. Cả hai đi qua `ColorScheme`/`SemanticColors` của theme đang active nên light/dark tự động đúng — đây chính là hợp đồng "45 role là danh tính chuẩn" đã đóng băng | fill: [mx_session_top_bar.dart:236](../../lib/shared/widgets/mx_session_top_bar.dart:236); ink: [mx_session_top_bar.dart:254](../../lib/shared/widgets/mx_session_top_bar.dart:254), [app_ink.dart:92](../../lib/core/theme/extensions/app_ink.dart:92); hợp đồng: [v1-freeze.md:43](../../docs/design-system/v1-freeze.md:43) (dòng 1) |
| Type scale | **Có.** Không cỡ chữ hay weight nào viết tay: chip dùng rung `sectionLabel` + `FontWeight.w600`, context line dùng `sectionLabelSmall`, figure cuối hàng dùng `labelMedium` với `isEmphasized`/`isTabular` — cả ba đều là style đặt tên, không phải số bịa | chip: [mx_session_top_bar.dart:249-254](../../lib/shared/widgets/mx_session_top_bar.dart:249); context line: [study_session_frame_section_widget.dart:189](../../lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart:189); figure: [study_session_frame_section_widget.dart:247-252](../../lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart:247) |
| Gutter 16 và spacing rhythm | **Có, xác nhận đúng ở đúng mốc đo 393dp của chính widget.** `mxScreenGutter` trả `AppSpacing.lg` (16) khi bề rộng ≥ `AppBreakpoints.compact` (360), `AppSpacing.md` (12) khi nhỏ hơn; ở 393dp — mốc đo trong doc comment của widget — 393 > 360 nên gutter là 16, đúng "16 gutter" của P0. Khoảng cách nội bộ (chip↔track, track↔figure) dùng `AppSpacing.sm` (8) từ đúng thang sáu bước, không phải số rời | gutter fn: [mx_content_shell.dart:465-475](../../lib/shared/widgets/mx_content_shell.dart:465); breakpoint: [app_breakpoints.dart:22](../../lib/core/theme/foundations/app_breakpoints.dart:22), [:46](../../lib/core/theme/foundations/app_breakpoints.dart:46); mốc 393: [mx_session_top_bar.dart:107](../../lib/shared/widgets/mx_session_top_bar.dart:107); `lg`=16: [app_spacing.dart:19](../../lib/core/theme/foundations/app_spacing.dart:19); gap `sm`: [mx_session_top_bar.dart:202](../../lib/shared/widgets/mx_session_top_bar.dart:202), [app_spacing.dart:13](../../lib/core/theme/foundations/app_spacing.dart:13) |

Không mục P0 nào bị bỏ ngỏ. Xác nhận ở đây dừng ở mức **cấu trúc** (đọc code,
theo đúng chuỗi role/token) — tài liệu này không tự chạy lại golden light/dark
để kiểm bằng mắt, vì đó là việc của gate hiện có (`v1-freeze.md` §2 dòng 9,
golden HC), không phải việc của một task đối chiếu docs-only.

## 7. Mục còn mở — accent theo từng mode (KHÔNG giải quyết ở đây)

**Xung đột.** Prompt gốc xếp `accent` là CONTENT-DRIVEN "per study mode" —
mỗi mode một màu. `MxSessionTopBar`/`_Chip` cố ý dùng **một** accent cố định
(role `primary`, qua `AppInk.accent`) cho mọi mode, phân biệt mode chỉ bằng
chữ trên chip
([mx_session_top_bar.dart:249-254](../../lib/shared/widgets/mx_session_top_bar.dart:249),
[app_ink.dart:92](../../lib/core/theme/extensions/app_ink.dart:92)). Đây
**không phải một implementation gap** — lý do đã được viết thành quyết định,
tại đúng chỗ compose bar vào khung phiên học: kit cho mỗi mode một họ màu,
app không có token nào mang nghĩa "đây là mode nào", và màu xanh gần nhất là
`success` — nghĩa là *đúng* — nên tô nó lên chip sẽ đọc như một phán quyết
đưa ra trước khi người dùng trả lời, và ở màn `match` cùng một màu sẽ vừa
đánh dấu "đây là mode nào" vừa đánh dấu "cặp này đúng" trên cùng một màn hình
([study_session_frame_section_widget.dart:28-34](../../lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart:28)).
Track tiến độ cũng không mang màu theo mode — nó tự nhận "own colour family,
never the accent"
([mx_progress_bar.dart:32](../../lib/shared/widgets/mx_progress_bar.dart:32))
— nên đây là một quyết định nhất quán cho cả bar, không phải một chỗ sót
riêng lẻ ở chip.

**Tài liệu này MUST NOT đề xuất implement accent theo từng mode, và MUST NOT
đề xuất bỏ yêu cầu đó khỏi hợp đồng kit.** Nó chỉ ghi lại xung đột. Đường duy
nhất để mở lại: `v1-freeze.md` §3 điều kiện 6 — "**Chủ dự án chỉ định một
thay đổi hình thức cho component đã có**, kèm tham chiếu thị giác cụ thể
(mockup, ảnh chụp, bản dựng)"
([v1-freeze.md:88-89](../../docs/design-system/v1-freeze.md:88)). Năm điều
kiện còn lại của §3 không điều kiện nào khớp ở đây: đây không phải nâng SDK,
không phải palette/theme redesign, `MxSessionTopBar`/`_Chip` đã là primitive
có sẵn nên không phải thêm họ mới, không phải yêu cầu accessibility, và hành
vi hiện tại chạy đúng như thiết kế nên không phải defect. Một task muốn đổi
hướng này MUST mở một task design-system riêng theo đúng §3, không phải tự
sửa trong lúc làm việc khác.

## 8. Kết luận

`StudyTopBar` đã có một bản dịch Flutter đầy đủ và đã production
(`MxSessionTopBar` + `StudySessionFrameSectionWidget`). Không có task
implement nào sinh ra từ tài liệu này: dimension `progress`, icon
`x`→`Icons.close`, ba mục P0 và toàn bộ implementation handoff đều khớp hoặc
đã được app xử lý đúng hơn bản tóm gọn trong prompt (Material Icons cổ điển
thay vì Material Symbols; system Back bị chặn có test ghim). Đúng một điểm là
xung đột thật — `accent` theo mode — và nó ở lại như một mục mở tại §7, chờ
đúng điều kiện 6 của `v1-freeze.md` §3 nếu chủ dự án từng muốn màu theo mode
thật.
