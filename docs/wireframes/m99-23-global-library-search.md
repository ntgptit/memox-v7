# Wireframe M99.23 — Global Library Search (deck · card · tag)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của màn tìm kiếm toàn thư viện để xây và review mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Màn tìm kiếm: lối vào, anatomy, hai nhóm kết quả, mọi trạng thái, hợp đồng geometry, responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-182…BR-190), luồng (UC-12), màn deck (`m4-11-card-management.md`) |
| **Source of truth for** | Anatomy màn Global Search · copy các trạng thái tìm kiếm · hợp đồng geometry của màn tìm kiếm · responsive/a11y contract của màn tìm kiếm |
| **Depends on** | `../use-cases.md` (UC-12), `../business-rules.md` (BR-182…BR-190), `../architecture.md` (AD-13, AD-15, AD-19), `m4-11-card-management.md` |
| **Updated by task** | M99.23 |
| **Last updated** | 2026-08-14 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

Tìm kiếm là màn duy nhất trong app đọc qua **hai** feature cùng lúc: tên deck
thuộc Deck, mặt card và tag thuộc Card. Đó là lý do nó không sống trong màn nào
trong hai màn đó.

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| S1 | Tìm kiếm là **route riêng** `/search` trong nhánh Library, không phải panel mở ra trong màn deck | Kết quả trải trên deck **và** card, nên bề mặt không thuộc feature nào trong hai feature đó — và `features/deck/presentation/` không được import widget của feature khác (AD-13). Một route là seam duy nhất hai bên cùng gọi tên được: header đẩy một `RouteNames` từ `core/`, không có gì khác được chia sẻ | 2026-08-14 |
| S2 | Route là **con của nhánh Library**, không phải route toàn màn hình | Thanh dưới còn nguyên, Back trả về đúng cấp vừa rời, và chuyển tab rồi quay lại vẫn thấy màn tìm kiếm đang mở. Một route toàn màn hình sẽ cắt người dùng khỏi chỗ họ vừa đứng để trả lời một câu hỏi về chính chỗ đó | 2026-08-14 |
| S3 | Ô nhập **ghim dưới app bar** (slot subheader của shell), không cuộn theo kết quả | Người dùng sửa câu truy vấn liên tục trong lúc đọc kết quả. Một ô nhập cuộn mất đi bắt họ cuộn ngược lên để sửa một chữ | 2026-08-14 |
| S4 | Tìm kiếm theo cấp bị **thay** bằng tìm kiếm toàn thư viện; không giữ cả hai | Hai ô tìm kiếm trong cùng một header là "dead control" mà chính codebase này đã từ chối một lần. Cái mất là phạm vi subtree; cái được là mỗi dòng kết quả mang **đường dẫn đầy đủ**, vốn trả lời câu hỏi thật ("mình để nó ở đâu") tốt hơn một danh sách tên trần đã được thu hẹp | 2026-08-14 |
| S5 | Hai mục có **tiêu đề nhóm, không có số đếm** | Danh sách phân trang, nên một con số ở tiêu đề là số **đã tải** chứ không phải số **tìm thấy**. Một câu trả lời sai nói chắc nịch tệ hơn không có câu trả lời. Tổng số chỉ hiện **một** chỗ — trên ô nhập — và chỉ khi mọi trang đã vào (S6) | 2026-08-14 |
| S6 | Không tô sáng đoạn khớp trong nội dung | Tô sáng là MAY của scope. Nó thêm một màu phải đạt tương phản, một quy tắc cắt chuỗi khi khớp nằm ngoài đoạn hiển thị, và một cách vô tình dựng lại nội dung thẻ bằng span. Thứ trả lời "vì sao dòng này ở đây" mà không tốn cái nào trong ba thứ đó là **tên tag đã khớp**, và nó chỉ hiện khi card khớp *chỉ* qua tag (BR-187) | 2026-08-14 |
| S7 | Trạng thái debounce và trạng thái loading **vẽ giống nhau**, nhưng là hai state khác nhau trong model | Người dùng không phân biệt được "đang chờ 250ms" với "đang đọc", nên hai hình khác nhau chỉ là nhấp nháy. Model vẫn tách hai vì chỉ một trong hai đã chạm database (BR-184), và test phải phân biệt được | 2026-08-14 |
| S8 | Kết quả cũ **ở lại** trong lúc gõ tiếp; chỉ trang đầu **lỗi** mới xoá danh sách | Câu trả lời cũ là thứ gần câu trả lời mới nhất cho tới khi câu mới tồn tại; một danh sách chớp tắt mỗi phím là danh sách không đọc được. Ngược lại, để kết quả cũ dưới một dòng "không tìm được" là nói dối về việc chúng trả lời câu hỏi đang nằm trong ô nhập | 2026-08-14 |
| S9 | Lỗi **trang sau** chỉ đổi dải cuối danh sách; không dựng error state toàn màn | Những gì đã tìm được vẫn đúng là những gì đã tìm được. Thay cả màn bằng một thông báo là vứt đi kết quả hợp lệ vì một trang chưa tới | 2026-08-14 |
| S10 | Kết quả card mở **chi tiết card ở chế độ đọc**; khi route đó chưa có thì nói thẳng ra | Đưa sang màn **sửa** card là mở một bề mặt ghi từ một thao tác đọc — cách nội dung bị đổi ngoài ý muốn. Dựng một màn chi tiết thứ hai trong feature này là tạo bản trùng để xoá sau (BR-189) | 2026-08-14 |
| S11 | Lối vào **push** route search, không `go` | `/search` là **anh em** của `/decks/:deckId` dưới `/`, nên `go` dựng lại match list thành `[/, /search]` và vứt mọi cấp bên dưới root — Back từ một tìm kiếm mở ở cấp ba rơi thẳng về danh sách gốc. Push giữ nguyên stack người dùng đã dựng, và vì route không có `parentNavigatorKey` nên nó vẫn nằm trên branch navigator: thanh dưới không đổi. Phát hiện ở review UI/UX M99.23 | 2026-08-14 |
| S12 | Dòng kết quả là **`MxCard`**, không phải `Material` + `InkWell` tự vẽ | Bản đầu vẽ lại đúng `surface` + `AppRadius.lg` + `borderSubtle` của card dùng chung, và thừa hưởng hai khuyết tật của việc là bản sao: **không có focus ring** — dòng tự khai `button: true`, màn hình này mở ra với bàn phím đang ở ô nhập, và một `InkWell` trần chỉ rơi về lớp phủ 10% mà chính doc của `AppStateOpacity.focus` đo được ~1.15:1, dưới mức 3:1 WCAG 1.4.11 đòi — và press rơi về splash của theme thay vì `AppInteractionStates.cardOverlay`. Phát hiện ở review UI/UX M99.23 | 2026-08-14 |

## W-cấu trúc

### W1 — Lối vào

Kính lúp nằm ở **subheader của Library**, cùng hàng với breadcrumb, ở mọi cấp —
gốc lẫn trong deck. Nhãn ngữ nghĩa và tooltip gọi tên **phạm vi** ("Search your
library"), không gọi tên hành động, vì phạm vi là thứ đổi so với bản trước.

Bấm vào đẩy route `/search`. Không có trạng thái "mở tại chỗ"; ô nhập sống ở màn
kia.

### W2 — Anatomy

```
┌──────────────────────────────────────────┐
│  ←   Search                              │  app bar (title 1 từ)
├──────────────────────────────────────────┤
│  🔍  Search decks, cards and tags    ✕    │  subheader: MxSearchField, ghim
├──────────────────────────────────────────┤
│  Decks                                   │  tiêu đề nhóm (labelSmall)
│  ┌────────────────────────────────────┐  │
│  │ 📁  Korean › Grammar               │  │  đường dẫn (labelSmall, muted)
│  │     Nouns                       ↗  │  │  tên deck (bodyLarge)
│  └────────────────────────────────────┘  │
│  Cards                                   │
│  ┌────────────────────────────────────┐  │
│  │ 📄  Korean › Grammar › Nouns       │  │  đường dẫn
│  │     noun                        ↗  │  │  mặt trước (bodyLarge, 1 dòng)
│  │     danh từ                        │  │  mặt sau (bodyMedium, muted, 1 dòng)
│  │     Tag: noun                      │  │  chỉ khi khớp *chỉ* qua tag
│  └────────────────────────────────────┘  │
│              Show more results           │  footer phân trang
├──────────────────────────────────────────┤
│   Library    Study   Progress  Settings  │  thanh dưới của shell
└──────────────────────────────────────────┘
```

Dòng deck hai dòng chữ, dòng card ba hoặc bốn. Cả hai dùng **một** khung: cùng
gutter, cùng bán kính, cùng viền, cùng sàn 48. Khác nhau đúng ở nội dung.

**Đường dẫn nằm trên tên, không nằm sau tên.** Ba sub-deck trong một thư viện
đều có thể tên "Nouns"; một danh sách tên trần là một danh sách dòng giống hệt
nhau mà người dùng phải mở từng cái mới phân biệt được.

### W3 — Mười trạng thái

| # | State | Body | Footer |
|---|---|---|---|
| 1 | initial — chưa gõ | Empty state: "Find anything in your library" + câu nói rõ bốn trường được tìm | không có |
| 2 | debouncing — đã gõ, chưa hết 250ms | Spinner **nếu chưa có kết quả cũ**; ngược lại giữ nguyên kết quả cũ (S8) | như trước |
| 3 | loading trang đầu | như (2) | như trước |
| 4 | mixed | Mục Decks rồi mục Cards | tải thêm / không có |
| 5 | decks-only | Chỉ mục Decks; **không** vẽ tiêu đề Cards rỗng | tải thêm / không có |
| 6 | cards-only | Chỉ mục Cards; **không** vẽ tiêu đề Decks rỗng | tải thêm / không có |
| 7 | no results | Empty state, tiêu đề nhắc lại **nguyên văn** đã gõ (không phải dạng đã fold) | không có |
| 8 | loading trang sau | Kết quả giữ nguyên | spinner có nhãn cho screen reader |
| 9 | lỗi trang sau | Kết quả giữ nguyên (S9) | dòng lỗi + `Try again` |
| 10 | lỗi trang đầu | Error state, danh sách trống (S8) | không có |

Trạng thái (2) và (3) vẽ giống nhau là **cố ý** — xem S7.

### W4 — Bàn phím, Back và xoá

- Vào màn: ô nhập nhận focus ngay. Lần chạm mở màn **là** yêu cầu gõ.
- `✕` trong ô: xoá nội dung, về state (1) tức thì, không đọc gì (BR-184).
- Back / cử chỉ back: rời route, về đúng cấp đã mở tìm kiếm. Không có bước
  trung gian "đóng ô nhập rồi mới đóng màn" — ô nhập và màn là một.
- Bàn phím mở: danh sách cuộn được tới dòng cuối; footer không bị bàn phím
  che ở 320×568.

### W5 — Hợp đồng geometry

Đo bằng `tester.getRect`, không đo bằng mắt.

| # | Ràng buộc | Cách đo |
|---|---|---|
| G1 | Ô nhập, tiêu đề nhóm và mọi dòng kết quả chung **một** mép trái, **ở cả hai phía breakpoint compact** | `left` của `MxSearchField` == `left` của `DeckResultTileWidget` == `left` của `CardResultTileWidget` == `left` của tiêu đề nhóm, đo ở **320** và **390** |
| G2 | Hai dòng của hai nhóm cùng **một** chiều rộng — một cột bề mặt | `width` bằng nhau |
| G3 | Ô nhập nằm **trên** kết quả và không cuộn qua nó | `bottom` của ô nhập ≤ `top` của dòng đầu tiên |
| G4 | Nhóm Decks nằm trên nhóm Cards | `bottom` dòng deck cuối ≤ `top` dòng card đầu |
| G5 | Mọi dòng ≥ 48dp | `height` của mỗi dòng |
| G6 | Không tràn ở 320@2.0, 390 và 412 với nội dung Hàn/Việt dài | `takeException()` là null và cả hai dòng vẫn dựng được |

**Gutter đến từ shell, không phải hằng số trong body.** Ô nhập sống ở slot
subheader và lấy `mxScreenGutter` — `md` (12) dưới breakpoint compact, `lg` (16)
từ đó trở lên. Body **MUST** đọc cùng hàm đó; ba `AppSpacing.lg` hardcode làm
dòng kết quả thụt vào 4dp so với ô nhập ở 320 và khớp ở 390, tức là một lỗi chỉ
lộ ra ở đúng viewport hẹp nhất. Đây là bài học `deck_path_widget.dart` đã ghi
lại một lần.

**Test đo geometry MUST giữ nguyên `MediaQuery` của cây, chỉ `copyWith` thứ nó
đổi.** Dựng một `MediaQueryData()` mới sẽ zero `size`, `padding` và `viewInsets`
— `MediaQuery.sizeOf` trả 0, mọi shell rẽ nhánh compact bất kể surface, và bộ
viewport tham số hoá chạy ba lần trên đúng một layout.

### W6 — Responsive & a11y

- Viewport bắt buộc kiểm: **320×568 @ textScaler 2.0**, 390 và 412.
- Ngôn ngữ: EN và VI, cả hai theme sáng/tối.
- Mỗi dòng là một `Semantics(button: true)` với **một** nhãn gộp: loại (Deck /
  Card), nội dung, rồi đường dẫn. Các `Text` con bị `ExcludeSemantics` để screen
  reader đọc một câu thay vì bốn mảnh theo thứ tự layout.
- Mặt sau bị cắt còn một dòng trên màn hình nhưng **đủ nguyên văn** trong nhãn
  ngữ nghĩa: dấu ba chấm là quyết định layout, không phải quyết định bỏ nội dung
  khỏi cây accessibility.
- **Tên tag đã khớp MUST nằm trong nhãn ngữ nghĩa**, không chỉ trên chip. Chip
  nằm trong `ExcludeSemantics` của dòng, và S6 đã cố ý bỏ tô sáng — nên với
  người dùng screen reader, tag là **tín hiệu duy nhất còn lại** trả lời "vì sao
  dòng này ở đây", và một nhãn không có nó là một dòng không giải thích được.
- **Ký tự phân cách đường dẫn thuộc ARB**, không phải literal trong widget: nó
  vừa được vẽ vừa được đọc lên giữa từng cặp tên, nên glyph là quyết định của
  người dịch. `MxBreadcrumb` giải cùng bài toán bằng **icon** decorative; một
  separator dạng text không có lối thoát đó.
- **Dòng kết quả MUST có focus ring** (S12). Lớp phủ 10% một mình đo ~1.15:1 và
  không đạt 3:1 của WCAG 1.4.11; ring là phần mang yêu cầu đó.
- Tiêu đề nhóm là `Semantics(header: true)`.
- Spinner tải-thêm và dòng lỗi tải-thêm đều là `liveRegion` — danh sách dừng
  giữa chừng thì phải nói ra, nếu không người dùng không phân biệt được "hết
  rồi" với "trang sau hỏng".
- Chuỗi tiêu đề nhóm hiển thị **đúng như ARB viết**; không `toUpperCase()` ở
  widget, vì đó là quyết định của người dịch và nó đổi bề rộng mà layout đã đo.
