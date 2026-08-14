import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';

import '../features/study/domain/support/fake_study_home_repository.dart';
import '../features/study/domain/support/fake_study_repository.dart';

/// The instant every Study audit renders at.
///
/// Fixed, because a screen that reads the clock renders differently at 23:59
/// than at noon and a golden cannot tell the two apart from a regression.
final DateTime kStudyAuditNow = DateTime.utc(2026, 8, 7, 2);

/// Wraps one Study screen in a `ProviderScope` over a fake repository.
///
/// **No `MaterialApp` here** — `auditMemoxScreen` supplies one, with the theme
/// for the brightness it is testing. A second one would pin the screen to a
/// single theme and hide exactly the dark-mode drift the audit exists to catch.
///
/// The clock and the timezone are pinned for the same reason the repository is:
/// `domain/` takes both as inputs (AD-06, AD-16), so an audit that left them
/// real would measure a different screen every day it ran.
Widget studyScreenWith(FakeStudyRepository repository, Widget screen) {
  return ProviderScope(
    overrides: [
      studyRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => kStudyAuditNow),
      utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
    ],
    child: screen,
  );
}

/// The same wrapping for the Study tab's home screen, whose contract is the
/// read-only one (UC-12).
///
/// **A second helper rather than a nullable argument on the first.** Study Home
/// holds `StudyHomeRepository` and nothing else — that is what makes it unable
/// to open a session (BR-182) — and an audit that handed it a session repository
/// as well would quietly widen the surface the golden is taken over.
Widget studyHomeScreenWith(FakeStudyHomeRepository repository, Widget screen) {
  return ProviderScope(
    overrides: [
      studyHomeRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => kStudyAuditNow),
      utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
    ],
    child: screen,
  );
}
