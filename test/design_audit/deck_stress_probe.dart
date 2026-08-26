@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../support/layout_probe.dart';
import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';
import '../features/deck/presentation/support/fake_deck_repository.dart';

/// Renders the deck list across the conditions the layout review could not
/// answer from a single 393×852 golden, and writes down what breaks.
///
/// **Why this is a probe and not a gate.** `deck_list_root.md` §16 and §19 were
/// both `➖ chưa có bằng chứng`: the gallery captures one width, one text scale
/// and one language, so nothing in the suite had ever rendered the screen at
/// 360, at scale 1.5, or in Vietnamese. This measures that matrix. The rules
/// that *fail* a build live in `test/visual_audit/` — a clipping budget belongs
/// there once the clipping it would catch is fixed, not before, or the gate
/// lands red and gets muted.
///
/// **Not named `_test.dart` on purpose.** `flutter test` collects by that
/// suffix, so this stays out of every suite and runs only when a reviewer names
/// it. It asserts nothing; it prints, and with `MEMOX_LAYOUT_PROBE=1` it also
/// writes `build/layout_probe/*.json` and the evidence PNGs under
/// `build/stress/`.
///
/// ```bash
/// MEMOX_LAYOUT_PROBE=1 flutter test test/design_audit/deck_stress_probe.dart \
///   --tags golden --update-goldens
/// ```
void main() {
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
      name: 'IELTS Writing Task 2',
      totalCardCount: 210,
      dueCardCount: 3,
      learnedCardCount: 145,
      subDeckCount: 2,
      schedulerType: SchedulerType.sm2,
    ),
    fakeSummary(
      id: 'd3',
      name: 'Phrasal verbs',
      totalCardCount: 88,
      learnedCardCount: 88,
      subDeckCount: 1,
    ),
    fakeSummary(id: 'd4', name: 'Business email', subDeckCount: 3),
  ];

  /// Vietnamese deck names of the length a real user types.
  List<DeckSummary> longNames() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Từ vựng học thuật nâng cao cho kỳ thi IELTS Academic 2026',
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
      name: 'Cụm động từ và thành ngữ thông dụng trong giao tiếp hằng ngày',
      totalCardCount: 210,
      dueCardCount: 3,
      learnedCardCount: 145,
      subDeckCount: 2,
    ),
  ];

  /// Reports every paragraph the renderer had to cut off, with how many
  /// logical pixels short of its own content the box was.
  List<String> clippedText() {
    final clipped = <String>[];
    final seen = <String>{};
    void visit(Element element) {
      final render = element.renderObject;
      // A pushed route leaves the page below it in the tree un-laid-out, and
      // asking an un-laid-out paragraph whether it clipped asserts rather than
      // answers. The level screen is a child route, so this is not hypothetical.
      if (render is RenderParagraph &&
          render.hasSize &&
          !render.debugNeedsLayout &&
          render.didExceedMaxLines &&
          render.text.style?.fontFamily != 'MaterialIcons') {
        final text = render.text.toPlainText().trim();
        final had = render.size.width;
        final needed = render.getMaxIntrinsicWidth(double.infinity);
        final line =
            '"$text" had ${had.toStringAsFixed(0)} '
            'needed ${needed.toStringAsFixed(0)} '
            '(short ${(needed - had).toStringAsFixed(0)})';
        if (seen.add(line)) clipped.add(line);
      }
      element.visitChildren(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root != null) visit(root);
    return clipped;
  }

  Future<void> report(
    WidgetTester tester,
    String label, {
    required Widget home,
    Size surface = kReviewSurface,
    double textScale = 1,
    Locale? locale,
    Brightness brightness = Brightness.light,
    bool capture = false,
  }) async {
    await pumpReview(
      tester,
      ReviewApp(
        home: home,
        brightness: brightness,
        textScale: textScale,
        locale: locale,
      ),
      surface: surface,
    );

    final exception = tester.takeException();
    final clipped = clippedText();

    // ignore: avoid_print
    print(
      '\n[$label] surface=${surface.width}x${surface.height} '
      'scale=$textScale locale=${locale?.languageCode ?? 'en'}\n'
      '  overflow : ${exception == null ? 'none' : exception.toString().split('\n').first}\n'
      '  clipped  :\n    ${clipped.isEmpty ? 'none' : clipped.join('\n    ')}',
    );

    probeLayout('goldens/stress_$label.png');
    // Written under build/ rather than beside the test: these are evidence for
    // one review, not baselines the suite compares against. Behind the same
    // flag as the probe, so a run without it can never fail on a missing PNG.
    if (capture && isLayoutProbeEnabled) {
      await expectLater(
        find.byType(ReviewApp),
        matchesGoldenFile('../../build/stress/$label.png'),
      );
    }
    debugDisableShadows = true;
  }

  const surfaces = <String, Size>{
    '360x640': Size(360, 640),
    '393x852': kReviewSurface,
    '412x915': Size(412, 915),
  };

  for (final entry in surfaces.entries) {
    for (final scale in <double>[1, 1.3, 1.5]) {
      testWidgets('root ${entry.key} @$scale', (tester) async {
        await report(
          tester,
          'root_${entry.key}_$scale',
          home: deckShellWith(FakeDeckRepository.withSummaries(roots())),
          surface: entry.value,
          textScale: scale,
          capture: entry.key == '360x640' && (scale == 1 || scale == 1.5),
        );
      });
    }
  }

  // The same fixture the gallery renders, in the other language the app ships.
  // Separated from the long-name case so a clip here cannot be blamed on the
  // deck names.
  testWidgets('root vi 393 @1.0', (tester) async {
    await report(
      tester,
      'root_vi_393_1.0',
      home: deckShellWith(FakeDeckRepository.withSummaries(roots())),
      locale: const Locale('vi'),
      capture: true,
    );
  });

  testWidgets('root vi long names', (tester) async {
    await report(
      tester,
      'root_vi_long',
      home: deckShellWith(FakeDeckRepository.withSummaries(longNames())),
      locale: const Locale('vi'),
    );
  });

  testWidgets('root vi long names @1.5', (tester) async {
    await report(
      tester,
      'root_vi_long_1.5',
      home: deckShellWith(FakeDeckRepository.withSummaries(longNames())),
      locale: const Locale('vi'),
      textScale: 1.5,
    );
  });

  testWidgets('root vi 360 @1.5', (tester) async {
    await report(
      tester,
      'root_vi_360_1.5',
      home: deckShellWith(FakeDeckRepository.withSummaries(longNames())),
      surface: const Size(360, 640),
      locale: const Locale('vi'),
      textScale: 1.5,
      capture: true,
    );
  });

  testWidgets('empty vi @1.5', (tester) async {
    await report(
      tester,
      'empty_vi_1.5',
      home: deckShellWith(
        FakeDeckRepository.withSummaries(const <DeckSummary>[]),
      ),
      surface: const Size(360, 640),
      locale: const Locale('vi'),
      textScale: 1.5,
    );
  });

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
      fakeChildSummary(
        id: 'd1a2',
        name: 'Verbs',
        parentId: 'd1a',
        totalCardCount: 60,
        learnedCardCount: 60,
      ),
      fakeChildSummary(
        id: 'd1a3',
        name: 'Adjectives',
        parentId: 'd1a',
        totalCardCount: 60,
        dueCardCount: 5,
        subDeckCount: 2,
      ),
    ],
  );

  for (final scale in <double>[1, 1.5]) {
    testWidgets('level 360 @$scale', (tester) async {
      await report(
        tester,
        'level_360_$scale',
        home: deckLevelWith(levelRepo()),
        surface: const Size(360, 640),
        textScale: scale,
        capture: true,
      );
    });

    testWidgets('new-only 360 @$scale', (tester) async {
      await report(
        tester,
        'newonly_360_$scale',
        home: deckShellWith(
          FakeDeckRepository.withSummaries(<DeckSummary>[
            fakeSummary(
              id: 'd1',
              name: 'Korean vocabulary',
              totalCardCount: 20,
              newCardCount: 20,
              subDeckCount: 2,
            ),
          ]),
        ),
        surface: const Size(360, 640),
        textScale: scale,
      );
    });

    testWidgets('empty 360 @$scale', (tester) async {
      await report(
        tester,
        'empty_360_$scale',
        home: deckShellWith(FakeDeckRepository()),
        surface: const Size(360, 640),
        textScale: scale,
      );
    });
  }

  // Does the level screen belong to SUMMARY's C1 — the screens that already
  // clip at the width the gallery captures? The breadcrumb is 5px short at 360,
  // so the answer turns on 33 pixels and is worth measuring rather than
  // inferring.
  testWidgets('level 393 @1.0', (tester) async {
    await report(tester, 'level_393_1.0', home: deckLevelWith(levelRepo()));
  });

  testWidgets('level vi 393 @1.0', (tester) async {
    await report(
      tester,
      'level_vi_393_1.0',
      home: deckLevelWith(levelRepo()),
      locale: const Locale('vi'),
    );
  });

  testWidgets('level vi 360 @1.5', (tester) async {
    await report(
      tester,
      'level_vi_360_1.5',
      home: deckLevelWith(levelRepo()),
      surface: const Size(360, 640),
      locale: const Locale('vi'),
      textScale: 1.5,
      capture: true,
    );
  });

  testWidgets('root dark 360 @1.5', (tester) async {
    await report(
      tester,
      'root_dark_360_1.5',
      home: deckShellWith(FakeDeckRepository.withSummaries(roots())),
      surface: const Size(360, 640),
      textScale: 1.5,
      brightness: Brightness.dark,
    );
  });

  testWidgets('root 50 decks', (tester) async {
    await report(
      tester,
      'root_50',
      home: deckShellWith(
        FakeDeckRepository.withSummaries(<DeckSummary>[
          for (var i = 0; i < 50; i++)
            fakeSummary(
              id: 'd$i',
              name: 'Deck number $i',
              totalCardCount: 40 + i,
              dueCardCount: i % 7,
              learnedCardCount: i,
              subDeckCount: i % 3,
            ),
        ]),
      ),
    );
  });
}
