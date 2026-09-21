# MemoX v3 component · StatusBar

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `StatusBar` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# StatusBar — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: USE_PLATFORM
  Do NOT build a widget. The platform supplies this; configure it.

Source: MemoX v3 HTML design kit · A · Chrome & navigation
NON-BINDING MATERIAL ANALOGY: the platform status bar — no app widget exists for it
  Orientation only. Inspect the repository and map this contract onto what is
  already there — do not read the analogy as a widget tree to reproduce.

> Run the MemoX Foundations spec ONCE before this prompt. It carries the palette
> (both themes), the type scale, the spacing / radius / icon / elevation scales,
> the semantic alias layer, screen composition, responsive rules and the web
> techniques that must not be copied. Everything below assumes it and names
> tokens instead of repeating values.

## Implementation guardrails

Do NOT build a widget. The platform supplies this; configure it. Inspect the repository only to confirm the platform behaviour is
already configured. Reserve whatever inset or barrier the platform reports at
runtime; never turn a dimension below into an app token or a fixed spacer, and
never paint a replacement for it.

THE CALLER OWNS: everything else on the screen.

## Component visual intent — StatusBar

Mock status bar drawn by the preview frame only. Android owns the real one; reserve the inset, never paint this.

## Component contract — StatusBar

Dimensions — label, dimension class, value:
  height              SYSTEM-OWNED    44 · PREVIEW (kit frame chrome, never an app token)
  padding             SYSTEM-OWNED    0 24 · PREVIEW
  content             SYSTEM-OWNED    time + signal/wifi/battery glyphs

FIXED means reproduce the value. MINIMUM means never go below it, grow freely.
MAXIMUM means never exceed it. CONTENT-DRIVEN means the content sets it — do
not convert it into a fixed box, and a content-driven control entering a
loading state keeps the width that instance already had. RESPONSIVE means it
changes with width or text scale. SYSTEM-OWNED means the platform supplies it.
UNSPECIFIED means this design does not determine the value: do not invent one —
keep the repository's existing convention where that is safe, and ask when
geometry, state behaviour, interaction, content loss or accessibility cannot be
settled without an answer.

## Priorities — StatusBar

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — StatusBar

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

## Implementation handoff — StatusBar

COMPONENT CONTRACT:
  StatusBar — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  USE_PLATFORM — Do NOT build a widget. The platform supplies this; configure it.

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel
  THIS ITEM IS ONE OF THEM — build nothing.

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
