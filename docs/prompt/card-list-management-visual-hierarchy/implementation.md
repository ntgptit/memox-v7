# Card List and management visual hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Nâng visual hierarchy và tính quét nhanh của Card List mà giữ nguyên toàn bộ CRUD/bulk/search/filter/navigation hiện có |
| **Scope** | `CardListScreen`, progress/toolbar/filter/selection states, card rows, empty states và management overlays liên quan |
| **Source of truth for** | Hướng dẫn triển khai restyle Card List; nghiệp vụ vẫn thuộc UC-04, BR liên quan và wireframe M4.11 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, `docs/wireframes/m4-11-card-management.md`, `docs/business-rules.md`, `docs/use-cases.md`, MemoX tokens/shared widgets |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Chỉ cải thiện bố cục, hierarchy, surface, màu semantic và interaction clarity. Không
đổi dữ liệu, filter semantics, pagination, selection, move/delete/tag/flag/export hoặc
độ dài nội dung canonical. Back trên row chỉ cần preview một dòng; nội dung đầy đủ thuộc
Card Detail. Mật độ danh sách hiện tại là quyết định có chủ đích vì search và import/export
là đường quản lý chính.

## 5Why

Trước implementation, đối chiếu ảnh/golden hiện tại và viết 5Why: hierarchy nào phẳng,
shared component/token nào giải được, behavior nào phải đóng băng, responsive risk nào
cần test và vì sao không mở rộng thành redesign CRUD.

## Layout contract

- Dùng production `CardListScreen`, `MxContentShell`, `MxCard`/shared primitives hiện có;
  không raw Material policy widget và không mint token.
- Progress/summary là entry to Study nhưng không lấn title/list. Search, filter, sort và
  overflow có thứ tự rõ; selection mode thay toolbar có chủ đích, không chồng action.
- Row ưu tiên Front, Back preview một dòng, rồi state/flag/tag/due metadata. Truncation có
  semantic label/full detail destination; không giảm font để nhét nội dung.
- Bulk actions phải phân cấp primary/secondary/destructive đúng; destructive vẫn có
  confirmation/undo theo behavior hiện tại.
- Empty deck, filtered empty và search-no-result phải khác nhau và đưa đúng next action.

## States và tests

Pin loaded short/long content, empty, filtered empty, searching, loading window, error,
single selection, select-all, menu open, flagged/due/new/learned và large-text states.
Thêm `getRect` assertions cho shared gutters, row edges, metadata baseline, toolbar và
bottom safe area tại 320@2.0, 393 và 412. Test semantics/tap target và giữ nguyên callback.

## Verification, delivery và clean stop

Làm việc trên worktree sạch từ `origin/main`; không chạm unrelated dirty files hoặc
frozen docs ngoài editable scope. Chạy changed gate trong loop, full consolidated gate
cuối. UI-only nên không cần emulator; ghi đúng trạng thái. Regenerate goldens `TZ=UTC`,
build/publish gallery URL cũ, commit/push và mở non-draft PR nhưng không merge.

Clean stop khi behavior parity có test, mọi state render sạch light/dark EN/VI,
geometry pass, không raw style/magic value, full gate xanh và gallery sẵn cho owner.
