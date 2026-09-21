# MemoX v3 component · FilterChip

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `FilterChip` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# FilterChip — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · B · Actions & controls
NON-BINDING MATERIAL ANALOGY: a selectable filter chip
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

## Component visual intent — FilterChip

A selectable filter (All · Cards · Decks / Due · New). Selection is exposed as a toggle state rather than a style class, so the control stays announceable; an optional count sits after the label at the same size.

## Component contract — FilterChip

Dimensions — label, dimension class, value:
  height              FIXED           28 · COMPONENT — chip geometry from the Button contract
  padding             FIXED           0 8
  radius              FIXED           full (--memox-radius-chip)
  label type          FIXED           12/600 · count 12/700, tabular numerals
  glyph               FIXED           16 (icon xs), gap 4
  touch area          MINIMUM         48 — a centred band around the painted 28 pill; the pill is not grown into its neighbour
  width               CONTENT-DRIVEN  label + count; the chip never shrinks — the row scrolls instead

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

## Foundation token references — FilterChip

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onPrimary · onSurface · op-disabled · radius-chip · surfaceContainerLowest

## Theme consumption — FilterChip

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
  container · unselected            surfaceContainerLowest  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      resting pill fill
  border · unselected               border-ghost  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      resting 1px edge
  label · unselected                onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      filter name
  count · unselected                onSurface  ·  M3_COLOR
      access: DIRECT · treatment: OPACITY 0.6
      beside the label
  container · selected              primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      selected pill fill, no border
  label + count · selected          onPrimary  ·  M3_COLOR
      access: DIRECT · treatment: OPACITY 0.75
      content on the selected fill; the count sits lighter
  state overlay · pressed           op-press  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL pressed rule
  focus ring · focused              primary  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      GLOBAL focus treatment
  whole control · disabled          op-disabled  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL disabled rule

## Icons / content slots — FilterChip

Glyph names this component paints, verbatim from the kit:

  filter
  check

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — FilterChip

  unselected        surfaceContainerLowest + 1px ghost border, onSurface label, count at 60% opacity
  selected          primary fill, onPrimary label, no border, count at 75% opacity, exposed as selected
  pressed           platform ripple inside the pill [INFERRED]
  focused           2px primary ring, offset 2
  disabled          the GLOBAL op-disabled opacity [INFERRED]

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — FilterChip

  long label or large count
      ONE line, always: the chip lengthens and the row scrolls horizontally. No wrap, no ellipsis, no shrinking.

## Caller-owned — do NOT build into FilterChip

  · the chip row: horizontal scroll, 8 between chips, 10 band above and below
  · which filters exist, and which one is selected

## Resolved from source · component overrides

  · COMPONENT OVERRIDE — touch floor: painted at 28, below the 48 global minimum. Scope: painted geometry only; v3 delivers the 48 target through the row band.

## Source trace — non-binding

  --memox-size-chip (32)declared in Foundations but has no v3 call site — the shipped chip is 28

## Priorities — FilterChip

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — FilterChip

  mode boundary           PASS
  dimension classes       PASS
  token references        PASS
  ownership               PASS
  web mechanics           PASS
  touch geometry          PASS
  long content            PASS
  loading width           n/a
  UNSPECIFIED             none
  internal contradiction  PASS

## Implementation handoff — FilterChip

COMPONENT CONTRACT:
  FilterChip — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): filter · check

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surfaceContainerLowest · border-ghost · onSurface · primary · onPrimary · op-press · op-disabled


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · the chip row: horizontal scroll, 8 between chips, 10 band above and below
  · which filters exist, and which one is selected

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
