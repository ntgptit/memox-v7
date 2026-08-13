# Implement Card Detail and History v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc thêm màn xem đầy đủ card và lịch sử học không làm mất ngữ cảnh danh sách |
| **Scope** | Read-only detail, tags/current state và raw answer history phân trang; Edit là action riêng |
| **Source of truth for** | Hướng dẫn thực thi Card Detail and History v1; nghiệp vụ chính thức thuộc BR/UC/AD/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, Card/Study history contracts, route/navigation docs và `docs/wbs.md` |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Card Detail and History v1** trong worktree riêng. Tap card row mở
detail read-only; chỉnh sửa chỉ qua explicit Edit action.

## Pre-flight và 5Why

Đọc repo/docs, Card list/editor/selection behavior, Study answer/state schema,
reset/generation rules, router, localization, Card README/feature blueprint.
Kiểm branch/status/base. Viết 5Why về one-line list summary, detail-vs-edit,
raw-history value, keyset pagination và generation grouping. Không commit/push/
PR/merge trước paired review.

## Docs và nghiệp vụ

Append BR/UC/WBS IDs, create Card Detail wireframe và update navigation flow.
Canonicalize:

1. Tap active card row mở read-only detail. Selection mode giữ tap-to-select và
   không điều hướng. Edit icon/menu là action riêng tới editor hiện có.
2. Detail hiển thị full Front (từ tiếng Hàn), full Back (nghĩa), optional example,
   hint, pronunciation, tags, flag và current scheduler study state.
3. History dùng `study_answers`, newest first by `answered_at DESC, id DESC`,
   keyset page 50; không offset pagination hoặc load toàn bộ.
4. Mỗi event hiển thị time, mode, stored kind, stored action, outcome/hint khi
   applicable và before→after schedule fields đúng scheduler. Không infer kind
   hoặc action từ state delta.
5. Rows được group visually theo `scheduler_generation`; reset không xóa history
   và generation cũ vẫn xem được. Không tính accuracy/score.
6. Empty history là hợp lệ cho new card. Current state và old history có lifecycle
   riêng; content edit không thay state/history.
7. Card missing/deleted giữa read trả typed not-found. Nếu Trash feature cùng tồn
   tại sau integration, active route không tự lộ trashed card; Trash có thể dùng
   cùng read model qua explicit capability, không duplicate screen.
8. Mở/detail/paginate không mutation DB hoặc đánh dấu card learned.

## Architecture và UI

- Domain detail/history/page cursor models, repository contract và watch/load
  use cases. Cursor typed `(answeredAt,id)`, không expose Drift row.
- Data named queries join content/tags/state và history bounded; first page/live
  detail stream tách command load-more có dedupe/ordering stable, no N+1.
- Presentation controller giữ initial/load-more/retry/end state và ignores stale
  requests; không BuildContext/repository in controller.
- Add route constants for card detail nested dưới card list; update navigation
  docs/tests. Preserve list filters/scroll/selection when Back.
- UI header full content + metadata/state section + History timeline. Edit visible
  but not dominant over reading. Long content wraps/scrolls; no arbitrary truncate.
- States loading, loaded-new/no-history, loaded-many pages, loading-more,
  page-error retry, top-level error/not-found. EN/VI, themes, compact/large text.

Wireframe pin gutters, content/state/history shared edges, label/value baselines,
generation header stickiness only if justified, row rhythm, load-more placement
and bottom safe area. Use locale-aware date/time and semantics.

## Tests và clean stop

Real SQLite tests full content/tags/state, exact newest ordering/ties, page 50,
no duplicates/gaps across insert between pages, generation groups, reset retention,
delete/not-found and read-only/no N+1. Domain/controller tests cursor, stale page,
retry/end, mapping both schedulers. Widget/router tests row vs selection tap,
Edit/Back preservation, all states, long content, locale date, semantics and
geometry/goldens.

Run targeted host checks; emulator deferred to integration. Stop when production
row opens detail, history is bounded/raw/stored, docs/code/tests agree, no
P0/P1/P2/TODO and handoff records route/ARB/schema conflicts.
