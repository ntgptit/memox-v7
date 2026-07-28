# WBS — work breakdown and progress ledger

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì đã xong, đang làm, bị chặn |
| **Scope** | Milestone, task, blocker, technical debt, mục đã descoped |
| **Source of truth for** | Trạng thái task · blocker · technical debt · quyết định descope |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | T1.3a |
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
| M2 · Project foundation (Phase 2–3, 6) | todo | Chặn bởi việc Flutter chưa có trong môi trường — xem Blocker |
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

- **Status:** todo — **việc tiếp theo, chưa thực hiện**
- **Goal:** Chia M2–M4 thành task có acceptance criteria và dependency; chốt phạm
  vi vertical slice đầu tiên.
- **Scope:** chỉ file này. Không tạo source code.
- **Out of scope:** Flutter source, sửa tài liệu frozen.
- **Editable documents:** `docs/wbs.md`
- **Output:** `docs/wbs.md`, mở rộng
- **Acceptance criteria:**
  - [ ] M2–M4 chia tới task, mỗi task có goal, scope, output, acceptance
        criteria, dependency và test yêu cầu.
  - [ ] M5 chốt phạm vi đúng luồng UC-05, xuyên từ Drift tới màn hình.
  - [ ] Milestone sau M5 để ở mức feature — chia tới task lúc này chắc chắn phải
        lập lại kế hoạch sau khi M2 dạy vài điều.
  - [ ] Không task ID nào trùng.
- **Dependencies:** T1.3a
- **Tests required:** `check_docs.sh` pass
- **Checklist phases:** 1.1, 1.2

---

## Blocker

| Blocker | Ảnh hưởng | Cách gỡ |
|---|---|---|
| `flutter` không có trong môi trường tạo tài liệu | M2 trở đi không chạy được `flutter create`, `pub get`, `build_runner`, `flutter analyze` | Cài Flutter SDK, và tạo SessionStart hook để phiên sau không phải cài lại |

Blocker này **không** chặn T1.4 — đó là task chỉ sửa tài liệu.

## Deferred and descoped

| Item | Decision | Reason | Revisit when |
|---|---|---|---|
| Flutter toolchain verification | deferred | `flutter` chưa có trong môi trường; `flutter doctor` và build sạch chưa chạy được | Phase 2.1 |
| Đưa deck con lên thành root deck | descoped khỏi MVP | Cần quyết định scheduler mới; là tính năng riêng chứ không phải phép di chuyển | Sau MVP (UC-09 A2) |
| Media và tag | descoped khỏi MVP | Kéo theo lưu trữ file và đồng bộ file | Sau MVP; quy tắc reset và lưu trữ đã đặt sẵn (BR-41, AD-08) |

## Known technical debt

| Item | Incurred in | Cost of leaving it | Planned repayment |
|---|---|---|---|
| `check_architecture.sh` chưa có test tự động | T0.1 | Regression trong checker âm thầm ngừng enforce boundary | Fixture trong `test/tools/` khi `test/` tồn tại (M6) |
| `analysis_options.yaml` chưa được áp dụng | T0.1 | Bộ lint đã viết nhưng chưa được enforce; nhiều khả năng có tên rule sai hoặc đã deprecated | Copy vào project ở Phase 2.3 và xác nhận từng rule được analyzer công nhận |
| 14 query bất biến chưa chạy trên **dữ liệu người dùng thật** | T1.3 | Bất biến mới được verify trên fixture, chưa enforce trên DB sản xuất | Chạy `check_docs.sh --db <path>` trong test tích hợp khi Drift schema tồn tại (M4) |
| Nội dung starter là fixture, không phải nội dung production | T1.3 | Không phát hành được với nội dung này | Tìm nguồn nội dung có bản quyền rõ ràng trước M8 (BR-87) |
