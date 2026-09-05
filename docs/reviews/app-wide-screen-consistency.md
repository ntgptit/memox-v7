# App-wide screen consistency

| | |
|---|---|
| **Status** | active |
| **Purpose** | Làm mọi màn production đọc như một sản phẩm: ghi lại inventory màn hình, grammar composition đang được đo, và registry finding mà các PR cluster sau sẽ đóng từng cụm |
| **Scope** | Composition ở **mức màn hình** — section nào có, thứ tự ra sao, phân cấp thông tin, các `Mx*` sẵn có được xếp và giãn cách thế nào. Ngoài phạm vi: 14 hợp đồng đóng băng của `design-system/v1-freeze.md` §2, giá trị token (AD-14), hợp đồng component-level (`.claude/skills/flutter-theme-design/`) |
| **Source of truth for** | Inventory 21 màn production và các bề mặt overlay · composition grammar áp cho việc lắp ráp màn hình · registry 123 finding SC-* và cụm của chúng · danh sách `DESIGN_SYSTEM_BLOCKED` của pass này |
| **Depends on** | `document-conventions.md` · `design-system/v1-freeze.md` · `architecture.md` (AD-04, AD-12, AD-14, AD-15) · `reviews/a18-responsive-compact-audit.md` · `reviews/a20-1-design-system-reconciliation.md` |
| **Updated by task** | M100.42 |
| **Last updated** | 2026-09-05 |

---

## 1. Tài liệu này là gì, và không phải là gì

Đây **không** phải audit design system thứ mười lăm. `v1-freeze.md` §4 nói thẳng rằng
một audit mới không sinh ra thông tin, và điều đó đúng: A7–A20.1 đã đóng 51/51 finding
ở **mức component**, và 14 hợp đồng ở §2 được guard và test canh.

Pass này đi vào đúng khoảng trống mà chính bản freeze cố ý để mở. §2 viết:

> **Không đóng băng:** composition của màn hình nghiệp vụ.

Đó là khoảng trống duy nhất còn lại, và nó là khoảng trống thật: một audit component
soi `MxCard` có đúng không, chứ cấu trúc không cho phép nó thấy **hai màn dùng
`MxCard` đúng nhưng giãn cách chúng khác nhau**. 123 finding dưới đây gần như toàn bộ
thuộc loại thứ hai.

**Tài liệu này ở trạng thái recon.** Nó ghi nhận cái đã đo được; nó chưa sửa gì. Mỗi
cụm sẽ đóng bằng một PR riêng, và cột trạng thái của từng cụm được cập nhật tại chính
PR đó.

### 1.1 Phương pháp, và giới hạn của nó

24 đơn vị bề mặt được review độc lập theo cùng một rubric mười chiều (§3). Mỗi finding
buộc phải trỏ `file:line`, nêu **giá trị đo được** ở đó, và **nêu tên một bề mặt anh
em làm khác** kèm `file:line` của nó — vì tính nhất quán là một mệnh đề so sánh, không
phải một cảm giác.

Có 17 finding P0/P1. **16 trong số đó** được đưa qua hai lăng kính phản biện độc lập —
cái thứ mười bảy (`SC-C4-21`) đến từ ba review chạy bù sau khi vòng phản biện đã đóng,
nên nó mang trạng thái UNVERIFIED như nhóm P2/P3:

| Lăng kính | Hỏi gì |
|---|---|
| **measurement** | Mở đúng dòng được trích. Số có đúng không? Bề mặt anh em có thật sự làm khác không? Có cơ chế hợp lệ nào (`AppBreakpoints.isCompact`, một comment giải thích chủ đích) đã giải thích nó chưa? |
| **improvement** | Giả sử số đúng. Áp `target` vào thì app **nhất quán hơn**, hay chỉ **khác đi**? Và việc áp nó có chạm hợp đồng đóng băng nào không? |

Kết quả: **13 CONFIRMED · 3 CONTESTED · 0 bị bác hoàn toàn.** Ba cái bị tranh cãi được
giữ lại nguyên văn kèm lập luận phản bác, vì cả ba đều dạy một điều khác nhau:

| ID | Số đo | Vì sao vẫn giữ lại |
|---|---|---|
| `SC-C3-16` | đúng, đã tái lập | Nhưng **đảo ngược**: khảo sát 46 call site `MxErrorState`/`MxEmptyState` trong `lib/features/` cho thấy chỉ 3 có live region; thu hẹp về đúng lớp so sánh là **14 trần / 2 có**. Card Detail không phải ngoại lệ — `study_home` và `progress` mới là. Vấn đề thật nằm ở **cấp cụm** (14 mặt lỗi toàn màn không thông báo gì), không ở màn này |
| `SC-C8-04` | đúng từng token | Nhưng phân chia thật là **5 (pill 24dp) / 4 (vuông 32dp)**, không phải 5/1. Sửa một cái thành 6/3 — "khác đi", không "nhất quán hơn". Và hai trong bốn cái còn lại có comment ghi rằng chúng khớp Card Detail, nên sửa riêng nó sẽ làm hai comment kia thành sai |
| `SC-C9-12` | đúng, tái lập đúng từng chữ số, và golden đã commit cho thấy điều đó | Nhưng **target sai**: đưa `ProgressWeekWidget` xuống dưới danh sách deck trái với 5/5 màn có danh sách, và trái tài liệu thiết kế của chính màn đó. Vấn đề giữ lại, cách sửa phải tìm lại |

Ba dòng trên là lý do vòng phản biện tồn tại: cả ba đều có số đo đúng, và cả ba đều
sẽ làm app tệ hơn nếu áp đúng như đề xuất.

**Giới hạn phải nói rõ:** 106 finding P2/P3 cộng `SC-C4-21` — **107 trong 123** — **chưa được phản biện độc lập** — chúng có
trích dẫn và số đo của một reviewer duy nhất. Trong nhóm P0/P1 đã kiểm, 3/16 có `target`
sai dù số đo đúng; không có lý do gì để tin tỉ lệ đó thấp hơn ở P2/P3. Cho nên **mỗi PR
cluster MUST phản biện lại các finding nó định sửa trước khi sửa**, và cột
*Verification* của bảng P2/P3 nói đúng như vậy.

### 1.2 Gom cụm làm severity tăng lên

Severity được gán bởi reviewer chỉ nhìn thấy **một** đơn vị. Điều đó làm nó đánh giá
thấp một cách có hệ thống: cùng một lỗi lặp ở sáu màn thì mỗi reviewer thấy một P2 cục
bộ, trong khi cụm gộp lại là một P1. Ba cụm C1, C2 và C3 đều ở tình trạng đó. Bảng
severity ở §5 ghi **cả hai** con số — severity gốc theo màn, và severity của cụm — chứ
không lặng lẽ nâng cấp.

---

## 2. Inventory màn hình production

Dựng từ bảng route thật (`lib/app/router/app_router.dart`), không phải từ việc liệt kê
file. Loại trừ: specimen chỉ có trong Widgetbook, màn chỉ tồn tại trong test, và màn
chết. **Không tìm thấy màn chết nào.**

Bộ khung là một `StatefulShellRoute.indexedStack` bốn nhánh dựng `AppNavigationShell`,
với `MxNavigationBar` bốn đích. `AppNavigationShell` là `Scaffold` **duy nhất** ngoài
`MxContentShell`; **không màn nào dùng `Scaffold` trần.** Mức đồng nhất nền vốn đã rất
cao — đó là lý do các finding dưới đây nằm ở tầng lắp ráp chứ không ở tầng khung.

| # | Màn | Route / lối vào | Feature | Loại | Chrome gốc | Ảnh gallery |
|---|---|---|---|---|---|---|
| 1 | `DeckListScreen` (root) | `/` (nhánh 0) | deck | list | `MxContentShell` + `MxFab` | 5 hàng |
| 2 | `DeckListScreen` (level) | `/decks/:deckId` | deck | list | `MxContentShell` | dùng chung ở trên |
| 3 | `LibrarySearchScreen` | `/search` | search | search | `MxContentShell` + subheader | 1 |
| 4 | `StarterLibraryScreen` | `/starter` | deck | list | `MxContentShell` | 1 |
| 5 | `TagCatalogScreen` | `/tags` | card | list | `MxContentShell` | 1 |
| 6 | `TrashScreen` | `/trash` | trash | list | `MxContentShell` + subheader | 1 |
| 7 | `StudyEntryScreen` | `/decks/:deckId/study` · `/study/:deckId` | study | modal-driven | `MxContentShell` | **0** |
| 8 | `CardListScreen` | `/decks/:deckId/cards` | card | list | `MxContentShell` + subheader | 4 |
| 9 | `CardEditorScreen` (create) | `/decks/:deckId/cards/new` | card | editor | `MxContentShell` | **0** |
| 10 | `CardEditorScreen` (edit) | `/decks/:deckId/cards/:cardId/edit` | card | editor | `MxContentShell` + `PopScope` | 1 |
| 11 | `CardImportScreen` | `/decks/:deckId/cards/import` (root navigator) | card | editor | `MxContentShell` + `PopScope` | 5 |
| 12 | `CardDetailScreen` | `/decks/:deckId/cards/:cardId` | card | detail | `MxContentShell` | 11 |
| 13 | `StudyHomeScreen` | `/study` (nhánh 1) | study | list | `MxContentShell` | 1 |
| 14 | `StudySessionScreen` | `MaterialPageRoute` trên root navigator | study | study/session | `MxShellChrome.none` + `MxSessionTopBar` | 5 |
| 15 | `StudyOptionsScreen` | `MaterialPageRoute` trên branch navigator | study | settings | `MxContentShell` | **0** |
| 16 | `ProgressScreen` | `/progress` (nhánh 2) | progress | statistics | `MxAsyncView` ⊃ `MxContentShell` | 1 |
| 17 | `ProgressDeckScreen` | `/progress/:deckId` | progress | statistics | `MxAsyncView` + `MxContentShell` | 1 |
| 18 | `SettingsScreen` | `/settings` (nhánh 3) | settings | settings | `MxContentShell` | 2 |
| 19 | `ReminderSettingsScreen` | `/settings/reminders` | reminder | settings | `MxContentShell` | 2 |
| 20 | `RouteNotFoundScreen` | `errorBuilder` | app | result | `MxContentShell` | **0** |
| 21 | `ErrorScreenWidget` | `runApp()` khi bootstrap chết · `ErrorWidget.builder` | app | result | không có — `widgets.dart` trần | ngoài phạm vi |

**Ba màn không nằm trong bảng route đều là cố ý** và đều tới được trong app thật:
`StudySessionScreen` đẩy trên root navigator để phiên học chỉ có một lối ra (BR-82),
`StudyOptionsScreen` đẩy trên branch navigator, `ErrorScreenWidget` chạy khi chưa có
`MaterialApp`.

`ErrorScreenWidget` **nằm ngoài pass này**, không phải vì bỏ sót: nó chạy khi bootstrap
đã chết, nên không có theme, không có l10n và không render được trong `ReviewApp`. Một
grammar composition không áp được vào thứ cố ý sống ngoài design system.

### 2.1 Overlay

35 bề mặt overlay: 30 hàm `show*` trong `presentation/widgets/overlays/`, 2 undo
snackbar, và 3 sheet body của study. Trong đó **15 cái có bố cục thật** (form sheet,
picker, export/import, filter, action sheet) và được review. 20 cái còn lại là confirm
dialog một dòng: hình dạng của chúng do `MxConfirmDialog` / `MxSheet` quyết định, tức
hợp đồng đóng băng #6, nên chúng được inventory chứ không review.

**`study` là feature duy nhất mở sheet inline bằng `showMxSheet`** với ba widget body
trần, thay vì gói trong một hàm `show*` có tên như năm feature còn lại — xem SC-C4-19.

### 2.2 Bốn màn không có ảnh nào

`StudyEntryScreen`, `StudyOptionsScreen`, `RouteNotFoundScreen` và `CardEditorScreen` ở
chế độ **create** không có hàng nào trong 61 hàng `SCREENS` của
`build_screen_gallery.py`. Không có ảnh thì §7 của quy trình — so BEFORE vs AFTER cho
mọi màn thay đổi đáng kể — là bất khả thi trên chính bốn màn này.

PR recon này **thêm baseline cho cả bốn**, đúng 393×852 như `_check_surface` bắt buộc.
Đó không phải việc tiện tay: bốn màn đó gom **19 finding**, trong đó 5 là P1.

---

## 3. Rubric, và grammar được đo

### 3.1 Composition grammar

Lấy từ `AppSpacing` của repo, không phải từ một thang bịa ra:

```
xs = 4    sm = 8    md = 12    lg = 16    xl = 24    xxl = 32
```

| Vai trò | Token | Vì sao |
|---|---|---|
| Padding ngang của màn | `lg` (16) | qua `mxScreenGutter(context)`, tự hạ xuống `md` dưới 360dp |
| Khoảng giữa các item trong một danh sách | `lg` (16) | doc của chính token: *"Standard screen padding **and the gap between list items**"* |
| Khoảng giữa các section | `xl` (24) | `SettingsScreen.sectionGap` và `_ProgressSections` đều đã ở 24 |
| Tách vùng lớn | `xxl` (32) | khi có lý do |

`md` (12) nghĩa là **bên trong một control gọn**. `md` dùng làm khoảng cách section
hay item là một finding.

**Con số "item gap = 12" trong brief của task là sai và đã bị bác.** Nó mâu thuẫn với
ngữ nghĩa token mà `feature_geometry_grid_test` và guard đang canh; làm theo nó sẽ siết
mọi danh sách trong app từ 16 xuống 12 và dịch pixel gần như toàn bộ golden. Luật nhà
thắng.

**`AppBreakpoints.isCompact` (320dp) hạ padding màn từ `lg` xuống `md` là hợp lệ** và
không phải finding — `compact_scale_test.dart` canh điều đó.

### 3.2 Mười chiều

| | Chiều | Đo cái gì |
|---|---|---|
| A | HIERARCHY | một tiêu đề màn rõ ràng; tối đa một CTA chính mỗi trạng thái; hành động phá huỷ/phụ phải nhỏ hơn về mặt thị giác |
| B | GROUPING | nội dung liên quan gom lại; section không liên quan tách mạnh hơn; nhãn thuộc về thứ nó mô tả |
| C | ALIGNMENT | một mép trái chung; hành động ở cuối hàng canh đều; không có offset ngang tuỳ tiện |
| D | SPACING | theo grammar §3.1; cấu trúc lặp cùng vai trò ngữ nghĩa thì cùng khoảng cách |
| E | DENSITY | nhất quán trong cùng họ ngữ nghĩa; target ≥48dp |
| F | TYPOGRAPHY | chỉ dùng role đã đóng băng; ≤1 phân cấp tiêu đề mỗi màn; không restyle thô để tạo phân cấp |
| G | COLOR | chỉ role ngữ nghĩa sẵn có; selection/error/warning/success/destructive giữ nguyên nghĩa |
| H | CHROME | AppBar, back/up, breadcrumb, search/filter, FAB, bottom nav, sheet — một hành động một grammar |
| I | STATES | loading / empty / populated / error / disabled / selected / xác nhận phá huỷ đều mạch lạc, không nhảy layout |
| J | RESPONSIVE | 320 / 360 / 375 / 393 dp × scale 1.0 / 1.3 / 2.0 (2.5 và 3.0 cho màn nhập liệu) × light / dark / HC |

---


## 4. Findings

123 finding, ID ổn định dạng `SC-<cụm>-<số>`. P0 và P1 có khối đầy đủ kèm kết quả
phản biện; P2 và P3 ở dạng bảng nhưng giữ nguyên `file:line` và số đo. Cột **Frozen**
đánh dấu ⛔ khi việc sửa sẽ chạm một hợp đồng đóng băng — sáu mục, liệt kê lại ở §7.


### C1 — Gutter ownership — a screen re-pads inside MxContentShell, or restates lg where mxScreenGutter belongs

**20 findings** (P1 2 · P2 14 · P3 4), across 16 surface units.

#### SC-C1-12 · P1 · I STATES · StudySessionScreen — finished / summary

| | |
|---|---|
| **State** | finished, summary read returned null |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/study/presentation/screens/study_session_screen.dart`, `lib/features/study/presentation/widgets/sections/study_summary_section_widget.dart` |

**Problem.** When the epilogue read fails, the finished session renders `MxEmptyState(title: studySessionFinished)` with no message and no action — on a screen that has deliberately removed every other control. `chrome: MxShellChrome.none` means no AppBar; `state.isFinished` skips `StudySessionFrameSectionWidget`, so the frame's ✕ is gone too. The result is one sentence, centred, with nothing to press. The sibling branch three lines below draws a `Back to deck` button for exactly the same state. Not P0 only because Android's back gesture still pops (`canPop: session == null || state.isFinished`).

**Evidence.** lib/features/study/presentation/screens/study_session_screen.dart:308 `MxEmptyState(title: context.l10n.studySessionFinished)` — no `message`, no `actionLabel`, no `onAction`; combined with :170 `chrome: MxShellChrome.none` and :181 `session == null || turn == null || state.isFinished` which drops the frame (and its ✕). Reachable: lib/features/study/presentation/controllers/study_session_summary_controller.dart:56-60 catches every failure and returns null. SIBLING doing it differently, same file, same state: study_session_screen.dart:309-312 `StudySummarySectionWidget(summary: summary, onBackToDeck: () => Navigator.of(context).pop())`, which draws lib/features/study/presentation/widgets/sections/study_summary_section_widget.dart:74-77 `MxActionButton(label: l10n.studySummaryBackToDeck, onPressed: onBackToDeck)`. Second-order: the fallback is also inset differently from the branch it replaces — the empty state adds its own `EdgeInsets.all(AppSpacing.xl)` (lib/shared/widgets/mx_empty_state.dart:61) on top of the screen's `EdgeInsets.all(mxScreenGutter(context))` (study_session_screen.dart:186), so its column starts at x=40 where the real summary starts at x=16.

**Target composition.** `MxEmptyState(title: l10n.studySessionFinished, actionLabel: l10n.studySummaryBackToDeck, onAction: () => Navigator.of(context).pop())` — both parameters already exist on the shared widget and the assert at mx_empty_state.dart:25-31 requires them as a pair. No new ARB key, no new component. The 40 vs 16 inset difference resolves itself once both branches carry the same control.

**Test required.** Widget test on `StudySessionScreen` with `studySessionSummaryProvider` overridden to `AsyncData(null)`: assert `find.byType(MxActionButton)` findsOneWidget and that its semantics node is enabled — plus a negative guard asserting the tree contains no `AppBar` and no widget with `l10n.studyFrameClose`, so the test fails if the fallback ever loses its only control again.

#### SC-C1-13 · P1 · C ALIGNMENT · StudyEntryScreen

| | |
|---|---|
| **State** | populated (and loading, and error — every branch) |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/study/presentation/screens/study_entry_screen.dart`, `lib/features/study/presentation/widgets/sections/study_entry_section_widget.dart` |

**Problem.** The screen pads its body a second time inside a shell that has already applied the screen gutter, so all of its content sits at a 32dp left edge instead of the app's 16dp, and the compact step at 320dp becomes 28dp instead of 12dp — inverting the rule rather than applying it. The mismatch is visible without leaving the route: the resume sheet that opens over this screen lays its buttons out at the correct gutter, so when it dismisses the same two verbs jump 16dp inward and lose 32dp of width.

**Evidence.** study_entry_screen.dart:126-127 wraps the body in `Padding(padding: const EdgeInsets.all(AppSpacing.lg))` while passing no `padding` to `MxContentShell`, which already applies `_defaultPadding` → `mxScreenGutter` (mx_content_shell.dart:352, 472-478 = lg 16 / md 12 below AppBreakpoints.compact). MEASURED with getRect on the real screen: counts Text left = 32.0 at 393dp and 28.0 at 320dp; a bare `MxContentShell` with the same body measures 16.0 and 12.0. Buttons measure x 32.0..361.0 (329 wide) at 393dp. SIBLING doing it correctly, with the failure spelled out: card_detail_screen.dart:98-101 passes `padding: EdgeInsets.zero` because "the shell's default would pad each of them twice"; study_home_screen.dart:67-69 does the same. SIBLING measured at the correct gutter on the same route: study_resume_widget.dart:29 (`MxSheetInsets`) puts its three buttons at x 16.0..377.0 (361 wide). SECOND OFFENDER, same feature: study_options_screen.dart:49.

**Target composition.** Delete the `Padding` at study_entry_screen.dart:126-127 and let `MxContentShell` own the gutter, exactly as study_home_screen.dart:69 and card_detail_screen.dart:101 decide it. If the loading and error faces should stay bare (they centre themselves inside `AppSpacing.xl` already — mx_error_state.dart:67), pass `padding: EdgeInsets.zero` to the shell and wrap only the `data:` branch in `Padding(EdgeInsets.all(mxScreenGutter(context)))`, the public helper mx_content_shell.dart:472 exists for that. No new token, no shell change.

**Test required.** Widget test pumping the real StudyEntryScreen over FakeStudyRepository at 393x852 and at 320x640, asserting `tester.getRect(find.text('New 3')).left` == 16.0 and == 12.0 respectively, and that the first `MxActionButton`'s rect width equals viewport − 2*gutter. Pair it with the same assertion on the resume sheet so the two surfaces are pinned to one edge.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C1-01 | P2 | C | StarterLibraryScreen | This is the only screen in the app whose body is a scroll view sitting inside `MxContentShell`'s *static* padding. Because the gutter is outside the scroll, rows clip at a 16dp dead band under the app bar instead of scrolling to the chrome edge, the list cannot use `mxScrollEndInsetOf`, and the screen gutter is paid twice by eve…<br>`lib/features/deck/presentation/screens/starter_library_screen.dart:34-46` `mx_content_shell.dart:353-355` `lib/features/deck/presentation/widgets/sections/deck_notice_widget.dart:21-25` — lib/features/deck/presentation/screens/starter_library_screen.dart:34-46 passes neither `padding` nor `isScrollable`, so mx_content_shell.dart:353-355 wraps the body in `Padding(EdgeInsets.all(mxScree… |  |
| SC-C1-02 | P2 | H | CardEditorScreen — create mode | The same command, `Save`, is placed two different ways in the two modes of one screen: pinned in the shell footer in edit, at the end of the scroll in create. Create autofocuses its first field, so the keyboard is up immediately and the body has already shrunk — the primary action of the screen is off-screen from the first frame…<br>`card_create_form_widget.dart:163-176` `card_editor_screen.dart:175-176` `card_editor_screen.dart:280-284` — card_create_form_widget.dart:163-176 — `MxButtonPair(primary: Save, secondary: Save and add another)` is the last child of the body `Column`, and that column is the shell's scroll view (card_editor_sc… |  |
| SC-C1-03 | P3 | J | StudyHomeScreen | The deck row is the only row in the app whose anatomy changes with screen width, and the threshold lands between two ordinary phone widths. Below the threshold the Study verb sits on its own band under the counts; above it the verb shares the counts' band.<br>`lib/features/study/presentation/widgets/items/study_home_deck_item_widget.dart:203` `mx_content_shell.dart:472-476` `mx_card.dart:663` — lib/features/study/presentation/widgets/items/study_home_deck_item_widget.dart:203 `static const double inlineActionMinWidth = 320;` and :160-186 the two branches. |  |
| SC-C1-04 | P3 | D | CardImportScreen — pinned footer (all phases) | The app has exactly two `MxContentShell.footer` callers and they draw the same anatomy — an `MxButtonPair` over a centred quiet `bodySmall` line — at two different rhythms.<br>`lib/features/card/presentation/widgets/sections/card_import_action_bar_widget.dart:136-139` `lib/features/card/presentation/widgets/sections/card_editor_action_bar_widget.dart:52-56` `card_editor_screen.dart:280` — lib/features/card/presentation/widgets/sections/card_import_action_bar_widget.dart:136-139 `EdgeInsets.symmetric(horizontal: mxScreenGutter, vertical: AppSpacing.sm)` and :154-156 `EdgeInsets.only(top… |  |
| SC-C1-05 | P2 | I | ProgressScreen | The same route renders `MxEmptyState`/`MxErrorState` at two different insets depending on which of the two stacked reads produced the state. `ProgressScreen`'s own three faces go through `shell()`, which takes `MxContentShell`'s default `EdgeInsets.all(mxScreenGutter)` on top of the state widget's own `EdgeInsets.all(AppSpacing.…<br>`progress_screen.dart:66-72` `mx_content_shell.dart:477` `progress_screen.dart:91` — progress_screen.dart:66-72 `shell()` builds `MxContentShell(title:..., isScrollable: true, body: body)` with no `padding`, resolving to mx_content_shell.dart:477 `EdgeInsets.all(mxScreenGutter(context… |  |
| SC-C1-06 | P2 | C | CardListScreen | The list body pins its horizontal gutter to a literal AppSpacing.lg while the pinned subheader directly above it derives its gutter from mxScreenGutter, which steps to AppSpacing.md below 360dp.<br>`lib/features/card/presentation/widgets/sections/card_list_body_widget.dart:59-64` `lib/shared/widgets/mx_content_shell.dart:223-227` `app_breakpoints.dart:22` — lib/features/card/presentation/widgets/sections/card_list_body_widget.dart:59-64 `EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl)` — literal 16 on both sides at every… |  |
| SC-C1-07 | P2 | C | StudyOptionsScreen | The screen wraps its body in a second `EdgeInsets.all(AppSpacing.lg)` on top of the gutter `MxContentShell` already applies. The result is a 32dp inset instead of 16: the body is 32dp narrower than on every other screen, it sits 16dp to the right of its own app-bar title (two left edges on one screen), and the compact step-down…<br>`lib/features/study/presentation/screens/study_options_screen.dart:48-49` `lib/shared/widgets/mx_content_shell.dart:352` `lib/features/progress/presentation/screens/progress_deck_screen.dart:99-102` — lib/features/study/presentation/screens/study_options_screen.dart:48-49 — `body: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: MxAsyncView<StudyOptionsModel>(...))`, while lib/shared/wi… |  |
| SC-C1-08 | P2 | C | TrashScreen | The selection bar hardcodes `AppSpacing.lg` as its horizontal gutter while every other band on the screen reads `mxScreenGutter(context)`. Below 360dp the gutter steps to `md` (12) and the bar's contents stay at 16, so the screen's single left edge — the one thing G1 exists to guarantee — breaks by 4dp at exactly the width the c…<br>`lib/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart:49-54` `lib/features/trash/presentation/widgets/items/trash_row_widget.dart:86-89` `lib/features/trash/presentation/screens/trash_screen.dart:339-345` — lib/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart:49-54 — `EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md)`, a literal 16 on both sides. |  |
| SC-C1-09 | P2 | C | TrashScreen | The row's trailing overflow glyph sits 28dp from the screen edge while every other mark on the same screen sits at 16 — the row is optically 16 left / 28 right. The row pads symmetrically with the gutter and never subtracts the icon button's own ~12dp internal inset, which the app's two other rows carrying a trailing overflow bo…<br>`lib/features/trash/presentation/widgets/items/trash_row_widget.dart:86-89` `lib/shared/widgets/mx_icon_button.dart:110-119` `test/features/trash/presentation/trash_geometry_test.dart:144-170` — lib/features/trash/presentation/widgets/items/trash_row_widget.dart:86-89 — `EdgeInsets.symmetric(horizontal: mxScreenGutter(context))`, so the trailing `MxIconButton` (48dp box, glyph inset ~12 per l… |  |
| SC-C1-10 | P2 | C | TagCatalogScreen | The catalog surface and every state face hold a hardcoded `AppSpacing.lg` gutter, while the search field directly above them takes the shell's gutter, which steps to `AppSpacing.md` below `AppBreakpoints.compact` (360).<br>`tag_catalog_screen.dart:166-171` `tag_catalog_screen.dart:107` `mx_content_shell.dart:224` — tag_catalog_screen.dart:166-171 `EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg)` and tag_catalog_screen.dart:107 `EdgeInsets.symmetric(horizontal: AppSpacing.lg)` — bo… |  |
| SC-C1-11 | P3 | C | TagCatalogScreen | The row separator's trailing end lands on nothing. The list uses an asymmetric `Divider(indent: 56, endIndent: AppSpacing.md)`; the leading `indent` is derived and provably ties to the text column, but the trailing `endIndent` of 12 is a bare literal that matches neither the row's own content edge nor the menu glyph nor the card…<br>`tag_catalog_screen.dart:187-192` `tag_catalog_row_widget.dart:62-67` `reminder_settings_section_widget.dart:107-112` — tag_catalog_screen.dart:187-192 `Divider(indent: _rowTextInset, endIndent: AppSpacing.md)`. MEASURED at 393x852 on the real screen: card = LTRB(16.0, 140.0, 377.0, 334.0); |  |
| SC-C1-14 | P2 | C | ReminderSettingsScreen | Below AppBreakpoints.compact (360dp) the two rows of the one settings card stop sharing a left edge, and the hairline between them stops aligning with either. The toggle row supplies its horizontal gutter with a fixed AppSpacing.lg literal and so does the Divider, while the time row takes its gutter from ListTileTheme.contentPad…<br>`lib/features/reminder/presentation/widgets/items/reminder_toggle_row_widget.dart:37-40` `lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart:107-108` `lib/core/theme/schemes/app_compact_scale.dart:73-78` — lib/features/reminder/presentation/widgets/items/reminder_toggle_row_widget.dart:37-40 EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs) - a fixed 16; |  |
| SC-C1-15 | P2 | E | ReminderSettingsScreen | The two rows of one card have tap targets and ripples of different width. The toggle row's InkWell is 329dp wide, the time row's is 361dp - the full card - so a 16dp strip down each edge of the toggle row is dead, while the identical x on the row directly beneath it opens the time picker.<br>`lib/features/reminder/presentation/widgets/items/reminder_toggle_row_widget.dart:36-44` `lib/shared/widgets/mx_switch_row.dart:53` `lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart:82-84` — Measured with getRect at 393x852: card 16.0..377.0 (w 361), toggle-row InkWell 32.0..361.0 (w 329, h 56), time-row InkWell 16.0..377.0 (w 361, h 68). | ⛔ 6 - public contract of shared primitives in lib/shared/widgets/ (MxSwitchRow's constructor… |
| SC-C1-16 | P3 | C | Reminder settings — time picker dialog | The time picker sits 16dp in from each screen edge while every other dialog in the app sits 40dp in, so the app's one Material-owned modal is 48dp wider than its siblings on the same screen — a visible break in the modal width the rest of the app holds constant.<br>`time_picker.dart:2668-2673` `lib/core/theme/components/pickers/app_time_picker_theme.dart:30-137` `lib/shared/widgets/mx_dialog_metrics.dart:28` — Flutter 3.44.8 time_picker.dart:2668-2673 hardcodes `insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: dial ? 24 : 0)` on the `Dialog`, and `TimePickerThemeData` has no slot for it — lib/co… | ⛔ 6 — public contract of shared primitives in lib/shared/widgets/ (the only available fix is… |
| SC-C1-17 | P2 | D | Card export sheet | This is the only sheet body in the app that pads itself instead of using MxSheetInsets, and the one edge it drops is the top — so its title sits 16dp closer to the drag handle than the title of every other sheet, including the three siblings in this same unit.<br>`card_export_sheet_widget.dart:216-221` `mx_sheet_insets.dart:139` `card_bulk_overlays_widget.dart:82` — card_export_sheet_widget.dart:216-221 builds `Padding(padding: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.lg + mxSheetBottomObstruction(context)))` — no `top`. |  |
| SC-C1-18 | P2 | C | SettingsScreen | Below 360dp the screen's single content column breaks into two: the Study defaults card keeps a 16dp inner gutter while the two choice cards and the reminder row drop to 12dp, so the content of four cards that share their outer edges starts at three different x positions.<br>`settings_study_defaults_section_widget.dart:166` `mx_card.dart:663` `mx_radio_rows.dart:96-100` — Pumped SettingsScreen under buildLightTheme() + applyCompactScale() at 320x1400, devicePixelRatio 1.0. Measured: all four MxCard rects 12.0..308.0; |  |
| SC-C1-19 | P2 | C | SettingsScreen | The error band inside a choice card restates AppSpacing.lg as a horizontal literal while the radio rows in the same card take mxScreenGutter, so below 360dp the band is inset 4dp further than the rows it reports on — a visible step inside one card, in the one state where the user is reading carefully.<br>`settings_choice_section_widget.dart:114-116` `mx_radio_rows.dart:77-84` — Pumped SettingsScreen with FailingAppSettingsRepository under the compact-scaled theme at 320x1600 and tapped 'Dark'. |  |
| SC-C1-20 | P2 | J | Study entry — resume sheet (BR-103) | StudyResumeWidget is the only sheet body in the app that is neither a SingleChildScrollView nor a ListView. Its Column of title + 86-character body + three full-width MxActionButtons overflows the sheet at 320dp x textScaler 2.0 and paints the third button off the bottom of the display, with no way to scroll to it.<br>`study_resume_widget.dart:29-63` `study_mode_chooser_widget.dart:53-54` `study_direction_chooser_widget.dart:117-118` — study_resume_widget.dart:29-63 — MxSheetInsets(child: Column(...)), no scroll view. Rendered inside the real showMxSheet route at 320x568, viewPadding top 24 / bottom 48, textScaler 2.0: 'A RenderFlex… |  |

---

### C2 — List and section rhythm — gaps one step below the composition grammar

**20 findings** (P2 14 · P3 6), across 15 surface units.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C2-01 | P2 | D | LibrarySearchScreen | The result list runs one step below the app's list rhythm at both levels at once: rows are separated by `sm` (8) where every other MxCard list uses 12 or 16, and the break between the Decks group and the Cards group is `lg` (16) where the app's documented section break is `xl` (24).<br>`lib/features/search/presentation/widgets/sections/library_search_body_widget.dart:174-175` `lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart:85-86` `lib/features/card/presentation/widgets/sections/card_list_body_widget.dart:69-70` — lib/features/search/presentation/widgets/sections/library_search_body_widget.dart:174-175 — `separatorBuilder: (…) => const SizedBox(height: AppSpacing.sm)` = 8; |  |
| SC-C2-02 | P2 | D | StarterLibraryScreen | The screen's whole vertical rhythm sits one step below the app's grammar: the gap between two template cards is `sm` (8) and the break between the BR-87 notice band and the list is `md` (12).<br>`lib/features/deck/presentation/screens/starter_library_screen.dart:73` `lib/shared/widgets/mx_card.dart:663` `lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart:83-86` — lib/features/deck/presentation/screens/starter_library_screen.dart:73 `const SizedBox(height: AppSpacing.sm)` between tiles and :70 `const SizedBox(height: AppSpacing.md)` after the notice. |  |
| SC-C2-03 | P2 | D | CardEditorScreen — create mode | `md` (12) is used as a section gap in the create form, which the composition grammar reserves for the inside of a compact control. The identical seam in edit mode — the two sides ending, the optional-details disclosure beginning — is `xl` (24).<br>`card_create_form_widget.dart:147` `card_editor_form_widget.dart:125` — card_create_form_widget.dart:147 `const SizedBox(height: AppSpacing.md)` = 12dp between the back field (or its failure text) and `CardDetailsSectionWidget`. |  |
| SC-C2-04 | P3 | D | CardEditorScreen — edit mode | The divider that separates the editing region from the destructive Trash region is the only asymmetric divider in the app: 36dp of space above the hairline, 12dp below.<br>`card_editor_form_widget.dart:139-144` `app_divider_theme.dart:19` `card_import_confirm_step_widget.dart:78-81` — card_editor_form_widget.dart:139-144 — `const SizedBox(height: AppSpacing.xl)` (24) followed by `Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider())` (12). |  |
| SC-C2-05 | P2 | D | CardImportScreen — outcome face (states 6-8) | The outcome column separates its three top-level card surfaces with `AppSpacing.md` (12), where every other band-to-band gap on this same screen — and on the screen the outcome's summary rows were modelled on — is `AppSpacing.xl` (24). `md` is the scale's inside-a-compact-control step;<br>`lib/features/card/presentation/widgets/sections/card_import_result_widget.dart:78` `lib/features/card/presentation/widgets/sections/card_import_preview_step_widget.dart:288` `lib/features/card/presentation/widgets/sections/card_import_source_step_widget.dart:89` — lib/features/card/presentation/widgets/sections/card_import_result_widget.dart:78 and :85 both `SizedBox(height: AppSpacing.md)`. |  |
| SC-C2-06 | P3 | D | ProgressScreen | Four cards of one family sit in one scroll, all `MxCard.raised` with a quiet heading over their content, and one of them steps heading → content by `md` (12) where the other three step by `sm` (8).<br>`progress_summary_widget.dart:53-55` `progress_streak_hero_widget.dart:60-62` `progress_today_widget.dart:40-42` — progress_summary_widget.dart:53-55 quiet `labelLarge` heading then `SizedBox(height: AppSpacing.md)` (12). Siblings on the same screen: progress_streak_hero_widget.dart:60-62 `AppSpacing.sm`; |  |
| SC-C2-07 | P2 | D | CardListScreen | The scroll ends xxl (32) below the last row, double the lg (16) that decision D21 settled on for every scrolling list in the app — and the test guarding this edge cites D21 in its own name while asserting the value D21 rejected, so the divergence is pinned rather than caught.<br>`lib/features/card/presentation/widgets/sections/card_list_body_widget.dart:63` `test/features/card/presentation/card_list_alignment_test.dart:234-250` `lib/features/progress/presentation/widgets/sections/progress_deck_list_widget.dart:49-56` — lib/features/card/presentation/widgets/sections/card_list_body_widget.dart:63 `AppSpacing.xxl` as the ListView's bottom inset; |  |
| SC-C2-08 | P2 | D | CardListScreen | Card rows are separated by md (12), where the composition grammar's item gap is lg (16) and the deck list — the list this tile is explicitly built to read like, with the same MxCard.raised surface — separates its rows by lg. Two lists of the same semantic family, one redirect apart, at two different item gaps.<br>`lib/features/card/presentation/widgets/sections/card_list_body_widget.dart:69-70` `lib/features/card/presentation/widgets/items/card_tile_widget.dart:19-21` `lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart:83-86` — lib/features/card/presentation/widgets/sections/card_list_body_widget.dart:69-70 `separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md)`; |  |
| SC-C2-09 | P2 | D | TrashScreen | The row's two independent meta facts — when it was deleted, and how many days are left — are laid out 4dp apart with no separator and, in light theme, in two inks that differ by 2.1 L*. They render as one run of text: "Deleted 2 days ago 28 days left".<br>`lib/features/trash/presentation/widgets/items/trash_row_widget.dart:186-200` `lib/core/theme/foundations/app_spacing.dart:11` `lib/core/theme/foundations/app_colors.dart:66` — lib/features/trash/presentation/widgets/items/trash_row_widget.dart:186-200 — `Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs)` over two bare `Text`s with no separator child. |  |
| SC-C2-10 | P2 | D | StudySessionScreen — all five mode bodies | The separation between a turn's content region and its action region takes four different values across the five modes of one screen: 8, 12, 16, 24. Nothing distinguishes the modes for this purpose — every one of them is "the card/board, then the thing you act on" — and the frame that wraps all five uses `lg` for both of its own…<br>`lib/features/study/presentation/widgets/support/study_swipe_deck_widget.dart:233` `recall_timer_section_widget.dart:365` `fill_answer_section_widget.dart:230` — MEASURED at 393×600: `browse` card bottom 544.0 → Previous/Next row top 552.0 = 8.0 (lib/features/study/presentation/widgets/support/study_swipe_deck_widget.dart:233 `EdgeInsets.only(top: AppSpacing.s… |  |
| SC-C2-11 | P3 | D | StudySessionScreen — self_assess revealed | The grade loop appends `SizedBox(height: AppSpacing.sm)` after *every* button including the last, so the mode body ends in 8dp of dead space that no other mode has. The effective separation between the last control and the frame's hint line is therefore 8 + 16 = 24 in `self_assess` and 16 everywhere else.<br>`lib/features/study/presentation/widgets/sections/study_card_face_section_widget.dart:394-407` `lib/features/study/presentation/widgets/sections/guess_question_section_widget.dart:251` `lib/features/study/presentation/widgets/support/match_board_grid_widget.dart:56` — MEASURED at 393×600: `self_assess` eight_box revealed — last button rect bottom 592.0, host bottom 600.0, trailing gap = 8.0; sm2 (four grades) identical, 8.0. |  |
| SC-C2-12 | P2 | D | StudyEntryScreen | The two entry buttons are stacked at `md` (12), the token the grammar reserves for the inside of a compact control, while the only other place in the app that stacks these same two labels — the resume sheet that opens over this very screen from this very route — stacks them at `sm` (8).<br>`study_entry_section_widget.dart:62` `study_resume_widget.dart:49` `study_options_section_widget.dart:116` — study_entry_section_widget.dart:62 `const SizedBox(height: AppSpacing.md)` between `MxActionButton(label: l10n.studyStartLearning)` (:59, primary) and `MxActionButton(label: l10n.studyStartReview, var… |  |
| SC-C2-13 | P2 | D | Reset progress sheet | BR-50's two opposed lists - what is kept, what is lost - are bound together by md (12), which is tighter than the lg (16) that separates the title from the first list and tighter than the lg before the study-mode section.<br>`deck_reset_progress_widget.dart:99` `deck_reset_progress_widget.dart:177-194` `card_export_sheet_widget.dart:319` — deck_reset_progress_widget.dart:99 'const SizedBox(height: AppSpacing.md)' (12) between the Kept _Section (:93-98) and the Lost _Section (:103-110), against :92 lg (16) title -> first section and :111… |  |
| SC-C2-14 | P3 | D | Starter install sheet (vs deck form, scheduler… | Four sheets in this unit end in a commit, and one of them ends differently in two measurable ways: it separates its footer from the body by lg (16) where the other three use xl (24), and it offers a lone full-width primary where the other three offer MxButtonPair(Cancel, primary).<br>`starter_install_widget.dart:164-169` `deck_form_widget.dart:145` `deck_scheduler_change_widget.dart:110` — starter_install_widget.dart:164-169: 'const SizedBox(height: AppSpacing.lg)' (16) then a single MxActionButton(label: starterLibraryInstallAction), no secondary. |  |
| SC-C2-15 | P2 | D | ReminderSettingsScreen | The screen stacks three surfaces at one uniform gap, so the composition says nothing about what belongs to what. The gap that should read as 'this banner reports the failure of that card' and the gap that should read as 'this disclosure is a separate region' are the same 16dp, and 16 is the app's item gap, not its section gap.<br>`lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart:124` `lib/features/settings/presentation/screens/settings_screen.dart:45` `lib/features/card/presentation/screens/card_detail_screen.dart:235` — lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart:124 SizedBox(height: AppSpacing.lg) before the banner and :127 SizedBox(height: AppSpacing.lg) before MxCard.m… |  |
| SC-C2-16 | P2 | D | Trash restore-target sheet (showTrashRestoreTa… | The sheet's terminal primary action is separated from the list above it by AppSpacing.md (12), the same gap the sheet uses between its title and the first row. The control that ends the sheet therefore gets exactly as much separation as an internal label gap, and md is the "inside a compact control" step of the scale, not a sect…<br>`lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:200` `lib/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart:152` `lib/features/study/presentation/widgets/overlays/study_resume_widget.dart:44` — lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:200 `const SizedBox(height: AppSpacing.md)` immediately before the MxActionButton at :201. |  |
| SC-C2-17 | P2 | D | Tag filter sheet | One uniform column gap means the title's own explanatory line sits exactly as far from the title as the tag list sits from the action row, so nothing binds the header pair together and nothing separates the three regions. This is the failure the export sheet in the same unit already diagnosed and fixed, in writing.<br>`card_tag_filter_sheet_widget.dart:86-120` `starter_install_widget.dart:133` `study_resume_widget.dart:42` — card_tag_filter_sheet_widget.dart:86-120 is one `Column` with `spacing: AppSpacing.lg` at :89, so every gap in the sheet is 16dp: title (:91, titleMedium) → subtitle (:95-98, bodySmall inked quiet) =… |  |
| SC-C2-18 | P3 | D | Tag rename sheet | The same uniform gap gives an inline disclosure that describes the field above it the same 16dp it gives the gap to the button row, and puts the shared MxFeedbackBand at a section gap this sheet uses for everything — where the export sheet, which this file explicitly says it copied the band grammar from, separates the band at xl…<br>`tag_rename_widget.dart:127` `tag_rename_widget.dart:235` `card_export_error_band_widget.dart:136` — tag_rename_widget.dart:127 sets `spacing: AppSpacing.lg`, so all four gaps are 16dp: title (:129) → MxTextField (:130); |  |
| SC-C2-19 | P3 | D | SettingsScreen | One widget, SettingsErrorBandWidget, is introduced by three different gaps on this one screen, and the reset section's value matches nothing on this screen or on its sibling — same semantic role, three spacings.<br>`settings_choice_section_widget.dart:112` `settings_study_defaults_section_widget.dart:219` `settings_reset_section_widget.dart:64` — settings_choice_section_widget.dart:112 `AppSpacing.sm` (8), settings_study_defaults_section_widget.dart:219 `AppSpacing.lg` (16), settings_reset_section_widget.dart:64 `AppSpacing.md` (12). |  |
| SC-C2-20 | P2 | D | ProgressDeckScreen | Progress deck rows are separated by md (12), where the composition grammar's item gap is lg (16) and deck_list_sliver_widget.dart — the other sliver list of tappable deck rows — is at lg.<br>`lib/features/progress/presentation/widgets/sections/progress_deck_list_widget.dart:61` `lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart:86` — lib/features/progress/presentation/widgets/sections/progress_deck_list_widget.dart:61 — separatorBuilder: (BuildContext context, int index) => const SizedBox(height: AppSpacing.md). |  |

---

### C3 — Failure and empty faces — screen title as error title, success copy as error copy, retry that says nothing

**27 findings** (P0 1 · P1 5 · P2 14 · P3 7), across 15 surface units.

#### SC-C3-01 · P0 · I STATES · StarterLibraryScreen

| | |
|---|---|
| **State** | error |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/deck/presentation/screens/starter_library_screen.dart`, `lib/shared/widgets/mx_error_state.dart` |

**Problem.** The error branch passes `onRetry:` with no `retryLabel:`. `MxErrorState` asserts that the pair is all-or-nothing, so in debug/profile the whole screen is replaced by the red assertion box, and in a release build the `if (retryLabel != null && onRetry != null)` guard drops the button silently — leaving a catalog failure the user can read and cannot act on. No test renders this branch (the visual audit file even records that the error state is 'audited on the deck list'), which is why it has never fired.

**Evidence.** lib/features/deck/presentation/screens/starter_library_screen.dart:40-44 — `MxErrorState(title:…, message:…, onRetry: () => ref.invalidate(starterLibraryProvider))`, no `retryLabel`. lib/shared/widgets/mx_error_state.dart:30-35 asserts `(retryLabel == null) == (onRetry == null)`. Measured: pumping `StarterLibraryScreen` with a throwing `deckTemplateCatalogProvider` produced `'package:memox/shared/widgets/mx_error_state.dart': Failed assertion: line 31 pos 10: '(retryLabel == null) == (onRetry == null)'`. Siblings that pass both halves: lib/features/trash/presentation/screens/trash_screen.dart:92 `retryLabel: l10n.trashRetryAction`; lib/features/card/presentation/screens/card_list_screen.dart:224 `retryLabel: context.l10n.retryAction`; lib/features/settings/presentation/screens/settings_screen.dart:58; lib/features/reminder/presentation/screens/reminder_settings_screen.dart:71; lib/features/study/presentation/screens/study_home_screen.dart:100-109 (which also passes `isRetrying`).

**Target composition.** Pass the existing ARB key `retryAction` as `retryLabel` alongside `onRetry`, and pass `isRetrying: ref.watch(starterLibraryProvider).isRefreshing` the way `study_home_screen.dart:109` does — `ref.invalidate` is a refresh, and `MxAsyncView` holds the previous value through a refresh, so without the flag the tap repaints the identical error face. No new widget, no new token.

**Test required.** A widget test in test/features/deck/presentation/starter_library_test.dart that pumps the screen with a `deckTemplateCatalogProvider` override that throws, asserts no exception is raised, finds `english.retryAction`, taps it and asserts the provider is re-read. The existing file has a harness (`pump`) that already takes overrides — the failing-catalog case is simply missing.

#### SC-C3-04 · P1 · I STATES · DeckListScreen (root + level)

| | |
|---|---|
| **State** | loading |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/deck/presentation/screens/deck_list_screen.dart`, `lib/features/deck/presentation/widgets/sections/deck_level_error_widget.dart` |

**Problem.** The screen's chrome is rebuilt separately in each async branch instead of once around them, so loading and error render a materially different app bar from the loaded state. Measured consequences: (a) the bar grows 56 -> 84dp the instant data lands, pushing every body pixel down 28dp at text scale 1.0 and 37.5dp at 2.0; (b) while loading and on any read failure the bar has NO actions at all — the search entry and the overflow disappear, and at root that overflow is the only door to Trash (AD-22 keeps it root-only) and to the tag catalog's deck-side entry; (c) the up affordance changes shape and slot across the same transition, because `automaticallyImplyLeading` is true only when there is no subline — a Material back arrow in the leading slot while loading/erroring, replaced by the breadcrumb's own `chevron_left` inside the title block once data arrives.

**Evidence.** lib/features/deck/presentation/screens/deck_list_screen.dart:78-79 — `loadingFrame: (loading) => MxContentShell(title: _titleBeforeData(context), body: loading)`: no `actions`, no `titleSubline`, no `floatingActionButton`. lib/features/deck/presentation/widgets/sections/deck_level_error_widget.dart:45-60 — same shape for the error branch. The loaded shell at deck_list_screen.dart:132-225 passes `actions` (:141 search, :156/:172 overflow), `titleSubline` (:223) and the FAB (:207). Height: lib/shared/widgets/mx_content_shell.dart:287 `toolbarHeight: subline == null ? null : _toolbarHeight(context)`; with no subline the bar is `kToolbarHeight` = 56; `_toolbarHeight` (:335-349) with `titleLarge` 22/1.2727 (app_typography.dart:272-276) computes 28 + 8 + 32 + 16 = 84, the arithmetic the shell itself states at :326-329 — a 28.0dp step, 37.5dp once the title scaler clamps at 1.34 (:333). Leading flip: mx_content_shell.dart:281 `automaticallyImplyLeading: widget.leading == null && subline == null`. SIBLING: lib/features/card/presentation/screens/card_list_screen.dart:144 builds ONE `MxContentShell` whose `actions` (:162-190) sit outside the `MxAsyncView` at :218, so its bar keeps every action in loading, error and populated; 11 of the app's 13 other screens compose in that order.

**Target composition.** One `MxContentShell` around the three branches, in the `MxContentShell(body: MxAsyncView(...))` order the other eleven screens use. The title stays honest via the existing `_titleBeforeData` fallback; `actions` and the FAB become constant across states; and the subline slot is reserved in every state — either by passing `DeckSubheaderWidget` once the snapshot exists and a `SizedBox(height: MxBreadcrumb.compactLineHeight)` placeholder before it, or by keeping the per-branch shells but making the loading and error frames pass the same `actions` and a same-height subline, the way progress_deck_screen.dart:96-105 already does. Existing slots only — no `MxContentShell` API change.

**Test required.** Widget test on a controllable stream at 393x852: capture `tester.getRect(find.byType(AppBar)).height` in the loading frame and again after the snapshot lands and assert they are equal (within 0.5dp), at `textScaler` 1.0 and 2.0; plus `expect(find.byIcon(Icons.search), findsOneWidget)` and `expect(find.byIcon(Icons.more_vert), findsWidgets)` asserted in all three of loading, error and populated at the root level. Existing `deck_list_screen_test.dart` (groups at :42 and :206) only asserts which body widget renders, so it cannot see any of this.

#### SC-C3-07 · P1 · I STATES · StudyOptionsScreen

| | |
|---|---|
| **State** | error |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/study/presentation/screens/study_options_screen.dart`, `lib/l10n/app_en.arb` |

**Problem.** The read-failure face reuses the screen title as its error title and a success-behaviour sentence as its error message, and offers no retry. Under the red error glyph the user reads "Study options / Takes effect from your next session." — copy that denies that anything failed — and the only recovery is the system back button. Every other feature's load-error face states the failure and offers a retry that re-subscribes the provider.

**Evidence.** lib/features/study/presentation/screens/study_options_screen.dart:53-56 — `MxErrorState(title: context.l10n.studyOptionsTitle, message: context.l10n.studyOptionsNextSessionNote)` with no `retryLabel` and no `onRetry`. lib/l10n/app_en.arb:1710 `studyOptionsNextSessionNote` = "Takes effect from your next session."; app_en.arb:1674 `studyOptionsTitle` = "Study options", which is also what the shell puts in the app bar at study_options_screen.dart:47 — so the error face prints the screen title twice (measured at 393x852: app-bar title rect LTRB(16.0, 14.0, 164.9, 42.0)). SIBLING that does it differently: lib/features/settings/presentation/screens/settings_screen.dart:55-61 — `title: settingsLoadErrorTitle` ("Couldn't load your settings") + `message: writeErrorMessage` ("Please try again.") + `retryLabel: retryAction` + `onRetry: () => ref.invalidate(appSettingsProvider)`. SECOND SIBLING: lib/features/reminder/presentation/screens/reminder_settings_screen.dart:68-72, same three-part shape, and lib/l10n/app_en.arb:3311 records the reasoning verbatim ("Deliberately not the save copy... Mirrors settingsLoadErrorTitle, which is the same situation one screen up"). Also lib/features/card/presentation/screens/card_list_screen.dart:221-225 and lib/features/card/presentation/screens/tag_catalog_screen.dart:71-75. The same defect is repeated once more inside this feature at lib/features/study/presentation/screens/study_entry_screen.dart:131-133 (`title: appTitle, message: studyNothingDueMessage`, no retry), which is what makes it a pattern rather than a slip.

**Target composition.** The three-part composition the other settings-shaped screens already use, with existing widgets only: a new load-error ARB title beside `settingsLoadErrorTitle`/`reminderLoadErrorTitle`, `message: context.l10n.writeErrorMessage`, `retryLabel: context.l10n.retryAction`, `onRetry: () => ref.invalidate(studyOptionsProvider(deckId))`. `MxErrorState` already asserts that retryLabel and onRetry arrive as a pair (mx_error_state.dart:29-35).

**Test required.** Widget test pumping the error branch (a FakeStudyRepository whose options read fails): assert a retry `MxActionButton` is present and tappable, assert the rendered text does not contain `studyOptionsNextSessionNote`, and assert the error title is not identical to the app-bar title.

#### SC-C3-14 · P1 · I STATES · StudyEntryScreen

| | |
|---|---|
| **State** | error |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/study/presentation/screens/study_entry_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` |

**Problem.** The error branch does not say anything failed. It titles the failure with the application's name and gives it the copy of a normal, healthy state — so a user whose read just failed is told "Nothing to review yet. Come back when a card is due.", which is a factual claim the screen cannot support and which sends them away instead of letting them retry. There is no retry control and no live region, so a failure arriving in place on an already-open screen is silent to a screen reader. The loading branch announces the app name for the same reason.

**Evidence.** study_entry_screen.dart:130-134: `loadingLabel: context.l10n.appTitle`, and `MxErrorState(title: context.l10n.appTitle, message: context.l10n.studyNothingDueMessage)`. app_en.arb:3 `"appTitle": "MemoX"`; app_en.arb:1754 `"studyNothingDueMessage": "Nothing to review yet. Come back when a card is due."`. MEASURED with a repository whose stream errors: the word "MemoX" renders twice on one screen — app bar at Rect(16.0,14.0,97.4,42.0) and error title at Rect(166.4,446.0,226.6,470.0) — and the body sentence is the nothing-due copy. SIBLINGS, five other features, all name the failure: card_detail_screen.dart:180 and card_list_screen.dart:222 (`unexpectedErrorTitle`), progress_screen.dart:106 (`progressErrorTitle`), settings_screen.dart:56 (`settingsLoadErrorTitle`), reminder_settings_screen.dart:69 (`reminderLoadErrorTitle`). Same feature, one screen across: study_home_screen.dart:97-110 passes `studyHomeErrorTitle` + `retryLabel: l10n.retryAction` + `onRetry` + `isRetrying`, inside `Semantics(liveRegion: true, container: true)` (study_home_screen.dart:89-96). SECOND AND THIRD OFFENDERS: study_options_screen.dart:54-55 (title = screen title, message = `studyOptionsNextSessionNote`, a note); study_session_screen.dart:272-273 (identical appTitle/nothing-due pair).

**Target composition.** Give the branch failure copy and a way out, composed exactly as study_home_screen.dart:89-110 does: `Semantics(liveRegion: true, container: true, child: MxErrorState(title: l10n.unexpectedErrorTitle, message: <a study-entry load-error string>, retryLabel: l10n.retryAction, onRetry: () => ref.invalidate(studyEntryProvider(deckId)), isRetrying: <the AsyncValue's isRefreshing>))`, and set `loadingLabel` to a screen-naming string rather than `appTitle`. All parameters already exist on MxErrorState (mx_error_state.dart:16-35); only an ARB entry is new.

**Test required.** Widget test pumping StudyEntryScreen over a repository whose `watchStudyEntry` returns `Stream.error`, asserting: `find.text('MemoX')` matches only the app bar (findsOneWidget, not two), the nothing-due sentence is absent, a retry control is present and calling it re-reads, and the error face is inside a `Semantics` node with `liveRegion: true`.

#### SC-C3-16 · P1 · I STATES · CardDetailScreen

| | |
|---|---|
| **State** | error / not-found (top-level read failure, incl. a card deleted from another screen while it is on screen) |
| **Verification** | **CONTESTED** — 1 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `D:/workspace/memox-v7/.claude/worktrees/app-wide-screen-consistency-0820fe/lib/features/card/presentation/screens/card_detail_screen.dart` |

**Problem.** The two whole-screen failure faces replace everything the user was reading and announce nothing. `_failureFace` returns a bare `MxEmptyState` (card gone) or a bare `MxErrorState` (read failed); neither shared widget carries a live region of its own, so a screen-reader user sitting on this screen when the stream flips is told nothing and is left on a stale focus node. The same screen already gets this right one band lower: the history page failure announces itself because `MxFeedbackBand` owns the live region, so this screen has two failure grammars — the partial failure speaks, the total failure is silent.

**Evidence.** lib/features/card/presentation/screens/card_detail_screen.dart:161-185 — `_failureFace` returns `MxEmptyState(...)` (:165-176) and `MxErrorState(...)` (:179-184) with no `Semantics(liveRegion:)` wrapper; neither primitive supplies one (lib/shared/widgets/mx_empty_state.dart:58-114 and lib/shared/widgets/mx_error_state.dart:64-105 build a bare `Center`). The read is a live stream, so the face arrives in place: lib/features/card/presentation/controllers/card_detail_controller.dart:25-27. SIBLINGS that do it differently: lib/features/study/presentation/screens/study_home_screen.dart:89-96 wraps its `MxErrorState` in `Semantics(liveRegion: true, container: true)` ("it can arrive in place"); lib/features/progress/presentation/screens/progress_screen.dart:95-105 does the same and states that the flag belongs at the call site, not inside `MxErrorState`; lib/features/progress/presentation/widgets/sections/progress_level_error_widget.dart:94. INTERNAL sibling on this very screen: lib/shared/widgets/mx_feedback_band.dart:101-105 (`liveRegion: true`), pinned by test/features/card/presentation/card_detail_history_faces_test.dart:394-421.

**Target composition.** Wrap the value `_failureFace` returns in `Semantics(container: true, liveRegion: true)` at the call site in card_detail_screen.dart — the exact composition study_home_screen.dart:89-96 and progress_screen.dart:100-105 already use. No shared-widget API changes, no new tokens, no chrome change.

**Test required.** Semantics test in test/features/card/presentation/card_detail_history_faces_test.dart (or card_detail_screen_test.dart) mirroring the existing page-error test: `tester.ensureSemantics()`, pump the not-found face and the read-error face, then assert `flagsCollection.isLiveRegion` on the ancestor `Semantics` of `cardDetailNotFoundTitle` and of `unexpectedErrorTitle` — the same assertion shape as card_detail_history_faces_test.dart:410-420.

**Contested.** One lens refuted this. Lens (b) passes: wrapping `_failureFace`'s return in `Semantics(container: true, liveRegion: true)` inside `card_detail_screen.dart` is feature-local composition — no Mx* public API touched (freeze contract 6 covers the *public contract* of `lib/shared/widgets/`, v1-freeze.md:48), no token value changed, no `MxContentShell` chrome. Nothing frozen blocks it. Lens (a) is where it fails, on both sub-tests the lens names. **It contradicts what the siblings actually do — I counted them.** A census of every `MxErrorState`/`MxEmptyState` construction under `lib/features/` gives **46 call sites: 3 carry a live region, 43 do not.** Narrow it to the exact comparable class — a whole-screen failure face returned from an async read's `error:` builder — and it is **14 bare vs 2 live**: bare at `card_list_screen.dart:221`, `tag_catalog_screen.dart:71`, `starter_library_screen.dart:40`, `settings_screen…

#### SC-C3-19 · P1 · I STATES · Deck content-bearing sheets (all five: create root / create sub-deck / rename, m

| | |
|---|---|
| **State** | error |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/deck/presentation/widgets/overlays/deck_form_widget.dart`, `lib/features/deck/presentation/widgets/overlays/move_deck_sheet_widget.dart`, `lib/features/deck/presentation/widgets/overlays/deck_scheduler_change_widget.dart`, `lib/features/deck/presentation/widgets/overlays/deck_reset_progress_widget.dart`, `lib/features/deck/presentation/widgets/overlays/starter_install_widget.dart` |

**Problem.** Every content-bearing sheet in this unit discloses a repository write failure as a bare bodySmall line inked AppInk.danger - no icon, no title, no container, and no liveRegion, so colour is the only cue and a screen-reader user gets no announcement at all when a Create / Rename / Move / Reset / Install write fails. The app already settled one grammar for an in-flow failure (MxFeedbackBand: errorContainer card, error glyph, title + message, Semantics container+liveRegion) and five other features speak it. The deviation is confined to deck, but it covers all five of its content sheets, and the a11y half is what lifts it above a pure consistency defect: the shared widget's own doc says a caller that forgot liveRegion ships a band a screen-reader user never hears.

**Evidence.** Deck, bare red line x5: deck_form_widget.dart:139-143 (SizedBox md=12 then Text(context.deckWriteFailure(...), texts.bodySmall!.inked(context, AppInk.danger))); move_deck_sheet_widget.dart:77-83 (same, gap sm=8); deck_scheduler_change_widget.dart:193-199 (gap md=12); deck_reset_progress_widget.dart:127-133 (gap md=12); starter_install_widget.dart:157-163 (gap md=12). Sibling that does it differently, same situation, same sheet shape: tag_rename_widget.dart:235 renders MxFeedbackBand for the identical event, and its doc at tag_rename_widget.dart:426-440 names the rule ('this app has settled on one grammar for an in-flow failure ... A fourth dialect one sheet away is the seam that pass was about'). Four more: card_export_error_band_widget.dart:32, settings_error_band_widget.dart:41, search_page_footer_widget.dart:82, reminder_banner_section_widget.dart:36. The band's announcement lives at mx_feedback_band.dart:101-105 (Semantics container:true, liveRegion:true) - none of the five deck sites has it. The strings already exist and are already declared to be one situation: app_en.arb:734 deckWriteErrorTitle = 'Couldn't save', whose @-doc at app_en.arb:3504 states it shares its wording with tagWriteErrorTitle and settingsSaveErrorTitle, 'one situation, one sentence'.

**Target composition.** Replace each of the five Text(...danger) blocks with MxFeedbackBand(title: l10n.deckWriteErrorTitle, message: context.deckWriteFailure(failure)) - the widget is used as-is, no API change. Keep the preceding gap at AppSpacing.md (12) where it already is, and raise move_deck_sheet_widget.dart:78 from sm (8) to md (12) so all five match. MxTextField's own errorText (deck_form_widget.dart:111-113) stays where it is: a field-level validation problem is not a write failure and must not move into the band.

**Test required.** Widget test per sheet driving the controller to a failure (deck_move_picker_test.dart already has a writeFailure fixture, and root_deck_create_test.dart / deck_scheduler_change_widget_test.dart / deck_reset_progress_widget_test.dart / starter_library_test.dart cover the other four) asserting find.byType(MxFeedbackBand) findsOneWidget; plus a semantics test asserting tester.getSemantics(find.byType(MxFeedbackBand)).hasFlag(SemanticsFlag.isLiveRegion) on at least one of them. Pixels move, so regenerate the affected goldens on Linux.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C3-02 | P2 | A | StarterLibraryScreen | Both non-populated states title themselves with the screen's own title, so 'Starter library' appears twice on one screen — once in the AppBar and once as the state's heading — and neither heading says what happened.<br>`lib/features/deck/presentation/screens/starter_library_screen.dart:35` `lib/features/trash/presentation/screens/trash_screen.dart:87-91` `lib/features/card/presentation/screens/card_list_screen.dart:222-223` — lib/features/deck/presentation/screens/starter_library_screen.dart:35 `title: context.l10n.starterLibraryTitle` on the shell, :41 the same key as the `MxErrorState` title, :62 the same key as the `MxE… |  |
| SC-C3-03 | P2 | I | CardEditorScreen — create mode | Create's save-failure message is the only write failure anywhere on this screen that is not a live region. A screen-reader user presses Save in create mode, the write fails, and nothing is announced — the identical string in edit mode is wrapped in a live region precisely because that bug was found and fixed there.<br>`card_create_form_widget.dart:140-146` `card_editor_form_widget.dart:117-123` `card_editor_screen.dart:276` — card_create_form_widget.dart:140-146 renders `context.l10n.cardEditorSaveFailed` as a bare `Text(... inked(context, AppInk.error))`. |  |
| SC-C3-05 | P2 | A | DeckListScreen (root + level) | On the app's first-run screen — root level, no decks — three call-to-actions are on screen and the loudest one is the *secondary* path. The FAB is a filled, elevated, brand-coloured control labelled "New deck"; the empty state's primary (filled `MxActionButton`) is a different action, "Starter library";<br>`lib/features/deck/presentation/screens/deck_list_screen.dart:310-327` `mx_empty_state.dart:96-107` `lib/features/card/presentation/screens/card_list_screen.dart:320-321` — lib/features/deck/presentation/screens/deck_list_screen.dart:310-327 — root empty: `actionLabel: deckStarterLibraryAction` ("Starter library", :323) with `onAction: goNamed(starterLibrary)`, and `seco… |  |
| SC-C3-06 | P2 | I | DeckListScreen (root + level) | When the due-only filter matches no deck, the list heading and the sort control stay on screen above the "Nothing due right now" empty state — a sort control acting on zero rows, and inside a deck a heading that reads "SUB-DECKS · 0".<br>`lib/features/deck/presentation/screens/deck_list_screen.dart:234-237` `lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart:55-70` `deck_list_toolbar_widget.dart:80` — lib/features/deck/presentation/screens/deck_list_screen.dart:234-237 states the policy and returns `_emptyLevel` before the toolbar is built when `snapshot.decks.isEmpty`; |  |
| SC-C3-08 | P2 | I | StudyOptionsScreen | Save is enabled over a pristine draft and over an invalid one, and the field's error text only appears after a round trip. The identical form — same two values, same labels, same Save word — gates Save on dirty-and-valid on the Settings screen and shows the field error on blur. Two disabled-state grammars for one form.<br>`lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:117-121` `lib/shared/widgets/mx_action_button.dart:169` `study_options_screen.dart:69` — lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:117-121 — `MxActionButton(label: l10n.studyOptionsSave, isLoading: widget.isSubmitting, onPressed: () => widget.onSav… |  |
| SC-C3-09 | P2 | I | TrashScreen | A completely empty Trash still renders the All / Cards / Decks filter chips over the "Nothing in Trash" state — three live, tappable filters for zero items, each of which only swaps the empty message for another empty message.<br>`lib/features/trash/presentation/screens/trash_screen.dart:77-82` `lib/features/trash/presentation/screens/trash_screen.dart:157-169` `lib/features/card/presentation/screens/card_list_screen.dart:274` — lib/features/trash/presentation/screens/trash_screen.dart:77-82 decides the subheader from `selection.isActive` alone — `subheader: selection.isActive ? null : TrashFilterBarWidget(...)` — so the chip… |  |
| SC-C3-10 | P3 | I | TrashScreen | Entering selection mode deletes the pinned filter band outright. The filter is still applied — `_TrashBody` keeps filtering by it — so the user is looking at a narrowed list with no indication of what narrowed it and no way to change it, and the whole list jumps up by the band's height on the frame the long-press lands, moving t…<br>`lib/features/trash/presentation/screens/trash_screen.dart:77-82` `lib/features/trash/presentation/screens/trash_screen.dart:152-155` `lib/shared/widgets/mx_pill_button.dart:246` — lib/features/trash/presentation/screens/trash_screen.dart:77-82, `subheader: selection.isActive ? null : TrashFilterBarWidget(...)`, with no comment justifying the removal — while lib/features/trash/p… |  |
| SC-C3-11 | P3 | I | TagCatalogScreen | Retry on the error face gives the user no evidence the app noticed. The screen builds `MxErrorState` with an `onRetry` that calls `ref.invalidate` but never passes `isRetrying`, and `MxAsyncView` sets `skipLoadingOnRefresh: true`, so an invalidate re-renders the same error branch with the same previous error — the identical face…<br>`tag_catalog_screen.dart:70-77` `mx_error_state.dart:22` `mx_error_state.dart:93` — tag_catalog_screen.dart:70-77 `MxErrorState(title:..., message:..., retryLabel:..., onRetry: () => ref.invalidate(tagCatalogProvider))` — no `isRetrying`, so mx_error_state.dart:22 default `false` app… |  |
| SC-C3-12 | P2 | I | StudySessionScreen — error state | The screen's only error face is titled with the product name and carries an empty-state sentence rendered in error styling. `MxErrorState` paints `Icons.error_outline` in `AppInk.danger`; under it the heading reads `MemoX` and the body reads "Nothing to review yet.<br>`lib/features/study/presentation/screens/study_session_screen.dart:270-275` `lib/shared/widgets/mx_error_state.dart:71-75` `lib/shared/widgets/mx_empty_state.dart:10-14` — lib/features/study/presentation/screens/study_session_screen.dart:270-275 `MxErrorState(title: context.l10n.appTitle, message: context.l10n.studyNothingDueMessage)`. |  |
| SC-C3-13 | P3 | I | StudySessionScreen — transient states | All three loading states announce the product name instead of what is loading. A screen reader on a session that is opening hears "MemoX", which says neither that something is happening nor what.<br>`lib/features/study/presentation/screens/study_session_screen.dart:277` `lib/features/study/presentation/screens/study_home_screen.dart:72` `lib/features/study/presentation/screens/study_options_screen.dart:52` — lib/features/study/presentation/screens/study_session_screen.dart:277, :313 and :319, all three `MxLoadingState(semanticsLabel: context.l10n.appTitle)`; `appTitle` = "MemoX" (lib/l10n/app_en.arb:3). |  |
| SC-C3-15 | P2 | I | StudyEntryScreen | A reachable and entirely normal state — a deck fully learned with nothing yet due, which BR-29/BR-145 treat as the schedule working — renders as two zeroes in the screen's largest type followed by two loose sentences and no action at all.<br>`study_entry_section_widget.dart:58-70` `deck_list_screen.dart:312` `card_list_screen.dart:341` — study_entry_section_widget.dart:58-70: both branches fall through to `Text(l10n.studyNothingNewMessage)` and `Text(l10n.studyNothingDueMessage)`, with the counts row above still rendered at `context.t… |  |
| SC-C3-17 | P2 | I | CardDetailScreen | The one control on the read-error face gives no evidence it was pressed. `Retry` calls `ref.invalidate` on a stream provider, which Riverpod treats as a refresh; `MxAsyncView` is built with `skipLoadingOnRefresh: true`, so the same error face is painted again, unchanged, until the read lands.<br>`lib/features/card/presentation/screens/card_detail_screen.dart:179-184` `lib/features/card/presentation/controllers/card_detail_controller.dart:25-27` `lib/shared/widgets/mx_async_view.dart:108` — lib/features/card/presentation/screens/card_detail_screen.dart:179-184 — `MxErrorState(title:…, message:…, retryLabel:…, onRetry: () => _retryDetail(ref, cardId))`, no `isRetrying`; |  |
| SC-C3-18 | P3 | I | ProgressDeckScreen (library level, /progress w… | One screen renders the same MxEmptyState two different ways depending on which empty it is, and the library-level one lands off screen. Measured at 393x852 the library-level empty state occupies y 700-876: the NavigationBar's top edge is at 772 and the screen ends at 852, so 72 of its 176dp are visible, its title and message are…<br>`lib/features/progress/presentation/screens/progress_deck_screen.dart:180-189` `progress_deck_screen.dart:299-301` `lib/features/progress/presentation/widgets/sections/progress_level_header_widget.dart:68-76` — Measured with a widget test at kReviewSurface 393x852 over emptyActivitySnapshot(): MxEmptyState Rect.fromLTRB(0.0, 700.0, 393.0, 876.0); NavigationBar Rect.fromLTRB(0.0, 772.0, 393.0, 852.0); |  |
| SC-C3-20 | P3 | A | RouteNotFoundScreen | The route name is a second, invisible copy of the visible title, so a screen-reader user meets two nodes labelled "Page not found" one after the other — a container node spanning the whole padded body, then the title text inside it.<br>`lib/app/fallback/route_not_found_screen.dart:35-40` `lib/shared/widgets/mx_error_state.dart:77-81` `lib/shared/widgets/mx_session_top_bar.dart:199` — lib/app/fallback/route_not_found_screen.dart:35-40 wraps the entire body in `Semantics(namesRoute: true, label: context.l10n.pageNotFoundTitle)` around an `MxErrorState` whose `title:` (line 39) is th… | ⛔ 6 — public contract of shared primitives in lib/shared/widgets/ (MxErrorState would have t… |
| SC-C3-21 | P2 | I | Trash restore-target sheet (showTrashRestoreTa… | Three of the sheet's four faces are Center-based, but only one of them was given the wrap that stops a Center from filling the modal's loose height. Result: the same modal is a full-screen sheet while loading and when there is no eligible target, and a compact card on a read failure and when populated.<br>`lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:74-86` `lib/shared/widgets/mx_loading_state.dart:83` `lib/shared/widgets/mx_empty_state.dart:59` — lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:74-86 wraps only the error face in `Column(mainAxisSize: MainAxisSize.min)`, and :69-73 spells out the mechanism… |  |
| SC-C3-22 | P2 | I | Trash restore-target sheet (showTrashRestoreTa… | The picked target is signalled by colour alone. The rows pass `isSelected` with no leading slot, so the only difference between the chosen deck and the others is MxListTile's selected fill plus a recoloured title.<br>`lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:185-196` `lib/shared/widgets/mx_list_tile.dart:94-97` `lib/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart:207-217` — lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:185-196 builds `MxListTile(title:…, subtitle:…, isSelected: target.deckId == selectedDeckId, onTap:…)` with no `… |  |
| SC-C3-23 | P3 | A | Trash restore-target sheet (showTrashRestoreTa… | The failed-read face uses the sheet's own name as its headline, so a user whose targets read failed sees 'Restore to' in large type above the failure message. The app's error-headline grammar is a 'Couldn't …' phrase or the generic 'Something went wrong' — and this feature's own screen was explicitly moved off the surface-name h…<br>`lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:78` `lib/features/trash/presentation/screens/trash_screen.dart:86-93` `lib/features/card/presentation/widgets/overlays/card_bulk_overlays_widget.dart:107` — lib/features/trash/presentation/widgets/overlays/trash_restore_target_sheet_widget.dart:78 `title: l10n.trashRestoreTargetTitle`, which lib/l10n/app_en.arb:4120 defines as 'Restore to'. |  |
| SC-C3-24 | P2 | I | Reminder settings — time picker reopened after… | After a time change is refused, the screen keeps two recovery affordances that disagree about which value is the user's. `Retry` in the banner re-submits the draft (the time the user actually picked), but tapping the time row again reopens the picker at the *rolled-back stored* time, silently discarding that pick.<br>`lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart:116` `lib/features/reminder/presentation/screens/reminder_settings_screen.dart:138` `lib/features/reminder/domain/usecases/change_reminder_time_use_case.dart:43-46` — lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart:116 passes the stored value: `onTap: () => onTimePressed(settings.time)`; |  |
| SC-C3-25 | P3 | H | Reminder settings — time picker dialog footer | The commit action reads "OK" from `MaterialLocalizations`, not from the ARB. Every other overlay in lib/features/ names the verb it performs, and the two shared overlay primitives make that structural by requiring the label in the constructor — so this is the one place in the app where a user confirms a fallible write with a wor…<br>`lib/features/reminder/presentation/widgets/overlays/reminder_time_picker_widget.dart:24-28` `time_picker.dart:2644` `time_picker.dart:2635` — lib/features/reminder/presentation/widgets/overlays/reminder_time_picker_widget.dart:24-28 passes no `confirmText` and no `cancelText`, so Flutter falls back to `localizations.okButtonLabel` (time_pic… |  |
| SC-C3-26 | P2 | I | Study entry — screen behind the sheets | A failed read renders as an empty state: the error face is titled with the app's name and its message is the nothing-due copy, so a storage failure tells the user their deck has nothing to review. It also offers no retry, where every sibling error face names the failure and most offer one.<br>`study_entry_screen.dart:131-134` `study_entry_section_widget.dart:70` `study_home_screen.dart:97-105` — study_entry_screen.dart:131-134 — MxErrorState(title: context.l10n.appTitle, message: context.l10n.studyNothingDueMessage), no retryLabel, no onRetry. app_en.arb:3 'appTitle': 'MemoX'; |  |
| SC-C3-27 | P2 | I | Study entry — mode chooser sheet (BR-99, BR-14… | A mode that cannot run is made non-tappable but not disabled: its title and subtitle paint at exactly the same values as a runnable mode, so the only signal that a row is dead is reading its subtitle sentence. The sheet's own class doc says these modes are 'disabled with its reason';<br>`study_mode_chooser_widget.dart:78-84` `mx_list_tile.dart:147` `move_deck_sheet_widget.dart:172` — study_mode_chooser_widget.dart:78-84 — MxListTile(title:, subtitle:, onTap: isAvailable ? ... : null); isEnabled is left at its default true. |  |

---

### C4 — Navigation and chrome grammar — one action, two grammars

**21 findings** (P1 3 · P2 14 · P3 4), across 12 surface units.

#### SC-C4-02 · P1 · H CHROME · CardEditorScreen — create mode

| | |
|---|---|
| **State** | populated |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/card/presentation/screens/card_editor_screen.dart`, `lib/features/card/presentation/widgets/sections/card_create_form_widget.dart`, `lib/features/card/presentation/widgets/overlays/card_discard_confirm_widget.dart` |

**Problem.** Create mode has no unsaved-work guard at all: the × and the Android back gesture both drop a fully typed card silently. The screen's own documented contract is "There is one way out" (card_editor_screen.dart:43-46) and it is implemented for edit only. The app's guard grammar is established in two features, so this is the single surface that breaks it — and it breaks it in the direction that costs data.

**Evidence.** lib/features/card/presentation/screens/card_editor_screen.dart:172-177 — the create branch returns `MxContentShell(... leading: _closeButton(context, _pop) ...)` with NO `PopScope`; `_pop()` at :387 is a bare `Navigator.of(context).pop()`. `CardCreateFormWidget` (card_create_form_widget.dart, 179 lines) contains no `PopScope` and no discard confirm, and it autofocuses the front field (:122 `shouldAutofocus: true`), so the user is typing from the first frame. SIBLINGS: edit mode, same file, card_editor_screen.dart:252-257 `PopScope<Object?>(canPop: !_hasUnsavedWork, onPopInvokedWithResult: ... _handleExitRequest)`; card_import_screen.dart:198-205 `PopScope(canPop: false)` plus `_cancel()` at :75-85 calling `showCardImportDiscardConfirm`; deck_form_widget.dart:173-193 `_cancel()` calling `showMxConfirm` for a form holding one name field. `grep -rn PopScope lib` returns 5 screen call sites and create is the one form route that is not among them.

**Target composition.** Wrap the create branch in the same shape edit uses: `PopScope(canPop: !hasTypedContent)` + one exit coordinator that both `_closeButton` and the pop handler call, reusing the existing `showCardEditorDiscardConfirm` (widgets/overlays/card_discard_confirm_widget.dart:27). Create needs no baseline comparison — its dirty predicate is "any of the five `TextEditingController`s is non-empty", which the form already owns.

**Test required.** Widget test in create mode mirroring card_editor_concept_test.dart:186 ("back arrow, Cancel and the gesture ask the same question"): type into the front field, then (a) tap the × and (b) fire the system back; both must show the `showCardEditorDiscardConfirm` dialog, and "Keep editing" must leave the route mounted with the text intact. A pristine create form must pop with no dialog.

#### SC-C4-05 · P1 · H CHROME · DeckListScreen (root + level)

| | |
|---|---|
| **State** | populated |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/deck/presentation/screens/deck_list_screen.dart`, `lib/features/card/presentation/screens/card_list_screen.dart` |

**Problem.** The app has two chrome grammars for the same "create the thing this list holds" action. The deck level puts it in a floating action button; the card list — one tap away, reached by opening a card deck — puts it in the app bar as a plain icon button, and its code still asserts the two match. The deck list's FAB is also the app's only FloatingActionButton (`grep floatingActionButton lib/features/` returns exactly one hit), so a user moving deck level -> card list sees the primary create verb change position, weight and colour tier for no reason the screens explain.

**Evidence.** lib/features/deck/presentation/screens/deck_list_screen.dart:207-213 builds `MxFab(icon: Icons.add, label: _createLabel(...))` — a filled, elevated, bottom-right control; `_createLabel` (:360-363) resolves to `deckCreateRootAction` ("New deck") or `deckCreateSubDeckAction` ("New sub-deck"). SIBLING: lib/features/card/presentation/screens/card_list_screen.dart:176-183 renders the same-class action as `MxIconButton(icon: Icons.add, semanticLabel: cardListNewAction)` in `actions:`, and the comment directly above it at :157-162 states the intent that is now false — "The add action lives on the app bar, not a floating button — the same place the deck list puts its create action, so 'the primary action' sits in one spot across the app. A FAB would also carry Material's default primaryContainer, a second emphasis tone...". deck_list_screen.dart:197-204 records the reversal (M4.10ag, owner review 2026-08-20) that made that comment stale.

**Target composition.** One create grammar app-wide. The last recorded owner decision is the floating action (deck_list_screen.dart:197-204), so the alignment is the card list adopting the existing `MxFab` in `MxContentShell.floatingActionButton` and dropping its bar `Icons.add`; the reverse (deck level returns to a bar `MxIconButton`) is equally valid but contradicts that decision. Either way both screens must then agree, and card_list_screen.dart:157-162 must be rewritten to describe what is actually built. No new shared widget: `MxFab` and `MxIconButton` both already exist and neither API changes.

**Test required.** A cross-feature widget test (e.g. `test/app/create_affordance_grammar_test.dart`) that pumps `DeckListScreen` and `CardListScreen` against the same fake data and asserts the create action is found through the same widget type on both — `find.byType(MxFab)` either `findsOneWidget` on both or `findsNothing` on both — so a future divergence fails rather than being re-argued in a comment.

#### SC-C4-21 · P1 · H CHROME · Tag filter sheet / Tag rename sheet

| | |
|---|---|
| **State** | all states |
| **Verification** | **UNVERIFIED** — single reviewer |
| **Frozen contract** | — |
| **Files** | `lib/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart`, `lib/features/card/presentation/widgets/overlays/tag_rename_widget.dart`, `lib/features/deck/presentation/widgets/overlays/deck_form_widget.dart`, `lib/features/deck/presentation/widgets/overlays/move_deck_sheet_widget.dart` |

**Problem.** Both sheets set their title as a bare Text, so a screen reader meets the name of a newly-opened surface as an ordinary sentence and cannot jump to it. Every other content-bearing sheet in the app — including the two in this same unit — wraps the title in Semantics(header: true).

**Evidence.** card_tag_filter_sheet_widget.dart:91 is `Text(context.l10n.tagFilterTitle, style: context.texts.titleMedium)` and tag_rename_widget.dart:129 is `Text(context.l10n.tagRenameTitle, style: context.texts.titleMedium)` — neither has a Semantics wrapper. Ten sibling sheets do, all at the same titleMedium/titleLarge rung: card_export_sheet_widget.dart:307-311 and card_bulk_overlays_widget.dart:88-92 (same unit, both carrying the comment 'The sheet's title announces as a header (A20.1 P1-01, §23 #17)'), trash_restore_target_sheet_widget.dart:170-175, study_mode_chooser_widget.dart:61-64, study_resume_widget.dart:36-39, study_direction_chooser_widget.dart:125-128, starter_install_widget.dart:127-130, deck_reset_progress_widget.dart:86-89, deck_scheduler_change_widget.dart:91-94 and :167-170. The policy is written down at mx_sheet.dart:48-56: 'One of seventeen sheets said header: true before A20.1 P1-01 ... a heading is how a reader knows a new surface has a name, and jumps to it.' Systemic rather than local: the same two files in the deck feature miss it — deck_form_widget.dart:106 and move_deck_sheet_widget.dart:73-76 — which is 2 features and 4 sheets. The reason it drifted is that mx_sheet_test.dart:34-45 asserts SemanticsFlag.isHeader only on MxSheetHeader (the MxActionSheet path); a feature sheet that builds its own title Text is unguarded, and both offenders are the two sheets that go through showMxFormSheet, which adds insets and scroll (mx_form_sheet.dart:44-52) but no header.

**Target composition.** Wrap both titles in Semantics(header: true), byte-identical to card_export_sheet_widget.dart:307-311. Same fix applies to deck_form_widget.dart:106 and move_deck_sheet_widget.dart:73-76 if the parent wants the cross-feature half closed in the same pass.

**Test required.** Assert SemanticsFlag.isHeader on the sheet-title node in test/features/card/presentation/card_tag_filter_sheet_test.dart and test/features/card/presentation/tag_rename_test.dart, mirroring the assertion at test/shared/widgets/mx_sheet_test.dart:45. Better placement for the systemic half: extend test/features/card/presentation/card_screens_accessibility_sweep_test.dart, which today contains no sheet assertion at all (grep for 'sheet|header' returns nothing).

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C4-01 | P2 | H | LibrarySearchScreen | Every result row ends in `Icons.north_east` — the app's only use of that glyph, and conventionally the mark for "opens outside this app". Both destinations are ordinary in-app pushes, and the app already has one glyph for "there is a screen behind this".<br>`lib/features/search/presentation/widgets/items/search_result_shell_widget.dart:83` `lib/features/search/presentation/screens/library_search_screen.dart:74-79` `lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart:108-113` — lib/features/search/presentation/widgets/items/search_result_shell_widget.dart:83 — `const MxIcon(Icons.north_east, size: MxIconSize.sm)`, on every row of both groups. |  |
| SC-C4-03 | P2 | H | CardEditorScreen — edit mode | The chrome slots are inverted. The pinned `subheader` — the slot whose whole purpose is a breadcrumb that must not scroll away — carries a transient flag-write error, while this screen's breadcrumb sits inside the scroll and disappears as soon as the user reaches the tags or the Trash card.<br>`card_editor_screen.dart:274-279` `card_editor_form_widget.dart:72` `card_editor_context_widget.dart:116` — card_editor_screen.dart:274-279 puts `CardWriteFailureTextWidget` (the flag failure) into `MxContentShell.subheader`; |  |
| SC-C4-04 | P3 | H | CardEditorScreen — edit mode | Edit mode is the only screen in the app that stacks two pinned bottom bands: its own action bar (Cancel / Save changes + the local-only note) sitting directly on top of the four-destination navigation bar.<br>`app_router.dart:168-175` `app_navigation_shell.dart:35` `card_editor_screen.dart:280` — Both editor routes are nested inside the Decks `StatefulShellBranch` — app_router.dart:168-175 (create) and :193-201 (edit), under the card list at :157 — so `AppNavigationShell`'s `MxNavigationBar` (… |  |
| SC-C4-06 | P2 | H | DeckListScreen (root + level) | The same `MxBreadcrumb`, answering the same "where am I in the deck tree" question on two screens one tap apart, is composed four different ways. Opening a card deck from this screen swaps the strip from a 32dp line inside the app-bar title to a 48dp band below the bar, adds a trailing step repeating the bar title, and drops the…<br>`lib/features/deck/presentation/widgets/sections/deck_path_widget.dart:76-100` `deck_list_screen.dart:223` `mx_content_shell.dart:281` — lib/features/deck/presentation/widgets/sections/deck_path_widget.dart:76-100 — `lineHeight: MxBreadcrumb.compactLineHeight` (:81) = `AppSizing.controlDense` = 32dp, `upIcon: Icons.chevron_left` (:86),… |  |
| SC-C4-07 | P2 | H | CardImportScreen — pinned subheader (all wizar… | The wizard draws the same deck-path strip the card list and the card editor draw, in the same pinned subheader slot, but passes neither `onUp` nor `onShowAll` and gives no item an `onTap`.<br>`lib/features/card/presentation/widgets/sections/card_import_context_widget.dart:43-56` `lib/shared/widgets/mx_breadcrumb.dart:317` `lib/features/card/presentation/widgets/sections/card_breadcrumb_widget.dart:53-54` — lib/features/card/presentation/widgets/sections/card_import_context_widget.dart:43-56 passes only `semanticLabel`, `rootIcon`, `collapseAfter: 3` and `items`. |  |
| SC-C4-08 | P2 | H | ProgressScreen | The pinned range strip never draws the chrome/content hairline, so deck rows scroll under it with no seam — the strip is painted in `scaffoldBackgroundColor` and the rows behind it are on the same page colour, so a row simply vanishes at the strip's bottom edge.<br>`progress_deck_screen.dart:231-237` `mx_content_shell.dart:400` `mx_content_shell.dart:419-427` — progress_deck_screen.dart:231-237 `MxSubheaderBand(gutter: gutter, child: ProgressRangeSelectorWidget(...))` — `isScrolled` omitted, so it takes the `false` default at mx_content_shell.dart:400, and t… | ⛔ 11 MxContentShell chrome contract — partially: wiring `MxSubheaderBand.isScrolled` from th… |
| SC-C4-09 | P3 | H | ProgressScreen | Progress drills the same 10-level deck tree as the Library and by the same mechanism, but answers "where am I" with a different grammar: the app-bar title is the bare deck name and nothing else on the chrome carries the path.<br>`progress_deck_screen.dart:162` `progress_deck_screen.dart:311-319` `deck_list_screen.dart:223` — progress_deck_screen.dart:162 `title: snapshot.scopeName ?? context.l10n.progressTitle` — no `titleSubline`, no `subheader`; |  |
| SC-C4-10 | P2 | H | CardListScreen | The deck trail is composed differently from the deck path it documents itself as mirroring, in three measurable ways at once: it sits in the shell's subheader band instead of the app-bar subline, it omits the up chevron that tells the reader the whole strip is a control, and it ends with a step that repeats the app-bar title and…<br>`lib/features/card/presentation/screens/card_list_screen.dart:146` `lib/shared/widgets/mx_content_shell.dart:281` `lib/features/card/presentation/widgets/sections/card_breadcrumb_widget.dart:44-60` — lib/features/card/presentation/screens/card_list_screen.dart:146 and :271 put CardBreadcrumbWidget in `subheader:`; |  |
| SC-C4-11 | P2 | H | CardListScreen | "Create the thing this list holds" has two grammars one route-redirect apart: an unlabeled 48dp app-bar glyph here, an extended filled MxFab on the deck list. The comment that justifies the app-bar placement describes a deck-list state that was reversed on 2026-08-20, so the stated reason for the divergence is no longer true.<br>`lib/features/card/presentation/screens/card_list_screen.dart:157-161` `lib/features/deck/presentation/screens/deck_list_screen.dart:194-204` `lib/core/theme/components/actions/app_fab_theme.dart:23-24` — lib/features/card/presentation/screens/card_list_screen.dart:157-161 — "The add action lives on the app bar, not a floating button — the same place the deck list puts its create action … A FAB would a… |  |
| SC-C4-12 | P2 | H | CardListScreen | Selection mode is expressed with two controls for leaving it and keeps the filter chrome live, where the app's only other multi-select surface uses one control and removes the chrome.<br>`lib/features/card/presentation/screens/card_list_screen.dart:194-199` `mx_content_shell.dart:281` `lib/features/card/presentation/widgets/sections/card_selection_bar_widget.dart:136-140` — lib/features/card/presentation/screens/card_list_screen.dart:194-199 `PopScope(canPop: !selection.isSelecting, onPopInvokedWithResult: … _clearSelection)` repurposes the bar's back affordance, which i… |  |
| SC-C4-13 | P3 | H | CardListScreen | Choosing the order of a list has two shapes in the app. This screen states the order in a quiet label-sm with a trailing expand_more inside an MxMenuButton; the deck list states it in a brand-ink label-md with a leading swap_vert inside an MxTextButton that opens a sheet.<br>`lib/features/card/presentation/widgets/support/card_sort_control_widget.dart:38-68` `lib/features/deck/presentation/widgets/sections/deck_list_toolbar_widget.dart:93-121` `card_sort_control_widget.dart:56` — lib/features/card/presentation/widgets/support/card_sort_control_widget.dart:38-68 — MxMenuButton whose child is Text(_label, context.texts.labelSmall inked AppInk.quiet) followed by `const MxIcon(Ico… |  |
| SC-C4-14 | P2 | H | TrashScreen | There are two back grammars for the same gesture in the same app. In selection mode the ✕ replaces the app bar's back arrow, so the only visible way out clears the selection — but the Android system back gesture still pops the route and leaves Trash entirely, discarding the selection.<br>`lib/features/trash/presentation/screens/trash_screen.dart:36-98` `lib/shared/widgets/mx_content_shell.dart:281` `lib/features/card/presentation/screens/card_list_screen.dart:194-199` — lib/features/trash/presentation/screens/trash_screen.dart:36-98 contains no `PopScope` at any level; the body is handed straight to `MxAsyncView` at :83. |  |
| SC-C4-15 | P2 | H | ProgressDeckScreen (deck level, /progress/:dec… | The deck level's entire chrome is a bar title holding the deck's own name, so at depth 3 or deeper the screen cannot answer 'which Verbs is this'. This is the app's third surface that walks the deck tree and the only one without a path: Deck renders MxBreadcrumb in MxContentShell.titleSubline and Card renders MxBreadcrumb in MxC…<br>`lib/features/progress/presentation/screens/progress_deck_screen.dart:160-177` `lib/features/progress/domain/models/deck_activity_snapshot_model.dart:38` `lib/features/progress/data/mappers/progress_mapper.dart:136-145` — lib/features/progress/presentation/screens/progress_deck_screen.dart:160-177 — MxContentShell(title: snapshot.scopeName ?? context.l10n.progressTitle, padding: EdgeInsets.zero, body: ...) with no subh… |  |
| SC-C4-16 | P2 | H | Move deck sheet | The move picker commits on row tap: tapping a target fires moveDeck immediately, moving a whole subtree, with no selected state drawn and no confirm step. The app's other write-target picker - trash restore - does the opposite and documents why: a tap only selects, the row shows the selection, and a separate primary commits.<br>`move_deck_sheet_widget.dart:136-140` `trash_restore_target_sheet_widget.dart:194-195` `trash_restore_target_sheet_widget.dart:105-110` — Commit-on-tap: move_deck_sheet_widget.dart:136-140 'itemBuilder: ... _TargetRow(..., onTap: () => onChoose(targets[index]))' wired at :92-94 straight to 'ref.read(moveDeckControllerProvider(deckId).no… |  |
| SC-C4-17 | P3 | H | RouteNotFoundScreen | The screen never states a chrome policy, so whether it draws an app bar is decided by how the user arrived rather than by the screen. Reached as a top-level error match it renders no bar at all;<br>`lib/app/fallback/route_not_found_screen.dart:31` `lib/shared/widgets/mx_content_shell.dart:67` `lib/shared/widgets/mx_content_shell.dart:264-272` — lib/app/fallback/route_not_found_screen.dart:31 — `MxContentShell(body: ...)` passes neither `title:` nor `chrome:`, so `chrome` falls through to `MxShellChrome.auto` (lib/shared/widgets/mx_content_sh… |  |
| SC-C4-18 | P2 | H | AppNavigationShell — screens that cover the sh… | A full-screen task leaves the shell by two different mechanisms. The card-import wizard leaves it declaratively — a GoRoute carrying `parentNavigatorKey: rootNavigatorKey` — so it keeps a URL, is deep-linkable, and the router's `matchedLocation` tells the truth while it is on screen.<br>`lib/app/router/app_router.dart:187` `lib/features/study/presentation/screens/study_entry_screen.dart:303-304` `lib/features/study/presentation/screens/study_home_screen.dart:147-148` — Declarative escape: `lib/app/router/app_router.dart:187` — `parentNavigatorKey: rootNavigatorKey` on the `cardImport` GoRoute (`:180-192`), URL `/decks/:deckId/cards/import`. |  |
| SC-C4-19 | P2 | H | CardEditorScreen, create mode (/decks/:deckId/… | Three screens in the app wear the ✕ leading affordance, which in this codebase means "a task you cancel, not a page you go back from". Two of them cover the shell; the create editor does not.<br>`lib/features/card/presentation/screens/card_editor_screen.dart:413` `lib/app/router/app_router.dart:168-175` `app_navigation_shell.dart:35` — `lib/features/card/presentation/screens/card_editor_screen.dart:413` — `icon: widget.cardId == null ? Icons.close : Icons.arrow_back` — on the shell built at `:172-177`, mounted by `lib/app/router/app… |  |
| SC-C4-20 | P2 | H | Deck level (/decks/:deckId, unset deck) — the… | One action sheet, two adjacent rows, two navigation verbs, and therefore two different landing places when the user cancels. The Import row pushes and says in place why it must ("an unset deck must land on its own detail again, not on a card list it never chose (UC-10, M4.12 W5)").<br>`lib/features/deck/presentation/widgets/overlays/deck_create_child_widget.dart:65` `lib/app/router/app_router.dart:157-162` `lib/features/card/presentation/screens/card_editor_screen.dart:387` — `lib/features/deck/presentation/widgets/overlays/deck_create_child_widget.dart:65` — `context.goNamed(RouteNames.cardEditor, ...)` for the row declared at `:82-90` (`deckCreateCardAction`) — against i… |  |

---

### C5 — Section headings — hand-rolled Text where the shared heading belongs

**6 findings** (P2 5 · P3 1), across 6 surface units.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C5-01 | P2 | F | LibrarySearchScreen | The two group headings ("Decks", "Cards") are a hand-rolled Text rather than the app's one section-heading component, and they land on the same rung, the same tracking and the same ink as the meta path line printed inside the rows they head.<br>`lib/features/search/presentation/widgets/sections/search_group_header_widget.dart:32-44` `lib/core/theme/typography/app_typography.dart:330-336` `lib/features/search/presentation/widgets/items/deck_result_tile_widget.dart:44` — lib/features/search/presentation/widgets/sections/search_group_header_widget.dart:32-44 — `Text(context.mxSearchGroupLabel(group), style: context.texts.labelSmall!.inked(context, AppInk.quiet, isEmpha… |  |
| SC-C5-02 | P2 | I | CardImportScreen — Preview step | When the parse resolves the whole step re-composes rather than filling in: the step's heading travels 229dp down the page, the source line changes surface class, and the loaded step becomes the only one of the three whose content opens with no top-level heading at all.<br>`lib/features/card/presentation/widgets/sections/card_import_preview_step_widget.dart:82` `card_import_preview_summary_widget.dart:69` `lib/features/card/presentation/widgets/sections/card_import_source_step_widget.dart:68` — Measured at 393x852 with the parse gated: while parsing, the standard-rung `PREVIEW` label sits at top 268.0 (lib/features/card/presentation/widgets/sections/card_import_preview_step_widget.dart:82) a… |  |
| SC-C5-03 | P2 | F | ProgressScreen | All four section headings on this surface are hand-set Text in a different type role from the app's single section-heading treatment, and carry no `header` semantics. The app has exactly one group-title component — `MxSectionLabel` (D18, A20.1 P2-02) — used at 14 call sites across card, deck, settings and study;<br>`progress_streak_hero_widget.dart:60` `progress_today_widget.dart:40` `progress_week_widget.dart:60` — progress_streak_hero_widget.dart:60 `texts.labelLarge!.inked(context, AppInk.quiet)`; progress_today_widget.dart:40 same; progress_week_widget.dart:60 same; |  |
| SC-C5-04 | P2 | F | Deck form sheet, Reset progress sheet, Starter… | One semantic element - the heading naming the scheduler radio group - is drawn three different ways inside this unit, and none of the three is the app's section-heading grammar. The three sheets share DeckSchedulerPickerWidget, so the group under the heading is byte-identical;<br>`deck_scheduler_picker_widget.dart:70-71` `deck_form_widget.dart:126-129` `deck_reset_progress_widget.dart:112-115` — Spelling 1 - deck_scheduler_picker_widget.dart:70-71 'Text(sectionLabel!, style: context.texts.labelLarge)', default ink, gap 0 to the radios; used from deck_form_widget.dart:126-129. |  |
| SC-C5-05 | P3 | A | ReminderSettingsScreen | The screen title and the first row's label are the same string, so the strongest slot on the screen is spent twice on the same words: the app bar reads 'Daily reminder' in titleLarge and the first row of the card reads 'Daily reminder' in bodyLarge about 60dp below it.<br>`lib/features/reminder/presentation/screens/reminder_settings_screen.dart:54` `lib/features/reminder/presentation/widgets/items/reminder_toggle_row_widget.dart:45` `test/features/reminder/presentation/reminder_settings_layout_test.dart:127-134` — lib/l10n/app_en.arb:3261 "reminderTitle": "Daily reminder" and :3265 "reminderToggleLabel": "Daily reminder" (identical in vi: app_vi.arb:3261 and :3265, both "Nhắc hằng ngày"), used at lib/features/r… |  |
| SC-C5-06 | P2 | D | SettingsScreen | The gap between an MxSectionLabel and the card it labels is AppSpacing.xs (4) on this screen and AppSpacing.md (12) on every other surface in the app that uses the same standard-rung MxSectionLabel over a card in a scrolling column.<br>`settings_section_widget.dart:33` `settings_screen_geometry_test.dart:155-168` `card_detail_state_widget.dart:51-52` — settings_section_widget.dart:33 `static const double headingGap = AppSpacing.xs;` (4), applied at line 54; settings_screen_geometry_test.dart:155-168 measures it. |  |

---

### C6 — Type rung and emphasis for one semantic element

**5 findings** (P2 3 · P3 2), across 5 surface units.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C6-01 | P2 | F | LibrarySearchScreen | The primary line of a result row — the deck name, the card front — is set at `bodyLarge` (16/24, w400) while every other MxCard row in the app titles at `titleMedium` (16/24, w600).<br>`lib/features/search/presentation/widgets/items/deck_result_tile_widget.dart:50` `lib/features/search/presentation/widgets/items/card_result_tile_widget.dart:77` `lib/core/theme/typography/app_typography.dart:294-300` — lib/features/search/presentation/widgets/items/deck_result_tile_widget.dart:50 and lib/features/search/presentation/widgets/items/card_result_tile_widget.dart:77 — `style: context.texts.bodyLarge` = w… |  |
| SC-C6-02 | P2 | F | CardEditorScreen — create mode | The same five card values are drawn in two different field grammars depending on which mode of the screen you are in. Edit gives every field an external upper-case section label, a Required/optional word and an always-on counter;<br>`card_create_form_widget.dart:116-128` `card_details_section_widget.dart:69` `card_editor_form_widget.dart:79-95` — CREATE: card_create_form_widget.dart:116-128 front is a bare `MxTextField(label:, hintText:, maxLines: 2)`; :130-139 back is `maxLines: 4`; |  |
| SC-C6-03 | P3 | F | TagCatalogScreen | The row's name — the thing the row is about — is set at `titleSmall` (14px/w600), one rung below the rung every other row in the app uses to name its item, and it is the rung this app otherwise reserves for section and panel headings (17 of the 19 non-theme `texts.titleSmall` sites are headings, option-group labels or panel titl…<br>`tag_catalog_row_widget.dart:82` `app_typography.dart:287-293` `trash_row_widget.dart:172` — tag_catalog_row_widget.dart:82 `style: context.texts.titleSmall` = 14px w600 (app_typography.dart:287-293). |  |
| SC-C6-04 | P2 | F | Scheduler change sheet, Reset progress sheet,… | The unit runs two title rungs for the same semantic element. Three of its five sheets title themselves at titleLarge while the other two use titleMedium - and titleMedium is the app's settled modal-title rung everywhere else: ten sheet titles across card, study and trash use it, and the dialog theme sets it for every dialog.<br>`deck_reset_progress_widget.dart:89` `deck_scheduler_change_widget.dart:94` `starter_install_widget.dart:130` — titleLarge, all four occurrences in the app and all four in deck: deck_reset_progress_widget.dart:89, deck_scheduler_change_widget.dart:94 and :170, starter_install_widget.dart:130. |  |
| SC-C6-05 | P3 | F | Study entry — resume sheet (BR-103) | The supporting line under the sheet title is the only one of its kind painted at full onSurface ink, and it sits at a 4dp gap — so neither the gap nor a tonal step separates an 86-character paragraph from the 16sp semibold title directly above it, and the two read as one block.<br>`study_resume_widget.dart:42-43` `study_direction_chooser_widget.dart:131-134` `starter_install_widget.dart:133-136` — study_resume_widget.dart:42-43 — SizedBox(height: AppSpacing.xs) then Text(studyResumeBody, style: context.texts.bodyMedium) with no ink; |  |

---

### C7 — Responsive and text-scale breakage

**5 findings** (P1 3 · P2 2), across 5 surface units.

#### SC-C7-01 · P1 · J RESPONSIVE · StarterLibraryScreen

| | |
|---|---|
| **State** | populated / textScale-2.0 |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/deck/presentation/screens/starter_library_screen.dart` |

**Problem.** `_TemplateTile` puts an `Expanded` identity column and a non-flexible trailing word in one fixed `Row` that never re-arranges. Because a `RenderFlex` sizes the non-flex child at its full intrinsic width first, the repeated word 'Add to library' — identical on every un-added row, so pure non-information — takes its full scaled width and the deck name, the only thing that distinguishes one row from another, gets whatever is left. At the app's supported large-text scale the name is crushed on ordinary phones, not just at the 320dp floor.

**Evidence.** lib/features/deck/presentation/screens/starter_library_screen.dart:114-161 — `Row(children: [Expanded(Column(title,…)), SizedBox(width: AppSpacing.md), Text(installed ? … : …)])`, no `Flexible`, no `LayoutBuilder`, no `maxLines` on the trailing `Text`. Measured widths of the card's 329dp content band at 393×852: scale 1.3/en title 175.0 vs trailing 108.8; scale 2.0/en title 153.4 vs trailing 163.6; scale 2.0/vi title 93.8 (28.5%) vs trailing 223.2 (67.8%). At 360×780 scale 2.0/vi: title 60.8 of 296 (20.5%) vs trailing 223.2. At 320×640 scale 2.0/vi: title 28.8 of 264 (10.9%) — about one glyph. Sibling that solved the identical shape: lib/features/study/presentation/widgets/items/study_home_deck_item_widget.dart:160-186 wraps the same `Expanded` + trailing-action row in a `LayoutBuilder` that stacks the action below when `constraints.maxWidth < MediaQuery.textScalerOf(context).scale(AppStudyHomeDeckCard.inlineActionMinWidth)`; the constant is 320 at line 203 and its doc records that at text scale 2.0 the scaled threshold of 640 stacks on every supported phone. The starter card's content band is 329 at 393dp and 264 at 320dp — both far under 640 — so the same rule would stack it and it does not.

**Target composition.** Wrap the row in a `LayoutBuilder` with the same scaled-threshold rule the study-home row already uses, stacking the trailing state/action under the identity column with one `AppSpacing.md` seam (the arrangement `study_home_deck_item_widget.dart:166-177` uses), and give the trailing `Text` `maxLines: 1, overflow: TextOverflow.ellipsis` like every other text in the tile. Existing widgets and existing tokens only.

**Test required.** A stress test that pumps the screen at 393×852 and 360×780 with `TextScaler.linear(2.0)` in both `en` and `vi`, and asserts via `tester.getRect` that the deck-title box keeps at least half of the card's content width — i.e. the row has stacked. Mirror `test/features/study/.../study_home_*` where the inline/stacked threshold is already pinned.

#### SC-C7-03 · P1 · J RESPONSIVE · StudyOptionsScreen

| | |
|---|---|
| **State** | populated (isRootOverride) at compact-320 / textScale-2.5 |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/study/presentation/screens/study_options_screen.dart` |

**Problem.** The body does not scroll. At 320dp with textScale 2.5 the form column overflows the viewport and the secondary action `Use app defaults` is clipped off the bottom with nothing to scroll it back. It is an input screen (a text field), so 2.5 is inside the review range, and 320dp is a supported width the theme explicitly steps down for.

**Evidence.** lib/features/study/presentation/screens/study_options_screen.dart:46 — `MxContentShell(...)` is constructed without `isScrollable`, so lib/shared/widgets/mx_content_shell.dart:353-355 returns `Padding(padding: resolvedPadding, child: widget.body)` — a fixed, unscrollable Column. MEASURED by pumping the real screen inside `ReviewApp` at 320x852: with `isRootOverride: true`, textScale 2.5 -> `A RenderFlex overflowed by 72 pixels on the bottom`; with the card-limit error line also shown, 112 pixels, and the `MxTextButton` for "Use app defaults" lands at Rect.fromLTRB(28.0, 836.0, 292.0, 936.0) against an 852 viewport. At 320 x 2.0 it still fits (Save 444-508, Use-app-defaults 624-672), so the break is at 2.5. SIBLING that does it differently: lib/features/reminder/presentation/screens/reminder_settings_screen.dart:59 `isScrollable: true`, with the reason written directly above it at :56-58 — "Two rows, a banner and two paragraphs fit a phone at scale 1 and do not at scale 2 - and the honest fix for a screen that outgrows its viewport is to let it scroll". SECOND SIBLING: lib/features/settings/presentation/screens/settings_screen.dart:51 and lib/features/card/presentation/screens/card_editor_screen.dart:175. Every other form screen in the app scrolls; this is the only one that does not.

**Target composition.** `isScrollable: true` on the existing `MxContentShell` call, which is exactly what reminder and settings pass. No new widget, no token change.

**Test required.** Stress test at 320x852 with textScale 2.5 and `isRootOverride: true` (and again with a `cardLimitProblem` set): assert zero `FlutterError` overflow reports, and assert the `MxTextButton` rect is reachable — inside the viewport after `tester.scrollUntilVisible`.

#### SC-C7-05 · P1 · J RESPONSIVE · StudyEntryScreen

| | |
|---|---|
| **State** | textScale-2.0 (measured at 360dp, the promised floor, and at 393dp; both locales) |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/study/presentation/widgets/sections/study_entry_section_widget.dart` |

**Problem.** The counts row is a bare `Row` of two unconstrained `Text`s with a fixed spacer — no `Wrap`, no `Flexible`, no `maxLines` — so it cannot break, wrap or ellipsize. At the size the project promises to fit (360x640 at textScaler 2.0) it paints RenderFlex overflow stripes across the screen's primary content with ordinary inputs: three-digit counts in Vietnamese, four-digit counts in English. Counts here aggregate a deck subtree, and the app's own code documents four figures as an ordinary number for somebody who has been away.

**Evidence.** study_entry_section_widget.dart:39-56 — `Row(children: [Text(l10n.studyNewCount(...)), SizedBox(width: AppSpacing.lg), Text(l10n.studyDueCount(...))])`, no flex child, no maxLines. MEASURED on the real screen at textScaler 2.0: en/360dp/1024 → "A RenderFlex overflowed by 21 pixels on the right"; vi/360dp/128 → overflowed by 32 pixels; vi/360dp/1024 → 75 pixels; vi/393dp/1024 → 42 pixels (vi strings are longer: app_vi.arb:1598 "Mới {count}", :1607 "Đến hạn {count}"). 360x640 at textScaler 2.0 is the stated floor — app_breakpoints.dart:10-22: "Screen tests run at 360x640 now, at textScaler 2.0, which is the guarantee worth keeping." Fixing the double gutter alone does not fix it: the vi/360/128 case overflows by exactly the 32dp the gutter fix returns. SIBLINGS, three of them, all solved this and all say why: study_home_workload_item_widget.dart:59-61 wraps the same kind of fact in `Wrap(spacing: md, runSpacing: xs)` with `Flexible` + `maxLines: 2` and :193-197 explains four digits is ordinary; progress_metric_widget.dart:197-199 uses `Flexible` "so a long word at double scale wraps ... instead of overflowing", and :128-134 records a four-figure count clipping to a different number at 320dp/2.0; deck_workload_line_widget.dart:103-108 uses `Wrap(spacing: sm, runSpacing: xs)`.

**Target composition.** Replace the `Row` at study_entry_section_widget.dart:39-56 with the shape the three siblings already use — a `Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center)` of the two counts, each `Text` given `maxLines: 2` so a count can never be truncated into a different number. Existing tokens, local layout only.

**Test required.** Stress test pumping the real StudyEntryScreen over a repository returning four-digit counts, across {360dp, 393dp} x {en, vi} at textScaler 2.0, asserting `tester.takeException()` is null in every cell — the same matrix reproduced the four failures above, so it fails today and would not pass on the current code.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C7-02 | P2 | J | CardImportScreen — Preview step, mapping rows | The mapping row splits the column 50/50 between the source-column label and the destination dropdown with no measured fallback, so at large text the destination — the whole decision of the step — is truncated. Three other components in this same screen measure the available width and stack instead;<br>`lib/features/card/presentation/widgets/items/card_import_mapping_row_widget.dart:43-71` `lib/features/card/presentation/widgets/sections/card_import_preview_step_widget.dart:323-346` `lib/features/card/presentation/widgets/sections/card_import_source_step_widget.dart:135-149` — lib/features/card/presentation/widgets/items/card_import_mapping_row_widget.dart:43-71 is a flat `Row` of `Expanded` + `SizedBox(width: AppSpacing.sm)` + `Expanded`, no LayoutBuilder. |  |
| SC-C7-04 | P2 | J | StudySessionScreen — recall / fill CTA row | `StudyCtaRowWidget` is a private re-implementation of `MxButtonPair` — its own doc restates that widget's contract almost sentence for sentence ("When there are two, they are the same size — the row's whole job") — with two consequences.<br>`lib/features/study/presentation/widgets/sections/recall_timer_pieces_widget.dart:269-303` `lib/shared/widgets/mx_button_pair.dart:131` `lib/shared/widgets/mx_confirm_dialog.dart:148` — MEASURED at 320dp width, `buildLightTheme()`, labels `Forgotten`/`Remembered`. StudyCtaRowWidget: scale 1.0 → buttons LTRB(12,0,154,48) and (166,0,308,48), 142.0 wide each; |  |

---

### C8 — Density and target size inside one semantic family

**4 findings** (P1 1 · P2 1 · P3 2), across 4 surface units.

#### SC-C8-04 · P1 · E DENSITY · CardDetailScreen

| | |
|---|---|
| **State** | populated (loaded card, `CURRENT STATE` panel) |
| **Verification** | **CONTESTED** — 1 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `D:/workspace/memox-v7/.claude/worktrees/app-wide-screen-consistency-0820fe/lib/features/card/presentation/widgets/items/card_metric_widget.dart`, `D:/workspace/memox-v7/.claude/worktrees/app-wide-screen-consistency-0820fe/lib/features/card/presentation/widgets/sections/card_detail_state_widget.dart` |

**Problem.** The schedule panel's metric cells are a second implementation of the app's metric grammar. Every other metric in the app anchors on the shared `MxMetricWell` — a 24×24 pill (16dp glyph + `xs` padding) — including two call sites inside this same feature; Card Detail hand-rolls a 32×32 rounded square at `AppRadius.sm`. The grid rhythm is inverted against the app's other metric grid too, and the well→text gap is a third value. So the same semantic family (icon well + label + figure, two across, inside a flat panel) is drawn at two well shapes, two well sizes, three anchor gaps and two grid rhythms — and the cross-axis gap between two cells is `md`, the inside-a-compact-control step, used as an item gap.

**Evidence.** lib/features/card/presentation/widgets/items/card_metric_widget.dart:75-84 — `Container(width: AppSizing.controlDense (32), height: 32, borderRadius: AppRadius.sm (8), color: surfaceMuted, child: MxIcon(size: MxIconSize.sm = 16))` then `SizedBox(width: AppSpacing.sm)` (8). SHARED PRIMITIVE: lib/shared/widgets/mx_metric_well.dart:46-55 — `AppRadius.pill` + `EdgeInsets.all(AppSpacing.xs)` + 16dp glyph = 24×24 circle. SIBLINGS, same feature: lib/features/card/presentation/widgets/sections/card_import_confirm_step_widget.dart:147 (`MxMetricWell(icon: icon, tint: color)`, gap `md`) whose comment at :142-146 asserts it is "the same anchored square Card Detail's schedule ... read by" — which is not true; lib/features/card/presentation/widgets/sections/card_import_result_widget.dart:276. Other features: lib/features/progress/presentation/widgets/items/progress_metric_widget.dart:192 (gap `AppSpacing.xs` at :193), lib/features/study/presentation/widgets/items/study_home_workload_item_widget.dart:165. GRID RHYTHM: card detail row gap `AppSpacing.lg` and column gap `AppSpacing.md` (lib/features/card/presentation/widgets/sections/card_detail_state_widget.dart:227 and :232, with `md` also in the fold math at :218) against Progress's row gap `AppSpacing.sm` and column gap `AppSpacing.lg` (lib/features/progress/presentation/widgets/items/progress_metric_widget.dart:104 and :117).

**Target composition.** Replace the private well in `CardMetricWidget` with `MxMetricWell(icon: metric.icon, tint: AppInk.accent)` — its API already takes exactly the `AppInk` + default muted `AppWellFill` this cell uses, so nothing shared changes — and adopt one grid rhythm with the Progress grid: cross-axis `AppSpacing.lg` (item gap, not `md`) in both `_MetricGrid`'s `SizedBox(width:)` and its fold arithmetic. Keep the two-line label-over-value cell and the `_minCellWidth` fold rule as they are.

**Test required.** Widget test with `getRect`: assert the schedule grid renders `MxMetricWell` and that its rect equals the rect `MxMetricWell` renders in `card_import_confirm_step_widget` (24×24, not 32×32); assert the horizontal distance between the two cells of one grid row is `AppSpacing.lg`; re-run the existing fold tests (`the metric grid drops to one column at 320dp with 2.0 text`) since the fold threshold arithmetic changes, then regenerate card_detail_light/dark, card_detail_sm2_*, card_detail_320_x2_vi and card_detail_state_grid_vi_x2 goldens on Linux.

**Contested.** One lens refuted this. REFUTED on Lens 2(a): the sibling count is wrong, and applying the target leaves the app no more coherent. The finding counts 5 MxMetricWell call sites against Card Detail as a lone hand-roll. It omits the other three members of the 32dp square-well tier, all of which are the identical widget (`AppSizing.controlDense` square + `AppRadius.sm` + one `MxIconSize.sm` glyph on a muted fill): `tag_catalog_row_widget.dart:49,148-157` (same feature, same `widgets/items/` bucket), `card_import_source_step_widget.dart:313-323`, `card_import_source_summary_widget.dart:63-73`. The real split is 5 (24dp pill) vs 4 (32dp square), not 5 vs 1. Converting one member makes it 6 vs 3 — both tiers still stand, nothing is eliminated, and the app still draws two well shapes for icon-anchored facts. That is "merely different", which is the refutation condition.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C8-01 | P3 | E | LibrarySearchScreen | Inside one list the two row types clamp their primary line differently — a deck name may wrap to two lines, a card front may not — so a long card front ellipsizes while the deck row beside it wraps. It is also the only card front in the app clamped to one line;<br>`lib/features/search/presentation/widgets/items/deck_result_tile_widget.dart:48-53` `lib/features/search/presentation/widgets/items/card_result_tile_widget.dart:75-80` `lib/features/card/presentation/widgets/items/card_tile_widget.dart:175-179` — lib/features/search/presentation/widgets/items/deck_result_tile_widget.dart:48-53 — `Text(hit.name, style: context.texts.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis)`; |  |
| SC-C8-02 | P3 | E | StudyOptionsScreen | `NewCardOrder` is edited as a pill group here and as radio rows on the only other screen that edits it — same heading string, same two option strings, same enum. The reason recorded for the split is no longer true, so the divergence now rests on nothing.<br>`lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:92` `lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart:193` `lib/features/settings/presentation/widgets/support/settings_labels_widget.dart:36-39` — lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:92 `Text(l10n.studyOptionsOrderLabel, style: context.texts.titleSmall)` then :100-110 `Wrap(spacing: AppSpacing.sm, c… |  |
| SC-C8-03 | P2 | E | StudySessionScreen — self_assess vs recall act… | The same string, `l10n.studyRevealAnswer`, is drawn as a 393dp full-bleed bar in `self_assess` and as a 141dp hugged, centred button in `recall` — same screen, same turn, same `MxActionButtonVariant.primary`.<br>`lib/features/study/presentation/widgets/sections/study_card_face_section_widget.dart:262-263` `lib/features/study/presentation/widgets/sections/recall_timer_pieces_widget.dart:189-194` — MEASURED at 393×600, `buildLightTheme()`, scale 1.0: `self_assess` reveal button rect = LTRB(0.0, 552.0, 393.0, 600.0) — width 393.0; |  |

---

### C9 — Screen-local — no repeated pattern behind it

**15 findings** (P1 2 · P2 9 · P3 4), across 13 surface units.

#### SC-C9-12 · P1 · B GROUPING · ProgressDeckScreen (library level, /progress)

| | |
|---|---|
| **State** | populated |
| **Verification** | **CONTESTED** — 1 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/progress/presentation/screens/progress_deck_screen.dart`, `lib/features/progress/presentation/screens/progress_screen.dart`, `lib/features/progress/presentation/widgets/sections/progress_level_header_widget.dart` |

**Problem.** At rest on the reference surface the range selector is the last element on the page and governs nothing that is on screen. Measured at 393x852: the pill strip occupies y 708-756, the NavigationBar's top edge is at y 772, and ProgressSummaryWidget — the first thing the selector actually changes — starts at y 772.0, i.e. exactly at the fold, 0dp visible. The scroll reports maxScrollExtent 585.8 against a viewportDimension of 716, so the entire subject of the screen (the totals panel and every deck row) sits one full viewport below the fold, with 16dp of blank page under the pills that reads as the end of the document. This is precisely the misread the code says the PinnedHeaderSliver was introduced to remove — progress_deck_screen.dart:168-173 rejects MxContentShell.subheader because it 'put the selector above the three overview sections it does not govern: pressing 30 days changed nothing in the 24dp directly under it'. The move relocated the strip but did not fix the condition: at rest it still changes nothing in the 16dp directly under it.

**Evidence.** Measured with a widget test at kReviewSurface 393x852 over the demo fixture from test/demo/feature_screens_demo_test.dart:78-111 (ReviewApp + progressShellWith + FakeProgressRepository.withSnapshot, two decks): ProgressRangeSelectorWidget Rect.fromLTRB(16.0, 708.0, 377.0, 756.0); ProgressSummaryWidget Rect.fromLTRB(16.0, 772.0, 377.0, 940.4); NavigationBar Rect.fromLTRB(0.0, 772.0, 393.0, 852.0); Scrollable maxScrollExtent 585.8, viewportDimension 716.0; find.byType(ProgressDeckRowWidget) built 0 elements. The band that consumes the viewport: lib/features/progress/presentation/widgets/sections/progress_level_header_widget.dart:30-35 Padding LTRB(gutter, AppSpacing.md=12, gutter, AppSpacing.xl=24) around lib/features/progress/presentation/screens/progress_screen.dart:137-146, three MxCard.raised sections separated by two SizedBox(height: AppSpacing.xl=24) at :141 and :143. The strip itself: lib/features/progress/presentation/screens/progress_deck_screen.dart:213-239. SIBLING that does it differently — lib/features/deck/presentation/screens/deck_list_screen.dart:255-292 places DeckListToolbarWidget inline immediately above the rows, measured on the same 393x852 surface as DeckListToolbarWidget Rect.fromLTRB(16.0, 210.9, 377.0, 258.9) with the first DeckTileWidget Rect.fromLTRB(16.0, 258.9, 377.0, 418.9) — control and first governed row both fully above the 772 fold. SECOND SIBLING — lib/features/card/presentation/screens/card_list_screen.dart:146 pins the filter pills in MxContentShell.subheader directly above the ListView they filter.

**Target composition.** Keep the owner-settled section order (overview, then range, totals, decks) and buy back fold space using only existing tokens and existing Mx* widgets. The chrome between the last overview card and the panel is already only 96dp — ProgressLevelHeaderWidget's bottom AppSpacing.xl (24) + MxSubheaderBand's top AppSpacing.sm (8) + the 48dp pill row + AppSpacing.xs (4) + the panel's AppSpacing.md (12) — so spacing alone cannot recover the ~170dp needed and must not be raided (dropping the panel's md would re-break the 16dp the strip and panel are documented to hold, progress_deck_screen.dart:243-249). The lever is the band's own composition in progress_screen.dart:137-146: either move ProgressWeekWidget out of the header and render it as a section below ProgressDeckListWidget, or fold ProgressTodayWidget's two figures into ProgressStreakHeroWidget's existing MxCard.raised so the band is two cards rather than three.

**Test required.** Widget test at kReviewSurface (393x852) mounting progressShellWith over the two-deck fixture: assert tester.getRect(find.byType(ProgressSummaryWidget)).top is strictly less than tester.getRect(find.byType(NavigationBar)).top, and assert find.byType(ProgressDeckRowWidget) evaluates to at least one element with no drag (today it is 0). Add a stress run of the same assertions at 320dp and at textScale 1.3. Then regenerate test/demo/goldens/progress_deck_light.png and progress_deck_dark.png on Linux (TZ=UTC) and republish the screen gallery, since the current PNGs show the defect as if it were the design.

**Contested.** One lens refuted this. Lens 2(a) kills both levers the target offers; 2(b) blocks nothing, so the refutation is on coherence, not on the freeze. Lever 1 — "move ProgressWeekWidget out of the header and render it as a section below ProgressDeckListWidget" — contradicts the target's own opening clause ("Keep the owner-settled section order (overview, then range, totals, decks)"): it puts an overview section after the deck rows. Sibling count, done by reading every list-bearing screen: deck_list_screen.dart:255 (DeckSummarySectionWidget above the toolbar), card_list_screen.dart:146 (panel + pills in subheader), trash_screen.dart:77-79 (TrashFilterBarWidget in subheader), library_search_screen.dart:139 (MxSearchField in subheader), study_home_body_section_widget.dart:171-177 (resume section, then deck items). 5 of 5 put the page-level summary/control before the rows; 0 put one after.

#### SC-C9-13 · P1 · A HIERARCHY · Deck form sheet (create root deck / create sub-deck / rename) and Move deck shee

| | |
|---|---|
| **State** | populated |
| **Verification** | **CONFIRMED** — 2 of 2 adversarial lenses upheld it |
| **Frozen contract** | — |
| **Files** | `lib/features/deck/presentation/widgets/overlays/deck_form_widget.dart`, `lib/features/deck/presentation/widgets/overlays/move_deck_sheet_widget.dart` |

**Problem.** Two of the unit's five content sheets put a plain Text at the top instead of a heading node, so a screen reader meets the sheet's name as an ordinary sentence and cannot jump to it. The deck form is the busiest sheet in the feature - it is the surface behind three separate flows - and the move sheet is the one with a scrollable list under the title, where the heading role matters most. The other three sheets in this same unit do it correctly and carry the comment naming the rule (A20.1 P1-01). This is the same gap in a second feature, which is what makes it systemic rather than local.

**Evidence.** Missing: deck_form_widget.dart:106 'Text(widget.title, style: context.texts.titleMedium)' - no Semantics wrapper; move_deck_sheet_widget.dart:73-76 'Text(context.l10n.deckMoveTitle, style: context.texts.titleMedium)' - no Semantics wrapper. Present in the same unit: deck_reset_progress_widget.dart:85-91, deck_scheduler_change_widget.dart:89-96 and :166-172, starter_install_widget.dart:126-132, each 'Semantics(header: true, child: Text(...))'. Sibling features that do it: trash_restore_target_sheet_widget.dart:169-176, card_export_sheet_widget.dart:307-313, study_mode_chooser_widget.dart:59-66, study_resume_widget.dart:36-39, card_bulk_overlays_widget.dart:89-92. Same gap in the card feature: card_tag_filter_sheet_widget.dart:91 and tag_rename_widget.dart:129. Nothing guards it - test/shared/widgets/mx_sheet_test.dart:34 asserts the heading only for MxSheetHeader, which is used exclusively by MxActionSheet (mx_action_sheet.dart:92), never by a content-bearing sheet.

**Target composition.** Wrap both titles in Semantics(header: true, child: Text(...)) exactly as deck_reset_progress_widget.dart:85-91 already does. No new widget, no shared-primitive change, no visual change - so no golden churn.

**Test required.** Semantics test in the deck harness: open each sheet and assert tester.getSemantics(find.text(<title>)).hasFlag(SemanticsFlag.isHeader), mirroring test/shared/widgets/mx_sheet_test.dart:34. Cover all three deck-form flows, since one widget serves create-root, create-sub-deck and rename.

**P2 / P3 in this cluster** — measurement and citation preserved; none independently re-verified.

| ID | Sev | Dim | Surface | Problem, and the measurement behind it | Frozen |
|---|---|---|---|---|---|
| SC-C9-01 | P2 | A | StarterLibraryScreen | The row's two mutually exclusive trailing words share one type role and differ only by ink, and the emphasis runs backwards: the state that means 'nothing to do here' is painted `AppInk.success` while the screen's only affordance is painted `AppInk.quiet` — the same style the app uses for quiet metadata figures.<br>`lib/features/deck/presentation/screens/starter_library_screen.dart:152-161` `lib/features/deck/presentation/widgets/items/deck_tile_widget.dart:248-261` `deck_tile_widget.dart:286` — lib/features/deck/presentation/screens/starter_library_screen.dart:152-161 — both branches render `context.texts.labelMedium!.inked(context, row.isInstalled ? AppInk.success : AppInk.quiet, isEmphasiz… |  |
| SC-C9-02 | P2 | B | CardEditorScreen — create mode | Create names no deck. The screen says "New flashcard" and shows two empty fields; nothing on it says which of a ten-level-deep deck tree the card is about to be written into.<br>`card_editor_screen.dart:172-177` `card_create_form_widget.dart:113-116` `app_router.dart:168-175` — card_editor_screen.dart:172-177 — create's shell carries `title: context.l10n.cardEditorCreateTitle` ("New flashcard", app_en.arb:1049) and a leading `×`, nothing else; |  |
| SC-C9-03 | P2 | A | StudyHomeScreen | The screen's focal panel is the flattest card on the screen. StudyHomeResumeSectionWidget — the one surface carrying the screen's single filled primary — is drawn with MxCard.tonal, which is AppElevation.none (0dp) on a fill that sits *below* the page, while the two ordinary deck rows under it are MxCard.raised at AppElevation.c…<br>`lib/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart:73` `lib/shared/widgets/mx_card.dart:332-341` `app_elevation.dart:19` — lib/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart:73 `MxCard.tonal(` → lib/shared/widgets/mx_card.dart:332-341 `elevation: AppElevation.none` (=0, app_elevation.da… |  |
| SC-C9-04 | P2 | G | StudyHomeScreen | The resume card paints container ink on a surface fill. All three of its text lines take AppInk.onSecondaryContainer — an ink app_ink.dart:66 documents as "for text on a tinted container, never on the page" — but the card's fill stopped being `secondaryContainer` at M99.98 and is now `semantic.surfaceEmphasis`, a page-adjacent s…<br>`lib/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart:92-96` `app_ink.dart:104` `app_material_roles.dart:123` — lib/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart:92-96, :103-106, :116-119 — three `.inked(context, AppInk.onSecondaryContainer)` calls; | ⛔ 2 — semantic role substitution (swapping one M3 role for another) |
| SC-C9-05 | P3 | B | CardImportScreen — Source step | The section label sits exactly as far from the source-option pair (12) as the option pair sits from the work surface below it (12), so nothing in the spacing says which of the two the label names; the next band then jumps to 24. `md` is doing duty as a band-to-band gap here, which the scale reserves for inside a compact control.<br>`lib/features/card/presentation/widgets/sections/card_import_source_step_widget.dart:69` `lib/features/card/presentation/widgets/sections/card_detail_state_widget.dart:51-52` `lib/features/card/presentation/widgets/overlays/card_export_sheet_widget.dart:314` — lib/features/card/presentation/widgets/sections/card_import_source_step_widget.dart:69 `AppSpacing.md` (label → options) and :71 `AppSpacing.md` (options → work surface) and :89 `AppSpacing.xl` (work… |  |
| SC-C9-06 | P2 | A | CardListScreen | In selection mode the contextual band offers no visible verb at all: all six bulk actions (Move, Add tag, Flag, Unflag, Export, Delete) sit inside one overflow menu, so the state the user deliberately entered presents zero primary CTAs — only a close, a count, select-all and a kebab.<br>`lib/features/card/presentation/widgets/sections/card_selection_bar_widget.dart:134-167` `lib/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart:78-87` — lib/features/card/presentation/widgets/sections/card_selection_bar_widget.dart:134-167 — the Row's children are MxIconButton(Icons.close), Expanded(Text count), MxIconButton(Icons.select_all), _Action… |  |
| SC-C9-07 | P3 | G | StudyOptionsScreen | Two supporting notes of the same semantic role — both 12px bodySmall explanatory copy, 40dp apart in the same column on the same page surface — render at two different inks. One is the primary body ink, the other the secondary.<br>`lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:115` `lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart:216` `lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart:148` — lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:115 `Text(l10n.studyOptionsNextSessionNote, style: context.texts.bodySmall)` versus :133 `style: context.texts.bodySm… |  |
| SC-C9-08 | P2 | G | TrashScreen | Rows of the kind the selection is not holding are dimmed with a raw `0.38` literal. That number is exactly the app's `AppStateOpacity.disabledContent` token — defined for a disabled label or glyph — applied here to a whole row of body text, path and counts.<br>`lib/features/trash/presentation/widgets/items/trash_row_widget.dart:75-77` `lib/core/theme/states/app_interaction_states.dart:90` `lib/core/theme/schemes/app_high_contrast.dart:70` — lib/features/trash/presentation/widgets/items/trash_row_widget.dart:75-77 — `Opacity(opacity: isDimmed ? 0.38 : 1, ...)`, a bare literal; |  |
| SC-C9-09 | P2 | A | StudyEntryScreen | The app bar names the application instead of the screen or the deck, so this is the only screen in the app whose title says nothing about where the user is. Arriving from the Study tab — where the user tapped a named deck row — the back stack reads "Study → MemoX", and nothing on the screen says which deck's two counts these are…<br>`study_entry_screen.dart:118` `card_list_screen.dart:145` `deck_list_screen.dart:134` — study_entry_screen.dart:118 `title: context.l10n.appTitle` → "MemoX" (app_en.arb:3). SIBLING deck-scoped screens all name the deck with a screen-name fallback: card_list_screen.dart:145 `deckContext?.… |  |
| SC-C9-10 | P3 | B | StudyEntryScreen | The two counts are the only 'count + word' pair in the app rendered with neither a visual anchor nor a stepped-down word: they are two undifferentiated `titleMedium` strings, so number and label carry identical weight and the pair reads as the screen's heading rather than as its data — which is how the eye lands on it first on a…<br>`study_entry_section_widget.dart:46-54` `study_home_workload_item_widget.dart:165-190` `progress_metric_widget.dart:146-149` — study_entry_section_widget.dart:46-54: `Text(l10n.studyNewCount(...), style: context.texts.titleMedium)` and `Text(l10n.studyDueCount(...), style: context.texts.titleMedium)` — one rung for numeral an… |  |
| SC-C9-11 | P2 | A | CardDetailScreen | The card's meaning — the back, the thing this read-only screen exists to show (BR-240) — is the quietest content in the hero. It is painted `AppInk.quiet`, the same ink as the *labels* `Example` / `Hint` / `Pronunciation` below it, and one step lighter than those labels' *values*, which are un-inked `bodyMedium` (onSurface).<br>`lib/features/card/presentation/widgets/sections/card_detail_summary_widget.dart:76-79` `lib/core/theme/extensions/app_ink.dart:31-33` `lib/features/card/presentation/widgets/items/card_tile_widget.dart:191-192` — lib/features/card/presentation/widgets/sections/card_detail_summary_widget.dart:76-79 — `Text(card.back, style: context.texts.bodyMedium!.inked(context, AppInk.quiet))` → onSurfaceVariant (lib/core/th… |  |
| SC-C9-14 | P2 | A | Reminder settings — time picker dialog footer | The picker's footer offers Cancel and the commit action at identical emphasis, both drawn as zero-padding text links with no fill, no ripple and no hover surface — so the one modal in this feature has no primary CTA at all, on a commit that reschedules an OS alarm and can fail.<br>`lib/features/reminder/presentation/widgets/overlays/reminder_time_picker_widget.dart:24-28` `lib/core/theme/components/pickers/app_time_picker_theme.dart:30-137` `time_picker.dart:2631-2646` — lib/features/reminder/presentation/widgets/overlays/reminder_time_picker_widget.dart:24-28 passes no button styling, and lib/core/theme/components/pickers/app_time_picker_theme.dart:30-137 sets neithe… | ⛔ 3 — ThemeData / component theme mapping |
| SC-C9-15 | P3 | A | Study entry — screen behind the sheets | A per-deck screen names itself with the app's name. StudyEntryScreen takes a deckId and is the entry to one deck's study flow, but its AppBar title, its async loading label and its error title are all context.l10n.appTitle — so nothing on screen, and nothing in the three sheets that open over it, says which deck the session belo…<br>`study_entry_screen.dart:118` `card_detail_screen.dart:97` `tag_catalog_screen.dart:49` — study_entry_screen.dart:118 title: context.l10n.appTitle, :130 loadingLabel: context.l10n.appTitle, :132 title: context.l10n.appTitle; app_en.arb:3 'appTitle': 'MemoX'. |  |

---

## 5. Cụm, và thứ tự đóng

Một cụm là **một grammar bị vi phạm nhiều lần**, không phải một nhóm màn giống nhau.
Cột *Severity cụm* là mức khi coi cả cụm là một vấn đề; cột *Cao nhất theo màn* là mức
mà reviewer nhìn một màn đã gán. Chênh lệch giữa hai cột là §1.2.

| Cụm | n | Đơn vị | Cao nhất theo màn | Severity cụm | PR |
|---|---|---|---|---|---|
| **C1** Sở hữu gutter | 20 | 16 | P1 | **P1** | chưa mở |
| **C2** Nhịp danh sách và section | 20 | 14 | P2 | **P1** — cùng một grammar sai ở 14 đơn vị | chưa mở |
| **C3** Mặt lỗi và mặt rỗng | 27 | 15 | **P0** | **P0** | chưa mở |
| **C4** Grammar điều hướng và chrome | 21 | 12 | P1 | **P1** | chưa mở |
| **C5** Section heading tự dựng | 6 | 6 | P2 | P2 | chưa mở |
| **C6** Bậc type cho một phần tử ngữ nghĩa | 5 | 5 | P2 | P2 | chưa mở |
| **C7** Vỡ ở responsive / text scale | 5 | 5 | P1 | **P1** | chưa mở |
| **C8** Mật độ và kích thước target | 4 | 4 | P1 | P2 | chưa mở |
| **C9** Cục bộ, không có mẫu lặp | 15 | 13 | P1 | P2 — sửa từng cái | chưa mở |

### 5.1 Thứ tự thi hành

Thứ tự này **không** theo severity. Nó theo phụ thuộc: C1 dịch mép trái của mười sáu
bề mặt, nên chạy nó sau C3 sẽ khiến mọi golden của C3 phải vẽ lại hai lần.

| Đợt | Cụm | Vì sao ở đây |
|---|---|---|
| 1 | **C3** (chỉ P0) | `SC-C3-01` làm `StarterLibraryScreen` bung assertion đỏ ở debug và nuốt mất nút retry ở release. Sửa riêng, một dòng, không đợi ai |
| 2 | **C1** | thay đổi hình học rộng nhất. Chạy trước để mọi cụm sau chỉ vẽ golden một lần |
| 3 | **C2** | nhịp dọc, sau khi mép ngang đã đứng yên |
| 4 | **C3** (phần còn lại) | copy, retry và live region của mặt lỗi — chủ yếu là chữ, ít dịch pixel |
| 5 | **C4** | grammar chrome. Nặng nhất về mặt quyết định, xem §5.2 |
| 6 | **C7** + **C8** | responsive, text scale, target — đo bằng stress test chứ không bằng golden |
| 7 | **C5** + **C6** | heading và bậc type |
| 8 | **C9** | các mục cục bộ còn lại |

### 5.2 C4 mang một quyết định không phải của tôi

C4 chứa **hai grammar tạo mới** cho cùng một hành động: `DeckListScreen` dùng `MxFab`
nổi, `CardListScreen` dùng icon trần trên app bar, cách nhau đúng một lần redirect
route (`SC-C4-06`, `SC-C4-14`). Cả hai đều đúng về mặt component; chỉ có một cái đúng
về mặt sản phẩm.

Hợp nhất chúng đổi diện mạo hai màn được dùng nhiều nhất trong app. Quyết định gốc gần
nhất được ghi lại nằm ở `deck_list_screen.dart:197-204` và nó chọn floating action.
**PR của C4 MUST hỏi chủ dự án trước khi hợp nhất**, chứ không tự chọn rồi báo lại.

---

## 6. Trạng thái từng bề mặt

Không màn nào đã sửa. Cột trạng thái sẽ được cập nhật bởi chính PR đóng cụm.


| Surface unit | P0 | P1 | P2 | P3 | Total | Status |
|---|---|---|---|---|---|---|
| AppNavigationShell (the chrome binding all four branches) — lib/app/sh | 0 | 0 | 3 | 0 | 3 | reviewed · unfixed |
| Card content-bearing sheets | 0 | 1 | 2 | 1 | 4 | reviewed · unfixed |
| CardDetailScreen | 0 | 2 | 2 | 0 | 4 | reviewed · unfixed |
| CardEditorScreen (create + edit) — lib/features/card/presentation/scre | 0 | 1 | 6 | 2 | 9 | reviewed · unfixed |
| CardImportScreen | 0 | 0 | 4 | 2 | 6 | reviewed · unfixed |
| CardListScreen | 0 | 0 | 7 | 1 | 8 | reviewed · unfixed |
| Deck content-bearing sheets | 0 | 2 | 4 | 1 | 7 | reviewed · unfixed |
| DeckListScreen (root + level) | 0 | 2 | 3 | 0 | 5 | reviewed · unfixed |
| LibrarySearchScreen | 0 | 0 | 4 | 1 | 5 | reviewed · unfixed |
| ProgressDeckScreen | 0 | 1 | 2 | 1 | 4 | reviewed · unfixed |
| ProgressScreen | 0 | 0 | 3 | 2 | 5 | reviewed · unfixed |
| Reminder time picker (showReminderTimePicker) | 0 | 0 | 2 | 2 | 4 | reviewed · unfixed |
| ReminderSettingsScreen | 0 | 0 | 3 | 1 | 4 | reviewed · unfixed |
| RouteNotFoundScreen | 0 | 0 | 0 | 2 | 2 | reviewed · unfixed |
| SettingsScreen | 0 | 0 | 3 | 1 | 4 | reviewed · unfixed |
| StarterLibraryScreen | 1 | 1 | 4 | 0 | 6 | reviewed · unfixed |
| Study sheets — StudyResumeWidget, StudyModeChooserWidget, StudyDirecti | 0 | 0 | 3 | 2 | 5 | reviewed · unfixed |
| StudyEntryScreen | 0 | 3 | 3 | 1 | 7 | reviewed · unfixed |
| StudyHomeScreen | 0 | 0 | 2 | 1 | 3 | reviewed · unfixed |
| StudyOptionsScreen | 0 | 2 | 2 | 2 | 6 | reviewed · unfixed |
| StudySessionScreen (all 5 modes) | 0 | 1 | 4 | 2 | 7 | reviewed · unfixed |
| TagCatalogScreen | 0 | 0 | 1 | 3 | 4 | reviewed · unfixed |
| Trash sheets | 0 | 0 | 3 | 1 | 4 | reviewed · unfixed |
| TrashScreen | 0 | 0 | 6 | 1 | 7 | reviewed · unfixed |

---

## 7. DESIGN_SYSTEM_BLOCKED

Sáu finding là **thật** nhưng sửa chúng đòi thay một hợp đồng ở `v1-freeze.md` §2.
Không cái nào được sửa trong pass này, và không cái nào tự mở được một task
design-system:
§3 bắt task đó phải được kích hoạt bởi **một trong năm reopen trigger**, và cột cuối
nói thẳng là chưa cái nào thoả.

Mỗi mục dưới đây có một dòng tương ứng trong bảng **Deferred and descoped** của
`docs/wbs.md`, để nó không chết trong một file `docs/reviews/` thứ hai mươi tư mà
không ai quay lại. Bảng đó là cơ chế sẵn có của repo cho đúng hình dạng này — một
thứ đã biết, đã quyết định là chưa làm, và có điều kiện để xem lại — nên nó được
dùng thay vì đẻ ra sáu số `M100.xx` cho việc có thể không bao giờ chạy.


| ID | Sev | Bề mặt | Sửa nó cần gì | Hợp đồng | Reopen trigger cần có |
|---|---|---|---|---|---|
| `SC-C1-15` | P2 | ReminderSettingsScreen | The two rows of one card have tap targets and ripples of different width. The toggle row's InkWell is 329dp wide, the time row's is 361dp - the full card - so a… | #6 | **trigger 3** — thêm một họ shared primitive/component mới |
| `SC-C1-16` | P3 | Reminder settings — time picker dialog | The time picker sits 16dp in from each screen edge while every other dialog in the app sits 40dp in, so the app's one Material-owned modal is 48dp wider than it… | #6 | **trigger 3** — thêm một họ shared primitive/component mới |
| `SC-C3-20` | P3 | RouteNotFoundScreen | The route name is a second, invisible copy of the visible title, so a screen-reader user meets two nodes labelled "Page not found" one after the other — a conta… | #6 | **trigger 3** — thêm một họ shared primitive/component mới |
| `SC-C4-08` | P2 | ProgressScreen | The pinned range strip never draws the chrome/content hairline, so deck rows scroll under it with no seam — the strip is painted in `scaffoldBackgroundColor` an… | #11 | **trigger 3** — `MxContentShell` phải học thêm một khái niệm mới |
| `SC-C9-04` | P2 | StudyHomeScreen | The resume card paints container ink on a surface fill. All three of its text lines take AppInk.onSecondaryContainer — an ink app_ink.dart:66 documents as "for … | #2 | trigger 2 — thiết kế lại palette/theme có chủ đích |
| `SC-C9-14` | P2 | Reminder settings — time picker dialog foote | The picker's footer offers Cancel and the commit action at identical emphasis, both drawn as zero-padding text links with no fill, no ripple and no hover surfac… | #3 | trigger 2 — thiết kế lại palette/theme có chủ đích |