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

### Task 3: Groups A and B — chrome, navigation and actions

**Read before each owner:** its individual file in `components/A-chrome-navigation/` or `components/B-actions-controls/`, Foundations and Theme Binding.

**Owners:** platform StatusBar; `MxAppBar`, `MxNavigationBar`, `MxBreadcrumb`, `MxSessionTopBar`, `MxFab`; `MxActionButton`, `MxIconButton`, `MxFilterChip`, `MxChipTrigger`.

- [ ] Use each component MD to write failing tests for its own geometry, direct theme roles, states, semantics, interaction target and long-content requirement.
- [ ] Make each test fail before implementation; correct its existing owner only through tokens/M3 APIs.
- [ ] Review direct callers via that record’s `callerSearch`; update Widgetbook for each public API or variant.
- [ ] Run all focused A/B tests, verify only evidenced ledger records, and commit one owner or coherent dependency pair at a time.

### Task 4: Group C — inputs and selection

**Read before each owner:** every individual file in `components/C-inputs-selection/`, Foundations and Theme Binding.

**Owners:** `MxSearchField`, `MxTextField`, `MxSwitch`, `MxOptionRow`, `MxCheckboxRow`, `MxSegmentedTray`, `MxStepper`, `MxFieldMessage`.

- [ ] Apply a red-to-green focused test cycle per contract using only requirements in its MD.
- [ ] Keep validation, selection and controller state caller-owned; shared widgets own only presentation/interaction declared in their MD.
- [ ] Run C focused tests, `test/app/shared_api_closure_test.dart`, Widgetbook coverage and direct feature tests before verifying the eight ledger records.

### Task 5: Group D — surfaces and content

**Read before each owner:** every file in `components/D-surfaces-content/`, Foundations and Theme Binding.

**Owners:** `MxCard`, `MxSection`, `MxListRow`, `MxSettingsRow`, `MxIconTile`, `MxActionSheet`, `MxSectionLabel`.

- [ ] Derive all tests from each component’s own MD; do not carry values from memory or this plan.
- [ ] Implement only in the listed shared owner, replace direct visual duplicates found by the ledger search, and preserve caller-owned commands/state.
- [ ] Run focused D tests and Widgetbook coverage, then verify and commit each independently reviewable owner.

### Task 6: Group E — status and metadata

**Read before each owner:** every file in `components/E-status-metadata/`, Foundations and Theme Binding.

**Owners:** `MxBadge`, `MxStatusBadge`, `MxTagChip`, `MxNote`, `MxMasteryRamp`, `MxWorkloadBreakdownLine`, `MxMasteryDonut`.

- [ ] Create required missing owners `MxNote` and `MxWorkloadBreakdownLine`; do not substitute screen-local recipes.
- [ ] Audit existing owners against their own MD, including non-interactive semantics and semantic summaries for chart-like visuals.
- [ ] Run focused E tests, shared API closure and Widgetbook coverage; verify rows only after all evidence is green.

### Task 7: Group F — overlays and feedback

**Read before each owner:** every file in `components/F-overlays-feedback/`, Foundations and Theme Binding.

**Owners:** framework Scrim; `MxAlertDialog`/`MxConfirmDialog`, `MxSheet`, `MxSheetActions`, `MxUndoSnackBar`, `MxFeedbackBand`, `MxDeckPickerSheet`.

- [ ] Create `MxSheetActions` and `MxDeckPickerSheet` if absent. They accept view data/localized labels/callbacks only and never import a feature provider or repository.
- [ ] Test each MD’s supported route/barrier semantics, focus, dismissal, action order, announcement and long-content rule.
- [ ] Review direct feature consumers, update Widgetbook, verify the seven ledger rows and commit coherent overlay units.

### Task 8: Groups G and H — states and shell

**Read before each owner:** every file in `components/G-loading-empty-error/` and `components/H-layout-shell/`, Foundations and Theme Binding.

**Owners:** `MxSkeleton`, `MxSpinner`, `MxEmptyState`, `MxErrorState`, `AppNavigationShell`/`MxContentShell`, `MxScrollEndInset`, `MxFooterBar`.

- [ ] Create missing owners `MxSkeleton`, `MxSpinner` and `MxFooterBar`.
- [ ] Test only the loading/layout stability, retry, reduced-motion, semantic, system-inset, scroll-tail, navigation, RTL and large-text requirements written in each owner’s MD.
- [ ] Confirm shared state/shell widgets import no feature, provider, repository or controller; migrate direct consumers and add Widgetbook specimens.
- [ ] Verify all seven ledger entries and commit per independently reviewable owner.

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
