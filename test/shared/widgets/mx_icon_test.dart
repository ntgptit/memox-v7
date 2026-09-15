import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/extensions/app_ink.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/shared/widgets/mx_icon.dart';

/// A20.1 P3-12 — the contract `MxIcon` exists for: a null label is silence,
/// a label is spoken, size and ink are names.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: child),
    ),
  );

  testWidgets('a null label excludes the glyph from semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MxIcon(Icons.star));

    expect(
      find.ancestor(
        of: find.byType(Icon),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    handle.dispose();
  });

  testWidgets('a label is spoken once', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MxIcon(Icons.star, semanticLabel: 'Starred'));

    expect(find.bySemanticsLabel('Starred'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(Icon),
        matching: find.byType(ExcludeSemantics),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('size is a step and ink is a name', (tester) async {
    await pump(
      tester,
      const MxIcon(Icons.star, size: MxIconSize.sm, ink: AppInk.danger),
    );
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, AppIconSize.sm);
    final context = tester.element(find.byType(Icon));
    expect(icon.color, AppInk.danger.resolve(context));
  });

  testWidgets('the glyph keeps its dp under text scaling (P3-02)', (
    tester,
  ) async {
    // Icon text-scaling policy: a control, decorative or navigation glyph
    // is a fixed dp step; only text scales. The other direction — a glyph
    // in a text run scaling with it — is the `WidgetSpan` case the SDK owns.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(body: MxIcon(Icons.star)),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxIcon)),
      const Size.square(AppIconSize.md),
    );
  });
}
