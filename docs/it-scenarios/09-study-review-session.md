# Kịch bản IT — Phiên ôn tập và thuật toán xếp lịch

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh phiên `reviewing` chỉ lấy thẻ đến hạn và cập nhật lịch đúng thuật toán, loại lượt và mốc ngày học |
| **Scope** | Hàng đợi thẻ đến hạn, chế độ ôn, lượt theo lịch/học lại, Eight Box, SM-2, thứ tự hạn, tổng kết và phiên kế tiếp |
| **Source of truth for** | Kịch bản IT về phiên Ôn tập của UC-05 |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, `../business-rules.md` (BR-15…30, BR-75…78, BR-105, BR-139…149, BR-154), `../use-cases.md` (UC-05) |
| **Updated by task** | Bổ sung kịch bản IT cho chức năng học, rà soát đệ quy ba vòng và chuẩn hóa tiếng Việt ngày 2026-08-08 |
| **Last updated** | 2026-08-08 |

## IT-REVIEW-001 — Hàng đợi ôn tập chỉ lấy thẻ đã học và đang đến hạn

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập và chọn `Recall` | Phiên `reviewing` mở với mẫu số 2 |
| 2 | Đi qua toàn bộ hàng đợi, ghi mặt trước đã thấy | Có đúng hai thẻ `Due`; không có hai thẻ `New` hoặc hai thẻ chưa đến hạn |
| 3 | Hoàn tất | Tổng kết không tính thẻ mới/chưa đến hạn là thẻ còn lại của phiên |

## IT-REVIEW-002 — Phiên ôn tập Eight Box chạy đúng một chế độ đã chọn

> **Tách thành** — `IT-REVIEW-002` (`HOST-FLOW`) · `IT-REVIEW-002W` (`HOST-WIDGET`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập rồi `Match` | Phiên mở tại `Match` |
| 2 | Hoàn tất hàng đợi/vòng | Không tự chuyển sang `Guess`, `Recall` hoặc `Fill` |
| 3 | Quan sát tổng kết | Phiên chuyển sang `completed` ngay khi `Match` hết; nhãn chế độ không đổi trong phiên |

## IT-REVIEW-003 — Phiên ôn tập SM-2 lấy hành động trực tiếp từ người dùng

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-SM2-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Vào thẳng `Self assess` |
| 2 | Trước khi lật | Chỉ thấy mặt trước; chưa thấy mặt sau hoặc hành động đánh giá |
| 3 | Lật | Hiện mặt sau cùng `Again`, `Hard`, `Good`, `Easy` |
| 4 | Chọn `Good` | Ghi đúng một kết quả và chuyển thẻ; không tự chấm lại lựa chọn của người dùng thành đúng/sai |

## IT-REVIEW-004 — Thẻ có hạn sớm hơn được phục vụ trước và giới hạn tính theo thẻ riêng biệt

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; đặt giới hạn thẻ là 3; `Recall` dùng được cho cả năm thẻ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đặt giới hạn thẻ là 3 và bắt đầu Ôn tập | Phiên chứa đúng ba thẻ riêng biệt dù thẻ có thể lặp ở vòng sau |
| 2 | Ghi thứ tự thẻ ở lượt đầu | Ba thẻ có `due_at` sớm nhất được phục vụ theo thứ tự tăng dần |
| 3 | Làm sai một thẻ để tạo vòng/học lại | Lượt lặp không làm một thẻ thứ tư lọt vào tập thẻ đã chốt của phiên |
| 4 | Hoàn tất | Tổng kết cho biết còn thẻ `Due` ngoài phiên |

## IT-REVIEW-005 — Lượt đầu là theo lịch, lượt lặp là học lại và không xếp lịch lần hai

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; chọn thẻ ở hộp 4 làm thẻ đầu của một phiên có chế độ chấm điểm độc lập.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở lượt đầu, trả lời sai | Thẻ được xếp về hộp 1, đến hạn đầu ngày kế tiếp; số lượt trả lời/sai tăng theo lượt `scheduled` |
| 2 | Khi thẻ quay lại, trả lời đúng | Đây là lượt `relearning`: thẻ rời hàng đợi nhưng lịch vẫn ở hộp 1/đầu ngày kế tiếp |
| 3 | Quay về bộ thẻ rồi khởi động lại | Lịch không nhảy thành hộp 2 vì lượt đúng thứ hai; kết quả đã được lưu ngay ở từng lượt |

## IT-REVIEW-006 — Eight Box đưa `Forgotten` và `Remembered` tới đúng hộp/khoảng cách

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2` có thẻ `Due` ở hộp 4 và hộp 8; đồng hồ kiểm thử ở `T0`; mỗi nhánh nạp lại bộ dữ liệu sạch.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ôn thẻ ở hộp 4 và tạo kết quả đúng | Thẻ sang hộp 5, hạn lúc 00:00 địa phương của ngày học `T0 + 16 ngày` |
| 2 | Ở một phiên độc lập, tạo kết quả sai cho thẻ ở hộp 4 | Thẻ về hộp 1, hạn lúc 00:00 địa phương của ngày học `T0 + 1 ngày` |
| 3 | Ôn thẻ ở hộp 8 với kết quả đúng | Thẻ vẫn ở hộp 8, hạn lúc 00:00 địa phương của ngày học `T0 + 128 ngày`; không biến mất như “tốt nghiệp” |

## IT-REVIEW-007 — SM-2 áp dụng `Again`/`Hard`/`Good`/`Easy` đúng thứ tự cập nhật

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-SM2-V2` có bốn bản sao độc lập với hệ số dễ 2.5, số lần lặp 2, khoảng cách 10 ngày; đồng hồ kiểm thử ở `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn `Again` cho bản 1 | Số lần lặp về 0, khoảng cách 1 ngày; hệ số dễ giảm nhưng không dưới 1.3; hạn ở đầu ngày thứ 1 |
| 2 | Chọn `Hard` cho bản 2 | Hệ số dễ mới 2.36 được dùng trước khi nhân; khoảng cách là 24 ngày, không phải 25 |
| 3 | Chọn `Good` cho bản 3 | Hệ số dễ giữ 2.5; khoảng cách là 25 ngày |
| 4 | Chọn `Easy` cho bản 4 | Hệ số dễ thành 2.6, khoảng cách thành 26 ngày; hạn neo ở 00:00 địa phương của ngày học `T0 + 26 ngày` |

## IT-REVIEW-008 — Không thể ôn lại trước hạn vừa được xếp

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Ôn tập, chọn `Match` và hoàn tất đúng mọi thẻ | Phiên chuyển sang `completed`; từng thẻ được xếp sang một hạn tương lai |
| 2 | Quay lại màn vào học ngay tại `T0`, rồi đóng/mở ứng dụng trong cùng ngày | `Due` về 0; không thẻ vừa xử lý nào mở lại được và không có đường “ôn sớm” |
| 3 | Dịch đồng hồ kiểm thử tới một giây trước 00:00 của hạn gần nhất | Thẻ vẫn chưa thuộc `Due` |
| 4 | Dịch tới đúng 00:00 địa phương của hạn gần nhất | Thẻ có hạn đó xuất hiện trong `Due`; thẻ có hạn muộn hơn vẫn chưa xuất hiện |

## IT-REVIEW-009 — Tổng kết phân biệt thẻ đã xử lý và thẻ đến hạn còn ngoài giới hạn

- **Ưu tiên:** P1
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; đặt giới hạn thẻ hiệu lực thành 3 trước khi mở phiên.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu rồi hoàn tất một phiên ôn tập | Tổng kết hiện 3 thẻ của phiên đã hoàn tất và còn đúng 2 thẻ `Due` ngoài phiên |
| 2 | Chạm bắt đầu phiên tiếp | Mở một phiên mới với tập thẻ mới chốt từ số thẻ `Due` còn lại |
| 3 | Quay lại bộ thẻ thay vì bắt đầu | Màn vào học vẫn hiển thị đúng số `Due` còn lại, không cộng lại thẻ đã xếp lịch |

## IT-REVIEW-010 — Số lượng và hàng đợi của từng chế độ không dùng chung một con số giả

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi số lượng `Match`/`Guess`/`Recall`/`Fill` | Lần lượt 5/5/5/3 |
| 2 | Chọn `Fill` | Hàng đợi có đúng ba thẻ có câu ví dụ |
| 3 | Thoát và chọn `Match` trong phiên mới | Hàng đợi có đủ năm thẻ, không bị giới hạn bởi số lượng 3 của `Fill` |
| 4 | So tổng kết hai phiên | Mỗi tổng kết dùng mẫu số của chính chế độ/phiên, không dùng số lượng chung |
