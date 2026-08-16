import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';

/// The contract every caller of the confirm dialog relies on, asserted once.
///
/// **This file exists because a claim about its callers went unchecked.** The
/// live region was added with a comment saying both callers that can fail
/// *append* their reason to the body — and one of them replaces it instead
/// (D26). Nothing was red, because the only test of the behaviour lived in one
/// caller's own suite and asserted that caller's shape.
///
/// So the assertion here is deliberately caller-agnostic: whatever a caller
/// puts in `message`, and however it changes it, the body is a live region and
/// the title is not. That is the part the shared widget owes; what each caller
/// *says* is its own business and is recorded in D26.
void main() {
  Future<void> pumpDialog(WidgetTester tester, String message) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxConfirmDialog(
            title: 'Delete this?',
            message: message,
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder bodyText() => find
      .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
      .at(1);

  testWidgets('the body is a live region, whatever the caller puts in it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDialog(tester, 'This deck and 12 cards will be deleted.');

    expect(tester.getSemantics(bodyText()), isSemantics(isLiveRegion: true));
    handle.dispose();
  });

  testWidgets('the title is not — it never changes, so announcing it would '
      'repeat', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDialog(tester, 'This deck and 12 cards will be deleted.');

    final title = tester.getSemantics(
      find
          .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
          .first,
    );

    expect(title, isNot(isSemantics(isLiveRegion: true)));
    handle.dispose();
  });

  testWidgets('a replaced body and an appended body are both announced', (
    tester,
  ) async {
    // The two shapes D26 records — deck replaces the question with the reason,
    // tag appends the reason to it. The widget owes the announcement for both;
    // the difference in wording is theirs.
    final handle = tester.ensureSemantics();

    await pumpDialog(tester, 'Could not delete. Please try again.');
    expect(tester.getSemantics(bodyText()), isSemantics(isLiveRegion: true));

    await pumpDialog(
      tester,
      'Delete this tag?\n\nCould not delete. Please try again.',
    );
    expect(tester.getSemantics(bodyText()), isSemantics(isLiveRegion: true));
    handle.dispose();
  });
}
