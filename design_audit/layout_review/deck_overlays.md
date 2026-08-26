# Deck — 11 overlay và màn starter

`test/demo/deck_overlays_demo_test.dart` · `test/demo/deck_starter_demo_test.dart`
· 17 golden · commit `cd4f3eb2`

Bản chấm 29 màn xét **4** bề mặt của deck, và cả bốn là cùng một màn ở bốn trạng
thái. Mọi sheet, menu, form và dialog mà màn đó mở ra thì không có ảnh, không có
số đo, và **không được chấm — kể cả chấm xấu**.

Đó là chỗ deck đặt hai hành động phá huỷ (xoá, reset tiến độ) và ô nhập tự do
duy nhất (đổi tên, tạo mới): những bề mặt sai thì đắt nhất lại là những bề mặt
không có bằng chứng nào.

## Vì sao một file, không phải mười lăm

Mỗi màn trong bản cũ có file riêng vì mỗi màn là một bố cục riêng. Mười một
overlay này thì ngược lại: chúng dùng chung `MxActionSheet`, `MxFormSheet`,
`MxConfirmDialog` và `MxButtonPair`, nên chấm riêng từng cái sẽ chép lại cùng
một nhận xét mười một lần và **giấu mất điều đáng nói nhất — cái nào lặp ở đâu**.
Ba trong bốn phát hiện dưới đây là lỗi của một component dùng chung, không phải
của một sheet.

## Cách dựng

Mở bằng **tap qua đường đi thật**, không gọi thẳng `showX`. Một sheet mở đúng
lối mang theo cả màn phía sau nó — scrim, thanh bar nó phủ, tile nó mọc ra từ đó
— và một nửa việc đánh giá modal là nhìn cái nó đè lên.

Hai lỗi của chính bản dựng này đã phải sửa trước khi có ảnh đúng, và cả hai đều
**im lặng**:

| Lỗi | Vì sao ảnh vẫn trông hợp lệ |
|---|---|
| `showDialog` đẩy route lên **root navigator**, nằm ngoài `ProviderScope` khi scope bọc *trong* `ReviewApp` | Dialog ném `No ProviderScope found` — cái này thì kêu. Nhưng cách sửa (`deckScopeAround` + `deckRouterAt`, đảo thứ tự lồng như `main.dart`) là điều `deckShellWith` không làm được, nên nếu không tách harness thì kết luận sẽ là "dialog không chụp được". |
| Chọn ⋮ bằng **chỉ số**: bar nằm **cuối** cây, không phải đầu | `.first` chụp menu của deck vào file tên `library_menu`; `.at(1)` chụp deck thứ hai dưới cái tên deck thứ nhất. Cả hai PNG trông hoàn toàn bình thường. Chọn theo nhãn (`byTooltip`, `bySemanticsLabel`) mới đúng. |

Cái thứ hai đúng loại "ảnh nói sai về thứ nó chụp" mà CLAUDE.md cảnh báo — và nó
lọt qua vì không ai đối chiếu ảnh với tên file.

## Số đo — 17 bề mặt

| | |
|---|---|
| Tap target dưới 48 | **0** trên cả 17, sau hit-test thật |
| Target nhỏ nằm trong target lớn | 2 ở mỗi sheet có bộ chọn scheduler — radio 40×40 trong hàng `InkWell` 361×80; bấm đâu trong hàng cũng chọn. Không phải lỗi — xem ghi chú probe dưới |
| Giá trị ngoài `AppSpacing.scale` | `48` (vùng bottom sheet), `40` (`insetPadding` của `AlertDialog`), `13` (tay cầm chọn text) — **cả ba đều của framework**, đã truy nguồn trong [README](README.md) |
| Typography rung | 10–12 cho sheet, nhưng đó là **hai màn cộng lại**: sheet vẽ đè lên deck list và probe đếm cả nền. `deck_starter_library` là màn thật, đứng một mình: **4 rung**, không giá trị lệch scale nào |

**Probe đã phải học một luật mới ở đây.** Bản trước báo 2 target dưới 48 trên ba
sheet — radio 40×40. Nhưng mỗi radio nằm trọn trong hàng `InkWell` 361×80 làm
đúng cùng một việc, nên mọi ngón tay chạm vào đều trúng. Đếm chúng là lỗi thì ba
sheet bị chấm hỏng oan. Chiều ngược lại vẫn có thật — nút xoá 40px nằm trong card
mở trang chi tiết là hai việc khác nhau — và probe **không thể** phân biệt, vì đó
là câu hỏi về ý định. Nên nó tách hai nhóm và để người đọc trả lời, thay vì đoán
rồi im lặng sai về một trong hai phía.

## Findings

### O1 — Câu xác nhận xoá mở đầu bằng chữ thường ✅ **đã sửa (#351)**

`"Delete "Business email"?"` / `no cards go to Trash with it.`

Chuỗi ICU ghép hai vế:

```
{deckCount, plural, =0{} =1{1 sub-deck and } other{...}}{cardCount, plural, =0{no cards} ...} go to Trash…
```

Khi deck **không có sub-deck**, nhánh `=0` trả chuỗi rỗng, nên câu bắt đầu ngay
tại `no cards` — chữ `n` thường. Tiếng Việt cùng lỗi: `không có thẻ nào vào Trash
cùng nó.`

Đây không phải trường hợp hiếm: nó là **mọi deck rỗng** — chính thứ người ta hay
xoá nhất. Deck có sub-deck thì câu mở bằng chữ số nên không lộ.

Sửa ở ARB, không ở code — và khi sửa mới lộ **lỗi thứ hai trong cùng chuỗi**:
`=1{1 card}` ghép với ` go to Trash` cho ra `1 card go to Trash with it.`, sai
chia động từ. Cùng nguyên nhân: vế đầu rỗng làm hỏng cả hoa/thường lẫn chủ ngữ
của động từ. Plural lồng, với động từ nằm trong từng nhánh, sửa cả hai:
`No cards go` · `1 card goes` · `1 sub-deck and 1 card go`.

### O2 — Nút của dialog xoá xuống hai dòng, ở **cả hai** ngôn ngữ ✅ **đã sửa (#348)**

`Move to Trash` vỡ thành hai dòng ở tiếng Anh; `Chuyển vào Trash` cũng vậy ở
tiếng Việt.

Đây **chính xác là C1** trong [SUMMARY](SUMMARY.md) — `MxButtonPair` tính
`line = MediaQuery.width − 32 = 361` trong khi nút thật chỉ có **265** (dialog trừ
`insetPadding` 40 và padding 24), nên nó không bao giờ chọn nhánh xếp chồng.

Cái bản chấm cũ chưa biết: lỗi này **không chỉ ở `card_bulk_delete_dialog`**. Nó
ở mọi dialog dùng `MxButtonPair`, và dialog xoá deck là cái thứ hai. C1 mô tả nó
như một khiếm khuyết của một màn; nó là khiếm khuyết của một component, và số
màn bị ảnh hưởng bằng số dialog.

### O3 + O4 — Bộ chọn scheduler tự mang tiêu đề, nên mọi nơi dùng nó có hai ✅ **đã sửa (#349)**

`DeckSchedulerPickerWidget` in `schedulerSectionLabel` ("Study mode") ở dòng 52
của chính nó. Cả ba nơi dùng nó cũng đặt tiêu đề:

| Bề mặt | Đọc ra |
|---|---|
| Reset learning progress | `Study mode after the reset` **rồi ngay dưới** `Study mode` |
| Change scheduler | tiêu đề sheet `Study mode` **rồi** `Study mode` — trùng nguyên văn, cách ba dòng |
| New deck | `New deck` … `Study mode` — **đúng**, vì hai tiêu đề khác nhau |

Sheet đổi scheduler là nặng nhất: cùng một từ, hai rung chữ, không có gì xen
giữa ngoài đoạn mô tả. Người đọc phải tự hiểu cái thứ hai là nhãn của nhóm radio
chứ không phải một mục mới.

Nguyên nhân là hợp đồng của component: một widget con mang sẵn tiêu đề section
thì mọi nơi nhúng nó đều phải biết mà **không** đặt tiêu đề của mình — một luật
bất thành văn mà hai trong ba nơi dùng đã vi phạm. Hướng sửa rẻ nhất là để
tiêu đề thành tuỳ chọn của picker và tắt nó khi nơi dùng đã có.

### O5 — Starter library in mã locale thô ✅ **đã sửa (#355)**

`120 cards · Language: en` và `480 cards · Language: ko`.

`en` / `ko` là mã ISO của schema, không phải thứ người đọc dùng. Màn này là màn
**đầu tiên** một người có thư viện rỗng nhìn thấy (UC-01), và nó đang nói bằng
từ vựng của cơ sở dữ liệu.

### O6 — ~~Hành động và trạng thái trông giống nhau~~ **RÚT LẠI** ✅

Bản đầu chấm mục này ⚠️: `Add to library` và `Added` cùng là chữ trần, cùng rung,
chỉ khác màu — và theo `references/coherence.md` thì khác biệt chỉ bằng màu là
kênh yếu nhất.

**Sai, vì tôi đọc ảnh mà không đọc code.** `starter_library_screen.dart` ghi rõ
hai điều mà bức ảnh không nói:

- **cả thẻ là vùng chạm** (`MxCard(onTap: () => _add(context))`), nên `Add to
  library` không phải một nút bị làm mờ affordance — nó là *nhãn nói thẻ này làm
  gì*. Chuyển nó thành nút viền sẽ tạo một control bên trong một control, đúng
  thứ `MxBreadcrumb.onUp` gọi là "gesture arena nobody wins";
- **không dùng màu primary là quyết định đo được**: `primary` ở rung label đo
  được **2,90:1** trên thẻ nền tối, dưới ngưỡng 4,5:1. Trọng lượng chữ gánh
  affordance thay cho màu là cách duy nhất còn lại vừa đạt tương phản.

Ghi lại thay vì xoá, vì cái sai ở đây có ích: một finding "khác biệt chỉ bằng
màu" nghe đúng theo sách và vẫn sai khi thứ nó mô tả không phải là control, và
khi màu đã bị loại vì lý do tương phản mà bức ảnh không kể.

### O7 — Hai kiểu bố cục cặp nút trong cùng một feature ⚠️

**Đã đổi hình dạng sau #348, và vẫn còn.** Bản đầu ghi:

| Ngang | Dọc |
|---|---|
| dialog xoá · form New deck | sheet reset · sheet đổi scheduler |

Sau khi `MxButtonPair` biết bề rộng thật của dialog, dialog xoá **tự chuyển sang
dọc** — vì 265px không đủ cho một hàng hai nút. Bảng bây giờ là:

| Ngang | Dọc |
|---|---|
| form New deck | dialog xoá · sheet reset · sheet đổi scheduler |

Nên ranh giới không phải "dialog hay sheet" mà là **bề rộng còn lại**, và đó là
một luật nhất quán hơn luật tôi đề xuất ban đầu. Cái còn lại cần chốt: form New
deck là sheet rộng nên vẫn ngang — nếu chủ dự án muốn cặp nút luôn cùng một
hướng bất kể chỗ, thì đó là quyết định, không phải lỗi.

### O8 — Đường duy nhất xem hết breadcrumb là một cử chỉ không có dấu hiệu ⚠️

Sheet `Go to` liệt kê đầy đủ tổ tiên, và nó chỉ mở bằng **long press** trên dải
breadcrumb — không có chevron, không có dấu ba chấm, không có gì báo là có cử chỉ
đó. Việc dải breadcrumb là **một** target cho "lên một cấp" là quyết định đã ghi
(owner review, 2026-08-21) và hợp lý.

Nhưng ghép với [S3](deck_responsive_matrix.md) — breadcrumb cắt cụt **cả hai**
bậc ở 360 × 1.5 × vi — thì hệ quả là: người dùng mất khả năng biết mình đang ở
đâu, và lối thoát duy nhất là một cử chỉ họ không có cách nào biết. Hai vấn đề
riêng lẻ đều nhỏ; chồng lên nhau thì màn level hết đường định vị.

### O9 — Move picker chặn 3 trong 4 mục, nhưng nói rõ vì sao ✅

`Already the current parent` · `This is the deck you are moving` · `Inside the
deck you are moving`. Mỗi mục bị chặn nêu lý do của nó (BR-69, BR-70) thay vì
biến mất — đúng hướng: người dùng thấy cây đầy đủ và hiểu vì sao không chọn được.

Ghi lại như một điểm **đạt** kèm một cảnh báo: với cây sâu 10 cấp (BR-55) thì tỷ
lệ mục không bấm được sẽ còn cao hơn, và lúc đó danh sách cần một cách để phần
chọn được nổi lên. Chưa đo ở độ sâu đó.

## Những gì đạt

- **0/17 bề mặt** có tap target dưới 48 sau hit-test thật.
- **0** giá trị spacing của app nằm ngoài scale; ba giá trị lệch đều của framework.
- Mọi sheet đều có tiêu đề nói nó là gì.
- Sheet tạo con của deck `unset` mở **cả** `New sub-deck` lẫn `New card`
  (BR-61/BR-62) — không cái nào bị vô hiệu hoá.
- `deck_starter_library` là màn sạch nhất trong toàn bộ bản review: **4 rung
  chữ**, không giá trị lệch scale nào.
- Dialog xoá nêu chính xác số sub-deck và số thẻ sẽ đi cùng (BR-04) và nói rõ
  khôi phục được trong 30 ngày (BR-256).

## Chưa đo

- **Responsive và text scale cho overlay.** 15/17 bề mặt chụp ở 393 × 1.0. Sheet
  là nơi chữ dài nhất trong app nằm, nên đây là lỗ hổng thật —
  [ma trận responsive](deck_responsive_matrix.md) mới chỉ phủ deck list.
- **Trạng thái đang xử lý và trạng thái lỗi** của mọi form và mọi hành động phá
  huỷ. `card_export_sheet` đã cho thấy trạng thái "đang chạy" là nơi hai lỗi chỉ
  ảnh mới thấy được đã trốn.
- **Sheet cài đặt starter** (`showStarterInstallSheet`) và nhánh "thêm lần nữa".
- **Dark** cho 13/17 bề mặt.
