# MemoX v3 component · SegmentedTray

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `SegmentedTray` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# SegmentedTray — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · C · Inputs & selection
NON-BINDING MATERIAL ANALOGY: SegmentedButton (M3)
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

## Component visual intent — SegmentedTray

A 2–3 option exclusive switch: a recessed tray with a raised thumb behind the active option. Settings (theme, new-card order) and Progress (range) shipped identical copies with different accessibility — the announced version is now the contract.

## Component contract — SegmentedTray

Dimensions — label, dimension class, value:
  tray padding        FIXED           4
  tray gap            FIXED           2 between options
  tray radius         FIXED           12 (--memox-radius-md)
  thumb height        FIXED           32 · COMPONENT
  thumb radius        FIXED           8 (--memox-radius-sm)
  option padding      FIXED           0 12 in a settings row · 0 16 on the Progress range tray — VARIANT
  label               FIXED           12/600, one line
  options             MAXIMUM         2 or 3 — beyond 3 this is the wrong control
  width               CONTENT-DRIVEN  the widest label sets it; the tray is inline, not block

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

## Foundation token references — SegmentedTray

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onSurface · onSurfaceVariant · radius-md · radius-sm

## Theme consumption — SegmentedTray

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
  tray fill                         surfaceContainer  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the recessed track
  thumb fill · active               surfaceContainerLowest  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the raised block behind the active option
  thumb shadow · active             shadow-soft  ·  DECORATION
      access: DIRECT · treatment: UNPARSED
      lifts the thumb off the tray
  label · active                    onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the current option
  label · inactive                  onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the options not in view
  focus ring · focused              primary  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      global focus treatment

## State matrix — SegmentedTray

  active option     raised thumb, onSurface label, exposed as selected
  inactive option   no thumb, onSurfaceVariant label
  pressed           platform ripple inside the option [INFERRED]
  focused           2px primary ring, offset 2

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — SegmentedTray

  option label
      the labels are short product strings and stay one line; a tray whose labels no longer fit is a signal to use OptionRow instead, not to wrap

## Resolved from source · component overrides

  · Progress exposed tablist roles and Settings shipped bare buttons for the same control; the announced treatment now applies to both (COMPONENT, not a Progress-only behaviour).

## HTML/JSX translation notes — SegmentedTray

  WEB TECHNIQUE   role=tablist / role=tab / aria-selected
  VISUAL INTENT   the tray announces as one exclusive group with a current option — use the platform segmented control, not a row of buttons

## Priorities — SegmentedTray

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — SegmentedTray

  mode boundary           PASS
  dimension classes       PASS
  token references        PASS
  ownership               PASS
  web mechanics           PASS
  touch geometry          FAIL — painted 32 is below the 48 floor and no interactive-target row states the difference
  long content            PASS
  loading width           n/a
  UNSPECIFIED             none
  internal contradiction  PASS

## Implementation handoff — SegmentedTray

COMPONENT CONTRACT:
  SegmentedTray — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surfaceContainer · surfaceContainerLowest · shadow-soft · onSurface · onSurfaceVariant · primary


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
