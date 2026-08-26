The app's button — one action, one variant, no colour parameter.

```jsx
<MxActionButton label="Study 15 cards due today" isBlock onClick={start} />
<MxActionButton label="End session" variant="secondary" isBlock onClick={end} />
<MxActionButton label="Delete deck" variant="destructive" onClick={remove} />
<MxActionButton label="Delete card" variant="destructive-secondary" isBlock onClick={remove} />
```

Variants: `primary` (indigo fill, one per screen), `secondary` (outlined, neutral
label — never brand-coloured, so it cannot compete with a review verdict),
`destructive` (the `danger` fill), `destructive-secondary` (outlined, `danger`
label **and** `danger` edge). `isLoading` keeps the button's width and hides
the label behind a spinner. Minimum height is 48px and cannot be overridden.

**Weight and danger are two axes, and `destructive` was answering both.** A
filled red button is the loudest thing a screen can draw — right in a confirm
dialog, where destroying something is the question being asked; wrong in a form
whose primary action is Save, where it shouts as loudly as the action the user
came for and leaves colour as the only difference. Pick `destructive-secondary`
when the screen has a primary action that is *not* the destruction.

`shouldKeepLabelWhileLoading` reverses that trade — the label stays painted and
the spinner moves to the leading slot:

```jsx
<MxActionButton label="Exporting…" isLoading shouldKeepLabelWhileLoading isBlock onClick={submit} />
```

It makes the row wider than the label alone, so it is for `isBlock` or a flex
row where the width is already decided, never for a button that sizes to its own
content. Reach for it when the wait has a name the user has to read: a bare
spinner announces "busy" to a screen reader and says nothing to anyone else.
