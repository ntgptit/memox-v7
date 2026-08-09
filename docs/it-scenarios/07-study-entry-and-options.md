# Kịch bản IT — Điểm vào chức năng học và tùy chọn

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh người dùng đi vào đúng loại phiên, thấy đúng khả năng học và cấu hình phiên trước khi bất kỳ lịch sử nào được ghi |
| **Scope** | Màn vào học, hai tập thẻ mới/đến hạn, màn chọn chế độ, giới hạn thẻ, thứ tự thẻ mới, tùy chọn toàn ứng dụng và ghi đè ở bộ thẻ gốc |
| **Source of truth for** | Kịch bản IT về điểm vào và tùy chọn học |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, `../business-rules.md` (BR-24, BR-29, BR-99, BR-101, BR-139, BR-142, BR-145…BR-154), `../use-cases.md` (UC-05) |
| **Updated by task** | Bổ sung kịch bản IT cho chức năng học, rà soát đệ quy ba vòng và chuẩn hóa tiếng Việt ngày 2026-08-08 |
| **Last updated** | 2026-08-08 |

## IT-STUDY-001 — Màn vào học tách thẻ mới và thẻ đến hạn thành hai tập rời nhau

> **Tách thành** — `IT-STUDY-001` (`HOST-WIDGET`) · `IT-STUDY-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở bộ thẻ và chạm Học | Màn vào học mở cho đúng bộ thẻ |
| 2 | Quan sát hai lựa chọn | Hiện `New 2` và `Due 2` thành hai lựa chọn riêng; không có tổng gộp 4 dưới một hành động |
| 3 | Mở danh sách thẻ với bộ lọc `New` rồi quay lại | Chỉ hai thẻ chưa học xuất hiện; không thẻ đến hạn nào nằm trong tập này |
| 4 | Mở bộ lọc `Due` | Chỉ hai thẻ đã học và đến hạn xuất hiện; không thẻ mới nào nằm trong tập này |

## IT-STUDY-002 — Chỉ xem số lượng hoặc huy hiệu không tạo phiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; chưa từng bấm Học mới.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở danh sách bộ thẻ gốc, danh sách thẻ và màn vào học; chỉ quan sát số lượng/huy hiệu | Mọi nơi thống nhất `New 5`, `Due 0`; chưa vào màn phiên |
| 2 | Đóng hẳn ứng dụng rồi mở lại, vào màn học | Không có hành động Tiếp tục phiên và không có tổng kết của phiên bỏ dở |
| 3 | Chạm Học mới | Chỉ lúc này phiên mới được tạo và giai đoạn đầu xuất hiện |

## IT-STUDY-003 — Không có thẻ đến hạn là trạng thái bình thường và không cho ôn sớm

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FUTURE-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở màn vào học tại `T0` | Lựa chọn Ôn tập không kích hoạt được; màn hình không báo lỗi |
| 2 | Quan sát giải thích | Hiện thời điểm thẻ gần nhất đến hạn bằng ngôn ngữ người dùng |
| 3 | Tìm mọi hành động trên màn | Không có “ôn ngay”, “ôn sớm” hoặc đường vòng mở chế độ ôn tập |
| 4 | Thử kích hoạt lựa chọn Ôn tập bằng thao tác hỗ trợ tiếp cận hoặc chạm | Mục bị vô hiệu hóa không kích hoạt; không tạo phiên và vẫn ở màn vào học |

## IT-STUDY-004 — Eight Box chỉ đưa các chế độ chấm điểm hợp lệ vào ôn tập

> **Tách thành** — `IT-STUDY-004` (`HOST-WIDGET`) · `IT-STUDY-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Hiện màn chọn chế độ cho Eight Box |
| 2 | Kiểm tra danh sách | Có `Match`, `Guess`, `Recall` và `Fill`; không có `Browse` hoặc `Self assess` |
| 3 | Quan sát từng chế độ | Mỗi chế độ có số lượng và trạng thái khả dụng riêng |
| 4 | Quay lại màn vào học mà chưa chọn chế độ | Không có phiên mới để tiếp tục |

## IT-STUDY-005 — SM-2 chỉ có một chế độ ôn nên vào thẳng `Self assess`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-SM2-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Vào thẳng phiên `Self assess`, không hiện màn chọn chỉ có một mục |
| 2 | Quan sát nhãn chế độ và mặt thẻ | Chế độ là `Self assess`; mặt sau còn ẩn |
| 3 | Lật thẻ | Hiện bốn hành động `Again`, `Hard`, `Good`, `Easy`; không có `Forgotten`/`Remembered` |

## IT-STUDY-006 — Chế độ thiếu dữ liệu bị vô hiệu hóa kèm lý do, không mở màn rỗng

> **Tách thành** — `IT-STUDY-006` (`HOST-WIDGET`) · `IT-STUDY-006F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-MINIMAL-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Cho thấy các chế độ của Eight Box |
| 2 | Quan sát `Match` | Bị vô hiệu hóa vì không đủ tối thiểu hai cặp; lý do vẫn đọc được |
| 3 | Quan sát `Guess` | Bị vô hiệu hóa vì không đủ năm nghĩa khác nhau; lý do không gợi ý Đặt lại tiến độ học |
| 4 | Quan sát `Fill` | Bị vô hiệu hóa vì không có thẻ chứa câu ví dụ (`example`); số lượng của `Fill` là 0 |
| 5 | Chọn `Recall` | Phiên mở bình thường; các chế độ bị vô hiệu hóa không chặn toàn bộ việc ôn tập |

## IT-STUDY-007 — Số lượng của từng chế độ ôn phản ánh đúng tập thẻ sử dụng được

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở màn chọn Ôn tập | `Match 5`, `Guess 5`, `Recall 5` và `Fill 3` |
| 2 | Mở `Fill` | Phiên chỉ gồm ba thẻ có câu ví dụ; mẫu số tiến độ là 3 |
| 3 | Thoát, mở lại Ôn tập và chọn `Recall` | `Recall` dùng đủ năm thẻ đến hạn; mẫu số là 5 |

## IT-STUDY-008 — Tùy chọn toàn ứng dụng được giữ sau khi khởi động lại

> **Tách thành** — `IT-STUDY-008` (`HOST-FLOW`) · `IT-PLAT-002` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; bộ thẻ gốc chưa có giá trị ghi đè.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đặt giới hạn thẻ toàn ứng dụng thành 7 và thứ tự thẻ mới thành `Random`; lưu | Có xác nhận lưu thành công, không đóng ứng dụng trước khi ghi xong |
| 2 | Đóng hẳn rồi mở lại ứng dụng | Hai giá trị vẫn là 7 và `Random` |
| 3 | Mở Học mới trên bộ thẻ không có giá trị ghi đè | Màn vào học và phiên dùng giới hạn 7, thứ tự `Random` |

## IT-STUDY-009 — Ghi đè ở bộ thẻ gốc thắng mặc định và bộ thẻ con không có cấu hình riêng

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; mặc định toàn ứng dụng là giới hạn 20/`Created`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đặt giá trị ghi đè của bộ thẻ gốc `Limit library` thành giới hạn 8/`Random` | Bộ thẻ gốc hiển thị giá trị riêng đã lưu |
| 2 | Mở tùy chọn từ bộ thẻ con `Twenty one` | Hiện giá trị hiệu lực của bộ thẻ gốc; không cho tạo giá trị ghi đè riêng cho bộ thẻ con |
| 3 | Bắt đầu Học mới từ bộ thẻ con | Phiên chốt giới hạn 8/`Random` |
| 4 | Xóa giá trị ghi đè ở bộ thẻ gốc | Lần mở phiên kế tiếp quay về 20/`Created`; phiên đang chạy không đổi |

## IT-STUDY-010 — Phiên chốt giới hạn thẻ lúc mở và không đổi theo tùy chọn sau đó

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; giới hạn thẻ hiệu lực là 20.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới | Tập thẻ đã chốt có đúng 20 thẻ riêng biệt và còn đúng 1 thẻ ngoài phiên |
| 2 | Trên một cửa sổ ứng dụng khác, đổi giới hạn thành 5 | Lưu thành công cho phiên tương lai |
| 3 | Quay lại và hoàn thành phiên đang chạy | Phiên vẫn dùng tập 20 thẻ đã chốt, không co xuống 5 |
| 4 | Bắt đầu phiên kế tiếp | Phiên mới dùng giới hạn 5 |

## IT-STUDY-011 — Phạm vi phiên là bộ thẻ đang mở và toàn bộ cây con của nó

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SCOPE`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở bộ thẻ gốc `Korean`, mở Học | Màn vào học hiện `New 5`, lấy cả hai bài trong cây |
| 2 | Tìm tùy chọn thu hẹp phạm vi trước khi bắt đầu | Không có bộ chọn phạm vi hoặc ô đánh dấu tự chọn một phần cây; người dùng chỉ chọn loại phiên |
| 3 | Quay lại, mở `Lesson A` rồi chọn Học | Màn vào học hiện `New 3`; hai thẻ của bộ thẻ cùng cấp `Lesson B` không thuộc phạm vi này |
| 4 | Bắt đầu Học mới tại `Lesson A` và ghi tập mặt trước ở `Browse` | Có đúng ba thẻ của `Lesson A`, không lẫn thẻ cùng cấp |

## IT-STUDY-012 — `Created` chọn đúng tập cũ nhất; `Random` không đổi tập đã chốt khi tiếp tục

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; thời điểm tạo thẻ phân biệt; giới hạn 7.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn `Created`, bắt đầu Học mới và ghi đủ tập thẻ ở `Browse` | Tập phiên có đúng `limit-001`…`limit-007`; không kiểm thứ tự hiển thị vì hàng đợi của giai đoạn được xáo độc lập |
| 2 | Chủ động thoát, chọn `Random`, bắt đầu phiên mới và ghi tập 7 thẻ; nếu trùng tập `Created` thì bỏ phiên và thử lại, tối đa 3 phiên `Random` | Mỗi tập đã chốt có đúng 7 thẻ riêng biệt thuộc 21 thẻ mới; mỗi lần thử lại tạo một phiên mới |
| 3 | So tối đa ba lần lấy với tập `Created` | Ít nhất một tập `Random` khác `limit-001`…`limit-007`; cả ba tập đều giống `Created` là `FAIL` |
| 4 | Trong phiên `Random` khác biệt đó, ghi tập thẻ và thứ tự, buộc đóng tiến trình rồi Tiếp tục trong cùng ngày | Đúng tập đã chốt, thẻ hiện tại và thứ tự đang dở được giữ; `Random` không chạy lại khi Tiếp tục |

## IT-STUDY-013 — Cấu hình bộ thẻ gốc không đọc được thì dùng mặc định và không chặn học

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-BROKEN-OPTIONS-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Tùy chọn học từ bộ thẻ gốc | Hiện giá trị hiệu lực mặc định 20/`Created`; không lộ JSON, ngoại lệ hoặc dấu vết ngăn xếp |
| 2 | Quay lại và mở Học | Màn vào học vẫn hiện `New 21`; lỗi cấu hình không biến thành trạng thái bị chặn hoặc trạng thái rỗng giả |
| 3 | Chọn Học mới và ghi tập thẻ ở `Browse` | Phiên mở với đúng 20 thẻ cũ nhất `limit-001`…`limit-020` |
| 4 | Thoát và mở lại Tùy chọn học | Vẫn dùng mặc định một cách xác định; ứng dụng không tự ghi giá trị đè mới nếu người dùng chưa bấm lưu |
