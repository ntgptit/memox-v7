# A20 — Final design-system architecture / closure audit

| | |
|---|---|
| **Status** | report only — no code, theme, test, guard, Widgetbook, golden, CI or generated file was changed. This file is the entire diff |
| **Purpose** | Answer one question with evidence: **is design system V1 architecturally closed?** Consolidate A7–A19 plus the five earlier component audits into one canonical registry, resolve their duplicates and conflicts against the current tree, and define the exact exit criteria for declaring V1 closed |
| **Scope** | The whole stack: `lib/core/theme/**` (49 files) · `lib/shared/widgets/**` (43 files) · every production caller under `lib/features/**` and `lib/app/**` · the active guard ruleset · `test/` (471 test files, 237 goldens) · `widgetbook/` · `design_system/` kit parity |
| **BASE_SHA** | **`b2d134b748c214c4130966358249d33fad5c4dea`** — *docs(audit): correct A18's R3 and R7 after review* (#449), identical to `origin/main` at audit time |
| **Pinned SDK** | Flutter **3.44.8** stable · framework `058e0af2c2` · engine `0cd610717b` · Dart 3.12.2 — **present in this container and read directly**, unlike A8/A12/A13 which had no SDK |
| **Not in scope** | Token *values* (AD-14 owns those) · business rules · anything requiring an emulator |
| **Last updated** | 2026-09-04 |

---

## 0 · Method, and what separates this pass from the thirteen it consolidates

Three things were available here that were not available to every source audit,
and each changed a conclusion:

1. **The pinned SDK is installed.** Every framework claim below was read from
   `D:/Setup/flutter/packages/flutter/lib/src/material/` at framework
   `058e0af2c2`, which is exactly the revision `.fvmrc` pins. A8, A12 and A13
   state plainly that they had no SDK; three of their claims are re-derived here
   from source rather than accepted.
2. **The suite runs.** 543 relevant tests were executed at BASE_SHA and the
   active guard was run to completion. Two claims that read as code defects
   turned out to be stale codegen in this worktree (§0.2).
3. **`lib/` has not moved since A7 was written.** `git diff --stat
   3207e7b7..b2d134b7` is **docs-only** — 13 files, all of them the A7–A19
   reports. So every A7–A19 finding is refuted by nothing, and no report is
   stale for code reasons. The five earlier component audits sit at `4cfddd3d`,
   behind exactly one `lib/` commit (`3207e7b7`, M100.35), which touched the FAB,
   snackbar and card themes, `app_colors`, `app_elevation`,
   `app_semantic_colors`, `app_surface_colors` and `mx_card.dart` — the only
   places their findings could have gone stale.

**Every count in this report was measured by a one-process scanner over the tree
at BASE_SHA, and every scanner that produces a violation count was run with a
control group** — a set of names the mechanism under test *should* catch. A
scanner whose control group returns zero has been shown to work before its
findings are believed. That discipline caught three errors in this audit's own
first pass, recorded in §0.1 rather than deleted, because they are the same
errors a reader is likely to repeat.

### 0.1 · Retracted from this audit's own first pass

- **"75 of 150 guard rules are bound to a scope that matches nothing."** True of
  the `memox` ruleset, which is vendored in the repo. **Irrelevant** — the gate
  runs `--ruleset memox-v7` (`dod_check.sh:355`), and every one of `memox-v7`'s
  14 scopes resolves to real files. The `memox` ruleset is the *previous*
  project's, its scopes name `lib/presentation/features/**`, and
  `memox-design-system-rules.yaml`'s own header already records the trap in
  those words: *"its scopes name the layer-first paths … so it would pass green
  while matching nothing."* Re-reporting it would have been re-reporting a fact
  the repo documents. What survives is §10's P3-04: four dead rulesets are still
  vendored, and `memox` is the name a reader would guess.
- **"49 dead design tokens."** An artefact of matching `Class.member` against
  `ThemeExtension` *instance* fields, which are read as `semantic.borderAccent`.
  Corrected count: **zero dead tokens** (§6.4).
- **"`AppBar` is banned by the active guard."** A substring match inside
  `BottomAppBar`. `AppBar` is **not** banned — A8-P2-16 is right and this
  audit's first scan was wrong. The same trap bit a `Colors\.` pattern matching
  inside `semanticColors.`; both were fixed by requiring word boundaries, and
  both are why §8's matrix extracts whole tokens from the rule alternations
  rather than searching for substrings.

### 0.2 · Two failures that were the environment, not the code

`flutter test test/core/theme` initially failed 2 of 405 at *load*:
`_$ReorderDeckController` not found, and four missing `AppLocalizations`
getters. Both are stale generated code in this worktree, not defects — after
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs`,
**543 of 543 pass**. Recorded because a reader who runs the suite in a fresh
worktree will see the same two failures and must not file them.

---

## 1 · Verdict

> **Design system V1 is NOT architecturally closed — but the open surface is one
> layer, not the stack.**
>
> The **token layer and the ThemeData layer are closed, and provably so.** The
> **primitive-ownership layer, the enforcement layer and the accessibility layer
> are not.**

That distinction is the whole finding, and it is sharper than any single source
audit could state, because each of them was looking at one component family.

**What is closed, verified:**

| axis | evidence |
|---|---|
| Colour literals | **115** `0xAARRGGBB` colour literals in `lib/`, **all** in four files under `lib/core/theme/foundations/`. Zero outside. The only hex elsewhere is three FNV hash constants in `study_mode_view_widget.dart:299-301` |
| Material palette | **14** `Colors.*` references in `lib/`, **every one** `Colors.transparent`, **every one** inside `lib/core/theme/`. Zero `Colors.red`-class uses anywhere |
| M3 role contract | Exactly **45** colour roles + `brightness` passed to both schemes — verified against the real 3.44.8 constructor, which takes 50 params: 45 passed, 3 deprecated (`background`, `onBackground`, `surfaceVariant`) and `surfaceTint` refused |
| `surfaceTint` | Architecturally **unreachable**. Never passed, never read in `lib/`; the only SDK consumer of `colorScheme.surfaceTint` as a default is `BottomAppBar` (`bottom_app_bar.dart:301`), which the app does not use; `SnackBar`, `TimePicker` and `FloatingActionButton` never mention `surfaceTintColor` at all |
| ThemeData coverage | **56** widget→slot mappings; `rendered ⇒ themed` and `themed ∧ ¬rendered ⇒ named reason` both enforced by `theme_coverage_test.dart` and **green**; the one blind spot (`DropdownButton`, which has no slot) is named and closed via `canvasColor`/`disabledColor` |
| Local theme override | **Zero** `Theme(`, `IconTheme(`, `DefaultTextStyle(` overrides in `lib/features/**` or `lib/shared/**`. The theme is applied once, in `app.dart:79-94`, with all four slots wired |
| Motion | **Zero** literal `Duration(` used as a `duration:` in `lib/`. All 6 animation sites route through `AppMotionPolicy.durationOf` |
| Feature surfaces | All **29** `BoxDecoration(` in feature presentation are token-fed; zero raw colours. All 9 visual-typed public fields on shared widgets are fed tokens at every call site |
| Dead tokens | **Zero.** All 8 zero-production-reference candidates resolve to an in-file consumer with production callers, a deliberate provenance record, or a documented kit-parity anchor (§6.4) |
| Dialogs | **Zero** raw `showDialog` in `lib/features/`. All 4 live in `lib/shared/widgets/`, one per dialog shape |

**What is open, verified:**

| axis | evidence |
|---|---|
| **Composition ownership** | **8** Material component names are composed raw in `lib/features/*/presentation/` at **40 sites**, and the active guard bans none of them (§8) |
| **Enforcement** | The guard runs to completion and prints *"Code verification passed. No violations found."* while those 40 sites exist. A control group of 44 names the guard *does* ban returns **0** violations — the guard works where it looks, and does not look here |
| **Sheets** | Dialogs have a route-opening primitive per shape; sheets have none. 16 raw `showModalBottomSheet` calls, with the bottom inset spelled 5 ways and one sheet header marked `Semantics(header: true)` out of 17 |
| **Text restyle** | `textStyles.<role>.copyWith(` is a fourth spelling of "restyle a rung" that `no_text_restyle`'s three patterns miss — **9** live sites, 8 of them applying a value that `AppInk.quiet` already *is* |
| **Accessibility** | Two WCAG AA failures at HEAD, both confirmed against SDK source, and **zero** keyboard primitives (`Shortcuts`, `CallbackShortcuts`, `LogicalKeyboardKey`, `SingleActivator`, `KeyboardListener`, `onKeyEvent`) anywhere in `lib/` |
| **High contrast** | Both high-contrast themes are wired into `MaterialApp` and verified at token level, but **no screen renders under them, no golden pictures them, and Widgetbook offers only Light and Dark** |
| **Kit parity** | The elevation parity gate compares the kit to string literals copied from the kit. Kit and Dart have since diverged on the dark rim's **colour, blur and spread** — all three — and the gate cannot see any of it |

**The honest one-line answer to "does feature code invent colours, states,
geometry, radius, elevation, focus or selection language?"** — No, it does not
invent *values*; that half is closed and enforced. It does invent *composition*:
for 8 component families a feature assembles a Material widget directly instead
of reaching for a primitive, and nothing stops it.

---

## 2 · Closure status by layer

The stack, bottom to top, with the enforcement that holds each one.

| # | Layer | Files | Status | Held by |
|---|---|---|---|---|
| 1 | Foundations (palette, spacing, radius, stroke, elevation, durations, breakpoints, icon size, sizing) | 14 | **CLOSED** | `design_tokens_test`, `app_palette_test`, `css_token_parity_test`, `memox_v7.design_token.*` (5 rules) |
| 2 | Schemes + semantics (45 M3 roles, `AppSemanticColors`, compact scale, high contrast) | 3 + 1 | **CLOSED** | `color_scheme_roles_test`, `m3_role_bindings`, two `color_scheme_*_are_m3_roles` guard rules (allowlist, both directions) |
| 3 | States + ink + typography (`AppInteractionStates`, `AppInk`, `AppTypography`, `AppTextStyles`) | 1 + 1 + 2 | **CLOSED with one leak** | `app_ink_test`, `app_typography_test`, `no_bare_font_weight`, `no_text_restyle` — the leak is the fourth restyle spelling, §10 P1-02 |
| 4 | Accessor extension (`context.colors` / `texts` / `semanticColors` / `textStyles`) | 1 | **UNAUDITED** — the only theme file no report names, and 367 call sites depend on it | nothing; and it is where the §10 P1-02 hole originates (§9.3) |
| 5 | Component themes (26 `ThemeData` slots) | 26 | **CLOSED** | `theme_coverage_test` (both directions + blind-spot + self-test), `component_theme_typography_test`, `m3_role_contract_test`, `app_planned_themes_test` |
| 6 | Shared primitives (`Mx*`) | 43 | **CLOSED as to values, OPEN as to completeness** | `mx_stress_test` (specimen per file), `widgetbook_coverage_test` (entry per component, 5 documented exclusions), 34 component test files — but no primitive owns a sheet route |
| 7 | Feature composition | 261 presentation files | **OPEN** | 40 unguarded raw-Material sites; 9 unguarded restyles |
| 8 | Kit parity (`design_system/`) | — | **OPEN / self-referential** | `css_scale_parity_test` compares the kit to its own literals for elevation |

Layers 1–3 and 5 are the ones "design system V1" most naturally names, and they
are closed. Layer 4 is a coverage hole with a consequence. Layers 6–8 are the
work left.

---

## 3 · Coverage map — every ThemeData family, shared widget and foundation

Attribution below was built mechanically: each file's basename was searched
across all 21 reports in `docs/reviews/`. `AUDITED` means at least one report
names the file. **No file is left unexplained.**

### 3.1 · Foundations (14) — all AUDITED

`app_border_colors` A19·BTN — `app_breakpoints` A16·A18·PAR —
`app_colors` A19·BTN·PAR — `app_durations` A17·PAR —
`app_elevation` A9·A16·ROW·PAR — `app_icon_size` A13·PAR —
`app_material_roles` BTN — `app_motion_policy` A17 — `app_radius` A7·PAR —
`app_semantic_colors` A12·PAR — `app_sizing` A8·A10·A11·A16·BTN·ROW —
`app_spacing` A16·PAR — `app_stroke` A16·A17 — `app_surface_colors` BTN

### 3.2 · Schemes, states, typography, extensions (8) — 7 AUDITED, 1 MISSING

| file | coverage |
|---|---|
| `app_color_scheme.dart` | A19 · BTN · INPUT |
| `app_compact_scale.dart` | A15 · A16 · A18 · ROW · PAR |
| `app_high_contrast.dart` | A12 · A13 · A19 |
| `app_interaction_states.dart` | A7 · A11 · A17 · BTN · ROW |
| `app_text_styles.dart` | A15 |
| `app_typography.dart` | A8 · A13 · A15 · A16 · PAR |
| `app_ink.dart` | A15 · A17 |
| **`theme_context_extension.dart`** | **MISSING — named by no report.** See §9.3; this is registered as P1-05 |

### 3.3 · Component themes (26) — all AUDITED

Every one of the 26 files under `lib/core/theme/components/` is named by at
least one report; the thinnest coverage is single-report and is listed so the
owner can see where a second pair of eyes never went:

| coverage | files |
|---|---|
| 1 report | `app_progress_theme` (A12) · `app_text_selection_theme` (INPUT) · `app_time_picker_theme` (A11) · `app_slider_theme` (A10) · `app_backdrop_recipe` (A16) · `app_card_theme` (A16) |
| 2 reports | `app_scrollbar_theme` · `app_tooltip_theme` · `app_tab_bar_theme` · `app_snackbar_theme` · `app_date_picker_theme` |
| 3+ reports | the remaining 15, led by `app_chip_theme` (8) and `app_button_themes` (7) |

`app_card_theme.dart` at one report is the notable thin cell: it is the surface
M100.35 last changed, and only A16 looked at it afterwards.

### 3.4 · Shared widgets (43) — all AUDITED, 2 ZERO-CALLER

All 43 are named by at least one report; A14 covers the whole set by design.
Classification against the four buckets the brief asks for:

| class | count | members |
|---|---|---|
| **AUDITED, production callers** | 41 | everything not listed below |
| **ZERO CALLER / INTENTIONALLY DEFERRED** | 1 | `MxAlertDialog` + `showMxAlert` — zero production callers, and the reason is written into the widget's own doc (`mx_alert_dialog.dart:15-27`) with two rejected candidates named, plus `docs/wbs.md` M99.59, plus a Widgetbook entry and 2 tests. This is the model of a documented deferral, not a defect (A9-14, A14-F2) |
| **DEAD API within a live widget** | 1 | `MxProgressBarShape.flush` — **zero** callers in `lib/`, `test/` or by name in Widgetbook; all three production `MxProgressBar(` sites take the `pill` default. Its doc claims the deck card "seats one on its base", but `deck_tile_widget.dart:233` puts the bar inline in a row and passes no `shape:`. Registered as P3-01 |
| **MISSING audit** | 0 | — |

Four public declarations initially scanned as zero-caller and are **not**:
`MxDialogToneX` and `MxFailureLabels` are extensions whose members are called on
the extended type (`tone.ink`, `context.mxWriteFailure` — 6 production callers);
`MxFormDialog` is reached through `showMxPromptDialog`, which has a caller at
`card_bulk_overlays_widget.dart:162`; `MxPromptParse` types that function's
parameter.

---

## 4 · Architecture — how the stack actually resolves

Read from the composition root down, with the mechanism at each hop.

```
app.dart:79-94
  theme / darkTheme / highContrastTheme / highContrastDarkTheme
    → buildLightTheme() … buildHighContrastDarkTheme()      (memoised, 4 singletons)
        → _buildTheme(scheme, semantic)
            ├─ ThemeData(useMaterial3, colorScheme, visualDensity: standard,
            │            materialTapTargetSize: padded, platform: android,
            │            fontFamily: bodyFamily)
            ├─ framework fall-throughs: hoverColor focusColor highlightColor
            │            splashColor canvasColor disabledColor iconTheme
            ├─ extensions: [AppSemanticColors, AppTextStyles]
            └─ 26 component-theme builders
                        ↑ read ColorScheme / TextTheme / AppSemanticColors only
                          (never the four palette files — enforced by
                           no_theme_token_imports's successor scoping)
feature widget
  → context.colors / texts / semanticColors / textStyles   (theme_context_extension.dart)
  → Mx* primitive                                          (lib/shared/widgets/**)
      → raw Material widget                                (legitimate here only)
```

Four properties of this shape are load-bearing and all four hold at BASE_SHA:

1. **The theme is built exactly four times and memoised.** `app_theme.dart`'s
   header explains why this is correctness and not optimisation:
   `ThemeData.==` compares component themes, component themes hold
   `resolveWith` closures with no value equality, and with
   `themeAnimationDuration: Duration.zero` `MaterialApp` mounts a plain `Theme`
   whose `updateShouldNotify` is `data != oldWidget.data`. Non-memoised, every
   settings-stream emission would invalidate every `Theme.of` dependent.
   `app_theme_identity_test.dart` pins both halves.
2. **`platform: TargetPlatform.android` is declared, not detected**, so the
   Playwright/web E2E channel measures the geometry and page transition the
   release target renders. Paired with `visualDensity: standard` and
   `materialTapTargetSize: padded` for the same reason.
3. **Component themes may not read the four palette files.** They take
   `ColorScheme`, `TextTheme`, `AppSemanticColors` or a closed enum. This is
   what makes the high-contrast themes possible at all — they transform the
   scheme, and a builder that froze a palette constant would not follow.
4. **The high-contrast pass adds no hex.** `highContrastSemantics` re-points
   four tokens via `copyWith`, `highContrastScheme` re-points `outline` and
   `outlineVariant`. Four swaps, zero new colours.

### 4.1 · Two stale file references inside the architecture layer

`app_theme.dart:266` and `:288`, and `app_sizing.dart:9` and `:40`, cite
`app_modal_themes.dart` and `app_planned_themes.dart` in the present tense.
**Neither file exists** — M100.31 dissolved them into `components/`, and
`docs/wbs.md:17327` records it. `docs/design-system/theme-architecture.md:181`
describes them correctly as history; the four code comments do not.
`test/core/theme/components/app_planned_themes_test.dart` is also named after
the deleted file. Registered as P3-02.

---

## 5 · Role architecture — the 45, verified against the real SDK

The `ColorScheme` constructor in Flutter 3.44.8 takes **50** named parameters.

| bucket | n | names |
|---|---|---|
| Passed by both schemes | **46** | 45 colour roles + `brightness` |
| Deprecated, refused | 3 | `background`, `onBackground`, `surfaceVariant` |
| Tint mechanism, refused | 1 | `surfaceTint` |

The 45 break down exactly as `app_color_scheme.dart`'s header claims: 26
standard (the `primary`/`secondary`/`tertiary`/`error` quartets; `surface`,
`onSurface`, `onSurfaceVariant`; `outline`, `outlineVariant`; the `inverse*`
trio; `shadow`, `scrim`) and 19 add-ons (`surfaceDim`, `surfaceBright`, five
`surfaceContainer*`, twelve `*Fixed`). **The header is correct and is now
verified rather than asserted.**

Both directions are locked by allowlist, not by naming what is out:
`color_scheme_arguments_are_m3_roles` (file mode, balanced-paren walk over
`ColorScheme(`, the four brightness constructors, and `copyWith` on the three
identifiers the codebase gives a scheme) and `color_scheme_reads_are_m3_roles`
(line mode, over `dart_lib`). A name absent from the list is a finding without
having to be enumerated — which is why the three deprecated roles need no
mention to stay out.

### 5.1 · `surfaceTint` is unreachable, and this was checked rather than assumed

`ColorScheme.surfaceTint`'s getter is `_surfaceTint ?? primary`
(`color_scheme.dart`), so an unpassed `surfaceTint` resolves to **indigo**, not
to transparent. That would matter if anything read it. Nothing does:

- `lib/` never reads `scheme.surfaceTint`; five component themes set
  `surfaceTintColor: Colors.transparent` explicitly.
- `Material.surfaceTintColor` defaults to `null`, and
  `ElevationOverlay.applySurfaceTint` returns the colour untouched when the tint
  is null or transparent (`elevation_overlay.dart:32`).
- Of the 58 `*DefaultsM3` classes in the SDK, exactly one resolves
  `colorScheme.surfaceTint` as a default: `_BottomAppBarDefaultsM3`
  (`bottom_app_bar.dart:301`). `BottomAppBar` has **zero** references in `lib/`.
- `SnackBar`, `TimePicker` and `FloatingActionButton` — the three elevated
  surfaces whose `*DefaultsM3` sets no `surfaceTintColor` — never mention the
  property at all, so there is nothing to fall through.

`app_elevation.dart:54-59` already states this conclusion; it is confirmed here
against source. **Elevation in this app has exactly one visual effect, the
shadow**, which is what makes `materialShadowColor`'s dark-transparent trick
sufficient.

### 5.2 · App semantic colours

`AppSemanticColors` carries **27 stored fields and 3 derived getters**
(`overdue → danger`, `dueContainer → streakContainer`,
`onDueContainer → onStreakContainer`). Two properties worth naming:

- **`lerp` interpolates all 27.** A field omitted from `lerp` snaps during a
  theme change and the snap is visible only on the one screen that uses it; the
  test compares a full mid-point rather than spot-checking.
- **The aliases exist so a call site can say what it means.** `overdue` is
  `danger` — one red system — but `danger` also names delete buttons, so an
  audit asking "where is overdue painted?" cannot answer via `danger` alone.
  This is the closed-vocabulary pattern working as intended.

---

## 6 · API closure — every visual escape hatch on the shared surface

### 6.1 · The census

Across 43 shared widgets there are exactly **9** public fields with a
visually-typed parameter. Two of the nine are data, not visual language.

| field | type | verdict |
|---|---|---|
| `MxProgressBar.value` | `double` | data (0–1, clamped) — not a hatch |
| `MxSessionTopBar.progress` | `double` | data — not a hatch |
| `MxMetricWell.wellColor` | `Color?` | **open.** Every one of 8 production call sites feeds a semantic token (`semantic.surfaceMuted`, `semantic.streakContainer`, `semantic.dangerContainer`, `semantic.dueContainer`, `context.colors.primaryContainer`). Zero raw colours |
| `MxTextField.textStyle` | `TextStyle?` | **open.** One production caller, `card_editor_form_widget.dart:93`, feeds `context.texts.titleLarge` |
| `MxContentShell.padding` | `EdgeInsetsGeometry?` | **open**, token-fed |
| `MxRadioRows.contentPadding` | `EdgeInsetsGeometry` | **open**, defaults `EdgeInsets.zero`; the one override is `EdgeInsets.symmetric(horizontal: AppSpacing.lg)` |
| `MxFocusRing.borderRadius` | `BorderRadius` | **open by necessity** — a focus ring must match the host's shape; there is no closed alternative |
| `MxBreadcrumb.lineHeight` | `double` | **effectively closed** — default `AppSizing.touchTarget`, the one override is `MxBreadcrumb.compactLineHeight`, a named constant on the widget itself |
| `MxSubheaderBand.gutter` | `double` | **open**, shell-derived |

**So the API surface is empirically closed and structurally open.** Nothing in
production abuses a hatch; nothing in the type system prevents it.

### 6.2 · The sharpest statement of it is inside one widget

`MxMetricWell` takes `AppInk tint` — a **closed enum** — for the glyph, and
`Color? wellColor` — **open** — for the fill behind it. The file documents the
asymmetry deliberately (`mx_metric_well.dart:18-27`): M100.5 closed `tint`
because all five call sites already spelled `<AppInk>.resolve(context)` longhand,
and left `wellColor` overridable "because the deck hero genuinely moves it with
the deck's state".

That reasoning is sound about *variability* and silent about *vocabulary*. The
well moves with state — and it moves between exactly five semantic tokens. A
closed `AppWellFill` enum mirroring `AppInk` would keep the variability and
close the vocabulary. Registered as P2-01, with the owner decision stated: V1
may accept empirical closure plus a guard, or require structural closure.

### 6.3 · Style-vocabulary hatches the guard does not watch

`no_raw_style_escape` bans `ButtonStyle(`, `BorderSide(`, `BoxShadow(`,
`ShapeDecoration(`, `RoundedRectangleBorder(`, `.styleFrom(`,
`WidgetStateProperty` and `Icon(size: <digit>)` in feature code. Control group:
**0 violations** for all five named constructors. Its neighbours are unwatched:

| unwatched | sites in feature presentation | all token-fed? |
|---|---|---|
| `BoxDecoration(` | **29** | **yes** — verified by balanced-paren walk over every call: zero raw colours, every one references `semantic.*` / `scheme.*` / `AppRadius` / `AppSpacing` / `cardStateColor` |
| `Border.all(` | 3 | yes (`ink`, `outline`, `skin.outline`) |
| `DecoratedBox(` | 10 | yes |
| `ClipRRect(` / `Opacity(` | 2 / 3 | n/a — geometry, not colour |

`BoxDecoration` is the general-purpose "invent a surface" constructor: it takes
colour, border, radius, gradient and shadow at once. That 29 sites use it and
**none** invents a value is a real closure result. That nothing prevents the
thirtieth is P2-02.

### 6.4 · Dead tokens: zero

A naive scan reports 49; one correction gives 8; verifying each gives **0**.

| candidate | resolution |
|---|---|
| `AppBreakpoints.compact` | consumed by `isCompact()` in its own file, which has **6** production call sites across 4 files |
| `AppTypography.cjkFallbackFamily` / `japaneseFallbackFamily` / `simplifiedChineseFallbackFamily` | all three consumed as bare identifiers inside `cjkFallback` (`app_typography.dart:70-72`) |
| `AppElevation.scale`, `AppSpacing.scale` | test-facing manifests; the parity and ordering tests iterate them |
| `AppStateOpacity.disabledContent` | a **provenance record** — its sibling `disabledSurfaceBlend`'s doc says so explicitly: "this constant records where the result came from" |
| `AppColors.seed` | documented parity anchor: "it stays because the design system names it (`--color-seed`) and the parity test pins the two together" — pinned at `css_token_parity_test.dart:91` |

This is worth stating as a verified negative, because it is the audit item most
likely to produce a confident wrong answer.

---

## 7 · Raw Material and feature-level drift

### 7.1 · By layer

Raw high-level Material usage, counted over `lib/` with comments stripped:

| widget / call | theme | core | shared | app | **features** |
|---|---|---|---|---|---|
| `showModalBottomSheet` | 0 | 0 | 1 | 0 | **16** |
| `Divider` | 0 | 0 | 1 | 0 | **10** |
| `CircularProgressIndicator` | 0 | 0 | 3 | 0 | **7** |
| `Material` | 0 | 0 | 6 | 0 | **3** |
| `Chip` / `ActionChip` | 0 | 0 | 0 | 0 | **2** |
| `TextField` | 0 | 0 | 2 | 0 | **1** |
| `showTimePicker` | 0 | 0 | 0 | 0 | **1** |
| `showDialog` | 0 | 0 | **4** | 0 | 0 |
| `AlertDialog` | 0 | 0 | 3 | 0 | 0 |
| `InkWell` | 0 | 0 | 5 | 0 | 0 |
| `ListTile` / `CheckboxListTile` / `RadioListTile` / `SwitchListTile` | 0 | 0 | 5 | 0 | 0 |
| every other button / chip / bar / control | 0–1 | 0 | 1–3 | 0 | **0** |

`lib/shared/widgets/` building raw Material is correct — that is where
primitives are defined, and `memox-design-system-rules.yaml`'s scope note says
so. `lib/app/` at zero and `lib/core/theme/` at one (a doc-adjacent
`IconButton` reference) are both clean.

### 7.2 · The drift is composition, not values

This is the correction that most changes how the 40 sites should be read.
**Seven of the eight drifting families are in `theme_coverage_test.dart`'s
widget→slot map, and that test enforces `rendered ⇒ themed` and is green.** So a
raw `Divider(` in a feature draws the house hairline; a raw
`CircularProgressIndicator(` draws the house indicator; the raw `TextField(`
takes `inputDecorationTheme`; the 16 sheets take `bottomSheetTheme`.

| drifting name | in the slot map? | therefore |
|---|---|---|
| `showModalBottomSheet` | yes → `bottomSheetTheme` | themed |
| `Divider` | yes → `dividerTheme` | themed |
| `CircularProgressIndicator` | yes → `progressIndicatorTheme` | themed |
| `Chip`, `ActionChip` | yes → `chipTheme` | themed |
| `TextField` | yes → `inputDecorationTheme` | themed |
| `showTimePicker` | yes → `timePickerTheme` | themed |
| `Material` | **no** — not a component with a slot | primitive; carries no house decision |

**What is lost is ownership, not pixels.** A raw `Divider(` cannot be given a
new decision — an inset, a semantic exclusion, a compact variant — in one place,
because there is no one place. That is exactly the failure A14-F1 records for
`MxActionSheet`'s raw `ListTile` (no focus ring, because no primitive owned the
row) and A12-#2 records for the silent spinner (no `semanticsLabel`, because no
primitive owned the spinner).

### 7.3 · The sheet asymmetry, quantified

| | dialogs | sheets |
|---|---|---|
| route-opening helper in `lib/shared/` | **4** — one per shape (`showMxConfirm`, `showMxAsyncConfirm`, `showMxPromptDialog`, `showMxAlert`) | **1** (`showMxFormSheet`), covering one shape |
| raw route calls in `lib/features/` | **0** | **16** |
| files with a raw route call | 0 | 13 |
| of those, using no shared sheet helper at all | — | **5** (`card_bulk_overlays_widget`, `deck_reset_progress_widget`, `deck_scheduler_change_widget`, `study_entry_screen` ×3, `trash_restore_target_sheet_widget`) |
| bottom-inset mechanisms in use | one (`MxDialogMetrics`) | **5** — `SafeArea` (7 files), `useSafeArea:` (2), `MxSheetInsets` (2), `mxSheetBottomObstruction` (1), raw `viewInsets` (1), bare `padding: EdgeInsets` (2) |
| headers marked `Semantics(header: true)` | shared via `MxDialogHeader` | **1 of 17** (`card_export_sheet_widget.dart:306`) |

A9 reported this as five separate findings (A9-01, -02, -03, -05, -06). It is
one structural absence with five symptoms: **there is no `MxSheet`.**

### 7.4 · The text-restyle leak

`no_text_restyle` watches three spellings in `presentation_files`. Control
group, run at BASE_SHA: `texts.<rung>.copyWith(` **0**,
`textTheme.<rung>.copyWith(` **0**, `withWeight(…).copyWith(` **0**. The rule
works. The fourth spelling it does not watch:

`textStyles.<role>.copyWith(` — **9 live sites**, all in `lib/features/card/`:

| what it sets | sites |
|---|---|
| `color: context.colors.onSurfaceVariant` | 8 |
| `color: context.colors.onSurface` | 1 |

`AppInk.quiet` resolves to `colors.onSurfaceVariant` and `AppInk.stated` to
`colors.onSurface` (`app_ink.dart:89-90`), and `InkedTextStyle.inked` is
`copyWith(color: ink.resolve(context))` with a no-op `fontFeatures` pass-through
when `isEmphasized`/`isTabular` are false. **So all 9 migrate to
`.inked(context, AppInk.quiet|stated)` with provably zero pixel change.**
`app_ink.dart:118` calls `inked` "the one legal way for a feature to colour a
text rung"; nine sites use another way, in one feature, because the guard's list
has three entries where the accessor extension has four.

A15-F4 already registered this with the same 9 sites and the same fix. It is
confirmed here with a control group and an exact zero-pixel-change proof.

### 7.5 · And the same rule stops at the feature boundary

A15-F5, verified: `no_text_restyle` is scoped to `presentation_files`, so
`lib/shared/widgets/` is out of scope, where there are **14** open-colour
`.copyWith(color:)` restyles. Ten would be caught by the existing line patterns
if the scope widened; **four are `withWeight(…).copyWith(` launderings and three
of those four are multi-line**, so they escape a line-scoped pattern even with
the scope widened. `mode: file` with a balanced-paren walk is required, not
optional.

There is a real architectural question inside this, and it is an owner decision.
The design-system rules file argues correctly that `lib/shared/` must be out of
scope for *raw-widget* rules — "`lib/shared/` is where the primitives
legitimately build the raw widgets these rules ban". **That argument does not
transfer to colours.** A primitive must build a `ListTile`; it need not invent
an open colour when `AppInk` exists. Scope is therefore a per-rule decision, and
`no_text_restyle` is a rule whose scope should include the shared layer.

---

## 8 · The enforcement gap, measured

This is the finding that makes the closure question answerable at all, because
it explains why every existing gate is green.

### 8.1 · The guard is green

```
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
  → 79 rules run
  → "Code verification passed. No violations found."
```

### 8.2 · The active ruleset

`memox-v7` — 58 project rules across 10 files (9 design-system, 5 design-token),
plus common/dart/flutter sets, 79 rules executed. **All 14 scopes resolve to
real files**; zero rules bound to an empty scope. The `memox` ruleset that does
have that problem is not the one running (§0.1).

### 8.3 · The coverage matrix, whole tokens only

Names extracted from the rule alternations as whole tokens, then each checked
for live raw use in the guard's own `presentation_files` scope with the guard's
own comment-exempt line pattern.

| | n | outcome |
|---|---|---|
| **Guarded** | **44** | `AlertDialog · Badge · BottomAppBar · BottomNavigationBar · Card · Checkbox · CheckboxListTile · Dialog · DropdownButton · DropdownButtonHideUnderline · DropdownMenu · ElevatedButton · ExpansionTile · FilledButton · FloatingActionButton · IconButton · InkResponse · InkWell · ListTile · MaterialBanner · NavigationBar · NavigationDrawer · NavigationRail · OutlinedButton · PopupMenuButton · PopupMenuItem · Radio · RadioGroup · RadioListTile · RangeSlider · SearchAnchor · SearchBar · SegmentedButton · SimpleDialog · Slider · SnackBar · SnackBarAction · Switch · SwitchListTile · TabBar · TextButton · TextFormField · ToggleButtons · showDialog` |
| **Unguarded, live violations** | **8 names / 40 sites** | see below |
| **Unguarded, latent** | **19** | `AppBar · BottomSheet · ChoiceChip · DataTable · Drawer · DropdownButtonFormField · FilterChip · Ink · InputChip · LinearProgressIndicator · Scaffold · SliverAppBar · Stepper · Tooltip · VerticalDivider · showAboutDialog · showBottomSheet · showDatePicker · showMenu` |

**Control group: the 44 guarded names produce 0 violations.** The guard is not
broken; it is blind in 27 places.

| unguarded, live | sites |
|---|---|
| `showModalBottomSheet` | 16 |
| `Divider` | 10 |
| `CircularProgressIndicator` | 7 |
| `Material` | 3 |
| `Chip` | 1 |
| `ActionChip` | 1 |
| `TextField` | 1 |
| `showTimePicker` | 1 |
| **total** | **40** |

Two of the latent 19 are the ones A8-P2-16 named — `AppBar` and `SliverAppBar`
— plus `Scaffold`, which A8 also named and which `memox_v7.screen_shell.*` does
not exist to cover in this ruleset. `TextFormField` is guarded and bare
`TextField` is not, which is a one-word hole with one live violation.

### 8.4 · Why no source audit reported the whole thing

Each audit checked its own family's rule and found it present or absent
locally: A8 found three navigation names missing (P2-16), A9 found sheets open
(§11.2), A13 found icon rules fine, A15 found the restyle pattern short
(F4/F5). **Nobody enumerated the pattern list against the Material surface as a
set**, which is the only way the 8/40 and the latent 19 become visible. That is
this pass's contribution, and it is why P0-01 is registered as new rather than
as a consolidation.

---

## 9 · Test architecture

### 9.1 · The five tiers, and what each can and cannot see

| tier | mechanism | files | blind to |
|---|---|---|---|
| **Source / AST guards** | 79 regex + balanced-paren rules, `check_architecture.sh`, `architecture_boundary_test.dart`, `command_query_separation_test.dart` | — | anything not on a pattern list (§8); anything expressed as a constant rather than a literal (A16-G-19) |
| **Structural / coverage guards** | `theme_coverage_test` (widget→slot, both directions, blind-spot, self-test), `widgetbook_coverage_test`, `mx_stress_test`, `css_token_parity_test`, `css_scale_parity_test`, `design_parity_gate_test` | 7 in `contracts/` + 7 in `design_audit/` | a decision **not made** leaves no trace — this is exactly the class `theme_coverage_test` was built for, and it says so |
| **Runtime semantics / state** | `m3_role_contract_test`, `m3_combined_state_test`, `app_toggle_themes_test`, `app_ink_test`, `mx_action_button_state_matrix_test`, `mx_card_recipes_test` | ~40 | states no theme declares; components nothing renders |
| **Geometry / layout** | `deck_text_fit_test`, `hero_action_width_test`, `compact_scale_test`, `visual_audit/**` | 12 + 20 helpers | widths never pumped — **360 and 375 dp are rendered nowhere** (A18) |
| **Goldens** | 237 PNGs — `test/demo` 152, `shared/widgets/goldens` 76, `shared/widgets/failures` 4, `design_preview` 4, `deck` 1 | Linux-authored, `ubuntu-latest`, PR-gated on `needs_goldens` | **0 high-contrast**; 148 of 152 demo goldens at 393×852 |
| **E2E / device** | `integration_test/` — 8 scenarios, local-only gate | — | not run by CI by design; business correctness moved to host (133 scenarios) |

Totals: **471 test files, 122 helpers, 237 goldens**; 543 relevant tests green
at BASE_SHA.

### 9.2 · What the tiers cover well

The structural tier is unusually strong and deserves saying so plainly, because
it is what makes the ThemeData verdict trustworthy rather than asserted:
`theme_coverage_test` scans `lib/` for widgets, asks the built theme whether the
slot was filled, enforces the **converse** (a themed-but-unrendered component
needs a written reason), enforces the converse-of-the-converse (an allowlist
entry that gains a caller is stale), **names its own blind spot**
(`DropdownButton` has no slot) and **tests its own mechanism** (a stripper that
strips nothing, a scan that matches nothing, both would pass forever). Four of
those five properties are absent from most coverage guards.

### 9.3 · The gap that produced the P1-02 leak

`theme_context_extension.dart` defines the four accessor names the whole app and
half the guard patterns are written in terms of — `colors`, `texts`,
`semanticColors`, `textStyles` — across **367** call sites in `lib/`. It is the
**only** file in `lib/core/theme/` that no report names, and it has no test of
its own.

The consequence is concrete: `no_text_restyle` watches `texts.` and
`textTheme.`, and `color_scheme_reads_are_m3_roles` allowlists
`scheme|colors|colorScheme`. **`textStyles` appears in neither.** Nobody
cross-checked the accessor surface against the pattern lists, because nobody
audited the accessor surface. The coverage hole and the enforcement hole have
one root cause.

---

## 10 · Canonical finding registry

Deduplicated across all 21 reports and refreshed against BASE_SHA. `Sources`
names the reports that own the finding — `A20` means this pass registered it.
Every P0/P1 carries evidence, the contract it violates, the resolution, its
dependencies, exact files and a closure test.

Axis: **ENF** enforcement · **CMP** composition · **A11Y** accessibility ·
**PAR** kit parity · **COV** coverage · **API** api/dead code · **DOC** docs.

### P0 — closure is unverifiable, or a user is blocked

---

**A20-P0-01 · ENF · The active guard's raw-widget list has an 8-name hole with 40 live violations, and reports green**

- **Sources.** A20 (new, systemic). Fragments seen by A8-P2-16 (`AppBar` /
  `SliverAppBar` / `Scaffold`), A9 §11.2 (sheets), A15-F4/F5 (restyle).
- **Evidence.** §8.3. Control group of 44 guarded names → **0** violations. 8
  unguarded names → **40** violations, in the guard's own `presentation_files`
  scope, using the guard's own comment-exempt line-pattern idiom. Guard run:
  *"Code verification passed. No violations found."*
- **Current code.** `memox-design-system-rules.yaml`,
  `memox_v7.design_system.no_raw_widget`, nine `patterns:` alternations.
- **Violated contract.** The rule's own message: *"No raw Material component
  widgets in feature code… A widget with no Mx wrapper yet goes through the
  admission rule in the flutter-theme-design skill first — wrapper, tests, then
  guard — never raw-first."* CLAUDE.md: *"No hardcoded colors, text styles, or
  padding"* is enforced; the composition half is not.
- **Resolution.** Add the 8 live names **and** the 19 latent ones to
  `no_raw_widget`, at `severity: warning` first (the house pattern — A19 Step 1,
  A16-G-9's warning→error promotion). Then fix, then promote to `error`. Each
  new pattern must be **fault-injected**: add the pattern, confirm the guard
  goes red on a known site, then proceed. A guard added without that step is a
  green that means nothing.
- **Dependencies.** Blocks nothing; **blocked by nothing**. This is the root of
  the DAG: until the guard can see the defects, every later phase is unverifiable.
- **Files.** `code-verification-guard-v2/registries/projects/memox-v7/rules/memox-design-system-rules.yaml`
- **Closure test.** A two-way probe test: for every name in the rule's
  alternations, assert the pattern matches a synthetic violation and does not
  match the same text in a comment; and a scan asserting zero live matches in
  `presentation_files`. Must be red today for 40 sites.

---

**A20-P0-02 · A11Y · `browse` has no accessible operation for keyboard-only and non-drag users**

- **Sources.** A19-01 (the corpus's only P0 in an accessibility audit).
- **Evidence.** Refreshed at BASE_SHA and confirmed exactly: `lib/` contains
  **zero** occurrences of `Shortcuts(`, `CallbackShortcuts`,
  `LogicalKeyboardKey`, `SingleActivator`, `KeyboardListener` or `onKeyEvent`.
  `study_mode_view_widget.dart:166` passes `actions: const <StudyAction>[]`;
  `study_card_face_section_widget.dart:375` early-returns
  `if (widget.actions.isEmpty) return const <Widget>[]`.
  `study_swipe_deck_widget.dart:184-189` is a `GestureDetector` with only
  `onHorizontalDragUpdate/End/Cancel`, threshold
  `kStudySwipeThreshold = 70` (`:18`, applied `:121`), no enclosing `Focus`.
  `customSemanticsActions` at `:170` serves screen readers only.
- **Violated contract.** WCAG 2.1.1 Keyboard (level A) and 2.5.7 Dragging
  Movements (2.2, AA). BR-110 puts `browse` first in every `eight_box`
  new-learning sequence, so this is a normal state, not an edge.
- **Resolution.** Owner decision on form (see §14, decision 3), but the minimum
  is a focusable, keyboard-activatable pair of "previous / continue" affordances
  on the `browse` face. `AppMotionPolicy` and `MxActionButton` already exist;
  what does not exist anywhere in the app is a keyboard layer.
- **Dependencies.** Independent of P0-01. Enables the keyboard half of P0-03.
- **Files.** `lib/features/study/presentation/widgets/support/study_swipe_deck_widget.dart`,
  `.../sections/study_card_face_section_widget.dart`,
  `.../support/study_mode_view_widget.dart`, ARB pair.
- **Closure test.** A widget test that pumps the `browse` face, sends
  `LogicalKeyboardKey.tab` until a control on the card holds focus, activates it
  and asserts the card advanced; plus a `SemanticsAction.tap` path that does not
  require a drag.

---

**A20-P0-03 · A11Y · `_MxBreadcrumbFold` is keyboard-focusable with zero focus indication**

- **Sources.** A17-P0-1.
- **Evidence.** `mx_breadcrumb.dart:397` is an enabled `InkWell` (`onTap:
  widget.onExpand`), so it is in the tab order.
  `overlayColor: _noOverlay(context)` where `_noOverlay` (`:425-426`) is
  `WidgetStatePropertyAll<Color>(context.colors.primary.withAlpha(0))`.
  `splashFactory: NoSplash.splashFactory`. The file has **0** `onFocusChange`
  and **no** `MxFocusRing`.
  **SDK-verified at 3.44.8**: `ink_well.dart` resolves
  `_HighlightType.focus => widget.overlayColor?.resolve(focused) ??
  widget.focusColor ?? theme.focusColor` — a `WidgetStatePropertyAll` answers
  `focused` non-null, so both fallbacks are short-circuited and the theme's
  seeded `focusColor` can never apply.
- **Violated contract.** WCAG 2.4.7 Focus Visible (AA), total-absence case.
  Reachable whenever a deck path overflows the header; BR-55 allows 10 levels.
- **Resolution.** Give the fold what `mx_breadcrumb_step.dart:139` already has —
  `onFocusChange` plus `MxFocusRing` — or drop the blanket `overlayColor` and
  let the theme's focus wash apply.
- **Dependencies.** None.
- **Files.** `lib/shared/widgets/mx_breadcrumb.dart`.
- **Closure test.** A17 specifies it: `mx_breadcrumb_focus_test.dart`, fold the
  trail, tab to the fold node, assert a foreground `BoxDecoration.border` at
  `AppStroke.focus` in `AppInteractionStates.focusIndicator(scheme).color`;
  assert absent at rest and under `FocusHighlightStrategy.alwaysTouch`.

---

**A20-P0-04 · CMP · Dismissing `MxAsyncConfirmDialog` mid-write commits the delete with no Undo**

- **Sources.** A9-03.
- **Evidence.** `mx_async_confirm_dialog.dart:203` calls `showDialog` with
  `barrierDismissible` left at its default and **no `PopScope`**; both buttons
  are disabled while `isSubmitting` but the barrier and the Android back gesture
  stay live. Dismissing skips `onDone`, so the write lands with no Undo (BR-263)
  and no message. The covering test group stops at the two buttons.
- **Violated contract.** BR-263 (destructive writes are undoable). CLAUDE.md:
  *"Never swallow errors"* generalises — a completed write that reports nothing
  is worse than a swallowed error.
- **Resolution.** `PopScope(canPop: !isSubmitting)` plus
  `barrierDismissible: !isSubmitting`, in the shared widget so all 4 callers get
  it.
- **Dependencies.** Independent. Should land with P1-01 (the sheet family) since
  `starter_install_widget` has the same shape (A9-04).
- **Files.** `lib/shared/widgets/mx_async_confirm_dialog.dart`.
- **Closure test.** A route test: submit, tap the barrier while `isSubmitting`,
  drive the state to `savedAndClose`, assert `onDone` fired exactly once — or
  that the barrier did not pop.

---

**A20-P0-05 · PAR · The elevation parity gate compares the kit to its own literals, and kit and Dart have diverged on all three rim properties**

- **Sources.** A16-G-15. Refined here: A16 says the kit "still specifies the
  dark glow"; the divergence is wider than that.
- **Evidence.** Measured at BASE_SHA:

  | property | kit `elevation.css` `[data-theme="dark"]` | Dart `_darkDepth` |
  |---|---|---|
  | colour | `#6A7199`, hardcoded | `scheme.outlineVariant` = `#272C48` in dark |
  | blur | `2px` | `0` — `BoxShadow` default; the doc says "zero-blur" |
  | spread | steps `1px` / `2px` / `3px` with level | constant `AppStroke.hairline` = 1; the doc says **"The ring never thickens"** |

  `css_scale_parity_test.dart:314-337` asserts the **kit** holds the three
  literal strings `'0 0 2px 1px #6A7199'` etc. — kit against test-literal, never
  kit against Dart — and its comment claims *"the kit says the same thing in the
  same words"*, which is now false in colour, blur and spread.
  `app_elevation_test.dart:90` records the move: *"The rim used to be Tokyo's
  `shadows.card` verbatim — `#6A7199`"*. Dart moved; the kit did not; the gate
  cannot tell.
- **Violated contract.** A parity gate exists to prove two systems agree. This
  one proves a file agrees with a copy of itself. It is the same false-green
  class as P0-01, one layer up.
- **Resolution.** Owner decision first (§14, decision 1): **is the kit still
  normative?** If yes, the gate must compare kit-derived values against the
  built `ThemeData`, and the kit is updated to Dart's quiet rim — **not the
  reverse**. A9-16 measured the dark sheet at 1.14:1 and concluded *do not act*,
  because a louder edge re-introduces #435's halo on the one surface whose
  ground cannot be pre-composed; adopting the kit's `#6A7199` in Dart would do
  exactly that. If the kit is no longer normative, retire the elevation rows
  from the parity gate and say so, rather than leaving a gate that reads as
  agreement.
- **Dependencies.** Must precede any elevation work, or that work will be
  measured against the wrong reference.
- **Files.** `design_system/tokens/elevation.css`,
  `test/design_audit/css_scale_parity_test.dart`,
  `docs/design-system/tokyo-component-mapping.md:127`,
  `docs/architecture.md:1057`.
- **Closure test.** The parity test derives the expected `BoxShadow` list from
  the kit's CSS and compares it to `shadowsFor(level, scheme)` for every level
  in both brightnesses. It must fail today.

### P1 — systemic openness

---

**A20-P1-01 · CMP · There is no `MxSheet`: 16 raw sheet routes, 5 inset mechanisms, 1 of 17 headers announced**

- **Sources.** A9-01, A9-02, A9-05, A9-06, A9-08, A9-12; A8 §10.5.
- **Evidence.** §7.3, all measured at BASE_SHA. Dialogs: 4 shared route
  helpers, 0 raw calls in features. Sheets: 1 helper covering one shape, 16 raw
  calls across 13 files, 5 of those files using no shared sheet helper at all;
  bottom inset in 5 mechanisms; `Semantics(header: true)` on 1 of 17 sheet
  headers. Plus, from A9 and SDK-confirmable: `showModalBottomSheet` defaults
  `useRootNavigator = false` (`bottom_sheet.dart:1301`) against `showDialog`'s
  `true` (`dialog.dart:1629`), so a sheet's scrim stops above the bottom
  navigation bar, which stays lit and tappable; and
  `MediaQuery.removePadding(removeTop: true)` (`:1163`) makes an inner
  `SafeArea(top:)` a no-op under `useSafeArea: false`.
- **Violated contract.** AD-15's bucket contract puts `showX` functions in
  `overlays/`, which these obey — but the design-system contract is that a
  component's visual grammar has one owner. Five inset mechanisms is five owners.
- **Resolution.** One `showMxSheet` route helper plus an `MxSheetHeader`
  counterpart to `MxDialogHeader`, owning: root-vs-branch navigator, safe area,
  bottom inset, drag handle, header semantics, traversal edge behaviour. Migrate
  16 call sites. The two `useSafeArea` and scrim questions are owner decisions
  A9 already raised (§14, decision 2).
- **Dependencies.** After P0-01's guard pattern for `showModalBottomSheet`
  (which makes the 16 visible and keeps the 17th out).
- **Files.** new `lib/shared/widgets/mx_sheet.dart`; `mx_sheet_insets.dart`,
  `mx_form_sheet.dart`, `mx_action_sheet.dart`; the 13 feature overlay files.
- **Closure test.** A route test per sheet asserting one bottom-inset value, one
  top gutter, `isHeader: true` on the title node, and a barrier rect covering
  the full `tester.view`; plus a source scan that `showModalBottomSheet` appears
  only in `lib/shared/`.

---

**A20-P1-02 · ENF · `textStyles.<role>.copyWith(` is a fourth restyle spelling outside the rule, and the rule stops at the feature boundary**

- **Sources.** A15-F4 and A15-F5. Confirmed independently here.
- **Evidence.** §7.4 and §7.5. In features: 9 sites, control group 0.
  In `lib/shared/widgets/`: 14 open-colour restyles, 4 `withWeight(…).copyWith(`
  launderings of which **3 are multi-line**. `AppInk.quiet == onSurfaceVariant`
  and `AppInk.stated == onSurface`, so the 9 feature sites are a zero-pixel
  migration.
- **Violated contract.** `app_ink.dart:118` — `inked` is *"the one legal way for
  a feature to colour a text rung"*. The rule's own message names the
  `textStyles` API it fails to watch.
- **Resolution.** Three changes, all three needed: add the fourth pattern; widen
  the scope for this rule to `ui_surfaces` (a per-rule decision — §7.5); make
  the laundering pattern `mode: file` with a balanced-paren walk. Then migrate 9
  + 14 sites.
- **Dependencies.** Guard change first, migration second. Independent of P0-01
  but belongs in the same phase.
- **Files.** `memox-design-system-rules.yaml`; 9 files under
  `lib/features/card/presentation/`; 8 under `lib/shared/widgets/`.
- **Closure test.** A15-F4's: the two-way probe goes red on today's 9 (and the
  shared 14) and green after they move to `.inked(…)`.

---

**A20-P1-03 · A11Y · No glyph in the app scales with text size**

- **Sources.** A13-P1-1.
- **Evidence.** `applyTextScaling` has zero occurrences in `lib/`. 36 of 58
  `MxIcon` sites are 16 dp beside 11–14 dp labels, so at `textScaler` 2.0 the
  glyph drops from 1.14–1.45× its label to 0.57–0.73×.
- **Violated contract.** CLAUDE.md DoD: *"UI uses tokens and was checked in
  light + dark + small screen + large text scale."*
- **Resolution.** Either opt the roles that should scale into
  `applyTextScaling`, or record the rejection with the per-role table. A13
  accepts either, and the second is legitimate — but the decision must be
  written and tested, because right now it is neither made nor recorded.
- **Dependencies.** After the guard phase; touches `mx_icon.dart` and
  `app_theme.dart:226-229`.
- **Files.** `lib/shared/widgets/mx_icon.dart`,
  `lib/core/theme/foundations/app_icon_size.dart`, `lib/core/theme/app_theme.dart`.
- **Closure test.** A13's: pump one `MxIcon(size: sm)` at `textScaler` 1.0 and
  2.0 and assert the glyph box grows for the roles that opt in, and that
  `MxIconButton`'s glyph does not.

---

**A20-P1-04 · COV · The high-contrast themes render in no screen, no golden and no catalogue mode**

- **Sources.** A19-15, A13-P3-10 (raised from P3 — this is the only render
  coverage a whole theme pair has).
- **Evidence.** `app.dart:93-94` wires both. Four test files exercise them, all
  at token or single-component level: `app_high_contrast_test`,
  `color_scheme_roles_test`, `mx_action_button_state_matrix_test`,
  `mx_card_recipes_test`. **0** of 237 goldens are high-contrast.
  `widgetbook/lib/main.dart:78-79` offers `Light` and `Dark` only.
- **Violated contract.** The palette re-points `outline`, `outlineVariant` and
  four semantic tokens — every hairline and every disabled control in the app.
  No screen has ever been looked at under it.
- **Resolution.** Two `WidgetbookTheme` entries (cheap, immediate), plus at
  least two screen goldens under high contrast — the densest border surface
  (`guess` options or `match` tiles) and one with disabled controls.
- **Dependencies.** After P2-05 (the palette's own numbers are wrong today, so a
  golden taken now pictures a decision made on a wrong figure).
- **Files.** `widgetbook/lib/main.dart`, `test/demo/` host + goldens.
- **Closure test.** The Widgetbook coverage test asserts 4 theme modes; the
  golden job renders at least two high-contrast screens.

---

**A20-P1-05 · COV · `theme_context_extension.dart` is the only theme file no audit has ever read, and it is where the P1-02 hole comes from**

- **Sources.** A20 (new).
- **Evidence.** §3.2 and §9.3. 367 call sites in `lib/`; named by 0 of 21
  reports; no test file of its own. Defines four accessor names; the guard's
  pattern lists know three.
- **Violated contract.** The task's own rule for this pass: *"No unexplained
  missing audit allowed."* More concretely, the file's own doc states its
  purpose is grep-ability — *"a hardcoded colour is easy to spot when every
  legitimate one reads `context.colors.*`"* — which is a claim about the guard,
  never checked against the guard.
- **Resolution.** A short audit of the four accessors, and a test that asserts
  every public getter on `ThemeContextX` appears in at least one guard pattern
  or is explicitly exempted. That test is what stops the fifth accessor
  repeating P1-02.
- **Dependencies.** Should precede P1-02's guard edit, so the edit covers all
  four rather than three-plus-one.
- **Files.** `lib/core/theme/extensions/theme_context_extension.dart`;
  new `test/core/theme/extensions/theme_context_extension_test.dart`.
- **Closure test.** As above: accessor surface ↔ guard pattern list, both
  directions.

---

**A20-P1-06 · CMP · The w700 weight registry is prose, and the test that guards it is titled after a claim that is now false**

- **Sources.** A15-F3, A15-F21.
- **Evidence.** `buttonLabelWeight = w700` (`app_button_themes.dart:430`,
  M100.30) makes a button label the app's most repeated w700, but
  `app_typography.dart:126-127` still argues the hero exception is safe because
  *"the theme spends `w700` only on the two display rungs"*.
  `app_typography_test.dart:271` is titled *"the hero numeral is the one weight a
  feature adds, and it is named"* and passes, because it asserts only
  `heroNumeralWeight == w700`. `deck_study_button_widget.dart:41` documents its
  label as w600; it renders w700.
- **Violated contract.** No magic values, and a named registry that is actually
  the registry.
- **Resolution.** Enumerate every weight reachable from the built theme — 15
  rungs + 6 roles + 20 component text slots + the named constants — assert the
  set is exactly `{400, 500, 600, 700}` and that each w700 site is on a named
  allowlist.
- **Dependencies.** None; pure test + doc.
- **Files.** `lib/core/theme/typography/app_typography.dart`,
  `test/core/theme/typography/app_typography_test.dart`,
  `lib/features/deck/presentation/widgets/items/deck_study_button_widget.dart`.
- **Closure test.** As above. A sixth weight, or an unnamed w700, fails.

---

**A20-P1-07 · A11Y · The OS Bold-text setting paints nothing, and 19 of 21 all-caps surfaces have no accessible name**

- **Sources.** A15-F1, A15-F2.
- **Evidence.** Every rung carries a `wght` axis; Flutter honours `boldText` by
  merging a bare `fontWeight`, which the axis overrides — the app's own
  `app_typography.dart:163-169` documents "axis beats fontWeight". Zero
  references to `boldText` in `lib/ test/ widgetbook/`. 21 `toUpperCase()` paint
  sites, 2 with `label:` + `excludeSemantics:`.
- **Violated contract.** WCAG 1.4.4 / platform accessibility contract; and the
  app fixes the TTS problem twice, which makes the other 19 an inconsistency
  rather than an unknown.
- **Resolution.** A `boldText`-aware wrapper in one place (composition root or
  `AppTypography`) that must state what boldText means for `heroNumeral`'s
  derived cap-trim; and a shared `MxSectionLabel` carrying the label, the role
  and `header: true` so the all-caps rule becomes structural. The shared
  component also closes A19-07's four heading policies and gives P1-02's 9 sites
  a destination better than `.inked(…)`.
- **Dependencies.** `MxSectionLabel` should land **before** P1-02's migration,
  or those 9 sites get migrated twice.
- **Files.** `lib/core/theme/typography/app_typography.dart`, `lib/app/app.dart`,
  new `lib/shared/widgets/mx_section_label.dart`, ~21 feature sites.
- **Closure test.** Pump `Text` at three rungs under
  `MediaQuery(boldText: true)` and assert the resolved `fontVariations` `wght`
  moves, not just `fontWeight`; plus a source-level walk requiring an accessible
  name at 21 of 21 `toUpperCase()` sites.

---

**A20-P1-08 · CMP · Elevation states a level and never wires `materialShadowColor`, on the two components that float**

- **Sources.** A16-G-14.
- **Evidence.** `app_fab_theme.dart:62-65` and `app_snackbar_theme.dart:26`
  state `elevation: overlay`; `grep shadowColor lib/` = 2 hits;
  `component_depth_and_state_test.dart:203` tests the invariant for
  `PopupMenu` alone. §5.1 confirms from SDK source that elevation's only visual
  effect here is the shadow, which is exactly why an unwired shadow colour is
  the whole defect rather than half of it.
- **Violated contract.** `app_elevation.dart`'s own model: dark has no shadow
  budget, so `materialShadowColor` returns transparent in dark. A component that
  does not read it paints `scheme.shadow` in dark.
- **Resolution.** Wire both; then loop the level-equal and dark-transparent
  assertions over every component theme with non-zero elevation instead of
  testing one.
- **Dependencies.** After P0-04 settles what the elevation reference is.
- **Files.** `app_fab_theme.dart`, `app_snackbar_theme.dart`,
  `test/core/theme/components/component_depth_and_state_test.dart`.
- **Closure test.** The generalised loop, which must fail today on two slots.

---

**A20-P1-09 · CMP · Feedback has no `warning` tone, and a caller that needs one has already landed**

- **Sources.** A12-#3, A12-#1, A12-#2.
- **Evidence.** `mx_card.dart:69-80` and `mx_feedback_band.dart:88` offer no
  warning tone; `reminder_labels_widget.dart:54-81` forces `permissionDenied`
  — one of five `ReminderSetupRejection` values — into the danger/error tone,
  although `AppSemanticColors.warningContainer`/`onWarningContainer` already
  exist. Alongside: a real `AsyncValue.error` rendered through `MxEmptyState`
  (`card_bulk_overlays_widget.dart:100-106`), and the app's one spinner with no
  accessible name (`:93-99`).
- **Violated contract.** `MxEmptyState`'s own doc renounces the error/empty
  conflation. The four-tone taxonomy exists in `MxDialogTone` and in the
  semantic palette; the band family has one tone.
- **Resolution.** Add the warning tone to the band family (the tokens exist);
  fix the rejection mapping per-value in `reminderBanner()`, **not** with a
  blanket widget switch; move the error branch to `MxErrorState`; give the
  spinner a name or replace it with `MxLoadingState`.
- **Dependencies.** None.
- **Files.** `mx_feedback_band.dart`, `mx_card.dart`,
  `reminder_labels_widget.dart`, `card_bulk_overlays_widget.dart`,
  `card_editor_screen.dart`.
- **Closure test.** A semantics test that every progress indicator in `lib/` has
  a name; a widget test that a `permissionDenied` rejection renders the warning
  tone and an `AsyncValue.error` renders `MxErrorState`.

---

**A20-P1-10 · COV · 360 dp and 375 dp are rendered nowhere, and one responsive rule is invisible at both tested widths**

- **Sources.** A18 §7.3, A8-P3-21.
- **Evidence.** Of 152 demo goldens, 148 are 393 dp and 4 are 320 dp. Neither
  360 nor 375 is rendered anywhere in the repository, and `MxHeroCard` takes the
  *cramped* branch at 360 and 375 while the 393 reference device hugs — so the
  branch most phones take is the one never pictured.
- **Violated contract.** DoD: checked on a small screen. Two widths are checked;
  the two most common phone widths are not.
- **Resolution.** A shared width matrix fixture at 320/360/375/393 for the
  layout tier. Per CLAUDE.md this must **not** add rows to the screen gallery —
  the gallery is 393×852 only and `build_screen_gallery.py` enforces it — so
  these belong to the test that measures them.
- **Dependencies.** None. A18-G3 asks for the same fixture.
- **Files.** `test/visual_audit/` fixtures.
- **Closure test.** The matrix exists and asserts the `MxHeroCard` branch at
  each width.

---

**A20-P1-11 · CMP · `MxActionSheet` rows are raw `ListTile` and draw no focus ring**

- **Sources.** A14-F1.
- **Evidence.** `mx_action_sheet.dart:149-186` — the only non-family raw
  `ListTile(` in `lib/shared/widgets/`. It therefore inherits no row-overlay
  tokens and no focus ring, on a keyboard-focusable row. No focus test exists.
- **Violated contract.** Exactly P0-01's failure one layer in: the row has no
  primitive owner, so a decision made for `MxListTile` did not reach it.
- **Resolution.** Route the rows through `MxListTile`, or give the sheet's rows
  the same focus treatment. Lands naturally with P1-01.
- **Dependencies.** With P1-01.
- **Files.** `lib/shared/widgets/mx_action_sheet.dart`.
- **Closure test.** A focused enabled action-sheet row paints a visible ring —
  the assertion `mx_list_tile_test.dart` already makes for its own rows.

---

**A20-P1-12 · CMP · Nav chrome: no app bar while loading or on error; two up-grammars one tap apart; app-bar ink is the inverse of M3**

- **Sources.** A8-P1-01, A8-P1-02, A8-P1-03.
- **Evidence.** `mx_content_shell.dart:213` drops `leading`/`actions` when
  `title == null`, and `deck_list_screen.dart:79` /
  `deck_level_error_widget.dart:45` render exactly that state — no title, no
  back, a 56 dp jump. `deck_path_widget.dart:76` and
  `card_breadcrumb_widget.dart:33` are two incompatible up-grammars.
  `app_app_bar_theme.dart:15` gives leading `onSurfaceVariant` and
  `app_icon_button_theme.dart:21` gives actions `onSurface` — the inverse of M3.
- **Violated contract.** M3 app-bar ink roles; and a screen with no exit at the
  chrome level.
- **Resolution.** A8's steps: make the shell keep its bar when the title is
  absent; pick one up-grammar; swap the two inks.
- **Dependencies.** The ink swap is a pixel change — regenerate goldens and
  republish the gallery in the same turn (CLAUDE.md).
- **Files.** `mx_content_shell.dart`, `app_app_bar_theme.dart`,
  `app_icon_button_theme.dart`, `deck_path_widget.dart`,
  `card_breadcrumb_widget.dart`.
- **Closure test.** A widget test that the shell renders a bar with a back
  affordance in loading and error states; a role test pinning the two inks.

---

**A20-P1-13 · ENF · The Slider role guard pins a defaults class the app does not instantiate**

- **Sources.** A10-P1-1.
- **Evidence.** `slider.dart:834-836` — `year2023` defaults to **true** when the
  theme leaves it null; measured `buildLightTheme().sliderTheme.year2023 == null`;
  four of the six pins in `m3_role_contract_test.dart`'s `Slider` block name
  `_SliderDefaultsM3` (2024) values. So the guard reports canonical compliance
  for `_SliderDefaultsM3Year2023`, which is what would actually resolve.
- **Violated contract.** A guard that passes for a class nothing instantiates is
  a green that means nothing — P0-01's class again, in the runtime tier.
- **Resolution.** State `year2023: false` in `buildSliderTheme`, or move the
  pins to the Year2023 roles. Either way assert the defaults class **before**
  asserting its roles.
- **Dependencies.** Slider has no renderer (deferred SM-2 parameters), so this
  is latent — but it is latent *and* actively misreporting.
- **Files.** `lib/core/theme/components/selection/app_slider_theme.dart`,
  `test/core/theme/contracts/m3_role_contract_test.dart`.
- **Closure test.** A10 gives it verbatim: assert
  `theme.sliderTheme.year2023 ?? true` is `false`.

### P2 — local quality and coverage

| id | axis | finding | sources | files |
|---|---|---|---|---|
| **P2-01** | API | `MxMetricWell.wellColor` is an open `Color?` beside a closed `AppInk tint` in the same constructor; all 8 callers feed semantic tokens (§6.2). Owner decision: empirical closure + guard, or a closed `AppWellFill` enum | A20, A13-P3-5 | `mx_metric_well.dart` |
| **P2-02** | ENF | `BoxDecoration(` / `Border.all(` / `DecoratedBox(` are outside `no_raw_style_escape`; 42 sites, **all** token-fed today (§6.3) | A20 | `memox-design-system-rules.yaml` |
| **P2-03** | ENF | No stroke-width guard: 5 raw stroke literals, one arguing `core/theme/` "has no home for a stroke width"; and 20 borders take Flutter's implicit `1.0` instead of `AppStroke.hairline` | A16-G-11, A16-G-12 | `mx_breadcrumb.dart`, `mx_radio_rows.dart`, `mx_action_button.dart`, 13 in `components/` |
| **P2-04** | ENF | The spacing guard sees inline literals only; all 25 feature geometry constants sit in its blind spot, **including both real violations** | A16-G-19, A13-P3-9 | `memox-design-token-rules.yaml` |
| **P2-05** | DOC | `app_high_contrast.dart`'s `onDisabled` row is wrong in all four figures, and the decision was made on the wrong number — **adjudicated in §11.1** | A13-P3-7, A19-05 | `app_high_contrast.dart` |
| **P2-06** | CMP | The 32 dp control tier has five spellings and no owner; `MxMetricWell` exists for it and is 24 dp. And 7 of 8 `AppSpacing.xxl` sites are dimensions, not gaps | A16-G-5, A16-G-1 | `app_chip_theme.dart`, `mx_breadcrumb.dart`, `tag_catalog_row_widget.dart`, `card_metric_widget.dart` |
| **P2-07** | A11Y | Four heading policies, one of them complete; the card row announces its state twice; `MxSwitchRow` stacks two state channels | A19-07, A19-11, A19-19 | closes with P1-07's `MxSectionLabel` |
| **P2-08** | A11Y | `borderOption` at 2.67:1 on a component that **is** its edge; a single-choice menu with no perceivable and no announced state | A19-02, A19-03 | `app_border_colors.dart`, `mx_menu_button.dart` |
| **P2-09** | CMP | Disabled selection controls lose their boolean: one `disabledSurface` where M3 uses two opacities; a disabled ticked checkbox draws a ring M3 makes transparent; radio has no interaction rung | A10-P2-2/3/4 | `app_toggle_themes.dart`, `app_radio_theme.dart` |
| **P2-10** | CMP | Pickers: a disabled-and-selected day is one colour (1.32:1 / 1.02:1); the reminder row and its picker disagree about 12 vs 24 hour | A11-F1, A11-F2 | `app_date_picker_theme.dart`, `reminder_labels_widget.dart` |
| **P2-11** | COV | 10 of 17 screens have no guideline sweep; the shared failure and empty faces are silent; nothing renders a screen under high contrast | A19-14, A19-09, A19-15 | `test/` |
| **P2-12** | CMP | Shell geometry: scroll hairline drawn in the wrong place; shell owns no max content width (4 screens re-derive it); FAB clearance is per-caller; two-line bar over-reserves above scale 1.34 | A8-P2-04/11/12/13 | `mx_content_shell.dart` |
| **P2-13** | CMP | Iconography vocabulary conflicts: one glyph two meanings on one screen; a pick-one group announcing a checkbox; Flag/Unflag both unfilled; `_rounded` mixed with outlined in one grid | A13-P1-2/3/4, A13-P2-4 | 8 feature files |
| **P2-14** | CMP | Snackbar: actionable non-undo keeps the 4 s default while undo got 8 s for the identical "reach a button" reason | A12-#5 | `mx_messenger.dart` |
| **P2-15** | COV | Neither picker is rendered or in the state guards; `MxDropdown` has no documented disabled/error decision | A11-G1/G2, A14-F5 | `test/`, `mx_dropdown.dart` |
| **P2-16** | ENF | `lib/app/` is in no typography scope; `error_screen_widget.dart` renders in the platform font — the only screen in the app that does | A15-F6 | `scopes.yaml`, `error_screen_widget.dart` |

### P3 — polish, dead code, documentation

| id | axis | finding | sources |
|---|---|---|---|
| **P3-01** | API | `MxProgressBarShape.flush` has zero callers anywhere, and its doc names a use case (`deck_tile_widget.dart:233`) that passes no `shape:` (§3.4) | A20 |
| **P3-02** | DOC | Four present-tense references to two deleted files: `app_theme.dart:266,288`, `app_sizing.dart:9,40` → `app_modal_themes.dart` / `app_planned_themes.dart`; plus a test file named after one (§4.1) | A20 |
| **P3-03** | DOC | Stale cross-references inside the design system: `mx_icon.dart:67-69` cites a `MxMetricWell` defect fixed at M100.5; `app_bottom_sheet_theme.dart:24-30` argues for `borderControl` and returns `onSurfaceVariant`; `app_dialog_theme.dart:26-28` says a shadow is "hand-painted" and nothing paints one; `app_elevation.dart:156-161` calls `overlay` callerless | A13-P3-5, A14-F3, A9-09, A9-10, A16-G-17 |
| **P3-04** | ENF | Four dead rulesets are vendored (`memox`, `memox-v4`, `memox-v5`, `memox-design-jsx`); `memox` is the name a reader would guess, and its 75 empty-scope rules would pass green (§0.1) | A20 |
| **P3-05** | API | `cupertino_icons` is a declared production dependency with zero `CupertinoIcons` references; `Icons.ios_share` is the share glyph on an Android-target app | A13-P3-4, A13-P2-10 |
| **P3-06** | COV | Token-scale coverage holes: `AppIconSize.mdCompact` absent from the Widgetbook catalogue and from the ordering assertion; `AppRadius.xl` likewise; the coverage test checks components only | A13-P3-1/2, A16-G-8 |
| **P3-07** | ENF | Four `elevation: 0` literals where `AppElevation.none` exists; a raw `4` scrollbar thickness; the radius guard is `warning` where the spacing guard beside it is `error` | A16-G-18, A16-G-21, A16-G-9 |
| **P3-08** | DOC | Route naming and announcement: every dialog announces "Alert", every sheet "Dialog"; session and 404 screens carry no `namesRoute`; `deckPathAncestorsHint` is orphaned in both ARBs | A9-13, A8-P3-19, A8-P2-08 |
| **P3-09** | API | `MxFormDialog.isSubmitting` and `MxActionSheetAction.isEnabled` have no production caller; two platform flags nothing reads | A9-14, A19-22 |
| **P3-10** | COV | `MxIcon` has no unit test; its null-label ⇒ `ExcludeSemantics` contract — the reason the widget exists — is asserted nowhere | A13-P3-3 |
| **P3-11** | DOC | `MxBreadcrumb` accepts `lineHeight: 32` with tappable steps, below `AppSizing.touchTarget`; only convention prevents it | A16-G-7, A8-P3-17 |
| **P3-12** | DOC | `AppStroke.input` names a component and 3 of its 5 call sites are not inputs; `MxSearchField`'s boundary is an implicit 1.0 where every other input is 1.5 | A16-G-10, A16-G-13 |

---

## 11 · Conflicting recommendations, resolved

Each row gives report A, report B, the current code, what Flutter 3.44.8 says
where it is relevant, and the final recommendation.

### 11.1 · `app_high_contrast.dart`'s `onDisabled` figures — A13 vs A19 vs the file

| source | normal light / dark | high contrast light / dark |
|---|---|---|
| The file (`app_high_contrast.dart:27`) | 2.37 / 3.20 | 4.88 / 6.33 |
| A13-P3-7 recomputation | 2.11 / 2.61 | 3.80 / 5.12 |
| A19-05 | "stale in every row" (no figures for this row) | — |
| **This audit, computed independently** | **2.11 / 2.62** | **3.80 / 5.11** |

**Method:** `Color.alphaBlend` compositing and WCAG 2.x relative luminance — the
repository's own model, the one `test/support/color_math.dart` uses.
`onDisabledLight = 0x61223354` (α = 97/255 = 0.3804) over
`pageLight = 0xFFF2F5F9` composites to `#A3ABBA`; high contrast is
`onSurface.withValues(alpha: 0.62)` → `0x9E223354` → `#717D93`.

**Resolution: A13 is right, to within rounding, and the file is wrong on all
four numbers.** A13's further claim that *"no ground in the app's ladder
produces the recorded pair"* is also confirmed: over `surfaceContainerLowest`
and `surfaceContainerLow` the normal figures are 2.15 / 2.65, still not
2.37 / 3.20. And a fifth number in the same doc block is wrong — it cites
`onSurface`'s contrast as 14.81:1 where the palette gives **11.50 / 12.01**.

**The consequence is a decision, not just bookkeeping.** The file's stated
justification for raising disabled ink to 62% is *"62% lands at 4.88:1 —
legible"*. The real value is **3.80:1**, which clears the 3:1 graphic floor and
**not** the 4.5:1 text floor. **No WCAG requirement is actually missed** — SC
1.4.3 explicitly exempts "text that is part of an inactive user interface
component" — so this is not an accessibility defect. But the trade was accepted
on a number that was 28% optimistic, and the owner should re-confirm 62% knowing
the real figure. Registered as P2-05, above A13's P3, because a wrong number
inside a justification is worse than a wrong number in a table.

### 11.2 · The dark rim — A9 says do not act, A16 says reconcile

- **A9-16** measured the dark sheet at 1.14:1 against the scrimmed page — the
  lowest figure in that report — and concluded explicitly **do not act**: ΔL\*
  6.58 is larger than the ladder's own 4.31 page→card step, and closing the gap
  with a border, rim or shadow would re-introduce #435's halo on the one surface
  whose ground cannot be pre-composed.
- **A16-G-15** (P0) says the kit still specifies the rim #435 removed and the
  parity test asserts it, and asks for reconciliation.
- **Current code.** Dart paints a quiet rim: `scheme.outlineVariant`, zero blur,
  constant `hairline` spread, 1.30:1 against the card. The kit specifies
  `#6A7199`, 2 px blur, spread stepping 1→2→3.
- **Flutter 3.44.8.** Neutral — both are legal `BoxShadow` lists; §5.1 confirms
  elevation's only effect here is the shadow, so the shadow list *is* the depth
  model.

**These read as opposed and are not.** They conflict only if "reconcile" means
moving Dart toward the kit. **Final recommendation: the kit follows Dart, never
the reverse**, and the parity gate is rewritten to compare kit-derived values
against the built `ThemeData` (P0-05). Adopting the kit's louder rim in Dart is
precisely the action A9-16 measured and rejected. This also matches the standing
project position that the kit is a mirror rather than a source of decisions.

### 11.3 · `no_text_restyle`'s scope — the rules file vs A15-F5

- **The rules file** argues `lib/shared/` must be **out** of scope: *"`lib/shared/`
  is where the primitives legitimately build the raw widgets these rules ban.
  Linting it would flag the definition as the crime."*
- **A15-F5** asks for the scope to widen to `ui_surfaces`, citing 14 restyles
  there.
- **Current code.** 14 open-colour `.copyWith(color:)` in
  `lib/shared/widgets/`, 4 of them `withWeight` launderings, 3 multi-line.

**Resolution: both are right about different rules.** The scope argument is
sound for *raw-widget* rules — a primitive must build a `ListTile`. It does not
transfer to *colour* rules: a primitive need not invent an open colour when
`AppInk` exists and is documented as "the one legal way". **Scope is a per-rule
decision**, `no_raw_widget` keeps `presentation_files`, and `no_text_restyle`
widens to `ui_surfaces` — with `mode: file`, because 3 of the 4 launderings are
multi-line and a line pattern misses them even after the scope widens.

### 11.4 · `MxAlertDialog`'s zero callers — A9-14 (P3) vs A14-F2 (informational)

- **A9-14** groups it with two genuinely dead API members at P3.
- **A14-F2** records it as "verified deliberate (WBS M99.59)", informational,
  not a defect.

**Resolution: A14 is right.** `mx_alert_dialog.dart:15-27` documents the
absence, names the two candidates examined and rejected and why, and the
component has a Widgetbook entry and 2 tests. That is the model of a recorded
deferral. It belongs in the coverage matrix as **ZERO CALLER / INTENTIONALLY
DEFERRED** (§3.4) and in **no** severity bucket. `MxFormDialog.isSubmitting` and
`MxActionSheetAction.isEnabled` — A9-14's other two — stay at P3-09, and
`MxProgressBarShape.flush` joins them as P3-01.

### 11.5 · Icon text-scaling — A13-P1-1 offers two mutually exclusive closures

A13's closure test is *"a test that asserts the glyph box grows… **or** an
`AppIconSize` doc block recording the rejection with the per-role table, plus a
test asserting `MxIconButton`'s glyph does **not** grow"*.

**Resolution: the decision must be made, and it is the owner's** (§14, decision
4). Decision priority puts accessibility above consistency, which argues for
scaling the roles where a glyph sits beside text; it puts mobile above
consistency too, which argues against scaling a 48 dp icon button that would
then break the touch-target grid at scale 2.0. **Recommended: opt in the
label-adjacent roles, opt out the control roles, and write the per-role table
either way** — because the current state is not the second option, it is the
absence of both.

---

## 12 · Coverage gaps

| gap | measured | registered |
|---|---|---|
| `theme_context_extension.dart` audited by nobody | 1 file, 367 call sites, 0 reports, 0 tests | P1-05 |
| High contrast never rendered | 0 of 237 goldens; 2 of 4 theme modes in Widgetbook; 4 token-level test files | P1-04 |
| 360 / 375 dp never rendered | 148 goldens at 393, 4 at 320, 0 at 360 or 375 | P1-10 |
| 10 of 17 screens have no guideline sweep | A19-14 | P2-11 |
| Neither picker rendered or in the state guards | A11-G1/G2 | P2-15 |
| No screen test for either high-contrast theme | — | P1-04 |
| `MxIcon` has no unit test | 0 files | P3-10 |
| Token-scale coverage: `mdCompact`, `AppRadius.xl` | absent from catalogue and ordering assertions | P3-06 |
| Guard blind spots: 8 live + 19 latent widget names; `BoxDecoration` family; stroke widths; geometry constants; `lib/app/` typography | §8.3, P2-02/03/04, P2-16 | P0-01 |
| Thin theme coverage: `app_card_theme` at 1 report, post-M100.35 | §3.3 | noted, no finding |

---

## 13 · Implementation DAG

Ordered so that nothing is fixed before the thing that can prove it is fixed
exists. The house pattern is followed: **guards land at `warning` first, fixes
follow, promotion to `error` closes the phase.**

```
Phase 0  GUARDS CAN SEE                     P0-01 P1-02(guard) P1-05 P2-02 P2-03 P2-04 P2-16 P1-13
   │      no production change; every new pattern fault-injected;
   │      guard expected to report ~50 warnings — that is the deliverable
   ▼
Phase 1  PARITY REFERENCE                   P0-05
   │      owner decision 1 first; elevation work is unmeasurable before this
   ▼
Phase 2  FOUNDATIONS                        P2-05 P2-03(fix) P2-06 P3-07 P3-12
   │      the high-contrast figures, the stroke tokens, the 32 dp tier
   ▼
Phase 3  ThemeData                          P1-08 P2-09 P2-10 P1-12(inks) P1-13(fix)
   │      shadow colours, disabled states, picker resolvers, app-bar ink swap
   ▼
Phase 4  PRIMITIVES                         P1-07(MxSectionLabel) P1-01(MxSheet) P0-04 P0-03 P1-11 P1-03 P2-01
   │      MxSectionLabel BEFORE Phase 5, or P1-02's 9 sites migrate twice
   ▼
Phase 5  COMPOSITIONS                       P1-02(migrate) P1-09 P2-07 P2-12 P2-14
   │      the 9 + 14 restyles, the warning tone, the shell geometry
   ▼
Phase 6  CALLERS                            the 40 raw-Material sites, P2-13
   │      16 sheets → showMxSheet · 10 Divider · 7 spinner · 2 chip · 1 TextField
   ▼
Phase 7  A11Y / HIGH CONTRAST               P0-02 P2-08 P2-11 P1-04(Widgetbook modes)
   │      the keyboard layer — the app has none today
   ▼
Phase 8  RESPONSIVE / MOTION                P1-10
   │      motion is already closed; this phase is the width matrix only
   ▼
Phase 9  API CLEANUP                        P3-01 P3-04 P3-05 P3-09
   ▼
Phase 10 DOCS / WIDGETBOOK                  P3-02 P3-03 P3-06 P3-08 P3-10 P3-11
   ▼
Phase 11 LINUX GOLDENS                      regenerate + republish gallery at the pinned URL
   │      required after Phases 3, 4, 5, 6 and 12 — any pixel move
   ▼
Phase 12 CI                                 promote every Phase-0 guard warning → error
```

Two ordering constraints are load-bearing and easy to get wrong:

- **Phase 0 before everything.** Fixing a raw `Divider(` before the guard bans
  `Divider` leaves nothing preventing the next one. The guard is the deliverable
  of the phase, not the fix.
- **`MxSectionLabel` (Phase 4) before the restyle migration (Phase 5).** The 9
  `textStyles.sectionLabel.copyWith(color:)` sites want a shared component, not
  a `.inked(…)` call — A15-F2 and A19-07 both land on the same component.
  Migrating them to `.inked(…)` first means touching them twice.
- **Phase 11 is not once.** CLAUDE.md requires goldens regenerated **and** the
  gallery republished at
  `https://claude.ai/code/artifact/e8a68227-1582-407c-88c2-ff25d66bd9d8` in the
  same turn as any change a person can see. Phases 3, 4, 5, 6 each move pixels.
  Goldens must be authored on **Linux** — a Windows checkout cannot regenerate
  them and have CI agree.

---

## 14 · Owner decisions genuinely required

Five. Everything else in this report has a determinate answer.

**1 · Is the `design_system/` kit still normative?** (blocks P0-05, Phase 1)
Kit and Dart have diverged on the dark rim's colour, blur and spread, and the
parity gate cannot see it because it compares the kit to literals copied from
itself. Three options: (a) kit is normative → update the kit to Dart's quiet rim
and rewrite the gate to compare kit ↔ `ThemeData`; (b) kit is a mirror → same
update, and the gate becomes advisory; (c) kit is retired for elevation → drop
those rows from the gate and say so. **Not an option: leaving a gate that reads
as agreement.** Recommended: (a) or (b), and in either case the kit follows Dart
— §11.2 explains why the reverse is the one action A9-16 measured and rejected.

**2 · `useSafeArea: true` for the seven scroll-controlled sheets, and does the
sheet scrim cover the app's own navigation bar?** (blocks P1-01)
A9's two decisions, unchanged at BASE_SHA. Both are behaviour changes on 16 call
sites with committed goldens; both are the kind of thing that should be decided
once, in the primitive, rather than per sheet — which is what `MxSheet` is for.

**3 · What form does the `browse` keyboard path take?** (blocks P0-02)
The Next button was removed deliberately and the reasoning is written down. The
options are a restored pair of affordances, a focusable card with key handlers
and no new chrome, or an app-level shortcut layer. The app has **no** keyboard
layer at all today, so this decision also decides whether one is introduced —
which affects far more than `browse`.

**4 · Do glyphs scale with text?** (blocks P1-03)
Per-role, not app-wide. §11.5's recommendation is opt-in for label-adjacent
roles, opt-out for control roles, with the table written either way. The current
state is neither option.

**5 · Does V1 closure require *structural* API closure, or does empirical
closure plus a guard suffice?** (decides P2-01, P2-02, and part of the exit
criteria)
Every escape hatch on the shared surface is fed a token at every call site
today, and nothing in the type system requires that. Structural closure means
`AppWellFill`-style enums and a smaller API; empirical closure means guard rules
and a scan. **Recommended: empirical + guard for V1**, structural for the two
cases where the enum already exists next door (`MxMetricWell.wellColor` beside
`AppInk tint`), because that one is an inconsistency inside a single
constructor rather than a general policy.

---

## 15 · Exit criteria — DESIGN SYSTEM V1 CLOSED

V1 may be declared closed when **all** of the following are mechanically true at
one commit. Each line is a command or an assertion, not a judgement.

**A · Enforcement (the gate can see what it claims)**

1. `no_raw_widget`'s alternations contain every name in §8.3's guarded (44) +
   live (8) + latent (19) sets = **71**, at `severity: error`, and the guard
   passes.
2. A two-way probe test exists asserting, for each such name, that the pattern
   matches a synthetic violation and does not match the same text in a comment.
   **Fault injection is part of the criterion**: a guard rule landed without a
   demonstrated red is not landed.
3. `no_text_restyle` has four patterns, `mode: file`, scope `ui_surfaces`, and
   passes.
4. `showModalBottomSheet` appears in `lib/shared/` only — asserted by a source
   scan, not by inspection.
5. A test asserts every public getter on `ThemeContextX` appears in a guard
   pattern or is explicitly exempted.
6. Stroke widths, radius values and geometry `const double` declarations are
   guarded at `error` with zero violations.

**B · Composition (a feature composes, it does not assemble)**

7. Zero raw Material component constructions in `lib/features/**` for the 71
   names, guard-verified — currently **40**.
8. Every modal route in the app opens through a shared helper: 4 dialog + 1
   sheet, zero raw `showDialog`/`showModalBottomSheet` in features.
9. One bottom-inset mechanism for sheets, one header component, `isHeader: true`
   on 17 of 17 sheet titles — currently 1 of 17 and 5 mechanisms.
10. `theme_coverage_test` still passes in **both** directions, with the
    allowlist reasons current. ✅ today

**C · Role and token architecture (already met — must stay met)**

11. Exactly 45 M3 roles + `brightness`, both directions allowlisted. ✅ today
12. Zero colour hex outside `lib/core/theme/foundations/`. ✅ today (115/115)
13. Zero `Colors.<name>` outside `lib/core/theme/`, and only `transparent`
    within it. ✅ today (14/14)
14. Zero dead tokens, or each survivor carrying a written reason. ✅ today
15. Zero literal `Duration(` as a `duration:`; every animation through
    `AppMotionPolicy`. ✅ today (6/6)
16. Zero local `Theme(` / `IconTheme(` / `DefaultTextStyle(` overrides outside
    the composition root. ✅ today

**D · Accessibility**

17. Every core task completable by keyboard alone, and without a drag —
    asserted by a widget test per study mode. Currently **not possible**.
18. Every keyboard-focusable control has a visible focus indicator, asserted for
    every `InkWell`/`Pressable` in `lib/shared/`. One total-absence case today.
19. `meetsGuideline` sweeps on 17 of 17 screens — currently 7.
20. The OS `boldText` flag moves the resolved `fontVariations` `wght`.
21. 21 of 21 all-caps surfaces carry an accessible name — currently 2.
22. Icon text-scaling decided, implemented per role, and tested in both
    directions.

**E · High contrast, responsive, parity**

23. At least two screens rendered as goldens under each high-contrast theme —
    currently 0.
24. Widgetbook offers 4 theme modes — currently 2.
25. The layout tier pumps 320 / 360 / 375 / 393 dp; the screen gallery stays
    393×852 only, and `build_screen_gallery.py` still enforces it.
26. The elevation parity gate compares kit-derived values to the built
    `ThemeData`, in both brightnesses, at every level.

**F · Housekeeping**

27. Zero present-tense references to deleted files in `lib/`; zero test files
    named after one.
28. Dead API removed or documented: `MxProgressBarShape.flush`,
    `MxFormDialog.isSubmitting`, `MxActionSheetAction.isEnabled`; the four
    vendored dead rulesets pruned to the one in use.
29. `dod_check.sh` green, `flutter analyze` zero errors **and** warnings
    repo-wide, `flutter test` green including goldens under `TZ=UTC`,
    `integration_test/` 8 of 8 on a device.
30. `docs/wbs.md` updated in the same commits, and the screen gallery
    republished at the pinned URL.

**Current score: 7 of 30 met** — criterion 10, plus all six of group C.
Group C is the group that was already closed before this audit, which is
exactly why the verdict is "one layer, not the stack": the criteria that pass
are the token and role ones, and every open criterion is enforcement,
composition, accessibility or coverage.

---

## 16 · Deferred items — recorded, not findings

These are open by decision, and this audit did not reopen them.

| item | status | recorded in |
|---|---|---|
| `MxAlertDialog` / `showMxAlert` — zero callers | intentional; two candidates examined and rejected; catalogued and tested | `mx_alert_dialog.dart:15-27`, WBS M99.59, A14-F2 |
| `datePickerTheme`, `segmentedButtonTheme`, `sliderTheme`, `tabBarTheme` — themed, unrendered | on `theme_coverage_test`'s `allowedUnrendered` with a per-slot reason; the test also fails if one gains a caller | `theme_coverage_test.dart:133-149` |
| `DropdownButton` has no `ThemeData` slot | blind spot named and closed via `canvasColor` + `disabledColor`; the coverage test asserts both | `app_theme.dart:236-250`, `theme_coverage_test.dart` |
| The dark sheet at 1.14:1 | **measured, conclusion "do not act"** — ΔL\* 6.58 exceeds the ladder's own 4.31 step; closing it re-introduces #435's halo | A9-16, upheld in §11.2 |
| FAB overlapping the third card | measured, deliberately left open by the owner | prior review; untouched here |
| `AppColors.seed` retained with no generator | deliberate: the kit names `--color-seed` and the parity test pins the pair | `app_colors.dart:50-55` |
| `AppStateOpacity.disabledContent` / `disabledSurfaceBlend` — no production reader | provenance records for precomputed values, by design | `app_interaction_states.dart:83-90` |
| SM-2 parameters, sync bookkeeping columns, DB encryption | deferred; migration testing in place so they stay cheap | CLAUDE.md |
| `integration_test/` at 8 scenarios, local-only | deliberate: an emulator on a runner costs 30–45 min and is the flakiest thing in a pipeline; 133 business scenarios moved to host | CLAUDE.md |
| Goldens authored on Linux only | deliberate since M100.24; a Windows checkout cannot regenerate them and have CI agree | `dart_test.yaml` |

---

## 17 · Verification status of this commit

| check | result |
|---|---|
| Files changed | **1** — this file |
| `lib/` touched | no |
| `test/` touched | no |
| Guard rules touched | no |
| Goldens regenerated | no — nothing a person can see moved |
| Guard at BASE_SHA | run to completion; 79 rules; passes (which is the subject of P0-01) |
| Test suite | 543 relevant tests green after codegen regeneration (§0.2) |
| SDK claims | read from Flutter 3.44.8, framework `058e0af2c2`, installed locally |
| Counts | measured by one-process scanners at BASE_SHA, each with a control group |
| Self-corrections | 3, recorded in §0.1 rather than deleted |
