# Hướng dẫn AI agent thực thi kịch bản IT

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Cung cấp hợp đồng thực thi xác định để AI agent chọn, chuẩn bị, chạy và báo cáo kịch bản IT mà không tự suy diễn |
| **Scope** | Quy trình của agent, mức sẵn sàng, chuẩn bị, dọn dẹp, dữ liệu dựng sẵn, bằng chứng và kết luận; không định nghĩa lại hành vi sản phẩm |
| **Source of truth for** | Giao thức AI agent thực thi bộ kịch bản IT |
| **Depends on** | `README.md`, `scenario-catalog.md`, `../business-rules.md`, `../use-cases.md`, `../wbs.md` |
| **Updated by task** | Bổ sung hợp đồng thực thi cho chức năng học và chuẩn hóa tiếng Việt ngày 2026-08-08 |
| **Last updated** | 2026-08-09 |

## 1. Điểm bắt đầu bắt buộc

AI agent MUST thực hiện theo thứ tự:

1. Đọc [`README.md`](README.md) để xác định phạm vi sản phẩm hiện có.
2. Tìm ID trong [`scenario-catalog.md`](scenario-catalog.md).
3. Kiểm tra mức sẵn sàng (`Readiness`), hồ sơ thực thi (`Profile`), chuẩn bị (`Setup`) và dọn dẹp (`Cleanup`) của ID đó.
4. Đọc kịch bản gốc và các UC/BR được danh mục liên kết.
5. Chuẩn bị dữ liệu bằng công thức chuẩn bị trong tài liệu này.
6. Thao tác toàn bộ bước của kịch bản qua giao diện người dùng.
7. Ghi bằng chứng và kết luận theo mục 8.
8. Chạy bước dọn dẹp đã khai báo, kể cả khi kịch bản thất bại.

Khi được giao “chạy toàn bộ”, agent MUST chạy `READY` theo thứ tự P0 → P1 → P2.
Các dòng `FIXTURE-BLOCKED` và `KNOWN-GAP` vẫn phải xuất hiện trong báo cáo tổng,
nhưng không được đưa vào hàng đợi chạy như một kịch bản được kỳ vọng đạt.

Nếu kịch bản, danh mục và UC/BR không thống nhất, agent MUST dừng kịch bản với
trạng thái `DOC-DRIFT`; MUST NOT tự chọn một phiên bản rồi tiếp tục.

### 1.1. Tự kiểm tra trước khi chạy

Trước mỗi kịch bản, AI agent MUST trả lời được cả sáu câu sau bằng bằng chứng từ tài liệu:

1. ID kịch bản chính xác là gì và nằm trong tệp nào?
2. Dòng tương ứng trong danh mục khai báo mức sẵn sàng, hồ sơ thực thi, chuẩn bị và dọn dẹp nào?
3. Mã chuẩn bị trong danh mục có trùng với mã được gọi tên ở tiền điều kiện không?
4. Môi trường hiện tại có đủ khả năng mà hồ sơ thực thi yêu cầu không?
5. Mỗi kết quả mong đợi có thể quan sát qua giao diện hoặc công cụ kiểm tra chỉ đọc đã được phê duyệt không?
6. UC/BR truy vết có thống nhất với hành vi nghiệp vụ trong kịch bản không?

Nếu câu 2, 3 hoặc 6 không có câu trả lời duy nhất, kết luận `DOC-DRIFT`. Nếu câu
4 hoặc 5 là “không”, kết luận `BLOCKED`. Agent MUST NOT đọc logic triển khai để
tự điền phần còn thiếu rồi ghi nhận kịch bản đạt.

## 2. Mức sẵn sàng

| Giá trị | Agent được làm gì |
|---|---|
| `READY` | Có thể dựng tiền điều kiện và chạy ngay |
| `FIXTURE-BLOCKED` | Kịch bản hợp lệ nhưng bộ dữ liệu dựng sẵn xác định chưa được triển khai |
| `KNOWN-GAP` | Hành vi mong đợi đúng theo nghiệp vụ nhưng giao diện hiện tại được biết là chưa đủ; chạy để xác nhận khoảng trống, MUST NOT ghi sản phẩm đạt |

**`FIXTURE-BLOCKED` chỉ còn nghĩa với `DEVICE-E2E`.** Ở đó luật cũ vẫn giữ
nguyên: agent MUST NOT sửa cơ sở dữ liệu của thiết bị để giả lập tiền điều kiện,
vì một bộ dữ liệu không có đường dẫn hiện vật và phiên bản thì không tái lập
được. Với `HOST-FLOW` và `HOST-WIDGET` thì trở ngại ấy không tồn tại: test tự
tạo database in-memory của chính nó, nên dựng hàng là một phần của test chứ
không phải một sự can thiệp vào máy ai cả.

## 3. Hồ sơ thực thi

Đúng **ba** hồ sơ. Luật chọn nằm ở `12-testing-pyramid-audit.md`; luật ngắn gọn
là: **luôn chọn tầng thấp nhất bắt được đúng loại lỗi.**

| Hồ sơ | Chạy bằng | Dùng cho |
|---|---|---|
| `HOST-FLOW` | `flutter test` | Use case + repository + DAO + Drift + SQLite in-memory thật, clock inject, `Random` có seed. Không render UI nếu không cần. Luật nghiệp vụ, scheduler, truy vấn, transaction, hàng đợi, tính `due_at`, resume, generation |
| `HOST-WIDGET` | `flutter test` | Pump app/widget thật trên `ProviderScope`, GoRouter, localization và database thật. Thao tác người dùng, form, dialog, điều hướng, trạng thái loading/empty/error, việc UI phản ánh đúng state nghiệp vụ |
| `DEVICE-E2E` | Android/iOS emulator hoặc thiết bị | Chỉ những gì hai hồ sơ trên không chứng minh nổi: khởi động nguội, chết tiến trình, deep link từ hệ điều hành, cử chỉ nền tảng, plugin native, smoke trước phát hành |

Modifier được phép khi nó nói thêm một điều kiện thật, ví dụ `HOST-FLOW-CLOCK`
hay `DEVICE-E2E-RESTART`. Hồ sơ gốc MUST luôn là một trong ba giá trị trên.

**Các hồ sơ cũ đã bị bỏ** — `UI`, `UI-FIXTURE`, `UI-CLOCK`, `UI-RESTART`,
`UI-DEVICE`, `UI-MULTI`, `UI-FAULT`, `UI-LARGE`, `DEV-LINK`. Chúng mô tả *cách
thao tác*, không mô tả *ranh giới thực thi*, nên mọi kịch bản đều rơi vào
emulator theo mặc định. Bảng ánh xạ cũ→mới nằm ở `12-testing-pyramid-audit.md`
mục C.

**Hai luật không được nới:**

- `DEVICE-E2E` MUST NOT là nơi kiểm một luật nghiệp vụ mà `HOST-FLOW` kiểm được.
- Một kịch bản MUST NOT bị hạ xuống host bằng cách mock database. SQLite phải
  thật; in-memory là được, giả thì không.

## 4. Môi trường xác định

| Thuộc tính | Giá trị chuẩn |
|---|---|
| Nền tảng xác nhận chính | Android |
| Bản dựng | Bản phát triển, trừ khi nhiệm vụ yêu cầu biến thể khác |
| Ngôn ngữ | `vi` |
| Múi giờ | `Asia/Seoul` |
| Dữ liệu ban đầu | Theo mã chuẩn bị trong danh mục, không dùng dữ liệu cá nhân |
| Khởi động lại | Đóng hẳn tiến trình rồi mở lại; chuyển tab không được tính là khởi động lại |
| Ngoại tuyến | Bật chế độ máy bay sau khi chuẩn bị hoàn tất và giữ tới hết bước dọn dẹp cần kiểm tra |

Với bộ dữ liệu dựng sẵn phụ thuộc thời gian, mốc chuẩn là:

```text
T0 = 2026-08-05T09:00:00+09:00
```

Agent MUST xác nhận đồng hồ của bộ dữ liệu dựng sẵn là `T0` trước khi đối chiếu
số lượng `Due` hoặc huy hiệu đến hạn. Nếu môi trường không cố định được đồng hồ, các kịch bản dùng `S-DUE` hoặc
`S-PROGRESS` là `BLOCKED`, không phải `FAIL`.

## 5. Công thức chuẩn bị hoàn toàn qua giao diện

### SETUP-EMPTY

1. Xác nhận đây là bản cài đặt phát triển/kiểm thử, không chứa dữ liệu người dùng thật.
2. Xoá dữ liệu ứng dụng của đúng gói kiểm thử hoặc gỡ/cài lại bản dựng phát triển.
3. Mở ứng dụng và xác nhận danh sách bộ thẻ gốc ở trạng thái rỗng.

Nếu không chứng minh được gói ứng dụng là bản kiểm thử, agent MUST dừng; không được xoá dữ liệu.

### SETUP-D-EB

1. Chạy `SETUP-EMPTY`.
2. Tạo bộ thẻ gốc `Giao tiếp hằng ngày` và chọn Eight Box.
3. Quay về danh sách bộ thẻ gốc, xác nhận đúng một bộ thẻ `D-EB`.

### SETUP-D-SM2

1. Chạy `SETUP-EMPTY`.
2. Tạo bộ thẻ gốc `IELTS 2026` và chọn SM-2.
3. Quay về danh sách bộ thẻ gốc, xác nhận đúng một bộ thẻ `D-SM2`.

### SETUP-ROOTS

1. Chạy `SETUP-EMPTY`.
2. Tạo `D-EB` với Eight Box.
3. Tạo `D-SM2` với SM-2.
4. Xác nhận danh sách bộ thẻ gốc có đúng hai bộ thẻ trên.

### SETUP-TREE-UNSET

1. Chạy `SETUP-D-EB`.
2. Trong `D-EB`, tạo `Vocabulary` (`D-BRANCH`).
3. Trong `D-BRANCH`, chọn tạo bộ thẻ và tạo `Academic words` (`D-LEAF`).
4. Dừng khi `D-LEAF` còn rỗng và chưa định loại; không tạo thẻ.

Kết quả: `D-BRANCH` là bộ thẻ chứa bộ thẻ; `D-LEAF` là bộ thẻ con `unset`.

### SETUP-UNSET-CHILD:&lt;name&gt;

1. Chạy `SETUP-D-EB`.
2. Trong `D-EB`, tạo một bộ thẻ con có tên đúng bằng tham số `<name>`.
3. Dừng khi bộ thẻ mới rỗng và chưa định loại.

Ví dụ `SETUP-UNSET-CHILD:Grammar` tạo một bộ thẻ con `Grammar` ở trạng thái `unset`.

### SETUP-TREE-CARD

1. Chạy `SETUP-TREE-UNSET`.
2. Trong `D-LEAF`, chọn tạo thẻ và lưu `C-001` theo dữ liệu chuẩn trong README.
3. Xác nhận mở `D-LEAF` đi thẳng vào danh sách thẻ và thấy `C-001`.

### SETUP-CARD-BASIC

1. Chạy `SETUP-CARD-PLAIN`.
2. Mở edit `C-002`, thêm tag `IELTS`.
3. Mở edit `C-003`, thêm tag `Writing` và bật cờ.
4. Xác nhận danh sách thẻ có đúng ba thẻ, nhãn và cờ như README.

### SETUP-CARD-PLAIN

1. Chạy `SETUP-TREE-CARD`.
2. Tạo thêm `C-002` và `C-003` qua UI nhưng chưa thêm tag hoặc cờ.
3. Xác nhận danh sách thẻ có đúng ba thẻ và cả ba đều chưa gắn cờ.

### SETUP-CARD-TAGS

1. Chạy `SETUP-CARD-PLAIN`.
2. Mở `C-001`, thêm hai tag `IELTS` và `Writing`.
3. Quay về list và xác nhận row `C-001` có đúng hai chip trên.

### SETUP-CARD-EMPTY-TYPED

1. Chạy `SETUP-TREE-CARD`.
2. Xoá `C-001` qua UI và xác nhận.
3. Dừng tại danh sách thẻ rỗng.

Kết quả: `D-LEAF` rỗng nhưng vẫn là bộ thẻ loại `card`.

### SETUP-CARD-SINGLE

Chạy `SETUP-TREE-CARD` và không tạo thêm thẻ. `D-LEAF` có đúng `C-001`.

### SETUP-MOVE-TREE

1. Chạy `SETUP-TREE-CARD`.
2. Trong `D-EB`, tạo branch `Grammar`.
3. Trong `Grammar`, tạo bộ thẻ con tạm `Tenses`, sau đó xoá `Tenses`.
4. Giữ `Grammar` rỗng nhưng thuộc loại `deck` để làm đích di chuyển.

### SETUP-DECK-TYPED-WITH-CHILD

1. Chạy `SETUP-D-EB`.
2. Trong `D-EB`, tạo `Grammar`.
3. Trong `Grammar`, chọn tạo bộ thẻ và tạo `Tenses`.
4. Dừng khi `Grammar` có đúng một bộ thẻ con `Tenses`.

### SETUP-DECK-TYPED-EMPTY

1. Chạy `SETUP-DECK-TYPED-WITH-CHILD`.
2. Xoá `Tenses` qua UI và xác nhận.
3. Dừng khi `Grammar` rỗng nhưng vẫn chỉ cho tạo bộ thẻ.

### SETUP-CYCLE-TREE

1. Chạy `SETUP-D-EB`.
2. Tạo đường `Vocabulary > Academic words > Level 1`, ở mỗi cấp chọn tạo bộ thẻ.
3. Dừng khi cả ba bộ thẻ đều là loại `deck` và `Level 1` rỗng.

### SETUP-CROSS-SCHEDULER-MOVE

1. Chạy `SETUP-ROOTS`.
2. Dưới `D-EB`, tạo `Source branch`, rồi tạo một bộ thẻ con để nguồn thành cây con.
3. Dưới `D-SM2`, tạo `Target branch`, tạo rồi xoá một bộ thẻ con để đích rỗng nhưng thuộc loại `deck`.
4. Xác nhận nguồn và đích nằm dưới hai bộ thẻ gốc dùng thuật toán xếp lịch khác nhau.

### SETUP-SEARCH-TREES

1. Chạy `SETUP-ROOTS`.
2. Dưới `D-EB`, tạo đường `Vocabulary > Academic words`.
3. Dưới `D-SM2`, tạo đường `Reading > Academic archive`.
4. Quay về cấp mà kịch bản yêu cầu trước khi nhập từ khóa tìm kiếm.

### SETUP-DEEP-10

1. Chạy `SETUP-D-EB`.
2. Tạo tuần tự `Level 02` tới `Level 10`, mỗi bộ thẻ nằm trong bộ thẻ trước.
3. Xác nhận đường dẫn điều hướng có bộ thẻ gốc ở cấp 1 và `Level 10` ở cấp 10.

### SETUP-ROOT-TRIO

1. Chạy `SETUP-EMPTY`.
2. Tạo ba bộ thẻ gốc theo thứ tự `beta`, `Alpha`, `gamma`, cùng thuật toán Eight Box.
3. Dừng tại danh sách bộ thẻ gốc.

### Dữ liệu thẻ học chuẩn

| ID | Mặt trước | Mặt sau | Câu ví dụ |
|---|---|---|---|
| `ST-01` | `사과` | `apple` | `I eat an apple.` |
| `ST-02` | `물` | `water` | `Drink water.` |
| `ST-03` | `책` | `book` | `This is a book.` |
| `ST-04` | `산` | `mountain` | `The mountain is high.` |
| `ST-05` | `바다` | `sea` | `The sea is calm.` |

Các nghĩa đã chuẩn hóa của năm thẻ MUST khác nhau để đủ BR-121/BR-123. Kịch bản
yêu cầu “không có câu ví dụ” dùng đúng mặt trước/mặt sau nhưng để `example` rỗng.

### SETUP-STUDY-EB-5-FULL

1. Chạy `SETUP-EMPTY`.
2. Tạo bộ thẻ gốc `Korean` với Eight Box, rồi tạo bộ thẻ con chứa thẻ `Chapter 1`.
3. Tạo `ST-01`…`ST-05`, gồm cả `example`.
4. Xác nhận màn vào học hiện `New 5`, `Due 0`; chưa bắt đầu phiên.

### SETUP-STUDY-EB-5-PLAIN

Như `SETUP-STUDY-EB-5-FULL` nhưng bỏ trống `example` của cả năm thẻ. Kết quả
mong đợi tại màn vào học vẫn là `New 5`, `Due 0`.

### SETUP-STUDY-EB-1

Như phần chuẩn bị trên nhưng chỉ tạo `ST-01`. Dùng để chứng minh `match` và `guess` bị
bỏ qua/vô hiệu hoá theo BR-99, BR-121 và BR-153.

### SETUP-STUDY-EB-4

Như `SETUP-STUDY-EB-5-FULL` nhưng chỉ tạo `ST-01`…`ST-04`. Bốn nghĩa đã chuẩn hóa
MUST khác nhau. Dùng cho nhánh bỏ qua toàn bộ giai đoạn `Guess` vì tập thẻ trong
phiên chưa đạt năm nghĩa, không dùng để giả lập lỗi dựng riêng một câu hỏi.

### SETUP-STUDY-SM2-4

1. Chạy `SETUP-EMPTY`.
2. Tạo bộ thẻ gốc `Spanish` với SM-2, rồi tạo bộ thẻ con chứa thẻ `Basics`.
3. Tạo bốn thẻ: `hola/hello`, `agua/water`, `libro/book`, `mar/sea`.
4. Xác nhận màn vào học hiện `New 4`, `Due 0`; chưa bắt đầu phiên.

### SETUP-STUDY-EB-21

1. Chạy `SETUP-EMPTY` và tạo bộ thẻ gốc Eight Box `Limit library`, bộ thẻ con `Twenty one`.
2. Tạo `limit-001/meaning-001` tới `limit-021/meaning-021` theo thứ tự tăng dần.
3. Xác nhận `New 21`, `Due 0`; không dùng SQL và không bắt đầu phiên.

### SETUP-STUDY-SCOPE

1. Chạy `SETUP-EMPTY`, tạo bộ thẻ gốc Eight Box `Korean`.
2. Tạo hai bộ thẻ con chứa thẻ cùng cấp: `Lesson A` có `ST-01`…`ST-03`, `Lesson B` có
   `ST-04`…`ST-05`.
3. Xác nhận tại bộ thẻ gốc có `New 5`; tại `Lesson A` có `New 3`; chưa mở chức năng học.

### SETUP-STUDY-ALL-MODES

1. Chạy `SETUP-EMPTY`.
2. Tạo bộ thẻ gốc Eight Box `Korean`, bộ thẻ con `Chapter 1`, rồi `ST-01`…`ST-05` có câu ví dụ.
3. Tạo bộ thẻ gốc SM-2 `Spanish`, bộ thẻ con `Basics`, rồi bốn thẻ của
   `SETUP-STUDY-SM2-4`.
4. Xác nhận cả hai bộ thẻ gốc chỉ có thẻ mới. Phần chuẩn bị này dùng để kiểm tra
   khả năng tiếp cận qua sáu chế độ; không dùng số lượng của bộ thẻ gốc này để
   đối chiếu bộ thẻ gốc kia.

## 6. Hợp đồng dữ liệu dựng sẵn

### 6.1. Trạng thái hiện tại

| Khả năng | Hiện vật | Tình trạng |
|---|---|---|
| Cố định/dịch chuyển đồng hồ | `integration_test/support/it_harness.dart` — `setNow` | Có |
| Mở lại cơ sở dữ liệu trong tiến trình kiểm thử | `ItHarness.restartApp` | Có; bằng chứng thấp hơn việc khởi động lại tiến trình Android thật và MUST ghi rõ trong báo cáo |
| Khởi động lại tiến trình Android thật | Trình chạy ADB/thiết bị | Phụ thuộc môi trường chạy |
| Hai bề mặt ứng dụng cùng cơ sở dữ liệu | — | Chưa có |
| Công cụ tiêm lỗi tại kho dữ liệu/cơ sở dữ liệu | — | Chưa có |

Bộ dữ liệu `v1` tại `integration_test/support/it_fixtures.dart` là **bản cũ và
không hợp lệ cho chức năng học sau BR-142/BR-144**: hồ sơ “New” của nó có `due_at`,
và thao tác chuyển trạng thái không chứng minh `learned_at`. Agent MUST NOT dùng
v1 để kết luận kịch bản học hoặc kịch bản thẻ đến hạn. Các dòng danh mục phụ thuộc `S-DUE` hay
`S-PROGRESS` giữ `FIXTURE-BLOCKED` cho tới khi v2 dưới đây được triển khai.

### 6.2. Bộ dữ liệu Study v2 bắt buộc nhưng chưa triển khai

| | |
|---|---|
| **Đường dẫn hiện vật** | `integration_test/support/it_study_fixtures.dart` |
| **Đường dẫn công cụ kiểm tra chỉ đọc** | `integration_test/support/it_study_audit.dart` |
| **Phiên bản** | `v2` |
| **Tình trạng** | Chưa có — mọi chuẩn bị `S-STUDY-*` và kịch bản cần kiểm tra chỉ đọc v2 là `FIXTURE-BLOCKED` |
| **Đồng hồ** | `T0`; mọi `due_at` lưu UTC nhưng kết quả mong đợi tính theo `Asia/Seoul` |
| **Đặt lại** | Trình nạp MUST xóa sạch trước khi nạp dữ liệu; nạp hai lần cho đúng một kết quả |
| **Đường ghi** | Nội dung qua kho dữ liệu; trạng thái đã học/ôn tập MUST được tạo bằng luồng học đã phê duyệt hoặc API dữ liệu dựng sẵn kiểm tra bất biến 24/25/28, không dùng SQL tùy hứng trong kịch bản |

#### S-DUE / S-PROGRESS / S-STUDY-MIXED-EB-V2

`S-DUE` và `S-PROGRESS` là hai tên tương thích cho hồ sơ v2 sau, không phải hồ sơ
v1 cũ. Bộ thẻ gốc Eight Box `Due library` có:

- `Mixed due`: bốn thẻ — `C-P-NEW` chưa học (`learned_at/due_at = NULL`);
  `C-P-BEGIN` đã học, beginning, flagged, due `T0 − 5 phút`; `C-P-REVIEW` đã
  học, reviewing, due `T0 − 1 ngày`; `C-P-MASTER` đã học, mastered, due
  `T0 + 30 ngày`.
- `No due group > Future only`: một thẻ đã học, đang ôn tập, đến hạn tại `T0 + 2 ngày`.

Kết quả mong đợi tại `T0`: bộ thẻ gốc có tổng 5, `New 1`, `Due 2`; `Mixed due`
có `All 4`, `New 1`, `Due 2`, `Flagged 1`, `Mastered 1/4 (25%)`. Hồ sơ này đồng
thời là `S-STUDY-MIXED-EB-V2`; thẻ mới và thẻ đến hạn tách biệt hoàn toàn.

#### S-STUDY-FUTURE-EB-V2

Bộ thẻ gốc Eight Box có ít nhất hai thẻ đã học, không có thẻ mới, mọi `due_at > T0`.
Thẻ gần nhất đến hạn tại `2026-08-06T00:00:00+09:00`; thẻ còn lại đến hạn muộn hơn.
Kết quả mong đợi tại màn vào học ở `T0`: `New 0`, `Due 0` và có thể nêu chính xác hạn gần nhất.

#### S-STUDY-BROKEN-OPTIONS-V2

Bộ thẻ gốc Eight Box có 21 thẻ mới theo dữ liệu `limit-001`…`limit-021`, không
có giá trị ghi đè của chức năng học có thể đọc được; dữ liệu lỗi chỉ làm cấu hình
bộ thẻ gốc không thể phân tích. Cài đặt ứng dụng vẫn là mặc định 20/`Created`.
Kết quả mong đợi: màn tùy chọn giải thích hoặc hiện giá trị mặc định đang có hiệu
lực, màn vào học vẫn mở được, phiên học mới chọn đúng 20 thẻ cũ nhất. Không sửa
cấu hình hỏng trong lúc đọc để làm kịch bản đạt.

#### S-STUDY-REVIEW-EB-V2

Năm thẻ Eight Box đã học và đều đến hạn, năm nghĩa đã chuẩn hóa khác nhau. Chỉ
ba thẻ có `example`. `ST-01` ở hộp 4, `ST-02` ở hộp 8; các thẻ còn lại ghi rõ
hộp và mọi `due_at` khác nhau để kiểm thứ tự. Số lượng chế độ mong đợi: `Match 5`,
`Guess 5`, `Recall 5`, `Fill 3`; `Browse` không phải chế độ ôn tập.

#### S-STUDY-REVIEW-EB-MINIMAL-V2

Một thẻ Eight Box đã học và đến hạn, không có `example`. Kết quả mong đợi ở màn
chọn chế độ: `Match` bị vô hiệu hóa, `Guess` bị vô hiệu hóa, `Fill` có số lượng
0 và bị vô hiệu hóa, `Recall` có số lượng 1 và được bật.

#### S-STUDY-FILL-V2

Một thẻ Eight Box đã học và đến hạn: mặt trước `Nghề nghiệp`, mặt sau `Công`, câu
ví dụ `Đây là một công việc tốt.`, gợi ý `Bắt đầu bằng C`. `Fill` có số lượng 1
và được bật. Bộ dữ liệu dựng sẵn MUST không chứa dữ liệu nhập thô từ bất kỳ lần chạy trước.

#### S-STUDY-GUESS-BLOCKED-V2

Năm nghĩa hợp lệ được báo khả dụng ở màn chọn chế độ, sau đó công cụ tiêm lỗi đã
phê duyệt làm nguồn phương án nhiễu của đúng câu hỏi hiện tại chỉ trả được ba
phương án nhiễu hợp lệ. Cơ sở dữ liệu vẫn nguyên vẹn. Kết quả mong đợi là nhánh
chặn BR-124, không phải bỏ qua giai đoạn và không phải câu hỏi bốn lựa chọn.

#### S-STUDY-GUESS-SOURCE-V2

Bộ thẻ gốc Eight Box A có một thẻ đã học và đến hạn làm câu hỏi, bốn thẻ đã học
nhưng chưa đến hạn có bốn `back_folded` khác nhau làm phương án nhiễu, thêm một
thẻ đã học có nghĩa chỉ khác chữ hoa/khoảng trắng với một phương án nhiễu, và
một thẻ mới mang nghĩa `new-only-secret`. Bộ thẻ gốc Eight Box B có thẻ đã học
mang nghĩa `other-root-secret`. Câu hỏi mong đợi ở bộ thẻ gốc A có đúng năm lựa
chọn: đáp án đúng xuất hiện một lần và bốn nghĩa đã học khác nhau trong bộ A;
không lộ thẻ mới, không lấy thẻ từ bộ B, không hiện hai nghĩa cùng `back_folded`.

#### S-STUDY-REVIEW-SM2-V2

Bốn thẻ SM-2 đã học và đến hạn, có trạng thái trước lượt được ghi rõ để kiểm
`Again`/`Hard`/`Good`/`Easy`. Màn vào học chỉ có một chế độ ôn tập `self_assess`.

#### S-STUDY-RESUME-V2

Một phiên cùng ngày ở trạng thái `in_progress` có điểm lưu giữa giai đoạn/vòng,
gồm biến thể `recall` còn 12,4 giây và chưa lật. Bộ dữ liệu dựng sẵn MUST lưu
hàng đợi, vị trí hiện tại và phiên; không giả lập bằng trạng thái widget.

#### S-STUDY-FAILURE-V2

Một cơ sở dữ liệu kiểm thử dùng công cụ tiêm lỗi có ba chế độ: lỗi ghi một lần
rồi phục hồi, lỗi lưu trữ không thể tiếp tục, và lỗi đọc thẻ một lần rồi phục hồi.
Công cụ tiêm lỗi MUST không sửa dữ liệu người dùng và MUST có bước kết thúc xác nhận đã tắt lỗi.

### 6.3. Bộ dữ liệu v1 cũ — đã xoá ở bước 7

`integration_test/support/it_fixtures.dart` **không còn tồn tại**. Nó nạp dữ
liệu cho các kịch bản `HOST-FLOW`/`HOST-WIDGET` nay chạy bằng `flutter test`, và
chính nó là thứ ghi thẳng vào bảng trạng thái ôn tập — đường ghi mà mục này vẫn
luôn nói là MUST NOT dùng làm bằng chứng chức năng học.

Fixture của các kịch bản host sống ở `test/helpers/fixtures/study_fixtures.dart`.
Chúng dựng dữ liệu trên SQLite in-memory trong tiến trình test, nên "không được
ghi vào database" — luật viết cho một thiết bị — không áp vào chúng.

Tám kịch bản `DEVICE-E2E` còn lại **không dùng loader nào**: mỗi kịch bản tạo
đúng trạng thái tối thiểu nó cần, qua giao diện, bằng `ItRobot`. Đó là điều kiện
tiên quyết chứ không phải bước, và nó giữ cho bộ device không mọc lại một tầng
fixture thứ hai.

### S-DUE · S-PROGRESS · S-LARGE — không còn là hồ sơ của bộ device

Ba hồ sơ này mô tả dữ liệu cho kịch bản khám phá, tiến độ và danh sách lớn. Cả
ba nay chạy ở host: `S-LARGE` là `test/integration/flows/card_window_flow_test.dart`
(65 thẻ, cửa sổ 50 → 65), `S-DUE`/`S-PROGRESS` là `sDue`/`sProgress` trong
`test/helpers/fixtures/study_fixtures.dart`.

Đặc tả dữ liệu của chúng vẫn có giá trị như **hợp đồng**, nhưng nơi hiện thực
hợp đồng ấy đã đổi. Agent MUST NOT dựng lại loader v1 trong `integration_test/`.

## 7. Hợp đồng dọn dẹp

| ID dọn dẹp | Hành động |
|---|---|
| `CLEAN-RESET` | Xác nhận đúng gói ứng dụng kiểm thử rồi xoá dữ liệu ứng dụng; mở lại và kiểm tra trạng thái rỗng |
| `CLEAN-DELETE-CREATED` | Xoá bằng giao diện mọi bộ thẻ/thẻ do kịch bản tạo; nếu không thể hoàn tất thì dùng `CLEAN-RESET` |
| `CLEAN-PRESERVE` | Không xoá; chỉ dùng khi nhiệm vụ nói rõ kịch bản sau phải nhận trạng thái này |
| `CLEAN-NONE` | Kịch bản không làm thay đổi dữ liệu |

Danh mục mặc định dùng `CLEAN-RESET` để giữ tính độc lập. Agent MUST ghi bước dọn dẹp
đã chạy hay bị chặn trong báo cáo.

## 8. Kết luận và bằng chứng

### 8.1. Trạng thái lần chạy

| Trạng thái | Khi nào dùng |
|---|---|
| `PASS` | Tất cả bước và kết quả quan sát khớp |
| `FAIL` | Chuẩn bị hợp lệ, thao tác tới được, nhưng ít nhất một kết quả sai |
| `BLOCKED` | Không dựng được phần chuẩn bị/mức sẵn sàng hoặc không điều khiển được môi trường |
| `KNOWN-GAP-CONFIRMED` | Kịch bản `KNOWN-GAP` tái hiện đúng khoảng trống đã ghi |
| `DOC-DRIFT` | Kịch bản/danh mục/UC/BR mâu thuẫn hoặc kết quả mong đợi không đủ xác định |
| `NOT-RUN` | Chưa thực thi |

Agent MUST NOT đổi `BLOCKED` thành `PASS`, và MUST NOT coi
`KNOWN-GAP-CONFIRMED` là sản phẩm đạt.

### 8.2. Bằng chứng tối thiểu

- Một ảnh hoặc hiện vật ở kết quả cuối của kịch bản.
- Ảnh tại bước thất bại đầu tiên nếu trạng thái là `FAIL`.
- Ghi nhận bản dựng/biến thể, nền tảng, ngôn ngữ và ID chuẩn bị.
- Với khởi động lại/ngoại tuyến/deep link: ghi nhận hành động môi trường đã thực hiện.
- Với số lượng/bộ lọc/tiến độ: ghi giá trị thực tế và mong đợi bằng số.
- Không đưa nội dung thẻ cá nhân, SQL, dấu vết ngăn xếp hoặc bí mật vào báo cáo.

### 8.3. Mẫu báo cáo

```markdown
Scenario: IT-...
Run status: PASS | FAIL | BLOCKED | KNOWN-GAP-CONFIRMED | DOC-DRIFT | NOT-RUN
Build: development
Platform: Android <version/device>
Locale/timezone: vi / Asia/Seoul
Setup: SETUP-...
Started at: <ISO-8601>

| Step | Result | Evidence | Note |
|---|---|---|---|
| 1 | PASS/FAIL/BLOCKED | <artifact path> | <actual vs expected> |

First divergence: <step or none>
Cleanup: <ID + PASS/BLOCKED>
```

## 9. Quy tắc đối chiếu không mơ hồ

### 9.1. Thứ tự tiêu chí kết luận

1. Ưu tiên tiêu chí người dùng quan sát được: nội dung hiển thị/vai trò ngữ nghĩa,
   thẻ đang hiện, tiến độ, số lượng, trạng thái hành động, điều hướng và kết quả
   còn đúng sau khi khởi động lại.
2. Hành động ngoài ứng dụng chỉ hợp lệ khi hồ sơ thực thi khai báo, và bằng chứng
   MUST ghi rõ tác động đã thực hiện (đồng hồ, tiến trình, chế độ máy bay, bề mặt thứ hai).
3. Trạng thái lưu trữ không có bề mặt giao diện (ví dụ `kind`, `generation`, phiên
   bản chính sách) chỉ được kiểm qua **công cụ kiểm tra chỉ đọc đã phê duyệt** trong
   hợp đồng dữ liệu dựng sẵn. Công cụ này MUST NOT nạp, sửa hoặc chữa dữ liệu sau thao tác giao diện.
4. Chưa có tiêu chí nhìn thấy hoặc hiện vật kiểm tra chỉ đọc thì kết luận `BLOCKED`;
   MUST NOT đọc logic triển khai rồi suy rằng kịch bản đã đạt.

Mọi thao tác tạo bộ thẻ/thẻ, bắt đầu phiên, trả lời, `Retry`, thoát và `Reset` vẫn
MUST đi qua giao diện. Kiểm tra chỉ đọc chỉ là tiêu chí sau thao tác, không thay người dùng thực hiện
nghiệp vụ.

### 9.2. Cách mở rộng tiền điều kiện

- Mã chuẩn bị trong danh mục dựng trạng thái nền sạch; phần **Tiền điều kiện** của
  kịch bản MAY yêu cầu agent đi tiếp bằng giao diện tới đúng giai đoạn/vòng/thẻ.
- Agent MUST ghi các thao tác mở rộng đó vào nhật ký chạy. Không được coi một câu
  như “phiên đang dở” là quyền tự nạp phiên nếu hợp đồng dữ liệu dựng sẵn không nói vậy.
- Nếu tiền điều kiện gọi tên bộ dữ liệu/hồ sơ thực thi không khớp danh mục, kết luận
  `DOC-DRIFT` trước bước 1.

### 9.3. Quy tắc kết quả mong đợi

- `A hoặc B` chỉ hợp lệ khi kịch bản hoặc hướng dẫn liệt kê cả A và B là hai kết quả
  được chấp nhận. Kết quả khác là `FAIL`.
- “Thông báo dễ hiểu” nghĩa là có nội dung hướng tới người dùng mô tả nguyên nhân/hành động;
  nội dung MUST NOT chứa SQL, dấu vết ngăn xếp, lớp ngoại lệ hoặc ID kỹ thuật.
- Với nội dung đã bản địa hóa, đối chiếu ý nghĩa và vai trò ngữ nghĩa; chỉ đối chiếu nguyên văn khi
  kịch bản đặt chuỗi trong dấu ngoặc kép.
- Thành phần bị vô hiệu hóa có thể không nhận thao tác chạm. Agent đối chiếu rằng thành phần không kích hoạt và
  lý do vẫn quan sát được; không gọi callback trực tiếp để chứng minh.
- Nếu kết quả mong đợi vẫn có hai cách hiểu sau khi áp dụng các quy tắc trên, kết luận
  `DOC-DRIFT` và dừng tại bước đó.
