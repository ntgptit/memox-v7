# MemoX v3 component · DeckPickerSheet

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `DeckPickerSheet` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# DeckPickerSheet — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · F · Overlays & feedback
NON-BINDING MATERIAL ANALOGY: a modal sheet with a scrolling list and a pinned footer
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

## Component visual intent — DeckPickerSheet

Choose the deck this goes to — deck move, card move, Trash restore. Deliberately thin: it owns the head typography and the scroll region that keeps the footer visible, and NOTHING about which decks are eligible. The three copies had already diverged in their scroll container.

## Component contract — DeckPickerSheet

Dimensions — label, dimension class, value:
  head padding        FIXED           4 20 12
  title               FIXED           16/700/-0.2px
  rule line           FIXED           12/1.5 — the one sentence stating what travels and what is not offered
  list padding        FIXED           0 8 8
  scroll region       FIXED           flex 1, vertical only, horizontal overflow clipped — the footer stays visible
  sheet height        MAXIMUM         the BottomSheet 85% cap; the list scrolls inside
  row count           CONTENT-DRIVEN  the eligible set — SCREEN

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

## Theme consumption — DeckPickerSheet

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
  title                             onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the sheet question
  rule line                         onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the product rule under the title
  sheet                             BottomSheet  ·  default configuration
      access: VIA_COMPONENT
      the surface, radius, cap and scrim come from BottomSheet unchanged
  candidate rows                    ListRow  ·  tileSize=sm · trailing=chevron · disabled=when the target cannot accept the payload
      access: VIA_COMPONENT
      a candidate destination is a ListRow; its disabled look is the ListRow one, and the REASON is passed as the sub-line
  empty                             EmptyState  ·  tone=neutral · compact=true
      access: VIA_COMPONENT
      nowhere to move is a neutral outcome, not a failure
  footer                            SheetActions  ·  divider=true
      access: VIA_COMPONENT
      the cancel/confirm footer is SheetActions and keeps its flex ratio

## Icons / content slots — DeckPickerSheet

Glyph names this component paints, verbatim from the kit:

  copy
  folder-tree
  chevron-right

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — DeckPickerSheet

  with targets      title, rule, a scrolling list of candidates, cancel footer
  no valid target   the list slot holds a neutral EmptyState explaining why, and the footer collapses to one OK
  target disabled   an ineligible candidate stays visible at the disabled opacity with its reason as the sub-line — never silently hidden

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — DeckPickerSheet

  deck path + capacity
      each row is a ListRow and follows its one-line-ellipsis contract — a deep path truncates rather than making one candidate taller than the others

## Caller-owned — do NOT build into DeckPickerSheet

  · which decks are eligible (BR-55 depth, BR-261 same tree), the payload, every string, and what selecting a target does

## Priorities — DeckPickerSheet

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — DeckPickerSheet

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

## Implementation handoff — DeckPickerSheet

COMPONENT CONTRACT:
  DeckPickerSheet — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): copy · folder-tree · chevron-right

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
onSurface · onSurfaceVariant
COMPOSED SHARED COMPONENTS — THE CHILD OWNS ITS COLOURS:
  · BottomSheet · default configuration
  · ListRow · tileSize=sm · trailing=chevron · disabled=when the target cannot accept the payload
  · EmptyState · tone=neutral · compact=true
  · SheetActions · divider=true


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · which decks are eligible (BR-55 depth, BR-261 same tree), the payload, every string, and what selecting a target does

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
