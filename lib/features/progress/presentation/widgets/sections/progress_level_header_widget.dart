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
///
/// **A `SliverFillRemaining`, not a `Column` in a `SingleChildScrollView`**
/// (SC-C3-18). The column gave [body] unbounded height, and every face this
/// wraps is a `Center` — `MxEmptyState`, `MxErrorState` and `MxLoadingState`
/// all centre themselves in whatever they are given. Unbounded, that `Center`
/// shrink-wraps and top-anchors directly under the band instead of taking the
/// space that is left, which is the one composition the *loaded* face of the
/// same screen does not use: `progress_deck_screen.dart` gives its own empty
/// level a `SliverFillRemaining(hasScrollBody: false)`, and
/// `deck_list_sliver_widget` does the same, "so the state is sized to its
/// content and centred in what is left". Three faces of one screen were laid
/// out by two different rules.
///
/// `hasScrollBody: false` is what keeps a short face short: the sliver takes
/// the larger of the remaining extent and the child's own intrinsic height, so
/// nothing is stretched down a viewport it does not fill and nothing is clipped
/// when the band alone has already filled one.
///
/// **One sliver holding both, and not the band and the body as two slivers**,
/// which is the obvious shape and is wrong here. A sliver whose scroll offset
/// starts past the viewport plus its cache extent is never laid out, and this
/// band gets that tall: at text scale 2.0 it measures 1084dp against a 716dp
/// viewport, so the face behind it is not merely off screen — it is not in the
/// tree, and `MxErrorState`'s `liveRegion` then announces nothing because there
/// is no node to announce. Measured, not reasoned about: as two slivers,
/// `find.byType(MxEmptyState)` finds zero widgets at scale 2.0. One sliver
/// starts at offset 0 and is always built, and `Expanded` hands the face
/// whatever the band leaves.
///
/// **It moves no pixel today, and that is the honest report.** Measured at
/// 393×852 the band runs 56→700 of a 56→772 viewport, so the 72dp left over is
/// smaller than every face's own height (empty 176, error 228, loading 84) and
/// each still lays out at its own size at y=700 — below the fold, but reachable
/// by scrolling rather than clipped. The centring this buys only becomes
/// visible once the band stops filling the viewport — SC-C9-12 — which is why
/// the tests pin *what the composition does with the space it is given* rather
/// than a fold that no sliver can reach while the band is this tall.
class ProgressHeaderedBody extends StatelessWidget {
  const ProgressHeaderedBody({required this.body, this.header, super.key});

  final Widget? header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final Widget? band = header;
    // Bare, and it must stay bare: inside a deck there is no band, so the body
    // is already given the shell's full height and centres in it correctly.
    // Wrapping it in a scroll view here would take that bound away again.
    if (band == null) return body;

    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ProgressLevelHeaderWidget(child: band),
              Expanded(child: body),
            ],
          ),
        ),
      ],
    );
  }
}
