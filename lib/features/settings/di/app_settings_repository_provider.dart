import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/app_settings_repository.dart';

part 'app_settings_repository_provider.g.dart';

/// The repository this feature needs, declared as the **contract** and bound at
/// the composition root.
///
/// The same shape `studyRepositoryProvider` has, and for the same reason:
/// `features/` may never import `app/` (AD-13), so the feature states what it
/// requires and `app/di/repository_bindings.dart` decides what satisfies it.
///
/// **`keepAlive`, and here it carries more weight than usual.** The root widget
/// subscribes to this feature's settings stream for the whole life of the app
/// (BR-186, BR-187); a provider that disposed between listeners would tear the
/// stream down and rebuild it, and a Drift `watchSingle` re-emits its first
/// value on resubscribe — a theme flicker with no user action behind it.
@Riverpod(keepAlive: true)
AppSettingsRepository appSettingsRepository(Ref ref) => throw StateError(
  'appSettingsRepositoryProvider must be overridden at the composition root',
);
