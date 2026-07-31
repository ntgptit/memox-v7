The app's bottom bar — two destinations today, Decks and Review.

```jsx
<MxNavigationBar
  selectedIndex={tab} onDestinationSelected={setTab}
  destinations={[
    { icon: 'folder', label: 'Decks' },
    { icon: 'school', label: 'Review' },
  ]}
/>
```

Outlined when idle, filled when selected — the second, non-colour signal beside
the always-visible label. It paints the page colour, so there is no band edge.
