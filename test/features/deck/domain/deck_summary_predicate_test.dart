import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';

import '../presentation/support/deck_fixtures.dart';

/// The three predicates a deck row answers with (BR-150, BR-90, BR-142).
///
/// Named predicates rather than comparisons in widgets, so that no screen can
/// quietly collapse the two sets back into one — `hasDueCards` standing in for
/// "anything to study" is exactly how the Study button vanished from a deck of
/// twenty unlearned cards.
void main() {
  DeckSummary of({int newCards = 0, int due = 0, int total = 0}) => fakeSummary(
    id: 'd1',
    name: 'Deck',
    totalCardCount: total,
    newCardCount: newCards,
    dueCardCount: due,
  );

  test('new-only: studyable through hasNewCards alone', () {
    final summary = of(newCards: 20, total: 20);

    expect(summary.hasNewCards, isTrue);
    expect(summary.hasDueCards, isFalse);
    expect(summary.hasStudyableCards, isTrue);
  });

  test('due-only: studyable through hasDueCards alone', () {
    final summary = of(due: 5, total: 5);

    expect(summary.hasNewCards, isFalse);
    expect(summary.hasDueCards, isTrue);
    expect(summary.hasStudyableCards, isTrue);
  });

  test('mixed: both predicates hold and neither hides the other', () {
    final summary = of(newCards: 12, due: 4, total: 16);

    expect(summary.hasNewCards, isTrue);
    expect(summary.hasDueCards, isTrue);
    expect(summary.hasStudyableCards, isTrue);
  });

  test('nothing waiting: a deck with cards but no work is not studyable', () {
    final summary = of(total: 8);

    expect(summary.hasNewCards, isFalse);
    expect(summary.hasDueCards, isFalse);
    expect(summary.hasStudyableCards, isFalse);
  });

  test('empty deck: also not studyable, for the other reason', () {
    // "No cards" and "nothing due today" are different facts; the predicates
    // agree only in the boolean, and the tile keeps them worded apart.
    final summary = of();

    expect(summary.hasStudyableCards, isFalse);
    expect(summary.totalCardCount, 0);
  });
}
