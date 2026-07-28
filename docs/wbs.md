# WBS — work breakdown and progress ledger

_Last updated: 2026-07-28_

Single source of truth for project progress. Update it in the same commit as the
work it describes. A task is `done` only when it meets the Definition of Done in
`.claude/skills/flutter-workflow/references/definition-of-done.md`.

Status values: `todo` · `in-progress` · `blocked` · `done` · `descoped`

## Progress summary

| Milestone | Status | Notes |
|---|---|---|
| M0 · Development harness | done | Skills, checklist and enforcement scripts in place |
| M1 · Product definition (Phase 0–1) | **in-progress** | T1.1 done; T1.2 blocked on 3 câu hỏi trong `product.md` |
| M2 · Project foundation (Phase 2–3, 6) | todo | Unblocked — platform/data/auth đã chốt. Không cài `dio` (AD-05) |
| M3 · Architecture & design system (Phase 4–5, 7, 12–13) | todo | |
| M4 · Router & Drift foundation (Phase 8, 11) | todo | **Phase 10 (networking) bị hoãn** — xem AD-01/AD-05 |
| M5 · First vertical slice: luồng ôn tập (Phase 14) | todo | Luồng 2 trong `product.md` |
| M6 · Test suite (Phase 15) | todo | Chạy song song M5, không phải sau |
| M7 · CI/CD (Phase 19) | todo | Bắt đầu được ngay sau M2. Job Android + Web, chưa có iOS (AD-04) |
| M8 · Release Android (Phase 16–18, 20–22) | todo | |
| M9 · Backend Spring Boot + auth + sync (Phase 10) | todo | Sau khi M8 ổn định. Kích hoạt phần networking của harness |

---

## M0 · Development harness

### T0.1 · Skill harness for the 22-phase checklist

- **Status:** done
- **Goal:** Encode `docs/checklist.md` as invocable skills so each phase has one
  place that holds its rules, and so phase order is enforced rather than
  remembered.
- **Scope:** 11 skills under `.claude/skills/`, the canonical checklist,
  root `CLAUDE.md`, document templates. Out of scope: any Flutter source code.
- **Output:**
  - `docs/checklist.md`, `docs/README.md`, `docs/wbs.md`
  - `CLAUDE.md` — non-negotiables that apply in every phase
  - `.claude/skills/flutter-workflow` — router, phase index, Definition of Done,
    `scripts/dod_check.sh`
  - `.claude/skills/flutter-product-spec` — Phase 0–1 + four document templates
  - `.claude/skills/flutter-project-setup` — Phase 2, 3, 6 + dependency and
    flavor references
  - `.claude/skills/flutter-architecture` — Phase 4–5, `analysis_options.yaml`,
    `scripts/check_architecture.sh`
  - `.claude/skills/flutter-design-system` — Phase 7, 12, 13 + token, component
    and a11y/l10n references
  - `.claude/skills/flutter-navigation` — Phase 8
  - `.claude/skills/flutter-state-riverpod` — Phase 9
  - `.claude/skills/flutter-data-layer` — Phase 10–11 + networking and
    persistence references
  - `.claude/skills/flutter-feature-slice` — Phase 14 + per-feature checklist
  - `.claude/skills/flutter-testing` — Phase 15
  - `.claude/skills/flutter-ship` — Phase 16–22 + CI reference
- **Acceptance criteria:**
  - [x] Every checklist phase maps to exactly one owning skill
        (`flutter-workflow/references/phase-index.md`).
  - [x] `check_architecture.sh` detects domain→framework imports,
        presentation→data imports, cross-feature imports, core/shared→feature
        imports, swallowed exceptions, `print` in `lib/`, naming-suffix
        violations and oversized files — verified against a fixture.
  - [x] `check_architecture.sh` reports zero violations on conforming code —
        verified against a fixture.
  - [x] Both scripts exit 0 with a clear message when the Flutter project does
        not exist yet.
- **Dependencies:** none
- **Tests required:** fixture-based verification of both scripts (done manually
  during authoring; see the note under Technical debt).
- **Checklist phases:** meta — supports all

---

## M1 · Product definition — next

Blocked on input only the product owner can give. The five answers that unblock
the most downstream work, in order of leverage:

1. **Offline-first, online-first, or hybrid?** Decides whether Drift is the
   source of truth or a cache, and therefore the shape of every repository.
2. **Which platforms ship at launch?** Decides plugin choices and responsive scope.
3. **Is there authentication, and are there roles?** Reaches into the router,
   the network layer, storage and the whole test setup.
4. **What data is sensitive?** Decides secure storage, database encryption and
   log redaction.
5. **What is genuinely in the MVP?**

### T1.1 · Product requirements và quyết định kiến trúc

- **Status:** done
- **Goal:** Chốt các quyết định nền tảng và ghi lại kèm lý do.
- **Output:** `docs/product.md` (gồm cả MVP scope), `docs/architecture.md`
- **Acceptance criteria:**
  - [x] Problem, users, core value.
  - [x] Quyết định platform / data posture / auth / sensitive data kèm hệ quả.
  - [x] Feature phân loại must / should / nice / out, mỗi cái có điều kiện hoàn thành.
  - [x] Quyết định kiến trúc ghi thành AD-01…06 kèm lý do và đánh đổi.
  - [x] Harness được chỉnh lại cho khớp quyết định (xem T1.1b).
- **Dependencies:** product owner input — đã nhận
- **Tests required:** none — document only
- **Checklist phases:** 0.1, 0.2, và một phần 4.3

### T1.1b · Chỉnh harness theo quyết định đã chốt

- **Status:** done
- **Goal:** Loại bỏ hướng dẫn đã thành sai sau khi chốt local-first / `.drift` /
  no-auth / Android-only. Một skill nói sai còn tệ hơn không có skill, vì phiên
  sau sẽ tin nó.
- **Output:**
  - `flutter-data-layer/references/persistence.md` — schema viết lại theo file
    `.drift` (bảng, index, named query, `@DriftDatabase(include:)`); mục cache
    đánh dấu chưa áp dụng
  - `flutter-data-layer/SKILL.md` — source of truth đã chốt, networking là tài
    liệu cho phase sau
  - `flutter-project-setup/references/dependencies.md` — `dio` và
    `flutter_secure_storage` hoãn; `uuid` bắt buộc từ đầu
  - `flutter-ship/references/ci.md` — thêm job `build-web` (kênh E2E),
    comment out `build-ios`
  - `CLAUDE.md` — tóm tắt quyết định, bỏ Dio khỏi stack
- **Acceptance criteria:**
  - [x] Không còn ví dụ Dart table class trong tài liệu Drift.
  - [x] Mọi chỗ nhắc `dio` đều nói rõ là hoãn và vì sao.
  - [x] Frontmatter và tham chiếu chéo vẫn hợp lệ sau khi sửa.
- **Dependencies:** T1.1
- **Tests required:** chạy lại kiểm tra frontmatter + tham chiếu chéo
- **Checklist phases:** meta

### T1.2 · Use cases and business rules

- **Status:** blocked — cần 3 câu trả lời ở cuối `docs/product.md`
- **Blocker:** thuật toán SRS (Leitner / SM-2 / FSRS), nguồn nội dung (tự tạo hay
  có sẵn), thang đánh giá (2 mức hay 4 mức). Cả ba đều quyết định trực tiếp cột
  của bảng `cards` và business rules của luồng ôn tập — viết use case trước khi
  chốt là đúng loại rework mà Phase 14.1 tồn tại để ngăn.
- **Goal:** Specify each must-have feature to the point where it can be built
  without further questions.
- **Output:** `docs/use-cases.md`, `docs/business-rules.md`
- **Acceptance criteria:**
  - [ ] Every must-have feature has a use case with actor, trigger,
        preconditions, main / alternative / error flows, and postconditions.
  - [ ] Business rules numbered `BR-xx`.
  - [ ] Validation rules carry the exact user-facing message.
  - [ ] Every entity has an explicit state machine with illegal transitions
        listed.
- **Dependencies:** T1.1
- **Tests required:** none — document only
- **Checklist phases:** 0.3

### T1.3 · WBS for M2–M5

- **Status:** todo
- **Goal:** Break the first milestones into task-level detail.
- **Output:** this file, extended
- **Acceptance criteria:**
  - [ ] M2–M4 broken to tasks with acceptance criteria and dependencies.
  - [ ] M5 scoped to one vertical slice that exercises database → screen.
  - [ ] Later milestones left at feature granularity — planning them to task
        level now guarantees replanning.
- **Dependencies:** T1.2
- **Tests required:** none
- **Checklist phases:** 1.1, 1.2

---

## Deferred and descoped

| Item | Decision | Reason | Revisit when |
|---|---|---|---|
| Flutter toolchain verification | deferred | `flutter` is not installed in the authoring environment; `flutter doctor` and a clean build could not be run | Phase 2.1, in an environment with Flutter |

## Known technical debt

| Item | Incurred in | Cost of leaving it | Planned repayment |
|---|---|---|---|
| `check_architecture.sh` has no automated test of its own | T0.1 | A regression in the checker silently stops enforcing boundaries | Add `test/tools/` fixtures running the script over known-good and known-bad trees, once `test/` exists (M6) |
| `analysis_options.yaml` not yet applied | T0.1 | The lint set is written but unenforced until a project exists | Copy from `flutter-architecture/references/` during Phase 2.3 and confirm every listed rule is recognised by the analyzer version in use |
