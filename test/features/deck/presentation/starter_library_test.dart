import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/presentation/screens/starter_library_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

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
  }) async {
    final repository = _ScriptedTemplateRepository(
      installed: installed ?? <({String templateId, int version})>{},
      failWith: failWith,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckTemplateCatalogProvider.overrideWith(
            (ref) async => catalog ?? <DeckTemplate>[template()],
          ),
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
