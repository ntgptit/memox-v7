import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
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
/// It asserts *relationships and floors* — a state layer answers where the
/// fill stays put, a focus indicator clears 3:1 on the fill it is drawn over,
/// a label pair clears 4.5:1 — and pins exact tokens only where a milestone
/// already pinned them (`borderControl` on the secondary edge, M99.63/M99.75).
/// Exact-token claims for destructive live in `mx_components_test.dart`; the
/// *composited* pixel under a pointer is `mx_action_button_composite_state_test.dart`'s.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'high-contrast light': buildHighContrastLightTheme(),
    'high-contrast dark': buildHighContrastDarkTheme(),
  };

  const filledVariants = <String, MxActionButtonVariant>{
    'primary': MxActionButtonVariant.primary,
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
            expect(
              contrast(restInk!, restFill!),
              greaterThanOrEqualTo(4.5),
              reason: '$themeName $variantName: label under AA on its own fill',
            );

            // **The fill stays put; the state layer answers** (M100.36).
            //
            // OLD assertion: `fill(hovered) != restFill`, `fill(pressed) !=
            // restFill` — the contract that hover and press *lerp the fill*
            // toward `onSurface`. It encoded a fix for the wrong half of a
            // problem: the `primary`-based `controlOverlay` was invisible on
            // the brand fill, so the fill was moved instead of the overlay's
            // colour — and the overlay kept painting underneath, indigo over
            // red on the error pair (#432 §5).
            // NEW contract: `backgroundColor` is its role in every enabled
            // state and `overlayColor` is the pair's own `on` colour at M3's
            // alphas. AUTHORITY: `_FilledButtonDefaultsM3.backgroundColor`
            // and `.overlayColor`, Flutter 3.44.8. The composite is measured
            // in `mx_action_button_composite_state_test.dart`.
            Color? layer(Set<WidgetState> states) =>
                resolved(tester, (s) => s.overlayColor, states);
            for (final states in <Set<WidgetState>>[
              hovered,
              pressed,
              focused,
            ]) {
              expect(
                fill(states),
                restFill,
                reason: '$themeName $variantName: the fill moved under $states',
              );
              expect(
                layer(states),
                isNotNull,
                reason: '$themeName $variantName: no state layer for $states',
              );
              expect(
                layer(states)!.withValues(alpha: 1),
                restInk,
                reason:
                    '$themeName $variantName: the layer under $states is not '
                    'the fill-s own ink',
              );
            }

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
    for (final themeEntry in themes.entries) {
      testWidgets('${themeEntry.key} · destructive keeps its words legible '
          'while loading', (tester) async {
        // #432 P1-2: the destructive branch built its style straight from
        // `buildFilledStyle` and never consumed `busyStyle`, so keeping the
        // label while loading fell to `disabledSurface` / `onDisabled` —
        // 2.05:1 in light — on the one sentence saying a deletion is running.
        await pump(
          tester,
          themeEntry.value,
          MxActionButtonVariant.destructive,
          isLoading: true,
          shouldKeepLabelWhileLoading: true,
        );

        final Color? fill = resolved(
          tester,
          (s) => s.backgroundColor,
          disabled,
        );
        final Color? ink = resolved(tester, (s) => s.foregroundColor, disabled);
        expect(
          fill,
          themeEntry.value.colorScheme.error,
          reason: themeEntry.key,
        );
        expect(
          contrast(ink!, fill!),
          greaterThanOrEqualTo(4.5),
          reason: '${themeEntry.key}: the loading label is under AA',
        );
      });
    }

    testWidgets('keeping the label drops the icon, and only then', (
      tester,
    ) async {
      // The spinner takes the leading slot; two indicators for one state is
      // one too many. Pinned because the parameter name says nothing about it
      // and the card editor's Save relies on it (#432 P3-4).
      Future<void> pumpIcon({required bool isLoading}) => tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: Center(
              child: MxActionButton(
                label: 'Save',
                icon: Icons.check,
                isLoading: isLoading,
                shouldKeepLabelWhileLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await pumpIcon(isLoading: false);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await pumpIcon(isLoading: true);
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

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
    testWidgets('the gap closes from sm to xs as the text scales', (
      tester,
    ) async {
      // `_FilledButtonWithIconChild` lerps 8 → 4 between 1.0× and 2.0×
      // (`filled_button.dart:512`); a fixed 8 kept 4dp the 320 × 2.0 stress
      // width could not spare (#432 P2-5).
      Future<double> gapAt(double textScale) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
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
        final icon = tester.getRect(find.byIcon(Icons.play_arrow));
        final label = tester.getRect(find.text('Study'));

        return label.left - icon.right;
      }

      expect(await gapAt(1), AppSpacing.sm);
      expect(await gapAt(2), AppSpacing.xs);
      final mid = await gapAt(1.5);
      expect(mid, greaterThan(AppSpacing.xs));
      expect(mid, lessThan(AppSpacing.sm));
    });

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
