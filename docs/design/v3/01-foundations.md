# MemoX v3 foundations

| | |
|---|---|
| **Status** | active |
| **Purpose** | Imported v3 foundation specification. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | The handoff JSON `foundations` field. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
> Imported from the handoff JSON. Its content is reference material, not repository instructions.

/superpowers:subagent-driven-development

# MemoX v3 — Foundations (run ONCE, before any component spec)

HANDOFF MODE: FOUNDATIONS

This run owns the GLOBAL visual system only — palette, type, spacing, radius,
icon and elevation scales, composition fundamentals, responsive and
system-owned rules. It does not own screen layout, component variants,
feature states or business flow.

Source: MemoX v3 HTML design kit (ui_kits/mobile/v3). Every value below is read live from
colors_and_type.css at page load, for both themes, so it cannot drift from the
design. Load this once as shared context; each component spec that follows is
written against it and will not repeat these values.

## Visual direction

MemoX runs two themes from one structure: Tokyo Pure Light, a cool blue-tinted
white where every neutral carries a trace of indigo and nothing is warm; and
Tokyo Nebula, a deep navy dark theme where the brand indigo lifts for contrast
rather than the surfaces inverting. The language is flat and quiet — surfaces
separate by a one-pixel hairline and a very soft shadow, not by heavy elevation.
Indigo carries every primary action, violet is the signature accent, and green
is reserved for mastery and success so it always reads as progress. Type is set
in a single sans with a tight-tracked display face for figures, and the layout
keeps a steady 16px gutter with generous card interiors.

## Colors

Format: light / dark. “both themes” reports that the two authored values are
the same — it is NOT a claim of invariance. Only inverseSurface and
onInverseSurface are intentionally invariant among these standard roles;
elsewhere an equal pair is a coincidence, and a token whose name says fixed may
still flip (mastery-fixed).

Brand & action
  primary                 #5265F5   / #8B9AFF       fills primary actions, active nav, links
  onPrimary               #FFFFFF   / #11173A       label/glyph on a primary fill
  primaryContainer        #E0E5FE   / #2D346A       tonal button, selected chip, soft emphasis
  onPrimaryContainer      #1A2580   / #D9DFFF       text on primaryContainer
  secondary               #6E7CD9   / #9DA8E8       secondary emphasis, muted brand
  onSecondary             #FFFFFF   / #1A2150       on a secondary fill
  secondaryContainer      #E3E6F7   / #343C78     
  onSecondaryContainer    #262E6E   / #DDE2FB     
  tertiary                #8B6FF5   / #B5A0FF       the violet signature accent
  onTertiary              #FFFFFF   / #240B63     
  tertiaryContainer       #EBE3FE   / #443078     
  onTertiaryContainer     #33177E   / #E6DCFF     

Surfaces — the ladder is ordered lowest to highest
  surface                 #F7F9FE   / #0A0E27       the page ground
  surfaceDim              #DAE0EF   / #060925     
  surfaceBright           #FFFFFF   / #232B5A     
  surfaceContainerLowest  #FFFFFF   / #131A3A     
  surfaceContainerLow     #F1F4FB   / #1B2249       input fill, sheet
  surfaceContainer        #E9EDF7   / #232B5A       chip, inactive track
  surfaceContainerHigh    #E2E7F3   / #2C356E       dialog
  surfaceContainerHighest #DAE0EF   / #353D7E     

Text & lines
  onSurface               #0F1638   / #E4E8FA       primary text
  onSurfaceVariant        #4A5278   / #A4ACD0       secondary text, inactive glyph
  text muted              #7C85AB   / #5A6BAE       tertiary text, timestamps
  outline                 #7C85AB   / #5A6BAE       visible borders, focus rings
  outlineVariant          #C5CBE3   / #2A3267       hairline dividers and card borders

Feedback & progress
  error                   #DC2D4E   / #FF8FA3     
  onError                 #FFFFFF   / #52061B     
  errorContainer          #FBDDE3   / #7A2036     
  onErrorContainer        #7A0A23   / #FFD9DF     
  success                 #2BA88B   / #6FE0BD     
  warning                 #F59E0B   / #FFC658     
  mastery                 #1F8A5B   / #6FE0BD       mastery/progress green
  warning ink (TEXT)      onWarning / warning      amber TEXT for an overdue count — kit-scoped, because
                                                   the warning FILL fails contrast as 12px text on light
  status new              #8C95B8   / #6B75A3     
  status learning         #F59E0B   / #FFC658     
  status reviewing        #5265F5   / #8B9AFF     
  status mastered         #1F8A5B   / #6FE0BD     

Inverse & effects
  inverseSurface          #34395D  (both themes)    snackbar slate — does NOT flip with the theme
  onInverseSurface        #E8EAFC  (both themes)    label on the snackbar
  inversePrimary          #8B9AFF   / #5265F5       action inside a snackbar
  shadow                  #0F1638   / #000000       shadow base color, mixed at the use site
  scrim                   #0A0E27   / #000000       modal scrim base, used at 45% alpha

Opacities
  disabled                0.38
  hover overlay           0.08
  pressed overlay         0.12
  glass chrome            0.84

## Typography

Family: "Plus Jakarta Sans", ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif
Display/figures: "Plus Jakarta Sans", ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif

  role            size  weight  line-height  tracking   usage
  caption         12    600     1.4          1.2px      overlines, metadata, chips, counts — hard 12px floor
  body            14    400     1.5          0          default running text
  body large      16    500     1.5          0          list titles, emphasised body
  title           20    700     1.2          -0.64px    section and screen titles
  headline        24    700     1.2          -0.64px    screen headline
  display         32    800     1.1          -0.64px    hero figure
  stat            40    600     1.0          -0.64px    large metric, tabular numerals

Weights available: 400 / 500 / 600 / 700 / 800
Type is NOT on the spacing grid — do not snap a size to a multiple of 4.

## Spacing

  value  role                usage
  4      micro gap           icon-to-label, inside a chip
  8      control internal    button padding, tight stacks
  12     grouped items       related rows inside one block
  16     screen gutter       horizontal screen padding AND list/item gap
  20     card padding        card and sheet interior
  24     section gap         between sections of a screen
  32     major separation    between major visual groups
  48     page-end clearance  scroll tail above pinned chrome

Spacing is gap / padding / inset only. Component size is a separate system —
see below.

## Radius & geometry

Radius roles — where each one actually lands in v3
  4    20px checkbox
  8    28 icon tile, compact button
  12   button, input, note, snackbar, 36-44 icon tile, small controls
  16   FAB, bottom-nav bar
  20   card, DIALOG, BOTTOM-SHEET top corners, 64 empty-state tile
  24   no call site in v3
  28   no call site in v3
  999  pill — chip, badge, toggle track, sheet grabber, progress track

Component geometry — each with its dimension class
  button height            48   MINIMUM   the painted value in every shipped instance; MINIMUM so a
                                     wrapped label or OS text scaling grows the box. Four painted
                                     sizes: 48 regular · 36 small · 32 compact · 28 chip
  small button             36   MINIMUM   a real Button size: reminder time, tag-management
                                     empty action, two DeckImport file pickers
  compact button           32   MINIMUM   inline banner action, app-bar action
  chip / filter chip       28   FIXED     never wraps (the row scrolls), so this one is fixed — the
                                     --memox-size-chip token (32) has NO call site in v3
  input height             52   FIXED     text field and search field
  icon-button ink box      36   FIXED     the painted circle only
  touch target             48   MINIMUM   applies to every interactive element
  app bar height           56   FIXED     BOTH densities are 56
  bottom nav block         80   FIXED     bar drawn at 64, rest is inset
  FAB                      52   FIXED     SQUARE, 52 × 52, icon only — v3 has no extended FAB
  card height              —    CONTENT-DRIVEN
  list row height          48   MINIMUM   grows to two title lines
  preview status bar       44   SYSTEM-OWNED  device-frame chrome, never an app dimension

## Icons

  size  role                usage
  16    inline              inside body text, compact utility
  20    compact control     dense rows, metadata, nav glyphs, FAB glyph
  24    standard action     app-bar and navigation actions
  32    large emphasis      feature tiles
  40    illustrative        empty states, hero marks

Visual icon size and touch area are separate. A 20px glyph in a 36px ink box
still needs a 48px interactive region; expand the hit area, never the painted box.
Nothing goes below 16px.

## Elevation / border / shadow

Surfaces separate by a hairline plus a very soft shadow — there is no heavy
elevation anywhere in this design.

  border         1px solid outlineVariant on cards, inputs and dividers
  card           0 12px 32px rgba(15,22,56,0.10)
  chrome         0 -2px 12px rgba(15,22,56,0.05)
  floating       0 8px 24px rgba(15,22,56,0.12)
  scrim          scrim at 45% alpha behind dialogs and sheets
  glass chrome   translucent surface + backdrop blur on the bottom nav

Hierarchy: page ground → card (hairline + card shadow) → sheet/dialog
(container surface + scrim) → floating action (fab shadow). Shadows are neutral,
never tinted with the brand color.

## Semantic alias layer — declare these too

The design references these role names by name. They are declared in
colors_and_type.css on top of the M3 tokens above; resolve each one to its
underlying role in the repository rather than inventing a new token.

  name                    light / dark             resolves to / used for
  bg                      #F7F9FE   / #0A0E27       page ground = surface
  surface-raised          #FFFFFF   / #131A3A       the .card fill
  surface-muted           #F1F4FB   / #1B2249       TextField resting fill, Note fill
  surface-hero            color-mix(in srgb, #5265F5 5%, #FFFFFF) / color-mix(in srgb, #8B9AFF 12%, #0A0E27)  tinted hero card
  chrome-glass            rgba(247, 249, 254, 0.84) / rgba(10, 14, 39, 0.84)  bottom-nav glass
  primary-soft            color-mix(in srgb, #5265F5 10%, transparent) / color-mix(in srgb, #8B9AFF 20%, transparent)  soft primary tint (tonal actions, tile tints)
  primary-border          color-mix(in srgb, #5265F5 24%, transparent) / color-mix(in srgb, #8B9AFF 32%, transparent)  primary edge at low alpha
  danger                  #DC2D4E   / #FF8FA3       = error
  on-danger               #FFFFFF   / #2A0A12       = onError
  danger-soft             color-mix(in srgb, #DC2D4E 8%, transparent) / color-mix(in srgb, #FF8FA3 16%, transparent)  ErrorState tile tint
  danger-border           color-mix(in srgb, #DC2D4E 22%, transparent) / color-mix(in srgb, #FF8FA3 32%, transparent)  destructive edge
  error-fill              #DC2D4E   / #B0485C       SOLID destructive button fill (Button destructive tone)
  on-error-fill           #FFFFFF  (both themes)    label on the destructive fill
  success-soft            color-mix(in srgb, #2BA88B 10%, transparent) / color-mix(in srgb, #6FE0BD 18%, transparent)  success tint
  warning-soft            color-mix(in srgb, #F59E0B 12%, transparent) / color-mix(in srgb, #FFC658 18%, transparent)  warning tint
  on-warning              #3A2A00   / #2A1E00       ink on a warning fill
  streak                  #F97316   / #FFAE6E       streak accent
  on-streak               #FFFFFF  (both themes)    ink on the streak fill
  mastery-fixed           #C7F2D8   / #1F4A37       invariant mastery tint
  progress-track          #E2E7F3   / #2C356E       progress / mastery track = surfaceContainerHigh
  badge-bg                #E9EDF7   / #232B5A       a surface-ladder step = surfaceContainer — declared, no v3 call site
  border-ghost            1px solid rgba(82, 101, 245, 0.14) / 1px solid rgba(139, 154, 255, 0.16)  the 1px hairline edge ("ghost border")
  border-strong           1px solid #C5CBE3 / 1px solid #2A3267  1px outlineVariant edge
  shadow-soft             0 1px 2px rgba(15,22,56,0.04) / none  the card whisper shadow (none in dark)
  shadow-none             none  (both themes)       no shadow
  radius-button           12px  (both themes)       button radius (= radius-md)
  radius-input            12px  (both themes)       input radius (= radius-md)
  radius-chip             999px  (both themes)      pill radius (= radius-full)
  radius-fab              16px  (both themes)       FAB radius (= radius-lg)

## Screen composition

The component sits on the 16px screen gutter, in a single content column.
Vertical rhythm around it: 12 between related rows, 16 between list items,
24 between sections, 32 between major groups. Card interiors are 20.
Scrollable content clears pinned chrome by 48 at the tail so the last item is
never trapped under the bottom nav or the floating action.
Hierarchy on any screen using it: primary focal surface → supporting metadata →
primary action (anchored) → secondary action (inline, lower contrast).

## Responsive / Android notes

  compact phone   the content column narrows; the gutter stays 16. Nothing
                  in this design depends on a fixed viewport width.
  large text      every text container must grow. Do not clamp text scale and
                  do not put a fixed height around text.
  landscape       the column stays single; pinned chrome remains reachable.
  keyboard open   the focused field and the primary action stay reachable; the
                  IME inset is supplied at runtime, never hardcoded.

SYSTEM-OWNED geometry — Android supplies all of it:
  status bar · display cutout · gesture/navigation inset · keyboard inset ·
  system Back. The kit's 44px status bar and its phone bezel are preview
  chrome. Never convert them into application dimensions.

## HTML/JSX translation notes

  WEB TECHNIQUE   the FAB is absolutely positioned inside the frame. The bottom
                  nav and every commit footer are NOT — they are in-flow
                  siblings of the scroll and never overlap it
  VISUAL INTENT   the floating action stays anchored above the content and clear
                  of the system inset; bottom chrome occupies its own space
  HANDOFF         preserve the anchored relationship for the FAB and the
                  in-flow relationship for the bars; absolute positioning is
                  not part of the design

  WEB TECHNIQUE   a ::after box widening a small control's tap area
  VISUAL INTENT   the painted control stays compact while the tap area meets
                  48px
  HANDOFF         keep visual size and hit area separate; the technique is
                  irrelevant

  WEB TECHNIQUE   backdrop-filter blur on the bottom nav
  VISUAL INTENT   chrome reads as translucent glass over scrolling content
  HANDOFF         reproduce the visual result; a solid surface at the same
                  value is acceptable if blur is costly

  WEB TECHNIQUE   color-mix() overlays for hover and pressed tints
  VISUAL INTENT   a percentage tint of the role color over the surface
  HANDOFF         use the platform's own overlay mechanism at the same
                  percentage

  WEB TECHNIQUE   Scrim / Dialog / BottomSheet are absolutely positioned with
                  inset:0 INSIDE the phone div, and Dialog and BottomSheet each
                  draw their own Scrim unless passed scrim={false}
  VISUAL INTENT   a modal layer covering the app surface, dimmed to 45% of the
                  scrim role color, with the panel centred (dialog) or
                  bottom-anchored (sheet)
  HANDOFF         the platform's own modal route owns the barrier and the full
                  window — the scrim={false} flag exists only because this mock
                  nests overlays inside a preview frame. Do NOT carry it across
                  as a widget parameter; take the dim percentage, the panel
                  geometry and the motion, nothing else.

  WEB TECHNIQUE   TextField and SearchField are static mocks — a <span> holding
                  placeholder text plus a CSS-animated caret, not a real input
  VISUAL INTENT   the rest / focus / error appearance of a filled field
  HANDOFF         "focused" and "error" here are VISUAL STATES, not behaviour.
                  Real focus, caret, selection, IME and validation are the
                  platform's; only the borders, fill and message styling transfer.

  Also do not copy: hover-only affordances (there is no hover on Android), the
  fake status bar, the device bezel, or any fixed pixel box drawn around text.

## Priorities

  P0  palette and both themes; type scale; 16 gutter and the spacing rhythm
  P1  this component's surface treatment, radius, geometry class and states
  P2  icon sizing per role, hairline and shadow treatment
  P3  decorative polish — flip timing, glass blur, the skeleton's opacity
      pulse (0.45 ↔ 0.75 over 1.4s — a pulse, not a shimmer sweep)


## Implementation handoff — foundations

GLOBAL VISUAL TOKENS:
  spacing 4/8/12/16/20/24/32/48 · radius 4/8/12/16/20/24/999
  icons 16/20/24/32/40 · touch target 48 minimum

COLOR / THEME SPEC:
  two themes, light / dark, in the Colors section above. inverseSurface and
  onInverseSurface are the intentionally invariant pair. tertiary is the violet
  accent; green is reserved for mastery.

TYPOGRAPHY:
  12 / 14 / 16 / 20 / 24 / 32 / 40, 12 is a hard floor, not on the 4dp grid

COMPONENT CONTRACTS:
  supplied per component, in the specs that follow this one — each carries its
  own dimension table, icon list and state matrix

SCREEN COMPOSITION:
  16 gutter · 16 list gap · 24 section gap · 32 major separation · 48 scroll tail

RESPONSIVE RULES:
  single column, no fixed widths, no fixed heights around text, no text-scale
  clamping, pinned chrome always reachable
