import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_sizing.dart';

/// Where the hairline between rows starts.
enum MxRowDividerInset {
  /// Full width — rows without a leading tile or glyph.
  none,

  /// Aligned past the leading column (56).
  leading,
}

/// Handoff ListRow grouping: rows on one surface, a hairline between each
/// pair, none after the last. The divider is the theme's (`outlineVariant`,
/// hairline — D2); this widget only decides where it goes.
///
/// **A row that leads with a tile owes the [MxRowDividerInset.leading] indent
/// its text column**: `AppSpacing.lg` inset, `MxIconTileSize.sm`, `AppSpacing.md`
/// gap — 56, the handoff Divider's indent. `app_sizing_test` pins the sum; the
/// Library, search and tag geometry tests pin each row's laid-out text on it.
class MxRowGroup extends StatelessWidget {
  const MxRowGroup({
    required this.children,
    this.inset = MxRowDividerInset.leading,
    super.key,
  });

  final List<Widget> children;
  final MxRowDividerInset inset;

  @override
  Widget build(BuildContext context) {
    final double indent = switch (inset) {
      MxRowDividerInset.none => 0,
      MxRowDividerInset.leading => AppSizing.listDividerIndent,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (int index, Widget child) in children.indexed) ...<Widget>[
          if (index > 0) Divider(indent: indent),
          child,
        ],
      ],
    );
  }
}
