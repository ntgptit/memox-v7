# MemoX v3 Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `MxActionButton` — the app's one shared button — into line with the
MemoX v3 Button component handoff: fix the two tone pairs whose colours the
handoff's `themeRoleUsage` table disagrees with, and add the three painted
rungs (`small` 36, `chip` 28, `study` — pill-shaped 48) the handoff ships that
the widget does not yet have a way to paint.

**Architecture:** `MxActionButton` (`lib/shared/widgets/mx_action_button.dart`)
is the widget; `app_button_themes.dart` is its theme file (`MxFilledPair`,
`buildSharedButtonStyle`, `buildFilledStyle`, `buildOutlinedButtonTheme`). Both
stay the only place a button's colour or geometry is decided — no feature file
gets a bespoke `ButtonStyle`.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, Material 3, flutter_test, the
repo's Python guard (`code-verification-guard-v2`).

**Spec:** the Button component handoff pasted into this session (MemoX v3 HTML
design kit · B · Actions & controls). No separate spec file exists; task briefs
quote the exact values.

## Gap analysis (why each task exists)

The handoff's four tones map onto the widget's four existing
`MxActionButtonVariant` values by **role**, not by name — nothing here adds or
renames a variant:

| Handoff tone | Existing variant | Status |
|---|---|---|
| primary | `primary` | Already correct — `primary`/`onPrimary`. No task. |
| outline | `secondary` (`OutlinedButton`) | Already correct since M100.101 — `outlineVariant` border, `accentInk` label. No task. |
| secondary (`surfaceContainer`/`onSurface`) | `tonal` | **Wrong today** — paints `secondaryContainer`/`onSecondaryContainer` (M100.73's M3 tonal pair). Task 1. |
| destructive (`error-fill`/`on-error-fill`) | `destructive` | **Wrong today** — paints `scheme.error`/`scheme.onError`, the *text* pair, not the deeper solid fill `AppSemanticColors.errorFill`/`.onErrorFill` already carries unused since the 2026-09-18 theme-binding plan. Task 2. |

The four handoff sizes map onto the widget's `MxActionButtonSize` rungs by
**painted height**, and two are missing outright:

| Handoff size | Height | Existing rung | Status |
|---|---|---|---|
| regular | 48 | `standard` | Correct. No task. |
| compact | 32, radius 8 | `dense` (32, but **no radius override** — inherits `AppRadius.md`) | Value matches, radius does not. Task 3 fixes the radius only. |
| small | 36 | *(none)* | New rung. Task 4. |
| chip | 28, radius full, fixed `surfaceContainerLowest` + `border-ghost` look | *(none)* | New rung, and the one whose fill/border do not follow `variant` at all. Task 5. |
| study action | 48, radius full, padding 0/36 | *(none — today's "Reveal answer" / "Continue" / "Retry" / "Check" buttons paint `standard`'s rectangle)* | New rung; two real screens are shipping the wrong shape today. Task 6 adds the rung and wires the two files. |

`compact` (40, existing) has no handoff rung at all and is left exactly as it
is — it predates this handoff, three feature files depend on its exact 40, and
nothing in the handoff asks for it to move.

`block` (full width) needs no code change: `MxActionButton` is already
content-driven, and `SizedBox(width: double.infinity, child: MxActionButton(...))`
inside a bounded-width parent already produces it — the pattern every dialog
and sheet confirm in this app already uses via `MxButtonPair`'s `Expanded`.
Not a task.

Icon slot names (`play`, `plus`, `refresh-cw`, `check`, `trash-2`) are
`COMPONENT_INPUT` — the caller passes an `IconData`, the widget does not own
icon choice. Not a task.

## Global Constraints

1. **`app_button_themes.dart` and `mx_action_button.dart` are the only files
   that may declare a button's colour or geometry.** No feature file gets an
   inline `ButtonStyle`, a raw `FilledButton`/`OutlinedButton`, or a literal
   radius/padding override on `MxActionButton`.
2. **Values are verbatim from the handoff**, quoted in each task brief. If a
   task discovers a second disagreement between the handoff and what a task
   brief states, stop and report rather than average the two.
3. **Existing, unrelated call sites of `MxActionButtonVariant.tonal` /
   `.destructive` keep their variant choice.** Only the *colour the variant
   paints* changes (Tasks 1–2); no call site's `variant:` argument is edited by
   those two tasks.
4. **`MxActionButtonSize.compact` (40) and `.standard` (48) are untouched.**
   Task 3 touches only `.dense`'s radius. No task renames an existing enum
   value or repoints an existing call site's size unless that call site is
   named in the task (Task 6 only).
5. **`MxFilledPair`'s methods take `(ColorScheme scheme, AppSemanticColors
   semantic)`, not `ColorScheme` alone**, once Task 2 lands — `errorFill` /
   `onErrorFill` live on `AppSemanticColors`, not `ColorScheme`. Update every
   call site of `fillOf`/`labelOf`/`stateLayerOf` in the same task.
6. **A test that pins a value this plan changes is the change's to update**,
   with a doc comment recording why (the same pattern M100.101 used when
   `buildOutlinedButtonTheme`'s border moved from `outline` to
   `outlineVariant`) — never delete or skip it. A test that pins something
   this plan does not touch stays exactly as it is.
7. **House style:** guard clauses, early return, no `else` after `return`, no
   magic numbers (name them in `AppSizing`/`AppRadius`/`AppSpacing`, or as a
   named local constant next to the code that uses it if it is genuinely
   local), no colour literal outside the token files
   `test/visual_audit/color_source_rules_test.dart` already lists, no
   `DateTime.now()`, no user-visible string. Keep every file you touch under
   400 lines — split `app_button_themes.dart` if a task would cross it.
8. **Layering** (`docs/design-system/theme-architecture.md` §2):
   `lib/core/theme/` never imports `lib/features/`, `lib/app/` or
   `lib/shared/`. `lib/shared/widgets/mx_action_button.dart` may import
   `lib/core/theme/**` (it already does).
9. **Tests:** TDD — write or move the assertion first and watch it fail. Never
   delete, skip, `exclude` or comment out a test.
10. **Verification before every commit** — all must pass, and the report
    quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
    - `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` when the task creates a file
    - then `git checkout -- design_audit/` — the suite rewrites those tracked reports.
    Never run `--update-goldens` inside a task — goldens are authored on Linux
    and handled once, at the end, by the controller (Task 7).
11. **Commits:** Conventional Commits, scope `design-system`, ending with
    `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. Do not push, open
    PRs or dispatch subagents.

---

### Task 1: Secondary tone — `tonal` repainted onto `surfaceContainer`/`onSurface`

**Files:**
- Modify: `lib/core/theme/components/actions/app_button_themes.dart` (`MxFilledPair.tonal`'s `fillOf`/`labelOf`/`stateLayerOf`, and the enum member's doc comment)
- Modify: `test/shared/widgets/mx_tonal_and_outlined_test.dart` (the `'the tonal pair reads M3 tonal roles, and only those'` group and its doc comment — repin to `surfaceContainer`/`onSurface`)

**Interfaces:**
- Consumes: `ColorScheme.surfaceContainer`, `ColorScheme.onSurface` (both already exist on the scheme; no new field).
- Produces: `MxFilledPair.tonal.fillOf(scheme) == scheme.surfaceContainer`, `.labelOf(scheme) == scheme.onSurface`, `.stateLayerOf(scheme) == scheme.onSurface` (same role as the label, same pattern the `brand`/`destructive` members already use).

**Why:** the Button handoff's `themeRoleUsage` table binds the "secondary" tone's container to `surfaceContainer` (M3_COLOR, DIRECT, FULL_STRENGTH) and its label to `onSurface` — not to `secondaryContainer`/`onSecondaryContainer`, which is M3's *own* `FilledButton.tonal` pair and is what `MxFilledPair.tonal` paints today (M100.73). `DeckStudyButtonWidget`'s "Study" verb is the one live caller of `MxActionButtonVariant.tonal`; its rendered colour changes as a result, which is the point of this task, not a side effect to avoid.

- [ ] **Step 1: Update the failing test first.** In `mx_tonal_and_outlined_test.dart`, change both `expect(MxFilledPair.tonal.fillOf(scheme), scheme.secondaryContainer)` / `.labelOf` assertions (and the `stateLayerOf` one a few lines below) to `scheme.surfaceContainer` / `scheme.onSurface`. Rewrite the group's doc comment: it currently argues *for* `secondaryContainer` as "what `_FilledButtonDefaultsM3` gives `FilledButton.tonal`" — replace that argument with the handoff's own reasoning (surfaceContainer/onSurface is the v3 Button spec's `themeRoleUsage` binding for the "secondary" tone, superseding M100.73's M3-default choice). Run `flutter test test/shared/widgets/mx_tonal_and_outlined_test.dart -r failures-only` and confirm it now fails against the unchanged source (compile succeeds, assertions fail).
- [ ] **Step 2: Retarget `MxFilledPair.tonal` in `app_button_themes.dart`.** `fillOf` → `scheme.surfaceContainer`; `labelOf` → `scheme.onSurface`; `stateLayerOf` → `scheme.onSurface` (same role as `labelOf`, matching the pattern `brand`/`destructive` already use — the state layer is the pair's own `on`/label colour). Rewrite the `tonal` member's doc comment: it currently says "M3's own tonal button pair" and "It is admitted because a screen needed a third weight, not a third colour" — the colour *is* changing now, so state plainly that the pair moved from M3's default tonal roles to the v3 Button handoff's own `surfaceContainer`/`onSurface` binding, and why (the handoff names the role directly; it is not M3's tonal button, it is this app's "secondary" tone).
- [ ] **Step 3: Run the test again** — `flutter test test/shared/widgets/mx_tonal_and_outlined_test.dart -r failures-only` → `All tests passed!`.
- [ ] **Step 4: Full verification** per Global Constraint 10, and report each command's output line.

---

### Task 2: Destructive tone — `destructive` repainted onto `errorFill`/`onErrorFill`

**Files:**
- Modify: `lib/core/theme/components/actions/app_button_themes.dart` (`MxFilledPair` enum's method signatures, `.destructive`'s three methods, `buildFilledButtonTheme`, `buildFilledStyle`'s three call sites of `pair.fillOf`/`pair.labelOf`/`pair.stateLayerOf`, and the `destructive` member's doc comment)
- Modify every other call site of `MxFilledPair.fillOf`/`.labelOf`/`.stateLayerOf` found by `grep -rn "\.fillOf(\|\.labelOf(\|\.stateLayerOf(" lib/ test/` (expected: only inside `app_button_themes.dart` itself and this task's test file — confirm and list any other hit in the report)
- Modify: `test/shared/widgets/mx_tonal_and_outlined_test.dart` if it asserts on `MxFilledPair.destructive` (check; the earlier grep in this plan's own research did not find it there — if a different test file pins `.destructive`, that file is in scope instead)
- Test: extend whichever existing test already exercises `MxFilledPair` (`mx_tonal_and_outlined_test.dart` is the established home for this enum's contract; add a `destructive` group there rather than opening a new file)

**Interfaces:**
- Consumes: `AppSemanticColors.errorFill`, `.onErrorFill` (already exist, landed 2026-09-18, currently unused by any widget — `grep -rn "errorFill\|onErrorFill" lib/` before this task returns zero hits outside the foundation files themselves).
- Produces: `MxFilledPair.fillOf(scheme, semantic)`, `.labelOf(scheme, semantic)`, `.stateLayerOf(scheme, semantic)` — new second parameter on all three methods, all three call sites in `buildFilledStyle` updated to pass it. `MxFilledPair.destructive.fillOf(scheme, semantic) == semantic.errorFill`, `.labelOf(...) == semantic.onErrorFill`, `.stateLayerOf(...) == semantic.onErrorFill`.

**Why:** the handoff's `themeRoleUsage` table binds the destructive tone's container to `error-fill` (`MEMOX_SEMANTIC_COLOR`), explicitly distinguished from `error` ("the SOLID destructive fill — deeper than error, which is the error text colour"). Today's `MxFilledPair.destructive` paints `scheme.error`/`scheme.onError` — the text pair, not the fill the theme-binding plan built for exactly this. `MxActionButton`'s two live destructive callers (`deck_reset_progress_widget.dart` via `MxConfirmDialog`, and `MxConfirmDialog` itself) get the correct fill as a result.

- [ ] **Step 1: Write the failing test.** In `mx_tonal_and_outlined_test.dart`, add a group mirroring the tonal one: for light and dark, `expect(MxFilledPair.destructive.fillOf(scheme, semantic), semantic.errorFill)`, `.labelOf(scheme, semantic)` → `semantic.onErrorFill`, `.stateLayerOf(scheme, semantic)` → `semantic.onErrorFill`. You will need `AppSemanticColors.light()`/`.dark()` in scope (the tonal group above already imports the type; instantiate alongside the existing `scheme`/`theme` locals). Run it and confirm a compile failure (methods do not yet take a second parameter).
- [ ] **Step 2: Widen `MxFilledPair`'s three methods** to `(ColorScheme scheme, AppSemanticColors semantic)`. `brand` and `tonal` ignore the new parameter (their answers do not change); `destructive.fillOf` → `semantic.errorFill`, `.labelOf` → `semantic.onErrorFill`, `.stateLayerOf` → `semantic.onErrorFill`.
- [ ] **Step 3: Update every call site** the Files section's grep found — `buildFilledStyle`'s three internal calls (`pair.fillOf(scheme)` → `pair.fillOf(scheme, semantic)`, etc. — `semantic` is already a parameter of `buildFilledStyle`, nothing new to plumb there) and `buildFilledButtonTheme`'s call to `buildFilledStyle` (unchanged signature, already passes `semantic` through).
- [ ] **Step 4: Rewrite `destructive`'s doc comment.** It currently says `` `error` / `onError` — the destructive action. `error` is `danger` in this palette, so this is not a second red.`` Replace it with the handoff's own distinction: the fill is `errorFill` (the SOLID destructive fill), the label is `onErrorFill`, and both are deliberately a different pair from `scheme.error`/`.onError` — the text/icon "this is an error" colour the rest of the app still uses for validation messages and the like.
- [ ] **Step 5: Run the test** → `All tests passed!`.
- [ ] **Step 6: Full verification** per Global Constraint 10, and report each command's output line.

---

### Task 3: `dense` (32) gets its radius — `AppRadius.sm` (8)

**Files:**
- Modify: `lib/shared/widgets/mx_action_button.dart` (`_sized`'s geometry `ButtonStyle` for the `dense` case; the `dense` enum member's doc comment)
- Test: `test/shared/widgets/mx_action_button_size_test.dart` (extend; this is the file that already measures `.compact`/`.dense` geometry — confirm by reading it first)

**Interfaces:**
- Produces: an `MxActionButton(size: MxActionButtonSize.dense, ...)` resolves a `shape` of `RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm))` (8), where every other size still resolves `AppRadius.md` (12) via `buildSharedButtonStyle`.

**Why:** the handoff's "compact" rung (32, radius 8) is a painted-height match for the existing `dense` (32) — same box, no reason to add a fourth enum value for it — but `dense` today inherits `AppRadius.md` (12) from the shared style because `_sized`'s geometry `ButtonStyle` never states a `shape`. The handoff is explicit that this rung paints radius 8. `DeckStudyButtonWidget`'s "Study" verb (the one live `.dense` caller) gets a tighter corner as a result — expected, not a side effect to avoid.

- [ ] **Step 1: Read `mx_action_button_size_test.dart` first** to find its existing per-size assertions and match its style (helper functions, `WidgetTester` setup) rather than writing a parallel pattern.
- [ ] **Step 2: Add a failing assertion** for `.dense`'s `shape` resolving to `BorderRadius.circular(AppRadius.sm)`. Run it and confirm it fails against the current `AppRadius.md`.
- [ ] **Step 3: In `_sized`**, add `shape: const WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)))` to the `geometry` `ButtonStyle` built for the `dense` branch only — `standard` still returns `base` unmodified (untouched by this task), `compact` keeps inheriting `AppRadius.md` (the handoff has no `compact`-40 rung to disagree with it). You will need to branch the geometry construction by `size` rather than build one shared `geometry` object for every non-standard size, since `dense` now differs from `compact` in more than its `Size`.
- [ ] **Step 4: Update `dense`'s doc comment** to record the v3 alignment: this rung is now also the handoff's "compact" (32, radius 8) size, painted at the same box the deck-row review already chose it for.
- [ ] **Step 5: Run the test** → `All tests passed!`.
- [ ] **Step 6: Full verification** per Global Constraint 10, and report each command's output line.

---

### Task 4: `MxActionButtonSize.small` (36)

**Files:**
- Modify: `lib/shared/widgets/mx_action_button.dart` (new enum value; `_sized`'s per-size branching; `_iconGap`/label-rung logic if it branches by size — check `_iconGap`'s `size == MxActionButtonSize.compact` condition, since `small` needs the *standard* rung's gap, not compact's)
- Modify: `lib/core/theme/foundations/app_sizing.dart` (new `controlSmall = 36` constant, with a doc comment matching the file's existing style; the file's header doc comment currently argues the app renders "two" control heights below the touch target — update that sentence, it becomes three with this task)
- Test: `test/shared/widgets/mx_action_button_size_test.dart` (extend)
- Test: `test/core/theme/foundations/app_sizing_test.dart` if it enumerates every constant (check; keep it passing)

**Interfaces:**
- Produces: `AppSizing.controlSmall == 36`. `MxActionButton(size: MxActionButtonSize.small, ...)` resolves `minimumSize` height 36 (width floor unchanged, `AppSizing.buttonMinWidth`), `tapTargetSize: MaterialTapTargetSize.padded` (48 floor, same mechanism `.compact`/`.dense` already use), radius `AppRadius.md` (12 — the handoff states no radius override for this rung, unlike `dense`), and **padding that depends on whether `icon` is set**: `EdgeInsets.symmetric(horizontal: 12)` when there is no icon, `EdgeInsets.symmetric(horizontal: 16)` when there is one. Label rung is the standard one (`labelLarge` at `buttonLabelWeight`), matching the handoff's "14/600" (the app's established 700-weight override applies here exactly as it does to `.standard` — do not introduce a third weight).

**Why:** the handoff ships a 36-high rung with no existing match — `.standard` is 48, `.compact` is 40, `.dense` is 32. This is additive: no existing call site's size argument changes, and none is required to adopt `.small` by this task (the handoff's four named call sites — a reminder-time control, a tag-management empty action, two DeckImport file pickers — do not exist as built Flutter screens in this repo today; confirm that with `grep -rln "reminder\|DeckImport" lib/features --include=*.dart -i` before starting, and if any of the four does turn out to exist, wire it to `.small` as part of this task and say so in the report).

- [ ] **Step 1: Read `mx_action_button_size_test.dart` and `_sized`/`_iconGap` in full** before writing anything — `_iconGap` currently branches only on `size == MxActionButtonSize.compact` to pick the compact label rung for its text-scale calculation; `.small` uses the *standard* rung (`labelLarge`), so no change to `_iconGap` should be needed, but confirm by reading rather than assuming.
- [ ] **Step 2: Add `MxActionButtonSize.small` to the enum**, with a doc comment stating its painted height (36), that its width floor is unchanged, and the icon-dependent padding rule.
- [ ] **Step 3: Add `AppSizing.controlSmall = 36`** next to `controlCompact`/`controlDense`, with a doc comment in the file's style (what call site motivates it — quote the handoff's four named roles even if none is built yet, the way other constants here cite their origin). Update the file header's "two heights" sentence to "three".
- [ ] **Step 4: Write a failing test** in `mx_action_button_size_test.dart` for `.small`'s height (36), touch floor (48 via `tapTargetSize: padded`), and both padding cases (with and without `icon`). Run it, confirm it fails (compile error — the enum value does not exist yet — is an acceptable "fail" here; note that in the report rather than treating it as a blocker).
- [ ] **Step 5: Implement.** In `_sized`, `.small` needs its own branch: height `AppSizing.controlSmall`, `tapTargetSize: padded`, `textStyle` the standard `labelLarge` rung (no re-weighting needed — `base`'s textStyle, inherited from `buildSharedButtonStyle`, already carries it; do not restate it), and `padding` computed from `icon != null` at build time (this method already receives `context`; it will now also need the button's own `icon`/`size` state, which it already closes over as instance fields — confirm `_sized` is an instance method with access to `icon`, not a static helper, before assuming this is free).
- [ ] **Step 6: Run the test** → `All tests passed!`.
- [ ] **Step 7: Full verification** per Global Constraint 10, and report each command's output line.

---

### Task 5: `MxActionButtonSize.chip` (28) — the one rung whose look ignores `variant`

**Files:**
- Modify: `lib/shared/widgets/mx_action_button.dart` (new enum value; `_buildButton`/`_sized` — this rung needs a fixed style layered *after* the variant's style, not merged geometry over it, since its fill/border are not the variant's tone)
- Modify: `lib/core/theme/components/actions/app_button_themes.dart` (a small exported builder for the chip look, so the fixed style lives in the theme file with everything else — do not inline `Color`/`BorderSide` literals in the widget)
- Modify: `lib/core/theme/foundations/app_sizing.dart` (new `controlChip = 28` constant)
- Test: `test/shared/widgets/mx_action_button_size_test.dart` (extend)

**Interfaces:**
- Produces: `AppSizing.controlChip == 28`. `MxActionButton(size: MxActionButtonSize.chip, ...)` paints height 28, radius `AppRadius.pill`, padding `EdgeInsets.symmetric(horizontal: 8)`, label rung `labelMedium` at `buttonLabelWeight` (12/700, the same re-weighting `.compact` already applies), fill `scheme.surfaceContainerLowest`, border `AppDecorations.hairlineEdge(scheme)` ("border-ghost"), label/icon colour `scheme.onSurfaceVariant` — **regardless of which `variant` the caller passed**. Disabled state still applies `AppStateOpacity.disabled` (0.38) over the whole control, per the handoff's state matrix; it does not fall through to a *different* disabled treatment than every other button.

**Why:** the handoff's `themeRoleUsage` table gives this rung exactly one container binding (`surfaceContainerLowest`) and one border binding (`border-ghost`), with no per-tone row — unlike every other rung, "chip" is a fixed look, not four tones at a smaller size. `_labelColorFor` in `app_chip_theme.dart` already pairs `surfaceContainerLowest` with `scheme.onSurfaceVariant` for the app's unselected `MxPillButton`; reuse that pairing here rather than inventing a second answer for the same two colours sitting on the same fill (ruling — the handoff's table has no row for this label, and `onSurfaceVariant` is the established precedent for text on this exact fill elsewhere in the app).

- [ ] **Step 1: Read `_buildButton` and `buildFilledStyle` in full** before writing anything. The four existing variants each resolve to a `FilledButton` or `OutlinedButton` whose `ButtonStyle` encodes the tone; `.chip` needs the *shape* of whichever button the variant would have built (so `onPressed`/disabled/focus semantics stay identical — reuse `FilledButton` for every `.chip` instance regardless of `variant`, since the tone is fixed anyway) with its *colours* replaced.
- [ ] **Step 2: Add `AppSizing.controlChip = 28`** next to the other control constants, doc comment in the file's style.
- [ ] **Step 3: Add `MxActionButtonSize.chip` to the enum**, doc comment stating it is the one rung whose fill/border/label colour are fixed rather than following `variant`, and why (quote the handoff's `themeRoleUsage` table having no per-tone row for it).
- [ ] **Step 4: Add a builder in `app_button_themes.dart`** — e.g. `ButtonStyle buildChipButtonStyle(ColorScheme scheme, TextTheme texts)` — returning the fixed fill/border/label/state-layer/disabled `ButtonStyle` described in Interfaces, built the same way `buildFilledStyle` is (explicit `WidgetStateProperty.resolveWith` per state, disabled first, matching the ordering convention every other resolver in this file uses). Use `AppDecorations.hairlineEdge(scheme)` for the border exactly as `app_card_theme.dart`/`app_input_theme.dart` already do — do not recompute the alpha.
- [ ] **Step 5: Wire it in `mx_action_button.dart`.** When `size == MxActionButtonSize.chip`, `_buildButton` renders a `FilledButton` (ignoring `variant`'s own branch entirely — state this explicitly in a doc comment on `_buildButton` so a future reader does not "fix" it back onto the tone ladder) with `_sized`'s geometry (height 28, `AppRadius.pill`, padding 8, `labelMedium` rung) merged with `buildChipButtonStyle`'s colours.
- [ ] **Step 6: Write the test** in `mx_action_button_size_test.dart`: `.chip`'s geometry (height, radius, padding), and — critically — that passing `variant: MxActionButtonVariant.destructive` (or any non-default variant) alongside `size: MxActionButtonSize.chip` still resolves the fixed `surfaceContainerLowest`/`border-ghost`/`onSurfaceVariant` look, not the destructive pair. Run it first against the unimplemented enum value to confirm it fails.
- [ ] **Step 7: Implement per Steps 4–5, then run the test** → `All tests passed!`.
- [ ] **Step 8: Full verification** per Global Constraint 10, and report each command's output line.

---

### Task 6: `MxActionButtonSize.study` (48, pill) — and its two real call sites

**Files:**
- Modify: `lib/shared/widgets/mx_action_button.dart` (new enum value; `_sized`)
- Modify: `lib/features/study/presentation/widgets/sections/recall_timer_pieces_widget.dart` (every `MxActionButton` in `_controls` — the "Reveal answer", both "Forgot"/"Remembered", "Continue", "Retry" instances)
- Modify: `lib/features/study/presentation/widgets/sections/fill_answer_section_widget.dart` (the "Check" `MxActionButton` at the `ValueListenableBuilder`; leave the "Show hint" `MxActionButton` at its current `.secondary` default size — the handoff's study-action rows in the kit show one wide pill action, not a hint chip reshaped to match)
- Test: `test/shared/widgets/mx_action_button_size_test.dart` (extend, for the rung's own geometry)
- Test: whatever widget test already covers `recall_timer_pieces_widget.dart` / `fill_answer_section_widget.dart` (find with `grep -rl "RecallPhase\|studyFillSubmit" test/` and read before touching — update any assertion that inspects these buttons' `shape`/`padding`, add none that duplicates Task's own size test)

**Interfaces:**
- Produces: `MxActionButton(size: MxActionButtonSize.study, ...)` paints height `AppSizing.touchTarget` (48, unchanged from `.standard`), radius `AppRadius.pill`, padding `EdgeInsets.symmetric(horizontal: 36)`, label rung unchanged from `.standard` (`labelLarge`/700). Colour is whatever `variant` the caller passes — this rung is a shape change only, unlike `.chip`.

**Why:** the handoff names "the Recall and Fill study screens" as this rung's shipped call sites, and those screens exist and render today — as plain `.standard` rectangles. `recall_timer_pieces_widget.dart`'s "Reveal answer", "Continue" (×2: `timedOutReview` and `timedOutSubmitting`/`advancing`), and "Retry", plus `fill_answer_section_widget.dart`'s "Check", are the five buttons in question (more than the handoff's "three" — the handoff was drawn from the kit's states, which may show fewer than the app's; wire all five, since all five are the same "the one primary action a study turn ends with" role the handoff describes). Each keeps the `variant`/`onPressed`/`label` it already has — only `size:` changes, added where the constructor call does not already state a `size:` argument (it does not, today, for any of the five). **`.selfAssessment`'s "Forgot"/"Remembered" pair is a genuine open question, not a default**: it is `secondary`-tone (outline), stacked/paired via `StudyCtaRowWidget`, and the handoff's own "study action" example is a single centred verb, not a two-up outlined pair — decide by reading the file's existing doc comment on that pair (it explains at length why the two are deliberately equal-weight and *not* filled) before choosing whether `.study`'s pill shape applies to an outlined pair at all, or whether it is a `.standard`-shape exception; record whichever you choose as a ruling in the fix report, since the handoff does not resolve it and this brief should not guess for you.

- [ ] **Step 1: Read both feature files in full**, and their existing tests, before writing anything.
- [ ] **Step 2: Add `MxActionButtonSize.study` to the enum**, doc comment naming its two call sites and stating explicitly that colour comes from `variant`, unlike `.chip`.
- [ ] **Step 3: Write a failing test** for `.study`'s own geometry (height 48, radius pill, padding 36) in `mx_action_button_size_test.dart`.
- [ ] **Step 4: Implement in `_sized`** — height `AppSizing.touchTarget` (reuse the existing constant, do not restate `48`), radius `AppRadius.pill`, padding `EdgeInsets.symmetric(horizontal: 36)` (name the `36` — it has no existing `AppSpacing` rung; add one only if the ladder genuinely has a gap at 36, otherwise a local named constant next to `_sized` is the right size for a single-rung, single-file value — decide by reading `AppSpacing` first).
- [ ] **Step 5: Wire the four unambiguous call sites** (Reveal answer, both Continue instances, Retry, Check) to `size: MxActionButtonSize.study`.
- [ ] **Step 6: Resolve the Forgot/Remembered question** per the "Why" paragraph above, apply your ruling, and state it plainly in the fix report.
- [ ] **Step 7: Run this task's test and every test touched in Step 1's read** → `All tests passed!`.
- [ ] **Step 8: Full verification** per Global Constraint 10, and report each command's output line.

---

### Task 7 (controller-run, not dispatched): Widgetbook, goldens, gallery

This task is **not** dispatched to a subagent. Run it yourself once Tasks 1–6
are all `complete` in the ledger.

1. Confirm Widgetbook needs no new use-case code: `widgetbook/lib/components/control_components.dart`'s interactive `MxActionButton` use case builds its variant/size dropdowns from `MxActionButtonVariant.values`/`MxActionButtonSize.values` — the three new enum members and the two retargeted colours appear there automatically. Open the catalog (or its test, if one renders every use case) and confirm rather than assume.
2. Any golden that captures a `.tonal` button, a `.destructive` button, `DeckStudyButtonWidget`, `recall_timer_pieces_widget.dart`, or `fill_answer_section_widget.dart` now differs. Find them: `grep -rl "tonal\|destructive\|DeckStudyButton\|Recall\|FillAnswer" test/**/goldens -i` will not work (goldens are PNGs) — instead diff `git status`/`flutter test --tags golden` failures after the six tasks land, which names the stale files directly.
3. Regenerate per `.claude/skills/flutter-testing` / the WSL golden runbook this project uses (goldens are Linux-authored only — do not run `--update-goldens` on this Windows checkout). `TZ=UTC` is required.
4. Rebuild and republish the screen gallery at the existing pinned Artifact URL, per this repo's `CLAUDE.md` "A change a person can see ends in the gallery" section — `python .claude/skills/flutter-testing/scripts/build_screen_gallery.py`, then publish `build/screen_gallery.html` to the URL already on file, quoting the new `ảnh <digest>` header when you hand it over.
5. Run `flutter test integration_test/ -d emulator-5554 --flavor development` if a device is available in this environment; if not, say so plainly in the finish message rather than skipping silently — Task 6 touched two `lib/features/study/` files, which is exactly the "adding anything under `lib/features/`" trigger this repo's `CLAUDE.md` names for the device suite.
