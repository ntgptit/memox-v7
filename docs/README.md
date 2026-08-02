# Documentation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chỉ mục tài liệu — cái gì tồn tại, cái gì cố ý chưa viết, và ai sở hữu cái gì |
| **Scope** | Toàn bộ `docs/`. Ngoài phạm vi: nội dung của từng tài liệu |
| **Source of truth for** | Danh mục tài liệu · trạng thái từng tài liệu · tài liệu chưa viết và phase sở hữu |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M4.11 |
| **Last updated** | 2026-08-02 |

Format và thứ tự đọc: [`document-conventions.md`](document-conventions.md).

## What exists

| Document | Purpose | Status |
|---|---|---|
| [`document-conventions.md`](document-conventions.md) | Hợp đồng tài liệu: thứ tự đọc, header bắt buộc, template AD/BR/UC/WBS, MUST/SHOULD/MAY | **frozen for MVP** |
| [`checklist.md`](checklist.md) | The canonical 22-phase development plan | **frozen for MVP** |
| [`wbs.md`](wbs.md) | Live progress ledger — the source of truth for what is done | active |
| [`product.md`](product.md) | Problem, users, platform/data/auth decisions, **and MVP scope** | **frozen for MVP** |
| [`architecture.md`](architecture.md) | Architecture decisions AD-01…11 with reasoning | active |
| [`use-cases.md`](use-cases.md) | UC-01…09 cho must-have MVP | **frozen for MVP** |
| [`business-rules.md`](business-rules.md) | BR-01…87: cây deck, hai scheduler, review_kind, session lifecycle, reset/generation, starter template | **frozen for MVP** |
| [`data-model.md`](data-model.md) | Schema + 15 câu query bất biến: decks (cây nhiều cấp), cards, card_review_states, review_history, study_sessions, templates | **frozen for MVP** |

"Frozen for MVP" nghĩa là đặc tả đã chốt và code được viết theo nó. Đổi một tài
liệu frozen là một quyết định có chủ đích, phải kèm cập nhật mọi tài liệu tham
chiếu tới nó trong cùng commit — không phải một chỉnh sửa tiện tay.

### Tài liệu theo task

Hai thư mục con giữ tài liệu gắn với **một** task chứ không phải với sản phẩm.
Chúng nằm ngoài bảng trên vì vòng đời khác: một report đóng lại khi task đóng,
còn `use-cases.md` thì không.

| Thư mục | Chứa gì | Vòng đời |
|---|---|---|
| [`wireframes/`](wireframes/) | Bố cục và hành vi UI chốt **trước** khi viết code một task | `draft` → `active` khi code land |
| [`reviews/`](reviews/) | Report và checklist của một vòng review đã chạy | Đóng băng sau khi task đóng |

Cả hai MUST tham chiếu BR/AD/UC bằng ID và MUST NOT phát biểu lại luật — cùng
quy tắc canonical location ở `document-conventions.md` §5. `check_docs.py` chỉ
quét `docs/*.md` cấp một, nên header bảy dòng ở đây là kỷ luật tự giác, không
phải thứ được cưỡng chế.

**ID là vĩnh viễn.** BR, AD và UC không bao giờ được đánh số lại; rule mới append
vào số tiếp theo. Lần renumber trước đã làm hỏng tham chiếu ngầm mà không có gì
báo lỗi — xem mục "Chính sách đánh số" trong `business-rules.md`.

MVP scope lives inside `product.md` rather than a separate `mvp.md` — it is
short, and splitting it would mean two files that must agree about the same
feature list.

## Not written yet

These are deliberately absent rather than forgotten. Each is created by the
phase that owns it — an empty placeholder would read as "considered, nothing
needed", which is worse than an obvious gap.

| Document | Created during | Owning skill |
|---|---|---|
| `api-spec.md` | Phase 10.2 — **not until the Spring Boot backend exists** (AD-05) | `flutter-data-layer` |
| `design-system.md` | Phase 7 | `flutter-design-system` |
| `testing-strategy.md` | Phase 15 | `flutter-testing` |
| `release-checklist.md` | Phase 20–21 | `flutter-ship` |

Templates for the Phase 0–1 documents are in
`.claude/skills/flutter-product-spec/assets/`.

## The rule that keeps this useful

Documentation and source code are updated in the same commit. A document that
lags the code is actively harmful — the next session reads it, believes it, and
builds on something that is no longer true. If a change makes a document wrong,
either fix the document or note the discrepancy in `wbs.md` before merging.
