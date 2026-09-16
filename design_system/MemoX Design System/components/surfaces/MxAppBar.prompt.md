MxAppBar — the screen's top bar; compact row by default, or a tall hero header with `large`.

```jsx
<MxAppBar node="dashboard/appbar" large eyebrow="Tuesday" title="Good evening"
  trailing={<MxIconButton icon="notifications" node="dashboard/notifications" />} />
```

- Compact: `leading` + `title` + `trailing`.
- `large`: `eyebrow` + big `title`, with an optional leading/trailing row.