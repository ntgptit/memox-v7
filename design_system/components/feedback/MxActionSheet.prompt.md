The bottom action menu for a deck or card row. Renders its own scrim and drag handle.

```jsx
<MxActionSheet
  title="Academic Word List"
  actions={[
    { label: 'Rename', icon: 'edit', onPress: rename },
    { label: 'Move', icon: 'drive_file_move', onPress: move },
    { label: 'Reset learning progress', icon: 'restart_alt', onPress: reset, isEnabled: false },
    { label: 'Delete', icon: 'delete_outline', onPress: remove, variant: 'destructive' },
  ]}
/>
```

Disabled wins over destructive: a greyed row that is still red reads as available
and dangerous.
