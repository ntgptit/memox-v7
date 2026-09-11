# Avatar — đặc tả component (chưa triển khai)

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Ghi lại hợp đồng component Avatar (ảnh hoặc initials, đại diện một danh tính) và ánh xạ nó sang token thật của app, làm sẵn cho ngày component này có caller đầu tiên |
| **Scope** | Bảng kích thước, ma trận trạng thái, ánh xạ token (size/shape/màu/chữ/icon) của Avatar. Ngoài phạm vi: bất kỳ implementation Dart nào (chưa được phép — xem §1), giá trị token gốc (AD-14, `ad-14-color-and-depth.md`), quyết định khi nào auth/profile domain mở (AD-03) |
| **Source of truth for** | Đặc tả component Avatar — bảng kích thước, ma trận trạng thái, ánh xạ token · Thuật toán chọn "seeded fill" cho một component nhận danh tính làm input |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-03, AD-14, AD-15, AD-19) · `design-system/v1-freeze.md` |
| **Updated by task** | — (khảo sát design-spec ngoài WBS; xem §0) |
| **Last updated** | 2026-09-12 |

---

## 0. Tài liệu này là gì, và không phải là gì

Đây là bản dịch một component contract (nguồn: MemoX HTML design kit, mục *C ·
Surfaces, cards & list items*) sang token thật của app, làm trước — **không có
use case nào trong `use-cases.md` gọi tới Avatar tại thời điểm viết**, và
`docs/wbs.md` không có task nào cho nó. Đây là việc chuẩn bị chủ đích, không
phải một lỗ hổng cần lấp.

**HTML design kit đã bị xoá** ở M100.83 (#541, "the CSS kit goes") — 79 file
dưới `design_system/` không còn trong cây làm việc. Mọi giá trị ở tài liệu này
đọc thẳng từ `lib/core/theme/` (như chính README đã xoá của kit từng khuyên:
*"going back to them will produce better work than reading this file alone"*),
không phải chép lại từ kit. Danh sách file đã đọc để viết tài liệu này:
`app_sizing.dart`, `app_icon_size.dart`, `app_radius.dart`, `app_typography.dart`,
`app_breakpoints.dart`, `app_spacing.dart`, `app_stroke.dart`, `app_elevation.dart`,
`app_color_scheme.dart`, `app_semantic_colors.dart`, `app_ink.dart`, `mx_icon.dart`,
`app_glyph_register.dart`, `mx_list_tile.dart`, `mx_badge.dart`, `text_scale.dart`.

**Bản "MemoX Foundations spec" mà prompt gốc yêu cầu chạy trước không tồn tại
ở dạng đã commit** — không có file, không có PR, không có branch nào đã
diverge mang nội dung đó. Tài liệu này tự đóng vai trò đó bằng cách trích
thẳng từ nguồn, thay vì chờ một phiên khác.

## 1. Vì sao component này chưa có caller, và MUST NOT có caller từ tài liệu này

Ba lớp bằng chứng, từ yếu nhất đến mạnh nhất:

1. HTML kit (đã xoá) từng liệt Avatar vào *"Not built, because the source has
   no counterpart"*, và liệt riêng *"a profile avatar"* vào mục *"What is
   deliberately absent"* của `ui_kits/memox-app/README.md` — cả hai vì
   *"the app is local-first with no auth, so there is no name, no avatar and
   no sign-out to show."* Đây là ghi chú lịch sử của một tài liệu đã xoá, giữ
   lại ở đây chỉ để biết lý do bắt đầu.
2. **AD-03 · Auth-ready, chưa có auth** (accepted): *"Không có màn login,
   không có `AuthRepository`, không có token storage. Chưa dùng được thì chưa
   xây."* `lib/features/` không có thư mục `profile`.
3. **AD-19 · Scaffold bốn navigation branch top-level** (accepted), nguyên
   văn: *"MUST NOT có tab Profile chừng nào chưa có auth/profile domain
   (AD-03)."* Đây là ràng buộc MUST đang sống trong tài liệu kiến trúc hiện
   hành, không phải suy diễn từ lịch sử.

**Tài liệu này KHÔNG mở khoá việc implement.** Nó là đặc tả chờ sẵn — xem §7
cho điều kiện mở khoá thật. Một task feature đọc thấy tài liệu này MUST NOT
suy ra rằng Avatar đã được duyệt để có widget, provider hay bất kỳ file
`lib/` nào.

## 2. Hợp đồng component (từ prompt gốc — binding)

**Mục đích.** Account identity — ảnh hoặc initials fallback.

**Ba lớp nội dung, mỗi lớp một class:**

| Nội dung | Class | Ý nghĩa |
|---|---|---|
| `image` | CONTENT-DRIVEN | Có ảnh thật — ảnh lấp đầy hình tròn |
| `initials` | CONTENT-DRIVEN | Không có ảnh, có danh tính (tên/chuỗi) để rút initials |
| `placeholder` | CONTENT-DRIVEN | Không ảnh, không danh tính khả dụng |

**Kích thước — FIXED, ba bước:**

| Bước | dp |
|---|---|
| dense | 32 |
| compact | 40 |
| prominent | 48 |

FIXED nghĩa là tái tạo đúng giá trị — không phải MINIMUM (không được co giãn
theo nội dung) và không phải RESPONSIVE (không tự đổi theo breakpoint hay text
scale; xem §3.7).

**Ma trận trạng thái, từ prompt gốc:**

| Trạng thái | Vẽ |
|---|---|
| `default` | initials trên một seeded fill |
| `image` | ảnh lấp đầy hình tròn |

**`placeholder` không có dòng trong ma trận trạng thái gốc — đây là khoảng
trống thật, không phải một trạng thái được suy ra an toàn.** Bảng kích thước
liệt nó như một content class nhưng mock không vẽ nó. §3.5 đề xuất một cách
vẽ nhất quán với ngôn ngữ thiết kế hiện có; đây là một điểm [cần xác nhận từ
chủ dự án] trước khi implement, không phải một quyết định đã chốt.

**Icon.** Kit cho một glyph, `user` (tên Lucide, vì bản HTML preview không có
Material Symbols). Ánh xạ theo nghĩa, không theo tên: `user` → Material Symbol
**`person`**, outlined ở trạng thái nghỉ — theo đúng quy ước một nghĩa một
glyph một kiểu vẽ của `app_glyph_register.dart` ("outlined Material, never
`_rounded`"). Component này không có trạng thái "selected/active" nên không
cần biến thể filled của glyph.

## 3. Ánh xạ token — mọi giá trị đọc từ `lib/core/theme/`, không giá trị nào bịa ra

### 3.1 Kích thước — tái dùng `AppSizing`, không thêm hằng số mới

32 / 40 / 48 **trùng số** với ba hằng số đã có trong `AppSizing`
([app_sizing.dart](../../lib/core/theme/foundations/app_sizing.dart)):

| Bước Avatar | Hằng số có sẵn | Giá trị |
|---|---|---|
| dense | `AppSizing.controlDense` | 32 |
| compact | `AppSizing.controlCompact` | 40 |
| prominent | `AppSizing.touchTarget` | 48 |

Đây MUST là tái sử dụng, không phải trùng hợp bịa ra ba hằng số mới
(`avatarSm`/`avatarMd`/`avatarLg`). `AppSizing`'s doc comment nói rõ lý do file
này tồn tại — "Every value here already existed; none is new" — và Avatar
không phải ngoại lệ đầu tiên đáng có. `controlCompact` và `touchTarget` vốn đã
mang đúng ngữ nghĩa cần: `controlCompact` là "a control that draws smaller
than the target it keeps" — Avatar đặt trong một hàng dày hơn touch target
đúng là ca đó; `touchTarget` là sàn 48dp — nếu Avatar từng trở thành bấm được
(đổi ảnh, mở hồ sơ), 48 đã sẵn là con số đúng mà không cần quyết định lại.

### 3.2 Hình khối — hình tròn thật, khác thang `AppRadius` hiện có

**Avatar là mặt tròn tuyệt đối đầu tiên của app.** Toàn bộ `AppRadius`
([app_radius.dart](../../lib/core/theme/foundations/app_radius.dart)) hiện chỉ
tạo hình chữ nhật bo góc — kể cả `AppRadius.pill = 999` cũng là một hình chữ
nhật có bán kính lớn hơn nửa cạnh ngắn, đúng bằng hình tròn *chỉ khi* hộp là
hình vuông. Với hộp vuông 32×32 / 40×40 / 48×48, `BorderRadius.circular(999)`
và `ClipOval`/`CircleBorder` cho ra cùng một pixel — nên không cần một token
hình học mới, nhưng việc vẽ MUST đi qua `ClipOval` hoặc `CircleBorder`
(hình tròn đúng nghĩa), không phải mượn `AppRadius.pill` như một góc bo — nếu
sau này Avatar không vuông (ví dụ ảnh tỉ lệ khác được crop), một "góc 999"
trên hộp không vuông không còn là hình tròn.

### 3.3 Màu nền "seeded fill" — tập đóng ba container role, không hue nào bịa ra

AD-14 nguyên tắc 5: *"Mọi thứ được vẽ phải đến từ theme của app"*; nguyên tắc
2: *"Mỗi role là một hue qua một bộ sinh"*. `AppSemanticColors`
([app_semantic_colors.dart](../../lib/core/theme/foundations/app_semantic_colors.dart))
không có một họ "seed palette" rời cho một danh tính bất kỳ — chỉ có các role
ngữ nghĩa cố định (streak, progress, success/warning/danger/info). Việc thêm
một họ hue mới cho riêng Avatar là **thêm một họ shared primitive mới**, tức
điều kiện mở lại #3 của `v1-freeze.md` §3 — ngoài phạm vi một tài liệu chưa có
implementation.

**Đề xuất: giới hạn "seeded fill" vào đúng ba cặp container role M3 đã có
sẵn**, đã tồn tại trong `ColorScheme` và đã có `AppInk` khớp cho chữ trên nó —
không cần thêm gì:

| Bucket | Fill | Ink cho initials (đã có trong `AppInk`) |
|---|---|---|
| 0 | `colorScheme.primaryContainer` | `AppInk.onPrimaryContainer` |
| 1 | `colorScheme.secondaryContainer` | `AppInk.onSecondaryContainer` |
| 2 | `colorScheme.tertiaryContainer` | `AppInk.onTertiaryContainer` |

Ba bucket, không phải bốn hay năm — vì đó là toàn bộ tập `*Container` M3
"trung tính về nghĩa" mà app có (đã cố ý không tính `errorContainer` /
`successContainer` v.v., vì các role đó mang nghĩa trạng thái — lỗi, thành
công — và một avatar được tô đỏ sẽ đọc thành "avatar báo lỗi"). Trang Lists
của M3 (m3.material.io/components/lists) tự liệt "Primary container / On
primary container" là một cặp role dùng cho list, củng cố rằng đây không phải
lựa chọn ngẫu nhiên.

**Thuật toán chọn bucket — MUST NOT dùng `Object.hashCode` / `String.hashCode`
làm seed.** Dart không cam kết hai giá trị này ổn định qua các phiên bản SDK
hay giữa các build — một avatar đổi màu sau khi nâng cấp Flutter là một hồi
quy trực quan mà không test nào bắt được (không phải bug logic, chỉ đổi màu).
Seed MUST là một hàm tường minh, ổn định do app tự định nghĩa — ví dụ tổng
`codeUnits` của chuỗi danh tính, modulo 3 — viết một lần trong `data/` hoặc
`domain/` của feature dùng nó, không phải gọi thẳng `hashCode`.

### 3.4 Chữ initials — rung nào theo từng size, và vì sao KHÔNG được co theo text scale

Ba rung có sẵn trong `AppTypography`
([app_typography.dart](../../lib/core/theme/typography/app_typography.dart)),
chọn theo tỉ lệ ~40–44% đường kính — không phải số bịa, là tỉ lệ đọc lại từ
rung có sẵn gần nhất:

| Avatar | Rung | Cỡ chữ | Family | Tỉ lệ/đường kính |
|---|---|---|---|---|
| 32 (dense) | `labelLarge` | 14sp, w600 | Inter | 43.8% |
| 40 (compact) | `titleMedium` | 16sp, w600 | Inter | 40.0% |
| 48 (prominent) | `titleLarge` | 22sp, w600 | Plus Jakarta Sans | 45.8% |

**Điểm cần chủ dự án xác nhận:** `titleLarge` là rung display-face duy nhất đủ
lớn cho bước 48, nên initials ở bước prominent đổi font family (Inter →
Plus Jakarta Sans) so với hai bước kia. Đây có thể đọc như một chủ đích —
"kích thước nổi bật nhất mượn giọng thương hiệu" — hoặc như một bất nhất
không mong muốn. Phương án giữ một family xuyên suốt là trần ở `titleMedium`
(16sp/Inter) cho cả ba bước, đánh đổi bằng tỉ lệ chữ/đường kính co lại còn
33% ở bước 48 — nhỏ hơn nhưng không phá layout. Tài liệu này không tự chốt
thay.

**MUST: initials text không phản ứng theo cài đặt text scale của hệ thống —
`Text.textScaler` của initials MUST cố định ở `TextScaler.noScaling`, hoặc
tương đương.** Đây là ca đầu tiên của app cần một hộp tròn đường kính CỐ ĐỊNH
chứa chữ — không giống `MxBadge` (pill tự giãn rộng theo chữ) hay bất kỳ chip
nào khác trong `lib/shared/widgets/`, vốn luôn để container lớn theo nội dung.
Ở text scale 2.0 (cỡ bộ test màn hình của app dùng, theo doc comment của
`AppBreakpoints.compact`: *"Screen tests run at 360x640 now, at `textScaler`
2.0"*), `titleMedium` 16sp thành 32sp — hai ký tự ở cỡ đó không còn vừa một vòng tròn
40dp bằng bất kỳ cách nào ngoài tràn ra ngoài. Vì kích thước Avatar là FIXED
theo hợp đồng ở §2 (không phải MINIMUM), chữ MUST nhường, không phải hộp —
đúng như một tấm ảnh đại diện không "phóng to" theo cỡ chữ hệ thống.

### 3.5 Icon placeholder — vẽ khi không có ảnh và không có danh tính để rút initials

Không có state trong ma trận gốc cho ca này (§2). Đề xuất, nhất quán với ngôn
ngữ hiện có thay vì bịa mới:

- Glyph: `person` outlined qua `MxIcon` (§2's mapping), không phải một `Icon`
  trần — component đứng độc lập trên nền riêng, đúng ca `MxIcon`'s doc comment
  mô tả là hợp lệ ("the icon that stands on its own ground").
- Kích thước glyph: `MxIconSize.mdCompact` (20) cho bước 32, `MxIconSize.md`
  (24) cho cả bước 40 và 48 — không phải bốn bước ăn khớp bốn bước Avatar, vì
  `MxIconSize.lg` (40) gần bằng nguyên đường kính 48, không còn margin. 24/40 =
  60%, 24/48 = 50%, cả hai nằm trong dải một glyph "well" dễ đọc.
- Nền: `semanticColors.surfaceMuted` (vai trò trung tính, không thuộc palette
  seeded — vì không có danh tính để seed) với ink `AppInk.quiet` cho glyph —
  cùng cặp `MxBadge` đã dùng cho một nhãn "không tốt không xấu".

### 3.6 Độ sâu — `AppElevation.none`, phẳng như mọi thứ khác

`AppElevation.none = 0`: *"Flush with the surface behind it. The default for
everything."* Không có gì trong hợp đồng §2 gọi Avatar là "a surface
deliberately lifted above its neighbours" (điều kiện duy nhất `AppElevation`
có bước khác 0), và tinh thần "flat colour, everywhere" ở nền tảng thiết kế
app áp dụng nguyên cho một huy hiệu nhỏ. Không cần bóng, không cần viền trang
trí mặc định — nếu một ngữ cảnh cụ thể sau này cần viền (ví dụ một trạng thái
"đang tải ảnh"), đó là quyết định của ngữ cảnh đó, không phải của component.

### 3.7 Responsive — component không tự phản ứng breakpoint; người gọi chọn size

`AppBreakpoints.compact = 360` và `.medium = 600`
([app_breakpoints.dart](../../lib/core/theme/foundations/app_breakpoints.dart))
không có nhánh nào Avatar cần tự rẽ: kích thước là FIXED theo §2, nghĩa là
**màn hình/hàng gọi Avatar chọn một trong ba bước theo vị trí nó đặt vào**
(ví dụ: 32 trong một hàng dày đặc, 40 trong một `MxListTile.leading` tiêu
chuẩn, 48 trong một header nổi bật) — giống hệt cách `AppSizing.controlDense`
/`.controlCompact` đã được dùng ở nơi khác trong app hôm nay. Avatar tự nó
không đọc `MediaQuery` để đổi bước.

## 4. Composition — ghép vào layout hiện có thế nào

`MxListTile` ([mx_list_tile.dart](../../lib/shared/widgets/mx_list_tile.dart))
nhận `leading` như một `Widget?` chung chung — "Deliberately generic... not a
deck or a card." Avatar composes như bất kỳ widget nào khác truyền vào đó,
không cần một slot riêng hay một thay đổi hợp đồng của `MxListTile`. Khoảng
cách giữa Avatar và nhãn cạnh nó (nếu ghép thủ công ngoài `MxListTile`, ví dụ
trong một header) dùng `AppSpacing.sm` (8, "between tightly related items in a
row") — không phải `AppSpacing.lg` (16, gutter màn hình), vì Avatar và tên
cạnh nó là một cặp gắn chặt, không phải hai khối độc lập.

Không cần một shell, provider hay primitive mới để compose — đây là lý do
điều kiện mở lại #3 của `v1-freeze.md` §3 (xem §7 dưới) nói về việc **thêm**
một họ primitive, không phải việc dùng nó trong layout.

## 5. SYSTEM-OWNED / không copy nguyên văn từ HTML kit

Từ prompt gốc, dịch sang ngữ cảnh app (không có gì trong danh sách này từng
tồn tại như code Dart — đây là rào chắn cho khi implement, không phải mô tả
hiện trạng):

- **SYSTEM-OWNED, không tự vẽ:** status bar, cutout, gesture/nav inset,
  keyboard inset, nút Back hệ thống, khung thiết bị — không cái nào liên quan
  trực tiếp Avatar, ghi lại để implementer sau không tự hỏi lại.
- **Không copy nguyên văn từ HTML/JSX** (không áp dụng cho Flutter, nhắc lại
  cho implementer chưa quen kit cũ): absolute positioning, `::after` hit
  expander, `backdrop-filter`, `color-mix` overlay, hover state kiểu web, fake
  system chrome, hộp pixel cố định quanh chữ.

## 6. Câu hỏi mở — cần chủ dự án xác nhận trước khi có task implement

1. **`placeholder` state (§2, §3.5)** — mock gốc không vẽ trạng thái này; đề
   xuất ở §3.5 là suy luận từ ngôn ngữ thiết kế hiện có, không phải điều đã
   xác nhận.
2. **Family-switch ở bước 48 (§3.4)** — `titleLarge` (Plus Jakarta Sans) làm
   initials 48dp khác family với hai bước kia. Cần một quyết định, không phải
   một mặc định do tài liệu này chọn.
3. **Thuật toán seed cụ thể (§3.3)** — tài liệu này chỉ ràng buộc "không phải
   `hashCode`" và "ba bucket cố định"; hàm băm tường minh (tổng `codeUnits`,
   hay khác) chưa được chọn, vì chọn nó là việc của task implement, có test
   giữ lại kết quả.
4. **Avatar có bao giờ bấm được không** (đổi ảnh, mở hồ sơ)? Nếu có, bước 48
   trùng `AppSizing.touchTarget` không phải trùng hợp — nhưng hai bước 32/40
   khi đó cần `MaterialTapTargetSize.padded` như cách `AppSizing.controlCompact`
   đã được dùng ở nơi khác, và cần một focus ring theo đúng cơ chế
   `tokyo-component-mapping.md` §8 đã thống nhất cho mọi control khác — chưa
   có gì trong hợp đồng §2 nói Avatar là control.

## 7. Điều kiện để mở khoá triển khai

Ba điều, MUST đều đúng trước khi một task feature được viết code cho Avatar:

1. **AD-03's auth/profile domain phải tồn tại** — Avatar không có danh tính
   thật để hiển thị chừng nào app còn đúng một local profile ẩn danh.
2. **AD-19's gate phải mở** — một tab/route Profile phải được quyết định trước
   khi có màn hình thật để đặt Avatar vào.
3. **Một task design-system riêng, theo `v1-freeze.md` §3 điều kiện #3** (thêm
   một họ shared primitive mới) — `MxAvatar` sẽ là primitive đầu tiên vẽ hình
   tròn tuyệt đối trong app (§3.2), nên nó MUST đi qua đúng con đường mọi
   primitive mới khác đã đi, không phải được thêm lặng lẽ trong lúc làm một
   feature khác.

Tài liệu này không tự kích hoạt điều kiện nào ở trên. Nó tồn tại để khi cả ba
đều đúng, người viết `MxAvatar` không phải tự đo lại từ đầu.
