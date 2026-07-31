Low-emphasis action drawn as a bare label — reveal a dismissed panel, a row
action that is a verb rather than a setting.

```jsx
<MxTextButton label="Show today's summary" trailingIcon="expand_more" onClick={show} />
<MxTextButton label="Reset learning progress" icon="restart_alt" isDestructive onClick={confirm} />
```

No padding, no radius, no hover surface — a text button with a background is an
outlined button with the border turned off. The 48px target comes from
`min-height` alone, so the label sits flush with the gutter. States live on the
text: hover darkens and underlines (offset 3px), focus underlines at 2px,
active darkens further. Colour is `--color-primary-accent`, the variant that
passes AA at label size; `--color-primary` measures 3.33:1 on dark and does not.
