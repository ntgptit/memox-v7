import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/models/deck_content_type_model.dart';
import 'deck_actions_widget.dart';
import '../../../../../shared/widgets/mx_sheet.dart';

/// What an `unset` deck can be asked to create — or to be filled from.
/// Import is a third door, not a third child kind: it leads to the card
/// wizard, and the first written card settles the type there (BR-172).
enum _ChildKind { subDeck, card, importCards }

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
///
/// **One sheet, one verb: both card doors `push`.** The rule belongs to the
/// sheet rather than to either row — an `unset` deck must land on its own
/// detail again when the user backs out, not on a card list it never chose
/// (UC-10, M4.12 W5), and that is as true of the editor as of the import
/// wizard. The editor used to `go`, which rebuilds the match list from
/// `/decks/<id>/cards/new` and materialises a `CardListScreen` page underneath
/// it, so ✕ dropped the user exactly where the import row forbids (SC-C4-20).
/// Save is unaffected: the write settles `content_type` to `card` (BR-62), and
/// the deck's own level is what answers a card deck from there.
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

  if (kind == _ChildKind.importCards) {
    // The wizard mounts on the root navigator, so this push covers the shell
    // and its bottom bar (M4.12 I1); the editor below pushes inside the branch
    // and keeps them. Which navigator receives the page is the only difference
    // between the two rows — where cancelling lands is the same.
    await context.pushNamed(
      RouteNames.cardImport,
      pathParameters: <String, String>{RoutePathParams.deckId: parent.id},
    );
    return;
  }

  await context.pushNamed(
    RouteNames.cardEditor,
    pathParameters: <String, String>{RoutePathParams.deckId: parent.id},
  );
}

Future<_ChildKind?> _askChildKind(BuildContext context) =>
    showMxSheet<_ChildKind>(
      context,
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
          // Import as the bulk way in (UC-10, M4.12 W6). Only the `unset`
          // sheet offers it here: a `card` deck redirects to its card list,
          // whose overflow menu owns the action, and a `deck` deck can never
          // hold cards (BR-64).
          MxActionSheetAction(
            label: sheetContext.l10n.cardImportEntryAction,
            icon: Icons.upload_file_outlined,
            onPressed: () =>
                Navigator.of(sheetContext).pop(_ChildKind.importCards),
          ),
        ],
      ),
    );
