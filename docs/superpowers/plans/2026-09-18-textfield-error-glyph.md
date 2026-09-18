# TextField error glyph — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `MxTextField`'s error message row gains the glyph the v3 registry
already names for it — an `alert-circle` icon beside the error text — closing
the one structural gap between the widget and the v3 "Inputs & selection"
handoff. Everything else the handoff asks for (fill, border, radius, hint/value
ink, disabled opacity) was already bound in wave 3 (M100.101, #577); this plan
does not touch it again.

**Architecture:** `MxTextField` builds its `InputDecoration` from the
`errorText` string alone today, which has no icon slot. `InputDecoration.error`
(a `Widget?`, mutually exclusive with `errorText`) is the native replacement —
`InputDecorator` treats either as equivalent for border/suffix/helper state
resolution, so switching to it costs no other state wiring. The task is
contained to `lib/shared/widgets/mx_text_field.dart` and its contract test; the
theme (`app_input_theme.dart`) is not touched.

**Spec:**
- The handoff: `TextField` component contract, source *MemoX v3 HTML design
  kit · C · Inputs & selection* (dimension table: `error FIXED — 1px error
  border + message row: 12px error text, alert-circle 16, padding 4 4 0`;
  icon slot: `alert-circle`, Lucide name mapped by meaning).
- Independent confirmation: `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md:340`
  — registry entry `error | M3_COLOR | TextField.error.border;
  TextField.error.message text + glyph; ErrorState.tile glyph` — the master
  v3 token registry already lists a glyph on this exact slot, independently of
  the handoff prompt.

## Global Constraints

1. **Ruling — supersedes the pre-v3 audit.** `docs/reviews/mx-text-field-deep-audit.md:542-543,826`
   ruled "no error icon exists in the design and none is expected... resolves
   to *none*, correctly." That audit is pinned to a pre-v3 baseline (commit
   `4cfddd3d`, `filled: false`, canonical M3-outlined) that wave 3 (M100.101)
   already reversed (`filled: true`, hairline border, `surfaceContainerLow`
   fill) — a change the audit itself never anticipated. The v3 redesign
   supersedes pre-v3 conventions where the two disagree (owner precedent:
   M100.99–101 already overturned other findings from the same audit
   generation). **Ruling: implement the glyph.** Cost if wrong: one icon glyph
   to remove and one test to delete; no other component depends on this slot.
2. **Ruling — icon ink extends GC-3, not the raw registry.** The registry
   (previous section) binds the message glyph to `error` (`M3_COLOR`, the
   fill). But `app_input_theme.dart`'s GC-3 (2026-09-17) already ruled the
   *message text* takes `dangerInk`, not the fill, "because it is read like
   text" — and the suffix glyph was ruled the same way for the same reason.
   A second glyph placed directly beside that text is text-adjacent content
   by the identical argument, not a boundary. **Ruling: the new icon uses
   `AppInk.error` (which resolves to `semantic.dangerInk`), matching the text
   beside it exactly — never `scheme.error` directly.** Cost if wrong: one
   `ink:` argument to flip; no border or theme file changes ride on this.
3. **No theme changes.** `app_input_theme.dart` is fully v3-bound already
   (fill, border, hint/error text style, suffix colour, disabled blend all
   carry `M100.101`/`M100.99` comments). Do not add a role, do not touch
   `InputDecorationTheme`. If a role this task needs turns out to be missing
   from the theme, STOP and report the gap — do not patch a colour into the
   widget to route around it.
4. **`MxTextField`'s public API does not grow.** `errorText` stays a
   `String?`; no new constructor parameter for the icon (it is not
   caller-configurable — the handoff makes it a component-owned fixed
   dimension, not a variant). Caller-owned stays caller-owned: the message
   text and when the error tone applies are supplied by the caller exactly as
   today.
5. **Reuse the existing vocabulary; add nothing new.**
   - Icon: `Icons.error_outline` — the app's one existing mapping for this
     meaning (`mx_dialog_tone.dart`, `mx_feedback_band.dart`,
     `mx_error_state.dart`, the card-import widgets all use it for the same
     "alert/failure" concept). Do not introduce a second glyph for the same
     meaning.
   - Size: `MxIconSize.sm` (`AppIconSize.sm` = 16) — matches the handoff's
     `alert-circle 16` exactly; it is already the app's "inline with body
     text" step.
   - Gap: `AppSpacing.xs` (4) — "micro gap between an icon and its label,"
     matches the handoff's leading `4` in `padding 4 4 0`.
   - Widget: `MxIcon` (`lib/shared/widgets/mx_icon.dart`) — "the icon that
     stands on its own ground," which this is (not inside an already-themed
     slot). `const MxIcon(Icons.error_outline, ink: AppInk.error, size:
     MxIconSize.sm)`. Decorative: pass no `semanticLabel` — the adjacent error
     text already carries the meaning, and `MxIcon`'s own doc says a
     decorative glyph beside a label that already says the thing must stay
     silent.
   - Max lines / overflow: reuse the existing `_maxMessageLines` constant
     (already 3, already reasoned about in the file) — do not add a second
     line-count constant.
6. **Layout stability holds.** The existing contract test
   ("an arriving error moves nothing below a reserved field") must keep
   passing unmodified — the icon adds width, not height, to the subtext row.
   If it cannot be made to hold, STOP and report rather than shipping a field
   that jumps when an error arrives.
7. **Tests:** TDD — add the new assertions first, watch them fail against the
   current plain-text error render, then implement. Never delete, skip,
   `exclude`, or comment out an existing test. The existing "the message
   itself is text" assertion (`mx_text_field_contract_test.dart` ~line
   235-238, `RenderParagraph` + `dangerInk`) must still pass unmodified — it
   is still true, just now reached through a `Row` instead of directly.
8. **House style:** guard clauses and early return, no `else` after `return`,
   no magic numbers (name them via existing tokens), no colour literal, no
   `DateTime.now()`, no user-visible string. Keep `mx_text_field.dart` under
   400 lines (it is 370 today; this task adds roughly 15-20).
9. **Goldens: do not touch them, do not run `--update-goldens`.** The visual
   output changes (an icon now paints in every error-state golden), so six
   PNGs go stale: `mx_text_field_error_{light,dark}`,
   `mx_text_field_focused_error_{light,dark}`,
   `mx_text_field_suffix_error_{light,dark}`. Goldens are authored on Linux
   only (repo rule) — name the stale files in the report; the controller
   regenerates them on WSL after this task's review is clean.
10. **Verification before every commit** — all must pass, and the report
    quotes each result line:
    - `dart format --output=none --set-exit-if-changed <every changed .dart file>`
    - `flutter analyze --no-fatal-infos` → `No issues found!`
    - `flutter test --exclude-tags golden -r failures-only` → `All tests passed!`
      (run at minimum `test/shared/widgets/mx_text_field_contract_test.dart`
      and `test/shared/widgets/mx_text_field_counter_test.dart`, plus the full
      exclude-tags-golden suite if time allows)
    - `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` → no errors
    - then `git checkout -- design_audit/` if that directory shows as modified
      — the suite rewrites those tracked reports as a side effect of running.
    Never run `--update-goldens`.
11. **Commits:** Conventional Commits, scope `shared` (this widget lives under
    `lib/shared/widgets/`). Do not push, open PRs, or dispatch subagents.

---

### Task 1: The error message row gains its glyph

**Files:**
- Modify: `lib/shared/widgets/mx_text_field.dart`
- Modify: `test/shared/widgets/mx_text_field_contract_test.dart`

**Interfaces:**
- Consumes: `MxIcon`, `AppInk.error`, `AppIconSize.sm` (via `MxIconSize.sm`),
  `AppSpacing.xs`, the existing `_maxMessageLines` constant, and
  `Theme.of(context).inputDecorationTheme.errorStyle` (already resolved to
  `dangerInk` by `app_input_theme.dart` — read it, do not re-derive the
  colour).
- Produces: no new public API. `MxTextField`'s rendered error state now shows
  an icon; its constructor signature is unchanged.

- [ ] **Step 1: Write the failing tests**

  Add to `test/shared/widgets/mx_text_field_contract_test.dart`, inside a new
  `group('error glyph', ...)` near the existing `focused error` group:

  - A field built with `errorText: 'Enter 1–500'` shows exactly one
    `Icons.error_outline` glyph: `expect(find.byIcon(Icons.error_outline),
    findsOneWidget)`.
  - The same field built with `errorText: null` shows none:
    `expect(find.byIcon(Icons.error_outline), findsNothing)`.
  - The glyph's colour matches the message text's colour exactly, in both
    light and dark (reuse the `for (final mode in ...)` light/dark loop
    pattern already in this file). Read the glyph's colour off the `Icon`
    widget inside the `MxIcon` (`tester.widget<Icon>(find.descendant(of:
    find.byType(MxIcon), matching: find.byIcon(Icons.error_outline))).color`)
    and assert it equals `theme.extension<AppSemanticColors>()!.dangerInk` —
    the same value the existing test already asserts for the error text at
    line ~238.
  - The existing "an arriving error moves nothing below a reserved field"
    test (line ~35) must still pass with no changes to its body — re-run it
    after implementing, do not weaken its assertions to make it pass.

  Run `flutter test test/shared/widgets/mx_text_field_contract_test.dart -r
  failures-only` and confirm the three new assertions fail (glyph not found /
  colour null) while the untouched tests still pass.

- [ ] **Step 2: Give `MxTextField` an error-row builder**

  In `lib/shared/widgets/mx_text_field.dart`:
  - Add `import 'mx_icon.dart';` (the file already imports `app_ink.dart`,
    so `AppInk` is in scope; add `import '../core/theme/foundations/app_spacing.dart';`
    if not already reachable — check the existing import for
    `app_sizing.dart` and add the sibling).
  - Add a private method:
    ```dart
    /// The error row's glyph plus its message, replacing the framework's
    /// plain `errorText` so the v3 handoff's icon can sit beside it.
    ///
    /// `InputDecoration.error` (a widget) is mutually exclusive with
    /// `errorText` (a string) but functionally equivalent for every other
    /// state `InputDecorator` derives from it — the border, the suffix
    /// colour and the focused-error stroke all key off "is one of the two
    /// non-null", not off which one.
    Widget? _buildError(BuildContext context) {
      final message = errorText;
      if (message == null) return null;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const MxIcon(Icons.error_outline, ink: AppInk.error, size: MxIconSize.sm),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              maxLines: _maxMessageLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).inputDecorationTheme.errorStyle,
            ),
          ),
        ],
      );
    }
    ```
  - In `build()`, replace `errorText: errorText` and `errorMaxLines:
    _maxMessageLines` in the `InputDecoration(...)` with `error:
    _buildError(context)`. Leave `helperText`/`helperMaxLines` exactly as they
    are — the mutual-exclusivity between helper and error is
    `InputDecorator`'s own behaviour and needs no change here.

- [ ] **Step 3: Verify, do not assume**

  Run, in order, and quote each result line in the report:
  1. `flutter test test/shared/widgets/mx_text_field_contract_test.dart -r failures-only`
     — every test in the file, including the three new ones and the
     unmodified layout-stability test, must pass.
  2. `flutter test test/shared/widgets/mx_text_field_counter_test.dart -r failures-only`
  3. `dart format --output=none --set-exit-if-changed lib/shared/widgets/mx_text_field.dart test/shared/widgets/mx_text_field_contract_test.dart`
  4. `flutter analyze --no-fatal-infos`
  5. `flutter test --exclude-tags golden -r failures-only` (full suite; if this
     is too slow to run to completion, run it and report whatever it reaches,
     and say so explicitly rather than skipping it silently)
  6. `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7`
  7. `git status --porcelain design_audit/` — if non-empty, `git checkout -- design_audit/`

  If any check fails for a reason this task's change plausibly caused, fix it
  before reporting DONE. If a failure is clearly pre-existing and unrelated,
  name it in the report rather than silently working around it.

- [ ] **Step 4: Commit**

  `feat(shared): the error message row gains its glyph (v3 TextField)` — body
  references the handoff and `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md:340`.
  Do not push.
