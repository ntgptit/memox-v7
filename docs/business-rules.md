# Business rules — memox

_Status: **frozen for MVP** · Last updated: 2026-07-28_

Rules đúng bất kể UI. Đánh số để use case, code comment và test cùng trích dẫn
một định danh — khi rule đổi, đó là cách tìm ra mọi chỗ phụ thuộc nó.

## Chính sách đánh số — đọc trước khi thêm rule

**ID rule là định danh vĩnh viễn. Không bao giờ đánh số lại.**

Rule mới **append vào số tiếp theo**, kể cả khi nó thuộc về một mục nằm ở đầu tài
liệu. Vì vậy ID trong file này **không** tăng dần theo thứ tự đọc, và điều đó là
cố ý.

Lý do: lần renumber trước đã làm hỏng tham chiếu ngầm — `BR-13` từng trỏ tới một
rule về reset, sau khi đánh số lại nó trỏ vào một rule về template mà không có gì
báo lỗi. Tham chiếu sai kiểu đó không hiện ra ở bất kỳ test nào; nó chỉ hiện ra
khi ai đó đọc và làm theo. Đổi lấy thứ tự đọc đẹp bằng rủi ro đó là một trao đổi
tồi.

Rule bị bãi bỏ thì đánh dấu `**BÃI BỎ**` kèm lý do và giữ nguyên ID, không xoá.

Trạng thái đánh số hiện tại: **BR-01…BR-87**, không trùng, không thiếu.

---

## Cây deck

Nền tảng của mô hình dữ liệu, nên đặt đầu tiên dù ID cao hơn (xem chính sách
đánh số).

| ID | Rule |
|---|---|
| BR-55 | Deck được phép lồng **nhiều cấp**. Thiết kế không được giả định cây chỉ có một cấp. |
| BR-56 | Mỗi deck mang `root_deck_id`. Root deck có `root_deck_id = id`. Mọi descendant mang đúng `root_deck_id` của root. |
| BR-57 | Xác định root **phải** qua `root_deck_id`. Cấm dùng `COALESCE(parent_deck_id, id)` — biểu thức đó chỉ đúng với cây một cấp và sẽ trả về sai root ở cấp thứ ba trở đi. |
| BR-58 | **Root deck chỉ được chứa deck con.** Không được tạo card trực tiếp trong root deck. |
| BR-59 | Nút Create tại root deck chỉ có một lựa chọn: **Create deck**. |
| BR-60 | Sub-deck mới tạo có `content_type = unset`. **Không** chọn `content_type` khi tạo. |
| BR-61 | Bấm Create trong sub-deck có `content_type = unset` hiển thị hai lựa chọn: **Create card** và **Create deck**. |
| BR-62 | Lần tạo phần tử con **đầu tiên** xác lập `content_type`, trong cùng một transaction với việc tạo phần tử đó. Chọn Create card → `content_type = card`; chọn Create deck → `content_type = deck`. |
| BR-63 | `content_type = card`: deck chỉ được chứa card. Không được tạo deck con. |
| BR-64 | `content_type = deck`: deck chỉ được chứa deck con. Không được tạo card trực tiếp. |
| BR-65 | **Một deck không bao giờ đồng thời chứa card và deck con.** |
| BR-66 | Sau khi `content_type` được xác lập, nút Create chỉ hiển thị hành động tương ứng. |
| BR-67 | Xoá hết nội dung **không** tự động đưa `content_type` về `unset`. |
| BR-68 | Đưa `content_type` về `unset` là thao tác **riêng biệt**, có xác nhận, và chỉ thực hiện được khi deck đang rỗng. |
| BR-69 | Cây deck **không được có cycle**. |
| BR-70 | Không được di chuyển một deck vào chính nó hoặc vào descendant của nó. |
| BR-71 | Di chuyển subtree phải cập nhật `root_deck_id` cho **toàn bộ** subtree trong **một** transaction. |
| BR-72 | Không descendant nào được trỏ sai root. |

BR-67 và BR-68 tách nhau là có chủ đích. Tự động quay về `unset` khi deck rỗng
nghe tiện, nhưng nó khiến `content_type` đổi âm thầm sau một thao tác xoá — người
dùng xoá card cuối cùng rồi lần sau thấy deck bỗng cho tạo deck con. Bắt đó thành
thao tác tường minh giữ cho cấu trúc cây chỉ đổi khi ai đó thực sự muốn.

BR-57 là ràng buộc cụ thể nhất trong mục này vì nó cấm đúng một biểu thức đã từng
xuất hiện trong tài liệu. `COALESCE(parent_deck_id, id)` cho ra "cha, hoặc chính
nó nếu không có cha" — với deck ở cấp 3 nó trả về deck cấp 2 chứ không phải root.

## Deck — tên và xoá

| ID | Rule |
|---|---|
| BR-01 | Deck phải có tên không rỗng sau khi trim, tối đa 200 ký tự. |
| BR-02 | Tên deck **không** bắt buộc là duy nhất. **Đã chốt** — người dùng có thể muốn hai deck "Unit 5" cho hai giáo trình; ép duy nhất là hạn chế tuỳ tiện. |
| BR-03 | Xoá deck xoá toàn bộ descendant, card, review state, review history và study session của nó (cascade). |
| BR-04 | Xoá deck là hành động phá huỷ và cần xác nhận, kèm số deck con và số card sẽ mất. |
| BR-05 | Scheduler thuộc về **root deck**. Mọi descendant ở mọi cấp kế thừa `scheduler_type`, `scheduler_version` và `scheduler_generation` từ root, và không chọn riêng (AD-06). |
| BR-06 | Cột scheduler chỉ có giá trị trên root deck. Deck không phải root để NULL và tra qua `root_deck_id` (BR-56). |

## Card

| ID | Rule |
|---|---|
| BR-07 | Card phải có mặt trước và mặt sau, đều không rỗng sau khi trim. |
| BR-08 | Mặt trước và mặt sau tối đa 2000 ký tự. **Đã chốt** — đủ cho câu ví dụ dài, đủ chặt để không phá layout. |
| BR-09 | Tạo card đồng thời tạo review state theo scheduler của root deck, với `scheduler_generation` = generation hiện tại của root và `due_at = NULL` (đến hạn ngay). |
| BR-10 | Sửa nội dung card **không** đụng đến review state hay review history. |

Card chỉ tồn tại trong deck có `content_type = card` (BR-63), và không bao giờ
trong root deck (BR-58).

Giá trị khởi tạo của review state theo scheduler:

| Scheduler | Khởi tạo |
|---|---|
| `eight_box` | `current_box = 1`; cột SM-2 để NULL |
| `sm2` | `ease_factor = 2.5`, `interval_days = 0`, `repetitions = 0`; `current_box` NULL |

## Chọn và khoá scheduler

| ID | Rule |
|---|---|
| BR-11 | **Root deck** bắt buộc chọn một scheduler khi tạo: `eight_box` hoặc `sm2`. Không có mặc định ngầm bỏ qua bước chọn. Deck con không hỏi lại (BR-05). |
| BR-12 | Scheduler, version và config đổi **trực tiếp** được chừng nào root deck chưa có lượt review nào ở generation hiện tại (`first_review_at IS NULL`). |
| BR-13 | Sau lượt review `scheduled` đầu tiên, scheduler, version và config bị **khoá**. Đổi chỉ thực hiện được qua Reset learning progress (BR-44). |
| BR-14 | Đổi scheduler khi chưa khoá cũng phải khởi tạo lại review state của toàn bộ card trong cây theo scheduler mới (BR-09) — trong một transaction. |
| BR-73 | **Không tự động chuyển đổi review state giữa hai scheduler.** Không có ánh xạ nào có cơ sở giữa box và ease factor. |
| BR-74 | Di chuyển subtree sang một root có scheduler hoặc generation **không tương thích** phải bị **chặn**, hoặc yêu cầu người dùng thực hiện reset một cách tường minh. Không im lặng chuyển đổi, không im lặng giữ nguyên state cũ. |

BR-14 dễ bị bỏ sót vì "chưa có review nên không có gì để mất". Nhưng review state
đã tồn tại từ lúc tạo card (BR-09), và state của 8-box không dùng được cho SM-2.
Bỏ bước này để lại card `sm2` với `current_box` và không có `ease_factor`.

BR-74 là hệ quả trực tiếp của BR-73 khi cây có nhiều root. Một subtree kéo từ root
dùng `eight_box` sang root dùng `sm2` sẽ mang theo card có `current_box` mà
scheduler mới không hiểu — đúng loại dữ liệu hỏng mà BR-49 cấm.

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

Cập nhật **ở mọi lượt `scheduled`**, kể cả khi `q < 3`. Sàn 1.3 là bắt buộc:
không có nó, một card liên tục bị quên sẽ có ease factor tiến về 0 và interval kẹt
ở 1 ngày vĩnh viễn.

## Loại lượt ôn — `scheduled` và `relearning`

| ID | Rule |
|---|---|
| BR-75 | `review_history` có cột `review_kind` với đúng hai giá trị: `scheduled` và `relearning`. |
| BR-76 | `review_kind` được **lưu tường minh** tại thời điểm ghi. **Cấm suy luận** bằng cách so sánh trạng thái trước và sau. |
| BR-77 | Lượt đánh giá **đầu tiên** của một card trong một session là `scheduled`. Chỉ lượt `scheduled` được cập nhật `current_box`, `ease_factor`, `interval_days` và `due_at`. |
| BR-78 | Card quay lại sau `forgotten` hoặc `again` (BR-26) là `relearning`. Lượt `relearning` **vẫn ghi** review history và **vẫn cập nhật** `last_reviewed_at`, nhưng **không** thay đổi `current_box`, `ease_factor`, `interval_days` hay `due_at`. |

BR-76 đáng nói vì cách suy luận nghe rất hợp lý: "trước và sau giống nhau thì là
relearning". Nó sai ở đúng một trường hợp và trường hợp đó không hiếm — một lượt
`scheduled` trên card ở box 8 trả lời `remembered` cũng có `previous_box == 8` và
`next_box == 8`. Suy luận sẽ gắn nhãn nó là `relearning` và mọi thống kê về sau
đều lệch. Lưu tường minh không có ca biên nào.

BR-77 là rule quan trọng nhất của mục này. Không có nó, một card trả lời
`forgotten` rồi `remembered` ngay trong phiên sẽ nhảy lên box 2 và biến mất khỏi
lịch ngày mai — người dùng vừa quên nó xong đã được cho nghỉ hai ngày. Với BR-77,
luyện lại trong phiên là luyện trí nhớ ngắn hạn (đúng mục đích), còn lịch dài hạn
vẫn giữ card ở box 1 và hẹn gặp lại ngày mai.

### BR-20 · Bộ đếm

| Cột | Quy tắc |
|---|---|
| `review_count` | +1 mỗi lượt `scheduled` (không tính `relearning`) |
| `lapse_count` | +1 khi lượt `scheduled` có action `forgotten` (8-box) hoặc `again` (SM-2) |
| `last_reviewed_at` | = thời điểm đánh giá, cập nhật ở **cả hai** loại lượt |

### BR-21 · Ghi review history

Mỗi lượt đánh giá — cả `scheduled` lẫn `relearning` — ghi một dòng vào
`review_history` gồm `card_id`, `session_id`, `scheduler_type`,
`scheduler_generation`, `review_kind`, `action`, `reviewed_at`, `next_due_at`, và
cặp trạng thái trước/sau của scheduler tương ứng (`previous_box`/`next_box`, hoặc
`previous_ease_factor`/`next_ease_factor` và
`previous_interval_days`/`next_interval_days`).

Ghi cả lượt `relearning` là có chủ đích: nó là dữ liệu thật về việc người dùng
phải lặp mấy lần mới nhớ — thứ cần để đánh giá chất lượng thuật toán sau này.

## Phiên ôn tập

| ID | Rule |
|---|---|
| BR-22 | Một phiên chỉ lấy card có `due_at IS NULL OR due_at <= now`. |
| BR-23 | Thứ tự: card mới (`due_at IS NULL`) trước, sau đó theo `due_at` tăng dần. |
| BR-24 | Giới hạn **50 card riêng biệt** mỗi phiên. **Đã chốt.** Không tính lượt `relearning`. |
| BR-25 | Đánh giá được ghi ngay khi người dùng bấm, không chờ hết phiên. |
| BR-26 | Card đánh giá `forgotten`/`again` **quay lại trong phiên hiện tại**, sau ít nhất **3 card khác**, hoặc cuối hàng đợi nếu không đủ 3. **Đã chốt.** |
| BR-27 | Chỉ lượt `scheduled` thay đổi lịch dài hạn; các lượt sau của cùng card trong cùng session là `relearning`. **Đã chốt.** Chi tiết ở BR-75…BR-78. |
| BR-28 | Card rời hàng đợi khi được đánh giá bằng action khác `forgotten`/`again`. |
| BR-29 | Không có card nào đến hạn là trạng thái **bình thường và tích cực**, không phải lỗi. |
| BR-30 | UI render nút đánh giá từ `supportedActions` của scheduler thuộc root deck. Không hardcode tập action (AD-06). |

## Vòng đời study session

| ID | Rule |
|---|---|
| BR-79 | `study_sessions.status` có đúng năm giá trị: `in_progress`, `completed`, `abandoned`, `invalidated`, `failed`. |
| BR-80 | `study_sessions.end_reason` có bốn giá trị và chỉ đặt khi phù hợp: `user_exit`, `scheduler_reset`, `stale_generation`, `persistence_error`. NULL khi session kết thúc bình thường hoặc chưa kết thúc. |
| BR-81 | Hoàn thành toàn bộ queue → `completed`, `end_reason` NULL. |
| BR-82 | Người dùng chủ động thoát → `abandoned`, `end_reason = user_exit`. |
| BR-83 | Reset xảy ra khi session đang mở → `invalidated`, `end_reason = scheduler_reset`. |
| BR-84 | Session thuộc generation cũ cố ghi review → **từ chối ghi**, chuyển `invalidated`, `end_reason = stale_generation`. |
| BR-85 | Lỗi không thể tiếp tục → `failed`, `end_reason = persistence_error`. |
| BR-86 | Các review đã ghi **thành công** trước khi session kết thúc bất thường **vẫn được giữ**, ở mọi trạng thái kết thúc. |

BR-86 là điều phân biệt "session hỏng" với "mất tiến độ". Session chuyển sang
`failed` hay `invalidated` không được kéo theo việc xoá các lượt đã ghi xong —
người dùng đã bỏ công ôn 20 card thì 20 lượt đó là thật, bất kể phiên kết thúc
thế nào. Đây cũng là lý do BR-25 bắt ghi ngay thay vì gom cuối phiên.

BR-84 chống một tình huống thật và dễ bỏ sót: người dùng mở phiên ôn, để đó, vào
Settings reset deck, rồi quay lại phiên cũ và bấm đánh giá. Không kiểm tra
generation thì kết quả đó ghi đè trạng thái vừa được làm mới, và người dùng thấy
tiến độ "tự sống lại" — một lỗi gần như không thể tái hiện có chủ đích.

## Starter deck (template)

| ID | Rule |
|---|---|
| BR-31 | Starter deck là **template**, không phải deck của người dùng. Template không xuất hiện trong danh sách deck và không ôn trực tiếp được. |
| BR-32 | Template có `template_id` ổn định không đổi giữa các phiên bản app, kèm `version`, `locale`, `title`, `content_source`. |
| BR-33 | Dùng một starter deck nghĩa là **tạo bản sao**: root deck mới với ID riêng, cây deck con, toàn bộ card, và review state theo scheduler đã chọn (BR-09). |
| BR-34 | Bản sao ghi `source_template_id` và `source_template_version` tại thời điểm sao chép. Người dùng chọn scheduler lúc này; template chỉ **gợi ý** qua `default_scheduler_type`. |
| BR-35 | Sau khi sao chép, bản sao là deck bình thường. Không có liên kết ghi ngược về template. |
| BR-36 | Nâng version template ở bản app mới **không** ghi đè, không sửa, không xoá bất kỳ bản sao nào đã tồn tại. |
| BR-37 | Tạo bản sao là idempotent theo `(source_template_id, source_template_version)`: đã có bản sao từ đúng template và version đó thì không tự tạo thêm. |
| BR-38 | Người dùng **cố ý** thêm lại cùng một starter deck là hợp lệ, nhưng phải hỏi xác nhận nêu rõ đã tồn tại. |
| BR-39 | Toàn bộ việc sao chép nằm trong một transaction. |
| BR-87 | Nội dung starter hiện tại là **fixture do dự án tự tạo, chỉ phục vụ development và test**. Không được mô tả hoặc trình bày như nội dung production. Thay bằng nguồn nội dung production hợp lệ trước khi phát hành. |

BR-36 và BR-37 dễ nhầm là một. BR-36 chống **ghi đè** dữ liệu người dùng khi app
cập nhật; BR-37 chống **tạo trùng** khi mở lại app. Vi phạm BR-36 làm mất công
sức người dùng; vi phạm BR-37 làm bẩn danh sách deck. Cả hai chỉ lộ ra ở lần cập
nhật thứ hai, nên phải có test riêng cho từng cái.

BR-87 tồn tại vì dự án chưa có nguồn nội dung từ vựng có bản quyền rõ ràng. Gọi
fixture là "bộ từ vựng" trong store listing hay trong UI sẽ là mô tả sai, và việc
đó khó rút lại sau khi đã phát hành.

## Reset learning progress và generation

| ID | Rule |
|---|---|
| BR-40 | Mỗi root deck có `scheduler_generation`, bắt đầu từ 1, **+1 sau mỗi lần reset**. |
| BR-41 | Reset **giữ nguyên**: deck, toàn bộ cây deck con, flashcard, media, tag và mọi nội dung. |
| BR-42 | Reset **xoá / đặt lại**: active scheduler state của mọi card trong cây (due date, interval, box, ease factor, repetitions, mastery state) và mọi session đang dở. |
| BR-43 | Review history cũ **được giữ lại** để tham khảo, mang generation cũ, và **không được dùng** cho chu kỳ mới. |
| BR-44 | Sau reset, `first_review_at` về NULL → scheduler mở khoá và chọn lại được. Đây là cơ chế **duy nhất** để đổi scheduler sau lượt review đầu (BR-13). |
| BR-45 | Card review state, study session và review history đều mang `scheduler_generation`. |
| BR-46 | **Không chấp nhận kết quả từ session thuộc generation cũ.** Mọi thao tác ghi đánh giá so `session.scheduler_generation` với generation hiện tại của root deck và **từ chối** nếu lệch (BR-84). |
| BR-47 | Reset và đổi scheduler chạy trong **một Drift transaction duy nhất**. |
| BR-48 | Bất biến 1: một cây deck có đúng **một** active scheduler tại một thời điểm. |
| BR-49 | Bất biến 2: toàn bộ card state trong một cây thuộc **cùng một** generation — generation hiện tại của root deck. |
| BR-50 | Reset là hành động phá huỷ và cần xác nhận, nêu rõ những gì mất và những gì giữ. |

BR-47 quan trọng vì nửa vời ở đây nghĩa là một cây deck có card thuộc hai
generation, hoặc scheduler mới với card state theo luật cũ. Cả hai là dữ liệu hỏng
không tự phục hồi, tệ hơn nhiều so với reset thất bại sạch sẽ.

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforce ở đâu |
|---|---|---|---|
| Deck.name | không rỗng sau trim | "Tên deck không được để trống" | domain |
| Deck.name | ≤ 200 ký tự | "Tên deck tối đa 200 ký tự" | domain |
| Deck.schedulerType | bắt buộc chọn khi tạo root deck | "Hãy chọn chế độ ôn tập cho deck" | domain |
| Deck.move | đích không phải chính nó hoặc descendant | "Không thể di chuyển deck vào chính nó" | domain |
| Deck.move | đích cùng root scheduler và generation | "Deck đích dùng chế độ ôn tập khác. Hãy đặt lại tiến độ học trước khi di chuyển" | domain |
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

### Deck — `content_type`

| Trạng thái | Ý nghĩa |
|---|---|
| `unset` | chưa có card và chưa có deck con (BR-60) |
| `card` | chỉ chứa card (BR-63) |
| `deck` | chỉ chứa deck con (BR-64) |

| From | To | Trigger |
|---|---|---|
| unset | card | tạo card đầu tiên (BR-62) |
| unset | deck | tạo deck con đầu tiên (BR-62) |
| card | unset | thao tác reset content_type tường minh, chỉ khi rỗng (BR-68) |
| deck | unset | thao tác reset content_type tường minh, chỉ khi rỗng (BR-68) |

**Chuyển đổi không hợp lệ:**
- `card` → `deck` và `deck` → `card` trực tiếp. Phải đi qua `unset`, tức là phải
  rỗng trước.
- Tự động về `unset` khi xoá hết nội dung (BR-67 cấm).

Root deck được tạo thẳng với `content_type = 'deck'` và giá trị đó **bất biến** —
root không có trạng thái `unset` và không chuyển đổi. Đó là cách BR-58 ("root chỉ
chứa deck con") trở thành ràng buộc kiểm tra được bằng cùng một câu query như mọi
deck khác, thay vì một luật riêng phải nhớ.

### Card review state

Trạng thái **suy ra từ `due_at`**, không lưu cột riêng.

| Trạng thái | Điều kiện |
|---|---|
| `new` | `due_at IS NULL` |
| `due` | `due_at <= now` |
| `scheduled` | `due_at > now` |

| From | To | Trigger |
|---|---|---|
| new | scheduled | lượt `scheduled` đầu tiên |
| scheduled | due | thời gian trôi qua `due_at` |
| due | scheduled | lượt `scheduled` |
| bất kỳ | new | **reset learning progress** (BR-42) |

Reset là chuyển đổi duy nhất quay ngược về `new` — và nó đi kèm generation mới,
nên card sau reset không bị nhầm với card chưa từng ôn ở chu kỳ trước.

**Chuyển đổi không hợp lệ:** sửa nội dung card không đưa nó về `new` (BR-10).
Lượt `relearning` không gây chuyển trạng thái nào (BR-78).

### Deck — trạng thái khoá scheduler

| Trạng thái | Điều kiện |
|---|---|
| `unlocked` | `first_review_at IS NULL` — đổi scheduler tự do |
| `locked` | `first_review_at IS NOT NULL` — chỉ đổi được qua reset |

| From | To | Trigger |
|---|---|---|
| unlocked | locked | lượt `scheduled` đầu tiên ở generation hiện tại |
| locked | unlocked | reset learning progress (BR-44) |

### Study session

| From | To | Trigger |
|---|---|---|
| in_progress | completed | hết queue (BR-81) |
| in_progress | abandoned | người dùng thoát (BR-82) |
| in_progress | invalidated | reset khi đang mở (BR-83), hoặc ghi từ generation cũ (BR-84) |
| in_progress | failed | lỗi không thể tiếp tục (BR-85) |

**Trạng thái kết thúc là terminal** — không có đường quay lại `in_progress`. Mở
lại nghĩa là một session mới.

---

## Edge cases

| Case | Expected behaviour |
|---|---|
| Mở app lần đầu | Hiện thư viện starter deck để chọn. Không tự chèn vào dữ liệu người dùng |
| Bấm Create ở root deck | Chỉ có lựa chọn Create deck (BR-59) |
| Bấm Create ở sub-deck `unset` | Hiện hai lựa chọn (BR-61) |
| Bấm Create ở sub-deck `content_type = card` | Chỉ có Create card (BR-66) |
| Xoá card cuối cùng của deck `content_type = card` | `content_type` giữ nguyên `card` (BR-67) |
| Muốn đổi deck rỗng từ `card` sang chứa deck con | Phải reset `content_type` tường minh (BR-68) |
| Kéo deck vào descendant của chính nó | Chặn, lỗi rõ ràng (BR-70) |
| Di chuyển subtree sang root khác scheduler | Chặn, đề nghị reset (BR-74) |
| Cây sâu 4–5 cấp | Hoạt động bình thường; root tra qua `root_deck_id` (BR-56, BR-57) |
| Tạo root deck không chọn scheduler | Chặn, lỗi inline (BR-11) |
| Đổi scheduler khi chưa có review | Cho phép, khởi tạo lại review state toàn bộ cây (BR-14) |
| Đổi scheduler khi đã có review | Chặn; đề nghị Reset learning progress (BR-13) |
| Mở phiên → reset ở màn khác → quay lại bấm đánh giá | Từ chối ghi; session → `invalidated`/`stale_generation` (BR-84) |
| Reset khi đang có phiên dở | Session → `invalidated`/`scheduler_reset` trong cùng transaction (BR-83, BR-47) |
| App bị kill giữa lúc reset | Transaction rollback; giữ nguyên generation và state cũ (BR-47) |
| Session lỗi ghi không thể tiếp tục | Session → `failed`/`persistence_error`; các lượt đã ghi vẫn giữ (BR-85, BR-86) |
| Card ở box 8 trả lời `remembered` trong lượt `scheduled` | Vẫn box 8, xếp lịch lại 128 ngày (BR-16). `review_kind` vẫn là `scheduled` dù box không đổi (BR-76) |
| Ôn phiên trải trên nhiều deck con | Một tập action duy nhất, của root deck (BR-05, BR-30) |
| Deck rỗng (0 card) | Empty state với hành động phù hợp `content_type`; không vào được phiên ôn |
| Không card nào đến hạn | Empty state tích cực (BR-29), hiện thời điểm card gần nhất đến hạn |
| Bỏ 2 tuần, 400 card quá hạn | Giới hạn 50 card/phiên (BR-24); hiện số còn lại |
| Thoát giữa phiên ôn | Giữ toàn bộ đánh giá đã ghi (BR-25, BR-86); session → `abandoned`/`user_exit` |
| SM-2, card bị quên liên tục | `ease_factor` chạm sàn 1.3 và dừng ở đó (BR-19) |
| Đổi giờ hệ thống / lệch múi giờ | Lưu và so sánh `due_at` bằng UTC |
| Thêm starter deck đã có bản sao | Hỏi xác nhận nêu rõ đã tồn tại (BR-38) |
| Cập nhật app nâng version template | Không đụng vào bản sao đã có (BR-36) |
| Nội dung card rất dài (2000 ký tự) | Cuộn được trong vùng card, không tràn, không cắt mất |
| Bộ nhớ đầy khi sao chép starter deck | Transaction rollback (BR-39); không để lại deck nửa vời |
