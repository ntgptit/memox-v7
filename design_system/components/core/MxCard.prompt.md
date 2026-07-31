The bordered panel every memox surface is built on: 16px radius, hairline border, one soft shadow in light only.

```jsx
<MxCard onClick={open} actionLabel={'Open ' + deck.name}>
  <h3>Academic Word List</h3>
  <p>46 cards · 5 due · 8 boxes</p>
</MxCard>
```

`elevation="flat"` — or `"none"`, the value the Flutter side uses — for a card
sitting inside another surface, or a card in a list under a hero: a shadow stacked
on a shadow reads as a rendering fault, and two competing depths in one scrolling
column make the list read as busy.

## A card that is clickable AND holds controls

`onClick` leaves the card a plain `<div>` and lays a full-bleed `<button>` under
its content. Everything above that overlay is inert; a real control takes its
pointer events back with `mx-card__control`:

```jsx
<MxCard onClick={openDeck} actionLabel={'Open ' + deck.name} elevation="none" padding="0">
  <div className="mx-deck__open">…name, meta…</div>
  <div className="mx-deck__foot">
    <span className="mx-deck__bar">5 due now</span>
    <button type="button" className="mx-deck__study mx-card__control" onClick={study}>Study</button>
    <span className="mx-deck__menu mx-card__control"><MxIconButton icon="more_vert" … /></span>
  </div>
</MxCard>
```

Hover, press and focus all live on the overlay, so they cover the **whole** card
— including the rows that hold the controls.

**Do not wrap part of a card's content in your own `<button>` to make it
clickable.** That is what this replaces, and it is exactly what produces a card
whose hover lights up only its top half while the progress bar and the footer
below look tappable and do nothing. If you find yourself reaching for it because
"the card is already a button and I can't nest one" — it is not, any more.

`actionLabel` is not optional in practice: the overlay contains no text, and the
content above it is a sibling rather than the button's label, so a card without
one announces as an unnamed button.
