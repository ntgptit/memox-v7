import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_messenger.dart';
import '../../../../../shared/widgets/mx_undo_snack_bar.dart';
import '../../../../trash/domain/failures/trash_conflict_failure.dart';
import '../../providers/deck_undo_provider.dart';

/// Reports that a deck went to Trash, and offers to take it back (BR-256,
/// BR-263).
///
/// **The Deck feature owns its own Undo wiring.** It could not be otherwise: a
/// feature may not import another feature's `presentation/`, so the snackbar
/// itself is a `shared/` widget that knows nothing about Trash, and the
/// dependency here is the Trash **domain** contract, declared in Trash's `di/`
/// and bound at the composition root — the same shape as Deck's dependency on
/// `StudyRepository`.
///
/// A null [batchId] means the delete failed and the dialog has already said so;
/// there is nothing to report and nothing to undo.
void showDeckMovedToTrash(
  BuildContext context,
  WidgetRef ref, {
  required String? batchId,
}) {
  if (batchId == null) return;

  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  showMxUndoSnackBar(
    context,
    message: l10n.trashMovedMessage,
    undoLabel: l10n.trashUndoAction,
    onUndo: () async {
      try {
        await ref.read(deckUndoUseCaseProvider)(batchId);

        return null;
      } on Object catch (error) {
        return error;
      }
    },
    // **The reason travels, and it has to** (UC-21 E3). "That couldn't be
    // undone" leaves the user with no idea where the item went; the typed
    // reason is the sentence that points them at Trash. `trashUndoFailed` is
    // the fallback for a failure with no reason worth distinguishing.
    //
    // The messenger is captured before the await rather than looked up after
    // it: by the time Undo is refused, this context may belong to a screen the
    // user has already left.
    onUndoFailed: (error) =>
        showMxMessageOn(messenger, _undoFailureText(l10n, error)),
  );
}

/// The sentence for a refused Undo (UC-21 E3).
///
/// A free function taking the localizations rather than a `BuildContext`
/// extension, because it runs *after* an await, when the context that started
/// the operation may be gone — the messenger was captured for the same reason.
String _undoFailureText(AppLocalizations l10n, Object error) => switch (error) {
  ConflictFailure(reason: TrashConflictReason.undoOriginUnavailable) =>
    l10n.trashConflictUndoOriginUnavailable,
  _ => l10n.trashUndoFailed,
};
