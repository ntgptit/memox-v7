import 'package:flutter/material.dart';

/// How much of the page a modal hides.
///
/// Material's `black54` reads as a dead grey over a navy palette. Deriving
/// from `scrim` keeps the hue instead.
///
/// **Used to split 0.48 light / 0.72 dark**, on the argument that a 54% black
/// over a near-black `#0A082D` page barely registers, so dark needed to go
/// deeper to read as dimmed at all. v3 replaces that per-mode judgement call
/// with one recipe: `scrim` at [_barrierOpacity] in both themes (§15.1 —
/// Scrim, Dialog and BottomSheet are all given 0.45), so no component spells
/// the number itself and there is only one value to ever change.
///
/// **Translucent on purpose, and exempt from the precompute rule for the same
/// reason a shadow is:** a barrier's whole job is to let the page show through
/// dimmed. There is no ground to blend against, because the ground is whatever
/// screen happens to be underneath.
Color modalBarrierColor(ColorScheme scheme) =>
    scheme.scrim.withValues(alpha: _barrierOpacity);

const double _barrierOpacity = 0.45;
