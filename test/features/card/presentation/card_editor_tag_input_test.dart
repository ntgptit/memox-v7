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

    /// The trailing 48-square of the chip: what the delete slot occupies once
    /// `deleteIconBoxConstraints` widens it, and what the chip's redirecting
    /// hit detection hands to that slot.
    Rect deleteBand(WidgetTester tester) {
      final Rect chip = tester.getRect(find.byType(Chip));

      return Rect.fromLTRB(
        chip.right - AppSpacing.minimumTouchTarget,
        chip.top,
        chip.right,
        chip.bottom,
      );
    }

    Future<void> pumpOneTag(
      WidgetTester tester,
      FakeCardRepository repository,
    ) async {
      await pumpCardEditor(tester, repository);
      repository.emitTags(<TagEntity>[repository.tag('t1', name: 'noun')]);
      await tester.pumpAndSettle();
    }

    testWidgets('the chip itself is 48 tall', (tester) async {
      final repository = seed();
      await pumpOneTag(tester, repository);

      expect(
        tester.getRect(find.byType(Chip)).height,
        AppSpacing.minimumTouchTarget,
      );
    });

    testWidgets('the near corner of the delete band fires', (tester) async {
      final repository = seed();
      await pumpOneTag(tester, repository);

      // **The painted glyph is 16 x 16 and is not the target.** The chip hands
      // its whole padded height to whichever slot is under the x, and the slot
      // width is what the constraint sets — so the reachable area is measured
      // from the chip, not from the icon. Boundary taps rather than a centre
      // tap: a centre tap passes on a 16 x 16 target too. Two pixels in, not
      // one — the chip's outermost row and column belong to its own edge.
      await tester.tapAt(deleteBand(tester).topLeft + const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(repository.tagRemoves.single.tagId, 't1');
    });

    testWidgets('the far corner of the delete band fires', (tester) async {
      final repository = seed();
      await pumpOneTag(tester, repository);

      // A separate test rather than a second tap: the remove controller
      // refuses a resubmit once it has reported, so two taps in one test would
      // pass on a tree where only the first point is live.
      await tester.tapAt(deleteBand(tester).bottomRight - const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(repository.tagRemoves.single.tagId, 't1');
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
