import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_breadcrumb.dart';
import '../../domain/entities/deck_entity.dart';
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

  @override
  Widget build(BuildContext context) {
    final DeckEntity? parent = snapshot.parent;
    if (parent == null || snapshot.ancestors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      // The same gutter the cards use, so the path lines up with the list it
      // describes. `sm` below rather than `xl`: the breadcrumb and the toolbar
      // are one band of chrome, and a section-sized gap between them would read
      // as two unrelated bars.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: MxBreadcrumb(
        semanticLabel: context.l10n.deckPathSemanticLabel,
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
      ),
    );
  }
}
