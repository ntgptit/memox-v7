import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/models/deck_content_type_model.dart';
import 'deck_actions_widget.dart';

/// What an `unset` deck can be asked to create.
enum _ChildKind { subDeck, card }

/// Opens the right create flow for [parent], asking first when the deck could
/// still become either kind (BR-61).
///
/// **An `unset` deck offers both, and neither is disabled.** BR-62 says the
/// first child decides the deck's `content_type`, and `createCard` applies that
/// in the same transaction as the insert — so creating a card here is a legal,
/// supported action, not a blocked one. The screen used to offer only "new
/// sub-deck" beside a notice saying cards were unavailable, which left an `unset`
/// deck with no way to ever hold a card: the card screen is reached only once
/// `content_type` is already `card`, and only a card could set it.
///
/// Once the type is settled the question disappears — BR-66 says Create shows
/// only the matching action, so a `deck` deck goes straight to the sub-deck form
/// and a `card` deck straight to the editor.
///
/// The card editor is reached by route name, the way every other cross-feature
/// jump in this feature works; the deck feature never imports the card feature's
/// widgets (AD-13).
Future<void> showCreateChildForm(
  BuildContext context, {
  required DeckEntity parent,
}) async {
  final kind = switch (parent.contentType) {
    DeckContentType.card => _ChildKind.card,
    DeckContentType.deck => _ChildKind.subDeck,
    // An unrecognised type is read-only (see DeckContentType.unknown): offering
    // to add to it could contradict a rule a newer schema attached.
    DeckContentType.unknown => null,
    DeckContentType.unset => await _askChildKind(context),
  };
  if (kind == null || !context.mounted) return;

  if (kind == _ChildKind.subDeck) {
    await showCreateSubDeckForm(context, parentDeckId: parent.id);
    return;
  }

  context.goNamed(
    RouteNames.cardEditor,
    pathParameters: <String, String>{RoutePathParams.deckId: parent.id},
  );
}

Future<_ChildKind?> _askChildKind(BuildContext context) =>
    showModalBottomSheet<_ChildKind>(
      context: context,
      builder: (sheetContext) => MxActionSheet(
        title: sheetContext.l10n.deckCreateChildTitle,
        actions: <MxActionSheetAction>[
          MxActionSheetAction(
            label: sheetContext.l10n.deckCreateSubDeckAction,
            icon: Icons.folder_outlined,
            onPressed: () => Navigator.of(sheetContext).pop(_ChildKind.subDeck),
          ),
          MxActionSheetAction(
            label: sheetContext.l10n.deckCreateCardAction,
            icon: Icons.style_outlined,
            onPressed: () => Navigator.of(sheetContext).pop(_ChildKind.card),
          ),
        ],
      ),
    );
