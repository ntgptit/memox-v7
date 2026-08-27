import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_radio_rows.dart';
import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/scheduler_type_model.dart';
import '../support/deck_labels_widget.dart';

/// The choice of study mode, as a radio group.
///
/// **Shared by the two places the choice is made, and there are exactly two**:
/// creating a root deck (BR-11, mandatory) and resetting learning progress
/// (UC-07 step 3, the only way to change it afterwards — BR-44). It was private
/// to the create form until the second caller existed; a copy would have been a
/// second list of which schedulers may be chosen, and `unknown` is excluded by
/// a rule rather than by an oversight.
class DeckSchedulerPickerWidget extends StatelessWidget {
  const DeckSchedulerPickerWidget({
    required this.selected,
    required this.isEnabled,
    required this.onChanged,
    required this.sectionLabel,
    this.errorText,
    this.shouldShowLockNotice = true,
    super.key,
  });

  final SchedulerType? selected;
  final bool isEnabled;
  final String? errorText;
  final ValueChanged<SchedulerType?> onChanged;

  /// The heading above the radios, or null when the caller has already titled
  /// the section itself.
  ///
  /// **Required and nullable, which is the point.** This widget used to print
  /// `Study mode` unconditionally, so every caller that also titled its own
  /// section got two headings — and four of the five did. The change sheet read
  /// `Study mode` twice three lines apart; reset read `Study mode after the
  /// reset` directly above `Study mode`; the starter install read `Review
  /// schedule` above `Study mode`.
  ///
  /// A `showSectionLabel: false` flag would have fixed those four and left the
  /// trap: the rule "do not title this yourself if you already have a title"
  /// stays unwritten, and the next caller breaks it exactly as these did.
  /// Making the parameter required moves the decision to the compiler — a new
  /// call site cannot be added without answering the question.
  final String? sectionLabel;

  /// **False inside the reset confirmation**, where the notice would be a lie:
  /// the lock is what the user is in the middle of undoing (BR-44), so telling
  /// them the choice locks after the first review is a warning about the state
  /// they are leaving rather than the one they are entering.
  final bool shouldShowLockNotice;

  /// `unknown` is deliberately absent from [_choices]: it exists for reading
  /// a value a newer build wrote and is not a choice anyone may make (BR-11).
  static const List<SchedulerType> _choices = <SchedulerType>[
    SchedulerType.eightBox,
    SchedulerType.sm2,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (sectionLabel != null)
          Text(sectionLabel!, style: context.texts.labelLarge),
        MxRadioRows<SchedulerType>(
          values: _choices,
          selected: selected,
          isEnabled: isEnabled,
          onChanged: onChanged,
          labelOf: context.schedulerLabel,
          subtitleOf: context.schedulerDescription,
        ),
        if (shouldShowLockNotice)
          Text(
            context.l10n.schedulerLockNotice,
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: context.texts.bodySmall!.inked(context, AppInk.danger),
          ),
        ],
      ],
    );
  }
}
