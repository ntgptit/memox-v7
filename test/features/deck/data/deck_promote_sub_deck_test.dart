import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_conflict_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';

import '../../card/data/support/card_text_fixture.dart';
import 'support/deck_repository_harness.dart';

/// Promotion invariants on real SQLite. The operation is intentionally not a
/// move: it produces a scheduler-owning root and resets just that new tree.
void main() {
  final h = installDeckRepositoryHarness();

  Future<({String rootId, String branchId, String leafId, String cardId})>
  seededBranch() async {
    final root = await h.deckRepository.createRootDeck(
      name: DeckName.parse('English').name!,
      schedulerType: SchedulerType.eightBox,
    );
    final branch = await h.deckRepository.createSubDeck(
      name: DeckName.parse('IELTS').name!,
      parentDeckId: root.id,
    );
    final leaf = await h.deckRepository.createSubDeck(
      name: DeckName.parse('Vocabulary').name!,
      parentDeckId: branch.id,
    );
    final card = await h.cardRepository.createCard(
      deckId: leaf.id,
      front: cardText('front'),
      back: cardText('back', side: CardSide.back),
    );

    return (
      rootId: root.id,
      branchId: branch.id,
      leafId: leaf.id,
      cardId: card.id,
    );
  }

  test('promotes a subtree onto the chosen scheduler and keeps its history', () async {
    final tree = await seededBranch();
    await h.db.customStatement(
      "UPDATE card_study_states SET learned_at = 10, due_at = 20, current_box = 4, answer_count = 3 WHERE card_id = '${tree.cardId}'",
    );
    await h.db.customStatement(
      "INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, status, end_reason, session_kind, current_mode, cursor, card_limit, started_at) VALUES ('session-1', '${tree.rootId}', '${tree.rootId}', 1, 'in_progress', NULL, 'learning', 'self_assess', 0, 20, 1)",
    );
    await h.db.customStatement(
      "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status) VALUES ('session-1', 'self_assess', 1, '${tree.cardId}', 0, 'pending')",
    );
    await h.db.customStatement(
      "INSERT INTO study_answers (id, card_id, session_id, scheduler_type, scheduler_generation, kind, mode, \"action\", answered_at) VALUES ('answer-1', '${tree.cardId}', 'session-1', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 2)",
    );

    await h.deckRepository.promoteSubDeckToRoot(
      deckId: tree.branchId,
      schedulerType: SchedulerType.sm2,
    );

    final branch = (await h.rawDeck(tree.branchId))!;
    final leaf = (await h.rawDeck(tree.leafId))!;
    final formerRoot = (await h.rawDeck(tree.rootId))!;
    final state = (await h.rawStates(tree.cardId)).single;
    expect(branch.readNullable<String>('parent_deck_id'), isNull);
    expect(branch.read<String>('root_deck_id'), tree.branchId);
    expect(branch.read<String>('scheduler_type'), 'sm2');
    expect(branch.read<int>('scheduler_generation'), 1);
    expect(branch.readNullable<int>('first_answered_at'), isNull);
    expect(leaf.read<String>('root_deck_id'), tree.branchId);
    expect(formerRoot.read<String>('content_type'), 'deck');
    expect(state.read<String>('scheduler_type'), 'sm2');
    expect(state.read<int>('scheduler_generation'), 1);
    expect(state.readNullable<int>('learned_at'), isNull);
    expect(state.readNullable<int>('due_at'), isNull);
    expect(await h.countAll('study_answers'), 1);

    final session = await h.db
        .customSelect(
          "SELECT status, end_reason FROM study_sessions WHERE id = 'session-1'",
        )
        .getSingle();
    expect(
      session.read<String>('status'),
      StudySessionStatus.invalidated.dbValue,
    );
    expect(session.read<String>('end_reason'), 'subtree_promoted');
  });

  test(
    'refuses roots and a branch with direct cards without changing data',
    () async {
      final tree = await seededBranch();
      await expectLater(
        h.deckRepository.promoteSubDeckToRoot(
          deckId: tree.rootId,
          schedulerType: SchedulerType.sm2,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            DeckConflictReason.promotionNeedsSubDeck,
          ),
        ),
      );
      final direct = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Direct').name!,
        parentDeckId: tree.rootId,
      );
      await h.cardRepository.createCard(
        deckId: direct.id,
        front: cardText('direct'),
        back: cardText('direct-back', side: CardSide.back),
      );
      await expectLater(
        h.deckRepository.promoteSubDeckToRoot(
          deckId: direct.id,
          schedulerType: SchedulerType.sm2,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            DeckConflictReason.promotionDeckHasCards,
          ),
        ),
      );
      expect(
        (await h.rawDeck(direct.id))!.read<String>('root_deck_id'),
        tree.rootId,
      );
    },
  );

  test('rolls every promotion write back on a database failure', () async {
    final tree = await seededBranch();
    await h.db.customStatement(
      "CREATE TRIGGER fail_promotion BEFORE UPDATE ON card_study_states BEGIN SELECT RAISE(ABORT, 'injected promotion failure'); END",
    );

    await expectLater(
      h.deckRepository.promoteSubDeckToRoot(
        deckId: tree.branchId,
        schedulerType: SchedulerType.sm2,
      ),
      throwsA(isA<Failure>()),
    );
    final branch = (await h.rawDeck(tree.branchId))!;
    final leaf = (await h.rawDeck(tree.leafId))!;
    expect(branch.read<String>('root_deck_id'), tree.rootId);
    expect(branch.read<String>('parent_deck_id'), tree.rootId);
    expect(leaf.read<String>('root_deck_id'), tree.rootId);
  });
}
