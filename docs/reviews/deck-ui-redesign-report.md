# Deck UI Redesign Report

## Base / final commit

| | |
|---|---|
| Base | `3e35aac` (`main`) |
| Baseline | `flutter analyze` clean · 485 targeted tests · 88 goldens |
| Final | 519 targeted tests · 88 goldens · 880 total · analyze clean · every guard clean |

The reference images were used for **composition and hierarchy only**. Not one
colour, size or control was copied from them; every value below resolves to a
token that already existed.

---

## Existing design-system audit

Run before any code was written. The finding that shaped everything else: the
MemoX palette already matches the reference's *structure*, so **no new colour
token was needed**. `backgroundLight #F4F5F8` is already a soft off-white rather
than flat white; `surfaceDark #1B1D32` already sits a clear step above
`backgroundDark #0A082D`; `success` / `warning` / `info` already exist for exactly
the up-to-date / due / new states the reference colours by hand.

| Need | Existing token / widget | Decision |
|---|---|---|
| Screen scaffold | `MxContentShell` | **extended** — `floatingActionButton` passthrough |
| Header | `MxContentShell`'s AppBar | reused — no new shell, no new nav |
| Card surface | `MxCard` (surface + `AppRadius.lg` + `borderSubtle`, unshadowed) | **extended** — optional `onTap` |
| Pill control | *nothing equivalent* | **created** — `MxPillButton` |
| Icon well | *nothing equivalent, 1 caller* | feature-local `DeckIconArea` |
| Icon button | `MxIconButton` | reused |
| FAB | *nothing shared* | Flutter `FloatingActionButton` + new `floatingActionButtonTheme` |
| Empty state | `MxEmptyState` | reused |
| Loading state | `MxLoadingState` via `MxAsyncView` | reused |
| Error state | `MxErrorState` | reused |
| Dialog / form / sheet | `MxConfirmDialog`, `MxActionSheet`, `MxTextField`, `MxActionButton` | reused unchanged |
| Spacing | `AppSpacing` (4/8/12/16/24/32, `minimumTouchTarget` 48) | reused, none added |
| Radius | `AppRadius` (8/12/16/pill) | reused, none added |
| Typography | `AppTypography` via `context.texts` | reused, none added |
| Semantic colours | `AppSemanticColors` + `ColorScheme` | reused, none added |

---

## Files changed

### Reused shared widgets

`MxEmptyState` · `MxErrorState` · `MxLoadingState` · `MxAsyncView` ·
`MxIconButton` · `MxActionButton` · `MxActionSheet` · `MxConfirmDialog` ·
`MxTextField` — all unchanged.

### Extended shared widgets

- `lib/shared/widgets/mx_card.dart` — optional `onTap`. Generic: any card standing
  for a thing the user can open wants it, and hand-rolling the ink per call site
  is how two call sites end up with different splash radii. The ripple clips to
  the same `AppRadius.lg` the border uses; with `onTap` null the card is
  byte-identical to before.
- `lib/shared/widgets/mx_content_shell.dart` — `floatingActionButton`
  passthrough. The `Scaffold` is what keeps a floating action clear of the system
  gesture inset and the navigation bar; a screen positioning its own would
  re-derive both and get them wrong on the first device with a different inset.

Neither knows anything about Deck.

### New shared widgets

- `lib/shared/widgets/mx_pill_button.dart`

  **Callers (2, both real):** the deck list's filter pill and its sort pill.

  **Why the repository had no equivalent:** `MxActionButton` *performs*
  something — its variant ladder is built around primary/destructive intent and
  it has no selected state, because a button that stays pressed is a different
  idea. `MxIconButton` has no label. `MxListTile` is a row, not an inline
  control. Nothing in `shared/widgets/` expressed "one of N, and you can see
  which".

  It wraps `ChoiceChip`, the same way `MxActionButton` wraps `FilledButton` and
  `MxIconButton` wraps `IconButton` — Material already owns the selection
  semantics a screen reader needs.

### Feature-local widgets

- `lib/features/deck/presentation/widgets/deck_tile_widget.dart` — `DeckTileWidget`
  rebuilt on `MxCard`; `DeckIconArea` added; `DeckChildTileWidget` brought onto the
  same card.
- `lib/features/deck/presentation/widgets/deck_list_toolbar_widget.dart` — new.
  Speaks `DeckListFilter` / `DeckListSort`, so it stays in the feature.

All three take Deck models. None was a candidate for `shared/`.

### Screens

- `root_deck_list_screen.dart` — header, toolbar, card rhythm, FAB, list inset.
- `deck_detail_screen.dart` — child list given the same card rhythm; create moved
  from an app-bar icon to a floating action, so the same kind of action is
  presented the same way on both screens. Conditional, because the action is: a
  `card` deck holds no sub-decks (BR-63), and a button that appears only when it
  applies is honest where a permanently disabled one is not.

### State / controllers

- `states/deck_list_view_state.dart` — `DeckListFilter`, `DeckListSort`, and the
  pure `applyDeckListView`.
- `controllers/deck_list_view_controller.dart` — two input-state notifiers.

### Theme

- `core/theme/app_theme.dart` — `chipTheme`, `floatingActionButtonTheme`.
- `core/theme/app_button_themes.dart` — **new file**, the button themes split out
  when `app_theme.dart` crossed the 400-line guard my additions pushed it over.

### Tests / goldens

New: `mx_pill_button_test.dart` · `mx_card_test.dart` · `deck_list_view_test.dart` ·
`deck_list_toolbar_test.dart`.
Updated: `mx_stress_specimens.dart` · `mx_surface_components_test.dart` ·
`app_navigation_shell_test.dart` · `root_deck_list_screen_test.dart` ·
`deck_audit_allowances.dart` and both visual-audit companions.

**No golden image was updated.** The 88 goldens pass unchanged — the deck screens
are covered by strict visual audits rather than pixel goldens, and the design
previews are separate mock explorations this work did not touch.

---

## Design decisions

**Reference principles adopted**

- header, then a pill toolbar, then a list of cards
- a card per deck, with the glyph in its own tinted well on the left
- three levels of type: name, then counts + state, then the quietest fact
- state carried by colour — amber due, green up to date
- create as a floating action rather than an app-bar icon
- generous, even vertical rhythm

**Existing MemoX conventions preserved**

- **Cards stay unshadowed.** The reference uses soft drop shadows; this app
  separates surfaces with a colour step and a hairline border, stated in
  `app_theme.dart` as "the page sits a step below the card, so a card reads as a
  card without needing a shadow to say so". Copying the shadow would have been
  copying a look over a rule.
- **Card radius stays `AppRadius.lg` (16).** The brief's target is 20–24. §10
  says to keep the existing token when it is close, and 16 is what every other
  panel in the app uses. Adding an `AppRadius.xl` would have made the deck card
  the only panel in the app with its own corner.
- **Icon well is 48, not 56** — `AppSpacing.minimumTouchTarget`, the number the
  row's real controls already use, which keeps icon, title and action optically
  aligned.
- **The app bar and navigation shell are untouched.** No new shell, no new bottom
  bar.

**Reference elements not copied, and why**

| Element | Why not |
|---|---|
| Search field | No search exists. A live-looking control that does nothing teaches the user to distrust the row. |
| Profile avatar | No profile, no account. |
| Lightning "study" button per row | The real right-hand action is the deck's action menu. Swapping the glyph would have made it look like a different, unbuilt feature. |
| Four-tab bottom bar (Today / Library / Stats / Profile) | This app has two branches. Inventing two more is inventing navigation. |
| Per-deck topic icons | Would need a database field. The glyph is derived from data that exists: a bell when cards are due, a folder otherwise. |
| The reference's specific purples | Every colour came from the existing palette. |

**Filter and sort are real.** The brief forbids dead controls and lists a toolbar
in scope; the only reading that satisfies both is to implement them. They operate
on the snapshot already in memory — no query, no repository change, no business
rule. And the toolbar **only renders when there are decks**: with an empty
library there is nothing to filter or order, so the pills would be exactly the
dead controls the reference was not copied for.

Defaults were chosen so the first frame after this landed looked like the last
frame before it: `all` is the repository's whole result and `recent` is its own
order.

---

## Token changes

**Existing tokens reused:** `AppSpacing.{xs,sm,md,lg}`, `AppSpacing.minimumTouchTarget`,
`AppRadius.{md,lg,pill}`, `AppIconSize.{sm,md}`, `AppSemanticColors.{success,warning}`,
`ColorScheme.{surface,primaryContainer,onPrimaryContainer,secondaryContainer,onSecondaryContainer,onSurfaceVariant,primary,onPrimary}`,
and the `titleMedium` / `bodySmall` / `labelSmall` / `labelLarge` text roles.

**New tokens: none.** Two *component themes* were added — `chipTheme` and
`floatingActionButtonTheme` — but both are compositions of existing colour
tokens, and both were added only because a screen now renders those components.
That is the rule `app_theme.dart` already states for itself.

**Literals used, and why:** one, `_kFabDiameter = 56` in
`root_deck_list_screen.dart`. It is Material's own FAB diameter, used to derive
the list's bottom inset (`56 + 16 + 16`). It is named rather than inlined so the
sum can be checked by eye. A token would be wrong: it is not a MemoX design
decision, it is a fact about the framework component.

---

## Visual verification

Rendered through the real router at 390×844 and 320×568, at text scale 1.0 and
2.0, in both themes.

| State | Light | Dark | Result |
|---|---|---|---|
| Loaded | ✓ | ✓ | Even card rhythm, 3-level hierarchy, state in colour |
| Empty (no decks) | ✓ | ✓ | No toolbar — nothing to act on |
| Empty (filter matched none) | ✓ | ✓ | Toolbar kept; its own copy and its own way back |
| Loading | ✓ | ✓ | Shared `MxLoadingState`, unchanged |
| Error | ✓ | ✓ | Shared `MxErrorState`, retry only |
| Long deck name | ✓ | ✓ | Wraps to 2 lines then ellipsises; icon and action stay anchored to line 1 |
| Due | ✓ | ✓ | Bell glyph + `warning` colour + the words — three carriers, never colour alone |
| Up to date | ✓ | ✓ | Folder glyph + `success` colour + the words |
| 320×568 | ✓ | ✓ | No overflow |
| 320×568 @ 2.0 | ✓ | ✓ | No overflow; pills stack, meta ellipsises |

---

## Commands

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | clean |
| `flutter analyze --no-fatal-infos` | No issues found |
| `flutter test --exclude-tags golden test/app test/features/deck test/shared` | **519 passed** (485 before) |
| `flutter test --tags golden` | **88 passed**, none updated |
| `flutter test` | **880 passed** |
| `check_architecture.sh` | clean — 114 files scanned |
| code verification guard | 0 violations, 66 rules |
| `check_docs.sh` | clean |
| `check_generated.sh` (full, with rebuild comparison) | clean — 111 sources, 21 parts, 21 generated files byte-identical on a clean rebuild |
| Visual audits (12 states) | all PASS, **0 blocking** |
| Sheets and detail screen rendered and checked | create form ✓ · actions sheet ✓ · move sheet ✓ (kept) · detail ✗→fixed |

---

## Visual refinement

Two rounds, both driven by looking at rendered output rather than at the code.

### Round 1 — after the first render

1. **The metadata line was over-stuffed.** "486 cards · 48 cards due · Eight
   boxes" wrapped on *every* card at 390 wide, so no two cards were the same
   height and the list had no rhythm; at 320 @ 2.0 the scheduler was cut to
   "Eigh…". Fixed by giving the scheduler its own line as the third and quietest
   level — a deliberate hierarchy instead of an accidental wrap.
2. **The icon well floated mid-card** whenever the name wrapped, leaving the row
   unreadable left-to-right. Both edges now anchor to the first line
   (`CrossAxisAlignment.start`).
3. **The action button drifted the same way** — same fix.

### Round 2 — after the second render

4. **The toolbar was a dead control on the empty screen.** With no decks, the
   filter and sort pills did visibly nothing — the exact defect the reference's
   search and avatar were rejected for. The toolbar moved inside the loaded
   branch, so it exists only when there is something to act on. `_RootDeckList`
   lost a parameter as a result: the "no decks at all" case is now answered
   before the toolbar is built, and the widget has one empty case instead of two.

### Round 3 — found by the strict visual audit, not by eye

5. **A real contrast failure in dark.** The icon well was `surfaceMuted` with a
   `primary` glyph — `#5656C9` on `#292D42` is **2.31:1**, below the 3.0 floor for
   a 24px icon. It looked fine in light and fine to me in dark. The audit caught
   it. Fixed by moving to the Material 3 container pair `primaryContainer` /
   `onPrimaryContainer`, which is **8.96:1** and carries a contrast guarantee by
   construction — `primary` is a fill colour and nothing promises it is legible
   *on* another surface.

---

## Where this deviates from the brief

Listed separately from the risks because these are places the brief gave a number
or a step and the result does not match it. Two were found by re-reading the brief
against the code after the first "done", and fixed; three stand, with reasons.

### Fixed on the second pass

| § | Brief | First result | Now |
|---|---|---|---|
| 10 | Bottom list padding **≥96** | 88 (`56 + lg + lg`) | **96** (`56 + lg + xl`) — cleared the button but read as crowded against it |
| 10 | Section gap **24** | 16 between toolbar and list | **24** (`AppSpacing.xl`). The "keep the existing token" argument did not apply: `xl` **is** 24 and already existed, so 16 was simply the wrong token for a section break |

### Standing, with reasons

| § | Brief | Result | Why |
|---|---|---|---|
| 10 | Card radius 20–24 | `AppRadius.lg` = 16 | §10 says keep the existing token when close. A new `xl` radius would make the deck card the only panel in the app with its own corner. |
| 10 | Icon area ~56 | 48 (`AppSpacing.minimumTouchTarget`) | Same rule. 56 is not a token; 48 is, and it is the number the row's real controls use, which keeps icon, title and action optically aligned. |
| 3 | `BorderRadius.circular(...)` listed among constructs not to use in Deck presentation | `DeckIconArea` uses `BorderRadius.circular(AppRadius.md)` | The value is a token, and this is exactly how `MxCard` — the shared component it sits inside — writes its own radius. Avoiding the construct would mean either a hardcoded `BorderRadius` constant or a shared wrapper with one caller. Flagged rather than hidden: if the rule is meant literally, the fix is a `BorderRadius` helper in `core/theme/`, which needs a second caller to justify. |

### Process steps not followed as written

| § | Step | What happened |
|---|---|---|
| 11.5 | "render Deck light/dark **hiện tại**" — capture the before state | Not done. Only the after state was rendered, so the comparison in this report is against the code as read (`MxListTile` rows, no toolbar, app-bar create) rather than against an image. The three refinement rounds were still driven by looking at real renders, but the before/after pair does not exist. |
| 7 | "Deck detail, form và dialog **nếu lệch rõ** với UI mới" | The first version of this report asserted these were aligned **without rendering them**, and one of them was not. Now rendered and resolved — see below. |

#### What rendering the rest of the feature actually found

| Surface | Verdict |
|---|---|
| Create/rename form sheet | Consistent. `MxTextField`, radio list with descriptions, `MxActionButton`. The scheduler choice stays radios rather than pills: each option carries two lines of explanation, which a pill cannot hold, and it is a form commitment rather than a view toggle. |
| Deck actions sheet | Consistent. Left alone. |
| Move-deck sheet | Still `MxListTile` while the lists use cards. **Kept deliberately** — it is a dense picker where every row carries an eligibility reason, and cards would roughly double the height of a ten-deck sheet. Now a checked decision rather than an assumed one. |
| **Deck detail screen** | **Was genuinely divergent and is now fixed.** Create was an app-bar icon there while the root list had moved it to a floating action — the same kind of action, two presentations, which is exactly the drift §7.6 asks about. It is now a floating action on both. |

A false comment was also found and corrected while checking this: the detail
screen's list claimed to own its horizontal gutters "now that the shell no longer
supplies them", which was never true — the detail screen never stopped letting
`MxContentShell` supply them. The gutters did match; the explanation did not.

---

## Remaining risks

1. **The scheduler label is a third line on every card.** It is required by UC-06
   and it is the least scannable fact on the row. If it later turns out nobody
   reads it on the list, removing it is a content decision, not a visual one, and
   would let the cards lose ~20px.
2. **The card is ~88px, below the reference's 104–116.** That follows from keeping
   `AppSpacing.lg` padding and a 48 icon well rather than inventing a 56 token, as
   §10 directs. It reads slightly tighter than the reference. (Not to be confused
   with the list's bottom inset, which was 88 and is now 96 — see the deviations
   table.)
3. **`DeckIconArea` is feature-local with one caller shape.** If a second feature
   wants a tinted glyph well it should be promoted then — the second caller is what
   shows whether the tint, the size or the radius is the part worth parameterising.
4. **The filter is binary (all / due).** Enough for the data the summary carries;
   a "new cards" filter is not possible because `RootDeckSummary` has no new-card
   count, and inventing one would have meant showing a number the query does not
   produce.
5. **Two files were split to stay under the 400-line guard**
   (`app_theme.dart` → `app_button_themes.dart`, and two test files). The seams are
   clean, but they were forced by a line count rather than chosen.
6. **Goldens are unchanged, so the redesign has no pixel baseline of its own.**
   The deck screens are covered by strict visual audits, which check contrast,
   token provenance and exact node counts but not layout pixels. A layout
   regression that keeps every colour legal would not be caught.

---

## Verdict

**DONE**

| Criterion | |
|---|---|
| Audited tokens/theme/shared widgets before coding | ✓ mapping table above |
| Mapping table reuse/extend/create | ✓ |
| No component duplicating an existing shared widget | ✓ `MxPillButton` justified against all four candidates |
| No hardcoded colour or style in Deck | ✓ one named framework constant, explained |
| No new app shell or bottom navigation | ✓ |
| Root Deck List clearly changed per the reference | ✓ |
| Deck card no longer a default `ListTile` | ✓ `MxCard` with icon well and 3-level type |
| Light/dark still MemoX's design language | ✓ unshadowed, existing palette, existing radii |
| No fake controls | ✓ filter and sort are real; toolbar hidden when there is nothing to act on |
| New shared widget has ≥2 callers and tests | ✓ 2 callers, 10 tests |
| Deck-specific widgets stay feature-local | ✓ |
| No overflow at 320×568 or text scale 2.0 | ✓ |
| Business logic unchanged | ✓ no domain, use case, repository, query, scheduler or due-count change |
| Analyze and tests pass | ✓ 880 tests, analyze clean, all guards clean |
| Golden diff reviewed | ✓ none needed — 88 pass unchanged |
| At least one refinement round | ✓ three |

---

# Addendum — one deck-list screen for every level

Requested after the redesign landed: *"khi truy cập deck con thì màn hình vẫn giữ
nguyên bản như còn ở deck cha — vì dù sao vẫn là màn hình danh sách deck."*

## What was actually different, and why

The redesign gave both screens the same card, the same rhythm and the same
floating action, and they still did not look the same. The reason was not styling:

| | Root list | Inside a deck |
|---|---|---|
| Read | `watchRootDeckList` — flat `GROUP BY root_deck_id` | `watchDeckDetail` — `LEFT JOIN` on `parent_deck_id` |
| Row carried | name · totals · due state · scheduler | name |
| Toolbar | filter + sort | none |

A sub-deck row showed only a name because the query returned only a name. Styling
the two screens identically could not close that; it would have made a row with
one fact look like a row with four.

So this was a **data** change, taken with the project owner's explicit approval —
the redesign brief had fenced off domain, use cases, the repository contract and
the Drift queries, and that fence was lifted for this work specifically.

## The query

`childDeckLevel` is a new named query in `deck.drift`: a recursive CTE that
attributes every descendant to the branch it hangs from, then joins the card
totals and the due counts per branch. One statement, one snapshot.

`rootDeckSummaries` is **unchanged**. A root's subtree is reachable through
`root_deck_id` (BR-56), so the root level gets its aggregate from a flat group-by
that measurement showed to be covering-index fast; generalising the two into one
recursive query would have paid for a walk where a column already answers.

That leaves the same number computed two ways, which is why
`deck_level_parity_test.dart` exists: for any deck D,
`subtree(D) == direct_cards(D) + Σ subtree(child of D)`, asserted against real
SQLite at the root, at a branch, at a leaf, across two trees, and after a move.
A mismatch would be invisible on screen — a root showing 120 and its children
summing to 118 look equally plausible.

`deck_level_read_test.dart` counts SQL statements through a real
`QueryInterceptor`. Three children with subtrees of their own still cost **one**
statement; the aggregates come from the CTE, not from a query per row.

## What collapsed

| Before | After |
|---|---|
| `RootDeckSummary` · `RootDeckListSnapshot` · `DeckDetail` | `DeckSummary` · `DeckListSnapshot` |
| `watchRootDeckList` · `watchDeckDetail` | `watchDeckList(parentDeckId:, now:)` |
| `WatchRootDeckListUseCase` · `WatchDeckDetailUseCase` | `WatchDeckListUseCase` |
| `RootDeckList` · `DeckDetail` notifiers | `DeckList` family on the parent id |
| `RootDeckListScreen` · `DeckDetailScreen` | `DeckListScreen({parentDeckId})` |
| `DeckTileWidget` · `DeckChildTileWidget` | `DeckTileWidget` |
| two visual-audit companions | one, with eight states |

`parentDeckId == null` is the root level. Nothing else branches on depth.

## What still differs by level, and why each is real

- **The title** — the app's name at the root, the deck's name below it.
- **The app-bar action menu** — only where there is a deck to rename, move or
  delete. The root level is not a deck; its rows carry their own menus.
- **Which create flow the floating action starts** — `createRootDeck` needs a
  scheduler (BR-11), `createSubDeck` inherits one (BR-06). The button, its
  position and now its glyph are identical; only the sheet differs.
- **Not-found** — a deck can be deleted while it is open (UC-03 E1). The root
  level cannot be missing, so there a failed read is always a read failure.

Everything else — the toolbar, the cards, the counts, the due colouring, the
scheduler line, the empty states, the bottom inset — is one code path.

## Two things the render caught that code review did not

1. **The floating action had two glyphs**: `add` at the root,
   `create_new_folder_outlined` inside a deck. One action drawn two ways, on the
   two screens this task exists to make identical. Now `add` at both levels; the
   tooltip and the semantic label carry the difference.
2. **The loading and error frames dropped the title.** Written that way because a
   deck's name is *in* the data that has not arrived — true inside a deck, false
   at the root, where the title is a constant. The root level now keeps "Decks"
   through loading and through a failed read, so the screen does not appear to be
   replaced whenever the data changes; a level inside a deck still shows no bar
   until it has a name, rather than a blank one or the previous deck's.

## Scheduler resolution, which the old detail screen simply lacked

Only a root carries `scheduler_type` (BR-06), so a sub-deck's own column is NULL.
A summary built from the entity would say "unknown" on every deck below the first
level. `childDeckLevel` resolves it through the child's `root_deck_id` and
`DeckSummary.schedulerType` carries the answer — which is why the tile reads
`summary.schedulerType`, not `summary.deck.schedulerType`.

## Guard changes

Two, both at the rule rather than at the call site:

- `memox.state_management.no_generated_ref_subclass` matched `WidgetRef ref`. That
  is a current Riverpod 3 type and the declared parameter of every `Consumer`
  builder — the rule fired on correct code the first time a builder's `ref` was
  passed to a helper. Excluded by name; verified it still fires on
  `DeckListRef ref`, `MyThingRef ref` and `AutoDisposeRef ref`.
- `MX-VIS-001`'s own path assertion named `root_deck_list_screen`; retargeted to
  the surviving screen.

Two files were split to stay under the 400-line guard —
`widgets/deck_level_error_widget.dart` out of the screen, and
`deck_level_create_test.dart` out of the level test. Both are real seams: the
error state shares no data with the list, and the create matrix shares no
assertions with the read states.

## Verification

| | |
|---|---|
| `flutter analyze` | clean, `lib` and `test` |
| `flutter test` | **892 pass** (from 880) |
| Visual audits | 97 pass — 8 states × light/dark on the one companion |
| `check_generated.sh` | fresh, complete, uncommitted |
| `check_architecture.sh` | clean, 112 files |
| code-verification-guard | 0 violations across 66 rules |
| `check_docs.sh` | specification internally consistent |
| `dod_check.sh` | mechanical gates passed |

Rendered at both levels, light and dark, 393×852: the two screens are identical
apart from the title, the back arrow and the parent's action menu.

---

# Addendum 2 — `MxBreadcrumb`, and the path back up

Requested once the screen became recursive: *"vì là màn hình đệ quy nên hãy phát
triển breadcrumb làm share widget để dễ dàng điều hướng"*.

## Where it appears, and where it deliberately does not

| Level | Breadcrumb |
|---|---|
| Root list | none — nothing above it |
| Inside a root deck | none |
| Level 3 and below | `Japanese N5 › Writing systems › Kana` |

**One level in it is suppressed on purpose.** The only step above a root deck is
the deck list, which the Back arrow *and* the Decks tab already reach in one tap.
A crumb there would be a third control doing the same job — the duplicate chrome
this design has refused elsewhere. From level 3 the intermediate decks are
reachable by nothing short of tapping Back repeatedly, and that is the gap a
breadcrumb closes.

The last step is the current deck and is **not** tappable. It repeats the app-bar
title on purpose: a path that stopped at the parent would read as a link to
somewhere else rather than as the trail that ends here.

## The shared widget

`MxBreadcrumb` takes `List<MxBreadcrumbItem>` — a label and an optional `onTap`.
No domain type, no Riverpod, no ARB lookup. `DeckPathWidget` is the feature-local
adapter that turns a `DeckListSnapshot` into those items.

**It ships with one caller, and that is a departure from the rule this project
set itself** ("a new shared widget needs ≥2 real callers"). It was asked for as a
shared widget explicitly, and the named second caller is the card list in M4.11,
which sits under the same tree and needs the same path. Recording the deviation
rather than pretending the rule was met.

Why it is not one of the existing components: `MxNavigationBar` switches between
siblings at a fixed top level, `MxPillButton` is one-of-N over the same content (a
set, not a sequence, with a selected state where a path has a last element), and
`MxListTile` is a row. Nothing held "where am I, and how do I get back up".

**It scrolls horizontally, so it cannot overflow.** Wrapping turns a ten-deep path
at `textScaler` 2.0 into five lines of chrome above the content it is meant to
help you scan; collapsing the middle behind an ellipsis hides exactly the steps a
user opens a breadcrumb to find. Scrolling hides nothing and costs nothing when
the path is short. Rendered at 320×568 / scale 2.0 with nine ancestors: the strip
clips mid-word at the right edge, the rest of the screen is unaffected, and the
clipped word is its own affordance.

## Getting the chain out of the database

The chain has to agree with the title — renaming an ancestor while a descendant is
open must move both or neither — so it comes from the level's **own statement**
(AD-13), not from a second query. Three shapes were tried:

1. **Join `ancestry` onto the child rows.** Fully typed, and wrong: it multiplies
   the result set by the depth. 100 children at level 5 becomes 400 rows where 100
   would do, and M4.10 measured that what costs on the UI thread is rows crossing
   the isolate boundary, not SQL time.
2. **`UNION ALL` returning ancestors as extra rows.** Free *and* typed — except
   drift does not expand `table.**` inside a compound select. It emits the literal
   `parent.**` into the SQL string, generates a result class with only the
   discriminator column, and reports **no error**. Verified against drift 2.34.
3. **One JSON scalar**, repeated per row exactly like `nextDueAt`. Chosen.

So `ancestryJson` is a deliberate hole in this file's rule that every column is
type-checked at build time, and it is sealed at the mapper: `deckPathFromJson`
is the only thing that sees a string, and everything above the repository
receives `List<DeckPathSegment>`.

The decode is **total**. A breadcrumb is chrome, so malformed input yields a
screen with no breadcrumb rather than a deck the user can no longer open — the
counts, the rows and the title in the same read are unaffected by whatever went
wrong. `deck_mapper_test.dart` pins that: bad JSON, valid JSON of the wrong
shape, and a partially damaged array where the intact entries survive.

`distance` travels inside each object rather than being inferred from array
order, because SQLite does not promise the order an aggregate consumes its input.
The sort happens in Dart, where the guarantee is real — and a test feeds the array
backwards to prove it.

## A drift footgun worth recording

The first version of the query silently failed to compile with
`Expected a sql statement here` pointing at the *next* query's label. The cause
was a **semicolon inside a `--` comment**: drift splits `.drift` files on `;`
before stripping comments, so one sentence ending in a semicolon truncated the
statement above it. It is reported as a warning, not an error, so the build
succeeds and the generated method simply does not exist.

## Verification

| | |
|---|---|
| `flutter analyze` | clean |
| `flutter test` | **930 pass** (from 892) |
| Visual audits | 97 — the loaded level now carries a two-step path, so the breadcrumb's colours are measured rather than assumed |
| `check_generated.sh` · `check_architecture.sh` · guard · `check_docs.sh` | all clean |
| `dod_check.sh` | mechanical gates passed |

New tests: `mx_breadcrumb_test.dart` (14 — the last step is not a control, deep
paths do not overflow, every step announces itself, separators do not),
`deck_ancestry_read_test.dart` (9, against real SQLite — depth 1 to 10, sibling
branches excluded, rename and move rewrite the chain, JSON punctuation survives),
plus the chain's statement count, six mapper cases and five screen cases.

Two files were split at the 400-line guard: `DeckPathWidget` out of the screen,
and `deck_move_picker_test.dart` out of the actions test. Both are real seams.

## Standing limitations

- **One caller.** See above.
- **No scroll affordance.** A deep path clips at the right edge with no fade or
  arrow. A gradient would be the usual fix and there is no token for one; adding a
  hardcoded shader to satisfy an edge case is the trade this design has refused
  elsewhere.
- **The strip is not keyboard-scrollable** beyond what focus traversal gives it.
  Web is the E2E channel, not a production target (AD-04), so this is deferred
  rather than dismissed.
