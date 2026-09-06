import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/card/data/datasources/card_transfer_resolver_data_source.dart';
import 'package:memox/features/card/di/card_import_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_transfer_failure.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/domain/repositories/card_import_repository.dart';
import 'package:memox/features/card/domain/repositories/card_import_source_repository.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_route_stub.dart';

/// `CardImportScreen` mounted whole, its three contracts faked (UC-10).
///
/// The wizard is live: choose Paste, type rows, walk Source → Preview →
/// Import and commit against the in-memory fake. The scenarios stage what
/// interaction alone cannot — a deck already holding duplicates, and a
/// source that refuses to parse.
WidgetbookComponent cardImportScreenComponent() {
  return WidgetbookComponent(
    name: 'CardImportScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<CardImportScenario>(
            label: 'scenario',
            options: CardImportScenario.values,
            labelBuilder: (CardImportScenario value) => value.label,
          );

          return _CardImportDemo(
            key: ValueKey<Object>(scenario),
            scenario: scenario,
          );
        },
      ),
    ],
  );
}

/// The states worth staging: a clean target, a target where every pasted row
/// is already present (BR-170), a source the decoder refuses (E1), and a
/// commit that fails and rolls back (state 8) — the one outcome interaction
/// alone cannot reach.
enum CardImportScenario {
  cleanDeck('empty-ish target deck'),
  duplicates('deck already holds the rows'),
  parseError('source refuses to parse'),
  commitFailure('commit fails and rolls back');

  const CardImportScenario(this.label);

  final String label;
}

/// The wizard's own deck, and the location the app opens the wizard at.
const String _catalogDeckId = 'catalog-deck';
const String _importLocation =
    '/decks/$_catalogDeckId/'
    '${RoutePaths.cardListRelative}/${RoutePaths.cardImportRelative}';

class _CardImportDemo extends StatefulWidget {
  const _CardImportDemo({required this.scenario, super.key});

  final CardImportScenario scenario;

  @override
  State<_CardImportDemo> createState() => _CardImportDemoState();
}

class _CardImportDemoState extends State<_CardImportDemo> {
  /// The card branch down to the wizard, so the screen's three ways out land
  /// somewhere instead of throwing.
  ///
  /// **The wizard is the app's most navigational screen and had no router at
  /// all.** The deck path leaves for the deck (SC-C4-07), its long-press sheet
  /// reaches any ancestor, `✕` pops or falls back to the deck, and
  /// `View cards` goes to the list — four controls, every one of them
  /// `goNamed`, every one of them throwing `GoError` in the catalogue.
  ///
  /// Nested exactly as `app_router.dart` nests it, so opening at
  /// [_importLocation] builds the deck and the card list underneath: `✕` finds
  /// something to pop, which is what it does in the app, rather than taking
  /// the no-history fallback that only exists for a deep link.
  late final GoRouter _router = GoRouter(
    initialLocation: _importLocation,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.decks,
        name: RouteNames.decks,
        builder: (BuildContext context, GoRouterState state) =>
            const CatalogRouteStubPage(routeName: 'Library'),
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.deckDetailRelative,
            name: RouteNames.deckDetail,
            builder: (BuildContext context, GoRouterState state) =>
                const CatalogRouteStubPage(routeName: 'Deck'),
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.cardListRelative,
                name: RouteNames.cardList,
                builder: (BuildContext context, GoRouterState state) =>
                    const CatalogRouteStubPage(routeName: 'Card list'),
                routes: <RouteBase>[
                  GoRoute(
                    path: RoutePaths.cardImportRelative,
                    name: RouteNames.cardImport,
                    builder: (BuildContext context, GoRouterState state) =>
                        CardImportScreen(
                          deckId: state.pathParameters[RoutePathParams.deckId]!,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    final importer = _CatalogImportRepository(
      existingKeys: scenario == CardImportScenario.duplicates
          ? <CardImportDuplicateKey>{
              cardImportDuplicateKey(frontFolded: '사과', backFolded: 'apple'),
              cardImportDuplicateKey(frontFolded: '바다', backFolded: 'sea'),
            }
          : <CardImportDuplicateKey>{},
      shouldFailCommit: scenario == CardImportScenario.commitFailure,
    );

    return ProviderScope(
      overrides: [
        cardRepositoryProvider.overrideWithValue(_CatalogCardRepository()),
        cardTransferRepositoryProvider.overrideWithValue(
          _CatalogTransferRepository(
            shouldFail: scenario == CardImportScenario.parseError,
          ),
        ),
        cardImportSourceRepositoryProvider.overrideWithValue(
          const _CatalogSourceRepository(),
        ),
        cardImportRepositoryProvider.overrideWithValue(importer),
      ],
      child: Router<Object>.withConfig(config: _router),
    );
  }
}

/// Only the two reads the wizard's context chip makes are real; the rest of
/// the wide CRUD contract is unreachable from this screen and answers with
/// [noSuchMethod] rather than thirty stub overrides.
final class _CatalogCardRepository implements CardRepository {
  @override
  Stream<DeckContextModel> watchDeckContext(String deckId) =>
      Stream<DeckContextModel>.value(
        const DeckContextModel(
          deckName: 'Korean · TOPIK I',
          ancestors: <DeckBreadcrumbSegment>[
            DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
            DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
          ],
        ),
      );

  @override
  Stream<int> watchCardCountByDeck(String deckId) => Stream<int>.value(142);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not catalog data');
}

final class _CatalogTransferRepository implements CardTransferRepository {
  const _CatalogTransferRepository({required this.shouldFail});

  final bool shouldFail;

  @override
  Future<CardTransferDocument> parse(CardTransferSource source) async {
    if (shouldFail) {
      throw const ValidationFailure(
        message: 'catalog: refused',
        problems: <Enum>{CardTransferProblem.invalidEncoding},
      );
    }

    return decodeCardTransferSource(source);
  }
}

final class _CatalogSourceRepository implements CardImportSourceRepository {
  const _CatalogSourceRepository();

  // The catalog runs on web where a real picker is available but pointless
  // for staged data; the pick simply cancels, steering the demo to Paste.
  @override
  Future<CardTransferFileSource?> pickFile() async => null;
}

final class _CatalogImportRepository implements CardImportRepository {
  _CatalogImportRepository({
    required this.existingKeys,
    this.shouldFailCommit = false,
  });

  final Set<CardImportDuplicateKey> existingKeys;
  final bool shouldFailCommit;

  @override
  Future<Set<CardImportDuplicateKey>> readExistingDuplicateKeys(
    String deckId,
  ) async => existingKeys;

  @override
  Future<CardImportResult> commitImport({
    required String deckId,
    required CardImportPlan plan,
  }) async {
    if (shouldFailCommit) {
      throw const DatabaseFailure(message: 'catalog: staged commit failure');
    }

    var imported = 0, skipped = 0;
    final seen = <CardImportDuplicateKey>{};
    for (final record in plan.records) {
      final key = record.duplicateKey;
      final isDuplicate = existingKeys.contains(key) || seen.contains(key);
      seen.add(key);
      if (isDuplicate && !plan.shouldIncludeDuplicates) {
        skipped += 1;
        continue;
      }
      imported += 1;
    }

    return CardImportResult(imported: imported, duplicatesSkipped: skipped);
  }
}
