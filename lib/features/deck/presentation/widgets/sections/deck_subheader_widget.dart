import 'package:flutter/material.dart';

import '../../../domain/models/deck_list_snapshot_model.dart';
import 'deck_path_widget.dart';

/// The path, and the way into search.
///
/// Both are chrome and both stay put while the list scrolls, which is what the
/// shell's subheader slot is for.
///
/// **Search opens a surface of its own now, and the scope changed with it
/// (M99.32).** The field used to expand into this strip and searched the
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
    // The strip is the breadcrumb alone now: search moved up into the app
    // bar so the header reads as one row of actions over one line of place
    // (owner mockup, 2026-08-20). The slot itself stays at every level —
    // a band of chrome that comes and goes is what the path widget's own
    // doc argues against.
    return DeckPathWidget(snapshot: snapshot);
  }
}
