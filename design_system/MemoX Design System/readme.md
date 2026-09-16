# MemoX Design System

A from-scratch visual system for **MemoX** — a local-first flashcard / spaced-repetition study app (originally Material 3). This system **rebuilds the visual language entirely** (color, type, spacing, radius, density) while **freezing the technical identifiers** that downstream code binds to, so the redesign stays compatible with the existing engineering system.

> **The golden rule:** changing a *value* is free; changing a *name or id* breaks the system.

---

## Sources (for the reader — access not assumed)

- **Color reference — Tokyo admin dashboard:** <https://github.com/ntgptit/tokyo-react-admin-dashboard>
  - Used **only** for the color *palette*. The light values come from `tokyo-free-white-…/src/theme/schemes/PureLightTheme.ts` (primary `#5569ff` on `#f2f5f9`); the dark values from `tokyo-free-black-…/src/theme/schemes/NebulaFighterTheme.ts` (primary `#8C7CF0` on `#070C27`). **No** token names, component names/classes, or layout were borrowed from Tokyo — only color.
- **Product context — MemoX repos** (not imported; for deeper exploration): `ntgptit/memox-v4`, `ntgptit/memox-v3`, `ntgptit/memox-design-v2`. Explore these to ground future screens in the real product.
- **Font:** Plus Jakarta Sans (variable), provided by the user → `fonts/PlusJakartaSans[wght].ttf`.

Anyone extending this system should browse the repos above for richer product detail.

---

## Architecture — three one-way layers

**Token → Component → Screen.** Screens only use Components; Components only use Tokens. No layer-skipping, and **no raw visual values** (`#rrggbb`, literal px colors/spacing) above the token layer.

1. **Tokens** (`tokens/*.css`) — the single source of truth for every visual value, as `--memox-<role>` custom properties, defined for **light** (`:root`) and **dark** (`[data-theme="dark"]`). Switch themes by setting `data-theme` on any ancestor — never by overriding inside components. Token names are an **additive-only** contract.
2. **Components** (`components/<group>/`) — the fixed `Mx*` family. Each has a **stable PascalCase name** and a **stable base class**; variants are **modifiers**, never new names.
3. **Screens** (`ui_kits/memox-app/`) — assembled only from components, presented as a state gallery in light + dark.

---

## CONTENT FUNDAMENTALS

How MemoX writes copy:

- **Voice:** calm, encouraging coach — never gamified-shouty. Second person ("your decks", "come back tomorrow"). The app refers to itself sparingly.
- **Casing:** Sentence case everywhere — titles, buttons, list rows ("Start review", "New cards / day", "Your library is empty"). Reserve ALL-CAPS for tiny overlines/labels only ("DUE NOW", "PRO") with wide letter-spacing.
- **Tone examples:** empty states are warm and actionable ("Create a deck and add a few cards — your daily reviews show up here."), completion is congratulatory but brief ("Session complete!" + one line of stats). Errors are plain and recoverable ("Nothing matched \"kanjii\". Check the spelling or try a different term.").
- **Numbers lead.** Study apps run on counts — surface the number big and the noun small ("83 / cards across 3 decks", "12 / day streak", "94% / accuracy").
- **Verbs for actions:** Start, Review, Show answer, Again / Hard / Good / Easy, Finish. Short and imperative.
- **No emoji** in UI text. Meaning is carried by Material Symbols icons and color, not emoji.
- **Punctuation:** em/en dashes and middots ("·") to separate meta ("Kanji · 320 cards", "Tuesday · 27 June"). Avoid exclamation except on genuine wins.

---

## VISUAL FOUNDATIONS

- **Color vibe.** Cool, focused, slightly nocturnal. Light theme is an airy blue-grey canvas (`#f2f5f9`) with crisp white cards and an **indigo** primary (`#5569ff`). Dark theme is a deep navy (`#070C27`) with raised navy cards and a softer **violet** primary (`#8C7CF0`) — easier on the eyes for evening study. Cyan (`#33C2FF`) is the secondary accent. Semantics: green success, amber warning, red error.
- **Type.** Plus Jakarta Sans throughout — a geometric-humanist sans with friendly round counters. Display/number weights are **Extrabold (800)**, titles **Bold (700)**, body **Regular/Semibold (400/600)**. Tight tracking (`-.02em`) on large display; wide tracking (`.04–.08em`) on small caps overlines. Big numerals are the hero element.
- **Spacing.** 4px base scale (`--memox-space-1…12`). Comfortable mobile density — 20px screen gutter, generous 20px card padding, 16px gaps between list rows.
- **Corner radii.** Soft and modern: cards `20px`, tiles `16px`, controls/buttons `12–14px`, FAB/extended pills, chips & switches fully rounded. Nothing sharp.
- **Cards.** The core surface. Light: white, no border, soft **blue-grey** ambient shadow (`0 9px 16px rgba(159,162,191,.18)`). Dark: raised navy with a hairline `#272C48` ring instead of a heavy shadow. Variants: `flat` (hairline), `muted` (sunken), `primary` (solid brand), `primary-soft` (tint).
- **Backgrounds.** Flat token fills — **no gradients, no photographic imagery, no patterns or textures.** Depth comes from surface layering (canvas → muted → surface → raised) and shadow, not decoration.
- **Elevation system.** Light uses soft blue-grey drop shadows (`shadow-sm` / `shadow-card` / `shadow-lg`) and a colored glow under the FAB (`shadow-fab`). Dark trades drop shadows for hairline rings + deep ambient shadow.
- **Borders.** Hairline `--memox-border`; chips/outline buttons use inset box-shadow rings so they don't shift layout. Dividers are low-alpha (`--memox-divider`).
- **Hover / press / focus.** Hover = subtle state overlay (`--memox-state-hover`) or a one-step-darker primary. Press = scale down (`0.94–0.97`) — a tactile Material-ish squash. Focus = 3px `--memox-focus-ring` halo. Transitions are quick (120–180ms) and eased; **no bounce, no long animations.** The bottom-nav active item slides a tinted pill behind its icon; the switch thumb grows as it travels.
- **Transparency & blur.** Used sparingly — soft tints (`*-soft` tokens at ~10–18% alpha) for containers and state layers; scrim/overlay for modals. No glassmorphism.
- **Layout rules.** Fixed top app bar (compact 64px, or 132px large/hero), fixed bottom nav (72px), FAB parked above the nav at the screen's right gutter; the body scrolls between them.

---

## ICONOGRAPHY

- **System:** [Material Symbols Rounded](https://fonts.google.com/icons) (variable icon font, weight 400, FILL 0), loaded from the Google Fonts CDN. Rounded fits the soft radii of the system. Used via ligatures: `<span class="material-symbols-rounded">style</span>`.
- **Why CDN:** MemoX is a Material-3 app; Material Symbols is its native icon language. No proprietary icon set was available to copy from the references, so the canonical Google set is used directly (not a substitute). If you later add a custom/offline icon set, document it here and self-host it.
- **Common glyphs:** `today`, `style`, `add_circle`, `insights`, `person` (nav); `schedule`, `local_fire_department`, `bolt`, `check_circle` (dashboard); `search`, `tune`, `swap_vert` (library); `visibility`, `touch_app`, `celebration` (study); `dark_mode`, `notifications`, `volume_up`, `chevron_right` (settings).
- **Emoji:** never used in UI. **Unicode** is used only for true content (e.g. the Japanese sample card 勉強) and the middot separator "·".
- **Brand mark:** there is currently **no logo asset** — the MemoX wordmark is set in Plus Jakarta Sans Extrabold. See caveats.

---

## Index / manifest

- **`styles.css`** — global entry; `@import`s tokens then components. Consumers link this one file.
- **`tokens/`** — `colors.css` (light+dark roles), `typography.css` (+ `@font-face`), `spacing.css`, `radius.css`, `elevation.css`.
- **`components.css`** — Layer-2 styling for every `Mx*` base class.
- **`components/`**
  - `surfaces/` — **MxScaffold** (`app`), **MxAppBar** (`appbar`/`appbar-lg`), **MxCard** (`card`), **MxSectionHeader** (`section-head`), **MxIconTile** (`icon-tile`)
  - `navigation/` — **MxBottomNav** (`bottom-nav`), **MxFab** (`fab`), **MxSearchDock** (`search-dock`), **MxIconButton** (`icon-btn`)
  - `core/` — **MxButton** (`btn` + primary/secondary/outline/ghost), **MxChip** (`chip`), **MxBadge** (`badge`), **MxSwitch** (`switch`), **MxSegmentedControl** (`segmented`), **MxAvatar** (`avatar`)
- **`guidelines/`** — foundation specimen cards (Colors / Type / Spacing) shown on the Design System tab.
- **`ui_kits/memox-app/`** — the screen gallery (23 screens × states × light/dark).
- **`fonts/`** — Plus Jakarta Sans variable TTF.
- **`SKILL.md`** — Agent-Skill manifest for use in Claude Code.

Namespace for `@dsCard` / kit HTML: `window.MemoXDesignSystem_2ffa54`.

---

## Caveats

- **No brand logo / app icon asset** was provided or available to copy — the wordmark is currently just Extrabold type. **Please share a MemoX logo / app-icon** if one exists.
- The **Tokyo palette** was used verbatim as token values. If MemoX has its own brand hues, send them and only the token *values* need to change.
- Screens use **realistic placeholder** copy and data, per the initialization brief — no real content, navigation, or validation yet.
