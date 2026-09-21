import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses the fixed icon, gap and padding geometry', (tester) async {
    await pump(tester, const MxFieldMessage(message: 'Enter a valid value'));

    final icon = tester.getRect(find.byIcon(Icons.error_outline));
    final text = tester.getRect(find.text('Enter a valid value'));
    final padding = tester.getRect(
      find.descendant(
        of: find.byType(MxFieldMessage),
        matching: find.byType(Padding),
      ),
    );

    expect(icon.size, const Size.square(AppIconSize.sm));
    expect(text.left - icon.right, AppSpacing.xs);
    expect(icon.left - padding.left, AppSpacing.xs);
    expect(icon.top - padding.top, AppSpacing.xs);
    final style = tester
        .renderObject<RenderParagraph>(find.text('Enter a valid value'))
        .text
        .style;
    expect(style?.fontSize, buildLightTheme().textTheme.labelMedium!.fontSize);
    expect(
      style?.fontWeight,
      buildLightTheme().textTheme.labelMedium!.fontWeight,
    );
  });

  testWidgets('uses contrast-safe error ink and warning fill/on-warning ink', (
    tester,
  ) async {
    await pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MxFieldMessage(message: 'Error'),
          MxFieldMessage(message: 'Warning', tone: MxFieldMessageTone.warning),
        ],
      ),
    );

    final semantic = buildLightTheme().extension<AppSemanticColors>()!;
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    final errorText = tester.renderObject<RenderParagraph>(find.text('Error'));
    final warningText = tester.renderObject<RenderParagraph>(
      find.text('Warning'),
    );

    expect(icons[0].color, buildLightTheme().colorScheme.error);
    expect(icons[1].color, semantic.warning);
    expect(errorText.text.style?.color, semantic.dangerInk);
    expect(warningText.text.style?.color, semantic.warningInk);
  });

  testWidgets('wraps complete long content rather than ellipsizing', (
    tester,
  ) async {
    const message =
        'Thông báo xác thực rất dài cần hiển thị đầy đủ cho người dùng';
    await pump(
      tester,
      const SizedBox(width: 160, child: MxFieldMessage(message: message)),
    );

    final text = tester.widget<Text>(find.text(message));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(
      tester.getSize(find.byType(MxFieldMessage)).height,
      greaterThan(AppIconSize.sm + AppSpacing.sm),
    );
  });
}
