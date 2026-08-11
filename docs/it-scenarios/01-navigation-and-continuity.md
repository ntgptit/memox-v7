# Kịch bản IT — Khởi động, điều hướng và tiếp tục

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Kiểm tra người dùng đi vào đúng điểm bắt đầu, di chuyển giữa các nhánh và không mất ngữ cảnh bộ thẻ, thẻ hoặc phiên học |
| **Scope** | Khởi động nguội, thanh điều hướng dưới, Back, đường dẫn phân cấp, route không hợp lệ và hành trình bộ thẻ/thẻ/Study xuyên suốt |
| **Source of truth for** | Kịch bản IT về điều hướng và khả năng tiếp tục của chức năng hiện có |
| **Depends on** | `README.md`, `../use-cases.md` (UC-04, UC-05, UC-06), `../business-rules.md` (BR-82, BR-101, BR-103), `../architecture.md` (AD-19), `../wbs.md` (M4.10a, M4.11, M4.12, M99.7), `../wbs-study.md` (M5.7, M5.9, M5.15), `../wireframes/m5-study-modes.md` |
| **Updated by task** | M99.7 (Bottom navigation IA scaffold — bốn destination, AD-19) |
| **Last updated** | 2026-08-11 |

## IT-NAV-001 — Cold start mở đúng danh sách Deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** App đã cài; không có process MemoX đang chạy.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở MemoX từ launcher | App khởi động thành công, không hiện màn đỏ hoặc chi tiết kỹ thuật |
| 2 | Quan sát bottom navigation | Tab Deck đang được chọn |
| 3 | Quan sát nội dung | Hiện danh sách Deck; nếu chưa có dữ liệu thì hiện empty state kèm hành động tạo deck |

## IT-NAV-002 — Chuyển giữa tab Bộ thẻ và Học giữ nguyên bộ thẻ đang mở

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có cây `D-EB > D-BRANCH`; người dùng đang ở trong `D-BRANCH`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm tab Học | Tab Học được chọn; hiện bề mặt Study thật, không còn thông báo tính năng chưa sẵn sàng, không tạo phiên chỉ vì đổi tab |
| 2 | Chạm tab Bộ thẻ | Quay lại đúng `D-BRANCH`, không bị đưa về danh sách bộ thẻ gốc |
| 3 | Quan sát đường dẫn phân cấp và danh sách | Đường dẫn và nội dung tại cấp đang mở vẫn đúng; không có phiên Study mới để Tiếp tục |

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

> **Tách thành** — `IT-NAV-005` (`HOST-WIDGET`) · `IT-PLAT-004` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có thể mở URL/deep link development trỏ tới route không tồn tại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở route không tồn tại | Hiện màn không tìm thấy bằng ngôn ngữ người dùng; không lộ stack trace, SQL hay ID nội bộ |
| 2 | Chạm hành động quay về Deck | Mở danh sách root deck và tab Deck được chọn |

## IT-NAV-006 — Hành trình Deck/Card xuyên suốt và còn dữ liệu sau restart

> **Tách thành** — `IT-NAV-006` (`HOST-FLOW`) · `IT-PLAT-002` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

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

## IT-NAV-008 — Back từ màn vào học quay về đúng bộ thẻ nguồn mà không tạo phiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SCOPE`; người dùng đang mở bộ thẻ con `Lesson A`; chưa có phiên đang dở.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Học từ `Lesson A` | Màn vào học mở cho đúng `Lesson A`, hiện `New 3`; không lấy hai thẻ của `Lesson B` |
| 2 | Bấm Back của hệ thống khi chưa chọn loại phiên | Quay về đúng `Lesson A`, không về bộ thẻ gốc hoặc tab Học |
| 3 | Quan sát đường dẫn và danh sách thẻ | Ngữ cảnh `Lesson A` còn nguyên; không có route Study trùng trong ngăn xếp |
| 4 | Mở Học lần nữa | Không có hành động Tiếp tục hoặc tổng kết vì lần mở trước chưa tạo phiên |

## IT-NAV-009 — Back qua màn chọn chế độ không tạo phiên và giữ đúng ngăn xếp

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; đang ở bộ thẻ chứa các thẻ đến hạn; chưa có phiên đang dở.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Học rồi chọn Ôn tập | Màn chọn chế độ Eight Box mở; chưa có chế độ nào được chọn |
| 2 | Bấm Back của hệ thống | Quay đúng màn vào học của bộ thẻ đó; chưa tạo phiên ôn tập |
| 3 | Bấm Back của hệ thống lần nữa | Quay đúng bộ thẻ nguồn, không về danh sách bộ thẻ gốc hoặc tab Học |
| 4 | Mở Học lại | Không có phiên để Tiếp tục; số `New`/`Due` không đổi chỉ vì đã đi qua màn chọn |

## IT-NAV-010 — Back của hệ thống trong phiên dùng cùng hợp đồng thoát như nút ✕

> **Tách thành** — `IT-NAV-010` (`HOST-WIDGET`) · `IT-PLAT-005` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đã bắt đầu Học mới và hoàn tất ít nhất một lượt; phiên đang `in_progress`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bấm Back của hệ thống | Hiện cùng xác nhận thoát như nút ✕; màn phiên không bị đóng âm thầm |
| 2 | Hủy xác nhận | Vẫn ở đúng chế độ, vòng, thẻ và tiến độ; phiên còn `in_progress` |
| 3 | Bấm Back lần nữa và xác nhận thoát | Phiên dừng do người dùng, hiện trạng thái đã dừng thay vì tổng kết thành tích và có lối về đúng bộ thẻ |
| 4 | Mở lại màn vào học | Không có Tiếp tục cho phiên đã thoát; các lượt ghi thành công trước đó vẫn được giữ |

## IT-NAV-011 — Bốn destination top-level, hai placeholder không tạo phiên và không ghi DB

- **Ưu tiên:** P1
- **Tiền điều kiện:** App đã cài, dữ liệu bất kỳ; không có phiên Study đang dở.
- **Liên kết:** AD-19; UC-06 cho cold start.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở app và quan sát bottom navigation | Đúng bốn destination theo thứ tự Bộ thẻ · Học · Tiến độ · Cài đặt; tab Bộ thẻ đang được chọn |
| 2 | Chạm tab Tiến độ | Placeholder Tiến độ hiện icon, tiêu đề và mô tả "đang được phát triển"; không có số liệu thống kê nào; không tạo phiên Study; không có ghi database nào |
| 3 | Chạm tab Cài đặt | Placeholder Cài đặt hiện tương tự; không có tùy chọn giả nào bật/tắt được; không tạo phiên; không ghi database |
| 4 | Mở deep link `/progress` khi app đã đóng | App mở thẳng placeholder Tiến độ và tab Tiến độ được chọn |
| 5 | Mở deep link `/settings` khi app đã đóng | App mở thẳng placeholder Cài đặt và tab Cài đặt được chọn |
| 6 | Từ một bộ thẻ con đang mở, chạm Tiến độ rồi quay lại Bộ thẻ | Quay đúng bộ thẻ con đang mở — chuyển qua placeholder không làm mất ngăn xếp của branch khác |
| 7 | Chạm lại tab đang được chọn | Branch quay về màn gốc của nó theo đúng hành vi reselect hiện có, không lỗi |
| 8 | Xem bốn nhãn ở màn 320dp và text scale 2.0 | Nhãn Bộ thẻ/Học/Tiến độ/Cài đặt vẫn đọc được, không tràn; nội dung placeholder cuộn được thay vì tràn |

Phần host của kịch bản này chạy ở `test/integration/widgets/navigation_widget_test.dart`
(đếm số dòng của mọi bảng trước và sau khi thăm hai placeholder) và
`test/app/router/app_router_test.dart` (deep link, thứ tự tab, giữ ngăn xếp).
