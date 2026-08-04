# Data model — memox

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Chốt hình dạng dữ liệu và các bất biến phải luôn đúng |
| **Scope** | Bảng, cột, index, quan hệ, query bất biến. Ngoài phạm vi: SQL runtime (`lib/core/database/`, chưa tồn tại) |
| **Source of truth for** | Schema · cột và kiểu · index · query bất biến · thứ tự migration |
| **Depends on** | `document-conventions.md`, `architecture.md`, `business-rules.md` |
| **Updated by task** | Sửa fold search (cột `front_folded`/`back_folded`, schema v3) |
| **Last updated** | 2026-08-04 |

Schema viết trong file `.drift` (AD-02). Đây là tài liệu thiết kế; SQL thật nằm
ở `lib/core/database/tables/` và **chưa được tạo** — task này chỉ chốt đặc tả.

Ba nguyên tắc chi phối cách chia bảng:

1. **Nội dung, trạng thái lịch, và lịch sử có ba vòng đời khác nhau**, nên là ba
   bảng. Nội dung sửa mà không đụng lịch (BR-10); lịch đổi mỗi lần ôn; lịch sử chỉ
   thêm, không bao giờ sửa.
2. **`scheduler_generation` có mặt ở mọi nơi trạng thái học tồn tại**, để "thuộc
   chu kỳ nào" là dữ kiện trong dữ liệu chứ không phải quy ước ngầm (AD-09).
3. **Trạng thái được lưu tường minh, không suy luận** — `review_kind`,
   `session.status`, `end_reason`, `content_type`, `root_deck_id` đều là cột thật
   (AD-10, AD-11).

---

## Tổng quan

```
deck_templates (asset JSON ở MVP)
        │ sao chép một lần, không liên kết ghi ngược
        ▼
     decks ──┐ parent_deck_id  (cây nhiều cấp)
       │  ▲  │ root_deck_id    (mọi descendant trỏ thẳng về root)
       │  └──┘
       │
       ├──► cards ──┬──► card_review_states   (1–1, mang generation)
       │            └──► review_history       (1–n, append-only, mang generation)
       │
       └──► study_sessions ──► review_history
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
| `scheduler_config` | TEXT NULL | JSON tham số ghi đè. Cùng quy tắc NULL |
| `scheduler_generation` | INTEGER NULL | bắt đầu từ 1, +1 mỗi lần reset (BR-40). Chỉ trên root |
| `first_review_at` | DATETIME NULL | NULL = chưa có lượt `scheduled` ở generation hiện tại → scheduler mở khoá |
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

`is_flagged` nằm ở đây chứ không ở `card_review_states` và đó là cùng một lập
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

## `card_review_states`

Một dòng cho mỗi card, tạo cùng lúc với card (BR-09). Xoá và tạo lại khi reset.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT PK | → `cards(id)` ON DELETE CASCADE. PK vì quan hệ 1–1 |
| `scheduler_type` | TEXT NOT NULL | phải bằng scheduler của root deck |
| `scheduler_version` | INTEGER NOT NULL | |
| `scheduler_generation` | INTEGER NOT NULL | phải bằng generation hiện tại của root (BR-49) |
| `due_at` | DATETIME NULL | chung cho mọi scheduler. NULL = đến hạn ngay. UTC |
| `last_reviewed_at` | DATETIME NULL | cập nhật ở cả `scheduled` lẫn `relearning` (BR-20) |
| `review_count` | INTEGER NOT NULL DEFAULT 0 | chỉ đếm `scheduled` (BR-20) |
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

Index: `idx_review_states_due` trên `(due_at)` — query nóng nhất của app.

## `review_history`

Append-only. Không sửa, không xoá — kể cả khi reset (BR-43). Chỉ mất khi card bị
xoá (cascade).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `card_id` | TEXT NOT NULL | → `cards(id)` ON DELETE CASCADE |
| `session_id` | TEXT NOT NULL | → `study_sessions(id)` |
| `scheduler_type` | TEXT NOT NULL | scheduler tại thời điểm đánh giá |
| `scheduler_generation` | INTEGER NOT NULL | generation tại thời điểm đánh giá |
| `review_kind` | TEXT NOT NULL | `'scheduled'` \| `'relearning'` (BR-75, BR-76) |
| `action` | TEXT NOT NULL | `forgotten`/`remembered` hoặc `again`/`hard`/`good`/`easy` |
| `reviewed_at` | DATETIME NOT NULL | UTC |
| `next_due_at` | DATETIME NULL | hạn sau khi đánh giá |
| `previous_box` | INTEGER NULL | chỉ `eight_box` |
| `next_box` | INTEGER NULL | chỉ `eight_box` |
| `previous_ease_factor` | REAL NULL | chỉ `sm2` |
| `next_ease_factor` | REAL NULL | chỉ `sm2` |
| `previous_interval_days` | INTEGER NULL | chỉ `sm2` |
| `next_interval_days` | INTEGER NULL | chỉ `sm2` |

`review_kind` là cột thật, **không suy ra** từ việc so `previous_*` với `next_*`
(BR-76, AD-11). Suy luận sai ở đúng một ca không hiếm: lượt `scheduled` trên card
ở box 8 trả lời `remembered` cũng có `previous_box == next_box == 8`.

Giữ history qua các lần reset là lý do bảng này mang `scheduler_type` và
`scheduler_generation` thay vì tra ngược lên deck: deck chỉ biết generation
**hiện tại**, còn dòng history phải nói được nó thuộc chu kỳ nào theo luật nào.

Index: `idx_history_card` trên `(card_id, reviewed_at)`; `idx_history_session`
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
| `status` | TEXT NOT NULL | `in_progress` \| `completed` \| `abandoned` \| `invalidated` \| `failed` (BR-79) |
| `end_reason` | TEXT NULL | `user_exit` \| `scheduler_reset` \| `stale_generation` \| `persistence_error` (BR-80). NULL khi `in_progress` hoặc `completed` |
| `started_at` | DATETIME NOT NULL | UTC |
| `ended_at` | DATETIME NULL | NULL khi `in_progress` |

Ma trận `status` × `end_reason` hợp lệ:

| status | end_reason | Khi nào |
|---|---|---|
| `in_progress` | NULL | phiên đang mở |
| `completed` | NULL | hết queue (BR-81) |
| `abandoned` | `user_exit` | người dùng thoát (BR-82) |
| `invalidated` | `scheduler_reset` | reset khi phiên đang mở (BR-83) |
| `invalidated` | `stale_generation` | phiên generation cũ cố ghi review (BR-84) |
| `failed` | `persistence_error` | lỗi không thể tiếp tục (BR-85) |

Mọi tổ hợp khác là dữ liệu sai.

`scheduler_generation` ở đây là thứ chặn tình huống ở AD-09: phiên mở trước khi
reset, người dùng quay lại bấm đánh giá sau khi reset. Mọi thao tác ghi so
generation của session với generation hiện tại của root và **từ chối** nếu lệch
(BR-46, BR-84).

Các review đã ghi thành công trước khi phiên kết thúc bất thường **vẫn được giữ**
(BR-86) — chuyển `status` không kéo theo xoá `review_history`.

**Hàng đợi của phiên không lưu trong DB.** Nó là trạng thái tạm trong controller.

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
| `default_scheduler_type` | scheduler gợi ý; người dùng đổi được trước lượt review đầu |

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
-- 9. Card review state không cùng scheduler hoặc generation với root (BR-48, BR-49)
SELECT s.card_id FROM card_review_states s
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
  OR (status = 'abandoned'   AND end_reason = 'user_exit')
  OR (status = 'invalidated' AND end_reason IN ('scheduler_reset','stale_generation'))
  OR (status = 'failed'      AND end_reason = 'persistence_error')
);

-- 13. Session đã kết thúc nhưng thiếu ended_at
SELECT id FROM study_sessions
WHERE status <> 'in_progress' AND ended_at IS NULL;
```

### Review history

```sql
-- 14. Lượt relearning làm đổi lịch (BR-78)
SELECT id FROM review_history
WHERE review_kind = 'relearning'
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
chỉ là chú thích. Cần test: xoá root deck → toàn bộ cây deck con, card, review
state, review history và study session đều biến mất (BR-03).

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
