import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/card_state_distribution_model.dart';
import '../providers/card_use_case_provider.dart';

part 'card_progress_controller.g.dart';

/// The deck's state distribution for the progress panel (D5).
///
/// A query provider — build-only, `noAutomaticRetry`, the same shape as the list
/// reads. It is whole-deck, not window-scoped, so it does not watch the window.
@Riverpod(retry: noAutomaticRetry)
Stream<CardStateDistributionModel> cardProgress(Ref ref, String deckId) =>
    ref.watch(watchCardStateDistributionUseCaseProvider)(deckId);
