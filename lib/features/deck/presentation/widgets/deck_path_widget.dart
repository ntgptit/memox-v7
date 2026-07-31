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
/// **Present at every level, including the deck list itself**, where it is the
/// single step `Root` with nothing to tap. A strip that appeared only once you
/// were inside something made the reader learn it twice — first that it exists,
/// then where. One shape, always in the same place, is cheaper to read than a
/// band of chrome that comes and goes.
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

  @override
  Widget build(BuildContext context) {
    final DeckEntity? parent = snapshot.parent;
    final bool isAtRoot = parent == null;

    // **No padding of its own any more.** The gutter and the space below it come
    // from `MxContentShell`'s subheader slot, which takes them from the same
    // `_defaultPadding` the body uses — so the path lines up with the rows under
    // it at both widths, where a hardcoded `AppSpacing.lg` matched them only at
    // the wide one.
    return MxBreadcrumb(
      semanticLabel: context.l10n.deckPathSemanticLabel,
      // The top of the tree, recognisable without reading it.
      rootIcon: Icons.home_outlined,
      items: <MxBreadcrumbItem>[
        // **"Root", not the screen's own title.** It names the top of the tree
        // rather than the screen that lists it: a first step reading "Decks"
        // while the app bar above also read "Decks" looked like a link back to
        // where the reader already was. And on that screen it is exactly that,
        // so it carries no `onTap` there — the same rule the last step follows.
        MxBreadcrumbItem(
          label: context.l10n.deckPathRootLabel,
          onTap: isAtRoot ? null : () => context.goNamed(RouteNames.decks),
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
        // No `onTap`: this is where the user already is. Absent at the root,
        // where the first step is already that statement.
        if (parent != null) MxBreadcrumbItem(label: parent.name),
      ],
    );
  }
}
