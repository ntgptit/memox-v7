# Implement Card Import — Card Detail Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Nâng cấp toàn bộ Card Import wizard bằng visual language đã được owner chấp thuận trên Card Detail, đồng thời giữ nguyên nghiệp vụ, dữ liệu và tám presentation phase hiện có |
| **Scope** | Card Import presentation, shell/header/footer, feature widgets, responsive geometry, accessibility, Widgetbook, tests, goldens, gallery và tài liệu parity; không đổi parser, import transaction hay business rule |
| **Source of truth for** | Hướng dẫn triển khai visual hierarchy mới của Card Import; nghiệp vụ vẫn thuộc BR-168…BR-173, UC-10 và wireframe M4.12 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-168…BR-173, UC-10, `docs/wireframes/m4-12-card-import.md`, Card Detail production UI và MemoX design system hiện hành |
| **Updated by task** | Card Import visual hierarchy prompt set |
| **Last updated** | 2026-08-27 |

---

Triển khai trên feature worktree đã sync `origin/main` mới nhất. Đây là
presentation-only refactor. Giữ nguyên route, provider/controller, parser,
mapping, validation, duplicate policy, transaction, result counts, draft
lifecycle và navigation outcome hiện tại.

Card Detail là **visual parent**, không phải layout template để sao chép. Tái sử
dụng ngôn ngữ của nó: page/surface separation, compact typography, section
labels, flat bordered panels, icon wells, status chips, shared gutters và một
cột đọc có giới hạn chiều rộng. Card Import vẫn là wizard thao tác nhiều bước;
stepper, source picker, mapping, preview và sticky actions không được biến thành
timeline hay detail metrics giả.

## Pre-flight

1. Đọc đầy đủ `CLAUDE.md`, `docs/document-conventions.md`, BR-168…BR-173,
   UC-10, wireframe M4.12 và các WBS item Card Import liên quan.
2. Đọc production Card Detail:
   - `card_detail_screen.dart`;
   - `card_detail_summary_widget.dart`;
   - `card_detail_state_widget.dart`;
   - `card_history_section_widget.dart`;
   - các item/support mà ba section đó dùng.
3. Mở và inspect trực tiếp các golden hiện tại, không chỉ đọc test name:
   - `card_detail_light.png`, `card_detail_dark.png`;
   - toàn bộ `card_import_*.png` trong `test/demo/goldens/`.
4. Đọc toàn bộ Card Import presentation tree, current tests, visual audit và
   Widgetbook use case. Lập state × widget inventory trước khi sửa.
5. Re-read API mới nhất của `MxContentShell`, `MxCard`, `MxActionButton`,
   `MxButtonPair`, `MxIcon`, `MxIconButton`, `MxTextField`, `MxBreadcrumb` và
   theme tokens. Không viết prompt assumption thành API nếu main đã đổi.
6. Viết một UI Contract ngắn, Section Table và widget tree theo visible order;
   validate đủ tám phase trước khi code.
7. Không commit/push/PR trong implementation phase. Coordinator delivery sau
   hai recursive review và final gate.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Import đã đủ chức năng nhưng Mapping, Preview options và result facts còn nằm rải trên page background, trong khi Card Detail đã chứng minh flat surface + section hierarchy quét nhanh hơn. | Gom mỗi nhóm quyết định vào một semantic panel, không card-hoá từng dòng. |
| 2 | Import tự dựng `Scaffold`, header padding và footer keyboard inset trong khi `MxContentShell` hiện đã sở hữu app bar, responsive gutter, scroll seam và keyboard-safe footer. | Chuyển màn sang `MxContentShell` và bỏ geometry bị sở hữu hai lần. |
| 3 | Source selector, source work area, info panel và sticky CTA có nhiều visual weight cạnh tranh. | Một current-step work surface là focal; context và guidance dùng quiet/flat treatment. |
| 4 | Wizard có tám phase nhưng polish theo từng ảnh riêng dễ làm stepper, body và footer lệch state. | Mọi visual branch tiếp tục đọc cùng `CardImportPhase`; giữ skeleton ổn định khi parsing/submitting/error. |
| 5 | Update hàng loạt golden có thể hợp thức hoá gutter, width hoặc baseline sai như bug source options trước đây. | Pin material geometry bằng `getRect`, inspect state-by-state rồi mới nhận golden mới. |

## Non-negotiable behavior

Không thêm, bỏ hoặc đổi nghĩa bất kỳ chức năng nào sau:

- một route full-screen, ba bước Source → Preview → Import;
- không tap-jump tới bước chưa hợp lệ;
- upload CSV/TSV/XLSX và paste CSV/TSV như hiện tại; không `.apkg`, drag/drop
  hay giới hạn file giả;
- paste chỉ parse khi bấm Preview và giữ nguyên sau parse error;
- file picker cancel giữ source cũ;
- source selection, mapping, header toggle, sheet selection, duplicate toggle,
  preview classification và typed row reasons;
- Front/Back required; không đổi duplicate/blank/invalid policy;
- Continue vẫn qua Confirm; không import trực tiếp từ Preview;
- commit atomic, một loader trung thực, không progress per-row;
- submitting khoá close/back/submit lần hai;
- completed, completedWithSkips, noCardsAdded và commitFailure giữ đúng copy,
  counts, retry/reset/view-cards behavior;
- discard guard, reset draft và back behavior hiện tại;
- không log source filename, pasted/card content hay error chứa dữ liệu riêng tư.

Không sửa domain/data/DAO/repository/database/generated files. Nếu visual task
phát hiện logic drift, ghi finding và dừng phần đó; không chữa nghiệp vụ trong PR.

## Visual thesis

Card Import là một **compact task workspace**:

- chrome/context cho biết đang ở đâu;
- một surface chính cho quyết định của bước hiện tại;
- supporting information yên hơn, không cạnh tranh CTA;
- status dùng icon + text + semantic tone, không dùng màu đơn độc;
- footer là nơi duy nhất sở hữu progression action;
- typography giữ cỡ gọn của Card Detail; không tăng font toàn app và không
  hardcode `fontSize` để bắt chước screenshot.

## UI Contract

### Global shell

Refactor `CardImportScreen` sang `MxContentShell` nếu API mới nhất vẫn cung cấp
đủ `leading`, `title`, `subheader`, `body`, `padding` và `footer`:

- Close dùng `MxIconButton`, giữ tooltip/semantics và submit lock;
- title vẫn `Import cards`, outcome vẫn `Import results`;
- wizard context nằm trong pinned `subheader`; outcome ẩn toàn bộ context;
- body là một scroll owner duy nhất;
- content dùng `mxScreenGutter(context)` và
  `ConstrainedBox(maxWidth: AppBreakpoints.medium)` như Card Detail;
- footer dùng slot `MxContentShell.footer`, không dùng
  `Scaffold.bottomNavigationBar`, không tự cộng `viewInsets.bottom`, không bọc
  thêm `SafeArea`;
- loại bỏ mọi double gutter giữa shell, context, body và footer;
- scroll content cuối luôn tới được trên footer seam và khi IME mở.

Nếu API shell trên latest main không biểu đạt một requirement, mở rộng shared
component chỉ khi đó là capability tổng quát có ít nhất Card Editor và Import
cùng cần; không tạo feature wrapper bắt chước shell.

### Shared visual grammar inherited from Card Detail

- page dùng app background; grouped content dùng canonical surface;
- cùng một scroll column dùng flat bordered surfaces, không shadow stack;
- section headings dùng `context.textStyles.sectionLabel` và semantic quiet ink;
- titles trong panel dùng `titleSmall/titleMedium`; supporting text dùng
  `bodySmall/bodyMedium`; result hero tối đa `titleLarge`/`headlineSmall` theo
  token hiện hữu;
- key counts dùng tabular figures;
- icon nhận semantic ink qua `MxIcon`; icon-only action qua `MxIconButton`;
- compact icon wells/tone containers dùng token hiện hữu, không mint màu;
- internal label → value rhythm giống Card Detail: `xs`; item → item `sm/md`;
  section → section `xl`;
- `MxCard` recipe/API phải lấy từ latest main. Dùng `flat`/semantic recipe đã
  được phê duyệt; không truyền raw visual knob nếu foundation mới đã đóng API.

Không sao chép Card Detail timeline, scheduler badge, Box grid hoặc study colors
sang Import. Chỉ tái sử dụng grammar, không tái sử dụng product meaning.

### Region order — wizard mode

| Thứ tự | Region | Contract mới | Hành vi giữ nguyên |
|---|---|---|---|
| 1 | App bar | Title gọn, Close rõ | Close/discard/submitting lock |
| 2 | Pinned context | Breadcrumb → compact stepper → destination context, cùng shared edges | Current/completed/future semantics, no tap-jump |
| 3 | Current-step heading | Section-label hierarchy; optional readiness metadata trailing | Phase-derived copy/count |
| 4 | Primary work surface | Một full-width semantic group cho source/mapping/preview/confirm/progress | Inputs và callbacks hiện có |
| 5 | Supporting guidance/error | Inset/quiet band gần object nó giải thích | Typed failure và recovery hiện có |
| 6 | Sticky footer | Một primary hoặc một `MxButtonPair`; reassurance line quiet | Enablement và navigation hiện có |

Không bọc cả context header trong hero card. Import's focal object là work
surface hiện tại; thêm hero cho chrome sẽ tạo hai focal surfaces cạnh tranh.

## Phase-specific layout

### 1. Source và source-ready

- `Choose a source` là section heading.
- Hai source option giữ equal-width/equal-height và stack full-width khi hẹp;
  đổi sang flat interactive-card treatment cùng Card Detail, selected có
  border + check + `Semantics(selected:)`, không saturated fill.
- Cả pair phải chia đúng content width và dùng chung left/right edge với mọi
  panel dưới; không intrinsic inboard width.
- Upload empty là primary work surface full-width: quiet icon well, concise
  prompt, `Choose file` action. Không phóng icon/title thành empty-state hero.
- File selected co về compact source summary hiện có; replace/remove giữ vùng
  chạm và semantics riêng.
- Paste dùng `MxTextField` hiện có; không bọc thêm một card nếu tạo
  surface-on-surface. IME không che footer.
- Information panel là inset/quiet supporting surface: icon + title + body +
  Korean-front/meaning-back/tag hints. Không đổi copy hoặc mapping rule.

### 2. Parsing

- Context/stepper giữ nguyên geometry so với Source.
- Source summary vẫn ở vị trí cũ.
- Parsing panel thay work content tại chỗ, flat surface với một loader, title và
  reassurance. Không thêm loader thứ hai trong footer.
- Back còn hoạt động; primary disabled và nhãn Parsing như hiện tại.

### 3. Preview all-valid và mixed

Sắp xếp thành hai semantic groups, thay vì các control trôi trên nền:

1. **Mapping panel**
   - compact source summary;
   - header toggle;
   - optional sheet selector;
   - `Match columns` label;
   - mapping rows có shared label/value edges, touch target ≥48 và subtle
     separators hoặc spacing, không card cho từng row.
2. **Preview panel**
   - heading `Preview` + `N of N ready` cùng baseline khi đủ chỗ, wrap có chủ ý
     khi hẹp;
   - status chips Ready/Invalid/Duplicate/Blank;
   - Include duplicates nằm trong group này, không lơ lửng giữa sections;
   - preview rows compact, full-width, một stable grid ở 393/412 và stack front/
     back tại 320 hoặc textScale lớn;
   - typed invalid reason nằm dưới đúng row, không chỉ đổi màu/glyph.

Không echo pasted content. Không đổi giới hạn preview rows hay validation.

### 4. Confirm

- Dùng một full-width flat summary panel giống current-state panel của Card
  Detail về hierarchy, không sao chép metrics.
- Destination/deck ở đầu panel; divider subtle; mỗi fact là icon well + label +
  tabular count neo trailing.
- Counts zero vẫn hiện theo W4.
- Back/Import actions giữ footer, không chèn CTA vào panel.

### 5. Submitting

- Confirm panel được thay tại cùng rect bởi submit status panel.
- Một spinner, title, body; không determinate bar hoặc `x of y`.
- Footer giữ geometry, cả actions disabled, primary label `Importing…` và không
  có spinner thứ hai.

### 6–8. Outcomes

Outcome ẩn context/stepper và dùng Card Detail-like reading column:

- status hero là một full-width flat panel: semantic icon well, concise title,
  message; không dùng giant empty-state whitespace;
- summary facts là panel riêng với compact rows, trailing tabular counts;
- complete dùng success cue; skips dùng warning cue; noCardsAdded dùng info cue;
  failure dùng danger cue. Tone không được phủ kín cả màn hoặc là tín hiệu duy
  nhất;
- chỉ render row có nghĩa theo W8; counts và nguồn của count giữ nguyên;
- failure detail nằm gần failure hero, giữ safe typed message;
- footer actions dùng `MxButtonPair`: Import another/View cards hoặc Back to
  preview/Try again; không đổi callbacks.

## Footer contract

Refactor `CardImportActionBarWidget`:

- một action → full-width `MxActionButton`;
- hai actions → `MxButtonPair`, theo rule latest main: cùng hàng khi longest word
  còn đọc được, chỉ stack ở boundary mà shared component quyết định;
- secondary luôn đứng trước primary theo reading order hiện tại;
- footer chỉ nhận phase/action data, không tự sở hữu SafeArea/keyboard math;
- reassurance line dùng `bodySmall` quiet, max-width theo action column và không
  làm button rows lệch chiều rộng;
- loading/disabled giữ kích thước, không duplicate submit.

## Files dự kiến

Ưu tiên sửa trong presentation scope:

- `lib/features/card/presentation/screens/card_import_screen.dart`;
- `widgets/sections/card_import_context_widget.dart`;
- `card_import_stepper_widget.dart`;
- `card_import_source_step_widget.dart`;
- `card_import_source_summary_widget.dart`;
- `card_import_preview_step_widget.dart`;
- `card_import_preview_summary_widget.dart`;
- `card_import_confirm_step_widget.dart`;
- `card_import_submit_progress_widget.dart`;
- `card_import_result_widget.dart`;
- `card_import_action_bar_widget.dart`;
- mapping/preview row items và import overlays chỉ khi geometry liên quan;
- `widgetbook/lib/screens/card_import_screen_use_case.dart`;
- related presentation/visual/golden tests;
- wireframe M4.12 visual notes, design parity và `docs/wbs.md`.

Không tạo folder bucket thứ năm. Không chuyển business logic vào widget. Không
thêm shared component nếu `MxContentShell`, `MxCard`, `MxButtonPair`,
`MxMetricWell` hoặc primitives hiện hữu đã biểu đạt được need.

## Tests và visual evidence

Giữ toàn bộ behavior tests hiện có và bổ sung/điều chỉnh:

### Geometry

- header, body, work panels và footer dùng cùng horizontal edges;
- source options bằng width/height ở 393/412 và stack full-width ở boundary;
- mapping/preview panels full-width, không inboard indentation;
- result hero và summary cùng edges;
- content max-width đúng `AppBreakpoints.medium` trên wide surface;
- footer nằm trên keyboard, không double SafeArea/inset và không che row cuối;
- phase transition không làm stepper/context/footer nhảy ngang;
- action pair equal height và đúng one-row/stack boundary.

### State/interaction

Cover đủ `source`, `source ready`, `paste`, `parsing`, `parse error`,
`preview valid`, `preview mixed`, `confirm`, `submitting`, `completed`,
`completedWithSkips`, `noCardsAdded`, `commitFailure`.

Pin Close/back/discard, file replace/remove, mapping, toggles, retry, reset,
view cards và submit lock bằng observable outcomes; không assert raw Material
widget type khi semantics/action/geometry là contract thật.

### Responsive/a11y

- 320×640, 393×852, 412×915;
- text scale 1.0 và 2.0;
- light/dark; Vietnamese/Korean long content; long deck/file/header names;
- keyboard-open Paste;
- selected/status/error không chỉ bằng màu;
- icon actions có accessible labels; tap targets ≥48;
- stepper đọc step/name/state, rows đọc typed failure và counts hợp lý.

### Goldens

Giữ và cập nhật toàn bộ committed `card_import_*.png`. Bổ sung deterministic
golden cho parsing/submitting nếu hai phase chưa có visual evidence. Stress
goldens khác 393×852 không được thêm vào gallery canonical.

Golden mới không phải bằng chứng pass. Trước khi update, render baseline từ
`origin/main`; sau update, inspect từng PNG và chạy fresh comparison.

## Verification và delivery

Inner loop:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Sau hai recursive review và auto-fix, coordinator chạy full gate:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator IT cho presentation-only task này; PR phải ghi rõ
`not run — presentation-only`, không gọi đó là pass.

Vì thay đổi user-visible:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Publish lại đúng existing Artifact URL trong `CLAUDE.md`, đưa URL cho owner
confirm, rồi commit/push và tạo non-draft PR ready for merge. Không merge nếu
execution session chưa được user yêu cầu rõ.

## Clean stop

Chỉ dừng khi:

- toàn bộ behavior và tám phase M4.12 giữ nguyên;
- shell/header/body/footer chỉ có một owner cho gutter, safe area, scroll và
  keyboard inset;
- visual grammar khớp Card Detail nhưng không nhập nhằng product meaning;
- mapping, preview và outcome có hierarchy rõ, không floating controls;
- mọi material shared edge/baseline có geometry assertion;
- responsive/a11y matrix sạch;
- changed gate, full gate và fresh golden comparison xanh;
- gallery existing URL đã cập nhật và PR chứa review/gate/emulator evidence.
