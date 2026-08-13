/// Why an export was refused or could not finish, as a value instead of a
/// sentence (BR-174, BR-181, UC-11 E1…E6).
///
/// The idiom is `CardTransferProblem`'s, one layer over: the boundary throws a
/// core `Failure` carrying one of these, and the screen maps each to its own
/// copy in an exhaustive switch. `Failure.message` stays a sanitized
/// diagnostic the UI never renders — which matters more here than anywhere
/// else in the feature, because the things an export failure is tempted to
/// name are a file path, a file name and a card's content, and BR-180 and
/// BR-181 forbid all three from reaching a log, let alone a screen.
///
/// **Which `Failure` carries which value** is fixed, so the presentation
/// switch is written once and the data layer has no choice to make:
///
/// | value | carried by | slot |
/// |---|---|---|
/// | [emptyScope], [staleSelection] | `ValidationFailure` | `problems` |
/// | [deckMissing] | `NotFoundFailure` | `reason` |
/// | [readFailed] | `DatabaseFailure` | `reason` |
/// | [encodeFailed] | `ValidationFailure` | `problems` |
/// | [shareUnavailable], [sharePlatformError] | `UnknownFailure` | `reason` |
///
/// `problems` is a set because a request can be refused for a scope reason
/// *and* nothing else — it is the shape the wizard already switches on, and
/// reusing it means the export sheet does not invent a second one.
enum CardExportProblem {
  /// Nothing to export: the deck holds no cards, or the selection was empty
  /// (BR-174, UC-11 E5). Refused in the domain even though the entry point is
  /// hidden for an empty deck — the deck can empty itself between the sheet
  /// opening and the button being pressed, and a deep link never saw the
  /// entry point at all.
  emptyScope,

  /// A selected id no longer exists, or no longer belongs to this deck, at the
  /// moment the snapshot is read (BR-174, UC-11 E6). The **whole** request
  /// fails on it: a file quietly missing the cards the user picked is worse
  /// than no file, because nothing about it says anything is missing.
  staleSelection,

  /// The deck itself is gone (UC-11 E3). Distinct from [emptyScope]: an empty
  /// deck can be re-filled, a deleted one cannot, and the copy differs.
  deckMissing,

  /// The snapshot read failed (UC-11 E3). No file was produced and nothing was
  /// written — export is read-only (BR-178), so a failed read leaves nothing
  /// to undo.
  readFailed,

  /// The records could not be turned into bytes (UC-11 E4). Deliberately
  /// distinct from [readFailed]: the data was fine and the file was not, so
  /// "try again" is advice for one and not the other, and no partial artifact
  /// is ever handed on.
  encodeFailed,

  /// The platform has no share sheet (UC-11 E1). Not an error the user caused
  /// and not a retry — the sheet stays open with the scope and format intact.
  shareUnavailable,

  /// The platform channel threw while sharing (UC-11 E2). Retry keeps the
  /// scope and format; the message names neither the path nor the file.
  sharePlatformError,
}
