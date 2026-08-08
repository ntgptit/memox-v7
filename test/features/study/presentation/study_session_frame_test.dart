import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';

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
    deckName: 'Korean',
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

  testWidgets('the context line names the deck and the session kind', (
    tester,
  ) async {
    // §7.2, BR-142: one card set, named. Never "12 NEW · 11 REVIEW" side by
    // side, which is the design the ruling threw out.
    // `guess`, because `match` adds a round to this line and the pair being
    // checked here is deck and kind.
    await pumpFrame(
      tester,
      frame(mode: StudyMode.guess, kind: StudySessionKind.learning),
    );
    expect(find.text('Korean · Learning'), findsOneWidget);

    // Named even though it is the default: the pair is the point of the test,
    // and a reader should not have to look up which one the helper picks.
    // ignore: avoid_redundant_argument_values
    await pumpFrame(
      tester,
      // ignore: avoid_redundant_argument_values
      frame(mode: StudyMode.guess, kind: StudySessionKind.reviewing),
    );
    expect(find.text('Korean · Review'), findsOneWidget);
  });

  testWidgets('every mode gets its own hint line, and it comes from ARB', (
    tester,
  ) async {
    const hints = <StudyMode, String>{
      StudyMode.browse: 'Read both sides, then continue',
      StudyMode.selfAssess: 'Flip the card, then say how it went',
      StudyMode.match: 'Tap a term, then its meaning',
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

  testWidgets('the mode pill names the mode', (tester) async {
    await pumpFrame(tester, frame(mode: StudyMode.guess));
    expect(find.text('Guess'), findsOneWidget);

    await pumpFrame(tester, frame(mode: StudyMode.fill));
    expect(find.text('Fill in'), findsOneWidget);
    expect(find.text('Guess'), findsNothing);
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

  testWidgets('match adds its round and how many pairs are left', (
    tester,
  ) async {
    // §7.6. Round, not board: BR-115 and BR-117 have only rounds, and splitting
    // one into smaller boards would need a rule saying how big a board is —
    // not a relabelled string.
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
      find.text('Korean · Review · Round 2 · 5 pairs left'),
      findsOneWidget,
    );
  });

  testWidgets('and no other mode adds anything to that line', (tester) async {
    // The counterpart. Without it, "match says round" also passes on a line
    // that says round for every mode.
    await pumpFrame(tester, frame(mode: StudyMode.guess));

    expect(find.text('Korean · Review'), findsOneWidget);
  });
}
