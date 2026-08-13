import 'card_transfer_format_model.dart';

/// What the name part falls back to when the deck name sanitizes to nothing
/// (BR-180) — a deck called `///` is legal and must still produce a file.
const String kCardExportFallbackName = 'cards';

/// How long the name part may be before the date and extension are added.
///
/// BR-01 already caps a deck name at 200 characters, so this is not about
/// runaway input. It is about **bytes**: filesystem and share-target limits are
/// measured in bytes, and 200 Vietnamese or Korean characters are 600 bytes in
/// UTF-8 — comfortably past the 255-byte limit Android and Windows both apply.
/// Sixty characters keeps the worst case around 180 bytes with room for the
/// date and extension.
const int kCardExportNameMaxLength = 60;

/// Separates the name part from the date. An underscore rather than a space so
/// the date reads as a suffix rather than as part of the deck's name.
const String kCardExportNameDateSeparator = '_';

/// Characters a file name may not carry: path separators, the Windows-reserved
/// set, and the ASCII control range **except** the whitespace controls, which
/// the collapse below turns into a single space instead — a deck name pasted
/// with a line break reads as two words, not one run-on word.
///
/// Removed rather than replaced with `_`: a deck named `A/B` becoming `AB`
/// reads as a name, while `A_B` reads as a name the app chose to change.
final RegExp _invalidFileNameCharacters = RegExp(
  r'[\x00-\x08\x0E-\x1F\x7F/\\:*?"<>|]',
);

/// Runs of any whitespace — including the newline and tab a pasted deck name
/// can carry — collapse to a single space (BR-180). Applied **after** the
/// removal above, because removing a character can leave two spaces adjacent
/// that were not adjacent in the deck's name.
final RegExp _whitespaceRun = RegExp(r'\s+');

/// Leading and trailing dots. A name starting with one is hidden on POSIX, and
/// `.` and `..` are not names at all.
final RegExp _edgeDots = RegExp(r'^\.+|\.+$');

/// Derives the export file name (BR-180): sanitized deck name, a date, and the
/// format's extension.
///
/// [date] is passed in and never read from the wall clock — `clockProvider`
/// owns "now" for the whole tree, and an ambient read hidden in here would be a
/// second, unoverridable clock that only production ever sees. The caller
/// also decides the zone, because whether "today" means UTC or the device's
/// day is a composition-root question, not this function's.
///
/// The result is a name only: no directory, no path. It is never logged
/// (BR-180) — a deck name is card-adjacent private data (BR-51).
String cardExportFileName({
  required String deckName,
  required CardTransferFormat format,
  required DateTime date,
}) {
  final name = sanitizeCardExportName(deckName);
  final day = _isoDate(date);

  return '$name$kCardExportNameDateSeparator$day.${format.fileExtension}';
}

/// The name part alone (BR-180), so the rule can be tested without a date and
/// an extension in the way.
String sanitizeCardExportName(String deckName) {
  final stripped = deckName
      .replaceAll(_invalidFileNameCharacters, '')
      .replaceAll(_whitespaceRun, ' ')
      .trim()
      .replaceAll(_edgeDots, '')
      .trim();
  if (stripped.isEmpty) return kCardExportFallbackName;

  // Truncation can expose a space that used to be interior, so trim again —
  // and if the cut leaves nothing but spaces, fall back rather than emit a
  // file whose name is a space.
  final capped = stripped.length <= kCardExportNameMaxLength
      ? stripped
      : stripped.substring(0, _cutPointOf(stripped)).trim();
  if (capped.isEmpty) return kCardExportFallbackName;

  return capped;
}

/// Where [stripped] may be cut without splitting a character in half.
///
/// Dart measures a string in UTF-16 code units, and everything outside the BMP
/// — every emoji a deck name plausibly carries — spends two of them. Cutting
/// between the pair leaves a **lone surrogate**: not a character, not valid
/// UTF-8, and something the platform channel that receives this file name has
/// to encode. So the cut moves back one unit when it would land inside a pair,
/// which costs one character of an already arbitrary limit and cannot fail.
int _cutPointOf(String stripped) {
  const int highSurrogateStart = 0xD800;
  const int highSurrogateEnd = 0xDBFF;

  final last = stripped.codeUnitAt(kCardExportNameMaxLength - 1);
  final splitsAPair = last >= highSurrogateStart && last <= highSurrogateEnd;

  return splitsAPair ? kCardExportNameMaxLength - 1 : kCardExportNameMaxLength;
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${_twoDigits(date.month)}-${_twoDigits(date.day)}';

String _twoDigits(int part) => part.toString().padLeft(2, '0');
