import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/extensions/app_ink.dart';
import '../../../../core/text/text_scale.dart';
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

    final identity = Column(
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
    );

    // The row's state, worded: an installed template says so, an open one
    // names the way in. Weight carries the affordance rather than the brand
    // colour — `primary` at label size measured 2.90:1 on the dark card, and
    // the whole card is the target anyway.
    final state = Text(
      row.isInstalled
          ? context.l10n.starterLibraryInstalledLabel
          : context.l10n.starterLibraryInstallAction,
      style: context.texts.labelMedium!.inked(
        context,
        row.isInstalled ? AppInk.success : AppInk.quiet,
        isEmphasized: true,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return MxCard.raised(
      onTap: () => _add(context),
      // **The pair re-arranges rather than one of them being crushed**
      // (SC-C7-01). A `RenderFlex` sizes its non-flex child at full intrinsic
      // width first, so the repeated word `Add to library` — identical on
      // every open row, and therefore the half carrying no information — took
      // what it wanted and the deck name took what was left. Measured on the
      // card's own content band: at 393dp and scale 2.0 in Vietnamese the
      // title got 93.8dp against the state's 223.2; at 360dp, 60.8; at 320dp,
      // 28.8 — about one glyph, on the only thing that tells one row from
      // another.
      //
      // The arrangement is `study_home_deck_item_widget.dart`'s, which solved
      // the same shape: a `LayoutBuilder` against a threshold widened by the
      // factor the row's own text grows by. The threshold is declared here
      // rather than imported — a feature never reads another feature's
      // internals (AD-13), and the two rows are answering the question about
      // different content anyway.
      //
      // **The factor is read off `titleMedium`, not off the threshold.** This
      // used to be `textScalerOf(context).scale(inlineStateMinWidth)`, which
      // asks the platform to size a 320sp font; Android's table is flat past
      // 100sp, so at the largest accessibility setting it returned 320
      // unchanged and the row stayed inline exactly where the deck name was
      // being cut to a glyph.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double threshold = scaledLayoutWidth(
            context,
            dp: AppStarterTile.inlineStateMinWidth,
            // The deck name is the half that runs out of line first, and it is
            // the largest rung on the row.
            rung: context.texts.titleMedium!,
          );

          if (constraints.maxWidth < threshold) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                identity,
                // The same step the study row puts between what a deck is and
                // what can be done about it (G8).
                const SizedBox(height: AppSpacing.md),
                state,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.md),
              // **Not `Flexible`, and that was tried.** Making the state a
              // second flex child gives the two halves `flex: 1` each, so the
              // `Row` splits the line 50/50 and the identity column loses the
              // share it had: the regenerated golden showed the state label
              // sitting mid-row and `Language: English` ellipsizing to
              // `Language: E…` at 393dp and ordinary text scale — a
              // regression on the render this change must not move. Above the
              // threshold the intrinsic-width slot is the *right* arrangement;
              // the crushing case is the one below it, and stacking is what
              // answers that.
              state,
            ],
          );
        },
      ),
    );
  }
}

/// What the starter row decides for itself.
abstract final class AppStarterTile {
  /// The narrowest content width at which the template's identity and its
  /// state share a band, at `textScaler` 1.0 — scaled by the live text factor
  /// before use.
  ///
  /// Read against the widths the app actually hands this row, measured at the
  /// level the `LayoutBuilder` sees (viewport minus the screen gutter minus
  /// the card's own padding): a 393dp phone gives 329 and stays inline, a
  /// 360dp phone gives 296 and stacks, and a 320dp screen gives 264. At text
  /// scale 2.0 the scaled threshold is 640, so every supported phone stacks —
  /// which is the point: that is the range where the deck name was being cut
  /// to a glyph.
  static const double inlineStateMinWidth = 320;
}
