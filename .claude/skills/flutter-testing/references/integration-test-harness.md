# The IT scenario suite — memox-specific knowledge

The 60 scenarios in `docs/it-scenarios/` run as `integration_test/it_*_test.dart`
on a real Android emulator, driven through the UI like a user. The generic craft
of driving `integration_test` (liveness, finder discipline, scrolling, IME,
clock ticks, classifying a red run) lives in the **global** `flutter-harness`
skill (its `e2e-driving.md` reference) — read that first. This file holds only what
is true of *this* app and would be wrong to generalize.

## Where things live

| Piece | File |
|---|---|
| Harness (db/clock seams, launch/restart, wipe, settle) | `integration_test/support/it_harness.dart` |
| Robot (user-level actions, `ItText` copy constants) | `integration_test/support/it_robot.dart` |
| Fixtures (S-DUE / S-PROGRESS / S-LARGE) | `integration_test/support/it_fixtures.dart` |
| Execution rules, setup recipes, fixture contract | `docs/it-scenarios/00-agent-execution-guide.md` |
| Status ledger per scenario | `docs/it-scenarios/scenario-catalog.md` |

Run one file at a time, watchdogged:

```bash
timeout 2100 flutter test integration_test/<file>.dart -d emulator-5554 \
  --flavor development --reporter expanded
```

Emulator: AVD `memox_it` (14G data partition, `-gpu host -memory 4096`).
App package for adb operations: `com.ntgptit.memox.dev` — never touch any
other package's data. Kill zombie runners with the whole tree
(`taskkill //F //IM dart.exe //T`) before a rerun; a TaskStop on the shell
alone leaves a runner that force-stops the app mid-way through the next run.

## The seam, and the mistake that hides it

Overrides (database, clock) are **parameters of `buildRootWidget`** — they must
live inside the app's own `ProviderScope`. Mounting an outer `ProviderScope`
with overrides above the app leaves the inner one un-overridden: every screen
renders its error state and the suite looks like a total product outage.

The harness clock starts frozen at `kT0` (2026-08-05T09:00+09:00). The robot
ticks it on every `createRootDeck`/`createSubDeck`/`createCard` (see
`ItHarness.tick`); scenarios needing specific instants call `setNow`. Never
create ordered content without distinct timestamps — `ORDER BY created_at
DESC, id DESC` tie-breaks on random UUIDs.

## App-specific driver rules

- **Deck names appear in up to three places at once** (row, breadcrumb,
  app-bar title). Always `openDeck` / `openDeckActions` (anchored to
  `DeckTileWidget`) for rows, `openCurrentDeckActions` for the app bar. A
  `.last` on the actions menu once hit the app bar and deleted the parent
  deck.
- **The breadcrumb is the sanctioned jump tool** (M4.10d) — but the card-list
  crumb shows only Root | parent | self, while the deck-level crumb has the
  full chain. Jumping to an arbitrary ancestor from a card list needs
  `pressBack` first.
- **Back from a card list lands on the deck level of the same deck**, not the
  parent — go_router does not re-run the redirect on pop (recorded product
  finding, deliberately not "fixed" in tests). One extra `pressBack`.
- **Deleting a deck lands on its parent** (#140); re-`openDeck` after.
- **Create actions shape-shift**: `Text` in the empty state, icon with
  `semanticLabel` once content exists — `tapCreateAction` handles both. An
  unset deck offers the "Add to this deck" ask-sheet (BR-61: both choices
  enabled).
- **Sheets/menus have no Cancel** (only the deck form does) — `dismissSheet()`.
- **Card list steady-state**: gate asserts behind `waitCardListSteady` (parses
  "Showing X of Y"); search is debounced 600ms.
- `mayOfferReset = !isRoot && decks.isEmpty` and the widget adds
  `contentType != unset`; the row menu never offers reset — only the app-bar
  menu does (that journey is IT-TREE-014).

## Fixture contract

Fixtures write through **real repositories** plus `CardDao.insertReviewState`
for promoted states (the scheduler is M5 and does not exist yet); every
promotion is guarded `changed == 1`. Loaders wipe first and are idempotent.
Content details are in the execution guide §6 — keep that section and
`it_fixtures.dart` in lockstep; the catalog row only says READY when the
loader actually runs.

## Defect classes this suite has caught (keep testing for them)

1. **Pass-through seam dropping optional params** — the card-list use case
   accepted `sort`/`searchTerm` and forwarded neither; symptom "Showing 3 of
   1". Locked by `watch_card_list_items_use_case_test.dart` with a
   parameter-recording fake. Any new use case with optional params gets the
   same lock.
2. **drift stream deps missing subquery-only tables** — see the project drift skill's
   `riverpod-drift.md` reference (the `cardListItems` case). Any query whose
   row content reads a table only via subquery needs a both-ways invalidation
   test at the repository level (`card_list_tag_invalidation_test.dart` is the
   template).
3. **Doc step silently skipped in the test** — ORG-009 shipped without the
   doc's >50-chars step. When writing a scenario test, diff its steps against
   the doc table line by line; asserting *less* than the doc is a quiet form
   of lowering the expected result.
