Something failed and the user may be able to retry.

```jsx
<MxErrorState title="Couldn't load your decks" message="The library is saved on this device. Try again." retryLabel="Try again" onRetry={reload} />
```

Retry is a `secondary` button, never primary: the screen is reporting, not asking.
The copy is the screen's — this component maps no failure types.
