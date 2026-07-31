Nothing to show, and that is fine — never dressed as an error.

```jsx
<MxEmptyState title="Nothing due today" message="Come back tomorrow, or study ahead." actionLabel="Show all decks" onAction={clear} />
```

The icon is the state's meaning: `check_circle_outline` for "finished",
`folder_outlined` for "you have not created anything yet". Pass an action label and
a callback together or not at all.
