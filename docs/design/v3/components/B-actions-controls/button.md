# MemoX v3 component · Button

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `Button` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# Button — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · B · Actions & controls
NON-BINDING MATERIAL ANALOGY: a filled / tonal / outlined button
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

## Component visual intent — Button

A calm rectangular action with a 12 radius and a 14/600 label, sized by role rather than by call site: one full-size action, one small action, one inline-banner action, one chip-geometry action.

## Component contract — Button

One button contract owns height, radius and type for every button in the kit. Four tones and four painted sizes cover every shipped role; call sites never re-declare the base geometry.

Dimensions — label, dimension class, value:
  height              MINIMUM         48 regular · 36 small · 32 compact · 28 chip — painted at exactly this in every shipped instance; MINIMUM, not FIXED, so a wrapped label or OS text scaling grows the box instead of clipping it
  radius              FIXED           12 (--memox-radius-button) · 8 compact (radius-sm) · full chip · full on the study action
  padding             FIXED           0 16 regular · 0 12 small numeric / 0 16 small with a glyph · 0 12 compact · 0 8 chip · 0 36 study action
  label type          FIXED           14/600, 0.1px tracking · 12/600 on compact and chip
  icon gap            FIXED           4 · leading glyph at 16 (icon xs)
  width               CONTENT-DRIVEN  content-driven. Only the caller can constrain it: the block variant fills the parent, and a button given a flex share in a dialog/sheet action row takes that share
  width while loading FIXED           the width the instance already had — a spinner never collapses the control to its own intrinsic width
  tones               FIXED           primary (primary/onPrimary) · secondary (surfaceContainer/onSurface) · outline (transparent/primary + 1px outlineVariant) · destructive (error-fill/on-error-fill, no border)
  touch area          MINIMUM         48 — a centred band around the painted box. The 36, 32 and 28 sizes stay painted at their own height

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

## Foundation token references — Button

Resolve each of these against the Foundations spec; none of them is redefined
here:

  error-fill · on-error-fill · onPrimary · onSurface · op-disabled · op-press · outlineVariant · radius-button · radius-sm · size-button-sm · surfaceContainer

## Theme consumption — Button

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
  container · primary tone          primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the filled action
  label + glyph · primary tone      onPrimary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      content on the primary fill
  container · secondary tone        surfaceContainer  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the tonal action
  label + glyph · secondary tone    onSurface  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      content on the tonal fill
  container · outline tone          transparent  ·  NONE
      access: DIRECT · treatment: NO_FILL
      no painted container fill
  label + glyph · outline tone      primary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      content on the page ground
  border · outline tone             outlineVariant  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      1px edge
  container · destructive tone      error-fill  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      the SOLID destructive fill — deeper than error, which is the error text colour
  label + glyph · destructive tone  on-error-fill  ·  MEMOX_SEMANTIC_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      content on the destructive fill
  container · chip variant          surfaceContainerLowest  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      chip-geometry fill
  border · chip variant             border-ghost  ·  DECORATION
      access: DIRECT · treatment: FULL_STRENGTH
      chip hairline
  whole control · disabled          op-disabled  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      the GLOBAL disabled rule — referenced, not redefined here
  state overlay · pressed           op-press  ·  STATE_TOKEN
      access: DIRECT · treatment: APPLY_TOKEN (the token's own value)
      the GLOBAL pressed rule
  focus ring · focused              primary  ·  M3_COLOR
      access: DIRECT · treatment: BORDER
      the GLOBAL focus treatment
  spinner · loading                 onPrimary  ·  M3_COLOR
      access: DIRECT · treatment: FULL_STRENGTH
      inside a filled button; primary on a transparent one

## Icons / content slots — Button

Glyph names this component paints, verbatim from the kit:

  play
  plus
  refresh-cw
  check
  trash-2

These are LUCIDE names. The kit uses Lucide as a stand-in because the HTML
preview has no Material Symbols dependency; the app ships Material Symbols.
Do not treat the string as an Icons.* identifier — pick the nearest Material
Symbol by MEANING, and keep the meaning stable across every screen that uses
it (one concept, one glyph). Where the glyph arrives as a slot, the name above
is what the kit demonstrates, not a fixed part of the contract; the size step
in the dimension table IS fixed.

## Variants — Button

  regular · 48          the base contract — dialog and sheet confirms, primary screen actions
  block                 regular geometry, width 100% of the parent — sticky footers, empty-state actions. The only variant the caller routinely width-constrains
  small · 36            height --memox-size-button-sm, padding 0 12 (numeric, e.g. the reminder time) or 0 16 (glyph + label), 14px label. FOUR shipped call sites: reminder time, tag-management empty action, two DeckImport file pickers
  compact · 32          padding 0 12, radius 8, 12px label — inline banner action, app-bar action
  chip · 28             padding 0 8, radius full, 12px label, surfaceContainerLowest + ghost border. Geometry only; the selectable filter and the menu trigger are FilterChip and ChipTrigger
  study action          regular 48 height with radius full and padding 0 36 — three shipped call sites in the Recall and Fill study screens

## State matrix — Button

  enabled           tone fill as above
  pressed           platform state overlay at the op-press value from Foundations — the kit paints no :active rule [INFERRED]
  focused           2px primary ring, offset 2
  disabled          the GLOBAL op-disabled opacity, no interaction — ONE value for every disabled button
  loading           the label is replaced by a 16 spinner (onPrimary inside a filled button) and the control keeps the width and height it already had [INFERRED]

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Long-content behaviour — Button

  regular, width not constrained
      ONE line: the button grows horizontally with the label. No wrap, no ellipsis.
  regular, width constrained by the caller (block, or a flex share in a dialog/sheet row)
      the label wraps, centred, to at most two lines and the box grows to fit them. No ellipsis, ever. Tightest slot in the product is a dialog confirm at 360: 126px for the label, 106px with a leading glyph — about 18 Latin or 13 Hangul characters. Past two lines the verb is too long: shorten it (authoring rule, checked with tools/button-fit.html).
  small · 36
      ONE line, grows horizontally. Wrapping is out of contract at this height — keep the label to a short verb or a numeric value.
  compact · 32
      ONE line, grows horizontally. Never constrained in v3 (it sits inline in a banner or an app-bar action row), so it never wraps.
  chip · 28
      ONE line, always. The chip row scrolls horizontally and the chip never shrinks, so a long label lengthens the chip — it never wraps and never truncates.
  study action
      ONE line, grows horizontally — it sits centred in a study footer with nothing constraining its width. Same rule as an unconstrained regular button.

## Component-specific responsive notes — Button

  large text
      labels grow with the OS text scale. Unconstrained instances widen; constrained instances wrap and the box grows (height is MINIMUM). Nothing is clamped and nothing is clipped.
  narrow width
      a block button follows the content column; an unconstrained button keeps its intrinsic width

## Resolved from source · component overrides

  · FIXED-height vs wrapping label: the kit CSS sets height + no white-space rule, which in a browser paints a second line outside the box. That is a web artefact, not an intent — and Foundations forbids a fixed box around text. RESOLVED: the height is the painted floor (MINIMUM) and the box grows for a wrapped label. No shipped instance changes, because every shipped label fits one line.
  · Three sizes vs a shipped fourth: the stylesheet comment says "a 4th size is a smell", but 36 (--memox-size-button-sm) ships in four call sites and Foundations documents it. RESOLVED: 36 is a real Button size (small); it is applied inline in source only because no class modifier was ever added. The stylesheet comment is stale.
  · Three tones vs a shipped fourth: destructive (--memox-error-fill / --memox-on-error-fill) ships in the tag-delete and trash-delete confirms. RESOLVED: four tones.
  · COMPONENT OVERRIDE — touch floor: the 36, 32 and 28 sizes are painted below the 48 global minimum on purpose. Scope: painted geometry only; the interactive target stays 48.

## HTML/JSX translation notes — Button

  WEB TECHNIQUE   inline style overrides at the call site (height, radius, padding, background)
  VISUAL INTENT   these are the small / study-action / destructive variants above — read them as variants of one contract, not as per-screen freedom
  WEB TECHNIQUE   flex: 1 / flex: 1.3 on dialog and sheet confirms
  VISUAL INTENT   the caller decides how the pair shares the row; the button itself is content-driven
  WEB TECHNIQUE   a CSS class per size (.compact, .chip, .block)
  VISUAL INTENT   source-design identifiers for traceability — not Flutter API names and not variant enum values

## Priorities — Button

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — Button

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

## Implementation handoff — Button

COMPONENT CONTRACT:
  Button — the dimension table, variants, long-content rules and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): play · plus · refresh-cw · check · trash-2

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
primary · onPrimary · surfaceContainer · onSurface · transparent · outlineVariant · error-fill · on-error-fill · surfaceContainerLowest · border-ghost · op-disabled · op-press


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
