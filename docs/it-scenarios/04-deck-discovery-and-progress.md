# IT scenarios — Khám phá deck và theo dõi tiến độ

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm tra người dùng tìm, lọc, sắp xếp và đọc trạng thái học của deck trên mọi cấp cây |
| **Scope** | Deck tile, summary, due filter, sort, subtree search, empty/no-result và cập nhật tức thời |
| **Source of truth for** | Scenario IT về danh sách, discovery và progress của deck |
| **Depends on** | `README.md`, `../business-rules.md` (BR-29, BR-56, BR-57, BR-65, BR-142, BR-150), `../use-cases.md` (UC-06) |
| **Updated by task** | BR-150 trên tile: bước 1 của IT-DISC-001 yêu cầu cả hai số New/Due, khớp badge hai chip của Library |
| **Last updated** | 2026-08-11 |

## IT-DISC-001 — Deck tile trình bày đủ thông tin ra quyết định

> **Tách thành** — `IT-DISC-001` (`HOST-WIDGET`) · `IT-DISC-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp, clock được pin tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở root deck list | Tile `Due library` hiện Eight Box, 5 card toàn cây, **số New và số Due là hai con số tách biệt** (BR-150) — 2 card đến hạn — và 2 sub-deck trực tiếp |
| 2 | Quan sát deck có card đến hạn | Trạng thái đến hạn được truyền đạt bằng chữ và biểu tượng, không chỉ bằng màu |
| 3 | Mở một child level | Tile child dùng cùng cách trình bày, số liệu đúng với subtree đó |

## IT-DISC-002 — Không có card đến hạn là trạng thái bình thường

- **Ưu tiên:** P0
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp; mở level `No due group` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát tile `Future only` | Tile cho biết 0 card đến hạn bằng thông điệp trung tính |
| 2 | Quan sát màn hình | Không hiện error state và không yêu cầu retry |

## IT-DISC-003 — Lọc chỉ các deck đang có card đến hạn

> **Tách thành** — `IT-DISC-003` (`HOST-WIDGET`) · `IT-DISC-003F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp; đang ở level `Due library` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn bộ lọc Đến hạn | Chỉ còn `Mixed due`; `No due group` bị loại khỏi kết quả |
| 2 | Mở một deck trong kết quả rồi Back | Quay lại level; bộ lọc vẫn phản ánh đúng dữ liệu hiện tại |
| 3 | Chọn Hiện tất cả | Tất cả deck quay lại |

## IT-DISC-004 — Bộ lọc không có kết quả có lối quay lại

- **Ưu tiên:** P1
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp; đang ở level `No due group` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn bộ lọc Đến hạn | Hiện empty state “không có gì đến hạn”, không phải lỗi |
| 2 | Chạm hành động Hiện tất cả | Danh sách deck được khôi phục |

## IT-DISC-005 — Sắp xếp theo tên và gần đây

> **Tách thành** — `IT-DISC-005` (`HOST-WIDGET`) · `IT-DISC-005F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có ba deck cùng cấp: `beta`, `Alpha`, `gamma`, với thời điểm tạo/cập nhật khác nhau.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn sắp xếp theo tên | Thứ tự là `Alpha`, `beta`, `gamma`, không phân biệt hoa thường |
| 2 | Chọn sắp xếp gần đây | Thứ tự là `gamma`, `Alpha`, `beta`, khớp thứ tự tạo mới nhất trước |
| 3 | Đổi bộ lọc rồi quay về tất cả | Kiểu sắp xếp đang chọn vẫn được áp dụng |

## IT-DISC-006 — Tìm deck trong đúng phạm vi subtree

> **Tách thành** — `IT-DISC-006` (`HOST-WIDGET`) · `IT-DISC-006F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-EB > Vocabulary > Academic words`; `D-SM2` có deck khác cũng chứa chữ `Academic`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở trong `D-EB`, nhập `Academic` vào ô tìm kiếm | Kết quả có `Academic words` trong subtree `D-EB`, kèm đường đi đủ để phân biệt vị trí |
| 2 | Quan sát kết quả | Không lẫn deck cùng tên/từ khoá nằm dưới `D-SM2` |
| 3 | Chạm kết quả | Điều hướng tới đúng deck được chọn |
| 4 | Xoá nội dung tìm kiếm | Quay về danh sách level bình thường |

## IT-DISC-007 — Tìm kiếm không khớp có thông tin phạm vi và lối xoá

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở một level có dữ liệu.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập một chuỗi không khớp deck nào | Hiện trạng thái không có kết quả, nêu phạm vi đang tìm |
| 2 | Chạm xoá tìm kiếm | Danh sách và summary của level trở lại |

## IT-DISC-008 — Summary và danh sách tự cập nhật sau thay đổi nội dung

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `D-LEAF` và có thể quan sát tile/summary của ancestor.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi lại tổng card, New và Due trên ancestor | Có baseline ba số rõ ràng |
| 2 | Tạo một card mới trong `D-LEAF`, rồi Back về ancestor | Tổng và New tăng đúng 1; Due không đổi vì card chưa học; không cần pull-to-refresh/restart |
| 3 | Xoá card vừa tạo, quay lại ancestor | Tổng và New giảm đúng 1 về baseline; Due vẫn không đổi |
| 4 | Khi summary panel đang hiện, chạm ẩn rồi gọi hiện lại | Panel ẩn/hiện theo hành động người dùng; số liệu không đổi sai |
