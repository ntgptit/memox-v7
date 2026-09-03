# A18 — Responsive / compact / mobile-density deep audit

| | |
|---|---|
| BASE_SHA | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` — *refactor(theme): the dark card stops glowing* (M100.35, #435) |
| Merged onto | `9d2f4b47` — eight audits (A7, A8, A10–A14, A17) landed on `main` mid-audit. **All eight are report-only: `git diff --stat 3207e7b7..9d2f4b47` is 8 files, all under `docs/reviews/`.** Not one `lib/`, `test/` or `design_system/` file moved, so the BASE_SHA above is still the code state this report describes |
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
same reason. `check_docs.py --quiet` **was** run and passes. This is a
documentation-only change; the repo's own plan builder classifies a docs-only
diff as verifying nothing, so nothing was skipped that CI will not itself run.

**One sibling audit did read the SDK, and it corrected this one.**
`a8-navigation-chrome-audit.md` landed on `main` while this audit was in
progress and cites the pinned framework directly — `app_bar.dart:43-44`
(`_kMaxTitleTextScaleFactor = 1.34`, applied at `:1091-1097`),
`navigation_bar.dart:31` (`_kMaxLabelTextScaleFactor = 1.3`, applied at
`:505-512`) and `navigation_bar.dart:291` (the bar's own `SafeArea`). Those
three readings resolve every ⚠ item this audit had left open about the app bar
and the navigation bar, and **one of them falsified a P1 finding written here
before the merge.** Where A8 read the SDK its reading is adopted and mine
deferred; §15 lists exactly what was withdrawn, downgraded or handed over, and
why. A finding that survives that pass is one this audit found and A8 did not
look at.

---

## 1 · Verdict

**The breakpoint model is sound, deliberately small, and honestly documented.
The system around it is in better shape than this audit expected, and the three
findings that survived review are all at its edges rather than in it: a shared
sheet helper that answers the bottom edge and forgets the top, one constant
compared against two different widths, and a scrollbar tuned for a desktop it
does not ship to while carrying a mobile job it cannot do at 1.79 : 1.**

Two things this audit first filed as defects were withdrawn on review against
the sibling audits that landed mid-pass — one of them a P1. §15 is the
reconciliation, and it is part of the finding set rather than a note at the
back: a report that quietly drops a claim it made is worse than one that never
made it.

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
- **The app never clamps `textScaler`.** 43 references across `lib/`, and not
  one is a `TextScaler.linear`, a clamp or a `MediaQuery(textScaler:)`
  override. Fifteen call sites *scale a threshold by the live scaler* before
  comparing it — the correct shape, and unusually consistent. (Flutter clamps
  it in two slots of its own — the `AppBar` title at 1.34 and navigation-bar
  labels at 1.3 — which §7.1 uses and A8's **G10** files as unstated. That is a
  framework ceiling, not an app decision, and it does not weaken this bullet:
  no app code takes the user's setting away.)
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
| R3 | `MxHeroCard` compares a **card** width against a **screen** constant → the effective threshold is 392 dp; 360 / 375 / 390 take one branch and 393 takes the other, and the two test harnesses straddle it | **P2** |
| R5 | Scrollbar thumb measures **1.79 : 1** light / **2.00 : 1** dark on the card paper, from a bare `0.4` alpha that is on no token — on the one surface where the scrollbar *is* the "there is more to read" cue | **P2** |
| R2′ | The one breadcrumb path that sizes itself with a **fixed** `SizedBox(height:)` instead of a `minHeight` — safe today only because of the 1.34 AppBar clamp, and a hidden precondition on A8's P1-02 option (B) | P3 |
| R6 | `ScrollbarThemeData.thickness` is a `WidgetStatePropertyAll`, so it is 4 dp in **every** state — no hover/drag thickening on the channel that has a pointer | P3 |
| R7 | `MobileFrameWidget` zeroes `viewInsets`, `viewPadding` **and** `padding` → the E2E/visual channel cannot reproduce a keyboard or a cutout at all | P3 |
| R8 | `mxSheetBottomObstruction` uses `MediaQuery.of` — one of only two full-data subscriptions in `lib/` | P3 |
| R9 | `AppBreakpoints.medium` caps 4 surfaces of ~26 → above 600 dp the app is half-capped, by accretion rather than by decision | P3 |
| R10 | Kit parity: the CSS kit publishes the compact tokens but has **no rule that applies them**, no compact gutter token, and neither shipped device is below 360 | P3 |
| ~~R4~~ | The deck list's extra `viewPadding.bottom` — **already filed as A8's P3-20**, with a sharper mechanism than this audit had. Handed over, not restated (§15) | — |

**R2 was written as a P1 and is withdrawn.** It claimed the header's second line
clips above `textScaler` 2.0. It does not: `AppBar` clamps its title slot — and
`titleSubline` is inside that slot — to **1.34×**, so the `bodySmall` line box
tops out at 12 × 1.3333 × 1.34 = **21.4 dp** inside its 32 dp box and never
reaches it. The arithmetic in §7.1 was right; the premise that the ambient
scaler reaches that text was wrong, and it was wrong for exactly the reason §0
gives — no SDK to read. What survives is R2′, at P3.

And the coverage holes that let R1, R3 and R5 exist unnoticed:

| # | Gap | Sev |
|---|---|---|
| G2 | No test asserts a sheet's top edge against the status bar, at any width or scale — the class R1 lives in | **P2** |
| G3 | `hero_action_width_test` pins 320 and 393 only, i.e. both sides of the *stated* threshold and neither side of the *effective* one | P2 |
| G4 | **4 of 152** committed screen goldens are at a compact width, covering 3 screens; Library, Study Home, Progress, Settings, Card list and the study session have no compact picture at all | P2 |
| G5 | No screen-level landscape test, though nothing in the manifest or in `lib/` locks the orientation | P3 |
| G6 | Widgetbook renders the breakpoint tokens as swatches (`scale_sections.dart`) but has no compact-width or text-scale knob, so the tier is not reachable in the catalog | P3 |
| ~~G1~~ | 375 dp untested — **already filed as A8's P3-21.** This audit adds only that 360 dp is no better off at screen level, and §13 keeps the shared-matrix remedy because it closes G3 in the same move (A8 · P3-21) | — |

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
| `library_search_body_widget.dart:17–24` vs `deck_list_sliver_widget.dart:18–26` | two neighbouring lists inside **the same navigation shell** documenting **opposite** rules about the bottom system inset, and reusing the same private name `_kListBottomInset` for two different numbers. A8 filed both halves — **P3-20** and **P3-22**; §8 and §15 defer to them |
| `design_system/ui_kits/memox-app/index.html:50` | `COMPACT_BELOW = 360` is correct, but neither shipped device (412, 375) is below it — see **R10** |

---

## 6 · Fixed-size hotspots

Every non-token fixed extent in `lib/`, classified by whether text can grow into
it:

| Constant | Value | Holds text? | Verdict |
|---|---|---|---|
| `MxBreadcrumb.compactLineHeight` used as `SizedBox(height:)` — `mx_breadcrumb.dart:193` | 32 | **yes**, `bodySmall` | **R2′** — safe at 21.4 dp under the 1.34 clamp; the only breadcrumb path with a fixed height rather than a floor |
| same, used as `SizedBox(height:)` — `deck_subheader_widget.dart:42` | 32 | **yes**, `bodySmall` | same — safe under the clamp, for the same reason and by the same margin |
| same, used as `BoxConstraints(minHeight:)` — `mx_breadcrumb.dart:324`, `mx_breadcrumb_step.dart:144` | 32 / 48 | yes | correct — a floor, grows; **this is the shape the two rows above should have** |
| same, as an unscaled term in `_toolbarHeight` — `mx_content_shell.dart:275` | 32 | reserves for the subline | correct term, wrong scaler on the *other* term — **A8's P2-13**, over-reservation not exhaustion |
| `AppGuessPrompt.cardMaxHeight` / `cardMinHeight` | 320 / 180 | yes, `cardPrompt` | correct — a clamp between two measured bounds, with the row demand measured first |
| `_ringSize` (`card_progress_panel_widget.dart:154`) | 64 | no | fine |
| `_stateDotSize` (×2) | 10 | no | fine |
| `progress_week_bar_widget` `trackHeight` | token | no | fine |
| `_firstLineHeight` (`card_history_event_widget.dart:344`) | 16 | yes | correct — scaled at `:246` before use |
| `_kButtonMinWidth` (`deck_study_button_widget.dart:11`) | 80 | yes | correct — a `minWidth`, grows |
| `widthPerNavigationDestination` | 120 | yes | correct — a cap that self-disarms; parity-checked against the CSS kit |
| `MxDialogMetrics.inset` / `actionsInset` | 40 / 24 | n/a | correct — stated so an SDK bump cannot move it silently |
| `kMobileFrameSize` | 393 × 852 | n/a | dev-channel only; see R7 |
| `NavigationBar` height | Material default, **no app token** | yes, labels | Resolved by A8: labels are clamped to **1.3×** (`navigation_bar.dart:31`, applied `:505-512`), so the default height is safe at any user setting. A8 files the *unstated assumption* as its G10 — nothing in this repo pins either SDK clamp |

---

## 7 · Text-scale × width matrix

Derived, not measured (§0). `bodySmall` = 12 px with declared `height: 16/12`,
so its line box is exactly `12 × 1.3333 × scale`.

### 7.1 The header's second line — where the clamp lands

The box is a fixed 32 dp; the text is `bodySmall`, 12 px with a declared
`height: 16/12`. So the question is only ever which scaler reaches it — and
because both implementations sit in `MxContentShell.titleSubline`, which
`_buildTitle` puts inside `AppBar`'s title slot, the answer is the clamp:

| Effective scaler | `bodySmall` line box | Box (fixed) | Result |
|---|---|---|---|
| 1.0 | 16.0 | 32 | 16 dp of slack |
| 1.3 | 20.8 | 32 | fits |
| **1.34 — the ceiling** (`app_bar.dart:43-44`) | **21.4** | 32 | **fits, 10.6 dp to spare, at every user setting** |
| *(2.0, unreachable here)* | *32.0* | 32 | *would fit with zero slack* |
| *(2.5 / 3.0, unreachable here)* | *40.0 / 48.0* | 32 | *would clip 8 / 16 dp* |

Width-independent: the box is 32 at 320, 360, 375 and 393 alike, and the clamp
is width-independent too. **So there is no clip, at any width and any user text
setting** — the rows in italics are what would happen if this text were ever
moved out of the title slot, which is R2′ and which A8's P1-02 option (B) is
one plausible route to.

Worth stating because it is the trap: `maxLines: 1` + `TextOverflow.ellipsis`
means `RenderParagraph` would set `_needsClipping` itself and **clip rather than
overflow** — no exception, no yellow stripe, nothing a `takeException()`
assertion could see. A fixed box holding growable text is therefore a defect
that tests cannot find by accident; here it is disarmed by an SDK constant that
nothing in the repository states.

### 7.2 The app bar's own budget — deferred to A8's P2-13

`_toolbarHeight = max(48, scale(titleSize) × titleHeight + 8 + 32 + 16)` reads
the **ambient** scaler for its title term while the content it measures is
clamped at 1.34. A8 §9.4 has the full table and files it as **P2-13**: the
error is 34.5 dp of *dead slack* at a user setting of 2.0, not a shortfall. This
audit's earlier reading — that `_barPadding`'s 16 dp was exactly exhausted at
3.0 — assumed the unclamped scaler reached both terms and is withdrawn. The
`+ 32` term is correct precisely because the subline cannot grow.

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

The two middle columns are the audit's blind spot: **360 and 375 are the two
most common phone widths in the world, they take a different branch from the
reference device on at least one rule (R3), and the repository renders neither
of them anywhere.** A8 filed the 375 half as its P3-21; the reason this audit
still asks for a shared width matrix is G3 — the same fixture is what makes R3
visible, and R3 is invisible at both of the widths currently tested.

### 7.4 320 × scale 2 and × scale 3, where it is critical

A user setting of 2.0 or 3.0 does not reach every surface — §7.1's clamp table
is the reason, and it is what makes two of these rows read the opposite way to
how they were first written.

| Surface | @ 2.0 | @ 3.0 |
|---|---|---|
| Deck list header second line | renders at **1.34** — fits, 10.6 dp spare | same; clamp is absolute |
| Deck detail path strip | renders at **1.34** — fits | same |
| App bar block | **34.5 dp of dead slack** (A8 P2-13) | more |
| Card list path strip, one tap deeper | **unclamped, 2.0** — same component, different scale (A8 P1-02) | unclamped, 3.0 |
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

**The extra term at `deck_list_sliver_widget.dart:79` is A8's P3-20, and A8 got
the mechanism right where this audit did not.**

```dart
_kListBottomInset + MediaQuery.viewPaddingOf(context).bottom
```

This audit first read that as a flat 24–48 dp of dead scroll on every device,
reasoning that `viewPadding` survives both the `Scaffold`'s `removePadding` and
`MxContentShell`'s `SafeArea`. **That is wrong**, and A8 §11 shows why:
`removePadding` leaves `max(0, viewPadding.bottom − padding.bottom)`, so inside
a shell branch — where the navigation bar has already paid the gesture inset in
its own `SafeArea` (`navigation_bar.dart:291`) — the term is normally **0**. It
goes non-zero only while the keyboard is up, and then it is a little extra tail
inset rather than a defect. What remains true is that the comment beside it
claims a need the navigation bar has already met, and that
`library_search_body_widget.dart:17–24` documents the opposite rule under the
same private name. Both halves are filed as A8's **P3-20** and **P3-22**; this
audit adds nothing and defers.

`MediaQuery.viewPaddingOf` appears **once** in production outside the sheet
helpers, and this is it — which is the one fact worth keeping from the original
reading, because it means there is exactly one place to change.

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

Counted by **width**, summing every height — A8 §12 counts the same literals by
full `Size(w, h)` pair, so its 320×568 (49) and 360×640 (27) are subsets of the
rows below rather than different readings:

| Width | Occurrences | Where |
|---|---|---|
| 320 | **80** | stress, compact goldens, geometry, screen tests (568 / 640 / 720 / 852 / 1400) |
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

**R2 · withdrawn — see §7.1.** It is reproduced in §15 with the reason, rather
than deleted, because the arithmetic is still the arithmetic anyone re-deriving
R2′ will do. What replaced it is R2′, at P3, below.

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

**R4 · handed to A8's P3-20 — see §8.** The mechanism this audit proposed was
wrong and A8's is right; restating it here at a different severity is exactly
the two-copies-one-drifts failure `docs/document-conventions.md` exists to
prevent.

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

**G3 · the hero test pins the stated threshold, not the effective one — and the
width matrix is what closes it**

*Evidence.* §12.1. `375` occurs in one file (`mx_card_mobile_test.dart`); `360`
is a default surface in `mx_navigation_bar_test.dart` and appears in two others;
neither is a screen-level surface anywhere, and neither has a golden.
`hero_action_width_test.dart` pins 320 and 393 — the two widths at which R3 is
invisible. A8's **P3-21** already files the 375 half of this as a coverage gap;
what this audit adds is *why it now has a defect attached to it.*

*Closure test.* Promote `mx_card_mobile_test.dart`'s
`const widths = [320, 360, 375, 393]` to a shared
`test/support/phone_widths.dart`, add 390 (the `host_widget_app` default, §12.2),
and drive `hero_action_width_test.dart` plus at least the three shell-level
geometry suites (deck list, study home, progress) over it — asserting gutters,
the hero branch and no exception. No new goldens: the repo's own rule is that
another width belongs to the test that measures it, not to the gallery.

---

**G2 · No test asserts a sheet's top edge** — closed by R1's test above.

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
| R2′ | The one breadcrumb path sized by a fixed `SizedBox(height:)` rather than a `minHeight` | `mx_breadcrumb.dart:193` (`_buildSingleTarget`, the branch `DeckPathWidget` always takes) and `deck_subheader_widget.dart:42`; §7.1's clamp table is why it is safe | **A precondition, not a test.** If A8's **P1-02** is settled as option (B) — the strip form wins, the path moves to `subheader` — that text becomes unclamped and a fixed box is the wrong shape at 48 dp too (`bodySmall` measures exactly 48 at scale 3.0, zero slack). Whoever executes P1-02 should change these two to `BoxConstraints(minHeight:)` in the same commit, matching `mx_breadcrumb.dart:324`. Under option (A) it is a no-op |
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
| 2 | **G3** — the shared width matrix | new `test/support/phone_widths.dart`; extend `hero_action_width_test`, `deck_list`, `study_home_geometry`, `progress_screen_geometry` | green at 320/360/375/390/393; expect it to **record** R3's current behaviour, not fix it. Closes A8's P3-21 in the same move |
| 3 | **R3 decision, then fix** | `mx_hero_card.dart` or `app_breakpoints.dart`; the matrix from step 2 | blocked on the owner's (a)/(b) choice in §13 |
| 4 | **R5** — the thumb | `app_scrollbar_theme.dart`, `study_card_face_pieces_widget.dart`, contrast suite | 3 : 1 in four themes; **regenerate goldens** — the study card face changes |
| 5 | **R6 / R8 / R10** — the cheap ones | `app_scrollbar_theme.dart`, `mx_sheet_insets.dart`, `design_system/ui_kits/memox-app/index.html` | analyze + existing suites |
| 6 | **R7 / R9 / G4 / G5** — decisions, not code | `docs/architecture.md` (AD-04 note), `docs/wbs.md` | `check_docs.py` |
| — | **R2′** | `mx_breadcrumb.dart:193`, `deck_subheader_widget.dart:42` | **Not a step of its own.** It rides along with whoever executes A8's P1-02, and only if that lands as option (B) |
| — | **R4 / G1 / §7.2** | — | Owned by A8 as P3-20 / P3-21 / P2-13. Do not open a second change for them |

**Step 4 moves committed pictures**, so it ends with

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

and a republish to the existing gallery URL, on Linux — `dart_test.yaml` and
`CLAUDE.md` both make Linux the only authoring platform, and this session could
not have regenerated them in any case (§0).

**Sequence note.** Steps 1, 4 and 5 are independent of every open decision and
of A8 entirely; they can land today. Step 2 is a test-only change and is worth
landing before step 3 so the decision is taken against measured behaviour rather
than against this report's arithmetic.

## 15 · Relationship to the sibling audits

Eight audits landed on `main` while this one was in progress (§ header). Two
overlap it — **A8 · navigation and screen chrome** and **A14 · shared
compositions** — and A8 overlaps it heavily, because `MxContentShell`,
`MxBreadcrumb`, `MxNavigationBar` and the deck list's bottom inset are its
subject as much as they are this audit's. `docs/document-conventions.md` says
one fact lives in exactly one place, so the reconciliation is part of the
deliverable rather than an appendix to it.

### 15.1 Withdrawn, because A8 read the SDK and this audit could not

**R2 — "the header's second line clips above `textScaler` 2.0" — is false.**

The arithmetic was right: `bodySmall` is 12 px × `height: 16/12`, so its line
box is 16 × the effective scaler, and both implementations
(`mx_breadcrumb.dart:193`, `deck_subheader_widget.dart:42`) put it in a fixed
32 dp box. At an *ambient* scaler of 2.5 that is 40 into 32, and
`RenderParagraph` would clip it silently.

The premise was wrong. Both sites reach the screen through
`MxContentShell.titleSubline`, which `_buildTitle` composes **inside `AppBar`'s
title slot**, and `AppBar` wraps that slot in a clamp of **1.34×**
(`_kMaxTitleTextScaleFactor`, `app_bar.dart:43-44`, applied `:1091-1097` — A8's
citation, at the pinned SDK). 12 × 1.3333 × 1.34 = **21.4 dp** into a 32 dp box,
at every user setting, at every width. There is no clip and there never was.

`onUp != null` is the only route into `_buildSingleTarget`, and `DeckPathWidget`
is its only caller, and it is only ever a `titleSubline` — so there is no third
site where the ambient scaler reaches that box. The finding is dead, not merely
mitigated.

**Why it is written down rather than deleted.** The fixed box is still the only
breadcrumb path sized by a `SizedBox(height:)` where the other three use
`BoxConstraints(minHeight:)`, and it is safe by an SDK constant that
**A8's own G10 records as unstated anywhere in this project**. That is R2′ at
P3, and it is a live precondition on A8's P1-02: option (B) moves this text out
of the clamp. The next person to re-derive R2 will do exactly this arithmetic,
and the useful thing to hand them is the answer, not the absence of a question.

### 15.2 Handed over — A8 filed it first, and better

| This audit's draft | A8's finding | What A8 had that this did not |
|---|---|---|
| R4 · deck list adds `viewPadding.bottom` (claimed 24–48 dp always) | **P3-20** | `removePadding` leaves `max(0, viewPadding − padding)`, so the term is normally **0** inside a shell branch and non-zero only with the keyboard up — and `navigation_bar.dart:291` is where the inset is actually paid. The magnitude claim here was wrong |
| §7.2 · `_toolbarHeight`'s subline budget "exactly exhausted at 3.0" | **P2-13** | The clamp again: the bar over-reserves by 34.5 dp at a 2.0 setting rather than running out. Opposite sign |
| §5.3 · `_kListBottomInset` means two different numbers in two files | **P3-22** | Nothing — same finding, A8 got there first |
| G1 · 375 dp untested | **P3-21** | Nothing — same finding, and A8's histogram is the same one |
| §6 · `NavigationBar` height "⚠ unverified" | **G10** | `_kMaxLabelTextScaleFactor = 1.3` (`navigation_bar.dart:31`), which closes the question, plus the sharper framing that the *assumption* is what is missing |

None of these should get a change of its own. Where this audit's step list
mentions them (§14) it is to say: A8 owns it.

### 15.3 This audit's own, and why the sibling passes did not catch them

Verified by grep across all eight merged reports plus the four earlier component
audits:

| Finding | Not in any other report because |
|---|---|
| **R1** · `useSafeArea` missing on seven scroll-controlled sheets | `useSafeArea` appears in **no** other audit. A14 §6 examined `showMxFormSheet`, scored it a "True primitive", and cited its `isScrollControlled` + `max(viewInsets, viewPadding)` as a *documented fix* — which it is, for the **bottom** edge. Nobody asked what removing the height cap does to the **top** edge |
| **R3** · the tier constant against a card width | `isCramped` appears in no other audit. A14 §6 scored `MxHeroCard` "Responsive by construction (that is its entire purpose)" with **no gap** — reading the docstring's claim, which is exactly what the docstring is good enough to earn. The effective 392 dp is only visible if you subtract the gutter yourself |
| **R5 / R6** · the scrollbar | `ScrollbarTheme` appears in no other audit. It is one theme builder and one hand-written `Scrollbar`, sitting between "content" and "chrome", and every pass so far has been organised by component family |
| **R7** · the web frame zeroes three insets | Nobody else has had a reason to ask what the E2E channel is evidence *for* |
| **R9 / R10** · the 600 ceiling's coverage, and CSS-kit compact parity | Both are cross-cutting rather than per-component |

### 15.4 What this means for reading the two reports together

A8 is the better source on **`MxContentShell`, `MxBreadcrumb`,
`MxNavigationBar` and the two Scaffolds** — it read the SDK and this audit did
not. This report is the better source on **`AppBreakpoints` and the compact tier
as a system** (§2–§5), on **sheets' top edge** (§9.2), on **the scrollbar**
(§11) and on **what the width and text-scale coverage actually is** (§12). Where
they touch the same line of code and disagree, A8 wins on mechanism and this
report wins only where §15.3 says nobody else looked.

---

## 16 · Decisions this audit needs from the owner

1. **A8's P1-02, option (A) or (B)** — this is A8's decision, not this audit's,
   and it is listed first because **R2′ is a precondition on it.** Option (B)
   moves the deck path out of the `AppBar` clamp, and the fixed 32/48 dp box
   that is safe today is the wrong shape once that text can grow. Whoever takes
   the decision should read §15.1 before executing it.
2. **R3 (a) or (b)** — is the hero's rule about the screen or about the card? A
   fix cannot be written until this is answered, and answering it inside the fix
   commit is how the next audit finds the same ambiguity with a different number.
3. **Landscape: supported or permitted?** Nothing locks it, one file tests it,
   no screen renders in it. Either answer is fine; the absence of one is not.
4. **G4** — is the compact tier a per-component safety net (which is what
   `app_breakpoints.dart` says) or a screen-level rendering promise (which is
   what four screen goldens at 320 imply)? Whichever it is, it should be written
   in one place, because right now the code says one thing and the golden set
   says the other.
5. **R9** — above 600 dp, is a half-capped app acceptable? "Yes, AD-04 says
   phone" is a complete answer; it is just not currently written down anywhere
   that a reader of the four capped screens would find it.
