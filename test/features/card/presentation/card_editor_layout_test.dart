import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/entities/tag_entity.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_action_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_context_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_trash_action_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// The concept's layout, measured: the context rows, the Trash card, the tag
/// cap, the shared content edge and the pinned footer.
///
/// Split from the command half at the 400-line guard.
void main() {
  Finder footerSave() => find.descendant(
    of: find.byType(CardEditorActionBarWidget),
    matching: find.widgetWithText(MxActionButton, 'Save changes'),
  );

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

  group('context rows', () {
    testWidgets('the history row opens card detail and states no metric', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      // BR-243: the editor must not build a second aggregate from history. It
      // is a way *to* the screen that owns those numbers.
      expect(find.textContaining('recall'), findsNothing);
      expect(find.textContaining('reviews'), findsNothing);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('card detail'), findsOneWidget);
    });

    testWidgets('the deck row offers nothing to tap', (tester) async {
      final repository = seed();
      repository.deckContextToShow = const DeckContextModel(
        deckName: 'TOPIK II',
        ancestors: <DeckBreadcrumbSegment>[],
      );
      await pumpCardEditor(tester, repository);

      // Moving a card between decks is UC-04 A5 and is refused across roots
      // (BR-73/BR-74). A chevron here would be an affordance for something this
      // screen will not do.
      expect(find.text('TOPIK II'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(CardEditorContextWidget),
          matching: find.byIcon(Icons.expand_more),
        ),
        findsNothing,
      );
    });

    testWidgets('a card in another deck refuses to render the wrong path', (
      tester,
    ) async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      repository.cardToGet = repository
          .card('card-1')
          .copyWith(deckId: 'another-deck');

      await pumpCardEditor(tester, repository);

      expect(find.textContaining("isn't in this deck"), findsOneWidget);
      expect(find.byType(CardEditorContextWidget), findsNothing);
    });
  });

  group('the Trash card is soft-delete, and says so', () {
    testWidgets('it never claims the history is removed', (tester) async {
      await pumpCardEditor(tester, seed());

      expect(find.text('Move this flashcard to Trash'), findsOneWidget);
      // BR-256 keeps the card, its state and its history until purge. Copy
      // claiming otherwise would be wrong, not just alarming.
      // BR-264 purges at 30 days whether or not the user empties Trash, so the
      // card names the same window the confirmation does.
      expect(find.textContaining('for 30 days'), findsOneWidget);
      expect(find.text('Danger zone'), findsNothing);
    });

    testWidgets('its action is neutral, not the purge colour', (tester) async {
      await pumpCardEditor(tester, seed());

      final MxActionButton action = tester.widget<MxActionButton>(
        find.descendant(
          of: find.byType(CardTrashActionWidget),
          matching: find.widgetWithText(MxActionButton, 'Move to Trash'),
        ),
      );

      // BR-266 reserves `destructive` for permanent purge. Spending it on a
      // reversible move leaves the colour with nothing to say later.
      expect(action.variant, MxActionButtonVariant.secondary);
    });
  });

  group('the tag cap', () {
    testWidgets('at the cap there is nothing to open', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      repository.emitTags(<TagEntity>[
        for (int i = 0; i < kMaxTagsPerCard; i++)
          repository.tag('tag-$i', name: 'tag $i'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Add tag'), findsNothing);
      expect(find.textContaining('Remove one'), findsOneWidget);
    });

    testWidgets('a draft stranded behind the cap does not trap the user', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      final field = await openTagEntry(tester);
      await tester.enterText(field, 'half typed');
      await tester.pump();

      // The chips are a `watch()` stream, so the cap can arrive from an import
      // or another surface while this editor is open.
      repository.emitTags(<TagEntity>[
        for (int i = 0; i < kMaxTagsPerCard; i++)
          repository.tag('tag-$i', name: 'tag $i'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Nothing visible is unsaved, so nothing is asked — and the only way out
      // is not `Discard` on changes the user cannot see.
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsOneWidget);
    });
  });

  group('geometry', () {
    testWidgets('every section shares one content edge', (tester) async {
      final repository = seed();
      repository.cardToGet = repository
          .card('card-1')
          .copyWith(example: 'seeded');
      await pumpCardEditor(
        tester,
        repository,
        surfaceSize: const Size(390, 900),
      );
      repository.emitTags(<TagEntity>[repository.tag('t1', name: 'noun')]);
      await tester.pumpAndSettle();

      const double gutter = AppSpacing.lg;
      for (final Finder section in <Finder>[
        find.byType(CardEditorContextWidget),
        find.byType(CardTrashActionWidget),
      ]) {
        final Rect rect = tester.getRect(section);
        expect(rect.left, gutter, reason: 'section left edge');
        expect(rect.right, 390 - gutter);
      }
    });

    testWidgets('the footer is outside the scroll and both actions match', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      expect(
        find.ancestor(
          of: find.byType(CardEditorActionBarWidget),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );

      final Rect save = tester.getRect(footerSave());
      final Rect cancel = tester.getRect(
        find.descendant(
          of: find.byType(CardEditorActionBarWidget),
          matching: find.widgetWithText(MxActionButton, 'Cancel'),
        ),
      );
      // **One size, which is not the concept's proportion.** Two attempts at
      // that proportion each broke a label: a 3 : 1 flex wrapped `Cancel` at
      // 390dp, and sizing Cancel to its own label let it grow past Save at 320
      // and text scale 2.0 — 142.6 against 141.4, with `Save changes`
      // ellipsized mid-word. `MxButtonPair` asks the buttons instead, and the
      // repo already argued in M99.53 that a pair drawn at two sizes has made
      // the choice for the user.
      expect(save.width, cancel.width);
      expect(save.height, cancel.height);
      expect(save.height, greaterThanOrEqualTo(AppSizing.touchTarget));
    });

    testWidgets('the footer stays above the keyboard', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.reset);

      await pumpCardEditor(tester, seed());

      // `Scaffold` subtracts the keyboard from the body and pins
      // `bottomNavigationBar` at `size.height - barHeight` regardless — which
      // is why the footer is the body's last row instead.
      expect(tester.getRect(footerSave()).bottom, lessThanOrEqualTo(844 - 336));
    });

    testWidgets('the note under the footer is not a status', (tester) async {
      final repository = seed();
      final gate = Completer<void>();
      repository.updateGate = gate;
      await pumpCardEditor(tester, repository);

      const String note = 'Changes save to this device only.';
      expect(find.text(note), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(footerSave());
      await tester.pump();

      expect(find.text(note), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
    });
  });

  group('approved differences hold', () {
    testWidgets('no mic, no speaker button, no aggregate metric', (
      tester,
    ) async {
      final repository = seed();
      repository.cardToGet = repository
          .card('card-1')
          .copyWith(pronunciation: 'yeon-gu-ja');
      await pumpCardEditor(tester, repository);

      // D9 defers voice input and TTS: a glyph that looks like an action and
      // does nothing is worse than no glyph. The pronunciation label keeps a
      // decorative speaker, which is why this looks for the *button*.
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byIcon(Icons.mic_none), findsNothing);
      expect(find.byType(IconButton), findsWidgets);
      for (final IconButton button in tester.widgetList<IconButton>(
        find.byType(IconButton),
      )) {
        final Widget icon = button.icon;
        if (icon is! Icon) continue;
        expect(icon.icon, isNot(Icons.volume_up_outlined));
        expect(icon.icon, isNot(Icons.volume_up));
      }
    });

    testWidgets('the flag survives a concept that does not draw it', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      // BR-92 is a shipped feature; a redesign that quietly removed its only
      // affordance would be deleting a capability under cover of a layout
      // change.
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });
  });
}
