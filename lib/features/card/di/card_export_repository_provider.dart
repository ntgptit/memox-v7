import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models/card_transfer_encoder_model.dart';
import '../domain/repositories/card_export_destination_repository.dart';
import '../domain/repositories/card_export_repository.dart';

part 'card_export_repository_provider.g.dart';

/// The read contract of export, declared here and bound at the composition
/// root — the same seam as `cardImportRepositoryProvider`, and separate from
/// the destination for the reason AD-20 keeps the two contracts apart: a test
/// of the snapshot read should never have to fake a share sheet it does not
/// open.
@Riverpod(keepAlive: true)
CardExportRepository cardExportRepository(Ref ref) => throw StateError(
  'cardExportRepositoryProvider was read without an override. The composition '
  'root binds it - see cardExportRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);

/// The one platform seam of the export direction (BR-181) — the mirror of
/// `cardImportSourceRepositoryProvider`.
@Riverpod(keepAlive: true)
CardExportDestinationRepository cardExportDestinationRepository(Ref ref) =>
    throw StateError(
      'cardExportDestinationRepositoryProvider was read without an override. '
      'The composition root binds it - see '
      'cardExportDestinationRepositoryBinding in '
      'app/di/repository_bindings.dart. A test must override it with a fake.',
    );

/// How a format finds its encoder, as the **domain** typedef.
///
/// Declared as a contract rather than imported directly for the boundary AD-20
/// draws: the one `switch` over `CardTransferFormat` lives in the encoder
/// resolver in `data/`, and anything above the repository layer that imported
/// that file would be seeing the codec. Binding it at the root keeps the
/// dispatch in one place and still lets a test substitute an encoder that
/// throws, which is the only way to reach UC-11 E4.
@Riverpod(keepAlive: true)
CardTransferEncoderResolver cardTransferEncoderResolver(Ref ref) =>
    throw StateError(
      'cardTransferEncoderResolverProvider was read without an override. The '
      'composition root binds it - see cardTransferEncoderResolverBinding in '
      'app/di/repository_bindings.dart. A test must override it with a fake.',
    );
