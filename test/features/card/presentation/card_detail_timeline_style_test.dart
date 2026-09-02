import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_summary_widget.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';

import '../../../support/color_math.dart';
import 'support/card_detail_harness.dart';
import 'support/fake_card_detail_repository.dart';

/// What the timeline paints, and the measurements behind every colour on the
/// screen (M4.15).
void main() {
  FakeCardDetailRepository loaded({List<CardHistoryEventModel>? events}) =>
      FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(front: '사과', back: 'quả táo')
        ..pages.add(
          events == null
              ? CardHistoryPageModel.empty
              : CardHistoryPageModel(
                  events: events,
                  hasMore: false,
                  nextCursor: null,
                ),
        );

  AppSemanticColors semanticOf(WidgetTester tester) => Theme.of(
    tester.element(find.byType(CardDetailSummaryWidget)),
  ).extension<AppSemanticColors>()!;

  const actions = <StudyAction>[
    StudyAction.forgotten,
    StudyAction.remembered,
    StudyAction.again,
    StudyAction.hard,
    StudyAction.good,
    StudyAction.easy,
  ];

  testWidgets('all six actions map to the three-step tone, dot and badge '
      'alike', (tester) async {
    await pumpCardDetail(
      tester,
      loaded(
        events: <CardHistoryEventModel>[
          for (var index = 0; index < actions.length; index++)
            fakeHistoryEvent(id: 'e-$index', action: actions[index]),
        ],
      ),
      surfaceSize: const Size(390, 2200),
    );
    await tester.pumpAndSettle();

    final semantic = semanticOf(tester);

    for (var index = 0; index < actions.length; index++) {
      final action = actions[index];
      final expected = switch (action) {
        StudyAction.forgotten || StudyAction.again => semantic.danger,
        // **`hard` is its own step.** It kept the card and cost effort doing
        // it; calling that a success flattens the only signal SM-2 has between
        // "fine" and "nearly lost it".
        StudyAction.hard => semantic.warning,
        _ => semantic.success,
      };
      final row = find.byType(CardHistoryEventWidget).at(index);

      // The dot, found by shape: every row but the first opens with a stub of
      // the connector, so "the first container" is a line on five of six rows.
      final containers = find.descendant(
        of: row,
        matching: find.byType(Container),
      );
      final dot = tester
          .widgetList<Container>(containers)
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.shape == BoxShape.circle);
      expect(dot.color, expected, reason: 'the dot of ${action.name}');

      // The badge: an outline in the same ink, with the word inside it.
      final badge = tester
          .widgetList<Container>(containers)
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.border != null);
      expect(
        badge.border!.top.color,
        expected,
        reason: 'the badge of ${action.name}',
      );
      expect(badge.color, isNull, reason: 'the badge is outlined, not filled');
    }
  });

  testWidgets('the verdict is a word, and the line under it stops repeating '
      'it', (tester) async {
    await pumpCardDetail(
      tester,
      loaded(
        events: <CardHistoryEventModel>[
          fakeHistoryEvent(id: 'e-1', previousBox: 2, nextBox: 3),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The badge carries the action; the line beneath carries where the turn
    // came from and what it was for. Saying the verdict twice was the shape the
    // banded layout needed and this one does not.
    expect(find.text('Remembered'), findsOneWidget);
    expect(find.text('Self-assess · Scheduled'), findsOneWidget);
    expect(find.textContaining('Self-assess · Scheduled · '), findsNothing);
  });

  testWidgets('the box line is accented by its kind, not by its words', (
    tester,
  ) async {
    await pumpCardDetail(
      tester,
      loaded(
        events: <CardHistoryEventModel>[
          fakeHistoryEvent(
            id: 'e-1',
            previousBox: 2,
            nextBox: 3,
            nextDueAt: fakeNow.add(const Duration(days: 2)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.text('Box 2 → 3')));
    // The brand as ink (`primaryInk`, M100.27), not the fill role.
    expect(
      tester.widget<Text>(find.text('Box 2 → 3')).style!.color,
      theme.extension<AppSemanticColors>()!.primaryInk,
    );
    expect(
      tester.widget<Text>(find.textContaining('Due')).style!.color,
      theme.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('the connector keeps the control border', (tester) async {
    await pumpCardDetail(
      tester,
      loaded(
        events: <CardHistoryEventModel>[
          fakeHistoryEvent(id: 'e-1'),
          fakeHistoryEvent(id: 'e-2'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final semantic = semanticOf(tester);
    final line = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CardHistoryEventWidget).at(1),
            matching: find.byType(Container),
          ),
        )
        .firstWhere((container) => container.color != null);
    expect(line.color, semantic.borderControl);
  });

  testWidgets('an event is still announced as one sentence', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCardDetail(
      tester,
      loaded(
        events: <CardHistoryEventModel>[
          fakeHistoryEvent(id: 'e-1', previousBox: 2, nextBox: 3),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The badge, the timestamp and the lines are inside one node — a card per
    // event must not become four announcements per event.
    final semantics = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Self-assess, Scheduled, Remembered')),
    );
    expect(semantics.label, contains('Box from 2 to 3'));
    expect(semantics.label, isNot(contains('→')));
    expect(find.text('Box 2 → 3'), findsOneWidget);
    handle.dispose();
  });

  group('contrast, measured rather than assumed', () {
    for (final entry in <(String, ThemeData)>[
      ('light', buildLightTheme()),
      ('dark', buildDarkTheme()),
    ]) {
      final theme = entry.$2;
      final scheme = theme.colorScheme;
      final semantic = theme.extension<AppSemanticColors>()!;

      test('all three verdict tones clear 4.5:1 on the event card in '
          '${entry.$1}', () {
        // The badge is an outline on the card's own surface precisely so that
        // this holds for `warning` too — on `surfaceMuted` it is 4.00:1 in
        // light, which is why the concept's filled pill could not be copied.
        for (final ink in <Color>[
          semantic.success,
          semantic.warning,
          semantic.danger,
        ]) {
          expect(contrast(ink, scheme.surface), greaterThanOrEqualTo(4.5));
        }
        // The box line is the brand as ink since M100.27; `primary` itself
        // is Tokyo's fill and reads 4.33 here.
        expect(
          contrast(semantic.primaryInk, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('the connector and the panel accents clear their floors in '
          '${entry.$1}', () {
        expect(
          contrast(semantic.borderControl, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(3),
        );
        // The scheduler badge's ink on the muted panel is text, so 4.5; the
        // current box step is a fill, so 3:1 (WCAG 1.4.11). Until M100.27 both
        // were `primary`; the fill is Tokyo's verbatim now and reads 3.62 on
        // the light panel, which is a fill's bar and not a label's.
        expect(
          contrast(semantic.primaryInk, semantic.surfaceMuted),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(scheme.primary, semantic.surfaceMuted),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrast(semantic.onDueContainer, semantic.dueContainer),
          greaterThanOrEqualTo(4.5),
        );
        // The tonal Edit label. The container behind it is not what identifies
        // the control — the word is — so only the pair is held to a ratio.
        expect(
          contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('the box track steps stay apart from the track in ${entry.$1}', () {
        // Non-text, so 3:1: the filled part is what identifies the component,
        // and it has to be findable against the part that is not filled.
        expect(
          contrast(semantic.progressFill, semantic.progressTrack),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrast(scheme.primary, semantic.progressTrack),
          greaterThanOrEqualTo(3),
        );
      });
    }

    test('the current and completed steps share one colour in dark, which is '
        'why height carries them', () {
      final semantic = buildDarkTheme().extension<AppSemanticColors>()!;

      // Both are `primary` in dark since M100.18 — `progressFill` derives
      // from it, and the accent token that used to stand between them is gone.
      // Recorded so the day they diverge, the height difference can be
      // revisited rather than inherited.
      expect(semantic.progressFill, buildDarkTheme().colorScheme.primary);
    });
  });
}
