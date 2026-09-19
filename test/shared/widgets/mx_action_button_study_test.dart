import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/components/actions/app_button_themes.dart'
    show buttonLabelWeight;
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

/// `MxActionButtonSize.study` — the pill a study turn ends with.
///
/// The v3 handoff's "study action": 48 tall, pill radius, padding `0 36`. A
/// shape change only — unlike `chip`, colour still comes from `variant`.
void main() {
  final ThemeData light = buildLightTheme();

  // The handoff's "study action … padding 0 36". Restated here on purpose: the
  // test must fail if the component's private constant drifts.
  const double studyInset = 36;
  // Long enough that the label, not `buttonMinWidth`, decides the width.
  const String label = 'Reveal the answer now';

  // A fresh tree per call: the label is an `AnimatedDefaultTextStyle`, and a
  // re-pump over a previous case reads that case's style mid-tween.
  Future<void> pump(
    WidgetTester tester,
    MxActionButtonSize size, {
    MxActionButtonVariant variant = MxActionButtonVariant.primary,
    VoidCallback? onPressed = _noop,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: Scaffold(
          body: Center(
            child: MxActionButton(
              label: label,
              size: size,
              variant: variant,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }

  Material ink(WidgetTester tester) => tester.widget<Material>(
    find
        .descendant(
          of: find.byType(MxActionButton),
          matching: find.byType(Material),
        )
        .first,
  );

  testWidgets('paints 48 and the finger gets at least 48', (tester) async {
    await pump(tester, MxActionButtonSize.study);

    final Finder button = find.byType(MxActionButton);
    final Finder body = find
        .descendant(of: button, matching: find.byType(Material))
        .first;

    expect(tester.getRect(body).height, AppSizing.touchTarget);
    expect(
      tester.getRect(button).height,
      greaterThanOrEqualTo(AppSizing.touchTarget),
    );
  });

  testWidgets('pads 36 either side of the label', (tester) async {
    await pump(tester, MxActionButtonSize.study);

    final Rect body = tester.getRect(
      find
          .descendant(
            of: find.byType(MxActionButton),
            matching: find.byType(Material),
          )
          .first,
    );
    final Rect text = tester.getRect(find.text(label));

    expect(text.left - body.left, studyInset);
    expect(body.right - text.right, studyInset);
  });

  testWidgets('is a pill for every variant', (tester) async {
    for (final MxActionButtonVariant variant in MxActionButtonVariant.values) {
      await pump(tester, MxActionButtonSize.study, variant: variant);

      final ShapeBorder? shape = ink(tester).shape;

      expect(shape, isA<RoundedRectangleBorder>(), reason: '$variant');
      expect(
        (shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.pill),
        reason: '$variant radius',
      );
    }
  });

  testWidgets('keeps the standard label rung', (tester) async {
    for (final MxActionButtonSize size in <MxActionButtonSize>[
      MxActionButtonSize.standard,
      MxActionButtonSize.study,
    ]) {
      await pump(tester, size);

      final TextStyle drawn = DefaultTextStyle.of(
        tester.element(find.text(label)),
      ).style;

      expect(
        drawn.fontSize,
        light.textTheme.labelLarge!.fontSize,
        reason: '$size size',
      );
      expect(drawn.fontWeight, buttonLabelWeight, reason: '$size weight');
    }
  });

  testWidgets('colour follows the variant, not the chip\'s fixed look', (
    tester,
  ) async {
    await pump(tester, MxActionButtonSize.chip);
    final Color? chipFill = ink(tester).color;

    for (final MxActionButtonVariant variant in MxActionButtonVariant.values) {
      await pump(tester, MxActionButtonSize.standard, variant: variant);
      final Material standard = ink(tester);
      await pump(tester, MxActionButtonSize.study, variant: variant);
      final Material study = ink(tester);

      expect(study.color, standard.color, reason: '$variant fill');
      expect(
        (study.shape! as RoundedRectangleBorder).side,
        (standard.shape! as RoundedRectangleBorder).side,
        reason: '$variant edge',
      );
      if (variant == MxActionButtonVariant.primary) {
        expect(study.color, light.colorScheme.primary);
        expect(study.color, isNot(chipFill));
      }
    }

    // The outlined variant keeps its border.
    await pump(
      tester,
      MxActionButtonSize.study,
      variant: MxActionButtonVariant.secondary,
    );
    expect(
      (ink(tester).shape! as RoundedRectangleBorder).side,
      isNot(BorderSide.none),
    );
  });

  testWidgets('disabled takes the solid disabled treatment, not a dim', (
    tester,
  ) async {
    await pump(tester, MxActionButtonSize.study, onPressed: null);
    final Color? disabledStudy = ink(tester).color;
    await pump(tester, MxActionButtonSize.standard, onPressed: null);
    final Color? disabledStandard = ink(tester).color;
    await pump(tester, MxActionButtonSize.study);
    final Color? enabledStudy = ink(tester).color;

    expect(disabledStudy, disabledStandard);
    expect(disabledStudy, isNot(enabledStudy));

    await pump(tester, MxActionButtonSize.study, onPressed: null);
    expect(
      find.descendant(
        of: find.byType(MxActionButton),
        matching: find.byType(Opacity),
      ),
      findsNothing,
      reason: 'only the chip dims as a whole',
    );
  });

  testWidgets('the other sizes keep their geometry', (tester) async {
    for (final (MxActionButtonSize size, double height, double radius)
        in <(MxActionButtonSize, double, double)>[
          (MxActionButtonSize.standard, AppSizing.touchTarget, AppRadius.md),
          (MxActionButtonSize.small, AppSizing.controlSmall, AppRadius.md),
          (MxActionButtonSize.compact, AppSizing.controlCompact, AppRadius.md),
          (MxActionButtonSize.dense, AppSizing.controlDense, AppRadius.sm),
          (MxActionButtonSize.chip, AppSizing.controlChip, AppRadius.pill),
        ]) {
      await pump(tester, size);

      final Material body = ink(tester);

      expect(
        tester
            .getRect(
              find
                  .descendant(
                    of: find.byType(MxActionButton),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .height,
        height,
        reason: '$size height',
      );
      expect(
        (body.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(radius),
        reason: '$size radius',
      );
    }
  });
}

void _noop() {}
