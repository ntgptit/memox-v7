import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_detail_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_not_found_failure.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../deck/data/support/deck_repository_harness.dart';
import 'support/card_text_fixture.dart';

/// What the detail read carries, and what it refuses to invent (BR-183,
/// BR-188).
///
/// Real SQLite, because what is in doubt is the SQL: whether the join is total,
/// whether one statement carries the tags, and whether a missing row is
/// distinguishable from a row of nulls. A mocked executor would only prove the
/// code calls the API it was written to call.
void main() {
  final h = installDeckRepositoryHarness();

  CardDetailRepositoryImpl repository() => CardDetailRepositoryImpl(h.db);

  Future<CardEntity> seedCard(
    String deckId, {
    String front = 'front',
    String back = 'back',
    String? example,
    String? hint,
    String? pronunciation,
    List<String> tags = const <String>[],
  }) async {
    final card = await h.cardRepository.createCard(
      deckId: deckId,
      front: cardText(front),
      back: cardText(back, side: CardSide.back),
      example: example == null ? null : cardDetail(example),
      hint: hint == null
          ? null
          : cardDetail(hint, field: CardDetailField.hint),
      pronunciation: pronunciation == null
          ? null
          : cardDetail(pronunciation, field: CardDetailField.pronunciation),
    );
    for (final tag in tags) {
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: TagName.parse(tag).name!,
      );
    }

    return card;
  }

  group('what one read carries (BR-183)', () {
    test('content, both optional fields, tags and the current state arrive '
        'together', () async {
      final tree = await h.seedTree();
      final card = await seedCard(
        tree.leaf.id,
        front: '사과',
        back: 'quả táo',
        example: '사과를 먹어요',
        hint: 'fruit',
        pronunciation: 'sa-gwa',
        tags: <String>['noun', 'food'],
      );

      final detail = await repository().watchCardDetail(card.id).first;

      expect(detail.card.front, '사과');
      expect(detail.card.back, 'quả táo');
      expect(detail.card.example, '사과를 먹어요');
      expect(detail.card.hint, 'fruit');
      expect(detail.card.pronunciation, 'sa-gwa');
      expect(detail.tagNames, containsAll(<String>['noun', 'food']));
      expect(detail.studyState.cardId, card.id);
      expect(detail.studyState.schedulerType, SchedulerType.eightBox);
      // A card born with its state (BR-09) has not finished the chain, so it is
      // new and carries no schedule (BR-90, BR-149).
      expect(detail.state, CardState.isNew);
      expect(detail.studyState.learnedAt, isNull);
      expect(detail.studyState.dueAt, isNull);
    });

    test('a card with no optional field and no tag reads as absent, not as '
        'empty strings (BR-95)', () async {
      final tree = await h.seedTree();
      final card = await seedCard(tree.leaf.id);

      final detail = await repository().watchCardDetail(card.id).first;

      expect(detail.card.example, isNull);
      expect(detail.card.hint, isNull);
      expect(detail.card.pronunciation, isNull);
      expect(detail.tagNames, isEmpty);
    });

    test('the tags cost no statement per tag', () async {
      final tree = await h.seedTree();
      final card = await seedCard(
        tree.leaf.id,
        tags: <String>['a', 'b', 'c', 'd', 'e'],
      );
      h.clearStatements();

      await repository().watchCardDetail(card.id).first;

      // One read for the whole row, tags included. The claim is invisible to
      // any assertion on the result — a repository issuing one query per tag
      // returns the same model — so it is made about the statements.
      expect(h.countStatements('FROM cards AS c'), 1);
      expect(h.countStatements('FROM card_tags AS ct'), 1);
    });

    test('adding a tag re-emits', () async {
      final tree = await h.seedTree();
      final card = await seedCard(tree.leaf.id);
      final emissions = <CardDetailModel>[];
      final subscription = repository()
          .watchCardDetail(card.id)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: TagName.parse('noun').name!,
      );
      await pumpEventQueue();

      // The tag tables *are* in this statement's generated `readsFrom` — see
      // `card.drift`, which records that `cardListItems`'s hand-merged
      // `tableUpdates` workaround is not needed here. What is pinned is the
      // behaviour, not the mechanism: if drift ever changes its mind, this is
      // the test that says so rather than a screen showing chips that are gone.
      expect(emissions.last.tagNames, <String>['noun']);
      await subscription.cancel();
    });
  });

  group('a card that is not there (BR-188)', () {
    test('an id that never existed is a typed not-found, not an empty '
        'result', () async {
      await expectLater(
        repository().watchCardDetail('no-such-card').first,
        throwsA(
          isA<NotFoundFailure>().having(
            (NotFoundFailure failure) => failure.reason,
            'reason',
            CardNotFoundReason.cardGone,
          ),
        ),
      );
    });

    test('a card deleted while the screen watches it turns into the same '
        'typed not-found', () async {
      final tree = await h.seedTree();
      final card = await seedCard(tree.leaf.id);
      final errors = <Object>[];
      final subscription = repository()
          .watchCardDetail(card.id)
          .listen((_) {}, onError: errors.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await h.cardRepository.deleteCard(card.id);
      await pumpEventQueue();

      expect(errors, isNotEmpty);
      expect(
        errors.last,
        isA<NotFoundFailure>().having(
          (NotFoundFailure failure) => failure.reason,
          'reason',
          CardNotFoundReason.cardGone,
        ),
      );
      await subscription.cancel();
    });

    test('the message names no id, path or SQL (BR-53)', () async {
      Object? captured;
      try {
        await repository().watchCardDetail('secret-card-id').first;
      } on Failure catch (failure) {
        captured = failure;
      }

      expect(captured, isA<NotFoundFailure>());
      expect((captured! as Failure).message, isNot(contains('secret-card-id')));
      expect((captured as Failure).message, isNot(contains('SELECT')));
    });
  });
}
