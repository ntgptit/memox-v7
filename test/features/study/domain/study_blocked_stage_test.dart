import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';

/// Which stages can run at all, and which single questions cannot be built.
///
/// **Two different rules that look like one.** `canRunOn` asks about the
/// session's card set and decides whether the stage is laid out at all (BR-99,
/// BR-121, BR-153). `buildQuestion` asks about one card inside a stage that was
/// allowed to run, and its null is BR-124's blocking case — the card is not
/// skipped and no turn is written. Collapsing them is what produced a stage full
/// of rows whose widget rendered nothing.
void main() {
  StudyCardModel card(String id, {String? back}) => StudyCardModel(
    id: id,
    front: 'front-$id',
    back: back ?? 'back-$id',
    example: 'ex-$id',
    hint: null,
    pronunciation: null,
    backFolded: back ?? 'back-$id',
  );

  List<StudyCardModel> cards(int count) => <StudyCardModel>[
    for (var i = 0; i < count; i++) card('c$i'),
  ];

  group('match', () {
    test('cannot run below two pairs (BR-153)', () {
      expect(const MatchModeHandler().canRunOn(cards(1)), isFalse);
      expect(const MatchModeHandler().canRunOn(cards(2)), isTrue);
    });

    test('canTake would have said yes to every one of them', () {
      // The reason the second predicate exists. Two pairs is a property of the
      // set, so a per-card check passes and the stage is laid out anyway.
      expect(const MatchModeHandler().canTake(card('c0')), isTrue);
    });
  });

  group('guess', () {
    test('cannot run below five distinct meanings (BR-121)', () {
      expect(const GuessModeHandler().canRunOn(cards(4)), isFalse);
      expect(const GuessModeHandler().canRunOn(cards(5)), isTrue);
    });

    test('counts distinct meanings, not cards', () {
      // Five cards that all mean the same thing cannot produce five options,
      // and a count of rows would have said they could.
      final sameMeaning = <StudyCardModel>[
        for (var i = 0; i < 5; i++) card('c$i', back: 'one meaning'),
      ];

      expect(const GuessModeHandler().canRunOn(sameMeaning), isFalse);
    });

    test('a stage that can run can still block one question (BR-124)', () {
      // The set clears the bar, so the stage is laid out — and this particular
      // term still cannot be given four wrong options with distinct meanings.
      final pool = <StudyCardModel>[
        card('c0', back: 'alpha'),
        card('c1', back: 'alpha'),
        card('c2', back: 'alpha'),
        card('c3', back: 'beta'),
        card('c4', back: 'gamma'),
        card('c5', back: 'delta'),
        card('c6', back: 'epsilon'),
      ];

      expect(const GuessModeHandler().canRunOn(pool), isTrue);
      expect(
        const GuessModeHandler().buildQuestion(
          term: card('c0', back: 'alpha'),
          pool: <StudyCardModel>[pool[0], pool[1], pool[2]],
          random: Random(1),
        ),
        isNull,
      );
    });
  });

  group('the modes that need nothing built', () {
    for (final mode in <StudyMode>[
      StudyMode.browse,
      StudyMode.selfAssess,
      StudyMode.recall,
      StudyMode.fill,
    ]) {
      test('${mode.dbValue} runs on any set, including one card', () {
        // Defaulting to true is right for every mode without a threshold; only
        // `fill` filters, and it filters per card through `canTake`.
        expect(studyModeHandler(mode)?.canRunOn(cards(1)), isTrue);
      });
    }
  });
}
