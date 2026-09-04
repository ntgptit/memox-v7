import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_breakpoints.dart';

/// The reading column: content capped at [AppBreakpoints.medium], so a line
/// of a card, a wizard row or a task list never stretches into a line the eye
/// cannot track back to the start of.
///
/// **One owner** (A20.1 P2-18). Card Detail, Card Import, the tag catalog and
/// Study Home each re-derived this cap as their own `ConstrainedBox`, which is
/// four decisions that happened to agree. The cap belongs to the shell's
/// geometry — a phone never binds it, anything wider binds it identically —
/// and a caller now names the column rather than restating its width.
///
/// It caps width only. Where the column sits — centred, or anchored to the
/// top of a scrollable body — is the caller's placement, not the column's
/// geometry, so the caller keeps its `Center` or `Align`.
class MxReadingColumn extends StatelessWidget {
  const MxReadingColumn({required this.child, super.key});

  final Widget child;

  /// The one width the column is allowed to be.
  static const double maxWidth = AppBreakpoints.medium;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: maxWidth),
    child: child,
  );
}
