import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../domain/failures/card_not_found_failure.dart';
import '../../domain/models/card_detail_model.dart';
import '../controllers/card_detail_controller.dart';
import '../controllers/card_history_controller.dart';
import '../widgets/sections/card_detail_summary_widget.dart';
import '../widgets/sections/card_detail_state_widget.dart';
import '../widgets/sections/card_history_section_widget.dart';

/// Re-subscribes the content read after a failure (UC-19 E3).
///
/// A free function, not a closure in `build()`: a `ref.read` written inline
/// there is indistinguishable — to the guard and to a reader — from the
/// unsubscribed read that silently stops a widget updating.
void _retryDetail(WidgetRef ref, String cardId) =>
    ref.invalidate(cardDetailProvider(cardId));

/// Paging is fire-and-forget from the widget's side: the result it produces is
/// the controller's state, which the body is already watching, so there is
/// nothing here to await and `unawaited` says so rather than letting a dropped
/// future look accidental.
void _loadMoreHistory(WidgetRef ref, String cardId) =>
    unawaited(ref.read(cardHistoryProvider(cardId).notifier).loadMore());

/// One card, read-only, with its study history (UC-19, M4.15).
///
/// **Reading is what a tap now means** (BR-246). Before this screen existed a
/// tap on a card row opened the editor, so the most common gesture in the list
/// led straight into a form over real content. Editing is still one tap away —
/// it is the app-bar action — but it is a tap the user chose.
///
/// **Nothing on this screen writes** (BR-239). There is no controller command
/// here beyond paging, the detail repository has no write method, and opening
/// or scrolling this screen does not mark the card learned. Reading a card is
/// not studying it.
///
/// **Two reads, deliberately** (BR-244). Content, tags and the current schedule
/// arrive together as one snapshot, because the screen shows them in one frame.
/// History is separate: it accumulates page by page and has a lifecycle of its
/// own, so an edit that changes the top of the screen must leave the timeline
/// alone — a property that holds only while they are two reads.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    required this.deckId,
    required this.cardId,
    super.key,
  });

  /// The deck the card sits in — carried so `Edit` and the not-found recovery
  /// can name the routes they go to, both of which are nested under it.
  final String deckId;
  final String cardId;

  /// Opens the editor **on top of** this screen (UC-19 A1).
  ///
  /// **Pushed, not gone-to, and the difference is where Save lands.** The
  /// editor route (`:cardId/edit`) is a *sibling* of this one (`:cardId`), not
  /// a child, so `goNamed` rebuilds the stack from the URL as
  /// `[…, cardList, editor]` — with the detail screen gone from it. The editor
  /// finishes by popping, so the user would come back to the list rather than
  /// to the card they were reading. A push keeps this screen underneath, which
  /// is also what makes the live `watchCardDetail` stream worth having: the
  /// edited content is already on screen when the editor pops.
  void _openEditor(BuildContext context) => context.pushNamed(
    RouteNames.cardEditorEdit,
    pathParameters: <String, String>{
      RoutePathParams.deckId: deckId,
      RoutePathParams.cardId: cardId,
    },
  );

  void _openCardList(BuildContext context) => context.goNamed(
    RouteNames.cardList,
    pathParameters: <String, String>{RoutePathParams.deckId: deckId},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(cardDetailProvider(cardId));

    return MxContentShell(
      title: context.l10n.cardDetailTitle,
      // Every branch below owns its gutters — the loaded body through its own
      // scroll padding, the empty and error faces through their own — so the
      // shell's default would pad each of them twice.
      padding: EdgeInsets.zero,
      actions: <Widget>[
        // Offered only once there is a card to edit. On the error and not-found
        // faces it would open an editor onto nothing, and on a deleted card it
        // would offer a repair that cannot work (M4.15 W3 faces 7 and 8).
        //
        // **`is AsyncData`, not `hasValue`.** Riverpod keeps the previous value
        // on an `AsyncError`, so a card that was on screen and then deleted
        // still reports `hasValue == true` — which left the action sitting on
        // the not-found face, pointing at a card that is gone.
        if (detail is AsyncData<CardDetailModel>)
          // **An icon on the app bar, which is what V3 asked for on day one.**
          // V19 moved it to a tonal button carrying the word, and its
          // measurement is the reason: `secondaryContainer` is only **1.14:1**
          // against the bar in light and 1.56:1 in dark, so a tonal pill with
          // no label is identified by nothing — the fill it is made of is
          // almost not there. That argues against *a tonal fill without a
          // word*, and it was read as an argument against a bare glyph.
          //
          // An icon button has no fill to be invisible. Its ink is the app
          // bar's own `foregroundColor` — `onSurface`, not the
          // `onSurfaceVariant` the icon-button theme would give it, because an
          // `AppBar` puts its foreground into the `IconTheme` its actions
          // inherit. Measured on the bar's background: **16.06:1** in light and
          // **16.62:1** in dark. Fourteen times the tonal container it
          // replaces, and five times WCAG 1.4.11's floor for a control. What
          // identifies it is the glyph, and the glyph is as legible as the
          // title beside it.
          //
          // BR-246 is satisfied either way and is worth quoting rather than
          // paraphrasing: edit must be *a separate, explicit action* that is
          // *not the default tap* and **must not out-weigh the content being
          // read**. It never required a word; the last clause prefers the
          // lighter control, and the card is what the page is for.
          //
          // No `Padding` wrapper: the card list's app bar puts its icon actions
          // in bare, and the gutter this used to carry existed only because a
          // tonal pill has a visible edge that an `IconButton` does not.
          MxIconButton(
            icon: Icons.edit_outlined,
            semanticLabel: context.l10n.cardDetailEditAction,
            tooltip: context.l10n.cardDetailEditAction,
            onPressed: () => _openEditor(context),
          ),
      ],
      body: MxAsyncView<CardDetailModel>(
        value: detail,
        loadingLabel: context.l10n.cardDetailLoadingLabel,
        error: (error, _) => _failureFace(context, ref, error),
        data: (value) => _Body(cardId: cardId, detail: value),
      ),
    );
  }

  /// A card that is gone is not the same event as a read that failed, and the
  /// two need different recoveries: one offers the way back to the list, the
  /// other offers to read again (BR-245, UC-19 E1/E3).
  ///
  /// The typed reason decides, never the message — a message is sanitized text
  /// for a human and matching on it would break the first time it is reworded.
  Widget _failureFace(BuildContext context, WidgetRef ref, Object error) {
    final isGone =
        error is NotFoundFailure && error.reason == CardNotFoundReason.cardGone;
    if (isGone) {
      return MxEmptyState(
        // **Not `search_off`.** Four screens use that glyph for "nothing
        // matched your search" — the card list, the tag catalog, deck search
        // — so a user who has met it there reads this face as "your filter
        // found nothing" rather than "this card is gone". `delete_outline`
        // says what actually happened.
        icon: Icons.delete_outline,
        title: context.l10n.cardDetailNotFoundTitle,
        message: context.l10n.cardDetailNotFoundMessage,
        actionLabel: context.l10n.cardDetailBackToListAction,
        onAction: () => _openCardList(context),
      );
    }

    return MxErrorState(
      title: context.l10n.unexpectedErrorTitle,
      message: context.l10n.cardDetailErrorMessage,
      retryLabel: context.l10n.retryAction,
      onRetry: () => _retryDetail(ref, cardId),
    );
  }
}

/// The three bands in one scroll view (M4.15 V4, W2).
///
/// One column rather than tabs: tabs would hide "what has happened to this
/// card" behind a choice the reader has to make before they can see it, which
/// is the question the screen exists to answer.
class _Body extends ConsumerWidget {
  const _Body({required this.cardId, required this.detail});

  final String cardId;
  final CardDetailModel detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(cardHistoryProvider(cardId));

    // `mxScreenGutter`, not a hardcoded `lg`: below 360dp every other screen
    // narrows to `md`, and this one would have sat 4dp wider than the list it
    // was opened from — on the width where those 4dp are least affordable.
    final gutter = mxScreenGutter(context);

    return SingleChildScrollView(
      // **`lg` at the foot** (D21). This screen pushes onto the Decks branch,
      // so the bottom bar stays — and Progress, Progress-by-deck and Study Home
      // all end a scroll a single gutter above it. `xxl` was double, on the one
      // screen a user reaches from those three.
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.xl,
        gutter,
        AppSpacing.lg,
      ),
      // **A reading column, not a full-bleed one.** On a phone this binds
      // nothing — 600 is above every width the app ships against — but a card's
      // two faces stretched across a tablet are a line nobody can track back to
      // the start of. `AppBreakpoints.medium` rather than a number invented
      // here, so the cap moves with the breakpoint it belongs to.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CardDetailSummaryWidget(detail: detail),
              // **`xl`, where the bands used to be `xxl` apart.** The gap was
              // carrying the whole separation between three groups that looked
              // alike; now every band is a surface, and the reader can see where
              // one ends without being told by 32dp of nothing.
              const SizedBox(height: AppSpacing.xl),
              CardDetailStateWidget(detail: detail),
              const SizedBox(height: AppSpacing.xl),
              CardHistorySectionWidget(
                state: history,
                onLoadMore: () => _loadMoreHistory(ref, cardId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
