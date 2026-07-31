import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../../domain/models/deck_summary_model.dart';
import '../controllers/deck_list_controller.dart';
import '../controllers/deck_list_view_controller.dart';
import '../states/deck_list_view_state.dart';
import '../widgets/deck_actions_widget.dart';
import '../widgets/deck_level_error_widget.dart';
import '../widgets/deck_list_toolbar_widget.dart';
import '../widgets/deck_path_widget.dart';
import '../widgets/deck_tile_widget.dart';

/// Material's own FAB diameter. Named because the inset below is derived from it
/// and a bare 56 in that sum would be a number nobody could check.
const double _kFabDiameter = 56;

/// Space under the last card so the floating action never covers it.
///
/// The button is [_kFabDiameter] and sits [AppSpacing.lg] from the bottom edge;
/// the [AppSpacing.xl] on top of that is the gap between it and the card it would
/// otherwise touch. `MxContentShell` deliberately reserves nothing — a floating
/// action overlaps content by definition — so the list is what has to make room.
const double _kListBottomInset = _kFabDiameter + AppSpacing.lg + AppSpacing.xl;

/// The toolbar's two commands, bound to a `ref`.
///
/// Free functions rather than closures written inline in `build()`. `ref.read` is
/// the right call — choosing a filter is a command, and a `watch` inside a
/// callback would subscribe the widget to a value it is about to set — but
/// written inline it sits lexically inside `build`, where neither a reader nor
/// `memox.state_management.no_ref_read_in_build` can tell a deliberate command
/// from a missed subscription. Hoisting it makes the distinction structural.
ValueChanged<DeckListFilter> _selectFilter(WidgetRef ref) =>
    (DeckListFilter value) =>
        ref.read(deckListFilterChoiceProvider.notifier).select(value);

ValueChanged<DeckListSort> _selectSort(WidgetRef ref) =>
    (DeckListSort value) =>
        ref.read(deckListSortChoiceProvider.notifier).select(value);

/// One level of the deck tree (UC-06, UC-08).
///
/// **The same screen at every depth**, which is the point. [parentDeckId] null is
/// the app's home — every root deck; any other id is what is inside that deck.
/// Opening a deck does not change what the user is looking at, it changes which
/// level of the same tree, so it does not get a different screen.
///
/// It was two: `RootDeckListScreen` with counts, a filter and a sort, and
/// `DeckDetailScreen` with a plainer list of names. Neither difference was a
/// design decision — the second screen showed less because the read underneath it
/// returned less. Both are now one read, one card and one layout, and the
/// sameness is structural rather than something two files have to maintain.
///
/// What legitimately differs by level is small and all of it comes from the
/// snapshot: the title, whether the app bar carries an action menu for the deck
/// being looked inside, and which create action the floating button starts.
class DeckListScreen extends StatelessWidget {
  const DeckListScreen({this.parentDeckId, super.key});

  /// Null at the root of the tree.
  final String? parentDeckId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => MxAsyncView<DeckListSnapshot>(
        value: ref.watch(deckListProvider(parentDeckId)),
        loadingLabel: context.l10n.decksLoadingLabel,
        // The shell is inside each branch rather than around them, because the
        // title is only knowable in some of them — see [_titleBeforeData].
        loadingFrame: (loading) =>
            MxContentShell(title: _titleBeforeData(context), body: loading),
        data: (snapshot) => _DeckLevel(
          snapshot: snapshot,
          filter: ref.watch(deckListFilterChoiceProvider),
          sort: ref.watch(deckListSortChoiceProvider),
          onFilterChanged: _selectFilter(ref),
          onSortChanged: _selectSort(ref),
        ),
        error: (error, stackTrace) => DeckLevelErrorWidget(
          error: error,
          title: _titleBeforeData(context),
          isRootLevel: parentDeckId == null,
          // `invalidate`, not `refresh`: the retry wants a read from scratch and
          // nothing here needs the new value as a return. `refresh` would also
          // read it immediately, which the rebuild does anyway.
          onRetry: () => ref.invalidate(deckListProvider(parentDeckId)),
        ),
      ),
    );
  }

  /// The app-bar title for a level whose data has not arrived, or `null` when
  /// there is honestly none yet.
  ///
  /// The root level's title is a constant, so keeping it through loading and
  /// through a failed read means the screen does not appear to be replaced every
  /// time the data changes. A deck's title is its name, which is *in* the data —
  /// so a level inside a deck shows no bar until it has one, rather than a blank
  /// one or, worse, the previous deck's name.
  String? _titleBeforeData(BuildContext context) =>
      parentDeckId == null ? context.l10n.decksTitle : null;
}

/// A level that loaded: its chrome, and whatever the current view of it shows.
class _DeckLevel extends StatelessWidget {
  const _DeckLevel({
    required this.snapshot,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final DeckListSnapshot snapshot;
  final DeckListFilter filter;
  final DeckListSort sort;
  final ValueChanged<DeckListFilter> onFilterChanged;
  final ValueChanged<DeckListSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final parent = snapshot.parent;

    return MxContentShell(
      // The level names itself: the app at the root, the deck below it.
      title: parent?.name ?? context.l10n.decksTitle,
      actions: <Widget>[
        // Only when there is a deck to act on. The root level is not a deck, so
        // there is nothing to rename, move or delete from up here — the rows have
        // their own menus for that.
        if (parent != null)
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: context.l10n.deckActionsSemanticLabel,
            onPressed: () => showDeckActions(
              context,
              deck: parent,
              mayOfferReset: snapshot.mayOfferReset,
              // The deck being viewed is gone, so staying here would show a
              // not-found state the user did not ask for.
              onDeleted: () => context.goNamed(RouteNames.decks),
            ),
          ),
      ],
      // Create is a floating action at every level, and it is the same button
      // starting the level-appropriate flow. It disappears where the action does:
      // a `card` deck holds no sub-decks (BR-63), and a button that appears only
      // when it applies is honest where a permanently disabled one is not.
      floatingActionButton: _mayCreate(parent)
          ? FloatingActionButton(
              onPressed: () => _startCreate(context, parent),
              tooltip: _createLabel(context, parent),
              // The same glyph at every level. It was `add` at the root and
              // `create_new_folder` inside a deck, which made one action look
              // like two — and the thing being created is a deck in both cases.
              // What differs is only which parent it lands under, and the
              // tooltip and the semantic label already say that.
              child: Icon(
                Icons.add,
                semanticLabel: _createLabel(context, parent),
              ),
            )
          : null,
      // The shell's own padding is dropped: the list scrolls under the toolbar
      // and under the floating button, so it owns its gutters and its bottom
      // inset.
      padding: EdgeInsets.zero,
      // **The path is the shell's subheader, not the first row of the body.**
      // It was already pinned — a `Column` above an `Expanded` does not scroll —
      // so this changes nothing about whether it moves. What it changes is who
      // owns it: as a subheader it sits inside the app bar's own chrome, takes
      // the screen gutter from the shell instead of re-deriving it, and lands on
      // the correct side of the hairline that appears once the list scrolls
      // under. It is also where the design puts it.
      //
      // Above every body state, including the empty ones — "where am I" is most
      // worth answering on a level with nothing in it to recognise.
      subheader: DeckPathWidget.hasPath(snapshot)
          ? DeckPathWidget(snapshot: snapshot)
          : null,
      body: _body(context, parent),
    );
  }

  Widget _body(BuildContext context, DeckEntity? parent) {
    // A `card` deck shows no deck list at all — not an empty one (BR-63). The
    // card list itself belongs to M4.11; until then this states plainly that the
    // feature is not in the build rather than offering a control that does
    // nothing.
    if (parent != null && parent.contentType == DeckContentType.card) {
      return MxEmptyState(
        icon: Icons.style_outlined,
        title: context.l10n.deckDetailEmptyCardTitle,
        message: context.l10n.deckDetailEmptyCardMessage,
      );
    }

    // Nothing here at all. The toolbar is not built for this state on purpose: a
    // filter and a sort over nothing are two controls that visibly do nothing,
    // which is exactly the dead control this design refused to copy.
    if (snapshot.decks.isEmpty) return _emptyLevel(context, parent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          // `xl` below, not `lg`: this is the gap between two *sections* — the
          // controls and the thing they control — and a section break that used
          // the same number as the gap between two cards would make the toolbar
          // read as the first row of the list.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: DeckListToolbarWidget(
            filter: filter,
            sort: sort,
            onFilterChanged: onFilterChanged,
            onSortChanged: onSortChanged,
          ),
        ),
        Expanded(
          child: _DeckList(
            summaries: applyDeckListView(
              snapshot.decks,
              filter: filter,
              sort: sort,
            ),
            onClearFilter: () => onFilterChanged(DeckListFilter.all),
          ),
        ),
      ],
    );
  }

  /// The empty state, which differs by level and by content type because the next
  /// step does.
  ///
  /// An `unset` deck can still become either kind, so BR-61 requires both choices
  /// to be visible — the card one disabled, with the reason, rather than hidden.
  /// Hiding it would teach the user this deck can only hold decks, which is not
  /// true until they add one.
  Widget _emptyLevel(BuildContext context, DeckEntity? parent) {
    if (parent == null) {
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

    final isUnset = parent.contentType == DeckContentType.unset;

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
                showCreateSubDeckForm(context, parentDeckId: parent.id),
          ),
        ),
        if (isUnset)
          DeckNoticeWidget(
            message: context.l10n.deckCreateCardUnavailableMessage,
          ),
      ],
    );
  }

  /// Creating is allowed at the root always, and inside a deck unless it is fixed
  /// to cards (BR-59, BR-64, BR-66).
  ///
  /// Depth is not checked here: the repository refuses a create past level 10
  /// before writing anything (BR-55), and a UI that also guessed at depth would
  /// need the ancestry this screen does not load.
  static bool _mayCreate(DeckEntity? parent) =>
      parent == null || parent.contentType != DeckContentType.card;

  static String _createLabel(BuildContext context, DeckEntity? parent) =>
      parent == null
      ? context.l10n.deckCreateRootAction
      : context.l10n.deckCreateSubDeckAction;

  /// Returns the sheet's future rather than dropping it, so a caller that wants
  /// to wait for the form to close can. Nothing here awaits it: the list is
  /// driven by the repository's stream, so the new deck arrives on its own.
  static Future<void> _startCreate(BuildContext context, DeckEntity? parent) {
    if (parent == null) return showCreateRootDeckForm(context);

    return showCreateSubDeckForm(context, parentDeckId: parent.id);
  }
}

/// The visible decks, or the note that the filter matched none of them.
///
/// Empty here means exactly one thing: this level has decks, and the due-only
/// filter matched none of them. The "nothing here at all" cases never reach this
/// widget — `_DeckLevel` answers them before the toolbar is even built, because
/// they need different words and different actions.
class _DeckList extends StatelessWidget {
  const _DeckList({required this.summaries, required this.onClearFilter});

  final List<DeckSummary> summaries;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return MxEmptyState(
        // `MxEmptyState`'s default check-mark, left unset on purpose: nothing due
        // means the reviews are finished, which is the one state in this feature
        // where that icon tells the truth.
        title: context.l10n.decksNoDueTitle,
        message: context.l10n.decksNoDueMessage,
        actionLabel: context.l10n.decksShowAllAction,
        onAction: onClearFilter,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        _kListBottomInset,
      ),
      itemCount: summaries.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final summary = summaries[index];

        return DeckTileWidget(
          summary: summary,
          // By name, with the id as a path parameter. The literal path would work
          // today and break silently the first time the route moves.
          onTap: () => context.goNamed(
            RouteNames.deckDetail,
            pathParameters: <String, String>{
              RoutePathParams.deckId: summary.deck.id,
            },
          ),
          onActions: () => showDeckActions(
            context,
            deck: summary.deck,
            // Whether a deck may be reset is a question about its own children,
            // answered on its own level where they are known. Offering it from
            // the level above would mean guessing.
            mayOfferReset: false,
            // Deleting from a list leaves the user on that list; there is nowhere
            // to navigate back from.
            onDeleted: () {},
          ),
        );
      },
    );
  }
}
