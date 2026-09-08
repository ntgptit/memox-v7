# WBS — work breakdown and progress ledger

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì đã xong, đang làm, bị chặn |
| **Scope** | Milestone, task, blocker, technical debt, mục đã descoped |
| **Source of truth for** | Trạng thái task · blocker · technical debt · quyết định descope |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M100.35 (card dark thôi phát sáng: rim Tokyo `#6A7199` blur-2 spread-1/2/3 thay bằng hairline `outlineVariant` blur-0 đo 1.30:1, độ cao nói bằng drop thật; `overlayElevationFor` bị gỡ — elevation ngữ nghĩa độc lập brightness, chỉ màu bóng phụ thuộc; `Card` trần có hairline dark như `MxCard`; `MxCard.option` bắt buộc `onTap` và có disabled thật; gỡ alias `surfaceElevated`; sửa docs lỗi thời; blocking finding cho FilledButton state); M100.34 (screen gallery vẽ lại thành proof sheet: Archivo + JetBrains Mono, accent đỏ china-marker cố ý xa indigo của app, con dấu commit lên hàng đầu, rail 9 nhóm, số khung khớp thứ tự loupe, loupe thêm chế độ so light↔dark cạnh nhau ở 393dp; tên tab thôi đếm để danh tính artifact ổn định); M100.33 (Card thành design primitive: một `ColorScheme` role cho cả hai mode — dark lấy độ sâu từ rim dày dần chứ không đổi role; viền state và focus ring ra hai lớp foreground vẽ chồng lên con, cộng thêm chứ không thay nhau; gỡ viền giả `Border.all(color: fill)`; phần web-only của brief 5A bị loại vì Tokyo là desktop còn memox là mobile); M100.32 (`ColorScheme.surface` là nền trang trở lại, giấy về `surfaceContainerLow`; FAB/Card/AppBar/ChoiceChip về binding canonical; `warning` retune cho sàn 4.5); M100.31 (`components/` chia chín họ; role canonical trích từ SDK ghim và tìm ra bốn sai lệch; builder thôi nhận `Color` rời); M100.30 (bóng đổ light thành hai lớp màu Tokyo `#9FA2BF` — `shadow` tách khỏi `scrim`; nhãn nút lên w700; `AppSizing.controlCompact`; golden còn chờ Linux); M100.29 (`lib/core/theme/` chia sáu tầng: token tách khỏi component builder, `ColorScheme` có nguồn riêng `schemes/app_color_scheme.dart`, `AppSizing` nhận ba giá trị đã có, guard chiều import đã kiểm ngược, tài liệu `docs/design-system/theme-architecture.md`); M100.28 (bất biến canonical binding: gỡ `primaryInk`, khôi phục `primary` cho TextButton/OutlinedButton/TabBar, sàn 4,5 và 12° trở lại, `primary` retune `#4454CC` / `#BCC2FF`); M100.27 (`primary`, nền trang, nền card lấy nguyên hex Tokyo theo chỉ định chủ dự án; `primaryInk` cho thương hiệu làm chữ; dark vẽ rim Tokyo thay shade; R9 miễn paper trắng, sàn 4,3 cho nhãn nút light); M100.26 (toàn bộ hệ màu về palette Tokyo — surface, ink, viền, bốn semantic, tertiary, thang container; ngân sách chroma semantic thay bằng luật bốn hue; golden vẽ lại); M100.25 (hai họ accent M3 lấy hue từ palette Tokyo; fill là giá trị Tokyo đầu tiên vượt sàn, container/on giữ tone và chroma; `surfaceContainerHighest` dark tách khỏi `secondaryContainer`); M100.24 (golden về một nền tảng: job CI chuyển sang Linux, thêm bước font, bỏ tolerance); M100.23 (tổ hợp state thôi phá canonical role; guard AST khoá slot→role; luật nền tảng golden); M100.22 (năm component về role M3 canonical; hai hex palette gánh phần contrast; gỡ khái niệm selected ink chung); M100.21 (container cho bốn semantic; chip trạng thái thôi mượn role accent); M100.20 (bảy binding component về role M3; sàn độ nổi của menu bỏ theo quyết định chủ dự án); M100.19 (gỡ ba token thay thế khỏi 112 call-site, golden chứng minh không đổi pixel); M100.18 (dark `primary` đảo tone theo M3; ba token thay thế thành dẫn xuất); M100.17 (`ColorScheme` đúng 45 role M3 — gỡ `surfaceTint` khai tường minh, catalog đủ 45 swatch); M99.86 (bound cho Deck ancestry CTE, trả debt M99.28); M99.55–M99.59 (bộ overlay dùng chung: trục tone error/warning/info/success, `showMxConfirm`, `MxAsyncConfirmDialog`, `MxFormDialog`, `MxSheetInsets`, `MxAlertDialog`); M99.39 (token architecture pass — ColorScheme tường minh, cardPrompt rời scale, alias ngữ nghĩa); M99.38 (Library redesign pass 4 — path một target, caught-up, gate FAB); M99.37 (Library redesign pass 3 — FAB, header hai dòng, lưới 4px); M99.36 (Library redesign pass 2 — 16 sai lệch đo trên device); M99.35 (redesign header + hero Library theo mockup chủ dự án 2026-08-20); M99.34 (impact-aware verification plan builder, đánh lại số từ M99.23 của main — số đó thuộc Progress overview trên nhánh tích hợp); M99.33 (Trash và restore v1 — soft-delete, batch, retention 30 ngày, purge); M99.32 (Global Library Search v1); M99.24 (Progress by Deck v1, stage 2 của batch tích hợp #301–#310) · M99.27 (Reverse Self-assess v1, stage 4) · M99.28 (Settings v1 — global study defaults, theme và ngôn ngữ, stage 5) · M99.29 (Daily Reminders v1) · M99.30 (Tag Management v1, stage 7 của batch tích hợp #301–#310) · M99.31 (Card Detail v1, stage 8 của batch tích hợp #301–#310) |
| **Last updated** | 2026-09-06 |

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
| M9 · Backend Spring Boot + auth + sync (Phase 10) | in-progress | Chủ dự án đã cho phép triển khai standalone backend trước M8. Nền tảng REST Spring Boot dùng MyBatis/Flyway, PostgreSQL Testcontainers cho integration test, integrity/concurrency, error contract, OpenAPI, observability và local verification đang thực hiện; validation cơ bản ở DTO, pagination page+count rõ ràng và depth traversal bị chặn ở 10 cấp. Auth và sync vẫn ngoài phạm vi theo chỉ đạo. |
| M99 · Adhoc | — | Task chủ dự án giao trực tiếp, ngoài chuỗi phụ thuộc. M99.1 **done** — `master-flow.md`. M99.2 **done** — Deck và Card thành bản tham chiếu (AD-17). M99.3 **done** — refactor toàn bộ IT theo Testing Pyramid: 133/133 kịch bản có coverage host, `integration_test/` còn 8 kịch bản `DEVICE-E2E`, và CI lần đầu có cổng tự động cho tính đúng đắn nghiệp vụ. M99.5 **done** — golden harness chưa bao giờ nạp `NotoSansKR`, nên mọi chữ Hàn trong mọi golden là ô `NO GLYPH`; đã nạp đủ ba face CJK, bổ sung Nhật/Trung, và fixture demo trở lại tiếng Hàn. M99.7 **done** — bottom navigation lên bốn branch (AD-19); Progress/Settings là placeholder presentation-only, hai feature này **chưa** hoàn thành. M99.8 **done** — nhãn tab đầu đổi Decks/Bộ thẻ → Library/Thư viện; branch nội bộ và title màn hình vẫn là Decks. M99.17 **done** — đồng bộ Card Management với manual entry khối lượng nhỏ và chốt import/export là hướng bulk-management sau MVP. M99.27 **done** — Reverse self-assess v1: chiều hỏi cho phiên `self_assess` của deck `sm2`; schema v8. M99.26 **in-progress** — một ngữ pháp cho Library/Study/Progress: bốn quyết định D18…D21, không đổi hành vi. M99.28 **in-progress** — Settings v1: mặc định học toàn cục, theme và ngôn ngữ; schema v9; không branch nào còn là placeholder. M99.29 **in-progress** — Daily Reminders v1: một notification tóm tắt mỗi ngày, mặc định tắt, dựng từ workload đến hạn tại thời điểm hiện tại; schema v10. M99.30 **in-progress** — Tag Management v1: catalog phạm vi library, lọc nhiều tag theo OR, rename/gộp và xoá; không đổi schema. M99.31 **in-progress** — Card Detail v1: mặt đọc của một thẻ kèm dòng thời gian lịch sử học, phân trang theo cursor; không đổi schema. Cả sáu còn nợ emulator IT (gate cuối của đợt tích hợp #301–#310). |

---

## M0 · Development harness

Mọi task của milestone này đã đóng — xem `wbs-archive/t0-t1-m2-m3.md`.

## M1 · Product definition — done

Mọi task của milestone này đã đóng — xem `wbs-archive/t0-t1-m2-m3.md`.

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

Mọi task của milestone này đã đóng — xem `wbs-archive/t0-t1-m2-m3.md`.

## M3 · Architecture and design foundation

Mọi task của milestone này đã đóng — xem `wbs-archive/t0-t1-m2-m3.md`.

## M4 · Router and Drift foundation

Mục tiêu: có router và một database chạy được, đúng schema đã frozen, kèm
migration test và enforcement cho các bất biến.

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

## M5 · Study vertical slice — UC-05

Mọi task của milestone này đã đóng — xem `wbs-archive/m5.md`.

## M99 · Adhoc

Task do chủ dự án giao trực tiếp, không thuộc chuỗi phụ thuộc M0…M9. Đánh số từ
99 để chúng không bao giờ tranh ID với một milestone thật, và để đọc bảng tiến độ
không nhầm chúng là một phase.

### M99.29 · Daily Reminders v1

- **Status:** **in-progress** — gate `integration_test/` đóng ở M100.14 (8/8); **còn smoke notification thật**, suite không phủ WorkManager/notification/Doze. phase 1–9 xong (gồm cả các vòng review đệ quy), CI xanh; gate thiết bị đã chạy.
- **Goal:** Một lời nhắc học hằng ngày, tuỳ chọn và mặc định tắt, dựng từ
  workload đến hạn thật tại thời điểm hiện tại — không phải từ một payload nạp sẵn
  hôm trước.
- **Scope:** BR-218…BR-229, UC-17, AD-21, ba cột `app_settings` + migration v10 (nhánh nguồn chia làm hai bước
  v8 và v9; cả hai số đó đã thuộc feature khác trên nhánh tích hợp, nên ba cột
  vào cùng một bước),
  query workload theo root deck, feature slice `lib/features/reminder/`
  (domain/data/di/presentation), route `/settings/reminders` và một hàng vào ở
  nhánh Settings, entry point worker ở `lib/app/reminder/`, hoà giải lịch lúc
  bootstrap, deep link khi chạm notification, ARB EN/VI, và host test cho từng
  lớp.
- **Out of scope:** nhắc
  theo thẻ mới, nhiều lượt nhắc trong ngày, nhắc theo từng deck, quyền exact
  alarm, iOS, và nhắc học trên Web (adapter báo không hỗ trợ). Smoke thật trên
  emulator/thiết bị **hoãn sang integration worktree** — xem Acceptance criteria.
- **Editable documents:** `docs/business-rules.md`, `docs/use-cases.md`,
  `docs/architecture.md`, `docs/data-model.md`, `docs/wbs.md`,
  `docs/wireframes/m6-daily-reminders.md`
- **5Why:** Vì sao mặc định tắt? Vì một notification không ai yêu cầu là spam,
  và xin quyền trước khi người dùng muốn là cách nhanh nhất để bị từ chối vĩnh
  viễn — Android chỉ cho hỏi một lần. Vì sao chỉ đếm thẻ đến hạn? Vì thẻ chưa
  học là *có thể học*, không phải *phải học*: nhắc về chúng làm lời nhắc kêu mỗi
  ngày kể cả khi người dùng không nợ gì, và một lời nhắc luôn kêu là một lời
  nhắc bị tắt. Vì sao một tóm tắt thay vì một notification mỗi deck? Vì số
  notification tỉ lệ với số deck, còn quyết định của người dùng thì không — họ
  chỉ quyết định có mở app hay không. Vì sao inexact thay vì exact alarm? Vì
  exact alarm là quyền đặc quyền Android 12+ soi rất kỹ, và không có yêu cầu sản
  phẩm nào nói lời nhắc phải đúng đến từng phút. Vì sao worker chứ không phải
  notification đặt sẵn? Vì BR-222 cho phép hiện số thẻ và tên deck, và những con
  số đó chỉ đúng nếu có Dart chạy lúc fire — nguyên nhân gốc là *nội dung phụ
  thuộc trạng thái tại thời điểm hiện tại*, không phải tại thời điểm đặt lịch
  (AD-21).
- **Output:** `lib/core/database/queries/reminder.drift`, ba cột trên
  `app_settings` + `_upgradeToV10`, `drift_schemas/drift_schema_v10.json`,
  `lib/features/reminder/**`, `lib/app/reminder/reminder_worker_entry.dart`,
  `lib/app/startup/reminder_reconciler_widget.dart`, route
  `/settings/reminders`, ARB EN/VI, và bộ test host tương ứng.
- **Acceptance criteria:**
  - [x] Mặc định tắt và 20:00; không xin quyền, không đặt lịch, không hiện
        notification trước khi người dùng bật (BR-218, BR-219).
  - [x] Chỉ overdue + due-today mới sinh notification; thẻ chưa học không tính;
        đến giờ mà tổng bằng 0 thì bỏ lượt (BR-220).
  - [x] Một notification mỗi ngày, id cố định; thứ tự cấp bách tất định và không
        đếm trùng thẻ qua ancestor/descendant (BR-221, BR-223, BR-224).
  - [x] Copy notification không mang nội dung thẻ, tag hay history; không log
        nội dung ở bất kỳ level nào (BR-222).
  - [x] Chạm mở Study Home, không auto-start; dismiss không mutation (BR-225).
  - [x] Không có `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` trong bất kỳ manifest
        hay flavor nào — có test đọc manifest chứng minh (BR-226).
  - [x] Hoà giải lịch idempotent với clock/offset tiêm vào (BR-227).
  - [x] Từ chối quyền là trạng thái có kiểu, settings vẫn tắt, có đường thử lại,
        không tự xin lại (BR-228).
  - [x] Web/iOS: adapter báo capability không hỗ trợ, không crash; domain và
        presentation không import kiểu plugin, không kiểm tra nền tảng, không
        chạm platform IO (BR-229). Màn **render** trạng thái đó (M6 S7) — suy từ
        capability chứ không chờ một lệnh hỏng, vì trên nền tảng này không lệnh
        nào chạy được.
  - [x] CTA khôi phục chạy lại **đúng lệnh đã hỏng**, không phải một lệnh cố
        định; huỷ lịch hỏng có rejection và copy riêng (`cancelFailed`) vì
        settings **đã** tắt.
  - [x] Host gate xanh: format, analyze, architecture, guard, docs, toàn bộ host
        suite.
  - [x] **Gate `integration_test/` — CHẠY XANH ở M100.14.** 8/8 trên
        `emulator-5554` (Android 16, API 36), chạy **từng file một**:
        `it_platform_test` 6/6 và `it_offline_test` 2/2. Chạy gộp một lệnh thì
        flaky — xem M100.14.
  - [ ] **Smoke notification trên emulator/thiết bị — chưa chạy, hoãn có chủ
        đích.** Host test dùng fake platform adapter và không gửi notification
        thật; hai plugin native (`workmanager`, `flutter_local_notifications`),
        việc worker mở connection SQLite thứ hai trong background isolate, và
        thời điểm fire dưới Doze **chỉ kiểm chứng được trên máy thật**. Việc này
        thuộc integration worktree và là điều kiện phát hành, không phải điều
        kiện merge của PR này.
- **Recursive review, vòng 1:** hai audit AUDIT_ONLY chạy song song
  (architecture/logic và UI/UX) trên commit đầu. Kết quả: 2 P0, 6 P1, 8 P2 —
  trùng lặp đáng kể giữa hai bên. Đã sửa hết trong vòng 2. Bốn defect đáng ghi
  vì chúng là *lớp lỗi*, không phải typo: (1) một CTA "Try again" cố định chạy
  `enable` bất kể lệnh nào hỏng, nên retry sau khi **tắt** hỏng sẽ bật lại thứ
  người dùng vừa tắt; (2) `reset()` gọi trên chính controller sắp `submit()` xoá
  luôn `isSubmitting`, tức xoá double-submit guard — hai enable song song nghĩa
  là hai prompt quyền và hai chuỗi ghi-đền-bù đan vào nhau; (3) trạng thái
  platform-unavailable chỉ sinh ra từ một lệnh, mà trên nền tảng đó không lệnh
  nào chạy được, nên nó **không bao giờ render** và hai ARB key thành code chết;
  (4) một lượt nhắc bị Doze đẩy qua nửa đêm sẽ đặt tiếp lượt của **chính ngày
  vừa phục vụ**, phá BR-221. Tất cả đều có test hồi quy.
- **Recursive review, vòng 2:** hai audit chạy lại trên bản đã sửa. Kết quả: 1 P0
  + 1 P1 + 5 P2, và **P0 là do chính vòng 1 gây ra** — đúng lý do vòng thứ hai
  tồn tại. `schedule()` dùng một tham số `now` cho hai việc: chọn lượt kế tiếp
  **và** đo `initialDelay`. Khi worker truyền anchor (đầu ngày kế tiếp) vào,
  delay hụt đúng bằng khoảng cách anchor − giờ thật, nên lượt nhắc trôi sớm 4
  tiếng **mỗi đêm** cho tới khi hai lượt rơi vào cùng một ngày — tức phá đúng
  BR-221 mà bản sửa tuyên bố đã vá. Hàm thuần `reminderRescheduleAnchor` đúng;
  chỗ nối dây sai, và test hàm thuần không chạm tới được. Nay contract tách
  `now` (đo delay) khỏi `notBefore` (chọn lượt), và
  `android_reminder_platform_repository_test.dart` đo thẳng `initialDelay` bằng
  mock Workmanager. P1: `ReminderTimeDraftController` là autoDispose và không ai
  `watch`, nên nó bị huỷ ngay frame sau khi ghi — retry luôn đọc `null` và
  re-submit giờ cũ, mà use case coi là no-op, nên retry báo thành công giả.
- **Recursive review, vòng 3:** audit architecture xác nhận cả ba fix của vòng 2
  đã thật sự vá, và tìm ra rằng **cơ chế bỏ-ngày của BR-221 chỉ sống trong đúng
  một lượt worker**: anchor là tham số chỉ worker truyền, nên lần hoà giải lịch
  kế tiếp lúc khởi động tính lại từ `now`, đặt lại ngày vừa bỏ, và
  `ExistingWorkPolicy.replace` biến đó thành lịch thật — hai notification trong
  một ngày địa phương, đúng thứ anchor sinh ra để chặn. Sửa bằng cách làm cho
  dấu vết **bền**: schema v9 thêm `app_settings.reminder_last_delivered_at`,
  `DeliverDailyReminderUseCase` ghi nó khi post, và
  `ReconcileReminderScheduleUseCase` tự dẫn xuất `notBefore` từ nó — nên cả bốn
  đường gọi (launch, enable, đổi giờ, worker) cùng một câu trả lời mà không
  đường nào phải biết. Cùng vòng: clamp chuyển từ *delay* sang *anchor* (clamp
  delay biến một anchor cũ thành "bắn ngay"), `watchSettings` map lỗi như
  `readSettings`, và M6 A2 nay được đo bằng `didExceedMaxLines` thay vì chỉ
  `takeException` — một nhãn bị cắt không ném exception nào.
- **Recursive review, vòng 4 và 5:** vòng 4 xác nhận cả năm finding vòng 3 đã
  vá và tìm ra rằng lịch vẫn là **thứ duy nhất** chặn lượt post thứ hai — dấu
  vết v9 chỉ được đọc theo chiều đặt lịch, nên một lượt đã gửi rồi ném trên
  đường ra sẽ bị WorkManager retry và post lại. Thêm khoá thứ hai ngay ở
  `DeliverDailyReminderUseCase`. Vòng 5 là vòng **đầu tiên trong năm vòng mà bản
  sửa trước không đẻ ra defect mới**, và auditor kết luận thiết kế đã hội tụ: các
  vòng 1–3 sửa vào *đường dây* (tham số anchor, chỗ clamp, ai sở hữu `now`) nên
  mỗi lần lại vỡ chỗ khác; bản sửa vòng 4 là *cộng thêm* — một guard thuần đọc
  từ đúng snapshot đã có. Hai việc còn lại đã làm nốt: ghi dấu vết hỏng **không**
  được biến thành retry (retry chính là thứ post lần hai, nên báo lỗi vì
  bookkeeping hỏng gây đúng cái hại mà bookkeeping ngăn), và một dấu vết mang
  timestamp ở tương lai bị coi là không dùng được ở **cả** guard lẫn `notBefore`
  — không màn nào hiện cột đó và không lệnh nào ghi lại nó, nên một đồng hồ chạy
  nhanh rồi được chỉnh lại sẽ tắt hẳn nhắc học vĩnh viễn.
- **Dependencies:** M4.2 (database), M5.0s (`app_settings`, `learned_at`),
  M99.15/M99.19a (bucket widget), AD-19 (nhánh Settings)
- **Tests required:** domain — dựng summary, đếm, thứ tự cấp bách, ranh giới
  due/overdue, "không có thẻ mới", copy input; SQLite thật — gộp workload theo
  root, không đếm trùng, không mutation; adapter/service — enable/disable/đổi
  giờ/đổi timezone/reboot hook, nhánh permission, due đã cũ lúc fire,
  idempotency, failure có kiểu, fallback Web; widget/router — luồng permission,
  dialog chọn giờ, deep link khi chạm, semantics, 320/390/412 và text scale;
  manifest/flavor — không có quyền exact alarm. **Không** gửi notification thật
  trong host suite. Sau vòng review: thêm test cho retry-đúng-lệnh, banner
  capability, semantics name/value của toggle và hàng giờ, và
  "một lượt mỗi ngày địa phương" qua mốc nửa đêm. Sau vòng 2: adapter test đo
  `initialDelay` thật, retry giữ đúng giờ người dùng chọn, read hỏng map thành
  `Failure`. Sau vòng 3: BR-221 được ghim bằng `reminder_use_cases_test.dart`
  (group reconcile — ngày đã giao thì mọi caller đều bỏ) và
  `migration_v8_test.dart` (case v9), thay cho hàm anchor đã bị xoá; M6 A2 đo
  bằng `didExceedMaxLines`. Sau vòng 4: round-trip `markDelivered` qua SQL thật,
  và lượt giao thứ hai trong cùng ngày bị chặn ở use case.
- **Checklist phases:** 9, 10, 11, 12, 13, 14, 15

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
| `SC-C8-02` — `NewCardOrder` được sửa bằng hai họ control | **cần quyết định lại ở wireframe**, không sửa ở task feature | `StudyOptionsScreen` dùng `MxPillButton`, `SettingsScreen` dùng `MxRadioRows` — cùng heading `studyOptionsOrderLabel`, cùng hai nhãn `studyOptionsOrderCreated`/`studyOptionsOrderRandom`, cùng một enum. `docs/wireframes/m99-settings.md` (Status `active`) S9a ghi đây là lệch **có chủ ý**, và lý do nó nêu là "pill chỉ khác nhau ở nền và màu chữ" — tiền đề đó **đã bị bác bỏ** từ M100.36 4M: `MxPillButton` dựng tick trong leading slot luôn được layout. Hai pass tái xác minh đều kết luận đổi họ control là **re-decision của S9/S9a**, không phải composition của một màn — nên PR của C8 chỉ sửa đoạn doc đã sai, không đổi control nào | Khi có một task design/wireframe cho `m99-settings.md` S9/S9a: chọn một trong hai họ cho cả hai màn, rồi đo lại 320dp × textScaler 2.0 với nhãn tiếng Việt — đúng cell mà lập luận của S9 dựa vào |
| `custom_lint` + `riverpod_lint` | descoped khỏi MVP | Không có phiên bản `custom_lint` nào tương thích `analyzer >=10`, trong khi `json_serializable`, `freezed` và `drift_dev` đều đòi mức đó. Cài được chỉ bằng cách hạ toàn bộ stack generator một thế hệ, kể cả `uuid` về `^3.0.6` — đi ngược AD-03. Chủ dự án quyết định không cần; nếu cần sẽ làm guard bên ngoài | Khi `custom_lint` hỗ trợ `analyzer >=10`, **hoặc** khi một guard ngoài được viết. Xem mục bên dưới về việc mất gì |
| Flutter toolchain verification | **đã xong** | Từng hoãn vì `flutter` chưa có trong môi trường cloud | Đã kiểm chứng ở M2.1 trên máy local: `flutter doctor -v` → `No issues found!` |
| Đưa deck con lên thành root deck | descoped khỏi MVP | Cần quyết định scheduler mới; là tính năng riêng chứ không phải phép di chuyển | Sau MVP (UC-09 A2) |
| Tách `use-cases.md` theo đối tượng (deck / card / study) | hoãn | Chủ dự án quyết định ở M99.1: dự án chưa đủ lớn để một file 560 dòng thành vấn đề, và refactor bây giờ là chi phí không đổi lấy gì. `master-flow.md` đã lấy đi phần việc gấp nhất — trả lời "xong bước này thì đi đâu" — nên phần còn lại chỉ là kích thước file | Khi `use-cases.md` đủ lớn để tìm một UC trong đó thành việc mất thời gian. **Task đó MUST bao gồm việc sửa `check_docs.py` trước:** nó chỉ quét `docs/*.md` cấp một, nên đưa UC xuống thư mục con sẽ làm guard ngừng kiểm chín UC — không header, không "đủ chín mục", không "ID resolve" — mà vẫn báo xanh. Giữ ở cấp một (`use-cases-deck.md`) tránh được điều đó nhưng đánh đổi bằng tên file dài |
| Media | descoped khỏi MVP | Kéo theo lưu trữ file và đồng bộ file | Sau MVP; quy tắc reset và lưu trữ đã đặt sẵn (BR-41, AD-08) |
| ~~Tag~~ | **đã vào MVP** | Màn card cần hiển thị và lọc theo tag; bảng `tags` + `card_tags` không kéo theo lưu trữ file như media | Đã làm ở M4.10at (BR-93, BR-94) |
| Dải metadata trên card editor — `78% recall` và link `History` | hoãn khỏi M4.11 | Hai nửa của nó chặn bởi hai thứ khác nhau. **`% recall`** cần một BR định nghĩa "nhớ được" cho từng scheduler — `remembered` với `eight_box`, còn `sm2` phải chốt `hard\|good\|easy` có tính là nhớ không — tức cùng hình dạng BR-89…BR-91. **Link `History`** mở một màn study answers, thứ M4.11 đặt thẳng vào out-of-scope | Cùng M5.x, khi study answers có màn của nó. `study_answers.action` đã lưu sẵn đủ dữ liệu (BR-77), nên đây là câu hỏi định nghĩa và UI, không phải câu hỏi schema |
| Nhập giọng nói (mic) và phát âm bằng TTS (loa) trên card editor | hoãn khỏi M4.11 | Cả hai có trong ảnh tham chiếu. Mỗi cái cần một plugin, một quyền hệ điều hành và một luồng lỗi riêng — gần với media, vốn đã hoãn | Sau MVP, cùng lúc với media |
| `SC-C1-15` — ReminderSettingsScreen | **DESIGN_SYSTEM_BLOCKED** (M100.42) | The two rows of one card have tap targets and ripples of different width. The toggle row's InkWell is 329dp wide, the time row's is 361dp - the full card - so a 16dp strip down each edge of … Sửa nó chạm hợp đồng đóng băng **#6** của `design-system/v1-freeze.md` §2, nên một task feature MUST NOT tự làm | **Trigger 3** — khi thêm một họ shared primitive/component mới |
| `SC-C1-16` — Reminder settings — time picker dialog | **DESIGN_SYSTEM_BLOCKED** (M100.42) | The time picker sits 16dp in from each screen edge while every other dialog in the app sits 40dp in, so the app's one Material-owned modal is 48dp wider than its siblings on the same screen … Sửa nó chạm hợp đồng đóng băng **#6** của `design-system/v1-freeze.md` §2, nên một task feature MUST NOT tự làm | **Trigger 3** — khi thêm một họ shared primitive/component mới |
| `SC-C3-20` — RouteNotFoundScreen | **DESIGN_SYSTEM_BLOCKED** (M100.42) | The route name is a second, invisible copy of the visible title, so a screen-reader user meets two nodes labelled "Page not found" one after the other — a container node spanning the whole p… Sửa nó chạm hợp đồng đóng băng **#6** của `design-system/v1-freeze.md` §2, nên một task feature MUST NOT tự làm | **Trigger 3** — khi thêm một họ shared primitive/component mới |
| `SC-C4-08` — ProgressScreen | **DESIGN_SYSTEM_BLOCKED** (M100.42) | The pinned range strip never draws the chrome/content hairline, so deck rows scroll under it with no seam — the strip is painted in `scaffoldBackgroundColor` and the rows behind it are on th… Sửa nó chạm hợp đồng đóng băng **#11** của `design-system/v1-freeze.md` §2, nên một task feature MUST NOT tự làm | **Trigger 3** — `MxContentShell` phải học một khái niệm mới, tức là một họ chrome mới |
| `SC-C9-03` — StudyHomeScreen | **DESIGN_SYSTEM_BLOCKED** (M100.42) | Panel resume không nổi hơn các hàng dưới nó ở light — đo trên golden đã commit: ΔE(hero, nền) 2,73 so với ΔE(row, nền) 4,25, và row còn có hai lớp shadow trong khi hero không có lớp nào. `MxCard.tonal` là recipe mức-trang duy nhất còn ở `AppElevation.none`. Không composition nào trong `lib/features/` chạm tới được: `MxCard` không phơi elevation, shadow tự vẽ bị chính sách raw-Material cấm, và phép đổi sang `MxCard.accent` mà finding đề xuất lại tô cùng thứ giấy các hàng dùng — xóa sắc độ và làm dark tệ đi, nơi hero đang đúng (ΔE 19,23 so với 5,23 của row). Sửa nó chạm hợp đồng đóng băng **#10** của `design-system/v1-freeze.md` §2, nên một task feature MUST NOT tự làm | **Trigger 2** — khi có một lần thiết kế lại palette/theme có chủ đích |
| `SC-C9-14` — Reminder settings — time picker dialog footer | **DESIGN_SYSTEM_BLOCKED** (M100.42) | The picker's footer offers Cancel and the commit action at identical emphasis, both drawn as zero-padding text links with no fill, no ripple and no hover surface — so the one modal in this f… Sửa nó chạm hợp đồng đóng băng **#3** của `design-system/v1-freeze.md` §2, nên một task feature MUST NOT tự làm | **Trigger 2** — khi có một lần thiết kế lại palette/theme có chủ đích |

### M99.32 · Global Library Search v1 — deck, hai mặt card và tag trong một danh sách

- **Status:** **integrated** — gộp vào nhánh tích hợp ở stage 9; Card
  Detail (M99.31) đã có mặt từ stage 8 nên điều hướng kết quả card đã được
  nối dây vào route chi tiết thẻ ngay khi tích hợp (BR-254), thay cho snackbar
  "chưa mở được" của thời điểm nhánh nguồn chưa có route ấy. Emulator IT chưa
  chạy (xem Acceptance criteria).
  Review architecture/logic xong — **không có P0/P1**; hai khoảng trống coverage
  đóng ngay: (P2) guard "chỉ lần đọc mới nhất được emit" trước đó chỉ đúng theo
  cách đọc code — một database thật không thể cho hai lần đọc hoàn tất ngược thứ
  tự bắt đầu, nên `search_read_ordering_test.dart` dựng một DAO parked-completer
  để làm đúng chuyện đó (và `LibrarySearchDao` bỏ `final` **chỉ** vì test này,
  có ghi lý do tại chỗ); (P3) BR-254 nêu đích danh đổi tên tag, mà
  `search_live_update_test.dart` chỉ phủ rename tổ tiên / move card / delete —
  nay có ca đổi tên tag làm card khớp-qua-tag rời khỏi kết quả.
  Review UI/UX xong — bốn P1 và bốn P2 đóng: (P1) lối vào dùng `go`, mà
  `/search` là **anh em** của `/decks/:deckId`, nên Back từ tìm kiếm mở ở cấp ba
  rơi về danh sách gốc — đổi sang `push`, và test cũ không thấy được vì nó mở
  search từ đúng root; (P1) body hardcode ba `AppSpacing.lg` trong khi ô nhập lấy
  `mxScreenGutter`, lệch **4dp ở 320dp** và khớp ở 390 — nay body đọc cùng hàm;
  (P1) harness test dựng `MediaQueryData()` mới, zero cả `size`/`padding`/
  `viewInsets`, nên `MediaQuery.sizeOf` trả 0 và **bộ ba viewport chạy đúng một
  layout ba lần** — `copyWith` là fix, và nó mở ra ca bàn phím ở 320×568;
  (P1) dòng kết quả là `Material` + `InkWell` tự vẽ nên **không có focus ring** —
  lớp phủ 10% một mình đo ~1.15:1, dưới 3:1 của WCAG 1.4.11 — nay là `MxCard`,
  vốn mang sẵn ring và `cardOverlay`. (P2) ô nhập in "0" trên mặt lỗi và cạnh
  spinner; (P2) tên tag đã khớp nằm trong `ExcludeSemantics` nên với screen
  reader là **tín hiệu duy nhất còn lại** mà không tới được — thêm key ARB
  `librarySearchCardResultTaggedSemantic`; (P2) spinner tải-thêm thiếu
  `liveRegion`; (P2) `' › '` là chuỗi hiển thị hardcode, nay là key ARB vì nó
  vừa được vẽ vừa được đọc lên. Đo tương phản trên token thật: **không cặp
  text/glyph nào trượt** ở cả sáng lẫn tối (thấp nhất 5.28:1 cho dòng lỗi trang
  sau, ngưỡng 4.5). Wireframe cập nhật S11, S12, G1 và W6 theo các fix trên.
- **Goal:** Cho người dùng tìm được một deck, một thẻ hay một tag ở bất kỳ đâu
  trong thư viện, với thứ tự giải thích được, phân trang không lặp không sót, và
  không một statement nào chạy trước khi họ thực sự gõ.
- **Scope:** Feature slice mới `lib/features/search/`, một `.drift` mới cho nửa
  card, seam chuẩn hoá chuỗi dùng chung trong `core/text/`, seam hẹn giờ trong
  `core/time/`, route `/search` trong nhánh Library, và việc **thay** ô tìm kiếm
  theo cấp của Deck bằng lối vào màn mới. Không đổi schema, không thêm index,
  không đụng scheduler, study state hay review history.
- **Editable documents:** `docs/business-rules.md`, `docs/use-cases.md`,
  `docs/wbs.md`, `docs/wireframes/m99-32-global-library-search.md`
- **5Why:** Người dùng không tìm lại được thứ mình đã lưu vì thư viện là cây mười
  cấp và tên lặp lại; không tìm được vì tìm kiếm cũ chỉ thấy **tên deck** trong
  subtree đang đứng, mà thứ họ nhớ thường là mặt thẻ hoặc cái tag; không thấy
  card vì chưa có bề mặt nào đọc qua cả hai feature; không có bề mặt đó vì cả hai
  feature đều không được import lẫn nhau (AD-13); nguyên nhân gốc là chưa ai đặt
  bề mặt tìm kiếm ở chỗ **không thuộc feature nào** — một slice riêng, gắn vào
  router bằng một tên route trong `core/`. Bốn quyết định theo sau: một hàm fold
  dùng chung cho cả hai phía so sánh; truy vấn rỗng **không** chạm database;
  debounce ở seam controller chứ không trong widget; và không thêm FTS/index cho
  tới khi có số đo (BR-255).
- **Output:** `core/text/search_fold.dart` (rule fold duy nhất, `CardText`,
  `TagName` và migration v2→v3 nay uỷ quyền cho nó); `core/time/delay_provider.dart`;
  `core/database/queries/search.drift` (`searchCardPage` — xếp hạng bằng `instr`,
  gộp tag tương quan, keyset bốn cột); slice `features/search/` đủ bốn tầng
  (7 model domain, contract, use case, DAO, mapper, repository impl, 4 provider,
  screen, 6 widget trong bốn bucket), 21 key ARB EN/VI, route `/search` +
  `RouteNames.librarySearch`, binding trong `app/di/repository_bindings.dart`,
  use case Widgetbook `LibrarySearchScreen`, và visual audit companion đầu tiên
  của repo có **ô nhập đang mở**.
- **Acceptance criteria:**
  - [x] Tìm đúng bốn trường (tên deck, front, back, tên tag) và không tìm
        `example`/`hint`/`pronunciation`, scheduler hay history (BR-247).
  - [x] Truy vấn rỗng **không** sinh statement nào — đo bằng `QueryLogInterceptor`,
        không suy ra từ kết quả (BR-249).
  - [x] Debounce 250ms ở seam controller, có test hai phía 249/250, gõ liên tiếp,
        xoá trắng tức thì, kết quả/lỗi đến muộn bị bỏ, và dispose huỷ hẹn giờ.
  - [x] Deck trước Card sau, mỗi nhóm exact → prefix → contains, hoà thì fold-name
        → `created_at` → `id`; hai nửa Dart và SQL được giữ cùng một câu trả lời
        bằng `search_rank_parity_test.dart`.
  - [x] Phân trang keyset: ba trang phủ đúng tập, không lặp không sót, và một hàng
        ghi thêm phía trên biên không làm lệch trang sau.
  - [x] Card khớp nhiều tag vẫn là **một** dòng; tag đã khớp hiện ra khi và chỉ
        khi card khớp *chỉ* qua tag.
  - [x] Fold Unicode đối xứng — `CÔNG NGHỆ` tìm được bằng `công nghệ`; `%` và `_`
        là ký tự thường, không phải wildcard.
  - [x] Đổi tên tổ tiên, chuyển card, xoá card và xoá deck cập nhật kết quả cùng
        đường dẫn đang hiển thị; huỷ subscription thì ngừng đọc.
  - [x] Một trang kết quả tốn **hai** statement, không phải một trên mỗi hàng.
  - [x] Mười trạng thái UI dựng được ở EN/VI, sáng/tối, 320@2.0 / 390 / 412; sáu
        ràng buộc geometry của W5 đo bằng `getRect`; mọi dòng ≥ 48dp và có nhãn
        ngữ nghĩa gộp.
  - [x] Kết quả deck mở deck; kết quả card mở **chi tiết chỉ đọc** qua router
        thật (`/decks/<deckId>/cards/<cardId>`, nối dây ở stage 9 tích hợp khi
        route M99.31 đã có mặt) và **không bao giờ** mở màn sửa card.
        Đích được **push** (đối xứng với lối vào, S11) nên Back quay về đúng
        màn tìm kiếm với query còn nguyên — `library_search_route_test.dart`
        giữ cả đường đi lẫn đường về cho hai loại kết quả.
  - [x] Chuỗi VI nói "nhãn" cho tag — thống nhất với Tag Catalog, chủ dự án
        chốt ở stage 9 tích hợp. **Nợ đặt tên còn lại, ngoài phạm vi stage
        này:** "deck" đang là "bộ thẻ" ở màn CRUD deck nhưng "deck" ở
        reminder/study/search — cần một quyết định app-wide riêng. Nhãn retry
        cấp màn cũng đang chia đôi ("Retry" ở settings/study vs "Try again" ở
        progress/import/export/trash), và VI có "Không thể tải bộ thẻ"
        (decks) cạnh "Không tải được bộ thẻ" (studyHome) — cùng chờ quyết
        định copy app-wide đó. Cùng nhóm:
        `deckSchedulerChangeBody`, `deckResetProgressKeptBody` và
        `cardImportInfoTagsHint` (VI) vẫn nói "tag" — chờ chung quyết định đó.
  - [x] Hai mặt chờ giữ mở được trong Widgetbook — scenario `loading` (stream
        không bao giờ trả lời) và `pageStalls` (trang hai treo vĩnh viễn) —
        cùng bài học M99.31: mặt chỉ loé một frame thì không review được.
  - [x] `dart format`, `flutter analyze` (lib + test + widgetbook), `check_docs.py`,
        `check_architecture.py`, guard, generated-code freshness, và toàn bộ host
        suite (2.683 test) xanh qua `dod_check.sh`.
  - [x] `flutter test integration_test/ -d emulator-5554 --flavor development`
        — **hoãn**, cần emulator. Đây là feature mới dưới `lib/features/`, nên
        theo `CLAUDE.md` nó **chưa done** cho tới khi suite này chạy xanh trên
        máy có emulator.
- **Dependencies:** M4.9a, M4.10at, M4.11, M99.15
- **Tests required:** domain (chuẩn hoá, ba bậc khớp, hoà, đường dẫn, cycle,
  cursor, zero-I/O ở use case); data trên SQLite thật (bốn trường, loại trừ, gộp
  tag, fold Unicode, wildcard, thứ tự, keyset, live update, đếm statement); controller
  (debounce hai phía, burst, xoá trắng, stale, dispose); widget (mười trạng thái,
  hai locale, dark, ba viewport, semantics, sáu ràng buộc geometry); router (lối
  vào, thanh dưới, Back, focus, mở deck); visual audit ba state × sáng/tối.
- **Checklist phases:** 9, 10, 12, 13, 14, 15

### M100.27 · Ba màu chính là của Tokyo nguyên hex — mọi thứ khác nhường

- **Status:** superseded — M100.28 gỡ `primaryInk`, sàn 4,3 và trần 16°; giữ rim, R9
  exemption cho paper và trần sat 0,75. Ghi lại để lần sau không đi lại đường này.
- **Goal:** Chủ dự án xem gallery M100.26 và chỉ định: `primary`, nền app và nền
  card là màu chính, **không sửa**, phải giống Tokyo; nếu phải sửa thì sửa những
  điểm khác. M100.25–26 đã hạ `primary` light về `primary.dark` (`#4454CC`), đảo
  dark `primary` về tone 80 (`#BCC2FF`), tint paper light (`#FBFBFE`) và nâng card
  dark lên tone 10,4 (`#171B30`) để qua gate. Task này trả bốn giá trị đó về
  Tokyo nguyên hex và dời phần điều chỉnh sang on-colour, binding chữ, cue chiều
  sâu và ngưỡng luật — mỗi chỗ có số đo.
- **Scope:** `app_colors.dart` (`primary` L/D, `onPrimaryDark`, **mới**
  `primaryInk` L/D, **mới** `cardRimDark`, `textSecondaryDark`, `disabledSurface`
  L/D); `app_surface_colors.dart` (`surface` L/D, `surfaceElevatedLight`);
  `app_material_roles.dart` (họ primary dark đổi hue theo `#8C7CF0`, `*Fixed`
  primary theo `#5569FF`); `app_semantic_colors.dart` (field `primaryInk`);
  `app_ink.dart`, `app_button_themes.dart`, `app_planned_themes.dart`,
  `app_theme.dart` và 4 widget (binding thương hiệu-làm-chữ → `primaryInk`);
  `app_elevation.dart` (dark vẽ rim); kit `colors.css` + `elevation.css`; 12 file
  test; `widgetbook` catalog; AD-14; `design_audit/`; toàn bộ golden.
- **Bốn giá trị cố định và cái giá của từng cái, đo được:**
  | Giá trị Tokyo | Đo | Nhường ở đâu |
  |---|---|---|
  | `primary` light `#5569FF` | trắng trên nó **4,33:1**; làm chữ 4,33 trên card, **3,96 trên trang** | nhãn nút giữ trắng, sàn cặp này **4,3** (quyết định chủ dự án, ghi trong test); chữ thương hiệu bind `primaryInk` = Tokyo `primary.dark` `#4454CC` (6,20 / 5,67) |
  | `primary` dark `#8C7CF0` | trắng trên nó **3,36:1**; làm chữ 5,73 / 5,27 nhưng **4,29 trên tile chọn**; lệch **15,3°** so với light | `onPrimary` = paper Tokyo `#111633` (5,27); `primaryInk` = `lighten(main,.25)` `#A99DF4` (6,2 trên tile, 4,83 trên band lỗi); trần lệch hue 12° → 16° |
  | card light `#FFFFFF` | không hue → R9 đỏ cho 4 role | R9 miễn đúng bốn role là paper (`surface`, `surfaceBright`, `surfaceContainerLowest`, `surfaceElevated`) |
  | card dark `#111633` | cao **4,3 L\*** trên trang (sàn 6); sat 0,50 = 72 % trang (trần 60 %) | dark vẽ **rim Tokyo** `0 0 2px #6A7199` (4,07:1 trên trang, 3,74 trên card) ở mọi level; sàn bậc 6 → 4 **cộng** rim ≥ 3:1; trần sat 0,6 → 0,75 |
- **`primaryInk` là token M100.18 đã gỡ, quay lại có lý do khác.** Khi đó `primary`
  được phép dịch nên token thay thế là triệu chứng; nay `primary` bị khoá nên
  binding là đòn bẩy duy nhất. Slot đổi: TextButton, OutlinedButton (foreground),
  TabBar `labelColor`, ListTile `selectedColor`, `AppInk.accent`, và 4 chỗ widget
  đọc `colors.primary` làm chữ (`MxActionButton` secondary, `MxSessionTopBar`,
  `CardMetric` scheduler, `CardState` reviewing). Fill, focus ring, caret, radio,
  switch, progress, stepper, indicator tab **vẫn là `primary`**.
  `m3_role_binding_guard_test.dart` ghi OutlinedButton là slot duy nhất cố ý rời
  `_OutlinedButtonDefaultsM3`, và `refuses` `primary` để không ai trả nhãn dưới AA
  về.
- **Phép đo tổng độ nổi card tách đôi** (`app_theme_test.dart`): light = bậc
  surface + shade ≥ 6 L\* (đo 9,2); dark = bậc ≥ 4 L\* **và** rim ≥ 3:1 trên
  trang lẫn card. Bỏ ràng buộc "hai mode lệch nhau < 2 L\*" vì hai mode nay dùng
  hai loại cue — shade và cạnh — không cộng chung được. `css_scale_parity_test`
  và `elevation.css` cùng nói dark vẽ rim.
- **Dẫn xuất theo:** `textSecondaryDark` = ink @ 70 % trên `#111633` (`#9395A2`);
  `disabledSurface` = ink @ 12 % trên paper (`#E4E7EA` / `#272C46`);
  `primaryContainerDark` `#32296D`, `onPrimaryContainerDark` `#DAD4FE`,
  `inversePrimaryDark` `#453799` đổi hue theo `#8C7CF0` giữ tone; `*Fixed` primary
  từ `#5569FF` (`#DFE0FF` `#BCC2FF` `#000B62` `#122CCB`).
- **Hai chỗ nhỏ theo sau:** `progressFillLight` là `#4454CC` (Tokyo `primary.dark`)
  thay cho `#5569FF` của M100.26 — `mx_progress_bar_test.dart` giữ luật "bar không
  bao giờ trùng hex của nút", và với `primary` bị khoá thì bar lấy shade kế tiếp
  của họ (5,50:1 trên track). Audit màn hình (`TextContrastRule`) ghi đúng **một**
  cặp được chủ dự án chấp nhận — trắng trên `#5569FF` ở sàn 4,3 — tại một chỗ
  thay cho allowance từng màn, nên trượt dưới mức đã chấp nhận vẫn đỏ.
- **Editable documents:** `docs/wbs.md`, `docs/architecture.md` (AD-14).
- **Output:** như Scope.
- **Acceptance criteria:**
  - [x] `primary` L/D, `background` L/D, `surface` L/D đúng hex Tokyo, không lệch
        một đơn vị; `css_token_parity_test.dart` xanh.
  - [x] Mọi chữ mang thương hiệu ≥ 4,5:1 trên mọi ground nó ngồi (`app_ink_test`,
        `app_palette_test` secondary action, `component_depth_and_state_test`
        ListTile, tab bar); duy nhất cặp nhãn nút light giữ 4,3 có ghi lý do.
  - [x] `test/core/theme`, `test/design_audit`, `color_*_rules`, `test/shared`
        xanh; full host suite 4181/4181; guard 0 finding; analyze 0/0 app +
        widgetbook; `check_architecture.py`, `check_docs.py`, 68 test CI tooling xanh.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`: 303/303, **202 PNG đổi**; gallery
        republish tại URL ghim.
- **Dependencies:** M100.26.
- **Tests required:** các test đã sửa ở Scope; không thêm file test.
- **Checklist phases:** 7.

## Known technical debt

| Item | Incurred in | Cost of leaving it | Planned repayment |
|---|---|---|---|
| ~~Bốn token thương hiệu ngoài scheme còn ở hue 240~~ | M100.25 | `borderSelected`, `borderAccent`, `borderOption`, `progressFill` light là dẫn xuất tay của indigo cũ, lệch 7° so với `primary` mới | **Đã trả ở M100.26.** Cả bốn nay là tint của Tokyo `primary.main` (`#5569FF`, `#AAB4FF`, `#8896FF`, `#5569FF`) |
| Shape, typography và shadow chưa theo Tokyo | M100.26 | Màu đã là Tokyo nhưng radius (memox 4/8/12 so với Tokyo 6/10/12/16), font và shadow card (`0 9px 16px rgba(159,162,191,.18)`) vẫn là của A2, nên màn hình đọc là "Tokyo tô lên khung memox" | Một task riêng cho từng trục: radius chạm `css_scale_parity_test.dart` và `radius.css`; shadow chạm `AppElevation` và phép đo tổng độ nổi card của AD-14 mục 4 |
| `AppSemanticColors.surfaceElevated` không còn consumer | M100.20 | Nó tồn tại để làm nền cho PopupMenu, và menu nay đọc `surfaceContainer` theo M3. Một token chết trong kit là thứ người sau sẽ với tay lấy, và nó là rung thứ sáu của một thang song song mà M3 chỉ có năm | Gỡ trong đợt hợp nhất hai thang surface: 21 dòng ở 7 file test, cộng `--color-surface-elevated` của kit cần map hoặc giải thích. Hằng số `AppSurfaceColors.surfaceElevated*` **vẫn dùng** làm dẫn xuất cho `surfaceContainerLowest` và `surfaceBright` nên chỉ field của extension mới chết |
| ~~`check_architecture.sh` chưa có test tự động~~ | T0.1 | Regression trong checker âm thầm ngừng enforce boundary | **Đã trả ở M100.11.** `test_architecture_checker.py` trong bộ CI tooling — bốn fixture tiêm lỗi: dự án sạch pass, `domain/` import Flutter thì đỏ và gọi tên file, thiếu suffix thì **cảnh báo** (ghim cả hai chiều, vì `_check_suffixes` gọi `_warn` chứ không `_fail`), và pubspec-không-lib thì đỏ. Đặt ở `scripts/tests/` chứ không `test/tools/` vì đó là nơi `unittest discover` của gate `ci_tooling` đã quét. Ghi chú gốc: **Giảm nhẹ ở M4.10b:** script tự in số file nó quét và coi 0 là lỗi, nên trường hợp tệ nhất — checker ngừng thấy gì mà vẫn pass — không còn im lặng. Vẫn cần fixture cho các trường hợp còn lại |
| ~~Không có CI~~ | T0.1 | Sáu gate tồn tại và chỉ chạy khi có người nhớ; một PR có thể merge với format lệch, guard đỏ hoặc test hỏng mà không ai thấy | **Đã trả ở M4.10b.** `.github/workflows/ci.yml` chạy trên `pull_request` và `push` vào `main`: format, analyze, generated-code, architecture, guard, docs, 844 test, golden, và build web |
| ~~`analysis_options.yaml` chưa được áp dụng~~ | T0.1 | Bộ lint đã viết nhưng chưa được enforce; nhiều khả năng có tên rule sai hoặc đã deprecated | **Đã trả ở M2.3.** Dự đoán đúng: `immutable_classes` không tồn tại, `use_if_null_to_convert_nulls_to_bools` đã deprecated. Nghiêm trọng hơn cả hai: 11 rule chỉ nằm ở `errors:` nên **chưa bao giờ chạy** — đã chuyển hết sang `linter: rules:` và kiểm chứng bằng tiêm lỗi |
| ~~14 query bất biến chưa chạy trên database thật~~ | T1.3 | Bất biến mới được verify trên fixture Python, chưa chạm schema Drift nào | **Đã trả một phần ở M4.4.** Cả 14 chạy trên database SQLite thật do schema production tạo — 30 test, mỗi bất biến hai chiều, cộng một test chứng minh một khiếm khuyết chỉ kích hoạt đúng những bất biến thật sự phủ nó. `check_docs.sh --db` cũng chạy đủ 14 (trước đó chép tay **10/14** và vẫn báo thành công). **Chưa trả:** vẫn là database tạm trong test, chưa phải dữ liệu người dùng thật — cái đó cần M8 |
| ~~Pin Flutter ở `.fvmrc` **khai báo** chứ không **cưỡng chế**~~ | M2.2 | Chạy `flutter` trực tiếp trên máy có version khác vẫn build được và không cảnh báo. Đây đúng là lỗi đã xảy ra: M2.1 chạy 3.44.8, phiên sau khởi động trên 3.44.6, không có gì phát hiện ra | **Đã trả một nửa ở M4.10b:** cả hai job CI dùng `flutter-version-file: .fvmrc`, nên `.fvmrc` là nguồn duy nhất và CI không thể lệch. **Chưa trả:** máy lập trình viên vẫn chạy version nào cũng được — **Đã trả ở M100.11:** `check_flutter_version.sh`, planned như một gate nên chỉ chạy khi gate thật sự chạy — pass stamp vẫn short-circuit trong ~0.4s, đúng như header của `dod_check.sh` giải thích. Kiểm bằng tiêm lỗi |
| ~~7 file skill vẫn bảo chạy `dart run custom_lint`~~ | M2.2 | Skill vẫn hướng dẫn cài và chạy một package không cài được; phiên sau sẽ tin skill và loay hoay | **Đã trả ở M2.2b.** Cả 7 file đã trỏ sang guard. `docs/checklist.md` **cố ý giữ nguyên**: nó `frozen for MVP`, và mục "Ngoài phạm vi: mọi quyết định riêng của memox" nói rõ nó mô tả quy trình 22 phase chung — `custom_lint` ở đó là khuyến nghị Flutter phổ thông, còn quyết định riêng của memox sống ở file này (§5 canonical location) |
| ~~`dependencies.md` vẫn liệt kê `sqlite3_flutter_libs`~~ | M2.2 | Package đó nay là tombstone (`0.6.0+eol`, không có native code). Skill nói sai còn tệ hơn không có skill — phiên sau sẽ cài lại nó | **Đã trả ở M100.11.** Sửa `.claude/skills/flutter-project-setup/references/dependencies.md`: thay bằng ghi chú rằng `sqlite3` 3.x cấp native lib qua native assets. Ngoài `Editable documents` của M2.2 nên chưa sửa ở đây |
| ~~`app_colors.dart` vượt trần 400 dòng của guard~~ | M99.4, **tái phát M99.94–M100.0** | Guard báo `no_large_source_file` (406/400). Cảnh báo chứ không lỗi nên CI vẫn xanh, nhưng **file đang ở đúng trần**: token tiếp theo bất kỳ cũng sẽ vượt, và `borderControl` chỉ tình cờ là cái đầu tiên | **Đã trả ở M99.5.** Khối `// --- Material roles` tách ra `lib/core/theme/app_material_roles.dart` (`AppMaterialRoles`), `app_colors.dart` còn 339 dòng. `part` vẫn không dùng được — Dart không có partial class. Chạm nhiều hơn 4 file đã dự đoán: hai allowlist (`color_source_rules_test.dart`, `audit_scan_steps.dart`) và **scanner của audit** cũng phải biết tên lớp mới, xem M99.6 **Tái phát và đã trả lại ở M100.1.** Bốn token mới (`surfaceEmphasis`, `surfaceSelected`, `borderSelected`, `borderDivider`) cùng phép đo giải thích từng cái đưa file từ 407 lên 513. Tách theo vai trò, đúng cách M99.5 đã làm: `AppSurfaceColors` và `AppBorderColors`, file gốc còn **309**. Bài học lặp lại nguyên vẹn — allowlist R2 của `color_source_rules_test.dart` lại phải học tên file mới, y như ghi chú M99.5 đã cảnh báo. |
| ~~`study_session_controller.dart` vượt trần 400 dòng của guard~~ | M5.23 | 408/400, và **warning cũng làm đỏ gate**. Class giữ toàn bộ command của phiên học, cộng summary và failure policy | **Đã trả trong cùng PR.** Tách `_loadSummary` + `StudySessionState.summary` thành `studySessionSummaryProvider` — một **query**, không phải command, nên nó chưa bao giờ thuộc về controller. Controller còn 380 dòng. Lợi ích thật chứ không chỉ số dòng: read cũ có ba call site (hết stage, leave, failure path) nên summary chỉ đúng bằng người cuối cùng nhớ đủ cả ba, và field thì sống lâu hơn phiên — quên một call site là hiện số của phiên trước dưới tiêu đề phiên mới |
| ~~`dart format .` trong `dod_check.sh` crash trên worktree~~ | M2.2b | Bước `format` đỏ ở **mọi** lần chạy local nhiều tuần liền: `.` đi vào `.claude/worktrees/`, nơi Gradle xoá thư mục ngay giữa lúc formatter đang liệt kê → `PathNotFoundException`. Vì là lỗi môi trường chứ không phải lỗi format, mỗi lần lại được *báo cáo và đi vòng* thay vì sửa — và một gate đỏ mà ai cũng biết là đỏ thì không còn là gate | **Đã trả.** `dart_roots()` lấy tập thư mục từ `git ls-files '*.dart'` cắt tới segment đầu. Đúng câu hỏi cần hỏi — *cây làm việc **này** track những file Dart nào* — nên build output không tracked không lọt vào, worktree bị `.git/info/exclude` loại sẵn, và một thư mục top-level mới tự động được nhận. **Lỗi thứ hai nghiêm trọng hơn cái crash:** `.` đưa cho formatter source của **nhánh khác**, nên một worktree có format cũ làm gate đỏ vì code không nằm trong cây làm việc |
| ~~`study_session_controller.dart` vượt trần 400 dòng của guard~~ | M5.24 | 423/400. Warning cũng làm đỏ gate. Class giữ toàn bộ command của phiên học | **Đã trả ở M5.25.** Không tách được bằng cơ chế ngôn ngữ — Dart không có partial class, base class Riverpod sinh ra là private, và extension trong `part` cũng không dùng được `state` (`invalid_use_of_protected_member`, đã thử và revert). Nên tách bằng **trách nhiệm**: offset nhìn lại của `browse` là view state, không phải command của phiên, và nay là `StudyBrowseTrailController`. Controller còn 387 dòng |
| ~~`study_answers` chưa có index cho khoảng thời gian~~ | M99.28 | Progress lọc `answered_at >= ? AND answered_at < ?`; index duy nhất chạm cột này là `(card_id, answered_at)`, mà cột dẫn đầu không nằm trong predicate — nên mỗi lần emit là một full scan `study_answers`, và stream re-emit theo **mỗi lượt trả lời** khi màn hình đang mở (ở độ sâu 3 là ba scan mỗi lượt). Output có chặn, scan thì không | **Đóng ở M100.12 bằng phép đo, và phép đo bác bỏ tiền đề.** `EXPLAIN QUERY PLAN` trên database thật: window **không** full-scan. Nó là một **join** và `cards` lái — SQLite tìm card sống qua `idx_cards_delete_batch` rồi vào `study_answers` với `card_id` **đã bind sẵn**, tức đúng cột dẫn đầu mà dòng nợ tưởng là thiếu, do join cấp chứ không do predicate. `idx_study_answers_card` phục vụ cả hàng như **COVERING INDEX**. Thêm `(answered_at)` đổi plan **bằng không**, nên **không thêm** — một index không ai đọc vẫn bắt mọi lượt ghi answer trả phí. `progress_query_plan_test.dart` ghim cả plan lẫn sự vắng mặt của index. Ghi chú gốc: Thêm index `(answered_at)` — nhưng đó là **đổi schema**, tức bump version + snapshot + migration test, và M99.28 cố ý không đụng schema. Trả cùng lần bump schema tiếp theo, và theo đúng rule index của repo: đo bằng `EXPLAIN QUERY PLAN` trên dữ liệu thật trước rồi mới thêm |
| ~~`ancestry` CTE trong `deck.drift` không có bound~~ | M99.28 | Cùng khiếm khuyết đã sửa ở `progress.drift`: walk mang `distance` tăng mỗi vòng nên `UNION` không dedup được, và trên cây cha vòng lặp thì statement không bao giờ trả về — nó giữ database isolate, nên mọi query khác của app chặn theo. Comment ở `deck.drift` còn khẳng định ngược lại | **Đã trả ở M99.86.** `ancestry` nhận `:maxWalk = DeckEntity.maxTreeDepth + 1`; `branch` giữ `UNION` không bound vì row của nó hữu hạn. Test SQLite thật dựng cycle, buộc read kết thúc và chứng minh query kế tiếp trên cùng database isolate vẫn chạy. |
| ~~`end_reason = scheduler_reset` phải mang cả BR-164~~ | M99.16 | Đổi scheduler khi chưa khoá ghi cùng giá trị với Reset, nên đọc riêng cột đó thì hai sự kiện khác nhau trông giống nhau. Không mất thông tin — `study_sessions.scheduler_generation` bằng generation của root sau một lần đổi và nhỏ hơn sau một lần reset — nhưng nó bắt người đọc phải biết mẹo đó | Tên đúng là `scheduler_changed`. `study_sessions.end_reason` có `CHECK` liệt kê giá trị nên thêm một giá trị là **đổi schema**, và nới `CHECK` là rebuild bảng nên xứng một bump riêng. Ba lần bump sau khi nợ được ghi đều đã đi việc khác: v8 (BR-203, ba cột `direction` additive), v9 (M99.28, hai cột theme/ngôn ngữ), v10 (M99.29, ba cột nhắc học); v11 (M99.33, Trash) có rebuild `study_sessions` nhưng cố ý không gánh thêm nợ này. **Đã trả ở M100.13.** Đích đúng là v12 và nó được làm riêng thay vì chờ ghép: không còn lần rebuild `study_sessions` nào đang chờ để ghép vào. Ghi chú gốc: Đích hiện tại là **v12** — lần rebuild kế tiếp của `study_sessions`, rồi đổi `deck_scheduler_repository_impl.dart` sang giá trị mới |
| `MxAlertDialog` không có consumer nào trong app | trước M100.5, **đo ở M100.5** | 101 dòng shared có entry Widgetbook, có test, có stress specimen — nên nhìn đâu cũng tưởng sống. Một kit có hai cách làm một việc thì lần sau người ta chọn nhầm nửa thời gian | **Cố ý chưa trả.** Nó không phải bản sao của `MxConfirmDialog`: một hành động thay vì hai, và doc ghi rõ vì sao nó **không** phải live region trong khi confirm thì phải. Xoá một primitive có chủ đích để đạt con số dòng là đổi chác sai. Quyết định khi có màn đầu tiên cần alert một-nút — dùng nó, hoặc lúc đó mới xoá |
| Suite  flaky khi chạy gộp một lệnh | M100.14 | Bốn lượt đo: gộp cho 5/8, 6/8, 7/8 với **tập lỗi đổi giữa các lượt mà code không đổi**; từng file thì 6/6 + 2/2 = 8/8. Hai file dùng chung một emulator và một bản cài, nên state hoặc thời gian rò giữa chúng. Hệ quả: gate chỉ tin được khi chạy từng file, và một người chạy gộp sẽ thấy đỏ mà không hiểu vì sao | Tìm state rò giữa hai file — nghi trước hết là app install và database còn sót giữa hai suite. Đoán mò sẽ làm hỏng thêm, nên cần một lượt đo riêng |
| Nội dung starter là fixture, không phải nội dung production | T1.3 | Không phát hành được với nội dung này | Tìm nguồn nội dung có bản quyền rõ ràng trước M8 (BR-87) |
| ~~`sqlite3.wasm` và `drift_worker.js` là binary vendored trong `web/`~~ | M4.2 | Không có bước build nào sinh ra chúng và không có bước build nào báo khi chúng cũ: app compile, load, rồi **không mở được database**. Nâng `drift` mà quên tải lại worker không có triệu chứng nào cho tới khi ai đó mở trình duyệt | **Đã trả ở M4.2, ghi vào sổ ở M100.9.** `test/database/web_assets_test.dart` so version trong `pubspec.lock` với version đã pin, kèm `web/WEB_ASSETS.md` ghi URL tải. Đã kiểm tiêm lỗi: đổi `drift` thành 2.99.0 làm test đỏ |
| Server phát web chưa gửi COOP/COEP | M4.2 | `crossOriginIsolated` là `false`, nên drift chọn backend lưu trữ kém hơn OPFS. Không có lỗi nào — chỉ là hiệu năng và độ bền khác đi, âm thầm | Thêm `Cross-Origin-Opener-Policy: same-origin` và `Cross-Origin-Embedder-Policy: require-corp` vào server phát web ở M7, và kiểm lại `crossOriginIsolated` trong E2E |
| ~~Bản build web MUST dùng `--no-web-resources-cdn`~~ | M2.1a | Mặc định Flutter tải CanvasKit từ `gstatic.com` lúc **runtime** dù đã bundle sẵn cục bộ. Trong môi trường chặn CDN, app im lặng không render — không có lỗi build nào cảnh báo | **Đã trả ở M4.10b.** Job `web-build` trong `.github/workflows/ci.yml` dùng cờ này. **Chưa trả:** hướng dẫn chạy web thủ công vẫn chưa nhắc nó |
| ~~`check_docs.sh` chỉ đếm task ID dạng `T*`, bỏ sót `M*`~~ | T1.4 | Báo "no duplicate WBS task IDs (8 tasks)" trong khi có 33 — **pass gây hiểu nhầm**, 25 task M2–M5 không được bảo vệ khỏi trùng ID | **Đã trả ở M2.1b.** Regex sửa thành `[TM][0-9]+(\.[0-9]+)?[a-z]?` (giờ báo 35 task), thêm check dependency resolve và check `M*` đủ field + acceptance criteria không rỗng. Cả ba verify bằng test tiêm lỗi, 4/4 case đạt |
| Chín trong mười bốn hợp đồng đóng băng của V1 chỉ được giữ bằng test | M100.41 | Guard quét `lib/features/` cho 5 dòng (mục 2, 4, 5, 12, 13); 9 dòng còn lại — role identity, ThemeData mapping, shared API, sàn 48dp, ripple/state, high contrast, depth của card, chrome của shell, golden Linux-only — chỉ có test giữ. Test là file trong repo, nên một nhánh feature nới nó ra là đi qua được, và **guard không đỏ khi chính nó bị sửa**. Hiện chỉ có văn bản (`v1-freeze.md` §3) cấm điều đó | Một cơ chế thay cho một câu văn: hoặc CODEOWNERS trên các file Enforcement của §2, hoặc một rule guard đọc diff và bắt PR nào vừa chạm `lib/features/` vừa nới một file canh gác. Chưa làm ở M100.41 vì nó là thay đổi tooling, không phải thay đổi tài liệu — và MUST được kiểm bằng tiêm lỗi trước khi tin |
| `StudySessionScreen` rời shell bằng `Navigator.push` chứ không bằng `GoRoute` | trước A8, đo ở A8 P2-15 (`docs/reviews/a8-navigation-chrome-audit.md` §10.5), đo lại ở C4 SC-C4-18 | Phiên học không có location: trong suốt lúc nó ở trên cùng, `GoRouterState.matchedLocation` vẫn đọc là `/study/<id>` hoặc `/decks/<id>/study`, nên không có gì deep-link hay restore vào một phiên đang chạy, và `GoRouterState` nói sai trong đúng khoảng thời gian dài nhất của app | **ACCEPTED, chờ quyết định của chủ dự án.** Phần *root navigator* đã có lý do và không phải nợ — nó là thứ giữ BR-82 một lối ra duy nhất (comment tại `study_entry_screen.dart` `_open`); chỉ **cơ chế** là còn mở. C4 cố ý chỉ mount `StudyOptionsScreen` (composition thuần: nó vốn đã render trong shell, chỉ thêm location) và **không** mount phiên học, vì bán kính nổ nằm ngoài tầm một task chrome: IT-NAV, đường resume khoá theo `sessionId` (BR-200, BR-103) và hợp đồng một-lối-ra của BR-82 đều chạm nó, và không cái nào verify được bằng host test. Khi mở lại: mount với `parentNavigatorKey: rootNavigatorKey` đúng như wizard import, `resumeSessionId`/`direction` đi bằng `extra`, và closure test là `currentConfiguration.uri` gọi tên route phiên |
| `CardEditorScreen` (edit) xếp chồng hai dải pinned ở đáy | trước C4, đo ở C4 SC-C4-04 | Route edit nằm trong `StatefulShellBranch` của Decks, nên `MxNavigationBar` bốn đích vẫn vẽ dưới nó; màn hình lại ghim action bar của chính nó vào `MxContentShell.footer` (`MxButtonPair` ≥48dp + `sm` + một dòng `bodySmall` + 2×`md`). **Đo, mount qua `createAppRouter`:** footer **96dp** + nav bar **80dp** = **176dp** chrome đáy. Không golden nào thấy được: `card_screens_demo_test.dart` pump thẳng `CardEditorScreen`, ngoài `createAppRouter` | **ACCEPTED — variance có chủ đích, không phải nợ nhánh route.** Edit là **page** được push lên card list và quay về đó (mũi tên back nói đúng điều đó), và nó push tiếp một branch route cho history của thẻ — đưa nó lên root navigator sẽ render Card Detail **dưới** editor. Wizard import thoát khỏi branch được vì nó là task không push branch route nào; đây không phải trường hợp đó. Đã ghi tại `app_router.dart` ngay trên `RouteNames.cardEditorEdit` để nó thôi là hệ quả tình cờ của việc lồng route. **Đính chính phép đo gốc:** SC-C4-04 viết edit là màn *duy nhất* xếp chồng hai dải — sai. Create cũng ghim footer từ SC-C1-02 và cũng nằm trong branch, nên nó xếp chồng y hệt; nửa mâu thuẫn thật sự là create, vì `✕` của nó tuyên bố một task trong khi thanh branch vẫn ở đó. Sửa nửa đó là SC-C4-19 (`parentNavigatorKey: rootNavigatorKey` cho `cardCreateRelative`), **không** nằm trong cụm C4 này | Khi 176dp chrome đáy được phán là không chấp nhận được trên thiết bị: lúc đó câu hỏi là "editor là page hay task" — một quyết định của chủ dự án, không phải một phép sửa composition. Hoặc khi SC-C4-19 được giao, vì nó chốt nửa create của cùng câu hỏi |
