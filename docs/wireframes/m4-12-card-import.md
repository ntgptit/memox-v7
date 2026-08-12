# Wireframe M4.12 — Card Import (Source → Preview → Import)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của wizard import card để M99.19 xây mà không phải đoán layout, copy hay state nào |
| **Scope** | Màn import: ba bước, entry point, back/close, error/result states. Ngoài phạm vi: luật nghiệp vụ (BR-168…BR-173), luồng (UC-10), export |
| **Source of truth for** | Anatomy màn import · copy các panel · hành vi Back/Close/draft · responsive/a11y contract của wizard |
| **Depends on** | `../use-cases.md` (UC-10), `../business-rules.md` (BR-168…BR-173), `m4-11-card-management.md` |
| **Updated by task** | M99.19 |
| **Last updated** | 2026-08-12 |

Concept tham chiếu là một mockup mobile (dark) với app bar, breadcrumb, stepper
ba bước, chip deck đích, hai lựa chọn nguồn, panel thông tin và sticky action.
Concept chỉ quyết **hierarchy**; mọi màu, chữ, spacing, radius lấy từ design
token hiện có. Ba điểm concept bị sửa có chủ đích:

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

## W-cấu trúc

### W1 — Khung màn (mọi bước)

- App bar: Close (trái) · title `Import cards`. Không có nút Help.
- Breadcrumb (component hiện có): đường dẫn deck, segment cuối `Import` không
  bấm được.
- Chip ngữ cảnh: icon deck · tên deck đích · số card hiện có.
- Stepper: `1 Source — 2 Preview — 3 Import`, semantics "Step n of 3", giữ
  nguyên cấu trúc khi loading/error.
- Sticky bottom bar: một primary action theo bước; tránh keyboard/IME; không
  che nội dung cuối (nội dung scroll có padding đáy).

### W2 — Bước Source

- Hai lựa chọn nguồn dạng card: `Upload file` (CSV, TSV, XLSX) và `Paste text`
  (CSV or TSV rows). Hai cột khi đủ rộng; wrap thành một cột khi hẹp/textScale
  lớn. Selected: viền primary + glyph + `Semantics(selected: true)` — không chỉ
  màu, không fill đậm.
- Upload: copy `Choose a file to preview` + nút `Choose file`; khi có file:
  tên, đuôi, kích thước (nếu có) và action Replace.
- Paste: ô nhập nhiều dòng, placeholder CSV/TSV ngắn (dữ liệu mẫu, không phải
  dữ liệu người dùng).
- Panel thông tin: title `Each row creates one card`; body `Front and Back are
  required. You will choose the matching columns in the next step.` kèm một
  dòng nghiệp vụ `Front stores the Korean term. Back stores its meaning.`
- Primary: `Preview import`, disabled khi chưa có nguồn.

### W3 — Bước Preview

- Tóm tắt nguồn; selector sheet (chỉ XLSX nhiều sheet, mặc định sheet không
  rỗng đầu tiên); toggle `First row contains headers` (mặc định bật; tắt thì
  cột hiện `Column A/B/C…`).
- Mapping list: mỗi cột nguồn một hàng → dropdown đích (Front/Back/Example/
  Hint/Pronunciation/Tags/Ignore); một đích không nhận hai cột; Front và Back
  bắt buộc.
- Summary counts: Total rows · Ready · Duplicates · Invalid · Blank skipped.
- Toggle `Include duplicates`, mặc định tắt.
- Preview 10–20 hàng đầu theo số hàng nguồn, mỗi hàng: trạng thái (valid /
  invalid / duplicate existing / duplicate in file / blank) + lý do có kiểu khi
  invalid; nội dung dài hiển thị tóm tắt, không phải editor.
- Primary: `Continue`, disabled khi Front/Back chưa map, mapping trùng đích,
  hoặc số sẽ ghi bằng 0. Secondary: `Back`.

### W4 — Bước Import

- Confirm summary: deck đích · số sẽ ghi · số trùng bỏ/ghi · số invalid loại ·
  số hàng trống bỏ qua.
- Primary: `Import N cards`; khi đang ghi: mọi action gây submit lần hai bị
  khoá, hiện tiến trình; không hiện fake per-row progress — commit là atomic.
- Lỗi commit: giữ nguyên preview/mapping/nguồn, hiện `Try again`; không lộ
  exception/SQL/path.
- Thành công: Imported · Duplicates skipped · Invalid rows skipped · tên deck;
  actions `View cards` và `Import another file` (I7).

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
