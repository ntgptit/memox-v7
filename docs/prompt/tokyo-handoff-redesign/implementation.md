# Tokyo handoff redesign — execution coordinator

| | |
|---|---|
| **Status** | active |
| **Purpose** | Điều phối thực thi plan redesign theo handoff Tokyo qua tám phase — mỗi phase một PR, có hai recursive audit độc lập và auto-fix trước khi merge `main` |
| **Scope** | Phase 0–7, Task 1–38 của `docs/superpowers/plans/2026-09-13-tokyo-handoff-redesign.md`: token, component theme, shared widget, composition của feature, test, golden, gallery, docs và WBS mà plan nêu. Không đổi nghiệp vụ, schema, query hay migration |
| **Source of truth for** | Cách chạy plan redesign Tokyo. Giá trị thiết kế thuộc `memox-flutter-handoff.json`; luật nghiệp vụ thuộc BR/AD/UC; quyết định của chủ dự án thuộc plan (Owner decisions, Decision log) và `docs/design-system/tokyo-component-mapping.md` §9 |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, `docs/design-system/v1-freeze.md` §3c, `docs/design-system/tokyo-component-mapping.md`, `docs/business-rules.md` (BR-88), `docs/architecture.md` (AD-12, AD-13, AD-15, AD-18, AD-23), plan và handoff JSON |
| **Updated by task** | Tokyo handoff redesign execution prompt |
| **Last updated** | 2026-09-13 |

---

Bạn là **coordinator** thực thi redesign Tokyo cho `memox-v7`. Bạn tự làm mọi
task (sửa code → chạy test → sửa tiếp) trong main loop; subagent chỉ dùng để
**audit**. File này là entrypoint duy nhất. Hai file review cùng thư mục là hợp
đồng bạn giao cho hai subagent audit-only sau mỗi phase.

## 0. Đầu vào và tính toàn vẹn

Hai input nằm ngoài worktree đích cho tới khi Phase 0 merge:

| Input | Đường dẫn nguồn | SHA-256 |
|---|---|---|
| Plan | `D:\workspace\memox-v7\.claude\worktrees\slider-flutter-handoff-c367c4\docs\superpowers\plans\2026-09-13-tokyo-handoff-redesign.md` | `6e6a7049ba61a7b5499cc7aa2c05da1891bfcb3d00fd07b177119745deaa179c` |
| Handoff | `C:\Users\ntgpt\OneDrive\Desktop\memox-flutter-handoff.json` | `d151265999182941f3377a134f6d133848d8864740f61a847110e4de13cd7722` |

- Kiểm tra hash bằng `Get-FileHash -Algorithm SHA256` **trước khi đọc**. Thiếu
  file hoặc sai hash là blocker: dừng, không lấy file cùng tên ở chỗ khác.
- Sau khi Phase 0 merge, đọc hai file từ repo
  (`docs/superpowers/plans/2026-09-13-tokyo-handoff-redesign.md`,
  `docs/design-system/handoff/memox-flutter-handoff.json`). Phase sau có thể
  sửa plan để ghi deviation (§4.2); bản trong repo khi đó là bản đúng.
- Session cloud hoặc remote không đọc được hai đường dẫn trên. Nếu bạn chạy ở
  đó: dừng và báo chủ dự án, trừ khi hai file đã có trên `origin/main`.
- Plan đã được kiểm chứng read-only với `dcd22f32`: 38 agent (mỗi task một)
  cộng một agent kiểm nối giữa các task. Mọi P0/P1 đã được đối chiếu với code.
  Phần thật đã sửa vào plan: `RoleBinding` bắt buộc có `scope`/`because`, tên
  helper test thật, pin ở `m3_role_contract_test`, D26, D27, và việc Task 30 đảo
  M100.69. Phần còn lại là dương tính giả, do agent bỏ qua tên mà task trước tạo
  ra. Code có thể đã trôi từ `dcd22f32`; cách xử lý khác biệt ở §4.2.

## 1. 5Why bắt buộc

Trước lệnh đầu tiên làm đổi trạng thái, ghi 5Why vào work log. Mỗi Why cần bằng
chứng file:line lấy từ repo hiện tại, trade-off, và tiêu chí cho biết quyết định
là đúng.

| Why | Root cause cần chứng minh | Quyết định mở khoá |
|---|---|---|
| 1 | Palette đã đúng hex handoff từ M100.87 (`app_material_roles.dart`), mà app vẫn chưa giống kit | Vì type, geometry, state của component và nhịp bố cục còn theo V1. Phase 1 (foundations) phải đi trước mọi component |
| 2 | Không làm cả redesign trong một PR được | Mỗi đổi token làm đổi gần hết ~300 golden và dời hàng chục contract test. Một PR khổng lồ khiến regression không truy được về nguyên nhân. Mỗi phase một PR, chụp golden một lần |
| 3 | Plan tự nó chưa đủ | Code trong plan chưa từng compile, và symbol trôi khi PR khác merge. TDD cho từng task; fact của repo thắng câu chữ plan; deviation được ghi lại |
| 4 | Cần hai reviewer độc lập | Gate xanh chỉ chứng minh không gãy. Nó không chứng minh UI khớp handoff (chủ dự án từng bác một redesign xanh toàn bộ, 2026-08-29), cũng không chứng minh BR-88 hay `supportedActions` còn đúng |
| 5 | Implement trong main loop, không giao subagent | Đo ở M100.42: vòng sửa-test giao subagent trung bình 90–143 lượt, tốn 818M cache read, chất lượng không hơn (`.claude/workflows/README.md`) |

## 2. Preflight và worktree safety

1. Đọc `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`. Rồi đọc trong
   plan: Global Constraints, Owner decisions, Decision log, Handoff → code map,
   Phase → PR map, Procedures P1–P6.
2. Worktree đích phải sạch và tạo từ `origin/main`: `git status --short` rỗng,
   `git fetch origin --prune`, ghi baseline `git rev-parse origin/main`. Nếu
   worktree bẩn hoặc lệch base thì dừng, không reset thứ không phải của mình.
3. Mỗi phase `N` là một branch `claude/tokyo-redesign-phase-<N>`, tạo từ
   `origin/main` **sau khi** PR của phase trước in `MERGED`:
   `git fetch origin --prune && git switch -c claude/tokyo-redesign-phase-<N> origin/main`.
4. Sau mỗi lần switch hoặc pull có đụng ARB, pubspec hay `.drift`: chạy
   `flutter pub get` và `dart run build_runner build --delete-conflicting-outputs`.
   Kiểm môi trường bằng dòng tổng kết của `flutter analyze`, không đếm file `.g.dart`.
5. Không force-push. Không `git stash` trần. Không `git checkout -B main`.
   Không đụng checkout chính `D:/workspace/memox-v7` (nó giữ `main`). Không
   dùng chung clone WSL `~/memox-hardening`: mỗi branch một clone riêng (plan P4).
6. **Commit/push/PR/merge:** session này được phép commit từng task, push
   branch phase, mở PR non-draft, merge squash khi CI xanh, xác nhận `MERGED`,
   rồi xoá branch — đúng thứ tự plan P6. Không `--auto`, không `--admin`, không
   `--delete-branch`. Không xoá branch trước khi thấy `MERGED`.
7. WBS ID: lấy ID tạm `M100.xx` khi tạo branch và dùng nó trong commit. Fetch
   lại trước khi push. Nếu ID đã bị PR khác lấy, đổi ID trong nội dung file bằng
   một commit riêng. Tiêu đề PR mang ID cuối (squash merge dùng tiêu đề PR làm
   commit trên `main`).

## 3. Model, effort và subagent

| Việc | Ai làm | Model / effort |
|---|---|---|
| Implement task: test → code → test → commit | coordinator, main loop | model của session |
| Audit architecture/logic và audit UI/UX sau mỗi phase | hai subagent qua `Agent`, chạy song song, audit-only | `sonnet` (hook `enforce_subagent_model.py` ép) |
| Workflow (nếu thật sự cần fan-out để tìm hoặc phán xử) | coordinator viết script | mọi `agent()` pin `model: 'sonnet'` và `effort`; `meta.description` nêu spend. Floor ≥300k tok hoặc có fan-out thì hỏi chủ dự án bằng `AskUserQuestion` trước |

- Không chạy nguyên `.claude/workflows/review-verify.js`: stage VERIFY của nó
  pin `opus`, thứ `CLAUDE.md` cấm nếu chưa hỏi chủ dự án.
- Subagent không đọc được prompt chưa commit ở worktree nguồn. Dán **toàn văn**
  prompt review (lấy từ output của `read_local_prompt_set.ps1`) vào prompt của
  subagent, kèm biến ở §4.4. Ghi rõ ngân sách khoảng 30 tool call mỗi pass.

## 4. Vòng lặp bắt buộc cho mỗi phase N

### 4.1. Freeze đầu vào

- Đọc hết section Phase N của plan, và spec handoff của từng widget mà task
  trong phase nêu tên:
  `python -X utf8 -c "import json;d=json.load(open('<handoff>',encoding='utf-8'));print([w['spec'] for w in d['widgets'] if w['name']=='<Name>'][0])"`.
- Ghi `PHASE_BASE_SHA` = `origin/main` lúc tạo branch.
- Lập coverage checklist: mỗi task gồm Files, Interfaces/Produces, test phải
  có, và tài liệu phải sửa.

### 4.2. Implement từng task

- Làm task theo đúng thứ tự, step theo đúng plan: viết test fail → chạy và thấy
  fail **đúng lý do plan nói** → implement → test pass → `dart format` →
  `flutter analyze --no-fatal-infos` in `No issues found!` → commit bằng message
  của task.
- **Deviation:** khi plan lệch repo (tên, signature, helper, số dòng, API SDK),
  fact của repo thắng. Làm thay đổi nhỏ nhất vẫn giữ Interfaces/Produces của
  task. Ghi `PLAN-DEV-<task>.<k>` gồm: plan nói gì, repo có gì, đã làm gì. Nếu
  deviation đổi một tên mà task sau dùng, sửa plan trong cùng PR để phase sau
  đọc đúng.
- **Dừng và hỏi** (`AskUserQuestion`) khi thay đổi cần làm sẽ: đảo một owner
  decision; đổi mặc định của một D-id; đổi BR/AD/UC; thêm giá trị token không
  có trong handoff; hoặc đụng persistence (`lib/core/database`, `*.drift`,
  `data/`, migration).
- Contract đổi thì test/guard canh nó dời theo **trong cùng commit**. Xoá test,
  `exclude`, `skip` hay `enabled: false` để qua CI là cấm (`v1-freeze.md` §3c).
- Không refactor ngoài scope. Không sửa `docs/*` có `Status: frozen for MVP`
  trừ file task nêu tên.

### 4.3. Phase gate

Chạy plan P3. Mọi lệnh phải xanh; đọc dòng tổng kết, không grep. Mọi phase từ 1
tới 7 đều đụng `lib/features/` hoặc `lib/shared/`, nên chạy thêm bộ integration
trên emulator:
`flutter test integration_test/ -d emulator-5554 --flavor development`, kỳ vọng
`9 passing, 0 failing`. Không chạy host suite Windows cùng lúc với golden WSL.

### 4.4. Hai audit độc lập, audit-only, song song

Sau gate xanh, mở **hai** subagent trong cùng một message:

- **A — architecture/logic:** toàn văn `recursive-architecture-logic-review.md`.
- **B — UI/UX:** toàn văn `recursive-ui-ux-review.md`.

Biến truyền cho cả hai (thiếu biến nào thì reviewer phải dừng):
`PHASE_NUMBER`, `PHASE_TITLE`, `PHASE_TASKS` (danh sách số và tên task),
`PHASE_BASE_SHA`, `CURRENT_HEAD_SHA`, `BRANCH`, `WBS_ID`, `WORKTREE` (đường dẫn
tuyệt đối), `PLAN_PATH`, `HANDOFF_PATH`, `PLAN_DEVIATIONS` (danh sách
`PLAN-DEV`). UI reviewer nhận thêm `GALLERY_URL` =
`https://claude.ai/code/artifact/e8a68227-1582-407c-88c2-ff25d66bd9d8`.

Hai reviewer không được edit, commit, push, hay tạo PR.

### 4.5. Auto-fix tuần tự

1. Gộp finding trùng. Mâu thuẫn giữa hai reviewer được giải theo docs (BR/AD >
   handoff > code); nếu docs cũng im lặng thì hỏi chủ dự án.
2. Fix **architecture/logic trước**: mỗi finding có test pin reproduction →
   chạy verification có mục tiêu → commit
   `fix(<scope>): <gist> (M100.xx)`.
3. Rồi fix **UI/UX**, sau khi đọc lại latest tree (sau các fix logic): thêm
   assertion `getRect`/semantics → verification → commit.
4. Mở lại audit tương ứng bằng subagent **mới**, trên delta
   `PHASE_BASE_SHA..HEAD`, và lặp tới clean stop của review đó. Nếu cùng một
   blocker quay lại ba vòng: dừng, gửi root-cause report, không hạ severity.
5. Chạy lại P3 sau fix cuối.

### 4.6. Golden, gallery, PR, merge

- P4 (golden Linux, clone riêng mỗi branch) sau fix cuối, cho mọi phase có
  thể đổi pixel. Phase 0 không chạy. Lượt compare phải exit 0 và `0` PNG bẩn.
  Golden mới chỉ là baseline hồi quy; UI reviewer phải so nó với handoff trước
  khi accept.
- P5 (gallery): đọc bản live trước; ghép vào nếu bản live mới hơn lần đọc
  trước; publish đúng URL ghim; ghi `ảnh <digest>`.
- WBS entry (P1) cùng commit với code nó mô tả; khi merge, entry sang
  `done (<ngày>)` và dời vào `docs/wbs-archive/m100.md`.
- P6: đồng bộ `origin/main` (merge nếu lệch, rồi chạy lại gate), push, PR, chờ
  CI xanh, squash merge, `gh pr view <n> --json state -q .state` in `MERGED`,
  rồi mới xoá branch.

### 4.7. Báo cáo phase (PR body)

Bảng task → commit · danh sách `PLAN-DEV` · finding của hai audit (severity,
reproduction, fix commit) · lệnh gate kèm dòng tổng kết (`No issues found!`,
số test host, guard `0 findings`, integration `9/0`) · số PNG đổi và
`ảnh <digest>` · approved divergence đã dùng (D-id) · debt còn lại kèm WBS
trace. Không có blanket "pass".

## 5. Ghi chú riêng từng phase

| Phase | Việc phải để ý |
|---|---|
| 0 | Chỉ docs: không golden, không integration, không gallery. Audit UI xác nhận "no user-visible delta" bằng bằng chứng `git diff --stat`. Kiểm hash handoff trong repo bằng hash ở §0 |
| 1 | Rename chạy theo compiler, hai pass (plan Task 3). `heroNumeralCapTrim` giữ nguyên (D14). Gần như mọi golden đổi (font và thang chữ); đó là đổi có chủ đích, vẫn phải inspect qua gallery |
| 2 | Phân loại `MxIconButtonPlacement.bar` và `content` từng call site (D16). FAB extended hiện label. Bảng tonal/outlined là D6 |
| 3 | Task 15 Step 6: **chứng minh vẫn học được một deck** từ tab Study trước khi xoá `DeckStudyButtonWidget`; không có đường thì `AskUserQuestion`. Ring chuyển màu mastery chỉ khi `isFullyLearned` (BR-88) |
| 4 | `MxSwitchRow` chỉ có một node semantics toggled. Sàn contrast của viền control: đo rồi ghim số đo (owner decision 5); không xoá gate |
| 5 | Kiểm constructor `DialogRoute` trong SDK trước khi viết `MxDialogRoute`. Reduced motion. Scenario back gesture trong integration |
| 6 | `studyActionVariant` phủ mọi `StudyAction`; số nút vẫn do `supportedActions` quyết (không hardcode bốn nút); không `switch` trên `StudyMode` ngoài resolver (AD-18) |
| 7 | Task 36 mỗi feature một commit. Task 37 hỏi chủ dự án trước khi đóng băng V2. Task 38 là gate cuối |

## 6. Verification

- Mỗi task: test có mục tiêu của task, `dart format`, `flutter analyze` sạch.
- Mỗi phase: P3 đầy đủ, integration `9/0`, golden compare sạch, Widgetbook
  analyze và test, `check_docs.py`, guard `memox-v7`, CI xanh trên PR.
- Cuối cùng: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force`
  exit 0, cộng Task 38 Step 3 (danh sách phủ handoff).
- Lệnh nào chưa chạy thì ghi là chưa chạy, kèm lý do. Không dùng "flaky",
  "pre-existing" hay "pass locally" nếu chưa tái hiện được trên `origin/main`.

## 7. Clean stop và stop condition

**Clean stop của một phase:** mọi task xong hoặc có `PLAN-DEV`; hai audit sạch
(không P0/P1/P2 mở, không unapproved divergence); P3 và integration xanh; golden
compare sạch; gallery republish; PR `MERGED`; branch đã xoá; WBS đã cập nhật.
Chỉ khi đạt đủ mới sang phase sau.

**Clean stop cuối:** tám PR đã merge; Task 38 xong; mỗi widget trong 46 widget
của handoff trỏ được tới commit đã ship hoặc D-id đã hoãn; quyết định V2 đã ghi.

**Dừng ngay và báo chủ dự án khi:**

- input ở §0 thiếu hoặc sai hash;
- thay đổi cần làm sẽ đảo owner decision, D-id, BR/AD/UC, hoặc đụng persistence;
- cùng một P0/P1/P2 quay lại sau ba vòng fix-review;
- gate bắt buộc, CI hoặc integration đỏ mà chưa có root cause;
- không author được golden trên Linux (WSL hỏng, thiếu tài nguyên);
- merge bị chặn bởi branch policy;
- cần thao tác git hay database mang tính phá huỷ ngoài scope.

## 8. Definition of Done

- Tám phase merge đúng thứ tự, mỗi phase một PR squash, có WBS entry đã archive.
- Mọi task có test pin; contract đổi đi cùng test/guard đã dời, không có test bị
  xoá hay tắt.
- Sau mỗi phase có hai audit độc lập, fix tuần tự, recursive re-audit tới clean
  stop, và gate xanh.
- Golden author trên Linux `TZ=UTC`; gallery ở URL ghim hiển thị build cuối.
- Integration suite `9/0` ở trạng thái cuối.
- `tokyo-component-mapping.md` §2 và §9, `v1-freeze.md`, `CLAUDE.md` và WBS mô tả
  đúng thứ đã ship; mục hoãn nằm ở `Deferred and descoped` kèm D-id.
