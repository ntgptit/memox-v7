import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_checkbox_row.dart';
import 'package:memox/shared/widgets/mx_dropdown.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_menu_button.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
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
  // The pill and the badge moved here with M100.36 Phase 5: the pill is a
  // selection control, and the badge is what a pill is *not* — kept beside
  // it so the two are read together.
  MxStressSpecimen(
    // A readout, not a control: no target to reach, so the stress is the long
    // word at 2.0x inside a pill that must not clip it.
    name: 'MxBadge',
    build: () => const MxBadge(label: kLongLabel),
  ),
  MxStressSpecimen(
    // A pill's label is short by design, so the stress here is the *selected*
    // pair plus an icon: that is the widest it gets, and the tap target still has
    // to reach the minimum — the widget's own now, grown outside the ring.
    name: 'MxPillButton',
    build: () => const MxPillButton(
      label: kLongLabel,
      icon: Icons.filter_list,
      isSelected: true,
      onPressed: _noop,
    ),
    isInteractive: true,
  ),
  // The row's three states moved here with the pill: a picked row and a
  // picked pill are the same decision drawn twice (M100.36 4I).
  MxStressSpecimen(
    // The two states whose extra ink and fill are most likely to fail on a
    // squeezed row — #431 F18.1 found only the resting row stressed.
    name: 'MxListTile (selected)',
    build: () => const MxListTile(
      title: kLongTitle,
      subtitle: kLongLabel,
      leading: Icon(Icons.radio_button_checked),
      isSelected: true,
      onTap: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxListTile (disabled)',
    build: () => const MxListTile(
      title: kLongTitle,
      subtitle: kLongLabel,
      leading: Icon(Icons.style_outlined),
      trailing: Icon(Icons.chevron_right),
      isEnabled: false,
      onTap: _noop,
    ),
  ),
  MxStressSpecimen(
    name: 'MxListTile',
    build: () => const MxListTile(
      title: kLongTitle,
      subtitle: kLongMessage,
      leading: Icon(Icons.folder_outlined),
      trailing: Icon(Icons.chevron_right),
      onTap: _noop,
    ),
    isInteractive: true,
  ),
];
