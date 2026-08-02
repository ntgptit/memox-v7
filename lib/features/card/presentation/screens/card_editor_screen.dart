import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/submit_outcome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_action_button.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_text_field.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/failures/card_validation_failure.dart';
import '../controllers/card_create_controller.dart';
import '../controllers/card_editor_load_controller.dart';
import '../controllers/card_flag_controller.dart';
import '../controllers/card_write_controller.dart';
import '../states/card_submit_state.dart';
import '../widgets/overlays/card_confirm_widget.dart';
import '../widgets/sections/card_tag_section_widget.dart';

/// The card editor — create and edit (UC-04 W4, A1).
///
/// One screen, two modes, decided by [cardId]: null creates, set edits. The two
/// share the front/back fields and the inline validation; they differ in title,
/// in the save paths (create offers save-and-add-another, edit does not), and in
/// what sits below the fields (edit adds a BR-10 reassurance and a danger zone).
///
/// It navigates nothing itself: each controller reports a [SubmitOutcome] and
/// this widget reacts — pop on `savedAndClose`, clear the form on
/// `savedAndContinue` — because a controller holding a `BuildContext` is the
/// crash `command_query_separation_test.dart` exists to forbid.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({required this.deckId, this.cardId, super.key});

  final String deckId;

  /// Null in create mode; the card being edited otherwise.
  final String? cardId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final TextEditingController _front = TextEditingController();
  final TextEditingController _back = TextEditingController();
  final FocusNode _frontFocus = FocusNode();

  /// Edit mode fills the fields once, when the card first arrives — re-filling
  /// on every rebuild would overwrite what the user is typing.
  bool _prefilled = false;

  bool get _isEditing => widget.cardId != null;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _isEditing ? _buildEdit(context, widget.cardId!) : _buildCreate(context);

  // ---- create ------------------------------------------------------------

  Widget _buildCreate(BuildContext context) {
    final provider = cardCreateProvider(widget.deckId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        Navigator.of(context).pop();
        return;
      }
      // Save-and-add-another: empty the form, return focus to the front, and
      // clear the outcome so the next save is a fresh attempt (UC-04 A4).
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        _front.clear();
        _back.clear();
        _frontFocus.requestFocus();
        controller.reset();
      }
    });

    final busy = state.isSubmitting;

    return MxContentShell(
      title: context.l10n.cardEditorCreateTitle,
      leading: _closeButton(context),
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ..._fields(state, busy: busy, autofocus: true),
          const SizedBox(height: AppSpacing.xl),
          MxActionButton(
            label: context.l10n.cardEditorSave,
            onPressed: busy
                ? null
                : () => controller.submit(
                    rawFront: _front.text,
                    rawBack: _back.text,
                  ),
            isLoading: busy,
          ),
          const SizedBox(height: AppSpacing.md),
          MxActionButton(
            label: context.l10n.cardEditorSaveAndAdd,
            variant: MxActionButtonVariant.secondary,
            onPressed: busy
                ? null
                : () => controller.submit(
                    rawFront: _front.text,
                    rawBack: _back.text,
                    disposition: SubmitDisposition.addAnother,
                  ),
          ),
        ],
      ),
    );
  }

  // ---- edit --------------------------------------------------------------

  Widget _buildEdit(BuildContext context, String cardId) {
    final loaded = ref.watch(cardToEditProvider(cardId));

    return loaded.when(
      loading: () => _shell(
        context,
        title: context.l10n.cardEditorEditTitle,
        body: Center(
          child: Semantics(
            label: context.l10n.cardEditorLoadingLabel,
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => _shell(
        context,
        title: context.l10n.cardEditorEditTitle,
        body: MxEmptyState(
          icon: Icons.error_outline,
          title: context.l10n.cardEditorLoadFailed,
          actionLabel: context.l10n.cardEditorLoadRetry,
          onAction: () => Navigator.of(context).pop(),
        ),
      ),
      data: (card) => _buildEditForm(context, cardId, card),
    );
  }

  Widget _buildEditForm(BuildContext context, String cardId, CardEntity card) {
    if (!_prefilled) {
      _front.text = card.front;
      _back.text = card.back;
      _prefilled = true;
    }

    final provider = cardEditProvider(cardId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        Navigator.of(context).pop();
      }
    });

    final busy = state.isSubmitting;

    return _shell(
      context,
      title: context.l10n.cardEditorEditTitle,
      actions: <Widget>[_flagToggle(cardId)],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ..._fields(state, busy: busy, autofocus: false),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.cardEditorProgressNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          MxActionButton(
            label: context.l10n.cardEditorSaveChanges,
            onPressed: busy
                ? null
                : () => controller.submit(
                    rawFront: _front.text,
                    rawBack: _back.text,
                  ),
            isLoading: busy,
          ),
          const SizedBox(height: AppSpacing.xl),
          CardTagSectionWidget(cardId: cardId),
          const SizedBox(height: AppSpacing.xxl),
          _dangerZone(context, cardId, disabled: busy),
        ],
      ),
    );
  }

  Widget _dangerZone(
    BuildContext context,
    String cardId, {
    required bool disabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.cardEditorDangerZone,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        MxActionButton(
          label: context.l10n.cardEditorDelete,
          variant: MxActionButtonVariant.destructive,
          onPressed: disabled
              ? null
              : () => showCardDeleteConfirm(
                  context,
                  cardId: cardId,
                  onDeleted: () => Navigator.of(context).pop(),
                ),
        ),
      ],
    );
  }

  // ---- shared ------------------------------------------------------------

  /// The two required sides plus the write-failed banner, shared by both modes.
  List<Widget> _fields(
    CardSubmitState state, {
    required bool busy,
    required bool autofocus,
  }) {
    return <Widget>[
      MxTextField(
        controller: _front,
        focusNode: _frontFocus,
        label: context.l10n.cardFrontLabel,
        hintText: context.l10n.cardFrontHint,
        isEnabled: !busy,
        shouldAutofocus: autofocus,
        maxLength: kCardFrontMaxLength,
        maxLines: 2,
        minLines: 1,
        errorText: _frontError(state.frontProblem),
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: AppSpacing.lg),
      MxTextField(
        controller: _back,
        label: context.l10n.cardBackLabel,
        hintText: context.l10n.cardBackHint,
        isEnabled: !busy,
        maxLength: kCardBackMaxLength,
        maxLines: 4,
        minLines: 2,
        errorText: _backError(state.backProblem),
      ),
      if (state.failure != null) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.cardEditorSaveFailed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    ];
  }

  Widget _shell(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget>? actions,
  }) => MxContentShell(
    title: title,
    leading: _closeButton(context),
    actions: actions,
    isScrollable: true,
    body: body,
  );

  /// The flag toggle, filled when the card is flagged (BR-92). Disabled until
  /// the flag has loaded, so a tap can never write against an unknown value. The
  /// icon reads the [cardFlag] stream; the tap is a [SetCardFlag] command, and
  /// the stream re-emits the written value.
  Widget _flagToggle(String cardId) {
    final flag = ref.watch(cardFlagProvider(cardId));
    final isFlagged = flag.value ?? false;

    return IconButton(
      icon: Icon(isFlagged ? Icons.flag : Icons.outlined_flag),
      onPressed: flag.isLoading
          ? null
          : () => ref
                .read(setCardFlagProvider(cardId).notifier)
                .submit(isFlagged: !isFlagged),
      tooltip: isFlagged
          ? context.l10n.cardEditorUnflagAction
          : context.l10n.cardEditorFlagAction,
    );
  }

  Widget _closeButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.close),
    onPressed: () => Navigator.of(context).pop(),
    tooltip: context.l10n.cardEditorClose,
  );

  String? _frontError(CardValidationProblem? problem) => switch (problem) {
    CardValidationProblem.frontEmpty => context.l10n.cardFrontEmptyError,
    CardValidationProblem.frontTooLong => context.l10n.cardFrontTooLongError,
    _ => null,
  };

  String? _backError(CardValidationProblem? problem) => switch (problem) {
    CardValidationProblem.backEmpty => context.l10n.cardBackEmptyError,
    CardValidationProblem.backTooLong => context.l10n.cardBackTooLongError,
    _ => null,
  };
}
