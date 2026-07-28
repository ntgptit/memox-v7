import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';

void main() {
  testWidgets('app builds and exposes its root widget', (tester) async {
    await tester.pumpWidget(const MemoxApp());

    expect(find.byType(MemoxApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
