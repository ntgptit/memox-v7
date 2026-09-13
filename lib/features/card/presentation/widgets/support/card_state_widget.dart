import 'package:flutter/widgets.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_status_badge.dart';
import '../../../domain/models/card_state_model.dart';

/// Presentation mapping for the four display states (D5) — the dot colour and the
/// label, in one place so a row and any later panel legend agree.
///
/// **The dot carries the colour, the label carries the word, and that is the
/// accessibility split.** Colour distinguishes the states for a fast vertical
/// scan; the label names them for anyone who cannot rely on colour. So the four
/// colours only have to clear the 3:1 UI-component bar (a dot is non-text), while
/// the label sits in `onSurfaceVariant`, which clears 4.5:1 as text.
///
/// **The handoff's lifecycle tokens** (D11, M100.91): `statusNew`,
/// `statusLearning`, `statusReviewing`, `statusMastered`, painted through
/// [MxStatusBadge]. It borrowed info → warning → primary → success until the
/// handoff named four of its own; the label inks below stay on the semantic
/// ladder, because a status token is a fill and never text (D23).
extension CardStatePresentation on BuildContext {
  /// The state's ink, for the closed text/icon API; [cardStateColor] stays for
  /// the dot fill beside it, and the two switches must agree family-for-family.
  AppInk cardStateInk(CardState state) => switch (state) {
    CardState.isNew => AppInk.info,
    CardState.beginning => AppInk.warning,
    CardState.reviewing => AppInk.accent,
    CardState.mastered => AppInk.success,
  };

  Color cardStateColor(CardState state) {
    final semantic = semanticColors;

    return switch (state) {
      CardState.isNew => semantic.statusNew,
      CardState.beginning => semantic.statusLearning,
      CardState.reviewing => semantic.statusReviewing,
      CardState.mastered => semantic.statusMastered,
    };
  }

  /// The badge tone for a state — the same four families as [cardStateColor].
  MxStatusTone cardStateTone(CardState state) => switch (state) {
    CardState.isNew => MxStatusTone.isNew,
    CardState.beginning => MxStatusTone.learning,
    CardState.reviewing => MxStatusTone.reviewing,
    CardState.mastered => MxStatusTone.mastered,
  };

  String cardStateLabel(CardState state) => switch (state) {
    CardState.isNew => l10n.cardStateNew,
    CardState.beginning => l10n.cardStateBeginning,
    CardState.reviewing => l10n.cardStateReviewing,
    CardState.mastered => l10n.cardStateMastered,
  };
}
