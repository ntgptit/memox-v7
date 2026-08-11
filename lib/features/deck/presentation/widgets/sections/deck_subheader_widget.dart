import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_search_field.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../controllers/deck_search_controller.dart';
import 'deck_path_widget.dart';

/// Typing into the search field of one level, bound to a `ref`.
///
/// A free function rather than a closure written inline in `build()`. `ref.read`
/// is the right call — typing is a command, and a `watch` inside a callback
/// would subscribe the widget to a value it is about to set — but written inline
/// it sits lexically inside `build`, where neither a reader nor
/// `memox.state_management.no_ref_read_in_build` can tell a deliberate command
/// from a missed subscription. Hoisting it makes the distinction structural.
///
/// The same move `deck_list_screen.dart` already makes for filter and sort.
ValueChanged<String> _updateQuery(WidgetRef ref, String? parentDeckId) =>
    (String value) =>
        ref.read(deckSearchQueryProvider(parentDeckId).notifier).update(value);

/// The path, and the way into search — which opens into the field on demand.
///
/// Both are chrome and both stay put while the list scrolls, which is what the
/// shell's subheader slot is for.
///
/// **The field is summoned, not resident.** It sat open on every level, and the
/// cost was a full row of chrome paid on every visit for a control most visits
/// never touch — the concept collapses it to a glyph, and it is right to: the
/// strip already holds the breadcrumb, so the search affordance shares that row
/// and the *field* appears only when asked for. What did not change is
/// everything that made the search worth keeping: the scope (this level's whole
/// subtree), the clear action, the result count and the focus ring are the same
/// field, mounted later.
///
/// **A live query pins the field open.** Collapse is for the resting state;
/// taking the input away while it is filtering the list would leave results on
/// screen with no visible cause and no way to amend them. So the toggle closes
/// only an *empty* field, and closing with a query clears it first — the same
/// tap count as clear-then-close, without the stranded state between.
class DeckSubheaderWidget extends ConsumerStatefulWidget {
  const DeckSubheaderWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  ConsumerState<DeckSubheaderWidget> createState() =>
      _DeckSubheaderWidgetState();
}

class _DeckSubheaderWidgetState extends ConsumerState<DeckSubheaderWidget> {
  /// Whether the field is mounted. View state, not business state: which level
  /// is being searched and for what lives in the provider, and survives this
  /// widget; whether the input is on screen right now belongs to the screen.
  bool _isSearchOpen = false;

  void _toggleSearch({required bool hasQuery, required String? parentId}) {
    if (_isSearchOpen && hasQuery) {
      // Closing a field that is filtering: clear first, so the list and the
      // chrome change together and no result set survives its own input.
      ref.read(deckSearchQueryProvider(parentId).notifier).update('');
    }
    setState(() => _isSearchOpen = !_isSearchOpen);
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.snapshot.parent;
    final parentId = parent?.id;
    final query = ref.watch(deckSearchQueryProvider(parentId));
    final results = ref.watch(deckSearchResultsProvider(parentId));
    final hasQuery = query.trim().isNotEmpty;
    // A query restored from a previous visit reopens the field: input the user
    // cannot see must never keep filtering the list.
    final isOpen = _isSearchOpen || hasQuery;

    return Column(
      mainAxisSize: MainAxisSize.min,
      // **`start`, and it is load-bearing.** The default is `center`, and the
      // breadcrumb is as wide as its own steps, so centring floats the path in
      // the middle of the strip with the list left-aligned under it. The gutter
      // is the line every other element on the screen starts from, so the path
      // starts there too.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: DeckPathWidget(snapshot: widget.snapshot)),
            MxIconButton(
              // `close` while open so the control reads as the way back out;
              // the glyph pair is the same one every collapsed control in
              // Material uses, and both states keep the 48 target.
              icon: isOpen ? Icons.close : Icons.search,
              semanticLabel: isOpen
                  ? context.l10n.deckSearchCloseLabel
                  : context.l10n.deckSearchOpenLabel,
              tooltip: isOpen
                  ? context.l10n.deckSearchCloseLabel
                  : context.l10n.deckSearchOpenLabel,
              onPressed: () =>
                  _toggleSearch(hasQuery: hasQuery, parentId: parentId),
            ),
          ],
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: MxSearchField(
              value: query,
              onChanged: _updateQuery(ref, parentId),
              // The tap that opened the field was the request to type.
              shouldAutofocus: true,
              hintText: parent == null
                  ? context.l10n.deckSearchHintRoot
                  : context.l10n.deckSearchHintInDeck(parent.name),
              clearSemanticLabel: context.l10n.deckSearchClearLabel,
              // Only once a search is running and has actually resolved: a
              // count that flickered to 0 while the stream was loading would
              // read as "no matches" for a frame.
              resultCount: hasQuery ? results.value?.length : null,
            ),
          ),
      ],
    );
  }
}
