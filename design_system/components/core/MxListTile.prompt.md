A generic list row — settings, action-sheet rows, pickers. It never knows a domain type.

```jsx
<MxListTile title="Scheduler" subtitle="Eight box" trailing={<MxIcon name="chevron_right" />} onClick={open} />
```

Selected fills with `--color-surface-muted` and turns the title indigo. Disabled and
"not tappable" are different states on purpose.
