import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/card/domain/entities/tag_entity.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// The tag strip's two affordances, its cap, and the targets they have to hit
/// (BR-93, BR-94).
///
/// **The visible half is the new one.** Committing a tag used to require the
/// keyboard's `done` key — an action with no affordance on a form otherwise
/// made of buttons, and unreachable at all on a platform whose soft keyboard is
/// not showing.
void main() {
  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    return repository;
  }

  List<TagEntity> tags(FakeCardRepository repository, int count) => <TagEntity>[
    for (int i = 0; i < count; i++) repository.tag('tag-$i', name: 'tag $i'),
  ];

  group('adding a tag', () {
    testWidgets('the button and the keyboard take the same path', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(tagInput(), 'from the button');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(tagInput(), 'from the keyboard');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.tagAdds.map((add) => add.name), <String>[
        'from the button',
        'from the keyboard',
      ]);
    });

    testWidgets('the button is inert until something is typed', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(repository.tagAdds, isEmpty);

      // Whitespace is not something: a save would trim it to nothing.
      await tester.enterText(tagInput(), '   ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(repository.tagAdds, isEmpty);
    });

    testWidgets('a successful add clears the field', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(tagInput(), 'noun');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(tagInput()).controller?.text, isEmpty);
    });

    testWidgets('a failed add keeps what was typed', (tester) async {
      final repository = seed();
      repository.nextTagFailure = const DatabaseFailure(message: 'nope');
      await pumpCardEditor(tester, repository);

      await tester.enterText(tagInput(), 'noun');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(tagInput()).controller?.text, 'noun');
      expect(find.text('Please try again.'), findsOneWidget);
    });
  });

  group('the cap', () {
    testWidgets('one below the cap the field is still there', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      repository.emitTags(tags(repository, kMaxTagsPerCard - 1));
      await tester.pumpAndSettle();

      expect(tagInput(), findsOneWidget);
      expect(find.text('9 / 10'), findsOneWidget);
    });

    testWidgets('at the cap the field is replaced by the reason', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      repository.emitTags(tags(repository, kMaxTagsPerCard));
      await tester.pumpAndSettle();

      // Not a disabled field: an input that accepts nothing and says nothing
      // is an invitation with the door shut.
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.textContaining('Remove one'), findsOneWidget);
      expect(find.text('10 / 10'), findsOneWidget);
    });
  });

  group('targets', () {
    testWidgets('the add button meets the Android guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCardEditor(tester, seed());

      await tester.enterText(tagInput(), 'noun');
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    Future<void> pumpOneTag(
      WidgetTester tester,
      FakeCardRepository repository,
    ) async {
      await pumpCardEditor(tester, repository);
      repository.emitTags(<TagEntity>[repository.tag('t1', name: 'noun')]);
      await tester.pumpAndSettle();
    }

    testWidgets('the chip is 48 tall and that band reaches the delete', (
      tester,
    ) async {
      final repository = seed();
      await pumpOneTag(tester, repository);

      // **The painted glyph is 16 x 16 and is not the target.** The chip hands
      // its whole padded height to whichever slot is under the x, so the top
      // and bottom edges of the pill are live above the delete icon. A centre
      // tap would pass on a 16-square too, which is why this taps the extremes.
      final Rect chip = tester.getRect(find.byType(Chip));
      final Rect glyph = tester.getRect(find.byTooltip('Remove tag noun'));
      expect(chip.height, AppSpacing.minimumTouchTarget);

      await tester.tapAt(Offset(glyph.center.dx, chip.top + 2));
      await tester.pumpAndSettle();
      expect(repository.tagRemoves.single.tagId, 't1');
    });

    testWidgets('the bottom of that band reaches it too', (tester) async {
      final repository = seed();
      await pumpOneTag(tester, repository);

      final Rect chip = tester.getRect(find.byType(Chip));
      final Rect glyph = tester.getRect(find.byTooltip('Remove tag noun'));

      // A separate test rather than a second tap: the remove controller
      // refuses a resubmit once it has reported, so two taps in one test would
      // pass on a tree where only the first point is live.
      await tester.tapAt(Offset(glyph.center.dx, chip.bottom - 2));
      await tester.pumpAndSettle();
      expect(repository.tagRemoves.single.tagId, 't1');
    });

    testWidgets('the chip is not widened to reach the 48dp guideline', (
      tester,
    ) async {
      final repository = seed();
      await pumpOneTag(tester, repository);

      // **A deliberate shortfall, pinned so that changing it is a decision.**
      // The delete band is 48 tall and **33 wide** — measured by hit-testing
      // its boundaries: live from x=63 to x=96 on a chip ending at 96.
      // `deleteIconBoxConstraints: minWidth 48` reaches the guideline and
      // costs 28px of chip width, 80 to 108, which at ten tags is a third row
      // on the narrowest screen. The owner looked at both rendered and chose
      // the width (2026-08-26).
      //
      // Asserted here rather than trusted to `meetsGuideline`, which is green
      // on this chip either way: it reads the semantics rect, and the delete's
      // node merges into the chip's 48dp one.
      expect(
        tester.widget<Chip>(find.byType(Chip)).deleteIconBoxConstraints,
        isNull,
      );
      expect(tester.getRect(find.byType(Chip)).width, lessThan(100));
    });

    testWidgets('a failed removal keeps the chip on screen', (tester) async {
      final repository = seed();
      repository.nextRemoveTagFailure = const DatabaseFailure(message: 'nope');
      await pumpCardEditor(tester, repository);

      repository.emitTags(<TagEntity>[repository.tag('t1', name: 'noun')]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove tag noun'));
      await tester.pumpAndSettle();

      expect(find.text('noun'), findsOneWidget);
      expect(find.text('Please try again.'), findsOneWidget);
    });
  });
}
