# MemoX v3 Handoff Full Implementation Plan

| | |
|---|---|
| **Status** | active |
| **Purpose** | Thực hiện và chứng minh parity với 50 Markdown files của MemoX v3 handoff |
| **Scope** | Four reference documents, 46 component contracts, direct consumers, Widgetbook, visual and device verification |
| **Source of truth for** | Thứ tự thực thi và bằng chứng hoàn thành redesign v3 |
| **Depends on** | `docs/design/v3/00-index.md` · `01-foundations.md` · `02-theme-binding.md` · `99-traceability.md` · `docs/wbs.md` |
| **Updated by task** | M100.122 |
| **Last updated** | 2026-09-21 |

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete every v3 component contract with a verified Flutter owner, while preserving business behaviour, data flow, routing and localized copy.

**Architecture:** `lib/core/theme/` owns colours, type, effects and Material defaults. `lib/shared/widgets/` owns reusable visual and interaction contracts. Feature widgets compose those owners with caller-supplied labels, view data and callbacks. A contract is complete only when its focused test, direct callers, Widgetbook use case and audit record all agree.

**Tech Stack:** Flutter stable · Material 3 · Dart · existing `Mx*` shared kit · Widgetbook · Flutter widget/accessibility tests · Linux/WSL golden tests.

**Spec:** `docs/design/v3/00-index.md`, `01-foundations.md`, `02-theme-binding.md`, all files in `docs/design/v3/components/`, and `99-traceability.md`.

## Global Constraints

- Do not change business rules, domain/data layers, routes, controller interfaces, or ARB copy policy.
- Resolve colour, type, spacing, radius, sizing, shadow and state through the canonical theme/token owner; no raw visual inputs or literals in a public API.
- Material 3 anatomy and supported platform semantics take priority over handoff HTML/CSS mechanics.
- StatusBar and Scrim are platform/framework-owned; verify insets and modal barrier semantics without fake app widgets.
- Preserve explicit handoff visual decisions; document measured accessibility exceptions in `docs/wbs.md` rather than silently weakening tests.
- Interactive controls retain a 48dp target and test disabled, focus/keyboard, RTL and text scale 2.0 where relevant.
- Every public new shared widget has a focused test and Widgetbook specimen. Update every direct caller in the same task as a public API migration.
- Goldens are authored only in Linux/WSL with `TZ=UTC`. Update `docs/wbs.md` with each code commit.

---

## 5Why

1. **Why re-audit before implementing?** A name-to-owner map proves only that documentation exists; it does not prove dimensions, states, semantics or consumers satisfy the handoff.
2. **Why keep theme work separate?** The contracts refer to semantic roles. Local colour fixes would fork light/dark binding and make later components drift.
3. **Why execute A through H?** Chrome and controls establish primitives that surfaces, feedback and shells compose. Dependency order prevents temporary feature-local visual recipes.
4. **Why create missing shared widgets?** Their contracts recur by semantic meaning. Screen-local copies would immediately diverge.
5. **Why close with screens, goldens and a device run?** Isolated widgets do not prove real layout, platform font rendering, system insets or interaction continuity.

## Complete Contract Map

| Wave | Contract document → owner |
|---|---|
| Audit/reference | `00-index`, `99-traceability` → `v3_handoff_coverage_test`; `01-foundations`, `02-theme-binding` → `lib/core/theme/**` |
| A | `status-bar` → platform; `app-bar` → `MxAppBar`; `bottom-nav` → `MxNavigationBar`; `breadcrumb` → `MxBreadcrumb`; `study-top-bar` → `MxSessionTopBar`; `fab` → `MxFab` |
| B | `button` → `MxActionButton`; `icon-button` → `MxIconButton`; `filter-chip` → `MxFilterChip`; `chip-trigger` → `MxChipTrigger` |
| C | `search-field` → `MxSearchField`; `text-field` → `MxTextField`; `toggle` → `MxSwitch`; `option-row` → `MxOptionRow`; `selection-checkbox` → `MxCheckboxRow`; `segmented-tray` → `MxSegmentedTray`; `stepper` → `MxStepper`; `field-message` → `MxFieldMessage` |
| D | `card` → `MxCard`; `section` → `MxSection`; `list-row` → `MxListRow`; `settings-row` → `MxSettingsRow`; `icon-tile` → `MxIconTile`; `action-sheet-command-row` → `MxActionSheet`; `list-section-header` → `MxSectionLabel` |
| E | `badge` → `MxBadge`; `status-badge` → `MxStatusBadge`; `tag-chip` → `MxTagChip`; `note` → `MxNote`; `mastery-ramp` → `MxMasteryRamp`; `workload-breakdown-line` → `MxWorkloadBreakdownLine`; `mastery-donut` → `MxMasteryDonut` |
| F | `scrim` → platform; `dialog` → `MxAlertDialog`/`MxConfirmDialog`; `bottom-sheet` → `MxSheet`; `sheet-actions` → `MxSheetActions`; `snackbar` → `MxUndoSnackBar`; `inline-banner` → `MxFeedbackBand`; `deck-picker-sheet` → `MxDeckPickerSheet` |
| G | `skeleton` → `MxSkeleton`; `spinner` → `MxSpinner`; `empty-state` → `MxEmptyState`; `error-state` → `MxErrorState` |
| H | `app-shell` → `AppNavigationShell`/`MxContentShell`; `screen-scroll` → `MxScrollEndInset`; `footer-bar` → `MxFooterBar` |

## Evidence Protocol

Each of the 46 entries in `test/design_audit/v3_handoff_coverage_test.dart` must carry: source document, owner source path, focused test path, direct-caller search command, and status (`auditing` or `verified`). The audit test only validates this evidence record. A component becomes `verified` only in its wave after focused tests pass and its call-site migration is reviewed.

### Task 1: Make the 46-contract audit truthful

**Files:** Modify `test/design_audit/v3_handoff_coverage_test.dart`, `docs/wbs.md`.

**Produces:** `V3ContractAudit(document, ownerFile, testFile, callerSearch, status)` for every contract.

- [ ] Write a failing audit that requires all five fields for all 46 contracts and checks referenced files exist.
- [ ] Run `flutter test test/design_audit/v3_handoff_coverage_test.dart`; confirm it names currently missing owner/test files.
- [ ] Populate source/test/caller evidence; mark every not-yet-reviewed item `auditing`, never `verified`.
- [ ] Run `flutter test test/design_audit/v3_handoff_coverage_test.dart` and `python .claude/skills/flutter-workflow/scripts/check_docs.py`.
- [ ] Commit `test(design): make v3 contract evidence explicit`.

### Task 2: Audit Foundations and Theme Binding

**Files:** Read `01-foundations.md`, `02-theme-binding.md`, `docs/design-system/v3-foundations.md`; modify only failed owners under `lib/core/theme/**`; test `test/core/theme/**` and `test/design_audit/audit_theme_steps.dart`.

**Produces:** all light/dark roles consumed by A–H through existing `context.colors`, `context.semanticColors`, `context.texts`, decoration and interaction-state helpers.

- [ ] Add a failing test for every consumed role absent from the theme audit: surface containers, status colours, progress track, feedback roles, focus and disabled overlays.
- [ ] Run `flutter test test/core/theme test/design_audit/audit_theme_steps.dart` and reproduce failures before editing theme code.
- [ ] Bind a missing role only in its canonical theme/foundation extension; do not add a component fallback.
- [ ] Run focused theme tests, `flutter analyze`, and `.claude/skills/flutter-architecture/scripts/check_architecture.sh`.
- [ ] Commit `feat(theme): complete v3 handoff bindings`.

### Task 3: Execute A — chrome and navigation

**Files:** `lib/shared/widgets/mx_app_bar.dart`, `mx_navigation_bar.dart`, `mx_breadcrumb.dart`, `mx_session_top_bar.dart`, `mx_fab.dart`; their tests; direct shell/feature callers; Widgetbook entries.

**Contract tests:** AppBar/BottomNav height, selected semantics, 48dp targets, light/dark and keyboard focus; Breadcrumb RTL order/focus; StudyTopBar state/accessibility; Fab size, focus and scroll clearance. StatusBar is verified by shell inset tests only.

- [ ] Add the failing contract tests above, then run `flutter test test/shared/widgets/mx_app_bar_test.dart test/shared/widgets/mx_navigation_bar_test.dart test/shared/widgets/mx_breadcrumb_test.dart test/shared/widgets/mx_fab_test.dart`.
- [ ] Correct owners through existing M3 themes/tokens; migrate direct matches from `rg 'Mx(AppBar|NavigationBar|Breadcrumb|SessionTopBar|Fab)' lib test widgetbook`.
- [ ] Run A tests plus `test/features/study/presentation/study_accessibility_test.dart`, mark only proven A audit entries `verified`, and commit `feat(design): reconcile v3 chrome`.

### Task 4: Execute B — actions and controls

**Files:** `mx_action_button.dart`, `mx_icon_button.dart`, `mx_filter_chip.dart`, `mx_chip_trigger.dart`, relevant component theme builders, focused tests and Widgetbook.

**Contract tests:** Button/IconButton default, disabled, loading, pressed and focus states; loading-width stability; FilterChip/ChipTrigger selected state, truncation, semantics, compact geometry and 48dp targets.

- [ ] Add the named failing state-matrix tests and run the matching test files before implementation.
- [ ] Correct only existing enum/theme/token owners; preserve callback and semantics labels at callers.
- [ ] Register new public variants in Widgetbook and run `test/app/shared_api_closure_test.dart`.
- [ ] Mark proven B entries `verified` and commit `feat(design): reconcile v3 action controls`.

### Task 5: Execute C — inputs and selection

**Files:** `mx_search_field.dart`, `mx_text_field.dart`, `mx_switch.dart`, `mx_option_row.dart`, `mx_checkbox_row.dart`, `mx_radio_rows.dart`, `mx_segmented_tray.dart`, `mx_stepper.dart`, `mx_field_message.dart`; focused form tests and Widgetbook.

**Contract tests:** fields’ focused/error/disabled/counter/large-text states; rows’ selected/disabled/group semantics/48dp state; tray’s 2–3 option bound, 4/2/12/32/8 geometry and exclusive semantics; stepper bounds; field-message error announcement.

- [ ] Write a failing case for every untested state/value listed above, then run all C focused tests.
- [ ] Reconcile fields and selection rows without moving validation/business rules from callers.
- [ ] Correct `MxSegmentedTray<T>`, `MxStepper`, and `MxFieldMessage` only through their typed closed APIs; migrate direct caller matches.
- [ ] Run `flutter test` over all `mx_*field*`, `mx_*row*`, `mx_switch_test.dart`, `mx_segmented_tray_test.dart`, `mx_stepper_test.dart`, and `mx_form_components_test.dart`.
- [ ] Mark C entries `verified` and commit `feat(design): complete v3 input selection`.

### Task 6: Execute D — surfaces and content

**Files:** `mx_card.dart`, `mx_section.dart`, `mx_list_row.dart`, `mx_settings_row.dart`, `mx_icon_tile.dart`, `mx_action_sheet.dart`, `mx_section_label.dart`; matching tests and Widgetbook.

**Contract tests:** Card/Section radius, internal padding, elevation, long content and theme surface; ListRow/SettingsRow/IconTile alignment, min height, truncation, RTL/focus; ActionSheet command order/destructive treatment; SectionLabel geometry.

- [ ] Add failing geometry/state tests for every item above and run the D focused suite.
- [ ] Correct existing surface/row owners using tokens; keep commands and feature state in callers.
- [ ] Migrate direct callers, register changed variants in Widgetbook, then run D tests.
- [ ] Mark D entries `verified` and commit `feat(design): reconcile v3 surfaces`.

### Task 7: Execute E — status and metadata

**Files:** modify `mx_badge.dart`, `mx_status_badge.dart`, `mx_tag_chip.dart`, `mx_mastery_ramp.dart`, `mx_mastery_donut.dart`; create `mx_note.dart`, `mx_workload_breakdown_line.dart`; create focused tests and Widgetbook entries.

**New interfaces:** `MxNote(message)`; `MxWorkloadBreakdownLine(overdue, today, newCards)`; existing `MxStatusBadge(status, {label, dotOnly})`, `MxTagChip(label, {dense})`, `MxMasteryRamp.colorFor(context, progress)`, `MxMasteryDonut(progress)` remain closed semantic APIs.

**Contract tests:** Badge/StatusBadge/TagChip geometry and non-interactive semantics; Note 10×12 padding, ghost border, 16dp glyph and multiline text; ramp thresholds at 0/33/34/66/67/100%; Donut 56dp semantic percentage; workload zero-term omission, urgency ordering, one-line ellipsis and tabular figures.

- [ ] Write failing tests for the listed values, including new Note and Workload files; run them before production code.
- [ ] Implement the two missing widgets with theme roles only and no data/provider imports.
- [ ] Reconcile existing metadata owners, add Widgetbook specimens, run focused E tests and shared API closure.
- [ ] Mark E entries `verified` and commit `feat(design): complete v3 metadata`.

### Task 8: Execute F — overlays and feedback

**Files:** modify `mx_alert_dialog.dart`, `mx_confirm_dialog.dart`, `mx_sheet.dart`, `mx_undo_snack_bar.dart`, `mx_feedback_band.dart`; create `mx_sheet_actions.dart`, `mx_deck_picker_sheet.dart`; focused overlay tests and Widgetbook.

**New interfaces:** `MxSheetActions(actions)` accepts localized view-action models; `MxDeckPickerSheet<T>(items, onSelected)` accepts view data and callback only, with no feature/provider/repository import.

**Contract tests:** Dialog/Sheet route barrier, focus trap, Escape/system-back dismissal, title/body/action order and destructive confirmation; SheetActions ordering/48dp target; Snackbar/Banner announcement and callback forwarding; DeckPicker long labels, keyboard selection and callback forwarding. Scrim is verified through modal routes only.

- [ ] Write the listed failing overlay tests and reproduce each before implementation.
- [ ] Implement through supported Material route APIs and token-backed component composition.
- [ ] Run overlay/focus tests, affected feature tests and Widgetbook; mark F verified and commit `feat(design): complete v3 feedback overlays`.

### Task 9: Execute G — loading, empty and error

**Files:** modify `mx_loading_state.dart`, `mx_empty_state.dart`, `mx_error_state.dart`; create `mx_skeleton.dart`, `mx_spinner.dart`; create focused/reduced-motion tests and Widgetbook.

**New interfaces:** `MxSkeleton` exposes only closed shape variants; `MxSpinner` owns visual/semantic progress only; `MxErrorState` forwards the caller retry callback.

**Contract tests:** Skeleton shape, layout stability, reduced motion and no semantic noise; Spinner size/reduced motion/announcement; Empty/Error long text, retry forwarding, light/dark and 320dp × text scale 2.0.

- [ ] Write failing tests, implement the two missing primitives with no feature imports, then run G tests.
- [ ] Audit shared source imports to prove no provider/repository/controller dependency.
- [ ] Register Widgetbook entries, mark G verified and commit `feat(design): complete v3 state views`.

### Task 10: Execute H — shell and layout

**Files:** modify `lib/app/shell/app_navigation_shell.dart`, `mx_content_shell.dart`, `mx_scroll_end_inset.dart`; create `mx_footer_bar.dart`; focused shell tests and Widgetbook.

**New interface:** `MxFooterBar(child)` owns visual/safe-area geometry only; it does not own commands or route state.

**Contract tests:** AppShell/ScreenScroll safe insets, nav coexistence, keyboard inset, scroll tail, RTL and text scale 2.0; FooterBar visual treatment, safe-area handling, action targets and scroll-tail interaction.

- [ ] Write the failures first; implement shell corrections without moving routing/state into shared widgets.
- [ ] Migrate direct caller matches from `rg 'Mx(ContentShell|ScrollEndInset)|AppNavigationShell' lib test widgetbook`.
- [ ] Run shell suite, register Widgetbook, mark H verified and commit `feat(design): complete v3 shell layout`.

### Task 11: Integrate direct consumers and close visual evidence

**Files:** direct feature matches from `rg 'Mx[A-Z]' lib/features lib/app widgetbook test`; affected feature tests; `test/design_audit/v3_handoff_coverage_test.dart`; `docs/wbs.md`; Linux/WSL-only goldens and gallery output.

- [ ] For every changed screen, add a mount test for loading, empty, error and loaded state before replacing local visual recipes with shared owners.
- [ ] Preserve callback targets, controller state transitions, routes and ARB strings; run feature tests and Widgetbook coverage.
- [ ] Make the audit fail unless all 46 contracts are `verified`, owner/test paths exist and caller searches reveal no legacy duplicate recipe.
- [ ] Run `.claude/skills/flutter-workflow/scripts/dod_check.sh` after focused tests are green.
- [ ] On Linux/WSL run `TZ=UTC flutter test --tags golden --update-goldens`, review every changed image against its handoff, then run `python .claude/skills/flutter-testing/scripts/build_screen_gallery.py` and record `ảnh <digest>`.
- [ ] Run `flutter test integration_test/ -d emulator-5554 --flavor development`; require 9 passing, 0 failing. If the device is unavailable, keep M100.122 open with exact evidence.
- [ ] Close WBS only after every required check passes; commit `feat(design): complete MemoX v3 handoff parity`.

## Self-Review

- **Coverage:** The map lists all 46 component documents, while Tasks 1–2 cover the four non-component handoff files.
- **Starting gaps:** `MxNote`, `MxWorkloadBreakdownLine`, `MxSheetActions`, `MxDeckPickerSheet`, `MxSkeleton`, `MxSpinner`, and `MxFooterBar` are absent today; Tasks 7–10 create them explicitly.
- **No shortcut:** A component is not complete merely because its mapped class exists. Each wave requires values, state/semantics, caller migration, Widgetbook and audit evidence.
- **Boundaries:** All new APIs accept semantic view data/callbacks, never raw styling or feature/data dependencies.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-09-21-memox-v3-handoff-full-implementation.md`.

1. **Subagent-driven:** execute isolated tasks with `superpowers:subagent-driven-development`, reviewing each commit before the next task.
2. **Inline execution:** use `superpowers:executing-plans` sequentially, preserving test-first checkpoints and the commit boundaries above.
