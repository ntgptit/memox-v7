import 'package:flutter/material.dart';

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
class MxListTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          // Two lines then ellipsis rather than unbounded growth: at
          // textScaler 2.0 an unbounded subtitle pushes the trailing action off
          // a 320-wide screen, and the row silently loses its only control.
          : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
      leading: leading,
      trailing: trailing,
      onTap: isEnabled ? onTap : null,
      enabled: isEnabled,
      selected: isSelected,
    );
  }
}
