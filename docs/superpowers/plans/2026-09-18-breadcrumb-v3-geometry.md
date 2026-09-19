# Breadcrumb v3 geometry — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Bring `MxBreadcrumb`'s plain scrolling-strip rendering (the mode used when `onUp` is not passed) into line with the MemoX v3 HTML kit's Breadcrumb dimension table — padding, gap, 12px type at 500/700 weight with 0.1 tracking, and an `outline`-coloured `chevron_right` separator — without touching the app's tested single-target header grammar.

**Spec:** the "Breadcrumb — design specification for Flutter handoff" prompt (component mode, MemoX v3 HTML design kit · A · Chrome & navigation), pasted in full below Global Constraints for traceability. No separate spec file exists for this one-component handoff.

## Pre-flight findings (read before touching code)

`lib/shared/widgets/mx_breadcrumb.dart` implements **two grammars** behind one widget:

1. **Header/single-target mode** (`onUp` set) — every production call site
   (`deck_path_widget.dart`, `card_breadcrumb_widget.dart`,
   `card_editor_breadcrumb_widget.dart`, `card_import_context_widget.dart`)
   uses this. The whole strip is one tap target ("go up a level"), long-press
   opens an ancestor sheet, the separator is `/`, and this is locked in by
   `test/app/breadcrumb_grammar_test.dart` (owner review 2026-08-21).
2. **Plain scrolling-strip mode** (`onUp` omitted) — no production screen uses
   it. Only `test/shared/widgets/mx_breadcrumb_test.dart`,
   `mx_breadcrumb_focus_test.dart`, `mx_stress_specimens.dart` and the
   Widgetbook `MxBreadcrumb` → `Playground` use-case
   (`widgetbook/lib/components/control_components.dart:616`) exercise it. Each
   segment is individually tappable via `_MxBreadcrumbStep`
   (`mx_breadcrumb_step.dart`), separated by `_MxBreadcrumbSeparator`.

**Owner ruling (AskUserQuestion, this session):** scope is cosmetic-only —
apply the v3 dimension table to mode 2 (the plain scrolling strip) and leave
mode 1 (the header grammar) untouched, including its `/` separator, its
whole-strip tap target, and `breadcrumb_grammar_test.dart`. The fold-into-
ellipsis behaviour for paths deeper than `collapseAfter` (both modes) is
UNCHANGED — the v3 "never truncates a segment" long-content rule is
explicitly NOT applied to the fold, because removing it would be a grammar
change the owner did not authorize and would touch `_MxBreadcrumbFold`,
`mx_breadcrumb_focus_test.dart`'s ring test, and the header's own
`_stepsThatFit` fold, none of which this task may touch.

**Ruling — separator glyph does not go in the header mode.** The v3 table
says the separator is `chevron-right`, and the owner's cosmetic-only approval
named the separator glyph as in scope. But the header mode's own comment
(`mx_breadcrumb.dart`'s `upIcon` doc — "The back glyph is the only chevron on
the line — the separator between steps is a slash" — and `mx_breadcrumb_step.dart`'s
`_kSeparator` doc) is a 2026-08-21 owner review that rejected exactly this: a
`chevron_right` between every step plus the header's own `chevron_left` "back"
icon reads as two controls disagreeing, which is why `breadcrumb_grammar_test.dart` and
`mx_breadcrumb_test.dart`'s `'a separator sits between steps and not at the
ends'` test both currently pin `/`. That rationale is untouched by the v3
redesign (it is about *this app's* header composition, not a v1-freeze
value), so the chevron replaces `/` in the plain scrolling strip's
`_MxBreadcrumbSeparator` ONLY. `_kSeparator` (`'/'`) stays as-is; it is still
read by the header's `_buildSingleTarget`/`_stepsThatFit`.

**Ruling — current-segment colour.** The v3 table's "current segment" row is
`onSurface`/700, replacing today's `onSurfaceVariant`/600 for the
non-tappable (last) step in the plain mode. This directly reverses the
rationale in `mx_breadcrumb_step.dart:76-79` ("Both states rest at
onSurfaceVariant... A breadcrumb is chrome"). Ship it anyway — the owner's
cosmetic-only approval explicitly covered "colors to match v3" for this
mode, and it is a value in the FIXED dimension table, not a mock inference.
Update the comment to state the new reason instead of leaving the old one
contradicting the code, and update
`mx_breadcrumb_test.dart`'s `'the step the user is on never reacts'` test,
which currently pins the old colour.

**Token mapping** (`AppSpacing`, `AppIconSize`, `AppTypography` —
`lib/core/theme/foundations/`, `lib/core/theme/typography/`):

| v3 value | maps to |
|---|---|
| gap 4 (segment↔chevron) | `AppSpacing.xs` (already 4) |
| padding sides 16 | `AppSpacing.lg` |
| padding bottom 8 | `AppSpacing.sm` |
| padding top 2 | no scale step is 2 — a local private constant, same pattern as this file's existing `_kFocusUnderlineThickness` |
| segment type size 12 | `AppTypography.captionSize`, already what `labelMedium` uses |
| tracking 0.1 | no named tracking token is 0.1 (`labelTracking`=0.72, `sectionLabelTracking`=1.2) — a local private constant, same pattern |
| separator icon 16 ("icon xs" in the spec's own ladder) | `AppIconSize.sm` (this app's 16 step) |
| separator colour `outline` | `context.colors.outline` — not an `AppInk` member (the enum has no boundary-only role); read directly, same precedent as `mx_search_field.dart:173`'s `colors.outline` |

`context.colors.outline` used directly on a raw `Icon` inside
`lib/shared/widgets/` requires an entry in
`test/app/icon_ink_boundary_test.dart`'s `allowedInKit` map (the guard fails
any raw-coloured `Icon(` in the kit that isn't `.resolve(...)` or listed
there) — adding an `AppInk` member for one call site is out of scope
(`AppInk` is a Foundations-level enum; widening it is not this task's to
decide) and the map's own docstring invites exactly this kind of entry.

## Global Constraints

1. Touch only: `lib/shared/widgets/mx_breadcrumb.dart`,
   `lib/shared/widgets/mx_breadcrumb_step.dart`,
   `test/shared/widgets/mx_breadcrumb_test.dart`,
   `test/app/icon_ink_boundary_test.dart`. No other file changes.
2. Do not touch `_buildSingleTarget`, `_stepsThatFit`, `_kSeparator`'s value,
   `_MxBreadcrumbFold`, `_isExpanded`/`collapseAfter` logic, or anything in
   `deck_path_widget.dart` / `card_breadcrumb_widget.dart` /
   `card_editor_breadcrumb_widget.dart` / `card_import_context_widget.dart`.
   `breadcrumb_grammar_test.dart` must pass unmodified.
3. No new `AppInk` member, no new `AppSpacing`/`AppTypography` scale step. The
   two values with no existing token (`2` top padding, `0.1` tracking) are
   local `_k`-prefixed private constants in `mx_breadcrumb.dart` (or the part
   file), matching the file's own `_kFocusUnderlineThickness` precedent —
   never a bare literal inline.
4. Values are verbatim from the dimension table above. If applying one would
   contradict a test outside the two listed for update in Task 1, stop and
   report rather than editing that test.
5. House style: guard clauses, early return, no magic numbers, no
   `else` after `return`, no colour or spacing literal outside a named
   constant/token. Keep every touched file under 400 lines.
6. Verification before commit — run and quote each result line:
   - `dart format --output=none --set-exit-if-changed lib/shared/widgets/mx_breadcrumb.dart lib/shared/widgets/mx_breadcrumb_step.dart test/shared/widgets/mx_breadcrumb_test.dart test/app/icon_ink_boundary_test.dart`
   - `flutter analyze --no-fatal-infos` → `No issues found!`
   - `flutter test test/shared/widgets/mx_breadcrumb_test.dart test/shared/widgets/mx_breadcrumb_focus_test.dart test/shared/widgets/mx_stress_test.dart test/app/breadcrumb_grammar_test.dart test/app/icon_ink_boundary_test.dart test/features/deck/presentation/deck_path_test.dart test/features/card/presentation/card_editor_up_navigation_test.dart test/features/card/presentation/card_import_up_navigation_test.dart -r expanded` → `All tests passed!`
   - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
7. No goldens capture this widget today (verified: no `matchesGoldenFile` in
   any breadcrumb test, no PNG under `test/demo/` for it) — do not add any.
8. Commits: Conventional Commits, scope `design-system`, ending with
   `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. Do not push,
   open PRs, or dispatch subagents.

---

### Task 1: v3 dimension table on the plain scrolling strip

**Files:**
- Modify: `lib/shared/widgets/mx_breadcrumb.dart`
- Modify: `lib/shared/widgets/mx_breadcrumb_step.dart`
- Modify: `test/shared/widgets/mx_breadcrumb_test.dart`
- Modify: `test/app/icon_ink_boundary_test.dart`

**Interfaces:** no public API change — `MxBreadcrumb`, `MxBreadcrumbItem`
keep their exact current constructors and fields. This task changes only
what the plain (non-`onUp`) mode paints.

- [ ] **Step 1: `mx_breadcrumb.dart` — outer padding and the separator glyph**

  In `lib/shared/widgets/mx_breadcrumb.dart`, add two private constants near
  `_kFocusUnderlineThickness` (top of file, same section):

  ```dart
  /// The strip's own outer box — v3's Breadcrumb padding row (2 top · 16
  /// sides · 8 bottom). `2` has no `AppSpacing` step; declared here for the
  /// same reason `_kFocusUnderlineThickness` is.
  const EdgeInsetsDirectional _kBreadcrumbPadding = EdgeInsetsDirectional.only(
    top: 2,
    start: AppSpacing.lg,
    end: AppSpacing.lg,
    bottom: AppSpacing.sm,
  );
  ```

  In `_MxBreadcrumbState.build()`, wrap the existing non-empty return value
  (the `Semantics(container: true, ...)` widget) in this padding — the empty
  early return (`if (items.isEmpty) return const SizedBox.shrink();`) stays
  before it, unwrapped, so `mx_breadcrumb_test.dart`'s `'an empty path
  renders nothing at all'` (asserts `Size(0, 0)`) keeps passing. Do not touch
  `_buildSingleTarget`'s branch — this padding applies to the plain mode
  only:

  ```dart
  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    if (widget.onUp != null) return _buildSingleTarget(context, items);

    final isFolded = !_isExpanded && items.length > widget.collapseAfter;
    final hiddenCount = items.length - 3;

    return Padding(
      padding: _kBreadcrumbPadding,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.semanticLabel,
        child: SingleChildScrollView(
          // ...unchanged...
        ),
      ),
    );
  }
  ```

  (Keep everything inside `Semantics(...)` exactly as it is today — only the
  new `Padding` wrapper is added around it.)

- [ ] **Step 2: `_MxBreadcrumbSeparator` — chevron-right, outline colour**

  In `lib/shared/widgets/mx_breadcrumb_step.dart`, replace
  `_MxBreadcrumbSeparator.build()`'s body. It currently renders
  `Text(_kSeparator, style: ...)` inside `ExcludeSemantics`. Change it to an
  `Icon`, still excluded from semantics, still decorative:

  ```dart
  class _MxBreadcrumbSeparator extends StatelessWidget {
    const _MxBreadcrumbSeparator();

    @override
    Widget build(BuildContext context) {
      // chevron-right, not the header's `/` (owner review, 2026-08-21,
      // mx_breadcrumb_step.dart's `_kSeparator` doc): that rejection is about
      // the header's own chevron_left "back" affordance reading as two
      // controls in disagreement. This mode has no whole-strip back
      // affordance, so the v3 kit's chevron-right applies here only.
      return const ExcludeSemantics(
        child: Icon(
          Icons.chevron_right,
          size: AppIconSize.sm,
          color: null, // placeholder — see below, must resolve via context
        ),
      );
    }
  }
  ```

  The snippet above is illustrative only — `Icon.color` needs
  `context.colors.outline`, so the widget cannot stay a `const`
  `StatelessWidget` body with a literal `Icon`; write it as a normal
  (non-const) `Icon(Icons.chevron_right, size: AppIconSize.sm, color:
  context.colors.outline)` inside the same `ExcludeSemantics`, dropping
  `const` from the `Icon(` call (the surrounding `ExcludeSemantics` can stay
  non-const too, or keep `const` only where the argument list allows it —
  whichever `dart format`/`flutter analyze` accept without a lint). Keep the
  class itself `StatelessWidget`, not `const` constructor changes needed
  beyond what already exists.

  Leave `_kSeparator` (`'/'`) and every other reader of it (`_buildSingleTarget`,
  `_stepsThatFit`) untouched.

- [ ] **Step 3: `_MxBreadcrumbStep` — 12/500 ancestor, 12/700 current, 0.1 tracking, xs gap**

  Add one private constant in `mx_breadcrumb_step.dart` (near the top, same
  section as other file-local constants):

  ```dart
  /// v3's Breadcrumb segment-type tracking — no named `AppTypography`
  /// tracking token is this value (`labelTracking`=0.72,
  /// `sectionLabelTracking`=1.2), so it is declared here the same way
  /// `mx_breadcrumb.dart`'s `_kFocusUnderlineThickness` is.
  const double _kSegmentTracking = 0.1;
  ```

  Change `_padding`'s gap from `AppSpacing.sm` to `AppSpacing.xs` (v3: 4
  between a segment and its chevron; `AppSpacing.xs` is already 4):

  ```dart
  EdgeInsetsGeometry get _padding => EdgeInsetsDirectional.only(
    start: widget.isFirst ? 0 : AppSpacing.xs,
    end: AppSpacing.xs,
  );
  ```

  In the `tap == null` branch (the current/non-tappable segment), change the
  style from `context.texts.labelMedium!.inked(context, AppInk.quiet)`
  (12/600/onSurfaceVariant) to 12/700/onSurface with the new tracking:

  ```dart
  style: AppTypography.withWeight(context.texts.labelMedium!, FontWeight.w700)
      .inked(context, AppInk.stated)
      .copyWith(letterSpacing: _kSegmentTracking),
  ```

  Update the comment block right above this branch (currently explaining
  "Both states rest at `onSurfaceVariant`... A breadcrumb is chrome") — it
  now contradicts the code. Replace it with a short note that v3's dimension
  table fixes the current segment at `onSurface`/700 to read as the bold,
  non-tappable "you are here" marker, and the ancestor stays quiet/500 below
  it — cite this plan rather than re-deriving the old rationale.

  In the tappable branch (`tap != null`), change the constant weight from
  `FontWeight.w600` to `FontWeight.w500` and add the tracking override; the
  `ink`/hover/focus/underline logic is UNCHANGED (not addressed by the v3
  state matrix, keep as-is):

  ```dart
  final style =
      AppTypography.withWeight(context.texts.labelMedium!, FontWeight.w500)
          .inked(context, ink)
          .copyWith(
            decoration: _isHovered || _isFocused
                ? TextDecoration.underline
                : null,
            decorationColor: ink.resolve(context),
            decorationThickness: _isFocused
                ? _kFocusUnderlineThickness
                : null,
            letterSpacing: _kSegmentTracking,
          );
  ```

- [ ] **Step 4: update the two tests the new values break**

  In `test/shared/widgets/mx_breadcrumb_test.dart`:

  - `'a separator sits between steps and not at the ends'` (currently expects
    `find.text('/')` × 2 and `find.byIcon(Icons.chevron_right)` findsNothing)
    — flip it: expect `find.byIcon(Icons.chevron_right)` findsNWidgets(2) and
    `find.text('/')` findsNothing. Update its comment: this mode's separator
    is now v3's `chevron-right`; the header mode (a different `pumpHeader`
    helper lower in this same file) still uses `/`, unaffected — the old
    comment's "the header's back affordance owns the only arrow on the
    line" reasoning still holds, just for that other mode now.
  - `'the step the user is on never reacts'` (currently expects hovered
    `Level 2`'s color to be `colorScheme.onSurfaceVariant`) — change the
    expected color to `colorScheme.onSurface`, and update the reason string
    (no longer "the step the user is on... reads as chrome, not a heading";
    it now reads as the bold current-location marker v3's dimension table
    specifies). Keep the `isNot(TextDecoration.underline)` assertion as-is —
    that part is unaffected.

  Re-read every other test in this file after making these two edits — none
  of them should need a change (color/weight assertions elsewhere target
  `Level 0`/ancestor rest state at `onSurfaceVariant`, which is unchanged;
  `Level 2`/current step's other assertions only check decoration, not
  color, except the one above). If you find another assertion that the new
  values break, STOP and report it rather than editing a test not listed
  here.

  In `test/app/icon_ink_boundary_test.dart`, add one entry to `allowedInKit`:

  ```dart
  'mx_breadcrumb.dart':
      'the plain-mode separator paints the theme\'s own outline role '
      'directly on a chevron_right — AppInk has no member for that '
      'boundary-only M3 slot, and one call site does not justify adding one '
      '(docs/superpowers/plans/2026-09-18-breadcrumb-v3-geometry.md).',
  ```

  (Adjust the file-name key if Step 2 ends up landing the `Icon(color:)` call
  in `mx_breadcrumb_step.dart` instead — the guard scans by filename, and
  `mx_breadcrumb_step.dart` is a `part of` file under `lib/shared/widgets/`
  so either key works as long as it matches the file that actually contains
  the `Icon(color: context.colors.outline)` call. Use the correct filename.)

- [ ] **Step 5: verify**

  Run every command in Global Constraints §6 and quote the output. All must
  pass before this task is DONE.
