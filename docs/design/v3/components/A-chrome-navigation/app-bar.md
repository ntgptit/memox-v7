# MemoX v3 component · AppBar

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `AppBar` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# AppBar — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · A · Chrome & navigation
NON-BINDING MATERIAL ANALOGY: AppBar
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

## Component visual intent — AppBar

The top chrome on every screen (.appbar / .appbar-lg): leading icon button, flexible title, trailing action row. Two densities — a compact bar carrying a back button and a content title, and a large bar carrying a screen name. The title always shrinks and ellipsises before the actions do.

## Component contract — AppBar

Dimensions — label, dimension class, value:
  height              FIXED           56 · COMPONENT (--memox-size-appbar) — BOTH densities are 56; .appbar-lg only widens the gutter
  padding             FIXED           0 8 compact · 0 16 large (.appbar-lg)
  content title       FIXED           16/700/-0.3px, ONE line, ellipsis — deck / card names
  screen title        FIXED           24/700/-0.5px — what every v3 screen writes inside .appbar-lg, one line
  gap                 FIXED           4 bar items · 4 between trailing actions
  fill                FIXED           none — the bar sits on the page ground, no glass, no shadow

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

## Foundation token references — AppBar

Resolve each of these against the Foundations spec; none of them is redefined
here:

  size-appbar

## Theme consumption — AppBar

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
  bar background                    surface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the bar has no fill of its own — it sits on the page ground
  title                             onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      both densities
  leading + trailing glyphs         onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      icon-button glyphs in the bar
  focus ring · focused              primary  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      global focus treatment

## Icons / content slots — AppBar

Glyph names this component paints, verbatim from the kit:

  arrow-left
  x
  more-vertical
  search
  plus
  check

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — AppBar

  resting           no fill of its own — sits on the page ground
  long title        content title truncates with an ellipsis; leading and actions keep their width
  no actions        trailing row is omitted entirely, title keeps the full remaining width
  selection mode    leading becomes ✕, actions become Select all / Done — same geometry

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — AppBar

  content title
      the title is the only slot that gives up width: one line, ellipsis. Leading and trailing actions keep their width and are never dropped.
  screen title (large density)
      one line — v3 screen names are short product strings; the bar does not grow to a second line.

## Component-specific responsive notes — AppBar

  narrow width
      the title yields horizontal space first; the action row keeps its intrinsic width
  large text
      the 56 bar stays and the title ellipsises rather than wrapping — the same rule a platform app bar uses

## Resolved from source · component overrides

  · the ScreenHeader helper in _shared.jsx documented a 22 large title with no call site; it is corrected to the 24/700/-0.5px every v3 screen actually paints and is now the adopted implementation.

## HTML/JSX translation notes — AppBar

  WEB TECHNIQUE   flex 1 + minWidth 0 on the title
  VISUAL INTENT   the title yields space before the actions do and ellipsises when space runs out — the CSS flex mechanics are not the contract

## Priorities — AppBar

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — AppBar

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

## Implementation handoff — AppBar

COMPONENT CONTRACT:
  AppBar — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): arrow-left · x · more-vertical · search · plus · check

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surface · onSurface · primary


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
