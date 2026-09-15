import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_form_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_reset_progress_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_scheduler_change_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/move_deck_sheet_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/starter_install_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// **One modal-title rung, and it is `titleMedium`** (SC-C6-04).
///
/// Deck ran two. Three of its five content sheets titled themselves at
/// `titleLarge` — the rung `AppBar` keeps by Material's default, because
/// `app_app_bar_theme.dart` sets no `titleTextStyle` — so those sheets named
/// themselves at the same size as the screen title still visible behind the
/// scrim. The other two, and the ten sibling sheets in card, study and trash,
/// and `app_dialog_theme.dart`'s own `titleTextStyle`, all say `titleMedium`.
///
/// **Nothing pinned this, which is why it drifted.** The rung is invisible to
/// `flutter analyze`, invisible to the guard, and a golden agrees with whatever
/// it was told the day it was written. So the assertion is the rung itself,
/// read off the rendered `Text`, and it covers all five sheets rather than the
/// three that were wrong — a sheet that is right today is exactly the one a
/// later edit can quietly move.
///
/// `MxSheetHeader` is deliberately absent: `mx_sheet.dart` titles *action*
/// sheets at `titleSmall` quiet by design, which is a third rung for a
/// different kind of sheet and a shared API this test does not speak for.
void main() {
  final english = AppLocalizationsEn();

  /// The title's rung, read off the theme rather than restated as a number.
  void expectModalTitleRung(WidgetTester tester, String title) {
    final Finder finder = find.text(title);
    expect(finder, findsOneWidget, reason: title);

    final double? rendered = tester.widget<Text>(finder).style?.fontSize;
    final double? expected = Theme.of(
      tester.element(finder),
    ).textTheme.titleMedium?.fontSize;

    expect(expected, isNotNull);
    expect(rendered, expected, reason: title);
  }

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

  Future<void> pumpSheet(
    WidgetTester tester,
    void Function(BuildContext context) open, {
    FakeDeckRepository? repository,
  }) async {
    await pumpDeckScreen(
      tester,
      repository: repository ?? FakeDeckRepository(),
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

  testWidgets('the create form', (tester) async {
    await pumpDeckApp(tester, repository: FakeDeckRepository());

    await tester.tap(find.text(english.deckCreateRootAction));
    await tester.pumpAndSettle();

    // Scoped to the form: the action that opened it carries the same words and
    // is still mounted behind the sheet, so an unscoped finder reads the
    // button's label — which has no explicit size at all and would compare
    // `null` against the rung.
    final Finder title = find.descendant(
      of: find.byType(DeckFormWidget),
      matching: find.text(english.deckCreateRootTitle),
    );
    expect(title, findsOneWidget);
    expect(
      tester.widget<Text>(title).style?.fontSize,
      Theme.of(tester.element(title)).textTheme.titleMedium?.fontSize,
    );
  });

  testWidgets('the move-target picker', (tester) async {
    final repository = FakeDeckRepository(
      deckList: (_) => Stream<DeckListSnapshot>.value(
        DeckListSnapshot(
          ancestors: const <DeckPathSegment>[],
          parent: deck(),
          decks: const <DeckSummary>[],
          nextDueAt: null,
          nextOverdueTickAt: null,
        ),
      ),
      allDecks: () => Stream<List<DeckEntity>>.value(<DeckEntity>[deck()]),
    );

    await pumpDeckScreen(
      tester,
      repository: repository,
      screen: Scaffold(
        body: MoveDeckSheetWidget(deckId: 'root', onDone: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expectModalTitleRung(tester, english.deckMoveTitle);
  });

  testWidgets('the reset confirmation', (tester) async {
    await pumpSheet(
      tester,
      (context) => showDeckResetProgressConfirm(
        context,
        deck: deck(isLocked: true),
        hasStudyProgress: true,
      ),
    );

    expectModalTitleRung(tester, english.deckResetProgressTitle);
  });

  testWidgets('the scheduler sheet, unlocked', (tester) async {
    await pumpSheet(
      tester,
      (context) => showDeckSchedulerSheet(context, deck: deck()),
    );

    expectModalTitleRung(tester, english.deckSchedulerChangeTitle);
  });

  testWidgets('the scheduler sheet, locked', (tester) async {
    // Its own case: the locked panel is a second `return <Widget>[...]` in the
    // same state class, and it kept its own copy of the title.
    await pumpSheet(
      tester,
      (context) => showDeckSchedulerSheet(context, deck: deck(isLocked: true)),
    );

    expectModalTitleRung(tester, english.deckSchedulerLockedTitle);
  });

  testWidgets('the starter install sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckTemplateRepositoryProvider.overrideWithValue(
            _StubTemplateRepository(),
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
            builder: (context) => TextButton(
              onPressed: () =>
                  showStarterInstallSheet(context, template: _template()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The one title on this sheet that is user content rather than an ARB
    // string, and the reason the drop from 22 to 16 is worth having here: a
    // template name is as long as its author made it.
    expectModalTitleRung(tester, 'Everyday English');
  });
}

DeckTemplate _template() => DeckTemplate(
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

/// Enough of the contract to open the sheet; nothing here installs anything.
final class _StubTemplateRepository implements DeckTemplateRepository {
  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) async => DeckTemplateInstallOutcome.installed;

  @override
  Future<Set<({String templateId, int version})>> installedTemplateKeys() =>
      Future<Set<({String templateId, int version})>>.value(
        const <({String templateId, int version})>{},
      );
}
