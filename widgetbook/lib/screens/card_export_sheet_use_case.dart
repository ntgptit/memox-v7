import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/data/datasources/card_transfer_encoder_resolver_data_source.dart';
import 'package:memox/features/card/di/card_export_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_export_artifact_model.dart';
import 'package:memox/features/card/domain/models/card_export_result_model.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_encoder_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/card_export_destination_repository.dart';
import 'package:memox/features/card/domain/repositories/card_export_repository.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:widgetbook/widgetbook.dart';

/// The export sheet (UC-11, M4.13), opened for real over a host screen.
///
/// **Opened rather than inlined.** The drag handle, the surface, the radius
/// and the scrim all come from `bottomSheetTheme` via `showModalBottomSheet`;
/// a sheet rendered as a plain panel would be judged without any of them.
///
/// The scenario knob stages what interaction alone cannot reach — the four
/// failure faces and a dismissed share sheet. Everything else is live: pick a
/// format, press Export, watch the state the scenario produces.
WidgetbookComponent cardExportSheetComponent() {
  return WidgetbookComponent(
    name: 'CardExportSheet',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<CardExportScenario>(
            label: 'scenario',
            options: CardExportScenario.values,
            labelBuilder: (CardExportScenario value) => value.label,
          );
          final isSelection = context.knobs.boolean(label: 'selection scope');

          return _CardExportDemo(
            key: ValueKey<Object>((scenario, isSelection)),
            scenario: scenario,
            isSelection: isSelection,
          );
        },
      ),
    ],
  );
}

/// The outcomes worth staging: the OS taking the file, the OS sheet being
/// dismissed (a cancel, not an error), and each typed refusal UC-11 names.
enum CardExportScenario {
  shared('the system takes the file'),
  dismissed('share sheet dismissed (a cancel)'),
  shareUnavailable('no share sheet on this device (E1)'),
  readFailed('reading the cards fails (E3)'),
  encodeFailed('building the file fails (E4)'),
  staleSelection('a picked card is gone (E6)');

  const CardExportScenario(this.label);

  final String label;
}

class _CardExportDemo extends StatelessWidget {
  const _CardExportDemo({
    required this.scenario,
    required this.isSelection,
    super.key,
  });

  final CardExportScenario scenario;
  final bool isSelection;

  static const int _deckCardCount = 128;
  static const Set<String> _selectedIds = <String>{'c1', 'c2', 'c3'};

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        cardExportRepositoryProvider.overrideWithValue(
          _CatalogExportRepository(scenario: scenario),
        ),
        cardExportDestinationRepositoryProvider.overrideWithValue(
          _CatalogDestinationRepository(scenario: scenario),
        ),
        // The real resolver: the catalog encodes with the production encoders,
        // so a format that cannot be built shows up here rather than only in
        // a test.
        cardTransferEncoderResolverProvider.overrideWithValue(
          scenario == CardExportScenario.encodeFailed
              ? _refuseToEncode
              : cardTransferEncoderFor,
        ),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 13)),
      ],
      child: _Host(
        scope: isSelection
            ? CardExportSelectionScope(_selectedIds)
            : const CardExportWholeDeckScope(),
      ),
    );
  }
}

/// The encode failure (UC-11 E4), which no interaction can reach: a real
/// encoder either works for every record or is broken for all of them.
CardTransferEncoder _refuseToEncode(CardTransferFormat format) =>
    throw StateError('catalog: staged encode failure');

class _Host extends StatelessWidget {
  const _Host({required this.scope});

  final CardExportScope scope;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showCardExportSheet(
            context,
            deckId: 'catalog-deck',
            scope: scope,
            deckCardCount: _CardExportDemo._deckCardCount,
          ),
          child: const Text('Open the export sheet'),
        ),
      ),
    );
  }
}

final class _CatalogExportRepository implements CardExportRepository {
  const _CatalogExportRepository({required this.scenario});

  final CardExportScenario scenario;

  @override
  Future<CardExportSnapshot> readSnapshot({
    required String deckId,
    required CardExportScope scope,
  }) async {
    if (scenario == CardExportScenario.readFailed) {
      throw const DatabaseFailure(
        message: 'catalog: staged read failure',
        reason: CardExportProblem.readFailed,
      );
    }
    if (scenario == CardExportScenario.staleSelection) {
      throw const ValidationFailure(
        message: 'catalog: staged stale id',
        problems: <Enum>{CardExportProblem.staleSelection},
      );
    }

    return CardExportSnapshot(
      deckName: 'Korean · TOPIK I',
      records: <CardTransferRecord>[_record],
    );
  }
}

final class _CatalogDestinationRepository
    implements CardExportDestinationRepository {
  const _CatalogDestinationRepository({required this.scenario});

  final CardExportScenario scenario;

  @override
  Future<CardExportResult> share(CardExportArtifact artifact) async {
    if (scenario == CardExportScenario.shareUnavailable) {
      throw const UnknownFailure(
        message: 'catalog: no share sheet',
        reason: CardExportProblem.shareUnavailable,
      );
    }

    return scenario == CardExportScenario.dismissed
        ? CardExportResult.dismissed
        : CardExportResult.shared;
  }
}

/// One canonical record, built through the value objects a real card is built
/// through — a catalog fixture that could not exist as a card is not a
/// fixture, it is a lie about the pipeline.
final CardTransferRecord _record = () {
  final sides = parseCardSides(rawFront: '사과', rawBack: 'apple');

  return CardTransferRecord(
    front: sides.front,
    back: sides.back,
    tags: <TagName>[TagName.parse('fruit').name!],
  );
}();
