import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/models/new_card_order_model.dart';
import '../../../domain/models/study_card_limit_model.dart';

/// The two study options, and the only place they are edited (BR-147, BR-148).
///
/// **The form holds its own draft, and the controller holds the outcome.** A
/// notifier cannot reach a `TextEditingController`, so a state that tried to own
/// the text would need the widget to push every keystroke into it — and the
/// keystroke is not a domain event.
///
/// **A saved value takes effect next session, not this one** (BR-139), which the
/// screen says out loud. Silence here reads as a change that failed to apply,
/// because the session on screen keeps the ceiling it opened with.
class StudyOptionsSectionWidget extends StatefulWidget {
  const StudyOptionsSectionWidget({
    required this.initialCardLimit,
    required this.initialNewCardOrder,
    required this.onSave,
    required this.isSubmitting,
    this.cardLimitProblem,
    super.key,
  });

  final int initialCardLimit;
  final NewCardOrder initialNewCardOrder;
  final void Function(String rawCardLimit, NewCardOrder newCardOrder) onSave;
  final bool isSubmitting;
  final StudyCardLimitProblem? cardLimitProblem;

  @override
  State<StudyOptionsSectionWidget> createState() =>
      _StudyOptionsSectionWidgetState();
}

class _StudyOptionsSectionWidgetState extends State<StudyOptionsSectionWidget> {
  late final TextEditingController _cardLimit = TextEditingController(
    text: '${widget.initialCardLimit}',
  );
  late NewCardOrder _order = widget.initialNewCardOrder;

  @override
  void dispose() {
    _cardLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.studyOptionsCardLimitLabel, style: context.texts.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        MxTextField(
          controller: _cardLimit,
          label: l10n.studyOptionsCardLimitLabel,
          // No hint: the field opens holding the value in force, so a hint
          // would be a second copy of the same number — and the default is not
          // what this deck necessarily uses.
          keyboardType: TextInputType.number,
          errorText: _cardLimitError(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.studyOptionsOrderLabel, style: context.texts.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final order in NewCardOrder.values)
              MxPillButton(
                label: _orderLabel(context, order),
                isSelected: _order == order,
                onPressed: () => setState(() => _order = order),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // BR-139 in one line: the session on screen keeps the ceiling it opened
        // with, so without this the change reads as one that did not apply.
        Text(l10n.studyOptionsNextSessionNote, style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        MxActionButton(
          label: l10n.studyOptionsSave,
          isLoading: widget.isSubmitting,
          onPressed: () => widget.onSave(_cardLimit.text, _order),
        ),
      ],
    );
  }

  String _orderLabel(BuildContext context, NewCardOrder order) =>
      switch (order) {
        NewCardOrder.created => context.l10n.studyOptionsOrderCreated,
        NewCardOrder.random => context.l10n.studyOptionsOrderRandom,
      };

  String? _cardLimitError(BuildContext context) =>
      switch (widget.cardLimitProblem) {
        StudyCardLimitProblem.notANumber =>
          context.l10n.studyOptionsCardLimitNotANumber,
        StudyCardLimitProblem.tooSmall || StudyCardLimitProblem.tooLarge =>
          context.l10n.studyOptionsCardLimitOutOfRange(
            kMinCardLimit,
            kMaxCardLimit,
          ),
        null => null,
      };
}
