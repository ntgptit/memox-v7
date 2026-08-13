import 'package:flutter/widgets.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/failures/card_export_failure.dart';
import '../../../domain/models/card_export_scope_model.dart';
import '../../states/card_export_state.dart';
import 'card_failure_labels_widget.dart';

/// Every enum-to-copy switch the export sheet needs, in one place — the
/// export counterpart of `card_import_labels_widget.dart`.
///
/// **Exhaustive on `CardExportProblem`**, all seven values. A new reason must
/// fail to compile here rather than reach the user as the generic write-failure
/// line, which is the whole reason the reason is an enum. The failure's own
/// `message` is never rendered: it is an unlocalized diagnostic, and on this
/// path it is the one most tempted to name a file, a path or a card (BR-180,
/// BR-181).
extension CardExportLabels on BuildContext {
  /// The sentence under the error band's title (UC-11 E1…E6).
  String cardExportFailureLabel(Failure failure) {
    final problem = cardExportProblemOf(failure);
    if (problem == null) return cardWriteFailure(failure);

    return switch (problem) {
      CardExportProblem.emptyScope => l10n.cardExportErrorEmptyScope,
      CardExportProblem.staleSelection => l10n.cardExportErrorStaleSelection,
      CardExportProblem.deckMissing => l10n.cardExportErrorDeckMissing,
      CardExportProblem.readFailed => l10n.cardExportErrorReadFailed,
      CardExportProblem.encodeFailed => l10n.cardExportErrorEncodeFailed,
      CardExportProblem.shareUnavailable =>
        l10n.cardExportErrorShareUnavailable,
      CardExportProblem.sharePlatformError =>
        l10n.cardExportErrorSharePlatformError,
    };
  }

  /// The error band's title. Two of them, and the split is the same one that
  /// decides the actions: a scope that no longer exists offers `Close`, not a
  /// `Try again` that cannot succeed (M4.13 W3 states 5–7).
  String cardExportFailureTitle(Failure failure) =>
      isCardExportScopeProblem(cardExportProblemOf(failure))
      ? l10n.cardExportScopeChangedTitle
      : l10n.cardExportErrorTitle;

  /// The read-only scope summary (M4.13 W2 item 3). The number is the scope's
  /// card count, never the rows the list happens to be showing (BR-174).
  String cardExportScopeLabel(CardExportScope scope, int deckCardCount) =>
      switch (scope) {
        CardExportWholeDeckScope() => l10n.cardExportScopeAllLabel(
          deckCardCount,
        ),
        CardExportSelectionScope(:final cardIds) =>
          l10n.cardExportScopeSelectedLabel(cardIds.length),
      };
}

/// How many cards [scope] covers, given the deck's own total.
///
/// The primary action's `N` and the scope summary's `N` are the same number by
/// construction — two independent counts on one sheet is exactly the kind of
/// disagreement a user notices and cannot explain.
int cardExportScopeCount(CardExportScope scope, int deckCardCount) =>
    switch (scope) {
      CardExportWholeDeckScope() => deckCardCount,
      CardExportSelectionScope(:final cardIds) => cardIds.length,
    };
