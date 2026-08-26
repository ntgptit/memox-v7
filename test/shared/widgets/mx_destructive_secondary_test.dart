import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/theme_context_extension.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The three axes added for the card editor, each proved on its own.
///
/// They are here rather than in the editor's tests because they are shared
/// surface: the next caller inherits whatever these assert.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('MxActionButtonVariant.destructiveSecondary', () {
    testWidgets('is an outlined button, not a filled one', (tester) async {
      await pump(
        tester,
        MxActionButton(
          label: 'Delete card',
          variant: MxActionButtonVariant.destructiveSecondary,
          onPressed: () {},
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('carries error in both the label and the edge', (tester) async {
      await pump(
        tester,
        MxActionButton(
          label: 'Delete card',
          variant: MxActionButtonVariant.destructiveSecondary,
          onPressed: () {},
        ),
      );

      final BuildContext context = tester.element(find.byType(OutlinedButton));
      final Color error = Theme.of(context).colorScheme.error;
      final ButtonStyle style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;

      const Set<WidgetState> resting = <WidgetState>{};
      expect(style.foregroundColor!.resolve(resting), error);
      expect(style.side!.resolve(resting)!.color, error);
      // Danger is not carried by colour alone — the label says `Delete`, and
      // the edge and the words agree — but it must at least be carried *by*
      // colour too, or the outlined variant reads as an ordinary secondary.
    });

    testWidgets('goes grey when disabled instead of staying armed', (
      tester,
    ) async {
      await pump(
        tester,
        const MxActionButton(
          label: 'Delete card',
          variant: MxActionButtonVariant.destructiveSecondary,
          onPressed: null,
        ),
      );

      final ButtonStyle style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;
      const Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};
      final BuildContext context = tester.element(find.byType(OutlinedButton));
      final Color error = Theme.of(context).colorScheme.error;

      // The bug `styleFrom` would have shipped: a flat property shadows the
      // resolver, so the button keeps its full-strength red while inert.
      expect(style.foregroundColor!.resolve(disabled), isNot(error));
      expect(style.side!.resolve(disabled)!.color, isNot(error));
    });

    testWidgets('keeps the touch floor every other button has', (tester) async {
      await pump(
        tester,
        MxActionButton(
          label: 'Delete card',
          variant: MxActionButtonVariant.destructiveSecondary,
          onPressed: () {},
        ),
      );

      expect(
        tester.getRect(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('MxIconButtonTone', () {
    testWidgets('standard leaves the theme to decide', (tester) async {
      await pump(
        tester,
        MxIconButton(
          icon: Icons.flag_outlined,
          semanticLabel: 'Flag card',
          onPressed: () {},
        ),
      );

      expect(tester.widget<IconButton>(find.byType(IconButton)).color, isNull);
    });

    testWidgets('warning resolves to the semantic role, not a literal', (
      tester,
    ) async {
      await pump(
        tester,
        MxIconButton(
          icon: Icons.flag,
          semanticLabel: 'Remove flag',
          tone: MxIconButtonTone.warning,
          onPressed: () {},
        ),
      );

      final BuildContext context = tester.element(find.byType(IconButton));
      // The resolved role, not a hex: `app_theme_test.dart` owns whether the
      // role itself is the right colour, and this owns whether the tone
      // reaches the button.
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).color,
        context.semanticColors.warning,
      );
    });
  });

  group('MxTextFieldAction', () {
    testWidgets('renders inside the field and meets the touch floor', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'noun');
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Add tag',
          trailingAction: MxTextFieldAction(
            icon: Icons.add,
            semanticLabel: 'Add this tag',
            onPressed: () {},
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(TextField),
        ),
        findsOneWidget,
      );
      final Rect rect = tester.getRect(find.byType(IconButton));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
    });

    testWidgets('a null callback leaves it visible and inert', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Add tag',
          trailingAction: const MxTextFieldAction(
            icon: Icons.add,
            semanticLabel: 'Add this tag',
            onPressed: null,
          ),
        ),
      );

      // Visible, so it does not appear under the finger as the first character
      // lands; inert, so it cannot submit nothing.
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    });

    testWidgets('no action leaves the field exactly as it was', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(controller: controller, label: 'Deck name'),
      );

      expect(find.byType(IconButton), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.suffixIcon,
        isNull,
      );
      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .decoration!
            .suffixIconConstraints,
        isNull,
      );
    });
  });
}
