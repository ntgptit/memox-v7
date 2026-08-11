import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../di/deck_template_provider.dart';
import '../../domain/models/deck_template_model.dart';
import '../../domain/models/scheduler_type_model.dart';
import '../../domain/usecases/get_installed_template_keys_use_case.dart';
import '../../domain/repositories/deck_template_repository.dart';

part 'starter_library_controller.g.dart';

/// One starter template as the catalog screen shows it: the published tree,
/// and whether the library already holds a copy.
typedef StarterTemplateRow = ({DeckTemplate template, bool isInstalled});

/// The catalog with each row's installed state — **one read model** (AD-13).
///
/// The catalog comes from the shipped assets and the installed set from the
/// database; the screen needs them *joined*, and joining them here means a row
/// cannot show "Add" beside a copy that already exists. The installed set is a
/// snapshot, not a stream — the only writer on this screen is the install
/// command below, which invalidates this provider on success.
///
/// Automatic retry is off — see `noAutomaticRetry`: an asset that fails to
/// decode fails identically on every retry, and the screen's error state with
/// its own retry button is the honest version of trying again.
@Riverpod(retry: noAutomaticRetry)
Future<List<StarterTemplateRow>> starterLibrary(Ref ref) async {
  final catalog = await ref.watch(deckTemplateCatalogProvider.future);
  final installed = await GetInstalledTemplateKeysUseCase(
    ref.watch(deckTemplateRepositoryProvider),
  )();

  return <StarterTemplateRow>[
    for (final template in catalog)
      (
        template: template,
        isInstalled: installed.contains((
          templateId: template.templateId,
          version: template.version,
        )),
      ),
  ];
}

/// The install command: at most one copy in flight, and its failure held where
/// the sheet can show it.
@riverpod
class StarterInstallController extends _$StarterInstallController {
  @override
  StarterInstallState build() => const StarterInstallState();

  /// Copies [template] with the chosen [schedulerType] (BR-33, BR-34).
  ///
  /// Returns the outcome so the sheet can close on success and explain an
  /// `alreadyPresent` — and null when the write failed or one was already in
  /// flight, matching the receipt convention the study feature settled: null
  /// means nothing happened, so nothing may be drawn as though it did.
  Future<DeckTemplateInstallOutcome?> install(
    DeckTemplate template, {
    required SchedulerType schedulerType,
    bool allowDuplicate = false,
  }) async {
    // A double tap on Add must not open two transactions (BR-25's shape).
    if (state.isInstalling) return null;

    state = const StarterInstallState(isInstalling: true);

    try {
      final outcome = await ref.read(installDeckTemplateUseCaseProvider)(
        template,
        schedulerType: schedulerType,
        allowDuplicate: allowDuplicate,
      );

      if (!ref.mounted) return outcome;
      state = const StarterInstallState();
      // The catalog rows carry `isInstalled`, and one of them just changed.
      ref.invalidate(starterLibraryProvider);

      return outcome;
    } on Object catch (error) {
      if (!ref.mounted) return null;
      // The transaction rolled back (BR-39): nothing was copied, and the state
      // says so rather than leaving a spinner over a library that did not
      // change.
      state = StarterInstallState(error: error);

      return null;
    }
  }
}

/// What the install command is doing, and what its last attempt left behind.
class StarterInstallState {
  const StarterInstallState({this.isInstalling = false, this.error});

  final bool isInstalling;
  final Object? error;
}
