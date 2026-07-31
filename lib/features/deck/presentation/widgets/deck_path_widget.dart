import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_breadcrumb.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../../domain/models/deck_path_segment_model.dart';

/// Where this level sits in the tree, once that stops being obvious.
///
/// **It appears from level 3 down, and nowhere else.** At the root there is
/// nothing above. One level in, the only step above is the deck list itself,
/// which the Back arrow and the Decks tab both already reach in one tap — a crumb
/// there would be a third control doing the same thing, which is the duplicate
/// chrome this design has refused elsewhere. From level 3 the intermediate decks
/// are reachable by nothing else short of tapping Back repeatedly, and that is
/// the gap a breadcrumb closes.
///
/// **It shows ancestors only.** The current deck was the last step until
/// M4.10e, on the argument that a path needs somewhere to terminate. On this
/// screen it does not: the app-bar title one line above says exactly the same
/// word, so the trailing step spent a third of the strip's width repeating the
/// largest text on screen. Dropping it also makes every element of the strip
/// actionable, which is a better answer to "what is this control for".
///
/// Navigation goes by route name and path-parameter constant, like every other
/// jump in this feature — a literal `/decks/$id` would work today and break
/// silently the first time the route moves.
class DeckPathWidget extends StatelessWidget {
  const DeckPathWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  /// Whether this snapshot has a path worth drawing.
  ///
  /// Exposed because the caller mounts this in `MxContentShell.subheader`, and a
  /// subheader reserves its height whether or not its child paints anything. A
  /// widget that shrinks to nothing inside a slot that has already claimed its
  /// height leaves a band of empty chrome at the root level, where there is no
  /// path to show.
  static bool hasPath(DeckListSnapshot snapshot) =>
      snapshot.parent != null && snapshot.ancestors.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasPath(snapshot)) return const SizedBox.shrink();

    // **No padding of its own any more.** The gutter and the space below it come
    // from `MxContentShell`'s subheader slot, which takes them from the same
    // `_defaultPadding` the body uses — so the path lines up with the rows under
    // it at both widths, where a hardcoded `AppSpacing.lg` matched them only at
    // the wide one.
    return MxBreadcrumb(
      semanticLabel: context.l10n.deckPathSemanticLabel,
      // The library root, recognisable without reading it. Outlined, because
      // this step is a place to go rather than the place you are — the design's
      // own rule for which twin of a glyph to use.
      rootIcon: Icons.home_outlined,
      items: <MxBreadcrumbItem>[
        for (final DeckPathSegment segment in snapshot.ancestors)
          MxBreadcrumbItem(
            label: segment.name,
            onTap: () => context.goNamed(
              RouteNames.deckDetail,
              pathParameters: <String, String>{
                RoutePathParams.deckId: segment.id,
              },
            ),
          ),
      ],
    );
  }
}
