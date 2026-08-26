# Wireframe · M4.11 Card management

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Chốt bố cục và hành vi UI của màn card trước khi viết code M4.11 |
| **Scope** | Card list, card editor, xoá card, các state của hai màn đó. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng người dùng (`use-cases.md`), giá trị token (`design_system/tokens/`), màn review (M5.1) |
| **Source of truth for** | Bố cục màn card M4.11 · quyết định UI đã chốt và còn mở của task này |
| **Depends on** | `document-conventions.md`, `use-cases.md` (UC-04, UC-08), `business-rules.md` (BR-88…BR-94), `data-model.md` (schema v2), `wbs.md` (M4.10at, M4.11) |
| **Updated by task** | M99.61 |
| **Last updated** | 2026-08-26 |

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
| 2026-08-26 | M99.61 | — | Chốt **D28**: editor bỏ hẳn lối xoá thẻ; D10 supersede phần đó, UC-04 A2 (frozen) không đụng vì A6 vẫn phủ. W6b vẽ lại theo Card Editor UX hardening: Save ghim đáy và disabled khi pristine, discard guard cho mọi lối rời màn, Delete outlined không heading, disclosure có nhãn ba trường, tag ghi tức thì với nút Add nhìn thấy được. Chốt D27. D6 và D10 giữ nguyên lịch sử, chỉ phần W6b bị supersede. Chế độ tạo (W4) **không** đổi. |
| 2026-08-12 | M99.17 | Codex | Đồng bộ màn đã triển khai và định hướng quản lý dữ liệu: tạo thủ công là luồng nhỏ qua app-bar `+`; Back một dòng là summary, tap mở editor để xem đủ; search/filter/sort phục vụ tìm card; import/export là hướng bulk-management sau MVP. |

---

## 2. Quyết định đã chốt

| ID | Quyết định | Lý do | Ngày |
|---|---|---|---|
| D1 | Card editor là **full-screen route**, không phải bottom sheet | Hai ô tới 2000 ký tự (BR-08) cộng luồng thêm liên tiếp (UC-04 A4) không vừa sheet ở 320×568 với `textScaler` 2.0. Lệch khỏi tiền lệ deck form (`showDeckRenameForm`) một cách có chủ đích. | 2026-08-02 |
| D2 | Hàng card hiện **front + back + chip trạng thái ôn tập** | Quét được cả cặp mà không phải mở từng card. Chip đọc từ `card_review_states` mà BR-09 đã tạo sẵn lúc tạo card, nên không cần dữ liệu mới. | 2026-08-02 |
| D3 | Search, filter và sort đều là control thật của danh sách | Card list phục vụ tìm và sửa một card cụ thể; cả ba control phải biến đổi query thật, không phải affordance trang trí. Chúng cho phép giữ card tile đủ thoáng thay vì đổi màn thành bảng dữ liệu dày đặc. | 2026-08-12 |
| D4 | Tạo card thủ công dùng app-bar `+`, không dùng extended FAB | Tạo từng card là luồng khối lượng nhỏ; app-bar giữ action nhất quán với Library và không nhấn quá mức lên manual entry. Import/export sau MVP mới là đường quản lý hàng loạt và sẽ có entry riêng khi use case được đặc tả. | 2026-08-12 |
| D6 | Editor có **thanh hành động ghim đáy**, và `Save & add another` sống ở đó | Ảnh tham chiếu có `Cancel` + `Save card` ở đáy nhưng **không** có add-another, trong khi UC-04 A4 (frozen) đòi giữ form mở. `Cancel` bỏ đi vì `✕` ở app bar đã làm đúng việc đó; chỗ trống thành add-another. | 2026-08-02 |
| D7 | Ba trường phụ nằm trong một **disclosure đóng mặc định** | BR-95 cho cả ba là tuỳ chọn. Mở sẵn biến form hai ô thành form năm ô cho việc thường gặp nhất. | 2026-08-02 |
| D8 | Deck hiện **read-only**, không phải picker | Đổi deck đích nghĩa là thẻ có thể sang root khác scheduler hoặc khác generation — đúng thứ BR-73/BR-74 đang chặn. Deck là ngữ cảnh màn đang mở. | 2026-08-02 |
| D10 | Xoá thẻ có **hai lối**: chọn nhiều ở danh sách, và danger zone trong editor | Ảnh tham chiếu đặt danger zone trong editor. Giữ cả hai vì chúng phục vụ hai việc khác nhau — dọn hàng loạt, và bỏ một thẻ đang đọc. **Sửa ở M99.16:** lối danh sách không còn là action sheet một-thẻ mà là chế độ chọn nhiều (D13); action sheet đó chưa bao giờ tồn tại trong production. | 2026-08-02, sửa 2026-08-12, **supersede 2026-08-26 bởi D28** |
| D27 | Ở **chế độ sửa**, `Save changes` là hành động ghim đáy duy nhất và bị **disable khi form còn pristine**; Delete là outlined destructive nằm trong thân cuộn, không có heading `Danger zone` | Ba việc khác nhau trong một quyết định, vì chúng là cùng một lỗi thứ bậc. **(a)** Save cũ nằm giữa Optional details và Tags: nó cuộn mất khi người dùng sửa tag, và vị trí *trên* Tags ngụ ý phạm vi lưu gồm cả tag — trong khi tag ghi tức thì (BR-93), tức là ngụ ý sai theo hướng mất dữ liệu. **(b)** Save luôn bấm được thì không nói gì về việc có gì để lưu; bấm nó ghi đè thẻ bằng chính nó. **(c)** Delete cũ dùng filled `error`, đúng bằng độ nhấn của Save, nên màn hình có hai hành động cùng hét to và chỉ còn màu để phân biệt cái nào kết thúc thẻ. Heading `Danger zone` chính là dấu hiệu: một cái nhãn đi làm việc mà trọng lượng của nút lẽ ra phải làm. **Supersede D6 chỉ cho W6b** — chế độ tạo vẫn theo D6 và không thuộc task này. | 2026-08-26 |
| D28 | Editor **không** có lối xoá thẻ; xoá chỉ còn ở chế độ chọn của danh sách | Bỏ hẳn thay vì hạ trọng lượng thêm một lần nữa. D27(c) đã đổi nút filled đỏ thành outlined và bỏ heading `Danger zone`; nhìn màn dựng thật, câu hỏi còn lại không phải nó *to* bao nhiêu mà là vì sao một hành động phá huỷ full-width lại nằm trên màn có mỗi việc là sửa chữ. **UC-04 A2 (frozen) không bị đụng:** nó đòi "xoá card, hỏi xác nhận", không đòi lối vào ở editor — A6 (long-press → chọn → Delete) vẫn phủ đúng câu đó. Cái mất là đường tắt một-thẻ: từ editor giờ phải quay ra danh sách, long-press, chọn, xoá. Chủ dự án chấp nhận đánh đổi đó. | 2026-08-26 |
| D13 | Long-press ở danh sách **vào chế độ chọn**, không mở action sheet | Đây là cử chỉ Android chuẩn cho selection, và nó là thứ đang thiếu để quản lý hàng loạt (BR-167). Vì cử chỉ không có affordance, app bar có thêm action **Select** nhìn thấy được. Thanh hành động ngữ cảnh là một **băng phía trên danh sách** chứ không phải app bar bị thay: ở 320px với `textScaler` 2.0, số đã chọn cộng năm hành động không nằm vừa một hàng 56pt, và `AppBar` xử lý việc đó bằng cách tràn chứ không xuống dòng. | 2026-08-12 |
| D11 | `OPTIONAL DETAILS` **đóng khi rỗng, mở khi đã có nội dung** | Ảnh tạo cho thấy disclosure đóng, ảnh sửa cho thấy ba ô mở sẵn — không mâu thuẫn, mà là cùng một quy tắc ở hai trạng thái. Đóng một ô đang có chữ là giấu nội dung của chính người dùng. | 2026-08-02 |
| D9 | **Không** có nút micro nhập giọng nói | Ảnh tham chiếu có. Nó cần plugin, quyền hệ điều hành và một luồng lỗi riêng; không nằm trong scope M4.11 và gần với media, vốn đã hoãn. | 2026-08-02 |
| D5 | Hàng card là **bốn phần**: dot trạng thái · front · back · nhãn trạng thái, cộng badge hạn bên phải | Từ ảnh tham chiếu. Thay chip đơn của bản đầu. Ba tín hiệu trạng thái trả lời ba câu khác nhau — xem bảng ở §4.3 — và gộp lại thành một chip là mất hai trong ba. | 2026-08-02 |
| D12 | Back trên tile là summary một dòng có ellipsis; tap toàn tile mở editor để xem đủ | Tăng thành hai hay ba dòng vẫn phải cắt với Back dài và làm chiều cao list biến động. Danh sách dùng để nhận diện; editor full-screen đã là đường detail + edit nên không dựng thêm màn read-only trùng trách nhiệm. | 2026-08-12 |

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
│  App bar `+` → New card                      │
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
| App-bar `+` → New card | — | **M4.11** — xem D4 |
| Nút `🔍` search | — | **Đã triển khai sau M4.11** — xem D3 |
| Sort | có | **Đã triển khai sau M4.11** — xem D3 |
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
│  App bar `+` → New card                      │
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
card đi qua chế độ chọn ở danh sách (W9) hoặc danger zone trong editor (W6b).

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

Vẽ lại 2026-08-26 theo D27. Bản 2026-08-02 (dựng từ hai ảnh tham chiếu) bị
supersede **chỉ ở màn này**; W4 chế độ tạo giữ nguyên.

```
┌──────────────────────────────────────────────┐
│  ✕   Edit flashcard                     ⚑    │  ✕ có discard guard; ⚑ ghi ngay
├──────────────────────────────────────────────┤
│                                              │
│  ┌─ Front ────────────────────────────────┐  │
│  │ 연구자                                 │  │  value = body
│  └────────────────────────────────────────┘  │
│                                              │
│  ┌─ Back ─────────────────────────────────┐  │
│  │ Researcher / Nhà nghiên cứu            │  │  value = body
│  └────────────────────────────────────────┘  │
│  Editing the text doesn't change this        │  helperText của Back (BR-10)
│  card's study progress.                      │
│                                              │
│  Add example, hint & pronunciation      ⌄    │  hàng ≥48dp, expanded semantics
│                                              │
│  Tags                                 3 / 10 │
│  ⟨TOPIK II ✕⟩ ⟨noun ✕⟩ ⟨people ✕⟩            │  ✕: băng chạm 33×48 — xem dưới
│  ┌────────────────────────────────────┬───┐  │
│  │ Add tag                            │ + │  │  + = trailing action
│  └────────────────────────────────────┴───┘  │
│                                              │
├──────────────────────────────────────────────┤
│  ┌────────────────────────────────────────┐  │
│  │             Save changes               │  │  ghim đáy; disabled khi pristine
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

**Hai chỗ chủ dự án đảo lại sau khi xem màn dựng thật (2026-08-26).**

- **Front không đậm hơn Back.** D27 bản đầu cho value của Front `titleLarge`
  với lập luận "Front là đề, Back là đáp, hai bên không ngang nhau". Nhìn trên
  màn thật nó đọc ra **nặng**, không phải **chính**. Cả hai mặt trở lại input
  style của theme — cũng là thứ chế độ tạo vẫn luôn dùng, nên luật giờ giống
  nhau ở hai chế độ thay vì một chế độ là ngoại lệ.
- **Chip tag không nới rộng.** `deleteIconBoxConstraints: minWidth 48` đưa băng
  chạm của nút ✕ từ **33×48** lên **48×48** và tốn **28px bề rộng mỗi chip**
  (80 → 108); ở 10 tag đó là ba hàng thay vì hai, trên đúng màn hẹp nhất. Chủ
  dự án chọn bề rộng. Ghi rõ con số ở đây vì
  `meetsGuideline(androidTapTargetGuideline)` **xanh ở cả hai trạng thái** — nó
  đọc rect semantics, mà node nút xoá merge vào node 48 của chip; ai mở lại việc
  này cần con số thật chứ không phải phán quyết của matcher. Chiều cao 48 thì
  có sẵn: `_RenderChipRedirectingHitDetection` giao cả dải cao của viên chip cho
  slot nằm dưới x.

**Ba thứ bản vẽ này cố ý không có, vì production không có.** Bản 2026-08-02
(dựng từ ảnh tham chiếu) vẽ nhãn kiểu `FRONT · KOREAN`, một dấu `Required`, và
counter luôn hiện. Không cái nào tồn tại: nhãn là floating label của
`MxTextField` nên chỉ là `Front`/`Back`; ràng buộc bắt buộc được nói bằng
**lỗi khi submit** (BR-07) chứ không bằng một dấu cạnh nhãn; và counter chỉ xuất
hiện từ 80% giới hạn (`MxTextField._counterVisibleFraction`) — `0 / 240` dưới
một ô rỗng là tiếng ồn về một luật người dùng còn cách rất xa. Ghi ra vì bản vẽ
này được vẽ lại *trong* cùng diff với code, nên một chi tiết chép lại từ bản cũ
sẽ thành một sai lệch mà không ai biết là sai lệch.

### Cái gì thuộc Save, và cái gì không

Đây là sự thật hay bị đọc sai nhất ở màn này, nên nó được viết ra chứ không suy
từ hình.

| Thứ | Ghi khi nào | Có làm Save sáng lên không |
|---|---|---|
| Front, Back, Example, Hint, Pronunciation | khi bấm `Save changes` | **có** — đúng năm trường này |
| Tag (thêm/xoá) | ngay lập tức (BR-93) | không |
| Cờ ⚑ | ngay lập tức (BR-92) | không |
| Chữ đang gõ trong ô Add tag | chưa ghi | **không** — nhưng có bật discard guard |
| Mở/đóng `Add example, hint & pronunciation` | không ghi gì | không |

Dòng thứ tư là dòng phải đọc kỹ: chữ chưa submit **là** việc người dùng sẽ mất,
nên nó tham gia câu hỏi lúc rời màn; nó **không** thuộc Save, nên một nút Save
sáng lên vì nó sẽ hứa một việc mà nút đó không làm.

Dirty là so sánh với ảnh chụp lúc nạp thẻ, không phải cờ "đã từng sửa": gõ một
chữ rồi xoá đi thì Save tắt lại, vì đó mới là trạng thái người dùng đang ở.
Khoảng trắng thừa không tính — `parseCardForm` trim, nên bản ghi sẽ y hệt.

### Rời màn có một cửa

`✕` và cử chỉ Back của hệ thống đi vào **cùng một** coordinator:

- pristine → rời ngay, không hỏi;
- có nội dung dirty **hoặc** có chữ trong ô Add tag → `MxConfirmDialog`
  `Discard changes?` / `Keep editing` · `Discard`, tone `warning`, focus rơi vào
  `Keep editing`;
- đang submit → không rời, không mở dialog;
- Back hai lần liên tiếp → **một** dialog;
- save thành công → rời đúng một lần, không hỏi discard.

Thông điệp discard nói cả cái **không** mất: tag và cờ đã ghi rồi. Người đọc
"unsaved changes will be lost" không có cách nào tự biết cái tag vừa thêm vẫn còn.

### Ba khối trong ảnh nhưng không có ở đây

Ghi ra để lần sau không ai tưởng là bỏ sót. Cả ba nằm ở
`wbs.md` §Deferred and descoped.

| Trong ảnh | Vì sao chưa vẽ |
|---|---|
| `Last edited 3 days ago · 14 reviews · 78% recall · History ›` | `% recall` cần một BR định nghĩa "nhớ được" cho từng scheduler; link `History` mở màn review history, thứ M4.11 đặt ngoài scope |
| Icon mic trong ô FRONT | Nhập giọng nói — plugin, quyền OS, luồng lỗi riêng (D9) |
| Icon loa trong ô PRONUNCIATION | Phát âm bằng TTS — cùng lý do |

### Bốn thứ của bản 2026-08-02 không còn đúng

| Bản cũ | Bây giờ | Vì sao |
|---|---|---|
| `←` ở app bar | `✕` | `←` nói "quay lại", nhưng ở đây rời màn có thể mất draft. `✕` là "đóng cái này", và nó là cái có guard. Breadcrumb không vẽ ở màn này nên D-của-M4.10ar về `←` không áp dụng. |
| `Cancel` cạnh `Save changes` ở thanh đáy | chỉ `Save changes` | Thanh đáy chỉ chứa hành động chính. Lối thoát là `✕`, và nó đã hỏi trước khi vứt. Hai nút ở đáy làm nút phá huỷ ở trên (`Delete card`) và nút thoát nằm cùng một vùng mắt. |
| `OPTIONAL DETAILS` mở sẵn, không disclosure | disclosure có nhãn `Add example, hint & pronunciation` | D11 vẫn đúng và vẫn chạy: thẻ **đã có** detail thì mở sẵn. Cái đổi là nhãn lúc đóng — `Add details` không nói tap vào sẽ hiện ra gì. |
| Khối `⚠ DANGER ZONE` với tiêu đề, câu mô tả và nút xoá | **không còn gì** | D28. Đi qua hai bước: D27(c) hạ nút filled đỏ xuống outlined và bỏ heading; rồi bỏ hẳn. Hậu quả xoá vẫn được nêu — trong dialog xác nhận của luồng chọn nhiều, đúng chỗ người dùng đang quyết định. |
| Nhãn `FRONT · KOREAN`, dấu `Required`, counter luôn hiện | `Front` / `Back`, không dấu, counter từ 80% giới hạn | Xem đoạn ngay dưới bản vẽ. Cả ba là hành vi, không phải nét vẽ. |

### Xoá thẻ chỉ còn một lối (D28)

| Lối | Ở đâu | Dùng khi |
|---|---|---|
| Long-press hàng → chế độ chọn (W9) | danh sách | Bỏ một thẻ, hoặc dọn cả tập đã lọc |

Bản 2026-08-02 có hai lối và ghi rõ đó là chủ đích: người dọn hàng loạt không
phải mở editor mười lần, còn người đang phân vân thì thấy nút xoá ở đúng chỗ họ
đang nhìn nội dung. Lập luận thứ hai vẫn đúng về mặt luồng — cái nó không trả
lời được là **vì sao một hành động phá huỷ full-width lại nằm trên một màn có
mỗi việc là sửa chữ**, và đó là thứ chỉ nhìn ra được khi nhìn màn dựng thật.

Cái mất, ghi ra để không ai tưởng là bỏ sót: xoá một thẻ đang mở giờ tốn bốn
bước — ra danh sách, long-press, chọn, xoá — thay vì một.

Soft-delete, cửa sổ Undo (BR-256) và câu mô tả hậu quả **không đổi**: chúng thuộc
dialog xác nhận của luồng chọn nhiều. Câu đó nói rõ cái gì mất và cái gì ở lại —
history mất theo, các thẻ khác trong deck thì không. Xoá thẻ **cuối cùng** còn
một hậu quả nữa: deck mất loại nội dung và quay về chưa định loại (BR-163).

---

## 12. W7 · Xoá card

```
        ┌──────────────────────────────┐
        │  Card actions                │   (không còn: long-press vào chế độ chọn)
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

Long-press không có affordance nhìn thấy được, và M99.16 trả lời điều đó bằng
action **Select** trên app bar chứ không bằng `⋮` trên hàng — góc phải hàng đã
là badge hạn và cờ ⚑. Danger zone trong editor vẫn là lối thứ hai — người đang
đọc nội dung một thẻ tìm được nút xoá bằng cách
mở thẻ, là điều họ sẽ làm để xem nội dung trước khi xoá.

**Xoá card cuối cùng** không dừng ở list nữa. Deck trở về `unset` trong cùng
transaction (BR-163), nên điều hướng đi qua màn hình deck: còn thẻ thì redirect
đưa người dùng lại card list, hết thẻ thì họ ở lại deck và chọn được Tạo card
hay Tạo sub-deck. W2 (`No cards yet`) vì thế là trạng thái của một bộ lọc, không
còn là trạng thái ổn định của deck rỗng. Phủ UC-04 A2.

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
| UC-04 A2 — xoá card | W7, W9 (chế độ chọn). **Không** còn ở W6b — D28. |
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
