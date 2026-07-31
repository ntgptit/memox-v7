One question, two answers. Renders its own scrim; position it over a screen.

```jsx
<MxConfirmDialog
  variant="destructive"
  title="Delete “Phrasal verbs”?"
  message="This also deletes 4 sub-decks and 88 cards. This cannot be undone."
  confirmLabel="Delete" cancelLabel="Cancel"
  onConfirm={remove} onCancel={close}
/>
```

On a destructive dialog focus starts on Cancel, so a stray Enter cannot delete
anything. Build the sentence — counts and plurals included — at the call site.
