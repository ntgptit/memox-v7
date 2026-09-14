import 'package:flutter/material.dart';

/// How much of the page a modal hides: the handoff Scrim, the `scrim` role at
/// 45% in both modes (M100.93).
///
/// Material's `black54` reads as a dead grey over a navy palette; deriving from
/// `scrim` keeps the hue. It used to go deeper in dark (72% against 48%); the
/// handoff holds one figure, and the dark page's depth is the surface ladder's.
///
/// **Translucent on purpose, and exempt from the precompute rule for the same
/// reason a shadow is:** a barrier's whole job is to let the page show through
/// dimmed. There is no ground to blend against, because the ground is whatever
/// screen happens to be underneath.
Color modalBarrierColor(ColorScheme scheme) =>
    scheme.scrim.withValues(alpha: _scrimAlpha);

/// The handoff Scrim's opacity.
const double _scrimAlpha = 0.45;
