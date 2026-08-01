import 'package:flutter/material.dart';

import '../../core/theme/app_interaction_states.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/theme_context_extension.dart';

/// A row in a list.
///
/// Deliberately generic. It takes a `String` title and a `Widget?` leading, not
/// a deck or a card: the moment a shared tile knows an entity, every widget test
/// in the project pulls the domain in behind it, and the tile stops being usable
/// by the next feature that has a different entity and the same layout.
/// `DeckTile` and `CardTile` are built **on** this, in their own features
/// (M4.10, M4.11).
///
/// Padding, minimum height and the selected colour come from `ListTileThemeData`
/// so a row keeps the same shape wherever it is used.
///
/// **The interaction states do not, and that is a `ListTile` limitation rather
/// than a choice.** `ListTileThemeData` has no slot for hover, focus or splash,
/// so a bare `ListTile` takes `ThemeData.hoverColor` and friends — hardcoded
/// washes with no seed in them. They are resolved here from
/// `AppInteractionStates.rowOverlay`, which is the one definition every row in
/// the app shares.
///
/// **Focus draws a ring, not just a tint.** The row's focus wash measures around
/// 1.15:1 against the surface behind it where WCAG 1.4.11 asks 3:1 of a focus
/// indicator, so on its own it marks the focused row for people who can already
/// see where they are. The ring is painted in *front* of the tile — a background
/// decoration would be covered by `selectedTileColor` on a selected row, which is
/// exactly the row most likely to be focused — and a foreground `DecoratedBox`
/// adds no layout, so nothing moves when focus arrives.
class MxListTile extends StatefulWidget {
  const MxListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.isEnabled = true,
    this.isSelected = false,
    super.key,
  });

  /// Already-localized.
  final String title;
  final String? subtitle;

  final Widget? leading;
  final Widget? trailing;

  /// `null` makes the row non-interactive without greying it out — a heading
  /// row, or a row whose action has not loaded yet.
  final VoidCallback? onTap;

  /// `false` greys the row and removes it from the focus order. Distinct from a
  /// null [onTap]: one says "not now", the other says "never".
  final bool isEnabled;

  final bool isSelected;

  @override
  State<MxListTile> createState() => _MxListTileState();
}

class _MxListTileState extends State<MxListTile> {
  /// Owned here rather than left to `ListTile` because the ring is drawn by this
  /// widget and the focus it reacts to belongs to the tile's own ink.
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChanged);
  bool _isFocused = false;

  void _onFocusChanged() {
    if (_focusNode.hasFocus == _isFocused) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlay = AppInteractionStates.rowOverlay(context.colors);
    final subtitle = widget.subtitle;

    return DecoratedBox(
      // Always in the tree, carrying a border only while focused. Adding and
      // removing the wrapper instead would move the `ListTile` to a new element
      // on the frame focus arrives, which throws away the ink's own state
      // mid-interaction.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: _isFocused
            ? Border.fromBorderSide(
                AppInteractionStates.focusRing(context.semanticColors),
              )
            : null,
      ),
      child: ListTile(
        title: Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? null
            // Two lines then ellipsis rather than unbounded growth: at
            // textScaler 2.0 an unbounded subtitle pushes the trailing action
            // off a 320-wide screen, and the row silently loses its only
            // control.
            : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        leading: widget.leading,
        trailing: widget.trailing,
        onTap: widget.isEnabled ? widget.onTap : null,
        enabled: widget.isEnabled,
        selected: widget.isSelected,
        focusNode: _focusNode,
        // Resolved from the one row contract rather than passed three loose
        // colours. `ListTile` has no `overlayColor`, so this is where the
        // property is unpacked — the values still have a single definition.
        hoverColor: overlay.resolve(const <WidgetState>{WidgetState.hovered}),
        focusColor: overlay.resolve(const <WidgetState>{WidgetState.focused}),
        splashColor: overlay.resolve(const <WidgetState>{WidgetState.pressed}),
      ),
    );
  }
}
