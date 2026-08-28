# Wireframe M4.12 — Card Import (Source → Preview → Import)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của wizard import card để M99.19 xây mà không phải đoán layout, copy hay state nào |
| **Scope** | Màn import: ba bước, entry point, back/close, error/result states. Ngoài phạm vi: luật nghiệp vụ (BR-168…BR-173), luồng (UC-10), export |
| **Source of truth for** | Anatomy màn import · copy các panel · hành vi Back/Close/draft · responsive/a11y contract của wizard |
| **Depends on** | `../use-cases.md` (UC-10), `../business-rules.md` (BR-168…BR-173), `m4-11-card-management.md` |
| **Updated by task** | M99.19 · M99.19a |
| **Last updated** | 2026-08-13 |

Concept tham chiếu là một mockup mobile (dark) với app bar, breadcrumb, stepper
ba bước, chip deck đích, hai lựa chọn nguồn, panel thông tin và sticky action.
Concept quyết **hierarchy và các quan hệ layout** (gutter chung, tỉ lệ, grouping,
thứ tự); màu, typography, giá trị spacing và radius cụ thể lấy từ design token
hiện có. Ba điểm concept bị sửa có chủ đích:

- Concept ghi "CSV, TSV, Anki" và "up to 5 MB" — v1 **không** hỗ trợ `.apkg`
  (out of scope M99.19) và không đặt trần 5 MB chỉ vì concept ghi vậy.
- Concept ghi "Drop a file or tap to browse" — drag-and-drop không phải
  capability chính trên Android; copy là "Choose a file to preview".
- Concept ghi "Column 1 = front · column 2 = back" — sai với mapping (UC-10
  bước 4); panel thông tin không ghi cứng thứ tự cột.

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| I1 | Wizard là **một route full-screen** (`/decks/:deckId/cards/import`), ba bước đổi trong màn, không phải ba route | Draft import là một khối state sống chung (nguồn, mapping, policy); tách route là tách state hoặc kéo state lên global. Back trong wizard là "về bước trước", Back ở bước 1 là "rời màn" — PopScope xử lý được trong một route | 2026-08-12 |
| I2 | Stepper ba bước **không cho tap nhảy tới bước chưa hợp lệ**; đi tới chỉ bằng primary action | Bước sau tiêu thụ kết quả bước trước (parse → mapping → commit); nhảy cóc tạo state không có nguồn | 2026-08-12 |
| I3 | Bar hành động **sticky dưới đáy**, một primary action mỗi bước; không có nút Cancel cạnh primary (Close đã ở app bar) | Hai lối thoát cùng nghĩa là hai chỗ phải giữ đồng bộ hành vi confirm-discard | 2026-08-12 |
| I4 | Paste text giữ trong ô nhập của màn; **chỉ parse khi bấm Preview**, không parse theo keystroke; parse lỗi giữ nguyên văn bản | Parse mỗi keystroke là việc nặng chạy sai lúc; mất văn bản khi lỗi là mất công dán lại cả nghìn dòng | 2026-08-12 |
| I5 | Hủy hộp chọn file không phải lỗi, không xoá file đã chọn trước; không hỏi confirm-discard khi picker bị hủy | Hủy là "thôi, giữ nguyên", không phải một quyết định về draft | 2026-08-12 |
| I6 | Mapping hiển thị dạng **list hàng dọc** (cột nguồn → dropdown đích), không phải bảng ngang kiểu desktop | 360px với textScale 2.0 không chứa bảng nhiều cột; list hàng dọc wrap tự nhiên | 2026-08-12 |
| I7 | Kết quả import là state của bước 3, không phải màn riêng; View cards quay về card list hiện có (stream tự cập nhật), Import another file reset draft giữ deck đích | Route stack không phình; card list không reload | 2026-08-12 |
| I8 | Toàn wizard chuyển sang **`MxContentShell`**: context (breadcrumb → stepper → deck chip) là **subheader ghim**, footer dùng slot của shell, body là reading column `AppBreakpoints.medium` neo top-center | Màn này là màn card cuối cùng tự sở hữu gutter/SafeArea/keyboard inset — ba câu trả lời shell đã sở hữu một lần. Context ghim vì “đang ở bước nào” trượt khỏi màn đúng lúc preview dài nhất. Bar cũ tự cộng `viewInsets.bottom` là số học chết — Scaffold đã tiêu inset trong body | 2026-08-28 |
| I9 | Visual grammar kế thừa **Card Detail**: section label UPPERCASE (`sectionLabel` + `onSurfaceVariant`) ngoài panel, `MxCard.flat` full-width trong một cột cuộn (D20 — không hai độ sâu cạnh tranh), fact row = `MxMetricWell` + label + count **tabular figures** neo trailing | Import từng rải control trần trên nền và trộn `raised` với flat; Card Detail đã chứng minh flat surface + section hierarchy quét nhanh hơn. Source option giữ hairline theo đúng owner decision M99.70 ghi trong `MxCard.option` | 2026-08-28 |
| I10 | Preview gồm **hai semantic panel**: Mapping (source row nhúng · sheet · header toggle · MATCH COLUMNS · các hàng ghép cột) và Preview (chips · Include duplicates · rows) — không control nào lơ lửng giữa sections | Mỗi panel là một câu hỏi: “nhập cái gì, ghép thế nào” và “kết quả phân loại ra sao”. Include duplicates nằm trong panel Preview vì nó đổi con số của chính panel đó | 2026-08-28 |
| I11 | Parsing và Submitting có **golden riêng** (`card_import_parsing_light.png`, `card_import_submitting_light.png`), spinner pin bằng pump duration cố định | Hai phase này chưa từng có bằng chứng ảnh — skeleton sai ở đây là loại lỗi mọi gate text-based đều mù | 2026-08-28 |

## W-cấu trúc

### W1 — Khung màn (mọi bước)

- App bar: Close (trái) · title `Import cards`. Không có nút Help.
- Header theo thứ tự concept: breadcrumb (segment cuối `Import` không bấm
  được) → stepper `1 Source — 2 Preview — 3 Import` (semantics "Step n of 3",
  giữ nguyên cấu trúc khi loading/error) → chip ngữ cảnh (icon deck · tên
  deck đích · số card hiện có).
- Sticky bottom bar: một primary action theo bước; tránh keyboard/IME; không
  che nội dung cuối (nội dung scroll có padding đáy). Dưới hàng action là một
  dòng reassurance theo phase (states 1–4): Source `Next you'll preview every
  row…`, Parsing `Reading your source — nothing is saved yet.`,
  Preview/Confirm `No cards are added until you tap Import.` Outcome và panel
  submit không có dòng này — copy của chúng đã tự nói.

### W2 — Bước Source

- Hai lựa chọn nguồn dạng card: `Upload file` (CSV, TSV, XLSX) và `Paste text`
  (CSV or TSV rows). Hai card **chia đôi cột nội dung** — card trái bắt đầu ở
  mép trái, card phải kết thúc ở mép phải, bằng chiều rộng và bằng chiều cao;
  khi không đủ chỗ (hẹp/textScale lớn) thì stack, mỗi card full-width. Không
  bao giờ co về intrinsic width để hàng hụt so với các band khác. Selected:
  viền primary + glyph + `Semantics(selected: true)` — không chỉ màu, không
  fill đậm.
- Upload: copy `Choose a file to preview` + nút `Choose file`. Khi có file,
  cả panel chọn được thay bằng **một card tóm tắt gọn** (state 1): icon file ·
  tên (tối đa 2 dòng, ellipsis) · `CSV · 1 KB · Ready to preview`; tap card =
  Replace (semantics nói rõ), X ở đuôi = Remove — Remove là một mutation của
  draft qua controller, không phải ẩn UI. Picker hủy giữ nguyên file cũ (I5).
- Paste: ô nhập nhiều dòng, placeholder CSV/TSV ngắn (dữ liệu mẫu, không phải
  dữ liệu người dùng).
- Panel thông tin: title `Each row creates one card`; body `Front and Back are
  required. You will choose the matching columns in the next step.` kèm một
  dòng nghiệp vụ `Front stores the Korean term. Back stores its meaning.` và
  một dòng tags `Tags share one cell, separated by ;`. Không ghi cứng
  "Column 1 = front".
- Primary: `Preview import`, disabled khi chưa có nguồn — một primary duy nhất.

### W3 — Bước Preview

- Tóm tắt nguồn là **một dòng context gọn** ở đầu bước (cùng component với
  card tóm tắt của W2, không có Replace/Remove): tên file hoặc `Pasted text` ·
  meta · trạng thái decode (`Parsing…` → `N rows detected`). Không lặp lại cả
  bộ chọn nguồn, không echo nội dung paste (BR-173).
- Selector sheet (chỉ XLSX nhiều sheet, mặc định sheet không rỗng đầu tiên);
  toggle `First row contains headers` (mặc định bật; tắt thì cột hiện
  `Column A/B/C…`).
- Mapping list: mỗi cột nguồn một hàng → dropdown đích (Front/Back/Example/
  Hint/Pronunciation/Tags/Ignore); một đích không nhận hai cột; Front và Back
  bắt buộc.
- Kết quả phân loại: heading `2 · Preview` với `N of N ready` bên phải, dưới
  là **chip theo trạng thái** (icon + chữ + số, không chỉ màu): `Ready` luôn
  hiện, `Invalid`/`Duplicate`/`Blank` chỉ khi > 0. Hai loại duplicate chung
  một chip; hàng chi tiết mới phân biệt `Already in deck` / `Duplicate in
  file`.
- Toggle `Include duplicates`, mặc định tắt.
- Preview 10–20 hàng đầu theo số hàng nguồn, mỗi hàng: số hàng nguồn · Front ·
  Back (hai cột, stack ở 320dp/textScale lớn) · glyph trạng thái; hàng invalid
  ghi **lý do có kiểu** từ validation hiện có (`Back can't be empty`…), không
  bao giờ chỉ "Missing term/meaning"; ô trống hiện `(empty)` nghiêng. Nội dung
  dài ellipsis — đây là checkpoint, không phải editor.
- Primary: `Continue`, disabled khi Front/Back chưa map, mapping trùng đích,
  hoặc số sẽ ghi bằng 0. Secondary: `Back`.

### W4 — Bước Import

- Confirm summary (giữ nguyên, không bỏ bước xác nhận) nói cùng ngôn ngữ
  summary-row với Result: một card, dòng đầu `Into {deck}`, rồi mỗi fact một
  hàng icon + label + count ở mép phải (Cards to import · Duplicates
  skipped/included · Invalid rows skipped · Blank rows ignored). Count 0 vẫn
  hiện — đây là bản hợp đồng trước khi ghi.
- Primary: `Import N cards`; khi đang ghi, panel confirm được thay bằng
  **panel submit** (state 5): một loader indeterminate duy nhất ·
  `Importing N cards…` · `Saving all cards together. Don't close the app.`
  Không bao giờ hiện `29 of 47`, phần trăm hay progress bar determinate —
  commit là một transaction atomic, không có tiến trình per-row trung thực.
  Primary đổi nhãn `Importing…` và disabled, **không** mang spinner thứ hai.
- Khi đang ghi: Close, Android Back, Back và submit lần hai đều bị khoá cho
  tới khi transaction kết thúc (thành công hay thất bại).
- Mọi kết cục (thành công / skips / zero-added / lỗi commit) là **outcome
  mode** của cùng route — xem W8, không phải state của riêng bước 3.

### W5 — Back, Close, draft

- Chưa có nguồn: Close/Back rời màn ngay.
- Đã có nguồn hoặc mapping đã chỉnh: Close/Android Back hỏi confirm bỏ draft
  (`Discard import?`).
- Back ở bước 2/3 về bước trước, giữ nguyên state.
- Draft không sống qua app restart (v1).

### W6 — Entry point

- Card list (deck loại card): `Import cards` trong overflow menu của app bar;
  selection mode không hiện action import.
- Card list rỗng: empty state có cả `Create first card` và `Import cards`.
- Deck `unset`: lựa chọn tạo phần tử con có thêm `Import cards` bên cạnh Create
  sub-deck / Create card; deck feature điều hướng bằng route name (AD-13).
- Root deck và deck đang giữ deck con: không có action import ở bất kỳ đâu
  (BR-168).

### W7 — Responsive & a11y

Kiểm ở 320/360/412, textScale 1.0/2.0, light/dark, keyboard mở ở Paste,
tiếng Việt dài, tên file dài, header cột dài, tên deck dài. Không overflow;
icon-only có semantic label; lỗi không chỉ biểu thị bằng màu; sticky bar không
che nội dung; scroll tới được mọi hàng mapping.

### W8 — Tám trạng thái trình bày (M99.19a)

Màn import có một **phase trình bày dẫn xuất** (enum, tính từ step + trạng
thái parse + trạng thái commit, không bao giờ persist): `source → parsing →
preview → confirm → submitting → completed / completedWithSkips /
noCardsAdded / commitFailure`. Body, stepper và sticky bar cùng đọc một phase
— ba nơi không bao giờ lệch nhau.

**Progressive disclosure.** Mỗi trạng thái chỉ thay phần thay đổi: nguồn đã
chọn co lại thành một dòng context (không lặp bộ chọn), panel parsing giữ
nguyên khung khi rows tới, panel submit thay panel confirm tại chỗ.

1. **Source ready** — card tóm tắt file (W2), step Source mang check.
2. **Parsing** — panel loading `Reading your file…` / `Reading your rows…` +
   `No cards will be added until you confirm Import.`; primary disabled
   `Parsing…`; chưa có gì được ghi.
3. **Preview all-valid** — heading + `N of N ready` + chip `Ready · N`
   (W3); Back + Continue — **không có** import trực tiếp từ Preview.
4. **Preview mixed** — thêm chip Invalid/Duplicate/Blank; hàng lỗi mang lý do
   có kiểu; luật disable Continue giữ nguyên (W3).
5. **Submitting** — panel submit + khoá điều hướng (W4).
6. **Complete** — outcome mode: app bar đổi title `Import results`;
   breadcrumb, chip ngữ cảnh và stepper **ẩn**; hero `Import complete` +
   `Added N cards to {deck}. They are ready to study.`; card tóm tắt hàng
   `Added N` (từ kết quả transaction); actions `Import another file`
   (secondary) + `View cards` (primary).
7. **Complete with skips** — khi preview có invalid > 0 **hoặc** transaction
   báo duplicates skipped > 0 (hàng blank **không** kích hoạt mặt cảnh báo —
   bỏ blank là by design, BR-169). Hero `Imported with skips`; hàng tóm tắt
   theo nguyên nhân, chỉ hiện khi > 0; hint theo nguyên nhân (fix invalid /
   duplicates theo setting). Imported + duplicates-skipped lấy từ transaction,
   invalid + blank lấy từ preview — hai nguồn số liệu không trộn.
   - Edge: transaction thành công nhưng imported = 0 → mặt `No new cards
     added` (info, không phải lỗi).
8. **Commit failure** — outcome layout: hero `Import didn't finish` + `No
   cards were added. Your source is unchanged and your deck is untouched.`
   ("source", không phải "file" — áp cho cả paste) + chi tiết an toàn có
   kiểu; actions `Back to preview` (secondary, xoá trạng thái commit, giữ
   nguyên toàn bộ draft) + `Try again` (primary, submit lại đúng plan đã giữ —
   không re-pick, không re-parse, không transaction chồng nhau). Close và
   Android Back trên mặt failure hỏi discard draft ngay — không bước lùi
   ngầm, vì phase dẫn xuất từ commit trước step nên lùi step không đổi gì
   trên màn; trên các mặt thành công Close/Back rời màn không hỏi.

**Stepper contract.** Ba mặt phân biệt: completed (check) / current (số, cặp
primary) / future (số, container nhạt). Check là **earned**: Source khi đã có
nguồn; Preview chỉ khi document đã load + mapping đủ + importable > 0.
Connector tô khi bước trước nó completed. Outcome mode ẩn cả stepper.
Semantics đọc `bước · tên · trạng thái` ở mọi presentation; không tap-jump
(I2 giữ nguyên).
