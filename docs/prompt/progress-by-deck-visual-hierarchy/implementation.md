# Upgrade Progress by Deck — Card Detail Visual Language

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc nâng cấp Progress by Deck thành drill-down compact, rõ hierarchy và nhất quán với Card Detail |
| **Scope** | Library/deck activity summary, range selector, deck rows, states, tests/goldens/gallery; không đổi metrics/query/navigation |
| **Source of truth for** | Hướng dẫn thực thi Progress by Deck visual hierarchy; nghiệp vụ vẫn thuộc BR-182…BR-189, UC-13 và wireframe M99 Progress by Deck |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-182…BR-189, UC-13, `docs/wireframes/m99-progress-by-deck.md`, M99.23, production Card Detail và tokens |
| **Updated by task** | Progress by Deck visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Restyle production **Progress by Deck** ở `/progress` và `/progress/:deckId`.
Không đổi four-metric definition, 7/30 range, current-location attribution,
hierarchy aggregation/order, stream/midnight refresh hoặc push-based drill-down.

Worktree safety: kiểm `git status`, branch và merge-base trước khi sửa; prompt và
reference ở source worktree là read-only. Không revert diff ngoài scope và không
commit/push/PR/merge trong implementation phase.

## Pre-flight và 5Why

Đọc canonical docs/code/tests/goldens, M99.23 composition, Card Detail visual
grammar và shared widgets. Lập reduced UI Contract/widget tree; kiểm branch/base/
dirty state; không commit/push/PR trong implementation phase.

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Detail level mở đầu bằng số rất lớn nhưng thiếu identity/path rõ trong first viewport. | Dùng compact header + summary panel, giữ deck identity là context dẫn. |
| 2 | Bốn metric đang cạnh tranh nhau và khó so theo hàng. | Dùng 2×2 metric grid có baseline/tabular figures, gập một cột khi hẹp. |
| 3 | Summary và repeated deck rows chưa phân biệt vai trò. | Summary dùng muted/focal surface nhẹ; rows dùng standard flat MxCard. |
| 4 | Range selector phải ghim nhưng không được đọc như tab của toàn app. | Giữ pinned band nhỏ, cùng edges và không thêm shadow/elevation. |
| 5 | Restyle dễ phá stack back qua cây. | Navigation push/back/deck-missing giữ nguyên và được review bằng scenario. |

## UI Contract

```text
Progress level CustomScrollView
├─ optional Overview header (top-level only; owned by M99.23)
├─ pinned compact 7/30 range band
├─ level identity/path where applicable
├─ range summary MxCard
└─ standard deck activity MxCard rows / empty / error
```

### Range và context

- Giữ đúng 7/30 selector, checkmark selected và pinned behavior. Không date
  picker/filter/sort mới.
- Top-level title vẫn Progress. Deck level phải làm rõ deck name/path bằng app
  bar/header hiện có, không dùng giant metric làm identity.
- Path wrap, không ellipsis. Không thêm breadcrumb top-level thứ hai nếu đã có
  path trong row/header theo wireframe.

### Summary panel

- Giữ đúng unique active cards, active days, Learning card-days, Reviewing
  card-days và unit explanation.
- Compact 2×2 metric grid với semantic wells, tabular counts, label `bodySmall`,
  value `titleMedium`; stack một cột theo measured available width/text scale.
- Summary có tone nhẹ khác rows nhưng không saturated fill/giant number/shadow.

### Deck rows

- Standard flat `MxCard`, title + current path + 2×2 compact metrics + chevron.
- Toàn row tappable với keyboard/focus/semantics do `MxCard.onTap` hoặc approved
  shared component sở hữu; không bọc `InkWell/GestureDetector` ngoài `MxCard`.
- Zero metrics neutral nhưng vẫn hiện. Không thêm Study CTA hoặc status due.
- Rows cùng edges, padding, grid columns; gap `md`, section break `xl` sau summary.

### States/composition

Giữ loading, mixed, all-zero, no-decks, no-subdecks, read-error, deck-missing và
live refresh. Top-level overview vẫn hiển thị theo contract M99.23 trên state phù
hợp. Không nested scroll; bottom nav không bị che.

## Files dự kiến

- `lib/features/progress/presentation/screens/progress_deck_screen.dart`
- `presentation/widgets/sections/progress_level_header_widget.dart`,
  `progress_range_selector_widget.dart`, `progress_summary_widget.dart`,
  `progress_deck_list_widget.dart`
- `presentation/widgets/items/progress_deck_row_widget.dart`,
  `progress_metric_widget.dart`
- append visual revision vào M99 Progress by Deck, cập nhật `docs/wbs.md`
- tests/goldens/Widgetbook/visual audit.

## Không được thay đổi

- BR-182…BR-189, four metrics/units/partition/ranges/sort/current attribution.
- Top-level vs deck-level composition, pushNamed stack/back/deep link.
- Query count/stream/midnight, read-only behavior, domain/data/SQL/schema.
- M99.23 overview anatomy hoặc range semantics.

## Tests bắt buộc

- Regression range switch no query/loading, current-location attribution UI,
  sort/zero rows, drill-down/back/deck-missing, all states/live update.
- `getRect`: range/summary/rows shared edges; summary→row `xl`, row gap `md`;
  metric grid columns/baselines/folding; title/path/chevron; 48dp row target;
  pinned band height adapts at text scale 2.
- 320dp @2.0, 393dp, 412dp; EN/VI; light/dark; long path/name; 4-digit counts;
  top-level and deep level.
- Semantics one row statement with deck/path/four metrics and button role; color
  not sole signal; selected range announced.
- Render/inspect mixed, all-zero, no decks/subdecks, error, missing, deep levels.

## Verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Không emulator IT: `not run — presentation-only restyle`. Clean stop khi gate,
geometry/state/a11y pass, navigation/metrics/data không drift và handoff reviews
sạch. Coordinator mới regenerate gallery và tạo PR.
