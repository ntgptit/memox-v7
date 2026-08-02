import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/entities/card_review_state_entity.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// BR-89 … BR-91, and BR-88's half of the same ladder.
///
/// **Every assertion here is a boundary.** A projection with three thresholds
/// fails at the edges or not at all — a test that checks box 2 and box 6 passes
/// on an off-by-one at box 4 and at box 8, which are the only two places the
/// arithmetic can be wrong.
void main() {
  CardReviewStateEntity eightBox({required int box, int reviewCount = 1}) =>
      CardReviewStateEntity(
        cardId: 'c1',
        schedulerType: SchedulerType.eightBox,
        schedulerVersion: 1,
        schedulerGeneration: 1,
        dueAt: null,
        lastReviewedAt: null,
        reviewCount: reviewCount,
        lapseCount: 0,
        currentBox: box,
        easeFactor: null,
        intervalDays: null,
        repetitions: null,
      );

  CardReviewStateEntity sm2({required int? days, int reviewCount = 1}) =>
      CardReviewStateEntity(
        cardId: 'c1',
        schedulerType: SchedulerType.sm2,
        schedulerVersion: 1,
        schedulerGeneration: 1,
        dueAt: null,
        lastReviewedAt: null,
        reviewCount: reviewCount,
        lapseCount: 0,
        currentBox: null,
        easeFactor: 2.5,
        intervalDays: days,
        repetitions: 1,
      );

  group('new comes before either scheduler (BR-90)', () {
    test(
      'a card with no scheduled review is new, whatever its columns say',
      () {
        // `eight_box` seeds `current_box = 1` at creation (BR-09), so a
        // projection that read the box first would call every untouched card
        // `beginning` and the state would never be reachable.
        expect(cardStateOf(eightBox(box: 1, reviewCount: 0)), CardState.isNew);
        expect(cardStateOf(sm2(days: 0, reviewCount: 0)), CardState.isNew);
      },
    );

    test('one review is enough to leave it', () {
      expect(cardStateOf(eightBox(box: 1)), isNot(CardState.isNew));
      expect(cardStateOf(sm2(days: 1)), isNot(CardState.isNew));
    });
  });

  group('eight_box boundaries (BR-91, BR-88)', () {
    test('box 1–3 is beginning, and box 4 is where reviewing starts', () {
      expect(cardStateOf(eightBox(box: 3)), CardState.beginning);
      expect(cardStateOf(eightBox(box: 4)), CardState.reviewing);
    });

    test('box 7 is still reviewing, and box 8 is mastered', () {
      expect(cardStateOf(eightBox(box: 7)), CardState.reviewing);
      expect(cardStateOf(eightBox(box: kMasteredBox)), CardState.mastered);
    });

    test('every box in the ladder maps to something', () {
      // BR-16's ladder is 1..8 and nothing outside it exists. A gap would show
      // up as a box that falls through to a default nobody chose.
      for (var box = 1; box <= 8; box++) {
        expect(
          cardStateOf(eightBox(box: box)),
          isNot(CardState.isNew),
          reason: 'box $box has no state',
        );
      }
    });
  });

  group('sm2 boundaries (BR-91, BR-88)', () {
    test('7 days is beginning and 8 days is reviewing', () {
      // 8 is box 4's interval. Sharing it is what makes `beginning` mean the
      // same distance in time on both schedulers.
      expect(cardStateOf(sm2(days: 7)), CardState.beginning);
      expect(
        cardStateOf(sm2(days: kReviewingIntervalDays)),
        CardState.reviewing,
      );
    });

    test('127 days is reviewing and 128 is mastered', () {
      expect(cardStateOf(sm2(days: 127)), CardState.reviewing);
      expect(cardStateOf(sm2(days: kMasteredIntervalDays)), CardState.mastered);
    });
  });

  test('the two schedulers agree at the boundaries they share', () {
    // The claim BR-88 and BR-91 both rest on: the same label means the same
    // interval on both sides. Box 4 is 8 days and box 8 is 128, so a card at
    // each ladder rung must carry the same state as an SM-2 card at that
    // rung's interval.
    const rungs = <int, int>{
      1: 1,
      2: 2,
      3: 4,
      4: 8,
      5: 16,
      6: 32,
      7: 64,
      8: 128,
    };

    for (final rung in rungs.entries) {
      expect(
        cardStateOf(eightBox(box: rung.key)),
        cardStateOf(sm2(days: rung.value)),
        reason:
            'box ${rung.key} is ${rung.value} days, so the two schedulers '
            'should show the same state',
      );
    }
  });

  group('broken rows render rather than throw', () {
    test('a scheduler this build does not know reads as new', () {
      // One row written by a newer version must not take down every screen
      // that lists cards — the same argument that put `unknown` on the enum.
      const state = CardReviewStateEntity(
        cardId: 'c1',
        schedulerType: SchedulerType.unknown,
        schedulerVersion: 99,
        schedulerGeneration: 1,
        dueAt: null,
        lastReviewedAt: null,
        reviewCount: 5,
        lapseCount: 0,
        currentBox: null,
        easeFactor: null,
        intervalDays: null,
        repetitions: null,
      );

      expect(cardStateOf(state), CardState.isNew);
    });

    test('a null box on an eight_box card reads as new, not as box 0', () {
      expect(
        cardStateOf(eightBox(box: 0).copyWith(currentBox: null)),
        CardState.isNew,
      );
    });
  });

  test('the Dart thresholds are the ones the SQL already uses (BR-88)', () {
    // **BR-88 is implemented three times and cannot be implemented once.**
    // `deck.drift` counts mastered cards in two queries, in SQL; this file
    // projects the same predicate in Dart. A `.drift` file and a Dart function
    // share no code, so the only thing that can stop them drifting is a test
    // that reads one and compares it to the other — the same trick the CSS
    // token parity tests use for the design kit.
    final sql = File('lib/core/database/queries/deck.drift').readAsStringSync();

    final boxes = RegExp(
      r"current_box = (\d+)",
    ).allMatches(sql).map((m) => int.parse(m.group(1)!)).toSet();
    final intervals = RegExp(
      r"interval_days >= (\d+)",
    ).allMatches(sql).map((m) => int.parse(m.group(1)!)).toSet();

    expect(
      boxes,
      isNotEmpty,
      reason: 'no mastered predicate found — the query moved or was renamed',
    );
    expect(boxes, <int>{
      kMasteredBox,
    }, reason: 'SQL calls a different box mastered than cardStateOf does');
    expect(
      intervals,
      <int>{kMasteredIntervalDays},
      reason: 'SQL calls a different interval mastered than cardStateOf does',
    );
  });
}
