import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import '../../support/color_math.dart';

/// The complete boundary state matrix of `MxActionButton`, table-driven.
///
/// M99.74 measured the button healthy; this file is that measurement kept —
/// every variant × every state × every theme, resolved the way Material
/// resolves it (widget style first, theme slot second), so a resolver that
/// quietly stops answering for one state fails here rather than on a device.
///
/// It asserts *relationships and floors* — a pressed fill differs from rest, a
/// focus indicator clears 3:1 on the fill it is drawn over, a label pair
/// clears 4.5:1 — and pins exact tokens only where a milestone already pinned
/// them (`borderControl` on the secondary edge, M99.63/M99.75). Exact-token
/// claims for tonal and destructive live in `mx_components_test.dart`.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'high-contrast light': buildHighContrastLightTheme(),
    'high-contrast dark': buildHighContrastDarkTheme(),
  };

  const filledVariants = <String, MxActionButtonVariant>{
    'primary': MxActionButtonVariant.primary,
    'tonal': MxActionButtonVariant.tonal,
    'destructive': MxActionButtonVariant.destructive,
  };

  Future<void> pump(
    WidgetTester tester,
    ThemeData theme,
    MxActionButtonVariant variant, {
    bool isLoading = false,
    bool shouldKeepLabelWhileLoading = false,
    MxActionButtonSize size = MxActionButtonSize.standard,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: MxActionButton(
              label: 'Remembered',
              variant: variant,
              size: size,
              isLoading: isLoading,
              shouldKeepLabelWhileLoading: shouldKeepLabelWhileLoading,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Resolves a style property the way `ButtonStyleButton` does: the widget's
  /// own style answers first, the theme slot answers the rest. A probe that
  /// only read the widget would break the moment the widget rightly stops
  /// carrying a value the theme owns (skill §XIII).
  T? resolved<T>(
    WidgetTester tester,
    WidgetStateProperty<T?>? Function(ButtonStyle) select,
    Set<WidgetState> states,
  ) {
    final button = tester.widget<ButtonStyleButton>(
      find.bySubtype<ButtonStyleButton>(),
    );
    final context = tester.element(find.bySubtype<ButtonStyleButton>());
    final ButtonStyle? themeStyle = button is OutlinedButton
        ? OutlinedButtonTheme.of(context).style
        : FilledButtonTheme.of(context).style;

    final own = button.style == null ? null : select(button.style!);
    final fromWidget = own?.resolve(states);
    if (fromWidget != null) return fromWidget;

    return themeStyle == null ? null : select(themeStyle)?.resolve(states);
  }

  const rest = <WidgetState>{};
  const hovered = <WidgetState>{WidgetState.hovered};
  const pressed = <WidgetState>{WidgetState.pressed};
  const focused = <WidgetState>{WidgetState.focused};
  const disabled = <WidgetState>{WidgetState.disabled};

  for (final themeEntry in themes.entries) {
    final themeName = themeEntry.key;
    final theme = themeEntry.value;

    group(themeName, () {
      for (final variantEntry in filledVariants.entries) {
        for (final size in MxActionButtonSize.values) {
          final variantName = '${variantEntry.key} · ${size.name}';
          final variant = variantEntry.value;

          testWidgets('$variantName · every state answers, and none is rest', (
            tester,
          ) async {
            await pump(tester, theme, variant, size: size);

            Color? fill(Set<WidgetState> states) =>
                resolved(tester, (s) => s.backgroundColor, states);
            Color? ink(Set<WidgetState> states) =>
                resolved(tester, (s) => s.foregroundColor, states);

            final restFill = fill(rest);
            final restInk = ink(rest);
            expect(restFill, isNotNull, reason: '$variantName has no fill');
            expect(restInk, isNotNull, reason: '$variantName has no ink');
            // The light primary fill is Tokyo's `#5569FF` verbatim (owner
            // decision, M100.27) and white on it is 4.33:1 — held at 4.3, the
            // same recorded floor as `app_theme_test.dart`. Every other pair
            // keeps the full bar.
            final isAcceptedPrimary =
                variantEntry.key == 'primary' &&
                theme.brightness == Brightness.light;
            expect(
              contrast(restInk!, restFill!),
              greaterThanOrEqualTo(isAcceptedPrimary ? 4.3 : 4.5),
              reason: '$themeName $variantName: label under AA on its own fill',
            );

            // Hover and press move the fill — a blend, because an accent
            // overlay on an accent fill is the accent again and reads as no
            // state at all (AppStateOpacity.filledHoverBlend).
            expect(
              fill(hovered),
              isNot(restFill),
              reason: '$themeName $variantName: hover is invisible',
            );
            expect(
              fill(pressed),
              isNot(restFill),
              reason: '$themeName $variantName: press is invisible',
            );

            // Disabled must not look armed.
            expect(
              fill(disabled),
              isNot(restFill),
              reason: '$themeName $variantName: disabled still wears its fill',
            );

            // The focus indicator is drawn over the *resting fill*, so that is
            // the ground it must clear 3:1 on (WCAG 1.4.11) — the trap AD-14
            // records is measuring it on a ground the control never sits on.
            final focusSide = resolved(tester, (s) => s.side, focused);
            expect(
              focusSide,
              isNotNull,
              reason: '$themeName $variantName: no focus indicator',
            );
            expect(
              contrast(focusSide!.color, restFill),
              greaterThanOrEqualTo(3.0),
              reason: '$themeName $variantName: focus ring invisible on fill',
            );
          });
        }
      }

      // Both sizes here too: compact swaps geometry, and geometry properties
      // are single-state — a compact button that lost its state resolvers
      // would fail this, not the drawn-40 test in mx_components_test.
      for (final size in MxActionButtonSize.values) {
        testWidgets('secondary · ${size.name} · edge is borderControl at rest '
            'and while loading, focus ring when focused', (tester) async {
          final semantic = theme.extension<AppSemanticColors>()!;

          await pump(
            tester,
            theme,
            MxActionButtonVariant.secondary,
            size: size,
          );

          final restSide = resolved(tester, (s) => s.side, rest);
          expect(restSide, isNotNull);
          expect(
            restSide!.color,
            semantic.borderControl,
            reason:
                '$themeName: the resting secondary edge moved off '
                'borderControl (M99.63)',
          );

          final restInk = resolved(tester, (s) => s.foregroundColor, rest);
          expect(restInk, isNotNull);
          expect(
            contrast(restInk!, theme.colorScheme.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$themeName: secondary label under AA on surface',
          );

          final focusSide = resolved(tester, (s) => s.side, focused);
          expect(focusSide, isNotNull);
          expect(
            contrast(focusSide!.color, theme.colorScheme.surface),
            greaterThanOrEqualTo(3.0),
            reason: '$themeName: secondary focus ring invisible on surface',
          );

          // Hover and press wash the outlined surface — the overlay must
          // answer, because the fill has nothing to move.
          expect(
            resolved(tester, (s) => s.overlayColor, hovered),
            isNotNull,
            reason: '$themeName: secondary hover is silent',
          );
          expect(
            resolved(tester, (s) => s.overlayColor, pressed),
            isNotNull,
            reason: '$themeName: secondary press is silent',
          );

          // A saving secondary keeps its edge: the loading style used to carry
          // `borderSubtle` after the resting edge moved, so the button changed
          // colour for the duration of a save (M99.75).
          await pump(
            tester,
            theme,
            MxActionButtonVariant.secondary,
            size: size,
            isLoading: true,
            shouldKeepLabelWhileLoading: true,
          );
          final loadingSide = resolved(tester, (s) => s.side, disabled);
          expect(loadingSide, isNotNull);
          expect(
            loadingSide!.color,
            semantic.borderControl,
            reason: '$themeName: the loading secondary edge drifted (M99.75)',
          );
        });
      }
    });
  }

  group('loading keeps the contract regardless of theme', () {
    testWidgets('geometry does not move when loading starts', (tester) async {
      await pump(tester, buildLightTheme(), MxActionButtonVariant.primary);
      final before = tester.getSize(find.bySubtype<ButtonStyleButton>());

      await pump(
        tester,
        buildLightTheme(),
        MxActionButtonVariant.primary,
        isLoading: true,
      );
      expect(tester.getSize(find.bySubtype<ButtonStyleButton>()), before);
    });

    testWidgets('a loading button blocks interaction and announces busy '
        'with its name intact', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        buildLightTheme(),
        MxActionButtonVariant.primary,
        isLoading: true,
      );

      final button = tester.widget<ButtonStyleButton>(
        find.bySubtype<ButtonStyleButton>(),
      );
      expect(button.onPressed, isNull, reason: 'a second tap queues a submit');
      // `alwaysIncludeSemantics` on the alpha-0 label is what keeps the name;
      // without it the button announces as "disabled" with no words at all.
      expect(find.bySemanticsLabel('Remembered'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the kept-label spinner takes the foreground colour', (
      tester,
    ) async {
      // `primary` on `primary` is nothing at all: the theme's spinner colour
      // reads on disabled grey and vanishes on the kept brand fill.
      await pump(
        tester,
        buildLightTheme(),
        MxActionButtonVariant.primary,
        isLoading: true,
        shouldKeepLabelWhileLoading: true,
      );

      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.color, isNotNull);
      expect(
        contrast(spinner.color!, buildLightTheme().colorScheme.primary),
        greaterThanOrEqualTo(3.0),
        reason: 'the spinner must read on the fill it spins over',
      );
    });
  });

  group('icon composition', () {
    testWidgets('the icon leads the label with the shared gap, and follows '
        'it in RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: Center(
              child: MxActionButton(
                label: 'Study',
                icon: Icons.play_arrow,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final icon = tester.getRect(find.byIcon(Icons.play_arrow));
      final label = tester.getRect(find.text('Study'));
      expect(icon.right, lessThan(label.left), reason: 'LTR: icon leads');

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: MxActionButton(
                  label: 'Study',
                  icon: Icons.play_arrow,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final rtlIcon = tester.getRect(find.byIcon(Icons.play_arrow));
      final rtlLabel = tester.getRect(find.text('Study'));
      expect(
        rtlIcon.left,
        greaterThan(rtlLabel.right),
        reason: 'RTL: the row mirrors',
      );
    });
  });
}
