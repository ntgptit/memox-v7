# Wireframe M99.33 — Trash và restore (list → target → confirm)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của Trash để xây mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Entry point, danh sách Trash, chế độ chọn, picker target, hộp thoại purge, snackbar Undo, hợp đồng geometry và responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-256…BR-267), luồng (UC-21), mô hình tombstone (AD-22) |
| **Source of truth for** | Anatomy màn Trash · copy các panel Trash · hợp đồng geometry của Trash · responsive/a11y contract của Trash |
| **Depends on** | `../use-cases.md` (UC-21), `../business-rules.md` (BR-256…BR-267), `../architecture.md` (AD-22), `m4-11-card-management.md` |
| **Updated by task** | M99.33 |
| **Last updated** | 2026-08-20 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

Trash là màn hình duy nhất trong app mà **hai hành động đối nghịch nhau nằm cạnh
nhau**: một hành động cứu dữ liệu và một hành động phá huỷ nó vĩnh viễn. Toàn bộ
các quyết định dưới đây xoay quanh việc làm cho hai hành động đó không bao giờ
trông giống nhau.

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| T1 | Trash là **route riêng trong branch Library** (`/trash`), entry là một action cố định trên app bar của danh sách root | Trash chứa nội dung Library, không phải thiết lập. Đặt ở Settings thì lối vào của một tính năng cứu dữ liệu nằm sau hai lần chạm ở một branch không liên quan — và Settings hiện là placeholder (AD-19) | 2026-08-13 |
| T2 | Entry point **luôn hiện**, kể cả khi Trash rỗng; không có badge đếm | Người dùng cần biết Trash tồn tại *trước* khi họ xoá nhầm, chứ không phải sau. Badge đếm biến một khu vực bình thường thành một thứ trông như cần xử lý | 2026-08-13 |
| T2a | **Amend T1/T2:** entry dời từ action cố định trên app bar vào **overflow menu duy nhất của app bar root** (`showLibraryMenu`); vẫn luôn hiện trong menu đó, vẫn không badge | Redesign header Library (owner mockup 2026-08-20): bar chỉ giữ search, create và một kebab — Trash là hành động *thỉnh thoảng*, một tap sâu hơn nhưng vẫn khám phá được từ root trước khi ai đó xoá nhầm. Ghi nhận tại `docs/reviews/design-parity-checklist.md` (Library header pass) | 2026-08-20 |
| T3 | Tách Cards / Decks bằng **filter chip trên một danh sách**, không phải `TabBar` | Trash hầu như luôn ngắn. Hai tab cho hai danh sách vài hàng là hai màn hình rỗng thay vì một; chip cũng giữ được trạng thái "All" mà tab không có, và All là mặc định đúng | 2026-08-13 |
| T4 | Mỗi hàng nêu **tên · loại · đã xoá khi nào · còn lại bao nhiêu ngày · đường dẫn gốc**; deck nêu thêm số item đi kèm | Bốn câu hỏi người dùng thực sự hỏi trước khi khôi phục hoặc xoá hẳn. "Còn lại N ngày" là thứ duy nhất trong màn có tính khẩn, nên nó là thứ duy nhất được phép mang màu nhấn | 2026-08-13 |
| T5 | Đường dẫn gốc là **dòng phụ, chữ nhỏ, không có affordance**; không phải nút, không phải link | BR-267 — nó là ngữ cảnh, không phải nơi item sẽ về. Một đường dẫn trông bấm được nói ngược lại BR-261 trước khi người dùng kịp đọc dialog | 2026-08-13 |
| T6 | `Restore` là hành động chính của hàng (trailing button); `Delete permanently` nằm trong overflow của hàng | Hành động cứu dữ liệu phải rẻ hơn hành động phá huỷ nó. Đặt cả hai ngang nhau là mời một lần chạm nhầm không hoàn tác được | 2026-08-13 |
| T7 | Chọn nhiều **khoá theo loại của item đầu tiên**: chọn một card thì mọi hàng deck mất khả năng chọn và ngược lại; thanh chọn nói rõ lý do | BR-266. Hiện checkbox rồi từ chối lúc submit là dạy người dùng một quy tắc bằng một lỗi | 2026-08-13 |
| T8 | Picker target là **bottom sheet**, dựng từ đúng eligibility của move; **không** có hàng bị vô hiệu hoá | BR-261, E1 của M4.13 cùng lập luận. Một hàng xám vẫn là một hàng phải đọc, và nó không nói được vì sao nó xám | 2026-08-13 |
| T9 | Picker **preselect** một target hợp lệ khi vị trí cũ vẫn hợp lệ, nhưng primary vẫn phải bấm | BR-262 — preselect tiết kiệm một lần chạm mà không biến im lặng thành đồng ý | 2026-08-13 |
| T10 | Chỉ `Delete permanently` mang vai trò màu destructive; `Restore` và mọi thứ khác dùng vai trò bình thường | BR-266. Nếu soft-delete cũng đỏ thì màu đỏ không còn nghĩa gì ở đúng chỗ nó phải có nghĩa | 2026-08-13 |
| T11 | Hộp thoại purge nêu **đúng số item**, nói lịch sử học không khôi phục được, và đặt focus mặc định ở `Cancel` | BR-266. Focus mặc định ở hành động phá huỷ biến phím Enter thành một cách mất dữ liệu | 2026-08-13 |
| T12 | Batch hết hạn biến mất **tại chỗ** khi auto-purge chạy; danh sách không cuộn lại đầu và không hiện spinner | UC-21 A4. Danh sách là một `watch()` stream, nên thứ đúng để xảy ra là một hàng biến mất, không phải một lần tải lại | 2026-08-13 |
| T13 | Undo là **snackbar tại màn vừa xoá**, không phải một banner trong Trash | Undo chỉ có nghĩa khi người dùng còn ngữ cảnh của thao tác (BR-263). Trong Trash thì hành động đúng đã là `Restore` | 2026-08-13 |

## W-cấu trúc

### W1 — Entry point

App bar của danh sách root mang, theo thứ tự: `add` (tạo deck) rồi `delete_outline`
(Trash). Trash là action **cuối** cùng phía end. Nó không có badge (T2), có
tooltip và semantic label riêng, và nằm ngoài overflow.

### W2 — Anatomy màn Trash

```
┌─────────────────────────────────────────┐
│ ←  Trash                          [☰]   │  app bar: title + overflow (Select)
├─────────────────────────────────────────┤
│  ( All )  ( Cards )  ( Decks )          │  filter chips — subheader
├─────────────────────────────────────────┤
│  Items are deleted forever after 30 days│  dòng giải thích, một lần, không đóng được
├─────────────────────────────────────────┤
│ ▣  Phrasal verbs                  [⟲] ⋮ │  hàng deck: icon · tên · Restore · overflow
│    Deleted 2 days ago · 27 days left    │
│    From  English › Grammar              │  đường dẫn gốc (T5)
│    12 decks, 340 cards                  │
├─────────────────────────────────────────┤
│ ▤  give up                        [⟲] ⋮ │  hàng card
│    Deleted 5 minutes ago · 30 days left │
│    From  English › Grammar › Phrasal…   │
└─────────────────────────────────────────┘
```

### W3 — Trạng thái

| # | State | Hình dạng |
|---|---|---|
| 1 | loading | skeleton ba hàng, giữ nguyên chip và dòng giải thích |
| 2 | empty | icon + `Nothing in Trash` + một dòng nói item đã xoá ở đây 30 ngày. Không chip, không overflow |
| 3 | cards-only | chip `Decks` vẫn hiện và vẫn bấm được, cho ra empty state có phạm vi riêng |
| 4 | decks-only | đối xứng với 3 |
| 5 | mixed | mặc định |
| 6 | selection (card) | app bar đổi thành `N selected`, hàng deck mờ và không nhận chạm, thanh dưới có `Restore` + `Delete permanently` |
| 7 | selection (deck) | đối xứng với 6 |
| 8 | restoring | hàng đang xử lý khoá tương tác, primary của sheet đổi sang trạng thái chờ; các hàng khác vẫn dùng được |
| 9 | purging | như 8, thanh chọn khoá |
| 10 | target picker — nhiều | danh sách target cuộn được, một hàng preselect (T9) |
| 11 | target picker — rỗng | không hiện danh sách; một dòng nói vì sao (cây đã đầy 10 cấp / không còn deck nhận được loại này) và chỉ có `Close` |
| 12 | validation conflict | dải lỗi trong sheet, giữ nguyên lựa chọn, `Try again` tải lại danh sách target |
| 13 | expired-live-removal | hàng biến mất tại chỗ, không cuộn (T12) |
| 14 | error + Retry | dải lỗi trên đầu danh sách, danh sách cũ giữ nguyên bên dưới |
| 15 | undo snackbar | ở màn vừa xoá, `Moved to Trash` + action `Undo` |

## G-hợp đồng geometry

Mọi số đo dưới đây được pin bằng `getRect` trong test golden/geometry, không phải
bằng mắt. `gutter` là gutter màn hình của `MxContentShell` ở breakpoint đang đo.

| # | Ràng buộc |
|---|---|
| G1 | Mép trái của chip đầu tiên, của dòng giải thích và của mọi hàng MUST bằng nhau và bằng `gutter` |
| G2 | Mép phải của overflow hàng MUST bằng mép phải của overflow app bar |
| G3 | Ba dòng text trong một hàng MUST cùng mép trái; icon loại nằm ngoài mép đó |
| G4 | Baseline của `Restore` MUST trùng baseline của dòng tên trong cùng hàng |
| G5 | Thanh chọn MUST neo mép dưới an toàn (`viewPadding.bottom`), và MUST NOT che hàng cuối — danh sách nhận thêm bottom inset bằng chiều cao thanh |
| G6 | Sheet target MUST giữ nguyên chiều cao giữa state 10 và state 8; chỉ dải lỗi (state 12) được phép làm nó cao lên |
| G7 | Hộp thoại purge MUST có `Cancel` ở vị trí start của hàng action, `Delete permanently` ở vị trí end |
| G8 | Snackbar Undo MUST NOT che FAB hay thanh điều hướng dưới; nó dùng inset của shell |

## R-responsive và a11y

| # | Ràng buộc |
|---|---|
| R1 | 320dp @ `textScaler` 2.0: hàng MUST không tràn ngang; tên và đường dẫn cắt bằng ellipsis, `còn lại N ngày` MUST không bị cắt |
| R2 | EN và VI: mọi copy MUST đến từ ARB; không chuỗi nào hardcode |
| R3 | Light và dark: vai trò destructive MUST đạt tương phản tối thiểu ở cả hai theme |
| R4 | Mọi icon-only control MUST có `semanticLabel` và tooltip |
| R5 | Hàng MUST đọc được thành một node semantics duy nhất mang tên, loại, thời điểm xoá và số ngày còn lại |
| R6 | Snackbar Undo MUST có thời lượng đủ dài để đọc và MUST có action đọc được bằng screen reader |
