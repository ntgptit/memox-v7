# MemoX Mobile — Shared Layout System

One layout vocabulary for every screen, kept deliberately close to the Flutter
widget tree so this JSX mock translates 1:1 later. **Spacing and bottom
clearance are token-derived — never hand-tuned per screen.**

Defined in:
- `index.html` `<style>` — the `.app` layout tokens + `.scroll` / `.fab` classes.
- `screens/_shared.jsx` — the React primitives (`MobileScaffold`, `ScreenScroll`,
  `ScreenHeader`, `BottomBar`, `Fab`), published on `window`.

---

## 1. The screen as a column

Every screen is the same vertical stack inside the phone frame:

```
.app  (Scaffold + SafeArea)            display:flex; flex-direction:column
├─ StatusBar
├─ ScreenHeader      (AppBar)          fixed height
├─ .scroll           (Expanded →       flex:1; the ONLY scrollable region
│                     SingleChildScrollView)
└─ BottomBar / BottomNav               in-flow chrome, fixed height
```

Pinned chrome layers **on top** of this column via absolute positioning and is
the only thing allowed to do so:

| Pinned layer | Flutter |
|---|---|
| `.fab` | `Scaffold.floatingActionButton` |
| `.bottom-nav` | `Scaffold.bottomNavigationBar` |
| bottom sheet / scrim / dialog | `showModalBottomSheet` / `Dialog` |
| toast / snackbar | `SnackBar` |

> Normal content is **never** absolutely positioned. Absolute is for chrome only.

---

## 2. Width

Optimized for mobile widths **360–430px** (frame renders at 390). No
desktop-specific behavior, no breakpoints, no hover-only affordances.

---

## 3. Horizontal padding

One shared gutter token, applied by the `.scroll` class — no per-screen
left/right values.

```css
--screen-gutter: 16px;   /* app bars, breadcrumbs, footers and bodies all align to this */
```

A screen that needs a different *top* padding sets only `paddingTop` inline; it
never overrides the horizontal gutter.

---

## 4. Bottom clearance (the core rule)

The bottom nav and sticky footers are **in-flow siblings** of `.scroll` — they
take their own height in the column and do **not** overlap content. The FAB is
the **only** chrome that floats over the scroll. So a scroll's bottom padding
only ever needs to clear (a) a comfort gap and (b) the FAB, if present.

All clearance is composed from tokens on `.app`:

```css
--safe-bottom:   env(safe-area-inset-bottom, 0px);  /* → Flutter SafeArea */
--fab-h:         52px;                                /* extended-FAB height */
--fab-inset:     24px;                                /* FAB offset from screen bottom */
--fab-nav-gap:   4px;                                 /* FAB lift above the nav block */
--clear-comfort: 24px;                                /* breathing room above any pinned UI */

--clear-base:    calc(comfort + safe)                       /* nav / footer / plain */
--clear-fab:     calc(fab-inset + fab-h + comfort + safe)   /* FAB, no bottom nav   */
--clear-fab-nav: calc(fab-nav-gap + fab-h + comfort + safe) /* FAB above the nav    */
```

Pick the variant with a modifier class — **do not write a pixel value**:

| Situation | Class | Used by |
|---|---|---|
| Normal screen (bottom nav) | `.scroll` | Dashboard, Stats, Progress, LibrarySearch |
| Screen with sticky footer | `.scroll` | Create, Edit, Import, StudyResult, Onboarding |
| Screen with FAB + bottom nav | `.scroll.scroll-fab-nav` | LibraryOverview |
| Screen with FAB, no nav | `.scroll.scroll-fab` | FlashcardList, FolderDetail |
| Bottom sheet / dialog open | (overlay covers content — no clearance needed) | — |

This replaced the old one-off paddings (`14` / `100` / `110` / `24` …).

---

## 5. React primitives (`window`)

Thin wrappers over the classes above — use them on new screens; existing screens
already follow the same rules via the shared classes.

```jsx
<MobileScaffold
   header={<ScreenHeader leading={…} title="Library" actions={…} />}
   bottomBar={<BottomNav active="library" onChange={go} />}
   fab={<Fab icon="folder-plus" label="New folder" aboveNav />}
   overlay={sheetOrDialog}          // optional pinned full-bleed layer
   clearance="fab-nav">             // 'base' | 'fab' | 'fab-nav'
  …scroll children…
</MobileScaffold>
```

| Primitive | Flutter |
|---|---|
| `MobileScaffold` | `Scaffold` + `SafeArea` |
| `ScreenHeader` | `AppBar` |
| `ScreenScroll` (`.scroll`) | `Expanded( SingleChildScrollView )` |
| `BottomBar` | `Scaffold.bottomNavigationBar` / `persistentFooterButtons` |
| `Fab` (`.fab`, `aboveNav`) | `FloatingActionButton.extended` |

---

## 6. Flutter migration shape

```dart
Scaffold(
  body: SafeArea(
    child: Column(children: [
      _Header(),
      Expanded(child: SingleChildScrollView(           // .scroll
        padding: EdgeInsets.fromLTRB(g, 0, g, clearance),
        child: Column(/* content */),
      )),
    ]),
  ),
  bottomNavigationBar: const AppBottomNav(),           // in-flow chrome
  floatingActionButton: FloatingActionButton.extended( // pinned chrome
    onPressed: …, icon: …, label: …,
  ),
)
```

`Stack` is introduced in Flutter only where the mock uses absolute positioning
(FAB, sheet, scrim, toast) — never for normal content layout.
