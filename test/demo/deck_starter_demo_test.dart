@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';

/// Device-faithful renders of the starter catalogue (UC-01) — the first screen
/// a user with an empty library is offered, and the only one in the deck
/// feature that had never been photographed at all.
///
/// It sits beside `deck_overlays_demo_test.dart` rather than inside it because
/// it needs a different seam faked: the template catalogue and the install
/// repository, not the deck repository.
void main() {
  DeckTemplate template({
    required String id,
    required String title,
    required String locale,
    required String source,
    int version = 1,
    int cardCount = 3,
  }) => DeckTemplate(
    templateId: id,
    version: version,
    locale: locale,
    title: DeckName.parse(title).name!,
    contentSource: source,
    defaultSchedulerType: SchedulerType.eightBox,
    children: <DeckTemplateNode>[
      DeckTemplateNode.leaf(
        name: DeckName.parse('Basics').name!,
        cards: <DeckTemplateCard>[
          for (var index = 0; index < cardCount; index++)
            DeckTemplateCard(
              front: CardText.parse('front $index', side: CardSide.front).text!,
              back: CardText.parse('back $index', side: CardSide.back).text!,
            ),
        ],
      ),
    ],
  );

  /// Three templates, one of them already installed — so the screen shows both
  /// of the states a catalogue row can be in (BR-37).
  List<DeckTemplate> catalogue() => <DeckTemplate>[
    template(
      id: 'starter-everyday',
      title: 'Everyday English',
      locale: 'en',
      source: 'memox',
      cardCount: 120,
    ),
    template(
      id: 'starter-topik',
      title: 'Korean · TOPIK I',
      locale: 'ko',
      source: 'memox',
      cardCount: 480,
    ),
    template(
      id: 'starter-ielts',
      title: 'IELTS Academic Word List',
      locale: 'en',
      source: 'memox',
      cardCount: 570,
    ),
  ];

  /// **Mounted through the router, not as a bare widget.** `/decks/starter`
  /// lives inside the Library branch precisely so the bottom bar stays and Back
  /// goes to the deck list (`route_paths.dart`). Pumping `StarterLibraryScreen`
  /// directly photographs it without either — which is the flaw the layout
  /// review already found in `study_home`, `progress_overview` and `settings`,
  /// and the reason their density and safe-area rows could not be scored.
  Widget scope(Brightness brightness) => ProviderScope(
    overrides: [
      envConfigProvider.overrideWithValue(EnvConfig.development),
      deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
      deckTemplateCatalogProvider.overrideWith((ref) async => catalogue()),
      deckTemplateRepositoryProvider.overrideWithValue(
        _DemoTemplateRepository(
          installed: const <({String templateId, int version})>{
            (templateId: 'starter-everyday', version: 1),
          },
        ),
      ),
    ],
    child: ReviewApp(
      // `/starter`, not `/decks/starter`: the path is relative to the
      // Library branch root, which is `/` (`route_paths.dart`).
      home: deckRouterAt('/starter'),
      brightness: brightness,
    ),
  );

  testWidgets('starter library — the catalogue, light', (tester) async {
    await pumpReview(tester, scope(Brightness.light));

    await matchesReviewGolden('goldens/deck_starter_library_light.png');
  });

  testWidgets('starter library — the catalogue, dark', (tester) async {
    await pumpReview(tester, scope(Brightness.dark));

    await matchesReviewGolden('goldens/deck_starter_library_dark.png');
  });
}

/// Installs nothing and reports one template already installed.
final class _DemoTemplateRepository implements DeckTemplateRepository {
  _DemoTemplateRepository({required this.installed});

  final Set<({String templateId, int version})> installed;

  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) async => DeckTemplateInstallOutcome.installed;

  @override
  Future<Set<({String templateId, int version})>> installedTemplateKeys() =>
      Future<Set<({String templateId, int version})>>.value(installed);
}
