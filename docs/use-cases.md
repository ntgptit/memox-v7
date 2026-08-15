# Use cases — memox (MVP)

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng đủ chi tiết để xây mà không phải hỏi thêm |
| **Scope** | Must-have của MVP. Ngoài phạm vi: should/nice-to-have, và mọi thứ ở mục "Điều đã cố ý không đặc tả" |
| **Source of truth for** | UC-xx · main/alternative/error flow · UI state matrix của từng màn |
| **Depends on** | `document-conventions.md`, `product.md`, `business-rules.md` |
| **Updated by task** | M99.24 — UC-13: xem tiến độ theo deck (cấp thư viện → cấp deck, hai khoảng); trước đó M99.23 — UC-12: xem tiến độ học (streak, hôm nay, bảy ngày) |
| **Last updated** | 2026-08-15 |

Chỉ đặc tả must-have. Should-have và nice-to-have viết khi tới lượt — đặc tả
trước những thứ có thể bị cắt là lãng phí.

Luồng viết bằng ngôn ngữ người dùng, không nói theo màn hình hay widget. Màn
hình sẽ đổi; luồng thì không.

**ID use case là định danh vĩnh viễn**, cùng chính sách với BR (xem
`business-rules.md`). UC mới append; không đánh số lại. Hiện tại: UC-01…UC-12.

**Các UC nối vào nhau thế nào thì xem [`master-flow.md`](master-flow.md).** Tài
liệu này đặc tả từng UC riêng lẻ và cố ý không vẽ đồ thị giữa chúng — mỗi UC mô
tả mình và im lặng về những UC bên cạnh, nên câu "xong bước này thì đi đâu" không
có chỗ nào ở đây trả lời. Cạnh của đồ thị đó là thứ `master-flow.md` sở hữu; nó
tham chiếu ngược về đây bằng ID và không phát biểu lại luồng nào.

---

## UC-01 · Khởi động lần đầu và chọn starter deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng mới cài app
**Trigger:** Mở app lần đầu sau khi cài
**Preconditions:** Chưa có deck nào

**Main flow:**
1. Người dùng mở app.
2. Hệ thống khởi tạo database.
3. Người dùng thấy màn hình chưa có deck, kèm hai lối đi: **chọn từ thư viện
   starter** hoặc **tạo deck mới**.
4. Người dùng mở thư viện starter deck.
5. Hệ thống đọc manifest template và hiện danh sách: tên, số card, ngôn ngữ,
   nguồn nội dung. Nội dung starter được ghi rõ là **fixture cho development và
   test** (BR-87).
6. Người dùng chọn một starter deck.
7. Hệ thống hỏi **chế độ ôn tập** cho bản sao, gợi ý sẵn `default_scheduler_type`
   của template (BR-34).
8. Hệ thống **tạo bản sao** trong một transaction (BR-39): root deck mới với
   `content_type = 'deck'`, `root_deck_id = id`, `scheduler_generation = 1`; toàn
   bộ cây deck con với `content_type` đúng theo template; toàn bộ card; và study
state theo scheduler đã chọn (BR-09, BR-33).
9. Bản sao xuất hiện trong danh sách deck. Toàn bộ card là thẻ **chưa học**
   (`learned_at IS NULL`), nên badge của deck hiện số New chứ không phải số
   đến hạn (BR-142, BR-150).
10. Người dùng bấm Study và bắt đầu phiên **học mới** ngay.

**Alternative flows:**
- **A1 — Bỏ qua thư viện, tự tạo deck:** đi thẳng UC-02.
- **A2 — Đã có bản sao từ đúng template và version đó:** hỏi xác nhận, nêu rõ đã
  tồn tại (BR-38). Đồng ý thì tạo bản sao thứ hai — lựa chọn có ý thức, khác hoàn
  toàn với việc app tự tạo trùng (BR-37).
- **A3 — Cập nhật app có template mới hoặc version mới:** template mới xuất hiện
  trong thư viện. Bản sao đã có **không** bị đụng đến (BR-36).
- **A4 — Người dùng đã xoá bản sao:** template vẫn còn trong thư viện, lấy lại
  được.

**Error flows:**
- **E1 — Không mở được database:** màn hình lỗi rõ ràng với hành động thử lại.
  Không được là màn hình trắng — trắng không phân biệt được với treo.
- **E2 — Manifest hỏng hoặc thiếu:** thư viện hiện empty state; app vẫn dùng bình
  thường với luồng tạo deck thủ công.
- **E3 — Một file template hỏng:** bỏ qua đúng template đó, các template khác vẫn
  hiện.
- **E4 — Sao chép thất bại giữa chừng:** transaction rollback (BR-39). Không có
  cây deck nửa vời.

**Postconditions:**
- Bản sao có `source_template_id`, `source_template_version`, `scheduler_type` đã
  chọn, `scheduler_generation = 1`, `first_answered_at = NULL`.
- Mọi deck trong bản sao có `root_deck_id` trỏ đúng root mới (BR-56).
- Mỗi card có đúng một study state khởi tạo theo scheduler đó.

**Business rules:** BR-09, BR-31…BR-39, BR-56, BR-87
**UI states:** initial · loading · loaded · empty · submitting · error

---

## UC-02 · Tạo root deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Bấm tạo deck ở màn hình danh sách deck
**Preconditions:** Không có

**Main flow:**
1. Người dùng nhập tên deck.
2. Người dùng **chọn chế độ ôn tập**: `eight_box` hoặc `sm2` (BR-11). Bắt buộc,
   không có mặc định ngầm bỏ qua bước này.
3. Hệ thống hiển thị mô tả ngắn cho từng chế độ, kèm lưu ý rằng chế độ sẽ bị khoá
   sau lượt ôn đầu tiên (BR-13).
4. Người dùng xác nhận.
5. Hệ thống validate tên (BR-01) và chế độ đã chọn.
6. Hệ thống tạo root deck với: `parent_deck_id = NULL`, `root_deck_id = id`,
   `content_type = 'deck'` (bất biến), `scheduler_generation = 1`,
   `first_answered_at = NULL`.
7. Deck xuất hiện trong danh sách, rỗng.

**Root deck chỉ chứa deck con** (BR-58). Nút Create bên trong nó chỉ có một lựa
chọn: Create deck (BR-59). Việc tạo phần tử con nằm ở UC-08.

**Alternative flows:**
- **A1 — Người dùng huỷ:** không tạo gì; nếu đã nhập, hỏi xác nhận trước khi bỏ.

**Error flows:**
- **E1 — Tên rỗng:** lỗi inline dưới ô nhập, không phải snackbar.
- **E2 — Tên quá 200 ký tự:** lỗi inline; chặn nhập thêm thay vì cắt âm thầm.
- **E3 — Chưa chọn chế độ:** lỗi inline ở phần chọn chế độ; không tạo.
- **E4 — Ghi database thất bại:** hiện lỗi, giữ nguyên form và dữ liệu đã nhập.

**Postconditions:** Root deck tồn tại với scheduler đã chọn, `content_type =
'deck'`, `root_deck_id = id`, và còn sau khi khởi động lại app.

**Business rules:** BR-01, BR-02, BR-11, BR-56, BR-58, BR-59
**UI states:** initial · submitting · error

---

## UC-03 · Sửa và xoá deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn sửa hoặc xoá trên một deck
**Preconditions:** Deck tồn tại

**Main flow (sửa tên):**
1. Người dùng đổi tên deck.
2. Hệ thống validate (BR-01) và lưu.

**Main flow (đổi chế độ ôn tập — chỉ trên root deck, chỉ khi chưa có lượt học):**
1. Hệ thống hiển thị phần chọn chế độ ở trạng thái **mở khoá**
   (`first_answered_at IS NULL`, BR-12).
2. Người dùng chọn chế độ khác.
3. Hệ thống cảnh báo study state của **toàn bộ card trong cây** sẽ được khởi tạo
   lại theo chế độ mới (BR-14), và phiên học đang mở sẽ bị đóng (BR-164). Đây
   **không** phải Reset learning progress: không có generation nào bị tiêu, không
   có lịch sử nào bị bỏ, nên cảnh báo này MUST NOT dùng giọng phá huỷ của UC-07.
4. Người dùng xác nhận.
5. Hệ thống đổi scheduler, khởi tạo lại study state toàn cây, **và** đóng mọi
   phiên đang mở của cây — trong một transaction (BR-14, BR-164).

**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số deck con và số card sẽ mất (BR-04).
2. Người dùng xác nhận.
3. Hệ thống xoá deck; toàn bộ descendant, card, study state, study answers và
   study session bị xoá cascade (BR-03).

**Alternative flows:**
- **A1 — Root deck đã có lượt học:** phần chọn chế độ hiển thị ở trạng thái **khoá**,
  kèm giải thích và lối đi tới Reset learning progress (UC-07). Không ẩn đi — ẩn
  khiến người dùng tưởng tính năng không tồn tại (BR-13).
- **A2 — Sửa deck con:** không có phần chọn chế độ (BR-06).
- **A3 — Huỷ xác nhận xoá:** không xảy ra gì.
- **A4 — Xác nhận đúng chế độ deck đang chạy:** thao tác được chấp nhận và không
  làm gì người dùng thấy được (BR-12). Không seed lại cây, không đóng phiên đang
  mở — mất một phiên đang học cho một thay đổi bằng không là cái giá không ai
  đồng ý trả.

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách với
  thông báo nhẹ nhàng.
- **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên
  scheduler cũ và study state cũ.
- **E3 — Xoá thất bại:** hiện lỗi; deck còn nguyên vẹn, và `content_type` của
  deck cha cũng không đổi — cả hai nằm trong một transaction (BR-163).
- **E4 — Scheduler bị khoá trong lúc bảng chọn đang mở:** người dùng học xong một
  thẻ ở màn khác giữa lúc bảng chọn mở. Repository đọc lại `first_answered_at`
  **bên trong** transaction (BR-13) và từ chối; màn hình hiện lý do và lối đi tới
  Reset. Trạng thái vẽ trên màn hình MUST NOT là thứ quyết định thao tác có hợp lệ
  hay không.

**Postconditions:**
- Sau đổi chế độ: `scheduler_type` mới, mọi study state trong cây khởi tạo lại,
  `scheduler_generation` **không đổi** (chưa có gì để reset), `first_answered_at`
  vẫn NULL, và không còn phiên `in_progress` nào của cây (BR-164).
- Sau xoá: không còn deck con, card, study state, history hay session mồ côi.
- Sau xoá một deck con: nếu deck cha là **sub-deck** và vừa mất phần tử con cuối
  cùng, `content_type` của nó tự về `unset` trong cùng transaction (BR-163). Deck
  cha là root thì giữ `deck` (BR-58).

**Business rules:** BR-01, BR-03, BR-04, BR-06, BR-12, BR-13, BR-14, BR-163, BR-164
**UI states:** loaded · submitting · error

---

## UC-04 · Quản lý card trong deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Mở một deck có `content_type = 'card'`
**Preconditions:** Deck tồn tại và `content_type = 'card'` (BR-63)

**Main flow:**
1. Người dùng thấy danh sách card của deck.
2. Người dùng thêm card: nhập mặt trước và mặt sau.
3. Hệ thống validate (BR-07, BR-08).
4. Hệ thống tạo card **và** study state của nó trong cùng transaction, theo
   scheduler của root deck (tra qua `root_deck_id`) và generation hiện tại (BR-09).
5. Card xuất hiện; số card đến hạn của deck tăng.

Card đầu tiên của một deck `unset` được tạo qua UC-08, và chính nó xác lập
`content_type = 'card'`.

**Alternative flows:**
- **A1 — Sửa card:** nội dung đổi; study state và history **không** đổi (BR-10).
- **A2 — Xoá card:** hỏi xác nhận; xoá kèm study state và history của card đó.
  Nếu đó là card **cuối cùng**, deck atomically trở về `content_type = unset`
  trong cùng transaction (BR-163); sau đó người dùng quay về màn hình deck và
  lại chọn được tạo card hay tạo sub-deck. "Deck `card` rỗng" không còn là một
  trạng thái ổn định của hệ thống.
- **A3 — Deck còn card nhưng danh sách rỗng theo bộ lọc:** empty state của bộ
  lọc, không phải của deck.
- **A5 — Di chuyển thẻ sang deck khác:** chọn deck đích trong cùng root; thẻ giữ
  nguyên id, nội dung, study state, history, cờ và tag — chỉ đổi chỗ (BR-165).
  Deck nguồn mất thẻ cuối thì về `unset`, deck đích đang `unset` thì thành
  `card`, cùng transaction (BR-163).
- **A6 — Chọn nhiều thẻ:** long-press một thẻ hoặc dùng action **Select** trên
  app bar để vào chế độ chọn. Thanh hành động ngữ cảnh hiện số đã chọn và các
  thao tác hàng loạt: Move, Add tag, Flag, Remove flag, Delete. **Select all**
  chọn toàn bộ tập kết quả theo filter và search hiện tại, không chỉ phần đã
  tải (BR-167). Mỗi thao tác là all-or-nothing (BR-166).
- **A4 — Thêm liên tiếp nhiều card:** sau khi lưu, giữ form mở và xoá trống các ô.

**Error flows:**
- **E1 — Mặt trước hoặc mặt sau rỗng:** lỗi inline ở đúng ô đó.
- **E5 — Deck đích không hợp lệ:** picker chỉ liệt kê deck cùng root, không phải
  root, không phải loại `deck`, và không phải chính deck nguồn. Nếu một thao tác
  vẫn tới được repository với đích không hợp lệ — deep link, hoặc cây đổi giữa
  lúc mở picker và lúc xác nhận — nó bị từ chối kèm lý do có kiểu và không ghi
  gì (BR-165).
- **E6 — Một thẻ trong lô vi phạm:** cả lô rollback; danh sách và selection giữ
  nguyên, lỗi nêu rõ vì sao (BR-166).
- **E2 — Vượt 2000 ký tự:** lỗi inline, chặn nhập thêm.
- **E3 — Ghi thất bại:** hiện lỗi, giữ nội dung; không tạo card không có study
state.

**Postconditions:** Card tồn tại kèm đúng một study state, đúng scheduler và
đúng generation của root deck.

**Business rules:** BR-07, BR-08, BR-09, BR-10, BR-63, BR-163, BR-165, BR-166, BR-167
**UI states:** loading · loaded · empty · submitting · error

---

## UC-05 · Ôn tập một deck — luồng chính

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Người dùng bấm Study trên một deck. Đây là **cách duy nhất** một phiên được tạo — badge, danh sách và thông báo số đến hạn không tạo phiên (BR-101)
**Preconditions:** Deck tồn tại và có ít nhất một thẻ thuộc một trong hai tập của BR-142

Đây là luồng chạy hằng ngày và là vertical slice đầu tiên nên xây.

**Hai loại phiên, không phải một.** *Học mới* đưa thẻ chưa biết qua chuỗi stage và
kết thúc bằng việc khởi tạo lịch; *ôn tập* đưa thẻ đến hạn qua **một** cách hỏi
do người dùng chọn và cập nhật lịch. Chúng không bao giờ trộn thẻ (BR-142).

**Main flow:**
1. Người dùng bấm Study. Còn phiên `in_progress` của cùng ngày học thì màn chọn có
   thêm đường **tiếp tục phiên đó**; chọn một trong hai đường bên dưới sẽ đóng nó
   lại (BR-103). Hệ thống đếm hai tập, **không trộn** (BR-142):
   **học mới** = thẻ `learned_at IS NULL`; **ôn tập** = thẻ `learned_at IS NOT
   NULL AND due_at <= now`. Cả hai hiện kèm số lượng.
2. Tập ôn tập rỗng ⇒ lối đó không mở được, kèm thời điểm thẻ gần nhất đến hạn
   (BR-29, BR-145). Không có thao tác nào ôn sớm hơn hạn.
3. **Chọn Học mới** — hệ thống lấy tối đa `card_limit` thẻ chưa học, theo
   `new_card_order` của tùy chọn hiệu lực (BR-147, BR-148), rồi tạo
   `study_session` với `session_kind = 'learning'` và chuỗi stage của thuật toán
   (BR-109, BR-110). Người dùng **không chọn** stage.
4. **Chọn Ôn tập** — hệ thống hiện các mode chấm điểm của thuật toán: `eight_box`
   → `match`, `guess`, `recall`, `fill`; `sm2` → `self_assess` (BR-146). `browse`
   không có mặt. Mỗi mode hiện **số thẻ của riêng nó** (BR-154) — `fill` chỉ nhận
   thẻ có `example` — và mode không đủ dữ liệu bị vô hiệu hoá kèm lý do (BR-99,
   BR-153). Chỉ còn một mode thì vào thẳng, không hiện màn chọn. Sau khi
   chọn, hệ thống lấy **toàn bộ** thẻ đến hạn theo `due_at` tăng dần, tối đa
   `card_limit` (BR-23, BR-24), và tạo phiên với `session_kind = 'reviewing'`.
5. Cả hai loại phiên ghi `card_limit` đã dùng vào phiên (BR-139) và dựng hàng đợi
   trong cùng transaction (BR-102, BR-113).
6. Người dùng trả lời một thẻ. Nguồn của `action` tùy mode: `self_assess` lấy
   **trực tiếp từ người dùng** qua `supportedActions` — 2 nút với `eight_box`, 4 với
   `sm2` (BR-30); bốn mode chấm điểm chấm ra kết quả **nhị phân** rồi ánh xạ theo
   BR-107 (BR-106). Hệ thống **so `session.scheduler_generation` với generation hiện
   tại của root** (BR-46); lệch thì đi E4.
7. Hệ thống xác định `kind` và ghi tường minh (BR-76):
   - phiên `learning` ⇒ `learning`, hoặc `relearning` nếu là lượt lặp trong round;
     **không đổi lịch** (BR-141, BR-143, BR-144);
   - phiên `reviewing` ⇒ `scheduled` ở lượt đầu của thẻ, `relearning` ở các lượt
     lặp (BR-141).
8. Lượt `scheduled` tính trạng thái mới bằng thuật toán (BR-15/BR-16 hoặc
   BR-18/BR-19) và cập nhật study state, `answer_count`, `lapse_count`. Lượt
   `learning` và `relearning` chỉ cập nhật `last_answered_at`.
9. Hệ thống ghi một dòng `study_answers` kèm `kind` (BR-21) — ngay lập tức
   (BR-25).
10. **Chỉ ở phiên `learning`:** thẻ đi hết **stage cuối mà chính nó tham gia** — stage
    bỏ qua nó theo BR-114 không được tính — ⇒ hệ thống đặt `learned_at`
    và khởi tạo lịch ở mức thấp nhất — `eight_box` box 1, `sm2` interval 1 — với
    `due_at` là đầu ngày học kế tiếp (BR-144, BR-105). Đây là **một sự kiện,
    không phải một lượt đánh giá**, nên không có `action` nào được ghi.
11. Nếu đây là thẻ **đầu tiên hoàn tất chuỗi học mới** của root ở generation này,
    hệ thống đặt `first_answered_at` → thuật toán bị khoá từ đây (BR-13).
12. Nếu action khác `forgotten`/`again`, card rời hàng đợi (BR-28).
13. Hết hàng đợi: session → `completed`, `end_reason = NULL`, `ended_at` được đặt
    (BR-81). Hiện tổng kết.

**Alternative flows:**
- **A1 — Thẻ trả lời sai:** cách nó quay lại **tùy mode**, không tùy loại phiên.
  Với `self_assess`: quay lại trong cùng hàng đợi sau ít nhất 3 thẻ khác, trần 3
  lượt (BR-26, BR-104). Với bốn mode chấm điểm: thẻ ở lại tập không đạt và quay lại
  ở **round sau**, không trần (BR-115, BR-119) — xem A0c.
- **A0 — Hết hàng đợi của một stage (chỉ phiên `learning`):** hệ thống chuyển
  `current_mode` sang stage kế trong `stageSequence` và chạy tiếp trên **cùng tập
  thẻ**, với thứ tự xoáo riêng (BR-113). Hết stage cuối mới là hết phiên (BR-81).
  Phiên `reviewing` chỉ có một mode, nên hết hàng đợi là hết phiên.
- **A0c — Hết một round của stage chấm điểm:** tập thẻ không đạt rỗng thì stage
  hoàn tất (BR-119); còn thẻ thì dựng round mới **chỉ từ tập đó**, với thứ tự xoáo
  riêng (BR-115, BR-117). Thẻ từng sai trong round vẫn thuộc tập đó kể cả khi sau
  đó làm đúng (BR-116). Không có trần số round.
- **A0b — Thẻ không đủ dữ liệu cho stage đang chạy:** bỏ qua **có ghi nhận** ở stage
  đó, không xoá khỏi deck, và vẫn xuất hiện ở các stage khác mà nó đủ dữ liệu
  (BR-114) — ví dụ thẻ không có `example` thì vắng ở `fill` nhưng có ở `guess`.
- **A2b — Thẻ chạm trần 3 lượt `relearning` ở `self_assess`:** thẻ rời hàng đợi dù
  lượt cuối vẫn là `forgotten`/`again`, và hệ thống bật cờ đánh dấu (BR-104).
  Trong phiên `reviewing`, lịch đã được đặt ở lượt `scheduled` đầu nên thẻ vẫn đến
  hạn lại sớm. Trong phiên `learning`, thẻ chưa có lịch và cũng chưa `learned_at`,
  nên nó ở lại tập học mới — cờ là dấu cho lần sau. Cờ chỉ được bật, không bao
  giờ tự tắt (BR-92).
- **A2 — Card quay lại được đánh giá lần nữa:** lượt đó là `relearning` (BR-78).
  Ghi history và cập nhật `last_answered_at`, nhưng không đổi lịch. Đánh giá khác
  `forgotten`/`again` thì rời hàng đợi; lại `forgotten`/`again` thì quay lại lần
  nữa.
- **A3 — Thoát giữa phiên:** session → `abandoned`, `end_reason = user_exit`,
  `ended_at` được đặt (BR-82). Mọi đánh giá đã ghi **vẫn giữ** (BR-25, BR-86).
  Hàng đợi **được lưu** (BR-102), nên xem A3b.
- **A3b — Mở lại app khi còn phiên `in_progress`:** cùng ngày học thì cho tiếp
  đúng hàng đợi đó — đúng thẻ đang dở, đúng thứ tự, đúng số lượt đã dùng. Ngày
  học khác thì phiên đó chuyển `abandoned` với `end_reason = interrupted`, và
  người dùng dựng phiên mới (BR-103). App bị hệ điều hành thu hồi rơi vào
  đúng nhánh này, và nó khác `user_exit`: người dùng không hề bỏ cuộc.
- **A4 — Còn card quá hạn ngoài giới hạn 50:** ở tổng kết nói rõ còn bao nhiêu và
  cho phép bắt đầu phiên tiếp theo ngay.
- **A5 — Xoá deck đang ôn dở:** kết thúc phiên, quay về danh sách.

**Error flows:**
- **E1 — Không còn card nào đến hạn lúc bắt đầu:** empty state tích cực (BR-29),
  kèm thời điểm card gần nhất đến hạn. **Không** phải màn hình lỗi, và **không**
  tạo session.
- **E2 — Ghi đánh giá thất bại nhưng còn tiếp tục được:** hiện lỗi ngay, **không**
  chuyển sang card tiếp theo. Người dùng thử lại action đó. Chuyển tiếp khi chưa
  ghi được là âm thầm mất tiến độ.
- **E3 — Lỗi ghi không thể tiếp tục:** session → `failed`,
  `end_reason = persistence_error` (BR-85). Các lượt đã ghi thành công **vẫn giữ**
  (BR-86). Hiện lỗi và đưa người dùng về danh sách deck.
- **E4 — Generation của session đã lỗi thời** (root bị reset ở màn khác trong lúc
  phiên đang mở): **từ chối ghi**, session → `invalidated`,
  `end_reason = stale_generation` (BR-84). Thông báo phiên đã hết hiệu lực vì tiến
  độ học vừa được đặt lại, đóng phiên và quay về danh sách. **Không** ghi bất kỳ
  phần nào của đánh giá đó.
- **E5 — Đọc card thất bại:** màn hình lỗi có nút thử lại.

**Postconditions:**
- Mỗi card đã đánh giá có trạng thái lịch đúng loại lượt, đúng scheduler và đúng
  generation.
- Mỗi lượt đánh giá có đúng một dòng `study_answers` mang `kind`,
  `scheduler_type` và `scheduler_generation` tại thời điểm đó.
- `first_answered_at` của root khác NULL sau khi **thẻ đầu tiên hoàn tất chuỗi
  học mới** (bước 10–11, BR-13, BR-144) — **không** phải sau lượt `scheduled`
  đầu tiên. Một phiên `reviewing` chỉ chạy được trên thẻ đã có `learned_at`,
  nên tới lúc đó cột này đã được đặt rồi.
- `study_sessions.status` và `end_reason` phản ánh đúng cách phiên kết thúc, theo
  ma trận ở `data-model.md`.
- Nếu E4 xảy ra, **không** có dòng history nào được ghi cho lượt đó.

**Business rules:** BR-13, BR-15…BR-30, BR-45, BR-46, BR-75…BR-86
**UI states:** loading · loaded (mặt trước) · loaded (đã lật) · submitting ·
empty · error

`submitting` tách khỏi `loaded` là đúng nguyên tắc "dữ liệu và trạng thái tác vụ
là hai chuyện": trong lúc ghi đánh giá, nội dung card vẫn hiện, chỉ các nút bị
khoá để tránh bấm đúp.

---

## UC-06 · Xem danh sách deck với tiến độ

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Mở app, hoặc quay về từ màn khác
**Preconditions:** Không có

**Main flow:**
1. Hệ thống lấy toàn bộ root deck kèm số card đến hạn — **một query gộp** theo
   `root_deck_id`, không phải N+1 query và không duyệt cây trong Dart.
2. Người dùng thấy mỗi deck với tên, tổng số card trong cây, **hai** số của
   BR-150 — card chưa học (New) và card đến hạn (Due), không bao giờ gộp — và
   chế độ ôn tập đang dùng.
3. Deck có card đến hạn được làm nổi bật bằng **cả biểu tượng lẫn chữ**, không
   chỉ bằng màu. Deck tile hiển thị **total Due + New**; biểu tượng lớn phân ba
   trạng thái lịch theo BR-161 — chưa đến hạn (outlined, neutral), đến hạn hôm
   nay (filled, vai time-pressure vàng/streak), quá hạn (missed + badge số ngày,
   cặp error container đỏ) — khác nhau bằng hình dạng/fill/badge chứ không chỉ
   màu. Hero level summary breakdown thành bốn tập rời nhau
   Overdue/Due today/New/Scheduled theo BR-162 — lưới 2×2, mỗi hàng căn theo
   alphabetic baseline; Scheduled là tập trung tính, không actionable và không
   bao giờ là primary metric.
4. Mở một deck hiển thị nội dung theo `content_type`: danh sách deck con, hoặc
   danh sách card, không bao giờ cả hai (BR-65).

**Alternative flows:**
- **A1 — Chưa có deck nào:** empty state với hai lối đi — thư viện starter (UC-01)
  hoặc tạo deck mới (UC-02).
- **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift
  (AD-01), không cần refresh thủ công.
- **A3 — Cây sâu nhiều cấp:** điều hướng xuống từng cấp; số liệu gộp luôn tính
  theo `root_deck_id` (BR-56, BR-57).

**Error flows:**
- **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại.

**Postconditions:** Không đổi gì — use case chỉ đọc.

**Business rules:** BR-142 — hai tập "chưa học" và "đến hạn" phải khớp **hệt** UC-05, nếu
không con số ở danh sách sẽ lệch với số card thực sự ôn được. Dùng chung một
named query. Ngoài ra BR-56, BR-57, BR-65.
**UI states:** loading · loaded · empty · error

---

## UC-07 · Reset learning progress

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn "Đặt lại tiến độ học" trên một **root deck** — thường từ chỗ
giải thích vì sao chế độ ôn tập đang bị khoá (UC-03 A1)
**Preconditions:** Root deck tồn tại

**Main flow:**
1. Người dùng chọn đặt lại tiến độ học.
2. Hệ thống hiện xác nhận nêu rõ hai danh sách (BR-50):
   - **Giữ nguyên:** deck, toàn bộ cây deck con, flashcard, media, tag, mọi nội
     dung, và lịch sử ôn tập cũ (để tham khảo).
   - **Mất:** lịch ôn hiện tại, ngày đến hạn, box / ease factor / interval, trạng
     thái thành thạo, phiên đang dở, và **dấu đã học xong lần đầu** — mọi thẻ
     trở lại tập Học mới và đi lại chuỗi stage (BR-152, BR-142).
3. Người dùng có thể chọn **chế độ ôn tập mới** ngay trong bước này — đây là mục
   đích chính của thao tác.
4. Người dùng xác nhận.
5. Hệ thống thực hiện, **trong một transaction duy nhất** (BR-47):
   - tăng `scheduler_generation` của root deck (BR-40);
   - đặt `scheduler_type` / `version` / `config` mới nếu người dùng đã chọn;
   - đặt `first_answered_at = NULL` → scheduler mở khoá (BR-44);
   - khởi tạo lại study state của **toàn bộ** card trong cây (mọi cấp), theo
     scheduler mới và generation mới (BR-42, BR-09);
   - mọi study session `in_progress` của cây → `invalidated`,
     `end_reason = scheduler_reset`, `ended_at` được đặt (BR-83);
   - **không** đụng tới `study_answers` (BR-43), và **không** đụng tới
     `content_type` hay cấu trúc cây (BR-41).
6. Người dùng quay về deck; toàn bộ card đã trở lại trạng thái Học mới
   (`learned_at`/`due_at` về NULL) và chưa thuộc tập Due/Reviewing; scheduler
   được mở khoá lại, lịch sử trả lời cũ vẫn được giữ.

**Alternative flows:**
- **A1 — Reset mà không đổi chế độ:** hợp lệ. Dùng khi người dùng chỉ muốn học lại
  từ đầu.
- **A2 — Reset trên deck chưa có lượt học:** vẫn cho phép, nhưng nêu rõ là không có
  gì để mất.
- **A3 — Huỷ ở bước xác nhận:** không xảy ra gì.
- **A4 — Reset trên deck con:** không có thao tác này. Reset chỉ tồn tại ở root vì
  scheduler và generation thuộc root (BR-05).

**Error flows:**
- **E1 — Thất bại giữa chừng:** transaction rollback (BR-47). Root giữ nguyên
  generation cũ, scheduler cũ và toàn bộ state cũ. **Không** có trạng thái nửa vời
  với card thuộc hai generation.
- **E2 — Người dùng có phiên đang mở ở màn khác:** phiên đó đã bị chuyển
  `invalidated` ở bước 5. Lần bấm đánh giá tiếp theo trong phiên đó bị từ chối
  (UC-05 E4, BR-84).

**Postconditions:**
- `scheduler_generation` tăng đúng 1.
- Mọi study state trong cây có generation mới, scheduler mới, `due_at = NULL`.
- `first_answered_at IS NULL`.
- Không còn session `in_progress` nào của cây.
- `study_answers` cũ còn nguyên, mang generation cũ (BR-43).
- Cấu trúc cây và `content_type` không đổi (BR-41).
- Bất biến BR-48 và BR-49 giữ nguyên.

**Business rules:** BR-40…BR-50, BR-83
**UI states:** loaded · submitting · error

---

## UC-08 · Tạo phần tử con và xác lập `content_type`

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Bấm Create bên trong một deck
**Preconditions:** Deck tồn tại

Đây là use case định hình toàn bộ cấu trúc cây, và là chỗ dễ cài sai nhất vì nút
Create có ba hành vi khác nhau tuỳ trạng thái deck.

**Main flow:**
1. Người dùng bấm Create trong một deck.
2. Hệ thống quyết định lựa chọn hiển thị:

   | Deck | Lựa chọn hiện ra |
   |---|---|
   | root deck (`content_type = 'deck'`, bất biến) | **chỉ** Create deck (BR-59) |
   | deck con, `content_type = 'unset'` | Create card **và** Create deck (BR-61) |
   | deck con, `content_type = 'card'` | **chỉ** Create card (BR-66) |
   | deck con, `content_type = 'deck'` | **chỉ** Create deck (BR-66) |

3. Người dùng chọn một hành động và nhập nội dung.
4. Hệ thống thực hiện **trong một transaction** (BR-62):
   - nếu deck đang `unset`: đặt `content_type` theo hành động đã chọn;
   - tạo phần tử con: card (kèm study state, BR-09) hoặc deck con mới với
     `content_type = 'unset'`, `parent_deck_id` = deck hiện tại,
     `root_deck_id` = root của deck hiện tại (BR-56), và **không** có cột
     scheduler (BR-06).
5. Từ đây nút Create trong deck này chỉ hiện hành động tương ứng (BR-66).

**Alternative flows:**
- **A1 — Deck đã `card`:** không có lựa chọn tạo deck con, ở bất kỳ đâu trong UI
  (BR-63).
- **A2 — Deck đã `deck`:** không có lựa chọn tạo card (BR-64).
- **A3 — Phần tử con cuối cùng rời đi:** xoá card cuối, xoá deck con cuối hoặc
  di chuyển deck con cuối sang cha khác đều đưa `content_type` của sub-deck về
  `unset`, trong cùng transaction với mutation đó (BR-163). Không có thao tác
  reset thủ công nào, và không cần có.
- **A4 — Huỷ giữa chừng:** không tạo gì và **không** xác lập `content_type` —
  `content_type` chỉ đổi cùng với việc phần tử con thực sự được tạo (BR-62).

**Error flows:**
- **E1 — Validate thất bại** (tên deck rỗng, card thiếu mặt): lỗi inline; không
  tạo gì và không đổi `content_type`.
- **E2 — Ghi thất bại giữa chừng:** transaction rollback. Deck giữ nguyên
  `content_type` cũ và không có phần tử con nửa vời (BR-62) — chiều xoá cũng
  vậy: mutation và thay đổi type cùng sống hoặc cùng chết (BR-163).
- **E3 — Cố tạo card trong root deck:** không có đường nào tới được trạng thái
  này qua UI (BR-59). Nếu xảy ra qua deep link hoặc lỗi lập trình, từ chối và log
  — đây là vi phạm BR-58 và validation phải bắt được.
- **E4 — Deck cha đã ở cấp 10:** tạo deck con bị chặn trước khi ghi (BR-55).
  Không tạo gì và không đổi `content_type` của deck cha — kể cả khi nó đang
  `unset`. Tạo card không bị giới hạn này: card không thêm cấp cho cây.

**Postconditions:**
- Deck có `content_type` khác `unset`, khớp với loại phần tử con vừa tạo.
- Deck không đồng thời chứa card và deck con (BR-65).
- Deck con mới có `root_deck_id` đúng bằng root của cha (BR-56, BR-72).

**Business rules:** BR-09, BR-55, BR-56, BR-58…BR-66, BR-72, BR-163
**UI states:** initial · submitting · error

---

## UC-09 · Di chuyển deck trong cây

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn di chuyển một deck sang deck cha khác
**Preconditions:** Deck nguồn và deck đích tồn tại

**Main flow:**
1. Người dùng chọn deck nguồn và deck đích.
2. Hệ thống kiểm tra, theo thứ tự:
   - đích không phải chính deck nguồn hoặc descendant của nó (BR-70);
   - đích có `content_type = 'deck'` hoặc `'unset'` (BR-64) — không thể đưa deck
     vào một deck chỉ chứa card;
   - root của đích có cùng `scheduler_type` và `scheduler_generation` với root
     của nguồn (BR-74);
   - độ sâu sau move không vượt giới hạn (BR-55): với `targetDepth` là cấp của
     deck đích (root là cấp 1) và `subtreeHeight` là chiều cao subtree nguồn
     (deck nguồn tính là 1), MUST có `targetDepth + subtreeHeight <= 10`.
3. Hệ thống thực hiện **trong một transaction** (BR-71):
   - đặt `parent_deck_id` của deck nguồn thành deck đích;
   - cập nhật `root_deck_id` cho **toàn bộ subtree** của deck nguồn;
   - nếu đích đang `unset`, đặt `content_type = 'deck'` (BR-62);
   - nếu deck cha **cũ** là sub-deck và vừa mất phần tử con cuối cùng, đặt
     `content_type` của nó về `unset` (BR-163); cha cũ là root thì giữ `deck`.
4. Cây được vẽ lại.

**Alternative flows:**
- **A1 — Di chuyển trong cùng một cây (cùng root):** `root_deck_id` không đổi,
  nhưng vẫn phải chạy trong transaction cùng với việc đổi `parent_deck_id`.
- **A2 — Di chuyển lên thành root deck:** ngoài phạm vi MVP — deck nguồn sẽ cần
  scheduler riêng, tức là một quyết định mới, không phải một phép di chuyển.

**Error flows:**
- **E1 — Đích là chính nó hoặc descendant:** chặn, lỗi rõ ràng "Không thể di
  chuyển deck vào chính nó" (BR-70). Đây là phép kiểm tra chống cycle (BR-69).
- **E2 — Đích có `content_type = 'card'`:** chặn, giải thích deck đích chỉ chứa
  card (BR-64).
- **E3 — Root đích khác scheduler hoặc generation:** **chặn**, và đề nghị đặt lại
  tiến độ học một cách tường minh (BR-74). Không im lặng chuyển đổi state — không
  có ánh xạ nào có cơ sở giữa box và ease factor (BR-73).
- **E4 — Thất bại giữa chừng:** transaction rollback (BR-71) — con trỏ cha, con
  trỏ root của cả subtree, `content_type` của đích **và** `content_type` của cha
  cũ cùng quay lại nguyên trạng (BR-163). Không có descendant nào trỏ sai root
  (BR-72).
- **E5 — Vượt độ sâu tối đa:** `targetDepth + subtreeHeight > 10` → chặn trước
  khi ghi (BR-55). Không đổi `parent_deck_id`, `root_deck_id`, `content_type`
  của đích hay bất kỳ timestamp nào.

**Postconditions:**
- Cây không có cycle (BR-69).
- Mọi deck trong subtree đã di chuyển có `root_deck_id` đúng bằng root mới
  (BR-56, BR-72).
- Không deck nào đồng thời chứa card và deck con (BR-65).
- Deck đích `unset` nhận phần tử con đầu tiên thành `deck`; cha cũ là sub-deck
  mất phần tử con cuối thành `unset`; cha cũ còn sibling giữ `deck` (BR-163).
- Không có card study state nào lệch scheduler hoặc generation so với root
  (BR-48, BR-49).

**Business rules:** BR-55, BR-56, BR-62, BR-64, BR-69…BR-74, BR-163
**UI states:** loaded · submitting · error

---

## UC-10 · Import card hàng loạt vào một deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn "Import cards" từ card list của một deck loại card, từ empty
state của card list, hoặc từ lựa chọn tạo phần tử con của một deck `unset`
**Preconditions:** Deck đích tồn tại và là sub-deck `unset` hoặc `card` (BR-168)

**Main flow:**
1. Người dùng mở màn import; hệ thống hiển thị deck đích, số card hiện có và
   ba bước Source → Preview → Import.
2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV.
3. Người dùng bấm Preview; hệ thống parse nguồn trong bộ nhớ (BR-173) — không
   ghi gì vào database.
4. Hệ thống mặc định coi hàng đầu là header và tự map các cột trùng tên
   (front, back, example, hint, pronunciation, tags — không phân biệt hoa
   thường); người dùng chỉnh mapping nếu cần. `front` và `back` bắt buộc phải
   được map; một cột nguồn không map vào hai đích (BR-169).
5. Hệ thống validate toàn bộ hàng bằng đúng các rule của card (BR-169), đánh
   dấu trùng lặp theo BR-170, và hiển thị: tổng số hàng, số sẵn sàng, số trùng,
   số invalid kèm lý do, số hàng trống đã bỏ qua, cùng các hàng đầu tiên.
6. Người dùng bấm Continue rồi xác nhận ở bước Import — màn xác nhận nêu deck
   đích, số card sẽ ghi, số trùng bị bỏ/ghi, số invalid bị loại.
7. Hệ thống ghi toàn bộ trong một transaction (BR-171): card, study state mới
   cho từng card, tag, và `content_type` nếu deck đang `unset` (BR-172).
8. Hệ thống hiện kết quả — số đã ghi, số trùng bỏ qua, số invalid bị loại — với
   hai lối ra: View cards về card list (danh sách tự cập nhật qua stream),
   hoặc Import another file giữ deck đích và làm lại từ bước Source.

**Alternative flows:**
- **A1 — Dán văn bản:** ở bước Source người dùng dán các hàng CSV/TSV vào ô
  nhập; parse chỉ chạy khi bấm Preview, và văn bản giữ nguyên khi parse lỗi.
- **A2 — XLSX nhiều sheet:** hệ thống mặc định chọn sheet không rỗng đầu tiên
  và cho người dùng đổi sheet; đổi sheet chạy lại bước 4–5.
- **A3 — Không có header:** người dùng tắt "First row contains headers"; các
  cột hiển thị tên vị trí ổn định (Column A, Column B, …) và hàng đầu được
  validate như dữ liệu.
- **A4 — Bao gồm trùng lặp:** người dùng bật "Include duplicates"; số sẵn sàng
  gồm cả các hàng trùng, và commit ghi chúng như card mới (BR-170).
- **A5 — Đổi file:** người dùng thay file đã chọn; hủy hộp chọn file không
  phải lỗi và không xoá lựa chọn trước đó.

**Error flows:**
- **E1 — File không đọc được:** file hỏng, có mật khẩu, đuôi không hỗ trợ hoặc
  encoding không phải UTF-8/UTF-8 BOM (BR-173) → lỗi có kiểu kèm hướng dẫn
  (export lại UTF-8); nguồn đã chọn trước đó giữ nguyên.
- **E2 — Nguồn rỗng:** file/sheet/văn bản không có hàng dữ liệu nào → thông báo
  rõ ở bước Preview; không đi tiếp được.
- **E3 — Không còn hàng hợp lệ:** sau validate và policy trùng lặp, số sẽ ghi
  bằng 0 → Continue bị khoá; không có mutation nào (BR-171).
- **E4 — Deck đích không còn hợp lệ lúc ghi:** deck biến mất, thành root-level
  hoặc đã giữ deck con → transaction từ chối bằng lý do có kiểu (BR-168), không
  ghi gì; preview và mapping giữ nguyên.
- **E5 — Commit thất bại giữa chừng:** một write lỗi → rollback toàn bộ
  (BR-171); màn import giữ nguyên nguồn, mapping và preview, hiện Try again.

**Postconditions:** Mọi card được ghi có đúng một study state mới theo scheduler
của root (BR-171); card, tiến độ và history đã có từ trước không bị sửa;
`content_type` của deck đích phản ánh đúng nội dung sau import (BR-172).

**Business rules:** BR-07, BR-08, BR-09, BR-58, BR-62, BR-64, BR-93, BR-94,
BR-95, BR-168, BR-169, BR-170, BR-171, BR-172, BR-173

**UI states:** initial (Source trống) · source đã chọn · parsing · parse error ·
preview loaded (đủ valid/invalid/duplicate/blank) · preview empty (E2/E3) ·
confirm · submitting · commit error · result. Không có state "refreshing" —
nguồn chỉ parse lại khi người dùng đổi nguồn, sheet, header hoặc bấm lại
Preview.

## UC-11 · Export card của một deck ra file

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn `Export cards` trong overflow menu của card list, hoặc
`Export selected` trên thanh hành động của chế độ chọn (UC-04 A6)
**Preconditions:** Deck đang mở là sub-deck loại `card` và có ít nhất một card;
với lối chọn nhiều thì tập chọn không rỗng (BR-174)

**Main flow:**
1. Người dùng mở export từ một trong hai entry point; hệ thống mở một sheet và
   hiển thị **scope đã cố định, chỉ đọc**: `All N cards in this deck` hoặc
   `N selected cards`. Sheet không cho đổi scope — scope là hệ quả của lối vào
   (BR-174).
2. Hệ thống hiển thị ba format — CSV (mặc định, gắn nhãn Recommended), TSV,
   XLSX — cùng một dòng nói file chứa nội dung và tag, và một dòng nói tiến độ
   học và lịch sử **không** nằm trong file (BR-175).
3. Người dùng chọn format nếu muốn khác mặc định, rồi bấm `Export N cards`.
4. Hệ thống đọc một snapshot nhất quán gồm tên deck, nội dung sáu field và tag
   theo thứ tự xác định (BR-177), không ghi gì vào database (BR-178).
5. Hệ thống encode snapshot thành artifact theo format đã chọn — sáu header
   canonical, ô rỗng cho field trống, BOM cho CSV/TSV, ô text cho XLSX
   (BR-179) — và đặt tên file từ tên deck đã sanitize cộng ngày (BR-180).
6. Hệ thống ghi artifact vào vùng riêng tạm thời của ứng dụng rồi bàn giao cho
   share sheet của hệ điều hành (BR-181).
7. Người dùng chọn đích ở share sheet. Hệ thống đóng sheet export và báo đã bàn
   giao file cho hệ thống — **không** khẳng định đã lưu ở đâu (BR-181).

**Alternative flows:**
- **A1 — Scope là tập đã chọn:** vào từ thanh hành động chọn nhiều; file chứa
  đúng tập id đã materialize, id trùng chỉ xuất hiện một lần, và thứ tự vẫn là
  `created_at ASC` chứ không phải thứ tự chạm (BR-174, BR-177). Selection giữ
  nguyên sau khi export xong (BR-178).
- **A2 — Đổi format:** chọn TSV hoặc XLSX; canonical schema, thứ tự card và ô
  tags không đổi, chỉ lớp mã hoá đổi (BR-179).
- **A3 — Đóng share sheet:** người dùng thoát share sheet mà không chọn đích.
  Đây là **cancel**: không báo lỗi, sheet export trở lại trạng thái ban đầu với
  scope và format đang chọn, và không có tuyên bố nào về việc đã lưu (BR-181).
- **A4 — Bấm export lần thứ hai khi đang tạo file:** hệ thống MUST bỏ qua lần
  bấm sau; primary action bị khoá cho tới khi lần đầu kết thúc, và không có hai
  artifact nào được tạo cho một lần mở sheet.
- **A5 — Huỷ trước khi submit:** `Cancel`, chạm ra ngoài sheet hoặc Android Back
  đóng sheet, không tạo file, không đụng selection.

**Error flows:**
- **E1 — Nền tảng không có share sheet:** hệ thống báo rằng chia sẻ không khả
  dụng trên thiết bị này, giữ sheet mở với scope và format đang chọn, và không
  để lại artifact nào.
- **E2 — Lỗi từ nền tảng khi chia sẻ:** exception của platform channel map
  thành lý do có kiểu; thông báo MUST NOT lộ đường dẫn, tên file hay nội dung
  card (BR-180, BR-181); Retry giữ nguyên scope và format.
- **E3 — Đọc dữ liệu thất bại:** repository lỗi khi lấy snapshot → lý do có
  kiểu, không có file, không có mutation (BR-178); Retry chạy lại từ bước 4.
- **E4 — Encode thất bại:** encoder lỗi → lý do có kiểu phân biệt được với lỗi
  đọc, không có artifact một phần nào được bàn giao.
- **E5 — Không có gì để export:** deck rỗng hoặc tập chọn rỗng → domain từ chối
  bằng lý do có kiểu (BR-174). Entry point không hiện khi deck rỗng, nên đây là
  chặn tầng dưới cho deep link và cho cây đổi sau khi sheet đã mở.
- **E6 — Id đã chọn không còn hợp lệ:** một id trong tập chọn đã bị xoá hoặc đã
  chuyển sang deck khác → **cả request** thất bại có kiểu, không sinh file một
  phần (BR-174); thông báo mời người dùng chọn lại.

**Postconditions:** Database không đổi — nội dung, timestamp, `content_type`,
study state, history, cờ và tag đều nguyên vẹn (BR-178). Artifact chỉ chứa sáu
field nội dung (BR-175) và chỉ tồn tại ở vùng riêng tạm thời cho tới khi người
dùng chọn đích ở share sheet (BR-181).

**Business rules:** BR-51, BR-52, BR-54, BR-93, BR-94, BR-163, BR-167, BR-174,
BR-175, BR-176, BR-177, BR-178, BR-179, BR-180, BR-181

**UI states:** initial (scope + format, primary bật) · generating (primary khoá,
Cancel còn dùng được) · share requested · dismissed (về initial, không lỗi) ·
unavailable/platform error · repository error · encoder error · invalid scope
(rỗng hoặc id đã cũ). Không có state `loading` khi mở sheet — scope và số card
đã có sẵn từ màn gọi; và không có state `empty`, vì scope rỗng là lỗi (E5) chứ
không phải một màn hình trống.

## UC-12 · Xem tiến độ học

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chạm tab **Tiến độ / Progress** ở bottom navigation, hoặc mở deep
link `/progress`
**Preconditions:** Không có. Màn hình mở được kể cả khi chưa từng học một lượt
nào — trạng thái "chưa có gì" là một mặt hợp lệ, không phải lỗi.

**Main flow:**
1. Người dùng mở tab Progress. Hệ thống chụp **một** snapshot của
   `clockProvider` và `utcOffsetProvider` rồi dựng ranh giới ngày theo BR-202.
2. Hệ thống mở **một** stream đọc lịch sử học, gộp ngay trong SQLite thành các
   hàng *card-day* rồi thành các hàng *active-day* (BR-200); không tải hàng
   `study_answers` thô lên tầng trên và không đọc từng ngày một.
3. Trong lúc chờ emission đầu tiên, màn hình hiện trạng thái loading có nhãn
   cho screen reader.
4. Emission tới. Hệ thống hiển thị ba khối, cùng một snapshot:
   **Current streak** (BR-187), **Today** với tổng số card cùng phân rã
   Learning/Reviewing (BR-185), và **Last 7 days** đúng bảy cột theo thứ tự
   cũ → mới, ngày trống là 0 (BR-186).
   Ba khối này **không chiếm cả màn**: `/progress` là một màn duy nhất, và
   chúng là phần đầu của cấp thư viện trong UC-13 — cùng một vùng cuộn, dưới
   chúng là bộ chọn khoảng, bảng tổng và danh sách deck. Bố cục là việc của
   `wireframes/m99-progress-by-deck.md` §1; ở đây chỉ ghi rằng hai use case
   dùng chung một màn, vì đọc riêng UC-12 sẽ hiểu nhầm thành một tab ba khối.
5. Người dùng đọc xong và rời tab. Hệ thống không ghi gì trong toàn bộ luồng
   (BR-190).

**Alternative flows:**
- **A1 — Hôm nay chưa học nhưng hôm qua có:** Today hiện 0, và streak **vẫn
  giữ** chuỗi kết thúc ở hôm qua (BR-187). Copy nói rõ đây là chuỗi đang giữ,
  không phải chuỗi đã mất.
- **A2 — Chưa từng học lượt nào:** cả ba khối rỗng. Hệ thống hiện một mặt
  empty của cả màn với CTA thật dẫn sang branch Study, không phải một màn ba
  khối toàn số 0.
- **A3 — Có một lượt mới ghi trong lúc màn đang mở:** người dùng học ở tab khác
  rồi quay lại, hoặc một answer được ghi khi màn còn sống — các con số tự cập
  nhật, không cần Retry và không nháy toàn trang (BR-189).
- **A4 — Local midnight trôi qua trong lúc màn đang mở:** cửa sổ bảy ngày trượt
  một ngày, Today về 0, và streak chuyển sang nhánh "hôm qua active" của
  BR-187 — tất cả không cần thao tác nào (BR-189).
- **A5 — Reset learning progress ở màn khác rồi quay lại:** mọi con số giữ
  nguyên, vì reset không đụng lịch sử (BR-188).
- **A6 — Xoá một card hoặc một deck ở màn khác rồi quay lại:** hoạt động của
  các card đã xoá biến mất khỏi mọi ngày, kể cả ngày quá khứ (BR-188).
- **A7 — Chỉ lướt `browse` rồi thoát:** không có gì đổi — `browse` không ghi
  answer nên không tạo hoạt động (BR-201).

**Error flows:**
- **E1 — Đọc lịch sử thất bại:** repository map exception thành `Failure`; màn
  hình hiện mặt lỗi kèm `Retry`. Thông báo MUST NOT lộ SQL, tên bảng hay nội
  dung card (BR-52).
- **E2 — Retry vẫn lỗi:** màn hình ở lại mặt lỗi; MUST NOT tự thử lại vòng lặp
  và MUST NOT ghi gì (BR-190).

**Postconditions:** Database không đổi ở mọi nhánh, kể cả nhánh lỗi và nhánh
Retry (BR-190). Không session nào được mở, tiếp tục hay đóng.

**Business rules:** BR-52, BR-105, BR-111, BR-200, BR-201, BR-202, BR-185,
BR-186, BR-187, BR-188, BR-189, BR-190, BR-191

**UI states:** loading · loaded-normal (có hoạt động trong cửa sổ) ·
loaded-today-zero-streak-retained (A1) · empty-lifetime + CTA sang Study (A2) ·
error + Retry (E1/E2). Live refresh (A3) và midnight rollover (A4) là **chuyển
tiếp giữa hai loaded**, không phải state thứ sáu; luật cấm hạ màn về loading khi
đã có dữ liệu nằm ở BR-189.

## UC-13 · Xem tiến độ theo deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Mở tab Progress, hoặc chạm một hàng deck trên màn hình tiến độ
**Preconditions:** Không có. Thư viện rỗng và thư viện chưa học lần nào đều là
trạng thái hợp lệ và có màn hình riêng.

**Main flow:**
1. Người dùng mở tab Progress. Hệ thống hiển thị **cấp thư viện** ngay dưới
   ba khối tổng quan của UC-12 — cùng một màn `/progress`, một vùng cuộn: bộ
   chọn khoảng 7/30 ngày, một bảng tổng cho toàn bộ dữ liệu, và một hàng cho
   mỗi root deck (BR-194). Chỉ cấp thư viện có phần đầu đó; `/progress/:deckId`
   là cấp của một deck và mở thẳng vào bộ chọn.
2. Mỗi hàng mang tên deck, đường dẫn của nó khi có, và bốn số của khoảng đang
   chọn: số thẻ đã học, số ngày có học, số card-day học mới và số card-day ôn
   tập (BR-192, BR-193, BR-196). Số của một hàng phủ **toàn bộ subtree** của
   deck đó (BR-195).
3. Danh sách sắp theo số thẻ đã học giảm dần, tie-break bằng tên đã fold rồi
   id; deck chưa học gì vẫn hiện và đứng cuối (BR-197).
4. Người dùng chạm `30 ngày`. Mọi số trên màn hình và thứ tự danh sách đổi ngay
   sang khoảng dài hơn — không có lần đọc thứ hai và không có trạng thái loading
   (BR-194, BR-197).
5. Người dùng chạm một hàng. Hệ thống mở **cấp của deck đó**: cùng bố cục, tổng
   của riêng subtree đó, và một hàng cho mỗi deck con trực tiếp. Back trả về
   đúng cấp vừa rời, ở mọi độ sâu.
6. Trong lúc màn hình mở, một lượt học được ghi ở nơi khác — hoặc một thẻ được
   chuyển deck, hoặc một deck bị xoá — thì các số tự cập nhật (BR-199).

**Alternative flows:**
- **A1 — Deck chứa thẻ chứ không chứa deck con:** cấp đó không có hàng nào để
  liệt kê. Hệ thống vẫn hiện bộ chọn và bảng tổng của chính deck đó, kèm một
  dòng nói rằng tổng ở trên đã là toàn bộ — vì cấp này **không** rỗng, nó chỉ
  không có gì để đi sâu thêm.
- **A2 — Thư viện chưa có deck nào:** hệ thống chỉ hiện empty state và **không**
  hiện bộ chọn hay bảng tổng: không có deck thì không có khoảng nào để có gì
  xảy ra trong đó. Không có nút hành động — bước tiếp theo nằm ở tab Thư viện,
  và một nút nhảy tab từ màn hình tiến độ đọc như một đường vòng.
- **A3 — Có deck nhưng khoảng đang chọn không có hoạt động nào:** danh sách
  **vẫn liệt kê đủ mọi deck** với các số 0, và bảng tổng mang thêm một dòng
  giải thích cùng gợi ý đổi sang khoảng dài hơn (BR-197). Trạng thái này trung
  tính: không dùng màu lỗi, không trách móc.
- **A4 — Nửa đêm địa phương đi qua khi màn hình đang mở:** cửa sổ trượt một
  ngày và hệ thống tự đọc lại, dù không có write nào trong database (BR-194,
  BR-199).

**Error flows:**
- **E1 — Đọc dữ liệu thất bại:** hệ thống hiện lý do đã localize theo **kiểu**
  failure — không bao giờ là `Failure.message` — cùng `Try again`, và nói rõ
  lịch sử học không bị ảnh hưởng vì đọc tiến độ không ghi gì (BR-198). Retry mở
  lại lần đọc từ đầu.
- **E2 — Deck của deep link không còn tồn tại:** đây **không** phải lỗi. Hệ
  thống hiện một empty state riêng và chỉ đề nghị đường quay lại cấp thư viện;
  `Try again` cố ý vắng mặt vì đọc lại sẽ thất bại y hệt.

**Postconditions:** Database không đổi — nội dung, timestamp, `content_type`,
study state, history, cờ và tag đều nguyên vẹn, và không session nào được mở
hay đóng (BR-198).

**Business rules:** BR-43, BR-51, BR-55, BR-56, BR-57, BR-76, BR-105, BR-192,
BR-193, BR-194, BR-195, BR-196, BR-197, BR-198, BR-199

**UI states:** loading · mixed activity (một số deck có, một số không) ·
all-zero (có deck, khoảng rỗng) · no decks (cấp thư viện) · no sub-decks (cấp
deck chứa thẻ) · read error + retry · deck missing + đường quay lại. Không có
state "empty selection": bộ chọn luôn có đúng một khoảng được chọn.

## Điều đã cố ý không đặc tả

| Thứ | Vì sao |
|---|---|
| Đưa deck con lên thành root deck | Cần quyết định scheduler mới; là tính năng riêng, không phải phép di chuyển (UC-09 A2) |
| Tìm kiếm card (S1) | Should-have, chưa tới lượt |
| ~~Thống kê / streak (S2)~~ | **Đã đặc tả ở M99.23, M99.24 và M99.25** — UC-12 với BR-182…BR-191 chốt đơn vị đếm, partition, streak và phạm vi v1; UC-13 với BR-192…BR-199 chốt tiến độ theo deck; UC-14 với BR-200…BR-202 chốt tab Study đọc thư viện thật |
| Đảo chiều card (S3) | Should-have — **một nửa đã đóng ở M99.27**: UC-15 và BR-203…BR-209 cho phép hỏi ngược trong một phiên `self_assess` của deck `sm2` mà **không** ghi lại thẻ, nên phần còn mở là đảo chiều ở các mode khác |
| ~~Export (nửa còn lại của N1)~~ | **Đã đặc tả ở M99.21** — UC-11 và BR-174…BR-181 chốt scope, encoder, filename, share và quyền riêng tư trước khi viết code |
| Nhắc nhở hằng ngày (N2) | Nice-to-have, cần quyền notification |
| Media và tag trong card | Ngoài MVP; quy tắc reset (BR-41) và lưu trữ (AD-08) đã đặt sẵn |
| Đăng nhập, đồng bộ | Ngoài MVP (AD-03) |
| Scheduler thứ ba | Abstraction đã sẵn sàng; thêm khi có nhu cầu thật |

## UC-14 · Mở tab Study và chọn việc để học

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chạm tab Study, deep link `/study`, hoặc quay về sau khi kết thúc một phiên
**Preconditions:** Không có

**Main flow:**
1. Hệ thống đọc **một snapshot** gồm session có thể học tiếp và toàn bộ root deck
   kèm workload — cùng một transaction, không phải hai lần đọc rời (AD-13). Màn
   hình là **chỉ-đọc**: vào tab, cuộn hay đổi tab không ghi gì (BR-200).
2. Nếu có đúng một session hợp lệ đang mở, Resume card đứng đầu màn hình và nói
   deck nào, loại phiên gì, đang ở chặng nào — cả hai giá trị lấy từ chính hàng
   session, không suy ra (BR-76, BR-98).
3. Dưới Resume là danh sách root deck, mỗi hàng có tên deck, nhãn scheduler khi
   biết, ba con số Overdue/Due today/New và **một** hành động Study. Thứ tự giảm
   dần theo ba khoá đó, tie-break theo tên đã fold rồi `id` (BR-201).
4. Chạm Resume mở đúng session và đúng lượt đã lưu (BR-133), không tạo session
   thứ hai. Chạm Study trên một deck mở study entry của deck đó (UC-05), nơi lựa
   chọn giữa học mới và ôn tập mới được đưa ra.
5. Kết thúc, bỏ dở hoặc invalidate một phiên rồi quay lại: danh sách tự cập nhật
   qua stream, không reload cả route và không giữ con số cũ.

**Alternative flows:**
- **A1 — Không có session nào đang mở:** không có Resume card — không phải một
  thẻ rỗng, cũng không phải nút bị vô hiệu hoá.
- **A2 — Session của ngày học cũ, generation đã đổi, deck hoặc card đã bị xoá:**
  không quảng cáo Resume. Việc đóng session cũ vẫn thuộc BR-103 và xảy ra khi
  người dùng thực sự vào luồng, không phải khi màn hình này rần.
- **A3 — Mọi deck đều không còn gì đến hạn:** danh sách vẫn hiển thị, kèm một dòng
  nói hiện chưa có thẻ nào tới hạn; deck vẫn mở được để học trước (BR-29).
- **A4 — Thư viện chưa có deck nào:** empty state dẫn tới Starter Library (UC-01),
  lối thứ hai là về Library.
- **A5 — Có deck nhưng chưa có card nào:** zero state riêng, dẫn về Library để thêm
  thẻ — không phải CTA starter, và không bịa số Due (BR-202).

**Error flows:**
- **E1 — Đọc thất bại:** trạng thái lỗi có nút thử lại, không nêu tên bảng, câu truy
  vấn hay đường dẫn. Copy nói rõ không có gì bị thay đổi — đúng theo cấu trúc, vì
  màn hình này không có đường ghi nào.

**Postconditions:** Không đổi gì — use case chỉ đọc. Mọi write phát sinh sau đó đều
thuộc UC-05, bắt đầu từ một lần chạm tường minh.

**Business rules:** BR-200, BR-201, BR-202. Ngoài ra BR-29, BR-84, BR-101, BR-103,
BR-105, BR-133, BR-142, BR-162.
**UI states:** loading · loaded (resume + danh sách) · loaded (không resume) ·
loaded (mọi workload bằng 0) · empty (không deck) · empty (không card) · error

---

## UC-15 · Chọn chiều hỏi cho một phiên self-assess

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Bấm `Review` ở Study Entry của một deck chạy `sm2`
**Preconditions:** Root deck của deck đang mở dùng scheduler `sm2` (BR-06), có ít
nhất một thẻ đến hạn (BR-145), và mode ôn duy nhất thuật toán này offer là
`self_assess` (BR-146) — ba điều kiện của BR-203

**Main flow:**
1. Người dùng bấm `Review`. Vì `sm2` chỉ offer một mode, hệ thống bỏ qua màn chọn
   mode (BR-146) và mở sheet chọn **chiều hỏi**.
2. Hệ thống hiển thị ba lựa chọn — `Korean first` (gắn nhãn Recommended),
   `Meaning first`, `Mixed` — mỗi lựa chọn kèm một dòng mô tả bằng lời của bài
   tập, và một dòng nói lựa chọn không đổi được sau khi phiên bắt đầu (BR-207).
3. Người dùng chạm một lựa chọn. Chạm chỉ **chọn**, không mở phiên: lựa chọn bị
   khoá suốt phiên nên một cú chạm nhầm không được phép tiêu mất một phiên
   (BR-207).
4. Người dùng bấm `Start review`. Hệ thống khoá sheet trong lúc mở phiên — cú
   chạm thứ hai không sinh phiên thứ hai (BR-25).
5. Hệ thống mở phiên với chiều đã chọn, materialize hàng đợi trong cùng
   transaction, và gán chiều cho từng dòng: một chiều duy nhất với hai lựa chọn
   cố định, hoặc chia gần đều một lần cho `mixed` (BR-205).
6. Màn phiên học mở ra. Mỗi thẻ hiện đề ở nửa trên theo chiều của dòng nó, và
   đáp án ở nửa dưới sau khi lật (BR-204). Tập action vẫn là bốn action của `sm2`
   (BR-30) và lịch chạy y như trước (BR-209).

**Alternative flows:**
- **A1 — Đóng sheet:** người dùng vuốt xuống hoặc chạm ra ngoài. Chưa có gì được
  ghi, nên không có session nào để dọn (BR-101, BR-207); màn Study Entry giữ
  nguyên.
- **A2 — Deck chạy `eight_box`:** sheet này không xuất hiện. Lối vào là màn chọn
  mode của BR-146, và không đường nào từ đó dẫn tới chiều hỏi (BR-203).
- **A3 — Còn phiên bỏ dở:** sheet ba lối của BR-103 hiện trước. Chọn `Continue`
  đọc chiều đã lưu và **không** hỏi lại (BR-207); chọn `Review` kết thúc phiên cũ
  rồi đi vào bước 1.
- **A4 — Phiên `mixed` đang chạy:** hai thẻ liên tiếp có thể hỏi hai chiều khác
  nhau. Đó là đúng bài tập người dùng chọn; chiều của mỗi thẻ đã cố định từ bước
  5 và không đổi khi thẻ quay lại (BR-26, BR-205).

**Error flows:**
- **E1 — Deck đổi scheduler hoặc bị reset trong lúc sheet đang mở:** hệ thống đọc
  lại trước khi mở phiên; nếu `self_assess` không còn được offer thì sheet hiện
  một dòng lỗi và **giữ nguyên lựa chọn**, để người dùng thử lại mà không phải
  chọn lại (BR-13, BR-83).
- **E2 — Không còn thẻ đến hạn tại thời điểm bấm Start:** phiên bị từ chối và
  không ghi dòng nào (BR-101, BR-145); sheet báo lỗi như E1.
- **E3 — Yêu cầu thiếu chiều:** không thể tạo từ UI này; use case vẫn từ chối là
  validation và không ghi session (BR-208).

**Postconditions:** `study_sessions.direction` giữ lựa chọn của phiên,
`study_queue_items.direction` giữ chiều thật của từng thẻ, và mỗi lượt ghi vào
`study_answers.direction` chiều chép từ dòng hàng đợi (BR-206). Nội dung thẻ,
`cards.updated_at` và toàn bộ lịch SRS không đổi (BR-209).

**Business rules:** BR-25, BR-30, BR-101, BR-103, BR-142, BR-145, BR-146,
BR-203, BR-204, BR-205, BR-206, BR-207, BR-208, BR-209

**UI states:** initial (ba lựa chọn, Korean first đã chọn sẵn) · submitting
(Start hiện spinner, ba lựa chọn khoá) · failure (dòng lỗi, lựa chọn giữ nguyên,
Start dùng lại được). Không có state `loading` khi mở sheet — điều kiện khả dụng
đã được đọc trước khi sheet mở; không có state `empty`, vì ba lựa chọn là hằng
số.
