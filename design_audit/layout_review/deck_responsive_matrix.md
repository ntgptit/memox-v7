# Deck — ma trận responsive và content stress

Bốn màn deck · `test/design_audit/deck_stress_probe.dart` · commit `cd4f3eb2`

Trả lời §16 (Responsive) và §19 (Content stress) cho
[deck_list_root](deck_list_root.md), [deck_list_level](deck_list_level.md),
[deck_list_empty](deck_list_empty.md) và
[deck_list_new_only](deck_list_new_only.md) — bốn mục mà bản chấm trên
`ea80d3f7` phải để `➖` vì gallery chỉ chụp **một** bề rộng, **một** text scale
và **một** ngôn ngữ.

## Vì sao phải đo lại chứ không đọc lại

Code deck không đổi một dòng nào giữa `ea80d3f7` và `cd4f3eb2` — chỉ
`app_toggle_themes.dart` đổi. Chạy lại probe cũ trên frame cũ sẽ in ra đúng
những con số cũ, và đó là chép lại chứ không phải review. Thứ chưa ai biết
không nằm ở lần pump đó; nó nằm ở **các frame chưa từng được dựng**.

Nên phép đo này dựng 25 frame mới: ba bề rộng × ba text scale, cộng tiếng Việt,
dark, tên deck dài, và list 0 / 1 / 50 item.

## Cách đọc

Probe hỏi từng `RenderParagraph` đã layout hai câu: `didExceedMaxLines` — nó có
phải cắt chữ không — và `getMaxIntrinsicWidth` — nó cần bao nhiêu bề rộng để
không phải cắt. Hiệu số là cột **thiếu**, tính bằng logical pixel.

Cách này quan trọng vì **không có overflow nào trên toàn ma trận**. Không một
frame nào vẽ sọc vàng đen, không một assert nào nổ. Mọi thứ hỏng ở đây đều hỏng
*êm*: `TextOverflow.ellipsis` làm đúng việc của nó, và một dấu `…` trông như một
lựa chọn thiết kế chứ không như một sự cố. Đó là lý do bốn vòng review trước
không thấy — chúng nhìn ảnh, mà ảnh thì không kêu.

## Ma trận — deck list, root

| Bề rộng | Scale | `cards due` | `8 overdue · 7 today` |
|---|---|---|---|
| 360 | 1,0 | ✅ | ❌ thiếu **6** |
| 360 | 1,3 | ❌ thiếu 33 | ❌ thiếu 44 |
| 360 | 1,5 | ❌ thiếu 56 | ❌ thiếu 70 |
| 393 | 1,0 | ✅ | ✅ |
| 393 | 1,3 | ❌ thiếu 16 | ❌ thiếu 28 |
| 393 | 1,5 | ❌ thiếu 40 | ❌ thiếu 53 |
| 412 | 1,0 | ✅ | ✅ |
| 412 | 1,3 | ❌ thiếu 7 | ❌ thiếu 18 |
| 412 | 1,5 | ❌ thiếu 30 | ❌ thiếu 44 |

**393 ở scale 1,0 là ô duy nhất sạch — và nó chính là ô gallery chụp.** Nhưng
chỉ sạch *trong tiếng Anh*:

| 393 · 1,0 | `cards due` / `thẻ đến hạn` | breakdown |
|---|---|---|
| **en** | ✅ | ✅ |
| **vi** | ✅ | ❌ thiếu **9** — `8 quá hạn · 7 hôm …` |

Cùng fixture, cùng bề rộng, cùng scale; đổi mỗi ngôn ngữ. Xem S1.

## Ma trận — deck list, level

| Điều kiện | Cắt |
|---|---|
| 393 · 1,0 · en | ✅ **sạch** |
| 393 · 1,0 · vi | `4 quá hạn · 8 hôm nay` thiếu 10 · filter pill `Tất cả bộ thẻ` thiếu 4 |
| 360 · 1,0 · en | `4 overdue · 8 today` thiếu 7 · breadcrumb `Academic Word List` thiếu 5 |
| 360 · 1,5 · en | thêm `cards due` thiếu 56 · filter pill `All decks` thiếu 9 · breadcrumb thiếu 45 |
| 360 · 1,5 · vi | `thẻ đến hạn` thiếu 78 · `4 quá hạn · 8 hôm nay` thiếu 100 · `Tất cả bộ thẻ` thiếu 40 · breadcrumb thiếu 45 |

## Sạch trên toàn ma trận

| | |
|---|---|
| `deck_list_empty` | ✅ mọi bề rộng, mọi scale, en + vi. Không cắt gì. |
| `deck_list_new_only` | ✅ như trên. |
| Overflow | ✅ **0/25 frame**. Không frame nào tràn. |
| 50 deck | ✅ không cắt, không tràn, cuộn bình thường |
| Dark | ✅ **giống hệt light** — không phát sinh, không che giấu lỗi nào |
| Tap target | ✅ 0 target dưới 48 ở mọi ô, **trừ** một ô — xem S5 |

Hai màn sạch tuyệt đối không phải may: cả hai đều **không có hero**. Mọi thứ
gãy trong bản review này đều gãy bên trong hero hoặc trong hàng điều hướng của
nó.

## Findings

### S1 — Hero mất một nửa dữ kiện ở cấu hình bình thường ❌ Level 1

`8 overdue · 7 today` có 126px, cần 132px. **Thiếu 6px** và hiển thị thành
`8 overdue · 7 to…`.

Đây không phải điều kiện khắc nghiệt: 360dp là bề rộng của một phần lớn máy
Android đang chạy, và text scale 1,0 là mặc định. Cái mất đi cũng không phải
trang trí — BR-162 tách tổng thành *overdue* và *due today* chính vì hai con số
đó trả lời hai câu khác nhau, và ở đây câu thứ hai biến mất.

**Và nó không cần tới 360px.** Ở **393 × 1,0 — đúng bề rộng và đúng scale mà
gallery chụp — chỉ cần ngôn ngữ là tiếng Việt** thì hero đã cắt: `8 quá hạn ·
7 hôm …`, thiếu 9px, mất chữ `nay`. Màn level cũng vậy (thiếu 10px), kèm filter
pill `Tất cả bộ thẻ` thiếu 4px.

Điều đó dịch ra một câu đáng nói thẳng: **ứng dụng này viết cho người Việt, và ở
cấu hình chuẩn của chính nó, hero tiếng Việt đang cắt chữ.** Bằng chứng duy nhất
mà 29 màn được chấm dựa trên — bộ golden — chụp bản tiếng Anh, nên trục này chưa
từng xuất hiện trong bất kỳ vòng review nào. Tiếng Việt ở đây **dài hơn** tiếng
Anh (`thẻ đến hạn` 9 ký tự so với `cards due`), đúng chiều mà quy tắc +30% của
localization dự báo, chỉ là chưa ai đo.

Ở scale 1,5 hero đọc nguyên văn **`15 car…  8 overdue…`**: `car…` không còn là
một từ, và `7 today` không còn tồn tại. Người dùng thấy hai con số trần không có
đơn vị.

`Semantics` vẫn đọc đủ, nên screen reader không mất gì — mất mát là hoàn toàn
thị giác, và chỉ với người nhìn.

**Nguyên nhân cấu trúc.** `_HeroLine` là một `Row` với **hai** `Flexible` cạnh
tranh cùng một bề rộng: cụm numeral + đơn vị bên trái, cụm breakdown bên phải.
Khi chật, `Flexible` chia phần cho cả hai và **cả hai cùng cắt** — không cái nào
được ưu tiên, nên thay vì mất trọn một thành phần ít quan trọng, màn mất một
mẩu của mỗi thành phần. Ba hướng đáng cân nhắc:

- cho breakdown xuống dòng riêng dưới numeral khi bề rộng không đủ;
- bỏ breakdown ở bề rộng hẹp và để chevron đang có gánh việc mở chi tiết;
- rút ngắn chuỗi (`8 quá hạn · 7 nay`) — rẻ nhất nhưng chỉ mua được vài pixel,
  và ở scale 1,3 thì thiếu tới 44px nên nó không đủ.

### S2 — Đơn vị của numeral hero rời khỏi màn từ scale 1,3 ❌ Level 1

`cards due` cắt ở **mọi** bề rộng khi scale ≥ 1,3, kể cả 412px (thiếu 7px).
Numeral `15` là điểm nhấn cấp 1 duy nhất của màn — nó là lý do 700 weight tồn
tại (F5 của bản cũ) — và ở scale 1,3 nó mất đơn vị, thành một con số không nói
nó đếm cái gì.

Text scale 1,3 không hiếm. Nó là một nấc giữa trên thanh trượt Android, không
phải chế độ trợ năng cực đoan.

### S3 — Breadcrumb hết khả năng định vị ở màn level ❌ Level 1

`Academic Word List` thiếu 5px ngay ở 360 · 1,0. Ở 360 · 1,5 · vi, breadcrumb
đọc **`Tất cả… / Academic W…`** — **cả hai** bậc đều cụt.

Breadcrumb có đúng một việc: trả lời "tôi đang ở đâu". Một breadcrumb mà mọi bậc
đều cụt không làm được việc đó, và nó chiếm chỗ như thể có làm.

Đây là dự đoán của chính `deck_list_level.md` §16 — *"ở 360px hoặc tiếng Việt nó
là thứ tràn trước tiên"* — được xác nhận bằng số. Ghi lại vì nó cho thấy `➖`
trong bản cũ là một câu hỏi thật, không phải chỗ trống lịch sự.

BR-55 cho phép deck sâu 10 cấp; phép đo này mới chỉ dùng 2.

### S4 — Nhãn control bị cắt ⚠️ Level 1

Filter pill `All decks` thiếu 9px ở scale 1,5; tiếng Việt `Tất cả bộ thẻ` thiếu
40px. Một nhãn control bị cắt nặng hơn một nhãn nội dung bị cắt: người dùng phải
quyết định có bấm hay không dựa trên chữ đã mất.

### S5 — FAB leo thang từ đè chữ thành đè control ⚠️ Level 1

Ở 393 · scale 1,5, FAB (`321,700 → 377,756`) và nút Study của card cuối
(`281,728 → 361,776`) **chồng nhau 40 × 28px** — nửa bề rộng của nút. Vùng chạm
thật của nút Study rơi xuống **46px**, dưới ngưỡng 48, và là target dưới ngưỡng
duy nhất trên cả ma trận.

Ở scale 1,0 và 1,3 hai thứ này không chạm nhau; chỉ scale 1,5 mới đẩy card thứ
ba vào đúng chỗ FAB đứng.

**Đây là dữ kiện mới cho F1, không phải một finding mới.** Chủ dự án đang cố ý
để F1 mở (2026-08-26) và bản review này **không** đề xuất chốt phương án. Điều nó
bổ sung là: ở text scale lớn, cái bị che không còn là chữ mà là một control, nên
bất kỳ phương án nào được chọn cũng cần đúng ở 1,5 chứ không chỉ ở 1,0.

### S6 — Tên deck tiếng Việt dài: đúng hành vi, nhưng hết chỗ sớm ➖

Tên 56 ký tự cần 476px trong khi cột chữ rộng 233px — tức hơn 2 dòng, nên
`maxLines: 2` cắt. Cắt một danh xưng dài **là** hành vi đúng, và phần còn lại đủ
để phân biệt hai deck.

Ở scale 1,5 thì cần 710px ≈ 3 dòng, nên phần đọc được rơi xuống khoảng một dòng
rưỡi. Ghi lại là một đánh đổi đã biết chứ không phải lỗi — nó chỉ thành lỗi nếu
hai deck khác nhau cùng cụt về một chuỗi giống nhau.

## Chấm lại §16 và §19

| Màn | §16 cũ | §16 mới | §19 mới |
|---|---|---|---|
| `deck_list_root` | ➖ | ❌ S1, S2 | ✅ 0/1/50 item đều sạch |
| `deck_list_level` | ➖ | ❌ S1, S2, S3, S4 | ➖ breadcrumb 10 cấp vẫn chưa đo |
| `deck_list_empty` | ⚠️ | ✅ sạch toàn ma trận | ✅ |
| `deck_list_new_only` | ➖ | ✅ sạch toàn ma trận | ✅ |

Điểm **Responsive** trong [SUMMARY](SUMMARY.md) đổi theo: root và level xuống
`0` (có bằng chứng hỏng), empty và new_only lên `2` (có bằng chứng đạt). Trung
bình toàn bộ 29 màn không đổi — vẫn `0,86` — vì bốn thay đổi triệt tiêu nhau.
25 màn còn lại vẫn `➖`: phép đo này chỉ dựng frame cho deck.

## Cái vẫn chưa đo được

- **Safe area** (§17) — vẫn `➖`. Frame test không có cutout hay gesture inset.
- **Breadcrumb sâu 10 cấp** — BR-55 cho phép, ma trận này dùng 2 cấp.
- **Trạng thái pressed / focused** — probe đo frame ở trạng thái nghỉ.
- **Loading và error của chính màn root** — chưa có fixture.
