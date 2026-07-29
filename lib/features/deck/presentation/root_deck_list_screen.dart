import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/mx_content_shell.dart';
import '../../../shared/widgets/mx_empty_state.dart';
import '../../../shared/widgets/mx_error_state.dart';
import '../../../shared/widgets/mx_list_tile.dart';
import '../../../shared/widgets/mx_loading_state.dart';
import '../domain/deck_entity.dart';
import 'root_decks_controller.dart';

/// The app's home: every root deck, read from Drift through the repository
/// (UC-06).
///
/// Composition only. It picks the copy for each state and hands it to the
/// shared components; it holds no query, no list building beyond the mapping,
/// and no state of its own. Anything it computed in `build()` would be
/// recomputed on every stream emission and could not be tested without pumping
/// a widget.
///
/// **Deliberately absent, and each for the same reason** — the flow behind it
/// does not exist yet, and a control that leads nowhere is worse than no
/// control:
///
/// * no create-deck action (UC-02 lands in a later M4.10 slice),
/// * no tap target on a row (deck detail is not built),
/// * no card counts or due counts — `watchRootDecks()` returns decks, and
///   deriving those numbers per row in Dart is the N+1 that UC-06 names by
///   name. They arrive with the aggregate query, not before.
///
/// **A `Consumer` around the body, not a `ConsumerWidget` around the screen.**
/// Two reasons, pointing the same way.
///
/// The design one: the app-bar title is a constant, so rebuilding the whole
/// shell on every stream emission repaints an AppBar that cannot have changed.
/// Scoping the watch to the part that actually depends on it is the rebuild
/// discipline the rest of this codebase is held to.
///
/// The mechanical one, stated because it influenced the choice rather than
/// discovered afterwards: the project guard's `no_generated_ref_subclass` rule
/// matches the two-argument `build` signature that `ConsumerWidget` requires,
/// reading Riverpod 3's widget-side ref type as if it were one of Riverpod 2's
/// generated per-provider `Ref` subclasses. It is a false positive for every
/// `ConsumerWidget` anyone writes in this project, and the fix belongs in the
/// guard repository, which this repo may not edit. Nothing here depends on it
/// staying broken.
class RootDeckListScreen extends StatelessWidget {
  const RootDeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      title: context.l10n.decksTitle,
      body: Consumer(
        builder: (context, ref, child) => ref
            .watch(rootDecksProvider)
            .when(
              loading: () => MxLoadingState(
                semanticsLabel: context.l10n.decksLoadingLabel,
              ),
              data: (decks) => _RootDeckList(decks: decks),
              // The failure itself never reaches the screen. A Drift message
              // would tell the user nothing they can act on, and can carry a
              // deck name.
              error: (error, stackTrace) => MxErrorState(
                title: context.l10n.decksLoadErrorTitle,
                message: context.l10n.decksLoadErrorMessage,
                retryLabel: context.l10n.retryAction,
                onRetry: () => ref.invalidate(rootDecksProvider),
              ),
            ),
      ),
    );
  }
}

/// The loaded list, and the empty state that is the same load with no rows.
///
/// One widget for both because they are one state of the stream, not two: an
/// empty result is a successful read. Splitting them at the `when` would put
/// `decks.isEmpty` in the screen and make "loaded" mean "loaded and non-empty",
/// which is the shape that later grows a spurious third branch.
class _RootDeckList extends StatelessWidget {
  const _RootDeckList({required this.decks});

  final List<DeckEntity> decks;

  @override
  Widget build(BuildContext context) {
    if (decks.isEmpty) {
      return MxEmptyState(
        // Not the default check-mark: that icon says "you have finished
        // everything", which is the opposite of what an account with no decks
        // means.
        icon: Icons.folder_outlined,
        title: context.l10n.decksEmptyTitle,
        message: context.l10n.decksEmptyMessage,
      );
    }

    return ListView.builder(
      itemCount: decks.length,
      itemBuilder: (context, index) => MxListTile(title: decks[index].name),
    );
  }
}
