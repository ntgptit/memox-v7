import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

/// Which side the glyph sits on, and the two things that must not change with
/// it.
///
/// **Measured by geometry, not by widget order.** A test that read the `Row`'s
/// children would pass on a build that laid them out right-to-left, and the
/// whole point of the axis is where the glyph *lands*. `getRect` answers that;
/// the tree does not.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  Future<(Rect icon, Rect label)> pump(
    WidgetTester tester,
    MxActionButtonIconSide side,
  ) async {
    await tester.pumpWidget(
      host(
        MxActionButton(
          label: 'Study',
          icon: Icons.arrow_forward,
          iconSide: side,
          onPressed: _noop,
        ),
      ),
    );

    return (
      tester.getRect(find.byIcon(Icons.arrow_forward)),
      tester.getRect(find.text('Study')),
    );
  }

  testWidgets('leading puts the glyph before the word', (tester) async {
    final (icon, label) = await pump(tester, MxActionButtonIconSide.leading);

    expect(icon.right, lessThanOrEqualTo(label.left));
  });

  testWidgets('trailing puts it after', (tester) async {
    final (icon, label) = await pump(tester, MxActionButtonIconSide.trailing);

    expect(icon.left, greaterThanOrEqualTo(label.right));
  });

  testWidgets(
    'leading is the default, and every existing caller relies on it',
    (tester) async {
      await tester.pumpWidget(
        host(
          const MxActionButton(
            label: 'Save',
            icon: Icons.check,
            onPressed: _noop,
          ),
        ),
      );

      expect(
        tester.getRect(find.byIcon(Icons.check)).right,
        lessThanOrEqualTo(tester.getRect(find.text('Save')).left),
      );
    },
  );

  testWidgets('the gap is the same on either side', (tester) async {
    // `_iconGap` answers "how far a glyph stands from this word at this text
    // scale". That distance does not depend on which side it stands on, and a
    // trailing branch that quietly used a different one would be a second
    // spacing rule nobody declared.
    final (leadIcon, leadLabel) = await pump(
      tester,
      MxActionButtonIconSide.leading,
    );
    final (trailIcon, trailLabel) = await pump(
      tester,
      MxActionButtonIconSide.trailing,
    );

    expect(
      trailIcon.left - trailLabel.right,
      moreOrLessEquals(leadLabel.left - leadIcon.right, epsilon: 0.01),
    );
  });

  testWidgets('the spinner takes the leading slot whichever side is set', (
    tester,
  ) async {
    // Stated in the field's own doc: "◌ Exporting…" is the row a reader
    // expects, and a spinner arriving to the right of a label reads as a
    // second control rather than as the button's own state.
    await tester.pumpWidget(
      host(
        const MxActionButton(
          label: 'Exporting…',
          icon: Icons.arrow_forward,
          iconSide: MxActionButtonIconSide.trailing,
          isLoading: true,
          shouldKeepLabelWhileLoading: true,
          onPressed: _noop,
        ),
      ),
    );

    expect(
      find.byIcon(Icons.arrow_forward),
      findsNothing,
      reason: 'two indicators for one state is one too many',
    );
    expect(
      tester.getRect(find.byType(CircularProgressIndicator)).right,
      lessThanOrEqualTo(tester.getRect(find.text('Exporting…')).left),
    );
  });
}

void _noop() {}
