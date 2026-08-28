# Upgrade Progress Overview — Card Detail Visual Language

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc nâng cấp ba section tổng quan Progress thành dashboard compact, hiện đại và dễ quét theo style Card Detail |
| **Scope** | Ba section overview ở `/progress`, tests hình học/a11y, golden và gallery; không đổi range selector hoặc danh sách by-deck ngoài shared-edge integration |
| **Source of truth for** | Hướng dẫn thực thi Progress Overview visual hierarchy; nghiệp vụ vẫn thuộc BR-190…BR-199, UC-12 và M99.23 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-190…BR-199, UC-12, `docs/wireframes/m99-23-progress-overview.md`, production Card Detail và MemoX design tokens |
| **Updated by task** | Progress Overview visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Restyle **Progress Overview** trên production `/progress`. Giữ nguyên card-day,
partition, streak, seven-day series, midnight refresh, range/by-deck composition,
repository và read-only contract. Không thêm metric, goal, accuracy hay chart mới.

Worktree safety: kiểm `git status`, branch và merge-base trước khi sửa; mọi input
ở worktree prompt là read-only, toàn bộ code/test nằm trong target worktree. Không
revert diff ngoài scope và không commit/push/PR/merge trong implementation phase.

## Pre-flight và 5Why

Đọc contract repo, BR-190…BR-199, UC-12, M99.23, M99 Progress by Deck, screen/
widgets/tests/goldens hiện tại và Card Detail. Lập reduced UI Contract; kiểm
branch/base/dirty state; không commit/push/PR trong implementation phase.

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Streak dùng display-size cực lớn nên chiếm phần lớn first viewport và lấn Today. | Thu hero về compact focal summary, vẫn giữ streak là số dẫn. |
| 2 | Today và chart dùng card ngang cấp nhưng thiếu liên kết visual với hero. | Dùng một surface ladder, section labels và compact metric grid nhất quán. |
| 3 | Daily activity có dữ liệu tốt nhưng bar/value khó scan ở mật độ hiện tại. | Giữ bar ngang, tăng alignment và tabular figures, không tăng decorative chrome. |
| 4 | Overview nằm trên Progress by Deck trong cùng scroll. | Shared edges và spacing phải nối được với pinned range selector bên dưới. |
| 5 | Một dashboard đẹp dễ dụ thêm metric không có BR. | Whitelist đúng streak, Today partition và 7-day activity; test cấm số giả. |

## Visual thesis

- Một centered reading column, `mxScreenGutter`, max `AppBreakpoints.medium`.
- Flat `MxCard` surfaces, subtle border, restrained/no shadow như Card Detail.
- Compact type: section label, `headlineMedium` hoặc nhỏ hơn cho streak; không
  dùng `displayLarge` nếu nó làm mất cân bằng first viewport.
- Semantic icon wells và tabular figures; màu chỉ nhấn, không thay nhãn.
- Không card cho từng metric/day. Mỗi section là một surface có một nhiệm vụ.

## UI Contract

```text
ProgressScreen / one CustomScrollView
├─ Overview header
│  ├─ compact streak hero MxCard
│  ├─ today summary MxCard
│  └─ seven-day activity MxCard
├─ pinned range selector (owned by by-deck composition)
├─ range summary
└─ deck activity rows
```

### Streak hero

- Giữ label, localized `N days` và supporting state cho active/held/zero.
- Dùng icon well/tone `streak` hoặc accent hiện có để tạo focal point; không
  gradient, celebration, flame giả hoặc saturated full-card fill.
- Headline vẫn mạnh nhất overview nhưng không được cao hơn cần thiết; text scale
  2.0 phải wrap mà không clip.

### Today

- Giữ total cards và hai dòng Learning/Reviewing, kể cả 0, cùng explanation.
- Có thể dùng responsive 2-column metric grid ở regular width và stack khi hẹp.
  Total là summary, Learning/Reviewing là breakdown; không làm ba số ngang cấp.
- Numeric values tabular; labels/body compact; màu learning/reviewing chỉ cue.

### Daily activity

- Giữ đúng bảy hàng cũ → mới và bar ngang. Không chuyển sang column chart.
- Day label, track và value có baseline ổn định; value tabular, luôn hiện 0.
- Bar giữ `progressFill` ngay cả fraction 1; không dùng success “completed”.
- Track/fill decorative và excluded semantics; mỗi row một spoken node.

### Integration với phần by-deck

- Overview vẫn thuộc cùng vùng cuộn và nằm trước pinned range selector.
- Ba overview cards, range band, range summary và deck rows dùng cùng content
  edges. Không thêm nested scroll hoặc sticky header thứ hai.
- Lifetime-empty/read-error/refresh giữ behavior/copy hiện hành.

## Files dự kiến

- `lib/features/progress/presentation/screens/progress_screen.dart`
- `presentation/widgets/sections/progress_streak_hero_widget.dart`
- `progress_today_widget.dart`, `progress_week_widget.dart`
- `presentation/widgets/items/progress_metric_widget.dart`,
  `progress_week_bar_widget.dart` khi cần
- append visual revision vào M99.23, cập nhật `docs/wbs.md`
- tests/goldens/Widgetbook/visual audit. Không sửa Progress by Deck logic.

## Không được thay đổi

- BR-190…BR-199, UC-12, card-day/partition/streak definitions.
- Read-only behavior, live stream, midnight/reload no-spinner transition.
- Exact seven-day data/order/zero-fill; no metric from BR-191 forbidden list.
- Range selector semantics, by-deck query/sort/navigation, domain/data/SQL/schema.
- Global typography/color tokens để vá riêng màn.

## Tests bắt buộc

- Regression read-only, streak active/held/zero, Today partition, seven-day
  zero/max, lifetime empty, read error, live update và midnight reload.
- `getRect`: three cards shared edges/width; vertical `xl` section rhythm;
  internal label/content rhythm; metric grid alignment; seven track left/right,
  pitch và height; overview → pinned range spacing.
- 320dp @2.0, 393dp, 412dp; EN/VI; light/dark; large counts/long labels.
- Semantics: streak one statement, each day one statement, decorative bars
  excluded, metric labels preserve meaning without color.
- Render/inspect active, held-from-yesterday, zero streak, mixed/zero Today,
  mixed/all-zero week, lifetime empty, error, loaded refresh.

## Verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Không emulator IT: `not run — presentation-only restyle`. Clean stop khi gate,
geometry, semantics và state matrix xanh; không logic/data/navigation drift;
handoff sạch cho reviews. Coordinator mới update gallery và tạo PR.
