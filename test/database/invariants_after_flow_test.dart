import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';

import '../features/deck/data/support/deck_repository_harness.dart';
import '../helpers/seed.dart';
import 'invariant_queries.dart';
import 'support/test_database.dart';

/// M4.12: the fifteen data invariants hold **after the required E2E flow**, not
/// only after a seed.
///
/// **Why this exists beside `invariants_test.dart`.** That one proves each query
/// fires on its own violation and stays clean on a hand-built fixture — it
/// checks the *queries*. This checks the *app*: it drives the whole demo flow
/// through the same repositories the screens call, on a real database, and then
/// asks whether anything the flow wrote broke an invariant. A rule can be
/// perfectly expressed and still be violated by a write path nobody pointed it
/// at.
///
/// **Through repositories, not through the UI.** The UI path is covered on a
/// device by `integration_test/` and in a browser by `e2e/`; neither can run a
/// SQL invariant against the database it just wrote — the Playwright suite's
/// data lives in IndexedDB inside a browser, and the device suite has no SQL
/// seam. Here the flow goes through `DeckRepository` and `CardRepository`, which
/// are exactly what those screens call, against SQLite where the queries can
/// actually be run.
void main() {
  final h = installDeckRepositoryHarness();

  Future<void> expectEveryInvariantClean(String moment) async {
    for (final entry in invariantQueries.entries) {
      final violations = await h.db.customSelect(entry.value).get();
      expect(
        violations,
        isEmpty,
        reason:
            '${entry.key} fired $moment: '
            '${violations.map((row) => row.data).toList()}',
      );
    }
  }

  test('every invariant holds after the required demo flow', () async {
    // ---- cold start, then a root deck with a scheduler chosen (BR-11) ------
    final root = await h.deckRepository.createRootDeck(
      name: DeckName.parse('Korean').name!,
      schedulerType: SchedulerType.eightBox,
    );
    await expectEveryInvariantClean('after creating a root deck');

    // ---- a branch, then a leaf: three levels (BR-55) -----------------------
    final branch = await h.deckRepository.createSubDeck(
      name: DeckName.parse('Vocabulary').name!,
      parentDeckId: root.id,
    );
    final leaf = await h.deckRepository.createSubDeck(
      name: DeckName.parse('Food').name!,
      parentDeckId: branch.id,
    );
    await expectEveryInvariantClean('after building a three-level tree');

    // ---- a card, which locks the leaf to `card` (BR-62) --------------------
    final card = await h.cardRepository.createCard(
      deckId: leaf.id,
      front: CardText.parse('kimchi', side: CardSide.front).text!,
      back: CardText.parse('kim chi', side: CardSide.back).text!,
    );
    await expectEveryInvariantClean('after creating a card');

    // ---- edit it: content changes, the study state must not (BR-10) -------
    await h.cardRepository.updateCard(
      cardId: card.id,
      front: CardText.parse('kimchi jjigae', side: CardSide.front).text!,
      back: CardText.parse('kim chi hầm', side: CardSide.back).text!,
    );
    await expectEveryInvariantClean('after editing a card');

    // ---- flag it (BR-92) ---------------------------------------------------
    await h.cardRepository.setCardFlag(cardId: card.id, isFlagged: true);
    await expectEveryInvariantClean('after flagging a card');

    // ---- delete the card, then the whole tree (BR-03, BR-67) ---------------
    await h.cardRepository.deleteCard(card.id);
    await expectEveryInvariantClean('after deleting the card');

    await h.deckRepository.deleteDeck(root.id);
    await expectEveryInvariantClean('after deleting the root deck');

    // Nothing survives the cascade, which is itself an invariant of the flow:
    // a delete that left a card behind would satisfy every query above simply
    // by having no deck left to contradict.
    final remaining = await h.db
        .customSelect('SELECT COUNT(*) AS c FROM cards')
        .getSingle();
    expect(remaining.read<int>('c'), 0);
  });

  test('every invariant holds after a seed and the flow on top of it', () async {
    // The realistic case: the app seeds its fixtures at startup and the user
    // then works in that same database. Either alone can be clean while the two
    // together are not — a second root, a second scheduler, ids from two
    // generators.
    final report = await seedFixtureDecks(
      h.db,
      clock: () => testNow,
      idGenerator: () => 'seed-${h.idCounter++}',
    );
    expect(
      report.map((entry) => entry.outcome),
      everyElement(DeckTemplateInstallOutcome.installed),
    );
    await expectEveryInvariantClean('after seeding the fixtures');

    final root = await h.deckRepository.createRootDeck(
      name: DeckName.parse('Grammar').name!,
      // The other scheduler, so the database holds both at once (BR-06).
      schedulerType: SchedulerType.sm2,
    );
    final child = await h.deckRepository.createSubDeck(
      name: DeckName.parse('Particles').name!,
      parentDeckId: root.id,
    );
    await h.cardRepository.createCard(
      deckId: child.id,
      front: CardText.parse('은/는', side: CardSide.front).text!,
      back: CardText.parse('topic marker', side: CardSide.back).text!,
    );

    await expectEveryInvariantClean('after working inside a seeded database');
  });
}
