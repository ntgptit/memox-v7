# MemoX v3 component · Scrim

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 component specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The `Scrim` component handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# Scrim — design specification for Flutter handoff

HANDOFF MODE: COMPONENT
IMPLEMENTATION ACTION: USE_PLATFORM
  Do NOT build a widget. The platform supplies this; configure it.

Source: MemoX v3 HTML design kit · F · Overlays & feedback
NON-BINDING MATERIAL ANALOGY: the dim behind a modal — platform modal-barrier configuration, not a standalone widget
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

## Component visual intent — Scrim

The dim behind every modal. The scrim ROLE token at 45% — not a hard-coded black, which is what made the dark theme look wrong before.

## Component contract — Scrim

Dimensions — label, dimension class, value:
  coverage            SYSTEM-OWNED    the whole app surface
  colour              FIXED           scrim role token at 45% alpha
  motion              FIXED           220ms fade in

FIXED means reproduce the value. MINIMUM means never go below it, grow freely.
MAXIMUM means never exceed it. CONTENT-DRIVEN means the content sets it — do
not convert it into a fixed box, and a content-driven control entering a
loading state keeps the width that instance already had. RESPONSIVE means it
changes with width or text scale. SYSTEM-OWNED means the platform supplies it.
UNSPECIFIED means this design does not determine the value: do not invent one —
keep the repository's existing convention where that is safe, and ask when
geometry, state behaviour, interaction, content loss or accessibility cannot be
settled without an answer.

## Theme consumption — Scrim

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
  barrier · visible                 scrim  ·  M3_COLOR
      access: DIRECT · treatment: OPACITY 0.45
      the scrim ROLE, never a hard-coded black

## State matrix — Scrim

  visible           45% dim
  tap               dismisses the modal it belongs to

Entries marked [INFERRED] are not drawn in the mock. Implement one only where
it matches the repository's existing design-system convention; otherwise keep
the canonical Flutter behaviour and report the mismatch. Never invent a new
convention to satisfy an inferred mock behaviour.

## Caller-owned — do NOT build into Scrim

  · which modal owns the barrier, and what tapping it dismisses

## HTML/JSX translation notes — Scrim

  WEB TECHNIQUE   Dialog and BottomSheet each draw their own scrim inside the preview frame, with a scrim={false} opt-out
  VISUAL INTENT   an artefact of nesting overlays in a phone div: the platform modal route owns the barrier and the full window. Take the 45% dim and the fade only — the opt-out flag is not part of the contract

## Priorities — Scrim

  P1  the dimension table and the tones/variants above — the component's own
      surface treatment, geometry and type
  P2  its states, icon steps and hairline / shadow treatment
  P3  motion and decorative polish
  Global palette, type scale and spacing rhythm are the FOUNDATIONS run's
  priorities, not this task's.

## Self-check — Scrim

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

## Implementation handoff — Scrim

COMPONENT CONTRACT:
  Scrim — the dimension table and state matrix above. The dimension
  CLASSIFICATIONS are binding; the source CSS class names are not.
  glyphs (Lucide names, map by meaning to Material Symbols): none

IMPLEMENTATION ACTION:
  USE_PLATFORM — Do NOT build a widget. The platform supplies this; configure it.

THEME ROLES CONSUMED DIRECTLY — READ, DO NOT REDEFINE:
scrim


THEME GAPS TO REPORT UPSTREAM:
  none — every role above is established by the theme prerequisite

CALLER-OWNED — DO NOT ABSORB:
  · which modal owns the barrier, and what tapping it dismisses

Everything else (tokens, colour, type, spacing, composition, responsive rules)
comes from the Foundations spec — do not re-derive it from this prompt.

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
  status bar (44 in the preview) · cutout · gesture/nav inset · keyboard
  inset · system Back · the device bezel
  THIS ITEM IS ONE OF THEM — build nothing.

DO NOT COPY LITERALLY FROM HTML/JSX:
  absolute positioning · ::after hit expanders · backdrop-filter · color-mix
  overlays · hover states · fake system chrome · fixed pixel boxes around text
