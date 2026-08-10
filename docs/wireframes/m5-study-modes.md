# Wireframe · M5 Study modes

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt bố cục và hành vi của năm màn học trước khi viết code M5.7+ |
| **Scope** | Khung phiên học, và năm màn `browse` · `match` · `guess` · `recall` · `fill`. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md`), luồng (`use-cases.md`), giá trị token (`design_system/tokens/`) |
| **Source of truth for** | Bố cục màn học · phán quyết cho tám điểm design lệch với BR |
| **Depends on** | `document-conventions.md`, `business-rules.md` (BR-108…BR-154), `wbs-study.md` (M5.7…M5.20) |
| **Updated by task** | Rà soát UI 5 stage — `match` nhận cả hai chiều chọn và giữ trạng thái đủ lâu để đọc (§4, §8.8), chuyển feedback sang viền + chữ thay vì nền đặc (§4), đổi meaning sang trái, hạ thang chữ và nâng sàn hàng lên 112 (§4, §8.6), `guess` bỏ huy hiệu A–E (§5), `fill` làm lại vùng đáp án (§6), `browse` cân bằng hai mặt và đổi nhãn (§3) |
| **Last updated** | 2026-08-10 |

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

- nửa trên: nhãn `FRONT` (chữ nhỏ, hoa, mờ) ở góc trái; mặt trước căn giữa.
- nửa dưới: nhãn `BACK`; mặt sau căn giữa, **cùng cỡ với nửa trên**.

**Nhãn gọi tên cột, không gọi tên nội dung.** Ảnh ghi `KOREAN`/`MEANING`; không
deck hay card nào mang ngôn ngữ, và `front` cũng không đảm bảo là thuật ngữ —
một bộ thẻ hoàn toàn có thể để nghĩa ở mặt trước và từ ở mặt sau, lúc đó cặp
`Thuật ngữ`/`Ý nghĩa` dán sai nhãn cho cả hai nửa.

**Mặt trước là tiêu điểm, mặt sau giải thích nó** —
`StudyFaceEmphasis.backSupportingFront`. Front dùng `titleLarge` hạ w500 bằng
`AppTypography.withWeight`; back dùng `bodyLarge`.

**BR-08 quyết định chiều này, và nó đã quyết từ trước khi widget tồn tại.** Mặt
trước trần 60 ký tự vì nó là prompt điện thoại vẽ trên một dòng; mặt sau trần
240 vì *"một nghĩa chứa nhiều hơn một từ — hai ngôn ngữ, ngăn bằng dấu phẩy"*.
Front giữ từ vựng, back giữ nghĩa tiếng mẹ đẻ.

**Hai lần trước đi vòng mới tới đây, và cả hai cùng một nguyên nhân.** Lần đầu
cho front vai prompt, một nghĩa thật nuốt cả thẻ; lần hai gọi hai mặt là
"peers", chữa được cái đó và để lại hai khối bằng nhau không nói gì về chỗ cần
nhìn. Cả hai đều suy luận từ một fixture có front dài **67 ký tự** — dữ liệu
BR-08 cấm và app từ chối lưu. Render của một thẻ không thể tồn tại còn tệ hơn
không có render.

`self_assess` không đổi: mặt trước **là** câu hỏi cho tới khi lật, nên nó giữ
vai prompt lớn hơn. Khác biệt đi qua một tham số có tên chứ không suy ra từ cờ
"có hiện mặt sau ngay không".

Không có nút nào, kể cả nút đi tiếp — khớp BR-111 và BR-155. Chuyển thẻ là **vuốt**;
một nút Next cạnh cử chỉ là cách thứ hai để làm đúng một việc mà cử chỉ đã làm,
trong khi ăn mất một dải màn hình vốn thuộc về thẻ — thứ duy nhất mode này có.
Đường cho screen reader là hai *custom semantics action* gắn trên chính vùng
vuốt, không vẽ gì ra màn.

Một chỗ ảnh không được làm theo: pill ghi `REVIEW`, trong khi mode tên `browse`
(§7.1). Vuốt để lùi thì **có** — xem lại, không ghi gì (BR-155, §7.7).

## 4. Study · Match (`match_mode`)

Lưới hai cột. **Một hàng là hai ô cùng chỉ số, không phải một cặp** — hai cột
là hai hoán vị độc lập (BR-127), nên hai ô cạnh nhau gần như không bao giờ thuộc
cùng một thẻ. Năm trạng thái ô:

**Trạng thái đổi viền và chữ, không đổi nền.** Cả năm đều ngồi trên đúng
`surfaceContainerLowest` của ô idle; chỉ `cleared` là ngoại lệ và nó không vẽ
nền nào cả.

| Trạng thái | Nền | Viền | Độ dày | Chữ / icon |
|---|---|---|---|---|
| chưa chọn | `surfaceContainerLowest` | `borderControl` | `AppStroke.hairline` | `onSurface` |
| đang chọn (vế trước) | *không đổi* | `primaryAccent` | `AppStroke.input` | `primaryAccent` |
| vừa ghép đúng | *không đổi* | `success` | `AppStroke.input` | `success` + ✓ — giữ **500ms** rồi tan (§8.8) |
| vừa ghép sai | *không đổi* | `danger` | `AppStroke.input` | `danger` + ✕ — giữ **700ms** rồi về idle (§8.8) |
| đã xong | **không vẽ** | viền cleared mờ | `AppStroke.hairline` | nội dung tan (§8.8) |

**Tô kín ô là thứ làm bàn rối.** Mỗi lượt chạm **hai** ô, nên một trạng thái đặc
tự nhân đôi diện tích của nó; trên bàn mười slot đó là một phần năm màn hình đổi
màu cùng lúc, và một nghĩa sáu dòng dưới nền `error` đặc thôi đọc như một câu và
thành một panel cảnh báo. Thông tin chưa bao giờ nằm ở diện tích — nó nằm ở hue,
ở dấu ✓/✕ và ở `Semantics` value, cả ba thứ một đường viền 1.5px chở đủ y hệt
trong khi bàn đứng yên.

`selected` dùng `primaryAccent` chứ không phải `primary`: nay nó là **chữ trên
surface**, mà `primary` cố ý được giữ dưới headline của thẻ để một CTA đặc không
lấn — đọc 3.33:1 dạng chữ trần trên nền tối. `danger` và `success` giữ nguyên
token cũ.

**Ripple của `InkWell` giữ nguyên** — nó là phản hồi cho *thao tác chạm*, không
phải trạng thái. Ripple là `primary @ pressed` phủ cả ô và `InkRipple` mờ đi
trong ~375ms; từ khi nhịp giữ lên 500/700ms nó **kết thúc trước** nhịp thay vì
kéo dài quá nó, nên mảng tím chỉ còn là vệt của cú chạm chứ không còn phủ suốt
trạng thái. Ba golden transient chụp ở mốc chuyển màu vừa xong nên vẫn thấy nó ở
light; dark gần như không thấy.

Ghép xong thì **nội dung biến mất, ô ở lại**: slot vẫn chiếm đúng chỗ cũ với
một viền mờ. Xoá ô khỏi bàn — như bản M5.4b từng làm — làm mọi ô bên dưới dịch
lên, tức là dịch ngay khi người dùng đang với tay tới một ô khác. Và vì hai cột
xáo độc lập, hai khoảng trống của một thẻ thường nằm ở **hai hàng khác nhau**;
đó là bàn đang chạy đúng, không phải một lỗ thủng.

Dòng ngữ cảnh trong ảnh ghi `BOARD 1 OF 3`. §7.6 từng bác vì "board" không có
trong BR — **nay có**: BR-156 chia một round thành các bàn năm cặp, nên nhãn ghi
cả hai: `ROUND 1 · BOARD 1/2 · 5 PAIRS LEFT`. Số cặp đếm là của **bàn**, vì thanh
header đã đo cả round rồi.

**Lưới lấp đầy chiều cao, cho tới khi không lấp được** — xem §8.6.

**Hai cột là hai giọng, đúng thứ bậc `browse` đã chốt ở §3.** BR-08 định nghĩa
sẵn hai vế: front là **từ vựng tiếng Hàn**, tối đa 60 ký tự, thứ mắt quét; back
là **nghĩa tiếng mẹ đẻ**, tối đa 240, thứ mắt đọc.

| cột | vế | vai trò | kiểu chữ | số dòng |
|---|---|---|---|---|
| **trái** | back (meaning) | đọc | `bodySmall` (12/w400) | 6, rồi ellipsis |
| **phải** | front (term) | quét | `titleMedium` @ `AppTypography.withWeight(w500)` | 2, rồi ellipsis |

Padding ô `AppSpacing.sm` cả bốn phía. `AppMatchTile.minRowHeight = 112`, và
không một phần nào của nó là số chọn tay: `bodySmall` là 12/16, nghĩa được sáu
dòng, ô chèn `sm` trên dưới — `6 × 16 + 2 × 8 = 112`.

**Meaning bên trái, và chỉ thứ tự trình bày đổi.** Mắt đọc khối dài trước rồi
quét cột ngắn để đối chiếu; đặt khối sáu dòng bên trái là thứ cho phép lượt quét
đó chạy một chiều. Không có gì trong domain bị đảo hay dựng lại — vẫn là hai
hoán vị cũ, xếp ngược lại.

**Chạm được từ cả hai phía.** Chạm một ô bất kỳ để giữ nó, chạm lại chính nó để
bỏ, chạm ô khác cùng cột để chuyển lựa chọn, chạm ô phía đối diện để tạo một
lượt. BR-118 quy định *thẻ nào trả lời cho cặp đó* — luôn là thẻ sở hữu term —
chứ không quy định phải chạm phía nào trước. Bản trước chỉ giữ được term, nên
chạm nghĩa trước rơi vào hư không: không lựa chọn, không lượt, không dấu hiệu
nào cho biết đã có gì xảy ra.

**Chữ nhỏ hơn không làm nghĩa thành vế phụ; nó mua sức chứa.** Chiều cao ô thuộc
về lưới, nên cỡ chữ ở đây đổi lấy *số chữ đọc được*: ở `bodySmall`, một nghĩa
thật — hai ngôn ngữ, từ loại, ghi chú cách dùng — vừa sáu dòng trong đúng cái ô
từng chứa bốn dòng `bodyMedium`. Một nghĩa cụt giữa câu đáng giá thấp hơn một
nghĩa nhỏ hơn một cỡ.

**Hai vòng trước đều lớn hơn cần thiết, và mỗi vòng lộ ra vì một lý do khác.**
Vòng #266 hạ cả hai cột khỏi một vai title in đậm chung — lỗi đó ẩn suốt một
vòng review vì fixture cho mọi thẻ một nghĩa hai chữ, ca không bao giờ xuống
dòng. Vòng này hạ tiếp: `titleLarge` 22px vẫn to hơn ảnh tham chiếu, và bốn dòng
vẫn cắt giữa câu trên dữ liệu thật.

`match_tile_widget_test.dart` khoá typography và `minRowHeight`;
`match_board_layout_test.dart` khoá thứ tự cột, BR-118 sau khi đảo cột, và việc
slot đã xong không làm bàn reflow. Ảnh: `study_match_{light,dark}.png` và ba cặp
`study_match_progress_{idle,wrong,paired}_{light,dark}.png`.

## 5. Study · Guess (`guess_mode`)

- Thẻ đề ở trên: nhãn `WHAT IS THIS?` rồi thuật ngữ cỡ lớn.
- Năm hàng lựa chọn. Mỗi hàng chỉ có nghĩa của thẻ.
- Sau khi trả lời: đáp án đúng nền xanh lá + ✓; lựa chọn sai đã chọn nền đỏ + ✕;
  ba lựa chọn còn lại mờ đi.

Dòng mô tả phụ không có trường nào chứa, nên **không dựng** ở MVP: mỗi lựa chọn
chỉ hiện nghĩa (§7.5).

**Huy hiệu tròn A–E: đã dựng, rồi gỡ.** Ảnh vẽ một vòng tròn chứa chữ cái ở đầu
mỗi hàng. Nó tốn **44pt** mỗi hàng — vòng tròn 28 cộng khoảng cách 16 — trên một
màn rộng 393. Với nội dung ảnh mẫu dùng ("apple") thì không thấy; với nội dung
sản phẩm này phục vụ — *"Deep sleep / Giấc ngủ sâu (Danh từ, trạng thái ngủ ngon
không bị gián đoạn…)"* — 44pt ấy là **một dòng nghĩa trên cả năm hàng**, đổi lấy
một số ghế mà BR-127 xáo lại ở lượt sau và **không có gì đọc ngược nó**: một
lượt được ghi bằng `cardId`, không bao giờ bằng vị trí (BR-125).

Chữ trên hàng cũng hạ từ 16/w600 xuống 14/w400 cùng lý do: một nghĩa là một câu,
không phải một tiêu đề.

## 6. Study · Recall (`recall_mode`) và Study · Fill (`fill_mode`)

Cùng một bố cục: **thẻ đề ở trên, vùng đáp án ở dưới, nút hành động dưới cùng.**

`recall`: vùng đáp án là một khối mờ có vạch giả; nút chính `Show answer`.
`fill`: vùng đáp án là ô nhập, có con trỏ; hai nút — `Hint` viền và `Check` đặc.

**Bố cục cặp thẻ giữ nguyên.** Thay đổi dưới đây chỉ nằm *bên trong* vùng đáp án
của `fill`; thẻ đề, hai `Expanded` và sàn chiều cao chung với `recall` không đụng
tới.

**Bỏ "chữ căn giữa cỡ lớn".** Ô nhập dùng đúng kiểu chữ mặc định của input trong
app, canh trái — một ô căn giữa cỡ 24 là kiểu input thứ hai, mà `MxTextField` tồn
tại để chỉ có một.

Sau khi chấm: một dòng kết cục bằng `success`/`danger`, và **chỉ khi sai** mới có
nhãn `Đáp án` cùng một khối viền `success` chứa mặt sau của thẻ. Trả lời đúng thì
không lặp lại đáp án — nói lại thứ người ta vừa gõ đúng đọc như một lời đính
chính.

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
  mép thẻ và vượt qua cả cột chữ của thẻ (`FRONT`/`BACK` ở 32). Sâu như vậy vì
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

**Năm hàng là trần, không phải nội dung của mock.** BR-156 chia một round thành
các bàn tối đa năm cặp, nên round mười hai thẻ là ba bàn và bàn cuối có thể chỉ
còn một cặp. Biên độ vì thế hẹp nhưng vẫn có: hàng lúc nào cũng flex thì bàn hai
cặp thành hai tấm 300px, còn bàn năm cặp ở textScale 2.0 thành năm hàng 48px. Vì
vậy flex **có sàn**: `AppMatchTile.minRowHeight` = **112**, nhân theo textScaler,
và bàn không đạt sàn thì **cuộn** thay vì bóp. Ở scale 1.0 năm hàng cần
`5 × 112 + 4 × 8 = 592`, vùng bàn của review surface là 628 — nên mọi bàn một
điện thoại thật hiển thị vẫn lấp chính xác.

Sàn không còn là `minimumTouchTarget`. Ô vẫn là *control* và 112 vượt 48 rất xa;
thứ đổi là ràng buộc quyết định: nay nó là sáu dòng nghĩa (§4), không phải ngón
tay.

Ba trạng thái ô theo handout, dịch sang token của dự án:

| handout | dự án |
|---|---|
| `mastery` | `AppSemanticColors.success` — `card_state_widget.dart` đã sơn `CardState.mastered` bằng nó, hai tên là một token |
| nền matched `mastery @12%`, viền `@30%` | **không làm theo** — trạng thái chỉ đổi viền và chữ, nền giữ nguyên (§4). `mastery @12%` từng được dựng bằng `Color.alphaBlend` và đã gỡ cùng `pairedFillAlpha`/`pairedOutlineAlpha` |
| radius 12 · gap 8 · transition 200ms `cubic-bezier(0.2,0,0,1)` | `AppRadius.md` · `AppSpacing.sm` · `AppDurations.normal` + `AppDurations.standard` — trùng khít, không thêm token |
| front 18/w700, back 14/w600 | `titleMedium` @ `w500` và `bodySmall` — xem §4 |
| icon ✓ đứng **trước** chữ, gap 6 | đúng ảnh mẫu; gap = `AppSpacing.xs` |

**Nền matched nay không tồn tại, và lập luận cũ vẫn cần giữ.** Khi còn vẽ nền
`mastery @12%` thì nó **phải blend, không được trong suốt**:
`color_source_rules_test` R7 cấm fill/border translucent vì nó composite với thứ
đằng sau lúc paint, nên một token ra hai giá trị trên hai mặt nền. Ghi lại ở đây
vì `cleared` vẫn dùng đúng kỹ thuật đó cho viền mờ của nó, và vì bản M5.19 từng
**từ chối** nền xanh nhạt với lý do "không có token" — có cách, chỉ là không
phải cách trong suốt. Cái bị bác bỏ ở vòng này là *diện tích*, không phải kỹ
thuật.

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
| đúng | ô sang `success` + ✓ trong `AppMatchTile.successFlash` = **500ms**, rồi **nội dung tan**, ô ở lại rỗng |
| ô rỗng | không vẽ nền (thủng thật), viền `borderSubtle` pha 45% trên nền trang |
| sai | **cả hai** ô sang `danger` + ✕ trong `AppMatchTile.wrongHold` = **700ms**, rồi tự về idle |
| cả hai | không khoá thao tác — chạm ô kế tiếp cắt màu ngay, và một cặp đang ghi DB không đóng băng bàn |

Cái ô rỗng còn làm được một việc nữa: nó là **bằng chứng tiến độ**. Nhìn bàn là
biết còn mấy cặp, không cần đọc dòng ngữ cảnh, và không tốn một màu nào.

**320ms là một phép so sai đơn vị, và đã sửa: nay 500ms cho đúng, 700ms cho
sai.** Lập luận cũ lấy `AppDurations.slow = 320` vì đó là *trần chuyển động* của
app — nhưng **nhịp giữ không phải chuyển động**. Chuyển động là thời gian một
trạng thái *đi tới*; nhịp giữ là thời gian nó *đứng yên để đọc*. Đặt hai thứ
bằng nhau — 320 giữ trên một crossfade 200 — để lại đúng 120ms màu đứng yên, và
lo ngại "3.2 giây chết" của bản cũ dựa trên một tiền đề nay không còn: nhịp giữ
**không khoá thao tác**, chạm ô kế tiếp cắt nó ngay, và cặp đang ghi DB không
đóng băng cả bàn.

Sai giữ lâu hơn đúng vì có nhiều thứ phải đọc hơn: người dùng phải tìm ra *hai ô
nào* sai với nhau — hai lượt nhìn — còn một cặp đúng chỉ xác nhận điều họ đã
biết.

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
  vệt tím, xanh không hiện ra lần nào. Nhịp phải dài hơn chuyển màu. `slow` cho
  120ms màu đứng yên, và **kể cả 120ms ấy cũng không tới được người dùng**: màn
  gọi tải lượt kế tiếp ngay sau khi ghi xong, bàn bị tháo khỏi cây widget trước
  khi nhịp chạy hết. Sửa cả hai: nhịp thành 500/700ms, và bàn chỉ được thay ở
  ranh giới bàn (§8.8b).

### 8.8b Bàn chỉ được thay ở ranh giới bàn

**Ghi từng cặp, tải từng bàn.** BR-25 buộc ghi ngay khi người dùng trả lời, và
điều đó không đổi: mỗi cặp vẫn là một transaction riêng. Thứ bỏ đi là *lần đọc*
đi kèm — trước đây mỗi attempt gọi lại luồng advance + get-next-turn, đọc lại
session, queue, thẻ và progress, rồi thay cả thân màn bằng loading state. Bàn
năm cặp trả giá năm lần như vậy, và ô vừa chạm biến mất dưới một spinner trước
khi phản hồi của chính nó chạy xong.

Nay: bàn tự cập nhật `completedCardIds` tại chỗ sau khi ghi thành công, và chỉ
gọi tải bàn kế tiếp khi **mọi cặp trên bàn đã ghép đúng** — sau khi nhịp xanh của
cặp cuối chạy hết. Lô 20 thẻ: vẫn 20 transaction, nhưng 4 lần chuyển bàn thay vì
20 lần reload. `MxLoadingState` chỉ được phép xuất hiện ở ranh giới **bàn, round
hoặc stage**.

Callback giữa bàn và controller trả về `Future`: ô chỉ được đánh dấu đã ghép sau
khi ghi xong, nên bàn vẽ đúng thứ database đang giữ chứ không đoán theo cú chạm.
Một ghi bị từ chối để nguyên cặp trên bàn.

### 8.12 Thời gian đọc kết quả của từng mode

**Nhịp giữ không phải animation.** `AppDurations` là thang *chuyển động*, rung
cao nhất 320ms vì lâu hơn thế đọc thành lag. Những con số dưới đây là *ngân sách
đọc*: người ta cần bao lâu để tiếp nhận thứ màn hình vừa nói, và câu trả lời phụ
thuộc hoàn toàn vào việc nó nói bao nhiêu. Vì thế chúng là component constant
(`AppStudyFeedback`), không phải token motion.

| Mode | Đúng | Sai | Ranh giới chuyển |
|---|---:|---:|---|
| `browse` | — | — | mỗi lần vuốt tới |
| `match` | 500ms (ô) | 700ms (ô) | chỉ sau cặp cuối của bàn |
| `guess` | 700ms | 1200ms | hết feedback |
| `recall` | 1800ms (revealed) | 2200ms (hết giờ) | hết feedback |
| `fill` | 800ms | 2200ms | hết feedback |
| `self_assess` | — | — | ngay sau khi ghi |

**Sai luôn dài hơn đúng.** Một câu đúng cần được *nhận ra*; một câu sai cần được
đọc, tìm trong danh sách, rồi hiểu. Khoảng cách rộng nhất ở chỗ phần sửa mang
nhiều chữ nhất — `fill` sai là một chính tả phải so bằng mắt với chính tả mình
vừa gõ.

**Không có nút Continue.** Mọi mode tự chuyển; thứ thay đổi là *khi nào*, không
phải *ai bấm*. `match` là ngoại lệ duy nhất về chủ thể: bàn tự giữ nhịp của ô
(`AppMatchTile.successFlash`/`wrongHold`) vì chỉ nó biết cặp vừa xong có phải cặp
cuối hay không, nên `studyModeFeedback(match)` bằng 0 và bàn tự gọi chuyển.

**Không mode nào bị tháo khỏi cây widget để tải thứ thay thế nó** (BR-158).
`advance(minimumVisible:)` chạy song song việc đọc lượt kế tiếp và việc đợi hết
nhịp, rồi mới đổi — fetch chậm không tốn thêm gì, fetch nhanh vẫn phải chờ hết
nhịp. Trạng thái tải toàn thân nay chỉ còn cho một ca: phiên chưa có lượt nào.

**Kết quả chỉ được vẽ sau khi commit** (BR-157). Ghi hỏng thì không có feedback
và không chuyển lượt — thẻ ở nguyên chỗ cũ thay vì trôi qua như thể đã được ghi.

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


### 8.10 `recall` và `fill` theo handout layout 390×780

Hai handout này **đâm vào bốn phán quyết đã chốt**, khác hẳn `guess`. Chủ dự
án đã quyết từng điểm bằng popup:

| handout | chốt | hệ quả |
|---|---|---|
| accent `mastery` cho chip + thanh tiến trình | **không**, giữ `primary` | §7.8 nguyên vẹn. `mastery` trong app này **là** `success` = *đúng*, nên chip RECALL xanh là phán quyết phát ra trước khi người ta trả lời; trên `fill` sai thì thành chrome xanh đè trên đáp án đỏ |
| icon bút chì / loa / undo | **hoãn cả ba** | §7.4 nguyên vẹn. Loa không dựng được thật — `card_media` chưa có trong data model (AD-03) |
| `recall` bỏ đồng hồ, thêm `Forgot` / `Got it` | **giữ BR-128 và §6.1** | Đó là đổi **định nghĩa của mode**, không phải đổi layout: BR-129 cho đúng một kết cục mỗi lượt và BR-130 khoá nó, nên hai nút kia không có gì để ghi |
| `fill` thêm `Try again`, `Mark correct`, hiện chữ đã gõ | **có, nhưng chưa dựng** | cả ba quyết định một lượt **ghi gì** — xem dưới |

**Cái đã lấy từ handout, và nó là phần đáng giá nhất:** hai thẻ là **`Expanded`
ngang nhau**, cùng sàn `AppStudyPair.cardMinHeight` = 160. Trước đó thẻ đề co
theo chữ của nó còn vùng đáp án lấy phần thừa — tức là mỗi thẻ một hình dạng
khác nhau. Chúng hỏi cùng một thứ theo hai chiều, nên chúng bằng nhau.

Thẻ dưới **lùi một bậc** (`surfaceContainerLow`) và **phẳng**: hai thẻ cùng nổi
đọc ra thành hai câu hỏi, còn cái bậc là thứ nói một trong hai đang chờ được
điền. `MxCard` vì thế có thêm tham số `color` — một **vai** của `ColorScheme`,
không phải một màu.

**Chỗ ẩn đáp án giờ là một thanh mờ, không phải một câu.** Panel cũ viết "đáp
án đang ẩn" đúng chỗ đáp án sẽ hiện ra — một dòng chữ người học **đọc thay vì
nhớ lại**. Thanh 140×14 blur 2px nói cùng sự thật mà không có gì để đọc; câu cũ
ở lại đúng chỗ nó vốn làm việc: trong `Semantics`. Blur chứ không hạ opacity —
một thanh mờ nhạt đọc ra là control bị tắt, một thanh nhoè đọc ra là thứ chưa
rõ.

**Hàng CTA ôm chữ, không kéo hết bề ngang** (`AppStudyPair.ctaMaxWidth` = 160 cho
mỗi nút khi có hai). Một nút kéo hết ngang dưới hai thẻ đọc ra là sàn của màn
hình, căn giữa thì đọc ra là đường đi tiếp.

#### Còn lại: `fill` cần một BR trước khi dựng tiếp

`Try again` và `Mark correct` không phải hai cái nút — chúng quyết định **một
lượt ghi gì xuống `study_answers`**:

- `fill` hiện **ghi ngay khi bấm Check**. Cho trả lời lại thì lần hai là lượt thứ
  hai (đụng cách đếm round của BR-115 và nguyên tắc một-lượt của BR-126), hay là
  sửa lượt cũ (đụng BR-135/AD-11: lượt đã ghi thì bất biến)?
- `Mark correct` là người dùng ghi đè kết quả chấm mà BR-134 sở hữu, trong khi
  BR-116 nói thẻ đã sai trong một round thì **vẫn thuộc tập trượt của round đó
  kể cả khi sau đó làm đúng**.

Đề xuất đang chờ duyệt: **hoãn việc ghi** — bấm Check mà sai thì chưa ghi gì,
lượt chỉ được ghi khi người dùng chọn lối ra (`Try again` → gõ lại → Check ghi
một lượt theo kết quả cuối; `Mark correct` ghi một lượt đúng kèm `outcome_reason`
nói rõ là người dùng tự khẳng định). Một lượt một thẻ, BR-126 và BR-135 nguyên
vẹn. Giá: app bị kill lúc đang ở trạng thái sai thì lượt đó mất — cần BR-103
(resume) nói rõ trạng thái sai chưa-ghi được khôi phục thế nào.

Việc hiện lại chữ đã gõ (gạch ngang) thì **không** đụng BR-138 — luật đó cấm
**lưu**, không cấm hiển thị — nhưng lật lại phán quyết ở §6.1, nên đi cùng gói
trên.

#### Còn thiếu, có chủ đích

Dòng gợi ý hai trạng thái (`guess` trước/sau khi trả lời, `recall` ẩn/hiện,
`fill` nhập/sai) — cả ba cần đúng một cơ chế: cờ "đã xong" trong state của
section phải tới được `hintOverride` của khung. Nối một lần cho cả ba.


### 8.11 Dòng gợi ý đổi khi thân màn thôi hỏi

Handout của `guess` ghi dòng gợi ý sau khi trả lời là
`Answer shown — the correct option is highlighted`. Không dựng được ngay ở §8.9
vì cờ "đã trả lời" nằm trong state của section, còn dòng gợi ý thuộc khung.

**Cơ chế: section báo một lần, màn giữ một khoá.** `onResolved` bắn từ chính
tay cầm sự kiện — không bao giờ từ `build`, vì `setState` của cha trong lúc cha
đang build là cách duy nhất đường dây này hỏng.

Màn lưu `_resolvedTurnKey` = `round:cardId` chứ **không phải một `bool`**. Một
bool phải được *xoá* khi sang thẻ mới, và chỗ xoá nó là một chỗ thứ hai phải
biết thế nào là một lượt mới — đúng cái bệnh đã sinh ra bug "lượt đã chốt vẽ đè
lên câu hỏi đang mở" của `recall`. So khoá thì giá trị cũ đơn giản là không phải
lượt hiện tại, và nó tự trả lời.

**Bản đồ `studyModeHintResolved` chỉ có một dòng, và sự trống rỗng đó mới là
phát hiện.** Chỉ `guess` giữ trạng thái đã-trả-lời trên màn đủ lâu để có gì mà
mô tả: người học đang đọc năm lựa chọn để xem cái nào đúng. `recall` và `fill`
ghi ngay khi chốt và thẻ sau nối tiếp, và mỗi màn đã tự in một câu trong thân
của nó — một bản sao thứ hai ở dòng gợi ý là cùng một câu hai lần trên một màn
hình. Null vì thế có nghĩa là *giữ dòng gợi ý thường của mode*.

Đường dây ở lại cho `fill`: khi `Try again` / `Mark correct` được chốt thì hai
trạng thái nhập/sai của nó đã có sẵn chỗ để nói.
