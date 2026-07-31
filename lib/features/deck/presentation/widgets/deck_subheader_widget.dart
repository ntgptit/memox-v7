import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// shell's subheader slot is for. The path is absent at the root — there is no
/// path to show — but the field never is: search is the one control that is as
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
      children: <Widget>[
        if (DeckPathWidget.hasPath(snapshot))
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
