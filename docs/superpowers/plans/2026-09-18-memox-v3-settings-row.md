# SettingsRow (v3 component) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **AMENDED after the final whole-branch review passed, before merge.**
> `origin/main` moved 24 commits ahead of this branch's base while this plan
> executed, and it already merged PR #587 (`M100.110`) and PR #588 (`M100.111`)
> — a parallel session's own `MxIconTile` and `MxListRow`, from the same v3
> design-kit batch. **Task 1 below (`MxIconTile`) is VOIDED — `origin/main`'s
> version supersedes it wholesale** (a superset: `size` enum, `seed` support,
> and a cleaner default-silent semantics answer arrived at independently for
> the same "Important" finding this branch's own final review caught). The
> branch was reset to `origin/main` and Task 2 (`MxSettingsRow`, still absent
> from `main`) was rebuilt from scratch composing `origin/main`'s real
> `MxIconTile(icon:, semanticLabel:)` (size defaults to `md` = 36, exactly this
> plan's contract). Full ruling, with the reasoning and what changed
> concretely, is in the SDD ledger
> (`.superpowers/sdd/2026-09-18-memox-v3-settings-row/progress.md`, "Base-shift
> ruling"). Task 1's text below is kept as the historical record of what was
> built and why it was a grounded ruling at the time — it is no longer live
> work. Task 2's text below describes the *original* attempt against the old
> `MxIconTile`; the rebuilt implementation follows `MxListRow`
> (`lib/shared/widgets/mx_list_row.dart`) as its concrete precedent instead —
> notably, it does not need the `MergeSemantics` workaround Task 2's original
> code required, because `origin/main`'s `MxIconTile` never emits a stray
> semantics node when unlabelled in the first place.

**Goal:** Add the `MxSettingsRow` shared component (a settings-screen row: leading
icon tile, label + optional sub-label, and an optional trailing control —
inline, wide, or a navigation chevron), plus its required dependency
`MxIconTile`, to `lib/shared/widgets/`.

**Architecture:** Two small, focused shared widgets in `lib/shared/widgets/`,
each following the interaction-state and theme-consumption idioms
`MxListTile`/`MxSwitchRow` already established (transparent `Material`,
`AppInteractionStates.rowOverlay`, `MxFocusRing`, `.inked()` text styling).
`MxIconTile` is a new shared primitive — it does not exist yet anywhere in the
repo — that `MxSettingsRow` composes via `VIA_COMPONENT` per the frozen theme
spec. No screen is wired to either widget in this plan; that is
`IMPLEMENT_SCREEN` work for later.

**Tech Stack:** Flutter/Dart, the existing `AppSpacing`/`AppRadius`/`AppIconSize`
design-token classes, `AppInk`, `AppInteractionStates`/`AppStateOpacity`,
`context.colors`/`context.texts` (`ThemeContextX`), `flutter_test`.

**Spec:** The component contract handed to this plan (SettingsRow HTML-kit
handoff, `HANDOFF MODE: COMPONENT`), cross-referenced against
`docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` (the frozen
theme-binding prerequisite — §5.5 `op-disabled`, §7 typography roles, §15.1
`onSurface`/`onSurfaceVariant`/`primary` consumers, §15.2 `VIA_COMPONENT`
table) and `docs/design-system/v3-foundations.md` line 293-294 (radius ladder:
icon tile 28 → `AppRadius.sm`, icon tile 36-44 → `AppRadius.md`).

## Global Constraints

- Geometry (verbatim from the component contract): grid `40 lead / 1fr text /
  auto trailing`, gap `16`; padding `12 16`; min height `48`; leading tile `36`
  (md) inside the `40` lead column; label `16/600, -0.1px`, wraps; sub `12
  onSurfaceVariant, 4 below the label, line-height 1.45`; chevron
  `chevron-right 20`, only when the row navigates and has no trailing control;
  wide control drops to its own line, full remaining width, `12` above.
- Token mapping (do not use raw numbers where a token exists): `16` →
  `AppSpacing.lg`, `12` (padding/gap-above-wide-control) → `AppSpacing.md`, `4`
  → `AppSpacing.xs`, `48` (min height) → `AppSizing.touchTarget`, `20`
  (chevron) → `AppIconSize.mdCompact` (via `MxIconSize.mdCompact`), `36`
  (`MxIconTile`'s own size) is a new named constant (no existing token is 36),
  its radius `12` → `AppRadius.md` (`docs/design-system/v3-foundations.md:294`
  — "icon tile 36-44" maps to `AppRadius.md`).
- Theme roles, DIRECT, read only (never redefine): `onSurface` (label, via
  `AppInk.stated`), `onSurfaceVariant` (sub + chevron, via `AppInk.quiet`),
  `primary` (focus ring, via `AppInteractionStates`/`MxFocusRing` — already
  wired), `AppStateOpacity.disabled` (`0.38`, whole-row dim).
- `MxIconTile` (new): `VVIA_COMPONENT` composition target for
  `MxSettingsRow`'s leading slot. Per the frozen spec's role index (line 354),
  its `default` variant reads `primary` DIRECTLY for **both** the tile fill
  (`TINT 10% light / 16% dark`) and the glyph (`FULL_STRENGTH`) — this is
  `context.colors.primary`, not `AppInk.accent` (a different, contrast-tuned
  value; see `lib/core/theme/extensions/app_ink.dart`). Because no `AppInk`
  member equals `primary`, the glyph is a raw `Icon(color: …)`, which requires
  a new entry in `test/app/icon_ink_boundary_test.dart`'s `allowedInKit` map.
  Do not invent a tint percentage — `10%`/`16%` is copied from the spec, not
  guessed.
- **Ruling (recorded before Task 1):** `MxIconTile` does not exist in the repo
  and has no separate component-handoff prompt available in this session, but
  it is a hard `FIXED` dependency of `SettingsRow`'s leading slot and its
  `default` variant (fill %, glyph role, both size steps and their radii) is
  fully specified by the frozen theme-prerequisite spec (§15.1, §15.2) and
  `v3-foundations.md`'s radius table — nothing about it is guessed. Building it
  now, scoped to exactly what `SettingsRow` needs (size `md` = 36, `variant:
  default`, no `seed` input, no `size: sm` step), is therefore a grounded
  ruling, not a stall. `size: sm` (28, for `ListRow`) and the `seed`
  `COMPONENT_INPUT` (per-deck colour, also for `ListRow`) are **out of scope**
  — added by whichever plan builds `ListRow`, following the same "second
  caller shows what varies" rule `lib/features/deck/presentation/widgets/items/deck_icon_area_widget.dart`
  already documents and that this plan's `MxIconTile` mirrors for its *first*
  real call site.
- `MxSettingsRow`'s `trailing` (inline control) and `wideControl` (full-width,
  own-line control) are `COMPONENT_INPUT` — arbitrary caller-supplied
  `Widget`s (e.g. a raw `Switch`, a time-picker button). `MxSettingsRow` does
  not build, colour, or enable/disable them; it only places them. They are
  mutually exclusive (the contract's state matrix has no state combining
  both) — passing both is a programming error, asserted in the constructor.
- Long label / long sub: mirror `MxListTile`'s established, previously-bug-fixed
  convention (`maxLines: 2, overflow: TextOverflow.ellipsis`) rather than
  leaving either unbounded — `MxListTile`'s doc comment records the exact
  failure this guards against (an unbounded subtitle at `textScaler 2.0`
  pushing a trailing control off a 320-wide screen, #431 P2-1). This is an
  `UNSPECIFIED` gap in the component contract, resolved per its own rule
  ("keep the repository's existing convention where that is safe").
- **Do not** wire `MxSettingsRow` into `settings_screen.dart` or any other
  screen. This plan is `IMPLEMENT_COMPONENT` scope only — no screen changes,
  no `test/demo/` goldens, no screen-gallery republish, no
  `integration_test/` run (that gate is scoped to `lib/features/`, which this
  plan does not touch).
- Both widgets are `StatelessWidget`s in `lib/shared/widgets/` (flat directory,
  no AD-15 bucket — that rule is for `lib/features/<feature>/presentation/widgets/`
  only). Filenames: `mx_icon_tile.dart`, `mx_settings_row.dart` — matching the
  existing `mx_*.dart` convention (no `_widget` suffix; that suffix belongs to
  `presentation/` files inside a feature).
- Keep each new/modified test file under the repo's 400-line guard (the reason
  `mx_list_tile_contract_test.dart` exists as a second file); split before that
  point if a task's tests grow past it.
- Every new/modified `.dart` file: `dart format`, then `flutter analyze`
  (zero errors and warnings) before commit.

---

### Task 1: `MxIconTile` — the shared leading-glyph well

**Files:**
- Create: `lib/shared/widgets/mx_icon_tile.dart`
- Create: `test/shared/widgets/mx_icon_tile_test.dart`
- Modify: `test/app/icon_ink_boundary_test.dart` (add one `allowedInKit` entry)
- Modify: `widgetbook/lib/components/form_components.dart` (new
  `iconTileComponent()` function)
- Modify: `widgetbook/lib/main.dart` (register `iconTileComponent()`)

**Interfaces:**
- Produces: `class MxIconTile extends StatelessWidget` with constructor
  `const MxIconTile({required IconData icon, String? semanticLabel, Key? key})`.
  Fixed 36×36 square, `AppRadius.md` corners, `primary` @ 10% light / 16% dark
  fill, `primary` glyph at the default `MxIconSize.md` (24dp, `MxIcon`'s own
  default — this component states no icon-size opinion beyond what `MxIcon`
  already defaults to). No `size`/`variant`/`seed` parameters (see Global
  Constraints ruling) — Task 2 depends on exactly this constructor shape.

- [ ] **Step 1: Write the failing widget test**

Create `test/shared/widgets/mx_icon_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// `MxIconTile` — the leading glyph well `SettingsRow` (and later `ListRow`)
/// compose. Its `default` variant is fully specified by
/// `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` §15.1:
/// `primary` tints the tile at 10%/16% and paints the glyph at full strength —
/// not `AppInk.accent`, a different value tuned for text contrast.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {bool isDark = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders the glyph it was given', (tester) async {
    await pump(tester, const MxIconTile(icon: Icons.notifications_outlined));

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('is a fixed 36dp square with AppRadius.md corners', (tester) async {
    await pump(tester, const MxIconTile(icon: Icons.notifications_outlined));

    expect(tester.getSize(find.byType(MxIconTile)), const Size(36, 36));
    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.md));
  });

  for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
    final label = mode.$1;
    final isDark = mode.$2;

    testWidgets('$label · tile tints primary at the spec percentage', (tester) async {
      await pump(tester, const MxIconTile(icon: Icons.notifications_outlined), isDark: isDark);
      final theme = isDark ? buildDarkTheme() : buildLightTheme();
      final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final fill = (decorated.decoration as BoxDecoration).color;

      expect(
        fill,
        theme.colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.10),
        reason: label,
      );
    });

    testWidgets('$label · glyph is primary at full strength, not AppInk.accent', (tester) async {
      await pump(tester, const MxIconTile(icon: Icons.notifications_outlined), isDark: isDark);
      final theme = isDark ? buildDarkTheme() : buildLightTheme();
      final icon = tester.widget<Icon>(find.byIcon(Icons.notifications_outlined));

      expect(icon.color, theme.colorScheme.primary, reason: label);
    });
  }

  testWidgets('a null semanticLabel excludes the glyph from semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MxIconTile(icon: Icons.notifications_outlined));

    expect(tester.getSemantics(find.byType(MxIconTile)), matchesSemantics());
    handle.dispose();
  });

  testWidgets('a semanticLabel is read', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxIconTile(icon: Icons.notifications_outlined, semanticLabel: 'Notifications'),
    );

    expect(
      tester.getSemantics(find.byType(MxIconTile)),
      matchesSemantics(label: 'Notifications'),
    );
    handle.dispose();
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart`
Expected: FAIL — `mx_icon_tile.dart` does not exist yet (import error).

- [ ] **Step 3: Implement `MxIconTile`**

Create `lib/shared/widgets/mx_icon_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

/// The leading glyph well `SettingsRow` and `ListRow` compose — a tinted
/// square with an icon centred inside it.
///
/// **The `default` variant only** (M100.102 / SettingsRow handoff). The
/// theme-prerequisite spec already names a `size: sm` (28, for `ListRow`) and
/// a `seed` `COMPONENT_INPUT` (a per-deck colour `ListRow` forwards), but this
/// component's first real caller is `SettingsRow`, which needs neither — only
/// `size: md` (36) at the `default` tint. Built to that one call site rather
/// than to the full future surface, on the same reasoning
/// `DeckIconArea` recorded before it: "promoting it on the first caller would
/// be guessing at what varies — the second caller is what shows whether the
/// tint, the size or the shape is the part worth parameterising."
/// `lib/features/deck/presentation/widgets/items/deck_icon_area_widget.dart`
/// is that same well shape at a different (feature-local) size and a
/// different, separately-tried tint — not this component's ancestor, just the
/// prior art for the same idea in this codebase. Add `size`/`seed` when
/// `ListRow` is the plan that needs them.
///
/// **`primary`, not `AppInk.accent`.** The spec's role index binds both the
/// tile fill and the glyph to `primary` directly (`docs/superpowers/specs/
/// 2026-09-18-memox-v3-theme-prerequisite.md` §15.1) — a fixed brand colour,
/// not the text-safe, contrast-tuned value `AppInk.accent` resolves to
/// (`AppSemanticColors.accentInk`). No `AppInk` member equals `primary`, so
/// the glyph is a raw `Icon(color: …)` rather than `MxIcon(ink: …)` — see the
/// `allowedInKit` entry in `test/app/icon_ink_boundary_test.dart`.
class MxIconTile extends StatelessWidget {
  /// The tile's own square edge. Not on the `AppSizing`/`AppIconSize` ladders:
  /// it is a genuinely new dimension the v3 kit introduces (v3-foundations.md
  /// line 294, "icon tile 36–44"), not a rename of one that already renders.
  static const double dimension = 36;

  /// `primary` @ 10% light / 16% dark — the spec's own figures, not derived.
  static const double _tintLight = 0.10;
  static const double _tintDark = 0.16;

  const MxIconTile({required this.icon, this.semanticLabel, super.key});

  final IconData icon;

  /// Read by screen readers; `null` leaves the glyph decorative (it almost
  /// always sits beside a label that already says the thing).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glyph = Icon(
      icon,
      color: scheme.primary,
      semanticLabel: semanticLabel,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: isDark ? _tintDark : _tintLight),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: semanticLabel == null ? ExcludeSemantics(child: glyph) : glyph,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart`
Expected: PASS, all cases.

- [ ] **Step 5: Allowlist the raw `Icon(color:)` in the boundary guard**

In `test/app/icon_ink_boundary_test.dart`, add to `allowedInKit`:

```dart
    'mx_icon_tile.dart':
        'the spec pins the glyph to primary directly (theme-prerequisite '
        '§15.1) — no AppInk member equals primary, only AppInk.accent, a '
        'different contrast-tuned value.',
```

Run: `flutter test test/app/icon_ink_boundary_test.dart`
Expected: PASS (both the "shared kit" and "no exemption outlives its reason" tests).

- [ ] **Step 6: Register in the Widgetbook catalog**

In `widgetbook/lib/components/form_components.dart`, add (near
`listTileComponent()`):

```dart
WidgetbookComponent iconTileComponent() {
  return WidgetbookComponent(
    name: 'MxIconTile',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final glyph = context.knobs.object.dropdown<IconData>(
            label: 'icon',
            options: const <IconData>[
              Icons.notifications_outlined,
              Icons.palette_outlined,
              Icons.public_outlined,
              Icons.psychology_outlined,
            ],
            labelBuilder: (IconData icon) => icon.toString(),
          );

          return CatalogCenterPage(child: MxIconTile(icon: glyph));
        },
      ),
    ],
  );
}
```

Import `mx_icon_tile.dart` at the top of the file
(`import 'package:memox/shared/widgets/mx_icon_tile.dart';`). In
`widgetbook/lib/main.dart`, add `iconTileComponent(),` to the `Components`
category's children list, next to `listTileComponent()`.

Run: `flutter analyze` (root and, separately, inside `widgetbook/`) — zero
errors and warnings in both.

- [ ] **Step 7: format, restore, guard, commit**

```bash
dart format lib/shared/widgets/mx_icon_tile.dart test/shared/widgets/mx_icon_tile_test.dart test/app/icon_ink_boundary_test.dart widgetbook/lib/components/form_components.dart widgetbook/lib/main.dart
flutter analyze
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
git add lib/shared/widgets/mx_icon_tile.dart test/shared/widgets/mx_icon_tile_test.dart test/app/icon_ink_boundary_test.dart widgetbook/lib/components/form_components.dart widgetbook/lib/main.dart
git commit -m "feat(design-system): MxIconTile, the settings/list leading glyph well (M100.102)"
```

---

### Task 2: `MxSettingsRow` — the settings-screen row

**Files:**
- Create: `lib/shared/widgets/mx_settings_row.dart`
- Create: `test/shared/widgets/mx_settings_row_test.dart`
- Modify: `widgetbook/lib/components/form_components.dart` (new
  `settingsRowComponent()` function)
- Modify: `widgetbook/lib/main.dart` (register `settingsRowComponent()`)

**Interfaces:**
- Consumes: `MxIconTile` from Task 1 — `const MxIconTile({required IconData
  icon, String? semanticLabel})`.
- Produces: `class MxSettingsRow extends StatelessWidget` —

```dart
const MxSettingsRow({
  required String label,
  String? sub,
  IconData? leadingIcon,
  String? leadingSemanticLabel,
  Widget? trailing,
  Widget? wideControl,
  VoidCallback? onTap,
  bool isEnabled = true,
  Key? key,
})
```

  A row is "navigable" (draws the chevron, is tappable, takes focus) exactly
  when `isEnabled && onTap != null && trailing == null && wideControl ==
  null`. `trailing` and `wideControl` are mutually exclusive
  (`assert` in the constructor).

- [ ] **Step 1: Write the failing widget test**

Create `test/shared/widgets/mx_settings_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import '../../support/ink_probe.dart';

/// `MxSettingsRow` — a settings-screen row: leading `MxIconTile`, label +
/// optional sub, and an optional trailing control (inline, wide, or a
/// navigation chevron). See the SettingsRow component handoff and
/// `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` §15.2.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
    Size surface = const Size(360, 640),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.pump();
  }

  const long =
      'A setting name long enough that it has to wrap or be cut off, twice over';

  group('MxSettingsRow layout', () {
    testWidgets('renders label, sub and a leading MxIconTile', (tester) async {
      await pump(
        tester,
        const MxSettingsRow(
          label: 'Notifications',
          sub: 'Reminders and study nudges',
          leadingIcon: Icons.notifications_outlined,
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Reminders and study nudges'), findsOneWidget);
      expect(find.byType(MxIconTile), findsOneWidget);
    });

    testWidgets('with no leadingIcon, no MxIconTile is built', (tester) async {
      await pump(tester, const MxSettingsRow(label: 'Notifications'));

      expect(find.byType(MxIconTile), findsNothing);
    });

    testWidgets('is at least AppSizing.touchTarget tall', (tester) async {
      await pump(tester, const MxSettingsRow(label: 'Notifications'));

      expect(tester.getSize(find.byType(MxSettingsRow)).height, greaterThanOrEqualTo(48));
    });

    testWidgets('a long label and sub wrap rather than overflow', (tester) async {
      await pump(
        tester,
        MxSettingsRow(label: long, sub: long, onTap: () {}),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('MxSettingsRow trailing shapes', () {
    testWidgets('navigable: draws the chevron, no leading control present', (tester) async {
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('a static row (no onTap) draws no chevron', (tester) async {
      await pump(tester, const MxSettingsRow(label: 'App version'));

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('a trailing control suppresses the chevron', (tester) async {
      await pump(
        tester,
        MxSettingsRow(
          label: 'Reminders',
          onTap: () {},
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('a wideControl drops to its own line and suppresses the chevron', (tester) async {
      await pump(
        tester,
        MxSettingsRow(
          label: 'Daily goal',
          onTap: () {},
          wideControl: const Text('stepper'),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      final rowBottom = tester.getBottomLeft(find.text('Daily goal')).dy;
      final controlTop = tester.getTopLeft(find.text('stepper')).dy;
      expect(controlTop, greaterThan(rowBottom), reason: 'the control is not on its own line');
    });

    test('passing both trailing and wideControl is a contract violation', () {
      expect(
        () => MxSettingsRow(
          label: 'Bad',
          trailing: const Icon(Icons.check),
          wideControl: const Text('x'),
        ),
        throwsAssertionError,
      );
    });
  });

  group('MxSettingsRow interaction', () {
    testWidgets('a navigable row taps once', (tester) async {
      var taps = 0;
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () => taps++));

      await tester.tap(find.byType(MxSettingsRow));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('a row with a trailing control is not itself tappable', (tester) async {
      var taps = 0;
      await pump(
        tester,
        MxSettingsRow(
          label: 'Reminders',
          onTap: () => taps++,
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
      );

      await tester.tap(find.byType(MxSettingsRow), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(taps, 0);
    });

    testWidgets('disabled: dims and drops the tap and the focus stop', (tester) async {
      var taps = 0;
      await pump(
        tester,
        MxSettingsRow(label: 'Theme', isEnabled: false, onTap: () => taps++),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, AppStateOpacity.disabled);

      await tester.tap(find.byType(MxSettingsRow), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<InkWell>()),
      );
    });

    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      final label = mode.$1;
      final isDark = mode.$2;

      testWidgets('$label · a navigable row hovers, presses and focuses like a row', (
        tester,
      ) async {
        await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}), isDark: isDark);
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final hoverWash = AppInteractionStates.rowOverlay(
          theme.colorScheme,
        ).resolve(const <WidgetState>{WidgetState.hovered})!;

        final gesture = await hover(tester, find.byType(MxSettingsRow));
        expectInkColor(tester, hoverWash, reason: '$label: no hover wash');
        await gesture.moveTo(const Offset(0, 0));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final ring = tester.widget<DecoratedBox>(
          find
              .descendant(of: find.byType(MxSettingsRow), matching: find.byType(DecoratedBox))
              .first,
        );
        final border = (ring.decoration as BoxDecoration).border as Border?;
        expect(border?.top.width, AppStroke.focus, reason: label);
      });
    }
  });

  group('MxSettingsRow typography and colour', () {
    testWidgets('label is onSurface, sub is onSurfaceVariant', (tester) async {
      final theme = buildLightTheme();
      await pump(
        tester,
        const MxSettingsRow(label: 'Notifications', sub: 'Reminders'),
      );

      final label = tester.renderObject<RenderParagraph>(find.text('Notifications'));
      final sub = tester.renderObject<RenderParagraph>(find.text('Reminders'));
      expect(label.text.style?.color, theme.colorScheme.onSurface);
      expect(sub.text.style?.color, theme.colorScheme.onSurfaceVariant);
    });

    testWidgets('chevron is onSurfaceVariant', (tester) async {
      final theme = buildLightTheme();
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}));

      final chevron = tester.widget<Icon>(find.byIcon(Icons.chevron_right));
      expect(chevron.color, theme.colorScheme.onSurfaceVariant);
    });
  });

  group('MxSettingsRow semantics', () {
    testWidgets('a navigable row is exposed as a button', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}));

      expect(
        tester.getSemantics(find.byType(MxSettingsRow)),
        matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, label: 'Theme'),
      );
      handle.dispose();
    });
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/shared/widgets/mx_settings_row_test.dart`
Expected: FAIL — `mx_settings_row.dart` does not exist yet.

- [ ] **Step 3: Implement `MxSettingsRow`**

Create `lib/shared/widgets/mx_settings_row.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/states/app_interaction_states.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_focus_ring.dart';
import 'mx_icon.dart';
import 'mx_icon_tile.dart';

/// A settings-screen row: a leading `MxIconTile`, a label with an optional
/// second line, and an optional trailing control.
///
/// **Kept apart from `MxListTile` on purpose** (SettingsRow component
/// handoff, "same silhouette, different contract"): a bigger label rung
/// (`16/600` vs `MxListTile`'s `body-lg`/`16/500`), its own `12 16` padding
/// and `48` floor rather than `ListTileThemeData`'s, and a leading tile fixed
/// to `MxIconTile` rather than an arbitrary `leading:` widget. Composing
/// `ListTile`/`MxListTile` here would mean fighting its theme-driven padding
/// and minimum height at every call, for a shape that only coincidentally
/// looks similar.
///
/// **This surface owns no colour of its own beyond what it reads directly**
/// (`onSurface`, `onSurfaceVariant`, the shared focus ring) — the leading
/// tile's tint and glyph colour belong entirely to `MxIconTile`
/// (`VIA_COMPONENT`, theme-prerequisite spec §15.2); this row does not
/// recolour it.
///
/// **One trailing shape at a time.** [trailing] (inline) and [wideControl]
/// (its own line, full width) are mutually exclusive — the component
/// contract's state matrix has no row combining them — and either one
/// suppresses the navigation chevron, matching "chevron ONLY when the row
/// navigates and has no trailing control."
class MxSettingsRow extends StatelessWidget {
  /// The lead column's width — wider than the [MxIconTile] it holds (`36`),
  /// so the icon centres with even space either side. Not on `AppSizing`'s
  /// ladder: `AppSizing.controlCompact` is also `40`, but it names a control
  /// *height* (M100.30's two-button-heights ladder); reusing it here for an
  /// unrelated layout column width would be the token-borrowed-for-its-number
  /// mistake `spacing_is_a_gap_test.dart` guards against on the spacing side.
  static const double _leadColumnWidth = 40;

  const MxSettingsRow({
    required this.label,
    this.sub,
    this.leadingIcon,
    this.leadingSemanticLabel,
    this.trailing,
    this.wideControl,
    this.onTap,
    this.isEnabled = true,
    super.key,
  }) : assert(
         trailing == null || wideControl == null,
         'a row has one trailing control at a time — inline or wide, not both',
       );

  /// Already-localized.
  final String label;
  final String? sub;

  /// `null` renders no lead column at all (grid collapses to `1fr / auto`).
  final IconData? leadingIcon;
  final String? leadingSemanticLabel;

  /// An inline control beside the label — e.g. a `Switch` or a time button.
  /// Mutually exclusive with [wideControl]. Suppresses the chevron.
  final Widget? trailing;

  /// A control that drops to its own line below the label — e.g. a stepper
  /// or a segmented control. Mutually exclusive with [trailing]. Suppresses
  /// the chevron.
  final Widget? wideControl;

  /// `null` makes the row non-interactive — a static row, or one whose
  /// action has not loaded yet. Ignored (no chevron, no tap, no focus stop)
  /// whenever [trailing] or [wideControl] is present, per the state matrix.
  final VoidCallback? onTap;

  /// `false` dims the whole row to `AppStateOpacity.disabled` (`0.38`, the
  /// v3 global disabled rule) and drops it out of the focus order.
  final bool isEnabled;

  bool get _isNavigable =>
      isEnabled && onTap != null && trailing == null && wideControl == null;

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.texts.bodyLarge!
        .inked(context, AppInk.stated, isEmphasized: true)
        .copyWith(letterSpacing: -0.1);
    // `bodySmall` is bound to the "caption" role (12/600/1.4, 1.2px tracking) —
    // the nearest existing 12px slot, but SettingsRow.sub wants a plain-weight
    // secondary line at 1.45 line-height and no tracking, so those three are a
    // component-level override of the nearest role (typography §7 sanctions
    // exactly this), not a new global style.
    final subStyle = context.texts.bodySmall!
        .inked(context, AppInk.quiet)
        .copyWith(fontWeight: FontWeight.w400, height: 1.45, letterSpacing: 0);

    final sub = this.sub;
    final leadingIcon = this.leadingIcon;
    final trailing = this.trailing;
    final wideControl = this.wideControl;
    final isNavigable = _isNavigable;

    Widget? trailingSlot;
    if (trailing != null) {
      trailingSlot = trailing;
    } else if (isNavigable) {
      trailingSlot = MxIcon(
        Icons.chevron_right,
        ink: AppInk.quiet,
        size: MxIconSize.mdCompact,
      );
    }

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  SizedBox(
                    width: _leadColumnWidth,
                    child: Center(
                      child: MxIconTile(
                        icon: leadingIcon,
                        semanticLabel: leadingSemanticLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: labelStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sub != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          sub,
                          style: subStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingSlot != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.lg),
                  trailingSlot,
                ],
              ],
            ),
            if (wideControl != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: wideControl),
            ],
          ],
        ),
      ),
    );

    final overlay = AppInteractionStates.rowOverlay(context.colors);
    // Its own transparent `Material`, so the row — and a caller-supplied
    // `trailing`/`wideControl` control — can paint ink on any surface,
    // the same move `MxListTile` and `MxSwitchRow` make.
    final interactive = Material(
      type: MaterialType.transparency,
      child: isNavigable
          ? InkWell(
              onTap: onTap,
              hoverColor: overlay.resolve(const <WidgetState>{WidgetState.hovered}),
              focusColor: overlay.resolve(const <WidgetState>{WidgetState.focused}),
              splashColor: overlay.resolve(const <WidgetState>{WidgetState.pressed}),
              child: content,
            )
          : content,
    );

    return Opacity(
      opacity: isEnabled ? 1 : AppStateOpacity.disabled,
      child: MxFocusRing(
        // Square, like the row: the ring traces the shape the ink takes.
        borderRadius: BorderRadius.zero,
        child: ExcludeFocus(excluding: !isNavigable, child: interactive),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/shared/widgets/mx_settings_row_test.dart`
Expected: PASS, all cases. If the file is at or past ~400 lines, split the
`typography and colour` + `semantics` groups into
`test/shared/widgets/mx_settings_row_contract_test.dart`, mirroring the
`mx_list_tile_test.dart` / `mx_list_tile_contract_test.dart` split, and update
both files' leading doc comments to say why.

- [ ] **Step 5: Confirm the icon-ink boundary guard still passes**

`MxSettingsRow` colours its own chevron through `MxIcon(ink: AppInk.quiet)`,
not a raw `Icon(color:)`, so it needs no new `allowedInKit` entry — this step
only re-runs the guard to confirm that stays true after Step 3.

Run: `flutter test test/app/icon_ink_boundary_test.dart`
Expected: PASS, unchanged from Task 1.

- [ ] **Step 6: Register in the Widgetbook catalog**

In `widgetbook/lib/components/form_components.dart`, add (near
`listTileComponent()` / `selectionRowsComponent()`):

```dart
WidgetbookComponent settingsRowComponent() {
  return WidgetbookComponent(
    name: 'MxSettingsRow',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Navigable',
        builder: (BuildContext context) => CatalogCenterPage(
          child: MxSettingsRow(
            label: 'Theme',
            sub: 'System default',
            leadingIcon: Icons.palette_outlined,
            isEnabled: context.knobs.boolean(label: 'enabled', initialValue: true),
            onTap: _noop,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With a trailing control',
        builder: (BuildContext context) => CatalogCenterPage(
          child: MxSettingsRow(
            label: 'Notifications',
            sub: 'Reminders and study nudges',
            leadingIcon: Icons.notifications_outlined,
            trailing: Switch(
              value: context.knobs.boolean(label: 'on', initialValue: true),
              onChanged: _noopBool,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With a wide control',
        builder: (BuildContext context) => CatalogCenterPage(
          child: MxSettingsRow(
            label: 'Daily goal',
            leadingIcon: Icons.psychology_outlined,
            wideControl: OutlinedButton(onPressed: _noop, child: const Text('12 cards / day')),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Static, no leading icon',
        builder: (BuildContext context) => const CatalogCenterPage(
          child: MxSettingsRow(label: 'App version', sub: '1.4.2 (build 218)'),
        ),
      ),
    ],
  );
}
```

Import `mx_settings_row.dart` at the top of the file. `_noop` and `_noopBool`
already exist in this file (used by `listTileComponent()` /
`selectionRowsComponent()`) — reuse them, do not redeclare. In
`widgetbook/lib/main.dart`, add `settingsRowComponent(),` to the `Components`
category's children list, next to `iconTileComponent()`.

Run: `flutter analyze` (root and `widgetbook/`) — zero errors and warnings.

- [ ] **Step 7: format, restore, guard, commit**

```bash
dart format lib/shared/widgets/mx_settings_row.dart test/shared/widgets/mx_settings_row_test.dart widgetbook/lib/components/form_components.dart widgetbook/lib/main.dart
flutter analyze
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
git add lib/shared/widgets/mx_settings_row.dart test/shared/widgets/mx_settings_row_test.dart widgetbook/lib/components/form_components.dart widgetbook/lib/main.dart
git commit -m "feat(design-system): MxSettingsRow, the settings-screen row (M100.103)"
```

---

## Controller-run steps (not dispatched)

1. `flutter test --exclude-tags golden` (full host suite — both new files plus
   fallout).
2. `bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main`
   and the guard, from the repo root.
3. No golden authoring, no screen-gallery republish, no
   `integration_test/` run: neither widget is wired into a screen or into
   `lib/features/` in this plan (see Global Constraints).
4. Final whole-branch review.
5. `docs/wbs.md`: one entry (`M100.102`/`M100.103` or whatever id is free at
   push time — check `git fetch origin --prune` first, per this repo's
   "WBS id collides with parallel PRs" lesson) recording both widgets, scoped
   as component-only (no screen wiring yet).
6. Merge `origin/main`, re-run the gate if the base moved, push, PR, CI green,
   merge, confirm `MERGED`, delete the branch.
