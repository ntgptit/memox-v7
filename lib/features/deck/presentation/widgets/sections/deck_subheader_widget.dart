import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
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
    // **The chevron belongs to the path, not to the bar** (owner review,
    // 2026-08-20). The line already says where "up" is; putting the platform
    // arrow beside the title as well gave the header two back affordances for
    // one destination. `MxContentShell` drops its automatic leading wherever a
    // subline is present, so this is the only one.
    //
    // Absent at the root, where there is nothing above to go to — and the
    // path line keeps its height either way, so the header does not change
    // shape on the way in.
    if (snapshot.parent == null) return DeckPathWidget(snapshot: snapshot);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _DeckPathBackWidget(snapshot: snapshot),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: DeckPathWidget(snapshot: snapshot)),
      ],
    );
  }
}

/// One level up, on the path's own line.
///
/// **It goes where the parent is, not where the stack came from.** The bar's
/// platform arrow pops the navigator, which is right for a pushed route and
/// wrong for a deep link — a deck opened from a notification has nothing to
/// pop to. The nearest ancestor is a place, so this navigates by name to it,
/// and to the deck list when the open deck is a root's child.
class _DeckPathBackWidget extends StatelessWidget {
  const _DeckPathBackWidget({required this.snapshot});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ancestors = snapshot.ancestors;

    return Semantics(
      button: true,
      label: context.l10n.deckPathUpSemanticLabel,
      child: InkWell(
        onTap: () => ancestors.isEmpty
            ? context.goNamed(RouteNames.decks)
            : context.goNamed(
                RouteNames.deckDetail,
                pathParameters: <String, String>{
                  RoutePathParams.deckId: ancestors.last.id,
                },
              ),
        child: SizedBox(
          height: MxBreadcrumb.compactLineHeight,
          width: AppSpacing.lg,
          child: Icon(
            Icons.chevron_left,
            size: AppIconSize.sm,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
