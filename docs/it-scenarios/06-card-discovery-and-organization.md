# IT scenarios — Tìm kiếm, tổ chức và tiến độ card

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm tra người dùng tìm card, sắp xếp, gắn cờ/tag, lọc và đọc tiến độ từ card list |
| **Scope** | Search front/back, sort, filter pills, flag, tag, state/due badge, progress panel và tải thêm |
| **Source of truth for** | Scenario IT về discovery và organization của card |
| **Depends on** | `README.md`, `../business-rules.md` (BR-89…95, BR-142, BR-151), `../use-cases.md` (UC-04) |
| **Updated by task** | Đồng bộ định nghĩa New/Due sau M5 ngày 2026-08-08 |
| **Last updated** | 2026-08-08 |

## IT-ORG-001 — Tìm card theo mặt trước và mặt sau

> **Tách thành** — `IT-ORG-001` (`HOST-WIDGET`) · `IT-ORG-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-LEAF` có `C-001`, `C-002`, `C-003`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập `abandon` vào ô tìm kiếm | Chỉ hiện `C-001` |
| 2 | Đổi query thành `nhân từ` | Chỉ hiện `C-002`, chứng minh tìm được theo mặt sau |
| 3 | Xoá query | Tất cả card quay lại |

## IT-ORG-002 — Search không có kết quả và phục hồi

- **Ưu tiên:** P1
- **Tiền điều kiện:** Deck có card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập `không-tồn-tại` | Hiện empty state nêu từ khoá không khớp; không hiện hành động “thêm card đầu tiên” |
| 2 | Xoá query | Danh sách, filter và progress panel hoạt động lại với dữ liệu gốc |

## IT-ORG-003 — Sắp xếp card mới nhất và đến hạn trước

- **Ưu tiên:** P1
- **Tiền điều kiện:** Dùng `S-DUE`, các card có thời điểm tạo khác nhau.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn sắp xếp Mới nhất | Thứ tự khớp `created_at` giảm dần của fixture; mỗi card xuất hiện đúng một lần |
| 2 | Chọn Đến hạn trước | Hai card đã học và đang Due (`C-P-BEGIN`, `C-P-REVIEW`) đứng trước card future; `C-P-NEW` không bị gọi là Due |
| 3 | Chọn một filter rồi đổi sort | Filter và sort kết hợp; không làm xuất hiện card ngoài filter |

## IT-ORG-004 — Gắn cờ và bỏ cờ một card

> **Tách thành** — `IT-ORG-004` (`HOST-WIDGET`) · `IT-ORG-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `C-003` chưa flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-003`, chạm biểu tượng cờ | Biểu tượng chuyển sang trạng thái đã đánh dấu |
| 2 | Quay về card list | Row `C-003` có dấu cờ |
| 3 | Restart app, mở lại card | Cờ vẫn còn |
| 4 | Chạm cờ lần nữa | Cờ được bỏ ở editor và card list |

## IT-ORG-005 — Lọc All, Due, New và Flagged với số lượng đúng

- **Ưu tiên:** P0
- **Tiền điều kiện:** Dùng `S-DUE`, trong đó có ít nhất một card flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát bốn filter pill | Hiện chính xác All 4, Due 2, New 1 và Flagged 1 |
| 2 | Chọn Due | Chỉ hiện `C-P-BEGIN` và `C-P-REVIEW`; `C-P-NEW` không xuất hiện |
| 3 | Chọn New | Chỉ hiện card chưa học |
| 4 | Chọn Flagged | Chỉ hiện card đã gắn cờ |
| 5 | Chọn All | Tất cả card trở lại |

## IT-ORG-006 — Filter không có kết quả không bị hiểu là deck rỗng

- **Ưu tiên:** P1
- **Tiền điều kiện:** Deck có card nhưng không card nào flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Flagged | Hiện trạng thái “không có card phù hợp”, không hiện CTA thêm card đầu tiên |
| 2 | Chọn All | Danh sách card trở lại |

## IT-ORG-007 — Thêm và tái sử dụng tag không phân biệt hoa thường

> **Tách thành** — `IT-ORG-007` (`HOST-WIDGET`) · `IT-ORG-007F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có `C-001` và `C-002`, chưa có tag.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-001`, thêm tag `IELTS` | Tag xuất hiện dạng chip trong editor |
| 2 | Quay về list | Row `C-001` hiện chip `IELTS` |
| 3 | Mở `C-002`, thêm tag `ielts` | Card nhận tag tương ứng; hệ thống không tạo hai tag nghiệp vụ khác nhau chỉ vì hoa/thường |
| 4 | Thêm lại `IELTS` trên cùng card | Không xuất hiện chip trùng |

## IT-ORG-008 — Xoá tag khỏi card không xoá nội dung card

- **Ưu tiên:** P1
- **Tiền điều kiện:** `C-001` có tag `IELTS` và `Writing`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-001`, xoá chip `IELTS` | Chip `IELTS` biến mất; `Writing` còn |
| 2 | Quay về list | Row chỉ còn chip `Writing`; front/back và state không đổi |
| 3 | Restart app | Kết quả xoá tag được giữ |

## IT-ORG-009 — Validation tên tag và giới hạn 10 tag

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có một card đang mở ở edit mode.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Thử thêm tag rỗng/chỉ khoảng trắng | Hiện lỗi; không tạo chip |
| 2 | Thử thêm tag dài hơn 50 ký tự | Không tạo tag: ký tự dư bị chặn, hoặc lỗi inline giữ form mở cho tới khi tên còn tối đa 50 ký tự |
| 3 | Thêm lần lượt 10 tag hợp lệ, khác nhau | Hiện đúng 10 chip và counter 10/10 |
| 4 | Thử thêm tag thứ 11 | Bị từ chối với thông báo rõ; 10 tag cũ còn nguyên |

## IT-ORG-010 — Trạng thái, due badge và progress panel nhất quán

> **Tách thành** — `IT-ORG-010` (`HOST-WIDGET`) · `IT-ORG-010F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Dùng `S-PROGRESS` v2; nó dùng chung contract dữ liệu với alias S-DUE.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở card list | Mỗi row hiện đúng một state: New, Beginning, Reviewing hoặc Mastered |
| 2 | Quan sát due badge | `C-P-NEW` không có due badge; hai card Due hiện quá hạn/đến hạn; card future hiện số ngày còn lại đúng fixture |
| 3 | Quan sát progress panel | Tổng 4; mỗi state có 1 card; Mastered là 1/4 và 25% |
| 4 | Gắn/bỏ cờ hoặc sửa text một card | Progress không thay đổi vì các thao tác này không phải review |

## IT-ORG-011 — Breadcrumb và tên deck trên card list cập nhật sau rename

- **Ưu tiên:** P1
- **Tiền điều kiện:** `D-EB > D-BRANCH > D-LEAF` có card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `D-LEAF` | App bar hiện `D-LEAF`; breadcrumb hiện đủ ancestors |
| 2 | Quay lại, đổi tên `D-BRANCH`, rồi mở lại `D-LEAF` | Breadcrumb dùng tên ancestor mới |
| 3 | Đổi tên chính `D-LEAF` và mở lại | App bar và breadcrumb dùng tên leaf mới |

## IT-ORG-012 — Danh sách lớn tải theo cửa sổ và không mất card

- **Ưu tiên:** P2
- **Tiền điều kiện:** Dùng `S-LARGE` có 65 card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở deck | Ban đầu hiển thị tối đa 50 card và dòng “đang hiện 50/65” |
| 2 | Cuộn cuối danh sách | Có hành động tải thêm, không báo đã hiển thị tất cả |
| 3 | Chạm tải thêm | Danh sách tăng và cuối cùng hiện đủ 65/65, không trùng hoặc mất row |
| 4 | Mở một card rồi Back | Card list vẫn sử dụng được và dữ liệu đã tải không bị sai |
