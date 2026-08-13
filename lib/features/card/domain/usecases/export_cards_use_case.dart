import 'dart:typed_data';

import '../../../../core/error/failure.dart';
import '../failures/card_export_failure.dart';
import '../models/card_export_artifact_model.dart';
import '../models/card_export_file_name_model.dart';
import '../models/card_export_request_model.dart';
import '../models/card_export_result_model.dart';
import '../models/card_transfer_encoder_model.dart';
import '../repositories/card_export_destination_repository.dart';
import '../repositories/card_export_repository.dart';

/// Exports one deck's cards to a file and hands it to the OS (UC-11).
///
/// **One interaction, one use case** — read the snapshot, encode it, name it,
/// hand it over. The four steps are one user action, and splitting them across
/// a controller would put the ordering of a business flow into presentation,
/// where the retry path (UC-11 E2…E4) would then have to re-implement it.
///
/// The clock is injected rather than read: `clockProvider` owns "now" for the
/// whole tree, and nothing under `lib/features/` may reach for the ambient wall
/// clock (BR-180). Passing a function rather than a `DateTime` is deliberate —
/// the date the file is named for is the date the button was pressed, not the
/// date the provider graph was built.
///
/// Nothing here writes (BR-178) and nothing here logs: not the deck name, not
/// the file name, not a card (BR-51, BR-180).
final class ExportCardsUseCase {
  /// Named rather than positional: four collaborators of four different kinds
  /// read as four anonymous arguments at the wiring site otherwise. The fields
  /// stay private and Dart forbids a named parameter starting with an
  /// underscore, which is the whole reason for the ignores —
  /// `DeckRepositoryImpl` carries the same pair for the same reason.
  const ExportCardsUseCase({
    required CardExportRepository repository,
    required CardTransferEncoderResolver encoderFor,
    required CardExportDestinationRepository destination,
    required DateTime Function() clock,
    // ignore: prefer_initializing_formals
  }) : _repository = repository,
       // ignore: prefer_initializing_formals
       _encoderFor = encoderFor,
       // ignore: prefer_initializing_formals
       _destination = destination,
       // ignore: prefer_initializing_formals
       _clock = clock;

  final CardExportRepository _repository;
  final CardTransferEncoderResolver _encoderFor;
  final CardExportDestinationRepository _destination;
  final DateTime Function() _clock;

  /// Runs one export, or stops short of it.
  ///
  /// [isCancelled] is asked twice, and both places are load-bearing (UC-11 A5,
  /// wireframe M4.13 W4). W4 says `Cancel` closes the sheet **without creating
  /// a file**, and the sheet's `Cancel` stays live while an export is running —
  /// so a hand-off that went ahead anyway put a share sheet in front of a user
  /// who had already said no, for a file the app then never confirmed. Nothing
  /// here can un-hand a file, so the check has to sit *before* the hand-off;
  /// the earlier one only avoids encoding a deck nobody is waiting for.
  ///
  /// **Asked, not awaited.** A cancellation is a fact the caller already knows
  /// by the time this reads it — the sheet is gone, or its provider was
  /// disposed — so a callback is the whole mechanism, and there is no token
  /// type, no stream and nothing to dispose.
  ///
  /// A cancelled export is a [CardExportResult.dismissed]: no file, no error,
  /// and the sheet's own phase already treats that as back-to-initial. It is
  /// the same outcome as closing the OS share sheet, because from the user's
  /// side it is the same thing — they did not send anything.
  Future<CardExportResult> call(
    CardExportRequest request, {
    required bool Function() isCancelled,
  }) async {
    final snapshot = await _repository.readSnapshot(
      deckId: request.deckId,
      scope: request.scope,
    );
    if (isCancelled()) return CardExportResult.dismissed;
    // BR-174's floor, held above the repository as well as inside it: a deck
    // that emptied while the sheet was open reaches here with a valid request
    // and no rows, and a file holding nothing but six headers is not an
    // export the user asked for.
    if (snapshot.records.isEmpty) {
      throw const ValidationFailure(
        message: 'The export scope holds no cards.',
        problems: <Enum>{CardExportProblem.emptyScope},
      );
    }

    final artifact = CardExportArtifact(
      fileName: cardExportFileName(
        deckName: snapshot.deckName,
        format: request.format,
        date: _clock(),
      ),
      mimeType: request.format.mimeType,
      bytes: _encode(request, snapshot),
    );
    // The last moment the promise is still keepable. The artifact exists, but
    // only in memory and only in this app's own process — nothing has been
    // written anywhere and nothing has been offered to the OS, so dropping it
    // here is exactly "no file was created" (BR-181, M4.13 W4).
    if (isCancelled()) return CardExportResult.dismissed;

    return _destination.share(artifact);
  }

  /// Encoding failure is its own reason (UC-11 E4), distinguishable from a
  /// read failure so the copy and the retry advice can differ.
  ///
  /// `on Object` because the packages behind the encoders throw whatever they
  /// like — the XLSX decoder catches the same way and for the same reason. The
  /// error is carried on `cause` for the log rather than dropped, and nothing
  /// partial escapes: the artifact is not built at all if this throws.
  Uint8List _encode(CardExportRequest request, CardExportSnapshot snapshot) {
    try {
      return _encoderFor(request.format).encode(snapshot.records);
    } on Object catch (error) {
      throw ValidationFailure(
        message: 'The export file could not be encoded.',
        problems: const <Enum>{CardExportProblem.encodeFailed},
        cause: error,
      );
    }
  }
}
