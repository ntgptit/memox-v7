# MemoX v3 component · ScreenScroll

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `ScreenScroll` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# ScreenScroll — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: IMPLEMENT_COMPONENT
  Build or extend a shared component for this contract.

Source: MemoX v3 HTML design kit · H · Layout shell
NON-BINDING MATERIAL ANALOGY: the single scrolling region of a screen
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

## Component visual intent — ScreenScroll

The single scrollable region per screen (.scroll). The horizontal gutter is one shared value and the bottom clearance is derived from whichever pinned chrome the screen has — never hand-tuned per screen.

## Component contract — ScreenScroll

Dimensions — label, dimension class, value:
  gutter              FIXED           16 · GLOBAL screen gutter (--memox-space-screen) — referenced, not redefined here
  clearance · plain/nav/footerMINIMUM         24 comfort + gesture inset
  clearance · FAB, no navMINIMUM         24 FAB inset + 52 FAB + 24 comfort + gesture inset
  clearance · FAB above navMINIMUM         4 gap + 52 FAB + 24 comfort + gesture inset
  content column      RESPONSIVE      single, full width inside the gutter

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

## Foundation token references — ScreenScroll

Resolve each of these against the Foundations spec; none of them is redefined
here:

  space-screen

## State matrix — ScreenScroll

  at rest           content from the top
  scrolled          the tail always clears the pinned chrome by the clearance above
  short content     no scroll; the clearance still applies

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Caller-owned — do NOT build into ScreenScroll

  · which pinned chrome the screen has, which is what selects the clearance row above

## HTML/JSX translation notes — ScreenScroll

  WEB TECHNIQUE   the preview hides the scrollbar
  VISUAL INTENT   PREVIEW concern only — not an app rule

## NOT PART OF CURRENT V3 CONTRACT

  · the ScreenScroll helper in _shared.jsx is a wrapper over .scroll with no v3 call site — screens apply the class directly.

## Priorities — ScreenScroll

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — ScreenScroll

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

## Implementation handoff — ScreenScroll

COMPONENT CONTRACT:
  ScreenScroll — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  IMPLEMENT_COMPONENT — Build or extend a shared component for this contract.

CALLER-OWNED — DO NOT ABSORB:
  · which pinned chrome the screen has, which is what selects the clearance row above

NOT PART OF CURRENT V3 CONTRACT:
  · the ScreenScroll helper in _shared.jsx is a wrapper over .scroll with no v3 call site — screens apply the class directly.

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
