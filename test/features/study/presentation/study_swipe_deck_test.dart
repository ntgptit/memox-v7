import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/support/study_swipe_deck_widget.dart';
import 'support/study_widget_harness.dart';

/// The swipe deck itself: what a drag commits, and what a reader can invoke.
///
/// **Split out of `study_browse_trail_test.dart` at the guard's 400-line
/// ceiling**, on the seam the file already had — everything above it drives the
/// controller and asks what the trail does, everything here drives a gesture
/// and asks what the widget reports. Same subject (BR-155), two different
/// questions, and the file was answering both.
void main() {
  group('the gesture', () {
    /// Drags the card [dx] pixels and lets go.
    Future<void> drag(WidgetTester tester, double dx) async {
      await tester.drag(find.text('card'), Offset(dx, 0));
      await tester.pumpAndSettle();
    }

    Future<({List<String> events})> pumpDeck(
      WidgetTester tester, {
      bool canGoBack = true,
      bool isLocked = false,
    }) async {
      final events = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          StudySwipeDeckWidget(
            cardKey: 'card-1',
            canGoBack: canGoBack,
            isLocked: isLocked,
            onForward: () => events.add('forward'),
            onBack: () => events.add('back'),
            child: const SizedBox(height: 300, child: Text('card')),
          ),
        ),
      );

      return (events: events);
    }

    testWidgets('a drag left past the threshold moves forward', (tester) async {
      final deck = await pumpDeck(tester);

      await drag(tester, -(kStudySwipeThreshold + 20));

      expect(deck.events, <String>['forward']);
    });

    testWidgets('a drag right past the threshold steps back', (tester) async {
      final deck = await pumpDeck(tester);

      await drag(tester, kStudySwipeThreshold + 20);

      expect(deck.events, <String>['back']);
    });

    testWidgets('a drag short of the threshold does neither', (tester) async {
      // The card scrolls its own halves at a large text scale, and a hair
      // trigger would turn a mis-aimed scroll into a card change.
      final deck = await pumpDeck(tester);

      await drag(tester, kStudySwipeThreshold - 10);
      await drag(tester, -(kStudySwipeThreshold - 10));

      expect(deck.events, isEmpty);
    });

    testWidgets('a drag back with nothing behind is refused, not silent', (
      tester,
    ) async {
      final deck = await pumpDeck(tester, canGoBack: false);

      await drag(tester, kStudySwipeThreshold + 20);

      expect(deck.events, isEmpty);
      // And the card is back where it started, which is what tells the user the
      // gesture was heard and declined.
      expect(tester.getRect(find.text('card')).left, closeTo(0, 1));
    });

    testWidgets('a locked deck offers no reader action either', (tester) async {
      // **The gesture was guarded and the custom actions were not.** A 70dp
      // drag is not available to a screen reader, so the custom actions are
      // that user's only way through the mode — and while the previous step
      // was still being written they were the one path that could fire twice.
      // Absent rather than present-and-inert: an action that does nothing is
      // worse than an action that is not there.
      await pumpDeck(tester, isLocked: true);

      final node = tester.getSemantics(find.byType(StudySwipeDeckWidget));
      expect(
        node.getSemanticsData().customSemanticsActionIds ?? const <int>[],
        isEmpty,
      );
    });

    testWidgets('while a write is in flight the gesture commits nothing', (
      tester,
    ) async {
      // BR-25: the card stays put and the controls stop responding. It still
      // moves under the finger — refusing to move reads as a dropped gesture.
      final deck = await pumpDeck(tester, isLocked: true);

      await drag(tester, -(kStudySwipeThreshold + 40));

      expect(deck.events, isEmpty);
    });
  });

  group('the screen-reader path', () {
    /// The custom actions a `Semantics` node offers: label to action id.
    Map<String, int> actionsOf(WidgetTester tester) {
      final node = tester.getSemantics(find.byType(StudySwipeDeckWidget));
      final ids = node.getSemanticsData().customSemanticsActionIds ?? <int>[];

      return <String, int>{
        for (final id in ids)
          CustomSemanticsAction.getAction(id)!.label ?? '?': id,
      };
    }

    /// Fires one, the way a screen reader does.
    void invoke(WidgetTester tester, int id) {
      final node = tester.getSemantics(find.byType(StudySwipeDeckWidget));
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.customAction,
          nodeId: node.id,
          viewId: tester.view.viewId,
          arguments: id,
        ),
      );
    }

    Future<Map<String, int>> pumpAndRead(
      WidgetTester tester, {
      required bool canGoBack,
      required List<String> events,
    }) async {
      await tester.pumpWidget(
        wrapForTest(
          StudySwipeDeckWidget(
            cardKey: 'card-1',
            canGoBack: canGoBack,
            onForward: () => events.add('forward'),
            onBack: () => events.add('back'),
            child: const SizedBox(height: 300, child: Text('card')),
          ),
        ),
      );

      return actionsOf(tester);
    }

    testWidgets('both moves are offered when there is a trail', (tester) async {
      // **Removing the buttons made this the only way through** for anyone who
      // cannot make a 70dp horizontal drag. Nothing else in the suite would
      // notice it disappearing: the screen renders identically without it.
      final handle = tester.ensureSemantics();
      final events = <String>[];

      final actions = await pumpAndRead(
        tester,
        canGoBack: true,
        events: events,
      );

      expect(actions.keys.toSet(), <String>{'Next', 'Previous card'});

      // Labelled *and* wired. A label pointing at the wrong callback is the
      // failure a label-only assertion cannot see.
      invoke(tester, actions['Previous card']!);
      invoke(tester, actions['Next']!);
      expect(events, <String>['back', 'forward']);

      handle.dispose();
    });

    testWidgets('back is not offered when there is nothing behind', (
      tester,
    ) async {
      // Same reason a disabled button would have been wrong: an action that
      // does nothing is worse than an action that is not there.
      final handle = tester.ensureSemantics();
      final events = <String>[];

      final actions = await pumpAndRead(
        tester,
        canGoBack: false,
        events: events,
      );

      expect(actions.keys.toList(), <String>['Next']);
      handle.dispose();
    });
  });
}
