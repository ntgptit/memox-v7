# Implement Global Library Search v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc triển khai tìm kiếm toàn Library qua deck, card và tag với ranking/pagination ổn định |
| **Scope** | Active deck names, card Front/Back và tag names; không gồm fuzzy/semantic search, Trash hoặc optional detail fields |
| **Source of truth for** | Hướng dẫn thực thi Global Library Search v1; nghiệp vụ chính thức thuộc BR/UC/AD/data model/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, Deck/Card/tag normalization, Library navigation và Card Detail route contract |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Global Library Search v1** trong worktree riêng. Search bao phủ
Library active content và phải production-ready trên base hiện tại mà không tạo
duplicate Card Detail implementation.

## Pre-flight và 5Why

Đọc repo/docs, Deck/Card list queries, string folding/search behavior, tags,
pagination, Library screen/router, Card Detail feature contract nếu đã có, query
indexes and benchmark conventions. Kiểm branch/status/base. Viết 5Why về global
discovery, exact scope fields, deterministic ranking, debounce/stale suppression
và benchmark-before-FTS. Không commit/push/PR/merge trước reviews.

## Docs và nghiệp vụ

Append BR/UC/WBS, update data model only when measured index changes, create
Global Search wireframe/navigation flow. Canonicalize:

1. Search active deck names, card Front, card Back và tag names. Không search
   example/hint/pronunciation, scheduler/history hoặc deleted Trash content.
2. Query trim+fold bằng shared production normalization. Empty normalized query
   trả initial/no-suggestions state và **không gọi DB**.
3. Debounce 250ms ở provider/controller seam, không trong TextField. Mỗi request
   có identity; late result/error từ query cũ bị bỏ.
4. Results group **Decks trước, Cards sau**. Trong mỗi group rank exact match,
   prefix match, then contains; tie-break normalized display name/content,
   created_at và ID theo canonical rule để pagination stable.
5. Deck result hiển thị path và mở đúng Deck Detail. Card result hiển thị Front,
   one-line Back summary và deck path, mở Card Detail read-only.
6. Nếu Card Detail route chưa có trên common base, define/reuse a typed navigation
   destination seam and record PR dependency; không tạo duplicate detail screen
   hoặc silently route to Edit. PR may stay blocked on integration wiring but
   search domain/data/UI must compile/test independently through injected action.
7. Multi-match card/tag vẫn cho một Card result; pagination keyset, page size
   phù hợp existing list convention, không duplicate/gap.
8. Trash exclusion, card/deck move/rename/tag rename live-update results and paths.
   Search read-only and does not start Study.
9. Do not add FTS/index until `EXPLAIN QUERY PLAN` + benchmark realistic data
   proves need. Preserve Unicode folded semantics; SQLite `lower()` is forbidden
   as replacement.

## Architecture và UI

- Domain query/result/page/cursor models, repository contract/watch/search use
  case. Group/type exhaustive; no Drift/router types.
- Data named SQL with deterministic rank/keyset and dedupe; bounded page, no N+1
  for paths/tags. Benchmark at realistic decks/cards/tags before schema change.
- Controller owns debounce/request identity/page/retry state using injected
  timer/clock seam; dispose cancels; UI only forwards query/actions.
- Library header search affordance expands to production search surface. Keep
  input/focus/back behavior clear and preserve branch state.
- UI sections Decks then Cards with group counts when useful, highlighted match
  MAY be used only via safe text spans and tokens, never mutate content. States
  initial, debouncing/loading, mixed, decks-only/cards-only, no results, page
  loading/error and top error.
- L10n EN/VI, Mx/tokens and Card Detail/Deck route constants or injected typed
  navigation seam as above.

Wireframe pin screen gutter, search field/group/list shared edges, row widths,
path/summary baselines, group gaps, pagination state and keyboard/bottom-nav
clearance. Validate long Korean/Vietnamese, themes, 320@2x/390/412 and TalkBack.

## Tests và clean stop

Domain tests normalization/ranking/ties/grouping/cursors. Real SQLite tests all
fields and exclusions, tag dedupe, exact/prefix/contains, Unicode case, stable
pagination, move/rename/delete/restore live paths, empty query zero DB calls,
query count/plan and benchmarks if index changes. Controller tests 249/250ms,
rapid queries, stale data/error, dispose, retry/load-more. Widget/router tests
focus/back, groups/states, result navigation contract, selection unaffected,
locales/themes/viewports/semantics and geometry.

Run targeted host checks; emulator deferred. Stop when empty query is zero-I/O,
ranking/paging deterministic, no deleted content leaks, Card Detail dependency
is explicit rather than duplicated, docs/code/tests agree, no P0/P1/P2/TODO and
handoff lists router/query/ARB conflicts.
