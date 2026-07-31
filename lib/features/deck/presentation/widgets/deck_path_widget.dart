import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_breadcrumb.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../../domain/models/deck_path_segment_model.dart';

/// Where this level sits in the tree.
///
/// **The whole path, from inside any deck.** It used to start at level 3 and
/// list ancestors only, and both restrictions were argued for here: one level in,
/// the only step above is the deck list, which Back and the Decks tab already
/// reach; and the current deck is the app-bar title one line up, so a trailing
/// copy repeats the largest text on screen. Both arguments are about *duplicate*
/// chrome, and both are true in isolation. What they added up to was a control
/// that was absent exactly where a user first looks for it — the project owner
/// reported it as "the breadcrumb doesn't show" from inside a deck, which is what
/// a rule that hides a component from its most common location looks like from
/// the outside.
///
/// So the strip is now literal: the deck list, every ancestor, and the deck you
/// are standing in. The costs the old comments named are real and are accepted —
/// the first step duplicates Back, the last duplicates the title, and the strip
/// is two steps longer before it folds. What is bought is that the answer to
/// "where am I" is always on screen and always has the same shape.
///
/// The last step carries no [MxBreadcrumbItem.onTap]: it is where you already
/// are, so it renders as quiet text rather than as a control that does nothing.
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
  /// Any deck level has one — at minimum the list and the deck itself. Only the
  /// deck list, where [DeckListSnapshot.parent] is null, has nothing to draw.
  static bool hasPath(DeckListSnapshot snapshot) => snapshot.parent != null;

  @override
  Widget build(BuildContext context) {
    final DeckEntity? parent = snapshot.parent;
    if (parent == null) return const SizedBox.shrink();

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
        // The list itself. `decksTitle` rather than a string of its own: this
        // step goes to that screen and should say what that screen is called,
        // and a second copy would be one rename away from disagreeing with it.
        MxBreadcrumbItem(
          label: context.l10n.decksTitle,
          onTap: () => context.goNamed(RouteNames.decks),
        ),
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
        // No `onTap`: this is where the user already is.
        MxBreadcrumbItem(label: parent.name),
      ],
    );
  }
}
