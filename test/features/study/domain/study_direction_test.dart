import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

/// The recall direction, as pure rules (BR-203…BR-206).
///
/// Everything here is input/output: no database, no widget. What the database
/// has to prove — that an assignment survives a retry and a restart — is in
/// `test/features/study/data/study_direction_flow_test.dart`, because it is a
/// property of what ends up in the tables rather than of this arithmetic.
void main() {
  group('eligibility (BR-203)', () {
    test('the one combination that is eligible', () {
      expect(
        isReverseDirectionEligible(
          kind: StudySessionKind.reviewing,
          schedulerType: SchedulerType.sm2,
          mode: StudyMode.selfAssess,
        ),
        isTrue,
      );
    });

    test('no eight_box mode is eligible, in either kind', () {
      // **The negative half, and it is the half that matters.** `eight_box`
      // never runs `self_assess` in a review (BR-110), so the interesting claim
      // is not "self_assess is off for it" but that *nothing* it does turns the
      // feature on. Enumerated rather than sampled: a mode added later is
      // covered by this loop the day it exists.
      for (final kind in StudySessionKind.values) {
        for (final mode in StudyMode.values) {
          expect(
            isReverseDirectionEligible(
              kind: kind,
              schedulerType: SchedulerType.eightBox,
              mode: mode,
            ),
            isFalse,
            reason: 'eight_box $kind/$mode must not reach the direction',
          );
        }
      }
    });

    test('an unknown algorithm is never eligible', () {
      for (final mode in StudyMode.values) {
        expect(
          isReverseDirectionEligible(
            kind: StudySessionKind.reviewing,
            schedulerType: SchedulerType.unknown,
            mode: mode,
          ),
          isFalse,
        );
      }
    });

    test('sm2 is eligible in exactly one mode, and only when reviewing', () {
      for (final mode in StudyMode.values) {
        expect(
          isReverseDirectionEligible(
            kind: StudySessionKind.learning,
            schedulerType: SchedulerType.sm2,
            mode: mode,
          ),
          isFalse,
          reason: 'a learning chain does not choose its stages (BR-109)',
        );

        expect(
          isReverseDirectionEligible(
            kind: StudySessionKind.reviewing,
            schedulerType: SchedulerType.sm2,
            mode: mode,
          ),
          mode == StudyMode.selfAssess,
          reason: '$mode',
        );
      }
    });
  });

  group('direction maps to faces (BR-204)', () {
    test('Korean→Meaning asks from the front and reveals the back', () {
      const direction = StudyRecallDirection.koreanToMeaning;

      expect(direction.promptFace, StudyCardFace.front);
      expect(direction.revealFace, StudyCardFace.back);
    });

    test('Meaning→Korean asks from the back and reveals the front', () {
      const direction = StudyRecallDirection.meaningToKorean;

      expect(direction.promptFace, StudyCardFace.back);
      expect(direction.revealFace, StudyCardFace.front);
    });

    test('the two faces are never the same one, for any value', () {
      // The reveal is derived from the prompt precisely so this cannot drift;
      // the test is what says the derivation is the right one, including for
      // `unknown` — which still has to draw a card.
      for (final direction in StudyRecallDirection.values) {
        expect(direction.promptFace, isNot(direction.revealFace));
      }
    });

    test('an unrecognised direction draws what every build before it drew', () {
      expect(
        StudyRecallDirection.unknown.promptFace,
        StudyCardFace.front,
        reason: 'a row from a newer build must not blank the card',
      );
    });
  });

  group('stored values', () {
    test('every nameable direction round-trips', () {
      for (final direction in StudyRecallDirection.values) {
        if (direction == StudyRecallDirection.unknown) continue;

        expect(StudyRecallDirection.fromDbValue(direction.dbValue), direction);
      }

      for (final direction in StudySessionDirection.values) {
        if (direction == StudySessionDirection.unknown) continue;

        expect(StudySessionDirection.fromDbValue(direction.dbValue), direction);
      }
    });

    test('a value this build does not know degrades rather than throws', () {
      expect(
        StudyRecallDirection.fromDbValue('korean_to_hanja'),
        StudyRecallDirection.unknown,
      );
      expect(
        StudySessionDirection.fromDbValue('korean_to_hanja'),
        StudySessionDirection.unknown,
      );
    });

    test('a turn can never store `mixed`', () {
      // The two enums are separate so that this is a type error rather than a
      // runtime check. What is left to assert is the other half: a turn's
      // enumeration has no `mixed` in it at all.
      expect(
        StudyRecallDirection.values.map((direction) => direction.name),
        isNot(contains('mixed')),
      );
      expect(
        StudyRecallDirection.fromDbValue(StudySessionDirection.mixed.dbValue),
        StudyRecallDirection.unknown,
      );
    });

    test('unknown refuses to be written back', () {
      expect(() => StudyRecallDirection.unknown.dbValue, throwsStateError);
      expect(() => StudySessionDirection.unknown.dbValue, throwsStateError);
    });

    test('a session direction resolves to a turn direction, except mixed', () {
      expect(
        StudySessionDirection.koreanToMeaning.fixedDirection,
        StudyRecallDirection.koreanToMeaning,
      );
      expect(
        StudySessionDirection.meaningToKorean.fixedDirection,
        StudyRecallDirection.meaningToKorean,
      );
      expect(StudySessionDirection.mixed.fixedDirection, isNull);
      expect(StudySessionDirection.unknown.fixedDirection, isNull);
    });
  });

  group('mixed assignment (BR-205)', () {
    int countOf(
      List<StudyRecallDirection> directions,
      StudyRecallDirection wanted,
    ) => directions.where((direction) => direction == wanted).length;

    test('the balance contract holds for every size', () {
      // **The contract is `|a - b| <= 1`, not a distribution.** A per-card coin
      // flip would pass a spot check and still hand a twenty-card session
      // fourteen of one kind about one time in sixteen — which is the failure
      // this rule exists to make impossible rather than unlikely.
      for (var count = 0; count <= 40; count++) {
        final directions = assignMixedDirections(
          count: count,
          random: Random(count),
        );

        expect(directions, hasLength(count));
        expect(
          countOf(directions, StudyRecallDirection.koreanToMeaning) -
              countOf(directions, StudyRecallDirection.meaningToKorean),
          inInclusiveRange(-1, 1),
          reason: 'count = $count',
        );
      }
    });

    test('neither direction is ever the unknown one', () {
      final directions = assignMixedDirections(count: 30, random: Random(1));

      expect(directions, isNot(contains(StudyRecallDirection.unknown)));
    });

    test('an even split is exact', () {
      final directions = assignMixedDirections(count: 20, random: Random(3));

      expect(countOf(directions, StudyRecallDirection.koreanToMeaning), 10);
      expect(countOf(directions, StudyRecallDirection.meaningToKorean), 10);
    });

    test('the odd card is not always given to the same side', () {
      // A fixed winner makes every odd-sized session lean the same way, which
      // over a fortnight of daily nineteen-card reviews is a bias a learner can
      // feel. Drawn from the injected generator, so both outcomes are reachable.
      final leaders = <StudyRecallDirection>{};
      for (var seed = 0; seed < 40; seed++) {
        final directions = assignMixedDirections(
          count: 5,
          random: Random(seed),
        );
        leaders.add(
          countOf(directions, StudyRecallDirection.koreanToMeaning) == 3
              ? StudyRecallDirection.koreanToMeaning
              : StudyRecallDirection.meaningToKorean,
        );
      }

      expect(leaders, hasLength(2));
    });

    test('both directions really appear once there is room for both', () {
      final directions = assignMixedDirections(count: 2, random: Random(9));

      expect(directions.toSet(), hasLength(2));
    });

    test('the same seed deals the same hand', () {
      // The whole point of the injected generator: a queue laid out twice from
      // one seed is one deal, so a test can pin it and a fixture can reproduce
      // it.
      expect(
        assignMixedDirections(count: 11, random: Random(42)),
        assignMixedDirections(count: 11, random: Random(42)),
      );
    });

    test('an empty queue asks for nothing', () {
      expect(assignMixedDirections(count: 0, random: Random(0)), isEmpty);
      expect(assignMixedDirections(count: -3, random: Random(0)), isEmpty);
    });
  });
}
