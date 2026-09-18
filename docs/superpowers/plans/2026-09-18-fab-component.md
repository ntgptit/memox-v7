# Fab component — v3 geometry pass

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `MxFab` / `buildFloatingActionButtonTheme` in line with the MemoX v3 Fab contract — a fixed 52×52 square icon-only FAB with a 20dp glyph, the house `radius-lg` corner (already correct), the already-correct `primary`/`onPrimary` fill (M100.100), and a visible keyboard-focus ring.

**Architecture:** `MxFab` (`lib/shared/widgets/mx_fab.dart`) is the only door to `FloatingActionButton` in `lib/features/`; `buildFloatingActionButtonTheme` (`lib/core/theme/components/actions/app_fab_theme.dart`) supplies every visual value through `FloatingActionButtonThemeData`. This task only touches geometry (`sizeConstraints`, `iconSize`) and adds a focus ring — colours, shape and elevation are already bound correctly and are NOT touched.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, Material 3, flutter_test.

**Spec:** MemoX v3 HTML design kit · A · Chrome & navigation — Fab component contract (component handoff, not a file in this repo). Foundations (palette, type, spacing/radius/icon/elevation scales) were bound by prior milestones (M100.99–101) and are read here, never redefined.

## Global Constraints

1. **Do not touch colour, shape or elevation on the FAB.** `backgroundColor: primary`, `foregroundColor: onPrimary`, `shape: RoundedRectangleBorder(borderRadius: AppRadius.lg)`, and the four elevation fields at `AppElevation.overlay` are already correct (M100.100, M100.35) and already covered by `test/core/theme/contracts/m3_role_bindings.dart` and `component_depth_and_state_test.dart`. Leave every line of `buildFloatingActionButtonTheme` that sets those alone; only add the two new geometry fields.
2. **New sizing token, not a reuse of `AppSizing.floatingAction`.** `AppSizing.floatingAction` (56) is documented as feeding only `AppSpacing.fabScrollClearance` and is pinned by `app_sizing_test.dart:79` (`fabScrollClearance == floatingAction + lg + xxxl`) and `card_list_alignment_test.dart` / `mx_content_shell_geometry_test.dart`. Do **not** change its value or delete it. Add a **new** constant `AppSizing.fab = 52` for the FAB's own painted box, with a doc comment that says explicitly why two constants exist (56 keeps backing the existing scroll-clearance arithmetic; 52 is the v3 FAB's actual size). The scroll clearance staying 4dp more generous than the new painted size is a caller-owned (`ScreenScroll`) concern, out of this task's scope — do not touch `AppSpacing.fabScrollClearance` or its test.
3. **Glyph size reuses an existing token: `AppIconSize.mdCompact` (20).** Do not add a new icon-size constant. Wire it through `FloatingActionButtonThemeData.iconSize`, not by editing `MxFab`'s `Icon` — `FloatingActionButton` already merges an `IconTheme` sized from `floatingActionButtonTheme.iconSize` around its `child` (`floating_action_button.dart` line ~531/541), so no widget-level change is needed for size.
4. **Fixed 52×52 painted box via `sizeConstraints`, not a widget-level `SizedBox`.** `FloatingActionButtonThemeData.sizeConstraints` (a `BoxConstraints`) already exists in this Flutter SDK and is exactly the mechanism `_floatingActionButtonType == regular` resolves through. Use `BoxConstraints.tightFor(width: AppSizing.fab, height: AppSizing.fab)`.
5. **Focus ring: `onPrimary`, not `primary` — a ruling, not a typo.** The spec's plain-language state matrix says "2px primary ring, offset 2," but this app already has a tested rule for exactly this situation: a control whose own fill IS `primary` cannot use a `primary` ring (1.00:1 contrast — invisible), so `AppInteractionStates.focusIndicatorOf` exists precisely so a filled/primary-ground control draws the ring in its own foreground colour instead (see `app_button_themes.dart:259`, and the doc comment on `focusIndicatorOf` in `app_interaction_states.dart:195-209`). The FAB's ground is `primary`. Ruling: draw the ring with `AppInteractionStates.focusIndicatorOf(scheme.onPrimary)` (via `MxFocusRing`, see Task 1 step 3), the same convention the filled button already follows, not the literal "primary ring" text. Report this deviation in the task's completion note; do not silently follow the literal spec text into an invisible ring, and do not invent a third convention.
6. **No ring offset.** "Offset 2" (a gap between the shape and the ring) has no existing implementation anywhere in this app's one focus-ring mechanism (`MxFocusRing` — used by `MxCard`, `MxPressable`, `MxPillButton`, `MxBreadcrumb`, `MxActionSheet`, `MxListTile`, all flush against the shape). Do not invent an offset variant for this one component; draw the ring flush, matching every other use of `MxFocusRing`, and note the deviation in the completion report.
7. **`pressed` state matrix entry is `[INFERRED]`** (platform ripple + elevation change) — already the canonical Flutter/M3 behaviour (`InkResponse` ripple, no code needed). Do not add anything for it.
8. **House style:** guard clauses, early return, no `else` after `return`, no magic numbers, no colour literal outside the existing token files. Keep every file under 400 lines. Match each file's existing doc-comment voice and length — do not write a new house style into a 25-year-old (in repo-years) file.
9. **Tests:** TDD — write or extend the failing assertion first. Never delete, skip, or comment out an existing test. A test that pins a value this task is not authorized to change (constraint 2) and would now fail is a stop-and-report, not a relax.
10. **Verification before completion** — all must pass, and the report quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
    - then `git checkout -- design_audit/` — the suite rewrites those tracked reports.
    Do **not** run `--update-goldens` — the controller regenerates goldens on Linux/WSL after this task's review is clean.
11. **Commits:** Conventional Commits, scope `fab` or `design-system`, ending with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. Do not push, open PRs, or dispatch subagents.

---

### Task 1: Fab — fixed 52×52 geometry, 20dp glyph, primary-ground focus ring

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (add `fab` constant; amend `floatingAction`'s doc comment)
- Modify: `lib/core/theme/components/actions/app_fab_theme.dart` (add `sizeConstraints`, `iconSize`)
- Modify: `lib/shared/widgets/mx_focus_ring.dart` (add optional `color` override)
- Modify: `lib/shared/widgets/mx_fab.dart` (wrap the `FloatingActionButton` in `MxFocusRing`)
- Test: `test/core/theme/foundations/app_sizing_test.dart` (add `fab` to the 4dp-grid list)
- Test: new or extended test asserting the FAB theme resolves `sizeConstraints`/`iconSize` (a `test('$mode: ...')` block alongside the existing FAB assertions in `test/core/theme/app_theme_test.dart` is the natural home — read that file's existing FAB group first)
- Test: a widget test for `MxFab` exercising the focus ring (there is currently no `test/shared/widgets/mx_fab_test.dart` — create one; model it on `test/shared/widgets/mx_pill_button_theme_test.dart`'s or `mx_breadcrumb_focus_test.dart`'s focus-ring assertions, whichever is closer in shape)

**Interfaces:**
- Consumes: `AppSizing`, `AppIconSize.mdCompact`, `AppInteractionStates.focusIndicatorOf`, `context.colors` (`ThemeContextX`).
- Produces: `AppSizing.fab` (`52`); `MxFocusRing({..., Color? color})`; `MxFab` now wraps its `FloatingActionButton` in a focus ring.

- [ ] **Step 1: `AppSizing.fab`**

  In `lib/core/theme/foundations/app_sizing.dart`, add (near `floatingAction`):

  ```dart
  /// The v3 Fab contract's own size — the actual painted box, fixed at 52×52
  /// (never `floatingAction`, which backs `AppSpacing.fabScrollClearance`
  /// only). Two constants because they answer two different questions: this
  /// one is what the FAB *is*; `floatingAction` is what the scroll tail
  /// clears, and shrinking the FAB does not need to shrink the clearance.
  static const double fab = 52;
  ```

  Amend `floatingAction`'s doc comment (the "never to size a FAB" line) to say
  it no longer needs to track the FAB's own size — `AppSizing.fab` does that —
  and this constant's only remaining job is feeding `fabScrollClearance`.

  In `test/core/theme/foundations/app_sizing_test.dart`, add `('fab', AppSizing.fab)` to the 4dp-grid list (the `test('every control dimension sits on the 4dp grid', ...)` block).

- [ ] **Step 2: theme geometry**

  In `lib/core/theme/components/actions/app_fab_theme.dart`, add two fields to the returned `FloatingActionButtonThemeData` (import `AppSizing` and `AppIconSize`):

  ```dart
  sizeConstraints: BoxConstraints.tightFor(
    width: AppSizing.fab,
    height: AppSizing.fab,
  ),
  iconSize: AppIconSize.mdCompact,
  ```

  Add a doc note (matching the file's existing per-field commentary style) explaining the 52 fixed size and the 20dp glyph are the v3 Fab contract's own dimension table, distinct from `_FABDefaultsM3`'s 56/24.

  Add a test alongside the existing FAB assertions in `test/core/theme/app_theme_test.dart` (both light and dark) asserting `fab.sizeConstraints == BoxConstraints.tightFor(width: AppSizing.fab, height: AppSizing.fab)` and `fab.iconSize == AppIconSize.mdCompact`.

- [ ] **Step 3: `MxFocusRing` colour override**

  In `lib/shared/widgets/mx_focus_ring.dart`, add an optional `Color? color` field to the constructor. In `build()`, when `_showsRing`:
  - if `color` is non-null, use `AppInteractionStates.focusIndicatorOf(color!)`
  - else keep the existing `AppInteractionStates.focusIndicator(context.colors)`

  Every current call site (`MxCard` — wait, `MxCard` calls `AppInteractionStates.focusIndicator` directly, not `MxFocusRing`; the actual `MxFocusRing` callers are `MxActionSheet`, `MxBreadcrumb`, `MxListTile`, `MxPillButton`, `MxPressable`) passes no `color`, so this must be fully backward compatible — verify by reading each call site, but do not change any of them.

  Add one short line to the class doc comment noting the override exists for a control whose own ground is not a surface (mirrors `focusIndicatorOf`'s own doc comment) — do not repeat that doc comment's full rationale, one sentence pointing to it is enough.

- [ ] **Step 4: wire it into `MxFab`**

  In `lib/shared/widgets/mx_fab.dart`, wrap the `FloatingActionButton` in `MxFocusRing`:

  ```dart
  return MxFocusRing(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    color: context.colors.onPrimary,
    child: FloatingActionButton(
      onPressed: onPressed,
      tooltip: label,
      child: Icon(icon, semanticLabel: label),
    ),
  );
  ```

  Import `AppRadius` (`../../core/theme/foundations/app_radius.dart`) and the `ThemeContextX` extension (`../../core/theme/extensions/theme_context_extension.dart`). Add one short doc-comment line on the class explaining the ring reads `onPrimary` rather than `primary` because the FAB's own fill is `primary` — point to `AppInteractionStates.focusIndicatorOf`'s doc comment rather than re-deriving the contrast argument.

- [ ] **Step 5: widget test for the ring**

  Create `test/shared/widgets/mx_fab_test.dart`. At minimum: pump an `MxFab` inside a themed host (reuse this test directory's existing golden/pump helpers — read `golden_hosts.dart`/`golden_pump.dart` first rather than hand-rolling a `MaterialApp`), request keyboard focus on it (`FocusHighlightMode.traditional` — copy the pattern from `mx_breadcrumb_focus_test.dart` or `mx_pill_button_theme_test.dart`, whichever already exercises `MxFocusRing` with a real `Tab`/`FocusNode.requestFocus()`), and assert the painted `Border` on the wrapping `DecoratedBox` uses `scheme.onPrimary` at `AppStroke.focus` width — not `scheme.primary`.

  Also assert (host-level, no golden needed) that the rendered `FloatingActionButton`'s resolved size is 52×52 and its icon's effective size is 20 — `tester.getSize(find.byType(FloatingActionButton))` and reading the merged `IconTheme` are both acceptable; pick whichever this test file's neighbours already do for other components.

- [ ] **Step 6: verify**

  Run the Global Constraints §10 commands. Quote every result line in the report. If `flutter test` reveals a golden that would move (a screen golden showing a FAB, e.g. under `card_list_screen` / `deck_list_screen`), do **not** regenerate it — report which golden file(s) failed and why (expected: pixel diff from the new 52×52 size / 20dp glyph), and leave them failing. The controller regenerates goldens on Linux/WSL after this task's review is clean, in the same turn as republishing the screen gallery.

**Report contract:** DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED, the commits made, the one-line test summary (host suite pass/fail counts, and which golden files are known-failing and why), and any concern — in particular, confirm explicitly whether any test other than the known-failing goldens went red.
