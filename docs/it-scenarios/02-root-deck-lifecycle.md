# IT scenarios — Vòng đời root deck

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm tra người dùng tạo, huỷ, đổi tên và xoá root deck đúng ràng buộc nghiệp vụ |
| **Scope** | Root deck form, scheduler lúc tạo, validation tên, rename, delete và persistence |
| **Source of truth for** | Scenario IT về vòng đời root deck hiện có |
| **Depends on** | `README.md`, `../business-rules.md` (BR-01…04, BR-11), `../use-cases.md` (UC-02, UC-03) |
| **Updated by task** | Yêu cầu viết IT scenario ngày 2026-08-05 |
| **Last updated** | 2026-08-05 |

## IT-DECK-001 — Tạo root deck dùng Eight Box

> **Tách thành** — `IT-DECK-001` (`HOST-WIDGET`) · `IT-DECK-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở root deck list.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm tạo deck | Form tạo root deck mở, có ô tên và lựa chọn chế độ học |
| 2 | Nhập `Giao tiếp hằng ngày`, chọn Eight Box | Lựa chọn được hiển thị rõ và có giải thích việc chế độ sẽ bị khoá sau khi bắt đầu học |
| 3 | Chạm Tạo/Lưu | Form đóng; deck mới xuất hiện với tên và chế độ Eight Box |
| 4 | Đóng hẳn rồi mở lại app | Deck vẫn còn |

## IT-DECK-002 — Tạo root deck dùng SM-2 và cho phép trùng tên

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đã có một root deck tên `IELTS 2026`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tạo root deck mới, cũng nhập `IELTS 2026` | Form chấp nhận tên trùng |
| 2 | Chọn SM-2 và xác nhận | Root deck thứ hai được tạo với chế độ SM-2 |
| 3 | Quan sát danh sách | Có hai deck cùng tên; app không ghi đè deck cũ |

## IT-DECK-003 — Không tạo deck khi thiếu dữ liệu bắt buộc

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang mở form tạo root deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Để trống tên, chọn Eight Box rồi gửi | Lỗi hiển thị ngay tại ô tên; form vẫn mở; không tạo deck |
| 2 | Nhập chỉ khoảng trắng rồi gửi | Vẫn báo tên không hợp lệ; không tạo deck |
| 3 | Nhập tên hợp lệ nhưng bỏ chọn chế độ học rồi gửi | Lỗi hiển thị tại khu vực chọn chế độ; không tạo deck |
| 4 | Chọn chế độ và gửi lại | Deck được tạo đúng một lần |

## IT-DECK-004 — Giới hạn tên và bảo toàn nội dung khi validation lỗi

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang mở form tạo root deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập tên dài đúng 200 ký tự và chọn scheduler | Có thể lưu deck |
| 2 | Mở form tạo deck khác, thử nhập ký tự thứ 201 | Giá trị được lưu MUST không vượt 200 ký tự: ký tự 201 bị chặn, hoặc form giữ nguyên và báo lỗi inline cho tới khi người dùng sửa |
| 3 | Gửi form không hợp lệ | Tên và scheduler người dùng đã nhập vẫn còn để sửa |

## IT-DECK-005 — Huỷ form có và không có thay đổi

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở root deck list.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở form tạo deck rồi đóng ngay khi chưa nhập gì | Form đóng, không hỏi bỏ thay đổi, không tạo deck |
| 2 | Mở lại, nhập tên rồi chạm Huỷ/đóng | Hiện xác nhận bỏ nội dung đã nhập |
| 3 | Chọn tiếp tục chỉnh sửa | Quay lại form và tên đã nhập còn nguyên |
| 4 | Đóng lần nữa và xác nhận bỏ | Form đóng; không có deck mới |

## IT-DECK-006 — Đổi tên root deck

> **Tách thành** — `IT-DECK-006` (`HOST-WIDGET`) · `IT-DECK-006F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `D-EB`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu của `D-EB`, chọn Đổi tên | Form hiện tên hiện tại |
| 2 | Đổi thành `Giao tiếp công việc` và lưu | Tên mới xuất hiện ngay trong danh sách |
| 3 | Mở deck | App bar và breadcrumb dùng tên mới |
| 4 | Restart app | Tên mới vẫn còn; cấu trúc con và card không bị thay đổi |

## IT-DECK-007 — Huỷ xoá root deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-EB` có ít nhất hai deck con và ba card trong toàn cây.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu `D-EB`, chọn Xoá | Hộp xác nhận nêu đúng tên deck, số deck con và số card sẽ mất |
| 2 | Chọn Huỷ | Hộp thoại đóng |
| 3 | Mở lại `D-EB` và đi tới các card | Deck, descendants và card vẫn còn nguyên |

## IT-DECK-008 — Xác nhận xoá root deck và toàn bộ cây

> **Tách thành** — `IT-DECK-008` (`HOST-WIDGET`) · `IT-DECK-008F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Như IT-DECK-007 và dữ liệu này không dùng chung với scenario khác.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Xoá trên `D-EB` | Hiện xác nhận impact |
| 2 | Xác nhận xoá | Quay về root deck list; `D-EB` biến mất |
| 3 | Restart app | `D-EB` không xuất hiện lại |
| 4 | Dùng search deck tìm tên các descendant cũ | Không tìm thấy descendant nào của cây đã xoá |
