# Wireframe · M5 Study modes

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Chốt bố cục và hành vi của năm màn học trước khi viết code M5.7+ |
| **Scope** | Khung phiên học, và năm màn `browse` · `match` · `guess` · `recall` · `fill`. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng (`use-cases.md`), giá trị token (`design_system/tokens/`) |
| **Source of truth for** | Bố cục màn học · các điểm lệch giữa design và BR đang chờ chốt |
| **Depends on** | `document-conventions.md`, `business-rules.md` (BR-108…BR-154), `wbs-study.md` (M5.7…M5.20) |
| **Updated by task** | M5.7r (rà soát việc còn lại của Study) |
| **Last updated** | 2026-08-08 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID; chỗ
nào design và BR lệch nhau thì ghi vào §7 chứ **không** tự chọn bên nào.

## 1. Ảnh gốc

Ảnh do chủ dự án cung cấp, đặt tại `docs/wireframes/assets/m5-study-modes/`:

| Tệp | Màn |
|---|---|
| `12-review.png` | Study · Review — một thẻ, hai mặt cùng lúc |
| `13-match.png` | Study · Match — bàn ghép cặp |
| `14-guess.png` | Study · Guess — năm lựa chọn, trạng thái đã trả lời |
| `15-recall.png` | Study · Recall — đáp án đang ẩn |
| `16-fill.png` | Study · Fill — đang nhập |

Mỗi ảnh có cặp light/dark cạnh nhau. Ảnh 15 và 16 ghi `1/2` ở tiêu đề khung —
tức mỗi màn còn một state thứ hai (đã lật / đã chấm) **chưa có ảnh**.

## 2. Khung dùng chung của mọi màn học

Cả năm màn chia đúng một khung, và đây là thứ nên dựng trước:

```
┌──────────────────────────────────────────┐
│ ✕   [PILL]  ▓▓▓▓▓░░░░░░░░░░░░     8 / 23 │  ← thanh trên
│        VOCAB — CHAPTER 1 · 12 NEW · 11 … │  ← dòng ngữ cảnh
├──────────────────────────────────────────┤
│                                          │
│              (thân theo mode)            │
│                                          │
├──────────────────────────────────────────┤
│  ✓  Tap a term, then its meaning to match│  ← dòng gợi ý dưới
└──────────────────────────────────────────┘
```

- **Nút ✕ bên trái**, không phải mũi tên back: thoát phiên là một hành động có
  hậu quả (BR-82 ghi `abandoned`/`user_exit`), khác với lùi một màn.
- **Pill tên mode**, chữ hoa, nền nhạt cùng tông với màu của mode.
- **Thanh tiến trình + đếm `n / m`** ở cùng một hàng.
- **Dòng ngữ cảnh** dưới thanh trên: tên deck và thông tin phụ của mode.
- **Dòng gợi ý dưới cùng**: một câu chỉ dẫn thao tác, có icon dẫn đầu.

**Hai họ màu.** `browse`/`match`/`guess` dùng xanh dương (màu primary);
`recall`/`fill` dùng xanh lá. Design không nói vì sao, và nó **không** trùng với
bất kỳ phân loại nào trong BR — xem §7.8.

## 3. Study · Review (ảnh 12)

Thân là **một thẻ duy nhất chiếm toàn bộ chiều cao**, chia đôi bằng một đường kẻ
mảnh:

- nửa trên: nhãn `KOREAN` (chữ nhỏ, hoa, mờ) ở góc trái; mặt trước căn giữa, cỡ
  lớn nhất màn hình.
- nửa dưới: nhãn `MEANING`; nghĩa căn giữa, cỡ vừa.

Không có nút hành động nào. Dòng dưới: *"Swipe left for next, right to go back"*.

Hai mặt cùng lúc và không có bước lật → đây là `browse` theo BR-112, **dù pill
ghi REVIEW**. Xem §7.1.

## 4. Study · Match (ảnh 13)

Lưới hai cột, mỗi hàng một cặp ô. Ba trạng thái ô:

| Trạng thái | Hình thức |
|---|---|
| chưa chọn | nền surface, viền mảnh |
| đang chọn (vế trước) | nền primary đặc, chữ trắng |
| đã ghép đúng | nền xanh lá rất nhạt, chữ xanh lá, có ✓, mờ đi |

Ô đã ghép **vẫn nằm nguyên chỗ** chứ không biến mất — khác với bản M5.4b hiện
tại, vốn xoá ô khỏi bàn.

Dòng ngữ cảnh: `BOARD 1 OF 3 · 4 PAIRS LEFT`. Khái niệm "board" chưa có trong
BR — xem §7.6.

## 5. Study · Guess (ảnh 14)

- Thẻ đề ở trên: nhãn `WHAT IS THIS?` rồi thuật ngữ cỡ lớn.
- Năm hàng lựa chọn A–E. Mỗi hàng: huy hiệu tròn chứa chữ cái, nhãn chính, và
  **một dòng mô tả phụ** cỡ nhỏ.
- Sau khi trả lời: đáp án đúng nền xanh lá + ✓; lựa chọn sai đã chọn nền đỏ + ✕;
  ba lựa chọn còn lại mờ đi.

Dòng mô tả phụ chưa có nguồn dữ liệu — xem §7.5.

## 6. Study · Recall (ảnh 15) và Study · Fill (ảnh 16)

Cùng một bố cục: **thẻ đề ở trên, vùng đáp án ở dưới, nút hành động dưới cùng.**

`recall`: vùng đáp án là một khối mờ có vạch giả; nút chính `Show answer`.
`fill`: vùng đáp án là ô nhập, chữ căn giữa cỡ lớn, có con trỏ; hai nút — `Hint`
viền và `Check` đặc.

Cả hai thẻ đề có **icon bút chì góc trên phải**; `recall` có thêm **icon loa góc
dưới phải**. Không màn nào hiện đồng hồ đếm ngược. Xem §7.3 và §7.4.

## 7. Điểm lệch giữa design và BR — **chưa chốt**

Đây là phần quan trọng nhất của tài liệu. Không mục nào dưới đây được tự quyết
khi viết code; mỗi mục cần chủ dự án chọn, và mỗi lựa chọn có giá khác nhau.

### 7.1 Pill ghi `REVIEW` cho màn hiện hai mặt

Màn ảnh 12 hiện cả hai mặt và không có nút chấm điểm — đó là `browse` (BR-112).
Nhưng pill ghi `REVIEW`, là tên mode cũ trước đợt đổi Review → Study.

**Cần chốt:** pill hiển thị tên nào cho `browse`. Đổi chuỗi là một dòng ARB.

### 7.2 Một phiên trộn cả thẻ mới lẫn thẻ ôn

Dòng ngữ cảnh ghi `12 NEW · 11 REVIEW` và bộ đếm `8 / 23` = 12 + 11.

**BR-142 cấm điều này**: một phiên là `learning` **hoặc** `reviewing`, không bao
giờ cả hai. Đây cũng chính là luật chủ dự án yêu cầu bắt buộc ở đợt brainstorm —
"không chạy đua số lượng thẻ".

**Cần chốt:** hoặc bỏ phần trộn khỏi design (chỉ hiện số của phiên đang chạy),
hoặc đảo lại BR-142. Đảo BR-142 là thay đổi lớn: nó kéo theo `session_kind`,
cách lấy thẻ, và toàn bộ luồng hoàn tất chuỗi học mới.

### 7.3 `recall` không hiện đồng hồ

BR-128 cho mỗi lượt `recall` **20 giây** đo bằng thời gian tương tác. Design
không có chỗ nào hiện thời gian còn lại.

**Cần chốt:** thêm đồng hồ vào đâu trên khung (gợi ý: thay chỗ bộ đếm `8 / 12`,
hoặc một vòng tròn quanh nút), hay bỏ giới hạn thời gian. Bỏ giới hạn là sửa
BR-128, BR-129, BR-130, BR-131 và xoá cột `remaining_ms`, `outcome_reason`.

### 7.4 Icon bút chì và icon loa

- **Bút chì**: sửa thẻ ngay giữa phiên học. Chưa có luật nào nói việc sửa nội
  dung thẻ đang được hỏi thì lượt đó tính thế nào.
- **Loa**: phát âm. Media bị **hoãn có chủ đích** ở MVP (AD-03) và
  `data-model.md` xếp `card_media` vào phần "chưa mô hình hoá".

**Cần chốt:** giữ hai icon này ở MVP hay để lại cho bản sau. Giữ loa nghĩa là mở
lại quyết định về media.

### 7.5 Dòng mô tả phụ dưới mỗi lựa chọn của `guess`

Design hiện `library` kèm *"public building or room with a collection of…"*.
`cards` không có trường nào cho nghĩa mở rộng: `back` là nghĩa, `example` là câu
ví dụ, `hint` là gợi ý.

**Cần chốt:** dùng `hint` cho dòng này, thêm trường mới, hay bỏ dòng phụ. Thêm
trường là migration v6.

### 7.6 Khái niệm "board" của `match`

Design ghi `BOARD 1 OF 3` — tức một round được chia thành nhiều bàn nhỏ. BR-115
và BR-117 chỉ có **round**, không có board.

**Cần chốt:** board là gì so với round. Nếu board = một lát của round thì cần một
BR mới nói kích thước bàn và cách chia; nếu board = round thì chỉ là đổi chữ.

### 7.7 Vuốt phải để quay lại thẻ trước

Design cho `browse` vuốt phải để lùi. Mô hình hàng đợi hiện tại chỉ tiến:
`cursor` tăng mỗi lượt và là nền của BR-26.

**Cần chốt:** lùi được hay không, và nếu được thì lùi có đổi `cursor` không. Cho
lùi mà vẫn giữ `cursor` là an toàn nhất — nhưng nó nghĩa là thẻ đã xem lại được
xem lần nữa mà không ghi gì.

### 7.8 Hai họ màu

`browse`/`match`/`guess` xanh dương, `recall`/`fill` xanh lá. Không luật nào chia
mode thành hai nhóm như vậy — BR-115 chia thành "dùng round" (bốn mode chấm
điểm) và "không dùng round", không khớp với cách chia màu này.

**Cần chốt:** màu mang ý nghĩa gì. Nếu chỉ để phân biệt thị giác thì cần token
cho từng mode; nếu mang nghĩa nghiệp vụ thì nghĩa đó phải thành một luật.

## 8. Điều design **khớp** với BR đang có

Ghi lại để không ai đi chốt lại thứ đã đúng:

- `guess` đúng **năm** lựa chọn (BR-121), có trạng thái đúng/sai rõ ràng.
- `fill` có nút `Hint` riêng, tách khỏi `Check` — khớp BR-136 (ghi nhận việc dùng
  gợi ý, không đổi kết quả).
- `match` chọn vế trước rồi vế sau — khớp BR-118 (lượt thuộc về vế được chọn
  trước).
- `browse` không có nút chấm điểm nào — khớp BR-111.
- Nút ✕ thay vì back — khớp với việc thoát phiên là hành động có ghi nhận
  (BR-82).
