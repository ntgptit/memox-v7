# MemoX v3 Redesign Implementation Plan

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kế hoạch triển khai trọn bộ redesign MemoX v3 từ handoff đã import |
| **Scope** | Theme, 46 shared components, các consumer trực tiếp, Widgetbook và visual verification; không đổi business rules hay data flow |
| **Source of truth for** | Thứ tự triển khai và verification của redesign v3 |
| **Depends on** | `docs/design/v3/00-index.md` · `docs/design-system/v3-foundations.md` · `docs/design-system/theme-architecture.md` |
| **Updated by task** | v3-redesign planning |
| **Last updated** | 2026-09-21 |

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconcile the shipped Flutter design system and its consumers with all 46 MemoX v3 component contracts, preserving application behaviour.

**Architecture:** The v3 theme is the sole shared source for colour, typography, spacing, state treatment and Material defaults. Each handoff component maps onto one existing `Mx*` primitive where one exists; a new primitive is added only when the handoff has a distinct reusable contract. Feature screens compose these primitives and do not duplicate their appearance, interaction, or state policy.

**Tech Stack:** Flutter stable, Material 3, Dart, existing `Mx*` shared-widget kit, Widgetbook, Flutter widget tests, Linux-authored golden tests.

**Spec:** `docs/design/v3/00-index.md`, `01-foundations.md`, `02-theme-binding.md`, every document under `docs/design/v3/components/`, and `99-traceability.md`.

## Global Constraints

- Keep the existing dependency direction and do not put business logic, persistence, or feature-specific state in shared widgets.
- Use Material 3 first; all visual values resolve from `ColorScheme`, `TextTheme`, theme extensions, or existing design tokens—never raw colours, typography, or spacing literals in a widget.
- Preserve public APIs unless a contract requires a deliberate migration; update every caller, Widgetbook use case and closure test in the same change.
- `StatusBar` and `Scrim` are platform/framework-owned: verify their integration but do not create fake app widgets.
- Keep layout accessible at light/dark, small width, large text scale and keyboard/focus interaction states.
- When a handoff visual contract and an existing accessibility convention conflict, preserve the handoff and record the measured exception in the WBS; do not pause execution for a new design decision.
- Each production change updates `docs/wbs.md` as the single redesign task, has focused tests, and passes format, analyze, architecture, document and code-verification guards.
- Regenerate goldens only on Linux/WSL with `TZ=UTC`; a Windows run must not write committed golden PNGs.

---

## 5Why

1. **Why redesign the whole shared kit instead of restyling screens?** The handoff defines a common vocabulary—roles, geometry, interaction states and component composition. Restyling each screen would duplicate those decisions and diverge on the next screen.
2. **Why establish theme binding before components?** The component contracts name semantic roles rather than raw values. A component cannot correctly resolve light, dark, high-contrast, disabled and focus states until those roles have one canonical owner.
3. **Why migrate by component group after the theme?** Components in the same group share Material defaults and lower-level primitives, while cross-group consumers can be wired only after their APIs stabilize. This keeps each wave reviewable without creating temporary palette forks.
4. **Why preserve existing `Mx*` widgets where their contract already matches?** Replacing a working primitive for naming alone expands the regression surface without advancing the visual contract. The redesign changes behaviour and geometry only where the v3 spec differs.
5. **Why finish with real screen, golden and device verification?** A shared component can pass an isolated widget test yet clip in a feature layout, fail a real system font, or change a shipped screenshot. The root outcome is production visual parity, not a locally green component catalog.

## File Structure and Ownership Map

| Area | Primary production ownership | Contract source | Primary tests/catalog |
|---|---|---|---|
| Theme and foundations | `lib/core/theme/` | `01-foundations.md`, `02-theme-binding.md` | `test/core/theme/`, `test/design_audit/`, `test/support/theme_probe.dart` |
| A — chrome/navigation | `lib/shared/widgets/mx_app_bar.dart`, `mx_navigation_bar.dart`, `mx_breadcrumb.dart`, `mx_session_top_bar.dart`, `mx_fab.dart` | `components/A-chrome-navigation/` | matching `test/shared/widgets/` files and Widgetbook navigation entries |
| B — actions/controls | `mx_action_button.dart`, `mx_icon_button.dart`, `mx_filter_chip.dart`, `mx_chip_trigger.dart` | `components/B-actions-controls/` | matching shared-widget tests and `control_components.dart` |
| C — inputs/selection | `mx_search_field.dart`, `mx_text_field.dart`, `mx_switch.dart`, `mx_option_row.dart`, `mx_checkbox_row.dart`, `mx_radio_rows.dart` plus narrowly named missing primitives | `components/C-inputs-selection/` | `mx_form_components_test.dart`, focused component tests and form Widgetbook entries |
| D — surfaces/content | `mx_card.dart`, `mx_section.dart`, `mx_list_row.dart`, `mx_settings_row.dart`, `mx_icon_tile.dart`, `mx_action_sheet.dart` | `components/D-surfaces-content/` | matching component tests, golden specimens and screen consumers |
| E — status/metadata | existing badge/progress widgets plus narrowly named reusable `Mx*` additions | `components/E-status-metadata/` | focused widget tests and status Widgetbook entries |
| F — overlays/feedback | `mx_alert_dialog.dart`, `mx_confirm_dialog.dart`, `mx_sheet.dart`, `mx_undo_snack_bar.dart`, `mx_feedback_band.dart` plus deck-picker composition | `components/F-overlays-feedback/` | overlay tests, focus tests and Widgetbook |
| G/H — states/layout | `mx_loading_state.dart`, `mx_empty_state.dart`, `mx_error_state.dart`, `mx_content_shell.dart`, `mx_scroll_end_inset.dart`, `app/shell/app_navigation_shell.dart` | `components/G-loading-empty-error/`, `components/H-layout-shell/` | state, shell-geometry, demo and integration tests |

### Contract-to-primitive map

This map is binding for the redesign. `existing` means reconcile the named API
and implementation; `new` means create exactly one shared primitive with that
name; `platform` means verify integration only.

| Handoff component | Target | Ownership |
|---|---|---|
| StatusBar | Android/Flutter system inset | platform |
| AppBar, BottomNav, Breadcrumb, StudyTopBar, Fab | `MxAppBar`, `MxNavigationBar`, `MxBreadcrumb`, `MxSessionTopBar`, `MxFab` | existing |
| Button, IconButton, FilterChip, ChipTrigger | `MxActionButton`, `MxIconButton`, `MxFilterChip`, `MxChipTrigger` | existing |
| SearchField, TextField, Toggle, OptionRow, SelectionCheckbox | `MxSearchField`, `MxTextField`, `MxSwitch`, `MxOptionRow`, `MxCheckboxRow` | existing |
| SegmentedTray, Stepper, FieldMessage | `MxSegmentedTray`, `MxStepper`, `MxFieldMessage` | new |
| Card, Section, ListRow, SettingsRow, IconTile | `MxCard`, `MxSection`, `MxListRow`, `MxSettingsRow`, `MxIconTile` | existing |
| ActionSheetCommandRow, ListSectionHeader | `MxActionSheet`, `MxSectionLabel` | existing |
| Badge, MasteryRamp | `MxBadge`, `MxProgressBar` | existing |
| StatusBadge, TagChip, Note, WorkloadBreakdownLine, MasteryDonut | `MxStatusBadge`, `MxTagChip`, `MxNote`, `MxWorkloadBreakdownLine`, `MxMasteryDonut` | new |
| Scrim | Flutter modal-route barrier | platform |
| Dialog, BottomSheet, Snackbar, InlineBanner | `MxAlertDialog`/`MxConfirmDialog`, `MxSheet`, `MxUndoSnackBar`, `MxFeedbackBand` | existing |
| SheetActions, DeckPickerSheet | `MxSheetActions`, `MxDeckPickerSheet` | new |
| Skeleton, Spinner | `MxSkeleton`, `MxSpinner` | new |
| EmptyState, ErrorState | `MxEmptyState`, `MxErrorState` | existing |
| AppShell, ScreenScroll, FooterBar | `AppNavigationShell`/`MxContentShell`, `MxScrollEndInset`, `MxFooterBar` | existing, existing, new |

## Task 1: Establish the redesign baseline and ledger

**Files:**

- Modify: `docs/wbs.md`
- Modify: `docs/design-system/v3-foundations.md` only if a spec-to-Dart mapping is missing or incorrect
- Create: `test/design_audit/v3_handoff_coverage_test.dart`

**Interfaces:**

- Produces WBS task `M100.122` covering this redesign and a test-owned inventory that locks the contract-to-primitive map above.
- Consumes the 46 component documents under `docs/design/v3/components/`.

- [ ] Add WBS entry `M100.122` with this plan and all `docs/design/v3/**` files as its sources; explicitly exclude business-rule, data-model and feature-flow changes.
- [ ] Write a failing inventory test with a `const Map<String, String>` containing all 46 component names and the exact target in the contract-to-primitive map; assert the map has length 46 and every mapped source document exists.
- [ ] Run `flutter test test/design_audit/v3_handoff_coverage_test.dart` and confirm the baseline fails until the inventory is complete.
- [ ] Complete the inventory from `00-index.md`, then run the test again and commit the ledger/inventory as `docs(design): establish v3 redesign inventory`.

## Task 2: Freeze the v3 theme prerequisite

**Files:**

- Modify: `lib/core/theme/app_theme.dart`, `lib/core/theme/foundations/`, `lib/core/theme/schemes/`, `lib/core/theme/states/`, and only the relevant files in `lib/core/theme/components/`
- Modify: `test/core/theme/app_theme_identity_test.dart`, `test/design_audit/audit_theme_steps.dart`
- Read first: `docs/superpowers/plans/2026-09-17-memox-v3-foundations.md`, `docs/superpowers/plans/2026-09-18-memox-v3-theme-binding.md`

**Interfaces:**

- Produces complete light/dark `ColorScheme`, canonical `TextTheme`, existing semantic extension values, decoration/effect tokens, and centralized disabled/pressed/focus state policy for every downstream widget.

- [ ] Add failing tests for every v3 role consumer declared in `02-theme-binding.md` that is not already verified by the theme suite.
- [ ] Reconcile foundations and component theme builders with `docs/design-system/v3-foundations.md`; preserve every explicitly repository-preserved role.
- [ ] Run focused theme tests, then `flutter analyze` and `.claude/skills/flutter-architecture/scripts/check_architecture.sh`.
- [ ] Commit the prerequisite as `feat(theme): bind MemoX v3 design roles` before changing any component that consumes a newly bound role.

## Task 3: Implement A — chrome and navigation

**Files:**

- Modify: `mx_app_bar.dart`, `mx_navigation_bar.dart`, `mx_breadcrumb.dart`, `mx_session_top_bar.dart`, `mx_fab.dart`, and their focused tests
- Modify consumers only where a v3 API requires it: `lib/app/shell/app_navigation_shell.dart` and current feature callers found by `rg 'Mx(AppBar|NavigationBar|Breadcrumb|SessionTopBar|Fab)' lib test`
- Read first: six specifications in `docs/design/v3/components/A-chrome-navigation/`

**Interfaces:**

- Produces v3 AppBar, BottomNav, Breadcrumb, StudyTopBar and FAB primitives. Status-bar handling remains framework-owned and is verified through insets rather than rendered as a widget.

- [ ] Add failing geometry, semantics, focus and light/dark tests for each changed primitive before changing its implementation.
- [ ] Apply the contracts in dependency order: AppBar → BottomNav → Breadcrumb → StudyTopBar → FAB.
- [ ] Update Widgetbook navigation entries and every feature caller that uses a changed required argument.
- [ ] Run all A-group tests and the affected demo/widgetbook tests; commit each primitive independently so a rejected geometry decision does not block the other four.

## Task 4: Implement B — actions and controls

**Files:**

- Modify: `mx_action_button.dart`, `mx_icon_button.dart`, `mx_filter_chip.dart`, `mx_chip_trigger.dart`, relevant `lib/core/theme/components/actions/` builders, and their focused tests
- Read first: four specifications in `docs/design/v3/components/B-actions-controls/` and the existing component plans in `docs/superpowers/plans/2026-09-18-*` for Button, IconButton, FilterChip and ChipTrigger

**Interfaces:**

- Produces v3 size, tone, disabled, pressed, focus, loading and accessibility contracts without introducing a second button or chip theme system.

- [ ] Add a failing test for every new public enum/variant and every changed visual state before implementation.
- [ ] Implement Button, IconButton, FilterChip, then ChipTrigger; retain callers' callbacks and semantics labels unchanged unless the spec explicitly changes them.
- [ ] Register every new public variant in Widgetbook and extend `test/app/shared_api_closure_test.dart` for a newly created shared file.
- [ ] Run focused tests after each component and commit one component per change.

## Task 5: Implement C — inputs and selection

**Files:**

- Modify: `mx_search_field.dart`, `mx_text_field.dart`, `mx_switch.dart`, `mx_option_row.dart`, `mx_checkbox_row.dart`, `mx_radio_rows.dart`
- Create only when no existing primitive can represent the contract: `lib/shared/widgets/mx_segmented_tray.dart`, `mx_stepper.dart`, `mx_field_message.dart`, with matching tests and Widgetbook entries
- Read first: eight specifications in `docs/design/v3/components/C-inputs-selection/`

**Interfaces:**

- Produces reusable input primitives whose validation presentation, selection state, 48dp target and keyboard/focus behaviour are owned once.

- [ ] Write failing widget tests for validation/error, disabled, selected/checked, focus and text-scale behaviour for each changed or new primitive.
- [ ] Reconcile existing primitives first; create `MxSegmentedTray`, `MxStepper` and `MxFieldMessage` only after confirming no existing widget has the same state contract.
- [ ] Replace duplicated local form presentation only in callers named by a direct source search; do not alter validation rules or controller behaviour.
- [ ] Run form, accessibility and focused component tests, then commit each primitive separately.

## Task 6: Implement D and E — surfaces, content and metadata

**Files:**

- Modify: `mx_card.dart`, `mx_section.dart`, `mx_list_row.dart`, `mx_settings_row.dart`, `mx_icon_tile.dart`, `mx_action_sheet.dart`, `mx_badge.dart`, `mx_progress_bar.dart`
- Create narrowly scoped primitives required by the E contracts: `mx_status_badge.dart`, `mx_tag_chip.dart`, `mx_note.dart`, `mx_mastery_ramp.dart`, `mx_workload_breakdown_line.dart`, `mx_mastery_donut.dart`, with tests and Widgetbook entries
- Read first: all documents in `components/D-surfaces-content/` and `components/E-status-metadata/`

**Interfaces:**

- Produces composition-safe rows, cards and metadata renderers; callers pass domain labels, values and callbacks, while the primitive owns visual treatment.

- [ ] Add failing state/geometry tests for each changed primitive, including long text and compact width where its contract requires it.
- [ ] Implement D primitives before E primitives because E compositions use card, row, icon-tile and section geometry.
- [ ] Introduce chart-like E widgets as paint-only renderers with semantic summaries; do not put scheduling or progress calculation inside them.
- [ ] Update only the direct call sites found by search, register Widgetbook specimens, run focused tests and commit one primitive at a time.

## Task 7: Implement F — overlays and feedback

**Files:**

- Modify: `mx_alert_dialog.dart`, `mx_confirm_dialog.dart`, `mx_sheet.dart`, `mx_undo_snack_bar.dart`, `mx_feedback_band.dart`
- Create: `mx_sheet_actions.dart`, `mx_deck_picker_sheet.dart` only if existing compositions cannot meet their contracts without feature coupling
- Modify matching overlay/focus tests and Widgetbook entries
- Read first: seven documents in `docs/design/v3/components/F-overlays-feedback/`

**Interfaces:**

- Produces M3-backed dialog, bottom-sheet, snackbar and banner APIs. Scrim ownership remains with Flutter's modal routes; shared code configures barrier semantics and appearance through supported APIs only.

- [ ] Add failing tests for focus trap, escape/back dismissal, semantic announcements, destructive confirmation and sheet action ordering.
- [ ] Implement Dialog, BottomSheet, SheetActions, Snackbar and InlineBanner before DeckPickerSheet so the picker composes stable primitives.
- [ ] Keep deck choice, repository reads and move rules in the calling feature; `MxDeckPickerSheet` accepts view data and callbacks only.
- [ ] Run overlay tests, keyboard/focus tests and affected feature tests after each component; commit independently.

## Task 8: Implement G and H — state views and app layout

**Files:**

- Modify: `mx_loading_state.dart`, `mx_empty_state.dart`, `mx_error_state.dart`, `mx_content_shell.dart`, `mx_scroll_end_inset.dart`, `lib/app/shell/app_navigation_shell.dart`
- Create: `mx_skeleton.dart`, `mx_spinner.dart`, `mx_footer_bar.dart` if the current state/shell primitives cannot expose the v3 contracts
- Modify: shell/state tests, `test/demo/` hosts and Widgetbook entries
- Read first: all documents in `components/G-loading-empty-error/` and `components/H-layout-shell/`

**Interfaces:**

- Produces standard loading, empty, error, scrolling and chrome composition while feature screens retain their own data-state decisions and retry commands.

- [ ] Add failing tests for loading-to-content stability, retry callback forwarding, scroll tail clearance, navigation-bar coexistence and large-text layout.
- [ ] Implement G components before H so `AppShell` can compose the final state primitives without local copies.
- [ ] Verify no shared state view imports a feature, provider, repository or controller.
- [ ] Run shell geometry, responsive, affected demo and Widgetbook tests; commit each primitive independently.

## Task 9: Integrate component contracts into real screens

**Files:**

- Modify only feature presentation widgets directly identified by `rg 'Mx[A-Z]' lib/features`
- Modify: `widgetbook/lib/components/` and `widgetbook/lib/main.dart` for every new public shared primitive
- Modify: affected `test/demo/*_demo_test.dart`, `test/shared/widgets/golden_*` and feature widget tests

**Interfaces:**

- Produces production screens that use the new primitives without changing use cases, Riverpod controller interfaces, repository calls, routes, translations or business rules.

- [ ] For each updated screen, write or extend a widget test that mounts its loading, empty, error and loaded state before changing its composition.
- [ ] Replace local visual duplication with the final shared API; preserve callback wiring and ARB strings.
- [ ] Verify light/dark, 320dp and text scale 2.0 for every visually changed screen.
- [ ] Commit by feature slice, never mix unrelated feature changes into one commit.

## Task 10: Visual closure and Definition of Done

**Files:**

- Modify: only golden PNGs and gallery output that fail after the approved changes
- Modify: `docs/wbs.md` to close the redesign entry with exact verification evidence

- [ ] Run `dart format .` and `flutter analyze`.
- [ ] Run `.claude/skills/flutter-workflow/scripts/dod_check.sh` after all focused tests are green.
- [ ] In Linux/WSL only, run `TZ=UTC flutter test --tags golden --update-goldens`; review every changed state against the corresponding v3 component contract before accepting it.
- [ ] Run `python .claude/skills/flutter-testing/scripts/build_screen_gallery.py`, publish the existing gallery artifact, and record its `ảnh <digest>`.
- [ ] Run `flutter test integration_test/ -d emulator-5554 --flavor development` because the redesign changes feature presentation; record any unavailable-device blocker explicitly.
- [ ] Re-run the full gate after the final WBS update and commit the closure as `feat(design): complete MemoX v3 redesign`.

## Self-Review

- **Spec coverage:** Tasks 2–8 cover the source groups in `docs/design/v3/`; Task 9 applies them to production consumers; Task 10 validates all user-visible output. StatusBar and Scrim are deliberately verified as platform/framework integrations rather than implemented as fake widgets.
- **Dependency coverage:** Theme precedes every shared primitive; primitive groups precede feature composition; visual/device verification follows all code changes.
- **Scope control:** The plan changes presentation and design-system code only. Any request that requires a business-rule, persistence, routing or localization policy change must be split into a separate approved task.
- **Placeholder scan:** No component group is omitted; each wave names the source documents, production ownership, test responsibility and completion command.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-09-21-memox-v3-redesign.md`.

Two execution options:

1. **Subagent-driven** — one fresh reviewer/implementer per independently committed component wave, followed by sequential integration.
2. **Inline execution** — implement the waves in this session with checkpoints after each component group.
