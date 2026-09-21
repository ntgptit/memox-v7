# MemoX v3 component · MasteryRamp

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `MasteryRamp` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# MasteryRamp — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_UTILITY
  Implement as logic (a function / mapping), not as a visual widget.

Source: MemoX v3 HTML design kit · E · Status & metadata
NON-BINDING MATERIAL ANALOGY: a colour/threshold function — not a visual widget
  Orientation only. Inspect the repository and map this contract onto what is
  already there — do not read the analogy as a widget tree to reproduce.

> Run the MemoX Foundations spec ONCE before this prompt. It carries the palette
> (both themes), the type scale, the spacing / radius / icon / elevation scales,
> the semantic alias layer, screen composition, responsive rules and the web
> techniques that must not be copied. Everything below assumes it and names
> tokens instead of repeating values.

## Implementation guardrails

Implement as logic (a function / mapping), not as a visual widget.

Before implementing: inspect the Flutter repository — its existing shared
widgets, theme and tokens. Reuse or extend whatever already owns this semantic
contract instead of adding a parallel one, map this contract onto the existing
theme / token architecture, and never re-declare a Foundations value locally
when a token or theme role already exists.

THIS UTILITY OWNS: the thresholds and the role each one resolves to. It paints nothing: no geometry, no states, no touch target, no layout.

THE CALLER OWNS: screen placement · external spacing · navigation · business
rules · validation flow · feature state management. Do not pull a caller-owned
concern in because the HTML mock colocates them.

Source-design identifiers (CSS class names, JSX component names) appear below
for traceability only. They are NOT Flutter API names and a CSS class is not a
variant enum — expose the smallest semantic API this contract needs. Global
palette / type / spacing / composition work belongs to the Foundations run.

## Component visual intent — MasteryRamp

The single-colour mastery ramp (masteryColor). One threshold function feeds every mastery fill in the product, so a 40% deck is the same colour on every screen. It replaced a three-stop gradient.

## Component contract — MasteryRamp

Dimensions — label, dimension class, value:
  < 34%               FIXED           status-learning (amber)
  34–66%              FIXED           status-reviewing (indigo)
  ≥ 67%               FIXED           status-mastered (green)
  track               FIXED           progress-track (= surfaceContainerHigh)

FIXED means reproduce the value. MINIMUM means never go below it, grow freely.
MAXIMUM means never exceed it. CONTENT-DRIVEN means the content sets it — do
not convert it into a fixed box, and a content-driven control entering a
loading state keeps the width that instance already had. RESPONSIVE means it
changes with width or text scale. SYSTEM-OWNED means the platform supplies it.
UNSPECIFIED means this design does not determine the value: do not invent one —
keep the repository's existing convention where that is safe, and ask when
geometry, state behaviour, interaction, content loss or accessibility cannot be
settled without an answer.

## Foundation token references — MasteryRamp

Resolve each of these against the Foundations spec; none of them is redefined
here:

  progress-track · status-learning · status-mastered · status-reviewing · surfaceContainerHigh

## Theme consumption — MasteryRamp

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
  fill · < 34%                      status-learning  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the low band
  fill · 34–66%                     status-reviewing  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the middle band
  fill · ≥ 67%                      status-mastered  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the high band — green means mastery, never tertiary
  track                             progress-track  ·  M3_ALIAS
      access: DIRECT · treatment: FULL_STRENGTH
      resolves to surfaceContainerHigh

## State matrix — MasteryRamp

  0%                track only — no fill is painted
  low / mid / high  the three ramp colours above; a single flat fill, never a gradient

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Caller-owned — do NOT build into MasteryRamp

  · the bar that displays the ramp — e.g. the deck-row progress bar at height 5, full row width, is SCREEN composition in the deck list

## Priorities — MasteryRamp

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — MasteryRamp

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

## Implementation handoff — MasteryRamp

COMPONENT CONTRACT:
  MasteryRamp — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  IMPLEMENT_UTILITY — Implement as logic (a function / mapping), not as a visual widget.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
status-learning · status-reviewing · status-mastered · progress-track


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · the bar that displays the ramp — e.g. the deck-row progress bar at height 5, full row width, is SCREEN composition in the deck list

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
