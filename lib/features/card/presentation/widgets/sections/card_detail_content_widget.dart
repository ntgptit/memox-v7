import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/entities/card_entity.dart';

/// The card's own words: both faces in full, then whichever of the three
/// optional fields carry a value (BR-240, M4.15 W2 band 1).
///
/// **A card, and that reverses D27** (owner decision, 2026-08-26). The band used
/// to sit straight on the page ground, on the reasoning that a reading surface
/// is one story rather than three objects. What that produced in practice was a
/// screen where the term being learned, its meaning, its schedule and its
/// history were all the same ink on the same white — nothing said which of them
/// the screen is *for*. The panel is now the one surface the screen is built
/// around: the page ground behind it, `surface` inside it, and
/// `AppSemanticColors.borderAccent` on its edge, which is the only accent-tinted
/// hairline in the app and is spent here rather than on any of the quieter
/// blocks below.
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
/// The divider goes with them: with no optional field to introduce, a rule under
/// the meaning would separate the pair from nothing.
class CardDetailContentWidget extends StatelessWidget {
  const CardDetailContentWidget({required this.card, super.key});

  final CardEntity card;

  @override
  Widget build(BuildContext context) {
    final fields = _optionalFields(context);

    return MxCard(
      // The one accent edge on the screen. `MxCard` takes a semantic role here
      // rather than a colour, so this is the same hairline every other accented
      // surface draws — not a second card style invented for one screen.
      borderColor: context.semanticColors.borderAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            // `cardPrompt`, the named style the review card's front is set in.
            // This is the same text answering the same question, and it used to
            // be `headlineSmall` — one rung above the meaning under it, on a
            // screen where it is the whole subject.
            card.front,
            style: context.textStyles.cardPrompt,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            card.back,
            style: context.texts.titleMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          if (fields.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              // Stated rather than inherited from `dividerTheme`, which already
              // resolves to the same token: the rule is what separates the pair
              // the card is about from the notes around it, so the call site
              // says which line it means.
              child: Divider(color: context.semanticColors.borderSubtle),
            ),
            for (var index = 0; index < fields.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              _DetailField(label: fields[index].$1, value: fields[index].$2),
            ],
          ],
        ],
      ),
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

/// A label over its value.
///
/// **`sectionLabel`, uppercase, the same style every group heading in the app
/// wears.** `labelSmall` set the three labels one rung under the values they
/// introduce and in the same case, so the panel read as six interchangeable
/// lines; the tracked capitals are what make a label legible *as* a label
/// without competing with the text under it for size.
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
          label.toUpperCase(),
          style: context.textStyles.sectionLabel.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // `bodyLarge`: these are sentences the reader is meant to read, not
        // metadata to scan past, and they sit inside the panel the screen is
        // built around.
        Text(value, style: context.texts.bodyLarge),
      ],
    );
  }
}
