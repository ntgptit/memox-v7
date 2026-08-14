import 'package:drift/drift.dart' show Variable;
import 'package:memox/core/database/app_database.dart';

import '../../../deck/data/support/deck_repository_harness.dart';

/// Seeds `study_sessions` and `study_answers` rows directly.
///
/// **Raw inserts, not the study repository.** The card history read is a read of
/// stored columns (BR-185), and every one of them has to be settable
/// independently — a `learning` turn with no schedule change, a `recall` turn
/// that timed out, a row written under a scheduler the deck has since left.
/// Driving the real session machinery to produce those would make each test
/// depend on the review flow's rules as well as on its own, and several of the
/// combinations it would have to reach are unreachable through a live session
/// at all.
///
/// The mirror image of the risk: a fixture that can write rows production never
/// writes. That is bounded here by the table's own `CHECK` constraints, which
/// these inserts go through exactly as production does.
final class CardHistoryFixture {
  CardHistoryFixture(this._harness);

  final DeckRepositoryHarness _harness;

  AppDatabase get _db => _harness.db;

  int _sessions = 0;

  /// One session to hang answers off. Sessions are a foreign key of
  /// `study_answers` and nothing about the history read looks at them, so a
  /// test names one and moves on.
  Future<String> seedSession({
    required String deckId,
    required String rootDeckId,
    int schedulerGeneration = 1,
  }) async {
    final id = 'session-${++_sessions}';
    await _db.customInsert(
      'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
      'scheduler_generation, status, session_kind, current_mode, cursor, '
      'card_limit, started_at) '
      "VALUES (?, ?, ?, ?, 'completed', 'reviewing', 'self_assess', 0, 20, ?)",
      variables: <Variable<Object>>[
        Variable<String>(id),
        Variable<String>(deckId),
        Variable<String>(rootDeckId),
        Variable<int>(schedulerGeneration),
        Variable<DateTime>(_harness.currentInstant),
      ],
    );

    return id;
  }

  /// One recorded turn, with every stored column under the caller's control.
  Future<String> seedAnswer({
    required String id,
    required String cardId,
    required String sessionId,
    required DateTime answeredAt,
    String schedulerType = 'eight_box',
    int schedulerGeneration = 1,
    String kind = 'scheduled',
    String mode = 'self_assess',
    String action = 'remembered',
    String? outcomeReason,
    bool? usedHint,
    DateTime? nextDueAt,
    int? previousBox = 1,
    int? nextBox = 2,
    double? previousEaseFactor,
    double? nextEaseFactor,
    int? previousIntervalDays,
    int? nextIntervalDays,
  }) async {
    await _db.customInsert(
      'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
      'scheduler_generation, kind, mode, outcome_reason, used_hint, "action", '
      'answered_at, next_due_at, previous_box, next_box, '
      'previous_ease_factor, next_ease_factor, previous_interval_days, '
      'next_interval_days) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: <Variable<Object>>[
        Variable<String>(id),
        Variable<String>(cardId),
        Variable<String>(sessionId),
        Variable<String>(schedulerType),
        Variable<int>(schedulerGeneration),
        Variable<String>(kind),
        Variable<String>(mode),
        Variable<String>(outcomeReason),
        Variable<int>(usedHint == null ? null : (usedHint ? 1 : 0)),
        Variable<String>(action),
        Variable<DateTime>(answeredAt),
        Variable<DateTime>(nextDueAt),
        Variable<int>(previousBox),
        Variable<int>(nextBox),
        Variable<double>(previousEaseFactor),
        Variable<double>(nextEaseFactor),
        Variable<int>(previousIntervalDays),
        Variable<int>(nextIntervalDays),
      ],
    );

    return id;
  }

  /// [count] turns, one minute apart, newest last — so the read's newest-first
  /// order is the reverse of the order they were written in and a test cannot
  /// pass by accident on insertion order.
  Future<void> seedRun({
    required String cardId,
    required String sessionId,
    required int count,
    String prefix = 'a',
    int schedulerGeneration = 1,
    DateTime? from,
  }) async {
    final start = from ?? _harness.currentInstant;
    for (var index = 0; index < count; index++) {
      await seedAnswer(
        // Zero-padded so the id order matches the numeric order; without it
        // `a-10` sorts before `a-9` and a tie-break assertion would be reading
        // its own fixture rather than the query.
        id: '$prefix-${index.toString().padLeft(4, '0')}',
        cardId: cardId,
        sessionId: sessionId,
        answeredAt: start.add(Duration(minutes: index)),
        schedulerGeneration: schedulerGeneration,
      );
    }
  }
}
