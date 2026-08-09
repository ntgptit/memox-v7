# Bộ kịch bản kiểm thử tích hợp theo hành trình người dùng

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Định nghĩa phạm vi, điểm bắt đầu và dữ liệu chung cho người hoặc AI agent thực thi kịch bản IT trên chức năng hiện có |
| **Scope** | Điều hướng, bộ thẻ, thẻ ghi nhớ, chức năng học theo UC-05 và Đặt lại tiến độ học theo UC-07; ngoài phạm vi là bộ thẻ mẫu, đồng bộ và máy chủ |
| **Source of truth for** | Chỉ mục và quy ước thực thi bộ kịch bản IT hiện tại |
| **Depends on** | `../product.md`, `../business-rules.md`, `../use-cases.md`, `../wbs.md`, `../wbs-study.md`, `../wireframes/m5-study-modes.md` |
| **Updated by task** | Refactor IT theo Testing Pyramid — ba execution profile |
| **Last updated** | 2026-08-09 |

## 1. Mục tiêu

Bộ tài liệu này mô tả MemoX hoạt động đúng ở mức hành trình người dùng. **Nó
không nói kịch bản phải chạy ở đâu** — cột `Profile` của
[`scenario-catalog.md`](scenario-catalog.md) nói điều đó, và luật chọn nằm ở
[`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md).

**Ba hồ sơ, và cái tên nói đúng chỗ chạy:**

| Profile | Chạy bằng | Chứng minh cái gì |
|---|---|---|
| `HOST-FLOW` | `flutter test` | Luật nghiệp vụ, scheduler, truy vấn, transaction, hàng đợi, `due_at`, resume — qua use case và repository thật trên SQLite in-memory thật |
| `HOST-WIDGET` | `flutter test` | Người dùng thao tác được qua giao diện Flutter thật, và giao diện phản ánh đúng state nghiệp vụ |
| `DEVICE-E2E` | emulator/thiết bị | Chỉ ranh giới với hệ điều hành: khởi động nguội, chết tiến trình, deep link, cử chỉ nền tảng, smoke phát hành |

**Luật cũ "mọi bước kiểm tra MUST đi qua UI" đã được thu hẹp về đúng chỗ của
nó.** Nó vẫn áp cho `DEVICE-E2E`: ở đó, gọi thẳng repository là bỏ qua chính cái
ranh giới đang cần chứng minh. Nhưng áp nó cho *mọi* kịch bản là lý do khiến
127/127 kịch bản đòi emulator, và vì thế không kịch bản nào chặn được một pull
request nào. Một luật `due_at` chứng minh bằng use case + SQLite thật là bằng
chứng **mạnh hơn**, không yếu hơn, so với việc đọc một con số trên màn hình.

Một bộ dữ liệu dựng sẵn MAY được dùng để chuẩn bị trạng thái. Với `DEVICE-E2E`
nó vẫn phải có đường dẫn hiện vật và phiên bản; với hai hồ sơ host thì test tự
tạo database của chính nó, nên "dựng sẵn" chỉ là mã dựng hàng.

Từ M5, hai tập thẻ học MUST tách hẳn theo BR-142: **Học mới** có `learned_at IS
NULL`; **Ôn tập** có `learned_at IS NOT NULL AND due_at <= now`. Thẻ mới không
được gọi là “đến hạn”. Bộ dữ liệu dựng sẵn hoặc kịch bản cũ nào còn dùng định nghĩa trước M5 là
`DOC-DRIFT`, không phải bằng chứng cho sản phẩm.

Phần chức năng học gồm **64 kịch bản** tách theo năm tệp năng lực; không phải 64
ca trong Bảng quyết định. Mỗi ID là một hành trình người dùng có tiền điều kiện,
thao tác, tiêu chí kết luận và mức sẵn sàng độc lập.

Bốn kịch bản Navigation liên quan trực tiếp tới chức năng học là `IT-NAV-002` và
`IT-NAV-008` tới `IT-NAV-010`. Vì vậy tổng phạm vi Study cần kiểm kê khi chạy là
**68 kịch bản**: 64 kịch bản năng lực Study cộng bốn kịch bản điều hướng.

AI agent MUST đọc theo thứ tự:

1. File này — phạm vi và dữ liệu nghiệp vụ chung.
2. [`00-agent-execution-guide.md`](00-agent-execution-guide.md) — cách chuẩn bị,
   kết luận và báo cáo mà không suy đoán.
3. [`scenario-catalog.md`](scenario-catalog.md) — mức sẵn sàng, hồ sơ thực thi,
   chuẩn bị, dọn dẹp và truy vết của đúng ID kịch bản.
4. Tệp năng lực chứa các bước của kịch bản.

## 2. Phạm vi hiện tại

| Nhóm | Trạng thái | Tài liệu |
|---|---|---|
| Giao thức thực thi cho AI agent | Bắt buộc đọc | [`00-agent-execution-guide.md`](00-agent-execution-guide.md) |
| Danh mục từng ID kịch bản | Bắt buộc tra cứu | [`scenario-catalog.md`](scenario-catalog.md) |
| Khởi động, điều hướng, tiếp tục | Có thể kiểm thử | [`01-navigation-and-continuity.md`](01-navigation-and-continuity.md) |
| Vòng đời bộ thẻ gốc | Có thể kiểm thử | [`02-root-deck-lifecycle.md`](02-root-deck-lifecycle.md) |
| Cây bộ thẻ, `content_type`, di chuyển | Có thể kiểm thử | [`03-deck-tree-and-content-type.md`](03-deck-tree-and-content-type.md) |
| Tìm kiếm, lọc, sắp xếp, tiến độ bộ thẻ | Có thể kiểm thử | [`04-deck-discovery-and-progress.md`](04-deck-discovery-and-progress.md) |
| Vòng đời thẻ | Có thể kiểm thử | [`05-card-lifecycle.md`](05-card-lifecycle.md) |
| Tìm kiếm, siêu dữ liệu, lọc, tiến độ thẻ | Có thể kiểm thử | [`06-card-discovery-and-organization.md`](06-card-discovery-and-organization.md) |
| Điểm vào chức năng học và tùy chọn | Có thể kiểm thử | [`07-study-entry-and-options.md`](07-study-entry-and-options.md) |
| Phiên học mới | Có thể kiểm thử | [`08-study-learning-session.md`](08-study-learning-session.md) |
| Phiên ôn tập và thuật toán xếp lịch | Cần bộ dữ liệu Study v2 cho phần lớn kịch bản | [`09-study-review-session.md`](09-study-review-session.md) |
| Sáu chế độ học | Có thể kiểm thử; một số ca biên cần dữ liệu dựng sẵn | [`10-study-modes.md`](10-study-modes.md) |
| Tiếp tục phiên, ngoại tuyến và lỗi | Hỗn hợp `READY`/`FIXTURE-BLOCKED` | [`11-study-continuity-and-failures.md`](11-study-continuity-and-failures.md) |

Các luồng sau MUST NOT được ghi nhận là đạt của sản phẩm hiện tại:

- UC-01 — thư viện bộ thẻ khởi đầu chưa có giao diện.
- Đổi trực tiếp thuật toán xếp lịch của bộ thẻ gốc đã khóa mà không đi qua
  Đặt lại tiến độ học không phải luồng được hỗ trợ.
- Nhập/xuất, nội dung đa phương tiện, xác thực, đồng bộ và máy chủ nằm ngoài MVP hiện tại.

## 3. Quy ước kịch bản

| Trường | Ý nghĩa |
|---|---|
| ID | Ổn định theo năng lực: các nhóm cũ và `IT-STUDY`, `IT-LEARN`, `IT-REVIEW`, `IT-MODE`, `IT-CONT` |
| Ưu tiên `P0` | Luồng chính hoặc bất biến nghiệp vụ; hỏng thì không thể tin cậy hoặc phát hành năng lực tương ứng, đặc biệt chức năng học |
| Ưu tiên `P1` | Chức năng quan trọng nhưng có đường vòng hoặc không chặn luồng chính |
| Ưu tiên `P2` | Trạng thái phụ, usability hoặc dữ liệu lớn |
| Tiền điều kiện | Trạng thái có trước khi người dùng bắt đầu kịch bản |
| Các bước | Thao tác nghiệp vụ qua bề mặt nhìn thấy; tiêu chí chỉ kiểm được ở dữ liệu lưu trữ phải dùng công cụ kiểm tra chỉ đọc theo hướng dẫn thực thi |
| Hậu điều kiện | Dữ liệu còn lại để quyết định có thể nối kịch bản hay phải đặt lại dữ liệu ứng dụng |

Mức sẵn sàng (`Readiness`), hồ sơ thực thi, chuẩn bị và dọn dẹp không lặp lại trong từng
kịch bản. Chúng nằm trong một dòng duy nhất theo ID tại `scenario-catalog.md`.
Giá trị dọn dẹp chính là hợp đồng hậu điều kiện để kịch bản kế tiếp không vô
tình nhận dữ liệu sót lại.

Mỗi kịch bản SHOULD chạy độc lập. Nếu chạy nối chuỗi, người kiểm thử MUST dùng đúng hậu
điều kiện của kịch bản trước làm tiền điều kiện cho kịch bản sau.

### 3.1. Thuật ngữ dành cho người rà soát và AI agent

Phần diễn giải MUST dùng tiếng Việt có dấu. Chỉ giữ tiếng Anh trong dấu backtick
khi đó là enum, tên trường dữ liệu, mã chuẩn bị hoặc nhãn phải đối chiếu nguyên văn.

| Cách gọi trong tài liệu | Giá trị canonical khi cần đối chiếu |
|---|---|
| phiên học thẻ mới | `learning` |
| phiên ôn tập | `reviewing` |
| giai đoạn học | `stage` |
| chế độ học | `mode` |
| hàng đợi | `queue` |
| tập thẻ đã chốt khi mở phiên | `snapshot` |
| thuật toán xếp lịch | `scheduler` |
| bộ dữ liệu dựng sẵn | `fixture` |
| tiêu chí kết luận | `oracle` |
| thẻ mới / thẻ đến hạn | nhãn `New` / `Due` nếu giao diện dùng đúng hai nhãn này |

AI agent MUST hiểu cột bên trái là ngôn ngữ rà soát; cột bên phải chỉ dùng để
đối chiếu tài liệu kỹ thuật hoặc giao diện, không phải một khái niệm thứ hai.

## 4. Môi trường và dữ liệu chuẩn

### 4.1. Môi trường

- Target chính: Android, locale tiếng Việt, kích thước màn hình điện thoại.
- Web MAY dùng làm kênh E2E development nhưng không thay thế vòng xác nhận Android.
- Với kịch bản ngoại tuyến, bật chế độ máy bay **sau khi ứng dụng và dữ liệu kiểm thử đã sẵn sàng**.
- “Khởi động lại ứng dụng” nghĩa là đóng hẳn tiến trình rồi mở lại, không chỉ chuyển tab.

### 4.2. Dữ liệu tạo qua UI

| Mã | Dữ liệu |
|---|---|
| `D-EB` | Bộ thẻ gốc `Giao tiếp hằng ngày`, thuật toán Eight Box |
| `D-SM2` | Bộ thẻ gốc `IELTS 2026`, thuật toán SM-2 |
| `D-BRANCH` | Bộ thẻ con `Vocabulary`, loại `deck` sau khi có bộ thẻ con |
| `D-LEAF` | Bộ thẻ con `Academic words`, loại `card` sau khi tạo thẻ đầu tiên |
| `C-001` | Mặt trước `abandon`, mặt sau `từ bỏ`, câu ví dụ `He abandoned the plan.`, phát âm `/əˈbændən/` |
| `C-002` | Mặt trước `benevolent`, mặt sau `nhân từ`, gợi ý `starts with bene`, nhãn `IELTS` |
| `C-003` | Mặt trước `concise`, mặt sau `ngắn gọn`, nhãn `Writing`, đã gắn cờ |

### 4.3. Dữ liệu seed dành riêng cho trạng thái học

Các mã `S-PROGRESS`, `S-DUE`, `S-LARGE` và `S-STUDY-*` có hợp đồng xác định tại
[`00-agent-execution-guide.md`](00-agent-execution-guide.md). Loader v1 hiện có
chỉ còn hợp lệ cho `S-LARGE`; `S-PROGRESS`/`S-DUE` v1 đã bị thay thế vì vi phạm
BR-142/BR-144. Bộ nạp và công cụ kiểm tra Study v2 chưa có nên catalog giữ các kịch bản tương
ứng ở `FIXTURE-BLOCKED`.

Agent MUST NOT tự tạo SQL hoặc sửa cơ sở dữ liệu để vượt trở ngại. Dữ liệu dựng sẵn MUST dùng nội
dung giả, không dùng dữ liệu cá nhân thật.

## 5. Traceability nghiệp vụ

| Nguồn | Scenario chính |
|---|---|
| UC-02 — tạo bộ thẻ gốc | `IT-DECK-001`, `IT-DECK-002`, `IT-DECK-003`, `IT-DECK-004` |
| UC-03 — sửa/xoá bộ thẻ | `IT-DECK-005`, `IT-DECK-006`, `IT-DECK-007`, `IT-DECK-008`, `IT-TREE-007`, `IT-TREE-008`, `IT-TREE-014` |
| UC-04 — quản lý thẻ | `IT-CARD-001` tới `IT-CARD-011`; `IT-ORG-001` tới `IT-ORG-012` |
| UC-06 — danh sách bộ thẻ và tiến độ | `IT-DISC-001` tới `IT-DISC-008`; `IT-ORG-011` |
| UC-08 — tạo phần tử con, xác lập loại | `IT-TREE-001` tới `IT-TREE-008`; `IT-TREE-013` |
| UC-09 — di chuyển bộ thẻ | `IT-TREE-009` tới `IT-TREE-013` |
| UC-05 — điểm vào và tùy chọn | `IT-STUDY-001` tới `IT-STUDY-013` |
| UC-05 — điều hướng Study | `IT-NAV-002`, `IT-NAV-008` tới `IT-NAV-010` |
| UC-05 — học mới | `IT-LEARN-001` tới `IT-LEARN-012` |
| UC-05 — ôn tập và thuật toán xếp lịch | `IT-REVIEW-001` tới `IT-REVIEW-010` |
| UC-05 — StudyMode | `IT-MODE-001` tới `IT-MODE-015` |
| UC-05 — tiếp tục và lỗi | `IT-CONT-001` tới `IT-CONT-014` |
| M4.12 — trình diễn E2E bộ thẻ/thẻ | `IT-NAV-006`, `IT-NAV-007`, các kịch bản `UI-FIXTURE` và `UI-LARGE` |

Bảng trên giúp người đọc định hướng. Traceability machine-readable theo từng ID
nằm tại [`scenario-catalog.md`](scenario-catalog.md) và là nguồn chuẩn.

## 6. Definition of ready cho AI agent

Một kịch bản chỉ sẵn sàng để agent chạy khi:

- ID tồn tại đúng một lần trong tệp kịch bản và đúng một lần trong danh mục.
- Catalog ghi `READY`.
- Mã chuẩn bị có công thức hoặc hiện vật đã được triển khai.
- Agent điều khiển được nền tảng và hồ sơ thực thi yêu cầu.
- Kết quả mong đợi có thể kết luận theo quy tắc kiểm tra trong hướng dẫn thực thi.

Thiếu một điều kiện trên thì agent MUST báo `BLOCKED` hoặc `DOC-DRIFT`; không tự
điền phần còn thiếu bằng phỏng đoán.
