# IT scenarios — Vòng đời card

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm tra người dùng tạo, thêm liên tiếp, sửa, xoá và giữ nội dung card đúng nghiệp vụ |
| **Scope** | Card list, create/edit form, required/optional fields, discard, persistence, delete và dữ liệu học không bị ảnh hưởng khi sửa |
| **Source of truth for** | Scenario IT về vòng đời card hiện có |
| **Depends on** | `README.md`, `../business-rules.md` (BR-07…10, BR-92, BR-95, BR-163), `../use-cases.md` (UC-04) |
| **Updated by task** | Yêu cầu viết IT scenario ngày 2026-08-05 |
| **Last updated** | 2026-08-05 |

## IT-CARD-001 — Empty card deck có hành động thêm card đầu tiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck loại card nhưng chưa có card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở deck | Hiện đúng tên deck, breadcrumb và empty state cho card |
| 2 | Chạm hành động thêm card trong empty state | Mở editor tạo card; focus ở mặt trước |

## IT-CARD-002 — Tạo card với hai mặt bắt buộc

> **Tách thành** — `IT-CARD-002` (`HOST-WIDGET`) · `IT-CARD-002F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở editor tạo card trong `D-LEAF`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập front `abandon`, back `từ bỏ` | Hai giá trị hiển thị đúng |
| 2 | Chạm Lưu | Quay về danh sách; card mới xuất hiện ở đầu |
| 3 | Quan sát card | Hiện đúng front/back và state New; card chưa có due badge vì chưa hoàn tất chuỗi học mới (BR-90, BR-144) |
| 4 | Restart app và mở lại deck | Card vẫn tồn tại |

## IT-CARD-003 — Validation mặt trước và mặt sau

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Để cả hai mặt trống và chạm Lưu | Mỗi ô bắt buộc hiển thị lỗi inline; editor không đóng |
| 2 | Nhập chỉ khoảng trắng ở front, back hợp lệ | Front vẫn bị coi là rỗng; không tạo card |
| 3 | Nhập front hợp lệ, back chỉ khoảng trắng | Back báo lỗi; dữ liệu front còn nguyên |
| 4 | Sửa cả hai hợp lệ và lưu | Tạo đúng một card |

## IT-CARD-004 — Giới hạn độ dài nội dung card

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập front đúng 60 ký tự và back đúng 240 ký tự | Có thể lưu |
| 2 | Mở editor mới và thử vượt 60 ký tự ở front | Giá trị được lưu không vượt 60 ký tự: ký tự dư bị chặn, hoặc form giữ nguyên và báo lỗi inline tại front |
| 3 | Thử vượt 240 ký tự ở back | Giá trị được lưu không vượt 240 ký tự: ký tự dư bị chặn, hoặc form giữ nguyên và báo lỗi inline tại back |

## IT-CARD-005 — Tạo card có thông tin bổ sung

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở phần Thông tin thêm | Hiện các ô ví dụ, gợi ý, phiên âm |
| 2 | Nhập đầy đủ dữ liệu `C-001` và lưu | Card được tạo |
| 3 | Mở card để sửa | Phần thông tin thêm tự mở và hiện đúng dữ liệu đã lưu |
| 4 | Xoá nội dung một trường tùy chọn rồi lưu | Lần mở tiếp theo trường đó rỗng; các trường khác giữ nguyên |

## IT-CARD-006 — Giới hạn 240 ký tự cho từng trường bổ sung

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở editor và đã mở phần Thông tin thêm.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập đúng 240 ký tự vào ví dụ, gợi ý và phiên âm | Form chấp nhận |
| 2 | Thử nhập ký tự thứ 241 vào từng ô | Không trường nào lưu quá 240 ký tự: ký tự dư bị chặn, hoặc form giữ nguyên và báo lỗi inline đúng ô |
| 3 | Sửa về hợp lệ và lưu | Card được lưu, không mất front/back |

## IT-CARD-007 — Lưu và thêm card khác

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập `C-001`, chạm Lưu và thêm | Card được lưu nhưng editor vẫn mở |
| 2 | Quan sát form | Tất cả ô được xoá và focus trở về front |
| 3 | Nhập `C-002`, chạm Lưu | Quay về danh sách |
| 4 | Quan sát danh sách | Có đúng hai card mới, card tạo sau ở trên; không có dòng trùng |

## IT-CARD-008 — Sửa card và giữ vị trí quản lý ổn định

> **Tách thành** — `IT-CARD-008` (`HOST-WIDGET`) · `IT-CARD-008F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có ít nhất ba card; `C-001` không phải card mới nhất.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm `C-001` | Editor sửa được prefill đúng front/back và dữ liệu tùy chọn |
| 2 | Đổi back thành `rời bỏ`, lưu | Quay về danh sách và thấy nội dung mới |
| 3 | Quan sát thứ tự | Card không nhảy lên đầu chỉ vì vừa sửa |
| 4 | Restart app | Nội dung sửa vẫn còn |

## IT-CARD-009 — Sửa nội dung không làm mất tiến độ hoặc cờ

- **Ưu tiên:** P0
- **Tiền điều kiện:** Dùng seed có một card đã học, có trạng thái/đến hạn quan sát được và đang flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi nhận state label, due badge và trạng thái cờ của card | Có baseline |
| 2 | Mở editor, chỉ sửa front/back rồi lưu | Nội dung thay đổi |
| 3 | Quan sát lại card | State label, due badge và cờ giữ nguyên |

## IT-CARD-010 — Huỷ và xác nhận xoá card

> **Tách thành** — `IT-CARD-010` (`HOST-WIDGET`) · `IT-CARD-010F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `C-001`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-001`, chọn Xoá | Hiện hộp xác nhận destructive |
| 2 | Chọn Huỷ | Quay lại editor; card vẫn còn sau khi đóng editor |
| 3 | Mở lại và chọn Xoá, sau đó xác nhận | Quay về danh sách; card biến mất |
| 4 | Restart app | Card không xuất hiện lại |

## IT-CARD-011 — Xoá card cuối đưa deck về chưa định loại

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một deck loại card chỉ còn đúng một card.
- **Liên kết:** UC-04 A2, BR-163. *(Hành vi cũ "loại không tự reset" theo BR-67
  đã bị supersede ở M99.15.)*

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá card cuối và xác nhận | Điều hướng về màn hình deck; card, study state và history của nó biến mất cùng nhau |
| 2 | Chạm hành động tạo | Có cả Tạo card và Tạo deck |
| 3 | Xoá một card khi deck vẫn còn card khác | Ở lại card list; loại vẫn là card |

## IT-CARD-012 — Chuyển card sang deck khác cùng cây giữ nguyên tiến độ

- **Ưu tiên:** P0
- **Tiền điều kiện:** Hai deck cùng root: nguồn loại `card` có đúng một card đã học và có tag, đích `unset`.
- **Liên kết:** UC-04 A5, BR-165, BR-163.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi nhận state label, due badge, cờ và tag của card | Có baseline |
| 2 | Nhấn giữ card, chọn Move, chọn deck đích | Card biến mất khỏi danh sách nguồn |
| 3 | Mở deck đích | Card ở đó, mọi thứ ở bước 1 giữ nguyên |
| 4 | Quan sát hai deck | Nguồn về `unset` (hiện cả hai lựa chọn tạo), đích thành loại `card` |
| 5 | Restart app | Cả bốn thay đổi vẫn còn |

## IT-CARD-013 — Đích không hợp lệ bị từ chối trước khi ghi

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một root khác đã tồn tại, cùng scheduler và cùng generation với root hiện tại.
- **Liên kết:** UC-04 E5, BR-165.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở picker Move từ một selection | Danh sách chỉ có deck cùng root, không có root, không có deck đang chứa deck con, không có chính deck nguồn |
| 2 | Gọi move tới một deck ở root khác | Bị từ chối kèm lý do; **không** tự đổi scheduler dù hai root trùng chế độ |
| 3 | Quan sát dữ liệu sau lần từ chối | `deck_id`, `content_type` hai đầu và `updated_at` đều không đổi |
