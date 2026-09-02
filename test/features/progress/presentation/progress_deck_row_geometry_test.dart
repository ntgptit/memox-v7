import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_level_fixtures.dart';
import 'support/progress_screen_harness.dart';

/// The row's own geometry, and the gap the list leaves at its end.
///
/// Split from `progress_deck_geometry_test.dart` at the guard's 400-line
/// ceiling. The seam is the subject: that file measures the *screen* — one
/// gutter for every band, the strip's step to the panel, a figure that must not
/// be truncated into a different figure — while this one measures a **row** and
/// the list it sits in. Both read the same fixtures from the same harness.
void main() {
  final english = AppLocalizationsEn();

  group('a row is a target and a place', () {
    testWidgets('every row clears the touch-target floor', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      for (var i = 0; i < 2; i++) {
        expect(
          tester.getRect(find.byType(ProgressDeckRowWidget).at(i)).height,
          greaterThanOrEqualTo(AppSizing.touchTarget),
        );
      }
    });

    testWidgets('the trailing affordance stays inside the row', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final row = tester.getRect(find.byType(ProgressDeckRowWidget).first);
      final chevron = tester.getRect(
        find
            .descendant(
              of: find.byType(ProgressDeckRowWidget).first,
              matching: find.byIcon(Icons.chevron_right),
            )
            .first,
      );

      expect(chevron.right, lessThanOrEqualTo(row.right));
      expect(chevron.left, greaterThan(row.left));
    });

    testWidgets('a long path wraps instead of pushing the metrics out', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'deep',
                name: 'Động từ bất quy tắc nhóm hai',
                path: const <ProgressPathSegment>[
                  ProgressPathSegment(id: 'a', name: 'Tiếng Nhật tổng hợp'),
                  ProgressPathSegment(
                    id: 'b',
                    name: 'Ngữ pháp trình độ trung cấp',
                  ),
                  ProgressPathSegment(id: 'c', name: 'Bài 12 — thể khả năng'),
                ],
                last7Days: activityMetrics(activeCards: 7, activeDays: 3),
              ),
            ],
            scopeLast7Days: activityMetrics(activeCards: 7, activeDays: 3),
          ),
        ),
        screen: const ProgressDeckScreen(),
        surface: const Size(320, 640),
      );

      final row = tester.getRect(find.byType(ProgressDeckRowWidget));
      final cards = tester.getRect(
        metric(english.progressActiveCardsSemanticLabel(7)).last,
      );

      expect(cards.left, greaterThanOrEqualTo(row.left));
      expect(cards.right, lessThanOrEqualTo(row.right));
      expect(tester.takeException(), isNull);
    });
  });

  group('the bottom of the list', () {
    testWidgets('the last row keeps its breathing space above the bar', (
      tester,
    ) async {
      // **Not "the row clears the bar"** - that assertion cannot fail.
      // `Scaffold` subtracts the navigation bar's height from the body's
      // `MediaQuery`, so no row can render behind it however the padding is
      // written. What is worth pinning is the inset itself: a list that ends
      // flush against the bar reads as cut off mid-way.
      //
      // It also has to be measured at the *end* of a scroll that really
      // happens - a fixture short enough to fit the viewport makes the drag a
      // no-op and the measurement meaningless.
      await pumpProgressApp(tester, repository: manyDecks());

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(position.maxScrollExtent, greaterThan(0));

      final lastRow = tester.getRect(find.byType(ProgressDeckRowWidget).last);
      final viewport = tester.getRect(find.byType(CustomScrollView));
      final bar = tester.getRect(find.byType(MxNavigationBar));

      // `lg`, the one step every list in the app now leaves under its last row
      // (M99.26). It was `xxl` here and `lg` on the deck list and Study Home,
      // for the same reason on all three.
      expect(viewport.bottom - lastRow.bottom, AppSpacing.lg);
      expect(lastRow.bottom, lessThanOrEqualTo(bar.top));
    });
  });
}
