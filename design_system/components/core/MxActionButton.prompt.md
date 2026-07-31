The app's button — one action, one variant, no colour parameter.

```jsx
<MxActionButton label="Study 15 cards due today" isBlock onClick={start} />
<MxActionButton label="End session" variant="secondary" isBlock onClick={end} />
<MxActionButton label="Delete deck" variant="destructive" onClick={remove} />
```

Variants: `primary` (indigo fill, one per screen), `secondary` (outlined, neutral
label — never brand-coloured, so it cannot compete with a review verdict),
`destructive` (the `danger` fill). `isLoading` keeps the button's width and hides
the label behind a spinner. Minimum height is 48px and cannot be overridden.
