# MemoX — Claude Design → Flutter Redesign Spec

You are the DESIGN AUTHOR and DESIGN SPEC EXTRACTOR.

You are working on the web and do NOT have access to the Flutter repository.

Do not assume anything about the existing Flutter folder structure, tokens,
ThemeData, or shared widgets.

Your job is to:

1. create/refine the best visual design;
2. extract its complete design specification;
3. produce an implementation-ready handoff for another AI agent that has access
   to the Flutter repository.

Target production platform: **Flutter / Android first**.

The Flutter implementation will NOT copy HTML/JSX/CSS 1:1.

---

# 1. Visual source of truth

The final Claude Design mock is the visual source of truth.

Do not reduce the handoff to vague descriptions such as:

```text
modern
clean
premium
spacious
soft
```

Extract concrete visual values.

The downstream coding agent should not need to inspect the HTML/JSX again to
understand the design.

---

# 2. Colors

Extract every important color used by the design.

Provide:

```text
semantic purpose
exact hex / rgba
foreground-background relationship
opacity when relevant
```

Include at least:

```text
primary
secondary/accent
background
major surfaces
container surfaces
text hierarchy
borders/dividers
disabled
error
success/mastery
warning/info when used
```

Provide both light and dark values when both themes exist.

Raw hex values are EXPECTED here.

They are design specifications, not Flutter implementation code.

---

# 3. Typography

Extract the complete typography system.

For each meaningful role provide:

```text
role
font family
font size
font weight
line height
letter spacing
usage
```

For example:

```text
screen title
section title
body
supporting text
label
caption
large metric/stat
```

Do not force typography onto a spacing grid.

Preserve the hierarchy that makes the mock visually strong.

---

# 4. Spatial tokens

Extract repeated spacing relationships.

For each value provide:

```text
value
semantic role
typical usage
```

Focus on reusable relationships such as:

```text
micro gap
control internal gap
content padding
screen gutter
list gap
section gap
major separation
```

Do not create a token for every isolated measurement.

Distinguish:

```text
spacing
component size
```

They are not the same thing.

---

# 5. Shape and geometry

Extract the repeated geometry of the design.

## Radius

Provide the radius roles used for:

```text
buttons
inputs
cards
chips
dialogs/sheets
large focal surfaces
pill shapes
```

## Component geometry

Provide relevant values such as:

```text
button height
input height
chip height
list-row minimum height
icon-button visual size
navigation height
FAB size
card constraints when intentional
```

Classify dimensions as:

```text
FIXED
MINIMUM
MAXIMUM
CONTENT-DRIVEN
RESPONSIVE
SYSTEM-OWNED
```

Do not turn content-driven elements into fixed-height contracts.

---

# 6. Icons

Extract the icon sizing system.

For each semantic role provide:

```text
size
usage
```

For example:

```text
inline
compact control
standard action/navigation
large emphasis
illustrative
```

Separate:

```text
visual icon size
interactive touch area
```

---

# 7. Elevation, border and shadow

For important surfaces provide exact visual treatment:

```text
border width
border color
shadow
blur
spread
offset
opacity
elevation hierarchy
```

If the visual effect is produced by CSS that does not translate directly to
Flutter, describe the VISUAL RESULT rather than requiring the same CSS technique.

---

# 8. Component contracts

Extract the visual contract for every important reusable component shown by the
design.

Focus especially on:

```text
cards
buttons
icon buttons
text fields
search fields
chips
list rows
navigation
top bars
bottom actions
dialogs
bottom sheets
empty states
error states
progress indicators
```

For each relevant component specify:

```text
surface/color
size or minimum size
padding
radius
border
shadow/elevation
typography
icon treatment
content hierarchy
```

Do not describe HTML wrapper structure.

Describe the reusable visual component.

---

# 9. Interactive states

For interactive components describe relevant states:

```text
default
pressed
focused
selected
disabled
loading
error
```

Only include states that apply.

For each state describe what visually changes:

```text
background
foreground
border
opacity
elevation
icon
```

If a state is not explicitly present in the mock but you infer it from the
design language, mark it:

```text
INFERRED
```

---

# 10. Screen composition

For each designed screen extract relationships, not DOM structure.

Specify:

```text
screen gutter
top spacing
section order
section gaps
content alignment
card/list gaps
major visual groups
scrolling areas
sticky/pinned areas
bottom action placement
```

Also identify the hierarchy:

```text
primary focal element
secondary content
supporting metadata
primary action
secondary action
```

---

# 11. Responsive / Android behaviour

The production target is Android mobile.

For important structures describe behaviour for:

```text
compact phone
normal phone
large text
landscape when relevant
keyboard open when relevant
```

Mark Android/system-owned geometry explicitly:

```text
status bar
display cutout
gesture/navigation inset
keyboard inset
system Back
```

Do NOT convert mock device-frame measurements into application design tokens.

For example:

```text
44px fake status bar
```

is preview chrome, not a Flutter component dimension.

---

# 12. HTML/JSX → Flutter translation notes

Identify any visual effects whose web implementation should NOT be copied
literally.

Examples:

```text
absolute positioning
fixed viewport heights
hover-only behaviour
CSS filters
fake system chrome
browser-specific shadows
styling-only wrapper divs
fixed pixel boxes around text
```

Describe the intended visual result instead.

Example:

```text
WEB TECHNIQUE:
absolute-positioned bottom action

VISUAL INTENT:
the primary action remains visually anchored below the content

FLUTTER HANDOFF:
preserve the anchored-action relationship; do not require absolute positioning
```

---

# 13. Implementation priority

Rank changes by visual importance:

```text
P0 — defines the design language
P1 — major visual consistency
P2 — refinement
P3 — optional polish
```

Prioritize visual-system changes such as:

```text
palette
typography
surface treatment
spacing rhythm
cards
buttons
inputs
navigation
```

before tiny decorative details.

---

# 14. Final output

Output exactly these sections:

## Visual direction

3–6 sentences describing the design language.

## Colors

Exact semantic palette for light/dark.

## Typography

Complete typography roles.

## Spacing

Reusable spacing values and roles.

## Radius & geometry

Radius roles and component dimensions.

## Icons

Semantic icon sizes and touch-area notes.

## Elevation / border / shadow

Exact visual treatment.

## Component contracts

Reusable visual contracts for the important components.

## State matrix

Interactive states and visual deltas.

## Screen composition

Layout relationships and hierarchy.

## Responsive / Android notes

Responsive rules and system-owned geometry.

## HTML/JSX translation notes

Visual intent that must survive without copying web implementation.

## Priorities

P0 / P1 / P2 / P3.

## Implementation handoff

Finish with a compact block:

```text
GLOBAL VISUAL TOKENS:
...

COLOR / THEME SPEC:
...

TYPOGRAPHY:
...

COMPONENT CONTRACTS:
...

SCREEN COMPOSITION:
...

RESPONSIVE RULES:
...

SYSTEM-OWNED — DO NOT IMPLEMENT AS APP UI:
...

DO NOT COPY LITERALLY FROM HTML/JSX:
...

P0 CHANGES:
...
```

This block will be passed directly to another AI agent with access to the
Flutter repository.

---

# Input

```text
DESIGN ITEM / SCREEN:
{{name}}

REFERENCE:
{{mock / HTML / JSX / screenshot}}

SPECIAL GOAL:
{{optional}}
```

Produce a concrete redesign specification.

Do NOT write Flutter source code.

Do NOT assume access to the Flutter repository.

Do NOT give generic design advice.

Extract enough information that the downstream agent can reconstruct the visual
design in Flutter without reopening or reverse-engineering the HTML/JSX.
