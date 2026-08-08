# Wireframe · M5 Study modes

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt bố cục và hành vi của năm màn học trước khi viết code M5.7+ |
| **Scope** | Khung phiên học, và năm màn `browse` · `match` · `guess` · `recall` · `fill`. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng (`use-cases.md`), giá trị token (`design_system/tokens/`) |
| **Source of truth for** | Bố cục màn học · phán quyết cho tám điểm design lệch với BR |
| **Depends on** | `document-conventions.md`, `business-rules.md` (BR-108…BR-154), `wbs-study.md` (M5.7…M5.20) |
| **Updated by task** | M5.20 (state thứ hai của `recall` và `fill`) — thêm §6.1 |
| **Last updated** | 2026-08-08 |

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

### 7.7 Vuốt phải để quay lại thẻ trước — **bỏ**

`cursor` chỉ tiến, và nó là nền của BR-26. Không luật nào cho xem lại thẻ đã qua,
và cho lùi sẽ mở ra câu hỏi lùi có đổi `cursor` không — tức một luật mới. Quy tắc
2. Dòng gợi ý dưới `browse` vì thế chỉ nói cách đi tiếp.

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

Phần vuốt thẻ của spec không nằm ở đây: nó lật lại §7.7 nên có mục riêng.
