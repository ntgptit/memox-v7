import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/study_widget_harness.dart';

/// The chrome the five study screens share (M5.18, §7.2, §7.3, §7.8).
void main() {
  Widget frame({
    StudyMode mode = StudyMode.match,
    StudySessionKind kind = StudySessionKind.reviewing,
    StudyStageProgressModel progress = const StudyStageProgressModel(
      round: 1,
      done: 3,
      total: 8,
      completedCardIds: <String>[],
    ),
    ValueListenable<Duration>? timeLeft,
    VoidCallback? onClose,
  }) => StudySessionFrameSectionWidget(
    mode: mode,
    kind: kind,
    cardCount: 12,
    progress: progress,
    timeLeft: timeLeft,
    onClose: onClose ?? () {},
    child: const Text('body'),
  );

  Future<void> pumpFrame(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
  }) => tester.pumpWidget(
    wrapForTest(child, brightness: brightness, isScrollable: false),
  );

  testWidgets('the close button ends the session rather than popping', (
    tester,
  ) async {
    // BR-82. The X is not a back arrow: leaving is a consequence, and a route
    // popped behind an open session is one the app offers to resume next time.
    var closed = false;
    await pumpFrame(tester, frame(onClose: () => closed = true));

    await tester.tap(find.byTooltip('Close session'));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('the counter reads the turn rather than counting', (
    tester,
  ) async {
    await pumpFrame(tester, frame());

    expect(find.text('3 / 8'), findsOneWidget);

    // Same widget, different turn: nothing accumulates between the two, because
    // there is nothing here to accumulate.
    await pumpFrame(
      tester,
      frame(
        progress: const StudyStageProgressModel(
          round: 1,
          done: 4,
          total: 8,
          completedCardIds: <String>[],
        ),
      ),
    );

    expect(find.text('4 / 8'), findsOneWidget);
    expect(find.text('3 / 8'), findsNothing);
  });

  testWidgets('the bar is drawn from the same pair as the figure', (
    tester,
  ) async {
    await pumpFrame(tester, frame());

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(3 / 8, 0.001));
  });

  testWidgets(
    'an empty round draws an empty bar rather than dividing by zero',
    (tester) async {
      await pumpFrame(
        tester,
        frame(
          progress: const StudyStageProgressModel(
            round: 1,
            done: 0,
            total: 0,
            completedCardIds: <String>[],
          ),
        ),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0);
    },
  );

  testWidgets('the context line sizes the session and names its set', (
    tester,
  ) async {
    // §7.2, BR-142: **one** card set, sized. Never "12 NEW · 11 REVIEW" side by
    // side — a session holds one of the two sets, so a line showing both is
    // describing two sessions.
    //
    // It used to read `Korean · Learning`. The deck was chosen two screens ago
    // and "Learning" repeats the chip beside it; between them they gave a
    // learner nothing to act on. How many cards there are is the number the
    // bar is measured against.
    //
    // `guess`, because `match` adds a round to this line and the pair being
    // checked here is the count and the set.
    await pumpFrame(
      tester,
      frame(mode: StudyMode.guess, kind: StudySessionKind.learning),
    );
    expect(find.text('12 NEW CARDS'), findsOneWidget);

    // Named even though it is the default: the pair is the point of the test,
    // and a reader should not have to look up which one the helper picks.
    // ignore: avoid_redundant_argument_values
    await pumpFrame(
      tester,
      // ignore: avoid_redundant_argument_values
      frame(mode: StudyMode.guess, kind: StudySessionKind.reviewing),
    );
    expect(find.text('12 CARDS DUE'), findsOneWidget);
  });

  testWidgets('every mode gets its own hint line, and it comes from ARB', (
    tester,
  ) async {
    const hints = <StudyMode, String>{
      StudyMode.browse: 'Swipe left for next, right to go back',
      StudyMode.selfAssess: 'Flip the card, then say how it went',
      StudyMode.match: 'Tap a term, then its meaning to match',
      StudyMode.guess: 'Choose the right meaning',
      StudyMode.recall: 'Recall it, then show the answer',
      StudyMode.fill: 'Type the answer, then check',
    };

    for (final entry in hints.entries) {
      await pumpFrame(tester, frame(mode: entry.key));
      expect(
        find.text(entry.value),
        findsOneWidget,
        reason: '${entry.key.name} should carry its own instruction',
      );
    }
  });

  testWidgets('the mode chip names the mode, uppercased', (tester) async {
    // The ARB holds the word as written and the chip uppercases it, so a mode
    // name is one string in one place rather than a second all-caps copy that
    // a translator has to keep in step.
    await pumpFrame(tester, frame(mode: StudyMode.guess));
    expect(find.text('GUESS'), findsOneWidget);

    await pumpFrame(tester, frame(mode: StudyMode.fill));
    expect(find.text('FILL IN'), findsOneWidget);
    expect(find.text('GUESS'), findsNothing);
  });

  testWidgets('recall replaces the counter with the clock, in words', (
    tester,
  ) async {
    // §7.3 and BR-128. In words rather than a bare number because this is also
    // what a screen reader announces — a clock readable only by its colour is
    // not readable.
    final clock = ValueNotifier<Duration>(const Duration(seconds: 12));
    addTearDown(clock.dispose);

    await pumpFrame(tester, frame(mode: StudyMode.recall, timeLeft: clock));

    expect(find.text('12s left'), findsOneWidget);
    expect(find.text('3 / 8'), findsNothing);

    clock.value = const Duration(seconds: 11);
    await tester.pump();

    expect(find.text('11s left'), findsOneWidget);
    expect(find.text('12s left'), findsNothing);
  });

  testWidgets('every other mode keeps the counter', (tester) async {
    // The counterpart of the test above: without it, "recall shows a clock"
    // passes on a frame that never shows a counter at all.
    await pumpFrame(tester, frame(mode: StudyMode.fill));

    expect(find.text('3 / 8'), findsOneWidget);
  });

  testWidgets('the count is announced with what it counts', (tester) async {
    await pumpFrame(tester, frame());

    final node = tester.getSemantics(find.bySemanticsLabel('Round progress'));
    expect(node.value, '3 / 8');
  });

  testWidgets('it survives a small screen at double text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // **With the screen gutter, and that is the whole test.** Without it this
    // measured 320px of usable width where the screen gives 272, and passed on
    // a top bar that overflowed by 19px in production — M5.16 found it.
    await tester.pumpWidget(
      wrapForTest(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: frame(),
          ),
        ),
        isScrollable: false,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('it renders in dark too', (tester) async {
    await pumpFrame(tester, frame(), brightness: Brightness.dark);

    expect(tester.takeException(), isNull);
    expect(find.text('3 / 8'), findsOneWidget);
  });

  testWidgets('match names its board and counts that board s pairs', (
    tester,
  ) async {
    // BR-156. A round of 8 is dealt into two boards; 3 answered puts the user
    // on board 1 with 2 of its 5 pairs left. The counter in the top bar still
    // measures the round — this line is the only place the split is visible,
    // and without it finishing five reads as finishing the round.
    await pumpFrame(
      tester,
      frame(
        // Named, because the mode is the subject of this test.
        // ignore: avoid_redundant_argument_values
        mode: StudyMode.match,
        progress: const StudyStageProgressModel(
          round: 2,
          done: 3,
          total: 8,
          completedCardIds: <String>[],
        ),
      ),
    );

    expect(
      find.text('12 CARDS DUE · ROUND 2 · BOARD 1/2 · 2 PAIRS LEFT'),
      findsOneWidget,
      reason:
          'The line is uppercased where the fragments are joined, so a mode '
          'that adds sentence-case copy cannot leave half of it shouting.',
    );
  });

  testWidgets('the last board of a round counts only its own remainder', (
    tester,
  ) async {
    // The same round, five answered: board 2 of 2, and it holds the three the
    // first board did not. Counting the round here instead would say 3 left on
    // a board of 3 and 3 left again on a board of 5 — the same number for two
    // different situations.
    await pumpFrame(
      tester,
      frame(
        // ignore: avoid_redundant_argument_values
        mode: StudyMode.match,
        progress: const StudyStageProgressModel(
          round: 2,
          done: 5,
          total: 8,
          completedCardIds: <String>[],
        ),
      ),
    );

    expect(
      find.text('12 CARDS DUE · ROUND 2 · BOARD 2/2 · 3 PAIRS LEFT'),
      findsOneWidget,
    );
  });

  testWidgets('and no other mode adds anything to that line', (tester) async {
    // The counterpart. Without it, "match says round" also passes on a line
    // that says round for every mode.
    await pumpFrame(tester, frame(mode: StudyMode.guess));

    expect(find.text('12 CARDS DUE'), findsOneWidget);
  });

  testWidgets('the progress track gets what the row does not need', (
    tester,
  ) async {
    // **Measured, because the failure was invisible to every other test.** A
    // bare `Flexible` defaults to `flex: 1`, so the pill and the counter were
    // each allocated a third of the free space, took what they needed, and left
    // the rest as dead space at the end of the row: at 393 wide the track was
    // 108px with 118px of nothing after the counter. Nothing overflowed and
    // nothing was missing — it simply read as an indicator rather than a
    // measure, which is not something an assertion about text can see.
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpFrame(tester, frame(mode: StudyMode.browse));

    final row = tester.getRect(find.byType(Row).first);
    final bar = tester.getRect(find.byType(MxProgressBar));
    final figure = tester.getRect(find.text('3 / 8'));

    expect(
      bar.width,
      greaterThan(row.width * 0.5),
      reason: 'the track is back to a share of the row; it was ${bar.width}',
    );
    // And the row ends where its last child ends. Slack here is the symptom:
    // it is space the track was refused.
    expect(figure.right, closeTo(row.right, 1));
  });
}
