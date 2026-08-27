import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/card_transfer_format_model.dart';

/// One format option as the sheet renders it: the value, its one-line hint,
/// and whether it wears the Recommended badge.
///
/// **A list of copy, not a dispatch table.** The two `switch`es over
/// `CardTransferFormat` in this app both pick a codec and both live in `data/`
/// (AD-20); this one picks a sentence, which no resolver can supply and no
/// widget can avoid. `card_export_sheet_test.dart` asserts the list covers
/// `CardTransferFormat.values`, so a fourth format cannot quietly go
/// unrenderable.
typedef CardExportFormatOption = ({
  CardTransferFormat format,
  String subtitle,
  bool isRecommended,
});

/// The three options, in the order M4.13 W2 declares them.
List<CardExportFormatOption> cardExportFormatOptions(BuildContext context) {
  final l10n = context.l10n;

  return <CardExportFormatOption>[
    (
      format: CardTransferFormat.csv,
      subtitle: l10n.cardExportCsvSubtitle,
      // The only recommendation, and it is a label rather than a removed
      // choice: E3 answers "which one?" without taking the other two away.
      isRecommended: true,
    ),
    (
      format: CardTransferFormat.tsv,
      subtitle: l10n.cardExportTsvSubtitle,
      isRecommended: false,
    ),
    (
      format: CardTransferFormat.xlsx,
      subtitle: l10n.cardExportXlsxSubtitle,
      isRecommended: false,
    ),
  ];
}

/// The format band of the export sheet (M4.13 W2 item 5, W5).
///
/// **The options fill the content column or they stack — never anything in
/// between.** This is the defect Card Import shipped and M99.19a caught: a
/// `Wrap`, or a `Row` without `Expanded`, sizes children to their *intrinsic*
/// width, so the band reads as indented while every measurement taken on the
/// container it sits in stays perfect, because the container is full-width and
/// only the cards are not. Here each option is an `Expanded` inside an
/// `IntrinsicHeight` when they share a row, and the fallback to one column is
/// a measured `LayoutBuilder` threshold under the live text scaler — not a
/// device guess.
///
/// On a phone the threshold never clears, so the wireframe's vertical stack is
/// what ships; the row exists for a sheet wide enough to hold it, which is
/// what W5's "if some build lays them in a row" is about.
class CardExportFormatOptionsWidget extends StatelessWidget {
  const CardExportFormatOptionsWidget({
    required this.selected,
    required this.onSelected,
    this.isEnabled = true,
    super.key,
  });

  final CardTransferFormat selected;
  final ValueChanged<CardTransferFormat> onSelected;

  /// False once the scope itself is gone (M4.13 W3 state 7).
  ///
  /// The sheet's only remaining action is `Close`, so a format the user can
  /// still change is a control that cannot affect anything — the screen would
  /// be offering a choice it has already stopped being able to act on. The
  /// options stay *visible*, because they are also the record of what was
  /// asked for; they simply stop taking taps.
  final bool isEnabled;

  /// The narrowest an option stays readable at 1.0× type: the radio glyph, a
  /// four-letter title and the `Recommended` badge on one line, plus a
  /// two-line subtitle under them.
  ///
  /// **Measured against the layout that ships**, which the first version of
  /// this comment was not: it justified 148 by a badge beside the title while
  /// the badge sat on its own row, and by a two-line subtitle while the
  /// subtitle had no `maxLines` at all. Both are now true — the title line is
  /// a `Wrap` and the subtitle clamps — so the number is checkable again.
  static const double _minOptionWidth = 148;

  /// How many lines the subtitle may take when the three share a row.
  ///
  /// **Clamped there and deliberately not when stacked.** In a row the option
  /// is a third of the column, so an unbounded hint drags all three cards down
  /// with it through `IntrinsicHeight`, and two lines is the shape
  /// [_minOptionWidth] is measured against. Stacked, the option has the whole
  /// column and clamping would cost meaning exactly where it is dearest: at
  /// 320dp × 2.0 a card fits about eleven characters a line, so two lines
  /// would ellipsize `Opens in any spreadsheet or text editor.` down to
  /// `Opens in any spreads…` for the readers who chose the larger type.
  static const int _rowSubtitleMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final options = cardExportFormatOptions(context);

    List<Widget> cardsWith({int? subtitleMaxLines}) => <Widget>[
      for (final option in options)
        _FormatOption(
          option: option,
          isSelected: option.format == selected,
          subtitleMaxLines: subtitleMaxLines,
          onTap: isEnabled ? () => onSelected(option.format) : null,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final gaps = AppSpacing.sm * (options.length - 1);
        final fitsInOneRow =
            constraints.maxWidth >=
            _minOptionWidth * scale * options.length + gaps;
        if (!fitsInOneRow) {
          final cards = cardsWith();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final (index, card) in cards.indexed) ...<Widget>[
                if (index > 0) const SizedBox(height: AppSpacing.sm),
                card,
              ],
            ],
          );
        }

        final cards = cardsWith(subtitleMaxLines: _rowSubtitleMaxLines);

        // `IntrinsicHeight` gives `stretch` something to stretch to, so the
        // three stay equal when one subtitle wraps and the others do not.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final (index, card) in cards.indexed) ...<Widget>[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: card),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One format option. Selection is a border, a radio glyph that changes *shape*
/// and `selected` semantics — never colour alone (M4.13 W6).
class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.option,
    required this.isSelected,
    required this.subtitleMaxLines,
    required this.onTap,
  });

  final CardExportFormatOption option;
  final bool isSelected;

  /// Null lets the hint take as many lines as it needs — see
  /// [CardExportFormatOptionsWidget._rowSubtitleMaxLines].
  final int? subtitleMaxLines;

  /// Null once the scope is gone, which greys nothing but stops the tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Merged into one node on purpose: without it a screen reader stops four
    // times on one option — the card, the title, the badge and the hint — and
    // the `selected` flag sits on a node with no words on it. One stop reads
    // "CSV, Recommended, opens in…, selected, button", which is the whole
    // option in one announcement.
    return MergeSemantics(
      child: Semantics(
        // `selected` and `button` come from [MxCard.isSelected] and its ink
        // layer; MergeSemantics folds them into this same single stop. What
        // the card cannot know is that these options exclude each other.
        inMutuallyExclusiveGroup: true,
        child: MxCard.flat(
          onTap: onTap,
          // **No `color`, unlike the card tile, and the badge is the reason.**
          // `card_tile_widget.dart` says "this one is picked" with
          // `secondaryContainer` + `secondary`, and that fill was tried here
          // first — it reads well, and then it swallows the one thing this
          // option has that the others do not: `_RecommendedBadge` is a
          // `secondaryContainer` pill, so on a `secondaryContainer` card it
          // stops being a pill at all. Making the badge depend on selection
          // fixes nothing, because a deselected CSV card is `surface` and any
          // second colour is then wrong on one of the two grounds. The border
          // carries the state on its own.
          //
          // **`secondary` selected, `borderControl` at rest — and neither is the
          // state slot being borrowed.** `MxCard` reserves `borderColor` for a
          // card whose meaning has changed and gives `borderSubtle` to "every
          // card that is only a card". This is not only a card: it is a radio
          // row whose fill *is* the sheet's, i.e. **1.00:1**, so the edge is the
          // whole component. That is the case `AppSemanticColors.borderControl`
          // was measured and written for — see its doc, and
          // `guess_option_item_widget.dart`, which reached the same conclusion
          // for the same reason.
          //
          // Selected was `primary`, which measures **2.90:1** on `surface` in
          // dark — under WCAG 1.4.11's 3:1 — and only **1.42:1** against the
          // hairline of the options beside it, so in dark the border stopped
          // saying anything while looking as though it did. `secondary` is
          // 8.77:1 there and 7.33:1 in light, and it is the token the glyph and
          // `card_tile_widget.dart` already use for "selected", so the sheet no
          // longer holds a second opinion about which accent means picked.
          // Selected comes from [MxCard.isSelected] (the same measured
          // `secondary` this site moved to first); the resting border stays
          // `borderControl`, because these options are controls, not panels.
          isSelected: isSelected,
          borderColor: context.semanticColors.borderControl,
          // Flat, because this card sits *inside* the sheet's own surface.
          // `MxCard`'s doc calls a shadow stacked on a shadow a rendering fault,
          // and every card the app nests in another surface — the card tile, the
          // deck tile, the progress panel, `fill`'s answer area — passes this.
          padding: const EdgeInsets.all(AppSpacing.md),
          // No width of its own: the band above decides whether this is a
          // third of a row or the whole column, and a minWidth here is
          // precisely what makes a row of cards size to its text instead of
          // to the column.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // **A `Wrap`, so the badge sits beside the title until it cannot.**
              // Beside is what M4.13 W2 draws and what keeps the three options
              // the same height; below is what the badge needs at 320dp × 2.0,
              // where glyph + `CSV` + `Recommended` wants ~247dp of a 264dp
              // card and a `Row` would ellipsize one of the two words that
              // carry the recommendation. `Wrap` picks per layout instead of
              // committing to the wrong one of the two everywhere.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  _TitleWithGlyph(option: option, isSelected: isSelected),
                  if (option.isRecommended) const _RecommendedBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                option.subtitle,
                maxLines: subtitleMaxLines,
                overflow: subtitleMaxLines == null
                    ? null
                    : TextOverflow.ellipsis,
                style: context.texts.bodySmall!.inked(context, AppInk.quiet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The radio glyph and the format's name, as one inseparable run.
///
/// Its own widget because it is one `Wrap` child: the glyph must never wrap
/// away from the word it marks, and only a widget can say that.
class _TitleWithGlyph extends StatelessWidget {
  const _TitleWithGlyph({required this.option, required this.isSelected});

  final CardExportFormatOption option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxIcon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          size: MxIconSize.mdCompact,
          // The same selected-mark token the card tile's check uses: dark
          // primary fails contrast as a glyph on dark surfaces.
          ink: isSelected ? AppInk.secondary : AppInk.quiet,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            // From the format's own member, so the three names are not spelled
            // a second time here and cannot drift from the extension the file
            // is written with (BR-180).
            option.format.fileExtension.toUpperCase(),
            style: context.texts.titleSmall,
          ),
        ),
      ],
    );
  }
}

/// `Recommended`, as words a screen reader can read (M4.13 W6).
class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          context.l10n.cardExportRecommendedBadge,
          style: context.texts.labelSmall!.inked(
            context,
            AppInk.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
