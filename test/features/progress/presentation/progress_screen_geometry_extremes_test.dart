import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_week_bar_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_week_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// The cells the viewport matrix cannot cover, and the one measurement that
/// needs the production shell.
///
/// Split from `progress_screen_geometry_test.dart`, which runs G1–G11 across
/// five viewport × locale cells. The seam is the input rather than the
/// assertion: everything here changes the *content* — a three-digit streak, a
/// failed read, a week of zeroes — or the *host*, in G12's case the real
/// `AppNavigationShell`. Keeping them in one file put it past the guard's
/// 400-line ceiling, and the ceiling is right: the matrix half is read by
/// somebody checking a viewport, this half by somebody checking a state.
void main() {
  final english = AppLocalizationsEn();

  FakeProgressRepository seeded({List<int>? totals, int streakDays = 5}) =>
      FakeProgressRepository(
        initial: progressOverviewFixture(
          totals: totals ?? const <int>[12, 0, 6, 143, 3, 9, 8],
          streakDays: streakDays,
          today: DateTime.utc(2026, 8, 12),
        ),
      );

  Rect rectOf(WidgetTester tester, Type type) =>
      tester.getRect(find.byType(type));

  group('the extremes the copy has to survive', () {
    testWidgets('a three-digit streak wraps without moving the shared edges', (
      tester,
    ) async {
      // The hero's headline is `displayLarge`; at 320dp with a 2.0 text scale
      // "999 days" cannot fit on one line, and W6 forbids buying the line back
      // by shrinking the type. What must hold is that it *wraps* — the card
      // grows taller and its left and right edges do not move.
      await pumpProgressScreen(
        tester,
        repository: seeded(streakDays: 999),
        surface: const Size(320, 720),
        textScale: 2,
      );

      final hero = rectOf(tester, ProgressStreakHeroWidget);
      final today = rectOf(tester, ProgressTodayWidget);
      final week = rectOf(tester, ProgressWeekWidget);

      expect(hero.left, AppSpacing.md);
      expect(today.left, hero.left);
      expect(week.left, hero.left);
      expect(today.right, hero.right);
      expect(week.right, hero.right);
      expect(find.text(english.progressStreakDaysLabel(999)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a three-digit streak survives Vietnamese at 320 @ 2.0', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: seeded(streakDays: 999),
        surface: const Size(320, 720),
        textScale: 2,
        locale: const Locale('vi'),
      );

      final hero = rectOf(tester, ProgressStreakHeroWidget);
      final week = rectOf(tester, ProgressWeekWidget);

      expect(week.left, hero.left);
      expect(week.right, hero.right);
      expect(tester.takeException(), isNull);
    });

    /// Nothing on the screen breaks a word in half at the tightest cell.
    ///
    /// **The assertion the rest of this file was missing.** Two tests already
    /// rendered `320 @ 2.0` in both locales and both were green while the hero
    /// drew `5` / `day` / `s`: they measured the card's edges, which do not
    /// move, and asked `takeException()`, which a mid-word break does not
    /// throw. Overflow is loud; breaking inside a word is silent.
    ///
    /// `getMinIntrinsicWidth` is the width of the widest run the engine cannot
    /// break, so comparing it with the box is exactly the question "did this
    /// have to break a word to fit". Asserted over every paragraph rather than
    /// the headline alone: the headline is where it happened, but the property
    /// is one the whole screen has to hold.
    for (final ({String name, Locale locale}) language
        in const <({String name, Locale locale})>[
          (name: 'en', locale: Locale('en')),
          (name: 'vi', locale: Locale('vi')),
        ]) {
      for (final int streak in const <int>[0, 1, 5, 14, 999]) {
        testWidgets('no word is broken in half at 320 @ 2.0 · '
            '${language.name} · streak $streak', (tester) async {
          await pumpProgressScreen(
            tester,
            repository: seeded(streakDays: streak),
            surface: const Size(320, 720),
            textScale: 2,
            locale: language.locale,
          );

          final paragraphs = find
              .byType(RichText)
              .evaluate()
              .map((element) => element.renderObject! as RenderParagraph)
              .toList();
          expect(paragraphs, isNotEmpty);

          for (final paragraph in paragraphs) {
            expect(
              paragraph.getMinIntrinsicWidth(double.infinity),
              lessThanOrEqualTo(paragraph.size.width),
              reason:
                  'unbreakable run wider than its box in '
                  '"${paragraph.text.toPlainText()}"',
            );
          }
        });
      }
    }

    testWidgets('the error face survives Vietnamese at 320 @ 2.0', (
      tester,
    ) async {
      // The tightest cell on the screen, and the one the matrix had never
      // rendered: the Vietnamese error copy is two sentences plus a button, at
      // twice the type size, on the narrowest viewport the app supports. It
      // fits only because `MxErrorState` carries its own scroll view — which is
      // a property of a shared component that this screen does not own, so it
      // is worth an assertion here rather than an assumption.
      final repository = FakeProgressRepository();
      await pumpProgressScreen(
        tester,
        repository: repository,
        surface: const Size(320, 568),
        textScale: 2,
        locale: const Locale('vi'),
      );
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The retry stays reachable rather than being pushed past the bottom
      // edge: an error face you cannot act on is an error face with no exit.
      await tester.ensureVisible(find.byType(MxActionButton).first);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the busiest day fills the track and a zero day fills none', (
    tester,
  ) async {
    await pumpProgressScreen(
      tester,
      repository: seeded(totals: const <int>[0, 1, 2, 3, 4, 5, 10]),
    );

    final bars = tester
        .widgetList<ProgressWeekBarWidget>(find.byType(ProgressWeekBarWidget))
        .toList();

    expect(bars.first.fraction, 0);
    expect(bars.last.fraction, 1);
  });

  testWidgets('a week with no activity divides by nothing', (tester) async {
    // The busiest day is zero here — a real state for somebody with older
    // history and a quiet fortnight. Every bar is empty and none of them is
    // `NaN`, which is what an unguarded `total / busiest` would produce and
    // what would then throw inside the layout rather than in the arithmetic.
    await pumpProgressScreen(
      tester,
      repository: FakeProgressRepository(
        initial: progressOverviewFixture(
          totals: const <int>[0, 0, 0, 0, 0, 0, 0],
          streakDays: 0,
          today: DateTime.utc(2026, 8, 12),
          hasLifetimeActivity: true,
        ),
      ),
    );

    final bars = tester
        .widgetList<ProgressWeekBarWidget>(find.byType(ProgressWeekBarWidget))
        .toList();

    expect(bars, hasLength(7));
    expect(bars.every((bar) => bar.fraction == 0), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the last section clears the bottom navigation bar (G12)', (
    tester,
  ) async {
    // Mounted through the real shell, because the claim is about the shell: a
    // `Scaffold` with a `bottomNavigationBar` removes the bar's height from its
    // body's `MediaQuery`, so no manual inset is needed — and adding one would
    // reserve the space twice.
    await pumpProgressApp(tester, repository: seeded());
    await tester.dragUntilVisible(
      find.byType(ProgressWeekWidget),
      find.byType(SingleChildScrollView),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    final week = tester.getRect(find.byType(ProgressWeekWidget));
    final bar = tester.getRect(find.byType(NavigationBar));

    expect(week.bottom, lessThanOrEqualTo(bar.top));
  });
}
