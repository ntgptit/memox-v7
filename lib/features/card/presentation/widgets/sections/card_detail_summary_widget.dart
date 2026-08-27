import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../deck/domain/models/scheduler_type_model.dart';
import '../../../domain/models/card_detail_model.dart';
import '../support/card_action_tone_widget.dart';
import '../support/card_tag_chip_widget.dart';

/// The card at a glance: both faces, what the scheduler makes of it, the marks
/// on it, and whichever optional fields carry a value (BR-240, M4.15 W2 band 1).
///
/// **A summary, not a poster.** The front used to be set in `cardPrompt` — the
/// 30sp rung the *review* card uses, where the term is the task and fills the
/// screen. Here it is one fact among several, so it takes `headlineSmall` and
/// the band gets its weight from being a surface rather than from type size.
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
/// The divider goes with them: it separates the faces from the extras, so with
/// no extras there is nothing to separate.
class CardDetailSummaryWidget extends StatelessWidget {
  const CardDetailSummaryWidget({required this.detail, super.key});

  final CardDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final card = detail.card;
    final optionalFields = _optionalFields(context);
    final marks = _marks(context);

    return SizedBox(
      width: double.infinity,
      child: MxCard(
        // Flat, like the progress panel and every event card below it (D20).
        // The hero leads by being first, by its type and by its size, not by
        // floating above the two surfaces that describe it — which is also what
        // keeps the ladder honest in dark, where `shadowsFor` paints nothing.
        elevation: AppElevation.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // **The badge is anchored to the term's row, and the meaning goes
            // under both.** A `Wrap` holding a `Column(front, back)` decided
            // where the badge went from the *back*'s width: a four-line meaning
            // took the whole run and dropped the badge onto its own, left
            // aligned, directly above the flag chip — where it read as a third
            // mark rather than as the corner of the hero. A `Row` puts it at
            // the trailing edge always; the term takes the remainder and wraps,
            // and the badge's own label wraps inside it, so neither shrinks a
            // font to fit.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(card.front, style: context.texts.headlineSmall),
                ),
                const SizedBox(width: AppSpacing.md),
                _SchedulerBadge(detail: detail),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              card.back,
              style: context.texts.bodyMedium!.inked(context, AppInk.quiet),
            ),
            if (marks.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: marks,
              ),
            ],
            if (optionalFields.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Divider(
                height: AppStroke.hairline,
                thickness: AppStroke.hairline,
                color: context.semanticColors.borderSubtle,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < optionalFields.length; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.md),
                _DetailField(
                  label: optionalFields[index].$1,
                  value: optionalFields[index].$2,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// The flag and the tags, in one run — both are marks somebody put on this
  /// card, and stacked as separate rows they read as two unrelated facts.
  ///
  /// Read-only, and structurally so: no `onTap`, no `InkWell`, no
  /// `Semantics(button:)`. The detail screen shows the flag and never toggles it
  /// (BR-92, BR-93, BR-239).
  List<Widget> _marks(BuildContext context) => <Widget>[
    if (detail.card.isFlagged)
      _FlagChip(label: context.l10n.cardDetailFlaggedLabel),
    for (final name in detail.tagNames) CardTagChipWidget(name: name),
  ];

  /// The optional fields that have something to show, in the order BR-95 lists
  /// them — one shape for three fields, so a fourth would be one line here
  /// rather than a fourth copy of a label-and-value block.
  List<(String, String)> _optionalFields(BuildContext context) {
    final l10n = context.l10n;
    final card = detail.card;

    return <(String, String)>[
      if (card.example != null) (l10n.cardDetailExampleLabel, card.example!),
      if (card.hint != null) (l10n.cardDetailHintLabel, card.hint!),
      if (card.pronunciation != null)
        (l10n.cardDetailPronunciationLabel, card.pronunciation!),
    ];
  }
}

/// Where the scheduler has this card, in the scheduler's own terms.
///
/// **`eight_box` says its position and `sm2` says its name**, because those are
/// the two different things the two algorithms know. SM-2 has no ladder to be
/// three-eighths of the way up, and inventing one for the sake of symmetry would
/// be inventing a metric (BR-243, AD-08). Its numbers live in the panel below.
///
/// The `/ 8` is read from the scheduler contract's own `kMaxBox`, so the badge
/// stops saying eight the day the algorithm stops having eight.
class _SchedulerBadge extends StatelessWidget {
  const _SchedulerBadge({required this.detail});

  final CardDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final state = detail.studyState;
    final box = state.currentBox;
    final isBoxed =
        state.schedulerType == SchedulerType.eightBox && box != null;

    // **The spoken form, on the badge as well as on the track.** `3 / 8` reaches
    // a screen reader as "3 slash 8" or as a silence, and the badge used to be
    // the only place on this screen saying the position — so before the panel
    // existed it was announced as `Box, 3`, and drawing it as two `Text`s made
    // that *worse* rather than better. Both places now speak the same sentence.
    return Semantics(
      container: true,
      label: isBoxed
          ? context.l10n.cardDetailBoxPositionSemantics(box, context.cardMaxBox)
          : context.cardSchedulerIdentity(state.schedulerType),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: semantic.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.bolt_rounded,
                size: AppIconSize.sm,
                color: semantic.primaryAccent,
              ),
              const SizedBox(width: AppSpacing.xs),
              // **No `Flexible` here, and that is deliberate.** This badge is a
              // non-flex child of the hero's `Row`, so it is measured against an
              // unbounded main axis — a `Flexible` inside it would constrain
              // nothing and only read as protection. What bounds it instead is
              // its vocabulary: `Box`, `SM-2`, `8 boxes` and the unknown-mode
              // label are all short, and the term beside it is `Expanded`, so
              // the term yields rather than the pill overflowing.
              Text(
                isBoxed
                    ? context.l10n.cardDetailBoxLabel
                    : context.cardSchedulerIdentity(state.schedulerType),
                style: context.texts.labelSmall!.inked(context, AppInk.quiet),
              ),
              if (isBoxed) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  // Two numbers and a stroke — punctuation, not copy, so the
                  // *drawn* form needs no ARB key and reads the same in every
                  // language. The spoken form is a key, on the `Semantics`
                  // above.
                  '$box / ${context.cardMaxBox}',
                  style: context.texts.labelSmall!.inked(
                    context,
                    AppInk.accent,
                    isTabular: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The user's flag, present only when set.
///
/// **A chip, and not a button.** The glyph takes `onDueContainer` rather than
/// `warning`: `warning` on this fill is 4.04:1 in light — above the 3:1 WCAG
/// asks of a graphic, below the 4.5:1 the strict screen audit applies, because a
/// glyph reaches the render tree as a text run and the auditor cannot tell it
/// from a word. The chip's own on-colour measures 6.38:1 / 6.57:1, and the warm
/// meaning is already carried by the fill.
class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: semantic.dueContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.flag,
            size: AppIconSize.sm,
            color: semantic.onDueContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          // `Flexible`, because a `Row` hands an unbounded main axis to a
          // non-flex child: without it a long label makes the pill wider than
          // the `Wrap` that holds it instead of wrapping inside it.
          Flexible(
            child: Text(
              label,
              style: context.texts.labelSmall!.inked(
                context,
                AppInk.onDueContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label over its value.
///
/// The label is `labelSmall` on the muted ink and the value is `bodyMedium` —
/// the same pair the progress panel's cells use, so the two halves of the screen
/// spend one rhythm rather than two. Not upper-cased: that is for the heading
/// above a section, and these sit inside one.
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
          style: context.texts.labelSmall!.inked(context, AppInk.quiet),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: context.texts.bodyMedium),
      ],
    );
  }
}
