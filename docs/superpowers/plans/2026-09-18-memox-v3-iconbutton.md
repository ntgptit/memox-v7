# MemoX v3 IconButton Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the plain-style `MxIconButton` (the app's bare-icon control — search, close, back, kebab, chevron actions) in line with the MemoX v3 IconButton component handoff: a 36×36 circular painted ink box, centred inside an unchanged 48×48 minimum touch target that is never grown to meet the circle, with a glyph fixed at 20 (v3's "Compact control" icon step, `AppIconSize.mdCompact`) instead of today's 24 (`AppIconSize.md`).

**Architecture:** The Foundations (#569/M100.97, `docs/superpowers/plans/2026-09-17-memox-v3-foundations.md`) and theme-binding (`docs/superpowers/plans/2026-09-18-memox-v3-theme-binding.md`) prerequisites are both merged, and the M100.99–101 "v3 component pass" already migrated every `IconButton` colour role (`app_icon_button_theme.dart`'s foreground is `onSurface`, done at M100.101). **Colour is out of scope here — geometry only.** This is the first v3 component-spec task in this repo to require real code changes rather than a docs-only reconciliation (compare the FAB/TonalButton/FilledButton/TextButton/Avatar "component spec" commits, all `docs(design-system):` because the shipped widget already matched).

The outlined `IconButton` variant (`buildOutlinedIconButtonStyle`) already implements the exact technique this task needs — a drawn box smaller than the touch target, held there by `tapTargetSize: MaterialTapTargetSize.padded` — for its own "40 drawn, 48 hit" contract. This task applies the same technique to the *plain* variant at a different, plain-specific size (36, not 40), and gives that size its own named constant because it is a distinct COMPONENT dimension, not a reuse of `AppSizing.controlCompact`.

**Spec:** The IconButton design-spec handoff (MemoX v3 HTML design kit · B · Actions & controls, delivered as this plan's originating prompt, 2026-09-18). Key contract points:
- ink box (painted circle): FIXED 36, component-owned — `--memox-size-icon-btn` in the kit, no existing Dart symbol.
- glyph: FIXED 20 — the kit's "icon sm" step, which per `docs/design-system/v3-foundations.md` §3 (Icon ladder) is Dart's `AppIconSize.mdCompact`, **not** `AppIconSize.sm` (16). Do not use `AppIconSize.sm`.
- radius: FIXED full (fully round / pill), not the current `AppRadius.md` squircle.
- touch area: MINIMUM 48 (`AppSizing.touchTarget`), centred on the 36 ink box, never inflating the circle.
- fill: FIXED transparent, `onSurface` glyph — already correct (M100.101), do not touch.
- state overlay (pressed): `op-press`, bounded by the 36 circle — already resolved via `AppInteractionStates.iconOverlay`, colour-only, no shape coupling (confirmed by inspection — do not touch).
- focus ring: `primary` border — already resolved via `AppInteractionStates.focusIndicator`, colour-only (do not touch).
- disabled: global `op-disabled` — already resolved via `disabledForegroundColor: semantic.onDisabled` (do not touch).
- hover (web-only, Android has no hover) and pressed ripple are marked `[INFERRED]` in the source spec — implement only where they already match repo convention; the repo already has a working ripple/overlay mechanism, so no new state work is needed here.

**Tech Stack:** Flutter (stable) / Dart, Material 3, flutter_test, the repo's Python guard (`code-verification-guard-v2`).

## Global Constraints

1. **Colour is frozen.** `onSurface` foreground, `disabledForegroundColor: semantic.onDisabled`, `AppInteractionStates.iconOverlay`/`focusIndicator` stay exactly as they are. This task touches geometry only: size, shape, `tapTargetSize`, and the glyph-size constant passed by `MxIconButton`.
2. **The outlined `IconButton` style (`buildOutlinedIconButtonStyle`, `MxIconButtonShape.outlined`) is out of scope.** It already has its own correct "40 drawn, 48 hit" contract for a different visual (a hairline circle on the page). Do not resize or reshape it, and do not merge its constant with the new plain-style one — they are two different component-owned values (40 vs 36) for two different variants.
3. **`isCompact` stays.** It exists for exactly one caller, `MxSessionTopBar`'s close button, sharing a row with a progress track that needs the width — a caller-owned layout constraint, not something this component spec touches. Its `BoxConstraints.tightFor(48,48)` + `padding: EdgeInsets.zero` mechanism does not change. Its glyph size **does** change as a side effect of Rule 4 below — see Task 1, Step 3.
4. **The glyph is `AppIconSize.mdCompact` (20) unconditionally**, for both the default and `isCompact` paths — the v3 spec fixes the IconButton glyph at 20 with no compact/non-compact distinction. Do not introduce a new size constant for this; reuse the existing `AppIconSize.mdCompact`.
5. **New `AppSizing` constant.** Add one new constant for the 36 painted circle (do not reuse `AppSizing.controlCompact`, which is 40 and belongs to a different component/variant). Give it a doc comment in the same style as its neighbours (see the file's existing entries) citing this component spec as its source. It must be added to `test/core/theme/foundations/app_sizing_test.dart`'s 4dp-grid enumeration (or the check does not see it) and given an ordering assertion analogous to the existing `controlCompact < touchTarget` one.
6. **This is a v3 redesign task, not a doc-freeze reconciliation** — per the project's redesign-supersedes-v1-freeze decision (2026-09-13), a real geometry mismatch between shipped code and the v3 handoff is fixed in code, not merely recorded. Do not stop at "document the gap."
7. **House style:** guard clauses and early return, no `else` after `return`, no magic numbers (name them), no colour literal outside the token files listed in `test/visual_audit/color_source_rules_test.dart` (not touched by this task), keep every file you touch under 400 lines.
8. **Tests:** TDD — write or move the assertion first and watch it fail. Never delete, skip, `exclude`, or comment out a test. A test that fails because this task deliberately moved a pinned value (e.g. `iconButtonTheme` `minimumSize`) is re-pinned with a one-line reason pointing at this task; do not relax a structural assertion (e.g. the 4dp-grid check, the `androidTapTargetGuideline` accessibility check) — those must keep passing as-is.
9. **Verification before every commit** — all must pass, and the report quotes each result line:
   - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
   - `flutter analyze --no-fatal-infos` → `No issues found!` (read the summary line, not a grep — a scoped-clean analyze can still hide a repo-wide error)
   - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
   - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
   - then `git checkout -- design_audit/` if it was rewritten — some suites rewrite those tracked reports as a side effect.
   - **Never run `--update-goldens` yourself.** Goldens are authored on Linux only; the controller regenerates and republishes them after this task's review is clean.
10. **Commits:** Conventional Commits, scope `design-system`, ending with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. Do not push, open PRs, or dispatch subagents.
11. **Do not touch:** `AppInteractionStates` (colour-only, no shape coupling — confirmed by inspection), `buildOutlinedIconButtonStyle`, any of the 23 non-`isCompact` `MxIconButton(` call sites (they take the theme's geometry automatically — no call-site edits needed), `docs/design-system/theme-architecture.md`'s `COMPONENT_MIGRATION_PENDING` table (it is colour-only and IconButton's colour row is already closed there).

---

### Task 1: Plain-style IconButton geometry — 36 drawn, 48 hit, full radius, 20 glyph

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (new constant)
- Modify: `lib/core/theme/components/actions/app_icon_button_theme.dart` (`buildIconButtonTheme`)
- Modify: `lib/shared/widgets/mx_icon_button.dart` (glyph size, doc comments)
- Modify: `test/core/theme/foundations/app_sizing_test.dart` (grid list, ordering, re-pinned `minimumSize`)
- Modify: `test/shared/widgets/mx_tonal_and_outlined_test.dart` (new "plain style" geometry group, reusing the existing drawn-vs-hit measurement technique already in this file for the outlined style)
- Modify: `docs/wbs.md` (new WBS entry recording this task; pick the next `M100.x` number and re-check `git fetch origin --prune` immediately before committing, in case a parallel PR already claimed it)

**Interfaces:**
- Consumes: `AppSizing.touchTarget` (48, unchanged), `AppIconSize.mdCompact` (20, unchanged), `AppRadius.pill` (unchanged), `AppInteractionStates.iconOverlay`/`focusIndicator` (unchanged, colour-only).
- Produces: one new `AppSizing` constant for the 36 painted circle (name it to fit the file's existing style, e.g. `AppSizing.iconButtonInk` — pick a name and use it consistently across all files in this task).

- [ ] **Step 1: Write the failing tests first**

  In `test/core/theme/foundations/app_sizing_test.dart`:
  - Add the new constant to the 4dp-grid enumeration alongside `touchTarget, controlCompact, floatingAction, buttonMinWidth, statusDot`.
  - Add an ordering assertion `expect(AppSizing.<newConstant>, lessThan(AppSizing.touchTarget))`, mirroring the existing `controlCompact < touchTarget` assertion.
  - Update the existing `iconButtonTheme.style.minimumSize` pin (both light and dark) from `Size.square(48)` (i.e. `Size.square(AppSizing.touchTarget)`) to `Size.square(AppSizing.<newConstant>)` — this assertion must fail against current code before Step 2, and pass after.

  In `test/shared/widgets/mx_tonal_and_outlined_test.dart`, add a new group next to the existing outlined-style "draws 40 and still hands a finger 48" test, reusing its exact measurement technique (`find.descendant(of: find.byType(IconButton), matching: find.byType(Material)).first` for the drawn box; `find.byType(IconButton)` for the hit box) to assert, for the **plain** style (`MxIconButtonShape.plain`, the default):
  - the drawn box is `Size.square(AppSizing.<newConstant>)` (36),
  - the hit box is at least `Size.square(AppSizing.touchTarget)` (48),
  - the shape is fully round (assert via the rendered `Material`'s `shape` being a `RoundedRectangleBorder` whose `borderRadius` resolves to `AppRadius.pill` at the drawn box's own corner, or an equivalent circularity check consistent with how this file already asserts the outlined variant's shape — match the file's existing assertion style rather than inventing a new one).
  - Also add or extend an assertion that a plain, non-`isCompact` `MxIconButton`'s `Icon.size` is `AppIconSize.mdCompact` (20), not `AppIconSize.md` (24).

  Run `flutter test --exclude-tags golden test/core/theme/foundations/app_sizing_test.dart test/shared/widgets/mx_tonal_and_outlined_test.dart` and confirm the new/changed assertions fail against unmodified code (the `minimumSize`/drawn-box/icon-size ones) before proceeding.

- [ ] **Step 2: Add the new `AppSizing` constant**

  In `lib/core/theme/foundations/app_sizing.dart`, add the 36 constant near `controlCompact`/`controlDense`, following the file's existing doc-comment convention (what caller motivates it, why it is not on the spacing/radius/icon ladder, why it is distinct from `controlCompact`'s 40). Cite the MemoX v3 IconButton component spec (2026-09-18) as its source, the same way `controlCompact`'s doc comment cites its own originating decision.

- [ ] **Step 3: Fix `buildIconButtonTheme`'s plain-style geometry**

  In `lib/core/theme/components/actions/app_icon_button_theme.dart`:
  - Change `minimumSize: const Size.square(AppSizing.touchTarget)` to `minimumSize: const Size.square(AppSizing.<newConstant>)`.
  - Add `tapTargetSize: MaterialTapTargetSize.padded` to the same `IconButton.styleFrom(...)` call (or the `.copyWith(...)` block, whichever the API accepts) — this is what holds the 48 hit target around the smaller drawn box, exactly as `buildOutlinedIconButtonStyle` already does.
  - Change `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))` to `BorderRadius.circular(AppRadius.pill)` — fully round, matching the outlined variant's shape token (reuse `AppRadius.pill`; do not invent a new radius constant).
  - Update the file's doc comments to describe the new "36 drawn, 48 hit" contract in the same voice as the existing "40 drawn, 48 hit" explanation on `buildOutlinedIconButtonStyle`, and to drop any language that still says the plain style takes "the whole 48" (it no longer does).
  - Leave `foregroundColor`, `disabledForegroundColor`, `overlayColor`, and the focused `side` untouched.

- [ ] **Step 4: Fix the glyph size in `MxIconButton`**

  In `lib/shared/widgets/mx_icon_button.dart`:
  - Change `size: isCompact ? AppIconSize.mdCompact : AppIconSize.md` to an unconditional `size: AppIconSize.mdCompact` — the v3 spec fixes the glyph at 20 regardless of `isCompact`.
  - Update the class doc comment ("Size comes from `AppIconSize` and the 48×48 minimum from `IconButtonThemeData`...") and the `isCompact` field doc comment (which currently says isCompact "Drops the glyph to `AppIconSize.mdCompact`") to reflect that the glyph is now always `mdCompact`, and that `isCompact`'s remaining and only job is the tight 48×48 box constraint for the one row-cramped caller (`MxSessionTopBar`) — do not change that constraint logic itself.
  - Do not touch `MxIconButtonTone`, `MxIconButtonShape`, `tooltip`, or the `onPressed`/disabled handling.

- [ ] **Step 5: Run the failing tests from Step 1 and confirm they pass; run the full verification list from Global Constraints #9.**

- [ ] **Step 6: Update `docs/wbs.md`**

  Add a new `M100.x` entry (fetch `origin/main` first and pick a number not already claimed by a parallel PR) recording: scope (the two theme/widget files + the new `AppSizing` constant), the before/after geometry (48-square/`AppRadius.md`/24-glyph → 36-circle/`AppRadius.pill`/20-glyph, 48 hit unchanged), dependency on M100.101 (colour already done), and that colour is unchanged. Mark golden regeneration as the controller's follow-up (not part of this task's own acceptance, since goldens cannot be produced on this Windows worktree).

- [ ] **Step 7: Commit.**

**Acceptance criteria:**
- [ ] `iconButtonTheme` (plain style) draws a 36×36 fully round box and hands the finger a 48×48 hit target — proven by a test, not by inspection.
- [ ] The outlined style's own 40/48 contract is byte-for-byte unchanged.
- [ ] A plain (non-`isCompact`) `MxIconButton`'s glyph renders at `AppIconSize.mdCompact` (20); an `isCompact` one still renders at 20 too, and its box is still exactly 48×48.
- [ ] `AppSizing`'s new constant is on the 4dp-grid test and has an ordering assertion against `touchTarget`.
- [ ] No colour, overlay, focus-ring, or disabled-state binding changed.
- [ ] `dart format`, `flutter analyze --no-fatal-infos`, `flutter test --exclude-tags golden`, and the Python guard all pass, quoted in the report.
- [ ] `docs/wbs.md` carries the new entry.
