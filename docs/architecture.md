# Architecture decisions

_Last updated: 2026-07-28_

Ghi lại các quyết định kiến trúc và **lý do**, để phiên làm việc sau đọc được
quyết định chứ không phải đoán từ code. Mỗi quyết định có ID `AD-xx` để code
comment và WBS trích dẫn.

Nguyên tắc xuyên suốt tài liệu này: **chuẩn bị sẵn những thứ đắt tiền khi
retrofit, hoãn những thứ rẻ khi retrofit.** Đó là ranh giới giữa "backend-ready"
và "over-engineering" — cả hai đều là yêu cầu trong CLAUDE.md và chúng kéo ngược
chiều nhau.

---

## AD-01 · Local-first, backend-ready

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

---

## AD-05 · Chưa thêm dependency mạng

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

**Sub-deck kế thừa scheduler của root deck.** Sub-deck chỉ là cấu trúc phân cấp;
nó **không** chọn scheduler riêng. Cột scheduler chỉ có giá trị trên root deck,
sub-deck để NULL và tra ngược lên root. Cho sub-deck chọn riêng sẽ khiến một phiên
ôn trải trên nhiều sub-deck phải hiển thị nhiều tập action cùng lúc — vô nghĩa với
người dùng.

---

## AD-09 · Reset learning progress và scheduler generation

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

## AD-07 · Starter deck là template, người dùng nhận bản sao

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
