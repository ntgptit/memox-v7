# Use cases — memox (MVP)

_Status: draft · Last updated: 2026-07-28_

Chỉ đặc tả must-have M1–M6. Should-have và nice-to-have viết khi tới lượt —
đặc tả trước những thứ có thể bị cắt là lãng phí.

Luồng viết bằng ngôn ngữ người dùng, không nói theo màn hình hay widget. Màn
hình sẽ đổi; luồng thì không.

Mục [suy luận] là chỗ tôi tự quyết vì không có đặc tả.

---

## UC-01 · Khởi động lần đầu và nhận deck quà tặng

**Actor:** Người dùng mới cài app
**Trigger:** Mở app lần đầu sau khi cài
**Preconditions:** Database chưa tồn tại hoặc `applied_seeds` rỗng

**Main flow:**
1. Người dùng mở app.
2. Hệ thống khởi tạo database.
3. Hệ thống đọc danh sách deck quà đóng gói trong app.
4. Với mỗi deck quà chưa từng được chèn (BR-21), hệ thống chèn deck, toàn bộ card
   của nó, và bản ghi `applied_seeds` — trong cùng một transaction (BR-23).
5. Người dùng thấy danh sách deck, mỗi deck kèm số card đến hạn. Deck quà có toàn
   card mới nên đến hạn hết (BR-08).
6. Người dùng có thể vào ôn ngay mà không phải tạo gì.

**Alternative flows:**
- **A1 — Không phải lần đầu, không có seed mới:** bước 4 không chèn gì, vào thẳng
  bước 5. Đây là đường chạy thường xuyên nhất và phải nhanh.
- **A2 — Cập nhật app có thêm deck quà mới:** chỉ `seed_id` chưa có trong
  `applied_seeds` được chèn. Deck quà cũ mà người dùng đã xoá **không** quay lại
  (BR-21).

**Error flows:**
- **E1 — Không mở được database:** hiện màn hình lỗi rõ ràng với hành động thử
  lại. Không được là màn hình trắng — trắng thì không phân biệt được với treo.
- **E2 — Chèn seed thất bại giữa chừng (hết bộ nhớ, file asset hỏng):**
  transaction rollback. App vẫn dùng được với 0 deck; lần mở sau thử lại. Không
  chặn người dùng vào app chỉ vì quà không chèn được.
- **E3 — File seed sai định dạng:** log lỗi, bỏ qua seed đó, các seed khác vẫn
  chèn. Một deck quà hỏng không nên làm mất cả bộ.

**Postconditions:**
- Mỗi `seed_id` trong app có đúng một dòng trong `applied_seeds`.
- Không có deck trùng lặp.
- Nếu E2 xảy ra, không có deck nửa vời và không có `applied_seeds` tương ứng.

**Business rules:** BR-20, BR-21, BR-22, BR-23
**UI states:** initial · loading · loaded · ~~empty~~ (không xảy ra ở lần đầu vì
có quà; xảy ra khi người dùng đã xoá hết — dùng chung với UC-04) · error

---

## UC-02 · Tạo deck

**Actor:** Người dùng
**Trigger:** Bấm tạo deck ở danh sách deck
**Preconditions:** Không có

**Main flow:**
1. Người dùng nhập tên deck.
2. Người dùng chọn scheduler, mặc định là 8-box (BR-05). [suy luận] Hiện lựa
   chọn ngay khi tạo, kèm mô tả ngắn — giấu vào phần sửa sau sẽ khiến gần như
   không ai đổi.
3. Người dùng xác nhận.
4. Hệ thống validate tên (BR-01).
5. Hệ thống tạo deck với ID sinh phía client (AD-03).
6. Deck xuất hiện trong danh sách với 0 card.

**Alternative flows:**
- **A1 — Người dùng huỷ:** không tạo gì, quay lại danh sách. Nếu đã nhập nội
  dung, hỏi xác nhận trước khi bỏ.

**Error flows:**
- **E1 — Tên rỗng:** hiện lỗi inline ngay dưới ô nhập, không phải snackbar.
  Không tạo. Nội dung đã nhập được giữ nguyên.
- **E2 — Tên quá 200 ký tự:** lỗi inline; chặn nhập thêm thay vì cắt âm thầm.
- **E3 — Ghi database thất bại:** hiện lỗi, giữ nguyên form và dữ liệu đã nhập.
  Người dùng không phải gõ lại.

**Postconditions:** Deck tồn tại và còn sau khi khởi động lại app.

**Business rules:** BR-01, BR-02, BR-05
**UI states:** initial · submitting · error (validation và lỗi ghi là hai loại
khác nhau, hiện khác nhau)

---

## UC-03 · Sửa và xoá deck

**Actor:** Người dùng
**Trigger:** Chọn sửa hoặc xoá trên một deck
**Preconditions:** Deck tồn tại

**Main flow (sửa):**
1. Người dùng đổi tên và/hoặc scheduler.
2. Hệ thống validate (BR-01).
3. Nếu scheduler đổi, hệ thống hỏi xác nhận có nói rõ tiến độ sẽ đặt lại (BR-13).
4. Hệ thống lưu; nếu scheduler đổi thì giữ `due_at` và reset tham số riêng.

**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số card sẽ mất (BR-04).
2. Người dùng xác nhận.
3. Hệ thống xoá deck; card bị xoá cascade (BR-03).
4. Deck biến mất khỏi danh sách.

**Alternative flows:**
- **A1 — Huỷ xác nhận xoá:** không xảy ra gì.
- **A2 — Xoá deck quà tặng:** xoá bình thường (BR-22) và **không hồi sinh** ở
  bản cập nhật sau (BR-21).
- **A3 — Đổi scheduler trên deck chưa ôn card nào:** không cần cảnh báo, vì không
  có tiến độ để mất. [suy luận] Cảnh báo thừa dạy người dùng bỏ qua cảnh báo.

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách với
  thông báo nhẹ nhàng. Không hiện lỗi kỹ thuật.
- **E2 — Xoá thất bại:** hiện lỗi; deck vẫn còn nguyên vẹn, không nửa vời.

**Postconditions:**
- Sau xoá: deck và toàn bộ card của nó không còn; không có card mồ côi.
- Sau đổi scheduler: `due_at` giữ nguyên, tham số riêng về mặc định.

**Business rules:** BR-01, BR-03, BR-04, BR-05, BR-13, BR-21, BR-22
**UI states:** loaded · submitting · error

---

## UC-04 · Quản lý card trong deck

**Actor:** Người dùng
**Trigger:** Mở một deck
**Preconditions:** Deck tồn tại

**Main flow:**
1. Người dùng thấy danh sách card của deck.
2. Người dùng thêm card: nhập mặt trước và mặt sau.
3. Hệ thống validate (BR-06, BR-07).
4. Hệ thống tạo card với `due_at = NULL` → đến hạn ngay (BR-08).
5. Card xuất hiện trong danh sách; số card đến hạn của deck tăng.

**Alternative flows:**
- **A1 — Sửa card:** nội dung đổi, tiến độ ôn tập **không** đổi (BR-09).
- **A2 — Xoá card:** hỏi xác nhận, xoá kèm lịch sử ôn của card đó.
- **A3 — Deck rỗng:** hiện empty state với hành động "Thêm card" ngay trong đó.
- **A4 — Thêm liên tiếp nhiều card:** sau khi lưu, giữ form mở và xoá trống các ô
  để nhập tiếp. [suy luận] Người dùng nhập từ vựng theo loạt; bắt bấm "thêm" lại
  cho từng từ là ma sát không cần thiết.

**Error flows:**
- **E1 — Mặt trước hoặc mặt sau rỗng:** lỗi inline ở đúng ô đó, không tạo.
- **E2 — Vượt 2000 ký tự:** lỗi inline, chặn nhập thêm.
- **E3 — Ghi thất bại:** hiện lỗi, giữ nội dung đã nhập.

**Postconditions:** Card tồn tại trong deck, đến hạn ngay, còn sau khi khởi động
lại.

**Business rules:** BR-06, BR-07, BR-08, BR-09
**UI states:** loading · loaded · empty · submitting · error

---

## UC-05 · Ôn tập một deck — luồng chính

**Actor:** Người dùng
**Trigger:** Bấm ôn tập trên một deck có card đến hạn
**Preconditions:** Deck tồn tại và có ít nhất một card thoả BR-14

Đây là luồng chạy hằng ngày và là vertical slice đầu tiên nên xây — nó chạm từ
Drift query có index, qua strategy thuần khiết ở domain, đến state matrix đầy đủ
ở presentation.

**Main flow:**
1. Hệ thống lấy card đến hạn: `due_at IS NULL OR due_at <= now` (BR-14), sắp xếp
   card mới trước rồi theo `due_at` tăng dần (BR-15), tối đa 50 (BR-16).
2. Hệ thống hiện mặt trước của card đầu tiên và tiến độ phiên (đã ôn / tổng).
3. Người dùng nghĩ đáp án rồi bấm lật.
4. Hệ thống hiện mặt sau kèm 4 lựa chọn: Again / Hard / Good / Easy.
5. Người dùng chọn một mức.
6. Hệ thống tính trạng thái mới bằng scheduler của deck (BR-10, BR-11) và **ghi
   ngay** (BR-17).
7. Hệ thống chuyển sang card tiếp theo; card vừa đánh giá không quay lại trong
   phiên (BR-18).
8. Hết card, hệ thống hiện tổng kết phiên: số card đã ôn, phân bố các mức đánh
   giá, số card còn quá hạn chưa tới lượt nếu có.

**Alternative flows:**
- **A1 — Thoát giữa phiên:** giữ toàn bộ đánh giá đã ghi (BR-17). Mở lại tiếp tục
  từ card chưa ôn.
- **A2 — Còn card quá hạn ngoài giới hạn 50:** ở tổng kết, nói rõ còn bao nhiêu và
  cho phép bắt đầu phiên tiếp theo ngay.
- **A3 — Card duy nhất trong phiên:** vẫn hiện tiến độ và tổng kết bình thường,
  không đặc cách.
- **A4 — Xoá deck đang ôn dở:** kết thúc phiên, quay về danh sách.

**Error flows:**
- **E1 — Không còn card nào đến hạn lúc bắt đầu:** empty state tích cực (BR-19),
  kèm thời điểm card gần nhất đến hạn. **Không** phải màn hình lỗi.
- **E2 — Ghi đánh giá thất bại:** hiện lỗi ngay, **không** chuyển sang card tiếp
  theo. Người dùng thử lại mức đánh giá đó. Chuyển tiếp khi chưa ghi được là âm
  thầm mất tiến độ, thứ người dùng chỉ phát hiện sau nhiều ngày.
- **E3 — Đọc card thất bại:** màn hình lỗi có nút thử lại.

**Postconditions:**
- Mỗi card đã đánh giá có `due_at` và tham số scheduler mới, đã lưu bền vững.
- Card đánh giá `Again` có `box = 1` và đến hạn sau 1 ngày.
- Số card đến hạn của deck ở danh sách phản ánh đúng trạng thái mới.

**Business rules:** BR-08, BR-10, BR-11, BR-12, BR-14, BR-15, BR-16, BR-17,
BR-18, BR-19
**UI states:** loading · loaded (đang hiện mặt trước) · loaded (đã lật) ·
submitting (đang ghi đánh giá) · empty (không có gì đến hạn) · error

Chú ý `submitting` tách khỏi `loaded`: đúng nguyên tắc "dữ liệu và trạng thái tác
vụ là hai chuyện" — trong lúc ghi đánh giá, nội dung card vẫn hiện, chỉ 4 nút bị
khoá để tránh bấm đúp.

---

## UC-06 · Xem danh sách deck với tiến độ

**Actor:** Người dùng
**Trigger:** Mở app, hoặc quay về từ màn khác
**Preconditions:** Không có

**Main flow:**
1. Hệ thống lấy toàn bộ deck kèm số card đến hạn của từng deck (một query gộp,
   không phải N+1 query).
2. Người dùng thấy mỗi deck với tên, tổng số card, số card đến hạn.
3. Deck có card đến hạn được làm nổi bật — bằng cả biểu tượng lẫn chữ, không chỉ
   bằng màu.

**Alternative flows:**
- **A1 — Chưa có deck nào:** empty state với hành động tạo deck. Chỉ xảy ra khi
  người dùng đã xoá hết, vì lần đầu luôn có quà (UC-01).
- **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift
  (AD-01), không cần refresh thủ công.

**Error flows:**
- **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại.

**Postconditions:** Không đổi gì — đây là use case chỉ đọc.

**Business rules:** BR-14 (định nghĩa "đến hạn" phải khớp hệt UC-05, nếu không
con số ở danh sách sẽ lệch với số card thực sự ôn được)
**UI states:** loading · loaded · empty · error

---

## Điều đã cố ý không đặc tả

| Thứ | Vì sao |
|---|---|
| Tìm kiếm card (S1) | Should-have, chưa tới lượt |
| Thống kê / streak (S2) | Should-have |
| Đảo chiều card (S3) | Should-have |
| Import/export (N1) | Nice-to-have; deck quà đã giải quyết vấn đề app trống |
| Nhắc nhở hằng ngày (N2) | Nice-to-have, cần quyền notification |
| SM-2 | Đã chốt làm sau 8-box; đặc tả khi làm |
| Đăng nhập, đồng bộ | Ngoài MVP (AD-03) |
