# Implement Strict Design-System Widget Boundary Enforcement

| | |
|---|---|
| **Status** | active |
| **Purpose** | Xoá ratchet tạm, bật strict boundary và admission enforcement sau khi raw policy-widget migration đã sạch |
| **Scope** | Final registry audit, zero-baseline enforcement, shared admission rules, guard/CI tests, docs/WBS và cleanup; không redesign production UI |
| **Source of truth for** | Hướng dẫn bật strict design-system boundary; quyết định chính thức thuộc AD design-system boundary |
| **Depends on** | Foundation và migration PR đã merge, AD boundary, resolved guard, component registry, full shared-widget/test/Widgetbook catalog |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Chỉ bắt đầu khi cả foundation và migration đã merge vào `origin/main`, rồi sync
worktree. Nếu exact baseline vẫn còn `mxRequired` occurrence, dừng và sửa ở
migration scope trước; không bật strict với ignore.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Ratchet chỉ cấm nợ mới, không phải invariant cuối. | Xoá baseline và fail mọi raw `mxRequired`. |
| 2 | Registry có thể stale khi Flutter thêm component hoặc code dùng alias mới. | Unknown resolved Material/Cupertino symbol luôn fail classification. |
| 3 | Agent có thể chữa fail bằng Mx wrapper rỗng. | Admission gate yêu cầu policy ownership và evidence tồn tại. |
| 4 | Heuristic trivial wrapper không đủ đáng tin để tự động kết án. | Machine gate kiểm fact cấu trúc/evidence; recursive review kiểm semantic ownership. |
| 5 | Local clean nhưng CI không gọi cùng mode sẽ tái mở lỗ. | Fault-inject và assert strict parity ở one local/CI gate. |

## Preconditions

Chứng minh trước khi sửa:

- resolved inventory không có raw `mxRequired` ngoài baseline;
- baseline đã về rỗng sau migration;
- mọi `themeOwnedRaw` có rationale, allowed args và ThemeData state coverage;
- không raw Cupertino trong feature;
- mọi public Mx type có admission entry và evidence path thật.

Nếu một điều sai, không nâng baseline và không đổi disposition cho tiện.

## Strict mode

- Xoá temporary baseline file/code path hoặc biến strict zero-baseline thành mode
  duy nhất; không để flag production có thể tắt boundary.
- Raw constructor/top-level function disposition `mxRequired` fail ngay.
- Unclassified Material/Cupertino symbol fail ngay, kể cả framework update thêm
  symbol mới.
- `themeOwnedRaw` chỉ pass với approved named args; local visual override fail.
- Base/layout primitives vẫn pass; không mở rộng guard thành “cấm mọi Flutter”.
- Scanner target count, resolution error và registry parse error đều fail closed.

## Admission enforcement

Machine-check:

- public shared Mx type/file phải registered;
- closed `owns` vocabulary có ít nhất một category;
- evidence path tồn tại và đúng loại component/state;
- interactive component có accessibility/tap target behavior evidence;
- visual component có Widgetbook/golden evidence;
- raw backing chỉ xuất hiện trong shared implementation hoặc approved
  `themeOwnedRaw` feature usage;
- shared API không expose raw styling knobs bị architecture cấm.

Rà rule shared-widget hiện có ở các ruleset cũ của vendored guard chỉ như nguồn
tham khảo. Port tối thiểu rule đúng với layout v7; không import nguyên ruleset
v4/memox và không dùng scope cũ. Fault-inject để chứng minh mọi scope v7 có target.

Trivial-wrapper heuristic MAY tạo actionable diagnostic khi wrapper chỉ có một
raw child và forward gần hết constructor, nhưng không được sole blocking proof.
Blocking finding phải dựa trên thiếu declared policy/evidence hoặc API raw-style
leak; recursive review sẽ xử lý semantic falsehood.

## Cleanup and docs

- Update AD consequence nếu implementation strict mode làm rõ chi tiết, không
  đổi quyết định đã accepted.
- Mark WBS foundation/migration/enforcement đúng trạng thái và ghi final counts:
  `mxRequired raw = 0`, Cupertino raw = 0, theme-owned raw by symbol.
- Update guard README/rule catalog và CI comments; không chép registry list vào
  nhiều docs.
- Gỡ temporary migration comments, dead helpers, unused variants và component
  không còn caller.

## Fault injection

Strict suite phải chứng minh:

- raw Material default/named/generic/alias constructor fail;
- top-level Material picker/dialog function fail;
- raw Cupertino fail;
- new unclassified Material symbol fail;
- theme-owned raw visual override fail nhưng content/behavior args pass;
- Row/Text/Icon/Container tokenized pass;
- locally-defined homonym pass;
- unregistered/empty-policy/fake-evidence Mx component fail;
- wrong v7 scope or zero targets fail;
- local `dod_check.sh` và CI invoke cùng strict behavior.

## Verification and delivery

Chạy changed gate trong loop và full `.claude/skills/flutter-workflow/scripts/dod_check.sh`
sau sync `origin/main`. Không chạy emulator vì strict tooling cleanup không thêm
device flow. Nếu production UI không đổi, không regenerate gallery; link existing
Artifact và ghi explicit no-visual-delta. Nếu auto-fix buộc đổi shared/feature
rendering, chuyển phần đó về migration scope, chạy golden/gallery đầy đủ trước khi
tiếp tục strict phase.

## Clean stop

Chỉ clean khi baseline mechanism không còn, strict fault injection xanh, raw
`mxRequired` và Cupertino bằng 0, theme-owned raw được chứng minh, admission gate
không pass rỗng, docs/WBS đồng bộ, full gate xanh, branch push và non-draft PR
ready. Không merge nếu user không yêu cầu execution session.
