import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/models/study_entry_summary_model.dart';
import '../../../domain/models/study_mode.dart';
import '../support/study_labels_widget.dart';
import '../../../../../shared/widgets/mx_sheet_insets.dart';

/// Picks the one mode a review session will run in (BR-146).
///
/// **A mode that cannot run is disabled with its reason, never hidden** (BR-99).
/// A control that vanishes reads as a bug; a control that says "needs cards with
/// an example" tells the user what to do about it.
///
/// **Each mode shows its own count** (BR-154). `fill` only accepts cards
/// carrying an `example`, and that field is optional — so a twenty-card review
/// can be three cards long in that one mode, and a single number against four
/// modes would be lying about three of them.
class StudyModeChooserWidget extends StatelessWidget {
  const StudyModeChooserWidget({
    required this.modes,
    required this.summary,
    required this.onModeSelected,
    super.key,
  });

  /// What the deck's algorithm offers (BR-146). `browse` is never in here.
  final List<StudyMode> modes;

  final StudyEntrySummaryModel summary;
  final ValueChanged<StudyMode> onModeSelected;

  /// How many cards [mode] can take, asked of the mode itself (AD-18).
  ///
  /// This was a `switch` here until the handlers existed, which is a second
  /// dispatch on `StudyMode` and exactly what the guard rule forbids. Asking the
  /// handler puts each rule in the file that owns it: `fill` counts examples,
  /// `guess` needs five distinct meanings, `match` needs two pairs.
  int _capacity(StudyMode mode) =>
      studyModeHandler(mode)?.capacityFrom(summary) ?? 0;

  /// **Scrollable, and the bottom inset is the sheet's own.**
  ///
  /// A modal sheet is capped at a fraction of the screen; four modes, each with
  /// a count or a reason under it, pass that cap on a short screen and well
  /// before a large text scale. The overflow was found by the direction
  /// chooser's entry test (BR-203) rather than by anything about the modes —
  /// same shape, same fix, and neither changes the layout when it fits.
  @override
  Widget build(BuildContext context) => MxSheetInsets(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The sheet's title announces as a header (A20.1 P1-01, §23 #17).
          Semantics(
            header: true,
            child: Text(
              context.l10n.studyChooseModeTitle,
              style: context.texts.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final mode in modes) _tile(context, mode),
        ],
      ),
    ),
  );

  Widget _tile(BuildContext context, StudyMode mode) {
    final count = _capacity(mode);
    final isAvailable = count > 0;

    return MxListTile(
      title: context.studyMode(mode),
      subtitle: isAvailable
          ? context.l10n.studyModeCardCount(count)
          : context.studyModeUnavailable(mode),
      onTap: isAvailable ? () => onModeSelected(mode) : null,
    );
  }
}
