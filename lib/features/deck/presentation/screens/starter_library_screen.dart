import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/extensions/app_ink.dart';
import '../../../../core/theme/foundations/app_spacing.dart';
import '../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_card.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_scroll_end_inset.dart';
import '../controllers/starter_library_controller.dart';
import '../widgets/overlays/starter_install_widget.dart';
import '../widgets/sections/deck_notice_widget.dart';

/// The published starter decks, and the way to copy one in (UC-01, AD-07).
///
/// **This screen exists because production seeds nothing.** The development
/// flavor copies every fixture in at startup; a real install starts from an
/// empty library, and its empty state has to offer content as well as a blank
/// form. Choosing from here *copies* a template (BR-33) — the copy is an
/// ordinary deck with its own ids, and updates to the template never touch it
/// (BR-35).
///
/// **The fixture notice is not decoration** (BR-87): the current starter
/// content is written by this project to exercise the app, and presenting it
/// as course content would be a claim the words cannot back.
class StarterLibraryScreen extends ConsumerWidget {
  const StarterLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read once and held: the error face below needs the same `AsyncValue` the
    // view is rendering, to say whether the retry it started is still in
    // flight. Watching a second time inside the error closure would be two
    // reads of one fact — what `progress_deck_screen.dart` records at its own
    // `ref.watch`.
    final AsyncValue<List<StarterTemplateRow>> catalog = ref.watch(
      starterLibraryProvider,
    );

    return MxContentShell(
      title: context.l10n.starterLibraryTitle,
      // The shell's own padding is dropped: the body is one scroll view and
      // owns its gutters. Keeping it outside the scroll clipped the rows at a
      // 16dp dead band under the bar, and paid the gutter twice for every
      // child that already carries one — the notice and the empty face.
      padding: EdgeInsets.zero,
      body: MxAsyncView<List<StarterTemplateRow>>(
        value: catalog,
        // The subject, which here happens to be the screen's own name —
        // `study_options_screen.dart` and `trash_screen.dart` do the same. A
        // loading label naming the product instead would say nothing about
        // what is being waited on.
        loadingLabel: context.l10n.starterLibraryTitle,
        data: (rows) => _Catalog(rows: rows),
        error: (error, stackTrace) => MxErrorState(
          // The failure, not the screen. `trash_screen.dart` states the reason
          // for the whole app: the screen name alone told the user nothing
          // about what went wrong.
          title: context.l10n.starterLibraryLoadErrorTitle,
          // **A read failure, not an install failure.** This branch fires when
          // the catalog cannot be *read*, so it cannot borrow
          // `starterLibraryInstallFailed` ("Could not add this deck. Nothing
          // was copied.") — nothing has been added at that point and the
          // sentence named an action the user never took. That key stays with
          // the install sheet, the only place an install can fail.
          message: context.l10n.starterLibraryLoadFailed,
          // Both halves or neither: `MxErrorState` asserts the pair, and the
          // release build drops the button silently when only one arrives —
          // which left a failure the user could read and could not act on.
          retryLabel: context.l10n.retryAction,
          onRetry: () => ref.invalidate(starterLibraryProvider),
          // Without this the tap repaints the identical face: `invalidate` is
          // a refresh, and `MxAsyncView` holds the previous value through one,
          // so nothing on screen tells the user the app noticed.
          isRetrying: catalog.isRefreshing,
        ),
      ),
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({required this.rows});

  final List<StarterTemplateRow> rows;

  @override
  Widget build(BuildContext context) {
    // A build with no published templates is a real state, not an error: the
    // manifest is allowed to be empty.
    if (rows.isEmpty) {
      return MxEmptyState(
        icon: Icons.auto_stories_outlined,
        // The situation, not the screen. Titling this with
        // `starterLibraryTitle` printed "Starter library" twice on one screen
        // — once in the bar, once here — and said nothing about the state.
        // Every other empty face names its own: `decksEmptyTitle`,
        // `cardListEmptyTitle`, `tagCatalogEmptyTitle`, `deckMoveEmptyTitle`.
        title: context.l10n.starterLibraryEmptyTitle,
        message: context.l10n.starterLibraryEmpty,
      );
    }

    final gutter = mxScreenGutter(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.lg,
        gutter,
        // The shell knows whether a floating action sits over the list and
        // answers the clearance; there is none here, so this is the ordinary
        // end gap (A20.1 P2-18).
        mxScrollEndInsetOf(context),
      ),
      children: <Widget>[
        DeckNoticeWidget(message: context.l10n.starterLibraryFixtureNotice),
        // `xl`, the scale's break between two sections of a screen. The BR-87
        // notice is not the first row of the catalog, and at the old `md` it
        // stood closer to the list than two rows stood to each other, so it
        // read as one more card to tap.
        const SizedBox(height: AppSpacing.xl),
        for (final (index, row) in rows.indexed) ...<Widget>[
          // `lg`, the gap between two list items, and what
          // `deck_list_sliver_widget.dart` settled on for the same
          // `MxCard.raised` row. Each card pads itself `lg` inside, so the
          // old `sm` made the space *between* two cards half the space
          // *inside* one and the grouping cue pointed the wrong way. Leading,
          // so the last card leaves the end gap to the list's own padding
          // instead of adding a stray one to it.
          if (index > 0) const SizedBox(height: AppSpacing.lg),
          _TemplateTile(row: row),
        ],
      ],
    );
  }
}

/// One template: what it is, where its words came from, and the way in.
class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.row});

  final StarterTemplateRow row;

  Future<void> _add(BuildContext context) async {
    // Already present: the default install path is idempotent (BR-37), so a
    // second copy exists only through BR-38's explicit confirmation. Cancel
    // copies nothing.
    if (row.isInstalled) {
      final isConfirmed = await showStarterAddAgainConfirm(context);
      if (!isConfirmed || !context.mounted) return;
    }

    final outcome = await showStarterInstallSheet(
      context,
      template: row.template,
      shouldAllowDuplicate: row.isInstalled,
    );
    if (outcome == null || !context.mounted) return;

    // Success returns to the Library, where the repository's stream is already
    // showing the new deck — nothing here reloads anything.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = row.template;
    final quiet = context.texts.bodySmall!.inked(context, AppInk.quiet);

    return MxCard.raised(
      onTap: () => _add(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  template.title.value,
                  style: context.texts.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${context.l10n.starterLibraryCardCount(template.cardCount)}'
                  ' · '
                  '${context.l10n.starterLibraryLocaleLabel(template.locale)}',
                  style: quiet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.starterLibrarySource(template.contentSource),
                  style: quiet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // The row's state, worded: an installed template says so, an open
          // one names the way in. Weight carries the affordance rather than
          // the brand colour — `primary` at label size measured 2.90:1 on the
          // dark card, and the whole card is the target anyway.
          Text(
            row.isInstalled
                ? context.l10n.starterLibraryInstalledLabel
                : context.l10n.starterLibraryInstallAction,
            style: context.texts.labelMedium!.inked(
              context,
              row.isInstalled ? AppInk.success : AppInk.quiet,
              isEmphasized: true,
            ),
          ),
        ],
      ),
    );
  }
}
