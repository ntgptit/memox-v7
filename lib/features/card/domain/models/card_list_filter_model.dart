/// Which cards the management list shows (D3 filter pills).
///
/// A filter narrows the `WHERE`, never the order or the window contract: the
/// list is still newest-first and re-read whole (C1, C2). Changing the filter
/// resets the window, because a window opened over 142 cards is meaningless over
/// the 23 that are due (§4.3).
///
/// [all] is the resting state. The other three each map to one indexed predicate
/// — `is_flagged` (BR-92), `review_count = 0` (BR-90), or the due test — which is
/// why each has its own query rather than an `OR (:mode = …)` chain.
///
/// **[due] and [isNew] never describe the same card.** [due] is BR-22's study
/// queue minus [isNew], so the two pills partition what a session would hand
/// over: `Due + New` is the queue exactly. It was the bare queue once, and a
/// deck holding one card that had never been opened showed `Due 1` beside
/// `New 1` — two counts for one card, and nothing in the row to say so. The
/// queue itself is unchanged and still takes new cards; see `duePredicate` in
/// `card_list_query_mapper.dart` for why the subtraction is structural.
enum CardListFilter { all, due, isNew, flagged }
