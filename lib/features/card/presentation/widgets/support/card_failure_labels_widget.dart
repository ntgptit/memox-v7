import 'package:flutter/widgets.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/theme_context_extension.dart';
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

/// A failed card write, said once.
///
/// **It was written twice, identically.** The editor screen and the tag strip
/// each carried the same `Semantics(liveRegion:) + Text(mxWriteFailure(...))`
/// block, and a third caller would have got a third copy. Live, because the
/// message arrives after the user has already moved on from the button that
/// caused it — a failure nobody is looking at is a failure nobody is told
/// about.
class CardWriteFailureTextWidget extends StatelessWidget {
  const CardWriteFailureTextWidget({required this.failure, super.key});

  final Failure failure;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      context.cardWriteFailure(failure),
      style: context.texts.bodySmall?.copyWith(color: context.colors.error),
    ),
  );
}
