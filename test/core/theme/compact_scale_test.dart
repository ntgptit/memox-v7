import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_breakpoints.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_text_styles.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// The compact scale: what shrinks below [AppBreakpoints.compact], and — the
/// half that matters more — what does not.
void main() {
  const small = Size(320, 568);
  const normal = Size(393, 852);

  Future<ThemeData> themeAt(WidgetTester tester, Size surface) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late ThemeData seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: CompactScaleWidget(
          child: Builder(
            builder: (context) {
              seen = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return seen;
  }

  group('what the compact scale changes', () {
    testWidgets('the app bar title gets smaller', (tester) async {
      final compact = await themeAt(tester, small);
      final roomy = await themeAt(tester, normal);

      expect(compact.textTheme.titleLarge!.fontSize, 20);
      expect(roomy.textTheme.titleLarge!.fontSize, 22);
    });

    testWidgets('the study card prompt gets smaller', (tester) async {
      final compact = await themeAt(tester, small);
      final roomy = await themeAt(tester, normal);

      expect(
        compact.extension<AppTextStyles>()!.cardPrompt.fontSize,
        AppTypography.compactCardPromptSize,
      );
      expect(
        roomy.extension<AppTextStyles>()!.cardPrompt.fontSize,
        AppTypography.cardPromptSize,
      );
      // The rung beside it no longer moves: the compact pass re-sizes the
      // prompt's own slot, and `headlineMedium` stays on the M3 metric.
      expect(compact.textTheme.headlineMedium!.fontSize, 28);
    });

    testWidgets('list rows lose horizontal padding, not vertical', (
      tester,
    ) async {
      final compact = await themeAt(tester, small);
      final roomy = await themeAt(tester, normal);

      final compactPadding =
          compact.listTileTheme.contentPadding! as EdgeInsets;
      final roomyPadding = roomy.listTileTheme.contentPadding! as EdgeInsets;

      expect(compactPadding.left, AppSpacing.md);
      expect(roomyPadding.left, AppSpacing.lg);
      // Vertical rhythm is what keeps a row tappable.
      expect(compactPadding.vertical, roomyPadding.vertical);
    });

    testWidgets('screen padding drops from lg to md', (tester) async {
      for (final entry in <Size, double>{
        small: AppSpacing.md,
        normal: AppSpacing.lg,
      }.entries) {
        tester.view.physicalSize = entry.key;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            home: const CompactScaleWidget(
              child: MxContentShell(body: Text('body')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final padding = tester.widget<Padding>(
          find
              .ancestor(of: find.text('body'), matching: find.byType(Padding))
              .first,
        );

        expect(
          (padding.padding as EdgeInsets).left,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });
  });

  group('buttons', () {
    testWidgets('lose horizontal padding, keep vertical', (tester) async {
      final compact = await themeAt(tester, small);
      final roomy = await themeAt(tester, normal);

      final compactPadding =
          compact.filledButtonTheme.style!.padding!.resolve(<WidgetState>{})!
              as EdgeInsets;
      final roomyPadding =
          roomy.filledButtonTheme.style!.padding!.resolve(<WidgetState>{})!
              as EdgeInsets;

      expect(compactPadding.left, AppSpacing.md);
      expect(roomyPadding.left, AppSpacing.xl);
      expect(compactPadding.vertical, roomyPadding.vertical);
    });

    testWidgets('four study actions keep their labels at 320', (tester) async {
      // The case that made the padding worth changing. `sm2` renders four
      // actions; at 320 each button gets 68px, and 24-a-side padding left 20 for
      // the label — "Again" came out as "Ag" and the rest broke mid-word. At
      // normal text scale, with no overflow and no exception to notice it by.
      tester.view.physicalSize = small;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const CompactScaleWidget(
            child: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: MxActionButton(label: 'Again', onPressed: _noop),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: MxActionButton(label: 'Hard', onPressed: _noop),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: MxActionButton(label: 'Good', onPressed: _noop),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: MxActionButton(label: 'Easy', onPressed: _noop),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in <String>['Again', 'Hard', 'Good', 'Easy']) {
        final button = find
            .ancestor(of: find.text(label), matching: find.byType(FilledButton))
            .first;

        // One line: a wrapped label makes the button taller than the floor, so
        // the height is the tell. It was 64 before.
        expect(
          tester.getSize(button).height,
          AppSpacing.minimumTouchTarget,
          reason: label,
        );
      }
    });
  });

  group('what the compact scale must never change', () {
    testWidgets('the text link keeps its zero padding', (tester) async {
      // The link has no horizontal padding to give back, and handing it the
      // buttons' compact padding would indent the one control whose whole
      // point is sitting flush with the column.
      final compact = await themeAt(tester, small);
      final roomy = await themeAt(tester, normal);

      for (final theme in <ThemeData>[compact, roomy]) {
        expect(
          theme.textButtonTheme.style!.padding!.resolve(const <WidgetState>{}),
          EdgeInsets.zero,
        );
      }
    });

    testWidgets('readable text keeps its size', (tester) async {
      // The line this whole feature is drawn along. Scaling body and label text
      // by device width silently undoes `MediaQuery.textScaler` — the user's own
      // accessibility setting — and undoes it hardest for the people most likely
      // to need it, since large text is at least as common on a small cheap
      // phone as on a big one. Device width is not a proxy for eyesight.
      final compact = await themeAt(tester, small);
      final roomy = await themeAt(tester, normal);

      for (final entry in <String, (TextStyle?, TextStyle?)>{
        'bodyLarge': (compact.textTheme.bodyLarge, roomy.textTheme.bodyLarge),
        'bodyMedium': (
          compact.textTheme.bodyMedium,
          roomy.textTheme.bodyMedium,
        ),
        'bodySmall': (compact.textTheme.bodySmall, roomy.textTheme.bodySmall),
        'titleMedium': (
          compact.textTheme.titleMedium,
          roomy.textTheme.titleMedium,
        ),
        'labelLarge': (
          compact.textTheme.labelLarge,
          roomy.textTheme.labelLarge,
        ),
      }.entries) {
        expect(
          entry.value.$1!.fontSize,
          entry.value.$2!.fontSize,
          reason: entry.key,
        );
      }
    });

    testWidgets('the 48x48 touch target survives', (tester) async {
      // `VisualDensity.compact` would have been the one-line route and it
      // subtracts 8dp from every button, taking this to 40x40 — under the floor
      // a thumb needs, and under the floor this theme was measured against.
      tester.view.physicalSize = small;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: CompactScaleWidget(
            child: Scaffold(
              body: Center(
                child: MxIconButton(
                  icon: Icons.delete_outline,
                  semanticLabel: 'Delete',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(IconButton));

      expect(size.width, greaterThanOrEqualTo(AppSpacing.minimumTouchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minimumTouchTarget));
    });
  });

  group('AppBreakpoints.isCompact', () {
    test('the boundary is exclusive', () {
      // 360 is the common Android width. It must land on the roomy side, or the
      // compact scale becomes the default rather than the exception.
      expect(AppBreakpoints.isCompact(320), isTrue);
      expect(AppBreakpoints.isCompact(359.9), isTrue);
      expect(AppBreakpoints.isCompact(AppBreakpoints.compact), isFalse);
      expect(AppBreakpoints.isCompact(393), isFalse);
    });
  });
}

void _noop() {}
