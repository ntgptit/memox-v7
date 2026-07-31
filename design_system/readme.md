# memox — design system

memox is a **Flutter flashcard / spaced-repetition app**: you create decks of vocabulary cards and the app decides which ones you see today. It is **local-first** — SQLite is the source of truth, everything works in airplane mode, and at MVP no data leaves the device. Android is the release target; the Web build exists only as the E2E / visual-regression channel and is framed to a phone.

This design system is a recreation of that product's real visual language, compiled from the source repository — not an invented brand.

## Sources

| Source | What was taken |
|---|---|
| **https://github.com/ntgptit/memox-v7** (branch `main`) | Everything below |
| `lib/core/theme/` — `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_elevation.dart`, `app_icon_size.dart`, `app_durations.dart`, `app_breakpoints.dart`, `app_semantic_colors.dart`, `app_theme.dart`, `app_button_themes.dart`, `app_compact_scale.dart` | Every token in `tokens/` |
| `lib/shared/widgets/mx_*.dart` | The component inventory in `components/` |
| `lib/features/deck/presentation/` | The deck-level screen, tile, toolbar and form in the UI kit |
| `test/design_preview/` and its goldens | The Library, Review and Settings screens, and the verdict / section-label treatments |
| `assets/fonts/` | Inter and Plus Jakarta Sans variable TTFs, copied in |

If you have access, read those files directly — `app_colors.dart` and `app_elevation.dart` in particular carry the reasoning behind almost every value here, and going back to them will produce better work than reading this file alone. Explore the repository further before building anything substantial on top of this system.

---

## CONTENT FUNDAMENTALS

**Language.** Product strings are English; the project's own internal documentation is Vietnamese. Every UI string is already localized before it reaches a component — no component in this system reads a string catalogue, and none builds a sentence.

**Register: plain, exact, unhurried.** Copy states what is true and stops. It never sells, never celebrates, never apologises twice.

- "Study 15 cards due today" — the action names its own scope.
- "Could not sync — changes are saved on this device" — problem, then reassurance, one line.
- "Nothing due today" — good news stated plainly, never dressed as an achievement and never as an error.
- "This also deletes 3 sub-decks and 180 cards. This cannot be undone."
- "The study mode locks after the first review. Changing it later needs a progress reset." — a consequence, stated before the choice.

**Casing.** Sentence case everywhere: titles, buttons, rows, dialogs ("Reset learning progress", not "Reset Learning Progress"). The one exception is the section label above a group of rows — UPPERCASE, 11px, tracked 1.1px: "YOUR DECKS", "STUDY", "APPEARANCE", "DATA".

**Person.** Mostly impersonal. "you" appears only where the thing genuinely belongs to the reader — "Search your decks", "Your decks". Never "we". Never a first-person app voice.

**Punctuation.** The middle dot separates facts on one line: `46 cards · 5 due · 8 boxes`, `adjective · lasting for a very short time`. The em dash joins a statement to its consequence. Curly quotes around a user's own deck name inside a dialog: `Delete "Phrasal verbs"?`. No exclamation marks anywhere.

**Numbers.** Always concrete, always shortened to fit one line: `3 of 20`, `12 due`, `20 of 570 learned`, `7-day streak`. When a count and a label compete for space the label shortens, never the number ("5 due", not "5 cards due").

**Emoji: never.** Not in the product, not in the docs, not in this system. Status is carried by a Material glyph, a word, and a colour — all three.

**Error copy belongs to the screen, not the component.** A shared component is never allowed a generic "Something went wrong": "Couldn't load your decks" is not "Couldn't load this deck", and the difference is what tells the user what to do next. Technical detail — table names, exception text — never reaches the user.

---

## VISUAL FOUNDATIONS

### The idea
A study tool for adults at work. Restrained, dense, quiet. Exactly one accent (indigo, hue 240), four semantic colours on a strict chroma budget, and a page that is the only place saturation is allowed to be loud.

### Colour
- **Surface ladder, four tiers.** Dark climbs L\* 3.9 → 10.2 → 16.9 → 24.0 (`#0A082D` page → `#1A1838` card → `#28254B` inset → `#37345F` raised). Light inverts the ordering: the card is the brightest thing (`#FBFBFE`) on a slightly darker page (`#F4F5F8`). The ladder is spaced in L\*, not contrast ratio — at the bottom of the scale WCAG's constant compresses every real step into "1.1-something".
- **The dark ladder is the page's own colour, lightened.** It used to be a separate slate — the card was hue 235 to the page's 243 and carried half its chroma — and the two families stacked on each other made the card read as grey paper laid on a violet app. Every dark surface now sits at OKLCH hue ~285, chroma 0.06–0.074. That is also why the dark `secondary` and the dark due-chip ground moved: a role whose fill and container disagree by 18° of hue, or a warm olive ground on a violet page, is the same mistake one level down.
- **The card is not pure white.** `#FBFBFE` is the seed at 2% over white: the surface the whole app is built on carries the same hue as every other neutral.
- **One accent, both modes.** `#4646B4` light, `#5656C9` dark. The dark value is deliberately held below the card's headline text, so the CTA is never the brightest thing on screen.
- **Secondary actions are neutral, not brand.** `#454B5E` / `#C3C6D2` — a secondary action sits next to the review verdicts, and a hue there competes with the user's actual decision.
- **Four semantics, deliberately unequal.** `danger` carries the most saturation, `info` the least. None reaches full saturation: four hues all shouting is how a study tool starts looking like a game.
- **`error` IS `danger`.** There is no second red system.
- **Colour is never alone.** Every state is carried by a glyph, a word and a colour together. The *absence* of a state carries none of the three.

### Type
Two families. **Plus Jakarta Sans** for display and titles — the app's only visual signature, geometric with humanist terminals. **Inter** for body and UI — drawn for screens, unambiguous `l` / `I` / `1` at 14px. Both bundled as variable fonts and loaded from `assets/fonts/`; nothing is fetched at runtime, because a study tool must render identically offline.

The one deliberately large style is the review card prompt: **30px / 1.22 / −0.5px tracking**, dropping to 26px below 360px wide so the answer never falls below the fold. Body text is never scaled by device width — that would silently undo the user's own accessibility setting.

### Spacing and layout
Six steps only: **4 · 8 · 12 · 16 · 24 · 32**. 16px is the screen gutter and the gap between list items; 24px separates sections; 32px surrounds a lone focal element. A scale wide enough to express "a bit more" invites per-screen drift, and the drift is what makes an interface feel unfinished long before anyone can point at a specific screen.

**48px is a floor, not a step** — nothing a finger has to hit goes below it, and no component exposes a prop that could shrink it. Mobile-first: one real breakpoint at 360px (tighter gutters, smaller app-bar title and card prompt, buttons lose horizontal padding but keep their height), and a documented upper edge at 600px that nothing branches on.

### Corners, borders, shadow
Radii: **8** chips · **12** buttons and inputs · **16** cards and sheets · **999** pills. Restrained on purpose — heavily rounded surfaces read as playful rather than focused.

Every card is a **1px hairline border plus a soft shadow in light only**: `0 1px 3px rgb(11 12 24 / .07)` — an alpha solved for (`0.06 + 0.01 × level`) rather than picked, so a card is lifted ~7.75 L\* off the page in light against dark's 7.70 on the surface step alone. **Dark paints no shadow at all**: at the bottom of the lightness scale a shadow moves the page by ΔL\* 0.26, which is paint nobody can see. Shadow colour is seed-tinted `#0B0C18`, never black.

### Backgrounds and imagery
Flat colour, everywhere. **No gradients, no photography, no illustration, no texture, no pattern** — the repository contains none, and the review screen is built so the flashcard is the most prominent thing on it. Blur and transparency appear in exactly one place: the 60% scrim over a dialog or sheet. Full-bleed imagery does not exist in this product; if a mock needs an image, that is a decision to take with the user, not a default.

### Motion
Three durations: **120ms** (press, ripple), **200ms** (card and surface transitions), **320ms** (the ceiling). Easing `cubic-bezier(0.2,0,0,1)`, decelerate `cubic-bezier(0,0,0,1)`. No bounce, no spring, no entrance animation on a list. During a review the user is answering, not watching.

### States
- **Hover** (web/desktop only): 8% neutral wash on rows, 6% indigo on outlined controls, 4% on cards.
- **Press:** a 12% indigo overlay; a filled button darkens by lerping 12% toward `onSurface`. Nothing scales, nothing shrinks.
- **Focus:** a 2px indigo ring. On an input, focus shifts the border's **hue** and never its width — Material's 1px→2px jump nudges everything laid out beside it.
- **Disabled:** a **precomputed solid** (`#E3E3E6` light, `#312E4E` dark), never a translucent token — a 12% alpha composites against whatever happens to be behind the control, so one token renders as three colours nobody chose.
- **Selected:** the navigation indicator pair (`secondary-container`), used identically for a tab, a filter pill and a chosen verdict.
- **Loading:** a spinner, never a skeleton. Local reads finish in single-digit milliseconds; motion that says "slow" about something that is not is worse than a moment of nothing.

### Layout rules
Bottom navigation is fixed and paints the **page** colour, so the chrome reads as one frame rather than three stacked surfaces. The app bar likewise: no elevation, no scroll tint — during a review a colour shift behind the card reads as the card itself changing. The FAB floats 16px from the bottom-right and reserves no space; a scrolling list ends with a 96px bottom inset so its last card clears the button.

---

## ICONOGRAPHY

- **One set: Material Icons**, Flutter's bundled family. **Outlined at rest** (`Icons.folder_outlined`), **filled when selected or active** (`Icons.folder`) — that pairing is the second, non-colour signal saying which tab is current.
- **Three sizes only:** 16 inline with text, 24 for actions and list affordances, 40 for the glyph in an empty or error state. A fourth would be a guess.
- Icons render through `MxIcon`, which wraps the Google Fonts **Material Icons / Material Icons Outlined** ligature webfonts — the same glyph set Flutter ships, reached by CDN because the repo carries it inside the Flutter toolchain rather than as loose files. **Substitution flag: the glyph shapes are identical; only the delivery differs.** Add `<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons|Material+Icons+Outlined">` to any page that renders components.
- **No emoji, no unicode characters used as icons, no hand-drawn SVG.** The one non-Material mark in the product is the middle dot separating facts on a summary line.
- **Working vocabulary:** `folder` (a deck), `style` (cards), `school` (review), `notifications_active` (something is due), `local_fire_department` (streak), `more_vert` (row and app-bar menus), `add` (the FAB), `chevron_right` (breadcrumb separator, row affordance), `filter_list` / `swap_vert` (the two toolbar pills), `restart_alt` (reset progress), `delete_outline`, `edit`, `drive_file_move`, `error_outline`, `check_circle_outline`, `info_outline`, `tune`, `close`, `arrow_back`, `search`, `radio_button_checked` / `radio_button_unchecked`.

## Logo

**There is no logo.** The repository contains no wordmark, no icon and no lockup — the launcher icons under `web/` are Flutter's untouched defaults. Wherever a mark would go, set the name in Plus Jakarta Sans, bold, **lowercase: memox**. See `guidelines/brand-wordmark.card.html`. Nothing here was drawn or reconstructed.

---

## Index

| Path | What it is |
|---|---|
| `styles.css` | The one stylesheet consumers link — `@import`s everything below |
| `tokens/` | `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `radius.css`, `elevation.css`, `motion.css`, `layout.css` |
| `components/mx.css` | Component classes — the hover / focus / press states inline styles cannot express |
| `components/core/` | The interactive primitives |
| `components/feedback/` | States, dialog, sheet |
| `components/navigation/` | Bar, breadcrumb, screen shell |
| `guidelines/` | 20 specimen cards — colour, type, spacing, radius, elevation, motion, brand, iconography |
| `ui_kits/memox-app/` | Click-through recreation of the app's four screens (see its own README) |
| `assets/fonts/` | Inter and Plus Jakarta Sans variable TTFs, with their OFL licences |
| `test/design_preview/goldens/` | The upstream golden screenshots, kept as visual ground truth |
| `thumbnail.html` | The project tile |
| `SKILL.md` | Agent-skill entry point |
| `github.md` | Source-repo association and sync record |

### Components

Mirrors `lib/shared/widgets/` one-for-one; the source defines the inventory.

**Core** — `MxActionButton`, `MxIconButton`, `MxPillButton`, `MxCard`, `MxTextField`, `MxListTile`, `MxProgressBar`, `MxIcon`
**Feedback** — `MxEmptyState`, `MxErrorState`, `MxLoadingState`, `MxAsyncView`, `MxConfirmDialog`, `MxActionSheet`
**Navigation** — `MxNavigationBar`, `MxBreadcrumb`, `MxSearchField`, `MxContentShell`

Each has a `.jsx`, a `.d.ts` props contract and a `.prompt.md` usage note beside it.

**Intentional additions** — two, both required by the redesign:

- `MxIcon`, because the Flutter side reaches for `Icons.*` directly and that has no web equivalent, so the glyph set needed a single component to route through.
- `MxProgressBar`, because the redesign organises the interface around progress. It draws in its own `--color-progress-*` family rather than the accent, so a bar never competes with the button beside it.
- `MxSearchField`, because the redesign searches the whole deck tree. `MxTextField` is a form control with a floating label and a 1.5px outline; a search bar with a label above it reads as something you must fill in before continuing.

**Not built, because the source has no counterpart:** Toast / Snackbar (themed upstream but with no caller), Avatar, Tabs, Tooltip, Select, Checkbox, Radio, Switch. The study-mode radio and the settings switch exist only as feature-local widgets upstream, so they live in the UI kit here rather than in `components/`.

## Working with this system

- Link `styles.css`, add the Material Icons stylesheet, load `_ds_bundle.js`, then `const { MxCard } = window.<Namespace>`.
- Dark mode is `document.documentElement.dataset.theme = 'dark'` — one scope re-points every semantic token.
- **A component that can be tapped is never itself a `<button>`.** A button may not contain a control, so a component that becomes one can hold none — and the first caller that needs a trailing menu wraps *part* of the content in its own button instead, which leaves every other part looking tappable and inert. `MxCard` composes `button.mx-card__action` under `.mx-card__content` and hands pointer events back with `.mx-card__control`; its `.prompt.md` has the pattern. **`MxListTile` still renders as a `<button>`** and needs the same treatment the first time a caller gives it an interactive `trailing` — a switch, an icon button — rather than a chevron.
- Never introduce a colour, radius, duration or spacing value that is not a token. Upstream this is enforced by a design-token guard in CI; here it is the same rule, unenforced.
