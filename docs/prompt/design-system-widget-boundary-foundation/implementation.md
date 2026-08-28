# Implement Design-System Widget Boundary Foundation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Dựng policy registry và AST guard có symbol resolution để MemoX phát hiện raw Material/Cupertino policy component trong feature mà chưa làm đỏ toàn bộ nợ hiện hữu |
| **Scope** | Architecture decision, resolved-AST classifier, component admission registry, exact migration baseline, local/CI gate wiring và fault-injection tests; không migrate production call-site |
| **Source of truth for** | Hướng dẫn thực thi foundation của design-system boundary; quyết định chính thức phải được promote vào AD mới trong `docs/architecture.md` |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, AD-04, AD-14, AD-15, `.claude/skills/flutter-design-system/SKILL.md`, `lib/shared/widgets/`, MemoX theme và guard hiện hành |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Thực hiện trong worktree sạch từ `origin/main` mới nhất. Prompt này là execution
aid; không được coi danh sách widget trong prompt là business rule. Không sửa
production UI ở đợt foundation.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Feature vẫn instantiate raw Material controls dù MemoX đã có theme và nhiều `Mx*` component. | Tạo boundary chạy bằng máy thay vì dựa vào review nhớ danh sách. |
| 2 | Regex bỏ sót alias, named constructor, generic và symbol mới của Flutter; đồng thời có thể match comment hoặc class trùng tên. | Dùng `package:analyzer` với resolved elements, không dùng regex làm classifier chính. |
| 3 | Cấm toàn bộ Material ngay sẽ làm đỏ khoảng bốn chục call-site đang tồn tại và khuyến khích allowlist tuỳ tiện. | Foundation dùng exact ratchet baseline: nợ cũ không tăng, call-site mới fail. |
| 4 | Bắt mọi Material widget qua wrapper tạo ra wrapper chỉ rename/forward, nhất là component đã được `ThemeData` sở hữu đủ policy. | Mọi symbol phải được phân loại `mxRequired` hoặc `themeOwnedRaw`; chưa phân loại thì fail. |
| 5 | Một lớp `Mx*` có thể được tạo chỉ để chữa guard mà không sở hữu policy. | Registry bắt mỗi shared component khai policy thật và evidence; structural heuristic chỉ là tín hiệu review, không được giả vờ là chứng minh. |

## Policy cần promote thành Architecture Decision

Đọc `docs/architecture.md` mới nhất, lấy AD ID tiếp theo mà không renumber ID cũ,
và thêm một AD quyết định đầy đủ. Task này được phép sửa tường minh
`docs/architecture.md` cho quyết định này.

AD phải chốt ba tầng:

1. **Raw forbidden by disposition.** Feature presentation MUST NOT instantiate
   Material/Cupertino constructor hoặc gọi top-level design-system function đã
   được registry phân loại `mxRequired`; phải dùng shared MemoX API sở hữu policy.
2. **Raw allowed, style restricted.** `Text`, `Icon`, `Image`, `Container`,
   `DecoratedBox` và primitive tương tự được dùng trực tiếp, nhưng color,
   typography, spacing, radius, duration, shadow/elevation và component state
   phải đến từ token/theme/approved helper. Tái sử dụng các guard hiện có; không
   tạo một rule trùng nghĩa chỉ để tăng số rule.
3. **Raw free.** Layout/render/async/semantics primitives như `Row`, `Column`,
   `Stack`, `Wrap`, `Padding`, `SizedBox`, `ListView`, `LayoutBuilder`,
   `SafeArea`, `Semantics`, `AnimatedBuilder`, `FutureBuilder` không cần `Mx*`
   wrapper chỉ vì chúng là Flutter widget. State-management rule hiện có vẫn có
   thể cấm một primitive vì lý do khác.

AD phải nêu rõ:

- `themeOwnedRaw` chỉ hợp lệ khi `ThemeData`/token đã sở hữu toàn bộ visual state
  cần thiết, feature không truyền style override, và wrapper mới sẽ không sở hữu
  thêm visual, interaction, accessibility, responsive, variant, behavior,
  theme-mapping hoặc app-composition policy;
- mọi Material/Cupertino symbol gặp trong feature phải có disposition; symbol
  chưa biết là lỗi `unclassified design-system dependency`, không tự được phép;
- Android-first không cho raw Cupertino trong feature; nếu sau này iOS được mở,
  adaptivity sống ở theme/shared layer chứ không ở feature branch;
- guard failure vì một nhu cầu mới là design-system gap review, không phải chỉ
  đổi tên raw widget thành `MxWidget`;
- shared component mới phải sở hữu ít nhất một policy thật, có automated evidence
  và Widgetbook surface phù hợp; không tạo `MxRow`, `MxColumn`, `MxPadding`.

## Inventory trước khi viết guard

Quét production source thực tế dưới
`lib/features/*/presentation/**/*.dart`, bỏ generated files. Lập inventory theo:

- resolved library URI;
- symbol và constructor/function cụ thể;
- file, line và số occurrence;
- shared equivalent hiện có;
- recommended disposition và lý do;
- style override đang được truyền.

Đối chiếu tối thiểu các họ đang tồn tại: action, input, selection, chip/menu,
shell/navigation, overlay/picker, surface/interaction và feedback/status. Không
copy danh sách từ nhận xét của user như sự thật; source mới nhất là inventory.

## Resolved-AST guard

Tạo một Dart guard dưới `tool/` dùng dependency `analyzer` đã được khai trực tiếp
trong `pubspec.yaml`. Không thêm custom_lint hoặc parser regex song song.

Guard MUST:

- nhận repo root/path từ CLI, không phụ thuộc current directory ngầm;
- dùng resolved unit/element để nhận owner library của constructor và top-level
  function call;
- bắt được default/named constructor, `.icon`, generic, prefixed import như
  `m.FilledButton`, và function như `showTimePicker`;
- không match comment, string, import không dùng, hoặc class cục bộ trùng tên;
- phân biệt Material, Cupertino và base widgets qua resolved source URI;
- chỉ scan handwritten production feature presentation; không scan generated,
  tests, Widgetbook, app composition root, core theme hoặc shared implementation;
- fail nếu scan được 0 target hoặc resolution lỗi, thay vì báo pass rỗng;
- in diagnostic có rule ID, file:line, resolved symbol, disposition, expected Mx
  API hoặc lý do cần classification;
- dùng deterministic ordering và path chuẩn POSIX để Linux/Windows cho cùng kết
  quả.

Tạo machine-readable registry dưới `tool/`, ưu tiên JSON để dùng `dart:convert`
thay vì thêm dependency YAML. Registry có hai phần:

- raw symbol disposition: library family, symbol, `mxRequired` hoặc
  `themeOwnedRaw`, approved shared owner/allowed visual arguments và rationale;
- shared component admission: public `Mx*` type, source file, policy categories
  nó sở hữu, raw backing nếu có, automated evidence và Widgetbook evidence.

Không thêm disposition `allowed` chung chung. `themeOwnedRaw` phải chỉ rõ các
named argument visual bị cấm ở feature; guard phải kiểm được các argument này.

## Ratchet baseline tạm thời

Foundation không migrate production code. Tạo exact baseline riêng dưới `tool/`
chỉ cho những occurrence `mxRequired` đã tồn tại ở commit này.

Baseline MUST:

- dùng path + resolved symbol + occurrence count, không dùng wildcard;
- không chứa Cupertino nếu source hiện không có Cupertino;
- fail khi có path/symbol mới hoặc count tăng;
- fail khi entry đã biến mất nhưng baseline chưa được thu nhỏ;
- không biến `themeOwnedRaw` thành debt;
- được ghi rõ là tạm thời và phải bị xoá ở enforcement phase.

## Shared-component admission

Backfill registry cho toàn bộ public `Mx*` type đang nằm trong
`lib/shared/widgets/`. Guard MUST fail khi:

- có public `Mx*` type/file mới nhưng không có registry entry;
- `owns` rỗng hoặc chứa category ngoài vocabulary đóng;
- source/evidence path không tồn tại;
- shared type không có stress/behavior/accessibility evidence phù hợp;
- component cần visual states nhưng không có Widgetbook/golden evidence.

Một heuristic “một raw child + forward nhiều params” MAY in advisory finding để
review, nhưng MUST NOT tự động kết luận wrapper trivial. Admission evidence và
human review mới quyết định; tránh false positive với wrapper nhỏ nhưng thật sự
sở hữu theme/state/a11y policy.

## Gate integration

Nối guard vào đúng một đường local/CI:

- `.claude/skills/flutter-workflow/scripts/dod_check.sh` ở static phase;
- `.github/workflows/ci.yml` static job;
- verification impact planner để thay đổi dưới `tool/` hoặc registry không thể
  chọn plan rỗng;
- unit/fault-injection tests của tooling.

Không chạy guard loose như một gate thứ hai ngoài `dod_check.sh` khi xác nhận
cuối. Lệnh riêng chỉ được dùng trong test fault injection của chính guard.

## Tests bắt buộc

Synthetic fixtures phải chứng minh ít nhất:

- `FilledButton`, `FilledButton.icon`, `SegmentedButton<T>` và alias import bị
  nhận đúng;
- raw Cupertino bị fail;
- top-level picker/dialog function được nhận;
- `Row`, `Text`, `Icon`, `Container` pass;
- literal/style violation vẫn do token guard hiện hành bắt, không bị classifier
  làm mờ;
- local class tên `FilledButton`, comment và string không tạo finding;
- unclassified Material symbol fail;
- `themeOwnedRaw` pass khi không override và fail khi dùng forbidden visual arg;
- baseline tăng, stale, wildcard hoặc target count 0 đều fail;
- Mx component thiếu policy/evidence fail;
- Linux/Windows separator cho cùng inventory.

Fault-inject một file vi phạm vào fixture, chứng minh exit non-zero và diagnostic
đúng; xoá/đổi fixture sang hợp lệ rồi chứng minh exit zero.

## Documentation và WBS

Được sửa:

- `docs/architecture.md` cho AD mới;
- `docs/wbs.md` để ghi ba phase foundation → migration → enforcement, đánh dấu
  phase này đúng trạng thái thực;
- README của guard/tooling nếu cần cho cách chạy và rule ownership;
- `CLAUDE.md` chỉ khi cần cập nhật danh sách mechanical gate, không chép lại AD.

Không sửa BR/UC/data model vì đây là engineering boundary, không đổi nghiệp vụ.

## Verification và delivery

Chạy inner loop bằng:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Sau auto-fix và sync `origin/main`, chạy full gate:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator: phase này không đổi production feature behavior. Không
regenerate gallery/golden nếu diff thực sự không có user-visible effect; báo rõ
no visual delta và dẫn existing gallery URL trong PR.

## Clean stop

Chỉ dừng clean khi:

- AD mới, registry, resolved-AST guard, exact baseline và gate wiring thống nhất;
- fault injection xanh ở cả positive/negative cases;
- current raw debt không tăng và scanner không pass rỗng;
- không file production UI nào đổi;
- changed gate và full gate xanh;
- branch được push, tạo non-draft PR kèm review/gate/no-visual-delta evidence;
- không merge PR nếu execution session không được user yêu cầu rõ.
