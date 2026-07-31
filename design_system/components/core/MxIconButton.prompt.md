Icon-only action — app-bar overflow, row menus, a close button.

```jsx
<MxIconButton icon="more_vert" semanticLabel="Deck actions" onClick={openSheet} />
```

The 48x48 target and the 12px radius come from the theme; there is no size prop.
Keyboard focus draws a 2px indigo ring, because the default tint alone measures
1.15:1 and fails WCAG 1.4.11.
