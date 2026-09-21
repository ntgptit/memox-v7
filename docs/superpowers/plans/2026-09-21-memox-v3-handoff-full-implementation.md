# MemoX v3 Handoff Implementation Plan

| | |
|---|---|
| **Status** | active |
| **Purpose** | Điều phối việc thực hiện đầy đủ handoff v3 mà không sao chép lại specification |
| **Scope** | 4 tài liệu tham chiếu và 46 component contracts trong `docs/design/v3/` |
| **Source of truth for** | Thứ tự triển khai, evidence ledger và Definition of Done của M100.122 |
| **Depends on** | `docs/design/v3/00-index.md` · `01-foundations.md` · `02-theme-binding.md` · `99-traceability.md` · `docs/wbs.md` |
| **Updated by task** | M100.122 |
| **Last updated** | 2026-09-21 |

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to execute this plan task-by-task. This plan orchestrates the v3 documents; it never replaces them.

**Goal:** Make the Flutter app conform to every requirement in the existing MemoX v3 handoff documents, with evidence for all 46 component contracts.

**Architecture:** The handoff Markdown files are the visual and interaction specification. `lib/core/theme/` owns tokens and Material 3 binding; `lib/shared/widgets/` owns reusable contracts; feature presentation code only composes them and supplies view data/callbacks. The plan records who reads and proves each contract, not copied values from the contract.

**Tech Stack:** Flutter stable · Material 3 · Dart · existing `Mx*` shared widgets · Widgetbook · Flutter widget/accessibility tests · Linux/WSL golden tests.

**Spec:** Every file indexed by `docs/design/v3/00-index.md`. When this plan and a handoff document disagree, the handoff document wins.

## Global Constraints

- Do not duplicate geometry, palette, state matrices, theme-role tables or HTML translation notes from `docs/design/v3/**` into this plan.
- Before changing a component, read its own handoff file plus `01-foundations.md` and `02-theme-binding.md`. Use `99-traceability.md` for source-name or owner ambiguity.
- Do not change business rules, domain/data layers, routes, controller interfaces or ARB copy policy.
- Resolve visuals through canonical tokens/theme owners and Material 3; do not copy web-specific mechanics.
- StatusBar and Scrim are platform/framework-owned. Verify them, but do not create fake app widgets.
- Preserve explicit handoff visuals. Record any measured accessibility exception in `docs/wbs.md`; do not silently suppress a test.
- New public shared widgets require focused tests and Widgetbook registration. Migrate direct callers in the same task as a public API migration.
- Goldens are authored only in Linux/WSL with `TZ=UTC`. Update `docs/wbs.md` with every code commit.

---

## 5Why

1. **Why use pointers rather than restate 50 files?** The MD files are already the source of truth. Copying them would create a competing specification that drifts.
2. **Why require a ledger?** A pointer cannot prove an agent implemented every file. One evidence record per contract makes omissions visible.
3. **Why execute A–H?** The index groups components by shared vocabulary and dependency; later surfaces/shells compose earlier controls.
4. **Why create missing shared widgets?** Their semantics recur; screen-local copies would immediately diverge.
5. **Why finish with screens, goldens and device checks?** Isolated widgets cannot prove real layout, platform fonts, system insets or interaction continuity.

## Required Ledger

`test/design_audit/v3_handoff_coverage_test.dart` is the execution ledger. It must contain exactly one `V3ContractAudit` record for every component link in `00-index.md`:

```dart
const V3ContractAudit(
  document: 'components/C-inputs-selection/segmented-tray.md',
  owner: 'lib/shared/widgets/mx_segmented_tray.dart',
  focusedTest: 'test/shared/widgets/mx_segmented_tray_test.dart',
  callerSearch: "rg 'MxSegmentedTray' lib test widgetbook",
  status: V3AuditStatus.auditing,
);
```

Mark a record `verified` only after the executor has read its component MD and Foundations/Theme Binding, added focused tests for all requirements declared there, reviewed direct callers, registered public additions in Widgetbook, and run the wave’s focused tests. File existence or an owner name alone is never parity evidence.

## Strict Execution Runbook

Run the documents in this order. Each numbered step is a checkpoint: finish its
focused tests and ledger updates before reading implementation work from the
next step. This is the handoff order `FOUNDATIONS → THEME_BINDING →
SHARED_COMPONENTS → SCREENS`, expanded by the component-composition edges in
`99-traceability.md`.

| Order | Read and execute | Why it precedes the next step |
|---:|---|---|
| 0 | `00-index.md`, `99-traceability.md` | Establish the complete 46-record ledger and the source composition graph. |
| 1 | `01-foundations.md` | Defines typography, sizing, radius, spacing, effect and semantic vocabulary; nothing may recreate these locally. |
| 2 | `02-theme-binding.md` | Binds all component-consumed roles to Flutter before any widget reads them. |
| 3 | `button.md`, `icon-button.md`, `filter-chip.md`, `badge.md`, `status-badge.md`, `tag-chip.md`, `chip-trigger.md`, `mastery-ramp.md`, `note.md`, `skeleton.md`, `spinner.md`, `screen-scroll.md` | Leaf primitives. ChipTrigger follows Button/Badge and now precedes ListSectionHeader; later components compose these stable APIs. |
| 4 | `field-message.md`, `icon-tile.md`, `toggle.md`, `option-row.md`, `selection-checkbox.md`, `segmented-tray.md`, `stepper.md` | FieldMessage must exist before TextField. IconTile must exist before ListRow/SettingsRow. The remaining selections are independent leaves. |
| 5 | `search-field.md`, `text-field.md`, `list-row.md`, `settings-row.md`, `list-section-header.md`, `card.md`, `section.md`, `action-sheet-command-row.md`, `mastery-donut.md`, `workload-breakdown-line.md` | These consume or align to the step-3/4 primitives: TextField uses FieldMessage; rows use IconTile; ListSectionHeader selects ChipTrigger/Badge/Button. |
| 6 | `app-bar.md`, `bottom-nav.md`, `breadcrumb.md`, `fab.md`, `study-top-bar.md`, `empty-state.md`, `error-state.md`, `footer-bar.md` | EmptyState/ErrorState/FooterBar compose the verified Button. Chrome is now safe to integrate with stabilized actions/tokens. |
| 7 | `dialog.md`, `bottom-sheet.md`, `snackbar.md`, `inline-banner.md`, `sheet-actions.md` | Overlay foundations use stabilized Button and action styling. SheetActions composes Button and is required by DeckPickerSheet. |
| 8 | `deck-picker-sheet.md` | It composes BottomSheet, ListRow, EmptyState and SheetActions; run only after all four are verified. |
| 9 | `app-shell.md` | Compose stabilized BottomNav, chrome, state views, screen scrolling and footer treatment into the application shell. |
| 10 | Direct screen handoffs, callers, Widgetbook, goldens and device suite | Screen composition is last; it must consume verified primitives rather than define visual policy. |

`ChipTrigger` deliberately follows Button/Badge in step 3 and precedes
ListSectionHeader in step 5. When a shared leaf API changes, re-run every
direct composite consumer test before advancing; this includes the Card,
Section and row compositions in step 5.

## Execution Waves

### Task 1: Establish truthful coverage

**Read:** `00-index.md`, `99-traceability.md`.

**Modify:** `test/design_audit/v3_handoff_coverage_test.dart`, `docs/wbs.md`.

- [ ] Replace the name-only map with one ledger record for each of the 46 indexed component documents.
- [ ] Initialize every not-rechecked contract as `auditing`, never `verified`.
- [ ] Run `flutter test test/design_audit/v3_handoff_coverage_test.dart` and `python .claude/skills/flutter-workflow/scripts/check_docs.py`.
- [ ] Commit `test(design): make v3 handoff evidence explicit`.

### Task 2: Foundation and theme prerequisite

**Read:** `01-foundations.md`, `02-theme-binding.md`, and every component’s theme-role section.

**Modify only if audit fails:** canonical owners under `lib/core/theme/**` and their tests.

- [ ] Add focused light/dark tests for each consumed role not already proved by the theme audit.
- [ ] Run `flutter test test/core/theme test/design_audit/audit_theme_steps.dart`, `flutter analyze`, and `.claude/skills/flutter-architecture/scripts/check_architecture.sh`.
- [ ] Commit a theme prerequisite before any component consumes a newly bound role.

### Task 3: Execute leaf primitives in runbook order 3

**Read before each owner:** the exact document in the Strict Execution Runbook, Foundations and Theme Binding.

**Owners:** `MxActionButton`, `MxIconButton`, `MxFilterChip`, `MxBadge`, `MxStatusBadge`, `MxTagChip`, `MxChipTrigger`, `MxMasteryRamp`, `MxNote`, `MxSkeleton`, `MxSpinner`, `MxScrollEndInset`.

- [ ] Execute runbook step 3 in its stated order. For each component MD, write failing tests for its own geometry, direct theme roles, states, semantics, interaction target and long-content requirement.
- [ ] Make each test fail before implementation; correct its existing owner only through tokens/M3 APIs.
- [ ] Review direct callers via that record’s `callerSearch`; update Widgetbook for each public API or variant.
- [ ] Run all focused leaf tests, verify only evidenced ledger records, and commit one owner or coherent dependency pair at a time.

### Task 4: Execute input and surface composites in runbook order 4–5

**Read before each owner:** its exact runbook document, Foundations and Theme Binding. Do not start a composite document before its row/field dependency is `verified`.

**Owners:** `MxFieldMessage`, `MxIconTile`, `MxSwitch`, `MxOptionRow`, `MxCheckboxRow`, `MxSegmentedTray`, `MxStepper`, `MxSearchField`, `MxTextField`, `MxListRow`, `MxSettingsRow`, `MxSectionLabel`, `MxCard`, `MxSection`, `MxActionSheet`, `MxMasteryDonut`, `MxWorkloadBreakdownLine`.

- [ ] Apply a red-to-green focused test cycle per contract using only requirements in its MD.
- [ ] Keep validation, selection and controller state caller-owned; shared widgets own only presentation/interaction declared in their MD.
- [ ] Run C/D/E focused tests, `test/app/shared_api_closure_test.dart`, Widgetbook coverage and direct feature tests before verifying these ledger records.

### Task 5: Execute chrome and state composites in runbook order 6

**Read before each owner:** its exact runbook document, Foundations and Theme Binding.

**Owners:** `MxAppBar`, `MxNavigationBar`, `MxBreadcrumb`, `MxFab`, `MxSessionTopBar`, `MxEmptyState`, `MxErrorState`, `MxFooterBar`.

- [ ] Derive all tests from each component’s own MD; do not carry values from memory or this plan.
- [ ] Implement only in the listed shared owner, replace direct visual duplicates found by the ledger search, and preserve caller-owned commands/state.
- [ ] Run focused A/G/H tests and Widgetbook coverage, then verify and commit each independently reviewable owner.

### Task 6: Execute overlays in runbook order 7–8

**Read before each owner:** its exact runbook document, Foundations and Theme Binding. DeckPickerSheet is blocked until BottomSheet, ListRow, EmptyState and SheetActions are verified.

**Owners:** `MxAlertDialog`/`MxConfirmDialog`, `MxSheet`, `MxUndoSnackBar`, `MxFeedbackBand`, `MxSheetActions`, `MxDeckPickerSheet`; framework owns Scrim.

- [ ] Verify Dialog, BottomSheet, Snackbar and InlineBanner first; then create/verify SheetActions; create/verify DeckPickerSheet last.
- [ ] Do not import feature providers or repositories into the two new overlay primitives; they receive view data and callbacks only.
- [ ] Run focused F tests, shared API closure and Widgetbook coverage; verify ledger rows only after all evidence is green.

### Task 7: Execute shell composition in runbook order 9

**Read:** `app-shell.md` after all runbook step 3–8 dependencies are verified.

**Owners:** `AppNavigationShell` and `MxContentShell`.

- [ ] Test system insets, stabilized bottom navigation/chrome, state-view slots and screen-scroll composition as the AppShell MD requires.
- [ ] Keep routing and feature state outside shared layout widgets.
- [ ] Run shell-focused tests and verify the AppShell ledger record.

### Task 8: Execute screens only after all shared components

**Read:** affected component MDs, `99-traceability.md` and corresponding screen handoff material.

**Owners:** direct feature presentation widgets and Widgetbook compositions only.

- [ ] Replace only local visual duplication with verified owners; preserve callbacks, route calls, controller states and ARB usage.
- [ ] Mount loading, empty, error and loaded screen states in tests before each composition migration.
- [ ] Run feature tests and Widgetbook coverage, then re-run the corresponding component-focused test before marking a screen integration complete.

### Task 9: Screen integration and closure

**Read:** each affected component MD, final ledger, `99-traceability.md` and `docs/wbs.md`.

- [ ] For every changed feature screen, test loading, empty, error and loaded compositions before replacing a local visual recipe; preserve callbacks, routes and ARB usage.
- [ ] Make the ledger fail unless all 46 records are `verified` and their owner/test paths and caller searches remain valid.
- [ ] Run `.claude/skills/flutter-workflow/scripts/dod_check.sh`.
- [ ] On Linux/WSL only, run `TZ=UTC flutter test --tags golden --update-goldens`; compare each changed image against its component MD. Then run `python .claude/skills/flutter-testing/scripts/build_screen_gallery.py` and record `ảnh <digest>` in WBS.
- [ ] Run `flutter test integration_test/ -d emulator-5554 --flavor development`; require 9 passing, 0 failing. If unavailable, keep M100.122 open with exact device evidence.
- [ ] Close M100.122 only after all evidence is green; commit `feat(design): complete MemoX v3 handoff parity`.

## Self-Review

- `00-index.md` remains the complete authoritative list; this plan only points agents at its 46 contracts.
- No design values or state tables are duplicated, so the handoff has one source to update.
- The ledger creates a mechanical omission check; each wave requires tests, caller review and Widgetbook evidence rather than owner-name presence.
- The delivery owners currently absent are explicitly queued: `MxNote`, `MxWorkloadBreakdownLine`, `MxSheetActions`, `MxDeckPickerSheet`, `MxSkeleton`, `MxSpinner`, `MxFooterBar`.

## Execution Handoff

Execute in wave order using `superpowers:executing-plans`. Before changing an owner, open its existing MD and implement every requirement in that file; this plan is not a replacement specification.
