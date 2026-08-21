# Design Kit colour audit — Material Design 3 token architecture

Audited 2026-08-21 against the current M3 colour-role set (including the
`*Fixed` family and the `surfaceContainer` ladder; `background`, `onBackground`
and `surfaceVariant` treated as deprecated per Flutter 3.22+).

**Scope.** Both halves of the kit:

- **Flutter** — `lib/core/theme/` (`app_colors.dart`, `app_material_roles.dart`,
  `app_theme.dart`, `app_semantic_colors.dart`, `app_interaction_states.dart`,
  component themes) and every consumer under `lib/`, `widgetbook/`, `e2e/`.
- **CSS kit** — `design_system/tokens/colors.css` and
  `design_system/components/mx.css`.

Contrast ratios below are computed (WCAG 2.x relative luminance), not quoted.
No design changes were made; this is inspection only.

---

## Token audit table

Statuses: **PASS** / **MISSING** / **INCORRECT** / **DEPRECATED** / **HARDCODED**.

### 1 · Reference / primitive layer

| Layer | Canonical M3 Token | Current Kit Token | Light Value | Dark Value | Used By | Status | Issue |
|---|---|---|---|---|---|---|---|
| Ref | primary tonal palette (T0–T100) | — (seed `AppColors.seed` `#4646B4` only) | — | — | `ColorScheme.fromSeed` (immediately overridden) | MISSING | No HCT tonal palettes exist. Every role is a hand-tuned OKLCH constant. Deliberate (documented in `app_colors.dart`), but there is no primitive layer to derive new roles from. |
| Ref | secondary tonal palette | — | — | — | — | MISSING | Same. |
| Ref | tertiary tonal palette | — | — | — | — | MISSING | Same. |
| Ref | neutral tonal palette | — | — | — | — | MISSING | Surface ladder values are hand-tuned per rung (L\* 3.9→10.2→16.9→24.0 dark). |
| Ref | neutral-variant tonal palette | — | — | — | — | MISSING | Same. |
| Ref | error tonal palette | — (`danger` constants) | — | — | — | MISSING | Same. |
| Ref | (CSS) base literals | `--mx-page/card/inset/raised/ink/line/indigo/…` | per hue | per hue | `colors.css` semantic layer | PASS | Two-stop (light/dark) primitives, not tonal palettes — a naming layer, not a derivation layer. |

### 2 · System / semantic layer (M3 colour roles)

Light/dark values are what `buildLightTheme()` / `buildDarkTheme()` actually
install on `ColorScheme`.

| Layer | Canonical M3 Token | Current Kit Token | Light Value | Dark Value | Used By | Status | Issue |
|---|---|---|---|---|---|---|---|
| Sys | primary | `AppColors.primary*` | `#4646B4` | `#5656C9` | FilledButton/FAB fill, nav indicator ink (light), stepper, state layers | PASS | Dark value is 3.29:1 as bare text on the page — intentional; text use is routed to `primaryAccent` (6.26:1). |
| Sys | onPrimary | `AppColors.onPrimary*` | `#FFFFFF` | `#FFFFFF` | Filled button/FAB labels | PASS | 7.51:1 / 5.88:1 on primary. |
| Sys | primaryContainer | `AppMaterialRoles.primaryContainer*` | `#DCDCF2` | `#2B2B6E` | NavigationBar indicator, deck icon well, deck summary metrics | PASS | |
| Sys | onPrimaryContainer | `AppMaterialRoles.onPrimaryContainer*` | `#1B1B5C` | `#D7D5FF` | deck status icon, `brandInk()` in dark | PASS | 11.46:1 / 8.87:1. |
| Sys | primaryFixed | mapped to `primaryContainerLight` | `#DCDCF2` | `#DCDCF2` | none (declared only) | PASS | Brightness-independent as M3 defines; no consumer yet. |
| Sys | primaryFixedDim | mapped to `primaryContainerLight` | `#DCDCF2` | `#DCDCF2` | none | INCORRECT | Identical to `primaryFixed`. M3 defines FixedDim as a distinctly darker tone (T80 vs T90). Harmless today (no consumer), wrong the day a component reads it. |
| Sys | onPrimaryFixed | mapped to `onPrimaryContainerLight` | `#1B1B5C` | `#1B1B5C` | none | PASS | 11.46:1 on fixed. |
| Sys | onPrimaryFixedVariant | mapped to `primaryLight` | `#4646B4` | `#4646B4` | none | PASS | ~5.6:1 on fixed. |
| Sys | secondary | `AppMaterialRoles.secondary*` | `#4E5468` | `#B8B7D0` | (via container pair) | PASS | Dark moved to page hue family at M4.10aa; R3 hue-distance test pins it. |
| Sys | onSecondary | `AppMaterialRoles.onSecondary*` | `#FFFFFF` | `#1E2033` | — | PASS | 7.52:1 / 8.19:1. |
| Sys | secondaryContainer | `AppMaterialRoles.secondaryContainer*` | `#E4E6EC` | `#332F58` | Tonal buttons, selected chips/pills, card selection bar, selected `ListTile` | PASS | |
| Sys | onSecondaryContainer | `AppMaterialRoles.onSecondaryContainer*` | `#2C3141` | `#D9DCE7` | same consumers | PASS | 10.37:1 / 9.09:1. |
| Sys | secondaryFixed | mapped to `secondaryContainerLight` | `#E4E6EC` | `#E4E6EC` | none | PASS | |
| Sys | secondaryFixedDim | mapped to `secondaryContainerLight` | `#E4E6EC` | `#E4E6EC` | none | INCORRECT | Duplicate of `secondaryFixed` (same defect as primaryFixedDim). |
| Sys | onSecondaryFixed | mapped to `onSecondaryContainerLight` | `#2C3141` | `#2C3141` | none | PASS | |
| Sys | onSecondaryFixedVariant | mapped to `secondaryLight` | `#4E5468` | `#4E5468` | none | PASS | |
| Sys | tertiary | `AppMaterialRoles.tertiary*` | `#45647F` | `#8DB4D8` | card-import flow accents | PASS | `tertiaryDark` deliberately equals `info` dark — the palette's one blue. Seed-generated pink tertiary was caught and overridden. |
| Sys | onTertiary | `AppMaterialRoles.onTertiary*` | `#FFFFFF` | `#17232E` | — | PASS | 6.21:1 / 7.33:1. |
| Sys | tertiaryContainer | `AppMaterialRoles.tertiaryContainer*` | `#E1E9F0` | `#33465A` | import preview summary | PASS | |
| Sys | onTertiaryContainer | `AppMaterialRoles.onTertiaryContainer*` | `#22394B` | `#D5E0EA` | — | PASS | 9.75:1 / 7.24:1. |
| Sys | tertiaryFixed | mapped to `tertiaryContainerLight` | `#E1E9F0` | `#E1E9F0` | none | PASS | |
| Sys | tertiaryFixedDim | mapped to `tertiaryContainerLight` | `#E1E9F0` | `#E1E9F0` | none | INCORRECT | Duplicate of `tertiaryFixed`. |
| Sys | onTertiaryFixed | mapped to `onTertiaryContainerLight` | `#22394B` | `#22394B` | none | PASS | |
| Sys | onTertiaryFixedVariant | mapped to `tertiaryLight` | `#45647F` | `#45647F` | none | PASS | |
| Sys | error | `AppColors.danger*` | `#C02B3A` | `#F2808F` | TextField error border, destructive buttons, error states | PASS | One red system: `error` **is** `danger`, by decision, not by accident. |
| Sys | onError | `AppMaterialRoles.onError*` | `#FFFFFF` | `#2C1319` | — | PASS | 5.76:1 / 6.80:1. |
| Sys | errorContainer | `AppMaterialRoles.errorContainer*` | `#F8DDE1` | `#5E2831` | reminder banner, search footer, tag rename, card history | PASS | |
| Sys | onErrorContainer | `AppMaterialRoles.onErrorContainer*` | `#641421` | `#F5D3D8` | same consumers | PASS | 9.87:1 / 8.33:1. |
| Sys | surface | `AppColors.surface*` | `#FBFBFE` | `#1A1838` | Card, Dialog, BottomSheet, chips | PASS | The **page** is *not* `surface`: `scaffoldBackgroundColor` is `AppColors.background*` (`#F4F5F8`/`#0A082D`), which has **no `ColorScheme` slot** — see §B. |
| Sys | onSurface | `AppColors.textPrimary*` | `#16182B` | `#EDEDF6` | body text, ListTile text, AppBar fg | PASS | 16.95:1 / 14.65:1. |
| Sys | onSurfaceVariant | `AppColors.textSecondary*` | `#565C72` | `#A8A7C4` | icons (global IconTheme), quiet text, dialog body | PASS | 6.41:1 / 7.30:1 on surface; 5.26:1 / 5.32:1 on `surfaceContainerHighest`. |
| Sys | surfaceDim | `AppMaterialRoles.surfaceDim*` | `#DEE0E7` | `#0B0327` | none directly | PASS | Declared; dark value ≈ the page (`#0A082D`), plausibly the page's ladder slot. |
| Sys | surfaceBright | `AppMaterialRoles.surfaceBright*` | `#FCFCFE` | `#37345F` | none directly | PASS | = `surfaceElevated` semantic token. |
| Sys | surfaceContainerLowest | `AppMaterialRoles.surfaceContainerLowest*` | `#FCFCFE` | `#0A0326` | guess option rows, match tiles | PASS | |
| Sys | surfaceContainerLow | `AppMaterialRoles.surfaceContainerLow*` | `#FAFAFC` | `#151134` | fill-answer pieces, recall timer | PASS | |
| Sys | surfaceContainer | `AppMaterialRoles.surfaceContainer*` | `#F1F2F6` | `#221E44` | none directly | PASS | |
| Sys | surfaceContainerHigh | `AppMaterialRoles.surfaceContainerHigh*` | `#EAECF1` | `#28254B` | import stepper/context/source steps | PASS | = `surfaceMuted` semantic token. |
| Sys | surfaceContainerHighest | `AppMaterialRoles.surfaceContainerHighest*` | `#E3E5EC` | `#332F58` | linear progress track (theme) | PASS | Dark value = `secondaryContainerDark` (documented, ladder-aligned). |
| Sys | outline | `AppColors.borderSubtle*` | `#D2D2DD` | `#4C487A` | Card/Dialog border, dividers, drag handle | INCORRECT | 1.45:1 / 2.04:1 on surface. M3's `outline` is the *stronger* stroke (~T50, the one asked to clear 3:1 for component boundaries). The kit's 3:1 stroke exists — `borderControl` (`#8D8D95`/`#66628D`, 3.19:1 / 3.00:1) — but lives **outside** `ColorScheme`, so `scheme.outline` under-delivers for any Material component that reads it. |
| Sys | outlineVariant | `AppColors.borderSubtle*` (same value) | `#D2D2DD` | `#4C487A` | same | INCORRECT | Degenerate: `outline == outlineVariant`. M3 defines them as a two-tier pair (strong/decorative); the kit collapses both onto the decorative tier. |
| Sys | inverseSurface | `AppMaterialRoles.inverseSurface*` | `#2A2C3E` | `#E7E8F0` | SnackBar background | PASS | |
| Sys | onInverseSurface | `AppMaterialRoles.onInverseSurface*` | `#F1F2F6` | `#23253A` | SnackBar text | PASS | 12.28:1 / 12.31:1. |
| Sys | inversePrimary | `AppMaterialRoles.inversePrimary*` | `#A9A9E0` | `#3A3A9B` | none (declared) | PASS | 6.18:1 / 7.62:1 on inverseSurface. |
| Sys | shadow | `AppColors.shadow*` | `#0B0C18` | `#04040B` | `AppElevation.shadowsFor` | PASS | Seed-tinted, both modes; dark opts out of painting shadows (measured ΔL\* 0.26). |
| Sys | scrim | `AppColors.scrim*` | `#0B0C18` | `#04040B` | `modalBarrierColor` for Dialog/BottomSheet | PASS | Alpha applied at use site (overlay exemption to the solids rule). |
| Sys | surfaceTint | `primaryLight` / `surfaceElevatedDark` | `#4646B4` | `#37345F` | suppressed (`surfaceTintColor: transparent` on Card/Dialog/Sheet/NavBar) | INCORRECT | Canonical M3: `surfaceTint = primary` in both modes. Dark deviates deliberately (documented: tone-80 lavender tint would undo the navy canvas). Low risk because every themed component disables tinting — but an unthemed elevated widget in dark will tint toward a surface colour, not the brand. |

### 3–7 · Deprecated roles, component tokens, states, themes (summary rows)

| Layer | Canonical M3 Token | Current Kit Token | Light Value | Dark Value | Used By | Status | Issue |
|---|---|---|---|---|---|---|---|
| Sys | ~~background~~ (deprecated) | not set, not read | — | — | — | PASS | Correctly avoided in Dart. Page colour handled outside the scheme (see §B). CSS kit still *names* a token `--color-background` — a naming echo only. |
| Sys | ~~onBackground~~ (deprecated) | not set, not read | — | — | — | PASS | Avoided. |
| Sys | ~~surfaceVariant~~ (deprecated) | not set, not read | — | — | — | PASS | Avoided; `surfaceContainerHighest` used instead (progress track). |
| Comp | component → system references | `context.colors.*` / `context.semanticColors.*` | — | — | all of `lib/` | PASS | **Zero** raw `Color(0x…)` literals outside `lib/core/theme/`; only Material `Colors.*` use is `Colors.transparent`; one alpha-modified token in features (`match_tile_widget.dart:255`, borderControl fade). Error screen reads `AppColors` constants directly — justified (renders above/without `MaterialApp`). |
| Comp | CSS components → tokens | `var(--color-*)` throughout `mx.css` | — | — | design_system HTML kit | PASS | One raw hex in `mx.css` and it is inside a comment. `--color-surface-bg` is a documented per-context override hook with a `var()` fallback, not a broken reference. |
| State | hover / focus / pressed layers | `AppStateOpacity` + `AppInteractionStates` | 4–12% washes | same | buttons, chips, cards, rows, icons, ThemeData fallbacks | PASS | Deviates from M3's canonical 8/10/10% single-scale on purpose (per-surface weights transcribed from `mx.css`); filled buttons use *blends* not overlays so the state is actually visible on an accent fill. |
| State | selected | `secondaryContainer` pair + `brandInk()` | — | — | chips, nav bar, ListTile | PASS | Selected+disabled compound handled explicitly in chip theme. |
| State | disabled | `disabledSurface` / `onDisabled` | `#E0E0E5` / 38% ink | `#33324F` / 38% ink | buttons, chips, inputs, icon buttons | PASS | Solids by rule R7 (no paint-time compositing) except `onDisabled`, translucent for its three grounds. |
| State | dragged | — | — | — | — | MISSING | No dragged state layer anywhere; `AppElevation` reserves a slot but no wash/token exists. Low priority (no drag-reorder UI ships), but the M3 state set is incomplete. |
| Theme | light/dark mappings | full `copyWith` per brightness | all roles | all roles | `buildLightTheme` / `buildDarkTheme` | PASS | Every role declared in both modes; `AppSemanticColors` is a `ThemeExtension` with full `lerp`, so theme animation cannot snap. |

---

## A. Current token architecture

Four layers, three of them in Dart:

1. **`AppColors`** (`app_colors.dart`) — ~40 hand-tuned constants, named by
   meaning (`danger`, `surfaceMuted`, `borderSubtle`), one per brightness.
   This is the closest thing to a reference layer, but the values are
   *decisions*, not palette derivations — there are no tonal palettes.
2. **`AppMaterialRoles`** (`app_material_roles.dart`) — the M3 slots the app
   declares *only* so `ColorScheme.fromSeed` cannot invent them (it had
   generated a pink tertiary, a grey container ladder and a second red before
   an audit caught it). Split from `AppColors` along a documented seam: "what
   a colour means here" vs "what Material will draw if nobody says".
3. **`ColorScheme`** — built in `app_theme.dart` via `fromSeed(...).copyWith(…)`
   with **every** role overridden, both brightnesses.
4. **`AppSemanticColors`** (`ThemeExtension`) — 18 roles `ColorScheme` has no
   slot for: `success`, `warning`, `info`, `primaryAccent`, `borderControl`,
   `focusRing`, `progressTrack/Fill`, `streakContainer` pair, `disabledSurface`,
   `onDisabled`, `secondaryAction`, `surfaceMuted/Elevated`, `borderAccent/Subtle`.
   Reached via `context.semanticColors`; throws if unregistered.

Access is funnelled through `ThemeContextX` (`context.colors` /
`context.texts` / `context.semanticColors`), which makes bypasses greppable.
Interaction states live in `AppStateOpacity` (alphas transcribed from `mx.css`,
selector named per constant) and `AppInteractionStates` (four
`WidgetStateProperty` shapes: control, icon, card, row). The CSS kit
(`design_system/tokens/colors.css`) mirrors the same values as `--mx-*` base
literals re-pointed by `[data-theme="dark"]`, and is declared authoritative for
the eight status hues (M4.10p). An in-repo conformance audit
(`test/design_audit/`, analyzer-based, 657 files / 484 colour sites / 0
violations) already enforces the component layer.

## B. Missing M3 tokens

1. **The entire reference layer.** No tonal palettes for
   primary/secondary/tertiary/neutral/neutral-variant/error — only a seed and
   hand-tuned endpoints. Consequence: a new role (e.g. a real `primaryFixedDim`)
   cannot be *derived*; someone must hand-tune it and re-run the contrast tests.
2. **Distinct `*FixedDim` values** — `primaryFixedDim`, `secondaryFixedDim`,
   `tertiaryFixedDim` are byte-identical to their `*Fixed` partners.
3. **A scheme slot for the page.** The scaffold ground (`#F4F5F8`/`#0A082D`)
   exists only as `AppColors.background*` outside `ColorScheme`. M3 maps a
   page onto the surface ladder (typically `surface` or `surfaceContainerLow`/
   `surfaceDim`); here `scheme.surfaceDim` dark (`#0B0327`) is within 1 L\* of
   the page but is not the page. Any third-party widget that paints
   `scheme.surface` expecting "the page" gets the card colour.
4. **`dragged` state layer** — no token, no wash (M3 state set incomplete).
5. **CSS kit gaps vs the Dart kit:** no `--color-border-control` (the 3:1
   WCAG 1.4.11 stroke exists only in Dart), no `*-fixed` family, no
   `--color-on-streak-container` (Dart had to derive one, see §C.4).

## C. Incorrect semantic mappings

1. **`outline` / `outlineVariant` are the same token** (`borderSubtle`), and it
   is the *weak* tier (1.45:1 light / 2.04:1 dark on surface). M3's contract is
   a two-tier pair; the strong tier the spec expects from `outline` is what the
   kit calls `borderControl` (3.19:1 / 3.00:1) — parked outside the scheme.
   Any Material or third-party component reading `scheme.outline` to draw a
   component boundary silently fails WCAG 1.4.11.
2. **`surfaceTint` dark = `surfaceElevatedDark`**, not `primary`. Deliberate
   and documented, and every themed component sets `surfaceTintColor:
   transparent` — but it is a non-canonical mapping with a real edge case
   (unthemed elevated widgets in dark).
3. **`*FixedDim` ≡ `*Fixed`** (see §B.2) — a wrong value, not just a missing
   one, since the role is populated.
4. **Cross-kit drift (CSS vs Dart), already known in-repo:**
   - `--color-disabled-surface` `#E3E3E6`/`#312E4E` vs Dart `#E0E0E5`/`#33324F`
     — stale transcription (~3/255 off, recorded under M4.10an).
   - `--color-streak` `#C2731B` as the due-chip label measures **3.12:1** on its
     own light container — under the 4.5:1 small text needs. Dart corrected it
     (`onStreakContainerLight #7A4A10`, 6.38:1) but the CSS kit still carries
     the failing pairing.
   - The design system's readme claim "danger carries the most saturation" is
     contradicted by its own values (warning 0.801 > success 0.766 > danger
     0.634 in light) — internal inconsistency, values authoritative.

## D. Hard-coded colours

Effectively none in the app layer:

- `lib/` outside `lib/core/theme/`: **zero** `Color(0x…)` / `Color.fromARGB` /
  `Color.fromRGBO` literals; the only Material `Colors.*` reference is
  `Colors.transparent`.
- One alpha-modified token in features
  (`match_tile_widget.dart:255` — `borderControl.withValues(...)`), the kind of
  overlay the kit's own R7 rule exempts.
- `error_screen_widget.dart` reads `AppColors` constants directly rather than
  the theme — deliberate and correct (it must render where no `Theme` exists);
  they are the real tokens, not copies.
- The theme layer itself holds 99 literal sites (per `design_audit/`), which is
  where literals are supposed to live.
- `mx.css`: no raw hex outside comments; component CSS files do not exist
  separately (JSX components consume `var(--color-*)`).

## E. Deprecated tokens

- Dart: **none**. `ColorScheme.background`, `onBackground` and `surfaceVariant`
  are neither written in the `copyWith` blocks nor read anywhere in `lib/`,
  `widgetbook/` or tests. `onSurfaceVariant` (still canonical) is used
  correctly. The progress track already uses `surfaceContainerHighest`, the
  Flutter-recommended replacement for `surfaceVariant`.
- CSS: `--color-background` survives as a *name* for the page ground. In CSS
  there is no deprecation, but if the kits are meant to share a vocabulary the
  M3-aligned name would be a surface-ladder one (see §G).

## F. Components bypassing semantic tokens

None found. Every widget reaches colour through `context.colors` (ColorScheme)
or `context.semanticColors` (extension); component themes (`app_button_themes`,
`app_chip_theme`, `app_input_theme`, `app_navigation_bar_theme`,
`app_overlay_themes`, `app_radio_theme`) reference scheme/semantic roles
exclusively, and the framework fall-throughs (`hoverColor`, `focusColor`,
`highlightColor`, `splashColor`, `iconTheme`) are re-seeded so even *unthemed*
widgets degrade to house tokens instead of Material's hardcoded
black-and-white. Presentation mappings that could have minted new colours
(card-state dots) instead reuse existing semantic roles
(`info`/`warning`/`primaryAccent`/`success`). The one structural bypass is
architectural, not a component's fault: the page colour itself bypasses
`ColorScheme` (§B.3).

## G. Recommended target token architecture

No visual changes implied — items 1–4 are re-mappings and value fixes; 5–7 are
hygiene. **Do not implement until the audit is signed off.**

1. **Fix the outline pair.** `scheme.outline ← borderControl`
   (`#8D8D95`/`#66628D`), `scheme.outlineVariant ← borderSubtle`. Audit the
   ~15 `outline`-consuming sites first (Card/Dialog borders currently expect
   the subtle tier — they should read `outlineVariant` after the swap, which
   is also the M3-canonical role for decorative hairlines).
2. **Give the page a scheme slot.** Either alias the page onto the ladder
   (`surfaceDim` dark is already within 1 L\*; light would need
   `surfaceDim ≈ #F4F5F8` or a documented decision that the page stays a
   constructor parameter) — or document `background` as intentionally
   scheme-external. Today it is neither aliased nor documented as a deviation.
3. **Populate `*FixedDim` with real dim tones** (or, if the family is to stay
   unused, pin a test asserting no component reads it — the same trap the pink
   tertiary fell into is documented in the kit's own comments).
4. **Reconcile CSS ↔ Dart drift:** update `--color-disabled-surface` to
   `#E0E0E5`/`#33324F`; add `--color-on-streak-container`
   (`#7A4A10`/`#E0B064`) and stop pairing `--color-streak` with its container
   as text; add `--color-border-control`; consider renaming
   `--color-background` → `--color-page` (or a surface-ladder name) so the
   deprecated M3 word disappears from the shared vocabulary.
5. **Decide `surfaceTint` dark on the record.** Either keep
   `surfaceElevatedDark` and add a test that every elevated component suppresses
   tinting, or set it to `primary` and rely on the existing per-component
   `surfaceTintColor: transparent`.
6. **Add a `dragged` state alpha** to `AppStateOpacity` when the first
   drag-reorder surface ships (M3 default: 16% on-color).
7. **Optionally add a reference layer** — a documented tone scale per family
   (even a partial one: the tones actually used) so future roles are derived
   rather than hand-tuned, and the `design_audit` tooling can assert
   role-to-tone conformance instead of only role-to-value.

---

*Sources inspected: `lib/core/theme/*` (22 files), all `lib/` consumers,
`design_system/tokens/colors.css`, `design_system/components/mx.css`,
`design_audit/` reports, `widgetbook/`, `e2e/`, `integration_test/`.*
