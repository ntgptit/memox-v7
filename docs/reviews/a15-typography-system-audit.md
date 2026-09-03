# A15 — Typography system deep audit

| | |
|---|---|
| BASE_SHA | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` — *the dark card stops glowing, and elevation stops meaning two things* (M100.35, #435) |
| Pinned SDK | Flutter **3.44.8** (`.fvmrc`) · Dart `^3.12.2` |
| Scope | Every typography surface under `lib/`: the two token files, `ThemeData.textTheme`, all 20 component-theme text slots, `lib/shared/widgets/`, every `lib/features/*/presentation/`, `lib/app/`, the font assets and their `@font-face` twins, the guard rules that watch type, and the tests / Widgetbook / goldens that cover it |
| Mode | **Report only.** No production, theme, token, test, Widgetbook or design-system file was changed; no golden was regenerated; no guard rule was edited |
| Method | Static source audit + mechanical probes (Python) run against the working tree. **No Flutter SDK is present in this environment** — see *Tooling constraint* below |

## Tooling constraint — read this before trusting a number

`flutter` and `dart` are **not installed** in the session this audit ran in
(`flutter: command not found`), and the Flutter framework source is not on disk.
So unlike `mx-text-field-deep-audit.md`, **nothing here was rendered or
measured**. Every claim is one of three kinds, and each finding says which:

- **Read** — taken from a file in this repository, with `file:line`. Re-checkable
  by anyone, and the great majority of this report.
- **Probed** — produced by a script that re-implements a guard rule's own regex
  and scope and reports the delta. The probe scripts are inlined in §7 so they
  can be re-run.
- **Framework** — a statement about what Material or the Flutter framework does
  with a slot this app leaves null. These are the only claims that need a device
  or an SDK to confirm, they are marked **[needs SDK confirmation]**, and every
  one of them ships with a closure test that both confirms and guards it.

No finding in this report rests on a pixel nobody looked at being a particular
colour. Where a decision needed a render to settle, the finding says so and asks
for the render rather than guessing the outcome.

---

## 1 · Verdict

**The type system is the strongest layer in this codebase, and it has one
accessibility hole that its own greatest strength drilled.**

The scale is declared rather than inherited, pinned against an external token
file, built once and handed to every component theme, closed at the feature
boundary by `AppInk`/`inked`, and guarded by three regex rules plus two test
files written specifically for the two ways typography goes wrong here. Feature
code contains **zero** `TextStyle(` literals, **zero** `fontSize:`, **zero**
`texts.*.copyWith`, and **zero** bare `fontWeight:`. That is not normal, and
nothing in this report should be read as suggesting the architecture is wrong.

What the audit found is that the system's defining decision — **weight moves
through the `wght` axis, and the axis beats `TextStyle.fontWeight`** — is
enforced inward and has never been checked outward. Flutter honours the
platform's *Bold text* accessibility setting by merging a bare
`fontWeight: FontWeight.bold` onto every `Text`. Every rung in this app carries
an explicit `wght` axis. By the app's own documented, twelve-times-measured
finding, the axis wins. So the setting reports as applied and paints nothing.
That is **F1**, and it is the report's only P1 of substance.

Everything else is drift of two shapes, and both are shapes the project already
recognises:

1. **The enforcement perimeter stops at `lib/features/`.** M99.66 migrated 89
   presentation files to a closed API and its acceptance criterion says
   `lib/features/` explicitly. The guard scope still says the same thing, so
   `lib/shared/widgets/` — the layer that *defines* the design system — holds 9
   open-colour restyles and 4 instances of the exact "laundering route" the rule
   was written to name, and `lib/app/error_screen_widget.dart` is outside every
   typography rule and renders in the platform font.
2. **A component's declared rung and its painted rung have parted in three
   places** — the chip, the list row and the dropdown — and in each case the
   test that exists to prevent exactly this reads the theme slot rather than the
   widget.

No P0. Nothing here is a crash, a data defect or a release blocker.

| | Count |
|---|---|
| **P0** | 0 |
| **P1** | 2 |
| **P2** | 14 |
| **P3** | 8 |

What must not be touched by the next pass, because it is right and was
argued for:

- `AppTypography._display` / `_body` state size, leading and tracking rather
  than inheriting Material's — the SDK-bump trap is closed and
  `app_typography_test.dart` is what closes it.
- `withWeight` as the only legal re-weighting, and the `no_bare_font_weight`
  rule behind it. **Zero violations inside its scope.**
- `AppInk` as a closed enum of 22 meanings, and `inked` as the only feature-level
  colouring route. **Zero `texts.*.copyWith` in all of `lib/features/`.**
- The card prompt owning `AppTextStyles.cardPrompt` instead of squatting on
  `headlineMedium`. This was the right move and this audit found no reason to
  revisit it.
- The CJK fallback chain, its ordering argument, and the rule that
  `test/flutter_test_config.dart` must load every family named in it.
- **No `textScaler` clamp anywhere in `lib/`.** Several screens compute against
  the scaler; none caps it. That is the correct posture and it is rarer than it
  should be.
- `AppTypography.compactCardPromptSize` and the compact pass's refusal to shrink
  body and label text. The reasoning in `app_compact_scale.dart`'s header is
  correct and this audit endorses it.

---

## 2 · Font and type inventory

### 2.1 Faces

| Family | Asset | Axis | Role | Declared in |
|---|---|---|---|---|
| `PlusJakartaSans` | `PlusJakartaSans-Variable.ttf` | `wght 200–800` | display + titles — the app's only visual signature | `pubspec.yaml`, `fonts.css` |
| `Inter` | `Inter-Variable.ttf` | `wght 100–900` | body + UI | `pubspec.yaml`, `fonts.css` |
| `NotoSansKR` | `NotoSansKR-Variable.ttf` | `wght 100–900` | CJK fallback #1 (Hangul) | `pubspec.yaml`, `fonts.css` |
| `NotoSansJP` | `NotoSansJP-Variable.ttf` | `wght 100–900` | CJK fallback #2 (kana + Han, JP forms) | `pubspec.yaml`, `fonts.css` |
| `NotoSansSC` | `NotoSansSC-Variable.ttf` | `wght 100–900` | CJK fallback #3 (Han, SC forms) | `pubspec.yaml`, `fonts.css` |

All five are **variable and deliberately not instanced** — a static face would
report one weight and paint another, which is the bug class this whole design
exists to prevent. All five are subset, and what was dropped is recorded in
`app_typography.dart:52-57`. All five are loaded by
`test/flutter_test_config.dart:82-86`, so the pubspec/test parity CLAUDE.md
demands **holds**.

`ThemeData.fontFamily: AppTypography.bodyFamily` (`app_theme.dart:174`) seeds
anything that builds a `TextStyle` without going through the scale. One widget
escapes it — see **F6**.

### 2.2 Every typography constant in Dart

| Constant | Value | Used by | Kit token |
|---|---|---|---|
| `displayFamily` | `PlusJakartaSans` | `_display` | `--font-display` ✅ |
| `bodyFamily` | `Inter` | `_body`, `ThemeData.fontFamily` | `--font-body` ✅ |
| `cjkFallback` | KR → JP → SC | every rung | `--font-*` stacks ✅ |
| `cardPromptSize` | 30 | `AppTextStyles.cardPrompt` | `--text-card-prompt` ✅ |
| `cardPromptHeight` | 1.22 | ↑ | `--leading-card-prompt` ✅ |
| `cardPromptTracking` | −0.5 | ↑ | `--tracking-card-prompt` ✅ |
| `compactCardPromptSize` | 26 | `app_compact_scale.dart:69` | `--text-card-prompt-compact` ✅ |
| `sectionLabelTracking` | 1.1 | `sectionLabel`, `sectionLabelSmall` | `--tracking-section-label` ✅ |
| `stateChipTracking` | 0.6 | `stateChipLabel` | **— none (F10)** |
| `listHeadingTracking` | 0.72 | `listHeading` | **— none (F10)** |
| `heroNumeralCapTrim` | 0.481 | `heroNumeral` | **— none (F10)** |
| `heroNumeralWeight` | `w700` | `heroNumeral` | `--weight-bold` (shared) |
| `buttonLabelWeight` † | `w700` | all four button themes | `--weight-bold` (shared) |
| `_chipLabelWeight` † | `w500` | `chipTheme.labelStyle` | `--weight-medium` (shared) |

† declared outside `AppTypography`, in `app_button_themes.dart:430` and
`app_chip_theme.dart:143`. Both are weight decisions; neither is registered
where `AppTypography` asks weight decisions to register. See **F3**.

---

## 3 · Mapping to canonical Material 3

Every one of the fifteen M3 `TextTheme` slots is declared. The table classifies
each as the audit brief asks: **canonical M3**, **approved MemoX semantic**,
**feature-justified display**, or **duplicate/dead**.

| Rung | Size / leading / tracking | Weight | Face | Classification | Live callers in `lib/` |
|---|---|---|---|---|---|
| `displayLarge` | 57 / 64 / 0 | w700 | PJS | canonical M3 | **0** |
| `displayMedium` | 45 / 52 / 0 | w700 | PJS | canonical M3 | **0** |
| `displaySmall` | 36 / 44 / 0 | w600 | PJS | canonical M3 | 1 (`timePickerTheme.hourMinuteTextStyle`) |
| `headlineLarge` | 32 / 40 / 0 | w600 | PJS | canonical M3 | 1 (base of `heroNumeral`) |
| `headlineMedium` | 28 / 36 / 0 | w400 | PJS | canonical M3 **with no kit token — F10** | 2 |
| `headlineSmall` | 24 / 32 / 0 | w600 | PJS | canonical M3 | 3 |
| `titleLarge` | 22 / 28 / 0 (compact 20) | w600 | PJS | canonical M3 | 12 |
| `titleMedium` | 16 / 24 / 0.15 | w600 | Inter | **MemoX semantic** — M3 says w500 | 30 |
| `titleSmall` | 14 / 20 / 0.1 | w600 | Inter | canonical M3 | 19 |
| `bodyLarge` | 16 / 24 / 0.5 | w400 | Inter | canonical M3 | 8 |
| `bodyMedium` | 14 / **1.45** / 0.25 | w400 | Inter | **MemoX semantic** — leading, documented | 54 |
| `bodySmall` | 12 / 16 / 0.4 | w400 | Inter | canonical M3 | 75 |
| `labelLarge` | 14 / 20 / 0.1 | **w600** | Inter | **MemoX semantic** — M3 says w500, raised for the filled button | 19 |
| `labelMedium` | 12 / 16 / 0.5 | w500 | Inter | canonical M3 | 30 |
| `labelSmall` | 11 / 16 / 0.5 | w500 | Inter | canonical M3 | 22 |

Three deliberate departures from M3's metrics, all three with written ownership:

1. **`bodyMedium` leading 1.45** instead of 20/14 — `app_typography.dart:295`
   ("keeps a two-line empty-state message readable without looking airy"), and
   the kit states it as a ratio (`--leading-body-md:1.45`), so both sources
   agree. ✅ **Keep.**
2. **`labelLarge` at w600** instead of M3's 500 — argued in
   `app_button_themes.dart:60-64` for a label reversed out of a solid fill, and
   `app_chip_theme.dart:120-142` records the measurement that then *excused the
   chip from it*. ✅ **Keep**; this is exactly the "documented ownership" the
   brief asks for.
3. **`titleMedium` at w600** instead of M3's 500 — this is the one departure
   with **no written argument anywhere**. It is the app's entity-title rung (30
   callers, the second-most-used rung in the codebase), so it is almost
   certainly deliberate, but the reasoning was never recorded. See **F7**, where
   its absence has a consequence.

Two rungs have **zero callers in `lib/`**: `displayLarge` and `displayMedium`.
They are canonical M3 slots and a widget can legitimately reach for them, so
they are **not dead** in the sense the brief means. They matter for a different
reason: `app_typography_test.dart:259-260` and
`app_typography.dart:126-127` both lean on "w700 belongs to the two display
rungs, which no screen uses" as the argument that the hero numeral is the app's
*only* fourth weight. That argument stopped holding at M100.30. See **F3**.

---

## 4 · MemoX additions beside the scale

`AppTextStyles` is a `ThemeExtension` and holds six roles. The extension shape is
right — the compact pass re-sizes `cardPrompt` per screen width, which a static
constant could not do (`app_compact_scale.dart:64-71`).

| Role | Composition | Resolved metrics | Callers | Owner recorded? |
|---|---|---|---|---|
| `cardPrompt` | `headlineMedium` → PJS 30 / 1.22 / −0.5, **w600** | 30 / 1.22 / −0.5 | 3 | ✅ `app_text_styles.dart:71-73` + kit token |
| `sectionLabel` | `labelMedium` + tracking 1.1 | 12 / 1.333 / 1.1, **w500** | 11 | ✅ `app_typography.dart:88-92` |
| `sectionLabelSmall` | `labelSmall` + tracking 1.1 | 11 / 1.4545 / 1.1, **w500** | 5 | ✅ `app_text_styles.dart:83-87` |
| `stateChipLabel` | `labelSmall` + tracking 0.6, **w600** | 11 / 1.4545 / 0.6 | 1 | ✅ `app_typography.dart:94-96` |
| `listHeading` | `labelMedium` + tracking 0.72, **w600** | 12 / 1.333 / 0.72 | 1 | ⚠️ tracking yes, **weight no** — **F11** |
| `heroNumeral` | `headlineLarge` + height 0.481 + tabular, **w700** | 32 / 0.481 / 0 | 1 | ✅ `app_typography.dart:98-143` |

Every role has at least one caller. **No dead role.** Two roles have exactly one
caller (`stateChipLabel`, `listHeading`) — that is the accepted price of naming a
decision, and `heroNumeralWeight`'s own dartdoc makes the case for paying it.

Two near-duplicates worth a decision rather than a fix:

- **`sectionLabel` (12/w500/1.1) vs `listHeading` (12/w600/0.72)** — both are an
  uppercase heading over a list. The tracking difference is argued
  (`app_typography.dart:145-154`: the deck-list heading shares its row with the
  sort control). The **weight** difference is stated and not argued. See **F11**.
- **`sectionLabelSmall` (11/w500/1.1) vs `stateChipLabel` (11/w600/0.6)** — both
  `labelSmall` plus tracking. These are genuinely different jobs (an overline
  over content vs a word inside a pill) and both say so. ✅ Keep both.

One MemoX treatment exists **without** a role: the progress screen's streak hero
assembles `withWeight(headlineMedium, w700)` inline
(`progress_streak_hero_widget.dart:106-109`) beside the named `heroNumeral`
role. See **F16**.

---

## 5 · Hierarchy across representative screens

Read from source: what rung each semantic slot resolves to, per screen family.
`✅` = one treatment across the app. `⚠️` = more than one, split by which widget
was reached for rather than by what the text means.

| Slot | Treatment(s) | |
|---|---|---|
| **Screen title** | `titleLarge` 22/w600 PJS — every screen, via `MxContentShell` → `AppBarTheme` (no `titleTextStyle`, so it resolves `textTheme.titleLarge`). Compact drops to 20 | ✅ |
| **Section title** | `sectionLabel` 12/w500/1.1 (11 sites) · `listHeading` 12/**w600**/0.72 (1) · `sectionLabelSmall` 11/w500/1.1 (5) · search group header `labelSmall`/w600/no tracking/**not uppercased** (1) | ⚠️ **F11** |
| **Entity / card title** | `titleMedium` 16/**w600** — deck tile, card tile, study-home deck item, progress deck row, match tile · `bodyLarge` 16/**w400** — both search result tiles + every `MxListTile` (8 call sites) | ⚠️ **F7** |
| **Body** | `bodyMedium` 14/w400/1.45 (54) · `bodyLarge` 16/w400 (8) | ✅ |
| **Supporting / meta** | `bodySmall` 12/w400 (75 — the app's most-used rung) | ✅ |
| **Label** | `labelMedium` 12/w500 (30) · `labelSmall` 11/w500 (22) · `labelLarge` 14/w600 (19) | ✅ |
| **Button** | `labelLarge` @ **w700** standard · `labelMedium` @ **w700** compact — one constant, four themes | ✅ |
| **Navigation** | `labelMedium` 12/w500, selected re-weighted to w600 through `withWeight` | ✅ |
| **Input — hint** | `bodyMedium` 14 @ `onSurfaceVariant` (declared) | — |
| **Input — value** | `TextField` → `bodyLarge` 16/w400 (M3 default, **undeclared**) · `DropdownButton` → `titleMedium` 16/**w600** (M2 default, **unthemable**) · card-editor front field → `titleLarge` 22 (declared + argued) | ⚠️ **F9** |
| **Metric** | `heroNumeral` 32/w700 tabular (deck summary) · `withWeight(headlineMedium, w700)` (progress streak) · `headlineSmall` 24 (progress today) · `withWeight(bodyMedium, w600)` (card metric) · `titleMedium`+`titleSmall`+`labelMedium` (progress metric) | ⚠️ **F16** |
| **Review prompt** | `cardPrompt` 30/1.22/−0.5 (compact 26) · `headlineSmall` 24 for a long back face · `withWeight(titleLarge, w500)` for `backSupportingFront` — all three argued in `study_card_face_section_widget.dart:226-232, 290-306` | ✅ argued |

### 5.1 Check 1 — ≤1 dominant title style per screen

**Screens pass. Overlays do not.**

Every screen has exactly one `titleLarge` at the top and nothing competing with
it. But an overlay's title depends on which helper built it:

| Surface | Title rung | Where |
|---|---|---|
| `MxAlertDialog` / `MxFormDialog` / `MxConfirmDialog` | `titleMedium` 16 | `dialogTheme.titleTextStyle` |
| `MxActionSheet` | `titleSmall` 14 | `mx_action_sheet.dart:118` |
| Hand-rolled sheet + overlay headings | **`titleLarge` 22** | 9 sites: `deck_reset_progress_widget.dart:87`, `deck_scheduler_change_widget.dart:91,161`, `starter_install_widget.dart:125`, `card_import_result_widget.dart:179`, `fill_answer_pieces_widget.dart:205,327`, `study_summary_section_widget.dart:46` |
| `card_export_sheet_widget.dart:310` | `titleMedium` 16 | inline |

Three rungs — 14 / 16 / 22 — for one job, and the split follows the helper, not
the weight of the message. The 22 is the same rung as the *screen* title behind
it, so a sheet heading currently reads at the same level as the app bar it
covers. **F14.**

### 5.2 Check 2 — ≤2 weights per screen unless justified

Fails on every content screen, and the count is 4, not 2.

Deck list, read from source:

| Element | Weight | Source |
|---|---|---|
| deck name, app-bar title, metric titles | w600 | `titleMedium` / `titleLarge` |
| `YOUR DECKS` | w600 | `listHeading` |
| workload meta, breakdown | w400 | `bodySmall` / `bodyMedium` |
| filter + sort pills | w500 | `chipTheme` |
| **the due numeral** | **w700** | `heroNumeral` |
| **the Study button label** | **w700** | `buttonLabelWeight` |

Four weights: 400 / 500 / 600 / 700. Two of the four sites are w700 and each was
argued **separately, in its own file**, neither in the place
`app_typography.dart:136-142` explicitly asks a new weight to argue itself. The
per-screen count is the symptom; **F3** is the cause, and it is the one to fix.

`app_typography.dart:143`'s own words are the strongest evidence here:

> *If a fifth weight ever appears, it should have to justify itself here too.*

`buttonLabelWeight` (M100.30) appeared afterwards and justified itself
elsewhere. The invariant was written down and then not enforced, which is the
one failure mode the whole file is organised against.

---

## 6 · Weights and variable fonts

### 6.1 The axis discipline holds inward — and only inward

`withWeight` is the single legal re-weighting and it moves `fontVariations` and
`fontWeight` together (`app_typography.dart:174-175`). The
`no_bare_font_weight` guard covers `lib/features/*/presentation/**`,
`lib/shared/**` and `lib/core/theme/**`.

**Probed: 0 violations inside that scope, 1 outside it**
(`lib/app/error_screen_widget.dart:95`).

Eighteen `withWeight` call sites, all correct. Every one of the four weights
carried by a rung is mirrored on the axis. This part of the system works.

### 6.2 F1 — the axis discipline defeats the platform's Bold text setting

**[needs SDK confirmation]** and the report's most consequential finding.

Three facts, each independently checkable:

1. **Every rung carries a `wght` axis.** `_display` and `_body` both set
   `fontVariations: _wght(weight)` unconditionally
   (`app_typography.dart:196-221`), so all fifteen rungs and all six
   `AppTextStyles` roles do.
2. **The axis beats `TextStyle.fontWeight` on these faces.** This is the
   project's own repeatedly measured finding, not an outside claim —
   `app_typography.dart:163-169`: *"the renderer consults [the axis] instead of
   `TextStyle.fontWeight` once it is present — so a style re-weighted by
   `fontWeight` alone reports the new weight to every test and paints the old
   one on the device."* Found live twelve times (`docs/wbs.md` M99.66).
3. **Flutter honours the OS Bold-text setting by merging a bare
   `fontWeight`.** `Text.build` merges `const TextStyle(fontWeight:
   FontWeight.bold)` when `MediaQuery.boldTextOf(context)` is true. That
   constant carries no `fontVariations`, and `TextStyle.merge` → `copyWith` with
   a null `fontVariations` **keeps the receiver's**. So the merged style is
   `fontWeight: w700` over `fontVariations: [wght 500]`.

Put together: with *Bold text* on (Android → Accessibility → Text and display →
Bold text; iOS → Display & Text Size → Bold Text), every `Text` in this app
reports w700 to the semantics tree and to every widget test, and paints the
rung's original weight.

**Probed: zero occurrences of `boldText` in `lib/`, `test/` or `widgetbook/`.**
The setting has never been considered, and the architecture that makes this app
render correctly everywhere else is precisely what neutralises it.

Two things make this worse than a missed feature:

- **It is silent in both directions.** A widget test that pumped
  `boldText: true` and asserted `fontWeight` would pass. Only reading
  `fontVariations` — or a device — shows it.
- **It compounds with `heroNumeral`.** That role's `height: 0.481` cap-trim was
  derived from the rendered ink of Plus Jakarta Sans at w700
  (`app_typography.dart:98-120`). If the boldText path *did* work, every
  boldText user would get a differently-trimmed numeral. The fix has to decide
  what boldText means for that role, not just turn it on.

### 6.3 F3 — the weight registry is prose

The app spends four weights. Where each is decided:

| Weight | Spent on | Decided in | Registered in `AppTypography`? |
|---|---|---|---|
| w400 | body rungs | `app_typography.dart` | ✅ it is the file |
| w500 | `labelMedium`, `labelSmall`, chip label, two title de-emphases | `app_typography.dart` + `app_chip_theme.dart:143` + two feature sites | partial |
| w600 | title rungs, `labelLarge`, `AppInk.isEmphasized`, three roles | `app_typography.dart` + `app_ink.dart:138` | ✅ |
| **w700** | `displayLarge`, `displayMedium`, **`heroNumeral`**, **every button label** | `app_typography.dart:143` + **`app_button_themes.dart:430`** | ❌ half |

`app_typography_test.dart:271` is named *"the hero numeral is the one weight a
feature adds, and it is named"*. Since M100.30 that sentence is false about the
application — a button label is the app's most repeated w700 — and the test
still passes, because it only asserts `heroNumeralWeight == w700` and
`headlineLarge == w600`. Neither assertion can see a new w700 arriving anywhere
else.

Two supporting artefacts of the same drift:

- `deck_study_button_widget.dart:41` documents its label as *"`label-md` at
  600"*. `MxActionButtonSize.compact` sets it through `buttonLabelWeight`, which
  is **700** (`mx_action_button.dart:303-307`). **F21.**
- `app_typography.dart:126-127` argues the hero exception is safe because *"the
  theme spends `w700` only on the two display rungs (57 and 45), neither of which
  appears on the deck list"*. The deck list now renders a w700 button label on
  every row.

### 6.4 Feature-level re-weighting is open by design, and unbounded in practice

M99.66 deliberately left a bare `withWeight(...)` legal in feature code
(`docs/wbs.md`: *"`withWeight` thuần vẫn hợp lệ"*), and that was a reasonable
call. What it left unbounded is the *weight argument*:

| Site | Rung | Weight | Expressible as `inked(isEmphasized:)`? |
|---|---|---|---|
| `progress_streak_hero_widget.dart:106` | `headlineMedium` | **w700** | no — 700 is not in the closed set |
| `card_metric_widget.dart:113` | `bodyMedium` | w600 | **yes** — already the closed spelling |
| `study_card_face_section_widget.dart:302` | `titleLarge` | **w500** | no — *downward* re-weighting has no name |
| `match_tile_widget.dart:104` | `titleMedium` | **w500** | no — same |

Two of these move a rung *down* in weight, which no role and no flag in the
system covers. Each is locally argued; nothing bounds the set they can produce.
The closure test in §11 (T3) bounds it without taking `withWeight` away.

---

## 7 · Direct-style drift, and the three ways it escapes the guard

Three guard rules watch typography. Each was re-implemented in a probe (regex
and scope copied verbatim from
`code-verification-guard-v2/registries/projects/memox-v7/`) and run against both
its declared scope and a wider one.

```
### no_bare_font_weight   scope: features/presentation + shared + core/theme
  in declared scope : 0
  in wider scope    : 1  (+1 escaping)
    ESCAPES  lib/app/error_screen_widget.dart:95   fontWeight: FontWeight.w600,

### no_text_restyle       scope: features/presentation only
  in declared scope : 0
  in wider scope    : 10 (+10 escaping)   ← all 10 in lib/shared/widgets/

### no_raw_text_style     scope: features/presentation + shared
  in declared scope : 0
  in wider scope    : 10 (+10 escaping)   ← 8 are lib/core/theme/typography/ and legitimate;
                                             2 are lib/app/error_screen_widget.dart:92,102
```

### F4 · `textStyles.<role>.copyWith(color:)` is not in the pattern list

`no_text_restyle`'s own message names the alternative:

> *"…or a named role on `context.textStyles`."*

Its three patterns watch `texts.X.copyWith`, `withWeight(...).copyWith` and
`textTheme.X.copyWith`. None matches `textStyles.X.copyWith` — the regex
`\btexts\.` finds `texts` inside `textStyles` and then needs a `.` where an `S`
is. **Probed: 9 live sites**, every one of them an open `Color` on a named role:

```
card_export_sheet_widget.dart:325          sectionLabel      + colors.onSurfaceVariant
card_detail_state_widget.dart:52           sectionLabel      + colors.onSurfaceVariant
card_history_section_widget.dart:64        sectionLabel      + colors.onSurfaceVariant
card_import_confirm_step_widget.dart:63    sectionLabel      + colors.onSurfaceVariant
card_import_preview_step_widget.dart:83    sectionLabel      + colors.onSurfaceVariant
card_import_preview_step_widget.dart:273   sectionLabelSmall + colors.onSurfaceVariant
card_import_preview_summary_widget.dart:70 sectionLabel      + colors.onSurfaceVariant
card_import_source_step_widget.dart:68     sectionLabel      + colors.onSurfaceVariant
card_progress_panel_widget.dart:254        sectionLabel      + colors.onSurface
```

Eight resolve to exactly `AppInk.quiet` and one to exactly `AppInk.stated`, so
**no pixel is wrong today** — this is a closure hole, not a visual defect. The
same eight labels are spelled the closed way in `settings_section_widget.dart:57`
and `study_home_body_section_widget.dart:202`. Two spellings, one meaning, and
the guard only sees one of them.

### F5 · `lib/shared/widgets/` is outside `no_text_restyle`, twice over

M99.66's acceptance criterion says `lib/features/`, and the rule's scope
(`presentation_files`) still says the same. Nine open-colour restyles remain in
the layer that *defines* the design system:

| Site | Rung | Colour | Closed spelling |
|---|---|---|---|
| `mx_empty_state.dart:82` | `bodyMedium` | `onSurfaceVariant` | `.inked(ctx, AppInk.quiet)` |
| `mx_error_state.dart:86` | `bodyMedium` | `onSurfaceVariant` | ↑ |
| `mx_progress_bar.dart:172` | `labelMedium` | `onSurfaceVariant` | ↑ |
| `mx_action_sheet.dart:118` | `titleSmall` | `onSurfaceVariant` | ↑ |
| `mx_breadcrumb.dart:184` | `bodySmall` | `onSurfaceVariant` | ↑ |
| `mx_breadcrumb_step.dart:97` | `labelMedium` | `onSurfaceVariant` | ↑ |
| `mx_breadcrumb_step.dart:187` | `bodySmall` | `onSurfaceVariant` | ↑ |
| `mx_form_dialog.dart:142` | `bodySmall` | `colors.error` | `.inked(ctx, AppInk.error)` |
| `mx_action_sheet.dart:173` | `bodyLarge` | computed | genuinely needs the escape |
| `mx_text_field.dart:274` | `bodySmall` | computed | ↑ (already noted as F9 in the text-field audit) |

**And widening the scope alone would not catch the worst four.** The rule's
second pattern exists specifically to close the
`withWeight(...).copyWith(color:)` laundering route. A second probe shows all
four live instances are formatted across lines by `dart format`, and the
pattern is line-scoped:

```
MULTILINE (invisible to the guard)  lib/shared/widgets/mx_breadcrumb_step.dart:119
MULTILINE (invisible to the guard)  lib/shared/widgets/mx_progress_bar.dart:183
MULTILINE (invisible to the guard)  lib/shared/widgets/mx_search_field.dart:188
MULTILINE (invisible to the guard)  lib/shared/widgets/mx_session_top_bar.dart:244
LINE-VISIBLE                        lib/core/theme/components/selection/app_chip_theme.dart:156  ← legitimate
```

`mx_session_top_bar.dart:244-251` is the clearest case: it is
`withWeight(textStyles.sectionLabel, w600).copyWith(color: colors.primary)` —
which is character-for-character what `sectionLabel.inked(ctx, AppInk.accent,
isEmphasized: true)` returns. The long spelling exists only because two
independent defences both miss it.

### F6 · `lib/app/` is in no typography scope, and one product screen lives there

`scopes.yaml:223-225` excludes `lib/app/**` from `ui_surfaces`, and the reason
given is about **colour**: *"it is the dev-channel shell (MobileFrameWidget's
backdrop colour is not product UI)"*. That argument does not extend to type, and
`lib/app/error_screen_widget.dart` is not the dev shell — it is what a user sees
when `bootstrap()` fails (`bootstrap.dart:86`) or a widget throws in release
(`bootstrap.dart:202`).

```dart
style: TextStyle(color: palette.title, fontSize: 20, fontWeight: FontWeight.w600),
style: TextStyle(color: palette.message, fontSize: 14),
```

`fontFamily` is **absent**. The screen deliberately renders without a `Theme`, so
`ThemeData.fontFamily: Inter` does not reach it and the engine falls back to the
platform default — Roboto on Android, whatever the browser picks on web. **It is
the only screen in the app that renders in a foreign typeface.**

The file's own reasoning already contains the fix. It writes:

> *"The real spacing tokens, like the colours below: `AppSpacing` is a class of
> compile-time constants and needs no theme to be alive. Only the two font sizes
> stay literal — the text theme does need a `Theme`."*

`AppTypography.displayFamily`, `bodyFamily` and `cjkFallback` are compile-time
constants under the identical argument. The sizes genuinely have to stay
literal; the **family does not**, and neither does the fallback chain, which is
why a startup failure in a Korean locale currently has no CJK face behind it.

Two details the fix must not miss:

- Adding `fontFamily` turns `fontWeight: w600` into the bug this app has fixed
  twelve times. It must arrive with `fontVariations: [FontVariation('wght',
  600)]` in the same edit.
- If the failure happened before the font manifest loaded, the family resolves
  to nothing and the screen renders exactly as it does today. So the change is
  strictly an improvement with no worse case.

Why nobody noticed: `test/flutter_test_config.dart:95` loads Roboto as *"the
fallback the framework reaches for when a style names no family"*, so a test
render and a device render agree — both in the wrong face.

---

## 8 · Scaling, localization and contrast

### 8.1 Text scale — the posture is right, the coverage has two holes

**No clamp anywhere in `lib/`.** Probed: every `clamp(` under `lib/` is on a
progress fraction, an inset or a stored minute. `MediaQuery.textScaler` is read
in ten widgets to *measure against*, never to cap. ✅ This is correct and worth
protecting.

Coverage, probed across `test/`:

| Scale | Assertions | Note |
|---|---|---|
| 1.0 | baseline everywhere | ✅ |
| **1.3** | **0** | ❌ **F12** — the top of Android's ordinary Font-size slider, and the most likely non-default value a real user has |
| 1.5 | 7 | breadcrumb + two deck probes |
| 2.0 | 82 | where essentially all large-text evidence lives |
| **2.5** | **0** | ❌ **F12** |
| 3.0 | 2 | `mx_accessibility_test.dart:176,193`, both at 320 wide |

The brief asks for 1 / 1.3 / 2 and 2.5 / 3 where critical. Two of the five steps
are untested. 1.3 is the interesting gap: it is common, it is small enough that
nothing overflows, and it is therefore exactly the scale where a *hierarchy*
inversion (a 12px heading and a 14px value converging) would show up without any
test failing.

### 8.2 Uppercase — the app writes the rule down once and breaks it twenty times

Twenty-one sites call `toUpperCase()` on painted text. Probed for an accessible
name (`Semantics(label:, excludeSemantics: true)` or `semanticsLabel:`):

```
total uppercase paint sites: 21
  with an accessible name:    2
  without:                   19
```

The two that have it state the reason, in almost the same words:

> `study_home_body_section_widget.dart:188-192` — *"**The name is the sentence,
> not the shouting.** The uppercase is a typographic treatment; some TTS engines
> spell an all-caps run out letter by letter, so the label states the heading as
> written and the painted text is excluded."*

> `settings_section_widget.dart:46-49` — *"The **written** sentence is the
> accessible name; the uppercase is a typographic treatment… these headings are
> what tell three rows all labelled 'System' apart."*

The other nineteen paint the same all-caps run with no label — including
`deck_list_toolbar_widget.dart:78` (`YOUR DECKS` / `SUB-DECKS`, on the app's
landing screen), `mx_session_top_bar.dart:242` (the mode chip on every study
screen), `card_tile_widget.dart:210` (the state word on every card row) and six
of the card-import stepper's headings. **F2.**

A third widget states the *opposite* rule and follows it:

> `search_group_header_widget.dart:27-30` — *"Rendered exactly as the ARB
> authored it. `toUpperCase()` on a localized string is the translator's decision
> to make, not the widget's — it is wrong for locales with no case and changes
> the width the layout was measured at."*

So the codebase contains two incompatible written rules about the same
treatment, each followed by the file that states it. That is not a bug in either
file; it is a missing decision, and §11 asks for it rather than assuming an
answer.

Header semantics is a separate, smaller gap: only 3 of the 16 files that render
a section-label role wrap it in `Semantics(header: true)`, so screen-reader
heading navigation skips most of the app's section structure.

### 8.3 Vietnamese

Measured over all 836 ARB keys:

| | |
|---|---|
| median VI/EN length ratio | **1.000** |
| mean | 0.968 |
| worst expansion (EN ≥ 10 chars) | 1.83× (`cardMoveEmptyTitle`, 18 → 33) |
| longest VI string | 240 chars (`deckDeleteImpactMessage`, shorter than EN's 355) |

Vietnamese is **not** an expansion risk for this app in aggregate. The uppercase
section labels are all short in both languages (worst: `TRẠNG THÁI HIỆN TẠI`, 19
chars). Width is fine.

The real Vietnamese typography risk is **vertical**: uppercase VI stacks two
marks on one vowel (`Ế` = E + circumflex + acute, `Ộ`, `Ậ`), and the
section-label roles run at 11–12 px inside a 16 px line box
(`height: 16/12` and `16/11`). Whether that ink stays inside its box is a font
metric question that needs a render.

**Committed evidence: one screen family.** VI goldens exist for card detail
(×5), card export sheet, deck delete confirm and tag catalog. `TRẠNG THÁI HIỆN
TẠI` appears in `card_detail_state_grid_vi_x2.png` — so the case *is* covered
once. Not covered in Vietnamese anywhere: the deck list heading
(`DECK CỦA BẠN`), the settings group headings, the study-home heading
(`HỌC TIẾP THEO`) and the session mode chip. **F15.**

### 8.4 Contrast — the threshold logic is correct

`test/visual_audit/audit_model.dart:208-221` implements WCAG 1.4.3 exactly:

```dart
const largeRegular = 24.0;      // 18pt
const largeBold    = 18.66;     // 14pt
final isBold = (fontWeight?.value ?? 0) >= FontWeight.w700.value;
return size >= largeRegular || (isBold && size >= largeBold);
```

Both thresholds right, both units right, and an unknown size resolves to `false`
so a missing measurement buys the *stricter* bar. `audit_rules.dart:53-79` picks
4.5 / 3.0 off it correctly. ✅ **This check passes**, and it is the only place in
the audited surface where WCAG's normal/large split is implemented at all.

One latent hole, and it is this report's own subject: `isBold` reads
`fontWeight`. In this app `fontWeight` and the `wght` axis are kept in step by
construction — but the entire guard architecture exists because they *can*
part, and if they ever do, the contrast audit grants the lenient 3:1 threshold
to text that paints at w500. **F20**, P3, one-line fix.

---

## 9 · Dead and duplicate typography

| Candidate | Verdict |
|---|---|
| `displayLarge`, `displayMedium` | **Not dead** — canonical M3 slots, legitimately reachable. But two arguments (`app_typography.dart:126`, `app_typography_test.dart:259`) lean on them being unused; see **F3** |
| `AppTextStyles` roles | **None dead.** All six have ≥1 caller |
| `AppTypography` constants | **None dead.** All fourteen have ≥1 consumer |
| `chipTheme.labelStyle` at `label-lg` 14 | **Live but nearly displaced** — painted only by the two raw `Chip`/`ActionChip` in `card_tag_section_widget.dart:290,299`. Every `MxPillButton` overrides size, leading and tracking down to `label-md` 12. See **F8** |
| `sectionLabel` vs `listHeading` | **Near-duplicate**, weight difference unargued — **F11** |
| `--text-headline-md` / `--leading-headline-md` | **Missing from the kit entirely** — **F10** |

### F10 · The kit is authoritative, and five typography values are not in it

`typography.css` has been authoritative for token values since M4.10p, and
`css_scale_coverage_test.dart` asserts every token in it is consumed. That check
runs **CSS → Dart only**. A Dart value with no CSS token is structurally
invisible to it, and five exist:

| Dart value | Where | CSS token |
|---|---|---|
| `headlineMedium` 28 / 36 / w400 | `app_typography.dart:254-259` | **absent** |
| `stateChipTracking` 0.6 | `app_typography.dart:96` | **absent** |
| `listHeadingTracking` 0.72 | `app_typography.dart:154` | **absent** |
| `heroNumeralCapTrim` 0.481 | `app_typography.dart:120` | **absent** |
| `sectionLabelSmall`'s composition | `app_text_styles.dart:46-48` | shares `--tracking-section-label` |

`headlineMedium` is the sharpest of the five: it is the only M3 rung with no kit
token *and* no assertion in `css_scale_parity_test.dart` (which covers the other
fourteen plus the card prompt). And `app_typography_test.dart:85-91` pins it
under the token name `'headline-md'` — a name that exists nowhere in
`typography.css`. That file's header says *"the numbers below are copied from
the CSS by hand, deliberately"*; for this rung there was nothing to copy.

It is not academic: `headlineMedium` is the base of `AppTextStyles.cardPrompt`
and is painted directly by the progress streak hero.

One smaller documentation drift in the same family: `--tracking-section-label`'s
CSS comment says *"uppercase label-sm, 1.1px tracked"* and
`sectionLabelTracking`'s dartdoc says *"Uppercase set at 11px closes up"* — but
the primary role, `sectionLabel`, applies it to **`labelMedium` at 12px** (11 of
16 call sites). The value was derived at 11px (0.1em) and is spent at 12px
(0.092em). **F22**, P3 — the value is defensible, the record is wrong.

---

## 10 · Coverage — tests, Widgetbook, goldens

### 10.1 Tests

| File | Covers | Gap |
|---|---|---|
| `app_typography_test.dart` (297 ln) | all 15 rungs + card prompt against hand-copied CSS numbers; the three scale weights; the hero exception | names a non-existent token (`headline-md`); its weight test no longer describes the app (**F3**) |
| `component_theme_typography_test.dart` (263 ln) | 10 of 20 component text slots; the anti-vacuous `base.textTheme` source check | 10 slots unasserted (**F13**); reads theme slots, so widget-level overrides are invisible (**F8**) |
| `css_scale_parity_test.dart` | 14 rungs + prompt + compact + faces + 4 weights against the parsed CSS | `headlineMedium` absent (**F10**) |
| `css_scale_coverage_test.dart` | every CSS token is asserted somewhere | one-directional by construction (**F10**) |
| `app_ink_test.dart` | every ink measured on its own ground, both themes | — |
| `visual_audit/` | WCAG normal/large split, correctly | `isBold` reads `fontWeight` (**F20**) |

The 10 component text slots with **no** typography assertion:
`popupMenuTheme.labelTextStyle`, `tabBarTheme.labelStyle`,
`tabBarTheme.unselectedLabelStyle`, `timePickerTheme.helpTextStyle` /
`.dialTextStyle` / `.hourMinuteTextStyle` / `.dayPeriodTextStyle`,
`datePickerTheme.weekdayStyle` / `.dayStyle`,
`sliderTheme.valueIndicatorTextStyle`. All ten resolve from `texts`, so they are
almost certainly right — but "almost certainly right" is the exact state
`component_theme_typography_test.dart`'s own header says is not the same as
right. **F13.**

### F8 · The chip test asserts a rung the app does not paint

`app_chip_theme.dart:140-142` states the decision:

> *"500 is Material's own chip weight… **Size, leading and tracking stay
> `label-lg`**: the label was never the wrong *size*."*

`mx_pill_button.dart:64-74` then overrides exactly those three:

```dart
/// The theme's chip label with `label-md`'s size, leading and tracking.
return themed.copyWith(
  fontSize: rung.fontSize,        // 12, not 14
  height: rung.height,            // 1.333, not 20/14
  letterSpacing: rung.letterSpacing,  // 0.5, not 0.1
);
```

`component_theme_typography_test.dart:119` asserts `chipTheme.labelStyle` is
`label-lg`. It is. **No `MxPillButton` paints it** — and `MxPillButton` is the
app's only `ChoiceChip` caller, used by the card filter bar, the trash filter
bar, the progress range selector, study options and study entry.

`docs/wbs.md:5694-5700` records the intent as a **two-tier** decision — toolbar
pills down to `label-md`, *"`chipTheme` giữ `label-lg` (14) cho pill filter của
card list"*. The implementation applies 12 to every caller including the card
filter bar, so either the WBS entry is stale or the code collapsed a two-tier
decision to one tier. Either way the shipped 12 is pinned by nothing, and the
tested 14 survives only on two raw tag chips. Worth an owner decision, not a
unilateral fix.

### F7 · One entity title, two weights, split by widget class

Every entity title in the app is 16 px. The weight is not:

| Surface | Rung | Weight |
|---|---|---|
| deck tile (`deck_tile_widget.dart:138`) | `titleMedium` | **w600** |
| card tile (`card_tile_widget.dart:173`) | `titleMedium` | **w600** |
| study-home deck item, progress deck row, match tile | `titleMedium` | **w600** |
| **deck search result** (`deck_result_tile_widget.dart:50`) | `bodyLarge` | **w400** |
| **card search result** (`card_result_tile_widget.dart:77`) | `bodyLarge` | **w400** |
| **every `MxListTile`** — 8 call sites incl. move-deck sheet, trash restore sheet, both study choosers | `bodyLarge` **[needs SDK confirmation: `_LisTileDefaultsM3.titleTextStyle`]** | **w400** |

So the same deck name is w600 in the Library and w400 in search results. Neither
search tile carries a comment — in a codebase where every decision carries three
paragraphs, the silence is itself evidence this was not a decision. The
`MxListTile` half is a known consequence of the theme declaring no
`titleTextStyle`; `mx-list-tile-deep-audit.md` §17 catalogued it inside that
component (F17.1, F17.2). This report's contribution is the **cross-screen**
view: it is one role with two weights across seven features, and the split
tracks which widget was reached for.

### F9 · `DropdownButton` renders its value at the app's emphatic weight

`app_theme.dart:204-218` already documents that `DropdownButton` is a Material 2
survivor with no `ThemeData` slot, and closes the `canvasColor` and
`disabledColor` gaps by hand for exactly that reason. It does not close the
typography gap.

`MxDropdown` (`mx_dropdown.dart:44-63`) states no style, so the value and every
menu item resolve `Theme.of(context).textTheme.titleMedium` **[needs SDK
confirmation]** — 16 px Inter **w600**, tracking 0.15. Every other input value
in the app is `bodyLarge`, 16 px **w400**. The card importer builds two of them
(`card_import_preview_step_widget.dart:341`,
`card_import_mapping_row_widget.dart:55`), so on the column-mapping screen the
dropdown's value is set heavier than the field label above it and heavier than
every other value on the screen. It is the app's only emphatic-weight *value*.

### 10.2 Widgetbook

`widgetbook/lib/tokens/typography_section.dart` catalogues all 15 rungs plus
`cardPrompt` and `sectionLabel` — **2 of the 6** `AppTextStyles` roles. The four
added by M99.66 (`sectionLabelSmall`, `stateChipLabel`, `listHeading`,
`heroNumeral`) never arrived, and the section's comment still reads *"The two
named styles that live beside the scale"*. **F18**, P3 — a straight CLAUDE.md
DoD miss ("every new shared component registered in the Widgetbook catalog").

`_spec()` (line 90) prints `style.fontWeight?.value` — the field this app has
decided not to trust. The catalog page whose job is to tell a reader what a rung
*is* reports the number that lies on a variable font. **F17**, P3.

### 10.3 Goldens

`typography_light.png` / `typography_dark.png` are the only visual specimen of
the type system. `TypographySpecimen` (`golden_specimens.dart:50-77`) renders
**6 of 15 rungs** (`cardPrompt`, `titleLarge`, `titleMedium`, `bodyMedium`,
`labelLarge`, `bodySmall`) and **1 of 6 named roles**. A change to `labelSmall`'s
tracking, `sectionLabel`'s weight or `heroNumeral`'s cap trim moves this golden
by zero pixels. **F19**, P3.

152 screen goldens exist. Breakdown relevant to type: 6 at `×2` text scale, 12
Vietnamese, 3 at 320 dp, 1 at 412 dp. The Vietnamese set covers one screen
family for the uppercase case (**F15**).

---

## 11 · Severity registry

Every P1 and P2 carries a closure test — the thing that must exist for the
finding to be considered fixed rather than tidied. All of them run on the host
suite; none needs a device or a golden.

### P1

| # | Finding | Evidence | Closure test |
|---|---|---|---|
| **F1** | The OS **Bold text** setting paints nothing. Every rung carries a `wght` axis; Flutter's `Text` honours `boldText` by merging a bare `fontWeight`, which the axis overrides. Zero references to `boldText` in the repo | `app_typography.dart:196-221` (axis on every rung) · `app_typography.dart:163-169` (the app's own measured "axis beats fontWeight") · probe: 0 hits for `boldText` in `lib/ test/ widgetbook/` | Pump a `Text` at three rungs under `MediaQuery(data: …copyWith(boldText: true))`; assert the **resolved `fontVariations` `wght`** moves, not just `fontWeight`. Must fail today. Fix belongs in one place — a `boldText`-aware wrapper at the composition root or in `AppTypography` — and must state what boldText means for `heroNumeral`'s derived cap-trim |
| **F2** | 19 of 21 all-caps surfaces have no accessible name. The app documents the TTS problem and fixes it twice | probe: 21 `toUpperCase()` paint sites, 2 with `label:` + `excludeSemantics:` · `study_home_body_section_widget.dart:188-192` · `settings_section_widget.dart:46-49` | A test that walks every widget calling `toUpperCase()` on painted text (source-level, like `component_theme_typography_test.dart`'s `base.textTheme` check) and requires an accessible name — or, better, a shared `MxSectionLabel` that carries the label, the role and `header: true` so the rule is structural. Count must be 21/21 |

### P2

| # | Finding | Evidence | Closure test |
|---|---|---|---|
| **F3** | The weight registry is prose. `buttonLabelWeight = w700` (M100.30) never came past the note that asks a fifth weight to justify itself; `app_typography_test.dart:271`'s title is now false and still green | `app_typography.dart:136-143` · `app_button_themes.dart:430` · `app_typography_test.dart:258-294` | Enumerate every weight reachable from the built theme — 15 rungs + 6 roles + all 20 component text slots + the named constants — and assert the set is exactly `{400, 500, 600, 700}` **and** that each w700 site is on a named allowlist. A sixth weight, or an unnamed w700, fails |
| **F4** | `textStyles.<role>.copyWith(color:)` is outside `no_text_restyle`'s patterns although the rule's message names that API. 9 live sites | probe §7 · rule at `memox-design-system-rules.yaml:165-183` | Add `'^(?!\s*(?://\|\*)).*\btextStyles\.[a-zA-Z]+\s*\.copyWith\s*\('` as a fourth pattern; a two-way probe must go red on today's 9 sites and green after they move to `.inked(…)` |
| **F5** | `no_text_restyle` stops at `lib/features/`. `lib/shared/widgets/` holds 9 open-colour restyles + 4 `withWeight(…).copyWith` launderings, and all 4 are multi-line so the line-scoped pattern misses them even with the scope widened | probe §7 (both parts) · `mx_session_top_bar.dart:244-251` | Two changes, both needed: widen the scope to `ui_surfaces`, **and** make the laundering pattern `mode: file` with a balanced-paren walk. Probe must find all 4 before, 0 after |
| **F6** | `lib/app/` is in no typography scope; `error_screen_widget.dart` renders in the platform font, the only screen in the app that does | probe §7 · `error_screen_widget.dart:92,102` · `scopes.yaml:223-225` | Add `lib/app/**` to `ui_and_theme_surfaces` (typography rules only — the colour exemption for `MobileFrameWidget` stays). Then a test asserting the error screen's two styles name `AppTypography` families, carry `cjkFallback`, and carry `fontVariations` matching their `fontWeight` |
| **F7** | Entity title is 16 px everywhere but w600 in six features and w400 in search + every `MxListTile`. Split follows widget class | `deck_tile_widget.dart:138` vs `deck_result_tile_widget.dart:50` · 8 `MxListTile` call sites | Decide the rung once, then pin it: a test asserting `listTileTheme.titleTextStyle` is non-null and equals the chosen rung, plus the two search tiles asserted against the same. (`mx-list-tile-deep-audit.md` step 1 already proposes the `ListTileThemeData` half — this makes it one decision instead of two) |
| **F8** | `chipTheme.labelStyle` declares `label-lg` and says size/leading/tracking stay there; `MxPillButton` overrides all three at every call site. The test asserts the slot | `app_chip_theme.dart:140-142` vs `mx_pill_button.dart:64-74` · `component_theme_typography_test.dart:119` · `docs/wbs.md:5694-5700` | A **widget-level** assertion: pump `MxPillButton` and read the resolved `DefaultTextStyle`, asserting the rung that actually ships. Then reconcile `app_chip_theme.dart`'s comment and the WBS entry with whichever tier the owner keeps |
| **F9** | `DropdownButton` renders its value at `titleMedium` w600 — the app's only emphatic-weight input value — through a widget family with no theme slot | `mx_dropdown.dart:44-63` (no style) · `app_theme.dart:204-218` (the gap, closed for colour only) | Pump `MxDropdown` and assert the resolved value style equals the app's input-value rung. Fix by stating `style:` in `MxDropdown`, beside the same argument `canvasColor` already carries |
| **F10** | Five typography values live only in Dart while the kit is authoritative; `headlineMedium` is the only M3 rung with no token and no parity assertion, and the test names a token that does not exist | `typography.css` (no `--text-headline-md`) · `css_scale_parity_test.dart:178-205` · `app_typography_test.dart:85-91` | Add the five tokens to `typography.css` + assertions to `css_scale_parity_test.dart` + names to `_asserted`. Then add the **reverse** check the coverage test cannot do: every public typography constant in `AppTypography` and every `AppTextStyles` role maps to a kit token or is on a named exemption list |
| **F11** | `sectionLabel` (12/w500/1.1) and `listHeading` (12/w600/0.72) are one job with two treatments. The tracking is argued; the weight raise is stated only | `app_typography.dart:145-154` · `app_text_styles.dart:93-95` | Either fold `listHeading` into `sectionLabel` + `isEmphasized`, or write the weight argument beside the tracking argument. Closure: a test asserting the two roles differ in exactly the properties the dartdoc names |
| **F12** | textScale 1.3 and 2.5 are exercised by zero tests; 82 of 91 assertions sit at 2.0 | probe over `test/` | Add 1.3 to the existing `textScale` harness parameter on at least the four densest screens (deck list, card detail, study session, progress) and 2.5 wherever 3.0 is already pinned |
| **F13** | 10 of 20 component-theme text slots have no typography assertion | §10.1 | Extend `component_theme_typography_test.dart` to the remaining ten. The file's own closing test already argues for exactly this |
| **F14** | Overlay titles span three rungs (14/16/22) by which helper built them; the 22 equals the screen title behind it | `mx_action_sheet.dart:118` · `app_dialog_theme.dart:35` · 9 inline `titleLarge` sites | Pick one overlay-title rung, put it on the shared overlay widgets, and assert it there. The nine inline sites then have nothing to state |
| **F15** | Uppercase Vietnamese is rendered in one golden family; the deck-list heading, settings headings and session mode chip have no VI render | `ls test/demo/goldens/*vi*` | Add a Vietnamese golden for the deck list and for settings. **Regenerate on Linux with `TZ=UTC` and republish the gallery at the pinned URL** (CLAUDE.md) |
| **F16** | A second hero treatment is assembled inline beside the named `heroNumeral` role — the failure mode `heroNumeralWeight`'s own dartdoc describes | `progress_streak_hero_widget.dart:106-109` vs `app_text_styles.dart:97-102` | Name it (`heroPhrase` or similar) on `AppTextStyles`, or fold it into `heroNumeral` if the owner decides the cap-trim suits a phrase. Closure: `lib/features/` contains no `withWeight(…, w700)` |

### P3

| # | Finding | Where |
|---|---|---|
| F17 | Widgetbook's `_spec()` prints `style.fontWeight` — the field this app decided not to trust | `typography_section.dart:90` |
| F18 | Widgetbook catalogues 2 of 6 `AppTextStyles` roles; the comment still says "the two named styles" | `typography_section.dart:37-39` |
| F19 | The typography golden shows 6 of 15 rungs and 1 of 6 roles | `golden_specimens.dart:50-77` |
| F20 | `isLargeText` reads `fontWeight`, not the `wght` axis — leniently wrong if the two ever part | `audit_model.dart:218` |
| F21 | `deck_study_button_widget`'s dartdoc says `label-md` at 600; it paints 700 | `deck_study_button_widget.dart:41` |
| F22 | `--tracking-section-label`'s comment and `sectionLabelTracking`'s dartdoc both describe 11 px; the primary role applies it at 12 px | `typography.css` · `app_typography.dart:88-92` |
| F23 | `heroNumeral` is a public role whose 0.481 cap-trim is safe only for digits ("no descenders, no diacritics"); nothing enforces digits-only | `deck_summary_metrics_widget.dart:285-287` |
| F24 | `card_progress_panel`'s comment claims "same rung as `YOUR DECKS`" — same rung, different weight and different tracking | `card_progress_panel_widget.dart:244-252` |

---

## 12 · Implementation order

Four steps. Each is independently mergeable, each leaves the tree greener than
it found it, and the order puts the things that *prevent recurrence* before the
things that *fix instances* — because otherwise the instances come back.

### Step 1 — close the enforcement perimeter (no behaviour change)

Fixes the mechanism that let F4, F5 and F6 exist, before touching any of them.

| File | Change |
|---|---|
| `…/memox-design-system-rules.yaml` | `no_text_restyle`: add the `textStyles.<role>.copyWith` pattern (F4); convert the laundering pattern to `mode: file` with a balanced-paren walk (F5); widen scope to `ui_surfaces` |
| `…/config/scopes.yaml` | add `lib/app/**` to `ui_and_theme_surfaces` for the typography rules; extend the existing comment to say the `MobileFrameWidget` exemption is about colour |
| probe | two-way, per the project's own convention: red on today's 9 + 9 + 4 + 1 sites, green after step 2 |

**Expected: the guard goes red.** That is the deliverable, not a problem.

### Step 2 — spend the closed API where it already exists (no visual change)

| File(s) | Change |
|---|---|
| 9 card-feature sites (§7 F4 table) | `textStyles.X.copyWith(color: onSurfaceVariant)` → `.inked(context, AppInk.quiet)`; the one `onSurface` → `AppInk.stated` |
| 7 shared sites (§7 F5 table) | same, to `AppInk.quiet` / `AppInk.error` |
| `mx_session_top_bar.dart:244-251`, `mx_search_field.dart:188-192`, `mx_breadcrumb_step.dart:119-123`, `mx_progress_bar.dart:183-187` | `withWeight(…).copyWith(color:)` → `.inked(…, isEmphasized: true)` |
| `error_screen_widget.dart:92-103` | add `fontFamily` (display for the title, body for the message), `fontFamilyFallback: cjkFallback`, and `fontVariations` beside the existing `fontWeight` |

Every colour here resolves to the value it already has, so no golden should
move — **except** the error screen, which changes typeface. Regenerate on Linux
with `TZ=UTC` and republish the gallery at the pinned URL.

### Step 3 — make the invariants checkable (the P1s and F3)

| File | Change |
|---|---|
| `test/core/theme/typography/app_typography_test.dart` | replace the "three weights" test with the **complete weight registry** (F3): enumerate every reachable weight, assert the set, assert every w700 is on a named list. Add `buttonLabelWeight` to that list and to `AppTypography`'s note |
| new — `test/core/theme/typography/bold_text_test.dart` | the F1 closure test. Must fail on `main` before the fix lands |
| `lib/core/theme/typography/app_typography.dart` or the composition root | the F1 fix. One place. Must state what boldText does to `heroNumeral`'s derived cap-trim |
| new or extended | the F2 closure test, and preferably an `MxSectionLabel` that makes the accessible name structural rather than remembered |
| `test/core/theme/components/component_theme_typography_test.dart` | the remaining 10 slots (F13); a widget-level pill assertion (F8) |
| `test/design_audit/css_scale_parity_test.dart`, `css_scale_coverage_test.dart`, `design_system/tokens/typography.css` | the five missing tokens + the reverse Dart→CSS check (F10) |

### Step 4 — the decisions this audit deliberately did not make

Four questions belong to the owner. Each is written as a question with the
evidence attached, not as a fix waiting for approval:

1. **Uppercase on localized strings — which written rule wins?**
   `search_group_header_widget.dart:27-30` says the translator decides;
   nineteen other widgets uppercase in the widget. Both are defensible; two
   written rules in one codebase are not. Whichever wins, the losing files
   change and the rule goes somewhere `docs/design-system/` can hold it.
2. **The entity-title rung (F7).** `titleMedium` w600 or `bodyLarge` w400 — and
   `titleMedium`'s w600 raise itself has never been written down. This is the
   app's second-most-used rung; the decision is worth ten minutes and a golden.
3. **The chip rung (F8).** The WBS records a two-tier decision that the code
   applies as one. Keep the two tiers (and give `MxPillButton` a size knob), or
   drop to one (and correct `app_chip_theme.dart`'s comment and the WBS entry).
4. **The overlay-title rung (F14).** One of 14 / 16 / 22, on the shared overlay
   widgets.

### What this audit did not do

- **Nothing was measured.** No render, no pixel, no contrast ratio computed from
  a screenshot. The three **[needs SDK confirmation]** claims (F1's framework
  half, F7's `MxListTile` default, F9's `DropdownButton` default) each ship with
  a host test that settles them.
- **No golden was regenerated and no gallery was published.** This branch
  changes one file.
- **`analyze`, `format`, the guard and the test suite were not run** — no
  Flutter or Dart SDK, and no `typer` for the guard runner. The only executable
  verification here is the Python probes, which are inlined so they can be
  re-run anywhere.
