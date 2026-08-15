import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart';
import 'package:widgetbook/widgetbook.dart';

import 'study_catalog_repository.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/failures/study_refusal_failure.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';

/// The Study screens, mounted whole against the catalog's own repository.
///
/// **They were the catalog's outstanding debt** — M5.7 added two screens and
/// M5.11 a third, and none of them were registered, because the app's test
/// doubles live under `test/` and a second package cannot import them. The debt
/// closes with `StudyCatalogRepository`, which is the catalog's own.
///
/// The clock and the timezone are pinned for the same reason the repository is:
/// `domain/` takes both as inputs (AD-06, AD-16), so a catalog that left them
/// real would show a different screen every day it was opened.
final DateTime _catalogNow = DateTime.utc(2026, 8, 8, 2);

List<WidgetbookComponent> studyScreenComponents() => <WidgetbookComponent>[
  // First, because it is the tab's own screen: the Study branch opens here and
  // every other Study screen is reached through it (UC-14).
  _screen('StudyHomeScreen', (scenario) => const StudyHomeScreen()),
  _screen(
    'StudyEntryScreen',
    (scenario) => const StudyEntryScreen(deckId: 'catalog-deck'),
  ),
  _screen(
    'StudySessionScreen',
    (scenario) => StudySessionScreen(
      deckId: 'catalog-deck',
      kind: scenario.isReview
          ? StudySessionKind.reviewing
          : StudySessionKind.learning,
      reviewMode: scenario.isReview ? StudyMode.selfAssess : null,
      direction: scenario.direction,
    ),
  ),
  _screen(
    'StudyOptionsScreen',
    (scenario) => const StudyOptionsScreen(deckId: 'catalog-deck'),
  ),

  // **The one overlay in this list, and it earns the exception.** The other
  // Study sheets are a fixed list of choices; this one has three states of its
  // own — initial, submitting, and a refusal that keeps the selection — and the
  // middle two are unreachable from the screen entries above, because the
  // catalog's repository never fails. The dropdown drives them directly.
  _screen(
    'StudyDirectionChooser',
    (scenario) => _DirectionChooserDemo(scenario: scenario),
  ),
];

/// The direction sheet on its own, with its three states on the scenario knob.
///
/// Mounted flat rather than inside a real `showModalBottomSheet`: a catalog page
/// is not a route, and the sheet's own `SafeArea` + scroll behaviour is what a
/// reviewer needs to look at. **The chrome is the theme's, not a stand-in** —
/// `bottomSheetTheme` gives the real sheet `surface`, its top radius and a drag
/// handle, and the demo used `surfaceContainerLow`, which is a different colour
/// in dark and happens to be the one the selected radio glyph sits on.
class _DirectionChooserDemo extends StatelessWidget {
  const _DirectionChooserDemo({required this.scenario});

  /// **Read, since the knob is there.** The first version took the parameter
  /// and ignored it, and hard-coded a future that never resolves — so the
  /// refusal state this entry exists to show could not be reached at all,
  /// while the doc above said the dropdown drove it.
  final StudyCatalogScenario scenario;

  Future<Object?> _submit(
    StudySessionDirection direction,
  ) => switch (scenario) {
    // Nothing due: the refusal that keeps the selection and disables the CTA.
    StudyCatalogScenario.nothingDue ||
    StudyCatalogScenario.nothingLeft => Future<Object?>.value(
      const ConflictFailure(
        message: 'catalog: nothing due to review',
        reason: StudyRefusalReason.nothingDueToReview,
      ),
    ),
    // Anything else: a submit that never lands, so the busy state holds still
    // for as long as somebody wants to look at it.
    _ => Completer<Object?>().future,
  };

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData sheet = Theme.of(context).bottomSheetTheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: sheet.backgroundColor ?? Theme.of(context).colorScheme.surface,
        shape: sheet.shape,
        child: StudyDirectionChooserWidget(onSubmit: _submit),
      ),
    );
  }
}

/// One screen, with the scenario dropdown every Study use-case shares.
WidgetbookComponent _screen(
  String name,
  Widget Function(StudyCatalogScenario scenario) build,
) => WidgetbookComponent(
  name: name,
  useCases: <WidgetbookUseCase>[
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final scenario = context.knobs.object.dropdown<StudyCatalogScenario>(
          label: 'scenario',
          options: StudyCatalogScenario.values,
          labelBuilder: (StudyCatalogScenario value) => value.label,
        );

        // Keyed by scenario so switching it rebuilds from scratch: a study
        // session screen opens its session in a post-frame callback, and a tree
        // that survived the switch would still hold the previous scenario's.
        return _StudyDemo(
          key: ValueKey<Object>(scenario),
          scenario: scenario,
          child: build(scenario),
        );
      },
    ),
  ],
);

class _StudyDemo extends StatelessWidget {
  const _StudyDemo({required this.scenario, required this.child, super.key});

  final StudyCatalogScenario scenario;
  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      studyRepositoryProvider.overrideWithValue(
        StudyCatalogRepository(scenario),
      ),
      studyHomeRepositoryProvider.overrideWithValue(
        StudyHomeCatalogRepository(scenario),
      ),
      clockProvider.overrideWithValue(() => _catalogNow),
      utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
    ],
    child: child,
  );
}
