/// Maps the domain's filter, search term and sort onto the `$predicate` and
/// `$order` the one list statement takes.
///
/// **One statement, composed here, instead of a query per filter × sort.** The
/// list read used to be four near-identical statements that differed only in a
/// `WHERE` line, and every change to the shared part — the tag `GROUP_CONCAT`,
/// then the sort — had to be made four times. That is the fragmentation this
/// file removes: the SELECT list, the join and the window live once in
/// `card.drift`, and what varies is assembled from named pieces below.
///
/// **The index objection that argued for separate statements does not apply.**
/// It was about an `OR (:mode = …)` chain inside a *static* query, which SQLite
/// cannot answer from `(deck_id, created_at, id)`. drift inlines a `$predicate`
/// as real SQL, so `all` emits `c.deck_id = ?` and `flagged` emits
/// `c.deck_id = ? AND c.is_flagged = 1` — the same text the separate statements
/// emitted, and the same plan.
///
/// **Each rule is a named function, not an inline expression.** "Due" is BR-22
/// and "new" is BR-90; naming them is what lets the list and the count share one
/// definition rather than two copies that can drift apart — which is exactly what
/// the four-statement version risked, and what `card_query_predicate_test.dart`
/// now pins.
library;

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_sort_model.dart';
import '../../domain/models/card_text_model.dart';

/// BR-22: a card is due when it has no scheduled date yet, or that date has
/// passed. The same predicate the review queue uses in `study.drift`.
Expression<bool> dueNowPredicate(CardReviewStates s, DateTime now) =>
    s.dueAt.isNull() | s.dueAt.isSmallerOrEqualValue(now);

/// BR-90: never reviewed.
Expression<bool> isNewPredicate(CardReviewStates s) => s.reviewCount.equals(0);

/// BR-92: the user's own mark.
Expression<bool> isFlaggedPredicate(Cards c) => c.isFlagged.equals(1);

/// Front or back contains [term], matched **literally** and case-insensitively
/// for every alphabet.
///
/// **`instr`, not `LIKE`, and that is what makes `%` an ordinary character.**
/// `LIKE` reads `%` and `_` in its pattern as wildcards, so a user searching
/// `100%` was really searching "100 followed by anything" and a lone `%` matched
/// the whole deck. Suppressing that needs a `LIKE … ESCAPE '\'` clause, which
/// drift's typed `like()` does not emit — and `CustomExpression` cannot bind a
/// variable, so writing the clause by hand would mean interpolating the user's
/// text into SQL. `instr(haystack, needle) > 0` has no pattern language at all:
/// every character is itself, and the term stays a bound variable.
///
/// **Both sides are folded in Dart, and no `lower()` appears in the SQL.** This
/// used to compare `instr(lower(front), :term)` with the term lowered by Dart —
/// two different folding rules on the two sides of one comparison. SQLite's
/// `lower()` covers ASCII only, so a card stored as `CÔNG NGHỆ` folded to
/// `cÔng nghệ` while the term `công nghệ` folded to itself, and the card could
/// not be found. The stored columns now carry the Dart-folded text
/// (`CardText.folded`) and the term goes through the same [CardText.fold], so
/// the two can no longer disagree.
///
/// Still a scan — no index serves "contains" — and still acceptable for the same
/// reason as before: the deck predicate has already narrowed it to one deck.
Expression<bool> searchPredicate(Cards c, String foldedTerm) =>
    _contains(c.frontFolded, foldedTerm) | _contains(c.backFolded, foldedTerm);

/// `instr(folded_column, ?) > 0`, with the needle already folded.
Expression<bool> _contains(GeneratedColumn<String> column, String foldedTerm) =>
    FunctionCallExpression<int>('instr', <Expression<Object>>[
      column,
      Variable<String>(foldedTerm),
    ]).isBiggerThanValue(0);

/// The whole `WHERE` for one list read: always the deck, plus the active filter,
/// plus the search term when there is one.
///
/// [now] is required only by [CardListFilter.dueNow] — the caller passes the
/// composition-root clock, and passing none for that filter is a programming
/// error the read surfaces rather than silently answering with the wrong "now".
Expression<bool> cardListPredicate({
  required Cards c,
  required CardReviewStates s,
  required String deckId,
  required CardListFilter filter,
  String? searchTerm,
  DateTime? now,
}) {
  var predicate = c.deckId.equals(deckId);

  predicate = switch (filter) {
    CardListFilter.all => predicate,
    CardListFilter.dueNow => predicate & dueNowPredicate(s, _requireNow(now)),
    CardListFilter.isNew => predicate & isNewPredicate(s),
    CardListFilter.flagged => predicate & isFlaggedPredicate(c),
  };

  // Folded through the same function the stored columns went through, so the
  // needle and the haystack cannot be folded by two different rules.
  final term = CardText.fold(searchTerm ?? '');
  if (term.isEmpty) return predicate;

  return predicate & searchPredicate(c, term);
}

DateTime _requireNow(DateTime? now) {
  if (now == null) throw ArgumentError.notNull('now');

  return now;
}

/// The `$order` term, built from the real columns so the emitted SQL is the text
/// a hand-written `ORDER BY` would produce — and the composite index still
/// supplies it. `id` breaks every tie, so re-reading a window cannot shuffle two
/// rows that share a timestamp.
OrderBy cardListOrder(
  CardListSort sort,
  Cards c,
  CardReviewStates s,
) => switch (sort) {
  CardListSort.newest => OrderBy(<OrderingTerm>[
    OrderingTerm.desc(c.createdAt),
    OrderingTerm.desc(c.id),
  ]),
  // NULL `due_at` is a new card — due now — and SQLite sorts NULLs first
  // ascending, so "soonest first" needs no COALESCE to put them at the front.
  CardListSort.dueFirst => OrderBy(<OrderingTerm>[
    OrderingTerm.asc(s.dueAt),
    OrderingTerm.desc(c.createdAt),
    OrderingTerm.desc(c.id),
  ]),
};
