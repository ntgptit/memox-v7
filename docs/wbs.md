# WBS — work breakdown and progress ledger

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì đã xong, đang làm, bị chặn |
| **Scope** | Milestone, task, blocker, technical debt, mục đã descoped |
| **Source of truth for** | Trạng thái task · blocker · technical debt · quyết định descope |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M2.1 |
| **Last updated** | 2026-07-28 |

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
| M2 · Project foundation (Phase 2–3, 6) | in-progress | M2.1 / M2.1a / M2.1b / M2.2 / **M2.2b done**. `custom_lint` descoped, thay bằng **guard `memox-v7`** — cổng chính, đã nối vào `dod_check.sh`. Flutter pin ở `.fvmrc`. Tiếp theo: M2.3 |
| M3 · Architecture & design system (Phase 4–5, 7, 12–13) | todo | |
| M4 · Router & Drift foundation (Phase 8, 11) | todo | **Phase 10 (networking) hoãn** — AD-01, AD-05 |
| M5 · First vertical slice: luồng ôn tập (Phase 14) | todo | UC-05 |
| M6 · Test suite (Phase 15) | todo | Chạy song song M5, không phải sau |
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

- **Status:** todo
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
  - [ ] `flutter analyze` → 0 error, 0 warning.
  - [ ] `flutter analyze` **không** in cảnh báo dạng
        `unrecognized/removed lint rule` cho bất kỳ rule nào trong file.
  - [ ] Không còn tham chiếu `custom_lint` trong `analysis_options.yaml` ở gốc
        project — một plugin khai báo mà không cài được sẽ làm analyzer im lặng
        bỏ qua, đúng kiểu "cấu hình trông như đang chạy nhưng không chạy".
  - [ ] Mỗi rule bị bỏ so với bản trong skill được ghi vào WBS kèm lý do.
  - [ ] Mục technical debt "analysis_options.yaml chưa được áp dụng" được đánh
        dấu đã trả.
- **Dependencies:** M2.2
- **Tests required:** none — cấu hình lint; acceptance criteria đã là lệnh kiểm
- **Checklist phases:** 5.1

### M2.4 · Localization ARB foundation

- **Status:** todo
- **Goal:** Dựng hạ tầng l10n để **không chuỗi hiển thị nào** phải hardcode từ
  task sau trở đi.
- **Scope:** `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`,
  `flutter: generate: true`, `localizationsDelegates`, `supportedLocales`,
  fallback locale.
- **Out of scope:** dịch đầy đủ. Chỉ cần đủ chuỗi cho smoke test.
- **Editable documents:** `docs/wbs.md`
- **Output:** `l10n.yaml`, `lib/l10n/*.arb`, wiring trong `app.dart`
- **Acceptance criteria:**
  - [ ] `flutter gen-l10n` (hoặc `flutter pub get`) sinh `AppLocalizations`
        thành công.
  - [ ] App hiển thị ít nhất một chuỗi lấy từ ARB, không hardcode.
  - [ ] `app_vi.arb` có đủ key của `app_en.arb`; thiếu key thì fail.
  - [ ] Đặt locale không hỗ trợ → app rơi về locale mặc định, không hiện chuỗi
        rỗng.
  - [ ] Mỗi key trong ARB có `description`.
- **Dependencies:** M2.2
- **Tests required:** widget test dựng app ở `en` và `vi`, assert chuỗi lấy từ
  ARB; test parity key giữa hai file ARB
- **Checklist phases:** 12

### M2.5 · Flavor Android và entrypoint theo môi trường

- **Status:** todo
- **Goal:** Ba flavor cài song song được trên một máy, mỗi flavor có config
  riêng.
- **Scope:** `EnvConfig`, `main_development.dart` / `main_staging.dart` /
  `main_production.dart`, `productFlavors` trong Gradle, `applicationIdSuffix`,
  `resValue` app name.
- **Out of scope:** signing key production, iOS scheme (AD-04 hoãn iOS), secret
  thật.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/config/env_config.dart`, ba entrypoint,
  `android/app/build.gradle`
- **Acceptance criteria:**
  - [ ] `flutter build apk --debug --flavor development -t lib/main_development.dart`
        exit 0; tương tự cho `staging` và `production`.
  - [ ] Ba APK có `applicationId` khác nhau (verify bằng `aapt dump badging`
        hoặc tương đương).
  - [ ] Ba APK cài song song được trên cùng một thiết bị/emulator.
  - [ ] `EnvConfig` được đọc qua provider bị override trong bootstrap; provider
        gốc throw khi thiếu override.
  - [ ] Không có secret nào trong repo; `env/` nằm trong `.gitignore`.
- **Dependencies:** M2.1
- **Tests required:** unit test khẳng định ba `EnvConfig` có `apiBaseUrl`,
  `logLevel` và `appName` khác nhau; test provider gốc throw khi chưa override
- **Checklist phases:** 6.2

### M2.6 · Bootstrap, error boundary và cổng build ba mặt

- **Status:** todo
- **Goal:** Một hàm `bootstrap()` duy nhất sở hữu khởi động, và không lỗi khởi
  động nào biến thành màn hình trắng.
- **Scope:** `bootstrap.dart` với thứ tự khởi tạo logging → config → storage →
  error boundary → `runApp` trong `ProviderScope`; `FlutterError.onError`,
  `PlatformDispatcher.instance.onError`, `ErrorWidget.builder` cho release.
- **Out of scope:** logging abstraction đầy đủ (M7), crash reporting (M8),
  khởi tạo database (M4.2 sẽ cắm vào đây).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/bootstrap.dart`, `lib/app/app.dart`
- **Acceptance criteria:**
  - [ ] Ném exception trong `runApp` → hiển thị màn hình lỗi có nội dung, **không**
        phải màn trắng và **không** phải red screen mặc định ở release.
  - [ ] Uncaught async error được bắt và log, app không crash.
  - [ ] `flutter build apk --debug --flavor development -t lib/main_development.dart`
        exit 0.
  - [ ] `flutter build web` exit 0 — cổng giữ kênh E2E còn sống (AD-04).
  - [ ] `flutter analyze` → 0 error, 0 warning.
  - [ ] `main.dart` và ba entrypoint không chứa logic khởi tạo nào.
- **Dependencies:** M2.5, M2.4, M2.3
- **Tests required:** widget test cho `ErrorWidget.builder`; test `bootstrap()`
  gọi được với fake config và không throw
- **Checklist phases:** 6.1

---

## M3 · Architecture and design foundation

Mục tiêu: dựng ranh giới layer và **đúng lượng** design foundation mà vertical
slice UC-05 cần. Không xây trọn design system trước khi có feature thật.

### M3.1 · Cấu trúc feature-first và ranh giới layer

- **Status:** todo
- **Goal:** Tạo bộ khung thư mục và làm `check_architecture.sh` chạy có ý nghĩa
  trên code thật.
- **Scope:** `lib/app/`, `lib/core/`, `lib/shared/`, `lib/features/` theo Phase
  4.1; một feature `review` rỗng đúng cấu trúc để script có gì để kiểm.
- **Out of scope:** logic nghiệp vụ; thư mục `data/remote/` (AD-01 — chưa có
  network, không tạo thư mục rỗng).
- **Editable documents:** `docs/wbs.md`
- **Output:** cây thư mục `lib/`, `docs/architecture.md` **không** đổi
- **Acceptance criteria:**
  - [ ] `.claude/skills/flutter-architecture/scripts/check_architecture.sh`
        exit 0.
  - [ ] Không tồn tại `lib/features/*/data/remote/`.
  - [ ] Thêm một file vi phạm cố ý (domain import Flutter) → script exit 1; xoá
        đi → exit 0. Ghi kết quả kiểm chứng này vào WBS.
  - [ ] Mọi file trong `lib/` đặt tên theo suffix quy ước ở `CLAUDE.md`.
  - [ ] **Siết guard**: đổi cả hai profile của ruleset `memox-v7` và
        `code-verification-guard.yaml` về `fail_on: [error, warning]` +
        `warning_as_error: true`, và xác nhận 26 cảnh báo
        `rule_without_targets` đã hết sau khi cây feature-first tồn tại (M2.2b).
- **Dependencies:** M2.6
- **Tests required:** none — kiểm chứng bằng fault injection ở acceptance
  criteria
- **Checklist phases:** 4.1, 4.2, 4.3, 5.3

### M3.2 · Core error và failure model

- **Status:** todo
- **Goal:** Có một hệ `Failure` sealed để mọi lớp trên data nói cùng một ngôn
  ngữ lỗi.
- **Scope:** `core/error/failure.dart` (sealed class: Network, Unauthorized,
  Forbidden, Validation, NotFound, Conflict, Database, Cancelled, Unknown),
  `core/error/drift_error_mapper.dart`.
- **Out of scope:** `dio_error_mapper.dart` — chưa có network (AD-05).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/error/`
- **Acceptance criteria:**
  - [ ] `Failure` là sealed class; `switch` trên nó không cần `default`.
  - [ ] `ValidationFailure` mang `Map<String, String> fieldErrors`.
  - [ ] `Failure.message` không chứa SQL, stack trace hay đường dẫn file — có
        test khẳng định.
  - [ ] Drift exception → `DatabaseFailure`, giữ nguyên gốc ở `cause`.
  - [ ] `core/error/` không import Flutter.
- **Dependencies:** M3.1
- **Tests required:** unit test bảng cho mapper Drift→Failure; test khẳng định
  không message nào lộ thông tin kỹ thuật
- **Checklist phases:** 6.3

### M3.3 · Riverpod foundation

- **Status:** todo
- **Goal:** Có khuôn provider chuẩn để mọi task sau viết giống nhau.
- **Scope:** `ProviderScope` trong bootstrap, quy ước `@riverpod` codegen, một
  provider hạ tầng thật (`envConfigProvider` override trong bootstrap),
  `ProviderContainer` helper cho test.
- **Out of scope:** provider của feature — thuộc M5.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/providers/`, `test/helpers/container.dart`
- **Acceptance criteria:**
  - [ ] `dart run build_runner build` sinh provider và `flutter analyze` exit 0.
  - [ ] Provider dùng `Ref` (Riverpod 3), **không** dùng `*Ref` sinh riêng.
  - [ ] `makeContainer()` trong `test/helpers/` tự `addTearDown(dispose)`.
  - [ ] Test khẳng định `envConfigProvider` throw khi chưa override.
- **Dependencies:** M3.1, M2.6
- **Tests required:** unit test cho provider hạ tầng và cho helper container
- **Checklist phases:** 9.1

### M3.4 · Design tokens

- **Status:** todo
- **Goal:** Mọi giá trị hình thức có tên, để feature không hardcode.
- **Scope:** `core/theme/app_spacing.dart`, `app_radius.dart`,
  `app_icon_size.dart`, `app_durations.dart`, `app_breakpoints.dart`,
  `app_colors.dart` (seed + semantic), `app_typography.dart`.
- **Out of scope:** component (M3.6), animation phức tạp.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/`
- **Acceptance criteria:**
  - [ ] Token dùng `abstract final class`, không instantiate được.
  - [ ] Spacing đúng thang 4 / 8 / 12 / 16 / 24 / 32, không có giá trị ngoài
        thang.
  - [ ] Tên token là semantic (`danger`), không phải vật lý (`red`).
  - [ ] `grep -rE 'Colors\.[a-z]|Color\(0x' lib/features lib/shared` không có
        kết quả.
  - [ ] `grep -rn 'TextStyle(' lib/features` không có kết quả.
- **Dependencies:** M3.1
- **Tests required:** unit test khẳng định thang spacing và bộ token bắt buộc tồn
  tại
- **Checklist phases:** 7.1

### M3.5 · Light theme và dark theme

- **Status:** todo
- **Goal:** Hai theme Material 3 hoàn chỉnh cho phạm vi UC-05.
- **Scope:** `buildLightTheme()`, `buildDarkTheme()`, `ColorScheme.fromSeed`,
  `AppSemanticColors` dạng `ThemeExtension`, component theme cho những widget
  UC-05 dùng: AppBar, Card, FilledButton, OutlinedButton, Snackbar.
- **Out of scope:** theme cho Dialog, BottomSheet, Chip, Input — chưa dùng ở
  UC-05; thêm khi feature cần.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/app_theme.dart`,
  `lib/core/theme/app_semantic_colors.dart`
- **Acceptance criteria:**
  - [ ] `useMaterial3: true` ở cả hai theme.
  - [ ] `AppSemanticColors` có `lerp` và `copyWith` đúng, đăng ký ở `extensions`.
  - [ ] Contrast text chính ≥ 4.5:1 ở cả hai theme — có test tính toán, không
        phải mắt thường.
  - [ ] Trạng thái disabled, pressed và focused đều có style ở button.
  - [ ] `context.colors` / `context.texts` / `context.semanticColors` là extension
        duy nhất trên `BuildContext`.
- **Dependencies:** M3.4
- **Tests required:** unit test contrast ratio cho cặp màu chính ở hai theme;
  widget test dựng cùng widget ở light và dark không throw
- **Checklist phases:** 7.2

### M3.6 · Base component tối thiểu và app shell

- **Status:** todo
- **Goal:** Đúng bộ component mà UC-05 cần, không hơn.
- **Scope:** `AppScaffold`, `AppButton` (variant + loading + disabled),
  `AppLoadingState`, `AppEmptyState`, `AppErrorState` (nhận `String`, không nhận
  `Failure`), `AppCardSurface` cho mặt card.
- **Out of scope:** TextField, SearchField, ListItem, Dialog, BottomSheet — UC-05
  không dùng. Tạo khi có caller thật (`CLAUDE.md`: không tạo shared component ở
  lần dùng đầu).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/shared/widgets/`
- **Acceptance criteria:**
  - [ ] Mỗi component có `const` constructor.
  - [ ] `AppButton` có enum variant, **không** nhận `Color` hay `TextStyle`.
  - [ ] `AppButton` ở trạng thái loading thì bị disable và giữ nguyên chiều rộng.
  - [ ] Mọi control chỉ có icon đều có semantic label — widget test dùng
        `find.bySemanticsLabel` chứng minh.
  - [ ] Touch target ≥ 48×48 — có test đo.
  - [ ] Mỗi component render được ở 320×568 và ở `textScaler` 2.0 mà
        `tester.takeException()` trả về null.
  - [ ] Golden test light + dark cho từng component.
- **Dependencies:** M3.5, M2.4
- **Tests required:** widget test cho từng state; golden test light/dark; test
  overflow ở màn nhỏ và text scale 2.0
- **Checklist phases:** 7.3, 7.4, 13, 15.3, 15.4

---

## M4 · Router and Drift foundation

Mục tiêu: có router và một database chạy được, đúng schema đã frozen, kèm
migration test và enforcement cho các bất biến.

### M4.1 · GoRouter foundation

- **Status:** todo
- **Goal:** Điều hướng tập trung, có sẵn chỗ cắm auth guard mà chưa xây auth.
- **Scope:** `app/router/route_paths.dart`, `route_names.dart`,
  `app_router.dart`, `errorBuilder` 404, một hàm `redirect` rỗng có comment nói
  rõ đây là điểm cắm guard (AD-03).
- **Out of scope:** auth guard thật, deep link config, `StatefulShellRoute` —
  MVP chưa có bottom navigation.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/router/`
- **Acceptance criteria:**
  - [ ] `MaterialApp.router` được dùng; không còn `MaterialApp` thường.
  - [ ] `grep -rnE "context\.(go|push)\('/" lib/` không có kết quả — mọi điều
        hướng đi qua tên route.
  - [ ] Route không tồn tại → màn 404 có nút quay về, không phải red screen.
  - [ ] `redirect` trả `null` và có comment chỉ rõ điểm cắm guard.
  - [ ] Widget test điều hướng tới một route bằng tên và assert màn đích.
- **Dependencies:** M3.6
- **Tests required:** widget test cho điều hướng theo tên và cho màn 404
- **Checklist phases:** 8.1, 8.2

### M4.2 · Drift connection và schema `.drift`

- **Status:** todo
- **Goal:** Database mở được, schema khớp `data-model.md`, SQL nằm trong file
  `.drift`.
- **Scope:** `core/database/connection.dart` (một chỗ duy nhất mở kết nối —
  AD-08), `app_database.dart`, `tables/*.drift` cho `decks`, `cards`,
  `card_review_states`, `review_history`, `study_sessions`; index; `PRAGMA
  foreign_keys = ON` trong `beforeOpen`.
- **Out of scope:** named query nghiệp vụ (M4.3), DAO và repository (M4.6),
  bảng `deck_templates` (AD-07: là asset ở MVP).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/database/`
- **Acceptance criteria:**
  - [ ] `dart run build_runner build` sinh code Drift, exit 0.
  - [ ] Mọi bảng và cột khớp `data-model.md` — kiểm bằng test so tên cột thực tế
        với danh sách mong đợi.
  - [ ] Không có Dart table class nào; toàn bộ khai báo nằm trong `.drift`
        (AD-02).
  - [ ] Xoá root deck → deck con, card, review state, history và session của nó
        đều biến mất (test khẳng định cascade thật sự chạy).
  - [ ] `grep -rn 'COALESCE(' lib/core/database/` không trả về dạng
        `COALESCE(...parent_deck_id...)` (BR-57).
  - [ ] `lib/core/database/connection.dart` là **file duy nhất** gọi
        `NativeDatabase`/`driftDatabase`.
- **Dependencies:** M3.2, M2.2
- **Tests required:** test schema (tên bảng/cột), test cascade delete, test
  `PRAGMA foreign_keys` đang bật
- **Checklist phases:** 11.1

### M4.3 · Named query và migration foundation

- **Status:** todo
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
  - [ ] `drift_schemas/drift_schema_v1.json` tồn tại và **được commit** (không bị
        `.gitignore` nuốt).
  - [ ] Test migration chạy `onCreate` từ rỗng lên v1 và assert đủ bảng.
  - [ ] `cardsDueForReview` và `dueCountPerRootDeck` dùng **cùng một** định nghĩa
        "đến hạn" — test khẳng định hai query trả cùng số card cho cùng dữ liệu
        (BR-22, UC-06).
  - [ ] Không số ngày nào của bảng interval xuất hiện trong `.drift` (BR-16 thuộc
        scheduler, không thuộc SQL).
  - [ ] `:now` là tham số, không dùng `CURRENT_TIMESTAMP`.
- **Dependencies:** M4.2
- **Tests required:** migration test từ rỗng lên v1; test đồng nhất giữa hai
  query đếm/lấy card đến hạn
- **Checklist phases:** 11.1, 15.1

### M4.4 · Enforcement cho bất biến dữ liệu

- **Status:** todo
- **Goal:** Biến 14 query bất biến trong `data-model.md` thành test chạy trên
  database thật.
- **Scope:** test tích hợp nạp fixture hợp lệ và fixture vi phạm cho từng bất
  biến; nối `check_docs.sh --db` vào một database tạm.
- **Out of scope:** sửa nội dung bất biến — `data-model.md` đang frozen.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/database/invariants_test.dart`
- **Acceptance criteria:**
  - [ ] Cả 14 bất biến có test; mỗi test kiểm **hai chiều**: sạch trên dữ liệu
        hợp lệ, và bắt được đúng vi phạm của nó.
  - [ ] Bất biến cây deck có case ở **cấp 3 trở lên** (BR-55, BR-57).
  - [ ] `.claude/skills/flutter-workflow/scripts/check_docs.sh --db <db tạm>`
        exit 0.
  - [ ] Mục technical debt "14 query bất biến chưa chạy trên dữ liệu người dùng
        thật" được cập nhật.
- **Dependencies:** M4.3
- **Tests required:** đây **là** task test; 14 test bất biến, mỗi cái hai chiều
- **Checklist phases:** 11.1, 15.1

### M4.5 · Domain entity và repository contract

- **Status:** todo
- **Goal:** Có hợp đồng domain viết theo nhu cầu presentation, không theo hình
  dạng Drift.
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
- **Dependencies:** M4.2
- **Tests required:** unit test equality của entity; test khẳng định enum phủ
  đúng tập giá trị của BR-79/BR-80
- **Checklist phases:** 14.2

### M4.6 · Data layer — DAO, mapper, repository implementation

- **Status:** todo
- **Goal:** Nối domain xuống Drift, và chặn mọi exception ở đúng ranh giới
  repository.
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
- **Dependencies:** M4.5, M4.3
- **Tests required:** repository test với database in-memory: happy path, failure
  path, cascade, stream phát lại; mapper test gồm case enum lạ
- **Checklist phases:** 14.3, 15.1

### M4.7 · Fixture cho development và test

- **Status:** todo
- **Goal:** Có dữ liệu thật để chạy vertical slice, đánh dấu rõ là fixture.
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
- **Dependencies:** M4.6, M4.4
- **Tests required:** test nạp fixture rồi chạy lại bộ bất biến; test idempotency
  khi nạp hai lần
- **Checklist phases:** 11.1, 14.3

---

## M5 · First vertical slice — UC-05 luồng ôn tập

Mục tiêu: chứng minh kiến trúc chạy xuyên suốt Drift → data source → repository
→ use case → controller/state → router → màn hình → ghi kết quả → UI cập nhật.

**Ngoài phạm vi M5** (nêu một lần, áp cho mọi task bên dưới): CRUD deck/card đầy
đủ, import/export, login, backend, sync, media, statistics, settings, và UI thư
viện starter deck.

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
- **Dependencies:** M4.5
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
- **Dependencies:** M5.1, M4.6
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
  UC-05 trên fixture của M4.7.
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
- **Dependencies:** M5.4, M5.5, M4.7
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
| `analysis_options.yaml` chưa được áp dụng | T0.1 | Bộ lint đã viết nhưng chưa được enforce; nhiều khả năng có tên rule sai hoặc đã deprecated | Copy vào project ở Phase 2.3 và xác nhận từng rule được analyzer công nhận |
| 14 query bất biến chưa chạy trên **dữ liệu người dùng thật** | T1.3 | Bất biến mới được verify trên fixture, chưa enforce trên DB sản xuất | Chạy `check_docs.sh --db <path>` trong test tích hợp khi Drift schema tồn tại (M4) |
| Pin Flutter ở `.fvmrc` **khai báo** chứ không **cưỡng chế** | M2.2 | Chạy `flutter` trực tiếp trên máy có version khác vẫn build được và không cảnh báo. Đây đúng là lỗi đã xảy ra: M2.1 chạy 3.44.8, phiên sau khởi động trên 3.44.6, không có gì phát hiện ra | Thêm một check so `flutter --version` với `.fvmrc` vào `dod_check.sh`, và dùng `flutter-version-file: .fvmrc` ở job CI của M7 |
| ~~7 file skill vẫn bảo chạy `dart run custom_lint`~~ | M2.2 | Skill vẫn hướng dẫn cài và chạy một package không cài được; phiên sau sẽ tin skill và loay hoay | **Đã trả ở M2.2b.** Cả 7 file đã trỏ sang guard. `docs/checklist.md` **cố ý giữ nguyên**: nó `frozen for MVP`, và mục "Ngoài phạm vi: mọi quyết định riêng của memox" nói rõ nó mô tả quy trình 22 phase chung — `custom_lint` ở đó là khuyến nghị Flutter phổ thông, còn quyết định riêng của memox sống ở file này (§5 canonical location) |
| `dependencies.md` vẫn liệt kê `sqlite3_flutter_libs` | M2.2 | Package đó nay là tombstone (`0.6.0+eol`, không có native code). Skill nói sai còn tệ hơn không có skill — phiên sau sẽ cài lại nó | Sửa `.claude/skills/flutter-project-setup/references/dependencies.md`: thay bằng ghi chú rằng `sqlite3` 3.x cấp native lib qua native assets. Ngoài `Editable documents` của M2.2 nên chưa sửa ở đây |
| Nội dung starter là fixture, không phải nội dung production | T1.3 | Không phát hành được với nội dung này | Tìm nguồn nội dung có bản quyền rõ ràng trước M8 (BR-87) |
| Bản build web MUST dùng `--no-web-resources-cdn` | M2.1a | Mặc định Flutter tải CanvasKit từ `gstatic.com` lúc **runtime** dù đã bundle sẵn cục bộ. Trong môi trường chặn CDN, app im lặng không render — không có lỗi build nào cảnh báo | Đưa cờ này vào job `build-web` của CI ở M7, và vào mọi hướng dẫn chạy web |
| ~~`check_docs.sh` chỉ đếm task ID dạng `T*`, bỏ sót `M*`~~ | T1.4 | Báo "no duplicate WBS task IDs (8 tasks)" trong khi có 33 — **pass gây hiểu nhầm**, 25 task M2–M5 không được bảo vệ khỏi trùng ID | **Đã trả ở M2.1b.** Regex sửa thành `[TM][0-9]+(\.[0-9]+)?[a-z]?` (giờ báo 35 task), thêm check dependency resolve và check `M*` đủ field + acceptance criteria không rỗng. Cả ba verify bằng test tiêm lỗi, 4/4 case đạt |
