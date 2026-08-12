# features/card

The second slice through the layering, and its job in this repo is different
from Deck's.

**Deck answers "what does a correct slice look like". Card answers "which parts
of that were the method, and which were Deck".** A single reference cannot tell
those apart — everything in it looks equally load-bearing. Card is the control
case: it was built to the same rules, ended up shaped differently in almost every
countable way, and is correct. AD-17 holds the rule; this file holds the
evidence.

So this is deliberately **not** a second copy of `deck/README.md`. Read that one
for how a slice works end to end, and `feature_blueprint.md` for the layout the
three enforcers actually accept. Read this one when you are about to bring
something across from Deck and want to know whether you have to.

---

## 1 · What business problem it owns

The flashcards inside one deck: their content, the list the user manages them
in, and the editor. UC-04, plus the flag and tag rules BR-92…BR-95 that arrived
after UC-04 was written.

What it does **not** own: the schedule (`card_review_states` belongs to Study),
the tree it sits in (Deck), and "due" (BR-22 — Card reads that definition, it
does not state it).

---

## 2 · Where it differs from Deck, and why each difference was right

Counted from the code, not remembered.

| | deck | card | What the difference means |
|---|---|---|---|
| `domain/repositories/` | 2 | **1** | Deck needs a second contract because starter templates are a separate source with a separate lifetime. One contract per *source of data*, not per feature. |
| `domain/entities/` | 2 | **6** | Card owns three entity types (card, review state, tag) against Deck's one. Entity count follows the domain, not a quota. |
| `domain/usecases/` | 14 | **21** | One per interaction, as AD-12 requires — and Card simply has more interactions. Neither number is a target. |
| `data/mappers/` | 3 | **7** | More row shapes crossing the boundary. A mapper per shape, not per feature. |
| `data/repositories/` | 4 | **2** | Deck splits its impl four ways; Card split once, when bulk management pushed the single file past the size guard. Splitting is a size response, not a rule. |
| `widgets/items/` | 7 | **1** | Deck's tile has a chip, a pill and a glyph as separate parts. Card's row does not. |
| `widgets/overlays/` | 8 | **2** | Deck is full of sheets, forms, confirm dialogs and a move picker; Card has the editor's danger zone and the bulk overlays. |
| `widgets/support/` | 1 | **4** | Reversed. Card has more cross-bucket display mapping. |
| dynamic SQL placeholders | **0** | 4 | Card's list statement composes filter + search + sort in one query; Deck's does not compose anything. |

**The bucket rows are the most useful ones.** `items/` 4→1, `overlays/` 5→1,
`support/` 1→3 — the four buckets are fixed by AD-15, but *which of them a feature
fills* is decided entirely by what it renders. A thin bucket is not an unfinished
feature, and Card proves it in three directions at once.

---

## 3 · What Card does not have, and did not need

Deck's most distinctive machinery is absent here and nothing suffered:

- **No tree.** No `parent_card_id`, no depth limit, no subtree traversal. Cards
  do not contain cards.
- **No `content_type`.** Nothing about a card settles what kind of thing it may
  hold next.
- **No scheduler columns.** Those live on the root deck (BR-06) and reach a card
  through `card_review_states`, which this feature reads and does not own.
- **No tree-shaped move.** A card *can* be moved now (BR-165), but the operation
  is a single `deck_id` write with two content-type consequences — not Deck's
  subtree relocation with its depth recount, root repointing and scheduler
  compatibility check. Same verb, an order of magnitude apart, and the second one
  was not copied over on the strength of the name.
- **`data/models/` empty**, same as Deck and for the same reason — the Drift row
  class is the data model, and AD-05 has no wire format yet.

If a third feature acquires any of the first four without its own reason, that is
the failure AD-17 names.

---

## 4 · What Card confirmed rather than invented

These came from Deck unchanged, which is what makes them method rather than
habit:

- **The dependency direction.** A controller calls a use case; it never reads a
  repository (AD-12).
- **One interaction is one read.** The card list gets its rows, its counts and
  its deck context from statements that arrive together, not from two subscriptions
  a controller composes (AD-13).
- **Validation lives in a value object.** `CardText` has a private constructor and
  a `parse` returning either the value or a typed problem, exactly as `DeckName`
  does — so the contract's signature answers "has this been validated?".
- **A failure carries its reason as a value.** `CardConflictReason`,
  `CardNotFoundReason`, `CardValidationProblem` are enums the UI matches on; no
  refusal is encoded in a message string.
- **Rules needing data *at the moment of writing* stay in the transaction.** The
  first-child lock that sets a deck's `content_type` when the first card is
  created runs inside `runInTransaction`, not in a use case above it — and so
  does every rule in BR-165, which is why `MoveCards` validates nothing before
  calling the use case.

---

## 5 · Where its business rules are

Content and validation: BR-07, BR-08 (front and back), BR-95 (the three optional
detail fields). Flag and tags: BR-92, BR-93, BR-94. Card states derived at read
time: BR-89…BR-91. Creation with its review state in one transaction: BR-09.
Editing never touching the schedule: BR-10. Moving a card within its own tree:
BR-165. Bulk writes are all-or-nothing and a selection is taken over the filtered
result: BR-166, BR-167.

`content_type` interactions — a card being the first child of an `unset` deck —
are BR-60…BR-66 and BR-163, and they belong to Deck; Card participates in that transaction but
does not state the rule.

**UC-04 is out of date against this feature** and is recorded as such in
`docs/master-flow.md` §6: it never mentions the flag or tags although BR-93 and
BR-95 both declare `Related: UC-04`. The reference is one-directional. Fixing it
means editing a `frozen for MVP` document and has not been done.

---

## 6 · Known gaps

- **Not in the Widgetbook catalog.** `widgetbook/lib/screens/` holds
  `DeckListScreen` only; `CardListScreen` and `CardEditorScreen` are absent,
  against the Definition of Done in `CLAUDE.md`. Card's screens are covered by
  the strict visual audit and by review renders in `test/demo/`, but not by the
  catalog.
