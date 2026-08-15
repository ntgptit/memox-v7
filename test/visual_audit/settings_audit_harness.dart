import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../features/settings/domain/support/fake_app_settings_repository.dart';

/// Wraps the Settings screen in a `ProviderScope` over a fake repository.
///
/// **No `MaterialApp` here** — `auditMemoxScreen` supplies one, with the theme
/// for the brightness it is testing. A second one would pin the screen to a
/// single theme and hide exactly the dark-mode drift the audit exists to catch.
///
/// Beside the other harnesses rather than under `screens/`, for the reason
/// `deck_audit_harness.dart` records: MX-VIS-001 treats everything under
/// `screens/` as a companion, and a harness is not one.
Widget settingsScreenWith(
  FakeAppSettingsRepository repository,
  Widget screen,
) => ProviderScope(
  overrides: [appSettingsRepositoryProvider.overrideWithValue(repository)],
  child: screen,
);
