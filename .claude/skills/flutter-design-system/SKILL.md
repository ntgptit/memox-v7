---
name: flutter-design-system
description: Design tokens, Material 3 theming, the shared component library, responsive layout, localization and accessibility for this Flutter app. Use this skill whenever UI is being built or reviewed — creating or changing a widget, picking a colour/spacing/text style, adding a shared component, wiring light and dark themes, handling small screens or large text scale, adding user-facing strings or ARB entries, or checking semantic labels and contrast. Also use it when reviewing UI code for hardcoded colours, hardcoded padding, or untranslated strings, which are the most common violations in this codebase. Covers checklist phases 7, 12 and 13.
---

# Design system, localization and accessibility

Covers checklist Phases 7 (tokens, theme, components, responsive), 12
(localization) and 13 (accessibility).

These three are one skill because they are all properties of *how a component is
written*. A component built with a hardcoded colour, a literal string, or no
semantic label has to be reopened later; treating them as one job means they get
done once.

## Tokens come first

Nothing in `features/` may contain a raw colour, text style, padding value,
radius, elevation, icon size or duration. Those live in `core/theme/` as tokens
and reach widgets through the theme.

Token names are **semantic**, not physical. `AppColors.danger`, not
`AppColors.red`; `AppSpacing.md`, not `AppSpacing.sixteen`. The reason is that
physical names lie the first time the design changes — a `red` token that has
become orange is worse than no token, because now nobody trusts the names.

Read `references/tokens.md` for the token set and the code shape.

Spacing uses one scale: 4 / 8 / 12 / 16 / 24 / 32. A layout that needs 15 is
telling you a constraint is wrong somewhere else; reach for the neighbouring
step rather than adding a value to the scale.

## Theme

Material 3 on. Build `ColorScheme` from a seed and then override deliberately —
seeding alone gives a coherent palette, but the semantic colours (success,
warning, info) are not part of `ColorScheme` and need a theme extension.

Configure component themes centrally: AppBar, NavigationBar, Card, Dialog,
BottomSheet, Input, Button, Chip, Snackbar. Setting these once is what stops
every screen re-specifying them slightly differently.

Light and dark are both first-class. Dark is not "light with inverted colours" —
elevation reads through surface tint rather than shadow, and a colour that
passes contrast on white can fail on a dark surface.

Check every interactive component in disabled, pressed, focused and selected
states. Focused especially: it is invisible to mouse users and essential for
keyboard and switch-access users, and it is the state most often left unstyled.

## Components

Build the base set once, in `shared/widgets/`: app scaffold, app bar, primary
button, secondary button, icon button, text field, search field, card, list
item, empty state, error state, loading state, confirmation dialog, bottom
sheet.

Each needs light, dark, enabled, disabled, loading, and error where it applies.
A button without a loading state means every caller invents its own, and they
will not match.

A new shared component is not done until it has a knob-driven playground in the
Widgetbook catalog (`widgetbook/lib/components/`, registered in
`widgetbook/lib/main.dart`) — the catalog is where every state is inspected
under both themes, text scales and viewports without hunting through screens,
and the CI smoke test fails if the tree stops building. New screens go in too,
mounted with their domain contract faked; `widgetbook/README.md` has the
how-to.

Two failure modes to avoid, in tension with each other:

- **The god component.** Twenty optional parameters, half mutually exclusive.
  When a component needs a flag that changes its layout structure, that is a
  second component. Sharing a name is not sharing a purpose.
- **Premature sharing.** Two screens looking similar is not a reason to merge
  them. Wait for the second real caller before abstracting — the second caller
  is what tells you which parts actually vary. This is the checklist's "không
  tạo shared widget chỉ vì hai đoạn UI trông gần giống nhau".

Read `references/components.md` for the API conventions.

## Responsive

Mobile-first, then adapt. Use `LayoutBuilder` and the breakpoint tokens; reach
for `MediaQuery` only when you genuinely need screen-level information such as
`viewInsets` for the keyboard. Scattered `MediaQuery.of(context).size` reads
rebuild on every keyboard animation frame and hardcode assumptions about what
"the screen" means.

The four checks that catch nearly everything:

1. **Small screen** — 320×568 logical. Overflow shows here first.
2. **Large text scale** — 1.5× minimum, 2.0× ideally. Fixed-height containers
   with text inside break here.
3. **Keyboard open** — does the focused field stay visible, does the submit
   button stay reachable.
4. **Landscape** — usually a scroll problem.

Also: nothing important within reach of the bottom navigation or the home
indicator, and no action flush against a screen edge.

## Localization

Every user-visible string comes from ARB. No exceptions — a "temporary"
hardcoded string is one nobody finds again.

Support plurals and placeholders properly. Do **not** assemble sentences from
fragments: `"You have" + count + "items"` is untranslatable, because word order
and pluralisation differ per language. One key, one complete sentence, with
placeholders.

Dates and numbers go through `intl` with the active locale — never
`toString()` on a `DateTime`, and never manual thousands separators.

Plan for text expansion: German and Vietnamese commonly run 30% longer than
English. Test with the longest locale you ship, not the shortest. Check RTL if
it is in scope.

Provide a fallback locale so a missing translation degrades to readable text
rather than a blank or a key name.

## Accessibility

Not a final pass — it is part of writing a component, which is why it lives
here.

- Icon-only controls get a `Semantics` label or `tooltip`. An `IconButton` with
  no label is an unlabelled button to a screen reader.
- Touch targets at least 48×48 logical, even when the icon is smaller.
- Contrast: 4.5:1 for body text, 3:1 for large text and meaningful icons —
  in both themes.
- Never encode information in colour alone. A red border needs an error message
  or an icon beside it; roughly 1 in 12 men cannot distinguish it otherwise.
- Form fields have programmatic labels and error text tied to them, so a screen
  reader announces the field and its error together.
- Respect text scaling. Never clamp `textScaler` to 1.0 to fix an overflow —
  that breaks the layout for the users who need it most. Fix the layout.
- Check `MediaQuery.disableAnimations` for reduced-motion before running a large
  animation.
- Verify with TalkBack or VoiceOver, and with the platform accessibility
  scanner. Semantics bugs are close to invisible when reading code.

Read `references/a11y-and-l10n.md` for the concrete patterns and test setup.
