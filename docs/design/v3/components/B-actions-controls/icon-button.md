# MemoX v3 component · IconButton

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `IconButton` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# IconButton — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · B · Actions & controls
NON-BINDING MATERIAL ANALOGY: an icon-only button
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

## Component visual intent — IconButton

A 36 round ink box holding a 20 glyph, with the tap area expanded to 48 without growing the painted circle. The kit's only bare-icon control.

## Component contract — IconButton

Dimensions — label, dimension class, value:
  ink box             FIXED           36 · COMPONENT (--memox-size-icon-btn) — the painted circle
  glyph               FIXED           20 (icon sm)
  radius              FIXED           full
  touch area          MINIMUM         48 (--memox-size-touch), centred on the 36 ink box — the circle is NOT grown to meet it
  fill                FIXED           transparent; onSurface glyph

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

## Foundation token references — IconButton

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onSurface · op-disabled · size-icon-btn · size-touch

## Theme consumption — IconButton

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
  ink box                           transparent  ·  NONE
      access: DIRECT · treatment: NO_FILL
      no resting fill
  glyph                             onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the 20 glyph
  state overlay · pressed           op-press  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL pressed rule, bounded by the 36 circle
  focus ring · focused              primary  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      GLOBAL focus treatment
  whole control · disabled          op-disabled  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL disabled rule

## Icons / content slots — IconButton

Glyph names this component paints, verbatim from the kit:

  more-vertical
  search
  x
  arrow-left
  chevron-right

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — IconButton

  resting           transparent, onSurface glyph
  hover             primary @8% light / @14% dark — WEB ONLY, Android has no hover
  pressed           platform ripple bounded by the 36 circle [INFERRED]
  focused           2px primary ring, offset 2
  disabled          the GLOBAL op-disabled opacity [INFERRED]

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Resolved from source · component overrides

  · COMPONENT OVERRIDE — touch floor: the painted circle is 36, below the 48 global minimum, on purpose. Scope: painted geometry only.

## HTML/JSX translation notes — IconButton

  WEB TECHNIQUE   ::after box widening the tap area
  VISUAL INTENT   the painted control stays 36 while the interactive area reaches 48; the technique is irrelevant
  WEB TECHNIQUE   hover tint
  VISUAL INTENT   web-only — Android has no hover state

## Priorities — IconButton

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — IconButton

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

## Implementation handoff — IconButton

COMPONENT CONTRACT:
  IconButton — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): more-vertical · search · x · arrow-left · chevron-right

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
transparent · onSurface · op-press · primary · op-disabled


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
