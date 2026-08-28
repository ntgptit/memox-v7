# Implement Card Editor Concept Parity

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc tái cấu trúc màn Edit flashcard theo concept light/dark mới, đồng thời giữ đúng nghiệp vụ Card, Tag, Flag và Trash hiện có |
| **Scope** | Edit mode của Card Editor, editor load context, shared shell/input API tối thiểu, localization, wireframe, Widgetbook, widget/geometry/accessibility/golden tests |
| **Source of truth for** | Hướng dẫn thực thi Card Editor concept parity; nghiệp vụ chính thức vẫn thuộc BR-07…BR-10, BR-92…BR-95, BR-163, BR-239…BR-246, BR-256…BR-267, UC-04, UC-19, UC-21 và wireframe M4.11 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, `docs/business-rules.md`, `docs/use-cases.md`, `docs/wireframes/m4-11-card-management.md`, MemoX theme/shared-widget contracts |
| **Updated by task** | Card Editor concept-parity prompt |
| **Last updated** | 2026-08-27 |

---

Triển khai trong một worktree feature sạch từ `origin/main` mới nhất. Đây là
một screen-level rework của **Edit flashcard**, không phải thay đổi nghiệp vụ
Card. Create mode dùng chung screen nhưng nằm ngoài phạm vi visual redesign;
mọi shared API mới phải giữ default hiện tại để Create mode và caller khác
không đổi pixel hoặc behavior.

## Concept và cách đọc concept

Concept là file hình ảnh, không phải tài liệu nghiệp vụ:

- absolute path:
  `C:\Users\ntgpt\AppData\Local\Temp\codex-clipboard-b4b92217-b93c-4850-9c2f-50d630b83d2f.png`;
- SHA-256:
  `16F50DFB5A77BA16AF707F8B195FE8F15876BC5A8806FCD41C8C39A79E2B5418`;
- kích thước: `1286 × 1217`;
- hai panel mô tả cùng một màn ở light/dark và hai vị trí cuộn, không phải hai
  màn khác nhau.

Trước khi code, kiểm tra file và hash rồi mở bằng công cụ xem ảnh. Nếu file
không còn tồn tại hoặc hash khác, dừng và xin handoff mới; không dùng một ảnh
cùng tên hoặc tự nhớ lại concept. Chữ và icon trong ảnh chỉ là bằng chứng về
hierarchy/geometry. BR/UC/wireframe mới nhất thắng khi concept gợi ý behavior
khác.

### Approved differences bắt buộc

Các khác biệt sau với ảnh đã được duyệt theo contract hiện tại và **không** được
“sửa cho giống ảnh”:

1. Không thêm mic nhập giọng nói và không thêm loa/TTS. D9 đã defer plugin,
   permission và error flow đó.
2. Không hiển thị `78% recall`, streak hoặc accuracy trong editor. BR-243 cấm
   dựng một định nghĩa aggregate thứ hai từ history.
3. History dùng một lối vào tới Card Detail/History hiện có, nhưng không được
   bịa `Last edited`, review count hay recall metric trong editor.
4. Deck context là read-only. Không vẽ chevron/dropdown giả và không cho đổi
   deck từ hàng context này; move card thuộc UC-04 A5.
5. Flag là chức năng hiện có theo BR-92 nên vẫn phải nhìn thấy và thao tác được,
   dù ảnh không vẽ nó.
6. Soft-delete phải nói `Move to Trash`, giữ study state/history tới purge và
   có Undo theo BR-256/BR-259/BR-263. Không dùng copy “review history is
   removed”, không hard-delete.
7. Vai trò màu destructive chỉ dành cho purge vĩnh viễn theo BR-266. Khối xoá
   trong editor có thể giữ cấu trúc card cảnh báo của ảnh, nhưng action soft-
   delete phải là secondary/outlined trung tính, không đỏ như purge.
8. Không dùng heading `Danger zone`. Giữ divider + một card có title/mô tả rõ
   hành động `Move this flashcard to Trash`; đây là ngôn ngữ sản phẩm, không
   phải nhãn kỹ thuật.
9. Không thay typography/density toàn app. Người dùng đã chấp nhận cỡ chữ nhỏ
   hiện tại; chỉ ánh xạ hierarchy sang semantic text roles sẵn có và giữ text
   scaling.

## Pre-flight và 5Why

Đọc đầy đủ `CLAUDE.md`, `docs/document-conventions.md`, BR/UC nêu trong header,
wireframe M4.11 W4–W7, implementation/test/golden hiện tại, `MxContentShell`,
`MxBreadcrumb`, `MxCard`, `MxTextField`, `MxActionButton`, `MxIconButton`, theme
tokens, component themes và visual-audit harness. Kiểm tra branch, worktree,
base commit và `git status`; không ghi đè hoặc revert thay đổi của session khác.
Không commit, push, tạo PR hoặc merge trong phase implementation/review; delivery
do coordinator thực hiện sau hai review.

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Production hiện là một cột field phẳng; Save nằm giữa body, Tags và delete nằm sau nó nên hierarchy và phạm vi lưu không rõ. | Chia màn thành chrome, context, form sections, metadata và destructive card; ghim action bar đáy. |
| 2 | Concept có cả top Save và bottom Save, nhưng hai command độc lập dễ double-submit hoặc lệch enabled state. | Hai affordance dùng đúng một coordinator/canSave; bottom là primary thường trực, top là shortcut compact. |
| 3 | Concept mang metadata, mic/TTS và hard-delete copy không còn khớp repo. | Chỉ lấy layout/hierarchy; lập danh sách approved differences tường minh và test nghiệp vụ hiện hành. |
| 4 | Edit form chưa có baseline/dirty contract nên Back/Cancel có thể làm mất draft và Save luôn trông sẵn sàng. | Snapshot năm field, dirty/revert semantics, một exit coordinator cho Back/Cancel/system gesture. |
| 5 | Golden mới có thể hợp thức hoá một layout sai nếu không đo shared edges và state-by-state. | Trích geometry contract, pin `getRect` trên production tree, inspect light/dark/scroll/keyboard trước khi chấp nhận golden. |

## UI Contract trước khi code

Agent MUST ghi một UI Contract ngắn vào implementation notes trước khi sửa
source, gồm section table, state matrix, widget tree, interaction ownership,
shared-widget mapping và geometry contract. Không bỏ qua vì màn đã tồn tại.

### Section table và thứ tự hiển thị

| Section | Position | Responsibility | Data source |
|---|---|---|---|
| App bar | pinned top | Back, title, Flag, compact Save | dirty/submit state + flag controller |
| Breadcrumb | dưới app bar, trước body | Nêu Library → path deck → Edit | editor context read |
| History entry | đầu body | Mở Card Detail/History hiện có, không tự tính metric | route + card id |
| Deck context | sau history entry | Hiển thị deck đích read-only | editor context read |
| Front | form đầu tiên | Required Korean term + counter 60 | content draft |
| Back | sau Front | Required meaning + counter 240 + BR-10 helper | content draft |
| Optional details | sau Back | Example, Hint, Pronunciation; expanded khi có data | content draft |
| Tags | sau details | Chips + immediate add/remove + cap 10 | tag controllers |
| Delete card | cuối scroll body | Giải thích và bắt đầu Move to Trash | soft-delete flow |
| Action bar | pinned bottom | Cancel + Save changes + local-only helper | dirty/submit state |

Visible reading order MUST đúng bảng này. Không đưa Save vào giữa details và
Tags. Không đặt delete dưới footer hoặc overlay lên content.

### Widget tree mục tiêu

```text
MxContentShell / Scaffold
├─ AppBar
│  ├─ Back
│  ├─ Edit flashcard
│  ├─ Flag toggle
│  └─ Compact Save
├─ Scrollable body (constrained reading width)
│  ├─ Breadcrumb
│  ├─ History entry (contract-safe)
│  ├─ Read-only deck context
│  ├─ CardEditorField(Front)
│  ├─ CardEditorField(Back + progress helper)
│  ├─ OptionalDetailsSection
│  │  ├─ Example
│  │  ├─ Hint
│  │  └─ Pronunciation
│  ├─ TagSection
│  ├─ Divider
│  └─ TrashActionCard
└─ SafeArea pinned action bar
   ├─ Cancel
   ├─ Save changes
   └─ local-only helper
```

### State matrix tối thiểu

| State | Form | Save shortcut/footer | Exit | Notes |
|---|---|---|---|---|
| loading | stable skeleton/loading face | disabled | Back allowed | không dựng draft giả |
| load error/not found | typed recovery face | absent | Back allowed | không lộ id/SQL |
| pristine | populated | disabled | rời ngay | tag/flag vẫn độc lập |
| dirty valid | populated | enabled | discard guard | revert về snapshot → pristine |
| validation error | giữ draft + inline error | theo canSubmit hiện có | discard guard | không layout jump vô cớ |
| saving | giữ form | một busy indicator; cả hai action inert | không pop | chống double-submit |
| save failure | giữ draft + scoped error | enabled lại | discard guard | không mất focus/scroll |
| tag/flag writing | content Save không đổi | theo content dirty | tag draft vẫn guard | feedback thuộc operation |
| moving to Trash | confirmation/submit | inert | không race với Save | success route + Undo |

## Nghiệp vụ và ownership phải giữ

- Content Save chỉ sở hữu năm field: Front, Back, Example, Hint,
  Pronunciation. BR-10 giữ study state/history nguyên vẹn.
- Tag add/remove và Flag toggle vẫn là mutation tức thì qua controller/use case
  riêng; chúng không chờ Content Save và không làm content dirty.
- Chữ Add tag đang gõ nhưng chưa submit là unsaved UI draft: nó chặn rời màn,
  nhưng không bật Content Save.
- Delete là soft-delete/Trash. Confirm, route fallback, batch id và Undo giữ
  đúng flow hiện có; action copy và color phải theo BR-256/BR-266.
- Optional disclosure là presentation state, không làm dirty. Giá trị field mới
  làm dirty.
- Create mode, Card Detail, Card List, move/bulk, scheduler, schema và study
  logic không được đổi ngoài read model tối thiểu thật sự cần cho editor context.

## Implementation

### 1. Editor context: breadcrumb và deck read-only

- Không ghép `getCard` và một stream deck độc lập trong widget/controller nếu
  chúng có thể tạo một frame card/deck khác snapshot. Reuse một editor-context
  read đã có; nếu thiếu, thêm model + use case + repository/DAO read nhỏ nhất
  trả về card snapshot và deck context/path trong một statement/snapshot theo
  AD-13. SQL ở `.drift`, mapping ở data, không để Drift type lên domain/UI.
- Xác minh `card.deckId == route deckId`; mismatch/deleted target surface bằng
  typed failure, không render breadcrumb sai.
- Breadcrumb dùng `MxBreadcrumb`/existing path grammar. Current leaf là `Edit`;
  long path fold/ellipsis theo shared component, không tự dựng Row chevron.
- Deck row dùng `MxCard` compact hoặc shared equivalent, icon deck + tên deck.
  Nó không có dropdown affordance và không nhận tap.
- Thêm lối `History` bằng route constant tới Card Detail hiện có. Render một
  row action có nhãn rõ; không query hoặc tính recall metric trong editor.

### 2. App bar và hai Save affordance

- Edit mode dùng Back arrow, không `×`. Back, bottom Cancel và system back gọi
  cùng `_requestExit()`/coordinator.
- Giữ Flag qua `MxIconButton`: outlined khi off, filled khi on; standard
  `onSurfaceVariant` khi off, `semantic.warning` khi on; tooltip/semantics ARB;
  target ≥48; submitting disables; failure giữ last committed state.
- Thêm compact Save theo concept. Nó và footer Save phải đọc cùng
  `contentDirty`, validation và submit state và gọi đúng cùng một `_save()`.
  Không copy submit body vào hai callbacks.
- Pristine: cả hai disabled. Dirty valid: cả hai enabled. Submitting: footer
  giữ một spinner + label; top Save chỉ disabled để không có hai spinner cho
  một operation. Save failure giữ draft và bật lại cả hai.
- Ở regular phone hiển thị label `Save`. Ở 320dp/text scale lớn, chỉ được dùng
  adaptation đã có của shared/responsive foundation; không thêm local magic
  breakpoint. Nếu label không thể fit, bottom Save vẫn là primary đầy đủ và top
  shortcut MAY thu về icon có tooltip/semantic label.

### 3. Dirty snapshot và unsaved guard

- Snapshot đúng năm giá trị sau prefill. Dirty so sánh theo representation mà
  submit sẽ lưu; không duplicate validation/trim rule trong UI.
- Prefill không được làm dirty hoặc `setState` trong build. Listener được gắn/
  tháo đúng lifecycle; card id đổi phải tạo baseline mới, không giữ baseline cũ.
- Sửa rồi trả đúng snapshot làm cả hai Save disabled lại.
- Tag section báo `hasTagDraft`; `_hasUnsavedWork = contentDirty || hasTagDraft`.
- `PopScope<Object?>` bảo vệ Back gesture. Back arrow và Cancel dùng cùng
  coordinator. Pristine rời ngay; unsaved mở một `MxConfirmDialog`: Discard /
  Keep editing. Keep giữ text, focus, scroll, tags đã commit và flag đã commit.
- Chặn re-entry, double dialog, double pop và callback sau dispose. Save thành
  công bypass guard đúng một lần; failure không pop.

### 4. Form hierarchy và field surfaces

- Dùng `mxScreenGutter(context)` và content max-width hiện có. Mọi section
  cùng một outer edge; không tạo gutter lồng khiến Optional/Tags bị thụt vào.
- Tạo feature composite `CardEditorFieldWidget` (bucket đúng AD-15) cho external
  label row + counter + field surface. Nếu `MxTextField` cần API mới, thêm typed
  variant/label-placement với default giữ nguyên; không expose raw
  `InputDecoration`, `Color`, `BorderRadius`, padding hay arbitrary style.
- Label row:
  - Front: `FRONT · KOREAN` khi language metadata thật có; fallback `FRONT`,
    không để dấu `·` treo;
  - Back: `BACK · MEANING`;
  - required/optional copy là ARB và không chỉ dựa vào màu;
  - counter luôn thấy `current / max` cho editor, lấy 60/240 từ domain constants.
- Front input dùng semantic role lớn hơn Back (`titleLarge` hoặc role hiện có
  tương đương); không hardcode font size. Back dùng body role. Không sửa global
  typography tokens.
- `cardEditorProgressNote` là helper thuộc Back, không là Text trôi giữa
  sections. Error/helper layout phải ổn định.
- Field surface, radius, border, focus/error/disabled states dùng MemoX input
  theme/tokens. Không copy màu hex/radius/padding từ ảnh.
- Không thêm mic. Không thêm TTS button ở Pronunciation.

### 5. Optional details

- Nếu card có bất kỳ Example/Hint/Pronunciation, section mở khi load và hiển
  thị cả ba field theo thứ tự ảnh. Nếu cả ba rỗng, giữ disclosure đóng theo D11.
- Heading `OPTIONAL DETAILS`; từng field có icon trang trí + label + `optional`
  và counter 240. Icon trang trí phải `ExcludeSemantics`; không giả làm action.
- Disclosure đóng dùng label rõ `Add example, hint & pronunciation` với
  expand icon; toàn row ≥48, semantics expanded/collapsed.
- Khoảng cách label→field chặt hơn field→field, toàn bộ qua `AppSpacing`.

### 6. Tags

- Heading `TAGS · optional`, tag counter khi có tag, chips trong Wrap cùng edge
  với fields. Chip delete có tooltip/semantic label và hit target Android.
- Mặc định hiển thị chip/action `+ Add tag` như concept. Khi tap, hiện inline
  `MxTextField` nhỏ với suffix Add + IME submit dùng chung `_submitTag()`; cung
  cấp cách đóng entry mà không submit và giữ exit guard khi còn draft.
- Blank/full/busy không gọi controller; failure giữ draft; success mới clear và
  collapse input. Tag commit không bật Content Save.
- Đủ 10 tag thì không render Add action/input; hiện localized cap message. Không
  cho gõ rồi mới báo.
- Không thêm `StadiumBorder` cục bộ; dùng chip theme/AppRadius.pill. Chỉ thêm
  constraint khi hit-test production chứng minh target chưa đạt 48dp.

### 7. Trash action card

- Sau Tags: divider rồi một `MxCard`/surface card có title
  `Move this flashcard to Trash`, mô tả chính xác: card biến khỏi Library/study,
  dữ liệu và history được giữ trong Trash tới purge, các card khác không đổi.
- Không heading `Danger zone`; không copy hard-delete; không nói history mất.
- Button outlined secondary có icon delete/trash và label `Move to Trash`.
  Không dùng `semantic.danger`, `ColorScheme.error` hay filled destructive vì
  BR-266 dành chúng cho purge vĩnh viễn.
- Tap vẫn mở shared confirm hiện có. Submit thành công đi tới deck route hiện có
  và hiện Undo snackbar từ batch id. Deleting last card vẫn để BR-163/BR-260
  quyết định deck `content_type`; UI không tự suy.

### 8. Pinned bottom action bar

- Mở rộng `MxContentShell` bằng optional typed footer/
  `bottomNavigationBar` passthrough nếu latest main chưa có. Default null và
  tests bảo vệ caller cũ.
- Footer: `SafeArea(top: false)` + token padding; `Cancel` outlined/secondary
  và `Save changes` primary trong một Row. Tỷ lệ gần concept: Save nhận phần
  còn lại lớn hơn Cancel, nhưng không hardcode pixel; cả hai đạt touch floor.
- Dưới row có localized helper `Changes save to this device only.` với bodySmall
  semantic muted. Helper không phải status và không đổi khi Save chạy.
- Footer nằm ngoài `SingleChildScrollView`, trên keyboard/bottom safe area,
  không che Trash card. Body có bottom clearance đúng token, không spacer đoán.

## Docs, localization và catalog

Trong cùng diff:

1. Cập nhật `docs/wireframes/m4-11-card-management.md` bằng decision/changelog
   2026-08-27 cho concept này. Giữ lịch sử D6–D11; ghi supersession rõ. Sửa
   delete copy cũ để tham chiếu BR-256/BR-266, không chép BR.
2. Cập nhật đúng task ở `docs/wbs.md`; không sửa frozen BR/UC/data model vì task
   không đổi nghiệp vụ.
3. Thêm/sửa ARB EN/VI cho Back/Cancel/Save/discard, labels, history entry, tag
   entry/cap, Trash card/helper. Không hardcode user-visible strings.
4. Update Widgetbook use case cho edit pristine/dirty/details/tags/Trash và
   light/dark. Không tạo component shared mới nếu existing primitive đủ.

## Test bắt buộc

Mở rộng `card_editor_edit_test.dart`, visual-audit test và demo golden bằng
production screen/harness. Tối thiểu:

1. editor context trả card + đúng deck/path; mismatch/not-found typed;
2. breadcrumb/deck row read-only, không dropdown/tap giả; History mở đúng
   Card Detail route và không render recall metric;
3. pristine/dirty/revert; năm field đều dirty; disclosure không dirty;
4. top/bottom Save cùng một submit path, không double write; enabled/loading/
   failure đồng bộ; success pop đúng một;
5. Back arrow, Cancel và system Back cùng discard guard; re-entry không stack;
6. Tag/Flag immediate không làm content dirty; tag draft chặn exit; failure
   giữ committed state/draft;
7. external labels/counters dùng đúng 60/240; Front style lớn hơn Back; Back
   helper đúng ownership; không mic/TTS;
8. optional section collapsed khi trống, mở khi có data; order/icon semantics;
9. tags 0/9/10, Add chip→entry, suffix/IME cùng path, cap/hit target/failure;
10. Trash card copy đúng soft-delete, neutral secondary role, confirm + route +
    Undo giữ nguyên; không dùng hard-delete/destructive color;
11. footer ngoài scroll, không che cuối body/keyboard; top shortcut không
    overflow tại 320dp/textScaler 2.0;
12. EN/VI, light/dark, 320×568 @2.0, 390 và 412, long Korean/Vietnamese không
    overflow, clip hoặc mất action.

### Geometry contract phải pin bằng `tester.getRect`

- Breadcrumb, history row, deck context, Front, Back, details, Tags, divider và
  Trash card chia sẻ cùng content left/right edge.
- Front và Back field surfaces cùng width; external label/counter row cùng edge
  với surface; counter right edges thẳng hàng.
- Optional field surfaces và tag Wrap **không** thụt thêm một gutter so với
  Front/Back.
- Label→surface gap dùng một tight token; field→field/section gaps dùng section
  token lớn hơn và nhất quán.
- Bottom Save rộng hơn Cancel như concept; cùng baseline/touch height; footer
  nằm ngoài scroll và hoàn toàn trên safe area/keyboard.
- Trash card có thể scroll hoàn toàn lên trên footer; không có dead space lớn
  hoặc overlap ở cuối.
- App-bar title/Flag/Save không overlap ở 390/412; 320×2.0 dùng adaptation đã
  định, không cắt action chính.

Golden/render tối thiểu: edit pristine light, edit dirty light, edit dark scrolled
tới Optional/Tags/Trash, tag entry, 10 tags, validation error, save failure,
discard dialog, Trash confirm, 320×568 VI @2.0. Một golden mới chỉ là baseline;
review phải so từng state với concept và approved differences.

## Verification và clean stop

Inner loop và final gate chỉ qua entry của repo:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Vì thay đổi nhìn thấy được, sau khi UI review sạch:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Không chạy emulator integration suite cho task này: đây là editor UI/host
behavior, không thêm plugin/platform binding và user đã yêu cầu bỏ emulator cho
chỉnh sửa thông thường. Báo `not run — scoped host verification`, không gọi là
pass.

Clean stop chỉ khi docs/code/tests đồng thuận; concept sections và geometry đã
được render/inspect; mọi approved difference được giữ; không metric/mic/TTS/
hard-delete giả; mutation ownership đúng; không double submit/dialog/pop;
footer không che content/keyboard; accessibility, changed gate và full gate đều
xanh; không còn P0/P1/P2 hoặc divergence chưa được duyệt.
