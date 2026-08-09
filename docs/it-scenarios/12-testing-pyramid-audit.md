# Audit tháp kiểm thử cho toàn bộ kịch bản IT

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Phân loại lại 100% kịch bản IT theo ba execution profile, để phần lớn tuyệt đối business correctness chạy được bằng `flutter test` trên PR |
| **Scope** | Toàn bộ 127 kịch bản trong `docs/it-scenarios`. Ngoài phạm vi: viết test mới, đổi nghiệp vụ |
| **Source of truth for** | Execution profile mới theo từng ID · migration mapping cũ→mới |
| **Depends on** | `scenario-catalog.md`, `00-agent-execution-guide.md`, `business-rules.md`, `use-cases.md`, `architecture.md` |
| **Updated by task** | Refactor IT theo Testing Pyramid |
| **Last updated** | 2026-08-09 |

Ma trận ở mục C đã được duyệt và đang thi hành: danh mục đã mang profile mới,
`13-platform-boundaries.md` đã có sáu kịch bản `IT-PLAT`, mỗi kịch bản bị tách
đã ghi "Tách thành" ngay dưới tiêu đề của nó, và CI đã tách làm hai —
`ci.yml` chạy **toàn bộ** host suite trên mọi PR, `ci-device.yml` chạy
`DEVICE-E2E` trước phát hành. Việc còn lại là dời và viết test (§18 bước 4–7).

## A. Hiện trạng

| Chỉ số | Giá trị |
|---|---|
| Tổng kịch bản | **127** |
| Phụ thuộc UI/emulator (mọi hồ sơ `UI*` và `DEV-LINK`) | **127** — *toàn bộ* |
| `FIXTURE-BLOCKED` | **42** (33%) |
| Thuộc chức năng học (STUDY+LEARN+REVIEW+MODE+CONT) | **64** (50%) |
| Yêu cầu restart/thiết bị (`UI-RESTART`, `UI-DEVICE`, `DEV-LINK`) | **24** |
| Đã hiện thực trong `integration_test/` | **60** kịch bản / 66 test |

Hồ sơ đang dùng: `UI` 60 · `UI-FIXTURE` 26 · `UI-RESTART` 20 · `UI-CLOCK` 6 ·
`UI-MULTI` 6 · `UI-FAULT` 4 · `UI-DEVICE` 3 · `UI-LARGE` 1 · `DEV-LINK` 1.

**Ba phát hiện quyết định hình dạng của bản refactor này:**

1. **Không có kịch bản nào được phép chạy trên host.** Cả chín hồ sơ đều mô tả
   thao tác trên giao diện; hệ quả là 100% business rule của bảng trên chỉ được
   kiểm khi có emulator. CI hiện tại (`ci.yml`, `ci-full.yml`) **không hề chạy**
   `integration_test/` — nên trên thực tế 127 kịch bản này không chặn PR nào cả.
   Đó là lý do suite từng đỏ 0/66 suốt bảy mươi PR mà không ai biết.
   **Và tệ hơn thế:** bước test của `ci.yml` chỉ chạy `test/app` và
   `test/features/deck`. Bộ lập lịch, mọi repository, toàn bộ truy vấn database
   và các migration **cũng không** được kiểm bởi pull request nào — chúng chờ
   `ci-full.yml`, vốn chạy thủ công. Cộng lại: trước bản refactor này, dự án
   không có một cổng tự động nào cho tính đúng của nghiệp vụ. Đó là thứ
   `ci.yml` sửa trong chính lần thay đổi này.
2. **Hạ tầng HOST-FLOW đã tồn tại và đã được dùng đúng cách.**
   `test/features/study/data/study_flow_test.dart` chạy use case → repository →
   DAO → SQLite in-memory với clock cố định và `Random` có seed; doc comment của
   nó đã lập luận đúng luận điểm của task này. `test/database/` cũng đã dùng DB
   thật. Việc cần làm là **mở rộng**, không phải dựng mới.
3. **`FIXTURE-BLOCKED` phần lớn là trở ngại giả.** 42 kịch bản bị chặn vì "bộ dữ
   liệu dựng sẵn chưa có", nhưng nội dung của chúng chỉ là hàng trong DB — deck,
   card, `learned_at`, `current_box`, `due_at`, session, queue. Ở HOST-FLOW,
   dựng đúng những hàng đó là việc mười dòng, và `00-agent-execution-guide.md`
   §2 cấm agent tự sửa DB **là luật cho E2E trên thiết bị**, không phải cho một
   test host tự tạo database của chính nó.

## B. Phân bố đề xuất

| Profile | Số kịch bản | Tỉ lệ |
|---|---|---|
| `HOST-FLOW` | **88** | 54% |
| `HOST-WIDGET` | **67** | 41% |
| `DEVICE-E2E` | **8** | 5% |
| | **163** | |

127 kịch bản cũ tách thành **163** kịch bản mới. `DEVICE-E2E` chiếm **5%**,
dưới ngưỡng 20–25% của §16.

**Sáu kịch bản `DEVICE-E2E` mới gom lại thứ mà hai mươi kịch bản `UI-RESTART`
đang lặp đi lặp lại.** Restart không phải là một luật nghiệp vụ; nó là **một**
ranh giới nền tảng. Chứng minh một lần rằng dữ liệu đã ghi sống sót qua một lần
chết tiến trình thật là đủ — hai mươi lần nữa chỉ chứng minh lại cùng ranh giới
đó với nội dung khác nhau, và nội dung thì HOST-FLOW đã chứng minh rẻ hơn.

| ID mới | Profile | Nội dung | Nguồn |
|---|---|---|---|
| IT-PLAT-001 | `DEVICE-E2E` | Cold start of the installed app reaches the deck list | derived from IT-NAV-001 |
| IT-PLAT-002 | `DEVICE-E2E` | State written before a real process death is still there after relaunch | derived from IT-NAV-006, IT-DECK-001, IT-CARD-002, IT-CARD-008, IT-CARD-010, IT-ORG-004, IT-ORG-008, IT-STUDY-008 |
| IT-PLAT-003 | `DEVICE-E2E` | A session interrupted by process death resumes at its cursor | derived from IT-CONT-001, IT-LEARN-003, IT-LEARN-004, IT-LEARN-012, IT-MODE-007, IT-MODE-009 |
| IT-PLAT-004 | `DEVICE-E2E` | A deep link entering from the OS lands on the right screen | derived from IT-NAV-005 |
| IT-PLAT-005 | `DEVICE-E2E` | The Android system back gesture inside a session exits like the X | derived from IT-NAV-010 |
| IT-PLAT-006 | `DEVICE-E2E` | Release smoke: install, open, create a deck and a card, study one card | new — the critical journey the release gate needs |

Hai kịch bản offline (`IT-NAV-007`, `IT-CONT-008`) giữ nguyên `DEVICE-E2E`
nhưng thu hẹp: AD-05 nói `dio` **cố tình không phải** dependency, nên app không
phát request nào. Chúng không còn là "kiểm app chạy offline" mà là "kiểm rằng
chưa ai lén thêm một lời gọi mạng vào" — một smoke trước phát hành.

## C. Ma trận migration

Bao phủ **100%** danh mục. `same` nghĩa là giữ nguyên ID vì ngữ nghĩa không đổi,
chỉ đổi execution profile (§11).

| ID cũ | ID mới | Hồ sơ cũ | Profile mới | Hành động | Lý do |
|---|---|---|---|---|---|
| IT-CARD-001 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Empty state offers the first card. |
| IT-CARD-002 | IT-CARD-002 / IT-CARD-002F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Form vs persisted row. |
| IT-CARD-003 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Front/back validation presentation. |
| IT-CARD-004 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Length limits. |
| IT-CARD-005 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Optional fields on the form. |
| IT-CARD-006 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Per-field 240 limit. |
| IT-CARD-007 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Save-and-add-another keeps the sheet open. |
| IT-CARD-008 | IT-CARD-008 / IT-CARD-008F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Editing keeps list position (UI) and the edited row persists (SQL). |
| IT-CARD-009 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Editing content MUST NOT touch card_review_states — the single most important cross-table invariant here, and only the DB can show it. |
| IT-CARD-010 | IT-CARD-010 / IT-CARD-010F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Confirm dialog vs the delete actually landing. |
| IT-CARD-011 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Deleting the last card must not flip content_type (BR-67). |
| IT-CONT-001 | IT-CONT-001 / IT-PLAT-003 | ``HOST-FLOW`` | `HOST-FLOW` + `DEVICE-E2E` | split | Resuming at the stored cursor (BR-79/102/103) is a DB read; being killed by the OS is the platform boundary. |
| IT-CONT-002 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Starting a new session abandons the same-day one (BR-82/103) — a status transition. |
| IT-CONT-003 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | A session from a previous study day is closed as interrupted (BR-80/86/103) — needs an injected clock, not a device. |
| IT-CONT-004 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | The X is a deliberate exit — the write it causes is asserted at HOST-FLOW by IT-CONT-002. |
| IT-CONT-005 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | A finished session has a summary and an empty queue (BR-81). |
| IT-CONT-006 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | The queue is frozen against later content changes (BR-102/139). Two surfaces were never needed — two writes against one database are. |
| IT-CONT-007 | IT-CONT-007 / IT-CONT-007W | ``HOST-FLOW` + `HOST-WIDGET`` | `HOST-FLOW` + `HOST-WIDGET` | split | Deleting a deck mid-session ends the session (DB); recovering navigation is the screen. |
| IT-CONT-008 | same | ``DEVICE-E2E`` | `DEVICE-E2E` | keep | Whole session offline. Same note as IT-NAV-007: kept as a release smoke because AD-05 means there is nothing to fail. |
| IT-CONT-009 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Reset invalidates the open session with scheduler_reset (BR-83/152) — one transaction. |
| IT-CONT-010 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | A stale-generation session is refused atomically (BR-46/84) — the reset-un-resets-itself guard. |
| IT-CONT-011 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | A transient write failure does not advance and a retry writes once (BR-25) — inject the failure at the DAO, not at the UI. |
| IT-CONT-012 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | An unrecoverable failure closes the session as failed and keeps prior turns (BR-85/86). |
| IT-CONT-013 | IT-CONT-013 / IT-CONT-013W | ``HOST-FLOW` + `HOST-WIDGET`` | `HOST-FLOW` + `HOST-WIDGET` | split | The read failure and the retry are repository; the Retry affordance keeping the cursor is the screen. |
| IT-CONT-014 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Choosing review with a same-day session open abandons it (BR-82/103). |
| IT-DECK-001 | IT-DECK-001 / IT-DECK-001F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Creating through the form is UI; that the row persists with scheduler=eight_box is SQL. |
| IT-DECK-002 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Duplicate names allowed (BR-02) — form submits, list shows two. |
| IT-DECK-003 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Validation presentation. |
| IT-DECK-004 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Length limit and field preservation are presentation. |
| IT-DECK-005 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Cancel with and without changes — dialog behaviour. |
| IT-DECK-006 | IT-DECK-006 / IT-DECK-006F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Rename through the sheet is UI; the renamed row surviving a read is SQL. |
| IT-DECK-007 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Cancelling a destructive dialog. |
| IT-DECK-008 | IT-DECK-008 / IT-DECK-008F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | The confirm dialog is UI; cascading the whole subtree is a SQL/transaction assertion and belongs beside cascade_test.dart. |
| IT-DISC-001 | IT-DISC-001 / IT-DISC-001F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Tile composition is UI; the due/total pair is the two-query agreement already guarded in query_test.dart. |
| IT-DISC-002 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Zero due is an ordinary empty state. |
| IT-DISC-003 | IT-DISC-003 / IT-DISC-003F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | The filter chip is UI; which decks match is SQL. |
| IT-DISC-004 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Empty-filter recovery is presentation. |
| IT-DISC-005 | IT-DISC-005 / IT-DISC-005F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Sort control vs ORDER BY. |
| IT-DISC-006 | IT-DISC-006 / IT-DISC-006F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Search field vs subtree-scoped query (BR-56/57). |
| IT-DISC-007 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | No-match state names its scope and offers a clear. |
| IT-DISC-008 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | watch() stream refreshes the list — a Riverpod/stream assertion the host can make. |
| IT-LEARN-001 | IT-LEARN-001 / IT-LEARN-001W | ``HOST-FLOW` + `HOST-WIDGET`` | `HOST-FLOW` + `HOST-WIDGET` | split | The five-stage sequence is queue construction (BR-97/108/109/110); the screens showing each stage is one widget walk. |
| IT-LEARN-002 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | SM-2 sequence is Browse then Self assess — queue construction. |
| IT-LEARN-003 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Browse shows both faces and grades nothing (BR-111/112) — a screen fact plus an absent write. |
| IT-LEARN-004 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Same card set, independent orders (BR-113/117/127) — seeded permutations over the queue. |
| IT-LEARN-005 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Fill skips a card without an example and learning still completes (BR-114/140/144). |
| IT-LEARN-006 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Guess skipped below five distinct meanings (BR-99/121/124/140). |
| IT-LEARN-007 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Match skipped at one pair (BR-99/153). |
| IT-LEARN-008 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | The fail set only clears after a clean round (BR-115/116/119) — round algorithm. |
| IT-LEARN-009 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Self-assess spacing and the relearning-ceiling flag (BR-26/28/92/104). |
| IT-LEARN-010 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Only a completed sequence writes the first schedule and locks the algorithm (BR-13/27/105/144/145/149). Fixed clock, asserted due_at. |
| IT-LEARN-011 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | The card limit is a per-session ceiling, not a daily quota (BR-24/139). |
| IT-LEARN-012 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Abandoning learning writes no half schedule and restarts at Browse (BR-82/86/144). |
| IT-MODE-001 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | The session frame names mode, set, kind and progress — chrome, already widget-tested. |
| IT-MODE-002 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Browse shows both faces and only moves on. |
| IT-MODE-003 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Board keeps its tiles and tells three states apart. |
| IT-MODE-004 | IT-MODE-004 / IT-MODE-004F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Tapping term-then-meaning is UI; that the turn is attributed to the term and the card stays in the fail set (BR-107/116/118/120) is what the DB records. |
| IT-MODE-005 | IT-MODE-005 / IT-MODE-005F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | One tap counted (BR-126) is UI; exactly five distinct meanings (BR-121/125) is question construction. |
| IT-MODE-006 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Guess skipped for the whole session set (BR-99/121/124). |
| IT-MODE-007 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Stable-on-resume, independent permutations (BR-117/127) — seeded Random over persisted order. |
| IT-MODE-008 | IT-MODE-008 / IT-MODE-008F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | The countdown UI is a widget with an injected clock; which outcome is recorded at the mark (BR-128/129) is domain. |
| IT-MODE-009 | IT-MODE-009 / IT-MODE-009F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Auto-reveal is UI; the locked-wrong outcome and remaining_ms persistence (BR-130/131/133) are DB facts. |
| IT-MODE-010 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Fill folding rules (BR-134/137/138) — a pure comparison plus what is written. |
| IT-MODE-011 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Hint recorded without changing the action, one submission only (BR-135/136/137/138). |
| IT-MODE-012 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Self assess shows actions only after a flip. |
| IT-MODE-013 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Screen reader and large text — meetsGuideline and textScaler are host matchers. No device needed. |
| IT-MODE-014 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Atomic block when a question cannot be built (BR-121/124) — a repository refusal, not a fault-injection UI. |
| IT-MODE-015 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Distractors come from the same tree and never leak an unseen new card (BR-121/122/123). |
| IT-NAV-001 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Router lands on the deck list. Real cold start is proved once by IT-PLAT-001. |
| IT-NAV-002 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Shell keeps branch state; pure GoRouter + widget. |
| IT-NAV-003 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Back pops one level; router only. |
| IT-NAV-004 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Breadcrumb navigates to an ancestor; router + widget. |
| IT-NAV-005 | IT-NAV-005 / IT-PLAT-004 | ``HOST-WIDGET`` | `HOST-WIDGET` + `DEVICE-E2E` | split | The 404 route and its recovery are router behaviour; an OS-originated deep link is the only part needing a device. |
| IT-NAV-006 | IT-NAV-006 / IT-PLAT-002 | ``HOST-FLOW`` | `HOST-FLOW` + `DEVICE-E2E` | split | Deck/Card CRUD persistence is SQLite; surviving a real process death is the platform boundary. |
| IT-NAV-007 | same | ``DEVICE-E2E`` | `DEVICE-E2E` | keep | Airplane mode is an OS control. Kept minimal: AD-05 means the app makes no request, so this is a release smoke that nothing was added. |
| IT-NAV-008 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Back from the study entry creates no session — the assertion is a route pop plus an absent write, both host-provable. |
| IT-NAV-009 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Fixture is DB state (a reviewing EB deck); no device needed once the builder exists. |
| IT-NAV-010 | IT-NAV-010 / IT-PLAT-005 | ``HOST-WIDGET`` | `HOST-WIDGET` + `DEVICE-E2E` | split | The exit contract (BR-82 writes abandoned/user_exit) is host-provable via PopScope; the physical Android back gesture is not. |
| IT-ORG-001 | IT-ORG-001 / IT-ORG-001F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Search field vs the front/back LIKE query. |
| IT-ORG-002 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Empty search recovery. |
| IT-ORG-003 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Sort by created/due is ORDER BY over learned_at and due_at (BR-151). |
| IT-ORG-004 | IT-ORG-004 / IT-ORG-004F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Toggling the flag is UI; it persisting is SQL (BR-92). |
| IT-ORG-005 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | All/Due/New/Flagged counts are four predicates that must agree with the lists they head. |
| IT-ORG-006 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | An empty filter is not an empty deck — presentation. |
| IT-ORG-007 | IT-ORG-007 / IT-ORG-007F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Tag entry is UI; case-insensitive reuse is a query/uniqueness rule (BR-93). |
| IT-ORG-008 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Removing a tag must not touch the card row. |
| IT-ORG-009 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Tag name validation and the 10-tag cap are presentation of BR-93/94. |
| IT-ORG-010 | IT-ORG-010 / IT-ORG-010F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Panel rendering vs the distribution query (BR-89/90/91). |
| IT-ORG-011 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | Breadcrumb refresh after a rename — stream + widget. |
| IT-ORG-012 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | keep | Windowed loading of a large list is a scroll/viewport behaviour; the fixture is DB state, so no device. |
| IT-REVIEW-001 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | The review queue takes learned and due cards only (BR-142) — the due predicate at a fixed clock. |
| IT-REVIEW-002 | IT-REVIEW-002 / IT-REVIEW-002W | ``HOST-FLOW` + `HOST-WIDGET`` | `HOST-FLOW` + `HOST-WIDGET` | split | One chosen mode runs the whole session (BR-109/146) is queue construction; the screen showing that mode is a widget walk. |
| IT-REVIEW-003 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | SM-2 takes the action straight from the user (BR-30/106/146) — four buttons and the action they emit. |
| IT-REVIEW-004 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Earlier due served first and the limit counted per distinct card (BR-23/24/102/139) — ORDER BY plus a cap. |
| IT-REVIEW-005 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | First turn scheduled, repeats relearning, no second schedule (BR-20/21/75-78/141/143). The densest scheduler assertion in the catalog. |
| IT-REVIEW-006 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Eight Box box/interval transitions (BR-15/16/105) with an asserted due_at. |
| IT-REVIEW-007 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | SM-2 update order for the four actions (BR-17/18/19/105). |
| IT-REVIEW-008 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | No re-review before the schedule just written (BR-105/145). |
| IT-REVIEW-009 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Summary separates handled cards from due-but-over-limit (BR-24) — a counting rule. |
| IT-REVIEW-010 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Per-mode counts and queues must not share one fake number. |
| IT-STUDY-001 | IT-STUDY-001 / IT-STUDY-001F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Two disjoint sets (BR-142) is a query rule; the entry screen only prints the two numbers. |
| IT-STUDY-002 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Looking at counts creates no session row — an absence in the DB, not a screen state. |
| IT-STUDY-003 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | No due card and no study-ahead (BR-29/145) is a due predicate at a fixed clock. |
| IT-STUDY-004 | IT-STUDY-004 / IT-STUDY-004F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Which modes are offered is BR-99/146/154 in the domain; the chooser reflects it. |
| IT-STUDY-005 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | SM-2 has one review mode (BR-30/146) — a scheduler fact. |
| IT-STUDY-006 | IT-STUDY-006 / IT-STUDY-006F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Disabled-with-a-reason is presentation; the eligibility itself is BR-99/100/121/153. |
| IT-STUDY-007 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Per-mode counts must come from each mode capacity (BR-114/154), not one shared number. |
| IT-STUDY-008 | IT-STUDY-008 / IT-PLAT-002 | ``HOST-FLOW`` | `HOST-FLOW` + `DEVICE-E2E` | split | App-wide options persisting is a store read; surviving a real restart is the platform boundary and is proved once. |
| IT-STUDY-009 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Root override beats default (BR-06/139/147) — pure resolution over DB rows. The UI-MULTI profile was never needed. |
| IT-STUDY-010 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | The card limit is frozen at open (BR-24/139) — a session-row assertion. |
| IT-STUDY-011 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Session scope is the deck subtree (BR-23/142) — a recursive query. |
| IT-STUDY-012 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Created/Random selection and stability on resume (BR-102/139/148) needs a seeded Random and the DB. |
| IT-STUDY-013 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Unreadable root config falls back to defaults (BR-24/147/148) — a repository failure path, not a fault-injection UI. |
| IT-TREE-001 | IT-TREE-001 / IT-TREE-001F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | BR-58/59 is a repository rule inside runInTransaction; the chooser only reflects it. |
| IT-TREE-002 | same | ``HOST-WIDGET`` | `HOST-WIDGET` | reclassify | An unset deck offers both actions — presentation of BR-60/61. |
| IT-TREE-003 | IT-TREE-003 / IT-TREE-003F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | First-child locking is a transaction rule (BR-62/63); the UI only stops offering the other kind. |
| IT-TREE-004 | IT-TREE-004 / IT-TREE-004F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Same rule, the other branch. |
| IT-TREE-005 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | A refused write must leave content_type unset — provable only against the DB. |
| IT-TREE-006 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Emptying a deck does not reset its type; pure persistence (BR-67). |
| IT-TREE-007 | IT-TREE-007 / IT-TREE-007F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Confirmed reset is a dialog; the reset itself is a transaction (BR-68). |
| IT-TREE-008 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Refusal to reset a non-empty deck is a repository guard. |
| IT-TREE-009 | IT-TREE-009 / IT-TREE-009F | ``HOST-WIDGET` + `HOST-FLOW`` | `HOST-WIDGET` + `HOST-FLOW` | split | Move UI vs the subtree rewrite (root_deck_id, depth) in one transaction. |
| IT-TREE-010 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Cycle refusal (BR-69/70) is checked inside the write. |
| IT-TREE-011 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | BR-64 refusal at the repository. |
| IT-TREE-012 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Cross-scheduler move refusal (BR-73/74) — never silently converted. |
| IT-TREE-013 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Depth-10 refusal (BR-55) is checked before anything is written. |
| IT-TREE-014 | same | ``HOST-FLOW`` | `HOST-FLOW` | reclassify | Reset after the last card — persistence. |

### Tổng kết hành động

| Hành động | Số kịch bản cũ |
|---|---|
| keep | 3 |
| reclassify | 89 |
| split | 35 |

Không kịch bản nào bị xoá. Không kịch bản nào mất truy vết: cột `Truy vết` của
danh mục được mang nguyên sang kịch bản dẫn xuất, và mỗi ID mới ghi
`Derived from` ở bảng B.

## D. Việc phải làm trước khi dời test

1. **Fixture builder trên test database.** Cần đủ: DB rỗng · root deck · cây
   deck · card · card đã học · card đến hạn · card hạn tương lai · trạng thái
   Eight Box · trạng thái SM-2 · session đang dở · session đã xong · study queue
   · `scheduler_generation`. Có sẵn một phần ở `test/database/support/` và
   `test/features/study/data/support/study_harness.dart`.
2. **App harness cho HOST-WIDGET**: `ProviderScope` thật + GoRouter thật +
   localization thật + database in-memory thật + clock inject.
3. **Đồng hồ và random**: mọi kịch bản `due_at`/study day/resume dùng
   `clockProvider` và `Random(seed)`. `lib/features/` đã không chứa
   `DateTime.now()` nào (AD-13), nên seam đã sẵn.
4. **CI**: `ci.yml` giữ nguyên `flutter test` nhưng thêm thư mục mới vào; thêm
   một job release-candidate chạy `DEVICE-E2E`. PR **không** boot emulator.

## E. Điều tài liệu này *không* làm

- Không đổi một luật nghiệp vụ nào. Mọi BR/UC ở cột truy vết giữ nguyên.
- Không làm yếu assertion nào. Kịch bản bị tách thì assertion đi theo tầng nào
  chứng minh được nó, không bị bỏ.
- Không xoá `integration_test/` trước khi HOST-FLOW/HOST-WIDGET tương đương đã
  tồn tại và xanh (§18).
