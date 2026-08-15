# Wireframe · Progress by Deck v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt bố cục, hình học và ma trận trạng thái của drill-down tiến độ theo deck trước khi UI review chạy |
| **Scope** | Bộ chọn khoảng, bảng tổng, hàng deck và mọi trạng thái của hai cấp. Ngoài phạm vi: luật nghiệp vụ (`business-rules.md` BR-192…BR-199), luồng (`use-cases.md` UC-13), giá trị token (`lib/core/theme/`) |
| **Source of truth for** | Bố cục màn hình tiến độ · hình học được pin bằng test · danh sách divergence đã duyệt |
| **Depends on** | `document-conventions.md`, `business-rules.md` (BR-192…BR-199), `use-cases.md` (UC-13), `wbs.md` (M99.24) |
| **Updated by task** | M99.24 · rà soát UI/UX vòng một (bộ chọn ghim, gutter theo breakpoint, lưới gập, rung chữ số, chú thích đơn vị, AppBar ở mọi cấp) · hợp nhất `/progress` thành một màn (phần đầu tổng quan ở cấp thư viện) |
| **Last updated** | 2026-08-15 |

---

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID.

**Không có ảnh nguồn cho màn hình này.** Progress by Deck không đến từ một mockup
do chủ dự án cung cấp; nó được dựng lại từ **ngữ pháp thị giác đã có** của deck
list — cùng card, cùng lưới metric 2×2, cùng thang chữ. Đó là lựa chọn có chủ ý:
hai màn hình đọc cùng một cây dữ liệu, và một màn hình thống kê tự phát minh
kiểu trình bày riêng là cách nhanh nhất để người dùng thấy hai nơi khác nhau
đang nói về hai app khác nhau. Nơi nào cần một quyết định mới, §5 ghi nó ra.

## 1. Bố cục hai cấp

Cùng **một** màn hình ở mọi độ sâu — `deckId` null là cấp thư viện, id khác là
cấp của deck đó (UC-13). Từ trên xuống:

```
┌─────────────────────────────────────────┐
│ AppBar · "Tiến độ"  hoặc  tên deck      │
├═════════════════════════════════════════┤  ← từ đây trở xuống là vùng cuộn
│ ╭─ CHỈ Ở CẤP THƯ VIỆN ─────────────────╮│
│ │ Streak · Hôm nay · Hoạt động hằng ngày││ ← ba khối tổng quan (UC-12);
│ │ nội dung do m99-23-progress-overview ││    nguồn sự thật của chúng là
│ │ chốt, không lặp lại ở đây            ││    wireframe kia, không phải đây
│ ╰──────────────────────────────────────╯│
│                 xl                      │  ← ngắt section, không phải md
│  [✓ 7 ngày] [ 30 ngày ]                 │  ← bộ chọn: sliver GHIM, cuộn cùng
│                                         │    phần đầu rồi mới dính lên đỉnh
│ ┌─────────────────────────────────────┐ │
│ │ 7 ngày gần nhất                     │ │  ← bảng tổng (MxCard)
│ │ ▣ 45 thẻ đã học   ▣ 6 ngày có học   │ │
│ │ ▣ 12 học mới      ▣ 60 ôn tập       │ │
│ │ Học mới và ôn tập đếm theo thẻ-ngày │ │  ← đơn vị, nói đúng một lần
│ └─────────────────────────────────────┘ │
│                                         │  ← xl: ngắt giữa hai section
│ ┌─────────────────────────────────────┐ │
│ │ Spanish                          ›  │ │  ← hàng deck (MxCard, tappable)
│ │ Thư viện › Ngữ pháp                 │ │  ← đường dẫn, wrap chứ không cắt
│ │ ▣ 42 thẻ đã học   ▣ 6 ngày có học   │ │
│ │ ▣ 12 học mới      ▣ 60 ôn tập       │ │
│ └─────────────────────────────────────┘ │
│                 md                      │
│ ┌─────────────────────────────────────┐ │
│ │ Idle deck                        ›  │ │
│ │ ▣ 0 thẻ đã học    ▣ 0 ngày có học   │ │
│ │ ▣ 0 học mới       ▣ 0 ôn tập        │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│  Thư viện   Học   [Tiến độ]   Cài đặt   │
└─────────────────────────────────────────┘
```

**Phần đầu tổng quan chỉ tồn tại ở cấp thư viện, và nó thuộc vùng cuộn.**
`/progress` là một màn: `ProgressScreen` đọc tổng quan rồi trao ba khối cho màn
này qua tham số `header`, kể cả trên nhánh không có deck nào — nên một thư viện
rỗng vẫn thấy streak của mình. `/progress/:deckId` truyền `header` null và mở
thẳng vào bảng tổng. Hệ quả về hình học: khoảng cách trên của bảng tổng là `md` ở **mọi** cấp — dải
bộ chọn luôn đứng ngay trên nó và tự mang `xs` bên dưới, tổng 16 đúng như trước
khi dải chuyển vào vùng cuộn. (Bản đầu của lần chuyển này đặt `0` với lý do
`xl` dưới phần đầu đã là ngắt section, nhưng giữa hai thứ đó còn dải bộ chọn,
nên kết quả chỉ còn 4 và hai pill đọc như đang ngồi lên card.) G-series của tài
liệu này đo cấp deck (`header` null); hợp đồng geometry của ba section phần đầu
là của `m99-23-progress-overview.md`, và suite đo nó mount `ProgressScreen`,
tức **có** phần đầu.

Ba khối đó **không được mô tả lại ở đây**. Nội dung, copy và hình học của chúng
là của `m99-23-progress-overview.md`; tài liệu này chỉ chốt rằng chúng đứng ở
đâu trong thứ tự cuộn. Một fact ở đúng một chỗ (`document-conventions.md`).

**Bộ chọn khoảng được ghim — nhưng ghim từ bên trong vùng cuộn.** BR-197 nói
thẳng tới trường hợp năm mươi deck; cuộn hai màn thì một bộ chọn đã trôi mất sẽ
để lại một danh sách số không nói nó thuộc tuần hay tháng. Bản đầu dùng slot
`subheader` của `MxContentShell`, và slot đó nằm **trên** thân màn — nghĩa là
sau khi hợp nhất, bộ chọn đứng trên cả ba section tổng quan mà nó không điều
khiển: bấm `30 ngày` thì 24dp ngay dưới nó không đổi gì (X10). `PinnedHeaderSliver`
đặt **sau** phần đầu giữ đúng điều BR-197 cần — bộ chọn không rời màn khi danh
sách cuộn — mà bỏ được cách đọc sai.

`PinnedHeaderSliver` chứ không phải `SliverPersistentHeader`: dải này không có
chiều cao cố định. Riêng hàng pill đo được **48dp tới text scale 1.3 và 58dp ở
2.0**; cộng padding của `MxSubheaderBand` (`sm` trên, `xs` dưới; trên là `0`
dưới breakpoint compact) thì sliver là **60dp** ở bề rộng thường và **52dp** ở
320dp. Một delegate khai `extent` phải chọn một con số trong số đó và cắt phần
còn lại, đúng với người đang cần cỡ chữ lớn. Dải
dùng lại `MxSubheaderBand` — chính widget mà slot `subheader` dùng — nên luật
padding theo breakpoint chỉ tồn tại ở một chỗ. Nền của nó là `DecoratedBox` tô
`scaffoldBackgroundColor` — **màu trang, không phải `surface`** — để hàng deck
cuộn **dưới** nó mà không tan vào nó: `surface` chính là màu `MxCard` tô, chênh
với màu trang ΔL* 2.17 ở light và 6.38 ở dark, nên dải sẽ đọc như một card vuông
góc và hàng deck chui vào chỉ còn hairline 1px phân biệt.

**Không có breadcrumb.** Đường dẫn sống trên từng hàng thay vì thành một dải
riêng phía trên. Lý do là hàng cũng chính là thứ TalkBack đọc: `Verbs, trong
Spanish › Ngữ pháp` là một câu trả lời đủ, còn `Verbs` thì không — và một dải
breadcrumb chỉ trả lời câu đó **một lần cho cả màn**, trong khi mỗi hàng lại
cần nó.

## 2. Hình học được pin

Mọi số dưới đây được đo bằng `getRect` sau layout trong
`test/features/progress/presentation/progress_deck_geometry_test.dart`. Chúng
được pin vì lỗi nằm ở **tổng** của hai file cùng padding đúng — không guard nào
quét literal thấy được.

| Đại lượng | Giá trị | Vì sao |
|---|---|---|
| Content gutter | `mxScreenGutter(context)` — 16, và 12 dưới 360 | Gutter chuẩn **phụ thuộc bề rộng**; viết cứng `AppSpacing.lg` làm màn này thụt sâu hơn Thư viện và Học 4px mỗi bên ở 320dp, đúng 8px mà ô metric đang thiếu |
| Cạnh trái/phải của bộ chọn · bảng tổng · hàng | **bằng nhau** | Hai file sở hữu hai gutter; lệch 4px đọc như danh sách bị thụt vào so với bảng ở trên |
| Bảng tổng → hàng đầu | `AppSpacing.xl` (24) | Ngắt giữa hai **section**; dùng `lg` sẽ làm bảng đọc như hàng đầu của danh sách |
| Hàng → hàng | `AppSpacing.md` (12) | Khoảng cách trong một danh sách |
| Padding trong card | `AppSpacing.lg` (mặc định của `MxCard`) | Không ghi đè |
| Tên → đường dẫn | `AppSpacing.xs` (4) | Hai dòng của cùng một khối |
| Khối tiêu đề → lưới metric | `AppSpacing.md` (12) | Hai khối trong một card |
| Cột metric | hai nửa `Expanded`, cách nhau `AppSpacing.lg` | Cột phải giữ nguyên cạnh trái xuống cả hai hàng; intrinsic sizing để chữ dài kéo lệch |
| Ngưỡng gập lưới | `ProgressMetricGridWidget.minimumCellWidth` (90) **nhân theo `textScaler`** | Một dãy chữ số **không có điểm ngắt dòng**: ô hẹp hơn nhu cầu thì số bị **cắt**, không wrap — và một con số bị cắt là một con số khác. Ở 320dp scale 2.0 lưới gập xuống một cột thay vì cắt `1234` thành `123` |
| Rung chữ số | panel `titleMedium`, hàng `titleSmall` | Cùng họ chữ (Inter) và cách nhau đúng một rung — `titleLarge` là rung của họ *display*, nên hai bậc lệch nhau cả typeface. Hàng ở `titleSmall` cũng để tên deck (`titleMedium`) thắng bốn con số cạnh nó |
| Baseline hàng metric | `CrossAxisAlignment.baseline` | Ở text scale lớn hai ô cao khác nhau; căn top làm chữ số nhấp nhô |
| Tap target hàng | ≥ `AppSpacing.minimumTouchTarget` (48) | Sàn chạm |
| Đường dẫn dài | wrap, **không** ellipsis | Cắt giữa đường dẫn là mất đúng thứ nó tồn tại để nói |
| Khoảng thở đáy | `AppSpacing.xxl` dưới hàng cuối | **Không phải** clearance cho bottom bar: `Scaffold` đã trừ chiều cao thanh bar khỏi `MediaQuery` của body, nên không hàng nào nấp được sau nó và một test khẳng định điều đó thì không bao giờ đỏ. Cái đáng pin là chính khoảng inset — danh sách kết thúc sát thanh bar đọc như bị cắt ngang |

## 3. Ma trận trạng thái

| Trạng thái | Bộ chọn | Bảng tổng | Thân |
|---|---|---|---|
| loading | — | — | spinner có nhãn; AppBar giữ chữ "Tiến độ" ở **mọi** cấp (§5). Ở cấp thư viện, ba section tổng quan **vẫn ở trên** spinner — chúng đã trả lời rồi, và `/progress` chỉ dựng màn này sau khi chúng trả lời |
| mixed activity | có | có | mọi deck, kể cả deck 0 |
| all-zero | có | có + dòng giải thích | mọi deck với số 0 (BR-197) |
| no decks (cấp thư viện) | **không** | **không** | empty state, không nút |
| no sub-decks (cấp deck) | có | có | empty state nói tổng ở trên đã là toàn bộ |
| read error | — | — | `MxErrorState` + `Try again`, dưới AppBar còn nguyên; ở cấp thư viện ba section tổng quan vẫn ở trên nó, và khối lỗi mang `liveRegion` vì nó không còn chiếm cả màn nên có thể nằm dưới fold |
| deck missing | — | — | `MxEmptyState` + đường quay lại, **không** retry. Chỉ xảy ra ở `/progress/:deckId`, nơi không có phần đầu |

Hai dòng đáng chú ý:

- **all-zero không phải empty.** Bản dựng đầu thay danh sách bằng một empty
  state và đó là sai: một cấp chưa học gì vẫn có deck, và "mình đã bỏ bê deck
  nào" chính là câu hỏi người ta hỏi ở trạng thái đó.
- **no decks bỏ cả bộ chọn lẫn bảng tổng.** Không có deck thì không có khoảng
  nào để có gì xảy ra trong đó; giữ lại cả hai là ba cách nói cùng một sự trống.

## 4. Màu và tín hiệu

- **Số 0 trung tính, không bao giờ mang sắc thái lỗi.** Ô metric rỗng rơi về
  `onSurfaceVariant` trên `surfaceMuted`, giữ nguyên glyph. Một tuần yên ắng là
  một lần đọc bình thường.
- **Màu không bao giờ là tín hiệu duy nhất.** Mỗi ô nói số và chữ; màu chỉ tách
  "có gì đó" khỏi "không có gì", điều mà chính con số đã nói.
- **Pill được chọn mang thêm dấu tick.** `chipTheme` tắt checkmark của Material
  cho pill lọc của card list, nên ở đây pill được chọn tự mang `Icons.check`:
  nền, viền và glyph cùng nói một điều, và ảnh chụp greyscale vẫn đọc được.
- Vai trò màu: thẻ đã học và học mới dùng `info`; ngày có học dùng cặp
  `streakContainer/onStreakContainer` — từ vựng sẵn có của app cho "thời gian
  giữ được"; ôn tập trung tính vì ôn là trạng thái bình thường của một lịch
  đang chạy.
- **Hai đơn vị trong một lưới, và chỉ một dòng nói ra.** Hàng trên đếm *thẻ* và
  *ngày*; hàng dưới đếm *thẻ-ngày* (BR-193, BR-196). Không có dòng chú thích thì
  `12` và `60` cạnh `45` đọc như một phép cộng không khớp. Chú thích nằm ở bảng
  tổng chứ không nhét vào bốn từ, vì một từ đủ dài để mang đơn vị sẽ bị cắt
  trong ô 320dp ở scale 2.0 — xem §2.

## 5. Divergence đã duyệt

Những chỗ màn hình này cố ý khác deck list, và vì sao:

| Divergence | Lý do |
|---|---|
| Không breadcrumb; đường dẫn nằm trên hàng | §1 |
| Lưới metric 2×2 thay vì hero 2×2 + workload line | Bốn số ở đây không có thứ tự khẩn cấp; không số nào "dẫn" |
| Không filter, không sort control | Thứ tự là một rule (BR-197), không phải lựa chọn xem |
| Không nút hành động ở hai empty state "không có gì để liệt kê" | Bước tiếp theo nằm ở tab khác; nút nhảy tab đọc như đường vòng. **Không** áp cho state deck-missing: nó có đường quay lại, vì đó là lối ra duy nhất còn đúng (§3, UC-13 E2) |
| Bộ chọn khoảng là chrome ghim, không cuộn | §1 |
| Đơn vị thẻ-ngày nói bằng một dòng chú thích, không nhét vào tên metric | §4 — chiều rộng ô ở 320dp scale 2.0 |
| Lưới metric gập một cột khi ô quá hẹp | §2 — số bị cắt là số sai |
| AppBar giữ chữ "Tiến độ" ở mọi cấp khi dữ liệu chưa về | Tiêu đề null làm `MxContentShell` bỏ luôn AppBar, mất cả nút back — chịu được lúc vào lần đầu, không chịu được ở mỗi lần reload (nửa đêm, resume) |
| Hàng không có nút Study | Màn hình này chỉ đọc (BR-198) |

## 6. Điều cố ý không dựng ở v1

Biểu đồ theo ngày, heatmap, so sánh hai khoảng, accuracy và streak — tất cả
thuộc BR-192 và cần định nghĩa riêng trước khi có hình. Một khung biểu đồ dựng
sẵn "để sau này điền" là cách chốt bố cục cho dữ liệu chưa ai định nghĩa.
