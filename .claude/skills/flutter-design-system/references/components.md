# Component library conventions

Location: `shared/widgets/`. Every component is `*_widget.dart` and has a
`const` constructor.

## API conventions

**Required things are required.** If a button without an `onPressed` makes no
sense, make it required rather than nullable-with-a-default. Optional parameters
with defaults are where god components come from — each one is a decision
deferred to every call site.

**Model finite variation as an enum, not as booleans.**

```dart
// no — 4 combinations, 2 of which are nonsense
AppButton(isPrimary: true, isDestructive: true, isGhost: false)

// yes — the illegal states cannot be written
enum AppButtonVariant { primary, secondary, ghost, destructive }
AppButton(variant: AppButtonVariant.destructive)
```

**Loading is a state of the component, not of the caller.** A button that owns
`isLoading` disables itself, swaps its label for a spinner sized to the label,
and keeps its width so the layout does not jump. If every caller does this
itself, none of them will do it the same way.

**Do not take a `Color` or a `TextStyle` parameter.** That is a hole through
which hardcoded values re-enter. If a component needs to look different, that is
a variant.

**Do not take a `BuildContext`.** It already has one.

## A surface that is a target

A card, a tile or a row the user can tap is **a surface with a target composed
into it** — not a control that happens to look like a surface. Three parts, in
this order:

1. the surface paints its own background, border and elevation;
2. the target covers **all** of it — the ink layer in Flutter, an absolutely
   positioned `<button>` under the content on the web;
3. any control the surface carries sits above the target and keeps its own tap.

A contract, not a preference, because the alternative does not compose. A surface
that *is* the control can hold no other control, so the first caller needing one
wraps a **region** of the content instead — and every region left over then looks
tappable and is not. It reads as a layout decision while you are making it. The
rationalization it ships with, verbatim from this repo before the fix: *"its own
target, not the whole card … the card used to be one button with the overflow
menu nested inside it, which works but makes the menu a hole in the middle of a
large target."* Both halves of that sentence are true; the conclusion is still
wrong, because a nested button wins the gesture arena and there was no hole.

**Flutter: the ink goes inside the decoration.**

`InkWell` paints its splash and its hover highlight *before* it paints its child,
so an ink layer wrapped **around** an opaque `DecoratedBox` draws every state
underneath the surface colour — a tappable card with no feedback at all. Nothing
fails, no golden moves, and it survives until someone happens to press one.

```dart
// no — the surface colour is painted over the splash
Material(child: InkWell(onTap: t, child: DecoratedBox(decoration: d, child: body)))

// yes — splash over the surface, under the content
DecoratedBox(decoration: d, child: Material(child: InkWell(onTap: t, child: body)))
```

`mx_card.dart` is the worked example, `deck_tile_widget.dart` the caller, and
`deck_tile_target_test.dart` pins it by geometry — which is the only way to see
it, since the widget tree is identical either way and only the reacting pixels
differ.

## The base set

| Component | Must handle | Notes |
|---|---|---|
| `AppScaffold` | safe areas, keyboard insets | wraps `Scaffold`, applies consistent padding |
| `AppBarWidget` | title, actions, back behaviour | one place for app-bar styling |
| `AppButton` | variant, loading, disabled, full-width | min height 48 for touch target |
| `AppIconButton` | semantic label **required** | unlabelled icon buttons are unusable with a screen reader |
| `AppTextField` | label, error, helper, obscure, keyboard type | error text tied to the field for a11y |
| `AppSearchField` | debounce, clear button | debounce belongs here, not in every caller |
| `AppCard` | tap target, elevation from tokens | tappable = surface + target composed in, never a card that *is* a button |
| `AppListItem` | leading/trailing, 2-line, tap | |
| `AppEmptyState` | icon, title, message, optional action | most-skipped state — build it early |
| `AppErrorState` | message, retry callback | takes a message string, never a `Failure` |
| `AppLoadingState` | full-screen and inline variants | |
| `AppConfirmDialog` | destructive variant, cancel default | destructive action must not be the default focus |
| `AppBottomSheet` | drag handle, scroll, keyboard-safe | |

`AppErrorState` taking a `String` rather than a `Failure` is deliberate: it keeps
`shared/` free of domain types, so the component stays reusable and the mapping
from failure to message happens once, in the presentation layer.

## Component checklist

Before a component is done:

- [ ] `const` constructor.
- [ ] No hardcoded colour, text style, spacing, radius or duration.
- [ ] Light and dark both correct.
- [ ] Enabled, disabled, pressed, focused all styled.
- [ ] If tappable: the target covers the **whole** surface, its feedback is
      visible over the surface colour, and any control it carries still fires on
      its own. Checked by pressing a corner, not by reading the tree.
- [ ] Loading state if it can trigger async work.
- [ ] Semantic label on anything without visible text.
- [ ] Touch target ≥ 48×48.
- [ ] Survives 2.0× text scale without overflow.
- [ ] Survives a 320px-wide screen.
- [ ] Long text truncates or wraps deliberately, not by accident.
- [ ] Golden test for light and dark (Phase 15.4).

## Widget composition

Split by UI section into private widget *classes*, not `_buildX()` methods:

```dart
// no — everything rebuilds together, no const possible
Widget _buildHeader() => Row(...);

// yes — independent rebuild scope, const constructor
class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Row(...);
}
```

A `_buildX()` method looks like decomposition but is not: the returned subtree is
part of the parent's build, so it rebuilds whenever the parent does and can never
be `const`. Separate classes give narrower rebuild scopes for free — the same
point Phase 17 makes about limiting rebuild range.
