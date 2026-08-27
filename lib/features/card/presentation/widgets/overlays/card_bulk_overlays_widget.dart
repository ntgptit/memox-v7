import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_form_dialog.dart';
import '../../../domain/models/card_move_target_model.dart';
import '../../../domain/models/tag_name_model.dart';
import '../../controllers/card_bulk_controller.dart';
import '../../controllers/card_move_target_controller.dart';
import '../../controllers/card_selection_controller.dart';
import '../../states/card_submit_state.dart';
import '../support/card_failure_labels_widget.dart';
import '../support/tag_labels_widget.dart';

/// The bulk-delete confirmation (UC-04 A6).
///
/// **It names the number and the consequence.** A generic "Are you sure?"
/// leaves the user to guess how many rows a selection covers — and after a
/// Select all that number is the whole filtered deck. The study history goes
/// with the cards, which is the part nobody predicts from the word "delete",
/// and the batch goes to Trash and can come back for 30 days (BR-256).
///
/// Returns true only when the user confirmed.
Future<bool> showCardBulkDeleteConfirm(
  BuildContext context, {
  required int count,
}) {
  final l10n = context.l10n;

  return showMxConfirm(
    context,
    // `cautious`, like the single-item deletes this PR relabelled:
    // the batch is recoverable, but Cancel keeps the default focus.
    variant: MxConfirmDialogVariant.cautious,
    // Recoverable for thirty days, so it warns rather than alarms — the error
    // tone stays with the purge that ends that window (BR-256, BR-266).
    tone: MxDialogTone.warning,
    title: l10n.cardBulkDeleteTitle(count),
    message: l10n.cardBulkDeleteMessage,
    confirmLabel: l10n.cardBulkDeleteConfirmAction,
    cancelLabel: l10n.commonCancelAction,
  );
}

/// The move-target picker (UC-04 A5, BR-165).
///
/// **The list is the rule.** Every row the stream yields is already a legal
/// target — same tree, not a root, not holding sub-decks, not the source — so
/// this sheet renders and never re-derives; a picker that filtered again would
/// be a second owner of BR-165, free to disagree with the repository that
/// actually decides.
///
/// Returns the chosen deck id, or null if the user backed out.
Future<String?> showCardMoveTargetSheet(
  BuildContext context, {
  required String sourceDeckId,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => _MoveTargetSheet(sourceDeckId: sourceDeckId),
);

class _MoveTargetSheet extends ConsumerWidget {
  const _MoveTargetSheet({required this.sourceDeckId});

  final String sourceDeckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = ref.watch(cardMoveTargetsProvider(sourceDeckId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.cardMoveTargetTitle,
              style: context.texts.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: targets.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => MxEmptyState(
                  icon: Icons.error_outline,
                  title: context.l10n.unexpectedErrorTitle,
                  message: error is Failure
                      ? context.l10n.cardMoveEmptyMessage
                      : context.l10n.cardMoveEmptyMessage,
                ),
                data: (list) => list.isEmpty
                    ? MxEmptyState(
                        icon: Icons.folder_off_outlined,
                        title: context.l10n.cardMoveEmptyTitle,
                        message: context.l10n.cardMoveEmptyMessage,
                      )
                    : _TargetList(targets: list),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetList extends StatelessWidget {
  const _TargetList({required this.targets});

  final List<CardMoveTarget> targets;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: targets.length,
      itemBuilder: (context, index) {
        final target = targets[index];

        // The parent's name is what tells two same-named decks apart; a deck
        // whose parent vanished mid-read simply shows no second line.
        return MxListTile(
          leading: const Icon(Icons.folder_outlined),
          title: target.name,
          subtitle: target.parentName,
          onTap: () => Navigator.of(context).pop(target.deckId),
        );
      },
    );
  }
}

/// Asks for the one tag a bulk add will apply (UC-04 A6, BR-93).
///
/// **A name, not a picker.** Tag reuse happens by folded name in the
/// repository (BR-93), so typing an existing tag attaches that tag rather than
/// minting a second one — which means a list of existing tags would be a
/// convenience, not a rule, and it is not what this task buys.
///
/// Returns null when the user cancels or types something the value object
/// refuses; the parse is the validation, exactly as the editor's tag field
/// does it.
Future<TagName?> showCardBulkTagPrompt(BuildContext context) {
  final l10n = context.l10n;

  return showMxPromptDialog<TagName>(
    context,
    title: l10n.cardSelectionAddTagAction,
    fieldLabel: l10n.cardEditorTagAddHint,
    hintText: l10n.cardEditorTagAddHint,
    maxLength: TagName.maxLength,
    confirmLabel: l10n.cardSelectionAddTagAction,
    cancelLabel: l10n.commonCancelAction,
    // **The refusal now says which rule refused it.** This used to be
    // `if (name == null) return;` inside the confirm button: an empty name, a
    // name over the limit and a name with a control character all produced the
    // same nothing — a button press with no dialog change and no message. The
    // mapping already existed in `tagProblemLabel`; what was missing was
    // anywhere to put its answer.
    parse: (raw) {
      final parsed = TagName.parse(raw);

      return (
        value: parsed.name,
        error: context.tagProblemLabel(parsed.problem),
      );
    },
  );
}

/// Runs one bulk command over the selection and reports what happened
/// (UC-04 A6, BR-166, BR-167).
///
/// **The controller writes; this shows and clears.** A controller holding a
/// `BuildContext` is what `command_query_separation_test.dart` forbids, so the
/// split is: the command owns the transaction and its submit state, the
/// selection owns the set, and the screen — where a context legitimately
/// exists — reads both and speaks.
///
/// The selection is cleared only on success. A refusal keeps it so the user
/// can read why and retry; clearing would make a refusal look like a completed
/// action with a surprising result.
///
/// The message is a statement of what happened, never an Undo: this build
/// deletes study history with the cards and cannot put it back.
Future<void> runBulk(
  BuildContext context,
  WidgetRef ref,
  String deckId, {
  required Future<void> Function(List<String> ids) submit,
  required CardSubmitState Function() readState,
  required String Function(int count) success,
}) async {
  final selection = ref.read(cardSelectionProvider(deckId));
  if (!selection.hasSelection) return;

  final count = selection.selectedCount;
  await submit(selection.orderedIds);
  if (!context.mounted) return;

  final result = readState();
  final failure = result.failure;
  if (failure == null) ref.read(cardSelectionProvider(deckId).notifier).clear();

  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        failure == null ? success(count) : context.cardWriteFailure(failure),
      ),
    ),
  );
}

/// Move: pick a target, then run the command (UC-04 A5, BR-165).
Future<void> bulkMove(
  BuildContext context,
  WidgetRef ref,
  String deckId,
) async {
  final targetDeckId = await showCardMoveTargetSheet(
    context,
    sourceDeckId: deckId,
  );
  if (targetDeckId == null || !context.mounted) return;

  final controller = ref.read(moveCardsProvider(deckId).notifier);
  await runBulk(
    context,
    ref,
    deckId,
    submit: (ids) =>
        controller.submit(cardIds: ids, targetDeckId: targetDeckId),
    readState: () => ref.read(moveCardsProvider(deckId)),
    success: (count) => context.l10n.cardBulkMovedMessage(count),
  );
}

/// Add one tag to the selection (UC-04 A6, BR-93, BR-94).
Future<void> bulkAddTag(
  BuildContext context,
  WidgetRef ref,
  String deckId,
) async {
  final name = await showCardBulkTagPrompt(context);
  if (name == null || !context.mounted) return;

  final controller = ref.read(addTagToCardsProvider(deckId).notifier);
  await runBulk(
    context,
    ref,
    deckId,
    submit: (ids) => controller.submit(cardIds: ids, name: name),
    readState: () => ref.read(addTagToCardsProvider(deckId)),
    success: (count) => context.l10n.cardBulkUpdatedMessage(count),
  );
}

/// Set or clear the flag — explicit, never a toggle (BR-166).
Future<void> bulkFlag(
  BuildContext context,
  WidgetRef ref,
  String deckId, {
  required bool isFlagged,
}) {
  final controller = ref.read(setCardsFlagProvider(deckId).notifier);

  return runBulk(
    context,
    ref,
    deckId,
    submit: (ids) => controller.submit(cardIds: ids, isFlagged: isFlagged),
    readState: () => ref.read(setCardsFlagProvider(deckId)),
    success: (count) => context.l10n.cardBulkUpdatedMessage(count),
  );
}

/// Delete the selection, after a confirmation that names the number and the
/// consequence (UC-04 A6).
Future<void> bulkDelete(
  BuildContext context,
  WidgetRef ref,
  String deckId,
) async {
  final count = ref.read(cardSelectionProvider(deckId)).selectedCount;
  final confirmed = await showCardBulkDeleteConfirm(context, count: count);
  if (!confirmed || !context.mounted) return;

  final controller = ref.read(deleteCardsProvider(deckId).notifier);
  await runBulk(
    context,
    ref,
    deckId,
    submit: controller.submit,
    readState: () => ref.read(deleteCardsProvider(deckId)),
    success: (deleted) => context.l10n.cardBulkDeletedMessage(deleted),
  );
}
