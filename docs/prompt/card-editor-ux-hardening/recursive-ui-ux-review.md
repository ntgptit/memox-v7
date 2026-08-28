# Recursive UI/UX Review — Card Editor Concept Parity

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và tự sửa triệt để hierarchy, shared edges, form rhythm, sticky actions, light/dark parity và accessibility của Edit flashcard theo concept mới |
| **Scope** | Production edit-mode Card Editor, states/dialogs, shared variants, Widgetbook, geometry tests, goldens và gallery; không redesign Create/Card Detail/Card List |
| **Source of truth for** | Quy trình recursive UI/UX review Card Editor concept parity |
| **Depends on** | `docs/prompt/card-editor-ux-hardening/implementation.md`, concept PNG đã hash, wireframe M4.11, MemoX tokens/shared components và production Card Editor |
| **Updated by task** | Card Editor concept-parity prompt |
| **Last updated** | 2026-08-27 |

---

Chạy trên latest worktree **sau** architecture/logic repair. Đọc lại đầy đủ
`CLAUDE.md`, implementation prompt, wireframe M4.11, theme/shared components,
production widgets, current tests và latest diff. Không commit, push, tạo PR
hoặc merge trong review này; không sửa đồng thời với review agent khác.

## Reference bắt buộc

Mở và inspect ảnh gốc trước mỗi audit cycle:

- `C:\Users\ntgpt\AppData\Local\Temp\codex-clipboard-b4b92217-b93c-4850-9c2f-50d630b83d2f.png`
- SHA-256 `16F50DFB5A77BA16AF707F8B195FE8F15876BC5A8806FCD41C8C39A79E2B5418`
- `1286 × 1217`

Hash mismatch/missing file là blocker; không review bằng ký ức. Hai phone frame
là light/dark và top/scrolled view của **cùng screen**. Dấu viền ngoài thiết bị,
status bar và crop của mock không phải app geometry.

### Approved differences với concept

- Không mic, không TTS/speaker action.
- Không fake `Last edited · reviews · recall`; không tính accuracy/streak trong
  editor. History entry chỉ được mở route hiện có và không được bịa metric.
- Deck context read-only, không chevron/dropdown giả.
- Flag vẫn hiện vì là chức năng production BR-92.
- Không heading `Danger zone`; Trash card dùng ngôn ngữ sản phẩm.
- Soft-delete/Move to Trash không dùng danger/destructive role và không nói
  history bị xoá; purge vĩnh viễn mới mang role đó.
- Cỡ chữ đến từ typography role MemoX hiện tại. Không tăng/giảm global font,
  không tắt text scaling và không copy font size từ ảnh.
- Colors/radius/shadow lấy từ light/dark tokens của repo; ảnh chỉ quyết định
  hierarchy, emphasis và surface separation.

Ngoài danh sách này, khác biệt material với section order, grouping, shared
edges, action hierarchy hoặc form rhythm của concept là unapproved divergence.

## Pass 1 — `AUDIT_ONLY`

Render production route/harness thật và inspect từng PNG bằng mắt; chưa sửa.
Mỗi state ghi focal point, reading order, section hierarchy, shared edges,
spacing rhythm, action weight, feedback ownership, contrast, semantics,
responsive/keyboard behavior và approved/unapproved differences.

### State coverage tối thiểu

- light + dark, EN + VI;
- 320×568 @ textScaler 2.0, 390×844 và 412×915;
- loading, typed load error/not found;
- pristine, dirty Front, dirty optional detail, reverted-pristine;
- details collapsed-empty và expanded-with-data;
- Tags 0, 9, 10; Add tag collapsed/entry; add/remove loading/failure;
- Flag off/on/loading/failure;
- validation error, save submitting/failure/success transition;
- discard dialog, Keep editing, Discard;
- Trash confirmation, submitting/failure, success/Undo handoff;
- keyboard focus Front, Back, optional field và Add tag;
- long Hangul, long Vietnamese copy và long deck breadcrumb.

Một golden vừa update không phải bằng chứng parity. Phải đặt concept và render
cạnh nhau, liệt kê mọi khác biệt, rồi phân loại approved hoặc finding.

## Geometry contract phải đo trên production tree bằng `tester.getRect`

### A. One content column

1. Breadcrumb, History row, deck context, Front, Back, Optional heading/fields,
   Tags, divider và Trash card dùng cùng `mxScreenGutter` left/right edges.
2. Không section nào tự thêm một page gutter thứ hai. Đặc biệt Optional fields
   và Tags không bị thụt vào như bug Import source cards trước đây.
3. Content max width được constrain ở wider surface; không kéo form vô hạn như
   stretched phone layout.

### B. Field alignment và rhythm

4. Front/Back/Example/Hint/Pronunciation surface left/right edges bằng nhau.
5. Mỗi external label row thẳng với field; counter có cùng right edge; required/
   optional label không làm title/counter lệch baseline.
6. Label→field gap dùng tight token và nhỏ hơn field/section→section gap.
7. Front và Back giữ surface geometry ổn định khi counter/error/helper xuất
   hiện. Front text visual weight lớn hơn Back nhưng không tăng global font.
8. Optional field icon là decoration, cùng optical center với label, không tạo
   một cột lề mới làm field bị lệch.

### C. Tags và Trash

9. Tag chips và `+ Add tag` chung baseline/Wrap gap; entry field mở ra không
   đổi outer edges; 10 tags không overflow hoặc tạo horizontal scroll.
10. Chip delete và Add action có hit rect ≥48dp, không chỉ semantics rect;
    hit-test các điểm biên qua production ancestors.
11. Divider và Trash card cùng width content. Trash card internal padding theo
    MxCard; title/body/button có grouping rõ nhưng action nhẹ hơn Save.
12. Trash card scroll hoàn toàn lên trên footer; không bị che, không dead space
    vô chủ và không dùng màu danger cho soft-delete.

### D. Header và pinned footer

13. App-bar Back, title, Flag và compact Save không overlap tại 390/412.
14. Tại 320×2.0, adaptive mode giữ title/action semantics; không ellipsize tới
    mức mất nghĩa và không dùng local magic breakpoint.
15. Bottom bar nằm ngoài `SingleChildScrollView`, trên system safe area và
    keyboard. Nó không nhảy khi pristine→dirty→loading→failure.
16. Cancel và Save cùng baseline/touch height; Save rộng hơn Cancel theo concept
    mà không hardcode px. Helper nằm dưới action row, center và không bị home
    indicator che.
17. Keyboard mở vẫn thấy/chạm được footer; focused field được ensure-visible;
    không double-count viewInsets hoặc phủ lên input cuối.

### E. Dialogs và route entry

18. Discard và Trash confirm dùng `MxConfirmDialog`, fit EN/VI @2.0; safe action
    có focus đúng; destructive semantics không gán nhầm cho soft-delete.
19. History entry và breadcrumb có target/semantics rõ, không làm row tĩnh trông
    tappable hoặc row action trông tĩnh.
20. Deck context không có chevron, pressed state hay button semantics.

## Visual hierarchy và accessibility checks

- App bar, context rows, required content, optional content, tags, Trash và
  footer đọc thành các nhóm rõ như concept; không quay lại một dải text phẳng.
- Top Save là shortcut, bottom Save là primary thường trực. Cả hai đồng bộ state;
  top shortcut không cạnh tranh với title/Flag và không tạo hai primary focal
  points có weight ngang nhau.
- Disabled pristine phải phân biệt được với enabled mà vẫn đọc được; loading
  không đổi button rect hoặc làm label biến mất không có status.
- Back/Cancel/Save/Flag/Add tag/chip delete/History có localized accessible name,
  role, enabled/selected/busy state đúng.
- Required/optional, Flag on/off, validation và soft-delete intent không chỉ
  truyền bằng màu. Contrast text ≥4.5:1; boundary/icon cần nhận diện ≥3:1 trên
  đúng light/dark surface.
- Tab order hợp lý: Back → Flag → top Save → History → fields → detail controls
  → Tags/Add/delete affordances → Trash → Cancel → bottom Save. Pinned Save
  không tạo semantics duplicate mơ hồ; hai nút phải có vị trí/tên rõ.
- Moderate/large text scaling vẫn hoạt động. Không `TextScaler.noScaling`, clamp
  cố định hoặc giảm font feature-local để làm screenshot vừa.
- Mọi spacing/radius/icon size/color/duration từ token/shared variant; không
  hardcode geometry để một viewport xanh.

## Pass 2 — `APPLY_FIXES`

Đóng băng audit-only report rồi sửa P0 → P1 → P2. Với từng finding:

1. thêm geometry/semantics/style regression đỏ trên production tree;
2. sửa nhỏ nhất bằng token/shared component/feature section đúng owner;
3. render lại đúng state và inspect;
4. re-read latest worktree;
5. chạy lại toàn bộ matrix từ đầu.

Không chữa visual bằng đổi business mutation, persistence, route contract hoặc
approved difference. Nếu cần làm vậy, dừng và trả finding về architecture
review. Không regenerate golden trước khi state comparison sạch và không coi
golden mới là bằng chứng tự thân.

## Verification và clean stop

Sau targeted visual/widget tests:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator; báo `not run — scoped host verification`. Clean stop chỉ
khi mọi production state đã inspect; geometry/semantics/hit-target/contrast
tests xanh; no nested-gutter drift; footer không che body/keyboard; no overflow,
dead space hoặc action ambiguity; approved differences được liệt kê; gallery
khớp latest validated commit; final gate xanh và không còn P0/P1/P2 hoặc
unapproved divergence. Nếu không publish được gallery theo contract repo, báo
blocker chính xác, không tuyên bố visual review hoàn tất.
