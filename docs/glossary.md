# Glossary — thuật ngữ memox

| | |
|---|---|
| **Status** | active |
| **Purpose** | Cho một cái tên đúng một nghĩa, và tách những cặp tên gần giống nhau mà nhầm lẫn giữa chúng đã tốn thời gian thật |
| **Scope** | Thuật ngữ nghiệp vụ và tên định danh xuất hiện trong schema, domain và UI. Ngoài phạm vi: bản thân luật nghiệp vụ (`business-rules.md`), hình dạng dữ liệu (`data-model.md`) |
| **Source of truth for** | Định nghĩa thuật ngữ · bí danh và tên dễ nhầm · phân biệt các khái niệm gần nhau |
| **Depends on** | `document-conventions.md`, `product.md` |
| **Updated by task** | project-documentation FULL_SYNC (no WBS id) |
| **Last updated** | 2026-09-23 |

Tài liệu này **định nghĩa tên**, không phát biểu luật. Khi một mục cần một luật,
nó dẫn ID (`BR-xx`, `AD-xx`, `UC-xx`) chứ không chép nội dung — quy tắc canonical
location ở `document-conventions.md` §5.

Mọi tên cột và tên bảng dưới đây đã được đối chiếu trực tiếp với
`lib/core/database/tables/*.drift` ở revision `5b83bfd8`.

---

## 1 · Cây deck

| Thuật ngữ | Nghĩa |
|---|---|
| **Deck** | Một nút trong cây. Hàng ở bảng `decks`. Không phân biệt "thư mục" và "bộ thẻ" bằng hai bảng — cùng một bảng, khác `content_type` |
| **Root deck** | Deck không có cha (`parent_deck_id IS NULL`). Nó sở hữu scheduler cho cả cây bên dưới (BR-06) và chỉ chứa deck con |
| **Sub-deck** | Deck có cha. Kế thừa scheduler của root, không chọn riêng được — `decks.scheduler_type` để NULL ở sub-deck làm điều đó bất khả thi về cấu trúc, không phải theo quy ước |
| **`content_type`** | `unset` · `card` · `deck`. Loại phần tử con mà deck này chứa. Deck con mới tạo là `unset`; phần tử con đầu tiên xác lập nó (BR-61, BR-62); rỗng trở lại thì về `unset` (BR-163) |
| **`root_deck_id`** | Đường tắt tới root của cây. **Đây là cách duy nhất đúng để tìm root.** `COALESCE(parent_deck_id, id)` trả sai từ cấp ba trở xuống |
| **`parent_deck_id`** | Cha trực tiếp, NULL ở root |
| **`sibling_position`** | Thứ tự thủ công giữa các deck cùng cha (BR-268, UC-22) |
| **Level** | Độ sâu, root là 1, tối đa 10 (BR-55) |
| **`owner_id`** | Chủ sở hữu, hiện luôn NULL. Tồn tại từ đầu để auth thêm vào sau không phải migrate (AD-03) |

## 2 · Nội dung thẻ

| Thuật ngữ | Nghĩa |
|---|---|
| **Card** | Một thẻ. Bảng `cards` giữ **chỉ nội dung** — không cột SRS, không generation. Nội dung sống sót qua mọi lần reset |
| **`front` / `back`** | Hai mặt thẻ. Bắt buộc, không rỗng |
| **`front_folded` / `back_folded`** | Bản đã fold chữ hoa-thường dùng cho tìm kiếm. **Chỉ fold hoa-thường, không bỏ dấu** — `công` không khớp `cong`, và đó là quyết định sản phẩm (S1), không phải hệ quả của một bug fix |
| **`example` · `hint` · `pronunciation`** | Trường phụ, đều nullable |
| **`is_flagged`** | Cờ người dùng tự đánh trên một thẻ. Không ảnh hưởng lịch học |
| **Tag** | Nhãn phạm vi library, nhiều-nhiều qua `card_tags` (UC-18, BR-230…BR-238) |

## 3 · Lịch học

| Thuật ngữ | Nghĩa |
|---|---|
| **Scheduler / thuật toán SRS** | `eight_box` hoặc `sm2`. Quyết định **khi nào** thẻ quay lại. Chọn một lần lúc tạo root deck, khoá sau khi thẻ đầu tiên học xong chuỗi học mới (BR-13) |
| **`scheduler_generation`** | Bộ đếm chu kỳ học, bắt đầu ở 1, +1 sau mỗi lần reset (BR-40). Có mặt trên deck, card state, session và mọi dòng lịch sử |
| **`scheduler_version`** | Phiên bản tham số của thuật toán. Khác `scheduler_generation` — version nói "luật nào", generation nói "chu kỳ thứ mấy" |
| **`card_study_states`** | Bảng giữ **lịch** của một thẻ: box, ease factor, interval, hạn kế tiếp. Một hàng một thẻ |
| **`current_box`** | Vị trí trong thang 8 hộp của `eight_box`. NULL với `sm2` |
| **`ease_factor` · `interval_days` · `repetitions`** | Ba đại lượng của `sm2`. NULL với `eight_box` |
| **`due_at`** | Thời điểm thẻ đến hạn, UTC. So ở sai múi giờ làm thẻ đến hạn sớm hoặc muộn một ngày |
| **`learned_at`** | Thời điểm thẻ học xong chuỗi học mới. NULL nghĩa là chưa học xong — và nó đi cùng `due_at IS NULL` |
| **`first_answered_at`** | Trên **deck**, không trên thẻ: mốc khoá scheduler (BR-13). Tên cột nói "answered", nhưng sự kiện đặt nó là **thẻ đầu tiên hoàn tất chuỗi học mới** — xem §6 |
| **Due / overdue** | Đến hạn hôm nay / đã quá hạn. `DeckSummary` tách hai số này (BR-162) |

## 4 · Phiên học

| Thuật ngữ | Nghĩa |
|---|---|
| **Study session** | Một lần ngồi học. Bảng `study_sessions` |
| **`session_kind`** | `learning` · `reviewing`. **Hai tập thẻ không bao giờ trộn** (BR-142): `learning` lấy thẻ `learned_at IS NULL`, `reviewing` lấy thẻ đã học xong và đến hạn |
| **StudyMode** | `browse` · `self_assess` · `match` · `guess` · `recall` · `fill`. Quyết định **cách** thẻ được hỏi. Không ai chọn trong phiên học mới — chuỗi stage là cố định theo thuật toán (BR-109, BR-110) |
| **Stage** | Một bước trong chuỗi của phiên học mới. Lưu tường minh ở `study_sessions.current_mode` (BR-98) |
| **`study_queue_items`** | Hàng đợi của phiên: thẻ nào, mode nào, round nào, vị trí nào |
| **`study_answers`** | Lịch sử học, **append-only**, giữ nguyên qua mọi lần reset. Đây là bảng "history" trong bộ ba nội dung / lịch / lịch sử |
| **`kind`** (trên `study_answers`) | `learning` · `scheduled` · `relearning`. Loại của **một lượt trả lời**. Lưu tường minh, không suy ra (BR-76, BR-131) |
| **Action** | Kết quả người học báo. Hai scheduler có hai tập khác nhau: `eight_box` dùng `forgotten`/`remembered`, `sm2` dùng `again`/`hard`/`good`/`easy` (BR-30) |
| **`outcome_reason`** | Hiện chỉ có `timeout`, và chỉ hợp lệ ở stage `recall` (BR-131) |
| **`status`** (trên `study_sessions`) | `in_progress` · `completed` · `abandoned` · `invalidated` · `failed` |
| **`end_reason`** | Bảy giá trị (BR-270). NULL khi chưa kết thúc hoặc kết thúc bình thường |
| **`direction`** | Chiều hỏi: `korean_to_meaning` · `meaning_to_korean` · `mixed` (BR-204, BR-205). Xem §6 về cái tên này |

## 5 · Xoá và khôi phục

| Thuật ngữ | Nghĩa |
|---|---|
| **Soft delete** | Xoá là gắn tombstone, không phải xoá hàng (AD-22) |
| **Tombstone** | Cột `delete_batch_id` trên chính hàng đó. Khác NULL nghĩa là hàng đã ở Trash |
| **Delete batch** | Bảng `delete_batches`. Một thao tác xoá của người dùng là một batch, và undo hoàn lại đúng một batch (BR-263) |
| **Retention** | 30 × 24 giờ tính từ `deleted_at` (BR-264) |
| **Purge** | Xoá cứng theo batch (BR-265) |

## 6 · Tên dễ nhầm

Mục này tồn tại vì mỗi cặp dưới đây **đã** gây nhầm lẫn thật.

| Cặp | Phân biệt |
|---|---|
| `kind` ↔ `session_kind` | `session_kind` ở trên **phiên** (`learning`/`reviewing`). `kind` ở trên **một lượt trả lời** (`learning`/`scheduled`/`relearning`). Ba giá trị và hai giá trị, hai bảng khác nhau |
| `mode` ↔ `current_mode` | `current_mode` là stage phiên đang chạy. `mode` là mode của một dòng hàng đợi |
| `scheduler_version` ↔ `scheduler_generation` | Version = bộ tham số nào. Generation = chu kỳ học thứ mấy, tăng khi reset |
| **Thư viện (Library)** ↔ **Decks** | Nhãn tab đầu ở bottom navigation là "Thư viện"; branch nội bộ và màn hình gốc của nó vẫn tên `Decks` (AD-19). Hai tên, một thứ |
| `korean_to_meaning` ↔ ngữ nghĩa thật | Tên mang tính tiếng Hàn, **ngữ nghĩa thì không**: BR-204 định nghĩa nó là "hiện `front` làm đề, `back` làm đáp án". `product.md` không hề nói app chỉ dành cho tiếng Hàn. Đừng suy ra phạm vi sản phẩm từ cái tên này, và đừng thêm hành vi riêng cho tiếng Hàn dựa trên nó |
| `front_folded` ↔ "đã chuẩn hoá" | Chỉ fold hoa-thường. **Không** bỏ dấu |
| `first_answered_at` ↔ "lượt ôn đầu tiên" | Cột nói "answered", nhưng sự kiện đặt nó là **thẻ đầu tiên hoàn tất chuỗi học mới** (BR-13, BR-144), không phải lượt ôn `scheduled` đầu tiên. Hai mốc này cách nhau ít nhất một interval, vì chuỗi học mới không sinh lượt `scheduled` nào. `CLAUDE.md` từng đọc nhầm đúng theo cái tên này và đã được sửa trong lần FULL_SYNC này. Bằng chứng: `lib/core/database/queries/study.drift:332` |

### Ba cái tên không còn tồn tại

`CLAUDE.md` từng dùng ba tên không có trong schema; chúng đã được sửa trong lần
FULL_SYNC này. Nếu bạn gặp chúng trong commit cũ, PR cũ hay bộ nhớ của một phiên
trước, đây là bản dịch:

| Tên cũ, không tồn tại | Tên thật |
|---|---|
| `card_review_states` | `card_study_states` |
| `review_history` | `study_answers` |
| `review_kind` | `study_answers.kind` |

## 7 · Nội dung dựng sẵn

| Thuật ngữ | Nghĩa |
|---|---|
| **Starter deck** | Deck mẫu app cung cấp. Là **template**, không phải bảng runtime — người dùng nhận một **bản sao** và bản sao là deck bình thường (AD-07, UC-01) |
| **`source_template_id` / `source_template_version`** | Trên deck bản sao: nó đến từ template nào, phiên bản nào. Cập nhật template không ghi đè bản sao |
