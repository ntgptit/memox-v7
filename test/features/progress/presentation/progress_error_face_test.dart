import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// The error face of the Progress screen, and what Retry does to it (UC-12 E1,
/// E2, wireframe S-e and S-e').
///
/// Split from `progress_screen_test.dart`, which keeps the four faces that are
/// only a state pumped and read. The seam is the interaction: everything here
/// presses something and then asks what changed, and this is the one face on
/// the screen with a control at all. The split was forced by the guard's
/// 400-line ceiling once the merge gave the shared helper the level's fixtures
/// too, and it is the right seam anyway.
void main() {
  final english = AppLocalizationsEn();

  /// The error face of the Progress screen and what Retry does to it (UC-12 E1,
  /// E2, wireframe S-e and S-e').
  ///
  /// Split from `progress_screen_test.dart`, which keeps the four faces that are
  /// just a state pumped and read. The seam is the interaction: everything here
  /// presses something and then asks what changed — the one face on this screen
  /// that has a control at all. The split was forced by the guard's 400-line
  /// ceiling once the merge added the level's fixtures to the shared helper, and
  /// it is the right seam anyway.

  group('error (S-e)', () {
    testWidgets('offers Retry and says nothing about the database', (
      tester,
    ) async {
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);

      repository.fail(
        const DatabaseFailure(message: 'no such table: study_answers'),
      );
      await tester.pump();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.progressErrorTitle), findsOneWidget);
      expect(find.text(english.progressErrorRetryAction), findsOneWidget);
      expect(find.textContaining('study_answers'), findsNothing);
    });

    testWidgets('Retry is a real target, and it is labelled', (tester) async {
      // The empty face's CTA had this and the error face did not, which is the
      // asymmetry worth closing: Retry is the only control on the one screen
      // state a user reaches by something going wrong.
      final handle = tester.ensureSemantics();
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the error face announces itself to a reader already on the '
        'screen', (tester) async {
      // The failure replaces a spinner in place. Without `liveRegion` a
      // TalkBack user is told nothing at all and waits on a screen that has
      // already given up.
      final handle = tester.ensureSemantics();
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      expect(
        tester
            .getSemantics(find.byType(MxErrorState))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('Retry re-opens the read', (tester) async {
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();
      expect(repository.subscriptionCount, 1);

      final Rect idleButton = tester.getRect(find.byType(MxActionButton));

      await tester.tap(find.text(english.progressErrorRetryAction));
      await tester.pump();

      expect(repository.subscriptionCount, 2);

      // The face stays — this is a re-read, not a new screen — but the control
      // now says the tap was received. `MxAsyncView` skips the loading branch on
      // a refresh for every screen, so without the button's own busy state a
      // person pressed Retry and nothing moved at all for as long as the read
      // took.
      expect(find.byType(MxLoadingState), findsNothing);
      expect(find.byType(MxErrorState), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MxActionButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      // **`findsOneWidget` on the label is not enough, and that is the point.**
      // `MxActionButton` keeps the label in the tree either way: at
      // `opacity 0` under the spinner by default, or beside it when
      // `shouldKeepLabelWhileLoading` is on. The first version of this
      // assertion could not tell those apart, so a change to the second shape —
      // which widens the button by `AppIconSize.sm + AppSpacing.sm` under the
      // finger that just pressed it — would have been invisible to the suite.
      //
      // The default is the right trade here: the rect must not move. Both halves
      // are asserted, because only together do they say which shape is on screen.
      expect(find.text(english.progressErrorRetryAction), findsOneWidget);
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text(english.progressErrorRetryAction),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0,
        reason:
            'the label holds its slot rather than being laid out beside '
            'the spinner',
      );
      expect(tester.getRect(find.byType(MxActionButton)), idleButton);
    });

    testWidgets('a Retry that fails again stays on the error face and opens '
        'nothing more (UC-12 E2)', (tester) async {
      // E2 is the half of the retry contract that a passing retry cannot show.
      // The screen must come back to the same face and then **stop** — a
      // controller that re-subscribed on its own would turn a database that is
      // down into a loop against it, and the person would see a spinner that
      // never resolves instead of the Retry they just pressed.
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      await tester.tap(find.text(english.progressErrorRetryAction));
      await tester.pump();
      repository.fail(const DatabaseFailure(message: 'read failed again'));
      await tester.pump();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.progressErrorRetryAction), findsOneWidget);

      // Five seconds of nothing happening: the subscription count is still the
      // two the user asked for, not a third nobody did.
      await tester.pump(const Duration(seconds: 5));
      expect(repository.subscriptionCount, 2);
      expect(find.byType(MxErrorState), findsOneWidget);

      // **And the way out is still there.** The busy state disables the button,
      // which is right while a read is in flight and would be a trap if it
      // outlived one: an error face whose only control is inert is an error face
      // with no exit. A second failure must give the button back, and it must
      // work — asserted by pressing it, not by reading a flag, because a flag
      // can be right while the tap goes nowhere.
      expect(
        find.descendant(
          of: find.byType(MxActionButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );

      await tester.tap(find.text(english.progressErrorRetryAction));
      await tester.pump();
      expect(repository.subscriptionCount, 3);
    });
  });
}
