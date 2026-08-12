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

> **Tách thành** — `IT-TREE-001` (`HOST-WIDGET`) · `IT-TREE-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

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

> **Tách thành** — `IT-TREE-003` (`HOST-WIDGET`) · `IT-TREE-003F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck con `D-LEAF` đang rỗng và chưa định loại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Tạo, chọn Card | Mở editor card |
| 2 | Nhập `C-001` và lưu | Mở/hiện danh sách card của `D-LEAF`, có `C-001` |
| 3 | Quan sát các hành động tạo | Chỉ còn tạo card; không có đường tạo deck con trong `D-LEAF` |
| 4 | Rời màn hình rồi mở lại `D-LEAF` | Tự đi vào danh sách card, không hiện danh sách sub-deck rỗng |

## IT-TREE-004 — Deck con đầu tiên cố định deck thành loại deck

> **Tách thành** — `IT-TREE-004` (`HOST-WIDGET`) · `IT-TREE-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

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

## IT-TREE-006 — Xoá child cuối đưa sub-deck về chưa định loại

- **Ưu tiên:** P0
- **Tiền điều kiện:** Deck con `Grammar` loại deck chỉ có một child `Tenses`.
- **Liên kết:** UC-08 A3, BR-163. *(Hành vi cũ "loại giữ nguyên" theo BR-67 đã bị
  supersede ở M99.15.)*

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá `Tenses` và xác nhận | `Grammar` trở thành empty state và `content_type` về `unset` trong cùng transaction |
| 2 | Chạm Tạo | Có cả Tạo card và Tạo deck — deck đã mở khoá loại |
| 3 | Lặp lại với một root rỗng | Root vẫn chỉ cho tạo deck: root bất biến `deck` (BR-58) |

## IT-TREE-007 — Di chuyển child cuối đi cũng mở khoá loại của deck nguồn

> **Kịch bản đổi nội dung ở M99.15.** ID giữ nguyên; hành vi cũ là reset thủ
> công theo BR-68 và đã bị BR-163 thay thế. Di chuyển là con đường thứ hai làm
> deck mất phần tử con cuối, nên nó thế chỗ ở đây.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-BRANCH` chỉ có `D-LEAF`; tồn tại một deck đích khác đang chưa định loại.
- **Liên kết:** UC-09, BR-163.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Di chuyển `D-LEAF` sang deck đích | `D-LEAF` xuất hiện ở đích cùng toàn bộ card |
| 2 | Mở deck đích | Đích đã thành loại deck: chỉ cho tạo deck con |
| 3 | Mở `D-BRANCH` | Đã trở về chưa định loại: có cả Tạo card và Tạo deck |
| 4 | Lặp lại khi `D-BRANCH` còn một child khác | `D-BRANCH` giữ nguyên loại deck |

## IT-TREE-008 — Deck còn nội dung giữ nguyên loại

> **Kịch bản đổi nội dung ở M99.15**, cùng lý do IT-TREE-007: không còn hành
> động reset để chặn, nhưng ràng buộc "còn nội dung thì giữ loại" vẫn phải đúng
> và nay là hệ quả của BR-163 chứ không phải của một nút bị ẩn.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-BRANCH` đang chứa `D-LEAF` và một deck con thứ hai.
- **Liên kết:** UC-08 A3, BR-163, invariant Q29.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá `D-LEAF`, xác nhận | `D-BRANCH` vẫn là loại deck; nút Tạo vẫn chỉ cho tạo deck con |
| 2 | Xoá nốt deck con còn lại | Lúc này `D-BRANCH` mới trở về chưa định loại |
| 3 | Chạm Tạo | Có cả Tạo card và Tạo deck |

## IT-TREE-009 — Di chuyển sub-deck tới đích hợp lệ trong cùng cây

> **Tách thành** — `IT-TREE-009` (`HOST-WIDGET`) · `IT-TREE-009F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

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

## IT-TREE-014 — Xoá card cuối mở khoá lại loại nội dung của deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một deck con loại card chỉ còn đúng một card.
- **Liên kết:** UC-04 A2, BR-163. *(Trước M99.15 kịch bản này mô tả reset thủ
  công theo BR-67/BR-68 và mang `KNOWN-GAP`; gap đã đóng bằng chuyển đổi tự
  động.)*

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá card cuối và xác nhận | Người dùng về màn hình deck, không mắc kẹt ở card list rỗng |
| 2 | Quan sát deck | Deck ở trạng thái chưa định loại; không cần thao tác quản trị nào |
| 3 | Chạm Tạo | Có cả Tạo card và Tạo deck |
