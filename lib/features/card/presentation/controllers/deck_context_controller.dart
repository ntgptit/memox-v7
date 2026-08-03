import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/deck_context_model.dart';
import '../providers/card_use_case_provider.dart';

part 'deck_context_controller.g.dart';

/// The deck's name and ancestor breadcrumb for the card list header (W1).
///
/// A query provider — build-only, `noAutomaticRetry`, the same shape as the other
/// reads. Keyed by deckId so a rename re-emits both the title and the breadcrumb
/// from the one snapshot the repository shapes.
@Riverpod(retry: noAutomaticRetry)
Stream<DeckContextModel> deckContext(Ref ref, String deckId) =>
    ref.watch(watchDeckContextUseCaseProvider)(deckId);
