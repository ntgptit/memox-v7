# IconTile Shared Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `MxIconTile` — the shared "tinted square holding a leading glyph" component the v3 registry names as `ListRow`'s and `SettingsRow`'s leading visual and as the deck row's icon well at 44dp — to `lib/shared/widgets/`, per the IconTile component handoff (reproduced in full in the dispatch args of this plan's originating command; no separate spec file exists for this component — the theme prerequisite spec at `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` is the binding authority for every token value this task consumes).

**Architecture:** A single new leaf widget in `lib/shared/widgets/`. It reads `ColorScheme.primary` directly (`M3_COLOR`, `DIRECT`, per the theme routing table) and takes `seed` as a per-instance `Color` (`COMPONENT_INPUT` — never a theme field, per the spec's explicit instruction at line 209). No other file in `lib/core/theme/` changes: every role this component needs (`primary`) is already bound by the merged theme-prerequisite work (#569 + M100.98). No screen wires it yet — `ListRow`/`SettingsRow`/`DeckIconArea` migration is out of scope (see Global Constraint 6).

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, Material 3, flutter_test, the repo's Python guard (`code-verification-guard-v2`), Widgetbook.

**Spec:** No `docs/superpowers/specs/*.md` file exists for this component specifically. The binding contract is the IconTile handoff text this plan was written from (dimension table, theme-consumption table, state matrix, self-check — all reproduced in the task brief below verbatim). Cross-reference for the token values and composition context: `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` lines 163, 209, 354, 384-385.

## Prior-art findings (read before dispatching)

An Explore pass over the repo (full findings kept in this session, condensed here) found:

1. **No shared tinted-square-with-icon widget exists.** `lib/shared/widgets/mx_icon.dart` is a bare glyph (no box, no fill). `lib/shared/widgets/mx_badge.dart` is a label pill, not an icon well.
2. **A feature-local near-duplicate exists and must NOT be touched or migrated by this task**: `lib/features/deck/presentation/widgets/items/deck_icon_area_widget.dart` (`DeckIconArea`). It renders a rounded square + centered `MxIcon` at 48dp (`AppSizing.touchTarget`, not 44), filled with `surfaceMuted` (a neutral well), glyph tinted via `AppInk.accent` — a design deliberately chosen over eight tried recipes, including several tinted-primary-fill variants, on 2026-09-10 (see that file's docstring history). The v3 `IconTile` contract asks for the *opposite* recipe (tinted primary fill). This is a real, documented direction change that belongs to a future call-site migration task, not this one. **Do not edit `deck_icon_area_widget.dart`.**
3. **No existing "tint at X%" shared helper.** The established idiom, used by `app_navigation_bar_theme.dart`'s indicator pill and `app_chip_theme.dart`'s private `_tint`, is `Color.alphaBlend(tint.withValues(alpha: pct), knownGround)` — never a bare translucent color assigned to a `color:`/`decoration:` field.
4. **`AppRadius.sm` (8) already documents pairing with a 28dp icon tile**; `AppRadius.md` (12) is the generic small-control radius. `AppIconSize.sm` (16) and `AppIconSize.mdCompact` (20) already match the two glyph steps the contract asks for. No existing token matches the 28/36/44 box sizes — Task 1 adds them as private, widget-owned constants (the `DeckIconArea.dimension` / `MxIconSize` precedent), not as new `AppSizing` ladder members (`AppSizing`'s own header argues against inventing ladder rungs a single caller uses).
5. **Widgetbook, feature-flat convention:** shared widgets register a `WidgetbookComponent xComponent()` function (see `badgeComponent()` / `listTileComponent()` in `widgetbook/lib/components/form_components.dart`, `iconComponent()` in `control_components.dart`) added to the `'Components'` list in `widgetbook/lib/main.dart`. No codegen involved — plain function registration.

## Global Constraints

1. **Reuse existing tokens; add nothing to the theme.** Box/radius/glyph-size steps: `sm` → box 28 (new, widget-owned) · radius `AppRadius.sm` (8) · glyph `AppIconSize.sm` (16); `md` → box 36 (new) · radius `AppRadius.md` (12) · glyph `AppIconSize.mdCompact` (20); `lg` → box 44 (new) · radius `AppRadius.md` (12) · glyph `AppIconSize.mdCompact` (20). The three box values are declared once, as fields on the size enum this task creates — never inline literals at more than one site.
2. **Default tile tint is `primary` at 10% light / 16% dark; seeded tile tint is the caller's `seed` at a flat 12% in both themes.** Both values are from the theme-prerequisite spec line 354 (`IconTile.default.tile · TINT 10% light / 16% dark`) and line 209 (`seed … tile TINT 12%`). Glyph color: default is `scheme.primary` at full strength (`DIRECT`, no percentage); seeded is the caller's `seed` at full strength. Neither glyph reads `AppInk` — see Constraint 3.
3. **`primary` DIRECT means the raw `ColorScheme.primary`, not `AppInk.accent`.** `AppInk.accent` resolves to `AppSemanticColors.accentInk` (`app_ink.dart:92`), a contrast-lightened variant for text/icon-on-arbitrary-ground use — a *different* value from `ColorScheme.primary`, and the v3 routing table binds this slot to the M3 role directly. Do not route the glyph color through `MxIcon`/`AppInk` for either variant: the seeded case is a genuinely computed, non-nameable color (the exact class of exception `MxIcon`'s own docstring and `mx_pill_button.dart` already document), and the default case would silently substitute `accentInk` for `primary` if routed through `AppInk.accent`. Use a raw `Icon(...)`, matching `MxIcon`'s own `ExcludeSemantics`-when-unlabeled behavior by hand.
4. **`test/app/icon_ink_boundary_test.dart` will flag the raw `Icon(color:)` call** unless `mx_icon_tile.dart` is added to that test's `allowedInKit` map, with a reason in the file's own style (see the existing `mx_pill_button.dart` entry for the shape of the argument: "a colour that is genuinely computed cannot be a name"). This edit is part of Task 1, not a follow-up.
5. **The tile fill must be built as `Color.alphaBlend(tint.withValues(alpha: pct), scheme.surface)`, never a bare translucent `Color` assigned to `decoration.color`.** A raw `.withValues(alpha:)`/`.withOpacity()` value landing directly on a `background`/`border` element outside `lib/core/theme/foundations/app_elevation.dart` and `app_decorations.dart` trips rule R7 (`test/design_audit/color_rule_scope.dart`'s `isTranslucentFillViolation`, enforced by `color_source_rules_test.dart` and the design-audit generator) — the ground is unknown at build time for a widget composed onto arbitrary caller backgrounds, and R7 exists exactly to force a precomputed, single chosen ground instead. **Ruling: the chosen ground is `scheme.surface`** (the base neutral, consistent with `AppDerivedColors.surfaceHero`'s dark-mode base). No caller-supplied ground override — YAGNI; every current and near-term caller (content/settings/deck rows) renders on or close to the base surface, and the visual delta at 10-16% tint between `surface` and a `surfaceContainer*` neighbor is sub-perceptual. Cost if wrong: a real screen shows a visible seam between the tile and its true backdrop; fix is a follow-up `ground` parameter, not a rewrite.
6. **Out of scope, this task only builds the shared widget:** wiring `ListRow`, `SettingsRow`, or migrating `DeckIconArea`'s call sites onto `MxIconTile`. Those widgets do not exist in `lib/` yet (confirmed by the prior-art pass) and are separate components under construction in parallel sessions.
7. **Shrink policy:** the tile itself is fixed-size (`SizedBox.square`) and must never be wrapped in `Flexible`/`Expanded` internally — "shrink: never" is the caller's obligation (give the text column the flexible space), not a behavior this widget implements.
8. **Custom child slot:** the widget accepts exactly one of `icon` (an `IconData`, colored and sized by the tile per Constraint 2/3) or `child` (an arbitrary `Widget`, centered in the tile *without* any color applied — a letter, a count, a donut chart owns its own styling). Enforce with an `assert`, matching the `MxEmptyState` precedent for XOR-style constructor constraints.
9. **House style** (matches the theme-binding plan and repo CLAUDE.md): guard clauses, early return, no `else` after `return`, no magic numbers (name them, with a citation comment to the value's source), no colour literal escaping the file's own named constants, no `DateTime.now()`, keep the file under 400 lines.
10. **Tests:** TDD — write the failing test first. Cover: all three size steps' box/radius/glyph dimensions; default tint composited value in both themes; seeded tint composited value (flat 12%, both themes) with an arbitrary seed color; glyph color equals `scheme.primary` (default) / `seed` (seeded) exactly, not `AppInk.accent.resolve(context)`; semantics (`null` `semanticLabel` excludes the glyph, a provided one is spoken — mirroring `mx_icon_test.dart`); the `icon`/`child` XOR assertion fires correctly in both violated directions; a `child` renders untouched (no color forced onto it).
11. **Verification before every commit** — all must pass, and the report quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
    - `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` (this task creates a file)
    - then `git checkout -- design_audit/` — the suite rewrites those tracked reports.
    - `cd widgetbook && flutter analyze --no-fatal-infos && flutter test --reporter failures-only` after the catalog entry is added.
    Never run `--update-goldens`: this task adds no golden test (no screen renders `MxIconTile` yet).
12. **Commits:** Conventional Commits, scope `design-system`, ending with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. Do not push, open PRs, or dispatch subagents (the controller running this plan does that).

---

### Task 1: `MxIconTile` — widget, tests, boundary allowlist, Widgetbook entry

**Files:**
- Create: `lib/shared/widgets/mx_icon_tile.dart`
- Create: `test/shared/widgets/mx_icon_tile_test.dart`
- Modify: `test/app/icon_ink_boundary_test.dart` (add `mx_icon_tile.dart` to `allowedInKit`)
- Modify: `widgetbook/lib/components/structure_components.dart` (add `iconTileComponent()` — this file already holds the kit's other "surfaces, rows & content" catalog entries; if inspection shows a better-fitting existing file, use that one instead and say so in the report)
- Modify: `widgetbook/lib/main.dart` (register `iconTileComponent()` in the `'Components'` list, alongside `badgeComponent()`/`listTileComponent()`)

**Interfaces:**
- Consumes: `Theme.of(context).colorScheme.primary`, `.surface`, `.brightness`; `AppRadius.sm`/`.md`; `AppIconSize.sm`/`.mdCompact`.
- Produces: `MxIconTile({IconData? icon, Widget? child, MxIconTileSize size = .md, Color? seed, String? semanticLabel})`, `enum MxIconTileSize { sm, md, lg }` with `box`/`radius`/`glyphSize` fields.

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_icon_tile_test.dart` — follow `test/shared/widgets/mx_icon_test.dart`'s `pump()` helper shape (wrap in `MaterialApp(theme: buildLightTheme()/buildDarkTheme(), home: Scaffold(...))`). Cover, as separate `testWidgets`:

```dart
// Dimensions per size step
for each MxIconTileSize step:
  pump MxIconTile(icon: Icons.folder, size: step)
  expect the DecoratedBox/SizedBox extent == step's box
  expect the BoxDecoration.borderRadius == BorderRadius.circular(step's radius)
  expect the Icon.size == step's glyphSize

// Default tint, both themes
pump under buildLightTheme(): expect fill color ==
  Color.alphaBlend(lightColorScheme.primary.withValues(alpha: 0.10), lightColorScheme.surface)
pump under buildDarkTheme(): expect fill color ==
  Color.alphaBlend(darkColorScheme.primary.withValues(alpha: 0.16), darkColorScheme.surface)
expect the Icon.color == colorScheme.primary in both themes (not AppInk.accent.resolve(context) —
  assert the two differ in this theme, so the test cannot pass by accident if a future edit swaps one for the other)

// Seeded tint, both themes, flat 12%
const seed = Color(0xFF2E7D32); // arbitrary, documented as a probe value
pump MxIconTile(icon: ..., seed: seed) under both themes:
  expect fill color == Color.alphaBlend(seed.withValues(alpha: 0.12), colorScheme.surface)
  expect Icon.color == seed

// Semantics — mirror mx_icon_test.dart's two cases exactly, against MxIconTile(icon: ...)

// icon/child XOR
expect(() => MxIconTile(), throwsAssertionError);          // neither
expect(() => MxIconTile(icon: Icons.tag, child: Text('x')), throwsAssertionError); // both

// child renders untouched
pump MxIconTile(child: const Text('A')):
  find.text('A') exists; no Icon widget is built; the child's own style is unmodified
  (assert no color was forced by checking the child is the exact widget instance passed, findsOneWidget)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart -r failures-only`
Expected: compile FAIL — `MxIconTile` and `MxIconTileSize` are not defined.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_icon_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';

/// The three fixed geometries `MxIconTile` paints — box, corner radius and
/// glyph size, one rung per row context the v3 registry names it for.
///
/// Box values have no shared ladder entry (`AppRadius.sm`'s own doc already
/// names 28dp as the icon-tile pairing, but nothing declares the box itself);
/// they are owned here, the same way `DeckIconArea.dimension` and
/// `MxIconSize` each hold a widget-local dimension rather than growing
/// `AppSizing` a rung only one caller uses.
enum MxIconTileSize {
  /// 28 box · radius 8 — content rows, move targets.
  sm(box: 28, radius: AppRadius.sm, glyphSize: AppIconSize.sm),

  /// 36 box · radius 12 — settings rows, sheet commands.
  md(box: 36, radius: AppRadius.md, glyphSize: AppIconSize.mdCompact),

  /// 44 box · radius 12 — deck rows, at every depth.
  lg(box: 44, radius: AppRadius.md, glyphSize: AppIconSize.mdCompact);

  const MxIconTileSize({
    required this.box,
    required this.radius,
    required this.glyphSize,
  });

  final double box;
  final double radius;
  final double glyphSize;
}

/// The tinted square that leads a row: [ListRow]'s and [SettingsRow]'s
/// leading visual (once those exist), and the deck row's icon well at
/// [MxIconTileSize.lg].
///
/// **A surface, not a control** — no interaction state, no touch target of
/// its own; the row around it owns tapping. **Never shrinks**: it is always
/// [SizedBox.square]-sized to [MxIconTileSize.box], and the caller's row
/// gives the *text* column the flexible space instead.
///
/// **Two tint variants, not a theme role each.** `primary` at 10% light /
/// 16% dark is the default; a caller-supplied [seed] (a per-deck colour,
/// never a theme field — `seed` is `COMPONENT_INPUT`) replaces it at a flat
/// 12% in both themes. Composited via `Color.alphaBlend` against
/// [ColorScheme.surface] rather than left translucent: a bare
/// `.withValues(alpha:)` on a background element trips rule R7 the moment
/// the file is not `app_elevation.dart`/`app_decorations.dart` — the R7
/// argument is precisely this widget's situation (composed on an unknown
/// caller ground) — so the ground is chosen once, here, rather than left to
/// whatever is behind the row at paint time.
///
/// **The glyph bypasses `AppInk` on purpose.** `AppInk.accent` is
/// `accentInk`, a contrast-lightened value distinct from `ColorScheme.primary`
/// — this component's glyph is bound to the M3 role directly, and a `seed`
/// glyph is a genuinely computed colour with no name to give it, the same
/// exception `mx_pill_button.dart` already carries
/// (`test/app/icon_ink_boundary_test.dart`'s `allowedInKit`).
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    this.icon,
    this.child,
    this.size = MxIconTileSize.md,
    this.seed,
    this.semanticLabel,
    super.key,
  }) : assert(
         (icon == null) != (child == null),
         'Provide exactly one of icon or child: the glyph slot cannot be '
         'empty, and a custom child already owns its own styling — a second '
         'icon would be a second, conflicting glyph.',
       );

  /// The glyph, coloured and sized by this tile. Mutually exclusive with
  /// [child].
  final IconData? icon;

  /// A caller-supplied replacement for the glyph — a letter, a count, a
  /// donut — centred in the tile with no colour applied by this widget.
  /// Mutually exclusive with [icon].
  final Widget? child;

  final MxIconTileSize size;

  /// A per-deck colour that replaces the default `primary` tint. Never a
  /// theme field — this is the caller's to pass per instance.
  final Color? seed;

  /// Read by screen readers when [icon] carries meaning of its own; null
  /// (the default) excludes the glyph from semantics, matching [MxIcon]'s
  /// rule that a glyph beside a label already saying the thing stays silent.
  /// Ignored when [child] is given — the child speaks for itself.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tintSource = seed ?? scheme.primary;
    final double tintAlpha = seed != null
        ? _seedTintAlpha
        : (scheme.brightness == Brightness.dark
              ? _defaultTintAlphaDark
              : _defaultTintAlphaLight);
    final Color tileColor = Color.alphaBlend(
      tintSource.withValues(alpha: tintAlpha),
      scheme.surface,
    );

    return SizedBox.square(
      dimension: size.box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(size.radius),
        ),
        child: Center(child: child ?? _glyph(tintSource)),
      ),
    );
  }

  Widget _glyph(Color color) {
    final Widget rendered = Icon(
      icon,
      size: size.glyphSize,
      color: color,
      semanticLabel: semanticLabel,
    );
    if (semanticLabel != null) return rendered;

    return ExcludeSemantics(child: rendered);
  }
}

/// `IconTile.default.tile` — `primary` TINT 10% light / 16% dark
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md:354).
const double _defaultTintAlphaLight = 0.10;
const double _defaultTintAlphaDark = 0.16;

/// `seed … tile TINT 12%` — flat across both themes
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md:209).
const double _seedTintAlpha = 0.12;
```

Then, in `test/app/icon_ink_boundary_test.dart`'s `allowedInKit` map, add:

```dart
    'mx_icon_tile.dart':
        'the glyph colour is the tile\'s own computed tint (`primary` or a '
        'caller `seed`), never a nameable AppInk — the same exception '
        'mx_pill_button.dart already carries.',
```

- [ ] **Step 4: Run the target test, then the full gate**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart test/app/icon_ink_boundary_test.dart -r failures-only` → PASS.
Then Global Constraint 11 in full.

- [ ] **Step 5: Widgetbook catalog entry**

Add to `widgetbook/lib/components/structure_components.dart` (or the better-fitting file found on inspection):

```dart
WidgetbookComponent iconTileComponent() {
  return WidgetbookComponent(
    name: 'MxIconTile',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final size = context.knobs.list<MxIconTileSize>(
            label: 'size',
            options: MxIconTileSize.values,
            initialOption: MxIconTileSize.md,
          );
          final seeded = context.knobs.boolean(label: 'seeded', initialValue: false);

          return CatalogCenterPage(
            child: MxIconTile(
              icon: Icons.folder,
              size: size,
              seed: seeded ? Colors.teal : null,
            ),
          );
        },
      ),
      // The three sizes side by side, default tint.
      WidgetbookUseCase(
        name: 'Sizes',
        builder: (BuildContext context) => const CatalogCenterPage(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MxIconTile(icon: Icons.style, size: MxIconTileSize.sm),
              SizedBox(width: AppSpacing.md),
              MxIconTile(icon: Icons.settings, size: MxIconTileSize.md),
              SizedBox(width: AppSpacing.md),
              MxIconTile(icon: Icons.folder, size: MxIconTileSize.lg),
            ],
          ),
        ),
      ),
    ],
  );
}
```

Adjust imports/spacing token to match whatever the chosen catalog file already imports. Register `iconTileComponent()` in `widgetbook/lib/main.dart`'s `'Components'` list, next to `badgeComponent()`/`listTileComponent()`.

- [ ] **Step 6: Run the widgetbook gate**

`cd widgetbook && flutter analyze --no-fatal-infos && flutter test --reporter failures-only` → clean.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/mx_icon_tile.dart test/shared/widgets/mx_icon_tile_test.dart test/app/icon_ink_boundary_test.dart widgetbook/lib
git commit -m "feat(design-system): MxIconTile — the tinted square leading a row

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```
