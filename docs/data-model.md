# Data model — memox

_Status: **frozen for MVP** · Last updated: 2026-07-28_

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

Index:
- `idx_decks_parent` trên `(parent_deck_id)` — dựng cây
- `idx_decks_root` trên `(root_deck_id)` — mọi query gộp theo cây

## `cards`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `deck_id` | TEXT NOT NULL | → `decks(id)` ON DELETE CASCADE. Chỉ deck có `content_type = 'card'` (BR-63) |
| `front` | TEXT NOT NULL | BR-07, BR-08 |
| `back` | TEXT NOT NULL | BR-07, BR-08 |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

**Không có cột SRS nào ở đây**, và không có `scheduler_generation` — card là nội
dung, nó sống xuyên qua mọi lần reset (BR-41). Reset learning progress không được
chạm vào bảng này.

Index: `idx_cards_deck` trên `(deck_id)`.

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
```

Query 8 giới hạn `depth < 64` để bản thân nó không thành vòng lặp vô hạn khi dữ
liệu đã hỏng — một checker treo là checker vô dụng.

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

Media và tag được nhắc trong quy tắc reset (BR-41: reset giữ nguyên chúng) nhưng
**chưa thuộc MVP** và chưa có bảng. Khi thêm, chúng gắn với `cards` và không mang
`scheduler_generation` — chúng là nội dung, và quy tắc "reset không chạm nội dung"
áp dụng nguyên vẹn.

## Thứ tự migration dự kiến

| Version | Nội dung |
|---|---|
| 1 | Toàn bộ schema trên |
| _sau_ | Bảng `tags`, `card_media` |
| _sau_ | Cột sync (`is_pending_sync`, `version`) khi có backend (AD-03) |
| _sau_ | `deck_templates` thành bảng runtime nếu tải template từ server |

Tất cả đều là thêm cột hoặc thêm bảng — không đụng dữ liệu đang có. Đó là kết quả
có chủ đích của việc tách bảng, đặt `scheduler_generation` và `root_deck_id` ngay
từ v1.
