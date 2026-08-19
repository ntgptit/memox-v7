import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';

import 'support/fake_study_home_repository.dart';

/// The ranking and the three loaded states, as pure Dart (BR-201, BR-202).
///
/// **Here as well as against SQLite, and the split is deliberate.** The database
/// test proves the counts are the right counts; this proves what is done with
/// them. Ordering is a rule — which deck the app puts in front of somebody first
/// — so it belongs where a rule can be stated as one comparison at a time, and a
/// comparator is the smallest thing that can hold it.
void main() {
  List<String> order(List<StudyHomeDeckModel> decks) =>
      (decks.toList()..sort(compareStudyHomeDecks))
          .map((deck) => deck.deckId)
          .toList();

  group('compareStudyHomeDecks', () {
    test('overdue is the first key, whatever the other two say', () {
      expect(
        order(<StudyHomeDeckModel>[
          fakeStudyHomeDeck(
            deckId: 'loud',
            deckName: 'B',
            dueTodayCount: 99,
            newCount: 99,
          ),
          fakeStudyHomeDeck(deckId: 'late', deckName: 'A', overdueCount: 1),
        ]),
        <String>['late', 'loud'],
      );
    });

    test('due today is the second key', () {
      expect(
        order(<StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'new', deckName: 'A', newCount: 40),
          fakeStudyHomeDeck(deckId: 'today', deckName: 'B', dueTodayCount: 1),
        ]),
        <String>['today', 'new'],
      );
    });

    test('new is the third key', () {
      expect(
        order(<StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'few', deckName: 'A', newCount: 1),
          fakeStudyHomeDeck(deckId: 'many', deckName: 'B', newCount: 2),
        ]),
        <String>['many', 'few'],
      );
    });

    test('an equal workload breaks on the case-folded name', () {
      // Case is folded, so `apple` and `Apple` are one name and the id decides
      // — not the byte order that would put every capital first.
      expect(
        order(<StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'b', deckName: 'banana', newCount: 3),
          fakeStudyHomeDeck(deckId: 'a', deckName: 'Apple', newCount: 3),
        ]),
        <String>['a', 'b'],
      );
    });

    test('the fold is Unicode-aware, which is the whole reason it is in Dart', () {
      // SQLite's `lower()` folds ASCII only: it leaves `Đ` at its uppercase byte,
      // which sorts before every lowercase letter. Dart's `toLowerCase()` does
      // not, so `đà nẵng` lands after `banana` where a reader expects it.
      expect(
        order(<StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'vn', deckName: 'Đà Nẵng', newCount: 3),
          fakeStudyHomeDeck(deckId: 'b', deckName: 'banana', newCount: 3),
        ]),
        <String>['b', 'vn'],
      );
    });

    test('identical names fall through to the id, so the order is stable', () {
      expect(
        order(<StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'z', deckName: 'same'),
          fakeStudyHomeDeck(deckId: 'a', deckName: 'same'),
        ]),
        <String>['a', 'z'],
      );
    });

    test('an empty workload sinks without a branch for it', () {
      expect(
        order(<StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'quiet', deckName: 'A'),
          fakeStudyHomeDeck(deckId: 'busy', deckName: 'Z', newCount: 1),
        ]),
        <String>['busy', 'quiet'],
      );
    });
  });

  group('StudyHomeDeckModel', () {
    test('dueCount is the two halves, never a fourth stored number', () {
      final deck = fakeStudyHomeDeck(
        deckId: 'd',
        deckName: 'd',
        overdueCount: 2,
        dueTodayCount: 3,
      );

      expect(deck.dueCount, 5);
      expect(deck.hasWorkload, isTrue);
    });

    test('a deck with cards and no workload is still studiable', () {
      // BR-29: nothing due is the schedule working, not a locked door. The row
      // keeps its action and the entry screen gives the honest answer.
      final deck = fakeStudyHomeDeck(
        deckId: 'd',
        deckName: 'd',
        totalCardCount: 40,
      );

      expect(deck.hasWorkload, isFalse);
      expect(deck.isStudiable, isTrue);
    });

    test('a deck with no cards is not studiable', () {
      final deck = fakeStudyHomeDeck(
        deckId: 'd',
        deckName: 'd',
        totalCardCount: 0,
      );

      expect(deck.isStudiable, isFalse);
    });
  });

  group('StudyHomeModel', () {
    test('no decks is the empty library, and it is not the no-cards state', () {
      final home = fakeStudyHome(decks: const <StudyHomeDeckModel>[]);

      expect(home.isLibraryEmpty, isTrue);
      expect(home.hasNoCards, isFalse);
      expect(home.studiableDecks, isEmpty);
    });

    test('decks with no cards anywhere is its own state', () {
      final home = fakeStudyHome(
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'a', deckName: 'A', totalCardCount: 0),
          fakeStudyHomeDeck(deckId: 'b', deckName: 'B', totalCardCount: 0),
        ],
      );

      expect(home.isLibraryEmpty, isFalse);
      expect(home.hasNoCards, isTrue);
    });

    test('one deck with cards is enough to leave the no-cards state', () {
      final home = fakeStudyHome(
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(deckId: 'a', deckName: 'A', totalCardCount: 0),
          fakeStudyHomeDeck(deckId: 'b', deckName: 'B', totalCardCount: 4),
        ],
      );

      expect(home.hasNoCards, isFalse);
      // And the empty one drops out of the list rather than offering an action
      // with nothing behind it.
      expect(home.studiableDecks.map((deck) => deck.deckId), <String>['b']);
    });
  });
}
