# Use cases — memox (MVP)

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng đủ chi tiết để xây mà không phải hỏi thêm |
| **Scope** | Must-have của MVP. Ngoài phạm vi: should/nice-to-have, và mọi thứ ở mục "Điều đã cố ý không đặc tả" |
| **Source of truth for** | UC-xx · main/alternative/error flow · UI state matrix của từng màn |
| **Depends on** | `document-conventions.md`, `product.md`, `business-rules.md` |
| **Updated by task** | T1.3a |
| **Last updated** | 2026-07-28 |

Chỉ đặc tả must-have. Should-have và nice-to-have viết khi tới lượt — đặc tả
trước những thứ có thể bị cắt là lãng phí.

Luồng viết bằng ngôn ngữ người dùng, không nói theo màn hình hay widget. Màn
hình sẽ đổi; luồng thì không.

**ID use case là định danh vĩnh viễn**, cùng chính sách với BR (xem
`business-rules.md`). UC mới append; không đánh số lại. Hiện tại: UC-01…UC-09.

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
   bộ cây deck con với `content_type` đúng theo template; toàn bộ card; và review
   state theo scheduler đã chọn (BR-09, BR-33).
9. Bản sao xuất hiện trong danh sách deck, toàn card mới nên đến hạn hết.
10. Người dùng ôn được ngay.

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
  chọn, `scheduler_generation = 1`, `first_review_at = NULL`.
- Mọi deck trong bản sao có `root_deck_id` trỏ đúng root mới (BR-56).
- Mỗi card có đúng một review state khởi tạo theo scheduler đó.

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
   `first_review_at = NULL`.
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

**Main flow (đổi chế độ ôn tập — chỉ trên root deck, chỉ khi chưa có review):**
1. Hệ thống hiển thị phần chọn chế độ ở trạng thái **mở khoá**
   (`first_review_at IS NULL`, BR-12).
2. Người dùng chọn chế độ khác.
3. Hệ thống cảnh báo review state của **toàn bộ card trong cây** sẽ được khởi tạo
   lại theo chế độ mới (BR-14).
4. Người dùng xác nhận.
5. Hệ thống đổi scheduler **và** khởi tạo lại review state toàn cây — trong một
   transaction.

**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số deck con và số card sẽ mất (BR-04).
2. Người dùng xác nhận.
3. Hệ thống xoá deck; toàn bộ descendant, card, review state, review history và
   study session bị xoá cascade (BR-03).

**Alternative flows:**
- **A1 — Root deck đã có review:** phần chọn chế độ hiển thị ở trạng thái **khoá**,
  kèm giải thích và lối đi tới Reset learning progress (UC-07). Không ẩn đi — ẩn
  khiến người dùng tưởng tính năng không tồn tại (BR-13).
- **A2 — Sửa deck con:** không có phần chọn chế độ (BR-06).
- **A3 — Đưa `content_type` về `unset`:** chỉ hiện khi deck đang rỗng; hỏi xác
  nhận; sau đó deck lại cho chọn cả hai loại phần tử con (BR-68). Không tự động
  xảy ra khi xoá hết nội dung (BR-67).
- **A4 — Huỷ xác nhận xoá:** không xảy ra gì.

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách với
  thông báo nhẹ nhàng.
- **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên
  scheduler cũ và review state cũ.
- **E3 — Đưa `content_type` về `unset` khi deck không rỗng:** chặn, giải thích
  phải xoá hết nội dung trước (BR-68).
- **E4 — Xoá thất bại:** hiện lỗi; deck còn nguyên vẹn.

**Postconditions:**
- Sau đổi chế độ: `scheduler_type` mới, mọi review state trong cây khởi tạo lại,
  `scheduler_generation` **không đổi** (chưa có gì để reset).
- Sau xoá: không còn deck con, card, review state, history hay session mồ côi.

**Business rules:** BR-01, BR-03, BR-04, BR-06, BR-12, BR-13, BR-14, BR-67, BR-68
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
4. Hệ thống tạo card **và** review state của nó trong cùng transaction, theo
   scheduler của root deck (tra qua `root_deck_id`) và generation hiện tại (BR-09).
5. Card xuất hiện; số card đến hạn của deck tăng.

Card đầu tiên của một deck `unset` được tạo qua UC-08, và chính nó xác lập
`content_type = 'card'`.

**Alternative flows:**
- **A1 — Sửa card:** nội dung đổi; review state và history **không** đổi (BR-10).
- **A2 — Xoá card:** hỏi xác nhận; xoá kèm review state và history của card đó.
  `content_type` **giữ nguyên** kể cả khi xoá card cuối cùng (BR-67).
- **A3 — Deck rỗng:** empty state với hành động "Thêm card".
- **A4 — Thêm liên tiếp nhiều card:** sau khi lưu, giữ form mở và xoá trống các ô.

**Error flows:**
- **E1 — Mặt trước hoặc mặt sau rỗng:** lỗi inline ở đúng ô đó.
- **E2 — Vượt 2000 ký tự:** lỗi inline, chặn nhập thêm.
- **E3 — Ghi thất bại:** hiện lỗi, giữ nội dung; không tạo card không có review
  state.

**Postconditions:** Card tồn tại kèm đúng một review state, đúng scheduler và
đúng generation của root deck.

**Business rules:** BR-07, BR-08, BR-09, BR-10, BR-63, BR-67
**UI states:** loading · loaded · empty · submitting · error

---

## UC-05 · Ôn tập một deck — luồng chính

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Bấm ôn tập trên một deck có card đến hạn
**Preconditions:** Deck tồn tại và có ít nhất một card thoả BR-22

Đây là luồng chạy hằng ngày và là vertical slice đầu tiên nên xây.

**Main flow:**
1. Hệ thống tạo `study_session` với `status = 'in_progress'`, `end_reason = NULL`,
   `root_deck_id` và `scheduler_generation` hiện tại của root (BR-45, BR-79).
2. Hệ thống lấy card đến hạn trong cả cây theo BR-22, BR-23, tối đa 50 card riêng
   biệt (BR-24).
3. Hệ thống xác định scheduler của root deck và **render nút đánh giá từ
   `supportedActions`** — 2 nút với `eight_box`, 4 nút với `sm2` (BR-30).
4. Hệ thống hiện mặt trước của card đầu tiên và tiến độ phiên.
5. Người dùng bấm lật; hệ thống hiện mặt sau kèm tập action tương ứng.
6. Người dùng chọn một action.
7. Hệ thống **so `session.scheduler_generation` với generation hiện tại của root**
   (BR-46). Lệch thì đi E4.
8. Hệ thống xác định `review_kind`: lượt **đầu tiên** của card này trong phiên là
   `scheduled`; các lượt sau là `relearning` (BR-77, BR-78). Giá trị này được
   **ghi tường minh**, không suy ra từ trạng thái trước/sau (BR-76).
9. Nếu `scheduled`: tính trạng thái mới bằng scheduler (BR-15/BR-16 hoặc
   BR-18/BR-19), cập nhật review state, `review_count`, `lapse_count`.
   Nếu `relearning`: **không** đổi box/ease/interval/due_at; chỉ cập nhật
   `last_reviewed_at` (BR-78).
10. Hệ thống ghi một dòng `review_history` kèm `review_kind` (BR-21) — ngay lập
    tức (BR-25).
11. Nếu đây là lượt `scheduled` đầu tiên của root ở generation này, hệ thống đặt
    `first_review_at` → scheduler bị khoá từ đây (BR-13).
12. Nếu action khác `forgotten`/`again`, card rời hàng đợi (BR-28).
13. Hết hàng đợi: session → `completed`, `end_reason = NULL`, `ended_at` được đặt
    (BR-81). Hiện tổng kết.

**Alternative flows:**
- **A1 — Đánh giá `forgotten` (8-box) hoặc `again` (SM-2):** card về trạng thái
  khởi đầu theo scheduler, và **quay lại trong phiên hiện tại** sau ít nhất 3 card
  khác, hoặc cuối hàng đợi nếu không đủ 3 (BR-26).
- **A2 — Card quay lại được đánh giá lần nữa:** lượt đó là `relearning` (BR-78).
  Ghi history và cập nhật `last_reviewed_at`, nhưng không đổi lịch. Đánh giá khác
  `forgotten`/`again` thì rời hàng đợi; lại `forgotten`/`again` thì quay lại lần
  nữa.
- **A3 — Thoát giữa phiên:** session → `abandoned`, `end_reason = user_exit`,
  `ended_at` được đặt (BR-82). Mọi đánh giá đã ghi **vẫn giữ** (BR-25, BR-86).
  Hàng đợi không lưu; mở lại là một phiên mới.
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
- Mỗi lượt đánh giá có đúng một dòng `review_history` mang `review_kind`,
  `scheduler_type` và `scheduler_generation` tại thời điểm đó.
- `first_review_at` của root khác NULL sau lượt `scheduled` đầu tiên.
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
2. Người dùng thấy mỗi deck với tên, tổng số card trong cây, số card đến hạn, và
   chế độ ôn tập đang dùng.
3. Deck có card đến hạn được làm nổi bật bằng **cả biểu tượng lẫn chữ**, không
   chỉ bằng màu.
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

**Business rules:** BR-22 — định nghĩa "đến hạn" phải khớp **hệt** UC-05, nếu
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
     thái thành thạo, và phiên đang dở.
3. Người dùng có thể chọn **chế độ ôn tập mới** ngay trong bước này — đây là mục
   đích chính của thao tác.
4. Người dùng xác nhận.
5. Hệ thống thực hiện, **trong một transaction duy nhất** (BR-47):
   - tăng `scheduler_generation` của root deck (BR-40);
   - đặt `scheduler_type` / `version` / `config` mới nếu người dùng đã chọn;
   - đặt `first_review_at = NULL` → scheduler mở khoá (BR-44);
   - khởi tạo lại review state của **toàn bộ** card trong cây (mọi cấp), theo
     scheduler mới và generation mới (BR-42, BR-09);
   - mọi study session `in_progress` của cây → `invalidated`,
     `end_reason = scheduler_reset`, `ended_at` được đặt (BR-83);
   - **không** đụng tới `review_history` (BR-43), và **không** đụng tới
     `content_type` hay cấu trúc cây (BR-41).
6. Người dùng quay về deck, toàn bộ card ở trạng thái mới và đến hạn ngay.

**Alternative flows:**
- **A1 — Reset mà không đổi chế độ:** hợp lệ. Dùng khi người dùng chỉ muốn học lại
  từ đầu.
- **A2 — Reset trên deck chưa có review:** vẫn cho phép, nhưng nêu rõ là không có
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
- Mọi review state trong cây có generation mới, scheduler mới, `due_at = NULL`.
- `first_review_at IS NULL`.
- Không còn session `in_progress` nào của cây.
- `review_history` cũ còn nguyên, mang generation cũ (BR-43).
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
   - tạo phần tử con: card (kèm review state, BR-09) hoặc deck con mới với
     `content_type = 'unset'`, `parent_deck_id` = deck hiện tại,
     `root_deck_id` = root của deck hiện tại (BR-56), và **không** có cột
     scheduler (BR-06).
5. Từ đây nút Create trong deck này chỉ hiện hành động tương ứng (BR-66).

**Alternative flows:**
- **A1 — Deck đã `card`:** không có lựa chọn tạo deck con, ở bất kỳ đâu trong UI
  (BR-63).
- **A2 — Deck đã `deck`:** không có lựa chọn tạo card (BR-64).
- **A3 — Xoá phần tử con cuối cùng:** `content_type` **giữ nguyên** (BR-67). Muốn
  đổi loại phải reset `content_type` tường minh (UC-03 A3, BR-68).
- **A4 — Huỷ giữa chừng:** không tạo gì và **không** xác lập `content_type` —
  `content_type` chỉ đổi cùng với việc phần tử con thực sự được tạo (BR-62).

**Error flows:**
- **E1 — Validate thất bại** (tên deck rỗng, card thiếu mặt): lỗi inline; không
  tạo gì và không đổi `content_type`.
- **E2 — Ghi thất bại giữa chừng:** transaction rollback. Deck giữ nguyên
  `content_type` cũ và không có phần tử con nửa vời (BR-62).
- **E3 — Cố tạo card trong root deck:** không có đường nào tới được trạng thái
  này qua UI (BR-59). Nếu xảy ra qua deep link hoặc lỗi lập trình, từ chối và log
  — đây là vi phạm BR-58 và validation phải bắt được.

**Postconditions:**
- Deck có `content_type` khác `unset`, khớp với loại phần tử con vừa tạo.
- Deck không đồng thời chứa card và deck con (BR-65).
- Deck con mới có `root_deck_id` đúng bằng root của cha (BR-56, BR-72).

**Business rules:** BR-09, BR-56, BR-58…BR-68, BR-72
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
     của nguồn (BR-74).
3. Hệ thống thực hiện **trong một transaction** (BR-71):
   - đặt `parent_deck_id` của deck nguồn thành deck đích;
   - cập nhật `root_deck_id` cho **toàn bộ subtree** của deck nguồn;
   - nếu đích đang `unset`, đặt `content_type = 'deck'` (BR-62).
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
- **E4 — Thất bại giữa chừng:** transaction rollback (BR-71). Không có descendant
  nào trỏ sai root (BR-72).

**Postconditions:**
- Cây không có cycle (BR-69).
- Mọi deck trong subtree đã di chuyển có `root_deck_id` đúng bằng root mới
  (BR-56, BR-72).
- Không deck nào đồng thời chứa card và deck con (BR-65).
- Không có card review state nào lệch scheduler hoặc generation so với root
  (BR-48, BR-49).

**Business rules:** BR-56, BR-62, BR-64, BR-69…BR-74
**UI states:** loaded · submitting · error

---

## Điều đã cố ý không đặc tả

| Thứ | Vì sao |
|---|---|
| Đưa deck con lên thành root deck | Cần quyết định scheduler mới; là tính năng riêng, không phải phép di chuyển (UC-09 A2) |
| Tìm kiếm card (S1) | Should-have, chưa tới lượt |
| Thống kê / streak (S2) | Should-have — `review_history` với `review_kind` đã đủ dữ liệu |
| Đảo chiều card (S3) | Should-have |
| Import/export (N1) | Nice-to-have; thư viện starter đã giải quyết vấn đề app trống |
| Nhắc nhở hằng ngày (N2) | Nice-to-have, cần quyền notification |
| Media và tag trong card | Ngoài MVP; quy tắc reset (BR-41) và lưu trữ (AD-08) đã đặt sẵn |
| Đăng nhập, đồng bộ | Ngoài MVP (AD-03) |
| Scheduler thứ ba | Abstraction đã sẵn sàng; thêm khi có nhu cầu thật |
