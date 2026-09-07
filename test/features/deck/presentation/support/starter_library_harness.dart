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

/// The starter catalog on a scripted repository, in one place.
///
/// Two test files drive this screen — one asks what the catalog *discloses*
/// (rows, rhythm, a read that failed), the other what one install *finishes
/// as*. They were one file until it crossed the size guard, and the harness is
/// shared rather than copied because a second copy is how the two of them start
/// disagreeing about what the repository does.

/// The one catalog entry both files are built on: a single deck, a single card.
DeckTemplate fakeDeckTemplate({String id = 'starter-1', int version = 1}) =>
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

/// Mounts the screen and returns the repository, so a test can assert on what
/// was actually written as well as on what was rendered.
Future<ScriptedTemplateRepository> pumpStarterLibrary(
  WidgetTester tester, {
  List<DeckTemplate>? catalog,
  Set<({String templateId, int version})>? installed,
  Object? failWith,
  Exception? catalogFailsWith,
  DeckTemplateInstallOutcome outcome = DeckTemplateInstallOutcome.installed,
}) async {
  final repository = ScriptedTemplateRepository(
    installed: installed ?? <({String templateId, int version})>{},
    failWith: failWith,
    outcome: outcome,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deckTemplateCatalogProvider.overrideWith((ref) async {
          // The read failing, not the install: this is the branch the
          // screen's `MxErrorState` covers, and nothing in the app had ever
          // rendered it.
          if (catalogFailsWith != null) throw catalogFailsWith;

          return catalog ?? <DeckTemplate>[fakeDeckTemplate()];
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

/// Answers what the test scripted, and records every install it was asked for.
final class ScriptedTemplateRepository implements DeckTemplateRepository {
  ScriptedTemplateRepository({
    required this.installed,
    this.failWith,
    this.outcome = DeckTemplateInstallOutcome.installed,
  });

  /// What a completed install answers. `alreadyPresent` is the race BR-37's
  /// in-transaction check exists for: the row said the deck was not there
  /// and the database disagreed.
  final DeckTemplateInstallOutcome outcome;

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

    return outcome;
  }

  @override
  Future<Set<({String templateId, int version})>> installedTemplateKeys() =>
      Future<Set<({String templateId, int version})>>.value(installed);
}
