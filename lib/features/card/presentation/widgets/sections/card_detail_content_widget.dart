import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/entities/card_entity.dart';

/// The card's own words: both faces in full, then whichever of the three
/// optional fields carry a value (BR-240, M4.15 W2 band 1).
///
/// **Nothing here truncates.** The list row is allowed its ellipsis because it
/// answers "which card"; this band answers "what does it say", and a meaning cut
/// off at the second line is the one thing the screen exists to prevent. So
/// there is no `maxLines` and no `TextOverflow` — the text wraps and the page
/// scrolls.
///
/// **An absent optional field renders nothing at all** — not a label with an
/// empty value, and not a dash. `null` means never filled (BR-95), and a row
/// standing there empty invites the reader to wonder whether it failed to load.
class CardDetailContentWidget extends StatelessWidget {
  const CardDetailContentWidget({required this.card, super.key});

  final CardEntity card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          // headlineSmall: the term being learned is the largest thing on the
          // screen, a clear step above the meaning under it and above every
          // label in the bands below.
          card.front,
          style: context.texts.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          card.back,
          style: context.texts.titleMedium?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        for (final field in _optionalFields(context))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: _DetailField(label: field.$1, value: field.$2),
          ),
      ],
    );
  }

  /// The optional fields that have something to show, in the order BR-95 lists
  /// them — one shape for three fields, so a fourth would be one line here
  /// rather than a fourth copy of a label-and-value block.
  List<(String, String)> _optionalFields(BuildContext context) {
    final l10n = context.l10n;

    return <(String, String)>[
      if (card.example != null) (l10n.cardDetailExampleLabel, card.example!),
      if (card.hint != null) (l10n.cardDetailHintLabel, card.hint!),
      if (card.pronunciation != null)
        (l10n.cardDetailPronunciationLabel, card.pronunciation!),
    ];
  }
}

/// A label over its value, which is the shape both this band and the state band
/// use so their left edges line up (M4.15 G1, G2).
class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: context.texts.bodyMedium),
      ],
    );
  }
}
