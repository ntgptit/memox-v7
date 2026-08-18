/// The one rule that decides whether two pieces of text are "the same" for
/// comparison and for search.
///
/// **In `core/` because four places already implement it and they must not
/// drift apart.** `CardText.folded` writes `cards.front_folded` /
/// `cards.back_folded`, `TagName.folded` writes `tags.name_folded`, the v2 → v3
/// migration backfills both, and Global Library Search folds the *query* before
/// comparing it with any of them. Those are the two sides of one comparison: the
/// moment one of them trims differently, or lowercases with a different rule,
/// a card stored as `CÔNG NGHỆ` stops being findable by typing `công nghệ` —
/// which is exactly the bug the folded columns were added to fix.
///
/// **Trim, then Dart's `toLowerCase()`, and no SQL equivalent is acceptable.**
/// SQLite's `lower()` and `COLLATE NOCASE` fold ASCII only, so they leave `Ô`,
/// `Ê` and `Đ` untouched. Dart's mapping is Unicode-aware, so folding both the
/// stored text and the search term here makes the comparison byte-for-byte and
/// correct for every alphabet the app admits.
///
/// **Case only — no diacritic stripping.** `công` does not match `cong`, exactly
/// as `Động từ` and `Dong tu` stay two different tags (BR-93). Diacritic-
/// insensitive search is a product decision, not a side effect of this function.
String foldForSearch(String raw) => raw.trim().toLowerCase();
