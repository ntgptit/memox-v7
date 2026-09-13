import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_elevation.dart';
import '../../core/theme/foundations/app_radius.dart';

/// The screen-level create/primary action: the handoff's extended FAB — glyph
/// plus label, 52 tall, radius 16, `shadow-fab` (M100.90).
///
/// **Exists so no feature builds a `FloatingActionButton` again** — the guard's
/// `no_raw_widget` rule bans the raw widget in `lib/features/`, and this is the
/// door it points at. Everything visual comes from
/// `FloatingActionButtonThemeData` and this widget's one shadow: it takes no
/// `Color`, no shape and no elevation, for the same reason `MxActionButton`
/// takes none.
///
/// **[label] is visible now, so it is also the accessible name** — no tooltip.
/// The circular FAB this replaced was an icon with no adjacent text and needed
/// the label as its tooltip; an extended one says the word.
///
/// One screen, one FAB, one verb. A screen that wants two floating actions is
/// asking a different design question, and it should be asked in review rather
/// than answered by a second parameter here.
class MxFab extends StatelessWidget {
  const MxFab({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;

  /// Already-localized. Painted beside the glyph, and the button's name.
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: shadowsFor(AppElevation.overlay, context.colors),
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
