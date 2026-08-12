/// Why a transfer source was refused, as a value instead of a sentence
/// (BR-173, UC-10 E1/E2).
///
/// The idiom is `CardConflictReason`'s: the boundary throws a core `Failure`
/// carrying one of these, and the screen maps each to its own copy in an
/// exhaustive switch — `Failure.message` stays a sanitized diagnostic the UI
/// never renders, so a corrupt workbook can never surface a package's
/// exception text, a path, or a row of the user's data.
///
/// **Only outcomes the user can act on.** A bug in a decoder is a
/// `DatabaseFailure`-grade programming error, not a value here; every value
/// on this list has a recovery the Source step can print next to it.
enum CardTransferProblem {
  /// The picked file's extension resolves to no supported format. The system
  /// picker filters by type, but pickers on some providers ignore filters —
  /// so the extension is checked again on what actually came back.
  unsupportedFile,

  /// The bytes are not UTF-8 and not UTF-8 with a BOM — the only encodings
  /// v1 reads (BR-173). The copy tells the user to re-export as UTF-8 rather
  /// than letting a lossy guess import mojibake into their deck.
  invalidEncoding,

  /// The file or pasted text decodes but holds no data rows at all
  /// (UC-10 E2).
  emptySource,

  /// The chosen sheet has no data rows while other sheets do (UC-10 A2).
  emptySheet,

  /// The bytes could not be decoded as the format the extension claims —
  /// a corrupt workbook, a password-protected file, or text the CSV reader
  /// cannot make rows of. One value for all three because the packages
  /// cannot reliably tell them apart, and the recovery is the same:
  /// re-export.
  unreadableFile,
}
