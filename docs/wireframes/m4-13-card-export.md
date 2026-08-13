# Wireframe M4.13 — Card Export (scope → format → share)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của sheet export card để M99.21 xây mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Sheet export: entry point, anatomy, format options, mọi trạng thái, hợp đồng geometry, responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-174…BR-181), luồng (UC-11), encoder/kiến trúc (AD-20), import (`m4-12-card-import.md`) |
| **Source of truth for** | Anatomy sheet export · copy các panel export · hợp đồng geometry của sheet export · responsive/a11y contract của sheet export |
| **Depends on** | `../use-cases.md` (UC-11), `../business-rules.md` (BR-174…BR-181), `../architecture.md` (AD-20), `m4-11-card-management.md`, `m4-12-card-import.md` |
| **Updated by task** | M99.21 (phase 6 — recursive UI/UX review) |
| **Last updated** | 2026-08-13 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

Export là nửa đối xứng của Import nhưng **không** đối xứng về hình dạng màn
hình. Import phải hỏi bốn thứ (nguồn, sheet, header, mapping) và cho xem trước
hàng trăm hàng, nên nó là wizard full-screen. Export chỉ hỏi **một** thứ —
format — và scope đã được quyết bởi lối vào. Một wizard cho một câu hỏi là một
màn hình đi tìm nội dung để lấp.

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| E1 | Export là **modal bottom sheet**, **không** phải route full-screen và không thêm route mới | Chỉ có một quyết định của người dùng (format) và một xác nhận. Một route full-screen kéo theo deep link, PopScope, breadcrumb, stepper và một chỗ trong `app_router.dart` cho một sheet ba nút — trả toàn bộ chi phí của I1 (M4.12) mà không có draft state nào để biện minh. Sheet cũng giữ card list phía sau nhìn thấy được, nên "N cards" trong sheet đối chiếu được ngay với danh sách | 2026-08-13 |
| E2 | Scope **chỉ đọc trong sheet**, do lối vào quyết định; không có selector scope | Hai lối vào đã là hai câu trả lời rõ ràng (BR-174). Thêm selector nghĩa là người mở từ `Export selected` có thể vô tình xuất cả deck — một lựa chọn không ai vào đây để làm, và là một cách âm thầm bỏ qua selection người dùng vừa dựng | 2026-08-13 |
| E3 | Ba format hiện **cùng lúc**, CSV chọn sẵn và gắn nhãn `Recommended`; không dùng dropdown | Ba lựa chọn ngắn thì dropdown thêm một lần chạm và giấu mất hai lựa chọn kia. Nhãn Recommended trả lời câu hỏi thật của người dùng ("chọn cái nào?") mà không tước quyền chọn | 2026-08-13 |
| E4 | Sheet nói rõ **cái không có trong file**: tiến độ học và lịch sử | BR-175 là quyết định nghiệp vụ, nhưng người dùng chỉ gặp hệ quả của nó khi import lại và thấy mọi thẻ về `new`. Nói trước một dòng rẻ hơn một hiểu lầm về "backup" | 2026-08-13 |
| E5 | Đóng share sheet là **cancel**, sheet export quay về trạng thái initial giữ nguyên format đang chọn; không toast, không mặt lỗi | BR-181. Đối xứng với I5 của M4.12: hủy một hộp thoại hệ thống là "thôi", không phải một sự cố | 2026-08-13 |
| E6 | Có `Cancel` **cạnh** primary, khác với I3 của M4.12 | Sheet không có app bar nên không có `✕`; nếu bỏ Cancel thì lối thoát duy nhất là cử chỉ kéo xuống — không có affordance và không đọc được bằng screen reader | 2026-08-13 |
| E7 | Trạng thái generating thay **panel action tại chỗ**: hàng action MUST giữ nguyên chiều cao và vị trí giữa `initial` và `generating`, body MUST không đổi | Sheet nhảy giữa lúc người dùng đang nhìn là mất ngữ cảnh, và ở 320dp nó đẩy nội dung ra khỏi tầm mắt. Cùng lý do M4.12 thay panel confirm bằng panel submit tại chỗ (W4) | 2026-08-13 |
| E7a | **Thu hẹp E7 về đúng panel action.** Bản đầu viết "sheet không đổi chiều cao khi chuyển state", câu đó mâu thuẫn với chính W3: mặt 5–7 bắt buộc chèn một dải lỗi *vào trong* sheet, và một sheet cao cố định thì hoặc phải chừa sẵn chỗ cho một dải chưa biết cao bao nhiêu, hoặc phải cắt nội dung. Lập luận của E7 nói về panel action, nên phạm vi của nó là panel action. Sheet **được phép** cao lên khi một dải xuất hiện và thấp lại khi nó biến mất — sheet neo mép dưới, nên hàng action không xê dịch dưới ngón tay; cái di chuyển là mép trên. Ràng buộc còn hiệu lực và phải đo được: `initial` → `generating` MUST không đổi chiều cao | 2026-08-13 |
| E8 | Mọi lỗi hiện **trong sheet**, giữ nguyên scope và format, có `Try again`; sheet không tự đóng khi lỗi | Đóng sheet rồi bắn snackbar nghĩa là người dùng phải dựng lại lựa chọn từ đầu, và với scope `selected` thì có khi phải chọn lại N thẻ | 2026-08-13 |
| E9 | Copy thành công nói **"đã bàn giao cho hệ thống"**, không nói `Saved` và không nói tên thư mục | BR-181 — app không biết người dùng chọn đích nào, và một câu khẳng định sai về nơi lưu là câu người dùng sẽ đi tìm | 2026-08-13 |

## W-cấu trúc

### W1 — Entry point

- **Card list, overflow menu app bar:** `Export cards` — nằm cạnh
  `Import cards` (M4.12 W6), mở sheet với scope `all`.
- **Thanh hành động chọn nhiều** (M4.11 D13): `Export selected` — mở sheet với
  scope là tập id đang chọn. Selection **không** bị xoá khi mở, khi export
  thành công hay khi hủy (BR-178).
- Deck rỗng: **không** hiện `Export cards` ở bất kỳ đâu; empty state của card
  list không có lối export. Deck loại `deck` và root deck cũng không có — chúng
  không giữ card trực tiếp.
- Chế độ chọn với 0 thẻ: thanh hành động không hiện, nên `Export selected`
  không tới được.

### W2 — Anatomy sheet (trạng thái initial)

Từ trên xuống, mỗi mục là một band của **một cột nội dung duy nhất** (W5):

1. **Drag handle** — chuẩn của `MxBottomSheet`.
2. **Title** `Export cards`.
3. **Scope summary, chỉ đọc** — một dòng có icon: `All 128 cards in this deck`
   hoặc `24 selected cards`. Không phải control, không nhận focus như một nút,
   nhưng vẫn nằm trong cây semantics (W6).
4. **Nhãn nhóm format** `Format`.
5. **Ba format option** dạng radio, xếp dọc, mỗi option một hàng: tên
   (`CSV` · `TSV` · `XLSX`), một dòng phụ ngắn nói mở được bằng gì, và **badge
   `Recommended` ở hàng CSV**. Badge MUST nằm **cạnh** tên format khi còn đủ
   chỗ, và MUST rơi xuống dòng dưới khi không — ba option là ba thứ ngang hàng,
   nên một badge cố định xuống dòng làm card CSV cao hơn hai card kia ở mọi
   phone; còn một `Row` cố định thì ở 320dp × 2.0 phải ellipsis đúng một trong
   hai từ mang nội dung khuyến nghị. CSV chọn sẵn. Trạng thái chọn dùng
   viền + glyph + `Semantics(selected: true)`, không chỉ màu (đối xứng M4.12
   W2), và MUST dùng đúng token mà app đã dùng cho "mục này đang được chọn" ở
   chỗ khác — không tự đặt accent thứ hai. Option **MUST NOT** đổi fill theo
   trạng thái chọn ở màn này, khác với card tile: badge `Recommended` là một
   pill cùng vai màu, nên một card được tô cùng vai sẽ nuốt mất badge đúng ở
   option duy nhất có badge.
6. **Dòng nội dung** `Includes front, back, example, hint, pronunciation and
   tags.` — liệt kê đúng sáu field canonical, không localize tên field trong
   file (BR-179).
7. **Dòng info** `Study progress and review history aren't in the file.`
   (E4, BR-175) — kiểu info, không phải warning: cùng cỡ chữ, không màu lỗi,
   không container, có glyph info. Dòng 7 MUST **không** nhạt hơn dòng 6: dòng
   6 là điều người dùng đã đoán được, dòng 7 là điều họ không đoán được và là
   lý do E4 tồn tại — để nó chìm hơn là đảo ngược đúng thứ tự cần đọc.
8. **Hàng action** — `Cancel` (secondary) và `Export N cards` (primary). `N` là
   số card của scope, không phải số hàng đang hiển thị trên card list.

Sheet **không** có: chọn scope (E2), ô đặt tên file (BR-180 dẫn xuất tên),
tùy chọn "include progress" (BR-175 không cho), preview nội dung (BR-181 —
không echo dữ liệu riêng tư ra một màn hình chỉ để trang trí).

### W3 — Sáu trạng thái

Sheet có một **phase trình bày dẫn xuất** (enum, tính từ trạng thái request,
không bao giờ persist). Body và hàng action cùng đọc một phase — hai nơi không
lệch nhau.

1. **Initial** — W2. Primary bật khi scope hợp lệ.
2. **Generating** — panel action được thay tại chỗ (E7): primary đổi nhãn
   `Exporting…`, disabled, mang một indicator **indeterminate duy nhất**;
   `Cancel` vẫn bấm được và đóng sheet mà không tạo file. Bấm primary lần hai
   không có tác dụng (UC-11 A4). Body giữ nguyên — scope và format vẫn đọc
   được, không bị che.
3. **Share requested** — artifact đã bàn giao cho share sheet của hệ điều hành.
   Sheet export **không** vẽ gì đè lên share sheet; khi share sheet trả về, sheet
   export đóng và card list hiện một xác nhận trung thực theo E9. Không hiện tên
   file, không hiện đường dẫn (BR-180).
4. **Dismissed** — người dùng đóng share sheet mà không chọn đích (E5): sheet
   export về đúng trạng thái initial, format đang chọn giữ nguyên, không có
   thông báo lỗi và không có xác nhận thành công.
5. **Unavailable / platform error** — một dải lỗi trong sheet, phía trên hàng
   action: tiêu đề ngắn + một câu có kiểu. Nền tảng không có share sheet nói rõ
   là không khả dụng trên thiết bị này; exception của platform channel nói lỗi
   hệ thống. Cả hai đều **không** lộ path, tên file hay nội dung card
   (BR-181). Action: `Cancel` + `Try again` (primary).
6. **Repository / encoder failure** — cùng dải lỗi, hai lý do phân biệt được:
   đọc dữ liệu thất bại (UC-11 E3) và encode thất bại (UC-11 E4). Không có
   file nào được bàn giao. Action: `Cancel` + `Try again`.
7. **Invalid scope** — deck đã rỗng, tập chọn đã rỗng, hoặc một id đã bị xoá /
   chuyển deck (UC-11 E5, E6). Dải lỗi nói rõ danh sách đã đổi và mời chọn lại;
   primary **ẩn** thay vì disabled — không có gì để thử lại cho tới khi người
   dùng chọn lại. Action còn lại: `Close`. Ba format option MUST vẫn **hiện**
   — chúng là bản ghi của điều vừa được yêu cầu — nhưng MUST **không** còn
   nhận chạm: sheet đã hết khả năng hành động theo một format, nên một control
   vẫn đổi được là màn hình nói sai về việc nó còn làm được gì.

Trạng thái 5–7 giữ nguyên scope và format (E8). Không trạng thái nào tự đóng
sheet trừ 3 (thành công) và 7 khi người dùng bấm `Close`.

### W4 — Hủy, Back, và lần bấm thứ hai

- Initial và các mặt lỗi: `Cancel`, chạm nền mờ, kéo xuống và Android Back đều
  đóng sheet; không tạo file, không đụng selection (BR-178).
- Generating: Android Back và kéo xuống **hủy request** và đóng sheet — request
  chưa chạm database (BR-178) nên không có gì để rollback. Khác với M4.12 W4,
  nơi Back bị khoá vì một transaction đang chạy.
- Bấm primary lần thứ hai khi đang generating không tạo request thứ hai
  (UC-11 A4).

### W5 — Hợp đồng geometry

Đây là phần bị bỏ ở Card Import và trở thành finding V9; nó được viết ra trước
khi code chạy, không phải sau.

- **Một cột nội dung duy nhất.** Title, scope summary, nhãn `Format`, cả ba
  format option, dòng nội dung, dòng info và hàng action **bắt đầu và kết thúc
  ở đúng hai toạ độ x**. Không band nào thụt vào so với band khác; không có
  nhóm căn lề thứ hai trong sheet này.
- **Format option MUST lấp trọn cột nội dung.** Chúng xếp dọc full-width. Nếu
  một bản dựng nào đó xếp chúng thành hàng ngang, mỗi option MUST là `Expanded`
  và hàng MUST rơi về xếp dọc full-width qua một ngưỡng `LayoutBuilder` đo
  được. **MUST NOT** để chúng co về intrinsic width — `Wrap` và `Row` không
  `Expanded` đều làm đúng chuyện đó, và container full-width phía ngoài khiến
  mọi phép đo ở tầng trên vẫn xanh trong khi mép phải bị hụt.
- **Hàng action** dùng chung hai toạ độ x đó: `Cancel` bám mép trái của cột,
  `Export N cards` bám mép phải. Ở 320dp với `textScaler` 2.0, hai nút xếp dọc
  và **mỗi nút full-width**, primary ở trên.
- **Dải lỗi** (W3 mặt 5–7) cũng là một band của cùng cột, không phải một hộp
  thụt vào.

Hợp đồng này MUST được chứng minh bằng **`tester.getRect` assertion** trong
widget test — đo đúng các widget người đọc nhìn thấy (option, dải lỗi, nút),
không đo cái hộp vô hình chứa chúng. Golden mới chỉ là regression baseline và
không chứng minh được geometry: nó so màn hình với bản chụp hôm qua của chính
nó, nên một mép sai nhưng ổn định sẽ pass mãi mãi. Xem mục Responsive của
`.claude/skills/flutter-design-system/SKILL.md` — quy tắc và ví dụ đo nằm ở đó,
tài liệu này chỉ khai báo cột và các band phải khớp.

### W6 — Responsive & a11y

- Kiểm ở 320 / 360 / 390 / 412dp, `textScaler` 1.0 và 2.0, light + dark, EN và
  VI. Không overflow ở bất kỳ tổ hợp nào.
- **Chiều cao cũng phải kiểm, không chỉ chiều rộng — 320×568 ở 2.0.** Sheet nở
  ra lấp màn hình, nên đây là bề mặt duy nhất của app mà chiều cao viewport đổi
  hành vi: một route đã cuộn sẵn, một sheet thì không. Ở tổ hợp đó hàng action
  MUST vẫn nằm trọn trên màn hình và mọi band MUST cuộn tới được.
- Tên deck dài và count lớn: scope summary ellipsis ở tên deck, **không** ở con
  số — con số là thứ người dùng đang kiểm chứng.
- Sheet cao quá màn hình thì body scroll được, hàng action vẫn nằm trong tầm
  với và không bị che bởi safe area hay home indicator.
- Format option có `Semantics(selected:)`; badge `Recommended` là văn bản đọc
  được, không phải chỉ một chấm màu.
- **Viền của option MUST đạt 3:1 với nền nó nằm trên, ở cả hai theme** (WCAG
  1.4.11). Nền của option bằng đúng nền sheet, nên viền là thứ duy nhất tách
  card khỏi sheet — đây chính là ca mà `AppSemanticColors.borderControl` được
  đo và viết ra, không phải ca được miễn dành cho "card chỉ là card". Viền
  trạng thái chọn cũng vậy: một accent đạt 7:1 ở light mà chỉ 2.90:1 ở dark là
  một viền thôi mang trạng thái ở đúng theme khó nhìn hơn.
- Dải lỗi mang icon + chữ, không chỉ dùng màu để báo lỗi, và là một
  `liveRegion` — nó xuất hiện trong lúc focus vẫn ở primary, nên nếu không
  thông báo thì người dùng screen reader chỉ nghe nút đổi nhãn và không bao giờ
  nghe rằng export đã hỏng.
- Trạng thái generating thông báo qua `Semantics` là đang xử lý; nhãn
  `Exporting…` là văn bản thật **và phải được vẽ ra**, không chỉ một spinner
  câm. Một nhãn nằm ở `Opacity(0)` trả lời screen reader và không trả lời ai
  khác — đó vẫn là spinner câm với mắt.
