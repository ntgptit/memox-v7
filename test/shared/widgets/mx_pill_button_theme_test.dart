import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_interaction_states.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

/// `MxPillButton`'s paint, state by state.
///
/// Split from `mx_pill_button_test.dart` at the 400-line guard, on the seam that
/// file already had: everything there is about what the widget *does* — it
/// presses, it announces, it fits — and everything here is about what the theme
/// resolves under it.
///
/// **What these guard is a class of bug a source scan cannot see.** The chip
/// theme used to declare two resting fills and leave Material to answer for
/// disabled, hover, focus and press. Material's answers were a translucent
/// `onSurface @ 12%` for disabled — the paint-time compositing MX-VIS-002 rule
/// R7 exists to stop — and, for disabled *and* selected, the full container
/// fill, so a pill nobody could press looked exactly as live as one they could.
/// Nothing in `lib/` said either of those things, which is why nothing found
/// them.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget pill, {
    bool isDark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(body: Center(child: pill)),
      ),
    );
  }

  group('theming', () {
    /// The fill the theme resolves for [states].
    ///
    /// Read through `chipTheme.color` rather than `backgroundColor` /
    /// `selectedColor`, because that is the property Material consults first —
    /// and the three cases below are precisely the ones where the other two are
    /// never reached.
    Color fill(ThemeData theme, Set<WidgetState> states) {
      final color = theme.chipTheme.color;
      expect(
        color,
        isNotNull,
        reason:
            'chipTheme.color is what owns the state machine. Without it '
            'Material answers for disabled, hover, focus and press.',
      );

      final resolved = color!.resolve(states);
      expect(resolved, isNotNull, reason: 'no fill resolved for $states');

      return resolved!;
    }

    testWidgets('selected and unselected differ in both themes', (
      tester,
    ) async {
      // The pill carries "which one is active" by fill alone, so the two fills
      // have to actually differ — in dark as well as light, where a scheme that
      // collapsed them would be invisible rather than merely subtle.
      for (final isDark in <bool>[false, true]) {
        await pump(
          tester,
          MxPillButton(label: 'A-Z', isSelected: false, onPressed: () {}),
          isDark: isDark,
        );
        final unselected = tester.widget<ChoiceChip>(find.byType(ChoiceChip));

        await pump(
          tester,
          MxPillButton(label: 'A-Z', isSelected: true, onPressed: () {}),
          isDark: isDark,
        );
        final selected = tester.widget<ChoiceChip>(find.byType(ChoiceChip));

        expect(unselected.selected, isFalse);
        expect(selected.selected, isTrue);

        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        expect(
          fill(theme, <WidgetState>{WidgetState.selected}),
          isNot(fill(theme, <WidgetState>{})),
          reason:
              'the two states are indistinguishable in '
              '${isDark ? 'dark' : 'light'}',
        );
      }
    });

    test('every state resolves to a solid fill', () {
      // **The rule this pins is R7, and the way it was being broken was by not
      // writing anything down.** Material's chip default for disabled is
      // `onSurface` at 12% alpha, so a theme that declares only the two resting
      // fills ships a translucent one for free — composited against a card here
      // and the page there, which is one token rendering as two colours.
      for (final isDark in <bool>[false, true]) {
        final theme = isDark ? buildDarkTheme() : buildLightTheme();

        for (final states in <Set<WidgetState>>[
          <WidgetState>{},
          {WidgetState.selected},
          {WidgetState.disabled},
          {WidgetState.selected, WidgetState.disabled},
          {WidgetState.hovered},
          {WidgetState.focused},
          {WidgetState.pressed},
          {WidgetState.selected, WidgetState.pressed},
        ]) {
          expect(
            fill(theme, states).a,
            1.0,
            reason:
                '$states resolves to a translucent fill in '
                '${isDark ? 'dark' : 'light'}',
          );
        }
      }
    });

    test('a disabled pill does not look live', () {
      // `_IndividualOverrides` returns `selectedColor` for selected+disabled
      // *before* the defaults are consulted, so a theme declaring `selectedColor`
      // and no `color` gives a disabled selected pill the full container fill.
      // It is the one state combination that looks completely untouched.
      for (final isDark in <bool>[false, true]) {
        final theme = isDark ? buildDarkTheme() : buildLightTheme();

        expect(
          fill(theme, <WidgetState>{
            WidgetState.selected,
            WidgetState.disabled,
          }),
          isNot(fill(theme, <WidgetState>{WidgetState.selected})),
          reason: 'disabled selected is indistinguishable from selected',
        );
        expect(
          fill(theme, <WidgetState>{WidgetState.disabled}),
          isNot(fill(theme, <WidgetState>{})),
          reason: 'disabled is indistinguishable from resting',
        );
        // Dimmed, not erased. Blending the disabled tint over `surface` for both
        // would make a disabled group forget which pill was chosen, and the
        // selection reappears the moment the data arrives.
        expect(
          fill(theme, <WidgetState>{
            WidgetState.selected,
            WidgetState.disabled,
          }),
          isNot(fill(theme, <WidgetState>{WidgetState.disabled})),
          reason: 'a disabled group has forgotten which pill was selected',
        );
      }
    });

    test('pointer feedback is answered by the theme, not by Material', () {
      // Declaring `color` makes Material set the InkWell's `hoverColor` to
      // transparent, so these three are the only feedback a pill has left. A
      // theme that resolved them all to the resting fill would leave the pill
      // silent under a pointer on the web build — which is the E2E channel.
      for (final isDark in <bool>[false, true]) {
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final resting = fill(theme, <WidgetState>{});

        for (final state in <WidgetState>[
          WidgetState.hovered,
          WidgetState.focused,
          WidgetState.pressed,
        ]) {
          expect(
            fill(theme, <WidgetState>{state}),
            isNot(resting),
            reason: '$state is silent in ${isDark ? 'dark' : 'light'}',
          );
        }
      }
    });

    test('the theme side never becomes the focus ring', () {
      // **This test asserted the opposite until M100.23, and the concern behind
      // it was right.** It required `chipTheme.side` to resolve to the ring
      // colour under focus, because a fill tint alone measures 1.15:1 in light
      // and 1.25:1 in dark against the resting fill — nowhere near the 3:1 WCAG
      // 1.4.11 asks of a focus indicator.
      //
      // What was wrong was the slot. `side` is where `_ChoiceChipDefaultsM3`
      // puts the chip's *identity*, so filling it with a focus colour meant a
      // selected, focused pill silently left its Material role — and because
      // `focused` was read before `selected`, it did so in the one combination
      // a keyboard user is always in.
      //
      // The indicator moved to `MxFocusRing`, a layer of its own; the rule the
      // side now keeps is asserted here, across every combination.
      const combinations = <Set<WidgetState>>[
        <WidgetState>{},
        <WidgetState>{WidgetState.focused},
        <WidgetState>{WidgetState.selected},
        <WidgetState>{WidgetState.selected, WidgetState.focused},
      ];

      for (final isDark in <bool>[false, true]) {
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final side = theme.chipTheme.side;
        expect(side, isA<WidgetStateBorderSide>());

        final ring = AppInteractionStates.focusIndicator(
          theme.colorScheme,
        ).color;

        for (final states in combinations) {
          expect(
            (side! as WidgetStateBorderSide).resolve(states)?.color,
            isNot(ring),
            reason:
                '${isDark ? 'dark' : 'light'}: the chip theme is carrying the '
                'focus ring in its identity slot under $states',
          );
        }
      }
    });

    test('the label answers to selection and to being disabled', () {
      // Carried by `labelStyle.color` as a `WidgetStateColor`, because
      // `ChoiceChip` merges `secondaryLabelStyle` *over* `labelStyle` when
      // selected — a plain colour there wins for the selected pill and takes
      // the disabled state with it.
      for (final isDark in <bool>[false, true]) {
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final color = theme.chipTheme.labelStyle?.color;
        expect(
          color,
          isA<WidgetStateColor>(),
          reason: 'the label colour does not resolve per state',
        );

        final states = color! as WidgetStateColor;
        // `onSecondaryContainer` on `secondaryContainer` —
        // `_ChoiceChipDefaultsM3.labelStyle`'s pair, restored at M100.22 from
        // the brand container the 2026-08-20 review had put here. The role
        // identity is pinned in `m3_role_contract_test.dart`; this file cares
        // that the *state resolution* still happens in the slot Material reads.
        expect(
          states.resolve(<WidgetState>{WidgetState.selected}),
          theme.colorScheme.onSecondaryContainer,
        );
        expect(
          states.resolve(<WidgetState>{}),
          theme.colorScheme.onSurfaceVariant,
        );
        expect(
          states.resolve(<WidgetState>{WidgetState.disabled}),
          isNot(states.resolve(<WidgetState>{})),
          reason: 'a disabled label is indistinguishable from an enabled one',
        );
      }
    });

    testWidgets('the painted fill is the one the theme resolved', (
      tester,
    ) async {
      // Everything above reads the theme. This reads the tree, because the
      // failure being guarded against is Material declining to consult the
      // theme at all — which no amount of asserting on `ChipThemeData` catches.
      await pump(
        tester,
        const MxPillButton(label: 'A-Z', isSelected: true, onPressed: null),
      );

      final ink = tester.widget<Ink>(
        find.descendant(of: find.byType(RawChip), matching: find.byType(Ink)),
      );
      final painted = (ink.decoration! as ShapeDecoration).color;

      expect(
        painted,
        buildLightTheme().chipTheme.color!.resolve(<WidgetState>{
          WidgetState.selected,
          WidgetState.disabled,
        }),
      );
    });

    testWidgets('the glyph rides the label through every state', (
      tester,
    ) async {
      // `ChipThemeData.iconTheme` is a plain `IconThemeData` with no per-state
      // slot, so it stated the resting ink for all of them: a *selected* pill
      // printed a brand-ink word beside a grey glyph, and a *disabled* one a
      // faded word beside a glyph at full strength. Read from the tree, like
      // the test above, because the answer now lives in the widget and no
      // assertion on `ChipThemeData` can reach it.
      final WidgetStateColor labelColor =
          buildLightTheme().chipTheme.labelStyle!.color! as WidgetStateColor;

      Future<void> expectGlyphMatchesLabel(
        String name, {
        required bool isSelected,
        required bool isEnabled,
        required Set<WidgetState> states,
      }) async {
        await pump(
          tester,
          MxPillButton(
            label: 'A-Z',
            icon: Icons.sort,
            isSelected: isSelected,
            onPressed: isEnabled ? () {} : null,
          ),
        );

        final glyph = tester.widget<Icon>(
          find.descendant(
            of: find.byType(RawChip),
            matching: find.byType(Icon),
          ),
        );

        expect(glyph.color, labelColor.resolve(states), reason: name);
      }

      await expectGlyphMatchesLabel(
        'selected',
        isSelected: true,
        isEnabled: true,
        states: const <WidgetState>{WidgetState.selected},
      );
      await expectGlyphMatchesLabel(
        'resting',
        isSelected: false,
        isEnabled: true,
        states: const <WidgetState>{},
      );
      await expectGlyphMatchesLabel(
        'disabled',
        isSelected: false,
        isEnabled: false,
        states: const <WidgetState>{WidgetState.disabled},
      );
    });
  });
}
