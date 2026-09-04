import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/support/study_swipe_deck_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'support/study_widget_harness.dart';

/// A20.1-P0-01 — `browse` must be completable by a single pointer without
/// dragging (WCAG 2.5.7).
///
/// **Implementation-neutral by design.** The affordance is found through the
/// accessibility tree — a `button` with the Continue / Previous label — and
/// never by widget type, so a card-region tap target and a real button both
/// satisfy it. What is asserted is the contract: the affordance is visible and
/// enabled, one tap advances, one tap goes back where going back is allowed,
/// and the swipe still works because the tap path is an addition, not a
/// replacement.
void main() {
  const cards = <String>['card-A', 'card-B', 'card-C'];

  Future<void> pumpBrowse(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(const _BrowseHost(cards: cards), isScrollable: false),
    );
  }

  String labelOf(WidgetTester tester, String Function(AppLocalizations) pick) {
    final context = tester.element(find.byType(StudySwipeDeckWidget));
    return pick(AppLocalizations.of(context));
  }

  /// The affordance with [label], as a screen reader would meet it: found in
  /// the semantics tree by its spoken name, then required to be a button —
  /// regardless of what widget draws it.
  Finder affordance(WidgetTester tester, String label) {
    return find.bySemanticsLabel(label);
  }

  void expectEnabledButton(WidgetTester tester, Finder finder) {
    expect(finder, findsAtLeastNWidgets(1));
    final node = tester.getSemantics(finder.first);
    final flags = node.flagsCollection;
    expect(flags.isButton, isTrue, reason: 'not announced as a button');
    expect(
      flags.isEnabled,
      Tristate.isTrue,
      reason: 'the affordance is disabled',
    );
    expect(flags.isHidden, isFalse, reason: 'the affordance is hidden');
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'no tap action',
    );
  }

  testWidgets('one tap on Continue advances; one tap on Previous goes back', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpBrowse(tester);
    expect(find.text('card-A'), findsOneWidget);

    final next = labelOf(tester, (l) => l.studyContinueAction);
    final previous = labelOf(tester, (l) => l.studyBrowsePreviousCard);

    // 2 — a visible, enabled, single-pointer Continue affordance exists.
    expectEnabledButton(tester, affordance(tester, next));
    // At the front of the trail there is nothing to go back to, so no
    // Previous is offered — an action that does nothing is worse than one
    // that is not there.
    expect(affordance(tester, previous), findsNothing);

    // 3 + 4 — one tap, no drag, and the study advanced.
    await tester.tap(affordance(tester, next).first);
    await tester.pumpAndSettle();
    expect(find.text('card-B'), findsOneWidget);
    expect(find.text('card-A'), findsNothing);

    // 5 — where going back is allowed, the equivalent Previous exists and
    // one tap goes back.
    expectEnabledButton(tester, affordance(tester, previous));
    await tester.tap(affordance(tester, previous).first);
    await tester.pumpAndSettle();
    expect(find.text('card-A'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('the swipe still advances — the tap path is an addition', (
    tester,
  ) async {
    await pumpBrowse(tester);

    await tester.drag(
      find.text('card-A'),
      const Offset(-(kStudySwipeThreshold + 20), 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('card-B'), findsOneWidget);
  });

  testWidgets('the affordances meet the touch-target floor', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBrowse(tester);
    await tester.tap(
      affordance(tester, labelOf(tester, (l) => l.studyContinueAction)).first,
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}

/// The smallest host that can *advance*: a list of cards and an index, so the
/// test observes the study moving rather than a callback being called.
class _BrowseHost extends StatefulWidget {
  const _BrowseHost({required this.cards});

  final List<String> cards;

  @override
  State<_BrowseHost> createState() => _BrowseHostState();
}

class _BrowseHostState extends State<_BrowseHost> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return StudySwipeDeckWidget(
      cardKey: widget.cards[_index],
      canGoBack: _index > 0,
      onForward: () {
        if (_index < widget.cards.length - 1) setState(() => _index++);
      },
      onBack: () {
        if (_index > 0) setState(() => _index--);
      },
      child: SizedBox(
        height: 300,
        child: Center(child: Text(widget.cards[_index])),
      ),
    );
  }
}
