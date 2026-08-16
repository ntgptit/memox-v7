# Wireframe M4.14 — Tag Management (catalog · rename/merge · delete · multi-tag filter)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của tag catalog và overlay lọc theo tag để M99.30 xây mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Tag catalog screen, overlay rename (có mặt gộp), dialog xoá, overlay lọc nhiều tag, và mặt "card list đang lọc theo tag". Ngoài phạm vi: luật nghiệp vụ (BR-230…BR-238), luồng (UC-18), card list nói chung (`m4-11-card-management.md`) |
| **Source of truth for** | Anatomy tag catalog · copy các overlay tag · hợp đồng geometry của catalog và filter overlay · responsive/a11y contract của tag management |
| **Depends on** | `../use-cases.md` (UC-18), `../business-rules.md` (BR-230…BR-238), `m4-11-card-management.md` |
| **Updated by task** | M99.30 (bổ sung T3a, W1, W7 và G10 sau hai vòng review) |
| **Last updated** | 2026-08-14 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

Tag là **nhãn phẳng**, không phải hệ thống deck thứ hai. Mọi quyết định dưới đây
đọc theo ràng buộc đó: không có cây, không có kéo thả, không có màu do người
dùng đặt, không có "tag cha". Một tag là một chuỗi văn bản và một con số.

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| T1 | Catalog là **route full-screen** trong nhánh Library (`/tags`), không phải sheet | Catalog là danh sách dài, có tìm kiếm, và mỗi hàng mở tiếp một overlay. Một sheet chứa danh sách cuộn rồi mở dialog chồng lên chính nó là hai lớp modal cho một việc quản lý; và catalog cần Back của Android trả về đúng chỗ đã vào, tức là cần một route | 2026-08-13 |
| T2 | Hai entry point, cả hai **nhìn thấy được**: icon `Tags` trên app bar của Library, và mục `Manage tags` trong overflow menu của card list | BR-230 nói catalog là library-level nên lối vào chính thuộc Library. Card list vẫn cần lối vào vì đó là nơi người dùng nhận ra một tag viết sai. Long-press **không** phải lối vào — nó không có affordance nào | 2026-08-13 |
| T3 | Lọc theo tag mở bằng một **pill `Tags` trên đúng thanh filter đang có**, không phải một thanh thứ hai | Thanh filter (M4.11 D3) đã là chỗ người dùng đi tìm "thu hẹp danh sách". Một thanh chip thứ hai bên dưới nó ăn chiều cao ở 320dp và tạo hai vốn từ cho một ý niệm | 2026-08-13 |
| T3a | **Pill `Tags` ghim ngoài vùng cuộn**; bốn pill trạng thái cuộn trong phần còn lại | Đo được, không phải thẩm mỹ: bốn pill cũ đã chiếm 341dp của viewport 361dp ở 393dp, nên pill thứ năm nằm trong cùng `SingleChildScrollView` bị đẩy 66% ra ngoài mép phải — **không một pixel nào của chữ "Tags" được vẽ**, ở mọi bề rộng hỗ trợ. Lối vào duy nhất của multi-tag filter khi đó không khám phá được, và con số của T4 không bao giờ đọc được. Ghim giữ nó trên đúng thanh đó (T3) mà không cần thanh thứ hai. **Chi phí đã chọn:** bốn pill trạng thái nay bị cắt sớm hơn — ở 393dp `Flagged` cắt giữa chữ. Đó là đúng cách một hàng cuộn báo "còn nữa", và phân bổ này đúng chiều: `All` luôn trong tầm mắt nên bốn pill kia có lối tới bằng cuộn, còn pill `Tags` **không có lối nào khác** — nó là cửa duy nhất vào multi-tag filter. **Đo lại sau khi ghim, ở 320dp:** `Flagged` kết thúc ở 337.6dp so với mép bar 308.0dp — bị cắt một phần, phần fill và glyph vẫn thấy, nên tiền đề "luôn có đúng một pill sáng" của T4 vẫn đọc được. Thanh này vốn đã tràn ở 320dp trước khi có pill `Tags`, nên đây không phải hồi quy | 2026-08-14 |
| T4 | Pill `Tags` **mang số tag đang chọn** khi tập chọn khác rỗng, và trạng thái chọn dùng đúng token "đang chọn" của `MxPillButton` | Vị từ tag là thứ duy nhất trong thanh filter không tự nói ra mình đang bật — bốn pill kia loại trừ nhau nên luôn có đúng một cái sáng. Con số là câu trả lời rẻ nhất cho "tôi đang lọc theo mấy tag" | 2026-08-13 |
| T5 | Overlay lọc là **bottom sheet có draft**: chọn nhiều, `Clear`, `Apply` | Áp ngay mỗi lần chạm khiến danh sách phía sau nhảy N lần cho một ý định, và mỗi lần nhảy là một lần reset cửa sổ (BR-232). Draft cũng là chỗ duy nhất `Clear` có nghĩa rõ ràng | 2026-08-13 |
| T6 | Nút `Apply` **nói số thẻ khớp với bản nháp**, không chỉ nói `Apply` | Người dùng chọn tag để tìm thẻ, không phải để chọn tag. Số khớp là phản hồi duy nhất trả lời được "cái này có ra gì không" trước khi đóng overlay | 2026-08-13 |
| T7 | Gộp **không** có hành động riêng; nó là hệ quả của rename và được **tiết lộ trước khi xác nhận** | BR-234. Người dùng gõ `Noun` lên `nouns` là đang nói hai cái này là một. Nhưng gộp là mất một tag, nên nó phải được nói ra trước, không phải phát hiện sau | 2026-08-13 |
| T8 | Copy xoá nói **gỡ tag khỏi N thẻ**, không bao giờ nói mất thẻ; nút phá huỷ là `Delete tag` chứ không phải `Delete` | BR-235. `Delete` trần trong một app có thẻ đọc như "xoá thẻ". Một danh từ trong nhãn nút là chi phí rẻ nhất để không ai mất dữ liệu vì một câu mơ hồ | 2026-08-13 |
| T9 | Hàng catalog là **tên + số thẻ + menu**, không có chip màu và không có preview thẻ | Màu do người dùng đặt nằm ngoài v1, và một preview thẻ biến catalog thành một danh sách thẻ thứ hai. Số thẻ là dữ liệu duy nhất có ích để quyết định đổi tên hay xoá | 2026-08-13 |
| T10 | Tag có 0 thẻ **vẫn hiện**, với số đếm `0` | BR-230. Nó là thứ người dùng vào đây để dọn; ẩn nó đi là ẩn đúng hàng mà catalog tồn tại để xử lý | 2026-08-13 |

## W-cấu trúc

### W1 — Entry point

- **Library app bar:** icon `sell_outlined`, `semanticLabel` = `Manage tags`
  (nhãn của **hành động**, không phải của đích — screen reader đọc nút thì cần
  biết chạm vào sẽ làm gì), đứng **trước** action tạo deck. Luôn hiện, kể cả khi chưa có tag nào — catalog
  rỗng là một câu trả lời, không phải một lỗi (T2, BR-230).
- **Card list, overflow menu:** `Manage tags`, cùng menu với `Import cards` và
  `Export cards`, đặt **sau** cả hai. Ẩn trong chế độ chọn nhiều, cùng lý do
  Add và Import bị ẩn: nó rời màn hình.
- **Card list, thanh filter:** pill `Tags` **ghim ở mép phải** của thanh filter,
  ngoài vùng cuộn; bốn pill trạng thái cuộn trong phần còn lại và kết thúc
  cách nó `AppSpacing.sm` (T3, T3a). Pill này MUST nhìn thấy trọn vẹn ở mọi bề
  rộng hỗ trợ — đó là điều T3a tồn tại để bảo đảm.

### W2 — Anatomy tag catalog (trạng thái populated)

Từ trên xuống:

1. **App bar** `Tags` — `MxContentShell`, không action nào ở phải. Catalog không
   tạo tag: tag sinh ra từ thẻ (BR-93), nên một nút `+` ở đây sẽ tạo được tag
   không thuộc thẻ nào và người dùng không có cách nào dùng nó.
2. **Ô tìm kiếm** `MxSearchField`, hint `Search tags`, chiếm hết cột nội dung,
   nằm trong subheader nên nó **không** cuộn theo danh sách.
3. **Danh sách hàng tag**, mỗi hàng:
   - **tên canonical**, tối đa **hai** dòng rồi ellipsis — không phải một:
     G5 vốn đã cho phép hàng cao khác nhau khi tên xuống dòng ở text scale
     lớn, nên "một dòng" ở đây mâu thuẫn với chính hợp đồng geometry bên dưới,
     và `MxListTile` đã dựng hai dòng từ trước;
   - **số thẻ**, dạng `12 cards` / `1 card` / `No cards` (ICU plural), kiểu
     phụ, canh **trái** ngay dưới tên — không canh phải, vì một cột số canh
     phải bên cạnh tên có độ dài bất kỳ tạo một vùng trắng đọc như cột trống;
   - **menu hành động** `more_vert` ở mép phải, chứa `Rename` và `Delete tag`.
4. Không có phân trang: catalog đọc toàn bộ tag của owner. Số tag bị chặn trên
   thực tế bởi BR-94 và bởi việc tag phải thuộc thẻ nào đó.

### W3 — Các mặt của catalog

| # | Mặt | Nội dung |
|---|---|---|
| 1 | loading | `MxAsyncView` loading, app bar giữ nguyên |
| 2 | populated | W2 |
| 3 | empty (chưa có tag nào) | `MxEmptyState`, icon `sell_outlined`, title `No tags yet`, message nói tag được tạo khi gắn vào thẻ. **Không** có CTA — không có hành động nào ở màn này tạo được tag |
| 4 | search empty | `MxEmptyState`, icon `search_off`, title nêu **nguyên văn chuỗi đã gõ**, message mời đổi từ khoá. Ô tìm kiếm **vẫn hiện** |
| 5 | error | `MxErrorState` + `Retry`, ô tìm kiếm ẩn (không có gì để tìm) |

### W4 — Overlay rename

`MxFormSheet`, một trường.

1. **Title** `Rename tag`.
2. **Ô nhập** điền sẵn tên hiện tại, đã chọn sẵn toàn bộ để gõ đè được ngay.
3. **Dải tiết lộ gộp** — chỉ hiện khi tên đã gõ fold trùng một tag **khác**
   (T7, BR-234). Kiểu info, icon `merge`, copy nêu **tên tag đích** và nói rõ
   hai điều: thẻ sẽ chuyển sang tag đích, và tag hiện tại sẽ biến mất. Dải này
   MUST xuất hiện **trước** khi bấm xác nhận, không phải sau.
4. **Hàng action**: `Cancel` và primary. Nhãn primary đổi theo mặt: `Rename` ở
   mặt thường, `Merge tags` khi dải gộp đang hiện — nhãn nút là chỗ cuối cùng
   người dùng đọc trước khi hành động xảy ra.
5. Lỗi validation (BR-93) gắn **dưới ô nhập**, không phải một dải riêng: nó nói
   về chữ vừa gõ.
6. Lỗi thao tác (E3, E4 của UC-18) hiện thành **dải lỗi trong sheet**, giữ
   nguyên chữ đã gõ, có `Retry`.

### W5 — Dialog xoá

`MxConfirmDialog`, kiểu phá huỷ.

- **Title** `Delete tag?`
- **Body** nêu tên tag và số thẻ: `"noun" will be removed from 12 cards. The
  cards themselves stay.` Với tag 0 thẻ, body nói tag không thuộc thẻ nào.
- **Nút phá huỷ** `Delete tag`; `Cancel` là mặc định (T8, BR-235).
- Body MUST NOT chứa từ nào ngụ ý thẻ bị xoá, ẩn hay chuyển đi.

### W6 — Overlay lọc theo tag

`MxFormSheet` hoặc bottom sheet tương đương, có draft (T5).

1. **Title** `Filter by tags`.
2. **Dòng phụ** nói rõ ngữ nghĩa: `Cards with any of the selected tags.` — đây
   là chỗ duy nhất người dùng học được rằng nhiều tag là **OR**, không phải AND
   (BR-231).
3. **Danh sách tag chọn nhiều**: mỗi hàng là tên + số thẻ + ô chọn. Trạng thái
   chọn MUST dùng ô chọn **và** `Semantics(checked:)`, không chỉ màu.
4. **Hàng action**: `Clear` (thứ cấp, vô hiệu khi draft rỗng) và primary
   `Apply` mang số thẻ khớp draft (T6).
5. Đóng overlay mà không `Apply` bỏ draft, giữ nguyên tập đang áp (UC-18 A5).
6. Catalog rỗng: overlay hiện cùng empty state của W3 mặt 3 và không có action
   nào ngoài đóng.

### W7 — Card list khi đang lọc theo tag

- Pill `Tags` sáng và mang số tag đang chọn (T4).
- Không có kết quả: dùng mặt `no match` đã có của card list (M4.11), vì lý do
  vẫn là "bộ lọc không khớp gì" — không thêm mặt thứ hai cho cùng một câu.
  **Khi thứ làm rỗng danh sách là vị từ tag**, mặt đó mang thêm một action
  `Clear` bỏ toàn bộ tag đang chọn (UC-18 A7). Thêm một action vào mặt đang có
  không phải là thêm một mặt: không có nó, lối thoát duy nhất là mở lại overlay
  và bấm `Clear` bên trong — hai chạm cho một việc mà màn hình đang nói thẳng
  vào mặt người dùng.
- Đổi tập tag reset cửa sổ và xoá selection (BR-232); không có hiệu ứng nào
  khác trên màn.

## G-hợp đồng geometry

Đo bằng `tester.getRect`, không đo bằng mắt.

| # | Ràng buộc |
|---|---|
| G1 | Gutter trái/phải của catalog **bằng đúng** gutter của card list ở cùng bề rộng — cả hai lấy từ `MxContentShell`. Một màn quản lý lệch gutter với màn nó quản lý đọc như hai app |
| G2 | Ô tìm kiếm của catalog và ô tìm kiếm của card list có **cùng mép trái và cùng mép phải** ở cùng bề rộng |
| G3 | Trong một hàng catalog: mép trái của **tên** và mép trái của **số thẻ** trùng nhau (W2 mục 3) |
| G4 | Nút menu của hàng có vùng chạm ≥ 48×48dp và mép phải của nó không vượt quá gutter phải |
| G5 | Mọi hàng catalog có **cùng mép trái và cùng mép phải**; chiều cao được phép khác nhau khi tên xuống dòng ở text scale lớn |
| G6 | Trong overlay lọc: hàng tag và hàng action nằm trong **cùng một cột nội dung** — cùng mép trái, cùng mép phải |
| G7 | Ô chọn của hàng lọc có vùng chạm ≥ 48×48dp và **toàn bộ hàng** là vùng chạm chuyển trạng thái, không chỉ ô chọn |
| G8 | Hàng action của mọi overlay nằm **trên** safe area dưới và trên keyboard inset; khi bàn phím mở ở W4, hàng action MUST vẫn nhìn thấy được |
| G9 | Ở 320dp × textScale 2.0: không hàng nào tràn ngang, không chữ nào bị cắt giữa chừng ngoài ellipsis đã khai báo ở W2. Áp cho **cả hai overlay**, không chỉ catalog — hàng action của chúng MUST xuống dòng thay vì tràn, vì một nút là con non-flex của `Row` nên nhãn của nó không tự xuống dòng được |
| G10 | Pill `Tags` MUST nằm **trọn vẹn** trong viewport của thanh filter ở 320 · 390 · 412dp: `getRect(pill).right <= getRect(bar).right` và `left >= bar.left`, **và** cách vùng cuộn đúng `AppSpacing.sm` (T3a). Khe đó MUST đến từ `Row.spacing` chứ không phải `SingleChildScrollView.padding`: padding của scroller pad **nội dung**, nên trên một thanh vốn luôn tràn thì nó chỉ hiện khi đã cuộn tới cuối — đo được 0.33dp ở trạng thái nghỉ, và hai pill dán nhau đọc như một control hỏng |

## R-responsive và a11y

- Kiểm ở **320dp @2.0**, **390dp**, **412dp**, light và dark, EN và VI.
- Mọi vùng chạm ≥ 48dp (G4, G7).
- Trạng thái chọn của cả W6 và pill `Tags` MUST đọc được bằng TalkBack qua
  `Semantics(selected:/checked:)` — màu không phải một thông tin.
- Đóng overlay rename/xoá MUST trả focus về **đúng hàng** đã mở nó.
- Số thẻ dùng ICU plural ở cả EN và VI; không nối chuỗi bằng tay.
- Không màu nào được đặt cứng; mọi màu và khoảng cách lấy từ token.
