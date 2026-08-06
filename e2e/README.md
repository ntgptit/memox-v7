# End-to-end suite — Flutter Web + Playwright

Drives the **real screens** of the built app through a browser, at a phone
viewport. AD-04: web is not a production target, it is the channel these tests
run on; Android is what ships.

## Running it

```bash
flutter build web --release --no-web-resources-cdn \
  -t lib/main_staging.dart --dart-define=MEMOX_E2E=true
cd e2e && npm install && npx playwright test
```

Both flags on the build matter:

- **`-t lib/main_staging.dart`** — the default entrypoint resolves to the
  development config, which seeds the fixture decks at startup. The flow starts
  at "cold start with an empty database"; a seeded one makes its first
  assertion meaningless.
- **`--dart-define=MEMOX_E2E=true`** — see below.

The config starts its own static server on `127.0.0.1:5173`. It reuses one that
is already running locally, so a rebuild is picked up without restarting
anything.

## Why the build needs a flag at all

Flutter Web paints to a canvas. The DOM a driver can read is the **semantics
tree**, and the engine builds it only after the user activates the hidden
"Enable accessibility" placeholder — the usual trick for this.

That trick does not survive here. The engine switches back to raw pointer
handling as soon as it sees ordinary pointer events, so the tree vanished the
moment the suite tapped anything, and every assertion after the first read as
"the deck was never created" while the deck was plainly on screen. The build
therefore calls `ensureSemantics()` at startup behind `isE2EBuild`
(`lib/app/bootstrap.dart`), which is a compile-time constant — a shipped build
does not contain the call.

**This is also why every control needs a semantic label.** A control a screen
reader cannot name is a control this suite cannot reach. The accessibility work
and the E2E reach are the same work, and a control that loses its label breaks
both at once.

## How elements are addressed

`specs/support/app.ts` is the whole vocabulary. Two things about it are worth
knowing before writing a spec:

- **A label reaches the DOM in two different ways.** A plain button carries it
  as text; anything given a `Semantics` label carries it as `aria-label` with no
  text at all — the scheduler radios, and every deck row, which merges its name,
  meta line and due state into one label. The helpers match both. Matching text
  alone finds the empty states and misses every row.
- **Taps use `[flt-tappable]`, not `[role="button"]`.** The engine stamps that
  attribute on every node with a tap action whatever ARIA role it ends up with;
  radios and card rows are not buttons.

## What is covered

| spec | flow |
|---|---|
| `demo-flow.spec.ts` | cold start → root deck with a scheduler → three levels → card → edit → **reload** → delete card → delete deck |
| `content-type.spec.ts` | `sm2` root; a deck locked to cards stays locked once emptied; a deck locked to sub-decks can be allowed both again (BR-68) |

The reload in `demo-flow` is the persistence check: drift keeps its data in
IndexedDB, so nothing about the page survives except what was written.

## What it does not cover

No review session — that is M5, and there is no session to drive yet. No visual
assertions: goldens and the strict visual audit own how things look, and a
screenshot comparison here would duplicate them at a much higher flake rate.
