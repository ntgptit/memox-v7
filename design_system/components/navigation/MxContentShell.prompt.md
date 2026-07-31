The screen frame: app bar on the page colour, 16px gutters, optional FAB.

```jsx
<MxContentShell title="Library" actions={<MxIconButton icon="more_vert" semanticLabel="Deck actions" onClick={open} />}
  fab={{ label: 'Create deck', onPress: create }} isScrollable>
  …
</MxContentShell>
```

The app bar has no fill and no elevation; a hairline fades in underneath it only
once the body has actually scrolled, so a screen that fits shows no line at all.
Prefer `isScrollable` over a scroller of your own inside the body — the shell's
own scroll is what drives that hairline.
