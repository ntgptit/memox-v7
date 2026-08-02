# Wireframe · M4.11 Card management

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Chốt bố cục và hành vi UI của màn card trước khi viết code M4.11 |
| **Scope** | Card list, card editor, xoá card, các state của hai màn đó. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng người dùng (`use-cases.md`), giá trị token (`design_system/tokens/`), màn review (M5.1) |
| **Source of truth for** | Bố cục màn card M4.11 · quyết định UI đã chốt và còn mở của task này |
| **Depends on** | `document-conventions.md`, `use-cases.md` (UC-04, UC-08), `business-rules.md` (BR-88…BR-94), `data-model.md` (schema v2), `wbs.md` (M4.10at, M4.11) |
| **Updated by task** | M4.10at |
| **Last updated** | 2026-08-02 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc đều tham chiếu bằng ID
(BR-xx, UC-xx) theo `document-conventions.md` §5; chỗ nào wireframe và BR có vẻ
mâu thuẫn thì BR đúng và wireframe sai.

Nó cũng không phải design reference để đo pixel. Acceptance criteria của M4.11
đòi pixel difference dưới 3% so với một design reference; bản đó là JSX trong
`design_system/ui_kits/memox-app/`, chưa tồn tại — xem [Q4](#việc-còn-mở).

---

## 1. Lịch sửa

| Ngày | Task | Ai | Thay đổi |
|---|---|---|---|
| 2026-08-02 | M4.11 | — | Bản đầu. Chốt D1–D3 qua trao đổi; mở Q1–Q5. |
| 2026-08-02 | M4.11 | — | Thêm ràng buộc kế thừa C1–C3 từ M4.10ar; thêm W1b (cửa sổ, load-more); Q2 đóng nhờ C1. |
| 2026-08-02 | M4.11 | — | Nhận màn hình tham chiếu của chủ dự án. W1 tách thành trạng thái đích (§4.1), phân tầng khối (§4.2) và lát cắt M4.11 (§4.3). Chốt D4–D5; mở Q8–Q11. |
| 2026-08-02 | M4.11 | — | Nhận hai ảnh tham chiếu chế độ sửa. W6b vẽ lại đầy đủ: optional details mở sẵn, tag chip, danger zone. Chốt D10–D11. Dải metadata, mic và TTS ghi vào `wbs.md` §Deferred. |
| 2026-08-02 | M4.10at | — | Nhận màn tham chiếu thứ hai (editor). W4–W6b vẽ lại theo nó. BR-08 siết 2000 → 60/240; BR-95 thêm ba trường phụ. Chốt D6–D9; mở Q12–Q13. |
| 2026-08-02 | M4.10at | — | Chủ dự án chốt đưa tag, cờ và panel tiến độ vào MVP, chèn M4.10at trước M4.11. Q8–Q11 đóng bằng BR-89…BR-94 và schema v2. D3 sửa: lọc vào scope, sort vẫn ngoài. Nhãn `LEARNING` → `BEGINNING`. |

---

## 2. Quyết định đã chốt

| ID | Quyết định | Lý do | Ngày |
|---|---|---|---|
| D1 | Card editor là **full-screen route**, không phải bottom sheet | Hai ô tới 2000 ký tự (BR-08) cộng luồng thêm liên tiếp (UC-04 A4) không vừa sheet ở 320×568 với `textScaler` 2.0. Lệch khỏi tiền lệ deck form (`showDeckRenameForm`) một cách có chủ đích. | 2026-08-02 |
| D2 | Hàng card hiện **front + back + chip trạng thái ôn tập** | Quét được cả cặp mà không phải mở từng card. Chip đọc từ `card_review_states` mà BR-09 đã tạo sẵn lúc tạo card, nên không cần dữ liệu mới. | 2026-08-02 |
| D3 | **Không** search, **không** sort. Pill **lọc** thì có | Sort đổi `ORDER BY` và mâu thuẫn C1 mà M4.10ar chốt; search thẻ là S1. Lọc chỉ thêm `WHERE` nên không đụng thứ tự hay cửa sổ — xem §4.3. Sửa lại D3 bản đầu, vốn gộp cả ba thành một. | 2026-08-02 |
| D4 | FAB là **extended** (`+ New card`), không phải icon tròn | Từ ảnh tham chiếu. Màn này chỉ có một hành động chính và nó cần được gọi tên — một dấu `+` trần trên màn đầy thẻ không nói nó tạo *thẻ* hay tạo *deck con*. Cùng lý do `MxActionButton` không có variant chỉ-icon. | 2026-08-02 |
| D6 | Editor có **thanh hành động ghim đáy**, và `Save & add another` sống ở đó | Ảnh tham chiếu có `Cancel` + `Save card` ở đáy nhưng **không** có add-another, trong khi UC-04 A4 (frozen) đòi giữ form mở. `Cancel` bỏ đi vì `✕` ở app bar đã làm đúng việc đó; chỗ trống thành add-another. | 2026-08-02 |
| D7 | Ba trường phụ nằm trong một **disclosure đóng mặc định** | BR-95 cho cả ba là tuỳ chọn. Mở sẵn biến form hai ô thành form năm ô cho việc thường gặp nhất. | 2026-08-02 |
| D8 | Deck hiện **read-only**, không phải picker | Đổi deck đích nghĩa là thẻ có thể sang root khác scheduler hoặc khác generation — đúng thứ BR-73/BR-74 đang chặn. Deck là ngữ cảnh màn đang mở. | 2026-08-02 |
| D10 | Xoá thẻ có **hai lối**: long-press ở danh sách, và danger zone trong editor | Ảnh tham chiếu đặt danger zone trong editor. Giữ cả hai vì chúng phục vụ hai việc khác nhau — dọn hàng loạt, và bỏ một thẻ đang đọc. Cùng một dialog xác nhận, nên không có hai đường xử lý. | 2026-08-02 |
| D11 | `OPTIONAL DETAILS` **đóng khi rỗng, mở khi đã có nội dung** | Ảnh tạo cho thấy disclosure đóng, ảnh sửa cho thấy ba ô mở sẵn — không mâu thuẫn, mà là cùng một quy tắc ở hai trạng thái. Đóng một ô đang có chữ là giấu nội dung của chính người dùng. | 2026-08-02 |
| D9 | **Không** có nút micro nhập giọng nói | Ảnh tham chiếu có. Nó cần plugin, quyền hệ điều hành và một luồng lỗi riêng; không nằm trong scope M4.11 và gần với media, vốn đã hoãn. | 2026-08-02 |
| D5 | Hàng card là **bốn phần**: dot trạng thái · front · back · nhãn trạng thái, cộng badge hạn bên phải | Từ ảnh tham chiếu. Thay chip đơn của bản đầu. Ba tín hiệu trạng thái trả lời ba câu khác nhau — xem bảng ở §4.3 — và gộp lại thành một chip là mất hai trong ba. | 2026-08-02 |

**D2 có một ranh giới phải giữ, và nó dịch chỗ ở M4.10at.** M4.11 **đọc**
`card_review_states` để vẽ nhãn và badge — kể cả `current_box` và `interval_days`,
vì BR-89…BR-91 quy chiếu từ đúng hai cột đó. Cái nó vẫn không làm là **ghi**:
`due_at` tiến lên, box đổi, history thêm dòng — toàn bộ là M5.1.

### Ràng buộc kế thừa từ M4.10ar

Ba điều dưới đây **đã chốt ở tầng data** trước khi wireframe này tồn tại. Chúng
không mở lại ở đây; wireframe phải vẽ theo chúng.

| ID | Ràng buộc | Hệ quả lên UI |
|---|---|---|
| C1 | Thứ tự `created_at DESC, id DESC` — **mới nhất trên cùng** | Thẻ vừa lưu xuất hiện ở đầu list, nên luồng thêm liên tiếp (UC-04 A4) thấy ngay kết quả mà không phải cuộn |
| C2 | Cửa sổ `LIMIT :limit`, **không cursor, không `OFFSET`**; cửa sổ lớn dần | Cần một affordance load-more tường minh — [W1b](#5-w1b--đáy-danh-sách-cửa-sổ-và-load-more) |
| C3 | Tổng số card là **query riêng**, không đi kèm các dòng | Dòng "đang hiện N / M" có hai nguồn; N và M có thể lệch nhau một nhịp khi vừa thêm thẻ |

C1 là lý do thứ tự được đảo ở M4.10ar: cũ-trước đặt thẻ vừa tạo ở cuối deck, tức
đúng luồng chính của UC-04 rơi vào trường hợp tệ nhất.

---

## 3. Bản đồ route

```
/decks/:deckId                     ← card list (deck content_type = card)
/decks/:deckId/cards/new           ← editor, chế độ tạo
/decks/:deckId/cards/:cardId/edit  ← editor, chế độ sửa
```

Shell tái dùng: `MxContentShell` · `MxBreadcrumb` · `MxCard` · `MxActionSheet` ·
`MxConfirmDialog` · `MxEmptyState` · `MxTextField` · `MxActionButton`.

---

## 4. W1 · Card list

### 4.1. Trạng thái đích

Bản dưới là màn hình tham chiếu chủ dự án đưa (ảnh chụp, 2026-08-02). Nó vẽ ra
màn deck detail **đầy đủ** — tức đích đến, không phải phạm vi M4.11.

```
┌──────────────────────────────────────────────┐
│  ←   TOPIK II — Vocab                🔍   ⋮  │  ⚑ search: S1
├──────────────────────────────────────────────┤
│  Library › Korean › TOPIK II › TOPIK II — V… │  MxBreadcrumb, 4 cấp
│                                              │
│  ┌────────────────────────────────────────┐  │ ╮
│  │   ╭────╮   DECK PROGRESS               │  │ │
│  │   │62% │   106 of 142 cards mastered   │  │ │
│  │   ╰────╯   ● 23 due · 6 new            │  │ │
│  │                                        │  │ │ M4.11
│  │  ▓▓▒▒▒▒▒████████░░░░░░░░░░░░░░░░░░░░░  │  │ │
│  │  ● New 4  ● Beginning 8 ● Reviewing 24 │  │ │
│  │  ● Mastered 106                        │  │ │
│  │  ┌──────────────────────────────────┐  │  │ │
│  │  │      ▷  Start study · 23 due     │  │  │ │ ⚑ M5.1
│  │  └──────────────────────────────────┘  │  │ │
│  └────────────────────────────────────────┘  │ ╯
│                                              │
│  ⟨All 142⟩ ⟨Due now 23⟩ ⟨New 4⟩ ⟨⚑ Flagged 2⟩│  lọc — M4.11
│                                              │
│  7 CARDS                       ⇅ Due first ⌄ │  ⚑ sort: out-of-scope
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ ●  연구자                        ⟨now⟩ │  │  dot · front · due badge
│  │    researcher / nhà nghiên cứu         │  │  back
│  │    NEW    ⟨noun⟩ ⟨people⟩              │  │  state (BR-90) · tag
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ ●  공부하다                    ⟨in 4d⟩ │  │
│  │    to study                            │  │
│  │    MASTERED   ⟨verb⟩                   │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ ●  도서관                           ⚑  │  │  cờ — `is_flagged`
│  │    library, reading room       ⟨10m⟩   │  │
│  │    BEGINNING  ⟨noun⟩ ⟨places⟩          │  │
│  └────────────────────────────────────────┘  │
│                                              │
│                     ┌────────────────────┐   │
│                     │  +   New card      │   │  extended FAB
│                     └────────────────────┘   │
└──────────────────────────────────────────────┘
```

### 4.2. Khối nào thuộc đâu

Đối chiếu từng khối với `data-model.md` và scope M4.11. Ba nhóm, và chúng bị
chặn bởi ba thứ khác nhau — nên gộp chúng thành "để sau" là mất thông tin.

| Khối | Dữ liệu có chưa | Thuộc đâu |
|---|---|---|
| Back · title · `⋮` · breadcrumb | có | **M4.11** |
| `7 CARDS` / dòng đếm | có (C3) | **M4.11** |
| Hàng: dot · front · back · state · due badge | có | **M4.11** |
| Extended FAB `+ New card` | — | **M4.11** — xem D4 |
| Nút `🔍` search | — | **Chặn bởi scope.** `wbs.md` M4.11: search thẻ là S1 |
| Sort `⇅ Due first` | có | **Chặn bởi scope**, và mâu thuẫn C1 (thứ tự cố định) |
| `▷ Start study` | có | **M5.1** — review nằm ngoài M4.11 |
| Pill lọc `All / Due now / New / ⚑` | M4.10at | **M4.11** — lọc, không đổi thứ tự |
| Panel Deck progress + vòng 62% | M4.10at (BR-89…BR-91) | **M4.11** |
| Icon ⚑ trên hàng | **M4.10at** thêm `cards.is_flagged` | **M4.11** |
| Chip tag `⟨noun⟩ ⟨people⟩` | **M4.10at** thêm `tags` + `card_tags` | **M4.11** |
| Chữ trạng thái | **M4.10at** thêm BR-89…BR-91 | **M4.11** |

**Bốn khối cuối đã được mở đường ở M4.10at** (schema v2 + BR-89…BR-94), nên
chúng chuyển từ "chặn" sang "trong scope M4.11". Bảng trên giữ lại cột giữa để
thấy cái gì mở đường cho cái gì.

Hai điều đáng giữ lại từ lúc đối chiếu, vì chúng vẫn đúng và vẫn dễ quên:

**`card_review_states` không có cột trạng thái.** Nó có `current_box` 1..8 cho
`eight_box`, và `ease_factor` / `interval_days` / `repetitions` cho `sm2`. Bốn
nhãn là một *phép quy chiếu* từ những cột đó — BR-94 nói thẳng là suy khi đọc,
không lưu thành cột.

**Hai hàm quy chiếu, không phải một.** Cùng nhãn `mastered` suy từ
`current_box = 8` ở deck này và từ `interval_days ≥ 128` ở deck kia (BR-88). Một
hàm chung cho cả hai là sai theo AD-06 — nó buộc phải đọc cột NULL của scheduler
kia.

**Nhãn đổi tên so với ảnh:** `LEARNING` → `BEGINNING`. `learning` trong repo này
đã có nghĩa khác — "reset learning progress" (UC-07) là xoá toàn bộ lịch — nên
dùng lại nó cho một nhãn hiển thị sẽ khiến hai khái niệm mang một tên.

### 4.3. Lát cắt M4.11

Sau khi M4.10at mở đường, lát cắt này chỉ còn thiếu **ba** khối so với §4.1:
search, sort, và Start study. Mọi thứ khác được build ở M4.11.

```
┌──────────────────────────────────────────────┐
│  ←   TOPIK II — Vocab                     ⋮  │  không có 🔍
├──────────────────────────────────────────────┤
│  Library › Korean › TOPIK II › TOPIK II — V… │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │   ╭────╮   DECK PROGRESS               │  │
│  │   │62% │   106 of 142 cards mastered   │  │  BR-88
│  │   ╰────╯   ● 23 due · 6 new            │  │
│  │  ▓▓▒▒▒▒▒████████░░░░░░░░░░░░░░░░░░░░░  │  │
│  │  ● New 4  ● Beginning 8 ● Reviewing 24 │  │  BR-89…BR-91
│  │  ● Mastered 106                        │  │
│  └────────────────────────────────────────┘  │  không có Start study
│                                              │
│  ⟨All 142⟩ ⟨Due now 23⟩ ⟨New 4⟩ ⟨⚑ Flagged 2⟩│
│                                              │
│  SHOWING 50 OF 142                           │  C3, không có sort
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ ●  연구자                        ⟨now⟩ │  │
│  │    researcher / nhà nghiên cứu         │  │
│  │    NEW    ⟨noun⟩ ⟨people⟩              │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ ●  공부하다                    ⟨in 4d⟩ │  │
│  │    to study                            │  │
│  │    MASTERED   ⟨verb⟩                   │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ ●  도서관                           ⚑  │  │
│  │    library, reading room       ⟨10m⟩   │  │
│  │    BEGINNING  ⟨noun⟩ ⟨places⟩          │  │
│  └────────────────────────────────────────┘  │
│                                              │
│                     ┌────────────────────┐   │
│                     │  +   New card      │   │
│                     └────────────────────┘   │
└──────────────────────────────────────────────┘
```

**Lọc thì được, sắp xếp thì không — và đó không phải nửa vời.** Một pill lọc
thêm mệnh đề `WHERE` vào cùng câu query; thứ tự vẫn là `created_at DESC, id DESC`
và cửa sổ `LIMIT` vẫn đọc lại nguyên vẹn từ đầu, nên C1 và C2 không bị đụng tới.
Một control **sort** thì đổi `ORDER BY`, và đó chính là thứ M4.10ar chốt là cố
định — nó cũng làm hỏng lập luận "thẻ vừa thêm nằm trên cùng" của UC-04 A4.

**Lọc kéo theo hai hệ quả lên C2 và C3**, cả hai cần giải trước khi code:

| | |
|---|---|
| Cửa sổ | Đổi pill lọc là đổi tập kết quả, nên cửa sổ **reset về `windowSize`**. Giữ nguyên độ mở khi tập nền đã khác là mở 200 dòng của một tập chỉ có 23 |
| Dòng đếm | `SHOWING 50 OF 142` với `All`, nhưng với `Due now` thì mẫu số là 23 — nó đếm **tập đang lọc**, không phải deck. Cùng một query đếm, cùng một `WHERE` |

Chạm vào hàng mở editor chế độ sửa. `⋮` trên hàng bị bỏ so với bản trước: ảnh
tham chiếu không có nó, và badge bên phải đã chiếm chỗ đó. Hành động của một
card đi qua long-press → action sheet (W7).

**Ba phần của trạng thái, và chúng trả lời ba câu khác nhau:**

| Phần | Nguồn | Trả lời |
|---|---|---|
| Dot màu (trái) | cùng nguồn với nhãn | Quét dọc cả cột thấy ngay phân bố |
| Nhãn chữ (dưới) | `current_box` \| `interval_days` | Thẻ này đang ở đâu |
| Badge `⟨…⟩` (phải) | `due_at` − now | Bao giờ tới lượt nó |

Badge là thời gian tương đối: `now` khi `due_at` NULL hoặc đã qua, `10m` / `in
4d` khi còn. Giờ đến từ `clockProvider` ở composition root — không widget nào
trong `lib/features/` đọc đồng hồ tường, theo `CLAUDE.md`.

**Dòng đếm nói cửa sổ, không nói deck.** `SHOWING 50 OF 214` là cách C2 và C3
hiện ra: 50 là cửa sổ đang mở, 214 là tổng thật từ query riêng. Ảnh tham chiếu
viết `7 CARDS` vì deck đó nhỏ hơn cửa sổ — ở deck lớn thì `214 CARDS` sẽ nói dối
về thứ người dùng cuộn được, và `50 CARDS` nói dối về deck.

---

## 5. W1b · Đáy danh sách — cửa sổ và load-more

```
│  ┌────────────────────────────────────────┐  │
│  │ candid                             ⋮   │  │  ← dòng thứ 50
│  │ truthful and straightforward           │  │
│  │ ○ New                                  │  │
│  └────────────────────────────────────────┘  │
│                                              │
│         ┌────────────────────────┐           │
│         │   Load 50 more         │           │  MxActionButton secondary
│         └────────────────────────┘           │
│                                              │
│              164 more cards                  │  body-sm, onSurfaceVariant
│                                              │
└──────────────────────────────────────────────┘

   ĐANG TẢI THÊM              HẾT DANH SÁCH
│         ◌  Loading…      │  │   All 214 cards shown   │
│    (nút → spinner)       │  │   (không còn nút)       │
```

**Tường minh, không phải cuộn-vô-hạn.** Cửa sổ là `LIMIT` đọc lại từ đầu (C2),
nên mỗi lần mở rộng có chi phí theo *cửa sổ mới* chứ không theo phần thêm vào —
1,75 / 4,29 / 16,87 ms ở 50 / 200 / 800 dòng, đo trên SQLite thật. Một trigger
tự động khi cuộn tới đáy sẽ gọi phép đó liên tiếp mà người dùng không biết mình
vừa yêu cầu gì; một cái nút thì họ biết.

`Load 50 more` không bao giờ hiện khi cửa sổ đã phủ hết — chỗ đó là câu
`All 214 cards shown`, để đáy danh sách luôn nói một điều gì đó thay vì im lặng
mập mờ giữa "hết rồi" và "chưa tải".

**Hành vi cuộn khi có dòng mới.** Thẻ vừa lưu vào đầu list (C1). Vị trí cuộn
**giữ nguyên theo dòng đang nhìn**, không nhảy về đầu và không trôi xuống một
hàng: người đang đọc giữa danh sách không bị đẩy đi vì một thao tác ở màn khác.
Riêng luồng UC-04 A4 thì list vốn đang ở đầu, nên thẻ mới nằm ngay trong tầm mắt
— đó chính là điều C1 mua được.

---

## 6. W2 · Empty — deck đã là `content_type = card`

```
┌──────────────────────────────────────────────┐
│  ←   Academic Word List                  ⋮   │
├──────────────────────────────────────────────┤
│  Library › English › Academic Word List      │
│                                              │
│                    ▢                         │  MxEmptyState
│                                              │
│              No cards yet                    │
│                                              │
│        Add your first card to start          │
│              studying this deck.             │
│                                              │
│            ┌──────────────────┐              │
│            │    Add card      │              │  MxActionButton primary
│            └──────────────────┘              │
│                                              │
└──────────────────────────────────────────────┘
```

FAB **ẩn** ở state này: hai lối vào cùng một hành động trên một màn trống là
thừa, và CTA giữa màn là thứ mắt tìm tới. Phủ UC-04 A3.

---

## 7. W3 · Empty — deck còn `unset`

Màn quyết định `content_type`, và là chỗ dễ sai nhất của M4.11. Luồng thuộc
UC-08; ràng buộc là BR-62 và BR-63.

```
┌──────────────────────────────────────────────┐
│  ←   Unit 3                              ⋮   │
├──────────────────────────────────────────────┤
│  Library › English › Unit 3                  │
│                                              │
│                    ▢                         │
│                                              │
│              Empty deck                      │
│                                              │
│      What goes in this deck? This choice     │
│      is locked once the first item is        │  ← nói thẳng là khoá
│      created.                                │
│                                              │
│      ┌────────────────┐ ┌────────────────┐   │
│      │   Add card     │ │  Add sub-deck  │   │
│      └────────────────┘ └────────────────┘   │
│                                              │
└──────────────────────────────────────────────┘
```

Chọn **Add card** đi thẳng tới editor. Việc khoá xảy ra trong cùng transaction
với card đầu tiên (BR-62, BR-63) — không có bước xác nhận riêng, và ghi hỏng thì
không có gì bị khoá.

---

## 8. W4 · Editor — chế độ tạo

Theo màn tham chiếu thứ hai chủ dự án đưa (ảnh chụp, 2026-08-02).

```
┌──────────────────────────────────────────────┐
│  ✕   New flashcard                    Save   │  Save: filled, app bar
├──────────────────────────────────────────────┤
│  Library › Korean › TOPIK II — Vocab ›       │
│  New card                                    │  bậc cuối đậm
│                                              │
│  ▤ TOPIK II — Vocab           ● REQUIRED     │  deck: read-only, xem D8
│                                              │
│  FRONT · KOREAN   Required           0 / 60  │  BR-07 · BR-08
│  ┌────────────────────────────────────────┐  │
│  │ The term you want to remember          │  │  placeholder
│  │                                        │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  BACK · MEANING   Required          0 / 240  │
│  ┌────────────────────────────────────────┐  │
│  │ English, Vietnamese, or both — comma-  │  │
│  │ separated reads cleanest.              │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐    │
│    ✦ Add details   example · hint · pron ⌄   │  disclosure, đóng mặc định
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘    │
│                                              │
│  ⌷ TAGS · optional                           │
│  ┌ ─ ─ ─ ─ ─ ─ ┐                             │
│    +  Add tag                                │  BR-93, tối đa 10
│  └ ─ ─ ─ ─ ─ ─ ┘                             │
│                                              │
├──────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Save & add   │  │   ✓  Save card       │  │  thanh ghim đáy
│  └──────────────┘  └──────────────────────┘  │
│  Front and back are required to save.        │  body-sm, onSurfaceVariant
└──────────────────────────────────────────────┘
```

**Nhãn ô nói cả vai trò lẫn nội dung.** `FRONT · KOREAN` và `BACK · MEANING` —
nửa trái là vai trò trong thẻ, nửa phải là thứ người dùng thực sự gõ. Ngôn ngữ
lấy từ deck; deck chưa khai ngôn ngữ thì chỉ còn `FRONT` / `BACK`, không để lại
dấu `·` treo lơ lửng. Xem Q12.

**Đếm ký tự thường trực, và hai ô có hai số** — 60 với 240 (BR-08). Chúng khác
nhau nên hiện cả hai là cần thiết: thấy `0 / 60` ở trên và `0 / 240` ở dưới thì
hiểu ngay mặt trước là một từ chứ không phải một câu, không cần hướng dẫn nào.

**Placeholder dạy cách dùng, không lặp lại nhãn.** `The term you want to
remember` nói *cái gì* thuộc về đây; `comma-separated reads cleanest` nói *viết
thế nào*. Một placeholder ghi "Front" là ô nhắc lại nhãn của chính nó.

**Add details đóng mặc định — ở chế độ tạo.** Ba trường của BR-95 đều tuỳ chọn,
và mở sẵn cả ba biến form hai ô thành form năm ô cho đúng việc thường gặp nhất —
thêm một từ. Viền đứt và dấu `⌄` nói rằng còn thứ bên dưới.

Ở **chế độ sửa** chúng mở sẵn (W6b), vì lúc đó chúng đã có nội dung. Cùng một
quy tắc D11: đóng khi rỗng, mở khi có chữ — đóng một ô đang có chữ là giấu nội
dung của chính người dùng.

---

## 9. W5 · Editor — Add details mở, tag đã nhập

```
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐    │
│    ✦ Add details                         ⌃   │
│                                              │
│    EXAMPLE                        0 / 240    │
│    ┌────────────────────────────────────┐    │
│    │ 그는 유명한 연구자입니다.          │    │
│    └────────────────────────────────────┘    │
│                                              │
│    HINT                           0 / 240    │
│    ┌────────────────────────────────────┐    │
│    │ 연구 + 자 (người làm)              │    │
│    └────────────────────────────────────┘    │
│                                              │
│    PRONUNCIATION                  0 / 240    │
│    ┌────────────────────────────────────┐    │
│    │ yeon-gu-ja                         │    │
│    └────────────────────────────────────┘    │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘    │
│                                              │
│  ⌷ TAGS · optional                   2 / 10  │
│  ⟨noun ✕⟩  ⟨people ✕⟩                        │
│  ┌ ─ ─ ─ ─ ─ ─ ┐                             │
│    +  Add tag                                │
│  └ ─ ─ ─ ─ ─ ─ ┘                             │
```

Ba ô phụ dùng chung giới hạn 240 (BR-95), nên chúng trông giống nhau và không ai
phải nhớ ô nào rộng hơn ô nào.

**Bộ đếm tag `2 / 10` chỉ hiện khi đã có tag.** Ở mức 0 nó là một giới hạn chưa
ai chạm tới, và hiện ngay từ đầu biến một trường tuỳ chọn thành thứ trông như có
hạn ngạch phải dùng hết.

---

## 10. W6 · Editor — lỗi validation

```
┌──────────────────────────────────────────────┐
│  ✕   New flashcard                    Save   │
├──────────────────────────────────────────────┤
│  FRONT · KOREAN   Required           0 / 60  │
│  ┌────────────────────────────────────────┐  │  viền → semantic.danger
│  └────────────────────────────────────────┘  │
│  ⚠ Front can't be empty                      │  UC-04 E1
│                                              │
│  BACK · MEANING   Required        240 / 240  │  ← đếm chuyển danger
│  ┌────────────────────────────────────────┐  │
│  │ Lorem ipsum dolor sit amet, consecte…  │  │
│  └────────────────────────────────────────┘  │
│  ⚠ Back is at the 240 character limit        │  UC-04 E2
│                                              │
├──────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Save & add   │  │   ✓  Save card       │  │  cả hai disabled
│  └──────────────┘  └──────────────────────┘  │
│  Front and back are required to save.        │
└──────────────────────────────────────────────┘
```

- **E1** kích hoạt khi submit, không phải khi gõ: báo "trống" lúc ô còn chưa
  được chạm là la mắng người dùng vì chưa làm gì. Chuỗi toàn khoảng trắng rơi
  vào E1 vì BR-07 xét sau khi trim.
- **E2** chặn nhập thêm ở đúng ngưỡng (`maxLength`), và câu lỗi nói *đang ở giới
  hạn* chứ không phải *đã vượt* — vượt là điều không xảy ra được.
- Câu dưới thanh hành động là **hướng dẫn thường trực**, không phải lỗi: nó có
  mặt cả khi form hợp lệ, nên nó không tranh chỗ với hai câu ⚠ ở trên.

---

## 11. W6b · Editor — chế độ sửa

Theo hai ảnh tham chiếu chủ dự án đưa (ảnh chụp, 2026-08-02).

```
┌──────────────────────────────────────────────┐
│  ←   Edit flashcard                   Save   │  ← chứ không phải ✕
├──────────────────────────────────────────────┤
│  Library › Korean › TOPIK II — Vocab › Edit  │
│                                              │
│  ▤ TOPIK II — Vocab           ● REQUIRED     │  read-only (D8)
│                                              │
│  FRONT · KOREAN   Required           3 / 60  │
│  ┌────────────────────────────────────────┐  │
│  │ 연구자                                 │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  BACK · MEANING   Required          27 / 240 │
│  ┌────────────────────────────────────────┐  │
│  │ Researcher / Nhà nghiên cứu            │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  OPTIONAL DETAILS                            │  mở sẵn, không disclosure
│                                              │
│  ▭ EXAMPLE SENTENCE · optional               │
│  ┌────────────────────────────────────────┐  │
│  │ 그는 유명한 언어학 연구자이다.         │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ✧ HINT · optional                           │
│  ┌────────────────────────────────────────┐  │
│  │ 연구 = research · 자 = person          │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ◁) PRONUNCIATION · ROMANIZATION · optional  │
│  ┌────────────────────────────────────────┐  │
│  │ yeon-gu-ja                             │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ⌷ TAGS · optional                    3 / 10 │
│  ⟨TOPIK II ✕⟩ ⟨noun ✕⟩ ⟨people ✕⟩            │
│  ┌ ─ ─ ─ ─ ─ ─ ┐                             │
│    +  Add tag                                │
│  └ ─ ─ ─ ─ ─ ─ ┘                             │
│                                              │
│  ────────────────────────────────────────    │  divider
│                                              │
│  ⚠ DANGER ZONE                               │  semantic.danger
│  ┌────────────────────────────────────────┐  │
│  │ Delete this flashcard                  │  │  title-sm
│  │ Removes the card and its review        │  │
│  │ history from TOPIK II — Vocab. Other   │  │
│  │ cards in this deck stay.               │  │
│  │  ┌──────────────────────────┐          │  │
│  │  │  🗑  Delete flashcard     │          │  │  outlined destructive
│  │  └──────────────────────────┘          │  │
│  └────────────────────────────────────────┘  │
│                                              │
├──────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────────────┐  │
│  │   Cancel     │  │  ✓  Save changes     │  │
│  └──────────────┘  └──────────────────────┘  │
└──────────────────────────────────────────────┘
```

Khác chế độ tạo ở năm chỗ: `←` thay `✕`, title, breadcrumb kết bằng `Edit`,
`OPTIONAL DETAILS` **mở sẵn** thay vì disclosure, và một khối danger zone.
Không có `Save & add` — thêm liên tiếp là luồng của chế độ tạo.

**`Cancel` quay lại ở đây, và nó không thừa như ở chế độ tạo.** Ở W4 tôi bỏ
`Cancel` vì `✕` đã làm đúng việc đó. Ở đây thanh dưới có một nút phá huỷ ở trên
nó, nên một nút thoát rõ ràng cạnh `Save changes` là thứ giữ cho người dùng
không phải tìm đường ra ở góc màn.

### Ba khối trong ảnh nhưng không có ở đây

Ghi ra để lần sau không ai tưởng là bỏ sót. Cả ba nằm ở
`wbs.md` §Deferred and descoped.

| Trong ảnh | Vì sao chưa vẽ |
|---|---|
| `Last edited 3 days ago · 14 reviews · 78% recall · History ›` | `% recall` cần một BR định nghĩa "nhớ được" cho từng scheduler; link `History` mở màn review history, thứ M4.11 đặt ngoài scope |
| Icon mic trong ô FRONT | Nhập giọng nói — plugin, quyền OS, luồng lỗi riêng (D9) |
| Icon loa trong ô PRONUNCIATION | Phát âm bằng TTS — cùng lý do |

Hai icon còn lại **có** vẽ: `▭` `✧` `◁)` là icon nhãn của ba trường phụ, không
phải nút bấm. Chúng chỉ trang trí nhãn, nên không kéo theo gì.

### Xoá thẻ có hai lối, và đó là chủ đích

| Lối | Ở đâu | Dùng khi |
|---|---|---|
| Long-press hàng → action sheet (W7) | danh sách | Dọn nhiều thẻ liên tiếp mà không mở từng cái |
| Danger zone | editor | Đang đọc nội dung thẻ và quyết định bỏ nó |

Cả hai đi qua **cùng một dialog xác nhận** ở W7. Hai lối vào một hành động phá
huỷ là thứ phải cân nhắc, và cái mua được ở đây là: người dọn hàng loạt không
phải mở editor mười lần, còn người đang phân vân thì thấy nút xoá ở đúng chỗ họ
đang nhìn nội dung.

Câu mô tả trong danger zone nói rõ **cái gì mất và cái gì ở lại** — history mất
theo, các thẻ khác trong deck thì không. Đó là hậu quả người dùng không đoán
được từ chữ "xoá", và nó cũng là lý do `content_type` giữ nguyên khi xoá thẻ
cuối (BR-67).

---

## 12. W7 · Xoá card

```
        ┌──────────────────────────────┐
        │  Card actions                │   MxActionSheet (long-press)
        │                              │
        │  ✎  Edit                     │
        │  🗑  Delete                   │   destructive
        └──────────────────────────────┘

        ┌──────────────────────────────┐
        │  Delete this card?           │   MxConfirmDialog
        │                              │
        │  Its learning history will   │
        │  be deleted too. This can't  │
        │  be undone.                  │
        │                              │
        │      ┌────────┐ ┌─────────┐  │
        │      │ Cancel │ │ Delete  │  │   destructive
        │      └────────┘ └─────────┘  │
        └──────────────────────────────┘
```

Câu xác nhận nói rõ history cũng mất — hậu quả người dùng không đoán được từ chữ
"xoá card". `Cancel` được autofocus, theo tiền lệ `mx_confirm_dialog` hiện có.

**Hai lối vào, một dialog.** Long-press ở danh sách, và danger zone trong
editor (W6b) — xem bảng ở W6b về việc mỗi lối phục vụ ai. Cả hai kết thúc ở
đúng dialog trên.

Long-press không có affordance nhìn thấy được, và đó là cái giá đã biết: `⋮`
trên hàng bị bỏ vì góc phải đã là badge hạn và cờ ⚑. Danger zone trong editor
là thứ bù lại — người không đoán ra long-press vẫn tìm được nút xoá bằng cách
mở thẻ, là điều họ sẽ làm để xem nội dung trước khi xoá.

**Xoá card cuối cùng** đưa list về W2 (`No cards yet`), **không** về W3:
`content_type` giữ nguyên `card` theo BR-67. Deck không hỏi lại câu đã trả lời.
Phủ UC-04 A2.

---

## 13. W8 · Loading, submitting, error

```
   LOADING                SUBMITTING             ERROR
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  ←  Deck  ⋮  │      │  ✕  New  ···  │      │  ✕  New  Save│
├──────────────┤      ├──────────────┤      ├──────────────┤
│              │      │ FRONT        │      │ ⚠ Couldn't   │
│      ◌       │      │ ┌──────────┐ │      │   save this  │
│              │      │ │ephemeral │ │      │   card.      │
│              │      │ └──────────┘ │      │   Try again. │
│              │      │  (disabled)  │      │              │
└──────────────┘      └──────────────┘      │ FRONT        │
 MxLoadingState        Save → spinner       │ ┌──────────┐ │
                       Field khoá           │ │ephemeral │ │ ← GIỮ NGUYÊN
                                            │ └──────────┘ │
                                            └──────────────┘
```

Ba acceptance criteria của M4.11 nằm ở đây:

- **Double-submit không tạo hai card.** Nút chuyển spinner và khoá ngay ở lần
  chạm đầu.
- **Lỗi persistence giữ nội dung form** (UC-04 E3). Lỗi hiện ở đầu màn chứ không
  phải snackbar: snackbar tự biến mất, còn người vừa mất 2000 ký tự cần thứ ở lại.
- **Không bao giờ có card thiếu review state.** Cả hai nằm trong một transaction
  (BR-09); hỏng thì rollback cả hai.

---

## 14. W9 · 320×568, `textScaler` 2.0

```
┌────────────────────────────────┐
│ ✕      New card                │  Save xuống thân màn
├────────────────────────────────┤
│ FRONT                          │
│ ┌────────────────────────────┐ │
│ │ ephemeral                  │ │
│ │                            │ │
│ └────────────────────────────┘ │
│                     9 / 2000   │
│ BACK                           │
│ ┌────────────────────────────┐ │
│ │ lasting a very short…      │ │
│ └────────────────────────────┘ │
│                    26 / 2000   │
│ ┌────────────────────────────┐ │
│ │           Save             │ │  full-width
│ └────────────────────────────┘ │
│ ┌────────────────────────────┐ │
│ │    Save and add another    │ │  xếp dọc, không cạnh nhau
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

Ở 2.0, `Save` rời app bar xuống thân màn: một action chữ trong app bar ở cỡ đó
hoặc bị cắt hoặc đẩy title mất. Hai nút xếp dọc chứ không chia đôi hàng.

---

## 15. Việc còn mở

Mỗi mục dưới đây chặn một phần code cụ thể. Chốt bằng cách điền cột **Chốt** và
thêm dòng vào [Lịch sửa](#1-lịch-sửa).

| ID | Câu hỏi | Chặn cái gì | Chốt |
|---|---|---|---|
| Q1 | ~~Ba chip `New / Due / Learned` có đủ không~~ | — | **Đã chốt ở M4.10at**: bốn nhãn, và chúng suy từ box / interval nên không mất thông tin như bản gộp ba |
| Q2 | ~~Thứ tự card trong list~~ | — | **Đã chốt ở M4.10ar: C1**, `created_at DESC, id DESC` |
| Q3 | `⋮` trên AppBar của card list làm gì. Có thể mượn lại `showDeckActions` của deck | W1 AppBar | — |
| Q4 | Design reference JSX (`CardScreen.jsx`, `CardEditor.jsx`) trong `design_system/ui_kits/memox-app/` — dựng trước hay sau code Flutter | Acceptance criteria "pixel difference dưới 3%" không đo được khi chưa có bản tham chiếu | — |
| Q5 | Copy tiếng Việt cho toàn bộ chuỗi ở trên | ARB `vi` | — |
| Q6 | ~~`windowSize`~~ | — | **Chốt ở lát 1**: `kCardWindowSize = 50`, bước load-more cũng 50 |
| Q7 | ~~Cửa sổ reset khi quay lại màn~~ | — | **Chốt ở lát 1**: `CardListWindow` là `autoDispose` → reset về `windowSize` mỗi lần vào |
| Q12 | Nhãn ô ghi ngôn ngữ (`FRONT · KOREAN`). Deck chưa có cột ngôn ngữ, nên hoặc thêm cột, hoặc bỏ nửa sau của nhãn | Nhãn ô ở W4 | — |
| Q13 | `Save` trên app bar và `Save card` ở đáy là hai lối cho một hành động. Giữ cả hai theo ảnh, hay bỏ cái trên | W4 app bar | — |
| Q8 | ~~Nhãn trạng thái thẻ cần một BR~~ | — | **Đã chốt ở M4.10at**: BR-89…BR-91, bốn nhãn `new / beginning / reviewing / mastered`, `mastered` đọc lại BR-88 |
| Q9 | ~~Chip tag~~ | — | **Đã chốt ở M4.10at**: bảng `tags` + `card_tags`, BR-93/BR-94 |
| Q10 | ~~Cờ ⚑~~ | — | **Đã chốt ở M4.10at**: cột `cards.is_flagged`, BR-92 |
| Q11 | ~~Panel Deck progress~~ | — | **Đã chốt**: vào scope M4.11; bốn con số suy từ BR-89…BR-91, nút Start study vẫn để M5.1 |

---

## 16. Bản đồ phủ

Kiểm chéo wireframe với UC-04 và UC-08, để chỗ thiếu lộ ra thành ô trống chứ
không thành thứ không ai nhớ.

| UC / flow | Wireframe |
|---|---|
| UC-04 main flow | W1, W4 |
| BR-95 — ba trường phụ | W5, W6b |
| BR-93 — tối đa 10 tag | W4, W5 |
| UC-04 A1 — sửa card | W6b |
| UC-04 A2 — xoá card | W7, W6b (danger zone) |
| UC-04 A3 — deck rỗng | W2 |
| UC-04 A4 — thêm liên tiếp | W4 |
| UC-04 E1 — mặt trước/sau rỗng | W6 |
| UC-04 E2 — vượt giới hạn ký tự | W6 |
| UC-04 E3 — ghi thất bại | W8 |
| UC-04 UI states | W1 (loaded), W2 (empty), W8 (loading · submitting · error) |
| UC-08 — card đầu tiên khoá `content_type` | W3 |
| M4.11 scope — `windowSize`, load-more, dòng "đang hiện N / M" | W1, W1b |
| M4.11 scope — hành vi cuộn khi có dòng mới | W1b |
| Màn tham chiếu của chủ dự án — trạng thái đích | W1 §4.1 |
| Màn tham chiếu — khối nào chặn bởi scope, khối nào chặn bởi schema | W1 §4.2 |

Một dòng của scope M4.11 **chưa có wireframe và cố ý vậy**: "auto-load". W1b chốt
là load-more tường minh (C2), nên nếu auto-load nghĩa là tự mở rộng khi cuộn tới
đáy thì hai bên mâu thuẫn — đó là Q6/Q7 phải giải trước khi code. Nếu nó chỉ
nghĩa là cửa sổ đầu tiên tự tải lúc mở màn thì W1 đã phủ.
