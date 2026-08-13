# Implement Tag Management v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc triển khai catalog, filter, rename/merge và delete tags trên dữ liệu Card thật |
| **Scope** | Library-level tag catalog và multi-tag filtering; không gồm hierarchy, colors hoặc cloud taxonomy |
| **Source of truth for** | Hướng dẫn thực thi Tag Management v1; nghiệp vụ chính thức thuộc BR/UC/AD/data model/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, Card tag/search/filter contracts, `tags`/`card_tags` data model và `docs/wbs.md` |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Tag Management v1** trong worktree riêng, reuse tag normalization
và limit hiện có. Không biến tag thành nested folder hoặc second deck system.

## Pre-flight và 5Why

Đọc repo/docs, Card README/list/filter/selection/editor, `tags`/`card_tags`, string
folding, bulk actions, import/export tag codec và feature blueprint. Kiểm
branch/status/base. Viết 5Why về catalog, multi-tag semantics, atomic merge,
unlink-not-delete-card và why flat tags. Không commit/push/PR/merge trước reviews.

## Docs và nghiệp vụ

Append BR/UC/WBS, update data model only if query/index changes, create tag
management/filter wireframe. Canonicalize:

1. Tag catalog là Library-level, hiển thị canonical name và active-card count.
   Sort name folded rồi ID; search dùng cùng normalization hiện tại.
2. Chọn nhiều tag trong Card List dùng **OR** giữa tags. Tag predicate được AND
   với current All/Due/New/Flagged filter và search query.
3. Không tag selected nghĩa là không áp tag predicate. Count/result phải ổn định
   và pagination không duplicate bởi many-to-many join.
4. Rename trim/fold theo production rule. Nếu folded name chưa tồn tại, rename
   giữ ID và links. Nếu collision, atomically merge source vào target, insert
   missing links/dedupe rồi xóa source tag.
5. Rename/merge vẫn tôn trọng tối đa 10 unique tags/card; dedupe không làm card
   vượt limit. Không đổi card content/study state/history/timestamps ngoài những
   metadata thật sự thuộc tag contract.
6. Delete tag chỉ unlink mọi `card_tags` rồi xóa tag; không xóa card. Strong
   confirmation nói rõ số card bị gỡ tag và không nói mất card.
7. Catalog operations áp dụng mọi persisted links theo schema hiện tại. Khi
   tích hợp Trash, hidden items không xuất hiện trong active counts/filter nhưng
   rename/merge giữ links để restore không mất metadata; purge cascade cleanup.
8. Import/export vẫn round-trip tag spelling/canonical links; không duplicate
   codec/normalizer trong feature.

## Architecture và UI

- Domain catalog/read models, filter model, repository contract và focused
  watch/search/rename/delete use cases with typed failures.
- Data named queries use EXISTS/distinct rather than multiplicative joins;
  rename/merge/delete transactions on real SQLite, watch invalidation complete.
- Extend Card List filter state without putting SQL/tag IDs in widgets. Preserve
  filter/search/page consistency and reset cursor on predicate change.
- Add Library/Card List entry point using visible affordance, not long-press only.
  Catalog screen/sheet supports search, counts, rename, delete. Filter overlay
  supports multi-select, Clear and Apply/current-result feedback.
- States loading, populated, no tags, search empty, rename normal/collision,
  submitting/failure, delete confirm/failure, active multi-filter.
- L10n EN/VI, Mx/tokens; tags are text identifiers, not arbitrary user colors.

Wireframe pin gutters, catalog/filter shared edges, row name/count/action
baselines, chip wrap/gaps, bottom actions and safe area. Validate 320@2x/390/412,
light/dark and keyboard/TalkBack.

## Tests và clean stop

Domain tests OR/AND composition, normalization, validation and merge outcomes.
Real SQLite tests counts, many-tag pagination, rename, collision merge/dedupe,
10-tag invariant, delete unlink-only, import-created tags, Trash compatibility,
rollback/live streams/no study mutation. Controller/widget tests filter/reset
cursor, search, all states/actions/errors, selection coexistence, locales/themes/
viewports/semantics and geometry.

Run targeted host checks; emulator deferred. Stop when filter semantics and
atomic operations are proved, no cards/history lost, docs/code/tests agree, no
P0/P1/P2/TODO and handoff lists Card List/ARB/schema conflicts.
