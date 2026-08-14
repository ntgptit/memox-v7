import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/tag_catalog_repository.dart';

/// A `TagCatalogRepository` a presentation test drives by hand (UC-12).
///
/// **Three methods, and that is the point of the contract being its own.** A
/// catalog test fakes what the catalog calls; it never has to satisfy
/// `CardRepository`'s twenty-six members to render a list of tags.
///
/// The catalog is a `StreamController` the test pushes into, so a screen can be
/// moved through loading → populated → empty by emitting. [seeded] takes the
/// other route — a value already in hand, for a visual audit that needs the
/// loaded frame without pumping.
final class FakeTagCatalogRepository implements TagCatalogRepository {
  FakeTagCatalogRepository();

  /// A repository whose catalog is already loaded.
  factory FakeTagCatalogRepository.seeded(List<TagCatalogEntry> entries) =>
      FakeTagCatalogRepository().._seeded = entries;

  List<TagCatalogEntry>? _seeded;

  final StreamController<List<TagCatalogEntry>> _catalog =
      StreamController<List<TagCatalogEntry>>.broadcast();

  /// Every search term the catalog read was asked for, in order.
  ///
  /// Recorded because the failure worth catching is a screen that filters a
  /// cached list in Dart instead of asking the statement — which folds by a
  /// different rule and reads the counts from a different instant (BR-182).
  final List<String?> requestedSearchTerms = <String?>[];

  /// Recorded rename calls: the tag and the raw name as it arrived.
  final List<({String tagId, String name})> renameCalls =
      <({String tagId, String name})>[];

  /// Recorded delete calls, in order.
  final List<String> deleteCalls = <String>[];

  /// What the next rename reports. `renamed` unless a test says otherwise.
  TagRenameOutcome renameOutcome = TagRenameOutcome.renamed;

  /// Thrown by the next write, then cleared — so a test can prove the failure
  /// path and the recovery in one run.
  Failure? nextFailure;

  /// Pushes a new catalog **and** replaces the seed.
  ///
  /// Both, because a surface that is open follows the stream while one opened
  /// afterwards re-subscribes and gets the seed — and a fake where those two
  /// disagree makes "the tag was merged away elsewhere" untestable.
  void emitCatalog(List<TagCatalogEntry> entries) {
    _seeded = entries;
    _catalog.add(entries);
  }

  void emitError(Object error) => _catalog.addError(error);

  @override
  Stream<List<TagCatalogEntry>> watchTagCatalog({String? searchTerm}) async* {
    requestedSearchTerms.add(searchTerm);
    // The seeded route still honours the search term, because the screen must
    // not be the thing that narrows: a test that types into the field and sees
    // an unchanged list would otherwise pass while the read was ignored.
    final folded = TagName.fold(searchTerm ?? '');
    final seeded = _seeded;
    if (seeded != null) yield _narrow(seeded, folded);

    yield* _catalog.stream.map(
      (List<TagCatalogEntry> entries) => _narrow(entries, folded),
    );
  }

  static List<TagCatalogEntry> _narrow(
    List<TagCatalogEntry> entries,
    String folded,
  ) {
    if (folded.isEmpty) return entries;

    return <TagCatalogEntry>[
      for (final entry in entries)
        if (TagName.fold(entry.name).contains(folded)) entry,
    ];
  }

  @override
  Future<TagRenameOutcome> renameTag({
    required String tagId,
    required TagName name,
  }) async {
    renameCalls.add((tagId: tagId, name: name.value));
    _throwIfAsked();

    return renameOutcome;
  }

  @override
  Future<void> deleteTag(String tagId) async {
    deleteCalls.add(tagId);
    _throwIfAsked();
  }

  void _throwIfAsked() {
    final failure = nextFailure;
    if (failure == null) return;
    nextFailure = null;
    throw failure;
  }
}
