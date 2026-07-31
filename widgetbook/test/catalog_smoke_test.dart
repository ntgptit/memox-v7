import 'package:flutter_test/flutter_test.dart';
import 'package:memox_widgetbook/main.dart';

/// The catalog is a dev tool, but a dev tool nobody tests rots silently.
/// One smoke test keeps the tree honest: every registered use-case must at
/// least construct, and the shell must build without throwing.
void main() {
  testWidgets('the catalog shell builds', (tester) async {
    await tester.pumpWidget(const MemoxWidgetbook());
    // No `pumpAndSettle`: the shell may host indefinitely animating demos
    // (spinners), which would keep it from ever settling.
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
