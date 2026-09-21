# MemoX v3 component · SheetActions

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `SheetActions` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# SheetActions — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · F · Overlays & feedback
NON-BINDING MATERIAL ANALOGY: a dialog / sheet footer holding a cancel and a confirm action
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

## Component visual intent — SheetActions

The footer every dialog and sheet ends with. The confirm sits at flex 1.3 and Cancel gives up width first, so a real verb ("Move to Trash") keeps its line — that ratio is the whole reason this is a component.

## Component contract — SheetActions

Dimensions — label, dimension class, value:
  layout              FIXED           row, gap 8 — cancel takes 1 share, confirm 1.3
  padding (dialog)    FIXED           16 all round
  padding (sheet)     FIXED           8 top · 16 sides · 16 bottom + 1px ghost top divider
  buttons             FIXED           the Button contract at its regular 48 size — outline + primary (or destructive on a delete confirm). This footer sets only the share each one takes
  confirm label budgetMAXIMUM         126px at 360 (106px with a glyph) — ≈18 Latin / 13 Hangul characters. The tightest button slot in the product: the dialog caps at 340 and the confirm takes 1.3 of 2.3
  custom footer       CONTENT-DRIVEN  children replace the pair (Trash restore / delete-forever)

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

## Foundation token references — SheetActions

Resolve each of these against the Foundations spec; none of them is redefined
here:

  op-disabled

## Theme consumption — SheetActions

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
  top divider · sheet               border-ghost  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      the 1px rule above a sheet footer
  cancel button                     Button  ·  tone=outline
      access: VIA_COMPONENT
      Cancel is a Button in its outline tone — Button owns every colour and border behind that tone
  confirm button                    Button  ·  tone=primary
      access: VIA_COMPONENT
      the default confirm is a Button in its primary tone
  confirm button · destructive      Button  ·  tone=destructive
      access: VIA_COMPONENT
      a destructive confirm selects the Button destructive tone; this footer never names the fill behind it
  confirm button · disabled         Button  ·  enabled=false
      access: VIA_COMPONENT
      the confirm is passed through disabled and the Button applies the global disabled rule — Cancel stays live

## Icons / content slots — SheetActions

Glyph names this component paints, verbatim from the kit:

  trash-2
  check
  folder-input

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## State matrix — SheetActions

  default           Cancel + confirm verb
  confirm disabled  the GLOBAL op-disabled opacity, no interaction — Cancel stays live
  long confirm verb the 1 / 1.3 ratio keeps the verb on one line; Cancel narrows. Past the 126px budget it wraps to two lines and the footer grows — shorten the verb
  destructive       the verb carries the meaning; the fill stays primary unless the screen says otherwise

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — SheetActions

  confirm verb
      the 1 / 1.3 ratio keeps the verb on one line and Cancel narrows first. Past the 126px budget the confirm label wraps to two lines and the footer grows — it never ellipsises. Shorten the verb instead.

## HTML/JSX translation notes — SheetActions

  WEB TECHNIQUE   flex: 1 and flex: 1.3 on the two buttons
  VISUAL INTENT   the confirm keeps its line and Cancel gives up width first — express the share, not the CSS property

## NOT PART OF CURRENT V3 CONTRACT

  · the confirmIcon prop exists in source but has NO v3 call site — every shipped confirm is text only. Not part of the current v3 contract (a 16 glyph + 4 gap would cost 20px of the 126px budget).

## Priorities — SheetActions

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — SheetActions

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

## Implementation handoff — SheetActions

COMPONENT CONTRACT:
  SheetActions — the dimension table, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): trash-2 · check · folder-input

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
border-ghost
COMPOSED SHARED COMPONENTS — THE CHILD OWNS ITS COLOURS:
  · Button · tone=outline
  · Button · tone=primary
  · Button · tone=destructive
  · Button · enabled=false


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

NOT PART OF CURRENT V3 CONTRACT:
  · the confirmIcon prop exists in source but has NO v3 call site — every shipped confirm is text only. Not part of the current v3 contract (a 16 glyph + 4 gap would cost 20px of the 126px budget).

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
