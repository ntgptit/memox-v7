import 'package:memox/shared/widgets/mx_checkbox_row.dart';
import 'package:memox/shared/widgets/mx_dropdown.dart';
import 'package:memox/shared/widgets/mx_menu_button.dart';
import 'package:memox/shared/widgets/mx_radio_rows.dart';
import 'package:memox/shared/widgets/mx_switch_row.dart';

import 'mx_stress_specimens.dart';

/// The selection-control specimens, split from `mx_stress_specimens.dart`
/// for the same reason that file is split from the cases: together they
/// exceed the file size the guard allows.
void _noop() {}

void _noopIndex(int index) {}

void _noopBool(bool value) {}

void _noopNullableIndex(int? index) {}

List<MxStressSpecimen> selectionStressSpecimens() => <MxStressSpecimen>[
  MxStressSpecimen(
    // The anchor is the standard overflow glyph; the long words live in the
    // tooltip and the (closed) menu, so the stress here is the anchor's
    // target and name, not its layout.
    name: 'MxMenuButton',
    build: () => const MxMenuButton(
      tooltip: kLongLabel,
      actions: <MxMenuAction>[
        MxMenuAction(label: kLongLabel, onSelected: _noop),
      ],
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxSwitchRow',
    build: () =>
        const MxSwitchRow(label: kLongTitle, isOn: true, onChanged: _noopBool),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // The announced variant: the label wraps beside the switch instead of
    // pushing it off the row.
    name: 'MxSwitchRow (announced)',
    build: () => const MxSwitchRow(
      label: kLongTitle,
      announcedValue: 'Bật',
      isOn: true,
      onChanged: _noopBool,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxCheckboxRow',
    build: () => const MxCheckboxRow(
      label: kLongTitle,
      subtitle: kLongMessage,
      isChecked: true,
      onToggle: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // Two rows, long labels, one-line subtitles: the stress is that the
    // label wraps inside its row. Growing taller than a screen is the
    // surrounding scrollable's job, not the group's.
    name: 'MxRadioRows',
    build: () => MxRadioRows<int>(
      values: const <int>[0, 1],
      selected: 0,
      onChanged: _noopIndex,
      labelOf: (int value) => kLongLabel,
      subtitleOf: (int value) => 'Hai hộp, tám bậc ôn tập',
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // One option long enough to need the single-line ellipsis the widget
    // promises instead of growing the row.
    name: 'MxDropdown',
    build: () => const MxDropdown<int>(
      value: 0,
      onChanged: _noopNullableIndex,
      options: <MxDropdownOption<int>>[
        MxDropdownOption<int>(value: 0, label: kLongTitle),
        MxDropdownOption<int>(value: 1, label: 'B'),
      ],
    ),
    isInteractive: true,
  ),
];
