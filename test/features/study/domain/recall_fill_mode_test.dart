import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/fill_mode.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';

/// The two rules that decide an outcome without anybody pressing a button.
void main() {
  group('recall · where the mark falls (BR-129)', () {
    const handler = RecallModeHandler();

    test('one millisecond before the mark the turn is still open', () {
      expect(
        handler.didTimeOut(
          elapsed: kRecallTurnLimit - const Duration(milliseconds: 1),
        ),
        isFalse,
      );
    });

    test('exactly at the mark is a timeout, not a reveal', () {
      // The boundary BR-129 names, and the one a user cannot tell apart from a
      // miss: reading it the other way makes the exact-zero tap generous at
      // random.
      expect(handler.didTimeOut(elapsed: kRecallTurnLimit), isTrue);
    });

    test('past the mark stays a timeout', () {
      expect(
        handler.didTimeOut(
          elapsed: kRecallTurnLimit + const Duration(seconds: 5),
        ),
        isTrue,
      );
    });

    test('the limit is twenty seconds (BR-128)', () {
      expect(kRecallTurnLimit, const Duration(seconds: 20));
    });

    test('remaining never goes negative', () {
      // Stored for Resume (BR-133); a negative value would resume a turn that
      // has already ended.
      expect(
        handler.remainingAfter(kRecallTurnLimit + const Duration(seconds: 9)),
        Duration.zero,
      );
      expect(
        handler.remainingAfter(const Duration(seconds: 5)),
        const Duration(seconds: 15),
      );
    });
  });

  group('recall · what an outcome is worth (BR-159)', () {
    test('only the learner saying so is correct', () {
      // **The rule this group exists for.** `revealed` used to be an outcome
      // and mapped to *correct*, so pressing Show answer promoted the card a
      // box — a learner who gave up at four seconds was graded as if they had
      // known it. Looking at the back is not evidence of recall, and there is
      // no longer an outcome that says it is.
      expect(RecallOutcome.remembered.isCorrect, isTrue);
      expect(RecallOutcome.forgotten.isCorrect, isFalse);
      expect(RecallOutcome.timedOut.isCorrect, isFalse);
    });

    test('running out is the only one that carries a reason (BR-131)', () {
      // Owning up to a blank and running out of time write the same action, so
      // the reason is the only thing that tells them apart afterwards.
      expect(RecallOutcome.timedOut.reason, StudyOutcomeReason.timeout);
      expect(RecallOutcome.forgotten.reason, isNull);
      expect(RecallOutcome.remembered.reason, isNull);
    });
  });

  group('fill · the comparison policy (BR-134)', () {
    const handler = FillModeHandler();

    FillOutcome? grade(String input, String frontFolded) => handler.grade(
      input: input,
      frontFolded: frontFolded,
      hasUsedHint: false,
    );

    test('the answer is measured against the front, not the back', () {
      // **The direction of the mode** (BR-134). `fill` shows the card's back —
      // its meaning — and asks for the front, the Korean term. Graded the other
      // way round, a learner typing the term was marked wrong and a learner
      // copying the prompt back was marked right.
      expect(grade('사과', '사과')!.isCorrect, isTrue);
      expect(grade('quả táo', '사과')!.isCorrect, isFalse);
    });

    test('a Korean term folds to itself — trimmed, and no case to lose', () {
      // Hangul is caseless, so the whole policy for the language this mode is
      // actually for reduces to the trim. It still has to hold: a keyboard that
      // commits a trailing space would otherwise fail every correct answer.
      expect(grade('  사과 ', '사과')!.isCorrect, isTrue);
      expect(FillModeHandler.fold(' 안녕하세요 '), '안녕하세요');
    });

    test('diacritics count — cong is not công', () {
      // The case this whole policy exists for, in the language the app was
      // built for. Folding them together marks a wrong answer right.
      expect(grade('cong', 'công')!.isCorrect, isFalse);
      expect(grade('công', 'công')!.isCorrect, isTrue);
    });

    test('case and surrounding space do not count', () {
      expect(grade('  CÔNG  ', 'công')!.isCorrect, isTrue);
    });

    test('folding is Unicode-aware, which SQLite lower() is not', () {
      // `lower()` in SQLite is ASCII-only; that is why the folded column exists
      // and why this policy is restated in Dart.
      expect(FillModeHandler.fold('ĐÂU'), 'đâu');
    });

    test('an empty answer produces no turn at all (BR-137)', () {
      // Not "wrong": a blank submit is an accident, and recording it as a
      // failure buries a card the user never actually got wrong.
      expect(grade('', 'công'), isNull);
      expect(grade('   ', 'công'), isNull);
    });

    test('every graded turn carries the policy version (BR-135)', () {
      // Changing the policy bumps the version; old rows keep theirs, so a
      // history row still means what it meant when it was written.
      expect(grade('công', 'công')!.comparisonVersion, kFillComparisonVersion);
    });

    test('a hint is recorded and changes nothing else (BR-136)', () {
      final withHint = handler.grade(
        input: 'công',
        frontFolded: 'công',
        hasUsedHint: true,
      )!;
      final without = handler.grade(
        input: 'công',
        frontFolded: 'công',
        hasUsedHint: false,
      )!;

      expect(withHint.hasUsedHint, isTrue);
      // Same correctness, same version: whether a hint makes an answer worth
      // less is a judgement nobody has made.
      expect(withHint.isCorrect, without.isCorrect);
      expect(withHint.comparisonVersion, without.comparisonVersion);
    });

    test('the outcome carries no trace of what was typed (BR-138)', () {
      // A wrong answer is the most private thing in the app. The type itself is
      // what keeps it out of everything downstream.
      final outcome = grade('something private', 'công')!;

      expect(
        outcome.toString(),
        isNot(contains('private')),
        reason: 'FillOutcome must not carry the typed text',
      );
    });
  });
}
