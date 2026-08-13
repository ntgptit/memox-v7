# Definition of Done

A task is done when every line below is true. "Mostly done" is not a state that
exists here — a task marked done in the WBS is one the next person will build on
without re-checking.

## Scope
- [ ] The work matches the WBS entry — no more, no less.
- [ ] Acceptance criteria from the WBS entry all pass.
- [ ] No refactoring outside the stated scope leaked in. If you found something
      that needs fixing, note it in the WBS as a separate item rather than
      widening this one.
- [ ] Existing architecture was not broken to make this fit. If the architecture
      genuinely blocked the task, that is a design conversation, not a workaround.

## Code
- [ ] `dart format` produces no changes — run `check_format.sh`, not
      `dart format .`, which walks into the worktrees under `.claude/` and
      formats other branches' source (and crashes on their build output).
- [ ] `flutter analyze` is clean — zero errors *and* zero warnings.
- [ ] No new dependency without a stated reason.
- [ ] Layer boundaries hold (`check_architecture.sh` passes).
- [ ] No `catch (_) {}`, no unexplained `// ignore:`, no leftover `print`.

## Tests
- [ ] Tests for the business logic this task added or changed.
- [ ] The failure paths are tested, not just the happy path.
- [ ] Full suite passes, not only the new tests.

## UI (skip only if the task touched no UI)
- [ ] All colours, text styles, spacing and radii come from design tokens.
- [ ] Light mode and dark mode both checked.
- [ ] Small screen checked — nothing overflows, nothing is hidden behind the
      bottom navigation or the keyboard.
- [ ] Large text scale checked (at least 1.5×, ideally 2.0×).
- [ ] Loading, empty, error and success states all render correctly. An
      unhandled empty state is the single most common gap here.
- [ ] Icon-only controls have semantic labels; touch targets are at least 48dp.
- [ ] The screen's geometry contract identifies its content gutters, alignment
      groups, relative widths/heights and important baselines. Every material
      relationship is asserted by a widget test that measures the production
      tree with `getRect` — not by looking at a golden. A container can be
      full-width while its children are not (`Wrap` and bare `Row` size children
      to their intrinsic width), and that defect is invisible to the analyzer,
      the guard, the colour audit and to a golden that was first recorded while
      wrong. See the Responsive section of `flutter-design-system` and
      `test/features/card/presentation/card_import_alignment_test.dart`.
      A screen MAY additionally opt its declared surface group into
      `SurfaceColumnRule`; this is never global because nested and asymmetric
      card groups can be intentional. The widget test remains the authority for
      headings, fields, exact gutters, gaps and baselines.
- [ ] A new or updated golden was compared state-by-state with the actual
      concept or canonical reference. The review records approved differences;
      regenerating a baseline and reviewing it in isolation is not visual
      parity evidence.
- [ ] No user-visible string outside the ARB files.
- [ ] Registered in the Widgetbook catalog (`widgetbook/`): a new shared
      component gets a knob-driven playground; a new screen gets a use-case
      mounting it with its domain contract faked, states reachable via knobs.
      The catalog is where a human inspects the UI under both themes, text
      scales and viewports without hunting through the app — a screen missing
      from it is invisible to that review.

## Paperwork
- [ ] `docs/wbs.md` updated in this commit.
- [ ] Any doc the change invalidates (data model, API spec, design system) updated
      in this commit too.
- [ ] Code reviewed.
- [ ] CI green.

## Running the mechanical checks

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

The script covers format, analyze, tests and layer boundaries. Everything under
Scope, UI and Paperwork needs a human to look — those are also where the real
defects hide, so do not let a green script stand in for that review.
