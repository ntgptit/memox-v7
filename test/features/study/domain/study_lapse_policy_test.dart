import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_lapse_policy_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/presentation/widgets/support/study_mode_feedback_widget.dart';

/// The two resolvers, one per layer, and the thing each of them replaced.
///
/// **A resolver's whole value is being total**, and neither of these can be
/// checked for that by reading it: Dart proves the switch covers the enum, not
/// that the arm it takes is the right one. So the arms are asserted here, and
/// the totality is asserted by iterating [StudyMode.values] rather than by
/// listing modes — a mode added later fails this file until someone decides
/// what it does with a lapse and how long its answer stays up.
void main() {
  group('the domain resolver answers for every mode', () {
    test('each mode names what a wrong answer does to its row', () {
      // The map that used to be an `if (mode == StudyMode.match)` in the
      // repository. Stated here as data so the data layer executes a policy
      // rather than recognising a mode (AD-18).
      const expected = <StudyMode, StudyLapsePolicy>{
        StudyMode.browse: StudyLapsePolicy.noAnswer,
        StudyMode.selfAssess: StudyLapsePolicy.spacedRetry,
        StudyMode.match: StudyLapsePolicy.retainAndEnrollNextRound,
        StudyMode.guess: StudyLapsePolicy.completeAndEnrollNextRound,
        StudyMode.recall: StudyLapsePolicy.completeAndEnrollNextRound,
        StudyMode.fill: StudyLapsePolicy.completeAndEnrollNextRound,
      };

      for (final mode in StudyMode.values) {
        final handler = studyModeHandler(mode);
        if (mode == StudyMode.unknown) {
          expect(handler, isNull, reason: 'an unknown mode cannot be run');

          continue;
        }

        expect(
          handler?.lapsePolicy,
          expected[mode],
          reason: '${mode.name} has no decided lapse policy',
        );
      }
    });

    test('only match keeps its card on the board after a wrong answer', () {
      // Stated as a count, not as a name: the point is that *one* mode differs,
      // and a second one appearing is a decision someone has to make rather
      // than a line that slips in.
      final retaining = StudyMode.values
          .map(studyModeHandler)
          .nonNulls
          .where(
            (handler) =>
                handler.lapsePolicy ==
                StudyLapsePolicy.retainAndEnrollNextRound,
          );

      expect(retaining, hasLength(1));
    });
  });

  group('the presentation resolver answers for every mode', () {
    test('a wrong answer is always given at least as long as a right one', () {
      // A correct answer needs to be noticed; an incorrect one needs to be read,
      // found and understood. The relation is the rule — the numbers may be
      // retuned, the order may not invert.
      for (final mode in StudyMode.values) {
        final feedback = studyModeFeedback(mode);

        expect(
          feedback.wrong,
          greaterThanOrEqualTo(feedback.correct),
          reason:
              '${mode.name} gives a wrong answer less time than a right one',
        );
      }
    });

    test('the modes that read a verdict back hold it on screen', () {
      // The bug this whole change exists for: `guess`, `recall` and `fill`
      // inherited a flow that fetched the next card the moment the write
      // returned, so their verdicts were drawn into a widget already being
      // unmounted. Zero here would be that bug returning — for the two modes
      // that still put a verdict up and take it away themselves.
      for (final mode in <StudyMode>[StudyMode.guess, StudyMode.fill]) {
        expect(studyModeFeedback(mode).correct, greaterThan(Duration.zero));
        expect(studyModeFeedback(mode).wrong, greaterThan(Duration.zero));
      }
    });

    test('the modes that time their own reading wait for nothing', () {
      // `browse` grades no card (BR-111) and `self_assess` is the user's own
      // verdict — they already know it. `match` is zero for a different reason:
      // its beats belong to the tile, because only the board knows whether the
      // pair that just landed was the last one.
      //
      // **`recall` joined them, and it is the interesting one** (BR-160). Its
      // two endings are timed by different people. An assessment is given
      // *after* the learner has read the back, so a hold afterwards pauses them
      // on something they are done with; a timeout hands them a back they have
      // never seen and ends at a *Next* they press. One number could serve
      // neither, and 1800/2200ms was answering a question nobody had asked.
      for (final mode in <StudyMode>[
        StudyMode.browse,
        StudyMode.selfAssess,
        StudyMode.match,
        StudyMode.recall,
      ]) {
        expect(studyModeFeedback(mode).correct, Duration.zero);
        expect(studyModeFeedback(mode).wrong, Duration.zero);
      }
    });
  });
}
