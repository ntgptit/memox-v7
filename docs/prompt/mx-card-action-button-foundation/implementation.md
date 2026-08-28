# Implement MxCard and MxActionButton Foundation Hardening

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đóng API và hoàn thiện contract của hai shared component được dùng nhiều nhất MemoX mà không đổi nghiệp vụ của các feature đang tiêu thụ chúng |
| **Scope** | `MxCard`, `MxActionButton`, toàn bộ production call-site liên quan, public-API guard, tests, Widgetbook, goldens và tài liệu kỹ thuật; không thêm chức năng sản phẩm hoặc một họ wrapper card mới khi `MxCard` hiện tại đã sở hữu policy đó |
| **Source of truth for** | Hướng dẫn thực thi đợt hardening MxCard/MxActionButton; quyết định kiến trúc chính thức phải được promote vào AD/design-system contract của repo |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, AD-14, `docs/reviews/design-parity-checklist.md`, `.claude/skills/flutter-design-system/SKILL.md`, `.claude/skills/flutter-theme-design/SKILL.md` và các reference component tương ứng |
| **Updated by task** | MxCard/MxActionButton foundation prompt set |
| **Last updated** | 2026-08-27 |

---

Thực hiện trên worktree sạch đã sync `origin/main` mới nhất. Prompt này là
execution aid, không phải nguồn business behavior. Mọi callback, navigation,
controller/use-case call, dữ liệu hiển thị và BR/UC hiện hữu phải được giữ nguyên.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | `origin/main` đã hoàn thành M99.70: `MxCard.flat` và tri-state `isSelected` là contract có owner, test, Widgetbook và production migration; prompt cũ còn định tạo `MxChoiceCard` nên sẽ dựng abstraction thứ hai cho cùng policy. | Giữ và harden `flat`/`isSelected`; không tạo `MxChoiceCard`, không đảo ngược token/semantics đã chốt. |
| 2 | `MxCard` vẫn cho feature truyền `Color`, radius, elevation, border và `EdgeInsets`, nên phần surface language còn lại vẫn thoát khỏi component. | Thay đúng các escape hatch còn tồn tại bằng closed semantic recipes dựa trên inventory mới nhất. |
| 3 | Một taxonomy cố định `standard × inset × raised × focal × accent` hoặc `variant × tone × padding` có thể không khớp 50 call-site thật và tạo tổ hợp vô nghĩa. | Giữ vocabulary đã có (`flat`, raised default, selection); chỉ thêm named recipe có cụm caller thật và một private spec duy nhất. |
| 4 | M99.74/M99.75 vừa audit `MxActionButton`, xoá state drift, đồng nhất secondary/loading edge và chốt button pair; viết lại state resolver sẽ gây regression trên nền đã đo. | Xem button hiện tại là baseline; chỉ bổ sung API closure/evidence còn thiếu và sửa defect được test tái hiện. |
| 5 | Golden hiện tại chỉ chứng minh ảnh mới ổn định với chính nó; guard hiện tại chặn raw feature widget/style nhưng chưa ngăn public shared constructor mở visual escape lần nữa. | Thêm resolved API boundary test, production geometry/state assertions và recursive visual comparison trước khi nhận golden. |

## Nguồn phải đọc trước khi sửa

Đọc đầy đủ, theo thứ tự:

1. `CLAUDE.md` và `docs/document-conventions.md`.
2. `docs/architecture.md`, riêng AD-14 và mọi AD mới nhất về design-system boundary.
3. `docs/wbs.md`, tối thiểu M99.70, M99.74 và M99.75; sau đó đọc
   `docs/reviews/design-parity-checklist.md`, đặc biệt C1, C4 và các D-row giải
   thích flat/raised card trong production screens.
4. `.claude/skills/flutter-design-system/SKILL.md`.
5. `.claude/skills/flutter-theme-design/SKILL.md` và:
   - `references/buttons-actions.md`;
   - `references/surfaces-containers.md`;
   - `references/construction-template.md`;
   - `references/legacy-and-guards.md`.
6. `lib/shared/widgets/mx_card.dart`, `mx_action_button.dart`,
   `mx_button_pair.dart`, `mx_pressable.dart`, `mx_icon.dart` và các related
   tests/Widgetbook entries.
7. Tất cả production `MxCard`/`MxActionButton` call-site trên `origin/main` mới
   nhất; không dùng số lượng nêu trong prompt như inventory cố định.

Nếu docs, skill và code mâu thuẫn, docs/AD đã được owner chốt thắng. Ghi drift
trước khi sửa; không hợp thức hoá code chỉ vì test hiện tại đang xanh.

## Phase 1 — inventory và component contract

Tạo inventory machine-readable hoặc test fixture ổn định cho mọi production
call-site của `MxCard` và `MxActionButton`. Với `MxCard`, ghi ít nhất:

- file/line và feature owner;
- ground thực tế: page, surface, sheet/dialog hoặc một card khác;
- visual role hiện tại: existing `flat`, existing raised default, focal/accent,
  muted/feedback và tri-state selected;
- padding, radius, elevation, fill, border đang truyền;
- interactive behavior: tap, long-press, nested controls, keyboard/semantics;
- product component đang bọc nó, nếu có;
- canonical recipe/composed component đích.

Inventory phải phát hiện count bằng 0 hoặc call-site chưa phân loại; không được
coi một list làm tay đã cũ là bằng chứng đủ.

Promote engineering decision vào canonical architecture location:

- re-read `docs/architecture.md` sau khi sync;
- nếu đã có AD sở hữu closed shared-component API thì cập nhật đúng AD đó;
- nếu chưa có, lấy AD ID kế tiếp và thêm một AD, không renumber ID cũ;
- không tạo AD trùng nghĩa chỉ vì một prompt cũ chưa commit đề xuất tên khác.

Trước khi thêm AD, xác nhận M99.70/M99.74/M99.75 đã ghi những engineering
decisions nào. Không promote một rule trái với chúng nếu owner chưa supersede.
AD hiện hữu hoặc AD mới phải chốt:

- surface/component visual policy thuộc theme/shared layer;
- feature chọn meaning và external layout, không chọn color/radius/elevation/
  shadow/border/internal padding;
- foundation component không expose Flutter visual primitive types;
- tri-state `MxCard.isSelected` tiếp tục thuộc foundation; selected tint chỉ
  được đưa vào component bằng closed semantic treatment có real caller, không
  bằng `Color` và không bằng một `MxChoiceCard` trùng trách nhiệm;
- product-specific compositions không được chui vào shared foundation;
- ThemeData và Mx wrapper là hai tầng của cùng design language, không phải hai
  hệ style khác nhau.

## Phase 2 — đóng `MxCard` thành surface primitive

Refactor `lib/shared/widgets/mx_card.dart` để public API không còn expose:

- `Color`/`Color?`;
- radius dưới dạng `double`;
- elevation dưới dạng `double`;
- `BorderSide`, border color, shadow, decoration hoặc shape;
- `EdgeInsets`/`EdgeInsetsGeometry` cho internal padding.

Public surface API phải dùng named semantic recipes. Baseline bắt buộc phải giữ:

```dart
MxCard.flat(...)
MxCard.raised(...)
// Các recipe khác chỉ khi inventory chứng minh một meaning lặp lại.
```

Constructor unnamed hiện tại đang là raised surface. Migrate nó sang tên
semantic (`raised` hoặc tên canonical được AD chốt) thay vì đổi `standard` thành
flat rồi âm thầm đảo depth. `MxCard.flat` hiện hữu phải giữ zero-shadow, radius,
clip và pixel behavior trừ delta được owner duyệt.

Inventory phải phân loại các meaning dưới đây, nhưng không buộc tạo một public
constructor cho từng dòng nếu một dòng chỉ có một product caller:

| Meaning | Ground | Fill | Border | Elevation | Radius |
|---|---|---|---|---|---|
| flat | content/list hoặc card nằm trong sheet/dialog/surface khác | surface/sheet/card | canonical surface | subtle/selected | none | lg |
| raised | surface cần tách khỏi ground | page/surface | canonical surface | subtle/selected | card | lg |
| focal | hero/study prompt có cụm caller thật | page | canonical surface | approved edge | raised | xl |
| muted/accent | informational emphasis có meaning lặp lại | page/surface | approved container role | approved semantic edge | depth theo AD | recipe-owned |
| feedback | trạng thái info/success/warning/danger có contract thật | page/surface | semantic container | matching edge/ink contract | depth theo AD | recipe-owned |

Không dùng `MxCard.study()` hoặc `MxCard.deck()`: đây là domain/product names.
Feature pattern như `StudyCard`/`DeckCard` phải compose recipe chung.

Internal padding là một enum đóng:

```dart
enum MxCardPadding { none, compact, standard }
```

Map theo token hiện có; không mint số. `none` chỉ dành cho child tự sở hữu
canonical content area hoặc thành phần cần bám mép như progress track. Không thêm
`spacious` nếu inventory không có ít nhất một use case thật mà `standard` không
biểu đạt được.

Mọi recipe phải được map trong một private immutable spec; feature không được
import spec đó. Không để `variant × tone` thành hai trục public tự do. Nếu
feedback cần tone, tone chỉ được nhận bởi đúng feedback recipe và không ghép tự
do với raised/focal. Nếu muted/accent/feedback không có đủ real caller hoặc
không sở hữu non-color semantics, giữ product composition thay vì tạo wrapper
hoặc factory giả.

### Interactive contract bắt buộc

Khi `onTap` hoặc `onLongPress` có callback, card phải sở hữu:

- hover, pressed và focus-visible treatment;
- keyboard activation cho tap action;
- correct mouse cursor;
- ripple/overlay clip theo đúng recipe radius;
- semantics role, enabled/action state và content-derived accessible name;
- target tối thiểu 48×48 mà không phụ thuộc padding tình cờ;
- nested control vẫn thắng đúng gesture và giữ semantics riêng;
- focus ring không đổi size, position hoặc content layout;
- pointer/touch focus không để lại keyboard focus-visible ring sai mode.

Sửa defect hiện tại nếu `onLongPress != null` nhưng `onTap == null` bị rơi vào
nhánh non-interactive. Không thêm disabled-card API nếu inventory không có use
case thật; `onTap == null` mặc định là informational surface, không phải một
button disabled.

## Phase 3 — giữ selection một chủ và đóng semantic treatments

Không tạo `MxChoiceCard`: `MxCard.isSelected` đã là owner của selected border và
tri-state semantics theo M99.70. Giữ chính xác:

- `null`: card không selectable, không announce selected;
- `false`: selectable nhưng chưa chọn;
- `true`: selected border dùng token đã đo và announce selected;
- focus ring ưu tiên hơn selected edge, không dịch geometry.

Các selected fill hiện có khác nhau theo use case. Thay raw `color` bằng closed
semantic treatment/factory chỉ khi treatment đó có meaning và callers thật;
không ép mọi selectable card cùng tint, không để feature tự vẽ selected border,
và không thêm `isTinted` boolean mơ hồ.

Tương tự, error/feedback surfaces chỉ đi qua một closed feedback recipe nếu
recipe sở hữu container/edge/ink mapping và yêu cầu non-color cue. Nội dung icon,
message và business verdict vẫn thuộc product widget. Không tạo
`MxFeedbackCard` chỉ để forward một tone vào `MxCard`.

## Phase 4 — migrate toàn bộ production MxCard call-site

Migrate atomically mọi call-site đã inventory. Sau migration:

- không còn legacy unnamed `MxCard(...)` nếu API cuối dùng named constructors;
- không feature truyền visual primitive vào card family;
- không nested raised-on-raised shadow stack;
- flat list/card decisions đã được ghi trong design parity không tự nhiên đổi
  thành shadow chỉ vì constructor mới có default khác;
- child seated on card edge vẫn clip đúng;
- onTap, onLongPress, tri-state selection, nested menu, focus và semantics giữ
  nguyên;
- không đổi callback, provider, controller, navigation, copy hoặc business data.

Một visual delta chỉ được chấp nhận nếu nó là kết quả trực tiếp của recipe đã
owner-approved trong task này. Ghi before/after và screen affected vào WBS/design
parity; không gọi toàn bộ golden churn là “expected”.

## Phase 5 — harden MxActionButton, không viết lại

Giữ các public capability hiện có và coi M99.74/M99.75 là regression baseline:

- variants `primary`, `tonal`, `secondary`, `destructive`;
- sizes `standard`, `compact`;
- label, optional icon, loading, fixed geometry, semantic label và autofocus;
- loading-label opt-in đã có use case thật.
- secondary edge phải tiếp tục dùng `borderControl` ở rest/loading; touch-mode
  autofocus không được vẽ keyboard focus ring; `MxButtonPair` giữ rule một hàng
  trừ khi longest word thật sự không vừa.

Không thêm success/warning/color button hoặc raw size/style/padding props. Chỉ
sửa implementation khi state-matrix test tái hiện một defect thật.

Hoàn thiện table-driven state specification cho từng variant:

- rest;
- hover;
- pressed;
- keyboard focus-visible;
- disabled;
- loading.

Cover light, dark, high-contrast light và high-contrast dark. Kiểm fill, ink,
edge/focus indicator, geometry, enabled semantics và contrast trên ground thật.
Loading phải giữ width/height/alignment, chặn interaction, giữ accessible name,
announce busy và dùng foreground spinner đọc được trên đúng fill. Compact phải
vẽ 40 nhưng target vẫn tối thiểu 48.

Button icon tiếp tục do `MxActionButton` sở hữu size, gap, RTL order, disabled
ink, loading replacement và alignment. Feature chỉ truyền `IconData`.

## Phase 6 — static API và composition guards

Dùng `package:analyzer` hoặc structural Dart test đã có tiền lệ trong repo để
kiểm public constructor/field types. Guard phải fail nếu foundation surface/action
API expose một trong các visual primitive sau mà không có exception được ghi rõ:

- `Color`, `TextStyle`, `ButtonStyle`;
- `ShapeBorder`, `BorderSide`, `BoxShadow`, `Decoration`;
- `EdgeInsets`/`EdgeInsetsGeometry`;
- raw radius/elevation/height/icon-size `double` parameters.

Guard chỉ xét public API, không cấm private implementation dùng Flutter types.
Không regex source đơn giản nếu alias/generic/typedef có thể lọt.

Raw `InkWell` trong features đã được guard hiện hành cấm; không thêm duplicate
rule. Bổ sung structural finding hẹp cho `GestureDetector` dùng như button-like
wrapper quanh `MxCard`/card family trong feature. Không cấm mọi
`GestureDetector`: swipe, drag hoặc gesture không phải activation vẫn hợp lệ.

Add negative fixtures/fault injection:

- thêm public `Color? color` vào probe component phải fail;
- thêm public `EdgeInsets padding` phải fail;
- private `Color`/`ButtonStyle` implementation vẫn pass;
- `GestureDetector(child: MxCard...)` button-like fail;
- legitimate non-card swipe/drag gesture pass;
- scanner target count 0 phải fail, không pass rỗng.

## Phase 7 — tests, Widgetbook và visual evidence

### MxCard family

Tối thiểu cover:

- từng legal recipe ở light/dark/high contrast;
- padding none/compact/standard ở boundary cases, không full Cartesian product;
- informational và interactive card;
- hover, pressed, keyboard focus-visible, pointer focus behavior;
- tap-only, long-press-only và tap + long-press;
- nested icon/menu button;
- minimum touch target;
- clipping và no geometry shift;
- flat/nested-surface và raised/focal hierarchy theo các recipe thực tế được
  chốt từ inventory;
- tri-state selection trên flat/raised representatives, gồm selected treatment
  nào được inventory chấp thuận;
- feedback recipe (nếu được tạo) với tone, non-color cue và contrast;
- width 320/393/412, text scale 1.0/2.0, Vietnamese, Korean, RTL where the
  component contains directional icon/text composition.

### MxActionButton

Tạo pairwise/boundary matrix, không tạo Cartesian explosion:

- four variants;
- standard/compact;
- rest/hover/press/focus/disabled/loading;
- icon + label;
- short/long Vietnamese/Korean label;
- light/dark/high contrast;
- text scale 2.0 và narrow width.

Goldens chỉ dùng deterministic states. Loading animation được pin bằng behavior,
semantics và settled frame/harness phù hợp; không bắt một frame spinner ngẫu nhiên.

Mở rộng Widgetbook/component gallery với dedicated specimens để owner quan sát
legal recipes và action variants. Không tạo `MxText` chỉ để tier table đối xứng.
`MxIcon` chỉ dùng cho standalone semantic icon; raw `Icon` trong themed slots vẫn
hợp lệ theo contract hiện tại.

### Production regression

Chạy targeted tests cho toàn bộ feature có MxCard visual delta. Test phải assert
observable text/semantics/action/geometry; không tìm raw Material type như một
implementation contract. Giữ các golden production screen quan trọng để phát
hiện thay đổi hierarchy toàn app.

## Files/layers dự kiến

Được sửa khi cần:

- `lib/shared/widgets/mx_card.dart`;
- `lib/shared/widgets/mx_action_button.dart` — chỉ defect/evidence-driven;
- shared semantic card recipe/treatment files mới chỉ khi cần và theo naming
  contract; không thêm `MxChoiceCard`/`MxFeedbackCard` forwarding wrapper;
- production feature presentation call-sites dùng card family;
- `lib/core/theme/**` chỉ khi recipe/state mapping cần một semantic/component
  token thật, không mint token trùng nghĩa;
- related shared/feature/widget/golden/visual-audit tests;
- `widgetbook/**` component specimens;
- `code-verification-guard-v2/**` và structural boundary test;
- `.claude/skills/flutter-theme-design/**` nếu contract cuối khác target prose
  hiện tại;
- `docs/architecture.md`, `docs/reviews/design-parity-checklist.md`, `docs/wbs.md`.

Không sửa domain/data/DB/BR/UC/generated files vì task không đổi nghiệp vụ.

## Verification và delivery

Inner loop:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Sau recursive auto-fix và sync/rebase với `origin/main`, chạy full gate:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator IT: đây là shared presentation/design-system refactor, không
thêm device-only flow. PR phải ghi rõ emulator status thay vì ngụ ý đã chạy.

Vì thay đổi user-visible trên nhiều màn, bắt buộc:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Không chấp nhận golden chỉ vì vừa update. Inspect state-by-state, publish lại
đúng existing Artifact URL trong `CLAUDE.md`, đưa URL cho user confirm.

## Clean stop

Chỉ dừng clean khi:

- `MxCard` public API chỉ còn semantic recipe/content/behavior, không visual
  primitive escape;
- all production call-sites được phân loại và migrate, inventory không còn
  unknown;
- tri-state selection vẫn có đúng một owner; semantic treatments có closed
  policy thật và không sinh forwarding wrapper/god flags;
- MxActionButton giữ behavior và pass complete boundary state matrix;
- static API/composition fault injection chứng minh fail/pass hai chiều;
- production behavior, focus, gestures, semantics và geometry không regress;
- changed gate, full gate và required goldens xanh;
- gallery existing URL được republish để owner confirm;
- branch được commit/push và tạo non-draft PR ready cho user merge, kèm hai
  recursive review reports, gate, emulator status và gallery URL;
- không merge PR nếu execution session không được user yêu cầu rõ.
