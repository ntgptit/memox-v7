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
    name: 'MxSheet',
    build: () => const MxSheetHeader(title: kLongLabel),
  ),
];
