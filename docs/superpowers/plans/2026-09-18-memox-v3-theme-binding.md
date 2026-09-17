# MemoX v3 Theme Binding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the theme-binding mechanisms the v3 registry needs that the Foundations PR (#569, `M100.97`) did not build — the MemoX product semantics, the central derived colours, the effect tokens, the decoration treatments by name, the two missing global state tokens and the one global overlay treatment — plus the validation, docs and WBS that freeze the prerequisite.

**Architecture:** #569 is the Foundation baseline and is never rewritten: the v3 palette, the twelve `*Fixed` roles, the accessibility text inks, `AppTypography`/Plus Jakarta Sans, the spacing/radius/icon ladders, the gutter, the foundation tests, the contrast gates and the goldens all stand as merged. This plan adds only what is missing, routed by kind: `MEMOX_SEMANTIC_COLOR` → `AppSemanticColors`; `DERIVED_COLOR` → one central function each; `DECORATION` → a named-treatment mechanism; `EFFECT_TOKEN` → its own constants, outside the state layer; `STATE_TOKEN` → `AppStateOpacity`/`AppStroke`; `M3_ALIAS` → its `ColorScheme` role, with **no new runtime field**.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, Material 3, flutter_test, the repo's Python guard (`code-verification-guard-v2`).

**Spec:** `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md`. The delta against main lives in `.superpowers/sdd/2026-09-18-memox-v3-theme-prerequisite/delta-matrix.md` (buckets A–D); this plan implements bucket B only.

## Global Constraints

1. **#569 is the baseline.** Do not rewrite or revert anything it merged: the 45 role values, the `*Fixed` twelve, the text inks (`accentInk`, `dangerInk`, `successInk`, `warningInk`, `secondaryInk`, `tertiaryInk`, `inversePrimaryInk`) and `AppInk`'s routing through them, `AppTypography`, the ladders, the gutter and scroll tail, the foundation tests, the contrast gates, the goldens.
2. **Values are verbatim** from the spec record. If a literal in the spec disagrees with what main already ships, **REPORT the mismatch** and change nothing — main wins for an already-implemented Foundation value.
3. **Route by kind.** `MEMOX_SEMANTIC_COLOR` BIND_NOW → `AppSemanticColors`; `M3_ALIAS` → its `ColorScheme` role with no new runtime field; `DERIVED_COLOR` → one central derivation each; `DECORATION` → the named-treatment mechanism; `STATE_TOKEN` → `AppStateOpacity` / `AppStroke`; `EFFECT_TOKEN` → `AppEffects`, never inside `lib/core/theme/states/`; `COMPONENT_INPUT` (`accent`, `seed`) and `NONE` (`transparent`) → no theme field at all.
4. **PRESERVE_ONLY adds nothing**: no field, constant or function for `success`, `warning`, `on-warning`, `streak`, `on-streak`, `mastery-fixed`, `on-danger`, `text-muted`, `badge-bg`, `danger`, `text-primary`, `primary-soft`, `primary-border`, `danger-border`, `success-soft`, `warning-soft`, `shadow-none`, `border-strong`, `op-hover`.
5. **Two legacy fields stay exactly as main has them** (owner ruling 2026-09-18): `AppSemanticColors.progressTrack` is a compatibility alias — main already derives it from `surfaceContainerHigh`, the validation asserts that equality, and it goes on the retirement-debt list; `AppSemanticColors.surfaceMuted` is a **name collision, not an alias** — it resolves to `surfaceContainer` (`#E9EDF7`) where v3's `surface-muted` is `surfaceContainerLow` (`#F1F4FB`), so its backing value is not touched and it is never asserted equal to `surfaceContainerLow`.
6. **No component behaviour or variant change.** `shadowsFor`'s level→treatment mapping, `MxCard`'s fills, and every Material component-theme colour slot stay as main has them. Where a slot does not yet match its v3 `themeRoleUsage`, record it as COMPONENT_MIGRATION_PENDING — do not fix it here. No feature or component call site is edited to tidy an alias table.
7. **Layering** (`docs/design-system/theme-architecture.md` §2): `foundations/` imports only `foundations/` and Flutter; `typography/` and `states/` import `foundations/`; `components/` and `schemes/` import `foundations/`, `typography/`, `states/`; `extensions/` imports `foundations/`, `typography/`; nothing under `lib/core/theme/` imports `lib/features/`, `lib/app/` or `lib/shared/`. Every `XxxThemeData(` constructor lives in `components/`.
8. **Tests:** TDD — write or move the assertion first and watch it fail. Never delete, skip, `exclude` or comment out a test; blocks already carrying a `TODO(...)` stay as they are. A test that fails because this plan moved a value it pinned is re-pinned with a one-line reason; a **structural** assertion that the change contradicts is a stop-and-report, not a relax.
9. **House style:** guard clauses and early return, no `else` after `return`, no magic numbers (name them), no colour literal outside the token files listed in `test/visual_audit/color_source_rules_test.dart`, no `DateTime.now()`, no user-visible string. Keep every file you touch under 400 lines.
10. **Verification before every commit** — all must pass, and the report quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
    - `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` when the task creates a file
    - then `git checkout -- design_audit/` — the suite rewrites those tracked reports.
    Never run `--update-goldens`: goldens are authored on Linux and the controller regenerates them.
11. **Commits:** Conventional Commits, scope `theme` or `design-system`, ending with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. Do not push, open PRs or dispatch subagents.

---

### Task 1: MemoX product semantics — the seven BIND_NOW fields

**Files:**
- Create: `lib/core/theme/foundations/app_product_colors.dart`
- Modify: `lib/core/theme/foundations/app_semantic_colors.dart`
- Modify: `test/visual_audit/color_source_rules_test.dart` (add the new file to `declarationFiles`, one-line reason in that file's style)
- Modify: `widgetbook/lib/tokens/color_sections.dart` (seven swatches in the existing section style)
- Test: `test/core/theme/foundations/app_semantic_colors_test.dart`

**Interfaces:**
- Consumes: main's `ColorScheme` and `AppSemanticColors`.
- Produces: `AppSemanticColors.mastery`, `.statusNew`, `.statusLearning`, `.statusReviewing`, `.statusMastered`, `.errorFill`, `.onErrorFill`; `AppProductColors.{mastery,statusNew,statusLearning,statusReviewing,statusMastered,errorFill,onErrorFill}{Light,Dark}`.

- [ ] **Step 1: Write the failing test**

Append to `main()` in `test/core/theme/foundations/app_semantic_colors_test.dart`:

```dart
  group('v3 MEMOX_SEMANTIC_COLOR — BIND_NOW', () {
    // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.1.
    const AppSemanticColors light = AppSemanticColors.light();
    const AppSemanticColors dark = AppSemanticColors.dark();

    void pin(String name, Color l, Color d, int lightArgb, int darkArgb) {
      expect(l.toARGB32(), lightArgb, reason: '$name light');
      expect(d.toARGB32(), darkArgb, reason: '$name dark');
    }

    test('carry the registry values in both themes', () {
      pin('mastery', light.mastery, dark.mastery, 0xFF1F8A5B, 0xFF6FE0BD);
      pin('status-new', light.statusNew, dark.statusNew, 0xFF8C95B8, 0xFF6B75A3);
      pin('status-learning', light.statusLearning, dark.statusLearning, 0xFFF59E0B, 0xFFFFC658);
      pin('status-reviewing', light.statusReviewing, dark.statusReviewing, 0xFF5265F5, 0xFF8B9AFF);
      pin('status-mastered', light.statusMastered, dark.statusMastered, 0xFF1F8A5B, 0xFF6FE0BD);
      pin('error-fill', light.errorFill, dark.errorFill, 0xFFDC2D4E, 0xFFB0485C);
      pin('on-error-fill', light.onErrorFill, dark.onErrorFill, 0xFFFFFFFF, 0xFFFFFFFF);
    });

    test('copyWith and lerp carry the new fields', () {
      const Color probe = Color(0xFF000000);
      final AppSemanticColors changed = light.copyWith(errorFill: probe);
      expect(changed.errorFill, probe);
      expect(changed.mastery, light.mastery);

      final AppSemanticColors mid = light.lerp(dark, 0.5);
      for (final (Color got, Color a, Color b) in <(Color, Color, Color)>[
        (mid.mastery, light.mastery, dark.mastery),
        (mid.statusNew, light.statusNew, dark.statusNew),
        (mid.statusLearning, light.statusLearning, dark.statusLearning),
        (mid.statusReviewing, light.statusReviewing, dark.statusReviewing),
        (mid.statusMastered, light.statusMastered, dark.statusMastered),
        (mid.errorFill, light.errorFill, dark.errorFill),
        (mid.onErrorFill, light.onErrorFill, dark.onErrorFill),
      ]) {
        expect(got, Color.lerp(a, b, 0.5));
      }
    });

    test('no v3 M3_ALIAS gained a field of its own', () {
      // `surfaceMuted` is NOT on this list: it is a pre-#569 name collision
      // (it resolves to `surfaceContainer`), not v3's `surface-muted`.
      final String source = File(
        'lib/core/theme/foundations/app_semantic_colors.dart',
      ).readAsStringSync();
      for (final String alias in <String>['bg', 'surfaceRaised', 'textSecondary']) {
        expect(source, isNot(contains('final Color $alias;')), reason: alias);
      }
    });
  });
```

`#569`'s own `copyWith`/`lerp` completeness tests in that file enumerate a hardcoded list of field names — add the seven to those lists as well, or they pass without covering the new fields.

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/core/theme/foundations/app_semantic_colors_test.dart -r failures-only`
Expected: compile FAIL — `mastery` and the rest are not defined.

- [ ] **Step 3: Create the value constants**

`lib/core/theme/foundations/app_product_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// MemoX product semantics Material has no honest role for — the v3 registry's
/// `MEMOX_SEMANTIC_COLOR` entries whose runtime disposition is `BIND_NOW`
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.1).
/// `AppSemanticColors` carries them into the theme.
///
/// **Two semantics may share an authored value and still be two semantics.**
/// `statusReviewing` equals `primary` and `statusMastered` equals `mastery`
/// today; each is its own literal, so moving one never moves the other.
///
/// **The PRESERVE_ONLY entries have no constant here on purpose** — `success`,
/// `warning`, `on-warning`, `streak`, `on-streak`, `mastery-fixed`,
/// `on-danger`, `text-muted`. No v3 consumer paints them, and a colour with no
/// caller is a colour nobody checks.
abstract final class AppProductColors {
  /// `mastery` — the accent StudyTopBar is handed in Recall and Fill sessions.
  static const Color masteryLight = Color(0xFF1F8A5B);
  static const Color masteryDark = Color(0xFF6FE0BD);

  /// `status-new` — a card never studied. StatusBadge dot, label and 12% tint.
  static const Color statusNewLight = Color(0xFF8C95B8);
  static const Color statusNewDark = Color(0xFF6B75A3);

  /// `status-learning` — StatusBadge, and MasteryRamp's fill below 34%.
  static const Color statusLearningLight = Color(0xFFF59E0B);
  static const Color statusLearningDark = Color(0xFFFFC658);

  /// `status-reviewing` — StatusBadge, and MasteryRamp's fill from 34% to 66%.
  static const Color statusReviewingLight = Color(0xFF5265F5);
  static const Color statusReviewingDark = Color(0xFF8B9AFF);

  /// `status-mastered` — StatusBadge, and MasteryRamp's fill from 67%.
  static const Color statusMasteredLight = Color(0xFF1F8A5B);
  static const Color statusMasteredDark = Color(0xFF6FE0BD);

  /// `error-fill` — the destructive button's solid fill. Not `error`: dark's
  /// fill is `#B0485C`, where `error` is `#FF8FA3`.
  static const Color errorFillLight = Color(0xFFDC2D4E);
  static const Color errorFillDark = Color(0xFFB0485C);

  /// `on-error-fill` — label and glyph on the fill above. Equal in both themes
  /// without being declared invariant: only `inverseSurface` and
  /// `onInverseSurface` carry that flag.
  static const Color onErrorFillLight = Color(0xFFFFFFFF);
  static const Color onErrorFillDark = Color(0xFFFFFFFF);
}
```

- [ ] **Step 4: Add the seven fields**

In `AppSemanticColors`: seven `required this.<field>` constructor parameters, seven `final Color <field>;` declarations each with a one-line doc naming the registry entry and its consumers, the `light()` and `dark()` initialisers reading `AppProductColors`, and the `copyWith` and `lerp` entries. Do not touch any existing field — including `surfaceMuted` and `progressTrack` (Global Constraint 5).

Add the new file to `declarationFiles` in `test/visual_audit/color_source_rules_test.dart`, and give the seven their swatches in `widgetbook/lib/tokens/color_sections.dart` in the section style already there.

- [ ] **Step 5: Run the target test, then the full gate**

Run: `flutter test test/core/theme/foundations/app_semantic_colors_test.dart -r failures-only` → PASS.
Then Global Constraint 10, plus `cd widgetbook && dart run build_runner build --delete-conflicting-outputs && flutter test --reporter failures-only`.

- [ ] **Step 6: Commit**

```bash
git add lib test widgetbook/lib
git commit -m "feat(theme): v3 MemoX product semantics — mastery, the four statuses and the destructive fill pair

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Derived colours, effect tokens and the two missing state tokens

Main already unified pressed (0.12) and hover (0.08) in #569 — **do not touch them**. What is missing is the whole-control disabled token, the focus-ring offset, the three central derivations and the glass effect tokens.

**Files:**
- Create: `lib/core/theme/foundations/app_effects.dart`
- Create: `lib/core/theme/foundations/app_derived_colors.dart`
- Modify: `lib/core/theme/states/app_interaction_states.dart` (add `AppStateOpacity.disabled`)
- Modify: `lib/core/theme/foundations/app_stroke.dart` (add `focusRingOffset`)
- Test: create `test/core/theme/foundations/app_derived_colors_test.dart`, create `test/core/theme/foundations/app_effects_test.dart`, extend `test/core/theme/states/app_interaction_states_test.dart` and `test/core/theme/foundations/app_stroke_test.dart`

**Interfaces:**
- Consumes: main's `ColorScheme`.
- Produces: `AppEffects.glassOpacity` (0.84), `AppEffects.glassBlurSigma` (18); `AppDerivedColors.dangerSoft/surfaceHero/chromeGlass(ColorScheme) → Color`; `AppStateOpacity.disabled` (0.38); `AppStroke.focusRingOffset` (2).

- [ ] **Step 1: Write the failing tests**

`test/core/theme/foundations/app_derived_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_derived_colors.dart';
import 'package:memox/core/theme/schemes/app_color_scheme.dart';

/// Channel-wise, within one 8-bit step: `color-mix()` rounds in the browser and
/// `Color.alphaBlend` rounds in `toARGB32`, and the two can land a step apart.
void _expectNear(Color actual, int argb) {
  final Color expected = Color(argb);
  int channel(double value) => (value * 255).round();
  expect((channel(actual.a) - channel(expected.a)).abs(), lessThanOrEqualTo(1));
  expect((channel(actual.r) - channel(expected.r)).abs(), lessThanOrEqualTo(1));
  expect((channel(actual.g) - channel(expected.g)).abs(), lessThanOrEqualTo(1));
  expect((channel(actual.b) - channel(expected.b)).abs(), lessThanOrEqualTo(1));
}

void main() {
  // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.3.
  test('danger-soft is error at 8% light and 16% dark, over transparent', () {
    expect(AppDerivedColors.dangerSoft(lightColorScheme).toARGB32(), 0x14DC2D4E);
    expect(AppDerivedColors.dangerSoft(darkColorScheme).toARGB32(), 0x29FF8FA3);
  });

  test('surface-hero is primary 5% over surfaceBright in light', () {
    _expectNear(AppDerivedColors.surfaceHero(lightColorScheme), 0xFFF6F7FE);
  });

  test('surface-hero is primary 12% over surface in dark — another base', () {
    _expectNear(AppDerivedColors.surfaceHero(darkColorScheme), 0xFF191F41);
  });

  test('chrome-glass is surface at op-glass, left translucent', () {
    expect(AppDerivedColors.chromeGlass(lightColorScheme).toARGB32(), 0xD6F7F9FE);
    expect(AppDerivedColors.chromeGlass(darkColorScheme).toARGB32(), 0xD60A0E27);
  });

  test('each derivation follows the scheme it is handed', () {
    final ColorScheme moved = lightColorScheme.copyWith(
      error: const Color(0xFF000000),
      surface: const Color(0xFF000000),
    );
    expect(AppDerivedColors.dangerSoft(moved).toARGB32(), 0x14000000);
    expect(AppDerivedColors.chromeGlass(moved).toARGB32(), 0xD6000000);
  });
}
```

`test/core/theme/foundations/app_effects_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';

void main() {
  // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.6.
  test('op-glass is 0.84 and the glass blur is 18 sigma', () {
    expect(AppEffects.glassOpacity, 0.84);
    expect(AppEffects.glassBlurSigma, 18);
  });

  test('the state layer does not own glass', () {
    for (final FileSystemEntity file in Directory(
      'lib/core/theme/states',
    ).listSync()) {
      expect(
        File(file.path).readAsStringSync(),
        isNot(contains('AppEffects')),
        reason: file.path,
      );
    }
  });
}
```

Append to `test/core/theme/states/app_interaction_states_test.dart`:

```dart
  group('v3 global state policy', () {
    // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.5, §8.
    test('disabled is 0.38 over the whole control', () {
      expect(AppStateOpacity.disabled, 0.38);
    });

    test('the ink alpha it sits beside is a different token', () {
      // `disabledContent` dims a label; `disabled` dims the control. Equal
      // values, two semantics — the registry names only the second.
      expect(AppStateOpacity.disabledContent, 0.38);
    });
  });
```

Append to `test/core/theme/foundations/app_stroke_test.dart`:

```dart
  test('the focus ring is 2dp at offset 2', () {
    // §8: one focus treatment for every control.
    expect(AppStroke.focus, 2);
    expect(AppStroke.focusRingOffset, 2);
  });
```

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/core/theme/foundations/app_derived_colors_test.dart test/core/theme/foundations/app_effects_test.dart test/core/theme/states/app_interaction_states_test.dart test/core/theme/foundations/app_stroke_test.dart -r failures-only`
Expected: compile FAIL — `AppDerivedColors`, `AppEffects`, `AppStateOpacity.disabled`, `AppStroke.focusRingOffset` do not exist.

- [ ] **Step 3: Implement**

`lib/core/theme/foundations/app_effects.dart`:

```dart
/// Visual effects that are neither an interaction state nor a colour — the v3
/// registry's `EFFECT_TOKEN` entries (docs/superpowers/specs/
/// 2026-09-18-memox-v3-theme-prerequisite.md §5.6).
///
/// **Kept out of `states/` on purpose.** Glass is translucency, not
/// interaction; a pressed or disabled policy that could reach these would be
/// the two layers sharing one channel.
abstract final class AppEffects {
  /// `op-glass` — the alpha chrome glass keeps over its runtime backdrop.
  /// `AppDerivedColors.chromeGlass` reads it, so 0.84 is authored once.
  static const double glassOpacity = 0.84;

  /// `glass-blur` — the blur behind glass chrome, as a Gaussian sigma.
  ///
  /// The registry's web value is `saturate(180%) blur(18px)`, a non-binding
  /// source trace. CSS `blur()` takes a standard deviation and so does
  /// `ImageFilter.blur`, so the number carries over as is. The saturation
  /// boost does not: it is a second filter pass over scrolling content for a
  /// web-only vibrancy cue, and blur alone carries the glass intent. Where a
  /// platform or the frame budget refuses live blur, the consumer keeps its
  /// solid or translucent fallback.
  static const double glassBlurSigma = 18;
}
```

`lib/core/theme/foundations/app_derived_colors.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_effects.dart';

/// The v3 registry's `DERIVED_COLOR` entries with runtime disposition
/// `BIND_NOW`, each derived exactly once, here, from the scheme it is handed
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.3).
///
/// A consumer applies no percentage of its own — its treatment is
/// `FULL_STRENGTH`. Deriving from the scheme rather than from constants is
/// what keeps high contrast and any future palette consistent without a second
/// edit.
///
/// **The PRESERVE_ONLY derivations are absent on purpose** — `primary-soft`,
/// `primary-border`, `danger-border`, `success-soft`, `warning-soft`. Three
/// components that look like `primary-soft` each tint `primary` at their own
/// percentage; they bind `primary` with a component treatment instead.
abstract final class AppDerivedColors {
  /// `danger-soft` — ErrorState's tile. `error` over transparent.
  static Color dangerSoft(ColorScheme scheme) => scheme.error.withValues(
    alpha: _isDark(scheme) ? _dangerSoftDarkAlpha : _dangerSoftLightAlpha,
  );

  /// `surface-hero` — the tinted hero card. **The base differs by theme:**
  /// `primary` 5% over `surfaceBright` in light, 12% over `surface` in dark.
  static Color surfaceHero(ColorScheme scheme) {
    if (_isDark(scheme)) {
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: _heroDarkAlpha),
        scheme.surface,
      );
    }

    return Color.alphaBlend(
      scheme.primary.withValues(alpha: _heroLightAlpha),
      scheme.surfaceBright,
    );
  }

  /// `chrome-glass` — the bottom navigation bar's surface: `surface` at
  /// [AppEffects.glassOpacity]. Returned translucent so it composites at paint
  /// time over whatever is behind it; never pre-flatten it against a page.
  static Color chromeGlass(ColorScheme scheme) =>
      scheme.surface.withValues(alpha: AppEffects.glassOpacity);

  static bool _isDark(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark;
}

const double _dangerSoftLightAlpha = 0.08;
const double _dangerSoftDarkAlpha = 0.16;
const double _heroLightAlpha = 0.05;
const double _heroDarkAlpha = 0.12;
```

In `AppStateOpacity`, beside the existing `disabledContent`, add:

```dart
  /// `op-disabled` — the v3 global rule: opacity 0.38 over the **whole
  /// control**, applied once by the component
  /// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §8).
  ///
  /// The solid disabled fill below ([disabledContent], [disabledSurfaceBlend]
  /// and `AppSemanticColors.disabledSurface`) stays exactly as it is: it is
  /// what today's controls draw, and switching a resolver before its component
  /// applies this opacity would make a disabled control look enabled.
  static const double disabled = 0.38;
```

In `AppStroke`, directly after `focus`:

```dart
  /// The gap between a control's edge and its focus ring — the v3 global rule
  /// is a 2dp `primary` ring at offset 2
  /// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §8).
  /// A spacing of the ring, not a stroke width, and kept beside [focus]
  /// because the two are one rule.
  static const double focusRingOffset = 2;
```

- [ ] **Step 4: Run the target tests, then the full gate** (Global Constraint 10, including `check_architecture.sh`).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "feat(theme): v3 derived colours, glass effect tokens, whole-control disabled and the focus-ring offset

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Decoration treatments by name, and the one global modal barrier

Main holds three of the four v3 shadows inside a private `_Shadow` enum in `app_elevation.dart`, bound to elevation levels. This task gives every treatment its v3 semantic name in one mechanism, adds the two main has no value for at all (`shadow-chrome`, `border-ghost`), and moves the modal barrier to its single v3 value — **without changing which treatment any component wears**.

**Files:**
- Create: `lib/core/theme/foundations/app_decorations.dart`
- Modify: `lib/core/theme/foundations/app_elevation.dart` (delegate to the named treatments; the level→treatment mapping does not change)
- Modify: `lib/core/theme/components/overlays/app_backdrop_recipe.dart` (barrier → `scrim` @ 0.45 in both themes)
- Modify: `test/design_audit/color_rule_scope.dart` if the R7 translucent-border guard fires on `hairlineEdge` — extend the existing file exemption that already covers `app_elevation.dart`, scoped to this file, with a comment naming `border-ghost`
- Test: create `test/core/theme/foundations/app_decorations_test.dart`; update whichever test pins the barrier's 0.48/0.72 (`test/core/theme/components/app_overlay_themes_test.dart` and any dialog/sheet test that repeats it)

**Interfaces:**
- Consumes: main's `ColorScheme` (`shadow`, `primary`, `scrim`), `AppStroke.hairline`.
- Produces: `AppDecorations.cardWhisperShadow/overlayShadow/chromeShadow/fabShadow(ColorScheme) → List<BoxShadow>`, `AppDecorations.hairlineEdge(ColorScheme) → BorderSide`. `shadowsFor(double, ColorScheme)` and `materialShadowColor(ColorScheme)` keep their signatures **and their behaviour**.

- [ ] **Step 1: Write the failing tests**

`test/core/theme/foundations/app_decorations_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/schemes/app_color_scheme.dart';

void _expectShadow(
  List<BoxShadow> shadows, {
  required double dy,
  required double blur,
  required int argb,
}) {
  expect(shadows, hasLength(1));
  final BoxShadow shadow = shadows.single;
  expect(shadow.offset, Offset(0, dy));
  expect(shadow.blurRadius, blur);
  expect(shadow.spreadRadius, 0);
  expect(shadow.color.toARGB32(), argb);
}

void main() {
  // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.4.
  test('card-whisper-shadow (shadow-soft): 0 1px 2px @4% light, none dark', () {
    _expectShadow(
      AppDecorations.cardWhisperShadow(lightColorScheme),
      dy: 1,
      blur: 2,
      argb: 0x0A0F1638,
    );
    expect(AppDecorations.cardWhisperShadow(darkColorScheme), isEmpty);
  });

  test('overlay-shadow (shadow-card) — the Dialog, not the Card', () {
    _expectShadow(
      AppDecorations.overlayShadow(lightColorScheme),
      dy: 12,
      blur: 32,
      argb: 0x1A0F1638,
    );
    _expectShadow(
      AppDecorations.overlayShadow(darkColorScheme),
      dy: 16,
      blur: 40,
      argb: 0x6B000000,
    );
  });

  test('chrome-shadow (shadow-chrome) casts upward', () {
    _expectShadow(
      AppDecorations.chromeShadow(lightColorScheme),
      dy: -2,
      blur: 12,
      argb: 0x0D0F1638,
    );
    _expectShadow(
      AppDecorations.chromeShadow(darkColorScheme),
      dy: -2,
      blur: 14,
      argb: 0x5C000000,
    );
  });

  test('fab-shadow (shadow-fab)', () {
    _expectShadow(
      AppDecorations.fabShadow(lightColorScheme),
      dy: 8,
      blur: 24,
      argb: 0x1F0F1638,
    );
    _expectShadow(
      AppDecorations.fabShadow(darkColorScheme),
      dy: 10,
      blur: 28,
      argb: 0x80000000,
    );
  });

  test('hairline-edge (border-ghost) is primary at 14% / 16%, one hairline', () {
    final BorderSide light = AppDecorations.hairlineEdge(lightColorScheme);
    final BorderSide dark = AppDecorations.hairlineEdge(darkColorScheme);
    expect(light.color.toARGB32(), 0x245265F5);
    expect(dark.color.toARGB32(), 0x298B9AFF);
    expect(light.width, AppStroke.hairline);
    expect(dark.width, AppStroke.hairline);
  });

  test('the elevation scale still paints what it painted before', () {
    // This task centralises the VALUES; which treatment a level wears is the
    // component contracts' decision, deferred (delta matrix D4). So the levels
    // keep main's mapping: card -> whisper, raised -> overlay-shadow,
    // overlay -> fab-shadow, with the dark rim unchanged.
    expect(
      shadowsFor(AppElevation.card, lightColorScheme),
      AppDecorations.cardWhisperShadow(lightColorScheme),
    );
    expect(
      shadowsFor(AppElevation.raised, lightColorScheme),
      AppDecorations.overlayShadow(lightColorScheme),
    );
    expect(
      shadowsFor(AppElevation.overlay, lightColorScheme),
      AppDecorations.fabShadow(lightColorScheme),
    );
  });
}
```

Add the imports that test needs for `shadowsFor` / `AppElevation`.

For the barrier, move the pin first — in whichever test asserts it today:

```dart
    // §15.1: Scrim, Dialog and BottomSheet all take the barrier at 0.45; one
    // recipe, one value, both themes.
    expect(modalBarrierColor(lightColorScheme).toARGB32(), 0x730A0E27);
    expect(modalBarrierColor(darkColorScheme).toARGB32(), 0x73000000);
    expect(modalBarrierColor(lightColorScheme).r, lightColorScheme.scrim.r);
```

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/core/theme/foundations/app_decorations_test.dart test/core/theme/components/app_overlay_themes_test.dart -r failures-only`
Expected: compile FAIL for `AppDecorations`, and the barrier pins failing at 0.48 / 0.72.

- [ ] **Step 3: Implement**

Create `AppDecorations` with the five treatments, each value a named record constant citing its registry token; the shadow colour derives from `scheme.shadow` and the hairline edge from `scheme.primary` (`rgba(82,101,245,.14)` / `rgba(139,154,255,.16)` ARE `primary` at those alphas). Then rewrite `app_elevation.dart`'s private `_Shadow` enum away: `shadowsFor` keeps its exact structure and mapping and calls the named treatments instead, and its doc says plainly that the mapping — not the values — is what a component contract will revisit.

In `app_backdrop_recipe.dart`, replace the brightness ternary with one named constant:

```dart
/// The v3 barrier: `scrim` at [_barrierOpacity], the same in both themes
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §15.1 —
/// Scrim, Dialog and BottomSheet are all given 0.45). One recipe, so no
/// component spells the number itself.
Color modalBarrierColor(ColorScheme scheme) =>
    scheme.scrim.withValues(alpha: _barrierOpacity);

const double _barrierOpacity = 0.45;
```

Update the comment that argued for 0.48 / 0.72 so it records what changed and why, rather than describing a value that is gone.

- [ ] **Step 4: Run the target tests, then the full gate** (Global Constraint 10, including `check_architecture.sh`). The barrier moves pixels in every modal golden — do **not** regenerate goldens; list the golden tests that will need regenerating in the report instead.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test
git commit -m "feat(theme): v3 decoration treatments by name, and one modal barrier at 0.45

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Validate the binding, document it, record it in the WBS

**Files:**
- Create: `test/core/theme/contracts/v3_theme_binding_test.dart`
- Modify: `docs/design-system/theme-architecture.md`
- Modify: `docs/wbs.md` (header rows `Updated by task` → `M100.98`, `Last updated` → `2026-09-18`; the Progress summary counts if `check_docs.py` requires it)
- Modify: `docs/wbs-archive/m100.md` (a `### M100.98` entry above `M100.97`, in that file's shape)

**Interfaces:** consumes everything Tasks 1–3 produced. Produces nothing new.

- [ ] **Step 1: Write the validation test**

`test/core/theme/contracts/v3_theme_binding_test.dart` — routing, dispositions and coverage; values are pinned by the per-mechanism tests, so nothing is pinned twice:

- **BIND_NOW `MEMOX_SEMANTIC_COLOR`**: the seven names are fields on `AppSemanticColors` (scan `final Color (\w+);` in its source).
- **PRESERVE_ONLY adds nothing**: none of `onWarning`, `streak`, `onStreak`, `masteryFixed`, `onDanger`, `textMuted`, `badgeBg`, `primarySoft`, `primaryBorder`, `dangerBorder`, `successSoft`, `warningSoft`, `shadowNone`, `borderStrong` appears as a symbol anywhere under `lib/core/theme`.
- **`M3_ALIAS` gets no new runtime field**: `bg`, `surfaceRaised`, `textSecondary` are not fields. **`surfaceMuted` is deliberately NOT on that list** — it is a pre-#569 legacy name that resolves to `surfaceContainer`, not v3's `surface-muted`; assert that collision explicitly so nobody reads one as the other: `expect(theme.extension<AppSemanticColors>()!.surfaceMuted, theme.colorScheme.surfaceContainer)` and `expect(…surfaceMuted, isNot(theme.colorScheme.surfaceContainerLow))`.
- **`progressTrack` is a compatibility alias**: `expect(theme.extension<AppSemanticColors>()!.progressTrack, theme.colorScheme.surfaceContainerHigh)` in both themes, with a comment naming it retirement debt.
- **`COMPONENT_INPUT` / `NONE`**: `accent`, `seed`, `transparent` are not fields.
- **Effect tokens stay outside the state layer**: no file under `lib/core/theme/states/` mentions `AppEffects`.
- **Every DIRECT consumer role resolves** (spec §15.1) in both themes, through the mechanism its kind names: the M3 roles from `ColorScheme`; `bg`/`surface-muted`/`surface-raised`/`progress-track`/`text-secondary` from their `ColorScheme` targets; the four `status-*`, `error-fill`, `on-error-fill` from `AppSemanticColors`; `danger-soft`, `surface-hero`, `chrome-glass` from `AppDerivedColors`; the four shadows and `border-ghost` from `AppDecorations`; `op-disabled`, `op-press` from `AppStateOpacity`; `glass-blur` from `AppEffects`. Assert each is non-null and, for a `Color`, has a positive alpha — except `transparent` (no theme value) and `shadow-soft` in dark (the registry says none).
- **The invariant pair**: `inverseSurface` and `onInverseSurface` are equal in the two themes — asserted, never inferred from other equal values.

- [ ] **Step 2: Run it** — `flutter test test/core/theme/contracts/v3_theme_binding_test.dart -r failures-only` → PASS. A failure here is a mismatch in an earlier task: report it (`DONE_WITH_CONCERNS`), do not change `lib/` in this task.

- [ ] **Step 3: Document**

`docs/design-system/theme-architecture.md` (Vietnamese prose like the rest of the file; identifiers in English):
- Header: `Updated by task` → `M100.98`, `Last updated` → `2026-09-18`.
- A new section **"Định tuyến registry v3 theo kind"**: the table kind → mechanism → file, a MUST that PRESERVE_ONLY adds nothing and an `M3_ALIAS` never gets a runtime field, and the sentence that #569 owns the Foundation values while this layer owns routing and ownership.
- A **name-collision note**: legacy `AppSemanticColors.surfaceMuted` (`surfaceContainer`) is not v3's `surface-muted` (`surfaceContainerLow`); `AppSemanticColors.progressTrack` is a compatibility alias of `surfaceContainerHigh` and is retirement debt.
- A **COMPONENT_MIGRATION_PENDING** table — component · slot · target semantic role — carrying the delta matrix's D3 and D5 rows so the component tasks inherit them: `MxCard` container → `surface-raised`; `MxCard` recessed → `surface-muted`; `CardTheme.color` → `surface-raised`; `BottomSheetThemeData.backgroundColor` → `surfaceContainerHigh` and its grabber → `outlineVariant`; `NavigationBar` background → `chrome-glass`, indicator → `primary` TINT 14%/20%, selected icon and label → `primary`; `FloatingActionButton` → `primary`/`onPrimary`; `FilterChip` selected → `primary`/`onPrimary`, unselected label → `onSurface`, border → `border-ghost`; `Switch` thumb → `surfaceBright`; `OutlinedButton` side → `outlineVariant`; `IconButton` glyph → `onSurface`; `TextField` resting fill → `surface-muted`, focused fill → `surface-raised`, borders → `border-ghost` / `primary` / `error`; `ProgressIndicator` linear track → `progress-track`; the elevation scale's level→treatment mapping; `MxNavigationBar`'s top edge → `border-ghost`; the dark card rim → `border-ghost`.
- Do **not** edit `docs/design-system/ad-14-color-and-depth.md` or `docs/architecture.md` (Status `frozen for MVP`, not named by this task).

`docs/wbs-archive/m100.md` — a `### M100.98` entry above `M100.97` in that file's shape: goal (bind the v3 registry's remaining mechanisms onto #569's foundations), scope (Tasks 1–4 of this plan), out of scope (everything in the delta matrix's D bucket, named), editable documents, output, acceptance criteria (routing validated; analyze/test/guard/check_docs green; goldens regenerated for the barrier), dependencies (`M100.97`), tests required, checklist phases 7 and 12.

- [ ] **Step 4: Run the full gate** — Global Constraint 10 plus `python .claude/skills/flutter-workflow/scripts/check_docs.py` → clean.

- [ ] **Step 5: Commit**

```bash
git add test/core/theme/contracts/v3_theme_binding_test.dart docs
git commit -m "test(theme): validate the v3 theme binding; document the routing and what stays pending (M100.98)

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```
