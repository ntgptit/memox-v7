# IT scenarios — Cây deck, loại nội dung và di chuyển

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm tra cây deck giữ đúng loại nội dung, giới hạn độ sâu và quy tắc di chuyển qua thao tác người dùng |
| **Scope** | Tạo sub-deck/card đầu tiên, khoá loại nội dung, reset loại khi rỗng, move subtree và depth limit |
| **Source of truth for** | Scenario IT về cấu trúc cây deck và content type |
| **Depends on** | `README.md`, `../business-rules.md` (BR-55…74), `../use-cases.md` (UC-08, UC-09) |
| **Updated by task** | Yêu cầu viết IT scenario ngày 2026-08-05 |
| **Last updated** | 2026-08-05 |

## IT-TREE-001 — Root deck chỉ cho tạo deck con

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có root `D-EB`, chưa có child.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `D-EB`, chạm hành động tạo | Chỉ có luồng tạo deck con; không có lựa chọn tạo card trực tiếp |
| 2 | Tạo deck `Vocabulary` | Deck con xuất hiện bên trong `D-EB`; form không yêu cầu chọn scheduler riêng |

## IT-TREE-002 — Deck con chưa định loại cho phép chọn card hoặc deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-LEAF` vừa được tạo và chưa có nội dung.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `D-LEAF`, chạm Tạo | Hiện hai lựa chọn: tạo card và tạo deck |
| 2 | Đóng sheet mà chưa chọn/lưu | Không tạo nội dung; khi mở lại vẫn còn đủ hai lựa chọn |

## IT-TREE-003 — Card đầu tiên cố định deck thành loại card

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck con `D-LEAF` đang rỗng và chưa định loại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Tạo, chọn Card | Mở editor card |
| 2 | Nhập `C-001` và lưu | Mở/hiện danh sách card của `D-LEAF`, có `C-001` |
| 3 | Quan sát các hành động tạo | Chỉ còn tạo card; không có đường tạo deck con trong `D-LEAF` |
| 4 | Rời màn hình rồi mở lại `D-LEAF` | Tự đi vào danh sách card, không hiện danh sách sub-deck rỗng |

## IT-TREE-004 — Deck con đầu tiên cố định deck thành loại deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck con `Grammar` đang rỗng và chưa định loại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Tạo, chọn Deck | Mở form tạo sub-deck |
| 2 | Tạo child `Tenses` | `Tenses` xuất hiện trong `Grammar` |
| 3 | Chạm Tạo lần nữa | Chỉ có luồng tạo deck; không còn lựa chọn tạo card |

## IT-TREE-005 — Validation thất bại không làm deck bị khoá loại

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck `Unclassified` chưa định loại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn tạo Card, để trống mặt trước và gửi | Hiện lỗi inline; không tạo card |
| 2 | Đóng editor, mở lại hành động Tạo của `Unclassified` | Vẫn có cả Tạo card và Tạo deck |
| 3 | Chọn tạo Deck, để tên trống và gửi | Hiện lỗi inline; không tạo deck |
| 4 | Đóng form và mở lại hành động Tạo | Vẫn có đủ hai lựa chọn |

## IT-TREE-006 — Xoá child cuối không tự đổi loại deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** Deck `Grammar` loại deck chỉ có một child `Tenses`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá `Tenses` và xác nhận | `Grammar` trở thành empty state |
| 2 | Chạm Tạo | Chỉ được tạo deck; app không tự cho tạo card |

## IT-TREE-007 — Reset loại nội dung của deck rỗng

- **Ưu tiên:** P0
- **Tiền điều kiện:** Deck con `Grammar` đang rỗng nhưng loại hiện tại là deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu của chính `Grammar` | Có hành động đặt lại loại nội dung |
| 2 | Chọn đặt lại | Hiện hộp xác nhận; chưa thay đổi gì trước khi xác nhận |
| 3 | Huỷ | Deck vẫn chỉ cho tạo deck |
| 4 | Thực hiện lại và xác nhận | Deck trở về trạng thái chưa định loại |
| 5 | Chạm Tạo | Có cả Tạo card và Tạo deck |

## IT-TREE-008 — Deck còn nội dung không cho reset loại

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-BRANCH` đang chứa `D-LEAF`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu của `D-BRANCH` | Không có hành động reset loại nội dung khi deck chưa rỗng |
| 2 | Xoá hết child, mở lại menu | Hành động reset mới xuất hiện |

## IT-TREE-009 — Di chuyển sub-deck tới đích hợp lệ trong cùng cây

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-EB` có hai branch `Vocabulary` và `Grammar`; `D-LEAF` nằm trong `Vocabulary`; `Grammar` có thể chứa deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu `D-LEAF`, chọn Di chuyển | Sheet hiển thị các đích và trạng thái có thể/không thể chọn |
| 2 | Chọn `Grammar` | Sheet đóng; `D-LEAF` không còn trong `Vocabulary` |
| 3 | Mở `Grammar` | `D-LEAF` xuất hiện với toàn bộ card cũ còn nguyên |

## IT-TREE-010 — Không cho di chuyển vào chính nó hoặc descendant

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `Vocabulary > Academic words > Level 1`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Di chuyển trên `Vocabulary` | `Vocabulary` và `Academic words`/`Level 1` không xuất hiện như đích có thể chọn |
| 2 | Quan sát sheet | Sheet **ẩn** đích không hợp lệ thay vì liệt kê kèm lý do; khi mọi ứng viên đều bị loại nó nói thẳng `Nowhere to move this` — cycle bất khả thi và người dùng được giải thích |
| 3 | Đóng sheet | Cây giữ nguyên, không có cycle |

## IT-TREE-011 — Không cho di chuyển deck vào deck chứa card

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có source sub-deck và `D-LEAF` đã chứa card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Di chuyển trên source | `D-LEAF` vẫn hiện để người dùng hiểu phạm vi nhưng ở trạng thái không thể chọn, kèm lý do deck chỉ chứa card |
| 2 | Quan sát lý do | Người dùng hiểu đích chỉ chứa card |
| 3 | Đóng sheet | Source vẫn ở vị trí cũ; card trong `D-LEAF` không đổi |

## IT-TREE-012 — Không cho move giữa hai root khác scheduler

- **Ưu tiên:** P0
- **Tiền điều kiện:** Source nằm dưới `D-EB`; target nằm dưới `D-SM2` và có thể chứa deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Di chuyển trên source | Target thuộc `D-SM2` không thể chọn |
| 2 | Quan sát lý do | UI giải thích hai cây không tương thích về chế độ/tiến độ học; không âm thầm chuyển đổi |
| 3 | Đóng sheet và kiểm tra hai cây | Source và target đều giữ nguyên |

## IT-TREE-013 — Chặn tạo hoặc move vượt quá 10 cấp

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có cây hợp lệ đủ 10 cấp, root là cấp 1.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tại deck cấp 10, thử tạo deck con | Không tạo cấp 11; có user-facing copy nói đã đạt giới hạn độ sâu và không chứa SQL/exception/ID kỹ thuật |
| 2 | Tạo card trong deck cấp 10 đang chưa định loại | Card vẫn có thể được tạo vì không làm cây sâu thêm |
| 3 | Với một subtree có chiều cao làm đích vượt cấp 10, thử move subtree vào đích sâu | Đích bị từ chối; subtree vẫn ở vị trí cũ |

## IT-TREE-014 — Reset deck loại card sau khi đã xoá card cuối

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một deck con đã được xác lập là loại card và hiện rỗng sau khi xoá card cuối.
- **Liên kết:** UC-03 A3, BR-67, BR-68.
- **Agent note:** Catalog đánh dấu `KNOWN-GAP`; kết quả phù hợp hiện tại là `KNOWN-GAP-CONFIRMED` cho tới khi có lối quản lý deck từ card list rỗng.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Từ card list rỗng, mở hành động quản lý deck | Có lối vào thao tác đặt lại loại nội dung; người dùng không bị mắc kẹt vĩnh viễn ở loại card |
| 2 | Chọn đặt lại loại nội dung | Hiện xác nhận và giải thích deck phải đang rỗng |
| 3 | Xác nhận | Quay về trạng thái deck chưa định loại |
| 4 | Chạm Tạo | Có cả Tạo card và Tạo deck |
