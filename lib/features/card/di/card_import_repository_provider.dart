import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/card_import_repository.dart';

part 'card_import_repository_provider.g.dart';

/// The import contract this feature needs, declared here and bound at the
/// composition root — the same seam as `cardRepositoryProvider`, and a
/// separate one for the same reason the contract is separate: a widget test
/// of the card list should never have to fake a parser it does not call.
@Riverpod(keepAlive: true)
CardImportRepository cardImportRepository(Ref ref) => throw StateError(
  'cardImportRepositoryProvider was read without an override. The composition '
  'root binds it — see cardImportRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);
