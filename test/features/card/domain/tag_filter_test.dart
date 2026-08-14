import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';

/// [TagFilter]'s algebra (BR-183, BR-184).
///
/// The rule this type exists to hold is BR-183's identity clause — "no tag
/// selected applies no tag predicate" — and the reason it is a type is that
/// four callers would otherwise each write it. These tests are that clause, plus
/// the two compositions the overlay is built out of.
void main() {
  group('the empty selection is the identity (BR-183)', () {
    test('none is not active', () {
      expect(TagFilter.none.isActive, isFalse);
      expect(TagFilter.none.tagIds, isEmpty);
      expect(TagFilter.none.length, 0);
    });

    test('an empty iterable produces none, not a distinct empty value', () {
      // Distinct-but-equal would still pass `==`; the point is that every route
      // to "nothing selected" produces the *same* value, so a provider
      // comparing states cannot see a change where there is none.
      expect(TagFilter.of(const <String>[]), same(TagFilter.none));
      expect(TagFilter.of(const <String>{}), same(TagFilter.none));
    });

    test('toggling a tag on and off again lands back on none', () {
      expect(TagFilter.none.toggled('t1').toggled('t1'), same(TagFilter.none));
    });
  });

  group('selection', () {
    test('of() takes a copy, so a caller cannot mutate a live filter', () {
      final source = <String>{'t1'};
      final filter = TagFilter.of(source);

      source.add('t2');

      expect(filter.tagIds, <String>{'t1'});
    });

    test('the copy is unmodifiable', () {
      final filter = TagFilter.of(const <String>['t1']);

      expect(() => filter.tagIds.add('t2'), throwsUnsupportedError);
    });

    test('toggled adds an absent tag and removes a present one', () {
      final one = TagFilter.none.toggled('t1');
      expect(one.tagIds, <String>{'t1'});
      expect(one.isActive, isTrue);

      final two = one.toggled('t2');
      expect(two.tagIds, <String>{'t1', 't2'});
      expect(two.length, 2);

      expect(two.toggled('t1').tagIds, <String>{'t2'});
    });

    test('contains answers for the checkbox', () {
      final filter = TagFilter.of(const <String>['t1', 't2']);

      expect(filter.contains('t1'), isTrue);
      expect(filter.contains('t9'), isFalse);
    });
  });

  group('retaining drops tags that no longer exist (BR-186, BR-187)', () {
    test('a merged-away or deleted id is dropped', () {
      final filter = TagFilter.of(const <String>['t1', 'gone']);

      expect(filter.retaining(<String>{'t1', 't2'}).tagIds, <String>{'t1'});
    });

    test('every id gone leaves the identity, not an active empty filter', () {
      final filter = TagFilter.of(const <String>['gone']);

      expect(filter.retaining(<String>{'t1'}).isActive, isFalse);
    });

    test('nothing missing leaves an equal filter', () {
      final filter = TagFilter.of(const <String>['t1', 't2']);

      expect(filter.retaining(<String>{'t1', 't2', 't3'}), filter);
    });
  });

  group('equality ignores order', () {
    test('two selections of the same ids are equal', () {
      expect(
        TagFilter.of(const <String>['a', 'b']),
        TagFilter.of(const <String>['b', 'a']),
      );
      expect(
        TagFilter.of(const <String>['a', 'b']).hashCode,
        TagFilter.of(const <String>['b', 'a']).hashCode,
      );
    });

    test('different selections are not equal', () {
      expect(
        TagFilter.of(const <String>['a']) == TagFilter.of(const <String>['b']),
        isFalse,
      );
      expect(
        TagFilter.of(const <String>['a', 'b']) ==
            TagFilter.of(const <String>['a']),
        isFalse,
      );
    });
  });
}
