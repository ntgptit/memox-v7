# Business rules — memox

_Status: draft · Last updated: 2026-07-28_

Rules đúng bất kể UI. Đánh số để use case, code comment và test cùng trích dẫn
một định danh — khi rule đổi, đó là cách tìm ra mọi chỗ phụ thuộc nó.

Mục [suy luận] là chỗ tôi tự quyết vì không có đặc tả; nếu sai thì sửa ở đây
trước, code theo sau.

---

## Deck

| ID | Rule |
|---|---|
| BR-01 | Deck phải có tên không rỗng sau khi trim, tối đa 200 ký tự. |
| BR-02 | Tên deck **không** bắt buộc là duy nhất. [suy luận] Người dùng có thể muốn hai deck "Unit 5" cho hai giáo trình; ép duy nhất là hạn chế tuỳ tiện. |
| BR-03 | Xoá deck xoá toàn bộ card của nó (cascade), kể cả lịch sử ôn tập. |
| BR-04 | Xoá deck là hành động phá huỷ và cần xác nhận, kèm số card sẽ mất. |
| BR-05 | Mỗi deck có đúng một scheduler: `eightBox` (mặc định) hoặc `sm2`. |

## Card

| ID | Rule |
|---|---|
| BR-06 | Card phải có mặt trước và mặt sau, đều không rỗng sau khi trim. |
| BR-07 | Mặt trước và mặt sau tối đa 2000 ký tự. [suy luận] Đủ cho câu ví dụ dài, đủ chặt để không phá layout. |
| BR-08 | Card mới có `due_at = NULL`, nghĩa là **đến hạn ngay**. Card mới luôn được ôn trước card đã có lịch. |
| BR-09 | Sửa nội dung card **không** làm mất tiến độ ôn tập. Người dùng sửa lỗi chính tả không đáng bị reset về hộp 1. |

## Thuật toán 8-box

| ID | Rule |
|---|---|
| BR-10 | Ánh xạ 4 mức đánh giá sang chuyển hộp. |
| BR-11 | Khoảng cách theo hộp. |
| BR-12 | Card chưa từng ôn coi như đang ở hộp 1. |

### BR-10 · Ánh xạ đánh giá → hộp

8-box truyền thống chỉ có đúng/sai. Với 4 mức, ánh xạ sau là **quyết định thiết
kế**, không phải chuẩn có sẵn:

| Đánh giá | Hộp mới | Lý do |
|---|---|---|
| Again | `1` | Quên là quên — reset hoàn toàn, không giảm dần |
| Hard | `max(1, box - 1)` | Nhớ được nhưng chật vật → lùi một bậc, không reset |
| Good | `min(8, box + 1)` | Bước tiến bình thường |
| Easy | `min(8, box + 2)` | Nhảy hai bậc để nội dung đã thuộc không chiếm thời gian |

`Again` reset thẳng về 1 thay vì lùi một bậc là điều đáng cân nhắc: nó khắc
nghiệt, nhưng đó là toàn bộ tinh thần của Leitner — quên nghĩa là chưa vào trí
nhớ dài hạn, và lùi một bậc sẽ khiến card khó cứ trồi sụt quanh hộp cao mà không
bao giờ thực sự được học lại.

### BR-11 · Khoảng cách theo hộp

| Hộp | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Ngày | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

`due_at = now + interval(hộp mới)`.

Hộp 8 (128 ngày ≈ 4 tháng) là hộp cuối. Card ở hộp 8 và trả lời `Good`/`Easy`
vẫn ở hộp 8 và được xếp lịch lại sau 128 ngày — **không** có trạng thái "tốt
nghiệp" khiến card biến mất, vì trí nhớ vẫn phai và người dùng vẫn nên gặp lại.

"Đã thuộc" (`box == 8`) là giá trị **suy ra để hiển thị**, không phải trạng thái
lưu trong DB. Lưu nó là tạo ra thứ có thể mâu thuẫn với `box`.

### BR-12 · Card mới

Card có `box = NULL` được xử lý như `box = 1`. Không backfill khi tạo card — để
NULL phân biệt được "chưa từng ôn" với "đã ôn và rơi về hộp 1", và sự khác biệt
đó có ý nghĩa với thống kê.

## Đổi scheduler

| ID | Rule |
|---|---|
| BR-13 | Đổi scheduler của deck: **giữ `due_at`**, reset tham số riêng của thuật toán về mặc định. Cần xác nhận, và câu xác nhận phải nói rõ tiến độ sẽ được đặt lại. |

Ánh xạ hộp ↔ ease factor là bịa đặt — không có tương ứng có cơ sở giữa "hộp 5"
và một `easeFactor` cụ thể. Giữ `due_at` để người dùng không bị dội một đống card
đến hạn ngay sau khi đổi, nhưng không giả vờ chuyển đổi được thứ không chuyển đổi
được.

## Phiên ôn tập

| ID | Rule |
|---|---|
| BR-14 | Một phiên chỉ lấy card có `due_at IS NULL OR due_at <= now`. |
| BR-15 | Thứ tự: card mới (`due_at IS NULL`) trước, sau đó theo `due_at` tăng dần — quá hạn lâu nhất trước. |
| BR-16 | Giới hạn 50 card mỗi phiên. [suy luận] Chống trường hợp người dùng bỏ 2 tuần rồi mở app thấy 400 card, thấy nản và bỏ hẳn. |
| BR-17 | Đánh giá được ghi ngay khi người dùng bấm, không chờ hết phiên. Thoát giữa chừng vẫn giữ những gì đã ôn. |
| BR-18 | Card đánh giá `Again` **không** quay lại trong cùng phiên. [suy luận] Ôn lại ngay chỉ luyện trí nhớ ngắn hạn; đúng tinh thần Leitner là gặp lại vào ngày mai. |
| BR-19 | Không có card nào đến hạn là trạng thái **bình thường và tích cực**, không phải lỗi. Đây là trạng thái người dùng gặp thường xuyên nhất sau vài tuần. |

## Deck quà tặng

| ID | Rule |
|---|---|
| BR-20 | Mỗi deck quà có `seed_id` cố định, không đổi giữa các phiên bản app. |
| BR-21 | Một `seed_id` chỉ được chèn **đúng một lần trong đời** của lần cài đặt đó. Đã ghi vào `applied_seeds` thì không chèn lại, kể cả khi người dùng đã xoá deck. |
| BR-22 | Sau khi chèn, deck quà không khác gì deck tự tạo: sửa, xoá, đổi scheduler đều được. |
| BR-23 | Chèn seed và ghi `applied_seeds` nằm trong cùng một transaction. |

BR-21 là rule dễ cài sai nhất và hậu quả rõ nhất với người dùng: cài sai thì deck
người dùng đã xoá sẽ hồi sinh sau mỗi lần cập nhật app.

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforce ở đâu |
|---|---|---|---|
| Deck.name | không rỗng sau trim | "Tên deck không được để trống" | domain |
| Deck.name | ≤ 200 ký tự | "Tên deck tối đa 200 ký tự" | domain |
| Card.front | không rỗng sau trim | "Mặt trước không được để trống" | domain |
| Card.back | không rỗng sau trim | "Mặt sau không được để trống" | domain |
| Card.front/back | ≤ 2000 ký tự | "Nội dung tối đa 2000 ký tự" | domain |

Toàn bộ enforce ở domain vì chưa có server. Khi có backend, server validate lại —
client validation là trải nghiệm, không phải bảo mật.

---

## Entity state machines

### Card — trạng thái học

Trạng thái **suy ra từ `box` và `due_at`**, không lưu cột riêng. Lưu thêm một cột
trạng thái sẽ tạo khả năng nó mâu thuẫn với `box`.

| Trạng thái | Điều kiện |
|---|---|
| `new` | `due_at IS NULL` |
| `due` | `due_at <= now` |
| `scheduled` | `due_at > now` |

| From | To | Trigger |
|---|---|---|
| new | scheduled | ôn lần đầu, mọi mức đánh giá |
| scheduled | due | thời gian trôi qua `due_at` |
| due | scheduled | được ôn |

**Chuyển đổi không hợp lệ:** không có đường quay lại `new` sau khi đã ôn. Sửa nội
dung card không đưa nó về `new` (BR-09).

### Deck

Deck không có state machine — nó chỉ tồn tại hoặc bị xoá. Cố gán trạng thái
`active`/`archived` lúc này là thêm khái niệm chưa có yêu cầu.

---

## Edge cases

| Case | Expected behaviour |
|---|---|
| Mở app lần đầu, chưa có gì | Chèn deck quà (BR-21), hiển thị luôn danh sách deck |
| Deck rỗng (0 card) | Hiện empty state trong deck với hành động "Thêm card"; không vào được phiên ôn |
| Không card nào đến hạn | Empty state tích cực (BR-19), hiện thời điểm card gần nhất đến hạn |
| Bỏ 2 tuần, 400 card quá hạn | Giới hạn 50 card/phiên (BR-16); hiện số còn lại |
| Thoát giữa phiên ôn | Giữ toàn bộ đánh giá đã ghi (BR-17); mở lại tiếp tục từ card chưa ôn |
| Đổi giờ hệ thống / lệch múi giờ | Lưu `due_at` dạng UTC; so sánh bằng UTC. Người dùng bay qua múi giờ khác không làm card đến hạn sai một ngày |
| Xoá deck đang ôn dở | Kết thúc phiên, quay về danh sách deck |
| Sửa card đang hiện trong phiên | Nội dung mới áp dụng ở lần gặp sau, không đổi giữa lúc đang lật |
| Card ở hộp 8 trả lời Easy | Vẫn hộp 8, xếp lịch lại 128 ngày (BR-11) |
| Nội dung card rất dài (2000 ký tự) | Cuộn được trong vùng card, không tràn, không cắt mất |
| Bộ nhớ đầy khi chèn seed | Transaction rollback (BR-23); hiện lỗi rõ ràng; lần mở sau thử lại |
