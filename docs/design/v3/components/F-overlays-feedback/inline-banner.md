# MemoX v3 component · InlineBanner

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `InlineBanner` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# InlineBanner — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · F · Overlays & feedback
NON-BINDING MATERIAL ANALOGY: a MaterialBanner-like inline row
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

## Component visual intent — InlineBanner

One in-place message about the state of an operation or an object, with the action that resolves it — 13 hand-built copies before extraction, and it had already drifted on geometry. Distinct from Note (info, no border tone, no action) and from ErrorState (a whole-card load failure).

## Component contract — InlineBanner

Dimensions — label, dimension class, value:
  padding             FIXED           12 16 — 8 12 where the banner sits inside a commit bar (VARIANT)
  radius              FIXED           12 (--memox-radius-md)
  border              FIXED           1px in the tone border token
  glyph               FIXED           16 (icon step xs), top-aligned
  gap                 FIXED           8 glyph → text
  text                FIXED           12/1.55
  title               FIXED           700 with 2 below it, present only in the two-line form
  action row          FIXED           gap 8, 8 below the body — compact Buttons
  margin-bottom       FIXED           16 in a scroll · 0 as the last child of a commit bar
  height              CONTENT-DRIVEN  the message sets it — it wraps, never truncates

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

## Foundation token references — InlineBanner

Resolve each of these against the Foundations spec; none of them is redefined
here:

  radius-md

## Theme consumption — InlineBanner

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
  fill · warning                    warning-soft  ·  DERIVED_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the amber ground
  fill · danger                     danger-soft  ·  DERIVED_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the red ground
  border · warning                  warning  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: TINT 26% light / 32% dark
      the 1px edge — a tint of the warning role, carried by --memox-warning-border. THEME GAP: the derived-colour registry declares danger-border and success-border but not warning-border; report it rather than inventing the role here
  border · danger                   danger-border  ·  DERIVED_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      1px edge
  glyph · warning                   warning  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the alert glyph
  glyph · danger                    error  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the alert glyph
  title + body lead                 onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      full-strength ink on a tinted ground
  body detail                       onSurfaceVariant  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the explanatory clause after the bold lead
  actions                           Button  ·  size=compact
      access: VIA_COMPONENT
      the resolving actions are compact Buttons and own their own tones

## Icons / content slots — InlineBanner

Glyph names this component paints, verbatim from the kit:

  alert-circle
  refresh-cw

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — InlineBanner

  warning           amber ground and border — a refusal or a limit, nothing was lost
  danger            red ground and border — an operation failed
  titled            bold lead line, body below, actions under the body
  single line       one flowing line with the action in the trailing slot
  without action    a statement only — the condition resolves itself

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — InlineBanner

  body
      the message wraps to as many lines as it needs. A failure the user cannot read in full is worse than a tall banner, so nothing here truncates.
  action row
      two compact actions sit side by side; they keep their labels and the row wraps before a label is cut

## Caller-owned — do NOT build into InlineBanner

  · the message text, whether the condition is true, what the action does, and the banner position on the screen

## Resolved from source · component overrides

  · the reminder screen shipped 34/14 buttons where the other twelve sites used the compact 32/12; 32/12 is the contract (COMPONENT, corrected 2026-09-16).

## Priorities — InlineBanner

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — InlineBanner

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

## Implementation handoff — InlineBanner

COMPONENT CONTRACT:
  InlineBanner — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): alert-circle · refresh-cw

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
warning-soft · danger-soft · warning · danger-border · error · onSurface · onSurfaceVariant
COMPOSED SHARED COMPONENTS — THE CHILD OWNS ITS COLOURS:
  · Button · size=compact


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · the message text, whether the condition is true, what the action does, and the banner position on the screen

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
