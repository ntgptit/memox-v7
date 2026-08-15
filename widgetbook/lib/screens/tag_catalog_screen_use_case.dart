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
/// (M4.14 W3 face 3), and a read that fails (face 5). The search-empty face is
/// reachable by typing, and the rename and delete overlays by using the row
/// menus, so none of those needs a scenario of its own.
enum TagCatalogScenario {
  populated('a library with tags'),
  empty('no tags yet'),
  readFails('the catalog read fails');

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
  late final _CatalogFake _catalog = _CatalogFake(widget.scenario);

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
/// **It re-implements the rules rather than stubbing them**, because the point
/// of the entry is that a designer can drive the real flow: renaming `nouns`
/// onto `Noun` has to actually collapse two rows into one, or the merge
/// disclosure is a label with nothing behind it.
final class _CatalogFake implements TagCatalogRepository {
  _CatalogFake(this.scenario) {
    if (scenario == TagCatalogScenario.populated) _tags.addAll(_seed);
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
    _tags.removeWhere((TagCatalogEntry tag) => tag.id == tagId);
    _changes.add(null);
  }
}
