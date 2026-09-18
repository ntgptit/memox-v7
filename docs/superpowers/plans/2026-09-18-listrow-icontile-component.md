# ListRow + IconTile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Superseded in part (2026-09-19):** Task 1 (`MxIconTile`, sm-only) was overtaken by PR #587 (M100.110), which merged a fuller `MxIconTile` (sm/md/lg, `child` slot) first. This branch dropped its own and `MxListRow` composes #587's with `size: MxIconTileSize.sm`. Also: `showDivider` shipped as `hasDivider`, the constructor asserts were removed, and the title style is `AppTextStyles.listRowTitle`.

**Goal:** Add `MxListRow` — the single-line, ellipsised CONTENT row behind decks/search results/tags/cards — and its required leading child `MxIconTile`, as new shared `lib/shared/widgets/` components.

**Architecture:** Two new flat `Mx*` shared widgets, no new layers. `MxIconTile` is a 28dp tinted glyph well (`default` tone tints `primary`, `seeded` tone tints a caller-supplied `Color`). `MxListRow` composes `MxIconTile` as its default leading slot, reads `onSurface`/`onSurfaceVariant`/`border-ghost`/`op-press` directly from the theme, and optionally wraps itself in a tappable `InkWell` when the caller passes `onTap` — otherwise it is inert content.

**Tech Stack:** Flutter (stable), Riverpod not involved (stateless presentational widgets only), the app's existing `lib/core/theme/` token/extension layer, Widgetbook for the catalogue.

**Spec:** The ListRow design handoff (pasted into this session's command arguments — MemoX v3 HTML design kit · D · Surfaces, rows & content) plus `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` (the already-merged v3 theme binding this component reads from, PR #570).

## Global Constraints

- **Naming:** shared design-system widgets live flat in `lib/shared/widgets/mx_*.dart`, class `Mx<PascalCase>` — no subfolders, matching `MxCard`/`MxListTile`/`MxIcon`.
- **Theme access only through `context.colors` / `context.texts`** (`lib/core/theme/extensions/theme_context_extension.dart`) — never `Theme.of(context)` directly, never a hardcoded hex.
- **`border-ghost`** → `AppDecorations.hairlineEdge(ColorScheme)` (`lib/core/theme/foundations/app_decorations.dart`) — returns a `BorderSide`, used as `Border(bottom: ...)`.
- **`op-press` (0.12)** → row overlay via `AppInteractionStates.rowOverlay(scheme)` (`lib/core/theme/states/app_interaction_states.dart`) — same helper `MxListTile` already uses for hover/focus/press.
- **`onSurface` / `onSurfaceVariant`** → `context.colors.onSurface` / `context.colors.onSurfaceVariant` directly (plain M3 `ColorScheme` fields, `FULL_STRENGTH`).
- **Dimensions:** `AppSpacing.md` = 12, `AppSpacing.lg` = 16 (`lib/core/theme/foundations/app_spacing.dart`); `AppSizing.touchTarget` = 48 (`lib/core/theme/foundations/app_sizing.dart`); `AppRadius.sm` = 8, whose own doc comment names it "icon tile (28dp)" (`lib/core/theme/foundations/app_radius.dart`); `AppIconSize.mdCompact` = 20, "the compact rows' step" (`lib/core/theme/foundations/app_icon_size.dart`).
- **No raw `Color`/hex literals** outside the one documented `COMPONENT_INPUT` escape hatch (`seed: Color?`, exactly like `DeckIconArea.wellColor` already does at `lib/features/deck/presentation/widgets/items/deck_icon_area_widget.dart:75`). Every other colour is a direct `ColorScheme` field.
- **Icon meaning → Material Symbol**, already established elsewhere in this repo — reuse, do not invent: chevron-right → `Icons.chevron_right` (`lib/features/search/presentation/widgets/items/search_result_shell_widget.dart:94`), more-vertical → `Icons.more_vert` (`lib/features/deck/presentation/widgets/items/deck_tile_widget.dart:153`), layers → `Icons.layers_outlined` (`lib/features/card/presentation/widgets/sections/card_editor_context_widget.dart:161`), tag → `Icons.sell_outlined` (`lib/features/card/presentation/widgets/items/tag_catalog_row_widget.dart:157`), file-text → `Icons.description_outlined` (`lib/features/card/presentation/widgets/sections/card_import_source_summary_widget.dart:71`).
- **Title typography** is a component-level override of the "body" role (v3 spec §7 explicitly sanctions this): `context.texts.bodyMedium!.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.35)`, coloured `onSurface`. **Sub typography** is the existing "caption" role unmodified: `context.texts.bodySmall!`, coloured `onSurfaceVariant`.
- **`MxListTile` (`lib/shared/widgets/mx_list_tile.dart`) is NOT the base for `MxListRow`.** It is explicitly the SettingsRow-shaped generic row (2-line title, full `ListTileThemeData`-driven selection semantics, own touch target). `MxListRow` is single-line, has no selection concept, and owns its own layout — do not extend or wrap `MxListTile`.
- **`MxIconTile` scope ruling (already made, do not reopen):** implement only the `size=sm` (28dp) variant with `default` and `seeded` tones. Do not add a `size` parameter or enum — a `md` step belongs to whichever future task gives `SettingsRow` its own leading tile; adding it here would be an unparameterised guess with no second caller to check it against.
- **Widgetbook registration:** add a `WidgetbookComponent` builder function per component to `widgetbook/lib/components/form_components.dart` (mirror `listTileComponent()` at line 557), and register the call in `widgetbook/lib/main.dart`'s `Components` category list (after `listTileComponent()`). Required by `test/app/widgetbook_coverage_test.dart`, which fails on any `Mx*` class with no `name: 'ClassName'` string under `widgetbook/lib/`.
- **Stress-suite coverage:** `test/shared/widgets/mx_stress_test.dart` requires every `lib/shared/widgets/*.dart` class to appear in `stressSpecimens()` or be in its fixed 12-item exclusion list. `mx_stress_specimens.dart` is already 500 lines (the guard's own split point) — add the two new specimens to `test/shared/widgets/mx_stress_owner_specimens.dart` instead (currently 25 lines), importing `kLongTitle`/`kLongMessage` from `mx_stress_specimens.dart` as it already does.
- **No component-level golden PNGs.** `test/shared/widgets/mx_components_golden_test.dart` is a curated, fixed list (no directory-coverage scan), so it does not fail for a new component with no entry. Golden-image authoring needs the Linux/WSL path this plan does not require — do not attempt it on Windows.
- **File size guard:** keep every new/modified file under 400 lines (repo's `code-verification-guard-v2` rule).
- **Verification per task:** `flutter analyze` (zero errors and warnings) and the task's own new/changed test files, run with `flutter test <path>`.

---

## Task 1: MxIconTile

**Files:**
- Create: `lib/shared/widgets/mx_icon_tile.dart`
- Create: `test/shared/widgets/mx_icon_tile_test.dart`
- Modify: `widgetbook/lib/components/form_components.dart` (add `iconTileComponent()`)
- Modify: `widgetbook/lib/main.dart` (register `iconTileComponent()`)
- Modify: `test/shared/widgets/mx_stress_owner_specimens.dart` (add an `MxIconTile` specimen)

**Interfaces:**
- Produces: `class MxIconTile extends StatelessWidget` with `const MxIconTile({required IconData icon, Color? seed, String? semanticLabel, Key? key})` and `static const double dimension = 28`. No other public members. Task 2 constructs it as `MxIconTile(icon: ..., seed: ...)`.

- [ ] **Step 1: Write `lib/shared/widgets/mx_icon_tile.dart`**

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';

/// The 28dp tinted glyph well that leads an [MxListRow] — and, later,
/// `SettingsRow`'s own leading slot, once that component's task extends it.
///
/// **One size today.** `AppRadius.sm`'s own doc comment already names "icon
/// tile (28dp)" as the v3 Radius table's 8 — this widget is that tile, sized
/// [dimension]. A `md` step belongs to whichever task gives `SettingsRow` its
/// own leading tile; adding an unused second size here would be a guess this
/// component has no second caller to check it against.
///
/// **Two tones, not a theme field.** `primary-soft` — the general "tint
/// primary and box it" token — is deliberately absent from the theme:
/// several components each tint `primary` at their own percentage instead
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.3).
/// This tile's own recipe: the `default` tone tints `primary` at 10% (light)
/// / 16% (dark); the `seeded` tone tints the caller's [seed] at a flat 12% in
/// both themes. Either way the glyph paints in the same source colour at full
/// strength — never a separate derived ink — which is what the spec's "tile
/// TINT, glyph FULL_STRENGTH" pairing means (spec §5.7).
class MxIconTile extends StatelessWidget {
  const MxIconTile({required this.icon, this.seed, this.semanticLabel, super.key});

  /// The tile's square edge.
  static const double dimension = 28;

  final IconData icon;

  /// A per-instance colour — a per-deck tint, typically. `null` keeps the
  /// neutral brand-tinted `default` tone. Never stored in the theme: the
  /// caller (`MxListRow.seed`, forwarded unchanged) owns it per instance.
  final Color? seed;

  /// Read by screen readers; `null` excludes the glyph from semantics
  /// entirely — the usual case, since the tile sits beside a title that
  /// already names the row.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = context.colors;
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color source = seed ?? scheme.primary;
    final double tintAlpha = seed != null
        ? _seededTintAlpha
        : (isDark ? _defaultTintDarkAlpha : _defaultTintLightAlpha);
    final Color fill = Color.alphaBlend(
      source.withValues(alpha: tintAlpha),
      scheme.surface,
    );

    final Widget glyph = Icon(
      icon,
      size: AppIconSize.mdCompact,
      color: source,
      semanticLabel: semanticLabel,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: semanticLabel == null
              ? ExcludeSemantics(child: glyph)
              : glyph,
        ),
      ),
    );
  }
}

const double _defaultTintLightAlpha = 0.10;
const double _defaultTintDarkAlpha = 0.16;
const double _seededTintAlpha = 0.12;
```

- [ ] **Step 2: Write `test/shared/widgets/mx_icon_tile_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

void main() {
  group('MxIconTile', () {
    testWidgets('sizes the tile at 28x28', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxIconTile(icon: Icons.layers_outlined),
          ),
        ),
      );

      expect(tester.getSize(find.byType(MxIconTile)), const Size(28, 28));
    });

    testWidgets(
      'default tone tints the fill and glyph with primary, light theme',
      (tester) async {
        final ThemeData theme = buildLightTheme();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: MxIconTile(icon: Icons.layers_outlined)),
          ),
        );

        final DecoratedBox box = tester.widget(find.byType(DecoratedBox));
        final BoxDecoration decoration = box.decoration as BoxDecoration;
        final Color expectedFill = Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.10),
          theme.colorScheme.surface,
        );
        expect(decoration.color, expectedFill);

        final Icon icon = tester.widget(find.byType(Icon));
        expect(icon.color, theme.colorScheme.primary);
      },
    );

    testWidgets('default tone tints at 16% in dark theme', (tester) async {
      final ThemeData theme = buildDarkTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: MxIconTile(icon: Icons.layers_outlined)),
        ),
      );

      final DecoratedBox box = tester.widget(find.byType(DecoratedBox));
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      final Color expectedFill = Color.alphaBlend(
        theme.colorScheme.primary.withValues(alpha: 0.16),
        theme.colorScheme.surface,
      );
      expect(decoration.color, expectedFill);
    });

    testWidgets('seeded tone tints the fill and glyph with the seed colour', (
      tester,
    ) async {
      const Color seed = Color(0xFF5265F5);
      final ThemeData theme = buildLightTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: MxIconTile(icon: Icons.layers_outlined, seed: seed),
          ),
        ),
      );

      final DecoratedBox box = tester.widget(find.byType(DecoratedBox));
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      final Color expectedFill = Color.alphaBlend(
        seed.withValues(alpha: 0.12),
        theme.colorScheme.surface,
      );
      expect(decoration.color, expectedFill);

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.color, seed);
    });

    testWidgets('null semanticLabel excludes the glyph from semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxIconTile(icon: Icons.layers_outlined)),
        ),
      );

      expect(find.byType(ExcludeSemantics), findsOneWidget);
      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.semanticLabel, isNull);
    });

    testWidgets('a semanticLabel is forwarded to the glyph, not excluded', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxIconTile(
              icon: Icons.layers_outlined,
              semanticLabel: 'Vocabulary deck',
            ),
          ),
        ),
      );

      expect(find.byType(ExcludeSemantics), findsNothing);
      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.semanticLabel, 'Vocabulary deck');
    });
  });
}
```

- [ ] **Step 3: Run the new test**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart`
Expected: all 6 tests PASS.

- [ ] **Step 4: Add the Widgetbook entry**

In `widgetbook/lib/components/form_components.dart`, add near `listTileComponent()`:

```dart
WidgetbookComponent iconTileComponent() {
  return WidgetbookComponent(
    name: 'MxIconTile',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final isSeeded = context.knobs.boolean(
            label: 'seeded',
            initialValue: false,
          );

          return Scaffold(
            body: Center(
              child: MxIconTile(
                icon: Icons.layers_outlined,
                seed: isSeeded ? const Color(0xFF5265F5) : null,
              ),
            ),
          );
        },
      ),
    ],
  );
}
```

Add the import `import 'package:memox/shared/widgets/mx_icon_tile.dart';` alongside the file's other `mx_*` imports.

In `widgetbook/lib/main.dart`, add `iconTileComponent(),` to the `Components` category list, immediately after `listTileComponent(),`.

- [ ] **Step 5: Add the stress specimen**

In `test/shared/widgets/mx_stress_owner_specimens.dart`, add the import
`import 'package:memox/shared/widgets/mx_icon_tile.dart';` and append to the
returned list:

```dart
  MxStressSpecimen(
    name: 'MxIconTile',
    build: () => const MxIconTile(icon: Icons.layers_outlined),
  ),
```

- [ ] **Step 6: Run analyze and the full widget/catalogue/stress gates**

Run:
```bash
flutter analyze
flutter test test/shared/widgets/mx_icon_tile_test.dart test/app/widgetbook_coverage_test.dart
flutter test test/shared/widgets/mx_stress_test.dart
```
Expected: zero analyzer issues; all tests PASS (stress suite includes the new `MxIconTile` cases across every width/scale/theme combination it runs).

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/mx_icon_tile.dart test/shared/widgets/mx_icon_tile_test.dart test/shared/widgets/mx_stress_owner_specimens.dart widgetbook/lib/components/form_components.dart widgetbook/lib/main.dart
git commit -m "feat(design-system): add MxIconTile, ListRow's leading tile"
```

---

## Task 2: MxListRow

**Files:**
- Create: `lib/shared/widgets/mx_list_row.dart`
- Create: `test/shared/widgets/mx_list_row_test.dart`
- Modify: `widgetbook/lib/components/form_components.dart` (add `listRowComponent()`)
- Modify: `widgetbook/lib/main.dart` (register `listRowComponent()`)
- Modify: `test/shared/widgets/mx_stress_owner_specimens.dart` (add an `MxListRow` specimen)

**Interfaces:**
- Consumes: `MxIconTile` from Task 1 — `MxIconTile({required IconData icon, Color? seed, String? semanticLabel})`, `MxIconTile.dimension == 28`.
- Produces: `class MxListRow extends StatelessWidget` with `const MxListRow({required String title, String? subtitle, Widget? leading, IconData? leadingIcon, Color? seed, Widget? trailing, IconData? trailingIcon, VoidCallback? onTap, bool showDivider = true, String? semanticLabel, Key? key})`.

- [ ] **Step 1: Write `lib/shared/widgets/mx_list_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';
import 'mx_icon.dart';
import 'mx_icon_tile.dart';

/// The content row behind decks, search results, tags and cards.
///
/// **Deliberately not `MxListTile`.** `MxListTile`
/// (`lib/shared/widgets/mx_list_tile.dart`) is the ordinary navigation,
/// settings, control or choice row — two-line title, `ListTileThemeData`
/// geometry, tri-state selection. `MxListRow` is a piece of *content*: title
/// and sub are both exactly one line so every row in a list is the same
/// height, and it carries no selection concept at all.
///
/// **A surface, not a control.** This widget owns its own geometry, spacing,
/// content slots and long-content behaviour — never a touch target of its
/// own. [onTap] is the one exception the contract itself asks for: the row
/// reads `op-press` directly (spec's Theme consumption table), so when a
/// caller passes it the row paints the same pressed/hover/focus overlay
/// every other row in the app uses
/// ([AppInteractionStates.rowOverlay]) and exposes itself as a button. A
/// `null` [onTap] renders plain, inert content — no ripple, no focus ring,
/// no button semantics.
class MxListRow extends StatelessWidget {
  const MxListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingIcon,
    this.seed,
    this.trailing,
    this.trailingIcon,
    this.onTap,
    this.showDivider = true,
    this.semanticLabel,
    super.key,
  }) : assert(
         leading == null || leadingIcon == null,
         'Pass either leading or leadingIcon, not both — leading replaces '
         'the default tile entirely.',
       ),
       assert(
         trailing == null || trailingIcon == null,
         'Pass either trailing or trailingIcon, not both — trailing '
         'replaces the default glyph entirely.',
       );

  /// Already-localized. One line, ellipsised — a long title is cut, never
  /// wrapped, so every row in a list stays the same height.
  final String title;

  /// Already-localized. One line, ellipsised, 2dp below the title.
  final String? subtitle;

  /// Replaces the default leading tile entirely — "any node may replace
  /// it" is the contract's own wording. Takes priority over [leadingIcon].
  final Widget? leading;

  /// Builds the default leading tile as `MxIconTile(icon: leadingIcon, seed:
  /// seed)`. Ignored when [leading] is supplied. `null` (with no [leading]
  /// either) renders no leading slot.
  final IconData? leadingIcon;

  /// Forwarded unchanged to `MxIconTile.seed` — this row never paints it
  /// itself. Ignored unless [leadingIcon] is building the default tile.
  final Color? seed;

  /// Replaces the default trailing glyph entirely — a spinner for the busy
  /// state, or any other presentational node. Takes priority over
  /// [trailingIcon]. Keeps its own width; only the text column gives up
  /// space to a long title.
  final Widget? trailing;

  /// Builds the default trailing glyph as `MxIcon(trailingIcon, ink:
  /// AppInk.quiet, size: MxIconSize.mdCompact)` — the row resolves
  /// `onSurfaceVariant` itself here, the one DIRECT theme role this row
  /// owns beyond title/sub/divider. Ignored when [trailing] is supplied.
  /// `null` (with no [trailing] either) renders no trailing slot.
  final IconData? trailingIcon;

  /// `null` renders the row as plain content. Non-null exposes the row as a
  /// button with the app's standard row press/hover/focus overlay.
  final VoidCallback? onTap;

  /// `false` omits the bottom hairline — pass it for the last row in a
  /// list. The row does not know its own position in a list, so the caller
  /// decides.
  final bool showDivider;

  /// `null` lets the title (and subtitle, if present) be read as separate
  /// nodes. Set it when the tappable row's target needs one merged
  /// announcement instead.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = context.colors;
    final String? subtitleText = subtitle;
    final Widget? leadingWidget =
        leading ??
        (leadingIcon != null
            ? MxIconTile(icon: leadingIcon!, seed: seed)
            : null);
    final Widget? trailingWidget =
        trailing ??
        (trailingIcon != null
            ? MxIcon(
                trailingIcon!,
                ink: AppInk.quiet,
                size: MxIconSize.mdCompact,
              )
            : null);

    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (leadingWidget != null) ...<Widget>[
              leadingWidget,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      height: 1.35,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (subtitleText != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              trailingWidget,
            ],
          ],
        ),
      ),
    );

    final Widget bordered = showDivider
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: AppDecorations.hairlineEdge(scheme)),
            ),
            child: row,
          )
        : row;

    final VoidCallback? tap = onTap;
    if (tap == null) return bordered;

    final WidgetStateProperty<Color?> overlay = AppInteractionStates.rowOverlay(
      scheme,
    );
    final Widget semanticContent = semanticLabel != null
        ? ExcludeSemantics(child: bordered)
        : bordered;

    return MxFocusRing(
      // Square, like the row — the same call `MxListTile` makes for the
      // same reason: the ring traces the shape the ink takes.
      borderRadius: BorderRadius.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: tap,
          hoverColor: overlay.resolve(const <WidgetState>{WidgetState.hovered}),
          focusColor: overlay.resolve(const <WidgetState>{WidgetState.focused}),
          splashColor: overlay.resolve(const <WidgetState>{WidgetState.pressed}),
          highlightColor: Colors.transparent,
          child: Semantics(
            button: true,
            label: semanticLabel,
            child: semanticContent,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run it against Task 1's test to make sure nothing regressed**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart`
Expected: still PASS (Task 2 does not modify `mx_icon_tile.dart`).

- [ ] **Step 3: Write `test/shared/widgets/mx_list_row_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_icon.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

void main() {
  group('MxListRow content', () {
    testWidgets('renders title and subtitle, each one line with ellipsis', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(title: 'Academic Word List', subtitle: '120 cards'),
          ),
        ),
      );

      final Text title = tester.widget(find.text('Academic Word List'));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);

      final Text subtitle = tester.widget(find.text('120 cards'));
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets('omits the subtitle row when none is given', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('is at least 48dp tall with only a title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      final Size size = tester.getSize(find.byType(MxListRow));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('leadingIcon builds the default MxIconTile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              leadingIcon: Icons.layers_outlined,
            ),
          ),
        ),
      );

      expect(find.byType(MxIconTile), findsOneWidget);
    });

    testWidgets('leading overrides the default tile entirely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              leadingIcon: Icons.layers_outlined,
              leading: const Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.byType(MxIconTile), findsNothing);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders no leading slot when neither is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      expect(find.byType(MxIconTile), findsNothing);
    });

    testWidgets('trailing overrides the default glyph entirely', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              trailingIcon: Icons.chevron_right,
              trailing: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'trailingIcon builds the default glyph, coloured onSurfaceVariant',
      (tester) async {
        final ThemeData theme = buildLightTheme();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: MxListRow(
                title: 'Academic Word List',
                trailingIcon: Icons.chevron_right,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        final Icon icon = tester.widget(find.byIcon(Icons.chevron_right));
        expect(icon.color, theme.colorScheme.onSurfaceVariant);
      },
    );

    testWidgets('renders no trailing slot when neither is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      expect(find.byType(MxIcon), findsNothing);
    });
  });

  group('MxListRow divider', () {
    testWidgets('shows the bottom hairline by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      final DecoratedBox box = tester.widget(find.byType(DecoratedBox).first);
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('omits the hairline when showDivider is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              showDivider: false,
            ),
          ),
        ),
      );

      expect(find.byType(DecoratedBox), findsNothing);
    });
  });

  group('MxListRow tap behaviour', () {
    testWidgets('a null onTap renders plain content: no InkWell, no button semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
      final SemanticsNode? node = tester.getSemantics(
        find.byType(MxListRow),
      );
      expect(node.hasFlag(SemanticsFlag.isButton), isFalse);
    });

    testWidgets('a non-null onTap exposes a button and fires on tap', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(find.byType(MxListRow));
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);

      await tester.tap(find.byType(MxListRow));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('a semanticLabel merges the row into one announced node', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              subtitle: '120 cards',
              onTap: () {},
              semanticLabel: 'Academic Word List, 120 cards',
            ),
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(MxListRow));
      expect(node.label, 'Academic Word List, 120 cards');
    });
  });
}
```

- [ ] **Step 4: Run the new test**

Run: `flutter test test/shared/widgets/mx_list_row_test.dart`
Expected: all tests PASS.

- [ ] **Step 5: Add the Widgetbook entry**

In `widgetbook/lib/components/form_components.dart`, add near `iconTileComponent()`:

```dart
WidgetbookComponent listRowComponent() {
  return WidgetbookComponent(
    name: 'MxListRow',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Academic Word List',
          );
          final subtitle = context.knobs.stringOrNull(
            label: 'subtitle',
            initialValue: '120 cards · 8 due',
          );
          final hasLeading = context.knobs.boolean(
            label: 'with leading tile',
            initialValue: true,
          );
          final isSeeded = context.knobs.boolean(
            label: 'seeded leading tile',
            initialValue: false,
          );
          final hasTrailing = context.knobs.boolean(
            label: 'with trailing chevron',
            initialValue: true,
          );
          final isInteractive = context.knobs.boolean(
            label: 'has onTap',
            initialValue: true,
          );
          final showDivider = context.knobs.boolean(
            label: 'show divider',
            initialValue: true,
          );

          return Scaffold(
            body: SafeArea(
              child: Center(
                child: MxListRow(
                  title: title,
                  subtitle: subtitle,
                  leadingIcon: hasLeading ? Icons.layers_outlined : null,
                  seed: isSeeded ? const Color(0xFF5265F5) : null,
                  trailingIcon: hasTrailing ? Icons.chevron_right : null,
                  onTap: isInteractive ? _noop : null,
                  showDivider: showDivider,
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
```

Add the import `import 'package:memox/shared/widgets/mx_list_row.dart';`. Reuse the file's existing private `_noop()` function (already defined for `listTileComponent()`) — do not redeclare it.

In `widgetbook/lib/main.dart`, add `iconTileComponent(),` and `listRowComponent(),` to the `Components` category list, immediately after `listTileComponent(),` (in that order).

- [ ] **Step 6: Add the stress specimen**

In `test/shared/widgets/mx_stress_owner_specimens.dart`, add the import
`import 'package:memox/shared/widgets/mx_list_row.dart';` and append:

```dart
  MxStressSpecimen(
    name: 'MxListRow',
    isInteractive: true,
    build: () => MxListRow(
      title: kLongTitle,
      subtitle: kLongMessage,
      leadingIcon: Icons.layers_outlined,
      trailingIcon: Icons.chevron_right,
      onTap: () {},
    ),
  ),
```

- [ ] **Step 7: Run analyze and the full gate**

Run:
```bash
flutter analyze
flutter test test/shared/widgets/mx_icon_tile_test.dart test/shared/widgets/mx_list_row_test.dart test/app/widgetbook_coverage_test.dart
flutter test test/shared/widgets/mx_stress_test.dart
```
Expected: zero analyzer issues; all tests PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/shared/widgets/mx_list_row.dart test/shared/widgets/mx_list_row_test.dart test/shared/widgets/mx_stress_owner_specimens.dart widgetbook/lib/components/form_components.dart widgetbook/lib/main.dart
git commit -m "feat(design-system): add MxListRow, the content row for decks/results/tags/cards"
```

---

## Out of scope, recorded rather than silently dropped

- **`SettingsRow`, `OptionRow`, and IconTile's `size=md` step** belong to their own dedicated tasks/worktrees (`settingsrow-flutter-component-b1be3d`, `optionrow-flutter-component-db7dde` already exist as sibling worktrees). This plan does not touch them.
- **Component-level golden PNGs** for `MxIconTile`/`MxListRow` are not added — `mx_components_golden_test.dart` does not require them, and authoring goldens needs the Linux/WSL path.
- **Wiring `MxListRow` into an existing feature screen** (deck list, search results, tag catalog) is not part of this plan — those screens keep their current hand-rolled rows until a feature task migrates them, which is its own reviewable change.
