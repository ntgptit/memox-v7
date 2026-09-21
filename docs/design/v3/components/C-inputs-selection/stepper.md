# MemoX v3 component · Stepper

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `Stepper` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# Stepper — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · C · Inputs & selection
NON-BINDING MATERIAL ANALOGY: a row of two IconButtons around a value
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

## Component visual intent — Stepper

The bounded integer input — cards per session, 1–200. Settings and Study options shipped identical copies. The component owns the invalid ring, the busy spinner in the value slot and the disabled dim; the caller owns the bounds.

## Component contract — Stepper

Dimensions — label, dimension class, value:
  button box          FIXED           36 · COMPONENT
  button radius       FIXED           12 (--memox-radius-md)
  button fill         FIXED           surface-container
  gap                 FIXED           4 button → value → button
  value column        MINIMUM         48 · COMPONENT — so 1 and 200 occupy the same width
  value type          FIXED           16/700 tabular
  invalid ring        FIXED           1px error border around the value; transparent when valid so nothing moves
  tap area            MINIMUM         48 per button
  bounds              UNSPECIFIED     1–200 · SCREEN — the component does not clamp

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

## Foundation token references — Stepper

Resolve each of these against the Foundations spec; none of them is redefined
here:

  op-disabled · radius-md · surface-container

## Theme consumption — Stepper

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
  button fill                       surfaceContainer  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      both increment and decrement
  button glyph                      onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the minus and plus glyphs
  value                             onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the number at rest
  value · invalid                   error  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      number and ring both take the error tone
  spinner · busy                    primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      replaces the number while the write is in flight

## Icons / content slots — Stepper

Glyph names this component paints, verbatim from the kit:

  minus
  plus

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — Stepper

  default           value between two 36 buttons, transparent ring
  invalid           error-toned number inside a 1px error ring
  busy              a spinner replaces the number; the buttons keep their width
  disabled          the whole control at the GLOBAL op-disabled opacity — Study options when "Use app defaults" is on
  at a bound        the outer button stops responding — SCREEN-owned; the component paints no separate look [INFERRED]

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Caller-owned — do NOT build into Stepper

  · min/max and the clamping, the validation message (FieldMessage), and what the number means

## Source trace — non-binding

  invalid ring          the valid state carries a 1px TRANSPARENT border, so turning invalid adds colour and never layout

## Priorities — Stepper

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — Stepper

  mode boundary           PASS
  dimension classes       PASS
  token references        PASS
  ownership               PASS
  web mechanics           PASS
  touch geometry          FAIL — painted 36 is below the 48 floor and no interactive-target row states the difference
  long content            n/a
  loading width           PASS
  UNSPECIFIED             none
  internal contradiction  PASS

## Implementation handoff — Stepper

COMPONENT CONTRACT:
  Stepper — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): minus · plus

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surfaceContainer · onSurface · error · primary


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · min/max and the clamping, the validation message (FieldMessage), and what the number means

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
