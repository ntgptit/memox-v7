# MemoX v3 component · WorkloadBreakdownLine

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `WorkloadBreakdownLine` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# WorkloadBreakdownLine — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · E · Status & metadata
NON-BINDING MATERIAL ANALOGY: a Text.rich of tokenised count spans — a colour mapping, not a layout
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

## Component visual intent — WorkloadBreakdownLine

The "N overdue · N today · N new" statement and the token behind each term. Six sites painted it in THREE different mappings. One mapping now — the sibling of MasteryRamp: one function owning one colour decision for the whole product.

## Component contract — WorkloadBreakdownLine

Dimensions — label, dimension class, value:
  band height         MINIMUM         18 · COMPONENT — ONE line, ellipsis
  type                FIXED           12 · coloured terms 600 · tabular
  separator           FIXED           a middot with a space either side, dropped with its term at zero
  term order          FIXED           overdue → today → new — urgency first, never re-ordered
  margin-top          FIXED           2 — it sits under a row title
  width               CONTENT-DRIVEN  the counts set it; the band never wraps to a second line

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

## Foundation token references — WorkloadBreakdownLine

Resolve each of these against the Foundations spec; none of them is redefined
here:

  mastery · status-new

## Theme consumption — WorkloadBreakdownLine

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
  overdue term                      on-warning  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      past due — the only term that is a problem. The kit scopes --memox-warning-ink to on-warning in Light and to the amber itself on the Nebula navy: the warning FILL fails contrast as 12px text on a light surface
  today term                        primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      due today — the actionable term
  new term                          status-new  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      never studied — the same token the card lifecycle uses
  separators + fallback line        onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the connective tissue and the nothing-due sentence

## State matrix — WorkloadBreakdownLine

  full              all three terms, each in its token
  partial           terms at zero are dropped with their separator — no "0 overdue"
  nothing due       one calm line: "N cards · nothing due", or "Nothing due" without a total
  no cards          "No cards yet" — a deck that cannot be studied at all
  with suffix       the caller trailing clause ("across 4 decks") follows the terms in the variant tone

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — WorkloadBreakdownLine

  the whole band
      ONE line with an ellipsis, not wrapping: the breakdown wrapping on the longest deck made that row 18px taller than its neighbours. Each term is individually nowrap so a break never lands inside "41 overdue".

## Component-specific responsive notes — WorkloadBreakdownLine

  large text
      the band still refuses a second line and truncates from the right — overdue, the urgent term, is the one that survives

## Caller-owned — do NOT build into WorkloadBreakdownLine

  · the counts, and the scope they describe (library · deck · session) — the component states numbers, it never fetches or sums them

## Resolved from source · component overrides

  · the new-card count was painted with --memox-mastery on Study home and Study entry while Cards used --memox-status-new for the same number; status-new is the single mapping (GLOBAL semantic, not a per-screen choice).

## Priorities — WorkloadBreakdownLine

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — WorkloadBreakdownLine

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

## Implementation handoff — WorkloadBreakdownLine

COMPONENT CONTRACT:
  WorkloadBreakdownLine — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
on-warning · primary · status-new · onSurfaceVariant


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · the counts, and the scope they describe (library · deck · session) — the component states numbers, it never fetches or sums them

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
