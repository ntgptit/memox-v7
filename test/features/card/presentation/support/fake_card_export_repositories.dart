import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_export_artifact_model.dart';
import 'package:memox/features/card/domain/models/card_export_result_model.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_encoder_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/repositories/card_export_destination_repository.dart';
import 'package:memox/features/card/domain/repositories/card_export_repository.dart';

/// The snapshot read, staged by hand. Records every scope it was asked for,
/// so a test can prove the sheet sent the scope its entry point promised.
final class FakeCardExportRepository implements CardExportRepository {
  FakeCardExportRepository({this.deckName = 'Korean · TOPIK I'});

  String deckName;
  List<CardTransferRecord> records = <CardTransferRecord>[];

  /// When set, the read throws it instead of answering (UC-11 E3).
  Failure? nextReadFailure;

  /// Holds the *read* open until completed.
  ///
  /// The counterpart of [FakeCardExportDestinationRepository.shareGate], and
  /// needed because that one parks too late: it opens inside the hand-off,
  /// which is past the point where a cancel can still stop anything. Parking
  /// here puts the pause where the user actually meets it — the sheet is
  /// generating and nothing has been encoded yet (M4.13 W4).
  Completer<void>? readGate;

  final List<CardExportScope> scopes = <CardExportScope>[];

  int get readCalls => scopes.length;

  @override
  Future<CardExportSnapshot> readSnapshot({
    required String deckId,
    required CardExportScope scope,
  }) async {
    scopes.add(scope);
    final gate = readGate;
    if (gate != null) await gate.future;

    final failure = nextReadFailure;
    if (failure != null) throw failure;

    return CardExportSnapshot(deckName: deckName, records: records);
  }
}

/// The one platform seam, without a platform: answers with whatever the test
/// staged, and can park mid-share so the generating face is observable.
final class FakeCardExportDestinationRepository
    implements CardExportDestinationRepository {
  CardExportResult resultToReturn = CardExportResult.shared;

  /// When set, the share throws it (UC-11 E1, E2).
  Failure? nextShareFailure;

  /// Holds the hand-off open until completed — how a test asserts the
  /// generating state and fires a second press while the first is in flight.
  Completer<void>? shareGate;

  final List<CardExportArtifact> artifacts = <CardExportArtifact>[];

  int get shareCalls => artifacts.length;

  @override
  Future<CardExportResult> share(CardExportArtifact artifact) async {
    artifacts.add(artifact);
    final gate = shareGate;
    if (gate != null) await gate.future;
    final failure = nextShareFailure;
    if (failure != null) throw failure;

    return resultToReturn;
  }
}

/// The encode half, faked at the resolver so no test needs a real codec.
///
/// Records every format asked for — which is how a test proves that picking
/// TSV actually reached the request rather than only the radio glyph.
final class FakeCardExportEncoders {
  final List<CardTransferFormat> formats = <CardTransferFormat>[];

  /// When true the encoder throws, which the use case maps to
  /// `CardExportProblem.encodeFailed` (UC-11 E4).
  bool shouldFailEncode = false;

  CardTransferEncoderResolver get resolver => _resolve;

  CardTransferEncoder _resolve(CardTransferFormat format) {
    formats.add(format);

    return _FakeEncoder(shouldFail: shouldFailEncode, format: format);
  }
}

final class _FakeEncoder implements CardTransferEncoder {
  const _FakeEncoder({required this.shouldFail, required this.format});

  final bool shouldFail;
  final CardTransferFormat format;

  @override
  Uint8List encode(List<CardTransferRecord> records) {
    // `on Object` in the use case catches whatever a real package throws; a
    // plain error is the honest stand-in for that.
    if (shouldFail) throw StateError('fake encoder refused');

    return Uint8List.fromList(
      utf8.encode('${format.fileExtension}:${records.length}'),
    );
  }
}
