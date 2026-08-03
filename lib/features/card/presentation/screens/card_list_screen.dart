import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../../../shared/widgets/mx_text_button.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_item_model.dart';
import '../../domain/models/deck_context_model.dart';
import '../controllers/card_list_controller.dart';
import '../controllers/card_list_filter_controller.dart';
import '../controllers/card_list_now_controller.dart';
import '../controllers/card_list_window_controller.dart';
import '../controllers/deck_context_controller.dart';
import '../widgets/items/card_tile_widget.dart';
import '../widgets/sections/card_breadcrumb_widget.dart';
import '../widgets/sections/card_filter_bar_widget.dart';
import '../widgets/sections/card_progress_panel_widget.dart';
import '../widgets/support/card_sort_control_widget.dart';

/// Grows the read window by one step (W1b).
///
/// A free function, not a closure in `build()`: `ref.read` inside a build reads
/// without subscribing and is almost always the bug the guard forbids, so a
/// command is written where the guard can tell it apart — the same shape
/// `deck_list_toolbar_widget.dart` uses for its filter and sort.
void _growWindow(WidgetRef ref, String deckId) =>
    ref.read(cardListWindowProvider(deckId).notifier).grow();

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

    return MxContentShell(
      title: deckContext?.deckName ?? context.l10n.cardListTitle,
      subheader: _subheader(deckId, deckContext, deckTotal),
      // The add action lives on the app bar, not a floating button — the same
      // place the deck list puts its create action, so "the primary action" sits
      // in one spot across the app. A FAB would also carry Material's default
      // `primaryContainer`, a second emphasis tone for the same "add" the deck
      // screen renders in `primary`; one app-bar icon keeps that consistent.
      actions: <Widget>[
        MxIconButton(
          icon: Icons.add,
          semanticLabel: context.l10n.cardListNewAction,
          tooltip: context.l10n.cardListNewAction,
          onPressed: () => _openEditor(context),
        ),
      ],
      body: MxAsyncView<List<CardListItemModel>>(
        value: cards,
        loadingLabel: context.l10n.cardListLoadingLabel,
        error: (_, _) => _Error(message: context.l10n.cardListError),
        data: (list) => list.isEmpty
            ? _empty(context, filter)
            : _Loaded(
                deckId: deckId,
                items: list,
                // The count trails the window by at most a frame (C3); until its
                // first value arrives the window length is the honest floor.
                total: count.value ?? list.length,
                onOpen: (item) => _openEditor(context, cardId: item.card.id),
              ),
      ),
    );
  }

  // The pinned strip: the breadcrumb (W1) above the filter pills (D3). The
  // breadcrumb is drawn as soon as the deck context lands, even on an empty deck
  // — "where am I" is most worth answering on a level with nothing to recognise,
  // the same rule the deck screen follows. The pills wait for the deck to hold
  // cards. When neither is ready there is no strip at all.
  Widget? _subheader(
    String deckId,
    DeckContextModel? deckContext,
    int deckTotal,
  ) {
    final crumb = deckContext == null
        ? null
        : CardBreadcrumbWidget(deckContext: deckContext);
    final pills = deckTotal > 0 ? CardFilterBarWidget(deckId: deckId) : null;
    if (crumb == null && pills == null) return null;
    if (pills == null) return crumb;
    if (crumb == null) return pills;

    return Column(
      // Stretch, not start: both strips scroll horizontally, so they take the
      // gutter-bounded width and scroll within it rather than sizing to content.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[crumb, pills],
    );
  }

  // An empty result means "add your first card" only when no filter is on;
  // otherwise it means the filter matched nothing (D3).
  Widget _empty(BuildContext context, CardListFilter filter) =>
      filter == CardListFilter.all
      ? _Empty(onAdd: () => _openEditor(context))
      : const _NoMatch();
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.deckId,
    required this.items,
    required this.total,
    required this.onOpen,
  });

  final String deckId;
  final List<CardListItemModel> items;
  final int total;
  final void Function(CardListItemModel item) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMore = items.length < total;
    // One "now" for the whole list, from the composition root — every badge is
    // measured against the same instant, and the tile never reads the clock.
    final now = ref.watch(cardListNowProvider);

    // Two header rows scroll above the cards: the progress panel (D5) and the
    // "showing N of M" line. The filter pills pin in the subheader instead, so
    // they stay reachable while the panel scrolls away.
    const headerCount = 2;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: items.length + headerCount + 1,
      // A plain gap between everything: each card row is now its own bordered
      // surface (MxCard, like the deck list), so the separation is the space
      // between cards, not a hairline drawn through one dense block.
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return CardProgressPanelWidget(deckId: deckId);
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.cardListShowing(items.length, total),
                    style: context.texts.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                CardSortControlWidget(deckId: deckId),
              ],
            ),
          );
        }
        final cardIndex = index - headerCount;
        if (cardIndex < items.length) {
          final item = items[cardIndex];
          return CardTileWidget(
            item: item,
            now: now,
            onTap: () => onOpen(item),
          );
        }

        return _Tail(
          deckId: deckId,
          shown: items.length,
          total: total,
          hasMore: hasMore,
        );
      },
    );
  }
}

/// The bottom of the window: a load-more button while rows remain, or the line
/// that says the whole deck is on screen (W1b).
class _Tail extends ConsumerWidget {
  const _Tail({
    required this.deckId,
    required this.shown,
    required this.total,
    required this.hasMore,
  });

  final String deckId;
  final int shown;
  final int total;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Center(
          child: Text(
            context.l10n.cardListAllShown(total),
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Center(
        child: MxTextButton(
          label: context.l10n.cardListLoadMore(kCardWindowSize),
          onPressed: () => _growWindow(ref, deckId),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    // The empty state carries its own "add first card" CTA; the app-bar add
    // action stays too, so there is one consistent place to add whatever the
    // body shows — the same pairing the deck list's empty level uses.
    return MxEmptyState(
      icon: Icons.style_outlined,
      title: context.l10n.cardListEmptyTitle,
      message: context.l10n.cardListEmptyMessage,
      actionLabel: context.l10n.cardListEmptyAction,
      onAction: onAdd,
    );
  }
}

/// The filtered-empty state: the deck has cards, this filter matched none (D3).
class _NoMatch extends StatelessWidget {
  const _NoMatch();

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.filter_list_off,
      title: context.l10n.cardListNoMatchTitle,
      message: context.l10n.cardListNoMatchMessage,
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
