# Business rules — memox

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu mọi luật nghiệp vụ đúng bất kể UI, dưới một ID vĩnh viễn để code, test và tài liệu khác cùng trích dẫn |
| **Scope** | Luật nghiệp vụ, validation rule, state machine, edge case của phạm vi MVP. Ngoài phạm vi: quyết định kiến trúc (`architecture.md`), hình dạng dữ liệu (`data-model.md`), luồng người dùng (`use-cases.md`) |
| **Source of truth for** | BR-xx · validation rule · entity state machine · edge case |
| **Depends on** | `document-conventions.md`, `product.md`, `architecture.md` |
| **Updated by task** | M5.0d (chuỗi stage; browse/self_assess) |
| **Last updated** | 2026-08-07 |

Format tuân theo `document-conventions.md` §6.2. Từ khoá MUST / SHOULD / MAY
theo §3. Prose **không** chứa từ khoá là giải thích, không phải rule (§9).

## Chính sách đánh số — đọc trước khi thêm rule

**ID rule là định danh vĩnh viễn. MUST NOT đánh số lại** (§7).

Rule mới append vào số tiếp theo, kể cả khi nó thuộc một mục nằm ở đầu tài liệu.
Vì vậy ID **không** tăng dần theo thứ tự đọc, và điều đó là cố ý.

Lý do: lần renumber trước đã làm hỏng tham chiếu ngầm — `BR-13` từng trỏ tới một
rule về reset, sau khi đánh số lại nó trỏ vào một rule về template mà không có gì
báo lỗi. Tham chiếu sai kiểu đó không hiện ra ở bất kỳ test nào; nó chỉ hiện ra
khi ai đó đọc và làm theo.

Rule bị thay thế MUST đánh `superseded by BR-yy` ở cột Status và giữ nguyên ID.

Trạng thái hiện tại: **BR-01…BR-114**, không trùng, không thiếu.

---

## Cây deck

Nền tảng của mô hình dữ liệu, nên đặt đầu tiên dù ID cao hơn.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-55 | active | Deck MUST được phép lồng nhiều cấp, tối đa **10 cấp** với root là cấp 1; tạo hoặc di chuyển deck vượt cấp 10 MUST bị chặn trước khi ghi. Thiết kế MUST NOT giả định cây chỉ có một cấp. | repository + invariant Q15 | AD-10, UC-08, UC-09 |
| BR-56 | active | Mỗi deck MUST mang `root_deck_id`. Root deck có `root_deck_id = id`; mọi descendant mang đúng `root_deck_id` của root. | db + invariant Q6, Q7 | AD-10, UC-08, UC-09 |
| BR-57 | active | Xác định root MUST qua `root_deck_id`. MUST NOT dùng `COALESCE(parent_deck_id, id)`. | script | AD-10 |
| BR-58 | active | Root deck MUST chỉ chứa deck con; MUST NOT chứa card trực tiếp. | db + invariant Q1 | AD-10, UC-02, UC-08 |
| BR-59 | active | Nút Create tại root deck MUST chỉ có một lựa chọn: Create deck. | UI | UC-08 |
| BR-60 | active | Sub-deck mới tạo MUST có `content_type = unset`. Người dùng MUST NOT chọn `content_type` khi tạo. | domain | AD-10, UC-08 |
| BR-61 | active | Bấm Create trong sub-deck `unset` MUST hiển thị hai lựa chọn: Create card và Create deck. | UI | UC-08 |
| BR-62 | active | Lần tạo phần tử con đầu tiên MUST xác lập `content_type`, trong cùng transaction với việc tạo phần tử đó. | repository | AD-10, UC-08 |
| BR-63 | active | `content_type = card`: deck MUST chỉ chứa card; MUST NOT chứa deck con. | db + invariant Q3 | UC-04, UC-08 |
| BR-64 | active | `content_type = deck`: deck MUST chỉ chứa deck con; MUST NOT chứa card trực tiếp. | db + invariant Q4 | UC-08, UC-09 |
| BR-65 | active | Một deck MUST NOT đồng thời chứa card và deck con. | db + invariant Q3, Q4 | AD-10, UC-06 |
| BR-66 | active | Sau khi `content_type` được xác lập, nút Create MUST chỉ hiển thị hành động tương ứng. | UI | UC-08 |
| BR-67 | active | Xoá hết nội dung MUST NOT tự động đưa `content_type` về `unset`. | domain | AD-10, UC-04 |
| BR-68 | active | Đưa `content_type` về `unset` MUST là thao tác riêng, có xác nhận, và chỉ thực hiện được khi deck rỗng. | domain + UI | AD-10, UC-03 |
| BR-69 | active | Cây deck MUST NOT có cycle. | invariant Q8 | AD-10, UC-09 |
| BR-70 | active | MUST NOT di chuyển một deck vào chính nó hoặc vào descendant của nó. | domain | UC-09 |
| BR-71 | active | Di chuyển subtree MUST cập nhật `root_deck_id` cho toàn bộ subtree trong một transaction. | repository | AD-10, UC-09 |
| BR-72 | active | MUST NOT có descendant trỏ sai root. | invariant Q6 | AD-10, UC-09 |

BR-67 và BR-68 tách nhau là có chủ đích. Tự động quay về `unset` khi deck rỗng
nghe tiện, nhưng nó khiến `content_type` đổi âm thầm sau một thao tác xoá — người
dùng xoá card cuối cùng rồi lần sau thấy deck bỗng cho tạo deck con. Bắt đó thành
thao tác tường minh giữ cho cấu trúc cây chỉ đổi khi ai đó thực sự muốn.

BR-57 cấm đúng một biểu thức đã từng xuất hiện trong tài liệu.
`COALESCE(parent_deck_id, id)` cho ra "cha, hoặc chính nó nếu không có cha", nên
với deck ở cấp 3 nó trả về deck cấp 2 chứ không phải root.

## Deck — tên và xoá

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-01 | active | Deck MUST có tên không rỗng sau khi trim, tối đa 200 ký tự. | domain | UC-02, UC-03 |
| BR-02 | active | Tên deck MAY trùng nhau. | domain | UC-02 |
| BR-03 | active | Xoá deck MUST xoá toàn bộ descendant, card, study state, study answers và study session của nó (cascade). | db | UC-03 |
| BR-04 | active | Xoá deck MUST cần xác nhận, kèm số deck con và số card sẽ mất. | UI | UC-03 |
| BR-05 | active | Scheduler thuộc về root deck. Mọi descendant ở mọi cấp MUST kế thừa `scheduler_type`, `scheduler_version` và `scheduler_generation` từ root, và MUST NOT chọn riêng. | db + invariant Q9, Q10 | AD-06, UC-05 |
| BR-06 | active | Cột scheduler MUST chỉ có giá trị trên root deck; deck không phải root MUST để NULL và tra qua `root_deck_id`. | invariant Q10 | AD-06, UC-03 |

BR-02 đã chốt: người dùng có thể muốn hai deck "Unit 5" cho hai giáo trình, nên
ép duy nhất là hạn chế tuỳ tiện.

## Card

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-07 | active | Card MUST có mặt trước và mặt sau, đều không rỗng sau khi trim. | domain | UC-04 |
| BR-08 | active | Mặt trước MUST tối đa **60** ký tự và mặt sau MUST tối đa **240** ký tự, đo sau khi trim. | domain | UC-04 |
| BR-95 | active | Thẻ MAY có ba trường phụ, đều tuỳ chọn: ví dụ, gợi ý và phiên âm. Mỗi trường MUST tối đa 240 ký tự sau khi trim. | domain | UC-04, BR-08 |
| BR-09 | active | Tạo card MUST đồng thời tạo study state theo scheduler của root deck, với `scheduler_generation` hiện tại của root và `due_at = NULL`. | repository | UC-04, UC-08 |
| BR-10 | active | Sửa nội dung card MUST NOT đụng đến study state hay study answers. | repository | UC-04 |

Card chỉ tồn tại trong deck có `content_type = card` (BR-63), và không bao giờ
trong root deck (BR-58).

**BR-08 đổi số ở M4.10at: 2000 cho cả hai → 60 và 240.** Rule giữ nguyên ID chứ
không đánh `superseded`, vì cơ chế supersede của §7 dành cho lúc *danh tính* một
rule đổi khiến tham chiếu cũ trỏ sai chỗ. Ở đây ý nghĩa không đổi — "hai mặt có
giới hạn độ dài" — nên 21 chỗ đang trích BR-08 vẫn trích đúng thứ chúng định
trích. Cái đổi là con số, và nó được ghi ở đây thay vì im lặng.

2000 là **hàng rào chống dán**, không phải một quyết định về thẻ: nó chặn ai đó
thả nguyên một trang vào ô và không nói gì về thẻ nên dài bao nhiêu. 60 là bề
rộng mà hàng danh sách và mặt trước thẻ ôn được vẽ cho; quá đó thì prompt xuống
ba dòng trên điện thoại và câu trả lời rơi khỏi tầm nhìn. 240 gấp bốn vì một
nghĩa chứa nhiều hơn một từ — hai ngôn ngữ, ngăn bằng dấu phẩy.

**Hai mặt nay có hai số, nên giới hạn thuộc về `CardSide`** chứ không phải một
hằng số dùng chung. Một hằng chung là đúng khi số giống nhau và trở thành cách
âm thầm cho mặt trước mượn hạn mức của mặt sau ngay khi chúng khác nhau;
`card_text_test.dart` ghim đúng điều đó.

BR-95 để cả ba trường phụ ở 240 thay vì ba con số riêng. Chúng là văn bản hỗ
trợ cùng bậc với mặt sau, và ba ngưỡng khác nhau cho ba ô trông giống nhau là
thứ phải giải thích mà không mua được gì.

Giá trị khởi tạo của study state theo scheduler:

| Scheduler | Khởi tạo |
|---|---|
| `eight_box` | `current_box = 1`; cột SM-2 để NULL |
| `sm2` | `ease_factor = 2.5`, `interval_days = 0`, `repetitions = 0`; `current_box` NULL |

## Chọn và khoá scheduler

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-11 | active | Root deck MUST chọn một scheduler khi tạo: `eight_box` hoặc `sm2`. MUST NOT có mặc định ngầm bỏ qua bước chọn. | domain + invariant Q11 | AD-06, UC-02 |
| BR-12 | active | Scheduler, version và config MAY đổi trực tiếp chừng nào root deck chưa có lượt học nào ở generation hiện tại (`first_answered_at IS NULL`). | domain | AD-06, UC-03 |
| BR-13 | active | Sau lượt học `scheduled` đầu tiên, scheduler, version và config MUST bị khoá. Đổi MUST đi qua Reset learning progress (BR-44). | domain | AD-06, UC-03, UC-07 |
| BR-14 | active | Đổi scheduler khi chưa khoá MUST khởi tạo lại study state của toàn bộ card trong cây theo scheduler mới, trong một transaction. | repository | UC-03 |
| BR-73 | active | MUST NOT tự động chuyển đổi study state giữa hai scheduler. | domain | AD-06, UC-09 |
| BR-74 | active | Di chuyển subtree sang root có scheduler hoặc generation không tương thích MUST bị chặn, hoặc MUST yêu cầu người dùng reset tường minh. | domain | AD-06, UC-09 |

BR-14 dễ bị bỏ sót vì "chưa có lượt học nên không có gì để mất". Nhưng study state
đã tồn tại từ lúc tạo card (BR-09), và state của 8-box không dùng được cho SM-2.
Bỏ bước này để lại card `sm2` với `current_box` và không có `ease_factor`.

BR-74 là hệ quả trực tiếp của BR-73 khi cây có nhiều root. Một subtree kéo từ root
dùng `eight_box` sang root dùng `sm2` sẽ mang theo card có `current_box` mà
scheduler mới không hiểu.

## Scheduler `eight_box`

Hai action: `forgotten` và `remembered`.

### BR-15 · Chuyển box

**Status:** active · **Enforced by:** scheduler · **Related:** AD-06

| Action | Box đích |
|---|---|
| `forgotten` | `1` |
| `remembered` | `min(8, current_box + 1)` |

### BR-16 · Bảng interval

**Status:** active · **Enforced by:** scheduler · **Related:** AD-06

| Box | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Ngày | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

`next_due_at` = đầu ngày học thứ `interval(box đích)` — 00:00 giờ địa phương,
lưu bằng UTC (BR-105). Không phải `now + N*24h`: xem AD-16.

Box 8 là box cuối. Card ở box 8 trả lời `remembered` vẫn ở box 8 và xếp lịch lại
sau 128 ngày — không có trạng thái "tốt nghiệp" khiến card biến mất, vì trí nhớ
vẫn phai. "Đã thuộc" (`current_box == 8`) là giá trị suy ra để hiển thị, không
phải cột trong DB.

## Scheduler `sm2`

Bốn action: `again`, `hard`, `good`, `easy`.

### BR-17 · Ánh xạ action sang thang chất lượng

**Status:** active · **Enforced by:** scheduler · **Related:** AD-06

| Action | q |
|---|---|
| `again` | 0 |
| `hard` | 3 |
| `good` | 4 |
| `easy` | 5 |

### BR-18 · Cập nhật interval và repetitions

**Status:** active · **Enforced by:** scheduler · **Related:** AD-06

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

`next_due_at` = đầu ngày học thứ `interval_days`, theo đúng BR-105 như `eight_box`.

### BR-19 · Cập nhật ease factor

**Status:** active · **Enforced by:** scheduler · **Related:** AD-06

```
ease_factor = max(1.3, ease_factor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
```

Cập nhật ở mọi lượt `scheduled`, kể cả khi `q < 3`. Sàn 1.3 là bắt buộc: không có
nó, một card liên tục bị quên sẽ có ease factor tiến về 0 và interval kẹt ở 1
ngày vĩnh viễn.

## Card "đã thuộc" — giá trị suy ra, hai scheduler

### BR-88 · Định nghĩa "đã thuộc"

**Status:** active · **Enforced by:** db (query tổng hợp) · **Related:** BR-16, BR-18, UC-06

Một card MUST được tính là "đã thuộc" khi:

| Scheduler | Điều kiện |
|---|---|
| `eight_box` | `current_box = 8` |
| `sm2` | `interval_days >= 128` |

Giá trị này MUST được suy ra khi đọc và MUST NOT là cột trong DB.

**Nửa `eight_box` không phải luật mới.** BR-16 đã phát biểu nó bằng văn xuôi từ
trước: *"Đã thuộc" (`current_box == 8`) là giá trị suy ra để hiển thị, không phải
cột trong DB*. BR-88 chỉ nâng nó thành một rule có ID và mở rộng sang scheduler
thứ hai, vì màn deck cần một con số dùng được cho cả hai.

**Vì sao `sm2` là 128 ngày và không phải 21.** 21 là ngưỡng "mature card" quen
thuộc của SM-2/Anki, và nó tới sớm hơn nhiều — khoảng bốn lần trả lời tốt
(1 → 6 → 15 → 37). Chọn 128 vì nó **khớp đúng interval của box 8** (BR-16), nên
"đã thuộc" nghĩa là cùng một khoảng cách thời gian ở cả hai scheduler thay vì
cùng một quy ước ở một cái và một quy ước khác ở cái kia.

Cái giá đã nhận, nói thẳng vì nó nhìn thấy được: một deck `sm2` cần khoảng bảy
lần trả lời tốt mới có card đầu tiên "đã thuộc", nên thanh tiến độ của nó nhúc
nhích chậm hơn hẳn một deck `eight_box` cùng số lần ôn. Đó là hệ quả của việc
khớp theo thời gian chứ không phải theo công sức, và là lựa chọn có ý thức.

**Suy ra khi đọc, không lưu.** Một cột `is_learned` sẽ phải cập nhật ở mọi
đường ghi chạm vào `current_box` hoặc `interval_days`, và sẽ sai ngay lần đầu
một đường nào đó quên — trong khi ngưỡng thì đứng yên và cả hai cột đã có index
cần thiết. Reset learning progress vì thế cũng tự động đúng: nó đặt lại state,
và con số suy ra đi theo.

## Loại lượt ôn — `scheduled` và `relearning`

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-75 | active | `study_answers` MUST có cột `kind` với đúng hai giá trị: `scheduled` và `relearning`. | db | AD-11 |
| BR-76 | active | `kind` MUST được lưu tường minh tại thời điểm ghi. MUST NOT suy luận bằng cách so sánh trạng thái trước và sau. | repository | AD-11 |
| BR-77 | active | Lượt đánh giá đầu tiên của một card trong một session MUST là `scheduled`. Chỉ lượt `scheduled` MAY cập nhật `current_box`, `ease_factor`, `interval_days` và `due_at`. | repository | UC-05, AD-11 |
| BR-78 | active | Card quay lại sau `forgotten`/`again` MUST là `relearning`. Lượt `relearning` MUST ghi study answers và cập nhật `last_answered_at`, nhưng MUST NOT thay đổi `current_box`, `ease_factor`, `interval_days` hay `due_at`. | repository + invariant Q14 | UC-05, AD-11 |

BR-76 đáng nói vì cách suy luận nghe rất hợp lý: "trước và sau giống nhau thì là
relearning". Nó sai ở đúng một trường hợp và trường hợp đó không hiếm — một lượt
`scheduled` trên card ở box 8 trả lời `remembered` cũng có `previous_box == 8` và
`next_box == 8`. Suy luận sẽ gắn nhãn nó là `relearning` và mọi thống kê về sau
đều lệch.

BR-77 là rule quan trọng nhất của mục này. Không có nó, một card trả lời
`forgotten` rồi `remembered` ngay trong phiên sẽ nhảy lên box 2 và biến mất khỏi
lịch ngày mai — người dùng vừa quên nó xong đã được cho nghỉ hai ngày.

### BR-20 · Bộ đếm

**Status:** active · **Enforced by:** repository · **Related:** UC-05

| Cột | Quy tắc |
|---|---|
| `answer_count` | +1 mỗi lượt `scheduled` (không tính `relearning`) |
| `lapse_count` | +1 khi lượt `scheduled` có action `forgotten` hoặc `again` |
| `last_answered_at` | = thời điểm đánh giá, cập nhật ở cả hai loại lượt |

### BR-21 · Ghi study answers

**Status:** active · **Enforced by:** repository · **Related:** UC-05, AD-11

Mỗi lượt đánh giá — cả `scheduled` lẫn `relearning` — MUST ghi một dòng vào
`study_answers` gồm `card_id`, `session_id`, `scheduler_type`,
`scheduler_generation`, `kind`, `action`, `answered_at`, `next_due_at`, và
cặp trạng thái trước/sau của scheduler tương ứng.

Ghi cả lượt `relearning` là có chủ đích: nó là dữ liệu thật về việc người dùng
phải lặp mấy lần mới nhớ — thứ cần để đánh giá chất lượng thuật toán sau này.

## Phiên ôn tập

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-22 | active | Một phiên MUST chỉ lấy card có `due_at IS NULL OR due_at <= now`. | db | UC-05, UC-06 |
| BR-23 | active | Thứ tự MUST là: thẻ **đến hạn** (`due_at <= now`) trước, theo `due_at` tăng dần; thẻ **mới** (`due_at IS NULL`) lấp phần còn lại của hạn ngạch BR-24. | db | UC-05 |
| BR-24 | active | Một phiên MUST giới hạn 50 card riêng biệt. Không tính lượt `relearning`. | repository | UC-05 |
| BR-25 | active | Đánh giá MUST được ghi ngay khi người dùng bấm, không chờ hết phiên. | repository | UC-05 |
| BR-26 | active | Card đánh giá `forgotten`/`again` MUST quay lại trong phiên hiện tại, sau ít nhất 3 card khác, hoặc cuối hàng đợi nếu không đủ 3. Mỗi thẻ MUST tối đa **3 lượt `relearning`** trong một phiên; chạm trần thì thẻ rời hàng đợi. | repository | UC-05, BR-104 |
| BR-27 | active | Chỉ lượt `scheduled` MAY thay đổi lịch dài hạn; các lượt sau của cùng card trong cùng session MUST là `relearning`. Chi tiết ở BR-75…BR-78. | scheduler | UC-05, AD-11 |
| BR-28 | active | Card MUST rời hàng đợi khi được đánh giá bằng action khác `forgotten`/`again`. | controller | UC-05 |
| BR-29 | active | Không có card nào đến hạn MUST được trình bày là trạng thái bình thường, không phải lỗi. | UI | UC-05, UC-06 |
| BR-30 | active | UI MUST render nút đánh giá từ `supportedActions`, và chuỗi stage từ `stageSequence`, của scheduler thuộc root deck; MUST NOT hardcode tập nào trong hai. | UI | AD-06, UC-05, BR-97 |

## Vòng đời study session

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-79 | active | `study_sessions.status` MUST có đúng năm giá trị: `in_progress`, `completed`, `abandoned`, `invalidated`, `failed`. | db + invariant Q12 | AD-11, UC-05 |
| BR-80 | active | `study_sessions.end_reason` MUST có năm giá trị: `user_exit`, `scheduler_reset`, `stale_generation`, `persistence_error`, `interrupted`; NULL khi kết thúc bình thường hoặc chưa kết thúc. | db + invariant Q12 | AD-11, UC-05 |
| BR-81 | active | Hoàn thành toàn bộ queue MUST cho `completed`, `end_reason` NULL. | repository | UC-05 |
| BR-82 | active | Người dùng chủ động thoát MUST cho `abandoned`, `end_reason = user_exit`. | repository | UC-05 |
| BR-83 | active | Reset xảy ra khi session đang mở MUST cho `invalidated`, `end_reason = scheduler_reset`. | repository | UC-07 |
| BR-84 | active | Session thuộc generation cũ cố ghi lượt học MUST bị từ chối ghi, và MUST chuyển `invalidated`, `end_reason = stale_generation`. | repository | AD-09, UC-05 |
| BR-85 | active | Lỗi không thể tiếp tục MUST cho `failed`, `end_reason = persistence_error`. | repository | UC-05 |
| BR-86 | active | Các lượt học đã ghi thành công trước khi session kết thúc bất thường MUST được giữ, ở mọi trạng thái kết thúc. | repository | UC-05 |

BR-86 là điều phân biệt "session hỏng" với "mất tiến độ". Session chuyển sang
`failed` hay `invalidated` không được kéo theo việc xoá các lượt đã ghi xong —
người dùng đã bỏ công ôn 20 card thì 20 lượt đó là thật.

BR-84 chống một tình huống thật và dễ bỏ sót: người dùng mở phiên ôn, để đó, vào
Settings reset deck, rồi quay lại phiên cũ và bấm đánh giá. Không kiểm tra
generation thì kết quả đó ghi đè trạng thái vừa được làm mới.

## Starter deck (template)

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-31 | active | Starter deck MUST là template, không phải deck của người dùng; MUST NOT xuất hiện trong danh sách deck và MUST NOT ôn trực tiếp được. | domain | AD-07, UC-01 |
| BR-32 | active | Template MUST có `template_id` ổn định không đổi giữa các phiên bản app, kèm `version`, `locale`, `title`, `content_source`. | asset | AD-07 |
| BR-33 | active | Dùng một starter deck MUST tạo bản sao: root deck mới với ID riêng, cây deck con, toàn bộ card, và study state theo scheduler đã chọn. | repository | AD-07, UC-01 |
| BR-34 | active | Bản sao MUST ghi `source_template_id` và `source_template_version` tại thời điểm sao chép. Template chỉ MAY gợi ý scheduler qua `default_scheduler_type`. | repository | AD-07, UC-01 |
| BR-35 | active | Sau khi sao chép, bản sao MUST là deck bình thường; MUST NOT có liên kết ghi ngược về template. | domain | AD-07 |
| BR-36 | active | Nâng version template ở bản app mới MUST NOT ghi đè, sửa hay xoá bất kỳ bản sao nào đã tồn tại. | repository | AD-07, UC-01 |
| BR-37 | active | Tạo bản sao MUST idempotent theo `(source_template_id, source_template_version)`. | repository | AD-07, UC-01 |
| BR-38 | active | Người dùng cố ý thêm lại cùng một starter deck MAY được phép, nhưng MUST hỏi xác nhận nêu rõ đã tồn tại. | UI | UC-01 |
| BR-39 | active | Toàn bộ việc sao chép MUST nằm trong một transaction. | repository | AD-07, UC-01 |
| BR-87 | active | Nội dung starter hiện tại MUST được mô tả là fixture cho development và test; MUST NOT trình bày như nội dung production. | docs + UI | AD-07 |

BR-36 và BR-37 dễ nhầm là một. BR-36 chống ghi đè dữ liệu người dùng khi app cập
nhật; BR-37 chống tạo trùng khi mở lại app. Vi phạm BR-36 làm mất công sức người
dùng; vi phạm BR-37 làm bẩn danh sách deck. Cả hai chỉ lộ ra ở lần cập nhật thứ
hai, nên phải có test riêng cho từng cái.

BR-87 tồn tại vì dự án chưa có nguồn nội dung từ vựng có bản quyền rõ ràng.

## Reset learning progress và generation

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-40 | active | Mỗi root deck MUST có `scheduler_generation`, bắt đầu từ 1, +1 sau mỗi lần reset. | db | AD-09, UC-07 |
| BR-41 | active | Reset MUST giữ nguyên: deck, toàn bộ cây deck con, flashcard, media, tag và mọi nội dung. | repository | AD-09, UC-07 |
| BR-42 | active | Reset MUST xoá/đặt lại: active scheduler state của mọi card trong cây và mọi session đang dở. | repository | AD-09, UC-07 |
| BR-43 | active | Study answers cũ MUST được giữ lại, mang generation cũ, và MUST NOT được dùng cho chu kỳ mới. | repository | AD-09, UC-07 |
| BR-44 | active | Sau reset, `first_answered_at` MUST về NULL → scheduler mở khoá. Đây là cơ chế duy nhất để đổi scheduler sau lượt học đầu. | repository | AD-09, UC-07 |
| BR-45 | active | Card study state, study session và study answers MUST đều mang `scheduler_generation`. | db | AD-09 |
| BR-46 | active | MUST NOT chấp nhận kết quả từ session thuộc generation cũ; mọi thao tác ghi MUST so generation và từ chối nếu lệch. | repository | AD-09, UC-05 |
| BR-47 | active | Reset và đổi scheduler MUST chạy trong một Drift transaction duy nhất. | repository | AD-09, UC-07 |
| BR-48 | active | Bất biến 1: một cây deck MUST có đúng một active scheduler tại một thời điểm. | invariant Q9 | AD-09 |
| BR-49 | active | Bất biến 2: toàn bộ card state trong một cây MUST thuộc cùng một generation. | invariant Q9 | AD-09 |
| BR-50 | active | Reset MUST cần xác nhận, nêu rõ những gì mất và những gì giữ. | UI | UC-07 |

BR-47 quan trọng vì nửa vời ở đây nghĩa là một cây deck có card thuộc hai
generation, hoặc scheduler mới với card state theo luật cũ. Cả hai là dữ liệu
hỏng không tự phục hồi, tệ hơn nhiều so với reset thất bại sạch sẽ.

## Trạng thái hiển thị của thẻ

BR-88 đã định nghĩa nửa trên của thang này — "đã thuộc" — cho cả hai scheduler.
Ba rule dưới đây chia phần còn lại, và **không** phát biểu lại BR-88.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-89 | active | Trạng thái hiển thị của một thẻ MUST là một trong bốn: `new`, `beginning`, `reviewing`, `mastered`. Nó MUST được suy ra khi đọc và MUST NOT là cột trong DB. | domain | BR-88, UC-04 |
| BR-90 | active | Thẻ chưa có lượt `scheduled` nào (`answer_count = 0`) MUST là `new`, ở cả hai scheduler. | domain | BR-89, BR-20 |
| BR-91 | active | Với thẻ đã học và chưa "đã thuộc": interval hiện tại dưới 8 ngày MUST là `beginning`, từ 8 ngày trở lên MUST là `reviewing`. Với `eight_box` đó là box 1–3 và box 4–7; với `sm2` là `interval_days` < 8 và 8…127. | domain | BR-89, BR-16, BR-88 |

**Mốc 8 ngày không phải số mới.** Nó là interval của box 4 trong BR-16, và thang
đó là luỹ thừa của hai — 1, 2, 4, **8**, 16, 32, 64, 128 — nên box 1–3 là toàn bộ
phần dưới một tuần và box 4 là bước đầu tiên ra khỏi nhịp ôn ngắn. Dùng lại đúng
mốc đó cho `sm2` khiến `beginning` nghĩa là **cùng một khoảng cách thời gian** ở
cả hai scheduler, là chính lập luận BR-88 dùng khi chọn 128 thay vì 21.

Chọn một ngưỡng riêng cho `sm2` — 7 ngày, hay 30 — sẽ khiến hai deck cùng nhịp
ôn hiện hai nhãn khác nhau, và không có gì trong dữ liệu giải thích được vì sao.

**Bốn trạng thái là nhãn hiển thị, không phải state machine.** Không có chuyển
tiếp nào được định nghĩa giữa chúng và không có gì lưu chúng lại; chúng là một
phép đọc `card_study_states` tại thời điểm vẽ. Thẻ đi lùi từ `reviewing` về
`beginning` sau một lần quên là chuyện bình thường, không phải vi phạm.

## Cờ và tag

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-92 | active | Cờ đánh dấu thẻ MUST là nội dung: sửa thẻ và reset learning progress MUST NOT đụng tới nó; xoá thẻ MUST xoá nó theo cascade. Hệ thống MAY **bật** cờ (BR-104) nhưng MUST NOT tự tắt — bỏ dấu là hành động của người dùng. | db + repository | BR-10, BR-41, BR-104 |
| BR-93 | active | Tag MUST là nội dung, quan hệ nhiều-nhiều với thẻ. Tên tag MUST không rỗng sau trim, MUST tối đa 50 ký tự, và MUST là duy nhất không phân biệt hoa thường. | domain + db | BR-41, UC-04 |
| BR-94 | active | Một thẻ MUST mang tối đa 10 tag. | domain | BR-93 |

BR-92 và BR-93 nói cùng một điều mà BR-41 đã nói cho reset, nhưng ở chiều khác:
BR-41 nói reset giữ chúng lại, hai rule này nói *vì sao* — chúng thuộc nội dung,
cùng phía với `front`/`back`, chứ không thuộc lịch. Đó cũng là lý do cờ nằm trên
`cards` chứ không trên `card_study_states`.

BR-94 là một giới hạn của **giao diện** được nâng thành rule, và nó thừa nhận
điều đó: hàng thẻ vẽ tag thành một dãy chip, và một dãy không giới hạn sẽ tràn ở
320 với `textScaler` 2.0. Mười là con số đủ rộng để không ai gặp phải trong thực
tế và đủ hẹp để hàng thẻ có chiều cao đoán được.

## StudyMode

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-96 | superseded by BR-108 | StudyMode MUST là một trong năm: `review`, `match`, `guess`, `recall`, `fill`. | domain | UC-05, BR-30 |
| BR-108 | active | StudyMode MUST là một trong sáu: `browse`, `self_assess`, `match`, `guess`, `recall`, `fill`. | domain | UC-05, BR-30 |
| BR-109 | active | Một phiên MUST chạy một **chuỗi stage** theo thứ tự cố định do thuật toán khai báo, mỗi stage là một StudyMode. Người dùng MUST NOT chọn stage; hệ thống chuyển stage khi stage hiện tại đi hết hàng đợi của nó. | domain | BR-110, UC-05 |
| BR-110 | active | Chuỗi stage MUST là: `eight_box` → `browse`, `match`, `guess`, `recall`, `fill`; `sm2` → `browse`, `self_assess`. | scheduler | BR-97, BR-109 |
| BR-111 | active | `browse` MUST NOT sinh `action`, MUST NOT ghi `study_answers` và MUST NOT đổi lịch. Nó chỉ ghi tiến độ stage để Resume quay đúng chỗ. | domain | BR-106, BR-112 |
| BR-112 | active | `browse` MUST hiển thị mặt trước và mặt sau **cùng lúc**, không có bước lật. `self_assess` MUST hiện mặt trước trước, và chỉ hiện mặt sau cùng tập action sau khi người dùng lật. | UI | BR-108, UC-05 |
| BR-97 | active | Chuỗi stage MUST do **thuật toán SRS của root deck** khai báo qua `stageSequence` (BR-110). MUST NOT hardcode ở UI. | scheduler | BR-30, BR-110, AD-06 |
| BR-98 | active | Stage đang chạy MUST được lưu tường minh trên `study_sessions.current_mode`, và mode của từng lượt trên `study_answers.mode`. MUST NOT suy luận từ hình dạng dữ liệu. | db | BR-76, BR-109, AD-11 |
| BR-99 | active | Một stage MUST chạy chỉ khi thoả **cả hai**: nằm trong `stageSequence` của thuật toán, **và** phiên có ít nhất một thẻ đủ dữ liệu cho nó; stage không còn thẻ nào MUST bị bỏ qua thay vì hiện rỗng. | domain | BR-97, BR-114, UC-05 |
| BR-100 | active | Mode bị chặn vì thuật toán MUST được trình bày là không khả dụng cho deck này, và MUST NOT gợi ý Reset learning progress như cách mở khoá. | UI | BR-13, BR-41 |
| BR-106 | active | Mọi mode **trừ `browse`** MUST sinh một `action` thuộc `supportedActions` của thuật toán. `self_assess` MUST lấy action **trực tiếp từ người dùng**; `match`/`guess`/`recall`/`fill` MUST chấm ra kết quả nhị phân rồi ánh xạ theo BR-107. | domain | BR-15, BR-30, BR-111, AD-18 |
| BR-107 | active | Với `eight_box`, kết quả nhị phân MUST ánh xạ: sai → `forgotten`, đúng → `remembered`. Hết giờ ở `recall` MUST tính là sai. | domain | BR-15, BR-96 |

**Vì sao tập mode thuộc thuật toán chứ không thuộc deck.** Bốn mode ngoài
`review` sinh tín hiệu **nhị phân** — đúng hoặc sai. `eight_box` nhận đúng hai
action (`forgotten`/`remembered`) nên ánh xạ là một-một. `sm2` cần bốn mức, và
một nguồn nhị phân chỉ nuôi được hai trong bốn; ease factor sẽ trôi hẹp dần theo
BR-19 mà không có gì báo. Nên `sm2` giữ đúng `review`, và điều đó là **thuộc tính
của thuật toán**, không phải một hạn chế tạm thời của UI.

Hệ quả trực tiếp: `stageSequence` đứng cạnh `supportedActions` trên cùng
abstraction, vì cả hai trả lời cùng một câu hỏi — "thuật toán này cho phép người
dùng làm gì". BR-30 đã cấm hardcode tập action; BR-97 là đúng câu đó cho tập mode.

BR-100 tồn tại vì lối thoát duy nhất là có thật nhưng không được phép đề nghị:
thuật toán khoá sau lượt `scheduled` đầu tiên (BR-13) và chỉ Reset mới mở, mà
Reset xoá toàn bộ tiến độ học. Một dòng copy gợi ý điều đó đang đề nghị người
dùng đánh đổi thứ họ không định đánh đổi.

**BR-106 gỡ một mâu thuẫn nghe rất hợp lý.** `review` thường được mô tả là "không
có đúng/sai" — đúng, theo nghĩa **không có máy chấm**: người học tự đánh giá. Nhưng
nó vẫn sinh ra `forgotten`/`remembered`, và nếu đọc thành "không sinh action" thì
**không mode nào cập nhật lịch** và toàn bộ SRS biến mất cùng M3 của `product.md`.

Khác biệt thật giữa năm mode vì thế nằm gọn ở **nguồn** của action, không phải ở
việc có hay không có action — và đó cũng chính là toàn bộ phần mỗi handler phải
tự viết (AD-18). `review` không còn là ngoại lệ của luồng chung; nó là mode mà
`evaluate` trả về đúng cái người dùng vừa bấm.

**Chưa chốt, và cố ý để trống:** ngưỡng tối thiểu cụ thể của `match` và `recall`;
`guess` so "khác nghĩa" bằng đâu (`back_folded` có sẵn nhưng khác chuỗi ≠ khác
nghĩa); `fill` đếm eligibility theo số thẻ có `example` khác rỗng (BR-95), nên con
số của nó khác mọi mode còn lại; và một lượt của bốn mode mới ghi `kind` là gì.
Không đoán ở đây — mỗi câu trả lời khác nhau cho ra một thiết kế khác nhau.

---

## Phiên học — cách mở, cách giữ, cách đóng

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-101 | active | Một `study_session` MUST chỉ được tạo bởi hành động Study tường minh của người dùng. Hiển thị số đến hạn — badge, danh sách, thông báo — MUST NOT tạo session. | domain | UC-05, BR-29 |
| BR-102 | active | Hàng đợi MUST được lưu trong database và MUST bất biến trong suốt phiên: thay đổi deck sau khi phiên mở MUST NOT đổi hàng đợi đang chạy. | db | UC-05, BR-24, BR-113 |
| BR-113 | active | Mỗi stage MUST có hàng đợi riêng trên **cùng tập thẻ** của phiên, với thứ tự xoáo độc lập. Hai stage MUST NOT dùng chung một sequence khi phiên có từ hai thẻ trở lên. | db | BR-102, BR-109 |
| BR-114 | active | Thẻ không đủ dữ liệu cho một stage MUST bị bỏ qua **có ghi nhận** ở stage đó, MUST NOT bị xoá khỏi deck, và MUST vẫn xuất hiện ở các stage khác mà nó đủ dữ liệu. | repository | BR-99, BR-113 |
| BR-103 | active | Khi mở app còn session `in_progress` của **cùng ngày học**, hệ thống MUST cho phép tiếp tục phiên đó. Session `in_progress` của ngày học khác MUST chuyển `abandoned` với `end_reason = interrupted`. | repository | BR-80, BR-105 |
| BR-104 | active | Chạm trần 3 lượt `relearning` (BR-26) MUST cho thẻ rời hàng đợi, và MUST bật cờ đánh dấu của thẻ. MUST NOT tự tắt cờ. | repository | BR-26, BR-92 |
| BR-105 | active | `next_due_at` MUST rơi vào **00:00 giờ địa phương** của ngày thứ N, với N là interval do thuật toán trả về. Giá trị lưu vẫn là UTC. | domain | BR-16, BR-18, AD-16 |

BR-102 thay câu cũ trong `data-model.md` rằng hàng đợi là trạng thái tạm của
controller. Lý do đổi: hàng đợi mang **luật**, không chỉ mang thứ tự — thứ tự
BR-23, lượt quay lại BR-26, trần BR-104 — và một cấu trúc mang luật nằm trong
`presentation/` là chỗ luật đi ra khỏi tầm với của mọi phép kiểm. Đặt nó vào
database biến "snapshot bất biến" từ một lời hứa thành một ràng buộc, và cho phép
BR-103 tồn tại: một phiên sống sót qua việc app bị hệ điều hành thu hồi.

BR-105 sửa một chỗ trôi mà không ai thấy: `now + N*24h` đẩy mốc đến hạn muộn dần
theo giờ người dùng bấm. Học lúc 23:00 thì hôm sau 22:00 thẻ **chưa** tới hạn, và
mỗi phiên lại đẩy thêm — giờ học trôi dần về khuya cho tới khi người dùng hụt cả
một ngày. Neo vào đầu ngày lịch làm "đến hạn hôm nay" đúng nghĩa là hôm nay.

**Một thẻ đi qua nhiều stage chấm điểm, và BR-77 đã trả lời sẵn lượt nào đổi lịch.**
Lượt đầu tiên của một thẻ trong một phiên là `scheduled` và đổi lịch; mọi lượt sau là
`relearning`, ghi lịch sử nhưng không đổi lịch. Áp nguyên vào chuỗi stage thì **stage
chấm điểm đầu tiên quyết định lịch**, các stage sau chỉ để luyện. Không cần luật
mới, và `browse` không đếm vì nó không ghi lượt nào (BR-111).

**Đây là hệ quả được chấp nhận có ý thức, không phải điều đã được cân nhắc đủ.**
Sai ở Match rồi đúng cả ba stage sau vẫn cho lịch của một lần sai; đúng ở Match rồi
sai ba stage sau vẫn cho lịch của một lần đúng. Có hai hướng khác — stage cuối
quyết định, hoặc tổng hợp toàn chuỗi — và cả hai đều cần một luật mới. Giữ BR-77
vì nó nhất quán với phần còn lại của hệ thống, và ghi ra đây để lần xem lại không
phải tự phát hiện.

**Chưa chốt:** trần 50 thẻ/phiên (BR-24) áp cho mọi mode hay chỉ `review`; và
phiên có cho chọn scope hẹp hơn deck đang đứng hay không.

---

## Dữ liệu riêng tư

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-51 | active | Nội dung deck/card, ghi chú, lịch sử học, file import, hình ảnh, audio và dữ liệu backup MUST được coi là dữ liệu riêng tư. | — | AD-08 |
| BR-52 | active | MUST NOT log nội dung flashcard hoặc ghi chú ở bất kỳ log level nào. Log ID thì MAY. | logging | AD-08 |
| BR-53 | active | Media MUST lưu trong thư mục riêng của ứng dụng. | storage | AD-08 |
| BR-54 | active | Export và backup MUST chỉ chạy khi người dùng chủ động yêu cầu. | domain | AD-08 |

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Deck.name | không rỗng sau trim | "Tên deck không được để trống" | domain |
| Deck.name | ≤ 200 ký tự | "Tên deck tối đa 200 ký tự" | domain |
| Deck.schedulerType | bắt buộc chọn khi tạo root deck | "Hãy chọn chế độ ôn tập cho deck" | domain |
| Deck.move | đích không phải chính nó hoặc descendant | "Không thể di chuyển deck vào chính nó" | domain |
| Deck.move | đích cùng root scheduler và generation | "Deck đích dùng chế độ ôn tập khác. Hãy đặt lại tiến độ học trước khi di chuyển" | domain |
| Deck.create (sub-deck) | cấp của deck mới ≤ 10 (BR-55) | "Deck đã ở độ sâu tối đa (10 cấp)" | repository |
| Deck.move | cấp đích + chiều cao subtree nguồn ≤ 10 (BR-55) | "Di chuyển vào đây sẽ vượt độ sâu tối đa (10 cấp)" | repository |
| Card.front | không rỗng sau trim | "Mặt trước không được để trống" | domain |
| Card.back | không rỗng sau trim | "Mặt sau không được để trống" | domain |
| Card.front | ≤ 60 ký tự (BR-08) | "Mặt trước tối đa 60 ký tự" | domain |
| Card.back | ≤ 240 ký tự (BR-08) | "Mặt sau tối đa 240 ký tự" | domain |
| Card.example / hint / pronunciation | ≤ 240 ký tự (BR-95) | "Tối đa 240 ký tự" | domain |
| Tag.name | không rỗng sau trim (BR-93) | "Tên tag không được để trống" | domain |
| Tag.name | ≤ 50 ký tự (BR-93) | "Tên tag tối đa 50 ký tự" | domain |
| Tag.name | không trùng, không phân biệt hoa thường (BR-93) | "Tag này đã tồn tại" | domain + db |
| Card.tags | ≤ 10 tag mỗi thẻ (BR-94) | "Mỗi thẻ tối đa 10 tag" | domain |

Toàn bộ enforce ở domain vì chưa có server. Khi có backend, server validate lại —
client validation là trải nghiệm, không phải bảo mật.

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

**Chuyển đổi không hợp lệ:** `card` → `deck` và `deck` → `card` trực tiếp; tự
động về `unset` khi xoá hết nội dung (BR-67).

Root deck được tạo thẳng với `content_type = 'deck'` và giá trị đó bất biến — đó
là cách BR-58 trở thành ràng buộc kiểm tra được bằng cùng một câu query như mọi
deck khác.

### Card study state

Trạng thái suy ra từ `due_at`, không lưu cột riêng.

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
| bất kỳ | new | reset learning progress (BR-42) |

Reset là chuyển đổi duy nhất quay ngược về `new` — và nó đi kèm generation mới,
nên card sau reset không bị nhầm với card chưa từng ôn ở chu kỳ trước.

**Chuyển đổi không hợp lệ:** sửa nội dung card không đưa nó về `new` (BR-10);
lượt `relearning` không gây chuyển trạng thái nào (BR-78).

### Deck — trạng thái khoá scheduler

| Trạng thái | Điều kiện |
|---|---|
| `unlocked` | `first_answered_at IS NULL` |
| `locked` | `first_answered_at IS NOT NULL` |

| From | To | Trigger |
|---|---|---|
| unlocked | locked | lượt `scheduled` đầu tiên ở generation hiện tại (BR-13) |
| locked | unlocked | reset learning progress (BR-44) |

### Study session

| From | To | Trigger |
|---|---|---|
| in_progress | completed | hết queue (BR-81) |
| in_progress | abandoned | người dùng thoát (BR-82) |
| in_progress | invalidated | reset khi đang mở (BR-83), hoặc ghi từ generation cũ (BR-84) |
| in_progress | failed | lỗi không thể tiếp tục (BR-85) |

Trạng thái kết thúc là terminal — không có đường quay lại `in_progress`.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

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
| Tạo deck con dưới deck đang ở cấp 10 | Chặn trước khi ghi; parent giữ nguyên `content_type` (BR-55, BR-62) |
| Move khiến cấp sâu nhất sau move vượt 10 | Chặn; không đổi parent, root pointer hay `content_type` của đích (BR-55, BR-71) |
| Tạo root deck không chọn scheduler | Chặn, lỗi inline (BR-11) |
| Đổi scheduler khi chưa có lượt học | Cho phép, khởi tạo lại study state toàn cây (BR-14) |
| Đổi scheduler khi đã có lượt học | Chặn; đề nghị Reset learning progress (BR-13) |
| Mở phiên → reset ở màn khác → quay lại bấm đánh giá | Từ chối ghi; session → `invalidated`/`stale_generation` (BR-84) |
| Reset khi đang có phiên dở | Session → `invalidated`/`scheduler_reset` trong cùng transaction (BR-83, BR-47) |
| App bị kill giữa lúc reset | Transaction rollback; giữ nguyên generation và state cũ (BR-47) |
| Session lỗi ghi không thể tiếp tục | Session → `failed`/`persistence_error`; các lượt đã ghi vẫn giữ (BR-85, BR-86) |
| Card ở box 8 trả lời `remembered` trong lượt `scheduled` | Vẫn box 8, xếp lịch lại 128 ngày (BR-16). `kind` vẫn là `scheduled` dù box không đổi (BR-76) |
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
