import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';

/// BR-174: two scopes, ids normalized on construction, an empty set refused
/// by the type rather than by whichever layer noticed.
void main() {
  test('duplicate ids normalize to one', () {
    final scope = CardExportSelectionScope(const <String>['a', 'b', 'a', 'b']);

    expect(scope.cardIds, <String>{'a', 'b'});
    expect(scope.cardIds.length, 2);
  });

  test('an already-distinct set is kept whole', () {
    final scope = CardExportSelectionScope(const <String>{'a', 'b', 'c'});

    expect(scope.cardIds, <String>{'a', 'b', 'c'});
  });

  test('an empty selection is refused with a typed reason (UC-11 E5)', () {
    expect(
      () => CardExportSelectionScope(const <String>[]),
      throwsA(
        isA<ValidationFailure>().having(
          (ValidationFailure failure) => failure.problems,
          'problems',
          contains(CardExportProblem.emptyScope),
        ),
      ),
    );
  });

  test('the id set cannot be mutated after construction', () {
    final scope = CardExportSelectionScope(const <String>['a']);

    expect(() => scope.cardIds.add('b'), throwsUnsupportedError);
  });

  test('the two scopes are the closed set the switch dispatches on', () {
    const CardExportScope whole = CardExportWholeDeckScope();
    final CardExportScope selection = CardExportSelectionScope(const <String>[
      'a',
    ]);

    String describe(CardExportScope scope) => switch (scope) {
      CardExportWholeDeckScope() => 'whole',
      CardExportSelectionScope(:final cardIds) => 'selection:${cardIds.length}',
    };

    expect(describe(whole), 'whole');
    expect(describe(selection), 'selection:1');
  });
}
