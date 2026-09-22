# Interfaces — ranh giới HTTP của memox-api

| | |
|---|---|
| **Status** | active |
| **Purpose** | Trả lời "backend hiện có gì, app đã nối vào chưa, và lỗi trả về hình gì" mà không chép lại `openapi.json` — bản sao đó sẽ lệch, và không có gate nào canh nó |
| **Scope** | Bề mặt HTTP của `memox-api/`, trạng thái tích hợp với client Flutter, hình dạng lỗi dùng chung, và quan hệ giữa schema Postgres của backend với schema Drift của app. Ngoài phạm vi: danh sách endpoint (xem `memox-api/openapi.json`), nội bộ Spring, schema Drift (`data-model.md`) |
| **Source of truth for** | Trạng thái tích hợp app ↔ backend · hình dạng lỗi HTTP dùng chung · quan hệ parity Postgres ↔ Drift và điểm phân kỳ có chủ đích |
| **Depends on** | `document-conventions.md`, `architecture.md` (AD-03, AD-05) |
| **Updated by task** | project-documentation FULL_SYNC (no WBS id) |
| **Last updated** | 2026-09-23 |

---

## 1 · Danh sách endpoint không nằm ở đây, và đó là cố ý

Hợp đồng HTTP gốc là [`memox-api/openapi.json`](../memox-api/openapi.json) —
**30 path, 37 operation**. Nó không phải tài liệu viết tay: `OpenApiSnapshotTest`
sinh lại document từ ứng dụng đang chạy rồi so byte với file đã commit, và
`ci.yml:476` chạy `git diff --exit-code -- openapi.json`. Đổi một endpoint mà
quên commit lại contract thì CI đỏ.

Chép 37 endpoint vào Markdown sẽ tạo bản sao thứ hai của thứ đã có gate canh —
và bản sao là bản nói dối, đúng như `lib/features/deck/README.md` §2 đã học được
khi liệt kê tên định danh trong prose. Cái tài liệu này giữ là **những thứ
`openapi.json` không diễn đạt được**.

## 2 · Backend hiện có gì

Số liệu đếm trực tiếp ở revision `5b83bfd8`:

| Hạng mục | Số lượng |
|---|---|
| Controller | 8 |
| Endpoint (method + path) | 37 |
| Flyway migration | `V1`…`V5` |
| Test method | 310 |

Vùng đã làm: Deck, Card, Tag, Trash — CRUD, cây, tag, soft-delete/restore/purge.
Vùng **chưa** làm: Study/SRS engine, Search, Progress, Settings. Schema của
Study đã migrate (`study_sessions`, `study_answers`, `study_queue_items`,
`card_study_states` đều có trong `V2`), nhưng phía ứng dụng mới chỉ có
`StudyMapper` với ba method phục vụ BR-259 — Javadoc của chính nó nói rõ phần
còn lại thuộc Phase 3.

`docs/wbs.md` ghi `M9.W1`…`M9.W3`, `M9.P0`, `M9.Phase2` là `done`; **không có
entry nào cho Phase 3, 4, 5.** Nên "chưa làm" ở đây là chưa bắt đầu theo sổ,
không phải làm dở.

## 3 · App **chưa** gọi backend

Đây là thứ dễ đoán sai nhất khi thấy `memox-api/` nằm trong repo.

| Kiểm tra | Kết quả |
|---|---|
| `dio`/`http`/`retrofit` trong `pubspec.yaml` | không có |
| `package:dio` / `package:http` / `HttpClient` trong `lib/` | không có |
| thư mục `api_client`/`remote`/`network` trong `lib/` | không có |

AD-05 vẫn đúng nguyên văn: dependency mạng được hoãn tới **đúng lúc bắt đầu tích
hợp**, không phải lúc backend tồn tại. Hai phía độc lập nói cùng một điều kiện —
`architecture.md` (AD-05) từ phía app, và
`docs/superpowers/specs/2026-09-06-memox-api-design.md` từ phía backend.

**Hệ quả:** backend hiện là một service đứng một mình, có CI, có test, có
contract — nhưng không có consumer nào trong repo này.

## 4 · Không có auth, và đó là quyết định

Không có Spring Security, không có `@PreAuthorize`, không có filter nào ngoài
`RequestIdFilter` (phục vụ observability). `OpenApiConfiguration.java:17` nói
thẳng trong description của contract: *"Authentication and sync are not enabled
yet."*

Khớp với AD-03 phía app: một local profile, `owner_id` nullable có sẵn từ đầu để
auth thêm vào sau không phải migrate.

## 5 · Hình dạng lỗi, dùng chung cho cả 37 endpoint

Một `@RestControllerAdvice` duy nhất (`common/error/ApiExceptionHandler.java`)
trả **RFC 9457 `application/problem+json`**:

| Trường | Nội dung |
|---|---|
| `type` | `urn:memox:error:<code>` |
| `title` · `status` · `detail` | chuẩn RFC 9457 |
| `code` | mã máy đọc, ổn định — 24 giá trị trong `ApiErrorCode` |
| `requestId` | lấy từ MDC, nối response với log |
| `fieldErrors` | chỉ có ở lỗi validation |

Chi tiết định danh (ví dụ `deckId=...`) đi vào **log**, không vào body — cùng
tinh thần BR-53 phía app: thông báo lỗi người dùng thấy không mang id, path hay SQL.

## 6 · Quan hệ với schema Drift

Schema Postgres soi gương schema Drift gần như cột-đối-cột, sai khác chỉ ở dịch
kiểu (`TEXT`→`VARCHAR(36)`, `DATETIME`→`TIMESTAMPTZ`, `INTEGER` 0/1→`SMALLINT` +
`CHECK`, `REAL`→`DOUBLE PRECISION`).

**Một phân kỳ có chủ đích, chỉ có ở server** — và nó đáng biết vì nó giải thích
vì sao hai bên không thể giống hệt nhau:

`decks.sibling_scope_id` (`V3__enforce_deck_position_integrity.sql:1`) hiện thực
hoá `parent_deck_id` thành một cột để khai được
`UNIQUE (sibling_scope_id, sibling_position)`. `V5` đổi ràng buộc đó thành
`DEFERRABLE INITIALLY DEFERRED`, vì một lần sắp xếp lại sibling đi qua trạng thái
trung gian mà hai hàng cùng position — Postgres không được từ chối ở giữa
transaction. **Drift không có cột này và không có ràng buộc unique nào ở đây**
(kiểm: 0 lần xuất hiện trong `decks.drift`): app là local-first, một writer, nên
thứ tự được giữ bằng code chứ không bằng constraint. Server có nhiều writer nên
không có lựa chọn đó.

Parity **không** được canh ở mức schema mà ở mức **câu query**:
`DriftParityTest` bắt mọi named query trong `lib/core/database/queries/{deck,card,tag,trash}.drift`
phải có một dòng trong `docs/superpowers/specs/2026-09-09-drift-to-mybatis-parity.md`,
và ngược lại mọi statement id trong `memox-api/src/main/resources/mybatis/*_mapper.xml`
cũng vậy. `study.drift` **không** nằm trong phạm vi test đó — khớp với việc Study
là Phase 3.

## 7 · Chạy và kiểm

```bash
cd memox-api
cp .env.example .env          # rồi đặt MEMOX_DB_PASSWORD
docker compose up -d          # postgres:16-alpine
./mvnw -Dspring-boot.run.profiles=local spring-boot:run
```

`compose.yaml` chỉ dựng **database**, không đóng gói ứng dụng. Repo không có
Dockerfile, không có manifest deploy, không có CD workflow cho service này —
cách duy nhất đã commit để chạy nó là Maven trực tiếp.

Gate: `./mvnw -B -ntp verify` (Checkstyle, PMD, SpotBugs, JaCoCo floor, snapshot
contract). CI chạy nó ở job `memox-api · verify` (`ci.yml:423`) trên hai leg
`testcontainers` và `local`, chỉ khi có path `memox-api/**` đổi.

Guard Dart-side **không** quét `memox-api/` — scope của nó dừng ở `lib/`, `test/`,
`integration_test/`, `pubspec.yaml`, `analysis_options.yaml`, `.fvmrc`. Layering
của backend do `LayerArchitectureTest` (ArchUnit) canh, chạy trong `mvnw verify`.

## 8 · Câu hỏi còn mở

**`api-spec.md` đã tới lúc viết chưa?** `docs/README.md` xếp nó vào "Not written
yet" với điều kiện *"not until the Spring Boot backend exists (AD-05)"*. Backend
đã tồn tại (§2). Nhưng AD-05 phát biểu mốc khác: dependency mạng hoãn tới *"đúng
lúc bắt đầu tích hợp Spring Boot"* — và tích hợp thì chưa bắt đầu (§3).

Hai cách đọc đều chống đỡ được từ cùng một AD, và `docs/README.md` không nói cách
nào chi phối. **Tài liệu này không quyết định thay.** Nó ghi nhận rằng điều kiện
đã trở nên nhập nhằng và cần một quyết định của chủ dự án.

Lưu ý cơ chế: `check_docs.py` sẽ không bao giờ phát hiện chuyện này. Hàm
`_check_not_written_yet()` chỉ kiểm file `docs/<name>` **không tồn tại trên đĩa**;
nó không đọc điều kiện viết bằng prose. `docs/api-spec.md` quả thật không tồn tại,
nên check đó xanh — nó được thiết kế để bắt lỗi ngược lại (tài liệu đã viết mà
quên xoá khỏi bảng).
