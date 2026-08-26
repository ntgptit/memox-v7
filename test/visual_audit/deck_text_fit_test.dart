import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../support/study_render.dart';
import 'deck_audit_harness.dart';

/// Nothing on the deck list may silently lose a word.
///
/// **The rule this makes enforceable.** Four review rounds looked at deck
/// screenshots and none of them saw that the hero read `15 car…  8 overdue…` at
/// 360, or that the breadcrumb read `Tất cả… / Academic W…` in Vietnamese —
/// because clipping is the one layout failure that produces **no error at all**.
/// `TextOverflow.ellipsis` does exactly what it was asked to do, nothing
/// overflows, every token stays legal, and a golden matches the day it was first
/// drawn wrong. An ellipsis looks like a decision.
///
/// So this asserts the frame rather than photographing it: render the real
/// screen across the widths, text scales and languages the gallery cannot
/// capture, and fail on any paragraph the renderer had to cut.
///
/// **It arrives last on purpose.** `deck_stress_probe.dart` measured this matrix
/// while the defects were still in it, and a gate that lands red is a gate
/// somebody mutes. #348, #350 and #351 fixed what it found; this keeps it fixed.
///
/// The two exemptions below are deliberate truncation, and each one is a
/// separate test rather than a silent skip — an allowlist nobody re-reads is
/// where the next defect moves in.
void main() {
  final english = AppLocalizationsEn();

  /// Deck names short enough that nothing is *meant* to truncate. A name long
  /// enough to wrap is a separate case, tested at the bottom.
  List<DeckSummary> roots() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Academic Word List',
      totalCardCount: 570,
      newCardCount: 46,
      dueCardCount: 12,
      overdueCardCount: 8,
      overdueDayCount: 7,
      learnedCardCount: 120,
      subDeckCount: 4,
    ),
    fakeSummary(
      id: 'd2',
      name: 'Phrasal verbs',
      totalCardCount: 88,
      learnedCardCount: 88,
      subDeckCount: 1,
    ),
  ];

  FakeDeckRepository levelRepo() => FakeDeckRepository.withLevel(
    parent: fakeSubDeck(id: 'd1a', name: 'Sublist 1', parentId: 'd1'),
    ancestors: <DeckPathSegment>[
      const DeckPathSegment(id: 'd1', name: 'Academic Word List'),
    ],
    children: <DeckSummary>[
      fakeChildSummary(
        id: 'd1a1',
        name: 'Nouns',
        parentId: 'd1a',
        totalCardCount: 60,
        newCardCount: 14,
        dueCardCount: 7,
        overdueCardCount: 4,
        overdueDayCount: 1,
        learnedCardCount: 22,
      ),
    ],
  );

  /// The quiet context row clips its unit word at large scales **on purpose**:
  /// half that row is narrower than the word, and the figure is the fact. The
  /// decision is written into `_QuietContextRow` — "the figure holds, the word
  /// clips".
  final deliberate = <String>{
    english.deckHeroNewMetricWord.toLowerCase(),
    english.deckHeroScheduledMetricWord.toLowerCase(),
  };

  Future<void> pumpDeck(
    WidgetTester tester, {
    required FakeDeckRepository repository,
    required Size surface,
    String? location,
    double textScale = 1,
    Locale? locale,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      // `ReviewApp` applies the text scale through `builder`, which leaves
      // `MediaQuery.size` alone. Constructing a fresh `MediaQueryData` — what
      // the deck screen harness does — zeroes `size`, and a widget that
      // measures its own line then measures nothing.
      deckScopeAround(
        repository,
        ReviewApp(
          home: deckRouterAt(location),
          textScale: textScale,
          locale: locale,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Text the renderer had to cut, minus the cuts that are decisions.
  List<String> clipped(WidgetTester tester) {
    final cut = <String>[];
    void visit(Element element) {
      final render = element.renderObject;
      if (render is RenderParagraph &&
          render.hasSize &&
          !render.debugNeedsLayout &&
          render.didExceedMaxLines) {
        final text = render.text.toPlainText().trim();
        if (!deliberate.contains(text.toLowerCase())) cut.add(text);
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);

    return cut;
  }

  // 360 is a common Android width; 412 a common large one; 393 is what the
  // gallery captures and the only one any review has ever seen.
  const widths = <double>[360, 393, 412];
  const scales = <double>[1, 1.3, 1.5];

  group('the root list keeps every word', () {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('$width at $scale', (tester) async {
          await pumpDeck(
            tester,
            repository: FakeDeckRepository.withSummaries(roots()),
            surface: Size(width, 900),
            textScale: scale,
          );

          expect(clipped(tester), isEmpty);
        });
      }
    }

    testWidgets('and keeps them in Vietnamese', (tester) async {
      // The language the app is for, and the one no golden is drawn in. The
      // hero lost `nay` here at 393 × 1.0 — the gallery's own configuration.
      for (final width in widths) {
        await pumpDeck(
          tester,
          repository: FakeDeckRepository.withSummaries(roots()),
          surface: Size(width, 900),
          locale: const Locale('vi'),
        );

        expect(clipped(tester), isEmpty, reason: 'clipped at ${width}dp in vi');
      }
    });
  });

  group('a level inside a deck keeps every word', () {
    for (final scale in <double>[1, 1.5]) {
      testWidgets('360 at $scale', (tester) async {
        await pumpDeck(
          tester,
          repository: levelRepo(),
          surface: const Size(360, 900),
          location: '/decks/deck-1',
          textScale: scale,
        );

        expect(clipped(tester), isEmpty);
      });
    }

    testWidgets('and in Vietnamese at 1.5, where the breadcrumb folded', (
      tester,
    ) async {
      await pumpDeck(
        tester,
        repository: levelRepo(),
        surface: const Size(360, 900),
        location: '/decks/deck-1',
        textScale: 1.5,
        locale: const Locale('vi'),
      );

      expect(clipped(tester), isEmpty);
    });
  });

  group('the truncation that is a decision', () {
    testWidgets('a deck name longer than two lines still truncates', (
      tester,
    ) async {
      // `maxLines: 2` on the tile title is deliberate: a name is a label a user
      // chose, it can be any length, and two lines is the budget a row has. The
      // gate would be lying if it claimed nothing ever truncates.
      await pumpDeck(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'd1',
            name:
                'Từ vựng học thuật nâng cao cho kỳ thi IELTS Academic 2026 '
                'và các kỳ thi tương đương khác',
            totalCardCount: 570,
            dueCardCount: 12,
          ),
        ]),
        surface: const Size(360, 900),
        locale: const Locale('vi'),
      );

      expect(
        clipped(tester),
        isNotEmpty,
        reason:
            'the tile title is allowed to run out of room; if this passes '
            'the fixture stopped being long, not the rule stopped applying',
      );
    });
  });
}
