/// Which cards the management list shows (D3 filter pills).
///
/// A filter narrows the `WHERE`, never the order or the window contract: the
/// list is still newest-first and re-read whole (C1, C2). Changing the filter
/// resets the window, because a window opened over 142 cards is meaningless over
/// the 23 that are due (§4.3).
///
/// [all] is the resting state. The other three each map to one indexed predicate
/// — `is_flagged` (BR-92), `review_count = 0` (BR-90), or the BR-22 due test —
/// which is why each has its own query rather than an `OR (:mode = …)` chain.
enum CardListFilter { all, dueNow, isNew, flagged }
