# Recursive Architecture and Logic Review — MxCard and MxActionButton Foundation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập audit và auto-fix component boundary, API closure, interaction semantics và production behavior sau đợt MxCard/MxActionButton hardening |
| **Scope** | Shared component APIs/implementation, all migrated call-sites, design-system guard, tests, architecture/design-parity docs và delivery evidence; không redesign UI theo cảm tính |
| **Source of truth for** | Quy trình recursive architecture/logic review của MxCard/MxActionButton hardening |
| **Depends on** | `implementation.md`, latest `origin/main`, AD-14/design-system AD, current business/screen docs, flutter design/theme skills và production tests |
| **Updated by task** | MxCard/MxActionButton foundation prompt set |
| **Last updated** | 2026-08-27 |

---

Bạn là reviewer độc lập. Bắt đầu sau khi implementation phase đã hoàn tất. Re-read
worktree hiện tại; không dựa vào implementation report như bằng chứng. Review
phải tái hiện finding, auto-fix finding trong scope, chạy lại verification và lặp
đến clean-stop. Report-only không đủ.

Không sửa song song cùng UI reviewer. Trong workflow có subagents, hai reviewer
được phép chạy audit-only song song, nhưng coordinator áp fix architecture trước;
UI reviewer phải re-read worktree mới nhất trước khi áp fix của mình.

## 5Why audit

| Why | Rủi ro cần chứng minh | Quyết định review |
|---|---|---|
| 1 | Constructor có tên semantic nhưng private mapping vẫn bị caller override bằng escape hatch khác. | Audit public symbol/type resolution và mọi call-site, không chỉ tên parameter cũ. |
| 2 | Xoá visual props có thể làm callback, long-press, selected state hoặc nested control đổi hành vi. | Reproduce từng interaction family trên production tree. |
| 3 | M99.70 đã giao selection cho `MxCard`; implementation có thể vô tình tạo `MxChoiceCard`, đổi selected token hoặc làm mất tri-state semantics khi đóng API. | So với baseline đã owner-review; giữ một owner và loại forwarding wrapper. |
| 4 | M99.74/M99.75 đã sửa secondary/loading/focus và button-pair layout, nhưng một refactor foundation có thể làm quay lại đúng drift vừa đóng. | Pin các behavior mới bằng regression evidence trước khi audit phần state matrix còn thiếu. |
| 5 | Guard có thể pass rỗng, chỉ match regex hoặc cấm legitimate GestureDetector. | Fault-inject positive/negative fixtures và kiểm resolved diagnostics. |

## Audit pass 1 — source-of-truth và diff scope

1. Sync/fetch metadata cần thiết nhưng không merge/rebase trong lúc audit nếu
   coordinator chưa cho phép.
2. Đọc `CLAUDE.md`, document conventions, AD-14/design-system AD, WBS M99.70,
   M99.74, M99.75, design parity C1/C4 và các screen rows liên quan.
3. So implementation diff với `origin/main`; liệt kê mọi file ngoài scope.
4. Xác nhận không domain/data/repository/controller/business rule/navigation/copy
   nào đổi. Nếu có, tái hiện lý do; revert in-scope accidental drift hoặc báo
   blocker nếu behavior change là bắt buộc.
5. Re-run inventory độc lập từ source. So count/classification với implementation
   inventory; fail nếu unknown, zero target hoặc stale path.

## Audit pass 2 — public API closure

Inspect resolved public constructors/fields của:

- `MxCard`;
- `MxActionButton`;
- bất kỳ shared surface/action component mới nào task thêm.

Fail và auto-fix nếu public API expose:

- raw color/style/shape/border/shadow/decoration;
- `EdgeInsets` internal padding;
- arbitrary radius/elevation/height/icon-size;
- callback/slot chỉ forward Material API mà không có product use case;
- independent flags tạo invalid visual combinations;
- product/domain enum/entity trong shared component.

Named recipe phải map một-một vào private immutable spec. Không cho caller truy
cập spec hoặc ghép `variant × tone` tự do. Existing `flat`/tri-state
`isSelected` phải tiếp tục đúng contract M99.70. `MxCardPadding` chỉ chứa steps
có real callers và token mapping.

Run fault-injection test: temporary probe thêm `Color?`, `EdgeInsetsGeometry` và
raw `double elevation` phải bị guard bắt; private implementation types phải pass.
Remove probe sau test.

## Audit pass 3 — component responsibility

### MxCard

Xác minh từng recipe sở hữu đầy đủ:

- ground/fill role;
- border;
- radius;
- elevation/shadow;
- clip;
- padding mapping;
- applicable interaction states.

Không recipe nào được đặt tên theo feature như `study`, `deck`, `cardDetail`.
Không nested raised-on-raised mặc định. Surface tint/shadow phải theo AD-14 và
high-contrast theme, không hardcode.

### Interactive card

Tái hiện trên production hoặc focused harness:

- tap-only;
- long-press-only;
- tap + long-press;
- nested trailing button/menu;
- keyboard Enter/Space activation;
- hover/press/focus-visible;
- pointer focus không để keyboard ring sai;
- minimum 48×48;
- no layout/size shift;
- semantics role/name/action/selected state không bị duplicate.

Đặc biệt kiểm nhánh `onLongPress != null && onTap == null`; nếu callback không
thể reach, đó là defect. Không chữa bằng wrapper `GestureDetector` ở feature.

### Selection và semantic treatments

Fail nếu implementation tạo `MxChoiceCard` để sở hữu lại policy mà
`MxCard.isSelected` vừa nhận ở M99.70. Audit đủ `null/false/true`, selected edge,
focus precedence, selected fill treatments và non-tappable semantics. Closed
muted/accent/feedback recipe chỉ hợp lệ khi có real callers và sở hữu mapping
semantic; một class/factory chỉ forward tone hoặc đổi tên `MxCard` phải bị xoá.

### MxActionButton

Giữ nguyên four variants/two sizes/loading semantics. Kiểm:

- no new raw style knobs;
- primary/tonal/secondary/destructive đều có explicit resting, hover, pressed,
  focused, disabled và loading behavior;
- focus indicator có contrast trên actual fill;
- disabled/loading không trông armed;
- loading giữ geometry và chặn duplicate submit;
- standard/compact typography, icon size/gap và target đúng;
- semanticLabel override không làm mất button role/enabled/busy state.
- secondary rest/loading giữ `borderControl`; autofocus chỉ vẽ focus ring trong
  keyboard highlight mode; button pair giữ một hàng khi longest word còn vừa và
  chỉ stack ở boundary đã chốt.

Không refactor implementation chỉ để đồng dạng nếu observable contract đã đúng.

## Audit pass 4 — production call-site parity

Với từng migrated call-site, so trước/sau:

- callback và conditional enablement;
- selected/error/loading/empty state;
- onTap/onLongPress/nested control;
- navigation/back/dialog behavior;
- displayed data và localized copy;
- layout ownership: external gap thuộc feature, internal component padding thuộc
  shared component;
- recipe ground hợp lệ.

Audit persistence và failure handling theo nguyên tắc **không đổi**:

- shared card/button không được import repository, DAO, use case, provider hoặc
  tự khởi tạo async/persistence operation;
- callback vẫn được feature/controller sở hữu và mỗi tap chỉ dispatch đúng một
  command như trước;
- loading/error/retry/undo state từ controller vẫn map đúng vào enablement,
  feedback surface và action label;
- migration không swallow failure, đổi failure thành generic UI state, thêm
  retry ngầm hoặc làm mất user-visible error path;
- không DB/schema/migration/query nào đổi. Nếu diff chạm persistence, coi là
  scope violation trừ khi chứng minh đó chỉ là unrelated pre-existing change và
  không được include trong PR này.

Fail nếu migration dùng `MxCard.focal` chỉ để lấy radius, dùng feedback tone chỉ
để lấy màu, hoặc biến informational card thành semantics button.

Production tests không được phụ thuộc raw `Card`/`FilledButton` type nếu outcome
có thể assert qua Mx API, semantics, text, callback hoặc geometry.

## Audit pass 5 — guard và evidence integrity

Kiểm:

- raw `InkWell` rule hiện có không bị duplicate;
- GestureDetector rule structural và chỉ bắt button-like MxCard wrapping;
- aliases, multiline constructor và nested tree được nhận;
- comment/string/local class không false-positive;
- scan zero target fail;
- API guard resolve public types, không source-regex mong manh;
- shared component admission/Widgetbook/test evidence path tồn tại;
- no allowlist wildcard hoặc per-file waiver không có expiry/rationale.

Fault-inject cả true positive và true negative rồi xoá fixtures tạm.

## Auto-fix loop

Cho mỗi finding:

1. Ghi severity, exact file:line, reproduction và violated contract.
2. Viết failing test/probe trước khi sửa nếu chưa có evidence.
3. Apply smallest fix trong scope.
4. Chạy targeted verification bằng repository entry, không loose commands.
5. Re-run independent inventory và pass liên quan.
6. Lặp đến khi không còn finding mới hai vòng liên tiếp.

Nếu fix cần đổi BR/UC/product behavior, dừng và báo blocker; không tự quyết.

## Verification

Inner loop:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Sau mọi auto-fix, chạy targeted tests của card/button/guard và production
consumers qua plan; coordinator sẽ chạy full gate sau UI pass. Reviewer không
claim full pass nếu chỉ targeted tests xanh.

## Clean stop

Chỉ trả clean khi:

- independent inventory ánh xạ mọi call-site, không unknown/zero/stale;
- public API closure guard pass và fault injection bắn đúng hai chiều;
- no business/navigation/data drift;
- all card interaction paths và button state matrix có automated evidence;
- selection có đúng một owner; mọi semantic treatment mới sở hữu policy thật,
  không trivial/god wrapper;
- targeted changed gate xanh;
- report liệt kê findings đã auto-fix, tests đã chạy và residual risks thực sự,
  không ghi blanket `pass` thiếu bằng chứng.
