# A8 — Navigation / screen chrome deep audit

| | |
|---|---|
| Base commit (`BASE_SHA`) | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` — *refactor(theme): the dark card stops glowing, and elevation stops meaning two things (M100.35)* (#435) |
| Branch audited | `claude/a8-navigation-chrome-audit-5nkwbm` (session-designated; the task text names `audit/a8-navigation-chrome` — see *Owner decisions*) |
| Pinned SDK | Flutter **3.44.8** stable · Dart SDK constraint `^3.12.2` |
| Scope | `AppBarThemeData` · `NavigationBarThemeData` · `TabBarThemeData` · `MxNavigationBar` · `MxBreadcrumb` / `MxBreadcrumbStep` · `MxSessionTopBar` · `MxContentShell` · every raw `AppBar` / `NavigationBar` / `TabBar` / `Scaffold` / `SafeArea` in `lib/` · the router, the shell and the session stack |
| Mode | **Report only.** This commit adds exactly one file. No production, theme, test, Widgetbook, golden, CI or guard file was touched |
| Method | Every framework claim is read from the pinned SDK source, fetched at `flutter/flutter@3.44.8` (`packages/flutter/lib/src/material/{app_bar,navigation_bar,tabs}.dart`) and cited by line. Every app claim is read from the working tree at `BASE_SHA` and cited by `file:line`. Arithmetic is derived from those two sources and shown |

**What this audit could not do, stated plainly.** The container has no Flutter
SDK (`which flutter` → not found), so nothing here was measured on a pump.
Unlike the A4/A5/A6/A7 audits, there is no throwaway measurement suite behind
these numbers: every figure below is either a constant read out of source or
arithmetic over such constants, and each one says which. Findings whose
confirmation genuinely needs a render are marked **needs render** and carry the
test that would confirm them. `dart format`, `flutter analyze` and
`flutter test` were **not run** — this commit changes no Dart.

---

## 1 · Verdict

**The chrome layer is unusually well-built at the component level and
inconsistent at the composition level. Nothing here is a data-correctness bug;
the P1s are all the same shape — the *same question* ("where am I, how do I get
out") is answered by three different mechanisms depending on which screen and
which async frame you are looking at.**

Three things are genuinely right and the next pass should not touch them:

- **One `AppBar`, one `NavigationBar`, two `Scaffold`s, zero bypasses.** `AppBar(`
  appears exactly once in `lib/` (`mx_content_shell.dart:217`), `NavigationBar(`
  exactly once (`mx_navigation_bar.dart:121`), `Scaffold(` exactly twice
  (`mx_content_shell.dart:177`, `app_navigation_shell.dart:33`), `SliverAppBar`
  never, `TabBar` never. That is a stronger raw-usage result than any other
  component family this project has audited.
- **The `NavigationBarThemeData` is a near-exact restatement of
  `_NavigationBarDefaultsM3`** — `surfaceContainer`, `secondaryContainer`,
  `onSecondaryContainer` / `onSurfaceVariant` icons, `onSurface` selected label,
  `alwaysShow`. The two deliberate departures (elevation `0` plus a hairline;
  the `wght`-axis weight bump) are argued in place and correct.
- **The two-`Scaffold` split is the right structure.** `Scaffold` removes the
  bottom bar's height *and* the bottom padding from its body's `MediaQuery`
  (`navigation_bar.dart:291` puts the destination row inside its own `SafeArea`),
  so the branch screens' own `SafeArea` and their FAB slot land correctly with
  nothing computed by hand.

What is wrong is above the components:

- A nested deck level renders **no app bar at all** while it loads and when its
  read fails — no title, no back affordance, no route name, and a ~56 dp body
  jump when the data lands (**P1-01**).
- The deck list and the card list — one tap apart in the same drill-down —
  answer "where am I" with two different breadcrumb grammars, in two different
  slots, at two different text scales, one with a back arrow and one without
  (**P1-02**, **P2-08**).
- The app bar's leading ink and its action ink are the **exact inverse** of the
  M3 roles: leading resolves `onSurfaceVariant`, actions resolve `onSurface`
  (**P1-03**).

Everything else is a P2 or below. The single highest-value fix in the whole
report is **P1-01**, and it is small.

---

## 2 · Navigation map

### 2.1 The real hierarchy at `BASE_SHA`

```
MaterialApp.router (app.dart:64)
└── MobileFrameWidget → CompactScaleWidget            (app.dart:121)     builder
    └── GoRouter  rootNavigatorKey                    (app_router.dart:66)
        │
        ├── StatefulShellRoute.indexedStack           (app_router.dart:72)
        │   └── AppNavigationShell                    (app_navigation_shell.dart:26)
        │       Scaffold #1 { body: navigationShell, bottomNavigationBar: MxNavigationBar }
        │       │
        │       ├── branch 0  /decks                  DeckListScreen            ← cold start
        │       │   ├── /decks/search                 LibrarySearchScreen
        │       │   ├── /decks/starter                StarterLibraryScreen
        │       │   ├── /decks/tags                   TagCatalogScreen
        │       │   ├── /decks/trash                  TrashScreen
        │       │   └── /decks/:deckId                DeckListScreen(parentDeckId)
        │       │       │  redirect → …/cards when the deck holds cards (BR-63)
        │       │       ├── /decks/:deckId/study      StudyEntryScreen
        │       │       └── /decks/:deckId/cards      CardListScreen
        │       │           ├── …/new                 CardEditorScreen
        │       │           ├── …/import              CardImportScreen   ← rootNavigatorKey
        │       │           ├── …/:cardId/edit        CardEditorScreen
        │       │           └── …/:cardId             CardDetailScreen
        │       │
        │       ├── branch 1  /study                  StudyHomeScreen
        │       │   └── /study/:deckId                StudyEntryScreen
        │       │
        │       ├── branch 2  /progress               ProgressScreen
        │       │   └── /progress/:deckId             ProgressDeckScreen
        │       │
        │       └── branch 3  /settings               SettingsScreen
        │           └── /settings/reminders           ReminderSettingsScreen
        │
        └── errorBuilder                              RouteNotFoundScreen

  OFF THE ROUTE TABLE — imperative MaterialPageRoute, no URL:
    StudySessionScreen   Navigator.of(context, rootNavigator: true).push(...)
                         study_entry_screen.dart:310 · study_home_screen.dart:149
    StudyOptionsScreen   Navigator.of(context).push(...)   (branch navigator)
                         study_entry_screen.dart:332
```

### 2.2 Chrome inventory, per screen

`MxContentShell` is the only screen frame; 20 call sites across 20 files.
`leading` is supplied by **3** of them. The remaining 17 either suppress the
leading slot or inherit Material's implicit `BackButton`.

| Screen | Slot used | `leading` | `titleSubline` | `subheader` | Implicit `BackButton`? |
|---|---|---|---|---|---|
| `DeckListScreen` root | title | — | stats line | — | n/a (branch root) |
| `DeckListScreen` nested, **loaded** | title | — | `DeckPathWidget` | — | **suppressed** (`:224`) |
| `DeckListScreen` nested, **loading** | — | — | — | — | **no app bar at all** |
| `DeckLevelErrorWidget` nested | — | — | — | — | **no app bar at all** |
| `CardListScreen` | title | — | — | breadcrumb + search + pills | **yes** |
| `CardDetailScreen` | title | — | — | — | **yes** |
| `CardEditorScreen` create | title | `Icons.close` | — | — | no (explicit) |
| `CardEditorScreen` edit | title | `Icons.arrow_back` | — | context strip | no (explicit) |
| `CardImportScreen` | title | `Icons.close` | — | breadcrumb + stepper + chip | no (explicit) |
| `TagCatalogScreen` · `LibrarySearchScreen` · `StarterLibraryScreen` · `TrashScreen` · `ProgressDeckScreen` · `ReminderSettingsScreen` · `StudyOptionsScreen` · `StudyEntryScreen` | title | — | — | varies | **yes** |
| `StudyHomeScreen` · `ProgressScreen` · `SettingsScreen` | title | — | — | — | n/a (branch root) |
| `StudySessionScreen` | *(none)* | — | — | — | **no app bar at all** (by design) |
| `RouteNotFoundScreen` | *(none)* | — | — | — | **no app bar at all** |

(`TrashScreen` supplies a `leading:` for its selection mode only; outside
selection it falls back to the implicit button.)

---

## 3 · Canonical contracts this audit judges against

Ordered as the audit rules require: **canonical Material role identity first,
project contract second, visual preference last.**

| # | Contract | Source |
|---|---|---|
| C1 | M3 top app bar: container `surface`, headline `onSurface`, **leading icon `onSurface`**, **trailing icons `onSurfaceVariant`**, height 64 | `_AppBarDefaultsM3`, `app_bar.dart:2521-2569` |
| C2 | M3 navigation bar: container `surfaceContainer`, active indicator `secondaryContainer` (stadium, 64×32), active icon `onSecondaryContainer`, active label `onSurface`, inactive both `onSurfaceVariant`, height 80, labels always shown | `_NavigationBarDefaultsM3`, `navigation_bar.dart:1427-1483` |
| C3 | M3 **primary** tabs: indicator `primary`, **label-width, 3 dp, top-rounded**; divider `outlineVariant` @ 1 dp; labels `titleSmall` | `_TabsPrimaryDefaultsM3`, `tabs.dart:2795-2866`; `_getIndicator`, `tabs.dart:1585-1640` |
| C4 | A control a finger must hit is ≥ 48 dp | `AppSizing.touchTarget`, `app_sizing.dart:28` |
| C5 | Selection is never signalled by colour alone | `app_navigation_bar_theme.dart:68-72`, `app_navigation_shell.dart:39-41` |
| C6 | `MxContentShell` is "the frame every screen is built in: app bar, gutters, an optional pinned subheader and an optional floating action" — screen padding and app-bar shape are decided **once** | `mx_content_shell.dart:11-16` |
| C7 | Four `StatefulShellBranch`, fixed order, real paths, deep-linkable; a full-screen task mounts on the root navigator | AD-19; `app_router.dart:72`, `:187` |
| C8 | Back goes up exactly one level in the tree; a breadcrumb jump replaces the stack | IT-NAV-003 / IT-NAV-004 |
| C9 | The session has exactly one way out — the ✕ — and the system back uses the same exit contract | BR-82; IT-NAV-010 |
| C10 | No user-visible string outside the ARB files; no hardcoded colour, text style or padding | `CLAUDE.md` §Non-negotiables |
| C11 | One breadcrumb shape, always in the same place | `deck_path_widget.dart:30-34` — *"the strip is now literal … the answer to 'where am I' is always on screen and always has the same shape"* |

---

## 4 · `AppBarThemeData`

`buildAppBarTheme` (`app_app_bar_theme.dart:15-22`) declares five slots:

```dart
backgroundColor: scheme.surface,
foregroundColor: scheme.onSurface,
scrolledUnderElevation: 0,
elevation: 0,
centerTitle: false,
```

**Correct, and worth keeping.** `surface` / `onSurface` is exactly
`_AppBarDefaultsM3` (C1). `scrolledUnderElevation: 0` with
`surfaceTintColor` left null is safe *only because* `backgroundColor` is
non-null: `_resolveColor` (`app_bar.dart:875`) falls through
`widget → theme → default`, and the M3 default for the scrolled-under
background is `colorScheme.surfaceContainer` (`app_bar.dart:935-939`). Set
`backgroundColor` to null and the bar would silently step to
`surfaceContainer` on scroll — the exact colour shift the file's own comment
forbids. That dependency is undocumented and is worth one line of comment.

**Three gaps.** They become P1-03, P2-09 and P2-11 below.

1. `iconTheme` / `actionsIconTheme` are unset, and Flutter's fall-through then
   inverts the two canonical roles (**P1-03**).
2. `toolbarHeight` is unset, and Flutter never consults
   `_AppBarDefaultsM3.toolbarHeight` — the bar renders at `kToolbarHeight`
   = 56, not M3's 64 (**P2-09**).
3. `titleTextStyle`, `titleSpacing`, `leadingWidth`, `shape` and
   `systemOverlayStyle` are all unset. Four of those resolve to a correct M3
   value; `systemOverlayStyle` is estimated per-bar from the background
   brightness (`app_bar.dart:1216-1225`), which is fine for every screen that
   *has* a bar — and is why the two screens without one have no status-bar
   contract at all (**P3-19**).

`centerTitle: false` restates the Android branch of
`_getEffectiveCenterTitle`, so it is a no-op on the release target and a real
(correct) override on iOS/macOS. Harmless.

---

## 5 · `NavigationBarThemeData` and `MxNavigationBar`

### 5.1 The theme is a faithful M3 restatement

Slot by slot against `_NavigationBarDefaultsM3` (`navigation_bar.dart:1427-1483`):

| Slot | App (`app_navigation_bar_theme.dart`) | M3 default | Verdict |
|---|---|---|---|
| `backgroundColor` | `surfaceContainer` (`:20`) | `surfaceContainer` | identical |
| `indicatorColor` | `secondaryContainer` (`:31`) | `secondaryContainer` | identical |
| icon selected | `onSecondaryContainer` (`:35`) | `onSecondaryContainer` | identical |
| icon unselected | `onSurfaceVariant` (`:36`) | `onSurfaceVariant` | identical |
| label selected | `onSurface` + `wght` 600 (`:59,63`) | `onSurface` | identical + a deliberate weight bump |
| label unselected | `onSurfaceVariant` (`:63`) | `onSurfaceVariant` | identical |
| `labelBehavior` | `alwaysShow` (`:72`) | `alwaysShow` | identical |
| `elevation` | `0` (`:67`) | `3.0` | **deliberate** — replaced by the hairline at `mx_navigation_bar.dart:97-103` |
| `indicatorShape` | unset → `StadiumBorder()` | `StadiumBorder()` | identical |
| **disabled state** | **absent** | `onSurfaceVariant.withOpacity(0.38)` | **P3-15** |

`_kIndicatorWidth` 64 × `_kIndicatorHeight` 32 (`navigation_bar.dart:29-30`) is
not overridden, so the indicator is canonical.

### 5.2 The non-colour cue is present and doubled

`app_navigation_shell.dart:42-63` pairs `*_outlined` with the filled glyph on
all four destinations, and the theme forces `alwaysShow` labels. On top of
that, Flutter 3.44.8 emits `SemanticsRole.tabBar` on the bar and
`SemanticsRole.tab` + `selected:` on each destination
(`navigation_bar.dart:294-306`), which the app gets for free. C5 is satisfied
three ways over. **No finding.**

### 5.3 The width cap paints a two-tone bar above 480 dp — P2-05

`widthPerNavigationDestination = 120` (`mx_navigation_bar.dart:28`) caps the
destination row at `destinations.length * 120` = **480** for the app's four
tabs (`:113-126`). Above 480 dp of surface the cap binds and the `Row`'s
`mainAxisAlignment: center` (`:105`) centres a 480-wide bar in a wider screen.

`NavigationBar`'s **`Material` — the thing that paints the background — is the
outermost widget it builds** (`navigation_bar.dart:285`), so it paints only
across the capped 480, while `MxNavigationBar`'s `DecoratedBox` hairline
(`:97-103`) spans the full width. The flanks show `scaffoldBackgroundColor`.

Those two are not the same colour: `scaffoldBackgroundColor: scheme.surface`
(`app_theme.dart:185`) versus `backgroundColor: scheme.surfaceContainer`
(`app_navigation_bar_theme.dart:20`). The file's own doc comment still asserts
the opposite:

> *"Seamless because `navigationBarTheme.backgroundColor` and
> `scaffoldBackgroundColor` are the same token: the bar paints the page colour,
> so narrowing it leaves no band edge to notice."* — `mx_navigation_bar.dart:21-23`

That sentence was true before M100.22 moved the bar to `surfaceContainer` and
is false at `BASE_SHA`. Result at ≥ 480 dp: a full-width hairline over a band
that is `surface` · `surfaceContainer` · `surface`, and the bottom gesture
inset (inside `NavigationBar`'s own `SafeArea`, `navigation_bar.dart:291`) is
unpainted at the flanks too.

`MobileFrameWidget` caps the **web** surface at 393 (`mobile_frame_widget.dart:12`)
and is `kIsWeb`-gated (`:29`), so this never appears on the E2E channel. It
appears on any Android tablet or unfolded foldable — and Android is the release
target (AD-04).

- **Violated contract** — C2 (the bar is one container), and the file's own
  stated invariant.
- **Exact callers** — `AppNavigationShell` (`app_navigation_shell.dart:35`) is
  the only production caller; the Widgetbook entry
  (`widgetbook/lib/components/control_components.dart:542`) reproduces it.
- **Recommendation** — move the paint outside the cap: keep the
  `ConstrainedBox` on the destination row, but give the full-width
  `DecoratedBox` the bar's own `surfaceContainer` fill so the band is one
  colour edge to edge. Do **not** raise the cap; the cap is doing a real job
  at two destinations. Correct the stale comment in the same change.
- **Closure test** — `mx_navigation_bar_test.dart`: pump at `Size(800, 900)`
  with four destinations and assert the painted band is a single colour across
  the full width (sample the `DecoratedBox`'s resolved decoration and the
  `Material`'s colour, and assert the `Material`'s width equals the surface
  width or that the flank colour equals the bar colour). Today no test pumps
  this widget above 412 dp.

### 5.4 Destination labels have no overflow contract — P3-16

`NavigationDestination.buildLabel` builds a bare
`Text(label, style: textStyle)` — **no `maxLines`, no `overflow`**
(`navigation_bar.dart:512`), inside
`MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` (`:505-512`,
`_kMaxLabelTextScaleFactor = 1.3` at `:31`). At 320 dp each destination gets
80 dp; `labelMedium` is 12 sp, clamped to 15.6 sp. `Library` / `Progress` /
`Thư viện` / `Tiến độ` all fit, which is why
`app_navigation_shell_destinations_test.dart:219` passes. A longer label — a
third locale, or a rename — wraps and then overflows a fixed
`SizedBox(height: 80)` with no ellipsis and no diagnostic. Latent, not live.

---

## 6 · `TabBarThemeData`

**There is no `TabBar`, `TabBarView`, `TabController` or `DefaultTabController`
anywhere in `lib/`.** The theme is a registered *planned* theme
(`app_theme.dart:285-293`), gated by
`test/core/theme/components/app_planned_themes_test.dart`, and its own header
names the consumer it is waiting for: the card detail screen's deferred
*History* view (`app_tab_bar_theme.dart:6-8`). That is a legitimate,
documented state and **not** a finding.

**Is any current caller a true tab?** No. The three candidates all switch a
filter over one list rather than switching between peer views, which is the
line M3 draws between tabs and filter chips:

| Caller | What it does | Correct primitive |
|---|---|---|
| `TrashFilterBarWidget` | all / decks / cards over one list | filter chips — and the file says so at `:10` |
| `CardFilterBarWidget` | filter predicate over one card list | filter chips |
| Progress range selector | 7 / 30 / 90 days over one dataset | segmented / chips |

`MxNavigationBar` is the app's only true "peer views" switcher and it is
correctly a `NavigationBar`, not a `TabBar`.

**One real defect in the theme itself — P2-06.** `indicatorSize:
TabBarIndicatorSize.tab` (`app_tab_bar_theme.dart:25`) contradicts
`_TabsPrimaryDefaultsM3`, whose constructor is
`super(indicatorSize: TabBarIndicatorSize.label)` (`tabs.dart:2796-2797`).
Read `_getIndicator` (`tabs.dart:1616-1640`) for what that costs:

```dart
final double effectiveIndicatorWeight = theme.useMaterial3
    ? math.max(widget.indicatorWeight, switch (widget._isPrimary) {
        true  => _TabsPrimaryDefaultsM3.indicatorWeight(indicatorSize),   // label → 3.0, tab → 2.0
        false => _TabsSecondaryDefaultsM3.indicatorWeight,                // 2.0
      })
    : widget.indicatorWeight;
final bool primaryWithLabelIndicator = switch (indicatorSize) {
  TabBarIndicatorSize.label => widget._isPrimary,
  TabBarIndicatorSize.tab   => false,          // ← forces the rounded cap off
};
```

So with `indicatorSize: tab` a plain `TabBar` — which is `_isPrimary` — renders
a **2 dp square-cornered indicator spanning the whole tab cell**. The M3
primary tab indicator is **3 dp, label-width, top-rounded at 3 dp radius**.
The theme silently converts every primary tab bar in the app into something
shaped like an M2 / secondary one, and it does it in the one slot where the
override cannot be seen from the call site.

- **Violated contract** — C3, and the audit's own rule that canonical Material
  role identity comes before visual preference.
- **Exact caller** — none yet, by design; the theme is registered at
  `app_theme.dart:293`, so the first `TabBar` written against it inherits the
  deviation on day one. That is precisely why this is worth fixing *before*
  the History view lands, not after.
- **Recommendation** — delete the `indicatorSize` line. Every other slot in
  the file already agrees with `_TabsPrimaryDefaultsM3` (`labelColor: primary`,
  `unselectedLabelColor: onSurfaceVariant`, `indicatorColor: primary`,
  `labelStyle: titleSmall`, `dividerColor: outlineVariant`,
  `dividerHeight: AppStroke.hairline` = 1 = M3's `1.0`), so removing it makes
  the file exactly canonical. If the owner wants the full-width indicator, the
  canonical way to ask for it is `TabBar.secondary`, not a theme override that
  reshapes the primary variant.
- **Closure test** — extend `app_planned_themes_test.dart`: assert
  `buildTabBarTheme(...).indicatorSize == null` (i.e. the M3 default survives),
  or pump a two-tab `TabBar` under `buildLightTheme()` and assert the resolved
  `UnderlineTabIndicator.borderRadius` is non-null and its `borderSide.width`
  is `3.0`.

---

## 7 · `MxBreadcrumb` / `MxBreadcrumbStep`

### 7.1 Two components in one class

`MxBreadcrumb` has two mutually exclusive renderings, selected by whether
`onUp` is non-null (`mx_breadcrumb.dart:312`):

| | **Strip form** (`onUp == null`) | **Header form** (`onUp != null`) |
|---|---|---|
| Built by | `build` (`:309-366`) | `_buildSingleTarget` (`:179-264`) |
| Layout | `SingleChildScrollView(horizontal)` | `Row` + `LayoutBuilder`, folds |
| Targets | one per step, `lineHeight` floor | **one**, the whole strip |
| Fold marker | `Icons.more_horiz`, expands in place | `…` character, never expands |
| Separators | `_MxBreadcrumbSeparator` — `ExcludeSemantics` (`mx_breadcrumb_step.dart:184`) | raw `Text(_kSeparator)` — **announced** (`:221`, `:228`) |
| Current step | present, non-tappable, quiet | **absent** (`deck_path_widget.dart:96-100`) |
| Up affordance | none | `chevron_left` + tap, long-press → sheet |
| Callers | card list, card editor, card import | deck list **only** |

Both are internally coherent and both are argued for in place. The problem is
that they are used on adjacent screens (P1-02).

### 7.2 The header form announces its punctuation — P2-07

`_buildSingleTarget` emits the separator and the fold marker as bare `Text`
widgets:

```dart
if (shown.length < items.length) ...<Widget>[
  Text(_kFoldedSteps, style: style),          // '…'   mx_breadcrumb.dart:219
  const SizedBox(width: AppSpacing.xs),
  Text(_kSeparator, style: style),            // '/'   mx_breadcrumb.dart:221
  ...
if (index > 0) ...<Widget>[
  const SizedBox(width: AppSpacing.xs),
  Text(_kSeparator, style: style),            // '/'   mx_breadcrumb.dart:228
```

The strip form wraps the identical glyph in `ExcludeSemantics`
(`mx_breadcrumb_step.dart:184-192`) with a comment explaining exactly why —
*"a separator with a semantic label would read the word 'chevron' between every
pair of names"*. The header form was cut later and did not inherit it.

On the deck list at level 4 a screen reader therefore traverses:
"Up one level, button" → "All decks" → "slash" → "Academic" → "slash" →
"Week 3". The `…` fold marker is announced as an ellipsis with no indication
that anything is hidden.

- **Violated contract** — C10-adjacent (`CLAUDE.md` a11y), and the component's
  own stated rule one file over.
- **Exact caller** — `DeckPathWidget` (`deck_path_widget.dart:76-101`), mounted
  as `titleSubline` by `deck_list_screen.dart:223` via `DeckSubheaderWidget`.
- **Recommendation** — wrap the three `Text` widgets in `ExcludeSemantics`, and
  raise the whole header form to `Semantics(container: true, excludeSemantics:
  true, button: true, label: …, value: <the path as one string>)` so the reader
  hears one control and one path instead of a control and five loose words.
- **Closure test** — `mx_breadcrumb_test.dart`, alongside the existing
  *"the separators are not announced"* (`:217`): the same assertion for the
  header form — build with `onUp`, and assert
  `tester.getSemantics(find.text('/'))` finds nothing / the `/` node carries no
  label.

### 7.3 The long-press affordance is invisible and its copy is orphaned — P2-08

`onShowAll` is the only route to a non-adjacent ancestor from a deck level
(`deck_path_widget.dart:88` → `showDeckAncestors`), and it is bound to
`InkWell.onLongPress` (`mx_breadcrumb.dart:191`) with:

- no visible hint anywhere on the strip,
- no `tooltip`,
- no `SemanticsHintOverrides.onLongPressHint`, and
- an outer `Semantics(button: true, label: 'Up one level')` (`:186-188`) that
  describes only the *tap*.

The copy that would fix it already exists, in both locales, and is rendered
nowhere:

```
lib/l10n/app_en.arb:4280   "deckPathAncestorsHint": "long press for all levels"
lib/l10n/app_vi.arb:4261   "deckPathAncestorsHint": "nhấn giữ để xem mọi cấp"
```

`grep -rn deckPathAncestorsHint --include=*.dart lib/` returns nothing. The
string was written for this affordance and never wired up. BR-55 allows ten
levels; from level 8 the only discoverable way to level 2 is six taps through
six `goNamed` replacements.

- **Violated contract** — C11 (the strip is supposed to be how you get back up)
  and C10 (a user-visible string that exists but is not shown is the inverse
  failure, and it is how the two drift).
- **Exact caller** — `deck_path_widget.dart:88`.
- **Recommendation** — pick one and only one: (a) render `deckPathAncestorsHint`
  as a trailing quiet label on the strip when `onShowAll != null`; or (b) drop
  the long press and put the ancestor sheet behind a visible chevron-down at
  the end of the strip. Either way add `SemanticsHintOverrides(onLongPressHint:
  …)` so assistive tech announces the second gesture. If neither is wanted, the
  ARB entry must be deleted — an orphan string is a claim about the UI that is
  not true.
- **Closure test** — `mx_breadcrumb_test.dart`: with `onUp` and `onShowAll`
  both set, assert the rendered subtree exposes a long-press hint
  (`getSemantics(...).hint` non-empty) — and an l10n test that every ARB key is
  referenced from `lib/`, which would have caught this and would catch the next
  one.

### 7.4 Fold arithmetic assumes `collapseAfter >= 3` — P3-17

`build` (`:314-315`) computes `isFolded = items.length > collapseAfter` and
`hiddenCount = items.length - 3`, then renders `first + fold + last two`. The
`3` is hard-wired to that shape. With `collapseAfter: 2` and three items the
widget renders every item *and* a fold marker claiming `0` hidden. No caller
passes below 3 today (`collapseAfter: 3` at `card_breadcrumb_widget.dart:41`,
`card_editor_context_widget.dart:112`, `card_import_context_widget.dart:46`;
default `4` on the deck list), so this is latent. An `assert(collapseAfter >= 3)`
in the constructor costs one line.

### 7.5 The header form's focus and hover states contradict the strip's — P3-18

`_MxBreadcrumbStep` suppresses every ink overlay deliberately —
`overlayColor: _noOverlay(context)`, `splashFactory: NoSplash.splashFactory`
(`mx_breadcrumb_step.dart:141-142`) — because *"four or five of those in a row
read as a toolbar of buttons rather than as a path"* (`:11-16`). The header
form's `InkWell` (`mx_breadcrumb.dart:189-192`) suppresses neither, and it
handles no `onFocusChange`. It therefore paints the app's theme-level
`focusColor` — `scheme.primary` at the focus alpha (`app_theme.dart:200`) —
as a filled rectangle across the whole title line, and gets no focus ring
(`AppInteractionStates.focusIndicator`) at all. Cosmetic, keyboard-only, but it
is the one state where the header form actively disagrees with the rule the
strip form is built around.

---

## 8 · `MxSessionTopBar` and its relation to `AppBar`

`MxSessionTopBar` (`mx_session_top_bar.dart:108-215`) is **not** an `AppBar`,
does not implement `PreferredSizeWidget`, and never enters the `Scaffold.appBar`
slot. `StudySessionScreen` passes no `title`, no `subheader` and no
`titleSubline` (`study_session_screen.dart:162-177`), so
`MxContentShell._buildAppBar` returns `null` (`mx_content_shell.dart:213-215`)
and the bar is drawn as the first row of the body, inside the shell's
`SafeArea`.

**That is the right call and the file argues it well** (`:163-167`): a Material
bar over the session would carry a back arrow that pops the route and leaves
the session open, which BR-82 forbids. The edge-to-edge region requirement
(`padding: EdgeInsets.zero` at `:177`, gutters re-applied by
`_leadingInset` / `_trailingInset` at `mx_session_top_bar.dart:60,72-73`) is
the same trick `AppBar` uses for its own leading icon, and the 48 dp close
target (`:164-169`, C4) is intact.

**What it does not inherit from `AppBar`, and nothing replaces:**

| `AppBar` provides | Source | Session bar |
|---|---|---|
| `Semantics(namesRoute: true, header: true)` on the title | `app_bar.dart:1069-1080` | absent |
| `AnnotatedRegion<SystemUiOverlayStyle>` derived from the background | `app_bar.dart:1216-1229` | absent (**P3-19**) |
| Title text-scale clamp at 1.34 | `app_bar.dart:1091-1097` | n/a (no title) |
| `Semantics(container: true)` around the bar | `app_bar.dart:1227` | absent |

The missing `AnnotatedRegion` matters because the session is pushed on the
**root** navigator (`study_entry_screen.dart:310`), above the shell — so the
`AnnotatedRegion` the branch's `AppBar` was contributing goes out of scope for
the duration of the session and nothing takes its place. **Needs render** to
confirm what the status bar actually does; the mechanism is certain from
source.

No colour, spacing or size finding: every value in the file resolves from
`AppSpacing` / `AppSizing` / `AppIconSize` / `AppRadius` / semantic colours,
and the chip is deliberately not `MxPillButton` (`:217-221`) for a stated and
correct reason.

---

## 9 · `MxContentShell`

### 9.1 What it owns, and what it does not

| Concern | Owned by the shell? | Where |
|---|---|---|
| App bar (title, leading, actions, subline, scroll hairline) | **yes** | `:210-241` |
| Screen gutter (16 / 12 below 360) | **yes** | `mxScreenGutter`, `:382-388` |
| `SafeArea` | **yes**, one, around the body column | `:180` |
| Pinned subheader band | **yes** | `MxSubheaderBand`, `:184-188`, `:327-373` |
| Pinned footer, above the keyboard | **yes** | `:195-203` |
| Opt-in scroll with min-height fill | **yes** | `:282-304` |
| Floating action **slot** | yes | `:179` |
| Floating action **clearance** | **no** — every caller re-derives it | **P2-12** |
| Max content width | **no** — three screens re-derive it | **P2-11** |
| Bottom-nav clearance | not needed — `Scaffold` #1 handles it | — |

### 9.2 The scroll hairline is drawn in the wrong place — P2-04

`_buildAppBar` puts the scrolled-under hairline on `AppBar.shape`
(`mx_content_shell.dart:235-239`) with this comment:

> *"Below the whole chrome block rather than between bar and subheader: the
> subheader is chrome too, and the line is there to say where chrome ends and
> scrolled content begins."*

The code does the opposite of what the comment says. In Flutter 3.44.8,
`shape` is applied to the **outermost `Material`** that wraps the toolbar
(`app_bar.dart:1230-1245`), and `MxContentShell` puts the subheader band
**below** the app bar, as the first child of the body `Column`
(`:180-188`). So the line lands *between the bar and the subheader*, and the
subheader — a search field, a breadcrumb, a row of filter pills — sits on the
content side of the seam with nothing separating it from the list scrolling
under it.

- **Violated contract** — C6 (the shell decides the app-bar shape once), and
  the file's own stated intent.
- **Exact callers** — every screen that uses the `subheader` slot:
  `library_search_screen.dart:139` (search field), `card_list_screen.dart:146`
  (breadcrumb + search + pills), `tag_catalog_screen.dart:63`,
  `card_import_screen.dart:238`, `card_editor_screen.dart:397`. Screens using
  `titleSubline` instead (`deck_list_screen.dart:223`) are unaffected — the
  subline is *inside* the bar, so the line is already below it.
- **Recommendation** — take the hairline off `AppBar.shape` and draw it as a
  `DecoratedBox` bottom border around the header block — i.e. around
  `MxSubheaderBand` when a subheader is present, and around the bar otherwise.
  The shell already draws exactly this line for the footer
  (`:196-201`), so the border side and token are settled. Keep
  `scrolledUnderElevation: 0`.
- **Closure test** — a new `test/shared/widgets/mx_content_shell_test.dart`
  (there is none today): pump the shell with a `subheader` and a long list,
  scroll past `_scrolledThreshold`, and assert the widget carrying the
  `borderSubtle` bottom border is positioned **below** the subheader's bottom
  edge (`tester.getRect`). Then a `card_list_screen` golden at 393×852.

### 9.3 The bar disappears when the title does — P1-01 / P2-10

`_buildAppBar` returns `null` when *title, subheader and subline are all
absent* (`mx_content_shell.dart:213-215`). `leading`, `actions` and
`floatingActionButton` are **not** in the condition. Two consequences:

**P2-10 (API).** A caller that passes `leading:` or `actions:` with no title
gets no bar and silently loses them. No live caller does this — but the slot
is public and the failure is silent, which is exactly the class of API trap the
`MxContentShell` doc comment says the component exists to prevent.

**P1-01 (live).** `DeckListScreen._titleBeforeData` returns `null` at any
nested level (`deck_list_screen.dart:108-109`) — deliberately, so a sub-deck
never shows the previous deck's name. It is then passed straight into the
shell:

```dart
loadingFrame: (loading) =>
    MxContentShell(title: _titleBeforeData(context), body: loading),   // deck_list_screen.dart:79
```
```dart
return MxContentShell(                                                 // deck_level_error_widget.dart:45
  title: title,                                                        //   null at a nested level
  body: MxErrorState(...),
);
```

Neither passes a `subheader` or a `titleSubline`. So at `/decks/:deckId`:

- **While the level loads** there is *no app bar at all* — no title, no
  `Semantics(namesRoute:)`, no back affordance.
- **When the read fails** — including the `NotFoundFailure` face for a deck
  someone deleted on another screen (UC-03 E1) — there is *no app bar at all*.
  For a plain read failure the only offered action is `Retry`
  (`deck_level_error_widget.dart:56-59`); if it keeps failing, the only ways out
  are the Android system gesture and the bottom bar.
- **When the data lands** the whole header materialises at once — title,
  subline and all — and the body's top edge moves down by the bar's height.
  From `toolbarHeight = widget.toolbarHeight ?? appBarTheme.toolbarHeight ??
  kToolbarHeight` (`app_bar.dart:925-926`) with neither of the first two set,
  that height is **56** (see P2-09). No back arrow ever appears: the loaded
  face suppresses the implicit one because its subline is non-null
  (`mx_content_shell.dart:224`). So the sequence a user sees entering a
  sub-deck is *no chrome → full header, list jumps 56 dp*. **Needs render** for
  the exact offset; the 56 is certain from source.

- **Violated contract** — C6 ("the frame every screen is built in: app bar…"),
  C8 (there must be a way up), and UC-03 E1's requirement that a missing deck
  gets "a gentle state with a way back".
- **Exact callers** — `deck_list_screen.dart:79`;
  `deck_level_error_widget.dart:45-47` (reached from `deck_list_screen.dart:87`).
  `ProgressDeckScreen` avoids this only because its `_titleBeforeData` returns
  a constant (`progress_deck_screen.dart:141`).
- **Recommendation** — two changes, both small, and they are independent:
  1. In `MxContentShell`, build the bar whenever *anything* the bar carries is
     present: `title != null || leading != null || (actions?.isNotEmpty ??
     false) || subheader != null || subline != null`. This alone fixes P2-10
     and gives the nested loading face a bar as soon as it is given one thing
     to put in it.
  2. In `DeckListScreen`, stop letting "we do not know the deck's name yet"
     mean "no chrome". Pass a neutral level title for the loading and error
     faces — the existing `decksTitle`, or a dedicated ARB key — so the bar and
     its back affordance are present in every face of the route. Do not invent
     a deck name; the objection in `_titleBeforeData`'s comment is right about
     *names* and wrong about *chrome*.
- **Closure test** — in `test/features/deck/presentation/`: pump
  `/decks/<id>` with the level provider held in `AsyncLoading`, then with an
  `AsyncError(NotFoundFailure())`, and assert `find.byType(AppBar)` is
  `findsOneWidget` in both, and that a back affordance is reachable. Plus a
  shell unit test that `MxContentShell(leading: X, body: Y)` renders `X`.

### 9.4 The two-line bar over-reserves height above text scale 1.34 — P2-13

`_toolbarHeight` (`mx_content_shell.dart:268-280`) computes the two-line bar
from the **ambient** text scaler:

```dart
final scaler = MediaQuery.textScalerOf(context);          // read in _MxContentShellState.build's context
return math.max(AppSizing.touchTarget,
    scaler.scale(title?.fontSize ?? 22) * (title?.height ?? 1.5)
        + AppSpacing.sm + MxBreadcrumb.compactLineHeight + _barPadding);
```

But `AppBar` clamps its title's text scaling to `_kMaxTitleTextScaleFactor =
1.34` (`app_bar.dart:43-44`, applied at `:1091-1097`), and
`MxContentShell` puts **both** the title and the subline inside that title slot
(`_buildTitle`, `:244-259`). So the height is computed against a scale the
content is not allowed to reach. With `titleLarge` = 22 sp / height 28⁄22
(`app_typography.dart:266-271`) and `compactLineHeight` = 32
(`mx_breadcrumb.dart:96`):

| textScaler | `_toolbarHeight` reserves | Block actually renders | Dead slack |
|---|---|---|---|
| 1.0 | 22·1·1.2727 + 8 + 32 + 16 = **84** | 28 + 8 + 32 = 68 | 16 — *the intended figure, and the comment's own arithmetic* |
| 1.3 | 22·1.3·1.2727 + 8 + 32 + 16 = **92.4** | 22·1.3·1.2727 = 36.4 → 36.4 + 8 + 32 = 76.4 | 16 |
| 2.0 | 22·2·1.2727 + 8 + 32 + 16 = **112** | 22·**1.34**·1.2727 = 37.5 → 37.5 + 8 + 32 = 77.5 | **34.5** |

At `textScaler` 2.0 the bar is 34.5 dp taller than the block it centres — on a
320×568 surface that is 6 % of the viewport spent on nothing, in the
configuration that can least afford it.

**The same clamp has a second, sharper consequence.** Because the deck path
lives in the title slot, `DeckPathWidget`'s text stops growing at 1.34× — while
`CardBreadcrumbWidget`, one tap deeper in the `subheader` slot
(`card_list_screen.dart:146`), is outside the clamp and grows to the user's
full 2.0×. The *same component* renders at two different text scales on two
adjacent screens. That is an accessibility regression hiding inside a layout
decision, and it is the strongest single piece of evidence for P1-02.

- **Violated contract** — C6, and `CLAUDE.md`'s large-text-scale requirement.
- **Exact caller** — `deck_list_screen.dart:223` is the only `titleSubline`
  caller.
- **Recommendation** — clamp the scaler used by `_toolbarHeight` to the same
  1.34 the bar applies (`TextScaler.clamp(maxScaleFactor: 1.34)`), so the
  reservation matches the render at every scale. Then decide the subline's home
  once, for both screens (see P1-02); if it stays in the title slot, the clamp
  is a deliberate, documented cap and the card list must adopt it too.
- **Closure test** — `mx_content_shell_test.dart`: pump with a `titleSubline`
  at `textScaler` 1.0 / 1.3 / 2.0 and assert
  `tester.getSize(find.byType(AppBar)).height` minus the rendered title-block
  height stays within one `AppSpacing` step at every scale.

### 9.5 Max content width is not the shell's, and the guard used to say it was — P2-11

`MxContentShell` applies no width cap. Four screens apply their own, all with
the same value and four separate `ConstrainedBox`es:

```
lib/features/card/presentation/screens/tag_catalog_screen.dart:111, :131, :183
lib/features/card/presentation/screens/card_import_screen.dart:258
lib/features/card/presentation/screens/card_detail_screen.dart:226
lib/features/study/presentation/widgets/sections/study_home_body_section_widget.dart:122
```

all `BoxConstraints(maxWidth: AppBreakpoints.medium)` (600). The remaining
sixteen screens have none, so above 600 dp the app is a mix of capped reading
columns and full-bleed lists.

This is not merely a style preference: the guard's own screen-shell contract —
present for the `memox` and `memox-v4` rulesets and **absent for `memox-v7`** —
names it as the shell's job:

> *"`MxScaffold`/… already wrap the body in `MxContentShell` (the page gutter +
> the max-width cap)"* —
> `code-verification-guard-v2/registries/projects/memox-v4/rules/memox-screen-shell-rules.yaml:39`

- **Violated contract** — C6 ("screen padding and the app-bar shape are decided
  once"), extended to width by the guard's own wording.
- **Exact callers** — the six sites above; and by omission, every screen that
  has no cap.
- **Recommendation** — give `MxContentShell` an opt-out `maxContentWidth`
  defaulting to `AppBreakpoints.medium`, centred, applied around the body and
  the subheader band together so both stay on the same column. Then delete the
  six local `ConstrainedBox`es. This is also half the fix for P2-05: at
  ≥ 600 dp the whole app becomes a centred column and the flanking bar band
  becomes a deliberate letterbox rather than an accident.
- **Closure test** — `mx_responsive_test.dart`: pump two different screens at
  `Size(800, 900)` and assert their body content rects have the same width and
  the same left edge.

### 9.6 FAB clearance is per-caller — P2-12

The shell takes a `floatingActionButton` (`:90`, `:179`) but reserves nothing
for it. Only one caller compensates:

```dart
const double _kListBottomInset = AppSpacing.fabScrollClearance;   // deck_list_sliver_widget.dart:26
```

and a second file declares a private constant with the **same name** meaning
something entirely different — `AppSpacing.lg`, on a screen with no FAB
(`library_search_body_widget.dart:24`). `MxSubheaderBand`'s own comment
(`mx_content_shell.dart:350-355`) already documents the collision this creates:
*"on the deck list that puts the last card's trailing icon under the floating
action — 24px of `textSecondary` on `primary`, which the visual audit fails at
1.13:1."*

The next screen that grows a FAB will re-derive the inset or forget it, and
forgetting it is invisible until someone scrolls to the bottom of a long list.

- **Recommendation** — when `floatingActionButton != null`, have the shell add
  `AppSpacing.fabScrollClearance` to the body's resolved bottom padding, and
  document that a caller passing `padding: EdgeInsets.zero` owns the clearance
  itself. Rename `library_search_body_widget.dart:24` so two different numbers
  stop sharing a name.
- **Closure test** — `mx_content_shell_test.dart`: with a FAB and a list taller
  than the viewport, scroll to the end and assert the last row's bottom edge is
  above the FAB's top edge.

---

## 10 · Root vs nested vs session grammar, and back vs close

### 10.1 The grammars actually in use

| Level | "Where am I" | "Up one level" | Mechanism |
|---|---|---|---|
| Branch root (`/decks`, `/study`, `/progress`, `/settings`) | app-bar title + selected tab | n/a | tab re-tap pops the branch to its root (`app_navigation_shell.dart:74-77`) |
| Deck level (`/decks/:id`) | title = deck name, **subline** = one-target path | strip tap → `goNamed(parent)` (`deck_path_widget.dart:53-67`); implicit back arrow **suppressed** (`mx_content_shell.dart:224`) | replace |
| Card list (`/decks/:id/cards`) | title = deck name, **subheader** = full scrolling path *ending in the deck name again* | per-step tap → `goNamed`; **plus** Material's implicit `BackButton` | replace *and* pop |
| Card editor / import | title, explicit `leading` | `Icons.arrow_back` (edit) / `Icons.close` (create, import) → `Navigator.pop` through the discard coordinator | pop |
| Session | `MxSessionTopBar` chip | ✕ only (BR-82); system back routed to the same exit via `PopScope` (`study_session_screen.dart:155-161`) | leave |

### 10.2 Two incompatible up-grammars, one tap apart — P1-02

`/decks/:id` → `/decks/:id/cards` is a single tap on a deck tile
(`deck_list_sliver_widget.dart:108`). Across that tap **every property of the
"where am I" chrome flips**:

| | Deck level | Card list |
|---|---|---|
| Component | `MxBreadcrumb` header form | `MxBreadcrumb` strip form |
| Slot | `titleSubline` (inside the bar) | `subheader` (below the bar) |
| Height | 32 (`compactLineHeight`) | 48 (`AppSizing.touchTarget`) |
| Text scale ceiling | **1.34** (AppBar clamp) | **unclamped** |
| Separator | `/`, announced | `/`, silenced |
| Targets | one, the whole strip | one per step |
| Fold | `…`, cannot be opened | `more_horiz`, expands in place |
| Ends with | the **parent** (current deck omitted, `deck_path_widget.dart:96-100`) | the **current deck** (duplicating the title, `card_breadcrumb_widget.dart:59-60`) |
| Leading chevron | `chevron_left` | none |
| Back arrow | **suppressed** | **present** |
| Hairline (P2-04) | below the path | **above** the path |

Both files argue their own choice, and each argument is locally sound. Read
together they contradict C11 — *"One shape, always in the same place, is
cheaper to read than a band of chrome that comes and goes"* — which is the
sentence `deck_path_widget.dart` uses to justify showing the strip at every
level. It shows it at every level in *two shapes*.

- **Violated contract** — C11; C8 (`goNamed` replaces while the co-present back
  arrow pops — from a deep link into `/decks/A/cards` the arrow and the crumbs
  go to different places); AD-15's "one grammar per surface" spirit.
- **Exact callers** — `deck_list_screen.dart:223` (via
  `deck_subheader_widget.dart` → `deck_path_widget.dart:76`) versus
  `card_list_screen.dart:146` (via `card_breadcrumb_widget.dart:33`), with the
  same divergence again at `card_editor_context_widget.dart:109` and
  `card_import_context_widget.dart:43`.
- **Recommendation** — this is an **owner decision**, not an engineering one,
  and it should be taken before any of the P2s in §7 and §9 are fixed, because
  three of them are cheaper on one side of the choice than the other. Two
  coherent options:
  - **(A) The header form wins.** Every level uses `titleSubline` + one-target
    strip + `chevron_left`; the card list drops its trailing self-reference and
    its subheader breadcrumb; `automaticallyImplyLeading` stays suppressed
    everywhere a subline exists. Cost: the 1.34 clamp becomes app-wide and must
    be documented as such; the ancestor sheet must get a visible affordance
    (P2-08). Buys: the smallest header, one grammar, and P2-04 mostly
    evaporates.
  - **(B) The strip form wins.** Every level uses `subheader` + per-step
    targets; the deck list gives up its 32 dp line for a 48 dp band; the back
    arrow is shown everywhere. Cost: ~16 dp of header on the app's busiest
    screen and the owner review of 2026-08-21 reversed. Buys: full text
    scaling, per-step targets, an openable fold.
  - Whichever wins, the loser's rendering path should be **deleted**, not left
    reachable — a component with two grammars will grow a third.
- **Closure test** — a cross-screen widget test that walks
  `/decks` → `/decks/:id` → `/decks/:id/cards` and asserts the path strip has
  the same widget type, the same height and the same slot at every stop; plus
  goldens for both screens at 393×852 in the gallery.

### 10.3 Back vs close is right where it is stated, and absent where it is not

The three screens that state it get it right, and `card_editor_screen.dart:403-415`
states the rule precisely:

> *"A back arrow in edit, an `×` in create, and the difference is real. Edit is
> pushed onto the card list and returns to it; create is a form the user opened
> and can abandon."*

`CardImportScreen` (`:226-235`) is consistent — a full-screen task on the root
navigator gets ✕, and the ✕ is disabled while the one commit runs. The session
(`MxSessionTopBar`) gets ✕ and routes the system gesture to the same exit.

**But 17 of 20 shells never make the choice** — they inherit Material's
implicit `BackButton` (`app_bar.dart:1011-1014`), which is **P2-14**.

### 10.4 The implicit back affordance is a raw Material widget — P2-14

When `leading == null && automaticallyImplyLeading` and the route can be
dismissed, `AppBar` inserts `const BackButton()` (`app_bar.dart:1014`). That is
a bare Material `IconButton` and it therefore:

- takes its semantics label and tooltip from
  `MaterialLocalizations.backButtonTooltip` ("Back" / the GlobalMaterial
  Vietnamese string), not from the app's ARB — so the app's most-used control
  is the one control whose copy is not owned by `lib/l10n/`;
- resolves its ink through `iconButtonTheme` (`onSurfaceVariant`, see P1-03)
  rather than through `MxIconButton`;
- is invisible to `memox_v7.design_system.no_raw_widget`, which scopes on
  `presentation_files` and matches source text — an *implicitly constructed*
  raw widget matches nothing.

The app has a wrapper for exactly this (`MxIconButton`, whose whole reason for
existing is that `semanticLabel` is required — `mx_icon_button.dart:31-36`) and
the shell's most common leading control does not use it.

- **Violated contract** — C10 (no user-visible string outside the ARB files);
  `CLAUDE.md` §Non-negotiables; the design-system admission rule.
- **Exact callers** — the 12 rows marked *"yes"* in §2.2.
- **Recommendation** — have `MxContentShell` build its own leading when
  `leading == null` and `ModalRoute.of(context)?.impliesAppBarDismissal ==
  true`: an `MxIconButton(icon: Icons.arrow_back, semanticLabel:
  l10n.<key>, onPressed: Navigator.maybePop)` — with the caveat that the shell
  is in `shared/` and may not read `l10n` itself, so the label must arrive as a
  parameter with a documented default, or the shell must expose
  `backSemanticLabel`. Keep `automaticallyImplyLeading: false` once it does.
- **Closure test** — `mx_content_shell_test.dart`: pump a pushed route with no
  `leading` and assert the leading widget is an `MxIconButton` carrying the
  supplied label, and that `find.byType(BackButton)` is `findsNothing`.

### 10.5 Two full-screen tasks, two mechanisms — P2-15

`CardImportScreen` is a `GoRoute` with
`parentNavigatorKey: rootNavigatorKey` (`app_router.dart:187`) — it keeps a
URL (`/decks/:id/cards/import`), is deep-linkable, and covers the shell.
`StudySessionScreen` does the same job with an imperative
`Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(...))`
(`study_entry_screen.dart:310`, `study_home_screen.dart:149`), and
`StudyOptionsScreen` with a branch-navigator `push`
(`study_entry_screen.dart:332`).

Consequences of the imperative form: no URL, so the browser location and the
router's `matchedLocation` both keep pointing at the *previous* screen while
the session is on top; nothing deep-links or restores into a running session;
and `GoRouterState` is a lie for the duration. IT-NAV-012 pins the import
wizard's shape; nothing pins the session's.

- **Recommendation** — mount `StudySessionScreen` and `StudyOptionsScreen` as
  `GoRoute`s (`/decks/:deckId/study/session`, `/study/:deckId/session`,
  `…/options`), the session with `parentNavigatorKey: rootNavigatorKey` exactly
  as the import wizard does. Constructor arguments that must not appear in a
  URL (`resumeSessionId`, `direction`) travel as `extra`. This is a routing
  change with real blast radius — it is listed here as a **deferred owner
  decision**, not as work for the chrome pass.
- **Closure test** — `app_router_test.dart`: assert
  `router.routerDelegate.currentConfiguration.uri` names the session while the
  session is on screen.

---

## 11 · The bottom-nav / FAB / content-clearance relationship

This is the part of the composition that is **correct**, and the reasoning is
worth recording so it is not "fixed" later:

1. `Scaffold` #1 (`app_navigation_shell.dart:33`) holds
   `bottomNavigationBar: MxNavigationBar`. Flutter's `Scaffold` passes
   `removeBottomPadding: bottomNavigationBar != null` for the body slot, so
   the branch content's `MediaQuery.padding.bottom` is zero and
   `MediaQueryData.removePadding` also reduces `viewPadding.bottom` by the same
   amount — the gesture inset is paid for **once**, inside `NavigationBar`'s
   own `SafeArea` (`navigation_bar.dart:291`).
2. `Scaffold` #2 (`mx_content_shell.dart:177`) therefore sees zero bottom
   padding, so its `SafeArea` (`:180`) is a no-op inside a branch and does the
   real work on the two root-navigator screens (session, import) where there is
   no bar below.
3. The FAB sits in `Scaffold` #2, so `endFloat` places it 16 dp above the
   *inner* scaffold's bottom, i.e. 16 dp above the navigation bar. Correct.
4. The last row of a list ends above the bar because of (1), and scrolls clear
   of the FAB because of `deck_list_sliver_widget.dart:79`.

Two residual notes:

- **P3-20.** `deck_list_sliver_widget.dart:79` adds
  `MediaQuery.viewPaddingOf(context).bottom` on top of `fabScrollClearance`.
  Per (1) that term is normally 0 inside a branch; it becomes non-zero while
  the keyboard is open (`padding.bottom` goes to 0, so
  `removePadding`'s `max(0, viewPadding.bottom - padding.bottom)` stops
  cancelling). Harmless — a little extra tail inset with the keyboard up — but
  the comment claims it is needed for the home indicator, which the navigation
  bar has already paid for. **Needs render** to confirm the exact value; the
  mechanism is certain.
- The FAB overlays the last *visible* row at rest by design
  (`deck_list_screen.dart:198-206`), and `MxSubheaderBand`'s comment
  (`mx_content_shell.dart:346-356`) measures that clearance at 7 px. That is
  tight enough that P2-12's shell-owned inset should be added carefully — it
  changes the resting frame, not just the scroll end.

---

## 12 · Responsive: 320 / 360 / 375 / 393 × textScale 1 / 1.3 / 2

**None of this was rendered.** What follows is what the source guarantees, and
where the guarantee runs out.

| Width | Gutter | Nav bar per destination | Notes |
|---|---|---|---|
| 320 | 12 (`mxScreenGutter`, compact) + `applyCompactScale` | 80 | `MxSubheaderBand` drops its top `sm` (`mx_content_shell.dart:367`); `MxSessionTopBar`'s start inset clamps to 0 (`mx_session_top_bar.dart:153-157`) |
| 360 | 16 | 90 | `AppBreakpoints.compact` boundary — the design's declared floor |
| **375** | 16 | 93.75 | **untested anywhere** — see below |
| 393 | 16 | 98.25 | the gallery / web frame size |
| ≥ 480 | 16 | capped at 120 | **P2-05** — the cap binds, the band goes two-tone |

**375 dp appears in no test in the repository.** Counting `Size(w, h)`
literals across `test/`: 320×568 (49), 393×852 (30), 360×640 (27), 390×844
(22), 320×640 (20), 412×915 (10), and a long tail — no 375. It is the width of
every non-Plus iPhone and of a large slice of small Android devices, and it
sits between the compact branch (< 360) and the gallery width, so it exercises
neither. This is a **coverage gap**, not a defect.

**Text scale.** Three clamps are in play and they do not agree:

| Surface | Ceiling | Source |
|---|---|---|
| App-bar title **and `titleSubline`** | **1.34** | `app_bar.dart:43-44`, applied `:1091-1097` |
| Navigation-bar labels | **1.3** | `navigation_bar.dart:31`, applied `:505-512` |
| `subheader`, body, footer, session bar | **unclamped** | — |

So at a user setting of 2.0 the deck list's path renders at 1.34× and the card
list's at 2.0×, and `_toolbarHeight` reserves for 2.0× on a bar that renders
1.34× (**P2-13**). The clamps themselves are Flutter's and are correct; what is
missing is anywhere in the project that states the ceilings exist.

**What is genuinely covered.** `app_navigation_shell_test.dart:295-337` and
`app_navigation_shell_destinations_test.dart:122-253` pump 320×568 at
`textScaler` 2.0 across four branches and assert no overflow, that all four
labels stay inside the bar, and that empty faces clear the bar.
`mx_breadcrumb_test.dart:229-300` pumps a ten-deep path at 320 and 320 ×
`textScaler` 2.0. That is a good baseline; it is the *widths above 412* and
the *375 case* that nothing reaches.

**EN / VI long labels.** The four tab labels are `Library` / `Study` /
`Progress` / `Settings` and `Thư viện` / `Học` / `Tiến độ` / `Cài đặt`
(`app_en.arb:7-21`, `app_vi.arb:7-21`), and
`app_navigation_shell_destinations_test.dart:276` pins the Vietnamese Study
label specifically. Titles ellipsize by way of `AppBar`'s
`DefaultTextStyle(softWrap: false, overflow: ellipsis)` (`app_bar.dart:1084-1089`)
and `_buildTitle`'s explicit `maxLines: 1` (`mx_content_shell.dart:254`).
A long Vietnamese deck name in the header form ellipsizes only the deepest step
(`mx_breadcrumb.dart:236-252`), which is the documented and correct behaviour.
**No finding** on long labels; the only exposure is P3-16's missing overflow
contract on the nav-bar label.

---

## 13 · Accessibility, keyboard and focus

| Surface | Semantics | Focus | Targets |
|---|---|---|---|
| `MxNavigationBar` | `SemanticsRole.tabBar` / `.tab` + `selected` from the SDK; labels always visible | InkWell per destination | 48+ (asserted, `mx_navigation_bar_test.dart:177`) |
| `AppBar` title | `namesRoute: true, header: true` on Android (`app_bar.dart:1069-1080`) | — | — |
| `AppBar` leading (implicit) | `MaterialLocalizations.backButtonTooltip` — **not the app's copy** (P2-14) | default | 48 via `iconButtonTheme.minimumSize` |
| `MxBreadcrumb` strip | steps announce as buttons; separators excluded; group label on the container | underline at `AppStroke.focus` (`mx_breadcrumb_step.dart:124-128`) | `lineHeight` floor on the strip |
| `MxBreadcrumb` header | one button; **separators and `…` announced** (P2-07); **long press unannounced** (P2-08) | **no focus handling**, theme overlay only (P3-18) | one wide target |
| `MxSessionTopBar` | contributes none by design; caller owns `trailing`; ✕ carries its own label | close button only | 48 (`mx_icon_button.dart` + `iconButtonTheme`) |
| `MxContentShell` | inherits the bar's; **no `namesRoute` on the two bar-less screens** (P3-19) | no explicit traversal group | — |

**No `Semantics` regression found in the navigation bar** — the SDK's roles
arrive intact through `MxNavigationBar`'s `Row`/`Flexible`/`ConstrainedBox`
wrapping, because all three are layout-only.

---

## 14 · Raw-usage and guard findings

### 14.1 The tree is clean

```
AppBar(         lib/shared/widgets/mx_content_shell.dart:217          (1)
NavigationBar(  lib/shared/widgets/mx_navigation_bar.dart:121         (1)
Scaffold(       lib/shared/widgets/mx_content_shell.dart:177          (2)
                lib/app/shell/app_navigation_shell.dart:33
SliverAppBar                                                          (0)
TabBar / TabBarView / TabController / DefaultTabController            (0)
BottomNavigationBar / NavigationRail / NavigationDrawer / BottomAppBar (0)
```

`SafeArea` appears 13 times, and every one is either the shell's, a sheet's, or
a documented exception — `mx_sheet_insets.dart:43-46` explains why the sheet
host has none, and `card_editor_action_bar_widget.dart:49` and
`card_import_action_bar_widget.dart:94-97` both explain why the footers have
none. That is a genuinely well-maintained boundary.

### 14.2 The guard cannot see three of those widget names — P2-16

`memox_v7.design_system.no_raw_widget`
(`…/projects/memox-v7/rules/memox-design-system-rules.yaml:63-86`) bans
`NavigationBar|NavigationDrawer|NavigationRail|BottomNavigationBar|BottomAppBar|TabBar`
in `presentation_files`. It does **not** ban `AppBar(`, `SliverAppBar(` or
`Scaffold(`.

The `memox` and `memox-v4` rulesets both did:
`…/projects/memox-v4/rules/memox-design-system-rules.yaml:54` is
`- \bAppBar\s*\(`. And both of those rulesets carry a whole
`memox-screen-shell` domain — `no_manual_page_gutter`,
`no_redundant_content_shell`, `use_mx_scaffold_family` — which `memox-v7`'s
rules directory does not contain at all:

```
code-verification-guard-v2/registries/projects/memox-v7/rules/
  memox-architecture-rules.yaml   memox-data-model-rules.yaml
  memox-design-system-rules.yaml  memox-design-token-rules.yaml
  memox-error-handling-rules.yaml memox-i18n-rules.yaml
  memox-naming-rules.yaml         memox-privacy-rules.yaml
  memox-state-management-rules.yaml memox-testing-rules.yaml
      ← no memox-screen-shell-rules.yaml
```

So today's clean result in §14.1 is a *property of the current code*, not
something the gate defends. A feature that writes its own `Scaffold` + `AppBar`
passes `flutter analyze`, the guard and the architecture boundary test.

- **Recommendation** — add `AppBar`, `SliverAppBar` and `Scaffold` to
  `no_raw_widget`'s patterns with the same line-anchored comment exemption the
  existing patterns use, scoped so `lib/shared/widgets/mx_content_shell.dart`
  and `lib/app/shell/app_navigation_shell.dart` are the two named exceptions.
  Porting the whole `memox-screen-shell` domain is a larger call and is listed
  as deferred.
- **Closure test** — the guard's own suite under
  `code-verification-guard-v2/tests/`: a fixture that writes
  `Scaffold(appBar: AppBar(...))` into a feature `presentation/` file and
  expects an error.

### 14.3 Component-level coverage

| Component | Unit test | Golden | Widgetbook | Stress |
|---|---|---|---|---|
| `MxNavigationBar` | `mx_navigation_bar_test.dart` (19 cases) | 4 PNGs | `control_components.dart:530` | yes |
| `MxBreadcrumb` | `mx_breadcrumb_test.dart` (26 cases) | — | `control_components.dart:485` | yes |
| `MxSessionTopBar` | **none of its own** | 2 PNGs | `feedback_components.dart:148` | yes |
| **`MxContentShell`** | **none of its own** | via screen goldens | `structure_components.dart:36` | yes |
| `AppNavigationShell` | 2 files, 20 cases | via screen goldens | n/a | n/a |
| `TabBarThemeData` | `app_planned_themes_test.dart` | n/a | n/a | n/a |

`MxContentShell` is used by 23 files 31 times (the Widgetbook coverage test
counts it, `widgetbook_coverage_test.dart:16-18`) and has **no unit test of its
own**. Four of this report's findings — P2-04, P2-10/P1-01, P2-12, P2-13 —
would each have been caught by one. That single missing file is the largest
verification gap in this area.

---

## 15 · Coverage gaps

| # | Gap | Consequence |
|---|---|---|
| G1 | No `test/shared/widgets/mx_content_shell_test.dart` | the shell's bar-null rule, hairline position, toolbar height and FAB clearance are unasserted |
| G2 | No `test/shared/widgets/mx_session_top_bar_test.dart` | the session bar has goldens and stress specimens but no behavioural test |
| G3 | Nothing pumps any chrome above 412 dp | P2-05 could not have been caught |
| G4 | 375 dp appears in no test | the most common phone width between the compact tier and the gallery is unexercised |
| G5 | No test asserts the deck list's *loading* or *error* face has an app bar | P1-01 shipped |
| G6 | No cross-screen test asserts the breadcrumb keeps one shape across `/decks/:id` → `/decks/:id/cards` | P1-02 shipped |
| G7 | No l10n test asserts every ARB key is referenced from `lib/` | P2-08's orphan string shipped in two locales |
| G8 | The guard's `memox-v7` ruleset has no `screen_shell` domain and does not ban `AppBar`/`Scaffold` | §14.2 |
| G9 | No test pins the app bar's resolved leading/action ink | P1-03 shipped |
| G10 | Nothing pins `_kMaxTitleTextScaleFactor` / `_kMaxLabelTextScaleFactor` as assumptions | an SDK bump changes the header's height budget silently |

---

## 16 · Severity registry

| ID | P | Finding | Primary file |
|---|---|---|---|
| **P1-01** | P1 | Nested deck level renders **no app bar** while loading and on error — no title, no back, 56 dp jump | `mx_content_shell.dart:213` · `deck_list_screen.dart:79` · `deck_level_error_widget.dart:45` |
| **P1-02** | P1 | Two incompatible breadcrumb / up grammars one tap apart | `deck_path_widget.dart:76` vs `card_breadcrumb_widget.dart:33` |
| **P1-03** | P1 | App-bar leading ink is `onSurfaceVariant` and action ink is `onSurface` — the **exact inverse** of M3 | `app_app_bar_theme.dart:15` · `app_icon_button_theme.dart:21` |
| **P2-04** | P2 | Scroll hairline drawn between bar and subheader, contradicting its own contract | `mx_content_shell.dart:235` |
| **P2-05** | P2 | Nav-bar width cap paints a two-tone band above 480 dp; the file's "same token" comment is stale | `mx_navigation_bar.dart:21,113` |
| **P2-06** | P2 | `TabBarThemeData` forces `indicatorSize: tab`, reshaping the M3 **primary** indicator | `app_tab_bar_theme.dart:25` |
| **P2-07** | P2 | Breadcrumb header form announces `/` and `…` | `mx_breadcrumb.dart:219,221,228` |
| **P2-08** | P2 | Long-press-to-ancestors is undiscoverable; `deckPathAncestorsHint` orphaned in both ARBs | `mx_breadcrumb.dart:191` · `app_en.arb:4280` |
| **P2-09** | P2 | App bar renders at `kToolbarHeight` 56, not M3's 64 — `_AppBarDefaultsM3.toolbarHeight` is never read | `app_app_bar_theme.dart` · `app_bar.dart:925` |
| **P2-10** | P2 | `MxContentShell` drops `leading` / `actions` when `title == null` | `mx_content_shell.dart:213` |
| **P2-11** | P2 | Shell owns no max content width; four screens re-derive `AppBreakpoints.medium` | `mx_content_shell.dart` · 6 call sites |
| **P2-12** | P2 | Shell owns the FAB slot but not its clearance; two private constants share a name | `mx_content_shell.dart:179` · `deck_list_sliver_widget.dart:26` |
| **P2-13** | P2 | `_toolbarHeight` uses the unclamped scaler against a title clamped at 1.34 → 34.5 dp dead slack at 2.0× | `mx_content_shell.dart:268` |
| **P2-14** | P2 | The implicit back affordance on 12 screens is a raw Material `BackButton` outside the design system and the ARBs | `mx_content_shell.dart:224` · `app_bar.dart:1014` |
| **P2-15** | P2 | Session and options screens are imperative `MaterialPageRoute`s — no URL, no deep link, no restoration | `study_entry_screen.dart:310,332` |
| **P2-16** | P2 | The `memox-v7` guard ruleset does not ban raw `AppBar` / `SliverAppBar` / `Scaffold` and has no `screen_shell` domain | `…/memox-v7/rules/memox-design-system-rules.yaml:78` |
| P3-15 | P3 | Nav-bar theme resolvers have no `disabled` branch | `app_navigation_bar_theme.dart:32,56` |
| P3-16 | P3 | `NavigationDestination` label has no `maxLines`/`overflow` | `navigation_bar.dart:512` |
| P3-17 | P3 | Breadcrumb fold hard-wires `- 3`; no `assert(collapseAfter >= 3)` | `mx_breadcrumb.dart:315` |
| P3-18 | P3 | Header form paints the theme's focus/hover overlay the strip form suppresses; no focus ring | `mx_breadcrumb.dart:189` |
| P3-19 | P3 | Session and 404 screens carry no `namesRoute` and no `SystemUiOverlayStyle` of their own | `study_session_screen.dart:162` · `route_not_found_screen.dart:31` |
| P3-20 | P3 | `viewPaddingOf(...).bottom` added on top of `fabScrollClearance` inside a branch that already paid it | `deck_list_sliver_widget.dart:79` |
| P3-21 | P3 | 375 dp untested; nothing pumps chrome above 412 dp | `test/` |
| P3-22 | P3 | `library_search_body_widget.dart:24` reuses the private name `_kListBottomInset` for a different number | that file |

**P0: none.** Nothing in the navigation chrome loses data, blocks the user
permanently, or violates a business rule outright. P1-01 comes closest — the
nested error face has no chrome-level exit — but the bottom bar and the system
gesture both still work.

---

## 17 · Implementation order

Ordered so that each step is independently shippable and no step invalidates
the next. **Steps 0 and 1 must not be reordered**: three later fixes are
cheaper on one side of the P1-02 decision.

| Step | Work | Depends on |
|---|---|---|
| **0** | **Owner decision on P1-02** — header form or strip form, app-wide | — |
| **1** | P1-01 + P2-10 — the shell builds a bar whenever it has anything to put in it; `DeckListScreen` supplies a neutral level title in its loading and error faces. Add `test/shared/widgets/mx_content_shell_test.dart` (closes G1 and carries the next three) | — |
| **2** | P1-03 — set `AppBarThemeData.actionsIconTheme` to `onSurfaceVariant` and give the leading slot `onSurface`; pin both in a theme test (closes G9) | — |
| **3** | P2-13 — clamp `_toolbarHeight`'s scaler to 1.34; pin `_kMaxTitleTextScaleFactor` as an assumption (closes G10) | 1 |
| **4** | P2-04 — move the hairline below the whole chrome block | 1 |
| **5** | P2-07 + P2-08 + P3-17 + P3-18 — the breadcrumb accessibility and consistency pass | 0 |
| **6** | P1-02 — collapse to one breadcrumb grammar, delete the losing path (closes G6) | 0, 5 |
| **7** | P2-05 — paint the nav band full width; correct the stale comment; add an ≥ 480 dp test (closes G3) | — |
| **8** | P2-11 + P2-12 — the shell takes over max width and FAB clearance; delete the six local caps; rename the colliding constant | 1 |
| **9** | P2-14 — the shell builds its own `MxIconButton` back affordance | 1, 6 |
| **10** | P2-06 — delete `indicatorSize` from the tab theme | — |
| **11** | P2-16 — extend the guard; add the ARB-orphan l10n test (closes G7, G8) | — |
| **12** | P2-09 — owner decision on 56 vs 64 dp, then one theme line and a full golden regeneration | 0–11 |
| **13** | P3 sweep; add 375 dp to the responsive surfaces (closes G4) | — |
| **later** | P2-15 — route the session and options screens through GoRouter | separate PR |

**Every one of steps 1–12 moves a committed golden.** Each PR must regenerate
under `TZ=UTC` on Linux and republish
`build/screen_gallery.html` to the existing artifact URL, per `CLAUDE.md`.
Step 12 moves every screen at once and should be its own PR.

---

## 18 · Likely files

**Shared components**
```
lib/shared/widgets/mx_content_shell.dart        steps 1, 3, 4, 8, 9
lib/shared/widgets/mx_navigation_bar.dart       step 7
lib/shared/widgets/mx_breadcrumb.dart           steps 5, 6
lib/shared/widgets/mx_breadcrumb_step.dart      step 6
```

**Theme**
```
lib/core/theme/components/navigation/app_app_bar_theme.dart          steps 2, 12
lib/core/theme/components/navigation/app_tab_bar_theme.dart          step 10
lib/core/theme/components/navigation/app_navigation_bar_theme.dart   P3-15
```

**Features and app**
```
lib/features/deck/presentation/screens/deck_list_screen.dart                       step 1
lib/features/deck/presentation/widgets/sections/deck_level_error_widget.dart       step 1
lib/features/deck/presentation/widgets/sections/deck_path_widget.dart              steps 5, 6
lib/features/deck/presentation/widgets/sections/deck_subheader_widget.dart         step 6
lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart       step 8, P3-20
lib/features/card/presentation/widgets/sections/card_breadcrumb_widget.dart        step 6
lib/features/card/presentation/widgets/sections/card_editor_context_widget.dart    step 6
lib/features/card/presentation/widgets/sections/card_import_context_widget.dart    step 6
lib/features/card/presentation/screens/{card_detail,card_import,tag_catalog}_screen.dart   step 8
lib/features/study/presentation/widgets/sections/study_home_body_section_widget.dart       step 8
lib/features/search/presentation/widgets/sections/library_search_body_widget.dart          P3-22
lib/app/router/app_router.dart · lib/app/shell/app_navigation_shell.dart                   step later
lib/l10n/app_en.arb · lib/l10n/app_vi.arb                                                  steps 5, 9
```

**Tests, catalogue and gate**
```
test/shared/widgets/mx_content_shell_test.dart          NEW — step 1
test/shared/widgets/mx_session_top_bar_test.dart        NEW — G2
test/shared/widgets/mx_navigation_bar_test.dart         step 7
test/shared/widgets/mx_breadcrumb_test.dart             steps 5, 6
test/core/theme/components/app_planned_themes_test.dart step 10
test/l10n/localization_test.dart                        step 11 (ARB orphan check)
test/shared/widgets/mx_responsive_test.dart             steps 8, 13
widgetbook/lib/components/structure_components.dart     steps 1, 4, 8
code-verification-guard-v2/registries/projects/memox-v7/rules/memox-design-system-rules.yaml   step 11
docs/wbs.md                                             every step
```

---

## 19 · Owner decisions and deferred items

**Decisions this audit cannot take**

| # | Question | Why it is the owner's |
|---|---|---|
| D1 | **P1-02** — header form or strip form, app-wide? | Both were settled by owner reviews (2026-08-20 and 2026-08-21) that pull in opposite directions; the choice trades ~16 dp of header on the busiest screen against full text scaling and per-step targets |
| D2 | **P2-09** — move the app bar from 56 to M3's 64 dp? | Canonical identity says 64; it moves every screen and every golden in the project, and the current 56 is Flutter's own fall-through rather than a mistake anyone made |
| D3 | **P2-05 / P2-11** — is a tablet or an unfolded foldable a supported surface? | `AppBreakpoints` says the project ships no large-screen layout; Play ships to tablets anyway. The answer decides whether P2-05 is a bug or a letterbox |
| D4 | **P2-08** — visible hint, visible chevron, or delete the long press and its two ARB entries? | Three different amounts of header width |
| D5 | **P2-14** — does `MxContentShell` gain a `backSemanticLabel` parameter, or does each screen pass its own leading? | Shapes the shell's public API, which AD-23 treats as a closed set |

**Deferred, and deliberately out of scope for the chrome pass**

- **P2-15** — routing the session and options screens through GoRouter. Real
  benefit (URL, deep link, restoration), real blast radius (BR-82, BR-200,
  IT-NAV-008/009/010, the resume contract). It is a routing PR, not a chrome
  PR.
- Porting the whole `memox-screen-shell` guard domain from the `memox-v4`
  ruleset. Step 11 adds the three missing widget names, which is the cheap 80 %;
  the gutter and nested-shell rules need their scopes rewritten for this tree.
- A `SliverAppBar` / collapsing-header treatment. Nothing in the app uses one
  and nothing needs one; noted only so the next reader knows it was considered.
- **A7 icon-button styling was not re-audited.** P1-03 and P2-14 touch icon
  buttons only where the *navigation slot* decides the outcome — the app bar's
  leading-versus-actions fall-through, and the implicitly-constructed
  `BackButton`. Everything else about `MxIconButton` is A7's.

---

## 20 · Verification status of this commit

| Check | Status |
|---|---|
| Files changed | exactly one — `docs/reviews/a8-navigation-chrome-audit.md` |
| Production code | untouched |
| Tests / goldens / Widgetbook / CI / guard | untouched |
| `dart format` · `flutter analyze` · `flutter test` | **not run** — no Flutter SDK in this container, and this commit changes no Dart |
| Framework claims | read from `flutter/flutter@3.44.8` source, cited by file and line |
| App claims | read from the working tree at `3207e7b7`, cited by file and line |
| Rendered measurements | **none** — every figure is a source constant or arithmetic over source constants, and the report says which |
