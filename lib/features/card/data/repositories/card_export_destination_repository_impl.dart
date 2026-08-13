import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/failure.dart';
import '../../domain/failures/card_export_failure.dart';
import '../../domain/models/card_export_artifact_model.dart';
import '../../domain/models/card_export_result_model.dart';
import '../../domain/repositories/card_export_destination_repository.dart';

/// The one place the export direction touches the operating system (BR-181) —
/// the mirror of `CardImportSourceRepositoryImpl` on the import side, and the
/// **only** file in the app that imports `share_plus`.
///
/// `card_transfer_boundary_test.dart` pins that: the encoders, the read
/// repository, the use case and every widget must stay testable without a
/// device, and they stop being so the moment a plugin type appears in their
/// signatures.
///
/// **No `dart:io`, no path, no permission.** The artifact is handed over as
/// `XFile.fromData`, so the plugin writes the transient copy into the app's own
/// temporary area and names it from `fileNameOverrides`; the app never
/// constructs a path, never asks for storage access, and never writes to shared
/// storage before the user has chosen a destination. It also keeps the web
/// build compiling, because `dart:io` never enters the graph through this file.
///
/// Nothing here logs. The file name is derived from a deck name and the bytes
/// are card content, so both are private data at card-content level (BR-51,
/// BR-180, BR-181) and neither may reach a log line or a `Failure.message`.
final class CardExportDestinationRepositoryImpl
    implements CardExportDestinationRepository {
  /// [share] defaults to the plugin's own singleton and is injectable so a
  /// host test can fake the platform behind it — the four outcomes below are
  /// business rules, and a rule verified only on a device is a rule nobody
  /// re-verifies.
  const CardExportDestinationRepositoryImpl({SharePlus? share})
    // A named parameter can't start with `_`, so the formal is impossible.
    // ignore: prefer_initializing_formals
    : _share = share;

  final SharePlus? _share;

  @override
  Future<CardExportResult> share(CardExportArtifact artifact) async {
    final ShareResult result;
    try {
      result = await (_share ?? SharePlus.instance).share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              artifact.bytes,
              mimeType: artifact.mimeType,
              name: artifact.fileName,
            ),
          ],
          // `cross_file` ignores `XFile.name` everywhere except web, so the
          // override is what actually names the file the user receives
          // (BR-180). Without it the plugin invents one from the MIME type.
          fileNameOverrides: <String>[artifact.fileName],
          // Both web fallbacks off: a silent download or a mailto compose is a
          // destination the user did not pick, and BR-181 forbids claiming a
          // file went anywhere the OS did not confirm.
          downloadFallbackEnabled: false,
          mailToFallbackEnabled: false,
        ),
      );
    } on UnimplementedError catch (error) {
      // The platform has no share sheet for files at all (UC-11 E1) — the
      // desktop fallbacks throw this rather than returning a status.
      throw UnknownFailure(
        message: 'Sharing a file is not available on this platform.',
        reason: CardExportProblem.shareUnavailable,
        cause: error,
      );
    } on MissingPluginException catch (error) {
      // No implementation registered for this platform. Same user-facing
      // situation as above, and told apart from a channel that failed.
      throw UnknownFailure(
        message: 'Sharing a file is not available on this platform.',
        reason: CardExportProblem.shareUnavailable,
        cause: error,
      );
    } on Failure {
      rethrow;
    } on Object catch (error) {
      // A `PlatformException` from the channel, or anything else the plugin
      // chose to throw (UC-11 E2). The raw error carries the temporary path
      // and the file name, which BR-180 and BR-181 keep out of every message,
      // so only the typed reason travels — the original stays on `cause`, for
      // the log.
      throw UnknownFailure(
        message: 'The share sheet could not be opened.',
        reason: CardExportProblem.sharePlatformError,
        cause: error,
      );
    }

    return switch (result.status) {
      // The user closed the sheet without choosing. A **cancel**, returned as
      // a value rather than thrown (BR-181, UC-11 A3).
      ShareResultStatus.dismissed => CardExportResult.dismissed,
      // `success` is "a destination was chosen"; `unavailable` is the plugin's
      // name for "the sheet was shown and the platform cannot report what the
      // user did" — which is every Android build without result support, and
      // the web and desktop implementations. Both are *handed over*, and
      // `CardExportResult.shared` claims exactly that much and no more: where
      // the file went is not knowable from here (BR-181). Mapping
      // `unavailable` to `dismissed` would tell the user they cancelled
      // something they did not.
      ShareResultStatus.success ||
      ShareResultStatus.unavailable => CardExportResult.shared,
    };
  }
}
