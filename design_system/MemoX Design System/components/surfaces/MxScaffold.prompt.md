MxScaffold — the root phone shell every screen mounts into; slots an app bar, scrolling body, bottom nav and an optional FAB. Use it once per screen.

```jsx
<MxScaffold
  node="dashboard/screen"
  appBar={<MxAppBar large title="Today" />}
  bottomNav={<MxBottomNav items={tabs} value="home" onChange={setTab} />}
  fab={<MxFab icon="add" label="New deck" />}
>
  {/* cards, sections… */}
</MxScaffold>
```

- `flush` drops body side-padding for full-bleed lists.
- Body scrolls; app bar and nav stay fixed.