# Implement Trash and Restore v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc thay destructive delete bằng soft-delete, restore có target và purge an toàn |
| **Scope** | Card/deck Trash, 30-day retention, undo, restore, multi-select và permanent purge; không gồm cloud backup |
| **Source of truth for** | Hướng dẫn thực thi Trash and Restore v1; nghiệp vụ chính thức thuộc BR/UC/AD/data model/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, Deck/Card lifecycle, content_type, hierarchy, Study session/history và privacy contracts |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Trash and Restore v1** trong worktree riêng. Soft-delete phải giữ
content, study state và history đến purge; đây không phải backup/restore database.

## Pre-flight và 5Why

Đọc repo/docs, all Deck/Card create/move/delete transactions, content_type
BR-163, hierarchy/root/scheduler generation, sessions/queues/answers, filters,
imports, Progress/Search contracts và migration testing. Kiểm branch/status/base.
Viết 5Why về accidental loss, soft-delete lifecycle, explicit restore target,
retention/purge và subtree consistency. Không commit/push/PR/merge trước reviews.

## Docs và nghiệp vụ

Append BR/UC/WBS, add architecture/data-model decision and invariants, migration
snapshot/tests, Trash wireframes/navigation. Canonicalize:

1. Delete Card/Deck mặc định là one-transaction soft-delete, không cascade hard
   delete. UI báo moved to Trash và cung cấp Undo snackbar cho single-item delete.
2. Soft-deleted card/deck/subtree bị ẩn khỏi active Library, Card List, search,
   study eligibility/queue, progress, counts, tags active counts và export.
3. Deck deletion là một batch: mark active descendant decks/cards cùng timestamp
   và batch identity. Descendant đã ở Trash từ batch trước giữ tombstone cũ;
   restore parent không hồi sinh item đã bị xóa trước đó.
4. Study state/history/tags/content được giữ. In-progress sessions chạm item vừa
   xóa bị invalidated atomically bằng stored typed end reason `content_deleted`;
   không để queue phục vụ hidden card.
5. Khi soft-delete/move-to-Trash lấy direct active child cuối khỏi parent,
   non-root parent tự động `content_type = unset` trong cùng transaction. Root
   vẫn `deck`. Không có manual reset.
6. Restore **luôn hỏi target**. Card target phải là compatible card/unset non-root
   deck; deck subtree target phải thỏa max depth, content type và scheduler root/
   generation rules. Unset target được set tự động trong restore transaction.
7. Restore batch chỉ hồi sinh rows thuộc batch đó; giữ IDs/state/history/tags.
   Original location không tự được chọn; UI có thể preselect một valid target
   nhưng user phải confirm.
8. Retention 30×24 giờ từ `deleted_at`. Auto-purge idempotent khi startup, resume
   và mở Trash. Clock injected; boundary exactly 30 days có test.
9. Purge hard-deletes eligible batch và cascades state/history/tags/queues. Không
   purge descendant còn phụ thuộc batch chưa eligible hoặc làm batch restore
   dang dở; transaction rollback toàn bộ khi lỗi.
10. Multi-select tách theo item type cho Restore/Purge; không mix card+deck trong
    một target operation. Permanent purge dùng strong confirmation nêu count và
    lịch sử không thể khôi phục.

Chọn tombstone/batch schema tối thiểu nhưng phải biểu diễn được item root, batch,
`deleted_at` và pre-existing deleted descendants; ghi canonical model/invariants
trước migration. Không suy ra batch chỉ từ current parent nếu không chứng minh.

## Architecture và UI

- Domain lifecycle models, target eligibility, repository/use cases và typed
  failures. Do not leak Drift rows.
- Data transactions own soft-delete/content-type reset/session invalidation,
  restore validation/content-type set and purge. Mọi active query phải có một
  auditable exclusion strategy; không vá từng screen ad hoc.
- Migration old rows active by default; schema snapshots/invariants/query tests.
- Trash route thuộc Library/Settings theo canonical navigation decision, dùng
  route constants. Entry visible. List groups Cards/Decks or filter by type,
  shows deleted time, original path as information only, retention and selection.
- Restore target picker reuse production deck eligibility; no fake enabled rows.
- States loading, empty, mixed, selection card/deck, restoring, purging,
  validation conflict, expired/live purge, error/retry and Undo.
- L10n/Mx/tokens; destructive visual role reserved for permanent purge.

Wireframes pin gutters, tab/filter/list shared edges, selection bar, row metadata,
target picker, dialogs/snackbar and safe areas across locales/themes/viewports.

## Tests và clean stop

Real SQLite decision-table tests: single card/deck/subtree soft delete, predeleted
descendant batches, active-query exclusion, session invalidation, BR-163 reset,
undo, valid/invalid restores, scheduler/depth/content type, batch isolation,
30-day boundaries, idempotent triggers, safe purge/cascade/rollback and migration.
Controller/widget/router tests all states, multi-select type rule, confirmations,
target picker, Back/refresh, semantics/geometry. Cross-feature tests prove
Progress/Search/Study/Export do not leak Trash.

Run targeted host gate; emulator deferred. Stop when invariants return zero,
no active query leaks tombstones, restore/purge cannot lose unrelated batches,
docs/code/tests agree, no P0/P1/P2/TODO and handoff highlights major schema/
query/router conflicts for integration.
