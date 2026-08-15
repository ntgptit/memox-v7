import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';

import 'fake_progress_repository.dart';

/// The two levels the geometry suites measure, and the finder they measure with.
///
/// Top-level rather than closures inside one `main()`: the geometry file passed
/// the guard's 400-line ceiling and split in two, and a fixture copied into the
/// second file is a fixture that drifts from the first. Both files measure the
/// same screen, so they measure the same level.
FakeProgressRepository level() => FakeProgressRepository.withSnapshot(
  activitySnapshot(
    decks: <DeckActivity>[
      deckActivity(
        deckId: 'busy',
        name: 'Spanish',
        path: const <ProgressPathSegment>[
          ProgressPathSegment(id: 'r', name: 'Library'),
        ],
        last7Days: activityMetrics(
          activeCards: 42,
          activeDays: 6,
          learning: 12,
          reviewing: 60,
        ),
      ),
      deckActivity(
        deckId: 'quiet',
        name: 'Japanese',
        last7Days: activityMetrics(activeCards: 3, activeDays: 1),
      ),
    ],
    scopeLast7Days: activityMetrics(
      activeCards: 45,
      activeDays: 6,
      learning: 12,
      reviewing: 60,
    ),
  ),
);

/// Enough decks that the list genuinely scrolls.
FakeProgressRepository manyDecks() => FakeProgressRepository.withSnapshot(
  activitySnapshot(
    decks: <DeckActivity>[
      for (var i = 0; i < 20; i++)
        deckActivity(
          deckId: 'deck-$i',
          name: 'Deck $i',
          last7Days: activityMetrics(activeCards: 20 - i, activeDays: 3),
        ),
    ],
    scopeLast7Days: activityMetrics(activeCards: 210, activeDays: 7),
  ),
);

Finder metric(String label) => find.bySemanticsLabel(label);
