---
last_updated: 2026-06-06
status: contract
route: /progress
screen: Progress
mock_source: "docs/system-design/MemoX Design System/ui_kits/mobile/index.html — 19 · Progress (18 · Stats = legacy ref only)"
---

# Progress Visual Contract

Maps the approved **Progress** mock to its (not-yet-built) Flutter
implementation. The `/progress` route and bottom-nav tab are wired, but the
**screen body is not implemented on this ref** (route → `RoutePlaceholder`; no
`lib/presentation/features/progress/**`). This contract documents the intended
**read-only V1 Progress Overview**, not the chart-heavy analytics mock (which is
explicitly Future).

> ⚠️ **Doc/code drift.** `docs/wireframes/03-progress.md` ("Prompt 20") describes
> a Current read-only overview and cites `features/progress/**` files that are
> **absent on this ref**. Build per this contract; reconcile the wireframe. The
> chart-heavy analytics layout in the mock (`19 · Progress`, `18 · Stats`) is
> **Future** and must not be implemented from the mock. See §16.

## 1. Screen identity

- **Screen name:** Progress
- **Route:** `/progress` (`RoutePaths.progress`, `RouteNames.progress`); shell
  branch 2.
- **Feature / module:** planned `progress` (`lib/presentation/features/progress/**`).
- **User purpose:** Read-only learning insights. Dashboard shows "today";
  Progress shows library-summary metrics + active-session recovery. **No edit
  actions.**
- **Mock source:** `index.html` `19 · Progress` (states: week · month · loading ·
  empty · insufficient · partial · error). `18 · Stats` is legacy reference only.
- **Related business docs:** `docs/business/srs/srs-review.md`,
  `docs/business/engagement/dashboard-engagement.md`,
  `docs/business/system/overview.md` ("Progress tracking — partially specified").
- **Related wireframe:** `docs/wireframes/03-progress.md`.
- **Related state docs:** `docs/state/state-management-contract.md`; planned
  `progress_session_notifier`, `progressOverviewProvider`.
- **Existing Flutter implementation files:** **none** (route → `RoutePlaceholder`).
- **Scope status:** **Future** (screen body); route + shell tab are Current.
- **Out-of-scope items (Future):** cards-studied bar chart, accuracy line chart,
  box distribution (1–8), streak/daily-goal widgets, suspended/buried links
  (need Global Search/global filtered list), Flashcard History, time-range chips
  as live filters.

## 2. Source priority

1. Business: `srs-review.md`, `dashboard-engagement.md`, `system/overview.md`.
2. Wireframe `03-progress.md` (use its `V1 verification status` + `V1 metric
   semantics` tables; discount "Current owner" file paths — see §16).
3. State: planned `progressOverviewProvider`, `ProgressSessionActionController`.
4. Route/navigation: `RoutePaths`/`RouteNames`.
5. Existing Flutter: none yet.
6. Shared widgets: `mx_widgets.dart`.
7. Theme/tokens: `lib/core/theme/**`.
8. Mock `19`/`18`.
9. This contract.

Mock = visual intent only. Charts/box-distribution must not be built before
their aggregate use cases exist.

## 3. Screen layout overview

`MxScaffold` + `MxAppBar` (title only, no actions) over a scrolling body inside
the shell. **V1 target body** = a read-only overview (due/new/mastery summary +
active-session list), wrapped in `MxRetainedAsyncState`. The mock's
chips+charts+box layout is the Future analytics target.

| Region | Position | Fixed/Scrollable | Visual weight | Token mapping | Shared widget | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| App bar | Top | Fixed | Low | `SizeTokens.appbar` | `MxAppBar` (`titleText` only) | No actions; read-only screen. |
| Time-range chips | Below app bar | Fixed | Low | chip `brFull` | chip row | **Future** (analytics). Not rendered V1. |
| Overview summary | Top of body | Fixed | High | `MxCard`; `MxStatDisplay` | `MxStatDisplay` / `MxCard` | **V1 target.** Due now / New available / Mastery from `LibraryOverviewReadModel`. |
| Active sessions | Below overview | Scrollable | Medium | `MxCard` rows | `StudySessionCard` (planned) | **V1 target.** Active/ready/failed sessions with Continue/Finalize/Retry/Cancel. |
| Cards-studied chart | (mock) | — | High | `MxBarChart` exists in kit | `MxBarChart` | **Future.** No daily-attempt aggregate use case. |
| Accuracy chart | (mock) | — | High | line chart | — | **Future.** |
| Box distribution | (mock) | — | Medium | `MxLinearProgress` per box | `MxLinearProgress` | **Future.** Sort by box number 1→8. |
| Streak card | (mock) | — | Low | `MxStreakChip` | `MxStreakChip` | **Future** (engagement). |
| Suspended/buried links | (mock) | — | Low | list rows | — | **Future** (needs global filtered list). |
| Empty state | Body (no active sessions) | Fixed | Medium | `MxEmptyState` | `ActiveSessionsEmptyState` (planned) | **V1 target.** "No active sessions"; CTA → Library. Does NOT fake analytics. |
| Loading / Error | Body | — | — | `MxSkeleton` / `MxErrorState` | `MxRetainedAsyncState` | **V1 target.** Shared loading/error + Try again. |
| Bottom nav | Bottom (shell) | Fixed | Low | `bottomNav` (80) | `MxBottomNavigationBar` | **Current.** |

## 4. State matrix

| State | Trigger | Visible regions | Hidden regions | Primary CTA | Secondary CTA | Shared state widget | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Loading | Initial fetch | skeleton overview/sessions | charts | — | — | `MxRetainedAsyncState` skeleton | Not a blank screen. |
| Populated (V1) | Data loaded | overview summary + active sessions | charts/box/streak | session "Continue" | Finalize/Retry/Cancel | — | Read-only metrics. |
| Empty (V1) | No active/resumable sessions | overview summary + empty state | session list | "View library" → Library | — | `ActiveSessionsEmptyState` | No fake analytics data. |
| Error | query failure | error state + Retry | content | "Try again" | — | `MxErrorState` | No raw exception text. |
| Insufficient data (analytics) | < 2 days data | charts single point + hint | — | — | — | — | **Future.** |
| Populated (analytics) | range data | charts visible | — | — | — | — | **Future.** |

## 5. Element mapping

| Mock element | Purpose | Existing shared widget | Token/theme mapping | State visibility | Behavior scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| App bar title | Identify screen | `MxAppBar(titleText:)` | app-bar title role | all | **Current** | No actions. |
| Time-range chips (Week/Month/All) | Filter analytics | chip widget | `brFull`; primary-selected | (mock) | **Future** | Not rendered V1. |
| Due now / New / Mastery summary | Library metrics | `MxStatDisplay` in `MxCard` | `brLg`; tabular figures; mastery green | V1 populated/empty | **Current-intent** | From `LibraryOverviewReadModel`; empty = 0 / 0% . |
| Active session card | Resume/finalize/retry/cancel session | `StudySessionCard` (planned) + `MxCardActions` | `brLg`; status badge tokens | V1 populated | **Current-intent** | Status, current card, started date/time, progress steps. |
| Cards-studied bar chart | Daily totals | `MxBarChart` | `chartDraw` (600); mastery gradient | (mock) | **Future** | No aggregate use case. |
| Accuracy line chart | Accuracy trend | line chart | chart tokens | (mock) | **Future** | — |
| Box distribution bars | Per-box counts | `MxLinearProgress` | `brFull`; status palette | (mock) | **Future** | Sort 1→8, snapshot (not range). |
| Streak card | Current/longest streak | `MxStreakChip` | streak orange | (mock) | **Future** | Engagement. |
| Suspended/buried links | Jump to filtered list | list rows | row tokens | (mock) | **Future** | Needs global filtered list. |
| Empty state | No sessions | `MxEmptyState` | `iconXl` | V1 empty | **Current-intent** | CTA → Library. |
| Loading / Error | Async surfaces | `MxSkeleton` / `MxErrorState` | state themes | loading/error | **Current-intent** | Per `MxRetainedAsyncState`. |

## 6. Typography contract

| Text element | UI role | Typography token/role | Color role | Max lines | Overflow | l10n | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| App bar title | Screen title | app-bar title | `onSurface` | 1 | ellipsis | yes | "Progress". |
| Stat value | Metric figure | display/heading + tabular figures | `onSurface` (mastery → green) | 1 | clip | numeric | `MxStatDisplay`. |
| Stat label | Metric caption | `labelMedium` | `onSurfaceVariant` | 1 | ellipsis | yes | "Due now", "Mastery". |
| Session title/status | List item | `titleSmall` + status label | `onSurface` / status color | 1–2 | ellipsis | yes (localized status) | — |
| Session meta (date/progress) | Metadata | `bodyMedium`/`labelMedium` | `onSurfaceVariant` | 1 | ellipsis | formatted date/time | — |
| Empty/error copy | Guidance | empty/error roles | `onSurface`/`onSurfaceVariant` | wrap | wrap | yes | Calm voice. |
| Chart summary text | Analytics caption | `bodyMedium` | `onSurfaceVariant` | 1–2 | wrap | yes | **Future**; precedes chart for a11y. |

## 7. Color and surface contract

| Surface/role | Required role | Notes |
| --- | --- | --- |
| Page background | `surface` | `MxScaffold`. |
| App bar | glass | `MxAppBar`. |
| Cards | `surfaceContainerLowest` via `MxCard` | ghost border. |
| Mastery value | mastery green (`CustomColors`) | tri-stop gradient only on bars/charts. |
| Session status | status palette (active/ready/failed) | `CustomColors`; localized labels. |
| Primary action | `primary` | session Continue. |
| Destructive (Cancel) | `error` | requires confirm. |
| Error | `error` via `MxErrorState` | — |
| Dark mode | Tokyo Nebula parity | charts legible on navy. |

## 8. Spacing, sizing, and radius contract

| Area/element | Padding | Gap | Radius | Size token | Responsive | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Screen horizontal | `screenPadding` (24) | — | — | — | wider ≥600 | — |
| Between sections | — | `sectionGap` (32) | — | — | — | — |
| Card | `cardPadding` (16) | inner `sm`/`md` | `brLg` | — | 2-col ≥600 | — |
| Session card actions | — | `sm` | `brMd` | `MxButtonSize` | — | stacked/trailing. |
| Box-distribution bar | — | row `sm` | `brFull` | — | full width | **Future.** |
| Empty-state icon | — | `lg`/`xl` | — | `iconXl` | center | — |
| Touch targets | — | — | — | min `touch` (48) | — | — |

## 9. Interaction contract

| Interaction | Trigger | Expected behavior | State change | Shared component/API | Scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| View library (empty CTA) | tap | → Library | nav | `AppNavigation.goLibrary()` | **Current-intent** | — |
| Continue session | tap | push study session route | nav | router | **Current-intent** | — |
| Finalize / Retry | tap | call study use case, refresh revision | mutation | `ProgressSessionActionController` | **Current-intent** | — |
| Cancel session | tap | confirm → cancel, refresh | mutation | `MxConfirmationDialog` + cancel use case | **Current-intent** | Requires confirmation. |
| Tap range chip | tap | (none V1) | — | — | **Future** | Analytics. |
| Tap suspended/buried | tap | (none V1) | — | — | **Future** | Needs global filtered list. |
| Tap chart bar/point | tap | (none V1) | — | — | **Future** | — |
| Retry (error) | tap | re-run query | invalidate | provider invalidate | **Current-intent** | — |

## 10. Motion and animation contract

| Motion | Token | Notes |
| --- | --- | --- |
| Skeleton → content | `contentSwitch` (200) | per-section. |
| Chart draw | `chartDraw` (600) | **Future**; reduced-motion gated. |
| Count-up on stats | `countUp` (400) | optional; reduced-motion gated; no `elasticOut`. |
| Page transitions | `pageTransition` (300) | router. |
| Button press | M3 state layer | no scale-down. |

## 11. Accessibility contract

- **SR order:** title → overview stats → active sessions → (empty/error). Charts
  (Future) must have a textual summary read **before** the chart.
- **Semantic labels:** stats announce "{value} {label}"; box distribution
  announces "Box {n}, {count} cards" (Future); session actions labeled.
- **Touch targets:** ≥ 48dp. **Range chips** keyboard-selectable (Future).
- **Contrast:** AA both themes. **Text scaling:** stat figures + copy reflow.
- **Empty/error announcement:** via `MxEmptyState`/`MxErrorState`.

## 12. Responsive contract

| Context | Fixed | Scrolls | Wraps | Truncates | Never hidden | Denser |
| --- | --- | --- | --- | --- | --- | --- |
| Mobile (all) | app bar, bottom nav | body | session meta | session titles | overview summary | — |
| ≥600dp | app bar, side rail | body | — | titles | overview summary | **charts 2-col**; box distribution full-width below (Future) |
| ≥1024dp | as ≥600 wider gutters | body | — | titles | same | — |

## 13. Data/content contract

- **Real data (V1):** `LibraryOverviewReadModel` (due/new/mastery/card counts)
  via `WatchLibraryOverviewUseCase`; active sessions via
  `ResumeStudySessionUseCase.listActiveSessions()`.
- **Future analytics data:** `study_attempts` aggregates (range), `flashcard_progress`
  box distribution / suspended / buried — none have a use case yet.
- **Mock/demo data (do NOT copy):** "124 this week", "88%", box counts, "7 days".
- **Empty value display:** Due/New = `0`, Mastery = `0%`, sessions = empty state.
  Each chart (Future) handles empty independently — no shared empty, no NaN.
- **Count formatting:** ICU plurals; tabular figures; mastery as integer %.
- **Sorting:** box distribution by box number (Future); sessions by repository
  order.
- **Localization:** all strings + status labels via ARB.

## 14. Flutter implementation guidance

**Inspect before building:** `app_router.dart` (replace `/progress`
placeholder), `route_names.dart`, `mx_widgets.dart`, `srs-review.md`,
`system/overview.md`, and `WatchLibraryOverviewUseCase` /
`ResumeStudySessionUseCase` contracts.

**Create (planned):** `features/progress/screens/progress_screen.dart`,
`providers/progress_session_notifier.dart`, `widgets/progress_overview_section.dart`,
`active_session_section.dart`, `study_session_card.dart`,
`active_sessions_empty_state.dart`.

**Reuse:** `MxScaffold`, `MxAppBar`, `MxCard`, `MxStatDisplay`,
`MxRetainedAsyncState`, `MxErrorState`, `MxEmptyState`, `MxSkeleton`,
`MxCardActions`, `MxConfirmationDialog`, `MxBottomNavigationBar`; and for Future
analytics `MxBarChart`, `MxLinearProgress`, `MxStreakChip`.

**Must not change:** token classes, `Mx*` internals, route structure, l10n keys.

**Forbidden assumptions:** no analytics aggregates exist; do not render charts,
box distribution, streak, or suspended/buried links from the mock. Progress is
**read-only** — add no edit actions. Do not invent fake trend data for empty.

## 15. Visual parity checklist

- [ ] All mock elements documented (§5).
- [ ] V1 elements (overview summary, active sessions, empty/loading/error)
      implementable with existing widgets/tokens.
- [ ] Future elements marked (charts, box distribution, streak, links, range
      chips).
- [ ] No raw hex / random spacing / raw `TextStyle` / raw `Card`.
- [ ] No hardcoded strings (l10n + ICU; localized statuses).
- [ ] Loading / populated / empty / error states distinct; each Future chart
      empties independently.
- [ ] Read-only (no edit actions).
- [ ] Dark mode considered. [ ] Text scaling considered. [ ] Accessibility
      (chart text summaries) considered. [ ] Conflicts documented (§16).

## 16. Open questions and conflicts

| Issue | Type | Affected element | Reason | Recommended action |
| --- | --- | --- | --- | --- |
| Wireframe marks the read-only overview "Current" with `features/progress/**` files; none exist on this ref | Unknown source | Whole screen | Doc ahead of code | Confirm source of truth; build per this contract; update wireframe |
| Mock is chart-heavy (charts, box distribution, streak); V1 target is a read-only summary + sessions | Future scope | Charts/box/streak | No aggregate use cases | Implement V1 overview only; defer analytics until aggregates exist |
| Suspended/buried links depend on a global filtered list / Global Search | Future scope | Suspended/buried rows | Global Search is Future | Do not render the links until that route lands |
| Time-range chips imply analytics filtering | Future scope | Range chips | No range aggregates | Do not render as live filters in V1 |
| Flashcard History reachable from mock context | Future scope | History entry | History is Future Proposal | Must not be exposed from Progress |

## Related

- `docs/design/README.md`, `docs/design/screen-index.md`
- `docs/design/design-token-mapping.md`, `docs/design/component-visual-contract.md`
- `docs/wireframes/03-progress.md`, `docs/wireframes/01-dashboard.md`,
  `docs/wireframes/06-flashcard-list.md`
