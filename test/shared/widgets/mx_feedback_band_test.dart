import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_feedback_band.dart';

/// The handoff Banner / Callout and OfflineBanner (M100.93): four tones and the
/// offline band, each a tinted fill, a hairline in the tone's own colour and
/// its own glyph.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  /// The edge the card paints over its child — a foreground layer since
  /// M100.33, so not on the fill's decoration.
  Color? edgeColorOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(MxCard),
          matching: find.byType(DecoratedBox),
        ),
      )
      .where((box) => box.position == DecorationPosition.foreground)
      .map((box) => (box.decoration as BoxDecoration).border)
      .whereType<Border>()
      .map((border) => border.top.color)
      .firstOrNull;

  for (final entry in themes.entries) {
    final theme = entry.value;
    final scheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;

    for (final (tone, icon) in <(MxFeedbackTone, IconData)>[
      (MxFeedbackTone.danger, Icons.error_outline),
      (MxFeedbackTone.warning, Icons.warning_amber_outlined),
      (MxFeedbackTone.info, Icons.info_outline),
      (MxFeedbackTone.success, Icons.check_circle_outline),
      (MxFeedbackTone.offline, Icons.cloud_off_outlined),
    ]) {
      testWidgets('${entry.key} · $tone: tinted fill, matching hairline, '
          'its glyph', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: MxFeedbackBand(title: 'T', message: 'M', tone: tone),
            ),
          ),
        );

        final (Color fill, Color edge) = switch (tone) {
          MxFeedbackTone.danger => (scheme.errorContainer, scheme.error),
          MxFeedbackTone.warning || MxFeedbackTone.offline => (
            semantic.warningContainer,
            semantic.warning,
          ),
          MxFeedbackTone.info => (semantic.infoContainer, scheme.primary),
          MxFeedbackTone.success => (
            semantic.successContainer,
            semantic.mastery,
          ),
        };
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(MxCard),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );

        expect(find.byIcon(icon), findsOneWidget);
        expect((box.decoration as BoxDecoration).color, fill);
        expect(edgeColorOf(tester), edge);
      });
    }
  }
}
