The app's single input: outlined, 1.5px stroke, 12px radius, floating label.

```jsx
<MxTextField label="Deck name" value={name} onChange={setName} maxLength={200} />
<MxTextField label="Back" value={back} onChange={setBack} maxLines={4} onSurface />
```

Focus recolours the border to `--color-focus-ring`; an error recolours it to
`--color-danger` AND shows the message — never colour alone. Set `onSurface` when
the field sits on a card so the floating label's backing matches the surface
behind it.
