# MemoX v3 component · FooterBar

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `FooterBar` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# FooterBar — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · H · Layout shell
NON-BINDING MATERIAL ANALOGY: an in-flow commit bar below the scroll
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

## Component visual intent — FooterBar

The in-flow commit bar (Save, Done, Cancel/Confirm, bulk actions). A sibling of the scroll, so it never overlaps content — which is why a screen with a footer needs only the base clearance.

## Component contract — FooterBar

Dimensions — label, dimension class, value:
  padding             FIXED           8 top · 16 sides · 16 + gesture inset bottom
  divider             FIXED           1px ghost top border
  fill                FIXED           surface
  content             CONTENT-DRIVEN  column, gap 8 — usually one block-width Button, sometimes an InlineBanner above it
  caption             FIXED           12 onSurfaceVariant, centred, opacity 0.7 — the optional line under the actions (6 of 9 sites carry one)
  height              CONTENT-DRIVEN  set by its content

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

## Foundation token references — FooterBar

Resolve each of these against the Foundations spec; none of them is redefined
here:

  onSurfaceVariant · op-disabled

## Theme consumption — FooterBar

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
  bar fill                          surface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the commit bar sits on the page ground
  top divider                       border-ghost  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      the 1px rule above it
  hint line                         onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the optional line above the CTA
  CTA                               Button  ·  tone=primary · width=block
      access: VIA_COMPONENT
      the commit action is a block-width Button in its primary tone; Button owns its tone colours

## State matrix — FooterBar

  single CTA        one full-width Button (block)
  CTA + caption     the calm caption line UNDER the actions, centred at opacity 0.7
  CTA pair          a shrink-proof secondary beside a flex-1 primary
  5-up icon grid    the card-list bulk bar — five icon+label columns in equal fractions (Cards-local content, this bar’s geometry)
  disabled CTA      the button at the GLOBAL op-disabled opacity; the bar itself does not dim
  busy              the button holds a spinner and keeps its width

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Resolved from source · component overrides

  · nine screens hand-built this bar and six of them omitted env(safe-area-inset-bottom); the BottomBar implementation carrying the inset is now the adopted one, so the inset is COMPONENT-owned and never re-declared at a call site.

## Priorities — FooterBar

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — FooterBar

  mode boundary           PASS
  dimension classes       PASS
  token references        PASS
  ownership               PASS
  web mechanics           PASS
  touch geometry          PASS
  long content            n/a
  loading width           PASS
  UNSPECIFIED             none
  internal contradiction  PASS

## Implementation handoff — FooterBar

COMPONENT CONTRACT:
  FooterBar — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
surface · border-ghost · onSurfaceVariant
COMPOSED SHARED COMPONENTS — THE CHILD OWNS ITS COLOURS:
  · Button · tone=primary · width=block


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
