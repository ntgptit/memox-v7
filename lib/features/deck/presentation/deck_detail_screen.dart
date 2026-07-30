import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/error/failure.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/mx_async_view.dart';
import '../../../shared/widgets/mx_content_shell.dart';
import '../../../shared/widgets/mx_empty_state.dart';
import '../../../shared/widgets/mx_error_state.dart';
import '../../../shared/widgets/mx_icon_button.dart';
import '../domain/deck_content_type_model.dart';
import '../domain/deck_entity.dart';
import 'deck_actions_widget.dart';
import 'deck_detail_controller.dart';
import 'deck_tile_widget.dart';

/// One deck's contents (UC-06 step 4, UC-08).
///
/// Renders **either** sub-decks or the card handoff, never both, because a deck
/// holds one kind of thing (BR-65). Which one is decided by the stored
/// `content_type` and not by what happens to be in the deck — an empty
/// `card`-type deck is still a card deck (BR-67).
///
/// It lives inside the Decks branch of the navigation shell, so the bottom bar
/// stays visible and Back returns to the list rather than leaving the app.
class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => MxAsyncView<DeckDetail>(
        value: ref.watch(deckDetailProvider(deckId)),
        loadingLabel: context.l10n.deckDetailLoadingLabel,
        // Untitled shell while loading: the app-bar title is the deck's name and
        // is not known yet. Without a shell the spinner would have no Scaffold,
        // and on this pushed route the deck list would show through behind it.
        loadingFrame: (loading) => MxContentShell(body: loading),
        data: (detail) => _DeckDetailBody(detail: detail),
        error: (error, stackTrace) =>
            _DeckDetailError(error: error, deckId: deckId),
      ),
    );
  }
}

class _DeckDetailBody extends StatelessWidget {
  const _DeckDetailBody({required this.detail});

  final DeckDetail detail;

  @override
  Widget build(BuildContext context) {
    final deck = detail.deck;

    return MxContentShell(
      title: deck.name,
      actions: <Widget>[
        // The create actions come from the content type, so they are built once
        // here and reflected in the empty state's button below.
        if (_mayCreateSubDeck(deck))
          MxIconButton(
            icon: Icons.create_new_folder_outlined,
            semanticLabel: context.l10n.deckCreateSubDeckAction,
            onPressed: () =>
                showCreateSubDeckForm(context, parentDeckId: deck.id),
          ),
        MxIconButton(
          icon: Icons.more_vert,
          semanticLabel: context.l10n.deckActionsSemanticLabel,
          onPressed: () => showDeckActions(
            context,
            deck: deck,
            mayOfferReset: detail.mayOfferReset,
            // The deck being viewed is gone, so staying here would show a
            // not-found state the user did not ask for.
            onDeleted: () => context.goNamed(RouteNames.decks),
          ),
        ),
      ],
      body: _body(context, deck),
    );
  }

  Widget _body(BuildContext context, DeckEntity deck) {
    // A `card` deck shows no deck list at all — not an empty one (BR-63). The
    // card list itself belongs to M4.11; until then this states plainly that
    // the feature is not in the build rather than offering a control that does
    // nothing.
    if (deck.contentType == DeckContentType.card) {
      return MxEmptyState(
        icon: Icons.style_outlined,
        title: context.l10n.deckDetailEmptyCardTitle,
        message: context.l10n.deckDetailEmptyCardMessage,
      );
    }

    if (detail.childDecks.isEmpty) return _emptyState(context, deck);

    return ListView.builder(
      itemCount: detail.childDecks.length,
      itemBuilder: (context, index) {
        final child = detail.childDecks[index];

        return DeckChildTileWidget(
          deck: child,
          onTap: () => context.goNamed(
            RouteNames.deckDetail,
            pathParameters: <String, String>{RoutePathParams.deckId: child.id},
          ),
          onActions: () => showDeckActions(
            context,
            deck: child,
            // Whether the child may be reset is its own question, answered on
            // its own screen where its children are known. Offering it from
            // here would mean guessing.
            mayOfferReset: false,
            onDeleted: () {},
          ),
        );
      },
    );
  }

  /// The empty state, which differs by content type because the next step does.
  ///
  /// An `unset` deck can still become either kind, so BR-61 requires both
  /// choices to be visible — the card one disabled, with the reason, rather than
  /// hidden. Hiding it would teach the user this deck can only hold decks, which
  /// is not true until they add one.
  Widget _emptyState(BuildContext context, DeckEntity deck) {
    final isUnset = deck.contentType == DeckContentType.unset;

    return Column(
      children: <Widget>[
        Expanded(
          child: MxEmptyState(
            icon: Icons.folder_outlined,
            title: isUnset
                ? context.l10n.deckDetailEmptyUnsetTitle
                : context.l10n.deckDetailEmptyDeckTitle,
            message: isUnset
                ? context.l10n.deckDetailEmptyUnsetMessage
                : context.l10n.deckDetailEmptyDeckMessage,
            actionLabel: context.l10n.deckCreateSubDeckAction,
            onAction: () =>
                showCreateSubDeckForm(context, parentDeckId: deck.id),
          ),
        ),
        if (isUnset)
          DeckNoticeWidget(
            message: context.l10n.deckCreateCardUnavailableMessage,
          ),
      ],
    );
  }

  /// Creating a sub-deck is allowed unless the deck is fixed to cards (BR-59,
  /// BR-64, BR-66). Depth is not checked here: the repository refuses a create
  /// past level 10 before writing anything (BR-55), and a UI that also guessed
  /// at depth would need the ancestry this screen does not load.
  static bool _mayCreateSubDeck(DeckEntity deck) =>
      deck.contentType != DeckContentType.card;
}

/// Not-found and read failures, told apart (UC-03 E1).
///
/// A deck deleted on another screen produces a `NotFoundFailure`, and that is
/// not an error the user caused — it gets its own gentle state with a way back,
/// not a retry button that will fail again forever.
class _DeckDetailError extends StatelessWidget {
  const _DeckDetailError({required this.error, required this.deckId});

  final Object error;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    final isMissing = error is NotFoundFailure;

    return MxContentShell(
      body: MxErrorState(
        title: isMissing
            ? context.l10n.deckDetailNotFoundTitle
            : context.l10n.deckDetailLoadErrorTitle,
        message: isMissing
            ? context.l10n.deckDetailNotFoundMessage
            : context.l10n.decksLoadErrorMessage,
        retryLabel: isMissing
            ? context.l10n.deckBackToDecksAction
            : context.l10n.retryAction,
        onRetry: isMissing
            ? () => context.goNamed(RouteNames.decks)
            : () => _retry(context),
      ),
    );
  }

  void _retry(BuildContext context) =>
      ProviderScope.containerOf(context).invalidate(deckDetailProvider(deckId));
}
