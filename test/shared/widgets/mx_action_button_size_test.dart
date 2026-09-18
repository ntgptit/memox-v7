import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/components/actions/app_button_themes.dart'
    show buttonLabelWeight;
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

/// What each size *draws*, and the floor none of them may take with it.
///
/// **The body and the target are two boxes, and the whole point of the enum is
/// that they can differ.** `MaterialTapTargetSize.padded` makes the widget the
/// target and the ink `Material` inside it the body, so a test that measures
/// the outer box reports every size as 48 and proves nothing. This one
/// measures both and names which is which.
void main() {
  final ThemeData light = buildLightTheme();

  Future<(double body, double target)> pump(
    WidgetTester tester,
    MxActionButtonSize size,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: Scaffold(
          body: Center(
            child: MxActionButton(label: 'Study', size: size, onPressed: _noop),
          ),
        ),
      ),
    );

    final button = find.byType(MxActionButton);
    final ink = find
        .descendant(of: button, matching: find.byType(Material))
        .first;

    return (tester.getRect(ink).height, tester.getRect(button).height);
  }

  test('the five bodies are the five tokens, in order', () {
    // Stated as an ordering rather than four numbers: what the enum promises
    // is a ladder, and a ladder that stops descending is the bug.
    expect(AppSizing.controlChip, lessThan(AppSizing.controlDense));
    expect(AppSizing.controlDense, lessThan(AppSizing.controlSmall));
    expect(AppSizing.controlSmall, lessThan(AppSizing.controlCompact));
    expect(AppSizing.controlCompact, lessThan(AppSizing.touchTarget));
  });

  testWidgets('small draws 36 and the finger still gets 48', (tester) async {
    final (body, target) = await pump(tester, MxActionButtonSize.small);

    expect(body, AppSizing.controlSmall);
    expect(
      target,
      greaterThanOrEqualTo(AppSizing.touchTarget),
      reason: 'a smaller body must never mean a smaller target',
    );
  });

  testWidgets('small pads 12 bare and 16 with a glyph', (tester) async {
    for (final (IconData? icon, double inset) in <(IconData?, double)>[
      (null, AppSpacing.md),
      (Icons.add, AppSpacing.lg),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: light,
          home: Scaffold(
            body: Center(
              child: MxActionButton(
                label: 'Study',
                icon: icon,
                size: MxActionButtonSize.small,
                onPressed: _noop,
              ),
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.bySubtype<FilledButton>(),
      );

      expect(
        button.style!.padding!.resolve(<WidgetState>{}),
        EdgeInsets.symmetric(horizontal: inset),
        reason: 'small padding with icon: $icon',
      );
    }
  });

  testWidgets('small keeps the standard label rung; compact keeps its own', (
    tester,
  ) async {
    // `small` states no `textStyle` of its own, so the label must arrive as
    // the theme's `label-lg` at the button weight — not compact's `label-md`.
    for (final (size, rung) in <(MxActionButtonSize, TextStyle)>[
      (MxActionButtonSize.standard, light.textTheme.labelLarge!),
      (MxActionButtonSize.small, light.textTheme.labelLarge!),
      (MxActionButtonSize.compact, light.textTheme.labelMedium!),
      (MxActionButtonSize.dense, light.textTheme.labelMedium!),
    ]) {
      // A fresh tree per size: the button's text style is an
      // `AnimatedDefaultTextStyle`, and re-pumping over the previous size reads
      // that size's rung mid-tween (and asserts on the inherit mismatch).
      await tester.pumpWidget(const SizedBox.shrink());
      await pump(tester, size);

      final TextStyle drawn = DefaultTextStyle.of(
        tester.element(find.text('Study')),
      ).style;

      expect(drawn.fontSize, rung.fontSize, reason: '$size label size');
      expect(drawn.fontWeight, buttonLabelWeight, reason: '$size weight');
    }
  });

  testWidgets('small keeps the standard icon gap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: const Scaffold(
          body: Center(
            child: MxActionButton(
              label: 'Study',
              icon: Icons.add,
              size: MxActionButtonSize.small,
              onPressed: _noop,
            ),
          ),
        ),
      ),
    );

    final double gap =
        tester.getRect(find.text('Study')).left -
        tester.getRect(find.byIcon(Icons.add)).right;

    expect(gap, AppSpacing.sm);
  });

  testWidgets('standard draws its target', (tester) async {
    final (body, target) = await pump(tester, MxActionButtonSize.standard);

    expect(body, AppSizing.touchTarget);
    expect(target, greaterThanOrEqualTo(AppSizing.touchTarget));
  });

  testWidgets('compact draws 40', (tester) async {
    final (body, target) = await pump(tester, MxActionButtonSize.compact);

    expect(body, AppSizing.controlCompact);
    expect(target, greaterThanOrEqualTo(AppSizing.touchTarget));
  });

  testWidgets('dense draws 32 and the finger still gets 48', (tester) async {
    // The size added at M100.77. It is a return to a body the 2026-08-20
    // review moved *away* from — "40 is on the 4px grid and clears the 32 the
    // pill used to paint" — so it arrived as an option beside `compact` rather
    // than as an edit to it. The floor is what is not optional, and it is
    // measured here rather than trusted to the sentence above.
    final (body, target) = await pump(tester, MxActionButtonSize.dense);

    expect(body, AppSizing.controlDense);
    expect(
      target,
      greaterThanOrEqualTo(AppSizing.touchTarget),
      reason: 'a smaller body must never mean a smaller target',
    );
  });

  testWidgets('dense paints the handoff compact radius, the rest keep md', (
    tester,
  ) async {
    // The v3 handoff's "compact" rung is 32 with radius 8 — the box `dense`
    // already draws — so the radius lives on `dense`. Every other size keeps
    // the shared `AppRadius.md`; asserting both pins the branching.
    for (final (size, radius) in <(MxActionButtonSize, double)>[
      (MxActionButtonSize.standard, AppRadius.md),
      (MxActionButtonSize.small, AppRadius.md),
      (MxActionButtonSize.compact, AppRadius.md),
      (MxActionButtonSize.dense, AppRadius.sm),
    ]) {
      await pump(tester, size);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final Set<WidgetState> none = <WidgetState>{};
      final OutlinedBorder? shape = (button.style ?? const ButtonStyle()).shape
          ?.resolve(none);
      final OutlinedBorder effective =
          shape ??
          (light.filledButtonTheme.style!.shape!.resolve(none)
              as OutlinedBorder);

      expect(
        effective,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        reason: '$size radius',
      );
    }
  });

  testWidgets('every size keeps the floor at 2.0x text scale', (tester) async {
    // The body grows past its token when the label does; the floor must hold
    // at both ends of that.
    for (final size in MxActionButtonSize.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Center(
                child: MxActionButton(
                  label: 'Study',
                  size: size,
                  onPressed: _noop,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getRect(find.byType(MxActionButton)).height,
        greaterThanOrEqualTo(AppSizing.touchTarget),
        reason: '$size drops below the touch floor at 2.0x',
      );
    }
  });
}

void _noop() {}
