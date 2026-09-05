import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/foundations/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_card.dart';
import '../../../../shared/widgets/mx_messenger.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_search_field.dart';
import '../../domain/failures/tag_catalog_failure.dart';
import '../../domain/models/tag_catalog_entry_model.dart';
import '../controllers/tag_catalog_controller.dart';
import '../widgets/items/tag_catalog_row_widget.dart';
import '../widgets/overlays/tag_delete_confirm_widget.dart';
import '../widgets/overlays/tag_rename_widget.dart';
import '../../../../shared/widgets/mx_reading_column.dart';

/// Types into the catalog's search field (UC-18, BR-230). A free function for
/// the reason every command in this feature is one — see
/// `card_list_screen.dart`.
void _updateSearch(WidgetRef ref, String query) =>
    ref.read(tagCatalogSearchQueryProvider.notifier).update(query);

/// The tag catalog (UC-18, wireframe M4.14).
///
/// **Library-level, not deck-level**, because a tag belongs to no deck (BR-93,
/// BR-230). It sits at `/tags` inside the Library branch, so the bottom bar
/// stays and Back returns to whichever surface opened it — the deck list or a
/// card list.
///
/// **It cannot create a tag, and there is no `+` action.** Tags come into being
/// by being put on a card; a create action here would mint a row belonging to
/// nothing, which the user would then have no way to use (M4.14 W2 item 1).
///
/// Rename and delete are overlays over this screen, so the row a user acted on
/// is still behind them and focus returns to it when they close.
class TagCatalogScreen extends ConsumerWidget {
  const TagCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(tagCatalogProvider);
    final query = ref.watch(tagCatalogSearchQueryProvider);

    return MxContentShell(
      title: context.l10n.tagCatalogTitle,
      // Every branch below owns its gutters — the list through its own padding,
      // the empty and error states through their own — so leaving the shell's
      // on as well would pad each of them twice. The card list drops it for the
      // same reason, and the two screens then agree at the edge (M4.14 G1).
      padding: EdgeInsets.zero,
      // The search field waits until the catalog has something to search:
      // offering to filter an empty list is chrome asking a question with one
      // answer. It is not shown on the error face either — there is nothing
      // to narrow (M4.14 W3 face 5). `hasError` is checked on its own because
      // Riverpod keeps the previous value through an error: an error arriving
      // *after* data used to leave the field floating over the error face,
      // which is the one face W3 says has no search.
      subheader:
          !catalog.hasError &&
              ((catalog.value?.isNotEmpty ?? false) || query.isNotEmpty)
          ? _SearchStrip(query: query)
          : null,
      body: MxAsyncView<List<TagCatalogEntry>>(
        value: catalog,
        loadingLabel: context.l10n.tagCatalogLoadingLabel,
        error: (_, _) => _FaceColumn(
          child: MxErrorState(
            title: context.l10n.unexpectedErrorTitle,
            message: context.l10n.tagCatalogError,
            retryLabel: context.l10n.retryAction,
            onRetry: () => ref.invalidate(tagCatalogProvider),
          ),
        ),
        data: (tags) =>
            tags.isEmpty ? _empty(context, query) : _CatalogList(tags: tags),
      ),
    );
  }

  /// An empty result means "no tags yet" only when nothing was typed;
  /// otherwise it means the search matched nothing (M4.14 W3 faces 3 and 4).
  Widget _empty(BuildContext context, String query) {
    final term = query.trim();
    if (term.isNotEmpty) return _FaceColumn(child: _NoSearchMatch(query: term));

    return const _FaceColumn(child: _Empty());
  }
}

/// The column every state face stands in: the catalog's own gutter and the
/// same reading-column cap, so populated, empty, search-empty and error all
/// share left and right edges (M4.14 G1, visual revision 2026-08-28). The
/// faces carry their own internal insets; this owns only the page geometry,
/// which is why it exists once instead of each face re-deriving it.
class _FaceColumn extends StatelessWidget {
  const _FaceColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The shell's gutter, not a fixed `lg`: the search field above these
      // faces comes from the subheader, which steps to `md` below 360dp, and a
      // face that stayed at 16 there would sit inside the field it belongs to.
      padding: EdgeInsets.symmetric(horizontal: mxScreenGutter(context)),
      child: Center(child: MxReadingColumn(child: child)),
    );
  }
}

class _SearchStrip extends ConsumerWidget {
  const _SearchStrip({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    // The same reading-column cap the catalog surface stands under. On a
    // phone this binds nothing; at the framed web width it is what keeps the
    // search and the surface it filters sharing edges (M4.14 G2) instead of
    // the field running wide over a capped list.
    child: MxReadingColumn(
      child: MxSearchField(
        value: query,
        onChanged: (value) => _updateSearch(ref, value),
        hintText: context.l10n.tagSearchHint,
        semanticLabel: context.l10n.tagSearchLabel,
        clearSemanticLabel: context.l10n.tagSearchClearLabel,
      ),
    ),
  );
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({required this.tags});

  final List<TagCatalogEntry> tags;

  @override
  Widget build(BuildContext context) {
    // **This build's context, never a per-row one.** A merge removes the
    // source row from the catalog, so the element a row was built in is
    // deactivated moments later — and `ScaffoldMessenger.of` on a deactivated
    // context asserts. The column's parent outlives every row it renders.
    //
    // **One `MxCard.flat` holding every row — a working surface, not a card
    // per tag** (visual revision of M4.14, 2026-08-28). The rows used to sit
    // as bare lines on the page ground; Card Detail's grammar puts grouped
    // data on one flat panel and lets hairlines carry the row rhythm. A
    // `Column` rather than a builder: the surface must be continuous, and a
    // catalog is tens of rows, the same order Card Detail's summary renders
    // in one pass. If catalogs ever reach the hundreds, pagination is the
    // answer (as history's is), not splitting the card.
    // Horizontal from the shell's helper, so the surface follows the search
    // field down to `md` below 360dp instead of holding a fixed 16 the field
    // has already left (M4.14 G2). The card list moved to the same call in the
    // same change, which is what keeps G1's pairing true at every width.
    final gutter = mxScreenGutter(context);

    return SingleChildScrollView(
      // **`lg` at the foot, not `sm`, and not the gutter** (D21). Progress,
      // Study Home and the deck level all end a scrolling list a full `lg`
      // above the navigation bar — that is an end-of-scroll gap, not a page
      // edge, so it does not step down with the width.
      // `xl` on top, the rhythm both references keep: the card list's body
      // stands `xl` under its subheader and Card Detail opens at `xl`. This
      // was `sm` when the rows were bare lines — invisible then, a visibly
      // short 12dp once the surface grew a hairline edge.
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.xl,
        gutter,
        AppSpacing.lg,
      ),
      child: Center(
        // The same reading-column cap Card Detail set (M4.15 W2): above
        // `AppBreakpoints.medium` a full-bleed list is a line nobody can
        // track back; below it, this binds nothing.
        child: MxReadingColumn(
          child: MxCard.raised(
            padding: MxCardPadding.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var index = 0; index < tags.length; index++) ...<Widget>[
                  if (index > 0)
                    // Inset to the text column at the head, so the line reads
                    // as a row separator rather than the card being sliced
                    // through. Card Detail's summary hairlines are full-bleed
                    // — this list is the one that insets, because its rows
                    // carry a leading well the summary's do not.
                    const Divider(
                      // Thickness and height are the theme's (one hairline,
                      // no reserved space); only the inset is this list's.
                      indent: _rowTextInset,
                      // `xs`, the row's own trailing inset: the line then ends
                      // exactly on the row's content edge. `md` ended it on
                      // nothing — 8dp short of the content, 4dp past the menu
                      // glyph, 12dp inside the card.
                      endIndent: AppSpacing.xs,
                    ),
                  TagCatalogRowWidget(
                    entry: tags[index],
                    onRename: () => _rename(context, tags[index]),
                    onDelete: () => _delete(context, tags[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Where a row's text begins inside the card: the row's own leading inset,
  /// the 32dp well, and the gap after it. Stated once so the separator and
  /// the row cannot disagree about where the text column starts.
  static const double _rowTextInset =
      AppSpacing.md + TagCatalogRowWidget.wellSize + AppSpacing.md;

  /// Opened from a post-frame callback by `PopupMenuItem.onTap`, which fires
  /// after the menu route pops — so the sheet is pushed onto the screen rather
  /// than onto a route that is on its way out.
  void _rename(BuildContext context, TagCatalogEntry entry) =>
      showTagRenameSheet(
        context,
        tag: entry,
        onDone: (outcome) => _announce(context, entry, outcome),
      );

  /// **No completion callback.** The catalog is a live stream, so the row
  /// leaving the list *is* the confirmation — there is nothing for the screen
  /// to do afterwards, and an empty closure would only look like something was
  /// forgotten. A merge is different (see [_announce]): the row also
  /// disappears, but so would a delete, and only the transaction can say which
  /// of the two happened.
  void _delete(BuildContext context, TagCatalogEntry entry) =>
      showTagDeleteConfirm(context, tag: entry);

  /// Confirms what the write turned out to be (BR-234).
  ///
  /// **The outcome comes from the transaction, not from what the form
  /// predicted.** The sheet disclosed a merge beforehand from the catalog it
  /// held; this says what actually happened, which is the only version that
  /// survives another surface renaming the same tag in between.
  void _announce(
    BuildContext context,
    TagCatalogEntry entry,
    TagRenameOutcome outcome,
  ) {
    if (outcome != TagRenameOutcome.merged) return;

    showMxMessage(context, context.l10n.tagMergedConfirmation(entry.name));
  }
}

/// No tags at all (M4.14 W3 face 3).
///
/// **No call to action**, deliberately: nothing on this screen can create a
/// tag, so a button here would either do nothing or navigate somewhere the user
/// did not ask to go. The message says where tags come from instead.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.sell_outlined,
      title: context.l10n.tagCatalogEmptyTitle,
      message: context.l10n.tagCatalogEmptyMessage,
    );
  }
}

/// The searched-empty state: tags exist, the term matched none (M4.14 W3
/// face 4). Names the term, so the user can see what was searched for.
class _NoSearchMatch extends StatelessWidget {
  const _NoSearchMatch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.search_off,
      title: context.l10n.tagSearchEmptyTitle(query),
      message: context.l10n.tagSearchEmptyMessage,
    );
  }
}
