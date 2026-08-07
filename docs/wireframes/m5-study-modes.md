# Wireframe · M5 Study modes

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt bố cục và hành vi của năm màn học trước khi viết code M5.7+ |
| **Scope** | Khung phiên học, và năm màn `browse` · `match` · `guess` · `recall` · `fill`. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng (`use-cases.md`), giá trị token (`design_system/tokens/`) |
| **Source of truth for** | Bố cục màn học · phán quyết cho tám điểm design lệch với BR |
| **Depends on** | `document-conventions.md`, `business-rules.md` (BR-108…BR-154), `wbs-study.md` (M5.7…M5.20) |
| **Updated by task** | M5.17 (chốt tám điểm lệch) |
| **Last updated** | 2026-08-08 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID.

**Ảnh là UI concept, không phải đặc tả.** Chủ dự án đã chốt: nơi nào design
lệch với nghiệp vụ đã chốt thì nghiệp vụ thắng — §7 ghi phán quyết cho từng
điểm. Dựng màn theo ảnh mà bỏ §7 là cách dựng lại đúng những thứ đã bị bỏ.

## 1. Ảnh gốc

Ảnh do chủ dự án cung cấp, đã có trong repo tại
`docs/wireframes/assets/m5-study-modes/`:

| Tệp | Màn |
|---|---|
| `review_mode.png` | Study · Review — một thẻ, hai mặt cùng lúc |
| `match_mode.png` | Study · Match — bàn ghép cặp |
| `guess_mode.png` | Study · Guess — năm lựa chọn, trạng thái đã trả lời |
| `recall_mode.png` | Study · Recall — đáp án đang ẩn |
| `fill_mode.png` | Study · Fill — đang nhập |

Mỗi ảnh có cặp light/dark cạnh nhau. Ảnh `recall_mode` và `fill_mode` ghi `1/2` ở tiêu đề khung —
tức mỗi màn còn một state thứ hai (đã lật / đã chấm) **chưa có ảnh**.

## 2. Khung dùng chung của mọi màn học

Cả năm màn chia đúng một khung, và đây là thứ nên dựng trước:

```
┌──────────────────────────────────────────┐
│ ✕   [PILL]  ▓▓▓▓▓░░░░░░░░░░░░      8 / 12 │  ← thanh trên
│        VOCAB — CHAPTER 1 · ÔN TẬP         │  ← dòng ngữ cảnh
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
- **Thanh tiến trình + đếm `n / m`** ở cùng một hàng. `n / m` đếm **tập của
  phiên đang chạy**, không trộn hai tập (§7.2); ở mode `recall` chỗ này là
  thời gian còn lại thay vì bộ đếm (§7.3).
- **Dòng ngữ cảnh** dưới thanh trên: tên deck và thông tin phụ của mode.
- **Dòng gợi ý dưới cùng**: một câu chỉ dẫn thao tác, có icon dẫn đầu.

**Hai họ màu.** `browse`/`match`/`guess` dùng xanh dương (màu primary);
`recall`/`fill` dùng xanh lá. Giữ nguyên vì thuần thị giác, nhưng **màu không
mang nghĩa nghiệp vụ** — xem §7.8.

## 3. Study · Review (`review_mode`)

Thân là **một thẻ duy nhất chiếm toàn bộ chiều cao**, chia đôi bằng một đường kẻ
mảnh:

- nửa trên: nhãn `KOREAN` (chữ nhỏ, hoa, mờ) ở góc trái; mặt trước căn giữa, cỡ
  lớn nhất màn hình.
- nửa dưới: nhãn `MEANING`; nghĩa căn giữa, cỡ vừa.

Không có nút hành động nào — khớp BR-111.

Hai chỗ ảnh không được làm theo: pill ghi `REVIEW` (mode tên `browse`, §7.1),
và dòng dưới mời vuốt phải để lùi (`cursor` chỉ tiến, §7.7). Dòng gợi ý chỉ
nói cách đi tiếp.

## 4. Study · Match (`match_mode`)

Lưới hai cột, mỗi hàng một cặp ô. Ba trạng thái ô:

| Trạng thái | Hình thức |
|---|---|
| chưa chọn | nền surface, viền mảnh |
| đang chọn (vế trước) | nền primary đặc, chữ trắng |
| đã ghép đúng | nền xanh lá rất nhạt, chữ xanh lá, có ✓, mờ đi |

Ô đã ghép **vẫn nằm nguyên chỗ** chứ không biến mất — khác với bản M5.4b hiện
tại, vốn xoá ô khỏi bàn.

Dòng ngữ cảnh trong ảnh ghi `BOARD 1 OF 3`; "board" không có trong BR nên nhãn
dùng round: `ROUND 1 · 4 PAIRS LEFT` (§7.6).

## 5. Study · Guess (`guess_mode`)

- Thẻ đề ở trên: nhãn `WHAT IS THIS?` rồi thuật ngữ cỡ lớn.
- Năm hàng lựa chọn A–E. Mỗi hàng: huy hiệu tròn chứa chữ cái, nhãn chính, và
  **một dòng mô tả phụ** cỡ nhỏ.
- Sau khi trả lời: đáp án đúng nền xanh lá + ✓; lựa chọn sai đã chọn nền đỏ + ✕;
  ba lựa chọn còn lại mờ đi.

Dòng mô tả phụ không có trường nào chứa, nên **không dựng** ở MVP: mỗi lựa chọn
chỉ hiện nghĩa (§7.5).

## 6. Study · Recall (`recall_mode`) và Study · Fill (`fill_mode`)

Cùng một bố cục: **thẻ đề ở trên, vùng đáp án ở dưới, nút hành động dưới cùng.**

`recall`: vùng đáp án là một khối mờ có vạch giả; nút chính `Show answer`.
`fill`: vùng đáp án là ô nhập, chữ căn giữa cỡ lớn, có con trỏ; hai nút — `Hint`
viền và `Check` đặc.

Ảnh có **icon bút chì** trên cả hai và **icon loa** ở `recall`; cả hai **không
dựng** ở MVP (§7.4). Ảnh **không** có đồng hồ, còn BR-128 bắt buộc phải có —
`recall` thêm thời gian còn lại vào thanh trên (§7.3).

## 7. Điểm lệch giữa design và BR — **đã chốt**

**Phán quyết của chủ dự án (2026-08-08): ảnh là một *UI concept*. Nơi nào design
lệch với nghiệp vụ đã chốt thì nghiệp vụ thắng.**

Ba hệ quả, áp cho cả tám mục dưới đây và cho mọi design về sau:

1. Design **mâu thuẫn** với một BR đang `active` → làm theo BR, sửa design.
2. Design đề xuất thứ **chưa luật nào nói** → không tự đặt luật mới; để ngoài MVP.
3. Design khác BR ở chỗ **thuần thị giác**, không mâu thuẫn luật nào → giữ design.

Phán quyết này đắt hơn nó nghe: nó bỏ hai thứ trong ảnh mà người dùng nhìn thấy
(icon loa, dòng mô tả phụ) và **thêm** một thứ ảnh không có (đồng hồ `recall`).
Ghi rõ ở đây để không ai đọc ảnh rồi tưởng đó là đặc tả.

### 7.1 Pill ghi `REVIEW` cho màn hiện hai mặt — **theo BR**

Mode tên `browse` (BR-108). Pill hiển thị nhãn của `browse`, không phải `REVIEW`
— chữ ấy là tên cũ trước đợt đổi Review → Study.

### 7.2 Một phiên trộn thẻ mới và thẻ ôn — **theo BR-142**

Bỏ phần trộn. Dòng ngữ cảnh và bộ đếm chỉ nói về **tập của phiên đang chạy**:
phiên `learning` đếm thẻ mới, phiên `reviewing` đếm thẻ đến hạn. Không có màn nào
hiện `12 NEW · 11 REVIEW` cạnh nhau trong lúc học.

Đây là mục đắt nhất trong tám mục nếu đi hướng ngược lại — nó là chính luật chủ
dự án yêu cầu bắt buộc ở đợt brainstorm: *"App cần tạo môi trường học tùy ý user,
tùy theo năng lực user chứ không phải chạy đua số lượng card."*

### 7.3 `recall` không hiện đồng hồ — **theo BR-128, thêm vào design**

Mỗi lượt `recall` có 20 giây đo bằng thời gian tương tác. Ảnh không có chỗ nào
hiện thời gian, nên đây là chỗ **design phải thêm**, không phải bỏ luật.

Vị trí: chiếm chỗ bộ đếm `8 / 12` ở thanh trên khi mode là `recall`, vì hai thứ
này không cần cùng lúc — số thẻ còn lại đã có ở thanh tiến trình. Thời gian còn
lại phải đọc được bằng screen reader, không chỉ bằng màu (M5.16).

### 7.4 Icon bút chì và icon loa — **cả hai ra khỏi MVP**

- **Loa**: media hoãn có chủ đích (AD-03); `card_media` nằm ở mục "chưa mô hình
  hoá" của `data-model.md`. Quy tắc 1.
- **Bút chì**: sửa thẻ giữa phiên học **chưa luật nào nói** — lượt đang dở tính
  thế nào, thẻ đã đổi nội dung thì `back_folded` của lượt vừa chấm còn đúng
  không. Quy tắc 2: không tự đặt luật, để ngoài MVP.

Cả hai nên quay lại khi có BR cho chúng, không phải khi có chỗ trống trên thẻ.

### 7.5 Dòng mô tả phụ dưới mỗi lựa chọn `guess` — **ra khỏi MVP**

`cards` không có trường nào cho nghĩa mở rộng. Dùng tạm `hint` là sai mục đích —
`hint` là gợi ý cho `fill` (BR-136), và đem nó ra làm mô tả cho `guess` biến một
trường có nghĩa thành hai thứ khác nhau tuỳ màn.

Thêm trường mới là migration v6 và một BR mới. Quy tắc 2: mỗi lựa chọn chỉ hiện
nghĩa (`back`), như BR-121 và BR-123 mô tả.

### 7.6 Khái niệm "board" của `match` — **dùng round**

BR-115 và BR-117 chỉ có **round**. Nhãn hiện round: `ROUND 1 · 4 PAIRS LEFT`.

Nếu sau này muốn chia một round thành nhiều bàn nhỏ thì đó là một BR mới nói kích
thước bàn và cách chia — không phải một nhãn đổi chữ.

### 7.7 Vuốt phải để quay lại thẻ trước — **bỏ**

`cursor` chỉ tiến, và nó là nền của BR-26. Không luật nào cho xem lại thẻ đã qua,
và cho lùi sẽ mở ra câu hỏi lùi có đổi `cursor` không — tức một luật mới. Quy tắc
2. Dòng gợi ý dưới `browse` vì thế chỉ nói cách đi tiếp.

### 7.8 Hai họ màu — **giữ design**

Không BR nào nói về màu của mode, nên đây là quy tắc 3: thuần thị giác, giữ
nguyên. Mỗi mode một token màu; **màu không mang nghĩa nghiệp vụ** và không được
dùng làm cách duy nhất để phân biệt trạng thái (M5.16).

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
