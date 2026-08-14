import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/tag_catalog_repository.dart';
import 'package:memox/features/card/domain/usecases/delete_tag_use_case.dart';
import 'package:memox/features/card/domain/usecases/rename_tag_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_tag_catalog_use_case.dart';

/// A repository that records what it was asked and answers what it was told.
final class _RecordingCatalog implements TagCatalogRepository {
  final List<String?> searchTerms = <String?>[];
  final List<({String tagId, String name, String folded})> renames =
      <({String tagId, String name, String folded})>[];
  final List<String> deletes = <String>[];
  TagRenameOutcome outcome = TagRenameOutcome.renamed;

  @override
  Stream<List<TagCatalogEntry>> watchTagCatalog({String? searchTerm}) {
    searchTerms.add(searchTerm);

    return const Stream<List<TagCatalogEntry>>.empty();
  }

  @override
  Future<TagRenameOutcome> renameTag({
    required String tagId,
    required TagName name,
  }) async {
    renames.add((tagId: tagId, name: name.value, folded: name.folded));

    return outcome;
  }

  @override
  Future<void> deleteTag(String tagId) async => deletes.add(tagId);
}

/// The three catalog use cases (UC-12).
///
/// What is worth pinning here is the split of responsibility, not the plumbing:
/// BR-93's validation runs in the use case, and the collision test does **not**
/// — it belongs to the repository's write, because it depends on the database at
/// the moment of the write (BR-186).
void main() {
  late _RecordingCatalog repository;

  setUp(() => repository = _RecordingCatalog());

  group('WatchTagCatalogUseCase', () {
    test('passes the search term through to the statement (BR-182)', () {
      WatchTagCatalogUseCase(repository)(searchTerm: 'độn');

      expect(repository.searchTerms, <String?>['độn']);
    });

    test('no term is a null, which the read takes as no search', () {
      WatchTagCatalogUseCase(repository)();

      expect(repository.searchTerms, <String?>[null]);
    });
  });

  group('RenameTagUseCase applies BR-93 before the repository', () {
    test('trims, and hands over the trimmed spelling', () async {
      await RenameTagUseCase(repository)(tagId: 't1', rawName: '  Động từ  ');

      expect(repository.renames.single.name, 'Động từ');
    });

    test('folds with the full Unicode rule, not SQLite NOCASE', () async {
      await RenameTagUseCase(repository)(tagId: 't1', rawName: 'Động Từ');

      expect(repository.renames.single.folded, 'động từ');
    });

    test('refuses a blank name and never reaches the repository', () async {
      await expectLater(
        RenameTagUseCase(repository)(tagId: 't1', rawName: '   '),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            contains(TagValidationProblem.nameEmpty),
          ),
        ),
      );
      expect(repository.renames, isEmpty);
    });

    test('refuses a name past BR-93s fifty characters', () async {
      await expectLater(
        RenameTagUseCase(repository)(tagId: 't1', rawName: 'a' * 51),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            contains(TagValidationProblem.nameTooLong),
          ),
        ),
      );
      expect(repository.renames, isEmpty);
    });

    test('refuses a control character — the char(31) invariant', () async {
      await expectLater(
        // U+001F is the unit separator both GROUP_CONCAT reads split on, so
        // a tag carrying one turns one tag into two on the way back.
        RenameTagUseCase(repository)(tagId: 't1', rawName: 'noun'),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            contains(TagValidationProblem.nameHasControlCharacter),
          ),
        ),
      );
      expect(repository.renames, isEmpty);
    });

    test('reports what the write turned out to be (BR-186)', () async {
      repository.outcome = TagRenameOutcome.merged;

      expect(
        await RenameTagUseCase(repository)(tagId: 't1', rawName: 'noun'),
        TagRenameOutcome.merged,
      );
    });

    test(
      'a name that collides is NOT refused here — the transaction decides',
      () async {
        // The use case has no view of what exists, deliberately: deciding
        // rename-or-merge above the repository would put the check outside the
        // transaction and make it a race (BR-186).
        expect(
          await RenameTagUseCase(repository)(tagId: 't1', rawName: 'noun'),
          TagRenameOutcome.renamed,
        );
        expect(repository.renames, hasLength(1));
      },
    );
  });

  group('DeleteTagUseCase', () {
    test('passes the id straight through', () async {
      await DeleteTagUseCase(repository)('t1');

      expect(repository.deletes, <String>['t1']);
    });
  });
}
