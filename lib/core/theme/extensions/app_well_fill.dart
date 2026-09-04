import 'package:flutter/material.dart';

import 'theme_context_extension.dart';

/// The fills a metric well may sit on — the closed counterpart of [AppInk]
/// for the surface *behind* a glyph (A20.1 P2-07).
///
/// `MxMetricWell.wellColor` was an open `Color?` beside a closed `AppInk`
/// tint in the same constructor. Every one of its eight callers fed a
/// semantic token, and they fed exactly these four; the enum makes that the
/// only thing a caller can say, so a metric cannot invent a fill any more
/// than it can invent an ink.
enum AppWellFill {
  /// The resting well — `surfaceMuted`, what most metrics sit on.
  muted,

  /// A count that is due today.
  due,

  /// A streak that is alive.
  streak,

  /// A count that is overdue — late rather than faulty, which is why it is
  /// the *danger* container and not `error`.
  danger;

  Color resolve(BuildContext context) {
    final semantic = context.semanticColors;
    return switch (this) {
      AppWellFill.muted => semantic.surfaceMuted,
      AppWellFill.due => semantic.dueContainer,
      AppWellFill.streak => semantic.streakContainer,
      AppWellFill.danger => semantic.dangerContainer,
    };
  }
}
