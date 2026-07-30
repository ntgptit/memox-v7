# Architecture decisions

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi lại quyết định kiến trúc và lý do, để phiên sau đọc được quyết định chứ không phải đoán từ code |
| **Scope** | Quyết định ràng buộc nhiều tài liệu hoặc nhiều layer. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), hình dạng dữ liệu (`data-model.md`) |
| **Source of truth for** | AD-xx · đánh đổi kiến trúc · phương án đã bị loại · lý do pin toolchain |
| **Depends on** | `document-conventions.md`, `product.md` |
| **Updated by task** | M4.10b (AD-13) |
| **Last updated** | 2026-07-30 |

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
Named query đặt tên theo động từ nghiệp vụ (`cardsDueForReview`), không theo hình
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

## AD-06 · Scheduler chọn theo deck, khoá sau lượt review đầu tiên

| | |
|---|---|
| **Status** | accepted |
| **Affected documents** | `business-rules.md` (BR-05, BR-06, BR-11…BR-19, BR-30, BR-73, BR-74) · `use-cases.md` (UC-02, UC-03, UC-05) · `data-model.md` |

**Quyết định.** MVP hỗ trợ **hai** scheduler: `eight_box` và `sm2`. Mỗi deck
**bắt buộc chọn một** khi tạo. Lựa chọn ở cấp deck, không phải cấp app.

Scheduler đổi trực tiếp được **chừng nào deck chưa có lượt review nào**. Sau lượt
review đầu tiên, `scheduler_type`, `scheduler_version` và `scheduler_config` của
deck bị **khoá**. Muốn đổi sau đó, người dùng phải thực hiện **Reset learning
progress** (AD-09).

```dart
// domain/scheduler/review_scheduler.dart
abstract interface class ReviewScheduler {
  SchedulerType get type;
  int get version;

  /// Tập action mà scheduler này chấp nhận. UI render nút từ đây,
  /// không hardcode — hai scheduler có hai tập action khác nhau.
  List<ReviewAction> get supportedActions;

  ReviewOutcome next({
    required ReviewState current,
    required ReviewAction action,
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

**Vì sao khoá sau review đầu tiên thay vì cho đổi tự do.** Đổi thuật toán giữa
chừng đặt ra những câu hỏi không có câu trả lời trung thực: box 5 tương ứng ease
factor nào, review history theo luật cũ còn giá trị gì cho chu kỳ mới, đổi ngược
lại có khôi phục trạng thái cũ không. Mọi ánh xạ đều là bịa đặt và nó âm thầm làm
hỏng lịch ôn.

Khoá-và-reset thừa nhận điều đó thẳng thắn: trước lượt review đầu, không có gì để
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
- Toàn bộ việc tạo bản sao (deck + card + review state) nằm trong **một
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

**Quyết định.** Đổi scheduler trên deck đã có review chỉ thực hiện được qua thao
tác **Reset learning progress**. Mỗi deck có `scheduler_generation`, tăng sau mỗi
lần reset.

**Reset giữ gì và xoá gì:**

| Giữ nguyên | Xoá / đặt lại |
|---|---|
| Deck và sub-deck | Active scheduler state của mọi card |
| Flashcard và nội dung | `due_at`, interval |
| Media, tag | `current_box`, ease factor, repetitions |
| Review history cũ | Mastery state |
| | Session đang dở |

**Review history cũ được giữ lại để tham khảo, nhưng không được dùng cho chu kỳ
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

Sau reset, deck lại ở trạng thái "chưa có review", nên scheduler mở khoá và chọn
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
trị `unset` / `card` / `deck`, xác lập bởi lần tạo phần tử con đầu tiên và sau đó
không đổi trừ khi reset tường minh.

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

**Xoá hết nội dung không đưa `content_type` về `unset`.** Tự động quay về nghe
tiện nhưng khiến cấu trúc đổi âm thầm sau một thao tác xoá. Reset `content_type`
là thao tác riêng, có xác nhận, chỉ khi deck rỗng (BR-68).

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

**Quyết định.** `review_history.review_kind` và `study_sessions.status` /
`end_reason` được **lưu tường minh** tại thời điểm ghi. Cấm suy ra chúng bằng cách
so sánh trạng thái trước và sau, hoặc bằng cách đoán từ dữ liệu khác.

**Vì sao, cụ thể.** Suy luận `review_kind` nghe rất hợp lý: "trước và sau giống
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
(content lock của con đầu), BR-68 (điều kiện rỗng) và bộ rule move UC-09 đều chạy
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
  `content_type` **và** từ việc children rỗng (BR-68), nên một rename hoặc một
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
