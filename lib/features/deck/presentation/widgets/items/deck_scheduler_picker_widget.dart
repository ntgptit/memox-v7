import 'package:flutter/material.dart';

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
    this.errorText,
    this.shouldShowLockNotice = true,
    super.key,
  });

  final SchedulerType? selected;
  final bool isEnabled;
  final String? errorText;
  final ValueChanged<SchedulerType?> onChanged;

  /// **False inside the reset confirmation**, where the notice would be a lie:
  /// the lock is what the user is in the middle of undoing (BR-44), so telling
  /// them the choice locks after the first review is a warning about the state
  /// they are leaving rather than the one they are entering.
  final bool shouldShowLockNotice;

  /// `unknown` is deliberately absent: it exists for reading a value a newer
  /// build wrote and is not a choice anyone may make (BR-11).
  static void _ignoreChange(SchedulerType? _) {}

  static const List<SchedulerType> _choices = <SchedulerType>[
    SchedulerType.eightBox,
    SchedulerType.sm2,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.schedulerSectionLabel,
          style: context.texts.labelLarge,
        ),
        // `RadioGroup`, not `RadioListTile.groupValue`: the per-tile group
        // parameters are deprecated as of Flutter 3.32 and this project treats
        // analyzer warnings as failures.
        // `RadioGroup.onChanged` is required and non-nullable, so the disabled
        // state lives on each tile instead. Both are set: `enabled` greys the
        // row and takes it out of the focus order, and the guarded callback
        // means a tap that somehow lands mid-submit changes nothing.
        RadioGroup<SchedulerType>(
          groupValue: selected,
          onChanged: isEnabled ? onChanged : _ignoreChange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final choice in _choices)
                RadioListTile<SchedulerType>(
                  value: choice,
                  enabled: isEnabled,
                  title: Text(context.schedulerLabel(choice)),
                  subtitle: Text(context.schedulerDescription(choice)),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        if (shouldShowLockNotice)
          Text(
            context.l10n.schedulerLockNotice,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: context.texts.bodySmall?.copyWith(
              color: context.semanticColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
