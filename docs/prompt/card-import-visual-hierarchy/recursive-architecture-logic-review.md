# Recursive Architecture and Logic Review — Card Import Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập audit và auto-fix mọi regression nghiệp vụ, state, navigation và component ownership sau khi nâng cấp Card Import presentation |
| **Scope** | Card Import screen/widgets, eight-phase derivation, shell/footer migration, callbacks, provider/controller boundaries, tests và tài liệu parity; không redesign UI |
| **Source of truth for** | Quy trình recursive architecture/logic review của Card Import visual hierarchy |
| **Depends on** | `implementation.md`, latest worktree, BR-168…BR-173, UC-10, wireframe M4.12, architecture docs và current Card Import tests |
| **Updated by task** | Card Import visual hierarchy prompt set |
| **Last updated** | 2026-08-27 |

---

Bạn là reviewer độc lập. Bắt đầu sau implementation. Re-read latest worktree;
không dùng implementation report hoặc golden vừa update làm bằng chứng. Audit,
tái hiện, auto-fix in-scope findings và lặp đến clean stop.

Audit-only có thể chạy song song với UI reviewer, nhưng hai reviewer không sửa
shared worktree đồng thời. Coordinator áp architecture fixes trước; UI reviewer
phải re-read sau đó.

## 5Why audit

| Why | Rủi ro | Quyết định review |
|---|---|---|
| 1 | Migrate raw Scaffold sang `MxContentShell` có thể làm Close/PopScope/footer hoạt động khác dù ảnh đẹp hơn. | Reproduce navigation và draft lifecycle theo từng phase. |
| 2 | Gom widgets vào panels có thể vô tình chuyển/refactor provider reads, bắt parse sớm hoặc mất paste/file state. | Trace mỗi callback và provider ownership trước/sau. |
| 3 | Footer chuyển sang `MxButtonPair` có thể đảo action order, enablement hoặc dispatch hai lần. | Pin exact action matrix và command count cho mọi phase. |
| 4 | Parsing/submitting skeleton có thể hiển thị body của phase khác vì step và async state cập nhật khác frame. | Audit duy nhất `deriveCardImportPhase` sở hữu face; không tạo derived boolean thứ hai. |
| 5 | UI-only PR có thể chạm parser/repository để làm dữ liệu demo vừa layout. | Reject mọi domain/data/persistence drift và fixture code đi vào production. |

## Pass 1 — source of truth và diff scope

1. Đọc `CLAUDE.md`, document conventions, BR-168…BR-173, UC-10, M4.12 và
   relevant architecture decisions.
2. So diff với `origin/main`; liệt kê mọi file ngoài presentation/tests/
   Widgetbook/docs visual scope.
3. Re-run production state/widget inventory độc lập; fail nếu thiếu một phase,
   action hoặc outcome.
4. Xác nhận không route name/path, ARB meaning, parser, repository, DAO, schema,
   use case, transaction hoặc generated file nào đổi.
5. Nếu prompt implementation và canonical docs khác nhau, docs thắng; không sửa
   test để hợp thức hoá implementation drift.

## Pass 2 — phase/state ownership

Audit `CardImportStep`, parse state, preview state và submit state →
`CardImportPhase`:

- body, stepper, title và footer cùng đọc một phase;
- parse không bắt đầu ở Source và paste chỉ được commit vào provider khi Preview;
- source-ready earned check không bị style state thay thế;
- Preview earned check vẫn yêu cầu document + valid mapping + importable > 0;
- outcome ẩn context; reset quay Source và giữ deck target;
- commitFailure giữ source/mapping/preview và retry đúng retained plan;
- completedWithSkips/noCardsAdded chọn đúng counts và reason;
- no async operation bị khởi động từ `build()`;
- no controller/provider được nhân đôi chỉ để phục vụ layout.

Tạo hoặc giữ table-driven test map từ phase sang title/context/body/footer
actions. Một phase thiếu evidence là finding, không phải “covered indirectly”.

## Pass 3 — navigation và draft lifecycle

Reproduce ít nhất:

- Close/Android Back ở Source sạch rời ngay;
- dirty Source hỏi discard;
- Back Preview/Confirm giữ source, paste, mapping và duplicate policy;
- picker cancel giữ file cũ và không báo lỗi;
- parsing Back hoạt động theo contract;
- submitting khoá Close/system Back/Back/submit lần hai;
- complete Close/Back rời không hỏi;
- failure Close/Back hỏi discard; Back to preview giữ draft;
- Import another reset toàn draft + paste controller nhưng giữ deck;
- View cards dùng existing route và stream, không reload thủ công.

Shell migration không được tạo `SafeArea`/footer/inset owner thứ hai. PopScope
phải bao toàn shell và không bị một nested Navigator/action bar né qua.

## Pass 4 — callback, persistence và failure parity

Với từng action, so exact callback/provider command trước/sau:

- source choose/upload/paste/remove/replace;
- header/sheet/mapping/duplicate choices;
- Preview/Back/Continue/Import;
- retry/back-to-preview/reset/view-cards;
- discard confirmation.

Mỗi tap dispatch tối đa một command. Loading/disabled state phải chặn duplicate
submit bằng controller contract hiện hữu, không bằng local boolean mới.

Audit persistence invariants:

- one atomic batch commit;
- failure rollback toàn bộ;
- deck `content_type` behavior giữ BR-172;
- imported cards nhận fresh study state như BR-171;
- no partial progress UI hoặc per-row DB update;
- source/card/file content không bị log;
- error UI chỉ render typed sanitized failure.

Không sửa persistence trong task. Nếu behavior test tái hiện bug có thật ngoài
scope, ghi blocker/task riêng.

## Pass 5 — shared component boundary

Kiểm:

- `MxContentShell` thực sự sở hữu app bar/subheader/footer/keyboard seam;
- feature không dựng một shell/scaffold wrapper song song;
- two-action states dùng `MxButtonPair` nếu latest contract yêu cầu;
- `MxCard`/`MxIcon`/`MxActionButton` dùng legal API mới nhất;
- không raw Material policy widget hoặc raw visual primitive bị guard cấm;
- không shared component mới chỉ forward params;
- feature-only grouping ở đúng `sections/items/overlays/support` bucket;
- tests assert outcomes/semantics/geometry, không raw Flutter class khi không
  phải contract.

## Recursive auto-fix loop

Với mỗi finding:

1. Ghi severity, exact file/phase/reproduction và violated BR/UC/W rule.
2. Viết failing test trước nếu chưa có evidence.
3. Sửa nhỏ nhất tại owner đúng layer.
4. Chạy targeted changed gate.
5. Re-run phase/action matrix và các consumers bị ảnh hưởng.
6. Lặp đến hai vòng liên tiếp không có finding mới.

Không tự đổi business behavior, copy meaning hoặc route để chữa layout.

## Verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Reviewer không claim full pass; coordinator chạy full gate sau UI pass. Chỉ trả
clean khi:

- đủ mọi phase/action/outcome trong independent matrix;
- navigation, draft, parse, mapping, commit, retry/reset giữ parity;
- no domain/data/persistence/privacy drift;
- shell/footer chỉ có một owner cho safe area/keyboard/scroll;
- no duplicate command hoặc hidden async work;
- targeted gate xanh;
- report liệt kê test/fix/risk cụ thể, không blanket `pass`.
