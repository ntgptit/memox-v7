---
last_updated: 2026-06-06
status: contract
route: /home
screen: Dashboard
mock_source: "docs/system-design/MemoX Design System/ui_kits/mobile/index.html — 02 · Dashboard"
---

# Dashboard Visual Contract

Maps the approved **Dashboard** mock to its (not-yet-built) Flutter
implementation. The `/home` route and the bottom-nav tab are wired, but the
**screen body is not implemented on this ref** — `app_router.dart` points `/home`
at `RoutePlaceholder`, and there is no `lib/presentation/features/dashboard/**`
package. This contract documents the intended V1 surface so it can be built
correctly with existing tokens and shared widgets.

> ⚠️ **Doc/code drift.** `docs/wireframes/01-dashboard.md` ("Prompt 04")
> describes the resume card, recent decks, Today CTA, and "Start new learning"
> as *implemented and tested* and cites `lib/presentation/features/dashboard/**`
> files. Those files are **absent on this ref**. Build against this contract;
> reconcile the wireframe. See §16.

## 1. Screen identity

- **Screen name:** Dashboard
- **Route:** `/home` (`RoutePaths.home`, `RouteNames.home`); shell branch 0.
  (Note: app boot still redirects `/` → Library; do not change the launch
  default in a docs/parity task.)
- **Feature / module:** planned `dashboard` (`lib/presentation/features/dashboard/**`).
- **User purpose:** Learning-first landing surface — continue a paused session
  and point to the next study action.
- **Mock source:** `index.html` `02 · Dashboard` (states: loaded · loading ·
  onboarding · goal off · resume only · streak broken · error · offline · multi
  resume).
- **Related business docs:** `docs/business/engagement/dashboard-engagement.md`,
  `docs/business/resume/resume-session.md`, `docs/business/study/study-flow.md`.
- **Related wireframe:** `docs/wireframes/01-dashboard.md`.
- **Related UI/UX docs:** `docs/ui-ux/ui-ux-contract.md`,
  `docs/ui-ux/action-hierarchy-contract.md`, `docs/design/design-token-mapping.md`,
  `docs/design/component-visual-contract.md`.
- **Related state docs:** `docs/state/state-management-contract.md`; planned
  `DashboardNotifier`.
- **Existing Flutter implementation files:** **none** (route → `RoutePlaceholder`).
- **Scope status:** **Future** (screen body); route + shell tab are Current.
- **Out-of-scope items (Future):** streak chip + history sheet, daily-goal ring +
  goal sheet, reminders/notification permission, streak-broken banner, dedicated
  onboarding route/carousel, Global Search action + search icon nav.

## 2. Source priority

1. Business: `dashboard-engagement.md`, `resume-session.md`, `study-flow.md`.
2. Wireframe `01-dashboard.md` (heed `Forbidden`/`Rules`; discount its
   "implemented" claims — see §16).
3. State: planned `DashboardNotifier`; `state-management-contract.md`.
4. Route/navigation: `RoutePaths`/`RouteNames`; `navigation-flow.md`.
5. Existing Flutter: none yet (build new under `features/dashboard/**`).
6. Shared widgets: `mx_widgets.dart`.
7. Theme/tokens: `lib/core/theme/**`.
8. Mock `02`.
9. This contract.

Mock = visual intent only. Engagement (streak/goal/reminders) must not be built
from the mock until the engagement product decision lands.

## 3. Screen layout overview

`MxScaffold` + `MxAppBar` (time-aware greeting) over a vertically scrolling body
inside the bottom-nav shell. Per `action-hierarchy-contract.md`, action cards use
**compact, trailing-aligned, stacked** card actions (`MxActionButton`
`cardPrimary`/`cardSecondary`), not full-width hero CTAs — exactly one dominant
primary per card.

| Region | Position | Fixed/Scrollable | Visual weight | Token mapping | Shared widget | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| App bar (greeting) | Top | Fixed | Low | `SizeTokens.appbar`; app-bar glass | `MxAppBar` (`titleText` = greeting) | Trailing search icon = **Future** (no Global Search); settings ⚙️ → `/settings`. |
| Streak-broken banner | Top of body (one-time) | Fixed | Medium | callout tokens | `MxCallout` | **Future.** Above resume card when shown. |
| Resume card | Top of body | Fixed | High | `MxCard`; `cardPadding`; `brLg` | `MxCard` + `MxCardActions` | **Current-intent.** Only if a resumable session exists; Continue (primary) / Discard (secondary). "{n-1} more paused sessions" link → paused-sessions sheet. |
| Streak chip | Below resume | Fixed | Low | chip `brFull`; `MxStreakChip` | `MxStreakChip` | **Future.** Hidden when streak = 0. V1 may show static "0 days" stat placeholder only. |
| Goal ring | Below streak | Fixed | Medium | `MxMasteryRing`/ring; `brLg` | ring widget | **Future.** Hidden (not greyed) when goal disabled. |
| Today CTA | Mid body | Fixed | High (primary) | `MxCard` + `MxActionButton cardPrimary` | action card | **Current-intent.** Subtitle = due count; disabled "all caught up" copy at 0 due → `/library/study/today`. |
| New-learning CTA | Below Today | Fixed | Medium | `MxActionButton cardSecondary` | action card | **Current-intent.** Opens scope picker sheet (Today/Deck/Folder; tag excluded V1). |
| Recent decks | Lower body | Scrollable | Medium | `MxSectionHeader`; `MxCard` rows | `MxSectionHeader` + deck rows | **Current-intent.** Fixed at 3, by `decks.updated_at desc`. Row → flashcard list. |
| Onboarding body (zero-content) | Replaces entire body | — | High | `MxEmptyState`-style | empty/onboarding layout | **Future** as dedicated layout; V1 surfaces thin empty-deck guidance only. |
| Bottom nav | Bottom (shell) | Fixed | Low | `SizeTokens.bottomNav` (80) | `MxBottomNavigationBar` (in `AppShell`) | **Current.** |

`SafeArea` top+bottom; bottom nav reserves the home-indicator gap.

## 4. State matrix

| State | Trigger | Visible regions | Hidden regions | Primary CTA | Secondary CTA | Shared state widget | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Loading | Initial open | per-section skeletons | — | — | — | `MxSkeleton` per card | Don't block on slowest query. |
| Populated | Normal | greeting, (resume), (streak/goal future), Today CTA, new-learning, recent decks | onboarding | "Start today's review" or "Start new learning" | companion | — | One dominant primary per card. |
| Onboarding (zero content) | `decks == 0 AND flashcards == 0` | onboarding layout only | resume/streak/goal/recent | "Create your first deck" | "Import from CSV/Excel"; "Sign in to restore" | `MxEmptyState` | **Future** as dedicated layout. |
| Resume only, no due | resumable exists, `dueToday == 0` | resume card; Today CTA disabled | — | "Start new learning" | — | — | Today CTA "All caught up — try new cards". |
| Goal disabled | `goalEnabled == false` | (hide goal ring + streak chip) | goal ring, streak chip | as populated | — | — | **Future** widgets; hidden, not greyed. |
| Streak broken | last streak > 0 AND yesterday not goal-met | one-time banner above resume | — | — | dismiss (auto) | `MxCallout` | **Future.** |
| Offline | connectivity lost | `MxOfflineBanner` above content; content still renders | — | as populated | — | `MxOfflineBanner` | Never blocks local study. |
| Error | query failure | inline error card + Retry | — | "Retry" | — | `MxErrorState` | "Couldn't load Dashboard." |

## 5. Element mapping

| Mock element | Purpose | Existing shared widget | Token/theme mapping | State visibility | Behavior scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Greeting title | Time-aware welcome | `MxAppBar(titleText:)` | app-bar title role; `onSurface` | all | **Current** | "Good evening, {name}" via l10n + `clock.now()`. |
| Search icon | Global Search | `MxIconButton(Icons.search)` | `iconMd`; `onSurfaceVariant` | all | **Future** | No Global Search route in V1; do not wire. |
| Settings icon | Open settings | `MxIconButton(Icons.settings)` | `iconMd` | all | **Current** | → `/settings`. |
| Resume card | Continue paused session | `MxCard` + `MxCardActions` | `brLg`; `cardPadding`; primary/secondary | resumable exists | **Current-intent** | Continue → `/library/study/session/{id}`; Discard → discard dialog. |
| "{n-1} more paused" link | Multi-resume | text button | label role; `primary` | multiple resumable | **Current-intent** | → paused-sessions sheet (`wireframes/25 §paused-sessions`). |
| Streak chip | Streak status | `MxStreakChip` | streak orange token; `brFull` | streak ≥ 1 | **Future** | Hidden at 0; no "Streak: 0". |
| Goal ring | Daily-goal progress | ring widget | `brLg`; primary→gold | `goalEnabled` | **Future** | Hidden when disabled. |
| Today CTA | Start due review | `MxCard` + `MxActionButton cardPrimary` | primary; `brLg` | all | **Current-intent** | Disabled "all caught up" at 0 due → `/library/study/today`. |
| New-learning CTA | Pick scope to study | `MxActionButton cardSecondary` | secondary | all | **Current-intent** | → scope picker sheet (tag excluded V1). |
| Recent decks header | Section label | `MxSectionHeader` | overline role; `onSurfaceVariant` | populated | **Current-intent** | "Recent decks". |
| Recent deck row | Open deck | `MxCard`/`MxListTile` | `brLg`; icon `iconMd` | populated | **Current-intent** | Fixed 3; → `/library/deck/:id/flashcards`. |
| Onboarding CTAs | First-run actions | `MxPrimaryButton`/`MxSecondaryButton` + `MxEmptyState` | button tokens | zero content | **Future (dedicated)** | V1 = thin empty-deck guidance. |
| Offline banner | Connectivity lost | `MxOfflineBanner` | status tokens | offline | **Current** (reusable primitive) | Brand-voice copy via l10n. |
| Bottom nav | Tab switching | `MxBottomNavigationBar` | `bottomNav` (80) | all | **Current** | Four tabs (Home/Library/Progress/Settings). |

## 6. Typography contract

| Text element | UI role | Typography token/role | Color role | Max lines | Overflow | l10n | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Greeting | Screen title | app-bar title / headline | `onSurface` | 1 | ellipsis | yes (name is data) | Time-aware. |
| Card titles | Action/section title | `titleSmall`/`titleMedium` | `onSurface` | 1–2 | ellipsis | yes | — |
| Card subtitles / counts | Metadata | `bodyMedium`/`labelMedium` | `onSurfaceVariant` | 1–2 | ellipsis | ICU plural ("{n} cards due across {m} decks") | Tabular figures. |
| Section overline | "Recent decks" | section overline (ALL CAPS, `sectionSpacing`) | `onSurfaceVariant` | 1 | clip | yes | `MxSectionHeader`; don't hand-roll. |
| CTA labels | Buttons | button label (bold, sentence case) | `onPrimary`/primary | 1 | clip | yes | — |
| Onboarding copy | Guidance | body/relaxed body | `onSurface`/`onSurfaceVariant` | wrap | wrap | yes | Calm coach voice. |

## 7. Color and surface contract

| Surface/role | Required role | Notes |
| --- | --- | --- |
| Page background | `surface` (via `MxScaffold`) | — |
| App bar | glass (page surface @ `surfaceGlass` + blur) | through `MxAppBar`. |
| Action/resume cards | `surfaceContainerLowest` via `MxCard` | ghost border; **no gradient** (mock's CTA gradients are flagged — flatten to `primaryContainer`/`surfaceContainer` tint; see §16). |
| Primary CTA | `primary`/`onPrimary` | Today review. |
| Secondary CTA | `secondary`/outline | New learning. |
| Streak | streak orange (`CustomColors`) | Future. |
| Goal ring | `primary` → gold on met | Future. |
| Offline banner | status tokens | reusable. |
| Error | `error` via `MxErrorState` | — |
| Dark mode | Tokyo Nebula parity | verify both themes. |

## 8. Spacing, sizing, and radius contract

| Area/element | Padding | Gap | Radius | Size token | Responsive | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Screen horizontal | `screenPadding` (24) | — | — | — | wider ≥600 | — |
| Between cards | — | `SpacingTokens.lg`/`sectionGap` | — | — | — | Section rhythm. |
| Card | `cardPadding` (16) | inner `sm`/`md` | `RadiusTokens.brLg` | — | — | Ghost border. |
| Card actions | — | `sm` | `brMd` | `MxButtonSize` | — | Compact, trailing-aligned, stacked. |
| Recent deck row | `cardPadding` | tile→text `md` | `brLg` | `MxIconTile` (`iconMd`) | — | — |
| Goal ring | — | — | — | ring 40/3dp in tiles or larger hero | — | Future. |
| Bottom nav | — | — | — | `bottomNav` (80) | side rail ≥600 | — |
| Touch targets | — | — | — | min `touch` (48) | — | — |

## 9. Interaction contract

| Interaction | Trigger | Expected behavior | State change | Shared component/API | Scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Continue resume | tap | → `/library/study/session/{id}` | nav | router | **Current-intent** | `push` (Dashboard stays in stack). |
| Discard resume | tap | discard dialog → cancel session | mutation | `MxConfirmationDialog` (`wireframes/24 §discard-session`) | **Current-intent** | status → cancelled. |
| Multi-resume link | tap | open paused-sessions sheet | sheet | `wireframes/25 §paused-sessions` | **Current-intent** | — |
| Start today's review | tap | → `/library/study/today` (entry gate) | nav | router | **Current-intent** | Disabled at 0 due. |
| Start new learning | tap | open scope picker sheet | sheet | `wireframes/25 §scope-picker` | **Current-intent** | Tag scope excluded V1. |
| Tap recent deck | tap | → `/library/deck/:id/flashcards` | nav | router | **Current-intent** | — |
| Tap settings icon | tap | → `/settings` | nav | router | **Current** | — |
| Tap search icon | tap | (none in V1) | — | — | **Future** | No Global Search. |
| Tap streak / goal | tap | open streak-history / goal sheet | sheet | — | **Future** | Only after engagement promoted. |
| Pull to refresh | pull | re-run all queries, replace skeletons | refresh | `DashboardNotifier` | **Current-intent** | Don't no-op. |
| Offline | connectivity stream | show `MxOfflineBanner`; keep content | — | `connectivity_plus` → banner | **Current** | — |

## 10. Motion and animation contract

| Motion | Token | Notes |
| --- | --- | --- |
| Per-card skeleton → content | `contentSwitch` (200) | independent per section. |
| Goal-met pulse | `countUp`/`stateChange`; reduced-motion gated | **Future**; no `elasticOut`. |
| Page transitions | `pageTransition` (300) + emphasized | router default. |
| Button press | M3 state layer (no scale-down) | — |
| Skeleton pulse / "continue" dot | gated on `prefers-reduced-motion` | neutralize on reduce. |

## 11. Accessibility contract

- **SR order:** greeting → (streak-broken banner) → resume card (Continue,
  Discard) → (streak/goal future) → Today CTA → New-learning CTA → recent decks
  → bottom nav.
- **Semantic labels:** search/settings icons labeled; goal ring announces
  "{progress} of {goal} cards"; streak chip "{n}-day streak".
- **Touch targets:** all CTAs ≥ 48dp.
- **Onboarding focus order:** title → primary CTA → secondary CTA → sign-in.
- **Contrast:** AA both themes. **Text scaling:** cards reflow; counts tabular.

## 12. Responsive contract

| Context | Fixed | Scrolls | Wraps | Truncates | Never hidden | Denser |
| --- | --- | --- | --- | --- | --- | --- |
| Small/normal/large mobile | app bar, bottom nav | body | card copy | titles | resume card, Today CTA | — |
| ≥600dp | app bar, side rail (nav) | columns | — | titles | resume, Today | **two-column** (resume/streak/goal left; Today/new/recent right) |
| ≥1024dp | as ≥600 with wider gutters | columns | — | titles | same | — |

Resume card must appear above everything when present. Onboarding replaces ALL
content when triggered.

## 13. Data/content contract

- **Real data:** greeting (local time), resumable session(s), today due count,
  recent 3 decks, content counts (empty-state branch). Engagement flags
  (goal/streak) are **Future**.
- **Mock/demo data (do NOT copy):** "Giap", "Korean N5", "7-day streak", "12/20",
  "18 cards due across 3 decks".
- **Empty value display:** zero content → onboarding/empty guidance; never blank.
- **Count formatting:** ICU plurals; tabular figures; hide streak at 0; hide
  Today CTA active state when 0 due (use caught-up copy).
- **Sorting:** recent decks by `updated_at desc`, fixed at 3 (do not
  parameterize).
- **Localization:** all strings via ARB.

## 14. Flutter implementation guidance

**Inspect before building:** `lib/app/app_shell.dart`, `app_router.dart`
(replace the `/home` `RoutePlaceholder` builder), `route_names.dart`,
`mx_widgets.dart`, `dashboard-engagement.md`, `resume-session.md`,
`action-hierarchy-contract.md`.

**Create (planned):** `features/dashboard/screens/dashboard_screen.dart`,
`features/dashboard/notifiers/dashboard_notifier.dart`, and per-section widgets
(`resume_card.dart`, `recent_decks.dart`; `streak_chip.dart`, `goal_ring.dart`
only when engagement is promoted).

**Reuse:** `MxScaffold`, `MxAppBar`, `MxCard`, `MxCardActions`, `MxActionButton`,
`MxSectionHeader`, `MxIconTile`, `MxSkeleton`, `MxEmptyState`, `MxErrorState`,
`MxOfflineBanner`, `MxBottomNavigationBar`, `MxConfirmationDialog`.

**Must not change:** token classes, `Mx*` internals, route structure, l10n key
names, and the launch default (`/` → Library).

**Forbidden assumptions:** no streak/goal/reminder engine exists; no Global
Search; no dedicated onboarding route. Do not call repos/DAOs from the widget —
go through the notifier. Do not refresh the whole screen on a single section
change. Do not compute due count in `build`.

## 15. Visual parity checklist

- [ ] All mock elements documented (§5).
- [ ] Current-intent elements (resume, Today CTA, new-learning, recent decks)
      implementable with existing widgets/tokens.
- [ ] Future elements marked (streak, goal, reminders, onboarding route, search).
- [ ] No raw hex / random spacing / raw `TextStyle` / raw `Card` required.
- [ ] No hardcoded strings (l10n + ICU).
- [ ] Loading / populated / onboarding / resume-only / goal-off / streak-broken /
      offline / error states distinct.
- [ ] Dark mode considered. [ ] Text scaling considered. [ ] Accessibility
      considered. [ ] Conflicts documented (§16).
- [ ] No CTA gradients (flatten per design rule).

## 16. Open questions and conflicts

| Issue | Type | Affected element | Reason | Recommended action |
| --- | --- | --- | --- | --- |
| Wireframe marks resume/recent/Today/new-learning "implemented and tested"; no `features/dashboard/**` exists on this ref | Unknown source | Whole screen | Doc ahead of code (or unmerged branch) | Confirm source of truth; build per this contract; update wireframe |
| Mock CTA cards use `linear-gradient` fills; design rule says no gradients in chrome (only mastery gradient) | Mock-only element | Resume/Today cards | Deliberate mock styling vs. system rule | Flatten to `primaryContainer`/`surfaceContainer` tint (also the cleaner token map) unless product confirms a hero-CTA tint |
| Search icon shown in app bar | Future scope | App-bar search | Global Search is Future | Render no action (or omit) until Global Search route lands |
| Streak/goal/reminders shown in mock | Future scope | Streak chip, goal ring | Engagement product decision pending | Keep Future; V1 may show static "0 days" stat placeholder only |
| Onboarding zero-content layout | Future scope | Onboarding body | No dedicated route in V1 | Use thin empty-deck guidance; defer full onboarding |
| Launch default | Route conflict | Boot destination | Mock implies Dashboard-first; boot redirects to Library | Keep Library default; changing it needs a dedicated navigation task |

## Related

- `docs/design/README.md`, `docs/design/screen-index.md`
- `docs/design/design-token-mapping.md`, `docs/design/component-visual-contract.md`
- `docs/wireframes/01-dashboard.md`, `docs/wireframes/23-onboarding.md`,
  `docs/wireframes/12-study-entry-gate.md`, `docs/wireframes/18-study-result.md`
- `docs/wireframes/25-shared-bottom-sheets.md` §paused-sessions, §scope-picker,
  §streak-history, §daily-goal
