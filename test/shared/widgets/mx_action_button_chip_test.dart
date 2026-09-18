import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/components/actions/app_button_themes.dart'
    show buttonLabelWeight;
import 'package:memox/core/theme/foundations/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

/// `MxActionButtonSize.chip` — the one rung whose look ignores `variant`.
///
/// The v3 handoff's `themeRoleUsage` table gives this rung one container
/// (`surfaceContainerLowest`) and one border (`border-ghost`) and no per-tone
/// row, so every assertion below is made for every variant: passing
/// `destructive` must not paint a red chip.
void main() {
  final Map<String, ThemeData> themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  // A fresh tree per call: the label is an `AnimatedDefaultTextStyle`, and a
  // re-pump over a previous case reads that case's style mid-tween.
  Future<void> pump(
    WidgetTester tester,
    ThemeData theme, {
    MxActionButtonVariant variant = MxActionButtonVariant.primary,
    VoidCallback? onPressed = _noop,
    bool isLoading = false,
    bool shouldKeepLabelWhileLoading = false,
    IconData? icon,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: MxActionButton(
              label: 'Tag',
              size: MxActionButtonSize.chip,
              variant: variant,
              onPressed: onPressed,
              isLoading: isLoading,
              shouldKeepLabelWhileLoading: shouldKeepLabelWhileLoading,
              icon: icon,
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle effective(WidgetTester tester, ThemeData theme) {
    final FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );

    return (button.style ?? const ButtonStyle()).merge(
      theme.filledButtonTheme.style,
    );
  }

  Color? fill(ButtonStyle style, Set<WidgetState> states) =>
      style.backgroundColor?.resolve(states);

  test('the chip body is 28, the bottom rung of the ladder', () {
    expect(AppSizing.controlChip, 28);
    expect(AppSizing.controlChip, lessThan(AppSizing.controlDense));
  });

  for (final MapEntry<String, ThemeData> mode in themes.entries) {
    final ThemeData theme = mode.value;
    final ColorScheme scheme = theme.colorScheme;

    group('${mode.key}: geometry', () {
      testWidgets('paints 28 and the finger still gets 48', (tester) async {
        await pump(tester, theme);

        final Finder button = find.byType(MxActionButton);
        final Finder ink = find
            .descendant(of: button, matching: find.byType(Material))
            .first;

        expect(tester.getRect(ink).height, AppSizing.controlChip);
        expect(
          tester.getRect(button).height,
          greaterThanOrEqualTo(AppSizing.touchTarget),
        );
      });

      testWidgets('is a pill padded 8 either side', (tester) async {
        await pump(tester, theme);

        final ButtonStyle style = effective(tester, theme);

        expect(
          style.shape?.resolve(<WidgetState>{}),
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
        expect(
          style.padding?.resolve(<WidgetState>{}),
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        );
        expect(style.tapTargetSize, MaterialTapTargetSize.padded);
      });

      testWidgets('sets the label in label-md at the button weight', (
        tester,
      ) async {
        await pump(tester, theme);

        final TextStyle drawn = DefaultTextStyle.of(
          tester.element(find.text('Tag')),
        ).style;

        expect(drawn.fontSize, theme.textTheme.labelMedium!.fontSize);
        expect(drawn.fontWeight, buttonLabelWeight);
      });

      testWidgets('paints a 16 glyph', (tester) async {
        await pump(tester, theme, icon: Icons.add);

        expect(
          tester.getSize(find.byIcon(Icons.add)),
          const Size.square(AppIconSize.sm),
        );
      });
    });

    group('${mode.key}: colour ignores the variant', () {
      for (final MxActionButtonVariant variant
          in MxActionButtonVariant.values) {
        testWidgets('${variant.name}: fill, edge and ink are the chip\'s', (
          tester,
        ) async {
          await pump(tester, theme, variant: variant);

          final ButtonStyle style = effective(tester, theme);
          final Set<WidgetState> resting = <WidgetState>{};

          expect(fill(style, resting), scheme.surfaceContainerLowest);
          expect(
            style.foregroundColor?.resolve(resting),
            scheme.onSurfaceVariant,
          );
          expect(
            style.side?.resolve(resting),
            AppDecorations.hairlineEdge(scheme),
          );
          // Always a `FilledButton`, whatever the variant would have built.
          expect(find.byType(OutlinedButton), findsNothing);
        });

        testWidgets('${variant.name}: focus swaps the edge for the ring', (
          tester,
        ) async {
          await pump(tester, theme, variant: variant);

          final ButtonStyle style = effective(tester, theme);

          expect(
            style.side?.resolve(<WidgetState>{WidgetState.focused}),
            AppInteractionStates.focusIndicator(scheme),
          );
        });
      }

      testWidgets('press, focus and hover lay the ink at the state alphas', (
        tester,
      ) async {
        await pump(tester, theme);

        final ButtonStyle style = effective(tester, theme);
        final Color ink = scheme.onSurfaceVariant;

        expect(
          style.overlayColor?.resolve(<WidgetState>{
            WidgetState.pressed,
            WidgetState.hovered,
          }),
          ink.withValues(alpha: AppStateOpacity.stateLayerPressed),
        );
        expect(
          style.overlayColor?.resolve(<WidgetState>{WidgetState.focused}),
          ink.withValues(alpha: AppStateOpacity.stateLayerFocus),
        );
        expect(
          style.overlayColor?.resolve(<WidgetState>{WidgetState.hovered}),
          ink.withValues(alpha: AppStateOpacity.stateLayerHover),
        );
        expect(style.overlayColor?.resolve(<WidgetState>{}), isNull);
      });
    });

    group('${mode.key}: disabled', () {
      testWidgets('dims the whole control once and keeps the enabled colours', (
        tester,
      ) async {
        await pump(tester, theme, onPressed: null);

        final ButtonStyle style = effective(tester, theme);
        final Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};

        // Not the solid `disabledSurface` / `onDisabled` pair: that on top of a
        // 0.38 opacity would dim it twice.
        expect(fill(style, disabled), scheme.surfaceContainerLowest);
        expect(
          style.foregroundColor?.resolve(disabled),
          scheme.onSurfaceVariant,
        );
        expect(
          style.side?.resolve(disabled),
          AppDecorations.hairlineEdge(scheme),
        );

        final Opacity dim = tester.widget<Opacity>(
          find
              .ancestor(
                of: find.byType(FilledButton),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(dim.opacity, AppStateOpacity.disabled);
      });

      testWidgets('an enabled chip is not dimmed', (tester) async {
        await pump(tester, theme);

        expect(
          find.ancestor(
            of: find.byType(FilledButton),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
      });

      testWidgets('loading disables it, so it dims like any disabled chip', (
        tester,
      ) async {
        await pump(tester, theme, isLoading: true);

        final Opacity dim = tester.widget<Opacity>(
          find
              .ancestor(
                of: find.byType(FilledButton),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(dim.opacity, AppStateOpacity.disabled);
      });

      testWidgets('keeping the label while loading does not repaint the fill', (
        tester,
      ) async {
        for (final MxActionButtonVariant variant
            in MxActionButtonVariant.values) {
          await pump(
            tester,
            theme,
            variant: variant,
            isLoading: true,
            shouldKeepLabelWhileLoading: true,
          );

          final ButtonStyle style = effective(tester, theme);
          final Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};

          expect(
            fill(style, disabled),
            scheme.surfaceContainerLowest,
            reason: '${variant.name} chip took the variant\'s busy fill',
          );
          expect(
            style.foregroundColor?.resolve(disabled),
            scheme.onSurfaceVariant,
            reason: '${variant.name} chip took the variant\'s busy label',
          );
        }
      });
    });
  }
}

void _noop() {}
