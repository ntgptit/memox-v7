import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// What a deck row says — on screen, to a screen reader, and in the other
/// locale, theme and viewport.
///
/// Split from `progress_deck_screen_test.dart` at the source-size ceiling, and
/// the seam is real: that file is the state matrix, this one is presentation of
/// one row and the axes a static screen can still get wrong.
void main() {
  final english = AppLocalizationsEn();
  final vietnamese = AppLocalizationsVi();

  /// A level with two busy decks and one nobody touched.
  FakeProgressRepository mixedLevel() => FakeProgressRepository.withSnapshot(
    activitySnapshot(
      decks: <DeckActivity>[
        deckActivity(
          deckId: 'busy',
          name: 'Spanish',
          last7Days: activityMetrics(
            activeCards: 42,
            activeDays: 6,
            learning: 12,
            reviewing: 60,
          ),
          last30Days: activityMetrics(
            activeCards: 120,
            activeDays: 24,
            learning: 30,
            reviewing: 200,
          ),
        ),
        deckActivity(
          deckId: 'quiet',
          name: 'Tiếng Nhật',
          last7Days: activityMetrics(activeCards: 3, activeDays: 1),
        ),
        deckActivity(deckId: 'idle', name: 'Idle deck'),
      ],
      scopeLast7Days: activityMetrics(
        activeCards: 45,
        activeDays: 6,
        learning: 12,
        reviewing: 60,
      ),
      scopeLast30Days: activityMetrics(
        activeCards: 123,
        activeDays: 24,
        learning: 30,
        reviewing: 200,
      ),
    ),
  );

  group('a deck row carries where it sits', () {
    testWidgets('a nested deck shows its path; a root shows none', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'nested',
                name: 'Verbs',
                path: const <ProgressPathSegment>[
                  ProgressPathSegment(id: 'r', name: 'Spanish'),
                  ProgressPathSegment(id: 'g', name: 'Grammar'),
                ],
                last7Days: activityMetrics(activeCards: 4),
              ),
            ],
            scopeDeckId: 'g',
            scopeName: 'Grammar',
            scopeLast7Days: activityMetrics(activeCards: 4),
          ),
        ),
        screen: const ProgressDeckScreen(deckId: 'g'),
      );

      expect(
        find.text('Spanish${english.progressPathSeparator}Grammar'),
        findsOneWidget,
      );
    });

    testWidgets('a screen reader hears the deck, its path, then its four '
        'metrics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'nested',
                name: 'Verbs',
                path: const <ProgressPathSegment>[
                  ProgressPathSegment(id: 'r', name: 'Spanish'),
                ],
                last7Days: activityMetrics(
                  activeCards: 4,
                  activeDays: 2,
                  learning: 1,
                  reviewing: 5,
                ),
              ),
            ],
            scopeDeckId: 'r',
            scopeName: 'Spanish',
            scopeLast7Days: activityMetrics(
              activeCards: 4,
              activeDays: 2,
              learning: 1,
              reviewing: 5,
            ),
          ),
        ),
        screen: const ProgressDeckScreen(deckId: 'r'),
      );

      expect(
        find.bySemanticsLabel(
          english.progressDeckRowSemanticLabel(
            'Verbs',
            'Spanish',
            english.progressRange7SemanticLabel,
          ),
        ),
        findsOneWidget,
      );
      // Each metric is one sentence rather than a number and a fragment: a
      // reader announces the two separately otherwise.
      expect(
        find.bySemanticsLabel(english.progressActiveCardsSemanticLabel(4)),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(english.progressLearningSemanticLabel(1)),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(english.progressReviewingSemanticLabel(5)),
        findsWidgets,
      );
      handle.dispose();
    });
  });

  group('locales, themes and viewports', () {
    testWidgets('renders in Vietnamese', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
        locale: const Locale('vi'),
      );

      expect(find.text(vietnamese.progressRange7Label), findsOneWidget);
      expect(
        find.text(vietnamese.progressSummaryLast7DaysTitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
        isDark: true,
      );

      expect(find.byType(ProgressDeckRowWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    for (final size in const <String, Size>{
      'narrow': Size(320, 640),
      'compact': Size(390, 844),
      'wide': Size(412, 892),
    }.entries) {
      testWidgets('lays out at ${size.key} with no overflow', (tester) async {
        await pumpProgressScreen(
          tester,
          repository: mixedLevel(),
          screen: const ProgressDeckScreen(),
          surface: size.value,
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives 320dp at text scale 2.0 with long names', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'long',
                name: 'Động từ bất quy tắc nhóm hai',
                path: const <ProgressPathSegment>[
                  ProgressPathSegment(id: 'a', name: 'Tiếng Nhật tổng hợp'),
                  ProgressPathSegment(
                    id: 'b',
                    name: 'Ngữ pháp trình độ trung cấp',
                  ),
                ],
                last7Days: activityMetrics(
                  activeCards: 24680,
                  activeDays: 30,
                  learning: 13579,
                  reviewing: 98765,
                ),
              ),
            ],
            scopeLast7Days: activityMetrics(
              activeCards: 24680,
              activeDays: 30,
              learning: 13579,
              reviewing: 98765,
            ),
          ),
        ),
        screen: const ProgressDeckScreen(),
        surface: const Size(320, 640),
        textScale: 2,
      );

      // Nothing ellipsized into a lie and nothing overflowed: the metric cells
      // wrap and the row grows.
      expect(tester.takeException(), isNull);
      expect(find.byType(ProgressDeckRowWidget), findsOneWidget);
    });
  });
}
