Renders loading / error / data for one async read, so the loading policy is written down once.

```jsx
<MxAsyncView
  status={status} value={decks} loadingLabel="Loading your decks"
  data={(d) => <DeckList decks={d} />}
  renderError={() => <MxErrorState title="Couldn't load your decks" message="…" retryLabel="Try again" onRetry={reload} />}
/>
```

A refresh keeps the previous data on screen; only an initial read shows the spinner.
