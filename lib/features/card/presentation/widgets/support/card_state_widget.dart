import 'package:flutter/widgets.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
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
/// **Existing semantic tokens, not four new ones.** The states map onto the
/// progress ladder the semantic palette already carries — info → warning →
/// primary accent → success — so nothing new has to be minted in either kit and
/// the two stay in sync by having nothing to diverge on.
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
      CardState.isNew => semantic.info,
      CardState.beginning => semantic.warning,
      CardState.reviewing => colors.primary,
      CardState.mastered => semantic.success,
    };
  }

  String cardStateLabel(CardState state) => switch (state) {
    CardState.isNew => l10n.cardStateNew,
    CardState.beginning => l10n.cardStateBeginning,
    CardState.reviewing => l10n.cardStateReviewing,
    CardState.mastered => l10n.cardStateMastered,
  };
}
