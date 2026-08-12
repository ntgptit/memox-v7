import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
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
/// is already present (BR-170), and a source the decoder refuses (E1).
enum CardImportScenario {
  cleanDeck('empty-ish target deck'),
  duplicates('deck already holds the rows'),
  parseError('source refuses to parse');

  const CardImportScenario(this.label);

  final String label;
}

class _CardImportDemo extends StatelessWidget {
  const _CardImportDemo({required this.scenario, super.key});

  final CardImportScenario scenario;

  @override
  Widget build(BuildContext context) {
    final importer = _CatalogImportRepository(
      existingKeys: scenario == CardImportScenario.duplicates
          ? <String>{
              cardImportDuplicateKey(frontFolded: '사과', backFolded: 'apple'),
              cardImportDuplicateKey(frontFolded: '바다', backFolded: 'sea'),
            }
          : <String>{},
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
      child: const CardImportScreen(deckId: 'catalog-deck'),
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
  _CatalogImportRepository({required this.existingKeys});

  final Set<String> existingKeys;

  @override
  Future<Set<String>> readExistingDuplicateKeys(String deckId) async =>
      existingKeys;

  @override
  Future<CardImportResult> commitImport({
    required String deckId,
    required CardImportPlan plan,
  }) async {
    var imported = 0, skipped = 0;
    final seen = <String>{};
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
