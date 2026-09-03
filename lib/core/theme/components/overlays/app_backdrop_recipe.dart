import 'package:flutter/material.dart';

/// How much of the page a modal hides.
///
/// Material's `black54` reads as a dead grey over a navy palette. Deriving from
/// `scrim` keeps the hue and lets dark go deeper than light, which is what the
/// two backgrounds need — a 54% black over a `#0A082D` page barely registers.
///
/// **Translucent on purpose, and exempt from the precompute rule for the same
/// reason a shadow is:** a barrier's whole job is to let the page show through
/// dimmed. There is no ground to blend against, because the ground is whatever
/// screen happens to be underneath.
Color modalBarrierColor(ColorScheme scheme) => scheme.scrim.withValues(
  alpha: scheme.brightness == Brightness.dark ? 0.72 : 0.48,
);
