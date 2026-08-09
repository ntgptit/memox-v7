# Kịch bản ranh giới nền tảng

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Gom mọi bằng chứng chỉ có thiết bị/emulator mới đưa ra được vào một nhóm nhỏ, để phần còn lại của danh mục chạy trên host |
| **Scope** | Cold start · chết tiến trình · deep link từ hệ điều hành · cử chỉ back của Android · smoke trước phát hành |
| **Source of truth for** | Các kịch bản `IT-PLAT-xx` |
| **Depends on** | `12-testing-pyramid-audit.md`, `scenario-catalog.md`, `00-agent-execution-guide.md` |
| **Updated by task** | Refactor IT theo Testing Pyramid |
| **Last updated** | 2026-08-09 |

**Đây là toàn bộ những gì còn cần thiết bị.** Mọi luật nghiệp vụ mà các kịch bản
dưới đây đi qua đã được chứng minh ở `HOST-FLOW` hoặc `HOST-WIDGET`; phần việc
còn lại của nhóm này là chứng minh **ranh giới với hệ điều hành**, không phải
chứng minh lại nghiệp vụ.

Vì vậy mỗi kịch bản ở đây dựng **trạng thái tối thiểu** cần để chạm tới ranh giới
ấy. Một kịch bản `IT-PLAT` đi lại cả một luồng nghiệp vụ là một kịch bản đặt sai
chỗ.

## IT-PLAT-001 — Khởi động nguội bản đã cài đặt vào đúng danh sách bộ thẻ

- **Ưu tiên:** P0
- **Tiền điều kiện:** Bản `development` đã cài, dữ liệu ứng dụng đã xoá, không có tiến trình MemoX nào đang chạy.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở MemoX từ launcher của hệ điều hành | App khởi động, không màn đỏ, không chi tiết kỹ thuật |
| 2 | Quan sát màn hình đầu tiên | Danh sách bộ thẻ, tab Bộ thẻ đang chọn |
| 3 | Quan sát khi chưa có dữ liệu | Empty state kèm hành động tạo bộ thẻ |

Dẫn xuất từ `IT-NAV-001`. Ranh giới: bootstrap thật của engine, đường dẫn
database do nền tảng cấp, và asset bundle của bản đã cài — không thứ nào
trong ba tồn tại khi `flutter test` dựng cây widget trong tiến trình host.

## IT-PLAT-002 — Dữ liệu đã ghi sống sót qua một lần chết tiến trình thật

- **Ưu tiên:** P0
- **Tiền điều kiện:** Bản `development` đã cài, dữ liệu ứng dụng đã xoá.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tạo một bộ thẻ gốc và một thẻ trong đó | Cả hai hiện trong danh sách |
| 2 | Bật cờ cho thẻ và đổi một tùy chọn toàn ứng dụng | Cờ và tùy chọn nhận thay đổi |
| 3 | Đóng hẳn tiến trình từ trình quản lý tác vụ | App thoát hoàn toàn |
| 4 | Mở lại app | Bộ thẻ, thẻ, cờ và tùy chọn đều còn nguyên |

Dẫn xuất từ `IT-NAV-006`, `IT-DECK-001`, `IT-CARD-002`, `IT-CARD-008`,
`IT-CARD-010`, `IT-ORG-004`, `IT-STUDY-008`. Ranh giới: file database thật
trên bộ nhớ thiết bị, ghi bởi một tiến trình và đọc bởi một tiến trình khác.
**Nội dung của từng luật không kiểm ở đây** — chúng đã có ở `HOST-FLOW`; ở
đây chỉ kiểm rằng byte đã chạm đĩa.

## IT-PLAT-003 — Phiên học bị hệ điều hành thu hồi vẫn tiếp tục đúng điểm dừng

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một bộ thẻ có đủ thẻ để mở phiên học mới.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở phiên học và trả lời ít nhất một thẻ | Bộ đếm tiến lên |
| 2 | Đóng hẳn tiến trình giữa phiên | App thoát hoàn toàn |
| 3 | Mở lại và chọn Tiếp tục | Phiên mở lại đúng thẻ kế tiếp, không quay về thẻ đầu |

Dẫn xuất từ `IT-CONT-001`. Ranh giới: `study_sessions.cursor` và hàng đợi
phải nằm trên đĩa chứ không trong bộ nhớ. Chuỗi vòng, tập không đạt và lịch
thì đã có ở `HOST-FLOW`.

## IT-PLAT-004 — Deep link đi từ hệ điều hành vào đúng màn hình

- **Ưu tiên:** P1
- **Tiền điều kiện:** Một bộ thẻ đang tồn tại; app đã đóng hẳn.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Từ hệ điều hành mở deep link tới bộ thẻ đó | App mở đúng màn bộ thẻ ấy |
| 2 | Bấm back | Có lối ra hợp lệ, không kẹt màn trắng |
| 3 | Lặp lại với một link không hợp lệ | Màn 404 kèm lối phục hồi |

Dẫn xuất từ `IT-NAV-005`. Ranh giới: intent filter của Android và việc hệ
điều hành bàn giao URL. Bảng route và màn 404 đã kiểm ở `HOST-WIDGET`.

## IT-PLAT-005 — Cử chỉ back của hệ thống trong phiên dùng cùng hợp đồng thoát như nút ✕

- **Ưu tiên:** P1
- **Tiền điều kiện:** Một phiên học đang mở.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Dùng cử chỉ back của hệ điều hành, không phải nút ✕ | Phiên đóng như người dùng bỏ, đúng BR-82 |
| 2 | Quay lại màn vào học | Không còn phiên nào đang mở chờ tiếp tục |

Dẫn xuất từ `IT-NAV-010`. Ranh giới: cử chỉ predictive back của Android và
đường nó tới `PopScope`. Việc `PopScope` ghi gì thì `HOST-WIDGET` đã kiểm.

## IT-PLAT-006 — Smoke trước phát hành: cài, mở, tạo, học

- **Ưu tiên:** P0
- **Tiền điều kiện:** Bản release đã cài lên thiết bị sạch.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở app | Khởi động thành công |
| 2 | Tạo một bộ thẻ gốc và một thẻ | Cả hai hiện ra |
| 3 | Bắt đầu học và hoàn tất một thẻ | Phiên chạy hết và có tổng kết |
| 4 | Đóng và mở lại | Tiến độ còn nguyên |

Kịch bản duy nhất trong danh mục cố tình đi qua nhiều lớp. Nó không tồn tại
để bắt lỗi nghiệp vụ — nó tồn tại để bắt một bản dựng **không chạy được**:
thiếu asset, sai flavor, hỏng chữ ký, R8 cắt nhầm, migration không chạy trên
máy thật.
