# 5Why — Trash and Restore v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi lại năm chuỗi "vì sao" đã dẫn tới quyết định soft-delete/batch/target/retention của Trash v1 |
| **Scope** | Lý do đằng sau BR-256…BR-267, AD-22 và schema v8. Không phát biểu rule — rule sống ở `business-rules.md` |
| **Source of truth for** | — (giải thích, không phải quyết định) |
| **Depends on** | `docs/prompt/trash-restore-v1/implementation.md`, `docs/business-rules.md`, `docs/architecture.md` |
| **Updated by task** | M99.33 |
| **Last updated** | 2026-08-13 |

---

Prose ở đây **không** chứa MUST/SHOULD/MAY và **không** phải rule (§9). Nó tồn
tại để phiên sau biết một quyết định trả giá cho điều gì, trước khi ai đó "đơn
giản hoá" nó đi.

## 1. Accidental loss

1. **Vì sao cần Trash?** Vì `deleteDeck` trước v8 là một `DELETE` thật, và
   `ON DELETE CASCADE` kéo theo mọi descendant deck, card, study state, history
   và session của cả cây.
2. **Vì sao điều đó nguy hiểm hơn một delete thông thường?** Vì thứ mất đi không
   phải nội dung người dùng gõ ra trong một phút — mà là *lịch sử học*. Nội dung
   gõ lại được; `learned_at`, box, ease factor và `study_answers` thì không.
3. **Vì sao không dựa vào dialog xác nhận?** Vì dialog đã có, và nó vẫn là một
   quyết định phải đúng ngay lần đầu, dưới ngón tay, trên một hàng danh sách
   giống hệt hàng bên cạnh. Xác nhận đo *ý định*, không đo *độ chính xác của
   thao tác chạm*.
4. **Vì sao không dựa vào backup?** Vì app là local-first và chưa có backend
   (AD-03, AD-05). "Khôi phục từ backup" hôm nay nghĩa là không khôi phục được.
5. **Vì sao 30 ngày mà không phải vô hạn?** Vì một Trash không bao giờ tự dọn là
   một database chỉ lớn lên, và người dùng không có cách nào biết cái gì trong
   đó còn quan trọng. 30 ngày là khoảng đủ dài để bắt được lỗi thao tác và đủ
   ngắn để Trash không thành kho lưu trữ thứ hai.

## 2. Soft-delete lifecycle

1. **Vì sao không copy hàng sang bảng `trash`?** Vì id sẽ đổi, hoặc phải giữ id
   qua hai bảng; và `card_study_states`, `study_answers`, `card_tags` đều trỏ về
   `cards.id` bằng FK. Copy nghĩa là nhân bản bốn quan hệ và ghép lại khi restore.
2. **Vì sao điều đó tệ?** Vì restore khi đó là một phép *tái tạo*, và mọi phép
   tái tạo đều có thể tái tạo sai. Rule 7 của prompt nói thẳng: restore giữ
   nguyên IDs/state/history/tags — cách duy nhất chắc chắn giữ nguyên là **không
   động vào chúng**.
3. **Vì sao đánh dấu tại chỗ lại đủ?** Vì mọi thứ treo dưới `cards.id` và
   `decks.id` vẫn đúng khi hàng còn nguyên; chỉ *khả kiến* thay đổi.
4. **Vì sao một cột thay vì hai (`deleted_at` + `delete_batch_id`)?** Vì hai cột
   trên cùng một hàng là hai nguồn sự thật cho cùng một sự kiện, và chúng sẽ lệch
   nhau. `delete_batch_id` một mình đã trả lời được "hàng này còn sống không";
   `deleted_at` thuộc về batch, nơi nó được ghi đúng một lần.
5. **Vì sao không suy ra "đã xoá" từ việc parent đã xoá?** Vì suy ra nghĩa là mọi
   query active phải đi ngược lên cây để biết một card có hiện hay không — một
   recursive walk trong query nóng nhất của app. Đánh dấu cả subtree lúc xoá là
   một lần ghi đổi lấy vĩnh viễn một phép so sánh cột.

## 3. Explicit restore target

1. **Vì sao restore phải hỏi target?** Vì vị trí cũ có thể không còn hợp lệ: cha
   đã bị xoá, đã thành `card`, đã đầy 10 cấp, hoặc đã sang cây có scheduler khác.
2. **Vì sao không tự chọn vị trí cũ khi nó vẫn hợp lệ?** Vì "khi nó vẫn hợp lệ"
   là một điều kiện người dùng không nhìn thấy, nên cùng một nút sẽ lúc hỏi lúc
   không — và lần nó không hỏi là lần nó đặt nhầm chỗ mà không ai kịp thấy.
3. **Vì sao không cho restore rồi sửa sau?** Vì "sửa sau" là move, và move có thể
   bị từ chối bởi đúng những rule vừa bị bỏ qua. Restore khi đó tạo ra được trạng
   thái mà move không tạo ra được — hai đường ghi, hai bộ luật.
4. **Vì sao dùng lại đúng eligibility của move?** Vì đó là bộ luật đã có test và
   đã có UI; một bản thứ hai "cho restore" là bản sẽ lệch.
5. **Vì sao Undo lại *không* hỏi?** Vì Undo không phải restore: nó đảo ngược một
   thao tác vừa xảy ra, vị trí cũ vẫn ở ngay đó, và người dùng vẫn còn ngữ cảnh.
   Nếu vị trí cũ đã hết hợp lệ thì Undo bị từ chối có lý do — không im lặng rơi
   về một chỗ khác.

## 4. Retention và purge

1. **Vì sao purge phải idempotent?** Vì nó chạy ở ba nơi — startup, resume, mở
   Trash — và hai trong ba có thể xảy ra cách nhau vài mili giây.
2. **Vì sao ba nơi mà không phải một scheduler nền?** Vì app không có tiến trình
   nền, và một job nền chỉ chạy khi hệ điều hành cho phép. Ba điểm chạm là ba
   thời điểm chắc chắn app đang chạy và người dùng sắp nhìn thấy kết quả.
3. **Vì sao clock phải inject?** Vì biên "đúng 30 ngày" là biên phải chạy được
   trong test, và `DateTime.now()` trong feature là thứ AD-06 tồn tại để chặn.
4. **Vì sao purge theo batch chứ không theo hàng?** Vì một hàng lẻ bị purge sẽ
   để lại một batch không restore được trọn vẹn — đúng thứ rule 9 gọi là "batch
   restore dang dở".
5. **Vì sao vẫn phải kiểm descendant trước khi purge, khi thứ tự thời gian đã
   đảm bảo?** Vì "đảm bảo" đó dựa trên một bất biến khác (không có hàng active
   dưới một hàng đã xoá, và descendant luôn bị xoá trước hoặc cùng lúc với tổ
   tiên). Một guard đọc được là cách duy nhất để khi bất biến kia hỏng, purge
   dừng lại thay vì cascade qua một batch chưa tới hạn.

## 5. Subtree consistency

1. **Vì sao batch phải là một identity chứ không phải một timestamp?** Vì hai
   lần xoá cách nhau dưới một giây sẽ có cùng timestamp, và restore khi đó hồi
   sinh cả hai.
2. **Vì sao descendant đã ở Trash từ trước giữ tombstone cũ?** Vì người dùng đã
   xoá nó *riêng*. Restore cha là hoàn tác một thao tác, không phải hoàn tác mọi
   thao tác từng chạm vào cây đó.
3. **Vì sao không suy ra batch từ parent hiện tại?** Vì sau khi restore, parent
   của một hàng có thể đã đổi; và vì hai batch chồng nhau trong cùng một subtree
   là trạng thái hợp lệ. Parent trả lời "nó ở đâu", không trả lời "nó đi cùng ai".
4. **Vì sao `content_type` phải tự về `unset` khi xoá?** Vì BR-163 đã nói thế cho
   delete cứng, và soft-delete lấy đi *đúng cái mà* BR-163 đo: direct child đang
   hiện. Không tự reset thì một deck rỗng vẫn khoá loại nội dung của nó vĩnh viễn.
5. **Vì sao invariant phải lọc theo `delete_batch_id IS NULL`?** Vì nếu không,
   invariant 2 báo vi phạm cho mọi deck vừa được dọn rỗng đúng luật, và invariant
   29 im lặng cho mọi deck lẽ ra phải `unset`. Một invariant đo sai tập hàng là
   một invariant nói ngược.
