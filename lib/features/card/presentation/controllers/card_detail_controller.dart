import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/card_detail_model.dart';
import '../providers/card_detail_use_case_provider.dart';

part 'card_detail_controller.g.dart';

/// One card's content, tags and current schedule, live (UC-19, BR-240).
///
/// **A stream, unlike the editor's `cardToEdit`, and the difference is what the
/// two screens do with what they read.** The editor takes a snapshot because
/// the user is typing into it and an incoming change would fight the text.
/// Nothing is typed here, so the honest behaviour is the opposite: come back
/// from the editor, or toggle a flag elsewhere, and this screen should already
/// show it.
///
/// `noAutomaticRetry`: a failed local read must show its failure rather than
/// spin for thirteen seconds under Riverpod's default ladder — see
/// `retry_policy.dart`. The visible `Retry` on the error state invalidates this
/// provider, which is the retry the user can actually control.
///
/// A card that is gone arrives as a `NotFoundFailure` on the stream, which the
/// screen renders as its not-found face (BR-245).
@Riverpod(retry: noAutomaticRetry)
Stream<CardDetailModel> cardDetail(Ref ref, String cardId) =>
    ref.watch(watchCardDetailUseCaseProvider)(cardId);
