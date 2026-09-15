# WBS — work breakdown and progress ledger

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì **đang** làm, bị chặn, hoặc đã descope. Việc đã đóng nằm ở `wbs-archive/` |
| **Scope** | Task đang mở · blocker · technical debt · quyết định descope/superseded. Ngoài phạm vi: entry đã `done` — chúng ở `wbs-archive/`, vẫn trong đồ thị dependency qua `_wbs_ledgers()` |
| **Source of truth for** | Trạng thái task · blocker · technical debt · quyết định descope |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M9.T1 |
| **Last updated** | 2026-09-08 |

Single source of truth for project progress. Update it in the same commit as the
work it describes. A task is `done` only when it meets the Definition of Done in
`.claude/skills/flutter-workflow/references/definition-of-done.md`.

Status values: `todo` · `in-progress` · `blocked` · `done` · `descoped`

**Task ID là định danh vĩnh viễn và không được trùng**, cùng chính sách với BR /
AD / UC (xem `business-rules.md`).

## Progress summary

| | Sổ sống | Archive | Tổng |
|---|---|---|---|
| Entry | 6 | 299 | 305 |
| Dòng | 593 | 19,432 | 20,025 |

**Đang chạy: một task** — `M99.29`. Năm entry còn lại ở sổ sống mang trạng thái
cuối (`descoped` ×3, `integrated`, `superseded`) và ở lại vì chúng là quyết
định người đọc cần thấy, không phải việc đã xong.

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

## M9 · MemoX API

Backend Spring Boot độc lập trong `memox-api/`. Ba plan Phase 0/1/2 đều ghi
"Updated by task: M9", nhưng milestone này chưa từng có mặt trong sổ — WBS đã
tụt sau code của module đó từ đầu.

### M9.W1 · Wave 1 — làm cho module kiểm chứng được

- **Status:** **done** — `./mvnw -B verify` xanh 37/37, cả hai gate đã tiêm lỗi.
- **Goal:** Không thêm tính năng nào. Chỉ dựng đủ hạ tầng để mọi khẳng định về
  module này là **phép đo** chứ không phải trí nhớ. Audit
  (`docs/reviews/memox-api-spring-standards-audit.md`) tìm ra hai blocker: module
  chưa từng được CI verify, và suite không chạy được trên máy dev.
- **Scope:** `mvnw` thành executable · backend test chọn được giữa Testcontainers
  và PostgreSQL local · reset dữ liệu đọc từ catalog · Checkstyle + PMD + SpotBugs
  · ngưỡng JaCoCo · snapshot OpenAPI · job `memox_api` trong `ci.yml` và trong
  `needs:` của `CI gate` · `compose.yaml` (deliverable còn nợ của Phase 0).
- **Out of scope:** Wave 2 (đổi tên package) và Wave 3 (contract phân trang, log
  service, exception ôm id) — cùng thiết kế, nhánh khác.

**Hai lỗi thật mà Wave 1 phát hiện — đây là giá trị của nó, không phải hạ tầng:**

1. **Mọi lệnh tạo deck/card trả HTTP 500.** `deck_mapper.xml` khai
   `javaType="int"`, nhưng trong `TypeAliasRegistry` của MyBatis `int` là
   `Integer`; kiểu nguyên thuỷ là `_int`. Record `Deck` nhận `int
   siblingPosition`, nên constructor không khớp:
   `NoSuchMethodException: Deck.<init>(…, Integer, Integer, Integer, …)`.
   `card_mapper.xml` sai y hệt với `boolean`/`is_flagged`. Bảy trong tám failure
   đầu tiên là nó. **Nó sống sót vì những test đó chưa từng chạy** — đúng câu
   audit viết: trạng thái xanh của module là trí nhớ, không phải phép đo.
2. **Snapshot OpenAPI ghi bằng CRLF.** Jackson dùng ký tự xuống dòng của nền
   tảng. Hậu quả thật không phải một test đỏ mà là CI (Linux) và máy dev
   (Windows) lật toàn bộ file qua lại mỗi lần regenerate — một contract diff
   không ai đọc nổi. Đã ghim LF trong bộ ghi.

**Ngưỡng coverage là số đo, không phải số chọn:** lần xanh đầu tiên cho
INSTRUCTION 0.9364 / BRANCH 0.7258; ngưỡng đặt ở `đo − 0.02` = 0.92 / 0.71. Một
ngưỡng bịa ra sẽ bị hạ xuống ngay lần đầu nó đỏ.

**Cả hai gate đã tiêm lỗi, không nhận xanh suông:** Checkstyle — thêm một `else`
và một biến không `final` → ERROR, BUILD FAILURE; JaCoCo — ép 0.99 →
`Rule violated … 0.93 < 0.99`. Lần tiêm lỗi coverage **đầu tiên vô hiệu** (gọi
`jacoco:check` thẳng từ CLI không nạp `<configuration>` của execution, nên nó đỏ
vì thiếu tham số chứ không vì coverage); đã làm lại qua đúng lifecycle.

**Còn nợ, có chủ đích:** Wave 2 và Wave 3. Và `openapi.json` mới chỉ phủ bốn
endpoint hiện có — nó là đường cơ sở để Wave 3 diff, chưa phải hợp đồng đầy đủ.

### M9.W2 · Wave 2 — đưa package về layout của skill

- **Status:** **done** — `./mvnw -B verify` xanh 39/39; guard mới đã tiêm lỗi hai lần.
- **Goal:** Đổi tên package, không đổi hành vi. Để một feature mới là bản sao của
  feature cũ chứ không phải một lần phán đoán ở mỗi thư mục.
- **Scope:** `<feature>/api/` → `controller/` + `dto/request/` + `dto/response/`;
  `<feature>/domain/` → `entity/` + `enums/` + `exception/`; `health/` theo cùng
  khuôn. Cộng I4 (javadoc rỗng) và I5 (`this.` lạc lõng).
- **Giữ nguyên có lý do:** `persistence/` **không** đổi thành `mapper/` —
  `spring-boot-mybatis.md` cho phép "package tương đương repository mà repo đã
  dùng". `common/` không đụng: nó ngoài phạm vi đã duyệt, và đổi tên nó không mua
  được gì.

**Bằng chứng "không đổi hành vi" không phải là "test vẫn xanh".** Test cũng dời
package, nên câu đó đã mất nghĩa. Bằng chứng thật là **`openapi.json` không đổi
một byte**: hợp đồng mà ứng dụng công bố giống hệt trước và sau. Đó là thứ Wave 1
dựng ra để hôm nay dùng được.

**Ba hệ quả mà "chỉ đổi tên thư mục" không nhìn thấy:**

1. **Tên class đầy đủ nằm trong chuỗi XML của MyBatis** — 8 chỗ ở `namespace`,
   `type`, `javaType`, `typeHandler`. Đổi package làm hỏng chúng ở **runtime**,
   không phải lúc biên dịch. Việc `DeckControllerTest`/`CardControllerTest` xanh
   là bằng chứng cả 8 đã sửa đúng.
2. **Tách `api/` xoá một ranh giới thật.** `DeckResponse.from()` và
   `CardResponse.from()` là package-private khi controller còn nằm cạnh chúng;
   sau khi tách thì phải `public`. Đây là mất mát thật, ghi ra chứ không lẳng lặng
   coi là sửa cơ học.
3. **Tham chiếu cùng-package giờ cần `import`** — 9 cái, javac chỉ đích danh từng
   cái thay vì phải đoán.

**Guard phải đi cùng nhịp, và giờ nó tự bắt được nếu không.** `LayerArchitectureTest`
canh theo tên package; một luật trỏ vào package đã biến mất sẽ **chọn rỗng và
xanh suông**. Thêm `everyGuardedPackageStillExists()` để đúng chuyện đó thành lỗi
đỏ, và một luật mới `entitiesDependOnNoOuterLayer` — luật này **trước đây không
phát biểu được**, khi entity/enum/exception còn chung một package `domain`. Cả
hai đã tiêm lỗi: trỏ guard vào `..api..` → đỏ kèm đúng câu giải thích vacuous
pass; cho `Deck` phụ thuộc `persistence` → đỏ.

**Còn nợ:** `this.` không có gì cưỡng chế — `RequireThis` của Checkstyle sẽ khoá
được, nhưng đó là một diff cơ học rộng nữa nên để lại cho một task riêng.

### M9.W3 · Wave 3 — đổi hợp đồng

- **Status:** **done** — `./mvnw -o verify` xanh 61/61; guard mới đã tiêm lỗi.
- **Goal:** Wave 1 làm module kiểm chứng được, Wave 2 dời chỗ. Wave 3 là wave duy
  nhất **đổi thứ client nhìn thấy**, nên nó đi sau cùng và diff `openapi.json`
  chính là biên bản của nó.
- **Scope:** R4 (hợp đồng phân trang `page`/`size` zero-based, `PageQuery<TSort>`,
  `SortSpec<TSort>`, `SortDirection`, `SortField`, `PageSlice`) · R2 (exception ôm
  `deckId`) · I1 (log ở service + ở `ApiExceptionHandler`) · I2 (bỏ reflection
  trong `DeckMapperTest`) · I3 (bỏ `readSchemaVersion` — method production không
  có caller production).
- **Hoãn có chủ đích:** trường `search` của `pagination-contract.md`. Chưa câu SQL
  nào trong module tìm kiếm, nên khai nó ra là công bố một query param mà SQL
  bỏ qua — client lọc, nhận về toàn bộ, và không có cách nào biết. Nó về cùng các
  câu lệnh Phase 2 biết đáp ứng nó.

**Hợp đồng cũ vẫn còn dấu vết trong SQL, và đó là chủ ý.** API đếm theo trang,
database đếm theo dòng; `LIMIT`/`OFFSET` giữ nguyên, phép quy đổi `page × size`
nằm đúng một chỗ (`PageQuery.offset()`) và mọi câu lệnh nhận `PageSlice`. Phép
nhân đó được nới lên `long`: `page × size` ở đỉnh dải `int` tràn thành offset âm,
và PostgreSQL trả lỗi chứ không trả trang đầu — một HTTP 500 cho một request chỉ
vô lý chứ không sai cú pháp.

**Sort là enum, không phải chuỗi — và đó là toàn bộ lý lẽ an toàn.** `ORDER BY`
được render bằng `${}` của MyBatis (tên cột không phải giá trị, JDBC không bind
được). An toàn ở đây vì mọi phần tử của `PageSlice.sorts` là `SortColumn`, mà
`SortColumn` chỉ sinh ra từ hằng của `DeckSortField`/`CardSortField` và
`SortDirection`. Một token client bịa ra bị `SortSpecs` chặn ở tầng transport,
trả 400 — không có đường nào dựng `SortColumn` từ text của request.

**Ba thứ Wave 3 học được, cả ba đều do test bắt chứ không do đọc lại code:**

1. **Spring cắt query param theo dấu phẩy khi bind `List<String>`.** Cú pháp
   `sort=createdAt,desc` bị xé làm đôi *trước khi* parser thấy, và `desc` bị đọc
   như tên field — lỗi báo "unknown sort field" trong khi direction hoàn toàn
   hợp lệ. Đổi dấu nối thành hai chấm: `sort=createdAt:desc`. Tác dụng phụ là
   dấu phẩy trở thành dấu ngăn *giữa các khoá sort*, nên
   `sort=a:asc,b:desc` và `sort=a:asc&sort=b:desc` là một. Hành vi bind này giờ
   được ghim bằng một test, vì cú pháp đang dựa vào nó.
2. **`ProblemDetail.instance` echo lại URI, mà `deckId` là path variable.** Test
   khẳng định "id không lọt vào response" đỏ — và nó đúng, khẳng định của tôi
   sai. Điều đúng là: không có property nào **được thêm** cho id; phần xuất hiện
   trong `instance` là input của chính client quay về. Javadoc đã sửa theo.
3. **`transient` trên field `String` của exception là sai.** Nó sinh đúng cảnh
   báo `SE_TRANSIENT_FIELD_NOT_RESTORED` của SpotBugs. `String` vốn
   serializable; bỏ `transient` là hết.

**Guard mới đã tiêm lỗi:** thêm rule Checkstyle `noPrivateContentInExceptions`.
Rule cũ chỉ canh lời gọi `log.*`, nhưng `ApiExceptionHandler` ghi
`exception.getMessage()` ở WARN cho **mọi** `MemoxException` — nên một tên deck
nhét vào constructor exception ra tới log y như gọi `log.warn` thẳng, mà rule cũ
không thấy. Tiêm `parent.name()` vào `DeckConflictException` → BUILD FAILURE,
đúng dòng 77.

**I1 được chứng minh, không phải được khai báo:** một test dựng `ListAppender`
của Logback trên `ApiExceptionHandler` và đòi dòng log chứa `deckId`. Nó khẳng
định *tính chất* chứ không khẳng định câu chữ — đổi cách diễn đạt vẫn xanh, làm
mất id thì đỏ.

### M9.P0 · Dọn đường cho Phase 2

- **Status:** **done** — `./mvnw -o verify` xanh 95/95; bốn guard mới đều đã tiêm lỗi.
- **Goal:** Trả lời câu hỏi "base code Java đã đủ để làm feature chưa" bằng cách sửa
  những chỗ chưa đủ, chứ không bằng một bản báo cáo.
- **Nguồn:** audit 11-agent (5 mảng, mỗi mảng một agent phản biện có nhiệm vụ **bác
  bỏ**, rồi tổng hợp). Kết luận `ready-with-gaps`: 19 finding sống / 1 bị bác. Tôi tự
  kiểm chứng lại 5 claim nặng nhất trước khi làm.

**Điều bất ngờ nhất của audit: trong 4 blocker, ba nằm ở *tài liệu*, một ở code.**
Plan Phase 2 (2689 dòng) là thứ session sau sẽ cầm để thực thi, và nó viết trước cả
ba wave. Một plan lỗi thời không trung tính — nó **sai một cách tự tin** và đọc như
có thẩm quyền.

**Đã sửa trong plan:** 30 đường dẫn `<feature>/domain/` và `<feature>/api/` mà Wave 2
đã xoá · `#{pageQuery.limit}` ở hai câu SQL và `limit=&offset=` ở doc endpoint mà
Wave 3 đã xoá · Task 0 viết lại thành lịch sử (nó đã được làm lại theo thiết kế tốt
hơn — reset đọc từ `pg_catalog` thay vì danh sách bảng chép tay) · Task 0 Step 7 ghi
vào `HELP.md` đang bị gitignore ngay dòng 1 → chuyển sang README · Task 15 trỏ nhầm
`OpenApiContractTest` (smoke test) thay vì `OpenApiSnapshotTest` (chủ sở hữu snapshot)
· `CardSort` trùng với `CardSortField` Wave 3 đã ship.

**Đã bổ sung vào code:**

- **`MemoxFixtures`** — bộ từ vựng seed mà ~186 call site trong plan gọi không định
  danh, và **chưa từng tồn tại**: mọi test Task 2–14 sẽ không compile. Cho
  `PostgresIntegrationTest extends MemoxFixtures` thay vì giữ nó làm field như plan
  viết — cùng kết quả cho mọi call site, mà không cần 25 method uỷ quyền đặt bề mặt
  fixture ở hai nơi. Có `MemoxFixturesTest` 15 ca, vì một DSL 186 chỗ dựa vào mà
  không ai test là đúng thứ audit đang chỉ trích.
- **`AffectedRows.requireExactlyOne`** — UPDATE duy nhất đang có vứt bỏ số dòng, và
  chỉ an toàn nhờ một tiền đề không ai ghi ra (`SELECT … FOR UPDATE` đi trước). Áp
  ngay vào hai call site đó chứ không kèm slice mới: helper không caller là lặp đúng
  lỗi `readSchemaVersion` mà Wave 3 vừa xoá. 0 dòng → exception của caller; >1 dòng →
  **luôn** `IllegalStateException`, vì WHERE hỏng không bao giờ là lỗi của client.
- **`BooleanSmallIntTypeHandler`** — `is_flagged` là `SMALLINT`; đọc chạy nhờ driver,
  **ghi thì hỏng thẳng**. Lệch một chỗ so với plan: **không** dùng
  `includeNullJdbcType`, vì nó sẽ chiếm luôn mọi boolean không khai jdbcType — kể cả
  `activeDeckExists` vốn đọc BOOLEAN thật.
- **`V5__defer_deck_sibling_position.sql`** — `DEFERRABLE INITIALLY DEFERRED`, đổi
  chỗ cho reorder deck. Không chỉ khẳng định `condeferrable`: có một test hoán vị hai
  deck thật trong một transaction, vì kiểm cờ không phải là kiểm hành vi.
- **Hai luật ArchUnit kéo từ Task 15 lên Task 1** — thêm sau khi tag/trash đã viết
  xong thì chỉ báo cáo được cái đã có.

**Bốn thứ chỉ lộ ra khi tiêm lỗi, không lộ ra khi đọc:**

1. **`sqlLivesOnlyInMapperXml` trong plan là luật xanh giả.** Nó kiểm
   `beAnnotatedWith` trên **class**, mà MyBatis đặt `@Select` trên **method** — nó
   không bao giờ nổ được. Đổi sang `noMethods()`.
2. **"Chỉ service gọi service" không phát biểu được.**
   `DeckService.prepareCardCreation` trả `DeckSchedulerState`, nên `CardService` **tất
   yếu** phụ thuộc `deck.entity` và `deck.enums`. Bề mặt công bố là service + entity +
   enums + exception, và chỉ với tới được **từ** `..service..`.
3. **Lần tiêm lỗi V5 đầu tiên vô hiệu** — gỡ file khỏi `src` nhưng bản copy trong
   `target/classes` vẫn còn, Flyway vẫn báo "applied 5 migrations". Cùng loại với vụ
   `jacoco:check` của Wave 1: xanh vì phép đo sai, không phải vì code đúng.
4. **Ngưỡng JaCoCo đỏ ở đúng lần đầu tiên nó có cơ hội.** Audit đã hỏi thẳng: 0.92 là
   sàn hay là bẫy sẽ bị hạ ngay lần đầu đỏ. Nó tụt còn 0.91 vì nhánh
   `CallableStatement` tôi viết mà chưa test — hụt đúng **6 instruction**. Viết test,
   không hạ ngưỡng. Đó là câu trả lời: nó là sàn.

**Quyết định mà plan còn thiếu:** trần **500 id** cho mọi thao tác `IN`-list (bulk
move/flag/delete, restore). Vượt thì trả `VALIDATION_FAILED` chứ không cắt bớt — client
mất dòng mà không biết thì tệ hơn là bị từ chối.

**Còn nợ có chủ đích:** `IdCollections` (chưa có caller — dựng ở Task 9 cùng trần
trên) và trường `search` của hợp đồng phân trang (chưa câu SQL nào tìm kiếm).

**Ngoại lệ SpotBugs đầu tiên của module**, `config/spotbugs/exclude.xml`: một entry hẹp
đúng một class · một method · một pattern. `X extends RuntimeException` erase thành
`RuntimeException`, nên bytecode đọc ra `throw (RuntimeException)` dù thực tế luôn là
subclass do caller cấp. Giữ `threshold=Low, effort=Max` nguyên vẹn.

### M9.Phase2 · Port toàn bộ SQL thư viện từ Drift sang MyBatis

- **Status:** **done** — `./mvnw -o verify` xanh 303/303; `check_docs.py` xanh; PR #516…#525.
- **Goal:** `memox-api` trả lời được **mọi** câu hỏi mà màn hình thư viện của client
  hỏi database, bằng đúng những luật BR mà client đang thi hành — không phải bằng một
  bộ luật thứ hai tình cờ giống.
- **Nguồn:** `docs/superpowers/plans/2026-09-09-memox-api-phase-2-library-writes.md`,
  chạy 15 task một vòng lặp. Bản đồ kết quả:
  `docs/superpowers/specs/2026-09-09-drift-to-mybatis-parity.md`.

| Task | Nội dung | PR |
|---|---|---|
| 1–2 | Hạ tầng, `V5`, deck reads đầu tiên | #512…#516 |
| 3–4 | Deck level view, ancestry, các probe cây | #518 |
| 5–6 | Deck reorder và move | #519 |
| 7–9 | Card list, detail, history keyset, edit, batch | #520 |
| 10 | Tag catalog, rename-merge, delete, gắn tag | #521 |
| 11 | Export deck và probe trùng lặp khi import | #522 |
| — | SQL toàn module chuyển sang comma-first | #523 |
| 12–14 | Trash: soft-delete, list/restore, purge theo retention | #525 |
| 15 | Tài liệu parity, contract test, WBS | (PR này) |

**Số liệu:** 69 câu Drift trong bốn file `deck/card/tag/trash.drift` → 77 câu MyBatis
(chênh vì Drift ghi qua companion sinh sẵn, còn API phải viết insert/update ra tay).
59 câu port thẳng, 10 câu **cố ý không port** — mỗi câu một dòng lý do trong tài liệu
parity — và 10 phân kỳ có chủ đích.

**Điều đáng nhớ nhất của cả phase: thiết kế nằm trong comment phía trên câu SQL, không
nằm trong SQL.** Ba phát hiện nặng nhất đều chỉ nhìn thấy ở đó, và **không cái nào làm
đỏ một test nào**:

1. `rootDeckSummaries.nextDueAt` là sub-select **không tương quan** một cách cố ý —
   comment gọi nó là đồng hồ đo lại của màn danh sách. Tôi "sửa" nó, ship ở #516, và
   revert ở #517. Ghi vào tài liệu parity như một phân kỳ *đã thử và đã sai*, để lần
   sau không ai suy ra lại từ SQL.
2. **SQLite sắp NULL trước khi ASC, PostgreSQL sắp sau.** Plan viết
   `DUE_ASC(… NULLS LAST)` — đúng ngược. Thẻ mới (`due_at IS NULL`) là thẻ *đến hạn
   ngay*, nên sẽ bị đẩy xuống cuối một danh sách sinh ra để đưa chúng lên đầu. Thành
   dòng dịch thứ 13 và thành `NullOrder` trên *trường* sort.
3. **BR-177 bắt tag của mỗi card sắp theo tên đã fold**, plan sắp theo cách viết. Cùng
   một deck sẽ export ra hai artifact khác nhau trên hai nền tảng — đúng thứ BR-177 tồn
   tại để chặn. SQLite không tôn trọng `ORDER BY` trong aggregate nên Dart phải sort
   lại ở tầng repository; PostgreSQL thì tôn trọng, nên luật về đúng chỗ của nó.

**Bốn MUST mà plan không thi hành:**

- **BR-256** — xoá nhiều item phải tạo **một batch cho mỗi item root**, không gộp
  chung. Plan trả một batch cho cả lô. Xoá 50 thẻ giờ là 50 batch chung một
  `deleted_at`.
- **BR-261** — restore phải thoả **đúng** bộ luật move và *"MUST NOT có bộ luật thứ hai
  dành riêng cho restore"*. Plan đề xuất kiểm lại luật độ sâu ở chỗ thứ hai. Restore
  giờ xoá tombstone rồi **gọi thẳng move**: luật được *chạy*, không được chép lại.
- **BR-262** — restore một deck phải viết lại `root_deck_id` cho **toàn bộ** subtree kể
  cả tombstone bên trong. Plan không nhắc.
- **BR-174** — ba mệnh đề của scope export (all-or-nothing, id trùng về một, scope rỗng
  bị từ chối ở repository) không có mệnh đề nào được thi hành.

**Phép đo thay cho phỏng đoán:** plan đề xuất `V6` thêm hai partial index và tự yêu cầu
đo `EXPLAIN (ANALYZE, BUFFERS)` ở quy mô thật trước. Đo trên 10 000 deck fan-out 100,
100 000 card, 10% tombstone: **cả hai truy vấn đã đi index từ trước**, sau vẫn cùng loại
node và cùng số buffer. Bỏ migration. Lần đo đầu của tôi sai vì cho 10 000 deck chung
một cha — seed phẳng thì đo cái seed.

**Guard kiếm cơm:** ArchUnit ép `SchedulerType` về `common.scheduler` (Task 7) và
`DeckAncestor` về `common.tree` (Task 13), chặn `CardBulkService` ghi thẳng
`decks.content_type`, và bắt response DTO của trash mượn DTO của deck. JaCoCo đỏ hai lần
và **không lần nào bị hạ ngưỡng**.

**Nợ có chủ đích, đã ghi trong tài liệu parity §7:**

- **BR-259 — đóng session khi xoá.** Soft-delete MUST đóng phiên đang chạy *trong cùng
  transaction*. `trash.drift` nói rõ write đó thuộc `study.drift` vì cặp
  `status × end_reason` là bất biến của module study. API chưa có module study, nên
  đường xoá **thiếu đúng một write**. Slice study phải thêm vào *trong* transaction của
  `TrashDeleteService`, không phải bên cạnh.
- **BR-266 — purge do người dùng chọn.** Chỉ mới có vòng quét retention.
  `countPurgeBlockers` giữ tập allowed là **tham số** để caller thứ hai không phải đổi
  câu SQL.

**Việc phía Flutter và hai nghĩa vụ còn nợ:** đã làm hết trong **M9.Phase2b** ngay dưới.

### M9.Phase2b · Bốn điểm tồn đọng của Phase 2

- **Status:** **done** — `./mvnw -o verify` xanh 317/317; `flutter analyze` 467 issues (đúng
  bằng baseline, không thêm lint nào); `flutter test test/features/card/` xanh 893/893;
  `check_docs.py` xanh.
- **Goal:** Đóng bốn điểm mà M9.Phase2 để lại — hai nghĩa vụ phía server và hai việc phía
  client — thay vì để chúng nằm trong sổ nợ.

**1. BR-259 — đóng session khi xoá (server, xong).** Đường soft-delete ship ở Phase 2 mà
thiếu đúng một write. `trash.drift` nói rõ vì sao write đó không thuộc Trash: cặp
`status × end_reason` là bất biến của module study. Nên `com.memox.study` giờ tồn tại như
**đúng lát cắt đó** — hai lookup, một update, hai enum — và `TrashDeleteService` gọi một
verb. Verb sở hữu cả hai cột, nên một cặp sai là **không viết được**, chứ không phải
"không nên viết": schema Postgres không hề ràng buộc tính hợp lệ của cặp, vì hai CHECK là
hai danh sách độc lập.

Ba điều chịu lực, mỗi điều một test: **hai lookup chứ không một** (phiên ôn cả root có
`deck_id` là root, root không nằm trong batch — chỉ hàng đợi nối nó với sub-deck bị xoá);
**chạy trước khi đánh dấu** (id phải còn mô tả hàng sống); và **chỉ `in_progress`** (phiên
đã kết thúc giữ nguyên cách nó kết thúc — BR-86).

**2. BR-266 — purge do người dùng chọn (server, xong).** `POST /api/v1/trash/purge`. Cùng
một tín hiệu blocker mang hai nghĩa trái ngược: vòng quét **bỏ qua**, cái này **từ chối**,
và từ chối nguyên khối — người dùng đã xác nhận một con số chính xác trước khi gọi. Kiểm
tra tồn tại chạy trước và tách riêng; tập allowed đúng bằng những gì được nêu tên, không
phải "mọi thứ quá hạn".

**Một bổ sung, không phải port:** BR-266 cấm trộn card và deck, và cột *Enforced by* của
nó ghi `UI`. App Flutter giữ luật đó ở selection state; repository của nó không kiểm, vì
không gì tới được đó với danh sách trộn. Client HTTP thì không có selection state, nên ở
biên này luật **không được thi hành** trừ khi endpoint thi hành. Hệ quả đã ghi thành test:
một batch **deck** mà bên trong còn batch **card** cũ hơn thì **không thể purge bằng tay** —
chọn cả hai là trộn loại. Nó chờ retention. Client Flutter cũng bí đúng như vậy.

**3. `tagCatalog` join `cards` (client, xong).** BR-237. `readsFrom` đổi từ
`{tags, cardTags}` thành `{tags, cardTags, cards}` — bắt buộc, vì nếu không catalog sẽ
**đứng im đúng lúc một thẻ vào Trash**, tức đúng ca mà bản sửa nhắm tới. Hai test mới, và
**đã tiêm lỗi**: bỏ `cards` khỏi `readsFrom` thì test stream đỏ (`Expected: <1>, Actual:
<2>`) trong khi test đếm vẫn xanh — nên chỉ một trong hai là guard thật.

Golden không bị ảnh hưởng: mọi widget test của catalog đi qua
`tagCatalogRepositoryProvider.overrideWithValue`, không chạm database.

**4. `orphanedTags` (client, xong).** Comment cũ chỉ nói "nothing calls it yet" — một mô tả
hiện trạng, không phải lệnh cấm. Giờ nó nói rõ **không được nối vào job dọn dẹp** và vì sao
(BR-230). Không sửa `docs/business-rules.md` — file đó frozen for MVP.

**Một việc nữa, do vòng phản biện tìm ra và đã làm luôn (3 agent, 1 finding sống / 2 bị bác):**

**Xác nhận xoá tag giờ nói hụt số thẻ.** BR-235 buộc xác nhận *"nêu rõ số thẻ sẽ bị gỡ tag"*, và
`tag_delete_confirm_widget.dart:57-59` lấy con số đó từ `TagCatalogEntry.cardCount`. Xoá tag gỡ
**mọi** hàng `card_tags` — BR-235 nói vậy, và `ON DELETE CASCADE` cũng làm vậy dù có
`unlinkAllCardsFromTag` hay không — nên thẻ trong Trash cũng mất link mà không còn nằm trong con số.

**Không trạng thái nào của code thoả cả hai rule.** Trước đây đếm mọi link: BR-235 đúng, BR-230 sai.
Bây giờ đếm thẻ active: BR-230 đúng, BR-235 nói hụt. Việc gộp một con số cho hai mục đích đã có từ
trước; thay đổi này chỉ dời phía đang sai — sang phía mà một MUST về catalog nêu đích danh.

**Đã giải bằng hai con số cho hai mục đích** (chủ dự án chốt): `tagCatalog` thêm aggregate
`linkedCardCount` đếm mọi hàng `card_tags`; `TagCatalogEntry` mang cả hai; dialog xoá đọc con số mới.
Hai số **được phép lệch nhau**, và đó mới đúng: một tag chỉ còn thẻ trong Trash hiện `0` ở danh sách
và "1 thẻ" ở dialog — nó không phải tag không còn thẻ nào, nên nhánh "unused" cũng chuyển sang
`linkedCardCount`. Server giữ một số: `TagCatalogResponse` chưa có client nào vẽ dialog xác nhận, và
thêm field không ai đọc đúng là thứ port này đã từ chối suốt.

43 call site được vá **theo vị trí analyzer chỉ**, không theo grep — lần đầu tôi dùng regex trên
`cardCount:` và nó đụng ~60 file vì đó là tên tham số dùng chung với deck/study/trash; đã revert sạch
và làm lại, `flutter analyze` trở về **đúng** 467 issues của baseline.

*Bị bác trong cùng vòng:* việc xoá tag làm mất link của thẻ trong Trash **không** phải defect và
không mới — BR-235 yêu cầu, FK cascade thực thi, và nó có từ trước trên cả hai nền tảng. Nó có mâu
thuẫn với BR-262 (*"tag MUST giữ nguyên"* khi restore), nhưng mâu thuẫn đó nằm trong **rule**, không
nằm trong implementation.

**Ba thứ bắt được trên đường đi:**

1. **BR-80 lỗi thời so với chính tài liệu của nó.** Nó nói `end_reason` MUST có **năm** giá
   trị, thiếu `content_deleted` và `scheduler_changed` — trong khi BR-259 (cùng file) *bắt
   buộc* dùng `content_deleted`, CHECK constraint cho **bảy**, và enum Dart định nghĩa bảy.
   Port nào lấy BR-80 làm miền giá trị sẽ **từ chối đúng giá trị BR-259 đòi**. Chỉ ghi lại,
   không sửa: business-rules.md frozen, sửa rule là một documents task.
2. **Postgres *làm tròn* phần dưới micro, `truncatedTo` *làm sàn*.** So một `Instant` trong
   bộ nhớ với `TIMESTAMPTZ` đã lưu lệch một micro giây tuỳ lúc — test flaky theo đúng nghĩa
   đen, và nó đã xanh một lần rồi mới đỏ. Giờ so hai giá trị **đã lưu** với nhau.
3. **`build_runner` không regenerate khi chỉ file sinh bị sửa.** Sau khi tiêm lỗi vào
   `app_database.g.dart`, lệnh build báo `5861 skipped` và giữ nguyên bản lỗi. Phải
   `build_runner clean` mới khôi phục. Cùng họ với bẫy `target/classes` cũ.

### M9.T1 · Mapper test có tier riêng: `@MybatisTest` và `@Sql`

- **Status:** **done** — `./mvnw -B -ntp verify` xanh **318/318**; hai fault injection đều đỏ
  đúng chỗ.
- **Goal:** Theo chỉ định của chủ dự án: test mapper phải chạy bằng `@MybatisTest` và nạp dữ
  liệu bằng `@Sql` của `org.springframework.test.context.jdbc`, thay vì `@SpringBootTest` +
  helper JdbcTemplate.
- **Nhánh / PR:** `claude/api-mapper-slice-tests`
- **Scope:** `pom.xml` (thêm `mybatis-spring-boot-starter-test`) ·
  `support/MapperSliceTest.java` (**mới**, annotation ghép) · `sql/deck/*.sql` (**mới**, ba
  fixture) · `deck/persistence/DeckMapperTest.java`. **Không** đụng `src/main`, không đụng
  `PostgresIntegrationTest` hay `MemoxFixtures` — 40 test class còn lại giữ nguyên tier cũ.
- **Out of scope:** `card_mapper.xml` và `tag_mapper.xml` chưa có mapper test nào; chúng được
  phủ gián tiếp qua tier `@SpringBootTest`. Dựng chúng là task khác.

**`DeckMapperTest` là test duy nhất của tầng này, và nó đang boot cả ứng dụng.** Nó hỏi hai
câu — statement trong `deck_mapper.xml` có sinh ra SQL hợp lệ không, và result map có bind
đúng cột vào đúng field không — nhưng nó thừa kế `PostgresIntegrationTest`, tức
`@SpringBootTest` + `@AutoConfigureMockMvc`: controller, service, MockMvc, toàn bộ. Mọi thứ
trên `persistence` là phông nền, và khi hỏng thì thông điệp lỗi gọi tên một tầng không liên
quan gì tới nguyên nhân — đúng cái đã xảy ra với lỗi `javaType="int"` mà M9.W1 ghi lại: nó
nổ ra thành HTTP 500 ở controller, ba tầng cách chỗ sai.

**`replace = NONE` là thuộc tính chịu lực, và đã tiêm lỗi để biết chắc.** `@MybatisTest`
mang sẵn `@AutoConfigureTestDatabase` với mặc định `Replace.ANY`, tức đổi `DataSource` sang
một embedded database. Cả lý do tồn tại của mapper test là SQL được chính engine của
production thực thi, nên mặc định đó phá đúng thứ cần giữ. Tiêm `Replace.ANY`: context chết
ngay, với *"Failed to replace DataSource with an embedded database for tests… or tune the
replace attribute of @AutoConfigureTestDatabase"*. Không có driver embedded trên classpath và
thông điệp gọi đúng tên thuộc tính — nên đây là lỗi **không thể mắc im lặng**. Ghi lại trong
javadoc theo đúng thông điệp thật, sau khi bản nháp đầu mô tả sai nó.

**Mỗi script `@Sql` mở đầu bằng hai lệnh `DELETE`, và đó không phải thừa.** Trên backend
`local`, tier này dùng chung một database với suite `@SpringBootTest`; mà suite đó truncate
**trước** mỗi test chứ không phải sau, nên dữ liệu của test cuối cùng nó chạy vẫn còn commit
khi mapper test bắt đầu. Trên `testcontainers` hai lệnh đó không khớp gì, vì slice có
container riêng. Chạy trên cả hai là thứ giữ hai backend là **cùng một lần chạy** — luật
`memox-api/README.md` đặt ra cho cặp này. Chúng là DML trong chính transaction của test, mà
`@MybatisTest` rollback transaction đó, nên không có gì của test khác bị mất thật.

Thứ tự `decks` trước `delete_batches` cũng có lý do: `decks.delete_batch_id` tham chiếu
`delete_batches` với `ON DELETE CASCADE`, nên xoá batch trước sẽ kéo deck đi cùng và lệnh thứ
hai chỉ đang mô tả một việc đã xảy ra rồi.

**Hai fault injection, cả hai đỏ đúng chỗ:**

| Tiêm | Kết quả |
|---|---|
| `Replace.NONE` → `Replace.ANY` | context không khởi động, `IllegalStateException` gọi tên thuộc tính |
| `scheduler_version` 1 → 2 trong fixture | `bindsEveryColumnOfTheResultMapToItsOwnField` đỏ: `expected: 1 but was: 2` |

Cái thứ hai là cái đáng giá: nó chứng minh `@Sql` thật sự nạp dữ liệu và assertion đọc chính
dữ liệu đó, chứ không phải xanh vì bảng rỗng hay vì rơi vào một giá trị mặc định.

**Lần tiêm đầu tiên không hợp lệ, và nó dạy một thứ về gate.** Bản đầu xoá luôn dòng
annotation; build đỏ, nhưng đỏ ở **Checkstyle** (`UnusedImports`) trước khi tới test. Tức
`includeTests=false` chỉ đúng cho PMD và SpotBugs — **Checkstyle có quét `src/test/`**. Một
"đỏ" đọc qua thì giống bằng chứng, mà thực ra chưa chạy tới test nào.

**Cái giá, đo được.** Tier mới là một context cache key thứ hai, nên trên backend
`testcontainers` nó boot container PostgreSQL của riêng nó — đếm được: chạy hai class, một
mỗi tier, ra **2** lần `Creating container for image: postgres:16-alpine`.

| | trước | sau |
|---|---:|---:|
| `DeckMapperTest` (class) | 0,218 s | 6,146 s |
| tổng thời gian test | 50,4 s | 53,8 s |
| `./mvnw verify` | 1 m 42 s | 1 m 36 s |

Con số đáng tin là **+3,4 s** thời gian test. Chênh lệch ở mức build nằm trong nhiễu giữa hai
lần chạy, nên không đọc nó là "nhanh hơn". Đổi lại: mapper test không còn dựng controller và
MockMvc để hỏi một câu về SQL, và `LocalPostgresConfiguration` đã lường trước context thứ hai
từ trước — cờ `ALREADY_CLEANED` của nó có mặt chính vì lý do này, nên backend `local` chỉ
migrate ở context thứ hai chứ không clean lại.

- **Dependencies:** M9.W1 (hai backend test và ngưỡng gate), M9.Phase2 (`deck_mapper.xml`)
- **Tests required:** `DeckMapperTest` (5), và toàn bộ `./mvnw verify`
- **Checklist phases:** không thuộc phase nào — đây là harness của module backend.

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
| Header của `MxProgressBar` tràn khi figure dài hơn nhãn | M100.72 | `_MxProgressHeader` cho nhãn trái `Expanded` còn figure phải **không flex, không ellipsis**. Đúng cho hero panel (`353 of 868 learned` cạnh `41%`: nửa dài ở bên trái, nó co lại và clip), sai cho mọi caller có figure dài: nhãn co về 0 rồi figure vẫn đòi phần của nó và tràn. Đo được ở 320dp textScaler 2.0 với caption của thẻ deck — figure cần 155.2 trong cột 160.2, cộng `sm` gap của chính primitive là tràn **3.0px**, tái hiện được chứ không phải suy đoán | Bọc `valueLabel` trong `Flexible` + ellipsis, hoặc bỏ leading gap khi không có nhãn. **Là task design-system, không phải task feature** — `MxProgressBar` là dòng 6 của `v1-freeze.md` §2, và §3 cấm task feature sửa rồi ghi chú lại. Điều kiện mở lại số 5 (defect production chứng minh được nằm trong hợp đồng đóng băng) là thứ biện minh cho task đó. M100.72 đi vòng ở tầng feature: `_DeckGauge` đo trước rồi mới vẽ, primitive không bị chạm |
| Chín trong mười bốn hợp đồng đóng băng của V1 chỉ được giữ bằng test | M100.41 | Guard quét `lib/features/` cho 5 dòng (mục 2, 4, 5, 12, 13); 9 dòng còn lại — role identity, ThemeData mapping, shared API, sàn 48dp, ripple/state, high contrast, depth của card, chrome của shell, golden Linux-only — chỉ có test giữ. Test là file trong repo, nên một nhánh feature nới nó ra là đi qua được, và **guard không đỏ khi chính nó bị sửa**. Hiện chỉ có văn bản (`v1-freeze.md` §3) cấm điều đó | Một cơ chế thay cho một câu văn: hoặc CODEOWNERS trên các file Enforcement của §2, hoặc một rule guard đọc diff và bắt PR nào vừa chạm `lib/features/` vừa nới một file canh gác. Chưa làm ở M100.41 vì nó là thay đổi tooling, không phải thay đổi tài liệu — và MUST được kiểm bằng tiêm lỗi trước khi tin |
| `StudySessionScreen` rời shell bằng `Navigator.push` chứ không bằng `GoRoute` | trước A8, đo ở A8 P2-15 (`docs/reviews/a8-navigation-chrome-audit.md` §10.5), đo lại ở C4 SC-C4-18 | Phiên học không có location: trong suốt lúc nó ở trên cùng, `GoRouterState.matchedLocation` vẫn đọc là `/study/<id>` hoặc `/decks/<id>/study`, nên không có gì deep-link hay restore vào một phiên đang chạy, và `GoRouterState` nói sai trong đúng khoảng thời gian dài nhất của app | **ACCEPTED, chờ quyết định của chủ dự án.** Phần *root navigator* đã có lý do và không phải nợ — nó là thứ giữ BR-82 một lối ra duy nhất (comment tại `study_entry_screen.dart` `_open`); chỉ **cơ chế** là còn mở. C4 cố ý chỉ mount `StudyOptionsScreen` (composition thuần: nó vốn đã render trong shell, chỉ thêm location) và **không** mount phiên học, vì bán kính nổ nằm ngoài tầm một task chrome: IT-NAV, đường resume khoá theo `sessionId` (BR-200, BR-103) và hợp đồng một-lối-ra của BR-82 đều chạm nó, và không cái nào verify được bằng host test. Khi mở lại: mount với `parentNavigatorKey: rootNavigatorKey` đúng như wizard import, `resumeSessionId`/`direction` đi bằng `extra`, và closure test là `currentConfiguration.uri` gọi tên route phiên |
| `CardEditorScreen` (edit) xếp chồng hai dải pinned ở đáy | trước C4, đo ở C4 SC-C4-04 | Route edit nằm trong `StatefulShellBranch` của Decks, nên `MxNavigationBar` bốn đích vẫn vẽ dưới nó; màn hình lại ghim action bar của chính nó vào `MxContentShell.footer` (`MxButtonPair` ≥48dp + `sm` + một dòng `bodySmall` + 2×`md`). **Đo, mount qua `createAppRouter`:** footer **96dp** + nav bar **80dp** = **176dp** chrome đáy. Không golden nào thấy được: `card_screens_demo_test.dart` pump thẳng `CardEditorScreen`, ngoài `createAppRouter` | **ACCEPTED — variance có chủ đích, không phải nợ nhánh route.** Edit là **page** được push lên card list và quay về đó (mũi tên back nói đúng điều đó), và nó push tiếp một branch route cho history của thẻ — đưa nó lên root navigator sẽ render Card Detail **dưới** editor. Wizard import thoát khỏi branch được vì nó là task không push branch route nào; đây không phải trường hợp đó. Đã ghi tại `app_router.dart` ngay trên `RouteNames.cardEditorEdit` để nó thôi là hệ quả tình cờ của việc lồng route. **Đính chính phép đo gốc:** SC-C4-04 viết edit là màn *duy nhất* xếp chồng hai dải — sai. Create cũng ghim footer từ SC-C1-02 và cũng nằm trong branch, nên nó xếp chồng y hệt; nửa mâu thuẫn thật sự là create, vì `✕` của nó tuyên bố một task trong khi thanh branch vẫn ở đó. Sửa nửa đó là SC-C4-19 (`parentNavigatorKey: rootNavigatorKey` cho `cardCreateRelative`), **không** nằm trong cụm C4 này | Khi 176dp chrome đáy được phán là không chấp nhận được trên thiết bị: lúc đó câu hỏi là "editor là page hay task" — một quyết định của chủ dự án, không phải một phép sửa composition. Hoặc khi SC-C4-19 được giao, vì nó chốt nửa create của cùng câu hỏi |
