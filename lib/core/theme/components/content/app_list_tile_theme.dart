import 'package:flutter/material.dart';

import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_sizing.dart';
import '../../foundations/app_spacing.dart';

/// Every `ListTile` in the app, and `MxListTile` with it.
///
/// One of the four component themes added at M4.8. The selected pair is the
/// one decision here that needed a measurement — see `selectedColor` below.
///
/// **No `textColor`** (M100.36, #431 P1-1). `ListTile` 3.44.8 takes a non-null
/// `textColor` as `effectiveColor` and copies it onto the title, the subtitle
/// *and* the leading/trailing text style alike (`list_tile.dart:920`, `:934`,
/// `:899`), so `textColor: onSurface` painted every second line in the app —
/// `MxListTile`, `RadioListTile`, `CheckboxListTile`, `SwitchListTile` — in
/// the primary ink, and the row's hierarchy was carried by 16-vs-14 alone.
/// The three text styles below name their own M3 roles instead, which is what
/// `_LisTileDefaultsM3` does, and `m3_role_binding_guard_test.dart` reads
/// them at source level.
ListTileThemeData buildListTileTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => ListTileThemeData(
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xs,
  ),
  minVerticalPadding: AppSpacing.sm,
  // **The reading row is 56, stated** (M100.36 4J, #431 P2-1). It was
  // Flutter's `_defaultTileHeight` all along — 56 / 72 / 88 for one, two and
  // three lines — and nothing in the design system owned it. 48 is the touch
  // *floor* (`AppSizing.touchTarget`), not a comfortable reading row: the kit
  // says 48 for a desktop tile and the app renders 56 + 4 + 4 for a phone.
  // Two-line rows grow past this on their own; the number is a minimum, so
  // no text is ever clipped to hold it.
  minTileHeight: AppSizing.rowMinHeight,
  iconColor: scheme.onSurfaceVariant,
  titleTextStyle: texts.bodyLarge!.copyWith(color: scheme.onSurface),
  subtitleTextStyle: texts.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
  // A trailing `Text` fell to `_LisTileDefaultsM3.leadingAndTrailingTextStyle`
  // — `labelSmall`, 11px — below anything this app uses for readable text
  // (#431 P2-8). The secondary rung, in the secondary ink.
  leadingAndTrailingTextStyle: texts.bodyMedium!.copyWith(
    color: scheme.onSurfaceVariant,
  ),
  // **`onPrimaryContainer`, the selected fill's own ink** (M100.87). A picked
  // row lands on `surfaceSelected`, which is the handoff's
  // `primaryContainer`; the brand as text reads 4.32:1 there in light, and
  // the container's own ink reads 10.37 (8.81 in dark). It is the pair the
  // kit gives a selected chip, so a picked row and a picked chip say
  // "selected" the same way.
  selectedColor: scheme.onPrimaryContainer,
  // **`surfaceSelected` — the one app-owned "picked" surface** (M100.36 4I,
  // #431 P1-4). It was `surfaceMuted`, a neutral grey, while `MxCard`'s tint
  // for the same meaning was `surfaceSelected`, an indigo tint; two fills for
  // one idea, argued in two files that never cited each other. `MxCard`
  // keeps its own; this one now shares it. The label ink is measured on it in
  // `component_depth_and_state_test.dart`.
  selectedTileColor: semantic.surfaceSelected,
  // **No `shape`: the row is the rectangle M3 draws it as** (M100.37, #431
  // P2-11). It carried `AppRadius.md` (12), and every row in the app sits
  // inside something that already owns the corner — an `MxCard` clipping at
  // 16, a sheet clipping at its top — so the 12 was only ever visible as a
  // mismatch: a picked row's fill and its ripple curved 12 inside a 16
  // corner, and a middle row's ink rounded off at the card's straight edge.
  // A rectangle is concentric with any container by construction; the
  // container supplies the only curve.
);
