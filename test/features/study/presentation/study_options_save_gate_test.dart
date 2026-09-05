import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// When Save is offered on a deck's own options form (SC-C3-08).
///
/// **The identical form on Settings has gated Save on dirty-and-valid since
/// BR-211; this one lit it over a pristine draft and over an unparsable one.**
/// Two disabled-state grammars for one form — same two values, same labels,
/// same `studyOptionsSave` word — and the field's error only appeared once the
/// save had gone out and been refused.
///
/// The gate here is `StudyCardLimit.parse`, the same parser the use case runs,
/// so there is no second opinion about the bounds.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpOptions(
    WidgetTester tester,
    FakeStudyRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [studyRepositoryProvider.overrideWithValue(repository)],
        // `isScrollable: false`: a whole screen with its own `Scaffold`; the
        // harness's scroll view would hand it an unbounded height.
        child: wrapForTest(
          const StudyOptionsScreen(deckId: 'd1'),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MxActionButton saveButton(WidgetTester tester) =>
      tester.widget<MxActionButton>(
        find.widgetWithText(MxActionButton, english.studyOptionsSave),
      );

  testWidgets('Save is disabled while the draft is pristine', (tester) async {
    // A bright Save over an unchanged draft reads as "something is waiting to
    // be saved" when nothing is.
    await pumpOptions(tester, FakeStudyRepository(cardLimit: 30));

    expect(find.text('30'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('a real edit enables it', (tester) async {
    await pumpOptions(tester, FakeStudyRepository(cardLimit: 30));

    await tester.enterText(find.byType(MxTextField), '40');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('re-typing the same value in another shape does not', (
    tester,
  ) async {
    // Dirtiness is compared by parsed value, not by string: `"030"` is the same
    // session ceiling as a stored 30, and lighting Save for it promises a save
    // that changes nothing.
    await pumpOptions(tester, FakeStudyRepository(cardLimit: 30));

    await tester.enterText(find.byType(MxTextField), '030');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('an out-of-range limit disables Save before any submit', (
    tester,
  ) async {
    // The old form let this through and waited for the write to refuse it — a
    // control promising an action it would immediately reject.
    await pumpOptions(tester, FakeStudyRepository(cardLimit: 30));

    await tester.enterText(find.byType(MxTextField), '9999');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('a non-number disables it too', (tester) async {
    await pumpOptions(tester, FakeStudyRepository(cardLimit: 30));

    await tester.enterText(find.byType(MxTextField), '');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('the field explains itself on blur, without a round trip', (
    tester,
  ) async {
    // `enterText` leaves the field focused, and the message is deferred to blur
    // so the field does not grow and shrink on every keystroke that crosses the
    // valid/invalid boundary.
    final repository = FakeStudyRepository(cardLimit: 30);
    await pumpOptions(tester, repository);

    await tester.enterText(find.byType(MxTextField), '9999');
    await tester.pump();

    expect(
      find.text(english.studyOptionsCardLimitOutOfRange(1, 200)),
      findsNothing,
    );

    FocusScope.of(tester.element(find.byType(MxTextField))).unfocus();
    await tester.pump();

    expect(
      find.text(english.studyOptionsCardLimitOutOfRange(1, 200)),
      findsOneWidget,
    );
    // Nothing was sent to be refused — the form knew on its own.
    expect(repository.savedOptions, isEmpty);
  });
}
