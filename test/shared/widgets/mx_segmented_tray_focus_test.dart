import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

import '../../visual_audit/audit_raster.dart';

enum _Choice { first, second }

void main() {
  testWidgets('an earlier focused ring paints above a later selected sibling', (
    tester,
  ) async {
    final captureKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: captureKey,
              child: MxSegmentedTray<_Choice>(
                options: const <MxSegmentedTrayOption<_Choice>>[
                  MxSegmentedTrayOption<_Choice>(
                    value: _Choice.first,
                    label: 'First',
                  ),
                  MxSegmentedTrayOption<_Choice>(
                    value: _Choice.second,
                    label: 'Second',
                  ),
                ],
                selected: _Choice.second,
                variant: MxSegmentedTrayVariant.settings,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final firstTarget = tester.getRect(find.byType(MxTapTarget).first);
    final secondTarget = tester.getRect(find.byType(MxTapTarget).at(1));
    final capture = await RasterCapture.capture(
      tester,
      boundaryFinder: find.byKey(captureKey),
    );
    final theme = Theme.of(
      tester.element(find.byKey(MxSegmentedTray.surfaceKey)),
    );

    expect(
      capture.farthestFrom(
        theme.colorScheme.surfaceContainerLowest,
        Rect.fromLTWH(secondTarget.left, firstTarget.center.dy - 2, 2, 4),
      ),
      theme.colorScheme.primary,
      reason:
          'the earlier option\'s right focus stroke must paint above the '
          'later selected surface',
    );
  });
}
