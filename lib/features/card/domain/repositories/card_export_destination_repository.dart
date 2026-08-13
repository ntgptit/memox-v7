import '../models/card_export_artifact_model.dart';
import '../models/card_export_result_model.dart';

/// The one platform seam the export direction has (BR-181) — the mirror of
/// `CardImportSourceRepository` on the import side.
///
/// Its own contract so the read and encode halves never see a plugin, and so a
/// headless test never has to open a system dialog it cannot close. Everything
/// platform-specific — writing the transient copy into the app's private area,
/// the plugin's file type, the channel exception — lives behind this one
/// method.
abstract interface class CardExportDestinationRepository {
  /// Hands [artifact] to the operating system's share sheet.
  ///
  /// Returns [CardExportResult.shared] when a destination was chosen and
  /// [CardExportResult.dismissed] when the user closed the sheet — dismissal
  /// is a **cancel**, not a failure, so it comes back as a value and not as a
  /// thrown failure (BR-181, UC-11 A3).
  ///
  /// Throws with `CardExportProblem.shareUnavailable` where the platform has
  /// no share sheet (UC-11 E1) and `sharePlatformError` when the channel
  /// itself fails (UC-11 E2). Neither message may carry the path, the file
  /// name or any card content.
  ///
  /// The implementation MUST NOT request broad storage permission and MUST NOT
  /// write anywhere outside the app's private area before the user has picked
  /// a destination (BR-181).
  Future<CardExportResult> share(CardExportArtifact artifact);
}
