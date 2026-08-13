# Implement Progress Overview v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc đặc tả và triển khai Progress Overview từ lịch sử học thật của MemoX |
| **Scope** | Today, current streak và hoạt động bảy ngày; thay Progress placeholder bằng vertical slice read-only |
| **Source of truth for** | Hướng dẫn thực thi Progress Overview v1; nghiệp vụ chính thức vẫn thuộc BR, UC, AD và wireframe được task cập nhật |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, `docs/product.md`, `docs/architecture.md`, `docs/business-rules.md`, `docs/data-model.md`, `docs/use-cases.md`, `docs/wbs.md` |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Bạn đang làm việc trong một feature worktree của `memox-v7`. Hãy đặc tả rồi
triển khai **Progress Overview v1** hoàn chỉnh. Prompt này là execution aid,
không phải nguồn nghiệp vụ mới.

## Chế độ phối hợp

- Đọc đầy đủ `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, các mục
  Progress/Study trong product, AD-01/12/13/16/19, BR về history/reset/delete,
  data model của `study_answers`, UC Study hiện có, WBS, Deck/Card README và
  feature blueprint.
- Kiểm tra branch, `git status`, `origin/main` và diff trước khi sửa. Không
  reset, checkout hoặc ghi đè thay đổi của worktree khác.
- Worktree này cùng base với chín feature PR khác. Mọi sửa router, DI, ARB,
  schema version và canonical docs phải tối thiểu, dễ rebase và ghi rõ trong PR.
- Implementation hoàn tất code, docs và targeted host tests rồi dừng để hai
  recursive review chạy. Không commit, push, tạo PR hoặc merge ở phase này.

## 5Why bắt buộc

Mở work log bằng 5Why thực chất: vì Progress phải dùng history thật; vì đơn vị
đếm phải chốt trước UI; vì không nên tạo persistent aggregate; vì local-day phải
dùng clock/offset injected; và vì accuracy/XP/goal bị loại khỏi v1. Mỗi Why phải
nêu constraint, trade-off và quyết định nó mở khóa.

## Docs-first và nghiệp vụ

Trước code, append BR/UC/WBS bằng ID kế tiếp sau khi kiểm tra repo; tạo wireframe
Progress v1 và cập nhật AD-19 để production screen thay placeholder. Chỉ sửa
frozen docs khi WBS liệt kê chúng trong `Editable documents`. Không sao chép
rule giữa tài liệu.

Canonicalize đúng các quyết định sau:

1. Activity unit là một cặp distinct `(localDay, cardId)`. Nhiều answer,
   stage, round hoặc session của cùng card trong ngày vẫn tính một.
2. Browse không ghi answer nên không tăng activity hoặc streak.
3. Today dùng `[startOfToday, startOfTomorrow)` theo một snapshot của
   `clockProvider` và `utcOffsetProvider`.
4. Breakdown loại trừ nhau: một card-day là Learning nếu có ít nhất một answer
   `learning`; nếu không mới là Reviewing khi có `scheduled` hoặc `relearning`.
   `learning + reviewing = total` luôn đúng.
5. Last 7 days gồm hôm nay và sáu ngày trước, zero-fill, thứ tự cũ tới mới.
6. Nếu hôm nay active, streak kết thúc hôm nay; nếu hôm nay chưa active nhưng
   hôm qua active, giữ chuỗi kết thúc hôm qua; nếu cả hai không active, streak 0.
7. Reset giữ history nên giữ activity. Card đã ở Trash hoặc bị hard-delete
   không xuất hiện trong Progress; v1 không tạo tombstone/analytics shadow.
8. Màn hình live-update khi answer thay đổi và tại local midnight. Timer phải
   one-shot, dispose-safe, xử lý stale boundary không loop và refresh khi offset
   đổi.
9. Progress là read-only: mở, đóng, retry hoặc đổi tab không mutation DB/session.
10. Không accuracy, correct rate, longest streak, goal, XP, heatmap, deck filter,
    share hoặc celebration trong v1.

Nếu canonical docs hiện tại mâu thuẫn các quyết định đã được chủ dự án chốt ở
prompt này, dừng và báo coordinator trước khi code; không lén chọn code/test.

## Kiến trúc và triển khai

- Domain: immutable day/snapshot models, `ProgressRepository` và
  `WatchProgressUseCase`; không Flutter/Drift/wall-clock read.
- Data: named SQL trong `.drift`, feature-local DAO/mapper/repository. Aggregate
  ở SQLite thành card-day/active-day rows; không tải raw answers về UI, không
  query từng ngày, không N+1.
- Reuse `LocalDayModel`; use case/controller truyền explicit now+offset. Một
  emission là một snapshot nhất quán.
- Không thêm bảng aggregate. Chỉ thêm index sau `EXPLAIN QUERY PLAN` và benchmark
  DB thật tối thiểu 100.000 answers chứng minh lợi ích vật chất. Named query
  không tự động đồng nghĩa schema migration.
- DI dùng feature contract provider và composition-root binding hiện có.
- Presentation có immutable state/controller, `ProgressScreen` và widgets đúng
  bốn bucket. Widgets chỉ render; không business calculation.
- Router giữ nguyên `/progress`, route name và shell branch index; chỉ thay
  placeholder builder. Copy EN/VI qua ARB; Widgetbook/visual-audit theo contract
  hiện tại, không sửa generated files.

## UI/UX và state matrix

Loaded screen gồm ba section cùng content gutter/shared edges:

1. Hero Current streak, headline là số ngày và supporting copy là card hôm nay;
   streak 0 dùng lời mời trung tính.
2. Today: total cùng Learning/Reviewing, nói rõ unit là card.
3. Last 7 days: mỗi ngày có label, value và semantics; zero vẫn đọc được, màu
   không là tín hiệu duy nhất.

Bắt buộc render loading, normal, today-zero-but-streak-retained, lifetime empty
với CTA thật tới Study branch, error+Retry, live refresh và midnight rollover.
Wireframe phải chốt gutter, shared edges, section width, padding, vertical
rhythm, chart baseline/bar gap, safe area và bottom-nav clearance. Kiểm EN/VI,
light/dark, 320dp @ text scale 2.0, 390dp và 412dp; không clip hoặc giảm font để
né overflow.

## Tests và verification

- Domain: distinct card-day, exclusive partition, streak branches, gaps,
  month/year, UTC offsets và zero-fill.
- Real SQLite: mixed kinds, duplicate answers, stream emission, reset retention,
  Trash exclusion, cascade/hard-delete, no mutation và query-count/plan.
- Controller: loading/loaded/empty/error/retry, midnight future/equal/past,
  offset change, dispose/no-loop và live update không full-page flicker.
- Widget/router/visual: mọi state, CTA bằng tap thật, deep link, branch
  preservation, semantics, locales/themes/viewports và `tester.getRect` geometry.
- Golden chỉ là regression baseline; phải inspect state-by-state với wireframe.

Chạy targeted host tests trong inner loop và cuối phase chạy targeted guard phù
hợp. Không chạy emulator/device IT trong feature worktree; báo chính xác
`emulator IT: deferred to integration worktree — not run`, không ghi `pass`.
Không sửa test để hợp thức hóa bug. Clean stop khi docs/code/tests thống nhất,
không còn P0/P1/P2 hay TODO/dead API, targeted host checks xanh và implementation
handoff liệt kê files, migrations/shared conflicts và bằng chứng UI đã render.
