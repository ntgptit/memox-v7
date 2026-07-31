The bordered panel every memox surface is built on: 16px radius, hairline border, one soft shadow in light only.

```jsx
<MxCard onClick={open}>
  <h3>Academic Word List</h3>
  <p>46 cards · 5 due · 8 boxes</p>
</MxCard>
```

`elevation="flat"` for a card sitting inside another surface — a shadow stacked on
a shadow reads as a rendering fault. Passing `onClick` makes the whole surface the
target and adds the press state; the card looks identical without it.
