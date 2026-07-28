# Data model — memox

_Status: draft · Last updated: 2026-07-28_

Schema viết trong file `.drift` (AD-02). Đây là tài liệu thiết kế; SQL thật nằm
ở `lib/core/database/tables/`.

Hai nguyên tắc chi phối cách chia bảng:

1. **Nội dung, trạng thái lịch, và lịch sử có ba vòng đời khác nhau**, nên là ba
   bảng. Nội dung sửa mà không đụng lịch (BR-09); lịch đổi mỗi lần ôn; lịch sử chỉ
   thêm, không bao giờ sửa.
2. **`scheduler_generation` có mặt ở mọi nơi trạng thái học tồn tại**, để "thuộc
   chu kỳ nào" là dữ kiện trong dữ liệu chứ không phải quy ước ngầm (AD-09).

---

## Tổng quan

```
deck_templates (asset JSON ở MVP)
        │ sao chép một lần, không liên kết ghi ngược
        ▼
     decks ◄──┐ parent_deck_id (sub-deck kế thừa scheduler của root)
       │      │
       ├──────┘
       ├──► cards ──┬──► card_review_states   (1–1, mang generation)
       │            └──► review_history       (1–n, append-only, mang generation)
       │
       └──► study_sessions ──► review_history  (session mang generation)
```

---

## `decks`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client (AD-03) |
| `name` | TEXT NOT NULL | BR-01 |
| `parent_deck_id` | TEXT NULL | NULL = root deck. → `decks(id)` ON DELETE CASCADE |
| `owner_id` | TEXT NULL | NULL = local profile (AD-03) |
| `scheduler_type` | TEXT NULL | `'eight_box'` \| `'sm2'`. **NOT NULL trên root, NULL trên sub-deck** |
| `scheduler_version` | INTEGER NULL | version của thuật toán. Cùng quy tắc NULL |
| `scheduler_config` | TEXT NULL | JSON tham số ghi đè. Cùng quy tắc NULL |
| `scheduler_generation` | INTEGER NULL | bắt đầu từ 1, +1 mỗi lần reset (AD-09). Chỉ trên root |
| `first_review_at` | DATETIME NULL | NULL = chưa có review ở generation hiện tại → scheduler mở khoá |
| `source_template_id` | TEXT NULL | NULL = deck tự tạo (BR-25) |
| `source_template_version` | INTEGER NULL | version tại thời điểm sao chép |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

**Cột scheduler chỉ có giá trị trên root deck.** Sub-deck để NULL và tra ngược
lên root (AD-06). Đây là cách khiến "sub-deck không chọn scheduler riêng" trở
thành bất khả thi về mặt cấu trúc, thay vì chỉ là quy ước ai đó phải nhớ.

`first_review_at` là **denormalization có chủ đích**. Điều kiện khoá đúng ra là
"tồn tại review_history thuộc generation hiện tại", nhưng câu đó phải chạy query
mỗi lần vẽ màn hình sửa deck. Bất biến: `first_review_at IS NOT NULL` ⟺ có ít
nhất một dòng `review_history` với `scheduler_generation` bằng generation hiện
tại của deck. Reset đặt nó về NULL.

Index: `idx_decks_parent` trên `(parent_deck_id)` cho việc dựng cây.

## `cards`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `deck_id` | TEXT NOT NULL | → `decks(id)` ON DELETE CASCADE. Có thể là sub-deck |
| `front` | TEXT NOT NULL | BR-06, BR-07 |
| `back` | TEXT NOT NULL | BR-06, BR-07 |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

**Không có cột SRS nào ở đây**, và không có `scheduler_generation` — card là nội
dung, nó sống xuyên qua mọi lần reset (AD-09). Đó là điểm chính của việc tách
bảng: reset learning progress không được chạm vào bảng này.

Index: `idx_cards_deck` trên `(deck_id)`.

## `card_review_states`

Một dòng cho mỗi card, tạo cùng lúc với card (BR-08). Bị xoá và tạo lại khi reset.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT PK | → `cards(id)` ON DELETE CASCADE. PK vì quan hệ 1–1 |
| `scheduler_type` | TEXT NOT NULL | phải bằng scheduler của root deck |
| `scheduler_version` | INTEGER NOT NULL | |
| `scheduler_generation` | INTEGER NOT NULL | phải bằng generation hiện tại của root deck |
| `due_at` | DATETIME NULL | chung cho mọi scheduler. NULL = đến hạn ngay. UTC |
| `last_reviewed_at` | DATETIME NULL | |
| `review_count` | INTEGER NOT NULL DEFAULT 0 | BR-12 |
| `lapse_count` | INTEGER NOT NULL DEFAULT 0 | BR-12 |
| `current_box` | INTEGER NULL | **chỉ `eight_box`**: 1..8 |
| `ease_factor` | REAL NULL | **chỉ `sm2`**: mặc định 2.5, sàn 1.3 |
| `interval_days` | INTEGER NULL | **chỉ `sm2`** |
| `repetitions` | INTEGER NULL | **chỉ `sm2`** |

`scheduler_type` và `scheduler_generation` lặp lại từ deck là **denormalization
có chủ đích**, để hai bất biến của AD-09 kiểm tra được bằng một câu query thay vì
bằng niềm tin:

```sql
-- phải luôn trả về 0 dòng
SELECT s.card_id FROM card_review_states s
JOIN cards c ON c.id = s.card_id
JOIN decks d ON d.id = c.deck_id
JOIN decks root ON root.id = COALESCE(d.parent_deck_id, d.id)
WHERE s.scheduler_generation <> root.scheduler_generation
   OR s.scheduler_type <> root.scheduler_type;
```

Cột riêng của từng scheduler để NULL khi không thuộc scheduler đang dùng. Phương
án gói vào JSON linh hoạt hơn nhưng mất type-safety và không query được — mâu
thuẫn trực tiếp với lý do chọn AD-02. Vài cột NULL rẻ hơn nhiều.

Index quan trọng nhất của app — query "card nào đến hạn" chạy mỗi lần mở danh
sách và mỗi lần bắt đầu phiên:

```sql
CREATE INDEX idx_review_states_due ON card_review_states (due_at);
```

## `review_history`

Append-only. Không sửa, không xoá — kể cả khi reset (AD-09). Chỉ mất khi card bị
xoá (cascade).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `card_id` | TEXT NOT NULL | → `cards(id)` ON DELETE CASCADE |
| `session_id` | TEXT NOT NULL | → `study_sessions(id)` |
| `scheduler_type` | TEXT NOT NULL | scheduler tại thời điểm đánh giá |
| `scheduler_generation` | INTEGER NOT NULL | generation tại thời điểm đánh giá |
| `action` | TEXT NOT NULL | `forgotten`/`remembered` hoặc `again`/`hard`/`good`/`easy` |
| `reviewed_at` | DATETIME NOT NULL | UTC |
| `next_due_at` | DATETIME NULL | hạn sau khi đánh giá |
| `previous_box` | INTEGER NULL | chỉ `eight_box` |
| `next_box` | INTEGER NULL | chỉ `eight_box` |
| `previous_ease_factor` | REAL NULL | chỉ `sm2` |
| `next_ease_factor` | REAL NULL | chỉ `sm2` |
| `previous_interval_days` | INTEGER NULL | chỉ `sm2` |
| `next_interval_days` | INTEGER NULL | chỉ `sm2` |

Giữ history qua các lần reset là lý do bảng này mang `scheduler_type` và
`scheduler_generation` thay vì tra ngược lên deck: deck chỉ biết generation
**hiện tại**, còn dòng history phải nói được nó thuộc chu kỳ nào theo luật nào.
Không có hai cột này thì history cũ trở thành dữ liệu vô nghĩa ngay sau lần reset
đầu tiên.

Lượt luyện lại trong phiên (BR-19) cũng ghi vào đây, với `previous_* == next_*`
và `next_due_at` không đổi — phân biệt được mà không cần thêm cột.

Index: `idx_history_card` trên `(card_id, reviewed_at)`; `idx_history_session`
trên `(session_id)`.

Bảng này lớn nhanh nhất — mỗi lượt đánh giá một dòng, và reset không dọn bớt.
Đây là bảng đầu tiên cần nhìn khi bàn về kích thước DB.

## `study_sessions`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `deck_id` | TEXT NOT NULL | → `decks(id)` ON DELETE CASCADE |
| `scheduler_generation` | INTEGER NOT NULL | generation lúc mở phiên |
| `started_at` | DATETIME NOT NULL | UTC |
| `ended_at` | DATETIME NULL | NULL = phiên chưa kết thúc |

`scheduler_generation` ở đây là thứ chặn tình huống ở AD-09: phiên mở trước khi
reset, người dùng quay lại bấm đánh giá sau khi reset. Mọi thao tác ghi đánh giá
so generation của session với generation hiện tại của deck và **từ chối** nếu
lệch (BR-40).

**Hàng đợi của phiên không lưu trong DB.** Nó là trạng thái tạm trong controller.

## `deck_templates`

**Ở MVP đây không phải bảng runtime** (AD-07) — template là asset JSON:

```
assets/templates/
├── manifest.json
└── vi/
    └── basic_1000.json
```

| Trường | Ghi chú |
|---|---|
| `template_id` | ổn định giữa các phiên bản app (BR-23) |
| `version` | tăng khi nội dung đổi |
| `locale` | `vi`, `en`, … |
| `title` | tên hiển thị |
| `content_source` | nguồn gốc nội dung, cho ghi công và kiểm tra bản quyền |
| `default_scheduler_type` | scheduler gợi ý khi tạo bản sao; người dùng đổi được trước lượt review đầu |

---

## Chưa mô hình hoá

Media và tag được nhắc trong quy tắc reset (AD-09: reset giữ nguyên chúng) nhưng
**chưa thuộc MVP** và chưa có bảng. Khi thêm, chúng gắn với `cards` và không mang
`scheduler_generation` — chúng là nội dung, và quy tắc "reset không chạm nội dung"
áp dụng nguyên vẹn.

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
chỉ là chú thích. Cần test: xoá root deck → sub-deck, card, review state, review
history và study session đều biến mất (BR-03).

## Thứ tự migration dự kiến

| Version | Nội dung |
|---|---|
| 1 | Toàn bộ schema trên |
| _sau_ | Bảng `tags`, `card_media` |
| _sau_ | Cột sync (`is_pending_sync`, `version`) khi có backend (AD-03) |
| _sau_ | `deck_templates` thành bảng runtime nếu tải template từ server |

Tất cả đều là thêm cột hoặc thêm bảng — không đụng dữ liệu đang có. Đó là kết quả
có chủ đích của việc tách bảng và đặt `scheduler_generation` ngay từ v1.
