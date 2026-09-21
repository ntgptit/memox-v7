# MemoX v3 component · Toggle

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `Toggle` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# Toggle — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · C · Inputs & selection
NON-BINDING MATERIAL ANALOGY: an on/off switch
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

## Component visual intent — Toggle

The on/off switch in Settings and Reminder. One size ships. The thumb slides, it does not resize.

## Component contract — Toggle

Dimensions — label, dimension class, value:
  track               FIXED           44 × 26, radius full
  thumb               FIXED           20, radius full, 3 inset — travels left 3 → 21
  thumb fill          FIXED           surface-bright + shadow-soft
  track off           FIXED           surfaceContainerHighest
  track on            FIXED           primary
  motion              FIXED           160ms, standard ease, on the track colour and the thumb offset
  touch area          MINIMUM         48 around the 44 × 26 track

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

## Foundation token references — Toggle

Resolve each of these against the Foundations spec; none of them is redefined
here:

  op-disabled · shadow-soft · surface-bright · surfaceContainerHighest

## Theme consumption — Toggle

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
  track · off                       surfaceContainerHighest  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the resting track
  track · on                        primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the engaged track
  thumb                             surfaceBright  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the sliding thumb, lifted by shadow-soft
  thumb elevation                   shadow-soft  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      a shadow treatment, not a colour role
  whole control · disabled          op-disabled  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL disabled rule
  focus ring · focused              primary  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      GLOBAL focus treatment

## State matrix — Toggle

  off               surfaceContainerHighest track, thumb left
  on                primary track, thumb right
  disabled          the whole control at the GLOBAL op-disabled opacity, no interaction
  focused           2px primary ring, offset 2
  pressed           platform overlay around the thumb [INFERRED]

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Priorities — Toggle

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — Toggle

  mode boundary           PASS
  dimension classes       PASS
  token references        PASS
  ownership               PASS
  web mechanics           PASS
  touch geometry          PASS
  long content            n/a
  loading width           n/a
  UNSPECIFIED             none
  internal contradiction  PASS

## Implementation handoff — Toggle

COMPONENT CONTRACT:
  Toggle — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surfaceContainerHighest · primary · surfaceBright · shadow-soft · op-disabled


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
