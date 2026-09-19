# StudyTopBar Component — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Give the study session's shared top bar (`MxSessionTopBar`) a per-instance
`accent` colour so its mode chip and progress fill can vary by study mode
(`primary` by default, `mastery` in `recall` and `fill`), fix its counter's ink
and fixed height against the StudyTopBar design contract, and update its one
caller (`StudySessionFrameSectionWidget`) to supply the accent.

**Architecture:** `MxSessionTopBar` (`lib/shared/widgets/mx_session_top_bar.dart`)
already owns this exact semantic contract — close action, mode chip, thin
progress track, trailing figure — and has exactly one caller,
`StudySessionFrameSectionWidget`
(`lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart`).
This plan extends both `MxSessionTopBar` and `MxProgressBar`
(`lib/shared/widgets/mx_progress_bar.dart`, which `MxSessionTopBar` already
composes for its track) rather than adding a parallel `StudyTopBar` widget.
`AppSemanticColors.mastery` / `AppProductColors.mastery{Light,Dark}` already
exist from the theme-prerequisite run, with the doc comment "the accent
StudyTopBar is handed in Recall and Fill sessions" — there is no theme gap.

**Spec:** the StudyTopBar component contract handed to this session (component
dimension table, theme-consumption table, state matrix — quoted in full in the
task brief). `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md`
§5.1 is the theme layer this plan reads from, not one it may change.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, Material 3, Riverpod, flutter_test,
the repo's Python guard (`code-verification-guard-v2`).

## Global Constraints

1. **Do not create a new widget named `StudyTopBar`.** `MxSessionTopBar` already
   owns this contract; extend it in place. The HTML kit's CSS/JSX names are for
   traceability only (per the handoff), not Flutter API names.
2. **`MxProgressBar`'s existing three callers keep their exact current pixels.**
   Any new parameter added to `MxProgressBar` must be optional and default to
   `null`/current behaviour, so `progress_week_bar_widget.dart`,
   `card_progress_panel_widget.dart` and `card_box_progress_widget.dart` are
   unaffected. Verify by reading their call sites before touching the widget.
3. **Do not touch `_leadingInset`/`_trailingInset` in `mx_session_top_bar.dart`.**
   These already implement (and extensively document, with measured pixel
   values) a more correct version of the HTML mock's naive "8px inset" —
   changing them to literally match the mock's box padding is exactly the
   "fixed pixel boxes around text" mistake the handoff warns against.
4. **`trailing` stays a caller-owned `Widget`, not a component-owned counter.**
   `MxSessionTopBar` already generalized the mock's fixed "n / total" slot to
   accept any figure, because `recall` mode needs a countdown clock there
   instead — a strictly more correct behaviour than the mock's single slot.
   Only the *ink* used by the counter's own text (owned by the caller, in
   `study_session_frame_section_widget.dart`'s `_Figure`) needs to change.
5. **No magic numbers.** The accent-tint opacity (10%) needs a named constant
   with a one-line doc comment, following the existing pattern of local named
   constants already in `mx_session_top_bar.dart` (e.g. `_kChipMaxWidthFraction`).
   Do not reuse `AppInteractionStates.focus` (0.10) — that constant means a
   focus state layer, not a badge fill tint, and reusing it would misstate why
   the value is what it is.
6. **The fixed 56dp height is the component's own, not a new global token.**
   Prefer Flutter's own `kToolbarHeight` (Material's app-bar-height constant,
   already 56.0) over inventing a new `AppSizing` field for a single caller.
   If the guard's magic-number scan rejects a framework constant, fall back to
   one local named constant in `mx_session_top_bar.dart` with a comment citing
   `kToolbarHeight`.
7. **House style:** guard clauses and early return, no `else` after `return`,
   no colour literal outside the token files `test/visual_audit/color_source_rules_test.dart`
   already allow-lists, no `DateTime.now()`, no new user-visible string. Keep
   every file you touch under 400 lines.
8. **Update the stale doc comment.** `study_session_frame_section_widget.dart`
   currently documents (around "One accent, and mode is told apart by the word
   on the chip", §7.8) that `MxSessionTopBar` deliberately takes no colour,
   specifically because a mode colour could collide with `match`'s correctness
   feedback. That reasoning no longer holds as stated — `match` keeps
   `primary` under this change, only `recall`/`fill` receive `mastery`, so the
   collision the old comment warned about does not recur — but the comment
   must be rewritten to say so, not silently left contradicting the code.
9. **Never run `--update-goldens` locally.** This change very likely moves the
   chip's fill/ink/weight and the bar's height, which will break any existing
   goldens over `MxSessionTopBar`/`StudySessionFrameSectionWidget`/study
   session screens. Note which golden files fail in the report; the controller
   regenerates them on Linux afterward per repo convention — do not attempt it
   on this Windows checkout.
10. **Verification before every commit** — all must pass, and the report
    quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → report pass/fail
      counts; a golden test failing for the reasons in constraint 9 is
      expected and must be named, not hidden
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7`
      → no errors
    - then `git checkout -- design_audit/` — some suites rewrite those tracked
      reports as a side effect of running.
11. **Commits:** Conventional Commits, scope `design-system`, ending with
    `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. Do not push,
    open PRs, or dispatch subagents.

---

### Task 1: `MxSessionTopBar` accent + `MxProgressBar` accent/motion overrides

**Files:**
- Modify: `lib/shared/widgets/mx_session_top_bar.dart`
- Modify: `lib/shared/widgets/mx_progress_bar.dart`
- Modify: `lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart`
- Test: whatever host test(s) already cover `MxSessionTopBar` and
  `StudySessionFrameSectionWidget` (locate via `grep -rl MxSessionTopBar test/`
  and `grep -rl StudySessionFrameSectionWidget test/`) — extend rather than
  replace their assertions.

**Interfaces:**
- `MxSessionTopBar` gains `required Color accent`.
- `MxProgressBar` gains `Color? fillColor`, `Duration? duration`, `Curve? curve`
  — all optional, all defaulting to today's behaviour when null.
- `StudySessionFrameSectionWidget` computes the accent from `mode` and passes
  it to `MxSessionTopBar`.

**Component contract (verbatim from the handoff, for reference):**

```
height              FIXED           56 (it is an .appbar)
mode badge          FIXED           12/700, 1.2px tracking, uppercase,
                                     padding 4/8, radius full,
                                     accent on accent @10%
progress track      FIXED           height 4, radius full, surfaceContainer
progress fill       RESPONSIVE      accent, width = current/total,
                                     200ms standard ease
counter             FIXED           12/600, tabular numerals,
                                     onSurfaceVariant, 8 right inset
accent              CONTENT-DRIVEN  per study mode — one prop drives badge,
                                     badge tint and fill

Theme bindings:
  bar background     surface (DIRECT, full strength) — bar paints no fill of
                      its own; this is already true (no Container behind the
                      Row) and needs no code change
  progress track      progress-track alias (DIRECT, full strength) — already
                      `context.semanticColors.progressTrack` inside
                      MxProgressBar; needs no change
  progress fill       accent (COMPONENT_INPUT, full strength)
  mode badge label    accent (COMPONENT_INPUT, full strength)
  mode badge fill     accent (COMPONENT_INPUT, TINT 10%)
  counter             onSurfaceVariant (DIRECT, full strength) — `AppInk.quiet`
  close glyph         onSurface (DIRECT, full strength) — already true via
                      `MxIconButton`'s default tone; needs no change

Accent selection (per this component's own spec):
  primary by default, mastery in Recall and Fill
```

- [ ] **Step 1: `MxProgressBar` — optional accent/motion overrides**

  Read `lib/shared/widgets/mx_progress_bar.dart` in full first. Add three new
  optional constructor parameters — `Color? fillColor`, `Duration? duration`,
  `Curve? curve` — and use them in `build()`:
  - `fill` becomes `fillColor ?? (isComplete ? semantic.success : semantic.progressFill)`.
  - The `TweenAnimationBuilder`'s `duration:` becomes
    `AppMotionPolicy.durationOf(context, duration ?? AppDurations.slow)`.
  - Its `curve:` becomes `curve ?? AppDurations.decelerate`.

  Confirm `progress_week_bar_widget.dart`, `card_progress_panel_widget.dart`
  and `card_box_progress_widget.dart` construct `MxProgressBar` without these
  three names, so their behaviour is provably unchanged.

- [ ] **Step 2: `MxSessionTopBar` — accent parameter, badge, track, height**

  Read `lib/shared/widgets/mx_session_top_bar.dart` in full first (it is
  heavily commented; keep comments that remain true, update or remove ones
  this change falsifies).

  - Add `required Color accent` to the constructor and field list.
  - `_Chip` (or the call site that builds it) needs the accent threaded in:
    - fill: `accent.withValues(alpha: <named 10% constant>)` instead of
      `context.semanticColors.surfaceMuted`.
    - label ink: paint the label in `accent` directly (full strength) instead
      of `.inked(context, AppInk.accent)` — this is a legitimate
      `COMPONENT_INPUT` colour, not a new general-purpose escape hatch; the
      theme layer already anticipates exactly this (see
      `AppProductColors.mastery`'s doc comment). Weight changes from `w600`
      to `w700` per the contract; tracking (already `sectionLabelTracking`
      via `sectionLabel`), uppercase, padding (`xs`/`sm`) and radius (`pill`)
      are already correct and need no change.
  - `MxProgressBar(value: progress, size: MxProgressBarSize.sm)` becomes
    `MxProgressBar(value: progress, size: MxProgressBarSize.sm, fillColor: accent, duration: AppDurations.normal, curve: AppDurations.standard)`.
  - Wrap the widget's returned tree so the whole bar is exactly `kToolbarHeight`
    tall (56dp), with its current content vertically centred inside that box —
    today's content is intrinsically ~48dp tall (the 48×48 close button), so
    centring inside 56 adds even top/bottom breathing room. Verify this does
    not change any of the already-measured horizontal positions
    (`_leadingInset`/`_trailingInset`/glyph placement) — it is a height-only
    change.

- [ ] **Step 3: `StudySessionFrameSectionWidget` — pass the accent, fix the counter ink, update the doc comment**

  - Compute `final accent = (mode == StudyMode.recall || mode == StudyMode.fill) ? context.semanticColors.mastery : context.colors.primary;` (or equivalent) and pass `accent: accent` to `MxSessionTopBar`.
  - In `_Figure` (the counter/clock text), change `AppInk.stated` to
    `AppInk.quiet` — the contract binds the counter to `onSurfaceVariant`, and
    `stated` resolves to `onSurface`. Weight (`isEmphasized: true` → w600) and
    `isTabular: true` are already correct.
  - Rewrite the class doc comment's "One accent, and mode is told apart by the
    word on the chip" paragraph (around line 28) to describe the new,
    narrower rule: the chip's colour now varies by mode (`primary` by
    default, `mastery` in `recall`/`fill`), and this does not reintroduce the
    `match`-vs-`success` collision the original comment warned about because
    `match` keeps `primary` — only `recall` and `fill`, which have no
    pair-correctness feedback sharing the screen, receive `mastery`.

- [ ] **Step 4: Widgetbook**

  Check whether `MxSessionTopBar` and/or `MxProgressBar` have existing
  Widgetbook specimens (`grep -rl MxSessionTopBar widgetbook/`). If a specimen
  exists, give it (or add) a case that exercises a non-default `accent` so the
  catalog is not stuck showing only the old brand-accent chip.

- [ ] **Step 5: Tests**

  Extend whatever host test(s) already cover `MxSessionTopBar` and
  `StudySessionFrameSectionWidget` (found via the greps in Files above) to
  assert: the chip fill/label follow the passed `accent`, the progress fill
  colour follows `accent`, the counter resolves to `onSurfaceVariant`, and the
  bar's height is `kToolbarHeight`. Do not delete or weaken any existing
  assertion; if one now conflicts with the new contract, it is this task's to
  update, not to silently drop.

**Acceptance criteria:**
- [ ] `MxSessionTopBar` takes `required Color accent`; chip fill is `accent`
      tinted at a named 10% constant, chip label is `accent` at full
      strength, weight 700, tracking/uppercase/padding/radius unchanged.
- [ ] The thin progress track's fill is `accent`, animated over
      `AppDurations.normal` (200ms) with `AppDurations.standard` easing — not
      the widget's general-purpose `slow`/`decelerate` default.
- [ ] `MxSessionTopBar`'s painted height is exactly `kToolbarHeight` (56dp);
      existing horizontal measurements are unchanged.
- [ ] `MxProgressBar`'s three existing callers are provably unaffected
      (no new parameters named at their call sites).
- [ ] The counter in `StudySessionFrameSectionWidget` reads `onSurfaceVariant`
      (`AppInk.quiet`), not `onSurface`.
- [ ] `StudySessionFrameSectionWidget` passes `primary` by default and
      `mastery` for `recall`/`fill`; its stale "one accent" doc comment is
      rewritten to match.
- [ ] `flutter analyze --no-fatal-infos`, the non-golden test suite, and the
      guard all pass; any golden failures are named in the report, not hidden
      or worked around locally.

**Checklist phases:** 7, 12, 14.
