# MemoX v3 component · Snackbar

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `Snackbar` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# Snackbar — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · F · Overlays & feedback
NON-BINDING MATERIAL ANALOGY: a bottom toast with one optional action
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

THIS COMPONENT OWNS: its visual geometry · internal spacing · content slots · variants · its own long-content behaviour. It is a surface, not a control: it has no interaction states or touch target of its own.

THE CALLER OWNS: screen placement · external spacing · navigation · business
rules · validation flow · feature state management. Do not pull a caller-owned
concern in because the HTML mock colocates them.

Source-design identifiers (CSS class names, JSX component names) appear below
for traceability only. They are NOT Flutter API names and a CSS class is not a
variant enum — expose the smallest semantic API this contract needs. Global
palette / type / spacing / composition work belongs to the Foundations run.

## Component visual intent — Snackbar

The bottom toast with one optional action — "Moved to Trash · Undo", save confirmations, export handoff. Its surface is the INVERSE surface, which does not flip with the theme.

## Component contract — Snackbar

Dimensions — label, dimension class, value:
  min height          MINIMUM         48
  padding             FIXED           10 16
  radius              FIXED           12 (--memox-radius-md)
  fill                FIXED           inverse-surface / on-inverse-surface — invariant across themes
  text                CONTENT-DRIVEN  14, line-height 1.4
  action              FIXED           14/700 inverse-primary, padding 4 8, min height 32, gap 12 from the text
  motion              FIXED           200ms sheet-in

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

## Foundation token references — Snackbar

Resolve each of these against the Foundations spec; none of them is redefined
here:

  inverse-primary · inverse-surface · radius-md

## Theme consumption — Snackbar

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
  container                         inverseSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      invariant across themes — the toast does not flip
  message                           onInverseSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the text on the inverse surface
  action label                      inversePrimary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      Undo / Retry at the trailing edge

## State matrix — Snackbar

  message only      one line, no action
  message + action  Undo / Retry at the trailing edge
  long message      text wraps and the toast grows; the action keeps its width
  auto-dismiss      duration is platform/screen behaviour, not a visual token [INFERRED]

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — Snackbar

  long message
      the text wraps to as many lines as it needs and the toast grows; the action keeps its width and stays on one line

## Caller-owned — do NOT build into Snackbar

  · placement: 16 left / right and 16 + gesture inset from the bottom — app-shell composition
  · the lift to 4 + 52 + 24 when the screen also shows the FAB and the bottom nav
  · how long the toast stays and what the action does

## Priorities — Snackbar

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — Snackbar

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

## Implementation handoff — Snackbar

COMPONENT CONTRACT:
  Snackbar — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
inverseSurface · onInverseSurface · inversePrimary


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · placement: 16 left / right and 16 + gesture inset from the bottom — app-shell composition
  · the lift to 4 + 52 + 24 when the screen also shows the FAB and the bottom nav
  · how long the toast stays and what the action does

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
