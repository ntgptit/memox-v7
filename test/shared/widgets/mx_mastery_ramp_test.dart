import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/shared/widgets/mx_mastery_ramp.dart';

void main() {
  testWidgets('maps the three fixed mastery bands', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      MxMasteryRamp.colorFor(context, 0.33),
      context.semanticColors.statusLearning,
    );
    expect(
      MxMasteryRamp.colorFor(context, 0.34),
      context.semanticColors.statusReviewing,
    );
    expect(
      MxMasteryRamp.colorFor(context, 0.67),
      context.semanticColors.statusMastered,
    );
    expect(
      MxMasteryRamp.trackFor(context),
      context.semanticColors.progressTrack,
    );
  });
}
