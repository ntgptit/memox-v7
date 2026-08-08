# Kịch bản IT — Tiếp tục phiên, ngoại tuyến và lỗi

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh phiên học tồn tại đúng qua vòng đời ứng dụng và kết thúc trung thực khi người dùng, thao tác đặt lại hoặc lỗi lưu trữ làm gián đoạn |
| **Scope** | Tiếp tục phiên, thoát chủ động, gián đoạn qua ngày, hàng đợi bất biến, xóa bộ thẻ, ngoại tuyến, lỗi ghi có thể/không thể phục hồi và thế hệ dữ liệu cũ |
| **Source of truth for** | Kịch bản IT về khả năng tiếp tục và xử lý lỗi của chức năng học |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, `../business-rules.md` (BR-25, BR-79…86, BR-102…105, BR-127, BR-133), `../use-cases.md` (UC-05, UC-07), `../wbs-study.md` (M5.9, M5.10, M5.14) |
| **Updated by task** | Bổ sung nhánh Ôn tập khi khôi phục phiên cùng ngày ngày 2026-08-08 |
| **Last updated** | 2026-08-08 |

## IT-CONT-001 — Tiến trình bị hệ điều hành thu hồi trong cùng ngày vẫn Tiếp tục đúng điểm dừng

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; người dùng chưa bấm ✕.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới, đi qua ít nhất hai lượt rồi ghi chế độ, vòng, thẻ hiện tại, tiến độ và trạng thái đang dở | Có mốc so sánh nhìn thấy được của phiên `in_progress` |
| 2 | Buộc đóng tiến trình như khi hệ điều hành thu hồi, không dùng hành động thoát trong ứng dụng | Ứng dụng đóng mà người dùng chưa chủ động bỏ phiên |
| 3 | Mở lại trong cùng ngày học và vào Học | Màn vào học có ba đường: Tiếp tục, Học mới, Ôn tập theo khả năng hiện tại |
| 4 | Chọn Tiếp tục | Quay đúng phiên/chế độ/vòng/thẻ/điểm dừng; hàng đợi và thứ tự không được dựng lại |

## IT-CONT-002 — Chọn phiên mới khi có phiên cùng ngày sẽ đóng phiên cũ do người dùng bỏ

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đã bắt đầu Học mới, đi qua ít nhất một lượt rồi buộc đóng tiến trình và mở lại cùng ngày.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Không chọn Tiếp tục; chọn Học mới | Phiên cũ được đóng và phiên `learning` mới mở; tài liệu không bắt buộc một bước xác nhận trung gian |
| 2 | Quay lại màn vào học | Phiên cũ không còn tiếp tục được; chỉ phiên mới là phiên đang chạy |
| 3 | Khởi động lại và mở màn vào học | Không xuất hiện hai phiên cùng cho Tiếp tục; chỉ trạng thái hợp lệ của phiên mới còn lại |
| 4 | Kiểm tra các lượt đã hoàn tất ở phiên cũ qua tiến độ người dùng | Kết quả đã ghi không bị hoàn tác vì bỏ phiên |

## IT-CONT-003 — Phiên từ ngày học trước bị đóng với lý do gián đoạn

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới, hoàn tất vài lượt rồi buộc đóng tiến trình mà không bấm ✕ | Phiên còn `in_progress` ở ngày học của `T0` |
| 2 | Dịch đồng hồ kiểm thử sang ngày học kế tiếp rồi mở ứng dụng | Phiên cũ không được tiếp tục như phiên cùng ngày |
| 3 | Mở màn vào học | Người dùng có thể tạo phiên mới; không thấy điểm dừng cũ giả như còn hợp lệ |
| 4 | Dùng công cụ kiểm tra chỉ đọc của Study v2 sau các thao tác giao diện | Phiên cũ là `abandoned/interrupted`, không phải `user_exit`; các lượt đã ghi trước khi đóng tiến trình vẫn giữ |

## IT-CONT-004 — Nút ✕ là thoát chủ động, không phải thao tác Quay lại vô hại

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; bắt đầu Học mới và đi qua ít nhất một lượt.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm ✕ | Có xác nhận nếu giao diện dùng; hậu quả thoát được nói rõ |
| 2 | Hủy xác nhận | Phiên vẫn nguyên điểm dừng, chưa kết thúc |
| 3 | Chạm ✕ và xác nhận | Hiện trạng thái phiên đã dừng vì người dùng thoát, không trình bày như một thành tích; có lối về bộ thẻ |
| 4 | Mở lại màn vào học | Không cho Tiếp tục phiên đã chủ động thoát; lượt đã ghi vẫn phản ánh trong tiến độ |

## IT-CONT-005 — Phiên hoàn tất có tổng kết và không còn hàng đợi chờ xử lý

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới khi phiên chỉ còn đúng một lượt hợp lệ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Hoàn tất lượt cuối | Không hiện thêm thẻ cũ hoặc vòng quay tải vô hạn |
| 2 | Quan sát tổng kết phiên học mới | Hiện số thẻ vừa hoàn tất chuỗi và số lượt sai; không có biểu đồ, chuỗi ngày học hoặc thống kê dài hạn |
| 3 | Chạm Quay về bộ thẻ | Trở về đúng bộ thẻ; số lượng phản ánh các lượt đã hoàn tất |
| 4 | Khởi động lại và mở màn vào học | Không có Tiếp tục cho phiên đã `completed` |

## IT-CONT-006 — Hàng đợi bất biến khi nội dung bộ thẻ đổi sau lúc mở phiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-RESUME-V2`; có cửa sổ ứng dụng thứ hai dùng cùng cơ sở dữ liệu kiểm thử.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi mẫu số và các thẻ đã thấy trong phiên | Có mốc so sánh cho tập thẻ đã chốt |
| 2 | Ở cửa sổ thứ hai, thêm một thẻ mới vào bộ thẻ | Thẻ mới được lưu cho bộ thẻ |
| 3 | Quay lại phiên | Mẫu số/tập thẻ không nhận thẻ mới; thứ tự hàng đợi không được dựng lại |
| 4 | Hoàn tất phần hàng đợi còn lại | Không có lượt nào của thẻ mới; thẻ đó chỉ có thể vào tập đã chốt của phiên tạo sau |

## IT-CONT-007 — Xóa bộ thẻ đang học kết thúc phiên và phục hồi điều hướng

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-RESUME-V2`; cửa sổ thứ hai có thể xóa đúng bộ thẻ/bộ thẻ gốc.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở cửa sổ thứ hai, xóa bộ thẻ và xác nhận | Bộ thẻ biến mất theo UC-03 |
| 2 | Quay lại phiên và thực hiện hành động tiếp | Ứng dụng không sập, không lộ ID/SQL và không ghi vào thẻ đã mất |
| 3 | Quan sát điều hướng | Phiên kết thúc và đưa về danh sách bộ thẻ hợp lệ |
| 4 | Khởi động lại | Bộ thẻ hoặc phiên mồ côi không xuất hiện lại |

## IT-CONT-008 — Toàn bộ phiên học hoạt động ngoại tuyến

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; ứng dụng đang mở; thiết bị điều khiển được chế độ máy bay.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bật chế độ máy bay | Ứng dụng không yêu cầu đăng nhập hoặc mạng |
| 2 | Mở màn vào học, bắt đầu và hoàn tất một phiên | Mọi chế độ/nội dung cần thiết được tải cục bộ; lượt được ghi ngay và tổng kết hiện bình thường |
| 3 | Đóng hẳn rồi mở lại khi vẫn ngoại tuyến | Phiên vẫn `completed`, trạng thái và hạn của thẻ còn đúng |
| 4 | Bắt đầu hoặc Tiếp tục một phiên khác | Không có chặn mạng giả hoặc yêu cầu thử lại kết nối |

## IT-CONT-009 — Đặt lại khi phiên đang mở làm phiên mất hiệu lực với `scheduler_reset`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; UC-07 có giao diện hoàn chỉnh; đã tạo phiên `in_progress` bằng giao diện.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Từ cửa sổ khác, Đặt lại tiến độ học của bộ thẻ gốc và xác nhận | Đặt lại thành công cho toàn cây |
| 2 | Quay lại phiên cũ | Phiên bị đóng ở trạng thái `invalidated` vì đặt lại thuật toán xếp lịch, không tiếp tục được |
| 3 | Thử đánh giá thẻ đang mở | Không ghi lượt mới và không hồi sinh thế hệ dữ liệu cũ |
| 4 | Mở lịch sử/tiến độ khả dụng | Các lượt đã ghi trước khi đặt lại vẫn được giữ ở chu kỳ cũ |

## IT-CONT-010 — Phiên thuộc thế hệ dữ liệu cũ bị từ chối nguyên tử

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-RESUME-V2`; công cụ tạo lỗi/nhiều cửa sổ tăng thế hệ dữ liệu nhưng chưa làm mất hiệu lực phiên trước khi gửi hành động.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Sau khi bộ thẻ gốc tăng thế hệ dữ liệu, gửi hành động từ phiên cũ | Hành động bị từ chối trước khi bất kỳ phần nào được ghi |
| 2 | Quan sát phiên | Phiên đóng với `invalidated/stale_generation` và giải thích tiến độ vừa được đặt lại |
| 3 | Quay về bộ thẻ | Trạng thái đang hoạt động hoàn toàn thuộc thế hệ mới |
| 4 | Kiểm tra bằng bề mặt lịch sử được phê duyệt | Không có dòng lịch sử cho hành động bị từ chối; các lượt cũ trước đó vẫn còn |

## IT-CONT-011 — Lỗi ghi tạm thời không tiến thẻ và thử lại chỉ ghi một lần

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FAILURE-V2` ở chế độ lỗi một lần rồi phục hồi.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Trả lời thẻ khi bộ tạo lỗi gây lỗi ghi đầu tiên | Hiện lỗi ngay; thẻ, tiến độ và hành động vẫn ở nguyên lượt |
| 2 | Chạm lại đúng hành động sau khi bộ tạo lỗi phục hồi | Ghi thành công và tiến đúng một thẻ |
| 3 | Khởi động lại/Tiếp tục | Không có lượt trùng do lần thử lại; lịch và trạng thái chỉ thay đổi một lần |

## IT-CONT-012 — Lỗi lưu trữ không thể tiếp tục đóng phiên ở trạng thái `failed` nhưng giữ lượt cũ

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FAILURE-V2` ở chế độ lỗi nghiêm trọng; phiên đã có ít nhất hai lượt thành công.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Thực hiện hành động tại điểm bộ tạo lỗi phát sinh lỗi nghiêm trọng | Ứng dụng không tiến sang thẻ tiếp và không giả vờ hoàn tất |
| 2 | Quan sát thông báo | Giải thích không thể tiếp tục, không lộ SQL/dấu vết ngăn xếp/nội dung riêng tư |
| 3 | Chọn lối phục hồi | Phiên đóng với `failed/persistence_error` và về danh sách bộ thẻ |
| 4 | Tắt bộ tạo lỗi, khởi động lại và xem tiến độ | Hai lượt đã thành công vẫn giữ; hành động gây lỗi không được ghi một phần |

## IT-CONT-013 — Lỗi đọc thẻ cho phép Thử lại mà không làm mất điểm dừng

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FAILURE-V2` ở chế độ lỗi đọc một lần rồi phục hồi; phiên đang ở thẻ đã biết.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đi tới thẻ mà bộ tạo lỗi làm lỗi đọc | Hiện trạng thái lỗi có Thử lại; không lộ nội dung thẻ khác, ID kỹ thuật, SQL hoặc dấu vết ngăn xếp |
| 2 | Quan sát tiến độ | Thẻ hiện tại và điểm dừng chưa bị bỏ qua; không có kết cục học giả được ghi |
| 3 | Tắt lỗi và chạm Thử lại | Chính thẻ đó tải lại thành công; phiên không bị dựng mới hoặc đổi thứ tự |
| 4 | Hoàn tất lượt bằng thao tác bình thường | Chỉ lượt người dùng vừa thực hiện được tính và phiên tiếp tục |

## IT-CONT-014 — Chọn Ôn tập khi có phiên cùng ngày đóng phiên cũ do người dùng bỏ

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2`; đã bắt đầu Học mới, hoàn tất ít nhất một lượt rồi buộc đóng tiến trình và mở lại trong cùng ngày học.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở lại Study | Màn chọn hiện đủ ba đường Tiếp tục, Học mới và Ôn tập; phiên cũ chưa bị đóng chỉ vì quan sát màn |
| 2 | Không chọn Tiếp tục; chọn Ôn tập rồi chọn một chế độ khả dụng | Phiên học mới cũ được đóng và một phiên `reviewing` mới mở; không có hai phiên cùng `in_progress` |
| 3 | Thoát phiên ôn tập rồi mở lại Study | Phiên học mới cũ không còn được mời Tiếp tục; các lượt đã ghi trước khi bỏ phiên vẫn còn trong tiến độ |
| 4 | Dùng công cụ kiểm tra chỉ đọc Study v2 | Phiên cũ là `abandoned/user_exit`, không phải `interrupted`; phiên ôn tập mang đúng loại `reviewing` |
