# A14 — remaining shared compositions, deep audit

| | |
|---|---|
| **Status** | report only — no production, theme, test, Widgetbook or golden file changed |
| **Purpose** | Prove that no shared UI primitive or composition under `lib/shared/widgets/` fell between the prior deep audits — enumerate every file, map what is already covered, and audit everything that is not |
| **Scope** | Every file in `lib/shared/widgets/` (43 files), their production callers under `lib/`, and the tests/Widgetbook/golden entries that cover them |
| **Audited against** | `main` @ `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` (**BASE_SHA**) |
| **Not in scope** | Re-auditing `MxCard`, `MxActionButton`/`MxTextButton`, `MxTextField`/`MxSearchField`, `MxListTile`/`MxRadioRows`/`MxCheckboxRow`/`MxSwitchRow`, `MxPillButton`/`MxFocusRing` beyond verifying composition boundaries — see §2 |
| **Last updated** | 2026-09-03 |

**Method.** Every file was read in full. Caller counts are `grep -rl` over
`lib/features/**` and `lib/app/**` for each public class name or top-level
function, cross-checked by hand where a name collides with prose (e.g.
`MxIcon` inside doc comments). Test and Widgetbook counts are files that
reference the symbol, not assertion counts. No probe harness was run and no
widget was rendered — this is a static-evidence pass, unlike the four prior
audits, which measured render output. Where a claim needed render-level
confirmation it is marked **unverified at render level** rather than stated as
fact.

---

## 1. Executive verdict

**No shared primitive is missing a home, and none is silently duplicating a
lower primitive's job — with one exception.** `MxActionSheet`'s row
(`_SheetRow`, `mx_action_sheet.dart:126-188`) builds a raw `ListTile` instead
of composing `MxListTile`, and it is the *only* place in `lib/shared/widgets/`
that does this. `MxListTile` cannot currently express what the row needs (a
per-instance destructive text/icon tint), so this is not a careless mistake —
but the row inherits none of `MxListTile`'s row contract: no
`AppInteractionStates.rowOverlay`, and critically, **no focus ring**, on a row
that Material still makes keyboard-focusable. This is the same defect class
the row audit (`mx-list-tile-deep-audit.md`) already found and fixed for
`MxListTile` itself — it just did not know a second, unrelated row existed.
**P1** — see F1.

**The rest of the previously-unaudited inventory is in good shape.** Twenty-
nine files were not the subject of any of the four prior deep audits. Of
those, one is genuinely dead in production with zero test coverage
(`mxWriteFailure` reachable-but-inert path — no, see correction below), one
is a documented, deliberate zero-caller component (`MxAlertDialog`, tracked at
WBS M99.59), and the remainder range from true primitives (`MxIcon`,
`MxProgressBar`, `MxPressable`) through well-composed structural widgets
(`MxContentShell`, `MxSessionTopBar`, `MxHeroCard`) to overlay plumbing
(`MxFormHost`, `MxAsyncConfirmDialog`) — all correctly composing the lower
primitives the four prior audits already cleared. Two components carry a
known, self-documented defect that has not yet been closed (F5, F6). None
qualifies as a misplaced feature widget — every file stayed generic across
its own doc comment's stated reason for existing.

**Correction made during this audit, recorded rather than silently fixed:**
the first pass of this audit flagged `lib/shared/widgets/mx_failure_labels_widget.dart`
(`MxFailureLabels.mxWriteFailure`) as dead code, because
`grep -rn "\.mxWriteFailure("` over `lib/features/` returned nothing. That
grep was wrong: five feature-level extensions
(`CardFailureLabels.cardWriteFailure`, `TagLabels.tagCatalogWriteFailure`,
`DeckLabels.deckWriteFailure`, `SettingsLabels.settingsWriteFailure`,
`TrashLabels.trashWriteFailure`) call `mxWriteFailure(` **unqualified**, from
inside their own `BuildContext` extensions — a valid call with no `.` prefix,
which the pattern missed entirely. `mxWriteFailure` is a live, well-adopted
primitive with five production consumers. What survives from that near-miss
is a real, narrower finding: **none of the five consumers, nor the shared
extension itself, has a single test** — the "exhaustive switch, no `_` branch"
safety property the doc comment leans on has never been exercised by a test
that would catch a regression. **P2** — see F7.

**Shared → feature dependency boundary: clean.** `grep -rn "import.*features/"`
and the `/app/` equivalent over `lib/shared/` return nothing. No finding here;
recorded as a verified-clean check rather than left unstated.

---

## 2. Coverage map — what A1–A13 actually covered

No file in this repository is literally titled `A1` … `A13`; the four "deep
audit" reports that exist are named by component family:

| Family (task's shorthand) | Report | In-scope files |
|---|---|---|
| Button | `mx-action-button-deep-audit.md` | `mx_action_button.dart`, `mx_text_button.dart` |
| Row | `mx-list-tile-deep-audit.md` | `mx_list_tile.dart`, and — by its own stated scope, "every row-like shared widget" — `mx_radio_rows.dart`, `mx_checkbox_row.dart`, `mx_switch_row.dart`, with `mx_pressable.dart` and `mx_breadcrumb.dart`/`mx_menu_button.dart` touched for the `Material(transparency)` shim and token comparisons only |
| Chip | `mx-chip-pill-deep-audit.md` | `mx_pill_button.dart`, `mx_focus_ring.dart` |
| Input | `mx-text-field-deep-audit.md` | `mx_text_field.dart`, `mx_search_field.dart` |
| Card | *(no standalone report; closed through implementation passes M99.83/M100.18–33, not an audit doc)* | `mx_card.dart` |

The task explicitly excludes re-auditing these five families "except to
verify composition boundaries" — done in §7. That leaves **29 of 43 files**
(the rest of the inventory in §3) with no prior deep-audit coverage. This
report is that audit.

---

## 3. Complete shared inventory

All 43 files under `lib/shared/widgets/`, their public exports, and where
each stands. **Callers** counts feature/app files referencing the symbol
(class or top-level function), not call sites. **Test / WBook** count files,
not assertions. **Prior audit** names the report that already covers the
row, blank if none.

| File | LOC | Public export(s) | Callers | Test files | WBook | Prior audit |
|---|---:|---|---:|---:|---:|---|
| `mx_action_button.dart` | 477 | `MxActionButton` | — | — | — | Button |
| `mx_text_button.dart` | 239 | `MxTextButton` | — | — | — | Button |
| `mx_list_tile.dart` | 128 | `MxListTile` | — | — | — | Row |
| `mx_radio_rows.dart` | 125 | `MxRadioRows` | 2 | 2 | 1 | Row |
| `mx_checkbox_row.dart` | 46 | `MxCheckboxRow` | 1 | 1 | 1 | Row |
| `mx_switch_row.dart` | 84 | `MxSwitchRow` | 3 | 2 | 1 | Row |
| `mx_pill_button.dart` | 198 | `MxPillButton` | — | — | — | Chip |
| `mx_focus_ring.dart` | 83 | `MxFocusRing` | — | — | — | Chip |
| `mx_text_field.dart` | 283 | `MxTextField`, `MxTextFieldAction` | — | — | — | Input |
| `mx_search_field.dart` | 220 | `MxSearchField` | 3 | 9 | 1 | Input |
| `mx_card.dart` | 807 | `MxCard` | — | — | — | Card (excluded, no re-audit) |
| `mx_pressable.dart` | 79 | `MxPressable` | — | 4 | 1 | Row (F13.4 only — shim touched) |
| `mx_content_shell.dart` | 388 | `MxContentShell`, `MxSubheaderBand`, `mxScreenGutter` | 23 / 1 / 13 | 35 | 1 | **none — audited below** |
| `mx_session_top_bar.dart` | 257 | `MxSessionTopBar` | 1 | 2 | 1 | **none** |
| `mx_hero_card.dart` | 117 | `MxHeroCard`, `MxHeroPrimary` | 2 / 2 | 1 / 2 | 1 | **none** |
| `mx_metric_well.dart` | 58 | `MxMetricWell` | 5 | 5 | 1 | **none** |
| `mx_feedback_band.dart` | 140 | `MxFeedbackBand` | 6 | 1 | 1 | **none** |
| `mx_progress_bar.dart` | 199 | `MxProgressBar`, `MxProgressBarSize`, `MxProgressBarShape` | 3 | 10 | 1 | **none** |
| `mx_breadcrumb.dart` | 426 | `MxBreadcrumb`, `MxBreadcrumbItem` | 7 / 4 | 7 | 1 | **none** (token value only in Row audit F7.3) |
| `mx_breadcrumb_step.dart` | 205 | *(none — `part of mx_breadcrumb.dart`, all-private)* | n/a | n/a | n/a | **none** |
| `mx_empty_state.dart` | 118 | `MxEmptyState` | 21 | 24 | 1 | **none** |
| `mx_error_state.dart` | 109 | `MxErrorState` | 20 | 29 | 2 | **none** |
| `mx_loading_state.dart` | 45 | `MxLoadingState` | 6 | 21 | 1 | **none** |
| `mx_async_view.dart` | 124 | `MxAsyncView` | 18 | 6 | 1 | **none** |
| `mx_navigation_bar.dart` | 132 | `MxNavigationBar`, `widthPerNavigationDestination` | 1 | 24 | 1 | **none** |
| `mx_fab.dart` | 48 | `MxFab` | 1 | 2 | 1 | **none** |
| `mx_icon_button.dart` | 124 | `MxIconButton`, `MxIconButtonTone` | 16 | 11 | 1 | **none** |
| `mx_icon.dart` | 107 | `MxIcon`, `MxIconSize` | 34 | 3 | 1 | **none** |
| `mx_button_pair.dart` | 304 | `MxButtonPair` | 9 | 7 | 1 | **none** |
| `mx_menu_button.dart` | 121 | `MxMenuButton`, `MxMenuAction` | 4 | 3 | 1 | **none** |
| `mx_dropdown.dart` | 65 | `MxDropdown`, `MxDropdownOption` | 2 | 1 | 1 | **none** |
| `mx_action_sheet.dart` | 188 | `MxActionSheet`, `MxActionSheetAction`, `MxActionSheetActionVariant` | 6 | 4 | 2 | **none — F1** |
| `mx_confirm_dialog.dart` | 216 | `MxConfirmDialog`, `MxConfirmDialogVariant`, `showMxConfirm` | 4 / — / 6 | 12 | 2 | **none** |
| `mx_alert_dialog.dart` | 101 | `MxAlertDialog`, `showMxAlert` | 0 / 0 | 1 | 1 | **none — F2 (verified-clean)** |
| `mx_form_dialog.dart` | 290 | `MxFormDialog`, `showMxPromptDialog`, `MxPromptParse` | 0 / 1 | 3 | 1 | **none** |
| `mx_async_confirm_dialog.dart` | 208 | `MxAsyncConfirmDialog`, `MxConfirmCloseWhen`, `showMxAsyncConfirm` | 4 / — / 4 | 3 | 0 | **none — F8** |
| `mx_dialog_tone.dart` | 122 | `MxDialogTone`, `MxDialogToneX`, `MxDialogHeader` | n/a / n/a / 0\* | 1 | 0 | **none** |
| `mx_dialog_metrics.dart` | 58 | `MxDialogMetrics` | 0\* | 2 | 0 | **none** |
| `mx_form_sheet.dart` | 102 | `showMxFormSheet`, `MxFormHost` | 5 / 1 | 2 | 0 | **none — F9** |
| `mx_sheet_insets.dart` | 64 | `MxSheetInsets`, `mxSheetBottomObstruction` | 2 / 1 | 2 | 1 | **none** |
| `mx_failure_labels_widget.dart` | 60 | `MxFailureLabels` (`mxWriteFailure`) | 5\*\* | 0 | 0 | **none — F7** |
| `mx_messenger.dart` | 63 | `showMxMessage`, `showMxMessageOn` | 5 / 2 | — | — | **none** |
| `mx_undo_snack_bar.dart` | 54 | `showMxUndoSnackBar`, `kMxUndoDuration` | 2 | — | — | **none** |

\* `MxDialogHeader`/`MxDialogMetrics` have zero *direct* production callers by
design — they are internal composition helpers consumed only by
`MxConfirmDialog`, `MxFormDialog` and `MxAlertDialog`, all three of which are
themselves in `lib/shared/widgets/`. Not a finding; see §5.6.
\*\* `mxWriteFailure` callers are unqualified in-extension calls; see §1's
correction.

---

## 4. Composition boundaries verified on the five excluded families

Per task instruction, Card/Button/Input/Row/Chip were not re-audited, but
every uncovered composition that touches one was checked for reimplementation
rather than reuse:

- `MxFeedbackBand` composes `MxCard.feedback` (not a hand-rolled surface) —
  clean.
- `MxEmptyState` / `MxErrorState` compose `MxActionButton` and `MxButtonPair`
  — no raw `ElevatedButton`/`TextButton`, clean.
- `MxHeroCard` **deliberately does not draw a card** — its own doc comment
  states why (four hero panels share one width rule, not one visual shape) —
  and composes `MxActionButton` via `MxHeroPrimary`. Not a violation: a
  documented, reasoned exception, not an omission.
- `MxSessionTopBar`'s private `_Chip` is **not** `MxPillButton` with a null
  callback — its own doc comment gives the reason (`MxPillButton` renders a
  null `onPressed` as *disabled*, and this is a name, not a switched-off
  control). Reasoned exception, not a violation.
- `MxConfirmDialog` / `MxFormDialog` / `MxAlertDialog` all compose
  `MxButtonPair` + `MxActionButton` + `MxDialogHeader`, never `OverflowBar` or
  a raw `TextButton` pair — clean, and this is the exact defect the button-
  pair's own doc comment says it was built to remove.
- `MxAsyncConfirmDialog` composes `MxConfirmDialog` wholesale rather than
  reimplementing its body — clean.
- **`MxActionSheet`'s `_SheetRow` builds a raw `ListTile` instead of
  `MxListTile`** — the one exception. See F1.

---

## 5. Findings

### F1 — `MxActionSheet` rows bypass `MxListTile`'s row contract, including the focus ring (P1)

**Evidence.** `mx_action_sheet.dart:149-186`, `_SheetRow.build`, constructs
`ListTile(...)` directly — the only raw `ListTile(` in `lib/shared/widgets/`
outside `mx_list_tile.dart`, `mx_radio_rows.dart`, `mx_checkbox_row.dart` and
`mx_switch_row.dart` (verified: `grep -rn "ListTile(" lib/shared/widgets/*.dart`
returns exactly one hit outside that family). `MxListTile`
(`mx_list_tile.dart:104-125`) wraps the same framework `ListTile` but adds
three things `_SheetRow` does not get:

1. `hoverColor`/`focusColor`/`splashColor` resolved from
   `AppInteractionStates.rowOverlay` — every other row surface in the app
   shares one overlay definition; the action sheet's rows fall back to
   `ThemeData.hoverColor` and friends, the exact "hardcoded washes with no
   seed in them" `MxListTile`'s own doc comment says a bare `ListTile`
   produces.
2. A foreground `DecoratedBox` border painted only while `_focusNode.hasFocus`
   — the row audit's own F3 finding (`mx-list-tile-deep-audit.md`, "a
   non-tappable row still takes keyboard focus and still draws the ring")
   established that `ListTile.canRequestFocus` follows `enabled`, which
   defaults true; `_SheetRow` sets `enabled: action.isEnabled` with no
   `focusNode` and no ring, so an enabled action-sheet row is Tab-reachable
   and renders **no visible focus indicator at all**.
3. `MxListTile`'s API is closed and asserted by
   `test/app/shared_api_closure_test.dart` (AD-23) — `_SheetRow` sits outside
   that guarantee entirely, so a future change to the row grammar can silently
   diverge here without the closure test noticing.

**Why it wasn't just switched over during this audit.** `MxListTile.title` is
a plain `String` rendered at a fixed theme colour; `_SheetRow` needs the
title/leading ink to vary per row (`AppInk.danger` for destructive,
`AppInk.disabled` for a disabled action, `AppInk.stated` otherwise) — a need
`MxListTile` cannot express today, by design (its closed API is the row
audit's own recommendation to protect, F2 in that report). Composing
`MxListTile` as-is would either lose the destructive-tint requirement or force
an escape hatch onto the one shared widget the prior audit singled out as
"the least drift-prone shared widget in the repo." Neither is free.

**Test-coverage confirmation.** `test/shared/widgets/mx_surface_components_test.dart`
(`group('MxActionSheet')`) asserts taps, colours and content, but no test in
the repository asserts focus behaviour for `MxActionSheet` rows — confirmed
by `grep -n "focus" test/shared/widgets/mx_surface_components_test.dart`,
which only matches `MxConfirmDialog`'s autofocus tests in the same file.

**Classification.** Reusable composition with a genuine, undocumented
composition-boundary gap — not a misplaced feature widget (the sheet itself
is correctly generic and shared-owned).

**Closure test (not written here — report only).** A widget test asserting
that a `Semantics` node for an enabled `_SheetRow` reports `isFocusable: true`
plus a golden or `find.byWidgetPredicate` check that a focused row paints a
visible ring, matching the pattern `mx_list_tile_test.dart` already uses for
`MxListTile`'s own focus ring.

**Implementation options for the next pass, not decided here:**
(a) extend `MxListTile`'s closed API with a narrowly-scoped `titleInk: AppInk?`
override, arguing the case in the same review that guards the API today; or
(b) give `_SheetRow` its own `AppInteractionStates.rowOverlay` + focus ring
directly, accepting one more site that owns the shim (a fifth, per the row
audit's F13.4 tally, which already counts four). Either closes the gap; which
one is an owner decision, not this audit's to make.

---

### F2 — `MxAlertDialog` / `showMxAlert`: zero production callers, verified deliberate (informational, not a defect)

**Evidence.** `grep -rl "MxAlertDialog\b\|showMxAlert\b" lib/features lib/app`
returns nothing. `mx_alert_dialog.dart:14-27`'s own doc comment states this
outright ("It has no caller in this app yet, and that is recorded rather than
hidden") and cites `docs/wbs.md` M99.59, which records the same decision:
*"Cố ý chưa trả"* (deliberately not yet paid down) — three other channels
(error band, `SnackBar`, confirm-dialog body) already cover every failure-
reporting case examined, and the component stays because deleting a primitive
to hit a line-count is "an exchange made on the wrong terms" (WBS, same
entry).

**Classification.** Legitimate helper, dead-zero-caller by design, already
tracked. No action item; recorded here only because the task requires A14 to
name every zero-caller component and confirm which are decisions versus
defects.

---

### F3 — `MxIcon`'s doc comment cites a stale defect on `MxMetricWell` (P3, documentation only)

**Evidence.** `mx_icon.dart:63-69` says: *"`MxMetricWell` takes a `Color`
parameter, which is its own defect and belongs to the API cleanup, not
here."* Current `mx_metric_well.dart:28-43` shows `tint` is already an
`AppInk` (converted at M100.5, per its own doc comment) — the remaining
`Color?` parameter is `wellColor`, the background well colour, which the
class doc explicitly defends as intentionally overridable ("the deck hero
genuinely moves it with the deck's state"). The cross-reference in
`mx_icon.dart` was accurate before M100.5 and was not updated after.

**Classification.** Stale cross-file doc comment, not a code defect —
`wellColor` remaining `Color?` is a documented, reasoned decision, not the
open item `mx_icon.dart` still implies. **P3** — fix the sentence in
`mx_icon.dart` to name `wellColor` specifically, or remove the claim; either
is a one-line diff for the implementation pass, not this report.

---

### F4 — `mx_breadcrumb_step.dart` is a `part` file with no independent public surface (informational)

**Evidence.** `mx_breadcrumb_step.dart:7` — `part of 'mx_breadcrumb.dart'`;
every declared type (`_MxBreadcrumbStep`, `_MxBreadcrumbStepState`,
`_MxBreadcrumbSeparator`) is private. The file exists only because
`mx_breadcrumb.dart` hit the project's 400-line guard (its own header comment
says so).

**Classification.** Not a component in its own right — cannot be audited
against the 9 dimensions because it has no public class, no independent
caller and no independent test target; it is exercised entirely through
`MxBreadcrumb`'s own tests. Listed in the inventory (§3) to satisfy "enumerate
every file," not counted among the 29 uncovered components.

---

### F5 — `MxDropdown` has materially less design attention than every sibling primitive (P2)

**Evidence.** `mx_dropdown.dart` (65 lines) has no owner-review commentary, no
disabled-state discussion, no error/validation slot, and wraps
`DropdownButtonHideUnderline(DropdownButton(isExpanded: true))` with a single
paragraph of rationale — contrasted with every other control-family primitive
in this inventory (`MxMenuButton`, `MxButtonPair`, `MxProgressBar`), all of
which carry measured rationale for every non-obvious choice. Two production
callers (`grep -rl "\bMxDropdown\b" lib/features lib/app`), one test file, one
Widgetbook entry. `DropdownButton`'s `onChanged: null` auto-disables per
Flutter's own contract, so the *behaviour* is not wrong — but there is no
recorded decision about how a validation error on the selected value should
read (the two production call sites are import-mapping rows, which currently
have no error slot of their own either).

**Classification.** True primitive, functioning correctly, under-documented
relative to its siblings. **P2** — not a behavioural bug; flagged because the
task's dimension 5/6 (layout/typography/state ownership, a11y/responsive)
found nothing to verify against for the disabled and error cases specifically,
which is a coverage gap rather than a proven defect. Closure: add the same
owner-review-style rationale the rest of the family carries, and a
`mx_dropdown_test.dart` case for the disabled (`onChanged: null`) state if the
next form work needs one.

---

### F6 — `MxDialogHeader`/`MxDialogMetrics` have no Widgetbook entry (P3)

**Evidence.** §3: both show `WBook = 0`. Both are consumed exclusively by
`MxConfirmDialog`, `MxFormDialog` and `MxAlertDialog`, all three of which
already have Widgetbook stories that render `MxDialogHeader` inside them —
so the visual is catalogued, just not addressably as its own entry.

**Classification.** Legitimate helper — not a coverage gap in practice, since
no screen renders these components without one of the three dialogs around
them, and a standalone catalog entry would show a header outside the frame it
always appears in (the same reasoning `mx_form_sheet.dart`'s own WBS entry,
M4.10as, gives for deferring `MxFormHost`'s Widgetbook entry). **P3**,
informational only.

---

### F7 — `mxWriteFailure` and its five feature wrappers have zero test coverage (P2)

**Evidence.** See §1's correction for the caller count (5, not 0).
`grep -rl "mxWriteFailure" test/` and
`grep -rl "cardWriteFailure\|deckWriteFailure\|trashWriteFailure\|settingsWriteFailure\|tagCatalogWriteFailure" test/`
both return nothing. The shared extension's own doc comment
(`mx_failure_labels_widget.dart:12-18`) states its entire value proposition is
the exhaustive `switch` with no `_` branch — a compile-time guarantee that a
new `Failure` subtype cannot silently fall through. That guarantee is real and
enforced by the compiler regardless of tests. What is untested is the
*mapping* itself: whether `NotFoundFailure`/`ConflictFailure` route to the
right feature-supplied callback, and whether the five feature-level
extensions (`CardFailureLabels`, `TagLabels`, `DeckLabels`,
`SettingsLabels`, `TrashLabels`) correctly narrow their own `ConflictFailure`
reasons. A rename or a reordering that silently swapped `onNotFound` and
`onConflict` at any of the five call sites would compile clean and fail
nothing in CI.

**Classification.** True primitive, correctly adopted, under-tested. **P2** —
dimension 8 (test coverage) gap on a component whose only stated safety
property is otherwise unverified at the mapping level. Closure: one test per
feature wrapper asserting `NotFoundFailure` and each `ConflictFailure` reason
map to the expected string, following the pattern already used for the
`_labels_widget.dart` files that do have tests elsewhere in the codebase.

---

### F8 — `MxAsyncConfirmDialog` has no Widgetbook entry (P3)

**Evidence.** §3: `WBook = 0`, `test = 3`. It wraps `MxConfirmDialog` (which
has 2 Widgetbook entries) and adds only behaviour (the `didUpdateWidget`
transition watch), not new visual surface — its own doc comment frames it as
"the other half of the confirmation story," not a new look.

**Classification.** Legitimate helper — behaviourally distinct, visually
identical to an already-catalogued component. **P3**, informational: a
Widgetbook entry would mostly demonstrate the `isBlocked`/`closeWhen` wiring
rather than new visuals, which is arguably better shown by its own tests than
by a static catalog page. Not required for DoD in the strict sense (no new
*visual* surface), but worth a knob if the next overlay pass touches this
file anyway.

---

### F9 — `showMxFormSheet` / `MxFormHost`: deferred Widgetbook entry is tracked, not forgotten (informational)

**Evidence.** §3: `WBook = 0`. `docs/wbs.md` M4.10as records the decision
explicitly: neither has an independent layout — `MxFailureLabelsWidget`
(sic, the old file name) "contains no widget at all," and `MxFormSheet` is "a
`showModalBottomSheet` configuration plus a host that returns its child
whole" — so a catalog entry would display the *caller's* form, not the
component. The entry defers to "when Card's editor exists, there is a real
form to show."

**Classification.** Legitimate helper, deferral already tracked and reasoned.
No new action; card's editor now exists in production (`card_failure_labels_widget.dart`,
confirmed live in F1's correction), so the condition M4.10as named as the
trigger for adding the entry has already occurred — **worth flagging to the
owner as a stale deferral condition**, not as a defect of this component.
**P3.**

---

## 6. The 29 previously-uncovered components — full classification

| Component | Purpose (1) | Callers (2) | Ownership (3) | Theme/primitive deps (4) | Layout/state ownership (5) | A11y/responsive (6) | Escape hatches (7) | Coverage (8) | Classification (9) |
|---|---|---:|---|---|---|---|---|---|---|
| `MxContentShell`/`MxSubheaderBand` | Screen scaffold: app bar, gutters, pinned subheader, footer | 23/1 | Shared | `AppBreakpoints`, `AppSpacing`, `theme_context_extension`, composes `MxBreadcrumb.compactLineHeight` | Owns scroll-hairline state (`_hasScrolled`), responsive padding | Responsive gutter (16/12 @ compact), text-scale-aware toolbar height; no explicit a11y gap found | `padding`, `titleSubline` — both argued at length in doc comments | 35 test files, 1 WBook | **True primitive / reusable composition** — the app's one screen frame |
| `MxSessionTopBar` | Full-screen task top bar: close, chip, progress, figure | 1 | Shared (generic, no study-mode knowledge) | Composes `MxIconButton`, `MxProgressBar`, `mxScreenGutter` | Owns responsive chip-cap math via `LayoutBuilder` | Documented touch-target math (48dp close button); `_leadingInset` clamp explicitly fixes a compact-width crash | None — every visual is fixed | 2 test, 1 WBook | **Reusable composition** — one caller today (study session), correctly generic |
| `MxHeroCard`/`MxHeroPrimary` | Leading-panel width contract (stretch below compact tier) | 2/2 | Shared | `AppBreakpoints`, composes `MxActionButton` | Pure layout measurement widget — deliberately draws no card | Responsive by construction (that is its entire purpose) | None | 1/2 test, 1 WBook | **True primitive** — a measurement contract, not a visual one |
| `MxMetricWell` | Icon well behind a metric figure | 5 | Shared | `AppRadius`, `AppSpacing`, `AppInk`, composes `MxIcon` | Stateless, no responsive logic needed | N/A (decorative well) | `wellColor: Color?` — documented, reasoned (F3 notes a stale cross-reference, not a live defect) | 5 test, 1 WBook | **True primitive** |
| `MxFeedbackBand` | Inline failure band with optional action | 6 | Shared | Composes `MxCard.feedback`, `MxIcon`, `MxTextButton` | Owns the live-region announcement | `liveRegion` + `container` semantics, explicit action-pair assert (mirrors `MxEmptyState`/`MxErrorState`) | None beyond `actionLabel`/`onAction` | 1 test, 1 WBook | **Reusable composition** |
| `MxProgressBar` | Determinate progress track | 3 | Shared | `AppDurations`, `AppMotionPolicy`, `AppRadius`, `AppSpacing` | Owns animated-value tween, reduced-motion collapse | `Semantics(label, value)` with `ExcludeSemantics` on the visual tree — correct pattern; ta­bular figures for a ticking value | `shape: pill/flush` — a named enum, not a raw radius | 10 test, 1 WBook | **True primitive** |
| `MxBreadcrumb`/`MxBreadcrumbItem` | Hierarchy path, folds past `collapseAfter` | 7/4 | Shared (generic `label`/`onTap`, no domain type) | `AppIconSize`, `AppSizing`, `AppSpacing`, `AppTypography`, composes `MxIcon` | Owns fold/expand state, single-target vs multi-step layout, glyph-width measurement | 48dp step targets, single-target strip mode explicitly built to fix under-floor targets (owner review 2026-08-21); horizontal-scroll a11y semantics container | None public | 7 test, 1 WBook | **True primitive** — most structurally complex file in the uncovered set |
| `mx_breadcrumb_step.dart` | Private `part` of `MxBreadcrumb` | n/a | n/a | n/a | n/a | n/a | n/a | n/a | **Not independently classifiable** — see F4 |
| `MxEmptyState` | "Nothing here, and that's fine" state | 21 | Shared | Composes `MxIcon`, `MxButtonPair`, `MxActionButton` | Owns primary/secondary action-pair assert logic | Explicit assert pairs (label⇔callback); secondary requires primary | `icon: IconData` default overridable | 24 test, 1 WBook | **True primitive** |
| `MxErrorState` | Retryable failure state | 20 | Shared | Composes `MxIcon`, `MxActionButton` | Owns `isRetrying` → button-loading wiring | Assert pairs for retry label/callback; `isRetrying` prevents "the button lied" bug (documented regression) | None | 29 test, 2 WBook | **True primitive** |
| `MxLoadingState` | Centred spinner with a11y label | 6 | Shared | `AppSpacing` only | `RepaintBoundary` isolation — documented perf fix (10 extra paints/frame measured) | Required `semanticsLabel`; deliberately no `color:` override (documented regression: overriding it broke contrast at 2.81:1) | None | 21 test, 1 WBook | **True primitive** |
| `MxAsyncView` | Renders `AsyncValue<T>`'s 3 cases with one loading policy | 18 | Shared, generic on `T` | Composes `MxLoadingState` | Owns `skipLoadingOnRefresh`/`shouldSkipLoadingOnReload` policy | Loading label required (a11y); no default error copy by design (prevents generic "something went wrong" sprawl) | `loadingFrame` builder | 6 test, 1 WBook | **True primitive** |
| `MxNavigationBar` | Bottom nav bar, render-only | 1 | Shared, deliberately ignorant of GoRouter | Composes framework `NavigationBar`; owns `widthPerNavigationDestination` (CSS-parity token) | Owns width-cap-vs-screen arbitration (`Flexible` + `ConstrainedBox`) | `assert(destinations.length >= 2)`; hairline border on `foreground` position — documented fix for a double-draw bug | None | 24 test, 1 WBook | **True primitive** |
| `MxFab` | Screen create/primary action | 1 | Shared | Composes framework `FloatingActionButton`; theme-only visuals | N/A | Required `label` doubles as tooltip + semantic name (documented rule, mirrors `MxIconButton`) | None — no colour/shape/elevation params, by design | 2 test, 1 WBook | **True primitive** |
| `MxIconButton` | Labeled icon-only action | 16 | Shared | `AppIconSize`, `AppSizing`, composes framework `IconButton` | `isCompact` moves the glyph, never the 48dp target (documented past-regression) | Required `semanticLabel`; a removed `isFilled` variant is documented as intentionally not restored | `tone: MxIconButtonTone` (2-value enum, not a raw colour) | 11 test, 1 WBook | **True primitive** |
| `MxIcon`/`MxIconSize` | Standalone-icon primitive | 34 | Shared | `AppIconSize`, composes `AppInk` | N/A | `semanticLabel` null → `ExcludeSemantics` (decorative); documents its own allowlist boundary vs. bare `Icon` (`icon_ink_boundary_test.dart`) | None — `ink`/`size` are both closed enums | 3 test, 1 WBook | **True primitive** — see F3 for a stale cross-reference in its own doc comment |
| `MxButtonPair` | Two actions, one size, row-or-stack | 9 | Shared | `AppSpacing`; custom `RenderBox` (`_RenderPairLayout`) | Owns the row/stack decision via intrinsic-width measurement — no `LayoutBuilder`, a render object (documented reason: `AlertDialog`'s `IntrinsicWidth` cannot host a `LayoutBuilder`) | Explicitly designed around text-scale wrapping (documents two prior wrong heuristics and why both failed at 320dp/2.0×) | `axis: Axis` (horizontal/vertical only) | 7 test, 1 WBook | **True primitive** — the most technically sophisticated widget in the uncovered set |
| `MxMenuButton`/`MxMenuAction` | Overflow/picker popup menu | 4/4 | Shared | Composes `MxIcon`; `AppSpacing` | N/A | Required `tooltip` (a11y — prevents N "more options" collisions); `isSelected` drives `initialValue` | `icon`, `isDestructive`, `isSelected` per action — all closed enums/bools | 3 test, 1 WBook | **True primitive** |
| `MxDropdown`/`MxDropdownOption` | Inline compact select | 2/— | Shared, generic on `T` | Wraps framework `DropdownButton` directly | N/A | Ellipsis on overflow; no documented disabled/error-state discussion | None | 1 test, 1 WBook | **True primitive**, under-documented — see F5 |
| `MxActionSheet`/`MxActionSheetAction` | Mobile action menu (bottom sheet) | 6/6 | Shared, "decides nothing" by design | Composes `MxIcon`; **raw `ListTile`** for rows | Owns nothing — pure list of caller-supplied actions | `SafeArea`, `isSelected` announced explicitly (not colour-only) | `isEnabled`, `isSelected`, `variant` — all closed | 4 test, 2 WBook | **Reusable composition with a boundary gap — see F1 (P1)** |
| `MxConfirmDialog`/`showMxConfirm` | Yes/no confirmation, one-shot | 4/6 | Shared, "counts nothing" | Composes `MxButtonPair`, `MxActionButton`, `MxDialogHeader`, `MxDialogMetrics` | Owns focus-on-cancel rule for destructive/cautious variants | `scrollable: true` (prevents silent truncation at 3.0× scale); live-region content | `variant`, `tone` — closed enums | 12 test, 2 WBook | **True primitive** |
| `MxAlertDialog`/`showMxAlert` | One-button statement dialog | 0/0 | Shared | Composes `MxActionButton`, `MxDialogHeader` | N/A | Required `tone` (not optional, unlike the other two dialogs) | None | 1 test, 1 WBook | **Legitimate helper, documented dead-zero-caller — see F2** |
| `MxFormDialog`/`showMxPromptDialog` | In-place single-field form dialog | 0/1 | Shared | Composes `MxButtonPair`, `MxActionButton`, `MxDialogHeader`, `MxDialogMetrics`, `MxTextField` | Owns submit/error/clear-on-edit state (`_PromptDialogState`) | Form-level vs field-level error separation documented; `TextInputAction.done` submits | `child: Widget` — one caller today | 3 test, 1 WBook | **True primitive** |
| `MxAsyncConfirmDialog`/`MxConfirmCloseWhen` | Confirmation that stays mounted through a write | 4/— | Shared | Composes `MxConfirmDialog` wholesale | Owns the settled-transition watch (`didUpdateWidget`, post-frame pop) | Post-frame pop explicitly fixes an `InheritedElement` assertion crash (documented past regression) | `closeWhen: saved/settled` — closed enum | 3 test, 0 WBook | **True primitive** — see F8 |
| `MxDialogTone`/`MxDialogToneX`/`MxDialogHeader` | Severity taxonomy + toned dialog headline | n/a/n/a/0 | Shared | Composes `MxIcon`, `AppInk` | N/A | Icon carries no semantic label (documented: avoids double-announcing) | None | 1 test, 0 WBook | **True primitive** — see F6 |
| `MxDialogMetrics` | Dialog inset/actions-padding constants | 0\* | Shared | `AppSpacing` | N/A | N/A | N/A (all `static const`) | 2 test, 0 WBook | **Legitimate helper** |
| `showMxFormSheet`/`MxFormHost` | Bottom-sheet form host with keyboard inset | 5/1 | Shared, generic on `P extends Enum` | Composes `MxSheetInsets` | Owns `shouldClose`-vs-`succeeded` transition (documented past bug: closing on `savedAndContinue`) | `isScrollControlled` + `max(viewInsets, viewPadding)` — documented fix for a keyboard-covers-submit bug | None | 2 test, 0 WBook | **True primitive** — see F9 |
| `MxSheetInsets`/`mxSheetBottomObstruction` | Bottom-sheet content padding | 2/1 | Shared | `AppSpacing` | N/A | `max`, not sum, of keyboard vs. system-bar inset — documented fix for 3 divergent hand-written copies | None | 2 test, 1 WBook | **True primitive** |
| `MxFailureLabels` (`mxWriteFailure`) | `Failure`-type → localized copy, exhaustive switch | 5\*\* | Shared | `core/error/failure.dart`, `l10n` | N/A (pure function) | N/A | Two required callbacks (`onNotFound`, `onConflict`) — closed by construction | 0 test | **True primitive, under-tested — see F7** |
| `showMxMessage`/`showMxMessageOn` | Transient message (`SnackBar`) | 5/2 | Shared | Framework `ScaffoldMessenger`/`SnackBar` | N/A | `liveRegion` announcement + queue-clear on every call (documented: unifies 7 divergent call sites) | `actionLabel`/`onAction` pair, asserted | — | **True primitive** (no dedicated test file found by name; exercised via caller tests — not independently verified, informational only, not scored as a gap given low complexity) |
| `showMxUndoSnackBar`/`kMxUndoDuration` | Undo-window snackbar | 2/— | Shared, "knows nothing about Trash" | Framework `ScaffoldMessenger`/`SnackBar` | N/A | 8s window (2× Material default, documented reasoning: large-text-scale reading time); one-shot `onUndo` | Message/label/callbacks all caller-supplied | — | **True primitive** |
| `MxPressable`/`MxPressableShape` | Ripple leg for a custom interactive surface | — | Shared | `AppRadius`, `AppSizing` | Floors content at `AppSizing.touchTarget` | Already the subject of the row audit's F13.4 (`Material(transparency)` shim asymmetry) | `shape` — closed enum | 4 test, 1 WBook | **True primitive** — touched by Row audit, not independently re-scored |

---

## 7. Shared → feature dependency audit

`grep -rn "import.*features/" lib/shared/` and the `lib/app/` equivalent both
return zero hits. `check_architecture.sh`'s guard scope (§ XI/XIV of
`flutter-theme-design/references/legacy-and-guards.md`) polices raw-widget and
style-escape rules only inside `lib/features/**`, with `lib/shared/widgets/**`
explicitly allowlisted for the widgets that *are* the wrappers — that scoping
is why F1 was not caught mechanically: the guard was never designed to check
one shared widget against another. No shared→feature import violation exists
in the current tree; the boundary this task asked A14 to also check is clean.

---

## 8. Severity registry

| ID | Severity | Finding | File(s) | Evidence | Closure test |
|---|---|---|---|---|---|
| F1 | **P1** | `MxActionSheet` rows use raw `ListTile`, inheriting no row-overlay tokens and drawing **no focus ring** on a keyboard-focusable row | `mx_action_sheet.dart:149-186` | §5, F1 — confirmed only non-family raw `ListTile(` in `lib/shared/widgets/`; no focus test exists | Widget test asserting a focused enabled action-sheet row paints a visible ring / reports `isFocusable`, mirroring `mx_list_tile_test.dart`'s own focus-ring test |
| F5 | **P2** | `MxDropdown` has no documented disabled/error-state decision, unlike every sibling primitive | `mx_dropdown.dart` | §5, F5 — 65 lines, no owner-review commentary, 1 test file | `mx_dropdown_test.dart` case for `onChanged: null`; a decision recorded on how a caller signals a validation error |
| F7 | **P2** | `mxWriteFailure` and its 5 feature wrappers have zero test coverage of the actual failure→copy mapping | `mx_failure_labels_widget.dart`, `card_failure_labels_widget.dart`, `tag_labels_widget.dart`, `deck_labels_widget.dart`, `settings_labels_widget.dart`, `trash_labels_widget.dart` | §5, F7 — `grep` for test callers of all six symbols returns nothing | One test per feature wrapper for `NotFoundFailure` + every `ConflictFailure`/reason enum value |
| F3 | **P3** | `mx_icon.dart`'s doc comment cites a stale `MxMetricWell` defect fixed at M100.5 | `mx_icon.dart:63-69` | §5, F3 | Doc-comment correction naming `wellColor` specifically (no test — documentation only) |
| F6 | **P3** | `MxDialogHeader`/`MxDialogMetrics` have no standalone Widgetbook entry | `mx_dialog_tone.dart`, `mx_dialog_metrics.dart` | §5, F6 | None required — visual already catalogued via the 3 dialogs that consume them |
| F8 | **P3** | `MxAsyncConfirmDialog` has no Widgetbook entry | `mx_async_confirm_dialog.dart` | §5, F8 | Optional — add if the next overlay pass touches this file |
| F9 | **P3** | M4.10as's stated Widgetbook-deferral trigger ("when Card's editor exists") has already occurred | `mx_form_sheet.dart` | §5, F9 | Owner decision: add the deferred entry now that Card's editor is live, or re-state the deferral condition |
| F2 | informational | `MxAlertDialog`/`showMxAlert`: zero callers, verified deliberate (WBS M99.59) | `mx_alert_dialog.dart` | §5, F2 | None — not a defect |
| §4 | verified clean | Composition boundaries on Card/Button/Row/Chip/Input families | multiple | §4 | None — no violation found |
| §7 | verified clean | Shared → feature import boundary | `lib/shared/**` | §7 | None — zero violations |

**0 P0. 1 P1. 2 P2. 5 P3 (4 of which are informational/no-code-change).**

---

## 9. Implementation order, files, owner decisions

This is a report; nothing below was implemented. Recorded so the next pass
does not have to re-derive priority.

1. **F1 (P1) first** — it is the only finding with a real, if narrow,
   accessibility gap (no focus ring on a keyboard-reachable control) and the
   only composition-boundary violation found. Owner decision needed before
   implementation: extend `MxListTile`'s closed API with a title-ink override,
   or give `_SheetRow` its own overlay/ring directly. Files:
   `mx_action_sheet.dart`, possibly `mx_list_tile.dart`,
   `test/shared/widgets/mx_surface_components_test.dart` or a new
   `mx_action_sheet_test.dart`.
2. **F7 (P2)** — test-only change, no owner decision needed, safe to batch
   with any other work touching the five `*_labels_widget.dart` files. Files:
   five new/extended test files under each feature's `presentation/widgets/support/`
   test mirror.
3. **F5 (P2)** — needs an owner decision on how `MxDropdown` should surface a
   validation error (a new optional slot vs. leaving it to the caller's
   surrounding row) before any code changes; documentation-only fix (rationale
   comment) can land without that decision.
4. **F3, F6, F8, F9 (P3)** — no urgency; bundle with whichever pass next
   touches each file. F9 specifically needs an owner call on whether the
   Widgetbook deferral condition in `docs/wbs.md` M4.10as should be closed now
   or re-justified.

---

## 10. Verdict

**REPORT ONLY. No production, theme, test, Widgetbook, golden or docs/wbs.md
file was changed by this task — `docs/reviews/a14-shared-composition-audit.md`
is the only file this branch adds.** Every file under `lib/shared/widgets/`
has been enumerated, mapped to prior coverage or audited fresh, and the
shared→feature boundary has been verified clean. One P1 (composition boundary
+ accessibility), two P2s (test coverage, documentation debt) and five P3s
(four informational) are open for a future implementation pass; none blocks
anything currently in flight.
