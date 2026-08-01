import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_search_field.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../controllers/deck_search_controller.dart';
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

/// The path, and the search field under it.
///
/// Both are chrome and both stay put while the list scrolls, which is what the
/// shell's subheader slot is for. Neither is ever absent: the path is drawn at
/// every level including the deck list, and search is the one control that is as
/// useful with three decks as with three hundred.
class DeckSubheaderWidget extends ConsumerWidget {
  const DeckSubheaderWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = snapshot.parent;
    final parentId = parent?.id;
    final query = ref.watch(deckSearchQueryProvider(parentId));
    final results = ref.watch(deckSearchResultsProvider(parentId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      // **`start`, and it is load-bearing.** The default is `center`, and the
      // search field is full width so it hid that: only the breadcrumb, which is
      // as wide as its own steps, showed the effect — a path floating in the
      // middle of the strip with the list left-aligned under it. The gutter is
      // the line every other element on the screen starts from, so the path
      // starts there too.
      crossAxisAlignment: CrossAxisAlignment.start,
      // **`sm`, and the number the eye meets is 24.** The strip above is 48
      // tall for its touch floor while its text is 16, so 16px of invisible
      // target space already sits under the words; what a reader sees is that
      // plus this gap. It shipped one release as `lg + xs` — 20, put there by a
      // squash while this very comment still argued for `sm`, and the kit's
      // `.mx-shell__sub` stayed at 8 — which pushed the visible gap to 36
      // against 16 on the panel side: the search field read as stranded from
      // the chrome it belongs to and glued to the content that scrolls under
      // it. 8 here and 28 below the field is as close to even as the 4px grid
      // allows (the exact split, 18, is not on it), with the odd 4 spent on the
      // side proximity wants: search groups with the breadcrumb, not the panel.
      spacing: AppSpacing.sm,
      children: <Widget>[
        // Unconditional: every level has a path now, the deck list included,
        // where it is the single `Root` step.
        DeckPathWidget(snapshot: snapshot),
        MxSearchField(
          value: query,
          onChanged: _updateQuery(ref, parentId),
          hintText: parent == null
              ? context.l10n.deckSearchHintRoot
              : context.l10n.deckSearchHintInDeck(parent.name),
          clearSemanticLabel: context.l10n.deckSearchClearLabel,
          // Only once a search is running and has actually resolved: a count
          // that flickered to 0 while the stream was loading would read as "no
          // matches" for a frame.
          resultCount: query.trim().isEmpty ? null : results.value?.length,
        ),
      ],
    );
  }
}
