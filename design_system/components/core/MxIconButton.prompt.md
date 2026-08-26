Icon-only action — app-bar overflow, row menus, a close button.

```jsx
<MxIconButton icon="more_vert" semanticLabel="Deck actions" onClick={openSheet} />
```

`tone="warning"` paints the glyph in the warning role, for a state the user set
and can undo — the card editor's raised flag:

```jsx
<MxIconButton icon="flag" tone="warning" semanticLabel="Remove flag" onClick={unflag} />
```

An enum, not a colour prop: a colour prop lets any caller paint any glyph any
shade. And never the only signal — change the glyph with the state
(`flag_outlined` -> `flag`) and let `semanticLabel` say which way the next tap
goes.

The 48x48 target and the 12px radius come from the theme; there is no size prop.
Keyboard focus draws a 2px indigo ring, because the default tint alone measures
1.15:1 and fails WCAG 1.4.11.
