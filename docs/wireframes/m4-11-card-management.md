# Wireframe · M4.11 Card management

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Chốt bố cục và hành vi UI của màn card trước khi viết code M4.11 |
| **Scope** | Card list, card editor, xoá card, các state của hai màn đó. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng người dùng (`use-cases.md`), giá trị token (`design_system/tokens/`), màn review (M5.1) |
| **Source of truth for** | Bố cục màn card M4.11 · quyết định UI đã chốt và còn mở của task này |
| **Depends on** | `document-conventions.md`, `use-cases.md` (UC-04, UC-08), `business-rules.md`, `wbs.md` (M4.11) |
| **Updated by task** | M4.11 |
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

---

## 2. Quyết định đã chốt

| ID | Quyết định | Lý do | Ngày |
|---|---|---|---|
| D1 | Card editor là **full-screen route**, không phải bottom sheet | Hai ô tới 2000 ký tự (BR-08) cộng luồng thêm liên tiếp (UC-04 A4) không vừa sheet ở 320×568 với `textScaler` 2.0. Lệch khỏi tiền lệ deck form (`showDeckRenameForm`) một cách có chủ đích. | 2026-08-02 |
| D2 | Hàng card hiện **front + back + chip trạng thái ôn tập** | Quét được cả cặp mà không phải mở từng card. Chip đọc từ `card_review_states` mà BR-09 đã tạo sẵn lúc tạo card, nên không cần dữ liệu mới. | 2026-08-02 |
| D3 | **Không** có search/filter/sort trên màn card | `wbs.md` M4.11 đặt thẳng chúng vào out-of-scope: thứ tự cố định, không control đổi thứ tự, search thẻ là S1. Deck list có search là quyết định riêng của M4.10; chép sang đây là nới scope. | 2026-08-02 |

**D2 có một ranh giới phải giữ.** M4.11 **đọc** state row để vẽ chip; nó không
tính lịch. `due_at` tiến lên là việc của M5.1. Nếu chip bắt đầu cần biết box số
mấy hay interval bao nhiêu thì nó đã bước sang M5.1 — dừng lại và hỏi.

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

## 4. W1 · Card list — loaded

```
┌──────────────────────────────────────────────┐
│  ←   Academic Word List                  ⋮   │  AppBar
├──────────────────────────────────────────────┤
│  Library › English › Academic Word List      │  MxBreadcrumb
│                                              │
│  SHOWING 50 OF 214                           │  section label · C3
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ ephemeral                          ⋮   │  │  front · title-sm
│  │ lasting a very short time              │  │  back  · body-sm, 1 dòng
│  │ ◷ Due now                              │  │  chip trạng thái
│  └────────────────────────────────────────┘  │
│                                              │  ← AppSpacing.md giữa các card
│  ┌────────────────────────────────────────┐  │
│  │ ubiquitous                         ⋮   │  │
│  │ present, appearing, or found every…    │  │  ellipsis khi tràn
│  │ ○ New                                  │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ pragmatic                          ⋮   │  │
│  │ dealing with things sensibly and re…   │  │
│  │ ✓ Learned                              │  │
│  └────────────────────────────────────────┘  │
│                                              │
│                                    ┌──────┐  │
│                                    │  +   │  │  FAB → /cards/new
│                                    └──────┘  │
└──────────────────────────────────────────────┘
```

Chạm vào hàng mở editor chế độ sửa. `⋮` mở action sheet (W7).

| Chip | Điều kiện | Token |
|---|---|---|
| `○ New` | chưa có review nào | `textSecondary` |
| `◷ Due now` | `due_at <= now`, đọc qua `clockProvider` | `semantic.warning` |
| `✓ Learned` | `due_at > now` | `semantic.success` |

Không widget nào trong `lib/features/` được đọc đồng hồ tường trực tiếp — giờ
đến từ `clockProvider` ở composition root, theo `CLAUDE.md`.

**Dòng đếm nói cửa sổ, không nói deck.** `SHOWING 50 OF 214` là cách C2 và C3
hiện ra: 50 là cửa sổ đang mở, 214 là tổng thật từ query riêng. Viết `214 CARDS`
sẽ nói dối về thứ người dùng cuộn được, và viết `50 CARDS` sẽ nói dối về deck.

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

```
┌──────────────────────────────────────────────┐
│  ✕                New card            Save   │
├──────────────────────────────────────────────┤
│                                              │
│  FRONT                                       │
│  ┌────────────────────────────────────────┐  │
│  │ ephemeral                              │  │  MxTextField
│  │                                        │  │  multiline, min 3 dòng
│  │                                        │  │
│  └────────────────────────────────────────┘  │
│                                     9 / 2000 │
│                                              │
│  BACK                                        │
│  ┌────────────────────────────────────────┐  │
│  │ lasting a very short time              │  │
│  │                                        │  │
│  │                                        │  │
│  └────────────────────────────────────────┘  │
│                                    26 / 2000 │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │        Save and add another            │  │  MxActionButton secondary
│  └────────────────────────────────────────┘  │
│                                              │
└──────────────────────────────────────────────┘
```

| Hành động | Kết quả |
|---|---|
| `Save` (app bar) | Lưu, pop về list |
| `Save and add another` | Lưu, **giữ màn**, xoá trống hai ô, focus về Front, snackbar `Card added` |

Hai lối lưu là cách UC-04 A4 được thể hiện. Đếm ký tự hiện thường trực chứ không
chỉ khi gần ngưỡng: 2000 là giới hạn người dùng cần biết *trước* khi viết dài.

---

## 9. W5 · Editor — lỗi validation

```
┌──────────────────────────────────────────────┐
│  ✕                New card            Save   │
├──────────────────────────────────────────────┤
│                                              │
│  FRONT                                       │
│  ┌────────────────────────────────────────┐  │
│  │                                        │  │  border → semantic.danger
│  └────────────────────────────────────────┘  │
│  ⚠ Front can't be empty                      │  UC-04 E1
│                                     0 / 2000 │
│                                              │
│  BACK                                        │
│  ┌────────────────────────────────────────┐  │
│  │ Lorem ipsum dolor sit amet, consecte…  │  │
│  └────────────────────────────────────────┘  │
│  ⚠ Back is at the 2000 character limit       │  UC-04 E2
│                                  2000 / 2000 │  ← counter chuyển danger
│                                              │
└──────────────────────────────────────────────┘
```

- **E1** kích hoạt khi submit, không phải khi gõ. Báo "trống" lúc ô còn chưa được
  chạm là la mắng người dùng vì chưa làm gì. Chuỗi toàn khoảng trắng rơi vào E1
  vì BR-07 xét sau khi trim.
- **E2** chặn nhập thêm ở đúng ngưỡng (`maxLength`), và câu lỗi nói *đang ở giới
  hạn* chứ không phải *đã vượt* — vượt là điều không xảy ra được.

---

## 10. W6 · Editor — chế độ sửa

```
┌──────────────────────────────────────────────┐
│  ✕                Edit card           Save   │
├──────────────────────────────────────────────┤
│  FRONT                                       │
│  ┌────────────────────────────────────────┐  │
│  │ ephemeral                              │  │
│  └────────────────────────────────────────┘  │
│                                     9 / 2000 │
│  BACK                                        │
│  ┌────────────────────────────────────────┐  │
│  │ lasting a very short time              │  │
│  └────────────────────────────────────────┘  │
│                                    26 / 2000 │
│                                              │
│  Editing content doesn't reset this card's   │  ← BR-10, nói ra
│  learning progress.                          │
│                                              │
└──────────────────────────────────────────────┘
```

Khác chế độ tạo ở ba chỗ: title, **không có** "Save and add another", và một dòng
giải thích BR-10. Dòng đó không phải trang trí — nỗi sợ "sửa chữ có mất tiến độ
không" là lý do người ta không dám sửa lỗi chính tả trong card. Phủ UC-04 A1.

---

## 11. W7 · Xoá card

```
        ┌──────────────────────────────┐
        │  Card actions                │   MxActionSheet ( ⋮ )
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

**Xoá card cuối cùng** đưa list về W2 (`No cards yet`), **không** về W3:
`content_type` giữ nguyên `card` theo BR-67. Deck không hỏi lại câu đã trả lời.
Phủ UC-04 A2.

---

## 12. W8 · Loading, submitting, error

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

## 13. W9 · 320×568, `textScaler` 2.0

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

## 14. Việc còn mở

Mỗi mục dưới đây chặn một phần code cụ thể. Chốt bằng cách điền cột **Chốt** và
thêm dòng vào [Lịch sửa](#1-lịch-sửa).

| ID | Câu hỏi | Chặn cái gì | Chốt |
|---|---|---|---|
| Q1 | Ba chip `New / Due / Learned` có đủ không? `eight_box` có 8 hộp, `sm2` có interval liên tục — gộp lại là mất thông tin, nhưng chưa màn nào cần hơn | Hình dạng chip ở W1 | — |
| Q2 | ~~Thứ tự card trong list~~ | — | **Đã chốt ở M4.10ar: C1**, `created_at DESC, id DESC` |
| Q3 | `⋮` trên AppBar của card list làm gì. Có thể mượn lại `showDeckActions` của deck | W1 AppBar | — |
| Q4 | Design reference JSX (`CardScreen.jsx`, `CardEditor.jsx`) trong `design_system/ui_kits/memox-app/` — dựng trước hay sau code Flutter | Acceptance criteria "pixel difference dưới 3%" không đo được khi chưa có bản tham chiếu | — |
| Q5 | Copy tiếng Việt cho toàn bộ chuỗi ở trên | ARB `vi` | — |
| Q6 | `windowSize` là bao nhiêu, và bước load-more có bằng nó không. Wireframe vẽ 50/50 làm chỗ đặt số, không phải để chốt | W1b, `card.drift` `LIMIT :limit` | — |
| Q7 | Cửa sổ có reset về `windowSize` khi rời màn rồi quay lại không, hay giữ nguyên độ mở | Controller state ở M4.11 | — |

---

## 15. Bản đồ phủ

Kiểm chéo wireframe với UC-04 và UC-08, để chỗ thiếu lộ ra thành ô trống chứ
không thành thứ không ai nhớ.

| UC / flow | Wireframe |
|---|---|
| UC-04 main flow | W1, W4 |
| UC-04 A1 — sửa card | W6 |
| UC-04 A2 — xoá card | W7 |
| UC-04 A3 — deck rỗng | W2 |
| UC-04 A4 — thêm liên tiếp | W4 |
| UC-04 E1 — mặt trước/sau rỗng | W5 |
| UC-04 E2 — vượt 2000 ký tự | W5 |
| UC-04 E3 — ghi thất bại | W8 |
| UC-04 UI states | W1 (loaded), W2 (empty), W8 (loading · submitting · error) |
| UC-08 — card đầu tiên khoá `content_type` | W3 |
| M4.11 scope — `windowSize`, load-more, dòng "đang hiện N / M" | W1, W1b |
| M4.11 scope — hành vi cuộn khi có dòng mới | W1b |

Một dòng của scope M4.11 **chưa có wireframe và cố ý vậy**: "auto-load". W1b chốt
là load-more tường minh (C2), nên nếu auto-load nghĩa là tự mở rộng khi cuộn tới
đáy thì hai bên mâu thuẫn — đó là Q6/Q7 phải giải trước khi code. Nếu nó chỉ
nghĩa là cửa sổ đầu tiên tự tải lúc mở màn thì W1 đã phủ.
