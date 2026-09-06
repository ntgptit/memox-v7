import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_path_segment_model.dart';
import '../overlays/deck_ancestors_widget.dart';

/// Where this level sits in the tree.
///
/// **Inside a deck only.** At the root the header's second line states the
/// level instead — `4 decks · 868 cards` — because "Library" over "All decks"
/// was one thing said twice in the header's scarcest space
/// (`deck_subheader_widget.dart`, which is what decides between the two). This
/// widget is never built with an empty ancestor list and never renders a
/// lone `All decks` step.
///
/// **The whole way out, and not the deck you are in.** It lists the top of the
/// tree and every ancestor, and stops there: the open deck's name is the bar's
/// title one line above, and a path that ended by repeating it would spend the
/// header's width saying the same word twice (owner review, 2026-08-20). So
/// the strip answers "how do I get back", and the title answers "where am I" —
/// between them nothing is missing and nothing is duplicated.
///
/// It used to start only at level 3 and to list ancestors alone. That was
/// argued from the same instinct — avoid duplicate chrome — and it went too
/// far: the strip was then absent exactly where a reader first looks for it,
/// which the project owner reported as "the breadcrumb doesn't show" from
/// inside a deck. One level in, it now shows `All decks` and nothing else,
/// which is a real answer rather than a hidden one.
///
/// **The strip is one target** (owner review, 2026-08-21): a tap goes up one
/// level, a long press opens every level. No step carries its own `onTap` —
/// see `MxBreadcrumb.onUp` for why four small controls became one big one.
///
/// Navigation goes by route name and path-parameter constant, like every other
/// jump in this feature — a literal `/decks/$id` would work today and break
/// silently the first time the route moves.
class DeckPathWidget extends StatelessWidget {
  const DeckPathWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  /// One level up: the nearest ancestor, or the list when there is none.
  ///
  /// **By name, not by popping.** The bar's platform arrow pops the navigator,
  /// which is right for a pushed route and wrong for a deep link — a deck
  /// opened from a notification has nothing to pop to. It is also wrong for
  /// the ancestor sheet, which jumps several levels at once.
  void _goUp(BuildContext context) {
    final ancestors = snapshot.ancestors;
    if (ancestors.isEmpty) {
      context.goNamed(RouteNames.decks);

      return;
    }

    context.goNamed(
      RouteNames.deckDetail,
      pathParameters: <String, String>{
        RoutePathParams.deckId: ancestors.last.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // **No padding of its own any more.** The gutter and the space below it come
    // from `MxContentShell`'s subheader slot, which takes them from the same
    // `_defaultPadding` the body uses — so the path lines up with the rows under
    // it at both widths, where a hardcoded `AppSpacing.lg` matched them only at
    // the wide one.
    return MxBreadcrumb(
      semanticLabel: context.l10n.deckPathUpSemanticLabel,
      // The top of the tree, recognisable without reading it.
      rootIcon: Icons.home_outlined,
      // A line of the header, not a band of its own.
      lineHeight: MxBreadcrumb.compactLineHeight,
      // **The strip is one target** (owner review, 2026-08-21): tap goes up a
      // level, long press opens every level. The steps below carry no `onTap`
      // — see `MxBreadcrumb.onUp` for why four small controls became one big
      // one.
      upIcon: Icons.chevron_left,
      onUp: () => _goUp(context),
      onShowAll: () => showDeckAncestors(context, snapshot: snapshot),
      items: <MxBreadcrumbItem>[
        // **"All decks", not "Root".** It names the top of the tree in the
        // user's own words — "Root" was the schema's term leaking into chrome
        // (owner mockup, 2026-08-20).
        MxBreadcrumbItem(label: context.l10n.deckPathRootLabel),
        for (final DeckPathSegment segment in snapshot.ancestors)
          MxBreadcrumbItem(label: segment.name),
        // **The open deck is not a step.** Its name is the bar's title one
        // line above, and a path that ends by repeating it spends the header's
        // scarcest width saying the same word twice (owner review,
        // 2026-08-20).
      ],
    );
  }
}
