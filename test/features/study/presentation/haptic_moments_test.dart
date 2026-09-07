import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/features/card/presentation/controllers/card_selection_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// The three moments the app is allowed to buzz at, and the many it is not.
///
/// **`MxActionButton` deliberately stays silent.** It is the app's one action
/// button and has seventy-three call sites; a haptic inside it would fire on
/// Cancel, Close, Retry and Save. A tap that opens a sheet already has the
/// sheet as its answer. So the decision is scoped to state changes a finger
/// cannot otherwise feel — and this file is what stops it spreading back.
void main() {
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') calls.add(call);

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  List<String> kinds() =>
      calls.map((call) => call.arguments as String).toList();

  group('entering and leaving multi-select', () {
    /// A container with the provider held open.
    ///
    /// `read` alone is not enough: the notifier is `autoDispose`, so without a
    /// live listener it is torn down between the call that enters selection and
    /// the one that leaves, and the second call throws on a disposed `Ref`
    /// rather than measuring anything.
    CardSelection notifierFor() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(
        cardSelectionProvider('deck-1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      return container.read(cardSelectionProvider('deck-1').notifier);
    }

    test('ticks on the way in and on the way out', () async {
      final notifier = notifierFor();

      notifier.beginWith('card-1');
      await Future<void>.delayed(Duration.zero);
      expect(kinds(), <String>['HapticFeedbackType.selectionClick']);

      notifier.clear();
      await Future<void>.delayed(Duration.zero);
      expect(kinds(), hasLength(2));
    });

    test('but not for every card added inside the mode', () async {
      final notifier = notifierFor();

      notifier.beginWith('card-1');
      await Future<void>.delayed(Duration.zero);
      calls.clear();

      notifier.toggle('card-2');
      notifier.toggle('card-3');
      await Future<void>.delayed(Duration.zero);

      expect(
        kinds(),
        isEmpty,
        reason:
            'the row already shows it is selected; a tick per card turns a '
            'five-card selection into five buzzes',
      );
    });

    test(
      'and the last card leaving the selection ticks, because the mode ends',
      () async {
        final notifier = notifierFor();

        notifier.beginWith('card-1');
        await Future<void>.delayed(Duration.zero);
        calls.clear();

        notifier.toggle('card-1');
        await Future<void>.delayed(Duration.zero);

        expect(kinds(), <String>['HapticFeedbackType.selectionClick']);
      },
    );
  });

  group('the verdict pair', () {
    final english = AppLocalizationsEn();

    Future<void> pumpRecall(WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (outcome) async => commitOf('c1'),
          ),
          isScrollable: false,
        ),
      );
      await tester.tap(find.text(english.studyRevealAnswer));
      await tester.pumpAndSettle();
    }

    testWidgets('answering is felt', (tester) async {
      await pumpRecall(tester);
      calls.clear();

      await tester.tap(find.text(english.studyActionRemembered));
      await tester.pump();

      expect(kinds(), <String>['HapticFeedbackType.lightImpact']);
    });

    testWidgets('but revealing the answer is not', (tester) async {
      // The counterpart that keeps this scoped: a tap whose whole result is
      // already on screen does not need a second channel to say so.
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (outcome) async => commitOf('c1'),
          ),
          isScrollable: false,
        ),
      );
      calls.clear();

      await tester.tap(find.text(english.studyRevealAnswer));
      await tester.pumpAndSettle();

      expect(kinds(), isEmpty);
    });
  });
}
