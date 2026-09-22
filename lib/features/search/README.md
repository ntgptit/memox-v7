# features/search

Global Library Search (UC-20). Read `features/deck/README.md` first for the
method — this file only records what Search does differently and why.

## 1 · What business problem it owns

Finding a deck or a card **anywhere** in the library from one screen, without
browsing the tree, and jumping straight to it.

It owns nothing else. It reads deck and card data and writes none of it: there
is no `domain/failures/` directory in this feature at all, because the only
failure it can produce is a mapped database error.

The older per-deck card search (S1, M4.11) still exists and belongs to
`features/card` — this feature is the library-wide one that replaced
`SearchDecksUseCase` at M99.32.

## 2 · Public entry points

| Kind | Where to read it |
|---|---|
| Route | `RouteNames.librarySearch` |
| Screen | `LibrarySearchScreen` |
| Contract | `LibrarySearchRepository` (`domain/repositories/`) |
| Use case | `SearchLibraryUseCase` — one method, one page |
| Read models | the files in `domain/models/` |

## 3 · Data flow

```
keystroke → controller (debounce 250ms) → SearchLibraryUseCase
          → LibrarySearchRepository → LibrarySearchDao → search.drift → SQLite
```

Reads are one-shot `Future`s, not `watch()` streams — this is the first place
Search departs from Deck, and deliberately. A live stream per keystroke would
re-run the statement on every write anywhere in the library while the user is
still typing.

**Everything hangs off one decision: an empty query does no I/O.** The guard
exists three times — in the use case, in the repository, and in the controller —
and `search_zero_io_test.dart` asserts zero statements execute. Three guards for
one rule is not redundancy here: each layer can be entered independently, and the
cost of the rule failing is a statement per keystroke.

## 4 · Providers, by role

`presentation/providers/` holds wiring only. `LibrarySearchController` holds the
query, the debounce timer, the accumulated pages and the phase.

`LibrarySearchPhase` (`initial → debouncing → loading → ready | failed`) is UI
state, not a domain state machine. No entity this feature reads has states of
its own.

## 5 · Where the business rules are

BR-247…BR-255, and the ones that matter most are the ones that look like
implementation details and are not:

- **Folding is case-only, never diacritic-stripping** (BR-248, `core/text/search_fold.dart`).
  `công` does not match `cong`. That is a product decision, not a limitation —
  diacritic-insensitive search is S1's business, not this feature's.
- **Matching uses `instr()`, never `LIKE`** (`search.drift`). A `%` or `_` typed
  by a user is a character, not a wildcard.
- **A card's rank is the best tier across front, back and any matching tag**
  (BR-250). The Dart function and the SQL agree, and `search_rank_parity_test.dart`
  is what keeps them agreeing — two implementations of one ranking is the risk
  this feature accepted in exchange for ranking inside the statement.
- **A card with several matching tags is one row** (BR-252). The tag lookup is a
  correlated subquery precisely because a `JOIN` would duplicate the card once
  per tag.
- **Paging is a keyset cursor, never `OFFSET`** (BR-253). The cursor is a 4-tuple
  ending in `id` so the order is total; a write between two pages cannot repeat
  or skip a row.
- **Decks are exhausted before cards** (BR-251) — a paging rule and a display
  rule at once.
- **No FTS table, no new index, until `EXPLAIN QUERY PLAN` plus a benchmark says
  so** (BR-255). This is written into `search.drift` as a prohibition. It is the
  one rule here nothing enforces automatically.

## 6 · How errors are converted

There is no feature-specific `Failure`. A Drift error maps to a generic failure
at the repository boundary, and the widget **discards the message entirely**
(`presentation/widgets/.../library_search_body_widget.dart`) in favour of an ARB
string. The comment says why: a Drift message tells the user nothing actionable
and can carry card content.

First page fails → clear results, screen-level error, retry.
Later page fails → keep results, error on the footer only, retry just that page.
Those are different states on purpose; collapsing them throws away work the user
can still see.

## 7 · How to test it

`test/features/search/`. The two tests that carry weight:

- `search_zero_io_test.dart` — proves an empty/whitespace query runs no statement.
- `search_rank_parity_test.dart` — proves the Dart ranking function and the SQL
  ranking agree. Without it, the two drift and the list order changes depending
  on which one you read.

## 8 · Known gaps

- BR-255's prohibition is documentation only. Nothing fails if someone adds an
  index without measuring.
- Result tiles render card front/back into the accessibility tree. That is the
  same boundary as any on-screen card content, but it is worth knowing it is
  there.
