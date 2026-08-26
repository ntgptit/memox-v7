The app's single input: outlined, 1.5px stroke, 12px radius, floating label.

```jsx
<MxTextField label="Deck name" value={name} onChange={setName} maxLength={200} />
<MxTextField label="Back" value={back} onChange={setBack} maxLines={4} onSurface />
```

`trailingAction` puts one button at the field's trailing edge — the visible half
of an action the keyboard's Enter also performs:

```jsx
<MxTextField label="Add tag" value={draft} onChange={setDraft}
  trailingAction={{ icon: 'add', semanticLabel: 'Add this tag',
                    onClick: draft.trim() ? submit : undefined }} />
```

A typed triple, not a slot: a slot would let a caller put a second text style or
a whole row inside a field. Omitting `onClick` leaves it visible and inert, so
the button does not appear under the finger as the first character lands.

Focus recolours the border to `--color-focus-ring`; an error recolours it to
`--color-danger` AND shows the message — never colour alone. Set `onSurface` when
the field sits on a card so the floating label's backing matches the surface
behind it.
