import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/study_options_model.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_options_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// What Study Options says when the read fails (SC-C3-07).
///
/// **The face used to deny that anything had failed.** Under the red glyph it
/// printed `studyOptionsTitle` — the app-bar title one line above it, so the
/// screen name appeared twice — over `studyOptionsNextSessionNote`, a sentence
/// about a save that took effect. There was no retry, so the only way out was
/// the system back button.
///
/// The grammar asserted here is the one `settingsLoadErrorTitle` and
/// `reminderLoadErrorTitle` already use on the two other screens that read this
/// same pair of values: the title names the failure, the message advises, and
/// the retry re-subscribes the provider.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpOptions(
    WidgetTester tester,
    FakeStudyRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [studyRepositoryProvider.overrideWithValue(repository)],
        // `isScrollable: false`: this is a whole screen with its own
        // `Scaffold`, and the harness's default scroll view would hand it an
        // unbounded height — an assertion rather than a layout.
        child: wrapForTest(
          const StudyOptionsScreen(deckId: 'd1'),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the title names the failure, not the screen', (tester) async {
    await pumpOptions(tester, _FailingOptionsRepository());

    expect(find.text(english.studyOptionsLoadErrorTitle), findsOneWidget);
    // The copy is a different sentence from the app bar's, and the app bar is
    // the only place the screen name is still rendered — the face used to be
    // the second.
    expect(
      english.studyOptionsLoadErrorTitle,
      isNot(english.studyOptionsTitle),
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(english.studyOptionsTitle),
      ),
      findsOneWidget,
    );
    expect(find.text(english.studyOptionsTitle), findsOneWidget);
  });

  testWidgets('it does not claim the change takes effect next session', (
    tester,
  ) async {
    // BR-139's note describes a save that landed. Nothing has been saved here
    // — the screen could not even be filled in.
    await pumpOptions(tester, _FailingOptionsRepository());

    expect(find.text(english.studyOptionsNextSessionNote), findsNothing);
    expect(find.text(english.writeErrorMessage), findsOneWidget);
  });

  testWidgets('the retry re-reads the provider and the form arrives', (
    tester,
  ) async {
    // One failure, then a working read: the tap has to produce a *fresh*
    // subscription, not a repaint of the same snapshot.
    final repository = _FailingOptionsRepository();
    await pumpOptions(tester, repository);

    expect(find.widgetWithText(MxActionButton, english.retryAction), findsOne);

    await tester.tap(find.text(english.retryAction));
    await tester.pumpAndSettle();

    expect(repository.reads, 2);
    expect(find.byType(StudyOptionsSectionWidget), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);
  });

  testWidgets('the retry says it is running while the re-read is in flight', (
    tester,
  ) async {
    // `invalidate` is a refresh, and `MxAsyncView` holds the previous value
    // through one — so without `isRetrying` the tap repaints an identical face
    // and the user cannot tell the app noticed.
    final repository = _FailingOptionsRepository()..gate = Completer<void>();
    await pumpOptions(tester, repository);

    expect(
      tester.widget<MxErrorState>(find.byType(MxErrorState)).isRetrying,
      isFalse,
    );

    await tester.tap(find.text(english.retryAction));
    await tester.pump();

    expect(
      tester.widget<MxErrorState>(find.byType(MxErrorState)).isRetrying,
      isTrue,
    );

    repository.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(StudyOptionsSectionWidget), findsOneWidget);
  });
}

/// Fails the options read once, then answers normally.
///
/// [gate] holds the *second* read open so the in-flight retry can be observed;
/// left null the retry resolves in the same pump.
final class _FailingOptionsRepository extends FakeStudyRepository {
  int reads = 0;
  Completer<void>? gate;

  @override
  Future<StudyOptionsModel> effectiveOptions(String rootDeckId) async {
    reads += 1;
    if (reads == 1) {
      throw StateError('options read failed');
    }

    final pending = gate;
    if (pending != null) {
      await pending.future;
    }

    return super.effectiveOptions(rootDeckId);
  }
}
