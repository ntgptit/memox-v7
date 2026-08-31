import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/failures/deck_validation_failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/create_sub_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/rename_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:memox/features/deck/domain/models/deck_reorder_placement_model.dart';

import '../presentation/support/fake_deck_repository.dart';

/// The write use cases, and the validation that moved into them.
///
/// It used to run **twice**: once in the controller and once again inside the
/// repository, with nothing to catch the two disagreeing. It runs here now — the
/// layer that owns BR-01 and BR-11 — and these are its tests.
///
/// The controller tests still pass unchanged, which is the interesting part: they
/// assert the same per-field state through a completely different path now, so
/// they are evidence the move preserved behaviour rather than evidence that
/// nothing moved.
void main() {
  late FakeDeckRepository repository;

  setUp(() {
    repository = FakeDeckRepository();
  });

  /// The typed problems a refusal reported.
  ///
  /// Awaited even though the refusal is thrown *before* the use case reaches its
  /// first await — so a non-awaited call would surface it too. Awaiting keeps the
  /// assertion true if validation ever moves behind an await, and
  /// `discarded_futures` is an error here for that class of mistake.
  Future<Set<Enum>> problemsRefusedBy(Future<void> Function() action) async {
    try {
      await action();
    } on ValidationFailure catch (failure) {
      return failure.problems.toSet();
    }

    return <Enum>{};
  }

  group('CreateRootDeckUseCase', () {
    test('a valid form reaches the repository once', () async {
      await CreateRootDeckUseCase(repository)(
        rawName: 'Japanese N5',
        schedulerType: SchedulerType.sm2,
      );

      expect(repository.createdRootDecks, hasLength(1));
      expect(repository.createdRootDecks.single.name, 'Japanese N5');
    });

    test('a blank name is refused before the repository is touched', () async {
      // BR-01. Refusing here rather than after the round trip is the whole point
      // of validating in the use case.
      expect(
        await problemsRefusedBy(
          () => CreateRootDeckUseCase(repository)(
            rawName: '   ',
            schedulerType: SchedulerType.sm2,
          ),
        ),
        <Enum>{DeckValidationProblem.nameEmpty},
      );
      expect(repository.createdRootDecks, isEmpty);
    });

    test('a missing scheduler is refused (BR-11)', () async {
      // Nullable on purpose: "not chosen yet" is a real state the form starts in,
      // and a default would be the implicit choice the rule forbids.
      expect(
        await problemsRefusedBy(
          () => CreateRootDeckUseCase(repository)(
            rawName: 'Japanese N5',
            schedulerType: null,
          ),
        ),
        <Enum>{DeckValidationProblem.schedulerMissing},
      );
      expect(repository.createdRootDecks, isEmpty);
    });

    test('both fields are reported from one attempt', () async {
      // The reason refusal carries a `Set` and not `Failure.reason`: a single
      // reason cannot say that two inputs are wrong, and reporting only the first
      // would send the user round twice.
      expect(
        await problemsRefusedBy(
          () => CreateRootDeckUseCase(repository)(
            rawName: '',
            schedulerType: null,
          ),
        ),
        <Enum>{
          DeckValidationProblem.nameEmpty,
          DeckValidationProblem.schedulerMissing,
        },
      );
    });

    test('the refusal message names no user-facing copy', () async {
      // `message` is a sanitized diagnostic for the log. The screen picks ARB text
      // from the typed problems — see `deckSubmitFailure`.
      try {
        await CreateRootDeckUseCase(repository)(
          rawName: '',
          schedulerType: null,
        );
        fail('expected a refusal');
      } on ValidationFailure catch (failure) {
        expect(failure.message, contains('invalid'));
        expect(failure.message, contains(DeckValidationProblem.nameEmpty.name));
        // No sentence a user should read.
        expect(failure.message, isNot(contains('Please')));
      }
    });
  });

  group('CreateSubDeckUseCase', () {
    test('a valid form reaches the repository', () async {
      await CreateSubDeckUseCase(repository)(
        rawName: 'Hiragana',
        parentDeckId: 'parent-1',
      );

      expect(repository.createdSubDecks, hasLength(1));
    });

    test('a blank name is refused, and depth is not checked here', () async {
      // BR-55 stays in the repository, inside its transaction: the tree can
      // change between this call and the write, so a depth check here would
      // answer a question about a moment that has passed.
      expect(
        await problemsRefusedBy(
          () => CreateSubDeckUseCase(repository)(
            rawName: '',
            parentDeckId: 'parent-1',
          ),
        ),
        <Enum>{DeckValidationProblem.nameEmpty},
      );
      expect(repository.createdSubDecks, isEmpty);
    });
  });

  group('RenameDeckUseCase', () {
    test('a valid name reaches the repository', () async {
      await RenameDeckUseCase(repository)(deckId: 'deck-1', rawName: 'Renamed');

      expect(repository.renames, hasLength(1));
    });

    test('an over-length name is refused (BR-01)', () async {
      expect(
        await problemsRefusedBy(
          () => RenameDeckUseCase(repository)(
            deckId: 'deck-1',
            rawName: 'x' * (DeckName.maxLength + 1),
          ),
        ),
        <Enum>{DeckValidationProblem.nameTooLong},
      );
      expect(repository.renames, isEmpty);
    });
  });

  group('ReorderDeckUseCase', () {
    test('forwards a stable sibling-relative operation', () async {
      await ReorderDeckUseCase(repository)(
        deckId: 'source',
        targetSiblingDeckId: 'target',
        placement: DeckReorderPlacement.after,
      );

      expect(
        repository.reorders,
        <({String deckId, String target, DeckReorderPlacement placement})>[
          (
            deckId: 'source',
            target: 'target',
            placement: DeckReorderPlacement.after,
          ),
        ],
      );
    });
  });
}
