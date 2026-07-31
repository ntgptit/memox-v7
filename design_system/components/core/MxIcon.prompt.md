One Material Icons glyph — use it for every icon in a memox surface; never hand-roll an SVG.

```jsx
<MxIcon name="folder" size="var(--icon-md)" />
<MxIcon name="notifications_active" filled color="var(--color-warning)" />
```

Outlined by default, matching Flutter's `Icons.*_outlined`; `filled` gives the solid
`Icons.*` twin. The page must load the Material Icons ligature fonts:
`<link href="https://fonts.googleapis.com/icon?family=Material+Icons|Material+Icons+Outlined" rel="stylesheet">`.
