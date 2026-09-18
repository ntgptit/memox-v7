import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';
import 'mx_icon.dart';
import 'mx_icon_tile.dart';

/// The 2dp between title and subtitle — finer than the 4dp spacing scale.
const double _subtitleGap = 2;

/// The content row behind decks, search results, tags and cards.
///
/// **Deliberately not `MxListTile`.** `MxListTile`
/// (`lib/shared/widgets/mx_list_tile.dart`) is the ordinary navigation,
/// settings, control or choice row — two-line title, `ListTileThemeData`
/// geometry, tri-state selection. `MxListRow` is a piece of *content*: title
/// and sub are both exactly one line so every row in a list is the same
/// height, and it carries no selection concept at all.
///
/// **A surface, not a control.** This widget owns its own geometry, spacing,
/// content slots and long-content behaviour — never a touch target of its
/// own. [onTap] is the one exception the contract itself asks for: the row
/// reads `op-press` directly (spec's Theme consumption table), so when a
/// caller passes it the row paints the same pressed/hover/focus overlay
/// every other row in the app uses
/// ([AppInteractionStates.rowOverlay]) and exposes itself as a button. A
/// `null` [onTap] renders plain, inert content — no ripple, no focus ring,
/// no button semantics.
class MxListRow extends StatelessWidget {
  const MxListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingIcon,
    this.seed,
    this.trailing,
    this.trailingIcon,
    this.onTap,
    this.showDivider = true,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. One line, ellipsised — a long title is cut, never
  /// wrapped, so every row in a list stays the same height.
  final String title;

  /// Already-localized. One line, ellipsised, 2dp below the title.
  final String? subtitle;

  /// Replaces the default leading tile entirely — "any node may replace
  /// it" is the contract's own wording. Takes priority over [leadingIcon].
  final Widget? leading;

  /// Builds the default leading tile as `MxIconTile(icon: leadingIcon, seed:
  /// seed)`. Ignored when [leading] is supplied. `null` (with no [leading]
  /// either) renders no leading slot.
  final IconData? leadingIcon;

  /// Forwarded unchanged to `MxIconTile.seed` — this row never paints it
  /// itself. Ignored unless [leadingIcon] is building the default tile.
  final Color? seed;

  /// Replaces the default trailing glyph entirely — a spinner for the busy
  /// state, or any other presentational node. Takes priority over
  /// [trailingIcon]. Keeps its own width; only the text column gives up
  /// space to a long title.
  final Widget? trailing;

  /// Builds the default trailing glyph as `MxIcon(trailingIcon, ink:
  /// AppInk.quiet, size: MxIconSize.mdCompact)` — the row resolves
  /// `onSurfaceVariant` itself here, the one DIRECT theme role this row
  /// owns beyond title/sub/divider. Ignored when [trailing] is supplied.
  /// `null` (with no [trailing] either) renders no trailing slot.
  final IconData? trailingIcon;

  /// `null` renders the row as plain content. Non-null exposes the row as a
  /// button with the app's standard row press/hover/focus overlay.
  final VoidCallback? onTap;

  /// `false` omits the bottom hairline — pass it for the last row in a
  /// list. The row does not know its own position in a list, so the caller
  /// decides.
  final bool showDivider;

  /// `null` lets the title (and subtitle, if present) be read as separate
  /// nodes. Set it when the tappable row's target needs one merged
  /// announcement instead. Ignored when [onTap] is null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = context.colors;
    final String? subtitleText = subtitle;
    final Widget? leadingWidget =
        leading ??
        (leadingIcon != null
            ? MxIconTile(icon: leadingIcon!, seed: seed)
            : null);
    final Widget? trailingWidget =
        trailing ??
        (trailingIcon != null
            ? MxIcon(trailingIcon!, size: MxIconSize.mdCompact)
            : null);

    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            if (leadingWidget != null) ...<Widget>[
              leadingWidget,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.listRowTitle.inked(
                      context,
                      AppInk.stated,
                    ),
                  ),
                  if (subtitleText != null) ...<Widget>[
                    const SizedBox(height: _subtitleGap),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall!.inked(
                        context,
                        AppInk.quiet,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              trailingWidget,
            ],
          ],
        ),
      ),
    );

    final Widget bordered = showDivider
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: AppDecorations.hairlineEdge(scheme)),
            ),
            child: row,
          )
        : row;

    final VoidCallback? tap = onTap;
    if (tap == null) return bordered;

    // Press paints the InkWell splash plus `ThemeData.highlightColor` — the
    // same accepted fall-through as `MxListTile` (mx_list_tile.dart:152-155),
    // not a second overlay of this row's own.

    final WidgetStateProperty<Color?> overlay = AppInteractionStates.rowOverlay(
      scheme,
    );
    final Widget semanticContent = semanticLabel != null
        ? ExcludeSemantics(child: bordered)
        : bordered;

    return MxFocusRing(
      // Square, like the row — the same call `MxListTile` makes for the
      // same reason: the ring traces the shape the ink takes.
      borderRadius: BorderRadius.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: tap,
          hoverColor: overlay.resolve(const <WidgetState>{WidgetState.hovered}),
          focusColor: overlay.resolve(const <WidgetState>{WidgetState.focused}),
          splashColor: overlay.resolve(const <WidgetState>{
            WidgetState.pressed,
          }),
          child: Semantics(
            button: true,
            label: semanticLabel,
            child: semanticContent,
          ),
        ),
      ),
    );
  }
}
