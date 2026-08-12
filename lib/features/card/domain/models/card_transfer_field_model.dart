/// The canonical card-transfer schema (M99.19): the six fields a transfer
/// file carries, their stable order, their non-localized header spellings,
/// and the tags separator.
///
/// **This file is the schema's single home.** Import auto-maps against these
/// headers today; an export encoder writes them verbatim later. UI labels
/// localize — the file schema never does: a file exported by a Vietnamese
/// device must import on an English one without a mapping step, and that
/// only holds if the header identity lives outside every locale.
///
/// A transfer record deliberately carries **content only** — no card id, no
/// deck id, no timestamps, no scheduler, box, interval, due date, study
/// state or history. Export-then-import keeps content and tags but mints new
/// ids and fresh study state: this is content transfer, not a database
/// backup.
enum CardTransferField {
  front,
  back,
  example,
  hint,
  pronunciation,
  tags;

  /// The canonical, lowercase-English header for this field — what auto-map
  /// recognises and what a future encoder writes. Exactly the enum name
  /// today, and stated as a member so renaming an enum value cannot silently
  /// change the file contract.
  String get canonicalHeader => name;

  /// The spellings auto-map accepts besides [canonicalHeader] (UC-10 step
  /// 4): each alias names its field unambiguously, which is the bar for this
  /// list — a spelling two fields could plausibly claim maps a thousand rows
  /// backwards, so it stays off. Decode-side convenience only: an encoder
  /// writes [canonicalHeader] and nothing else.
  static const Map<String, CardTransferField> _aliases =
      <String, CardTransferField>{
        'term': CardTransferField.front,
        'word': CardTransferField.front,
        'question': CardTransferField.front,
        'meaning': CardTransferField.back,
        'definition': CardTransferField.back,
        'answer': CardTransferField.back,
        'sentence': CardTransferField.example,
        'examples': CardTransferField.example,
        'hints': CardTransferField.hint,
        'reading': CardTransferField.pronunciation,
        'tag': CardTransferField.tags,
        'label': CardTransferField.tags,
        'labels': CardTransferField.tags,
      };

  /// The field [header] names — canonical spelling or alias, case-insensitive
  /// — or null. The user can always remap what auto-map decided.
  static CardTransferField? fromHeader(String header) {
    final folded = header.trim().toLowerCase();
    for (final field in CardTransferField.values) {
      if (field.canonicalHeader == folded) return field;
    }

    return _aliases[folded];
  }
}

/// How multiple tags share one cell (BR-169): split and joined on `;`,
/// never a comma — a comma is a CSV delimiter and legal content.
const String kCardTransferTagsSeparator = ';';
