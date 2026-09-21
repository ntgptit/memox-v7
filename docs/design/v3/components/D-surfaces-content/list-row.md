# MemoX v3 component · ListRow

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `ListRow` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# ListRow — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · D · Surfaces, rows & content
NON-BINDING MATERIAL ANALOGY: a tappable content row
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

## Component visual intent — ListRow

The content row behind decks, search results, tags, move targets and cards. Title and metadata are both ONE line with an ellipsis, so every row in a list is the same height — a wrapping title made card heights uneven down the list. Deliberately NOT SettingsRow — this is a piece of CONTENT.

## Component contract — ListRow

Dimensions — label, dimension class, value:
  grid                FIXED           auto leading / 1fr text / auto trailing, gap 12
  padding             FIXED           12 16
  min height          MINIMUM         48
  leading             CONTENT-DRIVEN  IconTile at 28 (sm) by default; any node may replace it
  title               FIXED           14/600, -0.1px, line-height 1.35 — ONE line, nowrap, ellipsis
  sub                 FIXED           12 onSurfaceVariant, 2 below the title, ONE line, ellipsis
  divider             FIXED           1px ghost bottom border, omitted on the last row
  disabled            FIXED           the whole row at the GLOBAL op-disabled opacity, not tappable — the row that cannot accept the payload in a DeckPickerSheet
  height              FIXED           one title line + one sub line + 12/12 padding — every row in a list is the same height

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

## Foundation token references — ListRow

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onSurfaceVariant · op-disabled

## Theme consumption — ListRow

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
  leading tile + glyph              IconTile  ·  size=sm (tileSize) · variant=default, or seeded when the caller passes a seed
      access: VIA_COMPONENT
      the 28 lead square is an IconTile — IconTile owns the tint and the glyph colour; this row picks the size and passes the seed through
  leading tile seed                 seed  ·  instance input
      access: COMPONENT_INPUT · treatment: FORWARD_UNCHANGED (the child owns the treatment)
      forward unchanged to IconTile.seed — the row never paints the seed itself; IconTile owns the tint and the glyph treatment
  title                             onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the content name
  sub / metadata                    onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the second line
  divider                           border-ghost  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      between rows
  trailing chevron / overflow glyph onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      navigation or menu affordance
  state overlay · pressed           op-press  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL pressed rule across the row
  whole row · disabled              op-disabled  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      GLOBAL disabled rule — the candidate destination that cannot accept the payload

## Icons / content slots — ListRow

Glyph names this component paints, verbatim from the kit:

  chevron-right
  more-vertical
  layers
  tag
  file-text

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — ListRow

  resting           no fill; divider below
  tappable          exposed as a button when it navigates; pressed = platform ripple across the row [INFERRED]
  long title        ONE line then ellipsis — a long Vietnamese or Korean deck name is cut, not wrapped, because a uniform row height down the list matters more than the tail of the name
  long sub          one line, ellipsis
  last row          no divider
  busy row          trailing slot holds a spinner instead of the chevron / overflow trigger
  disabled          the GLOBAL op-disabled opacity and no tap — used for an ineligible move target, whose REASON the caller passes as the sub-line so the row explains itself rather than just dimming

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — ListRow

  title
      ONE line then ellipsis. A long Vietnamese or Korean deck name is cut, not wrapped: a uniform row height down the list matters more than the tail of the name.
  sub / metadata
      ONE line then ellipsis
  trailing content
      leading and trailing slots keep their width; the text column is the only one that gives up space

## Component-specific responsive notes — ListRow

  large text
      the row grows because min height is a floor, but the title and sub stay at one line each

## HTML/JSX translation notes — ListRow

  WEB TECHNIQUE   role=button + tabIndex when the row navigates
  VISUAL INTENT   the row is exposed as a button when it leads somewhere; otherwise it is plain content

## Priorities — ListRow

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — ListRow

  mode boundary           PASS
  dimension classes       PASS
  token references        PASS
  ownership               PASS
  web mechanics           PASS
  touch geometry          PASS
  long content            PASS
  loading width           PASS
  UNSPECIFIED             none
  internal contradiction  PASS

## Implementation handoff — ListRow

COMPONENT CONTRACT:
  ListRow — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): chevron-right · more-vertical · layers · tag · file-text

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
onSurface · onSurfaceVariant · border-ghost · op-press · op-disabled
COMPOSED SHARED COMPONENTS — THE CHILD OWNS ITS COLOURS:
  · IconTile · size=sm (tileSize) · variant=default, or seeded when the caller passes a seed
INSTANCE INPUTS — NOT THEME FIELDS:
  · seed


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
