import 'package:flutter/material.dart';

/// Spinners — `MxLoadingState`, and a button mid-submit.
///
/// **`primary`, which is Material's own answer — and the history of how it
/// stopped being one is why this paragraph is long.** Declaring the slot found
/// that dark `primary` scored **2.81:1** against the surface it spins on, under
/// the 3.0 a graphic needs, because `primaryDark` was then a fill tone held down
/// so a filled button could not become the brightest thing on a navy page. The
/// answer taken at the time was a separate `focusRing` token; the answer taken
/// at M100.18 was to invert the tone, and the role now reads **10.01:1** on the
/// dark card. `focusRing` was retired with the reason for it.
ProgressIndicatorThemeData buildProgressIndicatorTheme(ColorScheme scheme) =>
    ProgressIndicatorThemeData(
      color: scheme.primary,
      // Explicitly transparent rather than left to default. Material draws a
      // faint track behind a circular indicator in newer versions; on a card
      // that reads as a second ring nobody asked for.
      circularTrackColor: Colors.transparent,
      linearTrackColor: scheme.secondaryContainer,
    );
