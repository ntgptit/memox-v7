# Design parity checklist — `design_system/` (CSS/JSX) ↔ `lib/` (Dart)

Since M4.10p the design system is authoritative for token **values**; this file
widens that to everything else the design encodes — theme data, shared widgets,
how tokens are used, corner radii, states, layout. It exists so the review is
**file-by-file rather than impression-by-impression**: every artefact on the
design side appears exactly once below, paired with what it maps to in `lib/`.

**Status key.** `[x]` reviewed 1:1, verdict recorded · `[ ]` not yet reviewed.

**A verdict opens with exactly one of six words, in bold**, and prose after it:

| Verdict | Means | Counts against the gate? |
|---|---|---|
| **match** | nothing to do | no |
| **resolved** | there was a difference; Dart has moved to the design | no |
| **divergence** | the two differ on purpose, measured, and the reason is in the divergence table below | no |
| **design-gap** | the design is missing something the app needs | no |
| **blocked** | needs a decision, a BR, or a feature that does not exist yet | no |
| **drift** | a real difference, still open | **yes** |
| **n/a** | there is nothing on one side to compare | no |

The vocabulary is closed because it is **executable**:
`test/design_audit/design_parity_gate_test.dart` parses every row and fails when
open **drift** exceeds 3% of the reviewed rows, when a row is unreviewed, or when
a verdict opens with a word not on this list. That is the shape M4.12's "design
parity below 3%" takes here — see the note under the gate table for why it is not
a pixel comparison.

**What the gate cannot see.** It reads this file, so it is only as current as the
review that wrote it. It caught nothing when nine rows sat at **drift** for three
milestones after the code had already moved; a re-verification in M4.12d found
seven of the nine closed and two closed by widgets written since. The gate stops a
*known* difference being forgotten. It does not stop *this file* going stale — only
re-reading `lib/` against `design_system/` does that, and the row's prose says
which file to open.

**Scope note.** `design_system/` files that carry no rule are excluded and listed
at the bottom, so their absence here is deliberate rather than an oversight.

---

## A · Tokens — `design_system/tokens/*.css`

| # | Design source | Flutter target | Compare | Status | Verdict |
|---|---|---|---|---|---|
| A1 | `colors.css` (light scope) | `app_colors.dart` | every `--color-*` hex | [x] | **resolved** — M4.10p: 11 of 40 taken from CSS |
| A2 | `colors.css` (`[data-theme=dark]`) | `app_colors.dart` | every dark override | [x] | **resolved** — same as A1 |
| A3 | `colors.css` progress + streak families | `app_semantic_colors.dart` | 5 tokens with no Dart counterpart | [x] | **blocked** — the progress family resolved M4.10r — `MxProgressBar` is the caller. Streak still blocked: no feature, and a fifth hue |
| A4 | `typography.css` sizes + leading | `app_typography.dart` | 15 M3 styles, measured off the built `TextTheme` | [x] | **match** (see §A-detail) |
| A5 | `typography.css` tracking | same | `--tracking-*` | [x] | **match** |
| A6 | `typography.css` weights | same | which style gets which `--weight-*` | [x] | **match** — 400/500/600/700 land on the same styles |
| A7 | `typography.css` `--tracking-section-label` 1.1px | `SectionLabel` (`preview_harness.dart`) | section-label treatment | [x] | **match**, and tokenised — the 1.1 was a literal at the call site; now `AppTypography.sectionLabelTracking` |
| A8 | `fonts.css` | `pubspec.yaml`, `app_typography.dart` | families, axes, bundling | [x] | **match** — both variable, both bundled |
| A9 | `spacing.css` | `app_spacing.dart` | 6 steps + 48 floor | [x] | **match** |
| A10 | `spacing.css` `--icon-*` | `app_icon_size.dart` | 16 / 24 / 40 | [x] | **match** |
| A11 | `radius.css` | `app_radius.dart` | 8 / 12 / 16 / 999 | [x] | **match** |
| A12 | `elevation.css` levels | `app_elevation.dart` | 0 / 1 / 3 / 8 | [x] | **match** |
| A13 | `elevation.css` shadows | `shadowsFor()` | the three shadow recipes, and dark = none | [x] | **match** — `shadowsFor` *derives* all three: alpha `0.06+0.01*level`, blur `3*level`, offset `(0,level)` reproduce the CSS exactly at 1/3/8 |
| A14 | `elevation.css` borders | `app_theme.dart`, `mx_text_field.dart` | hairline 1 / input 1.5 / focus 2 | [x] | **match** — hairline 1, input 1.5, focus ring 2 |
| A15 | `motion.css` | `app_durations.dart` | 120 / 200 / 320 | [x] | **match** |
| A16 | `motion.css` easing | — | `--ease-standard`, `--ease-decelerate` | [x] | **resolved** — Dart had no curve token and `Curves.decelerate` is `(0,0,0.2,1)`, not the design's `(0,0,0,1)` |
| A17 | `layout.css` breakpoints | `app_breakpoints.dart` | 360 / 600 | [x] | **match** |
| A18 | `layout.css` `--nav-width-per-destination` | `mx_navigation_bar.dart` | 120 | [x] | **match** — 120 |
| A19 | `layout.css` `--frame-*` | `web/` letterbox | preview frame only | [x] | **n/a** — the preview frame has no Flutter counterpart and needs none |

### A-detail · typography, measured

Read off the built `TextTheme` through a `BuildContext`, not from source — the
source only overrides family, weight and two specifics, and the rest comes from
Material's own scale at render time.

| Style | CSS size / leading / tracking | Flutter (measured) |
|---|---|---|
| display-lg | 57 / 64px / — | 57 / 1.12 / −0.25 |
| display-md | 45 / 52px | 45 / 1.16 / 0 |
| display-sm | 36 / 44px | 36 / 1.22 / 0 |
| headline-lg | 32 / 40px | 32 / 1.25 / 0 |
| **card prompt** | **30 / 1.22 / −0.5** | **30 / 1.22 / −0.5** |
| headline-sm | 24 / 32px | 24 / 1.33 / 0 |
| title-lg | 22 / 28px | 22 / 1.27 / 0 |
| title-md | 16 / 24px / 0.15 | 16 / 1.5 / 0.15 |
| title-sm | 14 / 20px / 0.1 | 14 / 1.43 / 0.1 |
| body-lg | 16 / 24px / 0.5 | 16 / 1.5 / 0.5 |
| **body-md** | **14 / 1.45 / 0.25** | **14 / 1.45 / 0.25** |
| body-sm | 12 / 16px / 0.4 | 12 / 1.33 / 0.4 |
| label-lg | 14 / 20px / 0.1 | 14 / 1.43 / 0.1 |
| label-md | 12 / 16px / 0.5 | 12 / 1.33 / 0.5 |
| label-sm | 11 / 16px / 0.5 | 11 / 1.45 / 0.5 |

Leading is expressed in px on the CSS side and as a multiplier in Dart; every
pair agrees to within a rounding step. Both deliberate overrides — the card
prompt and body-md's 1.45 — are identical on both sides.

---

## B · Theme data — how tokens become a rendered widget

| # | Design source | Flutter target | Compare | Status | Verdict |
|---|---|---|---|---|---|
| B1 | `mx.css` `.mx-btn--primary/--secondary/--destructive` | `app_button_themes.dart` | fill, label colour, border, radius, min height | [x] | **match** - 12/24 padding, radius 12, 64x48 floor, 12% press lerp, all identical |
| B2 | `mx.css` `:hover` / `:active` on buttons | `app_button_themes.dart` overlays | 4% / 6% / 10% / 12% state layers | [x] | **resolved** (F1) — hover was unspecified and fell through to Material's wash of the *foreground* colour, so a filled button had no visible hover at all. Every button theme now declares disabled, pressed, hovered and focused explicitly, and hover blends toward the ink as `.mx-btn--primary:hover` does |
| B3 | `mx.css` `:disabled` | `disabledSurfaceTint()` | precomputed solid vs alpha | [x] | **match** - fill + 38% label + transparent secondary all agree |
| B4 | `mx.css` `.mx-pill` | `app_chip_theme.dart` | fill, selected pair, border, 48 target | [x] | **match** - every property and no checkmark. Padding was 8/16 in both; **both moved to 8/8 together (2026-08-06)** - 16 across put 21px of chrome each side of a label as short as "All 1", 42 of a 69.5px pill, and the card list's four filter pills ran to 426.4 against the 374 a 390-wide screen leaves. 8 across is Material's own M3 chip padding, 17 a side, row 394.4 - and dropping "now" from the Due label took it to 361.8, so single-digit counts fit at 390 without scrolling. Three-digit counts (416.5) and 360-wide screens still scroll, which is what the row scrolls for. **Label weight moved 600 → 500 on both sides together (2026-08-06, M4.11e)** - semibold is the *button's* weight, raised from Material's 500 for a label reversed out of a solid fill, and the pill took it only by sharing the `label-lg` rung. Measured on a device render at 360dp: the pill labels covered 0.340 and 0.364 of their glyph box against the search hint's 0.271 at an identical 27px ascender, putting two toggles above every heading on the screen and just under the deck name (0.409). 500 is Material's own chip weight and `--weight-medium` here, so this rejoins a spec rather than inventing a value. **Sizing standardised on both sides together (2026-08-06)**: container 32 (M3's chip height, painted 34 with the two hairlines), touch target 48, icon 16, corner radius kept `--radius-pill` after rounding to `--radius-sm` was rendered and rejected by the owner, padding 12 across, and `labelPadding` **zeroed** - Material's default 8-both-sides landed entirely on the trailing edge of a chip with an avatar, which is why the toolbar pills measured 11 left against 17 right. With it gone, 12 means 12 and a no-icon chip is 13/13 including its hairline. The card list's four filter pills came out 8 NARROWER each, so that row now measures 354 against 374 visible at 390 - it fits with three-digit counts, where it needed scrolling before. **`MxPillButton` alone drops one rung to `label-md` with a 4px icon gap**, mirrored by `.mx-pill__body`: those two sit in a deck list beside the Study button on every row, and that button is `label-md` with a 4px gap. The filter pills keep `label-lg` from the theme - Only the metrics are taken from the rung; the colour stays the theme's `WidgetStateColor`, because copying a rung whole replaces it with a flat colour and takes the disabled and selected states with it. **The card list's filter row moved onto `MxPillButton` too (2026-08-06)**, so every pill in the app is now one component: it was the last place building a chip by hand, which is why its Flagged label had to open with `⚑` U+2691 — a character no bundled font carries, so both shipped goldens rendered a tofu box while a device with a wider system font might draw a flag. It is `Icons.flag` now, the same glyph the card row beside it uses |
| B5 | `mx.css` `.mx-field*` | `app_theme.dart` `inputDecorationTheme` | 1.5px stroke, radius, focus = hue not width, error | [x] | **match** - unfilled, 12/16 padding, hue-only focus |
| B6 | `mx.css` `.mx-nav` | `app_theme.dart` `navigationBarTheme`, `mx_navigation_bar.dart` | page-colour fill, hairline, indicator pair | [x] | **divergence** — page fill and elevation 0 match. **F2 resolved:** the top hairline is drawn, in `MxNavigationBar` rather than the theme because `NavigationBarThemeData` has no border slot, and as a *foreground* decoration because `NavigationBar` paints its own fill over a background one. **F3 stands, deliberately** — see divergence #2 |
| B7 | `mx.css` `.mx-scrim` (60%) | `modalBarrierColor()` | barrier opacity per mode | [x] | **divergence** (F16) — design 60% flat, Dart 48% light / 72% dark, measured. See divergence #4 |
| B8 | `mx.css` `.mx-dialog` / `.mx-sheet` | `app_theme.dart` dialog + sheet themes | radius, surface, shadow | [x] | **drift** (F15) — sheet matches entirely; radius, surface and the hairline match on the dialog too, but `.mx-dialog` carries `--shadow-overlay` and `dialogTheme` is `elevation: 0`. **The comment in `app_theme.dart` cites AD-14 to justify the zero, and AD-14 §4 says the opposite**: depth is a measured target each mode builds from what it has, and light builds it with a shadow. Dark is correct as it stands — `shadowsFor` is none there. Open: a dialog on a light page, which is where the shadow would show. Costed as an M4.12 follow-up rather than taken here, because it moves every dialog golden and those want a render review first |
| B9 | `mx.css` `.mx-spinner` | `buildProgressIndicatorTheme()` | colour source | [x] | **resolved** (F14) — the slot is declared at `focusRing` rather than left to Material's `primary`, which measured **2.81:1** on the dark surface it spins on, under the 3.0 a graphic needs; `focusRing` is the same hue at 5.36:1 dark / 7.41:1 light. The track is explicitly transparent so no second ring appears |
| B10 | `readme.md` "States" | `app_theme.dart` overlays | hover 8/6/4, press 12, focus 2px ring | [x] | **match** since M4.10q — hover 6%, press 12%, focus ring 2px |
| B11 | `readme.md` "Layout rules" | `app_theme.dart` appBar + `MxContentShell` | no elevation, no scroll tint, page-colour bar | [x] | **resolved** (F4, F11) — page colour and zero elevation match. **F4:** the scroll hairline is drawn, derived from scroll position in `MxContentShell` (`_hasScrolled`, a 2px threshold so a resting screen cannot flicker) and set as the `AppBar.shape` bottom border — below the whole chrome block, subheader included, exactly as `.mx-shell__bar--divided` swaps its `border-bottom` colour. It is a 1px line, not `scrolledUnderElevation`, which stays off so the header never shifts colour under a review card. **F11 is obsolete:** M4.10ag removed the FAB, and M4.10aq removed the theme that outlived it |
| B12 | — | `app_overlay_themes.dart` tooltip, selection, divider, scrollbar | design has no counterpart | [x] | **design-gap** — as expected: — tooltip, text selection, divider and scrollbar have no CSS counterpart; the design leaves them to the browser as Flutter left them to Material until M4.10j |
| B13 | `index.html` `COMPACT_BELOW` behaviour | `app_compact_scale.dart` | title 22→20, prompt 30→26, button padding | [x] | **match** — title 22→20, card prompt 30→26, button padding 24→12, same 360 breakpoint. The compact pass deliberately skips the text button: a zero-padding link has nothing to give back |
| B14 | `mx.css` `.mx-textbtn` (+ `--destructive`) | `buildTextButtonTheme()` in `app_button_themes.dart` | zero padding, 48 floor as height, 15%/28% hover/press label blends, underline on hover/focus | [x] | **match** since M4.10aq — the values always matched but lived inline in `MxTextButton`; the slot owns them now, the blends are `AppStateOpacity.textHoverBlend`/`textPressedBlend`, and the underline stays on the label because a decoration on the shared style reaches the icon glyphs |
| B15 | — | `app_radio_theme.dart` | design has no counterpart | [x] | **design-gap** — as B12: — no kit mock renders a scheduler picker, so the radio takes the app's own conventions: `primaryAccent` mark (a glyph, and `primary` misses 3:1 on the dark card), secondary-ink resting ring, the shared control overlay |

---

## C · Shared widgets — 18 design components ↔ 15 Dart

Each row compares the `.jsx` **and** its `.prompt.md` and `.d.ts` against the
Dart widget: props, defaults, states, radius, spacing, semantics.

| # | Design component | Flutter | Status | Verdict |
|---|---|---|---|---|
| C1 | `MxActionButton` | `mx_action_button.dart` | [x] | **match** - `isBlock`/`isCompact`/`isDisabled` are expressed idiomatically (caller width, global compact scale, null callback). **M99.21a:** `shouldKeepLabelWhileLoading` landed on both sides in one change. Both kits had hidden the loading label — `.mx-btn--loading .mx-btn__label{opacity:0}` and Flutter's `Opacity(opacity: 0)` — which answers a screen reader and nobody else; M4.13 W6 needs `Exporting…` to be readable text. The opt-in defaults off, so every existing caller keeps the fixed-width behaviour, and the two agree on the same two mechanics: spinner moves to the leading slot, leading icon is dropped for that frame |
| C2 | `MxIconButton` | `mx_icon_button.dart` | [x] | **match** - radius 12, 48 square, `onSurfaceVariant`; `filled` is expressed by which `IconData` the caller passes |
| C3 | `MxPillButton` | `mx_pill_button.dart` | [x] | **match** - props one-for-one, 48 target via `MaterialTapTargetSize.padded` |
| C4 | `MxCard` | `mx_card.dart` | [x] | **match** - radius 16, hairline, `--shadow-card` default, `--space-lg` padding. **M4.10ak:** both clip their content (`overflow:hidden` / `ClipRRect`), so a child seated on an edge is cut by the card's real corner rather than by its own box. **M4.10ac:** a clickable card no longer *becomes* a button on either side, so it may hold controls — web lays the target under the content (`.mx-card__action` / `.mx-card__control`, `actionLabel`), Flutter lets the nested button win the arena. Same guarantee, two mechanisms, because HTML forbids what Flutter merely arbitrates |
| C5 | `MxTextField` | `mx_text_field.dart` | [x] | **match** — unfilled, 1.5 stroke, hue-only focus, error shows a message and not colour alone. `onSurface` is web-only: Flutter's outline gaps for the label, so there is no backing to match |
| C6 | `MxListTile` | `mx_list_tile.dart` | [x] | **match** - radius 12, selected fill `surfaceMuted` + primary title, 2-line clamp both sides |
| C7 | `MxIcon` | — (Flutter uses `Icons.*`) | [x] | **n/a** — Flutter reaches `Icons.*` directly; the wrapper exists because the web has no bundled set |
| C8 | `MxProgressBar` | `mx_progress_bar.dart` | [x] | **resolved** — built M4.10r, BR-88 unblocked it. **M4.10ak:** `sm` track 4 → 6 on both sides, and both gain a `pill`/`flush` shape. `flush` is for a bar used as an *edge*: the container clips it, because a radius set on the bar is clamped to the bar's own height and rounds the wrong shape |
| C9 | `MxEmptyState` | `mx_empty_state.dart` | [x] | **match** - 40px primary glyph, 24 padding, 16/8 rhythm, `check_circle_outline` default |
| C10 | `MxErrorState` | `mx_error_state.dart` | [x] | **divergence** — repo wins: retry is primary. The design's note is prose, and M4.10n changed it so `MxErrorState` and `MxEmptyState` stop looking like two components. `isRetrying` landed on **both** sides at M99.23 (stage 1 of the #301–#310 integration): re-reading the same source is a refresh, a refresh repaints the same error face, so without it a press produced nothing on screen. A first attempt recorded it as Flutter-only on the grounds that the web's retry is a form submit the browser narrates — `MxErrorState.jsx` renders a plain `<button>` and the kit contains no `<form>` at all, so that reason was false and the prop was simply missing. The design's note is prose, and M4.10n changed it so `MxErrorState` and `MxEmptyState` stop looking like two components |
| C11 | `MxLoadingState` | `mx_loading_state.dart` | [x] | **resolved** (F14) — the explicit `color:` is gone, so the widget takes `progressIndicatorTheme` like every other spinner instead of overriding the slot that exists to keep it off `primary`. See B9 |
| C12 | `MxAsyncView` | `mx_async_view.dart` | [x] | **divergence** — repo wins, and the kit has nothing to mirror. `error` is required on both sides, so no screen can inherit a generic failure sentence; what only Flutter has is `shouldSkipLoadingOnReload`. Riverpod distinguishes a *reload* (a dependency changed) from a *refresh* (something asked again) and the React kit has no such distinction to expose, so mirroring the prop would add a flag with no meaning on that side. It exists because Progress is the first screen whose dependency is the instant its windows are measured against — that moves on every app resume without the user's question changing — and the default `false` stays right for every other screen (M99.23, stage 1 of the #301–#310 integration) |
| C13 | `MxConfirmDialog` | `mx_confirm_dialog.dart` | [x] | **match** — `shouldAutofocus: _isDestructive` puts initial focus on Cancel |
| C14 | `MxActionSheet` | `mx_action_sheet.dart` | [x] | **match** — `!isEnabled` is tested first, so disabled beats destructive |
| C15 | `MxNavigationBar` | `mx_navigation_bar.dart` | [x] | **match** — `selectedIcon` carries the filled twin, labels always shown |
| C16 | `MxBreadcrumb` | `mx_breadcrumb.dart` | [x] | **resolved** (F5–F8) — all four closed at M4.10q. **F5:** the middle folds above `collapseAfter` (default 4: first step, fold, last two) and the fold opens. **F6:** `rootIcon` exists and lands on the first step. **F7:** the label is `labelMedium`, the `--text-label-md` `.mx-crumbs__step` sets. **F8:** a link rests at `onSurfaceVariant` and travels to `onSurface` on hover, mirroring `text-secondary` → `text-primary`; weight separates link from current, so the path no longer competes with the app-bar title. F12 (36 vs 48 tall) stands as divergence #3 |
| C17 | `MxSearchField` | `mx_search_field.dart` | [x] | **resolved** — built M4.10x |
| C18 | `MxContentShell` | `mx_content_shell.dart` | [x] | **resolved** (F9, F10) — gutters always matched; both slots exist now. **F9:** `subheader` is pinned between the bar and the scrolling body, and sits above the `Expanded` rather than in `AppBar.bottom` because that slot demands a height up front and this strip's height follows the user's text scale. **F10:** `leading` is a slot, so a screen chooses its own back affordance and `AppBar` keeps its automatic one when the slot is null |

---

## D · Screens and feature widgets

| # | Design source | Flutter target | Status | Verdict |
|---|---|---|---|---|
| D1 | `DeckLevelScreen.jsx` shell + subheader | `deck_list_screen.dart` | [x] | **resolved** — M4.10q: `subheader` holds the path |
| D2 | `DeckLevelScreen.jsx` `DeckCard` | `deck_tile_widget.dart` | [x] | **resolved** — rebuilt M4.10s: — flat card, due chip, three foot states. Study pill deliberately absent: no session to start until M5. **M4.10ac:** the whole card is the target on both sides. **M4.10ak — deliberate divergences, app wins, kit updated to follow:** the Study pill was *filled* where the kit argued for outlined — the kit's reason (a column of filled buttons stops the card being calm) was weighed and the project owner chose emphasis; **revised 2026-08-05, owner-approved: the pill is now *tonal* (`secondaryContainer`) on both sides** — the measured UI review showed several due decks spraying the primary accent down the column, and tonal keeps the emphasis that beat outlined while leaving `primary` to screen-level actions; the progress track is the card's *base* rather than a rule across its middle; the row menu sits with the deck's identity in the head band rather than in the kit's foot, so the foot carries only the two verbs (due state, and Study when it lands) and is 32 tall rather than 48. The chevron is dropped: it said "this opens onto another level", which the whole card now says by being the target, and beside a real control it read as a second one that did nothing |
| D3 | `DeckLevelScreen.jsx` filter/sort row | `deck_list_toolbar_widget.dart` | [x] | **resolved** — the design heads the list "Your decks"/"Sub-decks" beside the pills; there was nothing saying what the pills filtered |
| D4 | `DeckLevelScreen.jsx` breadcrumb use | `deck_path_widget.dart` | [x] | **resolved** — M4.10q: fold, root icon, quiet weight. **M4.10ae:** the strip now runs the whole way on both sides — the deck list, every ancestor, then the deck you are in as a non-tappable last step. The kit already carried the list as its first step; what it gained is the last one |
| D5 | `DeckLevelScreen.jsx` `LevelEmpty` (three empties) | `deck_list_screen.dart` empty states | [x] | **match** — five empty states, more than the design's three: `card`-typed decks and a failed read are cases the kit has no fixture for |
| D6 | `DeckLevelScreen.jsx` `LevelSummary` | `deck_level_summary_widget.dart` | [x] | **resolved** — built M4.10t, dismiss added M4.10y. **M4.10ad:** it no longer auto-opens on a level with nothing due — `auto` / `shown` / `hidden` on both sides, the kit's `summaryChoice` mirroring `DeckSummaryVisibility`. Only the streak chip and Start studying remain, and both need M5 |
| D7 | `DeckLevelScreen.jsx` `SearchResults` | `deck_search_results_widget.dart` | [x] | **resolved** — built M4.10x, in memory over `watchAllDecks()`, so no new query and no contract change after all. Result rows carry the path but not the counts: those need a per-row subtree aggregate |
| D8 | `DeckForms.jsx` | `deck_form_widget.dart` | [x] | **match** — one form for create-root, create-sub and rename |
| D9 | `DeckForms.jsx` `SchedulerChoice` | `deck_form_widget.dart` radio rows | [x] | **match** — radio rows, `SchedulerType?` null until chosen, so nothing is preselected (BR-11) |
| D10 | `index.html` action sheet wiring | `deck_actions_widget.dart` | [x] | **match** — same four actions, reset disabled rather than hidden |
| D11 | `index.html` destructive confirm | `deck_confirm_widget.dart` | [x] | **match** — destructive confirm names the counts |
| D12 | `index.html` `MxNavigationBar` mount | `app_navigation_shell.dart` | [x] | **match** — two destinations; the kit's third is its "You" tab, which is M5 territory |
| D13 | `ReviewScreen.jsx` | `review_screen_preview_test.dart` harness | [x] | **blocked** — `VerdictAction` ground fixed M4.10p. The rest is a preview harness, not a screen: the review slice is M5 |
| D14 | `ProfileScreen.jsx` | `settings_screen.dart` | [x] | **divergence** — Settings là màn thật từ M99.28 (stage 5 của đợt tích hợp #301–#310), nên hàng này nay đối chiếu với màn thật. `test/design_preview/settings_preview_test.dart` vẫn còn — nó đo mật độ palette, không phải mock màn hình. Kit web có `ProfileScreen` cho một app có auth; màn này không có auth (AD-03) nên nó là **ba nhóm tuỳ chọn**: mặc định học toàn cục, theme, ngôn ngữ. Không có gì để mang sang từ kit cho tới khi profile tồn tại. Dùng chung: `MxCard`, `MxContentShell`, `MxConfirmDialog` (C-series), `MxTextField`, `RadioListTile` qua `app_radio_theme`. Phân kỳ có chủ ý ghi ở `docs/wbs.md` M99.28 (S9a: radio thay pill cho ba lựa chọn loại trừ nhau) |
| D15 | — | `deck_labels_widget.dart`, `deck_level_error_widget.dart`, `move_deck_sheet_widget.dart` | [x] | **n/a** — no design counterpart, and none needed — deck labels, level error and the move sheet are this app's own |
| D16 | — | `progress_screen.dart`, `progress_deck_screen.dart` | [x] | **n/a** — the kit has no Progress screen at all, so there is nothing to compare. Recorded rather than left out: the two screens landed with M99.23/M99.24 (stages 1–2 of the #301–#310 integration) and an absent row reads the same as an unreviewed one. What they reuse is already in scope elsewhere — `MxCard`, `MxContentShell`, `MxPillButton`, `MxAsyncView` (C12), `MxErrorState` (C10) |
| D17 | — | `progress_summary_widget.dart`, `progress_week_widget.dart` | [x] | **resolved** — M99.26: hai tiêu đề card cạnh nhau từng dùng hai type role cho cùng một vai (`labelLarge` cho ba section tổng quan, `titleSmall` cho bảng tổng). Đo từ `app_typography.dart`: hai role **giống hệt nhau hôm nay** — Inter w600 14/20, tracking 0.1 — nên không có seam nhìn thấy, và đó chính là lý do sửa ngay thay vì đợi: ngày một trong hai được chỉnh, hai tiêu đề cạnh nhau trên một màn sẽ đổi rời nhau. Bảng tổng nay dùng `labelLarge` như ba anh em của nó. Xem thêm D18–D21 |
| D18 | — | `study_home_body_section_widget.dart`, `deck_list_toolbar_widget.dart` | [x] | **resolved** — M99.26: một treatment duy nhất cho tiêu đề danh sách. Study Home dùng `titleMedium` ở `onSurface` đầy đủ, đọc to hơn mọi tiêu đề danh sách khác trong app; nay theo đúng cái A7 đã chốt và deck toolbar đang dùng — `labelMedium` + `AppTypography.sectionLabelTracking` + `onSurfaceVariant` + viết hoa |
| D19 | — | `mx_metric_well.dart` | [x] | **resolved** — M99.26: "well" của ô metric đã tồn tại **hai bản sao private y hệt nhau** (deck summary và Progress), và màn thứ ba sắp làm không có nó. Nâng thành `MxMetricWell` dùng chung; `wellColor` là tham số vì deck đổi nó theo trạng thái còn Progress giữ trung tính, cái không được đổi là **hình dạng**. Study Home cũng tách chữ số / chữ: chữ số giữ `onSurface`, chỉ chữ nhận tint — trước đó tô cả hai, khiến ba con số cạnh nhau đọc như ba loại số khác nhau |
| D20 | — | `progress_*_widget.dart` | [x] | **resolved** — M99.26: card trong cột cuộn để phẳng. Deck tile và hàng Study Home đã `AppElevation.none` với lý do "hai độ sâu cạnh tranh trong một cột làm danh sách đọc rối"; năm card của Progress là chỗ duy nhất còn lấy mặc định `AppElevation.card`. **Cái giá, đã đo:** không còn shadow thì cách duy nhất tách card khỏi nền trang là hairline `borderSubtle` — `surface` so với `scaffoldBackgroundColor` chỉ **1,06:1** (light) và **1,14:1** (dark), còn hairline so với nền trang là **1,38:1** (light) và **2,32:1** (dark). Light dưới ngưỡng 3:1 mà WCAG 1.4.11 đòi cho ranh giới thành phần. Đây **không phải** vấn đề do quyết định này tạo ra — deck tile và hàng Study Home đã ở đúng những con số đó từ trước, và D20 chính là chọn khớp với chúng; ghi lại vì trước đây chưa ở đâu ghi, và vì `app_elevation.dart` vẫn nói về một độ nâng ΔL* 8,04 mà nay không card nào trong danh sách còn có |
| D21 | — | `progress_deck_list_widget.dart`, `study_home_body_section_widget.dart`, `deck_level_body_widget.dart` | [x] | **resolved** — M99.26: khoảng dưới hàng cuối là `AppSpacing.lg` ở cả ba danh sách. Trước là 32 / 16 / gutter, và cả ba đều viện đúng một lý do — danh sách kết thúc sát navigation bar đọc như bị cắt |
| D22 | `settings_reminder_entry_section_widget.dart` | `settings_screen.dart` | [x] | **resolved** — M99.29: nhánh Settings có hàng vào `/settings/reminders` (wireframe M6 W1). Hàng **chỉ nhãn + chevron, không hiện trạng thái**: hiện `Off`/giờ ở đây buộc `features/settings/presentation/` theo dõi state của `features/reminder/` — đúng cross-feature import mà M6 R1 và guard chặn. Đặt sau nhóm Ngôn ngữ và trước Reset: Reset là hành động phá huỷ nên luôn đứng cuối. **Không có section heading**, khác ba nhóm bên trên: heading tồn tại để nói một cụm lựa chọn là *cái gì* — `System`/`Light`/`Dark` tự nó không nói — còn nhãn của hàng này đã là câu trả lời, nên thêm heading chỉ là lặp lại `reminderTitle` lần thứ hai. Trước pass này route tồn tại, screen render, deep link chạy, và **không màn nào trong app link tới nó** — mọi gate đều xanh vì không gate nào hỏi "có ai gọi route này không"; `test/app/router/settings_reminder_entry_test.dart` là cái hỏi |
| D23 | `reminder_settings_section_widget.dart`, `reminder_banner_section_widget.dart` | — | [x] | **resolved** — M99.29: hai `MxCard` của màn nhắc học nhận `AppElevation.none` như mọi card trong cột cuộn (D20). Feature này đến từ nhánh mà Settings còn là placeholder nên chưa từng đứng cạnh ba màn phẳng kia; card nổi bóng ở đây đúng là đường nối D20 sinh ra để xoá |
| D24 | `reminder_banner_section_widget.dart` | `settings_error_band_widget.dart` | [x] | **resolved** — M99.29: hai dải lỗi in-flow của app nói cùng một ngữ pháp. Trước pass này chúng khác nhau bốn điểm: `Try again` trái/phải, padding 12/16dp, message `bodySmall`/`bodyMedium`, khoảng trước nút 4/8dp. **Chọn theo dải của Settings** (quyết định chủ dự án 2026-08-15): nó đã có review và golden riêng, nên lần thống nhất dời màn mới chứ không dời màn đã ổn định — wireframe M6 W5 sửa theo, ghi ở R9. Banner cũng nhận `container: true` để tiêu đề và thông điệp đọc thành một khối như dải kia |

---

## E · Cross-cutting rules from `readme.md`

| # | Rule | Where it must hold | Status | Verdict |
|---|---|---|---|---|
| E1 | Radius policy: 8 chips · 12 buttons+inputs · 16 cards+sheets · 999 pills | every widget | [x] | **match** — zero raw `BorderRadius.circular(<number>)` anywhere in `lib/` |
| E2 | 48px is a floor no prop can shrink | every interactive widget | [x] | **match** — 14 references to `minimumTouchTarget`, no component exposes a prop that could shrink it |
| E3 | One accent, secondary actions neutral | buttons, verdicts | [x] | **match** — `secondaryAction` is neutral in both modes and `app_palette_test.dart` asserts it carries less hue than the accent |
| E4 | Colour never alone — glyph + word + colour | every state | [x] | **match** — the due chip is glyph + words + colour; the deck glyph state is announced |
| E5 | Icons outlined at rest, filled when active | nav bar, tiles | [x] | **match** — 12 `Icons.*_outlined` at rest, `selectedIcon` filled |
| E6 | Three icon sizes only | every icon call site | [x] | **match** — zero raw `size: <number>` on any `Icon` in `lib/` |
| E7 | No gradient, photo, illustration, texture | whole app | [x] | **match** — zero gradients, images or decoration images in `lib/` |
| E8 | Spinner, never skeleton | loading states | [x] | **match** — the only occurrence of the word "skeleton" is the comment explaining why there is none |
| E9 | Sentence case; UPPERCASE only for section labels | ARB files | [x] | **match** — sentence case throughout; the section label is uppercased by the widget, not stored uppercase |
| E10 | Middle dot separates facts on one line | ARB files | [x] | **match** — the middle dot separates facts on the deck meta line |
| E11 | No emoji anywhere | ARB files, code | [x] | **match** — no character above U+2100 in either ARB |
| E12 | Error copy belongs to the screen, not the component | `MxErrorState` callers | [x] | **match** — `MxErrorState` maps no failure type; every caller passes its own sentence |
| E13 | States are instant flat washes (readme §States) | every pressed control on Android | [x] | **divergence** — recorded: Android keeps Material's ink ripple; the wash colours are the kit's (`ThemeData.splashColor` is primary at 12% since M4.10aq), only the animation differs. See divergence #5 |

---

## Excluded, deliberately

| Path | Why it carries no rule |
|---|---|
| `design_system/_adherence.oxlintrc.json` | Lint config for JSX; its content is the `.d.ts` prop lists, already covered by §C |
| `design_system/_ds_manifest.json`, `thumbnail.html` | Gallery plumbing |
| `design_system/github.md`, `IMPORT_LEDGER.md` | Provenance, not design |
| `design_system/SKILL.md` | Agent entry point |
| `design_system/styles.css` | `@import` list only |
| `guidelines/*.card.html` (not yet imported) | Rendered specimens of values already in `tokens/` |

---

## Findings so far

Numbered so the checklist rows can point at them. Ordered by how much each
changes what a user sees.

### F5 - `MxBreadcrumb` never folds, and decks go ten levels deep

The design folds the middle of the path into an expandable ellipsis past four
steps (`collapseAfter`, default 4), keeping the two ends the user actually
navigates to. `mx_breadcrumb.dart` has no fold at all: it scrolls horizontally
and that is the whole strategy. BR-55 allows ten levels, so a deep path becomes
a strip the user has to scrub sideways to read.

**The largest single gap in the shared layer** - and self-contained: no domain
data, no BR.

### F6 - No `rootIcon`

The design puts a `home` glyph before the first step so the library root is
recognisable without reading it. Dart has no such prop.

### F7 - Breadcrumb type is one size too large

Design: `--text-label-md` (12px, tracking 0.5). Dart: `labelLarge` (14px,
tracking 0.1). A path strip is chrome; at 14px it competes with the app-bar
title directly above it.

### F8 - Breadcrumb links are full-strength text

Design keeps every step at `--color-text-secondary` and separates link from
current by **weight only** (semibold vs regular). Dart raises links to
`onSurface` and leaves the current step at `onSurfaceVariant`, so the path reads
louder than the design intends.

### F9 - `MxContentShell` has no `subheader`

The design pins a subheader between the app bar and the scrolling body, and that
is where the redesign puts the breadcrumb **and** the search field.

**Corrected while fixing it:** the first draft of this entry said the deck
screen's breadcrumb scrolled away. It did not - a `Column` above an `Expanded`
is already pinned. What the missing slot actually cost was ownership: the screen
re-derived the gutter with a hardcoded `AppSpacing.lg`, so the path lined up with
the rows at the wide width and not at the compact one, and there was no chrome
boundary for a scroll hairline to attach to.

### F10 - No `leading` slot

Dart relies on `AppBar`'s automatic back button. The design passes `leading`
explicitly, which is what lets the root level render no back affordance at all.

### F1 - Hover is unspecified in Dart

The design gives every control an explicit hover: 4% on cards, 6% on outlined
controls and pills, 8% neutral on rows. `buildSharedButtonStyle` resolves only
`pressed` and `focused` and returns `null` for hover, so Material's default
fills in. **Web and desktop only**, and Android is the release target (AD-04) -
but the web build is the E2E channel, so it shows up in exactly the place the
project looks at screenshots.

### F2 - The bottom bar has no top hairline

`.mx-nav` draws `border-top: 1px solid var(--color-border-subtle)`. The Flutter
`navigationBarTheme` sets background, indicator, elevation and label behaviour -
no border. Both agree the bar paints the page colour, which is precisely why the
design needs the hairline: without it, chrome and content share an edge with
nothing on it.

### F3 - The navigation indicator: the design contradicts itself

`readme.md` says the selected indicator is `secondary-container`, "used
identically for a tab, a filter pill and a chosen verdict". `mx.css` paints
`.mx-nav__pill` with **`--color-primary-container`** and uses
`secondary-container` only on the pill button. Flutter uses `secondaryContainer`
for both, which follows the prose.

**Third instance of the same pattern** - after the `danger`-saturation
contradiction at M4.10p and the breadcrumb height below, the design's prose and
its CSS disagree often enough that "follow the JSX" needs a tie-break. Proposed,
and applied throughout this review: **values win for token values; prose wins
for which token a component reaches for.** That is what M4.10p already did in
practice.

### F4 - No scroll hairline under the app bar

The design fades a hairline in under the bar once the body has actually
scrolled, so a screen whose content fits shows no line. Flutter sets
`scrolledUnderElevation: 0` and draws nothing in either state. The repo's stated
reason - a colour shift behind a flashcard reads as the card itself changing -
argues against Material's *tint*, not against a 1px line.

### F11 - The FAB is a circle; the design's is a rounded square

`floatingActionButtonTheme` sets `shape: CircleBorder()`. `.mx-shell__fab` is
56x56 with `border-radius: var(--radius-lg)` - the M3 shape - and carries
`--shadow-card`, where Flutter sets every elevation to 0.

### F12 - Breadcrumb step height: the design contradicts itself again

`MxBreadcrumb.prompt.md` says "Every step is a 48px target"; `.mx-crumbs__step`
sets `min-height: 36px`. Dart uses 48. **No change proposed** - the prose is
right, and 36 would break the 48px floor the design's own spacing token
declares.

### F14 - `MxLoadingState` overrides the theme that was written to fix it

This is the one finding that is a defect rather than a difference, and it is
this repo's, not the design's.

M4.10j set `buildProgressIndicatorTheme` to `semantic.focusRing` after measuring
that dark `primary` scores **2.81:1** against the surface it spins on - under
the 3.0 floor a graphic needs. `mx_loading_state.dart` then passes
`color: context.colors.primary` explicitly, which overrides that theme. So the
app's main loading state is the one progress indicator the fix does **not**
reach; it only ever applied to the spinners nobody had complained about.

The design says `--color-primary` too, so following the design here would keep a
measured contrast failure. **Prose loses to measurement**: the fix is to delete
the `color:` argument and let the theme supply it, which is also what the repo's
own "fix it at the rule, not the call site" rule says.

### F15 - The dialog has no shadow

`.mx-dialog` carries `box-shadow: var(--shadow-overlay)`; `dialogTheme` sets
`elevation: 0`. In dark this is a no-op - AD-14 already establishes that dark
paints no shadow - but in light a dialog currently floats on a 48% scrim with
only a hairline to separate it.

### F16 - Scrim opacity: 60% flat vs 48/72

The design uses `color-mix(var(--color-scrim) 60%)` in both modes and its readme
calls it "the 60% scrim". `modalBarrierColor()` uses **48% light / 72% dark**,
chosen at M4.10j on the reasoning that a mid scrim over a `#0A082D` page barely
registers.

Both numbers are defensible and the disagreement is about *mode-awareness*, not
about the colour. Flagged rather than changed, because taking 60% flat would
undo a measured decision to fix an unmeasured one.

### F13 - Not a finding: icon-button and list-tile corners

Recorded because it is the thing most likely to be re-checked. Flutter's
`IconButton` and `ListTile` are circular and rectangular by default, so both
looked like drift. Neither is: `iconButtonTheme` and `listTileTheme` both set
`RoundedRectangleBorder(AppRadius.md)`, which is the design's `--radius-md`.

---

## Where this stands (superseded — see below)

**25 of 77 rows reviewed.** Every token row is closed except four small ones;
the theme-data section is closed except three; nine of eighteen shared widgets
are done. Sections D (screens) and E (cross-cutting rules) are untouched.

Findings so far: **one defect (F14)**, **nine drifts** where the Dart should
move to the design (F1-F5 group, F9-F11, F15), **two design self-contradictions**
(F3, F12) and **one flagged disagreement** (F16).

Nothing here has been changed yet. This file is the plan; the fixes are the next
step, and F5 (breadcrumb folding) and F9 (`subheader`) are the two that change
what a user actually sees.

---

## Round 2 - what was fixed

`flutter analyze` clean, **959 tests pass**, 4 goldens regenerated.

| Finding | Fix | File |
|---|---|---|
| **F14** defect | dropped the `color:` argument so the theme supplies it | `mx_loading_state.dart` |
| **F5** | fold past 4 steps, expandable in place, auto-scroll to the deep end | `mx_breadcrumb.dart` |
| **F6** | `rootIcon`, wired to `Icons.home_outlined` | `mx_breadcrumb.dart`, `deck_path_widget.dart` |
| **F7** | `labelLarge` -> `labelMedium` | `mx_breadcrumb.dart` |
| **F8** | both states `onSurfaceVariant`; weight alone distinguishes them | `mx_breadcrumb.dart` |
| **F9** | `subheader` slot, and the deck path moved into it | `mx_content_shell.dart`, `deck_list_screen.dart` |
| **F10** | `leading` slot | `mx_content_shell.dart` |
| **F4** | hairline derived from scroll position | `mx_content_shell.dart` |
| **F1** | hover resolves to 6% accent instead of falling through | `app_button_themes.dart` |
| **F2** | top hairline on the bar | `mx_navigation_bar.dart` |
| **F11** (part) | FAB shape circle -> `RoundedRectangleBorder(AppRadius.lg)` | `app_theme.dart` |

### Two things the render caught that reading did not

**The nav hairline was broken in the middle.** `DecoratedBox` paints its
decoration *behind* its child by default, and `NavigationBar` paints its own
fill, so the first version drew a line at both edges and a gap where the
destinations sat. `DecorationPosition.foreground` fixes it. Only visible in the
golden.

**Material elevation renders as a solid black ring in goldens.** F11 and F15
originally added `elevation` to the FAB and the dialog to carry the design's
`--shadow-card` / `--shadow-overlay`. The regenerated golden showed a dialog
inside a heavy black outline, because `flutter_test` disables real shadows and
draws them as solid shapes.

That turned out to be the smaller reason to back it out. The larger one: **AD-14
makes depth one mechanism** - `shadowsFor`, a `BoxShadow` that the colour audit
can read and that is empty in dark by measurement. Material's `elevation` is a
second, parallel mechanism that is not mode-aware and that no audit rule can
see. Adding it would trade a measurable rule for an unmeasurable one. The shape
change landed; the shadow did not.

## Still open

**Superseded by Round 4.** This table is where Round 2 stood; six of its rows
have closed since. It is kept because the reasons are still the reasons — read
the tally at the foot of the file for what is actually open.

| # | Why |
|---|---|
| **F15** dialog / FAB shadow | Needs the `shadowsFor` mechanism, which for a dialog means wrapping its content rather than setting a theme property. Deferred deliberately, reason above. |
| **F3** nav indicator role | Design's prose and CSS disagree; Dart follows the prose. No change. |
| **F12** breadcrumb step height | Same - prose says 48, CSS says 36, and 36 breaks the design's own touch-target floor. No change. |
| **F16** scrim opacity | Design 60% flat vs Dart 48/72. Dart's numbers were measured at M4.10j; taking 60% would undo a measured decision to satisfy an unmeasured one. Flagged, not changed. |
| **C8 / C17 / D6 / D7** | `MxProgressBar`, `MxSearchField`, the summary panel and subtree search. Blocked on a `learned` definition that no BR provides, and on a query that does not exist. |
| A7, A13, A14, A16, A18, A19, B10, B12, B13, C5, C7, C10, C12-C15, D1-D5, D8-D15, E1-E12 | Not yet reviewed. |

---

## Complete — all 80 rows

Every row now carries a verdict. Final tally (B14, B15 and E13 joined in
M4.10aq's theme-slot audit — see Round 3 below):

| Outcome | Count |
|---|---|
| **match** — nothing to do | 48 |
| **fixed** — Dart moved to the design | 14 |
| **n/a / design-gap** — no counterpart is needed on one side | 9 |
| **blocked on M5** — streak, Start studying, the review and settings screens | 4 |
| **deliberate divergence, recorded** | 5 |

### Fixed in this last pass

- **A16** — Dart had no easing token at all, and the one call site used
  `Curves.decelerate`, which is `cubic-bezier(0, 0, 0.2, 1)` where the design's
  is `(0, 0, 0, 1)`. Close enough to look right and not the same curve. Both of
  the design's curves are now named in `AppDurations`.
- **A7** — the section label's 1.1px tracking was a literal at the call site.
- **D3** — the list had no heading. The design puts "Your decks" / "Sub-decks"
  beside the filter and sort pills, and without it the two pills float above the
  cards with nothing saying what they filter. It sits inside the `Wrap` rather
  than a `Row` above it, because at `textScaler` 2.0 on a 320 screen the label
  and both pills cannot share a line and a `Row` would clip instead of wrapping.

### The five deliberate divergences, all measured

| # | The design says | This repo does | Why the repo wins |
|---|---|---|---|
| C10 | retry is a `secondary` button | primary | Prose, not a value. M4.10n changed it so two states one keystroke apart stop looking like two components. |
| F3 | `mx.css` paints the nav indicator `primary-container` | `secondaryContainer` | The design's own readme says `secondary-container` "used identically for a tab, a filter pill and a chosen verdict". Its CSS and its prose disagree. |
| F12 | `.mx-crumbs__step` is 36px tall | 48 | The design's own usage note says 48, and 36 breaks the touch-target floor its own spacing token declares. |
| F16 | a 60% scrim in both modes | 48% light / 72% dark | M4.10j measured it: a mid scrim over a `#0A082D` page barely registers. |
| E13 | states snap to a flat wash, no animation | Android animates the press as an ink ripple, in the kit's colours | Platform-native touch feedback on the release target (decided M4.10aq). The kit is a web artifact with no press-animation vocabulary; the wash colours themselves are transcribed, and parity screenshots are static so no render can see the difference. `MxTextButton` and `MxBreadcrumb` keep their local `NoSplash` — text links carry states on the text itself. |

Plus the two contradictions resolved in the design's favour with a correction
attached — `danger`'s saturation (M4.10p) and the due chip's foreground
(M4.10s), where the design's value failed WCAG and the container it sits on had
no `on*Container` partner to reach for.

**Six contradictions inside the design in total.** That is the single most useful
thing this review produced: "follow the JSX" is not a rule that can be applied
without reading, because the JSX disagrees with itself often enough to need the
tie-break this file states — values win for token values, prose wins for which
token a component reaches for, and measurement wins over both.

### Still blocked, and on what

| Item | Blocked on |
|---|---|
| Streak chip (D6 part) | `review_history` has no writer until M5. A streak that is always zero is worse than no streak. |
| "Start studying" (D6 part) | No session to start until M5. |
| `ReviewScreen` (D13), `SettingsScreen` (D14) | Neither is a built screen; both exist here only as preview harnesses. |
| `MxSearchField` (C17), subtree search (D7) | **Not blocked** — needs a recursive name query, a contract method, a use case and the results UI. The one substantial piece of the design still unbuilt. |

---

## Round 3 — the theme-slot audit (M4.10aq)

An audit of `ThemeData` against what the app actually renders, in both
directions: slots a live renderer was missing, and slots that outlived their
renderer. Three rows joined the tables above (B14, B15, E13); the rest of what
it changed has no row of its own:

- **`floatingActionButtonTheme` is gone.** M4.10ag removed the FAB itself; the
  theme outlived its renderer and kept the F11 shape argument alive for a
  control that no longer exists. The kit still draws `.mx-shell__fab` — that
  cleanup is the kit's, recorded here so it is not mistaken for a Flutter gap.
- **`cardTheme` stays, re-labelled.** Still no `Card` in the app; the slot is
  now documented as the safety net that keeps a bare or third-party `Card` on
  the app's surface, radius and hairline. `MxCard` remains canonical.
- **Geometry pinned for the E2E channel.** `visualDensity: standard` and
  `materialTapTargetSize: padded`. Flutter's platform defaults hand a desktop
  browser `compact` density and `shrinkWrap` targets, so Playwright was
  measuring geometry Android never renders. No CSS counterpart — the kit has
  no density concept — so no row.
- **The framework fall-through is seeded.** `hoverColor` / `focusColor` /
  `highlightColor` / `splashColor` now carry the kit's washes, so a control
  nobody themes degrades to the house states instead of Material's unseeded
  black-and-white pair. `iconTheme` is declared at `onSurfaceVariant` /
  `AppIconSize.md` for the same reason.
- **`MxActionSheet`'s private `0.38`** — a re-derivation of
  `--color-on-disabled` — now reads the token (`semanticColors.onDisabled`).
  The 0.4-per-mille alpha difference between the literal and the token moved
  the two action-sheet goldens by one channel step; regenerated deliberately.

---

## Round 4 — re-verification, and the gate (M4.12d)

M4.12 asks for "design parity below 3% on screens with a baseline". Rounds 1–3
did the comparison; this round made the result **executable**, and in doing so
found that the file had stopped being true.

### Nine rows said drift; seven had been fixed and nobody moved the label

The nine were re-checked against `lib/` one at a time, not re-reasoned from the
prose:

| Row | Said | Actually |
|---|---|---|
| B2 (F1) | hover unspecified | every button theme declares hover, blending toward the ink |
| B6 (F2) | no top hairline on the nav | drawn in `MxNavigationBar` as a *foreground* border |
| B9 · C11 (F14) | spinner takes `primary` | slot declares `focusRing`; the widget's override is gone |
| B11 (F4) | no scroll hairline | derived from scroll position, set as the `AppBar.shape` bottom |
| B11 (F11) | FAB shape differs | the FAB went at M4.10ag, its theme at M4.10aq |
| C16 (F5–F8) | no fold, no `rootIcon`, wrong size, wrong colour | all four closed at M4.10q |
| C18 (F9, F10) | no `subheader`, no `leading` | both are slots, and `subheader` is what pins the deck path |

Two were never drift in the first place — **F3** and **F16** are measured
divergences and already sat in the divergence table, contradicting their own
rows. One is real: **F15**, the dialog's missing `--shadow-overlay` in light
mode. Its comment in `app_theme.dart` cites AD-14 to justify `elevation: 0`, and
AD-14 §4 says the opposite — depth is a measured target each mode builds from
what it has, and light builds it with a shadow. Left open deliberately rather
than fixed in passing: it moves every dialog golden, and goldens get a render
review first.

**The lesson is about the gate, not about the rows.** A checklist whose labels
are maintained by hand drifts from the code exactly the way the code was supposed
to drift from the design. Three milestones of parity work went into rows that
still read "drift", and nothing failed.

### The tally, and what the gate reads

`test/design_audit/design_parity_gate_test.dart` parses the tables in sections
A–E and fails when open **drift** exceeds 3% of the reviewed rows, when a row is
unreviewed, or when a verdict opens with a word outside the closed set.

| Verdict | Count |
|---|---|
| **match** | 50 |
| **resolved** | 17 |
| **divergence** | 4 |
| **blocked** | 3 |
| **n/a** | 3 |
| **design-gap** | 2 |
| **drift** — open | **1** |
| **Total rows** | **80** |

**1 of 80 = 1.25%**, against the 3% gate. Three open rows would fail it.

The four **divergence** rows are C10, B6 (F3), B7 (F16) and E13. The divergence
table names five, because F12 — the breadcrumb's 36px step — belongs to C16,
whose other four findings are resolved; a row carries the strongest verdict its
findings still justify.

### Why 3% is not a pixel difference here

`docs/checklist.md` 15.x says pixel difference, and M4.10 and M4.11 each recorded
that it could not be applied — scope mismatch between the two sides, then no card
list in the kit at all. Beyond both: the design renders in Chrome from CSS and the
app renders through Skia, so antialiasing, font hinting and the kit's CDN icon
glyphs put a floor under the difference that parity work cannot move. A number
that cannot reach its threshold however correct the app is, is not a gate — it is
a permanent red light, and a permanent red light gets muted.

The share of open drift is the same threshold on a quantity that is about the
design instead of about two rasterisers. It is also the quantity a reader of this
file can act on: each unit is a row, and the row says which file to open.

## Library density pass (concept 2026-08-11)

Concept: hai ảnh `1-Photo-1.jpg` / `2-Photo-2.jpg` trong
`.codex-remote-attachments/.../b43d1d34…/`. Quyết định lấy **bố cục và mật độ**,
không lấy màu hay tính năng ngoài domain.

| Quyết định | Flutter | design_system | Ghi chú |
|---|---|---|---|
| Search thu gọn thành icon trong strip breadcrumb, bấm mới mở field (autofocus) | ✅ `deck_subheader_widget.dart`, `MxSearchField.shouldAutofocus` | ❌ chưa — `.mx-search` giữ nguyên, kit chưa có trạng thái thu gọn | **Phân kỳ cố ý, ghi tại đây.** Component không đổi; thứ đổi là *khi nào* màn deck mount nó. Kit HTML là mock tĩnh nên trạng thái nghỉ/mở cần một mock mới — làm khi đụng kit lần sau |
| Badge hai chip New/Due trên tile (BR-150) | ✅ `deck_due_state_widget.dart` | ❌ chưa — kit còn một chip due | Cùng PR sau của kit; contract màu: due = `--color-streak-container`, new = viền `--border-hairline` + ink phụ |
| Summary một dòng `titleLarge` + câu, padding `md` | ✅ `deck_level_summary_widget.dart` | ❌ chưa | Kit đang là bản hai tầng cũ |
| Tile: đầu card `md/xs` thay `lg/sm` | ✅ `deck_tile_widget.dart` | ❌ chưa | Mật độ: 3 deck đủ khi summary mở, 393×852 |

## Deck tile anatomy pass (refine, 2026-08-11)

Chốt anatomy ba băng và color-role cho tile + summary. Concept chỉ cho
hierarchy; mọi màu là token.

| Quyết định | Flutter | design_system | Ghi chú |
|---|---|---|---|
| Workload line `7 Due · 14 New` đứng riêng trên hàng action; luôn hiện cả hai số, kể cả 0; bỏ micro-label `NEW` | ✅ `deck_workload_line_widget.dart` | ❌ chưa | **Bản hiện hành (three-set hero pass, BR-162):** hero tách workload thành **ba tập rời nhau** theo thứ tự khẩn cấp `Overdue → Due today → New` (thứ tự cố định, chỉ emphasis di chuyển: Overdue>0 → primary; hết Overdue thì Due today; hết Due thì New; all-zero → cả ba neutral cùng cỡ). Mỗi metric một icon anchor cùng geometry: Overdue = `event_busy` trên `error-container` khi >0 (word ink `error`), neutral khi 0, badge `+Nd` (tuổi backlog) chỉ ở đây; Due today = `event`/`event_outlined` trên `streak-container`; New = `auto_awesome_outlined` ink `info`. **Thống nhất màu Due toàn app:** tile `dueToday` đổi từ `primaryContainer` (tím) sang `streak-container` (vàng) — một trạng thái một màu ở mọi nơi; tile vẫn total Due + New (không nhồi ba metric vào row). Semantics: ba câu riêng (`deckHeroOverdue/DueToday/NewSemanticLabel`), mỗi câu đọc đúng một lần, visuals excluded. **Bổ sung cùng pass (lưới 2×2):** metric thứ tư `Scheduled`/`Chờ lịch` (= total − New − Due, thuần arithmetic trên snapshot — không query mới) đóng kín phân hoạch: bốn ô cộng đúng bằng tổng thẻ. **Grid 2 cột thật** (feedback chủ dự án 2026-08-12 từ screenshot device): cell = nửa bề rộng band qua `LayoutBuilder`, hai cột chung mép trái ở mọi hàng — intrinsic width đã thử và ô Overdue mang badge làm cột phải lệch. Hero **bỏ badge chip**: tuổi backlog ghi thẳng vào chữ — `Overdue (+7d)` / `Quá hạn (+7ng)`, cap `(99+d)` cùng ngưỡng `DeckOverdueBadgeWidget.capAt`; chữ wrap trong cell ở 320@2.0 thay vì ellipsis. Badge chip chỉ còn trên tile icon. **Baseline rhythm** (feedback chủ dự án 2026-08-12): grid đổi từ Wrap sang Column hai Row với `CrossAxisAlignment.baseline`/`TextBaseline.alphabetic`, cell `Expanded` — hàng trộn `headlineMedium` với `titleLarge` từng căn mép trên nên baseline số primary tụt thấp hơn. Row bên trong mỗi cell cũng baseline-aligned để baseline cell = baseline chữ (không phải mép icon well sau khi center). Không dùng Transform/padding nudge — chỉ khớp ở một scale. Test đo baseline thật qua TextPainter, sai số ≤ 0.5px. Rà các row tương tự: `MxProgressBar` đã baseline-aligned sẵn; workload/meta line dùng một style đồng nhất nên center vô hại. Icon `event_available_outlined`, luôn neutral và không bao giờ primary — thẻ nghỉ không đòi hành động. Chọn `Scheduled` thay vì `Learned`/`Total` (quyết định chủ dự án qua popup 2026-08-12) vì hai phương án kia trùng thông tin dòng progress. *(Supersede: hero hai-metric Due/New của status-first hero pass; phần eyebrow/MxCard/progress giữ nguyên.)*

*(Lịch sử — status-first hero pass:)* panel summary được nâng thành hero của màn hình, scan theo thứ tự *phạm vi thời gian → workload ưu tiên → workload hỗ trợ → tiến độ*. Surface = `MxCard` mặc định (padding `lg`, elevation card, radius/border/interaction dùng chung) thay cho `DecoratedBox` tự dựng; panel không tappable, nút đóng (`MxIconButton`, 48px, tertiary) là control duy nhất. Header có eyebrow `Today`/`Hôm nay` (`deckSummaryTodayLabel`, `labelMedium`/`onSurfaceVariant`). **Một focal point:** due>0 → numeral Due `headlineMedium`, New `titleLarge`; due=0 & new>0 → New lên `headlineMedium`, Due 0 vẫn hiện ở neutral; cả hai 0 → cùng cỡ supporting, không claim mới. Thứ tự Due→New không bao giờ đổi (BR-150). **Cả hai metric đều có icon anchor** cùng well (pill, padding `xs`, `AppIconSize.sm`): Due = event_outlined/muted → schedule/streak → event_busy/error-pair theo `deckScheduleStatusOf`; New = auto_awesome_outlined trên muted, ink `info` khi >0. Badge `+Nd` inline sát cụm Due, semantics một câu duy nhất (visuals excluded). Progress: một `MxProgressBar` sm sau seam `lg`. Metrics wrap hai hàng ở 320@2.0, không ellipsis số. *(Supersede: "support, not hero", "metrics một hàng", "panel không padding như hero" của các pass metric-first/level-status; phần schedule-status grammar và badge đỏ giữ nguyên hiệu lực.)*

*(Lịch sử — level-status pass:)* level summary nói cùng grammar lịch với tile (BR-161) — metric Due của panel phân ba trạng thái qua đúng hàm `deckScheduleStatusOf` mà tile dùng: notDue = số neutral không mark; dueToday = clock trên `streak-container` như cũ, không badge; overdue = missed calendar trên `error-container` + badge `+Nd` **inline** sau chữ (không cưỡi góc — ở cỡ metric, badge offset âm đè lên con số), semantics đọc nguyên câu. Anatomy panel giữ nguyên: một ProgressBar, không băng mới, chiều cao không đổi (badge labelSmall nằm trong dòng titleLarge). Đi sâu vào deck, panel vẫn giữ `+Nd` của subtree dù deck mang backlog không còn là hàng trên list. `DeckStatusIconWidget` nhận `status`/`dueCardCount`/`overdueDayCount` thay vì cả summary; badge tách thành `DeckOverdueBadgeWidget` dùng chung hai chỗ. *(Kế thừa schedule-status pass; supersede riêng phần "chỉ ô icon đổi đỏ" — badge của panel cũng thuộc trạng thái đỏ.)*

*(Lịch sử — schedule-status pass:)* anatomy giữ khối một Column (title → metadata → workload, nhịp `xs`) nhưng **rollback icon-per-metric** — golden cho thấy năm anchor trên ba dòng làm metadata wrap và card cao lên; metadata/workload trở lại **text thuần** `bodySmall` (`4 sub-decks · 570 cards · 8 boxes` / `12 Due · 46 New`, `·` dính vào fact phía sau). Scheduler **chỉ hiện ở root list** (`DeckTileWidget.showScheduler`, truyền từ `snapshot.isRootLevel`) vì mọi descendant kế thừa (BR-06). **Icon lớn = trạng thái lịch (BR-161):** `notDue` = `event_outlined` trên `surface-muted`; `dueToday` = `event` trên `primary-container`; `overdue` = `event_busy` trên `error-container` (đỏ — quyết định chủ dự án 2026-08-11, đảo phán quyết "không danger" cùng ngày; icon ink `on-error-container` đổi theo, cặp M3 tự đảm bảo contrast) + badge `+Nd` (`error`/`on-error` — cùng họ đỏ với well, 5.76:1 light / 6.8:1 dark; cap `99+`), semantics đọc nguyên câu. Completion **không** còn đổi icon — gauge success + 100% đảm nhiệm. Due ink của workload text vẫn `on-streak-container`/info — trạng thái overdue đỏ trọn bộ ô icon + badge. *(Supersede: unified-block pass phần icon-per-metric và check completed; các quyết định trước giữ nguyên phần còn hiệu lực.)*

*(Lịch sử — unified-block pass:)* title + metadata + workload là **một Column** trong head region — không còn indent bù `DeckIconArea.dimension + md`, nhịp `xs` cho mọi line break, seam `sm` trước action row (ranh giới thông tin/hành động). **Mọi metric cùng grammar icon+label** qua `DeckMetricWidget` (icon `sm`, gap `xs`, `bodySmall`, không well/chip/background): sub-decks `folder_outlined`, cards `style_outlined`, scheduler `account_tree_outlined`, Due `schedule`, New `auto_awesome_outlined`. **Due/New giữ icon ở cả zero** — state nằm ở ink: dương = streak-ink/`info` + w600, zero = `on-surface-variant` thường; luôn đủ hai số trên deck có card. **Icon lớn phản ánh Due:** `hasDueCards` → identity glyph trên well `streak-container` (ưu tiên hơn completed — 100% learned vẫn có thể nợ ôn); 0/0 + 100% → check success; new-only/idle → brand mặc định. Progress/action row không đổi. *(Supersede: metadata-block pass hai dòng tách region; và các bản trước — full pill, icon well, labelMedium.)* Summary giữ mini-well vì numeral ở scale hero. |
| Gauge vào trong surface, cùng hàng với `%` và Study; bỏ track flush đáy card | ✅ `_DeckActionRow` trong `deck_tile_widget.dart` | ❌ chưa | Track/fill = `progress-track`/`progress-fill`, success chỉ ở 100% (đã là contract của `MxProgressBar`) |
| Summary metric-first: `12 Due  14 New` + dòng learned + bar, bỏ câu văn dài | ✅ `deck_level_summary_widget.dart` | ❌ chưa | Numeral `on-surface` titleLarge, word `on-surface-variant`/role ink |
| Study giữ tonal `secondary-container` | ✅ (không đổi) | ✅ | |

Contrast đo tại `deck_workload_role_test.dart`: info/surface 5.23:1 (light),
7.84:1 (dark); onStreakContainer/streakContainer ≥ 4.5:1 hai theme;
progressFill/progressTrack ≥ 3:1 hai theme.

