import 'dart:math';

import 'package:drift/drift.dart' hide isNull;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import '../../../../database/support/test_database.dart';

/// A real SQLite database, a real repository, and the two seeds every Study test
/// needs.
///
/// **A real database, not a fake repository.** Everything these tests are about
/// — the comeback gap, the failed set, the two columns that must move together —
/// is a property of what ends up in the tables. A fake would only assert that
/// the code calls the methods the code calls.
final class StudyHarness {
  StudyHarness() : db = openTestDatabase() {
    repository = StudyRepositoryImpl(
      StudyDao(db),
      idGenerator: () => 'id-${_idCounter++}',
      // A fixed seed: the shuffle has to be real (BR-117) and reproducible.
      random: Random(7),
    );
  }

  /// The instant every test reads the world at.
  static final DateTime now = DateTime.utc(2026, 8, 7, 9);

  final AppDatabase db;
  late final StudyRepositoryImpl repository;
  int _idCounter = 0;

  Future<void> close() => db.close();

  Future<List<QueryRow>> rows(String sql) => db.customSelect(sql).get();

  /// A root deck with [cardCount] cards, none of them learned yet.
  Future<List<String>> seedDeck({
    required int cardCount,
    String schedulerType = 'eight_box',
    bool withExample = false,
  }) async {
    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('d1', 'Korean', 'd1', 'card', '$schedulerType', 1, 1, 0, 0)",
    );

    final ids = <String>[];
    for (var i = 0; i < cardCount; i++) {
      final id = 'c$i';
      ids.add(id);
      await db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, example, created_at, updated_at) '
        "VALUES ('$id', 'd1', 'front$i', 'back$i', 'front$i', 'back$i', "
        "${withExample ? "'example$i'" : 'NULL'}, $i, $i)",
      );
      await db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        'current_box) '
        "VALUES ('$id', '$schedulerType', 1, 1, 0, 0, 1)",
      );
    }

    return ids;
  }

  /// Marks a card learned and due — what moves it into the review set.
  ///
  /// Both columns, always: a card with one and not the other is exactly what
  /// invariants 24 and 28 exist to catch (BR-149).
  Future<void> makeDue(
    String cardId, {
    Duration ago = const Duration(days: 1),
  }) => db.customStatement(
    'UPDATE card_study_states SET learned_at = ?, due_at = ? WHERE card_id = ?',
    <Object?>[
      now.subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
      now.subtract(ago).millisecondsSinceEpoch ~/ 1000,
      cardId,
    ],
  );

  /// Opens a review session of [cardCount] due cards, running one [mode].
  ///
  /// [schedulerType] and [direction] exist for BR-203: the feature is reachable
  /// only from an `sm2` deck, so a test of it has to be able to seed one — and a
  /// test of its *unreachability* has to be able to seed the other.
  Future<String> openReview({
    required int cardCount,
    StudyMode mode = StudyMode.selfAssess,
    String schedulerType = 'eight_box',
    StudySessionDirection? direction,
  }) async {
    final ids = await seedDeck(
      cardCount: cardCount,
      schedulerType: schedulerType,
    );
    for (final id in ids) {
      await makeDue(id);
    }

    final session = await repository.openSession(
      deckId: 'd1',
      kind: StudySessionKind.reviewing,
      stageSequence: <StudyMode>[mode],
      cardLimit: 20,
      newCardOrder: NewCardOrder.created,
      now: now,
      direction: direction,
    );

    return session.id;
  }
}
