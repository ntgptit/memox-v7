# Business rules — memox

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu mọi luật nghiệp vụ đúng bất kể UI, dưới một ID vĩnh viễn để code, test và tài liệu khác cùng trích dẫn |
| **Scope** | Luật nghiệp vụ, validation rule, state machine, edge case của phạm vi MVP. Ngoài phạm vi: quyết định kiến trúc (`architecture.md`), hình dạng dữ liệu (`data-model.md`), luồng người dùng (`use-cases.md`) |
| **Source of truth for** | BR-xx · validation rule · entity state machine · edge case |
| **Depends on** | `document-conventions.md`, `product.md`, `architecture.md` |
| **Updated by task** | M99.25 — BR-200…BR-202: Study Home (đọc thư viện thật, workload toàn subtree, ba trạng thái đã tải); M99.24 — BR-192…BR-199: tiến độ theo deck (phạm vi metric, card-day, hai khoảng, quy-về-vị-trí-hiện-tại, phân hoạch Learning/Reviewing, thứ tự, chỉ-đọc, cập nhật trực tiếp); trước đó M99.23 — BR-182…BR-191: Progress overview v1 |
| **Last updated** | 2026-08-15 |

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

Trạng thái hiện tại: **BR-01…BR-154**, không trùng, không thiếu.

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
| BR-67 | superseded by BR-163 | Xoá hết nội dung MUST NOT tự động đưa `content_type` về `unset`. | domain | AD-10, UC-04 |
| BR-68 | superseded by BR-163 | Đưa `content_type` về `unset` MUST là thao tác riêng, có xác nhận, và chỉ thực hiện được khi deck rỗng. | domain + UI | AD-10, UC-03 |
| BR-163 | active | Với mọi sub-deck, `content_type` MUST được hệ thống cập nhật **atomically trong cùng transaction với mutation direct children**: `unset` khi không còn direct child nào, `card` khi chứa direct card, `deck` khi chứa direct child deck. Root deck vẫn bất biến `deck` theo BR-58. Người dùng MUST NOT có thao tác reset `content_type` thủ công. Transaction thất bại MUST rollback cả mutation lẫn thay đổi `content_type`. | repository + invariant Q29 | AD-10, UC-03, UC-04, UC-08, UC-09 |
| BR-69 | active | Cây deck MUST NOT có cycle. | invariant Q8 | AD-10, UC-09 |
| BR-70 | active | MUST NOT di chuyển một deck vào chính nó hoặc vào descendant của nó. | domain | UC-09 |
| BR-71 | active | Di chuyển subtree MUST cập nhật `root_deck_id` cho toàn bộ subtree trong một transaction. | repository | AD-10, UC-09 |
| BR-72 | active | MUST NOT có descendant trỏ sai root. | invariant Q6 | AD-10, UC-09 |

**BR-67 và BR-68 bị BR-163 thay thế (M99.15).** Lập luận cũ — "quay về `unset`
tự động khiến cấu trúc đổi âm thầm" — giả định `content_type` là một lựa chọn của
người dùng. Nó không phải: BR-60 cấm chọn lúc tạo và BR-62 xác lập nó tự động từ
phần tử con đầu tiên. Nó là **metadata hệ thống tự duy trì** để cưỡng chế "một deck
chỉ chứa một loại" (BR-65), nên hướng ngược lại cũng phải tự động: create đã
đổi type atomically, còn delete/move thì không — bất đối xứng đó để lại deck rỗng
nhưng vẫn `card`/`deck`, một trạng thái người dùng không thoát ra được nếu không
biết tới một nút reset chôn trong action sheet. Reset thủ công vì thế là thao tác
quản trị không mua được giá trị nghiệp vụ nào, và BR-163 xóa nó.

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
| BR-12 | active | Scheduler, version và config MAY đổi trực tiếp chừng nào root deck chưa có lượt học nào ở generation hiện tại (`first_answered_at IS NULL`). Đây là thao tác **riêng**, MUST NOT đi qua Reset: `scheduler_generation` MUST giữ nguyên (UC-03). Điều kiện mở khoá MUST được đọc lại bên trong transaction ghi, không tin trạng thái màn hình. Chọn đúng scheduler deck đang chạy MUST là no-op: MUST NOT seed lại cây (BR-14) và MUST NOT đóng session đang mở (BR-164). | repository | AD-06, UC-03, BR-14, BR-164 |
| BR-13 | active | Sau khi thẻ đầu tiên **hoàn tất chuỗi học mới** (BR-144), scheduler, version và config MUST bị khoá. Việc khoá — đặt `first_answered_at` trên root — MUST xảy ra trong **cùng transaction** với chính lần hoàn tất đó, và MUST NOT ghi đè dấu của thẻ hoàn tất đầu tiên. Đổi MUST đi qua Reset learning progress (BR-44). | repository + invariant Q30 | AD-06, UC-03, UC-05, BR-144 |
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
ease_factor = <giá trị mới theo BR-19>      ← chạy TRƯỚC

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

**Thứ tự là một phần của luật, không phải chi tiết triển khai.** `ease_factor`
trong phép nhân MUST là giá trị **sau** khi BR-19 đã chạy cho chính lượt này —
không phải giá trị thẻ mang vào lượt. Hai cách đọc chỉ khác nhau ở những action
làm đổi hệ số: với `good` (q=4) hệ số không đổi nên không phân biệt được, còn
`hard` (q=3) hạ 2.5 xuống 2.36, và một thẻ đang ở interval 10 ngày nhận 24 ngày
theo luật này thay vì 25.

Bản đầu của tài liệu không nói thứ tự, nên M5.1 triển khai theo cách đọc sát chữ
— nhân với hệ số cũ — và chủ dự án chốt lại hướng ngược lại. Ghi thẳng vào đây
thay vì để trong commit message, vì đây đúng là loại mơ hồ mà người đọc kế tiếp
sẽ tự suy lại và suy khác.

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
| BR-75 | active | `study_answers` MUST có cột `kind` với đúng ba giá trị: `learning`, `scheduled` và `relearning`. | db | AD-11, BR-143 |
| BR-76 | active | `kind` MUST được lưu tường minh tại thời điểm ghi. MUST NOT suy luận bằng cách so sánh trạng thái trước và sau. | repository | AD-11 |
| BR-77 | active | **Chỉ áp cho phiên `reviewing`.** Lượt đầu tiên của một thẻ trong phiên đó MUST là `scheduled`. Chỉ lượt `scheduled` MAY cập nhật `current_box`, `ease_factor`, `interval_days` và `due_at`. Phiên `learning` MUST NOT sinh lượt `scheduled` nào (BR-144). | repository | UC-05, AD-11, BR-144 |
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
| `answer_count` | +1 mỗi lượt `scheduled` (không tính `learning` hay `relearning`) |
| `lapse_count` | +1 khi lượt `scheduled` có action `forgotten` hoặc `again` |
| `last_answered_at` | = thời điểm đánh giá, cập nhật ở **cả ba** loại lượt |

**`answer_count` bằng 0 sau khi học xong lần đầu là đúng, không phải lỗi.** Chuỗi
học mới không sinh lượt `scheduled` nào (BR-144), nên bộ đếm này chỉ bắt đầu chạy
từ phiên ôn tập đầu tiên. Nó đếm "đã được xếp lịch bao nhiêu lần", không đếm "đã
gặp bao nhiêu lần" — số thứ hai đọc từ `study_answers`. Vì thế BR-90 xác định thẻ
mới bằng `learned_at`, không bằng bộ đếm này.

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
| BR-22 | superseded by BR-142 | Một phiên MUST chỉ lấy card có `due_at IS NULL OR due_at <= now`. | db | UC-05, UC-06 |
| BR-23 | active | Trong một phiên **ôn tập**, thứ tự MUST theo `due_at` tăng dần. Trong phiên **học mới**, thứ tự MUST theo tùy chọn `new_card_order` (BR-148). Hai loại phiên MUST NOT trộn thẻ của nhau. | db | UC-05, BR-142 |
| BR-24 | active | Một phiên MUST giới hạn số **thẻ riêng biệt** theo `study_sessions.card_limit`, mặc định **20**, áp cho **cả hai loại phiên**. Đây là trần **mỗi lần lấy**, MUST NOT được hiểu là hạn mức ngày: số phiên trong một ngày không giới hạn. | repository | UC-05, BR-139 |
| BR-25 | active | Đánh giá MUST được ghi ngay khi người dùng bấm, không chờ hết phiên. | repository | UC-05 |
| BR-26 | active | **Chỉ áp cho mode `self_assess`, ở mọi loại phiên.** Card đánh giá `forgotten`/`again` MUST quay lại trong cùng hàng đợi, sau ít nhất 3 card khác, hoặc cuối hàng đợi nếu không đủ 3. `self_assess` MUST NOT dùng round. | repository | UC-05, BR-104, BR-115 |
| BR-27 | active | Chỉ lượt `scheduled` MAY thay đổi lịch dài hạn, và nó chỉ tồn tại trong phiên `reviewing`. Trong phiên `learning`, mọi lượt là `learning` hoặc `relearning` và không đổi lịch. Chi tiết ở BR-75…BR-78, BR-141…BR-144. | scheduler | UC-05, AD-11 |
| BR-28 | active | Ở stage có chấm điểm, card MUST rời hàng đợi khi được đánh giá bằng action khác `forgotten`/`again`. `browse` không sinh action (BR-111), nên thẻ rời hàng đợi của nó ngay khi đã được hiển thị và người dùng chuyển tiếp. | controller | UC-05, BR-111 |
| BR-29 | active | Không có thẻ nào đến hạn MUST được trình bày là trạng thái bình thường, không phải lỗi — và MUST NOT có đường nào mở phiên ôn tập khi tập đến hạn rỗng (BR-145). | UI | UC-05, UC-06, BR-145 |
| BR-30 | active | UI MUST render nút đánh giá từ `supportedActions`, và chuỗi stage từ `stageSequence`, của scheduler thuộc root deck; MUST NOT hardcode tập nào trong hai. | UI | AD-06, UC-05, BR-97 |

## Vòng đời study session

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-79 | active | `study_sessions.status` MUST có đúng năm giá trị: `in_progress`, `completed`, `abandoned`, `invalidated`, `failed`. | db + invariant Q12 | AD-11, UC-05 |
| BR-80 | active | `study_sessions.end_reason` MUST có năm giá trị: `user_exit`, `scheduler_reset`, `stale_generation`, `persistence_error`, `interrupted`; NULL khi kết thúc bình thường hoặc chưa kết thúc. | db + invariant Q12 | AD-11, UC-05 |
| BR-81 | active | Hoàn thành toàn bộ queue MUST cho `completed`, `end_reason` NULL. | repository | UC-05 |
| BR-82 | active | Người dùng chủ động thoát MUST cho `abandoned`, `end_reason = user_exit`. | repository | UC-05 |
| BR-83 | active | Reset xảy ra khi session đang mở MUST cho `invalidated`, `end_reason = scheduler_reset`. | repository | UC-07 |
| BR-164 | active | Đổi scheduler khi chưa khoá (BR-12) xảy ra lúc session đang mở MUST cho session đó `invalidated`, trong **cùng** transaction đổi scheduler. MUST NOT dùng `user_exit` — người dùng không thoát phiên — và MUST NOT để phiên cũ chạy tiếp: hàng đợi của nó được chia theo thuật toán cũ, còn generation không đổi nên chốt chặn BR-84 sẽ cho mọi lượt của nó đi qua. MUST NOT bắt người dùng chạy thêm một Reset thủ công để dọn. | repository | BR-12, BR-14, BR-83, UC-03 |
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
| BR-42 | active | Reset MUST xoá/đặt lại: active scheduler state của mọi card trong cây — **bao gồm `learned_at`** — và mọi session đang dở. Thẻ trở lại tập học mới và đi lại chuỗi (BR-142, BR-144). | repository | AD-09, UC-07, BR-152 |
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
| BR-90 | active | Thẻ **chưa học xong lần đầu** (`learned_at IS NULL`) MUST là `new`, ở cả hai thuật toán. MUST NOT suy từ `answer_count`, vì chuỗi học mới không sinh lượt `scheduled` nào (BR-144). | domain | BR-89, BR-20, BR-144 |
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
| BR-165 | active | Di chuyển thẻ MUST chỉ xảy ra giữa hai sub-deck **cùng một root**. Deck đích MUST NOT là root (BR-58), MUST có `content_type` là `unset` hoặc `card`, và MUST NOT là `deck` (BR-64). Deck đích MUST khác deck nguồn. Di chuyển **cross-root** MUST bị từ chối bằng một lý do có kiểu riêng, **kể cả khi hai root tình cờ cùng scheduler và cùng generation** — BR-73/BR-74 cấm chuyển đổi study state, và "tình cờ giống nhau" không phải một phép ánh xạ. Di chuyển MUST giữ nguyên: id thẻ, nội dung hai mặt và ba trường phụ, study state, toàn bộ review history, cờ, quan hệ tag và `created_at`. MUST chỉ ghi `deck_id` và `updated_at` của thẻ; MUST NOT đụng `scheduler_type`, `scheduler_generation` hay bất kỳ cột lịch nào. Nếu deck nguồn mất thẻ cuối, `content_type` của nó MUST về `unset`; nếu deck đích đang `unset`, nó MUST thành `card` — cả hai trong **cùng transaction** với việc dời thẻ (BR-163). | repository | AD-10, UC-04, BR-58, BR-64, BR-73, BR-74, BR-163 |
| BR-166 | active | Mọi mutation hàng loạt trên thẻ — di chuyển, xoá, đặt/bỏ cờ, gắn tag — MUST là **all-or-nothing trong đúng một transaction**: một thẻ vi phạm làm cả lô rollback, và MUST NOT có partial success không được đặc tả. Gắn tag hàng loạt MUST giữ nguyên quy tắc đơn lẻ: dùng lại tag theo tên đã fold (BR-93), trần 10 tag mỗi thẻ (BR-94), và **idempotent** khi thẻ đã có tag đó. Chỉ cần một thẻ chạm trần là cả lô bị từ chối. Đặt cờ hàng loạt MUST là lệnh tường minh `Set flagged` / `Remove flag`, MUST NOT là toggle suy ra từ thẻ đầu tiên. Xoá hàng loạt MUST cascade study state và history như xoá đơn lẻ, và MUST đưa deck về `unset` nếu đó là những thẻ cuối (BR-163). | repository | UC-04, BR-92, BR-93, BR-94, BR-163 |
| BR-167 | active | Chọn nhiều thẻ MUST áp dụng lên **toàn bộ tập kết quả** của deck hiện tại theo đúng filter và search term đang bật, MUST NOT chỉ giới hạn trong cửa sổ phân trang đã tải. "Select all" MUST đọc danh sách id qua cùng vị từ mà danh sách và các pill đếm dùng, MUST NOT tải nội dung thẻ chỉ để lấy id. Khi filter, search term, sort hoặc deck đổi, selection MUST bị xoá — một selection không nhìn thấy được là một mutation người dùng không đồng ý. Sau mutation thành công MUST xoá selection; khi thất bại MUST giữ selection và nêu lỗi, MUST NOT báo thành công. | UI + repository | UC-04, BR-166 |
| BR-168 | active | Deck đích của một lần import MUST thoả cùng điều kiện với việc tạo card đơn lẻ: là sub-deck có `content_type` `unset` hoặc `card`; root deck (BR-58) và deck đang giữ deck con (BR-64) MUST bị từ chối bằng lý do có kiểu. Điều kiện này MUST được kiểm tra lại **bên trong** transaction commit — deck có thể đã đổi loại hoặc biến mất giữa lúc preview và lúc ghi. | repository | UC-10, BR-58, BR-62, BR-64 |
| BR-169 | active | Mỗi hàng import MUST có cả `front` và `back` sau khi trim; hàng chỉ có một trong hai là invalid, hàng trống toàn bộ được bỏ qua không tính là lỗi. Validation nội dung MUST tái sử dụng đúng các rule hiện có — BR-07/BR-08 cho hai mặt, BR-95 cho ba trường phụ, BR-93/BR-94 cho tag — MUST NOT có bộ validation thứ hai trong parser hoặc UI. Tag trong một ô MUST tách bằng dấu chấm phẩy `;`, MUST NOT dùng dấu phẩy vì nó là delimiter phổ biến của CSV. `front` MUST NOT bị từ chối chỉ vì không chứa Hangul — từ vay mượn, chữ số và ký hiệu vẫn hợp lệ. | domain | UC-10, BR-07, BR-08, BR-93, BR-94, BR-95 |
| BR-170 | active | Trùng lặp khi import MUST đo bằng khoá `front_folded + back_folded`, trong hai phạm vi: card đang có trong **chính deck đích**, và các hàng lặp lại trong cùng nguồn import; card ở deck khác MUST NOT bị coi là trùng. Mặc định trùng lặp bị bỏ qua; người dùng MAY bật "Include duplicates". Import MUST NOT cập nhật hay gộp vào card hiện có — trùng thì hoặc bỏ hoặc tạo bản thứ hai, không có đường thứ ba. Kiểm tra trùng MUST chạy lại **bên trong** transaction commit theo policy đã chọn, vì database có thể đổi giữa preview và import. | domain + repository | UC-10, BR-171 |
| BR-171 | active | Một lần import MUST ghi trong **đúng một** Drift transaction: toàn bộ card, **đúng một** study state mới cho mỗi card theo bảng khởi tạo BR-09 với scheduler và generation đọc từ root **một lần trong transaction đó**, tag tạo mới hoặc dùng lại theo tên đã fold (BR-93), và `content_type` của deck đích. Một write thất bại MUST rollback toàn bộ — không có partial card, state, tag hay content type. Không còn hàng hợp lệ nào để ghi thì MUST NOT có mutation nào. Import MUST NOT mang theo lịch học: không due date, không box, không SM-2 state, không history — card import là card mới. | repository | UC-10, BR-09, BR-93, BR-166 |
| BR-172 | active | Deck đích đang `unset` MUST thành `card` trong cùng transaction với batch nếu có ít nhất một card được ghi (BR-62 áp cho lô); một lần import ghi zero card MUST NOT đổi `content_type`. | repository | UC-10, BR-62, BR-163 |
| BR-173 | active | Nội dung import là dữ liệu riêng tư cùng mức với nội dung card (BR-32): MUST NOT log nội dung card, văn bản đã dán, tên file hay hàng dữ liệu thô ở bất kỳ level nào — diagnostic chỉ MAY ghi format, số hàng, thời lượng và lỗi có kiểu. File MUST xử lý trong bộ nhớ ứng dụng, MUST NOT để lại bản sao ở thư mục dùng chung. V1 chỉ hỗ trợ UTF-8 và UTF-8 BOM; encoding khác MUST báo lỗi có hướng dẫn, MUST NOT đoán mò. | data + UI | UC-10, BR-32 |

BR-92 và BR-93 nói cùng một điều mà BR-41 đã nói cho reset, nhưng ở chiều khác:
BR-41 nói reset giữ chúng lại, hai rule này nói *vì sao* — chúng thuộc nội dung,
cùng phía với `front`/`back`, chứ không thuộc lịch. Đó cũng là lý do cờ nằm trên
`cards` chứ không trên `card_study_states`.

BR-94 là một giới hạn của **giao diện** được nâng thành rule, và nó thừa nhận
điều đó: hàng thẻ vẽ tag thành một dãy chip, và một dãy không giới hạn sẽ tràn ở
320 với `textScaler` 2.0. Mười là con số đủ rộng để không ai gặp phải trong thực
tế và đủ hẹp để hàng thẻ có chiều cao đoán được.

## Export card ra file

Nửa còn lại của Card Transfer (AD-20). Các rule dưới đây **không** phát biểu lại
validation nội dung (BR-07, BR-08, BR-95), luật tag (BR-93, BR-94) hay luật
riêng tư chung (BR-51…BR-54) — chúng chỉ nói phần mà chiều export thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-174 | active | Export MUST hỗ trợ đúng hai scope và MUST NOT có scope thứ ba ở v1. `all`: toàn bộ card **trực tiếp** của deck đang mở, độc lập với filter, search term, sort và pagination đang bật, MUST NOT gồm card của deck descendant. `selected`: đúng tập id đã materialize từ chế độ chọn (BR-167), id trùng MUST được normalize về một lần và MUST NOT nhân bản hàng trong file. Một id không còn tồn tại, hoặc không còn thuộc chính deck đó tại thời điểm đọc snapshot, MUST làm **cả request** thất bại bằng lý do có kiểu — MUST NOT export một phần im lặng. Scope rỗng (deck không còn card, hoặc tập chọn rỗng) MUST bị từ chối ở domain/repository kể cả khi UI đã ẩn action. | domain + repository | UC-11, AD-20, BR-167 |
| BR-175 | active | Artifact export MUST chỉ mang sáu field nội dung canonical của AD-20 — `front · back · example · hint · pronunciation · tags` — và MUST NOT mang bất cứ thứ gì khác: id card hay deck, timestamp, cờ (BR-92), scheduler type/version/generation, box, ease factor, interval, due date, `learned_at`, review history hay dữ liệu session. Đây là **content transfer, không phải backup**: import lại chính file này MUST sinh id và study state mới (BR-171). Rule này chi phối **dữ liệu thẻ và dữ liệu học ghi vào các ô của file**. Metadata do chính định dạng container sinh ra — cụ thể là timestamp của từng entry trong file zip mà XLSX là — nằm ngoài phạm vi: nó không dẫn xuất từ bất kỳ thẻ nào, không mô tả thẻ nào, và MUST NOT được đọc ngược thành dữ liệu. Hệ quả là hai lần export cùng một dữ liệu ra XLSX MAY khác nhau ở mức byte; điều phải giống nhau là nội dung logic, và đó là BR-177. | domain | UC-11, AD-20, BR-171, BR-177 |
| BR-176 | active | Ô `tags` MUST đi qua đúng **một** codec dùng chung cho cả Import và Export; MUST NOT có bản thứ hai trong encoder, decoder hay preview. Encode: các tag nối bằng `;` (BR-169); `;` bên trong một tag MUST escape thành `\;` và `\` MUST escape thành `\\`. Decode: backslash MUST chỉ được coi là escape khi đứng ngay trước `;` hoặc `\`; backslash trước ký tự khác và backslash ở cuối ô MUST giữ nguyên verbatim, vì nguồn legacy chưa từng escape. Round-trip export → import MUST giữ nguyên cả spelling lẫn tập tag. | domain | UC-11, UC-10, BR-93, BR-169 |
| BR-177 | active | Cùng một dữ liệu MUST cho ra cùng một artifact **về mặt nội dung logic**: cùng tập record, cùng thứ tự record, cùng thứ tự tag trong mỗi record, và cùng giá trị từng ô. Determinism này MUST NOT được hiểu là byte-identical — container của XLSX ghi timestamp riêng của nó vào từng zip entry (BR-175), nên hai file byte khác nhau vẫn thoả rule khi giải mã ra cùng nội dung. Card MUST sắp theo `created_at ASC` với tie-break `id ASC`, **áp cho cả hai scope**; scope `selected` MUST NOT theo thứ tự người dùng chạm. Tag của mỗi card MUST sắp theo tên đã fold (BR-93) với tie-break ổn định. Tên deck, nội dung card và tag MUST đến từ **một snapshot nhất quán**, MUST NOT ghép từ nhiều lần đọc rời nhau và MUST NOT đọc tag theo kiểu N+1. | repository | UC-11, BR-93 |
| BR-178 | active | Export MUST là thao tác chỉ-đọc: MUST NOT ghi hay chạm tới nội dung card, `updated_at` hay bất kỳ timestamp nào, `content_type` của deck (BR-163), study state, review history, session, cờ hay quan hệ tag. Export thành công MUST NOT xoá selection hiện tại — BR-167 chỉ bắt xoá selection sau một **mutation** thành công, và export không phải mutation. | repository + UI | UC-11, BR-163, BR-167 |
| BR-179 | active | Mọi file export MUST mở đầu bằng đúng sáu header canonical theo thứ tự của AD-20, chữ thường tiếng Anh, và MUST NOT localize theo ngôn ngữ app. Field tuỳ chọn không có giá trị MUST là ô rỗng, MUST NOT là `null`, `-` hay chuỗi placeholder. CSV và TSV MUST ghi kèm UTF-8 BOM — đối xứng với encoding mà Import chấp nhận (BR-173). XLSX MUST ghi mọi ô dưới dạng **text**, nên nội dung bắt đầu bằng `=`, `+`, `-` hoặc `@` MUST NOT trở thành formula, và chuỗi trông như số (`001`, `1e3`, `+84…`) MUST giữ nguyên nguyên văn. | data | UC-11, AD-20, BR-173 |
| BR-180 | active | Tên file export MUST dẫn xuất từ tên deck đã sanitize — loại ký tự phân cách đường dẫn, ký tự điều khiển và ký tự không hợp lệ của hệ tệp, gộp khoảng trắng liên tiếp thành một, trim hai đầu — cộng một ngày lấy từ `clockProvider` và phần mở rộng theo format đã chọn. Sanitize ra chuỗi rỗng thì phần tên MUST fallback về `cards`. MUST NOT gọi `DateTime.now()` ở bất kỳ layer nào, và tên file MUST NOT xuất hiện trong log ở bất kỳ level nào (BR-173). | domain | UC-11, BR-173 |
| BR-181 | active | File export là dữ liệu riêng tư cùng mức nội dung card (BR-51, BR-52) và MUST chỉ được tạo khi người dùng chủ động yêu cầu (BR-54). Ứng dụng MUST NOT xin quyền truy cập bộ nhớ diện rộng, và MUST NOT ghi artifact vào thư mục dùng chung trước một hành động tường minh của người dùng; bản tạm MUST nằm trong vùng riêng của ứng dụng và là transient. Bàn giao file MUST đi qua share sheet của hệ điều hành. Người dùng đóng share sheet MUST được hiểu là **cancel**, MUST NOT báo lỗi. UI MUST NOT nói file đã được lưu khi hệ điều hành không xác nhận điều đó — copy trung thực nói "đã bàn giao cho hệ thống", không nói "đã lưu". | data + UI | UC-11, BR-51, BR-52, BR-54, BR-173 |

## Tiến độ theo deck

Drill-down hoạt động học theo cây deck (UC-12). Các rule dưới đây **không** phát
biểu lại định nghĩa ngày địa phương (BR-105), quan hệ cha–con và `root_deck_id`
(BR-55…BR-57), tính append-only của `study_answers` (BR-43) hay luật riêng tư
chung (BR-51…BR-54) — chúng chỉ nói phần mà chiều đọc tiến độ thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-182 | active | Progress by Deck v1 MUST chỉ báo cáo đúng bốn số cho mỗi phạm vi: **unique active cards**, **active days**, **Learning card-days** và **Reviewing card-days** (BR-183, BR-186). v1 MUST NOT báo cáo accuracy, điểm số, streak dài nhất, dự báo due, so sánh giữa hai khoảng, hay bất kỳ số dẫn xuất nào khác — mỗi số đó cần một định nghĩa riêng phải chốt trước, và một màn hình chứa năm số nửa-đồng-thuận thì không số nào đáng tin. Màn hình MUST là read-only (BR-188). | domain | UC-12, BR-183, BR-186, BR-188 |
| BR-183 | active | Đơn vị đếm MUST là **card-day**: một cặp phân biệt `(card, ngày địa phương)` theo đúng định nghĩa ngày của BR-105, MUST NOT là số lượt trả lời. Trả lời cùng một thẻ sáu lần trong một buổi tối MUST đếm là **một** card-day. `unique active cards` MUST là số card phân biệt có ít nhất một lượt trong khoảng; `active days` MUST là số ngày địa phương phân biệt có ít nhất một lượt trong khoảng. Hai số này đo hai thứ khác nhau và MUST NOT cộng vào nhau. `active days` MUST NOT được tính bằng cách cộng các deck con: cùng một ngày xuất hiện ở hai deck vẫn là một ngày học, nên mọi tổng MUST đọc trực tiếp từ cùng một câu lệnh chứ không fold từ các hàng. | domain + repository | UC-12, BR-105 |
| BR-184 | active | v1 MUST có đúng hai khoảng — **7 ngày** và **30 ngày** — và MUST NOT có khoảng thứ ba hay date picker tự do. Mỗi khoảng MUST gồm trọn các ngày địa phương **kết thúc bằng hôm nay**: 7 ngày là hôm nay cộng sáu ngày trước đó. Biên MUST dẫn xuất từ `clockProvider` và offset múi giờ do composition root cấp (AD-16), MUST NOT đọc đồng hồ hay múi giờ trong SQL hay trong `domain/`. Hai khoảng MUST đến từ **một** lần đọc, nên đổi khoảng trên màn hình MUST NOT mở lại query và MUST NOT hiện trạng thái loading. Snapshot MUST mang theo thời điểm nó hết hạn — nửa đêm địa phương kế tiếp — vì mọi số của nó đổi tại đó mà không có write nào trong database. | domain + repository | UC-12, BR-105, AD-16 |
| BR-185 | active | Lịch sử MUST được quy cho **vị trí hiện tại của thẻ**: đường đi `study_answers → cards → decks`. Chuyển một thẻ hoặc một subtree sang deck khác MUST làm **toàn bộ** lịch sử của thẻ xuất hiện dưới deck và root mới, không chỉ các lượt sau khi chuyển. `study_answers` MUST NOT nhận thêm cột deck lịch sử và hệ thống MUST NOT thêm bảng analytics riêng để né rule này; hệ quả được chấp nhận là "tháng Ba deck này trông thế nào" không trả lời được và không thuộc v1. Tổng của một deck MUST gồm thẻ trực tiếp của nó và mọi descendant theo cây thật — root resolve qua `root_deck_id`, cấp trung gian resolve bằng recursive walk, MUST NOT dùng `COALESCE(parent_deck_id, id)` (BR-57). Deck đã xoá MUST biến mất khỏi mọi số, và điều đó MUST đến từ cascade của schema chứ không từ một predicate lọc; khi một cơ chế Trash tồn tại thì deck trong Trash và mọi descendant của nó MUST bị loại theo cùng cách, restore MUST làm activity xuất hiện lại theo vị trí hiện tại của thẻ, và purge vĩnh viễn MUST loại nó vĩnh viễn. | repository | UC-12, BR-55, BR-56, BR-57, BR-71 |
| BR-186 | active | Learning và Reviewing MUST là một phân hoạch **loại trừ và vét cạn** của card-days: mỗi card-day MUST thuộc đúng một nửa, nên `Learning + Reviewing` MUST bằng tổng card-days. Ưu tiên thuộc về Learning: một ngày có ít nhất một lượt `kind = 'learning'` MUST là Learning day dù ngày đó còn lượt nào khác; mọi ngày còn lại — `scheduled` và `relearning` — MUST là Reviewing day. Phân loại MUST đọc cột `kind` đã lưu (BR-76), MUST NOT suy ra bằng cách so sánh trạng thái trước/sau. | domain + repository | UC-12, BR-76, BR-142 |
| BR-187 | active | Danh sách deck MUST sắp theo `unique active cards` **giảm dần của khoảng đang chọn**, tie-break bằng tên đã fold rồi tới id, để thứ tự ổn định qua mọi lần đọc. Fold MUST làm trong Dart bằng `toLowerCase()` Unicode, MUST NOT dùng `lower()` của SQLite (chỉ fold ASCII, nên `Động` và `động` tách nhau trong khi `Verbs` và `verbs` gộp). Deck không có hoạt động MUST vẫn hiển thị và MUST đứng cuối — ẩn chúng đi là trả lời câu hỏi "mình đã bỏ bê deck nào" bằng cách xoá chính câu trả lời. | domain | UC-12, BR-93 |
| BR-188 | active | Đọc tiến độ MUST là thao tác chỉ-đọc: mở, rời hay đổi khoảng trên màn hình MUST NOT ghi hay chạm tới nội dung card, timestamp, `content_type`, study state, review history, session hay quan hệ tag; MUST NOT mở hay đóng session nào. Một lần đọc thất bại vì thế MUST NOT làm hỏng dữ liệu, và copy lỗi MUST NOT gợi ý ngược lại. | repository + UI | UC-12, BR-178 |
| BR-189 | active | Màn hình MUST cập nhật trực tiếp: ghi một lượt trả lời, chuyển thẻ hoặc subtree, xoá deck, và nửa đêm địa phương đi qua MUST đều làm số trên màn hình đổi mà người dùng không phải thao tác gì. Ba sự kiện đầu MUST đến từ stream invalidation của các bảng liên quan; sự kiện thứ tư không có write nào trong database nên MUST đến từ một lần hẹn giờ duy nhất, đặt theo thời điểm hết hạn mà chính snapshot mang theo (BR-184). | repository + presentation | UC-12, BR-184 |

## StudyMode

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-96 | superseded by BR-108 | StudyMode MUST là một trong năm: `review`, `match`, `guess`, `recall`, `fill`. | domain | UC-05, BR-30 |
| BR-108 | active | StudyMode MUST là một trong sáu: `browse`, `self_assess`, `match`, `guess`, `recall`, `fill`. | domain | UC-05, BR-30 |
| BR-109 | active | Phiên **học mới** MUST chạy một **chuỗi stage** theo thứ tự cố định do thuật toán khai báo; người dùng MUST NOT chọn stage. Phiên **ôn tập** MUST chạy đúng **một** mode do người dùng chọn (BR-146). | domain | BR-110, BR-142, UC-05 |
| BR-110 | active | Chuỗi stage của phiên học mới MUST là: `eight_box` → `browse`, `match`, `guess`, `recall`, `fill`; `sm2` → `browse`, `self_assess`. | scheduler | BR-97, BR-109 |
| BR-111 | active | `browse` MUST NOT sinh `action`, MUST NOT ghi `study_answers` và MUST NOT đổi lịch. Nó chỉ ghi tiến độ stage để Resume quay đúng chỗ. | domain | BR-106, BR-112 |
| BR-112 | active | `browse` MUST hiển thị mặt trước và mặt sau **cùng lúc**, không có bước lật. `self_assess` MUST hiện mặt trước trước, và chỉ hiện mặt sau cùng tập action sau khi người dùng lật. | UI | BR-108, UC-05 |
| BR-97 | active | Chuỗi stage MUST do **thuật toán SRS của root deck** khai báo qua `stageSequence` (BR-110). MUST NOT hardcode ở UI. | scheduler | BR-30, BR-110, AD-06 |
| BR-98 | active | Stage đang chạy MUST được lưu tường minh trên `study_sessions.current_mode`, và mode của từng lượt trên `study_answers.mode`. MUST NOT suy luận từ hình dạng dữ liệu. | db | BR-76, BR-109, AD-11 |
| BR-99 | active | Trong phiên `learning`, một stage MUST chạy chỉ khi nằm trong `stageSequence` **và** có ít nhất một thẻ đủ dữ liệu; stage không còn thẻ nào MUST bị bỏ qua thay vì hiện rỗng. Trong phiên `reviewing`, không có stage nào để bỏ qua vì người dùng đã chọn: mode không đủ dữ liệu MUST bị **vô hiệu hoá ngay trên màn chọn**, kèm lý do. | domain + UI | BR-97, BR-114, BR-146, UC-05 |
| BR-100 | active | Mode bị chặn vì thuật toán MUST được trình bày là không khả dụng cho deck này, và MUST NOT gợi ý Reset learning progress như cách mở khoá. | UI | BR-13, BR-41 |
| BR-106 | active | Mọi mode **trừ `browse`** MUST sinh một `action` thuộc `supportedActions` của thuật toán. `self_assess` MUST lấy action **trực tiếp từ người dùng**; `match`/`guess`/`recall`/`fill` MUST chấm ra kết quả nhị phân rồi ánh xạ theo BR-107. | domain | BR-15, BR-30, BR-111, AD-18 |
| BR-107 | active | Với `eight_box`, kết quả nhị phân MUST ánh xạ: sai → `forgotten`, đúng → `remembered`. Hết giờ ở `recall` MUST tính là sai. | domain | BR-15, BR-108 |

**Vì sao tập mode thuộc thuật toán chứ không thuộc deck.** Bốn mode chấm điểm
sinh tín hiệu **nhị phân** — đúng hoặc sai. `eight_box` nhận đúng hai
action (`forgotten`/`remembered`) nên ánh xạ là một-một. `sm2` cần bốn mức, và
một nguồn nhị phân chỉ nuôi được hai trong bốn; ease factor sẽ trôi hẹp dần theo
BR-19 mà không có gì báo. Nên `sm2` giữ đúng `self_assess`, và điều đó là **thuộc tính
của thuật toán**, không phải một hạn chế tạm thời của UI.

Hệ quả trực tiếp: `stageSequence` đứng cạnh `supportedActions` trên cùng
abstraction, vì cả hai trả lời cùng một câu hỏi — "thuật toán này cho phép người
dùng làm gì". BR-30 đã cấm hardcode tập action; BR-97 là đúng câu đó cho tập mode.

BR-100 tồn tại vì lối thoát duy nhất là có thật nhưng không được phép đề nghị:
thuật toán khoá sau lượt `scheduled` đầu tiên (BR-13) và chỉ Reset mới mở, mà
Reset xoá toàn bộ tiến độ học. Một dòng copy gợi ý điều đó đang đề nghị người
dùng đánh đổi thứ họ không định đánh đổi.

**BR-106 gỡ một mâu thuẫn nghe rất hợp lý.** `self_assess` thường được mô tả là "không
có đúng/sai" — đúng, theo nghĩa **không có máy chấm**: người học tự đánh giá. Nhưng
nó vẫn sinh ra `forgotten`/`remembered`, và nếu đọc thành "không sinh action" thì
**không mode nào cập nhật lịch** và toàn bộ SRS biến mất cùng M3 của `product.md`.

Khác biệt thật giữa các mode vì thế nằm gọn ở **nguồn** của action, không phải ở
việc có hay không có action — và đó cũng chính là toàn bộ phần mỗi handler phải
tự viết (AD-18). `self_assess` không còn là ngoại lệ của luồng chung; nó là mode mà
`evaluate` trả về đúng cái người dùng vừa bấm.

**Không còn mục nào để trống.** Câu cuối cùng — lượt nào trong chuỗi stage đổi
lịch — được BR-141 trả lời, và câu trả lời đã nằm sẵn trong cơ chế round.

**Vì sao BR-77 vẫn đúng dù nó được viết cho một phiên một cách hỏi.** BR-119 bắt
mỗi stage lặp cho tới khi một round không còn thẻ sai, nên **lượt cuối của mọi
stage luôn là một lần đúng** — nó không mang tín hiệu nào về trí nhớ, chỉ nói rằng
vòng lặp đã kết thúc. Thứ duy nhất cho biết người học có thực sự nhớ hay không là
**lần thử đầu tiên**, khi chưa có stage nào nhắc bài. Lấy kết quả cuối chuỗi sẽ
cho mọi thẻ đều "nhớ được", và SRS mất sạch tín hiệu.

Ngưỡng riêng theo stage đã đóng ở BR-139: không có. Năm stage chạy trên **một**
tập thẻ của phiên, và BR-140 tách bạch điều đó với điều kiện dựng được nội dung —
`guess` cần năm nghĩa khác nhau, `fill` cần thẻ có `example`. Hai thứ đó quyết
định stage **có chạy hay bị bỏ qua**, không quyết định lấy bao nhiêu thẻ.
Không đoán ở đây — mỗi câu trả lời khác nhau cho ra một thiết kế khác nhau.

Hai mục từng nằm trong danh sách này đã đóng: `guess` so "khác nghĩa" bằng
`back_folded` (BR-123), và ngưỡng của chính `guess` là **năm nghĩa khác nhau
trong tập thẻ của phiên** (BR-121, BR-124). Ngưỡng đó khác `match` và `recall` ở
một điểm đáng chú ý: nó là điều kiện của **cả stage**, không phải của từng thẻ,
vì một question mượn bốn thẻ khác để dựng.

---

## Phiên học — cách mở, cách giữ, cách đóng

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-101 | active | Một `study_session` MUST chỉ được tạo bởi hành động Study tường minh của người dùng. Hiển thị số đến hạn — badge, danh sách, thông báo — MUST NOT tạo session. | domain | UC-05, BR-29 |
| BR-102 | active | Hàng đợi MUST được lưu trong database và MUST bất biến trong suốt phiên: thay đổi deck sau khi phiên mở MUST NOT đổi hàng đợi đang chạy. | db | UC-05, BR-24, BR-113 |
| BR-113 | active | Mỗi stage MUST có hàng đợi riêng trên **cùng tập thẻ** của phiên, với thứ tự xoáo độc lập. Phiên `reviewing` chỉ có một mode nên chỉ có một hàng đợi. Hai stage MUST NOT dùng chung một sequence khi phiên có từ hai thẻ trở lên. | db | BR-102, BR-109 |
| BR-141 | active | Trong phiên **học mới**, mọi lượt MUST là `learning` hoặc `relearning` và MUST NOT đổi lịch (BR-144). Trong phiên **ôn tập**, lượt đầu tiên của mỗi thẻ là `scheduled` và đổi lịch; mọi lượt lặp sau đó là `relearning`. | repository | BR-77, BR-115, BR-144 |
| BR-139 | active | Số thẻ của một phiên MUST được chốt **một lần lúc mở phiên** từ tùy chọn hiệu lực (BR-147) và lưu vào `study_sessions.card_limit`. Đổi tùy chọn sau đó MUST NOT ảnh hưởng phiên đang chạy. | db | BR-24, BR-147 |
| BR-140 | active | Điều kiện **dựng được nội dung** của một stage (BR-114, BR-121, BR-124) MUST NOT được hiểu là ngưỡng thẻ của stage đó. Chúng quyết định stage có chạy được hay bị bỏ qua, không quyết định lấy bao nhiêu thẻ. | domain | BR-99, BR-139 |
| BR-134 | active | `fill` MUST hiển thị **mặt sau** của thẻ làm đề bài và MUST yêu cầu người học gõ **mặt trước**: theo BR-08, `front` giữ term (tiếng Hàn) và `back` giữ nghĩa. Việc chấm MUST so dạng **đã fold** của câu trả lời với `front_folded` của thẻ — trim hai đầu và hạ hoa Unicode-aware — và khi sai, đáp án hiển thị MUST là `front`. Chính sách này **giữ nguyên dấu** — `cong` MUST NOT khớp `công`. | domain | BR-08, BR-123, BR-135 |
| BR-135 | active | Mỗi lượt `fill` MUST lưu phiên bản chính sách so khớp đã dùng. Đổi chính sách MUST tăng phiên bản, MUST NOT sửa lại các lượt cũ. | db | BR-134, AD-11 |
| BR-136 | active | Việc dùng gợi ý MUST được ghi trên lượt, và MUST NOT tự đổi `action` hay lịch. | db | BR-106, BR-95 |
| BR-137 | active | Câu trả lời rỗng sau khi trim MUST NOT sinh lượt và MUST NOT tiến checkpoint. | domain | BR-25, BR-134 |
| BR-138 | active | Nội dung người dùng gõ ở `fill` MUST NOT được lưu. Chỉ kết cục, phiên bản chính sách và cờ dùng gợi ý được ghi. | db | BR-51, BR-52, BR-54 |
| BR-128 | active | `recall` MUST cho tối đa **20 giây** mỗi lượt, đo bằng thời gian tương tác thực: MUST tạm dừng khi app vào nền hoặc bị ngắt, và MUST NOT tính thời gian tải nội dung. | domain + UI | AD-13, AD-16 |
| BR-129 | active | Một lượt `recall` MUST ghi **tối đa một** đáp án. Tại mốc hết giờ MUST chỉ một nhánh thắng: thao tác có thời điểm **trước** mốc là reveal thủ công (không ghi gì — BR-159); tại hoặc sau mốc là hết giờ (ghi sai — BR-160). MUST NOT vừa vào tự đánh giá vừa ghi hết giờ. | domain + UI | BR-25, BR-128, BR-159, BR-160 |
| BR-130 | active | Hết giờ MUST khoá kết cục thành sai và MUST tự lật đáp án **sau khi** ghi đã commit (BR-157). Trong cùng lượt đó MUST NOT đổi được sang đúng, kể cả khi ghi thất bại — retry MUST gửi lại đúng kết quả sai đó và MUST NOT mở lại lựa chọn của người học. | domain + UI | BR-107, BR-129, BR-157 |
| BR-131 | active | Lý do "hết giờ" MUST được lưu tường minh trên `study_answers.outcome_reason`. MUST NOT suy luận từ `action`, vì tự nhận quên và hết giờ cho cùng một `action`. | db | BR-76, BR-130 |
| BR-132 | active | Nhãn trên màn hình (ví dụ Remembered / Forgot) MUST NOT được lưu. Chỉ `action` canonical vào `study_answers`. | db + UI | BR-106, BR-120 |
| BR-133 | active | Thời gian còn lại và trạng thái đã lật MUST được lưu để Resume tiếp tục đúng chỗ, MUST NOT đặt lại 20 giây. Lượt Resume với `is_revealed = true` và còn thời gian MUST quay lại **tự đánh giá** với đáp án đang hiện và đồng hồ đã dừng, MUST NOT chạy lại đồng hồ. Một lượt mới của thẻ ở round sau là lượt khác và MUST bắt đầu lại đủ 20 giây với đáp án ẩn. | db + UI | BR-103, BR-115, BR-128, BR-159 |
| BR-121 | active | Mỗi question của `guess` MUST có **đúng năm** lựa chọn: một đáp án đúng xuất hiện đúng một lần, và bốn distractor. MUST NOT render số lượng khác. | domain + UI | BR-99, BR-122 |
| BR-122 | active | Distractor MUST lấy từ thẻ **đã học xong** (`learned_at IS NOT NULL`) **hoặc đang trong phiên hiện tại**, trong cùng cây deck. Mỗi distractor MUST tham chiếu một thẻ khác thẻ đang hỏi. | domain | BR-115, BR-121, BR-142 |
| BR-123 | active | "Hai nghĩa khác nhau" MUST đo bằng `back_folded` (schema v3), không bằng chuỗi hiển thị. Hai thẻ cùng `back_folded` MUST NOT cùng xuất hiện trong một option set. | domain | BR-121, BR-122 |
| BR-124 | active | Phân biệt hai ca: tập thẻ của phiên **không đủ năm nghĩa khác nhau** thì stage `guess` MUST bị bỏ qua theo BR-99, không phải lỗi. Đủ năm nhưng một question vẫn không dựng được thì MUST chặn: không render, không ghi lượt, không bỏ qua thẻ, không tiến checkpoint. | domain | BR-99, BR-114, BR-121 |
| BR-125 | active | Đánh giá lựa chọn MUST so bằng định danh, MUST NOT so bằng chuỗi hiển thị. | domain | BR-121 |
| BR-126 | active | Mỗi question MUST chỉ nhận **lựa chọn đầu tiên** và sinh tối đa một lượt. Chạm lặp MUST NOT sinh lượt thứ hai. | domain | BR-25, BR-121 |
| BR-127 | active | Thứ tự thẻ trong round và thứ tự năm lựa chọn MUST là hai hoán vị độc lập: đổi cái này MUST NOT đổi cái kia. Cả hai MUST ổn định khi Resume. | db + domain | BR-117 |
| BR-154 | active | Màn chọn mode ôn tập MUST hiện số thẻ **của từng mode**, không dùng chung một số: `fill` chỉ nhận thẻ có `example`, nên một phiên 20 thẻ có thể chỉ ôn được 3 bằng mode đó. | UI | BR-114, BR-146, BR-99 |
| BR-153 | active | `match` MUST có ít nhất **hai** cặp trên bàn. Một cặp duy nhất làm đáp án hiển nhiên, nên stage MUST bị bỏ qua (phiên `learning`) hoặc vô hiệu hoá trên màn chọn (phiên `reviewing`) theo BR-99. | domain + UI | BR-99, BR-115 |
| BR-150 | active | Badge trên danh sách deck MUST hiện **hai số** theo đúng hai tập của BR-142: số thẻ chưa học và số thẻ đến hạn ôn. MUST NOT gộp thành một số — hai tập có chi phí rất khác nhau. | UI | BR-142, BR-90 |
| BR-151 | active | Pill lọc trên danh sách thẻ MUST dùng cùng định nghĩa: **New** = `learned_at IS NULL` (BR-90); **Due** = `learned_at IS NOT NULL AND due_at <= now`. Hai tập MUST rời nhau. | UI + db | BR-90, BR-142 |
| BR-155 | active | Chỉ stage `browse` MUST cho xem lại thẻ đã qua trong cùng round, bằng vuốt hoặc bằng một control tương đương. Đây là **xem, không phải trả lời**: thẻ MUST giữ nguyên `completed`, `study_sessions.cursor` MUST NOT lùi, và tiến lại qua thẻ đó MUST NOT ghi lượt thứ hai hay tăng `cursor` lần hai. Các stage khác MUST NOT có thao tác này. | UI + domain | BR-111, BR-25, BR-126 |
| BR-156 | active | `match` MUST bày **tối đa năm cặp** một lúc. Một round MUST được chia thành các bàn liên tiếp theo thứ tự `position` của round đó (BR-117); bàn cuối lấy phần dư và **MAY chỉ có một cặp**. Một thẻ MUST ở nguyên bàn được chia cho nó trong suốt round. Bộ đếm và thanh tiến trình trên thanh header MUST đo **cả round**, không phải bàn. Sàn hai cặp của BR-153 MUST được áp cho **stage**, không cho từng bàn. | domain + UI | BR-115, BR-117, BR-153 |
| BR-152 | active | Reset MUST đặt `learned_at` và `due_at` cùng về NULL. MUST NOT để thẻ có `learned_at` mà không có lịch (BR-149). | repository | BR-42, BR-149 |
| BR-142 | active | MUST có đúng hai loại phiên, lưu trên `study_sessions.session_kind`: **`learning`** lấy thẻ `learned_at IS NULL`, và **`reviewing`** lấy thẻ `learned_at IS NOT NULL AND due_at <= now`. Một phiên MUST NOT trộn hai tập. | db | BR-23, BR-144 |
| BR-143 | active | `kind = 'learning'` MUST dành cho lượt trong chuỗi học mới: ghi lịch sử, không đổi lịch. MUST NOT xuất hiện trong phiên `reviewing`. | db | BR-75, BR-141 |
| BR-144 | active | Chuỗi học mới MUST NOT đổi `card_study_states` cho tới khi thẻ đi hết **stage cuối mà chính nó tham gia** — stage bỏ qua thẻ theo BR-114 không được tính là stage nó phải đợi. **Hoàn tất là một sự kiện, không phải một lượt đánh giá**: nó đặt `learned_at`, khởi tạo lịch ở mức thấp nhất — `eight_box` box 1, `sm2` interval 1 — với `due_at` là đầu ngày học kế tiếp (BR-105), và MUST NOT ghi lượt `scheduled` nào. | repository | BR-141, BR-105, BR-13, BR-114 |
| BR-145 | active | Phiên `reviewing` MUST NOT được mở khi không có thẻ nào đến hạn. MUST NOT có thao tác nào cho phép ôn sớm hơn hạn. | domain + UI | BR-29, BR-142 |
| BR-146 | active | Mode khả dụng để ôn tập MUST là các stage **chấm điểm** của thuật toán: `eight_box` → `match`, `guess`, `recall`, `fill`; `sm2` → `self_assess`. `browse` MUST NOT là một lựa chọn ôn tập. Chỉ còn một mode khả dụng thì MUST vào thẳng, không hiện màn chọn. | domain + UI | BR-111, BR-99, BR-110 |
| BR-147 | active | Tùy chọn học MUST có hai tầng: mặc định toàn app, và ghi đè trên **root deck**. Deck có giá trị riêng thì dùng giá trị đó; NULL thì theo mặc định. Deck con MUST NOT có tùy chọn riêng — tra qua `root_deck_id` như BR-06. | db | BR-06, BR-139, BR-148 |
| BR-148 | active | `new_card_order` MUST là một trong hai: `created` (theo `created_at` tăng dần) hoặc `random`. Mặc định `created`. | domain | BR-23, BR-147 |
| BR-149 | active | Thẻ có `learned_at` MUST có lịch (`due_at` không NULL); thẻ `learned_at IS NULL` MUST NOT có lượt `scheduled` nào. | db + invariant | BR-144 |
| BR-115 | active | Bốn mode chấm điểm (`match`, `guess`, `recall`, `fill`) MUST chạy theo **round**, ở cả hai loại phiên: round 1 gồm toàn bộ thẻ đủ dữ liệu; mỗi round sau chỉ gồm thẻ không đạt ở round vừa xong. `self_assess` MUST NOT dùng round — nó lặp theo BR-26. | repository | BR-26, BR-116 |
| BR-116 | active | Một thẻ từng có kết quả sai trong một round MUST thuộc tập không đạt của round đó, **kể cả khi sau đó nó được làm đúng** để rời bàn. Tập này MUST được khử trùng theo thẻ. | repository | BR-20, BR-115 |
| BR-117 | active | Mỗi round MUST có thứ tự xoáo riêng. Hai round liền nhau, và round 1 với stage trước đó, MUST NOT dùng chung một sequence khi còn từ hai thẻ trở lên. | db | BR-113 |
| BR-118 | active | Một lượt MUST thuộc về thẻ sở hữu **term**, bất kể vế nào được chạm trước; chạm meaning trước MUST được chấp nhận. Chọn nhầm meaning MUST NOT đánh dấu thẻ sở hữu meaning đó là không đạt. Một cặp sai MUST giữ hàng queue của round hiện tại ở `pending` — thẻ ở lại bàn để ghép lại — và MUST enroll thẻ vào round kế tiếp đúng một lần. | domain | BR-115, BR-116 |
| BR-157 | active | Giao diện MUST chỉ hiển thị kết quả của một lượt **sau khi** transaction ghi lượt đó đã commit; trạng thái đã chấm MUST NOT được vẽ dựa trên thao tác của người dùng trước khi có xác nhận ghi. Ghi thất bại MUST NOT bắt đầu feedback và MUST NOT chuyển lượt. | UI + repository | BR-25, BR-85 |
| BR-158 | active | Đơn vị học đang hiển thị MUST ở lại màn hình trong suốt thời gian đọc kết quả và trong suốt lúc tải lượt kế tiếp; MUST NOT thay thân màn bằng trạng thái tải giữa hai lượt. Trạng thái tải toàn thân MUST chỉ dùng khi phiên chưa có lượt nào. Mỗi mode MUST khai báo thời lượng hiển thị kết quả của mình. | UI | BR-25, BR-157 |
| BR-159 | active | Ở `recall`, mở đáp án MUST NOT là một kết cục: nó MUST NOT ghi `study_answers`, MUST NOT được chấm đúng hay sai, và MUST dừng đồng hồ rồi chuyển sang **tự đánh giá** với đúng hai lựa chọn — nhớ được (đúng) và đã quên (sai). Chỉ lựa chọn của người học MUST được ghi, đúng một lần cho một lượt. | domain + UI | BR-107, BR-120, BR-129, BR-132 |
| BR-160 | active | Hai kết thúc của `recall` MUST có nhịp khác nhau. Tự đánh giá: sau khi commit MUST tự chuyển lượt, MUST NOT giữ thêm một thời lượng cố định và MUST NOT hiện nút Tiếp theo. Hết giờ: sau khi commit MUST hiện trạng thái đã bị tính sai và một nút Tiếp theo, MUST NOT tự chuyển theo thời lượng; bấm Tiếp theo MUST chỉ chuyển lượt và MUST NOT ghi thêm đáp án nào. | UI | BR-129, BR-130, BR-157, BR-158 |
| BR-161 | active | Danh sách deck MUST phân loại mỗi deck theo lịch, suy ra lúc đọc và MUST NOT lưu thành cột: `notDue` khi `dueCardCount = 0`; `dueToday` khi thẻ Due **cũ nhất** của subtree có `due_at` thuộc ngày học địa phương hiện tại; `overdue` khi ngày của nó đã qua. Badge MUST hiện số **ranh giới ngày địa phương đã hoàn tất** giữa `due_at` của thẻ Due cũ nhất và hôm nay (theo mốc BR-105), MUST NOT là phép chia số giờ cho 24. Qua đầu ngày địa phương, trạng thái và badge MUST tự làm mới dù database không có write nào. Cả `dueToday` lẫn `overdue` vẫn thuộc đúng một tập Reviewing của BR-142 — phân loại này là presentation, MUST NOT tạo loại phiên thứ ba, MUST NOT đổi thứ tự thẻ hay hành vi scheduler, Trạng thái `overdue` MUST dùng cặp `errorContainer`/`onErrorContainer` cho ô icon (quyết định chủ dự án 2026-08-11 — đảo phán quyết "không danger" ban đầu của cùng ngày): trễ hạn là tín hiệu đỏ, phân biệt hẳn với `dueToday`. `dueToday` và `notDue` MUST NOT dùng màu đỏ. Level summary MUST tiếp tục phản ánh trạng thái của chính level đang xem — kể cả khi deck mang backlog không còn là một hàng trên màn hình: Due/New là tổng các child subtree (rời nhau), số ngày quá hạn là **max** trên các child có Due, và phân loại đi qua đúng một hàm chung với tile, MUST NOT chép lại điều kiện ở widget khác. Breakdown bốn tập của hero: BR-162. | UI + repository | BR-105, BR-142, BR-150, BR-29 |
| BR-162 | active | Hero level summary MUST hiển thị bốn tập rời nhau của level đang xem: `Overdue` = `learned_at IS NOT NULL AND due_at < startOfToday` (ranh giới đầu ngày địa phương theo mốc BR-105, tính bằng `LocalDayModel`, MUST NOT tự tính trong SQL); `Due today` = `learned_at IS NOT NULL AND due_at >= startOfToday AND due_at <= now`; `New` = `learned_at IS NULL`; `Scheduled` = `learned_at IS NOT NULL AND due_at > now` — hiển thị bằng `total − New − Due` từ cùng snapshot, MUST NOT mang headline hay màu cảnh báo (thẻ nghỉ là lịch đang chạy đúng, không phải việc cần làm). Bốn tập cộng đúng bằng tổng thẻ của level. MUST giữ `dueCardCount = overdueCardCount + dueTodayCardCount` — tổng Reviewing của BR-142 không đổi nghĩa và phiên học vẫn chọn thẻ theo total, không theo hai nửa. Count là aggregate subtree của chính level đang xem, suy ra lúc đọc trong cùng một statement với các count khác — MUST NOT lưu thành cột, MUST NOT query thứ hai. Chú thích tuổi `+Nd` (badge trên tile; dạng chữ trong ngoặc `(+Nd)` ở hero, cùng ngưỡng cap) vẫn là **tuổi** của thẻ Due cũ nhất (BR-161), MUST NOT là count. Qua đầu ngày địa phương, thẻ Due today của ngày cũ MUST tự chuyển sang Overdue ở lần đọc kế tiếp mà không có database write. Deck tile MAY tiếp tục hiển thị total Due + New và phân biệt Due today/Overdue bằng icon trạng thái. | UI + repository | BR-105, BR-142, BR-150, BR-161 |
| BR-119 | active | Mode dùng round MUST hoàn tất khi một round kết thúc mà tập không đạt rỗng. Không có trần số round. Trần 3 của BR-104 là của `self_assess`, không áp ở đây. | repository | BR-115, BR-104 |
| BR-120 | active | Một stage MAY có nhiều mức phản hồi (ví dụ `almost` của `match`), nhưng mọi mức không phải "đúng" MUST vào tập không đạt và MUST ánh xạ như sai theo BR-107. Mức phản hồi MUST NOT xuất hiện trong `study_answers.action`. | domain + UI | BR-106, BR-107 |
| BR-114 | active | Thẻ không đủ dữ liệu cho một stage MUST bị bỏ qua **có ghi nhận** ở stage đó, MUST NOT bị xoá khỏi deck, và MUST vẫn xuất hiện ở các stage khác mà nó đủ dữ liệu. | repository | BR-99, BR-113 |
| BR-103 | active | Khi mở app còn session `in_progress` của **cùng ngày học**, màn chọn MUST có ba đường: tiếp tục phiên đó, Học mới, hoặc Ôn tập. Chọn một trong hai đường sau MUST chuyển phiên dở sang `abandoned`/`user_exit`. Session `in_progress` của ngày học khác MUST chuyển `abandoned` với `end_reason = interrupted`. | repository | BR-80, BR-105, BR-142 |
| BR-104 | active | **Chỉ áp cho mode `self_assess`, ở mọi loại phiên.** Chạm trần 3 lượt `relearning` (BR-26) MUST cho thẻ rời hàng đợi, và MUST bật cờ đánh dấu của thẻ. MUST NOT tự tắt cờ. | repository | BR-26, BR-92 |
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

**BR-134 dùng lại `back_folded`, và điều đáng kiểm là nó fold những gì.** Cột đó
trim và hạ hoa Unicode-aware nhưng **không bỏ dấu** — `card_text_model.dart` ghi
thẳng "Case only. `công` still does not match `cong`". Nếu nó fold cả dấu thì `fill`
sẽ chấm "ma" bằng "mà" là đúng, và một app học từ vựng tiếng Việt hỏng ở đúng chỗ
quan trọng nhất. Kiểm trước khi dùng lại, không suy từ cái tên.

**BR-135 là lý do `scheduler_version` tồn tại, áp cho một thứ khác.** Một lượt đã ghi
phải đọc lại được bằng chính luật đã tạo ra nó. Nới chính sách so khớp — ví dụ bỏ
qua dấu câu — sẽ biến những lượt sai của hôm qua thành đúng khi đọc lại, và không
có cách nào biết lượt nào đã được chấm theo luật nào.

**BR-138 là quyết định có thể lật, và hiện tại nghiêng về không lưu.** Câu trả lời
sai của người học là dữ liệu phân tích tốt, nhưng nó cũng là dữ liệu riêng tư
(BR-51) và chưa có tính năng nào đọc nó. Thêm cột khi có caller thật thì rẻ; gỡ một
cột đã đầy dữ liệu riêng tư thì không.

**BR-144 làm một vấn đề biến mất thay vì phải xử lý nó.** Nếu chuỗi học mới đặt
lịch dọc đường thì một phiên bỏ dở ở stage 3 để lại thẻ có lịch nhưng chưa học
xong, và lần học mới sau sẽ đặt lại lịch lần hai. Gỡ chuyện đó cần hoàn tác
`card_study_states` từ `previous_*`, giảm `lapse_count`, và xoá lượt — tức sửa BR-86,
thứ tồn tại để đảm bảo không lượt nào bị mất.

Không đặt lịch cho tới khi xong chuỗi thì **không có gì để hoàn tác**: thẻ bỏ dở
chưa có `learned_at`, chưa có `due_at`, nên nó đơn giản nằm lại trong tập học mới
và học lại từ `browse`. Các lượt đã ghi vẫn ở nguyên trong `study_answers` dưới
`kind = 'learning'` — chúng là lịch sử thật về việc người học đã gặp thẻ đó.

**Hoàn tất học mới là sự kiện, không phải lượt đánh giá** — và đó là lý do nó
không cần một `action` tổng kết. Bốn stage chấm điểm đều lặp round tới khi sạch
(BR-119), nên mọi thẻ đều kết thúc chuỗi bằng một lần đúng: một action suy từ đó
sẽ luôn là "nhớ được" và không phân biệt được thẻ nào. Thẻ vừa học lần đầu
vì thế bắt đầu ở mức thấp nhất và gặp lại ngay ngày học kế — một buổi học không
đủ dữ kiện để nói thẻ nào dễ.

**BR-145 là luật về sản phẩm, không phải về dữ liệu.** Ôn sớm hơn hạn làm hỏng chính
thứ spaced repetition mua được: khoảng cách. App không chặn người dùng học nhiều —
họ có thể mở bao nhiêu phiên tùy ý (BR-24) — nhưng thứ họ học thêm phải là **thẻ
mới**, không phải thẻ chưa tới hạn.

**BR-147 tách hai tầng vì hai deck không giống nhau.** Một deck nhập từ giáo trình
cần học theo thứ tự bài; một deck từ vựng rời thì ngẫu nhiên tốt hơn. Bắt người
dùng chọn một kiểu cho cả hai là bắt họ chọn sai cho một trong hai. Deck để NULL
thì theo mặc định, nên không ai phải cấu hình gì để bắt đầu.

**Mốc 00:00 làm khoảng cách đầu tiên phụ thuộc giờ học, và đó là đánh đổi đã
nhận.** Thẻ học xong lúc 09:00 đến hạn sau 15 giờ; thẻ học xong lúc 23:00 đến hạn
sau **một giờ**. Từ lượt ôn thứ hai trở đi thì khoảng cách đo bằng ngày lịch nên
không còn lệch, nhưng lượt đầu tiên thì có.

Đây là giá của việc neo vào **ngày lịch** thay vì cộng giờ (BR-105), và cái mua
được lớn hơn: giờ học không trôi dần về khuya, và "đến hạn hôm nay" đúng nghĩa là
hôm nay. Nếu sau này muốn gỡ, lối đi là mốc cắt khác 00:00 — sửa một chỗ theo AD-16,
không phải sửa công thức.

**BR-159 sửa một lỗi chấm điểm, không phải một lỗi giao diện.** Mở đáp án từng
*là* kết cục "đúng": người học bấm Xem đáp án ở giây thứ tư và thẻ được thăng
hộp vì đã bỏ cuộc. 8-box cần đúng một bit bằng chứng cho mỗi lượt, và bằng chứng
ấy chỉ người học có — nhìn vào mặt sau không nói gì về việc có nhớ hay không.
Nên reveal là **trạng thái trình bày**, còn kết cục là thứ người học nói ra.

**BR-160 là hệ quả của việc hai kết thúc do hai người bấm giờ.** Tự đánh giá xảy
ra *sau* khi người học đã đọc mặt sau, nên giữ màn hình thêm một nhịp là bắt họ
chờ trên thứ họ đọc xong rồi. Hết giờ thì ngược lại: mặt sau là chữ họ chưa từng
thấy, trên một thẻ vừa mất vì đồng hồ — không ai chọn hộ được thời lượng ấy, nên
nó kết thúc ở một nút họ bấm. Một con số cố định phục vụ cả hai thì sai cả hai
lần, và 1800/2200ms đang đo một việc không ai làm.

**BR-131 là BR-76 lặp lại ở một chỗ khác.** Người học tự nhận quên và người học
hết giờ đều cho `action = forgotten`. Không có cột riêng thì hai điều đó không phân
biệt được từ dữ liệu đã lưu — và chúng nói hai chuyện rất khác nhau về chất
lượng thẻ. `study_answers` là bảng chỉ thêm, nên một cột thiếu hôm nay không tính
ngược được ngày mai.

**BR-133 là hệ quả của BR-103, không phải một yêu cầu UI.** Phiên sống sót qua
việc hệ điều hành thu hồi app, nên "còn bao nhiêu giây" phải nằm trong database
chứ không trong bộ nhớ của một controller. Ngược lại, một lượt mới ở round sau
bắt đầu lại đủ 20 giây — nó là lượt khác, không phải phần còn lại của lượt cũ.

**Đếm giờ nằm ở `presentation/`, không ở `domain/`.** AD-13 và AD-16 đã chốt
`lib/features/` không đọc đồng hồ. Handler của `recall` nhận `didTimeout` và
`elapsedMs` như input và vẫn là hàm thuần — đúng khuôn AD-18 đặt cho mọi stage.

**Mỗi mode có một ngưỡng riêng, và chúng không giống nhau.** BR-140 nói không mode
nào có ngưỡng **số thẻ lấy ra** riêng — mọi mode của một phiên dùng chung
một tập. Nhưng điều kiện
**dựng được nội dung** thì có, và khác nhau: `guess` cần năm nghĩa khác nhau trong cây
(BR-121, BR-122); `fill` cần thẻ có `example` (BR-114); `match` cần hai cặp (BR-153).
`recall`, `self_assess` và `browse` chạy được với một thẻ.

BR-153 tồn tại vì một deck mới tạo với đúng một thẻ là ca thật, không phải ca biên:
người dùng thêm thẻ đầu tiên rồi bấm Học mới ngay. Không có luật này thì `match`
hiện một cặp và người học ghép nó với chính nó — một lượt đúng không chứng minh gì.

**BR-22 bị thay, và điều đó chạm tới code đang chạy.** Định nghĩa cũ — `due_at IS
NULL OR due_at <= now` — đang được badge trên deck list, pill Due/New trên card
list và query `cardsDueForStudy` implement. Trong mô hình mới, `due_at IS NULL`
không còn nghĩa "đến hạn ngay" mà nghĩa "chưa học xong", nên một con số gom cả
hai đang trộn hai việc có chi phí khác hẳn nhau: 20 thẻ mới tốn gấp năm lần 20
thẻ ôn. BR-150 và BR-151 đưa hai con số đó về đúng ngôn ngữ mà popup Study dùng.

**BR-155 tồn tại vì `browse` là stage duy nhất không có câu hỏi nào.** Năm stage
còn lại đều lấy một câu trả lời từ thẻ đang hiện; đặt một thẻ đã trả lời lên đó
là mời người dùng chấm lại thứ phiên đã chấm — BR-126 nói mỗi câu hỏi sinh tối đa
một lượt, và một màn cho phép quay lại thẻ đã chấm là đường đi thẳng tới lượt thứ
hai. `browse` không chấm gì (BR-111), nên quay lại nó không mâu thuẫn với điều gì.

Chỗ dễ sai là **lùi rồi tiến**. Nếu lùi làm `cursor` giảm thì tiến lại sẽ đi qua
`markBrowsed` một lần nữa: thẻ được ghi hai lần và bộ đếm nhảy quá tay. Vì vậy
BR-155 nói rõ lùi **không** đụng tới queue — nó chỉ đổi thẻ nào đang được vẽ. Bộ
đếm và thanh tiến trình vẫn mô tả lượt đang mở, nên màn hình MUST nói rõ đang xem
lại; nếu không, một thẻ đã qua trông như phiên vừa tự lùi.

Chỗ dễ sai thứ hai là **thứ tự của vết đã xem**. Danh sách thẻ đã xong của một
round trước đây được đọc không kèm `ORDER BY`; `match` dùng nó như một tập nên
không thấy gì, còn `browse` đi ngược nó nên thứ tự là bắt buộc. Câu truy vấn nay
sắp theo `position` — thứ tự queue phục vụ, cũng chính là thứ tự người dùng đã
thấy trong một round phục vụ mỗi thẻ đúng một lần.

**BR-152 tồn tại vì invariant 24 đã bắt được một mâu thuẫn.** Reset xoá lịch;
nếu nó giữ `learned_at` thì mỗi lần reset sẽ để lại một thẻ "đã học xong nhưng
không có lịch" — đúng thiếu sót mà invariant 24 được viết để chặn, và một thẻ
không thuộc tập nào trong hai tập của BR-142. Xoá cả hai cùng lúc đưa thẻ về
đúng trạng thái trước khi học — đúng nghĩa của "đặt lại tiến độ".

**BR-122 đã đổi nguồn, và lý do nằm ở phiên ôn tập.** Một phiên ôn có thể chỉ có
ba thẻ đến hạn — lấy distractor từ phạm vi đó thì không bao giờ đủ năm nghĩa và
`guess` gần như luôn bị vô hiệu hoá, dù deck có hai trăm thẻ đã học. Nguồn đúng là
**thẻ đã học xong trong cây**: người học đã gặp chúng nên chúng là nhiễu thật, và
thẻ chưa học không bị lộ nội dung trước khi đến lượt nó.

**`self_assess` không bao giờ dùng round.** Nó lặp bằng BR-26 ở **mọi loại phiên**:
thẻ quay lại sau ≥ 3 thẻ khác, trần 3 lượt rồi rời hàng đợi kèm cờ (BR-104). Bốn
mode chấm điểm dùng round, không trần (BR-119). Hai cơ chế, ranh giới là **mode**
chứ không phải loại phiên — vì `self_assess` không có "bàn" để hết, còn bốn mode
kia thì có.

**BR-122 tách hai khái niệm dễ bị gộp.** *Hàng đợi* là những thẻ đang được hỏi ở
round này; *tập thẻ của phiên* là nguồn lấy distractor. Chúng khác nhau, và gộp
lại thì retry round còn một thẻ sẽ không đủ năm lựa chọn — đúng ca mà BR-115 tạo ra
thường xuyên nhất. Thẻ đã đạt rời hàng đợi nhưng **không** rời tập nguồn.

**BR-123 dùng lại `back_folded` thay vì định nghĩa một phép chuẩn hoá thứ hai.**
Cột đó có từ schema v3 (M4.11a) để search so trên nó: đã trim, hạ hoa và fold
Unicode. Một phép normalize riêng cho `guess` sẽ trôi khỏi phép kia ngay lần đầu
có ai sửa một trong hai, và không ai biết để sửa cả hai.

**BR-124 là chỗ đặc tả gốc và BR-114 nói ngược nhau, và cả hai đều đúng — cho hai
ca khác nhau.** Deck chỉ có ba thẻ thì `guess` **không bao giờ** dựng được question,
và hiện lỗi mỗi phiên là đổ cho người dùng một thứ họ không sửa được bằng thao
tác nào trong phiên; bỏ qua stage là đúng. Nhưng khi tập đủ năm mà một question
vẫn không dựng được thì đó là bất thường thật, và chặn lại mới đúng — render bốn
lựa chọn sẽ âm thầm đổi xác suất đoán đúng từ 20% lên 25%.

**Một thẻ đi qua nhiều mode trong một phiên, và câu "lượt nào đổi lịch" có hai
câu trả lời khác nhau tùy loại phiên.**

Trong phiên `reviewing`, mỗi thẻ được hỏi bằng **một** mode, nên lượt đầu của nó
là `scheduled` và đổi lịch; các lượt lặp sau đó — round hoặc BR-26 — là
`relearning` (BR-77, BR-141).

Trong phiên `learning`, thẻ đi qua cả chuỗi và **không lượt nào đổi lịch**
(BR-144). Lý do không phải là tiết kiệm: bốn mode chấm điểm đều lặp tới khi sạch
(BR-119), nên mọi thẻ đều kết thúc chuỗi bằng một lần đúng — một `action` suy từ
đó sẽ luôn đọc là "nhớ được" và không phân biệt được thẻ nào. Lịch vì thế được
khởi tạo bởi **sự kiện hoàn tất**, ở mức thấp nhất, giống nhau cho mọi thẻ.

**Mô hình này thay mô hình một-phiên-một-chuỗi của M5.0b…M5.0j.** Bản cũ cho lượt
đầu ở stage chấm điểm đầu tiên quyết định lịch, và ghi nhận thẳng rằng đó là hệ
quả được chấp nhận chứ chưa được cân nhắc đủ: sai ở Match rồi đúng ba stage sau
vẫn cho lịch của một lần sai. Câu hỏi đó không còn tồn tại — trong phiên học mới
không có lịch nào để đặt sai, và trong phiên ôn tập chỉ có một mode nên không có
gì để chọn giữa.

**Không còn mục nào để trống trong nghiệp vụ Study.** Hai mục cuối đã đóng ở
M5.0m: trần thẻ là `card_limit` áp cho cả hai loại phiên và là trần **mỗi lần
lấy** (BR-24); và phiên không cho chọn scope hẹp hơn deck đang đứng — người dùng
chọn **loại phiên**, không chọn phạm vi.

---

## Progress overview

Progress đọc `study_answers` (BR-77) và **không** ghi gì. Các rule dưới đây chỉ
nói phần mà việc *đọc lại lịch sử* thêm vào; chúng không phát biểu lại luật ghi
lượt (BR-76, BR-77, BR-111), luật reset (BR-41…BR-47) hay luật ngày học
(BR-105).

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-192 | active | Đơn vị hoạt động của Progress là một cặp **distinct `(localDay, cardId)`**, gọi là một *card-day*. Nhiều answer, nhiều stage, nhiều round hay nhiều session của **cùng một card trong cùng một local day** MUST đếm đúng **một**. Progress MUST NOT đếm số hàng `study_answers`, số session hay số lượt. Một card được trả lời trong hai local day khác nhau MUST đếm hai. `localDay` của **mọi** hàng — kể cả hàng ghi từ nhiều tháng trước — MUST được tính bằng UTC offset của **lần đọc hiện tại**, vì `study_answers` không lưu offset theo hàng. Hệ quả đã biết và chấp nhận cho v1: đổi múi giờ hoặc qua một mốc DST làm các ngày quá khứ được phân bucket lại, nên một chuỗi có thể dài ra hoặc đứt hồi tố. | repository (SQL) | UC-13, BR-77, BR-105 |
| BR-193 | active | Stage `browse` không ghi hàng `study_answers` nào (BR-111), nên nó MUST NOT tạo card-day, MUST NOT làm một ngày trở thành active và MUST NOT giữ streak. Mở một phiên rồi chỉ lướt `browse` và thoát MUST để Progress y nguyên. | repository (SQL) | UC-13, BR-111 |
| BR-194 | active | "Hôm nay" của Progress là nửa khoảng `[startOfToday, startOfTomorrow)` theo `LocalDayModel` (BR-105), dựng từ **một** snapshot của `clockProvider` và `utcOffsetProvider`. Mọi con số của một lần hiển thị — Today, Last 7 days, streak — MUST đến từ cùng snapshot đó; MUST NOT có hai lần đọc đồng hồ trong một emission, và SQL MUST NOT tự dẫn xuất local midnight. | use case + repository | UC-13, BR-105, AD-16 |
| BR-195 | active | Phân rã của một ngày là một **partition loại trừ nhau**: một card-day là **Learning** khi có ít nhất một answer `kind = 'learning'` trong ngày đó; nếu không, và chỉ khi đó, nó là **Reviewing** khi có answer `scheduled` hoặc `relearning`. `learning + reviewing = total` MUST luôn đúng cho mọi ngày. Một card vừa `learning` vừa `scheduled` trong cùng ngày MUST đếm là Learning và MUST NOT đếm hai lần. | repository (SQL) | UC-13, BR-76, BR-192 |
| BR-196 | active | "Last 7 days" gồm **hôm nay và sáu ngày trước đó**, đúng bảy phần tử, thứ tự **cũ → mới**. Ngày không có card-day nào MUST xuất hiện với giá trị 0 (zero-fill), MUST NOT bị bỏ khỏi dãy và MUST NOT làm dãy ngắn lại. Dãy MUST đúng khi cửa sổ bắc qua ranh giới tháng, ranh giới năm và ở mọi UTC offset. | repository + use case | UC-13, BR-192, BR-194 |
| BR-197 | active | Current streak là số local day liên tiếp có hoạt động, tính lùi từ **anchor**: nếu hôm nay active thì anchor là hôm nay; nếu hôm nay chưa active nhưng hôm qua active thì anchor là hôm qua và chuỗi MUST được giữ nguyên (không reset về 0 chỉ vì hôm nay chưa học); nếu cả hai đều không active thì streak là 0. Streak MUST NOT có trần và MUST NOT bị cắt bởi cửa sổ bảy ngày của BR-196. | repository + use case | UC-13, BR-192, BR-194 |
| BR-198 | active | Reset learning progress giữ `review_history`/`study_answers` (BR-43), nên nó MUST NOT làm thay đổi bất kỳ con số nào của Progress. Ngược lại, card đã bị xoá cứng — trực tiếp, hay theo cascade từ deck bị xoá — MUST NOT còn xuất hiện trong Progress, kể cả trong các ngày quá khứ, vì hàng `study_answers` của nó bị cascade xoá theo. v1 MUST NOT tạo tombstone, bảng bóng hay bản sao analytics để giữ lại hoạt động của card đã xoá. | repository (schema cascade) | UC-13, BR-41, BR-43 |
| BR-199 | active | Màn Progress MUST tự cập nhật khi lịch sử đổi (một answer mới ghi vào, một card hay deck bị xoá) và tại **local midnight**, không cần thao tác của người dùng. Bộ hẹn giờ midnight MUST là one-shot đặt theo `startOfTomorrow` của emission hiện tại, MUST bị huỷ khi controller dispose hoặc rebuild, MUST NOT lặp vô hạn khi ranh giới đã ở quá khứ tại lúc emission tới, và MUST resolve lại UTC offset ở **mỗi** lần đọc lại — resume, midnight hoặc Retry — chứ MUST NOT giữ offset mà màn hình mở lần đầu. Live refresh và midnight rollover MUST là chuyển tiếp giữa hai trạng thái loaded: khi đã có dữ liệu trên màn, cả hai MUST NOT hạ màn về loading. | controller + UI | UC-13, BR-194, AD-16 |
| BR-200 | active | Tab Study MUST đọc thư viện thật và MUST NOT phụ thuộc vào bất kỳ deck id cố định nào trong production. Vào tab, cuộn, đổi tab và stream tự refresh MUST NOT ghi database: MUST NOT tạo session, MUST NOT khoá scheduler (BR-13), MUST NOT materialize hàng đợi. Chỉ thao tác chạm tường minh của người dùng mới được dẫn tới write. Resume card MUST chỉ hiện khi tồn tại một session thoả **đồng thời** bốn điều kiện, tất cả kiểm bằng đọc: `status = in_progress`; `started_at` thuộc ngày học hiện tại theo mốc BR-105; generation của root khớp generation của session (BR-84); và hàng đợi của session còn ít nhất một hàng. Session không thoả MUST NOT được quảng cáo; việc **đóng** session của ngày cũ vẫn thuộc `abandonStaleSessions` (BR-103) và MUST NOT chuyển vào màn hình này. Chạm Resume MUST mở đúng session và đúng lượt đã lưu (BR-133), MUST NOT tạo session thứ hai. Nhiều session cùng mở thì MUST chọn session mới nhất theo `started_at`. Chạm hai lần liên tiếp MUST chỉ dẫn tới một lần mở. | repository + UI | UC-14, BR-84, BR-101, BR-103, BR-133 |
| BR-201 | active | Danh sách Study Home MUST chỉ liệt kê root deck, mỗi root một hàng, workload tổng hợp **toàn subtree** qua `root_deck_id` (BR-56, BR-57) và MUST NOT dùng shortcut coalesce parent. Thứ tự MUST giảm dần theo ba khoá xếp hạng, đúng thứ tự đó: số Overdue, rồi số Due today, rồi số New — MUST NOT xếp theo tổng. Bằng nhau cả ba thì tie-break theo tên deck đã fold chữ hoa/thường theo Unicode (cùng quy ước BR-93), rồi theo `id`; tie-break MUST NOT dựa vào `lower()` của SQL vì hàm đó chỉ fold ASCII. Deck không còn workload MUST vẫn nằm trong danh sách, đứng cuối theo chính thứ tự trên, và MUST giữ hành động mở nếu subtree còn ít nhất một card (BR-29). Deck không còn card nào MUST NOT được trao hành động mở. Ba con số MUST luôn hiển thị kể cả khi bằng 0, mỗi con số MUST có icon và nhãn chữ riêng, và màu MUST NOT là tín hiệu duy nhất. | repository + UI | UC-14, BR-29, BR-56, BR-57, BR-93, BR-162 |
| BR-202 | active | Study Home MUST phân biệt ba trạng thái đã tải, mỗi trạng thái có một bước tiếp theo riêng. Thư viện **không có root deck nào**: MUST hiển thị CTA tới Starter Library (UC-01) và MUST NOT hiện danh sách rỗng. Có root deck nhưng **không root nào có card**: MUST hiển thị zero state có đường về Library, MUST NOT hiện CTA starter và MUST NOT bịa số Due cho deck rỗng. Có card: MUST hiện danh sách theo BR-201, kể cả khi mọi workload bằng 0 — trường hợp đó là lịch đang chạy đúng (BR-29), MUST NOT trình bày như lỗi hay như thành tích. Mọi hành động trên màn hình MUST trỏ tới route có thật; MUST NOT có control bật mà không dẫn đi đâu. Lỗi đọc MUST hiện trạng thái lỗi có retry, MUST NOT nêu tên bảng, câu truy vấn hay đường dẫn. | UI | UC-14, UC-01, BR-29, BR-201 |
| BR-190 | active | Progress MUST là read-only tuyệt đối: mở màn, đóng màn, Retry, đổi tab hay quay lại MUST NOT ghi hay sửa bất kỳ hàng nào — không `study_sessions`, không `card_study_states`, không `study_answers`, không `app_settings` — và MUST NOT mở, tiếp tục hay đóng session nào. | repository + UI | UC-12, BR-178 |
| BR-191 | active | v1 của Progress MUST NOT hiển thị: accuracy hay correct rate, longest streak, mục tiêu/goal, XP hay điểm, heatmap, bộ lọc theo deck, chia sẻ, và hiệu ứng ăn mừng. Các chỉ số này cần định nghĩa nghiệp vụ riêng chưa được chốt; hiển thị một con số chưa có BR đứng sau là viết spec ở tầng sai. | UI | UC-12, AD-19 |

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
| card | unset | xoá card cuối cùng, hoặc chuyển card cuối cùng đi nơi khác — tự động, trong cùng transaction (BR-163, BR-165) |
| deck | unset | xoá deck con cuối cùng, hoặc chuyển deck con cuối cùng đi nơi khác — tự động, trong cùng transaction (BR-163) |

**Chuyển đổi không hợp lệ:** `card` → `deck` và `deck` → `card` trực tiếp — một
deck đang có nội dung không đổi loại. Đường duy nhất giữa hai loại là đi qua
`unset`, và `unset` chỉ đạt được bằng cách deck thật sự rỗng (BR-163).

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
| Xoá card cuối cùng của deck `content_type = card` | `content_type` về `unset` trong cùng transaction (BR-163) |
| Chuyển card cuối cùng sang deck khác cùng root | Nguồn về `unset`, đích thành `card` — một transaction (BR-165) |
| Import vào deck `unset`, có ít nhất một card ghi được | Deck thành `card` trong cùng transaction (BR-172) |
| Import mà mọi hàng đều trùng hoặc invalid | Không mutation nào; `content_type` giữ nguyên (BR-171, BR-172) |
| Import vào root deck hoặc deck đang giữ deck con | Chặn trong transaction, lỗi có kiểu (BR-168) |
| Hàng chỉ có `front`, thiếu `back` | Hàng invalid, hiện lý do; các hàng khác không bị ảnh hưởng (BR-169) |
| Hai hàng trong file cùng `front`+`back` sau fold | Hàng sau đánh dấu trùng-trong-file; mặc định bỏ qua (BR-170) |
| Card cùng nội dung đã có sẵn trong deck đích | Đánh dấu trùng-với-deck; bật Include duplicates thì vẫn ghi (BR-170) |
| Một write giữa batch thất bại | Rollback toàn bộ — không partial card/state/tag (BR-171) |
| Export scope `all` khi danh sách đang bật filter/search | File vẫn chứa toàn bộ card trực tiếp của deck, không phải tập đã lọc (BR-174) |
| Export scope `selected` có id lặp lại | Normalize còn một hàng; số card trong file khớp số id phân biệt (BR-174) |
| Một card trong tập chọn bị xoá hoặc chuyển deck trước lúc đọc | Cả request thất bại có kiểu; không sinh file một phần (BR-174) |
| Tag chứa `;` hoặc `\` | Escape khi ghi, khôi phục nguyên văn khi import lại (BR-176) |
| Ô nội dung bắt đầu bằng `=` hoặc `+` | Ghi như text trong XLSX; mở bằng spreadsheet không thành formula (BR-179) |
| Tên deck chỉ gồm ký tự bị loại khi sanitize | Tên file dùng `cards` + ngày + đuôi format (BR-180) |
| Người dùng đóng share sheet | Coi là cancel; không toast lỗi, không nói đã lưu (BR-181) |
| Muốn đổi deck rỗng từ `card` sang chứa deck con | Rỗng là đã `unset`; tạo deck con luôn được (BR-163) |
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
| Deck rỗng (0 card) | Empty state với hành động phù hợp `content_type`; không vào được phiên nào |
| Không card nào đến hạn | Ôn tập **không mở được** (BR-145); hiện thời điểm card gần nhất đến hạn. Học mới vẫn mở được nếu còn thẻ chưa học |
| Bỏ 2 tuần, 400 card quá hạn | `card_limit` thẻ mỗi lần lấy, mặc định 20 (BR-24); hiện số còn lại và cho mở phiên tiếp ngay — số phiên trong ngày không giới hạn |
| Thoát giữa phiên | Giữ toàn bộ lượt đã ghi (BR-25, BR-86); session → `abandoned`/`user_exit`. Phiên học mới bỏ dở **không để lại lịch nào** (BR-144) |
| SM-2, card bị quên liên tục | `ease_factor` chạm sàn 1.3 và dừng ở đó (BR-19) |
| Đổi giờ hệ thống / lệch múi giờ | Lưu và so sánh `due_at` bằng UTC |
| Thêm starter deck đã có bản sao | Hỏi xác nhận nêu rõ đã tồn tại (BR-38) |
| Cập nhật app nâng version template | Không đụng vào bản sao đã có (BR-36) |
| Nội dung card rất dài (2000 ký tự) | Cuộn được trong vùng card, không tràn, không cắt mất |
| Bộ nhớ đầy khi sao chép starter deck | Transaction rollback (BR-39); không để lại deck nửa vời |
| Trả lời cùng một thẻ sáu lần trong một buổi tối | Một card-day, một active day (BR-193) |
| Học hai deck khác nhau trong cùng một ngày | Mỗi deck một active day; tổng của cấp trên vẫn là một (BR-193) |
| Chuyển thẻ sang root khác sau khi đã học | Toàn bộ lịch sử của thẻ chuyển theo; deck cũ về 0 (BR-195) |
| Xoá deck đang có hoạt động | Cascade xoá card rồi answers; số về 0, không phải bị lọc (BR-195) |
| Reset learning progress rồi học tiếp | Cả hai generation đều được đếm — reset không làm việc đã học biến mất (BR-43, BR-193) |
| Mở màn hình tiến độ lúc 23:59 rồi để yên | Nửa đêm địa phương, cửa sổ trượt một ngày và màn hình tự đọc lại (BR-194, BR-199) |
| Một ngày có cả lượt `learning` và lượt `scheduled` trên cùng thẻ | Là Learning day (BR-196) |
| Năm mươi deck cùng 0 hoạt động | Vẫn hiện, đứng cuối, thứ tự không đổi giữa hai lần đọc (BR-197) |
