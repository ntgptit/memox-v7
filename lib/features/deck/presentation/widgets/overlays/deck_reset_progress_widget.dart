import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/models/scheduler_type_model.dart';
import '../../controllers/deck_write_controller.dart';
import '../../states/deck_submit_state.dart';
import '../items/deck_scheduler_picker_widget.dart';
import '../support/deck_labels_widget.dart';

/// The Reset learning progress confirmation (UC-07, BR-50).
///
/// **A sheet rather than `MxConfirmDialog`, and the rule is why.** BR-50 asks
/// for two lists — what is kept and what is lost — and UC-07 step 3 puts the
/// choice of study mode inside the same confirmation, because changing it is
/// the point of the operation. A confirm dialog takes one `message` string; the
/// three of those flattened into one paragraph is exactly the shape BR-50 was
/// written against.
Future<void> showDeckResetProgressConfirm(
  BuildContext context, {
  required DeckEntity deck,
  required bool hasLearnedCards,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => _ResetProgressSheet(
    deck: deck,
    hasLearnedCards: hasLearnedCards,
    onClose: () => Navigator.of(sheetContext).pop(),
  ),
);

class _ResetProgressSheet extends ConsumerStatefulWidget {
  const _ResetProgressSheet({
    required this.deck,
    required this.hasLearnedCards,
    required this.onClose,
  });

  final DeckEntity deck;

  /// Whether anything would actually be lost (UC-07 A2).
  final bool hasLearnedCards;

  final VoidCallback onClose;

  @override
  ConsumerState<_ResetProgressSheet> createState() =>
      _ResetProgressSheetState();
}

class _ResetProgressSheetState extends ConsumerState<_ResetProgressSheet> {
  /// Starts on what the deck already runs, so confirming without touching it is
  /// a plain reset (UC-07 A1) rather than an accidental change of algorithm.
  late SchedulerType _scheduler =
      widget.deck.schedulerType ?? SchedulerType.eightBox;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = resetLearningProgressControllerProvider(widget.deck.id);
    final submit = ref.watch(provider);

    ref.listen<DeckSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        widget.onClose();
      }
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.deckResetProgressTitle,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: l10n.deckResetProgressKeptTitle,
                body: l10n.deckResetProgressKeptBody,
                icon: Icons.check_circle_outline,
                tone: context.semanticColors.success,
              ),
              const SizedBox(height: AppSpacing.md),
              // UC-07 A2: still allowed, and said plainly. A deck nobody has
              // studied is the easiest case to reset and the one where a list of
              // losses would be a warning about nothing.
              _Section(
                title: l10n.deckResetProgressLostTitle,
                body: widget.hasLearnedCards
                    ? l10n.deckResetProgressLostBody
                    : l10n.deckResetProgressNothingToLose,
                icon: Icons.remove_circle_outline,
                tone: widget.hasLearnedCards
                    ? context.semanticColors.danger
                    : context.colors.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.deckResetProgressSchedulerLabel,
                style: context.texts.labelLarge,
              ),
              DeckSchedulerPickerWidget(
                selected: _scheduler,
                isEnabled: !submit.isSubmitting,
                // The lock is what this operation undoes (BR-44); repeating the
                // warning here would describe the state being left behind.
                shouldShowLockNotice: false,
                onChanged: (value) =>
                    setState(() => _scheduler = value ?? _scheduler),
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
              MxActionButton(
                label: l10n.deckResetProgressConfirm,
                variant: MxActionButtonVariant.destructive,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// One of BR-50's two lists: a heading, a line, and a glyph that carries the
/// same distinction for somebody who reads the shape before the words.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, color: tone, size: context.texts.titleMedium?.fontSize),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: context.texts.labelLarge?.copyWith(color: tone)),
            const SizedBox(height: AppSpacing.xs),
            Text(body, style: context.texts.bodyMedium),
          ],
        ),
      ),
    ],
  );
}
