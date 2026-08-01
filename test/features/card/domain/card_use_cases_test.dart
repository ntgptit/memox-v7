import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/create_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/delete_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/update_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_cards_by_deck_use_case.dart';

/// The card use cases: what they refuse, and what they never reach.
///
/// **The assertion that matters most here is a negative one.** Validation used
/// to run inside the repository's write transaction, so "an invalid card does
/// not change the row" could only be checked by writing and then looking. Now
/// the rule runs above the contract, and the stronger statement is available:
/// the repository is not called at all. A counting fake is what makes that
/// visible — an `expect` on the row could not tell "refused before the write"
/// apart from "written and rolled back".
void main() {
  late _CountingCardRepository repository;

  setUp(() => repository = _CountingCardRepository());

  group('creating', () {
    test('a valid card reaches the repository once, already trimmed', () async {
      await CreateCardUseCase(
        repository,
      ).call(deckId: 'deck-1', rawFront: '  front  ', rawBack: ' back ');

      expect(repository.createCalls, 1);
      expect(repository.lastFront?.value, 'front');
      expect(repository.lastBack?.value, 'back');
    });

    test('an invalid card never reaches the repository', () async {
      await expectLater(
        CreateCardUseCase(
          repository,
        ).call(deckId: 'deck-1', rawFront: '', rawBack: 'back'),
        throwsA(isA<ValidationFailure>()),
      );

      expect(
        repository.createCalls,
        0,
        reason:
            'the write must be refused above the repository, not attempted '
            'and rolled back',
      );
    });

    test('a refusal arrives through the future, not before it', () async {
      // The regression this pins: `parseCardSides` throws synchronously, so a
      // `call` that is not `async` throws *while being called* — before the
      // future it promises exists. Every other failure from this layer arrives
      // through the future, and `catchError` is the idiom that tells them
      // apart: it can only see what the future carries. A caller that used it
      // would crash on an invalid card and catch a database error, which is a
      // bug nobody finds by reading either side.
      Object? caught;
      await CreateCardUseCase(repository)
          .call(deckId: 'deck-1', rawFront: '', rawBack: '')
          .catchError((Object error) {
            caught = error;

            return _unreachableCard();
          });

      expect(caught, isA<ValidationFailure>());
    });

    test('both sides wrong are reported together', () async {
      await expectLater(
        CreateCardUseCase(
          repository,
        ).call(deckId: 'deck-1', rawFront: '  ', rawBack: ''),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            <Enum>{
              CardValidationProblem.frontEmpty,
              CardValidationProblem.backEmpty,
            },
          ),
        ),
      );
    });
  });

  group('updating', () {
    test('a valid edit reaches the repository once', () async {
      await UpdateCardUseCase(
        repository,
      ).call(cardId: 'card-1', rawFront: 'f', rawBack: 'b');

      expect(repository.updateCalls, 1);
    });

    test('an invalid edit never reaches the repository', () async {
      await expectLater(
        UpdateCardUseCase(
          repository,
        ).call(cardId: 'card-1', rawFront: 'f', rawBack: '   '),
        throwsA(isA<ValidationFailure>()),
      );

      expect(repository.updateCalls, 0);
    });

    test('creating and editing refuse on exactly the same input', () async {
      // A rule applied differently by the two paths is a card that can be
      // saved in a state it could not be created in. Both go through
      // `parseCardSides`, and this is what says so.
      const cases = <(String, String)>[('', 'b'), ('f', ''), ('   ', '   ')];

      for (final (String rawFront, String rawBack) in cases) {
        await expectLater(
          CreateCardUseCase(
            repository,
          ).call(deckId: 'd', rawFront: rawFront, rawBack: rawBack),
          throwsA(isA<ValidationFailure>()),
          reason: 'create accepted ("$rawFront", "$rawBack")',
        );
        await expectLater(
          UpdateCardUseCase(
            repository,
          ).call(cardId: 'c', rawFront: rawFront, rawBack: rawBack),
          throwsA(isA<ValidationFailure>()),
          reason: 'update accepted ("$rawFront", "$rawBack")',
        );
      }
    });
  });

  group('the pass-through use cases', () {
    test('delete forwards the id and validates nothing', () async {
      await DeleteCardUseCase(repository).call('card-1');

      expect(repository.deleteCalls, <String>['card-1']);
    });

    test('watch forwards the deck id', () async {
      WatchCardsByDeckUseCase(repository).call('deck-1');

      expect(repository.watchCalls, <String>['deck-1']);
    });
  });
}

/// `catchError` must return the future's type; this value is never read,
/// because the test asserts on what was caught rather than on what came back.
CardEntity _unreachableCard() => CardEntity(
  id: 'never-read',
  deckId: 'never-read',
  front: '',
  back: '',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Counts what it was asked to do. Nothing else — these tests are about
/// whether the repository is reached, not about what it would return.
final class _CountingCardRepository implements CardRepository {
  int createCalls = 0;
  int updateCalls = 0;
  final List<String> deleteCalls = <String>[];
  final List<String> watchCalls = <String>[];
  CardText? lastFront;
  CardText? lastBack;

  CardEntity _card() => CardEntity(
    id: 'card-1',
    deckId: 'deck-1',
    front: lastFront?.value ?? '',
    back: lastBack?.value ?? '',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
  }) async {
    createCalls += 1;
    lastFront = front;
    lastBack = back;

    return _card();
  }

  @override
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
  }) async {
    updateCalls += 1;
    lastFront = front;
    lastBack = back;

    return _card();
  }

  @override
  Future<void> deleteCard(String cardId) async => deleteCalls.add(cardId);

  @override
  Stream<List<CardEntity>> watchCardsByDeck(String deckId) {
    watchCalls.add(deckId);

    return const Stream<List<CardEntity>>.empty();
  }
}
