import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_create_action_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_action_bar_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// One sentence, one announcement, on both modes of one screen (SC-C3-03).
///
/// **Both modes are asserted here on purpose.** Edit was given its live region
/// when a sweep found that a screen-reader user pressed Save and was told
/// nothing at all; create rendered the identical string, after the identical
/// command, and was never looked at — because the accessibility sweep only
/// ever mounted edit. Pinning the two together is what stops the pair drifting
/// apart again the next time one of them is redesigned, which is the whole
/// defect class this file belongs to.
void main() {
  final english = AppLocalizationsEn();

  Finder failureLine() => find.text(english.cardEditorSaveFailed);

  testWidgets('create announces a failed save', (tester) async {
    final handle = tester.ensureSemantics();
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.nextCreateFailure = const DatabaseFailure(message: 'disk full');
    await pumpCardEditor(tester, repository, cardId: null);

    await tester.enterText(find.byType(TextField).at(0), 'ephemeral');
    await tester.enterText(find.byType(TextField).at(1), 'lasting briefly');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(CardCreateActionBarWidget),
        matching: find.widgetWithText(MxActionButton, english.cardEditorSave),
      ),
    );
    await tester.pumpAndSettle();

    expect(failureLine(), findsOneWidget);
    expect(tester.getSemantics(failureLine()), isSemantics(isLiveRegion: true));
    handle.dispose();
  });

  testWidgets('edit announces the same failure the same way', (tester) async {
    final handle = tester.ensureSemantics();
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card(
      'card-1',
      front: 'old front',
      back: 'old back',
    );
    repository.nextCreateFailure = const DatabaseFailure(message: 'disk full');
    await pumpCardEditor(tester, repository);

    await tester.enterText(find.byType(TextField).first, 'new front');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(CardEditorActionBarWidget),
        matching: find.widgetWithText(
          MxActionButton,
          english.cardEditorSaveChanges,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(failureLine(), findsOneWidget);
    expect(tester.getSemantics(failureLine()), isSemantics(isLiveRegion: true));
    handle.dispose();
  });
}
