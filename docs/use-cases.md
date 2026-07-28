# Use cases — memox (MVP)

_Status: draft · Last updated: 2026-07-28_

Chỉ đặc tả must-have. Should-have và nice-to-have viết khi tới lượt — đặc tả
trước những thứ có thể bị cắt là lãng phí.

Luồng viết bằng ngôn ngữ người dùng, không nói theo màn hình hay widget. Màn
hình sẽ đổi; luồng thì không.

Mục [suy luận] là chỗ tôi tự quyết vì không có đặc tả.

---

## UC-01 · Khởi động lần đầu và chọn starter deck

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
   nguồn nội dung.
6. Người dùng chọn một starter deck.
7. Hệ thống hỏi **chế độ ôn tập** cho bản sao, gợi ý sẵn `default_scheduler_type`
   của template (BR-34).
8. Hệ thống **tạo bản sao** trong một transaction: deck mới với ID riêng,
   `scheduler_generation = 1`, toàn bộ card, và review state theo scheduler đã
   chọn (BR-09, BR-33, BR-39).
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
  được. Đây là ưu điểm trực tiếp của mô hình template.

**Error flows:**
- **E1 — Không mở được database:** màn hình lỗi rõ ràng với hành động thử lại.
  Không được là màn hình trắng — trắng không phân biệt được với treo.
- **E2 — Manifest hỏng hoặc thiếu:** thư viện hiện empty state; app vẫn dùng bình
  thường với luồng tạo deck thủ công.
- **E3 — Một file template hỏng:** bỏ qua đúng template đó, các template khác vẫn
  hiện.
- **E4 — Sao chép thất bại giữa chừng:** transaction rollback (BR-39). Không có
  deck nửa vời.

**Postconditions:**
- Bản sao có `source_template_id`, `source_template_version`, `scheduler_type` đã
  chọn, `scheduler_generation = 1`, `first_review_at = NULL`.
- Mỗi card có đúng một review state khởi tạo theo scheduler đó.

**Business rules:** BR-09, BR-31…BR-39
**UI states:** initial · loading · loaded · empty · submitting · error

---

## UC-02 · Tạo deck

**Actor:** Người dùng
**Trigger:** Bấm tạo deck
**Preconditions:** Không có

**Main flow:**
1. Người dùng nhập tên deck.
2. Người dùng **chọn chế độ ôn tập**: `eight_box` hoặc `sm2` (BR-11). Đây là
   lựa chọn bắt buộc, không có mặc định ngầm bỏ qua bước này.
3. Hệ thống hiển thị mô tả ngắn cho từng chế độ, kèm lưu ý rằng chế độ sẽ bị khoá
   sau lượt ôn đầu tiên (BR-13).
4. Người dùng xác nhận.
5. Hệ thống validate tên (BR-01) và chế độ đã chọn.
6. Hệ thống tạo deck với ID sinh phía client, `scheduler_generation = 1`,
   `first_review_at = NULL`, `parent_deck_id = NULL`.
7. Deck xuất hiện trong danh sách với 0 card.

**Alternative flows:**
- **A1 — Tạo sub-deck:** `parent_deck_id` trỏ tới deck cha. **Không** hỏi chế độ
  ôn tập — sub-deck kế thừa scheduler của root (BR-05, BR-06).
- **A2 — Người dùng huỷ:** không tạo gì; nếu đã nhập, hỏi xác nhận trước khi bỏ.

**Error flows:**
- **E1 — Tên rỗng:** lỗi inline dưới ô nhập, không phải snackbar.
- **E2 — Tên quá 200 ký tự:** lỗi inline; chặn nhập thêm thay vì cắt âm thầm.
- **E3 — Chưa chọn chế độ:** lỗi inline ở phần chọn chế độ; không tạo.
- **E4 — Ghi database thất bại:** hiện lỗi, giữ nguyên form và dữ liệu đã nhập.

**Postconditions:** Deck tồn tại với scheduler đã chọn và còn sau khi khởi động
lại app.

**Business rules:** BR-01, BR-02, BR-05, BR-06, BR-11
**UI states:** initial · submitting · error

---

## UC-03 · Sửa và xoá deck

**Actor:** Người dùng
**Trigger:** Chọn sửa hoặc xoá trên một deck
**Preconditions:** Deck tồn tại

**Main flow (sửa tên):**
1. Người dùng đổi tên deck.
2. Hệ thống validate (BR-01) và lưu.

**Main flow (đổi chế độ ôn tập — khi deck chưa có review):**
1. Hệ thống hiển thị phần chọn chế độ ở trạng thái **mở khoá**
   (`first_review_at IS NULL`, BR-12).
2. Người dùng chọn chế độ khác.
3. Hệ thống cảnh báo rằng review state của toàn bộ card sẽ được khởi tạo lại
   theo chế độ mới (BR-14).
4. Người dùng xác nhận.
5. Hệ thống đổi scheduler **và** khởi tạo lại review state toàn bộ card — trong
   một transaction.

**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số sub-deck và số card sẽ mất (BR-04).
2. Người dùng xác nhận.
3. Hệ thống xoá deck; sub-deck, card, review state, review history và study
   session bị xoá cascade (BR-03).

**Alternative flows:**
- **A1 — Deck đã có review:** phần chọn chế độ hiển thị ở trạng thái **khoá**,
  kèm giải thích và lối đi tới Reset learning progress (UC-07). Không ẩn đi —
  ẩn khiến người dùng tưởng tính năng không tồn tại (BR-13).
- **A2 — Sửa sub-deck:** không có phần chọn chế độ (BR-06).
- **A3 — Huỷ xác nhận xoá:** không xảy ra gì.
- **A4 — Xoá deck có nguồn từ template:** xoá bình thường; template vẫn còn trong
  thư viện (UC-01 A4).

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách với
  thông báo nhẹ nhàng.
- **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên
  scheduler cũ và review state cũ.
- **E3 — Xoá thất bại:** hiện lỗi; deck còn nguyên vẹn.

**Postconditions:**
- Sau đổi chế độ: `scheduler_type` mới, mọi review state khởi tạo lại theo
  scheduler đó, `scheduler_generation` **không đổi** (chưa có gì để reset).
- Sau xoá: không còn card, review state, history hay session mồ côi.

**Business rules:** BR-01, BR-03, BR-04, BR-06, BR-12, BR-13, BR-14
**UI states:** loaded · submitting · error

---

## UC-04 · Quản lý card trong deck

**Actor:** Người dùng
**Trigger:** Mở một deck
**Preconditions:** Deck tồn tại

**Main flow:**
1. Người dùng thấy danh sách card của deck.
2. Người dùng thêm card: nhập mặt trước và mặt sau.
3. Hệ thống validate (BR-07, BR-08).
4. Hệ thống tạo card **và** review state của nó trong cùng transaction, theo
   scheduler của root deck và generation hiện tại (BR-09).
5. Card xuất hiện; số card đến hạn của deck tăng.

**Alternative flows:**
- **A1 — Sửa card:** nội dung đổi; review state và history **không** đổi (BR-10).
- **A2 — Xoá card:** hỏi xác nhận; xoá kèm review state và history của card đó.
- **A3 — Deck rỗng:** empty state với hành động "Thêm card" ngay trong đó.
- **A4 — Thêm liên tiếp nhiều card:** sau khi lưu, giữ form mở và xoá trống các ô.
  [suy luận] Người dùng nhập từ vựng theo loạt.

**Error flows:**
- **E1 — Mặt trước hoặc mặt sau rỗng:** lỗi inline ở đúng ô đó.
- **E2 — Vượt 2000 ký tự:** lỗi inline, chặn nhập thêm.
- **E3 — Ghi thất bại:** hiện lỗi, giữ nội dung; không tạo card không có review
  state.

**Postconditions:** Card tồn tại kèm đúng một review state, đúng scheduler và
đúng generation của root deck.

**Business rules:** BR-07, BR-08, BR-09, BR-10
**UI states:** loading · loaded · empty · submitting · error

---

## UC-05 · Ôn tập một deck — luồng chính

**Actor:** Người dùng
**Trigger:** Bấm ôn tập trên một deck có card đến hạn
**Preconditions:** Deck tồn tại và có ít nhất một card thoả BR-22

Đây là luồng chạy hằng ngày và là vertical slice đầu tiên nên xây — nó chạm từ
Drift query có index, qua scheduler thuần khiết ở domain, đến state matrix đầy đủ
ở presentation.

**Main flow:**
1. Hệ thống tạo `study_session` mang `scheduler_generation` hiện tại của root
   deck, và lấy card đến hạn theo BR-22, BR-23, tối đa 50 card riêng biệt
   (BR-24).
2. Hệ thống xác định scheduler của root deck và **render nút đánh giá từ
   `supportedActions`** — 2 nút với `eight_box`, 4 nút với `sm2` (BR-30).
3. Hệ thống hiện mặt trước của card đầu tiên và tiến độ phiên.
4. Người dùng nghĩ đáp án rồi bấm lật.
5. Hệ thống hiện mặt sau kèm tập action tương ứng.
6. Người dùng chọn một action.
7. Hệ thống **kiểm tra generation của session so với generation hiện tại của
   root deck** (BR-46). Lệch thì đi E4.
8. Hệ thống tính trạng thái mới bằng scheduler tương ứng (BR-15/BR-16 hoặc
   BR-17/BR-18/BR-19), cập nhật review state, và ghi một dòng `review_history`
   (BR-21) — ngay lập tức (BR-25).
9. Nếu đây là lượt đánh giá có xếp lịch đầu tiên của deck ở generation này, hệ
   thống đặt `first_review_at` → scheduler bị khoá từ đây (BR-13).
10. Nếu action khác `forgotten`/`again`, card rời hàng đợi (BR-28).
11. Hết hàng đợi, hệ thống đóng session và hiện tổng kết.

**Alternative flows:**
- **A1 — Đánh giá `forgotten` (8-box) hoặc `again` (SM-2):** card về trạng thái
  khởi đầu theo scheduler, và **quay lại trong phiên hiện tại** sau ít nhất 3
  card khác, hoặc cuối hàng đợi nếu còn ít hơn 3 (BR-26).
- **A2 — Card quay lại được đánh giá lần nữa trong cùng phiên:** đây là **luyện
  lại**. Ghi history (BR-21) và cập nhật `last_reviewed_at`, nhưng **không** đổi
  trạng thái lịch và không đổi `due_at` (BR-27).
- **A3 — Thoát giữa phiên:** giữ toàn bộ đánh giá đã ghi (BR-25). Hàng đợi không
  lưu; mở lại bắt đầu phiên mới với card còn đến hạn.
- **A4 — Còn card quá hạn ngoài giới hạn 50:** ở tổng kết nói rõ còn bao nhiêu và
  cho phép bắt đầu phiên tiếp theo ngay.
- **A5 — Xoá deck đang ôn dở:** kết thúc phiên, quay về danh sách.

**Error flows:**
- **E1 — Không còn card nào đến hạn lúc bắt đầu:** empty state tích cực (BR-29),
  kèm thời điểm card gần nhất đến hạn. **Không** phải màn hình lỗi.
- **E2 — Ghi đánh giá thất bại:** hiện lỗi ngay, **không** chuyển sang card tiếp
  theo. Người dùng thử lại action đó. Chuyển tiếp khi chưa ghi được là âm thầm
  mất tiến độ — thứ người dùng chỉ phát hiện sau nhiều ngày.
- **E3 — Đọc card thất bại:** màn hình lỗi có nút thử lại.
- **E4 — Generation của session đã lỗi thời** (deck bị reset ở màn khác trong lúc
  phiên đang mở): **từ chối ghi**, thông báo phiên đã hết hiệu lực vì tiến độ học
  của deck vừa được đặt lại, đóng phiên và quay về danh sách (BR-46). Không ghi
  bất kỳ phần nào của đánh giá đó.

**Postconditions:**
- Mỗi card đã đánh giá có trạng thái lịch mới, đúng scheduler và đúng generation.
- Mỗi lượt đánh giá — kể cả luyện lại — có đúng một dòng `review_history` mang
  `scheduler_type` và `scheduler_generation` tại thời điểm đó.
- `first_review_at` của root deck khác NULL sau lượt có xếp lịch đầu tiên.
- `study_session.ended_at` được đặt khi phiên kết thúc bình thường.
- Nếu E4 xảy ra, **không** có dòng history nào được ghi cho lượt đó.

**Business rules:** BR-13, BR-15…BR-30, BR-45, BR-46
**UI states:** loading · loaded (mặt trước) · loaded (đã lật) · submitting ·
empty · error

`submitting` tách khỏi `loaded` là đúng nguyên tắc "dữ liệu và trạng thái tác vụ
là hai chuyện": trong lúc ghi đánh giá, nội dung card vẫn hiện, chỉ các nút bị
khoá để tránh bấm đúp.

---

## UC-06 · Xem danh sách deck với tiến độ

**Actor:** Người dùng
**Trigger:** Mở app, hoặc quay về từ màn khác
**Preconditions:** Không có

**Main flow:**
1. Hệ thống lấy toàn bộ deck kèm số card đến hạn của từng deck — **một query
   gộp**, không phải N+1 query. Sub-deck gộp số liệu lên root.
2. Người dùng thấy mỗi deck với tên, tổng số card, số card đến hạn, và chế độ ôn
   tập đang dùng.
3. Deck có card đến hạn được làm nổi bật bằng **cả biểu tượng lẫn chữ**, không
   chỉ bằng màu.

**Alternative flows:**
- **A1 — Chưa có deck nào:** empty state với hai lối đi — thư viện starter
  (UC-01) hoặc tạo deck mới (UC-02).
- **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift
  (AD-01), không cần refresh thủ công.

**Error flows:**
- **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại.

**Postconditions:** Không đổi gì — use case chỉ đọc.

**Business rules:** BR-22 — định nghĩa "đến hạn" phải khớp **hệt** UC-05, nếu
không con số ở danh sách sẽ lệch với số card thực sự ôn được. Dùng chung một
named query cho cả hai chỗ.
**UI states:** loading · loaded · empty · error

---

## UC-07 · Reset learning progress

**Actor:** Người dùng
**Trigger:** Chọn "Đặt lại tiến độ học" trên một root deck — thường từ chỗ giải
thích vì sao chế độ ôn tập đang bị khoá (UC-03 A1)
**Preconditions:** Root deck tồn tại

**Main flow:**
1. Người dùng chọn đặt lại tiến độ học.
2. Hệ thống hiện xác nhận nêu rõ hai danh sách (BR-50):
   - **Giữ nguyên:** deck, sub-deck, flashcard, media, tag, toàn bộ nội dung, và
     lịch sử ôn tập cũ (để tham khảo).
   - **Mất:** lịch ôn hiện tại, ngày đến hạn, box / ease factor / interval, trạng
     thái thành thạo, và phiên đang dở.
3. Người dùng có thể chọn **chế độ ôn tập mới** ngay trong bước này — đây là mục
   đích chính của thao tác.
4. Người dùng xác nhận.
5. Hệ thống thực hiện, **trong một transaction duy nhất** (BR-47):
   - tăng `scheduler_generation` của root deck (BR-40);
   - đặt `scheduler_type` / `version` / `config` mới nếu người dùng đã chọn;
   - đặt `first_review_at = NULL` → scheduler mở khoá (BR-44);
   - khởi tạo lại review state của **toàn bộ** card thuộc root deck và mọi
     sub-deck, theo scheduler mới và generation mới (BR-42, BR-09);
   - đóng hoặc huỷ mọi study session đang dở của deck (BR-42);
   - **không** đụng tới `review_history` (BR-43).
6. Người dùng quay về deck, toàn bộ card ở trạng thái mới và đến hạn ngay.

**Alternative flows:**
- **A1 — Reset mà không đổi chế độ:** hợp lệ. Dùng khi người dùng chỉ muốn học
  lại deck từ đầu.
- **A2 — Reset trên deck chưa có review:** vẫn cho phép, nhưng nêu rõ là không có
  gì để mất. [suy luận] Đơn giản hơn cho người dùng so với việc ẩn nút đi.
- **A3 — Huỷ ở bước xác nhận:** không xảy ra gì.

**Error flows:**
- **E1 — Thất bại giữa chừng (app bị kill, hết bộ nhớ):** transaction rollback
  (BR-47). Deck giữ nguyên generation cũ, scheduler cũ và toàn bộ state cũ.
  **Không** có trạng thái nửa vời với card thuộc hai generation.
- **E2 — Người dùng có phiên đang mở ở màn khác:** phiên đó bị vô hiệu bởi
  generation mới; lần bấm đánh giá tiếp theo trong phiên đó bị từ chối (UC-05
  E4, BR-46).

**Postconditions:**
- `scheduler_generation` tăng đúng 1.
- Mọi review state của deck và sub-deck có generation mới, scheduler mới, và ở
  trạng thái khởi đầu (`due_at = NULL`).
- `first_review_at IS NULL`.
- Không còn session đang dở của deck.
- `review_history` cũ còn nguyên, mang generation cũ (BR-43).
- Bất biến BR-48 và BR-49 giữ nguyên: một scheduler, một generation.

**Business rules:** BR-40…BR-50
**UI states:** loaded · submitting · error

---

## Điều đã cố ý không đặc tả

| Thứ | Vì sao |
|---|---|
| Tìm kiếm card (S1) | Should-have, chưa tới lượt |
| Thống kê / streak (S2) | Should-have — `review_history` đã đủ dữ liệu để làm sau |
| Đảo chiều card (S3) | Should-have |
| Import/export (N1) | Nice-to-have; thư viện starter đã giải quyết vấn đề app trống |
| Nhắc nhở hằng ngày (N2) | Nice-to-have, cần quyền notification |
| Media và tag trong card | Ngoài MVP; quy tắc reset (BR-41) và lưu trữ (AD-08) đã đặt sẵn |
| Đăng nhập, đồng bộ | Ngoài MVP (AD-03) |
| Scheduler thứ ba | Abstraction đã sẵn sàng; thêm khi có nhu cầu thật |
