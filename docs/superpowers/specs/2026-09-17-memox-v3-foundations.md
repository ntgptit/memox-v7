# MemoX v3 — Foundations (handoff, verbatim)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Hold the owner's MemoX v3 foundations handoff verbatim, with the two answers given on 2026-09-17, so every later component spec argues from the same text |
| **Scope** | The global visual system: palette both themes, type, spacing, radius, icon and elevation scales, composition and responsive rules. Screen layout, component variants and feature states are explicitly outside it |
| **Source of truth for** | The owner's handoff as received (generated from `design_system/MemoX Design System/ui_kits/mobile/v3` and `colors_and_type.css`), and answers A1/A2 |
| **Depends on** | `design_system/MemoX Design System/colors_and_type.css` |
| **Updated by task** | M100.97 |
| **Last updated** | 2026-09-18 |

Everything between the two rules below is the owner's handoff. Every value, table row and rule is
copied as received; only the list layout of the translation notes was condensed into sentences. The
plan argues from it; where the plan and this text disagree, this text wins.

---

> **Run ONCE, before any component spec**

## Handoff Mode

**HANDOFF MODE: FOUNDATIONS**

This run owns the **GLOBAL visual system only**:

- Palette
- Type
- Spacing
- Radius
- Icon scales
- Elevation scales
- Composition fundamentals
- Responsive rules
- System-owned rules

It does **not** own:

- Screen layout
- Component variants
- Feature states
- Business flow

### Source

MemoX v3 HTML design kit:

```text
ui_kits/mobile/v3
```

Every value below is read live from `colors_and_type.css` at page load, for both themes, so it cannot drift from the design.

Load this once as shared context; each component spec that follows is written against it and will not repeat these values.

---

## Visual direction

MemoX runs two themes from one structure:

- **Tokyo Pure Light** — a cool blue-tinted white where every neutral carries a trace of indigo and nothing is warm.
- **Tokyo Nebula** — a deep navy dark theme where the brand indigo lifts for contrast rather than the surfaces inverting.

The language is flat and quiet — surfaces separate by a one-pixel hairline and a very soft shadow, not by heavy elevation.

- Indigo carries every primary action.
- Violet is the signature accent.
- Green is reserved for mastery and success so it always reads as progress.
- Type is set in a single sans with a tight-tracked display face for figures.
- Layout keeps a steady **16px gutter** with generous card interiors.

---

## Colors

**Format:** `light / dark`

> “both themes” reports that the two authored values are the same — it is **NOT** a claim of invariance.
>
> Only `inverseSurface` and `onInverseSurface` are intentionally invariant among these standard roles.
>
> Elsewhere, an equal pair is a coincidence, and a token whose name says `fixed` may still flip (`mastery-fixed`).

### Brand & action

| Role | Light | Dark | Usage |
|---|---|---|---|
| `primary` | `#5265F5` | `#8B9AFF` | Fills primary actions, active nav, links |
| `onPrimary` | `#FFFFFF` | `#11173A` | Label/glyph on a primary fill |
| `primaryContainer` | `#E0E5FE` | `#2D346A` | Tonal button, selected chip, soft emphasis |
| `onPrimaryContainer` | `#1A2580` | `#D9DFFF` | Text on `primaryContainer` |
| `secondary` | `#6E7CD9` | `#9DA8E8` | Secondary emphasis, muted brand |
| `onSecondary` | `#FFFFFF` | `#1A2150` | On a secondary fill |
| `secondaryContainer` | `#E3E6F7` | `#343C78` | |
| `onSecondaryContainer` | `#262E6E` | `#DDE2FB` | |
| `tertiary` | `#8B6FF5` | `#B5A0FF` | The violet signature accent |
| `onTertiary` | `#FFFFFF` | `#240B63` | |
| `tertiaryContainer` | `#EBE3FE` | `#443078` | |
| `onTertiaryContainer` | `#33177E` | `#E6DCFF` | |

### Surfaces

The ladder is ordered **lowest → highest**.

| Role | Light | Dark | Usage |
|---|---|---|---|
| `surface` | `#F7F9FE` | `#0A0E27` | Page ground |
| `surfaceDim` | `#DAE0EF` | `#060925` | |
| `surfaceBright` | `#FFFFFF` | `#232B5A` | |
| `surfaceContainerLowest` | `#FFFFFF` | `#131A3A` | |
| `surfaceContainerLow` | `#F1F4FB` | `#1B2249` | Input fill, sheet |
| `surfaceContainer` | `#E9EDF7` | `#232B5A` | Chip, inactive track |
| `surfaceContainerHigh` | `#E2E7F3` | `#2C356E` | Dialog |
| `surfaceContainerHighest` | `#DAE0EF` | `#353D7E` | |

### Text & lines

| Role | Light | Dark | Usage |
|---|---|---|---|
| `onSurface` | `#0F1638` | `#E4E8FA` | Primary text |
| `onSurfaceVariant` | `#4A5278` | `#A4ACD0` | Secondary text, inactive glyph |
| `text muted` | `#7C85AB` | `#5A6BAE` | Tertiary text, timestamps |
| `outline` | `#7C85AB` | `#5A6BAE` | Visible borders, focus rings |
| `outlineVariant` | `#C5CBE3` | `#2A3267` | Hairline dividers and card borders |

### Feedback & progress

| Role | Light | Dark | Usage |
|---|---|---|---|
| `error` | `#DC2D4E` | `#FF8FA3` | |
| `onError` | `#FFFFFF` | `#52061B` | |
| `errorContainer` | `#FBDDE3` | `#7A2036` | |
| `onErrorContainer` | `#7A0A23` | `#FFD9DF` | |
| `success` | `#2BA88B` | `#6FE0BD` | |
| `warning` | `#F59E0B` | `#FFC658` | |
| `mastery` | `#1F8A5B` | `#6FE0BD` | Mastery/progress green |
| `warning ink (TEXT)` | `onWarning` | `warning` | Amber TEXT for an overdue count — kit-scoped, because the warning FILL fails contrast as 12px text on light |
| `status new` | `#8C95B8` | `#6B75A3` | |
| `status learning` | `#F59E0B` | `#FFC658` | |
| `status reviewing` | `#5265F5` | `#8B9AFF` | |
| `status mastered` | `#1F8A5B` | `#6FE0BD` | |

### Inverse & effects

| Role | Light | Dark | Usage |
|---|---|---|---|
| `inverseSurface` | `#34395D` | `#34395D` | Snackbar slate — does **NOT** flip with the theme |
| `onInverseSurface` | `#E8EAFC` | `#E8EAFC` | Label on the snackbar |
| `inversePrimary` | `#8B9AFF` | `#5265F5` | Action inside a snackbar |
| `shadow` | `#0F1638` | `#000000` | Shadow base color, mixed at the use site |
| `scrim` | `#0A0E27` | `#000000` | Modal scrim base, used at 45% alpha |

### Opacities

| Role | Value |
|---|---:|
| Disabled | `0.38` |
| Hover overlay | `0.08` |
| Pressed overlay | `0.12` |
| Glass chrome | `0.84` |

---

## Typography

### Font family

**Family**

```text
"Plus Jakarta Sans", ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif
```

**Display / figures**

```text
"Plus Jakarta Sans", ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif
```

### Type scale

| Role | Size | Weight | Line height | Tracking | Usage |
|---|---:|---:|---:|---:|---|
| `caption` | 12 | 600 | 1.4 | `1.2px` | Overlines, metadata, chips, counts — **hard 12px floor** |
| `body` | 14 | 400 | 1.5 | 0 | Default running text |
| `body large` | 16 | 500 | 1.5 | 0 | List titles, emphasised body |
| `title` | 20 | 700 | 1.2 | `-0.64px` | Section and screen titles |
| `headline` | 24 | 700 | 1.2 | `-0.64px` | Screen headline |
| `display` | 32 | 800 | 1.1 | `-0.64px` | Hero figure |
| `stat` | 40 | 600 | 1.0 | `-0.64px` | Large metric, tabular numerals |

**Weights available:**

```text
400 / 500 / 600 / 700 / 800
```

> Type is **NOT** on the spacing grid — do not snap a size to a multiple of 4.

---

## Spacing

| Value | Role | Usage |
|---:|---|---|
| 4 | Micro gap | Icon-to-label, inside a chip |
| 8 | Control internal | Button padding, tight stacks |
| 12 | Grouped items | Related rows inside one block |
| 16 | Screen gutter | Horizontal screen padding **AND** list/item gap |
| 20 | Card padding | Card and sheet interior |
| 24 | Section gap | Between sections of a screen |
| 32 | Major separation | Between major visual groups |
| 48 | Page-end clearance | Scroll tail above pinned chrome |

> Spacing is gap / padding / inset only.
>
> Component size is a separate system — see below.

---

## Radius & geometry

### Radius roles

Where each radius actually lands in v3:

| Radius | Usage |
|---:|---|
| 4 | 20px checkbox |
| 8 | 28 icon tile, compact button |
| 12 | Button, input, note, snackbar, 36–44 icon tile, small controls |
| 16 | FAB, bottom-nav bar |
| 20 | Card, **DIALOG**, **BOTTOM-SHEET** top corners, 64 empty-state tile |
| 24 | No call site in v3 |
| 28 | No call site in v3 |
| 999 | Pill — chip, badge, toggle track, sheet grabber, progress track |

### Component geometry

Each component carries an explicit **dimension class**.

| Component | Size | Dimension class | Notes |
|---|---:|---|---|
| Button height | 48 | `MINIMUM` | Painted value in every shipped instance. Minimum so a wrapped label or OS text scaling grows the box. Four painted sizes: `48 regular · 36 small · 32 compact · 28 chip` |
| Small button | 36 | `MINIMUM` | Real Button size: reminder time, tag-management empty action, two DeckImport file pickers |
| Compact button | 32 | `MINIMUM` | Inline banner action, app-bar action |
| Chip / filter chip | 28 | `FIXED` | Never wraps; the row scrolls. `--memox-size-chip` token (`32`) has **NO** call site in v3 |
| Input height | 52 | `FIXED` | Text field and search field |
| Icon-button ink box | 36 | `FIXED` | Painted circle only |
| Touch target | 48 | `MINIMUM` | Applies to every interactive element |
| App bar height | 56 | `FIXED` | Both densities are 56 |
| Bottom nav block | 80 | `FIXED` | Bar drawn at 64, rest is inset |
| FAB | 52 | `FIXED` | **SQUARE**, `52 × 52`, icon only — v3 has no extended FAB |
| Card height | — | `CONTENT-DRIVEN` | |
| List row height | 48 | `MINIMUM` | Grows to two title lines |
| Preview status bar | 44 | `SYSTEM-OWNED` | Device-frame chrome, never an app dimension |

---

## Icons

| Size | Role | Usage |
|---:|---|---|
| 16 | Inline | Inside body text, compact utility |
| 20 | Compact control | Dense rows, metadata, nav glyphs, FAB glyph |
| 24 | Standard action | App-bar and navigation actions |
| 32 | Large emphasis | Feature tiles |
| 40 | Illustrative | Empty states, hero marks |

Visual icon size and touch area are separate.

A `20px` glyph in a `36px` ink box still needs a `48px` interactive region.

> Expand the hit area, never the painted box.
>
> Nothing goes below `16px`.

---

## Elevation / border / shadow

Surfaces separate by a hairline plus a very soft shadow — there is no heavy elevation anywhere in this design.

| Role | Specification |
|---|---|
| Border | `1px solid outlineVariant` on cards, inputs and dividers |
| Card | `0 12px 32px rgba(15,22,56,0.10)` |
| Chrome | `0 -2px 12px rgba(15,22,56,0.05)` |
| Floating | `0 8px 24px rgba(15,22,56,0.12)` |
| Scrim | `scrim` at 45% alpha behind dialogs and sheets |
| Glass chrome | Translucent surface + backdrop blur on the bottom nav |

### Hierarchy

```text
page ground
→ card (hairline + card shadow)
→ sheet/dialog (container surface + scrim)
→ floating action (fab shadow)
```

Shadows are neutral, never tinted with the brand color.

---

## Semantic alias layer — declare these too

The design references these role names by name.

They are declared in `colors_and_type.css` on top of the M3 tokens above; resolve each one to its underlying role in the repository rather than inventing a new token.

| Name | Light / Dark | Resolves to / used for |
|---|---|---|
| `bg` | `#F7F9FE / #0A0E27` | Page ground = `surface` |
| `surface-raised` | `#FFFFFF / #131A3A` | `.card` fill |
| `surface-muted` | `#F1F4FB / #1B2249` | TextField resting fill, Note fill |
| `surface-hero` | `color-mix(in srgb, #5265F5 5%, #FFFFFF)` / `color-mix(in srgb, #8B9AFF 12%, #0A0E27)` | Tinted hero card |
| `chrome-glass` | `rgba(247, 249, 254, 0.84)` / `rgba(10, 14, 39, 0.84)` | Bottom-nav glass |
| `primary-soft` | `color-mix(in srgb, #5265F5 10%, transparent)` / `color-mix(in srgb, #8B9AFF 20%, transparent)` | Soft primary tint — tonal actions, tile tints |
| `primary-border` | `color-mix(in srgb, #5265F5 24%, transparent)` / `color-mix(in srgb, #8B9AFF 32%, transparent)` | Primary edge at low alpha |
| `danger` | `#DC2D4E / #FF8FA3` | `= error` |
| `on-danger` | `#FFFFFF / #2A0A12` | `= onError` |
| `danger-soft` | `color-mix(in srgb, #DC2D4E 8%, transparent)` / `color-mix(in srgb, #FF8FA3 16%, transparent)` | ErrorState tile tint |
| `danger-border` | `color-mix(in srgb, #DC2D4E 22%, transparent)` / `color-mix(in srgb, #FF8FA3 32%, transparent)` | Destructive edge |
| `error-fill` | `#DC2D4E / #B0485C` | **SOLID** destructive button fill — Button destructive tone |
| `on-error-fill` | `#FFFFFF` both themes | Label on destructive fill |
| `success-soft` | `color-mix(in srgb, #2BA88B 10%, transparent)` / `color-mix(in srgb, #6FE0BD 18%, transparent)` | Success tint |
| `warning-soft` | `color-mix(in srgb, #F59E0B 12%, transparent)` / `color-mix(in srgb, #FFC658 18%, transparent)` | Warning tint |
| `on-warning` | `#3A2A00 / #2A1E00` | Ink on a warning fill |
| `streak` | `#F97316 / #FFAE6E` | Streak accent |
| `on-streak` | `#FFFFFF` both themes | Ink on streak fill |
| `mastery-fixed` | `#C7F2D8 / #1F4A37` | Invariant mastery tint |
| `progress-track` | `#E2E7F3 / #2C356E` | Progress / mastery track = `surfaceContainerHigh` |
| `badge-bg` | `#E9EDF7 / #232B5A` | Surface-ladder step = `surfaceContainer` — declared, no v3 call site |
| `border-ghost` | `1px solid rgba(82, 101, 245, 0.14)` / `1px solid rgba(139, 154, 255, 0.16)` | 1px hairline edge — “ghost border” |
| `border-strong` | `1px solid #C5CBE3` / `1px solid #2A3267` | 1px `outlineVariant` edge |
| `shadow-soft` | `0 1px 2px rgba(15,22,56,0.04)` / `none` | Card whisper shadow — none in dark |
| `shadow-none` | `none` both themes | No shadow |
| `radius-button` | `12px` both themes | Button radius = `radius-md` |
| `radius-input` | `12px` both themes | Input radius = `radius-md` |
| `radius-chip` | `999px` both themes | Pill radius = `radius-full` |
| `radius-fab` | `16px` both themes | FAB radius = `radius-lg` |

---

## Screen composition

The component sits on the **16px screen gutter**, in a single content column.

### Vertical rhythm

| Relationship | Spacing |
|---|---:|
| Between related rows | 12 |
| Between list items | 16 |
| Between sections | 24 |
| Between major groups | 32 |
| Card interiors | 20 |
| Scroll tail above pinned chrome | 48 |

Scrollable content clears pinned chrome by `48` at the tail so the last item is never trapped under the bottom nav or floating action.

### Hierarchy

```text
primary focal surface
→ supporting metadata
→ primary action (anchored)
→ secondary action (inline, lower contrast)
```

---

## Responsive / Android notes

| Context | Rule |
|---|---|
| Compact phone | Content column narrows; gutter stays `16`. Nothing in this design depends on a fixed viewport width |
| Large text | Every text container must grow. Do not clamp text scale and do not put a fixed height around text |
| Landscape | Column stays single; pinned chrome remains reachable |
| Keyboard open | Focused field and primary action stay reachable; IME inset is supplied at runtime, never hardcoded |

### SYSTEM-OWNED geometry

Android supplies all of the following:

- Status bar
- Display cutout
- Gesture/navigation inset
- Keyboard inset
- System Back

The kit's `44px` status bar and phone bezel are **preview chrome**.

> Never convert them into application dimensions.

---

## HTML/JSX translation notes

### FAB positioning

**WEB TECHNIQUE** — The FAB is absolutely positioned inside the frame. The bottom nav and every commit footer are **NOT** — they are in-flow siblings of the scroll and never overlap it.

**VISUAL INTENT** — The floating action stays anchored above the content and clear of the system inset; bottom chrome occupies its own space.

**HANDOFF** — Preserve the anchored relationship for the FAB and the in-flow relationship for the bars. Absolute positioning is **not** part of the design.

### Small control tap area

**WEB TECHNIQUE** — A `::after` box widens a small control's tap area.

**VISUAL INTENT** — The painted control stays compact while the tap area meets `48px`.

**HANDOFF** — Keep visual size and hit area separate; the technique is irrelevant.

### Bottom-nav glass

**WEB TECHNIQUE** — `backdrop-filter` blur on the bottom nav.

**VISUAL INTENT** — Chrome reads as translucent glass over scrolling content.

**HANDOFF** — Reproduce the visual result; a solid surface at the same value is acceptable if blur is costly.

### Hover / pressed overlays

**WEB TECHNIQUE** — `color-mix()` overlays for hover and pressed tints.

**VISUAL INTENT** — A percentage tint of the role color over the surface.

**HANDOFF** — Use the platform's own overlay mechanism at the same percentage.

### Scrim / Dialog / BottomSheet

**WEB TECHNIQUE** — `Scrim` / `Dialog` / `BottomSheet` are absolutely positioned with `inset:0` **INSIDE** the phone div. `Dialog` and `BottomSheet` each draw their own `Scrim` unless passed `scrim={false}`.

**VISUAL INTENT** — A modal layer covering the app surface, dimmed to `45%` of the scrim role color, with the panel centred for dialog and bottom-anchored for sheet.

**HANDOFF** — The platform's own modal route owns the barrier and the full window. The `scrim={false}` flag exists only because this mock nests overlays inside a preview frame.

> Do **NOT** carry it across as a widget parameter.
>
> Take the dim percentage, panel geometry and motion — nothing else.

### TextField / SearchField

**WEB TECHNIQUE** — `TextField` and `SearchField` are static mocks — a `<span>` holding placeholder text plus a CSS-animated caret, not a real input.

**VISUAL INTENT** — The rest / focus / error appearance of a filled field.

**HANDOFF** — `focused` and `error` here are **VISUAL STATES**, not behaviour. Real focus, caret, selection, IME and validation are the platform's responsibility. Only borders, fill and message styling transfer.

### Do not copy

Also do **not** copy:

- Hover-only affordances — there is no hover on Android.
- Fake status bar.
- Device bezel.
- Any fixed pixel box drawn around text.

---

## Priorities

| Priority | Scope |
|---|---|
| **P0** | Palette and both themes; type scale; 16 gutter and spacing rhythm |
| **P1** | This component's surface treatment, radius, geometry class and states |
| **P2** | Icon sizing per role, hairline and shadow treatment |
| **P3** | Decorative polish — flip timing, glass blur, skeleton opacity pulse |

Skeleton opacity pulse: `0.45 ↔ 0.75 over 1.4s` — a **pulse**, not a shimmer sweep.

---

## Implementation handoff — foundations

### GLOBAL VISUAL TOKENS

```text
spacing      4 / 8 / 12 / 16 / 20 / 24 / 32 / 48
radius       4 / 8 / 12 / 16 / 20 / 24 / 999
icons        16 / 20 / 24 / 32 / 40
touch target 48 minimum
```

### COLOR / THEME SPEC

Two themes: Light, Dark. See the **Colors** section above.

Special rules:

- `inverseSurface` and `onInverseSurface` are the intentionally invariant pair.
- `tertiary` is the violet accent.
- Green is reserved for mastery.

### TYPOGRAPHY

```text
12 / 14 / 16 / 20 / 24 / 32 / 40
```

- `12` is a hard floor.
- Type is **not** on the `4dp` grid.

### COMPONENT CONTRACTS

Supplied per component, in the specs that follow this one. Each carries its own dimension table, icon list and state matrix.

### SCREEN COMPOSITION

```text
16 gutter
16 list gap
24 section gap
32 major separation
48 scroll tail
```

### RESPONSIVE RULES

- Single column.
- No fixed widths.
- No fixed heights around text.
- No text-scale clamping.
- Pinned chrome always reachable.

---

## Owner answers (2026-09-17, AskUserQuestion)

| # | Question | Answer |
|---|---|---|
| A1 | Text drawn in a v3 hex that fails AA 4.5:1 (light `primary` 4.39, `error` 4.40, `mastery` 4.12, text-muted 3.44, `success` 2.82; dark text-muted 3.75, `inversePrimary` on the snackbar 2.40) | **Text inks.** Fills, surfaces, dots and icons keep the v3 hex; text that fails AA reads through a same-hue ink. `warning ink` is the v3 value (`onWarning` / `warning`). This re-confirms the owner decision of 2026-09-13. |
| A2 | `info` has no v3 counterpart | **Keep the `info` token** as it ships. |
