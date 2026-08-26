# Recursive UI/UX Review — Card Editor UX Hardening

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và tự sửa triệt để hierarchy, footer geometry, form clarity, responsive và accessibility của Edit flashcard |
| **Scope** | Production edit-mode Card Editor, its dialogs/states, shared control variants, Widgetbook, goldens và visual audit |
| **Source of truth for** | Quy trình recursive UI/UX review Card Editor UX hardening |
| **Depends on** | `docs/prompt/card-editor-ux-hardening/implementation.md`, wireframe M4.11, MemoX tokens và production Card Editor |
| **Updated by task** | Card Editor UX hardening prompt |
| **Last updated** | 2026-08-26 |

---

Chạy trên latest worktree **sau** architecture/logic repair. Đọc lại
`CLAUDE.md`, implementation prompt, wireframe M4.11, theme/shared components,
production widgets, current tests và latest diff. Không commit, push, tạo PR
hoặc merge; không sửa đồng thời với review agent khác.

Không có concept image mới cho task này. Chuẩn so sánh là owner feedback trong
implementation prompt đã được promote vào wireframe, design tokens và behavior
contract. Các approved differences so với câu chữ ban đầu:

- Tags và Flag ghi tức thì nên không tham gia trạng thái Save; chỉ draft tag chưa
  submit tham gia discard guard.
- Progress note dùng `helperText` của Back thay vì một banner dưới AppBar.
- Chip đã dùng `AppRadius.pill` và padded tap target từ app theme; chỉ thêm
  constraint nếu production hit-test chứng minh chưa đủ 48dp.
- Delete dùng typed shared destructive-outlined variant, không raw local button.
- Optional details không nhắc Notes vì data model chỉ có Example, Hint và
  Pronunciation.

Ngoài danh sách này, mọi khác biệt với implementation prompt/wireframe là
**unapproved divergence**.

## Pass 1 — `AUDIT_ONLY`

Render production route/harness thật và inspect từng PNG bằng mắt; chưa sửa.
Tối thiểu gồm:

- light + dark, EN + VI;
- 320dp @ textScaler 2.0, 390dp và 412dp;
- pristine, dirty Front, dirty optional detail và reverted-pristine;
- details collapsed/expanded và card được auto-expand vì có data;
- Tags 0, 9, 10; tag text draft; add/remove loading và failure;
- Flag off/on/loading/failure;
- save submitting/failure/validation error/success transition;
- discard dialog, Keep editing, Discard và delete confirmation;
- keyboard đóng/mở khi focus Front, Back, optional field và Add tag;
- long Hangul, long Vietnamese labels và RTL smoke nếu repo hỗ trợ locale đó.

Mỗi state phải ghi focal point, reading order, action hierarchy, ownership của
feedback, spacing, responsive behavior, keyboard/safe-area behavior, semantics,
contrast và approved/unapproved differences. Không chấp nhận golden chỉ vì file
vừa được update.

## Geometry contract phải đo bằng `getRect`

Dùng production `CardEditorScreen`, không dựng widget giả:

1. Front, Back, progress helper, disclosure, Tag section và Delete có cùng outer
   left/right edge theo `mxScreenGutter(context)`.
2. Pinned Save action có cùng horizontal gutter với content, nằm ngoài
   `SingleChildScrollView`, full-width trong gutter và luôn ở trên bottom safe
   area/app navigation.
3. Khi cuộn tới cuối, Delete nằm hoàn toàn trên footer, không bị che; body bottom
   clearance đúng token, không khoảng trắng vô chủ quá lớn.
4. Khi keyboard mở, Save còn nhìn/chạm được trên keyboard và field đang focus
   được `ensureVisible`; không double-count `viewInsets` hoặc safe area.
5. Save pristine/dirty/loading giữ cùng rect, không nhảy kích thước khi state đổi.
6. Delete nhẹ hơn Save bằng fill/outline resolved roles nhưng cùng touch floor;
   bỏ heading không để lại gap thừa.
7. Front và Back giữ cùng field edges; Front value typography lớn hơn Back nhưng
   label/counter/border không lệch baseline hoặc clip Hangul.
8. Details disclosure toàn row ≥48dp; label không đụng trailing expand icon tại
   VI/2.0; icon đổi hướng mà row không nhảy.
9. Tag suffix Add và mỗi delete affordance đạt target ≥48dp. Đo hit rect thật và
   hit-test biên; không suy từ kích thước glyph 24dp.
10. Chip dùng resolved `AppRadius.pill`; Wrap gap đều, không overflow ở 10 tags
    và input/cap message giữ đúng shared edges.
11. Flag action target ≥48dp, không che title; on/off icon giữ cùng center/rect.
12. Discard và delete dialog tuân `MxConfirmDialog`, action order/focus/width
    không overflow ở EN/VI/2.0.

## Visual và accessibility checks

- Save là primary duy nhất và luôn nhìn thấy; disabled pristine đủ khác enabled,
  loading không mất label/semantics hoặc đổi width.
- Delete không cạnh tranh visual weight với Save; danger không chỉ biểu đạt bằng
  màu, label vẫn rõ, confirmation vẫn nêu hậu quả Trash/Undo đúng production.
- Không còn chữ `Danger zone` hoặc khoảng trống từng dành cho nó.
- Progress note đọc như helper của Back, không trôi giữa hai section và không
  chiếm chỗ lỗi validation một cách làm layout giật không kiểm soát.
- Flag outline/filled + tooltip phân biệt được không cần màu; warning active đạt
  contrast trên app bar ở light/dark.
- Add tag có action nhìn thấy và IME action tương đương; full cap có giải thích,
  không có disabled field giả vờ nhận input.
- Error của content, tag add/remove và flag nằm gần operation sở hữu, có live
  semantics khi cần; không bị pinned footer che.
- Tab order: Close → Flag → Front → Back → details → detail fields → Tags → Add
  → chip delete actions → Delete → Save phải hợp lý theo production platform;
  pinned Save không chiếm focus sai hoặc lặp semantics.
- Mọi control icon-only có localized name; touch target đạt Android guideline;
  màu không là tín hiệu duy nhất; text contrast ≥4.5:1 và control boundary/icon
  cần nhận diện ≥3:1 trên đúng surface.
- Mọi spacing/radius/icon size/color đến từ token/shared component; không
  hardcode geometry để làm một viewport xanh.

## Pass 2 — `APPLY_FIXES`

Đóng băng audit-only report rồi sửa P0 → P1 → P2. Mỗi finding phải có state và
screenshot tái hiện; thêm geometry/semantics/style regression trước, sửa nhỏ
nhất bằng token/component có sẵn, render lại chính state, rồi chạy lại toàn ma
trận. Nếu visual fix cần đổi ownership mutation, dirty semantics, persistence
hoặc navigation, dừng và trả finding về architecture review.

Chỉ regenerate goldens/gallery sau khi state-by-state comparison sạch. Liệt kê
approved differences trong report; không dùng PNG mới làm bằng chứng tự thân.

## Verification và clean stop

```bash
flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator. Clean stop chỉ khi mọi production state đã inspect;
geometry, semantics, hit-target và contrast tests xanh; footer không che content
hay keyboard; không overflow/dead space/action ambiguity; gallery khớp latest
commit; không còn P0/P1/P2 hoặc unapproved divergence; final gate xanh. Nếu
gallery không publish được theo contract repo, báo blocker chính xác thay vì
tuyên bố visual review hoàn tất.

