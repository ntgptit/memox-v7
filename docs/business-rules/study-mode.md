# BR — StudyMode

Tách khỏi `../business-rules.md` ở M100.68. Trạng thái, cách đánh số và quyền
sở hữu không đổi: `../business-rules.md` vẫn là `Source of truth for` của
business rules, và `check_docs.py` đọc cả hai qua `_contract_files("BR")`.

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

