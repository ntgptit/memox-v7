# Wireframe M4.15 — Card Detail và lịch sử học

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của màn chi tiết card để M99.31 xây mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Màn chi tiết card: entry point, anatomy, dòng thời gian lịch sử, mọi trạng thái, hợp đồng geometry, responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-239…BR-246), luồng (UC-19), editor (`m4-11-card-management.md`) |
| **Source of truth for** | Anatomy màn chi tiết card · copy các band của màn này · hợp đồng geometry của màn này · responsive/a11y contract của màn này |
| **Depends on** | `../use-cases.md` (UC-19), `../business-rules.md` (BR-239…BR-246), `../architecture.md` (AD-08, AD-11, AD-13, AD-15), `m4-11-card-management.md` |
| **Updated by task** | Card Detail compact history layout (V13…V19: summary hero, scheduler-adaptive progress, event cards, tonal Edit; W2/W4 viết lại, G1…G12 đo theo bố cục mới) — trước đó M99.31 (phase 6: V10 bỏ đếm ở đuôi, V11 canh trái đuôi, V12 spinner tại chỗ, G3 co giãn, W6 thêm dạng nói) |
| **Last updated** | 2026-08-26 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

Danh sách card là một mặt **quản lý**: nó trả lời "thẻ nào" bằng một hàng một
dòng. Chi tiết là mặt **đọc**: nó trả lời "thẻ này là gì, và nó đã đi qua những
gì". Hai câu hỏi khác nhau, nên hai màn — và điều đó cũng là lý do hàng danh
sách được phép cắt bằng ellipsis còn màn này thì không (BR-240).

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| V1 | Chi tiết là **route riêng** `/decks/<deckId>/cards/<cardId>`, lồng dưới card list, **không** phải bottom sheet | Nội dung dài cộng một danh sách phân trang không vừa một sheet, và một sheet cuộn hai tầng (sheet cuộn, list cuộn) là cử chỉ tranh nhau. Route cũng là thứ deep link tới được, và Back của Android trả về đúng danh sách với ngữ cảnh của nó (BR-246) | 2026-08-13 |
| V2 | Chạm hàng mở **chi tiết**, không mở editor như trước M99.31 | Chạm là cử chỉ hay dùng nhất và nó phải dẫn tới hành động ít rủi ro nhất. Trước đây một lần chạm nhầm mở thẳng form sửa nội dung thật; đọc rồi mới sửa là thứ tự đúng (BR-246) | 2026-08-13 |
| V3 | `Edit` là **icon action trên app bar**, không phải nút lớn trong body và không phải FAB | Nó phải **thấy được** (một hành động không có affordance thì không tồn tại) nhưng **không** được nặng hơn phần nội dung đang đọc. App bar là chỗ danh sách card đã đặt các action của nó, nên vị trí này không phải một quy ước mới; FAB thì mang `primaryContainer` và sẽ đọc như hành động chính của màn (BR-246) | 2026-08-13 |
| V4 | Nội dung, trạng thái và lịch sử là **ba band trong một cột cuộn duy nhất**, không phải tab | Ba tab bắt người dùng biết trước cái mình cần trước khi nhìn thấy nó, và làm "thẻ này đã đi qua những gì" bị giấu sau một lần chạm — đúng thứ màn này tồn tại để trả lời. Một cột cũng là thứ duy nhất còn đọc được ở 320dp với `textScaler` 2.0 | 2026-08-13 |
| V5 | Lịch sử phân trang bằng **nút `Load more` ở đuôi danh sách**, không phải infinite scroll | Cùng idiom mà card list đã dùng (M4.11 W1b), nên hai màn không dạy hai cử chỉ khác nhau cho cùng một việc. Infinite scroll cũng không có chỗ nào để đặt dải lỗi của một trang hỏng mà không làm nó nhảy dưới ngón tay (UC-19 E4) | 2026-08-13 |
| V6 | Tiêu đề nhóm generation là **một dòng chữ**, không phải màu nền hay đường kẻ màu | BR-243 đòi nhóm đọc được không cần màu. Một dòng chữ cũng là thứ duy nhất TalkBack đọc lên được như một tiêu đề | 2026-08-13 |
| V7 | Tiêu đề nhóm **không** sticky | Sticky header cần một `CustomScrollView` với sliver riêng cho mỗi nhóm, và số nhóm chỉ bằng số lần Reset — thực tế là 1 với gần như mọi thẻ. Trả chi phí đó cho một trường hợp hiếm là sai; nếu một ngày dữ liệu thật cho thấy nhiều nhóm dài thì đó là lúc justify lại (BR-243) | 2026-08-13 |
| V8 | Mỗi event là **một hàng có marker ở cột trái**, marker là một chấm nhỏ trên một đường dọc | Đường dọc là thứ làm danh sách đọc như một dòng thời gian thay vì một bảng; chấm neo vào baseline dòng đầu của hàng chứ không vào giữa hàng, vì hàng cao thấp khác nhau tuỳ số field trước→sau | 2026-08-13 |
| V9 | Thay đổi lịch viết dạng `2 → 3`, kèm nhãn của chính field đó | Mũi tên là ký hiệu ngắn nhất mà không cần màu và không cần dịch. Nhãn là bắt buộc vì `2 → 3` một mình không nói đó là box hay số ngày (BR-242) | 2026-08-13 |
| V10 | Màn này **không** hiện bất kỳ con số tổng hợp nào — không phần trăm đúng, không streak, và **dòng cuối danh sách cũng không đếm** | BR-243. Bản đầu ghi "N reviews in total" và nó đã sai sẵn: `Reviews` ở band trên đếm **chỉ** lượt `scheduled` (BR-20), còn lịch sử giữ cả `learning` và `relearning` qua mọi generation — hai con số trên cùng một màn nói khác nhau. Dòng cuối nay là `All reviews shown`, không có số | 2026-08-14 |
| V11 | Đuôi danh sách lịch sử **canh trái theo mép band**, khác với card list vốn canh giữa đuôi của nó | Ghi lại vì nó là một divergence có chủ ý so với V5. Đuôi ở đây không phải một event nên không thụt vào cột chữ của event, nhưng nó thuộc band lịch sử nên đứng đúng mép band — cùng mép với tiêu đề `Study history` và với hai band trên (G1). Canh giữa sẽ tạo mép thứ ba trên một màn chỉ có một cột. Thống nhất hai màn là việc của một lượt design-system, không phải của task này | 2026-08-14 |
| V12 | Trạng thái `loading-more` là **spinner cỡ glyph, canh trái, cao đúng 48dp** — không phải `MxLoadingState` | `MxLoadingState` canh giữa một indicator 36dp trong `EdgeInsets.all(xl)`, nên đuôi sẽ cao 84 và nhảy vào giữa màn. W3 mặt 5 cấm đúng điều đó. Hình dạng này là footprint của chính nút `Load more` với spinner của nút — cùng shape `MxActionButton` đã dùng inline | 2026-08-14 |
| V13 | Màn là **ba bề mặt phẳng cùng một gutter**: summary hero, current-progress panel, và **một `MxCard` cho mỗi event**. Tất cả `AppElevation.none`; hairline `borderSubtle` làm việc tách bề mặt | Ba band cũ chỉ phân biệt bằng khoảng trắng — tín hiệu yếu nhất một layout có. Phẳng chứ không nổi vì D20: hai độ sâu trong một cột cuộn đọc như lỗi render chứ không như thứ bậc, và ở dark `shadowsFor` vẽ rỗng nên một "card nổi" chỉ nổi ở một trong hai theme | 2026-08-26 |
| V14 | **Summary hero**: mặt trước ở `headlineSmall` (24sp) — **không** phải `AppTextStyles.cardPrompt` (30sp) — mặt sau ở `bodyMedium`/`onSurfaceVariant`, cờ và tag trong cùng một `Wrap`, rồi divider `borderSubtle` và nhóm field tuỳ chọn. Divider **chỉ tồn tại khi nhóm đó tồn tại** | `cardPrompt` là rung của màn ôn, nơi thuật ngữ *là* nhiệm vụ và chiếm cả màn. Ở đây nó là một fact trong nhiều fact; một summary hét lên là summary không ai đọc tiếp. Divider không có gì bên dưới là divider cắt nghĩa khỏi đáy card | 2026-08-26 |
| V15 | **Scheduler badge** ở mép phải hàng đầu của hero: `eight_box` nói vị trí `Box N / 8` (N/8 lấy từ `kMaxBox` của chính scheduler), `sm2` nói tên `SM-2`. Badge và mặt trước ở trong một `Wrap` `spaceBetween` | Hai thuật toán biết hai thứ khác nhau: SM-2 không có bậc thang để ở 3/8 quãng đường, và bịa ra một cái cho cân đối là bịa ra một metric (BR-243, AD-08). `Wrap` vì một thuật ngữ dài phải được lấy trọn một hàng và badge xuống hàng riêng — không có đường nào khác ngoài thu nhỏ font, và type scale cấm điều đó | 2026-08-26 |
| V16 | **Current-progress panel**: trạng thái hiển thị (chấm + chữ), rồi — chỉ với `eight_box` — hàng `Box  N / 8` và một track **8 đoạn**, rồi lưới metric hai cột. Đoạn đã qua `progressFill`, đoạn hiện tại `primaryAccent` **và cao hơn**, đoạn còn lại `progressTrack` | Chiều cao chứ không chỉ màu, vì ở dark `progressFillDark` và `primaryAccentDark` **là cùng một màu** (`focusRingDark`). Ai không phân biệt được hai sắc đó vẫn đọc được vị trí nhờ chiều cao và nhờ dòng `N / 8` ngay trên track | 2026-08-26 |
| V17 | Mỗi event là **marker + connector bên trái, một `MxCard` phẳng bên phải**. Hàng đầu của card: **badge viền** (icon + action đã localize) bên trái, timestamp bên phải, trong một `Wrap` `spaceBetween`. Dòng dưới là mode · kind; rồi các dòng schedule; rồi mark | Badge mang phán quyết nên dòng dưới thôi lặp lại nó. Badge **viền chứ không tô nền**: container duy nhất mà bảng màu có cho cả ba tone là `surfaceMuted`, nơi `warning` chỉ đạt 4.00:1 ở light — dưới 4.5 mà chính nhãn của nó cần. Trên `surface` của card thì cả ba đều đạt (success 5.20/8.10, danger 5.57/6.71, warning 4.58/11.24) | 2026-08-26 |
| V18 | Tone của event có **ba bậc** đọc từ `StudyAction` đã lưu: `forgotten`/`again` → `danger`; `hard` → `warning`; `remembered`/`good`/`easy` → `success` | Sáu action trả lời một câu hỏi — "lượt này có ổn không" — theo ba cách. `hard` giữ được thẻ và tốn công làm việc đó; gọi nó là success sẽ xoá đúng tín hiệu duy nhất SM-2 có giữa "ổn" và "suýt mất". Đọc từ giá trị đã lưu, không suy từ delta lịch (BR-76) | 2026-08-26 |
| V19 | ~~`Edit` là `MxActionButton` biến thể **`tonal`** có icon **và nhãn**~~ — **thay bằng V20** | V3 đòi Edit thấy được nhưng không nặng hơn nội dung đang đọc (BR-246). Đo được: `secondaryContainer` chỉ **1.14:1** (light) / **1.56:1** (dark) so với app bar, nên thứ nhận diện nút này là **nhãn** chứ không phải nền — đó là đường conformant, và là lý do biến thể này luôn mang chữ. Cặp nhãn/nền đạt 10.37:1 / 9.09:1 | 2026-08-26 |
| V20 | `Edit` quay lại đúng **V3**: một `MxIconButton` trên app bar, không nhãn | Chủ dự án nói nút trông thô. Phép đo của V19 vẫn đúng và chính nó chỉ ra lối ra: `secondaryContainer` chỉ **1.14:1** (light) / **1.56:1** (dark) so với app bar, nên một pill tonal **không nhãn** thì không có gì nhận diện — đó là lập luận chống *nền tonal thiếu chữ*, và nó đã bị đọc thành lập luận chống icon trần. Icon button không có nền để mà mờ: mực của nó là `foregroundColor` của chính app bar — `onSurface`, **không** phải `onSurfaceVariant` mà icon-button theme sẽ cho, vì `AppBar` đẩy foreground của nó vào `IconTheme` mà các action đọc. Đo trên nền app bar: **16.06:1** / **16.62:1**, gấp mười bốn lần cái nền nó thay và gấp năm lần sàn 3:1 của WCAG 1.4.11. BR-246 đòi Edit là *một action riêng, tường minh*, **không** đòi có chữ — và vế "MUST NOT nổi bật hơn phần nội dung đang đọc" thì nghiêng về control nhẹ hơn. Lề gutter cũ bỏ luôn: nó chỉ tồn tại vì pill tonal có cạnh thấy được mà `IconButton` không có, và card list vốn đặt icon action vào `actions` trần | 2026-08-27 |

## W-cấu trúc

### W1 — Entry point và điều hướng

- **Hàng card trong danh sách, chế độ thường:** chạm → chi tiết (BR-246).
- **Hàng card trong chế độ chọn nhiều:** chạm → toggle chọn. Chi tiết **không**
  tới được từ đây; không có lối vào thứ hai nào trong chế độ đó (BR-246).
- **Giữ lâu:** vẫn vào chế độ chọn như trước, không đổi (UC-04 A6).
- **Back từ chi tiết:** về danh sách với filter, search term, sort, cửa sổ đã
  tải và selection nguyên vẹn (BR-246). Đây là hệ quả của việc chi tiết được
  **đẩy chồng** lên, không phải thay thế.
- **Deep link** `/decks/<deckId>/cards/<cardId>`: hợp lệ. Id không tồn tại →
  mặt not-found của chính màn này, **không** phải màn 404 của app (BR-245).

### W2 — Anatomy (trạng thái loaded, có lịch sử)

**Bản này thay bản W2 cũ** (V13…V19). Trước đây body là ba dải chữ trên nền
trang; nay là ba loại bề mặt phẳng cùng một gutter.

App bar: tiêu đề là nhãn chung `Card`, **không** phải mặt trước của thẻ — mặt
trước là nội dung, và nội dung không bị cắt (BR-240) trong khi tiêu đề app bar
thì buộc phải cắt. Action duy nhất: `Edit`, biến thể tonal có nhãn (V19).

Body là một cột cuộn, tối đa rộng `AppBreakpoints.medium`, từ trên xuống:

1. **Summary hero** — một `MxCard` phẳng.
   1. Hàng đầu: mặt trước (`headlineSmall`) và mặt sau (`bodyMedium`, muted) ở
      bên trái; scheduler badge (V15) ở mép phải, xuống hàng riêng khi hẹp.
   2. Cờ (chỉ khi được đánh cờ) và dãy chip tag (chỉ khi có tag), trong **một**
      `Wrap` — cả hai đều là dấu ai đó đặt lên thẻ.
   3. Divider hairline, **chỉ khi** có ít nhất một field tuỳ chọn.
   4. `example` · `hint` · `pronunciation` — nhãn `labelSmall` trên giá trị
      `bodyMedium`; field không có giá trị **vắng mặt hoàn toàn** (BR-240).
2. **Current progress** — tiêu đề section, rồi một `MxCard` phẳng.
   1. Trạng thái hiển thị: cùng chấm màu + nhãn chữ mà hàng danh sách dùng, nên
      hai mặt không nói hai cách về một sự thật (BR-89…BR-91).
   2. **Chỉ `eight_box`:** hàng `Box  N / 8` rồi track 8 đoạn (V16).
   3. Lưới metric hai cột: `Due`, `Learned`, `Last answered`, `Reviews`,
      `Lapses`, cộng `Ease`, `Interval`, `Repetitions` cho `sm2` (BR-240).
      Field của scheduler còn lại **không** hiện. Mỗi ô là một well có glyph,
      nhãn `bodySmall` trên giá trị `bodyMedium` w600.
3. **Band lịch sử** — tiêu đề section trên nền trang; band **không** có card của
   riêng nó.
   1. Tiêu đề band `Study history`.
   2. Với mỗi generation, một tiêu đề nhóm rồi các event của nó (V6, BR-243).
   3. Mỗi event: marker + connector, rồi một `MxCard` phẳng (V17).
   4. Đuôi: `Load more`, spinner loading-more, dòng "đã hết" (`All reviews
      shown` — không đếm, V10), hoặc dải lỗi của trang (W3).

**Concept có, màn này cố ý không có** (chủ dự án đã duyệt): breadcrumb — read
model không có deck path; `Recall rate`, `Correct streak`, `Since added`,
`TIMELINE · N EVENTS` — BR-243 và V10 cấm mọi aggregate; `All events` filter —
chưa có filter contract; taxonomy `CORRECT`/`RECOVERED`/`FORGOT` — event dùng
`mode`/`kind`/`action` đã lưu; thời lượng `1.4 s` — read model không lưu nó;
`Box 3 / 5` — `eight_box` có tám hộp, không phải năm.

### W3 — Ma trận mặt

| # | Mặt | Body |
|---|---|---|
| 1 | loading | Chỉ báo tải của cả màn. Không khung xương giả cho nội dung chưa biết dài bao nhiêu |
| 2 | loaded · chưa có lịch sử | Band 1 và 2 đầy đủ; band 3 là trạng thái rỗng có icon, tiêu đề và một câu giải thích rằng thẻ chưa được ôn lần nào (BR-244) |
| 3 | loaded · một trang | Band 3 có tối đa 50 event, đuôi là dòng "đã hết" |
| 4 | loaded · còn trang sau | Đuôi là `Load more` |
| 5 | loading-more | `Load more` đổi thành chỉ báo đang tải **tại chỗ**: hàng đuôi MUST giữ nguyên chiều cao, các event đã hiện MUST không dịch chuyển |
| 6 | page error | Các event đã hiện **giữ nguyên**; đuôi là dải lỗi một dòng + `Retry` (UC-19 E4) |
| 7 | error cấp cao nhất | Toàn body là mặt lỗi có `Retry`; app bar giữ `Edit`? **Không** — không có gì để sửa khi chưa đọc được thẻ, nên action ẩn |
| 8 | not-found | Toàn body là mặt not-found có lối về danh sách; app bar không có `Edit` (BR-245) |

### W4 — Anatomy một event

**Bản này thay bản W4 cũ** (V17).

```
│   ┌───────────────────────────────────────────┐
●   │ (✓ Remembered)          14 Aug 2026 · 09:41│
│   │ Self assess · Scheduled                   │
│   │ Box 2 → 3                                 │
│   │ Due 21 Aug 2026                           │
│   └───────────────────────────────────────────┘
```

- **Marker** — chấm mang tone của action đã lưu, nằm **ngoài** card, neo vào
  băng của hàng đầu *bên trong* card (G3). Connector chạy qua nó.
- **Hàng đầu** — badge viền (icon + action đã localize, V17/V18) ở trái;
  thời điểm ở phải, định dạng theo locale đang bật (W6). Cả hai trong một
  `Wrap`, nên ở 320dp với chữ gấp đôi thời điểm xuống hàng riêng chứ không đẩy
  badge ra khỏi card.
- **Dòng kế** — mode · kind, mỗi cái là nhãn đã localize của **giá trị đã lưu**
  (BR-242). Action **không** lặp lại ở đây: badge đã nói.
- **Dòng tiếp** — thay đổi lịch, một dòng cho mỗi field mà scheduler của hàng đó
  có (V9). Lượt không dời lịch hiện đúng một dòng nói không đổi lịch (BR-242).
- **Phần đuôi tuỳ chọn** — `Timed out` khi `outcome_reason` có giá trị, `Hint
  used` khi `used_hint` là true (BR-242).
- **Một node semantics gộp** cho cả card: badge, thời điểm và các dòng nằm trong
  cùng một câu, không thành bốn thông báo (W6).

### W5 — Hợp đồng geometry (đo bằng `getRect`)

| # | Ràng buộc |
|---|---|
| G1 | Một gutter duy nhất cho cả màn, lấy từ `mxScreenGutter(context)`. Mép **ngoài** trái và phải của summary hero và current-progress panel MUST bằng nhau và bằng gutter đó; hai tiêu đề section MUST nằm trên cùng mép ngoài ấy. **Event card thụt vào ở phía leading và chỉ ở đó** — marker và connector sống trong khoảng thụt ấy, ngoài card, đúng như concept vẽ — nên mọi event card MUST có cùng mép trái với nhau và MUST đóng trên cùng mép phải với hai bề mặt trên |
| G2 | Nội dung bên trong summary hero MUST thụt vào đúng `AppSpacing.lg` |
| G3 | Marker của event MUST neo vào **badge** của hàng đầu, không vào tâm hàng và không vào dòng chữ trần: badge là một pill, padding `xs` và hairline của nó làm nó cao hơn dòng chữ bên trong 10 điểm. Offset MUST co giãn theo `textScaler` ở phần chữ và MUST NOT co giãn ở phần padding |
| G4 | Mép trái phần chữ của mọi event MUST bằng nhau, độc lập với số dòng của event |
| G5 | Khoảng cách giữa hai event trong cùng nhóm MUST nhỏ hơn khoảng cách giữa nhóm cuối của một generation và tiêu đề nhóm kế tiếp |
| G6 | `Load more`, spinner loading-more, dải lỗi trang và dòng "đã hết" MUST chiếm cùng một vị trí đuôi — cùng mép trái, và từ V13 mép đó là **gutter màn hình** vì band không còn card của riêng nó — và MUST NOT làm event cuối dịch chuyển khi đổi giữa các mặt đó |
| G7 | Đáy của vùng cuộn MUST chừa safe area dưới; event cuối MUST không bị bottom bar che |
| G8 | Lưới metric MUST là **hai cột** khi `(bề rộng trong panel − AppSpacing.md) / 2` còn ≥ một sàn đã co giãn theo `textScaler`, và MUST rơi về **một cột** khi không. Quyết định MUST dựa vào constraints thật của panel, không dựa vào bề rộng thiết bị |
| G9 | Giá trị của lưới metric MUST dùng `FontFeature.tabularFigures()` khi là số đếm hoặc số đo, và MUST NOT dùng nó cho ngày — ngày được đọc chứ không so cột. Đúng **một** giá trị trên panel được nhận accent (`Box` của `eight_box`); ba field SM-2 MUST giữ màu thường (BR-243) |
| G10 | Chấm marker và badge của cùng một event MUST mang **cùng một tone**, và tone đó MUST đến từ `StudyAction` đã lưu. Đường nối MUST đạt ≥3:1 trên bề mặt nó được vẽ lên |
| G11 | Track của `eight_box` MUST có đúng `kMaxBox` đoạn, **bề rộng bằng nhau và khoảng cách bằng nhau**, đoạn đầu/cuối trùng mép trong của panel. Đoạn hiện tại MUST cao hơn hai loại còn lại — chiều cao, không chỉ màu, vì ở dark `progressFill` và `primaryAccent` là cùng một giá trị |
| G12 | Scheduler badge MUST NOT chồng lên mặt trước: hoặc nó nằm cùng hàng ở mép phải, hoặc nó xuống một hàng mới với spacing token. MUST NOT thu nhỏ font để cả hai vừa một hàng |

### W6 — Responsive và a11y

- Kiểm ở 320dp @2.0, 390dp, 412dp; EN và VI; light và dark.
- Ngày giờ MUST định dạng theo locale đang bật, MUST NOT ghép chuỗi bằng tay.
- Mỗi event MUST là **một node semantics gộp**: TalkBack đọc một câu có thời
  điểm, mode, kind, action và thay đổi lịch, chứ không đọc rời từng nhãn.
- Câu đọc lên MUST dùng **dạng nói**, không dùng lại chuỗi đã vẽ: `→` được đọc
  thành "right arrow" hoặc không đọc gì, và `–` gần như luôn im lặng — nên
  `Box 2 → 3` trên màn tương ứng với `Box from 2 to 3` khi đọc, và một cột
  không được ghi thành `not recorded` chứ không phải một khoảng lặng.
- `Edit`, `Load more` và `Retry` MUST có vùng chạm tối thiểu 48dp và MUST có
  nhãn semantics riêng.
- Chip cờ MUST NOT được đọc lên như một nút: màn này hiện cờ và không bao giờ
  đổi nó (BR-92, BR-239).
- **Bốn divergence đã đo so với concept, ghi lại để lần sau không phải đo lại:**
  - **Badge của event là pill *viền*, không phải pill *tô nền* như concept.**
    Bảng màu chỉ có một container dùng được cho cả ba tone — `surfaceMuted` —
    và `warning` trên nền đó là **4.00:1** ở light, dưới ngưỡng 4.5:1 mà chính
    nhãn của nó cần. Trên `scheme.surface` của card thì cả ba đạt: success
    5.20 / 8.10, danger 5.57 / 6.71, warning 4.58 / 11.24; viền mang cùng màu
    nên vượt xa ngưỡng 3:1 của một đường. Pill giữ hình dạng và bỏ phần nền,
    thay vì bảng màu có thêm một màu.
  - **Đường nối của dòng thời gian dùng `semantic.borderControl`, không dùng
    `borderSubtle`.** Đo trên nền trang: `borderSubtle` là 1.38:1 (sáng) và
    2.32:1 (tối), dưới ngưỡng 3:1 mà WCAG 1.4.11 đòi ở phần đồ hoạ cần nhận
    diện — và đường nối là toàn bộ cấu trúc của band chứ không phải trang trí
    trên nó. `borderControl` đạt 3.02:1 / 3.41:1 ở đúng chỗ đó.
  - **Glyph cờ dùng `semantic.onDueContainer`, không dùng `semantic.warning`.**
    `warning` trên `dueContainer` là 4.04:1 ở sáng: trên ngưỡng 3:1 của một
    graphic, dưới ngưỡng 4.5:1 mà strict screen audit áp — vì một glyph tới
    render tree dưới dạng text run và auditor không phân biệt được nó với một
    từ. `onDueContainer` đạt 6.38:1 / 6.57:1. Nghĩa "khẩn" đã do nền chip mang.
  - **Nút `Edit` tonal được nhận diện bằng nhãn, không bằng nền.**
    `secondaryContainer` chỉ **1.14:1** (sáng) / **1.56:1** (tối) so với app
    bar, nên cái nền pill mà concept vẽ gần như không tồn tại ở light. Cặp
    nhãn/nền đạt 10.37:1 / 9.09:1, và văn bản đọc được là đường conformant của
    WCAG 1.4.11 — đó là lý do biến thể này **luôn** mang chữ và không bao giờ
    rút về một icon.
- **Ba khác biệt nhỏ hơn so với concept, có chủ ý:**
  - Không có nhãn `Box 1` / `Box N` / `Box 8` dưới track: với tám đoạn chúng
    thành một hàng chú thích chật, và chúng đòi ghép chuỗi một nhãn đã localize
    với một con số. Vị trí đã được nói bằng chữ ngay trên track.
  - Badge **không** viết hoa, nhưng **tiêu đề section thì có** — và ranh giới
    này phải nói rõ, vì cùng một change làm cả hai. Tiêu đề section theo tiền lệ
    đã có ở hơn mười call site (`settings_section_widget.dart`,
    `study_home_body_section_widget.dart`, `deck_list_toolbar_widget.dart`,
    `mx_session_top_bar.dart`…): chúng là nhãn nhóm, ngắn, và app chỉ ship EN +
    VI nên không chạm case chữ `i` của tiếng Thổ. Badge thì mang **giá trị đã
    lưu** của một hàng dữ liệu, và `search_group_header_widget.dart` đã ghi lý do
    không viết hoa loại chuỗi đó: `toUpperCase()` trên một chuỗi đã localize là
    quyết định của người dịch, sai với ngôn ngữ không có hoa/thường, và đổi bề
    rộng mà layout đã được đo.
  - Marker là chấm đặc, không phải vòng tròn rỗng như concept: một vòng đòi một
    stroke, và `AppStroke` không có token nào nghĩa là "viền marker" — `focus`
    và `selectionControl` đều đã có nghĩa khác.
