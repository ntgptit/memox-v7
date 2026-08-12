import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';

import '../../domain/models/card_move_target_model.dart';
import '../providers/card_use_case_provider.dart';

part 'card_move_target_controller.g.dart';

/// The decks the open picker may move cards into (UC-04 A5, BR-165).
///
/// A stream, not a one-shot read: the picker can stay open while another
/// screen renames, creates or deletes a deck, and a target that stops being
/// legal should disappear rather than be refused after the tap.
///
/// Automatic retry is off, like every other local read here: while Riverpod
/// retries, the state is `AsyncLoading`, so a failed read would spin instead
/// of reaching the empty/error state the sheet draws.
@Riverpod(retry: noAutomaticRetry)
Stream<List<CardMoveTarget>> cardMoveTargets(Ref ref, String sourceDeckId) =>
    ref.watch(watchCardMoveTargetsUseCaseProvider)(sourceDeckId);
