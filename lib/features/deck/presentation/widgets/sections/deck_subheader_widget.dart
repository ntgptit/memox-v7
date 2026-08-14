import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import 'deck_path_widget.dart';

/// The path, and the way into search.
///
/// Both are chrome and both stay put while the list scrolls, which is what the
/// shell's subheader slot is for.
///
/// **Search opens a surface of its own now, and the scope changed with it
/// (M99.23).** The field used to expand into this strip and searched the
/// subtree the user was standing in — deck names only, because that is all the
/// deck feature can see. Global Library Search covers deck names, card fronts,
/// card backs and tag names in one ranked list, which is a surface neither this
/// feature nor the card feature can own: `features/deck/presentation/` may not
/// import another feature's widgets (AD-13). So the affordance navigates by
/// name, and the search screen holds the input.
///
/// What that costs is the in-place field, and with it the subtree scoping —
/// deliberately, because a result row now carries its full deck path, which
/// answers "where did I put it" better than a scoped list of bare names did.
class DeckSubheaderWidget extends StatelessWidget {
  const DeckSubheaderWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // `Expanded`, so the path starts on the screen gutter and the action
        // sits on the opposite edge — the two ends of the strip every other
        // element on the screen is aligned to.
        Expanded(child: DeckPathWidget(snapshot: snapshot)),
        MxIconButton(
          icon: Icons.search,
          semanticLabel: context.l10n.librarySearchOpenLabel,
          tooltip: context.l10n.librarySearchOpenLabel,
          // **`push`, not `go`.** Search is a *sibling* of the deck-detail
          // route under `/`, so `go('/search')` rebuilds the branch's match
          // list as `[/, /search]` and throws away every level below the root
          // — Back from a search opened three decks deep then landed on the
          // root list. Pushing keeps the stack the user built, which is what
          // the wireframe's S2 and W4 promise. It stays on the branch
          // navigator, so the bottom bar is unaffected.
          onPressed: () => context.pushNamed(RouteNames.librarySearch),
        ),
      ],
    );
  }
}
