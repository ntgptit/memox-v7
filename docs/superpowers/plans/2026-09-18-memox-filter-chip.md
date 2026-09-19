# MxFilterChip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the shared `MxFilterChip` widget the v3 FilterChip handoff specifies — a one-of-N selectable pill, painted at a fixed 28dp, with `primary`/`onPrimary` on selection and an optional trailing count — and land it as the first real caller of the `border-ghost` role the theme docs have been reserving for it.

**Architecture decision (ruling, made before Task 1):** This is a **new widget**, not an extension of `MxPillButton`.
1. `MxPillButton` wraps `ChoiceChip`/`RawChip`. `app_chip_theme.dart:281-286` documents that `RawChip` clamps its painted height to a 34dp floor ("measured by dropping this value to a deliberate 3 and watching nothing move") — below the spec's FIXED-28 target, so a `ChoiceChip`-backed widget structurally cannot meet this contract.
2. `docs/design-system/theme-architecture.md:342-389` explicitly earmarks `primary`/`onPrimary` (selected fill+label), `onSurface` (unselected label) and `border-ghost` (border) for `FilterChip`, and states in so many words that enforcing them on the shared `ChipThemeData` today "would silently change `ChoiceChip`, which v3 handles separately" — i.e. these roles are reserved for a distinct component, by design.
Building a separate `MxFilterChip` is therefore not a parallel component for the sake of it — it is the component these two facts already point to.

**Selection semantics ruling:** one-of-N / mutually exclusive, matching `MxPillButton`'s model. The spec's own "Caller-owned" section says the caller owns "which **one** is selected" (singular).

**Architecture:** `lib/shared/widgets/mx_filter_chip.dart` — a custom `Material`+`InkWell` pill (no `ChoiceChip`), composed the same way `MxPillButton` is: a tap-target wrapper restoring the 48dp minimum around the painted shape, `MxFocusRing` for the keyboard focus ring, hand-rolled `Semantics` for the button/selected/enabled state (no `RawChip` to supply it for free this time).

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, Material 3, flutter_test, `code-verification-guard-v2`.

**Spec:** the FilterChip component contract supplied in this session (dimension table, theme consumption table, state matrix, long-content rule). No separate spec file exists; this plan **is** the spec's implementation record.

## Global Constraints

1. **Do not touch `MxPillButton`, `app_chip_theme.dart`, or `ChoiceChip` anywhere.** They are a different, already-shipped component family; this plan adds a sibling, not a migration.
2. **Reuse, do not re-derive, existing tokens:**
   - `AppRadius.pill` (999) for the shape.
   - `AppSpacing.sm` (8) for horizontal padding, `AppSpacing.xs` (4) for the icon↔label and label↔count gaps.
   - `AppIconSize.sm` (16) for the leading glyph / tick.
   - `AppSizing.touchTarget` (48) for the minimum tap target.
   - `TextTheme.labelMedium` (12/600, tracking 0.72 — `app_typography.dart:281-287`) for the label, verbatim, with no local re-styling of size/weight/tracking.
   - `AppStateOpacity.pressed` (0.12), `AppStateOpacity.disabled` (0.38 — the *whole-control* `op-disabled` rule, `app_interaction_states.dart:93-101`), `AppInteractionStates.focusIndicator` / `MxFocusRing` for focus.
   - `context.colors` (`ColorScheme`) for `primary`, `onPrimary`, `onSurface`, `surfaceContainerLowest` — never construct a `ColorScheme` role locally.
3. **New tokens this task adds, and only these:**
   - `AppSizing.chipHeight = 28` in `lib/core/theme/foundations/app_sizing.dart`, doc-commented to `docs/design-system/v3-foundations.md:195-198` ("v3's own component table settles on a fixed chip size of 28 — that belongs to a later Chip spec") and to this component.
   - `AppBorderColors.borderGhostLight = Color(0xFFE7E9FE)` / `borderGhostDark = Color(0xFF262E5A)` in `lib/core/theme/foundations/app_border_colors.dart`, doc-commented as `primary` at 14% (light) / 16% (dark) over `surfaceContainerLowest` — the same derivation `borderAccentLight`/`borderAccentDark` already use in that file, just at a lower alpha. These are the exact literals `docs/design-system/v3-foundations.md:270` records (`rgba(82,101,245,.14)` / `rgba(139,154,255,.16)`, and `82,101,245` / `139,154,255` are `AppColors.primaryLight`/`primaryDark` verbatim).
   - `AppSemanticColors.borderGhost` — one new field, wired through the constructor, `.light()`, `.dark()`, `copyWith`, `lerp`, following the exact shape of the existing `borderAccent` field in that file (declaration, doc comment, all four call sites).
   - `MxFilterChip` itself.
   No other theme file changes. If a role this component needs turns out to be missing in a way not listed here, STOP and report it — do not invent a value.
4. **Count is numeric.** `count` is `final int?`, rendered via `count.toString()` after the label with an `AppSpacing.xs` gap, in `TextTheme.labelMedium` re-weighted to `FontWeight.w700` via `AppTypography.withWeight` plus `fontFeatures: const [FontFeature.tabularFigures()]`. `null` renders no count and no gap.
5. **Colour/opacity ruling for label vs. count** (the spec's "label + count · selected" row is read as: label full-strength, count dimmed — consistent with the unselected row's own asymmetry and its own note "the count sits lighter"):
   - unselected: label `onSurface` full strength; count `onSurface` at 0.6 opacity.
   - selected: label `onPrimary` full strength; count `onPrimary` at 0.75 opacity.
6. **Pressed-overlay ruling.** The spec states one `op-press` row without splitting by selection state, but a literal single `primary`-tint overlay would be nearly invisible painted on top of the selected chip's own `primary` fill. Follow this repo's own established fill-vs-outline convention instead (`app_fab_theme.dart`'s filled treatment vs. `AppInteractionStates.controlOverlay`'s outlined treatment): pressed overlay tints with `onPrimary` when selected, `primary` when unselected, both at `AppStateOpacity.pressed`. Implement via `InkWell.overlayColor` (`WidgetStateProperty`, pressed state only — no hover/focus wash, those are not requested here).
7. **Disabled ruling.** Use the v3 **global** `op-disabled` rule literally: `Opacity(opacity: AppStateOpacity.disabled)` wrapped around the whole painted pill (inside the tap target, outside the focus ring — the ring itself should not dim). This is deliberately **not** `MxPillButton`'s legacy `disabledSurfaceTint` mechanism: that mechanism exists because of `ChoiceChip`/`RawChip` constraints this widget does not have, and the spec names `op-disabled` — the global rule — directly for this component.
8. **Tap-target duplication is accepted, not refactored away.** `MxPillButton`'s `_TapTarget`/`_RenderTapTarget` (`mx_pill_button.dart:227-331`) does exactly what this component needs (48×48 redirecting hit box around a smaller painted shape). Copy it into `mx_filter_chip.dart` as a private pair rather than extracting a shared file — extracting is a refactor of `MxPillButton` too, which is out of this task's stated scope ("no drive-by refactors"). Note this in the final report as a candidate for a follow-up extraction task.
9. **Long content:** no `Flexible`, no `maxLines`, no `TextOverflow.ellipsis` anywhere in this widget — the label and count take their intrinsic width always. The caller is documented as owning horizontal scroll; this widget must never shrink or truncate its own content to fit a constraint.
10. **Semantics:** `MergeSemantics > Semantics(button: true, selected: isSelected, enabled: onPressed != null, label: semanticLabel ?? label, onTap: onPressed) > ExcludeSemantics > _TapTarget > MxFocusRing > Material/InkWell`. `ExcludeSemantics` around the visual `Row` stops the label `Text` (and the count) from being announced a second time — the same double-announcement trap `MxPillButton`'s own doc comment describes avoiding.
11. **House style:** guard clauses, early return, no `else` after `return`, no magic numbers (name them as constants next to the class, same as `mx_pill_button.dart`'s `AppSpacing.xs`/`AppIconSize.sm` usage), no colour literal outside `AppBorderColors`/`AppSemanticColors`, no user-visible string (there are none — `label`/`semanticLabel` arrive pre-localized from the caller, same contract as `MxPillButton`). Keep every file under 400 lines.
12. **Tests:** TDD — write the failing test, watch it fail, then implement. Never delete, skip or comment out a test.
13. **Verification before every commit** — all must pass, and the report quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
    - `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` (this task creates files)
    - then `git checkout -- design_audit/` — the suite rewrites those tracked reports.
    **Never run `--update-goldens`** — goldens are authored on Linux; the controller regenerates them after both tasks land.
14. **Commits:** Conventional Commits, scope `design-system`, ending with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. Do not push, open PRs, or dispatch subagents.

---

### Task 1: `MxFilterChip` widget, its new tokens, and non-golden tests

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (add `chipHeight = 28`)
- Modify: `lib/core/theme/foundations/app_border_colors.dart` (add `borderGhostLight`/`borderGhostDark`)
- Modify: `lib/core/theme/foundations/app_semantic_colors.dart` (add `borderGhost` field — constructor, `.light()`, `.dark()`, `copyWith`, `lerp`)
- Modify: `test/core/theme/foundations/app_semantic_colors_test.dart` — if it has a hardcoded field-name list backing a `copyWith`/`lerp` completeness assertion (check for one, the theme-binding plan's Task 1 hit exactly this), add `borderGhost` to it. If no such list exists, skip.
- Create: `lib/shared/widgets/mx_filter_chip.dart` (the `MxFilterChip` widget)
- Create: `test/shared/widgets/mx_filter_chip_test.dart` (interaction, semantics, layout/overflow, disabled, selection tick, count rendering — mirror the aspects `mx_pill_button_test.dart` covers, for this widget)
- Create: `test/shared/widgets/mx_filter_chip_focus_test.dart` (focus ring rect equals the painted 28-tall shape's rect, not the 48dp target — mirror `mx_pill_button_focus_test.dart`)

**Interfaces:**
- Consumes: `context.colors` (`primary`, `onPrimary`, `onSurface`, `surfaceContainerLowest`), `context.semanticColors.borderGhost`, `Theme.of(context).textTheme.labelMedium`, `AppRadius.pill`, `AppSpacing.{xs,sm}`, `AppIconSize.sm`, `AppSizing.{touchTarget,chipHeight}`, `AppStateOpacity.{pressed,disabled}`, `MxFocusRing`, `AppTypography.withWeight`.
- Produces: `MxFilterChip({required label, required isSelected, required onPressed, int? count, IconData? icon, String? semanticLabel})`; `AppSizing.chipHeight`; `AppBorderColors.borderGhostLight/Dark`; `AppSemanticColors.borderGhost`.

- [ ] **Step 1: Write the failing tests**

  In `test/shared/widgets/mx_filter_chip_test.dart`, cover at minimum:
  - tapping calls `onPressed` when enabled; does nothing and paints at `AppStateOpacity.disabled` when `onPressed` is null.
  - `Semantics` reports `button: true`, `selected: isSelected`, `enabled: onPressed != null`, and the label text (or `semanticLabel` when supplied) exactly once (no double announcement from the inner `Text`).
  - the leading slot shows the caller's `icon` when unselected and `Icons.check` when selected, without the pill's outer width changing between the two (assert the rendered width is equal both ways with the same label/count).
  - `count` renders after the label with a visible numeral (e.g. `count: 3` produces `Text` containing `'3'`); `count: null` renders no such text and no extra gap.
  - the tap target's semantics rect is `AppSizing.touchTarget` square (or larger) even though the painted pill is 28dp tall — same assertion style as `mx_pill_button_test.dart`'s touch-target test.
  - long label + large count does not wrap, ellipsize, or shrink — pump inside an unconstrained-width ancestor (e.g. wrapped in a horizontally scrolling `Row`/`SingleChildScrollView`, matching the caller contract) and assert no overflow error and the full text is present.

  In `test/shared/widgets/mx_filter_chip_focus_test.dart`, pin that the `MxFocusRing`'s rect matches the painted 28dp shape, not the 48dp tap target — same structure as `mx_pill_button_focus_test.dart`.

- [ ] **Step 2: Run it and watch it fail**

  `flutter test test/shared/widgets/mx_filter_chip_test.dart test/shared/widgets/mx_filter_chip_focus_test.dart -r failures-only`
  Expected: compile FAIL — `MxFilterChip` does not exist yet.

- [ ] **Step 3: Add the two new foundation tokens**

  `app_sizing.dart` — beside `controlDense`:
  ```dart
  /// A filter chip's fixed painted height (v3 component table —
  /// docs/design-system/v3-foundations.md:195-198 — "chip cỡ cố định 28").
  /// Below RawChip's own painted floor, which is why `MxFilterChip` does not
  /// wrap `ChoiceChip`.
  static const double chipHeight = 28;
  ```

  `app_border_colors.dart` — beside `borderAccentLight`/`borderAccentDark`:
  ```dart
  /// The hairline a `MxFilterChip` wears unselected — v3 `border-ghost`:
  /// `primary` at 14% (light) / 16% (dark) over `surfaceContainerLowest`,
  /// the same derivation as [borderAccentLight] at a lower alpha
  /// (docs/design-system/v3-foundations.md:270).
  static const Color borderGhostLight = Color(0xFFE7E9FE);
  static const Color borderGhostDark = Color(0xFF262E5A);
  ```

- [ ] **Step 4: Wire `AppSemanticColors.borderGhost`**

  Add `required this.borderGhost` to the constructor, `final Color borderGhost;` with a doc comment pointing at `AppBorderColors.borderGhostLight`, `borderGhost = AppBorderColors.borderGhostLight` / `...Dark` in `.light()`/`.dark()`, a `Color? borderGhost` parameter plus `borderGhost: borderGhost ?? this.borderGhost` in `copyWith`, and `borderGhost: Color.lerp(borderGhost, other.borderGhost, t)!` in `lerp` — same shape as the existing `borderAccent` field, placed next to it.

- [ ] **Step 5: Implement `MxFilterChip`**

  `lib/shared/widgets/mx_filter_chip.dart`. Composition, outside in:

  ```
  MergeSemantics
    Semantics(button: true, selected: isSelected, enabled: onPressed != null,
              label: semanticLabel ?? label, onTap: onPressed)
      ExcludeSemantics
        _TapTarget (48×48 floor, copied from mx_pill_button.dart)
          MxFocusRing(borderRadius: BorderRadius.circular(AppRadius.pill))
            Opacity(opacity: onPressed == null ? AppStateOpacity.disabled : 1.0)
              Material(
                color: isSelected ? context.colors.primary : context.colors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: isSelected ? BorderSide.none : BorderSide(color: context.semanticColors.borderGhost),
                ),
                child: InkWell(
                  onTap: onPressed,
                  customBorder: <same RoundedRectangleBorder>,
                  overlayColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.pressed)
                          ? (isSelected ? context.colors.onPrimary : context.colors.primary)
                              .withValues(alpha: AppStateOpacity.pressed)
                          : null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: SizedBox(
                      height: AppSizing.chipHeight,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [ ...leading glyph slot..., label Text, if (count != null) ...gap + count Text... ]),
                    ),
                  ),
                ),
              )
  ```

  Notes for the implementer:
  - The leading glyph slot is **always laid out** (a fixed `AppIconSize.sm` square, painting nothing when there is no icon and no selection) — same "no reflow on toggle" reasoning `mx_pill_button.dart:206-215` documents; copy that pattern.
  - Label style: `Theme.of(context).textTheme.labelMedium!.copyWith(color: isSelected ? onPrimaryColor : onSurfaceColor)` — no size/weight/tracking override, per Global Constraint 2.
  - Count style: the same `labelMedium`, re-weighted via `AppTypography.withWeight(style, FontWeight.w700)`, `fontFeatures: const [FontFeature.tabularFigures()]`, colour = the selected/unselected ink at 0.75/0.6 opacity per Global Constraint 5.
  - `Opacity` for disabled wraps the `Material` (the painted pill), not the `_TapTarget`/`MxFocusRing` layers — a disabled control should still be focusable-looking if it somehow gets focus, and the tap target itself is layout, not paint.
  - The `_TapTarget`/`_RenderTapTarget` pair is a verbatim copy of `mx_pill_button.dart:227-331` (Global Constraint 8) — copy, do not import across files.

- [ ] **Step 6: Run the target tests, then the full gate** (Global Constraint 13, including `check_architecture.sh`).

- [ ] **Step 7: Commit**

  ```bash
  git add lib/core/theme/foundations/app_sizing.dart lib/core/theme/foundations/app_border_colors.dart lib/core/theme/foundations/app_semantic_colors.dart lib/shared/widgets/mx_filter_chip.dart test/shared/widgets/mx_filter_chip_test.dart test/shared/widgets/mx_filter_chip_focus_test.dart test/core/theme/foundations/app_semantic_colors_test.dart
  git commit -m "feat(design-system): MxFilterChip — v3's first border-ghost caller (M100.102)

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

### Task 2: Widgetbook registration, golden specimens, docs and WBS

**Files:**
- Modify: `widgetbook/lib/components/control_components.dart` (add `filterChipComponent()`, wire it into whatever list registers `pillButtonComponent()`)
- Modify: `test/shared/widgets/selection_specimens.dart` (add `FilterChipGroupSpecimen`, `FilterChipStatesSpecimen`)
- Modify: `test/shared/widgets/mx_components_golden_test.dart` (register the two new specimens in its named-case map, `@Tags(['golden'])`)
- Modify: `docs/design-system/theme-architecture.md` (resolve the three `FilterChip` rows, `MxFilterChip` is now their caller)
- Modify: `docs/wbs.md` (header `Updated by task` → `M100.102`; a new milestone entry — check `M100.101`'s neighboring PRs for the exact section this repo currently uses for open milestones, since the tail of the file shown during planning was the technical-debt table, not the active task list)

**Interfaces:** consumes `MxFilterChip` from Task 1. Produces nothing new in `lib/`.

- [ ] **Step 1: Widgetbook**

  In `control_components.dart`, add `filterChipComponent()` immediately after `pillButtonComponent()`, matching its shape:
  - `Playground`: knobs for `label` (string, default `'Cards'`), `count` (nullable int via `context.knobs.stringOrNull` parsed, or `context.knobs.object.dropdown` over a small set — follow whatever knob type this Widgetbook version already uses elsewhere for optional ints; if none exists, a string-to-int parse with a `null`/empty sentinel is acceptable), `isSelected` (bool, default true), `enabled` (bool, default true), `hasIcon` (bool) mapped to `Icons.filter_list` same as the pill's playground.
  - `Group`: a `Row` of 3-4 `MxFilterChip`s over `<String>['All', 'Cards', 'Decks']` or similar, one selected via a dropdown knob — mirror `pillButtonComponent`'s `Group` case exactly, swapping the widget.
  - `Disabled pair`: one selected, one not, both `onPressed: null` — mirror the pill's `Disabled pair` case.
  - Find wherever `pillButtonComponent()` is added to a `WidgetbookComponent` list/folder (likely `widgetbook/lib/main.dart` or a components index) and add `filterChipComponent()` beside it.

- [ ] **Step 2: Golden specimens**

  In `selection_specimens.dart`, add `FilterChipGroupSpecimen` (a `Row` of a few `MxFilterChip`s, one selected, at least one with a `count`) and `FilterChipStatesSpecimen` (unselected / selected / disabled side by side) — same shape as the existing `PillGroupSpecimen`/`PillStatesSpecimen` in that file. Register both under new keys (`'mx_filter_chip_group'`, `'mx_filter_chip_states'`) in `mx_components_golden_test.dart`'s named-case map.

  Do **not** run `--update-goldens` (Global Constraint 13) — leave the new PNGs absent; the controller generates them on Linux after this task lands and commits them separately.

- [ ] **Step 3: Documentation**

  `docs/design-system/theme-architecture.md`:
  - Remove the **"không có caller"** annotation from the three `FilterChip` rows (currently around lines 345-347) and change each to name `MxFilterChip` as the consumer.
  - Rewrite the paragraph currently explaining why those three rows are unenforced (around lines 384-389) to instead record that `MxFilterChip` (M100.102) is now their caller, that it does **not** go through `ChipThemeData` (so `ChoiceChip`/`MxPillButton` are unaffected), and cross-reference this plan.
  - The contrast numbers already recorded at line 445 (`border-ghost` 1.19 / 1.28) stand as-is — do not remeasure unless a quick sanity check disagrees, in which case STOP and report rather than silently changing the recorded numbers.
  - Update the header's `Updated by task` / `Last updated` fields.
  - Do not touch any other row in that migration table, and do not edit `docs/design-system/ad-14-color-and-depth.md` or `docs/architecture.md`.

  `docs/wbs.md`: add a milestone entry for `M100.102` following the shape of the `M100.101` entry (goal, scope = this plan's two tasks, dependencies = `M100.101`, acceptance criteria = tests/analyze/guard green + goldens regenerated, checklist phases 7 and 12). Fetch `origin/main` immediately before this step and confirm `M100.102` is still unused — if a parallel PR has taken it, use the next free number instead and say so in the report.

- [ ] **Step 4: Run the full gate** (Global Constraint 13) plus, from `widgetbook/`: `dart run build_runner build --delete-conflicting-outputs && flutter test --reporter failures-only`. Also run `python .claude/skills/flutter-workflow/scripts/check_docs.py` if it exists in this repo (mirror the theme-binding plan's Task 4 gate) — clean.

- [ ] **Step 5: Commit**

  ```bash
  git add widgetbook/lib/components/control_components.dart test/shared/widgets/selection_specimens.dart test/shared/widgets/mx_components_golden_test.dart docs/design-system/theme-architecture.md docs/wbs.md
  git commit -m "feat(design-system): register MxFilterChip in Widgetbook, add golden specimens, resolve the FilterChip theme-architecture rows (M100.102)

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

## After both tasks (controller, not a subagent)

- Regenerate the two new component goldens on Linux (WSL), `TZ=UTC`, per this repo's golden runbook — never on Windows.
- No `test/demo/` screen changes are expected (this is a component-only task, not wired into any screen), so the pinned screen-gallery Artifact does **not** need republishing. Confirm this assumption by checking `git diff --stat` touches nothing under `test/demo/` before skipping that step.
- Final whole-branch review, then superpowers:finishing-a-development-branch.
