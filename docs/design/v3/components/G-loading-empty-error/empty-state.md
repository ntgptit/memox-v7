# MemoX v3 component · EmptyState

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `EmptyState` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# EmptyState — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · G · Loading, empty & error
NON-BINDING MATERIAL ANALOGY: a centred empty-state card with one action
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

## Component visual intent — EmptyState

The centred "this is the state of this surface" card: tinted tile, title, one warm line of copy, optionally the action that fixes it. `tone` is what let eight hand-built copies collapse into this one — a no-match reads neutral, a finished state reads success, and only the action-led empty reads primary.

## Component contract — EmptyState

Dimensions — label, dimension class, value:
  container           FIXED           .card, padding 44 24 32 · compact 32 24
  tile                FIXED           64 box · radius 20 · glyph 32 (lg) — compact 52 · radius 16 · glyph 24 (md)
  tile tint           FIXED           the tone @10%, tone glyph
  tones               FIXED           primary (default, action-led) · neutral (no match / not yet) · success (nothing due / finished) · warning · danger
  title               CONTENT-DRIVEN  20/700, -0.3px — compact 16/700
  body                CONTENT-DRIVEN  14 onSurfaceVariant, line-height 1.55, 20 below when an action follows
  action              CONTENT-DRIVEN  one Button, primary tone — geometry comes from the Button contract
  footnote            CONTENT-DRIVEN  Note-style box, 20 above, left-aligned inside a centred card

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

## Foundation token references — EmptyState

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onSurfaceVariant

## Theme consumption — EmptyState

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
  container                         surface-raised  ·  M3_ALIAS
      access: DIRECT · treatment: FULL_STRENGTH
      it is a card
  tile + glyph · tone primary       primary  ·  M3_COLOR
      access: DIRECT · treatment: TINT 10%
      the default, action-led empty — a COMPONENT tint at 10% for the tile, full strength for the glyph
  tile + glyph · tone neutral       onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: TINT 10%
      a query with no match, or history not yet written — a fact, not a failure
  tile + glyph · tone success       mastery  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: TINT 10%
      nothing due, every card resting — the calm end of a workflow
  tile + glyph · tone warning       warning  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: TINT 10%
      a state the user may want to act on
  tile + glyph · tone danger        error  ·  M3_COLOR
      access: DIRECT · treatment: TINT 10%
      reserved for a failed outcome; ErrorState remains the load-failure card
  title                             onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the headline
  body                              onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      one warm line of copy
  action                            Button  ·  tone=primary
      access: VIA_COMPONENT
      the call to action is a Button in its primary tone — Button owns every colour behind that tone

## Icons / content slots — EmptyState

Glyph names this component paints, verbatim from the kit:

  inbox
  layers
  search
  tag
  trash-2

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — EmptyState

  first launch      title + body + primary CTA
  filtered to nothingsame anatomy, copy names the filter instead of the feature
  compact           inside another card or a sheet
  with footnote     the rule sits below the action, not in the body
  no action         body only; the bottom padding closes up
  neutral tone      a query with no match, or history not yet written — a fact, not a failure
  success tone      nothing due, every card resting — the calm end of a workflow

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Priorities — EmptyState

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — EmptyState

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

## Implementation handoff — EmptyState

COMPONENT CONTRACT:
  EmptyState — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): inbox · layers · search · tag · trash-2

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surface-raised · primary · onSurfaceVariant · mastery · warning · error · onSurface
COMPOSED SHARED COMPONENTS — THE CHILD OWNS ITS COLOURS:
  · Button · tone=primary


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
