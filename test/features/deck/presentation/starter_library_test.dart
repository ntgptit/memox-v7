import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/presentation/screens/starter_library_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_notice_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon.dart';

/// The starter catalog: what it discloses, and what installing from it does —
/// and refuses to do (UC-01, BR-33, BR-37, BR-87).
void main() {
  final english = AppLocalizationsEn();

  DeckTemplate template({String id = 'starter-1', int version = 1}) =>
      DeckTemplate(
        templateId: id,
        version: version,
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

  Future<_ScriptedTemplateRepository> pump(
    WidgetTester tester, {
    List<DeckTemplate>? catalog,
    Set<({String templateId, int version})>? installed,
    Object? failWith,
    Exception? catalogFailsWith,
  }) async {
    final repository = _ScriptedTemplateRepository(
      installed: installed ?? <({String templateId, int version})>{},
      failWith: failWith,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckTemplateCatalogProvider.overrideWith((ref) async {
            // The read failing, not the install: this is the branch the
            // screen's `MxErrorState` covers, and nothing in the app had ever
            // rendered it.
            if (catalogFailsWith != null) throw catalogFailsWith;

            return catalog ?? <DeckTemplate>[template()];
          }),
          deckTemplateRepositoryProvider.overrideWithValue(repository),
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
          home: const StarterLibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  testWidgets('a row discloses name, size, language, source and the fixture '
      'notice (BR-87)', (tester) async {
    await pump(tester);

    expect(find.text('Everyday English'), findsOneWidget);
    expect(
      find.textContaining(english.starterLibraryCardCount(1)),
      findsOneWidget,
    );
    expect(
      find.textContaining(english.starterLibraryLocaleLabel('en')),
      findsOneWidget,
    );
    // **The language, not its code.** The row used to read `Language: en` —
    // the schema's value shown to a reader on the first screen an empty
    // library is offered. The names are endonyms and stay untranslated, for
    // the reason `settingsLanguageEnglish` records.
    expect(english.starterLibraryLocaleLabel('en'), 'Language: English');
    expect(english.starterLibraryLocaleLabel('ko'), 'Language: 한국어');
    expect(english.starterLibraryLocaleLabel('vi'), 'Language: Tiếng Việt');
    // A template in a language nobody has named yet still says something.
    expect(english.starterLibraryLocaleLabel('ja'), 'Language: ja');
    expect(
      find.text(english.starterLibrarySource('memox-fixture')),
      findsOneWidget,
    );
    // Not production content, and the screen says so rather than implying it.
    expect(find.text(english.starterLibraryFixtureNotice), findsOneWidget);
  });

  testWidgets('installing: scheduler defaults from the template, one write, '
      'sheet closes', (tester) async {
    final repository = await pump(tester);

    await tester.tap(find.text('Everyday English'));
    await tester.pumpAndSettle();

    // The sheet asks the one question a copy needs (BR-34).
    expect(find.text(english.starterLibrarySchedulerPrompt), findsOneWidget);

    await tester.tap(find.text(english.starterLibraryInstallAction).last);
    await tester.pumpAndSettle();

    expect(repository.installs, hasLength(1));
    expect(repository.installs.single.schedulerType, SchedulerType.eightBox);
    expect(find.text(english.starterLibrarySchedulerPrompt), findsNothing);
  });

  testWidgets('cancelling the sheet installs nothing', (tester) async {
    final repository = await pump(tester);

    await tester.tap(find.text('Everyday English'));
    await tester.pumpAndSettle();
    // Swipe the sheet away rather than confirming.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(repository.installs, isEmpty);
  });

  group('an installed template (BR-37, BR-38)', () {
    testWidgets('cancelling the confirm copies nothing', (tester) async {
      final repository = await pump(
        tester,
        installed: <({String templateId, int version})>{
          (templateId: 'starter-1', version: 1),
        },
      );

      expect(find.text(english.starterLibraryInstalledLabel), findsOneWidget);

      await tester.tap(find.text('Everyday English'));
      await tester.pumpAndSettle();

      // The BR-38 confirm names the fact before anything can be made.
      expect(
        find.text(english.starterLibraryAlreadyInstalledTitle),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.installs, isEmpty);
    });

    testWidgets('confirming makes one deliberate duplicate', (tester) async {
      final repository = await pump(
        tester,
        installed: <({String templateId, int version})>{
          (templateId: 'starter-1', version: 1),
        },
      );

      await tester.tap(find.text('Everyday English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.starterLibraryAddAgainAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.starterLibraryInstallAction).last);
      await tester.pumpAndSettle();

      expect(repository.installs, hasLength(1));
      expect(repository.installs.single.allowDuplicate, isTrue);
    });
  });

  testWidgets('a failed install keeps the sheet, shows the failure, and '
      'retries into a second attempt', (tester) async {
    final repository = await pump(tester, failWith: Exception('disk full'));

    await tester.tap(find.text('Everyday English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.starterLibraryInstallAction).last);
    await tester.pumpAndSettle();

    // Nothing was copied (BR-39), the sheet stays, and the line says so.
    expect(find.text(english.starterLibraryInstallFailed), findsOneWidget);
    expect(find.text(english.starterLibrarySchedulerPrompt), findsOneWidget);

    repository.failWith = null;
    await tester.tap(find.text(english.starterLibraryInstallAction).last);
    await tester.pumpAndSettle();

    expect(repository.installs, hasLength(1));
    expect(find.text(english.starterLibrarySchedulerPrompt), findsNothing);
  });

  testWidgets('an empty manifest is a state, not an error', (tester) async {
    await pump(tester, catalog: <DeckTemplate>[]);

    expect(find.text(english.starterLibraryEmpty), findsOneWidget);
    // The heading names the situation, not the screen (SC-C3-02). Titled with
    // `starterLibraryTitle` it printed "Starter library" twice — once in the
    // bar, once over the empty face — and said nothing about the state.
    expect(find.text(english.starterLibraryEmptyTitle), findsOneWidget);
    expect(
      find.text(english.starterLibraryTitle),
      findsOneWidget,
      reason: 'the screen name belongs to the app bar and nowhere else here',
    );
  });

  /// The read failing, which is a different failure from an install failing.
  ///
  /// Nothing rendered this branch before (SC-C3-01): it passed `onRetry`
  /// without `retryLabel`, which `MxErrorState` asserts against and a release
  /// build answers by dropping the button — a failure the user can read and
  /// cannot act on.
  group('a catalog that cannot be read (SC-C3-01, SC-C3-02)', () {
    testWidgets('renders a retryable failure instead of an assertion', (
      tester,
    ) async {
      await pump(tester, catalogFailsWith: Exception('asset missing'));

      expect(
        tester.takeException(),
        isNull,
        reason:
            'the half-pair used to trip MxErrorState\'s assert and replace '
            'the whole screen with the error box',
      );
      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.retryAction), findsOneWidget);
    });

    testWidgets('the headline names the load, and no copy was claimed', (
      tester,
    ) async {
      await pump(tester, catalogFailsWith: Exception('asset missing'));

      expect(find.text(english.starterLibraryLoadErrorTitle), findsOneWidget);
      expect(find.text(english.starterLibraryLoadFailed), findsOneWidget);
      // The install copy belongs to the install sheet. On a failed read
      // nothing has been added, so "Nothing was copied" named an action the
      // user never took.
      expect(find.text(english.starterLibraryInstallFailed), findsNothing);
    });

    testWidgets('the retry re-reads the row model and says it is running', (
      tester,
    ) async {
      await pump(tester, catalogFailsWith: Exception('asset missing'));

      final retry = find.widgetWithText(MxActionButton, english.retryAction);
      expect(
        tester.widget<MxActionButton>(retry).isLoading,
        isFalse,
        reason: 'nothing is running before the tap',
      );

      await tester.tap(retry);
      // Exactly one frame, never `pumpAndSettle`. `invalidate` is a refresh
      // and `MxAsyncView` keeps the previous state through one, so the error
      // face is painted again unchanged — settling past it settles past the
      // whole gap this asserts.
      await tester.pump();

      // **This flag is the evidence the read restarted.** `isRetrying` is
      // `catalog.isRefreshing`, which only becomes true because the tap put
      // `starterLibraryProvider` back in flight; a tap that did nothing would
      // leave it false. Without it the face is repainted identically and the
      // user gets no evidence the app noticed.
      expect(
        tester.widget<MxActionButton>(retry).isLoading,
        isTrue,
        reason: 'the tap re-read the provider, and the button says so',
      );

      await tester.pumpAndSettle();
    });
  });

  /// The gutter is the list's, not the shell's — one edge for every mark.
  ///
  /// The screen used to keep `MxContentShell`'s static padding around a scroll
  /// view, which cost it both halves of this group: the rows clipped at a 16dp
  /// dead band under the bar instead of scrolling to the chrome edge, and every
  /// child that carried its own gutter paid it twice.
  group('gutter ownership', () {
    testWidgets('the list scrolls to the chrome edge', (tester) async {
      await pump(tester);

      final bar = tester.getRect(find.byType(AppBar));
      final scroll = tester.getRect(find.byType(Scrollable));

      expect(scroll.top, bar.bottom);
    });

    testWidgets('the notice starts on the card edge', (tester) async {
      await pump(tester);

      final glyph = tester.getRect(
        find.descendant(
          of: find.byType(DeckNoticeWidget),
          matching: find.byType(MxIcon),
        ),
      );
      final card = tester.getRect(find.byType(MxCard));

      expect(glyph.left, card.left);
    });
  });

  /// The catalog's vertical rhythm, measured (SC-C2-02).
  ///
  /// Nothing pinned these two gaps before, and the screen had drifted a full
  /// step below the app's grammar in both: `sm` (8) between two cards that
  /// each pad themselves `lg` (16), so the space *between* two rows was half
  /// the space *inside* one; and `md` (12) under the BR-87 notice, which is a
  /// break between two sections rather than a gap between two rows. Every
  /// value involved is a legitimate token, so only geometry after layout can
  /// tell either of them apart from the right one — hence `getRect`.
  group('list rhythm (SC-C2-02)', () {
    testWidgets('two template cards sit one list-item gap apart', (
      tester,
    ) async {
      await pump(
        tester,
        catalog: <DeckTemplate>[
          template(),
          template(id: 'starter-2'),
        ],
      );

      final first = tester.getRect(find.byType(MxCard).at(0));
      final second = tester.getRect(find.byType(MxCard).at(1));

      expect(
        second.top - first.bottom,
        AppSpacing.lg,
        reason:
            'two MxCard.raised rows are `lg` apart — the value '
            'deck_list_sliver_widget.dart settled on for the same row',
      );
    });

    testWidgets('the fixture notice is a section break, not another row', (
      tester,
    ) async {
      await pump(tester);

      final notice = tester.getRect(find.byType(DeckNoticeWidget));
      final card = tester.getRect(find.byType(MxCard));

      expect(
        card.top - notice.bottom,
        AppSpacing.xl,
        reason: 'the BR-87 notice heads the catalog rather than joining it',
      );
      // The point of the number, not the number itself: the notice has to be
      // further from the first card than two cards are from each other, or it
      // reads as one more thing in the list to tap.
      expect(card.top - notice.bottom, greaterThan(AppSpacing.lg));
    });
  });
}

/// Answers what the test scripted, and records every install it was asked for.
final class _ScriptedTemplateRepository implements DeckTemplateRepository {
  _ScriptedTemplateRepository({required this.installed, this.failWith});

  final Set<({String templateId, int version})> installed;
  Object? failWith;
  final List<
    ({String templateId, SchedulerType? schedulerType, bool allowDuplicate})
  >
  installs =
      <
        ({String templateId, SchedulerType? schedulerType, bool allowDuplicate})
      >[];

  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) async {
    final failure = failWith;
    if (failure != null) throw Exception('$failure');

    installs.add((
      templateId: template.templateId,
      schedulerType: schedulerType,
      allowDuplicate: allowDuplicate,
    ));

    return DeckTemplateInstallOutcome.installed;
  }

  @override
  Future<Set<({String templateId, int version})>> installedTemplateKeys() =>
      Future<Set<({String templateId, int version})>>.value(installed);
}
