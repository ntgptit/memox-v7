import 'package:flutter/material.dart';

/// Readers that return what a widget will actually paint.
///
/// Colour tests read through these rather than through `AppColors`, because the
/// two have been out of step before: the palette named one colour for a
/// secondary label while `OutlinedButton` resolved a different one, and every
/// token-based test passed while the shipped label sat at 3.09:1. A test that
/// asserts about a constant proves the constant, not the screen.

/// The fill a `FilledButton` paints at rest.
Color filledButtonFill(ThemeData theme) =>
    theme.filledButtonTheme.style!.backgroundColor!.resolve(<WidgetState>{})!;

/// The label colour an `OutlinedButton` paints at rest.
Color outlinedButtonLabel(ThemeData theme) =>
    theme.outlinedButtonTheme.style!.foregroundColor!.resolve(<WidgetState>{})!;
