# Data model — memox

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Chốt hình dạng dữ liệu và các bất biến phải luôn đúng |
| **Scope** | Bảng, cột, index, quan hệ, query bất biến. Ngoài phạm vi: SQL runtime (`lib/core/database/`, chưa tồn tại) |
| **Source of truth for** | Schema · cột và kiểu · index · query bất biến · thứ tự migration |
| **Depends on** | `document-conventions.md`, `architecture.md`, `business-rules.md` |
| **Updated by task** | M5.0o (recursive review lượt hai) |
| **Last updated** | 2026-08-07 |

Schema viết trong file `.drift` (AD-02). Đây là tài liệu thiết kế; SQL thật nằm ở
`lib/core/database/tables/`, hiện ở **schema v4**.

**`review` vẫn còn nghĩa thứ hai trong repo, và nó không đổi.** Ở `docs/reviews/`,
"vòng review UI/UX", "code review" — đó là *rà soát*, không phải *ôn tập*. Đợt đổi
tên cố tình không đụng tới chúng, nên gặp chữ `review` ở đâu đó không có nghĩa là
sót.

**Năm chỗ trong `lib/` đang implement định nghĩa đã bị thay.** Chúng **đúng với
schema v4** và sẽ đổi cùng migration mang `learned_at`; liệt kê ở đây để không ai
đọc chúng rồi tưởng tài liệu sai, hoặc sửa chúng trước khi có cột để sửa:

| Nơi | Đang dùng | Phải thành |
|---|---|---|
| `card_state_model.dart` | `answerCount == 0` ⇒ `new` | `learned_at IS NULL` (BR-90) |
| `card.drift` — `newCount` | `answer_count = 0` | `learned_at IS NULL` |
| `deck.drift` ×2 | `due_at IS NULL OR due_at <= now` | hai số tách biệt (BR-150) |
| `study.drift` | cùng vị từ trên cho hàng đợi | hai tập của BR-142 |
| `card_list_query_mapper.dart` | comment nói quan hệ này "đúng hôm nay" | vị từ đổi, quan hệ giữ (invariant 24, 25) |

**Chưa tồn tại ở schema nào** — đến cùng đợt migration tiếp theo của M5: bảng
`study_queue_items`; `study_sessions.current_mode`, `cursor`, `card_limit`;
`study_answers.mode`, `outcome_reason`, `comparison_version`, `used_hint`; giá trị
`interrupted` của `end_reason`; và hai StudyMode `browse` / `self_assess`.
Mọi tên còn lại trong tài liệu này **đã là tên thật trong database** kể từ schema v4.

Ba nguyên tắc chi phối cách chia bảng:

1. **Nội dung, trạng thái lịch, và lịch sử có ba vòng đời khác nhau**, nên là ba
   bảng. Nội dung sửa mà không đụng lịch (BR-10); lịch đổi mỗi lần ôn; lịch sử chỉ
   thêm, không bao giờ sửa.
2. **`scheduler_generation` có mặt ở mọi nơi trạng thái học tồn tại**, để "thuộc
   chu kỳ nào" là dữ kiện trong dữ liệu chứ không phải quy ước ngầm (AD-09).
3. **Trạng thái được lưu tường minh, không suy luận** — `kind`,
   `session.status`, `end_reason`, `content_type`, `root_deck_id` đều là cột thật
   (AD-10, AD-11).

---

## Tổng quan

```
app_settings (một dòng — mặc định tùy chọn học)

deck_templates (asset JSON ở MVP)
        │ sao chép một lần, không liên kết ghi ngược
        ▼
     decks ──┐ parent_deck_id  (cây nhiều cấp)
       │  ▲  │ root_deck_id    (mọi descendant trỏ thẳng về root)
       │  └──┘
       │
       ├──► cards ──┬──► card_study_states   (1–1, mang generation)
       │            └──► study_answers       (1–n, append-only, mang generation)
       │
       └──► study_sessions ──┬──► study_answers
                             └──► study_queue_items  (một hàng đợi mỗi stage, BR-113)
```

---

## `decks`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client (AD-03) |
| `name` | TEXT NOT NULL | BR-01 |
| `parent_deck_id` | TEXT NULL | NULL = root deck. → `decks(id)` ON DELETE CASCADE |
| `root_deck_id` | TEXT NOT NULL | root có `root_deck_id = id`; descendant mang id của root (BR-56) |
| `content_type` | TEXT NOT NULL | `'unset'` \| `'card'` \| `'deck'` (BR-60…BR-68) |
| `owner_id` | TEXT NULL | NULL = local profile (AD-03) |
| `scheduler_type` | TEXT NULL | `'eight_box'` \| `'sm2'`. **NOT NULL trên root, NULL trên deck con** |
| `scheduler_version` | INTEGER NULL | cùng quy tắc NULL |
| `scheduler_config` | TEXT NULL | JSON tham số ghi đè của thuật toán. Cùng quy tắc NULL |
| `study_config` | TEXT NULL | JSON tùy chọn học ghi đè mặc định toàn app (BR-147). NULL = theo mặc định. Chỉ trên root |
| `scheduler_generation` | INTEGER NULL | bắt đầu từ 1, +1 mỗi lần reset (BR-40). Chỉ trên root |
| `first_answered_at` | DATETIME NULL | NULL = chưa có lượt `scheduled` ở generation hiện tại → scheduler mở khoá |
| `source_template_id` | TEXT NULL | NULL = deck tự tạo (BR-34) |
| `source_template_version` | INTEGER NULL | version tại thời điểm sao chép |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

### Duyệt cây — hai loại query, hai quy tắc

Cây có tối đa **10 cấp**, root là cấp 1 (BR-55). Hai giới hạn khác nhau chi
phối cách viết query duyệt cây:

1. **Query duyệt subtree** (`subtreeDeckIds`, `subtreeCardCount`,
   `updateSubtreeRootDeck` trong `queries/deck.drift`) MUST cycle-safe bằng
   recursive `UNION` — mỗi node chỉ đi qua một lần vì dòng trùng bị loại — và
   MUST NOT dùng depth cap để cắt kết quả. Một cap biến dữ liệu hỏng thành kết
   quả thiếu trong im lặng: card count nói dối dialog xoá, root rewrite bỏ sót
   node — chính là vi phạm mà bất biến 6 tồn tại để bắt.
2. **Query probe độ sâu** (`deckDepthProbe` — cấp của một deck, chính nó là
   bước 1; `subtreeHeightProbe` — chiều cao subtree, chính nó là 1) mang cột
   depth nên `UNION` không khử trùng được; chúng MUST nhận giới hạn duyệt qua
   **parameter** do caller suy từ hằng số domain duy nhất
   (`DeckEntity.maxTreeDepth`), và chạm giới hạn MUST được caller coi là lỗi
   (từ chối thao tác), không phải một câu trả lời ngắn hơn.

Giới hạn 10 cấp được cưỡng chế ở repository (`createSubDeck`, `moveDeck` —
kiểm trước mọi mutation), và kiểm tra được bằng bất biến 15. Cycle protection
là concern riêng: bất biến 8 phát hiện cycle, với safety cap riêng của một
diagnostic checker.

### `root_deck_id` — vì sao tồn tại

Xác định root bằng cách đi ngược `parent_deck_id` cần đệ quy, và không diễn đạt
được thành một điều kiện JOIN đơn giản — mà JOIN đó nằm trong query nóng nhất của
app.

`COALESCE(parent_deck_id, id)` **bị cấm** (BR-57, AD-10). Nó có nghĩa "cha, hoặc
chính nó nếu không có cha", nên với deck ở cấp 3 nó trả về deck cấp 2 chứ không
phải root. Với cây một cấp nó đúng — và đó chính là điều khiến nó nguy hiểm.

Cái giá: di chuyển subtree phải cập nhật `root_deck_id` cho toàn bộ subtree trong
một transaction (BR-71). Bỏ sót một node tạo ra descendant trỏ sai root — dữ liệu
hỏng im lặng, vì query vẫn chạy và chỉ trả về kết quả thiếu.

### `content_type` — bao gồm cả root

`content_type` là NOT NULL cho **mọi** deck. Root deck được tạo thẳng với
`content_type = 'deck'` và giá trị đó bất biến — đó là cách BR-58 ("root chỉ chứa
deck con") trở thành một ràng buộc kiểm tra được bằng cùng một câu query như các
deck khác, thay vì một luật riêng phải nhớ.

| Deck | `content_type` khi tạo | Đổi được không |
|---|---|---|
| root | `'deck'` | không |
| deck con | `'unset'` | `unset` → `card`/`deck` ở phần tử con đầu tiên (BR-62); về `unset` chỉ qua thao tác reset tường minh khi rỗng (BR-68) |

### Cột scheduler chỉ trên root

Deck con để NULL và tra qua `root_deck_id` (BR-06). Đây là cách khiến "deck con
không chọn scheduler riêng" bất khả thi về cấu trúc, thay vì chỉ là quy ước.

Index — composite, và thứ tự cột theo đúng thứ tự query lọc rồi sắp:
- `idx_decks_parent_created` trên `(parent_deck_id, created_at, id)` — dựng cây
  (`rootDecks`, `childDecks`)
- `idx_decks_root_created` trên `(root_deck_id, created_at, id)` — mọi query gộp
  theo cây (`decksInTree`, `allDecks`, hai subquery của `rootDeckSummaries`)

Mọi query đọc deck đều lọc theo một trong hai cột dẫn đầu rồi `ORDER BY
created_at, id`. Với index chỉ một cột, cả ba đều kết thúc bằng `USE TEMP B-TREE
FOR ORDER BY` — SQLite đọc hết row khớp rồi sắp, trước khi áp bất kỳ `LIMIT` nào.
Đo bằng `EXPLAIN QUERY PLAN`: thêm cột sắp vào index thì temp B-tree biến mất, và
subquery `total` của `rootDeckSummaries` trở thành **covering** (không chạm bảng).
Index composite thay thế bản một cột chứ không cộng thêm: cùng cột dẫn đầu thì nó
trả lời được mọi lookup cũ, giữ cả hai chỉ khiến mỗi insert bảo trì hai B-tree.

## `cards`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `deck_id` | TEXT NOT NULL | → `decks(id)` ON DELETE CASCADE. Chỉ deck có `content_type = 'card'` (BR-63) |
| `front` | TEXT NOT NULL | BR-07, BR-08 |
| `back` | TEXT NOT NULL | BR-07, BR-08 |
| `front_folded` | TEXT NOT NULL DEFAULT '' | `front` đã trim + hạ hoa bằng Dart. Search so trên cột này |
| `back_folded` | TEXT NOT NULL DEFAULT '' | Như trên, cho `back` |
| `is_flagged` | INTEGER NOT NULL DEFAULT 0 | 0 \| 1. Cờ người dùng đánh dấu (BR-92) |
| `example` | TEXT NULL | Tuỳ chọn (BR-95) |
| `hint` | TEXT NULL | Tuỳ chọn (BR-95) |
| `pronunciation` | TEXT NULL | Tuỳ chọn (BR-95) |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

**Hai cột `_folded` tồn tại vì `lower()` của SQLite chỉ hạ hoa ASCII.** Nó không
đụng tới `Ô`, `Ê`, `Đ`. Search từng so `instr(lower(front), :term)` với `:term`
đã được Dart hạ hoa theo Unicode — hai vế fold bằng hai luật khác nhau, nên thẻ
lưu `CÔNG NGHỆ` không tìm ra được bằng `công nghệ`, trong khi thẻ viết thường thì
tìm được. Fold cả hai vế trong Dart biến phép so thành byte-for-byte và đúng cho
mọi bảng chữ cái. Đây đúng là lập luận `tags.name_folded` đã dùng ở v2 (BR-93),
áp cho hai mặt thẻ.

Chỉ hạ hoa, **không** bỏ dấu: `công` vẫn không khớp `cong`. Tìm kiếm không dấu là
quyết định sản phẩm (S1), không phải hệ quả phụ của một bản vá.

`DEFAULT ''` vì SQLite bắt buộc có default khi thêm cột NOT NULL. Mọi lượt ghi
đều đi qua repository và luôn ghi giá trị thật; migration v3 backfill toàn bộ
dòng cũ **bằng Dart**, vì `SET front_folded = lower(front)` sẽ ghi đúng những giá
trị hỏng mà cột này sinh ra để thay thế.

**Không có cột SRS nào ở đây**, và không có `scheduler_generation` — card là nội
dung, nó sống xuyên qua mọi lần reset (BR-41). Reset learning progress không được
chạm vào bảng này.

Ba trường phụ để **NULL, không phải chuỗi rỗng**. NULL nghĩa là người dùng chưa
điền; chuỗi rỗng nghĩa là họ điền rồi xoá — và không màn nào phân biệt được hai
thứ đó, nên cho phép cả hai chỉ tạo ra hai cách biểu diễn một trạng thái. Lớp
domain trim rồi quy chuỗi rỗng về NULL trước khi ghi, cùng chỗ `CardText` trim.

`is_flagged` nằm ở đây chứ không ở `card_study_states` và đó là cùng một lập
luận: cờ là thứ người dùng đặt lên *nội dung* — "quay lại thẻ này" — nên nó phải
sống sót qua reset. Đặt nó cạnh `current_box` sẽ khiến reset xoá nó cùng lịch
(BR-92).

Index: `idx_cards_deck_created` trên `(deck_id, created_at, id)` — composite,
theo đúng thứ tự `cardsByDeck` lọc rồi sắp. Đây là điều kiện để phân trang keyset
(`WHERE deck_id = ? AND (created_at, id) > (?, ?)`) là một range scan thật thay vì
một lần sắp toàn bộ deck rồi đặt `LIMIT` lên trên: đo trên 5.000 thẻ một deck, một
trang 50 thẻ đi từ 1193µs xuống 102µs.

## `tags`

Nhãn phân loại nội dung do người dùng đặt — `noun`, `people`, `verb`. Nội dung,
không phải lịch: reset giữ nguyên (BR-41, BR-93).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client (AD-03) |
| `name` | TEXT NOT NULL | BR-93. Lưu nguyên dạng người dùng gõ |
| `name_folded` | TEXT NOT NULL | `lower(trim(name))`. Cột để **cưỡng chế** unique |
| `owner_id` | TEXT NULL | NULL = local profile (AD-03) |
| `created_at` | DATETIME NOT NULL | UTC |

Index: `UNIQUE (owner_id, name_folded)`.

**`name_folded` là một cột thật, không phải một expression index**, vì BR-93 đòi
unique không phân biệt hoa thường và SQLite chỉ có `NOCASE` cho ASCII — một tag
tiếng Việt `Động từ` và `động từ` sẽ lọt qua `COLLATE NOCASE`. Ghi cột đã fold
lúc insert thì phép so sánh là byte-với-byte và đúng cho mọi bảng chữ.

Tag **không** thuộc về một deck. Cùng một `noun` dùng lại ở mọi deck; buộc nó
theo deck sẽ sinh ra bản sao mỗi lần người dùng tạo deck mới, và lúc lọc thì
chúng là các tag khác nhau.

## `card_tags`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT NOT NULL | → `cards(id)` ON DELETE CASCADE |
| `tag_id` | TEXT NOT NULL | → `tags(id)` ON DELETE CASCADE |

PK là `(card_id, tag_id)`. Index thứ hai `idx_card_tags_tag` trên `(tag_id,
card_id)` cho chiều ngược lại — "mọi thẻ mang tag này" là câu mà bộ lọc hỏi, và
PK không phục vụ được nó.

Cả hai FK đều `CASCADE`: xoá thẻ thì liên kết mất theo (BR-92 nói cùng điều đó
cho cờ), xoá tag thì nó biến khỏi mọi thẻ. Không có bản ghi mồ côi nào cần dọn.

## `card_study_states`

Một dòng cho mỗi card, tạo cùng lúc với card (BR-09). Xoá và tạo lại khi reset.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT PK | → `cards(id)` ON DELETE CASCADE. PK vì quan hệ 1–1 |
| `scheduler_type` | TEXT NOT NULL | phải bằng scheduler của root deck |
| `scheduler_version` | INTEGER NOT NULL | |
| `scheduler_generation` | INTEGER NOT NULL | phải bằng generation hiện tại của root (BR-49) |
| `learned_at` | DATETIME NULL | NULL = chưa xong chuỗi học mới (BR-144). Đặt một lần, không bao giờ về NULL trừ khi Reset |
| `due_at` | DATETIME NULL | NULL = chưa có lịch, tức chưa học xong lần đầu. UTC |
| `last_answered_at` | DATETIME NULL | cập nhật ở cả `scheduled` lẫn `relearning` (BR-20) |
| `answer_count` | INTEGER NOT NULL DEFAULT 0 | chỉ đếm `scheduled` (BR-20) |
| `lapse_count` | INTEGER NOT NULL DEFAULT 0 | BR-20 |
| `current_box` | INTEGER NULL | **chỉ `eight_box`**: 1..8 |
| `ease_factor` | REAL NULL | **chỉ `sm2`**: mặc định 2.5, sàn 1.3 |
| `interval_days` | INTEGER NULL | **chỉ `sm2`** |
| `repetitions` | INTEGER NULL | **chỉ `sm2`** |

`scheduler_type` và `scheduler_generation` lặp lại từ root là **denormalization có
chủ đích**: nó biến hai bất biến của AD-09 thành thứ kiểm tra được bằng query thay
vì bằng niềm tin. Query kiểm tra ở mục "Bất biến" bên dưới.

Cột riêng của từng scheduler để NULL khi không thuộc scheduler đang dùng. Phương
án gói vào JSON linh hoạt hơn nhưng mất type-safety và không query được — mâu
thuẫn trực tiếp với lý do chọn AD-02.

Index: `idx_card_study_states_due` trên `(due_at)` — query nóng nhất của app.

## `study_answers`

Append-only. Không sửa, không xoá — kể cả khi reset (BR-43). Chỉ mất khi card bị
xoá (cascade).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `card_id` | TEXT NOT NULL | → `cards(id)` ON DELETE CASCADE |
| `session_id` | TEXT NOT NULL | → `study_sessions(id)` |
| `scheduler_type` | TEXT NOT NULL | scheduler tại thời điểm đánh giá |
| `scheduler_generation` | INTEGER NOT NULL | generation tại thời điểm đánh giá |
| `kind` | TEXT NOT NULL | `'learning'` \| `'scheduled'` \| `'relearning'` (BR-75, BR-76, BR-143) |
| `mode` | TEXT NOT NULL | StudyMode của lượt (BR-108, BR-98). `browse` không bao giờ xuất hiện ở đây (BR-111) |
| `outcome_reason` | TEXT NULL | `timeout` khi hết giờ ở `recall` (BR-131); NULL khi người dùng tự trả lời |
| `comparison_version` | INTEGER NULL | chỉ `fill`: phiên bản chính sách so khớp đã dùng (BR-135) |
| `used_hint` | INTEGER NULL | chỉ `fill`: 0 \| 1. Ghi nhận, không đổi `action` (BR-136) |
| `action` | TEXT NOT NULL | `forgotten`/`remembered` hoặc `again`/`hard`/`good`/`easy` |
| `answered_at` | DATETIME NOT NULL | UTC |
| `next_due_at` | DATETIME NULL | hạn sau khi đánh giá |
| `previous_box` | INTEGER NULL | chỉ `eight_box` |
| `next_box` | INTEGER NULL | chỉ `eight_box` |
| `previous_ease_factor` | REAL NULL | chỉ `sm2` |
| `next_ease_factor` | REAL NULL | chỉ `sm2` |
| `previous_interval_days` | INTEGER NULL | chỉ `sm2` |
| `next_interval_days` | INTEGER NULL | chỉ `sm2` |

`kind` là cột thật, **không suy ra** từ việc so `previous_*` với `next_*`
(BR-76, AD-11). Suy luận sai ở đúng một ca không hiếm: lượt `scheduled` trên card
ở box 8 trả lời `remembered` cũng có `previous_box == next_box == 8`.

Giữ history qua các lần reset là lý do bảng này mang `scheduler_type` và
`scheduler_generation` thay vì tra ngược lên deck: deck chỉ biết generation
**hiện tại**, còn dòng history phải nói được nó thuộc chu kỳ nào theo luật nào.

Index: `idx_study_answers_card` trên `(card_id, answered_at)`; `idx_study_answers_session`
trên `(session_id)`.

Bảng này lớn nhanh nhất — mỗi lượt đánh giá một dòng, reset không dọn bớt. Đây là
bảng đầu tiên cần nhìn khi bàn về kích thước DB.

## `study_sessions`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `deck_id` | TEXT NOT NULL | → `decks(id)` ON DELETE CASCADE. Deck được ôn (thường là root hoặc một nhánh) |
| `root_deck_id` | TEXT NOT NULL | root của cây tại thời điểm mở phiên |
| `scheduler_generation` | INTEGER NOT NULL | generation lúc mở phiên (BR-45) |
| `session_kind` | TEXT NOT NULL | `learning` \| `reviewing` (BR-142) |
| `current_mode` | TEXT NOT NULL | stage đang chạy: `browse` \| `self_assess` \| `match` \| `guess` \| `recall` \| `fill` (BR-108, BR-98). Phiên `reviewing` chỉ có một giá trị suốt phiên |
| `status` | TEXT NOT NULL | `in_progress` \| `completed` \| `abandoned` \| `invalidated` \| `failed` (BR-79) |
| `end_reason` | TEXT NULL | `user_exit` \| `scheduler_reset` \| `stale_generation` \| `persistence_error` \| `interrupted` (BR-80). NULL khi `in_progress` hoặc `completed` |
| `cursor` | INTEGER NOT NULL DEFAULT 0 | số lượt đã phục vụ trong phiên; nền của BR-26 |
| `card_limit` | INTEGER NOT NULL | số thẻ tối đa của phiên, chốt lúc mở (BR-24, BR-139). Mặc định 20 |
| `started_at` | DATETIME NOT NULL | UTC |
| `ended_at` | DATETIME NULL | NULL khi `in_progress` |

Ma trận `status` × `end_reason` hợp lệ:

| status | end_reason | Khi nào |
|---|---|---|
| `in_progress` | NULL | phiên đang mở |
| `completed` | NULL | hết queue (BR-81) |
| `abandoned` | `user_exit` | người dùng thoát (BR-82) |
| `abandoned` | `interrupted` | phiên của ngày học trước còn `in_progress` khi mở app (BR-103) |
| `invalidated` | `scheduler_reset` | reset khi phiên đang mở (BR-83) |
| `invalidated` | `stale_generation` | phiên generation cũ cố ghi lượt học (BR-84) |
| `failed` | `persistence_error` | lỗi không thể tiếp tục (BR-85) |

Mọi tổ hợp khác là dữ liệu sai.

`scheduler_generation` ở đây là thứ chặn tình huống ở AD-09: phiên mở trước khi
reset, người dùng quay lại bấm đánh giá sau khi reset. Mọi thao tác ghi so
generation của session với generation hiện tại của root và **từ chối** nếu lệch
(BR-46, BR-84).

Các lượt học đã ghi thành công trước khi phiên kết thúc bất thường **vẫn được giữ**
(BR-86) — chuyển `status` không kéo theo xoá `study_answers`.

`interrupted` tách khỏi `user_exit` vì cùng lý do BR-76 lưu `kind` tường minh:
"người dùng bấm thoát" và "hệ điều hành thu hồi app" là hai sự kiện khác nhau, và
gộp chúng làm lịch sử nói rằng người dùng bỏ cuộc trong khi họ không hề.

## `study_queue_items`

Hàng đợi của một phiên (BR-102). Một dòng cho mỗi thẻ được nạp lúc mở phiên.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `session_id` | TEXT NOT NULL | → `study_sessions(id)` ON DELETE CASCADE |
| `mode` | TEXT NOT NULL | stage mà dòng này thuộc về (BR-113) |
| `round` | INTEGER NOT NULL DEFAULT 1 | vòng trong stage (BR-115). `browse` và `self_assess` luôn `1` |
| `card_id` | TEXT NOT NULL | → `cards(id)` ON DELETE CASCADE |
| `position` | INTEGER NOT NULL | thứ tự trong round đó (BR-23, BR-117). **Bất biến một khi round đã dựng** |
| `status` | TEXT NOT NULL | `pending` \| `completed` (BR-28) |
| `available_at` | INTEGER NOT NULL DEFAULT 0 | mốc `cursor` tối thiểu để thẻ được phục vụ lại (BR-26) |
| `answers_in_session` | INTEGER NOT NULL DEFAULT 0 | số lượt đã đánh giá; `0` ⇒ lượt tới là `scheduled` (BR-77) |
| `remaining_ms` | INTEGER NULL | chỉ `recall`: thời gian còn lại của lượt đang dở (BR-133). NULL ở mọi stage khác |
| `is_revealed` | INTEGER NOT NULL DEFAULT 0 | chỉ `recall`: đáp án đã lật chưa, để Resume không che lại (BR-133) |

PK là `(session_id, mode, round, card_id)` — một thẻ xuất hiện đúng một lần **trong
mỗi round của mỗi stage**, và mọi round có thứ tự độc lập (BR-113, BR-117).

Giới hạn thẻ của BR-24 vì thế được đếm trên **tập thẻ riêng biệt của phiên**,
không phải trên số dòng — một phiên 20 thẻ × 5 stage đã là 100 dòng trước khi có
bất kỳ round nào. Xem invariant 18.

### Vì sao là `cursor` + `available_at`, không phải xáo lại `position`

BR-26 bắt thẻ bị quên quay lại "sau ít nhất 3 thẻ khác". Cách thẳng tay là ghi
lại `position` rồi dịch mọi thẻ phía sau — mỗi lượt `forgotten` thành một loạt
UPDATE, và thứ tự gốc mất luôn.

Thay vào đó mỗi lượt tăng `study_sessions.cursor` lên 1, còn thẻ bị quên được đặt
`available_at = cursor + 3`. Không dịch gì, một số thay một số:

```sql
SELECT card_id FROM study_queue_items
WHERE session_id = :s AND status = 'pending' AND available_at <= :cursor
ORDER BY position LIMIT 1
```

Rỗng nhưng vẫn còn `pending` nghĩa là chỉ còn thẻ đang chờ quay lại — đúng vế thứ
hai của BR-26 ("cuối hàng đợi nếu không đủ 3") — và phục vụ thẻ có `available_at`
nhỏ nhất. Vế đó thành một nhánh query, không phải một `if` ai đó phải nhớ viết.

### Vì sao hàng đợi rời `presentation/` để vào database

Tài liệu này trước đây nói hàng đợi là trạng thái tạm của controller. Nó đổi ở
BR-102, và lý do không phải là persistence: hàng đợi **mang luật** — thứ tự
BR-23, lượt quay lại BR-26, trần BR-104 — và một cấu trúc mang luật nằm trong
`presentation/` là chỗ luật đi ra khỏi tầm với của mọi phép kiểm chạy được.

Cái được kèm theo: phiên sống sót qua việc app bị hệ điều hành thu hồi (BR-103),
và hàng đợi của phiên đã đóng trở thành dữ liệu thật — "phiên đó gồm những thẻ
nào, bỏ dở bao nhiêu" — thứ hiện không tồn tại ở bất kỳ đâu.

## `app_settings`

Một dòng, cho local profile. Mặc định toàn app của tùy chọn học (BR-147).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | INTEGER PK | luôn `1`; `CHECK (id = 1)` giữ bảng ở đúng một dòng |
| `card_limit` | INTEGER NOT NULL DEFAULT 20 | trần thẻ **mỗi phiên**, không phải mỗi ngày (BR-24) |
| `new_card_order` | TEXT NOT NULL DEFAULT 'created' | `created` \| `random` (BR-148) |
| `updated_at` | DATETIME NOT NULL | UTC |

**Một bảng một dòng thay vì key-value.** Key-value đọc linh hoạt hơn nhưng mọi
giá trị thành `TEXT` và mọi lần đọc thành một phép ép kiểu không ai kiểm; một
dòng có cột thật thì `drift_dev` type-check ngay lúc build, và thêm một tùy chọn
là một migration — đúng mức nghiêm túc cần có cho thứ đổi hành vi học.

**Ghi đè nằm ở `decks.study_config`, không ở đây.** Deck root MAY mang JSON ghi
đè; deck con MUST NOT (BR-147), cùng quy tắc cột scheduler đã theo từ BR-06. Giá
trị hiệu lực = giá trị của root nếu có, ngược lại giá trị bảng này.

## `deck_templates`

**Ở MVP đây không phải bảng runtime** (AD-07) — template là asset JSON:

```
assets/templates/
├── manifest.json
└── vi/
    └── starter_fixture_a.json
```

| Trường | Ghi chú |
|---|---|
| `template_id` | ổn định giữa các phiên bản app (BR-32) |
| `version` | tăng khi nội dung đổi |
| `locale` | `vi`, `en`, … |
| `title` | tên hiển thị |
| `content_source` | nguồn gốc nội dung, cho ghi công và kiểm tra bản quyền |
| `default_scheduler_type` | scheduler gợi ý; người dùng đổi được trước lượt học đầu |

Template mô tả **cả cây deck**, không chỉ một danh sách card, vì bản sao phải
dựng lại đúng cấu trúc `content_type` và `root_deck_id`.

Nội dung starter hiện tại là **fixture do dự án tự tạo, chỉ phục vụ development
và test** (BR-87). Không mô tả nó như nội dung production ở bất kỳ đâu — UI, store
listing, hay tài liệu.

---

## Bất biến — phải kiểm tra được bằng query

Mỗi query dưới đây **phải luôn trả về 0 dòng**. Chúng là đặc tả cho phần kiểm tra
dữ liệu ở Phase 11, và là nguồn của các trường hợp trong validation script.

### Cây deck

```sql
-- 1. Root deck có card trực tiếp (BR-58)
SELECT c.id FROM cards c
JOIN decks d ON d.id = c.deck_id
WHERE d.parent_deck_id IS NULL;

-- 2. content_type = 'unset' nhưng đã có nội dung (BR-60, BR-62)
SELECT d.id FROM decks d
WHERE d.content_type = 'unset'
  AND (EXISTS (SELECT 1 FROM cards c WHERE c.deck_id = d.id)
    OR EXISTS (SELECT 1 FROM decks s WHERE s.parent_deck_id = d.id));

-- 3. content_type = 'card' nhưng có deck con (BR-63)
SELECT d.id FROM decks d
WHERE d.content_type = 'card'
  AND EXISTS (SELECT 1 FROM decks s WHERE s.parent_deck_id = d.id);

-- 4. content_type = 'deck' nhưng có card trực tiếp (BR-64)
SELECT d.id FROM decks d
WHERE d.content_type = 'deck'
  AND EXISTS (SELECT 1 FROM cards c WHERE c.deck_id = d.id);

-- 5. Root deck không mang content_type = 'deck'
SELECT d.id FROM decks d
WHERE d.parent_deck_id IS NULL AND d.content_type <> 'deck';

-- 6. Descendant trỏ sai root (BR-72)
--    root_deck_id của một deck phải bằng root_deck_id của cha nó.
SELECT d.id FROM decks d
JOIN decks p ON p.id = d.parent_deck_id
WHERE d.root_deck_id <> p.root_deck_id;

-- 7. Root deck không tự trỏ về chính nó (BR-56)
SELECT d.id FROM decks d
WHERE d.parent_deck_id IS NULL AND d.root_deck_id <> d.id;

-- 8. Cycle trong cây (BR-69)
--    Đi ngược từ mỗi deck lên tới root; gặp lại chính mình là cycle.
WITH RECURSIVE up(start_id, node_id, depth) AS (
  SELECT id, parent_deck_id, 1 FROM decks WHERE parent_deck_id IS NOT NULL
  UNION ALL
  SELECT u.start_id, d.parent_deck_id, u.depth + 1
  FROM up u JOIN decks d ON d.id = u.node_id
  WHERE u.node_id IS NOT NULL AND u.depth < 64
)
SELECT DISTINCT start_id FROM up WHERE node_id = start_id;

-- 15. Deck sâu hơn 10 cấp (BR-55)
--     Đi xuống từ mỗi root, root là cấp 1.
WITH RECURSIVE levels(id, depth) AS (
  SELECT id, 1 FROM decks WHERE parent_deck_id IS NULL
  UNION ALL
  SELECT d.id, l.depth + 1
  FROM decks d JOIN levels l ON d.parent_deck_id = l.id
  WHERE l.depth < 64
)
SELECT id FROM levels WHERE depth > 10;
```

Query 8 và 15 giới hạn `depth < 64` để bản thân chúng không thành vòng lặp vô
hạn khi dữ liệu đã hỏng — một checker treo là checker vô dụng. Cap đó là của
diagnostic checker; query production không dùng cap để cắt subtree (xem "Duyệt
cây" ở trên).

### Scheduler và generation

```sql
-- 9. Card study state không cùng scheduler hoặc generation với root (BR-48, BR-49)
SELECT s.card_id FROM card_study_states s
JOIN cards c ON c.id = s.card_id
JOIN decks d ON d.id = c.deck_id
JOIN decks root ON root.id = d.root_deck_id
WHERE s.scheduler_generation <> root.scheduler_generation
   OR s.scheduler_type <> root.scheduler_type;

-- 10. Deck con mang cột scheduler (BR-06)
SELECT d.id FROM decks d
WHERE d.parent_deck_id IS NOT NULL
  AND (d.scheduler_type IS NOT NULL OR d.scheduler_generation IS NOT NULL);

-- 11. Root deck thiếu scheduler (BR-11)
SELECT d.id FROM decks d
WHERE d.parent_deck_id IS NULL
  AND (d.scheduler_type IS NULL OR d.scheduler_generation IS NULL);
```

Chú ý query 9 dùng `d.root_deck_id`, **không** dùng `COALESCE(d.parent_deck_id,
d.id)`. Phiên bản cũ của tài liệu này dùng `COALESCE` và sẽ trả về sai root ngay
khi có deck ở cấp thứ ba (BR-57).

### Session

```sql
-- 12. Tổ hợp status × end_reason không hợp lệ (BR-79…BR-85)
SELECT id FROM study_sessions
WHERE NOT (
     (status = 'in_progress' AND end_reason IS NULL)
  OR (status = 'completed'   AND end_reason IS NULL)
  OR (status = 'abandoned'   AND end_reason IN ('user_exit','interrupted'))
  OR (status = 'invalidated' AND end_reason IN ('scheduler_reset','stale_generation'))
  OR (status = 'failed'      AND end_reason = 'persistence_error')
);

-- 13. Session đã kết thúc nhưng thiếu ended_at
SELECT id FROM study_sessions
WHERE status <> 'in_progress' AND ended_at IS NULL;
```

### Hàng đợi phiên

```sql
-- 16. Session completed nhưng hàng đợi còn thẻ chưa xong (BR-81)
SELECT s.id FROM study_sessions s
WHERE s.status = 'completed'
  AND EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = s.id AND q.status = 'pending');

-- 17. Bộ đếm của hàng đợi âm, hoặc lượt vượt trần BR-104
--     Trần 3 lượt relearning chỉ áp cho `self_assess` (BR-26, BR-104): 1 lượt
--     scheduled + 3 relearning = 4. Bốn stage chấm điểm lặp bằng round và
--     không có trần (BR-119), nên chúng không bị ràng buộc này.
SELECT session_id FROM study_queue_items
WHERE available_at < 0 OR answers_in_session < 0 OR round < 1
   OR (mode = 'self_assess' AND answers_in_session > 4);

-- 24. Thẻ đã xong học mới nhưng không có lịch (BR-144, BR-149)
SELECT card_id FROM card_study_states
WHERE learned_at IS NOT NULL AND due_at IS NULL;

-- 25. Thẻ chưa xong học mới mà đã có lượt `scheduled` (BR-144, BR-149)
--     Chuỗi học mới ghi `learning`/`relearning` và không đổi lịch; một lượt
--     `scheduled` ở đây nghĩa là lịch đã bị đặt giữa chừng.
SELECT a.id FROM study_answers a
JOIN card_study_states s ON s.card_id = a.card_id
WHERE a.kind = 'scheduled' AND s.learned_at IS NULL;

-- 26. `kind = 'learning'` nằm ngoài phiên học mới (BR-143)
SELECT a.id FROM study_answers a
JOIN study_sessions ss ON ss.id = a.session_id
WHERE a.kind = 'learning' AND ss.session_kind <> 'learning';

-- 27. Tùy chọn học nằm trên deck con (BR-147)
SELECT id FROM decks
WHERE parent_deck_id IS NOT NULL AND study_config IS NOT NULL;

-- 23. Cột đặc thù `fill` xuất hiện ở stage khác (BR-135, BR-136)
SELECT id FROM study_answers
WHERE mode <> 'fill' AND (comparison_version IS NOT NULL OR used_hint IS NOT NULL);

-- 21. Trạng thái timer nằm ngoài `recall`, hoặc vượt ngưỡng 20 giây (BR-128, BR-133)
SELECT session_id FROM study_queue_items
WHERE (mode <> 'recall' AND (remaining_ms IS NOT NULL OR is_revealed <> 0))
   OR remaining_ms < 0 OR remaining_ms > 20000;

-- 22. `outcome_reason = timeout` ở stage không phải `recall` (BR-131)
SELECT id FROM study_answers
WHERE outcome_reason IS NOT NULL
  AND (outcome_reason <> 'timeout' OR mode <> 'recall');

-- 19. Round nhảy số: stage có round N nhưng thiếu round N-1 (BR-115)
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1);

-- 20. Round sau chứa thẻ không có ở round trước (BR-115)
--     Tập của round N MUST là con của tập round N-1.
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1 AND p.card_id = q.card_id);

-- 18. Một phiên nạp quá số thẻ riêng biệt nó tự khai báo (BR-24, BR-139)
--     So với `card_limit` của **chính phiên đó**, không với một số viết cứng:
--     mặc định là 20 nhưng người dùng sẽ cài được, và một hằng số ở đây sẽ sai
--     ở đúng phiên đầu tiên họ đổi.
--     COUNT(DISTINCT card_id), không COUNT(*): mỗi thẻ có một dòng **mỗi round của
--     mỗi stage** (BR-113, BR-115), nên đếm dòng báo động giả ngay lập tức.
SELECT q.session_id FROM study_queue_items q
JOIN study_sessions s ON s.id = q.session_id
GROUP BY q.session_id, s.card_limit
HAVING COUNT(DISTINCT q.card_id) > s.card_limit;
```

Invariant 16 là thứ giữ cho `completed` có nghĩa. Không có nó, một phiên bỏ dở
được đánh dấu hoàn thành trông y hệt một phiên học hết — và sự khác nhau đó là
toàn bộ nội dung của BR-81.

### Study answers

```sql
-- 14. Lượt relearning làm đổi lịch (BR-78)
SELECT id FROM study_answers
WHERE kind = 'relearning'
  AND (previous_box IS NOT next_box
    OR previous_ease_factor IS NOT next_ease_factor
    OR previous_interval_days IS NOT next_interval_days);
```

---

## Quyết định về ID

Toàn bộ khoá chính là TEXT chứa UUID sinh phía client. Lý do ở AD-03: tạo dữ liệu
offline cần ID trước khi có server, và đổi kiểu khoá chính về sau là migration
đắt nhất có thể.

## Quyết định về thời gian

Mọi cột DATETIME lưu **UTC**. Chuyển sang giờ địa phương chỉ ở lớp hiển thị.

`due_at` so sánh sai một múi giờ nghĩa là card đến hạn sớm hoặc muộn một ngày, và
lỗi đó chỉ xuất hiện với người dùng đi qua múi giờ khác — gần như không bao giờ bị
phát hiện lúc dev.

## Foreign keys

`PRAGMA foreign_keys = ON` trong `beforeOpen`. Không có nó, `ON DELETE CASCADE`
chỉ là chú thích. Cần test: xoá root deck → toàn bộ cây deck con, card, study
state, study answers và study session đều biến mất (BR-03).

## Chưa mô hình hoá

Media được nhắc trong quy tắc reset (BR-41: reset giữ nguyên nó) nhưng **chưa
thuộc MVP** và chưa có bảng. Khi thêm, nó gắn với `cards` và không mang
`scheduler_generation` — nó là nội dung, và quy tắc "reset không chạm nội dung"
áp dụng nguyên vẹn.

Tag từng nằm ở mục này. Nó rời khỏi đây ở M4.10at, khi màn card cần hiển thị tag
và cờ — xem `docs/wireframes/m4-11-card-management.md`.

## Thứ tự migration dự kiến

| Version | Nội dung |
|---|---|
| 1 | Toàn bộ schema trên, trừ những gì v2 thêm |
| 2 | Bảng `tags`, `card_tags`; cột `cards.is_flagged`, `example`, `hint`, `pronunciation` (M4.10at) |
| 3 | Cột `cards.front_folded`, `back_folded` + backfill bằng Dart — sửa search không khớp chữ hoa non-ASCII |
| _sau_ | Bảng `card_media` |
| _sau_ | Cột sync (`is_pending_sync`, `version`) khi có backend (AD-03) |
| _sau_ | `deck_templates` thành bảng runtime nếu tải template từ server |

v2 là **thêm bảng và thêm cột** — không đụng dòng nào đang có. `is_flagged
DEFAULT 0` nghĩa là mọi thẻ cũ mở lên đúng trạng thái "chưa đánh dấu", và ba
trường phụ nullable nên thẻ cũ không cần giá trị nào. Đó là kết quả có chủ đích
của việc tách bảng ngay từ v1, không phải may.

**BR-08 siết từ 2000 xuống 60/240 ở cùng task, và migration không đụng tới nó.**
Không thẻ nào trong dữ liệu hiện tại vượt giới hạn mới — chưa có UI tạo thẻ, nên
chưa có thẻ người dùng nào tồn tại. Nếu điều đó đổi trước khi v2 chạy thì siết
giới hạn cần một bước dọn dữ liệu, và nó phải là quyết định tường minh chứ không
phải một `CHECK` làm hỏng lần mở app kế tiếp.

Tất cả đều là thêm cột hoặc thêm bảng — không đụng dữ liệu đang có. Đó là kết quả
có chủ đích của việc tách bảng, đặt `scheduler_generation` và `root_deck_id` ngay
từ v1.
