# WBS — work breakdown and progress ledger

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì đã xong, đang làm, bị chặn |
| **Scope** | Milestone, task, blocker, technical debt, mục đã descoped |
| **Source of truth for** | Trạng thái task · blocker · technical debt · quyết định descope |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M4.9a |
| **Last updated** | 2026-07-29 |

Single source of truth for project progress. Update it in the same commit as the
work it describes. A task is `done` only when it meets the Definition of Done in
`.claude/skills/flutter-workflow/references/definition-of-done.md`.

Status values: `todo` · `in-progress` · `blocked` · `done` · `descoped`

**Task ID là định danh vĩnh viễn và không được trùng**, cùng chính sách với BR /
AD / UC (xem `business-rules.md`).

## Progress summary

| Milestone | Status | Notes |
|---|---|---|
| M0 · Development harness | done | Skills, checklist và enforcement script đã có |
| M1 · Product definition (Phase 0–1) | **done** | Đặc tả MVP đã frozen: AD-01…11, BR-01…87, UC-01…09, data model đầy đủ |
| M2 · Project foundation (Phase 2–3, 6) | **done** | Toàn bộ 9 task đóng: M2.1 · M2.1a · M2.1b · M2.2 · M2.2b · M2.3 · M2.4 · M2.5 · M2.6. App build được trên Android (3 flavor cài song song) và Web, l10n en/vi, bootstrap có error boundary, lint + guard đều enforce. Tiếp theo: **M3.1 · Cấu trúc feature-first và ranh giới layer** |
| M3 · Architecture & design system (Phase 4–5, 7, 12–13) | **done** | Mười hai task đóng: M3.1…M3.6 cộng M3.5a (review color system), M3.5b (áp A2 Quizlet Navy Indigo — 46 role `ColorScheme` khai báo tường minh), M3.5c (visual audit harness), M3.5d (siết tính đúng đắn của audit core), M3.5e (anchor, clip và allowance) và M3.5f (clip hỏi Flutter thay vì đoán). Cây feature-first + guard siết về `fail_on: [error, warning]`, Failure model, Riverpod foundation, design token, hai theme M3, sáu base component kèm 14 golden. Milestone đóng — không quyết định next task |
| M4 · Router, Database & Content Management (Phase 8, 11, 14) | in progress | M4.1, M4.1a, M4.2, M4.3, M4.4 **done** — GoRouter tập trung với `MaterialApp.router` và 404 ở `app/fallback/`; MX-VIS-001 ép mọi production screen có strict visual audit; schema v1 toàn bộ trong `.drift`; hai named query dùng chung một định nghĩa "đến hạn"; schema v1 đã dump và commit; cả 14 bất biến chạy trên database thật. M4.4a **done** — sắp xếp lại kế hoạch theo vertical slice. M4.8 **done** — 11 shared component mang prefix `Mx` (5 mới, 6 đổi tên), 26 golden mới, rename không đổi pixel; vòng review UI/UX đóng thêm 4 lỗi accessibility có đo đạc. M4.8a **done** — responsive hardening: `MxContentShell` overflow 135px/167px ở landscape đã đóng, bốn component còn lại đã tự cuộn sẵn; màn rộng chốt giữ kéo căng. M4.8b **done** — compact scale cho màn 320: hàng list 88→80px, padding ngang button 24→12 (bốn action `sm2` từ "Ag" thành "Again"), body/label giữ nguyên cỡ, phát hiện harness test báo màn hình 0×0 từ M3.6. **M4.5, M4.6, M4.7 `descoped` trước khi triển khai** — không dòng code nào từng được viết dưới ba ID đó. M4.8–M4.12 là kế hoạch mới: shared component → Deck/Card domain+data → Deck full-stack → Card full-stack → demo hardening. M4.9 **done** — Deck/Card domain + data vertical: 6 file domain (entity/enum/contract), DAO + 3 mapper + repository impl với transaction thật, `deck.drift` recursive query, constraint conflict → `ConflictFailure`, 78 test mới (49 integration trên SQLite thật + 1 web runtime trên Chrome), cả 14 bất biến pass trên dữ liệu do repository ghi; đồng thời **đóng lỗ hổng web của M4.2**: `driftDatabase` thiếu `web:` options và `drift_worker.js` prebuilt lệch ABI với `sqlite3.wasm` — connection đã sửa, worker compile từ đúng lockfile. M4.9a **done** — giới hạn cây 10 cấp enforce ở `createSubDeck`/`moveDeck` trước mutation, subtree traversal cycle-safe bằng recursive `UNION` (bỏ cap `depth < 64` production), bất biến thứ 15 (deck sâu hơn 10 cấp), và tách `CardRepository`/`CardRepositoryImpl`/`CardDao` khỏi Deck boundary. **Next task: M4.10 · Deck management full-stack.** M4 chỉ `done` khi Deck/Card demo slice hoàn thành. **Phase 10 (networking) hoãn** — AD-01, AD-05 |
| M5 · Review vertical slice — UC-05 (Phase 14) | todo | Bắt đầu **sau M4.12**. Không còn là vertical slice đầu tiên — Deck/Card CRUD đã hoàn thành trong M4.8–M4.12 và M5 không triển khai lại. Review MUST NOT bắt đầu khi M4.12 chưa `done` |
| M6 · Test suite (Phase 15) | todo | Chạy song song **từ M4.8 trở đi**, không đợi tới sau Review |
| M7 · CI/CD (Phase 19) | todo | Bắt đầu được ngay sau M2. Job Android + Web, chưa có iOS (AD-04) |
| M8 · Release Android (Phase 16–18, 20–22) | todo | |
| M9 · Backend Spring Boot + auth + sync (Phase 10) | todo | Sau khi M8 ổn định |

---

## M0 · Development harness

### T0.1 · Skill harness for the 22-phase checklist

- **Status:** done
- **Goal:** Encode `docs/checklist.md` as invocable skills so each phase has one
  place that holds its rules, and so phase order is enforced rather than
  remembered.
- **Scope:** 11 skills under `.claude/skills/`, the canonical checklist,
  root `CLAUDE.md`, document templates. Out of scope: any Flutter source code.
- **Output:** `docs/checklist.md`, `docs/README.md`, `docs/wbs.md`, `CLAUDE.md`,
  và 11 skill dưới `.claude/skills/` (workflow, product-spec, project-setup,
  architecture, design-system, navigation, state-riverpod, data-layer,
  feature-slice, testing, ship).
- **Acceptance criteria:**
  - [x] Mỗi phase trong checklist map tới đúng một skill sở hữu.
  - [x] `check_architecture.sh` phát hiện domain→framework import,
        presentation→data import, cross-feature import, core/shared→feature
        import, swallowed exception, `print` trong `lib/`, sai suffix và file quá
        lớn — verify bằng fixture.
  - [x] `check_architecture.sh` báo 0 vi phạm trên code đúng chuẩn — verify bằng
        fixture.
  - [x] Cả hai script exit 0 kèm thông báo rõ khi project Flutter chưa tồn tại.
- **Dependencies:** none
- **Tests required:** fixture-based verification của cả hai script
- **Checklist phases:** meta — hỗ trợ tất cả

---

## M1 · Product definition — done

Đặc tả MVP đã **frozen**. Mọi tài liệu trong `docs/` đánh dấu frozen là hợp đồng
mà code sẽ được viết theo; đổi chúng là quyết định có chủ đích kèm cập nhật đồng
bộ, không phải chỉnh sửa tiện tay.

### T1.1 · Product requirements và quyết định kiến trúc

- **Status:** done
- **Goal:** Chốt các quyết định nền tảng và ghi lại kèm lý do.
- **Output:** `docs/product.md` (gồm cả MVP scope), `docs/architecture.md`
- **Acceptance criteria:**
  - [x] Problem, users, core value.
  - [x] Quyết định platform / data posture / auth / sensitive data kèm hệ quả.
  - [x] Feature phân loại must / should / nice / out, mỗi cái có điều kiện hoàn
        thành.
  - [x] Quyết định kiến trúc ghi thành AD kèm lý do và đánh đổi.
- **Dependencies:** product owner input — đã nhận
- **Tests required:** none — document only
- **Checklist phases:** 0.1, 0.2, và một phần 4.3

### T1.1b · Chỉnh harness theo quyết định đã chốt

- **Status:** done
- **Goal:** Loại bỏ hướng dẫn đã thành sai sau khi chốt local-first / `.drift` /
  no-auth / Android-only. Một skill nói sai còn tệ hơn không có skill, vì phiên
  sau sẽ tin nó.
- **Output:** `flutter-data-layer/references/persistence.md`,
  `flutter-data-layer/SKILL.md`,
  `flutter-project-setup/references/dependencies.md`,
  `flutter-ship/references/ci.md`, `CLAUDE.md`
- **Acceptance criteria:**
  - [x] Không còn ví dụ Dart table class trong tài liệu Drift.
  - [x] Mọi chỗ nhắc `dio` đều nói rõ là hoãn và vì sao.
  - [x] Frontmatter và tham chiếu chéo vẫn hợp lệ sau khi sửa.
- **Dependencies:** T1.1
- **Tests required:** kiểm tra frontmatter + tham chiếu chéo
- **Checklist phases:** meta

### T1.2 · Use cases and business rules

- **Status:** done
- **Goal:** Đặc tả must-have đủ chi tiết để code mà không phải hỏi thêm.
- **Output:** `docs/use-cases.md`, `docs/business-rules.md`
- **Acceptance criteria:**
  - [x] Mỗi must-have có use case đủ actor, trigger, preconditions,
        main / alternative / error flows, postconditions.
  - [x] Business rules đánh số và không trùng.
  - [x] Cả hai scheduler đặc tả chính xác, gồm công thức SM-2 và bảng interval
        8-box.
  - [x] Validation rules kèm message hiển thị chính xác.
  - [x] Card state machine suy ra từ `due_at`, có liệt kê chuyển đổi không hợp lệ.
  - [x] Edge case liệt kê kèm hành vi mong đợi.
- **Dependencies:** T1.1
- **Tests required:** none — document only
- **Checklist phases:** 0.3

### T1.2b · Sửa thiết kế scheduler theo phản hồi

- **Status:** done
- **Goal:** Áp thiết kế: scheduler theo deck, khoá sau review đầu, reset +
  generation, hai tập action khác nhau.
- **Output:** `docs/architecture.md` (AD-06 viết lại, AD-09 mới),
  `docs/business-rules.md`, `docs/data-model.md`, `docs/use-cases.md`,
  `docs/product.md`, `CLAUDE.md`,
  `flutter-data-layer/references/persistence.md`
- **Những gì bị đảo so với bản trước:**
  - SM-2 **vào lại MVP**.
  - 8-box đổi từ 4 mức đánh giá sang **2 action** `forgotten`/`remembered`.
  - Scheduler chuyển sang "đổi tự do trước review đầu, khoá sau đó, mở lại bằng
    reset".
  - Thêm `scheduler_generation` vào deck, card state, session và history.
- **Acceptance criteria:**
  - [x] BR liên tục, không trùng, không thiếu.
  - [x] Mọi trích dẫn BR/AD resolve.
  - [x] Hai bất biến của AD-09 diễn đạt được thành query kiểm tra.
- **Dependencies:** T1.2
- **Tests required:** none — document only
- **Checklist phases:** 0.3, 4.3, 11.1

### T1.3 · Freeze MVP specification và sửa tính nhất quán tài liệu

- **Status:** done
- **Goal:** Chốt mô hình cây deck nhiều cấp, hoàn thiện review history và session
  lifecycle, chốt các rule còn mở, và sửa mọi mâu thuẫn giữa các tài liệu. Không
  tạo source code.
- **Scope:** chỉ tài liệu, WBS và validation script.
- **Out of scope:** Flutter source, UI, Drift runtime schema, dependency mới,
  backend.
- **Editable documents:** `docs/*.md`, `CLAUDE.md`,
  `.claude/skills/flutter-data-layer/references/persistence.md`,
  `.claude/skills/flutter-workflow/scripts/`
- **Output:**
  - `docs/business-rules.md` — thêm BR-55…BR-87, chính sách đánh số vĩnh viễn
  - `docs/data-model.md` — viết lại: `root_deck_id`, `content_type`,
    `review_kind`, session `status`/`end_reason`, 14 query bất biến
  - `docs/use-cases.md` — UC-08 (xác lập `content_type`), UC-09 (di chuyển deck);
    UC-02…07 cập nhật
  - `docs/architecture.md` — AD-10 (cây deck), AD-11 (trạng thái tường minh)
  - `docs/product.md`, `docs/README.md`, `CLAUDE.md`
  - `.claude/skills/flutter-data-layer/references/persistence.md`
  - `.claude/skills/flutter-workflow/scripts/check_docs.sh` — validation script
  - `.claude/skills/flutter-workflow/scripts/verify_invariants.py` — self-test
    cho 14 query bất biến, trích thẳng từ `data-model.md`
- **Acceptance criteria:**
  - [x] Root deck chỉ tạo được deck con (BR-58, BR-59).
  - [x] Sub-deck mới có `content_type = unset` (BR-60).
  - [x] Lần tạo phần tử con đầu tiên xác lập `content_type` (BR-62).
  - [x] Một deck không thể chứa đồng thời card và deck con (BR-65).
  - [x] Cây deck hỗ trợ nhiều cấp; `COALESCE(parent_deck_id, id)` bị cấm và không
        còn xuất hiện (BR-55, BR-57).
  - [x] Cây deck không có cycle — có query phát hiện (BR-69).
  - [x] Scheduler chỉ thuộc root và được descendant kế thừa (BR-05, BR-06).
  - [x] `review_history` phân biệt `scheduled` và `relearning` bằng cột tường
        minh (BR-75, BR-76).
  - [x] `study_sessions` có lifecycle rõ ràng với ma trận `status` × `end_reason`
        (BR-79…BR-86).
  - [x] Không còn marker chưa xác nhận trong phạm vi MVP.
  - [x] Các tài liệu không mâu thuẫn — audit ngữ nghĩa toàn bộ tham chiếu BR/AD.
  - [x] Validation script chạy thành công.
  - [x] Hai task T1.3 trùng đã bị xoá; `data-model.md` đã ra khỏi "Not written
        yet"; progress summary đã sửa.
- **Dependencies:** T1.2b
- **Tests required:** `check_docs.sh` pass
- **Checklist phases:** 0.3, 1.1, 1.2, 4.3, 11.1

### T1.3a · Chuẩn hoá format tài liệu cho AI agent

- **Status:** done
- **Goal:** Thiết lập hợp đồng tài liệu cố định để mọi agent biết đọc theo thứ tự
  nào, đâu là quyết định chính thức, và không tự diễn giải prose thành rule mới.
- **Scope:** format, header, template, thứ tự đọc, validation. Chuẩn hoá tài liệu
  hiện có theo format mới.
- **Out of scope:** **thay đổi nghiệp vụ**. Không rule nào đổi nghĩa; không AD,
  BR hay UC nào được thêm, bỏ hay đánh số lại. Không Flutter source.
- **Editable documents:** toàn bộ `docs/*.md`, `CLAUDE.md`,
  `.claude/skills/flutter-workflow/scripts/check_docs.sh`
- **Output:**
  - `docs/document-conventions.md` — hợp đồng tài liệu: thứ tự đọc, header bắt
    buộc 7 field, template AD/BR/UC/data-model/WBS, MUST/SHOULD/MAY, canonical
    location, quy tắc superseded, quy tắc tài liệu frozen
  - Header 7 field cho cả 9 tài liệu trong `docs/`
  - `business-rules.md` — bảng BR thêm cột `Status`, `Enforced by`, `Related`
  - `architecture.md` — AD sắp lại theo số, mỗi AD có `Status` +
    `Affected documents`
  - `use-cases.md` — mỗi UC có khối `Status`
  - `CLAUDE.md` — mục Reading order
  - `check_docs.sh` — nhóm kiểm tra A2 cho hợp đồng format
- **Acceptance criteria:**
  - [x] Mọi tài liệu trong `docs/` có đủ 7 field header.
  - [x] Không hai tài liệu nào cùng nhận là source of truth của một chủ đề.
  - [x] Mọi dòng BR có đủ ID / Status / Rule / Enforced by / Related.
  - [x] Mọi UC có đủ chín mục bắt buộc.
  - [x] Mọi AD có Status, Affected documents và Decision.
  - [x] Reading order có trong `CLAUDE.md` và `document-conventions.md`.
  - [x] Năm check mới đều verify bằng test tiêm lỗi.
  - [x] **Không nghiệp vụ nào đổi** — số lượng AD/BR/UC không đổi (11/87/9), nội
        dung rule giữ nguyên nghĩa.
- **Dependencies:** T1.3
- **Tests required:** `check_docs.sh` pass; fault-injection cho mỗi check mới
- **Checklist phases:** 1.2

### T1.4 · Chia WBS chi tiết cho M2–M5

- **Status:** done
- **Goal:** Chia M2–M4 thành task có acceptance criteria và dependency; chốt phạm
  vi vertical slice đầu tiên.
- **Scope:** chỉ file này. Không tạo source code.
- **Out of scope:** Flutter source, sửa tài liệu frozen.
- **Editable documents:** `docs/wbs.md`
- **Output:** `docs/wbs.md`, mở rộng
- **Acceptance criteria:**
  - [x] M2–M4 chia tới task, mỗi task có goal, scope, out of scope, output,
        acceptance criteria, dependency và test yêu cầu.
  - [x] M5 chốt phạm vi đúng luồng UC-05, xuyên từ Drift tới màn hình.
  - [x] Milestone sau M5 để ở mức feature — chia tới task lúc này chắc chắn phải
        lập lại kế hoạch sau khi M2 dạy vài điều.
  - [x] Không task ID nào trùng; không dependency nào trỏ tới task không tồn tại.
  - [x] Mọi acceptance criteria kiểm được bằng lệnh hoặc hành vi cụ thể.
- **Dependencies:** T1.3a
- **Tests required:** `check_docs.sh` pass
- **Checklist phases:** 1.1, 1.2

---

## Quy tắc chung cho mọi task M2–M5

Áp cho tất cả task bên dưới, nêu một lần ở đây thay vì lặp lại 24 lần
(`document-conventions.md` §5):

- **MUST** cập nhật `docs/wbs.md` trong **cùng commit** với code mà nó mô tả.
- **MUST NOT** sửa tài liệu có `Status: frozen for MVP` trừ khi task nêu tên file
  đó ở `Editable documents`.
- **MUST** viết test trong cùng task. M6 chỉ bổ sung độ phủ còn thiếu, **không**
  phải nơi bắt đầu viết test.
- Mọi task **MUST** kết thúc với `flutter analyze` sạch (0 error, 0 warning).
  Không lặp lại điều này ở từng acceptance criteria; nó là điều kiện cần của mọi
  task có code. `custom_lint` **đã descoped** ở M2.2 — xem `Deferred and
  descoped`; đừng thêm lại nó vào acceptance criteria của task mới.
- `.claude/skills/flutter-architecture/scripts/check_architecture.sh` **MUST**
  exit 0 sau mọi task tạo file trong `lib/`.

---

## M2 · Project foundation

Mục tiêu: từ repo chỉ có tài liệu → một Flutter project build được trên Android
và Web, analyzer sạch, code generation chạy được.

### M2.1 · Khởi tạo Flutter project và xác nhận toolchain

- **Status:** done
- **Goal:** Tạo Flutter project chạy được và xác nhận toolchain đủ để build
  Android lẫn Web.
- **Scope:** `flutter create` với org/package đúng, xoá code demo, thu `main.dart`
  về đúng một lệnh bootstrap, xác nhận `flutter doctor`.
- **Out of scope:** dependency ngoài mặc định, flavor, l10n, theme, router,
  database. Tất cả có task riêng.
- **Editable documents:** `docs/wbs.md`
- **Output:** `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`,
  `lib/main.dart`, `lib/app/app.dart`, `test/widget_test.dart`, `README.md`,
  `android/`, `web/`, `.metadata`
- **Acceptance criteria:**
  - [x] `flutter doctor` không có mục nào ở trạng thái lỗi cho Android
        toolchain. → `[√] Android toolchain — develop for Android devices
        (Android SDK version 36.0.0)`, platform android-36, build-tools 36.0.0,
        JDK 21, all licenses accepted; `flutter doctor -v` → `No issues found!`
  - [x] `flutter analyze` → 0 error, 0 warning. → `No issues found!`, exit 0
  - [x] `flutter build apk --debug` exit 0. →
        `√ Built build\app\outputs\flutter-apk\app-debug.apk`, exit 0
  - [x] `flutter build web` exit 0. → `✓ Built build/web`, exit 0
  - [x] `flutter test` exit 0. → `All tests passed!`, 1 test
  - [x] `lib/main.dart` ≤ 10 dòng và không chứa widget nào. → 7 dòng, 0 widget
  - [x] Không còn counter demo trong `lib/` hay `test/`.
  - [x] `applicationId` và `namespace` = `com.ntgptit.memox`, không phải
        `com.example`.
  - [x] Chỉ có `android/` và `web/`; không có `ios/`, `linux/`, `macos/`,
        `windows/`.
  - [x] Dependency chỉ gồm bộ mặc định của Flutter: `cupertino_icons`,
        `flutter_test`, `flutter_lints`.
  - [x] `check_architecture.sh` exit 0.
  - [x] `check_docs.sh` exit 0.
  - [x] `.gitignore`, `docs/` và `.claude/` không bị `flutter create` ghi đè.
- **Dependencies:** T1.4
- **Tests required:** smoke test dựng app và tìm được root widget — **đã có**,
  `test/widget_test.dart`, pass. Ngoài ra APK đã được cài và chạy trên emulator
  `Medium_Phone` (Android 16, API 36): activity `com.ntgptit.memox/.MainActivity`
  giành được `mCurrentFocus` sau 7s và screenshot cho thấy app **render thật**
  — nền Material 3 sáng, chữ `memox` căn giữa. Build xong không đồng nghĩa với
  hiển thị được; đây là bước xác nhận điều thứ hai.
- **Checklist phases:** 2.1, 2.3

### M2.1a · Khung màn hình mobile cho bản build Web

- **Status:** done
- **Goal:** Bản Web render ở đúng tỉ lệ màn hình điện thoại, để screenshot và
  E2E phản ánh được bản Android.
- **Scope:** widget bọc app trên web, giới hạn bề mặt về kích thước điện thoại
  và **override `MediaQuery`** để code responsive nhìn thấy đúng kích thước đó.
- **Out of scope:** device frame có viền/notch, chọn nhiều kích thước máy,
  cấu hình Playwright (M7).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/mobile_frame_widget.dart`, wiring trong `lib/app/app.dart`,
  test trong `test/widget_test.dart`
- **Acceptance criteria:**
  - [x] Trên web, app bị giới hạn về `393×852` logic và căn giữa.
  - [x] `MediaQuery.sizeOf` bên trong trả về kích thước điện thoại, **không** phải
        kích thước cửa sổ trình duyệt — có test khẳng định.
  - [x] Cửa sổ nhỏ hơn khung thì **không** đóng khung và **không** tràn — có test.
  - [x] Trên Android là no-op (`kIsWeb` false).
  - [x] `flutter analyze` 0 issue; `flutter test` 4/4 pass;
        `flutter build web --no-web-resources-cdn` exit 0.
- **Kiểm chứng bằng screenshot thật:** widget test khẳng định được logic nhưng
  **không ai từng nhìn thấy** khung này render. Đã dựng
  `flutter build web --no-web-resources-cdn`, phục vụ `build/web` và chụp bằng
  Playwright ở hai viewport:

  | Viewport | Nhìn thấy | Đo được |
  |---|---|---|
  | 1440×900 | App nằm giữa trong khung dọc hình điện thoại, nền tối bao quanh | Nền `rgb(30,30,30)` = đúng `0xFF1E1E1E`; khung cao **852**, lề trái/phải **524/524**, lề trên/dưới **24/24** — căn giữa chính xác |
  | 393×852 | Không đóng khung, app tràn đầy viewport, không có dải tối | `scrollWidth` 393 = `innerWidth` 393 → **không** tràn ngang; canvas 393×852 |

  Bề rộng khung đo được 392 thay vì 393 là do pixel biên bị antialias rơi dưới
  ngưỡng lọc màu, không phải sai layout — chiều cao 852 và hai lề 524/524 khớp
  tuyệt đối.

  Khung hiển thị **đúng**; không cần sửa `mobile_frame_widget.dart`.
- **Dependencies:** M2.1
- **Tests required:** 3 widget test cho ba nhánh của widget — đã có, pass; cộng
  thêm kiểm chứng bằng screenshot thật ở hai viewport (bảng trên)
- **Checklist phases:** 7.4, 15.5

### M2.1b · Sửa `check_docs.sh` — task ID `M*` không được kiểm

- **Status:** done
- **Goal:** Làm cho check WBS trong `check_docs.sh` kiểm đúng thứ nó nói là đang
  kiểm, và mở rộng sang hai lỗi mà nó chưa bắt được.
- **Scope:** regex task ID; check dependency resolve; check `M*` đủ field và
  acceptance criteria không rỗng; test tiêm lỗi cho từng check mới.
- **Out of scope:** đổi nội dung WBS để chiều script. Nếu một check mới bắt được
  vi phạm có thật trong WBS hiện tại thì **sửa WBS**, và ghi lại là đã sửa gì.
- **Editable documents:** `docs/wbs.md`,
  `.claude/skills/flutter-workflow/scripts/check_docs.sh`
- **Output:** `.claude/skills/flutter-workflow/scripts/check_docs.sh`
- **Vấn đề:** regex cũ là `^### T[0-9]+...`, chỉ khớp tiền tố `T`. Nó in
  `no duplicate WBS task IDs (8 tasks)` trong khi WBS có 33 task. Đây là **pass
  gây hiểu nhầm**: 25 task `M2`–`M5` không được bảo vệ khỏi trùng ID, nhưng
  output đọc như đã kiểm hết. Một check im lặng bỏ sót còn tệ hơn không có
  check, vì nó tạo ra niềm tin sai.
- **Acceptance criteria:**
  - [x] Regex task ID là `[TM][0-9]+(\.[0-9]+)?[a-z]?`; số task báo ra khớp số
        task thật trong `wbs.md`. → báo `35 tasks`; `grep -c '^### '` = 35 và
        **mọi** heading `###` đều khớp shape task ID, không sót cái nào.
  - [x] Check mới: mọi `Dependencies` trỏ tới task **có tồn tại**. → `47 edges`
        resolve. Chỉ token có shape ID mới bị kiểm, nên `none` và
        `product owner input — đã nhận` không bị báo nhầm.
  - [x] Check mới: mọi task `M*` có đủ 9 field bắt buộc của §6.5 và khối
        acceptance criteria **không rỗng**. Giới hạn ở `M*` có chủ đích: `T*` có
        trước template §6.5 và một số task thiếu `Editable documents` một cách
        hợp lệ. `Out of scope` không nằm trong 9 field vì §6.5 đánh dấu nó là có
        điều kiện.
  - [x] **Mỗi** check mới được verify bằng **test tiêm lỗi** — 4/4 case đạt, xem
        bảng dưới.
  - [x] `check_docs.sh` exit 0 trên `wbs.md` hiện tại.
- **Kết quả test tiêm lỗi:**

  | Case | Vi phạm được tiêm | Sau khi tiêm | Sau khi khôi phục |
  |---|---|---|---|
  | 1 | Thêm heading `### M4.2` trùng | exit 1 · `duplicate WBS task ID` | exit 0 |
  | 2 | Đổi dependency của M4.6 thành `M9.9` | exit 1 · `dependency points at a task that does not exist` | exit 0 |
  | 3a | Xoá field `Tests required` của M2.3 | exit 1 · `missing field(s)` | exit 0 |
  | 3b | Xoá hết checkbox acceptance criteria của M3.4 | exit 1 · `Acceptance criteria block is empty` | exit 0 |

  Case 1 cũng là bằng chứng cho việc regex cũ mù: với đúng cùng một vi phạm,
  regex `T`-only thấy **8 task, 0 trùng** — pass sạch. Regex mới thấy 36 task và
  bắt được `M4.2`.
- **Dependencies:** M2.1
- **Tests required:** fault injection cho cả ba check (regex trùng ID,
  dependency chết, field thiếu / acceptance criteria rỗng) — **đã chạy, 4/4 đạt**
- **Checklist phases:** 1.2

### M2.2 · Dependency nền tảng và code generation

- **Status:** done
- **Goal:** Cài đúng bộ dependency của MVP, làm `build_runner` chạy sạch, và
  **pin phiên bản Flutter**.
- **Scope:** runtime + dev dependency theo
  `.claude/skills/flutter-project-setup/references/dependencies.md`; cấu hình
  `build.yaml` nếu cần; commit `pubspec.lock`; pin Flutter SDK.
- **Out of scope:** `dio`, `connectivity_plus`, `flutter_secure_storage` — hoãn
  theo AD-05 và AD-03. Thêm chúng ở M9. `golden_toolkit`/`alchemist` — thêm khi
  Phase 15.4 bắt đầu.
- **Editable documents:** `docs/wbs.md`, `docs/architecture.md`
- **Output:** `pubspec.yaml`, `pubspec.lock`, `build.yaml` nếu cần, `.fvmrc`,
  mục Toolchain trong `docs/architecture.md`
- **Acceptance criteria:**
  - [x] `flutter pub get` exit 0. → `Got dependencies!`
  - [x] `dart run build_runner build --delete-conflicting-outputs` exit 0. →
        `Built with build_runner/aot in 39s; wrote 8 outputs.`
  - [x] Chạy `build_runner` lần hai không sinh diff (`git status --porcelain`
        rỗng cho file không bị `.gitignore`). → lần hai `wrote 0 outputs`, và
        `git status --porcelain` **giống hệt** trước/sau.
  - [x] `flutter pub deps --style=compact | grep -c '^.*dio'` = 0. → `0`
  - [x] `uuid` có trong dependency (bắt buộc từ đầu theo AD-03). → `uuid: ^4.6.0`
  - [x] `pubspec.lock` được commit.
  - [x] Phiên bản Flutter được pin ở đúng **một** vị trí gốc và lý do được ghi
        lại (§5 — không chép con số ra hai chỗ). → con số ở `.fvmrc`, lý do ở
        mục Toolchain của `architecture.md`, mục đó **không** chép lại con số.
  - [x] `custom_lint` + `riverpod_lint` — **descoped**, không còn là tiêu chí.
- **Hai điểm lệch so với `dependencies.md`, cả hai đều có lý do:**

  1. **`custom_lint` + `riverpod_lint` — descoped khỏi MVP.** Mọi phiên bản
     `custom_lint` đã publish đều yêu cầu `analyzer ^7` hoặc `^8`; trong khi
     `json_serializable 6.14`, `freezed 3.2.5` và `drift_dev 2.34` đều yêu cầu
     `analyzer >=10`. Cách duy nhất để cài được là hạ **toàn bộ** stack
     generator xuống một thế hệ — kể cả `freezed_annotation` về `^2.2.0` và
     `uuid` về `^3.0.6`, tức đi ngược AD-03.

     Chủ dự án đã quyết định **không cần `custom_lint`**; nếu cần sẽ phát triển
     guard bên ngoài. Đây là quyết định descope, **không** phải blocker đang
     chờ gỡ — xem `Deferred and descoped` để biết chính xác mất gì.
  2. **`sqlite3_flutter_libs` bị **loại bỏ**.** Phiên bản duy nhất tương thích
     là `0.6.0+eol`, và đó là một **tombstone release**: mô tả của chính nó là
     *"Not used anymore, update to version 3.x of package:sqlite3 instead"*, và
     nội dung là đúng một file Dart, **không có native code nào**. Từ
     `sqlite3` 3.x, thư viện native được cung cấp qua **native assets**
     (`hook/build.dart`) — feature flag `enable-native-assets` đã bật sẵn trong
     Flutter 3.44. Giữ lại package này sẽ tạo cảm giác sai rằng native lib đã
     được lo, đúng vào chỗ nguy hiểm nhất: Drift hỏng ở **runtime**, không phải
     lúc build.

     **M4.2 MUST kiểm chứng** SQLite thật sự nạp được trên thiết bị Android
     thật, vì cơ chế đã đổi từ Flutter plugin sang native assets.
- **Dependencies:** M2.1
- **Tests required:** none — cấu hình; đã được cover bởi việc `build_runner` chạy
  sạch và analyzer sạch
- **Checklist phases:** 3.1, 3.2, 3.3

### M2.2b · Guard chính cho dự án — ruleset `memox-v7`

- **Status:** done
- **Goal:** Thay thứ đã mất khi descope `custom_lint` bằng một guard thật sự
  chạy được, và làm nó thành cổng cơ học chính của dự án.
- **Scope:** vendor `code-verification-guard-v2` vào repo; tạo ruleset
  `memox-v7`; nối vào `dod_check.sh`; cập nhật skill đang trỏ tới `custom_lint`.
- **Out of scope:** viết rule cho code chưa tồn tại ngoài phạm vi đã chốt của
  MVP; sửa engine Python (chính sách nằm ở YAML, engine giữ generic).
- **Editable documents:** `docs/wbs.md`, `.claude/skills/**`
- **Output:** `code-verification-guard-v2/` (vendored),
  `code-verification-guard-v2/registries/projects/memox-v7/`,
  `code-verification-guard.yaml`, `dod_check.sh`
- **Ranh giới sở hữu (từ `AGENTS.md` của repo guard):** thư mục
  `code-verification-guard-v2/` thuộc về repo guard, **MUST NOT sửa tại chỗ**.
  Mọi thay đổi rule đi upstream trước rồi refresh về. Bản vendor được commit vào
  đây có chủ đích để một lần clone mới chạy được cổng chính ngay — CI và
  `dod_check.sh` đều dựa vào điều đó. `code-verification-guard.yaml` ở gốc là
  phần cấu hình **duy nhất** thuộc về repo này.
- **Vì sao phải tạo ruleset mới thay vì dùng `memox` sẵn có:** `memox` và
  `memox-v4` là Flutter nhưng theo cây **layer-first**
  (`lib/presentation/features/**`, `lib/data/datasources/**`). memox-v7 là
  **feature-first** (`lib/features/<f>/{domain,data,presentation}`). Mọi đường
  dẫn scope đều khác, nên nếu dùng lại thì rule **không match file nào** và
  guard báo pass sạch — đúng loại lỗi mà M2.1b vừa sửa. `memox-v5` là React
  Native, khác hẳn ngôn ngữ.
- **Acceptance criteria:**
  - [x] Ruleset `memox-v7` tồn tại với scope khớp layout thật của repo.
  - [x] Guard chạy được và **exit 0** trên code hiện tại: `Errors: 0`.
  - [x] **Mỗi rule trụ cột được verify bằng test tiêm lỗi** — 6/6 đạt, xem bảng.
  - [x] Guard là một bước trong `dod_check.sh`; `dod_check.sh` exit 0.
  - [x] Ruleset `memox-v7` đã merge **upstream** vào
        `ntgptit/code-verification-guard-v2` (PR #6) — đó là vị trí gốc, cùng
        chỗ với `memox-v4` / `memox-v5`.
  - [x] Bản vendor trong repo **byte-identical với upstream** (`diff -r` sạch),
        nên refresh được bằng cách copy lại. Lệnh refresh ghi ở đầu
        `code-verification-guard.yaml`.
  - [x] Mọi skill từng bảo chạy `dart run custom_lint` nay trỏ sang guard.
- **Kết quả test tiêm lỗi:**

  | Rule | Vi phạm được tiêm | Kết quả |
  |---|---|---|
  | `state_management.no_ref_read_in_build` | `ref.read` trong `build()` | fires → exit 1; xoá → exit 0 |
  | `architecture.domain_no_infrastructure_import` | domain import `package:flutter` | fires → exit 1; xoá → exit 0 |
  | `data_model.no_coalesce_parent_deck_id` | `COALESCE(parent_deck_id, id)` (BR-57) | fires → exit 1; xoá → exit 0 |
  | `design_token.no_raw_color` | `Color(0xFF112233)` trong presentation | fires → exit 1; xoá → exit 0 |
  | `error_handling.no_swallowed_exception` | `catch (e) {}` | fires → exit 1; xoá → exit 0 |
  | `state_management.controller_no_build_context` | controller giữ `BuildContext` | fires → exit 1; xoá → exit 0 |

- **Một điều cố ý chưa siết:** guard hiện `fail_on: [error]`, chưa fail trên
  warning. Phần lớn `lib/` chưa tồn tại (features ở M3.1, database ở M4.2, l10n
  ở M2.4), nên engine báo 26 `guard.config.rule_without_targets` — nó **từ chối**
  để một rule không match file nào lặng lẽ pass. Diagnostic đó đúng và **MUST
  NOT** bị bịt; nó chính là lỗi mà M2.1b vừa sửa. Vì vậy cổng chặn trên `error`,
  còn 26 warning kia đứng đó như một backlog trung thực. **M3.1 siết lại thành
  `fail_on: [error, warning]`.**
- **Dependencies:** M2.2
- **Tests required:** fault injection cho từng rule trụ cột — **đã chạy, 6/6 đạt**
- **Checklist phases:** 5.1, 19.1

### M2.3 · analysis_options.yaml

- **Status:** done
- **Goal:** Áp bộ lint đã viết sẵn và xác nhận **từng rule** được analyzer công
  nhận.
- **Scope:** copy `analysis_options.yaml` từ
  `.claude/skills/flutter-architecture/references/`, sửa những rule sai tên hoặc
  đã deprecated, **gỡ khối `analyzer: plugins: - custom_lint`** vì package đó đã
  descoped ở M2.2.
- **Out of scope:** nới lỏng rule để code hiện tại pass. Nếu một rule quá chặt,
  ghi lý do vào WBS rồi mới đổi. Cũng ngoài phạm vi: guard thay thế cho
  `riverpod_lint` — nếu làm thì là task riêng, xem `Deferred and descoped`.
- **Editable documents:** `docs/wbs.md`,
  `.claude/skills/flutter-architecture/references/analysis_options.yaml`
- **Output:** `analysis_options.yaml` ở gốc project
- **Acceptance criteria:**
  - [x] `flutter analyze` → 0 error, 0 warning. → `No issues found!`
  - [x] `flutter analyze` **không** in cảnh báo dạng
        `unrecognized/removed lint rule` cho bất kỳ rule nào trong file. → grep
        `undefined_lint|deprecated_lint|unrecognized_error_code` không có kết quả
  - [x] Không có khối `analyzer: plugins:` trong `analysis_options.yaml` ở gốc
        project — một plugin khai báo mà không cài được sẽ làm analyzer im lặng
        bỏ qua, đúng kiểu "cấu hình trông như đang chạy nhưng không chạy". Hai
        lần nhắc `custom_lint` còn lại đều nằm trong **comment cảnh báo đừng
        thêm lại**, và được giữ có chủ đích vì đó chính là thứ chặn tái phạm.
  - [x] `strict-casts`, `strict-inference`, `strict-raw-types` đều bật **và
        được kiểm chứng là có hiệu lực**, không chỉ có mặt trong file.
  - [x] Mỗi rule bị bỏ hoặc thay so với bản trong skill được ghi vào WBS kèm lý
        do — xem bảng dưới.
  - [x] Mục technical debt "analysis_options.yaml chưa được áp dụng" được đánh
        dấu đã trả.

- **Phát hiện chính của task này — 11 rule chưa bao giờ chạy.** Bản reference
  liệt kê phần lớn lint chỉ ở `analyzer: errors:`. Nhưng `errors:` chỉ **đổi mức
  độ** của một chẩn đoán *đã được sinh ra*; nó **không bật** lint. Rule nào
  `flutter_lints` không bật sẵn thì nằm im, và severity mapping áp lên một chẩn
  đoán không bao giờ tồn tại.

  Kiểm chứng trực tiếp: file chứa `SizedBox(child: Text('x'))` với
  `prefer_const_constructors: error` trong `errors:` → `No issues found!`. Thêm
  đúng rule đó vào `linter: rules:` → bắn ngay 2 lỗi.

  Đây cùng một họ lỗi với bug `check_docs.sh` ở M2.1b và với plugin `custom_lint`
  khai báo mà không cài: **cấu hình trông như đang chạy nhưng không chạy**. 11
  rule bị ảnh hưởng, gồm `unawaited_futures`, `discarded_futures`,
  `prefer_const_constructors`, `prefer_final_locals`, `avoid_dynamic_calls`,
  `only_throw_errors`. Nay mọi lint đều nằm ở `rules:`, `errors:` chỉ để nâng mức.

- **Rule đã thay hoặc loại bỏ:**

  | Rule | Xử lý | Lý do |
  |---|---|---|
  | `immutable_classes` | **thay** bằng `must_be_immutable: error` | Không phải tên rule có thật — analyzer báo `undefined_lint`. `must_be_immutable` là chẩn đoán tương đương và đúng ý định ban đầu: class `@immutable` (mọi widget) có field mutable. Đã kiểm chứng nó bắn thật |
  | `use_if_null_to_convert_nulls_to_bools` | **xoá** | Analyzer báo `deprecated_lint`, không có rule kế nhiệm |
  | `exhaustive_cases` | **giữ** | Vẫn được nhận diện trên Dart 3.12.2; suýt bị rơi khi sắp xếp lại file, đã kiểm tra bằng cách diff danh sách rule giữa hai bản |

- **Kiểm chứng cấu hình có hiệu lực** (không chỉ tồn tại trong file):

  | Kiểm | Cách | Kết quả |
  |---|---|---|
  | analyzer có bắt mã lỗi lạ không | tiêm `totally_bogus_diagnostic_code` vào `errors:` | báo `unrecognized_error_code` → im lặng ở phần `errors:` là kiểm thật |
  | `strict-casts` | bật/tắt cờ trên cùng một file `final int x = d;` | `true` → `invalid_assignment`; `false` → sạch |
  | `strict-raw-types` | `List makeIt() => <int>[1];` | báo `strict_raw_type` |
  | `prefer_const_constructors` | constructor không `const` | bắn sau khi thêm vào `rules:` |
  | `avoid_print` · `empty_catches` · `must_be_immutable` | file vi phạm tương ứng | cả ba bắn đúng |

- **Dependencies:** M2.2
- **Tests required:** none — cấu hình lint; acceptance criteria đã là lệnh kiểm.
  Ngoài ra đã kiểm chứng bằng tiêm lỗi như bảng trên, vì "analyze sạch" trên 3
  file nguồn không phân biệt được cấu hình đúng với cấu hình chết
- **Checklist phases:** 5.1

### M2.4 · Localization ARB foundation

- **Status:** done
- **Goal:** Dựng hạ tầng l10n để **không chuỗi hiển thị nào** phải hardcode từ
  task sau trở đi.
- **Scope:** `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`,
  `flutter: generate: true`, `localizationsDelegates`, `supportedLocales`,
  fallback locale.
- **Out of scope:** dịch đầy đủ. Chỉ cần đủ chuỗi cho smoke test.
- **Editable documents:** `docs/wbs.md`
- **Output:** `l10n.yaml`, `lib/l10n/*.arb`, wiring trong `app.dart`
- **Acceptance criteria:**
  - [x] `flutter gen-l10n` (hoặc `flutter pub get`) sinh `AppLocalizations`
        thành công. → exit 0; sinh `app_localizations.dart` + `_en` + `_vi`
  - [x] App hiển thị ít nhất một chuỗi lấy từ ARB, không hardcode. → màn
        placeholder dùng `context.l10n.homePlaceholderMessage`; hai literal cũ
        trong `app.dart` đã bị xoá
  - [x] `app_vi.arb` có đủ key của `app_en.arb`; thiếu key thì fail. → test đọc
        **thẳng file ARB**, không qua binding sinh ra
  - [x] Đặt locale không hỗ trợ → app rơi về locale mặc định, không hiện chuỗi
        rỗng. → test `ja` render chuỗi `en` và assert không có chuỗi rỗng
  - [x] Mỗi key trong ARB có `description`. → test khẳng định cho **cả hai** file
- **Ghi chú kỹ thuật, hai điều đáng nhớ:**
  1. **Test parity phải đọc file ARB, không đọc binding sinh ra.** gen-l10n
     fallback về template, nên `app_vi.arb` có thể mất key mà mọi widget test
     vẫn xanh trong khi người dùng tiếng Việt lặng lẽ đọc tiếng Anh. Chỗ duy
     nhất nhìn thấy khoảng trống đó là chính file ARB.
  2. **Đã viết `localeResolutionCallback` rồi bỏ đi.** Test chứng minh nó không
     đổi gì: resolution mặc định của Flutter đã fallback về
     `supportedLocales.first`. Giữ lại là một tầng thừa (`CLAUDE.md`). Hành vi
     fallback vẫn được test ghim.
  3. `intl` phải để constraint mở. `flutter_localizations` ghim `intl` ở một
     version chính xác, và pin tay ở `pubspec.yaml` gây xung đột resolution —
     đúng cái bẫy `dependencies.md` đã nêu. `pubspec.lock` mới là thứ bảo đảm
     build lặp lại được.
- **Dependencies:** M2.2
- **Tests required:** widget test dựng app ở `en` và `vi`, assert chuỗi lấy từ
  ARB; test parity key giữa hai file ARB — **đã có**, `test/l10n/`, 11 test pass
- **Checklist phases:** 12

### M2.5 · Flavor Android và entrypoint theo môi trường

- **Status:** done
- **Goal:** Ba flavor cài song song được trên một máy, mỗi flavor có config
  riêng.
- **Scope:** `EnvConfig`, `main_development.dart` / `main_staging.dart` /
  `main_production.dart`, `productFlavors` trong Gradle, `applicationIdSuffix`,
  `resValue` app name.
- **Out of scope:** signing key production, iOS scheme (AD-04 hoãn iOS), secret
  thật.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/config/env_config.dart`,
  `lib/app/config/env_config_provider.dart`, ba entrypoint,
  `android/app/build.gradle.kts` (Kotlin DSL, không tạo bản Groovy)
- **Acceptance criteria:**
  - [x] `flutter build apk --debug --flavor <f> -t lib/main_<f>.dart` exit 0 cho
        cả ba. → `app-development-debug.apk`, `app-staging-debug.apk`,
        `app-production-debug.apk`
  - [x] Ba APK có `applicationId` khác nhau — verify bằng `aapt dump badging`:

        | Flavor | package | label |
        |---|---|---|
        | development | `com.ntgptit.memox.dev` | `MemoX Dev` |
        | staging | `com.ntgptit.memox.staging` | `MemoX Staging` |
        | production | `com.ntgptit.memox` | `MemoX` |

  - [x] Ba APK cài song song được trên cùng một thiết bị/emulator. → cài cả ba
        lên emulator `Medium_Phone` (Android 16), `pm list packages` trả về
        **đồng thời** cả ba package ở trên
  - [x] `EnvConfig` được đọc qua provider bị override trong bootstrap; provider
        gốc throw khi thiếu override.
  - [x] Không có secret nào trong repo; `env/` nằm trong `.gitignore`. →
        `env/`, `.env`, `.env.*` đã có sẵn từ M2.1; `apiBaseUrl` của cả ba
        flavor đều là placeholder `.invalid`
- **Ghi chú kỹ thuật:**
  - `resValue` cần `buildFeatures { resValues = true }`. AGP hiện tại **tắt mặc
    định**, và flavor khai báo resource value mà không bật cờ này thì build
    **fail hẳn** với `custom resource values, but the feature is disabled` —
    không phải bỏ qua giá trị đó trong im lặng.
  - `apiBaseUrl` dùng TLD `.invalid` (RFC 2606 dành riêng, không bao giờ resolve
    được). Có chủ đích: nếu code gọi mạng trước khi backend được chốt, nó fail
    ngay ở DNS thay vì lặng lẽ chạm vào thứ gì đó có thật.
  - `Override` là sealed class nội bộ của `riverpod`, **không** nằm trong public
    API của `flutter_riverpod` — không chú thích kiểu cho list `overrides`.
  - Riverpod 3 bọc lỗi provider trong `ProviderException`, nên test khẳng định
    theo **nội dung thông báo** chứ không theo kiểu; `throwsStateError` fail.
- **Dependencies:** M2.1
- **Tests required:** unit test khẳng định ba `EnvConfig` có `apiBaseUrl`,
  `logLevel` và `appName` khác nhau; test provider gốc throw khi chưa override
  — **đã có**, `test/app/env_config_test.dart`, 6 test pass
- **Checklist phases:** 6.2

### M2.6 · Bootstrap, error boundary và cổng build ba mặt

- **Status:** done
- **Goal:** Một hàm `bootstrap()` duy nhất sở hữu khởi động, và không lỗi khởi
  động nào biến thành màn hình trắng.
- **Scope:** `bootstrap.dart` với thứ tự khởi tạo logging → config → storage →
  error boundary → `runApp` trong `ProviderScope`; `FlutterError.onError`,
  `PlatformDispatcher.instance.onError`, `ErrorWidget.builder` cho release.
- **Out of scope:** logging abstraction đầy đủ (M7), crash reporting (M8),
  khởi tạo database (M4.2 sẽ cắm vào đây).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/bootstrap.dart`, `lib/app/error_screen_widget.dart`
- **Acceptance criteria:**
  - [x] Ném exception trong `runApp` → hiển thị màn hình lỗi có nội dung, **không**
        phải màn trắng và **không** phải red screen mặc định ở release. →
        `runApp` bọc trong `try/on Object catch`; thất bại → `ErrorScreenWidget`
  - [x] Uncaught async error được bắt và log, app không crash. → cả
        `PlatformDispatcher.instance.onError` (trả `true` để nhận trách nhiệm)
        lẫn `runZonedGuarded`; mỗi cái bắt thứ cái kia bỏ sót
  - [x] `flutter build apk --debug --flavor <f>` exit 0 cho cả ba flavor.
  - [x] `flutter build web` exit 0 — cổng giữ kênh E2E còn sống (AD-04).
  - [x] `flutter analyze` → 0 error, 0 warning.
  - [x] `main.dart` và ba entrypoint không chứa logic khởi tạo nào. → có **test**
        quét source, cấm `runApp(`, `ProviderScope(`, `FlutterError.onError`,
        `ensureInitialized(` trong cả bốn file
- **Ba điều học được, đáng ghi vì tốn thời gian:**
  1. **Không gọi `bootstrap()` trong widget test.** Nó bọc startup trong
     `runZonedGuarded` rồi gọi `runApp`, trong khi `flutter_test` sở hữu zone và
     binding riêng — test **treo** chứ không fail, và `pumpAndSettle` mặc định
     chờ tới 10 phút trước khi bỏ cuộc. Đã tách `buildRootWidget(config)` ra để
     test mount đúng cây thật mà không đụng zone. Đây là lý do file này có
     `buildRootWidget`.
  2. **`AppLocalizations.maybeOf` không tồn tại** khi `nullable-getter: false`.
     Tra cứu an toàn phải qua `Localizations.of<AppLocalizations>(...)`, trả
     `null` thay vì assert. Quan trọng vì `ErrorScreenWidget` có thể phải thay
     cho một widget hỏng **phía trên** delegates — nếu nó cần Localizations thì
     nó sẽ throw trong lúc đang báo cáo một throw, và người dùng nhận màn trắng.
  3. **`ProviderScope.containerOf` cần context là con của scope.** Truyền chính
     element của `ProviderScope` → `No ProviderScope found`.
- **Dependencies:** M2.5, M2.4, M2.3
- **Tests required:** widget test cho `ErrorWidget.builder`; test `bootstrap()`
  gọi được với fake config và không throw — **đã có**,
  `test/app/bootstrap_test.dart`, 9 test pass, gồm test khẳng định
  `installErrorHandlers` **khôi phục** cả ba handler toàn cục và test khẳng định
  màn lỗi không lộ chi tiết kỹ thuật
- **Checklist phases:** 6.1

---

## M3 · Architecture and design foundation

Mục tiêu: dựng ranh giới layer và **đúng lượng** design foundation mà vertical
slice UC-05 cần. Không xây trọn design system trước khi có feature thật.

### M3.1 · Cấu trúc feature-first và ranh giới layer

- **Status:** done
- **Goal:** Tạo bộ khung thư mục và làm `check_architecture.sh` chạy có ý nghĩa
  trên code thật.
- **Scope:** `lib/app/`, `lib/core/`, `lib/shared/`, `lib/features/` theo Phase
  4.1; một feature `review` rỗng đúng cấu trúc để script có gì để kiểm.
- **Out of scope:** logic nghiệp vụ; thư mục `data/remote/` (AD-01 — chưa có
  network, không tạo thư mục rỗng).
- **Editable documents:** `docs/wbs.md`
- **Output:** cây thư mục `lib/`, `docs/architecture.md` **không** đổi
- **Acceptance criteria:**
  - [x] `check_architecture.sh` exit 0.
  - [x] Không tồn tại `lib/features/*/data/remote/`.
  - [x] Thêm một file vi phạm cố ý (domain import Flutter) → script exit 1; xoá
        đi → exit 0. → guard báo `memox.architecture.domain_no_infrastructure_import`,
        exit 1; xoá file → exit 0
  - [x] Mọi file trong `lib/` đặt tên theo suffix quy ước ở `CLAUDE.md`. → rule
        `naming.*_file_role_suffix` của guard nay **có target thật** và pass
  - [x] **Siết guard**: cả hai profile và `code-verification-guard.yaml` về
        `fail_on: [error, warning]` + `warning_as_error: true`. → guard báo
        `No violations found`, exit 0
- **Ba file khung, mỗi file một trách nhiệm rõ ràng:** `review_repository.dart`
  (contract, pure Dart), `review_repository_impl.dart` (implement nó), và
  `review_placeholder_screen.dart` — màn placeholder **chuyển từ `app.dart` vào
  feature**, nên nó có caller thật chứ không phải file giả để lấp chỗ. Contract
  cố ý rỗng: method được viết ở **M4.9** **từ nhu cầu của presentation**, đoán trước
  là viết code và test cho một lời gọi không tồn tại.
- **Phát hiện khi siết guard — ba rule đang bảo vệ tập rỗng.** Đây là lý do
  `rule_without_targets` **không được** bịt: nó không phải nhiễu chờ code tới.
  - `provider_files` khớp `lib/**/providers/**` và `*_controller.dart`, nhưng
    quy ước của dự án là provider nằm cạnh thứ nó cấu hình, tên `*_provider.dart`.
    Provider duy nhất đang có — `lib/app/config/env_config_provider.dart` —
    **không khớp gì cả**, nên `controller_no_build_context` và
    `notifier_no_public_mutable_field` bảo vệ một tập rỗng.
  - `single_database_connection_site` exclude một **đường dẫn literal** chưa tồn
    tại; đổi sang glob.
  - `scheduler_no_ambient_now` chỉ nhìn `domain/scheduler/**`, hẹp hơn tính chất
    nó bảo vệ: **mọi** code domain đọc đồng hồ môi trường đều không test được ở
    một thời điểm cố định. Mở rộng sang `domain_files`; scope `scheduler_files`
    thành vô dụng nên bị xoá thay vì để lại mục rữa dần.

  Hai rule SQL của Drift cũng được mở sang `dart_source`: SQL không chỉ nằm
  trong `.drift`, Drift còn nhận SQL thô qua `customStatement`/`customSelect`.

  Sửa ở **upstream** `ntgptit/code-verification-guard-v2` (PR #7, đã merge), rồi
  re-vendor bản **byte-identical** (`diff -r` sạch) — không sửa trong bản vendor.
- **Dependencies:** M2.6
- **Tests required:** none — kiểm chứng bằng fault injection ở acceptance
  criteria; **đã chạy**
- **Checklist phases:** 4.1, 4.2, 4.3, 5.3

### M3.2 · Core error và failure model

- **Status:** done
- **Goal:** Có một hệ `Failure` sealed để mọi lớp trên data nói cùng một ngôn
  ngữ lỗi.
- **Scope:** `core/error/failure.dart` (sealed class: Network, Unauthorized,
  Forbidden, Validation, NotFound, Conflict, Database, Cancelled, Unknown),
  `core/error/drift_error_mapper.dart`.
- **Out of scope:** `dio_error_mapper.dart` — chưa có network (AD-05).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/error/`
- **Acceptance criteria:**
  - [x] `Failure` là sealed class; `switch` trên nó không cần `default`. → test
        có một `switch` phủ đủ 9 nhánh, **không** `default`
  - [x] `ValidationFailure` mang `Map<String, String> fieldErrors`, mặc định
        rỗng để call site không phải null-check.
  - [x] `Failure.message` không chứa SQL, stack trace hay đường dẫn file — có
        test quét cả 9 loại với danh sách chuỗi cấm.
  - [x] Drift exception → `DatabaseFailure`, giữ nguyên gốc ở `cause`.
  - [x] `core/error/failure.dart` không import Flutter — có test đọc source.
- **Hai quyết định đáng ghi:**
  1. **Mapper vứt bỏ nguyên văn exception.** SQLite báo
     `UNIQUE constraint failed: decks.name` — tên bảng và tên cột. Có test
     khẳng định `message` **không** chứa `decks` hay `constraint`; bản gốc nằm
     ở `cause` cho log.
  2. **`Failure.message` không được localize, có chủ đích.** `domain/` và
     `core/` không import Flutter nên không với tới ARB. Đây là fallback an
     toàn; màn hình hiển thị lỗi SHOULD lấy copy từ ARB theo loại failure —
     việc đó thuộc màn đầu tiên thật sự hiện lỗi (M5.4), không phải một phỏng
     đoán đặt ở đây.
- **Dependencies:** M3.1
- **Tests required:** unit test bảng cho mapper Drift→Failure; test khẳng định
  không message nào lộ thông tin kỹ thuật — **đã có**, `test/core/error/`, 8 test
- **Checklist phases:** 6.3

### M3.3 · Riverpod foundation

- **Status:** done
- **Goal:** Có khuôn provider chuẩn để mọi task sau viết giống nhau.
- **Scope:** `ProviderScope` trong bootstrap, quy ước `@riverpod` codegen, một
  provider hạ tầng thật, `ProviderContainer` helper cho test.
- **Out of scope:** provider của feature — thuộc M5.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/helpers/container.dart`. **Không** tạo `lib/core/providers/`:
  provider hạ tầng duy nhất — `envConfigProvider` — đã tồn tại từ M2.5 tại
  `lib/app/config/env_config_provider.dart`, nằm cạnh thứ nó cấu hình. Di
  chuyển nó chỉ để khớp một đường dẫn viết trước khi code tồn tại là đổi lấy
  rủi ro mà không được gì; WBS được sửa theo code, không ngược lại.
- **Acceptance criteria:**
  - [x] `dart run build_runner build` sinh provider sạch; lần chạy thứ hai
        `wrote 0 outputs`, không sinh diff.
  - [x] Provider dùng `Ref` (Riverpod 3), **không** dùng `*Ref` sinh riêng. →
        rule `no_generated_ref_subclass` của guard enforce điều này
  - [x] `makeContainer()` trong `test/helpers/` tự `addTearDown(dispose)`.
  - [x] Test khẳng định `envConfigProvider` throw khi chưa override, và trả
        đúng config khi được override (M2.5 đã có, vẫn pass).
- **Cách chứng minh `addTearDown` thật sự chạy:** không quan sát được từ trong
  chính test tạo container, vì dispose xảy ra sau khi thân test kết thúc. Nên
  một test giữ lại tham chiếu, và **test kế tiếp** khẳng định đọc nó thì throw.
  Nếu quên `addTearDown`, lần đọc đó sẽ im lặng thành công.
- **Một giới hạn của thư viện, đã ghi lại:** `makeContainer` **không** có tham
  số `overrides`. Kiểu `Override` của Riverpod không được export bởi `riverpod`
  lẫn `flutter_riverpod`, nên không hàm nào khai báo được nó trong chữ ký. Test
  cần override thêm thì tự dựng `ProviderContainer` và tự `addTearDown` — đã ghi
  kèm ví dụ trong doc comment của helper.
- **Dependencies:** M3.1, M2.6
- **Tests required:** unit test cho provider hạ tầng và cho helper container —
  **đã có**, `test/helpers/container_test.dart` 4 test + `test/app/env_config_test.dart`
- **Checklist phases:** 9.1

### M3.4 · Design tokens

- **Status:** done
- **Goal:** Mọi giá trị hình thức có tên, để feature không hardcode.
- **Scope:** `core/theme/app_spacing.dart`, `app_radius.dart`,
  `app_icon_size.dart`, `app_durations.dart`, `app_breakpoints.dart`,
  `app_colors.dart` (seed + semantic), `app_typography.dart`.
- **Out of scope:** component (M3.6), animation phức tạp.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/`
- **Acceptance criteria:**
  - [x] Token dùng `abstract final class`, không instantiate được — có test đọc
        source cho cả 7 file.
  - [x] Spacing đúng thang 4 / 8 / 12 / 16 / 24 / 32, không có giá trị ngoài
        thang. → test khẳng định `scale` đúng, tăng nghiêm ngặt, và **mọi hằng
        khai báo đều nằm trên thang** — chặn đúng cái nó sinh ra để chặn: một
        hằng thứ bảy lệch thang thêm lặng lẽ cho một màn hình
  - [x] Tên token là semantic (`danger`), không phải vật lý (`red`). → test quét
        tên hằng `Color` với danh sách từ vật lý
  - [x] `grep -rE 'Colors\.[a-z]|Color\(0x' lib/features lib/shared` không có
        kết quả — guard rule `design_token.no_raw_color` enforce, exit 0
  - [x] `grep -rn 'TextStyle(' lib/features` không có kết quả — guard rule
        `design_token.no_raw_text_style` enforce, exit 0
- **Phong cách:** Professional Learning Minimalism — một sắc violet-indigo duy
  nhất mang nhận diện, còn lại gần trung tính, để nội dung thẻ là thứ duy nhất
  tranh sự chú ý. Màu dark **không** phải màu light tối đi: trên nền tối, một
  màu bão hoà đọc ra sáng hơn chính nó trên nền trắng, nên từng màu được làm
  nhạt và giảm bão hoà để giữ contrast tương đương mà không bị chói.
- **Nguồn giá trị màu: ảnh tham chiếu chủ dự án chọn, sample từng pixel.**
  Không phỏng theo bằng mắt, không lấy nguyên một scheme Material. Bảng dark
  được đo trực tiếp; bảng light **suy ra từ dark** — giữ nguyên hue, soi gương
  thang lightness — chứ không chọn riêng. Đó là thứ giữ cho hai mode là **một
  sản phẩm** thay vì hai thiết kế tình cờ ship cùng nhau.
- **Thang surface ba tầng, không phải hai.** Tham chiếu tách bạch trang / card /
  ô lồng, và chính bậc thứ ba mới cho một chip hay một icon container đọc ra là
  nổi lên mà không cần đổ bóng. Hai tầng buộc mọi phần tử lồng phải mượn màu
  card rồi tan vào nó.

  | | Trang | Card | Ô lồng |
  |---|---|---|---|
  | Dark | `#0A082D` | `#201F3E` | `#2E3756` |
  | Light | `#F6F6FB` | `#FFFFFF` | `#EAEAF6` |

- **Bài học đo được, ngược với trực giác.** Nền tham chiếu `#0A082D` có luminance
  0.004 — **tối hơn** bản `#232225` từng bị chê là "quá tối", và card của họ sáng
  đúng bằng nền của bản đó. Nó vẫn dễ nhìn hơn vì hai lý do không liên quan tới
  độ sáng tuyệt đối: **hue navy bão hoà** đọc ra là sâu chứ không phải trống
  (đen trung tính đọc ra như một sự vắng mặt), và **khoảng cách nền↔card rộng
  hơn** (1.22× so với 1.10×). Thứ làm một card đọc ra là card là *bậc thang*,
  không phải *độ cao*.
- **Chữ không dùng đầu mút thuần.** `#EDECFE` thay vì trắng, `#17162D` thay vì
  đen: trên nền bão hoà một giá trị thuần bị rung, còn mang theo chút hue của
  surface là thứ làm chữ **nằm trong** giao diện chứ không dán lên trên.
- **Nút hành động ở dark là *tầng bề mặt thứ tư*, không phải một vật thể có
  màu.** Thang của tham chiếu là page 0.004 → card 0.016 → tile 0.040 → action
  0.125 (luminance), mỗi bậc gấp khoảng 2.5 lần bậc trước, **cùng một họ trung
  tính**. Nút dựng theo cách đó đọc ra là đỉnh của chồng bề mặt chứ không phải
  một mảng màu — nhờ vậy **mọi sắc bão hoà được để dành cho ý nghĩa**. Điều này
  quan trọng đúng ở đây: nút review sẽ được mã màu `forgotten`/`remembered`, và
  một CTA mang màu thương hiệu ngồi cạnh chúng sẽ tranh chấp với đúng hai màu
  đang mang quyết định.

  Light **không** dùng được thủ pháp đó: trắng đã là đỉnh thang, không còn bậc
  nào phía trên card để đẩy nút lên. Ở đó màu thương hiệu làm việc này. Sự bất
  đối xứng là cố ý — quy tắc là "hành động là bề mặt nổi bật nhất", còn *nổi bật*
  được tạo ra bằng cách khác nhau ở hai đầu thang.

  Có test khẳng định **thứ tự** bốn bậc ở dark (không khẳng định giá trị, để
  palette sau còn đổi được), và khẳng định nhãn trên nút đạt ≥ 4.5:1 ở cả hai
  theme. Màu nút được đọc **từ theme** chứ không từ token, nên test sẽ fail nếu
  nút thôi dùng thứ palette dành cho nó.
- **Nhãn nút phụ (outlined) có token riêng, không dùng chung `primary`.** Một
  màu không gánh được hai vai. Material 3 bắt `primary` vừa làm **nền** vừa làm
  **chữ trên nền tối**, và ở dark hai vai kéo ngược nhau: sửa nền cho hết chói
  đã đẩy nhãn xuống **3.09:1 trên nền trang** và **2.53:1 trên card** — không
  đọc được, chứ không chỉ là xấu.

  Dark dùng đầu sáng trung tính, đồng thời giữ đúng quy tắc mà nút hành động
  theo: sắc bão hoà để dành cho ý nghĩa. Light dùng màu thương hiệu, nơi nó đủ
  tương phản để xứng đáng.

  **Lỗ hổng đã để lọt lỗi này:** mọi test contrast trước đó kiểm một *nền* hoặc
  một màu trong *text theme*, **không** cái nào kiểm thứ `OutlinedButton` thật
  sự vẽ ra. Test mới đọc màu từ theme và kiểm trên **cả** nền trang lẫn card —
  card là nền khắc nghiệt hơn ở dark. Đã tiêm lại màu cũ để xác nhận test fail
  đúng ở `3.09`.
- **`primary` ở dark bị override khỏi mặc định Material 3.** M3 đặt dark
  `primary` ở tone 80 — một sắc lavender gần pastel, **luminance 0.565**, tức
  sáng hơn nửa màu trắng thuần. Đúng cho vai trò M3 giả định (chữ và icon trên
  nền tối) và **sai** cho vai trò app này dùng (nền của một nút lớn): trên trang
  luminance 0.004 nó chói, kéo mắt khỏi thẻ từ vựng, và chữ trắng trên nó chỉ
  đạt **1.71:1** — dưới mọi ngưỡng đọc được.

  Dùng chính seed hạ nền nút xuống luminance 0.118 và nâng chữ trắng lên 6.25:1.
  Có test ghim cả hai: `primary` dark phải dưới luminance 0.25, và `onPrimary`
  trên `primary` phải ≥ 4.5:1 ở **cả hai** theme.
- **Focus của ô nhập đổi *hue*, không đổi độ dày.** Material mặc định nhảy 1px →
  2px, làm ô nhảy và đẩy mọi thứ bên cạnh. Giữ nét 1.5 ở **mọi** trạng thái và
  chuyển màu sang `focusRing` (periwinkle `#A8B1FF` ở dark) — đây chính là điểm
  chủ dự án chỉ ra. Có test khẳng định độ dày và bo góc **không đổi** giữa hai
  trạng thái, còn màu thì phải đổi.
- **Lần chọn `iris` trước đó là một sai lầm đáng ghi lại:** `iris-9` = `#5b5bd6`,
  lệch đúng **15/255** so với indigo cũ. Đổi bậc trong cùng một họ thì mắt không
  phân biệt được — muốn thấy khác thì phải đổi **họ màu**, và phải đụng tới cả
  neutral chứ không chỉ màu nhấn.
- **Font (bổ sung sau M3.6):** hai họ, mỗi họ làm việc nó giỏi.
  **Plus Jakarta Sans** cho display/title — hình học pha humanist, để một từ vựng
  đặt lớn đọc ra như có thiết kế thay vì như chữ hệ thống mặc định; đây là chữ
  ký thị giác duy nhất của app. **Inter** cho body/UI — vẽ riêng cho màn hình,
  x-height cao, `l`/`I`/`1` phân biệt được, đúng thứ một định nghĩa đọc ở 14sp
  trên điện thoại cần.

  **Bundle vào repo** (`assets/fonts/`, kèm OFL) chứ không dùng `google_fonts`:
  app học tập phải render y hệt khi offline, và package đó thêm một dependency
  cùng một lần tải mạng ở lần chạy đầu cho thứ không bao giờ đổi.

  Cả hai là **variable font** — Google Fonts không còn ship bản static cho hai họ
  này. `fontWeight` một mình **không** dịch chuyển trục `wght` một cách nhất quán
  giữa các renderer, nên trọng số được đặt thêm qua `fontVariations`, và
  `fontWeight` vẫn giữ đồng bộ để công cụ a11y và `copyWith` đọc đúng giá trị.
- **Dependencies:** M3.1
- **Tests required:** unit test khẳng định thang spacing và bộ token bắt buộc
  tồn tại — **đã có**, `test/core/theme/design_tokens_test.dart`, 7 test
- **Checklist phases:** 7.1

### M3.5 · Light theme và dark theme

- **Status:** done
- **Goal:** Hai theme Material 3 hoàn chỉnh cho phạm vi UC-05.
- **Scope:** `buildLightTheme()`, `buildDarkTheme()`, `ColorScheme.fromSeed`,
  `AppSemanticColors` dạng `ThemeExtension`, component theme cho AppBar, Card,
  FilledButton, OutlinedButton, Snackbar.
- **Out of scope:** theme cho Dialog, BottomSheet, Chip, Input — chưa dùng ở
  UC-05.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/app_theme.dart`,
  `lib/core/theme/app_semantic_colors.dart`,
  `lib/core/theme/theme_context_extension.dart`
- **Acceptance criteria:**
  - [x] `useMaterial3: true` ở cả hai theme.
  - [x] `AppSemanticColors` có `lerp` và `copyWith` đúng, đăng ký ở `extensions`.
        → test so **từng field** với `Color.lerp` thay vì spot-check một màu:
        một field bị bỏ quên trong `lerp` sẽ giật khi đổi theme, và chỉ nhìn
        thấy trên đúng màn hình dùng nó
  - [x] Contrast text chính ≥ 4.5:1 ở cả hai theme — **tính bằng công thức WCAG**,
        không phải mắt thường. Hàm contrast được **hiệu chuẩn trước** khi tin
        (đen trên trắng = 21:1, màu trên chính nó = 1:1) rồi mới đem chấm palette
  - [x] Trạng thái disabled, pressed và focused đều có style ở button.
  - [x] `context.colors` / `context.texts` / `context.semanticColors` là
        extension duy nhất trên `BuildContext`. `semanticColors` **throw** khi
        thiếu extension thay vì trả mặc định — mặc định im lặng sẽ vẽ sai màu
        trên màn hình không ai kiểm lại
- **Một điểm lệch so với đề bài, có lý do:** `MemoxApp` **không** truyền
  `themeMode: ThemeMode.system` tường minh. Đó đúng là mặc định của
  `MaterialApp`, nên viết ra sẽ kích `avoid_redundant_argument_values` — lint mà
  chính dự án này promote lên `error` ở M2.3. Suppress lint của chính mình để
  nhắc lại một mặc định là đánh đổi tệ hơn. Hành vi được **ghim bằng test**
  (`app.themeMode == ThemeMode.system`), nên việc bỏ vẫn là cố ý chứ không thành
  tai nạn.
- **Dependencies:** M3.4
- **Tests required:** unit test contrast ratio cho cặp màu chính ở hai theme;
  widget test dựng cùng widget ở light và dark không throw — **đã có**,
  `test/core/theme/app_theme_test.dart`, 17 test
- **Checklist phases:** 7.2

### M3.5a · Review và tái hiệu chỉnh color system

- **Status:** done — candidate **A · Slate Indigo** đã được duyệt và áp
- **Goal:** Đánh giá lại **chiến lược** màu trên màn hình render thật, thay vì
  tiếp tục sửa từng mã hex.
- **Scope:** audit; ba candidate đầy đủ role; harness render; chấm điểm; áp
  candidate được duyệt.
- **Out of scope:** typography, spacing, radius, component structure, router,
  Drift.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/review/` (harness + 8 ảnh), và sau khi duyệt:
  `lib/core/theme/{app_colors,app_semantic_colors,app_theme}.dart`,
  `test/core/theme/`, 22 golden của shared widgets
- **Acceptance criteria:**
  - [x] Audit chỉ ra vấn đề ở **cấp hệ thống**, không chỉ nhận xét từng mã hex.
  - [x] Ba candidate, mỗi cái đủ 15 role × 2 brightness.
  - [x] 8 ảnh cùng viewport / typography / spacing / radius / locale / dữ liệu.
  - [x] Bảng điểm 9 tiêu chí. A 43 · C 41 · B 36 · baseline 26.
  - [x] Chủ dự án duyệt A và giao lại quyết định CTA.
  - [x] **Mọi role của `ColorScheme` được khai báo** — 40 role × 2 brightness.
        `fromSeed` không còn quyết định bất cứ thứ gì.
- **Phát hiện lớn nhất của audit:** chỉ **6 trên ~30** role đang được kiểm soát.
  Phần còn lại `fromSeed` sinh ở **họ màu khác**: thang `surfaceContainer*` ở
  dark là **xám trung tính** (S 9–15%) trong khi app là navy S 70%; `tertiary`
  là **hồng** (H 328); `error` là hệ đỏ **thứ hai** cạnh tranh với `danger`;
  `surfaceTint` vẫn giữ đúng sắc lavender chói đã bị gỡ khỏi `primary`. Chưa lộ
  vì MVP chưa có Dialog, BottomSheet, NavigationBar, Menu hay Chip — **sẽ lộ
  ngay ở Library/Settings/Statistics**, lúc sửa đắt hơn nhiều.
- **Vì sao chọn canvas trung tính.** Đây là app mở **mỗi ngày**, vài phút, suốt
  nhiều tháng. Trên chân trời đó thứ quan trọng không phải ấn tượng đầu mà là
  **không gây mỏi**, nên không có mảng bão hoà nào nằm ở vùng ngoại vi thị giác:
  canvas graphite S 6–16%, đúng một điểm nhấn indigo muted. Palette bị thay phủ
  navy bão hoà lên **mọi** bề mặt — bắt mắt ở ảnh chụp đầu, mệt ở phiên thứ ba.
- **CTA ở dark là tầng bề mặt cao nhất, không mang màu** (`surfaceElevated`).
  Để dành trọn ngân sách màu cho `forgotten`/`remembered` ở M5.4 — một CTA mang
  màu thương hiệu ngồi cạnh hai nút đó sẽ tranh chấp với chính hai màu đang mang
  quyết định của người dùng. Light không làm được vậy (trắng đã là đỉnh thang)
  nên dùng màu thương hiệu.
- **Ngân sách chroma cho semantic:** `danger` cao nhất (báo động), `info` thấp
  nhất (chỉ báo), không màu nào chạm bão hoà tối đa — cao nhất 62%. Bản trước có
  `warning` S=100% ở **cả hai** mode.
- **Hai điều chỉnh trong lúc áp:** `surfaceElevated` ở dark nâng từ L28 lên L34
  vì nút chỉ tách khỏi card **1.49×** (tham chiếu tách 2.64×) — nâng ngưỡng chứ
  không hạ test. Và `app_theme_test.dart` vượt 400 dòng nên tách phần kiểm hành
  vi `ThemeExtension` sang file riêng; hai file trả lời hai câu hỏi khác nhau.
- **Dependencies:** M3.5
- **Tests required:** none mới — bộ test contrast hiện có phủ toàn bộ; thêm
  kiểm `surfaceTint`/`surfaceBright`/`surfaceContainerHighest` không được trở
  thành nguồn sáng ở dark, vì lần trước chỉ kiểm `primary` và bỏ lọt
  `surfaceTint`
- **Checklist phases:** 7.2

### M3.5b · Áp A2 Quizlet Navy Indigo

- **Status:** done
- **Goal:** Giữ nền navy sâu của giao diện tham chiếu, nhưng dựng lại thang bề
  mặt phía trên nó để flashcard nổi rõ mà không cần shadow.
- **Scope:** thang bề mặt 4 tầng; primary indigo cho cả hai mode; secondary
  action trung tính; verdict idle/selected; ngân sách chroma; light mode suy ra
  từ dark; **46 role** của `ColorScheme` khai báo tường minh; harness render lại
  ba màn hình thật.
- **Out of scope:** typography, spacing, radius, component structure, router,
  Drift, M4.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/{app_colors,app_theme}.dart`,
  `test/core/theme/{color_math,theme_probe,app_palette_test,color_scheme_roles_test}.dart`,
  `test/review/` (harness + 6 ảnh), 22 golden của shared widgets
- **Acceptance criteria:**
  - [x] `backgroundDark` giữ `#0A082D`. Không graphite hoá dark canvas.
  - [x] Bốn tầng phân biệt bằng lightness, **không** bù bằng shadow.
  - [x] Mọi surface có saturation ≤ 60% saturation của page.
  - [x] `onPrimary/primary` ≥ 4.5:1 ở cả hai mode. Primary hai mode cùng hue 240.
  - [x] Secondary action trung tính (S ≤ 20%), không phải primary, không semantic.
  - [x] Verdict idle: nền tile trung tính + viền semantic. Selected: fill nhẹ.
  - [x] `danger` chroma cao nhất, `info` thấp nhất, đỉnh 67.8% (không màu nào 100%).
  - [x] Light canvas chroma ≤ 6% — không nhiễm lavender.
  - [x] **46/46 role** đều là token của palette; không role nào ngoài họ màu A2.
- **Vì sao thang bề mặt đo bằng L\* chứ không bằng contrast ratio.** Page navy
  sâu nằm ở luminance **0.004**, và ở đáy thang hằng số `+0.05` của WCAG nén mọi
  bước thật thành "1.1 gì đó": card sáng **gấp 3 lần** page mà vẫn chỉ chấm
  **1.17:1**. Ngưỡng cũ `> 1.25` sẽ loại đúng một palette đang tốt. L\* là thang
  cảm nhận và không nói dối ở đáy — ba bước dark là **7.70 / 7.41 / 7.28 L\***.
- **Điều test bắt được mà audit trước bỏ lọt:** `fromSeed` sinh `tertiaryFixed`
  ở **hue 329 — hồng**. Họ `*Fixed` chưa được component Material nào đọc, đúng
  cái lý do từng để `tertiary` hồng nằm đó không ai thấy. Nay cả 12 role `*Fixed`
  được khai báo (giá trị light cho cả hai theme, vì "fixed" nghĩa là không đổi
  theo brightness).
- **CTA ở dark đổi hướng so với M3.5a:** dùng **indigo**, không dùng
  `surfaceElevated` trung tính nữa — quyết định của chủ dự án. Ngân sách màu vẫn
  được bảo vệ, nhưng bằng cách khác: `secondaryAction` giữ trung tính, nên trên
  màn review chỉ có đúng hai mảng bão hoà là `forgotten` và `remembered`.
- **Fault injection:** đặt `surfaceDark` gần page (`#0F0C3A`) làm ba assertion
  fail đúng chỗ — bước L\* còn 2.19, và saturation card 65.7% vượt trần 41.9%.
- **Dependencies:** M3.5a
- **Tests required:** thang bề mặt theo L\*; saturation surface so với page;
  primary không vượt độ sáng và không lấn át nội dung card; secondary action
  trung tính; ngân sách chroma; light canvas không nhiễm; **mọi role thuộc
  palette** và thuộc họ màu A2
- **Checklist phases:** 7.2

### M3.5c · Visual audit harness dùng chung

- **Status:** done
- **Goal:** Đo được **màu màn hình thật sự sơn ra**, thay vì đo token rồi tin
  rằng UI dùng đúng token đó.
- **Scope:** `test/visual_audit/` — model, extractor registry, phân loại render
  node, raster capture, rule, report; `test/support/` gom `color_math` và danh
  sách token đang bị nhân bản; nối vào ba màn hình preview.
- **Out of scope:** overlay image, integration test trên thiết bị, M4.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/visual_audit/*.dart` (7 file), `test/support/app_palette.dart`,
  `test/visual_audit/audit_core_test.dart`, audit gắn vào 3 preview screen
- **Acceptance criteria:**
  - [x] Foreground đọc từ `RenderParagraph`, **merge style theo nhánh
        `InlineSpan`** — không đọc từ `ThemeData`.
  - [x] Fill/border đọc từ `RenderDecoratedBox`/`RenderPhysicalShape`/
        `RenderPhysicalModel`/`RenderImage`.
  - [x] Raster đọc một lần, `pixelRatio: 1`, **trừ origin của boundary** khi map
        toạ độ.
  - [x] Node không nhận diện được → **báo cáo**, không im lặng.
  - [x] Contrast 4.5/3.0 cho text, 3.0 cho non-text mang thông tin.
  - [x] Palette closure; blend của hai token được chấp nhận.
  - [x] 10 self-test, mỗi khẳng định có một cặp làm nó fail.
- **Vì sao không đọc màu từ `ThemeData`.** Đó chính là lỗi đã ship: test đọc
  token, `OutlinedButton` sơn màu khác, nhãn ra 3.09:1, mọi test xanh. `ButtonStyle
  .foregroundColor.resolve(states)` bắt phải **đoán** `states` và đọc từ style
  *mình nghĩ* widget đang dùng — trong khi widget có thể nhận style từ theme, từ
  tham số, hoặc từ `styleFrom`.
- **Vì sao vẫn cần raster.** `Ink` và `InkFeature` được vẽ **lên `Material`**,
  không tồn tại như render node. `overlayColor` của `_buttonStyle` (pressed 12%,
  focused 10%) vì thế **không có render object nào để đọc**. Audit thuần render
  tree sẽ báo nút pressed giống hệt nút idle và báo xanh.
- **Giới hạn đã biết:** `flutter_test` đặt `debugDisableShadows = true`, nên mọi
  capture ở đây là màn hình **không có shadow**. Vô hại với A2 vì thang bề mặt tự
  gánh hierarchy, nhưng màn nào dựa vào elevation sẽ khác trên thiết bị.
  Ngoài ra `RenderEditable`, `_RenderDecoration` và `_ShapeBorderPainter` là
  raster-only — **viền input và viền `OutlinedButton` không đọc được** từ render
  tree.
- **Lỗi thật harness bắt được ngay lần chạy đầu:** nhãn semantic trên verdict
  selected ở **4.23:1** (dark) và **4.40:1** (light). Nhãn và fill cùng hue nên
  mỗi điểm alpha ăn vào contrast của nhãn; hạ state layer 18% → **6%**, để
  selection dựa vào độ dày viền. Không test token nào bắt được, vì không token
  nào mang giá trị đã blend.
- **Dependencies:** M3.5b
- **Tests required:** self-test cho từng extractor kèm fault injection; raster
  thấy được ink overlay; rule pass ở 21:1 và fail ở 1:1; blend của hai token
  không bị coi là màu lạ; audit chạy trên cả ba màn hình preview, light và dark
- **Checklist phases:** 7.2, 14.1

### M3.5d · Visual audit core correctness hardening

- **Status:** done
- **Goal:** Sửa bốn chỗ audit core v1 có thể **báo xanh sai**. Đây là corrective
  hardening cho M3.5c, không phải tính năng mới.
- **Scope:** palette closure tách declared/raster; traversal policy prune subtree
  không được sơn; `AuditStatus` ba mức; scoped allowance; coverage summary;
  dispose order của raster; đổi tên `occluded` thành finding trung thực.
- **Out of scope:** state matrix đầy đủ, pressed/focused/disabled cho màn
  production, overlay image, integration test trên thiết bị, shadow fidelity,
  extractor SVG/ImageIcon, **palette production**, **component production**,
  **golden chính thức**, M4.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/visual_audit/{audit_model,audit_rules,audit_report,screen_auditor,audit_raster,memox_audit}.dart`,
  ba file self-test mới, `test/review/` chuyển sang scoped allowance
- **Acceptance criteria:**
  - [x] Declared color **chỉ** exact token mới pass. Blend của hai token **fail**.
  - [x] Raster: exact token pass, blend hợp lệ pass, còn lại report non-blocking.
  - [x] `Offstage(true)`, `Opacity(0)` và subtree ngoài capture bị prune, **không**
        tính vào skip.
  - [x] Transform kéo child vào tầm nhìn **không** bị prune nhầm.
  - [x] `PASS` / `PASS_WITH_UNRESOLVED` / `FAIL`, report bắt đầu bằng status.
  - [x] Allowance scoped theo `itemId` + `reason` + `detailContains` + rationale.
  - [x] Unused allowance được report và chặn `complete`.
  - [x] `image.width/height` đọc **trước** `dispose()`.
  - [x] 34 self-test trong `test/visual_audit/`, mỗi hành vi có cặp positive/negative.
- **Lỗ hổng lớn nhất đã bịt:** `_isBlendOfTokens()` chạy **trước** khi phân biệt
  declared với raster, nên một màu hardcode tại call site vẫn pass nếu nó tình cờ
  nằm trên đoạn nối hai token. Với 40 token, các đoạn đó phủ khá nhiều không gian
  màu. Rule khi đó **chứng nhận** màu hardcode là on-palette — đúng loại dấu tick
  xanh không phủ gì.
- **Vì sao prune phải cẩn thận với transform:** `RenderTransform` không xuất hiện
  trong `getTransformTo` của chính nó, nên rect của nó là rect **chưa biến đổi**.
  Prune theo rect của ancestor sẽ bỏ mất một widget đang hiển thị rõ ràng — và
  audit sẽ im lặng, tức là báo xanh. Chỉ prune khi node **clip** children.
- **Vì sao đổi tên `occluded`:** vật thể che chỉ là **một** cách giải thích;
  một surface con phủ phần lớn rect của cha cho ra cùng số liệu. Nay là
  `declaredRasterMismatch` (đủ phẳng để kết luận) và `rasterNotFlat` (không đủ
  dữ liệu — report unresolved thay vì đoán).
- **Hệ quả trên preview:** `VerdictAction` selected đang dùng `Color.alphaBlend`
  — một màu không thuộc palette nào. Chuyển sang `secondaryContainer` (token) +
  viền dày hơn. Đây là code preview trong `test/`, không phải component
  production.
- **Dependencies:** M3.5c
- **Tests required:** palette closure 6 case (declared exact/blend/hardcode,
  raster exact/blend/ngoài palette); traversal 7 case kèm transform trap; status
  và hai mode expectation; allowance scope, detail matcher, unused; raster
  dispose order
- **Checklist phases:** 7.2, 14.1

### M3.5e · Visual audit anchor, clip và allowance correctness

- **Status:** done
- **Goal:** Sửa năm lỗi correctness còn lại trước khi `expectAuditComplete()` có
  thể dùng làm production gate. Corrective task cho M3.5d.
- **Scope:** resolve anchor lặp; phát hiện anchor collision; truyền effective
  clip qua traversal; siết validation của allowance; giữ cặp allowed skip ↔
  allowance kèm rationale; sửa số task trong WBS.
- **Out of scope:** state matrix, pressed/focused/disabled, raster diff theo
  state, overlay image, extractor SVG/ImageIcon, shadow fidelity, integration
  test, **palette production**, **component production**, **`lib/`**,
  **golden**, M4.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/visual_audit/{audit_model,audit_report,screen_auditor}.dart`,
  `audit_anchor_test.dart` (mới), `audit_traversal_test.dart`,
  `audit_status_test.dart`
- **Acceptance criteria:**
  - [x] Anchor khớp nhiều widget **không** còn sinh `anchorNotFound` giả.
  - [x] Hai anchor cùng trỏ một render object → `anchorCollision`, không ghi đè
        âm thầm; strict mode không đạt PASS.
  - [x] Traversal mang `effectiveClip` từ ancestor xuống child.
  - [x] `Clip.none` **không** thu hẹp clip; `Clip.hardEdge` và viewport thì có.
  - [x] Transform kéo child vào tầm nhìn không bị prune; kéo ra ngoài thì bị.
  - [x] `detailContains` bắt buộc; itemId / detailContains / rationale không
        được rỗng hoặc chỉ whitespace.
  - [x] 0 allowance → unresolved · 1 → allowed · >1 → **ambiguous**, chặn
        `complete`.
  - [x] Allowed entry giữ cả skip lẫn allowance; text report và JSON in
        rationale và `detailContains`.
  - [x] 55 self-test trong `test/visual_audit/`.
- **Lỗi anchor lặp:** owner ID được sinh thành `verdict[0]`…`verdict[3]`, nhưng
  kiểm tra "đã match chưa" lại tìm `owners.values.contains('verdict')` — luôn
  false. Audit báo "matched no widget" về một anchor đã match **bốn** widget.
  Nay resolver trả về `matchedAnchorIds` riêng, không suy từ ID đã index.
- **Vì sao effective clip:** một node nằm trong capture rectangle vẫn có thể bị
  `ClipRect` ở giữa cây che hoàn toàn. Kiểm từng node với capture rect thôi sẽ
  báo màu cho những pixel chưa từng được vẽ.
- **Giới hạn đã ghi:** với `ClipOval`, `ClipPath` và `ClipRect` có clipper, core
  dùng **bounding rect** — là **superset** của vùng thật. Đủ để prune subtree
  nằm hoàn toàn ngoài, và **cố ý** không đủ để kết luận thứ nằm trong bounding
  box là hiển thị. Trường hợp không chắc thì giữ node và đo, không prune.
- **Ghi chú về số task:** brief yêu cầu sửa thành "Mười task đóng"; sau khi đóng
  M3.5e thì danh sách có **mười một** mục, nên summary ghi mười một.
- **Dependencies:** M3.5d
- **Tests required:** anchor 1/4/0 match, collision, collision chặn strict;
  clip ngoài/một phần/trong, `Clip.none` overflow, `Clip.hardEdge`, viewport,
  transform hai chiều; allowance rỗng và whitespace bị reject, ambiguous, allowed
  pairing, rationale trong text report và JSON
- **Checklist phases:** 7.2, 14.1

### M3.5f · Clip hỏi Flutter, visible rect, và cardinality của allowance

- **Status:** done
- **Goal:** Bịt lỗ hổng cuối còn tạo được **green giả**: audit prune một widget
  mà Flutter đang sơn. Corrective task cho M3.5e.
- **Scope:** thay type-based clip policy bằng `describeApproximatePaintClip`;
  đo bằng `visibleRect`; validate namespace anchor ID; `expectedMatches` cho
  allowance; thêm `unused` vào dòng summary.
- **Out of scope:** state matrix, overlay image, extractor SVG/ImageIcon,
  integration test, **palette production**, **component production**, **`lib/`**,
  **golden**, M4, **CI (M7)**.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/visual_audit/{traversal_policy,screen_auditor,audit_allowance,audit_report,audit_model}.dart`,
  ba file tách mới (`raster_cross_check`, `marker_probe`, `audit_clip_test`,
  `audit_allowance_test`), `test/review/deck_list_preview_test.dart`
- **Acceptance criteria:**
  - [x] Clip lấy từ `describeApproximatePaintClip(child)`, hỏi **theo từng child**.
  - [x] `Stack`/`Flex` `hardEdge` **không** overflow → không clip.
  - [x] `visibleRect = rect ∩ clip` dùng cho extractor, raster, paint rect.
  - [x] Anchor ID: cấm rỗng, cấm trùng, cấm `screen`, cấm dạng `name[i]`.
  - [x] `expectedMatches` mặc định 1; lệch **hai chiều** đều report và chặn
        `complete`.
  - [x] Dòng summary có `unused` và `miscounted`.
  - [x] Fault injection: khôi phục policy cũ làm đúng test P0 fail.
- **Green giả đã bịt được, đo bằng probe:**
  `Stack` mặc định `Clip.hardEdge`, **không** overflow, bên trong có `Transform`
  vẽ ra ngoài → `describeApproximatePaintClip` trả **null** (Flutter không clip),
  nhưng audit cũ vẫn prune. Một widget **đang được sơn** bị bỏ **im lặng**.
  Nguyên nhân: `RenderStack.paint` chỉ push clip khi **layout** thấy visual
  overflow, mà layout chỉ nhìn positioned children.
- **Vì sao 68 self-test cũ không bắt được:** test `Stack(hardEdge)` dùng
  `Positioned(left: 100)` trong stack 50×50 — tức **có** overflow thật, Flutter
  clip thật, test pass **đúng lý do**. Nó chỉ phủ một nửa không gian.
- **Phản biện một phần của review:** `describeApproximatePaintClip` **không**
  phản ánh vùng thật của custom clipper. Đo được: `ClipRect` với clipper thu về
  10px vẫn trả **50px** (toàn bộ node). API là xấp xỉ **theo hướng**, không theo
  độ chính xác — nó over-report. Đây là hướng sai an toàn (nhiễu trong danh sách
  người đọc, thay vì widget bị bỏ im lặng), và đã được pin bằng test kèm doc.
- **Lỗi allowance đang sống trong repo:** `detailContains: 'RenderEditable'` cũng
  nuốt hai node `_RenderEditableCustomPaint`, vì chuỗi sau chứa chuỗi trước. Ba
  node được miễn, một node được xem. Rule mới báo ngay `expected 1, matched 3`.
- **Còn mở, không thuộc task này:** repo **chưa có CI** (`.github/workflows`
  không tồn tại). Mọi con số test trong các PR M3.5* đều chạy trên máy local,
  không ai xác minh độc lập được. M7 ghi *"bắt đầu được ngay sau M2"* — đáng đặt
  lại thứ tự.
- **Dependencies:** M3.5e
- **Tests required:** `Stack`/`Flex` hardEdge không overflow; custom clipper
  over-report; visible rect của widget bị cắt một nửa; anchor id rỗng/trùng/
  `screen`/`name[i]`; allowance over- và under-match; summary có `unused`
- **Checklist phases:** 7.2, 14.1

### M3.6 · Base component tối thiểu và app shell

- **Status:** done
- **Goal:** Đúng bộ component mà UC-05 cần, không hơn.
- **Scope:** `AppScaffoldWidget`, `AppButtonWidget` (variant + loading +
  disabled), `AppLoadingStateWidget`, `AppEmptyStateWidget`,
  `AppErrorStateWidget` (nhận `String`, không nhận `Failure`), `AppCardSurface`.
- **Out of scope:** TextField, SearchField, ListItem, Dialog, BottomSheet —
  UC-05 không dùng. Tạo khi có caller thật.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/shared/widgets/`
- **Acceptance criteria:**
  - [x] Mỗi component có `const` constructor.
  - [x] `AppButtonWidget` có enum variant, **không** nhận `Color` hay
        `TextStyle`. Ngay khi caller truyền được màu, design system hết cưỡng
        chế được: mọi màn hình tự do bịa một sắc, và người review không phân
        biệt được biến thể cố ý với lỗi gõ.
  - [x] `AppButtonWidget` ở trạng thái loading thì bị disable và **giữ nguyên
        chiều rộng** — có test đo hai lần và so bằng nhau. Label vẫn được layout
        nhưng `Opacity(0)`; thay child bằng spinner sẽ làm nút co lại và đẩy mọi
        thứ bên cạnh đúng lúc người dùng đang nhìn.
  - [x] Mọi control chỉ có icon đều có semantic label — `AppLoadingStateWidget`
        bắt buộc truyền `semanticsLabel`, có test `find.bySemanticsLabel`.
  - [x] Touch target ≥ 48×48 — có test đo; ràng buộc đặt ở `ButtonStyle` trong
        theme nên không component nào dựng được nút thấp hơn.
  - [x] Mỗi component render được ở 320×568 và ở `textScaler` 2.0 mà
        `tester.takeException()` trả về null — 6/6 component.
  - [x] Golden test light + dark cho từng component — 14 file
        (`test/shared/widgets/goldens/`).
- **Golden — ba quyết định:**
  1. Dùng `matchesGoldenFile` có sẵn của `flutter_test`. **Không** thêm
     `golden_toolkit` hay `alchemist`: với snapshot cố định kích thước, một
     locale, chúng không mua thêm năng lực nào mà chỉ thêm dependency phải bảo
     trì.
  2. **Không** golden cho `AppLoadingStateWidget`. `CircularProgressIndicator`
     luôn ở giữa animation, nên golden của nó flaky theo thiết kế. Hành vi của
     nó được phủ bằng test semantics.
  3. **Nạp font thật** qua `test/flutter_test_config.dart` — nạp **font của
     chính app** (`assets/fonts/`) chứ không phải font hệ thống, nếu không golden
     sẽ ghi lại kiểu chữ mà app không bao giờ render. Mặc định
     `flutter_test` thay font bằng một placeholder vẽ mọi glyph thành ô vuông
     giống hệt nhau — khi đó golden chỉ ghi lại **hình dạng layout** và không
     ghi gì về chữ: sai font weight, sai màu chữ, label bị cắt và lỗi
     line-height đều cho ra ảnh **giống hệt nhau từng byte**. Nạp Roboto và
     MaterialIcons mới làm golden có khả năng fail vì đúng những lý do golden
     sinh ra để bắt. Font lấy từ **Flutter SDK đã pin** (`.fvmrc` → 3.44.8), nên
     repo không phải chứa file font lẫn giấy phép của nó, và glyph gắn với đúng
     version SDK mà mọi máy đã build bằng.

     Phụ phẩm đáng giá: test overflow ở `textScaler` 2.0 nay mới thật sự có ý
     nghĩa. Font hộp có metric đồng đều, còn font thật xuống dòng khác hẳn —
     6/6 component vẫn pass sau khi đổi.
- **Ràng buộc cho M7 (CI):** chữ nay render bằng glyph thật, nhưng **cách
  rasterise glyph vẫn khác nhau giữa hệ điều hành**. Bộ này sinh trên Windows;
  runner Linux sẽ khác antialiasing. M7 phải hoặc chạy suite này trên một nền
  tảng duy nhất, hoặc sinh lại theo nền tảng. File test gắn tag `golden` nên
  loại trừ được bằng `--exclude-tags golden`.
- **Golden bổ sung sau khi đổi font:** thêm `typography` và `card_prompt`. Lý do
  cụ thể: hai họ font có thể được khai báo trong `pubspec`, **im lặng không nạp
  được**, và mọi golden còn lại vẫn pass trên font fallback. Hai ảnh này là thứ
  duy nhất làm hỏng đó lộ ra — `typography` phơi từng vai trò chữ để thiếu họ
  font hay kẹt trục trọng số nhìn thấy được, `card_prompt` cho thấy màn hình
  chủ đạo thật.
- **App shell:** `ReviewPlaceholderScreen` nay dựng từ `AppScaffoldWidget` +
  `AppEmptyStateWidget`, tức bộ component được chứng minh chạy end-to-end trước
  khi có màn hình thật phụ thuộc vào nó. Chưa triển khai màn review (M5.4).
- **Dependencies:** M3.5, M2.4
- **Tests required:** widget test cho từng state; golden test light/dark; test
  overflow ở màn nhỏ và text scale 2.0 — **đã có**, `test/shared/widgets/`,
  12 widget test + 14 golden
- **Checklist phases:** 7.3, 7.4, 13, 15.3, 15.4

---

## M4 · Router and Drift foundation

Mục tiêu: có router và một database chạy được, đúng schema đã frozen, kèm
migration test và enforcement cho các bất biến.

### M4.1 · GoRouter foundation

- **Status:** done
- **Goal:** Điều hướng tập trung, có sẵn chỗ cắm auth guard mà chưa xây auth.
- **Scope:** `app/router/route_paths.dart`, `route_names.dart`,
  `app_router.dart`, `errorBuilder` 404, một hàm `redirect` rỗng có comment nói
  rõ đây là điểm cắm guard (AD-03).
- **Out of scope:** auth guard thật, deep link config, `StatefulShellRoute` —
  MVP chưa có bottom navigation.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/router/{route_paths,route_names,app_router}.dart`,
  `lib/app/fallback/route_not_found_screen.dart`, `lib/app/app.dart`,
  3 key ARB × 2 locale, `test/app/router/app_router_test.dart`
- **Acceptance criteria:**
  - [x] `MaterialApp.router` được dùng; `home` là `null` — có test khẳng định cả hai.
  - [x] `git grep -nE "context\.(go|push)\('/" -- lib` **rỗng**; và
        `context\.(goNamed|pushNamed)\('...'` cũng rỗng — không có route name
        viết thẳng tại call site.
  - [x] Route không tồn tại → `RouteNotFoundScreen` có nút quay về, không red
        screen, `takeException()` là `null`.
  - [x] `redirect` trả `null` và có comment chỉ rõ điểm cắm guard (AD-03).
  - [x] Widget test điều hướng bằng **tên** và assert màn đích.
- **RouteNotFoundScreen nằm ở `app/fallback/`, không phải feature.** Nó không có
  domain, use case, repository hay data source — `features/not_found/` sẽ là ba
  tầng rỗng bọc quanh một widget. Cũng không phải shared widget: nó biết
  `GoRouter` và `RouteNames`, mà thứ gì trong `shared/widgets/` biết hai cái đó
  sẽ kéo routing vào mọi widget test của dự án.
- **`app/router/` không chứa screen UI.** Layout viết bên trong định nghĩa route
  thì không pump riêng được, nên bài test đầu tiên của màn đó buộc phải đi qua
  router mới với tới.
- **Router tạo một lần.** `appRouter` là top-level `final`, không dựng trong
  `build()` — một `GoRouter` tạo lại lúc rebuild là một router mới với navigation
  stack mới, biểu hiện ra ngoài là màn hình nhảy về đầu mỗi khi thứ gì ở trên
  rebuild. Test truyền router riêng vì `GoRouter` mang lịch sử điều hướng.
- **Không hiển thị URL lỗi trên màn 404.** Người dùng không làm gì được với nó,
  và khi có deep link thì một location có thể mang nội dung thẻ.
- **Không làm:** auth guard thật, login, onboarding, deep link, URL strategy,
  `StatefulShellRoute`, bottom navigation, route observer, Riverpod router
  provider, `go_router_builder`, M4.2.
- **Một điều chỉnh ngoài brief:** ARB tiếng Việt phải kèm `description` cho cả ba
  key, vì `test/l10n/arb_parity_test.dart` (M2.4) bắt buộc mọi message ở **cả
  hai** file có description. Đây là cổng sẵn có, không phải copy mới.
- **Dependencies:** M3.6
- **Tests required:** 8 widget test — root đi qua router, `MaterialApp.router`
  với `home == null`, `goNamed` tới review, redirect không chặn, 404 thay red
  screen, copy đã localization và không lộ URL, nút quay về, fallback dùng
  `AppScaffoldWidget` + `AppErrorStateWidget`
- **Checklist phases:** 8.1, 8.2

### M4.1a · Screen audit coverage gate

- **Status:** done — cơ chế registry đã được **MX-VIS-001 thay thế** ở batch M4
- **Goal:** Ép mọi màn hình mới trong `lib/` phải được visual audit, bằng một
  cổng không thoả mãn được bằng file rỗng.
- **Scope:** registry `audited_screens.dart` lái cả audit lẫn coverage check;
  `PendingAudit` có rationale và WBS task; kiểm vị trí file screen; audit thật
  cho hai màn đang có; đổi tên `test/review/` → `test/design_preview/`.
- **Out of scope:** state matrix, golden cho màn mới, M4.2.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/visual_audit/screens/{audited_screens,screen_audit_coverage}.dart`,
  `screen_audit_test.dart`, `screen_audit_coverage_test.dart`;
  `test/design_preview/` (đổi tên từ `test/review/`)
- **Acceptance criteria:**
  - [x] Màn mới trong `lib/` không đăng ký → `flutter test` **đỏ**, thông báo nêu
        đúng tên class và dòng cần thêm.
  - [x] Một registry lái **cả hai**: entry sinh ra audit đang chạy, và coverage
        check đòi entry.
  - [x] `PendingAudit` bắt buộc có rationale + WBS task; entry cũ trỏ vào màn
        không còn tồn tại → fail.
  - [x] `*_screen.dart` chỉ được nằm ở `lib/features/*/presentation/` hoặc
        `lib/app/fallback/`.
  - [x] Fault injection cả hai nhánh: màn đặt sai chỗ, và màn hợp lệ chưa đăng ký.
- **Vì sao không dùng luật "mỗi screen phải có file test cùng tên":** luật đó
  **thoả mãn được bằng một file rỗng**. Ép sự *tồn tại* của file không ép được sự
  *chạy* của audit. Registry đóng lỗ đó vì không còn file nào để tạo rỗng.
- **Vì sao kiểm vị trí nằm ở Dart chứ không ở guard:** guard đọc từng file một,
  nên phải diễn đạt thành *"tập file này phải rỗng"* — mà nó không phân biệt được
  với một rule có scope đã chết, và báo `rule_without_targets` **vĩnh viễn**. Tôi
  đã viết rule đó, chạy được, rồi bỏ: im lặng diagnostic ấy chính là cách ba rule
  chết sống sót trong repo này. Kiểm trong Dart có full path và không có vấn đề
  scope rỗng.
- **Hai lỗi cổng này bắt được ngay lần chạy đầu:** harness `auditMemoxScreen`
  pump một `MaterialApp` **không có localization delegate**, nên cả hai màn
  production ném lỗi và render error box của Flutter — 0 paint, mà audit vẫn báo
  `PASS_WITH_UNRESOLVED`. Ba màn replica trong `test/review/` dùng chuỗi cứng nên
  chưa bao giờ chạm vào. Đã thêm delegate, và thêm `NoErrorWidgetRule` để một màn
  không build được **không bao giờ** pass — trước đó nó chỉ là
  `unknownRenderType`.
- **`test/review/` đổi tên thành `test/design_preview/`:** ba màn trong đó là bản
  sao private để tranh luận về màu trước khi có màn thật. Audit một bản sao chỉ
  chứng minh bản sao đúng. Các mục M3.5a–M3.5f vẫn ghi đường dẫn cũ vì chúng là
  ghi chép tại thời điểm đó — không sửa lại lịch sử.
- **Dependencies:** M4.1
- **Tests required:** coverage gate trên dữ liệu thật; năm luật của gate trên dữ
  liệu tổng hợp (chưa đăng ký, đã đăng ký, hoãn hợp lệ, hoãn cũ, vừa audit vừa
  hoãn); kiểm vị trí file; audit thật hai màn × light/dark
- **Checklist phases:** 8.1, 14.1

### M4.2 · Drift connection và schema `.drift`

- **Status:** done
- **Goal:** Database mở được, schema khớp `data-model.md`, SQL nằm trong file
  `.drift`.
- **Scope:** `core/database/connection.dart` (một chỗ duy nhất mở kết nối —
  AD-08), `app_database.dart`, `tables/*.drift` cho `decks`, `cards`,
  `card_review_states`, `review_history`, `study_sessions`; index; `PRAGMA
  foreign_keys = ON` trong `beforeOpen`.
- **Out of scope:** named query nghiệp vụ (M4.3), DAO và repository (M4.9 cho Deck/Card, M5.0 cho Review),
  bảng `deck_templates` (AD-07: là asset ở MVP).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/database/{connection,app_database}.dart`,
  `tables/{decks,cards,study}.drift`, `test/database/{schema,cascade}_test.dart`
- **Acceptance criteria:**
  - [x] `dart run build_runner build` sinh code Drift, exit 0.
  - [x] Mọi bảng và cột khớp `data-model.md` — kiểm bằng `PRAGMA table_info`
        **đọc ngược từ SQLite**, không đọc file `.drift`.
  - [x] Không có Dart table class hand-written; toàn bộ khai báo nằm trong
        `.drift` (AD-02).
  - [x] Xoá root deck → deck con, card, review state, history và session đều
        biến mất, trên cây **ba cấp** với dữ liệu thật.
  - [x] `COALESCE(` không xuất hiện trong `lib/core/database/` (BR-57).
  - [x] `connection.dart` là **file duy nhất** gọi `driftDatabase`.
  - [x] Web không bị âm thầm tắt: `web/sqlite3.wasm` và `web/drift_worker.js`
        được vendor kèm test khoá version. Kiểm trong trình duyệt thật — wasm
        **compile được** (86 export, có symbol sqlite3), worker **khởi động
        được**, không console error.
- **Cột `action` bị drift âm thầm bỏ.** `ACTION` là keyword với SQL parser của
  drift: viết trần thì build **thành công**, code sinh ra **compile được**, và
  `review_history` đơn giản là không có cột đó. Chỉ test đọc ngược cột từ SQLite
  bắt được — assert vào file `.drift` sẽ tự đồng ý với chính nó. Nay quote lại.
- **Không đặt CHECK cho cặp `status` × `end_reason`.** `data-model.md` frozen chỉ
  định invariant 12 là cơ chế cưỡng chế; thêm CHECK ở đây sẽ khiến invariant đó
  **không thể vi phạm được**, và một invariant test không dựng nổi vi phạm của
  chính nó thì không chứng minh gì. CHECK cho enum từng cột thì an toàn và có.
- **`root_deck_id` cố ý không phải foreign key** — tài liệu khai báo tham chiếu
  cho `parent_deck_id` và không cho cột này; invariant 6 và 7 là cơ chế nó nêu.
- **Đã kiểm tới đâu trên Web, và chưa tới đâu.** Kiểm được: hai asset phục vụ
  đúng MIME (`application/wasm`, `text/javascript`), wasm compile trong trình
  duyệt, worker chạy không lỗi. **Chưa kiểm:** drift thật sự mở một database —
  `driftDatabase()` kết nối lazy ở query đầu tiên, mà chưa có gì trong app phát
  query. Việc đó thuộc **M4.9**, khi repository Deck/Card có caller thật.
- **Dependencies:** M3.2, M2.2
- **Tests required:** 16 test schema (bảng, cột, nullability, PK, FK, index,
  không Dart table class, opener duy nhất) + 3 test cascade
- **Checklist phases:** 11.1

### M4.3 · Named query và migration foundation

- **Status:** done
- **Goal:** Có query nghiệp vụ dùng chung và hạ tầng test migration ngay từ v1.
- **Scope:** `queries/study.drift` với `cardsDueForReview` và
  `dueCountPerRootDeck` (dùng `root_deck_id`, nhận `:now` làm tham số — BR-57,
  AD-06); `MigrationStrategy` với `schemaVersion = 1`; export schema v1 bằng
  `drift_dev schema dump`; test migration harness.
- **Out of scope:** migration v2 — chưa có thay đổi schema nào.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/database/queries/`, `drift_schemas/`,
  `test/drift/generated/`, `test/database/migration_test.dart`
- **Acceptance criteria:**
  - [x] `drift_schemas/drift_schema_v1.json` tồn tại và **được commit**
        (`.gitignore` đã có negation `!drift_schemas/**`).
  - [x] Test migration chạy `onCreate` từ rỗng lên v1, assert đủ bảng, và
        `SchemaVerifier` xác nhận snapshot khớp thứ code dựng.
  - [x] Hai query dùng **cùng một** định nghĩa "đến hạn" — test lặp qua từng root
        và so số card của hai bên (BR-22, UC-06).
  - [x] Không số ngày interval nào trong `.drift` (BR-16 thuộc scheduler).
  - [x] `:now` là tham số; grep clock function trong `lib/core/database` rỗng.
- **`drift_dev 2.34.0` không tương thích với `drift 2.34.3`.** `schema dump` nổ ở
  `verifier_common.dart` (`allSchemaEntities` không tồn tại trên
  `drift3_preview.GeneratedDatabase`). Nâng `drift_dev` bất khả thi:
  `>=2.34.1` cần `analyzer ^13`, mà `freezed ^3.2.5` chặn dưới đó. Cách thoát là
  **pin `drift: 2.34.0`** cho khớp dev tool — hạ runtime, có chủ đích, ghi ở đây
  để lần nâng sau biết ràng buộc thật nằm ở `freezed`.
- **Dependencies:** M4.2
- **Tests required:** 5 migration test; 6 query test gồm biên "đến hạn đúng
  bằng now", `now` thật sự điều khiển kết quả, và card không có review state
  không được phát
- **Checklist phases:** 11.1, 15.1

### M4.4 · Enforcement cho bất biến dữ liệu

- **Status:** done
- **Goal:** Biến 14 query bất biến trong `data-model.md` thành test chạy trên
  database thật.
- **Scope:** test tích hợp nạp fixture hợp lệ và fixture vi phạm cho từng bất
  biến; nối `check_docs.sh --db` vào một database tạm.
- **Out of scope:** sửa nội dung bất biến — `data-model.md` đang frozen.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/database/{invariant_queries,invariants_test,fixture_db_test}.dart`
- **Acceptance criteria:**
  - [x] Cả 14 bất biến có test; mỗi cái **hai chiều** — 30 test tổng.
  - [x] Fixture là cây **ba cấp** (root → branch → leaf); Q6 dùng đúng case cấp 3
        (BR-55, BR-57).
  - [x] `check_docs.sh --db <db sạch>` exit 0; `--db <db vi phạm>` exit 1 và gọi
        đúng tên `Q10`.
  - [x] Mục technical debt được cập nhật — **trả một phần**, không tuyên bố đã
        chạy trên dữ liệu người dùng thật.
- **`check_docs.sh` chỉ chạy 10 trên 14.** Bốn bất biến (Q5, Q10, Q11, Q13) thiếu
  hẳn, và lần chạy vẫn báo thành công. Nguyên nhân là chúng được **chép tay** vào
  script. Sửa tận gốc: script uỷ quyền cho `verify_invariants.py`, vốn đã trích
  query thẳng từ `data-model.md`. Một bộ luật có hai bản sao là hai thứ để quên.
- **Bỏ luôn phụ thuộc vào `sqlite3` CLI.** Nó không có trên máy này, và khi vắng
  thì mục đó `warn` rồi bỏ qua — exit 0 mà không chạy gì. Verifier dùng
  `sqlite3` của Python stdlib.
- **Một khiếm khuyết có thể vi phạm hai bất biến, đúng như tài liệu nói.** Card
  gắn vào root vi phạm cả BR-58 (Q1) lẫn BR-64 (Q4), vì root luôn mang
  `content_type = 'deck'`. Test cô lập ghi nhận đúng cặp đó thay vì làm yếu một
  trong hai query.
- **Dependencies:** M4.3
- **Tests required:** 30 test bất biến (14 × 2 chiều + danh sách đủ 14 + test cô
  lập); 2 test sinh database fixture cho `check_docs.sh --db`
- **Checklist phases:** 11.1, 15.1

### M4.4a · Reorder WBS theo Deck/Card vertical slice

- **Status:** done
- **Goal:** Chuyển phần chưa triển khai từ layer-first sang vertical-slice-first,
  để app có luồng quản lý nội dung demo được trước khi làm Review.
- **Scope:** sắp xếp lại M4 sau M4.4; giữ nguyên ID vĩnh viễn; thay M4.5–M4.7 cũ
  bằng task kế nhiệm có caller UI thật; buộc Deck/Card hoàn chỉnh trước Review.
- **Out of scope:** sửa code; sửa frozen business rules; thay đổi phạm vi MVP;
  triển khai bất kỳ task mới nào.
- **Editable documents:** `docs/wbs.md`
- **Output:** `docs/wbs.md`
- **Acceptance criteria:**
  - [x] Không có task ID trùng.
  - [x] Không renumber ID cũ — M5.1…M5.6 giữ nguyên số.
  - [x] Không dependency nào của task **active** trỏ tới task đã `descoped`.
  - [x] Task tiếp theo là **M4.8**.
  - [x] Review chỉ bắt đầu sau **M4.12**.
  - [x] `check_docs.sh` exit 0.
- **Vấn đề đã sửa.** Kế hoạch cũ tiếp tục theo tầng: M4.5–M4.7 dựng toàn bộ domain
  và data cho **cả** Deck/Card lẫn Review, rồi M5 mới có UI — mà CRUD Deck/Card
  lại nằm **ngoài** phạm vi M5. Kết quả là backend lớn dần trong khi app không có
  luồng nào demo được, và shared component thì chỉ đủ cho UC-05 vì text field,
  list item, dialog và bottom sheet đã bị loại khỏi M3.6 lúc chưa có caller.
- **Vì sao không renumber.** Task ID là định danh vĩnh viễn (cùng chính sách với
  BR/AD/UC). Đổi M5.1 cũ thành M6.1 sẽ làm mọi tham chiếu trong commit message,
  PR và ghi chép phiên trước trỏ sai — im lặng, vì ID mới vẫn tồn tại và vẫn đọc
  được. Nên ID cũ giữ nguyên, và ba task bị thay dùng status `descoped` kèm task
  kế nhiệm.
- **Dependencies:** M4.4
- **Tests required:** document validation — `check_docs.sh`
- **Checklist phases:** meta / planning

#### Bảng chuyển nội dung

| Task cũ | Trạng thái | Nội dung được chuyển tới |
|---|---|---|
| M4.5 | `descoped` | Deck/Card → **M4.9** · Review → **M5.0** |
| M4.6 | `descoped` | Deck/Card → **M4.9** · Review → **M5.0** |
| M4.7 | `descoped` | Fixture/demo → **M4.12** |
| M5.1–M5.6 | giữ nguyên ID | Thực hiện sau **M4.12** |

Quyết định: **reordered before implementation.** Không có production
implementation nào từng được tuyên bố hoàn thành dưới M4.5, M4.6 hay M4.7. Phạm
vi MVP không đổi — chỉ đổi thứ tự và cách chia task để có sản phẩm demo được
sớm. Chiến lược mới là vertical-slice-first, **không** phải bỏ ranh giới kiến
trúc: mỗi slice vẫn đi qua domain → data → state → UI, chỉ là hẹp lại còn đúng
phần có caller thật.

### M4.5 · Domain entity và repository contract

- **Status:** descoped
- **Decision:** descoped **before implementation** (M4.4a). Không dòng code nào
  từng được viết dưới ID này.
- **Reason:** scope gộp Deck/Card và Review vào **một** domain batch, tức là tiếp
  tục layer-first trong khi app chưa có luồng quản lý nội dung nào để demo. Một
  contract viết cho cả hai slice cùng lúc buộc phải đoán nhu cầu của presentation
  chưa tồn tại — đúng cái mà acceptance criteria của chính task này cấm.
- **Superseded by:** **M4.9** cho Deck/Card domain và repository contract ·
  **M5.0** cho domain và repository contract riêng của Review.
- **Goal:** _(lịch sử)_ Có hợp đồng domain viết theo nhu cầu presentation,
  không theo hình dạng Drift.
- **Scope:** `features/review/domain/entity/` (`DeckEntity`, `CardEntity`,
  `CardReviewStateEntity`, `StudySessionEntity`, `ReviewHistoryEntity`), enum
  `SchedulerType`, `ReviewAction`, `ReviewKind`, `SessionStatus`,
  `SessionEndReason`, `DeckContentType`; repository contract dạng abstract.
- **Out of scope:** implementation (M4.6), use case (M5.2).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/review/domain/`
- **Acceptance criteria:**
  - [ ] `check_architecture.sh` exit 0 — domain không import Flutter, Drift,
        `json_annotation`.
  - [ ] Mọi trạng thái hữu hạn là enum hoặc sealed class, không phải `String`
        (BR-79, BR-80, BR-75).
  - [ ] Entity immutable, có value equality — test khẳng định hai instance cùng
        dữ liệu thì bằng nhau.
  - [ ] Không method nào trong contract nhận hoặc trả kiểu sinh bởi Drift
        (AD-01).
  - [ ] Contract có method mà UC-05 cần và **không** có method chưa ai gọi.
- **Dependencies:** M4.2 _(lịch sử — task đã descoped, không ai được phụ thuộc
  vào nó)_
- **Tests required:** _(không áp dụng — descoped trước khi triển khai)_
- **Checklist phases:** 14.2

### M4.6 · Data layer — DAO, mapper, repository implementation

- **Status:** descoped
- **Decision:** descoped **before implementation** (M4.4a). Không dòng code nào
  từng được viết dưới ID này.
- **Reason:** data layer phải lớn lên cùng caller UI/use case của từng vertical
  slice. Triển khai tràn toàn bộ review domain trước khi có màn hình nào gọi tới
  sinh ra code không ai chứng minh được là đúng — nó chỉ được chứng minh là
  *compile được*.
- **Superseded by:** **M4.9** cho Deck/Card data layer · **M5.0** cho data layer
  riêng của Review.
- **Goal:** _(lịch sử)_ Nối domain xuống Drift, và chặn mọi exception ở đúng
  ranh giới repository.
- **Scope:** DAO theo feature, mapper Drift row ↔ entity, repository
  implementation, mapping exception → `Failure`, transaction cho thao tác nhiều
  bước.
- **Out of scope:** remote data source, cache TTL, sync (AD-01, AD-05).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/review/data/`
- **Acceptance criteria:**
  - [ ] `check_architecture.sh` exit 0 — presentation chưa tồn tại, nhưng
        `data/` không được import ngược lên.
  - [ ] Không `DriftWrappedException` nào thoát khỏi repository — test khẳng
        định repository ném `DatabaseFailure`.
  - [ ] Repository đọc bằng `watch()` stream, không phải `Future` một lần
        (AD-01) — test khẳng định stream phát lại khi dữ liệu đổi.
  - [ ] Mapper xử lý enum lạ bằng cách map về giá trị `unknown` thay vì throw.
  - [ ] Tạo card sinh đúng một `card_review_states` trong cùng transaction
        (BR-09) — test khẳng định.
- **Dependencies:** M4.5, M4.3 _(lịch sử — task đã descoped)_
- **Tests required:** _(không áp dụng — descoped trước khi triển khai)_
- **Checklist phases:** 14.3, 15.1

### M4.7 · Fixture cho development và test

- **Status:** descoped
- **Decision:** descoped **before implementation** (M4.4a). Không dòng code nào
  từng được viết dưới ID này.
- **Reason:** fixture phải chứng minh một luồng demo **chạy thật**, không tồn tại
  như một backend artifact đứng riêng. Seed dữ liệu mà không có màn hình nào đọc
  nó chỉ chứng minh insert chạy được.
- **Superseded by:** **M4.12** cho Deck/Card development fixture, seed và demo
  E2E. Fixture riêng cho Review, nếu cần, mở rộng ở M5.
- **Goal:** _(lịch sử)_ Có dữ liệu thật để chạy vertical slice, đánh dấu rõ là
  fixture.
- **Scope:** `assets/templates/manifest.json` + một template cây deck nhiều cấp
  (root → deck con → deck chứa card) cho cả `eight_box` và `sm2`; loader nạp vào
  database; helper `seedTestDatabase()` cho test.
- **Out of scope:** nội dung production (BR-87 — thay trước M8); UI thư viện
  starter (UC-01 không thuộc M5).
- **Editable documents:** `docs/wbs.md`
- **Output:** `assets/templates/`, `lib/features/review/data/template_loader.dart`,
  `test/helpers/seed.dart`
- **Acceptance criteria:**
  - [ ] Fixture có cây **ít nhất 3 cấp** để chứng minh `root_deck_id` hoạt động
        (BR-55).
  - [ ] Fixture có ít nhất một root `eight_box` và một root `sm2`.
  - [ ] Mọi deck trong fixture có `content_type` hợp lệ; không deck nào vừa chứa
        card vừa chứa deck con (BR-65).
  - [ ] Nạp fixture hai lần **không** tạo bản sao trùng (BR-37).
  - [ ] Manifest ghi rõ nội dung là fixture cho development/test (BR-87).
  - [ ] Sau khi nạp, toàn bộ 14 bất biến của M4.4 vẫn pass.
- **Dependencies:** M4.6, M4.4 _(lịch sử — task đã descoped)_
- **Tests required:** _(không áp dụng — descoped trước khi triển khai)_
- **Checklist phases:** 11.1, 14.3

### M4.8 · Shared components cho content management

- **Status:** done
- **Goal:** Mở rộng design system từ token và theme đã có, để Deck/Card UI không
  phải tự dựng TextField, list item, dialog hay action sheet ở từng màn.
- **Scope:** `MxTextField`, `MxIconButton`, `MxListTile`, `MxConfirmDialog`,
  `MxActionSheet`; feedback component **chỉ khi** có từ hai caller thật;
  theme/component state mà Deck/Card form cần. Cộng **migration toàn bộ shared
  widget hiện có từ prefix `App*` sang `Mx*`** — quyết định của chủ dự án: mọi
  shared widget của MemoX dùng prefix `Mx`.
- **Out of scope:** Deck screen, Card screen (M4.10, M4.11); repository;
  controller; review verdict control và Review screen (M5).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/shared/widgets/mx_*.dart` (5 component mới + 6 component đổi
  tên), `lib/core/theme/app_theme.dart` (component theme mới),
  `test/shared/widgets/`
- **Acceptance criteria:**
  - [x] Dùng `AppSpacing`, `AppRadius`, `AppIconSize`, `AppTypography`,
        `ColorScheme` và `AppSemanticColors` hiện có.
  - [x] Không nhận raw `Color` hay `TextStyle` từ caller.
  - [x] `const` constructor ở mọi chỗ có thể.
  - [x] Light và dark.
  - [x] Focus, error, disabled và loading — với component có state đó.
  - [x] Touch target tối thiểu 48×48.
  - [x] Semantic label cho mọi action chỉ có icon.
  - [x] Render ở 320×568 và ở `textScaler` 2.0 không overflow.
  - [x] Widget test cho từng state; golden light/dark cho state ổn định.
  - [x] Không golden cho animation không tất định.
  - [x] Toàn bộ public shared widget dùng prefix `Mx`.
  - [x] Không còn production usage hoặc public shared class dùng prefix `App`.
  - [x] Không có compatibility wrapper `App*` — mọi consumer đều nằm trong repo.
  - [x] Import và test đã migrate sang file/class `Mx`.
  - [x] Migration naming **không** làm đổi hành vi ngoài phạm vi M4.8.
- **Cái này đáng lẽ đã có ở M3.6, và có lý do nó không có.** M3.6 loại text field,
  list item, dialog và bottom sheet vì lúc đó **chưa có caller** — đúng quy tắc
  "không tạo abstraction chưa có caller". Nay Deck/Card cho chúng caller thật, nên
  chúng được dựng ở đây chứ không phải trong từng feature. Vẫn giữ nguyên quy
  tắc: component nào **chưa** có caller trong M4.10 hoặc M4.11 thì không tạo.
- **Vì sao `Mx` chứ không `App`.** `App*` là tên chung, không nói được đây là
  taxonomy của MemoX Design System. Giữ song song cả `App*` lẫn `Mx*` sẽ tạo hai
  API shared cùng lúc, và feature mới sẽ không biết cái nào là canonical — nên
  migration là **cơ học và trọn vẹn**, không để lại typedef hay wrapper. Prefix
  `App` **giữ nguyên** cho token và core (`AppSpacing`, `AppRadius`,
  `AppIconSize`, `AppTypography`, `AppSemanticColors`, `AppTheme`,
  `AppDatabase`): quy tắc `Mx` áp cho widget, không áp cho namespace token.
- **DeckTile, CardTile và SchedulerSelector KHÔNG vào shared.** Chúng mang ngữ
  nghĩa nghiệp vụ của một feature; đưa vào `shared/` sẽ kéo domain của Deck vào
  mọi widget test của dự án, đúng lỗi mà `RouteNotFoundScreen` đã tránh ở M4.1.
- **Kết quả kiểm chứng.** 346 test pass; `flutter analyze` sạch; guard sạch;
  26 golden mới (13 state × light/dark). Rename `App*` → `Mx*` **không đổi một
  pixel nào**: 14 golden cũ pass mà không cần update — đó là bằng chứng cho
  tiêu chí "migration không đổi hành vi", không phải lời hứa.
- **Bảy boolean phải đổi tên sau khi guard bắt.** `enabled`, `readOnly`,
  `selected`, `autofocus` được đặt theo tên tham số của Flutter, nhưng repo đã
  có quy ước `isEnabled` / `isLoading` / `isSubmitting` từ trước. Đổi guard cho
  code mới lọt qua là đúng thứ mà cả M2.1b lẫn M4.4 đã phải sửa; nên đổi tên
  code, không đổi guard: `isEnabled`, `isReadOnly`, `isSelected`,
  `shouldAutofocus`.
- **`MxActionSheet` không tự vẽ surface.** Nền, bo góc, drag handle và elevation
  đến từ `bottomSheetTheme`, nghĩa là nó là child của `showModalBottomSheet`.
  Golden phơi ra điều này và doc comment đã nói rõ; đặt nó ở chỗ khác thì nó vẽ
  thẳng lên nền phía sau.
- **Không có `show()` helper cho sheet và dialog.** Cả hai cố ý không tự đóng:
  component không biết action vừa bắn có thành công hay không, nên quyền đóng
  route thuộc caller. Một helper `show()` sẽ mâu thuẫn với chính quyết định đó.
- **Vòng review UI/UX sau khi đóng task — bốn lỗi thật, hai luận điểm bị bác.**
  Review ngoài nêu bảy điểm; kiểm chứng trên code và trên ảnh thì:
  - **Đúng — nút đang submit mất tên.** `Opacity(opacity: 0)` không chỉ ẩn
    label mà còn **bỏ nó khỏi semantics tree**: node chỉ còn `isButton,
    hasEnabledState`, không có `label`. Screen reader đọc "nút, bị vô hiệu"
    mà không nói được là nút gì. Sửa bằng `alwaysIncludeSemantics: true`;
    trạng thái bận đã có sẵn qua `role: loadingSpinner` của spinner, nên
    không phải bịa thêm chuỗi nào ngoài ARB.
  - **Đúng — golden của action sheet không kiểm tra UI thật.** Sheet cố ý
    không tự vẽ surface, nên mount trực tiếp trong `Scaffold` chỉ chụp được
    các hàng trôi trên nền, một bố cục không bao giờ ship. Golden giờ đi qua
    `showModalBottomSheet` thật: pin cả surface, bo góc trên, drag handle và
    scrim. `MxConfirmDialog` không cần tương tự — `AlertDialog` tự mang
    `Material` của nó.
  - **Đúng — dialog cắt chữ ở text scale lớn.** Và test cũ chính là loại
    "xanh mà không che gì": `takeException()` trả về null, test pass, còn người
    dùng đọc được đúng "Dies entfernt 4 Unterstape" rồi bị cắt giữa từ. Text
    tràn thì **clip chứ không throw**. Sửa bằng `scrollable: true`; đã đo
    `maxScrollExtent = 1013` và kéo đến được phần dưới.
  - **Đúng — fixture dialog normal dùng hành động nguy hiểm.** Baseline normal
    đang là ảnh một nút Delete tô màu primary. Đổi sang "Save changes?".
  - **Bác — `MxListTile` không ổn định chiều cao.** Đo thật: tile ngắn 80px,
    tile 2 dòng tiêu đề + 2 dòng phụ 112px, không exception, không overflow.
    `ListTile` giãn theo nội dung. `isThreeLine` là phân loại của Material
    spec, không phải lỗi bố cục — không đổi API dựa trên một lỗi không tái hiện.
  - **Bác — `MxIconButton` bị đọc hai lần.** Dump semantics cho thấy đúng
    **một** node mang cả `label` lẫn `tooltip`, và finder khớp đúng 1. Bằng
    chứng mà review đưa ra (`findsWidgets`) chỉ là matcher lỏng của chính
    mình, không phải dấu hiệu trùng lặp. Đã siết về `findsOneWidget` cộng
    assert trên node. Thử nghiệm bỏ `Icon.semanticLabel` cho kết quả **tệ hơn**:
    node mất hẳn `label`, chỉ còn `tooltip` — đúng cái nút trắng tên mà
    `MxIconButton` sinh ra để chặn.
- **Một lỗi review không bắt, tìm được nhờ nhìn ảnh.** Ở textScaler 3.0 nhãn
  nút bị ellipsis thành `"End..."` cho "Endgültig löschen" — trên dialog
  destructive, người dùng đang duyệt một hành động họ không còn đọc được. Cho
  nhãn xuống 2 dòng trước khi ellipsis.
- **Một lỗi nữa chỉ lộ ra khi đo pixel.** Golden focus mới thêm cho thấy
  indicator bàn phím của icon button chỉ là mảng tint **1.15:1** so với nền ở
  cả hai chế độ; WCAG 1.4.11 đòi 3:1. Đã thêm focus ring vào
  `IconButtonThemeData`, đo lại: **6.87:1** (light) và **3.64:1** (dark).
- **Hai golden cũ đổi 40 pixel.** `button_secondary` light/dark, bbox 8×9 quanh
  một glyph — dấu vết dịch nửa pixel do `textAlign: center`, không phải đổi nội
  dung. Đã diff từng pixel trước khi nhận.
- **Ba trong năm test mới đã được kiểm chứng bằng mutation:** gỡ fix ra thì
  chúng đỏ. Hai cái còn lại là chốt chống hồi quy, không phải bắt lỗi — nói rõ
  để không ai nhầm.
- **Dependencies:** M3.4, M3.5, M3.6, M4.4a
- **Tests required:** widget test theo state, semantics, responsive 320×568,
  text scaling 2.0, golden light/dark cho state tất định
- **Checklist phases:** 7.3, 7.4, 13, 15.3, 15.4

### M4.8a · Responsive hardening cho shared component

- **Status:** done
- **Goal:** Đóng bốn điều kiện mà Phase 7.4 nêu — màn hình nhỏ, text scale
  lớn, bàn phím mở, landscape — ở tầng token, theme và shared widget, trước
  khi M4.9+ dựng màn hình thật lên trên chúng.
- **Scope:** `MxContentShell.isScrollable`; test responsive cho toàn bộ shared
  component.
- **Out of scope:** layout tablet/desktop (AD-04) · giới hạn bề rộng nội dung
  trên màn rộng (chủ dự án chọn giữ kéo căng) · áp `isScrollable` cho hai màn
  hình hiện có · màn hình Deck/Card (M4.10, M4.11).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/shared/widgets/mx_content_shell.dart`,
  `test/shared/widgets/mx_responsive_test.dart`
- **Acceptance criteria:**
  - [x] Đo trước khi sửa: landscape và bàn phím được thử trên **mọi** shared
        component, không chỉ cái bị nghi.
  - [x] Không component nào overflow ở landscape 852×393, textScaler 2.0,
        hoặc bàn phím mở.
  - [x] Đường không cuộn vẫn được giữ và **được test là vẫn overflow** — cờ
        này chỉ có nghĩa nếu chứng minh được nó là thứ sửa vấn đề.
  - [x] Body ngắn vẫn chiếm hết viewport, không co lại lên đầu màn hình.
  - [x] Body vừa khít không sinh ra scroll offset thừa.
  - [x] Không thêm breakpoint hay nhánh màn hình lớn nào.
- **Landscape là điều kiện duy nhất chưa từng được test, và đúng là chỗ có
  lỗi.** Portrait cao 852 điểm nên form nào cũng vừa; xoay ngang còn 393 —
  chưa tới một nửa — và bàn phím lấy thêm 200. Đo được, tái hiện được:
  `MxContentShell` chứa card editor **overflow 135px** ở landscape textScaler
  2.0, và **167px** ở landscape khi bàn phím mở. Bốn component còn lại
  (`MxEmptyState`, `MxErrorState`, `MxConfirmDialog`, `MxActionSheet`) sống sót
  mọi ca vì đã tự cuộn từ trước.
- **`isScrollable` phải là opt-in, không thể mặc định bật.** Body đã tự cuộn —
  `ListView`, `CustomScrollView` — mà lồng thêm một scroll view nữa thì nhận
  chiều cao vô hạn và chết ngay. Mặc định tắt giữ nguyên hành vi cũ cho mọi
  caller hiện tại.
- **`ConstrainedBox(minHeight:)` là phần dễ bị gỡ nhất.** `SingleChildScrollView`
  trần sẽ shrink-wrap, và mọi body trông đợi chiều cao viewport — `Center`,
  `Spacer`, action ghim đáy — sẽ lặng lẽ trôi lên đầu màn hình **trên mọi
  thiết bị**, không riêng máy màn ngắn. `minHeight` trừ đi padding, nếu không
  màn nào cũng cuộn thừa đúng bằng chiều cao padding. Cả hai đều có test riêng.
- **Tầng token và tầng theme không cần thêm gì, và đó là kết luận có bằng
  chứng chứ không phải bỏ sót.** Trục rủi ro của app này là **chiều dọc**
  (text scale × bàn phím × landscape), không phải chiều ngang; cách sửa đúng
  là ràng buộc layout, không phải breakpoint theo bề rộng. Thêm token chỉ để
  cho đủ ba tầng sẽ là abstraction không caller — đúng lỗi đã làm mất ba ID
  M4.5/M4.6/M4.7.
- **Quyết định của chủ dự án: màn rộng giữ nguyên kéo căng.** Đã dựng ảnh
  landscape thật để cân nhắc: nội dung trải hết 852px, chevron của list tile
  cách tiêu đề gần 700px và hàng đọc như bị rời. Không phải lỗi, là lựa chọn.
  Chốt lại ở đây để phiên sau không mở lại: **không** thêm `maxContentWidth`,
  **không** canh giữa nội dung. Muốn đổi thì mở task riêng.
- **Nợ kỹ thuật đã biết: `AppBreakpoints` không có caller production nào.**
  `compact = 360` và `medium = 600` chỉ được `design_tokens_test.dart` đọc.
  Với quyết định giữ kéo căng thì `medium` vẫn là nhánh không code nào đi —
  đúng thứ mà chính doc comment của file cảnh báo. Chưa xoá vì xoá token là
  thay đổi output của M3.4; ứng viên dọn ở M4.12 hoặc M6.
- **Dependencies:** M3.4, M3.6, M4.8
- **Tests required:** landscape 852×393 ở scale 1 và 2, bàn phím mở ở cả hai
  chiều, body ngắn/vừa/tràn cho `MxContentShell`
- **Checklist phases:** 7.4

### M4.8b · Compact scale cho màn hình hẹp

- **Status:** done
- **Goal:** Màn 320 không còn bị thừa gutter và wrap chữ ở mọi hàng, trong khi
  cỡ chữ đọc được và ngưỡng chạm 48dp giữ nguyên.
- **Scope:** `AppBreakpoints.isCompact`, `AppTypography.compactCardPromptSize`,
  `applyCompactScale` (file `app_compact_scale.dart`), `CompactScaleWidget`
  trong app root, padding màn hình theo bề rộng ở `MxContentShell`.
- **Out of scope:** thu cỡ chữ body/label · `VisualDensity` · layout
  tablet/desktop · giới hạn bề rộng trên màn rộng (M4.8a đã chốt giữ kéo căng).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/app_compact_scale.dart`, `app_breakpoints.dart`,
  `app_typography.dart`, `lib/app/app.dart`,
  `lib/shared/widgets/mx_content_shell.dart`,
  `test/core/theme/compact_scale_test.dart`, 4 golden compact
- **Acceptance criteria:**
  - [x] Đo trước và sau trên cùng một màn dựng thật, không chỉ nhìn cảm tính.
  - [x] Hàng list ở 320 cao bằng ở 393.
  - [x] Cỡ chữ body và label **không đổi** giữa compact và thường — có test.
  - [x] Ngưỡng chạm 48×48 vẫn giữ dưới compact — có test.
  - [x] Ngưỡng 360 là loại trừ: 360 nằm phía rộng, không phải phía compact.
  - [x] Golden ở đúng 320, light và dark.
- **Số đo, trước → sau, ở 320×568.** Hàng list **88 → 80px** (bằng 393); bề
  rộng tile 288 → 296; hộp chữ tiêu đề 176 → 192; tổng nội dung 392 → 368.
  Hai trong ba subtitle hết wrap. Nguyên nhân không phải chữ to mà là **gutter**:
  16dp mỗi bên chiếm 10% của màn 320 và 8% của màn 393 — cùng một con số,
  khác nhau về tỉ lệ.
- **Cái không làm, và đây là phần quan trọng nhất của task.** Body và label
  giữ nguyên cỡ. Thu chữ đọc được theo bề rộng thiết bị sẽ **lặng lẽ huỷ**
  `MediaQuery.textScaler` — thiết lập trợ năng của chính người dùng — và huỷ
  mạnh nhất với đúng nhóm cần nó, vì cỡ chữ lớn phổ biến trên máy nhỏ giá rẻ
  không kém gì trên máy lớn. Bề rộng thiết bị không phải là chỉ dấu của thị
  lực. Cái được thu là type mà **app tự chọn cho to**: `titleLarge` 22→20 và
  card prompt 30→26.
- **Không dùng `VisualDensity.compact`.** Nó là đường ngắn hơn một dòng, và nó
  trừ 8dp khỏi mọi button — đưa icon button về 40×40, dưới ngưỡng ngón tay và
  dưới đúng ngưỡng vừa được đo ở vòng review M4.8. Có test riêng chốt 48dp.
- **Tiêu đề AppBar dài vẫn cắt, và đó là hành vi đúng.** 22→20 chỉ mua thêm
  khoảng hai ký tự; không cỡ chữ nào làm vừa một tên deck dài tuỳ ý. Với một
  action thì "Academic Word List" vừa trọn ở 320; với hai action thì không.
- **`CompactScaleWidget` nằm trong `MobileFrameWidget`, không bọc ngoài.** Trên
  web frame ghi đè `MediaQuery` xuống 393×852; một phép thử bề rộng đặt phía
  trên sẽ đọc cửa sổ trình duyệt và kết luận app đang rộng rãi trong khi nó
  render ở cỡ điện thoại.
- **Phát hiện phụ, và nó lớn hơn cái golden nó làm hỏng: harness test nói dối
  về kích thước màn hình.** Sáu file test dựng `MediaQueryData(textScaler: ...)`
  mới toanh thay vì `copyWith`, nên `size`, `padding` và `viewInsets` đều bị
  zero — mọi widget trong golden suốt từ M3.6 đã được báo màn hình **0×0**,
  kể cả các test tự đặt `tester.view.physicalSize = 320×568`. Không ai đọc tới
  nên không lộ. Đã sửa cả sáu; sau khi sửa, golden `scaffold` **không cần sinh
  lại** — golden vốn đúng, chỉ harness sai.
- **`AppBreakpoints` hết nợ.** `isCompact` là caller production đầu tiên, đóng
  lại khoản nợ ghi ở M4.8a. `medium = 600` vẫn cố ý không có caller và doc đã
  nói rõ vì sao.
- **Button: giảm chiều cao thì không, giảm padding ngang thì có — và ca ép
  phải làm là màn Review.** Chiều cao đang **đúng ở sàn** 48dp
  (`minimumSize: Size(64, 48)`), không có gì để cắt; hạ xuống 40 chỉ tiết kiệm
  8px trên màn cao 568 — 1,4% — đổi lấy ngưỡng chạm. Trong dialog thì cũng
  không chật: hai nút ở 320 dùng 233 trên 280px khả dụng, và kích thước y hệt
  ở 393 vì nút ôm nội dung chứ không giãn.
  
  Nhưng với **bốn action của `sm2`** (again/hard/good/easy) trên một hàng ở
  320, mỗi nút chỉ được 68px. Padding 24 mỗi bên ăn 48, chừa **20px cho chữ**:
  "Again" render thành **"Ag"**, ba nhãn còn lại vỡ giữa từ — ở **text scale
  bình thường**, `exception: null`, không overflow, không có gì để một widget
  test nhận ra. Giảm còn 12 mỗi bên thì nhãn được 44px, cả bốn hiện đủ và nút
  về lại đúng 48 cao (trước đó là 64 vì nhãn xuống hai dòng).
  
  Áp cho `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`.
  `minimumSize` không đụng tới, nên ngưỡng chạm nguyên vẹn — có test.
- **Bốn nút một hàng vẫn là bố cục sai ở 320, kể cả sau khi sửa.** 44px cho
  nhãn là vừa đủ cho "Again", không đủ cho bản dịch dài hơn, và ở textScaler
  2.0 nút cao 104. Câu trả lời đúng là **bố cục** — 2×2 hoặc `Wrap` — chứ
  không phải token, và nó thuộc **M5** khi màn Review được dựng. Ghi lại ở đây
  để M5 không bắt đầu bằng một hàng bốn nút.
- **Dependencies:** M3.4, M3.5, M3.6, M4.8, M4.8a
- **Tests required:** cỡ chữ compact vs thường theo từng role, padding theo
  bề rộng, ngưỡng chạm, biên 360 loại trừ, golden 320 light/dark
- **Checklist phases:** 7.1, 7.4

### M4.9 · Deck/Card domain và data vertical foundation

- **Status:** done
- **Goal:** Chỉ xây domain và data mà Deck/Card management có caller thật, đủ để
  UI chạy xuyên suốt xuống Drift.
- **Scope:** **Domain** — `DeckEntity`, `CardEntity`, phần
  `CardReviewStateEntity` cần để tạo card đúng BR-09, `SchedulerType`,
  `DeckContentType`, command/value object khi có caller thật, repository contract
  theo UC-02, UC-03, UC-04, UC-08, UC-09. **Data** — DAO Deck/Card, mapper,
  repository implementation, mapping `Failure`, `watch()` stream, transaction cho
  thao tác nhiều bước.
- **Out of scope:** `StudySessionEntity`, `ReviewHistoryEntity`, `ReviewKind`,
  `ReviewAction`, `SessionStatus`, `SessionEndReason`, review persistence,
  scheduler formula, review use case (tất cả → **M5.0**, **M5.1**); controller UI.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/deck/domain/`, `lib/features/deck/data/`
- **Acceptance criteria:**
  - [x] `domain/` không import Flutter hay Drift; contract không nhận/trả kiểu
        sinh bởi Drift (AD-01). → `check_architecture.sh` + guard pass; test
        purity trong `deck_domain_test.dart` grep import từng file domain.
  - [x] Entity immutable, value equality; trạng thái hữu hạn là enum. → Freezed
        cho 4 type; `SchedulerType`/`DeckContentType` là enum có `unknown`.
  - [x] Enum lạ đọc từ database map về `unknown`, và `unknown` **không** được ghi
        ngược xuống database. → `fromDbValue('sm18') == unknown`;
        `unknown.dbValue` throws `StateError` — có test cả hai chiều.
  - [x] Repository đọc bằng `watch()` — test khẳng định stream phát lại. → 6
        test trong `deck_repository_watch_test.dart`: initial emit, re-emit sau
        insert/update/delete, card stream, tree stream.
  - [x] Không exception thô của Drift/SQLite thoát khỏi repository; conflict đã
        biết map thành `ConflictFailure`. → trigger `RAISE(ABORT)` thật trên
        `cards` → bắt được `Failure`; PK trùng thật → `ConflictFailure`;
        `drift_error_mapper.dart` đổi constraint → `ConflictFailure`, có
        table-driven test 7 case.
  - [x] Tạo card sinh **đúng một** review state, atomic (BR-09); insert state
        lỗi thì card rollback. → trigger `RAISE(ABORT)` trên
        `card_review_states`: card **và** content-type lock cùng rollback;
        `eight_box` khởi tạo box 1, `sm2` khởi tạo 2.5/0/0 — đều đọc lại từ row
        thật.
  - [x] Lần tạo child đầu tiên khoá `content_type` **trong cùng transaction**
        (BR-62). → trigger chặn insert child: parent giữ nguyên `unset`.
  - [x] Move subtree cập nhật `root_deck_id` cho **toàn bộ** subtree, atomic
        (BR-71). → cây 3 cấp + grand-leaf move sang root khác, mọi node trỏ root
        mới; trigger chặn node sâu nhất → parent pointer, root pointer và
        content-type của target đều rollback.
  - [x] Reset `content_type` bị chặn khi deck chưa rỗng (BR-68). →
        `ConflictFailure` khi còn card, còn child deck, và trên root.
  - [x] Toàn bộ 14 bất biến của M4.4 vẫn pass sau bộ repository test. → suite
        `test/database/` 67 test pass; thêm sweep 14 query trên dữ liệu do
        chính repository ghi (2 root khác scheduler, move, rename, delete).
  - [x] Web phát được query Drift **thật** — đóng phần chưa kiểm còn lại của
        M4.2. → `deck_repository_web_test.dart` chạy `flutter test --platform
        chrome`: mở production `AppDatabase.open()`, insert cây 3 cấp + card,
        chạy `deckById`/`subtreeDeckIds` (recursive CTE)/`reviewStateByCard`
        typed query và `watchRootDecks()` thật, dọn fixture, đóng database.
        Phát hiện và sửa hai lỗi production: `driftDatabase()` thiếu `web:`
        options (web chưa từng mở được database), và `drift_worker.js` prebuilt
        từ release drift 2.34.0 lệch ABI với `sqlite3.wasm` 3.5.0
        (`LinkError: xFileControl`) — worker nay compile từ đúng lockfile, quy
        trình ghi ở `web/WEB_ASSETS.md`.
- **Files:** domain — `deck_entity.dart`, `card_entity.dart`,
  `card_review_state_entity.dart`, `scheduler_type_model.dart`,
  `deck_content_type_model.dart` (hai enum mang hậu tố `_model` vì guard
  `memox.naming.domain_file_role_suffix` bắt buộc hậu tố role),
  `deck_deletion_impact_model.dart`, `deck_repository.dart`. Data —
  `local/deck_dao.dart`, `deck_mapper.dart`, `card_mapper.dart`,
  `card_review_state_mapper.dart`, `deck_repository_impl.dart` (+ 2 part
  `card_write_deck_repository_impl.dart`, `move_deck_repository_impl.dart` để
  giữ mỗi file dưới giới hạn của guard). Query —
  `lib/core/database/queries/deck.drift` (include vào `app_database.dart`,
  schema v1 không đổi). Core sửa: `failure.dart` (`implements Exception` để
  throw được dưới `only_throw_errors`), `drift_error_mapper.dart`
  (constraint → `ConflictFailure`), `connection.dart` (web options + đường dẫn
  asset root-absolute). Test — `test/features/deck/**` (harness + 8 file),
  `test/flutter_test_config.dart` (bỏ nạp font khi `kIsWeb`),
  `test/database/web_assets_test.dart` (+2 test parity), `test/sqlite3.wasm`
  + `test/drift_worker.js` (bản sao được test parity giữ đồng bộ).
- **Tests đã chạy:** 77 test `test/features/deck` trên VM (17 domain + 11
  mapper + 49 integration trên SQLite thật, không mock) + 1 web runtime trên
  Chrome + 67 `test/database` (gồm 14 bất biến hai chiều) + 9
  `test/core/error`. Verification: `dart format` sạch · `flutter analyze` 0/0
  · `check_architecture.sh` pass · guard `memox-v7` 0 violation ·
  `check_docs.sh` pass · `flutter test --platform chrome
  test/features/deck/data/web/deck_repository_web_test.dart` pass.
- **Ghi chú môi trường:** bộ golden pixel-comparison (M3/M4.8, baseline sinh
  trên Windows) fail y hệt trên checkout sạch ở Linux vì khác font
  rasterization — không liên quan M4.9; mọi test không-golden pass 100%.
- **Operation phải đủ cho:** đọc cây root và descendant · tạo root deck kèm chọn
  scheduler · tạo sub-deck · khoá `content_type` ở child đầu tiên · đổi tên · đếm
  descendant/card trước khi xoá · xoá cascade · reset `content_type` khi rỗng ·
  di chuyển subtree · đọc card theo deck · tạo card kèm đúng một review state ·
  sửa card không đụng review state/history · xoá card · stream phát lại.
- **Dependencies:** M4.3, M4.4, M4.8
- **Tests required:** unit domain, mapper (gồm enum lạ), repository integration
  trên database thật, transaction, rollback, stream, và chạy lại 14 bất biến
- **Checklist phases:** 11.1, 14.2, 14.3, 15.1

### M4.9a · Giới hạn 10 cấp và tách Deck/Card repository

- **Status:** done
- **Goal:** Enforce quyết định product "deck tối đa 10 cấp" ở write boundary,
  làm subtree traversal cycle-safe không truncate, và tách Card khỏi
  `DeckRepository`/`DeckDao` thành boundary riêng.
- **Scope:** hằng số domain `DeckEntity.maxTreeDepth = 10` (root là cấp 1);
  depth guard trong `createSubDeck` và `moveDeck` (chặn **trước** mọi
  mutation, trong cùng transaction); hai probe query `deckDepthProbe` /
  `subtreeHeightProbe` nhận giới hạn duyệt qua parameter; ba subtree query
  chuyển sang recursive `UNION` cycle-safe, bỏ hẳn cap `depth < 64` production;
  bất biến Q15 (deck sâu hơn 10 cấp); `CardRepository` +
  `CardRepositoryImpl` + `CardDao` độc lập (không còn `part of` deck impl);
  `card.drift` tách query card thuần; `.gitattributes` cho cặp asset `test/`;
  đồng bộ docs (BR-55, UC-08 E4, UC-09 depth formula + E5, data-model,
  CLAUDE.md, AD-10, README).
- **Out of scope:** UI/controller/provider (M4.10, M4.11); Review domain (M5);
  đổi schema.
- **Editable documents:** `docs/wbs.md`, `docs/business-rules.md`,
  `docs/use-cases.md`, `docs/data-model.md`, `docs/architecture.md`,
  `docs/README.md`, `CLAUDE.md`,
  `.claude/skills/flutter-workflow/scripts/verify_invariants.py`
- **Output:** `lib/features/deck/domain/card_repository.dart`,
  `lib/features/deck/data/card_repository_impl.dart`,
  `lib/features/deck/data/local/card_dao.dart`,
  `lib/core/database/queries/card.drift`, sửa `deck.drift`, `deck_dao.dart`,
  `deck_repository_impl.dart`, `move_deck_repository_impl.dart`,
  `deck_entity.dart`, `.gitattributes`, test mới
  `deck_repository_depth_test.dart` + `deck_card_boundary_test.dart`
- **Acceptance criteria:**
  - [x] Root là cấp 1, tối đa 10 cấp — một hằng số duy nhất
        `DeckEntity.maxTreeDepth`, SQL nhận giới hạn qua parameter.
  - [x] Tạo được deck ở cấp 10; cấp 11 bị chặn atomic — parent giữ nguyên
        `content_type` (kể cả `unset`), không deck mới, không đổi timestamp.
  - [x] Move tới đúng cấp 10 thành công (`targetDepth + subtreeHeight <= 10`,
        nguồn tính chiều cao 1); vượt bị chặn — không đổi `parent_deck_id`,
        `root_deck_id`, `content_type` đích hay timestamp.
  - [x] `subtreeDeckIds` / `subtreeCardCount` / `updateSubtreeRootDeck` dùng
        recursive `UNION` cycle-safe: dữ liệu có cycle trả về **đủ** tập
        reachable và kết thúc, không truncate im lặng; deletion impact và root
        rewrite đúng trên chuỗi đủ 10 cấp — có test.
  - [x] Cycle guard BR-70 giữ nguyên; probe gặp ancestry có cycle → từ chối
        (`ConflictFailure`), có test trên dữ liệu corrupt thật.
  - [x] `DeckRepository` chỉ còn Deck operations; `CardRepository` /
        `CardRepositoryImpl` / `CardDao` độc lập; `createCard` vẫn atomic
        (content lock + đúng một review state, trigger-injected rollback pass);
        `deck_card_boundary_test.dart` ghim ranh giới bằng source facts.
  - [x] Bất biến Q15 thêm vào `data-model.md` + `invariant_queries.dart` +
        `verify_invariants.py` (BAD case), pair test hai chiều pass — 15/15.
  - [x] `.gitattributes`: hai cặp asset cùng attribute (`binary` cho wasm,
        `-text` cho worker JS), `git ls-files --eol` xác nhận tương đương,
        copy `test/` byte-identical với `web/`. Bản LF là bản chính: banner
        provenance một dòng ở đầu cả hai bản worker đổi blob, nên mọi
        checkout — kể cả worktree Windows đã smudge CRLF trước khi có
        attribute — được git checkout lại thành LF ngay lần pull kế
        (`web/WEB_ASSETS.md`); không còn bước re-smudge thủ công.
- **Tests đã chạy:** `test/features/deck` 93 pass (thêm 9 depth + 5 boundary);
  `test/database` 69 pass (15 invariant hai chiều);
  `verify_invariants.py` 15/15 "TẤT CẢ ĐẠT"; web runtime Chrome pass; format /
  analyze / architecture / guard / `check_docs.sh` pass.
- **Dependencies:** M4.9
- **Tests required:** depth boundary (10 pass / 11 chặn, create + move),
  rollback atomic, cycle-safe traversal trên dữ liệu corrupt, boundary
  separation, invariant Q15 hai chiều, web runtime
- **Checklist phases:** 11.1, 14.2, 14.3, 15.1

### M4.10 · Deck management full-stack

- **Status:** todo
- **Goal:** Người dùng quản lý được toàn bộ cây deck từ UI xuống Drift, không cần
  fixture hay thao tác database thủ công.
- **Scope:** named route; root deck list; điều hướng deck lồng nhau; deck detail;
  tạo root deck kèm chọn scheduler; tạo sub-deck; đổi tên; xác nhận xoá kèm số
  deck/card sẽ mất; action theo `content_type`; reset `content_type` khi rỗng;
  move subtree trong phạm vi MVP; Riverpod state/controller; loading, loaded,
  empty, submitting, error; ARB en/vi; widget riêng của feature.
- **Out of scope:** card editor (M4.11); review session (M5); UI thư viện starter
  (UC-01); sync/backend; media và tag.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/deck/presentation/`, `lib/l10n/`,
  `test/features/deck/`, `test/visual_audit/screens/features/deck/`
- **Acceptance criteria:**
  - [ ] Cold start mở **root deck list**, không phải review placeholder.
  - [ ] Root chỉ cho tạo deck (BR-58); tạo root **bắt buộc** chọn scheduler
        (BR-11).
  - [ ] Sub-deck `unset` cho chọn *Create card* hoặc *Create deck*; deck đã có
        `content_type` chỉ hiện đúng một action (BR-63, BR-64).
  - [ ] Đổi tên validate trim, tối đa 200 ký tự (BR-01).
  - [ ] Xác nhận xoá hiển thị số deck và card sẽ mất (BR-03).
  - [ ] Cây hỗ trợ **ít nhất ba cấp** (BR-55).
  - [ ] Move không cho vào chính nó hoặc descendant (BR-69); move sang root khác
        scheduler/generation bị chặn (BR-70).
  - [ ] Dữ liệu tự cập nhật qua stream — không cần refresh thủ công.
  - [ ] Toàn bộ copy từ ARB; không raw color, text style, spacing hay radius.
  - [ ] 320×568 và `textScaler` 2.0 không overflow.
  - [ ] Mọi production screen đăng ký strict visual audit (MX-VIS-001), và đạt
        **PASS** ở light lẫn dark — không chấp nhận `PASS_WITH_UNRESOLVED`.
  - [ ] Screen có design reference đạt pixel difference **dưới 3%** trước merge.
- **Dependencies:** M4.9, M4.1, M4.1a
- **Tests required:** domain, repository, controller, widget, route, visual audit
  strict, responsive, flow test
- **Checklist phases:** 8.2, 9.2, 9.3, 14.4, 15.2, 15.3, 15.4

### M4.11 · Card management full-stack

- **Status:** todo
- **Goal:** Người dùng quản lý card hoàn chỉnh trong deck loại `card`, từ UI
  xuống transaction Drift.
- **Scope:** card list; empty state; tạo card; tạo card **đầu tiên** trong deck
  `unset`; editor front/back; sửa; xoá; luồng *add another*; validation; Riverpod
  state/controller; route; ARB en/vi; `CardTile`/`CardEditor` đặt trong feature.
- **Out of scope:** review scheduler (M5.1); review history UI; import/export;
  media; rich text.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/card/`, `lib/l10n/`, `test/features/card/`,
  `test/visual_audit/screens/features/card/`
- **Acceptance criteria:**
  - [ ] `front`/`back` trim không được rỗng, tối đa 2000 ký tự (BR-07, BR-08).
  - [ ] Card đầu tiên khoá `content_type = card` **trong cùng transaction**
        (BR-62, BR-63).
  - [ ] Tạo card sinh **đúng một** review state, khớp scheduler và generation của
        root (BR-09); cả `eight_box` lẫn `sm2` khởi tạo đúng.
  - [ ] Sửa card **không** đụng review state hay history (BR-10).
  - [ ] Xoá card kéo theo review state và history bằng cascade.
  - [ ] Xoá card cuối **không** tự chuyển `content_type` về `unset` (BR-67).
  - [ ] *Add another* giữ editor mở và xoá form sau khi lưu.
  - [ ] Lỗi persistence **giữ lại** nội dung form.
  - [ ] Double-submit không tạo hai card.
  - [ ] Card list tự cập nhật qua stream.
  - [ ] Toàn bộ copy từ ARB; không raw style hay token.
  - [ ] 320×568 và `textScaler` 2.0 không overflow.
  - [ ] Mọi production screen có strict visual audit **PASS** ở light và dark.
  - [ ] Screen có design reference đạt pixel difference **dưới 3%**.
- **Dependencies:** M4.10
- **Tests required:** domain, repository transaction và rollback, controller,
  form validation, widget, visual audit strict, route
- **Checklist phases:** 9.2, 9.3, 14.4, 15.1, 15.2, 15.3, 15.4

### M4.12 · Deck/Card demo hardening, fixture và E2E

- **Status:** todo
- **Goal:** Đưa app tới trạng thái **demo được** bằng luồng Deck/Card hoàn chỉnh,
  trước khi bắt đầu Review.
- **Scope:** fixture cho development/test; seed helper dùng **chính** repository
  và loader thật; persistence qua restart; Flutter Web + Playwright ở mobile
  viewport với thao tác trực tiếp trên UI; visual state matrix; regression toàn
  slice; thay `ReviewPlaceholderScreen` làm entrypoint nếu còn; dọn placeholder
  và navigation demo-only không còn caller.
- **Out of scope:** Review session (M5); nội dung production (BR-87, trước M8);
  sync/backend.
- **Editable documents:** `docs/wbs.md`
- **Output:** `assets/templates/`, `lib/features/deck/data/template_loader.dart`,
  `test/helpers/seed.dart`, `integration_test/`
- **Acceptance criteria:**
  - [ ] App demo được **không** cần sửa database bằng tay.
  - [ ] App không còn chỉ hiện placeholder.
  - [ ] Fixture: một root `eight_box`, một root `sm2`, cây **ít nhất ba cấp**,
        leaf chứa card; manifest ghi rõ là fixture development/test (BR-87).
  - [ ] Nạp fixture **hai lần** không nhân bản (BR-37).
  - [ ] Đủ 14 bất biến pass **sau seed** và **sau E2E**.
  - [ ] Playwright resize đúng mobile viewport và click trực tiếp trên UI.
  - [ ] Luồng chính chạy qua Flutter Web; persistence còn sau reload/restart theo
        khả năng của target.
  - [ ] Mọi production screen strict visual audit **PASS** ở light và dark.
  - [ ] State matrix phủ loading, empty, loaded, submitting, error và confirmation
        — với screen có state đó.
  - [ ] Design parity dưới 3% cho screen có baseline.
  - [ ] `flutter test` full pass; **một** `flutter build web` ở integration gate;
        không build APK như validation mặc định.
  - [ ] Báo cáo demo flow kèm bằng chứng từng bước.
- **Luồng E2E bắt buộc:** cold start app trống → tạo root deck và chọn scheduler
  → tạo branch → tạo leaf deck → chọn *Create card* → tạo card → sửa card → quay
  lại cây → đóng và mở lại app → **dữ liệu vẫn còn** → xoá card → xoá deck.
- **Luồng kiểm thêm:** `content_type = deck` · `content_type = card` · reset
  `content_type` khi rỗng · thao tác trên cây ba cấp · persistence thật trên Web
  · cả `eight_box` lẫn `sm2`.
- **Dependencies:** M4.11, M4.4
- **Tests required:** integration, Playwright E2E, persistence, fixture,
  invariant, visual audit, full regression
- **Checklist phases:** 11.1, 14.4, 15.1–15.5

---

## M5 · Review vertical slice — UC-05

Mục tiêu: luồng ôn tập chạy xuyên suốt Drift → data source → repository → use
case → controller/state → router → màn hình → ghi kết quả → UI cập nhật.

**Không còn là vertical slice đầu tiên.** Quản lý Deck/Card đã hoàn thành ở
M4.8–M4.12, và M5 **không** triển khai lại phần đó — nó xây đúng phần Review.
Điều kiện bắt đầu: **M4.12 `done`**. Review MUST NOT bắt đầu trước mốc đó, vì
không có cây deck và card thật thì phiên ôn không có gì để ôn, và mọi test của nó
sẽ phải dựng dữ liệu bằng tay — thứ M4.12 tồn tại để thay thế.

**Ngoài phạm vi M5** (nêu một lần, áp cho mọi task bên dưới): import/export,
login, backend, sync, media, statistics, settings, và UI thư viện starter deck.
CRUD deck/card **đã xong ở M4**, không lặp lại ở đây.

### M5.0 · Review-specific domain và data completion

- **Status:** todo
- **Goal:** Bổ sung đúng phần domain và data mà **chỉ Review** cần, sau khi
  Deck/Card demo slice đã hoàn thành.
- **Scope:** `StudySessionEntity`, `ReviewHistoryEntity`, `ReviewAction`,
  `ReviewKind`, `SessionStatus`, `SessionEndReason`; phần `CardReviewStateEntity`
  dành cho review; repository contract mở rộng cho UC-05; DAO/mapper/repository
  cho session, history và ghi review atomic.
- **Out of scope:** scheduler formula (M5.1); review use case (M5.2); controller
  và UI (M5.3, M5.4).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/review/domain/`, `lib/features/review/data/`
- **Acceptance criteria:**
  - [ ] `domain/` là Dart thuần — không Flutter, không Drift.
  - [ ] Enum phủ **đúng** tập giá trị của BR-75, BR-79, BR-80.
  - [ ] Repository contract không nhận hay trả kiểu sinh bởi Drift (AD-01).
  - [ ] Cập nhật card state và insert history là **một** transaction — nửa vời
        không tồn tại được (BR-86).
  - [ ] Chuyển trạng thái session enforce đúng ma trận `status` × `end_reason`
        (BR-79…BR-85), và bất biến 12 vẫn pass sau bộ test.
  - [ ] Không exception persistence thô nào thoát khỏi repository.
  - [ ] Không thêm API nào chưa có caller trong M5.1–M5.5.
- **Vì sao tách khỏi M4.9.** Domain của Review chỉ có caller khi scheduler và use
  case tồn tại. Gộp nó vào M4.9 sẽ lặp lại đúng sai lầm của M4.5: viết contract
  cho một presentation chưa có mặt.
- **Dependencies:** M4.12
- **Tests required:** entity, enum, mapper, repository transaction, rollback
- **Checklist phases:** 14.2, 14.3, 15.1

### M5.1 · `ReviewScheduler` và hai implementation

- **Status:** todo
- **Goal:** Logic xếp lịch là hàm thuần khiết, test được toàn bộ ma trận.
- **Scope:** `domain/scheduler/review_scheduler.dart` với `supportedActions`,
  `EightBoxScheduler` (BR-15, BR-16), `Sm2Scheduler` (BR-17, BR-18, BR-19), bảng
  interval trong scheduler config.
- **Out of scope:** dùng scheduler trong controller (M5.3) hay ghi DB (M5.2).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/review/domain/scheduler/`
- **Acceptance criteria:**
  - [ ] `next()` không gọi `DateTime.now()`; `now` là tham số (AD-06).
  - [ ] `EightBoxScheduler.supportedActions` = `[forgotten, remembered]`;
        `Sm2Scheduler.supportedActions` = `[again, hard, good, easy]` (BR-30).
  - [ ] Ma trận 8 box × 2 action của `eight_box` đều có test và khớp BR-15,
        BR-16.
  - [ ] `sm2`: `ease_factor` không bao giờ xuống dưới 1.3 kể cả sau 50 lượt
        `again` liên tiếp (BR-19) — có test.
  - [ ] `sm2`: `repetitions` 0 → interval 1; 1 → 6; ≥2 → `round(interval * ef)`
        (BR-18) — có test.
  - [ ] Card box 8 trả lời `remembered` vẫn ở box 8, hạn +128 ngày (BR-16).
  - [ ] `domain/scheduler/` không import Flutter hay Drift.
- **Dependencies:** M5.0
- **Tests required:** unit test toàn ma trận `eight_box`; unit test công thức
  `sm2` gồm biên sàn ease factor; test `supportedActions` của cả hai
- **Checklist phases:** 14.2, 15.1

### M5.2 · Use case phiên ôn và ghi kết quả

- **Status:** todo
- **Goal:** Logic phiên ôn nằm ở domain: mở phiên, lấy card đến hạn, ghi đánh
  giá đúng `review_kind`, từ chối generation cũ.
- **Scope:** `StartStudySessionUseCase`, `SubmitReviewUseCase`,
  `EndStudySessionUseCase`; xác định `review_kind` tường minh (BR-76);
  kiểm `scheduler_generation` (BR-46, BR-84); giới hạn 50 card (BR-24).
- **Out of scope:** hàng đợi và thứ tự trong phiên (M5.3 — đó là trạng thái tạm
  của controller).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/review/domain/usecase/`
- **Acceptance criteria:**
  - [ ] Lượt đầu của một card trong phiên ghi `review_kind = scheduled`; lượt sau
        ghi `relearning` (BR-77, BR-78) — test khẳng định.
  - [ ] Lượt `relearning` **không** đổi `current_box`, `ease_factor`,
        `interval_days`, `due_at`; **có** đổi `last_reviewed_at` (BR-78).
  - [ ] Card box 8 + `remembered` vẫn được ghi `scheduled` dù box không đổi
        (BR-76) — test khẳng định, đây là ca mà suy luận sẽ sai.
  - [ ] Ghi review từ session có generation cũ → ném `Failure`, **không** ghi
        `review_history`, session chuyển `invalidated`/`stale_generation`
        (BR-84).
  - [ ] `review_count` chỉ tăng ở lượt `scheduled`; `lapse_count` tăng khi
        `forgotten`/`again` ở lượt `scheduled` (BR-20).
  - [ ] Một phiên lấy tối đa 50 card riêng biệt (BR-24).
- **Dependencies:** M5.1, M5.0
- **Tests required:** unit test cho từng acceptance criteria ở trên, dùng
  repository fake; test riêng cho ca box-8 và ca generation cũ
- **Checklist phases:** 14.2, 15.1

### M5.3 · Controller, state và hàng đợi phiên ôn

- **Status:** todo
- **Goal:** State immutable tách dữ liệu khỏi trạng thái tác vụ, hàng đợi xử lý
  đúng luật `relearning`.
- **Scope:** `ReviewSessionState` (freezed), `ReviewSessionController`
  (`@riverpod`), hàng đợi với luật đưa card `forgotten`/`again` quay lại sau ít
  nhất 3 card (BR-26, BR-28), chống bấm đúp.
- **Out of scope:** widget (M5.4).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/review/presentation/state/`,
  `lib/features/review/presentation/controller/`
- **Acceptance criteria:**
  - [ ] State immutable, có value equality; **không** có một `isLoading` chung
        cho mọi thao tác.
  - [ ] Controller không giữ `BuildContext`.
  - [ ] Card `forgotten` quay lại sau ít nhất 3 card khác, hoặc cuối hàng đợi nếu
        không đủ 3 (BR-26) — test khẳng định cả hai nhánh.
  - [ ] Bấm hai lần liên tiếp cùng một action chỉ ghi **một** review — test
        khẳng định.
  - [ ] Đánh giá sau khi controller bị dispose không throw (`ref.mounted`).
  - [ ] Test chuyển trạng thái: initial → loading → loaded; loading → error;
        submitting thành công; submitting thất bại.
- **Dependencies:** M5.2, M3.3
- **Tests required:** controller test cho toàn bộ chuyển trạng thái ở trên, chạy
  bằng `ProviderContainer`, không cần widget
- **Checklist phases:** 9.2, 9.3, 15.2

### M5.4 · Màn hình ôn tập và route

- **Status:** todo
- **Goal:** Màn hình render đủ mọi trạng thái và nút đánh giá đúng theo
  scheduler.
- **Scope:** `ReviewSessionScreen`, route theo tên, widget con tách theo section,
  render nút từ `supportedActions` (BR-30), chuỗi lấy từ ARB.
- **Out of scope:** màn danh sách deck đầy đủ — chỉ cần một lối vào tối thiểu để
  mở phiên ôn từ fixture.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/review/presentation/screen/`,
  `lib/features/review/presentation/widget/`, route mới trong `app/router/`
- **Acceptance criteria:**
  - [ ] Deck `eight_box` hiện đúng **2** nút; deck `sm2` hiện đúng **4** nút
        (BR-30) — widget test cho cả hai.
  - [ ] Bốn trạng thái loading, empty, error, loaded đều có widget test.
  - [ ] Empty state khi không còn card đến hạn là thông điệp tích cực, **không**
        phải màn lỗi (BR-29).
  - [ ] Trong lúc ghi đánh giá, nội dung card vẫn hiện và các nút bị khoá.
  - [ ] `grep -rn "Text('" lib/features/review/presentation` không có kết quả —
        mọi chuỗi từ ARB.
  - [ ] Render ở 320×568 và `textScaler` 2.0 → `tester.takeException()` là null.
  - [ ] Light mode và dark mode đều có widget test.
- **Dependencies:** M5.3, M4.1, M3.6
- **Tests required:** widget test cho 4 trạng thái × 2 scheduler; test overflow
  màn nhỏ và text scale 2.0; test dark mode
- **Checklist phases:** 14.4, 15.3

### M5.5 · Vòng đời phiên và kết thúc đúng trạng thái

- **Status:** todo
- **Goal:** Phiên luôn kết thúc ở đúng `status` và `end_reason`, và review đã ghi
  không bao giờ mất.
- **Scope:** chuyển trạng thái `completed` / `abandoned` / `invalidated` /
  `failed` kèm `end_reason` (BR-81…BR-86), màn tổng kết phiên tối thiểu.
- **Out of scope:** thống kê đầy đủ (ngoài MVP slice).
- **Editable documents:** `docs/wbs.md`
- **Output:** cập nhật use case và controller của M5.2, M5.3; widget tổng kết
- **Acceptance criteria:**
  - [ ] Hết hàng đợi → `completed`, `end_reason` NULL, `ended_at` được đặt
        (BR-81).
  - [ ] Người dùng thoát → `abandoned` / `user_exit` (BR-82).
  - [ ] Reset deck khi phiên đang mở → `invalidated` / `scheduler_reset`
        (BR-83).
  - [ ] Ghi thất bại không thể tiếp tục → `failed` / `persistence_error`
        (BR-85).
  - [ ] Ở **cả bốn** trường hợp, review đã ghi thành công vẫn còn trong
        `review_history` (BR-86) — test khẳng định từng trường hợp.
  - [ ] Không tổ hợp `status` × `end_reason` nào ngoài ma trận ở `data-model.md`
        — bất biến Q12 của M4.4 vẫn pass sau khi chạy các luồng này.
- **Dependencies:** M5.3, M4.4
- **Tests required:** repository/use case test cho bốn cách kết thúc; test khẳng
  định `review_history` được giữ ở cả bốn
- **Checklist phases:** 14.4, 15.1, 15.2

### M5.6 · Integration test luồng UC-05

- **Status:** todo
- **Goal:** Chứng minh slice chạy thật xuyên suốt trên thiết bị, không chỉ ở
  unit test.
- **Scope:** `integration_test/review_flow_test.dart` chạy đúng luồng chính của
  UC-05 trên fixture của M4.12.
- **Out of scope:** Playwright + Flutter Web (M7 sẽ nối vào CI).
- **Editable documents:** `docs/wbs.md`
- **Output:** `integration_test/`
- **Acceptance criteria:**
  - [ ] Cold start → mở deck fixture → phiên ôn → đánh giá một card → thoát →
        mở lại → card đã ôn **không** còn đến hạn.
  - [ ] Đánh giá `forgotten` → card quay lại trong phiên → đánh giá
        `remembered` → hôm sau vẫn ở box 1 (BR-77) — assert trên database.
  - [ ] Chạy trên deck `eight_box` và deck `sm2`, đúng số nút mỗi loại.
  - [ ] `flutter test integration_test/` exit 0 trên emulator Android.
  - [ ] `flutter build web` vẫn exit 0 sau toàn bộ M5 — kênh E2E còn sống
        (AD-04).
- **Dependencies:** M5.4, M5.5, M4.12
- **Tests required:** đây **là** task test — integration test luồng chính
- **Checklist phases:** 15.5


---

## Blocker

| Blocker | Ảnh hưởng | Cách gỡ |
|---|---|---|
| Flutter SDK không tồn tại sẵn trong container | Mỗi phiên phải cài lại (~1.5 GB, vài phút) | Đã cài thủ công vào `/opt/flutter` ở M2.1. Container là ephemeral nên cần **SessionStart hook** để phiên sau tự dựng lại — chưa làm, xếp vào M2.2. **Chỉ áp dụng cho môi trường cloud**; máy local có Flutter cài sẵn |
| **WebGL không khả dụng trong Chromium headless của container** | Flutter 3.44 chỉ còn renderer CanvasKit/skwasm, cả hai cần WebGL; HTML renderer đã bị gỡ từ 3.29. App build được nhưng **không render** — screenshot ra trang trắng. Chặn visual regression và E2E bằng Playwright ngay trong container | **Không còn là blocker của kiến trúc — chỉ là ràng buộc môi trường.** Đã kiểm chứng ở máy local: WebGL2 khả dụng (`ANGLE (AMD Radeon, D3D11)`) và app render đúng ở cả hai viewport. AD-04 giữ nguyên, phần Consequences đã ghi rõ runner E2E MUST có WebGL (GPU thật hoặc SwiftShader) và job MUST assert app đã render thật trước khi so ảnh |

**Đã gỡ — `dl.google.com` bị chính sách mạng chặn (403 CONNECT).** Blocker này
chặn việc cài Android SDK và việc Gradle tải Android Gradle Plugin, khiến hai
tiêu chí Android của M2.1 không kiểm chứng được. Nó **chỉ áp dụng cho môi trường
cloud** nơi network policy chặn `dl.google.com`, **không** phải khuyết tật của
project: trên máy local có Android SDK, `flutter doctor -v` sạch và
`flutter build apk --debug` exit 0 mà không sửa một dòng code nào — đúng như dự
đoán lúc hoãn.

Hệ quả còn lại cho M7: mọi job build Android **MUST** chạy ở môi trường truy cập
được `dl.google.com`. Đây là ràng buộc khi chọn CI runner, không còn là blocker
của M2.

## Deferred and descoped

| Item | Decision | Reason | Revisit when |
|---|---|---|---|
| `custom_lint` + `riverpod_lint` | descoped khỏi MVP | Không có phiên bản `custom_lint` nào tương thích `analyzer >=10`, trong khi `json_serializable`, `freezed` và `drift_dev` đều đòi mức đó. Cài được chỉ bằng cách hạ toàn bộ stack generator một thế hệ, kể cả `uuid` về `^3.0.6` — đi ngược AD-03. Chủ dự án quyết định không cần; nếu cần sẽ làm guard bên ngoài | Khi `custom_lint` hỗ trợ `analyzer >=10`, **hoặc** khi một guard ngoài được viết. Xem mục bên dưới về việc mất gì |
| Flutter toolchain verification | **đã xong** | Từng hoãn vì `flutter` chưa có trong môi trường cloud | Đã kiểm chứng ở M2.1 trên máy local: `flutter doctor -v` → `No issues found!` |
| Đưa deck con lên thành root deck | descoped khỏi MVP | Cần quyết định scheduler mới; là tính năng riêng chứ không phải phép di chuyển | Sau MVP (UC-09 A2) |
| Media và tag | descoped khỏi MVP | Kéo theo lưu trữ file và đồng bộ file | Sau MVP; quy tắc reset và lưu trữ đã đặt sẵn (BR-41, AD-08) |

### Bỏ `riverpod_lint` thì mất chính xác cái gì

Ghi lại cụ thể, vì "mất một bộ lint" là câu quá mơ hồ để ai đó sau này biết
guard ngoài phải nhắm vào đâu. `flutter analyze` **không** bắt được những lỗi
dưới đây, và từ giờ **không có gì** bắt chúng:

| Lỗi | Vì sao nguy hiểm |
|---|---|
| `ref.read` bên trong `build()` | Đọc giá trị mà **không** subscribe, nên widget âm thầm ngừng cập nhật. Biểu hiện ra ngoài là "dữ liệu bị cũ" — rất khó lần ngược về nguyên nhân. Đây là rule đáng giá nhất trong bộ |
| Provider thiếu khai báo dependency | Provider bị scope sai, lỗi chỉ lộ khi override trong test hoặc khi scope thay đổi |
| Dùng `ref` sau `await` mà không kiểm `ref.mounted` | Ghi state vào controller đã dispose |
| Notifier có public property ngoài `state` | State thoát khỏi kênh duy nhất được theo dõi, làm rebuild không kích hoạt |

**Đã có guard thay thế (M2.2b).** Ba trong bốn mục trên nay được
`code-verification-guard` bắt bằng ruleset `memox-v7`, gồm cả cái đáng giá nhất:

| Lỗi | Rule thay thế |
|---|---|
| `ref.read` trong `build()` | `memox.state_management.no_ref_read_in_build` |
| `ref` sau `await` không kiểm `ref.mounted` | `memox.state_management.state_write_after_await_requires_mounted` |
| Notifier có public mutable property | `memox.state_management.notifier_no_public_mutable_field` |
| Provider thiếu khai báo dependency | **chưa có** — cần phân tích graph, không diễn đạt được bằng regex; vẫn thuộc code review |

## Known technical debt

| Item | Incurred in | Cost of leaving it | Planned repayment |
|---|---|---|---|
| `check_architecture.sh` chưa có test tự động | T0.1 | Regression trong checker âm thầm ngừng enforce boundary | Fixture trong `test/tools/` khi `test/` tồn tại (M6) |
| ~~`analysis_options.yaml` chưa được áp dụng~~ | T0.1 | Bộ lint đã viết nhưng chưa được enforce; nhiều khả năng có tên rule sai hoặc đã deprecated | **Đã trả ở M2.3.** Dự đoán đúng: `immutable_classes` không tồn tại, `use_if_null_to_convert_nulls_to_bools` đã deprecated. Nghiêm trọng hơn cả hai: 11 rule chỉ nằm ở `errors:` nên **chưa bao giờ chạy** — đã chuyển hết sang `linter: rules:` và kiểm chứng bằng tiêm lỗi |
| ~~14 query bất biến chưa chạy trên database thật~~ | T1.3 | Bất biến mới được verify trên fixture Python, chưa chạm schema Drift nào | **Đã trả một phần ở M4.4.** Cả 14 chạy trên database SQLite thật do schema production tạo — 30 test, mỗi bất biến hai chiều, cộng một test chứng minh một khiếm khuyết chỉ kích hoạt đúng những bất biến thật sự phủ nó. `check_docs.sh --db` cũng chạy đủ 14 (trước đó chép tay **10/14** và vẫn báo thành công). **Chưa trả:** vẫn là database tạm trong test, chưa phải dữ liệu người dùng thật — cái đó cần M8 |
| Pin Flutter ở `.fvmrc` **khai báo** chứ không **cưỡng chế** | M2.2 | Chạy `flutter` trực tiếp trên máy có version khác vẫn build được và không cảnh báo. Đây đúng là lỗi đã xảy ra: M2.1 chạy 3.44.8, phiên sau khởi động trên 3.44.6, không có gì phát hiện ra | Thêm một check so `flutter --version` với `.fvmrc` vào `dod_check.sh`, và dùng `flutter-version-file: .fvmrc` ở job CI của M7 |
| ~~7 file skill vẫn bảo chạy `dart run custom_lint`~~ | M2.2 | Skill vẫn hướng dẫn cài và chạy một package không cài được; phiên sau sẽ tin skill và loay hoay | **Đã trả ở M2.2b.** Cả 7 file đã trỏ sang guard. `docs/checklist.md` **cố ý giữ nguyên**: nó `frozen for MVP`, và mục "Ngoài phạm vi: mọi quyết định riêng của memox" nói rõ nó mô tả quy trình 22 phase chung — `custom_lint` ở đó là khuyến nghị Flutter phổ thông, còn quyết định riêng của memox sống ở file này (§5 canonical location) |
| `dependencies.md` vẫn liệt kê `sqlite3_flutter_libs` | M2.2 | Package đó nay là tombstone (`0.6.0+eol`, không có native code). Skill nói sai còn tệ hơn không có skill — phiên sau sẽ cài lại nó | Sửa `.claude/skills/flutter-project-setup/references/dependencies.md`: thay bằng ghi chú rằng `sqlite3` 3.x cấp native lib qua native assets. Ngoài `Editable documents` của M2.2 nên chưa sửa ở đây |
| Nội dung starter là fixture, không phải nội dung production | T1.3 | Không phát hành được với nội dung này | Tìm nguồn nội dung có bản quyền rõ ràng trước M8 (BR-87) |
| `sqlite3.wasm` và `drift_worker.js` là binary vendored trong `web/` | M4.2 | Không có bước build nào sinh ra chúng và không có bước build nào báo khi chúng cũ: app compile, load, rồi **không mở được database**. Nâng `drift` mà quên tải lại worker không có triệu chứng nào cho tới khi ai đó mở trình duyệt | `test/database/web_assets_test.dart` so version trong `pubspec.lock` với version đã pin, kèm `web/WEB_ASSETS.md` ghi URL tải. Đã kiểm tiêm lỗi: đổi `drift` thành 2.99.0 làm test đỏ |
| Server phát web chưa gửi COOP/COEP | M4.2 | `crossOriginIsolated` là `false`, nên drift chọn backend lưu trữ kém hơn OPFS. Không có lỗi nào — chỉ là hiệu năng và độ bền khác đi, âm thầm | Thêm `Cross-Origin-Opener-Policy: same-origin` và `Cross-Origin-Embedder-Policy: require-corp` vào server phát web ở M7, và kiểm lại `crossOriginIsolated` trong E2E |
| Bản build web MUST dùng `--no-web-resources-cdn` | M2.1a | Mặc định Flutter tải CanvasKit từ `gstatic.com` lúc **runtime** dù đã bundle sẵn cục bộ. Trong môi trường chặn CDN, app im lặng không render — không có lỗi build nào cảnh báo | Đưa cờ này vào job `build-web` của CI ở M7, và vào mọi hướng dẫn chạy web |
| ~~`check_docs.sh` chỉ đếm task ID dạng `T*`, bỏ sót `M*`~~ | T1.4 | Báo "no duplicate WBS task IDs (8 tasks)" trong khi có 33 — **pass gây hiểu nhầm**, 25 task M2–M5 không được bảo vệ khỏi trùng ID | **Đã trả ở M2.1b.** Regex sửa thành `[TM][0-9]+(\.[0-9]+)?[a-z]?` (giờ báo 35 task), thêm check dependency resolve và check `M*` đủ field + acceptance criteria không rỗng. Cả ba verify bằng test tiêm lỗi, 4/4 case đạt |
