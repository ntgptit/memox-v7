import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/theme/app_icon_size.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_workload_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../deck/presentation/support/fake_deck_repository.dart';
import '../domain/support/fake_study_home_repository.dart';
import '../domain/support/fake_study_repository.dart';

/// The geometry Study Home is pinned to (UC-12, wireframe `m5-study-home.md`).
///
/// **Measured on the production tree, not on a widget built for the test.** The
/// screen is pumped through the real router inside the real shell, because half
/// of what is asserted here — the gutter, the clearance above the bottom bar —
/// is a property of what the screen is mounted *in*. A bare pump would measure a
/// layout the app never renders.
///
/// Every number below is read out of the tree with `getRect` and compared to a
/// token, never to a literal. A literal is how a spacing change passes review by
/// changing the token and the test in one commit.
void main() {
  final english = AppLocalizationsEn();
  final now = DateTime.utc(2026, 8, 13, 9);

  late FakeStudyHomeRepository homeRepository;

  tearDown(() => homeRepository.dispose());

  Future<void> pumpHome(
    WidgetTester tester, {
    Size surface = const Size(393, 852),
    double textScale = 1,
    List<StudyHomeDeckModel>? decks,
    Locale? locale,
    bool failing = false,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The locale is forced through the platform dispatcher rather than through
    // a parameter on `MemoxApp`: production has exactly one way to resolve a
    // locale, and adding a test-only override to the app root would make the
    // thing under test different from the thing that ships.
    if (locale != null) {
      tester.platformDispatcher.localesTestValue = <Locale>[locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    }

    homeRepository = FakeStudyHomeRepository(
      initial: fakeStudyHome(resume: fakeStudyHomeResume(), decks: decks),
      failure: failing ? StateError('read failed') : null,
    );
    final router = createAppRouter(initialLocation: RoutePaths.study);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          studyHomeRepositoryProvider.overrideWithValue(homeRepository),
          clockProvider.overrideWithValue(() => now),
          utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
        ],
        // **`fromView`, then `copyWith`** — not a bare `MediaQueryData`. A
        // fresh one carries `Size.zero`, which makes every breakpoint read as
        // compact: the first version of this file measured a 12dp gutter on a
        // 393dp screen and the number was right about a screen the app never
        // renders.
        child: MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: MemoxApp(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('gutters and shared edges', () {
    testWidgets('the resume card and every row share both edges', (
      tester,
    ) async {
      await pumpHome(tester);

      final resume = tester.getRect(find.byType(StudyHomeResumeSectionWidget));
      final rows = find.byType(StudyHomeDeckItemWidget);
      final first = tester.getRect(rows.first);
      final last = tester.getRect(rows.last);

      // One content column: a resume band inset differently from the rows under
      // it reads as two screens stacked, which is the exact failure a shared
      // gutter exists to prevent.
      expect(first.left, resume.left);
      expect(first.right, resume.right);
      expect(last.left, resume.left);
      expect(last.right, resume.right);
    });

    testWidgets('the column is inset by the screen gutter', (tester) async {
      await pumpHome(tester);

      final screen = tester.getRect(find.byType(MaterialApp));
      final row = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      expect(row.left - screen.left, AppSpacing.lg);
      expect(screen.right - row.right, AppSpacing.lg);
    });

    testWidgets('at 320dp the gutter steps down with the breakpoint', (
      tester,
    ) async {
      await pumpHome(tester, surface: const Size(320, 568));

      final screen = tester.getRect(find.byType(MaterialApp));
      final row = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      // `mxScreenGutter` drops below `AppBreakpoints.compact`, and the screen
      // takes it from there rather than re-deriving the rule — a second copy is
      // how the two drift apart below 360, where nobody looks.
      expect(row.left - screen.left, AppSpacing.md);
    });
  });

  group('rhythm', () {
    testWidgets('rows are separated by one step, not by a section break', (
      tester,
    ) async {
      await pumpHome(tester);

      final rows = find.byType(StudyHomeDeckItemWidget);
      final first = tester.getRect(rows.at(0));
      final second = tester.getRect(rows.at(1));

      expect(second.top - first.bottom, AppSpacing.md);
    });

    testWidgets('the list heading sits a section break below the resume', (
      tester,
    ) async {
      await pumpHome(tester);

      final resume = tester.getRect(find.byType(StudyHomeResumeSectionWidget));
      final heading = tester.getRect(find.text(english.studyHomeNextTitle));

      // `xl`, not `md`: the seam between "what you were doing" and "what you
      // could do next" is a section boundary, and a break the size of the gap
      // between two cards would make the heading read as another row.
      expect(heading.top - resume.bottom, AppSpacing.xl);
    });

    testWidgets('the first row sits one step below the list heading', (
      tester,
    ) async {
      // **Unmeasured until now, and it moved under a refactor.** The row gap
      // was trailing each row and became leading, so this distance stopped
      // coming from a standalone `SizedBox` and started coming from the loop's
      // first iteration. It survived by construction rather than by a gate,
      // which is the situation a gate exists for.
      await pumpHome(tester);

      final heading = tester.getRect(find.text(english.studyHomeNextTitle));
      final first = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      expect(first.top - heading.bottom, AppSpacing.md);
    });
  });

  group('touch targets and clearance', () {
    testWidgets('every action clears the 48dp floor', (tester) async {
      await pumpHome(tester);

      for (final label in <String>[
        english.studyHomeResumeAction,
        english.studyHomeStudyAction,
      ]) {
        final buttons = find.widgetWithText(ButtonStyleButton, label);
        for (var i = 0; i < buttons.evaluate().length; i++) {
          expect(
            tester.getRect(buttons.at(i)).height,
            greaterThanOrEqualTo(AppSpacing.minimumTouchTarget),
            reason: '$label #$i is under the touch floor',
          );
        }
      }
    });

    testWidgets('the last row clears the bottom bar at the end of the scroll', (
      tester,
    ) async {
      // Enough rows that the list actually overscrolls: with two decks the
      // content is shorter than the viewport, the scroll never moves, and the
      // last row sits a hundred points clear of the bar for a reason that has
      // nothing to do with the padding under test.
      await pumpHome(
        tester,
        decks: <StudyHomeDeckModel>[
          for (var i = 0; i < 12; i++)
            fakeStudyHomeDeck(
              deckId: 'deck-$i',
              deckName: 'Deck number $i',
              newCount: 12 - i,
            ),
        ],
      );

      // **Jumped to the end, not flung at it.** A drag is clamped by the
      // physics and a fling settles wherever its simulation runs out, so both
      // measure a position nobody chose — the first attempt here stopped 177
      // points short and the assertion was about the gesture, not the padding.
      final controller = Scrollable.of(
        tester.element(find.byType(StudyHomeDeckItemWidget).first),
      ).position;
      //
      // Jumped until it settles, because the first jump changes the extent it
      // was aiming at: scrolling makes `MxContentShell` draw its hairline, and
      // the chrome that appears takes height out of the body the list lives in.
      for (var attempt = 0; attempt < 5; attempt++) {
        controller.jumpTo(controller.maxScrollExtent);
        await tester.pumpAndSettle();
      }

      final list = find.byType(ListView);
      final last = tester.getRect(find.byType(StudyHomeDeckItemWidget).last);
      final viewport = tester.getRect(list);
      final bar = tester.getRect(find.byType(MxNavigationBar));

      // **The scroll really reached its end**, so the clearance below is a fact
      // about the padding and not about where the finger stopped.
      expect(controller.pixels, controller.maxScrollExtent);

      // **The gap, not the inequality.** `last.bottom <= bar.top` was the first
      // version of this and it could not fail: the shell puts the bar on the
      // outer `Scaffold`, which takes its height out of the body's constraints,
      // so branch content is laid out entirely above it whatever padding the
      // list carries — deleting the padding left the assertion green. What is
      // actually promised is the list's own bottom gutter, measured against the
      // viewport that gutter lives in.
      expect(
        viewport.bottom - last.bottom,
        mxScreenGutter(
          tester.element(find.byType(StudyHomeDeckItemWidget).last),
        ),
      );
      // And the viewport itself never runs under the bar.
      expect(viewport.bottom, lessThanOrEqualTo(bar.top));
    });
  });

  group('inside one deck row', () {
    /// Anything under the first row, found by type or by text.
    Finder inRow(Finder matching) => find.descendant(
      of: find.byType(StudyHomeDeckItemWidget).first,
      matching: matching,
    );

    testWidgets('the card pads its content by one step on every side', (
      tester,
    ) async {
      await pumpHome(tester);

      final card = tester.getRect(inRow(find.byType(MxCard)).first);
      final name = tester.getRect(inRow(find.text('Everyday Korean')).first);
      final action = tester.getRect(inRow(find.byType(MxActionButton)).first);

      expect(name.left - card.left, AppSpacing.lg);
      expect(name.top - card.top, AppSpacing.lg);
      expect(card.bottom - action.bottom, AppSpacing.lg);
      // The fourth side, which the first version of this test called "every
      // side" without measuring. `CrossAxisAlignment.stretch` makes the name's
      // right edge the content edge, so this is exact rather than incidental.
      expect(card.right - name.right, AppSpacing.lg);
    });

    testWidgets('the resume card pads its content the same way', (
      tester,
    ) async {
      // G6 says "Resume card *and* row", and the row-scoped finder above could
      // not see the resume card at all — so the half of the rule about the one
      // surface that steps away from `surface` was going unmeasured.
      await pumpHome(tester);

      final resume = find.byType(StudyHomeResumeSectionWidget);
      final card = tester.getRect(
        find.descendant(of: resume, matching: find.byType(MxCard)).first,
      );
      final heading = tester.getRect(
        find
            .descendant(
              of: resume,
              matching: find.text(english.studyHomeResumeTitle),
            )
            .first,
      );
      final action = tester.getRect(
        find
            .descendant(of: resume, matching: find.byType(MxActionButton))
            .first,
      );

      expect(heading.left - card.left, AppSpacing.lg);
      expect(heading.top - card.top, AppSpacing.lg);
      expect(card.right - heading.right, AppSpacing.lg);
      expect(card.bottom - action.bottom, AppSpacing.lg);
    });

    testWidgets('the identity block breaks at xs, then sm before the counts', (
      tester,
    ) async {
      await pumpHome(tester);

      final name = tester.getRect(inRow(find.text('Everyday Korean')).first);
      final scheduler = tester.getRect(
        inRow(find.text(english.schedulerEightBoxShortLabel)).first,
      );
      final workload = tester.getRect(
        inRow(find.byType(StudyHomeWorkloadItemWidget)).first,
      );

      // Line breaks inside one block, so the smallest step; then one more for
      // the seam between what the deck *is* and what is waiting in it.
      expect(scheduler.top - name.bottom, AppSpacing.xs);
      expect(workload.top - scheduler.bottom, AppSpacing.sm);
    });

    testWidgets('the verb sits a section step below the counts', (
      tester,
    ) async {
      await pumpHome(tester);

      final workload = tester.getRect(
        inRow(find.byType(StudyHomeWorkloadItemWidget)).first,
      );
      final action = tester.getRect(inRow(find.byType(MxActionButton)).first);

      // Information above, verb below: one step more than the line breaks
      // inside the block, and one step less than a break between two cards.
      expect(action.top - workload.bottom, AppSpacing.md);
    });

    testWidgets(
      'a workload glyph rides the body baseline, one xs from its word',
      (tester) async {
        await pumpHome(tester);

        final icon = tester.getRect(inRow(find.byIcon(Icons.history)).first);
        final label = tester.getRect(
          inRow(find.text(english.studyHomeOverdueLabel(2))).first,
        );

        expect(icon.height, AppIconSize.sm);
        expect(icon.width, AppIconSize.sm);
        expect(label.left - icon.right, AppSpacing.xs);
        // Same band as the text it belongs to — a glyph on its own baseline reads
        // as a separate element rather than as part of the count.
        expect(icon.top, label.top);
        expect(icon.bottom, label.bottom);
      },
    );

    testWidgets('the three counts are one step apart', (tester) async {
      await pumpHome(tester);

      final overdue = tester.getRect(
        inRow(find.text(english.studyHomeOverdueLabel(2))).first,
      );
      final dueToday = tester.getRect(inRow(find.byIcon(Icons.today)).first);

      // Measured end-of-group to start-of-next-group, which is what `Wrap`'s
      // `spacing` actually controls — the icon leads each group.
      expect(dueToday.left - overdue.right, AppSpacing.md);
    });
  });

  group('the states share one frame', () {
    testWidgets('the error state is inset like the empty states, not more', (
      tester,
    ) async {
      // Both appear on this screen, and both centre themselves inside their own
      // padding. Adding the screen gutter to one of them made the error copy
      // narrower than the empty copy for no reason a reader could see.
      await pumpHome(tester, failing: true);

      final shell = tester.getRect(find.byType(MxContentShell));
      final error = tester.getRect(find.byType(MxErrorState));

      expect(error.left, shell.left);
      expect(error.width, shell.width);
    });

    testWidgets('an empty library is inset the same way', (tester) async {
      await pumpHome(tester, decks: const <StudyHomeDeckModel>[]);

      final shell = tester.getRect(find.byType(MxContentShell));
      final empty = tester.getRect(find.byType(MxEmptyState));

      expect(empty.left, shell.left);
      expect(empty.width, shell.width);
    });
  });

  group('across widths and locales', () {
    testWidgets('412dp keeps the anatomy and only widens the column', (
      tester,
    ) async {
      await pumpHome(tester, surface: const Size(412, 892));

      final screen = tester.getRect(find.byType(MaterialApp));
      final row = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      expect(row.left - screen.left, AppSpacing.lg);
      expect(screen.right - row.right, AppSpacing.lg);
      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Vietnamese renders every band without overflowing', (
      tester,
    ) async {
      // The locale had never been rendered by any test — ARB parity checks the
      // keys, not what the longer strings do to a layout built for English.
      await pumpHome(tester, locale: const Locale('vi'));

      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);
      expect(find.byType(StudyHomeDeckItemWidget), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Vietnamese at 320dp and textScaler 2.0 still fits', (
      tester,
    ) async {
      // **The worst case, not the default one.** The three variables that make
      // this hard — the longer locale, four-digit counts and doubled text — had
      // never met: the VI test used the two-digit fixture and the big-number
      // fixture ran in English.
      await pumpHome(
        tester,
        surface: const Size(320, 568),
        textScale: 2,
        locale: const Locale('vi'),
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(
            deckId: 'long',
            deckName: 'Từ vựng chuyên ngành công nghệ thông tin',
            overdueCount: 128,
            dueTodayCount: 64,
            newCount: 256,
          ),
        ],
      );

      expect(tester.takeException(), isNull);

      // **Overflow throws; ellipsis does not.** Every metric label is
      // `maxLines: 1, overflow: ellipsis`, so truncation is the widget's own
      // quiet default — a test that only watched for an exception would call a
      // cut-off count a pass. Asked directly instead.
      final truncated = tester
          .renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(StudyHomeWorkloadItemWidget),
              matching: find.byType(RichText),
            ),
          )
          .where((paragraph) => paragraph.didExceedMaxLines)
          .toList();
      expect(
        truncated,
        isEmpty,
        reason: 'a workload count was cut off rather than wrapped',
      );
    });
  });

  group('long content', () {
    testWidgets('a long deck name wraps to two lines and stops', (
      tester,
    ) async {
      await pumpHome(
        tester,
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(
            deckId: 'long',
            deckName:
                'Từ vựng chuyên ngành công nghệ thông tin và truyền thông '
                'dành cho kỳ thi cuối khoá',
            overdueCount: 128,
            dueTodayCount: 64,
            newCount: 256,
          ),
        ],
      );

      final name = tester.widget<Text>(
        find.descendant(
          of: find.byType(StudyHomeDeckItemWidget),
          matching: find.textContaining('Từ vựng chuyên ngành'),
        ),
      );

      expect(name.maxLines, 2);
      expect(name.overflow, TextOverflow.ellipsis);
      // And the row still holds its verb: a name long enough to push the action
      // out of the card is the failure this cap exists to prevent.
      expect(
        find.descendant(
          of: find.byType(StudyHomeDeckItemWidget),
          matching: find.text(english.studyHomeStudyAction),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no overflow at 320dp with textScaler 2.0', (tester) async {
      await pumpHome(
        tester,
        surface: const Size(320, 568),
        textScale: 2,
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(
            deckId: 'long',
            deckName: 'Từ vựng chuyên ngành công nghệ thông tin',
            overdueCount: 128,
            dueTodayCount: 64,
            newCount: 256,
          ),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });
}
