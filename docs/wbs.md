# WBS — work breakdown and progress ledger

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì **đang** làm, bị chặn, hoặc đã descope. Việc đã đóng nằm ở `wbs-archive/` |
| **Scope** | Task đang mở · blocker · technical debt · quyết định descope/superseded. Ngoài phạm vi: entry đã `done` — chúng ở `wbs-archive/`, vẫn trong đồ thị dependency qua `_wbs_ledgers()` |
| **Source of truth for** | Trạng thái task · blocker · technical debt · quyết định descope |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M100.122 |
| **Last updated** | 2026-09-21 |

Single source of truth for project progress. Update it in the same commit as the
work it describes. A task is `done` only when it meets the Definition of Done in
`.claude/skills/flutter-workflow/references/definition-of-done.md`.

Status values: `todo` · `in-progress` · `blocked` · `done` · `descoped`

**Task ID là định danh vĩnh viễn và không được trùng**, cùng chính sách với BR /
AD / UC (xem `business-rules.md`).

## Progress summary

| | Sổ sống | Archive | Tổng |
|---|---|---|---|
| Entry | 13 | 322 | 335 |
| Dòng | 1.066 | 20.811 | 21.877 |

**Đang chạy: một task** — `M99.29`. Đếm lại ở `M100.98` vì bảng này đã lệch
(ghi 6 entry trong khi sổ sống có 13): **bảy entry `done` của memox-api (`M9.*`)
vẫn nằm ở sổ sống, chưa ai dời sang archive** — đó là nợ sổ sách, không phải
việc đang chạy. Năm entry còn lại mang trạng thái cuối (`descoped` ×3,
`integrated`, `superseded`) và ở lại vì chúng là quyết định người đọc cần thấy.

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
| `SC-C1-15` — ReminderSettingsScreen | **DESIGN_SYSTEM** (M100.42) · bỏ chặn 2026-09-17 | The two rows of one card have tap targets and ripples of different width. The toggle row's InkWell is 329dp wide, the time row's is 361dp - the full card - so a 16dp strip down each edge of … Sửa nó chạm hợp đồng đóng băng **#6** của `design-system/v1-freeze.md` §2, nên nó là một **task design-system** chứ không phải task feature | **Sẵn sàng làm.** V1 đã mở khoá (`v1-freeze.md` §3) — không còn chờ trigger nào; chỉ cần đứng riêng trong task design-system của nó |
| `SC-C1-16` — Reminder settings — time picker dialog | **DESIGN_SYSTEM** (M100.42) · bỏ chặn 2026-09-17 | The time picker sits 16dp in from each screen edge while every other dialog in the app sits 40dp in, so the app's one Material-owned modal is 48dp wider than its siblings on the same screen … Sửa nó chạm hợp đồng đóng băng **#6** của `design-system/v1-freeze.md` §2, nên nó là một **task design-system** chứ không phải task feature | **Sẵn sàng làm.** V1 đã mở khoá (`v1-freeze.md` §3) — không còn chờ trigger nào; chỉ cần đứng riêng trong task design-system của nó |
| `SC-C3-20` — RouteNotFoundScreen | **DESIGN_SYSTEM** (M100.42) · bỏ chặn 2026-09-17 | The route name is a second, invisible copy of the visible title, so a screen-reader user meets two nodes labelled "Page not found" one after the other — a container node spanning the whole p… Sửa nó chạm hợp đồng đóng băng **#6** của `design-system/v1-freeze.md` §2, nên nó là một **task design-system** chứ không phải task feature | **Sẵn sàng làm.** V1 đã mở khoá (`v1-freeze.md` §3) — không còn chờ trigger nào; chỉ cần đứng riêng trong task design-system của nó |
| `SC-C4-08` — ProgressScreen | **DESIGN_SYSTEM** (M100.42) · bỏ chặn 2026-09-17 | The pinned range strip never draws the chrome/content hairline, so deck rows scroll under it with no seam — the strip is painted in `scaffoldBackgroundColor` and the rows behind it are on th… Sửa nó chạm hợp đồng đóng băng **#11** của `design-system/v1-freeze.md` §2, nên nó là một **task design-system** chứ không phải task feature | **Sẵn sàng làm.** V1 đã mở khoá (`v1-freeze.md` §3). Vẫn là việc thật: `MxContentShell` phải học một khái niệm chrome mới |
| `SC-C9-03` — StudyHomeScreen | **DESIGN_SYSTEM** (M100.42) · bỏ chặn 2026-09-17 | Panel resume không nổi hơn các hàng dưới nó ở light — đo trên golden đã commit: ΔE(hero, nền) 2,73 so với ΔE(row, nền) 4,25, và row còn có hai lớp shadow trong khi hero không có lớp nào. `MxCard.tonal` là recipe mức-trang duy nhất còn ở `AppElevation.none`. Không composition nào trong `lib/features/` chạm tới được: `MxCard` không phơi elevation, shadow tự vẽ bị chính sách raw-Material cấm, và phép đổi sang `MxCard.accent` mà finding đề xuất lại tô cùng thứ giấy các hàng dùng — xóa sắc độ và làm dark tệ đi, nơi hero đang đúng (ΔE 19,23 so với 5,23 của row). Sửa nó chạm hợp đồng đóng băng **#10** của `design-system/v1-freeze.md` §2, nên nó là một **task design-system** chứ không phải task feature | **Sẵn sàng làm.** V1 đã mở khoá (`v1-freeze.md` §3). Vẫn nên đi cùng một lần chỉnh palette/theme có chủ đích, vì nó đo bằng ΔE |
| `SC-C9-14` — Reminder settings — time picker dialog footer | **DESIGN_SYSTEM** (M100.42) · bỏ chặn 2026-09-17 | The picker's footer offers Cancel and the commit action at identical emphasis, both drawn as zero-padding text links with no fill, no ripple and no hover surface — so the one modal in this f… Sửa nó chạm hợp đồng đóng băng **#3** của `design-system/v1-freeze.md` §2, nên nó là một **task design-system** chứ không phải task feature | **Sẵn sàng làm.** V1 đã mở khoá (`v1-freeze.md` §3) — không còn chờ trigger nào |

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

### M100.99 · V3 component pass, đợt 1 — Surfaces đọc đúng vai v3

- **Status:** **done** — analyze sạch, host suite 5251 pass, guard 0, architecture
  sạch, `check_docs` xanh, golden vẽ lại trên Linux.
- **Goal:** Mười một dòng nhóm Surfaces của `COMPONENT_MIGRATION_PENDING` thôi
  trỏ sai vai. Bảng đó do M100.98 lập ra và cố ý hoãn; đây là task component đầu
  tiên thu nó về.
- **Scope:** `mx_card.dart` (đổi chỗ `.surface` ↔ `.recessed`),
  `app_card_theme.dart` (`color` + viền dark), `app_elevation.dart`
  (rim `_darkDepth` → `border-ghost`), `app_theme.dart` (`canvasColor`),
  `app_bottom_sheet_theme.dart` (nền + grabber), `app_chip_theme.dart`
  (fill nghỉ), `app_button_themes.dart` + `app_input_theme.dart` (nền hai phép
  blend disabled), `guess_option_item_widget.dart`, `match_tile_widget.dart`;
  mười file test ghim giá trị cũ; bảng §7 của `theme-architecture.md`.
- **Out of scope:** mười lăm dòng còn lại của bảng — `NavigationBar`, FAB,
  `MxNavigationBar`, `FilterChip`, `Switch`, `OutlinedButton`, `IconButton`,
  `ProgressIndicator`, `TextField` — thuộc đợt Chrome và đợt Controls.
- **Dependencies:** M100.98 (bảng và cơ chế `AppDecorations.hairlineEdge`).
- **Tests required:** các test đã sửa ở Scope; không thêm file test.
- **Editable documents:** `docs/wbs.md`, `docs/design-system/theme-architecture.md`
- **Output:** `lib/core/theme/`, `lib/shared/widgets/mx_card.dart`,
  `lib/features/study/presentation/widgets/items/`
- **Acceptance criteria:**
  - [x] `_MxCardFill.surface` → `surfaceContainerLowest`, `.recessed` →
        `surfaceContainerLow`; light thôi đảo ngược — card nâng +2.09 L\* trên
        trang, `.recessed` −1.76 L\*.
  - [x] Viền dark của card và rim `_darkDepth` cùng đọc
        `AppDecorations.hairlineEdge` (`border-ghost`).
  - [x] `CardTheme.color`, `canvasColor`, `ChoiceChip` nghỉ, nền guess-option,
        nền match tile, nền hai blend disabled đều là `surfaceContainerLowest`.
  - [x] `BottomSheetThemeData.backgroundColor` là `surfaceContainerHigh`, grabber
        là `outlineVariant`.
  - [x] **Sàn 3:1 của grabber bị nới, có hồ sơ.** 1.30:1 sáng / 1.05:1 tối, ghim
        lại trong `component_depth_and_state_test.dart` như bản ghi trạng thái
        trung gian nêu tên thứ sẽ khôi phục sàn — không phải như một chuẩn.
  - [x] Hai phép đo trỏ sai rung được sửa chứ không nới: `app_theme_test` đo
        `surfaceContainerLowest` (rung card thật sự mặc) và composite rim trong
        suốt lên card trước khi lấy tỷ số.
  - [x] Bảng `COMPONENT_MIGRATION_PENDING` còn đúng mười lăm dòng, kèm số đo sẵn
        cho những dòng sẽ xuống dưới sàn.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`; gallery republish tại URL ghim.
- **Checklist phases:** 7, 12.

### M100.100 · V3 component pass, đợt 2 — Chrome đọc đúng vai v3

- **Status:** **done** — analyze sạch, host suite 5251 pass, guard 0, architecture
  sạch, `check_docs` xanh, golden vẽ lại trên Linux.
- **Goal:** Năm dòng nhóm Chrome của `COMPONENT_MIGRATION_PENDING` thôi trỏ sai
  vai; hai va chạm không tự quyết được thì báo chứ không tự bịa binding.
- **Scope:** `app_fab_theme.dart` (cặp màu + ba wash trạng thái),
  `app_navigation_bar_theme.dart` (indicator tint, icon và label đã chọn),
  `app_progress_theme.dart` (`linearTrackColor`), `mx_navigation_bar.dart`
  (viền trên); tám file test ghim giá trị cũ; bảng §7.
- **Out of scope:** nền `NavigationBar` → `chrome-glass` (**chặn** — cần
  `extendBody` + `BackdropFilter`, là quyết định bố cục); mười dòng Controls.
- **Dependencies:** M100.99.
- **Tests required:** các test đã sửa ở Scope, cộng hai pin mới trong
  `component_depth_and_state_test.dart`.
- **Editable documents:** `docs/wbs.md`, `docs/design-system/theme-architecture.md`
- **Output:** `lib/core/theme/components/`, `lib/shared/widgets/mx_navigation_bar.dart`
- **Acceptance criteria:**
  - [x] FAB là `primary`/`onPrimary`; thân nó rời **1.19:1** (light) và
        **1.64:1** (dark) so với trang lên **4.39** và **7.39**. Ba wash
        hover/focus/splash đi theo cặp mới.
  - [x] Indicator của `NavigationBar` là `primary` tint 14%/20%, composite tại
        chỗ vì AD-14 §1 cấm alpha lúc vẽ — và composite **ở ngay slot**, vì
        guard chỉ đọc role trong khai báo có tên slot.
  - [x] Icon và label đã chọn là `primary`. Glyph đạt **3.34 / 3.69** trên pill
        (đủ cho graphic); label **3.95 / 5.22** trên bar — light **dưới sàn 4.5**
        của chữ nhỏ, ghim floor 3.94 theo R12 như bản ghi trạng thái trung gian.
  - [x] `linearTrackColor` là `surfaceContainerHigh`; track đọc 3.74 / 4.43 so
        với `primary` fill.
  - [x] Viền trên `MxNavigationBar` là `border-ghost`.
  - [x] **Hai va chạm được báo, không tự quyết:** nền `chrome-glass` bị chặn bởi
        `extendBody`; `SegmentedButton` rời "house pair" vì v3 không nhắc tới nó.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`; gallery republish tại URL ghim.
- **Checklist phases:** 7, 12.

### M100.101 · V3 component pass, đợt 3 — Controls đọc đúng vai v3

- **Status:** **done** — analyze sạch, host suite 5256 pass, guard 0, architecture
  sạch, `check_docs` xanh, golden vẽ lại trên Linux.
- **Goal:** Sáu dòng nhóm Controls của `COMPONENT_MIGRATION_PENDING`. Bảng còn
  bốn dòng, mỗi dòng có lý do nêu tên chứ không phải "để sau".
- **Scope:** `app_toggle_themes.dart` (thumb lúc nghỉ), `app_button_themes.dart`
  (side của OutlinedButton), `app_icon_button_theme.dart` (glyph),
  `app_input_theme.dart` (fill hai trạng thái + viền hairline),
  `mx_action_button.dart` (`_busyStyle` đọc lại side của theme); tám file test;
  bảng §7.
- **Out of scope:** ba dòng `FilterChip` — app không render `FilterChip` nào, và
  `ChipThemeData` dùng chung nên thi hành chúng sẽ đổi `ChoiceChip`; theo luật R7
  của v3 chúng đáp xuống cùng caller đầu tiên. Nền `NavigationBar` vẫn chặn từ
  M100.100.
- **Dependencies:** M100.100.
- **Tests required:** các test đã sửa ở Scope, cộng group mới trong
  `control_border_grounds_test.dart` đo cạnh thật.
- **Editable documents:** `docs/wbs.md`, `docs/design-system/theme-architecture.md`
- **Output:** `lib/core/theme/components/`, `lib/shared/widgets/mx_action_button.dart`
- **Acceptance criteria:**
  - [x] `IconButton` glyph là `onSurface`: **7.20 → 16.72** light, **8.50 →
        15.59** dark.
  - [x] `OutlinedButton` side là `outlineVariant`; ghim theo nền yếu nhất
        (**1.30** light / **1.05** dark trên `surfaceContainerHigh`), không phải
        theo trang.
  - [x] `TextField` có fill hai trạng thái và viền `border-ghost` ở hairline;
        ghim **1.17 / 1.27**. Ghi rõ rằng **fill cũng không gánh ranh giới**:
        1.05:1 so với trang trong light.
  - [x] `Switch` thumb là `surfaceBright` (**1.32 / 1.36** trên track).
  - [x] **Nghịch đảo disabled/live được ghi lại ở cả hai theme**, không làm mờ
        đi: 2.30 vs 1.32 (light), 3.00 vs 1.36 (dark).
        `app_toggle_themes_test.dart` sẽ đỏ có chủ ý khi spec Switch đổi binding.
  - [x] **Một gate xanh giả bị bắt và sửa:** `control_border_grounds_test.dart`
        đo token `borderControl` chứ không đo cạnh mà button và field thật sự
        vẽ, nên nó xanh trong khi không còn đo gì. Thêm group đo cạnh thật.
  - [x] `_busyStyle` của `MxActionButton` thôi chép lại câu trả lời của theme —
        đọc lại `outlinedButtonTheme` resting side. Comment ở đó đã than rằng
        bản sao sai ba lần; lần này là lần thứ tư.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`; gallery republish tại URL ghim.
- **Checklist phases:** 7, 12.

### M100.112 · Button — v3: hai tone đổi màu, ba nấc kích thước mới

- **Status:** **in-progress** — code, test, golden Linux, full host suite và gallery
  đã xong (xem checklist); còn bộ integration trên thiết bị chưa chạy vì máy
  không có emulator Android.
- **Goal:** `MxActionButton` đọc đúng hợp đồng Button của v3 handoff: hai tone
  đổi cặp màu, ba nấc kích thước mới, và các nút study đổi sang pill.
- **Scope:**
  - `tonal` đọc `surfaceContainer` / `onSurface` (trước là `secondaryContainer`
    / `onSecondaryContainer`) qua `MxFilledPair.tonal`, kể cả `_busyStyle`.
  - `destructive` đọc `errorFill` / `onErrorFill` (`AppSemanticColors`) thay cho
    `error` / `onError`, kể cả `_busyStyle`.
  - `dense` bo góc 8.
  - Ba nấc mới của `MxActionButtonSize`: `small` (36), `chip` (28, pill viền
    ghost, bỏ qua `variant`) và `study` (48, pill). `AppSizing` thêm
    `controlSmall` và `controlChip`.
  - Nối `study` vào Reveal / Continue / Retry của Recall, Check của Fill và
    Reveal answer của self-assess. Cặp Forgot / Remembered và Show hint cố ý ở
    lại `standard`: handoff định nghĩa study action là một động từ đứng giữa, còn
    cặp kia là hai control ngang hàng trong `StudyCtaRowWidget`, nơi 2×36 padding
    sẽ ăn hết hàng ở 320dp.
- **Out of scope:** không `small` / `chip` nào có caller thật (handoff cố định
  hình học của chúng, màn hình chưa dựng nút); không đổi token dùng chung ngoài
  hai cặp màu ở trên; không đổi cặp Forgot / Remembered.
- **Dependencies:** M100.99–101 (theme role v3), `errorFill` / `onErrorFill` đã
  khai báo ở `v3-foundations.md`.
- **Tests required:** `test/shared/widgets/mx_action_button_*_test.dart` (size,
  study, chip, state matrix, composite state), `mx_tonal_and_outlined_test.dart`,
  `study_action_size_test.dart`,
  `study_card_face_test.dart`, `deck_workload_role_test.dart` (repin).
- **Editable documents:** `docs/wbs.md`,
  `docs/design-system/tokyo-component-mapping.md`,
  `docs/design-system/v3-foundations.md`, `docs/design-system/v1-freeze.md`
  (một dòng ghi chú lịch sử).
- **Output:** `lib/shared/widgets/mx_action_button.dart`,
  `lib/core/theme/components/actions/app_button_themes.dart`,
  `lib/core/theme/foundations/app_sizing.dart`, các nút study.
- **Acceptance criteria:**
  - [x] `tonal` và `destructive` đổi cặp màu ở cả trạng thái nghỉ lẫn `_busyStyle`
        (loading không còn đổi màu giữa chừng).
  - [x] Reveal answer của self-assess là `study`, khớp Reveal của Recall; hai nút
        chấm điểm sau khi lật vẫn `standard` (test ở `study_card_face_test.dart`).
  - [x] **Sàn pressed dưới AA được chấp nhận có chủ ý:** nhãn destructive ở dark
        và high-contrast dark đạt 4.28:1 (< 4.5) khi nhấn. Giá trị fill
        (`#B0485C`) và nhãn (trắng) do theme handoff cố định; chỉnh chúng là việc
        của bước theme, không phải của Button. Ghi vào `acceptedSubAAPressedFloors` (`mx_action_button_composite_state_test.dart`).
        Mở lại nếu chủ dự án muốn `onErrorFill` sáng hơn hoặc state layer khác.
  - [x] Golden vẽ lại trên Linux (WSL, clone riêng, `TZ=UTC`, `-j 1`): 41 PNG
        đổi — 39 ở `test/demo/goldens` (deck list/actions/overlay, recall, fill),
        `deck_list_rhythm.png` và `mx_confirm_dialog_destructive_dark.png`.
  - [x] Full non-golden host suite: `+5380: All tests passed!` (một lần, sau khi
        merge `origin/main`; cảnh báo tap của `trash_screen_test.dart` là nhiễu có
        sẵn).
  - [x] Gallery: ảnh 401f2460 — ghép 18 màn deck/study vào bản đang ghim (không
        đè cả trang), cùng URL.
  - [ ] Bộ integration trên thiết bị (`integration_test/`, baseline 9): chưa chạy —
        máy không có emulator Android; task này chạm `lib/features/study/`.
- **Màn hình đổi diện mạo:** nút Study trên hàng deck (pill tonal `surfaceContainer`),
  nút destructive của mọi confirm dialog (`errorFill`), các nút study của
  Recall / Fill / self-assess (pill 48).
- **Hai quyết định chủ dự án có thể muốn xem lại:**
  - Nhãn chip dùng `onSurfaceVariant`: handoff không có hàng label cho chip;
    `app_chip_theme.dart` đã ghép `onSurfaceVariant` với `surfaceContainerLowest`
    cho chip chưa chọn. Đổi thành `onSurface` nếu design muốn vậy.
  - Chip disabled = `Opacity` 0.38 phủ cả control (đọc nguyên văn "op-disabled
    over the whole control"), không dùng `disabledSurface` đặc như nút khác; nên
    chip disabled trông khác các nút disabled còn lại.
- **Nợ còn lại (minor hoãn từ review, chưa sửa):**
  - Chip: chưa có test tương phản bốn theme (gồm high-contrast: nhãn ≥ 4.5, vòng
    focus ≥ 3) và test semantics cho chip disabled có `semanticLabel`.
  - `mx_tonal_and_outlined_test.dart`: khẳng định disabled bằng
    `isNot(surfaceContainer)` quá yếu.
  - Test bo góc `dense` chỉ phủ `primary`; đường `merge` của tonal / destructive
    chưa được ghim.
  - Chưa có test giữ chiều rộng cho `study` + `isLoading`; test Check ở 320dp chỉ
    khẳng định không exception, chưa đo bố cục.
  - `_iconGap` đọc thang `labelLarge` cho `chip` / `dense` (nhãn thật là
    `labelMedium`); chênh không đáng kể.
  - Nhánh `secondary` của `_busyStyle` (không với tới được) vẫn mang
    `error` / `onError`.
  - Thứ tự import trong `mx_action_button_size_test.dart`.
  - `mx_action_button.dart` đã vượt 700 dòng; guard chưa cắt nhưng nên tách khi
    chạm lần sau.
- **Checklist phases:** 7, 12.

### M100.107 · Breadcrumb đọc dimension table v3 — chỉ ở dải scroll thường

- **Status:** **done** — analyze sạch, 449/449 test đích pass (gồm
  `breadcrumb_grammar_test.dart` không sửa), guard 0 violation.
- **Goal:** Áp bảng dimension Breadcrumb của v3 handoff (padding 2/16/8, gap 4,
  kiểu chữ 12/500 ancestor · 12/700 current, tracking 0.1, separator
  chevron-right màu `outline`) lên MỘT trong hai ngữ pháp của `MxBreadcrumb` —
  dải scroll từng-bước-tap-được (không `onUp`) — không đụng ngữ pháp header
  một-target mà mọi màn hình thật đang dùng.
- **Scope:** `mx_breadcrumb.dart`, `mx_breadcrumb_step.dart`,
  `mx_breadcrumb_test.dart` (2 assertion đổi theo giá trị mới),
  `icon_ink_boundary_test.dart` (thêm `allowedInKit` cho
  `mx_breadcrumb_step.dart`).
- **Out of scope:** ngữ pháp header (`onUp`, separator `/`, fold-into-ellipsis
  ở cả hai mode) — chủ dự án chọn "cosmetic only, keep grammar" qua
  AskUserQuestion khi phát hiện xung đột với `breadcrumb_grammar_test.dart`
  (owner review 2026-08-21). Không màn hình sản phẩm nào dùng dải scroll
  thường nên rủi ro rò rỉ sang ngữ pháp header bằng 0 — đã verify `_padding`/
  `_MxBreadcrumbSeparator` không được `_buildSingleTarget`/`_stepsThatFit`
  đọc, ở cả task review và final review.
- **Dependencies:** kế thừa theme roles `onSurface`/`onSurfaceVariant`/
  `outline` đã có sẵn từ M100.99–101; không cần thay đổi theme.
- **Tests required:** `mx_breadcrumb_test.dart`, `mx_breadcrumb_focus_test.dart`,
  `mx_stress_test.dart`, `breadcrumb_grammar_test.dart` (phải xanh KHÔNG sửa),
  `icon_ink_boundary_test.dart`, `deck_path_test.dart`,
  `card_editor_up_navigation_test.dart`, `card_import_up_navigation_test.dart`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_breadcrumb.dart`,
  `lib/shared/widgets/mx_breadcrumb_step.dart`.
- **Acceptance criteria:**
  - [x] padding 2 top · 16 sides · 8 bottom quanh dải scroll — hằng số cục bộ
        `_kBreadcrumbPadding` (không token mới; `2` không có bậc `AppSpacing`).
  - [x] gap 4 giữa segment và chevron — `AppSpacing.xs` đã sẵn = 4.
  - [x] segment ancestor 12/500 `onSurfaceVariant`; current 12/700
        `onSurface`, tracking 0.1 (hằng số cục bộ `_kSegmentTracking`) — đảo
        màu current so với comment cũ ("a breadcrumb is chrome"); comment đã
        viết lại lý do mới thay vì để mâu thuẫn với code.
  - [x] separator đổi từ `/` sang icon `chevron_right` màu `outline`, cỡ
        `AppIconSize.sm` — CHỈ ở dải scroll thường; dải header vẫn `/` vì lý
        do 2026-08-21 (hai chevron ngược hướng cạnh nút back) vẫn còn đúng,
        không liên quan v1-freeze mà redesign v3 thay thế.
  - [x] `context.colors.outline` không có thành viên `AppInk` — đọc trực
        tiếp trên `Icon`, thêm entry `allowedInKit` trong
        `icon_ink_boundary_test.dart` (tiền lệ: `mx_search_field.dart:173`).
  - [x] Không golden nào bị đụng — widget này chưa có golden nào.
  - [x] Task review + final whole-branch review: cả hai "Approved"/"Ready to
        merge: Yes", 0 Critical/Important; 2 Minor đã park (line-count trên
        raw `wc -l` nhưng guard dùng `count_mode: logical` và xanh; một câu
        giải thích trong report của implementer không chính xác 100% nhưng
        không phải lỗi code).
- **Checklist phases:** 7, 12.

### M100.105 · V3 component pass — BottomNav đọc đúng hợp đồng v3

- **Status:** **done** — analyze sạch, host suite xanh, golden vẽ lại trên Linux
  (47 PNG đổi), gallery republish tại URL ghim.
- **Goal:** `MxNavigationBar` thôi là dải opaque sát mép; nó là một thẻ kính nổi
  trong luồng, đúng hợp đồng BottomNav của v3.
- **Scope:** `mx_navigation_bar.dart` (wrapper 4/8/12 + inset cử chỉ, `ClipRRect`
  `AppRadius.lg`, `BackdropFilter` `glassBlurSigma`, fill `chrome-glass`, viền
  `border-ghost` cả bốn cạnh, `NavigationBar.height` cố định),
  `app_navigation_bar_theme.dart` (nền trong suốt, glyph 20dp),
  `app_sizing.dart` (`bottomBarHeight` 64), `app_navigation_shell.dart` (ba glyph
  theo nghĩa: `layers` / `play_circle` / `bar_chart`), hai file ghim role cũ.
- **Out of scope:** `extendBody` của shell — vẫn là quyết định bố cục của caller,
  đúng như M100.100 đã chặn: bật nó thì Scaffold thôi trừ chiều cao bar khỏi
  `MediaQuery` của body và mọi branch phải tự chừa chỗ. Hôm nay blur làm mờ nền
  phẳng của Scaffold, tức fallback "solid chrome-glass" mà hợp đồng cho phép.
  Icon rỗng của `_ProgressEmptyView` (`insights_outlined`) chưa đổi theo glyph
  Progress mới; đó là nội dung màn hình của feature.
- **Dependencies:** M100.101.
- **Tests required:** group `v3 glass geometry` trong `mx_navigation_bar_test.dart`;
  `m3_role_contract_test.dart` và `m3_role_bindings.dart` đã sửa.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/shared/widgets/mx_navigation_bar.dart`
- **Acceptance criteria:**
  - [x] Bar vẽ cố định 64dp bất kể inset; wrapper cao 4 + 64 + 12 = 80 và lớn thêm
        đúng bằng inset cử chỉ. `NavigationBar` bị bỏ `SafeArea` nội bộ bằng
        `MediaQuery.removePadding`, nên inset chỉ được tính một lần.
  - [x] `backgroundColor` của theme là trong suốt; hai guard từng ghim
        `surfaceContainer` được nới có chủ đích vì role đã chuyển sang
        `chrome-glass`, đọc trực tiếp bởi component.
  - [x] Focus ring và ripple giữ hành vi toàn cục/canonical, không thêm quy ước.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`; gallery republish tại URL ghim.
- **Checklist phases:** 7, 12.

### M100.102 · Fab — hộp 52×52, glyph 20 và vòng focus `onPrimary`

- **Status:** **done** — analyze sạch, host suite 5258 pass, guard 0, golden vẽ
  lại trên Linux.
- **Goal:** `MxFab` khớp hợp đồng Fab của v3: hộp vuông 52, glyph 20, và một
  vòng focus bàn phím (trước đó FAB không có vòng nào).
- **Scope:** `app_sizing.dart` (`AppSizing.fab`), `app_fab_theme.dart`
  (`sizeConstraints`, `iconSize`), `mx_focus_ring.dart` (tham số `color` tùy
  chọn), `mx_fab.dart` (bọc bằng `MxFocusRing`); `mx_fab_test.dart` mới và hai
  test theme/sizing mở rộng.
- **Out of scope:** màu, shape, elevation của FAB (đã đúng từ M100.100/M100.35);
  `AppSizing.floatingAction` và `AppSpacing.fabScrollClearance` — clearance
  thuộc caller (`ScreenScroll`), nên vẫn 56 dù hộp vẽ là 52, dư 4dp.
- **Dependencies:** M100.101.
- **Tests required:** các test ở Scope.
- **Editable documents:** `docs/wbs.md`
- **Output:** `lib/core/theme/`, `lib/shared/widgets/mx_fab.dart`,
  `lib/shared/widgets/mx_focus_ring.dart`
- **Acceptance criteria:**
  - [x] Hộp vẽ **52×52** thay vì 56 mặc định của SDK; glyph **20** thay vì 24.
  - [x] **Vòng focus dùng `onPrimary`, không phải `primary` như prose của spec.**
        Nền FAB đã là `primary`, nên vòng `primary` là 1.00:1 — vô hình; đây
        đúng là trường hợp `focusIndicatorOf` sinh ra để xử lý và nút filled đã
        theo. Không có offset 2: mọi chỗ dùng `MxFocusRing` vẽ sát hình, và một
        biến thể offset chỉ cho FAB là quy ước thứ hai.
  - [x] `MxFocusRing` tương thích ngược: năm caller cũ không truyền `color`.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`; gallery republish tại URL ghim.
- **Checklist phases:** 7, 12.

### M100.103 · SearchField đọc handoff v3 riêng của nó

- **Status:** **done** — analyze sạch, unit test xanh, golden vẽ lại trên Linux
  `TZ=UTC`, gallery republish tại URL ghim.
- **Checklist phases:** 14.3
- **Goal:** `MxSearchField` có spec component riêng (không nằm trong ba đợt
  M100.99–101, mà `app_input_theme.dart` đã ghi rõ "MxSearchField is its own
  composition and reads none of this — see its file"). Đưa hình học và màu của
  nó theo đúng handoff v3 mới: bo góc, chiều cao, fill/viền hai trạng thái, kích
  cỡ icon.
- **Scope:** `lib/shared/widgets/mx_search_field.dart`,
  `test/shared/widgets/mx_search_field_test.dart`.
- **Out of scope:** token dùng chung (`AppRadius`, `AppSpacing`,
  `AppIconSize`, `AppDecorations`) — component chỉ đọc, không sửa; caller nào
  render field (`library_search_screen.dart`, `card_list_screen.dart`,
  `tag_catalog_screen.dart`) không đổi API nên không chạm.
- **Dependencies:** M100.101 (đợt Controls đã đặt `border-ghost` +
  `AppStroke.hairline` làm khuôn cho cặp fill/viền hai trạng thái mà
  SearchField nối theo).
- **Tests required:** `mx_search_field_test.dart` (sửa tại chỗ), stress
  test (`mx_stress_test.dart`), test alignment của hai màn dùng field
  (`card_list_alignment_test.dart`, `tag_catalog_alignment_test.dart`), test
  route/state của màn tìm kiếm.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_search_field.dart`.
- **Acceptance criteria:**
  - [x] Bo góc đổi từ pill (999) sang `AppRadius.md` (12, `radius-input` theo
        bảng đổi tên của `v3-foundations.md` §3).
      - [x] Floor chiều cao đổi 48 → 52 (`--memox-size-input`). `_fieldInset`
        đổi theo (48 → 52 trừ line-height 20, chia đôi) và tình cờ rơi đúng
        `AppSpacing.lg` (16) — không phải quy tắc, chỉ là trùng hợp của hai
        con số mới. Cơ chế "floor không phải ceiling" (#433 F2) **giữ
        nguyên**: field vẫn lớn theo `textScaler`, chỉ giá trị nghỉ dời.
  - [x] Viền nghỉ đổi từ `scheme.outline` (đặc, M100.36 4E) sang `border-ghost`
        (`AppDecorations.hairlineEdge`, mờ) ở `AppStroke.hairline` (1, trước là
        `AppStroke.control` 1.5) — cùng đánh đổi độ tương phản chủ dự án đã
        chấp nhận cho `MxTextField` ở M100.101 (**1.19:1** đo lại khớp con số
        `app_input_theme.dart` đã ghim cho cùng `border-ghost` trên cùng trang).
  - [x] Fill nghỉ đổi sang đọc trực tiếp `colors.surfaceContainer` (cùng giá
        trị `semantic.surfaceMuted` cũ, chỉ đổi đường đọc theo đúng bảng
        `access: DIRECT` của spec); fill focus đổi từ `colors.surface` sang
        `colors.surfaceContainerLowest`.
  - [x] Icon glyph dẫn đầu đổi 16 (`MxIconSize.sm`) → 20 (`MxIconSize.mdCompact`
        — bảng icon `v3-foundations.md` §3 map "compact control" 20 vào đúng
        bậc này) và **đổi màu theo trạng thái lần đầu tiên**: `onSurfaceVariant`
        nghỉ → `AppInk.accent` (primary's hue, không phải raw `primary`, vì
        `icon_ink_boundary_test.dart` chỉ chấp nhận màu đi qua `AppInk`) khi
        focus.
  - [x] Vùng trailing giữ 12dp chỗ trống khi rỗng thay vì để field giãn hết —
        field không còn đổi chiều rộng nhìn thấy khi gõ ký tự đầu tiên.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`; gallery republish tại URL ghim.

### M100.108 · `MxAppBar`

- **Status:** **in progress** — widget, wiring, Widgetbook use cases and unit
  tests land in this task; goldens under `test/demo/` moved (compact title
  16/700/−0.3 replaces `titleLarge` 20/700/−0.64) and are regenerated on Linux
  `TZ=UTC` in a follow-up pass, not by this task.
- **Goal:** Close the `MxAppBar` row of `.claude/skills/flutter-theme-design/
  references/chrome-navigation.md`'s "Shared widget: `MxAppBar`" checklist —
  extract the bar `MxContentShell` built inline into its own leaf component.
- **Scope:** `lib/shared/widgets/mx_app_bar.dart` (new — two densities,
  `PreferredSizeWidget`, fixed 56dp); `mx_content_shell.dart`'s `_buildAppBar`
  wired to it for the no-`titleSubline` case; two new `AppTypography` title
  trios (`appBarContentTitle*`, `appBarScreenTitle*`) plus their `_role`-built
  styles; `widgetbook/lib/components/structure_components.dart`'s new
  `appBarComponent()`; `test/shared/widgets/mx_app_bar_test.dart`.
- **Out of scope:** `titleSubline` redesign (that branch of `_buildAppBar` is
  untouched), `MxSessionTopBar` convergence, a `selectionMode` enum, a
  `sizeAppBar` token, `dio`/network, auth.
- **Dependencies:** none — a leaf extraction of existing `MxContentShell`
  chrome.
- **Tests required:** `mx_app_bar_test.dart` (preferredSize, slot order,
  ellipsis under a narrow width, density padding/typography, no-actions full
  width); existing `mx_content_shell_bar_test.dart`,
  `mx_content_shell_chrome_test.dart`, `mx_content_shell_geometry_test.dart`
  pass unmodified — the regression proof that the hairline, back affordance
  and `automaticallyImplyLeading` did not move. `study_options_geometry_test`
  and trash `geometry_test` G2 were changed in the same commit, because the bar
  title now sits at the 8dp compact inset.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_app_bar.dart`,
  `lib/shared/widgets/mx_content_shell.dart`,
  `lib/core/theme/typography/app_typography.dart`,
  `widgetbook/lib/components/structure_components.dart`, `widgetbook/lib/main.dart`.
- **Acceptance criteria:**
  - [x] `MxAppBar` takes `Widget? title`, `Widget? leading`,
        `List<Widget>? actions`, `MxAppBarDensity density = compact`; paints no
        background of its own.
  - [x] Compact padding `AppSpacing.sm` (8), large `AppSpacing.lg` (16);
        compact title 16/w700/−0.3, large 24/w700/−0.5, both through
        `AppTypography`'s `_role`-shaped helper, not a `TextTheme` rung.
  - [x] Row: leading → `xs` gap → `Expanded(title)` → (if actions) `xs` gap +
        actions, each pair `xs` apart; no actions leaves the title the full
        width via `Expanded` alone.
  - [x] `preferredSize == Size.fromHeight(kToolbarHeight)` (56).
  - [x] `MxContentShell._buildAppBar` delegates to `MxAppBar` (via `AppBar`'s
        own `title:`/`leading:`/`actions:` slots) when `titleSubline == null`;
        `automaticallyImplyLeading`, the scrolled hairline `shape:` and the
        back-affordance check stay exactly where they were — proven by the
        three existing `mx_content_shell_*_test.dart` files passing unmodified.
  - [x] Widgetbook: `appBarComponent()` — Playground (density/leading/action
        count knobs) plus `compact, with back + actions`, `large, screen title
        only`, `no actions`.
  - [x] `mx_app_bar_test.dart`: 8 tests covering every acceptance point above.
  - [ ] Goldens under `test/demo/` regenerated on Linux `TZ=UTC` and the screen
        gallery republished at its pinned Artifact URL — deferred to the
        controller per this task's brief (Windows cannot author goldens).

- **Checklist phases:** 7, 12.

### M100.104 · MxOptionRow — hàng chọn một của v3 (#578)

- **Status:** **done** — merged (#578), CI xanh; chưa màn nào dùng.
- **Goal:** shared component cho hợp đồng OptionRow của v3: vòng radio 20dp dày
  lên 2px → 6px primary khi chọn (không có chấm), min-height 48, padding 12/16,
  divider `border-ghost`, dim `op-disabled` khi khoá.
- **Scope:** `lib/shared/widgets/mx_option_row.dart`, hai role `optionRowTitle` /
  `optionRowDescription` trong `AppTextStyles` (+ hằng số ở `AppTypography`),
  test riêng, specimen stress, entry Widgetbook.
- **Out of scope:** chuyển caller sang dùng nó (`study_direction_chooser_widget`,
  picker thuật toán, thứ tự thẻ mới, reset) — mỗi màn là một thay đổi riêng.
  Không sửa `MxRadioRows`: `RadioListTile` bị buộc vào `ListTileTheme` (56/4/16)
  và `Radio` M3 vẽ cố định 16dp chấm-trong-vòng, nên hợp đồng này không đạt được
  qua nó.
- **Dependencies:** M100.101.
- **Tests required:** `mx_option_row_test.dart`, `mx_stress_test.dart`, test theme
  typography.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_option_row.dart`.
- **Acceptance criteria:**
  - [x] Vòng 20dp, viền `AppStroke.selectionControl` (2) khi chưa chọn và 6 khi
        chọn, màu `outline` / `primary`; sáng và tối.
  - [x] Tap target qua `MxPressable` (sàn 48, vòng focus dùng chung).
  - [x] Title/description đi qua role có tên (guard `no_text_restyle` cấm
        `copyWith` tại chỗ) — tracking −0.1 và leading 1.45 là giá trị của kit.
- **Checklist phases:** 7, 12.

### M100.106 · TextField — dòng lỗi có glyph `alert-circle`

- **Status:** **done** — analyze sạch (chỉ còn lỗi của gói `widgetbook/` do chưa `pub get`), host suite xanh,
  guard sạch, sáu golden lỗi vẽ lại trên Linux `TZ=UTC`.
- **Goal:** Handoff v3 của TextField ghi dòng lỗi gồm glyph 16 + chữ, và registry
  (`docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md:340`) liệt
  kê "message text + glyph". Theme của field đã đúng v3 từ M100.101; chỗ hở còn
  lại là widget vẽ lỗi bằng `errorText` thuần chữ, không có chỗ cho icon.
- **Scope:** `lib/shared/widgets/mx_text_field.dart` (lỗi đi qua
  `InputDecoration.error` thay cho `errorText`), test hợp đồng và test
  editor-surface, sáu golden `mx_text_field_{error,focused_error,suffix_error}`.
- **Out of scope:** `app_input_theme.dart` và mọi token — không đụng. API công
  khai của `MxTextField` không đổi (`errorText` vẫn là `String?`).
- **Dependencies:** M100.101.
- **Tests required:** `mx_text_field_contract_test.dart`,
  `mx_editor_surface_test.dart`, `mx_text_field_counter_test.dart`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_text_field.dart`.
- **Acceptance criteria:**
  - [x] Glyph `Icons.error_outline` (một glyph duy nhất của app cho nghĩa này),
        `MxIconSize.sm` = 16, cách chữ `AppSpacing.xs` = 4, trang trí (không
        `semanticLabel`).
  - [x] Màu glyph là `AppInk.error` (→ `dangerInk`), khớp chữ bên cạnh — nối tiếp
        phán quyết GC-3 trong `app_input_theme.dart`, không dùng `scheme.error`
        (viền vẫn dùng `error`).
  - [x] **Đảo phán quyết của audit trước v3** (`docs/reviews/mx-text-field-deep-audit.md`
        ghi "không có error icon by design"): audit đó dựa trên baseline
        `filled: false` mà M100.101 đã đảo; handoff và registry v3 đều đòi glyph.
  - [x] Chiều cao dòng lỗi không đổi khi lỗi xuất hiện; test layout-stability cũ
        chạy nguyên bản.
  - [x] `errorMaxLines` không còn tác dụng với lỗi dạng widget; test ghim nó chuyển
        sang `Text.maxLines == 3` của chính dòng lỗi.
  - [x] Trường hợp text vượt `maxLength` + có lỗi **không** nổ assert
        "error và errorText cùng khai báo": `buildCounter` luôn được truyền nên SDK
        return sớm trước nhánh thêm `errorText`. Có test ghim; bỏ `buildCounter`
        thì test đỏ.
  - [x] Golden vẽ lại trên Linux `TZ=UTC`; chỉ sáu PNG lỗi đổi khi chạy 44 file test golden.
- **Checklist phases:** 7, 12.

### M100.109 · MxSection — nhóm hàng có overline, thẻ và ghi chú của v3

- **Status:** **done** — analyze sạch, `mx_section_test.dart` + `mx_stress_test.dart`
  + `widgetbook_coverage_test.dart` xanh; chưa màn nào dùng.
- **Goal:** shared component cho hợp đồng Section của v3: overline in hoa phía trên,
  một thẻ chứa nhóm hàng có hairline `border-ghost` giữa các hàng, ghi chú tuỳ chọn
  bên dưới, và khoảng 16dp cuối khối. Hai màn Settings và Reminder đang tự dựng lại
  đúng hình này trong từng feature.
- **Scope:** `lib/shared/widgets/mx_section.dart`, test riêng, specimen stress, entry
  Widgetbook (`sectionComponent`).
- **Out of scope:** chuyển `SettingsSectionWidget` / `ReminderSettingsSectionWidget`
  sang dùng nó — mỗi màn là một thay đổi riêng, giống M100.104. Không đụng token hay
  theme.
- **Dependencies:** M100.101.
- **Tests required:** `mx_section_test.dart`, `mx_stress_test.dart`,
  `widgetbook_coverage_test.dart`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_section.dart`.
- **Acceptance criteria:**
  - [x] Overline đi qua `MxSectionLabel` (rung `standard`, ink `quiet` = `text-secondary`),
        cách thẻ `AppSpacing.sm` = 8 — cùng giá trị `SettingsSectionWidget.headingGap`.
  - [x] Hàng nằm trong `MxCard.raised(padding: MxCardPadding.none)` — thẻ đã sở hữu
        fill `surface-raised` và clip theo bán kính, nên divider full-bleed gặp đúng
        góc bo; widget này không tự resolve lại role đó.
  - [x] Divider giữa hàng dùng `AppDecorations.hairlineEdge(...).color`
        (`border-ghost`), dày `AppStroke.hairline`; N hàng có đúng N−1 divider.
  - [x] Ghi chú cách thẻ 8, lề ngang `AppSpacing.xs` = 4; không đặt màu riêng vì
        hợp đồng không nêu role cho nó (giữ `bodySmall` như panel ghi chú của Reminder).
  - [x] 16dp cuối khối (`AppSpacing.lg`) do chính widget vẽ, có hay không có tiêu đề.
  - [x] `rows` rỗng bị assert (fail fast).
- **Checklist phases:** 7, 12.

### M100.113 · MxSwitch — công tắc trần, không nhãn, của v3

- **Status:** **done** — analyze sạch, `mx_switch_test.dart` + `mx_stress_test.dart`
  xanh; chưa màn nào dùng.
- **Goal:** shared component cho hợp đồng Toggle của v3 mà `MxSwitchRow` không phủ
  được: một công tắc **không có hàng và không có nhãn**, cho chỗ gọi tự ghép nhãn.
  `MxSwitchRow` bọc `SwitchListTile` của Flutter, và `SwitchThemeData` chỉ chỉnh được
  màu — track 44×26 và thumb 20 cố định không có chỗ để đặt — nên đây là widget tự vẽ.
- **Scope:** `lib/shared/widgets/mx_switch.dart`, `mx_switch_test.dart`, specimen
  stress, entry Widgetbook (`MxSwitch` trong `selectionRowsComponent`).
- **Out of scope:**
  - `app_toggle_themes.dart` vẫn resolve thumb **đang bật** của `Switch` stock thành
    `onPrimary`, còn registry v3 (`2026-09-18-memox-v3-theme-prerequisite.md`) và
    `MxSwitch` dùng `surfaceBright` ở cả hai trạng thái. **Không sửa ở đây**; đã báo
    lên để phân loại riêng.
  - Chưa chuyển `MxSwitchRow` sang render qua `MxSwitch` — đó là thay đổi riêng, và
    sẽ đóng mục "tap cả hàng" trong `flutter-theme-design/references/input-selection.md`.
  - Chưa có golden: golden chỉ author trên Linux, nên là việc sau.
  - Chưa kiểm vai (role) TalkBack trên thiết bị — chỉ kiểm cờ `toggled`/`enabled`
    và action `tap` qua semantics tree.
- **Dependencies:** M100.101.
- **Tests required:** `mx_switch_test.dart`, `mx_stress_test.dart`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_switch.dart`.
- **Acceptance criteria:**
  - [x] Track 44×26 `AppRadius.pill`, thumb 20 tròn, đi từ x=3 đến x=21; thumb
        `surfaceBright` ở cả hai trạng thái, đổ bóng `cardWhisperShadow`; track
        `surfaceContainerHighest` → `primary`. Không tham số màu nào cho chỗ gọi.
  - [x] Chiếm hộp 48×48 (`AppSizing.touchTarget`), track căn giữa và không bị nới;
        chạm bất kỳ đâu trong hộp đều bật/tắt.
  - [x] 160ms là hằng riêng của component (không rung nào của `AppDurations` bằng 160),
        curve `AppDurations.standard`; giảm chuyển động (`AppMotionPolicy`) thì thumb
        đến nơi ngay trong cùng frame.
  - [x] Vô hiệu (`onChanged == null`): `Opacity(AppStateOpacity.disabled)` phủ track +
        thumb, không tap/hover/focus, semantics `enabled: false` và không có action `tap`.
  - [x] Vòng focus là `MxFocusRing` với khe **đúng `AppStroke.focusRingOffset`**. Đo
        được lỗi: `MxFocusRing` vẽ viền 2dp **vào trong** hộp của child, nên padding 2dp
        quanh track bị viền ăn hết — khe đo được **0.0 ở cả bốn cạnh**. Sửa: padding
        `focusRingOffset + focus` = 4, hộp vòng 52×34 tràn ra ngoài hộp 48×48 (chỉ vẽ;
        layout và hit-test vẫn 48×48) — khe đo lại **2.0 ở cả bốn cạnh**.
  - [x] Space/Enter (`ActivateIntent`) bật/tắt như tap; wash tròn tâm thumb khi
        pressed/hovered từ `AppInteractionStates.controlOverlay`; RTL đảo chiều thumb.
  - [x] Semantics: `toggled`, `enabled`, `label` (`semanticLabel`), action `tap`.
- **Checklist phases:** 7, 12.

### M100.115 · SelectionCheckbox — ô chọn hàng đa lựa chọn của v3

- **Status:** done — full Definition-of-Done gate xanh.
- **Goal:** đưa hợp đồng v3 SelectionCheckbox vào shared component đang có
  (`MxCheckboxRow`) mà không thay đổi state hay business rule của caller.
- **Scope:** box sơn 20dp, bo 4dp, viền `outline` 2dp khi chưa chọn; khi chọn
  dùng `primary`, glyph check 14dp `onPrimary`, row là target tối thiểu 48dp,
  focus ring và disabled opacity theo token hiện hữu; migrate assertions của
  tag-filter khỏi implementation `CheckboxListTile` đã bị thay thế.
- **Out of scope:** selection count, bulk-action availability, caller offsets,
  và thay đổi state/domain của Card.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_checkbox_row.dart` và focused tests/catalogue.
- **Acceptance criteria:**
  - [x] API `MxCheckboxRow` giữ nguyên; không còn phụ thuộc box stock 18dp.
  - [x] Màu chỉ đọc từ `ColorScheme`; không thêm role/tokens cục bộ.
  - [x] Shared and Card consumer tests assert component semantics/state thay vì
        `CheckboxListTile` bị xoá.
  - [x] `dod_check.sh` xanh sau khi generated sources/l10n available.
- **Dependencies:** M100.101.
- **Tests required:** `mx_checkbox_row_test.dart`,
  `card_tag_filter_sheet_test.dart`, Widgetbook coverage.
- **Checklist phases:** 7, 12, 15.


### M100.110 · MxIconTile — ô vuông tô màu dẫn đầu một hàng, theo hợp đồng IconTile của v3

- **Status:** **done** — analyze sạch, `mx_icon_tile_test.dart` + `icon_ink_boundary_test.dart`
  + `mx_stress_test.dart` + `widgetbook_coverage_test.dart` xanh; chưa màn nào dùng.
- **Goal:** shared component cho IconTile: ba cỡ (hộp 28/36/44, bo 8/12/12, glyph 16/20/20),
  tint `primary` 10% sáng / 16% tối hoặc `seed` của caller 12%, glyph đậm đủ, và một ô
  `child` thay glyph.
- **Scope:** `lib/shared/widgets/mx_icon_tile.dart`, test riêng, specimen stress, entry
  Widgetbook (`iconTileComponent`), một dòng trong `allowedInKit` của `icon_ink_boundary_test`.
- **Out of scope:** chuyển `DeckIconArea`, ListRow, SettingsRow sang dùng nó — mỗi nơi là
  một thay đổi riêng. Không đụng token hay theme.
- **Dependencies:** M100.101.
- **Tests required:** `mx_icon_tile_test.dart`, `icon_ink_boundary_test.dart`,
  `mx_stress_test.dart`, `widgetbook_coverage_test.dart`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_icon_tile.dart`.
- **Acceptance criteria:**
  - [x] Nền ô là `Color.alphaBlend(tint, scheme.surface)` — không để màu trong suốt trên
        `decoration.color` (rule R7); `surface` là nền được chọn một lần.
  - [x] Glyph đọc thẳng `scheme.primary` hoặc `seed`, không qua `AppInk` (`AppInk.accent`
        là `accentInk`, khác `primary`); file được khai trong `allowedInKit` kèm lý do.
  - [x] Đúng một trong `icon` / `child` (assert); `child` không bị ép màu.
  - [x] Ô cố định `SizedBox.square`, không co — cột chữ bên cạnh nhường chỗ.
- **Checklist phases:** 7, 12.

### M100.111 · MxListRow — hàng nội dung một dòng của v3 (deck, kết quả tìm, tag, thẻ)

- **Status:** **done** — analyze sạch, `mx_list_row_test.dart` + `mx_stress_test.dart` +
  `widgetbook_coverage_test.dart` + `test/core/theme/` xanh; chưa màn nào dùng.
- **Goal:** shared component `MxListRow`, **không** phải `MxListTile` (hàng điều hướng/cài đặt):
  tiêu đề và phụ đề mỗi cái đúng một dòng ellipsis nên mọi hàng trong list cao bằng nhau.
  Lưới leading / 1fr / trailing, gap 12, padding 12×16, cao tối thiểu 48, divider hairline
  `border-ghost` (`showDivider`), leading mặc định là `MxIconTile` cỡ `sm` (chuyển `seed`
  nguyên vẹn), trailing glyph tô `onSurfaceVariant`.
- **Scope:** `lib/shared/widgets/mx_list_row.dart`, test riêng, specimen stress, entry
  Widgetbook (`listRowComponent`), vai chữ `AppTextStyles.listRowTitle` (14/600, tracking
  -0.1, leading 1.35 — hai hằng đặt tên ở `AppTypography`).
- **Out of scope:** chuyển deck/card/tag/search row hiện có sang dùng nó; `SettingsRow`;
  golden của component (không test nào bắt buộc, và golden chỉ tác giả được trên Linux).
- **Dependencies:** M100.110.
- **Tests required:** `mx_list_row_test.dart`, `mx_stress_test.dart`,
  `widgetbook_coverage_test.dart`, `test/core/theme/`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_list_row.dart`.
- **Acceptance criteria:**
  - [x] `onTap == null` là nội dung thuần (không `InkWell`, không semantics button); có `onTap`
        thì `MxFocusRing` + `InkWell` với `AppInteractionStates.rowOverlay` và `Semantics(button)`.
  - [x] Cao tối thiểu 48 đặt **ngoài** padding; tiêu đề và phụ đề `maxLines: 1`, chỉ cột chữ
        nhường chỗ cho leading/trailing.
  - [x] Trọng lượng 600 của tiêu đề đi qua `AppTypography.withWeight` (font biến thiên: `fontWeight`
        trần không đổi gì trên máy).
  - [x] Không thêm assert loại trừ `leading`/`leadingIcon` — dartdoc ghi icon bị bỏ qua khi
        widget được truyền.
- **Checklist phases:** 7, 12.

### M100.114 · IconButton (plain) đọc đúng hình học v3 — 36 vẽ, 48 chạm, bo tròn, glyph 20

- **Status:** **done** — analyze, host suite 5290/5290 và guard xanh; golden vẽ lại
  trên Linux `TZ=UTC` (WSL, 44 file, 100 PNG đổi, không thêm/xoá).
- **Goal:** Style plain của `IconButton` (`buildIconButtonTheme`) đổi từ vẽ trọn
  ô 48×48 squircle `AppRadius.md`, glyph 24 sang đúng hợp đồng handoff kit
  MemoX v3 (Actions & controls, 2026-09-18): một hình tròn sơn 36×36, đặt giữa
  vùng chạm tối thiểu 48×48 không đổi (không bao giờ phóng to hình tròn để lấp
  đầy vùng chạm), glyph cố định 20 (`AppIconSize.mdCompact`) bất kể `isCompact`.
  Màu đã đúng từ M100.101 — task này chỉ đổi hình học.
- **Scope:** `app_sizing.dart` (hằng số mới `AppSizing.iconButtonInk = 36`,
  công dụng riêng cho ô sơn của style plain, không dùng chung với
  `controlCompact` = 40 của style outlined), `app_icon_button_theme.dart`
  (`buildIconButtonTheme`: `minimumSize` đổi sang `iconButtonInk`, thêm
  `tapTargetSize: MaterialTapTargetSize.padded`, `shape` đổi
  `AppRadius.md` → `AppRadius.pill`), `mx_icon_button.dart` (glyph luôn
  `AppIconSize.mdCompact`, bỏ nhánh `isCompact ? mdCompact : md`).
- **Out of scope:** style outlined (`buildOutlinedIconButtonStyle`, hợp đồng
  "40 vẽ, 48 chạm" của nó) — không đổi. `isCompact` vẫn giữ, chỉ còn tác dụng
  siết `BoxConstraints.tightFor(48,48)` cho `MxSessionTopBar`, không còn đổi
  glyph. Không đụng màu, overlay, focus ring, disabled — tất cả đã đúng từ
  M100.101.
- **Dependencies:** M100.101 (màu đã xong). Gallery republish tại URL ghim theo
  kiểu **ghép**: 19 figure lấy từ nhánh này, 40 figure còn hình IconButton cũ vì
  bản live đang mang thay đổi chưa merge của nhánh Button/SearchField — chúng tự
  cập nhật khi nhánh đó republish.
- **Tests required:** `app_sizing_test.dart` (hằng số mới vào bảng lưới 4dp,
  assertion `iconButtonInk < touchTarget`, pin `iconButtonTheme.minimumSize`
  đổi từ `touchTarget` sang `iconButtonInk`); nhóm mới "the plain icon button"
  trong `mx_tonal_and_outlined_test.dart` đo ô vẽ 36, ô chạm ≥48, shape tròn
  (`RoundedRectangleBorder(AppRadius.pill)`), và glyph `mdCompact` kể cả khi
  không `isCompact`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/core/theme/foundations/app_sizing.dart`,
  `lib/core/theme/components/actions/app_icon_button_theme.dart`,
  `lib/shared/widgets/mx_icon_button.dart`.
- **Acceptance criteria:**
  - [x] `iconButtonTheme` (style plain) vẽ ô tròn 36×36, vùng chạm ≥48×48 —
        chứng minh bằng test đo widget đã render, không phải suy luận.
  - [x] Hợp đồng 40/48 của style outlined không đổi một byte.
  - [x] Glyph của `MxIconButton` (plain, không `isCompact`) là `mdCompact`
        (20); trường hợp `isCompact` cũng 20, ô vẫn đúng 48×48.
  - [x] Hằng số mới nằm trong bảng lưới 4dp và có assertion thứ tự so với
        `touchTarget`.
  - [x] Không đổi màu, overlay, focus ring, hay binding disabled.
  - [x] **Sáu test ghim hình học cũ được trỏ lại, không nới.** Bốn test đo vùng chạm 48dp
        qua `InkWell` nay đo `IconButton` (InkWell giờ là hình tròn sơn 36 theo thiết kế);
        ngưỡng 47.5 giữ nguyên. Hai test G2 của trash suy `residue` từ
        `touchTarget` và `mdCompact` thay vì gõ số.
  - [x] **Hệ quả ghi lại, không giấu:** glyph 20 trong hộp 48 chừa 14dp mỗi bên, nên
        glyph cuối hàng trash nằm **2dp** trong gutter thay vì đúng gutter (residue
        0 → 2). Căn chính xác cần padding ngoài 2dp — lệch lưới 4dp và dưới `AppSpacing.xs`.
        Các caller khác của `MxIconButton` dịch cùng 2dp nhưng chưa có test đo.
  - [x] `dart format`, `flutter analyze --no-fatal-infos`, full host suite
        (`--exclude-tags golden`), guard Python đều xanh.
- **Checklist phases:** 7, 12.


### M100.117 · Card — góc 20, padding 20 và recipe `hero` theo hợp đồng v3

- **Status:** **done** — analyze sạch, `mx_card_*` + `mx_section_test` +
  `mx_app_bar_test` xanh, golden vẽ lại trên Linux (44 file, 121 PNG; compare
  44/44 xanh và không ghi PNG nào).
- **Goal:** Hợp đồng Card của v3 cố định **radius 20** và **padding 20**, và có
  biến thể *tinted hero* (`surface-hero` + `border-ghost` ở cả hai theme). Hai token
  đã có sẵn nhưng không ai dùng: `AppRadius.xl` chỉ `.focal`/`.recessed` đọc, còn
  `AppSpacing.card` không có caller nào trong `lib/`; các recipe trang vẫn vẽ góc 16
  (thang trước v3) và `MxCardPadding.standard` vẫn đo 16. `AppDerivedColors.surfaceHero`
  cũng không có consumer.
- **Scope:** `mx_card.dart` (sáu recipe `.flat` `.raised` `.feedback` `.muted`
  `.tonal` `.accent` đổi `AppRadius.lg` → `xl`; `standard` đọc `AppSpacing.card`;
  recipe mới `.hero`), `app_card_theme.dart` (fallback cho `Card` trần đổi cùng),
  `app_radius.dart` (doc), `mx_card_recipes_test.dart`,
  `progress_deck_screen_visual_audit_test.dart`, Widgetbook Playground,
  `card-recipes.md`, 121 golden.
- **Out of scope:** `.tile` (góc `md`, hàng dày đặc) và `.option` (góc `lg`, dạng
  control) giữ nguyên — mỗi cái có lý do ghi ngay trong doc của recipe; padding
  `compact` (12) không nằm trong hợp đồng nên giữ; bottom sheet và dialog vẫn ở
  `lg` (thuộc component khác); chuyển caller sang `.hero` (deck summary dùng
  `.accent`, Study Home dùng `.tonal`) — mỗi màn là một thay đổi riêng, giống
  M100.104 và M100.109. Không đụng theme, token hay palette: **không có theme gap.**
- **Dependencies:** M100.99.
- **Tests required:** `mx_card_recipes_test.dart` (bảng radius, padding
  `standard` = 20, recipe `hero` ở bốn theme), `progress_deck_screen_visual_audit_test.dart`,
  goldens.
- **Editable documents:** `docs/wbs.md`, `docs/design-system/card-recipes.md`
- **Output:** `lib/shared/widgets/mx_card.dart`
- **Acceptance criteria:**
  - [x] Sáu recipe trang vẽ góc 20; `.focal`/`.recessed` vốn đã 20; `.tile` 12 và
        `.option` 16 giữ nguyên.
  - [x] `MxCardPadding.standard` = `AppSpacing.card` = 20 (`none` 0, `compact` 12).
  - [x] `.hero`: fill = `AppDerivedColors.surfaceHero(scheme)` đúng giá trị theme
        trả về (card không tự áp phần trăm), viền `border-ghost` ở light **và**
        dark, góc 20, độ sâu như `.raised`; test ở bốn theme.
  - [x] **Số đếm của visual audit đổi và đã được đo, không sửa cho qua:** face
        `library_mixed` của `progress_deck_screen` mất đúng một host `InkWell`.
        Ở viewport 420×1040, hai deck row trước đây nằm ở 763…924.9 và
        948.9…1074.5; sau khi ba thẻ section và row đầu cao thêm 8dp mỗi thẻ,
        chúng nằm ở 787…956.9 và row thứ hai (bấm được) bắt đầu ở ~981, quá đáy
        vùng cuộn nên sliver không build. `tappableCards` 1 → 0.
  - [x] Chưa màn nào dùng `.hero`; không golden nào phụ thuộc nó.
- **Ghi nhận:** `surface-hero` (`AppDerivedColors`) và `surfaceEmphasis` (`.tonal`)
  là hai giá trị khác nhau cùng được mô tả là "hero" ở hai chỗ trong theme;
  `.tonal` vẫn đọc `surfaceEmphasis`. Gộp hay không là quyết định khi migrate caller.
- **Checklist phases:** 7, 12.

### M100.116 · MxFilterChip — control một-trong-N 28dp, caller đầu tiên của `border-ghost`

- **Status:** **done** — code, test, Widgetbook, specimen và golden Linux `TZ=UTC`
  đã xong; CI `goldens (linux)` là người so pixel lần cuối.
- **Goal:** Ba dòng `FilterChip` của `COMPONENT_MIGRATION_PENDING` có caller mà
  không chạm `ChipThemeData` dùng chung, nên `ChoiceChip` và `MxPillButton`
  không đổi.
- **Scope:** `lib/shared/widgets/mx_filter_chip.dart` (`MxFilterChip`: 28dp cố
  định, count tuỳ chọn, tick thay glyph khi chọn); tái dùng `AppSizing.controlChip`
  (M100.112, cùng nấc chip 28), thêm `AppBorderColors.borderGhost*`, `AppSemanticColors.borderGhost` (khai báo cùng
  caller đầu tiên theo R7, và bản high-contrast của nó); entry Widgetbook;
  specimen golden `FilterChipGroupSpecimen` / `FilterChipStatesSpecimen`; bảng §7
  của `theme-architecture.md` và dòng R7 của `v3-foundations.md`.
- **Out of scope:** `ChipThemeData` và mọi component đang dùng nó; `MxPillButton`
  (không đụng, kể cả trích `_TapTarget` dùng chung — `MxFilterChip` chép nguyên
  văn và ghi rõ đó là ứng viên cho task trích riêng); nối chip vào màn hình nào.
- **Dependencies:** M100.101, M100.112 (`AppSizing.controlChip`).
- **Tests required:** `mx_filter_chip_test.dart`, specimen stress trong
  `mx_stress_selection_specimens.dart`, `high_contrast_figures_test.dart`,
  `widgetbook_coverage_test.dart`, hai golden mới.
- **Editable documents:** `docs/wbs.md`, `docs/design-system/theme-architecture.md`,
  `docs/design-system/v3-foundations.md`
- **Output:** `lib/shared/widgets/`, `lib/core/theme/foundations/`, `widgetbook/`,
  `test/shared/widgets/`
- **Acceptance criteria:**
  - [x] `MxFilterChip` cao 28dp, hộp chạm 48dp, vòng focus vẽ theo hình 28dp.
  - [x] Viền `border-ghost` đo **1.14 / 1.47** trên `surface` (số ghim bởi
        `high_contrast_figures_test.dart`, thay cho ước lượng 1.19 / 1.28 đã ghi
        trước đó); high-contrast đẩy nó lên **7.20 / 8.50** vì với chip chưa chọn
        đây là thứ duy nhất nhận diện control (WCAG 1.4.11).
  - [x] Đã đăng ký trong Widgetbook; `widgetbook_coverage_test.dart` xanh.
  - [x] Golden `mx_filter_chip_group_*` / `mx_filter_chip_states_*` vẽ trên
        Linux `TZ=UTC` (WSL), commit cùng PR; file `mx_components_golden_test`
        vẽ lại thì chỉ bốn PNG mới xuất hiện, golden cũ không đổi byte nào.
  - [x] Gate: analyze sạch, guard, architecture, `check_docs`, host suite
        (5490 pass trước đợt sửa cuối, 2004 pass trên vùng chạm sau đó).
- **Checklist phases:** 7, 12.

### M100.122 · MxSegmentedTray — exclusive selector dùng chung cho Settings và Progress

- **Status:** **done** — focused component, Settings, Progress và Widgetbook
  coverage xanh; golden Linux `TZ=UTC` của Settings/Progress đã regenerate và
  được kiểm tra trực quan.
- **Goal:** Thay radio/pill rời rạc bằng một segmented tray typed cho 2–3 lựa
  chọn loại trừ nhau.
- **Scope:** `MxSegmentedTray`, migration chọn 7/30 ngày ở Progress, theme và
  thứ tự thẻ mới ở Settings, Widgetbook và focused widget coverage.
- **Out of scope:** palette/theme foundation, `MxPillButton`, ngôn ngữ Settings
  ba lựa chọn, controller/domain/persistence và golden Windows.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_segmented_tray.dart` và các caller/catalog
  trực tiếp.
- **Acceptance criteria:**
  - [x] Tray typed chỉ nhận 2 hoặc 3 option, công bố selection exclusive, thumb
        32dp trong target 48dp và giữ geometry 4/2/12/32/8.
  - [x] Progress, Settings theme và thứ tự thẻ mới giữ nguyên state transition,
        failure/submitting behavior và localized labels.
  - [x] Widgetbook có knobs 2/3 option, selection, enabled, variant; focused
        non-golden verification xanh. Golden Settings/Progress đã regenerate
        trên Linux `TZ=UTC` và được review; verifier profile không có trên disk
        và một geometry assertion Progress ngoài scope đã đỏ.
- **Dependencies:** M100.118 (`MxTapTarget`), M100.119 (v3 shared controls).
- **Tests required:** `mx_segmented_tray_test.dart`, focused Settings/Progress
  presentation tests, Widgetbook coverage and non-golden suite.
- **Checklist phases:** 7, 12, 15.

### M100.120 · Observer nêu nguyên nhân khi provider fail (cause của `Failure`)

- **Status:** **done** — analyze sạch, `provider_observer_test.dart` +
  `test/core` xanh.
- **Goal:** một provider đọc DB fail phải cho thấy *vì sao* trong log, không chỉ
  "đã fail". Ranh giới repository bọc mọi lỗi persistence thành `Failure`, mà
  `toString()` của `Failure` là `Instance of 'UnknownFailure'`, nên một migration
  không chạy được (`duplicate column name: sibling_position` trên IndexedDB lệch
  schema) chỉ hiện ra là spinner rồi màn "Couldn't load your decks", không có
  dòng nào nêu tên lỗi.
- **Scope:** `describeFailureCause` trong `lib/core/error/drift_error_mapper.dart`
  (chỗ duy nhất được biết hình dạng exception của Drift/SQLite);
  `MemoxProviderObserver.providerDidFail` nối `(cause: …)` vào message khi lỗi là
  `Failure`.
- **Out of scope:** đổi `Failure`/`mapDatabaseError`; thêm `DatabaseFailure` cho
  lỗi migration; tự phát hiện và dọn DB web lệch schema.
- **Dependencies:** AD-08 (không log nội dung card ở bất kỳ mức nào).
- **Tests required:** `test/core/state/provider_observer_test.dart`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** 3 file mã nguồn/test trên.
- **Acceptance criteria:**
  - [x] Cause là `SqliteException` (kể cả bọc trong `DriftWrappedException`) →
        message ghi `SqliteException(<extended code>): <message>`.
  - [x] Không bao giờ ghi câu SQL hay tham số bind:
        `SqliteException.toString()` nối cả hai, và tham số có thể là nội dung
        card (AD-08). Test dùng chuỗi card giả làm tham số và khẳng định nó
        không xuất hiện.
  - [x] Cause khác `SqliteException` chỉ ghi tên kiểu, không ghi text của nó.
- **Checklist phases:** 12.

### M100.121 · MxStepper — bộ điều khiển số nguyên dùng chung của v3

- **Status:** **done** — PR #601 merged after the required remote CI gate
  passed: host tests, Linux goldens, Widgetbook, format/analyze/guards and
  tooling/docs.
- **Goal:** shared component cho Stepper v3: hai icon well 36dp quanh giá trị
  số nguyên, trong khi caller vẫn sở hữu bounds, clamp, validation message và
  ý nghĩa của số.
- **Scope:** `lib/shared/widgets/mx_stepper.dart`, test widget/stress/API closure
  và catalogue Widgetbook cho resting, invalid, busy, disabled và một action bị
  khoá tại bound.
- **Out of scope:** migrate Settings/Study options; min/max/clamping; message
  validation; theme/tokens; persistence hay state của caller.
- **Dependencies:** M100.113 (`MxSwitch`, pattern 48dp target quanh paint nhỏ);
  M100.118 (`MxTapTarget`, redirect hit target).
- **Tests required:** `test/shared/widgets/mx_stepper_test.dart`,
  `mx_stress_test.dart`, `shared_api_closure_test.dart`, Widgetbook coverage,
  full `.claude/skills/flutter-workflow/scripts/dod_check.sh`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `MxStepper` shared primitive plus catalogue and test coverage.
- **Acceptance criteria:**
  - [x] Painted minus/plus wells are 36dp, `radius-md`, `surfaceContainer`; each
        retains an Android 48dp target without inflating paint.
  - [x] Value column has 48dp minimum, tabular 16/700 ink, 1dp transparent/error
        ring with no invalid layout shift; busy keeps width and paints a primary
        spinner.
  - [x] Global disabled uses `op-disabled` once; caller-null callbacks alone
        determine an at-bound action's interaction.
  - [x] Widgetbook and stress suite cover both themes, narrow/text-scale layout,
        RTL, semantics and tap-target accessibility.
- **Checklist phases:** 7, 12, 13, 15.

### M100.119 · MxSettingsRow — hàng cài đặt của v3 (label 16/600, sub, control cuối hàng)

- **Status:** **done** — analyze sạch, `mx_settings_row_test.dart` +
  `mx_settings_row_contract_test.dart` + `mx_stress_test.dart` +
  `widgetbook_coverage_test.dart` xanh; chưa màn nào dùng.
- **Goal:** shared component `MxSettingsRow`, khác `MxListTile`
  (điều hướng/nhiều dòng của `ListTileThemeData`) và `MxListRow`
  (nội dung một dòng): lưới 40 lead / 1fr / auto trailing, gap 16, padding
  12×16, cao tối thiểu 48, leading là `MxIconTile` cỡ mặc định (`md` = 36),
  label 16/600 tracking -0.1, sub 12 `onSurfaceVariant` cách label 4, leading
  1.45, chevron `chevron-right` 20 chỉ khi hàng điều hướng và không có control,
  control cuối hàng (`trailing`, inline) hoặc control rộng (`wideControl`, xuống
  dòng riêng, cách 12 phía trên) — hai cái loại trừ nhau.
- **Scope:** `lib/shared/widgets/mx_settings_row.dart`; vai chữ
  `AppTextStyles.settingsRowLabel` (bodyLarge qua `AppTypography.withWeight`
  600, tracking -0.1) và `settingsRowSub` (bodySmall, leading 1.45) — hai
  hằng đặt tên ở `AppTypography`, cùng cơ chế `listRowTitle` đã dùng; test
  riêng, specimen stress trong `mx_stress_owner_specimens.dart`, entry
  Widgetbook (`settingsRowComponent`).
- **Out of scope:** nối màn Settings sang dùng nó; `MxIconTile`/`MxListRow`
  (đã có, PR #587/#588, task khác) — bài học của phiên này: base đã đổi
  24 commit giữa lúc làm, phải dựng lại trên `origin/main` một lần
  (`.superpowers/sdd/2026-09-18-memox-v3-settings-row/progress.md`, mục
  "Base-shift ruling") thay vì merge tay.
- **Dependencies:** M100.110 (`MxIconTile`).
- **Tests required:** `mx_settings_row_test.dart`,
  `mx_settings_row_contract_test.dart`, `mx_stress_test.dart`,
  `widgetbook_coverage_test.dart`.
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_settings_row.dart` (249 dòng),
  `test/shared/widgets/mx_settings_row_test.dart` (295 dòng),
  `test/shared/widgets/mx_settings_row_contract_test.dart` (123 dòng).
- **Acceptance criteria:**
  - [x] `trailing`/`wideControl` là `COMPONENT_INPUT` — widget của caller,
        hàng không tô màu/bật-tắt chúng; assert loại trừ hai bên.
  - [x] Một control cuối hàng (ví dụ `Switch` truyền vào `trailing`) luôn
        tới được bằng Tab dù hàng không "điều hướng" — không có `InkWell`
        nào bọc quanh nó khi hàng không điều hướng, nên không có gì để loại
        focus. Đây là khiếm khuyết đã tái phát một lần trên nhánh này
        (review cuối bắt được ở bản `MxIconTile` tự viết đã bỏ) và test
        riêng khoá lại cho cả `trailing` và `wideControl`.
  - [x] Hàng dạng control (`onTap` có, không `trailing`/`wideControl`) luôn
        có `Semantics(button: true, enabled: isEnabled)` — kể cả khi
        `isEnabled: false`; tách khỏi hàng tĩnh thật (không `onTap`) không
        có semantics nút nào. Round sửa đầu tiên của rebuild bắt lỗi này:
        `isEnabled: false` từng làm rớt hết semantics nút, đọc giống hàng
        tĩnh.
  - [x] Label/sub `maxLines: 2` + ellipsis (quy ước đã có của
        `MxListTile`), không tràn ở 320dp/textScale 2.0.
  - [x] Không đụng `mx_icon_tile.dart`/`mx_list_row.dart`; không đổi
        `AppTextStyles.listRowTitle` hay field cũ nào của `copyWith`/`.lerp`.
- **Ghi chú:** đánh số lại một lần khi merge — `M100.118` bị PR #597
  (`MxChipTrigger`) chiếm đúng lúc nhánh này còn mở, đè thẳng vào chỗ chèn
  entry (cả hai task cùng nối vào cuối bảng M100.11x). Không đụng file nào
  của PR đó ngoài `docs/wbs.md` (nội dung, không phải số dòng, mới là chỗ
  conflict).
- **Checklist phases:** 7, 12.

### M100.118 · MxChipTrigger — the ghost menu-trigger chip

- **Status:** done — đã chạy và pass: `flutter test --exclude-tags golden`
  **+5281**, `widgetbook` **+8**, `flutter analyze` `No issues found!`, guard 0
  violation, `check_architecture.sh` sạch, `check_docs.py` xanh. Không chạy golden
  (không màn hình nào dùng chip này, không golden mới).
- **Goal:** Thêm `MxChipTrigger` — chip ghost 28dp mở menu do caller sở hữu, không
  bao giờ đọc là "đã chọn". Component đầu tiên hiện thực contract "menu trigger"
  của MemoX v3 design kit (nhóm B · Actions & controls).
- **Scope:** `lib/shared/widgets/mx_chip_trigger.dart` (mới),
  `lib/shared/widgets/mx_tap_target.dart` (mới — `MxTapTarget`, chuyển nguyên hành vi
  từ `_TapTarget` của `mx_pill_button.dart`, nay dùng chung),
  `lib/shared/widgets/mx_pill_button.dart` (dùng `MxTapTarget`, bỏ bản private),
  `test/shared/widgets/mx_chip_trigger_test.dart` (mới),
  `test/shared/widgets/mx_stress_selection_specimens.dart` (specimen bắt buộc của
  `mx_stress_test`), `test/shared/widgets/mx_stress_test.dart` (miễn trừ có lý do cho
  `MxTapTarget`), `test/shared/widgets/mx_pill_button_construction_test.dart` (một
  chuỗi `reason:` đổi tên `_TapTarget` → `MxTapTarget`),
  `test/visual_audit/render_classification.dart` (comment trỏ tới file mới),
  `test/app/shared_api_closure_test.dart` (`mx_chip_trigger.dart` vào
  `kClosedApiFiles`), `widgetbook/lib/components/control_components.dart`,
  `widgetbook/lib/main.dart`.
- **Ghi chú:** ở text scale > 1, dải nội dung 28dp là **cố định** (handoff bắt
  buộc) nên dòng chữ có thể vẽ lấn nhẹ ra ngoài dải; caller cuộn hàng chứa nó.
  Đánh số lại bốn lần khi merge: M100.102 → M100.115 → M100.116 → M100.117 →
  M100.118 — M100.102 bị hai PR khác chiếm (#580, #581), M100.115 bị #594
  (SelectionCheckbox) chiếm tiếp, M100.116 bị #595 (MxFilterChip) chiếm nốt,
  rồi M100.117 bị #596 (Card v3) chiếm nốt luôn, tất cả trong lúc nhánh này
  còn mở — hàng loạt task design-system chạy song song cùng ngày. `MxFilterChip` (#595) và nhánh này cùng đụng
  `mx_stress_selection_specimens.dart` và `widgetbook/lib/components/
  control_components.dart` — merge giữ cả hai specimen/entry, không cái nào
  ghi đè cái kia. `MxFilterChip` tự chép `_TapTarget` riêng thay vì dùng
  `MxTapTarget` mới của task này (task đó merge trước, chưa thấy
  `MxTapTarget`) — việc gộp hai bản sao để sau, không phải phạm vi của task này.
- **Out of scope:** nối `MxChipTrigger` vào bất kỳ màn hình nào (CardFilterBarWidget,
  deck toolbar, …) — handoff để ngỏ, caller sở hữu menu và quyết định khi nào dùng.
- **Dependencies:** không — dùng token/thành phần đã có (`MxFocusRing`, `MxIcon`,
  `AppInk`, `AppSpacing`, `AppRadius`); `MxTapTarget` tách ra từ `MxPillButton`.
- **Tests required:** `mx_chip_trigger_test.dart` (interaction, semantics, layout,
  theming, focus).
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_chip_trigger.dart`.
- **Acceptance criteria:**
  - [x] Không có `isSelected`/trạng thái "đã chọn" nào trong API hay semantics.
  - [x] Cao 28dp (nội dung), chạm tối thiểu 48×48 **nhận được cả bằng con trỏ**
        (`MxTapTarget` chuyển hit ở vùng đệm vào giữa chip; có test chạm ở đệm dọc
        và ngang), hình pill, không viền không nền.
  - [x] Nhãn ở `label-md` (12/600), ink `AppInk.quiet` (`onSurfaceVariant`); khi
        disabled cả nhãn lẫn hai glyph đổi sang `AppInk.disabled` (`onDisabled`,
        38% ink chính). Không có `Color` thô — guard `no_text_restyle` và
        `icon_ink_boundary_test` cấm chúng trong shared kit.
  - [x] Chevron `Icons.expand_more` 16dp luôn vẽ; icon dẫn đầu là slot tuỳ chọn.
  - [x] Focus ring dùng `MxFocusRing` nguyên trạng — không thêm cơ chế focus mới;
        ring cao đúng 28dp (đo bằng test), nằm trong `MxTapTarget`.
  - [x] Đăng ký trong Widgetbook (`chipTriggerComponent()`).
- **Checklist phases:** 7, 12.


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
| Header của `MxProgressBar` tràn khi figure dài hơn nhãn | M100.72 | `_MxProgressHeader` cho nhãn trái `Expanded` còn figure phải **không flex, không ellipsis**. Đúng cho hero panel (`353 of 868 learned` cạnh `41%`: nửa dài ở bên trái, nó co lại và clip), sai cho mọi caller có figure dài: nhãn co về 0 rồi figure vẫn đòi phần của nó và tràn. Đo được ở 320dp textScaler 2.0 với caption của thẻ deck — figure cần 155.2 trong cột 160.2, cộng `sm` gap của chính primitive là tràn **3.0px**, tái hiện được chứ không phải suy đoán | Bọc `valueLabel` trong `Flexible` + ellipsis, hoặc bỏ leading gap khi không có nhãn. **Là task design-system, không phải task feature** — `MxProgressBar` là dòng 6 của `v1-freeze.md` §2, nên sửa nó đứng riêng chứ không đi ké một PR feature. **Không còn chờ điều kiện mở lại:** V1 đã mở khoá 2026-09-17 (`v1-freeze.md` §3). M100.72 đi vòng ở tầng feature: `_DeckGauge` đo trước rồi mới vẽ, primitive không bị chạm |
| Chín trong mười bốn hợp đồng đóng băng của V1 chỉ được giữ bằng test | M100.41 | Guard quét `lib/features/` cho 5 dòng (mục 2, 4, 5, 12, 13); 9 dòng còn lại — role identity, ThemeData mapping, shared API, sàn 48dp, ripple/state, high contrast, depth của card, chrome của shell, golden Linux-only — chỉ có test giữ. Test là file trong repo, nên một nhánh feature nới nó ra là đi qua được, và **guard không đỏ khi chính nó bị sửa** | ~~Một cơ chế thay cho một câu văn (CODEOWNERS, hoặc rule guard đọc diff)~~ — **rút, 2026-09-17.** Chủ dự án đã mở khoá V1: sửa một file Enforcement nay là việc hợp lệ của task design-system, nên một cơ chế chặn nó sẽ chặn đúng thứ cần làm được. Lỗ hổng gốc — một PR feature nới lỏng gate rồi đi qua — nay dựa vào review diff và luật "no drive-by refactors", không dựa vào một lớp canh |
| `StudySessionScreen` rời shell bằng `Navigator.push` chứ không bằng `GoRoute` | trước A8, đo ở A8 P2-15 (`docs/reviews/a8-navigation-chrome-audit.md` §10.5), đo lại ở C4 SC-C4-18 | Phiên học không có location: trong suốt lúc nó ở trên cùng, `GoRouterState.matchedLocation` vẫn đọc là `/study/<id>` hoặc `/decks/<id>/study`, nên không có gì deep-link hay restore vào một phiên đang chạy, và `GoRouterState` nói sai trong đúng khoảng thời gian dài nhất của app | **ACCEPTED, chờ quyết định của chủ dự án.** Phần *root navigator* đã có lý do và không phải nợ — nó là thứ giữ BR-82 một lối ra duy nhất (comment tại `study_entry_screen.dart` `_open`); chỉ **cơ chế** là còn mở. C4 cố ý chỉ mount `StudyOptionsScreen` (composition thuần: nó vốn đã render trong shell, chỉ thêm location) và **không** mount phiên học, vì bán kính nổ nằm ngoài tầm một task chrome: IT-NAV, đường resume khoá theo `sessionId` (BR-200, BR-103) và hợp đồng một-lối-ra của BR-82 đều chạm nó, và không cái nào verify được bằng host test. Khi mở lại: mount với `parentNavigatorKey: rootNavigatorKey` đúng như wizard import, `resumeSessionId`/`direction` đi bằng `extra`, và closure test là `currentConfiguration.uri` gọi tên route phiên |
| `CardEditorScreen` (edit) xếp chồng hai dải pinned ở đáy | trước C4, đo ở C4 SC-C4-04 | Route edit nằm trong `StatefulShellBranch` của Decks, nên `MxNavigationBar` bốn đích vẫn vẽ dưới nó; màn hình lại ghim action bar của chính nó vào `MxContentShell.footer` (`MxButtonPair` ≥48dp + `sm` + một dòng `bodySmall` + 2×`md`). **Đo, mount qua `createAppRouter`:** footer **96dp** + nav bar **80dp** = **176dp** chrome đáy. Không golden nào thấy được: `card_screens_demo_test.dart` pump thẳng `CardEditorScreen`, ngoài `createAppRouter` | **ACCEPTED — variance có chủ đích, không phải nợ nhánh route.** Edit là **page** được push lên card list và quay về đó (mũi tên back nói đúng điều đó), và nó push tiếp một branch route cho history của thẻ — đưa nó lên root navigator sẽ render Card Detail **dưới** editor. Wizard import thoát khỏi branch được vì nó là task không push branch route nào; đây không phải trường hợp đó. Đã ghi tại `app_router.dart` ngay trên `RouteNames.cardEditorEdit` để nó thôi là hệ quả tình cờ của việc lồng route. **Đính chính phép đo gốc:** SC-C4-04 viết edit là màn *duy nhất* xếp chồng hai dải — sai. Create cũng ghim footer từ SC-C1-02 và cũng nằm trong branch, nên nó xếp chồng y hệt; nửa mâu thuẫn thật sự là create, vì `✕` của nó tuyên bố một task trong khi thanh branch vẫn ở đó. Sửa nửa đó là SC-C4-19 (`parentNavigatorKey: rootNavigatorKey` cho `cardCreateRelative`), **không** nằm trong cụm C4 này | Khi 176dp chrome đáy được phán là không chấp nhận được trên thiết bị: lúc đó câu hỏi là "editor là page hay task" — một quyết định của chủ dự án, không phải một phép sửa composition. Hoặc khi SC-C4-19 được giao, vì nó chốt nửa create của cùng câu hỏi |
| Nhãn mode pill của `MxSessionTopBar` không đạt AA ở light | StudyTopBar Task 1 (2026-09-18) | Hợp đồng handoff bắt nhãn tô bằng `accent` ở full strength trên nền là chính `accent` pha 10% vào `surface`, thay cho `AppInk.accent` (`accentInk`, sinh ra đúng vì `primary` thô không đủ AA làm chữ). Đo được: light **3.87:1** (primary) và **3.65:1** (mastery), dưới ngưỡng 4.5; dark đạt **6.43:1** (primary). Chip 12sp không được miễn ngưỡng chữ lớn. Chữ chỉ tên mode, và tên đã có ở `Semantics(namesRoute)`, nên không mất thông tin — nhưng người thị lực kém ở light mode đọc chip khó hơn bản trước (4.78:1) | **Cần chủ dự án quyết:** giữ nguyên hợp đồng, hoặc thêm một ink kiểu `accentInk` cho nhãn (ví dụ `AppInk`-style role cho từng accent), hoặc nâng độ đậm tint. Test `study_accessibility_test.dart` "the mode pill label clears AA for both accents" (primary + mastery × light + dark) đang `skip` với lý do này — bỏ `skip` khi sửa xong |
