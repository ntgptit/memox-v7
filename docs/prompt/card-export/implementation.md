# Implement Card Export

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc triển khai Card Export theo AD-20 và kiến trúc MemoX hiện tại |
| **Scope** | Content export CSV/TSV/XLSX cho toàn deck hoặc selected cards; không gồm backup và sync |
| **Source of truth for** | Prompt implementation Card Export |
| **Depends on** | `docs/product.md`, `docs/architecture.md` (AD-20), `docs/business-rules.md`, `docs/use-cases.md`, `docs/wireframes/m4-11-card-management.md`, `lib/features/card/README.md` |
| **Updated by task** | User-requested prompt workflow update |
| **Last updated** | 2026-08-13 |

---

Bạn đang làm việc trong repository `D:\workspace\memox-v7`.

Hãy triển khai Card Export hoàn chỉnh. Đây là nửa còn lại của Card Transfer theo
AD-20, không phải database backup.

## Quy tắc làm việc

1. Đọc đầy đủ `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, N1 và
   private-data contract trong `docs/product.md`, AD-20, các BR liên quan privacy
   và Import, UC-04/UC-10, wireframe Card Management/Card Import, `docs/wbs.md`,
   `lib/features/card/README.md` và production Card Transfer code.
2. Bắt đầu bằng 5Why; phân biệt content transfer, export file, database backup
   và Google Drive sync trong tương lai.
3. Kiểm tra `git status`; không reset/checkout/ghi đè session khác. Dừng và báo
   nếu có xung đột trực tiếp.
4. Docs là source of truth. Trước code:
   - append BR/UC bằng ID kế tiếp sau khi kiểm tra repo;
   - tạo WBS task đủ field và liệt kê frozen docs được phép sửa;
   - cập nhật AD-20 affected docs/consequences nếu cần, không tạo AD mới nếu
     quyết định hiện tại đã đủ;
   - tạo wireframe Card Export;
   - cập nhật N1, Card README và navigation docs chỉ khi route thật sự đổi;
   - không sao chép rule giữa docs, chỉ dẫn chiếu ID.

## Nghiệp vụ

### Scope

Hỗ trợ đúng hai scope:

- `All cards in this deck`: toàn bộ card trực tiếp trong deck, độc lập
  filter/search/sort/pagination; không export descendant.
- `Selected cards`: exact set ID đã materialize từ selection mode; normalize ID
  trùng; nếu một ID mất hoặc không còn thuộc deck trước snapshot thì typed
  failure cho toàn request, không silent partial.

Không hỗ trợ `current filtered results` ở v1. Export là read-only nên không tự
xóa selection. Không hiển thị action khi deck rỗng và vẫn chặn empty export tại
domain/repository.

### Format và canonical schema

Hỗ trợ `CardTransferFormat.csv` (default, Recommended), `.tsv`, `.xlsx`. Không
tạo format enum thứ hai.

Mỗi file luôn có sáu canonical headers, đúng thứ tự, không localize:

`front, back, example, hint, pronunciation, tags`

Optional field ghi ô rỗng.

- CSV/TSV dùng package `csv`, UTF-8 BOM, không tự split/join. Quoted delimiter,
  quote, CRLF và embedded newline phải round-trip; giữ `001`, `1e3`, `+84`.
- XLSX dùng package `excel`, một safe worksheet, ghi cell như text. Nội dung bắt
  đầu `=`, `+`, `-`, `@` không được trở thành formula.

### Reversible tags cell

Tags dùng `;`, nhưng tag có thể chứa `;` hoặc `\`. Tạo một codec chung cho
Import và Export:

- `;` → `\;`;
- `\` → `\\`;
- decode chỉ coi backslash là escape trước `;` hoặc `\`;
- backslash trước ký tự khác và trailing backslash giữ nguyên để tương thích
  nguồn legacy;
- Import chuyển sang codec chung;
- export → import giữ nguyên spelling và tập tags.

Codec sống cạnh canonical transfer schema, không duplicate ở encoder/preview.

### Content-only contract

Chỉ export sáu content fields. Không export card/deck ID, timestamp, flag,
scheduler/version/generation, box/ease/interval/due, learned state, review
history hoặc session. Import lại phải tạo ID và study state mới theo AD-20.

### Snapshot, ordering và filename

- Deck name, content và tags đến từ một snapshot nhất quán, không N+1.
- Cards: `created_at ASC`, tie-break `id ASC`.
- Selected scope cũng dùng ordering này, không theo thứ tự tap.
- Tags: `name_folded ASC` và stable tie-break.
- Không mutation DB, timestamps, content type, state/history hoặc selection.
- Filename sanitize deck name, loại path/control/invalid characters, collapse
  whitespace, fallback `cards`, thêm ngày từ `clockProvider`, extension theo
  format; không gọi `DateTime.now()` hoặc log filename.

### Share/save

Android không có save-location picker qua `file_selector`. Dùng Android system
share sheet:

- thêm `share_plus` version tương thích Flutter/Dart/AGP hiện tại, không chọn
  latest mù quáng; cập nhật lockfile;
- artifact domain chỉ chứa bytes/filename/MIME, không chứa plugin types;
- platform exception map typed Failure;
- dismiss share sheet là cancel, không phải error;
- không nói `Saved` nếu OS không xác nhận;
- không ghi shared storage trước explicit action;
- temporary cache là private/transient, không log content/path/name;
- không dùng `dart:io` trong presentation và giữ Web build.

## Kiến trúc

Không tạo `ImportExportFactory`; AD-20 đã loại God Object. Dùng Strategy:

- `CardTransferEncoder`: canonical records → bytes;
- một exhaustive encoder resolver theo `CardTransferFormat`;
- CSV/TSV chung delimited encoder với config khác nhau;
- XLSX encoder riêng;
- format switch chỉ ở resolver;
- encoder không biết UI/Riverpod/DB/picker/share;
- decoder và encoder là hai pipeline riêng.

Tạo/điều chỉnh tối thiểu:

- Domain: scope/request/artifact/result models, `CardExportRepository`, platform
  destination contract, `ExportCardsUseCase`, typed failures, tag codec.
- Data: SQL trong `.drift`, export DAO/read adapter, repository impl, delimited
  encoder, XLSX encoder, resolver, `share_plus` adapter.
- DI: providers, composition-root bindings và shared binding list.
- Presentation: controller/state riêng, overlay trong `widgets/overlays/`, Card
  List/selection entry points, EN/VI localization.

UI không gọi repository, controller không giữ `BuildContext`, plugin không lọt
vào domain và không dùng một `isLoading` chung của Card List.

## UI/UX

Dùng modal bottom sheet, không tạo full-screen route.

- Card List overflow: `Export cards` → `All N cards in this deck`.
- Selection bar: `Export selected` → `N selected cards`.

Sheet gồm title, read-only scope summary, ba format options, CSV Recommended,
mô tả content+tags, info rằng progress/history không có trong file, Cancel và
primary `Export N cards`.

States: initial, generating, share requested, dismissed, unavailable/platform
error, repository/encoder failure, stale/empty selection.

- Chặn double-submit; dismiss share không báo error; error giữ scope/format để
  Retry; success copy trung thực; selection giữ nguyên; Back/Close an toàn.
- Dùng Mx components/tokens, không hardcode visual values.
- Kiểm 320dp @ 2.0x, 390/412dp, long deck name, count lớn, EN/VI, light/dark.
- Format options phải fill shared column hoặc stack full-width, không intrinsic
  width gây hụt mép.

## Tests bắt buộc

1. Schema/domain: field order, tag codec+legacy, filename, scope normalization.
2. Encoders: ba format, Korean/Vietnamese, delimiter/quote/newline, textual
   numbers, formula-looking XLSX, optional fields, escaped tags.
3. Round-trip: production encoder → production decoder → production mapping;
   compare đủ sáu fields và tags. Không dùng helper cùng encoder làm oracle.
4. Real DB: all/selected, deterministic order/tags, stale/wrong-deck IDs,
   empty/missing deck và no mutation state/history/content type/timestamps.
5. Use case/destination: success, dismissed, unavailable, exception, read/
   encode failure, double submit.
6. Widget: entry points, scope, formats, loading/error/retry/dismiss, retained
   selection, semantics, responsiveness, locales/themes.
7. Visual: production states và `tester.getRect` geometry assertions; golden
   mới chỉ là regression baseline, phải đối chiếu wireframe.
8. Boundary: presentation không thấy codec/plugin/DB; encoder không thấy DB/UI/
   share; only resolver dispatches format; không log private export data.

## Verification và clean stop

- Inner loop: targeted Export, transfer round-trip, Card List và visual tests.
- Final: `.claude/skills/flutter-workflow/scripts/dod_check.sh`.
- Vì có feature code và platform dependency, chạy:
  `flutter test integration_test/ -d emulator-5554 --flavor development`.
- Android smoke: export Korean CSV, share sang Files/Drive, mở và import vào deck
  khác; dismiss không báo lỗi; không có broad storage permission.

Nếu device/share target không có, báo chính xác gate thiếu; không tuyên bố Done.
Chỉ dừng khi docs/code/tests thống nhất, ba format và hai scope đúng, round-trip
giữ content+tags, learning data không lọt file, DB không mutation, Android share
hoạt động, Import không regression, geometry đã đo và không còn TODO/dead API.
