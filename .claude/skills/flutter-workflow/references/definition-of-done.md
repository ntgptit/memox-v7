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
- [ ] `dart format` produces no changes.
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
