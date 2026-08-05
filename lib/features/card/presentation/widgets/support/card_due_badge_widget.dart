import 'package:flutter/widgets.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_due_badge_model.dart';

/// Presentation mapping for the due badge (D5): the sealed [CardDueBadge] the
/// domain computes, rendered as the compact copy the row shows.
///
/// Here, not in the tile, so the cases are named once and a screen-reader
/// wrapper can reuse the same short form. The domain owns *which* bucket; this
/// owns the words.
extension CardDueBadgePresentation on BuildContext {
  /// The badge copy, or **null when there is no badge to draw**.
  ///
  /// [CardNotScheduled] is the null case, and it is null rather than a word of
  /// its own because the row already answers it: a card with no due date is
  /// exactly a card that has never been reviewed, and the state label under the
  /// front word says `NEW`. A second mark saying the same thing in different
  /// words is the noise the badge is supposed to cut through — and the word it
  /// used to say there was `now`, which was not merely redundant but wrong.
  String? dueBadgeLabel(CardDueBadge badge) => switch (badge) {
    CardNotScheduled() => null,
    CardDueNow() => l10n.cardDueNow,
    CardDueInMinutes(:final minutes) => l10n.cardDueInMinutes(minutes),
    CardDueInHours(:final hours) => l10n.cardDueInHours(hours),
    CardDueInDays(:final days) => l10n.cardDueInDays(days),
  };
}
