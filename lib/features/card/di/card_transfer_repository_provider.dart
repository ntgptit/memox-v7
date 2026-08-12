import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/card_import_source_repository.dart';
import '../domain/repositories/card_transfer_repository.dart';

part 'card_transfer_repository_provider.g.dart';

/// The decode contract, declared here and bound at the composition root —
/// the same seam as `cardRepositoryProvider`. Separate from the commit
/// contract so a widget test fakes only the half it exercises.
@Riverpod(keepAlive: true)
CardTransferRepository cardTransferRepository(Ref ref) => throw StateError(
  'cardTransferRepositoryProvider was read without an override. The '
  'composition root binds it - see cardTransferRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);

/// The pick contract - the one platform seam the wizard needs.
@Riverpod(keepAlive: true)
CardImportSourceRepository cardImportSourceRepository(Ref ref) =>
    throw StateError(
      'cardImportSourceRepositoryProvider was read without an override. The '
      'composition root binds it - see cardImportSourceRepositoryBinding in '
      'app/di/repository_bindings.dart. A test must override it with a fake.',
    );
