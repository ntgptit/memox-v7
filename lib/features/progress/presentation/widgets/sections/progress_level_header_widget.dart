import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';

/// The overview band that sits above the library level, with its own spacing.
///
/// A widget rather than a `Padding` written out at each site: the band appears
/// in four places — the loaded level, the empty level, the loading face and the
/// error face — and four copies of its numbers is how the four faces end up
/// inset differently from one another, which is exactly what happened before it
/// existed.
///
/// The gap below is `AppSpacing.xl`, a *section* break. **It is not subtracted
/// from what follows.** An earlier version said it was, and the totals panel
/// took `0` above on that reasoning — but on the loaded face the pinned range
/// strip sits between the two, so the panel's neighbour is the strip and not
/// this band. The panel takes `md` at every level; the strip's own `xs` below
/// completes the 16 the two have between them.
class ProgressLevelHeaderWidget extends StatelessWidget {
  const ProgressLevelHeaderWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gutter = mxScreenGutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.md,
        gutter,
        AppSpacing.xl,
      ),
      child: child,
    );
  }
}

/// [body] with the overview band above it, or [body] alone when there is none.
///
/// For the three faces that are a single box — loading, empty, error. The
/// loaded face is a `CustomScrollView` and places [ProgressLevelHeaderWidget]
/// itself, because the pinned range strip has to sit *between* the band and the
/// rest; the two share the band widget, not this wrapper.
///
/// **Every face keeps the header, not just the loaded one.** The header is
/// the whole-library overview: it is true while the level loads, it is still
/// true when the level's read fails, and it is true when there are no decks to
/// list. A face that dropped it took three sections of real data off the screen
/// to report something about a *different* question — the user watching their
/// streak vanish because a deck query timed out has been told the wrong thing.
///
/// `/progress/:deckId` passes null and is unaffected: inside one deck there is
/// no library overview to keep.
class ProgressHeaderedBody extends StatelessWidget {
  const ProgressHeaderedBody({required this.body, this.header, super.key});

  final Widget? header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final Widget? band = header;
    if (band == null) return body;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProgressLevelHeaderWidget(child: band),
          body,
        ],
      ),
    );
  }
}
