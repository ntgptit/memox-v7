import 'package:flutter/widgets.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_due_badge_model.dart';

/// Presentation mapping for the due badge (D5): the sealed [CardDueBadge] the
/// domain computes, rendered as the compact copy the row shows.
///
/// Here, not in the tile, so the four cases are named once and a screen-reader
/// wrapper can reuse the same short form. The domain owns *which* bucket; this
/// owns the words.
extension CardDueBadgePresentation on BuildContext {
  String dueBadgeLabel(CardDueBadge badge) => switch (badge) {
    CardDueNow() => l10n.cardDueNow,
    CardDueInMinutes(:final minutes) => l10n.cardDueInMinutes(minutes),
    CardDueInHours(:final hours) => l10n.cardDueInHours(hours),
    CardDueInDays(:final days) => l10n.cardDueInDays(days),
  };
}
