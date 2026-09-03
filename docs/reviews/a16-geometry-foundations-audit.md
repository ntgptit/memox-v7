# A16 — Geometry / depth foundation deep audit

| | |
|---|---|
| **Status** | active |
| **Purpose** | Establish what the app's geometry and depth foundations actually are — spacing, sizing, radius, stroke, elevation and the borders that carry them — where the token layer owns a decision, where a screen re-decided it, and what each gap costs |
| **Scope** | `AppSpacing`, `AppSizing`, `AppRadius`, `AppStroke`, `AppElevation` + `shadowsFor`/`materialShadowColor`, `AppBorderColors`, `AppIconSize` and `AppBreakpoints` where geometric; every `lib/core/theme/components/**` builder; every `lib/shared/widgets/**`; every geometry literal under `lib/features/*/presentation/**`; the guard rules, host tests, kit CSS and Widgetbook surfaces that cover them. **Out of scope:** colour *values* and contrast (AD-14 and `app_palette_test.dart` own those), typography rungs beyond their geometric side, motion, anything under `lib/domain`/`lib/data` |
| **Source of truth for** | Nothing. This is a discovery report — every finding must land in `docs/wbs.md` and the owning document before it becomes a rule |
| **Depends on** | `CLAUDE.md` · `document-conventions.md` · `architecture.md` (AD-14, AD-15) · `design-system/theme-architecture.md` |
| **Updated by task** | — (audit only, no implementation) |
| **Last updated** | 2026-09-03 |

---

## Provenance

| | |
|---|---|
| **BASE_SHA** | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` |
| Base commit | `refactor(theme): the dark card stops glowing, and elevation stops meaning two things (M100.35) (#435)` — `main` at time of audit, 2026-09-03 |
| Rebased onto | `9f2d226` — five sibling audit reports landed on `main` during this audit (#437, #438, #440, #441, #444). All five are report-only: `git diff 3207e7b origin/main` touches nothing outside `docs/reviews/`, so **no finding below moved**, and BASE_SHA remains the correct provenance for the code state. One of them overlaps and is cross-referenced in §7.3 |
| Surface read | 722 Dart files under `lib/` (49 theme, 304 presentation), 471 test files, 233 committed goldens, 8 kit token files, 10 guard rule files |
| Method | Static. Every number below was read out of the tree at BASE_SHA and cross-checked against its declaration, its call sites, the kit CSS, the guard scopes and the tests that touch it. A comment-stripping scanner (not a plain grep) produced the literal inventories in §7, so a value quoted inside a doc comment is never counted as a call site |
| **Not verified** | Nothing was rendered. No Flutter SDK is present in this session, so no widget was pumped, no golden compared and no pixel measured. Every claim about *code* below is CONFIRMED by reading it; every claim about what a rendered frame looks like is marked as such and carries the probe that would settle it |

**Nothing in this document is a change.** No file under `lib/`, `test/`, `widgetbook/`,
`design_system/` or any other `docs/` page was touched. The single file this branch
adds is this one.

---

## 1 · Executive verdict

**The geometry foundation is in good structural health and its depth *contract* is
not.** Six token classes cover spacing, sizing, radius, stroke, elevation and icon
size; every corner radius in the app comes from `AppRadius` with zero literals, every
shadow in the app is built by one function in one file, the 48 dp touch floor is
enforced in the theme rather than per screen and is asserted at 20+ render sites, and
the guard already refuses inline `EdgeInsets`/`SizedBox` numbers in product UI. That
half of the job is done, and the report says so rather than manufacturing findings
against it.

Three things are wrong, and they are not the same kind of wrong.

**One is a live divergence between the code and the specification it is written
against.** #435 replaced the dark card's glow — Tokyo's `#6A7199` at `blur 2` with a
spread that climbed 1 → 2 → 3 by level — with a crisp `outlineVariant` hairline at
`blur 0` and a constant spread. The Dart is correct and well tested. **The kit still
declares the glow** (`design_system/tokens/elevation.css:40`), two documents still
describe it as current, and `css_scale_parity_test.dart:314-337` **asserts that the
kit keeps declaring it** while asserting in the same test body that Dart does the
opposite. The test's own name — *"dark paints Tokyo's rim at every level, as the kit
does"* — is now false, and it is green. The kit is the artifact a future renderer, a
web build or a designer handoff reads; it says the app glows in dark, and nothing can
correct it without turning a passing test red. **P0.**

**One is a wire that two components were reasoned about but never given.**
`materialShadowColor(scheme)` is documented as *"the only channel allowed to depend
on brightness"* and as the single answer to which mode paints a Material shadow. It is
wired into exactly two theme builders — `Card` and `PopupMenu`. The FAB and the
SnackBar both state `elevation: AppElevation.overlay` (8) and leave `shadowColor`
null, so they resolve through `ThemeData`'s default instead. The FAB's own comment
says *"The dark shadow it was hiding is invisible on its own terms
(`materialShadowColor` carries the measurement)"* — describing a wire the file does
not make. `component_depth_and_state_test.dart` asserts the transparent-in-dark
invariant for `PopupMenu` and for nothing else. **P1.**

**The rest is one root cause wearing five costumes: the app renders a 32 dp control
tier that no token owns.** Four 32 dp square glyph wells exist in the `card` feature
alone, spelled three different ways — `AppSpacing.xxl` used as a *dimension* twice, a
public `wellSize = 32` once, a private `_wellSize = 32` once — plus `_containerHeight
= 32` in the chip theme and `MxBreadcrumb.compactLineHeight = 32` in shared. Seven of
the eight `AppSpacing.xxl` call sites in the entire app are not gaps at all; one of
them uses a *spacing* token as an *icon size*, under a comment reading "32 has no
`MxIconSize` step". This is precisely the defect M100.29 and M100.30 fixed when
`touchTarget` and `_kCompactHeight` moved into `AppSizing` — it simply was not
finished, and `AppSizing`'s "two heights, not a five-rung ladder" note is the reason
it looked done. Meanwhile `MxMetricWell` exists in `shared/`, was created to stop
exactly this, is 24 dp rather than 32, and one file uses both it and a hand-built well.
**P1.**

**Nothing here is a rendering regression the owner would see today.** The 32 dp wells
all render 32 dp; the strokes all render at their intended widths. What is broken is
*ownership and provability* — five spellings of one number, a specification that
contradicts the code, and a depth invariant enforced for one component out of three.

Verdict: **the foundation is sound, the depth contract is not, and the sizing scale is
one rung short of matching what the app draws.** 1 × P0, 4 × P1, 9 × P2, 7 × P3.

---

## 2 · The structural / optical model

The brief asks every important dimension to be classified STRUCTURAL or OPTICAL. The
tree already behaves as if that split exists; it has never been written down, which is
why `AppSizing`'s test hedges it in a comment rather than stating it as a rule.

### 2.1 · The two categories

| | **STRUCTURAL** | **OPTICAL** |
|---|---|---|
| **What it is** | A dimension that participates in layout: a gap, a pad, an inset, a control's extent, a corner | A dimension that participates in *paint*: a stroke width, a font metric, a shadow offset or blur, a state opacity, a decorative mark's diameter |
| **Why it is that** | Two structural values sitting side by side must add up; a rhythm is only visible if every element shares its unit | An optical value is judged against what is beside it, not against a grid. A 1 dp hairline is one hairline because that is what reads as a line, not because 1 is on any scale |
| **Rhythm rule** | MUST be on the 4 dp grid and SHOULD come from `AppSpacing` (gaps) or `AppSizing` (extents) | MUST NOT be held to the 4 dp grid. It answers to its own scale — `AppStroke`, the type scale, `AppStateOpacity` |
| **Ownership rule** | One token per rung. A screen that needs a value the scale lacks has found a missing rung, not a licence to declare one | One token per *role*. Two roles that happen to share a number stay two tokens — this is `AppStroke`'s own stated reason for keeping `focus` and `selectionControl` apart at 2.0 |
| **Examples at BASE_SHA** | `AppSpacing.*`, `AppSizing.*`, `AppRadius.*`, `AppIconSize.*`, `_ringSize = 64`, `wellSize = 32`, `cardMinHeight = 180` | `AppStroke.*`, `_ringStroke = 6`, `_stateDotSize = 10`, `_stepHeight = 6`, `hiddenBlur = 2`, `_labelLineHeight = 20`, `AppStateOpacity.*`, every `BoxShadow` offset and blur in `app_elevation.dart` |

### 2.2 · The third category the brief's two do not cover

Forcing every dimension into two boxes files a **responsive threshold** as
STRUCTURAL and then wrongly demands it be divisible by 4. A threshold is not laid out
— nothing is drawn at it. It is a *comparison value*, usually measured from content:
"below this width the two-column grid folds", "past this drag distance the card is
dismissed".

`progress_metric_widget.dart:67` is the case that forces the distinction. It declares
`minimumCellWidth = 90` — the **only** off-grid structural-looking constant in the
whole tree — and its doc comment explains why: *"90 is the width the four words need
at scale 1.0 with room for four figures."* It is compared against
`textScalerOf(context).scale(90)`; no box is ever 90 wide. Rounding it to 88 or 92 to
satisfy a grid rule would trade a measured fact for an aesthetic one.

**Proposed rule.** A **THRESHOLD** is a value only ever used on the right-hand side of
a comparison. It is exempt from the 4 dp grid, and in exchange it MUST carry the
measurement that produced it in a comment beside it. Eight constants qualify today and
seven of the eight already carry that measurement:

| Constant | Value | Measurement stated? |
|---|---|---|
| `progress_metric_widget.dart:67` `minimumCellWidth` | 90 | ✅ four words + four figures at scale 1.0 |
| `card_export_format_options_widget.dart:96` `_minOptionWidth` | 148 | ✅ |
| `card_import_source_step_widget.dart:116` `_minCardWidth` | 164 | ✅ |
| `card_detail_state_widget.dart:296` `_minCellWidth` | 132 | ✅ |
| `card_import_row_preview_widget.dart:28` `_twoColumnMinWidth` | 280 | ✅ |
| `study_home_deck_item_widget.dart:203` `inlineActionMinWidth` | 320 | ✅ |
| `study_swipe_deck_widget.dart:18` `kStudySwipeThreshold` | 70 | ✅ |
| `study_swipe_deck_widget.dart:21` `_kFadeOverDistance` | 400 | ✅ |

### 2.3 · The model applied to the whole tree

Every named geometry constant outside `lib/core/theme/foundations/` was classified and
checked against its category's rhythm rule. **Exactly one structural value is off the
4 dp grid, and it is a threshold, not a structural value** (`minimumCellWidth`, §2.2).
Everything else off-grid is optical by the table above: `_stateDotSize = 10` (×2),
`_stepHeight = 6`, `_currentHeight = 10`, `_ringStroke = 6`, `hiddenBarHeight = 14`,
`hiddenBlur = 2`, `_flagIconSize = 18`, `_verticalPadding = 6` (derived from a type
metric), `_kGlyphInset = 14` (derived from `(48 − 20) / 2`).

**That is a genuinely good result, and it is the reason this model is worth writing
down rather than inventing.** The codebase already obeys the split; it just cannot
prove it, because `app_sizing_test.dart:17-32` states the grid rule for four constants
in `AppSizing` and nothing states it anywhere else. §12 proposes the sweep that would.

---

## 3 · Spacing

### 3.1 · The scale, and what each rung is used for

`app_spacing.dart` declares six rungs plus one derived clearance. The kit
(`design_system/tokens/spacing.css`) declares the same six with the same comments, and
`css_scale_parity_test.dart:35-46` pins each one.

| Rung | dp | Documented semantic | Call sites | Dominant *actual* use |
|---|---|---|---|---|
| `xs` | 4 | "Between an icon and its label" | 136 | `SizedBox(height:)` ×45 — a vertical gap |
| `sm` | 8 | "Between tightly related items in a row" | 178 | `SizedBox(height:)` ×52 — a vertical gap |
| `md` | 12 | "Inside a compact control" | 129 | `SizedBox(height:)` ×68 — a vertical gap |
| `lg` | 16 | "Standard screen padding and the gap between list items" | 125 | `SizedBox(height:)` ×44 + gutters — matches |
| `xl` | 24 | "Between sections of a screen" | 53 | `SizedBox(height:)` ×26 — matches |
| `xxl` | 32 | "Around a lone focal element" | 8 | **a 32 dp square glyph well** — does not match |
| `fabScrollClearance` | 88 | derived `56 + 16 + 16` | 2 | matches; pinned by `app_sizing_test.dart:41-49` |

### 3.2 · G-1 (P1) — `AppSpacing.xxl` is a control dimension wearing a spacing token's name

Seven of the eight `xxl` call sites in the app are not gaps. All seven are in the
`card` import flow:

| Site | What it does |
|---|---|
| `card_import_source_step_widget.dart:314-315` | `Container(width: xxl, height: xxl)` — a 32 dp square glyph well at `AppRadius.sm` |
| `card_import_source_summary_widget.dart:63-64` | the identical 32 dp square glyph well |
| `card_import_result_widget.dart:161-162` | `Container(width: xxl + md, height: xxl + md)` — a 44 dp circle |
| `card_import_result_widget.dart:172` | `Icon(size: AppSpacing.xxl)` — **a spacing token used as an icon size** |
| `card_list_body_widget.dart:63` | the one genuine gap: a bottom inset |

`card_import_result_widget.dart:170` states the reason in the file itself:

> `// 32 has no MxIconSize step; the closed-set spelling here is the ink's own resolve.`

**Why this is P1 and not a nit.** `AppSpacing`'s header calls itself "every gap, pad
and inset in the app". M100.29 moved `touchTarget` out of this class on exactly that
argument — *"a class that has to argue a member is not what the class is for is a
member in the wrong class"* — and the argument applies unchanged to the seven sites
above. The cost is not visual today; it is that a future change to the 32 dp gap rung
silently resizes four glyph wells and one icon, in a feature nobody would think to
re-check.

**Evidence** — `app_spacing.dart:25`, and the five sites above.
**Closure test** — a scan test asserting `AppSpacing.*` appears only as `EdgeInsets`
args, `SizedBox` gap args, `spacing:`/`runSpacing:`, and `Divider` insets — never as
`width:`/`height:`/`size:`/`dimension:`. It fails on all seven sites today.

### 3.3 · G-2 (P3) — three rung descriptions name a minority of their call sites

`md` is documented as *"Inside a compact control"* and is used 68 times as a vertical
gap; `xs` and `sm` are documented as horizontal relationships and are used as vertical
gaps more often than horizontal ones. This is not a rendering defect — the rhythm is
consistent either way — but the rung comments read as *roles* and function as
*examples*, and a reader picking a rung from them will pick the wrong one.

**Closure** — a doc-only correction: state each rung as a magnitude with one example
("12 — a tight relationship; the gap inside a compact control, and the common step
between stacked rows"), or state explicitly that the comments are examples. No code
change.

### 3.4 · G-3 (P3) — the vertical rhythm is 235 spacer widgets and 26 `spacing:` args

The app declares gaps as `SizedBox(height: AppSpacing.x)` 235 times and as
`Flex.spacing` 26 times. Both are correct and both are tokenised. The consequence is
only for *auditability*: a `Column`'s rhythm is not readable from one place, and a
structural test cannot ask "what is the gap between these two sections?" without
walking siblings. This is the reason the §12 closure tests are written as source scans
rather than as render probes.

**No action proposed.** Recorded so the next person does not read the imbalance as an
oversight.

### 3.5 · The compact step-down, and where it is re-derived

`mxScreenGutter(context)` (`mx_content_shell.dart:382-385`) returns `md` below 360 dp
and `lg` above it. Its doc says it is public precisely to stop the rule being
re-derived: *"Re-deriving the breakpoint rule at the call site is how the two drift
apart, and the drift only shows below 360 where nobody looks."*

It has been re-derived twice:

| Site | Rule | Status |
|---|---|---|
| `mx_content_shell.dart:382` | `isCompact ? md : lg` | the owner |
| `deck_tile_widget.dart:311-314` `deckTileGutter` | `isCompact ? md : lg` | **G-4 (P2)** — byte-identical logic, second copy |
| `deck_tile_widget.dart:282-284` | `isCompact ? sm : md` | a different step-down, unnamed |

**G-4 (P2).** `deckTileGutter` is `mxScreenGutter` with a different name, in a feature,
against the shared helper's own stated reason for existing. The third site is a
*second* compact rule (one rung down from `md` instead of from `lg`) with no name at
all — which means the app has two step-down policies and can only see one of them.

**Evidence** — `mx_content_shell.dart:378-385` (the doc), `deck_tile_widget.dart:311`.
**Closure test** — `deck_tile_widget.dart` calls `mxScreenGutter`; a guard rule or
scan asserting `AppBreakpoints.isCompact` appears in `lib/shared/` and
`lib/core/theme/` only, so a feature cannot re-derive the rule.

---

## 4 · Sizing and the touch floor

### 4.1 · What `AppSizing` owns

| Token | dp | Enforced where | Call sites |
|---|---|---|---|
| `touchTarget` | 48 | `buildSharedButtonStyle` `minimumSize`, `iconButtonTheme` `minimumSize`, `MxPressable` `ConstrainedBox`, `MxCard` `ConstrainedBox` | 39 |
| `controlCompact` | 40 | `MxActionButton` `minimumSize` + `tapTargetSize: padded` | 1 |
| `floatingAction` | 56 | read only, to derive `fabScrollClearance` | 2 |
| `buttonMinWidth` | 64 | `buildSharedButtonStyle` `minimumSize.width` | 2 |

`app_theme.dart:152-153` states `visualDensity: standard` and
`materialTapTargetSize: padded` globally, so no Material control can shrink under the
floor by density.

### 4.2 · The touch floor holds, and it is well proven

This is the strongest part of the foundation and the report says so plainly. The floor
is asserted at **20+ render sites** across shared widgets, feature screens and the
compact-scale suite — `mx_form_components_test.dart:204`,
`mx_card_interaction_test.dart:318`, `mx_pill_button_test.dart:160`,
`mx_pressable_test.dart:30`, `mx_breadcrumb_test.dart:295`,
`compact_scale_test.dart:272`, `settings_screen_geometry_test.dart:240`,
`progress_deck_row_geometry_test.dart:37`, `deck_tile_counts_test.dart:294`,
`study_home_geometry_test.dart:159`, `card_editor_layout_test.dart:220` and more.
`app_sizing_test.dart:52-77` proves both button families resolve it from the theme in
both modes.

Every control that paints below 48 restores the target rather than shrinking it, and
each one is tested:

| Control | Paints | Hits | Mechanism | Test |
|---|---|---|---|---|
| `MxActionButton.compact` | 40 | 48 | `tapTargetSize: padded` | `mx_components_test.dart:118-150` |
| Chip / `MxPillButton` | 32 (34 with hairlines) | 48 | `materialTapTargetSize: padded` | `mx_pill_button_test.dart:160` |
| Deck due chip | 24 | n/a — not a control | — | `deck_tile_geometry_test.dart:134` |
| Breadcrumb compact strip | 32 | whole strip is one target | `onUp` collapses the steps | `mx_breadcrumb_test.dart:295` |

### 4.3 · The rendered control-height tiers, and which are owned

| dp | What renders it | Owner |
|---|---|---|
| 24 | deck due chip | none — a local `DecoratedBox` |
| **32** | chip content box · pill · breadcrumb compact line · 4 × glyph well | **none** — 5 spellings, §4.4 |
| 40 | `MxActionButton.compact` | `AppSizing.controlCompact` ✅ |
| 48 | every button, icon button, list row, search field, pressable | `AppSizing.touchTarget` ✅ |
| 56 | FAB | `AppSizing.floatingAction` ✅ |

### 4.4 · G-5 (P1) — the 32 dp tier has five spellings and no owner

| Site | Spelling | Shape |
|---|---|---|
| `app_chip_theme.dart:271` | `const double _containerHeight = 32` | chip content box, `AppRadius.pill` |
| `mx_breadcrumb.dart:96` | `static const double compactLineHeight = 32` | header line, no fill |
| `tag_catalog_row_widget.dart:48` | `static const double wellSize = 32` | square well, `AppRadius.sm`, `surfaceMuted` |
| `card_metric_widget.dart:136` | `const double _wellSize = 32` | square well, `AppRadius.sm`, `surfaceMuted` |
| `card_import_source_step_widget.dart:314` | `AppSpacing.xxl` | square well, `AppRadius.sm`, `surfaceContainerHigh` |
| `card_import_source_summary_widget.dart:63` | `AppSpacing.xxl` | square well, `AppRadius.sm`, `surfaceContainerHigh` |

Four of these are the **same widget**: a 32 dp square, `AppRadius.sm`, a muted fill,
one `MxIconSize.sm` glyph centred. Two are in the same feature and know about each
other — `tag_catalog_row_widget.dart:149` says *"`surfaceMuted`, the spelling Card
Detail's metric wells use"* — and still duplicate.

**And `MxMetricWell` already exists in `lib/shared/widgets/` for this.** Its doc reads:

> **Shared because it was already written twice** — privately in the deck summary and
> privately in Progress's metric grid, identical line for line — and a third screen was
> about to do without it, which is the version of the same problem that shows up as
> three tabs looking like three apps (M99.26).

Five more screens then did exactly that. `MxMetricWell` is **24 dp** (16 dp glyph +
`AppSpacing.xs` padding × 2) at `AppRadius.pill`; the four hand-built wells are 32 dp
at `AppRadius.sm`. `card_import_result_widget.dart` uses **both** — `MxMetricWell` at
line 275 and a hand-built 44 dp circle at line 161.

**Evidence** — the six sites above; `mx_metric_well.dart:9-27`.
**Closure** — decide whether the app has one well or two. If one, either `MxMetricWell`
grows a size axis or the 32 dp variant becomes its second rung, and the four copies
become call sites. If two, `AppSizing` gains the tier (`controlSmall = 32`, or
`wellStandard`/`wellCompact`) and all five spellings read it.
**Closure test** — a scan asserting no `const double.*= 32` under `lib/features/`, plus
a Widgetbook story showing both well sizes side by side (§11 — there is none today).

### 4.5 · G-6 (P2) — two button minimum widths

`AppSizing.buttonMinWidth = 64` is documented as *"the narrowest a button is allowed to
be, label notwithstanding"* and is stated in `buildSharedButtonStyle` for every family
at once. `deck_study_button_widget.dart:11` then declares `_kButtonMinWidth = 80` and
`deck_tile_geometry_test.dart:140` pins the rendered result at `>= 80`.

The local constant carries a defensible reason — *"so a one-word verb is not narrower
than the chips above it… decided by what it sits next to"* — and the report accepts it.
What is missing is that the two numbers do not know about each other: `_kButtonMinWidth`
does not read `AppSizing.buttonMinWidth`, does not say it is a *floor above* the
global floor, and nothing fails if the global one is raised past 80.

**Closure** — express it as a relationship (`AppSizing.buttonMinWidth + AppSpacing.lg`,
or a named `deckVerbMinWidth` in `AppSizing` if it is really design grammar), and let
the test assert `>= AppSizing.buttonMinWidth` in addition to the local value.

### 4.6 · G-7 (P3) — `MxBreadcrumb` can be built with 32 dp tappable steps

`MxBreadcrumb.lineHeight` defaults to `AppSizing.touchTarget` and
`_MxBreadcrumbStep` floors its tappable branch at `ConstrainedBox(minHeight:
widget.lineHeight)` — so a caller passing `compactLineHeight` (32) **with** per-step
`onTap` and **without** `onUp` gets four 32 dp controls. Today no caller does:
`deck_path_widget.dart:81` is the only site that passes 32 and it also passes `onUp`,
and `build()` short-circuits to `_buildSingleTarget` whenever `onUp != null`
(`mx_breadcrumb.dart:312`). The invariant holds by convention, not by structure, and
`mx_breadcrumb_step.dart:81` asserts it in prose — *"the tappable steps still carry
48"* — which is true only under that convention.

**Closure** — an assertion in `MxBreadcrumb`'s constructor: `lineHeight >=
AppSizing.touchTarget || onUp != null || items.every((i) => i.onTap == null)`, plus the
widget test that trips it.

---

## 5 · Radius

### 5.1 · Complete inventory and semantic ownership

**Zero raw radius literals exist anywhere in `lib/`.** The comment-stripping scanner
found one `BorderRadius.circular` with a numeric argument in the whole tree —
`mx_progress_bar.dart:112`, `AppRadius.pill : 0`, where the `0` is the square variant
and is correct. This is the cleanest of the six foundations.

| Token | dp | Documented owner | Where it actually renders |
|---|---|---|---|
| `sm` | 8 | chips, badges, small indicators | scrollbar thumb · tooltip · 4 glyph wells · deck workload line · card metric · import source cards · deck summary metrics |
| `md` | 12 | buttons and inputs | every button family · input · icon button · list tile · snackbar · popup menu · segmented button · time-picker field · deck icon area · guess option · match tile · `MxPressable` default · `MxFocusRing` default |
| `lg` | 16 | cards and sheets | `MxCard` (7 recipes) · bare `Card` · dialog · bottom sheet · FAB · date picker · time picker dialog |
| `xl` | 20 | "the study card, the one surface a whole screen is built around" | `MxCard` — 2 recipes only (`mx_card.dart:227, 250`) |
| `pill` | 999 | fully rounded controls | chip · `MxPillButton` · `MxMetricWell` · search field · progress bars · session top bar · card tag chip · box progress |

**Semantic ownership is honest.** Each rung's stated purpose matches its call sites,
including `xl` — it is used exactly twice, both in `MxCard`, both for the study card,
which is what its comment claims. The kit declares the same five and
`css_scale_parity_test.dart:58-64` pins all five including `xl`.

### 5.2 · G-8 (P3) — `AppRadius.xl` is missing from the Widgetbook catalog

`widgetbook/lib/tokens/scale_sections.dart:65-68` renders `sm`, `md`, `lg` and `pill`.
`xl` is absent. The one rung whose whole justification is *"four pixels above `lg`, and
it is the only thing at this radius"* is the one a reviewer cannot see beside `lg` to
judge whether the four pixels earn their step. Same file, `:89-91`: `AppIconSize.mdCompact`
is missing from the icon row for the same reason.

`widgetbook_coverage_test.dart` checks *components*, not tokens, so neither omission
can fail.

**Closure** — add the two rows; extend the coverage test to assert every public member
of `AppRadius`, `AppIconSize`, `AppStroke`, `AppElevation` and `AppSizing` appears in
`scale_sections.dart`.

### 5.3 · G-9 (P3) — the radius guard is a warning where the spacing guard is an error

`memox.design_token.no_raw_border_radius` is `severity: warning`;
`memox.design_token.no_raw_spacing_literal` beside it is `severity: error`. Both are
structural rhythm rules over the same scope. Nothing in either rule's comment explains
the split, and radius is currently the *cleaner* of the two — so the weaker severity
protects the better-behaved scale.

**Closure** — raise to `error`. Zero call sites violate it today, so the change is free.

---

## 6 · Stroke, borders and dividers

### 6.1 · The taxonomy the brief asks for, mapped onto what exists

`AppStroke` declares four widths. The kit declares three (`--border-hairline`,
`--border-input`, `--border-focus` in `elevation.css:32-34`);
`design_tokens_test.dart:104-106` pins those three against it. `selectionControl` is a
deliberate fourth with its exception argued in the file — the kit draws no checkbox and
no switch, so M3's `_CheckboxDefaultsM3.side` is the next authority.

| Brief's role | Token | dp | Rendered by | Contrast expectation |
|---|---|---|---|---|
| **decorative hairline** | `hairline` | 1 | card dark rim · nav bar top edge · app-bar scrolled-under line · content-shell bands · dividers · popup-menu side · dialog side · picker sides · chip resting side · outlined-button resting side | **none — correctly** (§6.2) |
| **control boundary** | `input` | 1.5 | `InputDecoration` all states · guess option answered row · match tile picked | 3:1 |
| **focus** | `focus` | 2 | icon button · outlined button · `MxFocusRing` · `MxCard` focus layer · `MxTextButton` underline | 3:1 — held by `focus_ring_contrast_test.dart` |
| **selected state** | `input` **(borrowed)** | 1.5 | guess option, match tile | 3:1 |
| **selection control** | `selectionControl` | 2 | checkbox · switch track · date-picker today border | 3:1 |
| **error** | `input` | 1.5 | `InputDecoration` error state | 3:1 |
| **divider** | `hairline` | 1 | `DividerThemeData.thickness` **and** `.space` | none |

### 6.2 · Decorative neutral borders are not held to 3:1, and the tree already knows

The brief asks that a purely decorative neutral border not be forced to 3:1. It is not.
`app_elevation.dart:98-105` states the dark rim as `ColorScheme.outlineVariant` —
*"M3's own role for a boundary that is decorative and explicitly not required to reach
3:1"* — measured at **1.30:1 against the card and 1.41:1 against the page**, and
`app_elevation_test.dart:98-104` asserts the role by identity with that reason quoted.
`app_chip_theme.dart:206` and `app_dialog_theme.dart:33` use the same role for the same
reason. **No finding. Recorded because #435's whole argument was that the *old* rim was
wrong precisely by being a 3.74:1 control-grade edge on a decorative job**, and a later
pass that "fixed" the contrast of a decorative border would re-introduce it.

### 6.3 · G-10 (P2) — `AppStroke.input` is named for a component and used as a role

Five call sites, and **three are not inputs**:

| Site | Role it plays |
|---|---|
| `app_input_theme.dart:56, 58` | an input's border — matches the name |
| `guess_option_item_widget.dart:84` | `accent == null ? hairline : input` — the *answered/selected* row's boundary |
| `match_tile_widget.dart:241` | the *picked* tile's boundary |

The role these three share is "a control boundary that is stating something", which is
what the token means and not what it is called. `AppStroke`'s own file already argues
this distinction for `selectionControl` vs `focus` — *"It happens to equal `focus`.
That is a coincidence, not a relationship"* — and then leaves `input` naming a widget.

The kit constrains the rename: `design_tokens_test.dart:104-106` binds the Dart name to
`--border-input`. So this is a **two-sided** change (kit + Dart + test) or a doc-only
one.

**Closure** — either rename both sides to the role (`--border-stated` / `AppStroke.stated`,
keeping 1.5) or state in `app_stroke.dart` that `input` is the *stated control boundary*
and the kit's name is historical. The doc-only option is P3-cheap and removes the
ambiguity; the rename is the honest one.

### 6.4 · G-11 (P2) — five raw stroke literals, and no guard covers strokes at all

`memox-design-token-rules.yaml` has rules for colour, text style, spacing, duration and
radius. **There is no stroke rule.** Nothing refuses `BorderSide(width: 2)`,
`Border.all(width: 3)`, `thickness: 1`, `strokeWidth: 2` or `decorationThickness: 2`.
Five raw literals sit in that gap:

| Site | Literal | Should be |
|---|---|---|
| `mx_breadcrumb.dart:17` | `const double _kFocusUnderlineThickness = 2` | `AppStroke.focus` |
| `mx_radio_rows.dart:108-109` | `Divider(height: 1, thickness: 1)` | the theme already supplies both — delete the overrides |
| `mx_action_button.dart:389, 472` | `CircularProgressIndicator(strokeWidth: 2)` | a named spinner-stroke token |
| `search_page_footer_widget.dart:19` | `const double _kSpinnerStroke = 2` | ditto — third copy |
| `card_history_section_widget.dart:352` | `const double _spinnerStroke = 2` | ditto — fourth copy |

`mx_breadcrumb.dart:14-17` is the sharpest of the five, because its comment argues for
the literal on a premise that is false:

> *"Declared here rather than shared: two widgets is not yet a token, and `core/theme/`
> has no home for a stroke width."*

`lib/core/theme/foundations/app_stroke.dart` exists, holds `focus = 2`, and the same
comment names the kit's `--border-focus` two lines earlier. `AppStroke`'s own header
lists the exact drift this is an instance of: *"`2` in `iconButtonTheme.side`, again in
the outlined button's focused side, again as `MxTextButton`'s focus underline… the one
that was missed stayed at the old weight, visible only on the screen nobody
re-checked."* This is the one that was missed.

The four progress-indicator strokes are a related but distinct gap: **the app renders a
spinner stroke at three widths (2, 2, 6) and owns none of them.** `_ringStroke = 6`
(`card_progress_panel_widget.dart:158`) is a legitimately different optical decision
for a 64 dp ring; the three 2s are one decision written three times.

**Closure test** — a guard rule `memox.design_token.no_raw_stroke_width`, scoped
`ui_and_theme_surfaces` (the same reasoning `no_raw_duration` used: the theme is where
the regression happens, and `AppStroke`'s declarations are named constants the
lookahead exempts):

```
- '\bwidth\s*:\s*\d+(?:\.\d+)?\s*[,)]'          # inside BorderSide/Border.all
- '\b(?:thickness|strokeWidth|decorationThickness)\s*:\s*\d'
```

All five sites fail it today; `AppStroke`'s own file and `app_scrollbar_theme` need the
named-constant exemption or a token.

### 6.5 · G-12 (P2) — 20 borders state a colour and let the width default

Twenty `BorderSide(...)` / `Border.all(...)` constructions in `lib/` omit `width:` and
take Flutter's implicit `1.0`. Three more (`Border.fromBorderSide(focusIndicator(...))`
in `mx_card.dart:698`, `mx_focus_ring.dart:68`, `mx_list_tile.dart:99`) carry the width
inside the `BorderSide` and are fine.

The value is right — `1.0 == AppStroke.hairline` — so nothing renders wrongly. What is
wrong is that **20 hairlines in the app do not read the hairline token**, so raising
`AppStroke.hairline` would move three of them and leave seventeen behind. The tree
already contains the counter-example: `app_card_theme.dart:55-61` states
`width: AppStroke.hairline` with `// ignore: avoid_redundant_argument_values` and
explains why the redundancy is the point —

> *"the width is one **because the stroke scale says a hairline is one**, not because
> `BorderSide` happens to agree today."*

Seventeen files did not get that memo.

| Where | Count |
|---|---|
| `lib/core/theme/components/**` (buttons, popup menu, pickers ×3, chip ×3, segmented ×2, dialog) | 13 |
| `lib/shared/widgets/**` (`mx_action_button`, `mx_card`, `mx_content_shell` ×2, `mx_navigation_bar`, `mx_search_field`) | 6 |
| `lib/features/**` (`card_history_event_widget`) | 1 |

**Closure test** — extend the §6.4 guard rule with a pattern that flags
`BorderSide(`/`Border.all(` bodies containing no `width:`; or, cheaper and equally
provable, an AST scan test over `lib/` asserting every `BorderSide`/`Border.all`
literal names a width.

### 6.6 · G-13 (P3) — `MxSearchField`'s boundary is 1.0 where every other input is 1.5

`mx_search_field.dart:124-127` builds its own pill and its focused border is an
implicit 1.0 with `strokeAlignOutside`, while `buildInputDecorationTheme` gives every
other field `AppStroke.input` (1.5) in every state. The file argues the geometry —

> *"a border inside the box would make the pill 50 where the touch target needs its 48,
> and at 320 wide with `textScaler` 2.0 the chrome has no two pixels to spare"*

— which explains `strokeAlignOutside`, not the width. `strokeAlignOutside` removes the
stroke from layout entirely, so 1.5 would cost nothing there either. The result is that
the app's most-used input has a visibly lighter focused boundary than its forms do, and
the number carrying that difference is an unstated default.

This compounds F2 already recorded in `docs/reviews/mx-text-field-deep-audit.md` §11.2
(the search pill and the `InputDecoration` foundation are separate systems).

**Closure** — state the width as a token. If the intent is that a search pill is a
*decorative* boundary rather than a control one, `AppStroke.hairline` says so;
`AppStroke.input` says it is a control. Either is defensible; the implicit 1.0 says
nothing.

### 6.7 · Divider taxonomy — no finding

`app_divider_theme.dart:18-19` sets `thickness: AppStroke.hairline` and `space:
AppStroke.hairline`. A `Divider` therefore occupies exactly its own line and the
surrounding layout owns the gap, which is consistent with `CardThemeData.margin:
EdgeInsets.zero`'s stated reason (*"inter-card spacing belongs to the screen's
layout"*). `borderDivider` is its own colour token, separate from `borderSubtle`, in
both modes. The only defect is `mx_radio_rows.dart:108-109` restating both values as
literals, already counted in §6.4.

---

## 7 · Elevation and depth

### 7.1 · The model, and it is the right one

`AppElevation` holds dp only — `none 0`, `card 1`, `raised 3`, `overlay 8` — and the
paint lives in two functions beside it:

- `shadowsFor(level, scheme)` — for surfaces the app draws itself (`MxCard` only);
- `materialShadowColor(scheme)` — for surfaces Material draws, where the colour is the
  only slot available to say "this mode paints nothing".

**Separating the level from the paint is exactly right and #435 is what made it so.**
Before it, `overlayElevationFor` returned `AppElevation.none` in dark, making a
component's *semantic* depth brightness-dependent — a FAB claiming to be flush with the
page in one theme and eight dp above it in the other. That is gone from `lib/`
(`grep overlayElevationFor lib/` returns only doc comments recording its removal).

`app_elevation_test.dart` proves the rest thoroughly: the scale climbs from zero, level
`none` paints nothing in both modes, light gets Tokyo's float + contact pair, dark gets
a crisp `outlineVariant` rim at blur 0 with a constant hairline spread, `raised` says
"higher" with a drop rather than a thicker rim, and the L\* measurement the whole
decision rests on is **re-derived in the test** rather than quoted — so a palette change
that made a dark shadow visible would fail the test instead of ageing a comment.

**No hand-rolled `BoxShadow` exists anywhere in `lib/` outside `app_elevation.dart`.**
The scanner found four, all inside that file. That is a genuinely strong property and
nothing in this report should be read as diminishing it.

### 7.2 · Depth consistency across the six surfaces the brief names

| Surface | Semantic level | Paint channel | `shadowColor` stated | Light | Dark |
|---|---|---|---|---|---|
| `MxCard` (7 recipes) | `none` / `card` / `raised` | `shadowsFor` | n/a | float + contact | rim (+ drop above `card`) |
| bare `Card` | `card` (1) | Material | ✅ `materialShadowColor` | Material shadow | **transparent** + dark hairline side |
| `PopupMenu` | `raised` (3) | Material | ✅ `materialShadowColor` | Material shadow | **transparent** |
| **FAB** | `overlay` (8) | Material | ❌ **null** | Material shadow | **falls through to `ThemeData.shadowColor`** |
| **SnackBar** | `overlay` (8) | Material | ❌ **null** | Material shadow | **falls through to `ThemeData.shadowColor`** |
| `Dialog` | literal `0` | — | n/a | none — barrier separates | none |
| `BottomSheet` | literal `0` | — | n/a | none — barrier separates | none |
| `AppBar` / `NavigationBar` | literal `0` | — | n/a | none — hairline separates | none |

### 7.3 · G-14 (P1) — the FAB and the SnackBar bypass `materialShadowColor`

`grep -rn shadowColor lib/` returns exactly two production sites:
`app_popup_menu_theme.dart:52` and `app_card_theme.dart:41`. Neither
`buildFloatingActionButtonTheme` nor `buildSnackBarTheme` states one, and both state
`elevation: AppElevation.overlay`.

`materialShadowColor`'s own doc claims to be the single answer to this question:

> *"`shadowsFor` is for surfaces this app draws itself; a `PopupMenuThemeData` or a
> `Card` takes an `elevation` and paints its own shadow, so the only place to answer
> 'which mode paints one' is the colour. […] **This is the only channel allowed to
> depend on brightness, and that is the point** (M100.35)."*

And the FAB's own comment describes the wire as if it were made:

> *"The dark shadow it was hiding is invisible on its own terms (`materialShadowColor`
> carries the measurement)"* — `app_fab_theme.dart:52-54`

`ThemeData.shadowColor` is never set anywhere in `lib/`, so it takes the SDK default.
**CONFIRMED (code):** the wire is absent for both components, and the invariant is
asserted for `PopupMenu` alone (`component_depth_and_state_test.dart:203-226`).
`app_theme_test.dart:388-403` checks the FAB and SnackBar *levels* agree with each
other and explicitly defers the paint question to `materialShadowColor` — which is not
consulted.

**NOT VERIFIED (render):** whether the dark FAB and dark SnackBar actually paint a
visible shadow at elevation 8. No Flutter SDK is available in this session. The project's
own measurement (`_darkDropAlpha`'s derivation, `app_elevation_test.dart:136-186`) says
a fully opaque dark drop moves the page by ΔL\* 2.93, and dark's deliberate `raised`
drop spends 2.34 of that — so the paint is in the same order as a cue the app makes on
purpose, which is why this is P1 rather than cosmetic. Two goldens already contain a
dark FAB (`test/demo/goldens/deck_list_root_dark.png`,
`deck_list_empty_dark.png`), so the fix will move pixels and the goldens must be
regenerated with it.

**Probe that settles the render question** — pump `buildDarkTheme()`, read
`Material.of` under a `FloatingActionButton` and a `SnackBar`, and assert the resolved
`shadowColor`.

**Cross-reference — this finding corrects a sibling report.**
`docs/reviews/a12-feedback-system-audit.md` §3.2 landed on `main` while this audit was
in flight (#437) and returned **"Verdict: correct"** on `SnackBarThemeData`. It read the
level and not the paint channel, so the missing `shadowColor` is not a disagreement about
judgement — it is a slot A12 did not look at. That verdict should be read as scoped to
the roles and the level.

Its supporting sentence is also inaccurate at this BASE_SHA, and the inaccuracy is worth
correcting because it is the exact claim G-14 turns on:

> *"the same overlay depth `Dialog`/`BottomSheet`/`PopupMenu`/FAB use, so a snackbar does
> not float at a different depth than every other floating surface"*

`Dialog` and `BottomSheet` do **not** state `overlay`. Both state a literal `0`
(`app_dialog_theme.dart:30`, `app_bottom_sheet_theme.dart:14`) and separate themselves
with a barrier instead — which their own comments say, and which §7.2's table records.
Only `PopupMenu` (at `raised`, not `overlay`), the FAB and the SnackBar carry a non-zero
Material elevation, and of those three exactly one wires `materialShadowColor`. The
app's floating surfaces are **not** at one depth; they are at four (0, 3, 8, and
`shadowsFor`'s own ladder), which is correct — a barrier and a shadow are different
separators — but it means "every floating surface floats at the same depth" cannot be
the argument that a snackbar's depth is right.
**Closure test** — generalise `component_depth_and_state_test.dart:203` from
`popupMenuTheme` to a loop over *every* component theme that states a non-zero
elevation: the level must be equal across modes, and dark's `shadowColor` must be
`Colors.transparent`. It fails on two components today and would have caught this on
the day #435 landed.

### 7.4 · G-15 (P0) — the kit still specifies the dark glow, and a green test keeps it there

#435's whole subject was replacing dark's glow with a crisp rim. The Dart did change.
**The kit did not**, and it is the normative artifact:

`design_system/tokens/elevation.css:38-41`
```css
[data-theme="dark"]{
  /* The ring thickens with the level (M100.33): dark has no shadow to carry
     depth, so without this `card` and `raised` printed the same box … */
  --shadow-card:0 0 2px 1px #6A7199;--shadow-raised:0 0 2px 2px #6A7199;--shadow-overlay:0 0 2px 3px #6A7199;
}
```

Every one of those four facts is now false in the code:

| | kit says (`elevation.css:40`) | Dart does (`app_elevation.dart:116-138`) |
|---|---|---|
| colour | `#6A7199` | `ColorScheme.outlineVariant` — dark `#272C48` |
| blur | 2 | **0** |
| spread | climbs 1 → 2 → 3 by level | **constant `AppStroke.hairline`** at every level |
| depth above `card` | a thicker ring | **a real drop** — `0 4px 12px` at α 0.8, undeclared in the kit |

The file's prose header (`:16-24`) is stale by the same amount: *"The app adds a 1px
spread so the ring is painted solid at that colour before the blur falls off"* describes
the removed implementation.

**And the divergence is pinned in place by a passing test.**
`css_scale_parity_test.dart:314-337` is titled *"dark paints Tokyo's rim at every
level, **as the kit does**"* and does two incompatible things in one body: it asserts
the CSS still literally reads `0 0 2px 1px #6A7199` / `2px 2px` / `2px 3px`, and it
then asserts Dart paints `outlineVariant` at blur 0 with a constant hairline spread.
Correcting the kit turns that test red. The test that exists to prove kit and code agree
now certifies that they disagree, under a name asserting they agree.

Two more documents carry the stale statement:

| File | Line | Says |
|---|---|---|
| `docs/design-system/tokyo-component-mapping.md` | 127 | `` `shadows.card` (dark) │ rim thay shade │ rim `#6A7199` `` — as the current binding |
| `docs/architecture.md` | 1057 | `` card dark `#111633` với rim Tokyo `0 0 2px #6A7199` làm cue chiều sâu `` |

`docs/design-system/theme-architecture.md:227` is **correct** — it already records the
removal — so the tree contains two design-system documents that contradict each other
about the same value.

**Why P0.** The brief's item 10 is "protect #435: no dark glow and no
brightness-dependent semantic elevation". #435 is protected in Dart and actively
*un*-protected everywhere else: the specification says glow, the component mapping says
glow, the architecture doc says glow, and the parity gate enforces glow. Anyone
re-deriving from the kit — a web renderer, a Widgetbook doc, a designer handoff, or a
future agent that reads `design_system/` first as CLAUDE.md's reading order implies —
reinstates the exact effect the owner rejected on sight, and the full suite stays green
while they do it. This is not a latent risk; it is a live wrong answer in the one place
the project designates as the answer.

**Closure** — one change, four files: rewrite `elevation.css`'s `[data-theme="dark"]`
block and its prose to the current model (a crisp `outlineVariant` hairline at every
level, plus a drop above `card` that the kit does not currently declare at all); update
the two stale docs; and rewrite `css_scale_parity_test.dart:314` so it compares kit and
Dart to *each other* rather than to two different hard-coded literals.
`docs/architecture.md` carries Status `active`, not `frozen for MVP`, so the edit needs
no special dispensation — but it is a one-line correction inside a document this task
otherwise does not touch, so the task MUST name it in scope rather than making it as a
drive-by.

### 7.5 · G-16 (P2) — three brightness-dependent channels exist, one is declared

`materialShadowColor`'s doc says it is *"the only channel allowed to depend on
brightness"*. Two others do:

| Site | What varies | Assessment |
|---|---|---|
| `app_card_theme.dart:55-62` | a bare `Card` gets an `outlineVariant` hairline side in dark, `BorderSide.none` in light | **Correct, and argued in the file** — it mirrors `MxCard`'s dark rim through the only slot a `CardThemeData` has. Not a *semantic elevation* dependency: the level stays `card` (1) in both modes. Verified that `RoundedRectangleBorder.side` on a `Material` shape paints without insetting the child, so this does not create a geometry difference between `Card` and `MxCard` |
| `app_backdrop_recipe.dart:14` | scrim alpha `0.72` dark / `0.48` light | **Correct** — a scrim opacity is OPTICAL by §2.1 and has to differ, since the two grounds it dims are 40 L\* apart |

Neither is a defect. The finding is that the *claim* is now inaccurate and a reader
enforcing it literally would "fix" two correct decisions.

**Closure** — doc-only: amend `materialShadowColor`'s note to "the only channel by which
**depth** may depend on brightness", and list the two legitimate non-depth channels
beside it.

### 7.6 · G-17 (P3) — `AppElevation.overlay`'s shadow shape is derived, and only one branch says so

`_lightShadows` documents that `overlay` has no `shadowsFor` caller and is derived by
doubling `raised`, and writes it as a `switch` rather than a formula *"precisely so that
stays visible"* — good. `_darkDepth` does the same doubling (`_ => (8, 24)`) with a
one-line comment pointing back. Both are right, and both are now slightly wrong in a new
way: since #435 the FAB and the SnackBar *are* at `overlay`, they just reach it through
Material rather than through `shadowsFor`. The phrase "no production caller" is true of
the function and false of the level.

**Closure** — doc-only, and it should ride along with G-14: once FAB and SnackBar state
`materialShadowColor`, the sentence needs to say "no `shadowsFor` caller" rather than
"no production caller".

---

## 8 · Raw-literal hotspots

### 8.1 · What the scanner found in `lib/`

A comment-stripping, paren-matching scan over all 722 non-generated Dart files for
numeric literals inside `EdgeInsets*`, `SizedBox`, `BorderRadius`/`Radius.circular`,
`BorderSide`, `BoxShadow`, `elevation:`, `size:`/`iconSize:` and `StadiumBorder`:

| Construct | Hits with a literal | Assessment |
|---|---|---|
| `BorderRadius` / `Radius.circular` | **1** | `mx_progress_bar.dart:112` — the square variant's `0`. Correct |
| `BoxShadow` | **3** | all in `app_elevation.dart`, all `Offset(0, y)`. Correct |
| `elevation:` | **4** | all literal `0` — `AppBar`, `NavigationBar`, `BottomSheet`, `Dialog`. §8.2 |
| `EdgeInsets*` | **11** | all structural `0`s in `only`/`fromLTRB` (`isFirst ? 0 : …`). Correct |
| `SizedBox` | **8** | `double.infinity`, `widthFactor: 1`, `clamp(0.0, 1.0)` and named consts. Correct |
| `size:` / `iconSize:` | **15** | 14 are the type scale's own font sizes in `app_typography.dart`; 1 is `_flagIconSize` (§8.4) |

**`lib/` has essentially no inline geometry literals.** The guard
(`memox.design_token.no_raw_spacing_literal`, `no_raw_border_radius`) plus review has
done its job on the inline shape.

### 8.2 · G-18 (P3) — four `elevation: 0` literals where the token exists

`app_app_bar_theme.dart:21`, `app_navigation_bar_theme.dart:67`,
`app_bottom_sheet_theme.dart:14`, `app_dialog_theme.dart:30` all write `elevation: 0`
where `AppElevation.none` exists and is used 12 times elsewhere. The dialog's is the
odd one: it sits directly under a comment reasoning about elevation as a *concept*
(*"Zero, and the shadow is hand-painted instead"*), so the literal reads as a deliberate
"not on the scale" when it is exactly on it.

**Closure** — replace with `AppElevation.none`; add an `elevation:\s*\d` pattern to the
guard scoped `ui_and_theme_surfaces`, exempting named constants the same way
`no_raw_duration` does.

### 8.3 · G-19 (P2) — the guard measures inline literals and the tree has learned to route around it

`no_raw_spacing_literal` matches `EdgeInsets.*(…\d`, `SizedBox(width|height: \d`,
`spacing:/runSpacing: \d`. It does **not** see:

```dart
const double _barHeight = 8;          // declaration — not matched
SizedBox(height: _barHeight)          // usage — not matched
```

That is the shape of **all 25** feature-level geometry constants inventoried in §2.3.
Every one of them is a value the guard's message is about, expressed in a form the guard
cannot see.

**This is not straightforwardly bad.** A named constant with a stated reason is better
than a magic number, and most of these carry excellent reasons — that is why §2.3 comes
back almost clean. The finding is narrower and it matters: **the guard being green says
nothing about whether feature geometry is on the scale**, and nobody reading the CI
result knows that. The two real violations found in this audit (§3.2's `AppSpacing.xxl`
as a dimension, §4.4's five spellings of 32) both live entirely in the blind spot.

**Closure** — do not tighten the guard to ban named constants; that would push good
reasons out of the tree. Instead add a *scan test* (not a regex guard) that parses
`const double` declarations under `lib/features/` and `lib/shared/`, classifies each by
§2.1, and asserts every STRUCTURAL one is on the 4 dp grid or reads a token. Thresholds
declare themselves out by §2.2's comment rule. It passes today except where this report
says otherwise, which is what makes it worth having.

### 8.4 · G-20 (P2) — two rendered icon sizes the ladder does not own

`AppIconSize` declares 16 / 20 / 24 / 40 and `MxIconSize` closes the set so a widget
cannot pass a `double`. Two sites render outside it, and **both say so in a comment**:

| Site | Size | Comment |
|---|---|---|
| `card_tile_widget.dart:30, 254` | `_flagIconSize = 18` | *"18 has no `MxIconSize` step, so the closed-set spelling is the ink's own resolve"* |
| `card_import_result_widget.dart:170-172` | `AppSpacing.xxl` (32) | *"32 has no `MxIconSize` step; the closed-set spelling here is the ink's own resolve"* |

Two files independently reaching the same conclusion — "the ladder is missing a rung, so
I will use a bare `Icon`" — is the ladder telling you it is short. The 32 case is worse
than the 18 one, because it borrows a *spacing* token to express an icon size (§3.2).

**Closure** — decide per rung. 18 between `sm` (16) and `mdCompact` (20) is probably
noise and the flag should move to 16 or 20. 32 between `md` (24) and `lg` (40) is a real
gap — a hero glyph inside a 44 dp result circle is neither. Whichever way, the outcome
is that no `lib/` file constructs a bare `Icon(size:)`, which is a one-line scan test.

### 8.5 · G-21 (P3) — a raw `4` in the scrollbar theme

`app_scrollbar_theme.dart:15`: `thickness: const WidgetStatePropertyAll<double>(4)`. A
scrollbar thumb's thickness is OPTICAL by §2.1 and has no token; the value is on the
grid and reads fine. It is listed because it is the only unowned dimension inside
`lib/core/theme/components/` and would be caught by the §6.4 stroke rule if that rule
matched `thickness:` — which it should, since a scrollbar thumb is exactly the kind of
value that drifts when someone "makes the scrollbar a bit easier to grab".

---

## 9 · Compact and mobile interaction

`AppBreakpoints` declares two values and the kit pins both
(`css_scale_parity_test.dart:66-75`). Only `compact` (360) branches; `medium` (600) is
used exclusively as a *ceiling* on three reading columns, never as a layout switch, and
its doc says so.

`applyCompactScale` (`app_compact_scale.dart`) is careful in the ways that matter and
the report records them rather than re-litigating them:

- **body and label text are untouched**, so device width cannot silently undo the
  reader's own `textScaler` setting;
- **`VisualDensity.compact` is explicitly rejected** — it would take icon buttons to
  40×40, under the floor;
- **buttons keep their height and lose horizontal padding**, with the measurement that
  produced the choice quoted (four study actions at 320 dp get 68 px each; 24 a side
  leaves 20 for the label, 12 a side leaves 44);
- it is memoised on an `Expando` keyed by identity, for a stated performance reason.

`compact_scale_test.dart:188, 272-273` proves the touch floor survives the compact pass.

**No finding against the compact tier itself.** The two compact-related findings are
elsewhere: G-4 (the gutter rule re-derived in a feature, §3.5) and the unnamed second
step-down at `deck_tile_widget.dart:282`.

One inconsistency worth recording without a severity: `layout.css:5` describes
`--breakpoint-compact` as *"below this: the 320x568 case every component is tested
against"*, while `app_breakpoints.dart:15-16` records that screen tests moved to
360×640 and only *components* still run at 320. Both statements are true of different
suites; the CSS comment reads as if it were true of both.

---

## 10 · Border colour ladder

`AppBorderColors` holds six roles × two modes and the file states the ladder's order as
its organising rule: *"a card's resting edge is quieter than a control's, a control's
quieter than a picked one's, and the focus ring is louder than all of them in both
modes."*

| Role | Light | Dark | Carries |
|---|---|---|---|
| `borderDivider` | `#F2F5F9` | `#252C55` | the quietest line — `MxRadioRows` separators |
| `borderSubtle` | `#E4E7EA` | `#272C48` | resting card/band edges; bound to `ColorScheme.outlineVariant` |
| `borderControl` | `#6F727B` | `#747BA3` | a control's boundary; bound to `ColorScheme.outline` |
| `borderAccent` | `#AAB4FF` | `#7063C0` | an accented but unpicked edge |
| `borderOption` | `#8896FF` | `#5B65B2` | an option's edge — measured 3.33:1 on the dark card |
| `borderSelected` | `#5569FF` | `#8C7CF0` | picked — measured 5.27:1 on the dark card |

**Geometrically there is nothing to report.** Colour values, contrast ratios and the
ladder's ordering are AD-14's and `app_palette_test.dart`'s territory, and the audit
found no case where a border *colour* role and a border *width* role disagree about what
a line means — `borderSubtle` is always drawn at a hairline, `borderSelected` and
`borderOption` are drawn at `input` or `focus`. The one place the two systems are
described inconsistently is G-10 (`AppStroke.input` naming a component while the colour
beside it names a role).

---

## 11 · Coverage — guards, tests, goldens, catalog

### 11.1 · What covers what today

| Foundation | Guard rule | Unit/contract test | Kit parity | Render test | Widgetbook |
|---|---|---|---|---|---|
| `AppSpacing` | ✅ `no_raw_spacing_literal` (error) | ✅ scale is exactly 4/8/12/16/24/32; every declared member is on the scale | ✅ all 6 + touch target | ~ per-screen rhythm tests | ✅ all 6 |
| `AppSizing` | ~ via spacing rule | ✅ 4 dp grid · compact < target · derived clearance · both button families resolve it | ✅ `touchTarget` only | ✅ 20+ sites | ⚠️ `touchTarget` only |
| `AppRadius` | ⚠️ `no_raw_border_radius` (**warning**) | ⚠️ `sm < md < lg`, `pill > lg` — **`xl` not ordered** | ✅ all 5 incl. `xl` | ~ goldens | ⚠️ **`xl` missing** |
| `AppStroke` | ❌ **none** | ✅ 3 canonical widths + kit parity; ⚠️ `selectionControl` unasserted | ✅ 3 of 4 (`selectionControl` not in kit — argued) | ✅ focus contrast | ❌ **absent** |
| `AppElevation` | ❌ **none** | ✅ excellent — scale, both modes, rim shape, drop shape, L\* re-derived | ⚠️ **light ✅ / dark pins the stale kit (G-15)** | ✅ goldens both modes | ❌ **absent** |
| `AppIconSize` | ~ via `no_raw_style_escape` + `MxIconSize` | ✅ `sm < md < lg`; ⚠️ `mdCompact` unordered | ✅ all 4 | ~ | ⚠️ **`mdCompact` missing** |
| `AppBreakpoints` | n/a | ✅ ordered | ✅ both | ✅ compact-scale suite | ✅ both |

### 11.2 · The four coverage gaps, ranked

1. **No stroke guard rule at all** (G-11) — five raw literals live in it, one of them
   arguing for itself on a false premise.
2. **No elevation guard rule** — nothing refuses `elevation: 4` in a feature or a
   hand-rolled `BoxShadow`. Zero violations today, so the rule is free to add and would
   protect a property the project has just spent a milestone establishing.
3. **The brightness/depth invariant is asserted for one component out of three** (G-14).
4. **The Widgetbook token catalog omits two whole foundations** (stroke, elevation) and
   one rung each of radius and icon size (G-8), and `widgetbook_coverage_test.dart`
   checks components only, so no omission can fail.

### 11.3 · Goldens

233 committed PNGs, 152 of them screen demos, 92 in dark. Dark FAB coverage exists
(`deck_list_root_dark.png`, `deck_list_empty_dark.png`), so G-14's fix will move pixels
and must regenerate goldens and republish the gallery in the same turn, per CLAUDE.md.
G-15 is doc/kit/test only and moves nothing.

Two test-side nits, recorded without severity: `mx_components_test.dart:115, 143`
asserts the touch floor as the literals `48` and `40` rather than
`AppSizing.touchTarget`/`controlCompact`, and `deck_tile_geometry_test.dart:141`
restates `80` rather than reading `_kButtonMinWidth`. A test that restates the number
it is protecting cannot fail when the token moves.

---

## 12 · Severity registry

| # | Sev | Finding | Evidence | Closure test |
|---|---|---|---|---|
| **G-15** | **P0** | The kit still specifies the dark glow #435 removed, two docs repeat it, and `css_scale_parity_test` asserts the kit keeps it | `elevation.css:16-24, 38-41` · `css_scale_parity_test.dart:314-337` · `tokyo-component-mapping.md:127` · `architecture.md:1057` | Parity test compares kit ↔ Dart instead of two hard-coded literals |
| **G-14** | **P1** | FAB and SnackBar state `elevation: overlay` and never wire `materialShadowColor`; the invariant is tested for `PopupMenu` alone | `app_fab_theme.dart:62-65` · `app_snackbar_theme.dart:26` · `grep shadowColor lib/` = 2 hits · `component_depth_and_state_test.dart:203` | Loop the level-equal + dark-transparent assertions over every component theme with non-zero elevation |
| **G-1** | **P1** | 7 of 8 `AppSpacing.xxl` sites are dimensions, not gaps; one is an icon size | `card_import_source_step_widget.dart:314` · `card_import_source_summary_widget.dart:63` · `card_import_result_widget.dart:161, 172` | Scan: `AppSpacing.*` may not appear as `width:`/`height:`/`size:`/`dimension:` |
| **G-5** | **P1** | The 32 dp control tier has five spellings and no owner; `MxMetricWell` exists for it and is 24 dp | `app_chip_theme.dart:271` · `mx_breadcrumb.dart:96` · `tag_catalog_row_widget.dart:48` · `card_metric_widget.dart:136` · 2 × `xxl` · `mx_metric_well.dart:9-27` | Scan: no `const double … = 32` under `lib/features/`; Widgetbook story for both well sizes |
| **G-11** | **P2** | No stroke guard rule; 5 raw stroke literals, incl. one arguing `core/theme/` "has no home for a stroke width" | `mx_breadcrumb.dart:14-17` · `mx_radio_rows.dart:108` · `mx_action_button.dart:389, 472` · `search_page_footer_widget.dart:19` · `card_history_section_widget.dart:352` | Guard `no_raw_stroke_width`, scope `ui_and_theme_surfaces` |
| **G-12** | **P2** | 20 borders state a colour and take Flutter's implicit `1.0` instead of `AppStroke.hairline` | 13 in `components/`, 6 in `shared/`, 1 in `features/`; counter-example `app_card_theme.dart:55-61` | AST scan: every `BorderSide`/`Border.all` literal names a width |
| **G-4** | **P2** | `deckTileGutter` duplicates `mxScreenGutter` against its own stated reason for being public | `mx_content_shell.dart:378-385` · `deck_tile_widget.dart:311-314` | `AppBreakpoints.isCompact` appears only in `shared/` and `core/theme/` |
| **G-10** | **P2** | `AppStroke.input` names a component; 3 of its 5 call sites are not inputs | `guess_option_item_widget.dart:84` · `match_tile_widget.dart:241` | Doc, or rename kit + Dart + parity test together |
| **G-19** | **P2** | The spacing guard sees inline literals only; all 25 feature geometry constants sit in its blind spot, including both real violations | `memox-design-token-rules.yaml:56-76` vs §2.3 | Scan test classifying `const double` declarations, structural ones on the 4 dp grid |
| **G-20** | **P2** | Two rendered icon sizes (18, 32) outside `AppIconSize`, both admitted in comments | `card_tile_widget.dart:30, 249-254` · `card_import_result_widget.dart:170-172` | Scan: no bare `Icon(size:)` in `lib/` |
| **G-6** | **P2** | Two button minimum widths (64 global, 80 deck) with no relationship between them | `app_button_themes.dart:47-49` · `deck_study_button_widget.dart:11` | Deck test asserts `>= AppSizing.buttonMinWidth` too |
| **G-16** | **P2** | `materialShadowColor` claims to be the only brightness-dependent channel; two others exist and are both correct | `app_card_theme.dart:55` · `app_backdrop_recipe.dart:14` | Doc-only |
| **G-2** | **P3** | Three spacing rung comments name a minority of their call sites | §3.1 table | Doc-only |
| **G-3** | **P3** | Vertical rhythm is 235 spacer widgets vs 26 `Flex.spacing` — unauditable structurally | scanner counts | none proposed |
| **G-7** | **P3** | `MxBreadcrumb` accepts `lineHeight: 32` with tappable steps; only convention prevents it | `mx_breadcrumb.dart:79, 312` · `mx_breadcrumb_step.dart:81` | Constructor assertion + widget test |
| **G-8** | **P3** | `AppRadius.xl` and `AppIconSize.mdCompact` missing from the Widgetbook token catalog; the coverage test checks components only | `scale_sections.dart:65-68, 89-91` · `widgetbook_coverage_test.dart:67` | Extend coverage test to token members |
| **G-9** | **P3** | Radius guard is `warning` where the spacing guard beside it is `error` | `memox-design-token-rules.yaml:128` | Raise to error — zero violations today |
| **G-13** | **P3** | `MxSearchField`'s boundary is an implicit 1.0 where every other input is `AppStroke.input` (1.5) | `mx_search_field.dart:124-127` vs `app_input_theme.dart:58` | State the width as a token |
| **G-17** | **P3** | `AppElevation.overlay` documented as having "no production caller" — true of `shadowsFor`, false of the level | `app_elevation.dart:156-161` | Doc-only, rides with G-14 |
| **G-18** | **P3** | Four `elevation: 0` literals where `AppElevation.none` exists | `app_app_bar_theme.dart:21` · `app_navigation_bar_theme.dart:67` · `app_bottom_sheet_theme.dart:14` · `app_dialog_theme.dart:30` | Guard pattern `elevation:\s*\d` |
| **G-21** | **P3** | Raw `4` scrollbar thumb thickness — the only unowned dimension in `components/` | `app_scrollbar_theme.dart:15` | Covered by G-11's rule if it matches `thickness:` |

---

## 13 · Implementation order

Five passes. Each is independently shippable and each leaves the tree provably better
than the last. **None of this is done in this branch** — this report is the only file it
adds.

### Pass 1 — restore the specification (G-15, P0)

The only finding where the project's designated answer is currently wrong. Doc, kit and
test only; **no pixel moves**, so no goldens.

| File | Change |
|---|---|
| `design_system/tokens/elevation.css` | Rewrite the `[data-theme="dark"]` block and its prose header to the current model: a crisp `outlineVariant` hairline at every level, plus the drop above `card` the kit does not declare at all |
| `test/design_audit/css_scale_parity_test.dart` | Rewrite `:314` to compare kit ↔ Dart, not two hard-coded literals; fix the test name |
| `docs/design-system/tokyo-component-mapping.md` | `:127` — the dark binding |
| `docs/architecture.md` | `:1057` — Status is `active`, so no dispensation is needed; the task MUST still name the file in scope rather than editing it in passing |

**Decision needed:** the kit has no vocabulary for "a rim plus a drop". Either extend the
CSS to two dark shadow layers, or state in the header that the kit declares the rim and
Dart owns the drop, and have the parity test assert exactly that split.

### Pass 2 — close the depth invariant (G-14, G-16, G-17, G-18)

| File | Change |
|---|---|
| `lib/core/theme/components/actions/app_fab_theme.dart` | add `shadowColor: materialShadowColor(scheme)` |
| `lib/core/theme/components/feedback/app_snackbar_theme.dart` | same |
| `test/core/theme/components/component_depth_and_state_test.dart` | generalise `:203` from `popupMenuTheme` to every component theme with non-zero elevation |
| `lib/core/theme/foundations/app_elevation.dart` | correct the two doc claims (G-16, G-17) |
| four theme builders | `elevation: 0` → `AppElevation.none` |
| `test/demo/goldens/*` | **regenerate** — `TZ=UTC flutter test --tags golden --update-goldens`, then rebuild and republish the gallery at its existing URL |

**Goldens move here.** Dark FAB appears in at least two committed demos. Linux is the
only authoring platform.

### Pass 3 — own the 32 dp tier (G-5, G-1, G-20)

The largest pass and the one that needs a decision before any code.

**Decision needed, in this order:**
1. Does the app have **one** well or two? `MxMetricWell` is 24 dp at `AppRadius.pill`;
   the four hand-built ones are 32 dp at `AppRadius.sm`. If one, `MxMetricWell` grows a
   size axis and the four become call sites. If two, both sizes belong in `AppSizing`
   and both belong in the Widgetbook catalog side by side.
2. Does `AppSizing` gain a 32 rung? `AppSizing`'s header argues against inventing rungs
   *"no screen renders"* — but six screens render this one, which is the same evidence
   that justified `controlCompact` at M100.30. The argument for adding it is stronger
   than the argument that created the last one.
3. Does `AppIconSize` gain a 32 rung, or does the import result's hero glyph move to
   `lg` (40)?

| File | Change |
|---|---|
| `lib/core/theme/foundations/app_sizing.dart` | the 32 rung, if (2) says yes |
| `lib/shared/widgets/mx_metric_well.dart` | the size axis, if (1) says one well |
| 4 × `lib/features/card/presentation/widgets/**` | the wells become call sites or read the token |
| `lib/core/theme/components/selection/app_chip_theme.dart` | `_containerHeight` reads the token |
| `lib/shared/widgets/mx_breadcrumb.dart` | `compactLineHeight` reads the token |
| `widgetbook/lib/tokens/scale_sections.dart` | the tier, and the missing `AppRadius.xl` / `AppIconSize.mdCompact` rows |
| goldens | **regenerate** if any well's rendered size changes |

### Pass 4 — the stroke system (G-11, G-12, G-13, G-10, G-21)

| File | Change |
|---|---|
| `code-verification-guard-v2/.../memox-design-token-rules.yaml` | new `no_raw_stroke_width`, scope `ui_and_theme_surfaces`, named-constant lookahead as `no_raw_duration` uses |
| `lib/shared/widgets/mx_breadcrumb.dart` | `_kFocusUnderlineThickness` → `AppStroke.focus`; delete the false rationale |
| `lib/shared/widgets/mx_radio_rows.dart` | delete the `Divider` overrides — the theme supplies both |
| 3 spinner sites | one owned stroke token, or three reads of it |
| 20 border sites | state `width:` explicitly |
| `lib/shared/widgets/mx_search_field.dart` | state the pill's width as a token (G-13 decision: decorative or control?) |
| `lib/core/theme/foundations/app_stroke.dart` | G-10 doc, or the kit-side rename |

**Decision needed:** G-10 — rename `input` → a role name across kit + Dart + parity test,
or document the historical name. The rename is the honest answer and is the more
expensive one.

### Pass 5 — make the model provable (G-19, G-2, G-4, G-6, G-7, G-8, G-9, G-3)

The pass that converts this report into something CI holds.

| File | Change |
|---|---|
| `test/design_audit/` (new) | the §2 classifier scan: parse `const double` declarations under `lib/features/` and `lib/shared/`, classify STRUCTURAL / OPTICAL / THRESHOLD, assert structural values are on the 4 dp grid or read a token, assert thresholds carry their measurement |
| `test/app/widgetbook_coverage_test.dart` | extend to token members, not just components |
| `memox-design-token-rules.yaml` | radius `warning` → `error`; `elevation:\s*\d` pattern |
| `lib/features/deck/.../deck_tile_widget.dart` | `deckTileGutter` → `mxScreenGutter`; name the second step-down |
| `lib/shared/widgets/mx_breadcrumb.dart` | the constructor assertion |
| `lib/core/theme/foundations/app_spacing.dart` | rung comments as magnitudes-with-examples |
| `test/core/theme/foundations/design_tokens_test.dart` | order `AppRadius.xl` and `AppIconSize.mdCompact`; assert `AppStroke` has exactly four members |

---

## 14 · Decisions the owner has to make

Nothing in passes 3, 4 or 5 should start before these are settled, because each changes
what the code should look like rather than how it is written.

| # | Decision | Options | Report's recommendation |
|---|---|---|---|
| **D1** | How does the kit express dark depth now that it is a rim **plus** a drop? | (a) two CSS layers in the dark block; (b) kit declares the rim, header states Dart owns the drop, parity test asserts that split | **(a)** — the kit is the specification; a specification that declares half a decision is how this divergence started |
| **D2** | One well or two? | (a) `MxMetricWell` grows a size axis, four copies become call sites; (b) two named tiers, both in `AppSizing` and the catalog | **(a)** — the shared widget's own doc already made this call once at M99.26 and was right |
| **D3** | Does `AppSizing` gain a 32 rung? | (a) yes, `controlSmall` / `wellStandard`; (b) no — keep "two heights" and let the wells read `MxMetricWell` | **(a)** — six render sites is stronger evidence than the one that justified `controlCompact` |
| **D4** | Does `AppIconSize` gain 32, and does the flag's 18 stay? | (a) add 32, move 18 → 20; (b) hero glyph → `lg` (40), flag → 20; (c) leave both | **(b)** — one new rung is one more decision; moving two outliers onto existing rungs is none |
| **D5** | `AppStroke.input` — rename or document? | (a) rename kit + Dart + parity test to the role; (b) doc-only note | **(a)** if pass 4 is being done anyway; the file already argues that a token names a role, not a component |
| **D6** | `MxSearchField`'s boundary — decorative or control? | (a) `AppStroke.hairline` (1.0, no pixel change); (b) `AppStroke.input` (1.5, matches every other input) | **(b)** — it is a control and it is the app's most-used input; `strokeAlignOutside` means the extra 0.5 costs no layout |
| **D7** | Is THRESHOLD (§2.2) accepted as a third category? | (a) yes, with the measurement-comment requirement; (b) no — force everything into two boxes | **(a)** — without it the classifier test in pass 5 has to special-case eight constants, and `minimumCellWidth`'s measured 90 becomes a violation |
