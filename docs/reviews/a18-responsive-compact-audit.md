# A18 — Responsive / compact / mobile-density deep audit

| | |
|---|---|
| BASE_SHA | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` — *refactor(theme): the dark card stops glowing* (M100.35, #435) |
| Branch | `claude/a18-responsive-compact-audit-srftpd` (session-designated; the task's `audit/a18-responsive-compact` is recorded here rather than pushed, per the branch contract this session runs under) |
| Declared SDK | Flutter **3.44.8** stable · Dart `^3.12.2` (`pubspec.yaml`) |
| Scope | Every width-, orientation-, density- and text-scale-dependent decision under `lib/`, plus the tests, goldens, Widgetbook and CSS kit that are supposed to hold them |
| Mode | **Report only.** No production, theme, test, Widgetbook, kit or golden file was changed. `git status` verified clean apart from this file |
| Widths audited | **320 / 360 / 375 / 393**, plus the one upper edge that exists (`AppBreakpoints.medium` = 600) |

## 0 · Method, and what it could not do

**There is no Flutter or Dart SDK in this session's container** (`which flutter
dart` → nothing; no SDK anywhere under `/`, `/opt` or `$HOME`). So unlike the
`MxTextField`, `MxListTile` and chip audits, **nothing in this report was
measured on a running tree.** Every number below is one of:

- a **constant read from source** (a token, a literal, a threshold), or
- **arithmetic over those constants** — gutters subtracted from a width, a font
  size multiplied by its declared `height` and by a text scaler — shown in full
  so the step that is wrong is visible, or
- a **contrast ratio computed** from the palette hexes with the WCAG 2.x
  relative-luminance formula (the one computation that needs no renderer).

That is enough to find a fixed box holding text that outgrows it, and enough to
find two rules disagreeing about which width they read. It is **not** enough to
claim a pixel. So every finding carries a **closure test** that measures the
thing, and no finding is marked confirmed-by-measurement. Where a claim depends
on Flutter's own internals that could not be read at the pinned SDK, it is
marked ⚠ *unverified against the SDK* rather than asserted.

`flutter analyze`, `flutter test` and `dod_check.sh` were **not run**, for the
same reason. This is a documentation-only change; the repo's own plan builder
classifies a docs-only diff as verifying nothing, so nothing was skipped that
CI will not itself run.

---

## 1 · Verdict

**The breakpoint model is sound, deliberately small, and honestly documented —
and it is undermined in two specific places: one constant is compared against
two different widths, and the header's second line is a fixed 32 dp box with
growable text in it.**

What is right, and what the next pass must not "simplify":

- **One branch point, and it is real.** `AppBreakpoints.compact = 360` is the
  only width anything branches on. Five production sites read it. There is no
  desktop tier, no tablet tier, and no `Orientation` branch anywhere in `lib/`.
- **`AppBreakpoints.medium = 600` branches nothing.** Its four production uses
  are all `BoxConstraints(maxWidth:)` ceilings. The docstring, the CSS token
  comment and `design_system/readme.md` all say the same thing, and the code
  does it.
- **Body text is never scaled by device width.** The compact scale touches
  `titleLarge` (22→20) and `AppTextStyles.cardPrompt` (30→26) and nothing else
  typographic. `bodyLarge/Medium/Small` and every `label*` rung are untouched at
  every width.
- **`textScaler` is never clamped, anywhere.** 43 references across `lib/`, and
  not one is a `TextScaler.linear`, a clamp or a `MediaQuery(textScaler:)`
  override. Fifteen call sites *scale a threshold by the live scaler* before
  comparing it — the correct shape, and unusually consistent.
- **The 48 dp touch floor is structural, not conventional.** `minimumSize` in
  `buildSharedButtonStyle` and `app_icon_button_theme`, `tapTargetSize: padded`
  on the theme, and `_compactPadding` explicitly giving back *horizontal* room
  only. `MxIconButton.isCompact` was already fixed to move the glyph and not the
  box. The compact scale cannot reduce a target.
- **Sheets have one shared answer to the bottom obstruction** (`MxSheetInsets` /
  `mxSheetBottomObstruction`), written after three call sites had three
  spellings and one was broken.

What the next pass has to fix:

| # | Finding | Sev |
|---|---|---|
| R1 | **Seven `isScrollControlled` sheets omit `useSafeArea`** — the shared `showMxFormSheet` among them; the fix already exists at one call site and was never generalised | **P1** |
| R2 | **The header's second line is a fixed 32 dp box**, at both of its implementations, holding text that measures 40 at scale 2.5 and 48 at 3.0 — clipped silently, on the app's landing screen and every deck screen | **P1** |
| R3 | `MxHeroCard` compares a **card** width against a **screen** constant → the effective threshold is 392 dp; 360 / 375 / 390 take one branch and 393 takes the other, and the two test harnesses straddle it | **P2** |
| R4 | The deck list **adds `viewPadding.bottom` a second time** — the nav bar already removed it and the shell's `SafeArea` already ran; it also contradicts the rule written in the search list | **P2** |
| R5 | Scrollbar thumb measures **1.79 : 1** light / **2.00 : 1** dark on the card paper, from a bare `0.4` alpha that is on no token — on the one surface where the scrollbar *is* the "there is more to read" cue | **P2** |
| R6 | `ScrollbarThemeData.thickness` is a `WidgetStatePropertyAll`, so it is 4 dp in **every** state — no hover/drag thickening on the channel that has a pointer | P3 |
| R7 | `MobileFrameWidget` zeroes `viewInsets`, `viewPadding` **and** `padding` → the E2E/visual channel cannot reproduce a keyboard or a cutout at all | P3 |
| R8 | `mxSheetBottomObstruction` uses `MediaQuery.of` — one of only two full-data subscriptions in `lib/` | P3 |
| R9 | `AppBreakpoints.medium` caps 4 surfaces of ~26 → above 600 dp the app is half-capped, by accretion rather than by decision | P3 |
| R10 | Kit parity: the CSS kit publishes the compact tokens but has **no rule that applies them**, no compact gutter token, and neither shipped device is below 360 | P3 |

And the coverage holes that let R1–R4 exist unnoticed:

| # | Gap | Sev |
|---|---|---|
| G1 | **375 dp appears in exactly one test file** in the repository, and **360 dp in three** — neither is a screen-level surface anywhere | **P2** |
| G2 | No test asserts a sheet's top edge against the status bar, at any width or scale — the class R1 lives in | **P2** |
| G3 | `hero_action_width_test` pins 320 and 393 only, i.e. both sides of the *stated* threshold and neither side of the *effective* one | P2 |
| G4 | **4 of 152** committed screen goldens are at a compact width, covering 3 screens; Library, Study Home, Progress, Settings, Card list and the study session have no compact picture at all | P2 |
| G5 | No screen-level landscape test, though nothing in the manifest or in `lib/` locks the orientation | P3 |
| G6 | Widgetbook renders the breakpoint tokens as swatches (`scale_sections.dart`) but has no compact-width or text-scale knob, so the tier is not reachable in the catalog | P3 |

---

## 2 · The actual breakpoint model

### 2.1 What exists

```
AppBreakpoints                            lib/core/theme/foundations/app_breakpoints.dart
├── compact = 360   ← the only branch point in the app
├── medium  = 600   ← a ceiling; nothing branches on it
└── isCompact(double width) => width < compact       (strict <)
```

Two constants, one predicate, and they are mirrored into the CSS kit
(`design_system/tokens/layout.css`) with `css_scale_parity_test.dart` pinning
both. There is no third tier, and `design_tokens_test.dart` asserts only their
ordering.

### 2.2 Where the branch is taken — the complete list

Five production sites, all reading **screen** width:

| # | Site | Reads | Effect below 360 |
|---|---|---|---|
| 1 | `app/app.dart:165` `CompactScaleWidget` | `MediaQuery.sizeOf(context).width` | swaps in `applyCompactScale(theme)` |
| 2 | `shared/widgets/mx_content_shell.dart:383` `mxScreenGutter` | `sizeOf.width` | gutter 16 → 12 |
| 3 | `shared/widgets/mx_content_shell.dart:335` `MxSubheaderBand` | `sizeOf.width` | top pad 8 → 0 (bottom stays 4) |
| 4 | `features/deck/.../deck_tile_widget.dart:312` `deckTileGutter` | `sizeOf.width` | card gutter 16 → 12 |
| 5 | `features/deck/.../deck_tile_widget.dart:282` study-button gap | `sizeOf.width` | gap 12 → 8 |

One production site reading a **constraint** width — and this is R3:

| # | Site | Reads | Effect |
|---|---|---|---|
| 6 | `shared/widgets/mx_hero_card.dart:58` `MxHeroCard` | `constraints.maxWidth` (the card, = screen − 2 × gutter) | `isCramped` → hero primary stretches |

### 2.3 Where the ceiling is applied

`AppBreakpoints.medium` as `BoxConstraints(maxWidth:)`, never as a branch:

- `card_detail_screen.dart:226` — the reading column
- `study_home_body_section_widget.dart:122` — the working column
- `tag_catalog_screen.dart:111, 131, 183` — three bands of one column
- `card_import_screen.dart:258` — the stepper column

Below 600 every one of these is a no-op, which is exactly what the docstring
claims. See R9 for what happens above it.

### 2.4 The other ceilings, which are not breakpoints

| Ceiling | Value | Where |
|---|---|---|
| Navigation row | `4 × widthPerNavigationDestination` = **480** | `mx_navigation_bar.dart:116` — self-disarming: at four destinations the screen binds first on every phone |
| Dialog inset | **40** a side (`MxDialogMetrics.inset`, Material's own default) | `mx_confirm_dialog`, `mx_form_dialog`, `mx_alert_dialog` |
| Dialog actions inset | **24** a side (`AppSpacing.xl`) | same three |
| Web frame | **393 × 852** (`kMobileFrameSize`) | `mobile_frame_widget.dart` |
| Tag list viewport | **0.5 × screen height** | `card_tag_filter_sheet_widget.dart:27` |

---

## 3 · What the compact tier actually changes

`applyCompactScale(ThemeData)` — `lib/core/theme/schemes/app_compact_scale.dart`,
memoised through an `Expando` keyed on the base theme.

| Axis | Regular (≥ 360) | Compact (< 360) | Δ |
|---|---|---|---|
| **Typography** | `titleLarge` 22 | 20 | −2 (−9 %) |
| | `AppTextStyles.cardPrompt` 30 | 26 | −4 (−13 %) |
| | every `body*`, every `label*`, `headlineMedium` | **unchanged** | 0 |
| **Padding** | `listTileTheme.contentPadding` h 16 / v 4 | h **12** / v 4 | −4 horizontal only |
| | `filledButtonTheme` / `outlinedButtonTheme` padding h 24 / v 12 | h **12** / v 12 | −12 horizontal only |
| | `textButtonTheme` | **untouched, deliberately** — it is a zero-padding link | 0 |
| **Layout** | screen gutter 16 | **12** | −4 a side |
| | deck card gutter 16 | **12** | −4 a side |
| | subheader band top 8 | **0** | −8 |
| | deck study-button gap 12 | **8** | −4 |
| **Visual body** | — | nothing: no radius, no elevation, no stroke, no icon size changes | 0 |
| **Touch** | `AppSizing.touchTarget` 48 | **48** | 0 — `minimumSize` survives `copyWith(padding:)` |

Three properties of this design are worth stating because they are the ones a
future change is most likely to break:

**(a) It is a theme swap, not a layout mode.** `CompactScaleWidget` sits inside
`MaterialApp.builder`, *below* `MobileFrameWidget` — so on web it reads the
framed 393, not the browser window. Nothing above `MaterialApp` can see the
compact tier and nothing below it can opt out. That placement is correct and
the comment beside it explains why.

**(b) Height is never traded for width.** Every compact reduction is horizontal
or typographic; not one is a vertical shrink. `AppBreakpoints.isCompact` takes a
*width*, and the docstring states why height is handled by scrolling instead —
"shrinking type to win vertical space would apply on every device the moment a
keyboard opened". That reasoning holds and should be quoted at anyone who
proposes a height tier.

**(c) The two type reductions are not equivalent, and the docstring's own rule
is what separates them.** `titleLarge` is chrome the app chose to oversize —
reducing it is free. `cardPrompt` is **the learner's own card content**, and it
is the app's one deliberately-large style. At `textScaler` 2.0 on a 320 screen a
user who asked for double type gets 52 px rather than 60; at 3.0, 78 rather than
90. That is a **13 % reduction of a user's requested content size, driven by
device width** — the exact shape of thing the file's header says it refuses to
do to body text. It is nevertheless the right trade (the comment records the
failure it prevents: a two-word prompt on three lines pushing the answer below
the fold at 320), so this is **not filed as a defect**. It is filed here because
the rule "body text is never scaled by device width" is repeated in
`design_system/readme.md` and in this file's header, and a reader checking that
claim against the code will find `cardPrompt` and needs the answer written down:
*the prompt is app-chosen display type that happens to carry user content, and
the exception is deliberate.*

---

## 4 · Gutters and density

| Surface | Regular | Compact | Source |
|---|---|---|---|
| Screen body | 16 | 12 | `mxScreenGutter` |
| Screen subheader band | 16 (h) | 12 (h) | `MxSubheaderBand(gutter:)`, fed from `_defaultPadding().left` |
| Deck card interior | 16 | 12 | `deckTileGutter` |
| Deck list scroll | 16 | 16 — **does not scale** | `deck_list_sliver_widget.dart:73` uses `AppSpacing.lg` literally |
| Search list | `mxScreenGutter` | `mxScreenGutter` | correct |
| Progress level | `mxScreenGutter` | `mxScreenGutter` | correct, with the reason written down |
| Sheet | 16 all round + obstruction | 16 — **does not scale** | `MxSheetInsets` |
| Dialog | 40 outer / 24 actions | same | `MxDialogMetrics` |

Two of these do not follow the rule the other five do. Neither is a bug today
(`deck_list_sliver_widget`'s `SliverPadding` sits *inside* `MxContentShell`
whose own padding is null on that screen, so the 16 is the only gutter and the
compact tier simply does not reach it; the sheet is not a page). Both are worth
recording, because `mxScreenGutter` exists precisely so a second site does not
re-derive the rule — and these two re-derive it by writing the constant instead.

Derived content-column widths, which every downstream number depends on:

| Screen width | Gutter | Content column | `MxHeroCard.isCramped` |
|---|---|---|---|
| 320 | 12 | **296** | true |
| 360 | 16 | **328** | **true** |
| 375 | 16 | **343** | **true** |
| 390 | 16 | **358** | **true** |
| 392 | 16 | **360** | false |
| 393 | 16 | **361** | false |

---

## 5 · Literal-breakpoint inventory

### 5.1 Canonical — the tier, read through the predicate

`AppBreakpoints.compact` (360) at the six sites in §2.2 and §2.3, plus
`AppBreakpoints.medium` (600) at the six ceiling sites. `320`, `360`, `375`,
`393` and `412` appear ~40 times in `lib/` **as prose in doc comments recording
where a number was measured**. That is a good use of them and not drift: not one
of those comments is compiled.

### 5.2 Feature-specific and legitimate — a measured demand, not a width tier

These compare *what the content needs* against *what the box has*, and — this is
the part that makes them correct — **scale the demand by the live text scaler
first**. They are not breakpoints and must not be converted into any:

| Site | Constant | Comparison |
|---|---|---|
| `card_export_format_options_widget.dart:129` | `_minOptionWidth = 148` | `maxWidth >= 148 × scale × 2 + 8` |
| `card_import_source_step_widget.dart:139` | `_minCardWidth = 164` | `maxWidth >= 164 × scale × 2 + 8` |
| `card_import_row_preview_widget.dart:80` | `_twoColumnMinWidth = 280` | `maxWidth < 280 × scale` |
| `card_detail_state_widget.dart:222` | `_minCellWidth = 132` | `(maxWidth − 12) / 2 >= scale(132)` |
| `progress_metric_widget.dart:76` | `minimumCellWidth = 90` | `(maxWidth − 16) / 2` vs `scale(90)` |
| `study_home_deck_item_widget.dart:162` | threshold | scaled before use |
| `guess_option_item_widget.dart:196` | `rowMinHeight = touchTarget` | scaled floor |
| `match_board_grid_widget.dart:45` | min row height | scaled |
| `card_import_stepper_widget.dart:74` | three labels, `TextPainter` | painted at the live scaler |
| `deck_summary_metrics_widget.dart:205` | `needed <= maxWidth` | `TextPainter` at the live scaler |
| `mx_breadcrumb.dart:194` + `:282` | steps that fit | `TextPainter` at the live scaler |
| `mx_button_pair.dart` | row-or-stack | a `RenderBox` reading its own constraint |
| `mx_session_top_bar.dart:187` | `_kChipMaxWidthFraction = 0.4` | a share of the row, not a width |

Thirteen sites, one shape, no literal device width among them. This is the
strongest part of the responsive system and it should be the template for
anything added.

### 5.3 Drift

| Site | What drifts |
|---|---|
| `mx_hero_card.dart:58` | the tier constant applied to a **card** width — see **R3** |
| `deck_list_sliver_widget.dart:73` | gutter written as `AppSpacing.lg` rather than `mxScreenGutter(context)` — the rule `mxScreenGutter`'s own docstring says must not be re-derived |
| `mx_sheet_insets.dart:50–54` | sheet gutter written as `AppSpacing.lg` ×4 — same shape, different surface |
| `library_search_body_widget.dart:17–24` vs `deck_list_sliver_widget.dart:18–26` | two neighbouring lists inside **the same navigation shell** documenting **opposite** rules about the bottom system inset — see **R4** |
| `design_system/ui_kits/memox-app/index.html:50` | `COMPACT_BELOW = 360` is correct, but neither shipped device (412, 375) is below it — see **R10** |

---

## 6 · Fixed-size hotspots

Every non-token fixed extent in `lib/`, classified by whether text can grow into
it:

| Constant | Value | Holds text? | Verdict |
|---|---|---|---|
| `MxBreadcrumb.compactLineHeight` used as `SizedBox(height:)` — `mx_breadcrumb.dart:193` | 32 | **yes**, `bodySmall` | **R2 — clips above scale 2.0** |
| same, used as `SizedBox(height:)` — `deck_subheader_widget.dart:42` | 32 | **yes**, `bodySmall` | **R2 — clips above scale 2.0** |
| same, used as `BoxConstraints(minHeight:)` — `mx_breadcrumb.dart:324`, `mx_breadcrumb_step.dart:144` | 32 / 48 | yes | correct — a floor, grows |
| same, as an unscaled term in `_toolbarHeight` — `mx_content_shell.dart:275` | 32 | reserves for the subline | consistent **only because** the box above is fixed; fixing R2 without this makes the *bar* clip instead |
| `AppGuessPrompt.cardMaxHeight` / `cardMinHeight` | 320 / 180 | yes, `cardPrompt` | correct — a clamp between two measured bounds, with the row demand measured first |
| `_ringSize` (`card_progress_panel_widget.dart:154`) | 64 | no | fine |
| `_stateDotSize` (×2) | 10 | no | fine |
| `progress_week_bar_widget` `trackHeight` | token | no | fine |
| `_firstLineHeight` (`card_history_event_widget.dart:344`) | 16 | yes | correct — scaled at `:246` before use |
| `_kButtonMinWidth` (`deck_study_button_widget.dart:11`) | 80 | yes | correct — a `minWidth`, grows |
| `widthPerNavigationDestination` | 120 | yes | correct — a cap that self-disarms; parity-checked against the CSS kit |
| `MxDialogMetrics.inset` / `actionsInset` | 40 / 24 | n/a | correct — stated so an SDK bump cannot move it silently |
| `kMobileFrameSize` | 393 × 852 | n/a | dev-channel only; see R7 |
| `NavigationBar` height | Material default, **no app token** | yes, labels | ⚠ *unverified against the SDK* — the theme sets no `height`, so the bar's extent and any internal label-scale clamp are Material's. `mx_navigation_bar_test.dart:226` covers 320 @ 2.0; nothing covers 3.0 |

---

## 7 · Text-scale × width matrix

Derived, not measured (§0). `bodySmall` = 12 px with declared `height: 16/12`,
so its line box is exactly `12 × 1.3333 × scale`.

### 7.1 The header's second line — the finding

| scale | `bodySmall` line box | Box (fixed) | Result |
|---|---|---|---|
| 1.0 | 16.0 | 32 | 16 dp of slack |
| 1.3 | 20.8 | 32 | fits |
| 2.0 | **32.0** | 32 | fits with **zero** slack |
| 2.5 | **40.0** | 32 | **8 dp clipped** |
| 3.0 | **48.0** | 32 | **16 dp clipped — roughly the lower quarter of every glyph** |

Width-independent: the box is 32 at 320, 360, 375 and 393 alike. `maxLines: 1` +
`TextOverflow.ellipsis` means `RenderParagraph` sets `_needsClipping` itself, so
this **clips rather than overflows** — no exception, no yellow stripe, and
nothing a `takeException()` assertion can see. That is why the existing 320 ×
2.0 suite is green: 2.0 is the last scale that fits, exactly.

### 7.2 The app bar's own budget

`_toolbarHeight = max(48, scale(titleSize) × titleHeight + 8 + 32 + 16)`.

| Width | Title size | scale 1.0 | 2.0 | 3.0 |
|---|---|---|---|---|
| 320 (compact) | 20 | 81.5 | 106.9 | 132.4 |
| 360 / 375 / 393 | 22 | 84.0 | 112.0 | 140.0 |

The `+ 32` term is `MxBreadcrumb.compactLineHeight` **unscaled**, and `+ 16`
(`_barPadding`) is the slack its own docstring says exists to absorb a subline
growing past 32. That slack is **exactly 16**, and a `bodySmall` subline wants
16 more than 32 at precisely `textScaler` 3.0. So the bar's arithmetic is
correct today only because §7.1's box refuses to grow; the two defects cancel,
and either one fixed alone moves the clip rather than removing it.

### 7.3 Widths at a glance

| | 320 | 360 | 375 | 393 |
|---|---|---|---|---|
| compact tier | **on** | off | off | off |
| screen gutter | 12 | 16 | 16 | 16 |
| content column | 296 | 328 | 343 | 361 |
| app-bar title | 20 | 22 | 22 | 22 |
| card prompt | 26 | 30 | 30 | 30 |
| button h-padding | 12 | 24 | 24 | 24 |
| list-row h-padding | 12 | 16 | 16 | 16 |
| `MxHeroCard` branch | cramped | **cramped** | **cramped** | hugging |
| dialog width | 240 | 280 | 295 | 313 |
| dialog footer width | 192 | 232 | 247 | 265 |
| nav row | edge-to-edge (cap 480 never binds) | | | |
| committed golden? | 4 of 152 | **none** | **none** | 148 of 152 |

The two middle columns are the audit's blind spot and the reason G1 is filed at
P2: **360 and 375 are the two most common phone widths in the world, they take a
different branch from the reference device on at least one rule, and the
repository renders neither of them anywhere.**

### 7.4 320 × scale 2 and × scale 3, where it is critical

| Surface | @ 2.0 | @ 3.0 |
|---|---|---|
| Deck list header second line | fits exactly (0 slack) | **clipped 16 dp** (R2) |
| Deck detail path strip | fits exactly (0 slack) | **clipped 16 dp** (R2) |
| App bar block | 16 dp slack | **0 slack** (§7.2) |
| Confirm dialog | `scrollable: true`, `MxButtonPair` stacks — covered, with the reason written down | same |
| Form dialog | `scrollable: true` — covered | same |
| Study direction sheet | `isScrollControlled` **+ `useSafeArea`** — covered, and the only sheet that is | same |
| Every other tall sheet | `isScrollControlled` **without `useSafeArea`** — **R1** | **R1** |
| Study session top bar | chip capped at 0.4 of the free row, start inset clamped at 0 — covered | same |
| Guess board | card height measured against real row demand, then clamped 180…320 — covered | same |
| Nav bar | test exists at 320 @ 2.0 | **no test** |

---

## 8 · Chrome: navigation, FAB, and list clearance

The structure is two `Scaffold`s on purpose: `AppNavigationShell` owns the
bottom bar, each screen's `MxContentShell` owns the app bar. A `Scaffold` with a
`bottomNavigationBar` removes that height from its body's constraints, so no row
can hide under the bar — the comment says this and the layout depends on it.

`AppSpacing.fabScrollClearance = floatingAction(56) + lg + lg = 88`, derived
rather than chosen, and read by the one screen that has a FAB (deck list). That
part is right.

**R4 is what sits on top of it.** `deck_list_sliver_widget.dart:79`:

```dart
_kListBottomInset + MediaQuery.viewPaddingOf(context).bottom
```

`viewPadding` is the inset **as if no widget had consumed it** — by design it
survives both `MediaQuery.removePadding` (which the `Scaffold` applies to its
body because a `bottomNavigationBar` is present) and `SafeArea` (which
`MxContentShell` wraps the body in). So by the time this line runs, the gesture
strip has already been accounted for twice, and this adds it a third time:
**24 dp on a gesture-nav device, 48 dp with three-button navigation**, of empty
scroll under the last deck card. `library_search_body_widget.dart:17–24`, a
sibling list in the same shell, documents the opposite conclusion — "the shell
has already reserved it" — and adds `lg` only. One of the two is wrong; the
search list is the one that reasons correctly.

`MediaQuery.viewPaddingOf` appears **once** in production outside the sheet
helpers, and this is it.

---

## 9 · Modals, sheets and the keyboard

### 9.1 Keyboard

`resizeToAvoidBottomInset` is never set anywhere in `lib/` — every `Scaffold`
takes the default `true`, and `AndroidManifest.xml` declares
`windowSoftInputMode="adjustResize"`. That pairing is correct and is what makes
`MxContentShell.footer` land on the keyboard's top edge with nothing computed by
hand; the docstring records the measurement that proved
`Scaffold.bottomNavigationBar` could not do the same job.

Sheets get their bottom clearance from one function:

```dart
mxSheetBottomObstruction = max(viewInsets.bottom, viewPadding.bottom)
```

`max`, not a sum, and `viewPadding` not `padding` — both correct, and both
explained. `MxSheetInsets` deliberately adds no `SafeArea` of its own, which
keeps the function idempotent.

### 9.2 R1 — the top edge, which nothing answers

`showModalBottomSheet` with `isScrollControlled: true` removes Flutter's 9/16
height cap, so the sheet can reach the top of the display. The default
`useSafeArea: false` path then puts the sheet's content under the status bar and
any camera cutout. ⚠ *unverified against the SDK*, from the framework's own
documented behaviour and from the fix already in this repo.

`study_entry_screen.dart:206` found this, fixed it, and wrote down the
measurement — *"at 320 dp × 2.0 it does — its 16 dp top padding is less than a
modern cutout, so the title lost glyphs to the status bar."*

The fix was never generalised. Full census of `isScrollControlled: true` sites:

| Site | `useSafeArea` |
|---|---|
| `study_entry_screen.dart:206` (direction chooser) | ✅ true |
| `trash_restore_target_sheet_widget.dart:30` | ✅ true |
| **`shared/widgets/mx_form_sheet.dart:42` — `showMxFormSheet`** | ❌ **absent** |
| `card_bulk_overlays_widget.dart:67` (move target) | ❌ absent |
| `card_export_sheet_widget.dart:75` | ❌ absent |
| `deck_actions_widget.dart:266` (move deck) | ❌ absent |
| `starter_install_widget.dart:33` | ❌ absent |
| `deck_scheduler_change_widget.dart:41` | ❌ absent |
| `deck_reset_progress_widget.dart:32` | ❌ absent |

`showMxFormSheet` is the shared one, and it carries **every form in the app** —
create root deck, create child deck, rename deck, rename tag, the tag filter. A
form is a label, a field, an error line and two buttons; at 320 with `textScaler`
2.0 that is precisely the content the study sheet measured at ~916 dp against a
319 dp cap. The two sheets that *are* protected are the two that were looked at.

The mitigations that exist are partial and incidental: the tag filter caps its
list at 0.5 × screen height, and `MxSheetInsets` adds 16 at the top — which is
the exact number the study-entry comment says is *less than a modern cutout*.

### 9.3 Dialogs

`insetPadding` 40 a side and `actionsPadding` 24 a side, stated on the widget
rather than in `dialogTheme` so the footer width is computable. `MxButtonPair`
reads the constraint it is handed rather than assuming a page gutter — the fix
from #348 — so the row/stack decision is right in a dialog, a sheet and a page
alike. All three dialogs are `scrollable: true`, with the reason written down.
Nothing to file.

### 9.4 R7 — what the E2E channel cannot see

`MobileFrameWidget` overrides the framed `MediaQuery` with:

```dart
size: kMobileFrameSize, padding: .zero, viewPadding: .zero, viewInsets: .zero
```

Framing the size is the point of the widget. Zeroing the other three means the
web build — the project's E2E and visual-regression channel — **can never
reproduce a keyboard, a status bar, a cutout or a gesture strip.** Every finding
in §9 is therefore host-test-only by construction, and no Playwright run can
regress or confirm one. That is a defensible trade (a browser has no soft
keyboard to report anyway) but it should be a written decision rather than a
side effect of a `copyWith`, because it silently narrows what the E2E suite is
evidence for.

---

## 10 · Landscape

**Nothing locks the orientation.** `AndroidManifest.xml` declares no
`android:screenOrientation`; `configChanges` includes `orientation` and
`screenSize`, i.e. the activity handles rotation rather than refusing it; and
`lib/` contains no `SystemChrome.setPreferredOrientations` and no
`Orientation`/`MediaQuery.orientationOf` read at all. So the product **does**
support landscape — by default, not by decision.

What is tested there: `mx_responsive_test.dart` runs `MxContentShell`,
`MxEmptyState`, `MxErrorState`, `MxConfirmDialog` and `MxActionSheet` at
852 × 393, at `textScaler` 2.0, and with a 200 dp keyboard. It is a genuinely
good file — it pins the *failing* case (`isScrollable: false` must still
overflow) so the flag cannot be "simplified" away.

What is not tested there: **any screen.** 852 × 393 appears in exactly one file
in the repository. Filed as G5 at P3 rather than higher, because the shared
components are where a landscape failure actually lands, and those are covered.
The decision to record is whether landscape is supported or merely permitted —
if it is merely permitted, that belongs in `docs/product.md` next to the web
statement, and if it is supported, one screen-level case belongs in the suite.

---

## 11 · Scrollbar

`buildScrollbarTheme(scheme)` — three properties: `thumbColor`
`onSurfaceVariant` at **alpha 0.4**, `radius` `AppRadius.sm`, `thickness`
**4** as a `WidgetStatePropertyAll`.

On the release target this theme reaches exactly **one** widget. Material's
scroll behaviour adds a scrollbar only on desktop/pointer platforms, so on
Android the theme is inert except where a `Scrollbar` is written by hand — and
there is one, `study_card_face_pieces_widget.dart:59`, with an explicit purpose:

> *"Android draws no scrollbar for a bare `SingleChildScrollView`, so nothing
> said there was more to read — which on a card whose whole job is to be read is
> the difference between a hard question and a wrong one."*

So the scrollbar is **not** a mobile design driver in general, and the task's
framing is right — with one exception, and that exception is where R5 lands.

**R5 — the thumb is below the contrast floor.** Computed from the palette
(WCAG 2.x relative luminance, thumb composited over the card paper
`surfaceContainerLow`):

| Mode | Thumb `onSurfaceVariant` @ 0.4 | Composited | vs paper |
|---|---|---|---|
| light | `#596680` over `#FFFFFF` | `#BDC2CC` | **1.79 : 1** |
| dark | `#9395A2` over `#111633` | `#45495F` | **2.00 : 1** |

WCAG 1.4.11 asks 3 : 1 of a UI component's visual boundary. On the study card
this thumb is the *only* signal that the text continues — the widget exists for
that — so it is a component, not decoration.

Two aggravating details:

- **The alpha is a bare `0.4`,** on no token. Every other paint-time alpha under
  `lib/core/theme/components/` reads an `AppStateOpacity` member (`pressed`,
  `focus`, `disabledSurfaceBlend`, …) or is a shadow. `0.4` is not on that
  ladder, and AD-14 §1 is explicit that a neutral should be *precomputed into a
  constant, not a translucent colour placed into a paint slot.*
- **No `thumbVisibility`.** A `Scrollbar` fades its thumb in on scroll and hides
  it at rest, so on the study card the cue is absent at exactly the moment the
  reader needs to learn there is more — which is the stated purpose of the
  widget, half-met.

**R6** is the desktop half of the same theme: `thickness` is a
`WidgetStatePropertyAll`, which by definition returns 4 for every state,
including `hovered` and `dragged`. Material thickens the thumb on hover to make
it draggable; pinning the property removes that, leaving a 4 dp drag target on
the one channel that has a pointer. Low severity — the channel is
development-only — but it is a state resolver that resolves to a constant, which
is the shape M100.23 spent a milestone removing from four other components.

---

## 12 · Coverage

### 12.1 Widths present in the test suite

Histogram of every `Size(w, h)` literal under `test/`:

| Width | Occurrences | Where |
|---|---|---|
| 320 | **80** | stress, compact goldens, geometry, screen tests |
| 393 | 30 | `kReviewSurface`, demo goldens, shell tests |
| 390 | 28 | `host_widget_app.dart` default (390 × 780) |
| 360 | **30** | `mx_navigation_bar_test` default, three others |
| 412 | 14 | Android viewport cases |
| **375** | **1** | `mx_card_mobile_test.dart` only |
| 852 (landscape) | 1 | `mx_responsive_test.dart` |

`mx_card_mobile_test.dart` is the one file that runs the exact matrix this audit
asks for — `[320, 360, 375, 393]` × light/dark — and its header argues the case
for a structural test over a picture correctly. It covers **`MxCard` and nothing
else.**

### 12.2 The harness split that matters

Two default surfaces are in use and they **straddle the effective `MxHeroCard`
threshold of 392**:

- `test/support/study_render.dart` → `kReviewSurface = 393 × 852` (goldens, demo)
- `test/helpers/app_harness/host_widget_app.dart` → **390 × 780** (widget tests)

At 390 the content column is 358 → cramped; at 393 it is 361 → hugging. So a
widget test and a golden of the same hero render **different branches**, and
neither harness can see the other's. This is the same class of bug
`MxHeroCard`'s own docstring says it was built to make unreachable — *"the
golden had quietly stamped the wrong branch"* — moved one level up, from *where*
the measurement happens to *what it is compared against*.

### 12.3 Goldens

| | Count |
|---|---|
| Committed screen goldens (`test/demo/goldens/`) | **152** |
| …at a compact width | **4** — `card_detail_320_x2_vi`, `card_detail_320_x2_vi_scrolled`, `card_export_compact_2x_light`, `tag_catalog_320_x2` |
| …at 360 or 375 | **0** |
| Shared-component compact goldens | 4 (`compact_screen`, `compact_card_prompt` × light/dark, at 320 × 568) |
| Gallery rows (`SCREENS`) | 60, all 393 × 852 by rule, enforced by `build_screen_gallery.py` |

The gallery's single-surface rule is correct and should stay. The gap is not in
the gallery — it is that outside it, the compact tier has pictures for three
screens and structural tests for the rest, while 360 and 375 have neither.

### 12.4 What *is* well covered, and should be left alone

- `compact_scale_test.dart` — asserts both what changes **and what does not**,
  including `isCompact(359.9)` / `isCompact(360)` boundary behaviour.
- `mx_stress_test.dart` — every shared component at 320 × 640, `textScaler` 2.0,
  Vietnamese copy, light and dark, asserting no exception **and** tap-target
  size. The reasoning in its header is the best statement of test intent in the
  repository.
- `mx_responsive_test.dart` — landscape, keyboard, and the pinned negative case.
- `css_scale_parity_test.dart` — both breakpoints pinned across Dart and CSS.
- Six feature geometry tests that read `mxScreenGutter` rather than restating 16.

---

## 13 · Severity registry

Each finding: the claim, the evidence a reader can check without a toolchain,
and the **closure test** — the assertion that must exist and fail on today's
code before the fix, and pass after.

### P0

None. No finding in this audit produces a crash, a data loss, an unreachable
control at a shipped width and scale, or a touch target below 48 dp.

### P1

---

**R1 · Seven `isScrollControlled` sheets can lay content under the status bar**

*Evidence.* §9.2 census. `mx_form_sheet.dart:40–43` opens with
`isScrollControlled: true` and no `useSafeArea`; `study_entry_screen.dart:194–206`
opens with both and records the measurement that made the second necessary. The
top padding `MxSheetInsets` supplies is 16, which that same comment states is
less than a modern cutout.

*Blast radius.* Every form in the app (create root deck, create child deck,
rename deck, rename tag, tag filter) plus move-card, move-deck, export,
starter install, scheduler change and reset progress.

*Closure test.* `test/shared/widgets/mx_sheet_safe_area_test.dart`, new. For each
of the seven entry points, at 320 × 568 with `padding: EdgeInsets.only(top: 44)`
and `textScaler` 2.0: pump, then assert
`tester.getTopLeft(find.byType(<sheet content>)).dy >= MediaQuery.paddingOf(context).top`.
Must fail on `showMxFormSheet` today.

*Fix shape.* `useSafeArea: true` on `showMxFormSheet` and on the six direct
calls. It is one argument; there is no layout redesign in it.

---

**R2 · The header's second line is a fixed 32 dp box holding growable text**

*Evidence.* Two sites, one constant:

- `mx_breadcrumb.dart:192–193` — `_buildSingleTarget` wraps the whole strip in
  `SizedBox(height: widget.lineHeight)`. This is the branch taken whenever
  `onUp != null`, which is **`DeckPathWidget` and only `DeckPathWidget`**
  (`deck_path_widget.dart:81, 87` passes `lineHeight: compactLineHeight` = 32
  and `onUp`). The three card-side callers pass no `onUp`, take the
  `BoxConstraints(minHeight:)` branch at `:324`, and grow correctly.
- `deck_subheader_widget.dart:41–42` — the root branch returns
  `SizedBox(height: MxBreadcrumb.compactLineHeight)` around a `bodySmall` `Text`.

Arithmetic in §7.1: `bodySmall` is 12 px × `height: 16/12`, so the line box is
exactly 32 at `textScaler` 2.0 and 40 / 48 at 2.5 / 3.0. `maxLines: 1` with
`TextOverflow.ellipsis` makes `RenderParagraph` clip itself, so there is **no
exception and no overflow stripe** — which is why every existing 320 × 2.0
assertion is green: 2.0 is the last scale that fits, to the pixel.

*Blast radius.* The Library landing screen (root branch) and every deck detail
screen (path branch) — the two most-visited surfaces in the app.

*Closure test.* `test/shared/widgets/mx_breadcrumb_text_scale_test.dart`, new.
At `textScaler` 2.5 and 3.0, pump `DeckSubheaderWidget` (root snapshot) and
`DeckPathWidget`, then assert
`tester.getSize(find.byType(Text).first).height >= painter.height`
where `painter` is a `TextPainter` laid out with the same style and scaler —
i.e. the box is at least as tall as the line it holds. Must fail at 2.5 today.

*Fix shape.* `BoxConstraints(minHeight: lineHeight)` in place of
`SizedBox(height: lineHeight)` at both sites — the same shape
`mx_breadcrumb.dart:324` already uses. **And in the same commit**,
`_toolbarHeight` must scale its subline term (`scaler.scale(compactLineHeight)`
rather than the bare constant), or the clip moves from the text to the app bar:
§7.2 shows the `_barPadding` slack is exactly 16 and is exactly spent at
`textScaler` 3.0.

### P2

---

**R3 · One tier constant, two measurement bases**

*Evidence.* `mx_hero_card.dart:58` passes `constraints.maxWidth` — the card,
which is screen − 2 × gutter — to `AppBreakpoints.isCompact`, a constant defined
and documented as a **screen** width. Solving `screen − 32 < 360` gives an
effective threshold of **392 dp**. Table in §4: 360, 375 and 390 take the
cramped branch; 393 does not. `hero_action_width_test.dart:37–40` states the
1 dp margin at 393 explicitly and covers 320 and 393 only. §12.2: the two test
harness defaults sit either side of the effective threshold.

*Why it is P2, not P3.* This is not merely fragile — it means the hero primary
renders stretched on most phones in circulation and hugging on the one device
every committed picture is shot on, so the golden set systematically shows the
minority branch.

*Closure test.* Extend `hero_action_width_test.dart` to
`const widths = [320, 360, 375, 390, 393]` and assert the branch for each
against a stated table. Today's code will make 360/375/390 stretch; the test
then records that as intended, or the constant is fixed and the test records
that instead.

*Decision required before fixing.* Either
**(a)** the rule is "the *screen* is narrow" → read `MediaQuery.sizeOf().width`
like the other five sites, and `MxHeroCard`'s `LayoutBuilder` is only for
`isCramped`'s *value*, or
**(b)** the rule is "the *card* is narrow" → it needs its own named constant
(e.g. `AppBreakpoints.compactContent`), because reusing the screen tier is what
makes the effective number invisible. **(a)** is the smaller change and matches
what every neighbouring rule does; **(b)** is what the docstring currently
argues for. Owner's call — do not pick it inside a fix commit.

---

**R4 · The deck list adds the system inset a second time**

*Evidence.* §8. `deck_list_sliver_widget.dart:79` adds
`MediaQuery.viewPaddingOf(context).bottom` to `fabScrollClearance`, inside a
`Scaffold` whose `bottomNavigationBar` already removed the bottom padding and
inside `MxContentShell`'s `SafeArea`. `viewPadding` survives both by definition.
`library_search_body_widget.dart:17–24`, in the same shell, documents the
opposite rule and adds `lg` only. Cost: 24 dp (gesture) to 48 dp (three-button)
of dead scroll under the last card.

*Closure test.* `test/features/deck/presentation/deck_list_bottom_inset_test.dart`,
new. Pump the deck list through the real shell at 393 × 852 with
`viewPadding: EdgeInsets.only(bottom: 48)`, scroll to the end, and assert the
gap between the last card's bottom and the viewport bottom equals
`AppSpacing.fabScrollClearance` — not 88 + 48.

*Fix shape.* Delete the `viewPaddingOf` term. Then the two lists agree and the
rule lives in one comment instead of two contradictory ones.

---

**R5 · The scrollbar thumb is below the contrast floor where it is the only cue**

*Evidence.* §11. Computed 1.79 : 1 light, 2.00 : 1 dark against
`surfaceContainerLow`. Bare `0.4` alpha, not on `AppStateOpacity`, against
AD-14 §1's precompute rule. No `thumbVisibility`, so the cue is absent at rest —
half-defeating `study_card_face_pieces_widget.dart:59`'s stated purpose.

*Closure test.* Two. **(i)** Add `Scrollbar` to the contrast suite that already
covers control grounds: assert the composited thumb reaches 3 : 1 against
`surfaceContainerLow` in light, dark and both high-contrast themes. **(ii)** A
widget test on the study card face asserting the thumb is painted with a
scrollable that has not been touched (`thumbVisibility: true`).

*Fix shape.* Precompute the thumb as a constant blended against the paper, on
the model `app_chip_theme.dart:99` already uses, at whatever alpha reaches 3 : 1;
put the alpha on `AppStateOpacity` or state why it is not a state layer; set
`thumbVisibility: true` at the one call site that needs it (not in the theme —
the desktop channel should keep the fading thumb).

---

**G1 · 375 dp is tested once and 360 dp never at screen level**

*Evidence.* §12.1. `375` occurs in one file (`mx_card_mobile_test.dart`); `360`
is a default surface in `mx_navigation_bar_test.dart` and appears in two others;
neither is a screen-level surface anywhere, and neither has a golden.

*Closure test.* This is the gap, so the test *is* the fix: promote
`mx_card_mobile_test.dart`'s `const widths = [320, 360, 375, 393]` to a shared
`test/support/phone_widths.dart` and drive at least the three shell-level
geometry suites (deck list, study home, progress) over it, asserting gutters,
the hero branch and no exception. No new goldens — the repo's own rule is that
another width belongs to the test that measures it, not to the gallery.

---

**G2 · No test asserts a sheet's top edge**, and **G3 · the hero test pins the
stated threshold, not the effective one** — both closed by R1's and R3's tests
above.

---

**G4 · 4 of 152 screen goldens are compact.** Not closed by a test; closed by a
decision. Either the compact tier is a rendering promise for the six uncovered
screens — in which case they need the same structural geometry tests §12.4
already applies elsewhere, not more pictures — or it is a safety net for
components only, which is what `app_breakpoints.dart`'s own docstring says
("*a component that degrades below the floor is cheap, while a whole screen laid
out for a size nobody ships is what was expensive*"). If that docstring is the
policy, **G4 should be closed as won't-fix and the policy quoted in the WBS** so
the next audit does not re-open it.

### P3

| # | Finding | Evidence | Closure |
|---|---|---|---|
| R6 | Scrollbar `thickness` constant across states | `app_scrollbar_theme.dart:15` — `WidgetStatePropertyAll` resolves to 4 for `hovered`/`dragged` too | Resolver test asserting `thickness.resolve({hovered})` > resting |
| R7 | Web frame zeroes `viewInsets`/`viewPadding`/`padding` | `mobile_frame_widget.dart:62–67` | No test — record the decision in `docs/architecture.md` beside AD-04, so "the E2E channel is not evidence for keyboard or inset behaviour" is written rather than inferred |
| R8 | `MediaQuery.of` in `mxSheetBottomObstruction` | `mx_sheet_insets.dart:26` — one of only two `MediaQuery.of` in `lib/`; subscribes to size, brightness and text scale to read two insets | Swap to `viewInsetsOf` + `viewPaddingOf`; no behaviour change, so a rebuild-count test or nothing |
| R9 | `medium` caps 4 surfaces of ~26 | §2.3 | Not a tablet redesign. Record in the WBS which surfaces cap and why the rest do not, so the answer above 600 dp is a decision rather than an accident |
| R10 | Kit publishes the compact tier but applies nothing | `design_system/tokens/layout.css:4`; no `@media` anywhere in `design_system/`; devices are 412 and 375 (`index.html:45–46`); kit compact changes the title and the prompt but **not** button padding, which the Dart scale does | Add a 320 device to `DEVICES`, and either a compact gutter token or a note that the kit's compact face is partial |
| G5 | No screen-level landscape case | §10 | Decide support-vs-permit first; then one case, or a line in `docs/product.md` |
| G6 | Widgetbook has no compact or text-scale knob | `widgetbook/lib/tokens/scale_sections.dart` renders the breakpoints as swatches only | A width/scale addon on the shared-component stories |

---

## 14 · Implementation order

Ordered so that each step is independently reviewable and no step is blocked by
a decision that has not been made yet.

| # | Step | Files | Gate |
|---|---|---|---|
| 1 | **R1** — `useSafeArea: true` on seven sheets | `mx_form_sheet.dart`, `card_bulk_overlays_widget.dart`, `card_export_sheet_widget.dart`, `deck_actions_widget.dart`, `starter_install_widget.dart`, `deck_scheduler_change_widget.dart`, `deck_reset_progress_widget.dart` + new `mx_sheet_safe_area_test.dart` | new test red → green; existing sheet goldens unchanged (no top padding in the golden harness) |
| 2 | **R2** — the fixed 32 dp box, **both halves in one commit** | `mx_breadcrumb.dart:193`, `deck_subheader_widget.dart:42`, `mx_content_shell.dart:275` + new `mx_breadcrumb_text_scale_test.dart` | new test red → green at 2.5 and 3.0; **regenerate goldens** — the app bar's height is unchanged at scale 1.0 by this arithmetic, so a golden diff here means the fix moved something it should not have |
| 3 | **R4** — drop the double inset | `deck_list_sliver_widget.dart:79` + new `deck_list_bottom_inset_test.dart` | new test red → green; deck-list goldens unchanged (the harness reports no `viewPadding`) |
| 4 | **G1** — the width matrix | new `test/support/phone_widths.dart`; extend `deck_list`, `study_home_geometry`, `progress_screen_geometry` | green at 320/360/375/393; expect it to **record** R3's current behaviour, not fix it |
| 5 | **R3 decision, then fix** | `mx_hero_card.dart` or `app_breakpoints.dart`; extend `hero_action_width_test.dart` | blocked on the owner's (a)/(b) choice in §13 |
| 6 | **R5** — the thumb | `app_scrollbar_theme.dart`, `study_card_face_pieces_widget.dart`, contrast suite | 3 : 1 in four themes; **regenerate goldens** — the study card face changes |
| 7 | **R6 / R8 / R10** — the cheap ones | `app_scrollbar_theme.dart`, `mx_sheet_insets.dart`, `design_system/ui_kits/memox-app/index.html` | analyze + existing suites |
| 8 | **R7 / R9 / G4 / G5** — decisions, not code | `docs/architecture.md` (AD-04 note), `docs/wbs.md` | `check_docs.py` |

**Steps 2 and 6 move committed pictures**, so each ends with

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

and a republish to the existing gallery URL, on Linux — `dart_test.yaml` and
`CLAUDE.md` both make Linux the only authoring platform, and this session could
not have regenerated them in any case (§0).

## 15 · Decisions this audit needs from the owner

1. **R3 (a) or (b)** — is the hero's rule about the screen or about the card? A
   fix cannot be written until this is answered, and answering it inside the fix
   commit is how the next audit finds the same ambiguity with a different number.
2. **Landscape: supported or permitted?** Nothing locks it, one file tests it,
   no screen renders in it. Either answer is fine; the absence of one is not.
3. **G4** — is the compact tier a per-component safety net (which is what
   `app_breakpoints.dart` says) or a screen-level rendering promise (which is
   what four screen goldens at 320 imply)? Whichever it is, it should be written
   in one place, because right now the code says one thing and the golden set
   says the other.
4. **R9** — above 600 dp, is a half-capped app acceptable? "Yes, AD-04 says
   phone" is a complete answer; it is just not currently written down anywhere
   that a reader of the four capped screens would find it.
