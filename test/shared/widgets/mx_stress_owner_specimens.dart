import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_reading_column.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_section_label.dart';
import 'package:memox/shared/widgets/mx_sheet.dart';

import 'mx_stress_specimens.dart';

/// The semantic owners the Design System V1 closure added (A20.1 Phase 4),
/// split out of `mx_stress_specimens.dart` at the 400-line guard.
List<MxStressSpecimen> ownerStressSpecimens() => <MxStressSpecimen>[
  MxStressSpecimen(
    // One line, ellipsised: a heading that wrapped would push the list it
    // names; the stress is the long label at 2.0x staying on its line.
    name: 'MxSectionLabel',
    build: () => const MxSectionLabel(label: kLongLabel, detail: '128'),
  ),
  MxStressSpecimen(
    // A long title above and a long row inside: the stress is the label
    // wrapping to its ellipsis and the row content wrapping without
    // breaking the hairline divider — kept to two rows and a short note so
    // the specimen itself stays inside the 320 x 640 stress frame at 2.0x,
    // the same budget every non-scrolling specimen here works within.
    name: 'MxSection',
    build: () => MxSection(
      title: kLongTitle,
      note: kLongLabel,
      rows: const <Widget>[
        ListTile(title: Text(kLongLabel)),
        ListTile(title: Text('Sound')),
      ],
    ),
  ),
  MxStressSpecimen(
    // The tile beside a long title in a row: the stress is the text column
    // giving up the width and the 44dp tile keeping its box at 2.0x.
    name: 'MxIconTile',
    build: () => const Row(
      children: <Widget>[
        MxIconTile(icon: Icons.folder, size: MxIconTileSize.lg),
        Expanded(child: Text(kLongTitle)),
      ],
    ),
  ),
  MxStressSpecimen(
    name: 'MxReadingColumn',
    build: () => const MxReadingColumn(child: Text(kLongTitle)),
  ),
  MxStressSpecimen(
    name: 'MxSheet',
    build: () => const MxSheetHeader(title: kLongLabel),
  ),
  MxStressSpecimen(
    name: 'MxListRow',
    isInteractive: true,
    build: () => MxListRow(
      title: kLongTitle,
      subtitle: kLongMessage,
      leadingIcon: Icons.layers_outlined,
      trailingIcon: Icons.chevron_right,
      onTap: () {},
    ),
  ),
];
