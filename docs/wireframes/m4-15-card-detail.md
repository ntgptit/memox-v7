# Wireframe M4.15 — Card Detail và lịch sử học

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của màn chi tiết card để M99.31 xây mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Màn chi tiết card: entry point, anatomy, dòng thời gian lịch sử, mọi trạng thái, hợp đồng geometry, responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-239…BR-246), luồng (UC-19), editor (`m4-11-card-management.md`) |
| **Source of truth for** | Anatomy màn chi tiết card · copy các band của màn này · hợp đồng geometry của màn này · responsive/a11y contract của màn này |
| **Depends on** | `../use-cases.md` (UC-19), `../business-rules.md` (BR-239…BR-246), `../architecture.md` (AD-08, AD-11, AD-13, AD-15), `m4-11-card-management.md` |
| **Updated by task** | M99.31 (phase 6 — recursive UI/UX review: V10 bỏ đếm ở đuôi, V11 canh trái đuôi, V12 spinner tại chỗ, G3 co giãn, G8 xếp chồng khi hẹp, W6 thêm dạng nói) |
| **Last updated** | 2026-08-14 |

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

App bar: tiêu đề là nhãn chung `Card`, **không** phải mặt trước của thẻ — mặt
trước là nội dung, và nội dung không bị cắt (BR-240) trong khi tiêu đề app bar
thì buộc phải cắt. Action duy nhất: `Edit` (V3).

Body là một cột cuộn, từ trên xuống:

1. **Band nội dung**
   1. Mặt trước — kiểu chữ lớn nhất của màn, xuống dòng không giới hạn.
   2. Mặt sau — một bậc nhỏ hơn, xuống dòng không giới hạn.
   3. `example` · `hint` · `pronunciation` — mỗi field một dòng nhãn + một khối
      giá trị; field không có giá trị **vắng mặt hoàn toàn**, không nhãn rỗng
      (BR-240).
2. **Band siêu dữ liệu và trạng thái**
   1. Hàng cờ (chỉ khi thẻ được đánh cờ) và dãy chip tag (chỉ khi có tag).
   2. Trạng thái hiển thị của thẻ — cùng chấm màu + nhãn chữ mà hàng danh sách
      dùng, nên hai mặt không nói hai cách về một sự thật (BR-89…BR-91).
   3. Lưới nhãn–giá trị của lịch hiện tại: `Due`, `Learned`, `Last answered`,
      `Reviews`, `Lapses`, cộng field riêng của scheduler đang gắn — `Box` cho
      `eight_box`; `Ease`, `Interval`, `Repetitions` cho `sm2` (BR-240). Field
      của scheduler còn lại **không** hiện.
3. **Band lịch sử**
   1. Tiêu đề band `Study history`.
   2. Với mỗi generation, một tiêu đề nhóm rồi các event của nó (V6, BR-243).
   3. Đuôi: `Load more`, spinner loading-more, dòng "đã hết" (`All reviews
      shown` — không đếm, V10), hoặc dải lỗi của trang (W3).

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

```
│
●   14 Aug 2026 · 09:41
│   Self assess · Scheduled · Remembered
│   Box 2 → 3
│   Due 21 Aug 2026
│
```

- **Dòng 1** — thời điểm, định dạng theo locale đang bật (W6).
- **Dòng 2** — mode · kind · action, mỗi cái là nhãn đã localize của **giá trị
  đã lưu** trên hàng đó (BR-242). Thứ tự này là từ "ở đâu" tới "làm gì".
- **Dòng 3+** — thay đổi lịch, một dòng cho mỗi field mà scheduler của hàng đó
  có (V9). Lượt không dời lịch hiện đúng một dòng nói không đổi lịch, chứ không
  bỏ trống (BR-242).
- **Phần đuôi tuỳ chọn** — `Timed out` khi `outcome_reason` có giá trị, `Hint
  used` khi `used_hint` là true (BR-242).

### W5 — Hợp đồng geometry (đo bằng `getRect`)

| # | Ràng buộc |
|---|---|
| G1 | Một gutter duy nhất cho cả màn. Mép trái của band nội dung, band trạng thái và tiêu đề band lịch sử MUST bằng nhau |
| G2 | Nhãn và giá trị trong lưới trạng thái MUST thẳng hàng theo cột: mọi nhãn cùng mép trái, mọi giá trị cùng mép trái |
| G3 | Marker của event MUST neo vào **dòng đầu** của event, không vào tâm hàng — và offset MUST co giãn theo `textScaler`, vì dòng đầu cao lên ở 2.0 còn một offset hằng số thì không |
| G4 | Mép trái phần chữ của mọi event MUST bằng nhau, độc lập với số dòng của event |
| G5 | Khoảng cách giữa hai event trong cùng nhóm MUST nhỏ hơn khoảng cách giữa nhóm cuối của một generation và tiêu đề nhóm kế tiếp |
| G6 | `Load more`, spinner loading-more, dải lỗi trang và dòng "đã hết" MUST chiếm cùng một vị trí đuôi — cùng mép trái (mép band, theo V11) và `Load more` → loading-more MUST giữ nguyên chiều cao — và MUST NOT làm event cuối dịch chuyển khi đổi giữa các mặt đó |
| G7 | Đáy của vùng cuộn MUST chừa safe area dưới; event cuối MUST không bị bottom bar che |
| G8 | Lưới nhãn–giá trị của band trạng thái MUST chuyển sang xếp chồng (nhãn trên, giá trị dưới) khi cột nhãn đã co giãn chiếm quá 45% bề rộng khả dụng. Ở 320dp với `textScaler` 2.0, cột nhãn là 232/288 và chừa 44dp — hẹp hơn một từ ở cỡ đó, và không có overflow nào bắn ra: giá trị chỉ đơn giản tràn khỏi cột. Canh cột (G2) là thứ hy sinh được; đọc được giá trị thì không |

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
- Nội dung thẻ MUST NOT xuất hiện trong log ở bất kỳ level nào (BR-51, BR-52).
