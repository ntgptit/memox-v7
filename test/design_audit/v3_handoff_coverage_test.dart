@Tags(<String>['design-audit'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class _ComponentContract {
  const _ComponentContract(this.source, this.target);

  final String source;
  final String target;
}

const _contracts = <String, _ComponentContract>{
  'StatusBar': _ComponentContract(
    'A-chrome-navigation/status-bar.md',
    'platform',
  ),
  'AppBar': _ComponentContract('A-chrome-navigation/app-bar.md', 'MxAppBar'),
  'BottomNav': _ComponentContract(
    'A-chrome-navigation/bottom-nav.md',
    'MxNavigationBar',
  ),
  'Breadcrumb': _ComponentContract(
    'A-chrome-navigation/breadcrumb.md',
    'MxBreadcrumb',
  ),
  'StudyTopBar': _ComponentContract(
    'A-chrome-navigation/study-top-bar.md',
    'MxSessionTopBar',
  ),
  'Fab': _ComponentContract('A-chrome-navigation/fab.md', 'MxFab'),
  'Button': _ComponentContract(
    'B-actions-controls/button.md',
    'MxActionButton',
  ),
  'IconButton': _ComponentContract(
    'B-actions-controls/icon-button.md',
    'MxIconButton',
  ),
  'FilterChip': _ComponentContract(
    'B-actions-controls/filter-chip.md',
    'MxFilterChip',
  ),
  'ChipTrigger': _ComponentContract(
    'B-actions-controls/chip-trigger.md',
    'MxChipTrigger',
  ),
  'SearchField': _ComponentContract(
    'C-inputs-selection/search-field.md',
    'MxSearchField',
  ),
  'TextField': _ComponentContract(
    'C-inputs-selection/text-field.md',
    'MxTextField',
  ),
  'Toggle': _ComponentContract('C-inputs-selection/toggle.md', 'MxSwitch'),
  'OptionRow': _ComponentContract(
    'C-inputs-selection/option-row.md',
    'MxOptionRow',
  ),
  'SelectionCheckbox': _ComponentContract(
    'C-inputs-selection/selection-checkbox.md',
    'MxCheckboxRow',
  ),
  'SegmentedTray': _ComponentContract(
    'C-inputs-selection/segmented-tray.md',
    'MxSegmentedTray',
  ),
  'Stepper': _ComponentContract('C-inputs-selection/stepper.md', 'MxStepper'),
  'FieldMessage': _ComponentContract(
    'C-inputs-selection/field-message.md',
    'MxFieldMessage',
  ),
  'Card': _ComponentContract('D-surfaces-content/card.md', 'MxCard'),
  'Section': _ComponentContract('D-surfaces-content/section.md', 'MxSection'),
  'ListRow': _ComponentContract('D-surfaces-content/list-row.md', 'MxListRow'),
  'SettingsRow': _ComponentContract(
    'D-surfaces-content/settings-row.md',
    'MxSettingsRow',
  ),
  'IconTile': _ComponentContract(
    'D-surfaces-content/icon-tile.md',
    'MxIconTile',
  ),
  'ActionSheetCommandRow': _ComponentContract(
    'D-surfaces-content/action-sheet-command-row.md',
    'MxActionSheet',
  ),
  'ListSectionHeader': _ComponentContract(
    'D-surfaces-content/list-section-header.md',
    'MxSectionLabel',
  ),
  'Badge': _ComponentContract('E-status-metadata/badge.md', 'MxBadge'),
  'StatusBadge': _ComponentContract(
    'E-status-metadata/status-badge.md',
    'MxStatusBadge',
  ),
  'TagChip': _ComponentContract('E-status-metadata/tag-chip.md', 'MxTagChip'),
  'Note': _ComponentContract('E-status-metadata/note.md', 'MxNote'),
  'MasteryRamp': _ComponentContract(
    'E-status-metadata/mastery-ramp.md',
    'MxProgressBar',
  ),
  'WorkloadBreakdownLine': _ComponentContract(
    'E-status-metadata/workload-breakdown-line.md',
    'MxWorkloadBreakdownLine',
  ),
  'MasteryDonut': _ComponentContract(
    'E-status-metadata/mastery-donut.md',
    'MxMasteryDonut',
  ),
  'Scrim': _ComponentContract('F-overlays-feedback/scrim.md', 'platform'),
  'Dialog': _ComponentContract(
    'F-overlays-feedback/dialog.md',
    'MxAlertDialog/MxConfirmDialog',
  ),
  'BottomSheet': _ComponentContract(
    'F-overlays-feedback/bottom-sheet.md',
    'MxSheet',
  ),
  'SheetActions': _ComponentContract(
    'F-overlays-feedback/sheet-actions.md',
    'MxSheetActions',
  ),
  'Snackbar': _ComponentContract(
    'F-overlays-feedback/snackbar.md',
    'MxUndoSnackBar',
  ),
  'InlineBanner': _ComponentContract(
    'F-overlays-feedback/inline-banner.md',
    'MxFeedbackBand',
  ),
  'DeckPickerSheet': _ComponentContract(
    'F-overlays-feedback/deck-picker-sheet.md',
    'MxDeckPickerSheet',
  ),
  'Skeleton': _ComponentContract(
    'G-loading-empty-error/skeleton.md',
    'MxSkeleton',
  ),
  'Spinner': _ComponentContract(
    'G-loading-empty-error/spinner.md',
    'MxSpinner',
  ),
  'EmptyState': _ComponentContract(
    'G-loading-empty-error/empty-state.md',
    'MxEmptyState',
  ),
  'ErrorState': _ComponentContract(
    'G-loading-empty-error/error-state.md',
    'MxErrorState',
  ),
  'AppShell': _ComponentContract(
    'H-layout-shell/app-shell.md',
    'AppNavigationShell/MxContentShell',
  ),
  'ScreenScroll': _ComponentContract(
    'H-layout-shell/screen-scroll.md',
    'MxScrollEndInset',
  ),
  'FooterBar': _ComponentContract(
    'H-layout-shell/footer-bar.md',
    'MxFooterBar',
  ),
};

void main() {
  test(
    'v3 handoff maps each of its 46 components to one implementation owner',
    () {
      expect(_contracts, hasLength(46));
      for (final entry in _contracts.entries) {
        expect(
          entry.value.target,
          isNotEmpty,
          reason: '${entry.key} has no owner',
        );
        expect(
          File('docs/design/v3/components/${entry.value.source}').existsSync(),
          isTrue,
          reason: '${entry.key} source contract is missing',
        );
      }
    },
  );
}
