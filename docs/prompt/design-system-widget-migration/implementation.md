# Implement Design-System Policy Widget Migration

| | |
|---|---|
| **Status** | active |
| **Purpose** | Rút toàn bộ exact baseline `mxRequired` bằng cách tái dùng hoặc bổ sung MemoX shared components có policy thật, không đổi nghiệp vụ |
| **Scope** | Production feature presentation call-sites, shared Mx components tối thiểu, tests/Widgetbook/goldens, baseline shrink và WBS; không bật final strict mode |
| **Source of truth for** | Hướng dẫn migration raw policy widgets; behavior chính thức vẫn thuộc BR/UC/wireframe của từng screen và AD design-system boundary |
| **Depends on** | Foundation PR đã merge, AD design-system boundary, `tool/design_system_policy.*`, exact baseline, MemoX shared widgets, feature wireframes và gallery hiện hành |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Chỉ bắt đầu sau khi foundation PR đã merge vào `origin/main`. Rebase/sync worktree
trước khi inventory. Đây là architecture migration với visual parity, không phải
cơ hội redesign hoặc đổi business flow.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Foundation chỉ chặn nợ mới; exact baseline vẫn chứa raw call-site. | Drain baseline theo resolved inventory. |
| 2 | Một PR tuần tự sửa hơn bốn chục call-site dễ overload. | Chia ba workstream có file ownership rời và cho phép chạy song song dưới một coordinator. |
| 3 | Mỗi raw class không tương ứng một Mx class; thay tên máy móc sinh wrapper rác. | Migrate theo user intent/policy family, ưu tiên extend component hiện có. |
| 4 | Shared migration có thể âm thầm đổi pixel, semantics hoặc behavior. | Pin parity bằng feature tests, geometry, accessibility, goldens và Widgetbook. |
| 5 | Ba worker cùng sửa catalog/registry/WBS sẽ xung đột. | Coordinator giữ exclusive ownership của integration files và thu baseline sau cùng. |

## Coordination và ownership

User cho phép parallel implementation trong prompt này. Coordinator MAY spawn
tối đa ba worker/subagent, nhưng phải giao file ownership rõ và nhắc không revert
thay đổi của nhau.

### Workstream A — actions, forms, selection, chips and menus

Sở hữu các baseline occurrence thuộc action/button, text input, dropdown,
radio/switch/checkbox, chip và popup/menu. Ưu tiên:

- `MxActionButton`, `MxTextButton`, `MxIconButton`, `MxTextField`,
  `MxPillButton` hoặc shared equivalent hiện có;
- một app-specific shared component mới chỉ khi nó sở hữu variant/state/a11y/
  responsive/theme/composition policy thật;
- giữ nguyên enablement, validation, callbacks, focus, keyboard submit, selected
  state, tooltip và destructive semantics.

### Workstream B — feedback, overlay and picker

Sở hữu snackbar, progress/loading, dialog/sheet và date/time picker occurrences.
Phân biệt:

- full-state loading với inline glyph/submitting indicator;
- undo snackbar với success/error informational feedback;
- confirm dialog với simple information dialog;
- picker helper/API với raw control.

Không ép `MxLoadingState` vào footprint inline sai geometry. Nếu cần shared
inline indicator hoặc feedback helper, nó phải sở hữu size/semantic/theme policy
và có evidence riêng.

### Workstream C — shell, surface and interaction

Sở hữu raw Scaffold/AppBar/navigation shell, ListTile/surface, Divider và
InkWell/InkResponse occurrences được registry đánh `mxRequired`.

- ưu tiên `MxContentShell`, `MxCard`, `MxListTile`, `MxNavigationBar`;
- giữ gesture arena, nested control behavior, focus ring, hover/pressed overlay,
  clipping và target semantics;
- raw `GestureDetector` không tự động là cách chữa InkWell; chỉ dùng khi gesture
  không phải button-like action hoặc đã có đúng Semantics/focus/keyboard path.

### Coordinator-only files

Workers MUST NOT cùng sửa:

- `tool/design_system_policy.*` và exact baseline;
- `docs/architecture.md`, `docs/wbs.md`, `CLAUDE.md`;
- `.claude/**`, `.github/**`;
- shared stress specimen aggregator;
- Widgetbook root/catalog registration;
- central golden specimen registries.

Coordinator re-read latest worktree, tích hợp các shared entries/evidence, giải
conflict và shrink baseline một lần sau khi ba workstream xong. Parallel workers
không chạy auto-fix trên shared worktree cùng lúc.

## Migration rules

1. Chạy resolved guard để lấy baseline mới nhất; source mới nhất thắng con số
   nêu trong nhận xét cũ.
2. Chỉ migrate occurrence `mxRequired`. Giữ `themeOwnedRaw` nếu nó thật sự không
   override policy; không tạo wrapper để đạt “zero raw Material” giả tạo.
3. Nếu Mx equivalent có sẵn, dùng nó và không mở API bằng raw Color/TextStyle/
   radius/padding/style object.
4. Nếu thiếu capability lặp lại, mở shared component bằng closed semantic
   variant/slot/callback nhỏ nhất. Không forward toàn bộ Material constructor.
5. Shared component mới phải được admission registry nhận, có stress,
   accessibility, behavior, light/dark golden và Widgetbook evidence đúng loại.
6. Feature-specific composition vẫn ở đúng bucket `sections/items/overlays/support`;
   không đẩy domain widget vào shared.
7. Không thêm business logic, provider read, navigation hoặc ARB default vào
   shared widget.
8. Không sửa generated files.

## Behavior and visual parity

Giữ nguyên mọi:

- business data, controller/use case/repository call;
- visibility, enablement, selected/loading/error state;
- navigation/back/cancel/confirmation;
- localization copy;
- ordering và semantic grouping của screen.

Visual mặc định phải pixel-neutral nếu shared equivalent đã tồn tại. Một delta
chỉ được chấp nhận khi nó sửa đúng shared design-system contract đã có (ví dụ
touch target/focus ring/theme state), phải nêu trước/sau, test observable outcome
và được UI review duyệt. Không lợi dụng migration để đổi layout/hierarchy.

## Tests theo workstream

Mỗi raw occurrence family cần ít nhất một negative regression test chứng minh
feature không còn instantiate raw symbol, cộng behavior test ở production tree.

Tối thiểu kiểm:

- enabled/disabled/loading và double-tap của actions;
- focus, keyboard submit, validation và controller retention của input;
- radio/switch/checkbox selected + semantics;
- menu open/select/dismiss;
- snackbar/dialog/picker success, cancel và failure;
- inline/full loading geometry;
- card/list/surface nested controls, keyboard/focus and tap targets;
- 320 width, text scale 2.0, light/dark;
- exact baseline giảm đúng và không có occurrence mới.

Không thay test finder bằng raw Material type sau migration; finder phải nhắm
Mx API hoặc user-observable semantics/copy để test không kéo ngược boundary.

## Docs và evidence

- Update `docs/wbs.md` bằng inventory ban đầu, disposition giữ lại, component
  được reuse/added, visual divergences được duyệt và baseline còn lại.
- Không sửa BR/UC nếu behavior không đổi.
- Nếu registry lộ một Architecture Decision chưa đủ, dừng và báo; không âm thầm
  rewrite AD foundation.

## Verification

Trong inner loop chạy changed gate. Sau integration và sync `origin/main`, chạy
full `.claude/skills/flutter-workflow/scripts/dod_check.sh`.

Đây không phải feature/business flow mới nên không yêu cầu emulator integration
suite; PR phải ghi rõ emulator `not run — presentation architecture migration,
no new device-only flow`.

Vì production UI/shared components có thể đổi, coordinator MUST:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Sau đó inspect state-by-state, publish lại **existing** gallery Artifact URL,
không tạo URL thứ hai.

## Clean stop

Chỉ clean khi:

- mọi `mxRequired` occurrence trong scope migration đã rời feature raw calls;
- `themeOwnedRaw` còn lại có rationale và không visual override;
- baseline được shrink đúng, không tăng/ignore;
- shared component mới sở hữu policy thật và đủ evidence;
- behavior/geometry/a11y/goldens sạch ở hai theme và responsive cases;
- full gate xanh;
- gallery được republish để user confirm;
- branch push và non-draft PR ready, nhưng không merge nếu user chưa yêu cầu execution session.
