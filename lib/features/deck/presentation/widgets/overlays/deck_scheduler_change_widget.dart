import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/failures/deck_conflict_failure.dart';
import '../../../domain/models/scheduler_type_model.dart';
import '../../controllers/deck_write_controller.dart';
import '../../states/deck_submit_state.dart';
import '../items/deck_scheduler_picker_widget.dart';
import '../support/deck_labels_widget.dart';
import 'deck_reset_progress_widget.dart';

/// The study-mode sheet of UC-03 — the unlocked change, and the locked
/// explanation that replaces it.
///
/// **One entry point for both states, because UC-03 A1 says the locked deck must
/// not hide the section.** Hiding it makes a user think the app cannot change
/// study mode at all; showing it locked, with the reason and the way through,
/// tells them what actually happened and what to do.
///
/// **Not styled like Reset learning progress, and that is a rule rather than
/// taste.** BR-12's change runs on a deck where nothing has been learned: no
/// history is discarded, no generation is spent, the confirmation has no second
/// list of losses. Borrowing Reset's destructive treatment would ask the user to
/// brace for something that is not happening — and would then have nothing left
/// to distinguish the operation that really does destroy a cycle (UC-07).
Future<void> showDeckSchedulerSheet(
  BuildContext context, {
  required DeckEntity deck,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => _SchedulerSheet(
    deck: deck,
    onClose: () => Navigator.of(sheetContext).pop(),
  ),
);

class _SchedulerSheet extends ConsumerStatefulWidget {
  const _SchedulerSheet({required this.deck, required this.onClose});

  final DeckEntity deck;
  final VoidCallback onClose;

  @override
  ConsumerState<_SchedulerSheet> createState() => _SchedulerSheetState();
}

class _SchedulerSheetState extends ConsumerState<_SchedulerSheet> {
  /// **Starts on the mode the deck already runs, never on null.** A radio group
  /// opening with nothing selected reads as "you have not chosen yet" on a deck
  /// that chose at creation (BR-11), and it makes confirming without touching
  /// anything impossible to distinguish from confirming a change.
  late SchedulerType _scheduler =
      widget.deck.schedulerType ?? SchedulerType.eightBox;

  /// BR-13, as the screen can see it. The repository re-reads it inside the
  /// transaction, so this decides what is *drawn*, never what is allowed.
  bool get _isLocked => widget.deck.firstAnsweredAt != null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: _isLocked ? _locked(context) : _unlocked(context),
          ),
        ),
      ),
    );
  }

  /// UC-03 A1: the section stays, and it carries the way out.
  List<Widget> _locked(BuildContext context) {
    final l10n = context.l10n;

    return <Widget>[
      Text(l10n.deckSchedulerLockedTitle, style: context.texts.titleLarge),
      const SizedBox(height: AppSpacing.md),
      Text(l10n.deckSchedulerLockedBody, style: context.texts.bodyMedium),
      const SizedBox(height: AppSpacing.lg),
      // Shown, disabled: which mode the deck runs is still the thing the user came
      // to find out, and an empty locked panel does not answer it.
      DeckSchedulerPickerWidget(
        selected: _scheduler,
        isEnabled: false,
        shouldShowLockNotice: false,
        onChanged: (_) {},
      ),
      const SizedBox(height: AppSpacing.xl),
      _resetAction(context),
      const SizedBox(height: AppSpacing.sm),
      MxActionButton(
        label: l10n.commonCancelAction,
        variant: MxActionButtonVariant.secondary,
        onPressed: widget.onClose,
      ),
    ];
  }

  /// The way through a lock: Reset learning progress (BR-44).
  ///
  /// Shared by the locked panel and by the refusal below it, because the two are
  /// the same dead end reached a moment apart — one drawn from a deck that was
  /// already locked, the other from a deck that locked while the sheet was open.
  /// Offering the route in the first case and only an error line in the second
  /// would make the race the one state with no way forward.
  Widget _resetAction(BuildContext context) => MxActionButton(
    label: context.l10n.deckResetProgressAction,
    variant: MxActionButtonVariant.secondary,
    onPressed: () {
      widget.onClose();
      unawaited(
        showDeckResetProgressConfirm(
          context,
          deck: widget.deck,
          // Locked means a card finished the chain, so there is something to
          // lose and BR-50's second list is the true one.
          hasLearnedCards: true,
        ),
      );
    },
  );

  /// Whether the last refusal was the lock landing mid-sheet (UC-03 E4).
  bool _isLockedRefusal(Failure? failure) =>
      failure is ConflictFailure &&
      failure.reason == DeckConflictReason.schedulerLocked;

  List<Widget> _unlocked(BuildContext context) {
    final l10n = context.l10n;
    final provider = changeUnlockedSchedulerControllerProvider(widget.deck.id);
    final submit = ref.watch(provider);

    ref.listen<DeckSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        widget.onClose();
      }
    });

    return <Widget>[
      Text(l10n.deckSchedulerChangeTitle, style: context.texts.titleLarge),
      const SizedBox(height: AppSpacing.md),
      // BR-14, in the user's terms: the schedules restart, the content does not
      // move. No second list, because nothing is being taken away.
      Text(l10n.deckSchedulerChangeBody, style: context.texts.bodyMedium),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.deckSchedulerChangeSessionNotice,
        style: context.texts.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      DeckSchedulerPickerWidget(
        selected: _scheduler,
        isEnabled: !submit.isSubmitting,
        // The notice is true here and worth saying: this is the last moment the
        // choice is free (BR-13).
        onChanged: (value) => setState(() => _scheduler = value ?? _scheduler),
      ),
      if (submit.failure != null) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        Text(
          context.deckWriteFailure(submit.failure!),
          style: context.texts.bodySmall?.copyWith(
            color: context.semanticColors.danger,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
      // UC-03 E4: the deck locked between drawing this sheet and confirming it.
      // Retrying can only fail the same way, so the primary action becomes the
      // one that still works rather than a button that is now a trap.
      if (_isLockedRefusal(submit.failure))
        _resetAction(context)
      else
        MxActionButton(
          label: l10n.deckSchedulerChangeConfirm,
          isLoading: submit.isSubmitting,
          onPressed: submit.isSubmitting
              ? null
              : () => ref
                    .read(provider.notifier)
                    .submit(schedulerType: _scheduler),
        ),
      const SizedBox(height: AppSpacing.sm),
      MxActionButton(
        label: l10n.commonCancelAction,
        variant: MxActionButtonVariant.secondary,
        onPressed: submit.isSubmitting ? null : widget.onClose,
      ),
    ];
  }
}
