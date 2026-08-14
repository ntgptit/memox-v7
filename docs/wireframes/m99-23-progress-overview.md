# Wireframe M99.23 — Progress overview (streak · hôm nay · bảy ngày)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI, copy, geometry và ma trận trạng thái của màn Progress để M99.23 xây mà không phải đoán |
| **Scope** | Màn `/progress`: ba section, mọi state, hợp đồng geometry, responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-182…BR-191), luồng (UC-12), quyết định branch (AD-19) |
| **Source of truth for** | Anatomy màn Progress · copy ba section · hợp đồng geometry của màn Progress · responsive/a11y contract của màn Progress |
| **Depends on** | `../use-cases.md` (UC-12), `../business-rules.md` (BR-182…BR-191), `../architecture.md` (AD-19), `m4-11-card-management.md` |
| **Updated by task** | M99.23 (stage 1 của batch tích hợp #301–#310 — recursive UI/UX review vòng 1 và 2) |
| **Last updated** | 2026-08-14 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc nghiệp vụ tham chiếu
bằng ID theo `document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu
thuẫn thì BR đúng và wireframe sai.

Progress trả lời đúng ba câu, theo đúng thứ tự người dùng hỏi: **"tôi có đang
giữ nhịp không"** (streak), **"hôm nay tôi đã làm gì"** (Today), **"một tuần
vừa rồi ra sao"** (Last 7 days). Không có câu thứ tư trong v1 (BR-191).

## P-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| P1 | Màn hình **thay thẳng** placeholder trong branch Progress; MUST NOT thêm route, đổi path, đổi `RouteNames.progress` hay đổi branch index | Đó chính là tài sản AD-19 mua trước. Một route mới sẽ làm deep link cũ và test điều hướng phải sửa để đổi lấy đúng con số không | 2026-08-13 |
| P2 | Ba section là **ba `MxCard` xếp dọc**, cùng bề rộng nội dung, không lồng nhau, không tab, không carousel | Ba câu hỏi độc lập, đọc một lần từ trên xuống. Tab hay carousel giấu hai phần ba nội dung sau một thao tác để tiết kiệm chỗ mà màn này không thiếu | 2026-08-13 |
| P3 | Last 7 days dùng **bar ngang, mỗi ngày một hàng**, MUST NOT dùng cột dọc | Đo được: ở 320dp @ text scale 2.0, vùng nội dung còn `320 − 2×12 − 2×16 = 264dp`; bảy cột với sáu khe `sm` còn `≈30.9dp` mỗi cột, trong khi nhãn thứ (`Mon`, `T2`) ở 2.0 rộng hơn thế và một giá trị ba chữ số cũng vậy. Cột dọc chỉ sống được bằng cách cắt chữ hoặc thu font — hai thứ W6 cấm. Bar ngang còn cho mỗi ngày một hàng TalkBack đọc trọn vẹn | 2026-08-13 |
| P4 | Ngày có 0 hoạt động vẫn vẽ **track** đầy đủ chiều rộng, bar dài 0, và **luôn có số `0`** bên phải | Zero-fill là dữ liệu (BR-186), không phải chỗ trống. Một hàng biến mất đọc thành "không có ngày đó" | 2026-08-13 |
| P5 | Ý nghĩa MUST NOT chỉ nằm ở màu: Learning/Reviewing luôn có **nhãn chữ + số**, không chỉ hai chấm màu | WCAG 1.4.1. Hai vai màu của app phân biệt tốt ở cả hai theme, nhưng đó không phải lý do để bỏ nhãn | 2026-08-13 |
| P6 | Streak 0 dùng **lời mời trung tính**, MUST NOT dùng lời trách hay hình ảnh "chuỗi đã đứt" | Người mở Progress sau một ngày nghỉ không cần bị chấm điểm. Trung tính cũng là điều kiện để mặt này dùng lại được cho người chưa từng học | 2026-08-13 |
| P7 | Mặt **lifetime empty** thay **cả màn**, không phải ba section toàn số 0, và mang một CTA thật sang branch Study | Ba khối số 0 trông như lỗi đọc dữ liệu. CTA phải là điều hướng thật — một nút không đi đâu là một nút nói dối | 2026-08-13 |
| P8 | Live refresh và midnight rollover MUST NOT hạ màn về loading khi trên màn đã có dữ liệu | Cờ đúng ở đây là **`shouldSkipLoadingOnReload`**, không phải `skipLoadingOnRefresh`. Cả hai đường đều tới qua một **reload**: chúng đổi `progressNowProvider`, mà đó là dependency của controller — và đường thứ ba đổi nó là **mọi lần app resume**, thường xuyên hơn hẳn hai đường kia. `MxAsyncView` mặc định `skipLoadingOnReload: false` (đúng cho những màn mà dependency đổi nghĩa là câu hỏi đã đổi), nên `ProgressScreen` MUST opt-in `true` (prop trong Flutter tên là `shouldSkipLoadingOnReload`, theo quy ước boolean-đọc-thành-mệnh-đề của repo). Ghim ở `progress_screen_reload_test.dart`, và nó cần một repository phát emission **bất đồng bộ**: fake dùng chung yield seed đồng bộ nên assertion "không có spinner" xanh bất kể cờ nào (BR-189) | 2026-08-14 |
| P9 | Không kéo-để-làm-mới | Stream đã là nguồn sự thật và midnight đã có timer; một cử chỉ refresh cho dữ liệu tự cập nhật là affordance nói sai về cơ chế | 2026-08-13 |

## W-cấu trúc

### W1 — Khung màn

```
┌─ MxContentShell (title: Progress) ───────────────┐
│  AppBar · title                                  │
├──────────────────────────────────────────────────┤
│ ←gutter→ ┌────────────────────────────┐ ←gutter→ │
│          │  S1  Current streak (hero) │          │
│          └────────────────────────────┘          │
│                      ↕ xl                        │
│          ┌────────────────────────────┐          │
│          │  S2  Today                 │          │
│          └────────────────────────────┘          │
│                      ↕ xl                        │
│          ┌────────────────────────────┐          │
│          │  S3  Last 7 days           │          │
│          └────────────────────────────┘          │
└──────────────────────────────────────────────────┘
        (bottom navigation của AppNavigationShell)
```

Shell dùng `isScrollable: true`: ở 320dp @ 2.0 ba section cao hơn màn.

### W2 — S1 · Current streak (hero)

1. Nhãn section: `Current streak` / `Chuỗi hiện tại`.
2. Headline: **số ngày**, kiểu `displayLarge`, cộng đơn vị đọc được
   (`7 days` / `7 ngày`, dạng ICU plural).
3. Dòng phụ: số card **hôm nay** — `12 cards today` / `12 thẻ hôm nay`. Đây là
   cầu nối sang S2 và là lý do headline không cần tự giải thích.
4. Streak = 0: headline vẫn là số `0` với đơn vị — và nhãn screen reader nói đúng
   câu đó (`Current streak, 0 days` / `Chuỗi hiện tại, 0 ngày`), không rút gọn
   thành `No current streak`: mắt và trình đọc màn hình phải nghe cùng một thứ.
   Dòng phụ đổi thành lời mời
   trung tính — `Study today to start a streak` / `Học hôm nay để bắt đầu một
   chuỗi` (P6).
5. Streak giữ từ hôm qua (hôm nay chưa học, BR-187): headline giữ số ngày, dòng
   phụ nói rõ đang giữ — `No cards today — your streak is held from yesterday` /
   `Chưa có thẻ nào hôm nay — chuỗi đang được giữ từ hôm qua`. MUST NOT hiện `0`
   ở headline trong ca này.

   **Bản đầu viết `0 cards today · streak held from yesterday`, và đã sửa ở
   phase 7.** Hai lý do, cả hai lộ ra khi đọc ba section cạnh nhau: con số `0`
   lặp lại đúng con số S2 vừa nói, nên nó đọc thành một chỉ số thứ hai chứ không
   phải một lời giải thích; và dấu `·` nối hai mệnh đề không cùng loại — một số
   đo và một lời trấn an — trong khi một câu hoàn chỉnh nói được quan hệ nhân
   quả giữa chúng. Copy đang chạy là bản canonical.

### W3 — S2 · Today

1. Nhãn section: `Today` / `Hôm nay`.
2. Số tổng, kiểu `headlineSmall`, kèm đơn vị **card** viết rõ — `8 cards` /
   `8 thẻ`. Đơn vị bắt buộc xuất hiện vì đơn vị đếm là card-day chứ không phải
   lượt (BR-182), và người dùng không đoán được điều đó.
3. Hai dòng phân rã, mỗi dòng `nhãn · số`: `Learning` / `Đang học` và
   `Reviewing` / `Đang ôn` (BR-185). Hai dòng luôn hiện, kể cả khi bằng 0.
4. Một dòng chú thích nhỏ nói phép cộng: `Learning + Reviewing = total cards
   answered today`. Không phải trang trí — nó là thứ ngăn người dùng cộng nhầm
   sang "số lượt".

### W4 — S3 · Last 7 days

```
Last 7 days
┌──────────────────────────────────────────────┐
│ Mon  ▉▉▉▉▉▉▉▉░░░░░░░░░░░░░░░░░░░░░░░   12    │
│ Tue  ▉▉▉▉░░░░░░░░░░░░░░░░░░░░░░░░░░░    6    │
│ Wed  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    0    │
│ ...                                          │
│ Today ▉▉▉▉▉▉░░░░░░░░░░░░░░░░░░░░░░░░    8    │
└──────────────────────────────────────────────┘
```

1. Đúng **bảy** hàng, thứ tự cũ → mới, hàng cuối là hôm nay (BR-186).
2. Cột nhãn: tên thứ viết tắt theo locale; hàng cuối dùng `Today` / `Hôm nay`
   thay cho tên thứ.
3. Cột bar: `track` chiếm trọn bề rộng còn lại, `fill` tỉ lệ với giá trị chia
   cho giá trị lớn nhất trong bảy ngày. Mọi ngày đều có track (P4).
4. Cột giá trị: số, canh phải, luôn hiện kể cả `0`.
5. Giá trị lớn nhất bằng 0 (cả bảy ngày trống nhưng vẫn còn hoạt động ngoài cửa
   sổ) → mọi `fill` dài 0; MUST NOT chia cho 0.

### W5 — Hợp đồng geometry (đo bằng `tester.getRect`)

| # | Ràng buộc | Giá trị |
|---|---|---|
| G1 | Screen gutter | `mxScreenGutter` — `AppSpacing.lg` (16), `AppSpacing.md` (12) dưới `AppBreakpoints.compact` |
| G2 | Shared left edge | `left` của S1, S2, S3 **bằng nhau**, và bằng gutter |
| G3 | Shared right edge | `right` của S1, S2, S3 **bằng nhau**, và bằng `screenWidth − gutter` |
| G4 | Section width | Cả ba bằng nhau, bằng `screenWidth − 2×gutter`. MUST NOT co theo intrinsic width của nội dung |
| G5 | Internal padding | `MxCard` mặc định `AppSpacing.lg` (16) bốn phía |
| G6 | Vertical rhythm giữa các section | `AppSpacing.xl` (24), đo giữa `bottom` của section trên và `top` của section dưới |
| G7 | Nhịp trong một section | Nhãn → nội dung chính `AppSpacing.sm` (8); giữa các dòng phân rã `AppSpacing.xs` (4) |
| G8 | Chart baseline | `left` của **mọi** track trong S3 bằng nhau — đây là baseline của biểu đồ |
| G9 | Chart row gap | Khoảng cách dọc giữa hai hàng ngày liền nhau `AppSpacing.sm` (8), bằng nhau ở cả sáu khe. **Đo ở cột nhãn**, không đo ở track: `TableCellVerticalAlignment.middle` căn giữa mỗi cell trong một hàng cao bằng cell cao nhất — là nhãn — nên hai track cao 6dp trôi trong hàng ~20dp và khoảng cách giữa chúng không phải `sm`, cũng chưa bao giờ định là `sm`. Ngoài ra pitch giữa các track MUST bằng nhau ở cả sáu khe, vì đó mới là thứ người đọc thấy là "đều" |
| G10 | Chart bar width | `right` của mọi track bằng nhau; bề rộng track bằng nhau ở cả bảy hàng |
| G10a | Chart bar height | `MxProgressBarSize.sm.trackHeight` (6), lấy từ chính token đó chứ không viết lại số |
| G11 | Safe area | Nội dung nằm trong `SafeArea` của `MxContentShell`; `top` của S1 ≥ `bottom` của AppBar |
| G12 | Bottom-nav clearance | `bottom` của S3 khi cuộn hết ≤ `bottom` của body. `AppNavigationShell` là `Scaffold` có `bottomNavigationBar`, nên chiều cao thanh đã bị trừ khỏi `MediaQuery` của body — không được cộng thêm inset thủ công, cộng thêm là thừa hai lần |

### W6 — Responsive, theme, a11y

1. Kiểm ở **320dp @ text scale 2.0**, **390dp** và **412dp**, EN và VI,
   light và dark. MUST NOT có overflow, MUST NOT clip, MUST NOT thu font để né
   tràn.
2. Text wrap MUST NOT làm đổi alignment: nhãn xuống dòng thì cột giá trị vẫn
   canh phải và track vẫn giữ baseline G8.
3. Mọi target chạm ≥ `AppSpacing.minimumTouchTarget` (48). Ở v1 chỉ có hai
   target: CTA của mặt empty và `Retry` của mặt lỗi.
4. TalkBack: S1 đọc một mệnh đề gộp `streak + hôm nay`, không đọc rời số và
   đơn vị. S3 đọc **mỗi ngày một node**, nội dung `<tên ngày>: <n> thẻ`; track
   và fill là trang trí (`ExcludeSemantics`).
5. Mặt lỗi có `liveRegion` để đổi từ loading sang error được đọc lên.
6. Chỉ dùng token của repo và widget `Mx*`. MUST NOT hardcode màu, spacing hay
   duration để vá ảnh render.
7. Bar của biểu đồ là **graphic**, nên fill so với track MUST đạt 3:1 (WCAG
   1.4.11). Đo được ở phase 7: **3.34:1** light (`progressFill` trên
   `progressTrack`) và **4.08:1** dark. `progress_chart_contrast_test.dart` ghim
   ngưỡng này, vì strict visual audit **không** nhìn thấy cặp màu đó —
   `NonTextContrastRule` chỉ soi paint mang vai `border`, còn track và fill là
   background.

### Divergence đã chấp nhận

| # | Điều lệch | Đo được | Vì sao chấp nhận |
|---|---|---|---|
| X1 | Track của biểu đồ rất nhạt so với mặt card | **1.27:1** light (`progressTrack` trên `surface`), **1.35:1** dark | Track là trang trí: mỗi hàng đã nói giá trị bằng chữ số và tên ngày, còn bar mang `ExcludeSemantics` (P5). WCAG 1.4.11 áp cho graphic **cần thiết để hiểu nội dung**, và cái này không phải. Quan trọng hơn: `progressTrack` là track dùng chung của cả app (`MxProgressBar`), nên nâng nó là quyết định thiết kế cho mọi thanh cùng lúc — sửa riêng ở đây tạo hai loại track trông khác nhau. Con số nằm trong `progress_chart_contrast_test.dart` để lần đổi sau là một sửa đổi có chủ đích |
| X2 | Strict visual audit chạy ở một viewport cố định của harness, không phải ba viewport của W6.1 | — | Hai nửa của W6 do hai suite khác nhau nhìn: audit đọc **paint graph** (màu, surface column) ở bốn state × hai theme; `progress_screen_geometry_test.dart` đọc **rect** ở ba viewport × hai locale. `memoxProductionScreenAuditTest` không nhận viewport, nên gộp lại sẽ là một thay đổi harness chạm mọi companion đang có |
| X3 | State `loading` không có mặt trong audit | — | Nó là `MxLoadingState` một mình trong cùng shell; danh tính và nhãn screen reader được `progress_screen_test.dart` khẳng định, và màu của nó thuộc component đó chứ không thuộc màn này |
| X4 | Node semantics của một hàng biểu đồ chỉ rộng bằng **cột nhãn**, không phủ track và con số | Đo tại HEAD: **41.7dp** ở `390 · en`, **82.1dp** ở `320 @ 2.0 · en`, **119.3dp** ở `320 @ 2.0 · vi` — tức dải thật là ≈41–120dp, không phải bề rộng card | `Table` không cho bọc một `TableRow`, nên chỉ có hai lựa chọn: một node neo ở nhãn, hoặc ba mảnh rời trong đó con số đã mất tên ngày của nó (W6.4). Bỏ `Table` để lấy rect rộng hơn thì mất chính lý do `Table` được chọn — G8/G10, bảy bar trên **một** baseline ở mọi text scale. Hệ quả đã đo và chấp nhận: explore-by-touch chạm vào bar hoặc vào con số không đọc gì; đọc tuần tự và swipe qua từng node thì đủ câu, và đó là cách đọc một biểu đồ bảy hàng |
| X5 | Bar không dùng `MxProgressBar`, mà dựng `ClipRRect` + hai `DecoratedBox` | Hình dạng giống hệt component dùng chung: cùng `AppRadius.pill`, chiều cao đọc thẳng từ `MxProgressBarSize.sm.trackHeight` | Hai lý do đều là hành vi, không phải hình: `MxProgressBar` mang `TweenAnimationBuilder`, nên bảy bar sẽ chạy animation mỗi lần stream emit — mà stream này emit sau **mọi** lượt trả lời (BR-189); và nó mang `Semantics` riêng, trong khi W6.4 yêu cầu đúng một node cho cả hàng, neo ở nhãn. Token thì vẫn dùng chung: chiều cao lấy thẳng từ enum, hai màu là `progressTrack`/`progressFill` và được strict audit đọc từ paint graph |
| X6 | Headline của S1 **kẹp text scaler ở 1.75 khi viewport ở compact tier** (`< 360dp`), là chỗ duy nhất trong app làm việc đó | Ở scale 2.0, riêng từ đơn vị đã rộng hơn cột nội dung: `days` = **268.1dp**, `ngày` = **274.9dp** so với `320 − 2×12 − 2×16 = 264dp`. Không có chỗ ngắt nào bên trong một từ, nên engine ngắt **giữa từ** — EN vẽ `5`/`day`/`s`, VI vẽ `999`/`ngà`/`y`, và headline cao 384dp. W6 cấm thu font để né tràn, nhưng cái đang xảy ra không phải thừa một dòng mà là một từ bị cắt đôi, và nó trông như cố ý. Giới hạn tuyến tính thật là `264 / 274.9 × 2.0 ≈ **1.92**`; chọn **1.75** là biên an toàn có chủ ý chứ không phải mép đo được — hai con số trên là một font và một chuỗi, một dạng plural hoặc một font fallback ở locale sau ăn mất vài dp mà không báo. Ở 1.75 còn **234.6dp** EN / **240.5dp** VI, và **không đổi gì ở scale ≤ 1.75**. **Phạm vi là compact tier**: từ 360dp trở lên cột nội dung đã ≥ 296dp nên không có gì để né, và thu chữ ở đó mới đúng là thứ W6 cấm — bản clamp đầu tiên vô điều kiện và đã làm đúng thế ở 360/390/412. Residual đã biết: điều kiện là **tier** (`< 360dp`) chứ không phải bề rộng cột đo được, và cột đủ chỗ cho tiếng Việt từ `331dp`, nên trong dải `[331, 359]dp` clamp vẫn bắn khi không cần. Giữ ranh giới tier vì đó là cùng predicate `mxScreenGutter` dùng, và vì không thiết bị Android nào ship trong dải đó — keying theo bề rộng cột đo được sẽ đẩy một quyết định layout vào widget. Chỉ áp cho đúng `Text` headline; hai dòng còn lại trong card và mọi section khác giữ nguyên setting của người dùng. Ghim hai chiều: `getMinIntrinsicWidth ≤ size.width` trên **mọi** paragraph của ba mặt (loaded/error/empty) ở `320 @ 2.0` × {en, vi}, **và** `textScaler.scale(57)` bằng `114.0` ở 360/390/412 nhưng `99.75` ở 320 |
| X7 | `Retry` trên mặt lỗi **không tạo phản hồi hiển thị nào** trong suốt lần đọc lại | Đo từng frame ở `390 · en`: bốn frame liên tiếp sau khi tap đều `MxErrorState` = 1, `MxLoadingState` = 0, `isRefreshing = true`, `hasError = true` — không một pixel nào đổi | `ref.invalidate` sinh một *refresh*, và `MxAsyncView` đặt `skipLoadingOnRefresh: true` cho mọi màn, nên nhánh loading bị bỏ qua và mặt lỗi cũ được vẽ lại. Đây là hành vi của **component dùng chung**: đổi nó là quyết định cho toàn app, không phải cho riêng màn này, nên chủ sở hữu là M4.10 (`docs/wbs.md` M99.23, deferred debt 6). S-e không khai busy state, và ở ca thành công SQLite local trả lời dưới một frame nên không ai thấy — ca hỏng mới là ca người dùng cần biết cú chạm đã được nhận. Ghim bằng `progress_screen_test.dart` để ngày M4.10 đổi cờ thì test đỏ có chủ đích chứ không đổi âm thầm |

## S-ma trận trạng thái

| # | State | Điều kiện | Hiển thị |
|---|---|---|---|
| S-a | loading | Chưa có emission nào | `MxLoadingState` trong shell, có nhãn screen reader |
| S-b | loaded-normal | Có hoạt động trong cửa sổ bảy ngày | Ba section W2/W3/W4 |
| S-c | loaded-today-zero-streak-retained | Hôm nay 0, hôm qua active (BR-187) | Ba section; S1 dùng biến thể W2.5; S2 hiện nhánh `=0` của `progressTodayCardsLabel` — "No cards" / "Chưa có thẻ nào" — rồi `Learning 0` và `Reviewing 0`. Không phải chữ số `0`: cùng một plural resource phát ra "1 card" và "12 cards", nên `=0` phải là một câu, không phải một chữ số trần |
| S-d | empty-lifetime | Chưa từng có card-day nào | Mặt empty cả màn + CTA sang Study (P7) |
| S-e | error | Stream lỗi | `MxErrorState` + `Retry`, không ghi gì (BR-190) |
| S-f | live refresh | Answer mới trong lúc màn mở | Ở lại S-b/S-c, số đổi tại chỗ, MUST NOT về S-a (P8) |
| S-g | midnight rollover | Qua local midnight khi màn mở | Cửa sổ trượt một ngày, Today về 0, streak theo BR-187; MUST NOT về S-a |

`S-f` và `S-g` được kiểm **từng frame**, không chỉ ở trạng thái nghỉ: một spinner
chỉ hiện một frame vẫn là một cái nháy người dùng thấy, và assertion đặt ở cuối
sẽ bỏ sót đúng ca đó. `S-g` đáng chú ý hơn `S-f` vì nó là *reload* — dependency
`progressNow` đổi — nên nó phụ thuộc vào `shouldSkipLoadingOnReload`, và cùng đường đó
được đi lại ở **mọi lần app resume**.

Cái lỗ mà bản đầu của mục này tự ghi ra — "test chưa phủ được một lần đọc SQLite
thật chậm hơn một frame; nguồn trong test trả lời đồng bộ" — chính là chỗ defect
nằm: với nguồn đồng bộ, assertion "không có frame loading" xanh dù cờ đặt thế
nào. `progress_screen_reload_test.dart` đóng nó bằng một repository phát emission
sau một vòng event loop, đúng hình dạng của `watch()` thật; bỏ opt-in
`shouldSkipLoadingOnReload` ra thì test resume ở đó đỏ.

Không có state `refreshing` riêng: không có thao tác refresh nào của người dùng
để hiển thị (P9).
