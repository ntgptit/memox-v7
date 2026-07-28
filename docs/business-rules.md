# Business rules — memox

_Status: draft · Last updated: 2026-07-28_

Rules đúng bất kể UI. Đánh số để use case, code comment và test cùng trích dẫn
một định danh — khi rule đổi, đó là cách tìm ra mọi chỗ phụ thuộc nó.

Mục [suy luận] là chỗ tôi tự quyết vì không có đặc tả; nếu sai thì sửa ở đây
trước, code theo sau.

---

## Deck và sub-deck

| ID | Rule |
|---|---|
| BR-01 | Deck phải có tên không rỗng sau khi trim, tối đa 200 ký tự. |
| BR-02 | Tên deck **không** bắt buộc là duy nhất. [suy luận] |
| BR-03 | Xoá deck xoá toàn bộ sub-deck, card, review state, review history và study session của nó (cascade). |
| BR-04 | Xoá deck là hành động phá huỷ và cần xác nhận, kèm số sub-deck và số card sẽ mất. |
| BR-05 | Sub-deck chỉ là cấu trúc phân cấp. Nó **kế thừa scheduler của root deck** và **không** chọn scheduler riêng (AD-06). |
| BR-06 | Cột scheduler chỉ có giá trị trên root deck. Sub-deck để NULL và tra ngược lên root. |

## Card

| ID | Rule |
|---|---|
| BR-07 | Card phải có mặt trước và mặt sau, đều không rỗng sau khi trim. |
| BR-08 | Mặt trước và mặt sau tối đa 2000 ký tự. [suy luận] |
| BR-09 | Tạo card đồng thời tạo review state theo scheduler của root deck, với `scheduler_generation` = generation hiện tại của deck và `due_at = NULL` (đến hạn ngay). |
| BR-10 | Sửa nội dung card **không** đụng đến review state hay review history. |

Giá trị khởi tạo của review state theo scheduler:

| Scheduler | Khởi tạo |
|---|---|
| `eight_box` | `current_box = 1`; cột SM-2 để NULL |
| `sm2` | `ease_factor = 2.5`, `interval_days = 0`, `repetitions = 0`; `current_box` NULL |

## Chọn và khoá scheduler

| ID | Rule |
|---|---|
| BR-11 | Mỗi deck **bắt buộc chọn** một scheduler khi tạo: `eight_box` hoặc `sm2`. Không có mặc định ngầm bỏ qua bước chọn. |
| BR-12 | Scheduler, version và config đổi **trực tiếp** được chừng nào deck chưa có lượt review nào ở generation hiện tại (`first_review_at IS NULL`). |
| BR-13 | Sau lượt review đầu tiên, scheduler, version và config bị **khoá**. Đổi chỉ thực hiện được qua Reset learning progress (BR-36). |
| BR-14 | Đổi scheduler khi chưa khoá cũng phải khởi tạo lại review state của toàn bộ card theo scheduler mới (BR-09) — trong một transaction. |

BR-14 dễ bị bỏ sót vì "chưa có review nên không có gì để mất". Nhưng review state
đã tồn tại từ lúc tạo card (BR-09), và state của 8-box không dùng được cho SM-2.
Bỏ bước này để lại card `sm2` với `current_box` và không có `ease_factor`.

## Scheduler `eight_box`

Hai action: **`forgotten`** và **`remembered`**.

### BR-15 · Chuyển box

| Action | Box đích |
|---|---|
| `forgotten` | `1` |
| `remembered` | `min(8, current_box + 1)` |

### BR-16 · Bảng interval

| Box | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Ngày | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

`next_due_at = now + interval(box đích)`.

Box 8 là box cuối. Card ở box 8 trả lời `remembered` vẫn ở box 8 và xếp lịch lại
sau 128 ngày — **không** có trạng thái "tốt nghiệp" khiến card biến mất, vì trí
nhớ vẫn phai.

"Đã thuộc" (`current_box == 8`) là giá trị **suy ra để hiển thị**, không phải cột
trong DB.

## Scheduler `sm2`

Bốn action: **`again`**, **`hard`**, **`good`**, **`easy`**.

### BR-17 · Ánh xạ action sang thang chất lượng

| Action | q |
|---|---|
| `again` | 0 |
| `hard` | 3 |
| `good` | 4 |
| `easy` | 5 |

### BR-18 · Cập nhật interval và repetitions

```
nếu q < 3:
    repetitions = 0
    interval_days = 1
ngược lại:
    nếu repetitions == 0: interval_days = 1
    nếu repetitions == 1: interval_days = 6
    ngược lại:            interval_days = round(interval_days * ease_factor)
    repetitions = repetitions + 1
```

`next_due_at = now + interval_days`.

### BR-19 · Cập nhật ease factor

```
ease_factor = max(1.3, ease_factor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
```

Cập nhật **ở mọi lượt**, kể cả khi `q < 3`. Sàn 1.3 là bắt buộc: không có nó,
một card liên tục bị quên sẽ có ease factor tiến về 0 và interval kẹt ở 1 ngày
vĩnh viễn.

### BR-20 · Bộ đếm (cả hai scheduler)

| Cột | Quy tắc |
|---|---|
| `review_count` | +1 mỗi lượt đánh giá **có xếp lịch** (không tính luyện lại, BR-27) |
| `lapse_count` | +1 khi action là `forgotten` (8-box) hoặc `again` (SM-2) |
| `last_reviewed_at` | = thời điểm đánh giá, cập nhật cả ở lượt luyện lại |

### BR-21 · Ghi review history

Mỗi lượt đánh giá — kể cả luyện lại — ghi một dòng vào `review_history` gồm
`card_id`, `session_id`, `scheduler_type`, `scheduler_generation`, `action`,
`reviewed_at`, `next_due_at`, và cặp trạng thái trước/sau của scheduler tương ứng
(`previous_box`/`next_box`, hoặc `previous_ease_factor`/`next_ease_factor` và
`previous_interval_days`/`next_interval_days`).

Ghi cả lượt luyện lại là có chủ đích: nó là dữ liệu thật về việc người dùng phải
lặp mấy lần mới nhớ — thứ cần để đánh giá chất lượng thuật toán sau này.

## Phiên ôn tập

| ID | Rule |
|---|---|
| BR-22 | Một phiên chỉ lấy card có `due_at IS NULL OR due_at <= now`. |
| BR-23 | Thứ tự: card mới (`due_at IS NULL`) trước, sau đó theo `due_at` tăng dần. |
| BR-24 | Giới hạn 50 card riêng biệt mỗi phiên. [suy luận] Không tính lượt luyện lại. |
| BR-25 | Đánh giá được ghi ngay khi người dùng bấm, không chờ hết phiên. |
| BR-26 | Card đánh giá `forgotten`/`again` **quay lại trong phiên hiện tại**, sau ít nhất 3 card khác, hoặc cuối hàng đợi nếu còn ít hơn 3. [suy luận] |
| BR-27 | Chỉ lượt đánh giá **đầu tiên** của một card trong phiên quyết định trạng thái lịch. Các lượt sau là **luyện lại**: ghi history (BR-21), cập nhật `last_reviewed_at`, nhưng **không** đổi box/ease factor/interval và không đổi `due_at`. [suy luận] |
| BR-28 | Card rời hàng đợi khi được đánh giá bằng action khác `forgotten`/`again`. |
| BR-29 | Không có card nào đến hạn là trạng thái **bình thường và tích cực**, không phải lỗi. |
| BR-30 | UI render nút đánh giá từ `supportedActions` của scheduler thuộc root deck. Không hardcode tập action (AD-06). |

BR-27 là rule quan trọng nhất của mục này. Không có nó, một card trả lời
`forgotten` rồi `remembered` ngay trong phiên sẽ nhảy lên box 2 và biến mất khỏi
lịch ngày mai — người dùng vừa quên nó xong đã được cho nghỉ hai ngày. Với BR-27,
luyện lại trong phiên là luyện trí nhớ ngắn hạn (đúng mục đích), còn lịch dài hạn
vẫn giữ card ở box 1 và hẹn gặp lại ngày mai.

## Starter deck (template)

| ID | Rule |
|---|---|
| BR-31 | Starter deck là **template**, không phải deck của người dùng. Template không xuất hiện trong danh sách deck và không ôn trực tiếp được. |
| BR-32 | Template có `template_id` ổn định không đổi giữa các phiên bản app, kèm `version`, `locale`, `title`, `content_source`. |
| BR-33 | Dùng một starter deck nghĩa là **tạo bản sao**: deck mới với ID riêng, toàn bộ card, và review state theo scheduler đã chọn (BR-09). |
| BR-34 | Bản sao ghi `source_template_id` và `source_template_version` tại thời điểm sao chép. Người dùng chọn scheduler lúc này; template chỉ **gợi ý** qua `default_scheduler_type`. |
| BR-35 | Sau khi sao chép, bản sao là deck bình thường. Không có liên kết ghi ngược về template. |
| BR-36 | Nâng version template ở bản app mới **không** ghi đè, không sửa, không xoá bất kỳ bản sao nào đã tồn tại. |
| BR-37 | Tạo bản sao là idempotent theo `(source_template_id, source_template_version)`: đã có bản sao từ đúng template và version đó thì không tự tạo thêm. |
| BR-38 | Người dùng **cố ý** thêm lại cùng một starter deck là hợp lệ, nhưng phải hỏi xác nhận nêu rõ đã tồn tại. |
| BR-39 | Toàn bộ việc sao chép nằm trong một transaction. |

BR-36 và BR-37 dễ nhầm là một. BR-36 chống **ghi đè** dữ liệu người dùng khi app
cập nhật; BR-37 chống **tạo trùng** khi mở lại app. Vi phạm BR-36 làm mất công
sức người dùng; vi phạm BR-37 làm bẩn danh sách deck. Cả hai chỉ lộ ra ở lần cập
nhật thứ hai, nên phải có test riêng cho từng cái.

## Reset learning progress và generation

| ID | Rule |
|---|---|
| BR-40 | Mỗi root deck có `scheduler_generation`, bắt đầu từ 1, **+1 sau mỗi lần reset**. |
| BR-41 | Reset **giữ nguyên**: deck, sub-deck, flashcard, media, tag và toàn bộ nội dung. |
| BR-42 | Reset **xoá / đặt lại**: active scheduler state của mọi card (due date, interval, box, ease factor, repetitions, mastery state) và mọi session đang dở. |
| BR-43 | Review history cũ **được giữ lại** để tham khảo, mang generation cũ, và **không được dùng** cho chu kỳ mới. |
| BR-44 | Sau reset, `first_review_at` về NULL → scheduler mở khoá và chọn lại được. Đây là cơ chế **duy nhất** để đổi scheduler sau lượt review đầu (BR-13). |
| BR-45 | Card review state, study session và review history đều mang `scheduler_generation`. |
| BR-46 | **Không chấp nhận kết quả từ session thuộc generation cũ.** Mọi thao tác ghi đánh giá so `session.scheduler_generation` với generation hiện tại của root deck và **từ chối** nếu lệch. |
| BR-47 | Reset và đổi scheduler chạy trong **một Drift transaction duy nhất**. |
| BR-48 | Bất biến 1: một deck có đúng **một** active scheduler tại một thời điểm. |
| BR-49 | Bất biến 2: toàn bộ card state của một deck thuộc **cùng một** generation — generation hiện tại của root deck. |
| BR-50 | Reset là hành động phá huỷ và cần xác nhận, nêu rõ những gì mất và những gì giữ. |

BR-46 chống một tình huống thật và dễ bỏ sót: người dùng mở phiên ôn, để đó, vào
Settings reset deck, rồi quay lại phiên cũ và bấm đánh giá. Không kiểm tra
generation thì kết quả đó ghi đè trạng thái vừa được làm mới, và người dùng thấy
tiến độ "tự sống lại" — một lỗi gần như không thể tái hiện có chủ đích.

BR-47 quan trọng vì nửa vời ở đây nghĩa là một deck có card thuộc hai generation,
hoặc scheduler mới với card state theo luật cũ. Cả hai là dữ liệu hỏng không tự
phục hồi, tệ hơn nhiều so với reset thất bại sạch sẽ.

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforce ở đâu |
|---|---|---|---|
| Deck.name | không rỗng sau trim | "Tên deck không được để trống" | domain |
| Deck.name | ≤ 200 ký tự | "Tên deck tối đa 200 ký tự" | domain |
| Deck.schedulerType | bắt buộc chọn khi tạo | "Hãy chọn chế độ ôn tập cho deck" | domain |
| Card.front | không rỗng sau trim | "Mặt trước không được để trống" | domain |
| Card.back | không rỗng sau trim | "Mặt sau không được để trống" | domain |
| Card.front/back | ≤ 2000 ký tự | "Nội dung tối đa 2000 ký tự" | domain |

Toàn bộ enforce ở domain vì chưa có server. Khi có backend, server validate lại —
client validation là trải nghiệm, không phải bảo mật.

---

## Dữ liệu riêng tư

| ID | Rule |
|---|---|
| BR-51 | Nội dung deck/card, ghi chú, lịch sử học, file import, hình ảnh, audio và dữ liệu backup là **dữ liệu riêng tư**. |
| BR-52 | Không log nội dung flashcard hoặc ghi chú ở bất kỳ log level nào. Log ID thì được. |
| BR-53 | Media lưu trong thư mục riêng của ứng dụng, không phải bộ nhớ dùng chung. |
| BR-54 | Export và backup chỉ chạy khi người dùng chủ động yêu cầu — không tự động, không chạy nền. |

Xem AD-08 cho token và mã hoá database khi backend xuất hiện.

---

## Entity state machines

### Card review state

Trạng thái **suy ra từ `due_at`**, không lưu cột riêng.

| Trạng thái | Điều kiện |
|---|---|
| `new` | `due_at IS NULL` |
| `due` | `due_at <= now` |
| `scheduled` | `due_at > now` |

| From | To | Trigger |
|---|---|---|
| new | scheduled | lượt đánh giá có xếp lịch đầu tiên |
| scheduled | due | thời gian trôi qua `due_at` |
| due | scheduled | được đánh giá có xếp lịch |
| bất kỳ | new | **reset learning progress** (BR-42) |

Reset là chuyển đổi duy nhất quay ngược về `new` — và nó đi kèm generation mới,
nên card sau reset không bị nhầm với card chưa từng ôn ở chu kỳ trước.

**Chuyển đổi không hợp lệ:** sửa nội dung card không đưa nó về `new` (BR-10).
Lượt luyện lại trong phiên (BR-27) không gây chuyển trạng thái nào.

### Deck — trạng thái khoá scheduler

| Trạng thái | Điều kiện |
|---|---|
| `unlocked` | `first_review_at IS NULL` — đổi scheduler tự do |
| `locked` | `first_review_at IS NOT NULL` — chỉ đổi được qua reset |

| From | To | Trigger |
|---|---|---|
| unlocked | locked | lượt đánh giá có xếp lịch đầu tiên ở generation hiện tại |
| locked | unlocked | reset learning progress (BR-44) |

---

## Edge cases

| Case | Expected behaviour |
|---|---|
| Mở app lần đầu | Hiện thư viện starter deck để chọn. Không tự chèn vào dữ liệu người dùng |
| Tạo deck không chọn scheduler | Chặn, lỗi inline (BR-11) |
| Đổi scheduler khi chưa có review | Cho phép, khởi tạo lại review state toàn bộ card (BR-14) |
| Đổi scheduler khi đã có review | Chặn; đề nghị Reset learning progress (BR-13) |
| Mở phiên → reset ở màn khác → quay lại bấm đánh giá | Từ chối ghi, thông báo phiên đã hết hiệu lực, đóng phiên (BR-46) |
| Reset khi đang có phiên dở | Phiên bị huỷ trong cùng transaction (BR-42, BR-47) |
| App bị kill giữa lúc reset | Transaction rollback; deck giữ nguyên generation cũ và state cũ (BR-47) |
| Sub-deck cố đặt scheduler riêng | Không có đường nào làm được — cột scheduler trên sub-deck luôn NULL (BR-06) |
| Ôn phiên trải trên nhiều sub-deck | Một tập action duy nhất, của root deck (BR-05, BR-30) |
| Deck rỗng (0 card) | Empty state với hành động "Thêm card"; không vào được phiên ôn |
| Không card nào đến hạn | Empty state tích cực (BR-29), hiện thời điểm card gần nhất đến hạn |
| Bỏ 2 tuần, 400 card quá hạn | Giới hạn 50 card/phiên (BR-24); hiện số còn lại |
| Thoát giữa phiên ôn | Giữ toàn bộ đánh giá đã ghi (BR-25); mở lại bắt đầu phiên mới |
| SM-2, card bị quên liên tục | `ease_factor` chạm sàn 1.3 và dừng ở đó (BR-19) |
| 8-box, card ở box 8 trả lời `remembered` | Vẫn box 8, xếp lịch lại 128 ngày (BR-16) |
| Đổi giờ hệ thống / lệch múi giờ | Lưu và so sánh `due_at` bằng UTC |
| Thêm starter deck đã có bản sao | Hỏi xác nhận nêu rõ đã tồn tại (BR-38) |
| Cập nhật app nâng version template | Không đụng vào bản sao đã có (BR-36) |
| Nội dung card rất dài (2000 ký tự) | Cuộn được trong vùng card, không tràn, không cắt mất |
| Bộ nhớ đầy khi sao chép starter deck | Transaction rollback (BR-39); không để lại deck nửa vời |
