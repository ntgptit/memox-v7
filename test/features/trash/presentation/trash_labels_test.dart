import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/failures/deck_move_failure.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

/// The refusal-to-copy mapping, pinned per reason.
///
/// The repository refuses with a typed [DeckMoveRejection]; what the user
/// reads comes from [TrashLabels.trashMoveRejection]. Nothing else fails red
/// if a future edit drops a specific reason back to the generic write-error
/// line — the deck feature's own move picker pins its copy the same way.
void main() {
  final english = AppLocalizationsEn();

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('holdsCards renders its own sentence, not the generic '
      'write error', (tester) async {
    final context = await pumpContext(tester);

    expect(
      context.trashMoveRejection(DeckMoveRejection.holdsCards),
      english.deckMoveRejectHoldsCards,
    );
    expect(
      context.trashMoveRejection(DeckMoveRejection.holdsCards),
      isNot(english.writeErrorMessage),
    );
  });
}
