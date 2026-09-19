import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';
import 'mx_icon.dart';
import 'mx_icon_tile.dart';

/// A settings-screen row: a leading [MxIconTile], a label with an optional
/// sub line, and an optional trailing control — inline, wide, or a
/// navigation chevron.
///
/// **Kept apart from `MxListTile` on purpose** (SettingsRow component
/// handoff, "same silhouette, different contract"): a bigger label rung
/// (`16/600` vs `MxListTile`'s `body-lg`/`16/500`), its own `12 16` padding
/// and `48` floor rather than `ListTileThemeData`'s, and a leading tile fixed
/// to [MxIconTile] rather than an arbitrary `leading:` widget.
///
/// **This surface owns no colour of its own beyond what it reads directly**
/// (`onSurface`, `onSurfaceVariant`, the shared focus ring and row overlay) —
/// the leading tile's tint and glyph colour belong entirely to [MxIconTile].
///
/// **One trailing shape at a time.** [trailing] (inline) and [wideControl]
/// (its own line, full width) are mutually exclusive, and either one
/// suppresses the navigation chevron — the chevron draws only when the row
/// navigates and has no trailing control of its own.
///
/// **A caller-supplied [trailing]/[wideControl] stays reachable by Tab even
/// when the row itself does not navigate.** The row simply does not build a
/// tap target in that state — it never wraps the whole row in `ExcludeFocus`,
/// which is the exact defect a prior version of this widget shipped with: a
/// `Switch` passed as [trailing] must keep its own focus and its own tap,
/// regardless of whether the row around it is tappable.
class MxSettingsRow extends StatelessWidget {
  /// The lead column's width — wider than the [MxIconTile] it holds (`36`),
  /// so the icon centres with even space either side. Not on `AppSizing`'s
  /// ladder: `AppSizing.controlCompact` is also `40`, but it names a control
  /// *height* (M100.30's two-button-heights ladder); reusing it here for an
  /// unrelated layout column width would be the token-borrowed-for-its-number
  /// mistake `spacing_is_a_gap_test.dart` guards against on the spacing side.
  static const double _leadColumnWidth = 40;

  const MxSettingsRow({
    required this.label,
    this.sub,
    this.leadingIcon,
    this.leadingSemanticLabel,
    this.trailing,
    this.wideControl,
    this.onTap,
    this.isEnabled = true,
    super.key,
  }) : assert(
         trailing == null || wideControl == null,
         'a row has one trailing control at a time — inline or wide, not '
         'both',
       );

  /// Already-localized.
  final String label;
  final String? sub;

  /// `null` renders no lead column at all.
  final IconData? leadingIcon;
  final String? leadingSemanticLabel;

  /// An inline control beside the label — e.g. a `Switch`. Mutually
  /// exclusive with [wideControl]. Suppresses the chevron.
  final Widget? trailing;

  /// A control that drops to its own line below the label — e.g. a stepper.
  /// Mutually exclusive with [trailing]. Suppresses the chevron.
  final Widget? wideControl;

  /// `null` makes the row non-interactive — a static row, or one whose
  /// action has not loaded yet.
  final VoidCallback? onTap;

  /// `false` dims the whole row to `AppStateOpacity.disabled` (`0.38`) and
  /// drops its own tap target. It does not reach into [trailing]/
  /// [wideControl] — those are `COMPONENT_INPUT`, and enabling or disabling
  /// them is the caller's job.
  final bool isEnabled;

  /// Shaped like a control — it has one action and nothing else claiming the
  /// trailing slot — regardless of whether that action can fire right now.
  /// **Decides whether the row is exposed as a button at all**, so a
  /// disabled control still reads as a disabled button rather than as inert
  /// content indistinguishable from a genuinely static row (no [onTap]).
  bool get _isControl =>
      onTap != null && trailing == null && wideControl == null;

  /// Draws the chevron, is tappable, and takes focus — [_isControl] and
  /// actually enabled. **Decides only interactivity**, never whether the row
  /// is announced as a button; see [_isControl].
  bool get _isNavigable => isEnabled && _isControl;

  @override
  Widget build(BuildContext context) {
    final isControl = _isControl;
    final isNavigable = _isNavigable;
    final labelStyle = context.textStyles.settingsRowLabel.inked(
      context,
      AppInk.stated,
    );
    final subStyle = context.textStyles.settingsRowSub.inked(
      context,
      AppInk.quiet,
    );

    final sub = this.sub;
    final leadingIcon = this.leadingIcon;
    final trailing = this.trailing;
    final wideControl = this.wideControl;

    Widget? trailingSlot = trailing;
    if (trailingSlot == null && isNavigable) {
      trailingSlot = const MxIcon(
        Icons.chevron_right,
        size: MxIconSize.mdCompact,
      );
    }

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  SizedBox(
                    width: _leadColumnWidth,
                    child: Center(
                      child: MxIconTile(
                        icon: leadingIcon,
                        semanticLabel: leadingSemanticLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: labelStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sub != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          sub,
                          style: subStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingSlot != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.lg),
                  trailingSlot,
                ],
              ],
            ),
            if (wideControl != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: wideControl),
            ],
          ],
        ),
      ),
    );

    // **Not shaped like a control at all** (a static row, or one with a
    // `trailing`/`wideControl`): no button semantics, no tap target — just
    // the content, dimmed when disabled.
    if (!isControl) {
      if (isEnabled) return content;
      return Opacity(opacity: AppStateOpacity.disabled, child: content);
    }

    return _controlBody(context, content);
  }

  /// Builds the interactive core and its `Semantics(button: true, enabled:)`
  /// wrapper for a control-shaped row ([_isControl]), whether or not it can
  /// fire right now.
  ///
  /// **`Semantics` is the outermost widget returned here, `Opacity` is
  /// nested inside it — never the other way round.** `find.byType
  /// (MxSettingsRow)` resolves to the *first* `RenderObject` the widget
  /// builds; a plain layout object (`Opacity`, `Padding`, `Row`, …) carries
  /// no semantics of its own and is invisible to that lookup, so putting
  /// `Opacity` *outside* `Semantics` — as an earlier version of this method
  /// did for the enabled path — makes the lookup climb straight past the
  /// button node and out to the app's root. Semantics first, dimming inside
  /// it, and the row's own semantics are reachable regardless of
  /// [isEnabled].
  ///
  /// **No `ExcludeFocus`.** Disabling only nulls `InkWell.onTap`; `InkWell`
  /// already withdraws its own focus and hover/press affordances the moment
  /// every one of its callbacks is null, and nothing here has to reach past
  /// this control's own tap target to do it — a caller-supplied
  /// [trailing]/[wideControl] never appears alongside [_isControl] in the
  /// first place, so there is nothing else in this branch to blind.
  Widget _controlBody(BuildContext context, Widget content) {
    final overlay = AppInteractionStates.rowOverlay(context.colors);
    final core = MxFocusRing(
      // Square, like the row: the ring traces the shape the ink takes.
      borderRadius: BorderRadius.zero,
      child: Material(
        // Its own transparent `Material`, so the row can paint ink on any
        // surface, the same move `MxListRow`/`MxListTile` make.
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          hoverColor: overlay.resolve(const <WidgetState>{WidgetState.hovered}),
          focusColor: overlay.resolve(const <WidgetState>{WidgetState.focused}),
          splashColor: overlay.resolve(const <WidgetState>{
            WidgetState.pressed,
          }),
          child: content,
        ),
      ),
    );

    final dimmed = isEnabled
        ? core
        : Opacity(opacity: AppStateOpacity.disabled, child: core);

    return Semantics(button: true, enabled: isEnabled, child: dimmed);
  }
}
