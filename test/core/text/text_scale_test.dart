import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/text_scale.dart';

import '../../support/android_text_scaler.dart';

/// The factor a layout threshold is allowed to be multiplied by, and the reason
/// the obvious call does not produce it.
void main() {
  /// Reads the factor the way a widget would, under [scaler].
  Future<double> factorUnder(
    WidgetTester tester,
    TextScaler scaler, {
    required double rungSp,
  }) async {
    late double factor;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: Builder(
          builder: (context) {
            factor = layoutScaleOf(context, rung: TextStyle(fontSize: rungSp));

            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return factor;
  }

  group('the platform curve this exists for', () {
    test('Android compresses large sizes and is flat past the table', () {
      const scaler = AndroidTextScaler.largest;

      // Body rungs grow by exactly the factor a reader would name the setting
      // by, which is what makes the comparison with `TextScaler.linear(2.0)`
      // fair: same amount of scaling, different shape.
      expect(scaler.scale(12), 24);
      expect(scaler.scale(14), 28);
      expect(scaler.scale(16), closeTo(32, 0.01));

      // Large "fonts" grow less...
      expect(scaler.scale(30), 52);
      // ...and past the end of the table not at all.
      expect(scaler.scale(100), 100);
    });

    test('so scaling a breakpoint as if it were a font size does nothing', () {
      const scaler = AndroidTextScaler.largest;

      // The old idiom, at both named sites. On the device where the row most
      // needs to stack, the threshold comes back unchanged.
      expect(scaler.scale(240), 240, reason: 'CardImportPairWidget threshold');
      expect(scaler.scale(320), 320, reason: 'starter row threshold');

      // A linear scaler cannot show this: there, both look right.
      expect(const TextScaler.linear(2).scale(240), 480);
      expect(const TextScaler.linear(2).scale(320), 640);
    });
  });

  group('layoutScaleOf', () {
    testWidgets('is 1.0 with no scaling', (tester) async {
      expect(await factorUnder(tester, TextScaler.noScaling, rungSp: 14), 1.0);
    });

    testWidgets('asks the rung, so the non-linear curve is respected', (
      tester,
    ) async {
      // 14sp doubles; the threshold built on it doubles with it.
      expect(
        await factorUnder(tester, AndroidTextScaler.largest, rungSp: 14),
        closeTo(2.0, 0.001),
      );
      // 12sp doubles too — the compression starts above the body rungs.
      expect(
        await factorUnder(tester, AndroidTextScaler.largest, rungSp: 12),
        closeTo(2.0, 0.001),
      );
      // One step down, the factor follows the platform rather than a constant.
      expect(
        await factorUnder(tester, AndroidTextScaler.large, rungSp: 14),
        closeTo(1.5, 0.001),
      );
    });

    testWidgets('matches the linear case exactly, so nothing ordinary moves', (
      tester,
    ) async {
      expect(
        await factorUnder(tester, const TextScaler.linear(1.3), rungSp: 16),
        closeTo(1.3, 0.001),
      );
    });
  });

  testWidgets('scaledLayoutWidth widens the dp, not the font', (tester) async {
    late double width;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: AndroidTextScaler.largest),
        child: Builder(
          builder: (context) {
            width = scaledLayoutWidth(
              context,
              dp: 240,
              rung: const TextStyle(fontSize: 14),
            );

            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // 480, not the 240 the old idiom produced.
    expect(width, closeTo(480, 0.01));
  });
}
