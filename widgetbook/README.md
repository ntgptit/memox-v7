# memox_widgetbook

The [Widgetbook](https://widgetbook.io) catalog for memox's design tokens and
`Mx*` shared components. A separate package so the catalog's dependencies never
enter the app's dependency tree; it depends on `memox` by path and renders the
app's real themes, tokens and widgets.

## Run

```bash
flutter pub get
flutter run -d chrome
```

Addons: light/dark (the app's real `buildLightTheme`/`buildDarkTheme`), text
scale, viewports (including the 320×568 compact case from M4.8b), inspector.
Each component is a knob-driven playground; the token pages mirror what the
theme actually resolves at runtime.

## Adding a component

Add a `WidgetbookComponent` builder in `lib/components/` and register it in
`lib/main.dart`. The CI smoke test (`test/catalog_smoke_test.dart`) fails if
the tree stops building.
