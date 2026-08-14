# Architecture decisions

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi lại quyết định kiến trúc và lý do, để phiên sau đọc được quyết định chứ không phải đoán từ code |
| **Scope** | Quyết định ràng buộc nhiều tài liệu hoặc nhiều layer. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), hình dạng dữ liệu (`data-model.md`) |
| **Source of truth for** | AD-xx · đánh đổi kiến trúc · phương án đã bị loại · lý do pin toolchain |
| **Depends on** | `document-conventions.md`, `product.md` |
| **Updated by task** | M99.23 (AD-19 · Progress hết hạn placeholder, Settings thì chưa) |
| **Last updated** | 2026-08-13 |

Format theo `document-conventions.md` §6.1. AD xếp theo số; ID vĩnh viễn (§7).

Ghi lại các quyết định kiến trúc và **lý do**, để phiên làm việc sau đọc được
quyết định chứ không phải đoán từ code. Mỗi quyết định có ID `AD-xx` để code
comment và WBS trích dẫn.

Nguyên tắc xuyên suốt tài liệu này: **chuẩn bị sẵn những thứ đắt tiền khi
retrofit, hoãn những thứ rẻ khi retrofit.** Đó là ranh giới giữa "backend-ready"
và "over-engineering" — cả hai đều là yêu cầu trong CLAUDE.md và chúng kéo ngược
chiều nhau.

---

## AD-01 · Local-first, backend-ready

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `data-model.md` · `business-rules.md` · `flutter-data-layer` skill |

**Quyết định.** Drift/SQLite là source of truth. Toàn bộ MVP không có network.
Backend Spring Boot sẽ được thêm sau, khi app đã ổn định về UX, migration và
test.

**Hệ quả lên code:**

- Repository **đọc từ Drift qua stream** (`watch()`), không phải `Future` một
  lần. UI cập nhật khi dữ liệu đổi vì bất kỳ lý do gì — sửa ở màn khác, hoặc
  sync ở tương lai — mà không cần invalidate thủ công.
- Ghi vào Drift là ghi *thành công*. Không có trạng thái "đang gửi lên server".
- `features/*/data/remote/` **chưa tồn tại**. Không tạo thư mục rỗng, không tạo
  interface `RemoteDataSource` chưa có ai implement — đó đúng là thứ CLAUDE.md
  gọi là "interface chỉ để bọc một implementation không có nhu cầu thay thế".

**Điều gì làm nó "backend-ready":** repository contract nằm ở `domain/` và được
viết theo *nhu cầu của presentation*, không theo hình dạng của Drift. Khi thêm
backend, `DeckRepositoryImpl` nhận thêm một remote data source và một sync
policy; `domain/` và `presentation/` **không đổi một dòng nào**. Đó là toàn bộ
giá trị của lớp repository ở dự án này — nếu contract bị viết theo hình dạng
bảng Drift thì lợi ích này mất sạch.

**Kiểm tra tính đúng đắn:** nếu một method trong repository contract nhận tham số
kiểu Drift, hoặc trả về kiểu sinh bởi Drift, thì AD-01 đã bị vi phạm.

---

## AD-02 · SQL viết trong file `.drift`, tách khỏi Dart

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `data-model.md` · `flutter-data-layer/references/persistence.md` |

**Quyết định.** Bảng và query khai báo trong file `.drift`, không dùng Dart table
class.

```
lib/core/database/
├── app_database.dart          # @DriftDatabase, migration strategy
├── tables/
│   ├── decks.drift
│   └── cards.drift
└── queries/
    └── study.drift            # named query cho luồng ôn tập
```

**Lý do.**

1. SQL được `drift_dev` phân tích **lúc build**. Query sai cột, sai kiểu, sai
   join → lỗi biên dịch, không phải lỗi runtime. Đây là lợi ích lớn nhất và nó
   chỉ có ở đường `.drift`.
2. SQL nằm nguyên vẹn ở một chỗ, đọc được bởi người làm backend Spring Boot sau
   này. Khi thiết kế schema phía server, đây là tài liệu tham chiếu trực tiếp.
3. Query phức tạp của SRS (lọc theo hạn ôn, sắp xếp, giới hạn) viết bằng SQL rõ
   ràng hơn hẳn so với query builder lồng nhau.

**Đánh đổi đã chấp nhận:** ít type-safety hơn ở phía Dart khi *viết* query, và
lỗi cú pháp SQL chỉ hiện lúc chạy `build_runner` chứ không phải ngay trong IDE.
Chấp nhận được, đổi lại điểm 1.

**Quy ước:** một file `.drift` cho mỗi bảng hoặc mỗi nhóm query cùng mục đích.
Named query đặt tên theo động từ nghiệp vụ (`cardsDueForStudy`), không theo hình
dạng SQL (`selectCardsWhereDue`).

---

## AD-03 · Auth-ready, chưa có auth

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `data-model.md` · `product.md` · BR-56 |

**Quyết định.** MVP không có đăng nhập. Một local profile duy nhất trên thiết bị.
Nhưng kiến trúc chuẩn bị sẵn cho auth.

**Cụ thể là chuẩn bị những gì:**

| Chuẩn bị | Chi phí bây giờ | Chi phí nếu retrofit |
|---|---|---|
| `ownerId TEXT NULL` trên bảng người dùng sở hữu | một cột | migration + backfill trên mọi bảng, đúng lúc dữ liệu đã nhiều |
| ID sinh phía client (UUID/ULID) | dùng `uuid` thay vì autoincrement | **rất cao** — đổi kiểu khoá chính và mọi khoá ngoại |
| `createdAt` / `updatedAt` | hai cột | migration, và không khôi phục được giá trị lịch sử |
| Repository contract độc lập nguồn dữ liệu | 0 — vốn đã là yêu cầu | viết lại repository |
| Một chỗ duy nhất trong router để cắm guard | 0 — chỉ là kỷ luật | rải guard khắp các màn |

**Cụ thể là KHÔNG chuẩn bị gì:**

- Không có màn login, không có `AuthRepository`, không có token storage. Chưa
  dùng được thì chưa xây.
- Không có cột `isPendingSync` / `version`. Chúng vô nghĩa khi chưa có server, và
  thêm bằng migration sau là **rẻ** — hạ tầng test migration đã có sẵn theo kế
  hoạch, nên đây đúng là thứ nên hoãn.
- Không có role/permission. Kể cả sau khi có auth cũng chỉ có một loại user.

`ownerId` để `NULL` ở toàn bộ MVP, nghĩa là "thuộc về local profile". Khi có
auth, migration backfill `ownerId` bằng ID của user đăng nhập đầu tiên — dữ liệu
người dùng đã tạo offline không bị mất, đó là lý do cột này nullable ngay từ đầu
thay vì `NOT NULL DEFAULT ''`.

---

## AD-04 · Android là target release, Web chỉ để development

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `product.md` · `flutter-ship/references/ci.md` · `flutter-project-setup` |

**Quyết định.** Release đầu chỉ Android. Web build được giữ hoạt động nhưng
**không phát hành** — dùng để review UI nhanh và chạy E2E/visual regression bằng
Flutter Web + Playwright. iOS sau khi Android ổn định.

**Hệ quả thực tế, và đây là điều dễ bị bỏ qua:** Web không phải target *nhưng
phải build được*. Nếu chọn một plugin không hỗ trợ Web thì mất luôn kênh E2E —
tức là mất công cụ test, không phải mất một nền tảng.

Quy tắc khi thêm package: kiểm tra hỗ trợ Web. Nếu bắt buộc phải dùng package
không có Web, phải bọc sau một abstraction có fake implementation cho Web, và ghi
lại ở đây.

**Không** đánh đổi thiết kế Android để Web đẹp hơn. Responsive vẫn làm theo
mobile-first như Phase 7.4; desktop breakpoint chưa cần.

CI giai đoạn này: bỏ job `build-ios` (tiết kiệm macOS runner minutes), giữ
`build-android` và thêm `build-web` như một cổng kiểm tra rằng kênh E2E còn sống.

**Kênh E2E phụ thuộc WebGL — ràng buộc bắt buộc cho runner CI (M7).** Từ Flutter
3.29 renderer HTML đã bị gỡ; 3.44 chỉ còn CanvasKit và skwasm, **cả hai đều cần
WebGL**. Hệ quả cụ thể và nguy hiểm: ở môi trường không có WebGL, `flutter build
web` vẫn **exit 0** và Playwright vẫn điều hướng thành công, nhưng app **không
render** — screenshot ra trang trắng. Không có lỗi build nào cảnh báo, nên một
job visual-regression sẽ so sánh hai trang trắng với nhau và báo pass.

Vì vậy runner chạy E2E/visual regression **MUST** có WebGL — GPU thật, hoặc
SwiftShader/ANGLE làm software fallback. Job này **MUST** có một assert rằng app
đã render thật (ví dụ: tồn tại `<canvas>` do Flutter tạo, kích thước khác 0)
trước khi so sánh ảnh; nếu không, "pass" của nó không mang thông tin.

Lưu ý khi viết assert đó: Flutter đặt `<canvas>` bên trong **shadow DOM** của
`flutter-view`. `document.querySelectorAll('canvas')` trả về 0 ngay cả khi app
đang render bình thường — phải duyệt xuyên `shadowRoot`.

Kiểm chứng đã chạy (M2.1a, máy local Windows + Chrome 150): WebGL2 khả dụng,
renderer `ANGLE (AMD Radeon, Direct3D11)`, và bản build web render đúng ở cả
1440×900 lẫn 393×852. Giả định của quyết định này **đứng vững** ở môi trường có
GPU; nó chỉ đổ ở container headless không WebGL, và đó là thuộc tính của môi
trường chứ không phải của lựa chọn kiến trúc.

---

## AD-05 · Chưa thêm dependency mạng

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `flutter-project-setup/references/dependencies.md` · `flutter-data-layer` |

**Quyết định.** Chưa cài `dio`, `connectivity_plus` và các package liên quan
mạng, dù chúng có trong checklist Phase 3.1.

**Lý do.** CLAUDE.md và Phase 3.3 nói rõ: không thêm package khi chưa có lý do.
MVP không gọi mạng. Một `dio` nằm trong `pubspec.yaml` mà không ai dùng vẫn tốn
thời gian build, vẫn phải nâng cấp khi Flutter đổi phiên bản, và vẫn tạo ảo giác
rằng lớp network đã tồn tại.

Thêm vào đúng lúc bắt đầu tích hợp Spring Boot. Hướng dẫn cấu hình Dio và
interceptor đã sẵn sàng ở
`.claude/skills/flutter-data-layer/references/networking.md` — không mất gì khi
hoãn.

**Ngoại lệ:** `uuid` cài **ngay bây giờ**, dù nó chỉ thực sự cần thiết cho
offline-sync sau này. Lý do ở bảng AD-03: ID sinh phía client là thứ đắt nhất khi
retrofit.

---

## AD-06 · Scheduler chọn theo deck, khoá sau lượt học đầu tiên

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-05, BR-06, BR-11…BR-19, BR-30, BR-73, BR-74) · `use-cases.md` (UC-02, UC-03, UC-05) · `data-model.md` |

**Quyết định.** MVP hỗ trợ **hai** scheduler: `eight_box` và `sm2`. Mỗi deck
**bắt buộc chọn một** khi tạo. Lựa chọn ở cấp deck, không phải cấp app.

Scheduler đổi trực tiếp được **chừng nào deck chưa có lượt học nào**. Sau lượt
học đầu tiên, `scheduler_type`, `scheduler_version` và `scheduler_config` của
deck bị **khoá**. Muốn đổi sau đó, người dùng phải thực hiện **Reset learning
progress** (AD-09).

```dart
// domain/scheduler/study_scheduler.dart
abstract interface class StudyScheduler {
  SchedulerType get type;
  int get version;

  /// Tập action mà scheduler này chấp nhận. UI render nút từ đây,
  /// không hardcode — hai scheduler có hai tập action khác nhau.
  List<StudyAction> get supportedActions;

  StudyOutcome next({
    required CardStudyState current,
    required StudyAction action,
    required DateTime now,
  });
}
```

**Hai scheduler có hai tập action khác nhau, và đây là điểm dễ làm sai nhất:**

| Scheduler | Action |
|---|---|
| `eight_box` | `forgotten`, `remembered` |
| `sm2` | `again`, `hard`, `good`, `easy` |

UI **phải** render nút đánh giá từ `supportedActions` của scheduler thuộc deck.
Không hardcode bốn nút, không hiện nút mà scheduler hiện tại không hiểu. Một màn
ôn tập hardcode 4 nút sẽ vừa sai với 8-box vừa khiến việc thêm scheduler thứ ba
phải sửa UI — đúng thứ abstraction này tồn tại để tránh.

**Vì sao khoá sau lượt học đầu tiên thay vì cho đổi tự do.** Đổi thuật toán giữa
chừng đặt ra những câu hỏi không có câu trả lời trung thực: box 5 tương ứng ease
factor nào, study answers theo luật cũ còn giá trị gì cho chu kỳ mới, đổi ngược
lại có khôi phục trạng thái cũ không. Mọi ánh xạ đều là bịa đặt và nó âm thầm làm
hỏng lịch ôn.

Khoá-và-reset thừa nhận điều đó thẳng thắn: trước lượt học đầu, không có gì để
mất nên đổi tự do; sau đó, đổi nghĩa là bắt đầu lại, và người dùng biết rõ điều
mình đánh đổi.

**Vì sao thuần khiết.** `next()` không đọc database, không gọi `DateTime.now()` —
`now` truyền vào như tham số. Đây là phần logic duy nhất trong app thực sự phức
tạp và bắt buộc phải đúng: sai thuật toán thì người dùng không nhận ra ngay, chỉ
thấy "app không hiệu quả" sau vài tuần. Thuần khiết nghĩa là test toàn bộ ma trận
của cả hai scheduler trong vài mili giây, không cần database, không cần widget,
không phải chờ thời gian trôi.

**Bảng interval và tham số thuật toán nằm ở scheduler config**, không hardcode
trong UI, controller, hay SQL query. Một số ngày trong câu `WHERE` là số ma thuật
nằm ngoài tầm với của test thuật toán — và là chỗ nó sẽ lệch khỏi bảng thật.

**Scheduler thuộc về root deck; toàn bộ cây kế thừa.** Deck lồng được nhiều cấp
(AD-10), và ở mọi cấp, descendant kế thừa `scheduler_type`, `scheduler_version`
và `scheduler_generation` từ root. Cột scheduler chỉ có giá trị trên root; deck
không phải root để NULL và tra qua `root_deck_id`.

Cho deck con chọn riêng sẽ khiến một phiên ôn trải trên nhiều nhánh phải hiển thị
nhiều tập action cùng lúc — vô nghĩa với người dùng, vì `forgotten`/`remembered`
và `again`/`hard`/`good`/`easy` không quy đổi được cho nhau.

Hệ quả khi di chuyển subtree giữa hai root khác scheduler: **chặn, hoặc yêu cầu
reset tường minh** (BR-74). Không im lặng chuyển đổi state — không có ánh xạ nào
có cơ sở giữa box và ease factor (BR-73).

---

## AD-07 · Starter deck là template, người dùng nhận bản sao

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-31…BR-39, BR-87) · `use-cases.md` (UC-01) · `data-model.md` |

**Quyết định.** Deck dựng sẵn là **template**, quản lý tách biệt với deck thuộc
sở hữu người dùng. Khi người dùng chọn dùng một starter deck, app **tạo một bản
sao** vào dữ liệu cá nhân. Bản sao đó sau đấy là deck bình thường: sửa, xoá, học
như mọi deck khác.

Template mang metadata ổn định: `template_id`, `version`, `locale`, `title`,
`content_source`. Deck bản sao giữ `source_template_id` và
`source_template_version` để biết nó bắt nguồn từ đâu và từ phiên bản nào.

**Vì sao copy-on-use thay vì chèn thẳng lúc khởi động.**

1. Ranh giới sở hữu rõ ràng. Template là nội dung do app phát hành; bản sao là
   dữ liệu của người dùng. Trộn hai thứ vào một bảng khiến mọi câu hỏi về quyền
   ghi trở nên mơ hồ.
2. **Cập nhật template không được ghi đè nội dung người dùng đã sửa.** Đây là
   ràng buộc cứng. Với mô hình copy, nó đúng một cách tự nhiên: bản sao không có
   liên kết ghi ngược về template, nên nâng version template không chạm vào nó.
   Mô hình chèn-thẳng phải tự chống lại chính nó ở mỗi lần cập nhật.
3. Người dùng không bị ép nhận thứ họ không muốn. Chèn thẳng lúc khởi động là
   ghi vào dữ liệu cá nhân mà không hỏi.

**Idempotency là ràng buộc, không phải tối ưu.** Mở lại app hoặc nâng version
không được tạo deck trùng. Cụ thể:

- Quá trình seed/import kiểm tra theo `(source_template_id, source_template_version)`
  trước khi tạo — đã có bản sao từ đúng template và version đó thì không tạo nữa.
- Người dùng **cố ý** thêm cùng một starter deck lần thứ hai là hành động hợp lệ
  và khác hoàn toàn với việc app tự tạo trùng; luồng đó phải hỏi xác nhận rõ.
- Toàn bộ việc tạo bản sao (deck + card + study state) nằm trong **một
  transaction**, để app bị kill giữa chừng không để lại deck nửa vời.

**Ở MVP, `deck_templates` không cần là bảng runtime.** Template có thể chỉ là
asset JSON đóng gói theo app, đọc khi hiển thị danh sách starter deck. Nhưng khi
đưa vào database, ranh giới giữa template gốc và bản sao của người dùng phải rõ
ràng — đó là điều quan trọng, không phải việc nó nằm ở bảng hay ở file.

---

## AD-08 · Dữ liệu riêng tư và đường mở cho mã hoá

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-51…BR-54) · `product.md` |

**Quyết định.** MVP chưa có tài khoản, chưa có token, chưa mã hoá database. Nhưng
phạm vi "dữ liệu riêng tư" được định nghĩa rộng ngay từ đầu, và database layer
phải cho phép bổ sung mã hoá sau mà không viết lại.

**Coi là dữ liệu riêng tư ngay ở MVP:** nội dung deck và flashcard do người dùng
tạo, ghi chú, lịch sử học, file import, hình ảnh, audio, và dữ liệu backup.

Hệ quả cụ thể lên code:

- **Không log nội dung flashcard hoặc ghi chú, ở bất kỳ level nào.** Log ID thì
  được. Đây là ràng buộc dễ vi phạm nhất vì log nội dung là phản xạ tự nhiên khi
  debug — nên nó phải là quy tắc, không phải sự cẩn thận.
- **Media nằm trong thư mục riêng của ứng dụng**, không phải thư mục dùng chung
  hay bộ nhớ ngoài nơi app khác đọc được.
- **Export và backup chỉ chạy khi người dùng chủ động yêu cầu.** Không tự động,
  không nền, không "để cho tiện".

Khi Spring Boot xuất hiện: email, access token và refresh token là dữ liệu nhạy
cảm. Token lưu bằng secure storage, **không** lưu trong Drift, không xuất hiện
trong log. Lý do không để trong Drift là nó nằm ngoài vùng bảo vệ của keystore
nền tảng, và nó sẽ đi theo mọi bản backup của database.

**Đường mở cho mã hoá.** Chưa mã hoá ở MVP — dữ liệu học từ vựng không đủ nhạy
cảm để trả giá bằng độ phức tạp của SQLCipher. Nhưng việc mở kết nối database
phải nằm sau **một chỗ duy nhất** (`core/database/connection.dart`), để chuyển
sang `sqlcipher_flutter_libs` là sửa một hàm chứ không phải rà toàn bộ code.

Quyết định này cần xem lại nếu app hỗ trợ nội dung cá nhân tự do hoặc tài liệu
công việc — lúc đó phạm vi rủi ro khác hẳn từ vựng.

---

## AD-09 · Reset learning progress và scheduler generation

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-40…BR-50, BR-83, BR-84) · `use-cases.md` (UC-05, UC-07) · `data-model.md` |

**Quyết định.** Đổi scheduler trên deck đã có lượt học chỉ thực hiện được qua thao
tác **Reset learning progress**. Mỗi deck có `scheduler_generation`, tăng sau mỗi
lần reset.

**Reset giữ gì và xoá gì:**

| Giữ nguyên | Xoá / đặt lại |
|---|---|
| Deck và sub-deck | Active scheduler state của mọi card |
| Flashcard và nội dung | `due_at`, interval |
| Media, tag | `current_box`, ease factor, repetitions |
| Study answers cũ | Mastery state |
| | Session đang dở |

**Study answers cũ được giữ lại để tham khảo, nhưng không được dùng cho chu kỳ
mới.** Đó chính là việc `scheduler_generation` làm: mỗi dòng history, mỗi card
schedule và mỗi study session đều mang generation, nên "thuộc chu kỳ nào" là dữ
kiện có trong dữ liệu chứ không phải quy ước ngầm.

**Không chấp nhận kết quả từ session thuộc generation cũ.** Tình huống thật: người
dùng mở phiên ôn, để đó, vào Settings reset deck, rồi quay lại phiên cũ và bấm
đánh giá. Nếu không kiểm tra generation, kết quả đó sẽ ghi đè trạng thái vừa được
làm mới. Vì thế mọi thao tác ghi đánh giá phải so `session.scheduler_generation`
với generation hiện tại của deck và **từ chối** nếu lệch.

**Bất biến phải giữ:**

1. Một deck có đúng **một** active scheduler tại một thời điểm.
2. Toàn bộ card state của một deck thuộc **cùng một** generation — generation hiện
   tại của deck.

**Reset và đổi scheduler chạy trong một Drift transaction duy nhất.** Không có
trạng thái trung gian nào mà app bị kill có thể để lại. Nửa vời ở đây nghĩa là
một deck có card thuộc hai generation, hoặc scheduler mới với card state theo luật
cũ — cả hai đều là dữ liệu hỏng không tự phục hồi, và tệ hơn nhiều so với việc
reset thất bại sạch sẽ.

Sau reset, deck lại ở trạng thái "chưa có lượt học", nên scheduler mở khoá và chọn
lại được — đó là cơ chế duy nhất để đổi, và nó rơi ra tự nhiên từ định nghĩa của
khoá.

---

## AD-10 · Cây deck nhiều cấp, `root_deck_id`, và `content_type`

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-55…BR-72) · `use-cases.md` (UC-08, UC-09) · `data-model.md` |

**Quyết định.** Deck lồng được nhiều cấp — tối đa 10, root là cấp 1 (BR-55).
Root deck chỉ chứa deck con — không bao giờ chứa card trực tiếp. Mỗi deck không phải root mang `content_type` với ba giá
trị `unset` / `card` / `deck`, do **hệ thống tự duy trì** theo direct children
(BR-163).

### Vì sao `content_type` thay vì cho phép trộn

Một deck vừa chứa card vừa chứa deck con nghe linh hoạt, nhưng nó làm hỏng mọi
câu hỏi đơn giản về sau: "deck này có bao nhiêu card" phải trả lời theo hai
nghĩa; màn hình deck phải render hai loại danh sách; phiên ôn phải quyết định có
đi xuống nhánh con không. Ràng buộc "chỉ một loại" khiến mỗi màn hình có đúng một
hình dạng.

**Người dùng không chọn `content_type` khi tạo deck.** Bắt chọn trước là bắt quyết
định khi chưa có thông tin — lúc tạo deck "Unit 5" người dùng chưa biết nó sẽ chứa
card hay chia nhỏ tiếp. Lần tạo phần tử con đầu tiên tự nói lên điều đó, nên đó là
lúc xác lập.

**Lifecycle tự động hai chiều (BR-163, sửa từ M99.15).** Phần tử con **đầu tiên**
xác lập type; phần tử con **cuối cùng** rời đi mở khoá type về `unset`. Cả hai
chiều MUST nằm trong cùng transaction với mutation sinh ra chúng — create, delete
card, delete deck, move deck — nên một lần ghi hỏng rollback cả nội dung lẫn
type. Root deck nằm ngoài: nó luôn `deck`, kể cả khi không còn con (BR-58).

**Phương án bị loại — "reset thủ công có xác nhận" (BR-68 cũ).** Thiết kế ban
đầu bắt người dùng bấm một hành động riêng để gỡ type, với lý do "cấu trúc chỉ
đổi khi ai đó thực sự muốn". Nó giả định sai rằng `content_type` là lựa chọn của
người dùng — BR-60 cấm chọn, BR-62 tự xác lập — và cái giá là một deck rỗng bị
khoá loại mà lối thoát nằm trong action sheet. Ngoài ra check-rỗng-rồi-ghi ở
tầng UI là race giữa hai transaction, và mutation từ repository khác vẫn bỏ sót.

### Vì sao `root_deck_id` chứ không phải tra ngược từng cấp

Xác định root bằng cách đi ngược `parent_deck_id` cần đệ quy hoặc CTE, và **không
diễn đạt được thành một điều kiện JOIN đơn giản** — mà JOIN đó nằm trong query
nóng nhất của app (đếm card đến hạn theo deck).

Biểu thức `COALESCE(parent_deck_id, id)` từng xuất hiện trong tài liệu này và
**bị cấm** (BR-57): nó có nghĩa "cha, hoặc chính nó nếu không có cha", nên với
deck ở cấp 3 nó trả về deck cấp 2 chứ không phải root. Với cây một cấp nó đúng, và
đó chính là điều khiến nó nguy hiểm — nó chạy đúng cho đến khi ai đó tạo cấp thứ
ba.

`root_deck_id` là **denormalization có chủ đích**: root có `root_deck_id = id`,
mọi descendant mang cùng giá trị. Tra root là một phép so sánh cột, không phải
đệ quy.

Cái giá phải trả, và nó là cái giá thật: **di chuyển subtree phải cập nhật
`root_deck_id` cho toàn bộ subtree, trong một transaction** (BR-71). Bỏ sót một
node là tạo ra descendant trỏ sai root — dữ liệu hỏng im lặng, vì query vẫn chạy
và chỉ trả về kết quả thiếu. Validation phải kiểm tra được bất biến này (BR-72).

**Cycle bị cấm** (BR-69) và không được di chuyển deck vào chính nó hoặc descendant
của nó (BR-70). Một cycle khiến mọi phép duyệt cây thành vòng lặp vô hạn, và nó
tạo ra được chỉ bằng một thao tác kéo-thả sai.

---

## AD-11 · Trạng thái là dữ liệu tường minh, không phải suy luận

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-75…BR-86) · `data-model.md` |

**Quyết định.** `study_answers.kind` và `study_sessions.status` /
`end_reason` được **lưu tường minh** tại thời điểm ghi. Cấm suy ra chúng bằng cách
so sánh trạng thái trước và sau, hoặc bằng cách đoán từ dữ liệu khác.

**Vì sao, cụ thể.** Suy luận `kind` nghe rất hợp lý: "trước và sau giống
nhau thì là `relearning`". Nó sai ở đúng một trường hợp, và trường hợp đó không
hiếm — lượt `scheduled` trên card đang ở box 8 trả lời `remembered` cũng có
`previous_box == 8` và `next_box == 8` (BR-16). Suy luận sẽ gắn nhãn nó
`relearning`, và mọi thống kê về sau đều lệch mà không có gì báo lỗi.

Đây là một mẫu chung đáng nhận ra: **suy luận từ dữ liệu là đúng cho đến khi gặp
ca biên, và ca biên trong dữ liệu lịch sử thì không sửa lại được.** Một cột đã ghi
sai nhãn suốt sáu tháng không có cách nào tính lại, vì thông tin cần để tính đã
không được ghi.

Cùng lý do đó áp cho session: `abandoned` và `invalidated` đều là "session không
`completed`", nhưng chúng nói hai chuyện khác nhau về sản phẩm — một cái là người
dùng bỏ giữa chừng, một cái là hệ thống vô hiệu hoá. Gộp lại rồi đoán sau là mất
vĩnh viễn sự phân biệt đó. `end_reason` giữ nguyên nguyên nhân thay vì để lại một
mã lỗi chung.

---

## Ranh giới layer — không đổi so với CLAUDE.md

Các quyết định trên **không** nới lỏng bất kỳ ranh giới nào:

- `domain/` vẫn không import Flutter, Drift, hay `json_annotation`. Việc Drift là
  source of truth **không** cho phép kiểu Drift lọt vào domain — mapper ở
  `data/` vẫn bắt buộc.
- `presentation/` vẫn không chạm `data/`.
- Kiểm tra bằng `.claude/skills/flutter-architecture/scripts/check_architecture.sh`.

Cám dỗ lớn nhất ở dự án local-first là dùng thẳng class do Drift sinh ra làm
entity, vì chúng "trông giống nhau". Đừng — đó chính xác là cách AD-01 mất giá
trị, và nó chỉ lộ ra khi backend xuất hiện, lúc chi phí sửa cao nhất.

---

## Toolchain

**Phiên bản Flutter được pin. Con số nằm ở `.fvmrc` ở gốc repo — đó là vị trí
gốc duy nhất, tài liệu này MUST NOT chép lại nó** (§5). Chép ra chỗ thứ hai thì
sớm muộn hai chỗ lệch nhau, và lúc đó không ai biết chỗ nào đúng — đúng loại lỗi
mà việc pin sinh ra để phòng.

**Vì sao cần pin.** `pubspec.lock` khoá được dependency nhưng **không** khoá
được Flutter SDK. Trước M2.2 không có chỗ nào ghi phiên bản, nên hai máy có thể
dựng ra hai kết quả khác nhau mà không có tín hiệu nào báo. Đây không phải rủi
ro lý thuyết: M2.1 chạy trên 3.44.8 còn phiên hoàn tất phần Android của nó khởi
động trên 3.44.6, và không có gì phát hiện ra chênh lệch — nó lộ ra chỉ vì có
người đi so tay với commit message.

**Vì sao chọn `.fvmrc`** thay vì chỉ ghi vào tài liệu:

- máy đọc được. `subosito/flutter-action` nhận thẳng qua `flutter-version-file`,
  nên job CI ở M7 lấy đúng con số này mà không phải chép lại lần nữa
- là quy ước sẵn có của FVM để đổi SDK theo project, không phải định dạng tự
  nghĩ ra
- một dòng JSON, không kéo theo tooling nào nếu chưa dùng FVM

**Điều cần biết:** file này **khai báo**, không **cưỡng chế**. Chạy `flutter`
trực tiếp trên máy có version khác vẫn build được và không cảnh báo gì. Việc
biến pin này thành check thường trực nằm ở technical debt trong `wbs.md`.

**MUST** cập nhật `.fvmrc` trong cùng commit với lần nâng SDK, và ghi lý do nâng
vào WBS.

---

## AD-12 · Clean Architecture lồng, và tầng use case

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `feature_blueprint.md` · `flutter-feature-slice` skill · `flutter-architecture` skill · `CLAUDE.md` |

**Quyết định.** Mỗi feature dùng cấu trúc thư mục Clean Architecture lồng, tên
**số nhiều**, và có tầng use case đầy đủ — một use case cho mỗi interaction.

```
lib/features/<feature>/
├── domain/       entities/ · repositories/ · models/ · usecases/ · failures/
├── data/         repositories/ · mappers/ · datasources/ · models/
└── presentation/ screens/ · controllers/ · states/ · widgets/ · providers/
```

**Hướng phụ thuộc:** `presentation → domain use case → domain contract ← data
impl`. Không tầng nào nhảy qua tầng nào. Controller **không** đọc repository.

**Vì sao số nhiều.** Đây là quy ước ngành (Clean Architecture, template Flutter
của Reso Coder, Very Good Ventures, Android architecture guide). Số ít từng là kỳ
vọng của `check_suffix` trong `check_architecture.sh`, và vì layout phẳng cũng
không có thư mục nào tên `/domain/entity/`, **cả sáu check khớp 0 file** — chúng
chạy, không thấy gì để kiểm, và pass. Một check không thể đỏ thì đọc như là có
bảo vệ. Script đã trỏ lại sang tên số nhiều và mở rộng thành 14 check.

**Thư mục không thay được suffix.** `entities/deck_entity.dart`, không phải
`entities/deck.dart`. Guard khớp trên **tên file**, và nhiều scope chọn file theo
đó, nên file lệch suffix rời khỏi phạm vi đúng những rule dành cho nó.

### Tầng use case: cái gì vào, cái gì không

**Vào use case: validation.** Trước AD-12, `DeckEntity.nameProblem` chạy trong
controller *và* lần nữa trong repository. AD-12 chuyển nó vào use case, và **vẫn
chưa đủ** — xem AD-13: cho một lần submit, BR-01 thực ra chạy **ba** lần, vì screen
còn tự dẫn lại vấn đề từ chuỗi thô để biết field nào cần tô đỏ. Ba chủ sở hữu,
được phép lệch nhau, trong khi tài liệu nói là một.

Controller chỉ giữ phần thực sự là presentation: double-submit guard, cờ
submitting, kiểm `ref.mounted` sau await, và map `Failure` sang state per-field.

**KHÔNG vào use case: luật cần cây tại thời điểm ghi.** BR-55 (độ sâu), BR-62
(content lock của con đầu), BR-163 (auto-unset khi con cuối cùng biến mất) và bộ
rule move UC-09 đều chạy
trong `runInTransaction`. Đặt chúng lên use case là đẩy phần kiểm ra **ngoài**
transaction — tạo race giữa lúc kiểm và lúc ghi. Luật sẽ nằm ở chỗ gọn hơn và
**sai**. Use case là điểm vào; luật hình cây thuộc về nơi có transaction.

**Refusal đi bằng một `Set` vấn đề có type, không phải `Failure.reason`.** Một
form có thể sai hai field cùng lúc — tên trống *và* chưa chọn scheduler — mà
`reason` chỉ giữ một giá trị.

AD-12 chọn `Map<String, String> fieldErrors`. **Cả hai nửa của lựa chọn đó đều
sai**, và AD-13 sửa: key là chuỗi literal lặp lại (`'name'`, `'schedulerType'`)
không gì kiểm được, còn value là câu chữ mà UI bị **cấm** render — nên presentation
bỏ qua value và tự dẫn lại vấn đề từ input thô, đó chính là *lý do* BR-01 có chủ sở
hữu thứ ba. Nay là `Set<Enum> problems`: identifier có type, và không còn message
nào để ai đó bị dụ dùng.

**`Failure.reason` là `Enum?` trên base type.** `Enum` vì `core/` không được
import feature; trên base vì `Failure` là `sealed` nên feature **không thể** tự
thêm subtype — đó cũng là lý do `domain/failures/` không bao giờ chứa được một
`Failure` con, và thứ nó chứa là enum lý do cùng hàm rule thuần sinh ra chúng.

**Hệ quả cụ thể lên code:**

- Use case nhận contract ở `domain/repositories/`, không nhận implementation.
- `presentation/providers/` chỉ làm dependency wiring. `_provider` đã được thêm
  vào suffix cho phép của `presentation/` **và** loại khỏi scope
  `widget_ui_files`, vì một file làm wiring thì đọc repository là đúng định nghĩa
  của nó. Thứ gì giữ state hay lệnh là `_controller`.
- `app/di/` là composition root — chỗ duy nhất `*RepositoryImpl` được gọi tên.
  AD-12 đặt **cả khai báo** `deckRepositoryProvider` ở đó, khiến
  `features/deck/presentation/` phải import `app/`; AD-13 tách hai việc đó ra.
  Use case không có implementation nào để chọn, nên wiring của nó vẫn đi cùng
  feature.
- Provider trong `features/*/presentation/` phải `autoDispose`
  (`test/app/provider_convention_test.dart` cưỡng chế).

**Đánh đổi đã nhận.** Sáu use case write giữ validation; bốn use case read thì
mỏng — chúng gần như chỉ chuyển tiếp. Chúng tồn tại vì **tính nhất quán**: một
feature mới là một lần clone chứ không phải một lần phán xét ở từng operation.
Đây là chỗ lệch có ý thức với dòng "tạo use case chỉ khi nó có logic thật" trong
CLAUDE.md, và CLAUDE.md đã được sửa để nói ra điều đó thay vì để hai tài liệu mâu
thuẫn.

**Phương án đã bị loại:** giữ layout phẳng (bỏ, vì chủ dự án muốn Clean
Architecture đầy đủ trước khi clone sang feature thứ hai); tạo
`features/_feature_template/` (bỏ — một thư mục dưới `lib/` không thể trơ:
`flutter analyze` compile nó, 66 rule của guard chạy trên nó,
`no_hardcoded_strings_test` quét nó, và một `*_screen.dart` bên trong sẽ đòi
strict visual audit riêng; Deck kèm README của nó là ví dụ đã compile và đã được
gate).

## AD-13 · Một interaction là một read; hướng phụ thuộc chỉ đi xuống

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `feature_blueprint.md` · `lib/features/deck/README.md` · `flutter-project-setup` skill · `flutter-data-layer/references/networking.md` · `feature_checklist.md` · `wbs.md` |

**Quyết định.** Một interaction của người dùng đọc dữ liệu bằng **một** read
interaction — một contract method, một statement, một snapshot. Một luật input
thuộc về **một type**, không phải một tầng. Và `features/` không bao giờ import
`app/`: composition root thấy feature, không có chiều ngược lại.

**Bối cảnh.** Sau AD-12, Deck được rà lại như thể nó là feature *mới* — đọc code
thay vì đọc tài liệu về code. Bốn khiếm khuyết còn sống, và cả bốn đều đã pass mọi
test đang có.

### 1 · BR-01 có một chủ sở hữu, và là một *type*

`DeckEntity.nameProblem` + `validateName` bị xoá. Thay bằng value object
`DeckName` (`domain/models/deck_name_model.dart`): constructor private, `parse`
trả về hoặc giá trị hoặc một `DeckValidationProblem` có type. Contract repository
nhận `DeckName`, nên câu "cái này đã validate chưa?" được trả lời bởi **signature**
chứ không phải bởi việc đọc implementation.

Chuyển một luật vào một *tầng* chỉ ngăn được trùng lặp bằng **quy ước**; chuyển nó
vào một *type* ngăn được về mặt cấu trúc. Giới hạn đo **sau** khi trim, và tên quá
dài bị từ chối chứ không bị cắt — không tồn tại giá trị đã cắt để caller lỡ ghi.

**BR-11 cũng có hai chủ sở hữu, và cái thứ hai sai theo hai cách.**
`_requireRealScheduler` trong repository ném
`ValidationFailure(schedulerMissing)` khi nhận `SchedulerType.unknown`. Thứ nhất,
nó dư: `SchedulerType.unknown` **không có** `dbValue` — write đã bất khả thi chứ
không chỉ bị từ chối. Thứ hai, nó báo một vấn đề *form* cho một trạng thái người
dùng không thể gây ra và không thể sửa, nên "hãy chọn một scheduler" sẽ hiện lên để
trả lời một lỗi lập trình. Đã xoá; luật nằm ở **type**.

Dấu hiệu cấu trúc cho thấy việc xoá là đúng: `deck_repository_impl.dart` sau đó
không còn dùng `deck_validation_failure.dart`, và analyzer báo import không dùng.
Tầng data giờ không tham chiếu luật validation nào.

### 2 · Read model của một screen đến từ một statement

Hai screen từng dựng read model từ hai query, và cả hai **trông** đúng vì với
database im lặng thì hai snapshot cho cùng câu trả lời.

- **Deck screen** watch `childDecks` rồi await `getDeckById` mỗi lần emit, kèm một
  comment khẳng định hai dữ kiện "arrive together". Không đúng. Action set tính từ
  `content_type` **và** từ việc children rỗng (BR-163), nên một rename hoặc một
  create rơi vào giữa hai lần đọc tạo ra màn hình ghép từ hai thời điểm. Nay:
  `watchDeckDetail` — một `LEFT JOIN`, một contract method, `DeckDetail` nằm ở
  `domain/models/` vì repository trả về nó. Không có row nào nghĩa là deck đã mất
  (`NotFoundFailure`); một row với `child` null nghĩa là deck còn và không có con.
  Hai trạng thái đó phải phân biệt được: một là route chết, một là empty state.
- **Move picker** đọc mọi deck, rồi hỏi lại deck nguồn — một deck đã có trong danh
  sách nó vừa nhận, đọc lại từ snapshot **muộn hơn**. Nay nguồn lấy từ cùng lần
  emit đó; không có nghĩa là nó đã bị xoá ở screen khác, và đó là
  `NotFoundFailure` có type.

**Cách chứng minh mới là phần quan trọng.** Không assertion nào về *giá trị* phân
biệt được hai thiết kế, nên `deck_detail_read_test.dart` **đếm câu SQL** qua một
`QueryInterceptor` thật. Fault injection: dựng lại shape hai-read → đúng hai test
đếm đó đỏ, chín test hành vi còn lại vẫn xanh. Nguyên tắc: khi một tuyên bố nói về
*cách* dữ liệu được đọc chứ không phải nó trả về gì, phải **đo**.

### 3 · Due count hết hạn cùng snapshot sinh ra nó

`rootDeckSummaries` trả thêm `nextDueAt` — `MIN(due_at) WHERE due_at > :now`, một
scalar subquery trong **cùng** statement với các count. Vì mọi count đều tương đối
với `now` của lần đọc, mỗi count có một thời điểm hết hạn; đọc riêng thì thời điểm
đó tính từ một trạng thái database khác với các count, và lần refresh sẽ rơi vào
thời điểm không đúng với cả hai.

Contract đổi tên theo thứ nó trả về: `watchRootDeckList` → `RootDeckListSnapshot
{ decks, nextDueAt }`.

`> :now` **chặt**, và điều đó có ý nghĩa: một card đến hạn đúng tại `:now` đã được
tính là due, nên nếu bao gồm nó thì delay bằng 0, guard chống timer delay-0 sẽ từ
chối arm, và boundary thật sự kế tiếp **không bao giờ** được hẹn. Cùng một lỗi cũ,
tái sinh bằng một ký tự. Có test cho ký tự đó.

`DeckListNow` giờ có hai trigger: app resume, và một `Timer` một-lần arm theo
`nextDueAt`. Trước đó chỉ có resume, và comment ghi rằng timer chu kỳ đã được "cân
nhắc và loại" vì resume bắt được cùng boundary — **không đúng**: người dùng ngồi ở
danh sách khi một card đến hạn thấy badge nói 3 trong khi session nó mở phát ra 4.
Thay thế cũng **không** phải timer chu kỳ: là một lần thức được hẹn từ dữ liệu, nên
screen không có gì sắp đến hạn thì không có timer nào.

`kMaxDueBoundaryDelay = 1 ngày` là **trần**, không phải chu kỳ: trên web `Timer` là
`setTimeout`, delay là số millisecond 32-bit có dấu, nên boundary quá ~24,8 ngày
fire ngay và biến một lần hẹn thành busy loop. Web là kênh E2E nên phép tính đó
phải an toàn ở đó.

**Clock có một chủ sở hữu.** Hai repository impl từng default clock về
`DateTime.now()` khi không ai truyền. Điều đó khiến "now" là hai thứ: một provider
cả cây override được, và một static private không gì với tới — và cái khó với tới
là cái thắng trong production. `clock` nay là `required`, fallback bị xoá,
`app/di/` truyền `clockProvider` vào. `lib/features/` không còn `DateTime.now()`.

### 4 · `features/` không import `app/`

Hai chiều phụ thuộc sai cùng tồn tại: `presentation/providers/` import
`app/di/deck_repository_provider.dart`, và hai screen import
`app/router/route_names.dart`.

- **Repository provider đảo chiều.** Feature khai báo cái nó cần —
  `features/<feature>/di/<feature>_repository_provider.dart`, kiểu là contract
  domain, thân hàm **throw**. `app/di/repository_bindings.dart` quyết định cái gì
  thoả mãn nó, `buildRootWidget` cài đặt bằng một dòng. Giá phải trả: thiếu binding
  là `StateError` lúc đọc đầu tiên chứ không phải lỗi compile — bị chặn lại bởi hai
  test, một xác nhận root thật có bind, một xác nhận đọc khi chưa bind thì lỗi kèm
  message chỉ đúng chỗ cần sửa.
- **`di/` là một tầng**, không phải thư mục cho tiện. Nó đặt ở đó chứ không ở
  `presentation/providers/` vì `provider_convention_test.dart` cấm `keepAlive`
  dưới `features/*/presentation/`, mà một handle repository thì phải `keepAlive`.
  Luật đó đúng; chỗ đặt ban đầu sai. Phương án `autoDispose` bị loại: nó dựng lại
  repository mỗi lần điều hướng và chạy lại query đầu tiên của mỗi screen vô ích.
- **`RouteNames` + `RoutePathParams` chuyển sang `core/navigation/`.** Đảo chiều
  không phải phương án: một route thuộc về **bảng route**, không thuộc về một
  screen, nên router không thể lấy tên từ features. Chúng là từ vựng không bên nào
  sở hữu — đúng lập luận của `clockProvider`. `RoutePaths` **cố ý không** đi theo:
  một path là hợp đồng URL của app và chỉ bảng route xác nhận nó.

**Cưỡng chế:** `check_architecture.sh` rule 4b + `test/app/architecture_boundary_
test.dart`. Cả hai fault-inject.

### Hệ quả lên harness — guard đọc *code*, không đọc văn xuôi

Ba guard đã báo sai trên chính phần giải thích của chúng, và cả ba được sửa ở
**rule** chứ không phải bằng cách viết lại comment cho lọt:

| Guard | Nó khớp cái gì | Sửa |
|---|---|---|
| `command_query_separation_test.dart` | đếm method public **theo file**; cấm *chữ* `navigateTo` kể cả trong comment giải thích chính luật đó | parse AST bằng `package:analyzer`: class là object riêng, comment và string literal không phải node |
| `deck_card_boundary_test.dart` | `contains('part of')` khớp một comment nói file này **không** là part of cái gì | strip comment trước khi match |
| `memox.testing.no_real_clock_in_test`, `common.no_commented_out_code` | doc comment *nêu tên* `DateTime.now()`; câu văn xuôi gãy dòng `// for this assertion.` | pattern neo ở đầu dòng không vượt qua `//`; mỗi alternative đòi cú pháp thật theo sau keyword |

AST cho phép vẽ một phân biệt mà regex không vẽ được: có **ba** loại notifier, không
phải hai — command controller (`build` trả `SubmitState`: chỉ `build`/`submit`/
`reset`), query controller (`build` trả `Stream`/`Future`: chỉ `build`), input-state
notifier (còn lại: `build` + tối đa một mutator).

**Và luật quan trọng nhất về guard:** một rule không quét gì thì pass, và đọc như
là có bảo vệ. Mọi guard giờ **in ra số nó đã quét** và coi 0 là lỗi. Việc đó phát
hiện một lỗ đang sống: khi thiếu `lib/`, `check_architecture.sh` exit **0** với câu
"nothing to check yet". Trung thực trước khi project tồn tại; là một guard xanh cho
một working directory sai sau đó.

**Phương án đã bị loại:** viết một regex mới phức tạp hơn thay vì AST (bỏ — mọi
khiếm khuyết ở trên đều là tính chất của *text*, thêm pattern không đổi được điều
đó); ADR chứng minh `features/ → app/` là bất khả kháng (bỏ — nó khả thi, chỉ tốn
một dòng ở composition root); một timer chu kỳ cho due count (bỏ — nó đánh thức
database theo lịch để đổi một con số không ai đang xem, còn boundary nó bắt thì một
lần hẹn theo dữ liệu bắt chính xác hơn).

## AD-14 · Hệ màu và chiều sâu: seed, role, và cue theo mode

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `docs/checklist.md` (7.1 design tokens) · `wbs.md` · `design_audit/color_system_report.md` |
| **Decision** | Mọi màu trung tính suy từ một seed; mỗi role là một hue qua một bộ sinh; chiều sâu là **một mục tiêu đo được**, không phải một cơ chế cố định — mỗi mode được dựng nó bằng thứ mode đó có. |

### Vì sao có quyết định này

Hệ màu của app từng đúng ở hầu hết các chỗ mà không ai viết ra tại sao. Hậu quả
đo được ở M4.10f: light mode có nền mang seed nhưng **card là trắng thuần không
hue**, sáu token nữa cũng vậy, và shadow mang seed ở light còn dark là đen tuyệt
đối. Không cái nào là quyết định — chúng là chỗ trống chưa ai lấp.

Tệ hơn: **hai đoạn comment bị đọc thành luật**. `app_colors.dart` viết rằng thang
surface hoạt động "without a shadow being asked to carry the hierarchy", và
`mx_card.dart` viết "flat by design". Hai milestone sau đó trích chúng như một
ràng buộc — kể cả để bác bỏ một ceiling của bản brief audit — trong khi không có
AD, không BR, không test nào đứng sau, và `docs/checklist.md` thì vẫn đang yêu cầu
một Elevation token chưa ai làm. Chủ dự án cuối cùng phải nói thẳng rằng app **cần**
độ nổi. AD này tồn tại để lần sau không phải suy ra luật từ văn xuôi.

### Quyết định

**1 · Seed là nguồn của mọi trung tính.** `AppColors.seed` (hue 240). Mọi
neutral — surface, page, border, muted text, shadow, scrim — phải mang một trace
của nó. Công thức chuẩn tắc là
`Color.alphaBlend(seed.withValues(alpha: a), base)`, **precompute thành hằng số**,
không phải một màu trong suốt đặt vào slot vẽ.

Một trung tính không có hue không phải "trung tính hơn": nó là một trung tính
**không thể đi theo seed khi seed đổi**. MX-VIS-002 rule R9 chặn.

**2 · Mỗi role là một hue qua một bộ sinh.** `primary`, `secondary`, `tertiary`,
`error`/`danger`, `success`, `warning`, `info`. Fill và container của cùng một
role phải nằm trong 5° của nhau (rule R3). Không chọn tay một biến thể sáng hơn
cho một badge.

Lỗ đã biết: `success`, `warning`, `info` mới có fill. Container / border / focus
sẽ derive khi có caller thật, không derive trước.

**3 · Border lấy hue từ chủ của thứ nó bọc.** Container trung tính (card, input
nghỉ, divider, list tile, sheet) → từ seed. Component thuộc role (outline button
nguy hiểm, input lỗi, trạng thái focus) → từ hue của role đó.

**4 · Chiều sâu là mục tiêu đo được, không phải cơ chế cố định.**

Đây là phần đắt nhất và là phần dễ bị viết sai thành luật nhất. **Cái phải giữ
bằng nhau giữa hai mode là tổng độ nổi của một card khỏi trang nó nằm trên** —
hiện 7.75 L\* ở light và 7.70 ở dark. Mỗi mode tự do dựng con số đó bằng thứ nó có:

| | bậc surface | shadow | border |
|---|---|---|---|
| light | 2.15 L\* | +5.6 L\* (alpha 0.07) | 1.50:1 |
| dark | 7.70 L\* | **không có** | 1.82:1 |

Dark không vẽ shadow vì **đo được**, không phải vì thẩm mỹ: trang dark nằm ở đáy
thang lightness (L\* 3.86), nên một shadow ở alpha 0.20 chỉ dịch được 0.26 L\*.
Material 3 bỏ shadow ở dark vì cùng lý do. `app_elevation_test.dart` **dẫn lại**
phép đo đó chứ không trích nó, nên nếu palette đổi tới mức shadow dark trở nên
thấy được thì test đỏ và quyết định được xem lại.

**Hệ quả: hai luật cũ đã bị thay, và cả hai từng đúng.** "Border phải khớp giữa
hai mode" đúng khi border là cue duy nhất; sai ngay khi light có shadow. "Mỗi bậc
ladder ≥ 3 L\*" đúng khi ladder là toàn bộ hierarchy; light nay là 2.0 vì shadow
gánh phần chênh. Một luật viết cho một mode chỉ có một cue thì hết hiệu lực khi
mode đó có hai.

**5 · Mọi thứ được vẽ phải đến từ theme của app, kể cả khi Flutter có mặc định.**
Một màu tồn tại như mặc định framework thì **vô hình với mọi phép quét mã nguồn**
— đó là cách `Colors.black54` làm barrier sau mỗi dialog và sheet sống sót qua
trọn một cuộc audit màu (M4.10m). Component nào app dùng thì app khai báo theme
cho nó.

**Một token đúng vẫn có thể sai ở vai trò khác.** `primary` là fill của nút, và
`primaryDark` được giữ ở luminance thấp để một filled button không thành thứ sáng
nhất trên trang navy. Dùng chính nó làm **focus ring** thì đo được 2.90:1 trên
`surface` và 2.11:1 trên `secondaryContainer` — dưới ngưỡng 3:1 mà WCAG 1.4.11
đòi ở một chỉ báo đồ hoạ (M4.10ap). `focusRing` là token cho vai trò đó, và đây
là cùng một lập luận đã đưa progress indicator rời khỏi `primary` ở M4.10m.
**Đo trên nền thật, không trên một nền danh nghĩa:** `primaryDark` đạt 3.29:1
trên `background`, nên một phép kiểm chỉ dùng nền trang sẽ pass và bỏ sót cả hai
nền mà control được focus thực sự nằm lên.

**Và khai báo component là chưa đủ — phải khai báo đủ *state*.** `ChipThemeData`
có `backgroundColor` và `selectedColor` nên nhìn qua tưởng đã xong; Material vẫn
trả lời cho disabled, hover, focus và press. Câu trả lời của nó cho disabled là
`onSurface` ở **alpha** 12% — đúng thứ R7 cấm — và cho disabled-selected là
nguyên vẹn `secondaryContainer`, tức một pill không bấm được trông y hệt pill
bấm được (M4.10ao). Slot state-aware (`color`, `WidgetStateBorderSide`,
`WidgetStateColor` trong `labelStyle`) là nơi quyền sở hữu thật sự nằm.

### Nguồn của giá trị token đã đổi (M4.10p)

Khi AD này được viết, `lib/core/theme/` là nơi duy nhất định nghĩa một token.
**Nay không còn.** Chủ dự án đưa một design system dựng ở claude.ai/design về
`design_system/` và quyết định: **`design_system/tokens/*.css` là chuẩn cho
*giá trị* token**. Dart lệch thì Dart sửa theo, không phải ngược lại.

Đổi *nguồn*, không đổi *luật*. Năm quyết định ở trên vẫn nguyên: seed vẫn là gốc
của mọi trung tính, chiều sâu vẫn là mục tiêu đo được, mọi thứ được vẽ vẫn phải
đến từ theme. Cái đổi là ai chọn con số điền vào.

Hai giới hạn, cả hai đều rút ra từ lần áp đầu tiên chứ không phải phòng xa:

- **Giá trị của design không tự nhất quán với văn xuôi của chính nó.**
  `design_system/readme.md` viết "danger carries the most saturation"; hex của nó
  làm `warning` to nhất ở light (0.801 so với 0.634). Khi hai nửa của design cãi
  nhau, giá trị thắng — vì giá trị là thứ được cho quyền — nhưng mâu thuẫn đó là
  của design, không phải của repo, và `app_palette_test.dart` ghi lại toàn bộ
  phép đo thay vì lặng lẽ nới luật.
- **Một giá trị đúng vẫn có thể bị dùng sai.** Lấy `--color-success` xong, một
  nhãn 14px tụt xuống **4.30:1** trên `secondaryContainer`. Strict visual audit
  bắt được, và lời giải cũng nằm trong design: `VerdictAction` của nó giữ nền
  trung tính "vì một lớp tint cùng hue với nhãn ăn mất tương phản đúng lúc nhãn
  quan trọng nhất". **Theo một token là theo cả cách design dùng nó, không chỉ
  mã hex.**

Nguyên tắc mang token về: **token đi cùng component cần nó, không đi trước.**
`--color-progress-*` và `--color-streak-container` đã về ở M4.12 cùng
`MxProgressBar` và due chip, và nay có counterpart trong `AppSemanticColors`.

Còn đúng **một** token cố ý chưa mang về: `--color-streak`. Nó là nhãn của màn
streak — màn đó chưa tồn tại — và nó còn là **hue thứ năm** (cam), nằm ngoài một
accent và bốn semantic mà chính readme của design cho phép. Due chip cần một
foreground nên `onStreakContainerLight` được dẫn xuất riêng: `--color-streak`
đo **3.12:1** trên container của chính nó ở 11px semibold, dưới ngưỡng 4.5 của
chữ nhỏ.

Danh sách này không còn được duy trì bằng tay. `css_token_parity_test.dart` bắt
mọi `--color-*` mà Dart chưa có lập trường — mang về, hoặc ghi lý do — nên một
token thêm vào kit sẽ làm đỏ test thay vì trôi qua im lặng.

### Đánh đổi đã nhận

- **Tint làm card tối đi.** Bậc surface light tụt 3.46 → 2.15 L\*. Trả bằng shadow
  và bằng việc nới ngưỡng ladder, không phải bằng cách bỏ tint.
- **Precompute buộc phải chọn một nền.** `disabledSurfaceTint` blend trên
  `surface`, nên đúng ở form sheet và dialog, hơi sáng ở nút đặt thẳng trên page.
  Chính khoảng cách đó là lý do translucency tại điểm vẽ bị cấm.
- **Shadow và scrim được miễn trừ khỏi luật precompute**, vì nền của chúng theo
  định nghĩa là bất cứ thứ gì phía sau.

### Phương án đã bị loại

- **Nhận ceiling 1.6:1 cho border khi chưa có cue thứ hai** (bỏ ở M4.10f, nhận ở
  M4.10h) — hạ border trước khi có shadow là đổi một cái khung quá đậm lấy không
  có ranh giới nào.
- **Giữ card trắng thuần** (bỏ ở M4.10i) — nó là lựa chọn hợp lệ, nhưng nó để một
  surface duy nhất nằm ngoài hệ, và sau khi có shadow thì chi phí lightness không
  còn là lý do giữ.
- **Mở strict visual audit sang overlay** (bỏ ở M4.10m) — auditor duyệt một màn
  hình ở trạng thái nghỉ, trong khi một nửa render tree của overlay là nội dung
  người dùng đang bị cố ý ngăn không cho đọc. Làm nó xanh cần một danh sách
  allowance khẳng định chữ không đọc được là chấp nhận được.
- **Thêm tuỳ chọn surface cho `MxListTile`** (bỏ ở M4.10n) — không caller nào cần,
  và tấm ảnh mới là thứ sai chứ không phải component.


## AD-15 · `presentation/widgets` chia bốn bucket cố định, sâu đúng một tầng

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `CLAUDE.md` · `.claude/skills/flutter-architecture/SKILL.md` · `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md` · `lib/features/deck/README.md` |
| **Decision** | Mọi file trong `presentation/widgets/` của một feature nằm trong **đúng một** trong bốn bucket — `sections/`, `items/`, `overlays/`, `support/` — và sâu **đúng một tầng**. Danh sách bucket là bất biến của toàn app: thêm hay đổi tên bucket là sửa AD này trước, không phải tạo folder. |

### Vì sao có quyết định này

`deck/presentation/widgets/` đạt 18 file phẳng ở M4.10ak, và cái giá không phải
là đếm file: section của màn hình, item lặp trong danh sách, luồng modal và
mapping hiển thị **trộn vào nhau**, trong khi mọi tên file đều mở đầu bằng
`deck_` nên prefix không còn nói được file nào chịu trách nhiệm gì. Deck là
slice mẫu — feature sau **clone từ nó** — nên cây phẳng này sắp được nhân bản:
mỗi feature sẽ tự phát minh cách xếp riêng khi nó lớn lên, và toàn app mất chung
một bản đồ.

Phương án tự nhiên nhất — group theo màn hình hay theo flow — diễn đạt domain
tốt, nhưng taxonomy của nó **khác nhau giữa các feature**: deck có "level",
card có "editor", study có "session". Bốn bucket cố định đổi một chút sức diễn
đạt lấy một thứ đáng hơn: câu hỏi "widget này sống ở đâu" có **cùng một câu trả
lời** ở mọi feature.

Và một quy ước chỉ nằm trong tài liệu sẽ lệch — đó là bài học đã trả tiền ở
M4.10 (sáu suffix check từng match **zero file** mà vẫn pass). Vì vậy AD này
chỉ tồn tại cùng enforcement bằng máy, ghi ở mục Enforcement bên dưới.

### Quyết định

| Bucket | Trách nhiệm | Được chứa | Không được chứa |
|---|---|---|---|
| `sections/` | Các vùng màn hình compose trực tiếp vào body/chrome | subheader, toolbar, summary, body switcher, search results, error/notice mà screen tự đặt | dialog, sheet, phần chỉ item dùng |
| `items/` | Item lặp trong danh sách và các mảnh **chỉ** item đó dùng | tile/card/row, glyph well, chip trạng thái, action pill của item | section màn hình, luồng modal |
| `overlays/` | Luồng UI phủ lên màn hình | form, dialog, action sheet, bottom sheet, **và hàm `showX` mở chúng** | list body, item thường |
| `support/` | Hỗ trợ presentation dùng xuyên ≥ 2 bucket | mapping enum/failure sang ARB, extension render-only | business rule, provider, helper dùng toàn app |

Câu hỏi đặt chỗ, mỗi bucket một câu, trả lời theo thứ tự và dừng ở câu "có"
đầu tiên:

1. Nó **phủ lên** màn hình (mở bằng `showModalBottomSheet`/`showDialog`)? → `overlays/`
2. Nó là **hàng lặp lại** trong danh sách, hoặc mảnh chỉ hàng đó dùng? → `items/`
3. Màn hình **compose nó trực tiếp** vào body hay chrome? → `sections/`
4. Nó phục vụ **nhiều hơn một** bucket ở trên? → `support/`

Quy ước đi kèm, mỗi dòng là một luật:

- Sâu đúng một tầng: `presentation/widgets/<bucket>/<file>_widget.dart`. Không
  file Dart nào nằm trực tiếp trong `widgets/`, không nesting sâu hơn bucket.
- Bucket chỉ tạo khi có nội dung thật — không scaffold folder rỗng.
- Không barrel `index.dart`/file export: import site phải nêu đích danh file,
  vì guard chọn scope theo đường dẫn import được viết ra.
- Folder **không** thay suffix (`items/deck_tile_widget.dart`, không phải
  `items/deck_tile.dart`) — các guard chọn file theo suffix, sai suffix là file
  rời khỏi luật một cách im lặng.
- Widget chỉ được promote sang `lib/shared/` khi có caller thật từ feature thứ
  hai — bucket không đổi luật này, nó ghi ở blueprint từ trước.

Hai chi tiết đã cân nhắc chứ không phải bỏ sót:

- **`support` là danh từ khối, không phải số ít sai luật.** Quy ước "plural
  folder names" áp cho folder đếm được; tiền lệ cùng loại là
  `design_system/components/feedback`. Đổi thành `supports/` đúng ngữ pháp máy
  nhưng sai ngữ pháp người.
- **`test/features/deck/presentation/support/`** (harness của test) trùng chữ
  với bucket `support/` là **trùng hợp** — hai quy ước không liên quan, và
  bucket không áp cho cây test: test nhóm theo behavior, không mirror widget.

### Enforcement — ba nơi giữ luật, đổi theo đúng thứ tự này

1. **AD này** — danh sách bucket canonical. Đổi ở đây trước.
2. **`test/app/architecture_boundary_test.dart`** — chủ sở hữu hình dạng đầy đủ:
   đúng bốn tên, không file ở gốc `widgets/`, không nesting sâu hơn một tầng,
   kèm bằng chứng anti-vacuous **mức app** (suite phải thấy ≥ 1 file bucket ở
   đâu đó; feature chưa có widget không bị fail oan).
3. **Guard `memox.architecture.widgets_grouped_into_buckets`**
   (`memox-architecture-rules.yaml`) — lưới thứ hai, chạy trong `dod_check` và
   CI. Dùng matcher `file_path` (thêm ở M4.10am): pattern khớp trên đường dẫn
   tương-đối-repo, target set khoẻ mạnh là toàn bộ file widget. Bản nháp đầu
   dùng `file_name` với pattern never-match trên include/exclude đẽo gọt — bị
   chính guard bắt bằng `guard.config.rule_without_targets`, vì trạng thái
   khoẻ mạnh của nó là target set rỗng. Giữ lại chi tiết này để không ai thử
   lại cách đó.

`check_architecture.sh` **không** giữ luật bucket — nó sở hữu suffix, và chỉ
suffix. Một luật hai bản trong hai script là hai bản sẽ trôi khỏi nhau.

### Phương án bị loại

- **Group theo màn hình / theo flow** — diễn đạt domain tốt hơn nhưng taxonomy
  khác nhau giữa các feature; mất chính thứ AD này mua: một bản đồ chung.
- **Bucket thứ năm `feedback/`** cho error/notice — đã đề xuất và rút: cả hai
  đều được screen compose trực tiếp nên qua câu hỏi 3 của `sections/`, và bốn
  bucket rẻ hơn năm ở đúng chỗ đắt nhất — số nhánh của câu hỏi đặt chỗ.
- **Mirror bucket sang cây test** — đảo hơn 30 file test để thu về zero thông
  tin; test nhóm theo behavior từ trước và giữ nguyên.
- **Barrel export** — che import site khỏi guard và biến mọi đổi tên thành
  breaking change hai chỗ.

---

## AD-16 · "Đầu ngày học" vào từ composition root; scheduler trả số ngày, không trả thời điểm

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-105) · `data-model.md` · `wbs.md` |
| **Decision** | `StudyScheduler.next()` trả về **số ngày** cùng trạng thái mới của thẻ, không bao giờ trả `due_at`. Việc quy "N ngày nữa" thành một thời điểm UTC neo ở 00:00 giờ địa phương do một collaborator của domain đảm nhiệm, và múi giờ vào từ composition root như `clockProvider`. |

### Vì sao có quyết định này

BR-105 đổi mốc đến hạn từ `now + N*24h` sang đầu ngày lịch. Nghe như một phép
tính, nhưng nó kéo theo một thứ `domain/` không được phép biết: **múi giờ**.

Ba chỗ có thể đặt phép quy đổi, và hai chỗ sai:

| Đặt ở | Vì sao không |
|---|---|
| `next()` nhận thêm `dayStart` | Trộn hai luật độc lập vào một hàm: công thức SRS (BR-15…BR-19) và ranh giới ngày (BR-105). Mọi test ma trận 8 box × 2 action từ đó phải dựng một mốc ngày để kiểm một phép cộng số nguyên |
| Repository làm tròn khi ghi | Một luật nghiệp vụ nằm trong `data/`, và `next_due_at` ghi vào `study_answers` sẽ lệch với thứ scheduler vừa nói — lịch sử không còn tái tạo được |

Nên `next()` trả `intervalDays`, và một value object của domain nhận `now` cùng
offset để tính mốc. Ma trận scheduler vẫn test được bằng số nguyên; ranh giới
ngày test riêng, gồm các ca chỉ lộ ra ở biên: 23:59, đổi giờ mùa, và thiết bị đổi
múi giờ giữa hai phiên.

**Múi giờ vào từ ngoài, không đọc trong feature.** Đây là đúng bài học của
`clockProvider` (AD-13): một fallback riêng bên trong repository biến "bây giờ"
thành hai thứ — một provider cả cây override được, và một static không gì với
tới — và cái không với tới được là cái chạy trong production. Ranh giới ngày có
cùng hình dạng rủi ro, nên đi cùng đường.

### Hệ quả

- `lib/features/study/` MUST NOT gọi `DateTime.now()`, và cũng MUST NOT đọc múi
  giờ thiết bị trực tiếp.
- Test của scheduler không cần biết ngày là gì.
- Đổi mốc cắt sau này — nếu có ai muốn 04:00 thay vì 00:00 — là sửa một chỗ.

---

## AD-17 · Deck và Card là bản tham chiếu: thừa kế tầng, không thừa kế hình dạng dữ liệu

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `CLAUDE.md` · `.claude/skills/flutter-workflow/SKILL.md` · `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md` · `lib/features/deck/README.md` · `lib/features/card/README.md` |
| **Decision** | `features/deck` và `features/card` là hai bản tham chiếu của dự án. Feature mới MUST lấy từ chúng **phương pháp** — cách chia tầng, chỗ cưỡng chế một luật, thứ một use case được phép biết, cách một failure mang theo lý do, test nào nằm ở tầng nào. Feature mới MUST NOT thừa kế **nghiệp vụ** của chúng: cây deck, `content_type`, scheduler-trên-root, cờ và tag của card đều tồn tại vì hai feature đó cần, và một feature không cần mà vẫn mọc ra chúng là đã sao chép nhầm nửa. |

### Vì sao có quyết định này

Ba cơ chế đã cưỡng chế **hình dạng** rất chắc: `architecture_boundary_test.dart`
kiểm bucket và hướng import bằng AST, `check_architecture.py` ghép mỗi thư mục
với suffix nó nhận, và guard `memox-v7` phủ phần còn lại. Cái chưa có cơ chế nào
là **ranh giới giữa phương pháp và nghiệp vụ** — và đó lại đúng là chỗ một agent
sai mà mọi gate vẫn xanh: một feature mọc thêm cây nhiều cấp không vi phạm luật
nào cả.

Trước AD này, nguồn duy nhất nói ra điều đó là `feature_blueprint.md`, và nó hở
hai đường. **Cửa vào không dẫn tới nó:** `CLAUDE.md` chỉ định `flutter-workflow`
làm điểm bắt đầu, mà file đó không nhắc Deck lẫn blueprint lần nào — agent chỉ
gặp blueprint nếu tình cờ rơi đúng vào `flutter-feature-slice` trước.
**Và chính nó tự hứa rồi không trả:** mở đầu viết *"what to copy, what to rename,
and what must not be copied"*, nhưng trong 1182 dòng không có một dòng nào nói
cái gì không được mang sang. Đo được: 23 từ mang nghĩa sao chép (`copy`, `clone`,
`scaffold`, `template`) chọi lại **một** lần `reference implementation`.

### Hai bản, không phải một

Một bản tham chiếu duy nhất **không phân biệt được** "đây là luật" với "đây là
cách feature đó tình cờ được viết". Chỉ khi có bản thứ hai làm khác mà vẫn đúng
thì mới biết chỗ nào là bắt buộc. Vài chỗ Deck và Card khác nhau, và mỗi chỗ đều
đúng: Card không có cây và không có `content_type`; câu lệnh list của Card ghép
filter, search và sort động trong khi của Deck thì không; Card cần bốn chip lọc,
Deck cần hai.

`lib/features/card/README.md` giữ danh sách đó — nó là ca đối chứng, không phải
bản catalogue tính năng thứ hai.

### Phép thử

Với mỗi thứ định mang sang, hỏi: **"bỏ nó đi thì feature của tôi sai, hay chỉ là
bớt giống Deck?"** Chỉ vế đầu là lý do giữ. Vế sau là cách một codebase có được
một cái cây không ai cần và một `content_type` không ai đặt.

Phép thử ngược đã có sẵn trong blueprint và không đổi: nếu để feature mới chạy
được mà phải sửa `core/` hoặc `shared/`, thì thứ đó lẽ ra đã phải ở đó từ trước —
chuyển nó đi là **hoàn tất feature cũ**, không phải bắt đầu feature mới.

### Hệ quả

- `CLAUDE.md` và `flutter-workflow/SKILL.md` MUST trỏ tới hai bản tham chiếu.
  Trước M99.2 cả hai đều không.
- `feature_blueprint.md` MUST có mục nói cái gì **không** chuyển được, và MUST
  KHÔNG dùng từ vựng sao chép cho thứ nó muốn người đọc tham khảo.
- Feature thứ ba làm xong MUST được cân nhắc: nó xác nhận phương pháp, hay nó
  phơi ra một chỗ mà hai bản hiện tại đang đồng ý chỉ vì cùng một tác giả.

### Phương án đã loại

**Cưỡng chế bằng guard.** Đã cân nhắc một rule kiểu "feature mới không được có
cột `parent_*_id`". Loại vì nó sai cả hai chiều: một feature *thật sự* cần cây
sẽ bị chặn oan, còn một feature sao chép nhầm theo cách khác thì lọt. Ranh giới
này là phán đoán thiết kế; đưa nó cho regex là đổi một luật đúng lấy một luật
kiểm được.

**Sinh feature bằng script scaffold.** Loại vì nó tối ưu đúng cái phần rẻ nhất —
tạo thư mục — và tự động hoá đúng cái sai mà AD này tồn tại để chặn: một cây thư
mục sinh sẵn mời gọi việc điền vào cho đủ, kể cả những chỗ feature đó không cần.

---

## AD-18 · StudyMode là Strategy được use case gọi, không phải Template Method trong một abstract base

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-97…BR-100, BR-106…BR-108) · `CLAUDE.md` · `code-verification-guard-v2` naming rules |
| **Decision** | Mỗi StudyMode là một class thuần implement `StudyModeHandler` với đúng hai trách nhiệm: `validateInput` và `evaluate`. Luồng chung của một lượt học nằm trong **use case**, không nằm trong một abstract base mà sáu mode kế thừa. Phân giải mode là **một** `switch` exhaustive trên enum, ở đúng một chỗ. |

### Vì sao không phải Template Method

Đề xuất ban đầu — `StudyMode` interface → `AbstractStudyMode` giữ `process()` →
năm concrete override hook — là khuôn quen của Java/Spring và mục tiêu của nó
đúng: gom luồng chung, tránh `switch` rải rác, thêm mode không sửa luồng đang
chạy. Cái không chuyển sang được là **chỗ đặt luồng chung**.

Luồng của một lượt học gồm mười bước, và bảy trong số đó là I/O phải nằm **trong
một transaction**: ghi `study_answers`, cập nhật `card_study_states`, tăng
`cursor`, đặt `available_at`, `answers_in_session`, đóng phiên khi hết hàng đợi.
`CLAUDE.md` cấm hoisting đúng loại luật này ra khỏi repository — kiểm ngoài
transaction là một race giữa lúc kiểm và lúc ghi.

Nếu `process()` của abstract base làm những bước đó thì base phải cầm một
repository và mở transaction, tức `domain/` mode trở thành nơi chứa I/O. Nếu nó
**không** làm, thì phần chung còn lại đúng ba bước, quá mỏng để dựng một tầng kế
thừa cho năm class.

Nên luồng chung ở nơi nó vốn thuộc về: `SubmitStudyAnswerUseCase`. Use case
**chính là** template method — nó chạy mười bước và gọi handler ở giữa. Mode trở
thành Strategy:

```dart
final handler = studyModeHandler(session.mode);
handler.validateInput(context, input);
final evaluation = handler.evaluate(context, input);   // thuần, không I/O
await repository.recordAnswer(evaluation, ...);        // 1 transaction
```

Cái được kèm theo: Dart không có final method, nên một `process()` public luôn
override được. Không có `process()` thì cũng không có gì để bypass — vấn đề biến
mất thay vì phải canh bằng contract test.

### Fail-fast lúc biên dịch, không phải lúc khởi động

Registry kiểu factory-nhận-collection kiểm "đủ số mode" lúc khởi động. Dart 3
kiểm sớm hơn:

```dart
StudyModeHandler studyModeHandler(StudyMode mode) => switch (mode) {
  StudyMode.review => const ReviewModeHandler(),
  StudyMode.match  => const MatchModeHandler(),
  StudyMode.guess  => const GuessModeHandler(),
  StudyMode.recall => const RecallModeHandler(),
  StudyMode.fill   => const FillModeHandler(),
};
```

Thiếu một nhánh là **lỗi biên dịch**. Trùng enum và "mode không hỗ trợ" bất khả
thi về kiểu. Thêm mode thứ sáu thì compiler chỉ thẳng vào mọi chỗ chưa xử lý —
đó là thứ một registry runtime không làm được.

Điều này **không** mâu thuẫn với "không rải `switch` theo mode": switch tồn tại ở
đúng một điểm phân giải. Cái bị cấm là switch **thứ hai** trong controller hay
use case, và nó được cưỡng chế bằng rule của `code-verification-guard-v2`, không
bằng code review.

### Hai resolver, và vì sao đó không phải hai `switch` rải rác

Câu cấm của quyết định này là **switch thứ hai trong controller hay use case** —
tầng quyết định *một lượt làm gì*. Nó không cấm presentation có resolver riêng,
và presentation buộc phải có: `domain/` không được import Flutter, nên không
nơi nào trong domain trả về được một widget.

Nên có đúng hai điểm phân giải, mỗi tầng một:

| resolver | ở đâu | trả về |
|---|---|---|
| `studyModeHandler(mode)` | `domain/models/study_mode.dart` | Strategy: capacity, `canTake`, `canRunOn`, `lapsePolicy` |
| `studyModeView(...)` + `studyModeFeedback(mode)` | `presentation/widgets/support/` | thân màn của mode, và thời lượng hiển thị kết quả của nó |

Controller, use case và repository **không** có nhánh nào theo mode. Cái cuối
cùng bị bỏ đi là `if (mode == StudyMode.match)` trong queue effect: mode nay
khai báo `StudyLapsePolicy` và repository chỉ thi hành policy đó, nên tầng dữ
liệu không còn nhận diện mode nào cả.

Cả hai đều là `switch` chứ không phải `Map`: thiếu một nhánh là lỗi biên dịch,
còn thiếu một khoá là một màn hình trống lúc chạy. Bản `Map` của presentation đã
tồn tại đúng đến khi nó phải trả thêm một thứ cho mỗi mode.

### Lifecycle của một lượt là của luồng chung, không của mode

Ghi và tải là **hai** thao tác, và gộp chúng làm một là thứ khiến mọi feedback
vừa viết ra không bao giờ đọc được:

```text
mode driver → controller.submitAnswer()   → use case → repository transaction
                                                          ↓ commit receipt
           ← mode hiển thị kết quả ← controller cập nhật progress tại chỗ
                     ↓
           controller.advance(minimumVisible:)  ← đọc lượt kế tiếp *dưới* feedback
```

`submitAnswer` không tải gì; `advance(minimumVisible:)` giữ nguyên lượt đang
hiển thị, chạy song song việc đọc và việc đợi, rồi mới đổi. Mode quyết định
`minimumVisible` qua `studyModeFeedback`; nó không được gọi repository, không
tự cập nhật tiến độ bền vững và không giữ scheduler logic.

Trạng thái hàng queue sau transaction về theo `StudyAnswerCommitModel`. Controller
**không** được suy ra từ `action.isLapse`: cùng một lapse, `match` giữ hàng
`pending` còn ba mode chấm điểm còn lại đóng nó — và đoán sai thì một ô trên bàn
biến mất trong khi database vẫn giữ nó mở.

### Ranh giới

- `domain/models/*_mode.dart` là Dart thuần: không repository, không `DateTime.now()`,
  không random. Đếm giờ của Recall vào bằng `didTimeout` trong input (AD-13, AD-16);
  thứ tự xáo cố định trong phiên nên chỉ chạy một lần lúc nạp hàng đợi (BR-102).
- Handler không gọi handler khác. Chuyển mode do luồng chung quyết định.
- `evaluate` trả `StudyEvaluation` canonical — không widget, không chuỗi đã dịch,
  không row của Drift.

### Cái không lấy từ đề xuất gốc, và vì sao

Đề xuất dùng từ vựng **Attempt · checkpoint · round · nextRoundFailedCardIds**.
Repo đã có đủ những khái niệm đó dưới tên khác kể từ BR-102, nên dựng thêm một bộ
tên là dựng hai mô hình cho một thứ — và đó là lỗi tốn kém nhất trong nhóm này, vì
cả hai đều chạy được:

| Đề xuất gốc | Repo |
|---|---|
| Attempt | một dòng `study_answers` |
| checkpoint | `study_sessions.cursor` + trạng thái `study_queue_items` |
| nextRoundFailedCardIds | `available_at = cursor + 3` (BR-26) |
| mastery retry round | lượt `relearning`, trần 3 (BR-104) |
| deterministic shuffle | `position` cố định trong phiên (BR-102) |

## AD-19 · Scaffold bốn navigation branch top-level trước khi mọi feature hoàn thành

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `product.md` · `it-scenarios/01-navigation-and-continuity.md` · `wbs.md` (M99.7, M99.23) · `wireframes/m99-23-progress-overview.md` |

**Decision.** Navigation shell khai báo đúng bốn `StatefulShellBranch`, theo thứ
tự cố định: **Decks (0) · Study (1) · Progress (2) · Settings (3)**. Decks vẫn
là cold-start branch (UC-06). Một branch chưa có nghiệp vụ canonical MUST chỉ có
presentation-only placeholder screen: placeholder MUST NOT tạo domain entity,
repository, provider, DAO, bảng, dữ liệu mẫu hay persistence nào — không đọc
provider, không mở session, không ghi database khi vào, thoát hoặc chuyển tab.
Mỗi branch có path thật (`/progress`, `/settings`) để deep link mở đúng tab.
Thư viện starter thuộc branch Decks; MUST NOT có tab Profile chừng nào chưa có
auth/profile domain (AD-03).

**Ràng buộc placeholder hết hiệu lực đúng lúc nghiệp vụ được chốt, không sớm
hơn.** Từ M99.23, branch **Progress** mang màn hình thật: nghiệp vụ của nó đã
canonical ở UC-12 và BR-182…BR-191, nên điều kiện mà AD này đặt ra đã được đáp
ứng và ràng buộc "chỉ placeholder" MUST NOT còn áp cho Progress. Việc thay là
**một screen đổi một screen**: path `/progress`, `RouteNames.progress` và
branch index 2 MUST giữ nguyên — đó chính là tài sản mà AD này mua trước.
**Settings vẫn là placeholder** và vẫn chịu toàn bộ ràng buộc trên, vì chưa có
BR nào đứng sau nó.

**Context.** Sản phẩm cần IA ổn định cho năm study mode và các capability sắp
tới (thống kê S2, tùy chọn ứng dụng), trong khi Progress và Settings chưa có
nghiệp vụ canonical nào. Hai con đường đều xấu: chờ feature xong mới thêm tab
nghĩa là shell, URL contract và toàn bộ navigation test đổi lại lần nữa ở thời
điểm đắt hơn; còn dựng fake data cho màn hình "trông như xong" là viết spec ở
tầng sai — docs mới là nơi nghiệp vụ được chốt, và một thống kê bịa ra sẽ được
người dùng lẫn phiên làm việc sau tin là thật.

**Consequences.** IA và deep-link contract đóng băng sớm: feature thật sau này
thay một screen trong một branch có sẵn, không đụng router hay shell. Người
dùng thấy rõ tính năng đang phát triển thay vì một tab đột nhiên xuất hiện.
Giá phải trả: hai placeholder và test route của chúng phải được duy trì, và tab
scaffold dễ bị đọc nhầm là feature đã xong — WBS và `product.md` phải nói rõ
điều ngược lại. **Hệ quả đó đã được kiểm chứng ở M99.23:** thay placeholder
Progress bằng vertical slice thật chạm đúng một dòng `builder` trong
`app_router.dart`; shell, thứ tự branch, URL contract và test điều hướng không
đổi dòng nào, đúng như AD này dự đoán. Cái *có* phải đổi là hai file test đi
theo tên screen — companion visual audit ở đường dẫn gương (MX-VIS-001) và
widget test của screen — nên "một screen đổi một screen" là đúng cho production
tree và không đúng cho test tree. Một hệ quả đã đo được: bốn destination vượt trần
`4 × 120dp` của `MxNavigationBar` trên màn 393dp, nên cap bề rộng phải nhường
cho bề rộng màn hình (M99.7) — đúng hành vi Material thiết kế cho even split.

**Rejected alternatives.** Giữ hai tab cho tới khi mọi feature xong — trả chi
phí sửa shell/contract/test lần nữa vào lúc đắt nhất. Fake statistics/settings
data để màn hình trông hoàn chỉnh — gây hiểu nhầm và tạo kiến trúc không có
nghiệp vụ đứng sau. Toast "đang phát triển" thay cho branch thật — không deep
link được, không giữ stack, và toast không phải một destination. Đưa Starter
Library hoặc Profile thành tab top-level — starter là child flow của Decks
(AD-07), còn Profile chưa có domain nào đứng sau (AD-03).


## AD-20 · Card Transfer: canonical schema dùng chung, Strategy theo format, Import và Export là hai pipeline

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-168…BR-173 import, BR-174…BR-181 export), `use-cases.md` (UC-10, UC-11), `wireframes/m4-12-card-import.md`, `wireframes/m4-13-card-export.md` |

**Decision.** Card transfer có một **canonical schema** duy nhất — sáu field
`front · back · example · hint · pronunciation · tags`, header lowercase
English không bao giờ localize, tag nối bằng `;` qua **một codec dùng chung cho
cả hai chiều** (BR-176) — sống ở
`card_transfer_field_model.dart` và là bản gốc cho cả hai chiều. Mỗi file
format là một **decoder Strategy** cùng emit một raw document model; một
**resolver/registry** duy nhất (`cardTransferDecoderFor`) quyết định format
nào dùng decoder nào, và không nơi nào khác được switch theo format. Pipeline
đi qua ba stage model tách bạch: raw document (decode xong) → mapped record
(sau column mapping) → canonical validated record (qua `CardText` /
`CardDetailText` / `TagName`). Import và Export là **hai pipeline riêng**
chung schema và chung decoder/encoder boundary; MVP chỉ triển khai Import, và
không có API encode nào tồn tại trước caller đầu tiên của nó.

**Context.** Import v1 nhận CSV, TSV, XLSX và paste text. Nghiệp vụ card
không được phụ thuộc format biểu diễn — một rule chạy khác nhau tuỳ đuôi file
là một rule có nhiều chủ. Đồng thời Export là hướng đã định (M99.17 N1):
kiến trúc Import không được khoá schema/parser/model theo hướng import-only
khiến Export phải viết lại.

**Consequences.** Duplicate identity của import là một **record có kiểu**
(`CardImportDuplicateKey = ({frontFolded, backFolded})`), không phải chuỗi ghép:
mọi separator scheme đều đứng trên bất biến ngầm "separator không xuất hiện
trong text" mà không type nào bảo vệ — equality cấu trúc thì không có separator
để đụng. Wizard import mount trên **root navigator** (`parentNavigatorKey`):
một full-screen task che shell và bottom bar thay vì render trong branch; URL
giữ nguyên hình lồng `/decks/:id/cards/import`, entry point `push` để Cancel
`pop` về đúng nơi mở — deck `unset` về deck detail, card list về card list.
Ba contract hẹp thay vì một: `CardImportSourceRepository`
(picker — seam platform duy nhất), `CardTransferRepository` (decode, thuần
bytes-to-rows, chạy off-thread), `CardImportRepository` (commit, thuần
database, nói bằng canonical record). Widget test chỉ fake nửa nó gọi; impl
commit chứng minh được là không thấy một byte CSV nào —
`card_transfer_boundary_test.dart` ghim cả bốn ranh giới bằng source scan
(presentation không thấy codec/picker, decoder không thấy database, commit
không thấy codec, dispatch chỉ ở resolver). Thêm một format là một decoder
mới cộng một nhánh switch trong resolver — exhaustive, nên thiếu nhánh là lỗi
compile. Export sau này thêm encoder strategy + encoder resolver + export
repository bên cạnh các contract này mà không sửa Preview hay transaction
Import. Round-trip kỳ vọng: export rồi import lại giữ nội dung và tag, sinh
id và study state mới — đây là **content transfer, không phải backup**, nên
canonical record không mang id, timestamp, scheduler, box, interval, due hay
history.

**Nửa encode tới ở M99.21, và nó không sửa gì của Import.** Caller đầu tiên của
`encode()` xuất hiện đúng lúc quyết định này dự đoán: một `CardTransferEncoder`
đối xứng với decoder, một encoder resolver exhaustive thứ hai theo cùng
`CardTransferFormat`, và `CardExportRepository` cộng một platform destination
contract bên cạnh ba contract Import — Preview, mapping và transaction commit
không đổi một dòng. Hai chỗ chiều export **thay đổi** hợp đồng chung, và cả hai
đều là sửa đúng chỗ chứ không phải thêm nhánh: (1) ô `tags` nay đi qua một codec
có escape (BR-176) và **Import chuyển sang dùng chính codec đó**, vì `;` trần
không round-trip được một tag có chứa `;`, và một tag mất chỗ tách khi export là
mất dữ liệu chứ không phải mất định dạng; (2) canonical record vốn không có khái
niệm thứ tự, còn export thì cần — nên thứ tự là hợp đồng của **repository**
(BR-177), không phải của schema hay của encoder, và encoder vẫn chỉ nhận một
danh sách record đã sắp. Ranh giới platform mở rộng thêm một seam thứ hai đối
xứng với picker: destination (share sheet) là chỗ duy nhất chiều export chạm hệ
điều hành, nên `card_transfer_boundary_test.dart` mở rộng cùng kiểu source scan —
encoder không thấy database, UI hay share; presentation không thấy codec hay
plugin; dispatch format vẫn chỉ ở resolver.

**Rejected alternatives.** Một `ImportExportFactory` gom parse, validate, DB
và picker — God Object với bốn lý do đổi khác nhau, và là đúng cái AD-18 đã
loại ở trục StudyMode. Decode thẳng file thành `CardEntity` — trói entity vào
từng format và buộc validation chạy trong parser, vi phạm BR-169 "một bộ
validation". Tái sử dụng Study Mode factory cho transfer — hai trục mở rộng
khác nhau; chung factory là chung lý do đổi. Chuẩn bị sẵn `encode()` rỗng
"cho tương lai" — API chết không có test thật, và cái giá của thêm-sau đã
được trả trước bằng ranh giới, không cần trả bằng code chết.
