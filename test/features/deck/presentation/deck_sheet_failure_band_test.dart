import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/presentation/states/deck_submit_state.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_scheduler_picker_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_form_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_reset_progress_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_scheduler_change_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/move_deck_sheet_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/starter_install_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_feedback_band.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// One face for a write that failed, across every sheet in this unit
/// (SC-C3-19).
///
/// **Five sheets disclosed a failed write five times, and all five did it the
/// same wrong way:** a `bodySmall` line inked `AppInk.danger`, no glyph, no
/// title, no container and no announcement. Colour was the only cue, so the
/// failure was invisible to a screen-reader user and to roughly one man in
/// twelve — while `tag_rename_widget`, one sheet away, already spoke the app's
/// settled grammar for the identical event.
///
/// The measurement is deliberately cross-sheet, for the reason
/// `deck_sheet_footer_gap_test` gives: a face is only a grammar if the same
/// test reads it in every place it is supposed to hold. Five per-file
/// assertions are what the app already had implicitly, and they are exactly
/// what let five sheets agree on the wrong shape without anything noticing. A
/// sixth sheet added to this unit joins the list here rather than choosing for
/// itself.
///
/// Two things are asserted of every sheet: the band is the face, and the step
/// from the last content element to it is `lg`. The gap is measured rather than
/// read off the source because `md`, `lg` and `xl` are all legitimate tokens —
/// only geometry after layout can tell the one that was there from the one that
/// belongs.
void main() {
  final english = AppLocalizationsEn();

  DeckEntity deck({bool isLocked = false}) => DeckEntity(
    id: 'root',
    name: 'Korean',
    parentDeckId: null,
    rootDeckId: 'root',
    contentType: DeckContentType.deck,
    schedulerType: SchedulerType.eightBox,
    schedulerGeneration: 1,
    firstAnsweredAt: isLocked ? DateTime.utc(2026) : null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  DeckTemplate template() => DeckTemplate(
    templateId: 'starter-1',
    version: 1,
    locale: 'en',
    title: DeckName.parse('Everyday English').name!,
    contentSource: 'memox-fixture',
    defaultSchedulerType: SchedulerType.eightBox,
    children: <DeckTemplateNode>[
      DeckTemplateNode.leaf(
        name: DeckName.parse('Basics').name!,
        cards: <DeckTemplateCard>[
          DeckTemplateCard(
            front: CardText.parse('hello', side: CardSide.front).text!,
            back: CardText.parse('xin chào', side: CardSide.back).text!,
          ),
        ],
      ),
    ],
  );

  /// Opens [open] from a throwaway screen and returns once it has settled.
  Future<void> pumpSheet(
    WidgetTester tester,
    FakeDeckRepository repository,
    void Function(BuildContext context) open,
  ) async {
    await pumpDeckScreen(
      tester,
      repository: repository,
      screen: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The step from the last content element to the top of the failure band.
  double bandGap(WidgetTester tester, Finder lastContent) =>
      tester.getRect(find.byType(MxFeedbackBand)).top -
      tester.getRect(lastContent).bottom;

  /// What every one of these sheets must show once its write has failed.
  void expectDeckWriteBand(WidgetTester tester) {
    expect(find.byType(MxFeedbackBand), findsOneWidget);
    // The title is the half the bare red line never had: the line said only
    // "Please try again", which does not say what did not happen.
    expect(find.text(english.deckWriteErrorTitle), findsOneWidget);
    expect(find.text(english.writeErrorMessage), findsOneWidget);
  }

  testWidgets('the deck form discloses a failed write as a band', (
    tester,
  ) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository(),
      screen: Scaffold(
        body: SingleChildScrollView(
          child: DeckFormWidget(
            title: 'New deck',
            submitLabel: 'Create',
            state: const DeckSubmitState(
              failure: DatabaseFailure(message: 'disk full'),
            ),
            onSubmit: (_, _) {},
            onCancel: () {},
          ),
        ),
      ),
    );

    expectDeckWriteBand(tester);
    expect(bandGap(tester, find.byType(MxTextField)), AppSpacing.lg);
  });

  testWidgets('the move picker discloses a refused move as a band', (
    tester,
  ) async {
    final root = fakeRootDeck(id: 'root', name: 'Root');
    final source = fakeSubDeck(
      id: 'deck-1',
      name: 'Source',
      parentId: 'root',
      rootId: 'root',
    );
    final sibling = fakeSubDeck(
      id: 'sibling',
      name: 'Sibling',
      parentId: 'root',
      rootId: 'root',
      contentType: DeckContentType.deck,
    );
    final repository = FakeDeckRepository(
      allDecks: () =>
          Stream<List<DeckEntity>>.value(<DeckEntity>[root, source, sibling]),
      writeFailure: const DatabaseFailure(message: 'disk full'),
    );

    await pumpDeckScreen(
      tester,
      repository: repository,
      screen: Scaffold(
        body: MoveDeckSheetWidget(deckId: 'deck-1', onDone: () {}),
      ),
    );
    await tester.tap(find.text('Sibling'));
    await tester.pumpAndSettle();

    expectDeckWriteBand(tester);
    // The sheet's own title is the last thing above the band here — the list
    // it refuses to close over sits below it, in a `Flexible`.
    expect(bandGap(tester, find.text(english.deckMoveTitle)), AppSpacing.lg);
  });

  testWidgets('the refused move keeps its reason when the list runs out of '
      'room', (tester) async {
    // The one place in this unit where the band competes for height: it is a
    // fixed child of a `mainAxisSize.min` Column and the target list below it
    // is `Flexible`, so growing the band takes room from the list rather than
    // from the sheet. Worth pinning rather than reasoning about, because the
    // failure mode is silent — a band that overflowed would still satisfy
    // every `find.text` assertion above.
    //
    // 320 x 640 at scale 2.0 is the narrow-and-large corner: three targets,
    // double-height text, and a two-line band all asking for the same column.
    final root = fakeRootDeck(id: 'root', name: 'Root');
    final source = fakeSubDeck(
      id: 'deck-1',
      name: 'Source',
      parentId: 'root',
      rootId: 'root',
    );
    final repository = FakeDeckRepository(
      allDecks: () => Stream<List<DeckEntity>>.value(<DeckEntity>[
        root,
        source,
        for (var i = 0; i < 3; i++)
          fakeSubDeck(
            id: 'sibling-$i',
            name: 'Sibling $i',
            parentId: 'root',
            rootId: 'root',
            contentType: DeckContentType.deck,
          ),
      ]),
      writeFailure: const DatabaseFailure(message: 'disk full'),
    );

    await pumpDeckScreen(
      tester,
      repository: repository,
      screen: Scaffold(
        body: MoveDeckSheetWidget(deckId: 'deck-1', onDone: () {}),
      ),
      surface: const Size(320, 640),
      textScale: 2,
    );
    await tester.tap(find.text('Sibling 0'));
    await tester.pumpAndSettle();

    // No overflow: `pumpDeckScreen` would already have thrown, so this asserts
    // the half that a silent RenderFlex error would not — the reason is still
    // on screen, whole, and inside the sheet rather than under its edge.
    expectDeckWriteBand(tester);
    final band = tester.getRect(find.byType(MxFeedbackBand));
    expect(band.top, greaterThanOrEqualTo(0));
    expect(band.bottom, lessThanOrEqualTo(640));
    // The list is what yielded, and it is still there to scroll.
    expect(find.byType(MxListTile), findsWidgets);
  });

  testWidgets('the scheduler change sheet discloses a refusal as a band', (
    tester,
  ) async {
    final repository = FakeDeckRepository(
      writeFailure: const DatabaseFailure(message: 'disk'),
    );
    await pumpSheet(
      tester,
      repository,
      (context) => showDeckSchedulerSheet(context, deck: deck()),
    );

    await tester.tap(find.text(english.deckSchedulerChangeConfirm).last);
    await tester.pumpAndSettle();

    expectDeckWriteBand(tester);
    expect(
      bandGap(tester, find.byType(DeckSchedulerPickerWidget)),
      AppSpacing.lg,
    );
  });

  testWidgets('the reset sheet discloses a failed reset as a band', (
    tester,
  ) async {
    final repository = FakeDeckRepository(
      writeFailure: const DatabaseFailure(message: 'disk'),
    );
    await pumpSheet(
      tester,
      repository,
      (context) => showDeckResetProgressConfirm(
        context,
        deck: deck(),
        hasLearnedCards: true,
      ),
    );

    await tester.tap(find.text(english.deckResetProgressConfirm).last);
    await tester.pumpAndSettle();

    expectDeckWriteBand(tester);
    expect(
      bandGap(tester, find.byType(DeckSchedulerPickerWidget)),
      AppSpacing.lg,
    );
  });

  testWidgets('the starter install sheet names its own event, not a save', (
    tester,
  ) async {
    // The one sheet that does not fail to *save* a deck. "Couldn't save" over
    // "Could not add this deck. Nothing was copied." would put two events in
    // one band, which is why this call site has a title of its own.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckTemplateRepositoryProvider.overrideWithValue(
            _ThrowingTemplateRepository(),
          ),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showStarterInstallSheet(context, template: template()),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(english.starterLibraryInstallAction).last);
    await tester.pumpAndSettle();

    expect(find.byType(MxFeedbackBand), findsOneWidget);
    expect(find.text(english.starterLibraryInstallErrorTitle), findsOneWidget);
    expect(find.text(english.starterLibraryInstallFailed), findsOneWidget);
    expect(find.text(english.deckWriteErrorTitle), findsNothing);
    expect(
      bandGap(tester, find.byType(DeckSchedulerPickerWidget)),
      AppSpacing.lg,
    );
  });

  testWidgets('the band announces itself when it arrives', (tester) async {
    // The half of this that no golden and no `find.text` can see. The census
    // in the app-wide review found only 2 of 16 whole-screen failure faces
    // carrying a live region, so this is the grammar the app is moving
    // *towards* rather than one it has finished adopting — `MxFeedbackBand`
    // owns the flag precisely so a call site cannot forget it.
    final handle = tester.ensureSemantics();
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository(),
      screen: Scaffold(
        body: SingleChildScrollView(
          child: DeckFormWidget(
            title: 'New deck',
            submitLabel: 'Create',
            state: const DeckSubmitState(
              failure: DatabaseFailure(message: 'disk full'),
            ),
            onSubmit: (_, _) {},
            onCancel: () {},
          ),
        ),
      ),
    );

    final band = tester.getSemantics(
      find
          .ancestor(
            of: find.text(english.deckWriteErrorTitle),
            matching: find.byType(Semantics),
          )
          .first,
    );

    expect(band.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });
}

/// An install that always fails, so the sheet's BR-39 failure face renders.
///
/// The catalog is never read here — the sheet is opened directly rather than
/// through `StarterLibraryScreen` — so `installedTemplateKeys` answers empty.
class _ThrowingTemplateRepository implements DeckTemplateRepository {
  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) async => throw Exception('disk full');

  @override
  Future<Set<({String templateId, int version})>>
  installedTemplateKeys() async => <({String templateId, int version})>{};
}
