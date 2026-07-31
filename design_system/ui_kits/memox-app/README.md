# UI kit — memox Android app

A click-through recreation of the app's four real surfaces, built from `lib/features/deck/presentation/`, `lib/shared/widgets/` and the golden design previews in `test/design_preview/`. It composes the design system's own components; nothing is re-implemented here except the two feature-local widgets that live in the feature layer upstream too (`DeckTile`, `VerdictAction`).

Open `index.html`.

| File | Surface | Built from |
|---|---|---|
| `DeckLevelScreen.jsx` | **The deck list — one recursive screen used at every depth.** Root, sub-deck and leaf are the same component with a different path; breadcrumb, back arrow and the create label are the only things that vary | `deck_list_screen.dart`, `deck_tile_widget.dart`, `deck_list_toolbar_widget.dart`, `deck_path_widget.dart`, `test/design_preview/deck_list_preview_test.dart` |
| `ReviewScreen.jsx` | The review session — flashcard, two verdicts, end session, offline notice | `test/design_preview/review_screen_preview_test.dart`, `preview_harness.dart` |
| `SettingsScreen.jsx` | Grouped rows, switches, one destructive row | `test/design_preview/settings_preview_test.dart` |
| `DeckForms.jsx` | Create / rename sheet with the mandatory study-mode choice | `deck_form_widget.dart` |
| `kitdata.js` | Fixture content — one recursive deck tree, taken from the repo's own preview fixtures | — |

## Screen sizes

The frame switches between the two devices the app is actually built against, in **logical CSS px** rather than physical pixels:

| Device | Frame | Note |
|---|---|---|
| Samsung Galaxy S23 Ultra | 412 × 915 dp | The 1440 × 3088 panel at its 3.5× density |
| iPhone 13 mini | 375 × 812 pt | The 1080 × 2340 panel at 3× |

Both sit **above** the system's one real breakpoint (360px), so neither triggers the compact scale — the small frame is narrower, not a different layout. The `isCompact` flag is wired through every screen anyway, so dropping a frame below 360 immediately shows the compact app-bar title, tighter gutters and the 26px card prompt.

## What is deliberately absent

- **A card editor and a card list.** Still on the upstream backlog; there is no screen to copy, so there is none here.
- **Login, sync, profile.** No auth and no backend at MVP.
- **Search that filters server-side, a sort menu, a profile avatar.** The toolbar upstream carries exactly the two switches that do something.

## Interactions that work

Open a deck → the same screen, one level deeper; breadcrumb steps and the back arrow walk back up. Row menu (`⋮`) → action sheet → Delete → destructive confirm. FAB → create sheet (a root deck must pick a study mode; nothing is preselected). Review tab → answer a card → next card → session complete. Filter and sort pills re-order the level. The Screen and Theme switches under the frame change device and palette.
