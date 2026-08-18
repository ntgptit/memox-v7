import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_subheader_widget.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The gap between the header strip and the first body surface, measured.
///
/// This defect cannot be caught any other way. Every value involved is a
/// legitimate token — the shell's strip pads `xs` below itself for a reason
/// (the 320×2.0 overflow trade in `mx_content_shell.dart`), and the summary
/// section's own padding is tokens too — so the literal-hunting guard sees
/// nothing. The bug lives in the *sum*: two files each own half of one gap,
/// each half defensible alone, and the halves added up to 4px between two
/// same-width, same-radius surfaces, which read as a single glued blob.
/// Only geometry after layout can see a sum, hence `getRect`.
void main() {
  // Both sides of the breakpoint: the strip pads itself differently in each
  // (`mx_content_shell.dart`), and the glue was reported on a compact device.
  const surfaces = <String, Size>{
    'compact': Size(393, 852),
    'regular': Size(700, 900),
  };

  for (final entry in surfaces.entries) {
    testWidgets(
      'header strip and summary card are visibly separate — ${entry.key}',
      (tester) async {
        await pumpDeckScreen(
          tester,
          // **The due count is load-bearing here.** The summary panel follows
          // the level's due count unless the user has said otherwise, so a
          // fixture with nothing due renders the one-line link instead of the
          // card and there is no card to measure the gap to.
          repository: FakeDeckRepository.withSummaries(<DeckSummary>[
            fakeSummary(id: '1', name: 'Korean', dueCardCount: 3),
          ]),
          screen: const DeckListScreen(),
          surface: entry.value,
        );

        // **The strip, not the field.** M99.32 moved the search input onto its
        // own screen, so what sits above the body here is the path-and-action
        // strip. The defect is unchanged: two files each own half of one gap.
        final searchBottom = tester
            .getRect(find.byType(DeckSubheaderWidget))
            .bottom;
        final summaryTop = tester
            .getRect(find.byType(DeckLevelSummaryWidget))
            .top;

        // `sm` is the floor for two elements that are merely *related*; these
        // two are different sections. Anything under it reads as one shape.
        expect(
          summaryTop - searchBottom,
          greaterThanOrEqualTo(AppSpacing.sm),
          reason:
              'the header strip and the summary card must not read as one '
              'glued surface',
        );
      },
    );
  }
}
