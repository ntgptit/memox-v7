@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'golden_pump.dart';
import 'golden_specimens.dart';

/// Goldens for the compact type scale, on the narrowest screen the project
/// supports.
///
/// Split from `mx_components_golden_test.dart` at the 400-line guard. Its own
/// surface rather than more entries in that file's `cases`: the whole point is
/// the width, and 320 is the only width where the scale is active. The numbers
/// it produces are asserted in `test/core/theme/compact_scale_test.dart`; these
/// exist so a change to them has to be looked at.
void main() {
  const compactSurface = Size(320, 568);

  for (final entry in <String, Widget>{
    'compact_screen': const _CompactScreen(),
    // Same composition as the `card_prompt` case in the full-width suite, so
    // the only difference between the two baselines is the width and the type
    // scale it selects.
    'compact_card_prompt': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: MxCard(child: CardPrompt())),
      ),
    ),
  }.entries) {
    for (final isDark in <bool>[false, true]) {
      final mode = isDark ? 'dark' : 'light';

      testWidgets('${entry.key} — $mode', (tester) async {
        await pumpGolden(
          tester,
          CompactScaleWidget(child: entry.value),
          isDark: isDark,
          at: compactSurface,
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${entry.key}_$mode.png'),
        );
      });
    }
  }
}

/// A realistic screen: app bar with actions, a field, rows, a primary action.
///
/// Composed rather than reusing `scaffold`, because the compact scale shows up
/// in the interaction between them — a tighter gutter only matters once there is
/// a row whose subtitle was wrapping because of it.
class _CompactScreen extends StatelessWidget {
  const _CompactScreen();

  @override
  Widget build(BuildContext context) => MxContentShell(
    title: 'Academic Word List',
    isScrollable: true,
    actions: const <Widget>[
      MxIconButton(
        icon: Icons.search,
        semanticLabel: 'Search',
        onPressed: noop,
      ),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxTextField(controller: TextEditingController(), label: 'Filter cards'),
        const SizedBox(height: AppSpacing.lg),
        const MxListTile(
          title: 'ubiquitous',
          subtitle: 'present everywhere at once',
          leading: Icon(Icons.style_outlined),
          trailing: Icon(Icons.chevron_right),
        ),
        const MxListTile(
          title: 'ephemeral',
          subtitle: 'lasting for a very short time',
          leading: Icon(Icons.style_outlined),
          trailing: Icon(Icons.chevron_right),
        ),
        const SizedBox(height: AppSpacing.lg),
        const MxActionButton(label: 'Start review', onPressed: noop),
      ],
    ),
  );
}
