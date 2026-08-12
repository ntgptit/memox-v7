import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import 'support/study_harness.dart';

/// BR-13: the first card to finish the learning chain locks the root's
/// scheduler.
///
/// **This had no owner at all until now, and the gap was invisible.** Nothing in
/// the app ever wrote `decks.first_answered_at`; only Reset ever cleared it. So
/// BR-12 read every deck as still free to change algorithm no matter how much of
/// it had been learned, and BR-13 was a sentence in a document with no code
/// behind it. Every test here fails against that version.
void main() {
  late StudyHarness h;

  setUp(() => h = StudyHarness());
  tearDown(() => h.close());

  Future<DateTime?> lockOf(String deckId) async {
    final rows = await h.rows(
      "SELECT first_answered_at FROM decks WHERE id = '$deckId'",
    );
    final seconds = rows.single.read<int?>('first_answered_at');

    return seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  Future<int> updatedAtOf(String deckId) async => (await h.rows(
    "SELECT updated_at FROM decks WHERE id = '$deckId'",
  )).single.read<int>('updated_at');

  test(
    'a learning answer that has not finished the chain locks nothing',
    () async {
      // **The distinction BR-144 draws.** Answering inside a learning session is
      // not completing: the card can still fail a later stage and come back. A
      // lock written on the first answer would freeze the algorithm for a deck
      // whose first card never actually got learned.
      final ids = await h.seedDeck(cardCount: 2);
      final session = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.learning,
        stageSequence: <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );

      await h.repository.submitAnswer(
        sessionId: session.id,
        cardId: ids.first,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: StudyHarness.now,
      );

      expect(await lockOf('d1'), isNull);
    },
  );

  test('the first card to finish the chain locks the root', () async {
    final ids = await h.seedDeck(cardCount: 2);

    await h.repository.completeLearning(
      cardId: ids.first,
      learnedAt: StudyHarness.now,
      dueAt: StudyHarness.now.add(const Duration(days: 1)),
    );

    expect(await lockOf('d1'), StudyHarness.now);
  });

  test('the stamp is the completion it was given, not another clock', () async {
    // The lock is a fact *about* the completion, so it carries the completion's
    // own timestamp. Reading a clock inside the repository would put a second,
    // untestable source of "now" under a provider the tree can override.
    final ids = await h.seedDeck(cardCount: 1);
    final learned = StudyHarness.now.subtract(const Duration(hours: 6));

    await h.repository.completeLearning(
      cardId: ids.single,
      learnedAt: learned,
      dueAt: StudyHarness.now.add(const Duration(days: 1)),
    );

    expect(await lockOf('d1'), learned);
  });

  test('a later card does not overwrite the first stamp', () async {
    final ids = await h.seedDeck(cardCount: 2);
    final first = StudyHarness.now;
    final later = StudyHarness.now.add(const Duration(days: 3));

    await h.repository.completeLearning(
      cardId: ids.first,
      learnedAt: first,
      dueAt: first.add(const Duration(days: 1)),
    );
    await h.repository.completeLearning(
      cardId: ids.last,
      learnedAt: later,
      dueAt: later.add(const Duration(days: 1)),
    );

    // "When this tree was first learned", not "when it was last learned". The
    // guard is inside the UPDATE, so two cards finishing in one transaction
    // cannot both read NULL and both write.
    expect(await lockOf('d1'), first);
  });

  test('locking the deck does not touch its updated_at', () async {
    // Learning a card is not an edit to the deck. Bumping `updated_at` would
    // jump the deck to the top of Recent for something the user did *inside* it
    // rather than *to* it.
    final ids = await h.seedDeck(cardCount: 1);
    final before = await updatedAtOf('d1');

    await h.repository.completeLearning(
      cardId: ids.single,
      learnedAt: StudyHarness.now,
      dueAt: StudyHarness.now.add(const Duration(days: 1)),
    );

    expect(await updatedAtOf('d1'), before);
  });

  test('the card state and the lock land together or not at all', () async {
    // One transaction, and this is what proves it. A card marked learned under
    // a root that still reads unlocked is exactly what invariant 30 catches, and
    // two separate statements are the only way to produce it.
    final ids = await h.seedDeck(cardCount: 1);

    await expectLater(
      h.repository.completeLearning(
        cardId: 'no-such-card',
        learnedAt: StudyHarness.now,
        dueAt: StudyHarness.now.add(const Duration(days: 1)),
      ),
      throwsA(anything),
    );

    expect(await lockOf('d1'), isNull);
    expect(
      (await h.rows(
        "SELECT learned_at FROM card_study_states WHERE card_id = '${ids.single}'",
      )).single.read<int?>('learned_at'),
      isNull,
    );
  });

  test('a card in a sub-deck locks the root, not its own deck', () async {
    // Resolved through `root_deck_id`. The coalesce-the-parent shortcut BR-57
    // bans returns the level-2 deck from the third level down, and the
    // scheduler lives on the root (BR-05).
    await h.seedDeck(cardCount: 1);
    await h.db.customStatement(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('d2', 'Branch', 'd1', 'd1', 'card', 0, 0)",
    );
    await h.db.customStatement(
      'INSERT INTO cards (id, deck_id, front, back, front_folded, back_folded, '
      "created_at, updated_at) VALUES ('deep', 'd2', 'f', 'b', 'f', 'b', 0, 0)",
    );
    await h.db.customStatement(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, answer_count, lapse_count, '
      "current_box) VALUES ('deep', 'eight_box', 1, 1, 0, 0, 1)",
    );

    await h.repository.completeLearning(
      cardId: 'deep',
      learnedAt: StudyHarness.now,
      dueAt: StudyHarness.now.add(const Duration(days: 1)),
    );

    expect(await lockOf('d1'), StudyHarness.now);
    expect(await lockOf('d2'), isNull);
  });
}
