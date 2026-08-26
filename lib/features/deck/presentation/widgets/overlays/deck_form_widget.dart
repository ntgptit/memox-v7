import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_button_pair.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/models/scheduler_type_model.dart';
import '../items/deck_scheduler_picker_widget.dart';
import '../support/deck_labels_widget.dart';
import '../../../domain/failures/deck_validation_failure.dart';
import '../../../domain/models/deck_name_model.dart';
import '../../states/deck_submit_state.dart';

/// The one deck form, used for create-root, create-sub-deck and rename.
///
/// Three flows, one widget, because they differ in exactly two ways: whether the
/// study-mode section is shown, and the words on the submit button. Three
/// near-identical forms would drift — the validation on one, the submitting
/// state on another — and the drift only shows up in whichever one is used
/// least.
///
/// It owns the `TextEditingController` and therefore the typed text. That is
/// what makes "a failed write keeps the input" true without the controller
/// storing it: the state a persistence error must not destroy never left the
/// widget (UC-02 E4).
///
/// It holds no business rule. BR-01 is owned by `DeckName.parse`, applied in the
/// use case; the controller maps the resulting typed `DeckValidationProblem` into
/// `state`, and this widget renders whichever problem it is handed.
class DeckFormWidget extends StatefulWidget {
  const DeckFormWidget({
    required this.title,
    required this.submitLabel,
    required this.state,
    required this.onSubmit,
    required this.onCancel,
    this.initialName = '',
    this.isSchedulerRequired = false,
    super.key,
  });

  /// Already-localized.
  final String title;
  final String submitLabel;

  final DeckSubmitState state;

  /// Called with the raw text the user typed — untrimmed — and, for a root deck,
  /// the chosen mode. Trim and BR-01 are `DeckName.parse`'s job in the use case,
  /// not the widget's. [scheduler] is null when the section is not shown or
  /// nothing has been picked — "not chosen" is a real state and BR-11 forbids
  /// defaulting it.
  final void Function(String name, SchedulerType? scheduler) onSubmit;

  /// Called when the form is genuinely finished with.
  ///
  /// The discard confirmation happens **before** this fires: the form owns the
  /// typed text, so it is the only thing that knows whether anything would be
  /// lost, and asking here keeps UC-02 A1 in one place instead of in every
  /// caller that opens a form.
  final VoidCallback onCancel;

  final String initialName;

  /// Only true for a root deck (BR-06: a sub-deck must not carry scheduler
  /// columns, so it must not be offered the choice).
  final bool isSchedulerRequired;

  @override
  State<DeckFormWidget> createState() => _DeckFormWidgetState();
}

class _DeckFormWidgetState extends State<DeckFormWidget> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );

  /// Null until the user picks. `setState` here is not state architecture — it
  /// is one widget-local selection that never outlives the form, and lifting it
  /// into a provider would make an unsubmitted radio button survive the sheet
  /// being dismissed.
  SchedulerType? _scheduler;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _hasUnsavedInput => _name.text.trim() != widget.initialName.trim();

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final nameProblem = state.nameProblem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(widget.title, style: context.texts.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        MxTextField(
          controller: _name,
          label: context.l10n.deckNameLabel,
          errorText: nameProblem == null
              ? null
              : context.deckFormError(nameProblem),
          isEnabled: !state.isSubmitting,
          shouldAutofocus: true,
          // Bounded at the rule's limit rather than one character past it: BR-01
          // says never truncate silently, and `maxLength` refuses further input
          // instead of trimming what is already there. The over-length error
          // still exists for text arriving by paste on platforms that allow it.
          maxLength: DeckName.maxLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        if (widget.isSchedulerRequired) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          DeckSchedulerPickerWidget(
            // The only call site with no section title of its own: the form
            // above it is a name field, so the radios need naming here.
            sectionLabel: context.l10n.schedulerSectionLabel,
            selected: _scheduler,
            isEnabled: !state.isSubmitting,
            errorText: state.isSchedulerMissing
                ? context.deckFormError(DeckValidationProblem.schedulerMissing)
                : null,
            onChanged: (value) => setState(() => _scheduler = value),
          ),
        ],
        if (state.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.deckWriteFailure(state.failure!),
            style: context.texts.bodySmall?.copyWith(
              color: context.semanticColors.danger,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        // **`MxButtonPair`, not a `Row` of two self-sized buttons.** Sized to
        // their labels, `Cancel` and `Create deck` are two different buttons
        // for one decision; the pair splits the footer evenly, matches their
        // heights and stacks when the line is too narrow for both.
        MxButtonPair(
          secondary: MxActionButton(
            label: context.l10n.commonCancelAction,
            onPressed: state.isSubmitting ? null : _cancel,
            variant: MxActionButtonVariant.secondary,
          ),
          primary: MxActionButton(
            label: widget.submitLabel,
            onPressed: _submit,
            isLoading: state.isSubmitting,
          ),
        ),
      ],
    );
  }

  void _submit() => widget.onSubmit(_name.text, _scheduler);

  /// Backs out, asking first if anything would be lost (UC-02 A1).
  ///
  /// `mounted` is re-checked after the dialog because the sheet can be
  /// dismissed while it is open, and calling back into a disposed widget's
  /// caller is the classic use-after-dispose.
  Future<void> _cancel() async {
    if (!_hasUnsavedInput) {
      widget.onCancel();

      return;
    }

    final bool shouldDiscard = await showMxConfirm(
      context,
      title: context.l10n.deckFormDiscardTitle,
      message: context.l10n.deckFormDiscardMessage,
      confirmLabel: context.l10n.deckFormDiscardConfirmAction,
      cancelLabel: context.l10n.commonCancelAction,
      variant: MxConfirmDialogVariant.destructive,
      // The draft is lost, the deck is not: warning.
      tone: MxDialogTone.warning,
    );

    if (!mounted) return;
    if (shouldDiscard) widget.onCancel();
  }
}

/// The mandatory study-mode choice (UC-02 steps 2–4, BR-11).
///
/// Radio rows rather than a dropdown: a dropdown has to show something when
/// closed, and whatever it shows becomes a default — which is exactly what
/// BR-11 forbids. Nothing is selected until the user selects it.
