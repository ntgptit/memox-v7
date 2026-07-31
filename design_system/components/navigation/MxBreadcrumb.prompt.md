"Where am I, and how do I get back up" — the deck tree's path strip.

```jsx
<MxBreadcrumb semanticLabel="Deck path" rootIcon="home" items={[
  { label: 'Library', onTap: () => go(0) },
  { label: 'Academic Word List', onTap: () => go(1) },
  { label: 'Sublist 1', onTap: () => go(2) },
]} />
```

Pass **ancestors only** — the app-bar title one line above already names the
current deck. Past four steps the middle folds into a "…" the user can expand in
place; the strip scrolls horizontally and auto-scrolls to its deep end. Every
step is a 48px target.
