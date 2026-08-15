# Wireframe M5 — Study Home (resume → root decks theo workload)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của tab Study để xây và review mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Màn hình `/study`: anatomy, Resume card, danh sách root deck, mọi trạng thái, hợp đồng geometry, responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-200…BR-202), luồng (UC-14), study entry của một deck (UC-05), phiên học (`m5-study-modes.md`) |
| **Source of truth for** | Anatomy Study Home · copy các trạng thái của Study Home · hợp đồng geometry của Study Home · responsive/a11y contract của Study Home |
| **Depends on** | `../use-cases.md` (UC-14), `../business-rules.md` (BR-200…BR-202, BR-161, BR-162), `../architecture.md` (AD-13, AD-15, AD-16), `m5-study-modes.md` |
| **Updated by task** | M5.26 (Study Home v1) |
| **Last updated** | 2026-08-14 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

Tab Study từng trỏ vào một hằng số `kStudyBranchDeckId` — id của một deck do
seeder phát triển ghi ra. Trong production nó là một deck cứng cho mọi người
dùng, và trong bất kỳ database nào chưa từng có hàng đó thì nó là một study
entry của một deck không tồn tại. Màn hình này thay hằng số đó bằng thư viện
thật.

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| S1 | Study Home là **màn hình của branch**, không phải một sheet hay một redirect sang tab Library | Tab Study đã là một branch có route thật và deep link `/study` (AD-19). Redirect sang Library nghĩa là chạm tab Study thì tab Library sáng lên — một tab tự đổi sang tab khác là lỗi, không phải điều hướng | 2026-08-13 |
| S2 | Chạm Study trên một hàng đi tới **route lồng dưới `/study`** (`/study/<deckId>`), không dùng lại `deckStudy` dưới `/decks` | Hai route trỏ cùng một screen nhưng khác branch, và branch quyết định Back đi đâu. Dùng lại `deckStudy` thì chạm Study trên tab Study lại nhảy sang tab Library, và Back rơi vào một danh sách deck người dùng chưa từng mở | 2026-08-13 |
| S3 | Resume mở **thẳng** màn phiên với `shouldResume`, không đi qua study entry | Study entry là nơi *chọn* giữa học mới và ôn tập; một phiên đang dở đã chọn rồi (BR-103). Đi qua entry là thêm một lần chạm để trả lời một câu hỏi đã có đáp án, và entry sẽ mở lại chính sheet resume mà Resume card vừa thay thế | 2026-08-13 |
| S4 | Card là **surface, nút mới là hành động** — cả thẻ không tappable, khác với deck tile của UC-06 | Mở một deck ở Library là duyệt: rẻ, và Back hoàn tác. Ở đây cú chạm dẫn vào phiên học, thứ duy nhất trên màn hình này có thể ghi (BR-200). Một thẻ mở phiên vì bị quệt vào là một phiên không ai chọn | 2026-08-13 |
| S5 | Ba con số **luôn hiện, kể cả 0**, mỗi số có icon + nhãn chữ | Một chỉ số vắng mặt là nhập nhằng đúng theo cách dòng này sinh ra để chống: "không có số quá hạn" có thể là không có, cũng có thể là màn hình không theo dõi. `0 overdue · 0 due today · 12 new` nói rõ là cái nào (BR-201) | 2026-08-13 |
| S6 | Deck còn card nhưng **hết workload** vẫn giữ nút Study, đứng cuối danh sách | BR-29: hết hạn ôn là lịch chạy đúng, không phải cửa khoá. Một nút xám nói "bạn không làm được" trong khi sự thật là "không còn gì để làm" | 2026-08-13 |
| S7 | Deck **không còn card nào** thì không có hàng và không có nút | Không có gì sau hành động đó. Đây là control bật mà không dẫn đi đâu — đúng thứ mà `kStudyBranchDeckId` đã là | 2026-08-13 |
| S8 | Hai empty state riêng: **không deck** → Starter Library; **có deck nhưng không card** → Library | Hai trạng thái có hai bước tiếp theo khác nhau. Gộp lại nghĩa là đẩy người đã có bốn deck vào một catalog họ không cần (BR-202) | 2026-08-13 |
| S9 | Resume card dùng `secondaryContainer`, các hàng dùng `surface` | Nó là một loại lời mời khác với các hàng bên dưới, và cặp đó chỉ đọc ra là một cặp nếu nhìn một cái là phân biệt được. Đây là **một** surface bước ra khỏi `surface` trên toàn màn hình, không phải một bảng màu thứ hai | 2026-08-13 |
| S10 | Không có route-wide spinner khi stream refresh | `MxAsyncView` đặt `skipLoadingOnRefresh`, nên snapshot cũ ở lại tới khi cái mới về. Kết thúc một phiên rồi quay lại mà thấy cả tab thành spinner là chuyển động thay cho thông tin | 2026-08-13 |
| S11 | Hai CTA của empty state **cố ý** nhảy sang branch Library | Khác S2, và khác vì đích đến khác: `Study` trên một hàng là học **trong** tab Study, còn "xem bộ thẻ dựng sẵn" và "mở thư viện" là hai việc thuộc Library thật. Nhảy branch ở đây là đi đúng chỗ, không phải tab tự đổi | 2026-08-13 |
| S12 | Overdue dùng vai `danger` cho **chữ** | Đồng hướng với phán quyết đỏ của BR-161 cho ô icon của deck tile. Không mâu thuẫn với ghi chú "never `danger`" của `deck_workload_line_widget`: chỗ đó là chỉ số **Due tổng**, còn đây là nửa **Overdue** đã tách ra. Contrast đo được: 5.57:1 light, 6.71:1 dark | 2026-08-14 |
| S13 | Bản VI: heading Resume là "Đang học dở", không phải "Học tiếp" | "Học tiếp" và "Học tiếp theo" cách nhau đúng 24dp (G5), cùng cột, cùng họ typography — khác nhau một từ. EN phân biệt rõ ("Carry on" / "Study next"), VI thì không | 2026-08-14 |

## W-cấu trúc

### W1 — Anatomy

Từ trên xuống, trong đúng một scroll view:

```
AppBar  "Study"
────────────────────────────────────────
supporting copy         (bodyMedium, onSurfaceVariant)

┌────────────────────────────────────┐
│ Carry on              (labelMedium)│   Resume card
│ Everyday Korean       (titleMedium)│   secondaryContainer
│ Reviewing · Self-assess (bodySmall)│
│ [▶ Resume]                         │
└────────────────────────────────────┘

Study next                (titleMedium)
[dòng "chưa có gì tới hạn" — chỉ khi mọi workload = 0]

┌────────────────────────────────────┐
│ Everyday Korean       (titleMedium)│   deck row
│ 8 boxes                 (bodySmall)│   surface
│ ⟲ 2 overdue  ▤ 5 due today  ✦ 12 new  │
│ [▶ Study]                          │
└────────────────────────────────────┘
┌────────────────────────────────────┐
│ …                                  │
└────────────────────────────────────┘
────────────────────────────────────────
Bottom navigation (thuộc shell, không thuộc màn hình này)
```

Resume card vắng mặt hoàn toàn khi không có phiên hợp lệ — không phải một thẻ
rỗng, không phải một nút bị vô hiệu hoá (BR-200).

Ba chỉ số **không** có dấu `·` ngăn giữa. Icon đã nhóm từng chỉ số rồi, và
`deck_workload_line_widget.dart` phải bọc dấu `·` vào một `Row` chính vì `Wrap`
có thể bỏ rơi nó ở đầu dòng mới — ở đây không có dấu nào để bỏ rơi.

### W2 — Thứ tự và nội dung một hàng

Một hàng nói ba việc, theo đúng thứ tự người đọc cần: *đây là deck nào* → *có gì
đang chờ* → *làm gì được*. Nhãn scheduler chỉ hiện khi biết; `unknown` thì bỏ hẳn
dòng đó chứ không đoán (BR-201).

### W3 — Ma trận trạng thái

| # | Trạng thái | Điều kiện | Màn hình |
|---|---|---|---|
| 1 | loading | lần đọc đầu chưa về | `MxLoadingState` có nhãn screen-reader, không phải màn trắng |
| 2 | loaded · resume + danh sách | có phiên hợp lệ, có deck còn card | W1 đầy đủ |
| 3 | loaded · không resume | không phiên hợp lệ | như 2, bỏ hẳn Resume card |
| 4 | loaded · mọi workload = 0 | có deck còn card, ba số đều 0 ở mọi deck | danh sách vẫn hiện, thêm dòng "chưa có gì tới hạn"; nút Study vẫn còn (S6) |
| 5 | empty · không deck | `decks` rỗng | `MxEmptyState` icon folder, CTA Starter Library, lối phụ về Library |
| 6 | empty · không card | có deck, mọi deck 0 card | `MxEmptyState` icon style, CTA Open library, **không** CTA starter |
| 7 | error | đọc lỗi | `MxErrorState` + `Try again`; copy nói không có gì bị thay đổi, không nêu bảng/truy vấn/đường dẫn |

Refresh sau khi một phiên kết thúc đi từ 2 → 3 **không qua 1** (S10).

## G-hợp đồng geometry

Mọi số dưới đây là token, không phải literal, và **mỗi dòng có đúng một
assertion đo bằng `getRect` trên cây production** trong
`test/features/study/presentation/study_home_geometry_test.dart`.

Bản đầu của bảng này ghi assertion của G6…G10 và R2 là "golden
`study_home_screen`". Golden đó **không tồn tại**: `memoxProductionScreenAuditTest`
là paint-token inspector — nó đọc màu từ paint record và không đo hình học, không
so raster — nên năm ràng buộc bên trong thẻ và cả chiều rộng 412dp là hợp đồng
rỗng. Chúng nay có phép đo thật, và tên test là cột cuối.

| # | Ràng buộc | Giá trị | Assertion |
|---|---|---|---|
| G1 | Content gutter hai bên, ≥ 360dp | `AppSpacing.lg` = 16 | `the column is inset by the screen gutter` |
| G2 | Content gutter hai bên, < 360dp (`AppBreakpoints.compact`) | `AppSpacing.md` = 12 | `at 320dp the gutter steps down with the breakpoint` |
| G3 | Resume card và **mọi** hàng chung cả mép trái lẫn mép phải | bằng nhau tuyệt đối | `the resume card and every row share both edges` |
| G4 | Khoảng cách giữa hai hàng liên tiếp | `AppSpacing.md` = 12 | `rows are separated by one step, not by a section break` |
| G5 | Khoảng cách từ Resume card xuống tiêu đề `Study next` | `AppSpacing.xl` = 24 | `the list heading sits a section break below the resume` |
| G5b | Khoảng cách từ tiêu đề `Study next` xuống hàng đầu tiên | `AppSpacing.md` = 12 | `the first row sits one step below the list heading` |
| G6 | Padding bốn phía trong thẻ, cả Resume card lẫn deck row | `AppSpacing.lg` = 16, mặc định của `MxCard` | `the card pads its content by one step on every side` · `the resume card pads its content the same way` |
| G7 | Trong thẻ: tên → meta, meta → workload | `AppSpacing.xs` = 4, `AppSpacing.sm` = 8 | `the identity block breaks at xs, then sm before the counts` |
| G8 | Trong thẻ: workload → hàng hành động | `AppSpacing.md` = 12 | `the verb sits a section step below the counts` |
| G9 | Icon workload cùng dải với nhãn `bodySmall`, cách nhãn `xs` — **ở `textScaler` 1.0** | `AppIconSize.sm` = 16, gap `AppSpacing.xs` = 4 | `a workload glyph rides the body baseline, one xs from its word` |
| G10 | Khoảng cách giữa ba chỉ số workload | `AppSpacing.md` = 12 | `the three counts are one step apart` |
| G11 | Vùng chạm mọi hành động | ≥ `AppSpacing.minimumTouchTarget` = 48 | `every action clears the 48dp floor` |
| G12 | Ở **cuối** scroll, hàng cuối cách mép dưới viewport đúng một gutter | `mxScreenGutter` = 16 (12 khi < 360dp) | `the last row clears the bottom bar at the end of the scroll` |
| G13 | Tên deck dài wrap tối đa 2 dòng rồi ellipsis, hàng vẫn giữ nút | `maxLines: 2` | `a long deck name wraps to two lines and stops` |
| G14 | Error state và empty state cùng một khung, không cái nào inset thêm | trùng `MxContentShell` cả `left` lẫn `width` | `the error state is inset like the empty states, not more` · `an empty library is inset the same way` |

**G12 từng là một assertion không thể fail.** Bản đầu viết
`last.bottom ≤ bar.top`. Shell đặt `MxNavigationBar` làm `bottomNavigationBar`
của `Scaffold` ngoài, mà `Scaffold` trừ luôn chiều cao đó khỏi constraint của
body — nên nội dung branch **luôn** nằm trên thanh bar, kể cả khi xoá sạch
padding của list. Cái thực sự cần đo là khoảng hở, và khoảng hở là bottom padding
của chính list, đo so với viewport nó nằm trong. Phép đo cũng phải **nhảy** tới
`maxScrollExtent` chứ không kéo: một cú kéo bị physics chặn lại và đo vị trí
không ai chọn.

## R-responsive và a11y

| # | Ràng buộc | Kiểm ở đâu |
|---|---|---|
| R1 | 320dp @ `textScaler` 2.0 không overflow | `no overflow at 320dp with textScaler 2.0` |
| R2 | 390/412dp giữ nguyên anatomy, chỉ đổi bề rộng cột | `412dp keeps the anatomy and only widens the column` (393dp là mặc định của mọi test còn lại) |
| R3 | EN và VI cùng anatomy; VI dài hơn thì workload xuống dòng theo `Wrap`, **không cắt chữ** | `Vietnamese renders every band without overflowing` · `Vietnamese at 320dp and textScaler 2.0 still fits` (số lớn, và kiểm `didExceedMaxLines` — overflow thì ném, ellipsis thì im lặng nên phải hỏi thẳng). Nhãn count để `maxLines: 2` thay vì cắt: một con số **bị cắt** là một con số **sai**, không phải một con số ngắn, và `overdueCount` gộp cả subtree nên bốn chữ số là bình thường. `arb_parity_test.dart` chỉ kiểm khoá, không kiểm layout |
| R4 | Light và dark cùng cấu trúc, `secondaryContainer` đọc được ở cả hai | `study_home_screen_visual_audit_test.dart` (chạy cả hai brightness) |
| R5 | Ba chỉ số workload đọc thành **một** câu cho screen reader, không phải ba số rời | `study_home_accessibility_test.dart` |
| R6 | Tên hành động có kèm tên deck (`Study Everyday Korean`, `Resume Everyday Korean`) | `study_home_accessibility_test.dart` |
| R7 | Màu không bao giờ là tín hiệu duy nhất: mỗi chỉ số có icon + nhãn chữ + độ đậm | `study_home_accessibility_test.dart` |
| R8 | Chạm hai lần liên tiếp chỉ mở một màn | `two taps in one frame open one screen` |
| R9 | Tiêu đề `Study next` là **heading** với screen reader, không chỉ là chữ to | `the list heading is a heading to a screen reader` |
| R10 | Dòng supporting copy đổi theo việc có Resume hay không, không hứa chỗ để "học tiếp" khi không có | `the supporting line matches whether there is a resume` · `with nothing open it stops promising somewhere to carry on` |
| R11 | Đo lại đồng hồ (foreground, ranh giới due) **không** làm cả tab thành spinner và không mất vị trí cuộn | `re-measuring the clock does not blank the tab` (cuộn trước, rồi kiểm cả spinner lẫn `position.pixels`) |

## Nợ đã ghi

- `MxAsyncView.shouldSkipLoadingOnReload` là opt-in mới, và Study Home là caller
  duy nhất. Deck list có **cùng** cấu trúc — `ref.watch(deckListNowProvider)` —
  nên nhiều khả năng cũng nháy spinner khi app quay lại foreground; không sửa
  kèm ở đây vì nó viết lại một màn hình thay đổi này không có lý do nào khác để
  chạm, và vì hành vi đó chưa được đo trên màn ấy.

- Cơ chế hẹn giờ theo ranh giới due/nửa đêm hiện có **hai bản** — một trong
  `deck_list_controller.dart`, một trong `study_home_controller.dart` — vì
  `features/deck/presentation/` là thứ một feature khác không được import.
  Tách phần dùng chung xuống `core/` là việc riêng, không làm kèm ở đây vì nó
  sẽ viết lại một controller mà thay đổi này không có lý do nào khác để chạm.
