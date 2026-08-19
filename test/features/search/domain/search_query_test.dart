import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';

/// BR-248 and BR-249: what a query normalises to, and what "empty" means.
void main() {
  test('it trims and folds with the shared rule', () {
    final query = SearchQuery.parse('  CÔNG Nghệ  ');

    expect(
      query.raw,
      'CÔNG Nghệ',
      reason: 'the raw form is what a message echoes',
    );
    expect(query.folded, 'công nghệ');
  });

  test('the query and the stored columns fold by the same function', () {
    // The asymmetry this pins is the bug the folded columns were added to fix:
    // a card stored as `CÔNG NGHỆ` could not be found by typing `công nghệ`
    // while a lowercase one could, because SQLite's `lower()` folds ASCII only.
    // Both sides go through `foldForSearch` now, and this is what would notice
    // one of them growing its own copy of the rule again.
    const raw = 'ĐỘNG Từ';
    final stored = CardText.parse(raw, side: CardSide.front).text!;
    final tag = TagName.parse(raw).name!;

    expect(SearchQuery.parse(raw).folded, stored.folded);
    expect(SearchQuery.parse(raw).folded, tag.folded);
  });

  test('case only — a diacritic is not stripped', () {
    // A product decision, not a side effect: `công` and `cong` are two
    // different words, exactly as `Động từ` and `Dong tu` are two tags (BR-93).
    expect(
      SearchQuery.parse('công').folded,
      isNot(SearchQuery.parse('cong').folded),
    );
  });

  for (final raw in <String>['', '   ', '\t', '\n  \n']) {
    test('whitespace-only input (${raw.length} chars) is not a search', () {
      final query = SearchQuery.parse(raw);

      expect(query.isEmpty, isTrue);
      expect(query.isNotEmpty, isFalse);
      expect(
        query,
        SearchQuery.empty,
        reason:
            'every non-search normalises to one value, so the guard above the '
            'repository is a single comparison rather than a family of them',
      );
    });
  }

  test(
    'two spellings of one search compare equal only when both halves agree',
    () {
      // `update` skips a re-read when the new query equals the current one, so
      // equality has to mean "the same statement would run". Two queries that
      // fold alike but were typed differently still differ, because the empty
      // message echoes the raw text.
      expect(SearchQuery.parse('noun'), SearchQuery.parse('noun'));
      expect(SearchQuery.parse('noun'), SearchQuery.parse(' noun '));
      expect(SearchQuery.parse('Noun'), isNot(SearchQuery.parse('noun')));
    },
  );
}
