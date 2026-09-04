import 'package:flutter/material.dart';
import '../../foundations/app_elevation.dart';

/// The top bar on every screen.
///
/// **`surface`/`onSurface`, which is what `_AppBarDefaultsM3` names** — and it
/// is the page colour, because since M100.32 `ColorScheme.surface` *is* the
/// page. The bar and the content it sits over therefore share one ground and
/// the chrome reads as one frame, which is the appearance this app has always
/// had; what changed is that it now comes from the role instead of from a
/// `background` colour handed in past the scheme.
///
/// That parameter was the last piece of loose paint in a component builder:
/// it existed only because the app read `surface` as the card, so there was no
/// role left for the page. There is now.
AppBarTheme buildAppBarTheme(ColorScheme scheme) => AppBarTheme(
  backgroundColor: scheme.surface,
  foregroundColor: scheme.onSurface,
  // **The leading glyph is `onSurface`, stated** (A20.1 P2-05).
  // `_AppBarDefaultsM3.iconTheme` is `onSurface` and `actionsIconTheme` is
  // `onSurfaceVariant`; this app sets neither, and `app_bar.dart:958-1031`
  // then hands the leading to `iconButtonTheme` — `onSurfaceVariant` — so the
  // back arrow sat one ink step quieter than the SDK draws it while the
  // actions were canonical. Stating the slot puts the leading back on its
  // role; the actions keep theirs through the icon-button theme.
  iconTheme: IconThemeData(color: scheme.onSurface),
  // No tint on scroll: during a study session the header must stay still, because
  // a colour shift behind the card reads as the card itself changing.
  scrolledUnderElevation: 0,
  elevation: AppElevation.none,
  centerTitle: false,
);
