import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import '../../../visual_audit/study_audit_harness.dart';
import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// A repository whose entry read fails once and is then left in flight.
///
/// Two behaviours in one double on purpose: the retry has to produce a *second*
/// subscription to be a re-read at all, and `isRetrying` is only observable
/// while that second read has not landed. A fake that errored again immediately
/// would settle past the frame being asserted.
final class _FailingEntryRepository extends FakeStudyRepository {
  final List<StreamController<StudyEntrySummaryModel>> reads =
      <StreamController<StudyEntrySummaryModel>>[];

  @override
  Stream<StudyEntrySummaryModel> watchStudyEntry(
    String deckId, {
    required DateTime now,
  }) {
    final controller = StreamController<StudyEntrySummaryModel>();
    reads.add(controller);
    if (reads.length == 1) {
      controller.addError(StateError('the counts could not be read'));
    }

    return controller.stream;
  }
}

/// A repository whose entry read never lands.
///
/// A second double rather than a flag on the first, because the loading branch
/// cannot be observed through that one at all: its error is buffered on the
/// controller and delivered to the first listener's microtask, so by the end of
/// the very first `pump` the screen has already swapped to its failure face.
/// This one leaves the read in flight, which is the only state the spinner and
/// its label exist in.
final class _PendingEntryRepository extends FakeStudyRepository {
  final List<StreamController<StudyEntrySummaryModel>> reads =
      <StreamController<StudyEntrySummaryModel>>[];

  @override
  Stream<StudyEntrySummaryModel> watchStudyEntry(
    String deckId, {
    required DateTime now,
  }) {
    final controller = StreamController<StudyEntrySummaryModel>();
    reads.add(controller);

    return controller.stream;
  }
}

/// What the study entry screen says when the read behind it fails (SC-C3-14,
/// SC-C3-26).
///
/// **Measured through the real screen, not the section.** The defect was in the
/// three lines that build the `MxAsyncView`'s non-data branches, and the section
/// widget never sees any of them: the face was titled with the product name and
/// carried `studyNothingDueMessage`, so a user whose read had just failed was
/// told their deck was finished — the one sentence this screen must not say
/// when it does not know.
void main() {
  final english = AppLocalizationsEn();

  void closeReadsAfterwards(
    List<StreamController<StudyEntrySummaryModel>> reads,
  ) {
    addTearDown(() {
      for (final read in reads) {
        unawaited(read.close());
      }
    });
  }

  _FailingEntryRepository newRepository() {
    final repository = _FailingEntryRepository();
    closeReadsAfterwards(repository.reads);

    return repository;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    FakeStudyRepository repository,
  ) => tester.pumpWidget(
    studyScreenWith(
      repository,
      wrapForTest(
        const StudyEntryScreen(deckId: 'deck-1'),
        isScrollable: false,
      ),
    ),
  );

  Future<_FailingEntryRepository> pumpFailed(WidgetTester tester) async {
    final repository = newRepository();
    await pumpScreen(tester, repository);
    await tester.pumpAndSettle();

    return repository;
  }

  testWidgets('the loading state names the deck, not the product', (
    tester,
  ) async {
    final repository = _PendingEntryRepository();
    closeReadsAfterwards(repository.reads);
    await pumpScreen(tester, repository);
    // One frame only, and against the read that never lands: the screen is
    // still on its loading branch here, and `pumpAndSettle` would wait on a
    // stream that has nothing to emit.
    await tester.pump();

    expect(
      tester.widget<MxLoadingState>(find.byType(MxLoadingState)).semanticsLabel,
      english.studyEntryLoadingLabel,
    );
  });

  testWidgets('the failure names itself, and claims nothing about the deck', (
    tester,
  ) async {
    await pumpFailed(tester);

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(english.unexpectedErrorTitle), findsOneWidget);
    expect(find.text(english.studyEntryErrorMessage), findsOneWidget);
    // The product name survives in the app bar and nowhere else — it used to be
    // the heading of this face as well, so "MemoX" rendered twice on one screen.
    expect(find.text(english.appTitle), findsOneWidget);
    // The empty-state sentence belongs to the state that knows the deck is
    // finished. A failed read does not know that.
    expect(find.text(english.studyNothingDueMessage), findsNothing);
  });

  testWidgets('retry re-reads, and says so while it is running', (
    tester,
  ) async {
    final repository = await pumpFailed(tester);
    expect(repository.reads, hasLength(1));

    await tester.tap(find.text(english.retryAction));
    // One frame, not `pumpAndSettle`: the second read is deliberately left in
    // flight, and settling would wait for a stream that never emits.
    await tester.pump();

    expect(repository.reads, hasLength(2));
    // `invalidate` is a refresh and `MxAsyncView` holds the previous value
    // through one, so without the flag this frame is the identical error face.
    expect(
      tester.widget<MxErrorState>(find.byType(MxErrorState)).isRetrying,
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byType(MxActionButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a failure arriving in place announces itself', (tester) async {
    // Only two of the app's sixteen whole-screen failure faces carry a live
    // region today, so this is the grammar being adopted rather than one
    // already settled. It is needed here because the counts come from a stream:
    // the face can replace a populated screen with no navigation to announce it.
    final handle = tester.ensureSemantics();
    await pumpFailed(tester);

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
}
