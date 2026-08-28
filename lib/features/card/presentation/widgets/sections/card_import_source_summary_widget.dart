import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';

/// The chosen source, one compact card (M4.12 states 1–2): a file icon, the
/// name (or "Pasted text" — the content itself is private and never echoed,
/// BR-173), and a status line that moves with the phase — ready to preview,
/// parsing, N rows detected.
///
/// Dumb on purpose: the steps compose the strings and decide which actions
/// exist. On the Source step the card is tappable (replace) and carries a
/// remove X; on Preview it is context only, because removing the source out
/// from under a mounted preview would be a navigation, not an edit.
class CardImportSourceSummaryWidget extends StatelessWidget {
  const CardImportSourceSummaryWidget({
    required this.title,
    required this.subtitle,
    this.onReplace,
    this.onRemove,
    super.key,
  }) : isEmbedded = false;

  /// The same row without its own card, for a parent that *is* the surface —
  /// the Preview step's mapping panel opens with this. A card inside a card
  /// would stack two hairlines around one fact; context-only, so no actions.
  const CardImportSourceSummaryWidget.embedded({
    required this.title,
    required this.subtitle,
    super.key,
  }) : isEmbedded = true,
       onReplace = null,
       onRemove = null;

  /// True when a parent panel owns the surface and this widget is only the
  /// row: icon well, name, status.
  final bool isEmbedded;

  /// The filename, or the localized stand-in for pasted rows.
  final String title;

  /// Format · size · status, already composed and localized. Null when the
  /// caller has no honest status line (a pasted source whose parse failed);
  /// the row simply tightens rather than showing an empty line.
  final String? subtitle;

  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final row = Row(
      children: <Widget>[
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const MxIcon(Icons.description_outlined),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: context.texts.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: context.texts.bodySmall!.inked(context, AppInk.quiet),
                  maxLines: 2,
                ),
            ],
          ),
        ),
        if (onRemove != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          MxIconButton(
            icon: Icons.close,
            semanticLabel: context.l10n.cardImportRemoveFileLabel,
            onPressed: onRemove,
          ),
        ],
      ],
    );

    if (isEmbedded) return row;

    // Flat, like every surface in this wizard's column now (D20) — this was
    // one of the raised cards whose shadow competed with the work panel's.
    final card = MxCard.flat(
      onTap: onReplace,
      padding: MxCardPadding.compact,
      child: row,
    );

    if (onReplace == null) return card;

    // The tap replaces; the semantics say so, since a plain card gives the
    // gesture no name of its own.
    return Semantics(
      button: true,
      label: context.l10n.cardImportReplaceFileAction,
      child: card,
    );
  }
}
