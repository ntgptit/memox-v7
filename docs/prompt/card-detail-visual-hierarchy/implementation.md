# Implement Card Detail — Compact History Layout

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc chuyển Card Detail sang bố cục history hiện đại, gọn và có phân tầng rõ, đồng thời giữ nguyên nghiệp vụ và dữ liệu hiện có |
| **Scope** | Presentation, shared button variant tối thiểu, wireframe Card Detail, widget/geometry/semantics tests, visual audit, golden và gallery |
| **Source of truth for** | Hướng dẫn thực thi Card Detail compact history layout; nghiệp vụ chính thức vẫn thuộc BR-239…BR-246, UC-19 và wireframe M4.15 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-239…BR-246, UC-19, `docs/wireframes/m4-15-card-detail.md`, concept ảnh do owner cung cấp |
| **Updated by task** | Card Detail compact history layout prompt |
| **Last updated** | 2026-08-26 |

---

Triển khai **Card Detail — Compact History Layout** trong worktree feature lấy từ
`origin/main` mới nhất. Đây là thay đổi presentation-first: giữ nguyên read
model, repository, controller, route, paging, database và mọi business rule.

Concept bắt buộc phải mở bằng công cụ xem ảnh trước khi lập layout:

`D:/workspace/memox-v7/.codex-remote-attachments/019fe924-47e4-7741-9143-21cc8a21ddc9/9283098c-8784-4613-90c6-28c1edc3adfa/1-Photo-1.jpg`

Chỉ phần màn hình nằm **bên trong khung điện thoại** là concept Card Detail. Thanh
editor ở trên, số thứ tự frame, mũi tên carousel và khung thiết bị không thuộc
app, không được triển khai.

## Pre-flight

1. Đọc đầy đủ `CLAUDE.md`, `docs/document-conventions.md`, BR-239…BR-246,
   UC-19, wireframe M4.15, code/test/golden Card Detail hiện tại, `MxCard`,
   `MxActionButton`, typography, color, spacing, radius và responsive tokens.
2. Kiểm tra branch, worktree, base và `git status`. Không revert hoặc ghi đè
   thay đổi ngoài scope. Prompt và ảnh ở source worktree là read-only input.
3. Sinh generated code theo contract repo trước analyze/test. Không sửa generated
   files.
4. Lập UI Contract, UI Section Table và widget tree trước khi sửa code. Đối chiếu
   thứ tự widget tree với concept và với W2 của M4.15.
5. Không commit/push/PR trong phase implementation. Delivery do coordinator làm
   sau hai recursive review và final gate.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Màn hiện tại là ba dải chữ phẳng, nên nội dung, lịch hiện tại và lịch sử có cùng visual weight. | Dùng ba tầng rõ: summary hero, current-progress panel và timeline event cards. |
| 2 | Concept quét nhanh nhờ chữ nhỏ, grid hai cột và timestamp neo bên phải. | Dùng đúng các token 11/12/14/16/20–24sp hiện có; không giảm toàn bộ global type scale. |
| 3 | Concept chứa `Box 3/5`, recall rate, streak, event count và filter chưa tồn tại. | Chỉ lấy layout; dữ liệu phải theo BR-240/BR-243 và scheduler thật, không tạo metric hoặc control giả. |
| 4 | Eight-box và SM-2 không có cùng progress model. | Hero/progress dùng presentation mapping có kiểu cho từng scheduler; Eight-box có 8 segment, SM-2 không giả lập Box. |
| 5 | Một golden mới có thể khóa cả bố cục sai. | Pin quan hệ hình học bằng `getRect`, render production states rồi so trực tiếp concept trước khi cập nhật baseline. |

## Những divergence đã được owner chấp thuận

Concept là contract về hierarchy, density và relative geometry, không phải nguồn
nghiệp vụ. Những khác biệt sau là bắt buộc:

- Giữ tiêu đề localized hiện có của Card Detail; không đổi thành `Card history`
  nếu canonical copy chưa đổi.
- Không thêm breadcrumb: read model hiện không cung cấp deck path, và một UI-only
  task không được mở rộng query chỉ để bắt chước ảnh.
- Không hiện `Recall rate`, `Correct streak`, score, accuracy hoặc aggregate nào
  từ history; BR-243 cấm chúng.
- Không hiện `TIMELINE · N EVENTS`: history phân trang nên số đang giữ trong
  memory không phải tổng, và V10 cấm một định nghĩa đếm thứ hai.
- Không dựng `All events` hoặc filter chevron: feature chưa có filter contract.
- Không dùng `Correct`/`Recovered` như taxonomy mới. Event phải dùng localized
  stored `mode`, `kind`, `action`, `outcomeReason` và `usedHint` hiện có.
- Eight-box hiển thị `Box N / 8`, không phải `/ 5`. SM-2 không hiển thị segment
  Box; nó hiển thị Ease, Interval và Repetitions.
- Front, Back, Example, Hint, Pronunciation, flag và tags vẫn đầy đủ theo BR-240;
  concept không được dùng làm lý do ẩn dữ liệu.
- Mỗi generation vẫn có text heading theo BR-243; màu không thay thế heading.
- Vùng chạm Edit vẫn tối thiểu 48dp dù phần fill trong concept trông thấp hơn.

Mọi divergence khác phát hiện trong lúc làm phải dừng để xin owner duyệt; không
tự hợp thức hoá bằng comment hoặc golden.

## UI Contract

### Section table

| Thứ tự | Region | Dữ liệu | Hành vi |
|---|---|---|---|
| 1 | App bar | Title hiện có, Edit | Back giữ list context; Edit push editor hiện có |
| 2 | Summary hero | Front, Back, scheduler/state, flag, tags, optional fields | Read-only; long text wrap, field null biến mất |
| 3 | Current progress | Current schedule fields theo scheduler | Read-only; Eight-box segmented, SM-2 metric-only |
| 4 | History header | `Study history`, generation heading | Không event count, không filter giả |
| 5 | Timeline | Stored history events, paging tail | Load more/retry như hiện tại; một page scroll duy nhất |

### Widget tree đích

```text
MxContentShell
├─ appBar action: compact tonal Edit action
└─ SingleChildScrollView
   └─ Column
      ├─ CardDetailSummaryHero
      ├─ CurrentProgressSection
      │  └─ MxCard
      │     ├─ section label
      │     ├─ scheduler progress representation
      │     └─ responsive metric grid
      ├─ StudyHistoryHeader
      └─ generation groups
         ├─ text generation heading
         ├─ TimelineEvent
         │  ├─ marker + connector
         │  └─ flat MxCard
         └─ paging tail
```

Không tạo nested scroll view, tab, FAB hoặc một route mới.

## Tài liệu phải cập nhật trong implementation PR

1. Append quyết định visual mới vào
   `docs/wireframes/m4-15-card-detail.md`; không sửa/xoá V1…V12. Ghi rõ:
   compact typography, summary hero, scheduler-adaptive progress, event cards,
   approved divergences và geometry mới.
2. Cập nhật W2, W4 và G-contract để mô tả layout production mới. Giữ nguyên
   W1/W3/behavior và mọi BR reference.
3. Cập nhật đúng task trong `docs/wbs.md` với scope, output và bằng chứng thật.
4. Không sửa frozen BR/UC/AD/data model vì nghiệp vụ không đổi.

## Implementation

### 1. Screen shell và nhịp dọc

Chỉnh `card_detail_screen.dart` nhưng không đổi provider/state flow:

- Giữ `MxContentShell`, một `SingleChildScrollView`, `mxScreenGutter(context)` và
  bottom safe-area hiện có.
- Card/surface ngang cấp có cùng outer left/right edge. Khoảng giữa summary,
  progress và history dùng `AppSpacing`; không hardcode.
- Reading column phải có max-width theo precedent/layout token hiện có ở tablet,
  không kéo một cột chữ toàn bề rộng desktop.
- Loading, top-level error và not-found tiếp tục dùng shared state components và
  không mang Edit action khi card không ở `AsyncData`.

### 2. App-bar Edit

Concept dùng một tonal pill có icon và label `Edit`, rõ hơn icon đơn. Trước hết
kiểm kê shared API:

- Không dùng `MxPillButton`: nó là `ChoiceChip` cho selection, sai semantics.
- Nếu `MxActionButton` chưa expose tonal style đã có trong
  `app_button_themes.dart`, thêm đúng **một typed variant** `tonal` vào enum và
  dùng `buildFilledTonalStyle`; không thêm `Color?`, raw style knob hoặc local
  `Theme` patch.
- Card Detail dùng `MxActionButton` tonal với icon edit và localized label hiện
  có. Giữ callback `pushNamed`, semantic name và minimum touch target.
- Chứng minh các variant primary/secondary/destructive và call site hiện có
  không đổi pixel/behavior. Cập nhật shared component catalog nếu API tăng.

### 3. Summary hero

Refactor `card_detail_content_widget.dart` và phần metadata cần thiết thành một
`MxCard` summary:

- Surface `scheme.surface`, border/elevation/radius/padding qua `MxCard` và token
  hiện có; không sao chép decoration.
- Front dùng `headlineSmall` (24sp), không dùng `cardPrompt` 30sp. Back dùng
  `bodyMedium` hoặc `titleSmall` theo measured hierarchy, không nặng bằng Front.
- Ở đầu/bên phải summary, hiển thị một scheduler/state summary có chữ:
  `Box N / 8` cho Eight-box hoặc localized scheduler identity phù hợp cho SM-2.
  Nó phải wrap/stack khi hẹp và không đè Front.
- Flag và tags là read-only chips/marks, chỉ xuất hiện khi có dữ liệu. Không tạo
  onTap, button semantics hoặc mutation.
- Khi có Example/Hint/Pronunciation, đặt sau divider trong cùng surface hoặc
  một sub-region liên tục của hero. Label dùng `labelSmall`/section-label role,
  value dùng `bodyMedium`; field null không render. Không `maxLines`, ellipsis
  hoặc collapse.
- Dùng typography token hiện có. Không sửa global `AppTypography` trong task
  này: owner đã chấp thuận density 11–14sp cho UI text, không chấp thuận tắt
  text scaling hay thu nhỏ accessibility.

### 4. Current progress panel

Refactor `card_detail_state_widget.dart` thành section/card theo concept nhưng
hiển thị đúng toàn bộ BR-240:

- Section label uppercase/tracked bằng style token hiện có, không hardcode case
  của localized text nếu ARB đã sở hữu casing.
- Panel là `MxCard` flat hoặc đúng elevation ladder hiện có; nền/border dùng
  semantic roles.
- **Eight-box:** vẽ 8 segment bằng feature widget nhỏ, segment `1..<current`
  completed, current emphasized, future muted. Có text `Box N / 8` và semantics
  đầy đủ; 8 là named domain/UI constant lấy từ scheduler contract nếu repo đã có,
  không magic number lặp lại.
- **SM-2:** không render segment. Render scheduler label và metric grid chứa
  Ease, Interval, Repetitions bên cạnh fields chung.
- Fields chung bắt buộc: display state, Due, Learned, Last answered, Reviews,
  Lapses. Không thêm Since added nếu wireframe/canonical contract chưa xác nhận;
  không thay required field bằng metric concept.
- Grid hai cột ở 390/412; tự chuyển một cột khi constraints hoặc textScaler làm
  value không đọc được. Quyết định dựa trên layout constraints và token, không
  per-device width magic number.
- Label dùng `bodySmall`, value dùng `bodyMedium` w600 với variable-font helper
  của repo nếu đổi weight. Numeric values dùng tabular figures.
- Màu là secondary cue; icon + localized label luôn tồn tại. Không mint color.

### 5. History header và timeline event cards

Refactor `card_history_section_widget.dart` và
`card_history_event_widget.dart`:

- Header chỉ là localized `Study history`; không count, filter hoặc chevron.
- Generation heading vẫn là text, nằm trước nhóm và đọc được không cần màu.
- Mỗi event giữ marker/connector bên trái và một `MxCard` flat bên phải. Event
  cards cùng width, cùng text edge, và không phá connector giữa các hàng.
- Hàng đầu card: action badge/text ở trái, localized timestamp ở phải. Không
  thay persisted timestamp bằng một giá trị không kiểm chứng; visible copy và
  spoken copy đều locale-aware.
- Bên dưới phải hiển thị stored values: mode, kind, action, schedule transition,
  `nextDueAt`, outcome reason và hint mark khi có. Không phát minh câu
  `Answered correctly`/`Got it back after a slip` nếu không có canonical key.
- Action tone lấy từ stored `StudyAction` bằng presentation-only typed mapper:
  forgotten/again → danger; remembered/good/easy → success; hard → warning
  nếu token/contrast cho phép. Không infer action từ before/after state.
- Text vẫn nói rõ action; màu không phải tín hiệu duy nhất. Schedule transition
  Eight-box có accent, SM-2 vẫn hiện đúng ease/interval. Learning turn không đổi
  lịch phải hiện canonical “no schedule change”.
- Event semantics tiếp tục là một node gộp dùng spoken forms; không để badge,
  timestamp và card tạo nhiều announcement lặp.
- Load more/loading-more/page error/end giữ nguyên controller và transition.
  Tail cùng vị trí, không nhảy event cuối. Empty history vẫn là valid empty state.

### 6. Không được thay đổi

- Repository, DAO, SQL, use case, controller, provider, route hoặc database.
- Page size 50, keyset cursor, generation grouping hoặc history ordering.
- ARB copy trừ khi một key accessibility thật sự thiếu; mọi key mới phải có đủ
  locale/description và không định nghĩa nghiệp vụ mới.
- Field visibility/meaning, flag/tag behavior, Edit/back navigation.
- Global font-size tokens, minimum touch target hoặc `MediaQuery.textScaler`.

## Test bắt buộc

### Logic và regression

- Card Detail vẫn read-only; mở/scroll/load-more không ghi DB hoặc state.
- Đủ field BR-240; optional null biến mất; long content không truncate.
- Eight-box và SM-2 render đúng fields riêng, không lẫn nhau.
- Không có accuracy, recall rate, streak, event total hoặc filter giả.
- Stored action quyết định presentation tone; không suy diễn từ state delta.
- Paging, generation grouping, error/retry, edit/back behavior giữ nguyên.

### Geometry và responsive

Dùng production tree và `getRect`, không chỉ test widget giả:

- 320dp @ textScaler 2.0, 390dp và 412dp; EN + VI; light + dark.
- Outer edges summary/progress/event cards theo một gutter.
- Front và scheduler badge không overlap; badge wrap/stack có chủ đích.
- Eight segments bằng nhau, không overflow, current segment đúng vị trí.
- Metric grid hai cột thẳng hàng ở regular width và stack đọc được khi hẹp.
- Timeline marker neo baseline hàng đầu; connector liền qua event cao/thấp.
- Event cards cùng left/right edge; timestamp không đẩy action khỏi card.
- Tail giữ vị trí/height giữa idle/loading/error/complete.
- Edit action đạt Android tap target guideline.

### Visual evidence

Render và inspect ít nhất:

- loaded Eight-box light/dark;
- loaded SM-2 light/dark;
- flagged/tags + optional fields;
- long Front/Back/optional fields;
- positive, warning và negative actions trong timeline;
- multiple generations;
- no-history, load-more, loading-more, page-error, top-level error, not-found;
- 320dp @2.0 VI, 390 và 412.

Golden là baseline sau khi concept comparison đã pass, không phải bằng chứng tự
thân. Recursive UI review phải ghi approved differences ở trên và mọi divergence
còn lại.

## Verification và clean stop

Inner loop dùng changed planner của repo:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Không chạy emulator integration suite: đây là restyle route/feature có sẵn,
không đổi route, binding, persistence hoặc platform behavior. Báo rõ `not run —
presentation-only restyle`; không gọi là pass.

Implementation clean stop khi code/docs/tests khớp; targeted/changed gate xanh;
không P0/P1/P2 đã biết; không business/data/navigation drift; và đã giao lại
worktree cho hai recursive review độc lập. Chưa update golden/gallery hoặc tạo
PR cho tới khi cả hai review đã hoàn tất và coordinator chạy delivery phase.
