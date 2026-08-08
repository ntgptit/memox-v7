# Wireframe · M5 Study modes

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt bố cục và hành vi của năm màn học trước khi viết code M5.7+ |
| **Scope** | Khung phiên học, và năm màn `browse` · `match` · `guess` · `recall` · `fill`. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng (`use-cases.md`), giá trị token (`design_system/tokens/`) |
| **Source of truth for** | Bố cục màn học · phán quyết cho tám điểm design lệch với BR |
| **Depends on** | `document-conventions.md`, `business-rules.md` (BR-108…BR-154), `wbs-study.md` (M5.7…M5.20) |
| **Updated by task** | Màn `guess` theo handout layout — thêm §8.9 |
| **Last updated** | 2026-08-09 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID.

**Ảnh là UI concept, không phải đặc tả.** Chủ dự án đã chốt hai điều:

| Lấy từ ảnh | Lấy từ dự án |
|---|---|
| Bố cục và thứ bậc thị giác | Màu — `AppSemanticColors` và `ColorScheme` |
| Luồng thao tác của từng mode | Kiểu chữ — `context.texts` |
| Thành phần nào có mặt trên màn | Khoảng cách — `AppSpacing` |
| Trạng thái nào cần phân biệt | Component — `Mx*` trong `shared/widgets/` |

**Không dựng bảng màu hay theme mới.** Nếu một hiệu ứng trong ảnh không diễn
đạt được bằng token đang có thì đó là một quyết định về token — nêu ra, không
tự đẻ màu. Và nơi nào ảnh lệch với nghiệp vụ đã chốt thì nghiệp vụ thắng: §7
ghi phán quyết cho từng điểm. Dựng màn theo ảnh mà bỏ §7 là cách dựng lại đúng
những thứ đã bị bỏ.

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

> **Cập nhật sau spec layout của chủ dự án.** Ba điểm của khung đã đổi: dòng
> context nói **cỡ phiên** thay vì tên deck, nút ✕ hẹp lại còn 36 để thanh tiến
> trình có chỗ, và phiên học mở **ngoài** shell nên không còn thanh nav dưới.
> Chi tiết ở §8.3.

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

**Màu lấy từ token của dự án, không lấy từ ảnh.** Ảnh chia mode thành hai họ
màu; bộ token hiện có không có màu nào mang nghĩa "đây là mode nào" — xem §7.8
để biết vì sao chia như ảnh lại làm hỏng nghĩa của `success`.

## 3. Study · Review (`review_mode`)

Thân là **một thẻ duy nhất chiếm toàn bộ chiều cao**, chia đôi bằng một đường kẻ
mảnh:

- nửa trên: nhãn `KOREAN` (chữ nhỏ, hoa, mờ) ở góc trái; mặt trước căn giữa, cỡ
  lớn nhất màn hình.
- nửa dưới: nhãn `MEANING`; nghĩa căn giữa, cỡ vừa.

Không có nút nào, kể cả nút đi tiếp — khớp BR-111 và BR-155. Chuyển thẻ là **vuốt**;
một nút Next cạnh cử chỉ là cách thứ hai để làm đúng một việc mà cử chỉ đã làm,
trong khi ăn mất một dải màn hình vốn thuộc về thẻ — thứ duy nhất mode này có.
Đường cho screen reader là hai *custom semantics action* gắn trên chính vùng
vuốt, không vẽ gì ra màn.

Một chỗ ảnh không được làm theo: pill ghi `REVIEW`, trong khi mode tên `browse`
(§7.1). Vuốt để lùi thì **có** — xem lại, không ghi gì (BR-155, §7.7).

## 4. Study · Match (`match_mode`)

Lưới hai cột, mỗi hàng một cặp ô. Ba trạng thái ô:

| Trạng thái | Hình thức |
|---|---|
| chưa chọn | nền surface, viền mảnh |
| đang chọn (vế trước) | nền primary đặc, chữ trắng |
| vừa ghép đúng | nền xanh lá rất nhạt, chữ xanh lá, có ✓ — **một nhịp rồi tan** (§8.8) |
| vừa ghép sai | nền `error`, có ✕ — một nhịp rồi về idle (§8.8) |
| đã xong | ô rỗng, chỉ còn viền mờ (§8.8) |

Ô đã ghép **vẫn nằm nguyên chỗ** chứ không biến mất — khác với bản M5.4b hiện
tại, vốn xoá ô khỏi bàn.

Dòng ngữ cảnh trong ảnh ghi `BOARD 1 OF 3`. §7.6 từng bác vì "board" không có
trong BR — **nay có**: BR-156 chia một round thành các bàn năm cặp, nên nhãn ghi
cả hai: `ROUND 1 · BOARD 1/2 · 5 PAIRS LEFT`. Số cặp đếm là của **bàn**, vì thanh
header đã đo cả round rồi.

**Lưới lấp đầy chiều cao, cho tới khi không lấp được** — xem §8.6.

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

### 6.1 State thứ hai của `recall` và `fill` — **agent đề xuất, vẽ theo BR**

Tiêu đề khung của hai ảnh ghi `1/2`: mỗi màn còn một state chưa có ảnh. Hai bố
cục dưới đây **do agent đề xuất ở M5.20**, suy từ BR chứ không từ ảnh. Ghi ở đây
để người sau biết chúng chưa qua tay người thiết kế.

**`recall`, sau khi lật.** Vùng đáp án đổi từ tấm che sang chính mặt sau của
thẻ, và **không còn nút nào**:

- BR-129 cho đúng **một** kết cục mỗi lượt, BR-130 khoá nó — nên không có hành
  động nào còn hợp lệ để mời.
- Nhưng một màn có đáp án hiện ra và không nút nào trông **hệt như màn bị treo**.
  Nên chỗ nút cũ là một câu nói rõ lượt đã chốt và vòng sau bắt đầu lại đủ hai
  mươi giây (BR-133). Hết giờ thì câu ấy mở đầu bằng "Time's up" và dùng
  `danger`; tự lật thì dùng màu chữ phụ.
- Trước khi lật, vùng đáp án mang nhãn "đáp án đang ẩn". Một ô rỗng là **không
  có gì** với screen reader, còn "có đáp án ở đây và nó đang ẩn" là một sự thật
  về lượt học.

**`fill`, sau khi chấm.** Ô nhập đóng lại, và kết cục hiện bằng `success` hoặc
`danger`:

- Đóng ô nhập vì một câu trả lời thứ hai là một lượt thứ hai (BR-137, và cùng lý
  do với BR-126 ở `guess`).
- Sai thì hiện **mặt sau của thẻ**, không phải thứ người dùng đã gõ: BR-138 nói
  nội dung gõ vào không được lưu, và dội nó lại màn hình là cùng một dữ liệu chỉ
  đi theo hướng khác.
- Đúng thì **không** hiện dòng đáp án. Dòng đó tồn tại để nói cho người trượt
  biết họ thiếu gì; đưa cho người làm đúng thì nó đọc thành một lời đính chính.

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

### 7.7 Vuốt phải để quay lại thẻ trước — **đã dựng, BR-155**

*Trước đây mục này ghi "bỏ", với lý do `cursor` chỉ tiến. Chủ dự án đã lật lại
quyết định và yêu cầu dựng cả hai chiều; BR-155 được viết cho nó.*

Lý do cũ vẫn đúng và chính nó là hình dạng của luật mới: `cursor` **vẫn** chỉ
tiến. Lùi là **xem**, không phải trả lời — thẻ giữ nguyên `completed`, `cursor`
đứng yên, và tiến lại qua thẻ đó không ghi lượt thứ hai. Cái thay đổi không phải
queue mà là *thẻ nào đang được vẽ*.

Chỉ `browse` có thao tác này. Năm stage còn lại đều lấy câu trả lời từ thẻ đang
hiện, nên đặt một thẻ đã chấm lên đó là mời chấm lại (BR-126).

Ba điều màn hình phải làm:

- **Vuốt trái là tiến, vuốt phải là lùi**, ngưỡng 70dp; dưới ngưỡng thì thẻ trôi
  về chỗ cũ. Vuốt phải khi không còn gì phía sau cũng trôi về — cử chỉ đọc thành
  *bị từ chối*, không phải *không nghe thấy*.
- **Phải có đường không-cử-chỉ.** Một thao tác chỉ có bằng kéo ngang 70dp là
  không tồn tại với người dùng screen reader. Nút `Thẻ trước` hiện cạnh nút tiếp
  khi có vết phía sau, và **vắng mặt** khi không — nút disabled sẽ quảng cáo một
  chỗ không có cách nào tới.
- **Dòng gợi ý phải nói đang xem lại.** Bộ đếm và thanh tiến trình vẫn mô tả lượt
  đang mở, nên nếu không có câu này thì một thẻ đã qua trông như phiên tự lùi.

Thẻ **không** bị ném ra khỏi màn rồi mới đổi như trong design kit. Muốn ném thì
phải giữ thẻ cũ ở đâu đó trong lúc nó bay, và nếu bước đi bị từ chối thì thẻ nằm
ngoài màn không có gì kéo về. Trôi về chỗ cũ rồi để nội dung mới hiện ra tại chỗ
thì không bao giờ kẹt — mất cú ném, không mất cử chỉ. **Quyết định của agent.**

### 7.8 Hai họ màu — **bỏ, dùng token của dự án**

Ảnh cho `browse`/`match`/`guess` màu xanh dương và `recall`/`fill` màu xanh lá.
Bản trước của tài liệu này chốt "giữ design, mỗi mode một token màu". **Sai, và
chủ dự án đã chỉnh: chỉ lấy UI concept từ ảnh; màu, theme và token dùng của dự
án.**

Có một lý do kỹ thuật mạnh hơn cả yêu cầu ấy. Bộ token hiện có —
`AppSemanticColors` — không có màu nào nghĩa là "mode này là mode nào". Màu xanh
lá gần nhất là `success`, và nó có nghĩa **đúng**. Đem `success` làm màu nhận
dạng cho `recall` thì pill của mode trông như một phán quyết: người dùng thấy màu
"đúng" trước cả khi trả lời, và ở `match`/`guess` — nơi `success` thật sự đánh
dấu ô ghép đúng — cùng một màu sẽ mang hai nghĩa trên cùng một màn.

Nên:

- pill mode và thanh tiến trình dùng **một** accent chung: `primaryAccent` với
  `progressTrack`/`progressFill`. Mode phân biệt bằng **chữ trên pill**, không
  bằng màu.
- `success` và `danger` giữ đúng nghĩa: đúng và sai. Chỉ dùng cho kết quả một
  lượt, không dùng cho nhận dạng mode.
- Nếu sau này muốn màu riêng cho từng mode thì đó là một quyết định về token —
  thêm vào `AppSemanticColors` kèm lý do, không đặt màu thẳng trong widget.

Cái *concept* của ảnh vẫn giữ: có pill tên mode, có thanh tiến trình, trạng thái
đúng/sai phân biệt được. Chỉ giá trị màu là của dự án.

## 8. Spec layout của design kit cho Study · Review — **đối chiếu với token**

Chủ dự án đưa một spec layout viết bằng JS của một design kit **khác** repo này
(khung 390×780, kèm số đo cho từng thành phần). Mục này ghi lại từng con số của
spec đã đi về đâu, vì phần lớn chúng **đã có sẵn trong token** và phần còn lại
thì không đáng đổi lấy cái giá phải trả.

Nguyên tắc chủ dự án chốt khi duyệt: *thêm token nếu giá trị thực sự thiếu; còn
số lẻ thì làm tròn về thang đang có.* Mục 8.2 áp dụng đúng nguyên tắc ấy cho hai
trường hợp mà giá phải trả chỉ lộ ra sau khi đọc code.

### 8.1 Đã làm theo

| Spec | Trong code |
|---|---|
| Thẻ chiếm hết chiều cao, `Expanded` / `Divider` / `Expanded` | đúng như vậy — xem §3 |
| Thẻ `padding: 0`, mỗi nửa tự pad | thẻ pad **hai bên** `AppSpacing.lg`, mỗi nửa pad trên–dưới |
| Nửa trên `20/16/8`, nửa dưới `8/16/20` | `lg/–/sm` và `sm/–/lg` (16 và 8) |
| Đường kẻ 1px, lề hai bên | `AppStroke.hairline`, `borderSubtle`, chạy hết bề ngang trong lề |
| Nghĩa 24 / w600 | `headlineSmall` — trùng khít, trước đây là `titleLarge` (22) |
| Overline nhỏ, hoa, mờ, góc trái | `labelSmall` + `AppTypography.sectionLabelTracking` |
| Gutter màn hình 14 | `AppSpacing.lg` = 16 (làm tròn), vốn đã đúng từ trước |

Cái **đường kẻ chạm được hai mép thẻ** là điểm ăn thua của nhóm này. Trước đây
thẻ pad đều 24 mọi phía, nên đường kẻ hụt 24 mỗi đầu và hai nửa đọc thành *hai
thẻ xếp chồng* chứ không phải hai mặt của một thẻ. Có test đo bề ngang đường kẻ.

### 8.2 Không làm theo, và giá phải trả nếu làm

| Spec | Vì sao không |
|---|---|
| Thuật ngữ cỡ **32** | `headlineMedium` = `AppTypography.cardPromptSize` = 30, và doc của chính token gọi nó là *"the card prompt"*. Nó còn có `compactCardPromptSize` = 26 cho màn dưới breakpoint, kèm lý do đo được: 30 đã đẩy prompt hai chữ xuống ba dòng ở 320. Đổi 30→32 phải sửa thang chữ, web kit và `css_scale_parity_test` — cho 2px |
| Chữ đậm **w700** | Cả hai họ chữ đều là **variable font**. Doc của `AppTypography` ghi rõ `fontWeight` một mình không kéo trục `wght` — phải kèm `fontVariations`. `copyWith(fontWeight:)` tại chỗ dùng vì thế là một thay đổi **không có tác dụng** trên một số renderer |
| Bo góc thẻ **20**, **bỏ viền** | `MxCard` là component dùng chung, bo `AppRadius.lg` ở bốn chỗ (viền, clip, ink, focus ring), và có bản song sinh `.mx-card` bên `design_system/`. Thêm `AppRadius.xl` rồi thêm tham số cho `MxCard` + `--radius-xl` + modifier bên web — cho 4px, ở đúng một màn |
| Icon ✕ cỡ **20**, nút **36** | `MxIconButton` cũng dùng chung, cố định `AppIconSize.md` và 48×48. Cùng một cái giá như trên |
| Thanh tiến trình cao **4** | `MxProgressBarSize.sm` = 6, và comment tại chỗ ghi lý do đã thử 4: *"At 4 the figure sat on the track"* |
| Dòng context viết **HOA** | Dòng đó chứa **tên deck** — nội dung người dùng nhập. Viết hoa nội dung của người dùng là sửa dữ liệu của họ để lấy hình thức |
| `12 NEW · 11 REVIEW` và bộ đếm trộn hai tập | BR-142 cấm trộn thẻ mới với thẻ ôn trong một phiên; §7.2 đã chốt |
| Pill mode dùng `primary` trên `primary @10%` | §7.8 đã chốt `primaryAccent` trên `surfaceMuted` |

Ba dòng đầu là **quyết định của agent**, chủ dự án đã duyệt nguyên tắc chứ chưa
duyệt từng dòng. Điểm chung của cả ba: con số của spec chỉ lệch vài pixel, nhưng
để đạt nó phải cho một component **dùng chung** mọc thêm biến thể chỉ phục vụ một
màn — đúng cái điều mà test `design_tokens_test.dart` gọi tên là *"a seventh
constant added quietly, off-scale, for one screen"*. Nếu sau này muốn khớp mock
đến từng pixel thì đó là một quyết định về **design system**, làm cho cả hai kit
cùng lúc, không phải một sửa đổi của màn Study.

Phần vuốt thẻ của spec nằm ở §7.7, vì nó lật lại một quyết định cũ.

### 8.3 Khung phiên học, sau phản hồi trên ảnh chụp

Bốn điểm chủ dự án chỉ ra trên ảnh chạy thật, và cái gì đã đổi:

**Dòng context `Living room · Learning` không nói gì.** Deck đã được chọn từ hai
màn trước, còn chữ *Learning* lặp lại đúng cái pill bên cạnh — cộng lại chúng
không cho người học điều gì để hành động. Nay dòng ấy nói **cỡ của phiên**:
`12 THẺ MỚI` hoặc `12 THẺ ĐẾN HẠN`. Đó chính là con số thanh tiến trình đang đo.

Vẫn **một tập, không bao giờ hai**: `12 NEW · 11 REVIEW` của design không dựng
được, vì BR-142 cho một phiên đúng một trong hai tập — in cả hai là mô tả hai
phiên. Viết HOA ở đây an toàn, khác với tên deck: không có gì trong dòng này là
nội dung người dùng gõ vào.

**Thanh tiến trình quá ngắn — và nguyên nhân không phải cỡ icon.** Đo ở khung 393
rộng: thanh chỉ **108px**, và có **118px chết** sau bộ đếm. `Flexible` mặc định
`flex: 1`, nên pill và bộ đếm mỗi cái được *cấp* một phần ba khoảng trống, dùng
đúng phần chúng cần, và phần thừa dồn xuống cuối hàng. Đặt `flex: 0` cho cả hai
thì `Expanded` của thanh lấy hết phần còn lại: **226px**, hàng không còn chỗ chết.
Có test đo, vì không phép kiểm nào về chữ nhìn thấy được lỗi này.

Nút ✕ cũng hẹp lại còn **36** theo spec, và chỉ nhường **chiều ngang** — nó giữ
nguyên 48 chiều cao, nên ngón tay vẫn có cả thanh để chạm. *(Ràng buộc 36 này
không có tác dụng thật, và đã bị gỡ — xem §8.4 và §8.5.)*

**Nút Next đã bỏ** — xem §3 và BR-155.

**Phiên học mở ngoài shell.** Trước đây nó push trên navigator của nhánh nên giữ
thanh nav dưới, tức là có hai đường ra khỏi một phiên mà BR-82 nói chỉ có một:
nút ✕, đóng phiên thành `abandoned`/`user_exit`. Đổi tab để nguyên phiên đang mở,
và lần sau app mời resume đúng cái người dùng tưởng đã bỏ.

### 8.4 Thanh trên lệch tâm và dòng gợi ý, sau lần đo thứ hai

**Ràng buộc 36 của nút ✕ chưa bao giờ có tác dụng.** Đo ở khung 393: hộp nút vẫn
là **48×48**. `MaterialTapTargetSize.padded` bơm hộp 36 trở lại 48 rồi căn giữa
cái 36 bên trong, nên hàng vẫn tiêu 48 *và* glyph ✕ nằm lùi vào **14px** so với
chỗ nút bắt đầu. Đầu kia của hàng — bộ đếm `3 / 10` — lại kết thúc đúng mép
gutter. Hai đầu lùi vào không bằng nhau chính là cái đọc ra thành "thanh header
bị lệch, chưa nằm ở trung tâm": phần nhìn thấy được của hàng có tâm ở 203.5
trong khi cột nội dung có tâm ở 196.5.

Nay `isCompact` **không đụng vào vùng chạm nữa, chỉ dời glyph**: giữ nguyên
48×48, `alignment: AlignmentDirectional.centerStart` kéo glyph ra sát mép. Đo
lại: glyph bắt đầu ở **16**, bộ đếm kết thúc ở **377**, tâm hàng **196.5** —
đúng tâm cột nội dung. Khoảng `xs` sau nút cũng bỏ, vì hộp nút đã tự chừa 28px
trống phía sau glyph. Thanh tiến trình được thêm 4px: **198**.

**Dòng gợi ý: căn giữa, nhỏ hơn một bậc, và icon theo mode.** Trước đây nó căn
trái ở cỡ `bodyMedium` với `Expanded`, tức là chiếm hết bề ngang và đọc ra như
một đoạn nội dung thẻ bị tràn xuống. Ảnh wireframe vẽ nó là một dòng chú thích
căn giữa — đo trên ảnh ra ~12px, tức `bodySmall`. Dựng theo ảnh: `Row` căn giữa,
`Flexible` thay `Expanded` (Expanded sẽ đẩy icon về lại lề trái), chữ
`textAlign: center`. Đo lại ở 393: cụm icon + chữ rộng 234, tâm **196.5**.

Icon **không còn dùng chung một glyph**. Bốn mode có câu gợi ý mô tả thao tác
trên chính thẻ đang hiện thì giữ dấu ✓ — đúng như `match_mode`, `guess_mode`,
`recall_mode` vẽ, và đổi `check_circle_outline` thành `check` cho khớp ảnh.
`browse` là ngoại lệ: câu của nó nói về việc **đi giữa các thẻ**, và ảnh
`review_mode` vẽ dấu `»` chứ không phải ✓ — một dấu ✓ cạnh "swipe left for next"
đọc ra như một phán quyết về thẻ thay vì một hướng để đi. Bảng tra theo enum ở
`studyModeHintIcon`, không thêm `switch` thứ hai trong `presentation/` (AD-18).

**Câu của `browse` rút ngắn theo ảnh**: `Swipe left for next, right to go back`.
Bản dài cũ tràn hai dòng khi hạ xuống cỡ chú thích. BR-155 vẫn đúng — vuốt phải
là *xem lại*, không ghi gì; `studyBrowseLookingBack` là dòng nói rõ điều đó khi
người dùng đang thật sự nhìn lại.

### 8.5 Thanh trên tách thành `MxSessionTopBar`, và chip sát lại nút ✕

Lần sửa ở §8.4 kéo glyph ✕ ra sát mép gutter, và **làm khoảng cách ✕ → chip
rộng gấp đôi**: 14px thành 28px. Vùng chạm 48×48 là nguyên nhân, đúng như chủ
dự án đoán — glyph 20px nằm sát mép trái của hộp 48 thì 28px còn lại của hộp
nằm chết giữa nó và chip.

**Không thu hộp lại được.** 48 là `AppSpacing.minimumTouchTarget`, và
`study_accessibility_test.dart` khẳng định `androidTapTargetGuideline`. Mọi
cách "vẽ tràn ra ngoài ô" — `Transform`, `OverflowBox` — đều mất phần chạm nằm
ngoài ô, vì hit test của Flutter bị chặn bởi kích thước ô cha; vùng chạm co lại
mà `Semantics` vẫn khai 48×48, tức là hỏng *im lặng*.

Cách đúng là cách `AppBar` đặt icon leading của nó: **thanh trên chạy sát mép
màn hình**, nút hở vào gutter, glyph rơi *đúng* lên gutter. Màn truyền
`padding: EdgeInsets.zero` cho `MxContentShell`; khung tự đặt gutter cho dòng
ngữ cảnh, thân và dòng gợi ý bằng `mxScreenGutter` (public hoá từ
`_defaultPadding`, để 320 vẫn ra 12 chứ không phải 16 chép tay).

Đo lại ở 393, so với ảnh mẫu (đo trên chính file PNG, neo theo mép trái thẻ và
mép phải bộ đếm, tỉ lệ 1.335):

| | ảnh mẫu | trước | sau |
|---|---|---|---|
| glyph ✕ | 20.5…33.2 | 16…36 | **16…36** |
| mặt chip bắt đầu | 54.9 | 64 | **50** |
| khoảng ✕ → chip | 21.7 | 28 | **14** |
| thanh tiến trình | 201.5 | 206 | **188** |
| bộ đếm kết thúc | 377 | 377 | **353** |

**Hai đầu của thanh không dùng chung một giá trị, và đó là kết luận sau bốn
vòng review.** Thử cho cả hai bằng nhau rồi: nút ✕ đọc ra thành bị đẩy sâu vào
trong màn. Một *control* thì neo ở mép nó đóng — `AppBar` đặt icon leading của nó
đúng như vậy — còn một *nhãn* thì nằm trong. Cái **không** được phép là chiều
ngược lại: glyph thụt vào trong khi bộ đếm sát mép, vì hàng có control bị chôn và
chữ đang rơi khỏi mép thì đọc ra là hỏng chứ không phải là có bố cục. Đó chính là
thứ vòng review đầu tiên báo.

Nên có hai hàm chứ không một hằng:

- `_leadingInset` = **gutter**. Glyph ✕ rơi lên 16 (320: 14 — xem dưới).
- `_trailingInset` = **gutter + `xl`**. Hộp bộ đếm hết ở 353, tức lùi 24 so với
  mép thẻ và vượt qua cả cột chữ của thẻ (`TERM`/`MEANING` ở 32). Sâu như vậy vì
  ở mép không có gì để đứng lên: mép thẻ full-bleed chỉ **1.38:1** so với nền
  trang ở light, ruột thẻ **1.06:1** — bộ đếm từng được đo *sát khít* mép ấy,
  đúng từng pixel, mà vẫn bị báo là vượt ra ngoài, hai lần. Tránh hẳn ra là thứ
  chấm dứt câu hỏi.

**Clamp ở 0 là bắt buộc, không phải phòng xa.** Gutter compact là 12 còn glyph
nằm sau hộp nó 14, nên start đúng phải là −2; `Padding` assert với inset âm, và
nó hạ **năm** test ở 320 ngay khoảnh khắc hai đầu thôi dùng chung giá trị. Bị
clamp thì glyph rơi lên 14 thay vì 12 — hai pixel mà compact scale chịu được, đổi
lại thanh dựng được ở đó.

Giá phải trả: thanh tiến trình 206 → **188**. Và ở 320 @ textScale 2.0 hàng từng
hụt 5.9px, nên mức chặn chip đổi từ *2/5 bề rộng thanh* sang **2/5 phần còn lại
sau nút và hai khoảng `sm`**: 64 đó là cố định, chiếm 1/5 hàng ở 393 nhưng 1/4 ở
278, nên đo theo cả hàng là âm thầm hứa cho chip *nhiều* hơn đúng lúc nó phải
nhường.

**Không có spacer nào giữa nút ✕ và chip, và đó là cách khép khoảng cách chứ
không phải thu nút.** Khoảng trống mắt nhìn thấy không phải spacing: nút căn
giữa glyph 20px trong hộp 48px, nên `_kGlyphInset` = 14 của chính hộp nó đã nằm
sau glyph rồi. Thêm một `sm` lên trên thành 22; bỏ hẳn thì mặt chip rơi đúng
**54**, tức chỗ ảnh mẫu đặt nó (54.9). 14 còn lại **là vùng chạm**, không phải
không khí.

Thu nút là cách còn lại, và nó tốn đúng 48×48 mà `androidTapTargetGuideline`
khẳng định ở cả `study_accessibility_test.dart` lẫn stress suite. Tệ hơn: các mẹo
quen tay để thu — `Transform`, `OverflowBox` — cắt **vùng hit** theo ô cha trong
khi `Semantics` vẫn khai 48×48, nên gate vẫn xanh và chỉ ngón tay người dùng biết
là hỏng.

**Hai đầu thanh lùi vào một `xs` so với gutter, không nằm trên gutter.** Chủ dự
án báo bộ đếm "vượt mép" hai lần, trong khi đo từng cột pixel thì hộp chữ và hộp
thẻ **kết thúc đúng cùng 377**, và mực của số `0` còn dừng trước mực viền thẻ
1px. Cái sai không phải toạ độ mà là thứ để gióng: viền thẻ chỉ **1.38:1** so với
nền trang ở light (ruột thẻ 1.06:1), trong khi glyph ✕ và bộ đếm đậm hơn hẳn. Một
nét nặng đặt *đúng* lên một nét mờ thì đọc ra thành đè lên nó. `_opticalInset` =
gutter + `sm` là câu trả lời (`xs` là lần thử đầu, vẫn còn chật), và **cả hai đầu
cùng lùi bằng một giá trị**: chỉ lùi bộ đếm sẽ kéo tâm hàng lệch đi một nửa
lượng lùi so với tâm cột nội dung — đúng cái lỗi đầu tiên đã sửa. Một hằng, đặt
ở hai đầu, là thứ khiến hai bên không thể trôi khỏi nhau.

**Thanh trên nay là `MxSessionTopBar` trong `lib/shared/widgets/`.** Nó vốn đã
dùng chung cho cả năm mode — khung phiên học chỉ có một — nhưng nằm `private`
trong feature nên màn toàn-màn-hình tiếp theo sẽ phải dựng lại nó. Component
không biết `StudyMode` là gì: nhận một *chữ* cho chip, một `0…1` cho thanh, và
một widget cho ô cuối (bộ đếm, hoặc đồng hồ của `recall`). Chỉ có chip đổi giữa
năm mode, đúng như yêu cầu.

**Một lỗi tràn có thật lộ ra khi làm việc này.** Test 320×568 @ textScale 2.0
trước đây dựng khung ở **nguyên 320** vì harness không có shell, trong khi
production chỉ có 296 — nên nó chưa bao giờ đo đúng thứ đang chạy. Nay khung tự
đặt gutter, test và production khớp nhau, và hàng tràn 7.5px với tên mode dài.
Chip vì thế bị chặn bởi `_kChipMaxWidthFraction` (2/5 bề rộng thanh): ở mọi khổ
bình thường mức chặn rộng hơn chữ nên không đổi gì, ở 320 @ 2.0 nó là thứ nhường
lại chỗ thay vì tràn. Bộ đếm **không** bị chặn — nó là con số, và một con số bị
cắt là một con số sai.

### 8.6 Bàn ghép của `match`, theo handout layout 390×780

Handout dựng lưới **2 cột × 5 hàng**, `gap 8` hai chiều, mọi ô bằng nhau, ô cao
`(605 − 4×8)/5 ≈ 113` và ghi rõ *đừng hard-code, để nó flex*. Đã dựng đúng vậy:
`Column` gồm N hàng `Expanded`, mỗi hàng là `Row` hai `Expanded`. Đo ở 390×780:
bàn **358 × 628** ở `16…374 / 104…732`, ô **175 × 119.2**, bước hàng 127.2 =
119.2 + 8. Không còn dải trống dưới ô cuối.

**Năm hàng là nội dung của mock, không phải luật.** Bàn giữ **cả round**
(BR-115) và BR-153 chỉ đặt sàn hai cặp — nên mười thẻ là bàn mười hàng, hai thẻ
là bàn hai hàng. Hàng lúc nào cũng flex thì ca đầu cho ô cao 48 ở textScale 2.0
và ca sau cho hai tấm 300px. Vì vậy flex **có sàn**: `AppMatchTile.minRowHeight`
= `minimumTouchTarget`, nhân theo textScaler — một ô là *control* trước khi là
layout — và bàn không đạt sàn thì **cuộn** thay vì lấp. Mọi bàn vừa vẫn lấp
chính xác, tức là mọi bàn mock nói tới.

Ba trạng thái ô theo handout, dịch sang token của dự án:

| handout | dự án |
|---|---|
| `mastery` | `AppSemanticColors.success` — `card_state_widget.dart` đã sơn `CardState.mastered` bằng nó, hai tên là một token |
| nền matched `mastery @12%`, viền `@30%` | `Color.alphaBlend` trên `surfaceContainerLowest`, **không** vẽ trong suốt |
| radius 12 · gap 8 · transition 200ms `cubic-bezier(0.2,0,0,1)` | `AppRadius.md` · `AppSpacing.sm` · `AppDurations.normal` + `AppDurations.standard` — trùng khít, không thêm token |
| front 18/w700, back 14/w600 | `titleMedium` (16/w600) và `titleSmall` (14/w600) — thang chữ không có 18 |
| icon ✓ đứng **trước** chữ, gap 6 | đúng ảnh mẫu; gap = `AppSpacing.xs` |

**Nền matched phải blend, không được vẽ trong suốt.** `color_source_rules_test`
R7 cấm fill/border translucent: nó composite với thứ đằng sau lúc paint, nên một
token ra hai giá trị trên hai mặt nền. `Color.alphaBlend` chốt màu lúc build,
trên đúng mặt nền ô đang nằm. Đây cũng là lý do bản M5.19 từng **từ chối** nền
xanh nhạt và ghi "không có token" — có cách, chỉ là không phải cách trong suốt.

### 8.7 Ba điểm của handout không làm theo, và vì sao

| handout | dự án giữ | lý do |
|---|---|---|
| gutter **14** | **16** (12 ở compact) | 14 không có trong `AppSpacing`. README ảnh wireframe đã chốt: bố cục lấy từ ảnh, **khoảng cách lấy từ dự án** |
| nút ✕ **36×36** | **48×48** | `AppSpacing.minimumTouchTarget`; `androidTapTargetGuideline` khẳng định ở `study_accessibility_test.dart` và stress suite. §8.5 ghi đầy đủ |
| thanh tiến trình cao **4** | **6** (`MxProgressBarSize.sm`) | đã đo và chốt: ở 4 nó đọc thành sợi tóc chứ không phải một phép đo, và trên thẻ deck nó còn ăn sâu vào góc bo hơn |
| chip nền `accent @10%` | `surfaceMuted` + `primaryAccent` | §7.8 và bảng §8.2 đã bác đúng điểm này |
| bộ đếm `paddingRight 10` | `_trailingInset` = gutter + `xl` | §8.5, sau bốn vòng review |

Cái **có** làm theo từ phần chrome của handout: chip viết HOA kèm letter-spacing
(§2 cũng đã ghi "pill chữ hoa"), và icon dòng gợi ý lên `AppIconSize.sm` = 16.

Nhân đó sửa một lỗi thật: dòng ngữ cảnh ghép từ hai chuỗi mà chỉ một chuỗi viết
hoa, nên `match` in ra `5 CARDS DUE · Round 1 · 4 pairs left` — một câu đeo nửa
cái nhãn. Nay viết hoa **ở chỗ ghép**, để ARB giữ chữ chứ không giữ kiểu.

### 8.8 Phản hồi đúng/sai của `match`

Chủ dự án nêu hai ý, và **cả hai đều đúng chỗ đau**:

1. sai thì hiện **không có phản hồi nào** — chọn sai chỉ xoá lựa chọn, nhìn hệt
   như bấm hụt;
2. ô đã ghép giữ màu xanh tới hết round là **rác thị giác** — ba trạng thái
   (idle, selected, matched) cùng tồn tại, mà cái thứ ba là việc đã xong.

§4 từng chốt "ô ở nguyên chỗ", và lý do của nó là **reflow**, không phải là màu:
bỏ ô thì hàng dưới dồn lên, và từ khi lưới lấp đầy chiều cao (§8.6) thì mọi ô
còn lại còn phình to. Đề xuất của chủ dự án bỏ đúng cái đó ra — *biến mất nhưng
không dồn* — nên §4 giữ nguyên tinh thần, chỉ đổi cách thực hiện:

| | làm gì |
|---|---|
| đúng | ô sang `success` + ✓ trong `AppMatchTile.successFlash`, rồi **nội dung tan**, ô ở lại rỗng |
| ô rỗng | không vẽ nền (thủng thật), viền `borderSubtle` pha 45% trên nền trang |
| sai | **cả hai** ô sang `error` + ✕ trong `AppMatchTile.wrongHold`, rồi tự về idle |
| cả hai | không khoá thao tác — chạm term kế tiếp cắt màu đỏ ngay |

Cái ô rỗng còn làm được một việc nữa: nó là **bằng chứng tiến độ**. Nhìn bàn là
biết còn mấy cặp, không cần đọc dòng ngữ cảnh, và không tốn một màu nào.

**800ms của đề xuất ban đầu không dựng.** `AppDurations.slow = 320` được ghi là
*trần* của mọi chuyển động trong app, lý do: trong phiên học người ta đang trả
lời chứ không đang xem. Bàn năm cặp sai bốn lần ở 800ms là **3.2 giây chết**,
chồng lên thời gian khoá sẵn có trong lúc ghi DB. Chốt 320ms, và bù độ rõ bằng
việc giữ màu **trên cả hai ô** thay vì bằng thời gian.

**Không đánh dấu bằng riêng màu.** ✓ và ✕ đi kèm, và cả hai trạng thái có
`Semantics` value — `studyMatchPaired` và `studyMatchWrong`. WCAG 1.4.1. Ô rỗng
**vẫn** announce là đã ghép, nếu không thì screen reader mất luôn cặp đó khỏi bàn.

Sai tô đỏ **cả hai** ô vì cái *ghép* mới sai, không phải một ô nào sai. BR-118
vẫn chấm mình thẻ của term — đó là thứ được ghi lại, khác với thứ được nói ra.

**Hai lỗi chỉ render mới thấy, không phép kiểm nào bắt được:**

- ô rỗng vẽ bằng `scheme.surface` ra **sáng hơn** nền trang. Đo ở dark: trang là
  `(10, 8, 45)`, `surface` là `(26, 24, 56)`, còn nền ô là `surfaceContainerLowest`
  = `(10, 3, 38)`. Một cái lỗ sáng hơn xung quanh thì đọc thành ô mới chứ không
  phải ô đã xoá. Nay không vẽ nền gì cả, viền pha trên `scaffoldBackgroundColor`.
- nhịp xanh đặt bằng `AppDurations.normal`, **đúng bằng** thời gian chuyển màu của
  chính ô đó — nên suốt nhịp ấy ô chỉ đang *đi tới* xanh rồi quay đầu ngay: một
  vệt tím, xanh không hiện ra lần nào. Nhịp phải dài hơn chuyển màu; `slow` cho
  120ms màu đã đứng yên.

### 8.9 Màn `guess` theo handout layout 390×780

Handout của `guess` **không đụng vào phán quyết nào** — §7.5 đã chốt mỗi lựa chọn
chỉ hiện nghĩa, và handout cũng viết đúng thế ("meaning only, nothing else").
Nên dựng nguyên.

**Thẻ đề là `Expanded`, không phải chiều cao cố định** — handout gọi đích danh
đây là bug làm tràn lựa chọn. Năm hàng là chiều cao biết trước; thuật ngữ thì
không, vì nó có thể một từ hoặc bốn từ. Đặt sàn `AppGuessPrompt.cardMinHeight` =
180 rồi để thẻ ăn phần còn lại.

Thẻ thêm một dòng overline `WHAT IS THIS?` — thuật ngữ nằm một mình trên thẻ là
một từ không kèm câu hỏi, còn chip `GUESS` ở thanh trên chỉ gọi tên bài tập chứ
không gọi tên việc phải làm. Cùng dáng với dòng ngữ cảnh: nhỏ, hoa, giãn chữ, mờ.

Bốn trạng thái hàng, dịch sang token:

| handout | dự án |
|---|---|
| correct `mastery` @14% nền, @40% viền | `success` qua `Color.alphaBlend`, R7 |
| wrong `danger` @10% nền, @35% viền, chữ `error` | `danger` — trong app này `error` **là** `danger` |
| faded opacity 0.36 | đúng 0.36 (trước là 0.5) |
| badge 28, viền 1.5, opacity 0.85 | `AppStroke.input` = 1.5 |
| chữ 16/w500 | `titleMedium` (16/w600) — thang chữ không có w500, đẻ một weight cho một hàng là đúng thứ `app_typography.dart` sinh ra để chặn |
| min-height 50 | `minimumTouchTarget` = 48 — sàn của một control là con số dự án đã có |
| icon verdict 18 | `AppIconSize.sm` = 16 |
| transition 200ms `cubic-bezier(0.2,0,0,1)` | `AppDurations.normal` + `standard`, qua `AppMotionPolicy` |

**Nền có tô, không chỉ viền.** Handout đúng ở chỗ này: chỉ viền thì màn đã trả
lời đọc ra thành năm hàng cùng trọng lượng với hai cái mép có màu, mắt phải đi
tìm cái nào là cái nào.

**Còn thiếu, có chủ đích:** handout ghi dòng gợi ý sau khi trả lời là
`Answer shown — the correct option is highlighted`, tức `guess` có **hai** dòng
gợi ý. Cờ "đã trả lời" hiện nằm trong state của section, chưa tới được khung.
`recall` và `fill` cũng cần đúng cơ chế ấy (ẩn/hiện, nhập/sai), nên nối một lần
cùng hai màn đó thay vì ba lần rời.
