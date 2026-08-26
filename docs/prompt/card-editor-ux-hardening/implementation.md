# Implement Card Editor UX Hardening

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc sửa hierarchy, action placement, dirty-state protection và accessibility của màn Edit flashcard mà không đổi nghiệp vụ card |
| **Scope** | Edit-mode Card Editor, shared shell/control APIs tối thiểu, localization, canonical wireframe, widget/geometry/accessibility/golden tests |
| **Source of truth for** | Hướng dẫn thực thi Card Editor UX hardening; nghiệp vụ chính thức vẫn thuộc BR-07…BR-10, BR-92…BR-95, BR-163, BR-256, UC-04 và wireframe M4.11 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, `docs/business-rules.md` BR-07…BR-10, BR-92…BR-95, BR-163, BR-256, `docs/use-cases.md` UC-04, `docs/wireframes/m4-11-card-management.md` |
| **Updated by task** | Card Editor UX hardening prompt |
| **Last updated** | 2026-08-26 |

---

Triển khai **Card Editor UX Hardening** trong worktree riêng từ `origin/main`
mới nhất. Chỉ sửa **edit mode** của `CardEditorScreen`; create mode, dữ liệu,
repository, scheduler, study state, history, route và thao tác bulk nằm ngoài
scope.

## Pre-flight và 5Why

Đọc đầy đủ `CLAUDE.md`, `docs/document-conventions.md`, các BR/UC nêu ở header,
wireframe M4.11, implementation hiện tại, test Card Editor, `MxContentShell`,
`MxActionButton`, `MxTextField`, `MxIconButton`, chip theme và overlay xác nhận.
Kiểm tra branch, worktree, base commit và `git status`; không ghi đè hoặc revert
thay đổi của session khác. Không commit, push, tạo PR hoặc merge trong task này.

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | `Save changes` nằm trong scroll content và ở trước Tags, nên biến mất khi người dùng chỉnh phần cuối form và làm phạm vi lưu trở nên mơ hồ. | Ghim Save vào footer của `Scaffold`; Tags và Flag tiếp tục ghi tức thì với feedback riêng. |
| 2 | Form không có baseline/dirty state, nên Save trông khả dụng ngay khi chưa đổi gì và Close/System Back có thể làm mất draft. | So draft nội dung với snapshot ban đầu, disable Save khi pristine và dùng một PopScope cho mọi lối rời màn. |
| 3 | Delete dùng cùng filled weight với primary Save và nhãn `Danger zone` mang ngôn ngữ của công cụ kỹ thuật. | Thêm destructive-outlined variant có kiểu vào shared button, bỏ heading nhưng giữ confirmation/Trash flow. |
| 4 | Tag input chỉ có keyboard submit; chip delete và flag dựa vào default styling nên hành vi đúng chưa được bảo vệ bằng test trực tiếp. | Thêm trailing Add action có semantics, test hit target thực, và đưa Flag về shared icon contract. |
| 5 | Wireframe đã yêu cầu pinned action nhưng production drift; một golden được cập nhật có thể hợp thức hoá drift mới. | Cập nhật canonical wireframe theo quyết định owner mới, pin geometry/semantics trên production tree và inspect từng render trước khi chấp nhận golden. |

## Sự thật nghiệp vụ phải giữ

Trước khi code, ghi các fact sau vào checklist thực thi và test:

- `Save changes` chỉ ghi năm field nội dung: Front, Back, Example, Hint và
  Pronunciation qua `CardEdit`; BR-10 giữ study state/history nguyên vẹn.
- Tag **không** chờ Save. `CardTagEntry` và `CardTagRemove` là mutation tức thì,
  có loading/failure riêng. Tag đã add/remove thành công không làm form content
  dirty và không bật Save.
- Flag **không** chờ Save. `SetCardFlag` là mutation tức thì, có loading/failure
  riêng. Toggle thành công không làm form content dirty và không bật Save.
- Chữ đang gõ nhưng chưa submit trong Add tag vẫn là draft có thể mất: nó phải
  tham gia exit guard, nhưng **không** được bật Save vì Save không sở hữu nó.
- Delete tiếp tục đi qua `showCardDeleteConfirm`, soft-delete/Undo theo BR-256,
  và điều hướng qua deck theo behavior hiện có. Không thay bằng hard delete.
- Toggle mở/đóng Optional details chỉ là presentation state; tự nó không làm
  form dirty. Chỉ thay đổi giá trị field mới làm dirty.

## Cập nhật canonical docs trước khi sửa UI

Trong cùng diff:

1. Cập nhật `docs/wireframes/m4-11-card-management.md` bằng một decision ID mới
   và changelog ngày 2026-08-26. Không xoá lịch sử D6/D10; ghi rõ phần nào được
   supersede riêng cho W6b Edit mode.
2. Vẽ lại W6b theo contract mới: Close `×` có discard guard; Flag toggle; Front
   lớn hơn Back; progress note thuộc Back field; disclosure có nhãn cụ thể;
   Tags ghi tức thì; Delete outlined không có heading `Danger zone`; một Save
   full-width ghim đáy, disabled khi pristine.
3. Ghi rõ create mode chưa thuộc task này; không sửa W4 hoặc tuyên bố drift create
   đã được giải quyết.
4. Cập nhật đúng dòng WBS bằng output và bằng chứng. Không sửa BR/UC/data model,
   vì rule và persistence không đổi.

## Implementation

### 1. Dirty snapshot và exit guard

Trong `card_editor_screen.dart`:

- Tạo một presentation-private snapshot có đúng năm giá trị nội dung ban đầu.
  Dirty là so sánh draft hiện tại với snapshot theo dạng giá trị mà submit sẽ
  lưu; dùng normalization hiện có hoặc helper nhỏ dùng chung, không parse label
  và không đưa state UI vào domain/repository.
- Đăng ký listener cho năm `TextEditingController` và cập nhật dirty state khi
  người dùng gõ. Prefill phải có suppression rõ ràng để việc set controller
  trong lần load đầu không gọi `setState` giữa `build` hoặc làm form dirty.
- Nếu người dùng sửa rồi trả lại đúng snapshot, Save phải disabled lại.
- Nhận trạng thái `hasTagDraft` từ `CardTagSectionWidget`. Nó chỉ tham gia
  `_hasUnsavedWork = contentDirty || hasTagDraft`; không tham gia
  `contentDirty/canSave`.
- Bọc edit form bằng `PopScope<Object?>` với `canPop: false` và
  `onPopInvokedWithResult`. Close `×` và system Back gọi cùng một async exit
  coordinator; không có hai bản logic.
- Pristine thì rời ngay. Dirty content hoặc tag draft thì mở shared
  `MxConfirmDialog` với localized title `Discard changes?`, message nói nội dung
  chưa lưu sẽ mất, destructive action `Discard`, secondary `Keep editing`.
  `Keep editing` giữ nguyên toàn bộ draft/focus/scroll.
- Chặn re-entrancy: nhiều Back/tap Close khi dialog đang mở chỉ tạo một dialog.
  Trong lúc CardEdit đang submit, Close/Back không được tạo pop hoặc dialog.
- Sau save thành công, cho phép đúng một programmatic pop mà không hiện discard
  dialog. Cập nhật bypass/baseline trước, chờ tree phản ánh `canPop`, rồi pop;
  test phải tái hiện đường này để tránh PopScope nuốt chính kết quả save.
- Save failure giữ nguyên content dirty và mọi text; không đóng màn.
- Loading/error face không được hiện discard dialog vì chưa có draft được
  prefill. Create mode giữ behavior hiện tại.

Thêm ARB keys EN/VI cho discard dialog và chạy generation theo repo. Không
dùng lại key của Deck hoặc Import: thông điệp và ownership khác nhau.

### 2. Save action ghim đáy

`MxContentShell` hiện sở hữu `Scaffold` nhưng chưa có footer slot. Thêm đúng một
optional `bottomNavigationBar` passthrough (hoặc tên typed tương đương đã tồn tại
trên latest main), default null để mọi caller hiện tại giữ nguyên pixel và
behavior. Thêm shared test chứng minh caller cũ không đổi và footer không nằm
trong scroll body.

Edit mode truyền một action bar gồm:

- `SafeArea(top: false)`;
- horizontal padding `mxScreenGutter(context)`, vertical padding bằng
  `AppSpacing`;
- một `MxActionButton` primary full-width, label `Save changes`;
- disabled khi pristine, enabled khi `contentDirty`, loading/disabled trong
  submit; tag draft hoặc committed Tag/Flag không bật nút.

Action bar phải nằm trên app bottom navigation và trên keyboard, không phủ nội
dung cuối. Scroll body phải có đủ bottom clearance để Delete vẫn đọc/chạm được.
Không dùng `bottomSheet`, overlay hoặc fixed pixel inset. Nếu screen vượt file
size guard, tách `CardEditorActionBarWidget` dưới `widgets/sections/`; không đưa
dirty logic vào component thuần hiển thị.

### 3. Delete hierarchy

- Bỏ `cardEditorDangerZone` khỏi production UI và xóa ARB key/generated getter
  nếu không còn caller. Không để dead localization.
- `CardDangerZoneWidget` có thể đổi tên thành tên mô tả action nếu tên cũ không
  còn đúng; giữ file seam nếu nó vẫn sở hữu confirm + post-delete navigation.
- Không dùng raw `OutlinedButton` với local style. Thêm một typed
  `MxActionButtonVariant.destructiveSecondary` (tên tương đương được phép nếu
  nhất quán) dùng `OutlinedButton`, foreground/side từ resolved error/danger
  semantic pair, nền trong suốt, disabled/focus/pressed states đúng theme.
- Default, primary, secondary và filled destructive hiện có không đổi. Bổ sung
  unit/widget/golden/Widgetbook cho variant mới.
- Delete nằm trong scroll body sau Tags, full-width theo content column nhưng
  nhẹ hơn pinned Save. Giữ nguyên dialog xác nhận, copy Trash/Undo, double-submit
  guard, route fallback và failure behavior.

### 4. Flag action

Behavior hiện tại đã gần đúng; không viết lại controller:

- off: `Icons.flag_outlined`, resolved `onSurfaceVariant`;
- on: `Icons.flag`, resolved `semantic.warning`;
- tooltip/semantic label dùng hai key hiện có; target tối thiểu 48dp; submitting
  disables action; failed write giữ icon trước đó và hiện failure như hiện tại.

Đưa widget về `MxIconButton`. Nếu latest main đã có typed tone API từ feature
khác, reuse và thêm `warning` chỉ khi thiếu. Nếu chưa có, mở rộng bằng enum typed
`standard/warning` với default giữ nguyên; không thêm `Color?`, không local
`Theme`, không raw `IconButton` trong feature.

### 5. Front/Back và progress note

- Front `MxTextField` dùng `context.texts.titleLarge` (chỉ value style), Back giữ
  body input style mặc định. Label, hint, validation, max length, min/max lines,
  keyboard action và data không đổi.
- Dùng `helperText` đã có của **Back field** cho `cardEditorProgressNote`, theo
  lựa chọn ít scope nhất trong yêu cầu owner. Bỏ dòng Text lơ lửng hiện tại.
  Không đổi copy BR-10 và không biến note thành validation.
- Test style resolved thay vì chỉ tìm text; Front phải có visual weight lớn hơn
  Back ở light/dark và không clip Hangul tại text scale lớn.

### 6. Optional details disclosure

Đây là inline disclosure, không phải navigation:

- collapsed label phải nói cụ thể ba nội dung: `Add example, hint & pronunciation`
  và bản dịch VI tương ứng;
- dùng trailing `Icons.expand_more` khi đóng, `Icons.expand_less` khi mở;
- toàn row là một target ≥48dp, có expanded/collapsed semantics và keyboard tap;
- fields, validation và quy tắc tự mở khi card đã có detail giữ nguyên;
- không dùng `chevron_right`, không thêm Notes vì data model không có Notes.

### 7. Tag input và chip

Tags vẫn là immediate-save section:

- Mở rộng `MxTextField` bằng một typed trailing action nhỏ (icon, localized
  semantic label, callback), không expose `InputDecoration` hoặc color/style
  tùy ý. Render action trong `suffixIcon` với target ≥48dp.
- Add tag có `Icons.add`, tooltip/semantic label localized, và cùng gọi một
  `_submitTag()` với `onSubmitted`. Blank-after-trim, submitting hoặc full cap
  không gọi controller; failed add giữ text; success mới clear như hiện tại.
- Khi `tags.length == kMaxTagsPerCard`, không render input. Thay bằng localized
  body/helper text nói đã đạt 10/10. Counter vẫn phản ánh 10/10; không để người
  dùng gõ rồi mới báo lỗi cap.
- Khi dưới cap, field còn nhìn thấy. Add action disabled nếu input trim rỗng hoặc
  mutation đang chạy. Đăng ký listener cho input để trạng thái nút và
  `hasTagDraft` cập nhật ngay; dispose đầy đủ.
- Chip hiện đã kế thừa `AppRadius.pill` từ `app_chip_theme` và app theme đã đặt
  `MaterialTapTargetSize.padded`. Không thêm `StadiumBorder`, không bọc 48px một
  cách mù quáng. Trước hết viết test hit target cho delete affordance bằng
  `meetsGuideline(androidTapTargetGuideline)` và hit-test các điểm biên. Chỉ nếu
  production tree thật vẫn dưới 48dp mới thêm constraint/token nhỏ nhất mà
  không làm toàn chip cao 48px một cách không cần thiết.
- Remove failure giữ chip và hiện feedback; committed add/remove không làm Save
  dirty. Chữ đang gõ chưa submit phải kích hoạt exit guard.

## Test bắt buộc

Mở rộng `card_editor_edit_test.dart` và tách test theo seam nếu file guard yêu
cầu. Tối thiểu phải có:

1. pristine Save disabled; Front/Back/detail change enable; revert disable;
2. tag/flag mutation thành công không bật Save; unsubmitted tag draft không bật
   Save nhưng bật discard guard;
3. Close và system Back dùng cùng dialog; Keep editing giữ draft; Discard pop;
   repeated Back không stack dialog;
4. successful save pop không bị guard chặn; failed save giữ dirty; close inert
   khi submitting;
5. pinned Save còn nhìn thấy sau khi scroll tới Tags/Delete và khi keyboard mở;
   nó không phải descendant của `SingleChildScrollView`;
6. Delete là outlined destructive, nhẹ hơn Save, vẫn mở đúng confirm và giữ
   Trash/Undo/navigation behavior;
7. Flag off/on/loading/failure có đúng icon, resolved color, tooltip, semantics
   và target;
8. Front value style lớn hơn Back; BR-10 note là helper của Back, không còn text
   rời;
9. details label/icon/expanded semantics đúng và auto-expand card có detail;
10. Add tag bằng suffix và IME submit đi cùng path; blank/full/busy không write;
    cap 10 ẩn field; failure giữ draft;
11. chip delete target đạt Android guideline và remove failure không mất chip;
12. EN/VI, light/dark, 320dp @ textScaler 2.0 không overflow hoặc che action.

Thêm `getRect` assertions trên production `CardEditorScreen` cho shared gutter,
footer, viewport, field edges, disclosure row, tag action và delete action.
Golden/render states: pristine, dirty, details open, tags 0/9/10, flagged,
validation failure, save failure, discard dialog và delete confirm.

## Verification và clean stop

Inner loop:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Vì thay đổi nhìn thấy được, cập nhật/inspect golden và gallery rồi chạy full gate:

```bash
flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator integration suite: mọi behavior mới ở đây có thể chứng minh
bằng host widget/router test và không thêm platform binding, plugin, persistence
hoặc route mới. Báo `not run — scoped host verification`, không gọi là pass.

Clean stop chỉ khi docs/code/tests đồng thuận; Tags/Flag vẫn immediate, Save chỉ
sở hữu năm content fields; mọi exit path được bảo vệ; không double dialog/pop/
submit; footer không che content/keyboard; accessibility target và semantics
xanh; mọi production state đã render/inspect; không còn P0/P1/P2 hoặc visual
divergence chưa được duyệt; changed gate và full gate đều xanh.

