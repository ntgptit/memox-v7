import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context_extension.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/mx_action_button.dart';
import '../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../shared/widgets/mx_text_field.dart';
import '../domain/deck_entity.dart';
import '../domain/scheduler_type_model.dart';
import 'deck_copy_widget.dart';
import 'deck_submit_state.dart';

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
/// It holds no business rule. The name check comes from
/// `DeckEntity.nameProblem`, evaluated by the controller; this widget renders
/// whichever problem it is handed.
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

  /// Called with the trimmed-as-typed name and, for a root deck, the chosen
  /// mode. [scheduler] is null when the section is not shown or nothing has
  /// been picked — "not chosen" is a real state and BR-11 forbids defaulting it.
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
              : context.deckNameError(nameProblem),
          isEnabled: !state.isSubmitting,
          shouldAutofocus: true,
          // Bounded at the rule's limit rather than one character past it: BR-01
          // says never truncate silently, and `maxLength` refuses further input
          // instead of trimming what is already there. The over-length error
          // still exists for text arriving by paste on platforms that allow it.
          maxLength: DeckEntity.maxNameLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        if (widget.isSchedulerRequired) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _SchedulerPicker(
            selected: _scheduler,
            isEnabled: !state.isSubmitting,
            errorText: state.isSchedulerMissing
                ? context.l10n.schedulerMissingError
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
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            MxActionButton(
              label: context.l10n.commonCancelAction,
              onPressed: state.isSubmitting ? null : _cancel,
              variant: MxActionButtonVariant.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            MxActionButton(
              label: widget.submitLabel,
              onPressed: _submit,
              isLoading: state.isSubmitting,
            ),
          ],
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

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => MxConfirmDialog(
        title: dialogContext.l10n.deckFormDiscardTitle,
        message: dialogContext.l10n.deckFormDiscardMessage,
        confirmLabel: dialogContext.l10n.deckFormDiscardConfirmAction,
        cancelLabel: dialogContext.l10n.commonCancelAction,
        variant: MxConfirmDialogVariant.destructive,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (!mounted) return;
    if (shouldDiscard ?? false) widget.onCancel();
  }
}

/// The mandatory study-mode choice (UC-02 steps 2–4, BR-11).
///
/// Radio rows rather than a dropdown: a dropdown has to show something when
/// closed, and whatever it shows becomes a default — which is exactly what
/// BR-11 forbids. Nothing is selected until the user selects it.
class _SchedulerPicker extends StatelessWidget {
  const _SchedulerPicker({
    required this.selected,
    required this.isEnabled,
    required this.errorText,
    required this.onChanged,
  });

  final SchedulerType? selected;
  final bool isEnabled;
  final String? errorText;
  final ValueChanged<SchedulerType?> onChanged;

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
