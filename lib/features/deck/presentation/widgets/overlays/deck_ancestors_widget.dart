import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_path_segment_model.dart';
import '../../../../../shared/widgets/mx_sheet.dart';

/// Every level above the open deck, reachable in one tap.
///
/// **The other half of the header's one target** (owner review, 2026-08-21).
/// The path line is a single control that goes up one level, because that is
/// the move a reader makes almost every time and it deserves the whole width.
/// Jumping three levels at once is rarer, so it moved to a long press — and
/// here it is a list, where each row is an ordinary tile at the touch floor
/// rather than a word squeezed into a 32px line.
///
/// The open deck is not on the list: it is where the reader already is, and
/// its name is the bar's title.
Future<void> showDeckAncestors(
  BuildContext context, {
  required DeckListSnapshot snapshot,
}) async {
  final target = await showMxSheet<String?>(
    context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.deckPathAncestorsTitle,
      actions: <MxActionSheetAction>[
        MxActionSheetAction(
          label: sheetContext.l10n.deckPathRootLabel,
          icon: Icons.home_outlined,
          onPressed: () => Navigator.of(sheetContext).pop(_kLibrary),
        ),
        for (final DeckPathSegment segment in snapshot.ancestors)
          MxActionSheetAction(
            label: segment.name,
            icon: Icons.folder_outlined,
            onPressed: () => Navigator.of(sheetContext).pop(segment.id),
          ),
      ],
    ),
  );

  if (!context.mounted || target == null) return;

  if (target == _kLibrary) {
    context.goNamed(RouteNames.decks);

    return;
  }

  context.goNamed(
    RouteNames.deckDetail,
    pathParameters: <String, String>{RoutePathParams.deckId: target},
  );
}

/// Stands for the deck list itself, which has no deck id of its own. A
/// sentinel rather than an empty string: an id that means "no id" is the kind
/// of thing that survives a refactor as a bug.
const String _kLibrary = 'library';
