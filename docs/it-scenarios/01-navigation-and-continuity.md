# IT scenarios — Khởi động, navigation và continuity

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm tra người dùng đi vào đúng điểm bắt đầu, di chuyển giữa các nhánh và không mất ngữ cảnh Deck/Card |
| **Scope** | Cold start, bottom navigation, back, breadcrumb, route không hợp lệ, hành trình Deck/Card xuyên suốt |
| **Source of truth for** | Scenario IT về navigation và continuity của chức năng hiện có |
| **Depends on** | `README.md`, `../use-cases.md` (UC-04, UC-06), `../wbs.md` (M4.10a, M4.11, M4.12) |
| **Updated by task** | Yêu cầu viết IT scenario ngày 2026-08-05 |
| **Last updated** | 2026-08-05 |

## IT-NAV-001 — Cold start mở đúng danh sách Deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** App đã cài; không có process MemoX đang chạy.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở MemoX từ launcher | App khởi động thành công, không hiện màn đỏ hoặc chi tiết kỹ thuật |
| 2 | Quan sát bottom navigation | Tab Deck đang được chọn |
| 3 | Quan sát nội dung | Hiện danh sách Deck; nếu chưa có dữ liệu thì hiện empty state kèm hành động tạo deck |

## IT-NAV-002 — Chuyển tab và quay lại giữ nguyên deck đang mở

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có cây `D-EB > D-BRANCH`; người dùng đang ở trong `D-BRANCH`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm tab Review | Tab Review được chọn; màn hình thông báo tính năng Review chưa sẵn sàng, không giả vờ bắt đầu phiên học |
| 2 | Chạm tab Deck | Quay lại đúng `D-BRANCH`, không bị đưa về root deck list |
| 3 | Quan sát breadcrumb và danh sách | Breadcrumb và nội dung tại cấp đang mở vẫn đúng |

## IT-NAV-003 — Back đi lên đúng một cấp trong cây

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có cây ba cấp `D-EB > D-BRANCH > D-LEAF`; đang mở `D-LEAF`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bấm Back của hệ thống | Quay về `D-BRANCH`, không nhảy thẳng về root list |
| 2 | Bấm Back lần nữa | Quay về `D-EB` |
| 3 | Bấm Back lần nữa | Quay về danh sách root deck |

## IT-NAV-004 — Breadcrumb quay về ancestor đã chọn

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có cây ba cấp `D-EB > D-BRANCH > D-LEAF`; đang mở `D-LEAF`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát breadcrumb | Hiện đủ đường đi từ Root tới `D-LEAF`, đúng thứ tự |
| 2 | Chạm `D-EB` trên breadcrumb | Mở nội dung của `D-EB` |
| 3 | Mở lại `D-LEAF`, chạm Root | Quay về danh sách root deck |

## IT-NAV-005 — Route không hợp lệ có lối phục hồi an toàn

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có thể mở URL/deep link development trỏ tới route không tồn tại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở route không tồn tại | Hiện màn không tìm thấy bằng ngôn ngữ người dùng; không lộ stack trace, SQL hay ID nội bộ |
| 2 | Chạm hành động quay về Deck | Mở danh sách root deck và tab Deck được chọn |

## IT-NAV-006 — Hành trình Deck/Card xuyên suốt và còn dữ liệu sau restart

- **Ưu tiên:** P0
- **Tiền điều kiện:** App ở trạng thái trống; có thể đóng hẳn và mở lại app.
- **Liên kết:** UC-02, UC-03, UC-04, UC-08; luồng E2E bắt buộc của M4.12.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tạo root `D-EB` và chọn Eight Box | Root deck xuất hiện trong danh sách |
| 2 | Mở `D-EB`, tạo `D-BRANCH`, rồi mở `D-BRANCH` | Cây hiển thị đúng quan hệ cha-con |
| 3 | Trong `D-BRANCH`, tạo `D-LEAF`; trong `D-LEAF`, chọn tạo card | Mở editor card và deck leaf được định hướng thành deck chứa card khi card được lưu thành công |
| 4 | Tạo `C-001`, sau đó mở card và đổi nghĩa thành `rời bỏ` | Danh sách hiện nội dung đã sửa |
| 5 | Quay về root list, đóng hẳn app rồi mở lại | `D-EB` vẫn tồn tại |
| 6 | Đi lại tới `D-LEAF` | `C-001` vẫn tồn tại với nghĩa `rời bỏ` |
| 7 | Xoá `C-001` và xác nhận | Card biến mất; deck card trở thành empty state |
| 8 | Xoá lần lượt nhánh vừa tạo và xác nhận | Các deck bị xoá không còn xuất hiện; app vẫn hoạt động bình thường |

## IT-NAV-007 — Hành trình quản lý nội dung chạy khi offline

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `D-EB > D-LEAF`; app đang mở; thiết bị có thể bật chế độ máy bay.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bật chế độ máy bay | App không chặn thao tác quản lý nội dung và không yêu cầu đăng nhập |
| 2 | Điều hướng tới `D-EB` và tạo một sub-deck mới | Deck được tạo và xuất hiện ngay trong `D-EB` |
| 3 | Tạo, sửa rồi gắn cờ một card trong `D-LEAF` | Mọi thay đổi được phản ánh trên UI |
| 4 | Đóng hẳn rồi mở lại app khi vẫn offline | Deck và card vừa thay đổi vẫn còn |
| 5 | Xoá card vừa tạo | Card bị xoá thành công khi không có mạng |
