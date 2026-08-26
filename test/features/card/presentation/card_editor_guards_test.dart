import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_context_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_trash_action_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// The cases the two recursive reviews found, pinned so they cannot come back.
///
/// Each one is here because it was **reproduced red first**: a draft that
/// vanished through a breadcrumb, a history entry that could not be returned
/// from, a deck read whose failure looked like a slow frame, a flag that
/// hit-tested as pressable while inert, a label row that cut its own label, a
/// field that counted itself twice, and a heading that overflowed in
/// Vietnamese at the largest text scale.
void main() {
  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card(
      'card-1',
      front: 'old front',
      back: 'old back',
    );

    return repository;
  }

  Future<void> makeDirty(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'new front');
    await tester.pump();
  }

  group('every way out goes through the guard', () {
    testWidgets('a breadcrumb crumb asks before dropping the draft', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);
      await makeDirty(tester);

      // The screen's contract is that leaving with unsaved work asks first.
      // Four `goNamed` calls in the context rows walked past it.
      await tester.tap(find.text('TOPIK II — Vocab').first);
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('deck detail'), findsNothing);
    });

    testWidgets('Discard on a crumb goes where the crumb pointed', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());
      await makeDirty(tester);

      await tester.tap(find.text('TOPIK II — Vocab').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // The guard decides *whether* the navigation happens; it does not
      // replace it with a pop.
      expect(find.text('deck detail'), findsOneWidget);
    });

    testWidgets('a pristine form follows a crumb with no question', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      await tester.tap(find.text('TOPIK II — Vocab').first);
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsOneWidget);
    });

    testWidgets('History pushes, so back returns to the form', (tester) async {
      await pumpCardEditor(tester, seed());
      await makeDirty(tester);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('card detail'), findsOneWidget);

      // `go` replaced the stack, so the editor and its draft were gone. A push
      // leaves them underneath — which is also why this one needs no guard.
      await pressSystemBack(tester);
      expect(find.text('Edit flashcard'), findsOneWidget);
      expect(find.text('new front'), findsOneWidget);
    });
  });

  group('the deck read says which of its three states it is in', () {
    testWidgets('a failed read names what is unavailable', (tester) async {
      final repository = seed();
      repository.nextDeckContextFailure = StateError('deck is gone');
      await pumpCardEditor(tester, repository);

      // It used to be `.value`, which flattened loading, error and "deleted"
      // into one `null` and simply drew no path at all — indistinguishable
      // from a frame that had not arrived.
      expect(find.textContaining("isn't available"), findsOneWidget);
      expect(find.text('All decks'), findsNothing);
      // And the form is still usable: a missing path is not a dead screen.
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('a resolved read draws the path and the deck', (tester) async {
      await pumpCardEditor(tester, seed());

      expect(find.byType(CardEditorContextWidget), findsOneWidget);
      // `Korean` folds into the ellipsis at `collapseAfter: 3` — the root and
      // the leaf are the two crumbs always on screen.
      expect(find.text('All decks'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });
  });

  testWidgets('a flag the screen disabled looks disabled', (tester) async {
    final repository = seed();
    repository.nextFlagFailure = null;
    await pumpCardEditor(tester, repository);

    // The widget read its own `isLoading` and ignored the screen's null
    // `onToggle`, so mid-write the button hit-tested as enabled and did
    // nothing — the affordance lying about itself.
    final IconButton flag = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.flag_outlined),
        matching: find.byType(IconButton),
      ),
    );
    expect(flag.onPressed, isNotNull);
  });

  group('the label row', () {
    testWidgets('every counter ends at the field edge', (tester) async {
      await pumpCardEditor(tester, seed(), surfaceSize: const Size(390, 1400));

      // `Flexible(label)` beside a `Spacer` split the free space evenly, so the
      // counters landed at 282.9 / 353.5 / 374.0 against a surface edge of 374.
      final double edge = tester.getRect(find.byType(TextField).first).right;
      for (final String counter in <String>['9 / 60', '8 / 240']) {
        expect(
          tester.getRect(find.text(counter)).right,
          moreOrLessEquals(edge, epsilon: 0.5),
          reason: 'counter "$counter" is not on the field edge',
        );
      }
    });

    testWidgets('a field counts itself once', (tester) async {
      await pumpCardEditor(tester, seed());

      // `MxTextField` hides its own counter under an external label now: the
      // field used to show `55 / 60` in the label row and `55/60` under the
      // box, two formats of one number.
      await tester.enterText(find.byType(TextField).first, 'x' * 55);
      await tester.pumpAndSettle();

      expect(find.text('55 / 60'), findsOneWidget);
      // The slot stays — it is what keeps the field's height stable when an
      // error arrives — but nothing is painted in it.
      expect(
        tester
            .widget<Visibility>(
              find.ancestor(
                of: find.text('55/60'),
                matching: find.byType(Visibility),
              ),
            )
            .visible,
        isFalse,
      );
    });
  });

  testWidgets('the tag heading does not overflow at 320 and 2.0 in Vietnamese', (
    tester,
  ) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    final repository = seed();
    await pumpCardEditor(
      tester,
      repository,
      locale: const Locale('vi'),
      textScale: 2,
      surfaceSize: const Size(320, 568),
    );
    repository.emitTags(<dynamic>[repository.tag('t1', name: 'noun')].cast());
    await tester.pumpAndSettle();

    // Measured 7.5px over on a 296-wide row. A `Row` of rigid children reports
    // that as a stripe in debug and clips silently in release.
    expect(
      errors.where((e) => '${e.exception}'.contains('overflowed')),
      isEmpty,
    );
  });

  testWidgets('the Trash action sizes to its label, not to the card', (
    tester,
  ) async {
    await pumpCardEditor(tester, seed(), surfaceSize: const Size(390, 1400));

    final Rect action = tester.getRect(
      find.descendant(
        of: find.byType(CardTrashActionWidget),
        matching: find.widgetWithText(MxActionButton, 'Move to Trash'),
      ),
    );
    final Rect card = tester.getRect(find.byType(CardTrashActionWidget));

    // Stretched it came out 326 of the card's 358 — full bleed, reading as the
    // section's primary action rather than as the smaller of two.
    expect(action.width, lessThan(card.width * 0.75));
  });
}
