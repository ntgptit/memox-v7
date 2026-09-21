# MemoX v3 component · BottomNav

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `BottomNav` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# BottomNav — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · A · Chrome & navigation
NON-BINDING MATERIAL ANALOGY: NavigationBar (M3)
  Orientation only. Inspect the repository and map this contract onto what is
  already there — do not read the analogy as a widget tree to reproduce.

> Run the MemoX Foundations spec ONCE before this prompt. It carries the palette
> (both themes), the type scale, the spacing / radius / icon / elevation scales,
> the semantic alias layer, screen composition, responsive rules and the web
> techniques that must not be copied. Everything below assumes it and names
> tokens instead of repeating values.

## Implementation guardrails

Build or extend a shared component for this contract.

Before implementing: inspect the Flutter repository — its existing shared
widgets, theme and tokens. Reuse or extend whatever already owns this semantic
contract instead of adding a parallel one, map this contract onto the existing
theme / token architecture, and never re-declare a Foundations value locally
when a token or theme role already exists.

THIS COMPONENT OWNS: its visual geometry · internal spacing · content slots · variants · visual and interaction states · the minimum interactive target · its own long-content behaviour.

THE CALLER OWNS: screen placement · external spacing · navigation · business
rules · validation flow · feature state management. Do not pull a caller-owned
concern in because the HTML mock colocates them.

Source-design identifiers (CSS class names, JSX component names) appear below
for traceability only. They are NOT Flutter API names and a CSS class is not a
variant enum — expose the smallest semantic API this contract needs. Global
palette / type / spacing / composition work belongs to the Foundations run.

## Component visual intent — BottomNav

The four top-level destinations — Library · Study · Progress · Settings, in that order; the app opens on Library. A translucent glass bar inside an in-flow wrapper (it never overlaps the scroll), with a tinted pill behind the active glyph.

## Component contract — BottomNav

Dimensions — label, dimension class, value:
  block height        FIXED           80 · COMPONENT (--memox-size-bottom-nav, wrapper incl. inset)
  bar height          FIXED           64 · COMPONENT (--memox-size-bottom-bar, the painted bar)
  wrapper padding     FIXED           4 top · 8 sides · 12 + gesture inset bottom
  bar radius          FIXED           16 (--memox-radius-lg)
  destinations        FIXED           4, equal columns
  item gap            FIXED           4 glyph → label
  glyph               FIXED           20 painted
  label               FIXED           12/600, one line
  active pill         FIXED           padding 4 / 16, radius full, primary @14% light · @20% dark
  surface             FIXED           chrome glass (surface @84%) + blur, 1px ghost border

FIXED means reproduce the value. MINIMUM means never go below it, grow freely.
MAXIMUM means never exceed it. CONTENT-DRIVEN means the content sets it — do
not convert it into a fixed box, and a content-driven control entering a
loading state keeps the width that instance already had. RESPONSIVE means it
changes with width or text scale. SYSTEM-OWNED means the platform supplies it.
UNSPECIFIED means this design does not determine the value: do not invent one —
keep the repository's existing convention where that is safe, and ask when
geometry, state behaviour, interaction, content loss or accessibility cannot be
settled without an answer.

Where a painted dimension is smaller than the 48 touch minimum, both numbers
are in the table and both hold: keep the painted geometry and meet the touch
area by whatever platform technique the repo prefers — do not inflate the
control.

## Foundation token references — BottomNav

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onSurfaceVariant · radius-lg · size-bottom-bar · size-bottom-nav

## Theme consumption — BottomNav

The common Flutter theme must ALREADY have been established by the theme
prerequisite handoff before this component is implemented. The bindings below
are semantic dependencies, consumed through the repository's canonical theme
implementation — do not hard-code the V3 hex values locally, do not copy a
standard ColorScheme role into this widget, do not redefine a MemoX semantic
role here, and do not re-resolve a role the theme step already resolved.

Do not reopen or rebuild the global theme in this task. If a role below is
missing from the existing theme, REPORT THE THEME GAP — a missing role is a
prerequisite defect, not permission to patch a colour into this component.

GENERATED VIEW from this component's themeRoleUsage records. Three access
modes, three shapes:

  DIRECT           this component reads the theme role itself
  VIA_COMPONENT    it composes another shared component and selects that
                   child's semantic configuration — the CHILD owns every
                   colour behind it. No role is named here, and you must not
                   recolour the child from this side
  COMPONENT_INPUT  the value arrives per instance from the caller; it is not a
                   theme field

  slot / state                      binding
  bar surface                       chrome-glass  ·  DERIVED_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the translucent chrome FILL — the theme derives it once from surface at the op-glass opacity, so the bar applies no percentage of its own
  bar blur                          glass-blur  ·  EFFECT_TOKEN
      access: DIRECT · treatment: EFFECT (blur)
      the backdrop blur behind the fill — an effect token, never part of the colour; a solid fill at the same value is an acceptable fallback
  bar edge                          border-ghost  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      1px hairline around the bar
  glyph + label · inactive          onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the three destinations not in view
  glyph + label · active            primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the current destination
  active indicator pill · active    primary  ·  M3_COLOR
      access: DIRECT · treatment: TINT 14% light / 20% dark
      the pill behind the active glyph — a COMPONENT tint of primary, not the primary-soft token (authored at 10/20)
  focus ring · focused              primary  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      global focus treatment

## Icons / content slots — BottomNav

Glyph names this component paints, verbatim from the kit:

  layers
  play
  bar-chart-3
  settings

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — BottomNav

  inactive          glyph + label in onSurfaceVariant, no pill
  active            primary glyph + label, tinted pill behind the glyph, exposed as the current destination
  pressed           platform ripple over the item column [INFERRED]
  focused           2px primary ring, offset 2

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — BottomNav

  destination label
      the four labels are fixed product strings and fit one line; labels never wrap and the four columns stay equal

## Source trace — non-binding

  glyph                 the JSX passes icon step md (24) and the stylesheet constrains it to 20 — 20 ships, so 20 is the contract

## HTML/JSX translation notes — BottomNav

  WEB TECHNIQUE   backdrop-filter glass
  VISUAL INTENT   chrome reads as translucent over scrolling content; a solid surface at the same value is acceptable
  WEB TECHNIQUE   aria-current="page"
  VISUAL INTENT   the active destination is exposed as the current one to accessibility

## UNSPECIFIED — do not invent

  a localised label wider than its column
      SAFE TO DEFAULT: keep the repository convention for navigation labels (one line, ellipsis, equal columns). v3 ships only the four English strings, so the design does not determine it.

## Priorities — BottomNav

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — BottomNav

  mode boundary           PASS
  dimension classes       PASS
  token references        PASS
  ownership               PASS
  web mechanics           PASS
  touch geometry          PASS
  long content            PASS
  loading width           n/a
  UNSPECIFIED             PASS · 1 recorded
  internal contradiction  PASS

## Implementation handoff — BottomNav

COMPONENT CONTRACT:
  BottomNav — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): layers · play · bar-chart-3 · settings

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
chrome-glass · glass-blur · border-ghost · onSurfaceVariant · primary


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

UNSPECIFIED:
  · a localised label wider than its column — SAFE TO DEFAULT: keep the repository convention for navigation labels (one line, ellipsis, equal columns). v3 ships only the four English strings, so the design does not determine it.

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
