# AD-14 · Hệ màu và chiều sâu: seed, role, và cue theo mode

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Giữ toàn văn lý luận của AD-14 — vì sao, cách suy ra số, các phương án bị loại — tách khỏi `architecture.md` để file đó đọc được |
| **Scope** | Seed, 45 role của `ColorScheme`, cue chiều sâu theo mode, nguồn giá trị token, lịch sử các lần áp lại luật. Ngoài phạm vi: quyết định AD khác, layering của `lib/core/theme/` (`theme-architecture.md`) |
| **Source of truth for** | Suy luận đầy đủ, số đo và các phương án từng cân nhắc của AD-14 (quyết định và đánh đổi vẫn được tuyên bố ở `../architecture.md`) |
| **Depends on** | `../architecture.md` (AD-14) · `../document-conventions.md` |
| **Updated by task** | M100.65 |
| **Last updated** | 2026-09-08 |

---

Tài liệu này là phần thân đầy đủ của AD-14. Quyết định, năm nguyên tắc và
đánh đổi đã nhận được tuyên bố ở `../architecture.md` — đọc ở đó trước. Phần
dưới đây là *vì sao* mỗi con số là con số đó, các phương án đã bị loại, và
lịch sử các lần luật này được áp lại.

### Vì sao có quyết định này

Hệ màu của app từng đúng ở hầu hết các chỗ mà không ai viết ra tại sao. Hậu quả
đo được ở M4.10f: light mode có nền mang seed nhưng **card là trắng thuần không
hue**, sáu token nữa cũng vậy, và shadow mang seed ở light còn dark là đen tuyệt
đối. Không cái nào là quyết định — chúng là chỗ trống chưa ai lấp.

Tệ hơn: **hai đoạn comment bị đọc thành luật**. `app_colors.dart` viết rằng thang
surface hoạt động "without a shadow being asked to carry the hierarchy", và
`mx_card.dart` viết "flat by design". Hai milestone sau đó trích chúng như một
ràng buộc — kể cả để bác bỏ một ceiling của bản brief audit — trong khi không có
AD, không BR, không test nào đứng sau, và `docs/checklist.md` thì vẫn đang yêu cầu
một Elevation token chưa ai làm. Chủ dự án cuối cùng phải nói thẳng rằng app **cần**
độ nổi. AD này tồn tại để lần sau không phải suy ra luật từ văn xuôi.

### Quyết định (toàn văn)

**1 · Seed là nguồn của mọi trung tính.** `AppColors.seed` (HSL hue 233 từ
M100.25; 240 trước đó). Mọi
neutral — surface, page, border, muted text, shadow, scrim — phải mang một trace
của nó. Công thức chuẩn tắc là
`Color.alphaBlend(seed.withValues(alpha: a), base)`, **precompute thành hằng số**,
không phải một màu trong suốt đặt vào slot vẽ.

Một trung tính không có hue không phải "trung tính hơn": nó là một trung tính
**không thể đi theo seed khi seed đổi**. MX-VIS-002 rule R9 chặn.

**2 · Mỗi role là một hue qua một bộ sinh.** `primary`, `secondary`, `tertiary`,
`error`/`danger`, `success`, `warning`, `info`. Fill và container của cùng một
role phải nằm trong 5° của nhau (rule R3). Không chọn tay một biến thể sáng hơn
cho một badge.

Lỗ đã biết: `success`, `warning`, `info` mới có fill. Container / border / focus
sẽ derive khi có caller thật, không derive trước.

**3 · Border lấy hue từ chủ của thứ nó bọc.** Container trung tính (card, input
nghỉ, divider, list tile, sheet) → từ seed. Component thuộc role (outline button
nguy hiểm, input lỗi, trạng thái focus) → từ hue của role đó.

**4 · Chiều sâu là mục tiêu đo được, không phải cơ chế cố định.**

Đây là phần đắt nhất và là phần dễ bị viết sai thành luật nhất. **Cái phải giữ
bằng nhau giữa hai mode là tổng độ nổi của một card khỏi trang nó nằm trên** —
hiện 7.75 L\* ở light và 7.70 ở dark. Mỗi mode tự do dựng con số đó bằng thứ nó có:

| | bậc surface | shadow | border |
|---|---|---|---|
| light | 2.15 L\* | +5.6 L\* (alpha 0.07) | 1.50:1 |
| dark | 7.70 L\* | **không có** | 1.82:1 |

Dark không vẽ shadow vì **đo được**, không phải vì thẩm mỹ: trang dark nằm ở đáy
thang lightness (L\* 3.86), nên một shadow ở alpha 0.20 chỉ dịch được 0.26 L\*.
Material 3 bỏ shadow ở dark vì cùng lý do. `app_elevation_test.dart` **dẫn lại**
phép đo đó chứ không trích nó, nên nếu palette đổi tới mức shadow dark trở nên
thấy được thì test đỏ và quyết định được xem lại.

**Hệ quả: hai luật cũ đã bị thay, và cả hai từng đúng.** "Border phải khớp giữa
hai mode" đúng khi border là cue duy nhất; sai ngay khi light có shadow. "Mỗi bậc
ladder ≥ 3 L\*" đúng khi ladder là toàn bộ hierarchy; light nay là 2.0 vì shadow
gánh phần chênh. Một luật viết cho một mode chỉ có một cue thì hết hiệu lực khi
mode đó có hai.

**5 · Mọi thứ được vẽ phải đến từ theme của app, kể cả khi Flutter có mặc định.**
Một màu tồn tại như mặc định framework thì **vô hình với mọi phép quét mã nguồn**
— đó là cách `Colors.black54` làm barrier sau mỗi dialog và sheet sống sót qua
trọn một cuộc audit màu (M4.10m). Component nào app dùng thì app khai báo theme
cho nó.

**Một token đúng vẫn có thể sai ở vai trò khác — nhưng lời giải là sửa token,
không phải đổi role của component (M100.18).** Đoạn này trước đây kết luận ngược
lại, và kết luận đó đã đẻ ra năm token thay thế.

Sự việc: `primaryDark` từng được giữ ở luminance thấp để một filled button không
thành thứ sáng nhất trên trang navy. Dùng chính nó làm **focus ring** thì đo được
2.90:1 trên `surface` và 2.11:1 trên `secondaryContainer` — dưới ngưỡng 3:1 mà
WCAG 1.4.11 đòi ở một chỉ báo đồ hoạ (M4.10ap). Phản ứng lúc đó là cấp cho vai
trò ấy một token riêng (`focusRing`), và cùng lập luận đã đưa progress indicator
rời khỏi `primary` ở M4.10m, tab và list tile rời sang `primaryAccent`, còn nhãn
của control được chọn thì đổi role theo brightness (`selectedInk`).

**Nguyên nhân gốc không phải role, mà là palette.** M3 đặt `primary` của một dark
scheme ở tone 80 — một tone **sáng** — với `onPrimary` ở tone 20; palette này để
`primary` ở tone-fill 42.5 mang chữ trắng. Một tone không thể vừa đủ sáng để đọc
được như nhãn trên nền tối, vừa đủ tối để chữ trắng nằm lên: đo được điểm giao là
cứng — giá trị hue-240 đầu tiên đạt 4.5:1 như chữ làm trắng trên nó tụt còn
3.73:1. Nên mọi binding M3 giao cho `primary` đều trượt, và mỗi lần trượt lại đẻ
thêm một token.

**Quyết định:** component gắn với role M3 quy định cho nó; tỉ lệ không đạt thì
**đổi giá trị của role**, một chỗ, rồi đo lại toàn hệ. Đảo tone `primary` ở dark
(`#5656C9` → `#C3C3EB`, `onPrimary` `#FFFFFF` → `#262670`) làm mọi binding đạt
cùng lúc: 10.02:1 làm chữ trên card, 7.37:1 làm ring trên `primaryContainer`,
7.31:1 trên `secondaryContainer`, nhãn nút 7.72:1. Ba token thay thế
(`primaryAccent`, `focusRing`, `selectedInk`) mất lý do tồn tại và bị gỡ.

**Ràng buộc cũ vẫn còn, chỉ đổi công cụ đo.** CTA không bao giờ được là thứ sáng
nhất màn hình: `primary` trên page đo 11.36:1 trong khi `onSurface` đo 15.84:1.
Trước đây điều đó được cưỡng chế bằng trần luminance 0.20 — một công cụ của
palette tone-fill; nay nó được phát biểu trực tiếp thành quan hệ giữa hai tỉ lệ.

**Đo trên nền thật, không trên một nền danh nghĩa** vẫn nguyên giá trị:
`primaryDark` cũ đạt 3.29:1 trên `background`, nên một phép kiểm chỉ dùng nền
trang sẽ pass và bỏ sót cả hai nền mà control được focus thực sự nằm lên.

**Ba họ accent còn lại đã đúng M3 từ trước** — `secondary`, `tertiary` và `error`
ở dark đều đã đảo tone (fill sáng, on-fill tối), lệch tone mục tiêu 4,8–13,3 L\*
và không ràng buộc nào của chúng hỏng. Chúng **không** bị snap về đúng T80/T20:
trigger để đổi một hex là một tỉ lệ hỏng, và chúng không có.

**Luật này áp lần thứ hai ở M100.22, và lần này cái sai không phải token mà là
role của component.** M100.18 gỡ các token thay thế; nó không rà lại những
component đã *đổi sang role M3 khác* để né cùng một phép đo. Còn lại năm cái, và
tất cả đều dồn về hai lỗ trong palette:

| Component | Slot | Đã dùng | M3 quy định |
|---|---|---|---|
| NavigationBar | nền / indicator / glyph / nhãn active | `background` · `primaryContainer` · `onPrimaryContainer` · `onPrimaryContainer` | `surfaceContainer` · `secondaryContainer` · `onSecondaryContainer` · `onSurface` |
| ChoiceChip | fill / nhãn / viền selected | `primaryContainer` · `onPrimaryContainer` · `primary` | `secondaryContainer` · `onSecondaryContainer` · trong suốt |
| SegmentedButton | fill / nhãn selected / nhãn unselected | `primaryContainer` · `onPrimaryContainer` · `onSurfaceVariant` | `secondaryContainer` · `onSecondaryContainer` · `onSurface` |
| OutlinedButton | nhãn | `secondaryAction` | `primary` |
| Switch | thumb / track / viền track (off) | `onSurfaceVariant` · `surfaceMuted` · `borderControl` | `outline` · `surfaceContainerHighest` · `outline` |

Ba cái đầu né cùng một chỗ: `secondaryContainer` ở light (`#E4E6EC`) chỉ cách
`surfaceContainer` **4,22 L\***, nên trạng thái selected không đọc được và mỗi
component tự đi mượn `primaryContainer` (7,16 L\*). Cái thứ năm né chỗ khác:
`outline` trên `surfaceContainerHighest` đo **2,79 / 2,54** — dưới 3:1 mà WCAG
1.4.11 đòi, và trên switch thì thumb *chính là* trạng thái.

**Sửa hai hex, không sửa mười một slot:** `secondaryContainerLight`
`#E4E6EC` → `#D9DDEB` (L\* 91,30 → 88,19, chroma 0,031 → 0,071, giữ hue 226) và
`borderControl` `#8A8A92` → `#7D7D85` light, `#6E6A98` → `#7D79A2` dark. Sau đó
mọi cặp canonical đều đạt, và mọi nền khác của `outline` **tốt lên** như hệ quả
(3,32 → 3,95 trên card light; 3,39 → 4,16 dark).

**Dark không đổi, và đó là một phát hiện chứ không phải bỏ sót.**
`secondaryContainerDark` đã cách `surfaceContainer` 7,99 L\* — nhiều hơn cả 7,71
của `primaryContainer`. Việc thay role ở dark chưa bao giờ mua được gì; báo cáo
gốc của chủ dự án nói "trên nền sáng", và phép đo đồng ý.

**Cái mà M100.22 gỡ hẳn là khái niệm "một selected ink chung".**
`app_selected_ink_test.dart` từng ghim rằng pill, glyph tab và nhãn tab cùng phân
giải về một token. M3 không như vậy: nhãn tab active là `onSurface` vì nó nằm
*dưới* indicator chứ không nằm trong, còn glyph nằm trong nên lấy
`onSecondaryContainer`. Test đó không mô tả app — nó **giữ ba component ở ngoài
default của chúng**, và sẽ đánh trượt bất kỳ ai sửa đúng. Thay bằng
`m3_role_contract_test.dart`: ghim `slot → role` bằng **identity**, cho 17
component, ở cả hai mode.

**Vì sao identity chứ không phải hex hay tỉ lệ.** Ghim hex vẫn pass khi component
đổi sang role khác tình cờ trùng giá trị; ghim tỉ lệ pass cho *mọi* role vượt
sàn — đó chính là cách mười một slot trôi sang `primaryContainer` mà mọi gate vẫn
xanh. Phân công từ M100.22: **role thuộc về component, con số thuộc về palette.**

**Và khai báo component là chưa đủ — phải khai báo đủ *state*.** `ChipThemeData`
có `backgroundColor` và `selectedColor` nên nhìn qua tưởng đã xong; Material vẫn
trả lời cho disabled, hover, focus và press. Câu trả lời của nó cho disabled là
`onSurface` ở **alpha** 12% — đúng thứ R7 cấm — và cho disabled-selected là
nguyên vẹn `secondaryContainer`, tức một pill không bấm được trông y hệt pill
bấm được (M4.10ao). Slot state-aware (`color`, `WidgetStateBorderSide`,
`WidgetStateColor` trong `labelStyle`) là nơi quyền sở hữu thật sự nằm.

**Hue của hai họ accent đổi sang palette Tokyo ở M100.25, và luật trên là
thứ quyết định *cách* đổi.** Chủ dự án chỉ định tham chiếu
`ntgptit/tokyo-react-admin-dashboard`: `primary` `#5569FF`, `secondary`
`#6E759F`, dark `secondary` `#9EA4C1`. Không lấy nguyên hex vào slot fill khi
tỉ lệ không đạt — trắng trên `#5569FF` đo 4,33:1, trên `#6E759F` 4,46:1 — mà
lấy giá trị đầu tiên **của chính họ Tokyo** vượt sàn: `primary.dark`
(`#4454CC`, 6,20:1) và `secondary.dark` (`#585E7F`, 6,32:1), đều là tone ~41.
Dark `primary` là tone 80 của palette đó (`#BCC2FF`); dark accent riêng của Tokyo
(`#8C7CF0`) bị loại vì lệch 15,4° so với hue light và ink tone-20 trên nó chỉ
đạt 3,89:1. Mọi container, `on*` và `inverse*` của hai họ **giữ tone và chroma,
chỉ đổi hue** — nên bậc so với `surfaceContainer` và mọi tỉ lệ nằm trong 0,1 L\*
so với trước. Hệ quả cấu trúc duy nhất: `secondaryContainer` dark rời họ surface
(hue 230 so với 246), nên `surfaceContainerHighest` dark dẫn xuất từ
`surfaceEmphasis` thay vì từ nó — bậc thang không dịch một pixel. `tertiary`,
`error`, bốn semantic và thang surface không đổi: Tokyo không có tertiary, màu
trạng thái của nó vượt ngân sách chroma, và thang surface là quyết định về chiều
sâu (mục 4) chứ không phải về thương hiệu.

**M100.26 mở rộng quyết định đó ra toàn bộ hệ màu — theme là Tokyo, không chỉ
hai họ accent.** Chủ dự án xác nhận đây là redesign toàn diện. Mỗi token nay là
một trong ba thứ: (1) **literal Tokyo** — trang `#F2F5F9` / `#070C27`, ink
`#223354` / `#CBCCD2`, bốn màu trạng thái `#57CA22` `#FFA319` `#FF1943`
`#33C2FF` ở dark, viền `#272C48`, `primary.main` làm cạnh chọn; (2) **primitive
Tokyo làm phẳng** theo đúng idiom `alpha.black` / `primary.lighter` của nó —
text phụ = ink @ 70 % trên paper, inset = ink @ 10 %, fill chọn = `lighten(primary,
.85)`; (3) **giá trị cũ đổi hue** sang key Tokyo, giữ tone và chroma — toàn bộ
thang dark (L\* 4,1 → 10,4 → 17,0 → 24,0 ở hue ~231 thay cho ~245), thang
`surfaceContainer`, container và `on*` của mọi họ, `tertiary` theo hue của
`info`. Bốn fill trạng thái ở light lấy hue và chroma Tokyo ở đúng tone cũ (~45),
vì literal Tokyo trên trang sáng đo 2–2,4:1.

Năm quyết định của AD này vẫn nguyên và **không luật đo nào phải nới**: seed vẫn
là gốc trung tính (nay hue 233), R3/R4/R9, sàn thang, trần bão hoà surface dark
(card 0,35 so với trần 0,42), tổng độ nổi card đều pass với giá trị mới. Hai thứ
đổi ở tầng luật: `borderControl` light hạ chroma về 0,047 để canvas sáng giữ trần
0,06 (Tokyo `text.secondary` mang 0,137); và **ngân sách chroma semantic bị thay**
— Tokyo cố ý để bốn màu trạng thái ở saturation 1,0, nên "info yên nhất, trần
0,85" đỏ ngay khi áp và trần nâng lên 1,0 thì không bắt được gì. Phần cấu trúc
giữ lại thành luật mới: bốn hue cách nhau ≥ 40°, không cái nào là grey; phần
tương phản đã có sàn riêng ở `app_theme_test.dart` và `app_ink_test.dart`.

**Bất biến từ M100.28 — binding canonical bị khoá; palette retune để đáp ứng
binding.** M100.27 thử làm ngược lại: khoá ba hex Tokyo (`primary`, trang, card)
rồi dời chỗ điều chỉnh sang on-colour, một token `primaryInk` cho chữ thương hiệu,
và hạ sàn nhãn nút light xuống 4,3. Chủ dự án bác toàn bộ hướng đó và đặt luật:

1. Material component dùng đúng canonical M3 role mà `_XxxDefaultsM3` của SDK
   ghim. `m3_role_binding_guard_test.dart` khoá bằng AST: TextButton foreground,
   OutlinedButton foreground, TabBar label → `primary`; không có "deliberate
   departure".
2. Canonical role không đạt contrast/hierarchy → sửa **hex/tone của role** ở
   palette layer. Không tạo token thay thế để component né role (đây là lần thứ
   hai `primaryAccent`/`primaryInk` bị gỡ — M100.18 và M100.28 — và lý do là một).
3. Không hạ ngưỡng accessibility để giữ một hex. Normal text ≥ 4,5:1, graphic và
   viền control ≥ 3:1. Không có "owner exception".
4. Tokyo là visual reference. Thứ tự ưu tiên: canonical mapping → accessibility →
   họ màu nhất quán → hex Tokyo nguyên bản. Trang và card có thể giữ nguyên hex
   vì chúng không phá hợp đồng nào; `primary` là role nhiều consumer nhất nên
   không được khoá.

Áp vào `primary`: `#5569FF` đo 4,33 dưới trắng và 3,96 làm chữ trên trang — hỏng
ba consumer canonical cùng lúc — nên **không hợp lệ** cho hợp đồng M3 primary;
giá trị kế tiếp trong chính họ Tokyo, `primary.dark` `#4454CC`, đạt mọi consumer
(6,20 / 5,67 / 5,19 tile / 4,58 ring trên `secondaryContainer`). Dark: `#8C7CF0`
(tone 58) đo 3,36 dưới trắng và 4,29 làm chữ trên tile → tone 80 của họ light
(`#BCC2FF`, 1,7° lệch) thay cho tone 80 của họ Tokyo-dark (`#C8BFFF`, lệch 15,5°
quá trần 12° của "một thương hiệu hai mode"). Cả họ (`onPrimary`, container,
`inversePrimary`, `*Fixed`) sinh lại từ hai key đó. Test tách hai tầng: **role
identity** (slot → role) không bao giờ đổi vì contrast; **palette quality** (role
→ hex → tỉ lệ) là nơi số được đo.

Những gì M100.27 đổi và vẫn đứng, vì có lý do tri giác độc lập chứ không phải để
hex pass: card dark `#111633` với rim Tokyo `0 0 2px #6A7199` làm cue chiều sâu
thứ hai (bậc ≥ 4 L\* **và** rim ≥ 3:1, đo tách theo mode); R9 miễn cho bốn role
là paper trắng của Tokyo; trần bão hoà surface dark 0,75. Những gì bị revert:
sàn 4,3, khoảng hue 16° (về 12°), `primaryInk`, `onPrimary` dark `#111633`.

### Nguồn của giá trị token đã đổi hai lần (M4.10p, rồi M100.83)

**Hiện tại: `lib/core/theme/` lại là nơi duy nhất định nghĩa một token.** Bộ kit
CSS đã bị xoá khỏi dự án ở M100.83 theo quyết định của chủ dự án, cùng lượt thay
toàn bộ 45 role màu. Không còn `design_system/` để đối chiếu, và cũng không còn
sáu test parity giữ hai bên bằng nhau.

Lý do là thứ đã đúng trên thực tế từ lâu trước khi được ghi ra: kit không còn là
nơi ra quyết định. Mọi retune từ M100.22 trở đi đều bắt đầu ở Dart — một phép đo
hỏng, một sàn WCAG trượt — rồi mới chép ngược sang CSS để test parity khỏi đỏ.
Một "nguồn chuẩn" chỉ nhận bản sao thì không phải nguồn; nó là một bản sao thứ
hai phải bảo trì, và nó tính phí đúng vào lúc palette đổi.

Đoạn dưới giữ lại làm bản ghi của giai đoạn M4.10p → M100.82, khi kit thật sự là
chuẩn.

---

Khi AD này được viết, `lib/core/theme/` là nơi duy nhất định nghĩa một token.
**Nay không còn.** Chủ dự án đưa một design system dựng ở claude.ai/design về
`design_system/` và quyết định: **`design_system/tokens/*.css` là chuẩn cho
*giá trị* token**. Dart lệch thì Dart sửa theo, không phải ngược lại.

Đổi *nguồn*, không đổi *luật*. Năm quyết định ở trên vẫn nguyên: seed vẫn là gốc
của mọi trung tính, chiều sâu vẫn là mục tiêu đo được, mọi thứ được vẽ vẫn phải
đến từ theme. Cái đổi là ai chọn con số điền vào.

Hai giới hạn, cả hai đều rút ra từ lần áp đầu tiên chứ không phải phòng xa:

- **Giá trị của design không tự nhất quán với văn xuôi của chính nó.**
  `design_system/readme.md` viết "danger carries the most saturation"; hex của nó
  làm `warning` to nhất ở light (0.801 so với 0.634). Khi hai nửa của design cãi
  nhau, giá trị thắng — vì giá trị là thứ được cho quyền — nhưng mâu thuẫn đó là
  của design, không phải của repo, và `app_palette_test.dart` ghi lại toàn bộ
  phép đo thay vì lặng lẽ nới luật.
- **Một giá trị đúng vẫn có thể bị dùng sai.** Lấy `--color-success` xong, một
  nhãn 14px tụt xuống **4.30:1** trên `secondaryContainer`. Strict visual audit
  bắt được, và lời giải cũng nằm trong design: `VerdictAction` của nó giữ nền
  trung tính "vì một lớp tint cùng hue với nhãn ăn mất tương phản đúng lúc nhãn
  quan trọng nhất". **Theo một token là theo cả cách design dùng nó, không chỉ
  mã hex.**

Nguyên tắc mang token về: **token đi cùng component cần nó, không đi trước.**
`--color-progress-*` và `--color-streak-container` đã về ở M4.12 cùng
`MxProgressBar` và due chip, và nay có counterpart trong `AppSemanticColors`.

Còn đúng **một** token cố ý chưa mang về: `--color-streak`. Nó là nhãn của màn
streak — màn đó chưa tồn tại — và nó còn là **hue thứ năm** (cam), nằm ngoài một
accent và bốn semantic mà chính readme của design cho phép. Due chip cần một
foreground nên `onStreakContainerLight` được dẫn xuất riêng: `--color-streak`
đo **3.12:1** trên container của chính nó ở 11px semibold, dưới ngưỡng 4.5 của
chữ nhỏ.

Danh sách này không còn được duy trì bằng tay. `css_token_parity_test.dart` bắt
mọi `--color-*` mà Dart chưa có lập trường — mang về, hoặc ghi lý do — nên một
token thêm vào kit sẽ làm đỏ test thay vì trôi qua im lặng.

### Đánh đổi đã nhận (toàn văn)

- **Tint làm card tối đi.** Bậc surface light tụt 3.46 → 2.15 L\*. Trả bằng shadow
  và bằng việc nới ngưỡng ladder, không phải bằng cách bỏ tint.
- **Precompute buộc phải chọn một nền.** `disabledSurfaceTint` blend trên
  `surface`, nên đúng ở form sheet và dialog, hơi sáng ở nút đặt thẳng trên page.
  Chính khoảng cách đó là lý do translucency tại điểm vẽ bị cấm.
- **Shadow và scrim được miễn trừ khỏi luật precompute**, vì nền của chúng theo
  định nghĩa là bất cứ thứ gì phía sau.

### Phương án đã bị loại

- **Nhận ceiling 1.6:1 cho border khi chưa có cue thứ hai** (bỏ ở M4.10f, nhận ở
  M4.10h) — hạ border trước khi có shadow là đổi một cái khung quá đậm lấy không
  có ranh giới nào.
- **Giữ card trắng thuần** (bỏ ở M4.10i) — nó là lựa chọn hợp lệ, nhưng nó để một
  surface duy nhất nằm ngoài hệ, và sau khi có shadow thì chi phí lightness không
  còn là lý do giữ.
- **Mở strict visual audit sang overlay** (bỏ ở M4.10m) — auditor duyệt một màn
  hình ở trạng thái nghỉ, trong khi một nửa render tree của overlay là nội dung
  người dùng đang bị cố ý ngăn không cho đọc. Làm nó xanh cần một danh sách
  allowance khẳng định chữ không đọc được là chấp nhận được.
- **Thêm tuỳ chọn surface cho `MxListTile`** (bỏ ở M4.10n) — không caller nào cần,
  và tấm ảnh mới là thứ sai chứ không phải component.
