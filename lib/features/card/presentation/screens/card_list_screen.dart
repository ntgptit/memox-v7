import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/foundations/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_fab.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../../../shared/widgets/mx_reading_column.dart';
import '../../../../shared/widgets/mx_search_field.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_item_model.dart';
import '../../domain/models/tag_filter_model.dart';
import '../controllers/card_bulk_controller.dart';
import '../controllers/card_list_controller.dart';
import '../controllers/card_list_filter_controller.dart';
import '../controllers/card_list_tag_filter_controller.dart';
import '../controllers/card_selection_controller.dart';
import '../controllers/deck_context_controller.dart';
import '../states/card_selection_state.dart';
import '../widgets/overlays/card_bulk_overlays_widget.dart';
import '../widgets/overlays/card_export_sheet_widget.dart';
import '../widgets/overlays/card_list_menu_widget.dart';
import '../widgets/sections/card_breadcrumb_widget.dart';
import '../widgets/sections/card_filter_bar_widget.dart';
import '../widgets/sections/card_list_body_widget.dart';
import '../widgets/sections/card_selection_bar_widget.dart';

/// Types into the search field (S1). A free function for the same reason.
void _updateSearch(WidgetRef ref, String deckId, String query) =>
    ref.read(cardListSearchQueryProvider(deckId).notifier).update(query);

/// Enters selection mode from the app-bar action, and leaves it from Back
/// (UC-04 A6). Free functions for the same reason `_updateSearch` is one: a
/// `ref.read` written inline in `build()` is indistinguishable — to the guard
/// and to a reader — from the unsubscribed read that silently stops a widget
/// updating.
void _beginSelection(WidgetRef ref, String deckId) =>
    ref.read(cardSelectionProvider(deckId).notifier).begin();

void _clearSelection(WidgetRef ref, String deckId) =>
    ref.read(cardSelectionProvider(deckId).notifier).clear();

/// Drops every selected tag (UC-18 A7). A free function for the same reason as
/// its neighbours above.
void _clearTagFilter(WidgetRef ref, String deckId) =>
    ref.read(cardListTagFilterProvider(deckId).notifier).apply(TagFilter.none);

/// Re-subscribes both reads that render the card-list frame.
///
/// The list and total are separate statements, so retrying only the failed list
/// could leave the next frame paired with a stale count.
void _retryCardList(WidgetRef ref, String deckId) {
  ref.invalidate(cardListProvider(deckId));
  ref.invalidate(cardCountProvider(deckId));
}

/// The card list for a card-type deck (UC-04, W1).
///
/// **Reached by redirect, not built by the deck screen.** A `card` deck's detail
/// route redirects here (`_cardDeckRedirect` in `app_router.dart`), so the card
/// feature owns its own screen and the deck feature never imports it (AD-13). It
/// still sits inside the Decks branch, so the bottom bar stays and Back returns
/// to the deck tree.
///
/// It draws the deck-name title and its ancestor breadcrumb (W1), the progress
/// panel (D5), the filtered list and its counts (D3), the window's load-more tail
/// and the four-part card rows. The title and breadcrumb come from one card-side
/// read of deck context — `watchDeckContext`, the same seam `createCard` uses —
/// so a rename lands on both in the same frame and the deck feature's Dart is
/// never imported (AD-13).
class CardListScreen extends ConsumerWidget {
  const CardListScreen({required this.deckId, super.key});

  final String deckId;

  void _openEditor(BuildContext context, {String? cardId}) {
    // Create and edit are two named routes; the card id picks which, and rides
    // in the path only for edit.
    if (cardId == null) {
      context.goNamed(
        RouteNames.cardEditor,
        pathParameters: <String, String>{RoutePathParams.deckId: deckId},
      );
      return;
    }
    context.goNamed(
      RouteNames.cardEditorEdit,
      pathParameters: <String, String>{
        RoutePathParams.deckId: deckId,
        RoutePathParams.cardId: cardId,
      },
    );
  }

  /// What a tap on a row means outside selection mode (BR-246).
  ///
  /// **It used to be [_openEditor].** A tap is the most-used gesture in the
  /// list, so it has to lead to the reading surface rather than into a form
  /// over real content; editing is one explicit action away, on the detail
  /// screen's app bar.
  void _openDetail(BuildContext context, String cardId) => context.goNamed(
    RouteNames.cardDetail,
    pathParameters: <String, String>{
      RoutePathParams.deckId: deckId,
      RoutePathParams.cardId: cardId,
    },
  );

  /// The bulk entry (UC-10): manual create stays the small-volume path (D4),
  /// import is where a whole file goes. Pushed, not gone-to: the wizard sits
  /// on the root navigator above this screen, and Cancel must return here by
  /// popping — a `go` would rebuild the stack from the URL and forget where
  /// the user came from.
  void _openImport(BuildContext context) => context.pushNamed(
    RouteNames.cardImport,
    pathParameters: <String, String>{RoutePathParams.deckId: deckId},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardListProvider(deckId));
    final count = ref.watch(cardCountProvider(deckId));
    final filter = ref.watch(cardListFilterSelectionProvider(deckId));
    // The pills appear only once the deck has cards — an empty deck shows the
    // add-first state, not a bar of zeroes (W2/W3).
    final deckTotal = ref.watch(cardAllCountProvider(deckId)).value ?? 0;
    // The deck's name and breadcrumb (W1). Null until the read lands or if the
    // deck has vanished — the title then falls back to the generic label.
    final deckContext = ref.watch(deckContextProvider(deckId)).value;
    final selection = ref.watch(cardSelectionProvider(deckId));
    // Any bulk command in flight disables the bar. Four states rather than
    // one flag on the selection: the spinner belongs to the write that is
    // running, not to the set of rows it runs over.
    final isBulkBusy =
        ref.watch(moveCardsProvider(deckId)).isSubmitting ||
        ref.watch(deleteCardsProvider(deckId)).isSubmitting ||
        ref.watch(setCardsFlagProvider(deckId)).isSubmitting ||
        ref.watch(addTagToCardsProvider(deckId)).isSubmitting;

    return MxContentShell(
      // **While selecting, the bar names the selection rather than the place**
      // (SC-C4-12) — the shape `trash_screen.dart` already uses: the count as
      // the title, one ✕ in the leading slot, and no path under it. A path
      // below a count answers a question nobody asked, and a `chevron_left`
      // sitting under a ✕ would be the second dismiss-looking control this
      // change exists to remove.
      title: selection.isSelecting
          ? _selectionTitle(context, selection)
          : deckContext?.deckName ?? context.l10n.cardListTitle,
      // **One control leaves selection, not two.** A non-null leading turns
      // `automaticallyImplyLeading` off (`mx_content_shell.dart`), so the
      // platform arrow that used to sit beside the band's own ✕ — both meaning
      // "stop selecting" — is gone and the ✕ is the one control. Back still
      // leaves selection, through the `PopScope` below: a gesture, not a
      // second affordance.
      leading: selection.isSelecting
          ? MxIconButton(
              icon: Icons.close,
              semanticLabel: context.l10n.cardSelectionCloseLabel,
              onPressed: () => _clearSelection(ref, deckId),
            )
          : null,
      // **The path is a line of the title, not a band below it** (SC-C4-06,
      // SC-C4-10). It was a 48dp subheader strip with no chevron and the
      // deck's own name repeated at its end, one tap from a deck level that
      // draws a 32dp header line with a chevron and no repeat — four
      // differences answering one question. The deck level's is the reviewed
      // composition (owner review 2026-08-20/21, with the ~60dp measurement
      // recorded at `deck_list_screen.dart`), so this side adopts it.
      //
      // Nothing is reserved before the read lands: a subline tells the shell
      // the title owns the way back, so reserving one inside a deck would buy
      // an even bar and pay for it with a back-less one — the same call
      // `deck_list_screen.dart._sublineBeforeData` makes for the same reason.
      titleSubline: deckContext == null || selection.isSelecting
          ? null
          : CardBreadcrumbWidget(deckContext: deckContext),
      subheader: _subheader(
        ref,
        context,
        deckTotal,
        isSelecting: selection.isSelecting,
      ),
      // **The shell's own padding is dropped, exactly as the deck list drops
      // it.** Every branch below owns its gutters — the loaded list through its
      // `ListView` padding, the empty and error states through `MxEmptyState` /
      // `MxErrorState`'s own `xl` — so leaving the shell's `lg` on as well
      // padded each of them twice: the progress panel and the card rows sat at
      // 32 from the screen edge while the search field and the filter pills
      // above them, which take the gutter from the shell's default rather than
      // from this value, sat at 16. Two gutters on one screen, and neither
      // matched the deck list's 16 next door.
      padding: EdgeInsets.zero,
      // **Create floats here too, matching the deck list** (owner decision,
      // 2026-09-06). The comment this replaces claimed the app bar was "the
      // same place the deck list puts its create action"; that stopped being
      // true when the deck list's create floated again (M4.10ag reversal, owner
      // review 2026-08-20), so a user drilling deck level -> card list watched
      // the primary create verb change position, weight and colour tier one tap
      // apart. Two grammars for one action, and only one of them can be right.
      // See [floatingActionButton] below for the button itself.
      actions: <Widget>[
        // A visible way into selection mode. Long-press is the platform
        // gesture and it has no affordance at all, so a user who does not
        // already know it would never find bulk management (UC-04 A6).
        if (deckTotal > 0 && !selection.isSelecting)
          MxIconButton(
            icon: Icons.checklist,
            semanticLabel: context.l10n.cardSelectAction,
            tooltip: context.l10n.cardSelectAction,
            onPressed: () => _beginSelection(ref, deckId),
          ),
        // The overflow — import, export, tag catalog. Hidden during selection
        // for the same reason the floating create is: every item leaves the
        // screen, which would abandon the selection.
        if (!selection.isSelecting)
          CardListMenuWidget(
            deckId: deckId,
            deckTotal: deckTotal,
            onImport: () => _openImport(context),
          ),
      ],
      // The create verb, in the deck list's grammar (see [actions] above).
      // Labelled, because a bare glyph does not say what it creates — the label
      // is the tooltip and the name a screen reader announces.
      //
      // Absent mid-selection, which is the same rule the app-bar glyph carried:
      // creating a card leaves the screen, and that would abandon a selection
      // the user did not ask to lose.
      //
      // No clearance work is needed here: passing this makes the shell tell its
      // body a floating action exists, and `card_list_body_widget.dart` already
      // takes its end inset from `mxScrollEndInsetOf`.
      floatingActionButton: selection.isSelecting
          ? null
          : MxFab(
              icon: Icons.add,
              label: context.l10n.cardListNewAction,
              onPressed: () => _openEditor(context),
            ),
      // Back leaves selection first (UC-04 A6): a user who selected twenty
      // cards and pressed Back meant "stop selecting", not "leave the deck".
      // A card row is a front, a back and a chevron. Stretched across a
      // landscape phone the chevron ends up nowhere near the text it opens.
      body: Align(
        alignment: Alignment.topCenter,
        child: MxReadingColumn(
          child: PopScope<Object?>(
            canPop: !selection.isSelecting,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _clearSelection(ref, deckId);
            },
            child: Column(
              children: <Widget>[
                if (selection.isSelecting)
                  CardSelectionBarWidget(
                    deckId: deckId,
                    isBusy: isBulkBusy,
                    onMove: () => bulkMove(context, ref, deckId),
                    onAddTag: () => bulkAddTag(context, ref, deckId),
                    onFlag: () =>
                        bulkFlag(context, ref, deckId, isFlagged: true),
                    onUnflag: () =>
                        bulkFlag(context, ref, deckId, isFlagged: false),
                    // Read-only, so it is not routed through `runBulk`: that
                    // helper clears the selection on success, which is exactly
                    // what an export must not do (BR-178).
                    onExport: () => exportSelectedCards(context, ref, deckId),
                    onDelete: () => bulkDelete(context, ref, deckId),
                  ),
                Expanded(
                  child: MxAsyncView<List<CardListItemModel>>(
                    value: cards,
                    loadingLabel: context.l10n.cardListLoadingLabel,
                    error: (_, _) => MxErrorState(
                      title: context.l10n.unexpectedErrorTitle,
                      message: context.l10n.cardListError,
                      retryLabel: context.l10n.retryAction,
                      onRetry: () => _retryCardList(ref, deckId),
                    ),
                    data: (list) => list.isEmpty
                        ? _empty(
                            context,
                            ref,
                            filter,
                            ref.watch(cardListSearchQueryProvider(deckId)),
                            // A tag filter narrows the list exactly as the pills
                            // do, so an empty result under one is "nothing
                            // matched", never "this deck is empty" (M4.14 W7).
                            // Without this the screen offers "add your first card"
                            // to a user looking at a deck of 214.
                            isTagFiltered: ref
                                .watch(cardListTagFilterProvider(deckId))
                                .isActive,
                          )
                        : CardListBodyWidget(
                            deckId: deckId,
                            items: list,
                            // The count trails the window by at most a frame (C3);
                            // until its first value arrives the window length is the
                            // honest floor.
                            total: count.value ?? list.length,
                            onOpen: (item) =>
                                _openDetail(context, item.card.id),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The count, in the words the selection band used to carry (BR-167). One
  // label for one fact: drawing it here and again on the band would be two
  // numbers free to disagree about the set the actions run over.
  String _selectionTitle(BuildContext context, CardSelectionState selection) =>
      selection.isAllMatching
      ? context.l10n.cardSelectionAllLabel(selection.selectedCount)
      : context.l10n.cardSelectionCountLabel(selection.selectedCount);

  // The pinned strip: the search field over the filter pills (D3). Both narrow
  // the list, so they arrive together once the deck has anything to narrow;
  // on an empty deck there is no strip at all. The breadcrumb used to lead this
  // band and is a line of the title now (SC-C4-06, SC-C4-10).
  //
  // **Mounted but inert while selecting**, which is the rule `trash_screen.dart`
  // states for its own filter band. Removing it would drop ~60dp of chrome on
  // the frame the long press lands, moving the row out from under the finger;
  // leaving it live lets the narrowing change under a "select all matching"
  // that resolves against exactly that narrowing.
  Widget? _subheader(
    WidgetRef ref,
    BuildContext context,
    int deckTotal, {
    required bool isSelecting,
  }) {
    if (deckTotal <= 0) return null;

    return Column(
      // Stretch, not start: the strips scroll horizontally, so they take the
      // gutter-bounded width and scroll within it rather than sizing to content.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
        // **Inert at the call site, not through the field's own API.**
        // `MxSearchField.onChanged` is required and non-nullable, and V1
        // freezes the public contract of every shared primitive — contract 6
        // in `docs/design-system/v1-freeze.md`. So the way to stop the field
        // answering is to take the pointer and the focus away from it: the
        // focus too, because a field that already held it when the long press
        // landed would otherwise keep the keyboard and keep typing into a
        // query the selection is resolved against. No pixel moves either way.
        ExcludeFocus(
          excluding: isSelecting,
          child: IgnorePointer(
            ignoring: isSelecting,
            child: MxSearchField(
              value: ref.watch(cardListSearchQueryProvider(deckId)),
              onChanged: (query) => _updateSearch(ref, deckId, query),
              hintText: context.l10n.cardSearchHint,
              semanticLabel: context.l10n.cardSearchLabel,
              clearSemanticLabel: context.l10n.cardSearchClearLabel,
            ),
          ),
        ),
        // The pills say so themselves: a null callback keeps the 48dp box and
        // the selected pill's paint while making a filter change unable to
        // orphan the selection.
        CardFilterBarWidget(deckId: deckId, isEnabled: !isSelecting),
      ],
    );
  }

  // An empty result means "add your first card" only when no filter is on;
  // otherwise it means the filter matched nothing (D3).
  Widget _empty(
    BuildContext context,
    WidgetRef ref,
    CardListFilter filter,
    String search, {
    required bool isTagFiltered,
  }) {
    // A search that matched nothing names the term; a filter that matched
    // nothing says so; only a genuinely empty deck offers "add your first card".
    if (search.trim().isNotEmpty) return _NoSearchMatch(query: search.trim());
    // The tag predicate gets a way out on the face itself (UC-18 A7): the four
    // state pills are always visible so `All` is one tap away, but the tag
    // selection lives behind a sheet, and without this the only exit is to
    // reopen it and press Clear inside. The state filters keep the plain face —
    // adding a second action to it would be a control that does nothing.
    if (isTagFiltered) {
      return _NoMatch(onClearTags: () => _clearTagFilter(ref, deckId));
    }
    if (filter != CardListFilter.all) return const _NoMatch();

    return _Empty(
      onAdd: () => _openEditor(context),
      onImport: () => _openImport(context),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd, required this.onImport});

  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    // The empty state carries its own "add first card" CTA; the floating add
    // action stays too, so there is one consistent place to add whatever the
    // body shows — the same pairing the deck list's empty level uses. Import
    // rides along as the secondary way in (M4.12 W6): a deep link or a stale
    // route can land here, and a whole file should not have to start from a
    // hand-typed first card.
    return MxEmptyState(
      icon: Icons.style_outlined,
      title: context.l10n.cardListEmptyTitle,
      message: context.l10n.cardListEmptyMessage,
      actionLabel: context.l10n.cardListEmptyAction,
      onAction: onAdd,
      secondaryActionLabel: context.l10n.cardImportEntryAction,
      onSecondaryAction: onImport,
    );
  }
}

/// The searched-empty state: the deck has cards, the term matched none (S1).
class _NoSearchMatch extends StatelessWidget {
  const _NoSearchMatch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.search_off,
      title: context.l10n.cardSearchEmptyTitle(query),
      message: context.l10n.cardSearchEmptyMessage,
    );
  }
}

/// The filtered-empty state: the deck has cards, this filter matched none (D3).
///
/// [onClearTags] is present only when a tag selection is what emptied the list
/// (UC-18 A7, M4.14 W7). A state pill leaves no such dead end — `All` is on
/// screen beside it — so that face keeps the plain message and no action.
class _NoMatch extends StatelessWidget {
  const _NoMatch({this.onClearTags});

  final VoidCallback? onClearTags;

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.filter_list_off,
      title: context.l10n.cardListNoMatchTitle,
      message: context.l10n.cardListNoMatchMessage,
      // Named for what it clears. The sheet's own `Clear` is a different key:
      // there a selection is on screen to clear, here it is not.
      actionLabel: onClearTags == null
          ? null
          : context.l10n.tagFilterClearAllAction,
      onAction: onClearTags,
    );
  }
}
