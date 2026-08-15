import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../../study/domain/models/new_card_order_model.dart';
import '../../../../study/domain/models/study_card_limit_model.dart';
import '../items/settings_choice_rows_widget.dart';
import '../items/settings_error_band_widget.dart';
import '../support/settings_labels_widget.dart';
import 'settings_section_widget.dart';
import '../../../../../core/theme/app_elevation.dart';

/// The app-wide study defaults, and the one group with a Save button
/// (BR-211, wireframe S2, S3).
///
/// **The form holds its own draft, and the controller holds the outcome.** A
/// notifier cannot reach a `TextEditingController`, so a state that tried to own
/// the text would need the widget to push every keystroke into it — and a
/// keystroke is not a domain event. `StudyOptionsSectionWidget` made the same
/// call for the same reason.
///
/// **Both values save together** (S3). They are one row-group in the data and
/// one thought for the user; a separate Save for the order would let somebody
/// change both and walk away having saved half.
///
/// **A failed save keeps the draft** (BR-216). The text field is not rebuilt
/// from [initialCardLimit] on failure — the controller only re-seeds it when a
/// *save succeeds* and a new persisted value arrives.
class SettingsStudyDefaultsSectionWidget extends StatefulWidget {
  const SettingsStudyDefaultsSectionWidget({
    required this.initialCardLimit,
    required this.initialNewCardOrder,
    required this.isSubmitting,
    required this.onSave,
    this.cardLimitProblem,
    this.failure,
    super.key,
  });

  /// The persisted values. A change here re-seeds the draft — see
  /// [_SettingsStudyDefaultsSectionWidgetState.didUpdateWidget] for the one
  /// case that must not.
  final int initialCardLimit;
  final NewCardOrder initialNewCardOrder;

  final bool isSubmitting;
  final void Function(String rawCardLimit, NewCardOrder newCardOrder) onSave;
  final StudyCardLimitProblem? cardLimitProblem;
  final Failure? failure;

  @override
  State<SettingsStudyDefaultsSectionWidget> createState() =>
      _SettingsStudyDefaultsSectionWidgetState();
}

class _SettingsStudyDefaultsSectionWidgetState
    extends State<SettingsStudyDefaultsSectionWidget> {
  late final TextEditingController _cardLimit = TextEditingController(
    text: '${widget.initialCardLimit}',
  );
  late NewCardOrder _order = widget.initialNewCardOrder;

  @override
  void didUpdateWidget(SettingsStudyDefaultsSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // **Re-seed only when the persisted value actually changed.** The stream
    // re-emits on every write to the row, including a theme change, and
    // re-seeding on every rebuild would wipe a card limit the user is halfway
    // through typing (BR-216).
    if (oldWidget.initialCardLimit != widget.initialCardLimit) {
      _cardLimit.text = '${widget.initialCardLimit}';
    }
    if (oldWidget.initialNewCardOrder != widget.initialNewCardOrder) {
      _order = widget.initialNewCardOrder;
    }
  }

  @override
  void dispose() {
    _cardLimit.dispose();
    super.dispose();
  }

  /// The one submit path, so `Save` and `Try again` cannot diverge — a retry
  /// that sent anything other than the current draft would save a value the
  /// user is no longer looking at.
  void _submit() => widget.onSave(_cardLimit.text, _order);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final band = widget.failure;

    return SettingsSectionWidget(
      label: l10n.settingsStudyDefaultsSection,
      child: MxCard(
        // Flat, like every other card in a scrolling column (D20). This
        // screen was the last one still taking `AppElevation.card`, and
        // its own error band already passes `none` for the same reason.
        elevation: AppElevation.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // **The field owns its label; there is no `Text` above it.**
            // `MxTextField` passes `label` to `InputDecoration.labelText` and
            // the theme leaves `floatingLabelBehavior` at `auto`, so a field
            // that always has a value always floats its label — the same
            // string then rendered twice, 4dp apart, and TalkBack read it
            // twice. The order group below keeps its `Text` because a radio
            // group has no decoration to carry one.
            MxTextField(
              controller: _cardLimit,
              label: l10n.studyOptionsCardLimitLabel,
              isEnabled: !widget.isSubmitting,
              keyboardType: TextInputType.number,
              errorText: context.cardLimitError(widget.cardLimitProblem),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.studyOptionsOrderLabel, style: context.texts.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            // **Radio rows, not the pills `StudyOptionsSectionWidget` uses.**
            // W6 requires a selected state not to rest on colour, and a
            // `ChoiceChip` under `buildChipTheme` differs when selected only in
            // fill and label colour — `showCheckmark` is false and `side` is
            // resolved for disabled and focused only. The three groups on this
            // screen therefore share one control, which is also what W1 draws.
            //
            // `contentPadding: zero` because this card already pads its content
            // — the rows must start on the same x as the label above them (W5).
            SettingsChoiceRowsWidget<NewCardOrder>(
              values: NewCardOrder.values,
              selected: _order,
              labelOf: context.newCardOrderLabel,
              onChanged: (order) => setState(() => _order = order),
              isSubmitting: widget.isSubmitting,
            ),
            const SizedBox(height: AppSpacing.lg),
            // BR-213 in one line. Without it the change reads as one that did
            // not apply, because a session already running keeps its ceiling.
            Text(
              l10n.settingsStudyDefaultsNote,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (band != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              SettingsErrorBandWidget(
                failure: band,
                onRetry: widget.isSubmitting ? null : _submit,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            MxActionButton(
              label: l10n.studyOptionsSave,
              isLoading: widget.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
