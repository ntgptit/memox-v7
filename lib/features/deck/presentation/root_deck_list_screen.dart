import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/mx_content_shell.dart';
import '../../../shared/widgets/mx_empty_state.dart';
import '../../../shared/widgets/mx_error_state.dart';
import '../../../shared/widgets/mx_icon_button.dart';
import '../../../shared/widgets/mx_loading_state.dart';
import '../domain/root_deck_summary_model.dart';
import 'deck_actions_widget.dart';
import 'deck_tile_widget.dart';
import 'root_decks_controller.dart';

/// The app's home: every root deck with its progress (UC-06).
///
/// Composition only. It picks copy, maps the stream's three cases to the shared
/// components, and hands taps to `showDeckActions` or the router. The counts
/// beside each deck are computed by one SQL aggregate — deriving them here per
/// row would be the N+1 UC-06 names, and would also let the badge disagree with
/// the session it is meant to predict.
class RootDeckListScreen extends StatelessWidget {
  const RootDeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      title: context.l10n.decksTitle,
      actions: <Widget>[
        // Also reachable from the empty state. Two entry points because the
        // empty state's button is the only thing on an empty screen, while the
        // app-bar action is what a user with twenty decks reaches for.
        MxIconButton(
          icon: Icons.add,
          semanticLabel: context.l10n.deckCreateRootAction,
          onPressed: () => showCreateRootDeckForm(context),
        ),
      ],
      body: Consumer(
        builder: (context, ref, child) => ref
            .watch(rootDeckSummariesProvider)
            .when(
              loading: () => MxLoadingState(
                semanticsLabel: context.l10n.decksLoadingLabel,
              ),
              data: (summaries) => _RootDeckList(summaries: summaries),
              // The failure itself never reaches the screen. A Drift message
              // would tell the user nothing they can act on, and can carry a
              // deck name.
              error: (error, stackTrace) => MxErrorState(
                title: context.l10n.decksLoadErrorTitle,
                message: context.l10n.decksLoadErrorMessage,
                retryLabel: context.l10n.retryAction,
                onRetry: () => ref.invalidate(rootDeckSummariesProvider),
              ),
            ),
      ),
    );
  }
}

/// The loaded list, and the empty state that is the same load with no rows.
///
/// One widget for both because they are one state of the stream, not two: an
/// empty result is a successful read (BR-29). Splitting them at the `when` would
/// make "loaded" mean "loaded and non-empty", which is the shape that later
/// grows a spurious third branch.
class _RootDeckList extends StatelessWidget {
  const _RootDeckList({required this.summaries});

  final List<RootDeckSummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return MxEmptyState(
        // Not the default check-mark: that icon says "you have finished
        // everything", which is the opposite of what an account with no decks
        // means.
        icon: Icons.folder_outlined,
        title: context.l10n.decksEmptyTitle,
        message: context.l10n.decksEmptyMessage,
        actionLabel: context.l10n.deckCreateRootAction,
        onAction: () => showCreateRootDeckForm(context),
      );
    }

    return ListView.builder(
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];

        return DeckTileWidget(
          summary: summary,
          // By name, with the id as a path parameter. The literal path would
          // work today and break silently the first time the route moves.
          onTap: () => context.goNamed(
            RouteNames.deckDetail,
            pathParameters: <String, String>{
              RoutePathParams.deckId: summary.deck.id,
            },
          ),
          onActions: () => showDeckActions(
            context,
            deck: summary.deck,
            // A root's content type is invariant (BR-58), so reset is never
            // offered here.
            mayOfferReset: false,
            // Deleting from the list leaves the user on the list; there is
            // nowhere to navigate back from.
            onDeleted: () {},
          ),
        );
      },
    );
  }
}
