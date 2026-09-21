# MemoX v3 theme binding

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 theme-binding specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The handoff JSON `themeHandoff` field. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# MemoX v3 — Flutter theme implementation prerequisite

RUN ORDER: FOUNDATIONS → **THIS** → shared components → screens.
This is NOT a fourth handoff mode and NOT a design layer: it is the binding
step between the design Foundations and ONE common Flutter theme. No shared
component task is runnable until it is done.

## How to read this document

This step has two structured sources, each authoritative for ONE thing:

  themeRegistry              source of truth for THEME SEMANTIC BINDING: kind,
                             value, destination, alias evidence, derivation,
                             usage status, runtime disposition
  widgets[*].themeRoleUsage  source of truth for COMPONENT THEME CONSUMPTION:
                             slot, state, access, role / child configuration /
                             instance input, treatment

FOUNDATIONS stays authoritative for the rest of the design truth — typography,
spacing, geometry, sizing, motion. This step BINDS those values to the
repository's theme; it does not author them, and where a number here comes from
Foundations it is rendered from the same source the Foundations spec renders.

Every theme table, consumer list and index in this document is a GENERATED VIEW
over the two sources above. Editing the prose changes nothing. If a value here
is wrong, the registry or the component's usage record is wrong — fix it there
and regenerate.

## Repository inspection — do this first

Inspect the existing Flutter repository before changing anything. Identify:

  current ThemeData construction · light and dark ColorScheme definitions ·
  the current TextTheme · existing theme extensions / semantic-colour layers ·
  existing spacing / radius / sizing token classes · existing Material
  component-theme configuration · existing shared-widget theming conventions

Reuse and extend the canonical implementation. Do not create a parallel theme
system, and do not replace a larger canonical role set with this smaller
V3-specific palette.

## Theme architecture rules

  1. Standard Material colour semantics resolve through the ColorScheme.
  2. MemoX product SEMANTIC COLOURS that Material has no honest role for
     resolve through ONE semantic-colour mechanism the repository already has;
     introduce the smallest compatible extension only if none exists. This
     rule covers MEMOX_SEMANTIC_COLOR only — every other kind routes to its own
     destination (DERIVED_COLOR to central derivation, DECORATION to the
     decoration/token mechanism, STATE_TOKEN to the global state policy,
     EFFECT_TOKEN to the effect mechanism, M3_ALIAS to its ColorScheme role).
  3. Typography resolves through the shared TextTheme / canonical typography.
  4. Spacing, radius, control dimensions, icon sizes and the touch minimum
     belong to the repository's design-token system — never to ColorScheme.
  5. Component-specific geometry stays in the component contract; screen
     arrangement stays in the screen composition.
  6. If V3 does not determine a role the repository already defines (the
     Fixed family, container roles V3 never paints), PRESERVE the existing
     canonical definition. Do not invent a V3 colour to fill it, and do not
     delete the role. Report what you preserved.

## Runtime theme size control — read before you add a field

GENERATED VIEW from themeRegistry.implementationDisposition.

DO NOT create a theme field for every Foundation semantic just because it
appears in this registry. The design registry is deliberately LARGER than the
runtime semantic extension, and that is allowed.

  BIND_NOW       28 semantics — the current V3 implementation needs them;
                 make sure the common theme can provide them
  PRESERVE_ONLY  15 semantics — Foundation/design truth with no active V3
                 consumer path. Keep them documented, keep an existing repo
                 definition if one is already there, and do NOT add a new
                 unused field for them.

BIND_NOW does NOT mean "put it in the MemoX semantic extension". Each semantic
is routed by its KIND, and only some kinds store a value of their own:

  the existing MemoX semantic-colour mechanism
    mastery · warning · on-warning · status-new · status-learning · status-reviewing · status-mastered · error-fill · on-error-fill
  ColorScheme — resolve to the target role, no new field [stores nothing]
    bg · surface-muted · surface-raised · progress-track · text-secondary
  central colour derivation
    danger-soft · danger-border · warning-soft · surface-hero · chrome-glass
  the decoration / token mechanism
    shadow-soft · shadow-card · shadow-chrome · shadow-fab · border-ghost
  the global state-token / policy mechanism
    op-disabled · op-press
  the effect / token mechanism
    op-glass · glass-blur

  PRESERVE_ONLY (same routing when a definition already exists; add nothing new)
    success · streak · on-streak · mastery-fixed · on-danger · text-muted · badge-bg · danger · text-primary · primary-soft · primary-border · success-soft · shadow-none · border-strong · op-hover

This rule governs MemoX-specific semantics only; it never shrinks the canonical
M3 ColorScheme role set below.

## Standard M3 ColorScheme binding — the COMPLETE canonical role set

Every canonical Material 3 role, each with exactly one disposition.
V3_DEFINED — the design owns the value. REPO_PRESERVED — V3 says nothing:
keep the repository's canonical definition, invent nothing, delete nothing.

  role                      disposition      light / dark or action
  primary                   V3_DEFINED       #5265F5 / #8B9AFF
  onPrimary                 V3_DEFINED       #FFFFFF / #11173A
  primaryContainer          V3_DEFINED       #E0E5FE / #2D346A
  onPrimaryContainer        V3_DEFINED       #1A2580 / #D9DFFF
  secondary                 V3_DEFINED       #6E7CD9 / #9DA8E8
  onSecondary               V3_DEFINED       #FFFFFF / #1A2150
  secondaryContainer        V3_DEFINED       #E3E6F7 / #343C78
  onSecondaryContainer      V3_DEFINED       #262E6E / #DDE2FB
  tertiary                  V3_DEFINED       #8B6FF5 / #B5A0FF
  onTertiary                V3_DEFINED       #FFFFFF / #240B63
  tertiaryContainer         V3_DEFINED       #EBE3FE / #443078
  onTertiaryContainer       V3_DEFINED       #33177E / #E6DCFF
  error                     V3_DEFINED       #DC2D4E / #FF8FA3
  onError                   V3_DEFINED       #FFFFFF / #52061B
  errorContainer            V3_DEFINED       #FBDDE3 / #7A2036
  onErrorContainer          V3_DEFINED       #7A0A23 / #FFD9DF
  primaryFixed              REPO_PRESERVED   keep the canonical repository definition
  primaryFixedDim           REPO_PRESERVED   keep the canonical repository definition
  onPrimaryFixed            REPO_PRESERVED   keep the canonical repository definition
  onPrimaryFixedVariant     REPO_PRESERVED   keep the canonical repository definition
  secondaryFixed            REPO_PRESERVED   keep the canonical repository definition
  secondaryFixedDim         REPO_PRESERVED   keep the canonical repository definition
  onSecondaryFixed          REPO_PRESERVED   keep the canonical repository definition
  onSecondaryFixedVariant   REPO_PRESERVED   keep the canonical repository definition
  tertiaryFixed             REPO_PRESERVED   keep the canonical repository definition
  tertiaryFixedDim          REPO_PRESERVED   keep the canonical repository definition
  onTertiaryFixed           REPO_PRESERVED   keep the canonical repository definition
  onTertiaryFixedVariant    REPO_PRESERVED   keep the canonical repository definition
  surfaceDim                V3_DEFINED       #DAE0EF / #060925
  surface                   V3_DEFINED       #F7F9FE / #0A0E27
  surfaceBright             V3_DEFINED       #FFFFFF / #232B5A
  surfaceContainerLowest    V3_DEFINED       #FFFFFF / #131A3A
  surfaceContainerLow       V3_DEFINED       #F1F4FB / #1B2249
  surfaceContainer          V3_DEFINED       #E9EDF7 / #232B5A
  surfaceContainerHigh      V3_DEFINED       #E2E7F3 / #2C356E
  surfaceContainerHighest   V3_DEFINED       #DAE0EF / #353D7E
  onSurface                 V3_DEFINED       #0F1638 / #E4E8FA
  onSurfaceVariant          V3_DEFINED       #4A5278 / #A4ACD0
  outline                   V3_DEFINED       #7C85AB / #5A6BAE
  outlineVariant            V3_DEFINED       #C5CBE3 / #2A3267
  inverseSurface            V3_DEFINED       #34395D (both themes)
  onInverseSurface          V3_DEFINED       #E8EAFC (both themes)
  inversePrimary            V3_DEFINED       #8B9AFF / #5265F5
  scrim                     V3_DEFINED       #0A0E27 / #000000
  shadow                    V3_DEFINED       #0F1638 / #000000

None of these may be copied into a custom semantic layer, a widget constant or
a local hex.

## MemoX semantic colour binding — MEMOX_SEMANTIC_COLOR

GENERATED VIEW from themeRegistry where kind == MEMOX_SEMANTIC_COLOR.

These are product semantics, not Material roles. Do not overload primary /
secondary / tertiary to avoid a semantic role: tertiary is the violet accent
and green means mastery. Equally, do not introduce a MemoX copy of a role the
ColorScheme already owns. Two semantics may share an authored value and still
be two semantics.

  mastery
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #1F8A5B / #6FE0BD
    the repository semantic-colour mechanism (theme extension or equivalent)
  success
    kind: MEMOX_SEMANTIC_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #2BA88B / #6FE0BD
    the repository semantic-colour mechanism (theme extension or equivalent)
  warning
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #F59E0B / #FFC658
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-warning
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #3A2A00 / #2A1E00
    the repository semantic-colour mechanism (theme extension or equivalent)
  streak
    kind: MEMOX_SEMANTIC_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #F97316 / #FFAE6E
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-streak
    kind: MEMOX_SEMANTIC_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #FFFFFF (both themes)
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-new
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #8C95B8 / #6B75A3
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-learning
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #F59E0B / #FFC658
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-reviewing
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #5265F5 / #8B9AFF
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-mastered
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #1F8A5B / #6FE0BD
    the repository semantic-colour mechanism (theme extension or equivalent)
  error-fill
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #DC2D4E / #B0485C
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-error-fill
    kind: MEMOX_SEMANTIC_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: #FFFFFF (both themes)
    the repository semantic-colour mechanism (theme extension or equivalent)
  mastery-fixed
    kind: MEMOX_SEMANTIC_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #C7F2D8 / #1F4A37
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-danger
    kind: MEMOX_SEMANTIC_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #FFFFFF / #2A0A12
    the repository semantic-colour mechanism (theme extension or equivalent)
  text-muted
    kind: MEMOX_SEMANTIC_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #7C85AB / #5A6BAE
    the repository semantic-colour mechanism (theme extension or equivalent)

## Semantic alias resolution — M3_ALIAS

GENERATED VIEW from themeRegistry where kind == M3_ALIAS. An alias gets no
theme property of its own — it resolves to the named role. Every entry here
carries BOTH proofs: value equality in every theme AND semantic equivalence.
Value equality alone is never enough, which is why on-danger and text-muted
are MEMOX_SEMANTIC_COLOR and not aliases.

  bg
    kind: M3_ALIAS · DIRECTLY_CONSUMED · BIND_NOW
    value: #F7F9FE / #0A0E27
    resolves to surface — the page ground IS the surface role; the kit renames it for readability only. No second theme property.
  surface-muted
    kind: M3_ALIAS · DIRECTLY_CONSUMED · BIND_NOW
    value: #F1F4FB / #1B2249
    resolves to surfaceContainerLow — the input / Note resting fill is that step of the same surface ladder. No second theme property.
  surface-raised
    kind: M3_ALIAS · DIRECTLY_CONSUMED · BIND_NOW
    value: #FFFFFF / #131A3A
    resolves to surfaceContainerLowest — the card fill is that surface step in BOTH themes (#FFFFFF light / #131A3A dark) — no separate property, no brightness branch. No second theme property.
  progress-track
    kind: M3_ALIAS · DIRECTLY_CONSUMED · BIND_NOW
    value: #E2E7F3 / #2C356E
    resolves to surfaceContainerHigh — an unfilled track is a surface step, authored as that role. No second theme property.
  badge-bg
    kind: M3_ALIAS · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #E9EDF7 / #232B5A
    resolves to surfaceContainer — a surface-ladder step authored as surfaceContainer. It is NOT the current badge fill: the tonal Badge tints its own tone at 12% and nothing in v3 reads this token. The alias evidence is the surface step, not a badge treatment.. No second theme property.
  danger
    kind: M3_ALIAS · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #DC2D4E / #FF8FA3
    resolves to error — destructive FOREGROUND semantics — the same role as error, renamed for product vocabulary. No second theme property.
  text-primary
    kind: M3_ALIAS · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: #0F1638 / #E4E8FA
    resolves to onSurface — primary ink IS onSurface. No second theme property.
  text-secondary
    kind: M3_ALIAS · DIRECTLY_CONSUMED · BIND_NOW
    value: #4A5278 / #A4ACD0
    resolves to onSurfaceVariant — secondary ink IS onSurfaceVariant. No second theme property.

## Derived colours — DERIVED_COLOR

GENERATED VIEW from themeRegistry where kind == DERIVED_COLOR. Implement each
derivation ONCE, centrally. Never per widget, and never by copying a CSS
color-mix() string. A component that consumes a derived colour applies NO
percentage of its own — the derivation is already done here.

  primary-soft
    kind: DERIVED_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: color-mix(in srgb, #5265F5 10%, transparent) / color-mix(in srgb, #8B9AFF 20%, transparent)
    primary @ 10% light / 20% dark over transparent
    NOTE: PRESERVE_ONLY today: v3 paints no call site for it. The three places that look like it each tint primary themselves at a different percentage — BottomNav active pill 14/20, the icon tile 10/16, the EmptyState tile 10/10 — so they bind primary with an explicit component treatment instead. Keep the token; do not silently repoint those three at it, and do not add a runtime field until the design collapses them onto one value.
  primary-border
    kind: DERIVED_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: color-mix(in srgb, #5265F5 24%, transparent) / color-mix(in srgb, #8B9AFF 32%, transparent)
    primary @ 24% light / 32% dark over transparent
  danger-soft
    kind: DERIVED_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: color-mix(in srgb, #DC2D4E 8%, transparent) / color-mix(in srgb, #FF8FA3 16%, transparent)
    error @ 8% light / 16% dark over transparent
  danger-border
    kind: DERIVED_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: color-mix(in srgb, #DC2D4E 22%, transparent) / color-mix(in srgb, #FF8FA3 32%, transparent)
    error @ 22% light / 32% dark over transparent
  success-soft
    kind: DERIVED_COLOR · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: color-mix(in srgb, #2BA88B 10%, transparent) / color-mix(in srgb, #6FE0BD 18%, transparent)
    success @ 10% light / 18% dark over transparent
  warning-soft
    kind: DERIVED_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: color-mix(in srgb, #F59E0B 12%, transparent) / color-mix(in srgb, #FFC658 18%, transparent)
    warning @ 12% light / 18% dark over transparent
  surface-hero
    kind: DERIVED_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: color-mix(in srgb, #5265F5 5%, #FFFFFF) / color-mix(in srgb, #8B9AFF 12%, #0A0E27)
    primary @ 5% light / 12% dark over surfaceBright in LIGHT, surface in DARK — the bases differ by theme
  chrome-glass
    kind: DERIVED_COLOR · DIRECTLY_CONSUMED · BIND_NOW
    value: rgba(247, 249, 254, 0.84) / rgba(10, 14, 39, 0.84)
    surface @ alpha from op-glass over the runtime backdrop — composite at paint time, never pre-flattened against a fixed page colour · alpha owned by op-glass

A component consuming one of these carries treatment FULL_STRENGTH — the
untransformed treatment. (FULL_STRENGTH is a TREATMENT; DIRECT is an ACCESS
MODE. The two vocabularies never overlap.)

surface-hero is the one whose base changes with the theme: primary @5% over
surfaceBright in Light, primary @12% over the page surface in Dark. Do not
assume one base for both.

## Decoration treatments — DECORATION

GENERATED VIEW from themeRegistry where kind == DECORATION. SOURCE TOKEN NAME
≠ CANONICAL SEMANTIC NAME. Bind the semantic; the variable name is traceability
only (shadow-card is the OVERLAY shadow — the Card uses shadow-soft).

  shadow-soft
    kind: DECORATION · DIRECTLY_CONSUMED · BIND_NOW
    value: 0 1px 2px rgba(15,22,56,0.04) / none
    card-whisper-shadow — Card, Toggle thumb — none in Dark, which draws the hairline instead
  shadow-card
    kind: DECORATION · DIRECTLY_CONSUMED · BIND_NOW
    value: 0 12px 32px rgba(15,22,56,0.10) / 0 16px 40px rgba(0,0,0,0.42)
    overlay-shadow — Dialog — NOT the Card, despite the token name
  shadow-chrome
    kind: DECORATION · DIRECTLY_CONSUMED · BIND_NOW
    value: 0 -2px 12px rgba(15,22,56,0.05) / 0 -2px 14px rgba(0,0,0,0.36)
    chrome-shadow — BottomSheet and bottom chrome
  shadow-fab
    kind: DECORATION · DIRECTLY_CONSUMED · BIND_NOW
    value: 0 8px 24px rgba(15,22,56,0.12) / 0 10px 28px rgba(0,0,0,0.5)
    fab-shadow — the floating action
  shadow-none
    kind: DECORATION · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: none (both themes)
    no-shadow — explicit absence
  border-ghost
    kind: DECORATION · DIRECTLY_CONSUMED · BIND_NOW
    value: 1px solid rgba(82, 101, 245, 0.14) / 1px solid rgba(139, 154, 255, 0.16)
    hairline-edge — the 1px primary-tinted edge on cards, chips, dividers and chrome
  border-strong
    kind: DECORATION · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: 1px solid #C5CBE3 / 1px solid #2A3267
    strong-edge — the 1px outlineVariant edge — a border SHORTHAND (width + style + role), which is why it is a decoration and not a colour alias

Borders and shadows are decoration, not ColorScheme foregrounds.

Ownership split: the THEME owns the treatment values (card-whisper-shadow,
hairline-edge, overlay-shadow …). The COMPONENT contract owns which treatment
it uses per theme and state — e.g. Card: card-whisper-shadow in Light,
hairline-edge in Dark. ThemeData does not decide a component's behaviour.

## Global state tokens — STATE_TOKEN

GENERATED VIEW from themeRegistry where kind == STATE_TOKEN. Interaction states
only: disabled, pressed, hover. Not colours, and not a home for glass
translucency.

  op-disabled
    kind: STATE_TOKEN · DIRECTLY_CONSUMED · BIND_NOW
    value: 0.38 (both themes)
    global state policy, value 0.38 — applied once, never a colour
  op-press
    kind: STATE_TOKEN · DIRECTLY_CONSUMED · BIND_NOW
    value: 0.12 (both themes)
    global state policy, value 0.12 — applied once, never a colour
  op-hover
    kind: STATE_TOKEN · FOUNDATION_DEFINED_UNUSED · PRESERVE_ONLY
    value: 0.08 (both themes)
    global state policy, value 0.08 — applied once, never a colour

## Effect tokens — EFFECT_TOKEN

GENERATED VIEW from themeRegistry where kind == EFFECT_TOKEN. A non-state
visual effect configuration. op-glass lives here, not in the state layer: it is
translucency, not interaction. chrome-glass (a DERIVED_COLOR) references it for
its alpha, so the value 0.84 is authored in exactly one place. A colour
role never owns blur behaviour.

chrome-glass is the surface colour with alpha from op-glass, composited over
the RUNTIME BACKDROP — do not pre-composite it against a fixed page ground and
ship the flattened result. The web source value saturate(180%) blur(18px)
is a NON-BINDING SOURCE TRACE, not a Flutter API requirement: reproduce the
glass INTENT with the repository's or platform's own blur mechanism, and keep
the existing solid / translucent fallback wherever the platform or a
performance budget disallows a live blur.

  op-glass
    kind: EFFECT_TOKEN · INDIRECTLY_CONSUMED · BIND_NOW
    value: 0.84 (both themes)
    glass-opacity, value 0.84 (both themes) — an effect configuration, not an interaction state and not a colour
  glass-blur
    kind: EFFECT_TOKEN · DIRECTLY_CONSUMED · BIND_NOW
    value: saturate(180%) blur(18px) (both themes)
    glass-blur, value saturate(180%) blur(18px) (both themes) — an effect configuration, not an interaction state and not a colour

## Non-theme dependencies — NONE and COMPONENT_INPUT

GENERATED VIEW from themeRegistry where kind == NONE or COMPONENT_INPUT.
Neither becomes a theme field.

  accent
    kind: COMPONENT_INPUT · INDIRECTLY_CONSUMED
    value: n/a — not a theme value
    a per-instance prop, not a theme colour: StudyTopBar defaults to the primary role and the Recall / Fill sessions pass the mastery role. Resolve it to whichever existing role the caller passes — do NOT add an accent theme property.
  seed
    kind: COMPONENT_INPUT · INDIRECTLY_CONSUMED
    value: n/a — not a theme value
    a per-deck colour passed into IconTile at 12% for the tile and full strength for the glyph; ListRow accepts the same prop and FORWARDS it to the IconTile it composes, painting nothing with it itself. Instance input, not a global role — do NOT put seed in the theme.
  transparent
    kind: NONE · DIRECTLY_CONSUMED
    value: n/a — not a theme value
    no painted fill — do not create a theme property for it

## Foundation semantic role disposition — complete

GENERATED VIEW: every non-M3 entry in themeRegistry, consumed or not, with its
COMPUTED usage status. A role with no active consumer path is
FOUNDATION_DEFINED_UNUSED: preserve it, do not delete it, and do not invent a
usage so the table looks busier. Deriving an UNUSED colour from a role does not
make that role consumed.

  mastery
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · EmptyState.tone success.tile + glyph · TINT 10%
    runtime: BIND_NOW
    value: #1F8A5B / #6FE0BD
    the repository semantic-colour mechanism (theme extension or equivalent)
  success
    kind: MEMOX_SEMANTIC_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    derives: success-soft
    runtime: PRESERVE_ONLY
    value: #2BA88B / #6FE0BD
    the repository semantic-colour mechanism (theme extension or equivalent)
  warning
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · FieldMessage.warning.glyph, InlineBanner.warning.border · TINT 26% light / 32% dark, InlineBanner.warning.glyph, EmptyState.tone warning.tile + glyph · TINT 10%
    derives: warning-soft
    runtime: BIND_NOW
    value: #F59E0B / #FFC658
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-warning
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · FieldMessage.warning.text, WorkloadBreakdownLine.overdue term
    runtime: BIND_NOW
    value: #3A2A00 / #2A1E00
    the repository semantic-colour mechanism (theme extension or equivalent)
  streak
    kind: MEMOX_SEMANTIC_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #F97316 / #FFAE6E
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-streak
    kind: MEMOX_SEMANTIC_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #FFFFFF (both themes)
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-new
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · StatusBadge.new.dot, StatusBadge.new.label, StatusBadge.new.container · TINT 12%, WorkloadBreakdownLine.new term
    runtime: BIND_NOW
    value: #8C95B8 / #6B75A3
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-learning
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · StatusBadge.learning.dot + label, StatusBadge.learning.container · TINT 12%, MasteryRamp.< 34%.fill, MasteryDonut.< 34%.arc + label
    runtime: BIND_NOW
    value: #F59E0B / #FFC658
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-reviewing
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · StatusBadge.reviewing.dot + label, StatusBadge.reviewing.container · TINT 12%, MasteryRamp.34–66%.fill, MasteryDonut.34–66%.arc + label
    runtime: BIND_NOW
    value: #5265F5 / #8B9AFF
    the repository semantic-colour mechanism (theme extension or equivalent)
  status-mastered
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · StatusBadge.mastered.dot + label, StatusBadge.mastered.container · TINT 12%, MasteryRamp.≥ 67%.fill, MasteryDonut.≥ 67%.arc + label
    runtime: BIND_NOW
    value: #1F8A5B / #6FE0BD
    the repository semantic-colour mechanism (theme extension or equivalent)
  error-fill
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · Button.destructive tone.container
    runtime: BIND_NOW
    value: #DC2D4E / #B0485C
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-error-fill
    kind: MEMOX_SEMANTIC_COLOR
    usage: DIRECTLY_CONSUMED · Button.destructive tone.label + glyph
    runtime: BIND_NOW
    value: #FFFFFF (both themes)
    the repository semantic-colour mechanism (theme extension or equivalent)
  mastery-fixed
    kind: MEMOX_SEMANTIC_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #C7F2D8 / #1F4A37
    the repository semantic-colour mechanism (theme extension or equivalent)
  on-danger
    kind: MEMOX_SEMANTIC_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #FFFFFF / #2A0A12
    the repository semantic-colour mechanism (theme extension or equivalent)
  text-muted
    kind: MEMOX_SEMANTIC_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #7C85AB / #5A6BAE
    the repository semantic-colour mechanism (theme extension or equivalent)
  bg
    kind: M3_ALIAS
    usage: DIRECTLY_CONSUMED · AppShell.page ground
    runtime: BIND_NOW
    value: #F7F9FE / #0A0E27
    resolves to surface — the page ground IS the surface role; the kit renames it for readability only. No second theme property.
  surface-muted
    kind: M3_ALIAS
    usage: DIRECTLY_CONSUMED · TextField.resting.container, Note.container
    runtime: BIND_NOW
    value: #F1F4FB / #1B2249
    resolves to surfaceContainerLow — the input / Note resting fill is that step of the same surface ladder. No second theme property.
  surface-raised
    kind: M3_ALIAS
    usage: DIRECTLY_CONSUMED · Card.container, Section.row container, EmptyState.container, ErrorState.container
    runtime: BIND_NOW
    value: #FFFFFF / #131A3A
    resolves to surfaceContainerLowest — the card fill is that surface step in BOTH themes (#FFFFFF light / #131A3A dark) — no separate property, no brightness branch. No second theme property.
  progress-track
    kind: M3_ALIAS
    usage: DIRECTLY_CONSUMED · StudyTopBar.progress track, MasteryRamp.track
    runtime: BIND_NOW
    value: #E2E7F3 / #2C356E
    resolves to surfaceContainerHigh — an unfilled track is a surface step, authored as that role. No second theme property.
  badge-bg
    kind: M3_ALIAS
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #E9EDF7 / #232B5A
    resolves to surfaceContainer — a surface-ladder step authored as surfaceContainer. It is NOT the current badge fill: the tonal Badge tints its own tone at 12% and nothing in v3 reads this token. The alias evidence is the surface step, not a badge treatment.. No second theme property.
  danger
    kind: M3_ALIAS
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #DC2D4E / #FF8FA3
    resolves to error — destructive FOREGROUND semantics — the same role as error, renamed for product vocabulary. No second theme property.
  text-primary
    kind: M3_ALIAS
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: #0F1638 / #E4E8FA
    resolves to onSurface — primary ink IS onSurface. No second theme property.
  text-secondary
    kind: M3_ALIAS
    usage: DIRECTLY_CONSUMED · ChipTrigger.label, Section.overline
    runtime: BIND_NOW
    value: #4A5278 / #A4ACD0
    resolves to onSurfaceVariant — secondary ink IS onSurfaceVariant. No second theme property.
  primary-soft
    kind: DERIVED_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: color-mix(in srgb, #5265F5 10%, transparent) / color-mix(in srgb, #8B9AFF 20%, transparent)
    primary @ 10% light / 20% dark over transparent
  primary-border
    kind: DERIVED_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: color-mix(in srgb, #5265F5 24%, transparent) / color-mix(in srgb, #8B9AFF 32%, transparent)
    primary @ 24% light / 32% dark over transparent
  danger-soft
    kind: DERIVED_COLOR
    usage: DIRECTLY_CONSUMED · ActionSheetCommandRow.danger.tile fill, InlineBanner.danger.fill, ErrorState.tile
    runtime: BIND_NOW
    value: color-mix(in srgb, #DC2D4E 8%, transparent) / color-mix(in srgb, #FF8FA3 16%, transparent)
    error @ 8% light / 16% dark over transparent
  danger-border
    kind: DERIVED_COLOR
    usage: DIRECTLY_CONSUMED · InlineBanner.danger.border
    runtime: BIND_NOW
    value: color-mix(in srgb, #DC2D4E 22%, transparent) / color-mix(in srgb, #FF8FA3 32%, transparent)
    error @ 22% light / 32% dark over transparent
  success-soft
    kind: DERIVED_COLOR
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: color-mix(in srgb, #2BA88B 10%, transparent) / color-mix(in srgb, #6FE0BD 18%, transparent)
    success @ 10% light / 18% dark over transparent
  warning-soft
    kind: DERIVED_COLOR
    usage: DIRECTLY_CONSUMED · InlineBanner.warning.fill
    runtime: BIND_NOW
    value: color-mix(in srgb, #F59E0B 12%, transparent) / color-mix(in srgb, #FFC658 18%, transparent)
    warning @ 12% light / 18% dark over transparent
  surface-hero
    kind: DERIVED_COLOR
    usage: DIRECTLY_CONSUMED · Card.tinted hero variant
    runtime: BIND_NOW
    value: color-mix(in srgb, #5265F5 5%, #FFFFFF) / color-mix(in srgb, #8B9AFF 12%, #0A0E27)
    primary @ 5% light / 12% dark over surfaceBright in LIGHT, surface in DARK — the bases differ by theme
  chrome-glass
    kind: DERIVED_COLOR
    usage: DIRECTLY_CONSUMED · BottomNav.bar surface
    runtime: BIND_NOW
    value: rgba(247, 249, 254, 0.84) / rgba(10, 14, 39, 0.84)
    surface @ alpha from op-glass over the runtime backdrop — composite at paint time, never pre-flattened against a fixed page colour · alpha owned by op-glass
  shadow-soft
    kind: DECORATION
    usage: DIRECTLY_CONSUMED · Toggle.thumb elevation, SegmentedTray.active.thumb shadow · UNPARSED, Card.light edge
    runtime: BIND_NOW
    value: 0 1px 2px rgba(15,22,56,0.04) / none
    card-whisper-shadow — Card, Toggle thumb — none in Dark, which draws the hairline instead
  shadow-card
    kind: DECORATION
    usage: DIRECTLY_CONSUMED · Dialog.elevation
    runtime: BIND_NOW
    value: 0 12px 32px rgba(15,22,56,0.10) / 0 16px 40px rgba(0,0,0,0.42)
    overlay-shadow — Dialog — NOT the Card, despite the token name
  shadow-chrome
    kind: DECORATION
    usage: DIRECTLY_CONSUMED · BottomSheet.elevation
    runtime: BIND_NOW
    value: 0 -2px 12px rgba(15,22,56,0.05) / 0 -2px 14px rgba(0,0,0,0.36)
    chrome-shadow — BottomSheet and bottom chrome
  shadow-fab
    kind: DECORATION
    usage: DIRECTLY_CONSUMED · Fab.elevation
    runtime: BIND_NOW
    value: 0 8px 24px rgba(15,22,56,0.12) / 0 10px 28px rgba(0,0,0,0.5)
    fab-shadow — the floating action
  shadow-none
    kind: DECORATION
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: none (both themes)
    no-shadow — explicit absence
  border-ghost
    kind: DECORATION
    usage: DIRECTLY_CONSUMED · BottomNav.bar edge, Button.chip variant.border, FilterChip.unselected.border, SearchField.resting.border, TextField.resting.border, OptionRow.divider, Card.dark edge, Section.row dividers, ListRow.divider, Note.border, SheetActions.sheet.top divider, FooterBar.top divider
    runtime: BIND_NOW
    value: 1px solid rgba(82, 101, 245, 0.14) / 1px solid rgba(139, 154, 255, 0.16)
    hairline-edge — the 1px primary-tinted edge on cards, chips, dividers and chrome
  border-strong
    kind: DECORATION
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: 1px solid #C5CBE3 / 1px solid #2A3267
    strong-edge — the 1px outlineVariant edge — a border SHORTHAND (width + style + role), which is why it is a decoration and not a colour alias
  op-disabled
    kind: STATE_TOKEN
    usage: DIRECTLY_CONSUMED · Button.disabled.whole control · APPLY_TOKEN (the token's own value), IconButton.disabled.whole control · APPLY_TOKEN (the token's own value), FilterChip.disabled.whole control · APPLY_TOKEN (the token's own value), TextField.disabled.whole field · APPLY_TOKEN (the token's own value), Toggle.disabled.whole control · APPLY_TOKEN (the token's own value), OptionRow.disabled.whole row · APPLY_TOKEN (the token's own value), ListRow.disabled.whole row · APPLY_TOKEN (the token's own value), SettingsRow.dimmed.whole row · APPLY_TOKEN (the token's own value)
    runtime: BIND_NOW
    value: 0.38 (both themes)
    global state policy, value 0.38 — applied once, never a colour
  op-press
    kind: STATE_TOKEN
    usage: DIRECTLY_CONSUMED · Button.pressed.state overlay · APPLY_TOKEN (the token's own value), IconButton.pressed.state overlay · APPLY_TOKEN (the token's own value), FilterChip.pressed.state overlay · APPLY_TOKEN (the token's own value), OptionRow.pressed.state overlay · APPLY_TOKEN (the token's own value), ListRow.pressed.state overlay · APPLY_TOKEN (the token's own value)
    runtime: BIND_NOW
    value: 0.12 (both themes)
    global state policy, value 0.12 — applied once, never a colour
  op-hover
    kind: STATE_TOKEN
    usage: FOUNDATION_DEFINED_UNUSED
    runtime: PRESERVE_ONLY
    value: 0.08 (both themes)
    global state policy, value 0.08 — applied once, never a colour
  op-glass
    kind: EFFECT_TOKEN
    usage: INDIRECTLY_CONSUMED · derives chrome-glass (ACTIVE)
    derives: chrome-glass
    runtime: BIND_NOW
    value: 0.84 (both themes)
    glass-opacity, value 0.84 (both themes) — an effect configuration, not an interaction state and not a colour
  glass-blur
    kind: EFFECT_TOKEN
    usage: DIRECTLY_CONSUMED · BottomNav.bar blur · EFFECT (blur)
    runtime: BIND_NOW
    value: saturate(180%) blur(18px) (both themes)
    glass-blur, value saturate(180%) blur(18px) (both themes) — an effect configuration, not an interaction state and not a colour
  accent
    kind: COMPONENT_INPUT
    usage: INDIRECTLY_CONSUMED · StudyTopBar.progress fill (COMPONENT_INPUT), StudyTopBar.mode badge label (COMPONENT_INPUT), StudyTopBar.mode badge fill (COMPONENT_INPUT)
    runtime: not a theme field
    value: n/a — not a theme value
    a per-instance prop, not a theme colour: StudyTopBar defaults to the primary role and the Recall / Fill sessions pass the mastery role. Resolve it to whichever existing role the caller passes — do NOT add an accent theme property.
  seed
    kind: COMPONENT_INPUT
    usage: INDIRECTLY_CONSUMED · ListRow.leading tile seed (COMPONENT_INPUT), IconTile.seeded.tile (COMPONENT_INPUT), IconTile.seeded.glyph (COMPONENT_INPUT)
    runtime: not a theme field
    value: n/a — not a theme value
    a per-deck colour passed into IconTile at 12% for the tile and full strength for the glyph; ListRow accepts the same prop and FORWARDS it to the IconTile it composes, painting nothing with it itself. Instance input, not a global role — do NOT put seed in the theme.
  transparent
    kind: NONE
    usage: DIRECTLY_CONSUMED · Button.outline tone.container · NO_FILL, IconButton.ink box · NO_FILL, ChipTrigger.container · NO_FILL
    runtime: not a theme field
    value: n/a — not a theme value
    no painted fill — do not create a theme property for it

## Light / dark theme requirements

Both themes are complete and first-class: Tokyo Pure Light and Tokyo Nebula.
Dark is not a filter over light — the values are authored.

Among V3-authored standard M3 colour roles, inverseSurface and onInverseSurface
are intentionally invariant:

  inverse-surface       #34395D
  on-inverse-surface    #E8EAFC

That claim is scoped and asserted, not inferred: the registry stamps
invariant:true on exactly these roles and the validator fails if either value
differs between themes. It says nothing about the rest of the registry. Other
tokens may happen to carry the same value in both themes without being
invariant, and a token whose NAME says fixed may still flip — mastery-fixed is
#C7F2D8 light / #1F4A37 dark. Never read invariance off equal values or off a
token name; read it off the invariant flag.

## Typography / TextTheme binding

The SAME seven roles the Foundations spec states — one scale, rendered from one
source, so the two steps cannot disagree:

  role            size  weight  line-height  tracking   usage
  caption         12    600     1.4          1.2px      overlines, metadata, chips, counts — hard 12px floor
  body            14    400     1.5          0          default running text
  body large      16    500     1.5          0          list titles, emphasised body
  title           20    700     1.2          -0.64px    section and screen titles
  headline        24    700     1.2          -0.64px    screen headline
  display         32    800     1.1          -0.64px    hero figure
  stat            40    600     1.0          -0.64px    large metric, tabular numerals

Establish this once as the shared typography source. Button, Card, ListRow,
SettingsRow and every other shared widget consume it; none of them creates its
own text styles.

A component contract may state a type treatment of its own (the app-bar content
title at 20/700/-0.3px, the button label at 14/600/0.1px). Those are COMPONENT
rows, not additions to this scale: implement them as a component-level override
of the nearest role above, never as a new global text style.

## Global state semantics

The GLOBAL layer owns exactly three things:

  disabled          opacity 0.38 over the whole control — ONE value everywhere
  pressed           platform state overlay at op-press (0.12)
  focused           2px primary ring, offset 2 — one treatment for every control

  hover             web only; Android has no hover state — do not implement

Everything else is COMPONENT-owned, because it is not uniform across the kit:

  selected / checked / active    each component states its own role mapping
                                 (FilterChip swaps fill → primary and label →
                                 onPrimary; OptionRow thickens a ring; BottomNav
                                 tints a pill). Do not generalise one of them
                                 into a global rule.
  error presentation             the theme owns the error COLOUR semantics; the
                                 component owns whether there is a border, a
                                 message, where it sits and which slots change.
                                 The border-plus-message-line treatment belongs
                                 to TextField / SearchField, not to every control.

A component spec REFERENCES the three global rules; it never redefines them.

## Theme implementation sequence

   1. Inspect the repository's existing theme architecture.
   2. Enumerate the complete canonical M3 ColorScheme role set.
   3. Reconcile dispositions: V3_DEFINED vs REPO_PRESERVED (table above).
   4. Build / reconcile the Light ColorScheme.
   5. Build / reconcile the Dark ColorScheme.
   6. Verify the full canonical role set is still present.
   7. Bind the EXACT Foundations typography to the repository's TextTheme.
   8. Route each BIND_NOW entry BY KIND — only BIND_NOW MEMOX_SEMANTIC_COLOR
      entries use the MemoX semantic-colour mechanism; an alias resolves to its
      ColorScheme target, and no field is added for a PRESERVE_ONLY entry.
   9. Bind DERIVED_COLOR values centrally, each derivation exactly once.
  10. Bind DECORATION treatments centrally where the token architecture allows.
  11. Establish the global STATE_TOKEN policies: disabled, pressed, focus — and
      keep EFFECT_TOKEN values out of them.
  12. Configure Material component-theme defaults only where they represent
      the V3 baseline accurately.
  13. Validate the common theme on its own — including Foundation semantic-role
      coverage, every IMPLEMENT_COMPONENT theme usage, and aggregate
      role-consumer consistency.
  14. Freeze this prerequisite.
  15. Only then start the IMPLEMENT_COMPONENT tasks.

## Ownership matrix

  AREA                          OWNER
  standard Material colours     ColorScheme
  MemoX semantic colours        one semantic theme mechanism
  derived colours               central derivation in the theme layer
  typography                    TextTheme / canonical typography
  global interaction states     common state-token policy
  visual effect configuration   the effect/decoration token layer
  spacing / radius / sizing     the design-token system
  decoration, shadow, borders   the canonical decoration/token mechanism
  Material global defaults      ThemeData component themes, where appropriate
  shared-widget variants        the shared component
  screen composition            the screen

Which repository classes carry each row is Claude Code's decision after
inspection.

## Material component-theme policy

Inspect these categories and decide, per category, whether a central Material
component theme represents the V3 default honestly: buttons · text/input
fields · dialogs · navigation · chips · switch/toggle · snackbar · bottom sheet
· progress indicators.

  If a Material component theme can carry the V3 global default without
  fighting the MemoX variants → configure it centrally.
  If the MemoX contract is richer than the Material theme can express cleanly
  → keep the variation in the shared component, which still consumes
  ColorScheme, TextTheme and the global tokens.

Do not force everything into ThemeData; do not leave everything local.

## Shared-component consumption rules

Shared components declare slot/state → role usage and consume the theme. They
must not: hard-code a V3 hex; copy a standard role into a custom layer;
redefine a MemoX semantic role locally; re-resolve a role this step already
resolved; or reach into another shared component's theme roles.

## Theme gaps and UNSPECIFIED handling

A role a component needs that this step did not establish is a DEPENDENCY GAP:
report it upstream. It is not UNSPECIFIED, and it is never a licence for a
widget to patch in a colour. UNSPECIFIED stays what the frozen template says:
the design does not determine the value — keep the repository convention where
that is safe, ask where geometry, state, interaction, content loss or
accessibility depends on it.

## Validation — verify after implementing

  light ColorScheme complete · dark ColorScheme complete · the repository's
  existing canonical M3 role set still intact · every V3-defined standard role
  resolving through ColorScheme · every BIND_NOW entry routed by its KIND, with
  only MEMOX_SEMANTIC_COLOR entries in the MemoX semantic mechanism · no new
  field for a PRESERVE_ONLY semantic · TextTheme shared ·
  disabled/pressed/focus shared · glass opacity and blur outside the state
  layer · no raw colour duplicated in a shared widget · no widget running a
  private theme system · Material defaults centralized where appropriate ·
  custom variants still reading the common theme

Report every mismatch instead of inventing a value.

## Role consumers — DIRECT theme readers only

GENERATED VIEW from widgets[*].themeRoleUsage where access == DIRECT.
Deduplicated on component + slot + state + access. A parent that composes
another shared component is NOT listed here — the child owns that read. Each
entry carries the treatment its consumer applies, so a role reference never
implies full-strength paint.

RENDERING RULE: no treatment suffix means FULL_STRENGTH. The underlying
themeRoleUsage record still stores the treatment explicitly — the suffix is
omitted here only to keep the list readable, and every transformed treatment
(TINT, OPACITY, MIX, BORDER, NO_FILL, APPLY_TOKEN, EFFECT) is always shown.

  bg
    kind: M3_ALIAS
    consumers: AppShell.page ground
  border-ghost
    kind: DECORATION
    consumers: BottomNav.bar edge, Button.chip variant.border, FilterChip.unselected.border, SearchField.resting.border, TextField.resting.border, OptionRow.divider, Card.dark edge, Section.row dividers, ListRow.divider, Note.border, SheetActions.sheet.top divider, FooterBar.top divider
  chrome-glass
    kind: DERIVED_COLOR
    consumers: BottomNav.bar surface
  danger-border
    kind: DERIVED_COLOR
    consumers: InlineBanner.danger.border
  danger-soft
    kind: DERIVED_COLOR
    consumers: ActionSheetCommandRow.danger.tile fill, InlineBanner.danger.fill, ErrorState.tile
  error
    kind: M3_COLOR
    consumers: TextField.error.border, Stepper.invalid.value, FieldMessage.error.glyph + text, ActionSheetCommandRow.danger.tile glyph, ActionSheetCommandRow.danger.label, InlineBanner.danger.glyph, EmptyState.tone danger.tile + glyph · TINT 10%, ErrorState.tile glyph
  error-fill
    kind: MEMOX_SEMANTIC_COLOR
    consumers: Button.destructive tone.container
  glass-blur
    kind: EFFECT_TOKEN
    consumers: BottomNav.bar blur · EFFECT (blur)
  inversePrimary
    kind: M3_COLOR
    consumers: Snackbar.action label
  inverseSurface
    kind: M3_COLOR
    consumers: Snackbar.container
  mastery
    kind: MEMOX_SEMANTIC_COLOR
    consumers: EmptyState.tone success.tile + glyph · TINT 10%
  on-error-fill
    kind: MEMOX_SEMANTIC_COLOR
    consumers: Button.destructive tone.label + glyph
  on-warning
    kind: MEMOX_SEMANTIC_COLOR
    consumers: FieldMessage.warning.text, WorkloadBreakdownLine.overdue term
  onInverseSurface
    kind: M3_COLOR
    consumers: Snackbar.message
  onPrimary
    kind: M3_COLOR
    consumers: Fab.glyph, Button.primary tone.label + glyph, Button.loading.spinner, FilterChip.selected.label + count · OPACITY 0.75, SelectionCheckbox.checked.check glyph, Badge.solid.label, Spinner.inside a filled button.ring
  onSurface
    kind: M3_COLOR
    consumers: AppBar.title, AppBar.leading + trailing glyphs, Breadcrumb.current segment, StudyTopBar.close glyph, Button.secondary tone.label + glyph, IconButton.glyph, FilterChip.unselected.label, FilterChip.unselected.count · OPACITY 0.6, SearchField.filled.value text, SearchField.filled.clear button glyph, TextField.filled.value text, OptionRow.title, SegmentedTray.active.label, Stepper.button glyph, Stepper.value, Card.content, ListRow.title, SettingsRow.label, ActionSheetCommandRow.default.label, Dialog.content, BottomSheet.content, InlineBanner.title + body lead, DeckPickerSheet.title, EmptyState.title, ErrorState.title, AppShell.default text
  onSurfaceVariant
    kind: M3_COLOR
    consumers: BottomNav.inactive.glyph + label, Breadcrumb.ancestor segment, StudyTopBar.counter, ChipTrigger.trailing chevron, SearchField.empty.placeholder, SearchField.resting.leading glyph, TextField.empty.placeholder, OptionRow.description, SegmentedTray.inactive.label, ListRow.sub / metadata, ListRow.trailing chevron / overflow glyph, SettingsRow.sub, SettingsRow.chevron, ActionSheetCommandRow.sub, ActionSheetCommandRow.chevron, ListSectionHeader.label, TagChip.label, Note.text + glyph, WorkloadBreakdownLine.separators + fallback line, InlineBanner.body detail, DeckPickerSheet.rule line, EmptyState.tone neutral.tile + glyph · TINT 10%, EmptyState.body, ErrorState.body, FooterBar.hint line
  op-disabled
    kind: STATE_TOKEN
    consumers: Button.disabled.whole control · APPLY_TOKEN (the token's own value), IconButton.disabled.whole control · APPLY_TOKEN (the token's own value), FilterChip.disabled.whole control · APPLY_TOKEN (the token's own value), TextField.disabled.whole field · APPLY_TOKEN (the token's own value), Toggle.disabled.whole control · APPLY_TOKEN (the token's own value), OptionRow.disabled.whole row · APPLY_TOKEN (the token's own value), ListRow.disabled.whole row · APPLY_TOKEN (the token's own value), SettingsRow.dimmed.whole row · APPLY_TOKEN (the token's own value)
  op-press
    kind: STATE_TOKEN
    consumers: Button.pressed.state overlay · APPLY_TOKEN (the token's own value), IconButton.pressed.state overlay · APPLY_TOKEN (the token's own value), FilterChip.pressed.state overlay · APPLY_TOKEN (the token's own value), OptionRow.pressed.state overlay · APPLY_TOKEN (the token's own value), ListRow.pressed.state overlay · APPLY_TOKEN (the token's own value)
  outline
    kind: M3_COLOR
    consumers: Breadcrumb.chevron separator, OptionRow.unselected.radio ring, SelectionCheckbox.unchecked.box border
  outlineVariant
    kind: M3_COLOR
    consumers: Button.outline tone.border · BORDER, BottomSheet.grabber
  primary
    kind: M3_COLOR
    consumers: AppBar.focused.focus ring · BORDER, BottomNav.active.glyph + label, BottomNav.active.active indicator pill · TINT 14% light / 20% dark, BottomNav.focused.focus ring · BORDER, Fab.container, Fab.focused.focus ring · BORDER, Button.primary tone.container, Button.outline tone.label + glyph, Button.focused.focus ring · BORDER, IconButton.focused.focus ring · BORDER, FilterChip.selected.container, FilterChip.focused.focus ring · BORDER, ChipTrigger.focused.focus ring · BORDER, SearchField.focused.border, SearchField.focused.leading glyph, SearchField.focused.caret, TextField.focused.border, Toggle.on.track, Toggle.focused.focus ring · BORDER, OptionRow.selected.radio ring, SelectionCheckbox.checked.box fill, SelectionCheckbox.focused.focus ring · BORDER, SegmentedTray.focused.focus ring · BORDER, Stepper.busy.spinner, SettingsRow.focused.focus ring · BORDER, IconTile.default.tile · TINT 10% light / 16% dark, IconTile.default.glyph, ActionSheetCommandRow.default.tile fill · TINT 8%, ActionSheetCommandRow.default.tile glyph, ActionSheetCommandRow.focused.focus ring · BORDER, Badge.tonal.container · TINT 12%, Badge.tonal.label, Badge.solid.container, WorkloadBreakdownLine.today term, Spinner.on a surface.ring, EmptyState.tone primary.tile + glyph · TINT 10%
  progress-track
    kind: M3_ALIAS
    consumers: StudyTopBar.progress track, MasteryRamp.track
  scrim
    kind: M3_COLOR
    consumers: Scrim.visible.barrier · OPACITY 0.45, Dialog.barrier · OPACITY 0.45, BottomSheet.barrier · OPACITY 0.45
  shadow-card
    kind: DECORATION
    consumers: Dialog.elevation
  shadow-chrome
    kind: DECORATION
    consumers: BottomSheet.elevation
  shadow-fab
    kind: DECORATION
    consumers: Fab.elevation
  shadow-soft
    kind: DECORATION
    consumers: Toggle.thumb elevation, SegmentedTray.active.thumb shadow · UNPARSED, Card.light edge
  status-learning
    kind: MEMOX_SEMANTIC_COLOR
    consumers: StatusBadge.learning.dot + label, StatusBadge.learning.container · TINT 12%, MasteryRamp.< 34%.fill, MasteryDonut.< 34%.arc + label
  status-mastered
    kind: MEMOX_SEMANTIC_COLOR
    consumers: StatusBadge.mastered.dot + label, StatusBadge.mastered.container · TINT 12%, MasteryRamp.≥ 67%.fill, MasteryDonut.≥ 67%.arc + label
  status-new
    kind: MEMOX_SEMANTIC_COLOR
    consumers: StatusBadge.new.dot, StatusBadge.new.label, StatusBadge.new.container · TINT 12%, WorkloadBreakdownLine.new term
  status-reviewing
    kind: MEMOX_SEMANTIC_COLOR
    consumers: StatusBadge.reviewing.dot + label, StatusBadge.reviewing.container · TINT 12%, MasteryRamp.34–66%.fill, MasteryDonut.34–66%.arc + label
  surface
    kind: M3_COLOR
    consumers: AppBar.bar background, StudyTopBar.bar background, FooterBar.bar fill
  surface-hero
    kind: DERIVED_COLOR
    consumers: Card.tinted hero variant
  surface-muted
    kind: M3_ALIAS
    consumers: TextField.resting.container, Note.container
  surface-raised
    kind: M3_ALIAS
    consumers: Card.container, Section.row container, EmptyState.container, ErrorState.container
  surfaceBright
    kind: M3_COLOR
    consumers: Toggle.thumb
  surfaceContainer
    kind: M3_COLOR
    consumers: Button.secondary tone.container, SearchField.resting.container, SegmentedTray.tray fill, Stepper.button fill, TagChip.container, MasteryDonut.track
  surfaceContainerHigh
    kind: M3_COLOR
    consumers: Dialog.container, BottomSheet.container, Skeleton.placeholder block
  surfaceContainerHighest
    kind: M3_COLOR
    consumers: Toggle.off.track
  surfaceContainerLowest
    kind: M3_COLOR
    consumers: Button.chip variant.container, FilterChip.unselected.container, SearchField.focused.container, TextField.focused.container, SegmentedTray.active.thumb fill
  text-secondary
    kind: M3_ALIAS
    consumers: ChipTrigger.label, Section.overline
  transparent
    kind: NONE
    consumers: Button.outline tone.container · NO_FILL, IconButton.ink box · NO_FILL, ChipTrigger.container · NO_FILL
  warning
    kind: MEMOX_SEMANTIC_COLOR
    consumers: FieldMessage.warning.glyph, InlineBanner.warning.border · TINT 26% light / 32% dark, InlineBanner.warning.glyph, EmptyState.tone warning.tile + glyph · TINT 10%
  warning-soft
    kind: DERIVED_COLOR
    consumers: InlineBanner.warning.fill

## Component composition usage — VIA_COMPONENT

GENERATED VIEW from widgets[*].themeRoleUsage where access == VIA_COMPONENT.

These parents paint nothing. They ask another shared component for a semantic
configuration — a tone, an enabled state — and the CHILD owns every colour role
behind it. No child theme role appears in a parent's record, and none is
translated back into one here. If you are implementing a parent, you need the
child's semantic API, not its palette.

  DeckPickerSheet
    sheet → BottomSheet (default configuration)
    candidate rows → ListRow (tileSize=sm · trailing=chevron · disabled=when the target cannot accept the payload)
    empty → EmptyState (tone=neutral · compact=true)
    footer → SheetActions (divider=true)
  EmptyState
    action → Button (tone=primary)
  ErrorState
    action → Button (tone=primary)
  FooterBar
    CTA → Button (tone=primary · width=block)
  InlineBanner
    actions → Button (size=compact)
  ListRow
    leading tile + glyph → IconTile (size=sm (tileSize) · variant=default, or seeded when the caller passes a seed)
  ListSectionHeader
    trailing → ChipTrigger · Badge · Button (default configuration)
  SettingsRow
    leading tile + glyph → IconTile (size=md · variant=default)
  SheetActions
    cancel button → Button (tone=outline)
    confirm button → Button (tone=primary)
    destructive.confirm button → Button (tone=destructive)
    disabled.confirm button → Button (enabled=false)
  TextField
    message row → FieldMessage (tone=error)

## Component input usage — COMPONENT_INPUT

GENERATED VIEW from widgets[*].themeRoleUsage where access == COMPONENT_INPUT.

A per-instance semantic the caller supplies. Never a theme field, and never
mixed into the DIRECT consumer index above.

  accent
    kind: COMPONENT_INPUT
    consumers: StudyTopBar.progress fill · FULL_STRENGTH, StudyTopBar.mode badge label · FULL_STRENGTH, StudyTopBar.mode badge fill · TINT 10%
    carries in v3: primary, mastery
  seed
    kind: COMPONENT_INPUT
    consumers: ListRow.leading tile seed · FORWARD_UNCHANGED (the child owns the treatment), IconTile.seeded.tile · TINT 12%, IconTile.seeded.glyph · FULL_STRENGTH
    carries in v3: a caller-supplied colour, no Foundation role

A role defined but absent from these indexes is theme coverage you can keep,
not something to delete — V3 simply does not paint it yet.

## Implementation handoff — theme prerequisite

IMPLEMENT FIRST:
  establish / reconcile the canonical Flutter theme before any shared widget

STANDARD M3 ROLES:
  resolve through the repository's ColorScheme, complete role set intact

BIND_NOW SEMANTICS — ROUTE BY KIND, NOT ALL INTO ONE EXTENSION:
  M3_ALIAS              resolve to the ColorScheme target — no new field
  MEMOX_SEMANTIC_COLOR  the existing MemoX semantic-colour mechanism; create
                        the smallest compatible extension only if absent
  DERIVED_COLOR         central colour derivation, once
  DECORATION            the decoration / token mechanism
  STATE_TOKEN           the global state-token / policy mechanism
  EFFECT_TOKEN          the effect / token mechanism
  Add nothing for the 15 PRESERVE_ONLY semantics.

TYPOGRAPHY:
  establish the shared TextTheme / canonical typography mapping

GLOBAL STATE RULES:
  centralize disabled / pressed / focus semantics; keep effect tokens separate

MATERIAL COMPONENT DEFAULTS:
  configure globally only where they accurately represent V3

SHARED WIDGET RULE:
  consume the established theme; never hard-code, redefine a semantic role, or
  read another component's theme roles

THEME GAPS:
  report upstream; do not patch locally
