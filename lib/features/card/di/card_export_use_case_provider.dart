import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/time/clock_provider.dart';
import '../domain/usecases/export_cards_use_case.dart';
import 'card_export_repository_provider.dart';

part 'card_export_use_case_provider.g.dart';

/// The export use case, wired from contracts only — dependency wiring, no
/// state and no command, which is why this is a `_provider` and not a
/// `_controller`.
///
/// **In `di/` rather than in `presentation/providers/`, where the import
/// wizard's use-case providers live, and the difference is AD-20's boundary.**
/// Two of the four dependencies are things presentation must never see: the
/// encoder resolver is the codec, and the destination is the plugin. Composing
/// the use case here means the screen reads one provider and imports neither.
///
/// The clock comes from `clockProvider`, so "now" has one owner the whole tree
/// can override and no file under `lib/features/` reads the wall clock
/// (BR-180). The function is passed, not the instant: the date the file is
/// named for is the date the button was pressed, not the date this provider
/// was built.
@riverpod
ExportCardsUseCase exportCardsUseCase(Ref ref) => ExportCardsUseCase(
  repository: ref.watch(cardExportRepositoryProvider),
  encoderFor: ref.watch(cardTransferEncoderResolverProvider),
  destination: ref.watch(cardExportDestinationRepositoryProvider),
  clock: ref.watch(clockProvider),
);
