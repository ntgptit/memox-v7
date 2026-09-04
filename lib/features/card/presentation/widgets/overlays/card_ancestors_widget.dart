import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../../../shared/widgets/mx_sheet.dart';
import '../../../domain/models/deck_context_model.dart';

/// Reach any ancestor of the deck a card screen sits in — the long-press
/// companion to the trail's tap, the same grammar the deck list uses
/// (A20.1 P1-16).
///
/// The deck feature has its own sheet over its own snapshot type; a feature
/// may not import another's presentation, so this one walks the card's
/// `DeckContextModel` instead. Same rows, same words, same route names.
///
/// [onLeave] wraps the navigation for screens that must confirm before
/// leaving — the editor with unsaved changes.
Future<void> showCardAncestors(
  BuildContext context, {
  required DeckContextModel deckContext,
  void Function(VoidCallback go)? onLeave,
}) async {
  final String? target = await showMxSheet<String?>(
    context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.deckPathAncestorsTitle,
      actions: <MxActionSheetAction>[
        MxActionSheetAction(
          label: sheetContext.l10n.deckPathRootLabel,
          icon: Icons.home_outlined,
          onPressed: () => Navigator.of(sheetContext).pop(_kLibrary),
        ),
        for (final DeckBreadcrumbSegment segment in deckContext.ancestors)
          MxActionSheetAction(
            label: segment.name,
            icon: Icons.folder_outlined,
            onPressed: () => Navigator.of(sheetContext).pop(segment.id),
          ),
      ],
    ),
  );
  if (target == null || !context.mounted) return;

  void go() {
    if (target == _kLibrary) {
      context.goNamed(RouteNames.decks);
      return;
    }
    context.goNamed(
      RouteNames.deckDetail,
      pathParameters: <String, String>{RoutePathParams.deckId: target},
    );
  }

  if (onLeave == null) {
    go();
    return;
  }
  onLeave(go);
}

/// Go up one level from the deck a card screen sits in: the nearest ancestor,
/// or the library when there is none.
void goUpFromCardContext(
  BuildContext context,
  DeckContextModel deckContext, {
  void Function(VoidCallback go)? onLeave,
}) {
  void go() {
    final ancestors = deckContext.ancestors;
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

  if (onLeave == null) {
    go();
    return;
  }
  onLeave(go);
}

/// The sentinel the sheet returns for the top of the tree — never a deck id.
const String _kLibrary = '';
