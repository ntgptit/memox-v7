# WBS — work breakdown and progress ledger

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì đã xong, đang làm, bị chặn |
| **Scope** | Milestone, task, blocker, technical debt, mục đã descoped |
| **Source of truth for** | Trạng thái task · blocker · technical debt · quyết định descope |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M5.4a (lối vào, chọn mode, browse, self_assess) |
| **Last updated** | 2026-08-07 |

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
| M4 · Router, Database & Content Management (Phase 8, 11, 14) | done | M4.1, M4.1a, M4.2, M4.3, M4.4 **done** — GoRouter tập trung với `MaterialApp.router` và 404 ở `app/fallback/`; MX-VIS-001 ép mọi production screen có strict visual audit; schema v1 toàn bộ trong `.drift`; hai named query dùng chung một định nghĩa "đến hạn"; schema v1 đã dump và commit; cả 14 bất biến chạy trên database thật. M4.4a **done** — sắp xếp lại kế hoạch theo vertical slice. M4.8 **done** — 11 shared component mang prefix `Mx` (5 mới, 6 đổi tên), 26 golden mới, rename không đổi pixel; vòng review UI/UX đóng thêm 4 lỗi accessibility có đo đạc. M4.8a **done** — responsive hardening: `MxContentShell` overflow 135px/167px ở landscape đã đóng, bốn component còn lại đã tự cuộn sẵn; màn rộng chốt giữ kéo căng. M4.8b **done** — compact scale cho màn 320: hàng list 88→80px, padding ngang button 24→12 (bốn action `sm2` từ "Ag" thành "Again"), body/label giữ nguyên cỡ, phát hiện harness test báo màn hình 0×0 từ M3.6. **M4.5, M4.6, M4.7 `descoped` trước khi triển khai** — không dòng code nào từng được viết dưới ba ID đó. M4.8–M4.12 là kế hoạch mới: shared component → Deck/Card domain+data → Deck full-stack → Card full-stack → demo hardening. M4.9 **done** — Deck/Card domain + data vertical: 6 file domain (entity/enum/contract), DAO + 3 mapper + repository impl với transaction thật, `deck.drift` recursive query, constraint conflict → `ConflictFailure`, 78 test mới (49 integration trên SQLite thật + 1 web runtime trên Chrome), cả 14 bất biến pass trên dữ liệu do repository ghi; đồng thời **đóng lỗ hổng web của M4.2**: `driftDatabase` thiếu `web:` options và `drift_worker.js` prebuilt lệch ABI với `sqlite3.wasm` — connection đã sửa, worker compile từ đúng lockfile. M4.9a **done** — giới hạn cây 10 cấp enforce ở `createSubDeck`/`moveDeck` trước mutation, subtree traversal cycle-safe bằng recursive `UNION` (bỏ cap `depth < 64` production), bất biến thứ 15 (deck sâu hơn 10 cấp), và tách `CardRepository`/`CardRepositoryImpl`/`CardDao` khỏi Deck boundary. M4.9b **done** — hoàn tất ownership vật lý: toàn bộ Card domain/data chuyển sang `lib/features/card/`, không import Deck data layer, vẫn giữ một transaction chung cho BR-09/BR-62. **M4.10 `in-progress` — slice 1 xong:** Deck root list thay study placeholder ở route `/`, `rootDecksProvider` nối `watchRootDecks()` vào UI với loading/empty/loaded/error, DI đặt ở `lib/app/di/`, `StudyPlaceholderScreen` đã xoá, 6 strict visual audit PASS. Auto-retry của Riverpod 3 bị tắt cho provider này vì trong lúc retry state là `AsyncLoading` — một lần đọc lỗi sẽ quay spinner ~13 giây. **M4.10a `done` — quyết định product mới supersede M4.1:** MVP có Bottom Navigation Material 3, `StatefulShellRoute.indexedStack` với hai branch Decks/Review, `AppNavigationShell` + `MxNavigationBar`, `StudyPlaceholderScreen` khôi phục làm branch 1; chuyển tab giữ branch state (đo bằng số lần subscribe), deep link `/study` mở đúng tab. **M4.10 `done`** — Deck management full-stack hoàn tất trong một PR: root list có aggregate total/due/scheduler bằng **một** query (không N+1, predicate due khớp BR-22 và có parity test với query của Study), create root kèm chọn scheduler bắt buộc, create sub-deck, nested detail `/decks/:deckId` trong Decks branch, rename, delete kèm impact, reset `content_type`, move subtree với lý do từ chối hiển thị; 645 test pass, 16 strict visual audit state PASS. Card creation là handoff **disabled kèm giải thích** sang M4.11, không phải CTA giả. **Blueprint hardening (không phải task riêng, đi kèm M4.10):** `MemoxProviderObserver` luôn log provider failure vì Riverpod 3 retry 10 lần và giữ `AsyncLoading` suốt ~13 giây; `QueryLogInterceptor` log statement + thời gian ở debug build, **không** dùng `driftRuntimeOptions.debugPrint` vì flag đó in cả bound variable tức là nội dung flashcard (AD-08) — có test chứng minh. Đo được trên SQLite thật: đọc trọn 5.000 card mất **37,8 ms**, một trang 50 card mất **1,6 ms**, nên **M4.11 MUST viết `cardsByDeck` có page size ngay từ đầu, dùng keyset chứ không `OFFSET`**. **Tối ưu Deck trước khi clone (đo bằng `EXPLAIN QUERY PLAN` + Stopwatch trên SQLite thật):** ba index một cột đổi thành composite theo thứ tự lọc-rồi-sắp — `idx_cards_deck_created (deck_id, created_at, id)`, `idx_decks_parent_created`, `idx_decks_root_created`. Trước đó **cả năm** query nóng đều kết thúc bằng `USE TEMP B-TREE FOR ORDER BY`; sau đó biến mất ở 4/5 và subquery `total` của `rootDeckSummaries` thành **covering**. Một trang 50 thẻ trong deck 5.000 thẻ: 1193µs → 102µs. `cardsDueForStudy` giữ temp B-tree và sẽ giữ mãi — `ORDER BY` của nó bắt đầu bằng biểu thức `due_at IS NOT NULL`, không index nào thoả được. `schemaVersion` **giữ ở 1**: app chưa release (không tag, M8 `todo`), nên một version chưa từng ship không phải lịch sử đáng ghi; sau M8 thì cùng thay đổi này cần v2 + `onUpgrade`. `docs/data-model.md` (frozen) được sửa đúng phần index, có phép của chủ dự án. **Hai tối ưu bị loại kèm số đo:** index `(due_at, card_id)` chỉ giảm 7245µs → 6886µs (~5%) nên không đáng chi phí ghi; projection hẹp cho `allDecks` chỉ mua 0,6ms trong tổng 8ms mà 85% là mapping Dart. **Ghi nhận quan trọng:** production dùng `DriftIsolate` nên SQL chạy ở background isolate — chi phí trên UI thread là **số row** vượt biên isolate rồi map thành object, đó là lý do quyết định pagination keyset ở M4.11 quan trọng hơn index. **Deck chuyển sang layout Clean Architecture lồng (quyết định của chủ dự án, trước khi clone sang Card):** `domain/{entities,repositories,models,usecases,failures}`, `data/{repositories,mappers,datasources,models}`, `presentation/{screens,controllers,states,widgets,providers}` — tên **số nhiều** theo chuẩn ngành. 24 file nguồn + 2 audit companion di chuyển, 52 file rewrite import, codegen sinh lại; 763 test pass không đổi hành vi. **Thu được ngoài dự kiến:** sáu `check_suffix` trong `check_architecture.sh` viết theo tên **số ít** nên trước đây match **0 file** — chúng chạy, không thấy gì để kiểm, và pass. Đã trỏ lại sang tên số nhiều và thêm bốn check; giờ **23 file** được kiểm, fault injection xác nhận file sai suffix bị báo. Bốn thư mục rỗng có `.gitkeep` kèm lý do: `usecases` (repository contract chính là use-case surface), `failures` (failure dùng chung ở `core/error/`), `data/models` (không có DTO — AD-05), `providers` (mọi provider của Deck đều là controller). MX-VIS-001 giữ nguyên mọi segment dưới `presentation`, nên companion chuyển vào `test/visual_audit/screens/features/deck/screens/`. **Tách lý do thất bại thành type, và UC-09 về một chỗ (chủ dự án yêu cầu sau khi chỉ ra `domain/failures/` rỗng là triệu chứng chứ không phải trạng thái đúng):** `Failure.reason` là `Enum?` trên base type — `Enum` vì `core/` không được import feature, và trên base vì `Failure` là `sealed` nên feature **không thể** tự thêm subtype. Trước đó **15 chỗ ném `ConflictFailure` với 15 message khác nhau**, trong khi UI chỉ có `ConflictFailure() => deckConflictMessage` — 15 lý do tới người dùng thành **một câu**, vì lý do bị mã hoá vào chuỗi mà UI bị cấm render. Nay `domain/failures/` chứa `deck_conflict_failure.dart` (8 lý do) và `deck_move_failure.dart` (8 lý do move + hàm rule thuần), presentation match theo *type* của reason nên mỗi lý do có copy ARB riêng (18 key mới, en + vi). **UC-09 từng được viết hai lần** — một bản thuần sau move picker, một bản 8 `ConflictFailure` trong `moveDeck`, **không import lẫn nhau**; một rule (`sourceIsRoot`) chỉ tồn tại ở bản data nên picker không bao giờ thấy được. Nay cả hai gọi `deckMoveRejection(...)` nhận **fact** thay vì nhận cây, vì hai caller gom dữ liệu khác nhau (picker: một query rồi tính trong bộ nhớ; `moveDeck`: query từng mảnh **trong transaction** để write bị từ chối không để lại dấu vết). Guard **không** chuyển lên use case: làm vậy sẽ đẩy phần kiểm ra ngoài transaction và tạo race giữa lúc kiểm và lúc ghi. `check_suffix` thêm `/domain/failures/` → `_failure.dart` (11 check). 775 test pass (+12, trong đó có case 'mọi giá trị enum đều có rule sinh ra nó'). **Chuyển đổi sang Clean Architecture đầy đủ (chủ dự án yêu cầu — không chỉ move file):** thêm tầng **use case** 10 file trong `domain/usecases/`, một cái mỗi interaction, và `presentation/providers/` chứa DI cho chúng. **Validation chuyển từ controller vào use case** — trước đó `DeckEntity.nameProblem` chạy **hai lần**, một ở `presentation/` một ở `data/`, hai bên có thể lệch mà không gì bắt được; giờ chạy một lần ở tầng sở hữu BR-01. Controller chỉ còn double-submit guard, cờ submitting, `ref.mounted`, và map `Failure` sang state per-field — **không đọc repository nữa**. Refusal đi bằng `ValidationFailure.fieldErrors` chứ không phải `Failure.reason`, vì một form sai hai field cùng lúc mà `reason` chỉ giữ một giá trị; key lấy từ `DeckField`, là identifier không phải copy. **Cố ý KHÔNG chuyển vào use case:** BR-55 depth, BR-62 content lock, BR-68 emptiness, và rule move UC-09 — chúng cần cây *tại thời điểm ghi* và chạy trong `runInTransaction`; đặt lên use case là đẩy phần kiểm ra ngoài transaction, tức là race giữa lúc kiểm và lúc ghi. **`data/models/` vẫn rỗng có lý do:** row class Drift sinh ra *chính là* data model và nằm ở `core/database/` vì schema dùng chung; DTO riêng cho từng feature là hình dạng thứ hai cho cùng một row, và AD-05 chưa có wire format nào để mô hình hoá. Hai luật của chính dự án đã sửa có chủ ý: `_provider` thêm vào suffix cho phép của `presentation/`, và `presentation/providers/**` được loại khỏi scope `widget_ui_files` — một file chỉ làm dependency wiring thì đọc repository là đúng định nghĩa của nó. `provider_convention_test.dart` bắt được use-case provider dùng `keepAlive` ngay lúc đang thêm tầng; đã đổi sang `autoDispose`. 784 test pass (+9). **Đồng bộ toàn bộ tài liệu và harness với kiến trúc mới (chủ dự án yêu cầu):** **AD-12** ghi lại quyết định — layout lồng tên số nhiều, tầng use case một cái mỗi interaction, hướng phụ thuộc `presentation → use case → contract ← impl`, cái gì vào use case và cái gì phải ở lại trong transaction, và đánh đổi đã nhận (4 use case read mỏng, đổi lấy tính nhất quán). `CLAUDE.md` thêm sơ đồ thư mục, bảng suffix theo tầng, và nói rõ dòng *"use case chỉ khi có logic thật"* đã bị override — thay vì để hai tài liệu mâu thuẫn. `flutter-architecture/SKILL.md` và `flutter-feature-slice/SKILL.md` sửa hướng dẫn use case cùng cây thư mục; `feature_checklist.md` thêm mục **Layout (AD-12)** và bốn dòng Domain mới; deck README bỏ câu *"there is no use-case layer here"*. **Harness:** `check_suffix` nay nhận nhiều suffix (một folder có thể chấp nhận nhiều vai — `datasources/` nhận cả `_dao` và `_data_source`), thêm check cho `data/datasources`, `data/models`, `presentation/providers`; **14 check phủ 38 file** (trước sweep này: 6 check phủ 0 file). Message của rule 6 sửa lại — nó trỏ vào `core/logging`, một thư mục không tồn tại; nay chỉ sang `dart:developer` log() như hai diagnostic trong `core/` đang dùng. Mọi check mới đều fault-inject để xác nhận đỏ được. **Command/query tách bằng số đo, không bằng phán xét:** `test/app/command_query_separation_test.dart` giữ bốn count — use case đúng **một** method public; command controller chỉ `build`/`submit`/`reset`; input-state notifier một giá trị và tối đa một mutator; không controller/use case nào có `select*`, `search*`, `navigateTo*`, `show{Error,Snack}*`. Command controller được nhận diện bằng **state của nó là gì** (`build` trả `*SubmitState`), không bằng vị trí file — nên `DeckListNow` bị *chặn bởi check thứ ba* thay vì được miễn khỏi check thứ hai. **Check đầu bắt một vi phạm sống ngay lần chạy đầu:** `WatchDeckChildrenUseCase` giữ cả stream children *và* một lần đọc deck; đã tách thành `GetDeckByIdUseCase`, `deckDetail` compose hai cái — compose là việc của controller. **Cả bốn check đã fault-inject, và hai trong số đó pass rỗng lúc mới viết:** một cái có `replaceAll(r'', '/')` thay vì `r'\'` nên mọi path thành rác và `contains('/controllers/')` false với mọi file — thân loop không bao giờ chạy. Cả hai bug vô hình khi codebase còn sạch. 788 test pass (+4). **M4.10b `done` — Deck thành Golden Feature (AD-13):** rà lại Deck như thể nó là feature *mới* và đóng bốn khiếm khuyết mà một lần clone sẽ nhân bản, tất cả đều đang pass mọi test. **BR-01 có ba chủ sở hữu** (controller, repository, và screen tự dẫn lại từ chuỗi thô) → một value object `DeckName` constructor private, contract nhận nó, `Set<Enum> problems` thay `Map<String,String> fieldErrors` mà **cả hai nửa đều sai** (key là chuỗi không gì kiểm, value là copy UI bị cấm render — đó chính là lý do presentation phải tự dẫn lại). **Hai screen dựng read model từ hai query** trong khi comment khẳng định hai fact 'arrive together' → `watchDeckDetail` một `LEFT JOIN`, move picker lấy nguồn từ cùng lần emit; chứng minh bằng **đếm câu SQL** qua `QueryInterceptor` thật, vì không assertion nào về giá trị phân biệt được hai thiết kế (tiêm lại shape cũ: hai test đếm đỏ, chín test hành vi vẫn xanh). **Due count chỉ refresh khi resume**, comment ghi timer chu kỳ 'đã cân nhắc và loại' vì resume bắt cùng boundary — không đúng: ngồi ở danh sách khi card đến hạn thì badge nói 3 mà session phát 4 → `nextDueAt` trong **cùng** statement với các count, một `Timer` một-lần arm theo dữ liệu, `> :now` chặt. **Cập nhật ở deck-golden hardening:** khi emission được xử lý mà đồng hồ đã vượt `nextDueAt` (`delay <= 0`, kể cả bằng đúng `now`) thì trước đây guard chỉ `return` và count có thể đứng yên tới lần resume; nay nó refresh ngay một lần — mở lại query ở `now` mới để card vừa đến hạn được đếm — có guard chống lặp (một stale boundary tối đa một refresh, repository kẹt ở cùng boundary quá khứ không thể quay vòng), và có test cho past/future/`==now`/dispose/no-loop. **`features/` import `app/`** hai chiều → feature khai báo provider ở `di/` kiểu contract, `app/di/repository_bindings.dart` bind, `RouteNames` sang `core/navigation/`. **Clock có một chủ sở hữu:** hai repository impl từng default về `DateTime.now()` — một provider cả cây override được, và một static không gì với tới, mà cái khó với tới là cái thắng trong production; `clock` nay `required`, `lib/features/` không còn `DateTime.now()`. **Harness:** guard command/query chuyển sang **AST** (`package:analyzer`) vì cả hai khiếm khuyết của nó là tính chất của *text* — nó đếm method theo file (nên một file hai notifier đỏ oan) và cấm *chữ* `navigateTo` kể cả trong comment giải thích chính luật đó; AST cho phép phân biệt **ba** loại notifier thay vì hai. Ba guard khác cũng báo sai trên văn xuôi của chính chúng và **đều sửa ở rule**: `deck_card_boundary_test.dart` khớp `'part of'` trong comment nói file này *không* là part of gì; `memox.testing.no_real_clock_in_test` khớp doc comment nêu tên `DateTime.now()`; `common.no_commented_out_code` khớp câu văn gãy dòng `// for this assertion.`. Riverpod pin theo major thực tế trong lock (`>=3.0.0` resolve được nhưng vẫn bị chặn). **CI ra đời** — trước đó không có: `pull_request` + `push main`, format/analyze/generated/architecture/guard/docs/844 test/golden/build web, `flutter-version-file: .fvmrc`, `--no-web-resources-cdn` (hai nợ kỹ thuật đã trả). **Mọi guard giờ in số nó đã quét và coi 0 là lỗi** — việc đó phát hiện `check_architecture.sh` exit **0** khi thiếu `lib/`, tức một guard xanh cho working directory sai. **Ba khiếm khuyết ngoài kế hoạch do chính công việc này tìm ra:** `nextDueAt` về sai timezone (drift đọc `DateTime` thành local; đúng instant sai zone, chỉ lộ vì test mới so instant), lỗ exit-0 nói trên, và ba guard báo sai trên prose. **24 lần fault injection**, ghi trong báo cáo cuối. 844 test pass (+56 từ 788). **M4.10c `done` — Deck UI redesign + hợp nhất hai màn deck-list:** redesign theo reference nhưng giữ nguyên MemoX design system (mọi giá trị resolve về token đã có, `MxPillButton` là shared widget mới duy nhất, filter/sort là transform thuần chứ không phải query thứ hai); rồi khi hai màn **vẫn** khác nhau, hợp nhất `RootDeckListScreen` + `DeckDetailScreen` thành **một** `DeckListScreen(parentDeckId?)`. Nguyên nhân khác biệt không phải styling mà là dữ liệu — `deckDetail` chỉ trả tên deck con — nên thêm recursive CTE `childDeckLevel` để mỗi deck con mang đủ ba fact như deck gốc (tổng subtree, số đến hạn, scheduler resolve qua `root_deck_id`). `rootDeckSummaries` **giữ nguyên** vì root đã có covering index qua `root_deck_id`; cái giá là cùng một con số tính hai cách, nên `deck_level_parity_test.dart` khẳng định `subtree(D) == direct_cards(D) + Σ subtree(con)` ở root, branch, leaf, hai cây, và sau một lần move. 892 test pass, 97 visual audit state PASS. **Strict audit bắt một lỗi tương phản thật:** `primary` trên `surfaceMuted` chỉ 2,31:1 ở dark (sàn 3,0), nhìn mắt thấy ổn — đổi sang cặp `primaryContainer`/`onPrimaryContainer` = 8,96:1. **M4.10d `done` — breadcrumb cho màn hình đệ quy:** `MxBreadcrumb` là shared widget (không domain, không Riverpod, không tự đọc ARB), `DeckPathWidget` là adapter feature-local. Chain ancestor đến từ **cùng một statement** với level (AD-13) nên rename một ancestor đổi cả tiêu đề lẫn breadcrumb trong một frame. Hai shape typed đã thử và bị loại kèm lý do đo được — join làm nhân số dòng theo độ sâu, còn `UNION ALL` thì drift **không** expand `table.**` trong compound select và **không báo lỗi**; cách còn lại là một cột JSON, một lỗ untyped có chủ ý bịt kín ở mapper với decode total. Breadcrumb ẩn ở cấp 1–2 vì ở đó Back và tab Decks đã làm đúng việc đó. 930 test pass. **Footgun ghi lại:** một dấu `;` trong comment `--` của `.drift` cắt statement sớm và chỉ là warning, nên build xanh mà method sinh ra không tồn tại. **M4.10e `done` — bốn ghi nhận review về thị giác, đo trước sửa sau:** border của card ở light chỉ 1,40:1 trong khi dark là 1,82:1 — một cơ chế hai độ mạnh, và đó mới là lý do light nhìn phẳng; `borderSubtleLight` nay là `#BEC0C3` (1,82:1, khớp dark tới hai chữ số thập phân) và **độ lệch giữa hai mode có test chặn** chứ không chỉ có sàn. Card về hai dòng (`46 cards · 5 due · 8 boxes`). Màu và độ đậm chỉ dành cho trạng thái cần hành động. Breadcrumb bỏ bước cuối vì tiêu đề ngay trên đã nói. Bottom nav hai item kéo về giữa bằng giới hạn **tự vô hiệu** khi thêm tab. **Hai kết luận đổi sau khi đo:** giá trị border được đề xuất (`#E5E7EB`) *sáng hơn* cái đang dùng nên sẽ làm tệ hơn, và amber trên nền trắng **không** fail 4,5:1 — nó là 5,41:1, phần đúng của ghi nhận là nhấn mạnh chứ không phải tương phản. 931 test pass, 19 golden cập nhật. **M4.10f `done` — colour-system conformance audit toàn app:** quét bằng AST 112 file / 160 site, resolve theo `ThemeData` đã build, 17 vi phạm có target token cụ thể, không sửa một màu nào. **V1 lớn nhất:** ở light `surface` là `#FFFFFF` không có hue nào — trang có tint còn cái nằm trên trang thì không. **V2/V4 = 0 và đó là kết quả đo.** **Ba điều việc tính toán bác bỏ:** ceiling 1.6:1 của brief báo "too-heavy" ở **cả hai** mode nên nó bất đồng với depth model chứ không bắt regression; ba giá trị đề xuất tự tính bằng tay đều sai, giải lại bằng ràng buộc cho thấy 24° lệch seed của M4.10e là **tránh được**; và fix V1 cho `surface` làm khoảng cách card↔trang tụt 1.090 → 1.064, ghi rõ chứ không giấu. Bổ sung **MX-VIS-002** — 5 quy tắc đúng-hôm-nay vào visual audit, cả 5 đã fault-inject. **Không kiểm chứng được:** `component-map.json` không tồn tại trong repo. 943 test pass. **M4.10g `done` — chủ dự án bác tiền đề "flat by design", fix phần đáng fix:** "app không dùng shadow" chưa bao giờ là luật — không AD, không BR, không test, và `docs/checklist.md` còn yêu cầu Elevation token chưa ai làm; nó chỉ là hai đoạn comment bị hai milestone trích như ràng buộc. Sau quyết định "app cần độ nổi": V6 shadow/scrim từ tiềm ẩn thành lỗi thật (dark `#000000` → `#04040B` suy từ seed), V5 fill/border hết translucent tại điểm vẽ, màn hình lỗi đọc `platformBrightness`. **Viết rule trước, chạy cho đỏ để nó tự liệt kê chỗ mắc lỗi, rồi mới fix.** **Ba lỗi của chính harness do fault-inject phát hiện:** R8 khớp vào comment của chính nó; path chuẩn hoá rỗng nên trên Windows không quét gì; và scanner bỏ sót `Color(0x...)` không có `const` — bản audit M4.10f báo 158 site, thật ra **244**. 946 test pass, 4 golden đổi. **M4.10h `done` — elevation thật:** `AppElevation` là token mà checklist yêu cầu từ đầu và chưa ai làm. Light vẽ shadow, dark không — **đo được**: shadow dark chỉ mua ΔL* 0.26 trong khi bậc surface đã là 7.70, vì trang dark nằm đáy thang lightness. Alpha được **giải ra** chứ không chọn (light 7.62 L* so với dark 7.70). Border light hạ 1.82 → **1.50**, vào trong band 1.6 của brief — nó không còn phải gánh biên một mình. `app_theme_test.dart` đổi từ đo *tương phản border* sang đo **độ nổi của card**, vì luật cũ đúng khi border là cue duy nhất và sai ngay khi có shadow. 946 test pass, 15 golden light đổi. **M4.10i `done` — audit màu sắc về 0 vi phạm:** card light hết trắng thuần (`#FBFBFE`, seed@0.02, hue 240) cùng bốn token trắng khác; màn hình lỗi và khung web dùng token thật thay vì literal; nhãn disabled của action sheet precompute. **Một kết luận của chính agent bị bác:** M4.10g xếp 6 literal ở `error_screen` là "mirror không tránh được" vì file không đọc được `Theme` — sai, `AppColors` là hằng số biên dịch, import thẳng được. **Xung đột hai luật:** tint làm card tối đi nên phá luật ladder ≥3 L* của M3.5b; luật đó là luật của một mode không có cue nào khác, nên light hạ xuống 2.0 còn tổng độ nổi vẫn bị chặn — 7.75 so với 7.70. Thêm **R9** (mọi neutral phải mang hue của seed), đã fault-inject. 954 test pass. ****M4.10j `done` rồi `superseded` bởi M4.10k trong cùng PR** — màn design-system showcase in-app (route debug-only `/dev/design-system`) được dựng, rồi chủ dự án chọn Widgetbook để dễ maintain trước khi merge; màn in-app + cổng route + ngoại lệ l10n test đã gỡ sạch. **M4.10k `done` — Widgetbook catalog:** package `widgetbook/` riêng phụ thuộc `memox` qua path (pubspec app không đổi một dòng), theme addon dùng chính `buildLightTheme()`/`buildDarkTheme()`, 3 trang token đọc ngược từ theme đang chạy + 11 component `Mx*` mỗi cái một playground knobs, viewport có case Compact 320×568 của M4.8b; font copy vào catalog vì font khai báo trong package bị prefix `packages/<pkg>/` trong khi theme gọi tên trần; `ci.yml` thêm `pub get` lồng (root analyze tạo context cho package lồng — thiếu dep là 117 lỗi, đo bằng tái hiện) và smoke test catalog. **M4.10l `done` — backfill #57 vào catalog:** category Screens với `DeckListScreen` mount nguyên màn qua `ProviderScope` fake contract, knob 6 scenario, `GoRouter` mini trong use-case nên drill-down thật ngay trong khung catalog; `MxPillButton` playground; fake resolve scheduler qua root (BR-06) — chính catalog lộ lỗi "Eight boxes trong cây sm2" của bản fake đầu; khi #58 (breadcrumb) merge, fake dựng `ancestors` từ chuỗi id nên breadcrumb bấm được trong catalog, và `MxBreadcrumb` có playground knob depth 2–10. M4.10m `done` — giành lại phần Material tự quyết:** bảy nhóm màu framework đang vẽ mà app chưa đặt tên nay do app khai báo — barrier (dialog + sheet), progress, tooltip, text selection, divider, scrollbar. Barrier từ `Colors.black54` xám thuần sang suy từ `scrim`. **Lỗ hổng có hệ thống:** audit quét `lib/` nên màu tồn tại như mặc định framework thì vô hình với nó — đúng mục "Not verified" của M4.10f. **Một lỗi có sẵn lộ ra:** spinner dùng `primary` (mặc định Material) chỉ đạt **2.81:1** ở dark, dưới sàn 3.0; nay dùng `focusRing` (5.36 / 7.41). **Một hướng đã bỏ kèm lý do:** mở strict audit sang overlay cho 6 blocking failure toàn là chữ dưới barrier — auditor đúng nhưng sai chủ thể; thay bằng test giá trị ở tầng theme. 959 test pass. **M4.10n `done` — nâng shared widget:** icon action sheet thôi cạnh tranh với nhãn của chính nó, `MxErrorState` dùng nút chính khớp `MxEmptyState`. **Hai trong bốn nhận định của agent không đứng vững và đã báo lại thay vì sửa bừa:** input dùng `md` còn card dùng `lg` — một hệ nhất quán chứ không bất nhất; empty state đã là 16/8/24 tức là **không** đều. Cả hai là đọc ảnh nén rồi suy ra. **Một "lỗi component" hóa ra là lỗi của tấm ảnh:** `MxListTile` có đúng một caller là move-deck sheet, mà sheet là `surface`; specimen lại chụp nó trên `Scaffold` trống. Sửa ảnh, không thêm capability không caller. 959 test pass. **M4.10o `done` — AD-14 chốt hệ màu và chiều sâu.** Seed là nguồn của mọi trung tính; mỗi role một hue qua một bộ sinh; border lấy hue từ chủ của thứ nó bọc; **chiều sâu là mục tiêu đo được chứ không phải cơ chế cố định** — light 7.75 L* từ bậc surface + shadow, dark 7.70 L* từ bậc surface + border, và dark không vẽ shadow vì đo được chứ không vì thẩm mỹ. Ghi cả bốn phương án đã loại kèm milestone loại chúng. Không đổi dòng code nào. **Lý do tồn tại:** hai đoạn comment từng bị hai milestone đọc thành luật. **M4.10p `done` — token Flutter theo design system.** Chủ dự án đưa design system từ claude.ai/design về `design_system/` và chốt **`tokens/*.css` là chuẩn cho giá trị token**; Dart lệch thì Dart sửa. Mọi token số đã khớp sẵn; 11/40 token màu lệch và cả 11 lấy theo CSS. **Audit bắt được một lỗi thật:** `successLight` mới làm nhãn 14px tụt xuống 4.30:1 trên `secondaryContainer` — lời giải nằm trong chính design, `VerdictAction` của nó giữ nền trung tính đúng vì lý do đó. **Mâu thuẫn là của design:** hex làm `warning` to nhất ở light trong khi readme của nó viết "danger carries the most saturation". 14 golden đổi, 959 test pass. **M4.10q `in progress` — parity checklist với design system.** 77 dòng ghép từng artefact, 33 đã review, 12 finding, **sửa 11**. Lỗi thật: `mx_loading_state.dart` ghi đè chính cái theme M4.10j viết ra để tránh spinner 2.81:1. Breadcrumb nay gập được ở giữa (BR-55 cho 10 cấp), `MxContentShell` có `subheader` và hairline theo scroll, nav bar có hairline trên, hover thôi rơi về mặc định Material. **Bỏ elevation của Material:** AD-14 quy định chiều sâu chỉ một cơ chế, nhận thêm `elevation` là đổi luật đo được lấy luật không đo được. 959 test pass. Còn 44 dòng. **M4.10r `done` — BR-88 và `MxProgressBar`.** Nửa `eight_box` đã có sẵn trong BR-16 từ trước; BR-88 nâng nó thành rule có ID và mở sang `sm2` với `interval_days >= 128` — khớp interval của box 8, không phải 21 ngày theo quy ước Anki. `learnedCardCount` về **cùng một statement** với hai count kia (AD-13). Hai token `--color-progress-*` thôi bị hoãn vì `MxProgressBar` là caller mà M4.10p bảo còn thiếu. 973 test pass. **M4.10s `done` — deck card theo đúng design.** Thẻ phẳng + hairline, vùng mở là target riêng, due tách khỏi meta line thành chip ở chân thẻ, ba trạng thái chân thẻ, well chuyển sang trung tính khi deck đã thuộc hết. **Chip due của design trượt WCAG ở light (3.12:1)** — mâu thuẫn thứ tư của design; em giữ nền của nó và suy ra màu chữ nó thiếu, 6.38:1, cùng hue trong 1.2°. **Không làm nút "Study"** vì M5 chưa có session để bấm sang — một control chết còn tệ hơn thiếu control. 973 test pass, đã render và xem cả hai mode. **M4.10t `done` — level summary panel.** Con số đến hạn + câu nối tiếp + thanh tiến độ của cả cấp, **không đọc thêm lần nào**: số của child là cả subtree, subtree anh em rời nhau, nên cộng trong bộ nhớ ra đúng tổng và panel không bao giờ lệch thời điểm với list. "Xong" thay cho số 0 (BR-29). **Streak và nút Start studying cố ý vắng** — cả hai cần M5, và một streak luôn bằng 0 tệ hơn không có streak. 973 test pass. **M4.10u `done` — đóng nốt 77 dòng parity checklist.** 47 match, 14 đã sửa, 8 n/a, 4 chặn ở M5, 4 lệch có chủ đích. Ba chỗ sửa lần này: **A16** Dart không có token easing và chỗ duy nhất dùng curve viết `Curves.decelerate` — preset đó là `(0,0,0.2,1)` còn design là `(0,0,0,1)`; **A7** tracking 1.1 là literal; **D3** danh sách chưa có tiêu đề "Your decks"/"Sub-decks". **Sáu chỗ design tự mâu thuẫn** — kết quả giá trị nhất của cả đợt: "theo JSX" không áp được mà không đọc. 973 test pass. **M4.10v `done` — số deck con và căn hàng tiêu đề.** Đối chiếu ảnh render của design kit, hai chỗ lệch nhìn thấy được đã đóng: meta line mở đầu bằng `N deck con` (**đếm con trực tiếp**, ngược với hai count kia đếm cả subtree), và hai pill dạt về cuối hàng tiêu đề. **`Row` + `Expanded` tràn ở 320 + textScaler 2.0** — hai pill cộng lại đã rộng hơn màn hình khi chữ gấp đôi; `Wrap` lồng `Wrap` làm được cả hai. 973 test pass. **M4.10w `done` — golden render ở đúng mật độ máy thật.** Trước đây mọi golden render ở DPR 1, nên màn 420×1040 logic ra ảnh 420×1040 pixel — bằng một phần ba máy thật, và đọc review một tấm như vậy là đoán xem cạnh sai hay chỉ thiếu mẫu. **DPR 3 là con số suy ra**: mật độ của hai máy design system dựng khung kit. **Layout không đổi gì** — logic = physical / dpr — nên mọi assertion rect nguyên vẹn. 646 KB → 2.27 MB, 3.5× chứ không phải 9× vì UI phẳng nén tốt. 973 test pass. **M4.10x `done` — tìm kiếm toàn subtree.** Mảnh cuối của design đã dựng, **không query mới và không đổi contract**: use case đọc `watchAllDecks()` rồi khoanh phạm vi và dựng đường dẫn trong bộ nhớ, đúng tiền lệ move-target picker. **Ba lỗi thật chỉ test bắt được:** hai mutator trên một input-state notifier, ô search cao 20px dưới sàn 48, và chữ dính đỉnh pill vì `TextField` không được bảo `expands`. **`AppBar.bottom` là sai công cụ cho subheader** — nó bắt khai báo chiều cao trước, mà chiều cao đó phụ thuộc cỡ chữ. 28 finder hỏng vì đúng một lý do, sửa bằng một finder dùng chung. 978 test pass. **M4.10y `done` — nút đóng panel tổng kết.** Mảnh cuối của design không bị chặn bởi M5 đã đóng. **Không khoá theo cấp**: lý do design cho phép ẩn là một tâm trạng chứ không phải một chỗ, nên ẩn ở cấp gốc rồi thấy nó quay lại sau hai lần chạm là không được lắng nghe. **Luôn có thứ gì đó ở chỗ đó** — một dòng chữ thay chỗ và đưa nó về, và test đi trọn vòng chứ không dừng ở "đã biến mất". 979 test pass. **M4.10z `done` — ô search: căn dòng và focus.** Hai chỗ lệch so với design kit đã đóng. **Phép đo đầu tiên của em sai:** golden chụp cả màn chứ không phải riêng pill, nên mọi cửa sổ quét pixel rơi vào nền trang — số liệu thuyết phục mà vô nghĩa; render pill trên nền phẳng rồi nhìn mới thấy chữ cao hơn dòng icon. Nguyên nhân là hỏi `InputDecoration.constraints` cho chiều cao 48: nó nới hộp và để chữ dính trần. Focus nay đổi nền + viền mà không đổi kích thước; viền vẽ bằng màu nền thay vì trong suốt vì **alpha 0 không phải token** và audit chặn đúng. 985 test pass. M4.11 **done** (11 lát + recursive review). M4.11a **done** — fold Unicode cho search thẻ (schema v3): bốn lệnh bàn giao đã chạy thật trên máy có toolchain, snapshot v3 đã commit, và lệnh thứ tư lộ ra bốn chỗ khác còn chốt cứng "schema là v2" cộng một test card đỏ sẵn từ #121 — tất cả đã đóng, `flutter test` 1367/1367 pass, `check_drift.sh` 0 error. M4.11b…M4.11f **done** — 60/60 IT scenario chạy trên emulator thật; bốn vòng sửa hiển thị của card list (gutter đôi, pill quá rộng, `Due` tách hẳn khỏi `New` ở tầng query, badge `now` thôi nói thay cho thẻ chưa có lịch); và M4.11f đưa nhãn chip khỏi weight của button. M4.11g cho màn deck bộ ảnh render thật đầu tiên, và đưa review render về đúng mật độ M4.10w đã chốt; M4.11h gỡ bản dựng tay của màn deck khỏi `design_preview`. M4.12a…M4.12d **done** — starter template có seed idempotent; Playwright E2E chạy trên Flutter Web ở mobile viewport; 15 bất biến chạy sau **từng bước** của luồng bắt buộc và báo cáo demo flow kèm ảnh từng bước; và "design parity dưới 3%" thành một cổng chạy được — đo bằng tỉ lệ `drift` còn mở trong parity checklist (**1/80 = 1,25%**), vì so pixel giữa Chrome và Skia có một sàn không parity nào kéo xuống được. Cùng lúc phát hiện chín dòng checklist vẫn ghi `drift` sau khi code đã sửa xong từ ba milestone trước — bảy dòng đóng, hai dòng vốn là phân kỳ cố ý, một dòng thật (F15) được giữ mở có lý do. **86/86 task M4 đóng; M5 đủ điều kiện bắt đầu.** **Phase 10 (networking) hoãn** — AD-01, AD-05 |
| M5 · Study vertical slice — UC-05 (Phase 14) | todo | Bắt đầu **sau M4.12**. Không còn là vertical slice đầu tiên — Deck/Card CRUD đã hoàn thành trong M4.8–M4.12 và M5 không triển khai lại. Study MUST NOT bắt đầu khi M4.12 chưa `done` |
| M6 · Test suite (Phase 15) | todo | Chạy song song **từ M4.8 trở đi**, không đợi tới sau Study |
| M7 · CI/CD (Phase 19) | todo | Bắt đầu được ngay sau M2. Job Android + Web, chưa có iOS (AD-04) |
| M8 · Release Android (Phase 16–18, 20–22) | todo | |
| M9 · Backend Spring Boot + auth + sync (Phase 10) | todo | Sau khi M8 ổn định |
| M99 · Adhoc | — | Task chủ dự án giao trực tiếp, ngoài chuỗi phụ thuộc. M99.1 **done** — `master-flow.md`. M99.2 **done** — Deck và Card thành bản tham chiếu (AD-17) |

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
- **Goal:** Áp thiết kế: scheduler theo deck, khoá sau lượt học đầu, reset +
  generation, hai tập action khác nhau.
- **Output:** `docs/architecture.md` (AD-06 viết lại, AD-09 mới),
  `docs/business-rules.md`, `docs/data-model.md`, `docs/use-cases.md`,
  `docs/product.md`, `CLAUDE.md`,
  `flutter-data-layer/references/persistence.md`
- **Những gì bị đảo so với bản trước:**
  - SM-2 **vào lại MVP**.
  - 8-box đổi từ 4 mức đánh giá sang **2 action** `forgotten`/`remembered`.
  - Scheduler chuyển sang "đổi tự do trước lượt học đầu, khoá sau đó, mở lại bằng
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
- **Goal:** Chốt mô hình cây deck nhiều cấp, hoàn thiện study answers và session
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
    `kind`, session `status`/`end_reason`, 14 query bất biến
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
  - [x] `study_answers` phân biệt `scheduled` và `relearning` bằng cột tường
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
- **Ranh giới sở hữu — cập nhật ở deck-golden hardening (supersede mô hình
  upstream+refresh):** thư mục `code-verification-guard-v2/` nay **vendored vào và
  thuộc sở hữu của MemoX** — một nguồn sự thật duy nhất, **sửa tại chỗ**, commit
  cùng thay đổi MemoX tương ứng, chạy `python -m pytest -q` trong thư mục đó. Bản
  vendor được commit vào đây để một lần clone mới chạy được cổng chính ngay — CI và
  `dod_check.sh` đều dựa vào điều đó. **KHÔNG** re-clone một remote guard riêng đè
  lên thư mục này: một lần refresh như vậy âm thầm xoá các fix chỉ tồn tại ở bản
  vendor (fix false-positive `common.no_commented_out_code` và `DateTime.now()`
  trong comment) — chính là bẫy hai-nguồn-sự-thật mà mô hình cũ tạo ra. Các fix đó
  được `tests/test_memox_false_positive_regressions.py` ghim lại. Phiên bản vendor
  ghi ở `code-verification-guard-v2/VERSION`. Xem `code-verification-guard-v2/AGENTS.md`.
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
  - [x] Ruleset `memox-v7` từng merge **upstream** vào
        `ntgptit/code-verification-guard-v2` (PR #6) tại thời điểm đó.
        **Supersede ở deck-golden hardening:** guard nay vendored-và-thuộc-MemoX,
        không còn upstream nào là nguồn sự thật (xem bullet Ranh giới sở hữu).
  - [x] ~~Bản vendor byte-identical với upstream, refresh bằng cách copy lại,
        lệnh refresh ghi ở đầu `code-verification-guard.yaml`.~~ **Đã bỏ:** lệnh
        refresh sẽ xoá các fix chỉ có ở bản vendor; nó đã được gỡ khỏi
        `code-verification-guard.yaml` và thay bằng mô hình sửa-tại-chỗ.
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
  4.1; một feature `study` rỗng đúng cấu trúc để script có gì để kiểm.
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
- **Ba file khung, mỗi file một trách nhiệm rõ ràng:** `study_repository.dart`
  (contract, pure Dart), `study_repository_impl.dart` (implement nó), và
  `study_placeholder_screen.dart` — màn placeholder **chuyển từ `app.dart` vào
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
  - [x] ~~`ValidationFailure` mang `Map<String, String> fieldErrors`, mặc định
        rỗng để call site không phải null-check.~~ → **thay ở M4.10b** bằng
        `Set<Enum> problems`: key chuỗi không gì kiểm được, còn value là câu chữ
        UI bị cấm render — nên presentation bỏ qua value và tự dẫn lại luật, tức
        là BR-01 có thêm một chủ sở hữu.
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
- **Output:** `test/study/` (harness + 8 ảnh), và sau khi duyệt:
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
  `test/study/` (harness + 6 ảnh), 22 golden của shared widgets
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
  màn study chỉ có đúng hai mảng bão hoà là `forgotten` và `remembered`.
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
  ba file self-test mới, `test/study/` chuyển sang scoped allowance
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
  `audit_allowance_test`), `test/study/deck_list_preview_test.dart`
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
- **App shell:** `StudyPlaceholderScreen` nay dựng từ `AppScaffoldWidget` +
  `AppEmptyStateWidget`, tức bộ component được chứng minh chạy end-to-end trước
  khi có màn hình thật phụ thuộc vào nó. Chưa triển khai màn study (M5.4).
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
  rõ đây là điểm cắm guard (AD-03). — `route_names.dart` **chuyển sang
  `core/navigation/` ở M4.10b**: router đăng ký tên, screen dùng tên, không bên
  nào sở hữu.
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
  với `home == null`, `goNamed` tới study, redirect không chặn, 404 thay red
  screen, copy đã localization và không lộ URL, nút quay về, fallback dùng
  `AppScaffoldWidget` + `AppErrorStateWidget`
- **Checklist phases:** 8.1, 8.2

### M4.1a · Screen audit coverage gate

- **Status:** done — cơ chế registry đã được **MX-VIS-001 thay thế** ở batch M4
- **Goal:** Ép mọi màn hình mới trong `lib/` phải được visual audit, bằng một
  cổng không thoả mãn được bằng file rỗng.
- **Scope:** registry `audited_screens.dart` lái cả audit lẫn coverage check;
  `PendingAudit` có rationale và WBS task; kiểm vị trí file screen; audit thật
  cho hai màn đang có; đổi tên `test/study/` → `test/design_preview/`.
- **Out of scope:** state matrix, golden cho màn mới, M4.2.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/visual_audit/screens/{audited_screens,screen_audit_coverage}.dart`,
  `screen_audit_test.dart`, `screen_audit_coverage_test.dart`;
  `test/design_preview/` (đổi tên từ `test/study/`)
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
  `PASS_WITH_UNRESOLVED`. Ba màn replica trong `test/study/` dùng chuỗi cứng nên
  chưa bao giờ chạm vào. Đã thêm delegate, và thêm `NoErrorWidgetRule` để một màn
  không build được **không bao giờ** pass — trước đó nó chỉ là
  `unknownRenderType`.
- **`test/study/` đổi tên thành `test/design_preview/`:** ba màn trong đó là bản
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
  `card_study_states`, `study_answers`, `study_sessions`; index; `PRAGMA
  foreign_keys = ON` trong `beforeOpen`.
- **Out of scope:** named query nghiệp vụ (M4.3), DAO và repository (M4.9 cho Deck/Card, M5.0 cho Study),
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
  - [x] Xoá root deck → deck con, card, study state, history và session đều
        biến mất, trên cây **ba cấp** với dữ liệu thật.
  - [x] `COALESCE(` không xuất hiện trong `lib/core/database/` (BR-57).
  - [x] `connection.dart` là **file duy nhất** gọi `driftDatabase`.
  - [x] Web không bị âm thầm tắt: `web/sqlite3.wasm` và `web/drift_worker.js`
        được vendor kèm test khoá version. Kiểm trong trình duyệt thật — wasm
        **compile được** (86 export, có symbol sqlite3), worker **khởi động
        được**, không console error.
- **Cột `action` bị drift âm thầm bỏ.** `ACTION` là keyword với SQL parser của
  drift: viết trần thì build **thành công**, code sinh ra **compile được**, và
  `study_answers` đơn giản là không có cột đó. Chỉ test đọc ngược cột từ SQLite
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
- **Scope:** `queries/study.drift` với `cardsDueForStudy` và
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
  bằng now", `now` thật sự điều khiển kết quả, và card không có study state
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
  để app có luồng quản lý nội dung demo được trước khi làm Study.
- **Scope:** sắp xếp lại M4 sau M4.4; giữ nguyên ID vĩnh viễn; thay M4.5–M4.7 cũ
  bằng task kế nhiệm có caller UI thật; buộc Deck/Card hoàn chỉnh trước Study.
- **Out of scope:** sửa code; sửa frozen business rules; thay đổi phạm vi MVP;
  triển khai bất kỳ task mới nào.
- **Editable documents:** `docs/wbs.md`
- **Output:** `docs/wbs.md`
- **Acceptance criteria:**
  - [x] Không có task ID trùng.
  - [x] Không renumber ID cũ — M5.1…M5.6 giữ nguyên số.
  - [x] Không dependency nào của task **active** trỏ tới task đã `descoped`.
  - [x] Task tiếp theo là **M4.8**.
  - [x] Study chỉ bắt đầu sau **M4.12**.
  - [x] `check_docs.sh` exit 0.
- **Vấn đề đã sửa.** Kế hoạch cũ tiếp tục theo tầng: M4.5–M4.7 dựng toàn bộ domain
  và data cho **cả** Deck/Card lẫn Study, rồi M5 mới có UI — mà CRUD Deck/Card
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
| M4.5 | `descoped` | Deck/Card → **M4.9** · Study → **M5.0** |
| M4.6 | `descoped` | Deck/Card → **M4.9** · Study → **M5.0** |
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
- **Reason:** scope gộp Deck/Card và Study vào **một** domain batch, tức là tiếp
  tục layer-first trong khi app chưa có luồng quản lý nội dung nào để demo. Một
  contract viết cho cả hai slice cùng lúc buộc phải đoán nhu cầu của presentation
  chưa tồn tại — đúng cái mà acceptance criteria của chính task này cấm.
- **Superseded by:** **M4.9** cho Deck/Card domain và repository contract ·
  **M5.0** cho domain và repository contract riêng của Study.
- **Goal:** _(lịch sử)_ Có hợp đồng domain viết theo nhu cầu presentation,
  không theo hình dạng Drift.
- **Scope:** `features/study/domain/entity/` (`DeckEntity`, `CardEntity`,
  `CardStudyStateEntity`, `StudySessionEntity`, `StudyAnswerEntity`), enum
  `SchedulerType`, `StudyAction`, `StudyAnswerKind`, `SessionStatus`,
  `SessionEndReason`, `DeckContentType`; repository contract dạng abstract.
- **Out of scope:** implementation (M4.6), use case (M5.2).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/domain/`
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
  slice. Triển khai tràn toàn bộ study domain trước khi có màn hình nào gọi tới
  sinh ra code không ai chứng minh được là đúng — nó chỉ được chứng minh là
  *compile được*.
- **Superseded by:** **M4.9** cho Deck/Card data layer · **M5.0** cho data layer
  riêng của Study.
- **Goal:** _(lịch sử)_ Nối domain xuống Drift, và chặn mọi exception ở đúng
  ranh giới repository.
- **Scope:** DAO theo feature, mapper Drift row ↔ entity, repository
  implementation, mapping exception → `Failure`, transaction cho thao tác nhiều
  bước.
- **Out of scope:** remote data source, cache TTL, sync (AD-01, AD-05).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/data/`
- **Acceptance criteria:**
  - [ ] `check_architecture.sh` exit 0 — presentation chưa tồn tại, nhưng
        `data/` không được import ngược lên.
  - [ ] Không `DriftWrappedException` nào thoát khỏi repository — test khẳng
        định repository ném `DatabaseFailure`.
  - [ ] Repository đọc bằng `watch()` stream, không phải `Future` một lần
        (AD-01) — test khẳng định stream phát lại khi dữ liệu đổi.
  - [ ] Mapper xử lý enum lạ bằng cách map về giá trị `unknown` thay vì throw.
  - [ ] Tạo card sinh đúng một `card_study_states` trong cùng transaction
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
  E2E. Fixture riêng cho Study, nếu cần, mở rộng ở M5.
- **Goal:** _(lịch sử)_ Có dữ liệu thật để chạy vertical slice, đánh dấu rõ là
  fixture.
- **Scope:** `assets/templates/manifest.json` + một template cây deck nhiều cấp
  (root → deck con → deck chứa card) cho cả `eight_box` và `sm2`; loader nạp vào
  database; helper `seedTestDatabase()` cho test.
- **Out of scope:** nội dung production (BR-87 — thay trước M8); UI thư viện
  starter (UC-01 không thuộc M5).
- **Editable documents:** `docs/wbs.md`
- **Output:** `assets/templates/`, `lib/features/study/data/template_loader.dart`,
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
  controller; study verdict control và Study screen (M5).
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
  phải làm là màn Study.** Chiều cao đang **đúng ở sàn** 48dp
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
  không phải token, và nó thuộc **M5** khi màn Study được dựng. Ghi lại ở đây
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
  `CardStudyStateEntity` cần để tạo card đúng BR-09, `SchedulerType`,
  `DeckContentType`, command/value object khi có caller thật, repository contract
  theo UC-02, UC-03, UC-04, UC-08, UC-09. **Data** — DAO Deck/Card, mapper,
  repository implementation, mapping `Failure`, `watch()` stream, transaction cho
  thao tác nhiều bước.
- **Out of scope:** `StudySessionEntity`, `StudyAnswerEntity`, `StudyAnswerKind`,
  `StudyAction`, `SessionStatus`, `SessionEndReason`, study persistence,
  scheduler formula, study use case (tất cả → **M5.0**, **M5.1**); controller UI.
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
  - [x] Tạo card sinh **đúng một** study state, atomic (BR-09); insert state
        lỗi thì card rollback. → trigger `RAISE(ABORT)` trên
        `card_study_states`: card **và** content-type lock cùng rollback;
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
        chạy `deckById`/`subtreeDeckIds` (recursive CTE)/`studyStateByCard`
        typed query và `watchRootDecks()` thật, dọn fixture, đóng database.
        Phát hiện và sửa hai lỗi production: `driftDatabase()` thiếu `web:`
        options (web chưa từng mở được database), và `drift_worker.js` prebuilt
        từ release drift 2.34.0 lệch ABI với `sqlite3.wasm` 3.5.0
        (`LinkError: xFileControl`) — worker nay compile từ đúng lockfile, quy
        trình ghi ở `web/WEB_ASSETS.md`.
- **Files:** domain — `deck_entity.dart`, `card_entity.dart`,
  `card_study_state_entity.dart`, `scheduler_type_model.dart`,
  `deck_content_type_model.dart` (hai enum mang hậu tố `_model` vì guard
  `memox.naming.domain_file_role_suffix` bắt buộc hậu tố role),
  `deck_deletion_impact_model.dart`, `deck_repository.dart`. Data —
  `local/deck_dao.dart`, `deck_mapper.dart`, `card_mapper.dart`,
  `card_study_state_mapper.dart`, `deck_repository_impl.dart` (+ 2 part
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
  di chuyển subtree · đọc card theo deck · tạo card kèm đúng một study state ·
  sửa card không đụng study state/history · xoá card · stream phát lại.
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
- **Out of scope:** UI/controller/provider (M4.10, M4.11); Study domain (M5);
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
        (content lock + đúng một study state, trigger-injected rollback pass);
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

### M4.9b · Chuyển ownership vật lý Card sang feature riêng

- **Status:** done
- **Goal:** Ranh giới Card đã tách về trách nhiệm ở M4.9a cũng được phản ánh
  đúng trên cây thư mục feature-first, không còn source Card nằm dưới Deck.
- **Scope:** chuyển Card entity, repository contract/implementation, mapper và
  DAO từ `lib/features/deck/` sang `lib/features/card/`; thay phụ thuộc
  `CardRepositoryImpl -> DeckDao` bằng adapter deck-context hẹp do Card sở hữu,
  dùng cùng `AppDatabase`; cập nhật import, test ownership và WBS.
- **Out of scope:** schema/query `.drift`; hành vi CRUD; controller/UI (M4.10,
  M4.11); Study domain (M5).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/card/domain/`, `lib/features/card/data/`,
  `test/features/card/data/card_repository_test.dart`, cập nhật boundary test
- **Acceptance criteria:**
  - [x] Không còn Card entity/repository/mapper/DAO source dưới
        `lib/features/deck/`.
  - [x] `lib/features/card/data/` không import `lib/features/deck/data/` hoặc
        presentation của Deck; chỉ dùng Deck domain model cho invariant chung.
  - [x] `createCard` vẫn nhận một `AppDatabase` duy nhất và transaction vẫn bao
        trọn content-type lock + card + đúng một study state (BR-09, BR-62).
  - [x] Card integration test nằm dưới `test/features/card/`; boundary test
        chặn việc đưa source Card trở lại Deck.
- **Dependencies:** M4.9a
- **Tests required:** Card repository transaction/rollback; Deck/Card source
  boundary; architecture guard; full repository DoD
- **Checklist phases:** 4.1, 11.1, 14.2, 14.3, 15.1

### M4.10 · Deck management full-stack

- **Status:** done
- **Goal:** Người dùng quản lý được toàn bộ cây deck từ UI xuống Drift, không cần
  fixture hay thao tác database thủ công.
- **Scope:** named route; root deck list; điều hướng deck lồng nhau; deck detail;
  tạo root deck kèm chọn scheduler; tạo sub-deck; đổi tên; xác nhận xoá kèm số
  deck/card sẽ mất; action theo `content_type`; reset `content_type` khi rỗng;
  move subtree trong phạm vi MVP; Riverpod state/controller; loading, loaded,
  empty, submitting, error; ARB en/vi; widget riêng của feature.
- **Out of scope:** card editor (M4.11); study session (M5); UI thư viện starter
  (UC-01); sync/backend; media và tag.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/deck/presentation/`, `lib/l10n/`,
  `test/features/deck/`, `test/visual_audit/screens/features/deck/`
- **Acceptance criteria:**
  - [x] Cold start mở **root deck list**, không phải study placeholder.
  - [x] Root chỉ cho tạo deck (BR-58); tạo root **bắt buộc** chọn scheduler
        (BR-11).
  - [x] Sub-deck `unset` cho chọn *Create card* hoặc *Create deck*; deck đã có
        `content_type` chỉ hiện đúng một action (BR-63, BR-64).
  - [x] Đổi tên validate trim, tối đa 200 ký tự (BR-01).
  - [x] Xác nhận xoá hiển thị số deck và card sẽ mất (BR-03).
  - [x] Cây hỗ trợ **ít nhất ba cấp** (BR-55).
  - [x] Move không cho vào chính nó hoặc descendant (BR-69); move sang root khác
        scheduler/generation bị chặn (BR-70).
  - [x] Dữ liệu tự cập nhật qua stream — không cần refresh thủ công.
  - [x] Toàn bộ copy từ ARB; không raw color, text style, spacing hay radius.
  - [x] 320×568 và `textScaler` 2.0 không overflow.
  - [x] Mọi production screen đăng ký strict visual audit (MX-VIS-001), và đạt
        **PASS** ở light lẫn dark — không chấp nhận `PASS_WITH_UNRESOLVED`.
  - [~] Screen có design reference đạt pixel difference **dưới 3%** — **không
        áp dụng được, và không tuyên bố đạt.** `test/design_preview/goldens/
        deck_list_*.png` chứa hai thành phần ngoài phạm vi M4.10: ô Search và
        CTA *Study 15 cards due today*. So pixel giữa hai ảnh khác scope sẽ ra
        một con số vô nghĩa, và triển khai Search/Study chỉ để đuổi pixel là
        đúng thứ brief cấm. Phần **được dùng làm reference**: bố cục hàng
        (tên · dòng chi tiết · badge đến hạn) và quy tắc "deck không có gì đến
        hạn thì không có badge màu". Baseline production của M4.10 là 16 strict
        visual audit state, không phải một golden so pixel.
- **Slice 1 — root deck list là Home (xong).** Chỉ luồng **đọc**. Route `/` đổi
  từ `RouteNames.study` sang `RouteNames.decks` và render `RootDeckListScreen`;
  `rootDecksProvider` nối `DeckRepository.watchRootDecks()` vào UI qua bốn
  trạng thái loading / empty / loaded / error; retry trên error state
  `invalidate` provider nên thực sự mở `watch()` mới. ARB en/vi thêm bảy key,
  bỏ `homePlaceholderMessage`. Test: 8 route, 8 controller, 15 widget, 6 strict
  visual audit — cả sáu **PASS**, không có `PASS_WITH_UNRESOLVED`. Toàn bộ suite
  498 test xanh.
  - **~~Không có Bottom Navigation và không có `StatefulShellRoute`~~** —
    **superseded bởi M4.10a.** Tại thời điểm slice 1, quyết định này giữ nguyên
    từ M4.1 và đúng: app chỉ có một destination thật. Chủ dự án sau đó quyết
    định MVP có Bottom Navigation; xem M4.10a.
  - **~~`StudyPlaceholderScreen` đã xoá~~** — **khôi phục ở M4.10a**, nơi nó
    trở thành branch 1 của navigation shell. Tại thời điểm slice 1 nó không còn
    production caller, và MX-VIS-001 coi audit của một screen đã biến mất là
    orphan, nên xoá là đúng. `features/study/` vẫn giữ domain + data anchor
    cho M5 suốt cả hai lần.
  - **~~DI đặt ở `lib/app/di/`~~, không ở feature:** lập luận đúng nhưng kết
    luận sai một nửa — **sửa ở M4.10b**. Chọn *implementation* thì đúng là việc
    của composition root, nhưng *khai báo* provider đặt ở đó khiến
    `features/deck/presentation/` phải import `app/`, tức là feature phụ thuộc vào
    shell nó đang được mount vào. Nay feature khai báo (`features/<f>/di/`, kiểu là
    contract), `app/di/repository_bindings.dart` bind. `appDatabaseProvider`
    (keepAlive) vẫn nằm cạnh database ở `core/database/`.
  - **`rootDecksProvider` tắt auto-retry của Riverpod 3.** Mặc định
    `ProviderContainer.defaultRetry` chạy lại 10 lần với backoff 200ms→6.4s, và
    **trong lúc retry state là `AsyncLoading`, không phải `AsyncError`** — nghĩa
    là một lần đọc lỗi sẽ quay spinner ~13 giây trước khi người dùng biết có
    chuyện gì. Đây là một truy vấn SQLite local, không phải network chập chờn:
    retry đúng chỗ là nút người dùng bấm được. Có test khoá hành vi này.
  - **Chưa có `DeckTile`.** Hàng danh sách hiện chỉ là tên deck, tức một
    passthrough thuần tới `MxListTile`; nó sẽ có file riêng khi có trách nhiệm
    thứ hai (tap target, due count). Lưu ý naming guard bắt file dưới
    `presentation/` phải kết thúc bằng `_widget`, nên tên file sẽ là
    `deck_tile_widget.dart` chứ không phải `deck_tile.dart`.
  - **Không có due count / card count** — `watchRootDecks()` trả deck, và tính
    các con số đó theo từng hàng trong Dart chính là N+1 mà UC-06 nêu đích danh.
    Chúng đi cùng query gộp, không sớm hơn.
  - **Hai phát hiện ngoài phạm vi, ghi lại để xử lý đúng chỗ:**
    - `_RenderListTile` đã thêm vào `_privateAndTransparent` của visual audit
      harness — `paint` của nó chỉ gọi `context.paintChild` cho bốn slot, đã đối
      chiếu với SDK 3.44.8. Đây là sự thật về Flutter nên thuộc về classification
      chung, không phải allowance lặp lại ở mọi màn có list.
    - Guard rule `memox.state_management.no_generated_ref_subclass` **báo sai**
      với signature `build` hai tham số của `ConsumerWidget`: nó đọc kiểu ref
      phía widget của Riverpod 3 như thể là `Ref` subclass sinh ra của Riverpod
      2. Rule này sẽ bắt sai mọi `ConsumerWidget` trong dự án. Fix thuộc repo
      guard upstream, repo này không được sửa. Slice 1 dùng `Consumer` bọc riêng
      phần body — vốn cũng đúng hơn về rebuild scoping, vì title app bar là hằng.
- **Slice 2 — phần còn lại của Deck Management (xong).** Hoàn tất trong một
  branch và một PR, không chia nhỏ tiếp: create, detail, rename, delete, reset và
  move dùng chung router, controller pattern, repository stream và UI state, nên
  chia tiếp chỉ tạo thêm trạng thái tạm và CTA chưa hoạt động.
  - **Root list thành màn quản lý thật.** Mỗi hàng: tên, tổng card toàn cây, số
    đến hạn, scheduler. Due state mang **cả icon lẫn chữ** (UC-06 bước 3) — không
    bao giờ chỉ bằng màu. "Không có gì đến hạn" hiển thị trung tính (BR-29).
  - **Aggregate một query, không N+1.** `rootDeckSummaries` trong `deck.drift`:
    hai subquery `GROUP BY` join một lần, **không** correlated subquery và
    **không** vòng lặp Dart gọi `subtreeCardCount` từng deck — đó chính là N+1 mà
    UC-06 nêu đích danh. Cả hai count đi qua `root_deck_id` (BR-56, BR-57), nên
    đây là flat aggregate chứ không phải recursive walk. Predicate due **giống
    từng ký tự** với `study.drift`; có parity test chứng minh count == số card
    session phát ra, trên cùng dữ liệu và cùng `now` (BR-22). `:now` là parameter,
    không phải SQL clock, nên biên `due_at = now` dựng được và test được.
  - **Clock injectable, refresh khi app resume.** `clockProvider` +
    `deckListNowProvider` với `AppLifecycleListener`. Timer định kỳ đã cân nhắc và
    bỏ: nó đánh thức database theo lịch để đổi một con số không ai đang xem, và
    biên nó bắt được thì resume đã bắt. Không test nào đọc wall clock.
  - **Sáu controller ghi, mỗi operation một cái** — không phải một controller với
    sáu flag, tức chính lỗi `isLoading` dùng chung mà CLAUDE.md gọi tên. Mỗi cái
    chặn double-submit, gọi use case (nơi `DeckName.parse` áp dụng BR-01 — controller
    không tự validate), kiểm `ref.mounted` sau await, và giữ input khi thất bại.
    `DeckSubmitState` mang enum và `Failure`,
    **không mang message**: domain nói rule nào sai, screen chọn copy ARB — nên
    không chuỗi kỹ thuật nào tới được nhãn field.
  - **Route lồng `/decks/:deckId` là child route của Decks branch**, nên bottom bar
    còn, Back về đúng list, và chuyển sang Study rồi quay lại vẫn thấy deck đang
    mở. `RoutePathParams.deckId` là constant vì hai nửa (ghi ở screen, đọc ở route
    table) do hai file khác nhau viết và một typo thì compile được.
  - **Move picker hiện mọi deck**, cái không hợp lệ bị disable **kèm lý do**, thay
    vì ẩn đi. Ẩn thì người dùng đi tìm một deck đang nằm ngay đó, và "đích dùng
    chế độ ôn tập khác" không bao giờ học được (BR-74). Eligibility tính bằng
    `buildDeckMoveTargets` thuần từ một `watchAllDecks()` — một query, không N+1
    theo số cây. Repository **vẫn** kiểm lại toàn bộ rule trong transaction: UI để
    giải thích, repository để an toàn.
  - **Card creation là handoff sang M4.11, không phải CTA giả.** Deck `unset` hiện
    **cả hai** lựa chọn theo BR-61, nhưng lựa chọn card ở trạng thái disabled kèm
    câu giải thích rằng tính năng chưa có trong build này. Không ẩn (ẩn sẽ dạy
    người dùng rằng deck này chỉ chứa được deck, điều không đúng), không callback
    rỗng, không snackbar "coming soon". Không dòng Card source nào vào
    `lib/features/deck/`.
  - **66 ARB key** mới, en + vi, mỗi key có description.
  - **Test: 645 pass.** Mới: 11 aggregate/due-parity trên SQLite thật · 16
    move-target domain · 12 root-list read · 38 write controller · 22 root-list
    widget · 27 deck-detail widget · 6 deck-detail router.
  - **16 strict visual audit state PASS** (light + dark): root list ×3 (empty,
    loaded, error), deck detail ×5 (unset, empty_deck, loaded, card_handoff,
    not_found). Cả hai màn audit **qua production router**, nên shell, branch và
    bottom bar đều là đồ thật. Không state nào ở `PASS_WITH_UNRESOLVED`.
  - **Ba phát hiện ngoài phạm vi, đã sửa đúng chỗ:**
    - Visual audit harness đo `globalRect(node)` **trước** khi kiểm `isHidden`.
      `RenderBox.size` assert trên box chưa layout, nên walk ném lỗi đúng ở những
      node nó sắp bỏ qua. Chỉ lộ ra khi audit màn hình đầu tiên nằm trên **pushed
      route** — Navigator giữ route bên dưới trong cây, và Overlay có thể chứa
      deferred-layout child chưa layout. Đã đảo thứ tự và thêm box-chưa-layout vào
      `isHidden`.
    - `AppBar` tự thêm một back button trên pushed route. Nó là IconButton thật và
      góp đúng hai node không đọc được, nên mọi màn lồng có nhiều hơn số icon
      button nó khai báo đúng một. Đã đặt tên tham số `hasBackButton` thay vì gộp
      im lặng vào con số của từng caller.
    - `deck_copy_widget.dart` đổi tên thành `deck_labels_widget.dart`: guard đọc
      "copy" như một file backup, và đó là cách đọc hợp lý.
- **Card creation handoff sang M4.11.** Action *New card* hiện ở deck `unset` và
  deck `card` ở trạng thái disabled kèm giải thích. M4.11 chỉ cần enable nó và
  gắn `CardRepository`; không phần nào của Deck presentation cần sửa lại.
- **Dependencies:** M4.9, M4.1, M4.1a
- **Tests required:** domain, repository, controller, widget, route, visual audit
  strict, responsive, flow test
- **Checklist phases:** 8.2, 9.2, 9.3, 14.4, 15.2, 15.3, 15.4

### M4.10a · App shell và Bottom Navigation

- **Status:** done
- **Goal:** MVP có Bottom Navigation Material 3 với hai destination — Decks
và Study — thay vì một route đơn.
- **Quyết định product mới, supersede M4.1 và slice 1 của M4.10.** M4.1 ghi
  `StatefulShellRoute` và bottom navigation là out-of-scope, và slice 1 của
  M4.10 giữ nguyên quyết định đó; **cả hai đều đúng tại thời điểm được triển
  khai** — lúc ấy app chỉ có một destination thật, và một shell một tab là một
  shell phải dựng lại. Chủ dự án hiện quyết định MVP có Bottom Navigation với
Study là destination thứ hai. Mục M4.1 **không** được sửa để giả vờ bottom
  navigation từng nằm trong scope của nó; nó là ghi chép tại thời điểm đó.
- **Scope:** `StatefulShellRoute.indexedStack` với hai branch; `AppNavigationShell`
  ở `lib/app/shell/`; `MxNavigationBar` shared component; route `study` được
  khôi phục; ARB en/vi cho nhãn điều hướng; `navigationBarTheme`; router/shared/
  shell test; 4 golden; visual audit của Deck screen chụp qua router thật.
- **Out of scope:** Settings, Statistics, Library; FAB hoặc create action; nội
  dung thật của Study (M5.4); deep-link platform configuration.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/shell/app_navigation_shell.dart`,
  `lib/shared/widgets/mx_navigation_bar.dart`, `lib/app/router/`,
  `lib/core/theme/app_theme.dart`, `lib/l10n/`, `test/app/shell/`,
  `test/shared/widgets/mx_navigation_bar_test.dart`,
  `test/visual_audit/screens/features/deck/`
- **Acceptance criteria:**
  - [x] Bottom Navigation hiển thị trên Deck screen ở cả bốn trạng thái.
  - [x] Component tên `MxNavigationBar`, dùng Material 3 `NavigationBar`; không
        dùng `BottomNavigationBar` (có test khẳng định cả hai).
  - [x] Decks là tab mặc định; Study là tab thứ hai.
  - [x] Deep link `/study` mở đúng tab Study, không mở Decks rồi nhảy.
  - [x] Chuyển tab giữ branch state — đo bằng số lần `watchRootDecks()` được
        gọi: một lần cho cả vòng Decks → Study → Decks.
  - [x] Reselect tab được xử lý, không throw và không điều hướng sai chỗ.
  - [x] 404 vẫn hoạt động; nút Home vẫn về Decks.
  - [x] Nhãn lấy từ ARB en/vi; không hardcode route name hay path.
  - [x] Shared widget không biết feature, không biết GoRouter, không tự điều
        hướng — có test.
  - [x] Không overflow ở `320×568` và `textScaler` 2.0; light/dark pass.
  - [x] 4 golden mới; strict visual audit của Deck screen **PASS** ở cả ba
        trạng thái × hai theme, ảnh đã chứa Bottom Navigation.
  - [x] Deck root list của slice 1 không bị rollback.
- **`StudyPlaceholderScreen` được khôi phục.** Slice 1 của M4.10 đã xoá nó vì
  không còn production caller; giờ nó là branch 1 nên quay lại, cùng strict
  visual audit. ARB key đổi từ `homePlaceholderMessage` sang
  `studyPlaceholderMessage` — tên cũ mô tả một vai trò màn hình này không còn
  giữ.
- **Hai `Scaffold` là cố ý.** Shell mang bottom bar, mỗi màn mang
  `MxContentShell` với app bar. Đó là cấu trúc `StatefulShellRoute` được thiết
  kế quanh, và là thứ làm inset đúng: `Scaffold` có `bottomNavigationBar` trừ
  chiều cao đó khỏi `MediaQuery` của body, nên hàng cuối danh sách dừng **trên**
  thanh bar. Có test đo `list.bottom <= bar.top` với 30 deck.
- **Text scaling của bar không cần xử lý riêng.** Flutter's `NavigationBar` tự
  clamp text scale của nhãn (`_kMaxLabelTextScaleFactor`), đã kiểm tra trong SDK
  3.44.8 — nên không hardcode height và cũng không overflow ở `textScaler` 2.0.
  Có test khoá điều này để nếu Flutter bỏ clamp thì suite đỏ.
- **Visual audit của Deck screen giờ chụp qua router thật.** `Router.withConfig`
  gắn route table production vào trong `MaterialApp` của harness, nên shell,
  branch và bar đều là đồ thật. Audit một màn trần sẽ tạo ra tấm ảnh không người
  dùng nào nhìn thấy và để màu của bar không được đo.
- **Một sai sót có sẵn được sửa nhân tiện:** allowance của
  `_RenderColoredBox` trong hai audit cũ ghi rằng đó là nền `Scaffold` vẽ qua
  `ColoredBox` riêng. **Sai.** Node đó là backdrop chuyển trang của
  `_FadeForwardsPageTransition`, và ở trạng thái nghỉ nó vẽ `Colors.transparent`
  — đã kiểm chứng bằng cách dựng lại cây render và đối chiếu
  `page_transitions_theme.dart` của SDK 3.44.8. Số lượng bằng số `Navigator`
  trong cây, nên bản audit qua router thấy 3 còn bản một màn thấy 1. Rationale
  đã sửa ở cả ba file.
- **Hai render type nữa vào `_privateAndTransparent`:** `_RenderVisibility` và
  `_RenderLayoutSurrogateProxyBox`. Cả hai là `RenderProxyBox` không có màu của
  riêng mình — đã đối chiếu SDK. Chúng xuất hiện trên **mọi** màn audit qua
  router (`StatefulShellRoute` ẩn branch bằng `Visibility`; mỗi `Navigator` có
  một `Overlay`), nên thuộc classification chung chứ không phải allowance lặp.
- **Dependencies:** M4.10 (slice 1), M4.1, M4.8
- **Tests required:** router/branch, shared component, app shell layout,
  golden, strict visual audit
- **Checklist phases:** 8.1, 8.2, 12.1, 14.4, 15.2, 15.3


### M4.10b · Deck thành Golden Feature — hardening trước khi clone

- **Status:** done
- **Goal:** Rà Deck như thể nó là feature **mới** — đọc code thay vì đọc tài liệu
  về code — và đóng mọi khiếm khuyết mà một lần clone sẽ nhân bản. Không phải
  "code chạy chưa": mọi khiếm khuyết dưới đây đã pass toàn bộ test đang có.
- **Scope:** `features/deck` (mọi tầng), `core/error`, `core/navigation`,
  `core/database/queries/deck.drift`, `app/di`, `app/bootstrap`, harness
  (`check_architecture.sh`, `check_generated.sh`, `dod_check.sh`, hai rule của
  guard), CI, và tài liệu.
- **Out of scope:** luật nghiệp vụ (không BR/UC nào đổi), copy UI (không key ARB
  nào đổi), schema (`schemaVersion` giữ ở 1), và Card — M4.11 vẫn chưa bắt đầu.
- **Dependencies:** M4.10 (Deck full-stack), M4.10a (app shell)
- **Checklist phases:** 8, 11, 14, 19 (CI/CD)
- **Tests required:** domain (`DeckName` — luật của chính nó, giới hạn đo sau
  trim, parse idempotent); data trên SQLite thật (`deck_detail_read_test.dart`
  **đếm câu SQL** qua `QueryInterceptor`; `nextDueAt` — bỏ card due đúng tại
  `now`, null khi mọi card đã due, null khi không có card, null khi không có deck,
  sớm nhất trên mọi cây, đọc lại tại `nextDueAt` thì count tăng); domain use case
  (`watch_deck_move_targets_test.dart` — đếm số lần gọi repository, nguồn từ cùng
  lần emit, vắng nguồn → `NotFoundFailure`); presentation với fake-async
  (`root_deck_list_due_boundary_test.dart` — boundary trong tương lai, không có
  boundary, quá trần, dispose, không bao giờ hai timer); harness
  (`architecture_boundary_test.dart`, `dependency_pinning_test.dart`,
  `command_query_separation_test.dart` bằng AST). **Mỗi guard mới hoặc đã sửa phải
  fault-inject** và ghi lại lần tiêm đó.
- **Editable documents:** `docs/wbs.md`, `docs/architecture.md` (AD-13),
  `CLAUDE.md`, `feature_blueprint.md`, `feature_checklist.md`,
  `lib/features/deck/README.md`, hai file skill
- **Output:** AD-13; `domain/models/deck_name_model.dart`,
  `domain/models/deck_detail_model.dart`,
  `domain/models/root_deck_list_snapshot_model.dart`,
  `domain/usecases/watch_deck_detail_use_case.dart`,
  `di/deck_repository_provider.dart`, `app/di/repository_bindings.dart`,
  `core/navigation/route_names.dart`, `.github/workflows/ci.yml`,
  `check_generated.sh`, `test/app/architecture_boundary_test.dart`,
  `test/app/dependency_pinning_test.dart`,
  `test/features/deck/data/deck_detail_read_test.dart`,
  `test/features/deck/domain/watch_deck_move_targets_test.dart`,
  `test/features/deck/presentation/root_deck_list_due_boundary_test.dart`
- **Acceptance criteria:**
  - [x] BR-01 có **một** chủ sở hữu, và là một type — `DeckName`, constructor
        private. `grep` `validateName|nameProblem(` trong `data/` + `presentation/`
        **rỗng**; `grep` `'schedulerType'|fieldErrors` trong `lib/` **rỗng**. Một
        lần submit báo **cả hai** field sai.
  - [x] `DeckDetail` đến từ **một** statement. Chứng minh bằng cách **đếm câu SQL**
        qua `QueryInterceptor` thật, vì không assertion nào về giá trị phân biệt
        được hai thiết kế: tiêm lại shape hai-read → đúng hai test đếm đỏ, chín
        test hành vi còn lại vẫn xanh.
  - [x] Move-target stream không còn query thứ hai — nguồn lấy từ cùng lần emit,
        vắng mặt là `NotFoundFailure` có type; có test đếm số lần gọi repository.
  - [x] Due count refresh khi một card đến hạn **trong lúc app ở foreground**:
        `nextDueAt` từ cùng statement với các count, một `Timer` một-lần, không
        timer toàn cục, không timer trùng, resume vẫn refresh. `lib/features/`
        không còn `DateTime.now()`. **Deck-golden hardening:** boundary đã trôi
        qua khi emission được xử lý (`delay <= 0`) nay refresh ngay một lần
        (guard chống lặp), không còn bỏ qua tới lần resume.
  - [x] `lib/features/**` không import `lib/app/**` — cưỡng chế bằng
        `check_architecture.sh` rule 4b **và** `architecture_boundary_test.dart`.
  - [x] Guard command/query chạy trên **AST** (`package:analyzer`), không regex:
        comment và string literal không còn là subject. Phân biệt được ba loại
        notifier thay vì hai.
  - [x] Riverpod pin theo major thực tế trong `pubspec.lock`; `>=3.0.0` (resolve
        được nhưng không chặn trên) vẫn bị chặn.
  - [x] Mọi gate chạy trên CI, `pull_request` + `push main`, kèm phát hiện
        generated-code và **in số đã quét**; 0 scope là lỗi.
  - [x] Mọi guard mới hoặc đã sửa đều **fault-inject**: tạo vi phạm → đỏ → hoàn
        nguyên → xanh. 24 lần tiêm, ghi trong báo cáo cuối.
  - [x] Tài liệu khớp code: không còn tuyên bố "hai fact arrive together", không
        còn "timer chu kỳ đã bị loại vì resume bắt được cùng boundary", không còn
        "repo này không được sửa rule của guard".
  - [x] 844 test pass (từ 788), `flutter analyze` 0 issue, guard 0 violation,
        `check_docs.sh` xanh, build web xanh.

**Ba khiếm khuyết mà chính công việc này phát hiện, không nằm trong kế hoạch:**

1. **`nextDueAt` về sai timezone.** Drift đọc `DateTime` đã lưu bằng
   `fromMillisecondsSinceEpoch`, trả về giá trị **local**. Đúng thời điểm, sai zone
   — và chỉ lộ ra vì test mới so sánh instant thay vì so sánh hành vi.
2. **`check_architecture.sh` exit 0 khi thiếu `lib/`.** Trung thực trước khi
   project tồn tại; là một guard **xanh** cho một working directory sai sau đó.
   `pubspec.yaml` nay phân biệt hai trường hợp.
3. **Ba guard báo sai trên chính phần văn xuôi giải thích chúng.** Cả ba sửa ở
   *rule*, không phải bằng cách viết lại comment cho lọt — xem AD-13.

**Đánh đổi đã nhận:** khai báo provider trong feature đổi lỗi compile thành
`StateError` lúc đọc đầu tiên. Bị chặn bằng hai test và bằng việc lần đọc đầu tiên
xảy ra ngay khi screen đầu của feature mount.

**Next task: M4.11 · Card management full-stack** — giờ mới an toàn để clone.

### M4.10c · Deck UI redesign và hợp nhất hai màn deck-list

- **Status:** done
- **Goal:** Hai việc, làm liên tiếp. (1) Redesign Deck UI theo reference nhưng
  **giữ nguyên MemoX design system** — reference chỉ dùng để học bố cục và
  hierarchy, mọi giá trị phải resolve về token đã có. (2) Sau khi redesign xong
  mà hai màn **vẫn** khác nhau, hợp nhất `RootDeckListScreen` và
  `DeckDetailScreen` thành **một** `DeckListScreen(parentDeckId?)`.
- **Scope:** `features/deck` (mọi tầng), `core/theme`, `core/database/queries/
  deck.drift`, `shared/widgets`, `l10n`, visual audit companion, hai rule của
  guard.
- **Out of scope:** luật nghiệp vụ (không BR/UC nào đổi), scheduler, định nghĩa
  "đến hạn" (BR-22), navigation behaviour, Card (M4.11), bottom navigation.
- **Dependencies:** M4.10b (Deck Golden Feature)
- **Checklist phases:** 8, 11, 14
- **Tests required:** shared component (`mx_pill_button_test.dart`,
  `mx_card_test.dart` — semantics `isButton` phải assert, `InkWell` **không** tự
  đóng góp cờ đó); presentation thuần (`deck_list_view_test.dart` — filter/sort
  là transform thuần trên một snapshot, không phải query thứ hai); data trên
  SQLite thật (`deck_level_read_test.dart` **đếm câu SQL** — 3 con có subtree
  riêng vẫn phải là **một** statement; `deck_level_parity_test.dart` — hai
  aggregate phải khớp ở mọi độ sâu); visual audit strict một companion, 8 state ×
  2 theme.
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/deck-ui-redesign-report.md`
- **Output:** `shared/widgets/mx_pill_button.dart`,
  `core/theme/app_button_themes.dart`,
  `core/database/queries/deck.drift` (`childDeckLevel`),
  `domain/models/deck_summary_model.dart`,
  `domain/models/deck_list_snapshot_model.dart`,
  `domain/usecases/watch_deck_list_use_case.dart`,
  `presentation/controllers/deck_list_controller.dart`,
  `presentation/controllers/deck_deletion_impact_controller.dart`,
  `presentation/states/deck_list_view_state.dart`,
  `presentation/widgets/deck_list_toolbar_widget.dart`,
  `presentation/widgets/deck_level_error_widget.dart`,
  `presentation/screens/deck_list_screen.dart`,
  `test/features/deck/data/deck_level_parity_test.dart`,
  `test/visual_audit/screens/features/deck/screens/deck_list_screen_visual_audit_test.dart`
- **Acceptance criteria:**
  - [x] Không một màu, cỡ chữ, bo góc hay khoảng cách nào **hardcode** trong
        `features/deck/presentation/` — `grep` `Color(0xFF`, `Colors.`,
        `TextStyle(`, `BoxShadow(` rỗng.
  - [x] Shared widget mới (`MxPillButton`) có **≥2 caller thật** và test riêng;
        `MxCard`/`MxContentShell` được **mở rộng** chứ không bị copy.
  - [x] Không dead control: filter và sort là transform thật; toolbar **ẩn hẳn**
        khi không có gì để lọc hay sắp.
  - [x] **Một** `DeckListScreen` cho mọi cấp. `parentDeckId == null` là root;
        không nhánh nào khác rẽ theo độ sâu.
  - [x] Deck con mang **đúng ba fact** mà deck gốc mang — tổng thẻ cả subtree, số
        đến hạn, scheduler resolve qua `root_deck_id` (BR-06).
  - [x] Một cấp = **một** statement, kể cả với aggregate đệ quy — đo bằng
        `QueryInterceptor` thật, không phải khẳng định trong prose.
  - [x] Hai aggregate (flat ở root, đệ quy ở dưới) **khớp nhau**:
        `subtree(D) == direct_cards(D) + Σ subtree(con của D)`, kiểm ở root, ở
        branch, ở leaf, trên hai cây, và **sau một lần move**.
  - [x] Render cả hai cấp light/dark: giống hệt nhau trừ tiêu đề, nút back, và
        action menu của deck đang mở.
  - [x] 892 test pass (từ 880), 97 visual audit state PASS, `flutter analyze` 0
        issue, mọi guard 0 violation, `check_docs.sh` xanh.

**Cái mà chỉ việc render mới tìm ra, code review thì không:**

1. **Floating action có hai glyph** — `add` ở root, `create_new_folder_outlined`
   ở trong deck. Một hành động vẽ hai kiểu, đúng trên hai màn mà task này tồn tại
   để làm cho giống nhau.
2. **Loading và error frame làm mất tiêu đề.** Viết vậy vì tên deck *nằm trong*
   dữ liệu chưa về — đúng khi ở trong deck, sai ở root nơi tiêu đề là hằng số.

**Cái mà chỉ strict visual audit mới tìm ra:** `primary` (#5656C9) trên
`surfaceMuted` (#292D42) chỉ đạt **2,31:1** so với sàn 3,0 cho icon 24px, chỉ ở
dark. Nhìn bằng mắt thấy ổn. Đã đổi sang cặp container Material 3
`primaryContainer`/`onPrimaryContainer` = **8,96:1** — cặp đó *bảo đảm* tương phản
theo cấu trúc, còn `primary` là màu nền, không có gì hứa nó đọc được *trên* một
surface khác.

**Hai rule của guard sửa ở chính rule, không sửa call site:**
`memox.state_management.no_generated_ref_subclass` khớp `WidgetRef ref` — một type
Riverpod 3 còn dùng và là kiểu tham số của **mọi** `Consumer` builder; và
`MX-VIS-001` tự khẳng định đường dẫn companion theo tên màn hình cũ.

**Đánh đổi đã nhận:** `rootDeckSummaries` **giữ nguyên** thay vì gộp vào query đệ
quy. Root có `root_deck_id` nên aggregate phẳng của nó đã là covering-index; gộp
lại là trả tiền cho một lần đi cây ở nơi một cột đã trả lời. Cái giá là **cùng một
con số được tính hai cách** — nên `deck_level_parity_test.dart` tồn tại, vì lệch
nhau thì trên màn hình không nhìn ra được.

**Next task: M4.11 · Card management full-stack.**

### M4.10d · Breadcrumb điều hướng cho màn hình deck-list đệ quy

- **Status:** done
- **Goal:** Màn hình deck-list là một màn đệ quy tới 10 cấp (BR-55), nhưng ở cấp
  sâu người dùng chỉ có nút Back và tiêu đề — không biết mình đang ở đâu và không
  có cách nào nhảy về giữa chừng. Thêm breadcrumb, **làm shared widget** theo yêu
  cầu của chủ dự án.
- **Scope:** `shared/widgets/mx_breadcrumb.dart`,
  `core/database/queries/deck.drift`, `features/deck` (domain model, mapper,
  presentation), `l10n`, visual audit companion, `deck_audit_allowances.dart`.
- **Out of scope:** luật nghiệp vụ (không BR/UC nào đổi), scheduler, due-count,
  route table (breadcrumb dùng đúng route `deckDetail` đã có), Card (M4.11).
- **Dependencies:** M4.10c (một màn hình cho mọi cấp)
- **Checklist phases:** 8, 11, 14
- **Tests required:** shared component (`mx_breadcrumb_test.dart` — bước cuối
  **không** phải control, path 10 cấp không tràn ở 320×568 textScaler 2.0, mỗi
  bước tappable tự khai báo là button, separator không được đọc); mapper
  (`deck_mapper_test.dart` — thứ tự theo `distance` chứ không theo thứ tự mảng,
  JSON hỏng trả path rỗng chứ không giết cả level, entry hỏng bị bỏ còn lại sống);
  data trên SQLite thật (`deck_ancestry_read_test.dart` — độ sâu 1..10, nhánh
  anh em không lọt vào, rename/move viết lại chain, tên có dấu ngoặc kép và dấu
  phẩy đi qua được); presentation (breadcrumb ẩn ở cấp 1–2, tap ancestor điều
  hướng đúng route); visual audit strict phải **đo thật** màu của breadcrumb.
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/deck-ui-redesign-report.md`
- **Output:** `lib/shared/widgets/mx_breadcrumb.dart`,
  `lib/features/deck/domain/models/deck_path_segment_model.dart`,
  `lib/features/deck/presentation/widgets/deck_path_widget.dart`,
  `test/shared/widgets/mx_breadcrumb_test.dart`,
  `test/features/deck/data/deck_ancestry_read_test.dart`,
  `test/features/deck/presentation/deck_move_picker_test.dart`
- **Acceptance criteria:**
  - [x] Chain đến **cùng một statement** với level (AD-13). Rename một ancestor
        phải đổi cả tiêu đề lẫn breadcrumb trong **một** frame — đo bằng đếm câu
        SQL qua `QueryInterceptor` thật, không phải khẳng định trong prose.
  - [x] Breadcrumb **ẩn hẳn** ở cấp 1 và cấp 2. Ở cấp 2 bước duy nhất phía trên
        là danh sách deck, mà Back và tab Decks đều tới trong một lần chạm — thêm
        crumb ở đó là control thứ ba làm cùng một việc.
  - [x] Bước cuối (deck đang mở) **không** tappable.
  - [x] Path 10 cấp không tràn ở 320×568 với textScaler 2.0 — cuộn ngang, không
        wrap và không thu gọn giữa (thu gọn sẽ giấu đúng những bước người dùng mở
        breadcrumb để tìm).
  - [x] Shared widget **không** import domain, không import Riverpod, không tự
        đọc ARB; `DeckPathWidget` là adapter feature-local.
  - [x] Visual audit strict **đo màu breadcrumb thật** — state `level_loaded`
        mang chain hai bước, `breadcrumbSteps` khai báo số ink host chính xác.
  - [x] 930 test pass (từ 892), `flutter analyze` 0 issue, mọi guard 0 violation,
        `check_docs.sh` xanh.

**Ba shape đã thử cho chain, hai bị loại kèm lý do đo được:**

1. **Join `ancestry` vào các dòng con** — typed đầy đủ, nhưng nhân số dòng lên
   theo độ sâu: 100 con ở cấp 5 thành 400 dòng. M4.10 đã đo rằng cái tốn trên UI
   thread là **số dòng** vượt biên isolate, không phải thời gian SQL.
2. **`UNION ALL` trả ancestor thành dòng phụ** — vừa rẻ vừa typed, nhưng drift
   **không** expand `table.**` trong compound select: nó nhả nguyên chữ
   `parent.**` vào chuỗi SQL, sinh result class chỉ có cột discriminator, và
   **không báo lỗi**. Xác minh trên drift 2.34 trước khi chọn cách khác.
3. **Một cột JSON scalar**, lặp lại mỗi dòng đúng như `nextDueAt` — chọn cách này.

Đó là một **lỗ untyped có chủ ý** trong file mà cả điểm mạnh là drift type-check
mọi cột lúc build. Nó bị bịt ở mapper: `deckPathFromJson` là thứ duy nhất nhìn
thấy chuỗi, và decode là **total** — JSON hỏng trả path rỗng chứ không giết cả
level, vì breadcrumb là chrome còn số liệu, danh sách và tiêu đề trong cùng lần
đọc thì không việc gì.

**Footgun của drift, ghi lại vì mất thời gian tìm:** một dấu `;` **trong comment
`--`** làm drift cắt statement sớm. Lỗi báo ở label của query *kế tiếp* với nội
dung `Expected a sql statement here`, và nó là **warning** chứ không phải error —
build vẫn xanh, method sinh ra thì không tồn tại.

**Đánh đổi đã nhận:** shared widget này ship với **một** caller, lệch với luật
của chính dự án ("shared widget mới cần ≥2 caller thật"). Chủ dự án yêu cầu rõ
làm nó thành shared widget; caller thứ hai đã có tên là card list ở M4.11, nằm
dưới cùng cây và cần đúng path đó. Ghi lại chỗ lệch thay vì giả vờ đã đạt luật.

**Hạn chế còn lại:** path sâu bị cắt ở mép phải không có fade hay mũi tên báo còn
cuộn được — gradient là cách sửa thông thường nhưng không có token nào cho nó, và
thêm shader hardcode để chiều một edge case là đúng thứ thiết kế này đã từ chối ở
chỗ khác.

**Next task: M4.11 · Card management full-stack.**

### M4.10e · Bốn ghi nhận review về thị giác — đo trước, sửa sau

- **Status:** done
- **Goal:** Đóng bốn ghi nhận review: (1) light mode mất chiều sâu, (2) card ba
  dòng với dòng scheduler thừa, (3) "Nothing due" nhấn sai chỗ, (4) breadcrumb
  lặp tiêu đề và bottom nav hai item dạt hai mép. **Đo trước khi sửa** — hai
  trong bốn cái đổi kết luận sau khi có số.
- **Scope:** `core/theme/app_colors.dart`, `shared/widgets/mx_navigation_bar.dart`,
  `shared/widgets/mx_breadcrumb.dart`, `features/deck/presentation` (tile, path
  widget, labels), `l10n`, golden.
- **Out of scope:** luật nghiệp vụ, query, navigation behaviour, dock FAB vào
  bottom bar (xem phần từ chối bên dưới).
- **Dependencies:** M4.10d (breadcrumb)
- **Checklist phases:** 8, 14
- **Tests required:** theme (`app_theme_test.dart` — biên card phải nhìn thấy
  được **và hai mode phải lệch nhau dưới 0,25**, vì chỉ đặt sàn thì light lại
  trôi về hairline trong khi dark vẫn mạnh); presentation (nhãn scheduler dạng
  ngắn, breadcrumb **không** chứa deck đang mở); shell (ba test layout hiện có
  phải vẫn xanh — chúng bắt được lỗi `Center`/`Align` ngay).
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/deck-ui-redesign-report.md`
- **Output:** `borderSubtleLight` = `#BEC0C3`, `schedulerShortLabel`,
  `_kWidthPerDestination`, `test/features/deck/presentation/deck_path_test.dart`
- **Acceptance criteria:**
  - [x] Biên card **nhìn thấy được ở cả hai mode và mạnh ngang nhau** — light
        1,82:1 so với card, dark 1,82:1; chênh lệch có test chặn dưới 0,25.
  - [x] Card còn **hai dòng**: tên, rồi một dòng tổng hợp
        `46 cards · 5 due · 8 boxes`.
  - [x] Màu và độ đậm chỉ dành cho trạng thái **cần hành động**. "Nothing due"
        về xám như các số bên cạnh.
  - [x] Breadcrumb chỉ liệt kê tổ tiên; deck đang mở không có trong đó vì tiêu đề
        ngay trên đã nói.
  - [x] Hai item của bottom nav nằm hai bên tâm, và giới hạn **tự vô hiệu** khi
        thêm tab thứ tư.
  - [x] 931 test pass, 97 visual audit state, 19 golden cập nhật và đã xem lại,
        `flutter analyze` 0 issue, mọi guard 0 violation.

**Hai kết luận đổi sau khi đo:**

1. **Card *đã có* border 1px** — cái thiếu là border **nhìn thấy được**: 1,40:1 so
   với card ở light, trong khi dark là 1,82:1. Một cơ chế, hai độ mạnh. Và **giá
   trị được đề xuất (`#E5E7EB`) sẽ làm tệ hơn**: nó đo được 1,14:1 so với nền
   trang, trong khi `#D7DAE3` đang dùng đã là 1,28:1 — nó *sáng* hơn chứ không
   tối hơn.
2. **Amber trên nền trắng không fail 4,5:1** — nó là **5,41:1**, và màu xanh lá nó
   thay thế là 5,91:1. Cả hai đều đạt. Lý do test tương phản của theme chưa từng
   báo là vì chúng chưa từng sai. Phần đúng của ghi nhận là **nhấn mạnh**, không
   phải tương phản: `success` ở `w600` đặt thứ to tiếng nhất của card lên đúng cái
   fact không đòi hành động nào.

**Cái chỉ render mới tìm ra:** `MxBreadcrumb` tô bước **cuối danh sách** theo kiểu
"bạn đang ở đây". Điều đó trùng với "bước không có `onTap`" chỉ khi mọi caller kết
thúc path bằng deck hiện tại. Ngay khi deck list bỏ bước đó, tổ tiên cuối cùng trở
thành một link chạy được nhưng được vẽ như thể không phải link. Luật nay suy ra từ
`onTap`, chỗ nó vốn thuộc về.

**Luật của chính dự án bắt được một lựa chọn sai:** ứng viên đầu cho border light
là `#B9BECD`, và `app_palette_test.dart` từ chối — nền sáng có ngân sách chroma, và
giá trị đó tiêu nhiều hơn cả chính trang nền.

**Từ chối, kèm lý do:** dock FAB vào bottom bar. Việc đó thay `NavigationBar` bằng
`BottomAppBar` (mất indicator và label semantics của M3) và đẩy floating action từ
màn hình vào shell — tức `features/` phải đưa một nút cho `app/`, đúng chiều phụ
thuộc mà AD-13 tồn tại để chặn.

**Next task: M4.11 · Card management full-stack.**

### M4.10f · Colour-system conformance audit toàn app (seed / role / scope)

- **Status:** done
- **Goal:** Kiểm kê **mọi** chỗ dùng màu trong `lib/`, phân loại theo mô hình
  seed / role / scope, và ra báo cáo vi phạm kèm migration map. **Không sửa một
  màu nào** — đo, phân loại, báo cáo. Sau đó bổ sung vào visual audit những quy
  tắc đúng-hôm-nay để chúng không trôi mất.
- **Scope:** `design_audit/` (output), `test/design_audit/` (harness),
  `test/visual_audit/color_system_rules_test.dart` (quy tắc mới).
- **Out of scope:** mọi thay đổi màu. Bảy đề xuất trong migration map **chưa
  được áp dụng** và hai trong số đó được đánh dấu là quyết định thiết kế chứ
  không phải sửa lỗi.
- **Dependencies:** M4.10e
- **Checklist phases:** 8, 14
- **Tests required:** `flutter test test/design_audit/` sinh đủ 7 file output;
  `test/visual_audit/color_system_rules_test.dart` (5 quy tắc + 1 coverage
  check), **mỗi quy tắc phải fault-inject**.
- **Editable documents:** `docs/wbs.md`
- **Output:** `design_audit/{tokens_current,usage_inventory,violations,
  perceptual_checks,role_families}.json`,
  `design_audit/{color_system_report,migration_map}.md`,
  `test/visual_audit/color_system_rules_test.dart`
- **Acceptance criteria:**
  - [x] Quét bằng **AST** (`package:analyzer`), không grep — màu trong doc
        comment không phải một site, màu trong biểu thức điều kiện thì phải là.
  - [x] Giá trị resolve theo **`ThemeData` đã build**, không theo `AppColors`:
        `ColorScheme.fromSeed` điền role rồi app ghi đè, chỉ theme mới nói cái gì
        thật sự ship.
  - [x] Không hàng nào chứa tên token chưa resolve — hoặc là hex, hoặc là
        `unresolvable` **kèm lý do**.
  - [x] 112 file, 160 site, 17 vi phạm, mỗi hàng có target token cụ thể.
  - [x] Năm quy tắc mới vào visual audit (MX-VIS-002), **cả năm đã fault-inject**:
        tiêm → đỏ → hoàn nguyên → xanh.
  - [x] 943 test pass, `flutter analyze` 0 issue, mọi guard 0 violation.

**Kết quả chính (đo được, không phải cảm nhận):**

- **V1 lớn nhất:** ở light, `surface` là `#FFFFFF` **không có hue nào cả** — cùng
  với `surfaceBright`, `surfaceContainerLowest`, `surfaceElevated`, card, dialog
  và bottom sheet. Trang thì có tint (`#F4F5F8`, hue 225°, lệch seed 15°) nhưng
  cái nằm *trên* trang thì không. Đây chính là "light mode mất depth" của M4.10e
  nhìn từ phía khác.
- **V6:** `shadow`/`scrim` mang seed ở light (`#0B0C18`) nhưng là `#000000` ở
  dark — hai cơ chế đội một cái tên.
- **V2 và V4 = 0, và đó là kết quả đo chứ không phải ô chưa tick:** mọi role có
  fill và container nằm trong 2° cùng một hue.
- **Lỗ của mô hình:** `success`, `warning`, `info` chỉ có fill — không container,
  không border, không focus.

**Cái mà việc tính toán bác bỏ:**

1. **Ceiling 1.6:1 của brief cho border** báo "too-heavy" ở **cả hai mode** (light
   1.82/1.67, dark 1.82/2.12) — nó không bắt được một regression của light, nó
   bất đồng với depth model của app ở cả hai. App này cố ý **không dùng shadow**
   và surface chỉ cách trang 1.09:1 (light) / 1.17:1 (dark), nên border là *cue
   duy nhất*; một giá trị nằm dưới ceiling đó là một biên không nhìn thấy.
2. **Ba giá trị đề xuất đầu tiên tôi tự tính bằng tay đều sai** (`#FCFCFE`,
   `#BFC1C9`, `#050414`). Giải lại bằng ràng buộc cho ra `#FCFCFE`, `#BFBFCB`,
   `#04040B` — và quan trọng hơn, nó **bác bỏ luôn khẳng định của chính bản nháp**
   rằng "luật seed và ngân sách chroma kéo ngược nhau": `#BFBFCB` thoả cả ba ràng
   buộc cùng lúc (hue 240°, chroma 0.047, tương phản với card **1.82 y hệt hiện
   tại**). Nghĩa là 24° lệch seed mà M4.10e tạo ra là **tránh được**, không phải
   bắt buộc.
3. **Fix V1 cho `surface` có giá của nó:** tint seed vào trắng làm card **tối đi**
   nên khoảng cách card↔trang tụt từ 1.090:1 xuống 1.064:1. Đóng V1 lớn nhất
   nhưng làm hẹp đúng cái bậc surface vốn đã quá nhỏ. Ghi rõ trong migration map
   thay vì giấu.

**Quy tắc mới vào visual audit (MX-VIS-002) — chỉ những cái đúng hôm nay:** R1
không dùng `Colors.*` (trừ `transparent`), R2 literal màu chỉ nằm ở file khai
báo (miễn trừ **theo cấu trúc**: file chỉ import `widgets.dart` thì không có
`Theme.of` để gọi), R3 mỗi role trong 5°, R4 neutral có hue không lệch seed quá
25°, R5 một token không được đục ở mode này và trong suốt ở mode kia. Cái mà
audit tìm thấy đang **hỏng** thì nằm ở migration map dưới dạng đề xuất — một
quy tắc đỏ ngay khi thêm vào là một suite đỏ, không phải một tiêu chuẩn.

**Không kiểm chứng được, ghi rõ:** `component-map.json` **không tồn tại** trong
repo này (đã tìm toàn bộ cây trừ `.git`), nên không có mục stale nào để đối
chiếu; và dải `#0B1220` mà brief gọi là "dark surface family" không có trong
codebase — trang dark của app là `#0A082D`. Cả hai giả thuyết seed đều được đo
và lệch nhau 3.2°, nên lựa chọn không đổi kết luận nào.

**Next task: M4.11 · Card management full-stack.**

### M4.10g · Fix những gì audit màu sắc kết luận là lỗi, và đưa check vào harness

- **Status:** done
- **Goal:** Chủ dự án quyết định **app cần độ nổi để phân biệt element** — bác bỏ
  tiền đề "flat by design" mà hai milestone trước đã trích như một luật. Từ đó:
  phân loại lại 17 finding của M4.10f thành *lỗi* và *quyết định thiết kế*, đưa
  check cho phần đáng fix vào MX-VIS-002, **chạy cho đỏ để nó tự liệt kê chỗ mắc
  lỗi**, rồi mới fix.
- **Scope:** `lib/core/theme/app_colors.dart`, `app_theme.dart`,
  `app_button_themes.dart`, `lib/app/error_screen_widget.dart`,
  `lib/shared/widgets/mx_card.dart`, harness audit, MX-VIS-002.
- **Out of scope:** bật shadow thật (cần Elevation token và một vòng đo riêng),
  và `surface` trắng thuần — vẫn là quyết định thiết kế đang mở.
- **Dependencies:** M4.10f
- **Checklist phases:** 8, 14
- **Tests required:** R6/R7/R8 mới, **cả ba phải fault-inject**; toàn bộ suite;
  golden diff phải được xem lại từng cái.
- **Editable documents:** `docs/wbs.md`,
  `design_audit/color_system_report.md`
- **Output:** `shadowDark`/`scrimDark` = `#04040B`, `disabledSurfaceTint()`,
  `_FallbackPalette` trong error screen, `test/design_audit/audit_role_steps.dart`
- **Acceptance criteria:**
  - [x] Ba rule mới **được viết trước khi fix** và chạy cho đỏ, output tự liệt kê
        chính xác file:line mắc lỗi.
  - [x] `shadow`/`scrim` dark suy từ seed — cơ chế đối xứng hai mode (R6).
  - [x] Fill và border không còn translucent tại điểm vẽ (R7).
  - [x] Màn hình lỗi đọc `PlatformDispatcher.platformBrightness` (R8).
  - [x] Cả ba rule fault-inject: tiêm → đỏ → hoàn nguyên → xanh.
  - [x] 946 test pass, 4 golden đổi và đã xem lại, mọi guard 0 violation.

**Ba lỗi của chính harness mà việc fault-inject phát hiện:**

1. **R8 pass khi bị tiêm.** Nó dùng `source.contains('platformBrightness')`, và
   khi xoá code thì chữ đó vẫn còn trong comment giải thích chính nó. Đúng cái
   bẫy ba guard khác của dự án đã dính ở M4.10b. Đã chuyển sang AST.
2. **Path chuẩn hoá rỗng.** `replaceAll(r'', '/')` — mất backslash lúc soạn — nên
   trên Windows không file nào khớp và hàm luôn trả về "không tìm thấy". Guard
   xanh vì không quét gì.
3. **Scanner bỏ sót ~90 site.** Parse là *unresolved*, nên `Color(0x...)` **không
   có `const`/`new`** được phân tích thành lời gọi hàm chứ không phải khởi tạo
   đối tượng. Bản audit M4.10f đã merge vì thế under-report: **158 site báo cáo,
   thật ra là 244**. Chỉ lộ ra vì một lần tiêm từ chối đỏ.

**Điều audit tự sửa về chính nó:** `usesShadow` từng là literal `false` em gõ tay
trong file mà toàn bộ ý nghĩa là "số liệu được đo". Nay là phép đo thật
(`cardTheme.elevation` + số site `BoxShadow`).

**Đánh đổi đã nhận — precompute buộc phải chọn một nền.** `disabledSurfaceTint`
blend trên `surface`, nên đúng ở nơi trạng thái disabled thật sự xuất hiện (form
sheet, dialog) và hơi sáng ở nút disabled đặt thẳng trên page: light `#E3E3E6`
trên card so với `#D9DADF` trên page. **Chính khoảng cách đó là finding** — một
token đang render ra hai màu tuỳ thứ nằm phía sau, và không ai chọn cái nào. Bốn
golden đổi là cách nó lộ ra.

**Không fix, và ghi rõ vì sao:** `surface` trắng thuần ở light (V1 🔴 lớn nhất) —
card trắng là lựa chọn hợp lệ, và đã đo được rằng tint seed vào làm khoảng cách
card↔page tụt **1.090 → 1.064**, tức là fix nó làm depth *tệ đi*. Để mở tới khi
có shadow thật.

**Thứ tự cho việc bật elevation, chưa làm:** tạo Elevation token → bật shadow ở
mức thấp nhất → đo lại card↔page → *chỉ khi đó* mới hạ border từ 1.82 về vùng
1.4–1.6. Hạ border trước là đổi một cái khung quá đậm lấy không có ranh giới nào.

**Next task: M4.11 · Card management full-stack.**

### M4.10h · Elevation thật: token, shadow ở light, và phép đo thay cho luật cũ

- **Status:** done
- **Goal:** Thực hiện quyết định "app cần độ nổi để phân biệt element". Tạo
  Elevation token mà `docs/checklist.md` yêu cầu từ đầu và chưa ai làm, bật
  shadow, đo lại, rồi hạ border xuống mức mà nó thật sự cần.
- **Scope:** `core/theme/app_elevation.dart` (mới), `app_colors.dart`,
  `shared/widgets/mx_card.dart`, `app_theme_test.dart`, harness audit.
- **Out of scope:** `surface` trắng thuần ở light — vẫn là quyết định thiết kế
  đang mở; sau khi có shadow nó càng ít cấp bách.
- **Dependencies:** M4.10g
- **Checklist phases:** 7.1 (design token), 8, 14
- **Tests required:** `app_elevation_test.dart` mới (thang tăng dần, light vẽ /
  dark không, **và phép đo chứng minh vì sao dark không**); `app_theme_test.dart`
  viết lại để đo *độ nổi* thay vì *tương phản border*; cả hai phải fault-inject.
- **Editable documents:** `docs/wbs.md`,
  `design_audit/color_system_report.md`
- **Output:** `lib/core/theme/app_elevation.dart`,
  `test/core/theme/app_elevation_test.dart`, `borderSubtleLight` = `#D2D2DD`
- **Acceptance criteria:**
  - [x] Elevation là **token** (`AppElevation` — thang dp), tách khỏi cách nó
        render (`shadowsFor`), nên dark từ chối shadow mà không từ chối thang.
  - [x] Light vẽ shadow, dark không — **đo được**, không phải chọn.
  - [x] Alpha shadow được **giải ra** chứ không chọn: light 7.62 L\* so với dark
        7.70 L\*, lệch 0.08.
  - [x] Border light hạ 1.82 → **1.50**, vào trong band 1.6 của brief.
  - [x] `app_theme_test.dart` đo **độ nổi của card** thay vì tương phản border.
  - [x] Cả hai test mới fault-inject.
  - [x] 946 test pass, 15 golden light đổi và đã xem lại, mọi guard 0 violation.

**Vì sao dark không vẽ shadow — con số, không phải sở thích:**

| | shadow alpha 0.10 | bậc surface sẵn có |
|---|---|---|
| Light | ΔL\* **8.04** | ΔL\* 3.46 |
| Dark | ΔL\* **0.26** | ΔL\* 7.70 |

Trang dark nằm ở đáy thang lightness (L\* 3.86) nên không còn chỗ để tối đi —
ngay cả alpha 0.70 cũng chỉ mua được 2.04. Material 3 bỏ shadow ở dark vì đúng lý
do đó. `app_elevation_test.dart` **dẫn lại phép đo này** thay vì trích nó, nên nếu
palette đổi tới mức shadow dark trở nên thấy được thì test đỏ và quyết định được
xem lại — điều một comment không bao giờ làm được.

**Luật cũ đã sai và đã bị thay:** `app_theme_test.dart` từng khẳng định *tương
phản border* phải khớp giữa hai mode. Đúng khi border là cue duy nhất; sai ngay
khi light có shadow, vì nó ép light giữ một cái khung nó không còn cần. Nay nó đo
**độ nổi tổng của card** — mỗi mode tự do dựng từ thứ nó có.

**Ba lần đo lại vì tính sai:**
1. Phép đo đầu lấy *max* của các cue — border dark luôn thắng và báo 26.8 L\* cho
   một card chỉ nổi 7.7. Đại lượng đúng là bậc surface cộng đóng góp của shadow.
2. Alpha đầu tiên (0.12) cho light 13.28 so với dark 7.70 — card light nổi bồng
   bềnh. Giải ngược từ 7.70 ra alpha **0.05**.
3. Scanner của audit báo `boxShadowSitesInLib: 0` trên một file đang vẽ shadow:
   `BoxShadow(...)` không có `const` cũng bị parse thành lời gọi hàm, đúng lỗi đã
   sửa cho `Color` ở M4.10g nhưng chỉ sửa riêng cho `Color`. Nay nhận diện chung
   cho mọi constructor viết hoa không có target.

**Next task: M4.11 · Card management full-stack.**

### M4.10i · Đóng dứt điểm mọi finding của audit màu sắc

- **Status:** done
- **Goal:** Đưa số vi phạm của audit về **0**, và khoá phần đã đóng bằng rule để
  không tái phát.
- **Scope:** `core/theme/app_colors.dart`, `app_elevation.dart`,
  `app/error_screen_widget.dart`, `app/mobile_frame_widget.dart`,
  `shared/widgets/mx_action_sheet.dart`, `app_palette_test.dart`, MX-VIS-002.
- **Out of scope:** không có. Đây là lượt đóng nốt.
- **Dependencies:** M4.10h
- **Checklist phases:** 7.1, 8, 14
- **Tests required:** R9 mới (**mọi neutral phải mang hue của seed**), fault-inject;
  `app_palette_test.dart` sửa ngưỡng ladder theo mode kèm lý do đo được.
- **Editable documents:** `docs/wbs.md`,
  `design_audit/color_system_report.md`
- **Output:** `surfaceLight` = `#FBFBFE`, `surfaceElevatedLight` /
  `surfaceBrightLight` / `surfaceContainerLowestLight` = `#FCFCFE`,
  `AppColors.webLetterbox`, `test/visual_audit/color_source_rules_test.dart`
- **Acceptance criteria:**
  - [x] **0 vi phạm** trong `design_audit/violations.json`.
  - [x] **Không neutral nào không mang hue**, ở cả hai mode — khoá bằng R9.
  - [x] Tổng độ nổi của card giữ nguyên: **7.75 L\* (light) so với 7.70 (dark)**.
  - [x] R9 fault-inject: card về trắng thuần → đỏ.
  - [x] 954 test pass, golden light đã xem lại, mọi guard 0 violation.

**Một kết luận trước đó của chính agent bị bác bỏ.** Ở M4.10g em xếp 6 literal
trong `error_screen_widget.dart` là "mirror không tránh được", lập luận rằng file
không đọc được `Theme` thì không có token nào với tới. Sai: `Theme.of` cần một
element tree, còn `AppColors` là **class hằng số biên dịch** — import thẳng được
từ bất cứ đâu. Màn hình lỗi nay dùng đúng token của app, và một lần đổi palette
sẽ tới được nó.

**Xung đột thật giữa hai luật, và cách xử.** Tint seed vào card làm card **tối
đi**, nên bậc ladder light tụt 3.46 → 2.15 và phá luật "mỗi bậc ≥ 3 L\*" có từ
M3.5b. Không có giá trị page nào giữ được cả hai bậc — ladder light chỉ có 5.31
L\* để chia. Cách xử: **luật ladder là luật của một mode không có cue nào khác**,
đúng loại luật đã lỗi thời như "border phải khớp hai mode". Light nay là 2.0,
dark giữ 3.0, và cái không được phép nhúc nhích — tổng độ nổi — vẫn bị chặn ở
`app_theme_test.dart`. Phần ladder nhường lại chính là phần shadow gánh thêm
(alpha 0.05 → 0.07).

**False positive cuối cùng, đã sửa ở rule chứ không ở call site:** audit gắn V5
cho `scheme.shadow.withValues(...)` trong `app_elevation.dart`. Nhưng shadow
**bắt buộc** trong suốt — một shadow đặc là một khối màu. Miễn trừ giống
`overlayColor`, với lý do ghi kèm.

**Next task: M4.11 · Card management full-stack.**

### M4.10j · Design-system showcase (dev-only)

- **Status:** done — **superseded by M4.10k** trong cùng PR, trước khi merge:
  chủ dự án chọn Widgetbook để dễ maintain. Màn in-app, route `/dev/design-system`,
  cổng `includeDevRoutes` và ngoại lệ trong `no_hardcoded_strings_test` đều đã
  gỡ; nội dung demo (token gallery + component state) chuyển thành use-case
  Widgetbook. Ghi chép dưới đây giữ nguyên làm lịch sử quyết định.
- **Goal:** Một màn duy nhất render **mọi** design token kèm giá trị đã resolve
  và **mọi** shared component `Mx*` theo từng state, để review một thay đổi ở
  `core/theme/` hoặc `shared/widgets/` không phải đi săn từng màn production
  đang dùng nó.
- **Scope:** route `/dev/design-system` gate theo build mode; màn showcase với
  hai tab Tokens/Components; toggle light↔dark và text scale 1.0/1.5/2.0 **tại
  chỗ** (không đụng cài đặt hệ thống, không đổi theme của app).
- **Out of scope:** Widgetbook/Storybook (một app catalog riêng chưa đáng chi
  phí ở quy mô 13 component); entry point trong product UI; golden cho màn này
  (`mx_components_golden_test.dart` đã phủ từng component — golden cho màn gộp
  sẽ là ảnh thứ hai của cùng pixel).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/app/dev/` — `design_system_showcase_screen.dart`,
  `token_gallery_widget.dart` + 3 file section token,
  `component_gallery_widget.dart` + 3 file section component,
  `showcase_section_widget.dart`; route trong `app_router.dart` +
  `route_paths.dart`; `test/app/dev/design_system_showcase_screen_test.dart`
  (7 test), `test/app/router/dev_route_test.dart` (2 test).
- **Acceptance criteria:**
  - [x] Tokens tab đọc màu và typography **từ theme đang chạy**
        (`context.colors` / `context.texts` / `context.semanticColors`), không
        đọc thẳng `AppColors` — swatch hiện đúng cái widget product sẽ nhận,
        kèm hex và thông số font (family · sp · weight · line height).
  - [x] Components tab demo 11 component `Mx*` theo state: enabled / disabled /
        loading / error / selected / destructive / submitting; hai component
        không có visual riêng (`MxContentShell`, `MxAsyncView`) có ghi chú
        thay vì bị bỏ sót lặng lẽ.
  - [x] Route chỉ tồn tại khi `includeDevRoutes` (default `kDebugMode`);
        release đi vào 404 — có test cho **cả hai phía** của cổng.
  - [x] Không có gì trong `features/` hay shell trỏ tới màn này; guard, 766
        test, `check_architecture.sh`, `check_docs.sh` đều xanh.
- **Vị trí là quyết định, không phải tiện tay.** `lib/app/dev/` vì đó là kênh
  dev đã có tiền lệ (`MobileFrameWidget` — "not product UI"): ngoài scope
  `ui_surfaces` của guard i18n/token, ngoài `productionScreenRoots` của
  MX-VIS-001 nên không cần audit companion, và `features/` không import được
  nó theo rule 4b. Copy tiếng Anh có chủ đích — nội dung là **định danh code**
  (`MxActionButton`, `primaryContainer`), thứ translator không dịch được;
  `no_hardcoded_strings_test.dart` được nới **đúng một thư mục**
  `lib/app/dev/` kèm lý do, phần còn lại của `lib/app/` vẫn bị kiểm.
- **Demo render inline, không qua `showDialog`/`showModalBottomSheet`.** Route
  pop dựng dưới theme gốc của app nên sẽ bỏ qua toggle light/dark của màn —
  chức năng chính của nó. Giá phải trả: `MxActionSheet` cần một `Material`
  đóng thế làm surface (sheet tự nó không vẽ nền), và phải là `Material` chứ
  không phải `DecoratedBox` — `ListTile` vẽ splash lên Material gần nhất,
  framework assert ngay khi tile nằm trên hộp trang trí thường (bắt được bằng
  test trước khi bắt được bằng mắt, hai lần).
- **`MxListTile` demo nằm trần trên nền scaffold** đúng như row trong product,
  cùng lý do assert ở trên — bọc trong `MxCard` là dựng một ngữ cảnh product
  không hề có.
- **Toggle theme là `Theme` override subtree + `MediaQuery` override cho text
  scale**, đặt **dưới** toolbar: thanh công cụ là dụng cụ đo, gallery là mẫu
  đo. Có test khẳng định app phía trên không đổi brightness khi toggle.
- **Phát hiện phụ (môi trường, không phải code):** `flutter_test_config.dart`
  liệt kê font SDK bằng tên **thường** (`roboto-regular.ttf`) — khớp trên
  Windows/macOS vì filesystem không phân biệt hoa thường, hỏng trên Linux dev
  máy trạm (artifact thật là `Roboto-Regular.ttf`). Chưa sửa trong repo vì CI
  Linux hiện exclude golden; ghi lại đây để lần dựng CI Linux full biết chỗ
  ngã.
- **Dependencies:** M3.4, M3.5, M4.8, M4.8a, M4.8b
- **Tests required:** hai phía của cổng dev route, inventory đủ component ở cả
  hai theme, toggle không rò ra app, text scale cycle 1.0→1.5→2.0→1.0
- **Checklist phases:** 7.3, 7.5

### M4.10k · Widgetbook catalog — thay màn showcase in-app

- **Status:** done
- **Goal:** Cùng nội dung M4.10j nhưng ở dạng chuẩn công nghiệp: mỗi component
  một use-case có **knobs** chỉnh prop lúc chạy, addon light/dark, text scale,
  viewport — chọn theo yêu cầu maintainability của chủ dự án.
- **Scope:** package `widgetbook/` mới (app riêng, web); 3 trang token +
  11 component playground; addon theme dùng **chính**
  `buildLightTheme()`/`buildDarkTheme()` của app; viewport có case
  **Compact 320×568** (M4.8b) không preset nào có sẵn; gỡ toàn bộ M4.10j khỏi
  `lib/app/`, router và test app.
- **Out of scope:** `widgetbook_generator` (codegen thứ hai cho 13 component
  không đáng — cây catalog compose tay trong `main.dart`, đọc được toàn bộ
  trong một file); Widgetbook Cloud; deploy catalog.
- **Editable documents:** `docs/wbs.md`, `.github/workflows/ci.yml`
- **Output:** `widgetbook/{pubspec.yaml, lib/main.dart, lib/support/,
  lib/tokens/ (3 file), lib/components/ (4 file), test/catalog_smoke_test.dart,
  web/, README.md}`; hai step CI mới trong `ci.yml`.
- **Acceptance criteria:**
  - [x] **Package riêng, không phải dependency của app.** `widgetbook` phụ
        thuộc `memox` qua path; pubspec của app không đổi một dòng —
        `dependency_pinning_test` và kỷ luật M2.2 giữ nguyên hiệu lực.
  - [x] Theme addon lấy từ theme builder thật của app, không khai báo lại màu
        — catalog không thể lệch với product.
  - [x] 11 component `Mx*` mỗi cái một playground knobs (variant dropdown từ
        enum thật, enabled/loading/error/selected/submitting, `stringOrNull`
        cho phần tuỳ chọn); 3 trang token đọc ngược từ theme đang chạy.
  - [x] Build web pass (`--no-web-resources-cdn` như CI của app), smoke test
        pass, root `flutter analyze` sạch với catalog trong cây.
- **Font phải copy vào catalog, và đó không phải tiện tay.** Font khai báo
  trong pubspec của một *package* được đăng ký dưới family có prefix
  `packages/<pkg>/`, trong khi theme của memox gọi `Inter` /
  `PlusJakartaSans` trần — nên catalog tự bundle hai file .ttf (kèm OFL) dưới
  đúng tên trần. Không làm vậy thì trang Typography render bằng font fallback,
  tức là trưng bày thứ app không bao giờ vẽ.
- **CI phải biết về package lồng, phát hiện bằng tái hiện chứ không đoán:**
  xoá `widgetbook/.dart_tool` rồi chạy `flutter analyze` ở root — analyzer tạo
  context cho package lồng và báo **117 lỗi** `uri_does_not_exist` khi dep
  chưa resolve. `ci.yml` thêm `pub get` trong `widgetbook/` trước analyze, và
  một step smoke test để catalog hỏng là CI đỏ chứ không phải người mở nó tuần
  sau phát hiện.
- **Demo overlay vẫn render inline** (không `showDialog`/`showModalBottomSheet`)
  vì route pop dựng ngoài subtree use-case, nơi addon theme/viewport không với
  tới; `MxActionSheet` giữ `Material` đóng thế làm surface — cùng lý do
  ListTile/Material đã ghi ở M4.10j.
- **Controller của `MxTextField` sống trong `StatefulWidget` demo riêng**, vì
  controller tạo trong builder của use-case sẽ bị tạo lại (và leak) mỗi lần
  xoay knob.
- **Dependencies:** M4.10j (nội dung demo), M4.8, M3.4, M3.5
- **Tests required:** smoke test catalog build không throw (chạy cả local lẫn CI)
- **Checklist phases:** 7.3, 7.5
- **Bổ sung sau khi đóng task (chủ dự án yêu cầu):** đăng ký Widgetbook thành
  **điều kiện Definition of Done** cho mọi screen/shared component mới — screen
  mount trong `ProviderScope` fake contract, state chọn bằng knobs; component
  là knob playground. Ghi ở `CLAUDE.md`, `definition-of-done.md`,
  `flutter-feature-slice` (Step 4 + checklist), `flutter-design-system`, và
  `widgetbook/README.md` (mẫu mount screen). Lý do: catalog cô lập không thấy
  lỗi composition — screen use-case với dữ liệu điều khiển được là chỗ mắt
  người soi được chúng. Màn deck hợp nhất của #57 đã được backfill ngay ở
  M4.10l; M4.11 trở đi áp dụng bắt buộc cho mọi màn mới.

### M4.10l · Backfill `DeckListScreen` (#57) và `MxPillButton` vào catalog

- **Status:** done
- **Goal:** Áp dụng rule DoD mới (ghi ở M4.10k) lên chính output của M4.10c:
  màn deck-list hợp nhất mount **nguyên màn** trong catalog với contract fake,
  và shared widget mới có playground riêng.
- **Scope:** category **Screens** trong Widgetbook; `DeckListScreen` use-case
  với knob `scenario` (a few root decks / long Vietnamese names / 25 decks /
  nothing due / no decks yet / read fails); `MxPillButton` playground; knob
  `tappable` cho `MxCard` (API mới của #57); `LocalizationAddon` en + vi vì
  màn thật đọc ARB qua `context.l10n`.
- **Out of scope:** use-case cho các form/sheet của Deck (mở được từ màn đã
  mount, không cần entry riêng); mô phỏng stream re-emit; Widgetbook Cloud.
- **Editable documents:** `docs/wbs.md`
- **Output:** `widgetbook/lib/screens/deck_list_screen_use_case.dart` (fake
  `DeckRepository` + router mini + 6 scenario), `MxPillButton` playground trong
  `component_control_sections... (control_components.dart)`, knob `tappable`
  trong `form_components.dart`, `LocalizationAddon` trong `main.dart`.
- **Acceptance criteria:**
  - [x] `DeckListScreen` render trong catalog bằng contract fake — không mở
        database, không import `data/` của feature.
  - [x] Sáu scenario chuyển được bằng knob; drill-down bằng tap row hoạt động
        trong khung catalog và quay lại được bằng Back của router mini.
  - [x] Scheduler của hàng con resolve qua root (BR-06) — không còn
        "Eight boxes" trong cây `sm2`.
  - [x] Root gates xanh sau merge #57: 804 test, guard, architecture, analyze;
        catalog analyze/test/web build xanh.
- **Cách mount, và hai quyết định trong đó:**
  - **Use-case mang một `GoRouter` mini riêng** (route `decks` + `deckDetail`,
    giữ trong `State` để knob rebuild không reset stack) — nên tap một row
    **drill-down thật** ngay trong khung catalog, đúng hành vi hợp nhất của
    #57: cùng màn ở mọi cấp.
  - **Fake resolve scheduler qua root (BR-06)** như read thật: bản đầu để
    fallback hằng số và hàng con của cây `sm2` hiện "Eight boxes" — chính
    catalog làm lộ lỗi semantics đó trước khi ai mở app.
- **Dependencies:** M4.10c (#57 — màn hợp nhất), M4.10k (catalog + rule)
- **Tests required:** smoke test catalog (cover cây mới, chạy cả local lẫn CI)
- **Checklist phases:** 7.3, 7.5
- **Bổ sung khi merge #58 (breadcrumb):** `DeckListSnapshot` thêm field bắt
  buộc `ancestors` — fake của catalog dựng lại path từ chuỗi id tổng hợp
  (root-first, không chứa deck đang mở, đúng contract của read thật) nên
  breadcrumb hiển thị và **bấm lên tổ tiên hoạt động** trong khung catalog;
  `MxBreadcrumb` có playground riêng với knob depth 2–10 và tên tiếng Việt
  dài. Compile error của fake khi model đổi chính là điểm cộng: catalog gãy
  **lúc build** thay vì mục lục mồ côi.
- **Viewport mặc định là khung điện thoại (chủ dự án yêu cầu):** catalog mở
  mọi use-case trong frame **Galaxy S23 Ultra** (384×823 logical, dpr 3.75 —
  tự định nghĩa vì Widgetbook không có preset) thay vì kéo căng canvas trình
  duyệt; một màn được thẩm ở bề rộng desktop là thẩm trong hình dạng không
  user nào thấy (AD-04: Android là release target). `Viewports.first` là
  default của addon nên thứ tự list chính là quyết định; `None` giữ cuối
  list cho việc soi bảng token rộng. **Màn nhỏ đại diện bằng máy thật (chủ dự
  án yêu cầu):** thêm preset iPhone 13 Mini (375×812) và iPhone SE (375×667 —
  trùng logical size iPhone 8); Compact 320 đổi nhãn thành "M4.8b floor" —
  nó là cận dưới dự án test, không phải điện thoại nhỏ tiêu biểu, và một
  catalog mà lựa chọn màn nhỏ duy nhất là 320 sẽ biến mọi lần kiểm màn nhỏ
  thành kiểm ca cực đoan.
### M4.10m · Giành lại phần Material đang tự quyết (refactor tầng common, đợt 1)

- **Status:** done
- **Goal:** Chủ dự án đề xuất refactor ở tầng common lúc dự án còn nhỏ. Đợt đầu
  làm phần **khách quan**: mọi thứ Flutter đang vẽ mà app chưa bao giờ đặt tên.
- **Scope:** `core/theme/app_overlay_themes.dart` (mới),
  `app_chip_theme.dart` (tách), `app_theme.dart`, harness audit.
- **Out of scope:** nâng lại từng shared widget (nhịp, khoảng cách, hierarchy) —
  phần chủ quan, chủ dự án duyệt bằng ảnh render trước khi sửa.
- **Dependencies:** M4.10i
- **Checklist phases:** 7.1, 8, 14
- **Tests required:** `app_overlay_themes_test.dart` — barrier suy từ scrim,
  tooltip đọc được và đảo theo mode, spinner đạt sàn non-text.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/app_overlay_themes.dart`,
  `lib/core/theme/app_chip_theme.dart`,
  `test/core/theme/app_overlay_themes_test.dart`
- **Acceptance criteria:**
  - [x] Bảy nhóm màu Material từng tự quyết nay do app khai báo: modal barrier
        (dialog + sheet), progress indicator, tooltip, text selection, divider,
        scrollbar.
  - [x] Barrier suy từ `scrim` — dark 0.72, light 0.48 — thay cho `Colors.black54`
        xám thuần không đổi theo mode.
  - [x] 959 test pass, 6 golden đổi và đã xem lại, mọi guard 0 violation, audit
        vẫn 0 vi phạm.

**Lỗ hổng có hệ thống mà audit không thể thấy.** `design_audit/` quét `lib/` nên
nó chỉ thấy màu **code viết ra**. Màu tồn tại như một mặc định của framework thì
vô hình với nó — chính mục "Not verified" em đã ghi ở M4.10f. Và nó giấu drift
thật: barrier sau mọi dialog và sheet là `Colors.black54`, một mảng xám không
mang seed và không đổi giữa hai mode, sống sót qua trọn một cuộc audit màu.

**Một lỗi có sẵn lộ ra khi khai báo.** Material mặc định lấy `colorScheme.primary`
cho spinner, nên đó là thứ app đang vẽ. Đo trên nền nó quay: dark `primary` chỉ
**2.81:1**, dưới sàn 3.0 của một đồ hoạ. Giá trị đó chưa bao giờ được chọn cho
việc này — `primaryDark` bị giữ ở mức sáng vừa đủ để nút filled không thành thứ
chói nhất trên trang navy, tức là ngược với cái spinner cần. Nay dùng `focusRing`:
cùng hue, 5.36:1 ở dark và 7.41:1 ở light.

**Một hướng đã thử và bỏ, kèm lý do.** Định mở strict visual audit sang overlay
(MX-VIS-003). Chạy thử: 6 blocking contrast failure, **toàn bộ là chữ nằm dưới
barrier** — thứ bị làm mờ có chủ đích. Auditor hoạt động đúng trên một chủ thể nó
không được thiết kế cho: nó duyệt một màn hình ở trạng thái nghỉ và phán xét mọi
thứ được vẽ, trong khi một nửa render tree của overlay là nội dung người dùng
**đang bị cố ý ngăn không cho đọc**. Làm nó xanh sẽ cần một danh sách allowance
lớn khẳng định rằng chữ không đọc được là chấp nhận được — ngược hẳn mục đích của
allowance. Thay bằng test giá trị ở tầng theme, còn hình hài thì golden dialog và
sheet đã phủ.

**Next task: M4.10n (nâng shared widget, chờ duyệt) rồi M4.11.**

### M4.10n · Nâng shared widget (refactor tầng common, đợt 2)

- **Status:** done
- **Goal:** Phần **chủ quan** của refactor common. Chủ dự án duyệt bằng ảnh
  render trước khi sửa.
- **Scope:** `mx_action_sheet.dart`, `mx_error_state.dart`, specimen golden.
- **Out of scope:** radius và nhịp empty state — hai nhận định ban đầu không
  đứng vững khi đọc code, xem bên dưới.
- **Dependencies:** M4.10m
- **Checklist phases:** 8, 14
- **Tests required:** golden cho ba specimen list tile, action sheet, error state.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/shared/widgets/golden_surfaces.dart`
- **Acceptance criteria:**
  - [x] Icon trong action sheet không còn cạnh tranh với nhãn của chính nó.
  - [x] `MxErrorState` dùng nút chính, khớp `MxEmptyState`.
  - [x] Specimen list tile chụp ở đúng môi trường nó được dùng.
  - [x] 959 test pass, 10 golden đổi và đã xem lại.

**Hai trong bốn nhận định của agent không đứng vững, và đã báo lại thay vì sửa
bừa.** Nhìn ảnh thì thấy ô nhập "bo tròn như pill" và empty state "cách đều,
thiếu nhịp". Đọc code thì: input dùng `AppRadius.md` (12) còn card dùng `lg` (16)
— đó là một hệ nhất quán (control nhỏ hơn surface), không phải bất nhất; và
empty state đã là 16/8/24, tức là **không** đều. Cả hai đều là đọc ảnh nén rồi
suy ra, đúng loại sai lầm mà mấy milestone này tồn tại để tránh.

**Một "lỗi component" hóa ra là lỗi của tấm ảnh.** `MxListTile` trông trần trụi
so với `MxCard`, nhưng nó có **đúng một caller** — move-deck sheet — và một sheet
là `surface`. Specimen lại đặt nó trên `Scaffold` trống. Sửa tấm ảnh, không sửa
component: thêm một tuỳ chọn surface sẽ là capability không caller, đúng thứ dự
án từ chối ở mọi component khác. Flutter còn bắt thêm một tầng nữa: bọc
`ColoredBox` che ink của `ListTile` — phải là `Material`, mà sheet vốn là
Material.

**Next task: M4.10o (AD cho design system) rồi M4.11.**

### M4.10o · AD-14: chốt hệ màu và chiều sâu thành tài liệu

- **Status:** done
- **Goal:** Viết ra thứ mà hai milestone trước phải suy từ comment. Đợt cuối của
  refactor tầng common.
- **Scope:** `docs/architecture.md` (AD-14)
- **Out of scope:** không đổi một dòng code nào.
- **Dependencies:** M4.10n
- **Checklist phases:** 7.1
- **Tests required:** không có test mới — AD ghi lại các phép đo mà
  `app_elevation_test.dart`, `app_theme_test.dart`, `app_palette_test.dart` và
  `color_system_rules_test.dart` đã bảo vệ sẵn; `check_docs.sh` là gate.
- **Editable documents:** `docs/architecture.md`, `docs/wbs.md`
- **Output:** `docs/architecture.md` §AD-14
- **Acceptance criteria:**
  - [x] AD-14 ghi: seed là nguồn của mọi trung tính; mỗi role là một hue qua một
        bộ sinh; border lấy hue từ chủ của thứ nó bọc; **chiều sâu là mục tiêu đo
        được chứ không phải cơ chế cố định**; mọi thứ được vẽ phải đến từ theme
        kể cả khi Flutter có mặc định.
  - [x] Ghi cả bốn phương án đã bị loại kèm lý do và milestone loại chúng.
  - [x] `check_docs.sh` xanh.

**Lý do tồn tại của AD này, nói thẳng:** hai đoạn comment từng bị đọc thành luật.
`app_colors.dart` viết thang surface hoạt động "without a shadow being asked to
carry the hierarchy" và `mx_card.dart` viết "flat by design"; hai milestone sau
trích chúng như ràng buộc — kể cả để bác một ceiling của bản brief audit — trong
khi không AD, không BR, không test nào đứng sau, còn `docs/checklist.md` thì vẫn
đang yêu cầu một Elevation token chưa ai làm. Chủ dự án phải nói thẳng rằng app
**cần** độ nổi thì việc mới được xem lại. AD-14 tồn tại để lần sau không ai phải
suy ra luật từ văn xuôi.

**Next task: M4.11 · Card management full-stack.**

### M4.10p · Token Flutter theo design system (đổi nguồn của giá trị)

- **Status:** done
- **Goal:** Đối chiếu từng token của `lib/core/theme/` với
  `design_system/tokens/*.css`, lệch chỗ nào sửa Dart theo CSS chỗ đó.
- **Scope:** `app_colors.dart`, `app_palette_test.dart`, `preview_harness.dart`,
  14 golden, `docs/architecture.md` (AD-14), `design_system/IMPORT_LEDGER.md`
- **Out of scope:** hành vi component (nút retry của `MxErrorState` vẫn primary —
  chỗ đó `.prompt.md` của design vẫn ghi `secondary`, chưa xử lý); ba token CSS
  chưa có caller.
- **Dependencies:** M4.10o, và đợt import `design_system/`
- **Checklist phases:** 7.1
- **Tests required:** `app_palette_test.dart`, `app_theme_test.dart`,
  `color_system_rules_test.dart`, strict visual audit, 14 golden.
- **Editable documents:** `docs/architecture.md`, `docs/wbs.md`,
  `design_system/IMPORT_LEDGER.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] **Mọi token số đã khớp sẵn** — spacing, radius, icon size, duration,
        breakpoint, thang elevation, không cái nào lệch.
  - [x] 11/40 token màu lệch, cả 11 lấy theo CSS: bốn semantic × hai mode,
        `onPrimaryContainerDark`, `tertiaryDark`, `webLetterbox`.
  - [x] Ba token CSS chưa mang về, có ghi lý do: `--color-progress-*`,
        `--color-streak*` (chưa có caller, và streak là hue thứ năm),
        `--color-primary-accent` (đã biểu diễn được), `--color-disabled-surface`
        (Dart derive, lệch ≤3/255).
  - [x] 959 test pass, `flutter analyze` sạch, `check_docs.sh` xanh.

**Audit bắt được một lỗi thật, và lời giải nằm trong chính design.** Lấy
`successLight #10795C` xong, nhãn 14px của verdict tụt xuống **4.30:1** trên
`secondaryContainer` — dưới 4.5. `VerdictAction` của design giữ nền trung tính
đúng vì lý do đó ("một lớp tint cùng hue với nhãn ăn mất tương phản đúng lúc nhãn
quan trọng nhất"), nên idle chuyển sang `surface` và selected chuyển sang
`surfaceMuted`. Đo cả năm nền ứng viên: `secondaryContainer` là nền duy nhất
trượt. **Theo một token là theo cả cách design dùng nó, không chỉ mã hex.**

**Một luật cũ bị thay, và mâu thuẫn là của design chứ không phải của repo.**
`app_palette_test.dart` từng khẳng định `danger` to nhất; với giá trị mới,
`warning` 0.801 và `success` 0.766 vượt `danger` 0.634 ở light. `readme.md` của
design vẫn viết "danger carries the most saturation" — tức **hex và văn xuôi của
design cãi nhau**. Giá trị thắng vì giá trị là thứ được cho quyền; test giữ nửa
còn đúng (`info` vẫn nhỏ nhất ở cả hai mode), nâng trần 0.70 → 0.85 theo số đo
thật, và thêm ràng buộc mới rằng bốn màu phải còn cách nhau ≥1.5 lần, để "cố ý
không bằng nhau" vẫn có test canh.

**Next task: M4.11 · Card management full-stack.**

### M4.10q · Parity checklist với design system, và vòng sửa đầu tiên

- **Status:** done — 80/80 dòng đã review. Bốn dòng cuối đóng ở M4.10aq
  (theme-slot audit) và phần nhãn verdict được chuẩn hoá ở **M4.12d**, nơi phát
  hiện chín dòng vẫn ghi `drift` sau khi code đã sửa xong từ lâu.
- **Goal:** Ghép từng artefact của `design_system/` với đúng một chỗ trong `lib/`,
  review 1:1, rồi sửa những chỗ lệch.
- **Scope:** `docs/reviews/design-parity-checklist.md` (77 dòng),
  `mx_loading_state.dart`, `mx_breadcrumb.dart`, `mx_content_shell.dart`,
  `mx_navigation_bar.dart`, `app_button_themes.dart`, `app_theme.dart`,
  `deck_path_widget.dart`, `deck_list_screen.dart`, 4 golden.
- **Out of scope:** những gì chặn bởi BR (`learned`, streak, subtree search).
- **Dependencies:** M4.10p
- **Checklist phases:** 7, 8
- **Tests required:** toàn bộ suite, strict visual audit, golden.
- **Editable documents:** `docs/reviews/design-parity-checklist.md`, `docs/wbs.md`
- **Output:** `docs/reviews/design-parity-checklist.md`
- **Acceptance criteria:**
  - [x] Checklist liệt kê đủ, kèm bảng "cố ý loại trừ" để chỗ thiếu nhìn thấy được.
  - [x] 33/77 dòng đã review, 12 finding có đánh số.
  - [x] Sửa 11 finding; 959 test pass, analyze sạch.
  - [x] 44 dòng còn lại (D, E và vài dòng lẻ A, B) — đóng dần qua M4.10r…M4.10aq.

**Một lỗi thật, và nó sống được vì bị sửa ở call site.** M4.10j đặt progress
indicator theme sang `focusRing` vì `primary` ở dark chỉ đo được **2.81:1**.
Nhưng `mx_loading_state.dart` truyền thẳng `color: primary`, ghi đè chính cái
theme đó — nên màn loading chính của app là cái spinner duy nhất bản vá không
với tới. Design cũng ghi `primary`, nên chỗ này giải bằng phép đo chứ không theo
design.

**Hai thứ chỉ ảnh render mới bắt được.** Hairline của nav bar đứt ở giữa vì
`DecoratedBox` vẽ decoration *sau lưng* con, mà `NavigationBar` tự vẽ nền —
phải `DecorationPosition.foreground`. Và **Material elevation render thành vòng
đen đặc trong golden** vì `flutter_test` tắt shadow thật; nhưng lý do lớn hơn để
bỏ nó là **AD-14 quy định chiều sâu chỉ có một cơ chế** — `shadowsFor`, thứ audit
đọc được và rỗng ở dark. Nhận `elevation` là đổi một luật đo được lấy một luật
không đo được. Giữ phần hình dạng FAB, bỏ phần shadow.

**Next task: hoàn tất 44 dòng còn lại của checklist, rồi M4.11.**

### M4.10r · BR-88 "đã thuộc", và `MxProgressBar`

- **Status:** done
- **Goal:** Bỏ chặn cho progress bar bằng cách viết luật còn thiếu, rồi dựng
  component và gắn vào deck card.
- **Scope:** `docs/business-rules.md` (BR-88), `deck.drift` (hai query),
  `DeckSummary`, mapper, `AppColors` + `AppSemanticColors`,
  `mx_progress_bar.dart`, `deck_tile_widget.dart`, ARB en/vi, widgetbook fake,
  test + 2 golden mới.
- **Out of scope:** streak (chưa có feature), subtree search.
- **Dependencies:** M4.10q
- **Checklist phases:** 7, 8, 11, 14
- **Tests required:** `mx_progress_bar_test.dart`, `deck_list_level_test.dart`,
  strict visual audit, golden, arb parity, stress specimen.
- **Editable documents:** `docs/business-rules.md`, `docs/wbs.md`,
  `docs/reviews/design-parity-checklist.md`
- **Output:** `lib/shared/widgets/mx_progress_bar.dart`,
  `test/shared/widgets/mx_progress_bar_test.dart`
- **Acceptance criteria:**
  - [x] BR-88 định nghĩa "đã thuộc" cho cả hai scheduler, suy ra khi đọc.
  - [x] Cả hai query tổng hợp trả `learnedCardCount` trong **cùng một statement**
        với `totalCardCount` và `dueCardCount` (AD-13).
  - [x] `MxProgressBar` vẽ bằng họ màu riêng, không phải accent.
  - [x] 973 test pass, analyze sạch, audit xanh.

**Nửa `eight_box` đã có sẵn trong doc từ trước.** BR-16 viết `"Đã thuộc"
(current_box == 8) là giá trị suy ra để hiển thị, không phải cột trong DB` — nên
BR-88 không phải luật mới hoàn toàn, nó nâng câu đó thành rule có ID và mở sang
scheduler thứ hai. Chủ dự án chốt `sm2` là `interval_days >= 128`, **khớp đúng
interval của box 8**, chứ không phải 21 ngày theo quy ước Anki. Cái giá đã ghi
vào BR: deck `sm2` cần ~7 lần trả lời tốt mới có card "đã thuộc" đầu tiên.

**Hai token màu thôi bị hoãn vì đã có caller.** M4.10p ghi `--color-progress-*`
chưa mang về vì không gì vẽ chúng. `MxProgressBar` là caller đó, nên
`progressTrack` và `progressFill` vào `AppSemanticColors` với đúng giá trị của
design. `progressComplete` thì không — design trỏ nó vào `success`, và một tên
thứ hai cho một màu là một thứ nữa phải giữ đồng bộ.

**`LinearProgressIndicator` vẽ bằng CustomPainter**, nên audit không đọc được
màu nào. Allowance đếm chính xác — 2 ở root, 3 ở level — và trỏ sang
`mx_progress_bar_test.dart`, nơi cả fill lẫn track được assert từ widget.

**Next task: M4.11 · Card management full-stack.**

### M4.10s · Deck card theo đúng design

- **Status:** done
- **Goal:** Dựng lại deck card theo `DeckLevelScreen.jsx` — ba vùng, chip due,
  well theo trạng thái, thẻ phẳng.
- **Scope:** `deck_tile_widget.dart`, `deck_due_state_widget.dart` (mới),
  `AppColors` + `AppSemanticColors` (cặp streak container), ARB en/vi, palette
  của audit, ba test, `app_navigation_shell_test.dart`.
- **Out of scope:** nút "Study" (chưa có màn study để bấm sang — M5), số
  sub-deck (chưa có trong `DeckSummary`).
- **Dependencies:** M4.10r
- **Checklist phases:** 7, 8, 14
- **Tests required:** strict visual audit, deck screen test, shell layout test.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** `lib/features/deck/presentation/widgets/deck_due_state_widget.dart`
- **Acceptance criteria:**
  - [x] Card phẳng, hairline, không shadow — hai tầng độ nổi trong một cột cuộn
        là thứ làm danh sách trông rối.
  - [x] Vùng mở là target riêng, không còn là cả thẻ với một lỗ ở giữa.
  - [x] Due tách khỏi meta line thành chip riêng ở chân thẻ.
  - [x] Ba trạng thái chân thẻ: có due / không due / chưa có thẻ nào.
  - [x] 973 test pass, analyze sạch, audit xanh, đã render và xem cả hai mode.

**Chip due của design trượt WCAG ở light, và đó là mâu thuẫn thứ tư.**
`.mx-deck__due` vẽ chữ bằng `--color-streak` trên `--color-streak-container` —
đo được **3.12:1** ở 11px semibold, dưới sàn 4.5 cho chữ nhỏ. Dark thì 6.65 nên
chắc vì thế không ai để ý. Mọi container khác trong palette đều có cặp
`on*Container`, họ màu này thì không, nên em suy ra một cái: cùng hue trong
1.2°, **6.38:1** trên container. `--color-streak` bản thân nó vẫn không mang về
— nó thuộc về màn streak chưa tồn tại.

**Hai thứ không làm, vì làm sẽ là control chết.** Nút "Study" của design cần một
session để bấm sang; M5 chưa bắt đầu. Số sub-deck không có trong `DeckSummary`.
Chevron vì thế suy từ `contentType`: deck cố định là card thì không mở ra danh
sách nào (BR-63), nên nó không có chevron.

**Một test hỏng vì lý do đáng sửa hơn là vì thiết kế.**
`app_navigation_shell_test.dart` cuộn bằng `fling(-3000)` — đủ khi thẻ còn thấp,
hụt 4px khi thẻ cao lên. Nay nhảy tới `maxScrollExtent` đo được. Một khoảng cách
phải "đủ lớn" là một khoảng cách sẽ âm thầm hết đủ lớn.

**Next task: M4.11 · Card management full-stack.**

### M4.10t · Level summary panel

- **Status:** done
- **Goal:** Dựng panel tổng kết đầu màn theo `LevelSummary` của design, bằng
  đúng dữ liệu snapshot đã có.
- **Scope:** `deck_level_summary_widget.dart` (mới), `deck_list_screen.dart`,
  ARB en/vi, ba test, allowance của audit.
- **Out of scope:** streak chip và nút "Start studying" — cả hai cần M5.
- **Dependencies:** M4.10s
- **Checklist phases:** 8, 14
- **Tests required:** deck screen test, level test, strict visual audit.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** `lib/features/deck/presentation/widgets/deck_level_summary_widget.dart`
- **Acceptance criteria:**
  - [x] Con số đến hạn, câu nối tiếp nó, và thanh tiến độ của cả cấp.
  - [x] Không đọc thêm lần nào — mọi số là phép cộng trên snapshot đã có (AD-13).
  - [x] Cấp rỗng thì không có panel; empty state nói nhiều hơn "0 đến hạn".
  - [x] 973 test pass, đã render và xem cả hai mode.

**Không cần đụng data.** Số của một child là cả subtree của nó, các subtree anh
em rời nhau, nên cộng children ra đúng tổng của cấp — và một deck chỉ chứa một
loại (BR-63) nên cấp có children là deck thì không có card riêng bị bỏ sót. Cộng
trong bộ nhớ thay vì đọc lần hai cũng là thứ giữ panel và list không bao giờ nói
hai con số của hai thời điểm khác nhau.

**"Xong" chứ không phải số 0.** Số 0 đặt ở cỡ chữ headline là thứ to nhất màn
hình nói rằng chẳng có gì xảy ra; BR-29 nói không có thẻ đến hạn là trạng thái
bình thường, không phải thất bại của ngày hôm đó.

**Hai thứ của design cố ý vắng mặt.** Streak chip cần `study_answers` mà chưa gì
ghi vào cho tới M5 — một streak luôn bằng 0 tệ hơn không có streak. Nút "Start
studying" cần một session để bấm sang, cùng milestone đó.

**Một test đổi kỳ vọng vì đúng.** `the loaded list fits 320x568` đòi thấy đủ 3
thẻ; panel chiếm phần trên của màn 568 cao nên thẻ thứ ba xuống dưới nếp gấp,
dựng lazy và cuộn tới được. Giữ nguyên con số 3 là khẳng định không thứ gì phía
trên list được phép có chiều cao — một luật không ai chọn. Test nay kiểm điều
thực sự quan trọng ở khổ đó: không overflow, và phần còn lại cuộn tới được.

**Next task: M4.11 · Card management full-stack.**

### M4.10u · Đóng nốt 77 dòng parity checklist

- **Status:** done
- **Goal:** Review đủ 77 dòng, sửa luôn chỗ nào có vấn đề.
- **Scope:** `app_durations.dart`, `app_typography.dart`, `mx_progress_bar.dart`,
  `deck_list_toolbar_widget.dart`, `deck_list_screen.dart`, `preview_harness.dart`,
  ARB en/vi, `docs/reviews/design-parity-checklist.md`.
- **Out of scope:** `MxSearchField` và subtree search — đã review, chưa dựng.
- **Dependencies:** M4.10t
- **Checklist phases:** 7, 8, 14
- **Tests required:** toàn bộ suite.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Cả 77 dòng có verdict; không còn dòng nào `[ ]`.
  - [x] Ba chỗ có vấn đề đã sửa: A16, A7, D3.
  - [x] 973 test pass, analyze sạch, check_docs xanh.

**Chỗ đáng giá nhất là A16, và nó ẩn kỹ.** Dart không có token easing nào, và
chỗ duy nhất dùng curve viết `Curves.decelerate` — mà preset đó là
`cubic-bezier(0, 0, 0.2, 1)` trong khi `--ease-decelerate` của design là
`(0, 0, 0, 1)`. Đủ giống để nhìn không ra, và không phải cùng một đường cong.
Cả hai curve của design nay có tên trong `AppDurations`.

**D3: danh sách chưa có tiêu đề.** Design đặt "Your decks"/"Sub-decks" cạnh hai
pill; thiếu nó thì hai pill lơ lửng trên các thẻ mà không gì nói chúng lọc cái
gì. Đặt trong `Wrap` chứ không phải `Row` phía trên, vì ở `textScaler` 2.0 trên
màn 320 nhãn và hai pill không đủ một dòng — `Row` sẽ cắt thay vì xuống dòng.

**Sáu chỗ design tự mâu thuẫn — đó mới là kết quả có giá trị nhất của cả đợt
review.** "Theo JSX" không phải một luật áp được mà không cần đọc, vì JSX cãi
chính nó đủ nhiều để cần luật phân xử: giá trị thắng khi là giá trị token, văn
xuôi thắng khi là chuyện component với tay vào token nào, và **phép đo thắng cả
hai**.

**Next task: M4.11 · Card management full-stack** (hoặc subtree search nếu muốn
đóng nốt phần design còn thiếu trước).

### M4.10v · Số deck con và căn hàng tiêu đề

- **Status:** done
- **Goal:** Đóng hai chỗ còn lệch nhìn thấy được khi so với ảnh render của
  design kit.
- **Scope:** `deck.drift` (hai query), `DeckSummary`, mapper,
  `deck_tile_widget.dart`, `deck_list_toolbar_widget.dart`, ARB en/vi, fake
  repository, widgetbook fake.
- **Out of scope:** ô search, chip streak, nút Start studying / Study, tab "You",
  nút đóng panel.
- **Dependencies:** M4.10u
- **Checklist phases:** 11, 14
- **Tests required:** toàn bộ suite, đặc biệt các test 320 + textScaler 2.0.
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Meta line mở đầu bằng `N deck con` khi có, đúng như design.
  - [x] Hai pill dạt về cuối hàng tiêu đề.
  - [x] 973 test pass, đã render và đối chiếu với ảnh.

**`subDeckCount` đếm con trực tiếp, không phải cả subtree** — ngược với hai count
kia. Dòng đó viết "3 deck con" và người đọc đếm thứ họ sẽ thấy khi mở; còn số
card là cả subtree vì một card nằm sâu ba cấp vẫn là card deck này chịu trách
nhiệm.

**`Row` với `Expanded` tràn ở 320 + textScaler 2.0, và đó là lý do đổi cách
dựng.** Design cho tiêu đề `flex: 1` nên hai pill nằm cuối hàng; dịch thẳng
thành `Row` thì tiêu đề co lại được nhưng **hai pill cộng lại đã rộng hơn màn
hình** khi chữ gấp đôi. `Wrap` chứa tiêu đề và một `Wrap` thứ hai chứa hai pill
làm được cả hai: một dòng thì `spaceBetween` đẩy pill về cuối, không đủ thì cả
cụm xuống dòng, và nếu hai pill cũng không chung dòng được thì `Wrap` trong tách
tiếp. Bốn test responsive là thứ bắt được lần dựng đầu.

**Next task: M4.11 · Card management full-stack.**

### M4.10w · Golden render ở đúng mật độ máy thật

- **Status:** done
- **Goal:** Golden hết mờ — render ở mật độ của máy thật thay vì 1×.
- **Scope:** `test/support/golden_density.dart` (mới), `preview_harness.dart`,
  `mx_components_golden_test.dart`, 64 golden sinh lại.
- **Out of scope:** các test đo layout vẫn giữ DPR 1.
- **Dependencies:** M4.10v
- **Checklist phases:** 14
- **Tests required:** toàn bộ suite.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/support/golden_density.dart`
- **Acceptance criteria:**
  - [x] Golden render ở DPR 3; `deck_list_light` từ 420×1040 thành 1260×3120.
  - [x] Không một assertion layout nào đổi.
  - [x] 973 test pass.

**DPR 3 là con số suy ra, không phải chọn.** Đó là mật độ của hai máy mà design
system dựng khung kit của nó: iPhone 13 mini 3×, S23 Ultra 3.5×. Golden vì thế
là thứ một trong hai panel đó thật sự hiển thị, thay vì một phần ba của nó.

**Layout không đổi một chút nào.** Kích thước logic là `physicalSize /
devicePixelRatio`, nên widget vẫn dựng ở đúng những con số cũ và mọi assertion
về rect trong suite không bị ảnh hưởng — chỉ raster mịn hơn. Đó cũng là lý do
các test đo layout giữ nguyên DPR 1: chúng đo rect logic, còn raster to hơn ở đó
là trả giá thời gian mà không được gì.

**Chi phí thấp hơn nhiều so với số pixel gợi ý.** 64 golden từ 646 KB lên
2.27 MB — 3.5× chứ không phải 9×, vì UI phẳng nén rất tốt. Một golden không ai
đọc nổi cũng không đáng số byte của nó.

**Next task: M4.11 · Card management full-stack.**

### M4.10x · Tìm kiếm toàn subtree

- **Status:** done
- **Goal:** Đóng mảnh cuối của design còn thiếu — tìm deck theo tên ở bất kỳ đâu
  dưới chỗ người dùng đang đứng.
- **Scope:** `DeckSearchResult`, `SearchDecksUseCase`, `DeckSearchQuery` +
  `deckSearchResults`, `MxSearchField`, `DeckSearchResultsWidget`,
  `DeckSubheaderWidget`, `DeckLevelBodyWidget`, ARB en/vi, 2 golden, allowance
  audit, 28 finder trong test.
- **Out of scope:** đếm card/due trên dòng kết quả — cần aggregate theo subtree
  của từng dòng, khác hình dạng query.
- **Dependencies:** M4.10w
- **Checklist phases:** 8, 14
- **Tests required:** toàn bộ suite, strict visual audit, golden, stress.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** `mx_search_field.dart`, `search_decks_use_case.dart`,
  `deck_search_result_model.dart`, `deck_search_controller.dart`,
  `deck_search_results_widget.dart`
- **Acceptance criteria:**
  - [x] Tìm cả subtree, kết quả có đường dẫn, sắp nông trước rồi theo tên.
  - [x] **Không query mới, không đổi contract.**
  - [x] 978 test pass, analyze sạch, audit xanh.

**Không đụng tầng data, và đó là lựa chọn có tiền lệ.** Use case đọc qua
`watchAllDecks()` rồi khoanh phạm vi, khớp tên, dựng đường dẫn trong bộ nhớ —
đúng hình dạng move-target picker đã dùng và đúng lý do ghi ở đó: ancestry là
phép tính trên một tập parent pointer, không phải lượt đi lại xuống database.

**Ba thứ chỉ test mới bắt được, và cả ba là lỗi thật.**
`command_query_separation_test.dart` chặn `DeckSearchQuery` vì em cho nó hai
mutator. Guideline tap-target bắt ô search cao 20px — `TextField` lấy chiều cao
từ chữ, `isDense` + padding 0 thì không còn gì khác. Và golden lộ ra chữ dính
lên đỉnh pill: một `TextField` cao hơn nội dung thì neo lên trên trừ khi được
bảo `expands`.

**`AppBar.bottom` là sai công cụ cho subheader.** Nó bắt khai báo chiều cao
trước, mà chiều cao của dải này phụ thuộc cỡ chữ người dùng — một con số khai
sẵn là một phỏng đoán, và ở `textScaler` 2.0 nó tràn 41px. Đặt trên một
`Expanded` thì nó tự lấy đúng chiều cao cần và vẫn ghim y như cũ.

**28 finder hỏng vì đúng một lý do.** Ô search là `TextField` thứ hai trên mọi
màn deck. Thay vì sửa mỗi chỗ một kiểu, thêm `deckFormField` dùng chung — nói rõ
test đang muốn ô *nào*, và vẫn đúng lần sau màn hình mọc thêm input.

**Next task: M4.11 · Card management full-stack.**

### M4.10y · Nút đóng panel tổng kết

- **Status:** done
- **Goal:** Đóng mảnh cuối của design không bị chặn bởi M5.
- **Scope:** `DeckSummaryVisibility`, `deck_level_summary_widget.dart`,
  `deck_summary_section_widget.dart` (mới), `deck_list_screen.dart`, ARB en/vi,
  một test, allowance audit.
- **Out of scope:** streak, Start studying, nút Study, tab "You" — đều cần M5.
- **Dependencies:** M4.10x
- **Checklist phases:** 8, 14
- **Tests required:** toàn bộ suite, strict visual audit.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** `lib/features/deck/presentation/widgets/deck_summary_section_widget.dart`
- **Acceptance criteria:**
  - [x] Nút × ẩn panel; một dòng chữ thay chỗ nó và đưa nó trở lại.
  - [x] Test đi trọn vòng ẩn → hiện lại, không dừng ở "đã biến mất".
  - [x] 979 test pass, analyze sạch, audit xanh.

**Không khoá theo cấp, có chủ đích.** Lý do design đưa ra cho việc cho phép ẩn
là một tâm trạng chứ không phải một chỗ — "vào ngày dành để sắp xếp lại deck thì
nó chắn mất danh sách nó ngồi lên trên" — nên một người ẩn nó ở cấp gốc rồi thấy
nó quay lại sau hai lần chạm là một người không được lắng nghe. Filter và sort
cũng toàn cục vì cùng lý do.

**Luôn có thứ gì đó ở chỗ đó.** Một panel biến mất không dấu vết thì người dùng
không có đường quay lại và cũng không có lý do tin rằng nó từng ở đó. Dòng chữ
thay chỗ là thứ biến việc ẩn thành một lựa chọn thay vì một mất mát — và test đi
trọn vòng chứ không dừng ở chỗ nó biến mất.

**Một mutator, không phải toggle.** Nút đóng và dòng chữ đưa nó về đều biết
trước câu trả lời của mình, nên `setVisible` nói ra trạng thái muốn có thay vì
lật cái đang có.

**Next task: M4.11 · Card management full-stack.**

### M4.10z · Ô search: căn dòng và trạng thái focus

- **Status:** done
- **Goal:** Đóng hai chỗ lệch so với design kit mà chủ dự án chỉ ra.
- **Scope:** `mx_search_field.dart`, `mx_search_field_test.dart` (mới), 2 golden.
- **Out of scope:** chiều cao 44 của design — sàn 48 thắng.
- **Dependencies:** M4.10y
- **Checklist phases:** 7, 8
- **Tests required:** `mx_search_field_test.dart`, golden, strict visual audit,
  test responsive 320 + textScaler 2.0.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/shared/widgets/mx_search_field_test.dart`
- **Acceptance criteria:**
  - [x] Icon và chữ chung một dòng, lệch dưới 1px, có test canh.
  - [x] Focus đổi nền và viền, không đổi kích thước, có test canh.
  - [x] 985 test pass, audit xanh.

**Follow-up:** một nudge dọc 2px qua `TextAlignVertical` đã đóng phần mép dưới
khó chịu còn lại, và golden của `mx_search_field` đã được regen để khớp.

**Phép đo đầu tiên của em sai, và đó là bài học đáng ghi.** Em báo "căn giữa
trong sai số nửa pixel" dựa trên `matchesGoldenFile` — nhưng golden chụp **cả
màn**, không phải riêng pill, nên mọi cửa sổ quét pixel của em rơi vào nền trang.
Số liệu trông thuyết phục và vô nghĩa. Chỉ tới khi render pill trên nền phẳng
rồi *nhìn* thì mới thấy chữ nằm cao hơn hẳn dòng icon. **Một phép đo không kiểm
được chủ thể của nó thì tệ hơn không đo.**

**Nguyên nhân: hỏi sai chỗ cho chiều cao 48.** `InputDecoration.constraints`
nới hộp của decorator lên 48 và để chữ dính trần; `AppSpacing.minimumTouchTarget`
phải nằm trên `SizedBox` bọc ngoài, còn field thì `expands` vào và
`textAlignVertical: center` đưa chữ về giữa. Design nói `align-items: center`
ngay từ đầu — em dùng `stretch`, và stretch khiến mỗi con tự căn giữa nội dung
theo luật riêng của nó.

**Viền không trong suốt, dù design để trong suốt.** Alpha 0 không phải token và
audit chặn — đúng, vì "alpha bằng 0" chính là cách một màu vô chủ ẩn mình. Vẽ
đúng màu nền cũng vô hình y hệt mà lại là token. `strokeAlignOutside` giữ nét
viền ngoài layout: viền nằm trong hộp sẽ đẩy pill lên 50 trong khi tap target
cần 48, và ở 320 với `textScaler` 2.0 chrome không dư nổi hai pixel.

**Next task: M4.10aa · Thang bề mặt dark về đúng hue của page.**

### M4.10aa · Thang bề mặt dark về đúng hue của page

- **Status:** done
- **Goal:** Card dark thôi trông như tờ giấy xám nổi trên nền app tím.
- **Scope:** `design_system/tokens/colors.css` (khối dark), `app_colors.dart`,
  `design_system/readme.md`, `IMPORT_LEDGER.md`, 32 golden dark.
- **Out of scope:** light mode — không đụng một giá trị nào. `--color-progress-track`
  và `--color-on-secondary-container`: xem *Chưa đóng* bên dưới.
- **Dependencies:** M4.10z
- **Checklist phases:** 7
- **Tests required:** `app_palette_test.dart`, `app_theme_test.dart`,
  `color_system_rules_test.dart`, golden dark, strict visual audit.
- **Editable documents:** `docs/wbs.md`, `design_system/readme.md`,
  `design_system/IMPORT_LEDGER.md`
- **Output:** `design_system/tokens/colors.css`, `lib/core/theme/app_colors.dart`
- **Acceptance criteria:**
  - [x] Mọi bề mặt dark nằm ở OKLCH hue ~285, chroma 0.06–0.074.
  - [x] Thang L\* vẫn tăng đều và card vẫn cách page ≥ 6.0 L\* (đo 6.32).
  - [x] R3/R8/R9 xanh; 985 test pass; analyze sạch.

**Nguyên nhân chủ dự án chỉ ra, và nó đúng ở hai tầng cùng lúc.** Card `#1B1D32`
lệch hue so với page `#0A082D` (235 với 243), **và** chỉ mang hơn nửa chroma của
page (0.040 với 0.072). Nhìn riêng từng màu thì không gọi tên được khác biệt nào;
xếp chồng lên nhau thì một bề mặt xỉn hơn, ngả xanh lá hơn nằm trên nền tím bão
hoà đọc thành *tờ giấy dán lên app* chứ không phải một mặt phẳng cùng phòng.

**Giữ bậc sáng là ý định, không phải kết quả.** Kéo về hue mới trong sRGB tốn
khoảng 2 L\* mỗi bậc: thang thực tế thành 3.9 → 10.2 → 16.9 → 24.0 thay vì
3.9 → 11.6 → 19.0 → 26.3. Mọi assertion vẫn xanh, chỗ sát nhất là card cách page
6.32 L\* trên sàn 6.0.

**Hai thứ đi kèm không nằm trong danh sách ban đầu.**

- `--color-secondary` (`#B4B9CC` → `#B8B7D0`). R3 buộc fill và container của một
  role cách nhau tối đa 5°; đưa container sang họ page mà để fill ở slate cũ mở
  ra 18°, và test đỏ ngay. Đây là kiểu lỗi mà chỉ đổi container mới lộ ra.
- Comment trong `app_colors.dart` khẳng định border dark giữ 1.82:1 — nay là
  1.69:1, vì cả border lẫn card đều tăng chroma và border thì đọc so với card.
  Con số bị pin trong test là *tổng độ nâng của card khỏi page*, không phải
  border, nên gate không đỏ; nhưng một comment sai thì phiên sau tin.

**Chưa đóng, cố ý.** `--color-progress-track` (`#2E3247`) và
`--color-on-secondary-container` (`#D9DCE7`) vẫn ở họ slate cũ. Không gate nào
phủ chúng và chủ dự án không liệt kê; ghi ra đây để lần sau không phải đo lại.

**Next task: M4.10ab · Khoảng hở subheader và nút text dùng chung.**

### M4.10ab · Khoảng hở subheader và nút text dùng chung

- **Status:** done
- **Goal:** Ô search thôi dính app bar; *Show today's summary* thành component
  dùng chung, không padding.
- **Scope:** `mx_content_shell.dart` (`_MxSubheader`), `mx_text_button.dart`
  (mới), `deck_summary_section_widget.dart`, Widgetbook, 2 golden mới, 1 stress
  specimen.
- **Out of scope:** khoảng hở ở màn compact — không còn pixel nào để chia lại.
- **Dependencies:** M4.10aa
- **Checklist phases:** 7
- **Tests required:** golden `text_button` light/dark, stress specimen, strict
  visual audit toàn bộ.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/shared/widgets/mx_text_button.dart`
- **Acceptance criteria:**
  - [x] Subheader có khoảng hở phía trên, **tổng chiều cao không đổi**.
  - [x] `MxTextButton` không padding ngang, vẫn giữ sàn chạm 48.
  - [x] Đăng ký Widgetbook, có golden và stress specimen; 992 test pass.

**Cộng thêm khoảng hở thì hỏng, chia lại thì không — và đó là phát hiện đáng
ghi.** Thêm thẳng `md` phía trên đẩy toàn bộ body xuống 12px, và trên deck list
điều đó nhét icon trailing của card cuối xuống dưới floating action: 24px
`textSecondary` trên `primary`, visual audit đo **1,13:1** và fail. Khoảng hở
giữa icon đó và FAB chỉ có **7px** — nghĩa là mọi mức cộng thêm lớn hơn `xs` đều
va. Giải pháp là chia lại 12px sẵn có thành `sm` trên / `xs` dưới: pill có không
khí, body không dịch một pixel nào.

`_kListBottomInset` không cứu được chỗ này, và lý do đáng nhớ: nó chừa chỗ ở
**cuối** vùng cuộn, còn hàng đang nằm dưới FAB ở trạng thái nghỉ thì không liên
quan gì tới padding cuối danh sách.

**Nút text không padding phải là component, không phải một `TextButton` chỉnh
tại chỗ.** `TextButton` của Material thụt label 12px, nên một link đặt ở gutter
màn hình lệch 12px so với tiêu đề và card phía trên — mắt đọc ra là phần tử căn
sai chứ không phải nút. Sàn chạm 48 vẫn giữ, nhưng chuyển sang `minimumSize`
thay vì padding; `AppSpacing` gọi nó là *floor* chứ không phải *step* đúng cho
tình huống này.

**Next task: M4.10ac · Cả card là một target.**

### M4.10ac · Cả card là một target, ở cả hai kit

- **Status:** done
- **Goal:** Bấm chỗ nào trên deck card cũng mở deck; hover/press phủ toàn card.
  Sửa ở tầng component, không phải ở deck card.
- **Scope:** `design_system/components/core/MxCard.{jsx,d.ts,prompt.md}`,
  `design_system/components/mx.css`, `ui_kits/memox-app/DeckLevelScreen.jsx`,
  `_adherence.oxlintrc.json`; `lib/shared/widgets/mx_card.dart`,
  `lib/features/deck/presentation/widgets/deck_tile_widget.dart`; 2 file test.
- **Out of scope:** nút *Study* phía Flutter — chưa có session để mở (M4.11).
- **Dependencies:** M4.10ab
- **Checklist phases:** 7
- **Tests required:** `deck_tile_target_test.dart` (geometry qua router thật),
  2 test mới trong `mx_card_test.dart`.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/features/deck/presentation/deck_tile_target_test.dart`
- **Acceptance criteria:**
  - [x] Bấm dải dưới cùng của card mở đúng deck; bấm ⋮ thì không.
  - [x] `MxCard` có `onClick`/`onTap` vẫn chứa được control bên trong.
  - [x] 998 test pass, analyze sạch, architecture check sạch.

**Bug nằm ở component, không ở deck card.** Kit bọc riêng phần đầu vào
`<button className="mx-deck__open">` vì `MxCard` khi có `onClick` render chính
card thành `<button>` — mà một `<button>` không được chứa control. Ai cần card
vừa bấm được vừa có control thì **buộc** phải tự bọc một phần, tức lặp lại đúng
lỗi này. `MxCard` giờ giữ card là `<div>` và đặt một `button.mx-card__action`
`inset:0` **dưới** nội dung; nội dung `pointer-events:none`, control nào cần thì
nhận lại bằng `mx-card__control`. Overlay không có chữ nên `actionLabel` là bắt
buộc trên thực tế — nếu không, card announce ra là một button không tên.

**Flutter có đúng lỗi song song, ở một tầng khác.** `InkWell` vẽ splash và hover
highlight **trước** khi vẽ child, nên `MxCard` bọc `InkWell` quanh cả
`DecoratedBox` là vẽ mọi trạng thái xuống *dưới* một nền đục: card bấm được mà
không có phản hồi nào. Chưa ai gặp vì chưa call site nào truyền `onTap` — nâng
tap của deck card lên `MxCard` là thứ làm nó lộ ra. Ink giờ nằm **trong**
decoration, chỉ còn padding và nội dung ở dưới nó.

Nested interactive là chỗ hai nền tảng khác nhau thật: HTML cấm, Flutter thì nút
lồng bên trong thắng gesture arena của card. Cùng một kết quả, hai lý do —
`deck_tile_target_test.dart` pin cả hai chiều, và đã kiểm tiêm lỗi: bỏ
`onTap: onTap` thì test đỏ.

**Next task: M4.10ad · Panel tổng kết theo due.**

### M4.10ad · Panel tổng kết chỉ tự mở khi có due

- **Status:** done
- **Goal:** Panel tổng kết thôi tự mở ở level không có gì tới hạn. Lựa chọn của
  người dùng vẫn thắng, theo cả hai chiều.
- **Scope:** `deck_list_view_state.dart` (enum mới),
  `deck_list_view_controller.dart` (đổi tên notifier + codegen),
  `deck_level_summary_widget.dart` (`hasDue`), `deck_summary_section_widget.dart`;
  `ui_kits/memox-app/DeckLevelScreen.jsx` cho khớp.
- **Out of scope:** ghi nhớ lựa chọn qua các lần mở app — vẫn là state trong bộ
  nhớ, như filter và sort.
- **Dependencies:** M4.10ac
- **Checklist phases:** 7, 9
- **Tests required:** `deck_list_summary_test.dart` (mới, 5 case).
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/features/deck/presentation/deck_list_summary_test.dart`
- **Acceptance criteria:**
  - [x] Level có due → panel tự mở. Không có due → chỉ còn dòng link.
  - [x] Người dùng bấm mở thì panel ở lại kể cả khi không có due; bấm đóng thì
        đóng kể cả khi có due.
  - [x] 1006 test pass, mọi gate xanh.

**Boolean không diễn đạt được "người dùng chưa nói gì".** `build() => true` làm
panel mở ở mọi level, kể cả level mà toàn bộ nội dung của nó là "không có gì tới
hạn" — một panel đòi một thao tác để nói rằng không cần thao tác nào. Ba trạng
thái `auto` / `shown` / `hidden` mới tách được "chưa chọn" khỏi "chọn ẩn", và đó
đúng là chỗ CLAUDE.md nói: trạng thái hữu hạn là enum, không phải một đống bool.

**`auto` giải ở widget, không giải trong notifier.** Notifier giữ một *sở thích*
và không biết level nào cả; sở thích đó có ra panel hay không phụ thuộc snapshot
mà widget đang cầm. Đẩy snapshot vào notifier để giải trong đó là bắt một lựa
chọn global mang dữ liệu của một level — và mang nhầm level ngay khi có hai
level cùng sống trong lúc chuyển route.

**Dòng link vẫn ở lại khi không có due.** Cái phiền là phải *đóng* một thứ để
tới được danh sách, không phải bản thân panel; thanh tiến độ bên trong vẫn đáng
xem trên một deck đã học xong, và một tap là tới.

`deck_list_screen_test.dart` vượt 400 dòng khi thêm các case này, nên nhóm
summary tách hẳn sang file riêng — cùng lý do `mx_card_test.dart` từng tách khỏi
`mx_surface_components_test.dart`.

**Next task: M4.10ae · Breadcrumb đủ đường.**

### M4.10ae · Breadcrumb chạy hết đường, từ danh sách tới deck đang mở

- **Status:** done
- **Goal:** Breadcrumb hiện ở mọi cấp deck, và liệt kê đủ: danh sách deck, mọi
  tổ tiên, rồi chính deck đang mở.
- **Scope:** `deck_path_widget.dart`; `deck_path_test.dart`,
  `deck_list_level_test.dart`, `deck_route_test.dart`, allowance của visual
  audit; `ui_kits/memox-app/DeckLevelScreen.jsx` cho khớp.
- **Out of scope:** thao tác trên bước breadcrumb (menu, kéo-thả) — chưa có yêu
  cầu.
- **Dependencies:** M4.10ad
- **Checklist phases:** 7, 8
- **Tests required:** 3 case trong `deck_path_test.dart` (đủ đường, root deck
  cũng có, bước đầu về danh sách).
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/visual_audit/deck_audit_harness.dart`
- **Acceptance criteria:**
  - [x] Vào một root deck cũng có breadcrumb: `Decks › <tên deck>`.
  - [x] Bước cuối là deck đang mở, không bấm được; mọi bước khác điều hướng.
  - [x] 1007 test pass, mọi gate xanh.

**Không có bug — và đó mới là phát hiện.** Chủ dự án báo "breadcrumb không hiện",
nên bước đầu là truy nguồn: `ancestryJson` được `deck_ancestry_read_test.dart`
kiểm trên SQLite thật ở cả ba mức (root không có tổ tiên, cấp 3 nêu đúng root,
mười cấp cho đủ chín). Data layer đúng. Cái sai là **luật hiển thị**: widget cố ý
im lặng cho tới khi có ít nhất một tổ tiên, tức đúng chỗ người dùng nhìn đầu tiên
— bên trong một root deck — thì không có gì. Một component bị giấu khỏi vị trí
phổ biến nhất của nó, từ ngoài nhìn vào không khác gì hỏng.

**Hai lý lẽ cũ đều đúng, và cộng lại thì sai.** Bước đầu trùng nút Back; bước
cuối trùng app-bar title. Cả hai là lập luận chống *chrome trùng lặp*, đều đứng
vững khi xét riêng. Cái giá phải trả là chấp nhận: đổi lại, câu trả lời cho "tôi
đang ở đâu" luôn có mặt và luôn cùng một hình dạng.

Chi phí đã đo được ngay trong test: tên deck giờ xuất hiện hai lần, nên hai test
`findsOneWidget` đỏ. Cả hai chuyển sang tìm trong `AppBar` — `findsNWidgets(2)`
thì vẫn xanh kể cả khi title biến mất và breadcrumb mọc thêm một bản.

File audit companion đứng sẵn ở 399/400 dòng nên phần fixture tách sang
`deck_audit_harness.dart` — **không** tách theo state, vì MX-VIS-001 đòi đúng một
companion cho mỗi screen.

**Next task: M4.10af · Breadcrumb: Root, căn trái, và là link.**

### M4.10af · Breadcrumb: bước Root, căn trái, và là link chứ không phải button

- **Status:** done
- **Goal:** Ba chỉnh sửa chủ dự án yêu cầu sau khi dùng thử M4.10ae.
- **Scope:** `mx_breadcrumb.dart`, `deck_path_widget.dart`,
  `deck_subheader_widget.dart`, `deck_list_screen.dart`,
  `deck_summary_section_widget.dart`, ARB en+vi; `MxBreadcrumb.jsx`, `mx.css`,
  `DeckLevelScreen.jsx`.
- **Out of scope:** đổi mô hình cuộn của màn deck list — xem mục nợ kỹ thuật bên
  dưới.
- **Dependencies:** M4.10ae
- **Checklist phases:** 7
- **Tests required:** 3 case hover/rest trong `mx_breadcrumb_test.dart`, 1 case
  căn trái đo bằng geometry, 1 case màn danh sách chỉ có bước `Root` không bấm
  được, 1 case strip mở ở đầu trái.
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Màn danh sách deck: `🏠 Root`, không bấm được.
  - [x] Trong root deck: `🏠 Root › Japanese N5`. Sâu 3 cấp: đủ bốn bước.
  - [x] Strip bắt đầu ở gutter, cùng mép trái với ô search.
  - [x] Hover không còn ô nền — chỉ đổi màu chữ và gạch chân.
  - [x] 1013 test pass, mọi gate xanh.

**Ba lỗi, và cả ba đều là thứ chỉ người dùng thật mới thấy.** "Root" chứ không
phải `decksTitle`: bước đầu tên là "Decks" nằm dưới app bar cũng tên "Decks"
đọc ra như một link về đúng chỗ đang đứng. Căn trái: `Column` của
`DeckSubheaderWidget` mặc định `CrossAxisAlignment.center`, và ô search rộng hết
chiều ngang nên che mất điều đó — chỉ breadcrumb, rộng đúng bằng các bước của
nó, mới lộ ra. Hover: `InkWell` vẽ một ô bo góc sau mỗi chữ, bốn ô cạnh nhau đọc
ra như một hàng nút chứ không phải một đường dẫn.

**Cái giá của việc thêm strip vào màn danh sách đã đo được: tràn 33px** ở
320×568 với `textScaler` 2.0. Trả bằng ba khoản, không khoản nào là "thu nhỏ cho
vừa":

1. Bước không bấm được bỏ sàn chạm 48 (−16px). `AppSpacing` gọi 48 là *floor*
   cho thứ ngón tay phải chạm; một bước không hành động là một câu khẳng định.
   Strip hỗn hợp không đổi chiều cao vì các bước bấm được vẫn giữ 48.
2. Khoảng hở section dưới toolbar `xl` → `md` ở compact.
3. Khoảng hở dưới panel tổng kết `lg` → `sm` ở compact.

**Nợ kỹ thuật phát hiện ở đây, chưa trả:** panel tổng kết và toolbar được ghim
phía trên danh sách, nên chiều cao của chúng trừ vào màn hình chứ không trừ vào
vùng cuộn. Ở text scale lớn trên máy hẹp, chúng không vừa — và mọi lần thêm chrome
sau này lại phải đi cạo pixel một lần nữa. Cách sửa đúng là cho chúng cuộn cùng
danh sách (`CustomScrollView` + sliver), là đổi mô hình cuộn của màn hình chứ
không phải đổi spacing, nên tách ra làm riêng.

**Next task: M4.10ag · Bỏ FAB, nâng đáy màn hình.**

### M4.10ag · Bỏ floating action, và nâng đáy màn hình lên 360×640

- **Status:** done
- **Goal:** Chấm dứt hai lớp lỗi đã ngốn cả một phiên: chrome không vừa màn hình
  bé, và nút nổi đè lên control của hàng danh sách.
- **Scope:** `deck_list_screen.dart` (create lên app bar, bỏ FAB, bỏ inset 112),
  `app_breakpoints.dart` (tài liệu), 4 file test màn hình đổi surface,
  `app_navigation_shell_test.dart`, allowance của visual audit;
  `ui_kits/memox-app/DeckLevelScreen.jsx` cho khớp.
- **Out of scope:** mật độ card và thang chữ — chủ dự án dừng hướng đó.
- **Dependencies:** M4.10af
- **Checklist phases:** 7
- **Tests required:** toàn bộ suite; visual audit `level_loaded` phải xanh trở
  lại mà không cần allowance nào.
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Không còn `FloatingActionButton` trên màn deck; create nằm ở app bar.
  - [x] Visual audit hết `contrast.text 1.13:1` mà không nới gate.
  - [x] Test màn hình chạy ở 360×640, `textScaler` 2.0 vẫn giữ.
  - [x] 1014 test pass, mọi gate xanh.

**320×568 chưa bao giờ là thứ thiết kế hứa.** `design_system/readme.md:71` ghi
"one real breakpoint at 360px", nhưng 19 chỗ trong 12 file test chạy ở 320 —
thấp hơn đáy đã tuyên bố 40px. Đó là cỗ máy sinh ra chuỗi đánh đổi khoảng hở:
mỗi lần chrome to lên một chút lại phải cạo một section break để mua lại vài
pixel trên một kích thước không thiết bị nào báo cáo. Test màn hình giờ chạy ở
360×640. **Tầng compact dưới 360 giữ nguyên và vẫn được test ở mức component** —
một component xuống dưới đáy mà vẫn dùng được thì rẻ; một màn hình dựng cho kích
thước không ai ship mới là thứ đắt.

**Nút nổi thì không có cách nào "né đúng".** `_kListBottomInset` 112px chỉ chừa
chỗ ở **cuối** vùng cuộn; ở trạng thái nghỉ, hàng nào rơi vào góc dưới phải thì
bị che, và trên deck card đó là nút ⋮. Đo được: FAB `y 700→756`, ⋮ của hàng hai
`y 692→716`. Trước đây pass là do may — comment cũ trong repo tự ghi khoảng hở
chỉ còn 7px. Bỏ hẳn phần tử nổi biến bảo đảm từ "đo được hôm nay" thành "cấu
trúc". Giá phải trả, chấp nhận và ghi lại: hành động chính rời khỏi tầm ngón cái
lên đầu màn hình. Inset cuối danh sách từ 112 xuống `lg`.

**Next task: M4.10ah · Thang chữ thôi là tai nạn.**

### M4.10ah · Khai báo thang chữ tường minh, và pin nó vào design kit

- **Status:** done
- **Goal:** Thang chữ của app thôi phụ thuộc mặc định Material 3.
- **Scope:** `app_typography.dart`, `app_typography_test.dart` (mới), 2 golden.
- **Out of scope:** đổi cỡ chữ — đây là khai báo, không phải thiết kế lại.
- **Dependencies:** M4.10ag
- **Checklist phases:** 7
- **Tests required:** `app_typography_test.dart`, kiểm tiêm lỗi.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/core/theme/app_typography_test.dart`
- **Acceptance criteria:**
  - [x] Mọi rung của thang khai báo `fontSize`, `height`, `letterSpacing`.
  - [x] Test đối chiếu tay với `tokens/typography.css`; tiêm lỗi 16→15 thì đỏ.
  - [x] 1021 test pass, mọi gate xanh.

**App và kit trùng nhau do may, không do khai báo.** `app_typography.dart` chỉ
đặt font family và weight; mọi cỡ chữ là mặc định Material 3, và chúng tình cờ
đúng bằng token của kit. Nâng SDK là cả thang chữ đổi mà **không gì trong dự án
đỏ**: không analyze, không widget test, và không cả golden — vì golden so app với
chính nó chứ không so với thiết kế.

**Test chép tay từ CSS, có chủ ý.** Một test đọc token từ cùng nguồn mà code đọc
chỉ chứng minh code tự nhất quán. Thứ đáng chứng minh là code khớp với một tài
liệu không ai sửa được từ trong Dart.

**Hai golden đổi 0.05%, và đó là bằng chứng chứ không phải phiền toái.** Material
làm tròn `height` của `label-lg` thành **1.43**; kit ghi leading 20px trên cỡ 14,
tức **1.42857**. Lệch 0.02px, đủ đổi khử răng cưa của gạch chân ở trạng thái
focus. Khai báo theo kit là đúng hơn, và golden bắt được — đúng việc nó sinh ra
để làm.

**Next task: M4.10ai · Deck card hai dải.**

### M4.10ai · Deck card ba dải xuống hai: 168px → 100px

- **Status:** done
- **Goal:** Thấy được nhiều deck hơn trong một màn, không đụng cỡ chữ.
- **Scope:** `deck_tile_widget.dart`; `deck_list_level_test.dart`.
- **Out of scope:** thang chữ (đã khai báo ở M4.10ah, giá trị không đổi).
- **Dependencies:** M4.10ah
- **Checklist phases:** 7
- **Tests required:** toàn bộ suite, gồm visual audit và golden.
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Card 100px thay vì 168px; màn 393×852 hiện ~3,5 card thay vì 2,3.
  - [x] Trạng thái due vẫn mang icon + chữ + màu (UC-06 step 3).
  - [x] Tiến độ vẫn được screen reader đọc dù không còn vẽ chữ.
  - [x] 1021 test pass, mọi gate xanh.

**Chữ chỉ chiếm 24 trong 168px — nên không đụng tới nó.** Đo trước khi sửa:
16 padding + 48 dải well/tên + 20 dòng meta + 12 + 20 thanh tiến độ + 12 + 48
dải chân + 8. Hai ô vuông 48 và ba dải xếp chồng là toàn bộ câu chuyện; hạ tên
deck 16→14 chỉ tiết kiệm ~4px, tức 3% của vấn đề.

**Hai khoản cắt, cả hai đều là chỗ nói thừa:**

1. **Dải chân biến mất.** Nó cao 48px để chứa đúng một icon button. Dải đầu vốn
   đã cao ít nhất 48 vì chính nút đó đặt sàn, nên chuyển ⋮ lên đấy là miễn phí.
2. **Header của thanh tiến độ biến mất.** `21 of 42 learned` viết bằng chữ ngay
   trên một cái track dài đúng bằng tỉ lệ đó là một sự thật nói hai lần, tốn 24px
   trên mỗi hàng. Chữ chuyển vào `Semantics` — screen reader vẫn nghe đủ, và
   `deck_list_level_test.dart` kiểm chính nhãn gộp của card chứ không kiểm một
   node riêng, vì `MxCard` announce cả card là một button.

Thanh tiến độ và chip due giờ chung một hàng: bar giãn, chip nằm phải.

**Một lỗi do chính thay đổi này sinh ra, đã sửa:** chevron căn theo đỉnh hàng
trong khi ⋮ nằm giữa ô 48 của nó, nên hai dấu ở đuôi hàng lệch nhau nửa dòng —
đọc ra như lỗi chứ không như hai control. Chevron giờ đóng hộp cùng chiều cao.

**Next task: M4.10aj · Deck card chừa chỗ cho Study.**

### M4.10aj · Deck card ba dải chia lại việc, và chừa sẵn chỗ cho Study

- **Status:** done
- **Goal:** Card thấp hơn bản gốc nhưng vẫn có chỗ cho nút Study về sau, không
  phải dựng lại lần nữa.
- **Scope:** `deck_tile_widget.dart`; `design-parity-checklist.md`.
- **Out of scope:** bản thân nút Study — cần session, thuộc M5.
- **Dependencies:** M4.10ai
- **Checklist phases:** 7
- **Tests required:** toàn bộ suite, gồm visual audit và golden.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Card 120px hôm nay, 128px khi Study về — vẫn thấp hơn bản gốc 168.
  - [x] Dải chân là một hàng thật, Study chỉ việc điền vào.
  - [x] 1021 test pass, mọi gate xanh.

**Cắt hẳn dải chân là đóng cửa cho verb thứ hai.** M4.10ai gộp thanh tiến độ và
chip due vào một hàng, xuống 100px — và chủ dự án chỉ ra hai điều tôi bỏ sót:
card như vậy **chật**, và kit có **ba** thứ ở dải chân (chip due, nút Study, ⋮)
nên Study sẽ không có chỗ về.

**Chia lại việc thay vì xoá dải.** ⋮ lên dải 1, ở cùng chỗ với danh tính của
deck. Dải chân còn đúng hai *verb*: cái đang chờ, và việc để làm với nó. Nhờ đó
dải chân cao **32** (chiều cao pill) thay vì **48** (chiều cao icon button) —
đây là chỗ khác kit, cố ý, đã ghi vào parity checklist.

**Bỏ mũi tên `›`.** Nó nói "chỗ này mở ra một cấp nữa", mà cả card giờ đã nói
điều đó bằng cách chính nó là target; đứng cạnh một control thật thì nó đọc ra
như control thứ hai không làm gì. Cái row được làm bằng gì vẫn còn: glyph trong
well, và số sub-deck trên dòng meta.

**Luật cần chốt trước M5:** kit chỉ vẽ pill Study khi `due > 0`. Mời học một deck
đã xong hôm nay là mời làm một việc không có nội dung — nhưng đó là luật nghiệp
vụ, chưa chốt.

**Next task: M4.10ak · Deck card chốt hình, hai kit.**

### M4.10ak · Deck card: nút Study, thanh nền, và cân lại padding — cả hai kit

- **Status:** done
- **Goal:** Chốt hình dạng deck card sau một vòng review giao diện, và đưa **cả**
  Flutter lẫn design kit về cùng một trạng thái.
- **Scope:** `deck_tile_widget.dart`, `deck_study_button_widget.dart` (mới),
  `deck_icon_area_widget.dart` (tách ra), `deck_due_state_widget.dart`,
  `mx_card.dart`, `mx_progress_bar.dart`, ARB en+vi, `deck_list_level_test.dart`,
  allowance của visual audit; `MxProgressBar.{jsx,d.ts,prompt.md}`, `mx.css`,
  `DeckLevelScreen.jsx`, `_adherence.oxlintrc.json`.
- **Out of scope:** nối nút Study vào phiên học — issue #89, thuộc M5.
- **Dependencies:** M4.10aj
- **Checklist phases:** 7
- **Tests required:** case Study trong `deck_list_level_test.dart`; toàn bộ suite.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** `lib/features/deck/presentation/widgets/deck_study_button_widget.dart`
- **Acceptance criteria:**
  - [x] Card 134px, **đều** ở cả ba trạng thái due.
  - [x] Study filled, chỉ khi `due > 0`; không có due thì `%` đứng chỗ đó.
  - [x] Padding trên/dưới cân 16/16 tính từ mặt sơn.
  - [x] Thanh nền 6px, vuông đầu, bị **card** cắt chứ không tự cắt.
  - [x] Kit khớp từng điểm; 1022 test pass, mọi gate xanh.

**Cắt sai đối tượng, không phải thiếu clip.** Thanh tiến độ ở đáy card "lòi ra
ngoài" vì `ClipRRect` bọc **chính thanh**: bán kính 16 bị co xuống bằng chiều cao
thanh (luật `RRect`), nên nó bo góc *của thanh* trong khi mặt card ở dải cuối đã
cong vào ~5px. Chỗ duy nhất biết hình học thật là card, nên `MxCard` tự cắt nội
dung — `overflow:hidden` bên kit. Hai đầu pill là lớp lỗi thứ hai nằm trên nó:
`MxProgressBarShape.flush`.

**Track 6px làm góc *khít hơn*, không hụt hơn.** Thụt ngang tại mép trên thanh là
`r − √(r² − (r−h)²)`: với r=16, h=4 → 5,4px; h=6 → 3,5px.

**Padding "đúng" ở cả hai đầu mà mắt vẫn thấy lệch.** Trên đo từ mép hộp, dưới đo
từ mặt sơn: pill vẽ 32 trong hộp 48 (sàn chạm), nên đã trống 8 trước khi cộng
padding. `lg` dưới → `sm`: 8 + 8 = 16, khớp trên.

**Nút Study có mặt trước cả tính năng.** Chưa có phiên học (M5), nên nó trả lời
bằng snackbar thay vì nuốt cú chạm — repo từ chối control bật sáng mà không đi
đâu, và một lời đáp là thứ tách nó khỏi loại đó. Nhờ vậy bố cục đem review là bố
cục thật. Guard đòi TODO có mã ticket nên mở issue **#89** thay vì bịa mã.

**Ba lỗi tự tạo trong lượt này, tự bắt:** (1) label nút lấy `labelMedium` nguyên
khối nên kèm màu chữ mặc định — chữ đen trên nền brand, visual audit đo 2,33:1;
đặt `onPrimary` tường minh. (2) hằng số chừa chỗ cho card chưa có thẻ là literal
`4`, track lên 6 thì nhịp lệch 2px — giờ đọc `MxProgressBarSize.sm.trackHeight`.
(3) assertion a11y đầu tiên pass rỗng vì `MxCard` gộp semantics thành một node.

**Phân kỳ có chủ ý với kit, đã ghi vào parity:** Study filled (kit lập luận
outlined để cột card không ồn — cân nhắc rồi, chủ dự án chọn nhấn mạnh); thanh ở
**đáy** card thay vì giữa; ⋮ nằm với danh tính deck thay vì ở dải chân. Kit đã
được cập nhật theo cả ba.

**Next task: M4.10al · Ô search cân giữa breadcrumb và panel.**

### M4.10al · Ô search cân lại giữa breadcrumb và hero panel

- **Status:** done
- **Goal:** Khoảng mắt thấy từ chữ breadcrumb xuống ô search ≈ từ ô search
  xuống panel, với breadcrumb và panel đứng yên — chỉ ô search trượt.
- **Scope:** `deck_subheader_widget.dart`, `deck_summary_section_widget.dart`;
  `mx.css` (`.mx-today`).
- **Out of scope:** mọi khoảng cách khác — đã đo và đạt từ các vòng trước.
- **Dependencies:** M4.10ak
- **Checklist phases:** 7
- **Tests required:** toàn bộ suite; đo geometry xác nhận span bất biến.
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Chữ breadcrumb → search: 36 → 24. Search → panel: 16 → 28.
  - [x] Panel top và breadcrumb không đổi vị trí (span 84 giữ nguyên, đo được).
  - [x] Kit khớp (`.mx-shell__sub` gap sm vốn có; `.mx-today` md → xl).
  - [x] 1022 test pass, mọi gate xanh.

**Giá trị và chính comment của nó cãi nhau.** `spacing: AppSpacing.lg +
AppSpacing.xs` (= 20) lọt vào ở squash của #86, trong khi comment ngay trên nó
vẫn lập luận cho `sm` — và kit chưa bao giờ rời 8. Cộng với 16px không khí vô
hình dưới chữ (strip 48 cho sàn chạm, chữ 16), khoảng mắt thấy phía trên ô
search thành 36 so với 16 phía dưới: ô search đọc ra như bị tách khỏi chrome
của nó và dính vào nội dung cuộn bên dưới — ngược đúng luật proximity, vì
subheader là chrome ghim còn panel trượt dưới nó.

**Chia đôi tuyệt đối là bất khả trên lưới 4px.** Quỹ đệm 36 cố định, nửa là 18
— không phải bội của 4. Gần nhất: 24/28 theo mắt, và 4px lệch đặt về phía
proximity muốn — search nhích về breadcrumb, không phải về panel.

**Next task: M4.10am · Bucket hoá presentation/widgets.**

### M4.10am · `presentation/widgets` chia bốn bucket, enforce ở ba nơi

- **Status:** done
- **Goal:** 18 widget phẳng của deck vào bốn bucket cố định
  (`sections/` · `items/` · `overlays/` · `support/`), và biến cách xếp này
  thành contract toàn app mà feature sau clone được nguyên vẹn.
- **Scope:** 18 `git mv` + 26 file sửa import (screens, widgets, tests);
  AD-15 trong `docs/architecture.md`; `CLAUDE.md`; hai skill
  (`flutter-architecture`, blueprint của `flutter-feature-slice`);
  `lib/features/deck/README.md`; `design_system/github.md`;
  `lib/core/error/failure.dart` (comment path đã stale từ trước);
  test bucket trong `architecture_boundary_test.dart`; rule
  `memox.architecture.widgets_grouped_into_buckets` + matcher `file_path` mới
  trong guard engine.
- **Out of scope:** cây test (nhóm theo behavior, không mirror bucket);
  WBS/report lịch sử (giữ nguyên path cũ như hồ sơ); `controllers/` (7 file,
  phẳng vẫn đọc được — cùng luật có thể áp sau nếu cần, là quyết định riêng).
- **Dependencies:** M4.10al
- **Checklist phases:** 4, 5
- **Tests required:** toàn bộ suite; test bucket mới kiểm tiêm lỗi đủ ba hình
  dạng sai (file ở gốc, bucket lạ, nesting sâu); guard cũng kiểm tiêm lỗi đủ ba.
- **Editable documents:** `docs/wbs.md`, `docs/architecture.md`, `CLAUDE.md`
- **Output:**
  `code-verification-guard-v2/code_verification_guard/matchers/file_path_matcher.py`
- **Acceptance criteria:**
  - [x] 18 file đúng bucket theo contract AD-15, import tính lại bằng script,
        `flutter analyze` 0 issue, không đổi class/hành vi/public API nào.
  - [x] Ba hình dạng sai đều bị bắt ở cả harness lẫn guard (đã tiêm lỗi, đã đỏ,
        đã gỡ, đã xanh lại).
  - [x] 1022 test pass, mọi gate xanh.

**Guard tự bắt bản nháp đầu của chính luật này, và đó là phát hiện đáng ghi.**
Cách hiển nhiên để enforce bucket bằng rule `file_name` là include/exclude đẽo
gọt + pattern never-match — nhưng trạng thái khoẻ mạnh của rule đó là *target
set rỗng*, và runner có sẵn diagnostic `guard.config.rule_without_targets` coi
đúng hình dạng đó là rule chết. Trả lời đúng không phải là tắt diagnostic mà là
thêm matcher `file_path` vào engine (enum + matcher + registry, theo đúng
plugin-style có sẵn): pattern khớp trên đường-dẫn-tương-đối-repo, target set
khoẻ mạnh là toàn bộ file widget, và **một** rule phủ cả ba hình dạng sai thay
vì hai rule never-match.

**Import không thay chuỗi mù mà tính lại:** script resolve từng import tương
đối theo thư mục cũ của file, rồi re-relativize theo thư mục mới — vì file bị
move đổi cả độ sâu (`../../../../core/` thành `../../../../../core/`) lẫn quan
hệ với hàng xóm (labels từ sibling thành `../support/`).

Phân công enforcement ghi trong AD-15 và nhắc ở cả ba nơi: AD giữ danh sách
canonical, boundary test giữ hình dạng đầy đủ + anti-vacuous mức app, guard là
lưới thứ hai; `check_architecture.sh` cố ý đứng ngoài — nó sở hữu suffix, và
một luật hai bản trong hai script là hai bản sẽ trôi khỏi nhau.

**Next task: M4.10ao · Component theme lấy đúng typography, chip sở hữu đủ state.**

### M4.10ao · Theme lấy đúng token, và bốn lỗ hổng enforcement được bịt

- **Status:** done
- **Goal:** Đóng năm phát hiện của vòng review theme: component theme dùng
  `AppTypography`, `ChipThemeData` sở hữu mọi interaction state, parity CSS↔Dart
  được tự động hoá, duration có guard thay cho rule đã tắt, và hai hệ audit
  thôi đưa ra hai kết luận trái nhau.
- **Scope:** `app_theme.dart` (build `texts` một lần, truyền vào 6 slot);
  `app_chip_theme.dart` (viết lại quanh `ChipThemeData.color`);
  `app_button_themes.dart` (`disabledSurfaceTint` nhận ground, đặt tên 5 alpha);
  `app_overlay_themes.dart` (`kTooltipWaitDuration`);
  rule `memox.design_token.no_raw_duration`; predicate dùng chung
  `isTranslucentFillViolation`; `docs/architecture.md` + `IMPORT_LEDGER.md`
  (progress/streak đã có counterpart Dart).
- **Out of scope:** `chipTheme.iconTheme` vẫn là `onSurfaceVariant` ở mọi state
  — `IconThemeData` trong `ChipThemeData` không resolve theo state được, và
  icon của pill là trang trí; nếu muốn nó theo label thì phải đổi cách
  `MxPillButton` dựng avatar, là quyết định riêng.
- **Dependencies:** M4.10am
- **Checklist phases:** 7, 12
- **Tests required:** 5 file test mới; fault injection cho cả ba guard mới
  (typography, duration, parity).
- **Editable documents:** `docs/wbs.md`, `docs/architecture.md`,
  `design_system/IMPORT_LEDGER.md`
- **Output:** `test/design_audit/css_tokens.dart`,
  `test/design_audit/color_rule_scope.dart`
- **Acceptance criteria:**
  - [x] 6 component theme resolve đúng rung của app; test tiêm lỗi bắt được cả
        ở mức hành vi lẫn mức source.
  - [x] Mọi tổ hợp state của chip resolve ra màu **đục**; disabled-selected
        khác cả selected lẫn disabled; widget test đọc `Ink` để chứng minh
        Material thật sự dùng theme.
  - [x] Parity test parse CSS bắt được ba lớp lỗi: đổi giá trị, đổi màu, và
        **thêm** token mới.
  - [x] `no_raw_duration` bắt literal ẩn danh, tha named const — đã tiêm cả hai
        chiều.
  - [x] `violations.json` từ 1 xuống 0; V5 và R7 dùng chung một predicate.
  - [x] 1107 test pass, `flutter analyze` 0 issue, guard 68 rule xanh.

**Ba trong năm phát hiện có chung một hình dạng: luật đúng, nhưng không ai
kiểm.** `ThemeData.textTheme` được build đúng và có test riêng — chỉ là component
theme lấy `base.textTheme`, nên `labelLarge` của pill chạy weight 500 trong khi
`Theme.of(context).textTheme.labelLarge` nói 600. Hai họ font trùng nhau, nên nó
sống sót qua review. CSS được tuyên bố là nguồn chuẩn ở AD-05, nhưng test chép
tay số nên sửa CSS xong mọi gate vẫn xanh. `flutter.no_hardcoded_duration` bị tắt
có lý do, và không ai viết rule thay thế.

**Chip là hình dạng còn lại: framework default vô hình với source scan** — đúng
loại AD-05 rule 5 gọi tên. Khai báo `backgroundColor`/`selectedColor` mà không
khai `color` để Material trả lời cho phần còn lại, và câu trả lời của nó là
`onSurface` ở **alpha** 12% cho disabled (đúng thứ R7 tồn tại để cấm) cùng
nguyên vẹn `secondaryContainer` cho disabled-selected — một pill không bấm được
trông y hệt pill bấm được. Không dòng nào trong `lib/` nói hai điều đó.

**Hai hệ audit cãi nhau thì báo cáo mất tác dụng, chứ không phải màu sai.** V5
đánh dấu mọi `opacity-modified-token` ngoài shadow/scrim; R7 cố ý tha alpha cho
label. Cùng một nhãn disabled vừa hợp lệ với gate vừa là violation trong report
— và "sửa" nó theo report sẽ làm gate đỏ. Một violation không hành động được là
cách một báo cáo ngừng được đọc. Nay cả hai đi qua `isTranslucentFillViolation`.

**Một lệch parity thật lộ ra và cố ý không sửa:** `--color-disabled-surface` của
kit là `#E3E3E6`/`#312E4E`, còn Dart dẫn xuất ra `#E0E0E5`/`#33324F`. Ledger đã
ghi lý do giữ dẫn xuất — nó tự đi theo khi surface ladder đổi — nên test khoá
bằng **dung sai 4 đơn vị** thay vì đẳng thức: đủ rộng cho khoảng chép tay, quá
hẹp cho một token bị trỏ lại. Comment trong `app_button_themes.dart` ghi
`#E3E3E6` là số đo cũ, đã sửa theo số đo lại.

**Next task: M4.10an · Nền tảng chung cho interaction state, stroke và motion.**

### M4.10an · Interaction state, stroke token và reduced motion về tầng common

- **Status:** done
- **Goal:** Mọi trạng thái tương tác quan trọng (hover · pressed · focus ·
  disabled · selected) được **khai báo** ở tầng common thay vì rơi về default
  của Material, ba bề rộng nét có token semantic, và animation hữu hạn tôn trọng
  reduced motion của hệ điều hành.
- **Scope:** ba file token/policy mới dưới `lib/core/theme/` (`app_stroke.dart`,
  `app_interaction_states.dart`, `app_motion_policy.dart`);
  hai field mới trên `AppSemanticColors` (`disabledSurface`, `onDisabled`);
  `app_theme.dart`, `app_button_themes.dart`, `app_overlay_themes.dart`,
  `app_chip_theme.dart` (gộp với M4.10ao); `MxCard`, `MxListTile`, `MxActionButton`,
  `MxTextButton`, `MxProgressBar`, `MxSearchField`; `test/support/ink_probe.dart`
  và test ở 8 file; `design_audit/` sinh lại; `test/design_audit/`
  `audit_scan_steps.dart` thêm file theme mới vào `declarationSites`.
- **Out of scope:** `MxSnackbar` / feedback coordinator; responsive
  tablet/desktop; settings theme-mode / locale / text-scale; routing, Riverpod,
  domain, repository, Drift; component shared mới; `lib/features/**` (hai chỗ
  `Border.all` ở deck vẫn dùng width mặc định — không có literal để thay).
- **Dependencies:** M4.10am
- **Checklist phases:** 7, 12, 13
- **Tests required:** stroke token so với `design_system/tokens/elevation.css`;
  contract state ở tầng theme; chuột và bàn phím **thật** trên `MxCard` và
  `MxListTile` ở cả light lẫn dark; reduced motion trên `MxProgressBar` và
  `MxSearchField` với cả hai giá trị của cờ.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/app_stroke.dart` ·
  `lib/core/theme/app_interaction_states.dart` ·
  `lib/core/theme/app_motion_policy.dart` ·
  `test/support/ink_probe.dart` · `test/shared/widgets/mx_list_tile_test.dart`
- **Acceptance criteria:**
  - [x] `AppStroke.hairline/input/focus` khớp `--border-hairline/input/focus`,
        kiểm bằng cách **parse CSS** chứ không chép tay.
  - [x] Không còn state quan trọng nào của button / card / list item rơi về
        default Material; ngoại lệ có chủ ý là `MxTextButton` và breadcrumb
        (link-like, state nằm trên chữ).
  - [x] Focus trên card và row là **ring 2px**, không phải chỉ đổi màu; đo được
        là không có layout shift ở hover / pressed / focus.
  - [x] `MxProgressBar` và `MxSearchField` trả `Duration.zero` khi
        `disableAnimations`; giá trị cuối, màu, semantics và callback không đổi.
  - [x] 1063 test pass; `flutter analyze` 0 issue; guard xanh; 4 golden đổi có
        chủ đích, đã render và kiểm bằng mắt ở cả hai chế độ.

**Ba lỗi thật mà việc "khai báo state" phơi ra, và không lỗi nào nhìn thấy được
trong source trước đó.** (1) `MxActionButton.destructive` truyền
`FilledButton.styleFrom(backgroundColor: error)` — `styleFrom` dựng một
`WidgetStatePropertyAll` phẳng, và property non-null của widget **che property
của theme cho mọi state**: nút destructive không tối đi khi nhấn, và khi disabled
vẫn đỏ nguyên dưới một nhãn 38%. (2) `FilledButton` primary phủ overlay 6%
`primary` lên nền `primary` — hover **vô hình**; kit quy định `.mx-btn--primary`
hover là lerp 6% về phía ink, tức một phép trộn chứ không phải một lớp phủ. (3)
`MxCard` và `MxListTile` không khai bất kỳ màu tương tác nào, nên hover / focus /
splash đến từ `ThemeData.hoverColor` — một wash đen hardcoded, không mang seed,
giống hệt nhau ở light và dark. Cả ba vô hình với `design_audit/` vì nó quét
source, còn default của framework không tồn tại trong source.

**Độ trễ tooltip tách khỏi `AppDurations`, và task này nhường tên cho M4.10ao.**
500ms là độ trễ tương tác, không phải thời lượng chuyển động; đặt nó vào
`AppDurations.slow` sẽ phá chính hợp đồng của file đó — `slow` được mô tả là
**trần** của motion. Bản nháp ở đây đặt tên nó là `AppDelays.tooltipWait` trong
file riêng; M4.10ao merge trước với `kTooltipWaitDuration` đứng cạnh theme duy
nhất đọc nó, và **hai tên cho một giá trị chính là thứ task này tồn tại để
chống**, nên bản đã merge thắng. Reduced motion cố ý không đụng tới nó: tooltip
bật ngay khi con trỏ chạm sẽ nháy ở mọi lần lướt qua một toolbar icon. Spinner
indeterminate cũng giữ nguyên: chuyển động của nó *là* thông tin.

**Bảng alpha gộp làm một.** M4.10ao đặt `kPressedOverlayAlpha` /
`kFocusedOverlayAlpha` / `kHoveredOverlayAlpha` / `kDisabledTintAlpha` /
`kDisabledForegroundAlpha` trong `app_button_themes.dart`; `AppStateOpacity` là
tập cha của chúng — nó còn giữ bốn trọng số hover riêng cho row / icon / control
/ card kèm selector `mx.css` của từng cái. Sau merge chỉ còn một bảng, và
`app_chip_theme.dart` (bản đầy đủ của M4.10ao) đọc từ đó, cùng
`AppInteractionStates.focusRing` mà nút và card đã dùng.

**Ba mâu thuẫn design/code phát hiện được, xử lý theo thứ tự nguồn.**
- `design_system/tokens/colors.css` khai `--color-disabled-surface:#E3E3E6` /
  `#312E4E`; phép trộn mà code chạy cho ra `#E0E0E5` / `#33324F`, lệch ~3/255.
  Kit là bản **chép lại** từ một comment cũ trong `app_button_themes.dart`, nên
  giữ giá trị code đang render và ghi nhận ở đây. Token mới nằm trong
  `AppColors` — luật MX-VIS-002 R2 giữ mọi colour literal ở đó, và bản nháp đầu
  đặt chúng cạnh alpha trong `app_interaction_states.dart` đã bị
  `color_source_rules_test.dart` bắt — còn test buộc nó bằng đúng phép trộn.
- `mx.css` tự mâu thuẫn với chính nó: comment đầu file nói press là overlay 12%
  ở mọi nơi, còn rule `.mx-card__action:active` ngay dưới đó nói 10%. Rule thắng
  comment — cùng thứ tự ưu tiên mà `document-conventions.md` §9 đặt ra.
- `readme.md` nói hover trên row là "8% neutral"; `mx.css` `button.mx-tile:hover`
  nói 7%. `mx.css` là nguồn cho hành vi component, nên 7% thắng.
- **Chưa xử lý, cần người quyết:** `.mx-iconbtn:focus-visible` dùng
  `--color-primary`, mà `primary` ở dark đo được **2.81:1** trên surface — dưới
  ngưỡng 3:1 của WCAG 1.4.11 cho focus indicator. Token `--color-focus-ring` tồn
  tại và đạt 5.36:1 dark / 7.41:1 light, `mx.css` đã dùng nó cho nav và nút
  Study. Đổi màu ring là **thay đổi pixel dựa trên một mâu thuẫn chưa có nguồn
  canonical**, nên task này chỉ token hoá bề rộng và giữ nguyên màu.

**`design_audit/` xuống 0 violation** (từ 1): V5 duy nhất còn lại là
`onSurface.withValues(alpha: 0.38)` trong `MxTextButton`, nay đọc
`semantic.onDisabled`. `app_interaction_states.dart` được thêm vào
`declarationSites` của audit vì state layer **về bản chất** là trong suốt — nền
của nó là bề mặt mà control tình cờ ngồi lên — đúng miễn trừ mà shadow và scrim
đã có, và chính rule V5 nêu `overlayColor` là trường hợp nó muốn nói tới.

**Test dùng sự kiện thật, và cái đó buộc phải viết một probe.** Đọc
`inkWell.overlayColor.resolve({hovered})` chỉ chứng minh một property đã được
gán — nó pass y hệt khi con trỏ không bao giờ tới control. `test/support/`
`ink_probe.dart` lái chuột thật rồi đọc lệnh vẽ trên `_RenderInkFeatures`; nó
quét **mọi** lớp ink (`MxCard` tự dựng Material của nó, `MxListTile` vẽ vào lớp
của `Scaffold`) và so màu theo ARGB đóng gói, vì `InkHighlight` animate alpha
bằng số nguyên nên token khai `alpha: 0.04` chạm canvas ở `10/255`.

**Next task: M4.10ap · Focus ring đạt ngưỡng, và hai lỗ hổng enforcement còn lại.**

### M4.10ap · Focus ring lên semantic token, guard duration và scale parity khép kín

- **Status:** done
- **Goal:** Đóng ba phát hiện của vòng review M4.10ao: focus ring không đạt
  3:1 ở dark, guard duration không phủ nơi regression thật sự xảy ra, và scale
  parity không có completeness.
- **Scope:** `focusRingSide()` + `kFocusRingWidth` trong `app_button_themes.dart`
  và ba nơi gọi (chip, outlined button, icon button); scope
  `ui_and_theme_surfaces` + regex bỏ qua dòng comment cho `no_raw_duration`;
  `widthPerNavigationDestination` đổi từ private thành public; completeness cho
  6 file token còn lại; `CssTokens.tokenFileNames()`.
- **Out of scope:** giá trị `primaryDark` — nó được giữ ở luminance đó có lý do
  (một filled button không được là thứ sáng nhất trên trang navy); vấn đề là
  dùng nó làm focus ring, không phải bản thân nó.
- **Dependencies:** M4.10ao
- **Checklist phases:** 7, 12, 13
- **Tests required:** `focus_ring_contrast_test.dart` (8 test, 4 nền × 2 mode);
  `css_scale_coverage_test.dart`; fault injection cho cả ba.
- **Editable documents:** `docs/wbs.md`, `docs/architecture.md`
- **Output:** `test/core/theme/focus_ring_contrast_test.dart`,
  `test/design_audit/css_scale_coverage_test.dart`
- **Acceptance criteria:**
  - [x] Ba component vẽ focus ring đều đi qua `focusRingSide`; đo được ≥3:1
        trên **cả bốn** nền ở cả hai mode.
  - [x] `no_raw_duration` bắt được đúng regression tooltip khi tiêm lại vào
        `app_overlay_themes.dart`; named const vẫn được tha.
  - [x] Completeness bắt token scale mới; anti-vacuous bắt cả **file** token mới.
  - [x] 1121 test pass, `flutter analyze` 0 issue, guard 68 rule xanh.

**Đảo một quyết định vừa land ở M4.10an, và đây là lý do.** M4.10an gom focus
ring về `AppInteractionStates.focusRing` — đúng về cấu trúc, và task này giữ
nguyên helper đó. Nhưng nó chọn `primary` với lập luận "`semanticColors.focusRing`
là hue của viền *input*". Hai điểm bác lập luận đó: kit không nhất quán với chính
nó (`.mx-deck__study:focus-visible` dùng `--color-focus-ring` trên một **button**,
nên token đó không phải của riêng input), và quan trọng hơn — số đo. `primary`
trượt 3:1 ở dark trên đúng hai nền mà control được focus nằm lên. AD-05 đã có
tiền lệ cho đúng tình huống này: theo kit là theo *cách* nó dùng token, và khi
một giá trị của kit rơi vào lỗi tương phản thì app lệch đi và ghi lại lý do.

**Test cũ khẳng định đúng cái giá trị đang sai.** `mx_pill_button_theme_test.dart`
pin `focused?.color == colorScheme.primary` — nó pass, và nó pin một màu đo được
**2.11:1** trên chính `secondaryContainer` mà pill selected dùng làm nền. Một
test viết bằng cách đọc giá trị hiện có sẽ đồng ý với bug. Nay nó pin qua
`focusRingSide`, còn con số thì `focus_ring_contrast_test.dart` đo.

**Đo trên nền thật, không trên một nền danh nghĩa.** `primaryDark` đạt 3.29:1
trên `background` — nếu chỉ kiểm nền trang thì đã pass. Nó hỏng ở `surface`
(2.90) và hỏng nặng nhất ở `secondaryContainer` (2.11), tức đúng hai nền mà một
control được focus thực sự nằm lên. Comment của `iconButtonTheme` viện dẫn ngưỡng
3:1 trong khi vẽ một màu không đạt nó.

**Guard scoped sai thì không bắt được chính ca nó được viết ra để chặn.**
`ui_surfaces` cố ý loại `lib/core/theme/**` — đúng cho màu và radius, vì ở đó
literal *chính là* token. Duration không như vậy: `AppDurations` khai báo ba rung
của nó dưới dạng **named const**, và mọi duration hợp lệ khác trong repo cũng
thế, nên thư mục theme không cần miễn trừ nào — trong khi nó lại là nơi
`Duration(milliseconds: 500)` từng nằm ẩn danh. Scope mới `ui_and_theme_surfaces`
đưa theme vào, lookahead giữ domain ở ngoài.

**Rule bắt chính tài liệu của nó.** Sau khi mở scope, `no_raw_duration` đỏ ở
`app_overlay_themes.dart:75` — dòng doc comment giải thích *không được viết*
`Duration(milliseconds: 500)`. Repo đã gặp đúng lỗi này một lần (R8 khớp chữ
`platformBrightness` còn sót trong comment giải thích nó). Lookahead nay bỏ qua
dòng bắt đầu bằng `//` hoặc `*`.

**Next task: M4.10aq · Audit slot ThemeData theo chuẩn hiện đại.**

### M4.10aq · ThemeData slot audit — bịt slot thiếu, dọn slot mồ côi

- **Status:** done
- **Goal:** Mọi slot component theme có renderer đang chạy đều được khai báo,
  slot sống lâu hơn renderer của nó bị gỡ, và các knob toàn cục quyết định
  geometry được pin thay vì rơi về default theo platform.
- **Scope:** `textButtonTheme` (`buildTextButtonTheme` + `textLinkForeground`
  trong `app_button_themes.dart`, hấp thụ style inline của `MxTextButton`);
  `app_radio_theme.dart` mới (`RadioListTile` của deck form vốn render hoàn
  toàn theo default Material); `iconTheme`; `visualDensity: standard` +
  `materialTapTargetSize: padded`; bốn wash fall-through
  (`hoverColor`/`focusColor`/`highlightColor`/`splashColor`) mang alpha của
  `AppStateOpacity`; hai blend `textHoverBlend`/`textPressedBlend` về
  `AppStateOpacity`; gỡ `floatingActionButtonTheme` (FAB đã bỏ ở M4.10ag) và
  `useMaterial3` (default từ 3.16); gỡ clause compact của textButton (link
  zero-padding không có padding để thu); `MxNavigationBar` thôi khai
  `labelBehavior` lần hai; `MxActionSheet` đọc `onDisabled` thay hằng 0.38
  riêng; widgetbook thêm `BuilderAddon` bọc `CompactScaleWidget` để viewport
  320 của catalog chạy đúng compact scale.
- **Out of scope:** slot không có renderer và không nằm trong lộ trình
  (elevated/segmented/switch/checkbox/slider/tab/menu/search/badge/banner/
  datePicker/timePicker/dataTable…); ThemeExtension per-component; đổi
  `listTileTheme.selectedColor`; panel geometry trùng lặp ở 3 widget deck
  (việc tầng component, không phải tầng theme); `.mx-shell__fab` phía kit.
- **Dependencies:** M4.10ap
- **Checklist phases:** 7, 12, 13
- **Tests required:** state resolution của text link và radio ở cả hai mode;
  sàn tương phản cho nhãn link (4.5:1) và mark radio (3:1); compact scale
  **không** đụng `textButtonTheme`; `labelBehavior` đo hành vi hiệu dụng.
- **Editable documents:** `docs/wbs.md`, `docs/reviews/design-parity-checklist.md`
- **Output:** `lib/core/theme/app_radio_theme.dart` ·
  `lib/core/theme/app_input_theme.dart` (input family tách khỏi
  `app_theme.dart` khi file chạm guard 400 dòng — cùng seam với button/chip/
  overlay)
- **Acceptance criteria:**
  - [x] `textButtonTheme` giữ nguyên từng giá trị `MxTextButton` từng render —
        golden của nó **zero-diff**, đó là bằng chứng migration trung thực.
  - [x] Radio khai đủ selected / resting / disabled / hover / press / focus ở
        cả hai mode; mark selected là `primaryAccent` vì `primary` đo 2.90:1
        trên card dark, dưới ngưỡng 3:1 của WCAG 1.4.11.
  - [x] Widget test đo hành vi hiệu dụng (`widget ?? theme`) thay vì thuộc
        tính widget, nên một quyết định chỉ còn một chỗ khai.
  - [x] Toàn bộ test pass; analyze 0 issue; 2 golden action-sheet đổi có chủ ý
        (hằng 0.38 → token `0x61`, lệch 1 nấc kênh màu); parity checklist thêm
        B14/B15/E13 và Round 3.

**Điều tra trước khi làm** (chuẩn ngoài: `ThemeData` stable có 48 slot; flex
color scheme theme 40 — nhưng đó là package tổng quát): app đã khai 24 slot,
đủ Tier 1 trừ đúng `textButtonTheme`. Kết luận giữ nguyên luật của repo —
*chỉ theme cái gì đang render* — thay vì chạy theo con số 40; hai lỗ hổng
thật là slot có renderer mà không khai (textButton, radio), và một slot khai
mà không còn renderer (FAB). `cardTheme` giữ lại có chủ ý làm lưới an toàn
cho `Card` trần/3rd-party, đổi doc thay vì xoá.

**Hai knob geometry là bug parity E2E thật:** default theo platform cho trình
duyệt desktop `compact` density và `shrinkWrap` tap target, nghĩa là Playwright
đo một geometry mà Android không bao giờ render. Pin `standard`/`padded` là
khai báo giá trị Android đang dùng, không phải đổi hành vi release.

**Một quyết định cần người dùng và đã hỏi:** giữ ripple M3 trên Android thay
vì `NoSplash` toàn cục theo kit — ghi thành divergence #5 (E13) với
counter-argument của kit giữ nguyên trong checklist; `splashColor` giờ mang
màu wash của kit nên ripple loang đúng alpha 12% của `primary`.

**Cùng lập luận với M4.10ap, ở một control khác.** Task trước chuyển focus
ring khỏi `primary` vì nó đo 2.90:1 trên `surface` ở dark; mark của radio là
đúng loại đối tượng đó — một glyph trên nền trần, không phải một mảng fill —
nên nó nhận `primaryAccent` chứ không phải `primary`, và con số hỏng là cùng
một con số.

**Commit của task này mang sai ID trên subject.** Squash commit `139733b` (#98)
ghi `(M4.10ap)` vì nó được viết trước khi #97 land và giành mất ID đó; việc đánh
số lại chỉ kịp vào nội dung, không vào subject. `git log --grep M4.10aq` vì thế
không tìm ra nó — dòng này là chỗ để tìm. Không rewrite lịch sử của `main` cho
một dòng subject.

**Next task: M4.10ar · Chuẩn bị nền trước khi clone sang Card.**

### M4.10ar · Card lên chuẩn golden feature, và guard nhìn thấy được nó

- **Status:** done
- **Goal:** Trước khi M4.11 dựng presentation cho Card, đóng bốn lớp defect mà
  Deck đã mắc và đã sửa nhưng Card vẫn còn — vì domain/data của Card viết ở
  M4.9, **trước** đợt hardening M4.10b — để feature thứ hai không nhân bản
  chúng và trở thành tiền lệ cho feature thứ ba.
- **Scope:** ba commit.
  1. **Layout + guard.** `architecture_boundary_test` giữ `domain/`, `data/`,
     `presentation/` đúng bucket như AD-15 đã giữ `presentation/widgets/`;
     Card và Review chuyển vào bucket (`data/local/` không phải tên AD-12),
     màn Study vào `presentation/screens/` kèm companion visual audit.
  2. **Hardening.** `CardText` value object (constructor private), contract
     nhận `CardText`, xoá validate trùng ở data layer, `domain/failures/` ba
     file với enum reason, bốn use case, `di/` + binding + bootstrap.
  3. **README + vệ sinh.** Sửa ~12 câu đã trôi trong README của Deck, gỡ
     `.gitkeep` thừa, đồng bộ `_kListBottomInset` bị sót.
- **Out of scope:** presentation của Card (đó là M4.11); phân trang keyset —
  xem quyết định bên dưới; gỡ `watchRootDecks`/`watchDeckTree` chết.
- **Dependencies:** M4.10aq
- **Checklist phases:** 4, 5, 14
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/card/{domain/{models,failures,usecases},di}/`,
  `test/features/card/domain/`, `test/features/card/data/support/`
- **Acceptance criteria:**
  - [x] Rule bucket viết **trước**, chạy cho đỏ, báo đúng 10 file thuộc hai
        feature; fault injection xác nhận bắt cả hai dạng lỗi.
  - [x] Contract nhận `CardText`; `card_repository_impl` không còn tham chiếu
        luật nào; sáu `ConflictFailure` và hai `NotFoundFailure` mang reason.
  - [x] `cardRepositoryProvider` đi qua composition root — contract **thứ hai**
        từng làm vậy.
  - [x] 1189 test pass, analyze 0 issue, guard xanh, DoD mechanical xanh.

**Lỗ hổng guard là phát hiện đáng giá nhất, và nó rộng hơn dự đoán.**
`check_suffix` chọn file theo path fragment `/domain/entities/`,
`/data/datasources/`. Card khớp **không rule nào** — nên mọi rule đó pass mà
không soi file Card nào, còn bộ đếm scope cuối script vẫn khác 0 vì một mình
Deck thoả. Card không hề *tuân thủ*; nó **vô hình**. Đúng lớp defect mà comment
của chính script mô tả (sáu check match 0 file, đọc như là có phủ), quay lại
bằng cửa khác. Rule mới bắt được 10 file thuộc **hai** feature — Review cũng
vô hình y hệt.

**Hai lỗi của chính Deck bị phát hiện khi soi để clone, và đã sửa ở cả hai.**
(1) Use case validating khai trả `Future` nhưng `refuse*Form` ném **đồng bộ**,
nên refusal thoát ra *trước khi* future tồn tại và `catchError` không thấy —
trong khi mọi failure khác đều đến qua future. Một controller viết theo
`.catchError` sẽ crash với card sai và bắt được lỗi database, tức đúng ngược
lại. Nay ba use case của Deck và hai của Card đều `async`, có test khoá lại và
fault injection xác nhận. (2) `_kListBottomInset` bị sót ở nhánh search.

**Hai chỗ cố ý KHÔNG clone từ Deck.** `parseCardSides` là một helper thay cho
khối parse/refuse/`StateError('unreachable')` sáu dòng mà Deck chép nguyên vào
từng use case validating — với Card có hai mặt và hai lệnh ghi thì đó sẽ là bốn
bản sao. Và bảng liệt kê tên class trong README đổi thành trỏ tới thư mục: mọi
cái tên trong đó đều đã sai, vì một bản sao chép tay của thứ compiler đã giữ
thì bản chép tay là bản nói dối.

**Cập nhật sau review thiết kế — hình dạng đã chốt và tầng data đã làm.** Đoạn
dưới là lập luận lúc dừng lại; sau khi soi UC-04 thì lộ ra một dữ kiện đổi hẳn
kết luận: **thứ tự cũ-trước đặt thẻ vừa tạo ở cuối deck**, tức đúng luồng chính
UC-04 A4 rơi vào trường hợp tệ nhất, và muốn thấy thẻ mới thì cửa sổ buộc phải
mở gần hết deck — mà `watch()` đọc lại cả cửa sổ đó sau **mỗi** lần thêm.

Chốt: `created_at DESC, id DESC` + `LIMIT :limit` **không cursor, không
`OFFSET`**. Một stream, cửa sổ lớn dần, đọc lại nguyên vẹn — nên insert phía
trên không thể làm trùng hay mất dòng như cửa sổ có offset. Tổng số card là
**query riêng**: `COUNT(*) OVER ()` cạnh các dòng sẽ buộc SQLite duyệt hết tập
kết quả và huỷ đúng khoản lợi mà `LIMIT` mua được.

**Phân biệt bị hiểu sai lúc đầu, đã sửa:** phép đo 1193µs → 102µs là index xoá
`USE TEMP B-TREE FOR ORDER BY` — và **cửa sổ `LIMIT` hưởng trọn khoản đó**.
Mệnh đề cursor chỉ cần khi có thứ nhảy sâu mà không đọc phần phía trước; không
luồng MVP nào làm vậy vì chưa có search thẻ (S1). Nên keyset là tối ưu cho một
access path chưa tồn tại.

Đo lại trên SQLite thật (`card_list_window_test.dart`), deck 800 thẻ: cửa sổ
50/200/800 = **1,75 / 4,29 / 16,87 ms** — chi phí theo cửa sổ chứ không theo
deck. `EXPLAIN QUERY PLAN` xác nhận dạng `DESC` vẫn dùng
`idx_cards_deck_created` và **không** sinh temp B-tree; điều này được assert
chứ không giả định, vì quét ngược index chỉ miễn phí khi mọi cột sắp cùng chiều.

**Điều kiện xem xét lại keyset** (ghi ra để lần sau không phải tranh luận từ
đầu): người dùng thường xuyên vượt 500 thẻ hiển thị · p95 của load-more vượt
ngân sách · search cần kết quả vô hạn · có deep link hoặc jump tới một thẻ · có
đồng bộ nhiều nguồn làm danh sách đổi liên tục.

**Còn nợ ở M4.11:** nửa presentation của phép đo — end-to-end từ DB invalidate
tới UI ổn định, **trên thiết bị Android mục tiêu**, ở 50/500/3.000 dòng. Số ở
trên là debug VM trên máy dev, không phải số của thiết bị.

<details><summary>Lập luận lúc dừng lại (giữ nguyên để đối chiếu)</summary>

**Phân trang keyset: cố ý chưa làm, và đây là lý do.** `docs/wbs.md` đo được
5.000 card đọc trọn 37,8ms so với một trang 50 là 1,6ms, index
`idx_cards_deck_created` đã dựng sẵn cho đúng mệnh đề keyset, và
`feature_blueprint.md` cảnh báo retrofit sau sẽ đổi cả state shape, controller
lẫn widget. Nhưng **acceptance criteria của M4.11 đang tự mâu thuẫn**: nó không
có tiêu chí phân trang nào, lại có tiêu chí "card list tự cập nhật qua stream"
— mà một trang keyset không thể là `watch()` cả bảng. Cửa sổ lớn dần bằng
`LIMIT` thì không phải `OFFSET` nhưng đọc lại từ đầu mỗi lần, nên tới trang 99
nó thoái hoá về đúng 37,8ms mà phép đo muốn tránh. Chọn hình dạng nào là quyết
định **gắn với UI** (cửa sổ lớn theo cái gì, ai giữ cursor), và đoán mò ở tầng
contract rồi phải đổi lần hai là đắt hơn chờ. **M4.11 MUST chốt hình dạng đó ở
bước thiết kế, trước dòng code đầu tiên, và sửa lại tiêu chí "tự cập nhật qua
stream" cho khớp.**

</details>

**Còn nợ, ghi lại để không quên:** `watchRootDecks` và `watchDeckTree` không có
caller nào trong `lib/` nhưng vẫn nằm trên contract, kéo theo 5 tầng mỗi cái
cộng 2 query `.drift` và hai bản fake. Gỡ chúng cần trỏ lại 4 test reactivity
sang `watchAllDecks` và quyết định số phận test `watchDeckTree covers every
depth` — một quyết định về độ phủ test, nên tách thành thay đổi riêng thay vì
kèm vào đây.

**Next task: M4.10as · Promote cái Card chắc chắn cần, ở caller thứ hai.**

### M4.10as · Form sheet và bảng copy lỗi lên `shared/`

- **Status:** done
- **Goal:** Những thứ Deck đang giữ private mà Card chắc chắn cần được promote
  **trước** khi Card tự viết lại — đúng luật của repo: promote ở caller thứ hai,
  không phải caller thứ nhất. Caller thứ hai vừa tới.
- **Scope:** `lib/shared/widgets/mx_form_sheet.dart` (`showMxFormSheet` +
  `MxFormHost<P extends Enum>`, tách khỏi `deck_actions_widget.dart`);
  `lib/shared/widgets/mx_failure_labels_widget.dart` (`mxWriteFailure` giữ
  switch exhaustive không `_`, nhận hai callback cho `NotFoundFailure` và
  `ConflictFailure`); key ARB chung `writeErrorMessage` (en + vi); Deck nối vào
  cả hai; `mx_form_sheet_test.dart` 5 test; `mx_stress_test.dart` mở rộng danh
  sách miễn trừ kèm lý do từng mục.
- **Out of scope:** promote `MxIconWell`, `MxNotice`, `_DueStateBox` — Card
  **có thể** cần nhưng chưa chắc, và một caller vẫn là một phỏng đoán. Chờ màn
  card list có hình dạng rồi quyết. Entry widgetbook cho form sheet: hoãn có lý
  do, xem dưới.
- **Dependencies:** M4.10ar
- **Checklist phases:** 7, 14
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/shared/widgets/mx_form_sheet.dart` ·
  `lib/shared/widgets/mx_failure_labels_widget.dart` ·
  `test/shared/widgets/mx_form_sheet_test.dart`
- **Acceptance criteria:**
  - [x] Deck hành vi không đổi; 1204 test pass, analyze 0 issue, hai guard xanh.
  - [x] Fault injection: bỏ view inset → test bàn phím đỏ; đổi `shouldClose`
        thành `outcome != null` → hai test host đỏ.
  - [x] `mxWriteFailure` giữ switch exhaustive không nhánh `_`; hai loại failure
        mang nghĩa của feature là **required callback**, nên một feature không
        thể để chúng rơi vào câu chữ chung do quên.

**Bẫy bàn phím là lý do chính, và nó đã dính một lần.** Doc comment của
`_showFormSheet` ghi rõ: thiếu `isScrollControlled` **cộng** view inset thì
sheet bị chặn ở nửa màn và bàn phím che nút submit — một form không submit được
nếu không tắt bàn phím trước. Card editor có hai ô tối đa 2000 ký tự, tức đúng
ca tệ nhất. Để Card tự cấu hình `showModalBottomSheet` lần nữa là mở lại đường
cho lỗi đó.

**`MxFormHost` được viết sẵn cho Card từ trước.** Nó đóng theo *transition*
`shouldClose` chứ không theo "đã thành công", và comment gốc nói thẳng: Deck
không có form add-another nào, viết thế này để lúc clone sang một form như vậy
thì không sai âm thầm. Card editor **chính là** cái clone đó. Generic hoá theo
`SubmitState<P extends Enum>` vì host ghim vào enum của Deck là host Card không
dùng được — đúng hình dạng mà việc promote này gỡ bỏ.

**Bảng copy lỗi: 7/12 nhánh đổ về đúng một câu, và câu đó không có gì thuộc về
deck** — `deckWriteErrorMessage` nghĩa đen là "Please try again.". Phần thật sự
của feature chỉ có 4 nhánh: *cái gì* không còn (NotFound) và *vì sao* bị từ chối
(ba dạng Conflict). Giá trị lớn nhất của bản gốc là switch exhaustive không
`_` — một `Failure` subtype mới không compile được cho tới khi có người quyết —
và giữ nó ở **một** chỗ nghĩa là Card thừa hưởng luôn thay vì tự dẫn lại; mà
tự dẫn lại chính là cách một trong hai bản mọc ra nhánh `_`.

**Một điều test tự phát hiện về chính nó.** Bản đầu giả lập bàn phím bằng widget
`MediaQuery` bọc quanh nút mở sheet, và đo được inset **0**. Sheet là một route:
nội dung của nó dựng dưới Navigator nên đọc `MediaQuery` của app, không bao giờ
thấy cái bọc quanh nút. Phải set ở `tester.view.viewInsets`. Một test giả lập
sai kiểu đó sẽ báo đỏ và trông y hệt như lỗi của sheet.

**Widgetbook: hoãn có lý do.** Cả hai thứ không có layout riêng —
`MxFailureLabelsWidget` không chứa widget nào, `MxFormSheet` là một cấu hình
`showModalBottomSheet` cộng một host trả nguyên child. Một use-case catalog cho
nó sẽ đang trưng bày *form của caller*, không phải component. Khi card editor
tồn tại thì có form thật để trưng, và đó là lúc thêm — cùng lập luận "caller thứ
hai mới cho biết cái gì thay đổi".

**Next task: M4.10at · Schema v2 và phép quy chiếu trạng thái thẻ.**

### M4.10at · `tags`, `card_tags`, `is_flagged` và bốn trạng thái thẻ

- **Status:** done — schema, migration, domain primitive, DAO/named query đủ.
  Bảo chứng reset không đụng `is_flagged`/`card_tags` chuyển sang M5.x cùng
  đường reset của repository (chưa có caller); cascade `card_tags` đã kiểm.
- **Goal:** Đưa schema và luật mà màn card cần lên trước, để M4.11 dựng hàng thẻ
  **một lần** theo hình dạng cuối thay vì dựng rồi sửa.
- **Scope:** migration v2 (`tags`, `card_tags`, `cards.is_flagged` và ba trường
  phụ `example` / `hint` / `pronunciation`); **BR-08 siết 2000 → 60/240**, kéo
  theo `CardSide.maxLength` thay cho một hằng dùng chung; DAO và
  named query cho tag, cờ và bộ đếm theo trạng thái; phép quy chiếu bốn trạng
  thái (BR-89…BR-91) đặt cạnh scheduler tương ứng, **hai** hàm chứ không một;
  value object `TagName` với private constructor (BR-93); bất biến mới cho
  `card_tags`; migration test từ v1.
- **Out of scope:** mọi UI. Màn card, chip tag, pill lọc và panel tiến độ đều
  thuộc M4.11 — task này chỉ mở đường. `card_media` vẫn để sau.
- **Dependencies:** M4.10as
- **Checklist phases:** 11.1, 11.2, 15.1
- **Tests required:** migration v1→v2 giữ nguyên dữ liệu; `is_flagged` mặc định
  0 cho thẻ cũ; unique tag không phân biệt hoa thường **có dấu tiếng Việt**;
  cascade hai chiều của `card_tags`; quy chiếu trạng thái ở biên box 3/4 và 7/8,
  và ở biên `interval_days` 7/8 và 127/128; reset giữ nguyên cờ và tag (BR-41).
- **Editable documents:** `docs/wbs.md`, `docs/data-model.md`,
  `docs/business-rules.md`
- **Output:** `lib/core/database/tables/`, `lib/core/database/queries/`,
  `lib/features/card/domain/`
- **Acceptance criteria:**
  - [x] Migration v1→v2 chạy trên DB v1 thật, không mất dòng nào.
  - [x] `TagName` chặn rỗng-sau-trim và quá 50 ký tự ở **kiểu**, không ở caller.
  - [x] `Động từ` và `động từ` va nhau ở fold — tức không phải `NOCASE`. Ở mức
        value object; ràng buộc UNIQUE trên DB kiểm khi DAO có.
  - [x] Bốn trạng thái suy ra đúng ở cả hai scheduler, kiểm ở từng biên.
  - [x] `mastered` đọc lại BR-88 — không share code được giữa `.drift` và Dart,
        nên `card_state_test.dart` **parse `deck.drift`** và so ngưỡng, cùng
        cách các test parity CSS làm. Đã tiêm lỗi.
  - [ ] Reset learning progress không đụng `is_flagged` và `card_tags`. Chưa
        kiểm được ở đây: đường reset sống trong repository của Deck và chưa có
        caller nào; cascade hai chiều của `card_tags` thì đã kiểm.
  - [ ] Mặt trước 240 ký tự bị từ chối, mặt sau thì không — hai giới hạn thật
        sự khác nhau, không phải một hằng dùng chung.
  - [ ] Ba trường phụ trim rồi quy chuỗi rỗng về NULL, không lưu chuỗi rỗng.

**Vì sao task này chen vào trước M4.11 thay vì gộp vào nó.** Màn hình tham chiếu
mà chủ dự án đưa vẽ tag, cờ và một panel tiến độ bốn trạng thái — không cái nào
có schema. Nếu M4.11 làm cả hai nửa thì migration và UI nằm chung một PR, và
hàng thẻ phải dựng hai lần: một lần cho `front`/`back`, một lần nữa khi tag và cờ
tới. Tách ra thì M4.11 chỉ còn là UI trên một hình dạng dữ liệu đã cố định.

**Một lỗi schema mà chỉ test ở tầng DB mới thấy.** `UNIQUE (owner_id,
name_folded)` đọc như đúng, và enforce **không gì cả**: SQLite coi mọi NULL là
khác nhau trong unique index, còn MVP chưa có auth nên `owner_id` NULL ở *mọi*
dòng. `TagName` fold đúng, index tồn tại, và hai tag `Động từ` vẫn vào được cả
hai. Sửa bằng `COALESCE(owner_id, '')`. Test value object không thể bắt được
điều này — nó đúng ở tầng của nó.

**Quy chiếu trạng thái đặt cạnh scheduler, không đặt ở widget.** BR-89…BR-91 là
luật nghiệp vụ; một `switch` trong `CardTile` đọc `current_box` sẽ là bản sao thứ
hai của chúng, và bản sao đó không có test nào của scheduler chạm tới. Hai hàm
riêng vì AD-06 cho hai scheduler state khác nhau — một hàm chung buộc phải đọc
cột NULL của scheduler kia.

**Next task: M4.11 · Card management full-stack.**

### M4.11 · Card management full-stack

- **Status:** **done** (11/11 lát + recursive review) — lát 1 (card list + create editor tối giản) **done**;
  lát 2 (edit-mode + delete/danger-zone) **done** — `getCard` một-phát để prefill,
  `CardEdit`/`CardDelete` controller, editor rẽ hai nhánh (title, prefill, ghi chú
  BR-10, không có save-and-add ở edit), overlay xác nhận xóa dùng `MxConfirmDialog`
  destructive, route `:cardId/edit` (tên `cardEditorEdit`), strict visual audit
  thêm state `edit`;
  lát 3 (cờ end-to-end, BR-92) **done** — `setCardFlag` use case + repo (ghi đúng
  một cột `is_flagged`, `NotFoundFailure` nếu thiếu card), `CardFlag` controller
  optimistic + revert khi ghi lỗi, toggle cờ ở app bar editor (filled/outline),
  icon cờ trên hàng card dùng `onSurface` — không `primary`, vì accent đo 3,29:1
  trên nền tối, dưới 4,5:1 cho glyph;
  lát 4 (tag end-to-end, BR-93/BR-94) **done** — `TagEntity` + mapper,
  `addCardTag` (find-or-create theo `name_folded`, link idempotent
  `insertOrIgnore`, cap 10 tag trong transaction), `removeCardTag`,
  `watchCardTags` stream; use case `AddCardTagUseCase` (parse TagName, refuse
  trước repo) / `Remove` / `Watch`; `CardTagEntry` controller + `cardTags`
  stream; section tag trong editor edit mode (chip xóa được + field thêm +
  counter `n / 10`). Audit editor tách field-count theo mode (edit có 3 field).
  lát 5 (hàng card đầy đủ: state, D5) **done** — read gộp `cardListItemsByDeck`
  (`c.**, s.**`, INNER JOIN total nhờ BR-09) → projection `CardListItemModel`
  (state suy bằng `cardStateOf`), use case + đổi `CardList` sang projection; tile
  vẽ chấm trạng thái (màu map vào token semantic có sẵn info/warning/primaryAccent/
  success — chấm là non-text nên 3:1 đủ, không thêm token mới nên 2 kit khỏi phân
  kỳ) + front + back + nhãn trạng thái (`onSurfaceVariant`). Audit list đo cả chấm
  lẫn nhãn;
  lát 6 (badge hạn + fix CQS, D5) **done** — model thuần `dueBadgeOf(dueAt, now)`
  → sealed `CardDueBadge` (now/phút/giờ/ngày, coarse), `CardListNow` (now từ
  clockProvider, refresh khi resume — mirror `DeckListNow`, không widget đọc đồng
  hồ), badge ở góc phải hàng (cột flag + badge). **Đồng thời sửa vi phạm CQS/
  provider mà `test/app` bắt (slice 3/4 lọt vì trước chỉ chạy test/features):**
  `cardTags`/`cardFlag` thành query-stream `noAutomaticRetry` build-only; tách
  `CardFlag` (Future+toggle, vi phạm query) thành `cardFlag` stream + `SetCardFlag`
  command (`watchCardFlag` mới ở repo/DAO); tách `CardTagEntry.add/remove` thành
  `CardTagEntry.submit` + `CardTagRemove.submit`; đổi typedef `CardTagState` →
  `CardTagSubmitState` để test phân loại đúng command controller. Còn: tag chip
  trên hàng, filter pills All/Due/New/Flagged, panel tiến độ, optional details,
  breadcrumb + tên deck, auto-forward. Ghi chú: tag ở create mode hoãn — card chưa
  có id để link;
  lát 7 (optional detail fields, BR-95) **done** — value object `CardDetailText`
  (empty→null, ≤240) + enum `CardDetailField` + 3 problem `tooLong` +
  `parseCardForm` gộp 2 mặt và 3 detail, refuse một lần; create/update use case +
  repo + DAO ghi 3 cột (null = clear); section "Add details" mặc định collapse
  (W4), tự mở khi card đã có detail (W5), 3 field example/hint/pronunciation, nhãn
  và icon dùng `primaryAccent` (không `primary` — accent-as-text mới đạt 4.5:1 ở
  nền tối). Audit editor không đổi (InkWell dùng chung Material ink);
  lát 8 (tag chip trên hàng, BR-93) **done** — `cardListItemsByDeck` thêm subquery
  `GROUP_CONCAT(t.name, char(31))` (live theo `card_tags`), `CardListItemModel`
  mang `tagNames`, mapper tách theo unit-separator; tile vẽ chip viền
  (`borderSubtle`, text `onSurfaceVariant`) trên dòng state (Wrap để tràn dòng ở
  màn hẹp); tách `build()` tile thành `_StateDot`/`_CardFace`/`_TrailingBadges`
  cho qua guard max_build_lines;
  lát 9 (filter pills All/Due/New/Flagged, D3) **done** — 3 query list lọc
  (due/new/flagged) + due/new count trong `card.drift`; enum `CardListFilter`;
  repo dispatch qua record `CardListItemRow` chung (mọi filter một map); tách
  phần đọc-danh-sách ra `CardListReadDataSource` để impl < 400 dòng;
  `CardListFilterSelection` (reset window bằng `ref.invalidate`, không thêm
  mutator vào window để giữ CQS) + 4 count provider; `CardFilterBarWidget`
  (FilterChip, count trên từng pill) ở subheader, ẩn khi deck rỗng; empty-theo-
  filter (`_NoMatch`). Audit list thêm allowance cho `_RenderChip`/ink 8/no-
  painter 5/rasterNotFlat chip;
  lát 10 (panel tiến độ deck, D5) **done** — `CardStateDistributionModel`
  (total + 4 band, `masteredFraction`) đọc từ `cardStateCountsByDeck` có sẵn
  (map trong `CardListReadDataSource`, `?? 0` cho SUM nullable);
  `watchCardStateDistribution` use case + `cardProgress` stream provider;
  `CardProgressPanelWidget` (vòng mastered `success`/track `progressTrack`, thanh
  phân bố bốn màu `info`/`warning`/`primaryAccent`/`success` khớp
  `card_state_widget.dart`, legend) là header index 0 của list, tự ẩn khi total 0;
  audit list thêm `drive: pumpAndSettle` (stream phân bố tới sau list một frame) +
  allowance customPainter cho `_CircularProgressIndicatorPainter`;
  lát 11 (breadcrumb + tên deck + auto-forward, W1) **done** — query card-side
  `deckContextById` (tên + content_type + ancestryJson, một snapshot) trong
  `card.drift`; `DeckContextModel`/`DeckBreadcrumbSegment` (card-side, không import
  deck presentation — AD-13), mapper decode JSON root-first mirror `deckPathFromJson`;
  `DeckContextReadDataSource` (watch header + `readDeckHoldsCards` một lần, tách
  khỏi impl để giữ <400 dòng); contract `CardRepository` thêm `watchDeckContext` +
  `readDeckHoldsCards`; use case + `deckContext` stream provider; title màn = tên
  deck (fallback `cardListTitle`), subheader = `CardBreadcrumbWidget` (dùng
  `MxBreadcrumb` shared) trên filter pills. Auto-forward: `_cardDeckRedirect` trong
  `app_router.dart` — async route redirect đọc `readDeckHoldsCardsUseCase` qua
  `ProviderScope.containerOf`, chỉ chạy khi `topRoute == deckDetail` (tránh loop),
  lỗi thì không forward (deck screen tự xử lý); `DeckCardHandoffWidget` giờ là
  fallback. Test: data read (tên + ancestry root-first, rename live, holdsCards),
  widget (title + breadcrumb), router (forward card-deck / ở lại deck-deck).
  **Recursive review toàn tính năng (11 lát, 69 file) done — sạch, không sửa
  code.** Đã soát mọi layer + `card.drift` + redirect: layering (domain không
  Flutter/Drift), AD-12 (use case mỗi interaction; controller gọi use case),
  AD-13 (card không import deck data/presentation; không `DateTime.now()` trong
  feature — chỉ `clockProvider`; redirect đọc use case card-side qua
  `ProviderScope.containerOf`), AD-15 (widgets bốn bucket), CQS (mọi command
  controller build/submit/reset + `ref.mounted`, giữ input khi lỗi), error →
  `Failure` ở biên repo (không rò Drift/SQL lên UI), band `cardStateOf` khớp SQL
  `cardStateCountsByDeck`, redirect có loop-guard (`topRoute`) + guard lỗi. Hai
  quan sát nhỏ **không chặn, không cần sửa**: (1) hàng `answer_count > 0` mà
  scheduler `unknown` / `current_box` NULL được `cardStateOf` gán `isNew` nhưng
  SQL panel không đếm vào band nào (chỉ `total`) → chỉ xảy ra với dữ liệu
  hỏng/schema mới hơn; (2) audit list chưa set `deckContextToShow` nên không đo
  breadcrumb — `MxBreadcrumb` đã có golden riêng + widget test phủ logic card, nên
  chỉ là fidelity gap. Các method DAO chưa có caller production (`watchAllTags`,
  `watchTagsForCards`, `watchFlaggedCardsByDeck`, `studyStateByCard`) là surface
  có chủ đích cho M5, đã có DAO test — không phải dead code. **M4.11 DONE.**
- **Hậu M4.11 — sửa lỗ hổng BR-61 (chủ dự án phát hiện).** UI đang chặn việc tạo
  card ở deck `unset`: empty state chỉ có nút tạo sub-deck kèm notice
  "card chưa khả dụng", và nút `+` trên app bar đi thẳng vào form sub-deck. Hệ quả
  là **deck `unset` không bao giờ trở thành deck card được** — màn card chỉ mở khi
  `content_type` đã là `card`, mà chỉ card đầu tiên mới đặt được giá trị đó
  (BR-62). Tài liệu **vốn đã đúng**: BR-61 ghi "bấm Create trong sub-deck `unset`
  MUST hiển thị hai lựa chọn"; code mới là chỗ lệch. Đã thêm
  `deck_create_child_widget.dart`: deck `unset` → sheet hai lựa chọn (deck con /
  card, **không disable cái nào**), deck đã chốt type → vào thẳng form tương ứng
  (BR-66). Điều hướng sang editor bằng route name nên deck vẫn không import
  presentation của card (AD-13). Bỏ `deckCreateCardUnavailableMessage`. Test
  `an unset sub-deck offers both kinds` viết lại theo BR-61 thật (trước đó nó
  đang ghim chính hành vi sai).
- **Goal:** Người dùng quản lý card hoàn chỉnh trong deck loại `card`, từ UI
  xuống transaction Drift.
- **Scope:** card list; empty state; tạo card; tạo card **đầu tiên** trong deck
  `unset`; editor front/back; sửa; xoá; luồng *add another*; validation; Riverpod
  state/controller; route; ARB en/vi; `CardTile`/`CardEditor` đặt trong feature.
  Cộng thêm phía presentation của cửa sổ danh sách: `windowSize`, auto-load,
  load-more tường minh, dòng "đang hiện N / M", và hành vi cuộn khi có dòng mới.
  **Cộng phần UI mà M4.10at mở đường:** nhãn bốn trạng thái trên hàng thẻ, chip
  tag, cờ ⚑ và pill lọc theo cờ, panel tiến độ deck (vòng %, thanh phân đoạn,
  "N of M mastered"), và form gán tag trong editor.
- **Out of scope:** review scheduler và nút **Start study** (M5.1); study
answers UI; import/export; media; rich text. **Keyset cursor** — xem điều kiện
  kích hoạt ở M4.10ar; cửa sổ `LIMIT` không cursor là hình dạng đã chốt cho MVP.
  **Sort control và search thẻ** — thứ tự danh sách cố định mới-trước; search là
  S1. Pill lọc theo cờ và theo trạng thái thì **trong** scope: chúng lọc, không
  đổi thứ tự.
- **Wireframe:** [`docs/wireframes/m4-11-card-management.md`](wireframes/m4-11-card-management.md)
  — bố cục chín màn, năm quyết định UI đã chốt (D1–D5). §4 tách trạng thái đích
  (màn tham chiếu của chủ dự án) khỏi lát cắt M4.11, kèm bảng phân tầng từng
  khối. Q8–Q11 đã đóng ở M4.10at; còn mở Q1, Q3–Q7, trong đó **Q6/Q7 chặn code**
  (`windowSize`, hành vi cửa sổ khi quay lại màn).
- **Editable documents:** `docs/wbs.md`, `docs/wireframes/m4-11-card-management.md`
- **Output:** `lib/features/card/`, `lib/l10n/`, `test/features/card/`,
  `test/visual_audit/screens/features/card/`
- **Acceptance criteria:**
  - [ ] `front`/`back` trim không được rỗng, tối đa 2000 ký tự (BR-07, BR-08).
  - [ ] Card đầu tiên khoá `content_type = card` **trong cùng transaction**
        (BR-62, BR-63).
  - [ ] Tạo card sinh **đúng một** study state, khớp scheduler và generation của
        root (BR-09); cả `eight_box` lẫn `sm2` khởi tạo đúng.
  - [ ] Sửa card **không** đụng study state hay history (BR-10).
  - [ ] Xoá card kéo theo study state và history bằng cascade.
  - [ ] Xoá card cuối **không** tự chuyển `content_type` về `unset` (BR-67).
  - [ ] *Add another* giữ editor mở và xoá form sau khi lưu.
  - [ ] Lỗi persistence **giữ lại** nội dung form.
  - [ ] Double-submit không tạo hai card.
  - [ ] Danh sách dùng **một** reactive stream ứng với giới hạn hiện tại; insert,
        update và delete phản ánh lên danh sách mà **không** tạo dòng trùng hoặc
        mất dòng. (Thay cho tiêu chí "card list tự cập nhật qua stream" cũ, vốn
        mâu thuẫn với phân trang khi chưa nói rõ hình dạng cửa sổ.)
  - [ ] Danh sách sắp `created_at DESC, id DESC`; thẻ mới tạo ở đầu danh sách.
        **Thứ tự này là thứ tự quản lý, không quyết định thứ tự học hay review**
        (BR-23 sở hữu thứ tự hàng đợi ôn qua query riêng). Dùng `created_at`,
        **không** `updated_at`: sửa một thẻ cũ mà nó nhảy lên đầu sẽ cướp chỗ
        đang đọc của người dùng.
  - [ ] Tải ban đầu tối đa **50** card; gần đáy thì cửa sổ tăng thêm 50.
  - [ ] Auto-load dừng sau **500** card; quá mốc đó người dùng tải thêm bằng
        hành động tường minh. Đây là **soft cap** — không được khoá hẳn, vì dữ
        liệu tồn tại mà không quản lý được thì tệ hơn một danh sách chậm.
  - [ ] Màn hình hiển thị đúng **số đang hiện / tổng số**, và tổng số lấy bằng
        query riêng — **không** dùng window count (`COUNT(*) OVER ()`) trong
        query có `LIMIT`, vì nó buộc SQLite duyệt hết tập kết quả và huỷ đúng
        khoản lợi mà `LIMIT` cùng index mua được.
  - [ ] Query danh sách **không** dùng `OFFSET`, và query `DESC` dùng index,
        không sinh temporary B-tree. (Đã khoá sẵn ở tầng data:
        `test/features/card/data/card_list_window_test.dart`.)
  - [ ] Sau chuỗi *add another*, quay lại danh sách **thấy ngay thẻ mới mà không
        phải cuộn**; đánh dấu ngắn thẻ vừa tạo hoặc trạng thái "đã thêm".
  - [ ] **Không tự cuộn khi người dùng đang thao tác sâu trong danh sách.** Dòng
        mới xuất hiện phía trên không được giật vị trí đang đọc; nếu sau này có
        write từ nguồn khác thì dùng chip kiểu "Có 3 thẻ mới" thay vì cuộn.
  - [ ] Đo end-to-end **trên thiết bị Android mục tiêu**, không chỉ benchmark
        database: từ lúc DB invalidate tới lúc UI ổn định, ở 50 / 500 / 3.000
        dòng. Ghi số vào WBS. (Nửa SQL đã đo ở M4.10ar: deck 800 thẻ, cửa sổ
        50/200/800 = 1,75 / 4,29 / 16,87 ms — chi phí theo cửa sổ, không theo
        deck.)
  - [ ] Toàn bộ copy từ ARB; không raw style hay token.
  - [ ] 320×568 và `textScaler` 2.0 không overflow.
  - [ ] Mọi production screen có strict visual audit **PASS** ở light và dark.
  - [ ] ~~Screen có design reference đạt pixel difference **dưới 3%**.~~
        **Không áp dụng được:** kit không có màn card list. `design_system/`
        chỉ ship `DeckLevelScreen`, `ReviewScreen`, `SettingsScreen`,
        `DeckForms`, và `ui_kits/memox-app/README.md` nói thẳng "a card editor
        and a card list … there is no screen to copy, so there is none here".
        Thay bằng: dựng màn theo token và component sẵn có, rồi **bổ sung màn
        đó vào kit trong cùng PR** theo luật both-kits-must-match.
- **Dependencies:** M4.10, M4.10ar, M4.10as, M4.10at
- **Tests required:** domain, repository transaction và rollback, controller,
  form validation, widget, visual audit strict, route
- **Checklist phases:** 9.2, 9.3, 14.4, 15.1, 15.2, 15.3, 15.4

### M4.11a · Fold Unicode cho search thẻ (schema v3)

- **Status:** **done** — bốn lệnh bàn giao đã chạy trên máy có toolchain
  (Flutter 3.44.8). Snapshot v3 đã commit, `flutter analyze` sạch,
  `flutter test` 1367/1367 pass, `check_drift.sh` 0 error.
- **Goal:** Search card MUST fold Unicode nhất quán giữa dữ liệu đã lưu và từ
  khoá, đồng thời migration v3 MUST backfill đúng dữ liệu cũ.
- **Vấn đề.** `searchPredicate` so `instr(lower(front), :term)` với `:term` đã
  được Dart hạ hoa. `lower()` của SQLite chỉ fold ASCII, `String.toLowerCase()`
  của Dart fold theo Unicode — hai vế của **một** phép so dùng hai luật khác
  nhau. Hệ quả: thẻ lưu `CÔNG NGHỆ` không tìm ra bằng `công nghệ`. Tiếng Hàn
  không ảnh hưởng (không có hoa/thường), thẻ viết thường cũng không — nên lỗi
  sống sót qua test thủ công trong đúng một app mà nội dung là tiếng Việt và
  tiếng Hàn. `tags.drift` đã ghi rõ chính xác cái bẫy này từ v2 (BR-93) và giải
  bằng `name_folded`; hai mặt thẻ thì chưa được hưởng.
- **Cách sửa.** Cột `cards.front_folded` / `back_folded`, fold trong Dart
  (`CardText.folded`, `CardText.fold` cho từ khoá), search so trên hai cột đó và
  **không còn `lower()` nào ở phía SQL**. Chỉ hạ hoa, không bỏ dấu — `công` vẫn
  không khớp `cong`; tìm không dấu là quyết định sản phẩm (S1), không phải hệ
  quả phụ của một bản vá.
- **Migration v3.** `addColumn` ×2 rồi backfill **bằng Dart**: `SET front_folded
  = lower(front)` sẽ ghi đúng những giá trị hỏng mà cột này sinh ra để thay thế.
  Backfill dùng raw SQL chứ không dùng generated query — API sinh ra luôn mô tả
  schema mới nhất, nên một bước migration dùng nó sẽ vỡ vào ngày v4 thêm cột cho
  `cards`.
- **Scope:** `lib/core/database/tables/cards.drift`, `app_database.dart`,
  `card_text_model.dart`, `card_list_query_mapper.dart`,
  `card_repository_impl.dart`, `test/features/card/data/card_filter_repository_test.dart`,
  `test/database/migration_test.dart`, `docs/data-model.md`.
- **Editable documents:** `docs/wbs.md`, `docs/data-model.md`.
- **Output:** Schema v3, Unicode-folded search columns/query, migration/backfill,
  schema snapshot và regression tests liên quan.
- **Bàn giao — đã chạy, kết quả bên dưới:**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
  dart run drift_dev schema generate drift_schemas/ test/drift/generated/
  flutter analyze && flutter test test/database/ test/features/card/
  ```
- **Acceptance criteria:**
  - [x] Thẻ `CÔNG NGHỆ` tìm được bằng `công nghệ`, và ngược lại.
  - [x] `công` **không** khớp `cong` (fold chỉ hạ hoa).
  - [x] Count và list khớp nhau trên cùng một từ khoá đã fold.
  - [x] `%` và `100%` vẫn khớp theo nghĩa đen (không regress `instr`).
  - [x] v2 → v3 backfill đúng cho cả dòng non-ASCII lẫn ASCII; không dòng nào
        còn giữ default `''`.
  - [x] v1 → v3 trong một lần mở app cũng cho kết quả như vậy.
  - [x] Snapshot v3 đã commit; `check_drift.sh` sạch.
- **Dependencies:** M4.11
- **Tests required:** Card search repository tests, migration/schema/query tests,
  analyzer và Drift guard.
- **Checklist phases:** 11.1, 15.1

**Bốn thứ đỏ mà lệnh thứ tư mới lộ ra.** Code fold là đúng và không phải sửa
dòng nào; cái vỡ là những chỗ *khác* đã chốt cứng "schema là v2":

- `migration_test.dart` còn `expect(db.schemaVersion, 2)`, và nhóm `v1 → v2` gọi
  `migrateAndValidate(db, 2)`. Cái sau không thể đúng nữa: `onUpgrade` rẽ theo
  `from` chứ không theo `to` — hình dạng đúng, vì production luôn nâng tới bản
  mới nhất nên một guard `to >= n` sẽ là nhánh không máy nào chạy. Hệ quả là một
  database v1 **không dừng được ở v2**; nó chạy hết mọi bước. Nhóm đó giờ nâng
  tới `db.schemaVersion` và đổi tên thành "what v2 added, seen from a v1
  database" — điều nó khẳng định là dòng v1 sống sót cả đường, không phải sống
  sót một bước, nên nó cũng không vỡ vào ngày v4 tới.
- `query_test.dart` giữ bản sao thứ hai của phép chốt version. Hai chỗ chốt cùng
  một số nghĩa là mỗi lần bump phải nhớ cả hai — đã sửa số, còn việc gộp thì để
  lại như nợ nhỏ.
- `schema_test.dart` so cột `cards` với `data-model.md`. Tài liệu **đã** có
  `front_folded`/`back_folded` đúng vị trí; chỉ danh sách trong test là chưa.
- `deck_mapper_test.dart` dựng một `Card` row bằng tay và thiếu hai cột mới —
  `flutter analyze` bắt, không phải test bắt. Nhân đó cho front/back chữ hoa và
  folded chữ thường khác nhau, để test chứng minh mapper đọc cột gốc.

**`check_drift.sh` không im như đã đoán, vì lý do khác.** Sau khi snapshot v3 vào
repo nó vẫn báo 9 error — tất cả trong `app_database.g.dart`. Guard quét cả code
sinh ra, nên nó đang báo `customSelect` thiếu `readsFrom` và SQL nội suy của
chính drift, ở một file không ai sửa được và không ai commit. Đã cho nó bỏ qua
`.g.dart` / `.freezed.dart` / `.drift.dart`. Còn lại 1 NOTE về `build.yaml`
vắng mặt, đúng như trước.

**Một test card đỏ sẵn, không liên quan fold.** `card_list_screen_test.dart` đo
"retry re-subscribes both reads" bằng tổng tuyệt đối `cardCountWatchCount == 2`,
trong khi màn hình có **hai** người đọc tổng số thẻ — dòng "Showing X of Y" và
pill *All* (thêm ở #121) — nên tổng đã là 2 trước khi bấm Retry. Hành vi thì
đúng: retry chỉ cần lấy lại list và tổng của nó. Phép đo mới là delta, nên nó đo
việc retry đã làm chứ không đo màn hình đang có bao nhiêu read.

### M4.11b · Thực thi 60 IT scenario trên thiết bị thật

- **Status:** **done** — 60/60 PASS trên emulator Android (AVD `memox_it`,
  flavor development), host regression 1370/1370, analyze/format sạch,
  `check_drift.sh --diff` 0 error. Catalog: 60 READY, 0 FIXTURE-BLOCKED,
  0 KNOWN-GAP (IT-TREE-014 đóng bằng journey app-bar reset có sẵn).
- **Goal:** Mọi scenario trong `docs/it-scenarios/` MUST chạy qua UI như người
  dùng thật; defect tìm thấy MUST sửa tận root cause kèm regression test đúng
  boundary; KHÔNG hạ expected result để test pass.
- **Giao được:** harness/robot/fixtures (`integration_test/support/`) với seam
  `buildRootWidget(database, now)`, clock T0 tick-per-write, watchdog; 8 file
  `it_*_test.dart`; fixtures S-DUE/S-PROGRESS/S-LARGE qua repository thật.
- **Defect sản phẩm:** (1) back-sau-redirect không re-run — ghi nhận, hướng A
  `pushNamed` ở deck list; (2) use case nuốt `sort`/`searchTerm` — sửa +
  `watch_card_list_items_use_case_test.dart`; (3) drift 2.34 bỏ `card_tags`/
  `tags` khỏi `readsFrom` của `cardListItems` (subquery-only) — DAO merge
  `tableUpdates`, pin bằng `card_list_tag_invalidation_test.dart` 2 chiều.
  20 defect harness/automation đã sửa trong suite (IME connection chết sau
  `done`, frozen-clock tie-breaker UUID, finder đo sai bề mặt…).
- **Scope:** `integration_test/**` (harness, robot, fixtures, 8 file
  scenario), fix sản phẩm tối thiểu trong `lib/features/card/**` và
  `lib/features/deck/presentation/screens/deck_list_screen.dart`, seam
  `lib/app/bootstrap.dart`; KHÔNG đổi business rule, KHÔNG đổi schema.
- **Editable documents:** `docs/it-scenarios/**` (catalog, execution guide,
  agent notes), `docs/wbs.md`.
- **Output:** suite 60 scenario chạy được lặp lại trên emulator; 3 regression
  test host mới; catalog 60 READY; báo cáo defect per-ID.
- **Acceptance criteria:**
  - [x] 60/60 scenario PASS qua UI thật, không hạ expected result nào.
  - [x] Mọi defect sản phẩm có root cause + regression test đúng boundary
        (use case seam, repository stream, widget).
  - [x] Host regression không giảm: `flutter test` 1370/1370.
  - [x] `flutter analyze` / `dart format` / `check_drift.sh --diff` sạch.
  - [x] Catalog 60 READY / 0 FIXTURE-BLOCKED / 0 KNOWN-GAP, khớp 1:1 với
        `integration_test/it_*_test.dart`.
- **Dependencies:** M4.11a
- **Tests required:** integration (60 scenario), use-case seam test,
  repository stream-invalidation test 2 chiều, widget boundary test
- **Checklist phases:** 15.4

### M4.11c · Card list: gutter đôi, chữ "due" cho thẻ chưa học, và pill quá rộng

- **Status:** **done** — 1372/1372 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** Ba lỗi UI trên `CardListScreen` mà chủ dự án chỉ ra từ ảnh chụp,
  mỗi lỗi MUST được đo trước khi sửa và đo lại sau khi sửa.
- **Scope:** `card_list_screen.dart`, `card_progress_panel_widget.dart`,
  `app_chip_theme.dart`, `mx.css` (`.mx-pill__body`), `app_en.arb`/`app_vi.arb`,
  fixture `test/demo/card_screens_demo_test.dart`, 3 golden.
- **Out of scope:** predicate của BR-22 và của pill "Due now" — chỉ đổi chữ;
  `CardFilterBarWidget` vẫn dựng `FilterChip` thô thay vì `MxPillButton`.
- **Dependencies:** M4.11
- **Checklist phases:** 7, 12
- **Tests required:** toàn bộ suite; đo geometry trước/sau bằng widget test
  tạm; golden `card_list_light`/`card_list_dark`/`card_editor_edit` sinh lại.
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/design-parity-checklist.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Gutter thân màn 32 → 16, bằng đúng ô search phía trên và bằng deck list.
  - [x] Panel không còn đếm một thẻ hai lần; nút không gọi "due" thẻ chưa học.
  - [x] Pill hẹp lại 8px mỗi bên ở **cả hai** kit, hàng filter 426.4 → 394.4.
  - [x] 1372 test pass, mọi gate xanh.

**Gutter đôi: `MxContentShell` bọc padding, rồi `ListView` bọc lần nữa.** Màn
này không truyền `padding`, nên shell áp `EdgeInsets.all(lg)` quanh body — trong
khi `ListView` bên trong đã có `fromLTRB(lg, md, lg, xxl)` của riêng nó. Đo ở
390×844: ô search và dải pill ở L=16 (chúng lấy gutter từ **default** của shell
chứ không từ tham số), còn panel tiến độ và mọi card row ở L=32. Deck list không
dính vì nó truyền `padding: EdgeInsets.zero` với đúng lý do đó, nên hai màn cạnh
nhau lệch nhau 16px. Sửa giống deck list: shell nhả padding, mỗi nhánh tự giữ
gutter — `ListView` đã có, `MxEmptyState`/`MxErrorState` đã có `xl` của chúng.
Top của `ListView` lên `xl` để bù phần shell nhả ra.

**"1 due · 1 new" là một thẻ đếm hai lần.** BR-22 định nghĩa hàng đợi phiên học
là `due_at IS NULL OR due_at <= now`, nên thẻ vừa tạo nằm trong đó; bảng trạng
thái ở `business-rules.md` lại gọi đúng thẻ ấy là `new`, không phải `due`. Hai
từ vựng, một chữ "due" — và màn hình in cả hai cạnh nhau. Deck một thẻ mới đọc
ra "1 due · 1 new" rồi mời "Start study · 1 due", tức là bảo người dùng có thẻ
đến hạn quay lại trong khi chưa thẻ nào được giới thiệu.

Predicate không đổi — nó đúng, và là hợp đồng của hàng đợi. Chỉ chữ đổi: nút đọc
kích thước hàng đợi ("Start study · N cards") khi trong đó có thẻ từng học, và
đọc "Learn N new cards" khi toàn thẻ mới; dòng meta lấy hiệu hai số nên mỗi thẻ
chỉ đếm một lần. `new ⊆ hàng đợi` là bảo đảm được: BR-09 tạo study state với
`due_at = NULL`, BR-77 mới điền nó ở lượt `scheduled` đầu tiên.

Fixture demo từng khai 23 due / 38 new — bất khả trong dữ liệu thật, và phép trừ
làm lộ ra ngay: golden vẽ "Learn 23 new cards". Đã sửa thành 61 = 38 mới + 23
quay lại.

**Pill: 42px chrome quanh nhãn 27.5px.** `md` ngang cho "All 1" một viên rộng
69.5 mà chỉ 27.5 là chữ. Bốn pill của card list dài 426.4 so với 374 mà màn 390
chừa trong gutter, nên "Flagged" nằm ngoài màn ở **mọi** kích thước hỗ trợ.
Hạ xuống `sm` — đúng mức M3 mặc định — ở cả `app_chip_theme.dart` lẫn
`.mx-pill__body`: 17px mỗi bên, hàng còn 394.4. **Vẫn phải cuộn**: còn thừa 20px,
và đóng nốt là câu hỏi về chữ ("Due now" → "Due"), không phải về padding. Không
hạ token thêm nữa để mua 20px đó — token dùng chung với mọi pill khác trong app,
và chúng không phải bên đang thiếu chỗ.

**Phần chữ ấy đã chốt ngay sau đó, trong cùng task này.** Chủ dự án duyệt rút
nhãn, `"Due now
{count}"` → `"Due {count}"` trong `app_en.arb`; bản `vi` vốn đã là `"Đến hạn
{count}"` nên không đổi. Pill hẹp 38px, hàng còn **361.8** so với 374 — deck có
số đếm một chữ số hiện đủ bốn pill ở màn 390 mà không cần cuộn.

**Nhưng không phải mọi cỡ, và không có mức padding nào đóng được nốt.** Đo tiếp:
360 vẫn tràn 17.8; deck ba chữ số (`All 142`) dài 416.5 ở màn 390. Nhãn nở theo
dữ liệu, nên hàng pill **là** hàng cuộn ngang theo thiết kế — trailing gutter
trong `CardFilterBarWidget` tồn tại đúng cho việc đó. Ghi lại đây để phiên sau
không đọc "đã fit" thành "đã fit mọi lúc" rồi lại đi hạ token.

Một hệ quả cần biết: `robot.tapTextContaining('Due now')` trong
`it_fixture_scenarios_test.dart` thành `'Due 1'` chứ không phải `'Due'` — panel
ngay trên dải pill mang chuỗi "1 due · 1 new", nên tiền tố trần chỉ cách một cú
tap là chạm vào văn xuôi.

### M4.11d · Pill Due tách hẳn khỏi New — đổi predicate, không đổi BR-22

- **Status:** **done** — 1373/1373 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation, `check_generated` sạch.
- **Goal:** Hai pill `Due` và `New` MUST KHÔNG bao giờ cùng mô tả một thẻ, và
  tổng của chúng MUST bằng đúng hàng đợi BR-22.
- **Scope:** `card_list_query_mapper.dart`, `card_list_filter_model.dart`,
  `card_list_filter_controller.dart`, `card_list_controller.dart`,
  `card_repository.dart` (doc), `card_progress_panel_widget.dart`,
  `card_filter_bar_widget.dart`, ARB en/vi, 3 test + 1 IT + 2 fixture.
- **Out of scope:** BR-22 và mọi read của nó (`study.drift`, `deck.drift`);
  badge `now` trên từng hàng thẻ.
- **Dependencies:** M4.11c
- **Checklist phases:** 7, 11, 12
- **Tests required:** repository test trên SQLite thật cho predicate mới **và**
  cho tính phân hoạch; IT-ORG-005; toàn bộ suite; 2 golden sinh lại.
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/design-parity-checklist.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] `Due ∩ New = ∅` và `Due + New = hàng đợi BR-22`, chứng minh bằng test
        trên database thật (`due and new partition the session queue`).
  - [x] `studyQueuePredicate` (BR-22) không đổi hành vi; `study.drift` và
        `deck.drift` không bị đụng.
  - [x] Nút Start study vẫn in kích thước hàng đợi (`Due + New`).
  - [x] 1373 test pass, mọi gate xanh.

**M4.11c mới sửa chỗ hiển thị, chưa sửa chỗ định nghĩa.** Panel đã đếm mỗi thẻ
một lần bằng cách **trừ** `New` khỏi hàng đợi ngay tại widget, nhưng pill `Due`
vẫn là hàng đợi trần — nên deck một thẻ mới vẫn hiện `Due 1` cạnh `New 1`. Trừ ở
tầng trình bày thì chỉ panel được hưởng; đưa phép trừ xuống query thì pill được
luôn, và không còn chỗ nào phải nhớ trừ.

**`duePredicate = studyQueuePredicate & NOT isNewPredicate`.** Phủ định chính
`isNewPredicate` chứ không viết `due_at IS NOT NULL AND due_at <= now`. Hai cách
cho cùng kết quả **hôm nay**, vì BR-09 tạo `due_at = NULL` và BR-77 chỉ điền nó ở
lượt `scheduled` đầu tiên nên `answer_count = 0` kéo theo `due_at IS NULL`. Nhưng
cách thứ hai chỉ đúng chừng nào giả định đó còn đúng; cách thứ nhất **không thể**
rời khỏi định nghĩa của `New` — `New` là gì thì `Due` là phần còn lại của hàng
đợi. Đó là thứ cho phép panel **cộng** hai số lại thành kích thước phiên học mà
không phải là một xấp xỉ.

**BR-22 không đổi, và không được đổi.** `studyQueuePredicate` (đổi tên từ
`dueNowPredicate` cho khỏi nhầm) vẫn là `due_at IS NULL OR due_at <= now`, và
phiên học vẫn lấy cả thẻ mới — `study.drift`, `deck.drift` không bị chạm. Cái đổi
là **bộ lọc UI**, thứ `use-cases.md` chưa bao giờ đặc tả (không có mục filter
nào trong đó), nên đây là quyết định trình bày, không phải sửa luật.

Hệ quả trên fixture: demo trả `due = 23 / new = 38` — chính là cặp số nó đã khai
trước M4.11c, và nút vẫn in 61 vì giờ 61 là tổng chứ không phải một trong hai.
IT-ORG-005 đổi từ `Due 2` sang `Due 1`: bốn thẻ của "Mixed due" gồm một thẻ chưa
mở, một thẻ quay lại, một thẻ hẹn sau, một thẻ đã thuộc — hàng đợi có hai, nhưng
`Due` chỉ nhận thẻ quay lại.

**Còn lại, chưa làm:** badge `now` trên hàng thẻ vẫn dùng BR-22
(`dueBadgeOf(null, now)` → `CardDueNow`), nên một thẻ chưa học vẫn hiện `now`
ngay cạnh nhãn `NEW`. Cùng loại va chạm từ vựng, ở cấp hàng thay vì cấp pill;
tách ra vì nó là quyết định về badge, không phải về bộ lọc. **Đã đóng ở
M4.11e.**

### M4.11e · Badge `now` thôi nói thay cho thẻ chưa có lịch

- **Status:** **done** — 1374/1374 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation, `check_generated` sạch.
- **Goal:** Hàng thẻ MUST KHÔNG trả lời "khi nào đến hạn" bằng `now` cho thẻ
  chưa từng được lên lịch.
- **Scope:** `card_due_badge_model.dart`, `card_due_badge_widget.dart`,
  `card_tile_widget.dart`, `fake_card_repository.dart`, 3 test + 2 fixture,
  2 golden.
- **Out of scope:** BR-22; pill và panel (đã xong ở M4.11c/d); badge của deck.
- **Dependencies:** M4.11d
- **Checklist phases:** 7, 13
- **Tests required:** unit cho `dueBadgeOf`; widget test cho cả hai nhánh
  (có badge / không badge); toàn bộ suite; 2 golden sinh lại.
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] `dueBadgeOf(null, now)` trả `CardNotScheduled`, không phải `CardDueNow`.
  - [x] Hàng thẻ chưa lên lịch không vẽ badge; hàng quá hạn vẫn vẽ `now`.
  - [x] Cụm trailing rỗng không để lại khoảng trống mồ côi.
  - [x] 1374 test pass, mọi gate xanh.

**Nốt cuối của cùng một va chạm.** M4.11c sửa panel, M4.11d sửa pill, và cả hai
lần lý do đều là: BR-22 nói về *hàng đợi phiên học*, còn bảng trạng thái nói về
*thẻ này đang ở đâu*. Badge là chỗ thứ ba đọc BR-22 rồi in ra như thể nó trả lời
câu hỏi thứ hai — `due_at == null` cho ra `CardDueNow`, nên thẻ vừa tạo hiện
`now` ngay cạnh nhãn `NEW`.

**Thêm case `CardNotScheduled`, và không vẽ gì.** Không đặt một chữ khác (kiểu
"chưa lên lịch") vì hàng đã trả lời rồi: thẻ không có `due_at` đúng là thẻ chưa
từng ôn, và nhãn state ngay dưới từ khoá đã ghi `NEW`. Một dấu thứ hai nói lại
cùng một điều bằng chữ khác chính là thứ nhiễu mà badge sinh ra để cắt bớt.
`dueBadgeLabel` do đó trả `String?`, và `null` là nhánh "không có badge" — kiểu
trả về ép mọi call site phải xử lý, thay vì trông cậy vào việc nhớ.

**Cụm trailing tự mang gap của nó.** Cả flag lẫn badge đều có thể vắng, nên hàng
có thể không còn gì bên phải; `SizedBox(width: sm)` do `Row` cha giữ sẽ đứng đó
ôm chỗ cho hư không và bóp mặt trước 8px. Gap chuyển vào trong, và cụm rỗng trả
`SizedBox.shrink()`.

**Fixture phải mang `due_at` thật từ đây.** `FakeCardRepository.listItem` trước
đây luôn tạo `due_at = null`, nên sau thay đổi này mọi hàng trong demo và trong
visual audit sẽ mất badge — độ phủ biến mất mà không test nào đỏ. `listItem`
nhận thêm `dueAt`, demo cấp ngày cho mọi thẻ đã qua `isNew` (đúng BR-77), và
audit giữ một hàng mỗi loại. Ngày dùng là `DateTime.utc(2020)`: một golden mà
nội dung phụ thuộc ngày sinh ra nó là golden hỏng vào hôm sau.

### M4.11f · Nhãn chip thôi mượn weight của button

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation, `check_generated` sạch.
- **Goal:** Chip MUST khai weight của riêng nó. Nó MUST KHÔNG thừa hưởng cú nâng
  `label-lg` 500 → 600 vốn được lập luận cho `FilledButton`.
- **Scope:** `app_chip_theme.dart`, `app_typography.dart`,
  `design_system/components/mx.css`, `component_theme_typography_test.dart`,
  `golden_specimens.dart`, `mx_components_golden_test.dart`, 5 golden.
- **Out of scope:** bậc `label-lg` (vẫn 600 — button cần nó); bề rộng chip và
  hai icon trang trí của toolbar deck; `_TagChip` (là `Container`, không đọc
  `chipTheme`).
- **Dependencies:** M4.10p, M4.11e
- **Checklist phases:** 7
- **Tests required:** `component_theme_typography_test.dart` phải chặn được cả
  hai chiều — weight sai, **và** weight đúng mà trục `wght` sai; golden của
  chính chip.
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/design-parity-checklist.md`
- **Output:** `test/shared/widgets/goldens/mx_pill_group_{light,dark}.png`
- **Acceptance criteria:**
  - [x] `chipTheme.labelStyle` là `label-lg` ở 500, và trục `wght` đi cùng.
  - [x] `.mx-pill__body` mang đúng quyết định đó (`--weight-medium`).
  - [x] Test đỏ khi weight và trục lệch nhau, và tự báo phải xoá khi bậc dịch
        tới gặp nó — kiểm bằng tiêm lỗi.
  - [x] `MxPillButton` có golden; 1400 test pass, mọi gate xanh.

**Chủ dự án nhìn ra trước, phép đo chỉ xác nhận và đặt tên.** Cảm nhận là "chip
to hơn phần còn lại của app, trong khi hint của ô search thì cân đối". Đo trên
ảnh chụp máy thật ở 360dp: chiều cao ascender của `Search` và của `All decks`
**bằng nhau đúng từng pixel** — 27px, cùng 14sp. Chênh lệch nằm ở lượng mực:
0,271 với hint so với 0,340 và 0,364 với hai chip, tức 26–34% nhiều hơn ở **cùng
một cỡ chữ**. Không phải vấn đề size, và sửa size sẽ sửa nhầm thứ.

**Nguyên nhân là một cú nâng đi lạc.** App đặt `label-lg` ở 600 nơi Material 3
đặt 500, có chủ đích và **cho `FilledButton`**: chữ đảo trên nền đặc cần thêm nét.
`ChipThemeData` đọc đúng bậc đó, nên pill thừa hưởng lý lẽ của một bề mặt nó
không có — nó ngồi trên trang sau một hairline 1,50:1, không có fill nào đỡ. Xếp
cả màn theo lượng mực, hai toggle 2-trạng-thái đứng hạng 2 và 3, dưới tên deck
(0,409) và **trên** chính tiêu đề section mà chúng lọc.

**Cái bẫy nằm ở `fontVariations`, không ở `fontWeight`.** Cả hai face đều là
variable font và mọi bậc mang trục `wght`; renderer đọc trục **thay vì**
`TextStyle.fontWeight` khi trục có mặt. Một lần đổi weight chỉ bằng `copyWith`
sẽ **báo** 500 cho mọi test và **vẽ** 600 trên máy. `AppTypography.withWeight`
tồn tại để hai thứ không thể rời nhau, và test khẳng định cả hai — khẳng định
mỗi weight thôi thì pass đúng vào con bug đáng bắt.

**Test cũ pin 600, và nó không sai — nó nói chuyện khác.** Nó ra đời khi mọi
component theme dựng từ `base.textTheme`, tức bậc của Material, và 600 ở đó là
"bậc của app" chứ không phải "weight của chip". Giá trị mới lại đúng bằng 500 —
cùng con số Material trả về hồi đó — nên `expectRungReweighted` phải phân biệt
được *một giá trị* với *một quyết định*: size/leading/tracking vẫn phải là
`label-lg`, weight phải đúng 500, trục phải theo, và nó **tự báo phải xoá** nếu
có ngày bậc dịch xuống gặp nó — một ngoại lệ trùng với luật là ngoại lệ đã chết.

**Lỗ hổng lộ ra khi sửa: `MxPillButton` chưa từng có golden.** Ba golden card đỏ
vì chúng chứa `FilterChip` và `Chip`; màn deck không đỏ dòng nào, và lý do là
golden `deck_list` trong `design_preview/` là một bản dựng tay có từ trước
toolbar. Nên chip — component lặp lại nhiều nhất trong app — không có một pixel
nào bảo vệ. Golden mới đặt hai chip **dưới chính dòng hint** đã dùng để so, vì
một golden chỉ có chip trong đó sẽ ghi lại 600 là đúng: một weight không có gì
để sai khi đứng một mình.

Đo trên chính golden đó, trước và sau, tách từng cụm chữ: `All` 0,345 → 0,317 ·
`decks` 0,286 → 0,255 · `Due` 0,316 → 0,281 · `only` 0,292 → 0,259, trong khi
icon `filter_list` giữ nguyên 0,194 và dòng hint không đổi một byte. Bề rộng chữ
dịch 2px — dấu hiệu của đổi weight chứ không phải đổi size.

**Ba thứ cố ý không làm.** Bậc `label-lg` **giữ 600**: button vẫn cần nó, và hạ
bậc để sửa một component là sửa 40 chỗ để chữa 1. Hai icon trang trí của toolbar
deck (`filter_list`, `swap_vert`) **vẫn còn** — chúng chiếm 16dp cộng khoảng
cách, tức 32dp trong 202dp của cả nhóm, nhưng bỏ icon là quyết định của feature
chứ không phải của `core/theme/`. Và bề rộng chip **không đụng**: `chipTheme`
dùng chung với bốn pill của màn card list, và comment sẵn trong file đã cảnh báo
đúng chỗ đó.

### M4.11g · Màn deck có ảnh, và review render đúng mật độ máy thật

- **Status:** **done** — 1404/1404 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation, `check_generated` và
  `check_docs` sạch.
- **Goal:** Mọi production screen đã dựng MUST có ít nhất một ảnh render thật.
  Review render MUST rasterise ở đúng mật độ mà M4.10w đã chốt.
- **Scope:** `test/demo/deck_screens_demo_test.dart` (mới),
  `test/support/review_render.dart`, `test/demo/card_screens_demo_test.dart`,
  7 review golden.
- **Out of scope:** `design_preview/goldens/deck_list_*.png` — bản dựng tay cũ,
  để nguyên vì nó là chủ thể của một audit riêng; màn Study và Settings.
- **Dependencies:** M4.10w, M4.11f
- **Checklist phases:** 15
- **Tests required:** render thật qua router production ở cả hai cấp và cả hai
  theme; toàn bộ suite.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/demo/goldens/deck_list_{root,level}_{light,dark}.png`
- **Acceptance criteria:**
  - [x] `DeckListScreen` có render thật ở cấp gốc và cấp lồng, light + dark.
  - [x] Cả 7 review golden là 1179×2556, không phải 393×852.
  - [x] Ảnh gồm cả bottom navigation bar.
  - [x] 1404 test pass, mọi gate xanh.

**Màn deck chưa từng có ảnh của chính nó.** `design_preview/deck_list_*.png` là
bản dựng tay có từ trước toolbar, panel tổng kết và breadcrumb — nên nó không
phải ảnh của màn đang chạy mà là bức vẽ lại một màn đã không còn. Đó chính là lý
do M4.11f làm đỏ ba golden Card và **không đỏ dòng nào** bên Deck: bên đó không
có gì để đỏ. Bản mới mount `DeckListScreen` qua router production với database
fake, y như companion audit của nó, nên cái chụp được là màn hình chứ không phải
bản mô phỏng.

**Hai cấp, vì một màn làm hai việc.** Cấp gốc tự xưng "Your decks" và liệt kê
root; cấp lồng thêm breadcrumb, tự xưng "Sub-decks" và resolve scheduler qua
root. Fixture đầu tiên đặt chính parent vào `ancestors` và ảnh lộ ra ngay —
breadcrumb in tên deck hai lần. `ancestors` là chuỗi **trên** parent và không bao
giờ chứa nó; bước cuối của breadcrumb dựng từ parent.

**DPR: hai chỗ đã sửa, và chỗ thứ hai mới là chỗ thật.** `pumpReview` còn chốt
`devicePixelRatio = 1` trong khi M4.10w đã đưa golden nghiêm ngặt và design
preview lên 3 — nên đúng bộ ảnh sinh ra *để người đọc* lại là bộ mờ nhất trong
repo. Nhưng sửa `tester.view` **không đủ**: ảnh vẫn ra 393×852. `captureImage`
đi ngược lên repaint boundary gần nhất rồi rasterise layer đó trong hệ toạ độ
của chính nó, nên một finder trỏ vào màn hình bên trong app luôn cho **pixel
logic** bất kể view khai gì; chỉ ở gốc mới chạm `RenderView`, nơi bounds là vật
lý. Đo bằng probe: `MaterialApp` và `ReviewApp` cho 1179×2556, `Scaffold` cho
393×852.

**Cùng cái finder tự do đó còn cắt ảnh, và cắt im lặng.**
`find.byType(DeckListScreen)` trả về khung thiếu 80px so với surface, vì
navigation bar nằm *cạnh* màn chứ không nằm trong nó — tức mảnh chrome mà người
review cần nhất lại vắng khỏi đúng bức ảnh dành cho việc review. Hai lỗi cùng
một gốc là để caller tự chọn, và cả hai đều không tự khai báo: ảnh trông vẫn
đúng cho tới khi có người đo. Nên `matchesReviewGolden` bỏ hẳn tham số finder.

Trên đĩa: 7 ảnh từ ~40 KB lên 107–175 KB. Layout không đổi một pixel logic nào —
`logical = physical / dpr` — nên không assertion rect nào bị chạm.

### M4.11h · Gỡ bản dựng tay của màn deck khỏi `design_preview`

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation, `check_generated` và
  `check_docs` sạch.
- **Goal:** Một replica MUST KHÔNG tồn tại song song với màn production mà nó
  bắt chước.
- **Scope:** xoá `test/design_preview/deck_list_preview_test.dart` cùng
  `goldens/deck_list_{light,dark}.png`; `preview_harness.dart` (doc),
  `design_system/github.md`, `design_system/ui_kits/memox-app/README.md`.
- **Out of scope:** `_ReviewScreen` và `_SettingsScreen` — hai màn đó chưa tồn
  tại trong `lib/`, nên replica của chúng vẫn đang làm đúng việc của mình.
- **Dependencies:** M4.11g
- **Checklist phases:** 7, 15
- **Tests required:** toàn bộ suite; đếm lại golden so với sàn của `ci-full`.
- **Editable documents:** `docs/wbs.md`, `design_system/github.md`,
  `design_system/ui_kits/memox-app/README.md`
- **Output:** không có file mới
- **Acceptance criteria:**
  - [x] Không còn replica nào của một màn đã có trong `lib/`.
  - [x] Hai tài liệu design kit trỏ sang `test/demo/deck_screens_demo_test.dart`.
  - [x] Golden còn 111, trên sàn 70 của `ci-full.yml`.
  - [x] 1400 test pass, mọi gate xanh.

**Nó không còn là ảnh cũ của màn deck — nó là ảnh của một màn khác.** Replica
hiển thị tiêu đề `Library`, một `FilledButton` full-width
`Study 15 cards due today`, và badge đến hạn dạng chữ. Màn thật đã là `Decks`,
một panel tổng kết có nút đóng, và chip đến hạn ở chân thẻ — từ nhiều tháng
trước. Không một dòng nào trong replica còn đúng.

**Và nó đọc như là coverage.** Ngoài hai golden, file còn chạy một
`memoxAuditTest` — tức bốn test màu trên một widget riêng tư. Audit một replica
chỉ chứng minh replica đúng; đó chính là câu đã viết sẵn trong doc của
`preview_harness.dart` mà không ai áp lại cho chính nó. Bằng chứng mạnh nhất là
M4.11f: đổi weight nhãn chip làm đỏ ba golden Card và **không đỏ dòng nào** bên
Deck — trong khi bên Deck đang có hai golden và bốn test audit.

**Mất đúng 4 test, và không mất một dòng coverage production nào.**
`deck_list_screen_visual_audit_test.dart` audit màn thật ở 8 state (16 test) và
không bị chạm; `test/demo/deck_screens_demo_test.dart` (M4.11g) giữ ảnh ở hai
cấp × hai theme. Golden còn 111 so với sàn 70.

**Hai replica còn lại giữ nguyên, và đó là ranh giới.** `_ReviewScreen` và
`_SettingsScreen` chưa có màn production nào để làm bản sao *của* — `lib/` chỉ
có `StudyPlaceholderScreen`. Chúng vẫn đang trả lời đúng câu hỏi mà một swatch
grid không trả lời được. Khi M5 dựng màn thật, replica tương ứng ra đi theo cùng
cách này.

### M4.11i · Chip về chuẩn M3 trên thang bội-4, và heading thôi thua chip

- **Status:** **done** — 1404/1404 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** Hai chip `All decks` / `Recent` MUST cân đối với `YOUR DECKS` bên
  cạnh và với nút Study bên dưới, và việc chuẩn hoá MUST KHÔNG làm chip nào
  khác tràn.
- **Scope:** `app_chip_theme.dart`, `mx_pill_button.dart`,
  `deck_list_toolbar_widget.dart` (một dòng rung chữ), `.mx-pill__body` trong
  `mx.css`, 9 golden.
- **Out of scope:** nhãn/màu/icon/hành vi của chip; bố cục quanh nó.
- **Dependencies:** M4.11h
- **Checklist phases:** 7
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/design-parity-checklist.md`
- **Output:** không có file mới
- **Tests required:** đo geometry trước/sau; `mx_stress_test` ở 320×568
  `textScaler` 2.0; toàn bộ suite; 9 golden sinh lại sau khi chủ dự án duyệt ảnh
- **Acceptance criteria:**
  - [x] Container 32 · touch target 48 · icon 16 · padding ngang 12 · gap
        icon–nhãn 4 · gap giữa chip 8, đo trên render thật.
  - [x] Hai bên chip cân nhau (13/13 kể cả hairline), không còn 11/17.
  - [x] Không chip dùng chung nào tràn; card list filter row **hẹp lại**.
  - [x] 320×568 @ 2.0 không overflow.
  - [x] Bo góc giữ nguyên pill; ảnh render được duyệt trước khi chốt golden.

**`labelPadding` mặc định là thứ gây lệch, không phải padding.** Material xếp
chip là `padding.left │ avatar │ labelPadding.left │ label │ labelPadding.right │
padding.right`, và mặc định `labelPadding` là 8 **cả hai bên**. Với chip có
avatar, 8 đó rơi trọn vào mép phải: đo được 11 trái / 17 phải. Zero nó ở theme
là sửa gốc — sau đó `padding` là thứ duy nhất giữa mép và nội dung, nên 12 nghĩa
là 12, và chip không icon ra 13/13 (12 + hairline).

**Icon phải rời slot `avatar`.** Material giữ một hộp leading cố định rồi căn
glyph vào giữa, nên icon 16 vẫn cách mép 15 và cách nhãn 10 — những con số thuộc
nội bộ `RawChip`. Dựng icon trong `label` thì gap là gap. Cái giá phải trả lộ ra
ngay: `Text` trần trong `Row` không chịu co, và `mx_stress_test` bắt được
`RenderFlex overflowed by 171 pixels` ở 320 @ 2.0 — slot `avatar` vốn lo việc đó
hộ. `Flexible` đóng lại.

**Material có sàn 34px cho chip.** Hạ `_containerHeight` xuống 26 để thử thì
không gì nhúc nhích. Nên padding dọc vẫn viết theo M3 `(32−20)/2` chứ không viết
dưới sàn: dưới sàn thì theme nói một đằng render một nẻo, và người đầu tiên nâng
cỡ nhãn sẽ thấy chip lớn lên từ một con số không ai ghi.

**Chuẩn hoá làm hàng filter card list HẸP lại, không rộng ra.** Đây là điều
ngược trực giác và là lý do phải đo thay vì suy: padding ngang +4 mỗi bên, nhưng
bỏ `labelPadding` −16 mỗi chip, nên mỗi chip hẹp đi 8. Hàng bốn pill từ 416.5
xuống **354** so với 374 khả kiến ở 390 — giờ vừa màn cả khi đếm ba chữ số, việc
mà M4.11c/d còn phải chấp nhận cuộn.

**Bo góc: thử `AppRadius.sm` rồi trả về pill.** Radius token tên là "chips,
badges, small indicators" và chưa chip nào dùng, nên đổi là hợp lý trên giấy;
render ra thì chủ dự án giữ pill. Lý do đứng vững cạnh số đo: ở 32 chip cao đúng
bằng nút Study trên mỗi hàng deck, mà nút đó bo tròn hết cạnh — hai control cùng
cỡ trong một danh sách không nên khác hình.

**`MxPillButton` hạ một rung, các chip khác thì không.** `chipTheme` giữ
`label-lg` (14) cho pill filter của card list — chúng mang số đếm để đọc lướt và
không đứng cạnh gì. Hai pill toolbar xuống `label-md` (12) với gap 4, vì chúng
nằm cùng danh sách với nút Study vốn là `label-md` gap 4. Chỉ lấy **metrics** từ
rung; màu giữ `WidgetStateColor` của theme — chép nguyên rung sẽ thay bằng màu
phẳng và kéo theo cả trạng thái disabled/selected, đúng cái bẫy
`app_chip_theme.dart` đã ghi cho `secondaryLabelStyle`.

**`YOUR DECKS` lên `label-md`, và cân nhắc xoá đã bị bác bằng ảnh.** Heading
11sp bare text đứng cạnh chip 12sp **có nền và viền** đọc ra như chú thích cho
control chứ không phải tiêu đề của danh sách mà control đó lọc. Hai phương án
được render và so: bỏ hẳn heading để lại nửa trái trống với hai chip dạt về
phải, và mất luôn thông tin — ở cấp con heading đọc `SUB-DECKS`, thứ duy nhất
trên màn nói danh sách bên dưới là deck con chứ không phải card, mà tên deck và
breadcrumb đều không nói. Cùng rung 12 là đủ; chip vẫn nổi hơn nhờ khối, và đó
mới là thứ bậc đúng giữa một nhãn và một control. Màu **không** đổi sang
`onSurface`: làm vậy nó sẽ ngang hàng với tên deck ngay dưới.

### M4.11j · Pill filter của card list về chung một component, và `⚑` thôi là tofu

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** Mọi pill trong app MUST là một component; nhãn MUST KHÔNG dựa vào
  ký tự mà font trong bundle không có.
- **Scope:** `card_filter_bar_widget.dart`, `cardFilterFlagged` (en + vi),
  2 assertion trong `card_list_screen_test.dart`, 2 golden.
- **Out of scope:** predicate, thứ tự, hành vi của bộ lọc.
- **Dependencies:** M4.11i
- **Checklist phases:** 7, 12, 13
- **Editable documents:** `docs/wbs.md`,
  `docs/reviews/design-parity-checklist.md`
- **Output:** không có file mới
- **Tests required:** toàn bộ suite; 2 golden sinh lại sau khi chủ dự án xem
  render
- **Acceptance criteria:**
  - [x] Bốn pill dùng `MxPillButton`, không còn `FilterChip` dựng tay.
  - [x] Cờ là `Icons.flag`, không còn ký tự trong chuỗi ARB.
  - [x] Bốn pill vẫn vừa màn 390 với đếm ba chữ số.

**`⚑` U+2691 là tofu trong chính golden của dự án.** Không font nào trong bundle
mang nó — Inter, PlusJakartaSans, NotoSansKR đều thiếu — nên cả hai golden vẽ ra
một ô vuông có mã hex. Điều làm nó tệ hơn một lỗi hiển thị đơn thuần: máy có font
hệ thống rộng hơn **có thể** vẽ ra hình cờ, nên dấu này đúng hay sai tuỳ chỗ
người ta nhìn. Ngay hàng card bên dưới đã dùng `Icons.flag` và render sạch ở cả
hai theme.

**Nguyên nhân gốc là chỗ này bypass shared component.** `CardFilterBarWidget` là
nơi duy nhất trong app còn dựng chip bằng tay, và cái giá trả cùng lúc ba thứ:
cờ phải là ký tự vì không có chỗ đặt icon, nhãn đứng cao hơn mọi pill khác một
rung, và các sửa chữa của `MxPillButton` — `labelPadding` bị zero, gap icon dựng
trong label — đến được mọi nơi trừ đây. Chuyển sang `MxPillButton` đóng cả ba
bằng một thay đổi.

Ngữ nghĩa cũng đúng hơn: bốn pill này là chọn-một-trong-bốn, tức `ChoiceChip`,
không phải `FilterChip` với các công tắc bật/tắt độc lập.

**Hai assertion phải đổi, và cả hai đổi vì lý do tốt.** `find.byIcon(Icons.flag)`
giờ đếm được hai — pill Flagged và hàng card — nên nó được thu vào trong
`CardTileWidget`, tức nói đúng điều nó muốn nói. Cái còn lại đổi `FilterChip`
thành `MxPillButton`.

### M4.11k · Bốn pill filter đều có icon, và số đếm rời nhãn sang semantics

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** Cả bốn pill filter MUST mang icon, và hàng MUST vừa màn ở cả 390
  lẫn 360.
- **Scope:** `card_filter_bar_widget.dart`, 4 nhãn + 1 chuỗi semantics trong
  ARB (en + vi), 1 assertion, 2 golden.
- **Out of scope:** predicate, thứ tự, hành vi bộ lọc.
- **Dependencies:** M4.11j
- **Checklist phases:** 7, 12, 13
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Tests required:** đo bề rộng hàng ở 390/360 với đếm 1 và 3 chữ số; toàn bộ
  suite; 2 golden sinh lại sau khi chủ dự án chọn phương án
- **Acceptance criteria:**
  - [x] Bốn pill đều có icon, lấy từ từ vựng icon sẵn có của app.
  - [x] Hàng vừa ở **cả** 390 và 360, và không đổi theo độ dài số đếm.
  - [x] Số đếm vẫn được screen reader đọc trên **mọi** pill.

**Thêm icon và giữ số đếm là hai thứ không cùng vừa màn — đo mới thấy.** Mỗi
icon tốn 20 (16 icon + gap 4), ba icon mới là +60. Số đo ở 390 (374 khả kiến):

| phương án | hàng dài | 390 | 360 |
|---|---|---|---|
| icon cả 4 + giữ số | 418.0 | tràn 44 | tràn 74 |
| **icon cả 4 + bỏ số** | **341.6** | **vừa** | **vừa** |
| chỉ Flagged có icon | 354.0 | vừa | tràn |

Chủ dự án chọn phương án giữa. Nó không chỉ vừa — nó **không còn phụ thuộc số
đếm**: nhãn cố định nên deck 3 chữ số hay 1 chữ số đều 341.6, trong khi hai
phương án kia co giãn theo dữ liệu và chỉ vừa cho một khoảng.

**Số đếm rời *nhãn*, không rời *pill*.** Panel tiến độ ngay dưới đã nhắc lại
All, Due và New (`44 of 142 mastered`, `23 due · 38 new`), nên bỏ số khỏi ba
pill đó không mất gì. **Flagged thì không được nhắc ở đâu khác** — và một screen
reader không có ràng buộc bề rộng nào cả. Nên số vẫn được đọc, trên cả bốn pill,
qua `semanticLabel` với chuỗi `cardFilterSemantics`.

**Icon lấy từ từ vựng sẵn có, không phát minh mới.** `Icons.schedule` là glyph
mà `deck_due_state_widget.dart` đã dùng cho "khi nào"; `Icons.style_outlined` là
glyph empty state của card list dùng cho "thẻ"; `Icons.flag` là cờ hàng card
dùng. Riêng New chưa có tiền lệ: chọn `Icons.circle_outlined` — vòng tròn rỗng
là hình của "chưa bắt đầu" bên cạnh chấm đặc mà mỗi hàng mang. `Icons.fiber_new`
là lựa chọn hiển nhiên và sai: nó vẽ chữ NEW, ngay cạnh chữ New.

### M4.11l · Dải pill filter trải hết bề rộng khi vừa, cuộn khi không

- **Status:** done, **reverted ở M4.11o**.
- **Goal:** Bốn pill MUST trải đều hết bề rộng strip khi chúng vừa, và MUST vẫn
  cuộn được khi không vừa.
- **Scope:** `card_filter_bar_widget.dart`, một allowance trong
  `card_list_screen_visual_audit_test.dart`, 2 golden.
- **Out of scope:** nhãn, icon, predicate, hành vi.
- **Dependencies:** M4.11k
- **Checklist phases:** 7
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Tests required:** toàn bộ suite; strict visual audit; 2 golden sinh lại
- **Acceptance criteria:**
  - [x] Bốn pill trải đều, pill cuối chạm gutter phải.
  - [x] Vẫn cuộn khi nội dung rộng hơn strip.
  - [x] Không overflow ở 320×568 @ textScaler 2.0.

**`spaceBetween` một mình không làm được, và lý do đáng ghi.** Bên trong một
`SingleChildScrollView` ngang, `Row` có bề rộng **không giới hạn** — nên không
có khoảng thừa nào để phân phối, và alignment không có tác dụng gì. Thứ tạo ra
khoảng thừa là `ConstrainedBox(minWidth: viewport)`: khi bốn pill hẹp hơn strip,
row giãn ra đúng bằng strip và các khe mở đều; khi chúng rộng hơn — locale dài,
text scale lớn — row giữ bề rộng nội dung và cuộn y như cũ.

**`spacing` và `spaceBetween` cùng lúc, mỗi cái một việc.** `spacing` là **sàn**:
khi row cuộn thì `spaceBetween` không còn gì để chia, và không có sàn thì các
pill dính vào nhau. `spaceBetween` chia phần dư trên màn mà chúng vừa. Ba
`SizedBox` ngăn cách trước đây không làm được việc thứ hai: alignment sẽ coi
chính các spacer là children và giãn cách cả chúng, nên pill và spacer trôi xa
nhau.

**Trailing gutter bị bỏ, và nó vốn đang chống lại chính mục tiêu này.** Nó tồn
tại để pill cuối không dính sát mép viewport khi cuộn tới cuối — nhưng nó cũng
chặn row chạm tới gutter phải khi mọi thứ vừa. Gutter của subheader đã giữ pill
cách mép màn rồi.

**Audit đòi giải thích `_RenderLayoutBuilder`.** MX-VIS-001 không cho một render
object nào đi qua mà không có lý do; `LayoutBuilder` không vẽ gì cả — nó báo
constraint và dựng con, và cái con đó được audit riêng.

### M4.11m · Sàn bề rộng cho pill, để khoảng trống rơi vào pill chứ không vào khe

- **Status:** done, **reverted ở M4.11o**.
- **Goal:** Bốn pill MUST đọc ra như một control, không phải bốn thứ rời rạc.
- **Scope:** `card_filter_bar_widget.dart` (một hằng + `ConstrainedBox`),
  2 golden.
- **Out of scope:** nhãn, icon, predicate, hành vi.
- **Dependencies:** M4.11l
- **Checklist phases:** 7
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Tests required:** đo bề rộng và khe ở `en`/`vi`, strip 358 và 328,
  `textScaler` 2.0; toàn bộ suite; 2 golden sinh lại
- **Acceptance criteria:**
  - [x] Khe giữa pill từ ~19 xuống **11.4**, và là 8 khi hàng cuộn.
  - [x] Hàng vẫn vừa strip ở `en`, vẫn cuộn ở `vi` và ở text scale lớn.
  - [x] Không pill nào bị cắt ở 390.

**Trải đều xong thì khoảng trống rơi vào khe, không vào pill.** M4.11l làm hàng
trải hết bề rộng, nhưng `spaceBetween` đem 56px thừa chia vào ba khe — 19 mỗi
khe, gần bằng bề rộng một pill. Bốn thứ thuộc cùng một control đứng xa nhau như
thế đọc ra là bốn control. Cho pill hẹp một cái sàn chung thì tiêu đúng chỗ
trống ấy vào chính các control, và khe về gần giá trị nghỉ 8.

**Strip rộng 358, không phải 374 — và tôi đã đặt sai lần đầu.** Subheader gutter
**cả hai bên**, nên `390 − 2 × 16`. Lần đầu tôi tính theo 374, chọn sàn 84, và
hàng vượt 14px; nó không làm test nào đỏ — nó chỉ hiện ra là pill cuối bị cắt
trong render. Đó là lý do phải xem ảnh chứ không chỉ đọc số: `SingleChildScrollView`
không bao giờ báo overflow, nó cuộn.

Với 358: Flagged cần 96, còn lại chia `(358 − 96 − 24) / 3 = 79.4`, nên 76 là bội
số 4 lớn nhất còn vừa. Đo được: `en` 76/76/76/95.7 khe 11.4 vừa khít; `vi`
83.9/97.1/76/108.2 khe 8 và cuộn; `textScaler` 2.0 khe 8 và cuộn.

**Sàn, không phải bề rộng cố định.** Locale dài hơn hay text scale lớn đẩy pill
vượt sàn, hàng vượt strip, và nó cuộn — đúng thứ `ConstrainedBox` quanh row ở
M4.11l đã chuẩn bị sẵn.

### M4.11n · Khe giữa pill về đúng 8, và lớp layout thêm ở M4.11l bị gỡ

- **Status:** done, **reverted ở M4.11o**.
- **Goal:** Khoảng cách cuối-pill-này tới đầu-pill-kia MUST là 8, giá trị khe
  của cả app.
- **Scope:** `card_filter_bar_widget.dart`, gỡ một allowance trong
  `card_list_screen_visual_audit_test.dart`, 2 golden.
- **Out of scope:** nhãn, icon, sàn bề rộng, predicate.
- **Dependencies:** M4.11m
- **Checklist phases:** 7
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Tests required:** đo khe ở `en`/`vi` và `textScaler` 2.0; toàn bộ suite;
  strict visual audit; 2 golden sinh lại
- **Acceptance criteria:**
  - [x] Khe = **8.0** ở mọi trường hợp đo.
  - [x] Không pill nào bị cắt ở 390 (`en`).
  - [x] `LayoutBuilder` và `ConstrainedBox` của M4.11l bị gỡ, allowance audit
        tương ứng cũng vậy.

**M4.11l và M4.11m giải quyết đúng vấn đề bằng công cụ sai.** Cả hai làm hàng
trải rộng bằng cách đẩy phần dư vào `spaceBetween`, tức vào **khe** — mà khe
rộng chính là thứ làm bốn control của một nhóm đọc ra thành bốn nhóm. M4.11m thu
khe từ 19 xuống 11.4 bằng sàn bề rộng, nhưng vẫn còn 3.4 rắc vào mỗi khe.

Bỏ `spaceBetween` thì khe về đúng **8**, giá trị khe của cả app, ở mọi trường
hợp đo: `en` (hàng 347.7 trên strip 358), `vi` (389.3, cuộn), `textScaler` 2.0
(435.2, cuộn). Phần dư còn lại là **10.3 trên 358 — dưới 3% strip**, nằm ở mép
phải nơi không có gì khác, và không đọc ra như "thiếu một pill thứ năm" theo
cách 72px ban đầu đã đọc.

**Gỡ luôn `LayoutBuilder` và `ConstrainedBox`.** Chúng được thêm ở M4.11l chỉ để
tạo khoảng thừa cho `spaceBetween` phân phối; không còn `spaceBetween` thì
chúng không làm gì cả. Allowance `_RenderLayoutBuilder` trong strict visual audit
đi theo — audit không còn thấy render object đó nữa, và một allowance cho thứ
không tồn tại là thứ audit báo là `unused`.

### M4.11o · Trả dải pill filter về căn trái, và bỏ ba vòng layout trước đó

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** Dải pill quay lại đúng trạng thái sau M4.11k: căn trái, khe 8, bốn
  icon.
- **Scope:** `card_filter_bar_widget.dart` khôi phục nguyên văn từ M4.11k;
  2 golden.
- **Out of scope:** icon, nhãn, semantics, sàn bề rộng — tất cả bị gỡ cùng lúc.
- **Dependencies:** M4.11n
- **Checklist phases:** 7
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Tests required:** toàn bộ suite; 2 golden sinh lại
- **Acceptance criteria:**
  - [x] Widget giống hệt bản M4.11k (`git checkout` từ chính commit đó).
  - [x] Không còn `LayoutBuilder`, `ConstrainedBox`, sàn bề rộng hay
        `spaceBetween`.

**Ba vòng liên tiếp không hội tụ, và đó là dữ liệu chứ không phải thất bại.**
M4.11l trải rộng, M4.11m thêm sàn để thu khe, M4.11n bỏ `spaceBetween` để khe về
8 — mỗi vòng sửa đúng thứ vòng trước làm hỏng, vì cả ba đều xoay quanh việc phân
phối cùng một khoảng dư. Vòng thứ tư định cho bốn pill bằng nhau đúng bằng nhãn
rộng nhất, và số đo cho thấy giá của nó: 407 (`en`) / 457 (`vi`) trên strip 358,
tức luôn phải cuộn.

Chủ dự án dừng ở đó và chọn quay về trạng thái đơn giản nhất còn lại: căn trái,
khe 8, bốn icon. Đó là lựa chọn đúng — mọi phương án còn lại đều đổi một khuyết
điểm nhìn thấy được lấy một khuyết điểm nhìn thấy được khác, và cái đơn giản
nhất là cái ít phải giải thích nhất.

**Cái được giữ lại là phần có thật.** M4.11j (bốn pill về `MxPillButton`, cờ
thôi là tofu) và M4.11k (bốn icon, số đếm sang semantics) đứng nguyên: chúng sửa
lỗi hiển thị và lỗi accessibility, không phải sắp xếp khoảng trắng.

**Ghi lại số đo để không ai đi lại vòng này.** Bốn pill bằng nhau **và** vừa
strip 358 đòi mỗi pill ≤ 83.5, tức nhãn ≤ 37.5px ở 12sp sau khi trừ 46 chrome
(padding, hairline, icon, gap) — khoảng năm đến sáu ký tự. `Flagged` cần bảy,
`Đến hạn` còn hơn. Muốn cân bằng bề rộng thì phải rút nhãn hoặc bỏ icon trước,
không phải chỉnh layout.

### M4.11p · Tiêu đề panel tiến độ thôi mờ hơn nội dung, và legend hết gãy dòng

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** `DECK PROGRESS` MUST đọc ra là tiêu đề của khối, và bốn nhãn trạng
  thái MUST KHÔNG gãy dòng lẻ.
- **Scope:** `card_progress_panel_widget.dart` (`_Legend` và style tiêu đề),
  2 golden.
- **Out of scope:** ring, thanh phân bố, nút Start study, các con số.
- **Dependencies:** M4.11o
- **Checklist phases:** 7
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Tests required:** đo cỡ chữ tiêu đề và vị trí từng mục legend; toàn bộ
  suite; 2 golden sinh lại
- **Acceptance criteria:**
  - [x] Tiêu đề `label-md` trên `onSurface`, cùng rung với `YOUR DECKS`.
  - [x] Bốn mục legend nằm 2×2, thẳng cột, không mục nào đứng một mình.

**Tiêu đề nhỏ hơn *và* nhạt hơn thứ nó giới thiệu.** Đo được: `DECK PROGRESS`
11px `w500` trên `onSurfaceVariant`, ngay trên `44 of 142 mastered` 14px `w600`
trên `onSurface`. Một tiêu đề thua nội dung ở cả hai chiều thì đọc ra là chú
thích dưới cái ring, không phải tên của khối. Nâng lên `label-md` trên
`onSurface` — cùng rung với `YOUR DECKS` ở màn deck, và cùng màu với dòng nó
đứng đầu. Vẫn viết hoa và giữ section tracking, đó là thứ giữ nó ở vai trò tiêu
đề: 12 so với 14 của con số, và bản thân nó không mang số nào.

**`Wrap` gãy 3 + 1, và đó là gãy chứ không phải xuống dòng.** Bốn mục cần 371.9
theo chiều ngang, panel cho 326 — nên `Mastered 44` đứng một mình ở dòng hai
(top 124 so với 104 của ba mục kia). Đổi sang hai hàng, mỗi hàng hai
`Expanded`: cùng lượng thông tin trong hai dòng đều nhau, và **cột thẳng hàng**
vì mỗi ô lấy nửa bề rộng thay vì lấy theo nội dung. Thứ tự vẫn là thứ tự
`CardState`, đọc trái sang phải rồi xuống dòng: New → Beginning → Reviewing →
Mastered.

### M4.11q · Vòng tiến độ vẽ đúng cỡ nó được cho, và CTA có khoảng thở

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** Vòng tiến độ MUST chiếm đúng hộp nó được cấp, và nút hành động MUST
  tách khỏi khối thông tin bằng một khoảng cách cấp section.
- **Scope:** `card_progress_panel_widget.dart` (`_ProgressRing`, padding của
  `_StudyAction`), 2 golden.
- **Out of scope:** thứ tự legend (đã đúng, xem bên dưới); thanh phân bố.
- **Dependencies:** M4.11p
- **Checklist phases:** 7
- **Editable documents:** `docs/wbs.md`
- **Output:** không có file mới
- **Tests required:** đo đường kính vòng và khoảng cách CTA; toàn bộ suite;
  2 golden sinh lại
- **Acceptance criteria:**
  - [x] Vòng vẽ **64**, đúng bằng hộp của nó.
  - [x] Khoảng cách legend → CTA từ 16 lên **24**.

**Vòng chưa bao giờ vẽ ở 52.** `_ringSize` ghi 52 và hộp đúng 52, nhưng
`CircularProgressIndicator` đặt trần trong `Stack` tự lấy kích thước nội tại và
căn giữa — nên nó vẽ ở **36**, để lại 16 khoảng chết quanh mình. Đó là lý do
vòng đọc ra nhỏ và con số phần trăm lọt thỏm: con số trong source không phải con
số trên màn hình. `Positioned.fill` làm cung chiếm đúng hộp, và 64 giờ là 64 —
tăng 78% so với thứ thực sự đang hiển thị.

Stroke lên 6 theo: giữ nguyên 5 thì cung mảnh đi khi đường tròn to ra.

**Khoảng cách legend → CTA lên `xl`.** Ở 16 nó bằng đúng khoảng cách giữa hai
hàng legend, tức một section break đo bằng khoảng cách bên trong section. 24
tách phần "đọc thông tin" khỏi phần "hành động".

**Thứ tự legend đã đúng, không sửa.** Đo được: `New` (28, 104), `Beginning`
(197, 104), `Reviewing` (28, 124), `Mastered` (197, 124) — tức hàng 1 là
New | Beginning, hàng 2 là Reviewing | Mastered, đúng luồng tiến trình đọc trái
sang phải rồi xuống dòng. Cùng một lưới đọc theo cột sẽ ra New → Reviewing, và
đó là cách nhìn chứ không phải cách nó được xếp.

**Quan sát để ngỏ: thanh phân bố gần như vô hình.** Nó có thật — đo được
326×8 với bốn đoạn đúng tỉ lệ (87.2 / 71.2 / 66.6 / 101.0) — nhưng 8px trên một
panel cao khoảng 300 thì mắt bỏ qua, và nó nói đúng thứ legend ngay dưới đã nói
bằng chữ. Nếu vòng chuyển sang multi-segment bốn màu thì thanh này nên bỏ, chứ
không nên có ba lần cùng một thông tin.

### M4.11r · Sub-text panel lên một rung, và phần phân bố tách file

- **Status:** **done** — 1400/1400 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation.
- **Goal:** Dòng `23 due · 38 new` MUST dễ đọc hơn mà MUST KHÔNG đánh mất thứ
  bậc của nó dưới dòng headline.
- **Scope:** `card_progress_panel_widget.dart`, file mới
  `card_state_distribution_widget.dart`, 2 golden.
- **Out of scope:** thứ tự legend, kích thước vòng, khoảng cách CTA — đã xong ở
  M4.11p/q.
- **Dependencies:** M4.11q
- **Checklist phases:** 7, 13
- **Editable documents:** `docs/wbs.md`
- **Output:** `card_state_distribution_widget.dart`
- **Tests required:** đo contrast WCAG hai theme; toàn bộ suite; 2 golden
- **Acceptance criteria:**
  - [x] Sub-text lên `label-md`, **màu giữ nguyên**.
  - [x] File panel dưới ngưỡng 400 dòng của guard.

**Đề xuất "đậm màu lên cho đạt WCAG" đo ra là không có cơ sở.**
`onSurfaceVariant` trên `surface` cho **6.41:1** ở light và **7.30:1** ở dark,
so với ngưỡng AA body là 4.5:1 — light còn sát ngưỡng AAA (7:1) và dark thì
vượt. Đổi sang `onSurface` sẽ đưa nó lên 16.95:1, tức ngang bằng dòng headline
ngay trên, và đánh đổi một thứ bậc **có thật** lấy một mức tuân thủ **đã đạt**.

Thứ thực sự nhỏ là cỡ chữ: 11px mang hai con số. Lên `label-md` (12) thì panel
giờ đặt mọi thứ ở `label-md` trừ đúng một dòng headline — heading, sub-text và
legend cùng một rung, headline một mình ở trên.

**Guard bắt file vượt 400 dòng, và seam để tách nằm sẵn ở đó.** Thanh phân bố và
legend là **một phát biểu** — thanh cho thấy tỉ lệ, legend gọi tên màu, và không
cái nào có nghĩa nếu thiếu cái kia. Panel thì gồm ba ý riêng: một vòng, một phân
bố, một hành động. Tách theo đúng đường đó: 411 → 294 + 150.

**Hai mục còn lại trong yêu cầu không cần code.** Thứ tự legend đã đúng từ
M4.11p (đo lại: hàng 1 New | Beginning, hàng 2 Reviewing | Mastered), và khoảng
cách CTA đã lên `xl` = 24 ở M4.11q, đúng mức "+8" được đề nghị.

**Donut multi-segment vẫn để ngỏ, có điều kiện.**
`CircularProgressIndicator` nhận đúng một `value` — không có contract nào để
truyền bốn đoạn vào, nên theo chính nguyên tắc "không làm vỡ component chung"
thì nó phải là một `CustomPainter` mới chứ không phải một tham số mới. Khi làm,
thanh phân bố nên bỏ: ba lần phát biểu cùng một phân bố trên một panel là hai
lần thừa.

### M4.12a · Starter template, loader và seed idempotent

- **Status:** **done** — 1398/1398 test pass, `flutter analyze` sạch,
  `dart format` sạch, guard `memox-v7` 0 violation, `check_generated` và
  `check_docs` sạch.
- **Goal:** Lát nền của M4.12: app **tự có dữ liệu** ở bản development mà không
  ai phải sửa database bằng tay, và nạp lại **không** nhân bản (BR-37).
- **Scope:** `assets/templates/` (manifest + 2 template), `DeckTemplate` domain
  model, `DeckTemplateDataSource`, `DeckTemplateRepository` + impl + DAO + seed
  mapper, `InstallDeckTemplatesUseCase`, DI + binding, `FixtureSeederWidget`,
  `test/helpers/seed.dart`, 20 test mới.
- **Out of scope:** Playwright/Web E2E, state matrix, design parity — vẫn nằm ở
  M4.12 và **chưa làm**; xem "Còn lại" bên dưới.
- **Dependencies:** M4.11, M4.4
- **Checklist phases:** 11.1, 14.4
- **Editable documents:** `docs/wbs.md`
- **Output:** `assets/templates/` (3 file), `deck_template_model.dart`,
  `deck_template_repository.dart`, `install_deck_templates_use_case.dart`,
  `datasources/deck_template_data_source.dart`, `datasources/deck_template_dao.dart`,
  `mappers/deck_template_seed_mapper.dart`,
  `repositories/deck_template_repository_impl.dart`,
  `di/deck_template_provider.dart`, `app/startup/fixture_seeder_widget.dart`,
  `test/helpers/seed.dart`
- **Tests required:** repository integration trên SQLite thật (copy, idempotent,
  rollback, cả hai scheduler), toàn bộ 15 bất biến sau seed, loader trên asset
  thật + 5 asset hỏng, seed helper end-to-end, seeder widget theo flavor
- **Acceptance criteria:**
  - [x] Fixture: một root `eight_box`, một root `sm2`, cây **ba cấp**, leaf chứa
        card; `manifest.json` ghi rõ là fixture development/test (BR-87).
  - [x] Nạp **hai lần** không nhân bản (BR-37), chứng minh trên SQLite thật.
  - [x] Đủ **15** bất biến pass sau seed (và sau seed hai lần).
  - [x] Copy nằm trong **một** transaction; copy hỏng không để lại gì (BR-39).
  - [x] Seed chạy qua **chính** repository và loader thật, không INSERT tay.

**Copy-on-use là AD-07, seed-at-startup là fixture — hai chuyện khác nhau.**
AD-07 cấm chèn thẳng nội dung starter vào dữ liệu người dùng lúc khởi động, vì
đó là ghi mà không hỏi. Lập luận ấy đúng với **nội dung starter thật**. Thứ đang
ship không phải vậy: BR-87 khai báo nó là fixture cho development và test, và
M4.12 cần app demo được mà không ai sửa database. Nên seed chỉ chạy ở flavor
`development`; `staging` và `production` khởi động rỗng và sẽ nhận màn thư viện
starter mà AD-07 thực sự mô tả. `fixture_seeder_widget_test.dart` ghim cả ba
flavor.

**Idempotency check nằm *trong* transaction.** Kiểm tra trước rồi ghi sau để lại
một khe: hai lần khởi động, hoặc một test chạy song song, cùng đọc "chưa có" rồi
cùng ghi. Trong transaction thì cái thứ hai nhìn thấy root của cái thứ nhất.

**Node khai `children` **hoặc** `cards`, không cả hai.** Loader từ chối node khai cả hai, nên `installTemplate` không cần một dòng
kiểm tra content-type nào — cây mà app từ chối thì không bao giờ tồn tại dưới
dạng `DeckTemplate`. `content_type` được quyết bởi nội dung node: leaf có card
là `card`, leaf rỗng giữ `unset` — đúng trạng thái một deck rỗng người dùng vừa
tạo (BR-62).

**Loader nằm ở `datasources/`, không phải thẳng trong `data/`.** WBS gốc ghi
`lib/features/deck/data/template_loader.dart`; `architecture_boundary_test.dart`
từ chối — file thẳng dưới `data/` không nằm trong bucket nào, và các rule suffix
chọn file **theo đúng đường dẫn đó**, nên một file không bucket là file không
được rule nào kiểm. Đổi thành `datasources/deck_template_data_source.dart`.

**Seed mapper là bản sao thứ hai của BR-09, có chủ ý.** Bản gốc ở
`features/card/data/`, mà feature này không được import. Lựa chọn còn lại là đẩy
BR-09 vào `core/`, biến bảng khởi tạo study state thành hạ tầng chung không
feature nào sở hữu. Hai mapper ngắn có test ghim từng cột là giá rẻ hơn.

### M4.12b · Playwright E2E trên Flutter Web ở mobile viewport

- **Status:** **done** — 3/3 spec pass (~26s), `flutter analyze` sạch,
  `dart format` sạch, 1398/1398 test Dart, guard `memox-v7` 0 violation.
- **Goal:** Luồng E2E bắt buộc của M4.12 MUST chạy qua **UI thật** trên Flutter
  Web ở viewport điện thoại, kể cả persistence sau khi mở lại app.
- **Scope:** `e2e/` (package.json, playwright.config.ts, specs, support,
  README), `--dart-define=MEMOX_E2E` + `keepSemanticsOn` trong `bootstrap.dart`,
  job CI `web build + Playwright E2E`.
- **Out of scope:** study session (M5); so ảnh — golden và strict visual audit
  đã sở hữu phần "trông thế nào".
- **Dependencies:** M4.12a
- **Checklist phases:** 15.5
- **Editable documents:** `docs/wbs.md`
- **Output:** `e2e/` (7 file), `lib/app/bootstrap.dart` (+2 khai báo),
  `.github/workflows/ci-full.yml`
- **Tests required:** demo flow đầy đủ, content-type lock + reset (BR-68), cả
  hai scheduler
- **Acceptance criteria:**
  - [x] Viewport 390×844, click trực tiếp trên UI (không gọi API sau lưng).
  - [x] Luồng bắt buộc: cold start rỗng → root deck + chọn scheduler → branch →
        leaf → *Create card* → tạo card → sửa card → quay lại cây → **reload** →
        dữ liệu còn → xoá card → xoá deck.
  - [x] `content_type = deck`, `content_type = card`, reset khi rỗng (BR-68).
  - [x] Cả `eight_box` lẫn `sm2`.
  - [x] Cây ba cấp.
  - [x] CI chạy build web + E2E, upload report khi đỏ.

**Semantics là DOM duy nhất Playwright đọc được, và mẹo thông thường không sống
sót.** Flutter Web vẽ lên canvas; driver chỉ thấy semantics tree. Cách phổ biến
là click `<flt-semantics-placeholder>` để bật — và nó **hỏng ở đây**: engine
chuyển về xử lý pointer thô ngay khi thấy pointer event thường, nên tree biến
mất đúng lúc suite tap thứ đầu tiên, và mọi assertion sau đó đọc ra "deck chưa
bao giờ được tạo" trong khi deck sờ sờ trên màn hình. Bản build E2E vì thế gọi
`ensureSemantics()` lúc khởi động, sau `isE2EBuild` — một `const` từ
`--dart-define=MEMOX_E2E=true`, nên bản ship không mang lời gọi đó.

**Hệ quả đáng ghi: reach của E2E và accessibility là **một** việc.** Control nào
screen reader không gọi tên được thì suite này cũng không chạm tới. Một control
mất `semanticLabel` làm hỏng cả hai cùng lúc — đó là lý do suite này là bài kiểm
tra accessibility rẻ nhất repo có.

**Nhãn tới DOM theo hai đường khác nhau.** Button thường mang nhãn ở text; thứ
gì được gán `Semantics` label thì mang ở `aria-label` và **textContent rỗng** —
radio chọn scheduler, và mọi deck row (gộp tên + dòng meta + trạng thái đến hạn
vào một label). Helper khớp cả hai; khớp mỗi text thì tìm thấy empty state và bỏ
sót mọi hàng app thực sự vẽ. Tap dùng `[flt-tappable]` chứ không
`[role="button"]`: engine đóng dấu thuộc tính đó lên mọi node có tap action, còn
radio và card row không phải button.

**Build E2E dùng `main_staging.dart`, không phải entrypoint mặc định.** Mặc định
là config development, tức seed fixture lúc khởi động (M4.12a) — mà luồng bắt
buộc bắt đầu từ "cold start rỗng", nên database đã có deck làm assertion đầu
tiên trở nên vô nghĩa.

### M4.12c · Bất biến sau luồng E2E, và báo cáo demo flow

- **Status:** done
- **Goal:** Đóng hai tiêu chí M4.12 chưa có gì đứng sau: "đủ bất biến pass **sau
  E2E**" và "báo cáo demo flow kèm bằng chứng từng bước".
- **Scope:** `test/database/invariants_after_flow_test.dart`,
  `e2e/specs/support/evidence.ts`, `e2e/specs/demo-flow.spec.ts`,
  `.github/workflows/ci-full.yml`, `.gitignore`.
- **Out of scope:** assertion thị giác trong Playwright — golden và strict visual
  audit đã sở hữu phần "trông thế nào", so ảnh ở đây chỉ nhân đôi chúng với tỉ lệ
  flake cao hơn nhiều.
- **Dependencies:** M4.12a, M4.12b
- **Checklist phases:** 11.1, 15.1–15.5
- **Tests required:** `invariants_after_flow_test.dart`, Playwright `demo-flow`.
- **Editable documents:** `docs/wbs.md`
- **Output:** `test/database/invariants_after_flow_test.dart`,
  `e2e/specs/support/evidence.ts`, `e2e/report/` (gitignored, CI artifact)
- **Acceptance criteria:**
  - [x] Cả 15 bất biến chạy **sau mỗi bước** của luồng bắt buộc, không chỉ sau seed.
  - [x] Chạy thêm một lần nữa trên database **đã seed fixture** rồi làm việc tiếp
        trên đó — hai thứ riêng lẻ sạch vẫn có thể bẩn khi ghép.
  - [x] Mỗi bước của demo flow sinh một ảnh màn hình và một dòng "chứng minh điều gì".
  - [x] Báo cáo là markdown, ghi commit và viewport, link ảnh **tương đối** để mở
        được ở bất kỳ đâu thư mục nằm.
  - [x] CI upload `e2e/report/` với `always()`, không chỉ khi fail.

**Qua repository, không qua UI — và đó là điểm đáng nói.** Bất biến là câu SQL;
Playwright ghi vào IndexedDB trong trình duyệt và `integration_test/` không có
seam SQL nào. Nên luồng ở đây đi qua đúng `DeckRepository`/`CardRepository` mà màn
hình gọi, trên SQLite thật. Test bất biến cũ (`invariants_test.dart`) kiểm **các
câu query**: mỗi câu có bắt đúng vi phạm của nó không. Cái này kiểm **ứng dụng**:
một luật có thể phát biểu hoàn hảo mà vẫn bị một đường ghi không ai chĩa nó vào
phá vỡ.

**Báo cáo là báo cáo, không phải bộ assertion thứ hai.** Spec đã assert từng bước
tạo ra cái gì; `step()` chỉ chụp lại màn hình *sau khi* bước đó pass. Bước hỏng
thì spec fail — ảnh không phải là thứ quyết định.

**Đường dẫn giải từ `__dirname`, không từ cwd.** CI chạy Playwright từ gốc repo,
tay chạy từ `e2e/`; đường dẫn tương đối đặt báo cáo ở hai chỗ khác nhau — cách một
báo cáo được viết ra, không ai tìm thấy, rồi bị coi là không chạy.

### M4.12d · Design parity gate, và một lần re-verify checklist

- **Status:** done
- **Goal:** Biến tiêu chí "design parity dưới 3%" thành một cổng chạy được, và
  kiểm lại xem checklist còn đúng với `lib/` không.
- **Scope:** `test/design_audit/design_parity_gate_test.dart`,
  `docs/reviews/design-parity-checklist.md` (chuẩn hoá 35 verdict, viết lại 9 dòng
  `drift`, thêm Round 4).
- **Out of scope:** F15 (dialog thiếu `--shadow-overlay` ở light) — xem dưới.
- **Dependencies:** M4.10q
- **Checklist phases:** 7, 15.4
- **Tests required:** `design_parity_gate_test.dart`, toàn bộ suite.
- **Editable documents:** `docs/reviews/design-parity-checklist.md`, `docs/wbs.md`
- **Output:** `test/design_audit/design_parity_gate_test.dart`
- **Acceptance criteria:**
  - [x] Verdict thuộc **tập đóng sáu từ**; từ lạ làm test fail chứ không lọt.
  - [x] Không dòng nào chưa review, không ID trùng, không dòng thiếu ô status.
  - [x] Tỉ lệ `drift` còn mở dưới 3% — hiện **1/80 = 1,25%**.
  - [x] Lý do không dùng so pixel được viết trong chính test, không chỉ trong docs.

**So pixel không phải là một cổng.** `docs/checklist.md` 15.x viết "pixel
difference dưới 3%", và cả M4.10 lẫn M4.11 đều đã ghi là **không áp dụng được** —
lần đầu vì hai bên khác scope, lần sau vì kit không có màn card list. Còn một lý
do sâu hơn: design render bằng Chrome từ CSS, app render qua Skia. Antialiasing,
font hinting và icon glyph tải từ CDN đặt một sàn dưới con số chênh lệch mà không
lượng parity nào kéo xuống được. Một con số không thể chạm ngưỡng dù app có đúng
đến đâu thì không phải cổng — nó là đèn đỏ vĩnh viễn, và đèn đỏ vĩnh viễn thì bị
tắt tiếng.

Đại lượng thay thế: **tỉ lệ dòng còn `drift` mở** trong parity checklist. Cùng
ngưỡng, trên một đại lượng nói về design chứ không nói về hai bộ rasteriser — và
là đại lượng người đọc file làm được gì đó với nó, vì mỗi đơn vị là một dòng, và
dòng đó ghi sẵn phải mở file nào.

**Chín dòng ghi `drift`, bảy dòng đã được sửa xong từ lâu.** Kiểm lại từng dòng
với `lib/`: hover button (F1), hairline nav (F2), hairline cuộn dưới app bar (F4),
spinner (F14), breadcrumb fold/`rootIcon`/cỡ chữ/màu link (F5–F8), `subheader` và
`leading` của shell (F9, F10) — tất cả đã đóng, có cái từ M4.10q. F11 chết theo
FAB (M4.10ag/M4.10aq). F3 và F16 chưa bao giờ là drift: chúng là phân kỳ đã đo và
đã nằm sẵn trong bảng divergence, tự mâu thuẫn với chính dòng của mình.

**Đúng một dòng là thật: F15.** `.mx-dialog` có `--shadow-overlay`, `dialogTheme`
để `elevation: 0`, và comment trong `app_theme.dart` viện AD-14 để biện minh —
trong khi **AD-14 §4 nói ngược lại**: chiều sâu là mục tiêu đo được, mỗi mode dựng
bằng thứ mode đó có, và light dựng bằng shadow. Dark đúng như hiện tại
(`shadowsFor` rỗng ở dark). Không sửa trong task này vì nó làm đổi mọi golden
dialog, và golden phải duyệt ảnh render trước — đó là luật đã chốt ở M4.11.

**Bài học thuộc về cổng, không thuộc về chín dòng kia.** Một checklist có nhãn
sửa bằng tay sẽ trôi khỏi code đúng theo cách code lẽ ra sẽ trôi khỏi design. Ba
milestone làm parity đổ vào những dòng vẫn đọc là "drift", và không có gì fail.
Cổng mới chặn được việc **quên một khác biệt đã biết**; nó **không** chặn được
file này cũ đi — chỉ đọc lại `lib/` mới làm được, và điều đó được ghi thẳng vào
đầu file lẫn trong doc comment của test.

### M4.12 · Deck/Card demo hardening, fixture và E2E

- **Status:** done — **M4.12a** (fixture, loader, seed idempotent), **M4.12b**
  (Playwright E2E), **M4.12c** (15 bất biến sau luồng E2E, báo cáo demo flow),
  **M4.12d** (design parity gate). State matrix coi như đã phủ bởi widget test
  hiện có (deck list: loading/empty/loaded/error/dark/textScale 2.0/320×568; card
  list: loading/empty/loaded/error/no-match; card editor: submitting, save-failed,
  load-failed) — nếu muốn nó là một gate riêng thay vì một tính chất của bộ test
  thì cần một task ghi rõ hình dạng gate đó.
- **Điều kiện mở M5 đã đủ.** Không còn hạng mục nào của M4.12 để mở, ngoài một
  finding parity được ghi nhận và hoãn có lý do (F15, xem M4.12d).
- **Goal:** Đưa app tới trạng thái **demo được** bằng luồng Deck/Card hoàn chỉnh,
  trước khi bắt đầu Review.
- **Scope:** fixture cho development/test; seed helper dùng **chính** repository
  và loader thật; persistence qua restart; Flutter Web + Playwright ở mobile
  viewport với thao tác trực tiếp trên UI; visual state matrix; regression toàn
  slice; thay `StudyPlaceholderScreen` làm entrypoint nếu còn; dọn placeholder
  và navigation demo-only không còn caller.
- **Out of scope:** Review session (M5); nội dung production (BR-87, trước M8);
  sync/backend.
- **Editable documents:** `docs/wbs.md`
- **Output:** `assets/templates/`, `lib/features/deck/data/template_loader.dart`,
  `test/helpers/seed.dart`, `integration_test/`
- **Acceptance criteria:**
  - [x] App demo được **không** cần sửa database bằng tay. (M4.12a)
  - [x] App không còn chỉ hiện placeholder.
  - [x] Fixture: một root `eight_box`, một root `sm2`, cây **ít nhất ba cấp**,
        leaf chứa card; manifest ghi rõ là fixture development/test (BR-87).
  - [x] Nạp fixture **hai lần** không nhân bản (BR-37).
  - [x] Đủ **15** bất biến pass **sau seed** và **sau E2E** — con số là 15 từ
        M4.9a, không còn 14. (M4.12c)
  - [x] Playwright resize đúng mobile viewport và click trực tiếp trên UI. (M4.12b)
  - [x] Luồng chính chạy qua Flutter Web; persistence còn sau reload/restart theo
        khả năng của target.
  - [x] Mọi production screen strict visual audit **PASS** ở light và dark.
  - [x] State matrix phủ loading, empty, loaded, submitting, error và confirmation
        — với screen có state đó.
  - [x] Design parity dưới 3% cho screen có baseline — **đo bằng tỉ lệ `drift` còn
        mở trong parity checklist, không phải so pixel**; 1/80 = 1,25%. Lý do
        thay đại lượng nằm ở M4.12d.
  - [x] `flutter test` full pass; **một** `flutter build web` ở integration gate;
        không build APK như validation mặc định.
  - [x] Báo cáo demo flow kèm bằng chứng từng bước. (M4.12c)
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

## M5 · Study vertical slice — UC-05

Mục tiêu: luồng ôn tập chạy xuyên suốt Drift → data source → repository → use
case → controller/state → router → màn hình → ghi kết quả → UI cập nhật.

**Không còn là vertical slice đầu tiên.** Quản lý Deck/Card đã hoàn thành ở
M4.8–M4.12, và M5 **không** triển khai lại phần đó — nó xây đúng phần Study.
Điều kiện bắt đầu: **M4.12 `done`**. Study MUST NOT bắt đầu trước mốc đó, vì
không có cây deck và card thật thì phiên ôn không có gì để ôn, và mọi test của nó
sẽ phải dựng dữ liệu bằng tay — thứ M4.12 tồn tại để thay thế.

**Thứ tự thi hành sau brainstorm.** Kế hoạch M5.0…M5.6 ở bản đầu được viết trước
M5.0a–M5.0r và mô tả mô hình một-loại-phiên đã bị thay. Nội dung từng task đã
viết lại; **ID và ý nghĩa của chúng giữ nguyên** theo quyết định ở M4.4a — M5.4
vẫn là "màn hình Study", và bốn chỗ khác trong tài liệu trỏ tới nó vẫn đúng. Hai
thay đổi về hình dạng: schema v5 tách thành **M5.0s** đứng trước mọi thứ, và hàng
đợi chuyển từ M5.3 xuống **M5.0** vì BR-102 đưa nó vào database.

**Ngoài phạm vi M5** (nêu một lần, áp cho mọi task bên dưới): import/export,
login, backend, sync, media, statistics, settings, và UI thư viện starter deck.
CRUD deck/card **đã xong ở M4**, không lặp lại ở đây.

### M5.0a · Đổi tên Review → Study trong toàn bộ tài liệu

- **Status:** done — chỉ `docs/` và hai script guard. `lib/`, `.drift` và
  migration **chưa đụng tới**; xem "Còn nợ".
- **Goal:** Gọi cùng một thứ bằng cùng một tên, trước khi M5 viết code sinh thêm
  chỗ cho hai tên cùng tồn tại.
- **Scope:** 8 tài liệu trong `docs/`, cộng `verify_invariants.py` (fixture
  `CREATE TABLE`) và `check_docs.py` (pattern invariant) — hai script này chạy
  thật các query trích từ `data-model.md`, nên phải đổi cùng lượt hoặc guard đỏ.
- **Out of scope:** `lib/`, `.drift`, migration, ARB, golden — và toàn bộ quyết
  định nghiệp vụ mới của Study, vì chúng chưa chốt xong.
- **Editable documents:** `docs/product.md`, `docs/architecture.md`,
  `docs/business-rules.md`, `docs/data-model.md`, `docs/use-cases.md`,
  `docs/master-flow.md`, `docs/README.md`, `docs/wbs.md`
- **Output:** không file mới; 312 lượt đổi tên trong `docs/`
- **Acceptance criteria:**
  - [x] Tên miền là `study`; danh từ theo sau mang **đơn vị**: `study_sessions`
        (phiên) · `study_answers` (lượt) · `card_study_states` (lịch một thẻ).
  - [x] `review` nghĩa **rà soát** không bị đụng: `docs/reviews/`, "vòng review
        UI/UX", "code review", "reviewer", "Review KPI".
  - [x] `reviewing` giữ nguyên — nó là tên một giai đoạn trong `new`/`beginning`/
        `reviewing`/`mastered`, không phải tên chức năng; đổi thành "studying" sẽ
        mất phân biệt với `beginning`.
  - [x] `data-model.md` mang khối nói rõ tên trong tài liệu là **tên đích** còn
        database đang ở v3, kèm bảng tra cũ ↔ mới.
  - [x] `check_docs.py` xanh, gồm self-test 15 invariant query; guard `memox-v7`
        xanh; `code_snippets_test.dart` xanh.
- **Dependencies:** M4.12
- **Tests required:** `check_docs.py`, `verify_invariants.py` self-test, guard
  `memox-v7`, `code_snippets_test.dart`
- **Checklist phases:** 14.1

**Vì sao không thay được bằng một lệnh.** `review` ở đây mang hai nghĩa: *ôn tập*
và *rà soát*. Riêng `wbs.md` có 228 lượt, phần lớn là nghĩa thứ hai — "vòng review
UI/UX", "review 1:1 parity checklist". Một lệnh thay toàn cục sẽ phá đúng những
dòng ghi lại việc rà soát đã làm. Đợt này chạy theo ba nhóm, đo trước mỗi nhóm:
định danh kỹ thuật, prose nghĩa ôn tập, rồi tab/route/định danh sót. Nhóm thứ hai
phải khớp qua `\s+` chứ không phải chuỗi phẳng, vì tài liệu wrap ở 80 cột nên
"review state" có khi nằm trên hai dòng.

**Cái suýt bị bỏ qua.** `verify_invariants.py` giữ một schema `CREATE TABLE`
hardcode rồi chạy các invariant query trích thẳng từ `data-model.md`. Đổi tên bảng
trong tài liệu mà quên fixture thì 15 query chạy trên schema cũ và guard đỏ —
không phải vì tài liệu sai, mà vì hai nửa của cùng một phép kiểm nói hai thứ tiếng.

**Còn nợ, và cố ý để nợ:** `lib/` (8 file/thư mục mang tên `review`), `.drift`,
schema v4 cho rename bảng/cột, ARB (`navigationReviewLabel` → `navigationStudyLabel`,
copy "Review" → "Study"), và các golden mang tên `review`. Chúng là task riêng vì
cần một migration, và migration nên đi cùng đợt schema mà nghiệp vụ Study sẽ yêu
cầu — thứ vẫn đang được chốt.

### M5.0b · Chốt nghiệp vụ Study vào tài liệu frozen

- **Status:** done — chỉ tài liệu và fixture của guard. Không dòng code sản phẩm
  nào; schema vẫn v3.
- **Goal:** Đưa các quyết định nghiệp vụ đã chốt vào đúng tài liệu sở hữu chúng,
  trước khi M5.0 sinh code từ những tài liệu đó.
- **Scope:** `business-rules.md` (sửa BR-16, BR-18, BR-23, BR-26, BR-30, BR-80,
  BR-92; thêm **BR-96…BR-105**), `data-model.md` (bảng `study_queue_items`;
  `study_sessions.mode`/`cursor`; `study_answers.mode`; ma trận `status` ×
  `end_reason`; **3 invariant mới**), `use-cases.md` (UC-05 đảo thứ tự bước, thêm
  A2b và A3b), `architecture.md` (**AD-16**), `product.md` (hai trục SRS ×
  StudyMode), `verify_invariants.py` (fixture cho bảng và cột mới).
- **Out of scope:** `lib/`, `.drift`, migration, ARB, golden. Và sáu điểm còn mở
  — xem dưới; chúng được ghi là **chưa chốt** trong chính tài liệu thay vì đoán.
- **Editable documents:** `docs/business-rules.md`, `docs/data-model.md`,
  `docs/use-cases.md`, `docs/architecture.md`, `docs/product.md`, `docs/wbs.md`
- **Output:** BR-96…BR-105, AD-16, bảng `study_queue_items`, invariant 16–18
- **Acceptance criteria:**
  - [x] Tập StudyMode là thuộc tính của thuật toán (`stageSequence`), cùng khuôn
        `supportedActions` mà BR-30 đã cấm hardcode.
  - [x] Session **chỉ** sinh từ hành động Study tường minh (BR-101).
  - [x] Hàng đợi lưu DB và bất biến trong phiên (BR-102); UC-05 đảo bước để queue
        được lấy **trước** khi session được tạo.
  - [x] `interrupted` vào ma trận `status` × `end_reason` và vào invariant 12.
  - [x] Ba invariant mới chạy được: mỗi câu fire trên đúng vi phạm của nó
        (`verify_invariants.py` 18/18).
  - [x] Mốc đến hạn neo 00:00 địa phương (BR-105), và AD-16 nói rõ ai quy đổi.
  - [x] `check_docs.py` xanh; guard `memox-v7` xanh.
- **Dependencies:** M5.0a
- **Tests required:** `check_docs.py`, `verify_invariants.py` (18 query), guard
  `memox-v7`
- **Checklist phases:** 14.1

**Ba quyết định đáng ghi lại vì sao, không chỉ ghi là gì.**

**BR-23 đảo thứ tự** — thẻ đến hạn trước, thẻ mới lấp phần dư. Luật cũ cho thẻ
mới đi trước, và trên một deck 200 thẻ mới cộng 30 thẻ quá hạn thì mọi phiên đều
là 50 thẻ mới: 30 thẻ quá hạn **không bao giờ** được ôn. Nó ẩn vì deck nhỏ không
lộ ra — chỉ hiện khi người dùng nhập một bộ lớn, tức đúng lúc mất mát là lớn nhất.

**BR-102 kéo hàng đợi từ `presentation/` vào database.** Lý do không phải
persistence: hàng đợi mang luật — thứ tự BR-23, lượt quay lại BR-26, trần BR-104 —
và một cấu trúc mang luật nằm trong `presentation/` là chỗ luật đi ra khỏi tầm
với của mọi phép kiểm. Đặt vào DB biến "snapshot bất biến" từ lời hứa thành ràng
buộc, và cho phép BR-103 tồn tại.

**BR-105 neo mốc đến hạn vào đầu ngày lịch.** `now + N*24h` đẩy hạn muộn dần theo
giờ bấm: học 23:00 thì hôm sau 22:00 thẻ chưa tới hạn, và mỗi phiên đẩy thêm một
chút — giờ học trôi về khuya cho tới khi người dùng hụt hẳn một ngày. AD-16 giữ
`domain/` không phải biết múi giờ: scheduler trả **số ngày**, một collaborator
nhận offset từ composition root quy ra thời điểm, đúng đường `clockProvider` đã đi.

**Sáu điểm cố ý để trống**, ghi thẳng trong `business-rules.md`: ngưỡng tối thiểu
của `match` và `recall`; `guess` so "khác nghĩa" bằng đâu; `kind` của một lượt
thuộc bốn mode mới; trần 50 thẻ áp cho mode nào; phiên có cho chọn scope hẹp hơn
không; và `fill` đếm eligibility theo số thẻ có `example` nên con số của nó khác
mọi mode còn lại. Mỗi câu trả lời khác nhau cho ra một thiết kế khác nhau, nên
đoán ở đây rẻ hơn nhưng đắt hơn nhiều ở M5.2.

### M5.0c · Kiến trúc StudyMode: Strategy, một điểm phân giải, và suffix `_mode`

- **Status:** done — tài liệu, naming contract và một guard rule. Không dòng code
  sản phẩm nào.
- **Goal:** Chốt hình dạng triển khai của năm StudyMode trước khi M5.1 viết class
  đầu tiên, để năm mode không mọc thành năm bản sao của cùng một luồng.
- **Scope:** `architecture.md` (**AD-18**), `business-rules.md` (**BR-106**,
  **BR-107**), `CLAUDE.md` + `memox-naming-rules.yaml` +
  `check_architecture.py` (thêm suffix `_mode`), `scopes.yaml` +
  `memox-architecture-rules.yaml` (rule `single_study_mode_dispatch`).
- **Out of scope:** viết handler thật (M5.1); sáu điểm nghiệp vụ còn mở của
  M5.0b.
- **Editable documents:** `docs/architecture.md`, `docs/business-rules.md`,
  `docs/wbs.md`, `CLAUDE.md`
- **Output:** AD-18, BR-106, BR-107, rule `memox.architecture.single_study_mode_dispatch`
- **Acceptance criteria:**
  - [x] Suffix `_mode` được cả ba nơi giữ danh sách chấp nhận: `CLAUDE.md`, guard
        YAML, `check_architecture.py`. Thiếu một nơi là file bị từ chối ở nơi còn lại.
  - [x] AD-17 nói rõ vì sao **không** dùng Template Method ở đây.
  - [x] BR-106 gỡ mâu thuẫn "review không có đúng/sai".
  - [x] Rule chặn nhánh `StudyMode` thứ hai trong `domain/`/`data/` **đã được
        chứng minh là fire** trên một file thử, rồi dọn sạch.
  - [x] `check_docs.py` xanh; guard `memox-v7` xanh (70 rule).
- **Dependencies:** M5.0b
- **Tests required:** `check_docs.py`, guard `memox-v7`
- **Checklist phases:** 14.1, 14.2

**Đề xuất gốc là Java, và phần không chuyển sang được là chỗ đặt luồng chung.**
Khuôn `interface → abstract base giữ process() → năm concrete override hook` có
mục tiêu đúng. Nhưng luồng một lượt học có mười bước, bảy trong đó là I/O phải nằm
trong **một transaction** — ghi `study_answers`, cập nhật `card_study_states`,
tăng `cursor`, đặt `available_at`, `answers_in_session`, đóng phiên khi hết hàng
đợi. `CLAUDE.md` cấm hoisting đúng loại luật đó ra khỏi repository.

Nên hoặc abstract base cầm repository và mở transaction — biến `domain/` thành nơi
chứa I/O — hoặc nó không làm bảy bước ấy, và phần chung còn lại đúng ba bước, quá
mỏng để dựng một tầng kế thừa cho năm class. Luồng chung vì thế ở lại
`SubmitStudyAnswerUseCase`: use case **chính là** template method, mode trở thành
Strategy với hai trách nhiệm thuần — `validateInput` và `evaluate`.

Kèm theo một cái được không định trước: Dart không có final method, nên một
`process()` public luôn override được. Không có `process()` thì cũng không có gì
để bypass — vấn đề biến mất thay vì phải canh bằng contract test, đúng thứ đề xuất
gốc phải dặn ở mục 5.

**Fail-fast chuyển từ startup sang compile.** Registry kiểu factory-nhận-collection
kiểm "đủ năm mode" lúc khởi động; `switch` exhaustive trên enum của Dart 3 kiểm
lúc biên dịch, và thêm mode thứ sáu thì compiler chỉ thẳng vào mọi chỗ chưa xử lý.
Trùng enum và "mode không hỗ trợ" trở thành bất khả thi về kiểu.

**Rule mới không cấm switch, nó cấm switch thứ hai.** Phạm vi cố ý dừng ở
`domain/` và `data/`: map một mode sang nhãn hay icon là việc của `presentation/`,
và cấm ở đó chỉ đẩy phép map sang chỗ tệ hơn. Rule đã được thử bằng một file vi
phạm thật trước khi commit — một rule chưa từng fire là một rule chưa ai biết có
chạy không.

### M5.0d · Một phiên là chuỗi stage, và `review` tách làm hai

- **Status:** done — tài liệu và fixture guard. Không code sản phẩm.
- **Goal:** Thay mô hình "một phiên một mode do người dùng chọn" bằng "một phiên
  chạy chuỗi stage cố định của thuật toán", theo đặc tả Review Cards.
- **Scope:** `business-rules.md` (BR-96 `superseded`; sửa BR-30, BR-97, BR-98,
  BR-99, BR-102, BR-106; thêm **BR-108…BR-114**), `data-model.md`
  (`study_sessions.current_mode`, `study_queue_items.mode`, PK ba cột, sửa
  invariant 18), `use-cases.md` (UC-05 bỏ bước chọn mode, thêm A0 và A0b),
  `product.md`, `architecture.md` (`supportedModes` → `stageSequence`),
  `verify_invariants.py`.
- **Out of scope:** ngưỡng dữ liệu tối thiểu của từng stage; UI của từng stage.
- **Editable documents:** `docs/business-rules.md`, `docs/data-model.md`,
  `docs/use-cases.md`, `docs/product.md`, `docs/architecture.md`, `docs/wbs.md`
- **Output:** BR-108…BR-114; `study_queue_items` PK `(session_id, mode, card_id)`
- **Acceptance criteria:**
  - [x] Sáu StudyMode; `browse` và `self_assess` thay cho `review`.
  - [x] Chuỗi stage do thuật toán khai báo (`stageSequence`), người dùng không chọn.
  - [x] `browse` không sinh action, không ghi `study_answers`, không đổi lịch.
  - [x] Mỗi stage có hàng đợi riêng, thứ tự xoáo độc lập; PK ba cột enforce điều đó.
  - [x] Invariant 18 đếm `COUNT(DISTINCT card_id)` — đếm dòng sẽ báo động giả
        ngay ở phiên 11 thẻ × 5 stage.
  - [x] `verify_invariants.py` 18/18; `check_docs.py` xanh; guard xanh.
- **Dependencies:** M5.0c
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Đặc tả Review Cards mang theo một hệ quả chết người mà chính nó không nêu.** Nó
viết "Review tạo evidence hoàn tất stage nhưng **không tự cập nhật SRS**". Ghép với
BR-97 — `sm2` chỉ có `review` — thì deck dùng `sm2` chạy hết phiên mà **không có
gì ghi vào lịch**: `due_at` đứng yên vĩnh viễn, và một nửa số deck của app thôi là
ứng dụng spaced-repetition.

Gốc rễ là cái tên: `review` đang ôm hai việc khác nhau — "xem trước cho quen" và
"lật thẻ rồi tự chấm". Mô hình chuỗi cần cái thứ nhất; SRS cần cái thứ hai; và
`sm2` chỉ dùng được cái thứ hai vì bốn stage chấm điểm đều sinh tín hiệu nhị phân
mà SM-2 cần bốn mức. Tách thành `browse` và `self_assess` giải cả ba ràng buộc
bằng một đường: một tên một việc.

**BR-77 đã trả lời sẵn câu "lượt nào đổi lịch" mà không cần luật mới.** Lượt đầu
tiên của một thẻ trong phiên là `scheduled`; mọi lượt sau là `relearning`. Áp vào
chuỗi stage thì **stage chấm điểm đầu tiên quyết định lịch**, các stage sau chỉ để
luyện. Hệ quả được chấp nhận có ý thức chứ không phải đã cân nhắc đủ: sai ở Match
rồi đúng ba stage sau vẫn cho lịch của một lần sai. Hai hướng khác — stage cuối
quyết định, hoặc tổng hợp toàn chuỗi — đều cần luật mới; ghi lại trong
`business-rules.md` để lần xem lại không phải tự phát hiện.

**Invariant 18 suýt thành báo động giả.** Nó đếm số dòng `study_queue_items` mỗi
phiên và so với trần 50 của BR-24. Khi mỗi thẻ có một dòng **mỗi stage**, một phiên
11 thẻ × 5 stage đã là 55 dòng và invariant đỏ trên dữ liệu hoàn toàn hợp lệ. Sửa
thành `COUNT(DISTINCT card_id)`.

### M5.0e · Stage chấm điểm lặp bằng round, không bằng hàng đợi

- **Status:** done — tài liệu và fixture guard. Không code sản phẩm.
- **Goal:** Chốt cơ chế lặp lại thẻ chưa thuộc cho bốn stage chấm điểm, theo đặc
  tả Match Terms and Meanings.
- **Scope:** `business-rules.md` (thu hẹp BR-26 và BR-104 về `self_assess`; thêm
  **BR-115…BR-120**), `data-model.md` (`study_queue_items.round`, PK bốn cột, sửa
  invariant 17, thêm **invariant 19 và 20**), `use-cases.md` (UC-05 A0c),
  `verify_invariants.py`.
- **Out of scope:** khi nào `match` trả `almost` thay vì `wrong`; ngưỡng dữ liệu
  tối thiểu của từng stage.
- **Editable documents:** `docs/business-rules.md`, `docs/data-model.md`,
  `docs/use-cases.md`, `docs/wbs.md`
- **Output:** BR-115…BR-120; invariant 19, 20; PK `(session_id, mode, round, card_id)`
- **Acceptance criteria:**
  - [x] Bốn stage chấm điểm lặp bằng round; `self_assess` giữ BR-26/BR-104.
  - [x] Round 1 gồm toàn bộ thẻ đủ dữ liệu; round sau chỉ gồm thẻ không đạt, đã
        khử trùng.
  - [x] Thẻ từng sai vẫn thuộc tập không đạt kể cả sau đó làm đúng (BR-116).
  - [x] Mỗi round có thứ tự xoáo riêng (BR-117).
  - [x] Lượt thuộc về thẻ của **vế được chọn trước** (BR-118).
  - [x] Không trần số round (BR-119).
  - [x] `verify_invariants.py` **20/20**, hai câu mới fire trên đúng vi phạm.
- **Dependencies:** M5.0d
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Hai cơ chế lặp cho cùng một mục đích, và chúng không chồng lên nhau được.**
BR-26 cho thẻ sai quay lại **trong cùng hàng đợi** sau ≥3 thẻ khác, trần 3 lượt
(BR-104). Đặc tả Match cho thẻ sai quay lại **ở round sau**, sau khi bàn hiện tại
hết, và không giới hạn số round. Giữ cả hai nghĩa mỗi stage mới phải trả lời lại
câu "stage này lặp kiểu gì", nên bốn stage chấm điểm thống nhất về round và
BR-26/BR-104 thu hẹp còn `self_assess` — stage duy nhất không có "bàn" để hết.

**Không trần round là quyết định của chủ dự án, ngược với BR-104.** Nó có nghĩa
một thẻ người dùng không nhớ nổi sẽ chặn họ khỏi các stage còn lại của phiên.
Đánh đổi được chấp nhận vì bàn nhỏ dần sau mỗi round nên tiến độ nhìn thấy được,
khác với vòng lặp phẳng mà BR-104 tồn tại để cắt.

**BR-118 chặn một lỗi quy trách nhiệm rất dễ mắc.** Ghép sai gồm hai thẻ: thẻ của
vế được chọn trước, và thẻ sở hữu vế bị chọn nhầm. Chỉ thẻ thứ nhất không đạt —
người dùng chưa hề nói gì về thẻ thứ hai. Đánh dấu cả hai làm tập không đạt phình
ra theo mỗi lần nhầm tay, và thẻ đã thuộc bị kéo ngược vào round sau.

**Invariant 17 phải hẹp lại cùng BR-104.** Nó đang chặn `answers_in_session > 4`
cho mọi dòng; với round không trần thì một stage chấm điểm vượt 4 là hợp lệ. Giờ
điều kiện đó chỉ áp khi `mode = 'self_assess'`. Bù lại, hai invariant mới giữ cấu
trúc round trung thực: round không nhảy số, và tập của round N là con của round
N-1 — cái thứ hai là phát biểu SQL của chính BR-115.

### M5.0f · Luật của stage `guess`: năm lựa chọn, và nguồn distractor

- **Status:** done — chỉ tài liệu. Không code, không schema mới.
- **Goal:** Chốt luật dựng question của `guess` theo đặc tả Guess Card Meaning,
  dùng lại cơ chế sẵn có thay vì thêm khái niệm.
- **Scope:** `business-rules.md` (thêm **BR-121…BR-127**; đóng hai mục trong danh
  sách chưa chốt).
- **Out of scope:** ngưỡng của `match`, `recall`, `fill`; UI của stage.
- **Editable documents:** `docs/business-rules.md`, `docs/wbs.md`
- **Output:** BR-121…BR-127
- **Acceptance criteria:**
  - [x] Đúng năm lựa chọn mỗi question, một đúng và bốn distractor (BR-121).
  - [x] Distractor lấy từ **tập thẻ của phiên**, không từ round hiện tại (BR-122).
  - [x] "Khác nghĩa" đo bằng `back_folded`, không định nghĩa phép chuẩn hoá thứ
        hai (BR-123).
  - [x] Tách ca "pool không đủ" khỏi ca "question hỏng" (BR-124).
  - [x] Đánh giá bằng định danh, không bằng chuỗi hiển thị (BR-125).
  - [x] Một lựa chọn đầu tiên, một lượt (BR-126).
  - [x] Thứ tự thẻ và thứ tự lựa chọn là hai hoán vị độc lập (BR-127).
- **Dependencies:** M5.0e
- **Tests required:** `check_docs.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Không thêm bảng, không thêm cột — cả bảy luật dựng trên thứ đã có.**

**BR-122 tách hai khái niệm dễ bị gộp.** *Hàng đợi* là những thẻ đang được hỏi ở
round này; *tập thẻ của phiên* là nguồn lấy distractor. Gộp lại thì retry round
còn một thẻ sẽ không đủ năm lựa chọn — đúng ca mà BR-115 tạo ra thường xuyên
nhất. Thẻ đã đạt rời hàng đợi nhưng **không** rời tập nguồn.

**BR-123 dùng lại `back_folded` thay vì định nghĩa phép chuẩn hoá thứ hai.** Cột
đó có từ schema v3 (M4.11a) cho search: đã trim, hạ hoa và fold Unicode. Một phép
normalize riêng cho `guess` sẽ trôi khỏi phép kia ngay lần đầu có ai sửa một
trong hai, và không ai biết để sửa cả hai.

**BR-124 là chỗ đặc tả gốc và BR-114 nói ngược nhau — và cả hai đều đúng, cho hai
ca khác nhau.** Đặc tả nói thiếu distractor là lỗi chặn; BR-114 nói thẻ thiếu dữ
liệu thì bỏ qua có ghi nhận. Deck chỉ có ba thẻ thì `guess` **không bao giờ** dựng
được question, và hiện lỗi mỗi phiên là đổ cho người dùng một thứ họ không sửa
được bằng thao tác nào trong phiên — bỏ qua stage mới đúng, và BR-99 đã có sẵn câu
đó. Nhưng khi tập đủ năm mà một question vẫn hỏng thì chặn lại là đúng: render
bốn lựa chọn sẽ âm thầm đổi xác suất đoán trúng từ 20% lên 25%.

**Hai mục rời khỏi danh sách chưa chốt.** `guess` so "khác nghĩa" bằng đâu, và
ngưỡng tối thiểu của `guess`. Ngưỡng đó khác `match`/`recall` ở một điểm đáng chú
ý: nó là điều kiện của **cả stage**, không phải của từng thẻ, vì một question mượn
bốn thẻ khác để dựng.

### M5.0g · Luật của stage `recall`: 20 giây, và lý do thua

- **Status:** done — tài liệu và fixture guard. Không code sản phẩm.
- **Goal:** Chốt luật đếm giờ và tự chấm của `recall` theo đặc tả Recall and
  Self-grade, đặt phần đếm giờ đúng tầng.
- **Scope:** `business-rules.md` (**BR-128…BR-133**), `data-model.md`
  (`study_answers.outcome_reason`; `study_queue_items.remaining_ms`,
  `is_revealed`; **invariant 21 và 22**), `verify_invariants.py`.
- **Out of scope:** ngưỡng của `match` và `recall` về số thẻ tối thiểu; UI.
- **Editable documents:** `docs/business-rules.md`, `docs/data-model.md`,
  `docs/wbs.md`
- **Output:** BR-128…BR-133; invariant 21, 22
- **Acceptance criteria:**
  - [x] 20 giây đo bằng **thời gian tương tác thực**: tạm dừng khi app vào nền,
        không tính thời gian tải (BR-128).
  - [x] Đua tại mốc hết giờ cho đúng **một** kết cục (BR-129).
  - [x] Hết giờ khoá kết cục thành sai; không đổi được trong cùng lượt (BR-130).
  - [x] `outcome_reason = timeout` là cột thật, không suy từ `action` (BR-131).
  - [x] Nhãn màn hình không được lưu (BR-132).
  - [x] Thời gian còn lại persist để Resume không đặt lại; lượt ở round sau bắt
        đầu lại đủ 20 giây (BR-133).
  - [x] `verify_invariants.py` **22/22**.
- **Dependencies:** M5.0f
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**BR-131 là BR-76 lặp lại ở một chỗ khác.** Người học tự nhận quên và người học
hết giờ đều cho `action = forgotten`. Không có cột riêng thì hai điều đó không
phân biệt được từ dữ liệu đã lưu — mà chúng nói hai chuyện rất khác nhau về chất
lượng thẻ. `study_answers` là bảng chỉ thêm, nên một cột thiếu hôm nay không tính
ngược được ngày mai.

**BR-133 là hệ quả của BR-103, không phải một yêu cầu UI.** Phiên sống sót qua
việc hệ điều hành thu hồi app, nên "còn bao nhiêu giây" phải nằm trong database
chứ không trong bộ nhớ một controller. Ngược lại, một lượt mới ở round sau bắt
đầu lại đủ 20 giây — nó là lượt khác, không phải phần còn lại của lượt cũ.

**Đếm giờ nằm ở `presentation/`.** AD-13 và AD-16 đã chốt `lib/features/` không
đọc đồng hồ. Handler của `recall` nhận `didTimeout` và `elapsedMs` như input và
vẫn là hàm thuần — đúng khuôn AD-18 đặt cho mọi stage. Đó cũng là lý do BR-129
phát biểu cuộc đua bằng **thời điểm của sự kiện** chứ không bằng "ai chạy trước":
so hai timestamp là việc kiểm được, còn thứ tự thực thi thì không.

**Hai invariant mới giữ cho cột mới không lan ra chỗ khác.** Trạng thái timer chỉ
được tồn tại ở `recall`, và `outcome_reason = timeout` chỉ được xuất hiện ở
`recall` — nếu không, cột đặc thù một stage sẽ dần trở thành cột chung mà không ai
quyết định điều đó.

### M5.0h · Luật của stage `fill`: so khớp có phiên bản, và cái không lưu

- **Status:** done — tài liệu và fixture guard. Stage cuối trong năm.
- **Goal:** Chốt chính sách so khớp text của `fill` theo đặc tả Fill Card Answer.
- **Scope:** `business-rules.md` (**BR-134…BR-138**), `data-model.md`
  (`study_answers.comparison_version`, `used_hint`; **invariant 23**),
  `verify_invariants.py`.
- **Out of scope:** ngưỡng số thẻ tối thiểu của `match` và `recall`; UI.
- **Editable documents:** `docs/business-rules.md`, `docs/data-model.md`,
  `docs/wbs.md`
- **Output:** BR-134…BR-138; invariant 23
- **Acceptance criteria:**
  - [x] So khớp dùng lại `back_folded`: trim + hạ hoa Unicode, **giữ dấu**.
  - [x] Phiên bản chính sách lưu trên từng lượt (BR-135).
  - [x] Dùng gợi ý được ghi nhưng không đổi `action` (BR-136).
  - [x] Chuỗi rỗng sau trim không sinh lượt (BR-137).
  - [x] Nội dung người dùng gõ **không** được lưu (BR-138).
  - [x] `verify_invariants.py` **23/23**.
- **Dependencies:** M5.0g
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Điều đáng kiểm nhất là `back_folded` fold những gì, không phải nó tên là gì.**
Nếu nó bỏ dấu thì `fill` sẽ chấm "ma" bằng "mà" là đúng, và một app học từ vựng
tiếng Việt hỏng ở đúng chỗ quan trọng nhất. Đọc `card_text_model.dart` trước khi
dùng lại: *"Case only. `công` still does not match `cong`"* — nó trim và hạ hoa
Unicode-aware nhưng giữ nguyên dấu, tức đúng thứ `fill` cần. Suy từ cái tên
"folded" thì đã đi sai hướng.

**BR-135 là lý do `scheduler_version` tồn tại, áp cho một thứ khác.** Một lượt đã
ghi phải đọc lại được bằng chính luật đã tạo ra nó. Nới chính sách so khớp — ví dụ
bỏ qua dấu câu — sẽ biến những lượt sai của hôm qua thành đúng khi đọc lại, và
không có cách nào biết lượt nào đã được chấm theo luật nào.

**BR-138 là quyết định có thể lật, và hiện nghiêng về không lưu.** Câu trả lời sai
của người học là dữ liệu phân tích tốt, nhưng nó cũng là dữ liệu riêng tư (BR-51)
và chưa có tính năng nào đọc nó. Thêm cột khi có caller thật thì rẻ; gỡ một cột đã
đầy dữ liệu riêng tư thì không.

**Năm stage đã có luật đầy đủ.** Còn hai mục chưa chốt: ngưỡng số thẻ tối thiểu
của `match` và `recall`, và `kind` của một lượt thuộc bốn stage chấm điểm. Mục sau
đáng chốt trước khi viết code — `study_answers` chỉ thêm, nên ghi sai không sửa
lại được.

### M5.0i · Giới hạn thẻ thuộc phiên, mặc định 20, và lưu trên chính phiên

- **Status:** done — tài liệu và fixture guard.
- **Goal:** Chốt rằng năm stage dùng chung một tập thẻ, đổi trần từ 50 xuống 20,
  và chuẩn bị sẵn cho việc người dùng cài đặt số lượng.
- **Scope:** `business-rules.md` (sửa BR-24; thêm **BR-139**, **BR-140**),
  `data-model.md` (`study_sessions.card_limit`; viết lại invariant 18),
  `use-cases.md`, `master-flow.md`, `verify_invariants.py`.
- **Out of scope:** UI cài đặt số thẻ mỗi phiên — đến khi có màn Settings.
- **Editable documents:** `docs/business-rules.md`, `docs/data-model.md`,
  `docs/use-cases.md`, `docs/master-flow.md`, `docs/wbs.md`
- **Output:** BR-139, BR-140; `study_sessions.card_limit`
- **Acceptance criteria:**
  - [x] Giới hạn thuộc **phiên**, không thuộc stage hay round (BR-139).
  - [x] Mặc định 20, chốt một lần lúc mở phiên và lưu vào `card_limit`.
  - [x] Không stage nào có ngưỡng tối thiểu/tối đa riêng (BR-139).
  - [x] Điều kiện dựng được nội dung **không** bị hiểu thành ngưỡng thẻ (BR-140).
  - [x] Invariant 18 so với `card_limit` của chính phiên, không với hằng số.
  - [x] `verify_invariants.py` **23/23**; `check_docs.py` xanh.
- **Dependencies:** M5.0h
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Con số 20 không phải phần khó — chỗ nó được lưu mới là.** Người dùng sẽ cài đặt
được số thẻ mỗi phiên, nên một invariant viết `> 50` (hay `> 20`) sẽ sai ở đúng
phiên đầu tiên họ đổi, và sai theo kiểu tệ nhất: đỏ trên dữ liệu hoàn toàn hợp lệ.
Nên `card_limit` được chốt **một lần lúc mở phiên** và lưu trên chính phiên đó;
invariant 18 `JOIN` về đọc con số ấy. Đây là pattern repo đã dùng ba lần —
`scheduler_version`, `scheduler_generation`, `comparison_version`: một bản ghi
phải đọc lại được bằng chính tham số đã tạo ra nó.

**BR-140 tách hai thứ đang bị gọi cùng một tên.** "Ngưỡng của stage" có thể hiểu
là *stage này lấy bao nhiêu thẻ* — không còn tồn tại, năm stage dùng chung một tập
— hoặc *stage này có dựng được nội dung không*: `guess` cần năm nghĩa khác nhau
(BR-121, BR-124), `fill` cần thẻ có `example` (BR-114). Vế thứ hai vẫn còn và
quyết định stage **chạy hay bị bỏ qua**, không quyết định lấy bao nhiêu thẻ. Gộp
hai vế lại là cách một stage bị bỏ qua vì lý do sai.

**Còn đúng một mục chưa chốt trong toàn bộ nghiệp vụ Study:** một lượt của bốn
stage chấm điểm ghi `kind` là gì. BR-77 nói lượt đầu của thẻ trong phiên là
`scheduled`, nhưng nó được viết khi một phiên chỉ có một cách hỏi; giờ một thẻ có
thể có bốn lượt trong một phiên, và đó là ca BR-77 chưa từng phải xử lý.

### M5.0j · Lượt nào đổi lịch trong chuỗi stage — và vì sao cơ chế round đã trả lời

- **Status:** done — chỉ tài liệu. Đóng mục cuối cùng của nghiệp vụ Study.
- **Goal:** Phát biểu tường minh cách BR-77 áp vào một phiên nhiều stage, thay vì
  để người đọc sau tự suy.
- **Scope:** `business-rules.md` (**BR-141**; đóng danh sách chưa chốt).
- **Out of scope:** không đổi hành vi nào — BR-141 nói rõ thứ đã đúng sẵn.
- **Editable documents:** `docs/business-rules.md`, `docs/wbs.md`
- **Output:** BR-141
- **Acceptance criteria:**
  - [x] Lượt đầu tiên của thẻ trong phiên là `scheduled`; mọi lượt sau —
        retry round cùng stage hay stage kế — là `relearning`.
  - [x] Danh sách "chưa chốt" của nghiệp vụ Study **rỗng**.
  - [x] `check_docs.py` xanh.
- **Dependencies:** M5.0i
- **Tests required:** `check_docs.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Câu hỏi tưởng còn mở hoá ra đã được cơ chế round trả lời.** BR-119 bắt mỗi stage
lặp cho tới khi một round không còn thẻ sai, nên **lượt cuối của mọi stage luôn là
một lần đúng**. Nó không nói gì về trí nhớ — chỉ nói vòng lặp đã kết thúc. Thứ duy
nhất mang tín hiệu là **lần thử đầu tiên**, khi chưa stage nào nhắc bài.

Nên hai phương án còn lại đều sai theo cách đo được: lấy kết quả cuối chuỗi cho
mọi thẻ đều "nhớ được" và SRS mất sạch tín hiệu; cho mỗi stage đổi lịch một lần
thì một thẻ vừa quên ở Match vẫn leo bốn box trong một buổi, và `answer_count`
đếm 4 cho một lần học.

BR-77 vì thế đúng sẵn dù nó được viết khi một phiên chỉ có một cách hỏi. BR-141
không đổi hành vi — nó ghi lại lập luận, để lần sau không ai phải suy lại từ đầu
rồi rút ra một kết luận khác.

### M5.0k · Đổi tên Review → Study trong `lib/` (nửa Dart)

- **Status:** done — code Dart, ARB, route, golden. **Không đụng schema**: tên
  bảng và cột để nguyên cho M5.0l.
- **Goal:** Đóng nửa rẻ của khoảng lệch tên giữa tài liệu và code, không kèm
  migration.
- **Scope:** `lib/features/review/` → `lib/features/study/`; `CardReviewStateEntity`
  → `CardStudyStateEntity` và ba file mapper/entity đi kèm; `ReviewRepository` →
  `StudyRepository`; `ReviewPlaceholderScreen` → `StudyPlaceholderScreen`;
  `RouteNames.review`/`RoutePaths.review` → `study`, path `/review` → `/study`;
  ARB `navigationReviewLabel` → `navigationStudyLabel` (copy "Review" → "Study"),
  `reviewPlaceholderMessage` → `studyPlaceholderMessage`; tên query
  `cardsDueForReview` → `cardsDueForStudy`, `reviewStateByCard` →
  `studyStateByCard`; cây test và 4 golden tương ứng.
- **Out of scope:** tên bảng/cột (`card_review_states`, `review_history`,
  `review_count`, `first_review_at`, `reviewed_at`) và mọi định danh Drift sinh ra
  từ chúng — M5.0l.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/`, 4 golden đổi tên + regenerate
- **Acceptance criteria:**
  - [x] `flutter analyze` sạch; `flutter test` **1404 pass**.
  - [x] guard `memox-v7`, `check_architecture`, `check_generated` xanh.
  - [x] Không định danh Drift-generated nào bị đổi.
  - [x] `docs/reviews/`, "reviewer", "in review" — nghĩa **rà soát** — giữ nguyên.
- **Dependencies:** M5.0j
- **Tests required:** toàn bộ suite, golden, guard, architecture
- **Checklist phases:** 14.1

**Ranh giới của PR này là "cái gì sinh ra từ `.drift`".** `CardReviewStateEntity`
là entity viết tay nên đổi được ngay; `CardReviewState` — không có hậu tố
`Entity` — là **row class Drift sinh từ bảng `card_review_states`**, nên đổi nó ở
đây là đổi thứ sẽ bị regenerate ghi đè. Một phép thay chuỗi đã quét trúng nó và
`flutter analyze` bắt được ngay; nếu ranh giới không rõ từ đầu thì lỗi đó lọt vào
diff dưới dạng "sửa cho nhất quán".

**Golden đổi vì copy đổi, không vì quyết định thị giác.** Tab thứ hai từ "Review"
thành "Study" nằm trong pixel của bốn golden navigation bar. `MxNavigationBar`
nhận label đã dịch từ caller, nên chỉ golden specimen hardcode label mới đổi —
mọi golden khác không nhúc nhích, và đó là bằng chứng ranh giới component vẫn
đúng.

**`test/design_preview/review_screen_*` giữ nguyên tên.** Nó là preview harness
cho `ReviewScreen.jsx` **của design kit** — tên riêng của kit, cùng loại với
`docs/reviews/`. Đổi nó sẽ làm mất liên kết với artefact nó đang tham chiếu.

**Còn nợ, và là toàn bộ nội dung của M5.0l:** tên bảng và cột, cộng `reviewCount`,
`firstReviewAt`, `lastReviewedAt` — chúng là tên field Dart do Drift sinh từ cột,
nên chỉ đổi được cùng migration.

### M5.0l · Schema v4: đổi tên bảng, cột và index

- **Status:** done — migration thuần đổi tên. Không thêm, không xoá, không ghi
  lại dòng nào.
- **Goal:** Đóng nốt khoảng lệch tên giữa tài liệu và database, để `data-model.md`
  thôi phải mang khối tra cứu cũ ↔ mới.
- **Scope:** `.drift` (2 bảng, 5 cột, 3 index), migration v3 → v4 trong
  `app_database.dart`, `schemaVersion` 3 → 4, `drift_schema_v4.json`,
  `test/drift/generated/schema_v4.dart`, định danh Drift trong code tay, raw SQL
  trong test, và `docs/data-model.md`.
- **Out of scope:** `study_queue_items` và các cột của nghiệp vụ Study — chúng
  đến ở migration sau, cùng M5.0/M5.1.
- **Editable documents:** `docs/data-model.md`, `docs/wbs.md`
- **Output:** schema v4; `migration_v4_test.dart`
- **Acceptance criteria:**
  - [x] `card_review_states` → `card_study_states`; `review_history` →
        `study_answers`.
  - [x] `review_count` → `answer_count`; `last_reviewed_at` → `last_answered_at`;
        `review_kind` → `kind`; `reviewed_at` → `answered_at`;
        `first_review_at` → `first_answered_at`.
  - [x] Ba index đổi tên; `idx_history_*` → `idx_study_answers_*`.
  - [x] Migration giữ nguyên **giá trị** của mọi dòng, giữ `kind`, giữ
        `first_answered_at`, và giữ cả foreign key — bốn test riêng cho bốn điều
        đó.
  - [x] `flutter test` **1408 pass**; analyze, format, guard, architecture,
        check_generated, check_docs xanh.
  - [x] Khối tra cứu cũ ↔ mới trong `data-model.md` đã **xoá**.
- **Dependencies:** M5.0k
- **Tests required:** `migration_v4_test.dart`, `migration_test.dart`,
  `schema_test.dart`, toàn bộ suite
- **Checklist phases:** 11.1, 14.1

**Một phép thay chuỗi đã phá chính migration, và `analyze` không thấy gì.** Đợt
đổi raw SQL trong test quét cả `app_database.dart`, biến
`ALTER TABLE card_review_states RENAME TO card_study_states` thành
`RENAME card_study_states TO card_study_states` — câu lệnh đọc gọn gàng, biên dịch
sạch, và là một no-op sẽ nổ trên database v3 thật vì bảng đích chưa tồn tại.
`flutter analyze` không nhìn được vào trong một chuỗi; nhóm test v3 → v4 là thứ
bắt được. Doc comment của `_renameForV4` giờ nói thẳng rằng mọi tên **cũ** trong
đó là load-bearing và không được "sửa cho nhất quán".

**`ALTER TABLE … RENAME` chứ không create-copy-drop.** SQLite đổi tên cột từ
3.25, và với `legacy_alter_table` tắt nó cũng viết lại foreign key và định nghĩa
index trỏ tới bảng vừa đổi. Cách chép bảng sẽ dời từng dòng cho một thay đổi
không đụng dữ liệu, và cần `PRAGMA foreign_keys = OFF` bao quanh — đúng cái pragma
database này từ chối tắt. Test cuối trong nhóm v4 kiểm chính điều đó: xoá một thẻ
và đòi dòng `study_answers` biến mất theo.

**Test rename phải seed dữ liệu, không thì nó không kiểm gì.** `migrateAndValidate`
so sánh **hình dạng** schema, nên nó pass trên database rỗng và pass luôn nếu
migration đã drop rồi tạo lại hai bảng. Đọc giá trị ra sau đó là thứ phân biệt hai
trường hợp.

**Một literal đã chờ sẵn để hỏng.** `migration_test.dart` gọi
`migrateAndValidate(db, 3)` ở hai chỗ, trong khi chính file đó có một comment dặn
"target là `db.schemaVersion`, không phải literal". Bump lên v4 làm cả hai đỏ ngay.
Đã đổi sang `db.schemaVersion`, nên v5 sẽ không lặp lại.

> **M5.0b…M5.0j mô tả mô hình một-phiên-một-chuỗi, đã bị M5.0m thay.** Các mục đó
> giữ nguyên vì lý do trong chúng vẫn là lý do — nhưng chỗ nào chúng nói "một phiên
> chạy năm stage", "thẻ mới lấp phần dư" hay "stage chấm điểm đầu tiên quyết định
> lịch", đó là mô hình cũ. `business-rules.md` là nơi đọc trạng thái hiện tại.

### M5.0m · Hai loại phiên: học mới và ôn tập

- **Status:** done — tài liệu và fixture guard. Viết lại phần lớn nghiệp vụ Study
  đã chốt ở M5.0b…M5.0j.
- **Goal:** App tạo môi trường học theo năng lực người dùng, không chạy đua số
  lượng thẻ — và chỉ lần học đầu tiên mới đi qua cả chuỗi stage.
- **Scope:** `business-rules.md` (sửa BR-13, BR-23, BR-24, BR-29, BR-75, BR-90,
  BR-109, BR-110, BR-139, BR-141; thêm **BR-142…BR-149**), `data-model.md`
  (`card_study_states.learned_at`, `study_sessions.session_kind`, `kind` thêm
  `learning`, `decks.study_config`, bảng **`app_settings`**, invariant **24–27**),
  `use-cases.md` (UC-05 luồng chính viết lại), `product.md`, `master-flow.md`,
  `verify_invariants.py`.
- **Out of scope:** UI của hai popup; migration v5 — đến cùng M5.0/M5.1.
- **Editable documents:** `docs/business-rules.md`, `docs/data-model.md`,
  `docs/use-cases.md`, `docs/product.md`, `docs/master-flow.md`, `docs/wbs.md`
- **Output:** BR-142…BR-149; `app_settings`; invariant 24–27
- **Acceptance criteria:**
  - [x] Hai loại phiên tách hẳn, không trộn thẻ (BR-142).
  - [x] Phiên ôn tập lấy **toàn bộ** thẻ đến hạn, tối đa `card_limit`; không lấp
        thêm thẻ mới cho đủ số (BR-23, BR-24).
  - [x] `card_limit` là trần **mỗi lần lấy**, không phải hạn mức ngày (BR-24).
  - [x] Chuỗi stage chỉ cho học mới; ôn tập chọn một mode chấm điểm, `browse`
        không phải lựa chọn (BR-109, BR-146).
  - [x] Không có thẻ đến hạn ⇒ **không mở được** phiên ôn tập (BR-145).
  - [x] Chuỗi học mới không đổi lịch; hoàn tất là một **sự kiện** đặt `learned_at`
        và khởi tạo lịch ở mức thấp nhất (BR-144).
  - [x] Tùy chọn học hai tầng: mặc định `app_settings`, ghi đè trên root deck
        (BR-147, BR-148).
  - [x] `verify_invariants.py` **27/27**, bốn query mới đều fire trên đúng vi
        phạm của nó.
- **Dependencies:** M5.0l
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Yêu cầu của chủ dự án, nguyên văn hai ý.** Một: có 8 thẻ đến hạn thì học 8, lấy
thêm 12 thẻ mới cho đủ 20 là chạy đua số lượng chứ không phải học. Hai: chỉ lần
đầu mới cần cả năm cách hỏi; từ lần sau là ôn tập và người học chọn cách ôn.

**BR-144 làm một vấn đề biến mất thay vì phải xử lý nó.** Câu hỏi ban đầu là "phiên
học mới bỏ dở giữa chừng thì sao" — thẻ đã bị đặt lịch nhưng chưa học xong, và
lần học mới sau sẽ đặt lại lịch lần hai. Gỡ chuyện đó cần hoàn tác
`card_study_states` từ `previous_*`, giảm `lapse_count`, xoá lượt — tức sửa BR-86,
thứ tồn tại để đảm bảo không lượt nào bị mất.

Không đặt lịch cho tới khi xong chuỗi thì **không có gì để hoàn tác**: thẻ bỏ dở
chưa có `learned_at`, chưa có `due_at`, nên nó nằm lại trong tập học mới và học
lại từ `browse`. Các lượt đã ghi vẫn ở nguyên dưới `kind = 'learning'` — chúng là
lịch sử thật về việc người học đã gặp thẻ đó.

**Hoàn tất học mới là sự kiện, không phải lượt đánh giá** — và đó là lý do nó
không cần một `action` tổng kết. Bốn stage chấm điểm đều lặp round tới khi sạch
(BR-119), nên mọi thẻ đều kết thúc chuỗi bằng một lần đúng: một action suy từ đó
sẽ luôn là "nhớ được" và không phân biệt được thẻ nào. Thẻ vừa học lần đầu vì thế
bắt đầu ở mức thấp nhất và gặp lại ngay ngày học kế.

**BR-90 phải đổi định nghĩa, không chỉ đổi câu chữ.** "Thẻ mới" đang là
`answer_count = 0`. Chuỗi học mới không sinh lượt `scheduled` nào, nên thẻ học xong
vẫn có `answer_count = 0` và sẽ hiển thị là mới. Định nghĩa đúng bây giờ là
`learned_at IS NULL` — và nó cũng là định nghĩa mà BR-142 dùng để chia hai tập.

**Bốn invariant mới giữ hai trạng thái không tách rời nhau.** Thẻ có `learned_at`
phải có lịch; thẻ chưa có `learned_at` không được mang lượt `scheduled`;
`kind = 'learning'` không được xuất hiện ngoài phiên học mới; tùy chọn học không
được nằm trên deck con. Cả bốn đã được chứng minh fire trên vi phạm của chính
chúng trước khi commit.

### M5.0n · Recursive review nghiệp vụ Study trước khi viết code

- **Status:** done — chín vòng, dừng khi vòng cuối không tìm thêm được gì.
- **Goal:** Bắt các luật cũ chưa theo kịp mô hình hai loại phiên, **trước** khi
  M5 sinh code từ chúng.
- **Scope:** `business-rules.md` (sửa 12 BR, thêm **BR-150…BR-152**),
  `use-cases.md` (UC-05 A0/A1/A2b, UC-07), `product.md`, `architecture.md`,
  `wbs.md`.
- **Out of scope:** không đổi quyết định nghiệp vụ nào — chỉ đưa các luật cũ về
  đúng mô hình đã chốt ở M5.0m.
- **Editable documents:** `docs/business-rules.md`, `docs/use-cases.md`,
  `docs/product.md`, `docs/architecture.md`, `docs/wbs.md`
- **Output:** BR-150, BR-151, BR-152
- **Acceptance criteria:**
  - [x] Không BR nào còn nói lượt đầu của thẻ trong **mọi** phiên là `scheduled`.
  - [x] Không tài liệu nào còn định nghĩa "thẻ mới" bằng `answer_count`.
  - [x] Reset không còn để lại thẻ `learned_at` mà không có lịch (BR-152).
  - [x] Badge và pill có luật riêng, cùng ngôn ngữ với popup Study (BR-150,
        BR-151).
  - [x] Vòng cuối của phép quét không tìm thêm phát hiện nào.
  - [x] `check_docs.py`, `verify_invariants.py` 27/27, guard xanh.
- **Dependencies:** M5.0m
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Mười hai luật cũ nói bằng từ vựng của mô hình đã bị thay.** Nặng nhất là BR-77
— *"lượt đầu tiên của một thẻ trong một session MUST là `scheduled`"* — mâu thuẫn
thẳng BR-144, vốn nói phiên học mới không sinh lượt `scheduled` nào. Hai luật cùng
`active`, cùng nói về cùng một lượt, và nói ngược nhau. Cùng loại: BR-27, BR-20
(*"cả **hai** loại lượt"* khi đã có ba), BR-113, BR-28 (`browse` không sinh action
nào để mà "khác `forgotten`"), và BR-99 (*"stage bị bỏ qua"* không áp được khi
người dùng đã **chọn** mode).

**Một mâu thuẫn chỉ lộ ra khi đọc invariant vừa viết.** BR-41/BR-42 nói Reset xoá
lịch nhưng giữ nội dung; nếu `learned_at` thuộc "nội dung" thì mỗi lần Reset để
lại một thẻ **đã học xong nhưng không có lịch** — đúng thứ invariant 24 được viết
để chặn, và một thẻ không thuộc tập nào trong hai tập của BR-142. BR-152 đưa cả
hai về NULL cùng lúc.

**BR-22 bị thay, và nó chạm tới code đang chạy.** Badge trên deck list, pill
Due/New trên card list và `cardsDueForStudy` đều implement `due_at IS NULL OR
due_at <= now`. Trong mô hình mới `due_at IS NULL` nghĩa là *chưa học xong*, không
phải *đến hạn ngay* — nên một con số gộp hai tập đang trộn hai việc chênh nhau năm
lần công sức. BR-150 và BR-151 đưa hai con số về đúng ngôn ngữ popup Study dùng.

**Phép quét bằng máy tìm được thứ đọc bằng mắt bỏ sót**, và ngược lại. Bốn vòng
đầu đọc từng BR; bốn vòng sau grep theo mẫu — "lấp phần dư", "năm mode", "mode
`review`", "answer_count = 0" — và bắt được `architecture.md` AD-18 nói "năm mode"
khi đã sáu, `product.md` M3 còn ghi mode `review`, và một đoạn prose trong chính
`business-rules.md` vẫn giải thích theo mô hình cũ. Không phép nào thay được phép
kia: grep không hiểu mâu thuẫn giữa hai luật, mắt không quét hết 179 trích dẫn.

### M5.0o · Recursive review lượt hai — đổi góc nhìn thay vì đọc lại

- **Status:** done — sáu góc, hội tụ ở 0 phát hiện.
- **Goal:** Tìm những gì lượt một không thể tìm, bằng cách soi từ phía schema,
  invariant, code và kịch bản biên thay vì đọc lại từng luật.
- **Scope:** `business-rules.md` (thêm **BR-153**), `use-cases.md` (UC-05 khôi
  phục trích dẫn, UC-06), `master-flow.md`, `architecture.md`, `data-model.md`
  (khối nợ code).
- **Out of scope:** không đổi quyết định nghiệp vụ nào.
- **Editable documents:** `docs/business-rules.md`, `docs/use-cases.md`,
  `docs/master-flow.md`, `docs/architecture.md`, `docs/data-model.md`, `docs/wbs.md`
- **Output:** BR-153; khối "năm chỗ trong `lib/` implement định nghĩa đã bị thay"
- **Acceptance criteria:**
  - [x] Không tài liệu nào (trừ ledger) còn trích BR đã `superseded` như luật
        đang dùng.
  - [x] UC-05 trích lại BR-106 và BR-107 — nguồn của `action`.
  - [x] Mọi mode có điều kiện dựng được nội dung rõ ràng, gồm `match` (BR-153).
  - [x] Nợ code được ghi ở nơi người viết M5 sẽ đọc.
  - [x] Vòng cuối của cả sáu phép quét trả về **0**.
- **Dependencies:** M5.0n
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Lượt một đã hội tụ, nên lặp lại nó sẽ cho đúng kết quả cũ.** Sáu góc mới:
đối chiếu cột mà luật nhắc với schema thật; đối chiếu hai chiều giữa BR và
invariant; tìm trích dẫn tới BR đã `superseded`; tìm BR active không xuất hiện ở
UC nào; đọc code tìm chỗ implement định nghĩa đã đổi; và thử kịch bản biên.

**Góc "BR nào biến mất khỏi UC" bắt được một mất mát thật.** Viết lại luồng chính
UC-05 ở M5.0m đã làm rơi **BR-106 và BR-107** — chính là luật nói `action` từ đâu
ra. Đọc UC-05 sau đợt đó không còn biết `self_assess` lấy action trực tiếp từ
người dùng còn bốn mode kia chấm nhị phân rồi ánh xạ. Không phép kiểm nào của
lượt một thấy được điều này: cả hai luật vẫn đúng, vẫn `active`, chỉ là không còn
ai trích.

**Góc kịch bản biên bắt được `match` với một thẻ.** Người dùng tạo deck, thêm thẻ
đầu tiên, bấm Học mới ngay — đó là ca thật, không phải ca biên. Ghép cặp cần ít
nhất hai cặp; một cặp thì đáp án hiển nhiên và một lượt đúng không chứng minh gì.
BR-121 lo cho `guess`, BR-114 lo cho thẻ thiếu dữ liệu, không luật nào lo cho
`match`. BR-153 đóng chỗ đó, và đoạn prose đi kèm liệt kê ngưỡng của cả sáu mode
cạnh nhau — vì chúng khác nhau và trước giờ nằm rải rác.

**Góc đọc code tìm ra thứ không tài liệu nào ghi.** Năm chỗ trong `lib/` đang
implement `answer_count = 0` là "thẻ mới" và `due_at IS NULL` là "đến hạn" — cả
hai đã bị BR-90 và BR-142 thay. Chúng **đúng với schema v4** và chỉ đổi được khi
có `learned_at`, nhưng không tài liệu nào nói vậy: người viết M5 sẽ hoặc tưởng tài
liệu sai, hoặc sửa code trước khi có cột để sửa. `data-model.md` giờ có bảng liệt
kê năm chỗ đó cạnh khối "chưa tồn tại ở schema nào".

### M5.0p · Recursive review lượt ba — thi hành thử thay vì đọc

- **Status:** done — bốn lỗ, một trong đó là bug chết người. Hội tụ ở 0 trên cả
  ba góc của lượt một, hai và ba.
- **Goal:** Lấy tình huống cụ thể, chạy qua từng luật, và coi chỗ nào luật không
  đủ để quyết định là chỗ hở.
- **Scope:** `business-rules.md` (sửa BR-103, BR-122, BR-144; thêm **BR-154**),
  `use-cases.md` (UC-05 bước 1, 4, 10).
- **Out of scope:** không đổi quyết định nghiệp vụ nào ngoài ba câu hỏi đã hỏi.
- **Editable documents:** `docs/business-rules.md`, `docs/use-cases.md`,
  `docs/wbs.md`
- **Output:** BR-154; ba luật sửa
- **Acceptance criteria:**
  - [x] Thẻ không có `example` **hoàn tất được** chuỗi học mới (BR-144).
  - [x] `guess` chạy được ngay ở phiên học mới đầu tiên của một deck (BR-122).
  - [x] Còn phiên dở mà muốn đổi loại phiên thì có đường đi (BR-103).
  - [x] Màn chọn mode ôn tập hiện số thẻ **của từng mode** (BR-154).
  - [x] Bảng thi hành mode × điều kiện không còn ô nào không quyết định được.
  - [x] Vòng cuối của cả ba góc trả về **0**.
- **Dependencies:** M5.0o
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Bug chết người: thẻ không có `example` mắc kẹt vĩnh viễn.** BR-144 nói hoàn tất
khi thẻ *"đi hết stage cuối"*; BR-114 nói thẻ thiếu dữ liệu bị **bỏ qua** ở stage
đó; `fill` là stage cuối của `eight_box` và cần `example`. Ghép ba câu lại: thẻ
không có `example` không bao giờ đi hết `fill`, nên `learned_at` không bao giờ
được đặt, nên nó ở lại tập Học mới **mãi mãi** và bị học lại mỗi phiên. `example`
là trường tuỳ chọn (BR-95), nên đây là đa số thẻ, không phải ca hiếm.

Ba luật đều đúng khi đọc riêng. Chỉ khi **thi hành** một thẻ cụ thể qua chuỗi thì
hệ quả mới hiện ra — và đó là thứ hai lượt review trước không thể tìm, vì cả hai
đều đọc luật chứ không chạy chúng.

**`guess` không bao giờ chạy ở phiên học mới đầu tiên.** BR-122 lấy distractor từ
thẻ `learned_at IS NOT NULL`; trên deck mới chưa thẻ nào như vậy, nên pool rỗng và
stage bị bỏ qua. Thẻ của chính phiên hiện tại giờ cũng vào pool — chúng đã qua
`browse` nên người học vừa nhìn thấy cả hai mặt, tức chúng là nhiễu thật.

**Con số ở màn chọn mode nói dối ba trên bốn mode.** Popup đầu hiện "Ôn tập (20
từ)"; chọn `fill` thì chỉ ôn được số thẻ có `example` — có thể là 2. BR-154 bắt
mỗi mode hiện số của riêng nó.

**Bảng thi hành là công cụ, không phải một lần đọc.** Dựng ma trận mode × điều
kiện — deck 1/3/5/20 thẻ, có/không `example`, pool đầy/rỗng — rồi hỏi từng ô
"stage nào chạy, thẻ hoàn tất sau stage nào". Ô nào không trả lời được bằng một
luật là một lỗ. Ba lượt review dùng ba góc khác nhau và mỗi góc bắt một loại lỗi:
mâu thuẫn giữa các luật, luật mất kết nối, và luật đúng nhưng ghép lại thành hành
vi sai.

### M5.0q · Recursive review lượt bốn — và điểm dừng

- **Status:** done — hai phát hiện, cả hai đều nhẹ. **Lượt cuối nên chạy trước
  M5.**
- **Goal:** Thử hai góc chưa dùng — "ai ghi và ai đọc từng cột", và "vòng đời một
  thẻ qua nhiều ngày" — rồi đánh giá xem còn đáng rà nữa không.
- **Scope:** `data-model.md` (bảng ánh xạ cột → BR), `business-rules.md` (ghi chú
  hệ quả của mốc 00:00).
- **Out of scope:** không đổi luật nào.
- **Editable documents:** `docs/data-model.md`, `docs/business-rules.md`,
  `docs/wbs.md`
- **Output:** bảng ánh xạ 16 cột → BR; ghi chú day-boundary
- **Acceptance criteria:**
  - [x] Mọi cột của Study tra ngược được về luật yêu cầu nó.
  - [x] Hệ quả "học lúc 23:00 thì đến hạn sau một giờ" được ghi ở nơi người đọc
        BR-105 sẽ thấy.
  - [x] Vòng đời 78 ngày chạy qua chín lượt ôn không sinh mâu thuẫn nào.
- **Dependencies:** M5.0p
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1

**Góc "ai ghi cột này" không tìm ra cột mồ côi, và đó là kết quả tốt.** Mười trong
mười sáu cột không được BR nào gọi thẳng tên — nhưng mọi cột đều có một luật yêu
cầu **hành vi** mà nó phục vụ. Đó là đúng phân công: `business-rules.md` nói luật,
`data-model.md` nói hình dạng. Cái thiếu là chiều tra ngược, nên bảng ánh xạ 16
dòng giờ nằm trong `data-model.md` — người viết M5 cần biết "cột này tồn tại vì
luật nào" trước khi đụng vào nó.

**Góc vòng đời chạy một thẻ qua 78 ngày và chín lượt ôn**, gồm một lần quên ở
ngày 15: box về 1, `lapse_count` +1, rồi leo lại tới box 6. Không mâu thuẫn nào
giữa BR-15, BR-16, BR-20, BR-88, BR-90 và BR-91. Cái nó lộ ra là một **hệ quả**,
không phải lỗi: thẻ học xong lúc 23:00 đến hạn sau một giờ, thẻ học lúc 09:00 sau
mười lăm giờ. Đó là giá của việc neo vào ngày lịch thay vì cộng giờ, và cái mua
được — giờ học không trôi về khuya — lớn hơn. Giờ nó được ghi ở nơi người đọc
BR-105 sẽ thấy.

**Lợi tức đã giảm rõ rệt, và đây là chỗ nên dừng.** Bốn lượt: lượt một tìm 9 mâu
thuẫn, lượt hai tìm 3 mất kết nối, lượt ba tìm 4 lỗ trong đó một là bug chết
người, lượt bốn tìm 2 và cả hai chỉ là tài liệu hoá. Ba phép quét của ba lượt
trước đều trả về 0. Rà thêm cần một góc thứ năm, và góc đó nhiều khả năng là
**chạy code thật** — tức chính M5.

### M5.0r · Tồn đọng và recursive review lượt năm — góc "tài liệu chưa ai rà"

- **Status:** done — một invariant mới, và nợ IT scenario được ghi.
- **Goal:** Đóng tồn đọng, rồi rà bằng góc duy nhất còn lại: những tài liệu bốn
  lượt trước chưa từng mở.
- **Scope:** `data-model.md` (**invariant 28**), `docs/it-scenarios/README.md`
  (bảng nợ scenario + profile fixture), `verify_invariants.py`.
- **Out of scope:** sửa IT scenario — chúng **đúng với code hiện tại**; sửa sớm
  làm chúng fail trên bản đang chạy.
- **Editable documents:** `docs/data-model.md`, `docs/it-scenarios/README.md`,
  `docs/wbs.md`
- **Output:** invariant 28; bảng "bốn scenario và một profile phải đổi khi M5 land"
- **Acceptance criteria:**
  - [x] `learned_at IS NULL AND due_at IS NOT NULL` bị chặn (invariant 28).
  - [x] `verify_invariants.py` **28/28**, câu mới fire trên đúng vi phạm.
  - [x] Bốn IT scenario và profile `C-P-NEW` được ghi là nợ, kèm lý do và cách sửa.
  - [x] `checklist.md` xác nhận sạch — cả ba lượt "review" đều nghĩa rà soát.
- **Dependencies:** M5.0q
- **Tests required:** `check_docs.py`, `verify_invariants.py`, guard `memox-v7`
- **Checklist phases:** 14.1, 15.5

**Góc thứ năm là những tài liệu chưa ai mở.** Bốn lượt trước rà `business-rules`,
`data-model`, `use-cases`, `architecture`, `product`, `master-flow`. Chưa từng
đụng: 60 IT scenario, `checklist.md`, `README.md` của `it-scenarios`.

**Và nó tìm ra một lỗ hổng thật trong invariant.** Bảng profile fixture định nghĩa
`C-P-NEW` là *New, đến hạn ngay, `due_at = T0 − 1 giờ`*. Sau M5 đó là thẻ **chưa
học xong nhưng đã có lịch** — thứ BR-144 cấm. Kiểm lại thì **không invariant nào
chặn cặp đó**: invariant 24 chặn chiều ngược (`learned_at` có mà `due_at` NULL),
25 chặn lượt `scheduled` trên thẻ chưa học, và cặp `learned_at NULL` + `due_at NOT
NULL` lọt qua cả hai. Invariant 28 đóng nó.

Đáng chú ý là **cách** nó lộ ra: không phải bằng đọc luật, mà bằng đọc một **bảng
dữ liệu thử** viết cho mô hình cũ. Fixture là nơi mô hình bị ép thành giá trị cụ
thể, và giá trị cụ thể thì hoặc hợp lệ hoặc không — không có chỗ cho diễn giải.

**IT scenario là nợ, không phải lỗi.** Bốn scenario mô tả `due_at IS NULL` là
"đến hạn ngay"; chúng **đúng với schema v4** và đã chạy 60/60 ở M4.11b. Sửa bây
giờ làm chúng fail trên bản đang chạy. Ghi vào `it-scenarios/README.md` cùng cách
`data-model.md` ghi nợ code — cùng một thay đổi, cùng một thời điểm.

### M5.0s · Schema v5: toàn bộ cột và bảng mà Study cần

- **Status:** **done** — analyze sạch, 1424 test xanh, guard sạch, invariants 28/28
- **Goal:** Đưa `data-model.md` sau brainstorm vào SQLite, một lần, trước khi có
  dòng code Study nào chạm vào nó.
- **Scope:** `card_study_states.learned_at`; `study_sessions.session_kind`,
  `current_mode`, `cursor`, `card_limit`; `study_answers.mode`, `outcome_reason`,
  `comparison_version`, `used_hint` và giá trị `learning` của `kind`;
  `decks.study_config`; bảng `study_queue_items` và `app_settings`; migration
  v4 → v5 và snapshot `drift_schema_v5.json`.
- **Out of scope:** mọi thứ đọc các cột này — entity, repository, use case đều là
  M5.0 trở đi. Năm chỗ trong `lib/` đang dùng định nghĩa cũ (`answer_count = 0`
  là "mới") **có** đổi ở đây, vì `learned_at` đến ở chính migration này và để lại
  thì hai định nghĩa "mới" cùng chạy.
- **Editable documents:** `docs/data-model.md` (bảng thứ tự migration), `docs/wbs.md`
- **Output:** `lib/core/database/tables/*.drift`, `app_database.dart`,
  `drift_schemas/drift_schema_v5.json`, `test/database/migration_v5_test.dart`
- **Acceptance criteria:**
  - [x] `kind` nhận thêm `learning`; `end_reason` nhận thêm `interrupted`.
  - [x] `study_queue_items` PK là `(session_id, mode, round, card_id)` (BR-113).
  - [x] `app_settings` có `CHECK (id = 1)` — bảng không thể có dòng thứ hai.
  - [x] Migration v1→v5, v2→v5, v3→v5 và v4→v5 đều mở được; test khẳng định dữ
        liệu v4 giữ nguyên giá trị sau khi lên v5.
  - [x] Thẻ đang có `due_at` từ trước v5 nhận `learned_at` =
        `COALESCE(last_answered_at, due_at)` chứ không NULL — để NULL thì invariant
        28 đỏ ngay lần mở app đầu tiên sau cập nhật. Tiêu chí ban đầu viết
        `learned_at = due_at`; `due_at` là một ngày ở tương lai, không phải thời
        điểm học xong.
  - [x] `verify_invariants.py` 28/28 chạy trên fixture đã đồng bộ với v5.
  - [x] `SchemaVerifier.migrateAndValidate(db, db.schemaVersion)` xanh.
- **Vì sao một migration chứ không phải năm.** Mỗi cột ở đây vô nghĩa nếu thiếu
  các cột còn lại: `session_kind` không có `learned_at` thì không chia được hai
  tập, `study_queue_items` không có `current_mode` thì không biết stage nào đang
  chạy. Chia nhỏ chỉ tạo ra những phiên bản trung gian không phiên bản nào của
  app từng chạy — tức những migration không ai test thật.
**Hai bảng phải dựng lại, không phải `ALTER`.** SQLite không đổi được `CHECK`, mà
`study_answers.kind` thêm `learning` còn `study_sessions.end_reason` thêm
`interrupted`. Đó là dạng migration duy nhất có thể mất sạch dữ liệu mà
`migrateAndValidate` không thấy — nó so schema, và bảng rỗng thì schema vẫn đúng.
Nên mọi test ở đây gieo dòng trước rồi đọc lại sau.

**SQL viết tay phải nói `INTEGER`, không phải `DATETIME`.** Drift dịch kiểu thời
gian giúp ở `.drift`; SQL viết tay thì không, và `migrateAndValidate` từ chối cặp
lệch đó. Bảy dòng đầu tiên viết `DATETIME` đều đỏ.

**Định nghĩa "mới" đổi cùng migration, không để lại.** Năm chỗ trong `lib/` dùng
`answer_count = 0` chuyển sang `learned_at IS NULL` (BR-90). Để lại thì hai định
nghĩa "mới" cùng chạy, và cái cũ sai hẳn: chuỗi học mới không ghi lượt `scheduled`
nào, nên một thẻ đi hết năm stage vẫn đọc ra `answer_count = 0`.

**Một việc ngoài danh sách, do guard đòi:** `fake_card_repository.dart` vượt 400
dòng vì đúng một dòng thêm vào. Tách `CardFixtures` thành mixin riêng thay vì cắt cho
vừa — seam có thật: phần đó dựng giá trị, không trả lời lời gọi repository nào.

- **Dependencies:** M5.0r
- **Tests required:** `migration_v5_test.dart` cho bốn đường lên; test backfill
  `learned_at`; `verify_invariants.py`
- **Checklist phases:** 8.3, 14.3

### M5.0 · Study domain và data — gồm cả hàng đợi

- **Status:** **done** — analyze sạch, 1458 test xanh, guard sạch, invariants 28/28
- **Goal:** Dựng phần domain và data mà **chỉ Study** cần, trên schema v5.
- **Scope:** entity `StudySessionEntity`, `StudyAnswerEntity`,
  `StudyQueueItemEntity`, `CardStudyStateEntity`; enum `StudyMode` (sáu giá trị,
  BR-108), `StudySessionKind`, `StudyAnswerKind` (ba giá trị, BR-75),
  `StudyAction`, `SessionStatus`, `SessionEndReason`, `NewCardOrder`; repository
  contract cho UC-05; DAO, mapper, `StudyRepositoryImpl` — **kể cả engine hàng
  đợi**: dựng hàng đợi lúc mở phiên, `cursor`/`available_at` của BR-26, dựng
  round kế tiếp của BR-115/BR-116, ghi lượt atomic, và sự kiện hoàn tất chuỗi
  học mới của BR-144.
- **Out of scope:** công thức scheduler (M5.1); use case (M5.2); controller và
  UI (M5.3, M5.4).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/domain/`, `lib/features/study/data/`
- **Acceptance criteria:**
  - [x] `domain/` là Dart thuần — không Flutter, không Drift.
  - [x] Repository contract không nhận hay trả kiểu sinh bởi Drift (AD-01).
  - [x] Ghi một lượt = cập nhật queue item + insert `study_answers` (+ cập nhật
        `card_study_states` nếu là `scheduled`) trong **một** transaction (BR-86).
  - [x] Hoàn tất chuỗi học mới đặt `learned_at` **và** `due_at` cùng lúc, trong
        một transaction, và **không** ghi lượt `scheduled` nào (BR-144, BR-149).
  - [x] `forgotten` ở `self_assess` đặt `available_at = cursor + 3`; khi hàng đợi
        còn dưới 3 thẻ khác, thẻ vẫn quay lại ở cuối — test cả hai nhánh (BR-26).
  - [x] Round kế tiếp chỉ gồm thẻ **từng sai** trong round vừa xong, kể cả thẻ sau
        đó làm đúng để rời bàn (BR-116) — test khẳng định đúng ca này.
  - [x] Round mới có hoán vị `position` khác round trước khi còn ≥2 thẻ (BR-117).
  - [x] Không exception persistence thô nào thoát khỏi repository.
  - [x] Bất biến 12 và 16…28 vẫn pass sau toàn bộ bộ test.
**BR-116 không cần thêm cột.** Luật nói thẻ *từng sai* trong một round thuộc tập
trượt, kể cả khi sau đó làm đúng để rời bàn — và schema v5 không có cờ "đã sai".
Cách tránh thêm cột: **ghi thẻ vào round kế ngay lúc sai**, trong cùng transaction.
Tư cách thành viên của round sau *chính là* bản ghi, và một câu trả lời đúng sau đó
không xoá được nó. `position` lấy ngẫu nhiên chứ không theo thứ tự sai, nên round sau
vẫn có hoán vị riêng (BR-117).

**Một lỗi thật do test bắt: BR-84 đòi hai việc không thể cùng một transaction.** Phiên
generation cũ phải bị đánh dấu `invalidated` **và** lượt không được ghi. Để chứng
trong cùng transaction thì việc đánh dấu bị rollback cùng với lượt bị từ chối, và
phiên nằm lại ở `in_progress` — vẫn mời ghi tiếp những lượt không bao giờ được
chấp nhận. Phép kiểm generation vì thế chạy **trước** transaction và commit riêng;
transaction đọc lại phiên và chỉ từ chối.

**Guard bắt một vi phạm kiến trúc đúng.** `_modeCapacity` switch trên `StudyMode`
trong `data/` — AD-18 nói chính sách của một mode thuộc handler của nó. Bỏ hẳn:
`watchStudyEntry` trả **dữ kiện** (`dueCount`, `fillableCount`, `distinctMeanings`),
còn việc quy ra số mỗi mode để cho resolver ở M5.1.

**Một lỗi cũ lộ ra khi sửa:** `deck.drift` vẫn đếm badge bằng vị từ BR-22, tức thẻ
chưa học cũng bị tính là đến hạn — đúng lỗi PR #152 đã sửa cho danh sách thẻ, còn sót
ở badge deck. Sửa luôn, vì để lại là hai định nghĩa "đến hạn" cùng chạy. Seeder
`insertReviewState` cũng tự nó vi phạm invariant 28 — đặt `due_at` mà không đặt
`learned_at`; giờ nó suy ra cặp, nên mọi fixture nằm đúng phía của BR-149.

**Chia làm hai PR.** Contract phải có trước để use case của M5.2 có cái để viết
dựa vào, còn implementation đi kèm bộ test riêng của nó; gộp làm một PR thì phần
review đáng chú ý nhất — các phép ghi trong transaction — nằm lẫn giữa vài trăm dòng
khai báo kiểu.

**Contract cố tình **không** biết thuật toán chạy stage nào.** `openSession` được
**truyền** `stageSequence` (BR-97). Để repository hỏi scheduler thì kiến thức thuật
toán rơi xuống tầng data, và thêm một thuật toán thành sửa hai chỗ.

**`nextItem` trả null không có nghĩa stage đã xong.** Nó còn nghĩa mọi thẻ còn lại
đang đợi hết khoảng ba thẻ của BR-26. `isStageExhausted` là câu hỏi tách hai ca đó ra;
gộp chúng làm phiên kết thúc sớm đúng ba thẻ.

- **Vì sao hàng đợi nằm ở đây, không ở M5.3.** BR-102 chuyển hàng đợi vào
  database, và các luật nó mang — thứ tự BR-23, quay lại BR-26, round BR-115 —
  đều cần **dữ liệu tại đúng thời điểm ghi**. Đó là tiêu chí `CLAUDE.md` dùng để
  quyết định cái gì MUST NOT lên use case: kiểm ở trên repository là đặt phép
  kiểm ra ngoài transaction. WBS bản trước xếp hàng đợi vào M5.3 vì khi đó nó còn
  là trạng thái tạm của controller; BR-102 đã bỏ điều đó.
- **Dependencies:** M5.0s
- **Tests required:** entity, enum, mapper; repository test cho transaction và
  rollback; test riêng cho BR-26 hai nhánh, BR-116, BR-117, BR-144
- **Checklist phases:** 14.2, 14.3, 15.1

### M5.1 · `StudyScheduler` — chuỗi stage và hai implementation

- **Status:** **done** — analyze sạch, 1521 test xanh, guard sạch
- **Goal:** Thuật toán SRS là hàm thuần khiết, và nó là nơi **duy nhất** biết
  stage nào chạy theo thứ tự nào.
- **Scope:** `domain/scheduler/study_scheduler.dart` với `supportedActions`,
  **`stageSequence`** (BR-97, BR-110) và **`reviewModes`** (BR-146);
  `EightBoxScheduler` (BR-15, BR-16), `Sm2Scheduler` (BR-17, BR-18, BR-19); ánh
  xạ kết quả nhị phân → action của BR-107.
- **Out of scope:** dùng scheduler trong controller (M5.3) hay ghi DB (M5.0).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/domain/models/` (`study_scheduler.dart`, `eight_box_scheduler.dart`, `sm2_scheduler.dart`, `study_day_model.dart`, `study_schedule_model.dart`)
- **Acceptance criteria:**
  - [x] `next()` không gọi `DateTime.now()`; `now` là tham số (AD-06).
  - [x] `eight_box`: `stageSequence` = `[browse, match, guess, recall, fill]`,
        `reviewModes` = `[match, guess, recall, fill]`,
        `supportedActions` = `[forgotten, remembered]` (BR-110, BR-146, BR-30).
  - [x] `sm2`: `stageSequence` = `[browse, self_assess]`,
        `reviewModes` = `[self_assess]`,
        `supportedActions` = `[again, hard, good, easy]`.
  - [x] `browse` không nằm trong `reviewModes` của bất kỳ thuật toán nào (BR-146).
  - [x] Ma trận 8 box × 2 action của `eight_box` đều có test và khớp BR-15, BR-16.
  - [x] Card box 8 trả lời `remembered` vẫn ở box 8, hạn +128 ngày (BR-16).
  - [x] `sm2`: `ease_factor` không xuống dưới 1.3 kể cả sau 50 lượt `again` (BR-19).
  - [x] `sm2`: `repetitions` 0 → interval 1; 1 → 6; ≥2 → `round(interval * ef)` (BR-18).
  - [x] Không import Flutter hay Drift ở bất kỳ file scheduler nào.
**`domain/` chỉ có năm bucket, không có `scheduler/`.** Bản kế hoạch ghi output là
`domain/scheduler/`; `architecture_boundary_test` từ chối ngay, và nó đúng — CLAUDE.md
liệt kê đúng `entities/ · repositories/ · models/ · usecases/ · failures/`. File giữ
suffix `_scheduler` (bảng naming cho phép) và nằm trong `models/`. Chỗ sai là WBS,
không phải test.

**BR-18 nhân interval với ease factor **mới** — chủ dự án chốt ở M5.1a.** Bản đầu
triển khai theo cách đọc sát chữ (hệ số cũ), vì tài liệu không nói thứ tự. Thứ tự
giờ nằm thẳng trong BR-18 thay vì trong commit message, vì đây đúng loại mơ hồ mà
người đọc kế tiếp sẽ tự suy lại và suy khác.

**`binaryAction` trả null cho `sm2` thay vì bịa một ánh xạ.** BR-107 chỉ nói cho
`eight_box`, và `sm2` không có stage chấm điểm nào (BR-146). Cho nó trả
`again`/`good` là tự đặt ra nghiệp vụ; trả null làm lỗi của caller hiện ra thay vì chấm
sai âm thầm.

**Hai action của thuật toán kia bị **từ chối**, không bỏ qua.** Một dòng history từ
deck đã đổi thuật toán trước khi khoá có thể mang action lạ; chấm đại nó tệ hơn dừng.

- **Dependencies:** M5.0
- **Tests required:** unit test toàn ma trận `eight_box`; unit test công thức
  `sm2` gồm biên sàn ease factor; test `stageSequence`, `reviewModes`,
  `supportedActions` của cả hai
- **Checklist phases:** 14.2, 15.1

### M5.1a · BR-18 nhân với ease factor mới

- **Status:** **done** — analyze sạch, 1521 test xanh, guard sạch
- **Goal:** Gỡ một mơ hồ của BR-18 trước khi nó kịp neo vào integration test.
- **Scope:** `business-rules.md` (BR-18), `sm2_scheduler.dart`, `sm2_scheduler_test.dart`
- **Out of scope:** BR-19 — công thức hệ số không đổi, chỉ thứ tự đổi.
- **Editable documents:** `docs/business-rules.md`, `docs/wbs.md`
- **Output:** BR-18 nói rõ thứ tự; scheduler nhân với hệ số sau cập nhật
- **Acceptance criteria:**
  - [x] BR-18 nêu thứ tự tường minh, kèm con số phân biệt hai cách đọc.
  - [x] `hard` từ interval 10, ef 2.5 → **24 ngày**, không phải 25.
  - [x] `good` vẫn cho kết quả cũ — nó không đổi hệ số nên không phân biệt được.
  - [x] Sàn 1.3 vẫn giữ sau 50 lượt `again`.

**Sửa tài liệu chứ không chỉ sửa code.** BR-18 không sai — nó **im lặng** về thứ tự,
và pseudocode đặt phép nhân trước khi nhắc tới BR-19 nên cách đọc sát chữ cho ra hệ
số cũ. Để nguyên thì người đọc kế tiếp suy lại và suy khác — và không test nào bắt
được, vì cả hai cách đọc đều cho cùng kết quả với `good`, là action phổ biến nhất.

**Đây là lý do sửa ngay thay vì sau M5.6.** Chỉ một test hiện neo vào con số này. Sau
khi integration test và fixture demo chạy qua vài chu kỳ `sm2`, con số ấy nằm trong
dữ liệu kỳ vọng của nhiều chỗ và đổi hướng thành một đợt sửa rải rác.

- **Dependencies:** M5.1
- **Tests required:** `sm2_scheduler_test.dart` — ca `hard` tách hai cách đọc
- **Checklist phases:** 14.2, 15.1

### M5.2 · Use case: mở phiên, ghi lượt, hoàn tất, đóng phiên

- **Status:** **done** — analyze sạch, 1541 test xanh, guard sạch
- **Goal:** Mỗi tương tác của UC-05 có đúng một use case, và không use case nào
  đọc repository của feature khác.
- **Scope:** `StartLearningSessionUseCase`, `StartReviewingSessionUseCase`,
  `SubmitStudyAnswerUseCase`, `AdvanceStageUseCase`, `EndStudySessionUseCase`,
  `WatchStudyEntryUseCase` (một lượt đọc trả **cả hai** số của BR-150 và số thẻ
  từng mode của BR-154).
- **Out of scope:** hàng đợi (M5.0 — nó chạy trong transaction); UI (M5.3, M5.4).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/domain/usecases/`
- **Acceptance criteria:**
  - [x] Phiên `learning` chỉ lấy thẻ `learned_at IS NULL`; phiên `reviewing` chỉ
        lấy `learned_at IS NOT NULL AND due_at <= now`. Không phiên nào trộn (BR-142).
  - [x] Mở `reviewing` khi tập đến hạn rỗng → `Failure`, **không** tạo session
        (BR-145, BR-101) — test khẳng định không có dòng nào được ghi.
  - [x] Phiên `learning` không sinh lượt `scheduled` nào (BR-141, BR-144).
  - [x] Trong `reviewing`, lượt đầu của mỗi thẻ ghi `scheduled`, các lượt sau ghi
        `relearning`, và `relearning` **không** đổi `due_at`/`current_box` (BR-77, BR-78).
  - [x] Thẻ box 8 + `remembered` vẫn ghi `scheduled` dù box không đổi (BR-76) —
        đây là ca mà suy luận sẽ sai.
  - [x] Ghi từ session có generation cũ → `Failure`, không ghi `study_answers`,
        session chuyển `invalidated`/`stale_generation` (BR-84).
  - [x] `card_limit` chốt một lần lúc mở phiên; đổi tùy chọn sau đó không ảnh
        hưởng phiên đang chạy (BR-139).
  - [x] Giá trị hiệu lực của tùy chọn = `decks.study_config` của root nếu có,
        ngược lại `app_settings` (BR-147) — test cả hai nhánh.
  - [x] Một lượt đọc duy nhất trả cả số chưa học lẫn số đến hạn (AD-13).
**Một use case cho cả hai loại phiên, không phải hai.** WBS đặt tên
`StartLearningSessionUseCase` và `StartReviewingSessionUseCase`, nhưng mở phiên là
**một** tương tác; cái khác nhau là lấy tập thẻ nào và chạy stage nào, mà cả hai đều
do thuật toán và BR-142 trả lời sẵn. Tách đôi sẽ nhân đôi phần đọc tùy chọn, đọc
generation và xử lý từ chối — và hai bản sao ấy sẽ trôi khỏi nhau. Tên thực tế:
`StartStudySessionUseCase`.

**Thêm `ResumeStudyDayUseCase`, không có trong scope ban đầu.** BR-103 cần **một** lời
gọi: đóng phiên của ngày trước rồi mới tìm phiên hôm nay. Tách làm hai cho phép
caller gọi ngược thứ tự và mời người dùng tiếp tục đúng phiên nó vừa đóng.

**Ba phương thức contract phải thêm.** Use case cần biết thuật toán của root
(`deckContext`), số liệu lịch của thẻ để đưa cho scheduler (`scheduleOf`), và thẻ nào
đã xong mọi stage để đánh dấu học xong (`cardsFinishedInSession`). Cái thứ ba là nơi
BR-114 sống: nó hỏi "không còn dòng `pending` nào", chứ không hỏi "đã qua stage cuối
của chuỗi" — thẻ bị `fill` bỏ qua vì thiếu `example` không có dòng nào ở đó để mà
pending, nên nó xong cùng những thẻ khác.

**Đọc lịch ngoài transaction rồi ghi trong transaction.** Use case đọc `scheduleOf`,
tính bằng scheduler, rồi gọi `submitAnswer`. Về lý thuyết là một khoảng hở; thực tế
mỗi deck chỉ có một phiên mở (BR-101) và không đường ghi nào khác đổi lịch, nên
không có ai để đua. Đưa phép tính vào trong transaction sẽ đặt công thức SRS vào
`data/`, đổi một rủi ro lý thuyết lấy một vi phạm kiến trúc thật.

- **Dependencies:** M5.1, M5.0
- **Tests required:** unit test cho từng acceptance criteria, dùng repository
  fake; test riêng cho ca box-8, ca generation cũ, và ca mở `reviewing` rỗng
- **Checklist phases:** 14.2, 15.1

### M5.3 · Controller và state của phiên

- **Status:** **done** — analyze sạch, 1551 test xanh, guard sạch
- **Goal:** State immutable, tách dữ liệu khỏi trạng thái tác vụ; controller là
  lớp mỏng gọi use case, không giữ luật.
- **Scope:** `StudySessionState` (freezed), `StudySessionController`
  (`@riverpod`), chống bấm đúp, chuyển stage khi hàng đợi của stage cạn.
- **Out of scope:** hàng đợi (M5.0); widget (M5.4).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/presentation/states/`,
  `lib/features/study/presentation/controllers/`
- **Acceptance criteria:**
  - [x] State immutable, có value equality; **không** có một `isLoading` chung.
  - [x] Controller không giữ `BuildContext` — `command_query_separation_test` xanh.
  - [x] Bấm hai lần liên tiếp cùng một action chỉ ghi **một** lượt (BR-126, BR-25).
  - [x] Ghi lượt sau khi controller bị dispose không throw (`ref.mounted`).
  - [x] Controller **không** tự quyết thứ tự thẻ hay thẻ nào quay lại — nó đọc
        thẻ kế tiếp từ use case; test khẳng định bằng cách đếm lời gọi.
  - [x] Test chuyển trạng thái: initial → loading → loaded; loading → error;
        submitting thành công; submitting thất bại.
**Không có cờ nào tên `isLoading`.** Guard cấm đúng cái tên đó, và nó đúng: state
này có **ba** cờ tác vụ — `isOpening`, `isAdvancing`, `isSubmitting`. Một cờ chung
không nói được "thẻ vẫn trên màn hình và câu trả lời đang được ghi", là trạng thái
màn hình ở lâu nhất, và cũng không tách được "mở phiên" với "lấy thẻ kế" — hai cái
đó cần hai loại chrome khác nhau.

**Phải mở rộng taxonomy controller — đây là chỗ tự quyết.**
`command_query_separation_test` biết ba loại notifier: command (state có
`SubmitState`), query (`build` trả Stream/Future), và input-state (còn lại, tối đa
một mutator). `StudySessionController` rơi vào loại thứ ba và có ba mutator, nên test
đỏ.

Không gấp được ba thành một: `answer` thất bại **phải** để thẻ lại trên màn hình,
còn `start` thất bại **phải** không để gì, và một mutator không mang được cả hai
nghĩa. Tách làm ba notifier còn tệ hơn: chúng dùng chung một phiên, nên tách là đặt
một giá trị sau ba chủ sở hữu.

Nên thêm loại thứ tư vào chính test đó: **session controller**, nhận diện bằng state
kết thúc `SessionState`, cho đúng `build/start/answer/leave` — có giới hạn chứ
không miễn trừ. Đây là sửa **test**, không phải sửa tài liệu frozen, và lý do nằm
ngay trong file. Nếu chủ dự án thấy không ổn thì phương án thay thế là tách
`leave` sang controller riêng và đưa `start` vào `build`.

**`nextItem` thành `nextTurn`.** Màn hình cần hàng đợi **và** nội dung thẻ cùng lúc;
hai lượt đọc có thể nằm hai bên một phép ghi, và đó là cách một màn hình hiện mặt
trước của thẻ này kèm đồng hồ của thẻ khác (AD-13).

- **Dependencies:** M5.2, M3.3
- **Tests required:** controller test cho toàn bộ chuyển trạng thái, chạy bằng
  `ProviderContainer`, không cần widget
- **Checklist phases:** 9.2, 9.3, 15.2

### M5.4 · Màn hình Study: lối vào, màn chọn mode, và sáu mode

- **Status:** todo — chia ba lát, xem M5.4a…M5.4c
- **Goal:** Người dùng đi được trọn UC-05 trên thiết bị.
- **Scope:** route, lối vào từ deck, màn chọn mode ôn tập, và widget của sáu
  StudyMode. Chuỗi lấy từ ARB, màu và khoảng cách lấy từ token.
- **Out of scope:** thống kê phiên (M5.5).
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/features/study/presentation/screens/`,
  `lib/features/study/presentation/widgets/{sections,items,overlays,support}/`,
  route mới trong `app/router/`
- **Acceptance criteria (áp cho cả ba lát):**
  - [ ] Nút action render từ `supportedActions`, không hardcode (BR-30, BR-97).
  - [ ] `grep -rn "Text('" lib/features/study/presentation` không có kết quả.
  - [ ] Mọi widget nằm đúng một trong bốn bucket của AD-15.
  - [ ] Render ở 320×568 và `textScaler` 2.0 → `takeException()` là null.
  - [ ] Light và dark mode đều có widget test.
  - [ ] Mọi màn và component dùng chung đăng ký trong Widgetbook.
- **Dependencies:** M5.3, M4.1, M3.6
- **Tests required:** xem từng lát
- **Checklist phases:** 14.4, 15.3

#### M5.4a · Lối vào, màn chọn mode, `browse` và `self_assess`

- **Status:** **done** — analyze sạch, 1455 test xanh (trừ golden Windows), guard sạch
- **Scope:** badge hai số của BR-150, màn chọn mode với số thẻ **mỗi mode**
  (BR-154), `browse` (hai mặt cùng lúc, không có bước lật — BR-112) và
  `self_assess` (lật rồi mới hiện action — BR-112).
- **Acceptance criteria:**
  - [x] Deck `eight_box` hiện **4** lựa chọn ôn tập; deck `sm2` vào thẳng
        `self_assess` không hiện màn chọn (BR-146).
  - [x] Mode không đủ dữ liệu bị vô hiệu hoá **kèm lý do**, không bị ẩn (BR-99).
  - [x] Không có đường nào mở phiên ôn khi tập đến hạn rỗng (BR-29, BR-145).
  - [x] `browse` không có nút action nào (BR-111).
  - [x] Bốn trạng thái loading, empty, error, loaded đều có widget test.
**`browse` và `self_assess` dùng chung một widget.** Chúng khác nhau đúng một điểm
(BR-112): `browse` hiện hai mặt cùng lúc và không có action nào, `self_assess` hiện
mặt trước rồi mới lật. Tách làm hai widget là hai bản sao layout và một khác biệt
thật — hai bản sao ấy sẽ trôi khỏi nhau ngay lần đổi typography đầu tiên.

**Số thẻ mỗi mode tính ở chọn-mode, không ở repository.** M5.0 đã bỏ switch trên
`StudyMode` khỏi `data/` theo AD-18; chính sách "mode này nhận được bao nhiêu thẻ"
giờ nằm ở widget chọn mode, đọc từ dữ kiện repository báo về. **Đây là chỗ tạm:**
khi handler của AD-18 ra đời ở M5.4b/c, phần này nên chuyển sang handler.

**Ba file phải đổi tên theo guard.** File trong `presentation/` phải kết thúc bằng
một suffix trong bảng naming, nên `*_section.dart` và `*_sheet.dart` thành
`*_widget.dart`. `showsBackImmediately` cũng đổi thành `shouldShowBackImmediately`
vì biến bool phải đọc như một vị từ.

**Một lỗi có sẵn, không phải của mốc này:** golden `deck_screens_demo_test` lệch
0.06% trên máy này, và lệch **cả trên `main` sạch**. Chúng là golden bound theo
Windows, chạy ở CI job riêng; số test báo ở trên là chạy với `--exclude-tags golden`.
Cần một lượt điều tra riêng, không gộp vào M5.

- **Tests required:** widget test 4 trạng thái × 2 thuật toán; test màn chọn khi
  một mode bị vô hiệu hoá; test deck `sm2` bỏ qua màn chọn

#### M5.4b · `match` và `guess`

- **Status:** todo
- **Scope:** bàn ghép cặp của `match`, câu hỏi năm lựa chọn của `guess`.
- **Acceptance criteria:**
  - [ ] `match` dưới hai cặp thì bỏ qua (phiên học) hoặc vô hiệu hoá (phiên ôn)
        — không bao giờ render bàn một cặp (BR-153).
  - [ ] Chọn nhầm vế sau **không** đánh dấu thẻ sở hữu vế đó là sai (BR-118).
  - [ ] `guess` render đúng **năm** lựa chọn, đáp án đúng xuất hiện đúng một lần
        (BR-121); hai thẻ cùng `back_folded` không cùng xuất hiện (BR-123).
  - [ ] Chọn được ghi bằng định danh, không bằng chuỗi hiển thị (BR-125).
  - [ ] Chạm lặp trên một question chỉ sinh một lượt (BR-126).
  - [ ] Thứ tự thẻ và thứ tự lựa chọn là hai hoán vị độc lập, ổn định khi Resume
        (BR-127).
- **Tests required:** widget test cho từng criteria; test khẳng định `almost` của
  `match` vào tập không đạt nhưng **không** vào `study_answers.action` (BR-120)

#### M5.4c · `recall` và `fill`

- **Status:** todo
- **Scope:** đồng hồ 20 giây của `recall`, ô nhập và chấm của `fill`.
- **Acceptance criteria:**
  - [ ] Đồng hồ tạm dừng khi app vào nền, và không tính thời gian tải (BR-128).
  - [ ] Tại mốc hết giờ chỉ **một** kết cục được ghi; thao tác trước mốc là
        reveal thủ công (BR-129) — test đúng ca đua này.
  - [ ] Hết giờ tự lật đáp án, khoá kết cục thành sai, và ghi
        `outcome_reason = timeout` (BR-130, BR-131).
  - [ ] Resume tiếp tục đúng `remaining_ms`, không đặt lại 20 giây; round sau bắt
        đầu lại đủ 20 giây (BR-133).
  - [ ] `fill` chấm bằng `back_folded` — `cong` **không** khớp `công` (BR-134).
  - [ ] Câu trả lời rỗng sau trim không sinh lượt, không tiến checkpoint (BR-137).
  - [ ] Nội dung người dùng gõ **không** được lưu ở bất kỳ đâu (BR-138, BR-51).
  - [ ] Dùng gợi ý được ghi nhưng không đổi `action` (BR-136).
- **Tests required:** widget test cho từng criteria; test đua reveal/timeout;
  test khẳng định không có chuỗi người dùng gõ nào chạm tới database

### M5.5 · Vòng đời phiên và kết thúc đúng trạng thái

- **Status:** todo
- **Goal:** Phiên luôn kết thúc ở đúng `status` và `end_reason`, và lượt đã ghi
  không bao giờ mất.
- **Scope:** chuyển trạng thái `completed` / `abandoned` / `invalidated` /
  `failed` kèm `end_reason` (BR-81…BR-86), **dọn phiên lỗi thời của ngày trước**
  (BR-103), màn tổng kết phiên tối thiểu.
- **Out of scope:** thống kê đầy đủ (ngoài MVP slice).
- **Editable documents:** `docs/wbs.md`
- **Output:** cập nhật use case và controller của M5.2, M5.3; widget tổng kết
- **Acceptance criteria:**
  - [ ] Hết mọi hàng đợi → `completed`, `end_reason` NULL, `ended_at` được đặt (BR-81).
  - [ ] Người dùng thoát → `abandoned` / `user_exit` (BR-82).
  - [ ] Phiên `in_progress` của ngày học trước, khi mở app → `abandoned` /
        `interrupted`, **không** phải `user_exit` (BR-103) — test khẳng định.
  - [ ] Reset deck khi phiên đang mở → `invalidated` / `scheduler_reset` (BR-83).
  - [ ] Ghi thất bại không thể tiếp tục → `failed` / `persistence_error` (BR-85).
  - [ ] Ở **cả năm** trường hợp, lượt đã ghi vẫn còn trong `study_answers` (BR-86).
  - [ ] Thẻ bỏ dở giữa chuỗi học mới **không** giữ `learned_at`, và phiên lỗi thời
        không cho ghi tiếp — một thẻ MUST NOT được ghi `scheduled` hai lần bởi hai
        phiên học mới khác nhau.
  - [ ] Không tổ hợp `status` × `end_reason` nào ngoài ma trận `data-model.md` —
        bất biến 12 vẫn pass sau khi chạy các luồng này.
- **Dependencies:** M5.3, M4.4
- **Tests required:** repository/use case test cho năm cách kết thúc; test khẳng
  định `study_answers` được giữ ở cả năm; test phiên lỗi thời
- **Checklist phases:** 14.4, 15.1, 15.2

### M5.6 · Integration test luồng UC-05

- **Status:** todo
- **Goal:** Chứng minh slice chạy thật xuyên suốt trên thiết bị, không chỉ ở unit test.
- **Scope:** `integration_test/study_flow_test.dart` chạy đúng luồng chính của
  UC-05 trên fixture của M4.12.
- **Out of scope:** Playwright + Flutter Web (M7 sẽ nối vào CI).
- **Editable documents:** `docs/wbs.md`
- **Output:** `integration_test/`
- **Acceptance criteria:**
  - [ ] Cold start → mở deck fixture → **phiên học mới** → đi hết chuỗi stage của
        `eight_box` → thẻ nhận `learned_at` và `due_at` đầu ngày kế tiếp (BR-144).
  - [ ] Thẻ vừa học xong **không** mở được phiên ôn ngay trong ngày (BR-145).
  - [ ] Đến hạn → chọn một mode → ôn → thẻ hết đến hạn — assert trên database.
  - [ ] Thẻ thiếu `example` vẫn hoàn tất chuỗi học mới: `fill` bỏ qua nó, và
        stage cuối **mà chính nó tham gia** là stage tính hoàn tất (BR-114, BR-144).
        Đây là ca mà bản nghiệp vụ đầu tiên làm hầu hết thẻ kẹt vĩnh viễn.
  - [ ] Chạy trên deck `eight_box` và deck `sm2`, đúng chuỗi stage mỗi loại.
  - [ ] `flutter test integration_test/` exit 0 trên emulator Android.
  - [ ] `flutter build web` vẫn exit 0 sau toàn bộ M5 — kênh E2E còn sống (AD-04).
- **Dependencies:** M5.4, M5.5, M4.12
- **Tests required:** đây **là** task test — integration test luồng chính
- **Checklist phases:** 15.5

---

## M99 · Adhoc

Task do chủ dự án giao trực tiếp, không thuộc chuỗi phụ thuộc M0…M9. Đánh số từ
99 để chúng không bao giờ tranh ID với một milestone thật, và để đọc bảng tiến độ
không nhầm chúng là một phase.

### M99.1 · Master flow — đồ thị nối các UC

- **Status:** **done** — `check_docs` sạch, cả 4 sơ đồ mermaid render được bằng
  `@mermaid-js/mermaid-cli`.
- **Goal:** Trả lời được câu "xong bước này thì người dùng đi đâu" — thứ mà đọc
  từng UC riêng lẻ không trả lời được.
- **Scope:** `docs/master-flow.md` (mới); một đoạn trỏ sang nó trong
  `use-cases.md`; một dòng trong bảng "What exists" của `docs/README.md`.
- **Out of scope:** nội dung của từng UC; mọi luật nghiệp vụ; tách nhỏ
  `use-cases.md` theo đối tượng — xem ghi chú cuối task.
- **Dependencies:** none
- **Checklist phases:** 0.3
- **Tests required:** none — document only. Thay vào đó: `check_docs.sh` phải
  xanh, và **mọi khối mermaid MUST render được** chứ không chỉ nhìn đúng.
- **Editable documents:** `docs/master-flow.md`, `docs/use-cases.md`,
  `docs/README.md`, `docs/wbs.md`
- **Output:** `docs/master-flow.md`
- **Acceptance criteria:**
  - [x] Một sơ đồ toàn app, cộng ba sơ đồ theo đối tượng: deck, card, review.
  - [x] Mọi đỉnh trỏ về UC hoặc BR bằng ID; không phát biểu lại luật nào.
  - [x] `Source of truth for` không đụng file nào khác — `check_docs` xác nhận.
  - [x] Cả 4 khối mermaid parse và render ra SVG.
  - [x] `use-cases.md` trỏ sang tài liệu mới.

**`use-cases.md` đang `frozen for MVP`, và task này sửa nó có phép.** Chủ dự án
chỉ định: tạo file riêng, còn `use-cases.md` thì trỏ sang. Phần sửa giới hạn đúng
một đoạn văn cộng hai dòng header — không UC nào bị đụng.

**Vì sao là file riêng chứ không phải một mục trong `use-cases.md`.**
`document-conventions.md` §5 nói luồng người dùng có canonical location là
`use-cases.md`, nên thoạt nhìn mục "Master flow" phải nằm trong đó. Nhưng thứ tài
liệu mới sở hữu **không phải luồng** — nó là *các cạnh giữa các luồng*, thứ
`use-cases.md` chưa bao giờ khai là của mình: mỗi UC ở đó tự mô tả mình và im
lặng về những UC bên cạnh. Hai `Source of truth for` vì thế không giao nhau, và
`check_docs` kiểm được điều đó.

**Tách theo đối tượng, không theo hành động** — quyết định của chủ dự án. Mục 3–5
chia theo *deck* / *card* / *review*; không có mục riêng cho "tạo deck". Một tài
liệu cho mỗi hành động sẽ nhân số file theo số nút bấm và phần lớn chỉ chứa một
sơ đồ ba đỉnh.

**Mermaid được kiểm bằng cách render, không bằng cách đọc.** `check_docs.sh`
không biết gì về mermaid, nên một sơ đồ sai cú pháp sẽ merge sạch và chỉ hỏng khi
có người mở file trên GitHub. Cả 4 khối được trích ra và đưa qua
`@mermaid-js/mermaid-cli`; 31 / 57 / 27 / 47 node vẽ ra đúng.

**Ba chỗ tài liệu lệch code, phát hiện trong lúc dựng sơ đồ và chỉ *ghi lại*.**
Chúng nằm ở `use-cases.md`, ngoài phạm vi sửa của task này: UC-04 không nhắc cờ
và tag dù BR-93/BR-95 khai `Related: UC-04`; UC-06 không nhắc tìm kiếm dù
`search_decks_use_case.dart` đã có và màn danh sách có ô tìm kiếm; và UC-01 mô tả
một màn thư viện starter chưa tồn tại — phần đã xây là seed tự động lúc khởi động
(`app/startup/fixture_seeder_widget.dart`), khác ở chỗ ai chọn `scheduler_type`.

**Việc tách `use-cases.md` đã được cân nhắc và hoãn.** Chủ dự án chốt ngay sau
task này: dự án chưa đủ lớn để một file 560 dòng thành vấn đề. Lý do và điều kiện
mở lại nằm ở bảng "Deferred and descoped" — gồm cả việc `check_docs.py` phải được
sửa **trước**, vì nó chỉ quét `docs/*.md` cấp một.

---

### M99.2 · Deck và Card thành bản tham chiếu — tham khảo cách làm, không sao chép

- **Status:** **done** — `check_docs` sạch, `flutter analyze` sạch, guard 0
  violation, toàn bộ suite pass.
- **Goal:** Một agent đi qua cửa vào chính thức MUST gặp được hai bản tham chiếu,
  và MUST hiểu là lấy **phương pháp** chứ không phải bê nghiệp vụ.
- **Scope:** `CLAUDE.md`; `flutter-workflow/SKILL.md`; `feature_blueprint.md`;
  `docs/architecture.md` (AD-17); `lib/features/card/README.md` (mới);
  `lib/features/deck/README.md` (§8 và hai câu đóng khung).
- **Out of scope:** đưa Card vào Widgetbook (nợ DoD, ghi ở `card/README.md` §6);
  chuyển `DECK_GOLDEN_FEATURE_REPORT.md` vào `docs/reviews/`; sửa UC-04 cho khớp
  cờ và tag — `use-cases.md` đang frozen.
- **Dependencies:** M4.11 (Card đóng)
- **Checklist phases:** 4, 14
- **Tests required:** none — document only. Gate: `check_docs` xanh và toàn bộ
  suite không đỏ vì hai README nằm trong `lib/`.
- **Editable documents:** `CLAUDE.md`, `docs/architecture.md`, `docs/wbs.md`,
  `.claude/skills/flutter-workflow/SKILL.md`,
  `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md`,
  `lib/features/deck/README.md`, `lib/features/card/README.md`
- **Output:** `lib/features/card/README.md`, AD-17
- **Acceptance criteria:**
  - [x] `CLAUDE.md` và `flutter-workflow/SKILL.md` đều trỏ tới hai bản tham chiếu.
  - [x] `feature_blueprint.md` có mục nói cái gì **không** chuyển được.
  - [x] Từ vựng `clone` trong blueprint về **0**.
  - [x] AD-17 chốt ranh giới thừa kế tầng / không thừa kế hình dạng dữ liệu.
  - [x] `card/README.md` là ca đối chứng có số đo, không phải catalogue thứ hai.

**Chỗ hở là đường dẫn, không phải nội dung.** `feature_blueprint.md` đã có 1182
dòng viết rất kỹ, và trong đó chỉ **9 lần** dẫn Deck làm ví dụ — tức nó vốn đã là
phương pháp chứ không phải kể chuyện một feature. Nhưng `CLAUDE.md` chỉ định
`flutter-workflow` làm điểm bắt đầu, mà file đó **không nhắc Deck lẫn blueprint
lần nào**, nên agent chỉ gặp blueprint nếu tình cờ rơi đúng vào
`flutter-feature-slice` trước. Sửa bằng hai đoạn ở đúng hai file đó.

**Blueprint tự hứa ba việc và chỉ làm hai.** Mở đầu viết *"what to copy, what to
rename, and what must not be copied"*; vế thứ ba không có một dòng nào trong toàn
bộ file. Tìm `deck-specific`, `your feature may not`, `does not apply` đều không
ra gì. Mục "What does not transfer" trả nợ đó bằng một bảng tám dòng: cái gì
thuộc Deck, cái gì thuộc Card, và vì sao mỗi cái không phải của feature sau.

**Từ vựng kéo ngược lại ý định.** Đo được trước khi sửa: 23 từ mang nghĩa sao chép
(`copy` 13 · `clone` 4 · `scaffold` 4 · `template` 2) chọi lại **một** lần
`reference implementation`. Một tài liệu có nội dung là phương pháp nhưng động từ
là "copy" thì mời gọi đúng cái sao chép 1:1 mà nó muốn ngăn. `clone` nay về 0;
`copy` còn lại toàn bộ mang nghĩa "ARB copy" — chữ hiển thị — và giữ nguyên là
đúng.

**Card là ca đối chứng, và đó mới là lý do cần bản thứ hai.** Một bản tham chiếu
duy nhất không phân biệt được "đây là luật" với "đây là cách feature đó tình cờ
được viết". Đếm từ code: `domain/repositories` 2→1, `entities` 2→6, `usecases`
11→15, `mappers` 2→7, `widgets/items` 4→1, `overlays` 5→1, `support` 1→3, và
`card.drift` có 4 placeholder động trong khi `deck.drift` có 0. Ba dòng bucket là
hữu ích nhất: chúng chứng minh theo **ba hướng khác nhau** rằng một bucket mỏng
không phải là feature làm dở.

**Đã cân nhắc và loại: cưỡng chế bằng guard.** Một rule kiểu "feature mới không
được có cột `parent_*_id`" sai cả hai chiều — chặn oan feature thật sự cần cây, và
lọt feature sao chép nhầm theo cách khác. Ranh giới này là phán đoán thiết kế; đưa
cho regex là đổi một luật đúng lấy một luật kiểm được. Ghi trong AD-17.

**Ba việc còn nợ, cố ý không làm trong task này:** Card chưa có trong Widgetbook
(vi phạm DoD, ghi ở `card/README.md` §6); `DECK_GOLDEN_FEATURE_REPORT.md` vẫn nằm
ở gốc repo không ai trỏ tới; và UC-04 vẫn không nhắc cờ với tag dù BR-93/BR-95
khai `Related: UC-04` — sửa nó là mở một tài liệu frozen.


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
| Tách `use-cases.md` theo đối tượng (deck / card / study) | hoãn | Chủ dự án quyết định ở M99.1: dự án chưa đủ lớn để một file 560 dòng thành vấn đề, và refactor bây giờ là chi phí không đổi lấy gì. `master-flow.md` đã lấy đi phần việc gấp nhất — trả lời "xong bước này thì đi đâu" — nên phần còn lại chỉ là kích thước file | Khi `use-cases.md` đủ lớn để tìm một UC trong đó thành việc mất thời gian. **Task đó MUST bao gồm việc sửa `check_docs.py` trước:** nó chỉ quét `docs/*.md` cấp một, nên đưa UC xuống thư mục con sẽ làm guard ngừng kiểm chín UC — không header, không "đủ chín mục", không "ID resolve" — mà vẫn báo xanh. Giữ ở cấp một (`use-cases-deck.md`) tránh được điều đó nhưng đánh đổi bằng tên file dài |
| Media | descoped khỏi MVP | Kéo theo lưu trữ file và đồng bộ file | Sau MVP; quy tắc reset và lưu trữ đã đặt sẵn (BR-41, AD-08) |
| ~~Tag~~ | **đã vào MVP** | Màn card cần hiển thị và lọc theo tag; bảng `tags` + `card_tags` không kéo theo lưu trữ file như media | Đã làm ở M4.10at (BR-93, BR-94) |
| Dải metadata trên card editor — `78% recall` và link `History` | hoãn khỏi M4.11 | Hai nửa của nó chặn bởi hai thứ khác nhau. **`% recall`** cần một BR định nghĩa "nhớ được" cho từng scheduler — `remembered` với `eight_box`, còn `sm2` phải chốt `hard\|good\|easy` có tính là nhớ không — tức cùng hình dạng BR-89…BR-91. **Link `History`** mở một màn study answers, thứ M4.11 đặt thẳng vào out-of-scope | Cùng M5.x, khi study answers có màn của nó. `study_answers.action` đã lưu sẵn đủ dữ liệu (BR-77), nên đây là câu hỏi định nghĩa và UI, không phải câu hỏi schema |
| Nhập giọng nói (mic) và phát âm bằng TTS (loa) trên card editor | hoãn khỏi M4.11 | Cả hai có trong ảnh tham chiếu. Mỗi cái cần một plugin, một quyền hệ điều hành và một luồng lỗi riêng — gần với media, vốn đã hoãn | Sau MVP, cùng lúc với media |

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
| `check_architecture.sh` chưa có test tự động | T0.1 | Regression trong checker âm thầm ngừng enforce boundary | Fixture trong `test/tools/` khi `test/` tồn tại (M6). **Giảm nhẹ ở M4.10b:** script tự in số file nó quét và coi 0 là lỗi, nên trường hợp tệ nhất — checker ngừng thấy gì mà vẫn pass — không còn im lặng. Vẫn cần fixture cho các trường hợp còn lại |
| ~~Không có CI~~ | T0.1 | Sáu gate tồn tại và chỉ chạy khi có người nhớ; một PR có thể merge với format lệch, guard đỏ hoặc test hỏng mà không ai thấy | **Đã trả ở M4.10b.** `.github/workflows/ci.yml` chạy trên `pull_request` và `push` vào `main`: format, analyze, generated-code, architecture, guard, docs, 844 test, golden, và build web |
| ~~`analysis_options.yaml` chưa được áp dụng~~ | T0.1 | Bộ lint đã viết nhưng chưa được enforce; nhiều khả năng có tên rule sai hoặc đã deprecated | **Đã trả ở M2.3.** Dự đoán đúng: `immutable_classes` không tồn tại, `use_if_null_to_convert_nulls_to_bools` đã deprecated. Nghiêm trọng hơn cả hai: 11 rule chỉ nằm ở `errors:` nên **chưa bao giờ chạy** — đã chuyển hết sang `linter: rules:` và kiểm chứng bằng tiêm lỗi |
| ~~14 query bất biến chưa chạy trên database thật~~ | T1.3 | Bất biến mới được verify trên fixture Python, chưa chạm schema Drift nào | **Đã trả một phần ở M4.4.** Cả 14 chạy trên database SQLite thật do schema production tạo — 30 test, mỗi bất biến hai chiều, cộng một test chứng minh một khiếm khuyết chỉ kích hoạt đúng những bất biến thật sự phủ nó. `check_docs.sh --db` cũng chạy đủ 14 (trước đó chép tay **10/14** và vẫn báo thành công). **Chưa trả:** vẫn là database tạm trong test, chưa phải dữ liệu người dùng thật — cái đó cần M8 |
| Pin Flutter ở `.fvmrc` **khai báo** chứ không **cưỡng chế** | M2.2 | Chạy `flutter` trực tiếp trên máy có version khác vẫn build được và không cảnh báo. Đây đúng là lỗi đã xảy ra: M2.1 chạy 3.44.8, phiên sau khởi động trên 3.44.6, không có gì phát hiện ra | **Đã trả một nửa ở M4.10b:** cả hai job CI dùng `flutter-version-file: .fvmrc`, nên `.fvmrc` là nguồn duy nhất và CI không thể lệch. **Chưa trả:** máy lập trình viên vẫn chạy version nào cũng được — cần một check so `flutter --version` với `.fvmrc` trong `dod_check.sh` |
| ~~7 file skill vẫn bảo chạy `dart run custom_lint`~~ | M2.2 | Skill vẫn hướng dẫn cài và chạy một package không cài được; phiên sau sẽ tin skill và loay hoay | **Đã trả ở M2.2b.** Cả 7 file đã trỏ sang guard. `docs/checklist.md` **cố ý giữ nguyên**: nó `frozen for MVP`, và mục "Ngoài phạm vi: mọi quyết định riêng của memox" nói rõ nó mô tả quy trình 22 phase chung — `custom_lint` ở đó là khuyến nghị Flutter phổ thông, còn quyết định riêng của memox sống ở file này (§5 canonical location) |
| `dependencies.md` vẫn liệt kê `sqlite3_flutter_libs` | M2.2 | Package đó nay là tombstone (`0.6.0+eol`, không có native code). Skill nói sai còn tệ hơn không có skill — phiên sau sẽ cài lại nó | Sửa `.claude/skills/flutter-project-setup/references/dependencies.md`: thay bằng ghi chú rằng `sqlite3` 3.x cấp native lib qua native assets. Ngoài `Editable documents` của M2.2 nên chưa sửa ở đây |
| Nội dung starter là fixture, không phải nội dung production | T1.3 | Không phát hành được với nội dung này | Tìm nguồn nội dung có bản quyền rõ ràng trước M8 (BR-87) |
| `sqlite3.wasm` và `drift_worker.js` là binary vendored trong `web/` | M4.2 | Không có bước build nào sinh ra chúng và không có bước build nào báo khi chúng cũ: app compile, load, rồi **không mở được database**. Nâng `drift` mà quên tải lại worker không có triệu chứng nào cho tới khi ai đó mở trình duyệt | `test/database/web_assets_test.dart` so version trong `pubspec.lock` với version đã pin, kèm `web/WEB_ASSETS.md` ghi URL tải. Đã kiểm tiêm lỗi: đổi `drift` thành 2.99.0 làm test đỏ |
| Server phát web chưa gửi COOP/COEP | M4.2 | `crossOriginIsolated` là `false`, nên drift chọn backend lưu trữ kém hơn OPFS. Không có lỗi nào — chỉ là hiệu năng và độ bền khác đi, âm thầm | Thêm `Cross-Origin-Opener-Policy: same-origin` và `Cross-Origin-Embedder-Policy: require-corp` vào server phát web ở M7, và kiểm lại `crossOriginIsolated` trong E2E |
| ~~Bản build web MUST dùng `--no-web-resources-cdn`~~ | M2.1a | Mặc định Flutter tải CanvasKit từ `gstatic.com` lúc **runtime** dù đã bundle sẵn cục bộ. Trong môi trường chặn CDN, app im lặng không render — không có lỗi build nào cảnh báo | **Đã trả ở M4.10b.** Job `web-build` trong `.github/workflows/ci.yml` dùng cờ này. **Chưa trả:** hướng dẫn chạy web thủ công vẫn chưa nhắc nó |
| ~~`check_docs.sh` chỉ đếm task ID dạng `T*`, bỏ sót `M*`~~ | T1.4 | Báo "no duplicate WBS task IDs (8 tasks)" trong khi có 33 — **pass gây hiểu nhầm**, 25 task M2–M5 không được bảo vệ khỏi trùng ID | **Đã trả ở M2.1b.** Regex sửa thành `[TM][0-9]+(\.[0-9]+)?[a-z]?` (giờ báo 35 task), thêm check dependency resolve và check `M*` đủ field + acceptance criteria không rỗng. Cả ba verify bằng test tiêm lỗi, 4/4 case đạt |
