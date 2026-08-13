import 'card_transfer_field_model.dart';

/// The one tags-cell codec, shared by Import and Export (BR-176).
///
/// **One implementation on purpose.** A bare `split(';')` on the decode side
/// and a bare `join(';')` on the encode side agree on every happy path and
/// disagree on exactly the inputs that matter — a tag holding a `;` splits
/// into two tags on the way back in, which is data loss, not a formatting
/// difference. Two codecs cannot be kept in agreement by review, so there is
/// one, it lives beside the canonical schema it belongs to
/// (`card_transfer_field_model.dart`), and both directions call it.
///
/// The escape rules, stated once:
///
/// | on encode | becomes |
/// |---|---|
/// | `\` | `\\` |
/// | `;` | `\;` |
///
/// and on decode a backslash is an escape **only** when the next character is
/// [separator] or [escape]. A backslash before anything else — and a
/// backslash at the very end of the cell — is content and survives verbatim.
///
/// That asymmetry is deliberate and is what keeps legacy files importable:
/// every file written before this codec existed escaped nothing, so a cell
/// like `C:\path;note` must still decode to `C:\path` and `note` rather than
/// to one tag with a swallowed backslash.
abstract final class CardTransferTagCodec {
  /// What joins two tags in one cell (BR-169) — never a comma, which is a CSV
  /// delimiter and legal tag content.
  static const String separator = kCardTransferTagsSeparator;

  /// The escape introducer. It escapes itself, which is what makes the
  /// encoding reversible at all.
  static const String escape = r'\';

  /// Joins [tags] into one cell, escaping each name first.
  ///
  /// An empty [tags] gives an empty cell — BR-179's "optional field with no
  /// value is an empty cell", not a placeholder.
  static String encode(Iterable<String> tags) =>
      tags.map(_escapeTag).join(separator);

  /// Splits [cell] back into tag names, undoing [encode].
  ///
  /// Zero-length pieces are dropped: a trailing `;`, a leading `;` or a `;;`
  /// is spacing in a hand-written file, and an empty tag name cannot exist
  /// (BR-93 refuses it). Whitespace-only pieces are **kept** so the caller's
  /// own validation decides what they mean, exactly as it did before this
  /// codec existed.
  static List<String> decode(String cell) {
    final pieces = <String>[];
    final current = StringBuffer();

    var index = 0;
    while (index < cell.length) {
      final char = cell[index];
      final next = index + 1 < cell.length ? cell[index + 1] : null;

      final isEscapeSequence =
          char == escape && (next == separator || next == escape);
      if (isEscapeSequence) {
        current.write(next);
        index += 2;
        continue;
      }

      index += 1;
      if (char != separator) {
        current.write(char);
        continue;
      }

      _addPiece(pieces, current);
    }
    _addPiece(pieces, current);

    return pieces;
  }

  static void _addPiece(List<String> pieces, StringBuffer current) {
    final piece = current.toString();
    current.clear();
    if (piece.isEmpty) return;

    pieces.add(piece);
  }

  /// Backslashes first, then separators — the other order would escape the
  /// backslash this method just introduced and double it.
  static String _escapeTag(String tag) => tag
      .replaceAll(escape, '$escape$escape')
      .replaceAll(separator, '$escape$separator');
}
