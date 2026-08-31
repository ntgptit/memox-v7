import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';

/// The Study vocabulary, and the three places it is easy to get backwards.
void main() {
  group('StudyMode', () {
    test('the stored values are exactly the six of BR-108', () {
      final stored = StudyMode.values
          .where((mode) => mode != StudyMode.unknown)
          .map((mode) => mode.dbValue)
          .toList();

      expect(stored, <String>[
        'browse',
        'self_assess',
        'match',
        'guess',
        'recall',
        'fill',
      ]);
    });

    test('browse is the only mode that writes no answer (BR-111)', () {
      final silent = StudyMode.values
          .where((mode) => mode != StudyMode.unknown && !mode.producesAnswer)
          .toList();

      expect(silent, <StudyMode>[StudyMode.browse]);
    });

    test('exactly the four graded modes use rounds (BR-115)', () {
      // Getting this backwards is not a small bug. A `self_assess` queue driven
      // by rounds loses BR-104's ceiling of three; a `match` queue driven by
      // BR-26 never finishes its failed set.
      final rounds = StudyMode.values.where((mode) => mode.usesRounds).toList();

      expect(rounds, <StudyMode>[
        StudyMode.match,
        StudyMode.guess,
        StudyMode.recall,
        StudyMode.fill,
      ]);
    });

    test(
      'an unrecognised value reads as unknown and refuses to be written',
      () {
        // A row from a newer build must not take down the screen that lists it,
        // and must not round-trip back as if somebody had chosen it.
        expect(StudyMode.fromDbValue('hologram'), StudyMode.unknown);
        expect(() => StudyMode.unknown.dbValue, throwsStateError);
      },
    );
  });

  group('StudySessionKind and StudyAnswerKind', () {
    test('an unrecognised session kind throws rather than degrading', () {
      // Unlike StudyMode: a session whose kind cannot be read can neither be
      // shown nor continued, so there is no safe half-render to fall back to.
      expect(() => StudySessionKind.fromDbValue('cramming'), throwsStateError);
    });

    test('only scheduled moves the schedule (BR-77, BR-141)', () {
      final moving = StudyAnswerKind.values
          .where((kind) => kind.movesSchedule)
          .toList();

      expect(moving, <StudyAnswerKind>[StudyAnswerKind.scheduled]);
    });
  });

  group('StudyAction', () {
    test('the two algorithms have disjoint action sets (BR-30)', () {
      // A screen rendering four buttons is wrong for every eight_box deck. The
      // sets never overlap, which is what makes the scheduler the only sensible
      // source for them.
      const eightBox = <StudyAction>[
        StudyAction.forgotten,
        StudyAction.remembered,
      ];
      const sm2 = <StudyAction>[
        StudyAction.again,
        StudyAction.hard,
        StudyAction.good,
        StudyAction.easy,
      ];

      expect(<StudyAction>[...eightBox, ...sm2], StudyAction.values);
      expect(eightBox.toSet().intersection(sm2.toSet()), isEmpty);
    });

    test('a lapse is the wrong answer of either algorithm (BR-20)', () {
      final lapses = StudyAction.values
          .where((action) => action.isLapse)
          .toList();

      expect(lapses, <StudyAction>[StudyAction.forgotten, StudyAction.again]);
    });
  });

  group('the status × end_reason matrix (BR-79 … BR-85)', () {
    // Every pair, both ways, because this is a table and a table is exactly
    // where a spot check passes while a row is wrong.
    const legal = <(StudySessionStatus, StudySessionEndReason?)>[
      (StudySessionStatus.inProgress, null),
      (StudySessionStatus.completed, null),
      (StudySessionStatus.abandoned, StudySessionEndReason.userExit),
      (StudySessionStatus.abandoned, StudySessionEndReason.interrupted),
      (StudySessionStatus.invalidated, StudySessionEndReason.schedulerReset),
      (StudySessionStatus.invalidated, StudySessionEndReason.staleGeneration),
      // BR-259: the deck or card the session was running on went to Trash. Its
      // own value rather than `scheduler_reset`, because nothing about the
      // scheduler changed and only one of the two is undone by pressing Undo.
      (StudySessionStatus.invalidated, StudySessionEndReason.contentDeleted),
      // BR-12's unlocked scheduler change (M100.13). `invalidated` for the same
      // reason a reset is — the queue is dealt for an algorithm the deck no
      // longer runs — but its own reason, because the generation does not move.
      (StudySessionStatus.invalidated, StudySessionEndReason.schedulerChanged),
      (StudySessionStatus.failed, StudySessionEndReason.persistenceError),
    ];

    test('every legal pair is accepted', () {
      for (final (status, reason) in legal) {
        expect(
          status.isValidWith(reason),
          isTrue,
          reason: '$status with $reason should be legal',
        );
      }
    });

    test('every other pair is rejected', () {
      final reasons = <StudySessionEndReason?>[
        null,
        ...StudySessionEndReason.values,
      ];

      for (final status in StudySessionStatus.values) {
        for (final reason in reasons) {
          if (legal.contains((status, reason))) continue;

          expect(
            status.isValidWith(reason),
            isFalse,
            reason: '$status with $reason should be rejected',
          );
        }
      }
    });

    test('interrupted is not user_exit, and both are abandoned', () {
      // BR-103. Merging them would make the history say the user gave up when
      // the OS reclaimed the app — the same argument BR-76 makes for storing
      // `kind` instead of deriving it.
      expect(
        StudySessionEndReason.interrupted,
        isNot(StudySessionEndReason.userExit),
      );
      expect(
        StudySessionStatus.abandoned.isValidWith(
          StudySessionEndReason.interrupted,
        ),
        isTrue,
      );
      expect(
        StudySessionStatus.completed.isValidWith(
          StudySessionEndReason.interrupted,
        ),
        isFalse,
      );
    });
  });
}
