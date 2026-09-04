import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';

import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// A20.1 P2-17 — the search screen under the accessibility guidelines.
void main() {
  Future<void> sweep(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // Contrast is deliberately not swept here: `textContrastGuideline`
    // samples rendered pixels, and on a 12px line most glyph pixels are only
    // partially covered — `settings_accessibility_test.dart` records it
    // reporting 1.35:1 on a pair that measures 7.0:1. Every ink this screen
    // writes in is measured from the tokens by the contrast suites under
    // `test/core/theme/`.
    handle.dispose();
  }

  testWidgets('initial and with results', (tester) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          decks: <DeckSearchHit>[fakeDeckHit()],
          cards: <CardSearchHit>[fakeCardHit()],
        ),
      ),
    );
    await sweep(tester);
    await typeSearch(tester, 'noun');
    await sweep(tester);
  });
}
