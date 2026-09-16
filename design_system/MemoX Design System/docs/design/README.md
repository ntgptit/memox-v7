---
last_updated: 2026-06-06
status: contract
applies_to: UI mock-to-code implementation
generated_by: mock-design documentation pass (2026-06-06)
---

# MemoX Mock-Design Documentation

This folder is the **bridge between the approved visual mock and the Flutter
implementation**. It tells a coding agent (Claude Code, Codex, or a human) how
each mocked screen should be built **using the design system, tokens, shared
widgets, localization, route contracts, and state contracts that already exist
in this repository** — not how to redesign them.

> The common theme, design tokens, typography, spacing, radius, color roles, and
> reusable shared widgets already exist. **Do not redesign them. Do not invent a
> new design system.** Map mock visual intent onto what is already in the repo.

## Why this folder (and not `ui_kits/ui_kits_docs/`)

The task brief suggests creating docs under `ui_kits/ui_kits_docs/` if a
`ui_kits` folder exists. A `ui_kits` folder **does** exist, but it holds the
**mock source itself**, not its documentation:

- `docs/system-design/MemoX Design System/ui_kits/mobile/index.html` — the
  interactive 23-screen click-through (the mock).
- `docs/system-design/MemoX Design System/ui_kits/mobile/README.md`,
  `AUDIT.md` — descriptions of that mock.

The repo's **mock-design documentation contract** already lives in
`docs/design/`:

- `docs/design/mock-design-index.md`
- `docs/design/design-token-mapping.md`
- `docs/design/component-visual-contract.md`
- `docs/design/visual-parity-checklist.md`
- `docs/design/screens/library-overview.visual-contract.md` (the first fully
  mapped screen)

Per the brief's own fallback rule ("if the repo uses a different current path,
create the docs in the nearest appropriate mock-design documentation folder and
explain why"), this generated set is added **here, in `docs/design/`**, so it
extends the existing contract set instead of forking a parallel docs tree under
`ui_kits/`. Co-locating mock-source under `ui_kits/` and mock-documentation under
`docs/design/` keeps a single home for each concern.

## What is in this folder

| File | Purpose |
| --- | --- |
| `README.md` | This file — how to use the docs, source priority, and the non-redesign rules. |
| `screen-index.md` | Master table: every mock screen → route, mock source, related docs, existing Flutter files, visual contract, **scope status**, priority. |
| `mock-design-index.md` | Pre-existing lighter index that maps approved mocks to routes/wireframes/contracts. `screen-index.md` is the fuller scope view; keep both in sync. |
| `design-token-mapping.md` | Pre-existing. How mock visual intent maps to `SpacingTokens` / `RadiusTokens` / `SizeTokens` / typography roles / `ColorScheme` roles. |
| `component-visual-contract.md` | Pre-existing. Which `Mx*` shared widget owns each UI need. |
| `visual-parity-checklist.md` | Pre-existing. Gate to run before reporting a screen complete. |
| `screens/{screen}.visual-contract.md` | One per screen. The detailed, section-by-section visual contract a coding agent reads to implement that screen. |

## How Claude Code / Codex should use these docs

1. **Find the screen** in `screen-index.md`. Read its **scope status** first.
   Implement only `Current` (and `Partial`) elements unless a task explicitly
   promotes a `Future` item.
2. **Open the screen's visual contract** in `screens/`. It is the single entry
   point: it links every business/wireframe/state/route doc and every existing
   Flutter file you must read before editing.
3. **Read the linked wireframe and business spec** named in the contract's
   "Source priority" and "Flutter implementation guidance" sections.
4. **Read `design-token-mapping.md` and `component-visual-contract.md`** so you
   reach for the right token name and the right `Mx*` widget.
5. **Implement**, composing existing `Mx*` shared widgets, theme roles, l10n
   keys, and route builders.
6. **Run `visual-parity-checklist.md`** before reporting completion.

## Source priority (authoritative order)

When sources disagree, follow this order. Lower-numbered sources win.

1. **V1 scope / business docs** — `docs/business/**`.
2. **Wireframe docs** — `docs/wireframes/**` (layout, states, actions, the
   `## V1 verification status` block that marks Current vs Future).
3. **State-management docs** — `docs/state/**`.
4. **Route / navigation contracts** — `docs/business/navigation/navigation-flow.md`,
   `lib/app/router/route_paths.dart`, `route_names.dart`.
5. **Existing Flutter implementation** — `lib/presentation/features/**`,
   `lib/app/**`.
6. **Existing shared widgets / components** — `lib/presentation/shared/**`
   (the `Mx*` kit, barreled in `mx_widgets.dart`).
7. **Existing theme and tokens** — `lib/core/theme/**`.
8. **Mock design visual intent** —
   `docs/system-design/MemoX Design System/ui_kits/mobile/index.html` and
   `colors_and_type.css`.
9. **This generated visual contract** — the per-screen files in `screens/`.

> The mock is for **visual intent only**. It must never override product scope,
> business rules, routing, state, accessibility, or existing design-system
> contracts. If a contract here ever disagrees with a higher-priority source,
> the higher source wins and the contract should be corrected.

## The mock describes intent, not implementation

The mock (`index.html`) is a static HTML/JSX click-through. It exists to fix the
**visual language** — hierarchy, spacing rhythm, surface ladder, state coverage.
Its raw output is **not** an implementation artifact.

**Agents must NOT copy any of the following from the mock into Flutter code:**

- ❌ Raw HTML structure or JSX components.
- ❌ Raw CSS, CSS custom properties, or Tailwind-style classes.
- ❌ Raw hex colors (`#5265F5`, `#0F1638`, …) — use `ColorScheme` roles and
  theme extensions.
- ❌ Random pixel values (`padding: 14px`) — use `SpacingTokens.*`,
  `RadiusTokens.*`, `SizeTokens.*`.
- ❌ Mock-only inline styles, gradients, or shadows.
- ❌ Lucide icon names — the app uses Material Symbols (`Icons.*`). Lucide is a
  web-only stand-in.
- ❌ Hardcoded user-facing strings — copy comes from l10n (`app_en.arb` /
  `app_ko.arb` / `app_vi.arb`); counts use ICU plurals.
- ❌ Mock/demo data (sample folder names, fake counts) — these are illustrative.

**Instead, every mock value resolves to a repo construct:**

| Mock thing | Resolve to |
| --- | --- |
| Color / surface | `context.colorScheme.*` role + `CustomColors` extension |
| Spacing / gap | `SpacingTokens.*` |
| Radius | `RadiusTokens.*` |
| Icon / touch size | `SizeTokens.*` |
| Text style | `MxText` role / `TextTheme` (collapsed scale 48/32/24/20/16/14/12) |
| Card / input / sheet | `MxCard` / `MxSearchField` / shared sheet — never a raw `Container`/`TextField` |
| Copy | l10n key (ICU plural for counts) |
| Motion | `DurationTokens.*` / `EasingTokens.*` (no `elasticOut`) |

## Conflict rule: docs override the mock

If the mock shows something that business / wireframe / state / route / schema
docs do not support (a control, a count, a navigation target, a behavior):

1. **Stop. Do not implement it to "match the mock."**
2. The higher-priority doc wins. Mark the mock element `Future`, `Visual-only`,
   or `Rejected` in the screen's contract, with the reason.
3. If sources genuinely conflict (e.g. a wireframe's `V1 verification status`
   contradicts the screen's own code comment — see Folder Detail), record it in
   the contract's **§16 Open questions and conflicts** and escalate. Do not
   guess.

## Design system at a glance (for context only — never hardcode)

- **Themes:** *Tokyo Pure Light* (day) and *Tokyo Nebula* (night). Dark mode is
  in scope; design every surface for both.
- **Type:** Plus Jakarta Sans, one family, collapsed scale 48/32/24/20/16/14/12.
- **Color:** Material 3 seeded `ColorScheme` (indigo seed). Cards carry a `1px`
  **ghost border** (15% outlineVariant) instead of shadows.
- **Spacing:** 4dp grid. **Radius:** cards/dialogs/sheets `lg 16`,
  buttons/inputs `md 12`, chips `full`, FAB `xxl 28`.
- **Voice:** calm, second-person, no emoji, no hype. Counts pluralized via ICU.
- **Icons:** Material Symbols (`Icons.*`). The *only* gradient anywhere is the
  mastery tri-stop gradient.

Token sources of truth: `lib/core/theme/tokens/**`,
`lib/core/theme/extensions/**`, `lib/core/theme/schemes/**`.

## Related

- `docs/design/screen-index.md`
- `docs/design/design-token-mapping.md`
- `docs/design/component-visual-contract.md`
- `docs/design/visual-parity-checklist.md`
- `docs/ui-ux/ui-ux-contract.md`
- `docs/wireframes/index.md`
- `docs/system-design/MemoX Design System/README.md`
- `docs/system-design/MemoX Design System/ui_kits/mobile/README.md`,
  `AUDIT.md`
