import 'dart:typed_data';

/// The finished file, before anything platform-specific touches it (BR-181).
///
/// **Bytes, a name and a type — and no plugin types, no `dart:io`, no
/// `XFile`.** The artifact crosses from the encoder to the platform seam, and
/// it is the last place both halves can still be tested without a device: the
/// moment a plugin's file handle appears on this class, every test that
/// produces one needs the plugin, and the domain has grown a dependency on
/// how the OS happens to accept a file this year.
///
/// It is also transient by contract. [bytes] live in app memory; whichever
/// adapter hands the file over writes it, if it must, only inside the app's
/// private area and never to shared storage before the user has chosen a
/// destination (BR-181). [fileName] is derived, never typed by the user
/// (BR-180), and — like card content — never logged at any level.
final class CardExportArtifact {
  const CardExportArtifact({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  /// Sanitized deck name + date + the format's extension (BR-180).
  final String fileName;

  /// The format's own declaration of what these bytes are.
  final String mimeType;

  final Uint8List bytes;
}
