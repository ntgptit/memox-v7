# MemoX v3 component · TextField

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `TextField` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# TextField — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · C · Inputs & selection
NON-BINDING MATERIAL ANALOGY: a filled text field with an error message row
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

## Component visual intent — TextField

Every form field in the kit: filled surface, ghost border, primary border on focus, error tone plus a message line below. `multiline` switches to the shorter content-driven box the card editor uses.

## Component contract — TextField

Dimensions — label, dimension class, value:
  height              FIXED           52 · COMPONENT (--memox-size-input) single line
  multiline height    MINIMUM         40 start, grows with the text
  padding             FIXED           0 12 single line · 8 12 multiline
  radius              FIXED           12 (--memox-radius-input)
  resting             FIXED           surface-muted fill + 1px ghost border
  focused             FIXED           surfaceContainerLowest fill + 1px primary border
  error               FIXED           1px error border + a FieldMessage row below (that row is now its own contract, reachable by fields that are not TextFields)
  text                CONTENT-DRIVEN  14/400, line-height 1.5
  slots               CONTENT-DRIVEN  leading + trailing nodes, gap 8
  touch area          MINIMUM         48 — the whole field is the tap target: the 52 single-line box already exceeds it, and the multiline box grows from its 40 floor

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

## Foundation token references — TextField

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onSurface · onSurfaceVariant · op-disabled · radius-input · size-input · surface-muted · surfaceContainerLowest

## Theme consumption — TextField

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
  container · resting               surface-muted  ·  M3_ALIAS
      access: DIRECT · treatment: FULL_STRENGTH
      resolves to surfaceContainerLow
  border · resting                  border-ghost  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      resting 1px edge
  container · focused               surfaceContainerLowest  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the field lightens on focus
  border · focused                  primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      1px primary edge
  border · error                    error  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      1px error edge
  message row                       FieldMessage  ·  tone=error
      access: VIA_COMPONENT
      the validation line under the field is FieldMessage — the same contract the card editor and the tag dialog use for fields that are not TextFields
  value text · filled               onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      typed content
  placeholder · empty               onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      prompt text
  whole field · disabled            op-disabled  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL disabled rule

## Icons / content slots — TextField

Glyph names this component paints, verbatim from the kit:

  alert-circle

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — TextField

  resting           muted fill, ghost border, placeholder in onSurfaceVariant
  focused           primary border, lowest fill, blinking caret
  filled            value in onSurface
  error             error border + message; the message pushes the following content down, it does not overlay
  disabled          the whole field at the GLOBAL op-disabled opacity
  long value        single line ellipsises · multiline wraps and the box grows

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — TextField

  single line
      the value ellipsises; the field does not grow or wrap
  multiline
      the text wraps and the box grows from its 40 floor — no maximum in v3
  error message
      wraps to as many lines as it needs and pushes the following content down; it never overlays

## Component-specific responsive notes — TextField

  large text
      both boxes grow with the text — the 52 single-line height is a floor, not a clamp

## Caller-owned — do NOT build into TextField

  · validation rules, when the error tone is applied, and the message text

## HTML/JSX translation notes — TextField

  WEB TECHNIQUE   static mock: placeholder span + animated caret
  VISUAL INTENT   "focused" and "error" here are VISUAL states. Real focus, caret, selection, IME and validation are platform-owned

## Priorities — TextField

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — TextField

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

## Implementation handoff — TextField

COMPONENT CONTRACT:
  TextField — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): alert-circle

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surface-muted · border-ghost · surfaceContainerLowest · primary · error · onSurface · onSurfaceVariant · op-disabled
COMPOSED SHARED COMPONENTS — THE CHILD OWNS ITS COLOURS:
  · FieldMessage · tone=error


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · validation rules, when the error tone is applied, and the message text

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
