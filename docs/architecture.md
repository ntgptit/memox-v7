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

## AD-06 · Scheduler là strategy thuần khiết, chọn được theo deck

**Quyết định.** Logic xếp lịch ôn tập là một **strategy** ở `domain/`, thuần
khiết: nhận trạng thái card hiện tại + đánh giá của người dùng + thời điểm hiện
tại, trả về trạng thái card mới. Không đọc database, không gọi `DateTime.now()`.

```dart
// domain/scheduler/review_scheduler.dart
abstract interface class ReviewScheduler {
  SchedulingState next({
    required SchedulingState current,
    required ReviewRating rating,
    required DateTime now,
  });
}
```

Hai implementation: `EightBoxScheduler` (MVP) và `Sm2Scheduler` (sau MVP). Người
dùng chọn theo **deck**, không phải theo app — deck từ vựng cơ bản và deck ngữ
pháp phức tạp hợp với chế độ khác nhau, và lưu ở deck chỉ tốn một cột.

**Vì sao đây là ngoại lệ hợp lệ của quy tắc "không tạo interface cho một
implementation".** CLAUDE.md cấm bọc interface quanh thứ không có nhu cầu thay
thế. Ở đây implementation thứ hai **đã được đặc tả**, không phải phỏng đoán —
người dùng chọn được là một yêu cầu sản phẩm, không phải khả năng tưởng tượng.
Nếu SM-2 chỉ là "có thể sau này làm", quyết định đúng sẽ là viết thẳng 8-box
không interface.

**Vì sao thuần khiết.** Đây là phần logic duy nhất trong app thực sự phức tạp và
bắt buộc phải đúng — sai thuật toán thì người dùng không nhận ra ngay, chỉ thấy
"app không hiệu quả" sau vài tuần. Hàm thuần khiết nghĩa là test được toàn bộ ma
trận (8 hộp × 4 mức đánh giá = 32 trường hợp) mà không cần database, không cần
widget, không phải chờ thời gian trôi.

Truyền `DateTime now` vào như tham số là điều kiện để test "card đến hạn sau 64
ngày" trong một mili giây.

**Trạng thái lưu ở đâu.** `due_at` là **cột chung**, độc lập thuật toán — vì đó
là cột duy nhất mà query nóng ("card nào đến hạn") cần, và nó phải được đánh
index. Tham số riêng của từng thuật toán nằm ở các cột nullable riêng:

| Cột | Thuộc về | Ghi chú |
|---|---|---|
| `due_at` | chung | index cùng `deck_id`; NULL = card mới |
| `box` | 8-box | 1..8 |
| `ease_factor`, `interval_days`, `repetitions` | SM-2 | NULL khi deck dùng 8-box |

**Phương án đã cân nhắc và loại:** gói trạng thái vào một cột JSON. Linh hoạt
hơn, nhưng mất type-safety và không query được — mâu thuẫn trực tiếp với lý do
chọn AD-02. Vài cột NULL là cái giá rẻ hơn nhiều.

**Đổi thuật toán trên deck đã có tiến độ:** giữ nguyên `due_at`, reset tham số
riêng về mặc định. Xem BR-13 — ánh xạ box ↔ ease factor là bịa đặt, và nó âm
thầm làm hỏng lịch ôn của người dùng.

---

## AD-07 · Deck quà tặng đóng gói theo app, chèn một lần

**Quyết định.** Bộ deck dựng sẵn nằm trong `assets/seed/` dạng JSON, chèn vào DB
ở lần chạy đầu. Sau khi chèn, chúng là dữ liệu bình thường của người dùng: sửa
được, xoá được, ôn được như deck tự tạo.

**Vì sao chèn vào DB thay vì đọc thẳng từ asset.** Nếu deck quà là read-only đọc
từ asset, chúng phải là một loại deck thứ hai trong toàn bộ code — repository
phải hợp nhất hai nguồn, xoá và sửa phải có nhánh riêng, query "card đến hạn"
phải chạy hai lần. Chèn một lần rồi coi như dữ liệu thường giữ cho **chỉ có một
loại deck** trong hệ thống.

**Cái bẫy phải tránh, và nó không hiển nhiên:** bản cập nhật app sau thêm deck
quà mới. Cách làm ngây thơ — "chèn seed nếu chưa có" — sẽ **chèn lại deck mà
người dùng đã cố tình xoá**. Người dùng xoá nó lần nữa, bản cập nhật sau lại chèn
lại. Đó là lỗi làm người dùng mất niềm tin vào việc xoá.

Cách làm: bảng `applied_seeds(seed_id TEXT PRIMARY KEY, applied_at DATETIME)`.
Mỗi deck quà có `seed_id` cố định. Khởi động: chỉ chèn seed nào **chưa từng**
xuất hiện trong `applied_seeds`, và ghi nhận ngay cả khi sau đó người dùng xoá.
Đã tặng một lần là đã tặng — không tặng lại.

Việc chèn seed chạy trong **một transaction** cùng với ghi `applied_seeds`, để
app bị kill giữa chừng không để lại nửa bộ deck và một cờ đã đánh dấu.

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
