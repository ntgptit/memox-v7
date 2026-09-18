# MemoX v3 — Flutter Theme Implementation Prerequisite (spec record)

> Transcribed from the owner's handoff message of 2026-09-18. Every table below
> is a generated view over two sources — `themeRegistry` (theme semantic
> binding) and `widgets[*].themeRoleUsage` (component theme consumption). This
> file keeps **one copy of each fact**; the handoff's duplicate views
> ("Foundation semantic role disposition — complete", per-kind bullet lists) are
> folded into the tables here. Values are verbatim.

**Run order:** FOUNDATIONS → **THIS** → shared components → screens. This is not
a design layer; it binds Foundations to ONE common Flutter theme. No shared
component task is runnable until it is done.

`FOUNDATIONS` stays authoritative for typography, spacing, geometry, sizing and
motion. This step binds those values; it does not author them.

---

## 1. Repository inspection — first

Identify the current `ThemeData` construction, light/dark `ColorScheme`,
`TextTheme`, theme extensions / semantic-colour layers, spacing/radius/sizing
token classes, Material component-theme configuration and shared-widget
theming conventions. **Reuse and extend the canonical implementation.** Do not
create a parallel theme system. Do not replace a larger canonical role set with
this smaller V3-specific palette.

## 2. Theme architecture rules

1. Standard Material colour semantics resolve through `ColorScheme`.
2. MemoX product semantic colours Material has no honest role for resolve
   through ONE semantic-colour mechanism the repository already has (smallest
   compatible extension only if none exists). This covers
   `MEMOX_SEMANTIC_COLOR` only — `DERIVED_COLOR` → central derivation,
   `DECORATION` → decoration/token mechanism, `STATE_TOKEN` → global state
   policy, `EFFECT_TOKEN` → effect mechanism, `M3_ALIAS` → its `ColorScheme`
   role.
3. Typography resolves through the shared `TextTheme` / canonical typography.
4. Spacing, radius, control dimensions, icon sizes, touch minimum → design-token
   system, never `ColorScheme`.
5. Component-specific geometry stays in the component contract; screen
   arrangement stays in the screen composition.
6. If V3 does not determine a role the repository already defines, PRESERVE the
   existing canonical definition. Do not invent a V3 colour to fill it; do not
   delete the role. Report what you preserved.

## 3. Runtime theme size control

Do NOT create a theme field for every Foundation semantic. The design registry
is deliberately larger than the runtime extension.

| Disposition | Count | Meaning |
|---|---:|---|
| `BIND_NOW` | 24 | Current V3 implementation needs them; the common theme must be able to provide them |
| `PRESERVE_ONLY` | 19 | No active V3 consumer path. Keep documented, preserve an existing repo definition if present, **add no new unused field** |

`BIND_NOW` does NOT mean "put it in the MemoX semantic extension" — each
semantic is routed by its KIND. This rule never shrinks the canonical M3
`ColorScheme` role set.

## 4. Standard M3 `ColorScheme` — complete canonical role set

`V3_DEFINED` — the design owns the value. `REPO_PRESERVED` — V3 says nothing;
keep the repository's canonical definition, invent nothing, delete nothing.
None of these may be copied into a custom semantic layer, a widget constant or
a local hex.

| Role | Disposition | Light | Dark |
|---|---|---|---|
| `primary` | V3_DEFINED | `#5265F5` | `#8B9AFF` |
| `onPrimary` | V3_DEFINED | `#FFFFFF` | `#11173A` |
| `primaryContainer` | V3_DEFINED | `#E0E5FE` | `#2D346A` |
| `onPrimaryContainer` | V3_DEFINED | `#1A2580` | `#D9DFFF` |
| `secondary` | V3_DEFINED | `#6E7CD9` | `#9DA8E8` |
| `onSecondary` | V3_DEFINED | `#FFFFFF` | `#1A2150` |
| `secondaryContainer` | V3_DEFINED | `#E3E6F7` | `#343C78` |
| `onSecondaryContainer` | V3_DEFINED | `#262E6E` | `#DDE2FB` |
| `tertiary` | V3_DEFINED | `#8B6FF5` | `#B5A0FF` |
| `onTertiary` | V3_DEFINED | `#FFFFFF` | `#240B63` |
| `tertiaryContainer` | V3_DEFINED | `#EBE3FE` | `#443078` |
| `onTertiaryContainer` | V3_DEFINED | `#33177E` | `#E6DCFF` |
| `error` | V3_DEFINED | `#DC2D4E` | `#FF8FA3` |
| `onError` | V3_DEFINED | `#FFFFFF` | `#52061B` |
| `errorContainer` | V3_DEFINED | `#FBDDE3` | `#7A2036` |
| `onErrorContainer` | V3_DEFINED | `#7A0A23` | `#FFD9DF` |
| `primaryFixed` … `onTertiaryFixedVariant` (12 roles) | REPO_PRESERVED | keep repository definition | keep repository definition |
| `surfaceDim` | V3_DEFINED | `#DAE0EF` | `#060925` |
| `surface` | V3_DEFINED | `#F7F9FE` | `#0A0E27` |
| `surfaceBright` | V3_DEFINED | `#FFFFFF` | `#232B5A` |
| `surfaceContainerLowest` | V3_DEFINED | `#FFFFFF` | `#131A3A` |
| `surfaceContainerLow` | V3_DEFINED | `#F1F4FB` | `#1B2249` |
| `surfaceContainer` | V3_DEFINED | `#E9EDF7` | `#232B5A` |
| `surfaceContainerHigh` | V3_DEFINED | `#E2E7F3` | `#2C356E` |
| `surfaceContainerHighest` | V3_DEFINED | `#DAE0EF` | `#353D7E` |
| `onSurface` | V3_DEFINED | `#0F1638` | `#E4E8FA` |
| `onSurfaceVariant` | V3_DEFINED | `#4A5278` | `#A4ACD0` |
| `outline` | V3_DEFINED | `#7C85AB` | `#5A6BAE` |
| `outlineVariant` | V3_DEFINED | `#C5CBE3` | `#2A3267` |
| `inverseSurface` | V3_DEFINED · `invariant: true` | `#34395D` | `#34395D` |
| `onInverseSurface` | V3_DEFINED · `invariant: true` | `#E8EAFC` | `#E8EAFC` |
| `inversePrimary` | V3_DEFINED | `#8B9AFF` | `#5265F5` |
| `scrim` | V3_DEFINED | `#0A0E27` | `#000000` |
| `shadow` | V3_DEFINED | `#0F1638` | `#000000` |

**Invariance** is scoped and asserted: exactly `inverseSurface` and
`onInverseSurface` carry `invariant: true`, and validation fails if either
differs between themes. Never read invariance off equal values or token names
(`mastery-fixed` flips: `#C7F2D8` / `#1F4A37`).

## 5. Registry — non-M3 entries (one row per semantic)

Usage: `DIRECT` = DIRECTLY_CONSUMED, `INDIRECT` = INDIRECTLY_CONSUMED, `UNUSED` =
FOUNDATION_DEFINED_UNUSED.

### 5.1 `MEMOX_SEMANTIC_COLOR` → repository semantic-colour mechanism

| Name | Usage | Runtime | Light | Dark | Consumers |
|---|---|---|---|---|---|
| `mastery` | INDIRECT | BIND_NOW | `#1F8A5B` | `#6FE0BD` | StudyTopBar progress fill, mode badge label, mode badge fill (passed as `accent`) |
| `success` | UNUSED | PRESERVE_ONLY | `#2BA88B` | `#6FE0BD` | derives `success-soft` |
| `warning` | UNUSED | PRESERVE_ONLY | `#F59E0B` | `#FFC658` | derives `warning-soft` |
| `on-warning` | UNUSED | PRESERVE_ONLY | `#3A2A00` | `#2A1E00` | — |
| `streak` | UNUSED | PRESERVE_ONLY | `#F97316` | `#FFAE6E` | — |
| `on-streak` | UNUSED | PRESERVE_ONLY | `#FFFFFF` | `#FFFFFF` | — |
| `status-new` | DIRECT | BIND_NOW | `#8C95B8` | `#6B75A3` | StatusBadge.new dot, label, container · TINT 12% |
| `status-learning` | DIRECT | BIND_NOW | `#F59E0B` | `#FFC658` | StatusBadge.learning dot+label, container · TINT 12%; MasteryRamp `< 34%` fill |
| `status-reviewing` | DIRECT | BIND_NOW | `#5265F5` | `#8B9AFF` | StatusBadge.reviewing dot+label, container · TINT 12%; MasteryRamp `34–66%` fill |
| `status-mastered` | DIRECT | BIND_NOW | `#1F8A5B` | `#6FE0BD` | StatusBadge.mastered dot+label, container · TINT 12%; MasteryRamp `≥ 67%` fill |
| `error-fill` | DIRECT | BIND_NOW | `#DC2D4E` | `#B0485C` | Button.destructive tone container |
| `on-error-fill` | DIRECT | BIND_NOW | `#FFFFFF` | `#FFFFFF` | Button.destructive tone label + glyph |
| `mastery-fixed` | UNUSED | PRESERVE_ONLY | `#C7F2D8` | `#1F4A37` | — |
| `on-danger` | UNUSED | PRESERVE_ONLY | `#FFFFFF` | `#2A0A12` | — |
| `text-muted` | UNUSED | PRESERVE_ONLY | `#7C85AB` | `#5A6BAE` | — |

Do not overload `primary`/`secondary`/`tertiary` to avoid a semantic role
(`tertiary` is the violet accent; green means mastery). Do not introduce a
MemoX copy of a role the `ColorScheme` already owns. Two semantics may share an
authored value and still be two semantics.

### 5.2 `M3_ALIAS` → its `ColorScheme` role, no theme property of its own

Every alias carries both proofs: value equality in every theme AND semantic
equivalence. (That is why `on-danger` and `text-muted` are not aliases.)

| Name | Usage | Runtime | Resolves to | Light | Dark | Consumers / note |
|---|---|---|---|---|---|---|
| `bg` | DIRECT | BIND_NOW | `surface` | `#F7F9FE` | `#0A0E27` | AppShell page ground |
| `surface-muted` | DIRECT | BIND_NOW | `surfaceContainerLow` | `#F1F4FB` | `#1B2249` | TextField resting container; Note container |
| `surface-raised` | DIRECT | BIND_NOW | `surfaceContainerLowest` | `#FFFFFF` | `#131A3A` | Card container; Section row container; EmptyState / ErrorState container. No brightness branch |
| `progress-track` | DIRECT | BIND_NOW | `surfaceContainerHigh` | `#E2E7F3` | `#2C356E` | StudyTopBar progress track; MasteryRamp track |
| `badge-bg` | UNUSED | PRESERVE_ONLY | `surfaceContainer` | `#E9EDF7` | `#232B5A` | NOT the current badge fill (tonal badge tints its own tone at 12%) |
| `danger` | UNUSED | PRESERVE_ONLY | `error` | `#DC2D4E` | `#FF8FA3` | destructive foreground, product vocabulary |
| `text-primary` | UNUSED | PRESERVE_ONLY | `onSurface` | `#0F1638` | `#E4E8FA` | — |
| `text-secondary` | DIRECT | BIND_NOW | `onSurfaceVariant` | `#4A5278` | `#A4ACD0` | ChipTrigger label; Section overline |

### 5.3 `DERIVED_COLOR` → central derivation, each exactly once

A component consuming one applies NO percentage of its own (treatment
`FULL_STRENGTH`). `FULL_STRENGTH` is a TREATMENT; `DIRECT` is an ACCESS MODE.

| Name | Usage | Runtime | Light | Dark | Consumers / note |
|---|---|---|---|---|---|
| `primary-soft` | UNUSED | PRESERVE_ONLY | `primary` @ 10% over transparent | `primary` @ 20% | BottomNav pill (14/20%), IconTile (10/16%) and EmptyState tile (10/10%) each tint `primary` themselves — bind `primary` with an explicit component treatment; do not repoint them; no runtime field until the design collapses them |
| `primary-border` | UNUSED | PRESERVE_ONLY | `primary` @ 24% | `primary` @ 32% | — |
| `danger-soft` | DIRECT | BIND_NOW | `error` @ 8% over transparent | `error` @ 16% | ErrorState tile |
| `danger-border` | UNUSED | PRESERVE_ONLY | `error` @ 22% | `error` @ 32% | — |
| `success-soft` | UNUSED | PRESERVE_ONLY | `success` @ 10% | `success` @ 18% | — |
| `warning-soft` | UNUSED | PRESERVE_ONLY | `warning` @ 12% | `warning` @ 18% | — |
| `surface-hero` | DIRECT | BIND_NOW | `primary` @ 5% over `surfaceBright` (`color-mix(in srgb, #5265F5 5%, #FFFFFF)`) | `primary` @ 12% over `surface` (`color-mix(in srgb, #8B9AFF 12%, #0A0E27)`) | Card tinted hero variant. The base differs by theme |
| `chrome-glass` | DIRECT | BIND_NOW | `rgba(247, 249, 254, 0.84)` | `rgba(10, 14, 39, 0.84)` | BottomNav bar surface. `surface` @ alpha from `op-glass`, composited at paint time over the runtime backdrop — never pre-flattened |

### 5.4 `DECORATION` → decoration/token mechanism

Source token name ≠ canonical semantic name; bind the semantic. The THEME owns
treatment values; the COMPONENT contract owns which treatment it uses per theme
and state (e.g. Card: Light → card-whisper-shadow, Dark → hairline-edge).
`ThemeData` does not decide a component's behaviour.

| Token | Semantic | Usage | Runtime | Light | Dark | Consumers |
|---|---|---|---|---|---|---|
| `shadow-soft` | card-whisper-shadow | DIRECT | BIND_NOW | `0 1px 2px rgba(15,22,56,0.04)` | `none` | Card light edge; Toggle thumb elevation (dark draws the hairline instead) |
| `shadow-card` | overlay-shadow | DIRECT | BIND_NOW | `0 12px 32px rgba(15,22,56,0.10)` | `0 16px 40px rgba(0,0,0,0.42)` | Dialog elevation — **NOT the Card** |
| `shadow-chrome` | chrome-shadow | DIRECT | BIND_NOW | `0 -2px 12px rgba(15,22,56,0.05)` | `0 -2px 14px rgba(0,0,0,0.36)` | BottomSheet elevation; bottom chrome |
| `shadow-fab` | fab-shadow | DIRECT | BIND_NOW | `0 8px 24px rgba(15,22,56,0.12)` | `0 10px 28px rgba(0,0,0,0.5)` | FAB elevation |
| `shadow-none` | no-shadow | UNUSED | PRESERVE_ONLY | `none` | `none` | — |
| `border-ghost` | hairline-edge | DIRECT | BIND_NOW | `1px solid rgba(82, 101, 245, 0.14)` | `1px solid rgba(139, 154, 255, 0.16)` | BottomNav bar edge; Button chip variant border; FilterChip unselected border; SearchField resting border; TextField resting border; OptionRow divider; Card dark edge; Section row dividers; ListRow divider; Note border; SheetActions sheet top divider; FooterBar top divider |
| `border-strong` | strong-edge | UNUSED | PRESERVE_ONLY | `1px solid #C5CBE3` | `1px solid #2A3267` | 1px `outlineVariant` edge — a border shorthand, hence decoration |

### 5.5 `STATE_TOKEN` → global state policy (interaction states only; never a colour, never glass)

| Token | Usage | Runtime | Value (both themes) | Consumers |
|---|---|---|---|---|
| `op-disabled` | DIRECT | BIND_NOW | `0.38` | whole control · APPLY_TOKEN: Button, IconButton, FilterChip, TextField (whole field), Toggle, OptionRow (whole row), SettingsRow.dimmed (whole row) |
| `op-press` | DIRECT | BIND_NOW | `0.12` | state overlay · APPLY_TOKEN: Button, IconButton, FilterChip, OptionRow, ListRow |
| `op-hover` | UNUSED | PRESERVE_ONLY | `0.08` | — |

### 5.6 `EFFECT_TOKEN` → effect mechanism (not state, not colour)

| Token | Usage | Runtime | Value (both themes) | Note |
|---|---|---|---|---|
| `op-glass` | INDIRECT | BIND_NOW | `0.84` | glass opacity; `chrome-glass` references it, so `0.84` is authored once |
| `glass-blur` | DIRECT | BIND_NOW | `saturate(180%) blur(18px)` | BottomNav bar blur · EFFECT (blur). The web value is a NON-BINDING SOURCE TRACE: reproduce the glass INTENT with the repository or platform blur mechanism; keep the existing solid/translucent fallback where platform or performance disallows live blur. A colour role never owns blur |

### 5.7 Not theme fields — `COMPONENT_INPUT` and `NONE`

| Name | Kind | Note |
|---|---|---|
| `accent` | COMPONENT_INPUT | Per-instance prop. StudyTopBar defaults to `primary`; Recall/Fill sessions pass `mastery`. Consumers: StudyTopBar progress fill (FULL_STRENGTH), mode badge label (FULL_STRENGTH), mode badge fill (TINT 10%). Do NOT add an `accent` theme property |
| `seed` | COMPONENT_INPUT | Per-deck colour into IconTile (tile TINT 12%, glyph FULL_STRENGTH). ListRow forwards it unchanged. Do NOT put `seed` in the theme |
| `transparent` | NONE | No painted fill: Button outline tone container, IconButton ink box, ChipTrigger container (NO_FILL). No theme property |

## 6. Light / dark

Both themes are complete and first-class — Tokyo Pure Light and Tokyo Nebula.
Dark is authored, not a filter over light.

## 7. Typography / `TextTheme`

The same seven roles Foundations states — one scale, one source. Consumers
(Button, Card, ListRow, SettingsRow, every shared widget) create no text
styles of their own.

| Role | Size | Weight | Line height | Tracking | Usage |
|---|---:|---:|---:|---:|---|
| caption | 12 | 600 | 1.4 | `1.2px` | Overlines, metadata, chips, counts — hard 12px floor |
| body | 14 | 400 | 1.5 | 0 | Default running text |
| body large | 16 | 500 | 1.5 | 0 | List titles, emphasised body |
| title | 20 | 700 | 1.2 | `-0.64px` | Section and screen titles |
| headline | 24 | 700 | 1.2 | `-0.64px` | Screen headline |
| display | 32 | 800 | 1.1 | `-0.64px` | Hero figure |
| stat | 40 | 600 | 1.0 | `-0.64px` | Large metric, tabular numerals |

Component type treatments (e.g. AppBar content title `20 / 700 / -0.3px`,
Button label `14 / 600 / 0.1px`) are COMPONENT rows: a component-level override
of the nearest role, never a new global text style.

Design-source mapping to M3 rungs (`design_system/MemoX Design System/colors_and_type.css`):
caption = `bodySmall · labelMedium` (M3 `labelSmall` 11 → floor 12); body =
`bodyMedium · labelLarge · titleSmall`; body large = `bodyLarge · titleMedium`;
title = `titleLarge`; headline = `headlineSmall`; display = `displaySmall`;
stat = outside the M3 scale. One family: Plus Jakarta Sans.

## 8. Global state semantics

The GLOBAL layer owns exactly three things:

| State | Global rule |
|---|---|
| Disabled | Opacity `0.38` over the whole control — ONE value everywhere |
| Pressed | Platform state overlay at `op-press (0.12)` |
| Focused | `2px primary ring`, offset `2` — one treatment for every control |

Hover is web only; do not implement hover for Android. Selected / checked /
active are COMPONENT-owned (FilterChip fill `primary` + label `onPrimary`;
OptionRow thickens a ring; BottomNav tints a pill). Error presentation: the
theme owns the error colour semantics; the component owns border/message
placement (TextField, SearchField). A component spec references the three
global rules; it never redefines them.

## 9. Implementation sequence

1. Inspect the theme architecture. 2. Enumerate the complete canonical M3 role
set. 3. Reconcile V3_DEFINED / REPO_PRESERVED. 4–5. Build/reconcile light and
dark `ColorScheme`. 6. Verify the full canonical role set is still present.
7. Bind the exact Foundations typography to `TextTheme`. 8. Route each BIND_NOW
entry BY KIND (only BIND_NOW `MEMOX_SEMANTIC_COLOR` uses the semantic
mechanism; aliases resolve to `ColorScheme`; no field for PRESERVE_ONLY).
9. Bind DERIVED_COLOR centrally, once each. 10. Bind DECORATION centrally where
the token architecture allows. 11. Establish STATE_TOKEN policies (disabled,
pressed, focus); keep EFFECT_TOKEN out of them. 12. Configure Material
component-theme defaults only where they represent the V3 baseline accurately.
13. Validate the common theme on its own — Foundation semantic-role coverage,
every IMPLEMENT_COMPONENT theme usage, aggregate role-consumer consistency.
14. Freeze this prerequisite. 15. Only then start IMPLEMENT_COMPONENT tasks.

## 10. Ownership matrix

| Area | Owner |
|---|---|
| Standard Material colours | `ColorScheme` |
| MemoX semantic colours | One semantic theme mechanism |
| Derived colours | Central derivation in the theme layer |
| Typography | `TextTheme` / canonical typography |
| Global interaction states | Common state-token policy |
| Visual effect configuration | Effect/decoration token layer |
| Spacing / radius / sizing | Design-token system |
| Decoration, shadow, borders | Canonical decoration/token mechanism |
| Material global defaults | `ThemeData` component themes, where appropriate |
| Shared-widget variants | Shared component |
| Screen composition | Screen |

## 11. Material component-theme policy

Per category — buttons, text/input fields, dialogs, navigation, chips,
switch/toggle, snackbar, bottom sheet, progress indicators — decide whether a
central Material component theme represents the V3 default honestly. If it can
carry the default without fighting the MemoX variants: configure it centrally.
If the MemoX contract is richer than the Material theme can express cleanly:
keep the variation in the shared component, which still consumes
`ColorScheme`, `TextTheme` and global tokens. Do not force everything into
`ThemeData`; do not leave everything local.

## 12. Shared-component consumption rules

Shared components declare `slot/state → role usage` and consume the theme. They
must not hard-code a V3 hex, copy a standard role into a custom layer, redefine
a MemoX semantic role locally, re-resolve a role this step resolved, or reach
into another shared component's theme roles.

## 13. Gaps and `UNSPECIFIED`

A role a component needs that this step did not establish is a DEPENDENCY GAP —
report it upstream; never a licence to patch in a colour. `UNSPECIFIED` means
the design does not determine the value: keep the repository convention where
safe; ask where geometry, state, interaction, content loss or accessibility
depend on it.

## 14. Validation

Light and dark `ColorScheme` complete · repository canonical M3 role set intact
· every V3-defined standard role resolves through `ColorScheme` · every
BIND_NOW entry routed by KIND · only `MEMOX_SEMANTIC_COLOR` entries in the
MemoX semantic mechanism · no new field for a PRESERVE_ONLY semantic ·
`TextTheme` shared · disabled/pressed/focus shared · glass opacity and blur
outside the state layer · no raw colour duplicated in a shared widget · no
widget runs a private theme system · Material defaults centralised where
appropriate · custom variants still read the common theme. **Report every
mismatch instead of inventing a value.**

## 15. Component theme consumption index

### 15.1 DIRECT readers (deduplicated on component + slot + state + access; no suffix = FULL_STRENGTH)

| Role | Kind | Consumers |
|---|---|---|
| `bg` | M3_ALIAS | AppShell.page ground |
| `border-ghost` | DECORATION | see §5.4 |
| `chrome-glass` | DERIVED_COLOR | BottomNav.bar surface |
| `danger-soft` | DERIVED_COLOR | ErrorState.tile |
| `error` | M3_COLOR | TextField.error.border; TextField.error.message text + glyph; ErrorState.tile glyph |
| `error-fill` | MEMOX_SEMANTIC_COLOR | Button.destructive tone.container |
| `glass-blur` | EFFECT_TOKEN | BottomNav.bar blur · EFFECT (blur) |
| `inversePrimary` | M3_COLOR | Snackbar.action label |
| `inverseSurface` | M3_COLOR | Snackbar.container |
| `on-error-fill` | MEMOX_SEMANTIC_COLOR | Button.destructive tone.label + glyph |
| `onInverseSurface` | M3_COLOR | Snackbar.message |
| `onPrimary` | M3_COLOR | Fab.glyph; Button.primary tone.label + glyph; Button.loading.spinner; FilterChip.selected.label + count · OPACITY 0.75; Badge.solid.label; Spinner.inside a filled button.ring |
| `onSurface` | M3_COLOR | AppBar.title; AppBar.leading + trailing glyphs; Breadcrumb.current segment; StudyTopBar.close glyph; Button.secondary tone.label + glyph; IconButton.glyph; FilterChip.unselected.label; FilterChip.unselected.count · OPACITY 0.6; SearchField.filled.value text; SearchField.filled.clear button glyph; TextField.filled.value text; OptionRow.title; Card.content; ListRow.title; SettingsRow.label; Dialog.content; BottomSheet.content; EmptyState.title; ErrorState.title; AppShell.default text |
| `onSurfaceVariant` | M3_COLOR | BottomNav.inactive.glyph + label; Breadcrumb.ancestor segment; StudyTopBar.counter; ChipTrigger.trailing chevron; SearchField.empty.placeholder; SearchField.resting.leading glyph; TextField.empty.placeholder; OptionRow.description; ListRow.sub / metadata; ListRow.trailing chevron / overflow glyph; SettingsRow.sub; SettingsRow.chevron; TagChip.label; Note.text + glyph; EmptyState.body; ErrorState.body; FooterBar.hint line |
| `op-disabled` | STATE_TOKEN | see §5.5 |
| `op-press` | STATE_TOKEN | see §5.5 |
| `outline` | M3_COLOR | Breadcrumb.chevron separator; OptionRow.unselected.radio ring |
| `outlineVariant` | M3_COLOR | Button.outline tone.border · BORDER; BottomSheet.grabber |
| `primary` | M3_COLOR | AppBar.focused.focus ring · BORDER; BottomNav.active.glyph + label; BottomNav.active.active indicator pill · TINT 14% light / 20% dark; BottomNav.focused.focus ring · BORDER; Fab.container; Fab.focused.focus ring · BORDER; Button.primary tone.container; Button.outline tone.label + glyph; Button.focused.focus ring · BORDER; IconButton.focused.focus ring · BORDER; FilterChip.selected.container; FilterChip.focused.focus ring · BORDER; ChipTrigger.focused.focus ring · BORDER; SearchField.focused.border; SearchField.focused.leading glyph; SearchField.focused.caret; TextField.focused.border; Toggle.on.track; Toggle.focused.focus ring · BORDER; OptionRow.selected.radio ring; SettingsRow.focused.focus ring · BORDER; IconTile.default.tile · TINT 10% light / 16% dark; IconTile.default.glyph; Badge.tonal.container · TINT 12%; Badge.tonal.label; Badge.solid.container; Spinner.on a surface.ring; EmptyState.tile · TINT 10%; EmptyState.tile glyph |
| `progress-track` | M3_ALIAS | StudyTopBar.progress track; MasteryRamp.track |
| `scrim` | M3_COLOR | Scrim.visible.barrier · OPACITY 0.45; Dialog.barrier · OPACITY 0.45; BottomSheet.barrier · OPACITY 0.45 |
| `shadow-card` | DECORATION | Dialog.elevation |
| `shadow-chrome` | DECORATION | BottomSheet.elevation |
| `shadow-fab` | DECORATION | Fab.elevation |
| `shadow-soft` | DECORATION | Toggle.thumb elevation; Card.light edge |
| `status-learning` / `status-mastered` / `status-new` / `status-reviewing` | MEMOX_SEMANTIC_COLOR | see §5.1 |
| `surface` | M3_COLOR | AppBar.bar background; StudyTopBar.bar background; FooterBar.bar fill |
| `surface-hero` | DERIVED_COLOR | Card.tinted hero variant |
| `surface-muted` | M3_ALIAS | TextField.resting.container; Note.container |
| `surface-raised` | M3_ALIAS | Card.container; Section.row container; EmptyState.container; ErrorState.container |
| `surfaceBright` | M3_COLOR | Toggle.thumb |
| `surfaceContainer` | M3_COLOR | Button.secondary tone.container; SearchField.resting.container; TagChip.container |
| `surfaceContainerHigh` | M3_COLOR | Dialog.container; BottomSheet.container; Skeleton.placeholder block |
| `surfaceContainerHighest` | M3_COLOR | Toggle.off.track |
| `surfaceContainerLowest` | M3_COLOR | Button.chip variant.container; FilterChip.unselected.container; SearchField.focused.container; TextField.focused.container |
| `text-secondary` | M3_ALIAS | ChipTrigger.label; Section.overline |
| `transparent` | NONE | Button.outline tone.container · NO_FILL; IconButton.ink box · NO_FILL; ChipTrigger.container · NO_FILL |

A role defined but absent from these indexes is theme coverage to keep, not
something to delete.

### 15.2 `VIA_COMPONENT` (parents paint nothing; the child owns every role)

| Parent | Composition |
|---|---|
| EmptyState | action → Button (tone=primary) |
| ErrorState | action → Button (tone=primary) |
| FooterBar | CTA → Button (tone=primary · width=block) |
| ListRow | leading tile + glyph → IconTile (size=sm, variant=default, or seeded when the caller passes a seed) |
| SettingsRow | leading tile + glyph → IconTile (size=md, variant=default) |
| SheetActions | cancel → Button (tone=outline); confirm → Button (tone=primary); destructive confirm → Button (tone=destructive); disabled confirm → Button (enabled=false) |
