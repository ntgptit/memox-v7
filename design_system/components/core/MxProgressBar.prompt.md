How far through something the user is — a deck's mastery, a session's run.

```jsx
<MxProgressBar value={0.62} label="Learned" valueLabel="62%" size="sm" />
<MxProgressBar value={3 / 20} valueLabel="3 of 20" />
```

Draws in `--color-progress-*`, never the accent: a bar in the accent colour sits
beside a button in the accent colour and neither reads as the pressable one. At
100% the fill turns `--color-progress-complete` and the value label follows it.

## A bar used as an edge

`shape="flush"` squares the track's ends. Use it when the bar **is** a container's
edge rather than a component sitting on a surface — the deck card seats one on its
base:

```jsx
<MxCard elevation="none" padding="0" onClick={open} actionLabel={'Open ' + deck.name}>
  …
  <MxProgressBar value={learned} size="sm" shape="flush" />
</MxCard>
```

Two things have to be true for that to look right, and both bit once:

- **The container clips, not the bar.** A radius set on the bar is clamped to the
  bar's own height — 6 on a 6px track — so it rounds the bar instead of following
  the card's 16px corner, and the colour runs past the corner. `.mx-card` carries
  `overflow:hidden` for this.
- **Square ends.** A pill end seated inside a 16px corner reads as a lozenge
  tucked into it rather than as the card's base.
