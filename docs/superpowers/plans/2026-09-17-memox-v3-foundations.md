# MemoX v3 foundations implementation plan

| | |
|---|---|
| **Status** | historical — the record of how the branch was executed; current values live in `docs/design-system/v3-foundations.md` |
| **Purpose** | Turn the owner's v3 foundations handoff into eleven reviewable tasks, each with the exact values it must hit |
| **Scope** | The global visual system only: palette, text inks, shadows, type, ladders, gutter and scroll tail. Component geometry, variants and surface treatments are out (ruling R1) |
| **Source of truth for** | The task breakdown and the rulings R1–R13 made before execution |
| **Depends on** | `docs/superpowers/specs/2026-09-17-memox-v3-foundations.md`, `docs/design-system/v3-foundations.md` |
| **Updated by task** | M100.97 |
| **Last updated** | 2026-09-18 |

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Put the app's global visual system on the MemoX v3 foundations — both palettes, the text inks, one type family and its seven roles, the spacing / radius / icon / state-layer ladders, the shadow recipe, and the 16 gutter with a 48 scroll tail — without touching any component's geometry, variant or surface treatment.

**Architecture:** Foundations are tokens plus the global theme. A component theme keeps the *role* it binds today and picks up the v3 value of that role automatically; the one exception is text, because owner answer A1 makes "text that fails AA reads an ink" a global rule rather than a component choice. Everything a later component spec owns (card fill, FAB fill, nav indicator, chip fill, switch track, radii and heights per component) is left exactly where it is.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12.2, Material 3 `ThemeData`, `ThemeExtension`, `flutter_test`, Python guard (`code-verification-guard-v2`).

**Spec:** `docs/superpowers/specs/2026-09-17-memox-v3-foundations.md` — the owner's handoff verbatim plus answers A1 (text inks) and A2 (keep `info`). The spec outranks this plan.

**Baseline** (`ce620c24`, this worktree, before Task 1): `flutter analyze` → `No issues found!`; `flutter test --exclude-tags golden` → `+5010: All tests passed!`.

---

## Global Constraints

These bind every task. Reviewers check diffs against them verbatim.

### GC-1 · The 45 `ColorScheme` roles (light / dark)

| Role | Light | Dark | Dart constant(s) the scheme reads |
|---|---|---|---|
| primary | `#5265F5` | `#8B9AFF` | `AppColors.primaryLight/Dark` |
| onPrimary | `#FFFFFF` | `#11173A` | `AppColors.onPrimaryLight/Dark` |
| primaryContainer | `#E0E5FE` | `#2D346A` | `AppMaterialRoles.primaryContainerLight/Dark` |
| onPrimaryContainer | `#1A2580` | `#D9DFFF` | `AppMaterialRoles.onPrimaryContainerLight/Dark` |
| secondary | `#6E7CD9` | `#9DA8E8` | `AppMaterialRoles.secondaryLight/Dark` |
| onSecondary | `#FFFFFF` | `#1A2150` | `AppMaterialRoles.onSecondaryLight/Dark` |
| secondaryContainer | `#E3E6F7` | `#343C78` | `AppMaterialRoles.secondaryContainerLight/Dark` |
| onSecondaryContainer | `#262E6E` | `#DDE2FB` | `AppMaterialRoles.onSecondaryContainerLight/Dark` |
| tertiary | `#8B6FF5` | `#B5A0FF` | `AppMaterialRoles.tertiaryLight/Dark` |
| onTertiary | `#FFFFFF` | `#240B63` | `AppMaterialRoles.onTertiaryLight/Dark` |
| tertiaryContainer | `#EBE3FE` | `#443078` | `AppMaterialRoles.tertiaryContainerLight/Dark` |
| onTertiaryContainer | `#33177E` | `#E6DCFF` | `AppMaterialRoles.onTertiaryContainerLight/Dark` |
| error | `#DC2D4E` | `#FF8FA3` | `AppColors.dangerLight/Dark` |
| onError | `#FFFFFF` | `#52061B` | `AppMaterialRoles.onErrorLight/Dark` |
| errorContainer | `#FBDDE3` | `#7A2036` | `AppMaterialRoles.errorContainerLight/Dark` |
| onErrorContainer | `#7A0A23` | `#FFD9DF` | `AppMaterialRoles.onErrorContainerLight/Dark` |
| surface | `#F7F9FE` | `#0A0E27` | `AppSurfaceColors.pageLight/Dark` |
| onSurface | `#0F1638` | `#E4E8FA` | `AppColors.textPrimaryLight/Dark` |
| onSurfaceVariant | `#4A5278` | `#A4ACD0` | `AppColors.textSecondaryLight/Dark` |
| surfaceDim | `#DAE0EF` | `#060925` | `AppMaterialRoles.surfaceDimLight/Dark` |
| surfaceBright | `#FFFFFF` | `#232B5A` | `AppMaterialRoles.surfaceBrightLight/Dark` |
| surfaceContainerLowest | `#FFFFFF` | `#131A3A` | `AppMaterialRoles.surfaceContainerLowestLight/Dark` |
| surfaceContainerLow | `#F1F4FB` | `#1B2249` | `AppMaterialRoles.surfaceContainerLowLight/Dark` |
| surfaceContainer | `#E9EDF7` | `#232B5A` | `AppMaterialRoles.surfaceContainerLight/Dark` |
| surfaceContainerHigh | `#E2E7F3` | `#2C356E` | `AppMaterialRoles.surfaceContainerHighLight/Dark` |
| surfaceContainerHighest | `#DAE0EF` | `#353D7E` | `AppMaterialRoles.surfaceContainerHighestLight/Dark` |
| outline | `#7C85AB` | `#5A6BAE` | `AppBorderColors.borderControlLight/Dark` |
| outlineVariant | `#C5CBE3` | `#2A3267` | `AppBorderColors.borderSubtleLight/Dark` |
| inverseSurface | `#34395D` | `#34395D` | `AppMaterialRoles.inverseSurfaceLight/Dark` |
| onInverseSurface | `#E8EAFC` | `#E8EAFC` | `AppMaterialRoles.onInverseSurfaceLight/Dark` |
| inversePrimary | `#8B9AFF` | `#5265F5` | `AppMaterialRoles.inversePrimaryLight/Dark` |
| shadow | `#0F1638` | `#000000` | `AppColors.shadowLight/Dark` |
| scrim | `#0A0E27` | `#000000` | `AppColors.scrimLight/Dark` |

The twelve `*Fixed` roles are theme-invariant and take the values `colors_and_type.css` declares (lines 128–141), not generated tones:

| Role | Value | Role | Value |
|---|---|---|---|
| primaryFixed | `#E0E5FE` | secondaryFixedDim | `#C8CEF0` |
| primaryFixedDim | `#C2CBFD` | onSecondaryFixed | `#131A4E` |
| onPrimaryFixed | `#0B1252` | onSecondaryFixedVariant | `#4453A8` |
| onPrimaryFixedVariant | `#2B3AB8` | tertiaryFixed | `#EBE3FE` |
| secondaryFixed | `#E3E6F7` | tertiaryFixedDim | `#D7C8FD` |
| onTertiaryFixed | `#1D0A57` | onTertiaryFixedVariant | `#6A4AD4` |

### GC-2 · Legacy semantic tokens on the v3 palette

The existing `AppSemanticColors` API keeps every field; only values move. **All 45 roles in GC-1 are literals; a legacy token derives from a role, never the reverse, and no import cycle is introduced.**

| Token (light / dark) | Value | Derivation |
|---|---|---|
| `AppColors.disabledSurface` | `#DBDEE6` / `#242840` | `onSurface` at 12% flattened over `surface` |
| `AppColors.onDisabled` | `0x610F1638` / `0x61E4E8FA` | `onSurface` at 38% (v3 disabled 0.38) |
| `AppColors.success` | `#2BA88B` / `#6FE0BD` | v3 `success` |
| `AppColors.warning` | `#F59E0B` / `#FFC658` | v3 `warning` |
| `AppColors.danger` | `#DC2D4E` / `#FF8FA3` | v3 `error` (feeds `ColorScheme.error`) |
| `AppColors.info`, `infoContainer`, `onInfoContainer` | **unchanged** | owner answer A2 |
| `AppColors.successContainer` | `#EAF6F3` / `#243E52` | v3 `success-soft` (10% / 18%) flattened over `surfaceContainerLowest` |
| `AppColors.onSuccessContainer` | `#1E7460` / `#6FE0BD` | = `successInk` (5.10 / 6.93 on the container) |
| `AppColors.warningContainer` | `#FEF3E2` / `#3D393F` | v3 `warning-soft` (12% / 18%) flattened over `surfaceContainerLowest` |
| `AppColors.onWarningContainer` | `#3A2A00` / `#FFC658` | = `warningInk` |
| `AppColors.streakContainer` / `onStreakContainer` | = `warningContainer` / `onWarningContainer` | the due chip is the time-pressure family; v3 paints overdue counts in `warning ink` |
| `AppColors.progressTrack` | `#E2E7F3` / `#2C356E` | v3 `progress-track` = `surfaceContainerHigh` |
| `AppColors.progressFill` | `#5265F5` / `#8B9AFF` | = `primary` |
| `AppColors.webLetterbox` | **unchanged** | outside the app surface |
| `AppSurfaceColors.paper` | `#F1F4FB` / `#1B2249` | = `surfaceContainerLow` (the role the card theme binds today) |
| `AppSurfaceColors.surfaceEmphasis` | `#F6F7FE` / `#191F41` | v3 `surface-hero`: `primary` 5% over `#FFFFFF` / 12% over `#0A0E27` |
| `AppSurfaceColors.surfaceSelected` | `#E0E5FE` / `#2D346A` | = `primaryContainer` ("selected chip, soft emphasis") |
| `AppSurfaceColors.surfaceMuted` | `#E9EDF7` / `#232B5A` | = `surfaceContainer` |
| `AppSurfaceColors.surfaceElevated` | `#FFFFFF` / `#232B5A` | = `surfaceBright` |
| `AppBorderColors.borderSubtle` | `#C5CBE3` / `#2A3267` | = `outlineVariant` |
| `AppBorderColors.borderControl` | `#7C85AB` / `#5A6BAE` | = `outline` |
| `AppBorderColors.borderSelected` | `#5265F5` / `#8B9AFF` | = `primary` |
| `AppBorderColors.borderOption` | `#7C85AB` / `#5A6BAE` | = `outline` |
| `AppBorderColors.borderAccent` | `#D5DAFD` / `#394379` | v3 `primary-border` (24% / 32%) flattened over `surfaceContainerLowest` |

### GC-3 · Text inks (owner answer A1)

Solved by holding the fill's HSL hue and saturation and moving lightness to the first value that reads **≥ 4.5:1 on all five text grounds** of its mode — light `#F7F9FE #FFFFFF #F1F4FB #E9EDF7 #E2E7F3`, dark `#0A0E27 #131A3A #1B2249 #232B5A #2C356E`. Measured minimum in brackets.

| Ink on `AppSemanticColors` | Light | Dark |
|---|---|---|
| `accentInk` (from `primary`) | `#3E53F4` (4.52) | `#8D9CFF` (4.52) |
| `dangerInk` (from `error`) | `#C82141` (4.52) | `#FF8FA3` = fill (5.27) |
| `successInk` (from `success`) | `#1E7460` (4.56) | `#6FE0BD` = fill (7.10) |
| `warningInk` | `#3A2A00` = v3 `on-warning` (11.22) | `#FFC658` = fill (7.32) |
| `secondaryInk` (from `secondary`) | `#4B5CD0` (4.53) | `#9DA8E8` = fill (5.00) |
| `tertiaryInk` (from `tertiary`) | `#6945F2` (4.54) | `#B5A0FF` = fill (5.12) |
| `inversePrimaryInk` (invariant, on `#34395D`) | `#919FFF` (4.56) | `#919FFF` (4.56) |

`AppInk.resolve`: `accent → accentInk`, `success → successInk`, `warning → warningInk`, `danger`, `error` and `overdue → dangerInk`, `secondary → secondaryInk`, `tertiary → tertiaryInk`. `stated`, `quiet`, `info`, `disabled` and every `on*` member are unchanged.

### GC-4 · Type

One family: `PlusJakartaSans` (bundled, variable). `Inter` leaves the bundle, `pubspec.yaml`, the licence page, the test font loader and Widgetbook. `NotoSansKR` stays the CJK fallback on every style. Weight is always set through `fontWeight` **and** the `wght` axis (`AppTypography.withWeight`).

| v3 role | Size | Weight | Height | Tracking |
|---|---:|---:|---:|---:|
| caption | 12 | 600 | 1.4 | 1.2 |
| body | 14 | 400 | 1.5 | 0 |
| body large | 16 | 500 | 1.5 | 0 |
| title | 20 | 700 | 1.2 | −0.64 |
| headline | 24 | 700 | 1.2 | −0.64 |
| display | 32 | 800 | 1.1 | −0.64 |
| stat | 40 | 600 | 1.0 | −0.64 |

The fifteen `TextTheme` slots (ruling R5):

| Slot(s) | Resolves to |
|---|---|
| `displayLarge`, `displayMedium` | stat — 40 / 600 / 1.0 / −0.64 |
| `displaySmall`, `headlineLarge` | display — 32 / 800 / 1.1 / −0.64 |
| `headlineMedium`, `headlineSmall` | headline — 24 / 700 / 1.2 / −0.64 |
| `titleLarge` | title — 20 / 700 / 1.2 / −0.64 |
| `titleMedium`, `bodyLarge` | body large — 16 / 500 / 1.5 / 0 |
| `titleSmall`, `labelLarge` | 14 / 600 / 1.5 / 0 (body size at semibold, derived) |
| `bodyMedium` | body — 14 / 400 / 1.5 / 0 |
| `bodySmall` | 12 / 400 / 1.4 / 0 (caption size at body weight, derived) |
| `labelMedium` | 12 / 600 / 1.4 / 0.72 (caption at CSS `--memox-ls-label`, derived) |
| `labelSmall` | caption — 12 / 600 / 1.4 / 1.2 |

Named styles: `sectionLabelTracking` = **1.2** (CSS `--memox-ls-section`); `stateChipTracking` 0.6 and `listHeadingTracking` 0.72 unchanged; `heroNumeral` = the stat rung (`displayLarge`) + tabular figures + `heroNumeralCapTrim` (0.481, unchanged), and `heroNumeralWeight` is deleted (ruling R6); `cardPrompt` keeps 30 / 1.22 / −0.5 / w600 and its compact 26 (ruling R6). The weight set the theme can reach is exactly `{400, 500, 600, 700, 800}`.

### GC-5 · Ladders and state layers

| Token | Value(s) |
|---|---|
| `AppSpacing` | `xs 4 · sm 8 · md 12 · lg 16 · card 20 · xl 24 · xxl 32 · xxxl 48`; `scale` lists all eight in that order |
| `AppRadius` | `xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · pill 999` (no 28 — no v3 call site) |
| `AppIconSize` | `sm 16 · mdCompact 20 · md 24 · lg 32 · xl 40` — today's `lg` (40) is renamed `xl`; `lg` is the new 32. `MxIconSize` mirrors it |
| `AppSizing.touchTarget` | 48, unchanged |
| `AppStateOpacity` hover | `hoverRow`, `hoverIcon`, `hoverControl`, `hoverCard`, `stateLayerHover` = **0.08** |
| `AppStateOpacity` pressed | `pressed`, `pressedCard`, `stateLayerPressed` = **0.12** |
| `AppStateOpacity` focus | `focus`, `stateLayerFocus` unchanged at 0.10 (spec silent) |

### GC-6 · Shadows (owner decision 6, 2026-09-13, on v3 values)

`AppElevation` keeps its four levels (`none 0 · card 1 · raised 3 · overlay 8`) and `materialShadowColor` is unchanged. `shadowsFor(level, scheme)`:

| Level | Light (colour = `scheme.shadow` `#0F1638`) | Dark (colour = `scheme.shadow` `#000000`) |
|---|---|---|
| `card` | `0 1 2` at 4% (v3 `shadow-soft`) | rim only: `BoxShadow(color: outlineVariant, spreadRadius: AppStroke.hairline)` |
| `raised` | `0 12 32` at 10% (v3 `shadow-card`) | rim + `0 16 40` at 42% |
| `overlay` | `0 8 24` at 12% (v3 `shadow-fab`) | rim + `0 10 28` at 50% |

Written as `offsetY blurRadius` at alpha; no spread on a drop; one light layer per level. The v3 `Chrome` shadow is not declared (ruling R9).

### GC-7 · Composition

- `mxScreenGutter(context)` returns `AppSpacing.lg` (16) at every width.
- `mxScrollEndInsetOf(context)` returns `AppSpacing.xxxl` (48) without a floating action, and `AppSpacing.fabScrollClearance + MediaQuery.viewPaddingOf(context).bottom` with one, where `fabScrollClearance = AppSizing.floatingAction + AppSpacing.lg + AppSpacing.xxxl`.
- `applyCompactScale` no longer overrides `listTileTheme.contentPadding` or `titleLarge`; it keeps the compact card prompt and the compact button padding.

### GC-8 · House rules every task obeys

- No magic values: every value lives in a token file, named. No hex literal outside `lib/core/theme/foundations/`.
- A doc comment on a changed token says, in at most four lines, where the value comes from (CSS variable or derivation) and nothing that is no longer true. Delete measurement history the new value falsifies; git keeps it.
- No file under `lib/` or `test/` above 400 counted lines (the guard runs `warning_as_error`).
- Never delete, `skip`, or comment out a test to go green. A value pin that the spec moves is updated in place with the new value.
- A `/* TODO(M100.84) … (TOKYO-2) */` block is only re-enabled by Tasks 8 and 9.
- `dart format` clean; `flutter analyze` repo-wide prints `No issues found!` (read the summary line, never grep).
- Running tests rewrites `design_audit/*`. Restore it (`git checkout -- design_audit/`) before committing, except in Task 10.
- Commits: Conventional Commits, scope `theme` / `design-system`, ending with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

---

## Rulings made before execution

The spec is silent or ambiguous on each of these. Each is recorded with what it costs if wrong.

| ID | Ruling | Why | Cost if wrong |
|---|---|---|---|
| R1 | Component surface, fill, radius and height bindings do not move (card stays on `surfaceContainerLow`, FAB on `primaryContainer`, nav indicator on `secondaryContainer`, chip on `surfaceContainerLow`/`secondaryContainer`, switch track on `surfaceContainerHighest`). | The spec says foundations do not own component variants, and P1 puts "surface treatment, radius, geometry class" in each component spec. | Until the Card spec lands, a light card is `#F1F4FB` on a `#F7F9FE` page — a hairline-edged panel a shade *below* the page. |
| R2 | The twelve `*Fixed` roles take the CSS literals. | The CSS declares them; generating tones would invent values. | Twelve literals to re-point. |
| R3 | Text-slot bindings **do** move onto inks (Task 3). | A1 is a rule about text, not about a component. | Revert Task 3's slot rows. |
| R4 | No `masteryInk` (mastery as text reads `successInk`), no `infoInk` (A2 keeps `info`; it reads 5.17 on the page), one red ink for `danger`, `error` and `overdue`. | Mastery and success share one green family; `info` is kept as shipped. | One ink to add later. |
| R5 | The `TextTheme` slot table in GC-4 (the 2026-09-13 D1 table). | The CSS maps seven sizes to eleven slots; the remaining four take the nearest role by size, and the two derived pairings keep the weight M3 gives those slots. | Slot rows re-pointed, goldens re-authored. |
| R6 | `heroNumeral` becomes the stat role (the spec names stat "Large metric, tabular numerals"); `cardPrompt` keeps its own metrics until the flashcard spec. | Hero numeral *is* the large metric; the card prompt is a component style. | Library hero 32 → 40 is visible on one screen. |
| R7 | New v3 colours with no caller today (`mastery`, `status*`, `streak`, `on-streak`, `on-warning` as a fill ink, `error-fill`, `on-error-fill`, `mastery-fixed`, the `*-soft` / `*-border` alphas, `chrome-glass`, text-muted ink) are **documented, not declared in Dart** (Task 10's mapping table). Each lands with its first caller. | The repo refuses colours nobody renders ("a colour with no caller is a colour nobody is checking", `app_colors.dart`), and the spec asks to resolve aliases to existing roles rather than invent tokens. | Each component spec adds one or two constants. |
| R8 | Radius and spacing ladders grow without renames; the icon ladder renames only `lg → xl` (5 call sites) to make room for 32. | Smallest diff that holds every v3 value in order. | Names differ from the CSS (`radius-xl` is 24 in CSS, 20 here); Task 10 documents the map. |
| R9 | No `chrome` shadow level and no glass constant. | No caller; the bottom-nav spec owns them. | One level added with the nav spec. |
| R10 | Focus state-layer alphas stay at 0.10. | The spec lists hover, pressed, disabled and glass only. | Two constants. |
| R11 | Dark Material components keep casting no shadow (`materialShadowColor` unchanged). | Component-level; decision 6 governs `shadowsFor`, which the app's own surfaces use. | A dialog/FAB spec flips it. |
| R12 | Contrast gates return in Tasks 8–9: text must clear 4.5:1 through its ink; a non-text edge, dot, fill or track the v3 hex puts under 3:1 is pinned at its measured figure (owner decision 5). | M100.84 switched them off for exactly this palette swap. | Floors re-pinned when a component spec re-binds. |
| R13 | The WBS id is chosen immediately before push (`git log --all` census), placeholder `M100.97`. | Parallel PRs take numbers. | A rename commit. |

---

## Shared commands

```bash
# repo root: D:/workspace/memox-v7/.claude/worktrees/chip-flutter-design-spec-fd5cea
dart format --output=none --set-exit-if-changed lib test integration_test widgetbook/lib
flutter analyze                                   # summary line must be "No issues found!"
flutter test <paths>                              # the task's targeted set
git checkout -- design_audit/                     # after any test run, except Task 10
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
```

Reference commits (read-only, for *how* the reverted 2026-09-13 redesign did a similar edit — this plan's values and rulings win on every conflict):

- `dcd22f32` — Tokyo palette, text inks and depth (M100.87)
- `42d8c3b4` — one family, token ladders, 16 gutter (M100.89)
- `origin/codex/backup-main-before-reset-20260915-233610` — the tree those commits produced

---

### Task 1: The v3 palette — 45 roles and the legacy semantic values

**Files:**
- Modify: `lib/core/theme/foundations/app_colors.dart`
- Modify: `lib/core/theme/foundations/app_material_roles.dart`
- Modify: `lib/core/theme/foundations/app_surface_colors.dart`
- Modify: `lib/core/theme/foundations/app_border_colors.dart`
- Modify only if a constant name changes: `lib/core/theme/schemes/app_color_scheme.dart`
- Test: `test/core/theme/schemes/color_scheme_roles_test.dart`, `test/core/theme/foundations/app_palette_test.dart`, and any other active assertion under `test/core/theme/` that pins a value from these four files

- [ ] **Step 1:** Set every constant in GC-1 and GC-2 to its value. Make the 45 roles literals; turn every legacy token in GC-2 marked "=" into a derivation from its role constant (e.g. `static const Color surfaceMutedLight = AppMaterialRoles.surfaceContainerLight;`). Remove `AppMaterialRoles`' dependency on `AppSurfaceColors` if a derivation now runs the other way; no import cycle.
- [ ] **Step 2:** Rewrite the class headers and every changed constant's doc comment per GC-8: name the v3 source (`colors_and_type.css`, 2026-09-17) or the derivation; delete history the new value falsifies (Tokyo re-hueing, A2, M100.2x measurements). Keep `info*` and `webLetterbox` docs as they are.
- [ ] **Step 3:** `flutter analyze` → `No issues found!`
- [ ] **Step 4:** `flutter test test/core/theme` — update every *active* assertion that fails because it pins an old value or a relation the v3 palette deliberately breaks (hue budgets, L\* steps, seed traces): new value in place, one-line reason citing the spec. Do not open `TODO(M100.84)` blocks.
- [ ] **Step 5:** `flutter test test/core/theme` green; list in the report any failure *outside* `test/core/theme` you noticed, without fixing it.
- [ ] **Step 6:** format, restore `design_audit/`, guard, commit `feat(theme): v3 palette for the 45 roles and the legacy semantics`.

**Out of scope:** inks (Task 2), component bindings (R1), shadows (Task 4).

### Task 2: Text inks on `AppSemanticColors` and `AppInk`

**Files:**
- Modify: `lib/core/theme/foundations/app_colors.dart` (ink constants)
- Modify: `lib/core/theme/foundations/app_semantic_colors.dart` (seven ink fields: constructor, `light()`, `dark()`, field, `copyWith`, `lerp`)
- Modify: `lib/core/theme/schemes/app_high_contrast.dart` only if it constructs `AppSemanticColors` field by field
- Modify: `lib/core/theme/extensions/app_ink.dart`
- Test: `test/core/theme/extensions/app_ink_test.dart`, `test/core/theme/foundations/app_semantic_colors_test.dart`, `test/core/theme/extensions/theme_context_extension_test.dart`

- [ ] **Step 1:** Add the GC-3 constants to `AppColors` (`accentInkLight/Dark`, `dangerInkLight/Dark`, `successInkLight/Dark`, `warningInkLight/Dark`, `secondaryInkLight/Dark`, `tertiaryInkLight/Dark`, `inversePrimaryInk`). A dark ink equal to its fill is written as a derivation of the fill constant. Point `onSuccessContainer*`, `onWarningContainer*`, `onStreakContainer*` at the inks as GC-2 states.
- [ ] **Step 2:** Add the seven fields to `AppSemanticColors` in every place a field appears. Keep the file ≤ 400 counted lines by shortening existing doc comments, not by dropping behaviour.
- [ ] **Step 3:** Re-map `AppInk.resolve` exactly as GC-3 states; update the enum member docs that name a colour.
- [ ] **Step 4:** Tests: every new field is covered by the existing `copyWith`/`lerp` completeness tests; add one test that each ink reads ≥ 4.5:1 on the five grounds of its mode (GC-3) and `inversePrimaryInk` on `inverseSurface` — this is a new active test, not an M100.84 block.
- [ ] **Step 5:** `flutter analyze`; `flutter test test/core/theme` green.
- [ ] **Step 6:** format, restore, guard, commit `feat(theme): text inks for the v3 hexes that fail AA`.

### Task 3: Text slots read the inks

**Rule:** a slot or paint call that colours **text** (or a glyph standing in for a word: an error suffix icon, a warning flag glyph) with `primary`, `error`, `success`, `warning`, `secondary`, `tertiary` or `inversePrimary` reads the GC-3 ink instead. Fills, borders, indicators, tracks, carets, focus rings, radio/switch/checkbox marks and decorative icons keep the fill role.

**Files (inventory to verify, not a limit):**
- `lib/core/theme/components/actions/app_button_themes.dart` — TextButton label/accent, OutlinedButton foreground → `accentInk`
- `lib/core/theme/components/navigation/app_tab_bar_theme.dart` — label colour → `accentInk`
- `lib/core/theme/components/feedback/app_snackbar_theme.dart` — action text → `inversePrimaryInk`
- `lib/core/theme/components/inputs/app_input_theme.dart` — error text, error suffix icon → `dangerInk`
- `lib/core/theme/components/content/app_list_tile_theme.dart` — any text colour on the listed roles
- `lib/shared/widgets/mx_text_button.dart`, `mx_action_button.dart`, `mx_icon_button.dart` (warning glyph tone → `warningInk`)
- `lib/features/card/presentation/widgets/items/card_history_event_widget.dart`, `card_tile_widget.dart`, `lib/features/card/presentation/widgets/support/card_action_tone_widget.dart`
- Test ledger: `test/core/theme/contracts/m3_role_bindings.dart`, `m3_role_bindings_inputs.dart`, `m3_role_binding_guard_test.dart` (add `requiresSemantic` support if absent, as `dcd22f32` did)

- [ ] **Step 1:** Read `git show dcd22f32 -- <each file above>` and `git show dcd22f32 -- test/core/theme/contracts/`. Port **only** hunks that move text or word-glyph colour onto an ink. Do not port card fill, surface, shadow, FAB, chip or high-contrast hunks (R1).
- [ ] **Step 2:** Find the rest: `grep -rnE "(colors|scheme|context\.colors)\.(primary|error|secondary|tertiary|inversePrimary)\b|semantic(Colors)?\.(success|warning|danger|overdue)\b" lib/shared lib/features lib/core/theme/components` and classify each hit as text or graphic under the rule. Move the text ones; list every hit and its class in the report.
- [ ] **Step 3:** Ledger rows for each moved slot: `requires: []`, `requiresSemantic: ['<ink>']`, `refuses` gains the fill role, `because` names answer A1.
- [ ] **Step 4:** `flutter analyze`; `flutter test test/core/theme test/shared/widgets` plus the test files of every feature widget you changed.
- [ ] **Step 5:** format, restore, guard, commit `feat(design-system): text reads the v3 inks (A1)`.

### Task 4: v3 shadows

**Files:**
- Modify: `lib/core/theme/foundations/app_elevation.dart`
- Test: `test/core/theme/foundations/app_elevation_test.dart`, `test/core/theme/components/component_depth_and_state_test.dart` (active assertions only)

- [ ] **Step 1:** Replace `_lightShadows`, `_darkDepth` and the three alpha constants with one private enum of the three GC-6 shadows (`soft`, `card`, `floating`), each carrying its light and dark offset, blur and alpha, and a `paint` method. `shadowsFor` maps `card → soft`, `raised → card`, `overlay → floating`; dark prepends the rim and paints no drop at `card`. The backup tree's `app_elevation.dart` is a faithful shape to follow.
- [ ] **Step 2:** Doc comments per GC-8 — cite the CSS variables and owner decision 6.
- [ ] **Step 3:** Update active value pins in the two tests; `flutter test test/core/theme` green.
- [ ] **Step 4:** format, restore, guard, commit `feat(theme): v3 shadow tiers`.

### Task 5: One family and the seven type roles

**Files:**
- Modify: `lib/core/theme/typography/app_typography.dart`, `lib/core/theme/typography/app_text_styles.dart`, `lib/core/theme/app_theme.dart` (`fontFamily`), `lib/core/theme/schemes/app_compact_scale.dart` (drop the `titleLarge` override only), `lib/core/theme/schemes/app_bold_text.dart` (only if it names the body family or a removed constant)
- Delete: `assets/fonts/Inter-Variable.ttf`, `assets/fonts/OFL-Inter.txt`
- Modify: `pubspec.yaml` (remove the `Inter` family), `lib/app/startup/font_licenses.dart`, `test/flutter_test_config.dart`, `widgetbook/pubspec.yaml` and any Widgetbook file naming Inter
- Modify: `integration_test/it_platform_test.dart` — IT-PLAT-009 also probes IPA letters (`ɪ` U+026A, `ˈ` U+02C8) through the platform fallback, as `42d8c3b4` did; respell any golden specimen string that contains IPA so no host picture records a missing glyph
- Test: `test/core/theme/typography/*`, `test/core/theme/components/component_theme_typography_test.dart`, `test/core/theme/schemes/compact_scale_test.dart`, `test/core/theme/schemes/app_bold_text*_test.dart`, `test/features/settings/presentation/settings_licenses_test.dart`, `test/features/deck/presentation/deck_list_rhythm_golden_test.dart` (compile only; it is golden-tagged)

- [ ] **Step 1:** `AppTypography`: one `family` constant (`'PlusJakartaSans'`) replacing `displayFamily`/`bodyFamily` at every reader; the GC-4 role constants (size, height, tracking per role, `headingTracking = -0.64`, `labelTracking = 0.72`, `sectionLabelTracking = 1.2`); `buildTextTheme` fills the fifteen slots from the GC-4 table through one private helper that sets family, fallback, weight + `wght` axis, size, height and tracking. Delete `heroNumeralWeight`.
- [ ] **Step 2:** `AppTextStyles.from`: `heroNumeral` reads `displayLarge` (stat) with tabular figures and `heroNumeralCapTrim`; `cardPrompt` keeps its constants; other named styles unchanged beyond what their base rung and `sectionLabelTracking` now give.
- [ ] **Step 3:** Remove Inter from the bundle, licences, test font loader and Widgetbook. Update the IT probe and specimen as listed.
- [ ] **Step 4:** Tests: the weight registry expects `{w400, w500, w600, w700, w800}`; every `w700`/`w800` source it enumerates is named from the GC-4 table (`displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, plus the component themes that already re-weight to 700); only `app_typography.dart` may spell `FontWeight.w800`. Slot metrics assert the GC-4 table. The assertion that the hero numeral is heavier than the rung it overrides becomes "the hero numeral is the stat rung (`displayLarge`) with tabular figures and the cap trim" (R6). `flutter test` on the listed files green.
- [ ] **Step 5:** `flutter pub get` (root and `widgetbook/`), `flutter analyze`, format, restore, guard, commit `feat(theme): one family and the v3 type roles`.

### Task 6: Spacing, radius, icon and state-layer ladders

**Files:**
- Modify: `lib/core/theme/foundations/app_spacing.dart` (add `card = 20`, `xxxl = 48`, extend `scale`; leave `fabScrollClearance` for Task 7)
- Modify: `lib/core/theme/foundations/app_radius.dart` (add `xs = 4`, `xxl = 24`)
- Modify: `lib/core/theme/foundations/app_icon_size.dart` (rename `lg` → `xl` = 40, add `lg = 32`) and the `MxIconSize` enum (grep `enum MxIconSize`) the same way
- Modify: every caller of `AppIconSize.lg` (3) and `MxIconSize.lg` (2) → `.xl`
- Modify: `lib/core/theme/states/app_interaction_states.dart` (GC-5 alphas)
- Test: `test/core/theme/foundations/design_tokens_test.dart`, `spacing_is_a_gap_test.dart`, `glyph_register_test.dart`, `app_sizing_test.dart`, `test/core/theme/states/app_interaction_states_test.dart`, `test/shared/widgets/` tests naming `MxIconSize`

- [ ] **Step 1:** Before renaming, record `grep -rn "AppIconSize\.lg\b\|MxIconSize\.lg\b" lib test widgetbook` and rename exactly those sites to `.xl` in the same commit as the new `lg`; afterwards the same grep for `.lg` must return only sites you intend to be 32 (there should be none).
- [ ] **Step 2:** Doc comments give each rung its v3 role from the spec's Spacing, Radius and Icons tables.
- [ ] **Step 3:** State alphas per GC-5; update value pins in `app_interaction_states_test.dart`.
- [ ] **Step 4:** `flutter analyze`; `flutter test test/core/theme test/shared/widgets` green.
- [ ] **Step 5:** format, restore, guard, commit `feat(theme): v3 spacing, radius, icon and state-layer ladders`.

### Task 7: Composition — the 16 gutter and the 48 tail

**Files:**
- Modify: `lib/shared/widgets/mx_content_shell.dart` (`mxScreenGutter`)
- Modify: `lib/shared/widgets/mx_scroll_end_inset.dart` (`mxScrollEndInsetOf`)
- Modify: `lib/core/theme/foundations/app_spacing.dart` (`fabScrollClearance`)
- Modify: `lib/core/theme/schemes/app_compact_scale.dart` (remove the `listTileTheme.contentPadding` override)
- Test: every test that pins a gutter of 12 at compact width, a scroll tail of 16, or the old clearance — find with `grep -rnE "mxScreenGutter|mxScrollEndInset|fabScrollClearance|isCompact" test`

- [ ] **Step 1:** Apply GC-7. Doc comments say 16 at every width (spec: "Compact phone … gutter stays 16") and 48 above pinned chrome.
- [ ] **Step 2:** `grep -rn "isCompact" lib/shared lib/features` — for each site that steps a **screen gutter or list-row inset** down to 12 at compact width, make it 16; leave component paddings (buttons, chips, tiles' internal gaps) alone. List every site and its class in the report.
- [ ] **Step 3:** Update geometry pins; `flutter analyze`; run the tests the grep found plus `test/shared/widgets` green.
- [ ] **Step 4:** format, restore, guard, commit `feat(design-system): 16 gutter at every width and a 48 scroll tail`.

### Task 8: Contrast gates return — theme contracts

**Files:** the seventeen files under `test/core/theme/` that contain `TODO(M100.84)`:
`app_theme_test.dart`, `components/app_date_picker_theme_test.dart`, `components/app_overlay_themes_test.dart`, `components/app_time_picker_theme_test.dart`, `components/app_toggle_themes_test.dart`, `components/app_unrendered_component_themes_test.dart`, `components/component_depth_and_state_test.dart`, `contracts/border_ladder_test.dart`, `contracts/control_border_grounds_test.dart`, `contracts/focus_ring_contrast_test.dart`, `extensions/app_ink_test.dart`, `foundations/app_elevation_test.dart`, `foundations/app_palette_test.dart`, `foundations/app_semantic_colors_test.dart`, `schemes/app_high_contrast_test.dart`, `schemes/color_scheme_roles_test.dart`, `schemes/high_contrast_figures_test.dart`

- [ ] **Step 1:** In each file remove the `/* … */` wrapper and its `TODO(M100.84) … (TOKYO-2)` line so the original body runs.
- [ ] **Step 2:** Run the file. For each failing assertion apply R12: a **text** pair must reach 4.5:1 — if it does not, the slot is still on a fill; fix the binding (Task 3's rule) rather than the number. A **non-text** pair the v3 hex puts under its floor gets the measured figure, floored to two decimals, as the new floor, with a one-line comment `v3 hex kept under 3:1 — owner decision 5 (2026-09-13)`. An assertion whose premise was a value the spec replaced gets the v3 value. A relation a coherent palette satisfies must pass unchanged.
- [ ] **Step 3:** `grep -rn "TODO(M100.84)" test/core/theme` returns nothing; `flutter test test/core/theme` green.
- [ ] **Step 4:** List every floor you pinned (file, pair, figure) in the report.
- [ ] **Step 5:** format, restore, guard, commit `test(theme): contrast gates return on the v3 palette (theme contracts)`.

### Task 9: Contrast gates return — features and shared, and the suite fallout

**Files:** the nine remaining `TODO(M100.84)` files — `test/features/card/presentation/card_detail_timeline_style_test.dart`, `test/features/deck/presentation/deck_icon_area_test.dart`, `test/features/deck/presentation/deck_workload_role_test.dart`, `test/features/progress/presentation/progress_chart_contrast_test.dart`, `test/features/settings/presentation/settings_accessibility_test.dart`, `test/features/study/presentation/study_accessibility_test.dart`, `test/shared/widgets/mx_action_button_composite_state_test.dart`, `test/shared/widgets/mx_action_button_state_matrix_test.dart`, `test/shared/widgets/mx_pressable_test.dart` — plus the host-suite failure list the controller attaches to the dispatch.

- [ ] **Step 1:** Re-enable the nine files exactly as Task 8 Steps 1–2.
- [ ] **Step 2:** For each failure on the attached list: if it pins a value the spec moved (a colour, size, gutter, weight, tail), update the pin in place and name the GC row in a comment only where the reason is not obvious; if it reveals a behaviour change (a control no longer reachable, text clipped, overflow), fix the **production** cause inside this plan's scope and report it; never loosen a behavioural assertion.
- [ ] **Step 3:** `grep -rn "TODO(M100.84)" test lib` returns nothing; every file on the list and the nine files pass.
- [ ] **Step 4:** format, restore, guard, commit `test(design-system): contrast gates and pins follow the v3 foundations`.

### Task 10: Documents, WBS and the audit record

**Files:**
- Create: `docs/design-system/v3-foundations.md` — header per `docs/document-conventions.md`; sections: (1) token map, spec value → Dart symbol, for GC-1…GC-7; (2) the alias table from the spec with each alias resolved to a Dart expression (`surface-raised` → `scheme.surfaceContainerLowest`, `primary-soft` → `scheme.primary` at 0.10 / 0.20, …) and, for R7's undeclared colours, their hex and "declared with its first caller"; (3) the CSS ↔ Dart name map for radius and icons (R8); (4) the rulings table R1–R13 copied from this plan
- Modify: `docs/design-system/theme-architecture.md`, `docs/design-system/ad-14-color-and-depth.md` — only sentences the v3 values or the one-family change make false; link the new file
- Modify: `docs/wbs.md` — one entry under the live ledger in the file's own language and shape (read two recent entries first), id placeholder `M100.97`, acceptance criteria as checkboxes, linking the spec, this plan and `v3-foundations.md`
- Modify: `.claude/skills/**/*.md` only where a sentence names Inter or a removed constant
- Commit: `design_audit/*` as regenerated by `flutter test test/design_audit`

- [ ] **Step 1:** Read `docs/document-conventions.md` (header, MUST/SHOULD/MAY) before writing.
- [ ] **Step 2:** Write the files above; every hex you write is copied from GC-1…GC-6 or the spec, never retyped from memory.
- [ ] **Step 3:** `python .claude/skills/flutter-workflow/scripts/check_docs.py` clean.
- [ ] **Step 4:** `flutter test test/design_audit`, then commit the regenerated `design_audit/*` with the docs: `docs(design-system): v3 foundations map, rulings and WBS entry`.

---

## Controller-run steps (not dispatched)

1. Full host suite after Task 8 (feeds Task 9's failure list) and after Task 9: `flutter test --exclude-tags golden`.
2. `bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main` and the guard.
3. Goldens: re-author on Linux in a WSL clone dedicated to this branch (`TZ=UTC`, CI's `goldens (linux)` file list, sliced `-j 1`), copy the PNGs back, commit `test(goldens): re-author on Linux for the v3 foundations`.
4. `flutter test integration_test/ -d emulator-5554 --flavor development` — 9 passing, 0 failing; never concurrently with the host suite.
5. Final whole-branch review.
6. `python .claude/skills/flutter-testing/scripts/build_screen_gallery.py`; publish `build/screen_gallery.html` at the pinned gallery URL after reading the live page.
7. WBS id census, merge `origin/main`, re-run the gate if the base moved, push, PR, CI green, merge, confirm `MERGED`, delete the branch.
