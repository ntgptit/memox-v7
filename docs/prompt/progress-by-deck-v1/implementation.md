# Implement Progress by Deck v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc triển khai drill-down tiến độ theo deck trên dữ liệu học thật |
| **Scope** | Activity summary cho root/deck trong 7 và 30 ngày; không gồm accuracy, goals hoặc historical-location snapshots |
| **Source of truth for** | Hướng dẫn thực thi Progress by Deck v1; nghiệp vụ chính thức thuộc BR/UC/AD/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, canonical Progress docs, deck/card/study data model, `docs/prompt/progress-v1/implementation.md` |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Trong feature worktree riêng, đặc tả và triển khai **Progress by Deck v1** thành
vertical slice production. Không giả dữ liệu và không gộp feature này vào
Progress Overview PR.

## Pre-flight và 5Why

Đọc `CLAUDE.md`, `AGENTS.md`, document conventions, product/AD/BR/data-model/UC/
WBS hiện tại, Progress Overview contract, Deck/Card README, feature blueprint và
production move-card/move-deck queries. Kiểm tra branch/status/base; không reset
hoặc ghi đè worktree khác. Viết 5Why giải thích nhu cầu drill-down, vì sao
attribution phải chốt, vì sao current-location được chọn thay historical
snapshot, vì sao chỉ activity metrics và vì sao aggregate phải ở DB.

Implementation phase không commit/push/PR/merge; dừng sau docs, code và targeted
host tests để paired reviews chạy.

## Docs và nghiệp vụ phải khóa

Append BR/UC/WBS bằng ID hiện tại tiếp theo và tạo wireframe riêng. Nếu Progress
Overview chưa tồn tại trên base, không sao chép implementation của nó; tạo seam
feature-local tối thiểu và ghi dependency để integration rebase. Canonicalize:

1. Một card-day dùng cùng distinct/local-day definition của Progress Overview.
2. History được gán cho **vị trí hiện tại của card**. Move card/subtree làm toàn
   lịch sử của card xuất hiện dưới root/deck mới; không lưu deck snapshot trên
   answer cũ.
3. Root summary gồm toàn subtree; deck summary gồm card trực tiếp và descendants
   theo hierarchy thật. Không dùng `COALESCE(parent_deck_id,id)`.
4. Trash và mọi descendant của deleted deck bị loại. Restore làm activity xuất
   hiện lại theo target hiện tại; hard purge loại vĩnh viễn do cascade.
5. Metrics v1: unique active cards, active days, Learning, Reviewing cho 7 ngày
   và 30 ngày. Không accuracy, score, longest streak, due forecast hoặc compare.
6. Learning/Reviewing là exclusive partition với Learning priority như Overview.
7. Sort deck list theo activity card count giảm dần, rồi tên folded và ID để ổn
   định; zero-activity decks vẫn có thể xem và đứng cuối.
8. Read-only, live-update sau answer/move/delete/restore và local-day rollover.

## Architecture và UI

- Domain có filter/range/read models, repository contract và watch use case.
- Data dùng recursive tree/current card location + aggregated SQL; một snapshot,
  bounded output, không N+1 hoặc raw-answer grouping. Tái sử dụng local-day seam.
- Không thêm historical deck ID vào `study_answers`, không bảng analytics.
- Presentation nằm trong Progress feature hoặc feature slice riêng theo pattern
  hiện hữu; không import data/presentation internals của Deck/Card.
- Route/deep-link chỉ thêm khi canonical navigation contract yêu cầu; dùng
  RouteNames/RoutePaths và cập nhật navigation docs cùng commit.
- UI gồm summary range selector 7/30, deck rows có name/path, active cards/days
  và Learning/Reviewing; tap mở detail cùng hierarchy context. Dùng Mx/tokens.
- States: loading, mixed results, all-zero, no decks, error/retry, moved-card
  live refresh, long paths/counts, EN/VI, light/dark, compact/large text.

Chốt wireframe geometry: content gutter; selector/summary/list shared edges;
row padding; metric column baselines; tap targets; path wrapping; bottom-nav
clearance. Không dùng màu làm tín hiệu duy nhất.

## Tests và clean stop

Domain test ranges/partition/sort. Real SQLite test nested 10 levels, current-
location reattribution after card/subtree move, Trash/restore/purge, duplicate
answers, reset, live invalidation, no mutation, bounded query count và no N+1.
Controller/widget/router test mọi state, range switching, retry, navigation,
semantics, locales/themes/viewports. Pin geometry bằng `getRect`; inspect goldens
theo wireframe.

Chạy targeted host tests; không emulator IT, báo `deferred to integration
worktree — not run`. Handoff phải nêu shared conflicts/schema work. Dừng khi
docs/code/tests đồng nhất, query semantics được chứng minh trên SQLite thật,
không còn P0/P1/P2/TODO và targeted checks xanh.
