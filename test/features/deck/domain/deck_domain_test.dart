import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/entities/card_review_state_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// Domain-layer tests for M4.9: entity equality, validation boundaries and
/// the unknown-enum policy (read tolerantly, never write back).
void main() {
  final createdAt = DateTime.utc(2026, 7, 29, 12);

  DeckEntity buildDeck({String id = 'deck-1', String name = 'Deck'}) =>
      DeckEntity(
        id: id,
        name: name,
        parentDeckId: null,
        rootDeckId: id,
        contentType: DeckContentType.deck,
        schedulerType: SchedulerType.eightBox,
        schedulerGeneration: 1,
        firstReviewAt: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

  group('value equality and immutability', () {
    test('two identically-built decks are equal', () {
      expect(buildDeck(), buildDeck());
      expect(buildDeck().hashCode, buildDeck().hashCode);
    });

    test('a changed field breaks equality; the original is untouched', () {
      final deck = buildDeck();
      final renamed = deck.copyWith(name: 'Other');

      expect(renamed, isNot(equals(deck)));
      // copyWith returned a new object — the entity itself cannot mutate.
      expect(deck.name, 'Deck');
    });

    test('cards and review states carry value equality too', () {
      CardEntity buildCard() => CardEntity(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'f',
        back: 'b',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      CardReviewStateEntity buildState() => const CardReviewStateEntity(
        cardId: 'card-1',
        schedulerType: SchedulerType.sm2,
        schedulerVersion: 1,
        schedulerGeneration: 1,
        dueAt: null,
        lastReviewedAt: null,
        reviewCount: 0,
        lapseCount: 0,
        currentBox: null,
        easeFactor: 2.5,
        intervalDays: 0,
        repetitions: 0,
      );

      expect(buildCard(), buildCard());
      expect(buildState(), buildState());
      expect(
        const DeckDeletionImpact(descendantDeckCount: 2, cardCount: 5),
        const DeckDeletionImpact(descendantDeckCount: 2, cardCount: 5),
      );
    });

    test('isRoot reads from parentDeckId', () {
      expect(buildDeck().isRoot, isTrue);
      expect(buildDeck().copyWith(parentDeckId: 'parent').isRoot, isFalse);
    });
  });

  // Deck name validation (BR-01) lives in `deck_name_test.dart` now, with the
  // `DeckName` value object that owns the rule. It used to be tested here because
  // the rule was on the entity — and being on the entity is what let three layers
  // each call it for one submit.

  group('card content validation (BR-07, BR-08)', () {
    test('an empty front is refused, with a typed problem for that side', () {
      expect(
        () => CardEntity.validateSide('', side: CardSide.front),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            <Enum>{CardValidationProblem.frontEmpty},
          ),
        ),
      );
    });

    test('a whitespace-only back is refused, keyed to its own side', () {
      expect(
        () => CardEntity.validateSide(' \n ', side: CardSide.back),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            <Enum>{CardValidationProblem.backEmpty},
          ),
        ),
      );
    });

    test('exactly the limit passes, and is returned trimmed', () {
      final text = 'x' * CardEntity.maxSideLength;

      expect(CardEntity.validateSide(' $text ', side: CardSide.front), text);
    });

    test('one over the limit is refused, never truncated', () {
      final text = 'x' * (CardEntity.maxSideLength + 1);

      expect(
        () => CardEntity.validateSide(text, side: CardSide.back),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            <Enum>{CardValidationProblem.backTooLong},
          ),
        ),
      );
    });
  });

  group('enum round-trips', () {
    test('every real value maps both ways', () {
      expect(SchedulerType.fromDbValue('eight_box'), SchedulerType.eightBox);
      expect(SchedulerType.fromDbValue('sm2'), SchedulerType.sm2);
      expect(SchedulerType.eightBox.dbValue, 'eight_box');
      expect(SchedulerType.sm2.dbValue, 'sm2');

      expect(DeckContentType.fromDbValue('unset'), DeckContentType.unset);
      expect(DeckContentType.fromDbValue('card'), DeckContentType.card);
      expect(DeckContentType.fromDbValue('deck'), DeckContentType.deck);
      expect(DeckContentType.unset.dbValue, 'unset');
      expect(DeckContentType.card.dbValue, 'card');
      expect(DeckContentType.deck.dbValue, 'deck');
    });

    test('a database value this build has never seen maps to unknown', () {
      expect(SchedulerType.fromDbValue('sm18'), SchedulerType.unknown);
      expect(SchedulerType.fromDbValue(''), SchedulerType.unknown);
      expect(DeckContentType.fromDbValue('mixed'), DeckContentType.unknown);
    });

    test('unknown can never be written back — dbValue fails fast', () {
      expect(() => SchedulerType.unknown.dbValue, throwsStateError);
      expect(() => DeckContentType.unknown.dbValue, throwsStateError);
    });

    test(
      'the literal string unknown is not a storable value of either enum',
      () {
        // Reading 'unknown' from the database must not resolve to a real
        // variant, or a fail-fast write of it would quietly succeed.
        expect(SchedulerType.fromDbValue('unknown'), SchedulerType.unknown);
        expect(DeckContentType.fromDbValue('unknown'), DeckContentType.unknown);
      },
    );
  });

  test('domain stays pure Dart — no Flutter, Drift or generated import', () {
    final domainDir = Directory('lib/features/deck/domain');
    final sources = domainDir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => !f.path.endsWith('.freezed.dart'));

    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final forbidden in <String>[
        'package:flutter/',
        'package:drift/',
        'package:dio/',
        'package:json_annotation/',
        'core/database/',
      ]) {
        expect(
          source,
          isNot(contains(forbidden)),
          reason: '${file.path} imports $forbidden',
        );
      }
    }
  });
}
