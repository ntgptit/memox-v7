# Implement Study Home v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc thay Study branch fixture bằng Study Home production dựa trên workload thật |
| **Scope** | Resume session, root-deck study entry list và empty-library CTA; không tự mở session hoặc tạo dashboard analytics |
| **Source of truth for** | Hướng dẫn thực thi Study Home v1; nghiệp vụ chính thức thuộc BR/UC/AD/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, Study contracts, Deck/Card read models, route contracts và `docs/wbs.md` |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Study Home v1** trong worktree riêng, loại bỏ production dependency
vào fixture `kStudyBranchDeckId`. Đây là screen read-only cho đến khi người dùng
tap Resume/Study, không phải nơi tự tạo session.

## Pre-flight và 5Why

Đọc repo contract, document conventions, product/AD/BR/data model/UC/WBS, Study
README/code, session lifecycle, effective study options, Deck/Card README,
router/shell và feature blueprint. Kiểm branch/status/base, bảo toàn diff khác.
Viết 5Why về fixture risk, resume priority, workload ordering, explicit user
action và empty-library onboarding. Không commit/push/PR/merge trước paired review.

## Docs và nghiệp vụ

Append BR/UC/WBS bằng ID tiếp theo, tạo Study Home wireframe/state matrix và cập
nhật navigation docs khi production branch behavior đổi. Canonicalize:

1. Nếu có một session hợp lệ `in_progress`, Resume card đứng đầu và mở đúng
   session/turn persisted. Không tạo session thứ hai.
2. Stale generation, missing/deleted deck/card hoặc invalid session không được
   quảng cáo Resume; lifecycle hiện hữu xử lý typed invalidation trước khi list
   được trình bày.
3. Sau Resume, hiển thị root decks có thể học. Workload tổng hợp toàn subtree,
   không dùng parent shortcut sai.
4. Order giảm dần theo overdue count, due-today count, new count; tie-break tên
   folded rồi ID. Deck không workload đứng cuối, vẫn có thể mở nếu còn cards.
5. Overdue, due today và new loại trừ theo production eligibility; dùng cùng
   local-day/clock seam của Study, không định nghĩa lại scheduler trong UI.
6. Tap Study mới gọi flow mở/resume session; chỉ render/scroll/change tab không
   ghi DB, khóa scheduler hoặc materialize queue.
7. Empty library hiển thị CTA tới Starter Library. Library có deck nhưng không
   card/workload dùng zero state có đường về Library, không giả due.
8. Sau session complete/abandon/invalidate, Home stream refresh mượt, không
   reload toàn route hoặc giữ count cũ.

## Architecture và UI

- Tạo read model/repository/use case tối thiểu hoặc mở rộng Study contract đúng
  boundary; không để Study presentation import Deck/Card data internals.
- Aggregate root workload bằng named SQL/repository, bounded query, không N+1.
- Controller chỉ orchestration/navigation intent; business ordering/eligibility
  nằm domain/data theo canonical owner.
- Giữ `/study`, RouteNames và shell index. Remove fixture constant/call sites và
  tests dựa vào fixture; không thay bằng fixture mới.
- UI hierarchy: title/supporting copy; Resume card khi có; `Study next` root-deck
  list với deck name, scheduler label khi hữu ích, Overdue/Due/New summary và
  single Study action; loading/empty/error/refresh states.
- Use Mx components/tokens/l10n. Workload colors có semantic role nhất quán,
  copy không shame và không dùng màu làm tín hiệu duy nhất.

Wireframe pin content gutter, Resume/list shared edges, row/action baselines,
badge spacing, long-name wrapping, bottom-nav clearance. Kiểm EN/VI, light/dark,
320dp@2.0, 390/412dp và keyboard/TalkBack focus order.

## Tests và clean stop

Domain/data tests: resume validity, root aggregation/nesting, exact workload
partition/order/ties, zero decks, live answer/session/deck changes, read-only and
no N+1 on real SQLite. Controller/widget tests: all states, Resume vs Study,
double tap guard, Starter CTA, error/retry, branch preservation and no session
write before tap. Visual/semantics tests cover locales/themes/viewports and
`getRect` geometry on production tree.

Run targeted host checks. Emulator IT is `deferred to integration worktree —
not run`. Stop when fixture is absent from production, docs/code/tests agree,
all actions have real routes, no P0/P1/P2/TODO and implementation handoff records
shared router/DI/ARB conflicts.
