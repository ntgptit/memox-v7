import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/card_import_repository_provider.dart';
import '../../di/card_transfer_repository_provider.dart';
import '../../domain/usecases/build_card_import_preview_use_case.dart';
import '../../domain/usecases/commit_card_import_use_case.dart';
import '../../domain/usecases/parse_card_transfer_use_case.dart';
import '../../domain/usecases/pick_card_import_source_use_case.dart';

part 'card_import_use_case_provider.g.dart';

/// The import use cases, wired to the import contract — dependency wiring
/// only, the same split `card_use_case_provider.dart` documents.
@riverpod
PickCardImportSourceUseCase pickCardImportSourceUseCase(Ref ref) =>
    PickCardImportSourceUseCase(ref.watch(cardImportSourceRepositoryProvider));

@riverpod
ParseCardTransferUseCase parseCardTransferUseCase(Ref ref) =>
    ParseCardTransferUseCase(ref.watch(cardTransferRepositoryProvider));

@riverpod
BuildCardImportPreviewUseCase buildCardImportPreviewUseCase(Ref ref) =>
    BuildCardImportPreviewUseCase(ref.watch(cardImportRepositoryProvider));

@riverpod
CommitCardImportUseCase commitCardImportUseCase(Ref ref) =>
    CommitCardImportUseCase(ref.watch(cardImportRepositoryProvider));
