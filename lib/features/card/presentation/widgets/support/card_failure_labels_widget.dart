import 'package:flutter/widgets.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_failure_labels_widget.dart';
import '../../../domain/failures/card_conflict_failure.dart';

/// A card write's failure, as copy the user can act on.
///
/// The shared extension owns every `Failure` subtype; this owns the half that
/// is Card's — the conflict reasons, which are an enum precisely so the screen
/// can say *which* rule refused rather than "something went wrong".
///
/// **Exhaustive on purpose.** No `_` branch: a new reason must fail to compile
/// here rather than silently arrive as the generic line.
extension CardFailureLabels on BuildContext {
  String cardWriteFailure(Failure failure) => mxWriteFailure(
    failure,
    onNotFound: (_) => l10n.writeErrorMessage,
    onConflict: (conflict) => switch (conflict.reason) {
      CardConflictReason.moveTargetIsSameDeck => l10n.cardConflictMoveSameDeck,
      CardConflictReason.moveTargetIsRoot => l10n.cardConflictMoveTargetIsRoot,
      CardConflictReason.moveTargetHoldsDecks =>
        l10n.cardConflictMoveTargetHoldsDecks,
      CardConflictReason.moveCrossRoot => l10n.cardConflictMoveCrossRoot,
      // The create-path reasons keep the generic line: they are unreachable
      // from a bulk action, and the screens that can reach them explain the
      // rule in place.
      _ => l10n.writeErrorMessage,
    },
  );
}
