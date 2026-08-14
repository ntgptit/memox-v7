import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../di/app_settings_repository_provider.dart';
import '../../domain/models/app_settings_model.dart';
import '../../domain/usecases/watch_app_settings_use_case.dart';

part 'app_settings_controller.g.dart';

/// The app's global options, live (BR-182).
///
/// **The only reader of the settings row, and deliberately the only one.** The
/// root widget takes theme and language from here and the settings screen takes
/// all four; a second provider for "just the appearance" would be a second
/// subscription to one row, and two subscriptions are two snapshots (AD-13).
///
/// **A stream, not a future.** BR-182 requires one write to update every open
/// surface, and BR-186/BR-187 require the theme to change under a screen that
/// is already built. A `Future` provider would need every writer to remember to
/// invalidate it, and the one that forgot would be the one shipping.
///
/// `autoDispose`, like every provider under `presentation/`. It survives for
/// the life of the app anyway, because the root widget watches it and the root
/// never unmounts — which is a consequence of who listens, not a lifetime this
/// file grants itself.
@Riverpod(retry: noAutomaticRetry)
Stream<AppSettingsModel> appSettings(Ref ref) =>
    WatchAppSettingsUseCase(ref.watch(appSettingsRepositoryProvider)).call();
