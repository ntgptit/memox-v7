import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/di/tag_catalog_repository_provider.dart';
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/tag_catalog_repository.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// `TagCatalogScreen` mounted whole, its one contract faked (UC-18).
///
/// Live: type in the search field, open a row's menu, rename a tag onto
/// another one to see the merge disclosure, delete one and watch the count
/// move. The scenarios stage what interaction alone cannot — an empty library
/// and a read that fails.
WidgetbookComponent tagCatalogScreenComponent() {
  return WidgetbookComponent(
    name: 'TagCatalogScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<TagCatalogScenario>(
            label: 'scenario',
            options: TagCatalogScenario.values,
            labelBuilder: (TagCatalogScenario value) => value.label,
          );

          return _TagCatalogDemo(
            key: ValueKey<Object>(scenario),
            scenario: scenario,
          );
        },
      ),
    ],
  );
}

/// The states worth staging: a populated library, one with no tags at all
/// (M4.14 W3 face 3), a read that fails (face 5), and the two write failures
/// UC-18 names. The search-empty face is reachable by typing, and the rename
/// and delete overlays by using the row menus, so none of those needs a
/// scenario of its own.
///
/// **The write failures do.** They were implemented, and unit-tested, and
/// unreachable here — so the error band inside the rename sheet spent a whole
/// stage as a bare red line instead of the band the wireframe specifies, and no
/// design review could have seen it. Reached by opening a row's menu and
/// committing the action.
enum TagCatalogScenario {
  populated('a library with tags'),
  empty('no tags yet'),
  readFails('the catalog read fails'),
  renameFails('rename fails (use a row menu)'),
  deleteFails('delete fails (use a row menu)');

  const TagCatalogScenario(this.label);

  final String label;
}

class _TagCatalogDemo extends StatefulWidget {
  const _TagCatalogDemo({required this.scenario, super.key});

  final TagCatalogScenario scenario;

  @override
  State<_TagCatalogDemo> createState() => _TagCatalogDemoState();
}

class _TagCatalogDemoState extends State<_TagCatalogDemo> {
  late final TagCatalogFake _catalog = TagCatalogFake(widget.scenario);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [tagCatalogRepositoryProvider.overrideWithValue(_catalog)],
      child: const TagCatalogScreen(),
    );
  }
}

/// An in-memory catalog that actually renames, merges and deletes.
///
/// Public because the tag filter sheet's entry needs the same thing, and a
/// second fake for one contract is two places for the rules to drift apart —
/// which is the defect this feature's own BR-238 exists to forbid in the app.
///
/// **It re-implements the rules rather than stubbing them**, because the point
/// of the entry is that a designer can drive the real flow: renaming `nouns`
/// onto `Noun` has to actually collapse two rows into one, or the merge
/// disclosure is a label with nothing behind it.
final class TagCatalogFake implements TagCatalogRepository {
  TagCatalogFake(this.scenario) {
    // Seeded for every scenario that needs something to act on — the two
    // write failures are reached from a row menu, so an empty catalog
    // would leave them as unreachable as they were before.
    if (scenario != TagCatalogScenario.empty) _tags.addAll(_seed);
  }

  final TagCatalogScenario scenario;

  static const List<TagCatalogEntry> _seed = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 42),
    TagCatalogEntry(id: 't2', name: 'food', cardCount: 12),
    TagCatalogEntry(id: 't3', name: 'Noun', cardCount: 7),
    TagCatalogEntry(id: 't4', name: 'nouns', cardCount: 3),
    TagCatalogEntry(id: 't5', name: 'TOPIK II · chapter 3', cardCount: 1),
    TagCatalogEntry(id: 't6', name: 'unused', cardCount: 0),
  ];

  final List<TagCatalogEntry> _tags = <TagCatalogEntry>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<TagCatalogEntry>> watchTagCatalog({String? searchTerm}) async* {
    if (scenario == TagCatalogScenario.readFails) {
      throw const DatabaseFailure(message: 'staged failure');
    }
    yield _narrow(searchTerm);
    yield* _changes.stream.map((_) => _narrow(searchTerm));
  }

  List<TagCatalogEntry> _narrow(String? searchTerm) {
    final folded = TagName.fold(searchTerm ?? '');
    final rows = <TagCatalogEntry>[
      for (final tag in _tags)
        if (folded.isEmpty || TagName.fold(tag.name).contains(folded)) tag,
    ];
    rows.sort((a, b) {
      final byName = TagName.fold(a.name).compareTo(TagName.fold(b.name));

      return byName != 0 ? byName : a.id.compareTo(b.id);
    });

    return rows;
  }

  @override
  Future<TagRenameOutcome> renameTag({
    required String tagId,
    required TagName name,
  }) async {
    if (scenario == TagCatalogScenario.renameFails) {
      // No typed reason: a plain database refusal is what the repository
      // maps every unclassified write error to, and the sheet renders it
      // through the generic branch of `tagCatalogWriteFailure`.
      throw const DatabaseFailure(message: 'catalog: rename refused');
    }
    final index = _tags.indexWhere((TagCatalogEntry tag) => tag.id == tagId);
    if (index < 0) {
      throw const NotFoundFailure(
        message: 'gone',
        reason: TagCatalogProblem.tagMissing,
      );
    }
    final targetIndex = _tags.indexWhere(
      (TagCatalogEntry tag) =>
          tag.id != tagId && TagName.fold(tag.name) == name.folded,
    );
    if (targetIndex < 0) {
      _tags[index] = TagCatalogEntry(
        id: tagId,
        name: name.value,
        cardCount: _tags[index].cardCount,
      );
      _changes.add(null);

      return TagRenameOutcome.renamed;
    }

    final target = _tags[targetIndex];
    _tags[targetIndex] = TagCatalogEntry(
      id: target.id,
      name: target.name,
      // The overlap is unknown here, so the demo takes the sum — the shape of
      // a merge, not an arithmetic claim.
      cardCount: target.cardCount + _tags[index].cardCount,
    );
    _tags.removeAt(index);
    _changes.add(null);

    return TagRenameOutcome.merged;
  }

  @override
  Future<void> deleteTag(String tagId) async {
    if (scenario == TagCatalogScenario.deleteFails) {
      throw const DatabaseFailure(message: 'catalog: delete refused');
    }
    _tags.removeWhere((TagCatalogEntry tag) => tag.id == tagId);
    _changes.add(null);
  }
}
