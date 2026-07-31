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

## Adding a screen

Every new production screen gets a use-case here as well (Definition of Done).
Mount the screen inside a `ProviderScope` that overrides its domain contract
with the feature's existing fake, and use knobs to select the states worth
looking at — empty, a few items, long Vietnamese names, error:

```dart
WidgetbookUseCase(
  name: 'Playground',
  builder: (context) {
    final state = context.knobs.object.dropdown(
      label: 'state',
      options: ['empty', '3 decks', 'long names', 'error'],
    );
    return ProviderScope(
      overrides: [
        deckRepositoryProvider.overrideWithValue(fakeFor(state)),
      ],
      child: const RootDeckListScreen(),
    );
  },
)
```

Components in isolation cannot show composition problems — double padding,
a counter wrapping badly next to a trailing action, a layout that only breaks
with real-length data. Screen use-cases are where those become visible, with
the viewport and theme addons doing the rotating.
