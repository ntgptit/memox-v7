# MxCard

A bordered panel that carries elevation. The app's one raised surface.

## Use it when

Content needs to read as an object sitting on the page: a review card, a deck
summary, a settings group, a stat panel.

## Elevation

| Value | dp | For |
| --- | --- | --- |
| `none` | 0 | A card **inside** another surface. A shadow stacked on a shadow reads as a rendering fault rather than as depth. |
| `card` | 1 | The default. A card in a list. |
| `raised` | 3 | Deliberately lifted above its neighbours — selected, dragged. |
| `overlay` | 8 | A sheet or dialog over the whole screen. |

**Dark mode paints no shadow at any level, and that is measured.** The dark page
is at L* 3.86, the bottom of the scale, so a shadow has no room below it to
occupy: at alpha 0.10 it moves the page by ΔL* 0.26 where the surface step already
moves it 7.70. Dark separates the card with the surface ladder and its border;
light separates it with a lighter border and a solved-for shadow. The two modes
stay symmetric in the thing a reader perceives — total lift, ΔL* 8.04 against 7.70
— not in how they get there.

## Interactive cards

`onTap` renders a real `<button>`, so the card gets the button role, focus,
Enter/Space activation and a focus ring without a call site arranging any of it.

**Do not add an `aria-label`.** The children are readable text and already name
the card; a label would replace that content for a screen reader rather than add
to it.

**Do not nest a button inside a tappable card.** One target or the other — a
control inside a control gives the user two overlapping hit areas and a keyboard
user a tab stop that does the wrong thing.

## Do not

- Set a background or a border at a call site. `--mx-color-surface` and
  `--mx-color-border-subtle` are the card, and a screen that paints its own is the
  screen that looks wrong beside the others.
- Reach for `raised` to mean "important". Importance is type and colour; elevation
  is depth.
