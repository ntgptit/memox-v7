# Kịch bản IT — Phiên học thẻ mới

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh thẻ chưa học đi đúng chuỗi giai đoạn, vòng và điều kiện hoàn tất trước khi nhận lịch đầu tiên |
| **Scope** | Loại phiên `learning`, chuỗi Eight Box/SM-2, bỏ qua giai đoạn, vòng lặp, học lại trong `Self assess`, hoàn tất và giới hạn mỗi phiên |
| **Source of truth for** | Kịch bản IT về phiên Học mới của UC-05 |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, `../business-rules.md` (BR-23…30, BR-97…119, BR-139…149), `../use-cases.md` (UC-05) |
| **Updated by task** | Bổ sung kịch bản IT cho chức năng học, rà soát đệ quy ba vòng và chuẩn hóa tiếng Việt ngày 2026-08-08 |
| **Last updated** | 2026-08-08 |

## IT-LEARN-001 — Eight Box đi đúng chuỗi năm giai đoạn

> **Tách thành** — `IT-LEARN-001` (`HOST-FLOW`) · `IT-LEARN-001W` (`HOST-WIDGET`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Học mới | Giai đoạn đầu là `Browse`; người dùng không được chọn giai đoạn |
| 2 | Đi hết `Browse` | Chuyển sang `Match`, không nhảy thẳng tới giai đoạn khác |
| 3 | Hoàn tất mỗi vòng `Match` bằng kết quả đúng | Chuyển lần lượt sang `Guess`, `Recall`, rồi `Fill` |
| 4 | Hoàn tất `Fill` | Phiên chuyển sang `completed` và hiện tổng kết |
| 5 | Quan sát toàn hành trình | Chuỗi chính xác `Browse → Match → Guess → Recall → Fill`; không có `Self assess` |

## IT-LEARN-002 — SM-2 đi đúng chuỗi `Browse` rồi `Self assess`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SM2-4`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Học mới | Mở `Browse`, không có màn chọn giai đoạn |
| 2 | Đi hết bốn thẻ ở `Browse` | Chuyển sang `Self assess` |
| 3 | Với mỗi thẻ, lật rồi chọn `Good` | Không xuất hiện `Match`, `Guess`, `Recall` hoặc `Fill` |
| 4 | Hết hàng đợi | Phiên chuyển sang `completed` và hiện tổng kết |

## IT-LEARN-003 — `Browse` chỉ làm quen, hiện cả hai mặt và không chấm điểm

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; chọn Học mới để vào Browse.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát thẻ | Mặt trước và mặt sau cùng hiện, có nhãn cho hai mặt; không cần lật |
| 2 | Kiểm tra vùng hành động | Chỉ có hành động đi tiếp; không có hành động của thuật toán xếp lịch và không có đúng/sai |
| 3 | Đi qua một thẻ, đóng hẳn ứng dụng rồi chọn Tiếp tục | Thẻ đã xem ở `Browse` không quay lại; ứng dụng tiếp tục đúng điểm dừng |
| 4 | Quan sát trạng thái và hạn của thẻ trước khi hết chuỗi | Thẻ vẫn thuộc `New`, chưa có lịch ôn |

## IT-LEARN-004 — Mọi giai đoạn dùng cùng tập thẻ nhưng thứ tự độc lập

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; công cụ tự động ghi lại thứ tự mặt trước nhìn thấy.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi thứ tự năm thẻ ở `Browse` | Có đúng năm ID, không trùng và không thiếu |
| 2 | Ghi thứ tự và thẻ sở hữu lượt ở `Match` và `Guess` | Vẫn đúng cùng tập năm thẻ |
| 3 | So sánh các chuỗi | Với từ hai thẻ trở lên, giai đoạn sau không tái sử dụng nguyên chuỗi của giai đoạn trước |
| 4 | Chọn Tiếp tục giữa một giai đoạn | Thứ tự của giai đoạn đang dở không đổi chỉ vì dựng lại giao diện hoặc khởi động lại |

## IT-LEARN-005 — Thẻ thiếu câu ví dụ được bỏ qua ở `Fill` nhưng vẫn hoàn tất học mới

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-PLAIN`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đi hết `Browse`, `Match`, `Guess` và `Recall` | Năm thẻ đều tham gia các giai đoạn đủ dữ liệu |
| 2 | Tới chỗ `Fill` đáng lẽ bắt đầu | `Fill` bị bỏ qua thay vì hiện trạng thái rỗng/lỗi hoặc thẻ không có câu ví dụ |
| 3 | Quan sát tổng kết | Phiên đã `completed`; không có thẻ bị kẹt ở trạng thái chờ |
| 4 | Quay về bộ thẻ | Cả năm thẻ không còn trong tập `New` và có hạn đầu tiên vào ngày học kế tiếp |

## IT-LEARN-006 — `Guess` bị bỏ qua khi tập phiên không đủ năm nghĩa khác nhau

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-4`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Hoàn tất `Match` | Hệ thống đánh giá điều kiện `Guess` trên cả tập thẻ của phiên |
| 2 | Quan sát giai đoạn kế | Không hiển thị câu hỏi `Guess` thiếu lựa chọn và không báo lỗi |
| 3 | Tiếp tục | Chuyển tới `Recall`; các thẻ vẫn còn trong chuỗi học |

## IT-LEARN-007 — `Match` bị bỏ qua khi chỉ có một cặp

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-1`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đi hết `Browse` | `Match` không mở bàn một cặp vì đáp án sẽ hiển nhiên |
| 2 | Quan sát chuỗi tiếp theo | `Guess` cũng bị bỏ qua do thiếu dữ liệu; `Recall` vẫn chạy cho thẻ |
| 3 | Hoàn tất các giai đoạn thẻ tham gia | Thẻ vẫn được đánh dấu học xong; giai đoạn bị bỏ qua không giữ thẻ lại |

## IT-LEARN-008 — Thẻ sai trong một vòng chỉ rời tập không đạt sau vòng sạch

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới vòng 1 của `Recall`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Trong vòng 1 của `Recall`, để `ST-01` hết giờ và lật đúng bốn thẻ còn lại | `ST-01` là thẻ duy nhất thuộc tập không đạt của vòng 1 |
| 2 | Quan sát vòng 2 | Chỉ có `ST-01`, không có bản sao trùng của thẻ này |
| 3 | Để `ST-01` hết giờ ở vòng 2 và vòng 3 | Mỗi vòng kế tiếp vẫn được tạo; ứng dụng không áp trần 3 của `Self assess` cho chế độ dùng vòng |
| 4 | Quan sát vòng 4 rồi lật `ST-01` trước hạn | Vòng 4 thực sự mở; chỉ vòng sạch mới kết thúc giai đoạn |

## IT-LEARN-009 — `Self assess` lặp thẻ đúng khoảng cách và bật cờ ở trần học lại

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SM2-4`; đi hết `Browse` để tới `Self assess`; tất cả thẻ chưa được gắn cờ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Lật thẻ đầu và chọn `Again` | Thẻ chưa xuất hiện lại trước khi đã phục vụ ít nhất ba thẻ khác, hoặc ở cuối nếu hàng đợi không đủ |
| 2 | Chọn `Again` ở ba lượt học lại của cùng thẻ | Sau lượt học lại thứ ba, thẻ rời hàng đợi dù kết quả vẫn là `Again` |
| 3 | Hoàn tất phiên rồi mở danh sách thẻ | Thẻ đó được bật cờ và vẫn thuộc `New`, chưa có hạn; các thẻ khác không tự bị gắn cờ |
| 4 | Mở phiên khác | Ứng dụng không tự tắt cờ; bỏ cờ vẫn là thao tác người dùng |

## IT-LEARN-010 — Chỉ hoàn tất chuỗi mới tạo lịch đầu tiên và khóa thuật toán xếp lịch

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`, đồng hồ kiểm thử ở `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới và dừng giữa chuỗi | Thẻ đã trả lời vẫn thuộc `New`; `Due` vẫn 0; thuật toán xếp lịch của bộ thẻ gốc chưa bị coi là đã có lượt ôn theo lịch |
| 2 | Hoàn tất toàn bộ giai đoạn mỗi thẻ tham gia | Mỗi thẻ rời `New` đúng một lần; phiên chuyển sang `completed` |
| 3 | Quay về bộ thẻ tại `T0` | `New 0`, `Due 0`; không cho ôn lại cùng ngày |
| 4 | Dịch đồng hồ kiểm thử tới đầu ngày học kế tiếp | Các thẻ xuất hiện trong `Due`; hạn neo ở 00:00 địa phương, không phải `T0 + 24 giờ` |
| 5 | Mở chỉnh thuật toán xếp lịch của bộ thẻ gốc | Thuật toán đã khóa và giải thích Đặt lại tiến độ học là đường đổi duy nhất |

## IT-LEARN-011 — Giới hạn thẻ là trần mỗi phiên, không phải hạn mức ngày

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; giới hạn hiệu lực là 20.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới | Phiên chứa tối đa 20 thẻ riêng biệt dù mỗi thẻ có nhiều giai đoạn/vòng |
| 2 | Hoàn tất phiên | Tổng kết nói còn đúng 1 thẻ mới ngoài phiên và cho hành động bắt đầu phiên tiếp |
| 3 | Bắt đầu phiên thứ hai trong cùng ngày | Phiên mở với thẻ còn lại; không báo đã hết “hạn mức ngày” |
| 4 | Hoàn tất | `New` về 0; hai phiên đều có tổng kết riêng |

## IT-LEARN-012 — Bỏ dở học mới không tạo lịch nửa chừng và lần sau học lại từ `Browse`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới, đi hết `Browse`, ghép đúng một cặp rồi ghép sai một cặp `Match` | Tiến độ trong phiên được ghi, nhưng cả năm thẻ vẫn là `New` và `Due` vẫn 0 |
| 2 | Chạm ✕ và xác nhận thoát | Phiên kết thúc do người dùng; không có Tiếp tục cho phiên này |
| 3 | Đóng/mở ứng dụng rồi vào Học trong cùng ngày | `New 5`, `Due 0`; không thẻ nào bị đưa sang ôn tập chỉ vì đã đi qua một phần chuỗi |
| 4 | Bắt đầu Học mới lần nữa | Phiên mới bắt đầu từ `Browse` trên tập thẻ mới chốt; không nối thẳng vào `Match` của phiên đã bỏ |
