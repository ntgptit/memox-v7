# ChipTrigger Flutter Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `MxChipTrigger` — a new shared widget for the "compact menu trigger" contract
(e.g. "Newest first", "Manual · Due only"): a 28dp-tall ghost chip with a label and a
fixed trailing chevron that opens a caller-owned menu. It is never selectable — that is
what makes it a distinct widget from the existing `MxPillButton` rather than a variant of it.

**Architecture:** New file in `lib/shared/widgets/` (flat, no bucket subfolders — AD-15's
four-bucket rule is for a *feature's* `presentation/widgets/`, not for `lib/shared/widgets/`).
Composed from primitives that already exist — `MxFocusRing`, `AppSizing.touchTarget`,
`AppSpacing`, `AppRadius.pill`, `AppIconSize.sm`, `AppStateOpacity.disabledContent`,
`context.colors` / `context.texts` — with no new theme role, no new `ChipThemeData` slot,
and no edit to `MxPillButton`. This task does not wire `MxChipTrigger` into any screen; the
menu it opens is caller-owned and out of scope (see the handoff's Caller-owned section).

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, Material 3, flutter_test, the repo's Python guard
(`code-verification-guard-v2`).

**Spec:** The design handoff pasted into this session's `/superpowers:subagent-driven-development`
invocation (MemoX v3 HTML design kit · B · Actions & controls · ChipTrigger). No separate spec
file exists for this component; the Global Constraints below carry every binding value out of
that handoff plus what this session's own codebase research resolved against it.

## Research findings this plan is built on

(A pre-flight `Agent` research pass read the repo before this plan was written. Citations below are
exact paths so the implementer never has to re-derive them.)

- `lib/shared/widgets/` is **flat** — 47 files, no bucket subfolders. Confirmed no
  `lib/shared/widgets/README.md` exists.
- **Every public class in `lib/shared/widgets/` must carry the `Mx` prefix and live in a
  `mx_*.dart` file** — enforced by `test/shared/widgets/mx_naming_test.dart`. The handoff's
  bare identifier "ChipTrigger" is not legal here: the widget MUST be named `MxChipTrigger` in
  `lib/shared/widgets/mx_chip_trigger.dart`. This is a naming ruling, not an open question.
- No `MxFilterChip` exists. The app's only chip-geometry widget is `MxPillButton`
  (`lib/shared/widgets/mx_pill_button.dart`), which wraps a flat `ChoiceChip`, is 32dp tall
  (`AppSizing.controlDense`), and takes a **required** `isSelected: bool`. It cannot be
  extended or subclassed for this contract — a selectable chip and a chip that must *never*
  read as selected are two different accessibility contracts, which is exactly why the
  handoff calls ChipTrigger out as "deliberately a separate control." `AppSizing` has no `28`
  constant (only `controlCompact` = 40, `controlDense` = 32) — see Global Constraint 3 for the
  ruling on how to introduce `28`.
- No existing "chip that opens a menu" pattern exists. `MxMenuButton` wraps `PopupMenuButton`
  but is icon-only by default; `MxDropdown` is documented as "the *inline* select", not a chip.
  Today's actual sort/filter triggers (`CardSortControlWidget`,
  `lib/features/card/presentation/widgets/support/card_sort_control_widget.dart`; the deck
  toolbar's sort control, `lib/features/deck/presentation/widgets/sections/deck_list_toolbar_widget.dart`)
  are `MxTextButton`/similar wrapping a call to `showCardSortSheet`/`showMxSheet` — i.e. the
  established shape is "trigger fires a callback; caller decides what UI the callback opens."
  `MxChipTrigger` follows that shape: it exposes `onPressed: VoidCallback?` and owns no menu,
  no `PopupMenuButton`, no `showMenu` call.
- `Theme.of(context).textTheme.labelMedium` (`lib/core/theme/typography/app_typography.dart`)
  is exactly "12/600": caption size (12), weight 600, height 1.4, tracking `AppTypography.labelTracking`
  (0.72). This is the label rung to consume — do not hand-build a `TextStyle`.
- `AppIconSize.sm` = 16 (`lib/core/theme/foundations/app_icon_size.dart`) — matches the
  handoff's "chevron-down at 16" exactly. `AppSpacing.xs` = 4 — matches "gap 4" exactly.
  `AppSpacing.sm` = 8 is the app's own "control-internal gap" token, used here for the chip's
  horizontal inset. `AppRadius.pill` = 999, `AppSizing.touchTarget` = 48.
- Icon meaning, by grepping existing call sites for consistency (do **not** invent new Material
  Symbol choices for glyphs the app has already picked a meaning for):
  - "chevron-down" → `Icons.expand_more`. Already the app's established glyph for "reveals
    more" (`lib/shared/widgets/mx_text_button.dart`'s doc comment, and
    `lib/features/card/presentation/widgets/sections/card_editor_details_widget.dart:161`).
    `Icons.keyboard_arrow_down` exists elsewhere in the app
    (`lib/features/deck/presentation/widgets/overlays/deck_actions_widget.dart:111`) but means
    "move this item later in a list" there — a different semantic; do not reuse it here.
  - "arrow-up-down" → `Icons.swap_vert`. Already the app's sort glyph
    (`card_sort_control_widget.dart:62`, `deck_list_toolbar_widget.dart:101`).
  - "sliders-horizontal" → `Icons.tune`. Already the app's filter/adjust glyph
    (`deck_actions_widget.dart:123`, `lib/features/study/presentation/screens/study_entry_screen.dart:227`).
  - Neither `swap_vert` nor `tune` is in the FIXED dimension table (only the trailing chevron
    is FIXED). They are the two example **leading** glyphs the handoff's Icons section lists
    for the sort/filter instances shown in the kit ("Newest first", "Manual · Due only") — see
    Global Constraint 4 for the resulting API shape.
- `MxFocusRing` (`lib/shared/widgets/mx_focus_ring.dart`) already implements the exact
  "primary, GLOBAL focus treatment, keyboard-only" row in the handoff's theme table — wrap the
  interactive shape in it and the focus-ring binding is done; do not re-implement any part of it.
- `context.colors` / `context.texts` / `context.semanticColors`
  (`lib/core/theme/extensions/theme_context_extension.dart`) are the established accessors for
  `ColorScheme` / `TextTheme` / `AppSemanticColors` — use them, not `Theme.of(context).colorScheme`
  spelled out by hand.
- `AppStateOpacity.disabledContent` = 0.38 (`lib/core/theme/states/app_interaction_states.dart`)
  is the established "dim this ink because the control is disabled" token — reuse it rather than
  inventing a new disabled-alpha value; the handoff's state matrix does not cover disabled, so
  this is the repo's own convention filling a genuine gap, not an invented one.
- Widgetbook registers one `WidgetbookComponent`-returning function per component, all in
  `widgetbook/lib/components/control_components.dart` (e.g. `pillButtonComponent()`,
  `menuButtonComponent()`), listed in `widgetbook/lib/main.dart`'s `Components` category. New
  entries follow that same-file convention; there is no per-component Widgetbook file.
- No `test/demo/` screen gallery entry or golden test is implicated: this widget is not wired
  into any screen by this task, and no other shared component in `lib/shared/widgets/` carries
  its own dedicated golden — `MxPillButton`'s own test suite
  (`test/shared/widgets/mx_pill_button_test.dart`, `..._focus_test.dart`, `..._theme_test.dart`,
  `..._construction_test.dart`) is plain widget/unit tests. `MxChipTrigger` follows that
  pattern; no golden regeneration, no gallery republish for this task.

## Global Constraints

1. **Naming.** The widget is `MxChipTrigger` in `lib/shared/widgets/mx_chip_trigger.dart`,
   enforced by `test/shared/widgets/mx_naming_test.dart`. It is never called bare
   "ChipTrigger" in code.
2. **Never selectable, by construction.** There is no `isSelected` parameter and no
   `selected`/`hasSelectedState` semantics flag anywhere in this widget. The handoff's "state:
   FIXED none — it never reads as selected" is structural, not a default.
3. **The 28dp content height is a new local constant, not a promotion into `AppSizing`.**
   `AppSizing`'s own header explains why it holds only two control heights today
   (`controlCompact` = 40, `controlDense` = 32) rather than a five-rung ladder: a value only
   belongs there once more than one component renders it. `MxChipTrigger` is the first and, for
   now, only consumer of 28 — define it as a private top-level constant in
   `mx_chip_trigger.dart` (e.g. `const double _contentHeight = 28;`) with a one-line comment
   citing the handoff. Do **not** edit `app_sizing.dart`, and do not spell `28` as a bare
   literal anywhere (no magic values).
4. **API shape:** `MxChipTrigger({required String label, required VoidCallback? onPressed,
   IconData? leadingIcon, String? semanticLabel, Key? key})`.
   - `onPressed`: null disables the trigger, matching every other interactive `Mx*` widget's
     convention (`MxPillButton`, `MxActionButton`). `MxChipTrigger` never renders, opens, or
     references a menu, a `PopupMenuButton`, or a `showMenu` call — the caller wires `onPressed`
     to whatever surface it wants (a sheet, a `PopupMenuButton`, a `MenuAnchor`); that surface,
     its items, and which option is "current" are 100% caller-owned per the handoff.
   - `leadingIcon`: optional. The handoff's Icons section lists three glyphs this component
     paints, but only the trailing chevron is FIXED in the dimension table; `swap_vert` and
     `tune` are the two example **leading** glyphs its own two worked examples ("Newest first",
     "Manual · Due only") would use. Expose it as a plain optional slot, painted only when
     non-null, sized and gapped exactly like the trailing chevron (`AppIconSize.sm`,
     `AppSpacing.xs`). Do not hardcode `swap_vert`/`tune` inside the widget — the caller passes
     the icon that matches its own menu's contents.
   - Trailing chevron is **not** a parameter — it is always `Icons.expand_more`, hardcoded,
     because the dimension table marks it FIXED.
   - `semanticLabel`: same contract as `MxPillButton.semanticLabel` — replaces the announced
     name when the visible label is not enough on its own (e.g. an abbreviation); passed
     through as `Text.semanticsLabel`, never via a wrapping `Semantics(label:, excludeSemantics:
     true)`, for the same reason `MxPillButton`'s doc comment gives (a `Semantics` wrapper drops
     the child's own accessible node unless handled exactly right; `Text.semanticsLabel` cannot
     get this wrong).
5. **Geometry, exactly:**
   - Painted content band: 28dp tall (`_contentHeight`), laid out via a tight-height
     `SizedBox(height: _contentHeight, child: Row(...))` so `find.byType(Row)` in a test reports
     exactly 28 — do not let the row's height be merely intrinsic (label + icon alone would lay
     out shorter than 28 and silently violate the FIXED value).
   - Touch target: `AppSizing.touchTarget` (48) on **both** axes, centred around the 28dp band —
     same reasoning `AppSizing.touchTarget`'s own doc gives for `MxPillButton` ("both sides. A
     one-glyph pill paints 33 wide and occupies 48, centred"). **Amended after review 1:** the
     target must be hit-testable, not just laid out. `ConstrainedBox` + `Center` left the
     `InkWell` at 28dp, so the pad is `MxTapTarget` (promoted unchanged from `MxPillButton`'s
     private `_TapTarget`/`_RenderTapTarget` into `mx_tap_target.dart`, used by both widgets),
     placed outside `MxFocusRing` so the ring and `InkWell` stay at the painted 28dp band.
   - Shape: `AppRadius.pill` (999) for the `InkWell`'s `borderRadius` and for `MxFocusRing`'s
     `borderRadius` — the shared "chip family" shape, consistent with `MxPillButton`.
   - Fill: none. `Material(type: MaterialType.transparency, ...)` under the `InkWell`, no
     `Container`/`BoxDecoration`, no border — "ghost, no fill and no border" is what
     distinguishes this from `MxPillButton`'s filled `ChoiceChip`.
   - Horizontal inset around the content band: `AppSpacing.sm` (8), the app's own
     "control-internal gap" token.
   - Gap between leading icon / label / trailing chevron: `AppSpacing.xs` (4) each, matching the
     handoff's "gap 4" verbatim.
6. **Colour, exactly:** label ink and both icons' ink are the same colour —
   `context.colors.onSurfaceVariant` when enabled, dimmed to
   `context.colors.onSurfaceVariant.withValues(alpha: AppStateOpacity.disabledContent)` when
   `onPressed == null`. Read `context.texts.labelMedium!` for the label's `TextStyle` and only
   override its `color`; do not restate size/height/tracking by hand.
7. **Focus:** wrap the interactive shape in `MxFocusRing(borderRadius:
   BorderRadius.circular(AppRadius.pill), child: ...)`. Do not add any other focus-visual code —
   `MxFocusRing` already is the handoff's entire "focus ring · focused: primary, GLOBAL focus
   treatment" row.
8. **Long content:** the label is one line (`maxLines: 1`, `softWrap: false`), no
   `TextOverflow.ellipsis` — the row's own `mainAxisSize: MainAxisSize.min` already makes the
   trigger grow with its label; a caller that needs to fit it in a bounded width wraps it in a
   horizontally-scrolling row itself (caller-owned per the handoff — "the row scrolls").
9. **Semantics:** `MergeSemantics(child: Semantics(button: true, enabled: onPressed != null,
   onTap: onPressed, child: MxFocusRing(...)))`. There is no built-in Material control here
   (unlike `MxPillButton`'s `ChoiceChip` or `MxActionButton`'s `FilledButton`) supplying button
   semantics for free, so this wrapper is mandatory, not conditional on `semanticLabel` being
   set.
10. **House style:** guard clauses and early return, no `else` after `return`, no magic numbers
    (name them per Constraint 3/5/6), no colour literal outside the token files listed in
    `test/visual_audit/color_source_rules_test.dart` (this task adds none), no `DateTime.now()`,
    no user-visible string (the widget takes an already-localized `label`, same contract as
    every other `Mx*` widget). Keep `mx_chip_trigger.dart` under 400 lines.
11. **Tests:** TDD — write the test first, watch it fail on the missing class, then implement.
    Model the test file on `test/shared/widgets/mx_pill_button_test.dart`'s structure (a local
    `pump` helper building a `MaterialApp`/`buildLightTheme()`, then `interaction` / `semantics`
    / `layout` groups) and `mx_pill_button_focus_test.dart`'s technique for the ring
    (`tester.sendKeyEvent(LogicalKeyboardKey.tab)`, reading the foreground `DecoratedBox`). Never
    delete, skip, or comment out a test.
12. **No screen wiring, no golden.** This task does not touch any file under `lib/features/` or
    `test/demo/`, and does not run `--update-goldens`. Wiring `MxChipTrigger` into
    `CardFilterBarWidget`, the deck toolbar, or anywhere else is explicitly out of scope — the
    handoff's Caller-owned section reserves that decision, and it is not this task's to make.
13. **Verification before commit** — all must pass, and the report quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no
      errors
    - `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`
    - `cd widgetbook && dart run build_runner build --delete-conflicting-outputs && flutter test
      --reporter failures-only && cd ..`
    - `python .claude/skills/flutter-workflow/scripts/check_docs.py` → clean
    - then `git checkout -- design_audit/` — the suite rewrites those tracked reports.
14. **Commits:** Conventional Commits, scope `design-system` (this is a shared-component
    addition, not a feature), ending with `Co-Authored-By: Claude Sonnet 5
    <noreply@anthropic.com>`. Do not push, open PRs, or dispatch subagents.

---

### Task 1: `MxChipTrigger` — the widget, its tests, the Widgetbook entry, the WBS record

**Files:**
- Create: `lib/shared/widgets/mx_chip_trigger.dart`
- Create: `test/shared/widgets/mx_chip_trigger_test.dart`
- Modify: `widgetbook/lib/components/control_components.dart` (add `chipTriggerComponent()`,
  same style as `pillButtonComponent()`)
- Modify: `widgetbook/lib/main.dart` (register `chipTriggerComponent()` in the `Components`
  category, beside `pillButtonComponent()`)
- Modify: `docs/wbs.md` (new `### M100.102` entry; header `Updated by task` → `M100.102`,
  `Last updated` → `2026-09-18`, if `check_docs.py` requires the header to move)

**Interfaces:**
- Consumes: `MxFocusRing`, `AppSizing.touchTarget`, `AppSpacing.{xs,sm}`, `AppRadius.pill`,
  `AppIconSize.sm`, `AppStateOpacity.disabledContent`, `context.colors`, `context.texts`.
- Produces: `MxChipTrigger({required label, required onPressed, leadingIcon, semanticLabel,
  key})`.

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_chip_trigger_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// `MxChipTrigger` — the ghost menu trigger. Never selectable, never owns the
/// menu it opens: see the widget's own doc comment for why it is not a
/// variant of `MxPillButton`.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget trigger, {
    bool isDark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(body: Center(child: trigger)),
      ),
    );
  }

  group('interaction', () {
    testWidgets('reports a press', (tester) async {
      var presses = 0;
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () => presses += 1),
      );

      await tester.tap(find.byType(MxChipTrigger));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets('a null callback disables it', (tester) async {
      await pump(
        tester,
        const MxChipTrigger(label: 'Newest first', onPressed: null),
      );

      final semantics = tester.getSemantics(find.byType(MxChipTrigger));
      expect(
        semantics,
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Newest first',
        ),
      );
    });
  });

  group('semantics', () {
    testWidgets('announces as a button, never as selected', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );

      expect(
        tester.getSemantics(find.byType(MxChipTrigger)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Newest first',
        ),
      );
      handle.dispose();
    });

    testWidgets('an override replaces the visible label, not appends it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxChipTrigger(
          label: 'A-Z',
          semanticLabel: 'Sorted by name. Activate to change the sort order.',
          onPressed: () {},
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Sorted by name. Activate to change the sort order.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('A-Z'), findsNothing);
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('meets the 48 touch target on both axes', (tester) async {
      await pump(tester, MxChipTrigger(label: 'X', onPressed: () {}));

      final size = tester.getSize(find.byType(MxChipTrigger));
      expect(size.height, greaterThanOrEqualTo(AppSizing.touchTarget));
      expect(size.width, greaterThanOrEqualTo(AppSizing.touchTarget));
    });

    testWidgets('the painted content band is exactly 28', (tester) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );

      expect(tester.getSize(find.byType(Row)).height, 28);
    });

    testWidgets('the trailing chevron is always painted, at 16', (
      tester,
    ) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      final Size icon = tester.getSize(find.byIcon(Icons.expand_more));
      expect(icon.width, 16);
      expect(icon.height, 16);
    });

    testWidgets('a leading icon paints only when supplied', (tester) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Manual', onPressed: () {}),
      );
      expect(find.byIcon(Icons.tune), findsNothing);

      await pump(
        tester,
        MxChipTrigger(
          label: 'Manual',
          leadingIcon: Icons.tune,
          onPressed: () {},
        ),
      );
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('a long label lengthens the trigger instead of clipping it', (
      tester,
    ) async {
      const longLabel =
          'A label long enough that a fixed-width chip would have to '
          'ellipsize it';

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: MxChipTrigger(label: longLabel, onPressed: () {}),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MxChipTrigger)).width,
        greaterThan(100),
      );
      expect(find.text(longLabel), findsOneWidget);
    });
  });

  group('theming', () {
    testWidgets('the ink is onSurfaceVariant in both themes', (tester) async {
      for (final isDark in <bool>[false, true]) {
        await pump(
          tester,
          MxChipTrigger(label: 'Newest first', onPressed: () {}),
          isDark: isDark,
        );

        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final icon = tester.widget<Icon>(find.byIcon(Icons.expand_more));
        expect(icon.color, theme.colorScheme.onSurfaceVariant);
      }
    });

    testWidgets('disabled ink is dimmer than enabled ink', (tester) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );
      final Color enabled = tester
          .widget<Icon>(find.byIcon(Icons.expand_more))
          .color!;

      await pump(tester, const MxChipTrigger(label: 'Newest first', onPressed: null));
      final Color disabled = tester
          .widget<Icon>(find.byIcon(Icons.expand_more))
          .color!;

      expect(disabled, isNot(enabled));
    });
  });

  group('focus', () {
    BoxDecoration? ringDecoration(WidgetTester tester) {
      final Finder finder = find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox && w.position == DecorationPosition.foreground,
      );
      if (finder.evaluate().isEmpty) return null;

      return tester.widget<DecoratedBox>(finder.first).decoration
          as BoxDecoration?;
    }

    testWidgets('draws no ring until focused, then the primary ring', (
      tester,
    ) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );
      expect(ringDecoration(tester)?.border, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final BoxDecoration? decoration = ringDecoration(tester);
      expect(decoration?.border, isNotNull);
      expect(
        decoration!.border!.top.color,
        AppInteractionStates.focusIndicator(
          buildLightTheme().colorScheme,
        ).color,
      );
    });

    testWidgets('the ring traces the 28dp band, not the 48 touch target', (
      tester,
    ) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final Rect ring = tester.getRect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox && w.position == DecorationPosition.foreground,
        ),
      );
      final Rect target = tester.getRect(find.byType(MxChipTrigger));

      expect(target.height, greaterThan(ring.height));
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/shared/widgets/mx_chip_trigger_test.dart -r failures-only`
Expected: compile FAIL — `MxChipTrigger` is not defined.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_chip_trigger.dart` — build to satisfy Global Constraints 1–10 above.
The shape (guard-clause style, not copy verbatim):

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';

/// A compact chip that opens a menu instead of holding a selection —
/// "Newest first", "Manual · Due only".
///
/// **Why this is not `MxPillButton` with a flag.** `MxPillButton.isSelected`
/// is required, and a pill's whole accessibility contract (`hasSelectedState`,
/// `inMutuallyExclusiveGroup`) is built around it. `MxChipTrigger` must never
/// read as selected — not "selected: false" but no selection concept at all —
/// so it composes its own `InkWell` rather than a `ChoiceChip`.
///
/// **Ghost, not filled.** No fill, no border: [onPressed] fires a caller-owned
/// menu (a sheet, a `PopupMenuButton`, a `MenuAnchor`) — this widget renders
/// only the trigger and knows nothing about what opens.
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. The trigger never reaches for ARB itself.
  final String label;

  /// Null disables the trigger. Opens whatever caller-owned surface answers
  /// this menu — this widget never builds one itself.
  final VoidCallback? onPressed;

  /// Painted before the label, at the same size and gap as the trailing
  /// chevron. Null paints nothing — the slot is not reserved when absent, so
  /// the trigger does not carry a phantom 20dp width for a glyph nobody asked
  /// for.
  final IconData? leadingIcon;

  /// Replaces [label] for assistive technology when the visible text is not
  /// enough on its own (an abbreviation, a short code).
  final String? semanticLabel;

  static const double _contentHeight = 28;

  Color _ink(BuildContext context) {
    final Color resting = context.colors.onSurfaceVariant;
    if (onPressed != null) return resting;

    return resting.withValues(alpha: AppStateOpacity.disabledContent);
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = _ink(context);
    final BorderRadius shape = BorderRadius.circular(AppRadius.pill);

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        onTap: onPressed,
        child: MxFocusRing(
          borderRadius: shape,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: shape,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppSizing.touchTarget,
                  minHeight: AppSizing.touchTarget,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: SizedBox(
                      height: _contentHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: AppSpacing.xs,
                        children: <Widget>[
                          if (leadingIcon != null)
                            Icon(leadingIcon, size: AppIconSize.sm, color: ink),
                          Text(
                            label,
                            semanticsLabel: semanticLabel,
                            maxLines: 1,
                            softWrap: false,
                            style: context.texts.labelMedium!.copyWith(
                              color: ink,
                            ),
                          ),
                          Icon(Icons.expand_more, size: AppIconSize.sm, color: ink),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Adjust freely to keep the file under 400 lines and `flutter analyze` clean — the code above is
the shape the tests are written against, not a transcription requirement over Global
Constraints 1–10 if the two ever conflict (they should not; if they do, the Global Constraints
win and the implementer records why in its report).

- [ ] **Step 4: Run the target test, then the full gate**

Run: `flutter test test/shared/widgets/mx_chip_trigger_test.dart -r failures-only` → PASS.
Then Global Constraint 13 in full.

- [ ] **Step 5: Widgetbook entry**

In `widgetbook/lib/components/control_components.dart`, add (near `pillButtonComponent()`,
same file, same pattern):

```dart
WidgetbookComponent chipTriggerComponent() {
  return WidgetbookComponent(
    name: 'MxChipTrigger',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: 'Newest first',
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final hasLeadingIcon = context.knobs.boolean(label: 'with leading icon');
          final semanticLabel = context.knobs.stringOrNull(
            label: 'semanticLabel',
          );

          return CatalogCenterPage(
            child: MxChipTrigger(
              label: label,
              onPressed: isEnabled ? _noop : null,
              leadingIcon: hasLeadingIcon ? Icons.swap_vert : null,
              semanticLabel: semanticLabel,
            ),
          );
        },
      ),
      // The two worked examples from the design kit: a sort trigger and a
      // filter trigger side by side.
      WidgetbookUseCase(
        name: 'Sort and filter row',
        builder: (BuildContext context) {
          return const CatalogCenterPage(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxChipTrigger(
                  label: 'Newest first',
                  leadingIcon: Icons.swap_vert,
                  onPressed: _noop,
                ),
                MxChipTrigger(
                  label: 'Manual · Due only',
                  leadingIcon: Icons.tune,
                  onPressed: _noop,
                ),
              ],
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Disabled',
        builder: (BuildContext context) {
          return const CatalogCenterPage(
            child: MxChipTrigger(label: 'Newest first', onPressed: null),
          );
        },
      ),
    ],
  );
}
```

Import `mx_chip_trigger.dart` at the top of that file if not already reachable. Register it in
`widgetbook/lib/main.dart`'s `Components` category, next to `pillButtonComponent()`:

```dart
            pillButtonComponent(),
            chipTriggerComponent(),
```

- [ ] **Step 6: WBS entry**

Append to `docs/wbs.md`, in the same section style as `### M100.101` immediately above it:

```markdown
### M100.102 · MxChipTrigger — the ghost menu-trigger chip

- **Status:** done — analyze sạch, host suite pass, guard 0, architecture sạch,
  `check_docs` xanh.
- **Goal:** Thêm `MxChipTrigger` — chip ghost 28dp mở menu do caller sở hữu, không
  bao giờ đọc là "đã chọn". Component đầu tiên hiện thực contract "menu trigger"
  của MemoX v3 design kit (nhóm B · Actions & controls).
- **Scope:** `lib/shared/widgets/mx_chip_trigger.dart` (mới),
  `test/shared/widgets/mx_chip_trigger_test.dart` (mới),
  `widgetbook/lib/components/control_components.dart`, `widgetbook/lib/main.dart`.
- **Out of scope:** nối `MxChipTrigger` vào bất kỳ màn hình nào (CardFilterBarWidget,
  deck toolbar, …) — handoff để ngỏ, caller sở hữu menu và quyết định khi nào dùng.
- **Dependencies:** không — dùng token/thành phần đã có (`MxFocusRing`, `AppSizing`,
  `AppSpacing`, `AppRadius`, `AppIconSize`, `AppStateOpacity`).
- **Tests required:** `mx_chip_trigger_test.dart` (interaction, semantics, layout,
  theming, focus).
- **Editable documents:** `docs/wbs.md`.
- **Output:** `lib/shared/widgets/mx_chip_trigger.dart`.
- **Acceptance criteria:**
  - [x] Không có `isSelected`/trạng thái "đã chọn" nào trong API hay semantics.
  - [x] Cao 28dp (nội dung), chạm tối thiểu 48×48, hình pill, không viền không nền.
  - [x] Nhãn ở `label-md` (12/600), ink `onSurfaceVariant`, mờ đi khi disabled qua
        `AppStateOpacity.disabledContent`.
  - [x] Chevron `Icons.expand_more` 16dp luôn vẽ; icon dẫn đầu là slot tuỳ chọn.
  - [x] Focus ring dùng `MxFocusRing` nguyên trạng — không thêm cơ chế focus mới.
  - [x] Đăng ký trong Widgetbook (`chipTriggerComponent()`).
```

Update the header table's `Updated by task` → `M100.102` and `Last updated` → `2026-09-18`
only if `check_docs.py` reports the header as stale; if it does not check that, leave the
header as-is and say so in the report (Global Constraint 13's `check_docs.py` run settles this
either way).

- [ ] **Step 7: Full gate, then commit**

Run Global Constraint 13 in full, including the Widgetbook `build_runner`/`flutter test` pair
and `check_docs.py`.

```bash
git add lib/shared/widgets/mx_chip_trigger.dart test/shared/widgets/mx_chip_trigger_test.dart widgetbook docs/wbs.md
git commit -m "feat(design-system): MxChipTrigger — the ghost menu-trigger chip (M100.102)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```
