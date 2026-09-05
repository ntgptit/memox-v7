@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_options_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../features/study/domain/support/fake_study_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';

/// Device-faithful renders of the study options screen (UC-15, BR-147, BR-148)
/// — one of the four production screens that had no picture of itself at all.
///
/// **It has no route, so it is reached the way a user reaches it.** The screen
/// is pushed by `StudyEntryScreen._openOptions` with a `MaterialPageRoute` on
/// the *branch* navigator, which is what keeps the bottom bar under it. There
/// is no location to mount, so the render mounts `/decks/<id>/study` through
/// the production router and then taps the `Icons.tune` action — photographing
/// the pushed route rather than the widget, for the reason
/// `deck_starter_demo_test.dart` records: a bare pump loses the shell's
/// navigation bar and its safe area, and those are exactly the parts a
/// layout review has to score.
///
/// The state is the populated one: a deck carrying its **own** override
/// (BR-212), so the card limit is a number the user chose, the order pill on
/// `Shuffled` is a selection rather than the default, and the two things that
/// only exist for an override — the note and `Use app defaults` — are in the
/// picture. The empty variant of this screen does not exist; the values always
/// resolve to something.
void main() {
  final l10n = AppLocalizationsEn();

  /// The tune action in the study entry's app bar, matched on the accessible
  /// name rather than on the glyph.
  ///
  /// The label is what the control promises to do, and it is the thing that
  /// has to keep pointing at this screen — `Icons.tune` could be swapped for
  /// another glyph tomorrow without the promise changing.
  final optionsAction = find.byWidgetPredicate(
    (widget) =>
        widget is MxIconButton &&
        widget.semanticLabel == l10n.studyOptionsTitle,
  );

  /// The router parked on one deck's study entry, over faked storage.
  ///
  /// `deckRepositoryProvider` is faked as well as the study one because the
  /// route nests inside the Library branch: `/decks/<id>` sits under the pushed
  /// entry, and the deck list it builds reads the deck repository.
  Widget scope(Brightness brightness) => ProviderScope(
    overrides: [
      envConfigProvider.overrideWithValue(EnvConfig.development),
      deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
      studyRepositoryProvider.overrideWithValue(
        FakeStudyRepository(cardLimit: 30, newCardOrder: NewCardOrder.random)
          // BR-212: the values are this root's own, so the screen says so and
          // offers the way back to the app defaults.
          ..isRootOverride = true,
      ),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
      utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
    ],
    child: ReviewApp(
      // Relative to the Library branch root, which is `/` — so the full
      // location of `decks/:deckId` + `study` is this (`route_paths.dart`).
      home: deckRouterAt('/decks/deck-1/study'),
      brightness: brightness,
    ),
  );

  for (final (String label, Brightness brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('study options — an overridden deck, $label', (tester) async {
      await pumpReview(tester, scope(brightness));

      expect(optionsAction, findsOneWidget);
      await tester.tap(optionsAction);
      await tester.pumpAndSettle();

      // **The golden cannot be the only witness.** A push that silently failed
      // would photograph the entry screen, and a picture of the wrong screen
      // is exactly as green as a picture of the right one. These four are what
      // the entry screen cannot satisfy: the pushed route, its form, the card
      // limit the fake serves, and the override affordance BR-212 attaches to
      // it.
      expect(find.byType(StudyOptionsScreen), findsOneWidget);
      expect(find.byType(StudyOptionsSectionWidget), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text(l10n.studyOptionsUseAppDefaults), findsOneWidget);

      await matchesReviewGolden('goldens/study_options_$label.png');
    });
  }
}
